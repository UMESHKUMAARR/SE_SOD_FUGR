*----------------------------------------------------------------------*
* Report  /PSYNG/SW_024                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_023 LINE-SIZE 250 MESSAGE-ID /psyng/sw.

TABLES: /psyng/rolehdr, /psyng/roletrans,
        /psyng/position, /psyng/usrdet, /psyng/posndet.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: gs_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      gt_sort TYPE STANDARD TABLE OF slis_sortinfo_alv,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: BEGIN OF output OCCURS 10,
        bname LIKE /psyng/usrdet-userid,
        positionid LIKE /psyng/position-positionid,
        postext LIKE /psyng/position-description,
        pospfcg LIKE /psyng/position-saptechname,
        roleid LIKE /psyng/rolehdr-roleid,
        roletext LIKE /psyng/rolehdr-description ,
        rolepfcg LIKE /psyng/rolehdr-saptechname,
        tcode LIKE /psyng/roletrans-tcode,
        ttext LIKE tstct-ttext,
      END OF output.
DATA: gs_output LIKE output.

DATA: gt_tstct TYPE HASHED TABLE OF tstct WITH UNIQUE KEY
             sprsl tcode
             WITH HEADER LINE.
DATA: gs_posndet TYPE /psyng/posndet.

DATA: BEGIN OF it_usrdet OCCURS 0,
         bname LIKE /psyng/usrdet-userid,
         positionid LIKE /psyng/usrdet-positionid,
         class      TYPE usr02-class,
        END OF it_usrdet.

DATA : gt_usrdet_uniq  LIKE TABLE OF it_usrdet.

DATA: BEGIN OF gt_position OCCURS 0,
    positionid LIKE /psyng/position-positionid,
     postext LIKE /psyng/position-description,
     pospfcg LIKE /psyng/position-saptechname,
     roleid LIKE /psyng/posndet-roleid,
END OF gt_position.

DATA : gt_position_uniq LIKE TABLE OF gt_position.

DATA: BEGIN OF gt_role OCCURS 0,
      roleid LIKE /psyng/rolehdr-roleid,
      roletext LIKE /psyng/rolehdr-description ,
      rolepfcg LIKE /psyng/rolehdr-saptechname,
      tcode LIKE /psyng/roletrans-tcode,
END OF gt_role.

DATA : gt_role_uniq LIKE TABLE OF  gt_role.

DATA:g_index_p TYPE i,
     g_index_r TYPE i.

FIELD-SYMBOLS : <fs_usrdet> LIKE it_usrdet,
                <fs_position> LIKE gt_position,
                <fs_role> LIKE gt_role.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-000.
SELECT-OPTIONS: pbname FOR /psyng/usrdet-userid.
SELECTION-SCREEN SKIP 1.
SELECT-OPTIONS: pposid FOR /psyng/position-positionid,
                ppsaptec FOR /psyng/position-saptechname.
SELECTION-SCREEN SKIP 1.
SELECT-OPTIONS: proleid FOR /psyng/rolehdr-roleid,
                pstatus FOR /psyng/rolehdr-status,
                prsaptec FOR /psyng/rolehdr-saptechname,
                powner  FOR /psyng/rolehdr-owner,
                ptcode FOR /psyng/roletrans-tcode.
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN: END OF BLOCK blk1.

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
****SF Case # 3469 Start Fix
****Code by Shekhar 07/08/2013

*******************************************
* Ist join for usr02 & /psyng/usrdet tables
*******************************************

  SELECT a~bname
         b~positionid
         a~class
        INTO TABLE it_usrdet
        FROM usr02 AS a INNER JOIN /psyng/usrdet AS b
    ON a~bname = b~userid
    WHERE
     b~userid     IN pbname  AND
     b~positionid IN pposid.

  SORT it_usrdet BY bname.
  gt_usrdet_uniq[] = it_usrdet[].

  SORT gt_usrdet_uniq BY positionid.
  DELETE ADJACENT DUPLICATES FROM gt_usrdet_uniq COMPARING positionid.

