*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_043
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/sw_043  NO STANDARD PAGE HEADING LINE-SIZE 200.
TABLES : usr02.

TYPE-POOLS: slis.                                        "For ALV call
DATA: g_program LIKE sy-repid.                           "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv.           "For ALV call
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: gt_mchistxn TYPE STANDARD TABLE OF /psyng/mchistxn WITH HEADER
LINE.
DATA: gt_mchisrpt TYPE STANDARD TABLE OF /psyng/mchisrpt WITH HEADER
LINE.

DATA: BEGIN OF usrtcode OCCURS 0.
DATA:   contid LIKE /psyng/mchdr-contid,
        bname LIKE usr02-bname,
        tcode LIKE tstc-tcode,
        freq  LIKE /psyng/mcrepid-frequency,
        programm LIKE rs38m-programm,
      END OF usrtcode.

*end of performance enhancements
DATA: BEGIN OF gt_outab OCCURS 10.    "Table to contain data For ALV
DATA:   contid LIKE /psyng/mchdr-contid,
        bname LIKE usr02-bname,
        programm LIKE rs38m-programm,
        freq LIKE /psyng/sw_freq-freq,
        exe(4)   TYPE c,
        dte LIKE /psyng/mchistxn-xdate.
DATA: END OF gt_outab.

DATA:gf_missing_auth TYPE flag.
DATA: g_percent TYPE f,      "Progress indicator flag
      g_records TYPE f,      "# of records in table
      g_pertext(200),        "Progress indicator text
      g_nodata VALUE 'Y'.    "No data in table flag


SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-005.

SELECT-OPTIONS: s_contid FOR gt_outab-contid,
                uid      FOR gt_outab-bname MATCHCODE OBJECT user_comp,
                fromdate FOR sy-datum.
SELECTION-SCREEN SKIP.
PARAMETERS: p_assgnd AS CHECKBOX USER-COMMAND assgnd,
            p_sodvrs LIKE /psyng/sod_vrsio-vrsio.
SELECTION-SCREEN SKIP.
PARAMETERS: p_mon   AS CHECKBOX DEFAULT 'X',
            p_nomon AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK blk1.

SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-006.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) caut2.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) caut3.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) caut4.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk3.

*-------------------------- INITIALIZATION ----------------------------*
INITIALIZATION.
  PERFORM initialization.
  PERFORM exelog.
*-------------------- AT SELECTION-SCREEN OUTPUT ----------------------*
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CHECK screen-name CS 'SODVRSIO'.

    IF p_assgnd = 'X'.
      screen-input = 1.
    ELSE.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

AT SELECTION-SCREEN.
  PERFORM date_validation.

*------------------------ START-OF-SELECTION --------------------------*
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
  g_program = sy-repid.


  PERFORM get_users_data.
  PERFORM get_executed_tcodes.
* ************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
        'Missing some user authorizations'(084).
  ENDIF.
*************************************
  PERFORM format_output.
  MESSAGE s208(00) WITH text-000.
  COMMIT WORK.

  g_percent = 75.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = g_percent
            text       = text-001.
  IF g_nodata = space.
*    PERFORM build_sort_table.
    PERFORM build_alv_catalog.
* ************************************
    IF gf_missing_auth = 'X'.
*  **SF 1665
      MESSAGE s398(00) WITH
          'Missing some user authorizations'(084).
    ENDIF.
*************************************
    PERFORM output_using_alv.
  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  GET_USERS_DATA             "USER ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_users_data.
  DATA: l_contid  TYPE /psyng/mcuser-contid,
        l_auditor TYPE /psyng/mcuser-auditor.


  CLEAR:gf_missing_auth.
  REFRESH usrtcode.

 SELECT contid auditor INTO (l_contid, l_auditor) FROM /psyng/mcauditor
               WHERE contid  IN s_contid
                 AND auditor IN uid.

