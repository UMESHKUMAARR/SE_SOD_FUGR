*----------------------------------------------------------------------
* PROGRAM               : /PSYNG/SUMRYRPT
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sumryrpt NO STANDARD PAGE HEADING .
type-pools:slis.
TABLES: agr_1251, usr02.
TABLES: /psyng/functtran, /psyng/sodobject,
        /psyng/rolehdr, /psyng/confdet, /psyng/user, /psyng/posndet.

DATA:     BEGIN OF g_role_trans_itab   OCCURS 0.
DATA:     uname TYPE agr_users-uname,
          saptechname TYPE /psyng/rolehdr-saptechname,
          tcode TYPE tstct-tcode,
          ttext TYPE tstct-ttext,
          flag TYPE c.
DATA: END OF g_role_trans_itab.

DATA:     BEGIN OF conflict  OCCURS 0.
DATA:     uname TYPE agr_users-uname,
          conid TYPE /psyng/conflict-conid,
          description TYPE /psyng/conflict-description.
DATA:     END OF conflict.

DATA: tot_usr TYPE i,
      tot_txns TYPE i,
      tot_role TYPE i,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      gs_program like sy-repid,
      gs_variant type disvariant,
      g_current_user TYPE sy-uname. "C0700

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: uname FOR /psyng/user-userid.
SELECT-OPTIONS: s_class FOR usr02-class.
parameter :     p_sodvrs    type /psyng/sodvrsio.
SELECT-OPTIONS: location FOR /psyng/user-location,
                role FOR /psyng/rolehdr-saptechname.
SELECTION-SCREEN END OF BLOCK blk1.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024
AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  gs_program = sy-repid.
  PERFORM get_txns.
  PERFORM check_conflict.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH text-007.
  ENDIF.

  PERFORM write_report.

*&---------------------------------------------------------------------*
*&      Form  GET_TXNS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_txns.
DATA: BEGIN OF lt_user OCCURS 0,
        class  TYPE usr02-class,
        userid TYPE /psyng/user-userid,
      END OF lt_user.

DATA: lt_usrdet  TYPE TABLE OF /psyng/usrdet  WITH HEADER LINE,
      lt_posndet TYPE TABLE OF /psyng/posndet WITH HEADER LINE.


  SELECT usr02~class /psyng/user~userid INTO TABLE lt_user
    FROM /PSYNG/USER
   INNER JOIN usr02
      ON /psyng/user~userid = usr02~bname
   WHERE /psyng/user~userid IN uname
     AND usr02~class IN s_class
     AND /psyng/user~location IN location.
  data : lt_uinfo type table of /psyng/sw_uinfo with header line.
  loop at lt_user.
      lt_uinfo-bname = lt_user-userid.
      append lt_uinfo.
  endloop.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
       VRSIO                    = p_sodvrs
*       ENHANCED_SCANTABLE       = ''
       I_NAME_ONLY              = 'X'
       I_MR_COMPANY             = 'X'
      TABLES
        sw_uinfo                 = lt_uinfo.
              .

  LOOP AT lt_uinfo.


  if not lt_uinfo-class is initial AND
     not lt_uinfo-company is initial.

    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD lt_uinfo-class
         ID 'Y&SW_VRSIO'  field p_sodvrs
         ID 'Y&SW_COMP'   field lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  elseif not lt_uinfo-class is initial.
    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD lt_uinfo-class
         ID 'Y&SW_VRSIO'  field p_sodvrs
         ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  elseif not lt_uinfo-company is initial.
    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
         ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_VRSIO'  field p_sodvrs
         ID 'Y&SW_COMP'   field lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
  endif.
  ENDLOOP.



  DESCRIBE TABLE lt_user LINES tot_usr.
  CHECK tot_usr > 0.
  if not lt_user[] is initial.
    SELECT * INTO TABLE lt_usrdet FROM /PSYNG/USRDET
       FOR ALL ENTRIES IN lt_user
     WHERE USERID = lt_user-userid.
  endif.
  CHECK NOT lt_usrdet[] IS INITIAL.

  SELECT * INTO TABLE lt_posndet         "#EC CI_NO_TRANSFORM
    FROM /PSYNG/POSNDET
     FOR ALL ENTRIES IN lt_usrdet
   WHERE POSITIONID = lt_usrdet-positionid.

  SORT lt_usrdet BY userid.
  LOOP AT lt_usrdet.
    g_role_trans_itab-uname = lt_usrdet-userid.

    LOOP AT lt_posndet WHERE positionid = lt_usrdet-positionid.
      SELECT roleid saptechname    "#EC CI_SEL_NESTED
        INTO (/psyng/rolehdr-roleid, g_role_trans_itab-saptechname)
        FROM /psyng/rolehdr
       WHERE saptechname IN role