*******************************************************
* IInd join for /psyng/position & /psyng/posndet tables
*******************************************************

*  CHECK NOT gt_usrdet_uniq[] IS INITIAL.
  IF NOT gt_usrdet_uniq[] IS INITIAL.

    SELECT c~positionid
           c~description
           c~saptechname
           d~roleid
        INTO TABLE gt_position
      FROM /psyng/position AS c INNER JOIN /psyng/posndet AS d
      ON c~positionid = d~positionid
      FOR ALL ENTRIES IN gt_usrdet_uniq
      WHERE
      c~positionid = gt_usrdet_uniq-positionid  AND
      c~saptechname IN ppsaptec AND
      d~roleid       IN proleid.


    SORT gt_position BY positionid.

    gt_position_uniq[] = gt_position[].

    SORT gt_position_uniq BY roleid.
    DELETE ADJACENT DUPLICATES FROM gt_position_uniq COMPARING roleid.
  ENDIF.
**********************************************************
* IIIrd join for /psyng/rolehdr & /psyng/roletrans tables
**********************************************************
*  CHECK NOT gt_position_uniq[] IS INITIAL.
  IF NOT gt_position_uniq[] IS INITIAL.

    SELECT  e~roleid
            e~description
            e~saptechname
            f~tcode
          INTO TABLE gt_role
          FROM /psyng/rolehdr AS e INNER JOIN /psyng/roletrans AS f
          ON e~roleid = f~roleid
          FOR ALL ENTRIES IN gt_position_uniq
          WHERE
            e~roleid     = gt_position_uniq-roleid AND
            e~saptechname  IN prsaptec  AND
            e~owner        IN powner    AND
            e~status       IN pstatus   AND
            f~tcode        IN ptcode.

    SORT gt_role BY roleid.

    gt_role_uniq[] = gt_role[].

    SORT gt_role_uniq[] BY tcode.
    DELETE ADJACENT DUPLICATES FROM gt_role_uniq COMPARING tcode.
  ENDIF.
*  CHECK NOT gt_role_uniq[] IS INITIAL.
  IF NOT gt_role_uniq[] IS INITIAL.
    SELECT * FROM tstct INTO TABLE gt_tstct
    FOR ALL ENTRIES IN gt_role_uniq
    WHERE
      tcode = gt_role_uniq-tcode AND
      sprsl = sy-langu.
  ENDIF.

* Check user group authority
*DHO 20101202
*  SORT gt_usrdet BY class.
*  LOOP AT gt_usrdet.
*    AT NEW class.
*      CHECK NOT gt_usrdet-class IS INITIAL.
*      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*               ID 'CLASS' FIELD gt_usrdet-class.
*      IF sy-subrc <> 0.
*        DELETE gt_usrdet WHERE class = gt_usrdet-class.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*    ENDAT.
*  ENDLOOP.
*DHO 20101202
*DHO 20101202
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

  LOOP AT it_usrdet ASSIGNING <fs_usrdet>.
    lt_uinfo-bname = <fs_usrdet>-bname.
    APPEND lt_uinfo.
  ENDLOOP.

  SORT lt_uinfo BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

  IF NOT lt_uinfo IS INITIAL.

    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
