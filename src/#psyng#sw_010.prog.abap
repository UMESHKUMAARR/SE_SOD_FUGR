REPORT /psyng/sw_010 .

TABLES: agr_tcodes, tstc.

TYPE-POOLS: slis, sscr.                               "For ALV call
DATA: g_program         LIKE sy-repid.                "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv,        "For ALV call
      gs_variant     TYPE disvariant,                 "For ALV call
      gs_alv_layout  TYPE slis_layout_alv.            "For ALV call
DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
      gt_sort         TYPE slis_t_sortinfo_alv,
      gs_sort         TYPE slis_sortinfo_alv.

TYPES: BEGIN OF tcodes_typ,
         tcode LIKE agr_tcodes-tcode,
       END OF tcodes_typ.
DATA: wa_tcodes TYPE tcodes_typ.

TYPES: BEGIN OF functtran_typ,
         tcode      LIKE /psyng/functtran-tcode,
         functionid LIKE /psyng/functtran-functionid,
       END OF functtran_typ.

TYPES: BEGIN OF itstct_typ,
         tcode LIKE tstct-tcode,
         text  LIKE tstct-ttext,
       END OF itstct_typ.
DATA: ls_itstct TYPE itstct_typ.

DATA: BEGIN OF gt_function OCCURS 0,
        function    TYPE /psyng/function-function,
        description TYPE /psyng/function-description,
      END OF gt_function.

DATA: gt_functtran TYPE TABLE OF functtran_typ WITH HEADER LINE.

DATA: gt_agrtcodes TYPE HASHED TABLE OF tcodes_typ WITH UNIQUE KEY
            tcode
            WITH HEADER LINE.
DATA: gt_itstct TYPE HASHED TABLE OF itstct_typ WITH UNIQUE KEY
            tcode
            WITH HEADER LINE.

DATA: BEGIN OF notinsod OCCURS 0.
DATA: tcode LIKE tstc-tcode,
      text  LIKE tstct-ttext.
DATA: END OF notinsod.

DATA: BEGIN OF notinrole OCCURS 0,
        tcode       LIKE tstc-tcode,
        text        LIKE tstct-ttext,
        function    LIKE /psyng/function-function,
        description LIKE /psyng/function-description,
      END OF notinrole.

DATA restrict TYPE sscr_restrict.
DATA : optlist TYPE sscr_opt_list,
       ass     TYPE sscr_ass.


*-------------------  SELECTION STATEMENTS   --------------------------*
SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_rolnam FOR agr_tcodes-agr_name.      "Role Name(s)
PARAMETERS: p_sodver LIKE /psyng/conflict-vrsio.       "SOD Version
SELECT-OPTIONS: s_tcodes FOR tstc-tcode NO INTERVALS.  "Transaction Code
PARAMETERS: p_inrole RADIOBUTTON GROUP 1 DEFAULT 'X',
            p_insod  RADIOBUTTON GROUP 1.
SELECTION-SCREEN END OF BLOCK blk1.


*------------------------   INITIALIZATION   --------------------------*
INITIALIZATION.
  PERFORM define_restriction."Simplifies the handling of SELECT-OPTIONS


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
  SELECT DISTINCT tcode INTO TABLE gt_agrtcodes FROM agr_tcodes
           WHERE type     EQ 'TR'          "Transactions
               AND agr_name IN s_rolnam.  "Role Name(s)
*SW: Functions and Transactions
  SELECT tcode functionid INTO TABLE gt_functtran FROM /psyng/functtran
         WHERE vrsio EQ p_sodver.         "SOD Version

  SORT gt_functtran BY tcode functionid.

  LOOP AT gt_agrtcodes.
    READ TABLE gt_functtran WITH KEY tcode = gt_agrtcodes-tcode
                                                          BINARY SEARCH.
    IF sy-subrc <> 0.
      notinsod-tcode = gt_agrtcodes-tcode.
      APPEND notinsod.
    ENDIF.
  ENDLOOP.

* NOTE: For performance reason do this look-up in two steps.
*  Report Duration: from 564,933 to 412,600
*  SELECT tcode ttext INTO TABLE gt_itstct FROM tstct
*           WHERE sprsl = sy-langu.
  IF notinsod[] IS NOT INITIAL.
    SELECT tcode ttext INTO TABLE gt_itstct FROM tstct
              FOR ALL ENTRIES IN notinsod
               WHERE tcode EQ notinsod-tcode
                 AND sprsl EQ sy-langu.
  ENDIF.

  LOOP AT notinsod.
    READ TABLE gt_itstct WITH TABLE KEY tcode = notinsod-tcode.
    IF sy-subrc = 0.
      notinsod-text = gt_itstct-text.
      MODIFY notinsod.
    ENDIF.
  ENDLOOP.

