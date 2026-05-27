REPORT /psyng/sw_074 MESSAGE-ID /psyng/sw.
DATA : BEGIN OF gs_tc_exclude .
DATA:   sel(1) TYPE c.
        INCLUDE STRUCTURE /psyng/sw_excltx.
DATA : END OF gs_tc_exclude .
DATA : gt_tc_exclude LIKE TABLE OF gs_tc_exclude,
       gf_data_change TYPE flag,
       g_mode(1)            TYPE c,
       g_filename     TYPE string,
       g_delim TYPE c VALUE ';'.
.
DATA: BEGIN OF gt_excfunc OCCURS 0,
        func TYPE rsmpe-func,
      END OF gt_excfunc.
*CONTROLS: tc_exclude  TYPE TABLEVIEW USING SCREEN 0100.
*&spwizard: lines of tablecontrol 'TC_EXCLUDE'
DATA:     g_tc_exclude_lines  LIKE sy-loopc.
DATA:     ok_code LIKE sy-ucomm.
**&spwizard: declaration of tablecontrol 'TC_EXCLUDE' itself
CONTROLS: tc_exclude TYPE TABLEVIEW USING SCREEN 0100.

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
*Authorization check for Display table /psyng/sw_excltx
*SF 1665
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'ACTVT' FIELD '03'
             ID 'DICBERCLS' FIELD 'Y&S5'.
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-e04 '/psyng/sw_excltx'.
    STOP.
  ENDIF.

  PERFORM enqueue.
  SELECT * FROM /psyng/sw_excltx INTO CORRESPONDING FIELDS OF
  TABLE gt_tc_exclude.
  CALL SCREEN 100.
* Includes inserted by Screen Painter Wizard. DO NOT CHANGE THIS LINE!
  INCLUDE /psyng/sw_074_pai .
  INCLUDE /psyng/sw_074_pbo.

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

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            l_ok.
      CLEAR p_ok.
*     WHEN 'L--'.                       "total left
*       PERFORM FCODE_TOTAL_LEFT USING P_TC_NAME.
*
*     WHEN 'L-'.                        "column left
*       PERFORM FCODE_COLUMN_LEFT USING P_TC_NAME.
*
*     WHEN 'R+'.                        "column right
*       PERFORM FCODE_COLUMN_RIGHT USING P_TC_NAME.
*
*     WHEN 'R++'.                       "total right
*       PERFORM FCODE_TOTAL_RIGHT USING P_TC_NAME.
*
 WHEN 'MARK'. "#EC SAST_CI_GEN_CHECK (HBHALLA) "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name   .
      CLEAR p_ok.

WHEN 'DMRK'. "#EC SAST_CI_GEN_CHECK (HBHALLA) "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name .
      CLEAR p_ok.

*     WHEN 'SASCEND'   OR
*          'SDESCEND'.                  "sort column
*       PERFORM FCODE_SORT_TC USING P_TC_NAME
*                                   l_ok.
    WHEN 'UPLD' OR 'DWNLD'.           "upload or download
      CALL SCREEN 200 STARTING AT 3 3 ENDING AT 105 8.
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

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>.  "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

* get looplines of TableControl
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.
  ASSIGN (l_lines_name) TO <lines>. "#EC PATHLOCK_CI_DYN_ACCES
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

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
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
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

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
  ASSIGN (l_tc_lines_name) TO <lines>. "#EC PATHLOCK_CI_DYN_ACCES
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
"(++)BOC UMITTAL SE VF scan-25/11/2024.
         EXCEPTIONS
              NO_ENTRY_OR_PAGE_ACT  = 1
              NO_ENTRY_TO           = 2
              NO_OK_CODE_OR_PAGE_GO = 3
              OTHERS                = 4.
IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
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
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_mark_lines USING p_tc_name
                               p_table_name
                               p_mark_name.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

"not headerline

