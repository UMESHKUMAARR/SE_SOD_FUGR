*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_LOCCFGF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_data_100
*&---------------------------------------------------------------------*
*       Get data from database for table /PSYNG/ORGNR_UG
*----------------------------------------------------------------------*
FORM get_data_100.
  PERFORM enqueue.
  SELECT * INTO TABLE gt_orgnr_ug FROM /psyng/orgnr_ug.
*20110719 - SF Case 1802
  sort gt_orgnr_ug.
ENDFORM.                    " get_data_100

*&---------------------------------------------------------------------*
*&      Form  get_data_200
*&---------------------------------------------------------------------*
*       Get data from database for table /PSYNG/ORGNR_ADR
*----------------------------------------------------------------------*
FORM get_data_200.
  PERFORM enqueue.
  SELECT * INTO TABLE gt_orgnr_adr FROM /psyng/orgnr_adr.
*20110719 - SF Case 1802
  sort gt_orgnr_adr.

ENDFORM.                    " get_data_200

*&---------------------------------------------------------------------*
*&      Form  get_data_300
*&---------------------------------------------------------------------*
*       Get data from database for table /PSYNG/SW_LOCCFG
*----------------------------------------------------------------------*
FORM get_data_300.
  PERFORM enqueue.
  SELECT * INTO TABLE gt_loccfg FROM /psyng/sw_loccfg.
*20110719 - SF Case 1802
  sort gt_loccfg.

ENDFORM.                    " get_data_300

*&---------------------------------------------------------------------*
*&      Form  get_data_400
*&---------------------------------------------------------------------*
*       Get data from database for table /PSYNG/ORGNR_USR
*----------------------------------------------------------------------*
FORM get_data_400.
  PERFORM enqueue.
  SELECT * INTO TABLE gt_orgnr_usr FROM /psyng/orgnr_usr.
*20110719 - SF Case 1802
  sort gt_orgnr_usr.
ENDFORM.                    " get_data_400

*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       Lock table for editing
*----------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = g_tabname
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc = 0.
    g_mode = 'C'.                      "Change mode
  ELSE.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    g_mode = 'D'.                      "Display mode
  ENDIF.
ENDFORM.                    " enqueue

*&---------------------------------------------------------------------*
*&      Form  dequeue
*&---------------------------------------------------------------------*
*       Unlock table
*----------------------------------------------------------------------*
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = g_tabname.
ENDFORM.                    " dequeue

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                         p_table_name
                         p_mark_name
                CHANGING p_ok      LIKE sy-ucomm.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA: l_ok              TYPE sy-ucomm,
        l_offset          TYPE i,
        lf_answer(1)      TYPE c.
*-END OF LOCAL DATA----------------------------------------------------*

* Table control specific operations                                    *
*   evaluate TC name and operations                                    *
  SEARCH p_ok FOR p_tc_name.
  IF sy-subrc = 0.
    l_offset = strlen( p_tc_name ) + 1.
    l_ok = p_ok+l_offset.
  ELSE.
    l_ok = p_ok.
  ENDIF.

* execute general and TC specific operations                           *
  CASE l_ok.
    WHEN 'INSR'.                      "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name.
      CLEAR p_ok.

    WHEN 'DELE'.                      "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'UPLD' OR 'DWNLD'.           "upload or download

*********** 29-08-2008 changed by sgottapu ***************

      Clear g_filename.
      CALL SCREEN 9000 STARTING AT 3 3 ENDING AT 120 8.

*********** 29-08-2008 changed by sgottapu ***************

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            l_ok.
      CLEAR p_ok.

    WHEN 'SELALL'.                     "Select all records
      PERFORM select_all USING p_table_name p_mark_name.

    WHEN 'DESELALL'.                   "Deselect all records
      PERFORM deselect_all USING p_table_name p_mark_name.

    WHEN 'SAVE'.
      PERFORM save_data.

    WHEN 'EXIT'.
      PERFORM confirm_exit CHANGING lf_answer.
      CHECK lf_answer = '1'.
      PERFORM dequeue.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_lastline         TYPE i.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
                 "not headerline

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get current line
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line and new cursor line                           *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
    l_lastline = <tc>-top_line + <lines> - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.
* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
  <tc>-lines = <tc>-lines + 1.
* set cursor
  SET CURSOR LINE l_line.

ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name   .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* delete marked lines                                                  *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.

  gf_data_change = 'X'.
ENDFORM.                              " FCODE_DELETE_ROW

*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
FORM compute_scrolling_in_tc USING    p_tc_name
                                      p_ok.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.

  ASSIGN (l_tc_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)


* is no line filled?                                                   *
  IF <tc>-lines = 0.
*   yes, ...                                                           *
    l_tc_new_top_line = 1.
  ELSE.
*   no, ...                                                            *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
         EXPORTING
              entry_act             = <tc>-top_line
              entry_from            = 1
              entry_to              = <tc>-lines
              last_page_full        = 'X'
              loops                 = <lines>
              ok_code               = p_ok
              overlapping           = 'X'
         IMPORTING
              entry_new             = l_tc_new_top_line
*BOC:HBHALLA (04/12/24)
    EXCEPTIONS
        NO_ENTRY_OR_PAGE_ACT  = 1
        NO_ENTRY_TO           = 2
        NO_OK_CODE_OR_PAGE_GO = 3
            OTHERS            = 4 .
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw)
         WITH 'no start index or page specified'.
         WHEN 2.
            MESSAGE s002(/psyng/sw)
         WITH 'End of table substructure is zero'.
         WHEN 3.
            MESSAGE s002(/psyng/sw)
         WITH 'no function code or target page specified'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
  ENDIF.

* get actual tc and column                                             *
  GET CURSOR FIELD l_tc_field_name
             AREA  l_tc_name.

  IF syst-subrc = 0.
    IF l_tc_name = p_tc_name.
*     set actual column                                                *
      SET CURSOR FIELD l_tc_field_name LINE 1.
    ENDIF.
  ENDIF.

* set the new top line                                                 *
  <tc>-top_line = l_tc_new_top_line.


ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  select_all
*&---------------------------------------------------------------------*
*       Select all records
*----------------------------------------------------------------------*
*      -->I_TABLE_NAME  Internal table name
*      -->I_MARK_NAME   Mark field name
*----------------------------------------------------------------------*
FORM select_all USING    i_table_name
                         i_mark_name.

  DATA: l_table_name LIKE feld-name.

  FIELD-SYMBOLS: <table> TYPE STANDARD TABLE,
                 <wa>,
                 <mark_field>.

* get the table, which belongs to the tc                               *
  CONCATENATE i_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

  LOOP AT <table> ASSIGNING <wa>.
*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT i_mark_name OF STRUCTURE <wa> TO <mark_field>.
    <mark_field> = 'X'.
  ENDLOOP.
ENDFORM.                    " select_all

*&---------------------------------------------------------------------*
*&      Form  deselect_all
*&---------------------------------------------------------------------*
*       Deselect all records
*----------------------------------------------------------------------*
*      -->I_TABLE_NAME  Internal table name
*      -->I_MARK_NAME   Mark field name
*----------------------------------------------------------------------*
FORM deselect_all USING    i_table_name
                           i_mark_name.

  DATA: l_table_name LIKE feld-name.

  FIELD-SYMBOLS: <table> TYPE STANDARD TABLE,
                 <wa>,
                 <mark_field>.

* get the table, which belongs to the tc                               *
  CONCATENATE i_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

  LOOP AT <table> ASSIGNING <wa>.
*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT i_mark_name OF STRUCTURE <wa> TO <mark_field>.
    CLEAR <mark_field>.
  ENDLOOP.
ENDFORM.                    " deselect_all