*         AND roleid = /psyng/posndet-roleid.
         AND roleid = lt_posndet-roleid.

        tot_role = tot_role + 1.

        SELECT tcode INTO g_role_trans_itab-tcode    "#EC CI_SEL_NESTED
             FROM /psyng/roletrans
               WHERE roleid = /psyng/rolehdr-roleid.

          APPEND g_role_trans_itab.
          tot_txns = tot_txns + 1.
        ENDSELECT.
      ENDSELECT.
    ENDLOOP.

    PERFORM check_conflict.
    REFRESH g_role_trans_itab.
  ENDLOOP.
ENDFORM.                    " GET_TXNS
*&---------------------------------------------------------------------*
*&      Form  CHECK_CONFLICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_conflict.
DATA: l_exist TYPE c.

DATA: BEGIN OF itab_tcode   OCCURS 0.
DATA: uname TYPE agr_users-uname,
      tcode TYPE tstct-tcode.
DATA: END OF itab_tcode.

DATA:     BEGIN OF itab_funct1   OCCURS 0.
DATA:     uname TYPE agr_users-uname,
          functionid TYPE /psyng/functtran-functionid,
          tcode  TYPE /psyng/functtran-tcode.
DATA: END OF itab_funct1.

DATA:     BEGIN OF g_role_trans_itab2   OCCURS 0.
DATA:     uname TYPE agr_users-uname,
          saptechname TYPE /psyng/rolehdr-saptechname,
          tcode TYPE tstct-tcode,
          ttext TYPE tstct-ttext.
DATA: END OF g_role_trans_itab2.

DATA:     BEGIN OF itab_con  OCCURS 0.
DATA:     uname TYPE agr_users-uname,
          conid TYPE /psyng/conflict-conid.
DATA:     END OF itab_con.


  REFRESH itab_tcode.
  REFRESH g_role_trans_itab2.
  LOOP AT g_role_trans_itab.
    MOVE g_role_trans_itab TO g_role_trans_itab2.
    APPEND g_role_trans_itab2.
  ENDLOOP.

  LOOP AT g_role_trans_itab.
    l_exist = 'X'.
    SELECT * FROM /psyng/sodobject   "#EC CI_SEL_NESTED
    WHERE tcode =  g_role_trans_itab-tcode
    and   vrsio =  p_sodvrs.

      l_exist = space.

      SELECT * FROM agr_1251 INTO agr_1251
      WHERE agr_name = g_role_trans_itab-saptechname
      AND object = /psyng/sodobject-object
      AND field = /psyng/sodobject-field
      AND deleted NE 'X'.

*      AND LOW NE '*'.
        IF agr_1251-low = '*'.
          l_exist = 'X'.
        ENDIF.

        IF /psyng/sodobject-val_to > space AND
            /psyng/sodobject-val_from > space.
          IF /psyng/sodobject-val_from <= agr_1251-low AND
             /psyng/sodobject-val_to >= agr_1251-low.
            l_exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from > space AND
           /psyng/sodobject-val_to = space.
          IF /psyng/sodobject-val_from = agr_1251-low.
            l_exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to > space.
          IF /psyng/sodobject-val_to = agr_1251-low.
            l_exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to = space.
          l_exist = 'X'.
        ENDIF.
      ENDSELECT.

      IF l_exist = space.
        itab_tcode-uname = g_role_trans_itab-uname.
        itab_tcode-tcode = g_role_trans_itab-tcode.
        APPEND itab_tcode.
      ENDIF.

    ENDSELECT.
  ENDLOOP.

  LOOP AT itab_tcode.
    DELETE g_role_trans_itab2 WHERE tcode = itab_tcode-tcode.
  ENDLOOP.

  REFRESH itab_funct1.
  LOOP AT g_role_trans_itab2.
    SELECT * FROM /psyng/functtran   "#EC CI_SEL_NESTED
    WHERE tcode = g_role_trans_itab2-tcode
    and   vrsio = p_sodvrs.
      itab_funct1-uname = g_role_trans_itab2-uname.
      itab_funct1-functionid = /psyng/functtran-functionid.
      APPEND itab_funct1.
    ENDSELECT.
  ENDLOOP.

  SORT itab_funct1.
  DELETE ADJACENT DUPLICATES FROM itab_funct1.
  REFRESH itab_con.
  LOOP AT itab_funct1.
    SELECT * FROM /psyng/confdet      "#EC CI_SEL_NESTED
    WHERE functionid = itab_funct1-functionid
    and   vrsio      = p_sodvrs.
      itab_con-uname = itab_funct1-uname.
      itab_con-conid = /psyng/confdet-conid.
      APPEND itab_con.
    ENDSELECT.
  ENDLOOP.
  SORT itab_con.
  DELETE ADJACENT DUPLICATES FROM itab_con.

  LOOP AT itab_con.
    l_exist = space.
    SELECT * FROM /psyng/confdet      "#EC CI_SEL_NESTED
    WHERE conid = itab_con-conid
    and   vrsio = p_sodvrs.
      READ TABLE itab_funct1
      WITH KEY functionid = /psyng/confdet-functionid.
      IF sy-subrc <> 0.
        l_exist = 'X'.
      ENDIF.
    ENDSELECT.
    IF sy-subrc <> 0.
      l_exist = 'X'.
    ENDIF.
    IF l_exist = space.
      conflict-uname = itab_con-uname.
      conflict-conid = itab_con-conid.

      SELECT SINGLE description      "#EC CI_SEL_NESTED
         INTO conflict-description
           FROM /psyng/conflict
            WHERE conid = conflict-conid
            and   vrsio = p_sodvrs.

      APPEND conflict.
    ENDIF.
  ENDLOOP.
  SORT conflict.
  DELETE ADJACENT DUPLICATES FROM conflict.