************************************************
**SF 1665
**Authorization check for Displaying SW Mitigations
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD '03'
             ID 'Y&SW_CNTID' FIELD l_contid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc EQ 0.
      IF p_assgnd = 'X'.
        SELECT SINGLE mandt INTO sy-mandt    "#EC CI_SEL_NESTED
          FROM /psyng/mcuser
               WHERE contid  = l_contid
               AND   auditor = l_auditor
               AND   vrsio   =  p_sodvrs.
        IF sy-subrc = 0.
          PERFORM get_mc_data USING l_contid l_auditor.
        ELSE.
          SELECT SINGLE mandt INTO sy-mandt    "#EC CI_SEL_NESTED
            FROM /psyng/mcusrgrp
                 WHERE contid  = l_contid
                 AND   auditor = l_auditor
                 AND   vrsio   =  p_sodvrs.
          IF sy-subrc = 0.
            PERFORM get_mc_data USING l_contid l_auditor.
          ENDIF.
        ENDIF.
      ELSE.
        PERFORM get_mc_data USING l_contid l_auditor.
      ENDIF.
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
**SF 1665
**************************************************
  ENDSELECT.

  IF p_assgnd IS INITIAL.
    SELECT contid auditor INTO (l_contid, l_auditor) FROM /psyng/mcuser
           WHERE contid  IN s_contid
           AND   auditor IN uid
           AND   vrsio   =  p_sodvrs.
*  ***********************************************
*  *SF 1665
*  *Authorization check for Displaying SW Mitigations
      AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
               ID 'ACTVT'      FIELD '03'
               ID 'Y&SW_CNTID' FIELD l_contid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc EQ 0.
        PERFORM get_mc_data USING l_contid l_auditor.
      ELSE.
        gf_missing_auth = 'X'.
      ENDIF.
*  *SF 1665
*  *************************************************
    ENDSELECT.
  ENDIF.

  SORT usrtcode.
  DELETE ADJACENT DUPLICATES FROM usrtcode.
ENDFORM.                    " GET_USERS_DATA

*&---------------------------------------------------------------------*
*&      Form  get_mc_data
*&---------------------------------------------------------------------*
*       Get Mitigating Control transactions and reports
*----------------------------------------------------------------------*
*      -->I_CONTID   Mitigating Control ID
*      -->I_AUDITOR  Auditor ID
*----------------------------------------------------------------------*
FORM get_mc_data USING    i_contid TYPE /psyng/mcuser-contid
                          i_auditor TYPE /psyng/mcuser-auditor.

  CLEAR usrtcode.
  MOVE i_contid  TO usrtcode-contid.
  MOVE i_auditor TO usrtcode-bname.

  SELECT repid frequency            "#EC CI_SEL_NESTED
    INTO (usrtcode-programm, usrtcode-freq)
         FROM /psyng/mcrepid
         WHERE contid = i_contid.
    APPEND usrtcode.
  ENDSELECT.

  CLEAR: usrtcode-programm, usrtcode-freq.
  SELECT tcode frequency              "#EC CI_SEL_NESTED
    INTO (usrtcode-tcode, usrtcode-freq)
         FROM /psyng/mctran
         WHERE contid = i_contid.
    APPEND usrtcode.
  ENDSELECT.
ENDFORM.                    " get_mc_data

*&---------------------------------------------------------------------*
*&      Form  get_executed_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_executed_tcodes.

  SELECT * FROM /psyng/mchisrpt INTO TABLE gt_mchisrpt
  WHERE bname IN uid
  AND   xdate IN fromdate.
*--Mitigations are not version specific
*  AND   vrsio =  sodvrsio.

  SELECT * FROM /psyng/mchistxn INTO TABLE gt_mchistxn
  WHERE bname IN uid
  AND   xdate IN fromdate.
*--Mitigations are not version specific
*  AND   vrsio = sodvrsio.
  SORT gt_mchisrpt.
  DELETE ADJACENT DUPLICATES FROM gt_mchisrpt.

  SORT gt_mchistxn.
  DELETE ADJACENT DUPLICATES FROM gt_mchistxn.

ENDFORM.                    " get_executed_tcodes

