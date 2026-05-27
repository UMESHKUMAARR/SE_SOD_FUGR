REPORT /psyng/rolerpt NO STANDARD PAGE HEADING.
**----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/ROLERPT
* AUTHOR                : Principal Synergy LLC
* RELEASE               : 1.0
* DATE OF RELEASE       : 10/19/2004
* TRANSPORT REQUEST #   :
*----------------------------------------------------------------------*
*
* COPYRIGHTS Principal Synergy LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*
type-pools : slis.
TABLES: agr_users, agr_1251, usr02.
TABLES: /psyng/functtran, /psyng/sodobject,
        /psyng/rolehdr, /psyng/confdet, /psyng/user.

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

DATA: gf_missing_auth_ugroup TYPE /psyng/bapiflagx.
DATA : gs_program LIKE sy-repid.
DATA : gs_variant TYPE disvariant.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: uname FOR agr_users-uname,
                s_class FOR usr02-class,
                location FOR /psyng/user-location,
                roles FOR /psyng/rolehdr-saptechname.
SELECTION-SCREEN END OF BLOCK blk1.

*Version selection
SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
PARAMETER : p_vrsio LIKE /psyng/functtran-vrsio DEFAULT '0'.
SELECTION-SCREEN: END OF BLOCK blk2 .
*version selection

*&---------------------------------------------------------------------*
*&    At Selection screen on valye request
*&---------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR location-low.
  PERFORM location_f4help.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR location-high.
  PERFORM location_f4help.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR roles-low.
  PERFORM roles_f4help.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR roles-high.
  PERFORM roles_f4help.

INITIALIZATION.
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
  PERFORM get_txns.
  PERFORM check_conflict.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH text-001.
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
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA: lt_usrdet  TYPE TABLE OF /psyng/usrdet  WITH HEADER LINE,
        lt_posndet TYPE TABLE OF /psyng/posndet WITH HEADER LINE.


  SELECT usr02~class /psyng/user~userid INTO TABLE lt_user
    FROM /psyng/user
   INNER JOIN usr02
      ON /psyng/user~userid   =  usr02~bname
   WHERE /psyng/user~userid   IN uname
     AND /psyng/user~location IN location
     AND usr02~class          IN s_class.

* Check user group authority
*  SORT lt_user BY class.
*  LOOP AT lt_user.
*    AT NEW class.
*      CHECK NOT lt_user-class IS INITIAL.
*      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*               ID 'CLASS' FIELD lt_user-class.
*      IF sy-subrc <> 0.
*        DELETE lt_user WHERE class = lt_user-class.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*    ENDAT.
*  ENDLOOP.

  SORT lt_user BY class.
*DHO 20101202
  LOOP AT lt_user.
    lt_uinfo-bname = lt_user-userid.
    APPEND lt_uinfo.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
     vrsio                    = p_vrsio
*       ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  .

  LOOP AT lt_uinfo.


    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.

      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD p_vrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD p_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD p_vrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE lt_user WHERE userid = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.


  CHECK NOT lt_user[] IS INITIAL.

  SELECT * INTO TABLE lt_usrdet FROM /psyng/usrdet    "#EC CI_NOWHERE
     FOR ALL ENTRIES IN lt_user
   WHERE userid = lt_user-userid.

  CHECK NOT lt_usrdet[] IS INITIAL.

  SELECT * INTO TABLE lt_posndet FROM /psyng/posndet    "#EC CI_NOWHERE
     FOR ALL ENTRIES IN lt_usrdet
   WHERE positionid = lt_usrdet-positionid.

  SORT lt_usrdet BY userid.
  LOOP AT lt_usrdet.
    g_role_trans_itab-uname = lt_usrdet-userid.

    LOOP AT lt_posndet WHERE positionid = lt_usrdet-positionid.
      SELECT /psyng/rolehdr~saptechname            "#EC CI_SEL_NESTED
             /psyng/roletrans~tcode
        INTO (g_role_trans_itab-saptechname, g_role_trans_itab-tcode)
        FROM /psyng/rolehdr
       INNER JOIN /psyng/roletrans
          ON /psyng/rolehdr~roleid = /psyng/roletrans~roleid
WHERE /psyng/rolehdr~saptechname IN roles
         AND /psyng/rolehdr~roleid  = lt_posndet-roleid.
        APPEND g_role_trans_itab.
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
  DATA: BEGIN OF itab_tcode   OCCURS 0.
  DATA: uname TYPE agr_users-uname,
        tcode TYPE tstct-tcode.
  DATA: END OF itab_tcode.

  DATA: exist TYPE c.

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
    exist = 'X'.
    SELECT * FROM /psyng/sodobject  "#EC CI_SEL_NESTED
    WHERE tcode =  g_role_trans_itab-tcode.

      exist = space.

      SELECT * FROM agr_1251 INTO agr_1251    "#EC CI_SEL_NESTED
      WHERE agr_name = g_role_trans_itab-saptechname
      AND object = /psyng/sodobject-object
      AND field = /psyng/sodobject-field
      AND deleted NE 'X'.