*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       Save data to database
*----------------------------------------------------------------------*
FORM save_data.
DATA: lt_orgnr_ug  LIKE /psyng/orgnr_ug,
      lt_orgnr_adr LIKE /psyng/orgnr_adr,
      lt_orgnr_usr LIKE /psyng/orgnr_usr,
      lt_loccfg    LIKE /psyng/sw_loccfg.

*BOC UMITTAL PN11269 ATC fixes
CASE g_tabname.
  WHEN '/PSYNG/ORGNR_UG'.
    DELETE FROM /psyng/orgnr_ug
      WHERE class NE space.
  WHEN '/PSYNG/ORGNR_ADR'.
    DELETE FROM /psyng/orgnr_adr
      WHERE ADDRNUMBER NE space.
  WHEN '/PSYNG/ORGNR_USR'.
    DELETE FROM /PSYNG/ORGNR_USR
      WHERE BNAME NE space.
  WHEN '/PSYNG/SW_LOCCFG'.
    DELETE FROM /PSYNG/SW_LOCCFG
      WHERE PARAM NE space.
ENDCASE.

* Since there's not much data, delete everything and re-add
*  DELETE FROM (g_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(12/12/24)
*   CLIENT SPECIFIED WHERE mandt = sy-mandt.
*EOC UMITTAL PN11269 ATC fixes

  CASE g_tabname.
    WHEN '/PSYNG/ORGNR_UG'.
      LOOP AT gt_orgnr_ug.
        lt_orgnr_ug = gt_orgnr_ug.
        INSERT INTO /psyng/orgnr_ug    "#EC CI_IMUD_NESTED
          VALUES lt_orgnr_ug.
      ENDLOOP.

    WHEN '/PSYNG/ORGNR_ADR'.
      LOOP AT gt_orgnr_adr.
        lt_orgnr_adr = gt_orgnr_adr.
        INSERT INTO /psyng/orgnr_adr   "#EC CI_IMUD_NESTED
          VALUES lt_orgnr_adr.
      ENDLOOP.

    WHEN '/PSYNG/ORGNR_USR'.
      LOOP AT gt_orgnr_usr.
        lt_orgnr_usr = gt_orgnr_usr.
        INSERT INTO /psyng/orgnr_usr     "#EC CI_IMUD_NESTED
             VALUES lt_orgnr_usr.
      ENDLOOP.

    WHEN '/PSYNG/SW_LOCCFG'.
      LOOP AT gt_loccfg.
        lt_loccfg = gt_loccfg.
        INSERT INTO /psyng/sw_loccfg    "#EC CI_IMUD_NESTED
           VALUES lt_loccfg.
      ENDLOOP.
  ENDCASE.

  CLEAR gf_data_change.
ENDFORM.                    " save_data
*&---------------------------------------------------------------------*
*&      Form  f4_addrnumber
*&---------------------------------------------------------------------*
*       F4 Value help for Address number
*----------------------------------------------------------------------*
*      <--E_ADDRNUMBER  Address number
*----------------------------------------------------------------------*
FORM f4_addrnumber
                 CHANGING e_addrnumber TYPE /psyng/orgnr_adr-addrnumber.
DATA: BEGIN OF lt_values OCCURS 0,
        line(50) TYPE c,
      END OF lt_values.

DATA: BEGIN OF ls_uscompa,
        addrnumber TYPE v_uscompa-addrnumber,
        company    TYPE v_uscompa-company,
        name1      TYPE v_uscompa-name1,
        name2      TYPE v_uscompa-name2,
        city1      TYPE v_uscompa-city1,
      END OF ls_uscompa.

DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
      lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.


  lt_fields-tabname   = 'V_USCOMPA'.
  lt_fields-fieldname = 'ADDRNUMBER'.
  APPEND lt_fields.
  lt_fields-fieldname = 'COMPANY'.
  APPEND lt_fields.
  lt_fields-fieldname = 'NAME1'.
  APPEND lt_fields.
  lt_fields-fieldname = 'NAME2'.
  APPEND lt_fields.
  lt_fields-fieldname = 'CITY1'.
  APPEND lt_fields.

* Get values for popup
  SELECT addrnumber company name1 name2 city1 INTO ls_uscompa
         FROM v_uscompa."#EC SAST_CI_GEN_CHECK

    lt_values-line = ls_uscompa-addrnumber.
    APPEND lt_values.
    lt_values-line = ls_uscompa-company.
    APPEND lt_values.
    lt_values-line = ls_uscompa-name1.
    APPEND lt_values.
    lt_values-line = ls_uscompa-name2.
    APPEND lt_values.
    lt_values-line = ls_uscompa-city1.
    APPEND lt_values.
  ENDSELECT.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield               = 'ADDRNUMBER'
    TABLES
      value_tab              = lt_values
      field_tab              = lt_fields
      return_tab             = lt_return
    EXCEPTIONS
      parameter_error        = 1
      no_values_found        = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
   MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_addrnumber = lt_return-fieldval.
ENDFORM.                    " f4_addrnumber

*&---------------------------------------------------------------------*
*&      Form  validate_100
*&---------------------------------------------------------------------*
*       Validations for screen 100
*----------------------------------------------------------------------*
FORM validate_100.
DATA: ls_orgnr_ug LIKE gt_orgnr_ug.

* Check user group
  SELECT SINGLE mandt INTO sy-mandt FROM usgrp
                WHERE usergroup = gt_orgnr_ug-class.
  IF sy-subrc <> 0.
    MESSAGE e100.
  ENDIF.

* Check for duplicates
  LOOP AT gt_orgnr_ug INTO ls_orgnr_ug WHERE class = gt_orgnr_ug-class.
    IF sy-tabix <> tc_orgnr_ug-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " validate_100

*&---------------------------------------------------------------------*
*&      Form  validate_200
*&---------------------------------------------------------------------*
*       Validations for screen 200
*----------------------------------------------------------------------*
FORM validate_200.
DATA: ls_orgnr_adr LIKE gt_orgnr_adr.

  CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
    EXPORTING
      input         = gt_orgnr_adr-addrnumber
    IMPORTING
      output        = gt_orgnr_adr-addrnumber.

* Check address number
  SELECT SINGLE mandt INTO sy-mandt FROM v_uscompa
   WHERE addrnumber = gt_orgnr_adr-addrnumber."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    MESSAGE e100.
  ENDIF.

* Check for duplicates
  LOOP AT gt_orgnr_adr INTO ls_orgnr_adr
          WHERE addrnumber = gt_orgnr_adr-addrnumber.
    IF sy-tabix <> tc_orgnr_adr-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " validate_200

*&---------------------------------------------------------------------*
*&      Form  validate_300
*&---------------------------------------------------------------------*
*       Validations for screen 300
*----------------------------------------------------------------------*
FORM validate_300.
DATA: ls_loccfg LIKE gt_loccfg.

* Check for duplicates
  LOOP AT gt_loccfg INTO ls_loccfg
          WHERE param = gt_loccfg-param.
    IF sy-tabix <> tc_loccfg-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " validate_300

*&---------------------------------------------------------------------*
*&      Form  validate_400
*&---------------------------------------------------------------------*
*       Validations for screen 400
*----------------------------------------------------------------------*
FORM validate_400.
DATA: ls_orgnr_usr LIKE gt_orgnr_usr.

* Check user ID
  SELECT SINGLE mandt INTO sy-mandt FROM usr02
                WHERE bname = gt_orgnr_usr-bname.
  IF sy-subrc <> 0.
    MESSAGE e100.
  ENDIF.

* Check for duplicates
  LOOP AT gt_orgnr_usr INTO ls_orgnr_usr
          WHERE bname = gt_orgnr_usr-bname.
    IF sy-tabix <> tc_orgnr_usr-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " validate_400

*&---------------------------------------------------------------------*
*&      Form  toggle_display_change
*&---------------------------------------------------------------------*
*       Set screen attributes for Display/Change mode
*----------------------------------------------------------------------*
FORM toggle_display_change.
  IF g_mode = 'D'.                     "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                "Change
    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " toggle_display_change

*&---------------------------------------------------------------------*
*&      Form  upload_file
*&---------------------------------------------------------------------*
*       Upload from file
*----------------------------------------------------------------------*
FORM upload_file.
*CONSTANTS: lc_readfile_func TYPE rs38l-name VALUE '/PSYNG/BASIS_70_001'
*.

DATA: lt_import    TYPE TABLE OF string,
      l_import     TYPE string,
      l_orgnr      TYPE /psyng/orgnr,
      l_class      TYPE /psyng/orgnr_ug-class,
      l_addrnumber TYPE /psyng/orgnr_adr-addrnumber,
      l_bname      TYPE /psyng/orgnr_usr-bname,
      l_param      TYPE /psyng/sw_loccfg-param,
      l_value      TYPE /psyng/sw_loccfg-value,
      l_readsubrc  TYPE sysubrc,
      l_msg        TYPE string.


*  CASE 'X'.
*    WHEN gf_serverfile.                "Server file
*      CALL FUNCTION 'FUNCTION_EXISTS'
*        EXPORTING
*          funcname                 = lc_readfile_func
*        EXCEPTIONS
*         function_not_exist       = 1
*         OTHERS                   = 2.
*
*      IF sy-subrc = 0 and sy-SAPRL(1) > '4'.
*        CALL FUNCTION lc_readfile_func
*          EXPORTING
*            i_path               = g_filename
*          IMPORTING
*            return_code          = l_readsubrc
*            return_message       = l_msg
*          TABLES
*            contents            = lt_import.
*      ELSE.
*       CALL FUNCTION '/PSYNG/BASIS_46_001'
*         EXPORTING
*           i_path               = g_filename
*         IMPORTING
*           return_code          = l_readsubrc
*           return_message       = l_msg
*         TABLES
*           contents             = lt_import.
*      ENDIF.
*
*      IF l_readsubrc <> 0.
*        MESSAGE e113 WITH l_msg.
*      ENDIF.
*
*    WHEN gf_localfile.                 "Local file
*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
      CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
        EXPORTING
          filename                      = g_filename
          has_field_separator           = gc_delimit
        TABLES
          data_tab                      = lt_import
        EXCEPTIONS
          OTHERS                        = 1.
      IF sy-subrc <> 0.
        MESSAGE e133 WITH g_filename.
      ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
*  ENDCASE.

  CASE g_tabname.
    WHEN '/PSYNG/ORGNR_UG'.
      LOOP AT lt_import INTO l_import.
        SPLIT l_import AT gc_delimit INTO l_class l_orgnr.
        READ TABLE gt_orgnr_ug WITH KEY class = l_class.
        IF sy-subrc = 0.
          gt_orgnr_ug-orgnr = l_orgnr.
          MODIFY gt_orgnr_ug INDEX sy-tabix.
        ELSE.
*         Check user group
          SELECT SINGLE mandt INTO sy-mandt FROM usgrp
                        WHERE usergroup = l_class.
          IF sy-subrc <> 0.
            MESSAGE e113 WITH text-e01 text-001 l_class.
          ENDIF.

          gt_orgnr_ug-class = l_class.
          gt_orgnr_ug-orgnr = l_orgnr.
          APPEND gt_orgnr_ug.
        ENDIF.
      ENDLOOP.

      SORT gt_orgnr_ug BY class.

    WHEN '/PSYNG/ORGNR_ADR'.
      LOOP AT lt_import INTO l_import.
        SPLIT l_import AT gc_delimit INTO l_addrnumber l_orgnr.

        CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
          EXPORTING
            input         = l_addrnumber
          IMPORTING
            output        = l_addrnumber.

        READ TABLE gt_orgnr_adr WITH KEY addrnumber = l_addrnumber.
        IF sy-subrc = 0.
          gt_orgnr_adr-orgnr = l_orgnr.
          MODIFY gt_orgnr_adr INDEX sy-tabix.
        ELSE.
*         Check address number
          SELECT SINGLE mandt INTO sy-mandt        "#EC CI_SEL_NESTED
                    FROM v_uscompa
         WHERE addrnumber = l_addrnumber."#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            MESSAGE e113 WITH text-e01 text-002 l_addrnumber.
          ENDIF.

          gt_orgnr_adr-addrnumber = l_addrnumber.
          gt_orgnr_adr-orgnr      = l_orgnr.
          APPEND gt_orgnr_adr.
        ENDIF.
      ENDLOOP.

      SORT gt_orgnr_adr BY addrnumber.

    WHEN '/PSYNG/ORGNR_USR'.
      LOOP AT lt_import INTO l_import.
        SPLIT l_import AT gc_delimit INTO l_bname l_orgnr.
        READ TABLE gt_orgnr_usr WITH KEY bname = l_bname.
        IF sy-subrc = 0.
          gt_orgnr_usr-orgnr = l_orgnr.
          MODIFY gt_orgnr_usr INDEX sy-tabix.
        ELSE.
*         Check user ID
          SELECT SINGLE mandt INTO sy-mandt FROM usr02
                        WHERE bname = l_bname.
          IF sy-subrc <> 0.
            MESSAGE e113 WITH text-e01 text-003 l_bname.
          ENDIF.

          gt_orgnr_usr-bname = l_bname.
          gt_orgnr_usr-orgnr = l_orgnr.
          APPEND gt_orgnr_usr.
        ENDIF.
      ENDLOOP.

      SORT gt_orgnr_usr BY bname.

    WHEN '/PSYNG/SW_LOCCFG'.
      LOOP AT lt_import INTO l_import.
        SPLIT l_import AT gc_delimit INTO l_param l_value.
        READ TABLE gt_loccfg WITH KEY param = l_param.
        IF sy-subrc = 0.
          gt_loccfg-value = l_value.
          MODIFY gt_loccfg INDEX sy-tabix.
        ELSE.
          gt_loccfg-param = l_param.
          gt_loccfg-value = l_value.
          APPEND gt_loccfg.
        ENDIF.
      ENDLOOP.

      SORT gt_loccfg BY param.
  ENDCASE.
ENDFORM.                    " upload_file

*&---------------------------------------------------------------------*
*&      Form  download_file
*&---------------------------------------------------------------------*
*       Download table to file
*----------------------------------------------------------------------*
FORM download_file.
*CONSTANTS: lc_writefile_func TYPE rs38l-name VALUE
*'/PSYNG/BASIS_70_002'
*.
DATA: l_out  TYPE string,
      lt_out TYPE TABLE OF string,
      l_writesubrc  TYPE sysubrc,
      l_msg        TYPE string.
      CASE g_tabname.
        WHEN '/PSYNG/ORGNR_UG'.
          LOOP AT gt_orgnr_ug.
            CONCATENATE gt_orgnr_ug-class gt_orgnr_ug-orgnr
                        INTO l_out SEPARATED BY gc_delimit.
            APPEND l_out TO lt_out.
          ENDLOOP.
        WHEN '/PSYNG/ORGNR_ADR'.
          LOOP AT gt_orgnr_adr.
            CONCATENATE gt_orgnr_adr-addrnumber gt_orgnr_adr-orgnr
                        INTO l_out SEPARATED BY gc_delimit.
            APPEND l_out TO lt_out.
          ENDLOOP.
        WHEN '/PSYNG/ORGNR_USR'.
          LOOP AT gt_orgnr_usr.
            CONCATENATE gt_orgnr_usr-bname gt_orgnr_usr-orgnr
                        INTO l_out SEPARATED BY gc_delimit.
            APPEND l_out TO lt_out.
          ENDLOOP.
        WHEN '/PSYNG/SW_LOCCFG'.
          LOOP AT gt_loccfg.
            CONCATENATE gt_loccfg-param gt_loccfg-value
                        INTO l_out SEPARATED BY gc_delimit.
            APPEND l_out TO lt_out.
          ENDLOOP.
      ENDCASE.

*  CASE 'X'.
*      when gf_localfile.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
      CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
        EXPORTING
          filename                      = g_filename
        TABLES
          data_tab                      = lt_out
        EXCEPTIONS
          OTHERS                        = 1.
      IF sy-subrc <> 0.
        MESSAGE e133 WITH g_filename.
      ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
*      when gf_serverfile.
*            CALL FUNCTION 'FUNCTION_EXISTS'
*        EXPORTING
*          funcname                 = lc_writefile_func
*        EXCEPTIONS
*         function_not_exist       = 1
*         OTHERS                   = 2.
*
*      IF sy-subrc = 0 and sy-SAPRL(1) > '4'.
*        CALL FUNCTION lc_writefile_func
*          EXPORTING
*            i_path               = g_filename
*          IMPORTING
*            return_code          = l_writesubrc
*            return_message       = l_msg
*          TABLES
*            contents            = lt_out.
*      ELSE.
*       CALL FUNCTION '/PSYNG/BASIS_46_002'
*         EXPORTING
*           i_path               = g_filename
*         IMPORTING
*           return_code          = l_writesubrc
*           return_message       = l_msg
*         TABLES
*           contents             = lt_out.
*      ENDIF.
*
*      IF l_writesubrc <> 0.
*        MESSAGE e113 WITH l_msg.
*      ENDIF.
*
*  ENDCASE.
ENDFORM.                    " download_file

*&---------------------------------------------------------------------*
*&      Form  confirm_exit
*&---------------------------------------------------------------------*
*       Confirm that the user wants to exit without saving
*----------------------------------------------------------------------*
*      -->E_ANSWER  Answer
*----------------------------------------------------------------------*
FORM confirm_exit USING    e_answer TYPE char1.
  e_answer = '1'.
  CHECK gf_data_change = 'X'.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            titlebar              = text-t02
            text_question         = text-q01
            text_button_1         = text-004
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-005
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '2'
            display_cancel_button = space
       IMPORTING
            answer                = e_answer
       EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Diagnosis text not found'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
ENDFORM.                    " confirm_exit
*&---------------------------------------------------------------------*
*&      Module  f4_FILE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

*********** 29-08-2008 changed by sgottapu *****************

module f4_FILE input.
 PERFORM f4_file CHANGING g_filename.
endmodule.                 " f4_FILE  INPUT

*********** 29-08-2008 changed by sgottapu *****************
*&---------------------------------------------------------------------*
*&      Form  f4_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_FILENAME  text
*----------------------------------------------------------------------*

*********** 29-08-2008 changed by sgottapu *****************

form f4_file changing p_g_filename.

  DATA : uaction TYPE i,
         title TYPE string,
         fn TYPE string,
         path TYPE string,
         filetable TYPE  filetable.
  IF ok_code = 'UPLD'.
    MOVE text-006 TO title.
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      window_title      = title
      default_extension = 'txt'
      default_filename  = 'test'
      initial_directory = 'c:\temp'
      file_filter       = '*.txt'
      multiselection          = ''
    CHANGING
      file_table              = filetable
      rc                      = uaction
  EXCEPTIONS
    file_open_dialog_failed = 1
    cntl_error              = 2
    error_no_gui            = 3
    OTHERS                  = 4
                      .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      READ TABLE filetable INDEX 1 INTO p_g_filename.
    ENDIF.
  ELSE.
    MOVE text-007 TO title.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
      EXPORTING
        window_title      = title
        default_extension = 'txt'
        default_file_name = 'SW_excltx.csv'
        file_filter       = '*.txt'
      CHANGING
        filename          = fn
        path              = path
        fullpath          = p_g_filename
        user_action       = uaction
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3
            .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

endform.                    " f4_file

*********** 29-08-2008 changed by sgottapu *****************
