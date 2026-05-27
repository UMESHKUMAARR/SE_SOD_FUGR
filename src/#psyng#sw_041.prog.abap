*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_041
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

REPORT /psyng/sw_041 .
INCLUDE /PSYNG/SW_CONFIG.
TABLES: /psyng/function, /psyng/functtran, /psyng/texts, rfcdes.

TYPE-POOLS: slis.                                        "For ALV call
DATA: program LIKE sy-repid.                             "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv,           "For ALV call
      alv_layout     TYPE slis_layout_alv.               "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort TYPE slis_sortinfo_alv.

DATA: function TYPE STANDARD TABLE OF /psyng/function WITH HEADER LINE.

DATA : GS_PROGRAM LIKE SY-REPID,
       GS_VARIANT TYPE DISVARIANT.

DATA: BEGIN OF output OCCURS 0,
        function LIKE /psyng/function-function,
        description LIKE /psyng/function-description,
        funid_copied,
        funid_hdr_copied,
        funid_tc_copied,
        funid_txt_copied,
        message(100),
      END OF output.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE blktl.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.                      "Function ID
SELECTION-SCREEN COMMENT 4(23) funcom.
SELECTION-SCREEN POSITION 25.
SELECT-OPTIONS: funids FOR /psyng/function-function.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.                      "RFC destinations
SELECTION-SCREEN COMMENT 4(23) rfccom.
PARAMETERS: rfc LIKE rfcdes-rfcdest OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk1.

SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-021.
PARAMETERS : trgvrsio like /psyng/function-vrsio. "target sod version
PARAMETERS : srcvrsio like /psyng/function-vrsio. "source sod version
SELECTION-SCREEN: END OF BLOCK blk2.

INITIALIZATION.
  PERFORM initialization.

AT SELECTION-SCREEN.
  IF NOT rfc IS INITIAL.
    SELECT SINGLE * FROM rfcdes WHERE rfcdest = rfc.
    IF sy-subrc NE 0.
      MESSAGE e208(00) WITH TEXT-000.
*      exit.
    ENDIF.
  ENDIF.

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
  GS_PROGRAM = SY-REPID.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
  CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_FUNIDS'
    DESTINATION rfc
       EXPORTING
             vrsio   = srcvrsio
       TABLES
            function = function
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT function WHERE function IN funids.

    CLEAR output.
    MOVE-CORRESPONDING function TO output.

    CALL FUNCTION '/PSYNG/SW_CR_COPY_REMOTE_FUNID'
         EXPORTING
              sourcefunctionid             = function-function
              sourcevrsio                  = srcvrsio
              targetfunctionid             = function-function
              targetvrsio                  = trgvrsio
              rfcdest                      = rfc
         IMPORTING
              funid_copied                 = output-funid_copied
              funid_hdr_copied             = output-funid_hdr_copied
              funid_tc_copied              = output-funid_tc_copied
              funid_txt_copied             = output-funid_txt_copied
         EXCEPTIONS
              target_funid_not_specified   = 1
              not_authorized               = 2
              target_already_exists        = 3
              source_function_doesnt_exist = 4
              not_authorized_to_display    = 5
              invalid_rfc                  = 6
              OTHERS                       = 7.

    CASE sy-subrc .
      WHEN 0.
        output-message = TEXT-004.
      WHEN 1.
        output-message = TEXT-005.
      WHEN 2.
        output-message = TEXT-006.
      WHEN 3.
        output-message = TEXT-007.
      WHEN 4.
        output-message = TEXT-008.
      WHEN 5.
        output-message = TEXT-009.
      WHEN 6.
        output-message = TEXT-010.
      WHEN 7.
        output-message = TEXT-011.
    ENDCASE.

    APPEND output.

  ENDLOOP.

  PERFORM build_sort_table.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

END-OF-SELECTION.
*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialization.
  data: dflt_rfc LIKE /psyng/swconfig-value.
  se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
  IF NOT dflt_rfc IS INITIAL.
    rfc = dflt_rfc.
  ENDIF.

  MOVE TEXT-001 TO blktl.
  MOVE TEXT-002 TO funcom.
  MOVE TEXT-003 TO rfccom.

ENDFORM.                    " initialization
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog.

  program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = gs_program
            i_internal_tabname = 'OUTPUT'
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat_alv-seltext_l = TEXT-012.
  wa_fieldcat_alv-seltext_m = TEXT-013.
  wa_fieldcat_alv-seltext_s = TEXT-013.
  wa_fieldcat_alv-reptext_ddic = TEXT-012.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNID_COPIED'.

  wa_fieldcat_alv-seltext_l = TEXT-014.
  wa_fieldcat_alv-seltext_m = TEXT-015.
  wa_fieldcat_alv-seltext_s = TEXT-015.
  wa_fieldcat_alv-reptext_ddic = TEXT-014.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNID_HDR_COPIED'.

  wa_fieldcat_alv-seltext_l = TEXT-016.
  wa_fieldcat_alv-seltext_m = TEXT-016.
  wa_fieldcat_alv-seltext_s = TEXT-017.
  wa_fieldcat_alv-reptext_ddic = TEXT-016.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNID_TC_COPIED'.

  wa_fieldcat_alv-seltext_l = TEXT-018.
  wa_fieldcat_alv-seltext_m = TEXT-018.
  wa_fieldcat_alv-seltext_s = TEXT-019.
  wa_fieldcat_alv-reptext_ddic = TEXT-018.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNID_TXT_COPIED'.

  wa_fieldcat_alv-seltext_l = TEXT-020.
  wa_fieldcat_alv-seltext_m = TEXT-020.
  wa_fieldcat_alv-seltext_s = TEXT-020.
  wa_fieldcat_alv-reptext_ddic = TEXT-020.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'MESSAGE'.

ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = gs_program
            it_sort            = isort
            is_layout          = alv_layout
            i_save             = 'A'
            is_variant         = gs_variant
            it_fieldcat        = i_fieldcat_alv
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
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort_table.

  l_sort-spos = '1'.
  l_sort-fieldname = 'FUNCTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " build_sort_table
