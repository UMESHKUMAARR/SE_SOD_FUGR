REPORT /psyng/functhist NO STANDARD PAGE HEADING .
*----------------------------------------------------------------------
*
* PROGRAM               : /PSYNG/FUNCTHIST
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
TABLES: /psyng/history, /psyng/function.

TYPE-POOLS: slis.                              "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv, "For ALV call
      gs_alv_layout     TYPE slis_layout_alv.     "For ALV call

DATA: ihistory TYPE /psyng/history OCCURS 0 WITH HEADER LINE.
DATA: gs_program LIKE sy-repid,            "For ALV call
      gs_variant type disvariant.

SELECT-OPTIONS: function FOR /psyng/function-function,
                date FOR sy-datum,
                time FOR sy-uzeit,
                user FOR sy-uname.
PARAMETERS    : sodvrsio like /psyng/function-vrsio.

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
  PERFORM get_history.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.
*&---------------------------------------------------------------------*
*&      Form  GET_HISTORY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_history.
  SELECT * FROM /psyng/history                      "#EC CI_SEL_NESTED
        WHERE tabname = '/PSYNG/FUNCTION'
                                    AND   oldval  IN function
                                    AND   create_dat IN date
                                    AND   create_tim IN time
                                    AND   create_usr IN user
                                    AND   vrsio = sodvrsio.
    ihistory-oldval = /psyng/history-oldval.
    ihistory-status = /psyng/history-status.
    ihistory-create_usr = /psyng/history-create_usr.
    ihistory-create_dat = /psyng/history-create_dat.
    ihistory-create_tim = /psyng/history-create_tim.
    APPEND ihistory.
    SELECT * FROM /psyng/history                      "#EC CI_SEL_NESTED
              WHERE tabname = '/PSYNG/FUNCTTRANS'
                        AND   hdrfld  = /psyng/history-oldval
                        AND   create_dat = /psyng/history-create_dat
                        AND   create_tim = /psyng/history-create_tim
                        AND   create_usr = /psyng/history-create_usr
                        AND   vrsio      = sodvrsio.
      ihistory-oldval = /psyng/history-oldval.
      ihistory-newval = /psyng/history-newval.
      ihistory-status = /psyng/history-status.
      ihistory-create_usr = /psyng/history-create_usr.
      ihistory-create_dat = /psyng/history-create_dat.
      ihistory-create_tim = /psyng/history-create_tim.
      APPEND ihistory.
    ENDSELECT.
  ENDSELECT.

ENDFORM.                    " GET_HISTORY

*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = gs_program
            i_internal_tabname = 'IHISTORY'
            i_inclname         = gs_program
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .

ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*&      Form  OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv.
  gs_alv_layout-zebra = 'X'.
  gs_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = gs_program
            is_layout          = gs_alv_layout
            i_save                  = 'A'
            is_variant              = gs_variant
            it_fieldcat        = i_fieldcat_alv
       TABLES
            t_outtab           = ihistory
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .
ENDFORM.                    " OUTPUT_USING_ALV
