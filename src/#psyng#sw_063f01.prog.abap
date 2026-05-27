***INCLUDE /PSYNG/SW_063F01 .
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
        ls_cuscon         TYPE /psyng/sw_cuscon.

  RANGES: lr_conid FOR /psyng/sw_cuscon-conid.
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

    WHEN 'MARK'.                      "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name   .
      CLEAR p_ok.

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name .
      CLEAR p_ok.

    WHEN 'DISPCHG'.                    "Toggle display <-> change modes
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        IF gf_auth_mode = gc_display.
          MESSAGE i108 WITH text-002.
          EXIT.
        ENDIF.

        gf_dispchg = gc_change.
        PERFORM enqueue.
      ELSE.                            "Change mode to DISPLAY
*       If data was changed, ask if user wants to exit without saving
        IF gf_data_change = 'X'.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
               EXPORTING
                    text_question         = text-003
                    text_button_1         = text-004
                    icon_button_1         = 'ICON_CHECKED'
                    text_button_2         = text-005
                    icon_button_2         = 'ICON_INCOMPLETE'
                    default_button        = '2'
                    display_cancel_button = ' '
               IMPORTING
                    answer                = gf_answer
               EXCEPTIONS
                    text_not_found        = 1
                    OTHERS                = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

          CHECK gf_answer = 1.
        ENDIF.

        gf_dispchg = gc_display.
        PERFORM dequeue.
        PERFORM get_data.
        CLEAR gf_data_change.
      ENDIF.

    WHEN 'SAVE'.                       "Save table
*     Since there's not much data, delete everything and re-add
      DELETE FROM /psyng/sw_cuscon WHERE vrsio = p_vrsio.

      LOOP AT gt_cuscon.
        ls_cuscon = gt_cuscon.

        IF ls_cuscon IS INITIAL.
          DELETE gt_cuscon.
          CONTINUE.
        ENDIF.

        IF ls_cuscon-conid IS INITIAL.
          CLEAR sy-ucomm.
          MESSAGE e106 WITH text-000.
        ENDIF.

        ls_cuscon-vrsio = p_vrsio.
        INSERT INTO /psyng/sw_cuscon       "#EC CI_IMUD_NESTED
            VALUES ls_cuscon.
      ENDLOOP.

      MESSAGE s120.

      COMMIT WORK.
      CLEAR gf_data_change.

    WHEN 'TRAN'.                       "Transport
      lr_conid-sign = 'I'.
      lr_conid-option = 'EQ'.
      LOOP AT gt_cuscon WHERE sel = 'X'.
        lr_conid-low = gt_cuscon-conid.
        APPEND lr_conid.
      ENDLOOP.

      IF sy-subrc <> 0.
        MESSAGE w113 WITH text-e03.
        EXIT.
      ENDIF.

      SUBMIT /psyng/sw_048
             WITH p_vrsio  = p_vrsio
             WITH p_tcscon = 'X'
             WITH s_cuscon IN lr_conid
             AND RETURN.
  ENDCASE.
ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
               USING    p_tc_name           TYPE dynfnam
                        p_table_name             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA: l_lines_name       LIKE feld-name,
        l_selline          LIKE sy-stepl,
        l_line             TYPE i,
        l_table_name       LIKE feld-name,
        ls_cuscon          LIKE gt_cuscon.

  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
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
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.
* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
  READ TABLE <table> INDEX l_selline INTO ls_cuscon.
  ls_cuscon-create_usr = g_current_user."sy-uname. C0700
  ls_cuscon-create_dat = sy-datum.
  ls_cuscon-create_tim = sy-uzeit.
  MODIFY <table> FROM ls_cuscon INDEX l_selline.

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
      gf_data_change = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
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

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
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
              entry_act      = <tc>-top_line
              entry_from     = 1
              entry_to       = <tc>-lines
              last_page_full = 'X'
              loops          = <lines>
              ok_code        = p_ok
              overlapping    = 'X'
         IMPORTING
              entry_new      = l_tc_new_top_line
"(++)BOC UMITTAL SE VF scan-25/11/2024.
         EXCEPTIONS
              NO_ENTRY_OR_PAGE_ACT    = 1
              NO_ENTRY_TO             = 2
              NO_OK_CODE_OR_PAGE_GO   = 3
              OTHERS         = 4.
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

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
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

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
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
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       Lock table for editing
*----------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SW_CUSCON'
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    gf_dispchg = gc_display.                "Display mode
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
            tabname = '/PSYNG/SW_CUSCON'.
ENDFORM.                    " dequeue

*&---------------------------------------------------------------------*
*&      Form  dispchg
*&---------------------------------------------------------------------*
*       Set screen attributes for Display/Change mode
*----------------------------------------------------------------------*
FORM dispchg.
  IF gf_dispchg = gc_display.          "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = 'MOD' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                "Change
    LOOP AT SCREEN.
      CHECK screen-group1 = 'MOD' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " dispchg

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get all data from database
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * INTO TABLE gt_cuscon FROM /psyng/sw_cuscon
         WHERE vrsio = p_vrsio.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  validate
*&---------------------------------------------------------------------*
*       Perform all validations
*----------------------------------------------------------------------*
FORM validate.
DATA: ls_cuscon LIKE gt_cuscon.

* Check for duplicates
  LOOP AT gt_cuscon INTO ls_cuscon WHERE conid = gt_cuscon-conid.
    IF sy-tabix <> tc_cuscon-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.

* Check that conflict is not already defined in SW
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                WHERE conid = gt_cuscon-conid
                  AND vrsio = p_vrsio.
  IF sy-subrc = 0.
    MESSAGE e113 WITH text-e02.
  ENDIF.

* Check function module
  SELECT SINGLE mand INTO sy-mandt FROM tfdir
                WHERE funcname = gt_cuscon-funct.
  IF sy-subrc <> 0.
    MESSAGE e110(fl) WITH gt_cuscon-funct.
  ENDIF.

* Check business area
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/busarea
                WHERE busarea = gt_cuscon-busarea.
  IF sy-subrc <> 0.
    MESSAGE e113 WITH text-006 gt_cuscon-busarea text-e01.
  ENDIF.
ENDFORM.                    " validate
