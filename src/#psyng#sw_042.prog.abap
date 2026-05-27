*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_042
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

REPORT /psyng/sw_042 .
INCLUDE /PSYNG/SW_CONFIG.
TABLES: rfcdes,
        /psyng/conflict.

TYPE-POOLS: slis.                                        "For ALV call
DATA: program LIKE sy-repid.                             "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv.           "For ALV call
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: conflict TYPE STANDARD TABLE OF /psyng/conflict WITH HEADER LINE.

DATA : gs_program LIKE sy-repid,
       gs_variant TYPE disvariant.

DATA: BEGIN OF output OCCURS 0,
        conid LIKE /psyng/conflict-conid,
        description LIKE /psyng/conflict-description,
        conid_copied,
        conid_hdr_copied,
        conid_tc_copied,
        conid_txt_copied,
        message(100),
      END OF output.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-010.
SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: conids FOR /psyng/conflict-conid.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: rfc LIKE rfcdes-rfcdest MATCHCODE OBJECT /psyng/sw_rfcsh
OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK blk1.

SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-022.
PARAMETERS : trgvrsio LIKE /psyng/function-vrsio. "target sod version
PARAMETERS : srcvrsio LIKE /psyng/function-vrsio. "source sod version
SELECTION-SCREEN: END OF BLOCK blk2.


INITIALIZATION.
  PERFORM initialization.

AT SELECTION-SCREEN.
  IF NOT rfc IS INITIAL.
    SELECT SINGLE rfcdest INTO rfcdes-rfcdest FROM rfcdes
                  WHERE rfcdest = rfc.
    IF sy-subrc NE 0.
      MESSAGE e208(00) WITH text-000.
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
  gs_program = sy-repid.

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
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CONIDS'
    DESTINATION rfc
       EXPORTING
            vrsio    = srcvrsio
       TABLES
            conflict = conflict
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


  LOOP AT conflict WHERE conid IN conids.

    CLEAR output.
    MOVE-CORRESPONDING conflict TO output.


    CALL FUNCTION '/PSYNG/SW_CR_COPY_REMOTE_CONID'
         EXPORTING
              sourceconflictid             = conflict-conid
              sourcevrsio                  = srcvrsio
              targetconflictid             = conflict-conid
              targetvrsio                  = trgvrsio
              rfcdest                      = rfc
         IMPORTING
              conid_copied                 = output-conid_copied
              conid_hdr_copied             = output-conid_hdr_copied
              conid_tc_copied              = output-conid_tc_copied
              conid_txt_copied             = output-conid_txt_copied
         EXCEPTIONS
              target_not_specified         = 1
              target_already_exists        = 2
              not_authorized               = 3
              source_conflict_doesnt_exist = 4
              not_authorized_to_display    = 5
              dependent_funid_doesnt_exist = 6
              invalid_rfc                  = 7
              OTHERS                       = 8.

    CASE sy-subrc .
      WHEN 0.
        output-message = text-001.
      WHEN 1.
        output-message = text-002.
      WHEN 2.
        output-message = text-003.
      WHEN 3.
        output-message = text-004.
      WHEN 4.
        output-message = text-005.
      WHEN 5.
        output-message = text-006.
      WHEN 6.
        output-message = text-007.
      WHEN 7.
        output-message = text-008.
      WHEN 8.
        output-message = text-009.
    ENDCASE.

** program is not allowing to import only functions for a conflict that
** is already exist in the local system
** so for new conflict conid_hdr_copied flag will always be 'N'
** Hence for new conflict ID if whole conflict is copied then headr also
** get copied.

    IF output-conid_copied = 'Y'.
      output-conid_hdr_copied = 'Y'.
    ENDIF.

    APPEND output.

  ENDLOOP.

  PERFORM build_sort_table.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.

*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialization.
  DATA: dflt_rfc LIKE /psyng/swconfig-value.
  se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
  IF NOT dflt_rfc IS INITIAL.
    rfc = dflt_rfc.
  ENDIF.
ENDFORM.                    " initialization
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

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

  wa_fieldcat_alv-seltext_l = text-013.
  wa_fieldcat_alv-seltext_m = text-014.
  wa_fieldcat_alv-seltext_s = text-014.
  wa_fieldcat_alv-reptext_ddic = text-013.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONID_COPIED'.

  wa_fieldcat_alv-seltext_l = text-015.
  wa_fieldcat_alv-seltext_m = text-016.
  wa_fieldcat_alv-seltext_s = text-016.
  wa_fieldcat_alv-reptext_ddic = text-015.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONID_HDR_COPIED'.

  wa_fieldcat_alv-seltext_l = text-017.
  wa_fieldcat_alv-seltext_m = text-017.
  wa_fieldcat_alv-seltext_s = text-018.
  wa_fieldcat_alv-reptext_ddic = text-017.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONID_TC_COPIED'.

  wa_fieldcat_alv-seltext_l = text-019.
  wa_fieldcat_alv-seltext_m = text-019.
  wa_fieldcat_alv-seltext_s = text-020.
  wa_fieldcat_alv-reptext_ddic = text-019.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONID_TXT_COPIED'.

  wa_fieldcat_alv-seltext_l = text-021.
  wa_fieldcat_alv-seltext_m = text-021.
  wa_fieldcat_alv-seltext_s = text-021.
  wa_fieldcat_alv-reptext_ddic = text-021.
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
FORM output_using_alv.
  DATA: alv_layout TYPE slis_layout_alv.

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
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " build_sort_table