* mark all filled lines                                                *
  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

    <mark_field> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_demark_lines USING p_tc_name
                                 p_table_name
                                 p_mark_name .
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

* demark all filled lines                                              *
  LOOP AT <table> ASSIGNING <wa>.

*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines
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
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " confirm_exit

*---------------------------------------------------------------------*
*       FORM dequeue                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = '/PSYNG/SW_EXCLTX'.
ENDFORM.                    " dequeue

*---------------------------------------------------------------------*
*       FORM enqueue                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SW_EXCLTX'
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
*&      Form  save_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data.
  DATA : ls_excl TYPE /psyng/sw_excltx,
         lt_exclude TYPE TABLE OF /psyng/sw_excltx.
* Since there's not much data, delete everything and re-add
*BOC:HBHALLA (17/12/24)
  DELETE FROM /psyng/sw_excltx WHERE sign NE space.
"#EC SAST_CI_GEN_CHECK
*EOC:HBHALLA (17/12/24)
  LOOP AT gt_tc_exclude INTO gs_tc_exclude.
    MOVE-CORRESPONDING gs_tc_exclude TO ls_excl.
    IF ls_excl-sign = 'I' OR
       ls_excl-sign = 'E'.
      IF   gs_tc_exclude-type = 'EQ' OR
      gs_tc_exclude-type = 'BT' OR
      gs_tc_exclude-type = 'CP' .
        APPEND  ls_excl TO lt_exclude.
      ELSE.
        MESSAGE w113 WITH text-e01 text-e02 gs_tc_exclude-type.
        EXIT.
      ENDIF.
    ELSE.
      MESSAGE w113 WITH text-e01 text-e03 gs_tc_exclude-sign.
      EXIT.

    ENDIF.
  ENDLOOP.
*Save changes to database
  MODIFY /psyng/sw_excltx FROM TABLE lt_exclude.
  COMMIT WORK.
  MESSAGE s140 WITH text-006.
  CLEAR gf_data_change.
ENDFORM.                    " save_data
*&---------------------------------------------------------------------*
*&      Form  f4_TYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_TC_EXCLUDE_TYPE  text
*----------------------------------------------------------------------*
FORM f4_type CHANGING p_type.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.

*set fields
  lt_fields-tabname   = 'TVARV'.
  lt_fields-fieldname = 'OPTI'.
  APPEND lt_fields.
*Add allowed values
  lt_values-line = 'CP'.APPEND lt_values.
  lt_values-line = 'BT'.APPEND lt_values.
  lt_values-line = 'EQ'.APPEND lt_values.
*call dialog
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'TYPE'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*return value
  READ TABLE lt_return INDEX 1.
  p_type = lt_return-fieldval.

ENDFORM.                                                    " f4_TYPE
*&---------------------------------------------------------------------*
*&      Form  toggle_display_change
*&---------------------------------------------------------------------*
*       Set screen attributes for Display/Change mode
*----------------------------------------------------------------------*
FORM toggle_display_change.
  IF g_mode = 'D'.                     "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = '100' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                "Change
    LOOP AT SCREEN.
      CHECK screen-group1 = '100' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " toggle_display_change
*&---------------------------------------------------------------------*
*&      Form  f4_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_G_FILENAME  text
*----------------------------------------------------------------------*
FORM f4_file CHANGING p_g_filename.
  DATA : uaction TYPE i,
         title TYPE string,
         fn TYPE string,
         path TYPE string,
         filetable TYPE  filetable.
  IF ok_code = 'UPLD'.
    MOVE text-003 TO title.
    CALL METHOD cl_gui_frontend_services=>file_open_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      window_title      = title
      default_extension = 'csv'
      default_filename  = 'SW_excltx.csv'
      initial_directory = 'c:\temp'
      file_filter       = '*.csv'
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
    MOVE text-002 TO title.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