*      AND LOW NE '*'.
        IF agr_1251-low = '*'.
          exist = 'X'.
        ENDIF.

        IF /psyng/sodobject-val_to > space AND
            /psyng/sodobject-val_from > space.
          IF /psyng/sodobject-val_from <= agr_1251-low AND
             /psyng/sodobject-val_to >= agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from > space AND
           /psyng/sodobject-val_to = space.
          IF /psyng/sodobject-val_from = agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to > space.
          IF /psyng/sodobject-val_to = agr_1251-low.
            exist = 'X'.
          ENDIF.
        ENDIF.

        IF /psyng/sodobject-val_from = space AND
           /psyng/sodobject-val_to = space.
          exist = 'X'.
        ENDIF.
      ENDSELECT.

      IF exist = space.
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
    SELECT * FROM /psyng/functtran    "#EC CI_SEL_NESTED
    WHERE tcode = g_role_trans_itab2-tcode
    AND   vrsio = p_vrsio.
      itab_funct1-uname = g_role_trans_itab2-uname.
      itab_funct1-functionid = /psyng/functtran-functionid.
      APPEND itab_funct1.
    ENDSELECT.
  ENDLOOP.

  SORT itab_funct1.
  DELETE ADJACENT DUPLICATES FROM itab_funct1.
  REFRESH itab_con.
  LOOP AT itab_funct1.
    SELECT * FROM /psyng/confdet    "#EC CI_SEL_NESTED
    WHERE functionid = itab_funct1-functionid
    AND   vrsio      = p_vrsio.
      itab_con-uname = itab_funct1-uname.
      itab_con-conid = /psyng/confdet-conid.
      APPEND itab_con.
    ENDSELECT.
  ENDLOOP.
  SORT itab_con.
  DELETE ADJACENT DUPLICATES FROM itab_con.

  LOOP AT itab_con.
    exist = space.
    SELECT * FROM /psyng/confdet     "#EC CI_SEL_NESTED
    WHERE conid = itab_con-conid
    AND   vrsio = p_vrsio.
      READ TABLE itab_funct1
      WITH KEY functionid = /psyng/confdet-functionid.
      IF sy-subrc <> 0.
        exist = 'X'.
      ENDIF.
    ENDSELECT.
    IF sy-subrc <> 0.
      exist = 'X'.
    ENDIF.
    IF exist = space.
      conflict-uname = itab_con-uname.
      conflict-conid = itab_con-conid.

      SELECT SINGLE description   "#EC CI_SEL_NESTED
        INTO conflict-description
         FROM /psyng/conflict
          WHERE conid  = conflict-conid
            AND vrsio    = p_vrsio
            AND inactive = space.

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
  gs_program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = gs_program
            i_callback_top_of_page   = 'ALV_HEADER'
            i_structure_name   = '/PSYNG/CNFLTALV'
            i_save             = 'A'
            is_variant         = gs_variant
       TABLES
            t_outtab           = conflict
"(++)BOC UMITTAL SE VF scan-25/11/2024
       EXCEPTIONS
        PROGRAM_ERROR          = 1
        OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .
ENDFORM.                    " WRITE_REPORT
*&---------------------------------------------------------------------*
*&      Form  Location_f4help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM location_f4help.

  DATA: BEGIN OF lt_location OCCURS 0,
              location TYPE /psyng/user-location,
              END OF lt_location.

  SELECT DISTINCT location
              UP TO 500 ROWS FROM /psyng/user
             INTO TABLE
                   lt_location.

  SORT lt_location BY location.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = ''
            dynpprog        = sy-cprog
            dynpnr          = sy-dynnr
            dynprofield     = 'LOCATION'
            value_org       = 'S'
       TABLES
            value_tab       = lt_location
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " Location_f4help
*&---------------------------------------------------------------------*
*&      Form  roles_f4help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM roles_f4help.

  DATA: BEGIN OF lt_role OCCURS 0,
        roleid TYPE /psyng/rolehdr-roleid,
        saptechname TYPE /psyng/rolehdr-saptechname,
        END OF lt_role.

  SELECT DISTINCT roleid saptechname
              UP TO 500 ROWS FROM /psyng/rolehdr
             INTO TABLE
                  lt_role.

  SORT lt_role BY roleid saptechname .

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = ''
            dynpprog        = sy-cprog
            dynpnr          = sy-dynnr
            dynprofield     = 'SAPTECHNAME'
            value_org       = 'S'
       TABLES
            value_tab       = lt_role
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " roles_f4help

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
* BOC by RGUPTA on 28.03.22 for C0700
        l_current_user type sy-uname.
        CLEAR l_current_user.
        CALL METHOD cl_abap_syst=>get_user_name
         RECEIVING
         user_name = l_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user."sy-uname. C0700
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
  wa-info = 'User Based SOD Conflict Report'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
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
