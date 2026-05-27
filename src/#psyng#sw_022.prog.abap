*----------------------------------------------------------------------*
* Report  /PSYNG/SW_022                                                *
* AUTHOR: Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_022 .

TABLES: /psyng/rolehdr, /psyng/roletrans.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: BEGIN OF output OCCURS 10,
        roleid LIKE /psyng/rolehdr-roleid,
        description LIKE /psyng/rolehdr-description ,
        owner LIKE /psyng/rolehdr-owner ,
        approval LIKE /psyng/rolehdr-approval ,
        importance LIKE /psyng/rolehdr-importance ,
        project LIKE /psyng/rolehdr-project ,
        rolemodule LIKE /psyng/rolehdr-rolemodule ,
        saptechname LIKE /psyng/rolehdr-saptechname ,
        status LIKE /psyng/rolehdr-status ,
        tcode LIKE /psyng/roletrans-tcode,
        ttext LIKE tstct-ttext,
      END OF output.
DATA: g_wa_output LIKE output.
DATA:gf_missing_auth TYPE flag.
DATA: gt_itstct TYPE HASHED TABLE OF tstct WITH UNIQUE KEY
             sprsl tcode
             WITH HEADER LINE.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-000.
SELECT-OPTIONS: proleid FOR /psyng/rolehdr-roleid,
                psaptech FOR /psyng/rolehdr-saptechname,
                powner  FOR /psyng/rolehdr-owner,
                pstatus FOR /psyng/rolehdr-status,
                ptcode FOR /psyng/roletrans-tcode.
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
*************************************
**SF 1665
  CLEAR:gf_missing_auth.
*************************************

  SELECT * FROM tstct INTO CORRESPONDING FIELDS OF TABLE gt_itstct WHERE
                sprsl = sy-langu AND
                tcode IN ptcode.

  SELECT * FROM /psyng/rolehdr
           INTO CORRESPONDING FIELDS OF g_wa_output
           WHERE roleid       IN proleid  AND
                 saptechname IN  psaptech AND
                 owner       IN  powner   AND
                 status      IN  pstatus.

*************************************
**SF 1665
**Authorization check for Displaying SW Roles
    AUTHORITY-CHECK OBJECT 'Y&SW_ROLEH'
               ID 'ACTVT' FIELD '03'
               ID 'Y&SW_ROLID' FIELD g_wa_output-roleid.
    IF sy-subrc EQ 0.
*************************************
      SELECT tcode INTO g_wa_output-tcode        "#EC CI_SEL_NESTED
             FROM /psyng/roletrans
                 WHERE roleid = g_wa_output-roleid AND
                       tcode IN ptcode.

        READ TABLE gt_itstct WITH TABLE KEY sprsl = sy-langu
                                         tcode = g_wa_output-tcode.
        IF sy-subrc = 0.
          g_wa_output-ttext = gt_itstct-ttext.
        ENDIF.
        INSERT g_wa_output INTO TABLE output.

      ENDSELECT.
** Fix case 3198
*      IF sy-subrc <> 0.
**Add role without tcodes.
*        CLEAR : wa_output-tcode, wa_output-ttext.
*        INSERT wa_output INTO TABLE output.
*      ENDIF.
**End Fix
************************************
**SF 1665
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
**SF 1665
*************************************
  ENDSELECT.


  PERFORM build_alv_catalog.
*************************************
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
        'Missing some user authorizations'(084).
  ENDIF.
*************************************

  PERFORM output_using_alv.

***&--------------------------------------------------------------------
*-
**
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.

  IF output[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

  DATA: wa_fieldcat LIKE LINE OF i_fieldcat_alv.

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'OUTPUT'
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

  wa_fieldcat-seltext_l = text-h01.
  wa_fieldcat-seltext_m = text-h01.
  wa_fieldcat-seltext_s = text-h01.
  wa_fieldcat-reptext_ddic = text-h01.
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'APPROVAL'.
ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: alv_layout    TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl TYPE lvc_title,                  "For ALV call
        ls_variant    TYPE disvariant.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  PERFORM build_sort_table.
  alv_grid_titl = text-t01.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = alv_grid_titl
            i_callback_program = g_program
            it_sort            = isort
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
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
  l_sort-fieldname = 'ROLEID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '10'.
  l_sort-fieldname = 'APPROVAL'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '11'.
  l_sort-fieldname = 'IMPORTANCE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '12'.
  l_sort-fieldname = 'PROJECT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '13'.
  l_sort-fieldname = 'ROLEMODULE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '14'.
  l_sort-fieldname = 'SAPTECHNAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '15'.
  l_sort-fieldname = 'STATUS'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '16'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
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