*       VRSIO                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
       i_name_only              = 'X'
       i_mr_company             = 'X'
      TABLES
        sw_uinfo                 = lt_uinfo.

  ENDIF.
  LOOP AT lt_uinfo.

    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE it_usrdet INDEX sy-tabix.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE it_usrdet INDEX sy-tabix.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE it_usrdet INDEX sy-tabix.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.

  LOOP AT it_usrdet ASSIGNING <fs_usrdet>.
    READ TABLE gt_position WITH KEY
                        positionid = <fs_usrdet>-positionid
                        BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc EQ 0.
    g_index_p = sy-tabix.

    LOOP AT gt_position ASSIGNING <fs_position> FROM g_index_p
                            WHERE positionid EQ <fs_usrdet>-positionid.

      READ TABLE gt_role WITH KEY roleid = <fs_position>-roleid
                               BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc EQ 0.
      g_index_r = sy-tabix.

      LOOP AT gt_role ASSIGNING <fs_role>  FROM g_index_r
                             WHERE roleid EQ <fs_position>-roleid.

        gs_output-bname = <fs_usrdet>-bname.
        gs_output-positionid = <fs_position>-positionid.
        gs_output-postext = <fs_position>-postext.
        gs_output-pospfcg = <fs_position>-pospfcg.
        gs_output-roleid = <fs_role>-roleid.
        gs_output-roletext = <fs_role>-roletext.
        gs_output-rolepfcg = <fs_role>-rolepfcg.
        gs_output-tcode = <fs_role>-tcode.
        READ TABLE gt_tstct WITH TABLE KEY  sprsl = sy-langu
                                          tcode = <fs_role>-tcode.
        IF sy-subrc = 0.
          gs_output-ttext = gt_tstct-ttext.
        ENDIF.
        INSERT gs_output INTO TABLE output.
        CLEAR : gs_output.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.

****** Code Commented by shekhar for Case # 3469
****** Date 07/08/2013
* SELECT positionid description saptechname INTO TABLE gt_position
*          FROM /psyng/position FOR ALL ENTRIES IN gt_usrdet
*          WHERE positionid  =  gt_usrdet-positionid AND
*                saptechname IN ppsaptec             .
*
*  LOOP AT gt_usrdet.
*    LOOP AT gt_position WHERE positionid = gt_usrdet-positionid.
*
*      SELECT * FROM /psyng/posndet INTO gs_posndet WHERE
*               positionid = gt_position-positionid .
*
*        SELECT roleid description saptechname
*          INTO (/psyng/rolehdr-roleid, /psyng/rolehdr-description,
*                /psyng/rolehdr-saptechname)
*          FROM /psyng/rolehdr  WHERE
*               roleid       = gs_posndet-roleid AND
*               roleid       IN proleid   AND
*               saptechname  IN prsaptec  AND
*               owner        IN powner    AND
*               status       IN pstatus   .
*          SELECT * FROM /psyng/roletrans
*                   WHERE  roleid = /psyng/rolehdr-roleid AND
*                          tcode IN ptcode .
*            gs_output-bname = gt_usrdet-userid.
*            gs_output-positionid = gt_position-positionid.
*            gs_output-postext = gt_position-description.
*            gs_output-pospfcg = gt_position-saptechname.
*            gs_output-roleid = /psyng/rolehdr-roleid.
*            gs_output-roletext = /psyng/rolehdr-description.
*            gs_output-rolepfcg = /psyng/rolehdr-saptechname.
*            gs_output-tcode = /psyng/roletrans-tcode.
*            READ TABLE gt_tstct WITH TABLE KEY sprsl = sy-langu
*                                         tcode = /psyng/roletrans-tcode
*.
*            IF sy-subrc = 0.
*              gs_output-ttext = gt_tstct-ttext.
*            ENDIF.
*            INSERT gs_output INTO TABLE output.
*          ENDSELECT.
*        ENDSELECT.
*      ENDSELECT.
*    ENDLOOP.
*  ENDLOOP.


  IF output[] IS INITIAL.
    MESSAGE s174(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

***** End fix
  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH text-002.
  ENDIF.

  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat LIKE LINE OF gs_fieldcat_alv.        "For ALV call

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gs_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat-seltext_l = text-h01.
  wa_fieldcat-seltext_m = text-h01.
  wa_fieldcat-seltext_s = text-h01.
  wa_fieldcat-reptext_ddic = text-h01.
  MODIFY gs_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'POSTEXT'.
ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_layout      TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl   TYPE lvc_title,                  "For ALV call
        ls_variant      TYPE disvariant.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  PERFORM build_sort_table.
  alv_grid_titl = text-001.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = g_program
            it_sort            = gt_sort
            is_layout          = alv_layout
            it_fieldcat        = gs_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'POSITIONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'POSTEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'POSPFCG'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'ROLEID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'ROLETEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'ROLEPFCG'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_sort.

ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user  TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.


ENDFORM.                    " exelog
