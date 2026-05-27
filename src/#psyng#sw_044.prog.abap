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
TABLES: /psyng/critcodes, rfcdes.

TYPE-POOLS: slis.                                        "For ALV call
DATA: gs_program LIKE sy-repid.                           "For ALV call
DATA: i_fieldcat_alv1 TYPE slis_t_fieldcat_alv,           "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,           "For ALV call
      alv_layout     TYPE slis_layout_alv.               "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort TYPE slis_sortinfo_alv,
      gs_variant TYPE disvariant.
DATA: BEGIN OF output OCCURS 0.
        INCLUDE STRUCTURE /psyng/critcodes.
DATA: END OF output.

DATA: return TYPE bapireturn.

SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE blktl.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.                      "RFC destinations
SELECTION-SCREEN COMMENT 4(23) rfccom.
PARAMETERS: rfc LIKE rfcdes-rfcdest OBLIGATORY MATCHCODE OBJECT
/psyng/sw_rfcsh.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk1.
SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-021.
PARAMETERS : trgvrsio LIKE /psyng/function-vrsio. "target sod version
PARAMETERS : srcvrsio LIKE /psyng/function-vrsio. "source sod version
SELECTION-SCREEN: END OF BLOCK blk2.

INITIALIZATION.
  PERFORM initialization.

AT SELECTION-SCREEN.
  IF NOT rfc IS INITIAL.
    SELECT SINGLE * FROM rfcdes WHERE rfcdest = rfc.
    IF sy-subrc NE 0.
      MESSAGE e208(00) WITH text-000.
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

  CALL FUNCTION '/PSYNG/SW_CR_COPY_REM_CRITCODS'
       EXPORTING
            sourcevrsio              = srcvrsio
            targetvrsio              = trgvrsio
            rfcdest                  = rfc
       IMPORTING
            return                   = return
       TABLES
            critcodes                = output
       EXCEPTIONS
            not_authorized_to_import = 1
            no_auth_to_read_source   = 2
            invalid_rfc              = 3
            source_list_empty        = 4
            OTHERS                   = 5.

  CASE sy-subrc.
    WHEN 0.
      IF return-type = 'W'.
        MESSAGE i208(00) WITH return-message.
      ELSE.
        MESSAGE i208(00) WITH text-001.
      ENDIF.
    WHEN 1.
      MESSAGE i208(00) WITH text-002.
    WHEN 2.
      MESSAGE i208(00) WITH text-003.
    WHEN 3.
      MESSAGE i208(00) WITH text-004.
    WHEN 4.
      MESSAGE i208(00) WITH text-005.
    WHEN 5.
      MESSAGE i208(00) WITH text-006.
    WHEN OTHERS.
      MESSAGE i208(00) WITH text-006.
  ENDCASE.

  CHECK sy-subrc = 0 AND NOT ( output[] IS INITIAL ) .

  PERFORM build_alv_catalog1.
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
  DATA: dflt_rfc LIKE /psyng/swconfig-value.
    se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
  IF NOT dflt_rfc IS INITIAL.
    rfc = dflt_rfc.
  ENDIF.

  MOVE text-007 TO blktl.
  MOVE text-008 TO rfccom.
ENDFORM.                    " initialization
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog1.

  gs_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = gs_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = gs_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv1
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
*            it_sort            = isort
            is_layout          = alv_layout
            i_save             = 'A'
            is_variant         = gs_variant
            it_fieldcat        = i_fieldcat_alv1
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