*&---------------------------------------------------------------------*
*&      Form  FORMAT_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_output.
  DATA: BEGIN OF lt_freq OCCURS 0,
          freq TYPE /psyng/sw_freq-freq,
          text   TYPE /psyng/sw_freqt-text,
          lang   TYPE /psyng/sw_freqt-lang,
        END OF lt_freq.


  CLEAR g_nodata.

  g_percent = 50.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = g_percent
            text       = text-002.

 SELECT a~freq b~text b~lang INTO CORRESPONDING FIELDS OF TABLE lt_freq
        FROM  /psyng/sw_freq AS a
        INNER JOIN /psyng/sw_freqt AS b ON a~freq = b~freq
        WHERE lang = sy-langu.


  LOOP AT usrtcode.
    CLEAR gt_outab.
    CLEAR lt_freq-text.
    gt_outab-contid = usrtcode-contid.
    gt_outab-bname  = usrtcode-bname.

    READ TABLE lt_freq WITH KEY freq = usrtcode-freq.
    gt_outab-freq = lt_freq-text.

    IF usrtcode-tcode > space.
      gt_outab-programm = usrtcode-tcode.

      LOOP AT gt_mchistxn WHERE bname = usrtcode-bname
      AND tcode = usrtcode-tcode.

        IF p_mon = 'X'.
          gt_outab-exe = '@08@'.
          gt_outab-dte = gt_mchistxn-xdate.
          APPEND gt_outab.
        ENDIF.
      ENDLOOP.

      IF sy-subrc <> 0 AND p_nomon = 'X'.
        gt_outab-exe = '@0A@'.
        APPEND gt_outab.
      ENDIF.
    ENDIF.

    IF usrtcode-programm > space.
      gt_outab-programm = usrtcode-programm.

      LOOP AT gt_mchisrpt WHERE bname = usrtcode-bname
      AND repid = usrtcode-programm.

        IF p_mon = 'X'.
          gt_outab-exe = '@08@'.
          gt_outab-dte = gt_mchisrpt-xdate.
          APPEND gt_outab.
        ENDIF.
      ENDLOOP.

      IF sy-subrc <> 0 AND p_nomon = 'X'.
        gt_outab-exe = '@0A@'.
        APPEND gt_outab.
      ENDIF.
    ENDIF.
  ENDLOOP.

  DESCRIBE TABLE gt_outab LINES g_records.
  IF g_records = 0.
    g_nodata = 'Y'.
    MESSAGE i208(00) WITH text-003.
  ENDIF.

  SORT gt_outab.
  DELETE ADJACENT DUPLICATES FROM gt_outab.
ENDFORM.                    " FORMAT_OUTPUT

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.


  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTAB'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
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

  wa_fieldcat_alv-seltext_l = text-014.
  wa_fieldcat_alv-seltext_m = text-015.
  wa_fieldcat_alv-seltext_s = text-014.
  wa_fieldcat_alv-reptext_ddic = text-014.
  wa_fieldcat_alv-icon         = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      icon
                   WHERE
                      fieldname = 'EXE'.

  wa_fieldcat_alv-seltext_l = text-019.
  wa_fieldcat_alv-seltext_m = text-020.
  wa_fieldcat_alv-seltext_s = text-014.
  wa_fieldcat_alv-reptext_ddic = text-019.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DTE'.

  wa_fieldcat_alv-seltext_l = text-007.
  wa_fieldcat_alv-seltext_m = text-007.
  wa_fieldcat_alv-seltext_s = text-007.
  wa_fieldcat_alv-reptext_ddic = text-007.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'PROGRAMM'.

  wa_fieldcat_alv-seltext_l = text-008.
  wa_fieldcat_alv-seltext_m = text-008.
  wa_fieldcat_alv-seltext_s = text-008.
  wa_fieldcat_alv-reptext_ddic = text-008.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FREQ'.

  MOVE text-004 TO g_pertext.

  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = 95
            text       = g_pertext.

ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*&      Form  OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_layout TYPE slis_layout_alv.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program     = g_program
            i_callback_top_of_page = 'ALV_HEADER'
            it_sort                = isort
            is_layout              = alv_layout
            it_fieldcat            = i_fieldcat_alv
       TABLES
            t_outtab               = gt_outab
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " OUTPUT_USING_ALV

*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialization.
  MOVE text-009 TO caut2.
  MOVE text-010 TO caut3.
  MOVE text-011 TO caut4.
ENDFORM.                    " initialization

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

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
  wa-info = 'Mitigation Monitor'(h01).
  APPEND wa TO header.
  IF p_assgnd = 'X'.
*SOD Version.
    wa-typ = 'S'.
    wa-key = 'Sod Version'(h02).
    SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
    WHERE vrsio = p_sodvrs.
    CONCATENATE p_sodvrs ' : '  wa-info INTO wa-info SEPARATED BY space.
    APPEND wa TO header.
  ENDIF.
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
*&---------------------------------------------------------------------*
*&      Form  date_validation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM date_validation.

  IF fromdate-low > sy-datum.
    MESSAGE e182(/psyng/sw).
  ENDIF.

  IF fromdate-high > sy-datum.
    MESSAGE e183(/psyng/sw).
  ENDIF.
ENDFORM.                    " date_validation