"#EC SAST_CI_GEN_CHECK (HBHALLA)
      EXPORTING
        window_title      = title
        default_extension = 'csv'
        default_file_name = 'SW_excltx.csv'
        file_filter       = '*.csv'
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
ENDFORM.                                                    " f4_file
*&---------------------------------------------------------------------*
*&      Form  download_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_file.
*Authorization check for Display table /psyng/sw_excltx
*SF 1665
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'ACTVT' FIELD '03'
             ID 'DICBERCLS' FIELD 'Y&S5'.
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-e04 '/psyng/sw_excltx'.
    STOP.
  ENDIF.

  DATA: l_out  TYPE string,
        lt_out TYPE TABLE OF string.
  LOOP AT gt_tc_exclude INTO gs_tc_exclude.
    CONCATENATE gs_tc_exclude-sign
                gs_tc_exclude-type
                gs_tc_exclude-low
                gs_tc_exclude-high
                INTO l_out
                SEPARATED BY g_delim.
    APPEND l_out TO lt_out.
  ENDLOOP.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename = g_filename
       TABLES
            data_tab = lt_out
       EXCEPTIONS
            OTHERS   = 1.
  IF sy-subrc <> 0.
    MESSAGE e133 WITH g_filename.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
*if sy-su brc = 0.
*message

ENDFORM.                    " download_file
*&---------------------------------------------------------------------*
*&      Form  upload_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_file.
*Authorization check for Display table /psyng/sw_excltx
*SF 1665
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
             ID 'ACTVT' FIELD '02'
             ID 'DICBERCLS' FIELD 'Y&S5'.
  IF sy-subrc NE 0.
    MESSAGE e113(/psyng/sw) WITH text-e05 '/psyng/sw_excltx'.
    STOP.
  ENDIF.

  DATA: lt_import    TYPE TABLE OF string,
        l_import     TYPE string,
        lt_exclude   TYPE TABLE OF /psyng/sw_excltx,
        ls_exclude   TYPE /psyng/sw_excltx.

*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename            = g_filename
            has_field_separator = g_delim
       TABLES
            data_tab            = lt_import
       EXCEPTIONS
            OTHERS              = 1.
  IF sy-subrc <> 0.
    MESSAGE e133 WITH g_filename.
  ENDIF.
  IF sy-subrc = 0.
    MESSAGE s140 WITH 'Uploaded Successfully'(007).
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)
  LOOP AT lt_import INTO l_import.
    SPLIT l_import AT g_delim INTO
      ls_exclude-sign
      ls_exclude-type
      ls_exclude-low
      ls_exclude-high.


    IF   ls_exclude-type = 'EQ' OR
         ls_exclude-type = 'BT' OR
         ls_exclude-type = 'CP' .

      IF ls_exclude-sign = 'I' OR
         ls_exclude-sign = 'E'.
        READ TABLE gt_tc_exclude WITH KEY
          type = ls_exclude-type
          low = ls_exclude-low
          high = ls_exclude-high
          TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          MOVE-CORRESPONDING ls_exclude TO gs_tc_exclude.
          APPEND gs_tc_exclude TO  gt_tc_exclude.
        ENDIF.
      ELSE.
        MESSAGE e113 WITH text-e01 text-e03 ls_exclude-sign.
      ENDIF.
    ELSE.
      MESSAGE e113 WITH text-e01 text-e02 ls_exclude-type.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " upload_file
*&---------------------------------------------------------------------*
*&      Form  f4_sign
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_sign CHANGING p_sign.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.

*set fields
  lt_fields-tabname   = 'TVARV'.
  lt_fields-fieldname = 'SIGN'.
  APPEND lt_fields.
*Add allowed values
  lt_values-line = 'I'.APPEND lt_values.
  lt_values-line = 'E'.APPEND lt_values.
*call dialog
  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SIGN'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*return value
  READ TABLE lt_return INDEX 1.
  p_sign = lt_return-fieldval.
ENDFORM.                                                    " f4_sign