ENDFORM.                    " CHECK_CONFLICT
*&---------------------------------------------------------------------*
*&      Form  WRITE_REPORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM write_report.
TYPES: BEGIN OF uitab,
        name(20) TYPE c,
        count    TYPE i,
      END OF uitab.

DATA:     BEGIN OF itab_total   OCCURS 0.
DATA:     description TYPE /psyng/summary-description,
          tot  TYPE i.
DATA: END OF itab_total.

DATA: mit_flg1,
      mit_flg2,
      ztxt(15)           TYPE c,
      i                  TYPE i,
      tot_mit_usrs       TYPE i,
      tot_no_mit_usrs    TYPE i,
      tot_high_usrs      TYPE i,
      tot_avrg_usrs      TYPE i,
      tot_avrgroles_usrs TYPE i,
      tot_avrgtxns_usrs  TYPE i,
      utab               TYPE uitab,
      uutab              TYPE HASHED TABLE OF uitab
                         WITH UNIQUE KEY name.


  SORT conflict.
  REFRESH uutab.
  LOOP AT conflict.
    utab-name = conflict-uname.
    utab-count = 1.
    COLLECT utab INTO uutab.
  ENDLOOP.
  i = 0.
  LOOP AT uutab INTO utab.
    tot_avrg_usrs = tot_avrg_usrs + utab-count.
  ENDLOOP.
  DESCRIBE TABLE uutab LINES i.
  IF i >= 1.
    tot_avrg_usrs      = tot_avrg_usrs / i.
    tot_avrgroles_usrs = tot_role / i.
    tot_avrgtxns_usrs  = tot_txns / i.
  ENDIF.

  LOOP AT uutab INTO utab.
    mit_flg1 = space.
    mit_flg2 = space.
    LOOP AT conflict WHERE uname = utab-name.
      mit_flg1 = space.
      CONCATENATE conflict-uname conflict-conid INTO ztxt.
      SELECT SINGLE mandt INTO sy-mandt      "#EC CI_SEL_NESTED
      FROM /psyng/texts
      WHERE textname = ztxt.
      IF sy-subrc = 0.
        mit_flg1 = 'X'.
      ELSE.
        mit_flg1 = space.
        IF mit_flg2 = space.
          mit_flg2 = 'X'.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF mit_flg1 = 'X'.
      tot_mit_usrs = tot_mit_usrs + 1.
    ENDIF.
    IF mit_flg2 = 'X'.
      tot_no_mit_usrs = tot_no_mit_usrs + 1.
      IF utab-count >= tot_avrg_usrs.
        tot_high_usrs = tot_high_usrs + 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

  itab_total-description = text-000.
  itab_total-tot = tot_usr.
  APPEND itab_total.

  itab_total-description = text-001.
  itab_total-tot = tot_mit_usrs.
  APPEND itab_total.

  itab_total-description = text-002.
  itab_total-tot = tot_no_mit_usrs.
  APPEND itab_total.

  itab_total-description = text-003.
  itab_total-tot = tot_high_usrs.
  APPEND itab_total.

  itab_total-description = text-004.
  itab_total-tot = tot_avrg_usrs.
  APPEND itab_total.

  itab_total-description = text-005.
  itab_total-tot = tot_avrgroles_usrs.
  APPEND itab_total.

  itab_total-description = text-006.
  itab_total-tot = tot_avrgtxns_usrs.
  APPEND itab_total.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_structure_name = '/PSYNG/SUMMARY'
            i_callback_program      = gs_program
            i_callback_top_of_page  = 'ALV_HEADER'
            i_save                  = 'A'
            is_variant              = gs_variant
       TABLES
            t_outtab         = itab_total
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " WRITE_REPORT

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_count TYPE i,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  wa-typ = 'H'.
  wa-info = 'Summary Report'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_sodvrs.
  CONCATENATE p_sodvrs ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'Date'(h03).
  WRITE sy-datum TO l_date.
  wa-info = l_date.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

ENDFORM.