* Build the NOT-IN-ROLE internal table.
  LOOP AT gt_functtran.
    READ TABLE gt_agrtcodes WITH TABLE KEY tcode = gt_functtran-tcode.
    IF sy-subrc NE 0.
      notinrole-tcode = gt_functtran-tcode.
      notinrole-function = gt_functtran-functionid.
      APPEND notinrole.
    ENDIF.
  ENDLOOP.

  IF notinrole[] IS NOT INITIAL.
    SORT notinrole.
    DELETE ADJACENT DUPLICATES FROM notinrole COMPARING tcode function.
    REFRESH gt_itstct. CLEAR gt_itstct.
    SELECT tcode ttext INTO TABLE gt_itstct FROM tstct
                  FOR ALL ENTRIES IN notinrole
                  WHERE tcode EQ notinrole-tcode
                    AND sprsl EQ sy-langu.
  ENDIF.

  LOOP AT notinrole.
    AT FIRST.
      IF NOT notinrole[] IS INITIAL.
        SELECT function description                  "#EC CI_SEL_NESTED
            INTO TABLE gt_function
               FROM /psyng/function FOR ALL ENTRIES IN notinrole
               WHERE function = notinrole-function
                 AND vrsio    = p_sodver.
        SORT gt_function BY function.
      ENDIF.
    ENDAT.

    CLEAR: gt_itstct-text, gt_function-description.
    READ TABLE gt_itstct WITH TABLE KEY tcode = notinrole-tcode.

    READ TABLE gt_function WITH KEY function = notinrole-function
                           BINARY SEARCH.

    notinrole-description = gt_function-description.
    notinrole-text = gt_itstct-text.
    MODIFY notinrole.
  ENDLOOP.

  g_program = sy-repid.
  gs_alv_layout-zebra = 'X'.
  gs_alv_layout-colwidth_optimize = 'X'.

*LOOP AT notinrole.
*  IF notinrole-tcode CS 'F'.
*    notinrole-linecolor = 'C200'.
*    MODIFY notinrole.
*  ENDIF.
*ENDLOOP.

  IF p_inrole = 'X'.
    SORT notinrole.
    IF NOT s_tcodes IS INITIAL.
      DELETE notinrole WHERE tcode IN s_tcodes.
    ENDIF.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = g_program
        i_internal_tabname = 'NOTINROLE'
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


    wa_fieldcat_alv-emphasize = 'C210'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        emphasize
                     WHERE
                        fieldname = 'TCODE'.

    gs_sort-spos      = '1'.
    gs_sort-tabname   = 'NOTINROLE'.
    gs_sort-fieldname = 'TCODE'.
    gs_sort-up        = 'X'.
    APPEND gs_sort TO gt_sort.
    gs_sort-spos      = '2'.
    gs_sort-fieldname = 'TEXT'.
    APPEND gs_sort TO gt_sort.
    gs_sort-spos      = '3'.
    gs_sort-fieldname = 'FUNCTION'.
    APPEND gs_sort TO gt_sort.
    gs_sort-spos      = '4'.
    gs_sort-fieldname = 'DESCRIPTION'.
    APPEND gs_sort TO gt_sort.

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program      = g_program
        i_grid_title            = text-000
        i_callback_user_command = 'USER_DOUBLE_CLICK_ON_SUMRY'
        is_layout               = gs_alv_layout
        it_fieldcat             = i_fieldcat_alv
        it_sort                 = gt_sort
        i_save                  = 'A'
        is_variant              = gs_variant
      TABLES
        t_outtab                = notinrole
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  ELSE.
    SORT notinsod.
    IF NOT s_tcodes IS INITIAL.
      DELETE notinsod WHERE tcode IN s_tcodes.
    ENDIF.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = g_program
        i_internal_tabname = 'NOTINSOD'
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

    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program      = g_program
        i_grid_title            = text-001
        i_callback_user_command = 'USER_DOUBLE_CLICK_ON_SUMRY'
        is_layout               = gs_alv_layout
        it_fieldcat             = i_fieldcat_alv
        i_save                  = 'A'
        is_variant              = gs_variant
      TABLES
        t_outtab                = notinsod
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDIF.

*---------------------------------------------------------------------*
*       FORM USER_DOUBLE_CLICK_ON_SUMRY                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                  rs_selfield TYPE slis_selfield.
  DATA: l_line(80),
        l_answer,
        l_value(40).

  CASE rs_selfield-fieldname.
    WHEN 'TCODE'.
      SELECT SINGLE ttext FROM tstct INTO l_line
                    WHERE sprsl = sy-langu
                      AND tcode = rs_selfield-value.

      IF sy-subrc <> 0.
        MESSAGE i020(/psyng/sw) WITH rs_selfield-value.
        EXIT.
      ENDIF.
      l_value = rs_selfield-value.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = rs_selfield-value
          text_question         = l_line
          text_button_1         = text-003
          icon_button_1         = 'ICON_EXECUTE_OBJECT'
          text_button_2         = text-004
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = ' '
        IMPORTING
          answer                = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      CHECK l_answer = '1'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD l_value.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH rs_selfield-value.
      ELSE.
        CALL TRANSACTION rs_selfield-value."#EC PATHLOCK_CI_DYN_ACCES

      ENDIF.
  ENDCASE.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DEFINE_RESTRICTION
*&---------------------------------------------------------------------*
*       Display "Exclude Single Values" tab only
*----------------------------------------------------------------------*
FORM define_restriction .

* Restricting the TCODE selection to only NE, NB and 'NB'.
  optlist-name = 'EXTCODES'.
  optlist-options-eq = 'X'.
  APPEND optlist TO restrict-opt_list_tab.

  ass-kind = 'S'.
  ass-name = 'S_TCODES'.
  ass-sg_main = 'I'.
  ass-sg_addy = space.
  ass-op_main = 'EXTCODES'.
  APPEND ass TO restrict-ass_tab.

  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
      program                = sy-repid
      restriction            = restrict
    EXCEPTIONS
      too_late               = 1
      repeated               = 2
      selopt_without_options = 3
      selopt_without_signs   = 4
      invalid_sign           = 5
      empty_option_list      = 6
      invalid_kind           = 7
      repeated_kind_a        = 8
      OTHERS                 = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.
