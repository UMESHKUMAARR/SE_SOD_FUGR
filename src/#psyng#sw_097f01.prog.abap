*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_097F01                                           *
*----------------------------------------------------------------------*
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

  DATA: ls_remcon LIKE /psyng/sw_remcon.

* execute general and TC specific operations                           *
  CASE p_ok.
    WHEN 'INSR'.                       "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name.

    WHEN 'DELE'.                       "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.

    WHEN 'P--' OR                      "top of list
         'P-'  OR                      "previous page
         'P+'  OR                      "next page
         'P++'.                        "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            p_ok.

    WHEN 'MARK'.                      "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name   .

    WHEN 'DMRK'.                      "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name .

    WHEN 'SORTA' OR 'SORTD'.           "sort column
      PERFORM fcode_sort_tc USING p_ok.

    WHEN 'SAVE'.                         "Save
*     Since there's not much data, delete everything and re-add
      DELETE FROM /psyng/sw_remcon WHERE conid <> space.

      LOOP AT gt_remcon.
        ls_remcon = gt_remcon.
        INSERT INTO /psyng/sw_remcon      "#EC CI_IMUD_NESTED
          VALUES ls_remcon.
      ENDLOOP.

      COMMIT WORK.
      CLEAR gf_data_change.

    WHEN 'DISPCHG'.                    "Toggle display<->change
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

    WHEN 'TRAN'.                       "Transport
      READ TABLE gt_remcon WITH KEY sel = 'X' TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR p_ok.
        MESSAGE w146.
        EXIT.
      ENDIF.

      PERFORM create_transport.
      PERFORM add_to_transport.
  ENDCASE.

  CLEAR p_ok.
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
  l_lines_name = 'G_TC_LINES'.
  ASSIGN (l_lines_name) TO <lines>.

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
        gf_data_change = 'X'.
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

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
* get looplines of TableControl
  l_tc_lines_name = 'G_TC_LINES'.
  ASSIGN (l_tc_lines_name) TO <lines>.

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
           "(++)BOC UMITTAL SE VF scan-25/11/2024
         EXCEPTIONS
             NO_ENTRY_OR_PAGE_ACT = 1
             NO_ENTRY_TO   = 2
             NO_OK_CODE_OR_PAGE_GO = 3
             OTHERS                 = 4 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  ENDIF.

* get actual tc and column                                             *
  GET CURSOR FIELD l_tc_field_name AREA l_tc_name.

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
*&      Form  fcode_sort_tc
*&---------------------------------------------------------------------*
*       Dynamically sort internal table
*----------------------------------------------------------------------*
*      -->I_OK          OK Code
*----------------------------------------------------------------------*
FORM fcode_sort_tc USING    i_ok LIKE sy-ucomm.
  DATA: l_column TYPE dd03d-fieldname,
        l_table  TYPE dd02d-tabname.

  FIELD-SYMBOLS: <cols> TYPE cxtab_column.


  LOOP AT tc_remcon-cols ASSIGNING <cols> WHERE selected = 'X'.
    SPLIT <cols>-screen-name AT '-' INTO l_table l_column.
    IF i_ok = 'SORTA'.
      SORT gt_remcon BY (l_column).
    ELSE.
      SORT gt_remcon BY (l_column) DESCENDING.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " fcode_sort_tc

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

* demark all filled lines                                              *
  LOOP AT <table> ASSIGNING <wa>.
*   access to the component 'FLAG' of the table header                 *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.
    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get all data from database
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * INTO TABLE gt_remcon FROM /psyng/sw_remcon.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       Lock table for editing
*----------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SW_REMCON'
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
            tabname = '/PSYNG/SW_REMCON'.
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
*&      Form  validate
*&---------------------------------------------------------------------*
*       Perform all validations
*----------------------------------------------------------------------*
FORM validate.
  DATA: ls_remcon LIKE gt_remcon.

* Check for duplicates
  LOOP AT gt_remcon INTO ls_remcon WHERE rfcdest = gt_remcon-rfcdest
                                     AND conid   = gt_remcon-conid
                                     AND vrsio   = gt_remcon-vrsio.
    IF sy-tabix <> tc_remcon-current_line.
      MESSAGE e101.
    ENDIF.
  ENDLOOP.

* Check that RFC destination exists
  SELECT SINGLE rfcdest INTO ls_remcon-rfcdest FROM rfcdes
                WHERE rfcdest = gt_remcon-rfcdest.
  IF sy-subrc <> 0.
    MESSAGE e004(sr).
  ENDIF.

* Check that version exists
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = gt_remcon-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e156 WITH gt_remcon-vrsio.
  ENDIF.

* Check that conflict exists
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/conflict
                WHERE conid = gt_remcon-conid
                  AND vrsio = gt_remcon-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e158 WITH gt_remcon-vrsio gt_remcon-conid.
  ENDIF.
ENDFORM.                    " validate

*&---------------------------------------------------------------------*
*&      Form  create_transport
*&---------------------------------------------------------------------*
*       Create/choose transport request
*----------------------------------------------------------------------*
FORM create_transport.
  CHECK g_trkorr IS INITIAL.

  CALL FUNCTION 'TRINT_ORDER_CHOICE'
       EXPORTING
            wi_cli_dep             = 'X'
            wi_display_button      = 'X'
       IMPORTING
            we_task                = g_trkorr
       TABLES
            wt_e071                = gt_e071
            wt_e071k               = gt_e071k
       EXCEPTIONS
            no_correction_selected = 1
            display_mode           = 2
            object_append_error    = 3
            recursive_call         = 4
            wrong_order_type       = 5
            OTHERS                 = 6.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

* Get existing data
  SELECT * INTO TABLE gt_e071 FROM e071
         WHERE trkorr = g_trkorr.

  SELECT * INTO TABLE gt_e071k FROM e071k
         WHERE trkorr = g_trkorr.
ENDFORM.                    " create_transport

*&---------------------------------------------------------------------*
*&      Form  add_to_transport
*&---------------------------------------------------------------------*
*       Add entries to transport
*----------------------------------------------------------------------*
FORM add_to_transport.
  DATA: ls_remcon LIKE /psyng/sw_remcon,
        ls_e070   LIKE e070,
        ls_e07t   LIKE e07t.


  gt_e071-trkorr   = g_trkorr.
  gt_e071-pgmid    = 'R3TR'.
  gt_e071-object   = 'TABU'.
  gt_e071-obj_name = '/PSYNG/SW_REMCON'.
  gt_e071-objfunc  = 'K'.
  APPEND gt_e071.

  MOVE-CORRESPONDING gt_e071 TO gt_e071k.
  CLEAR gt_e071k-objfunc.
  gt_e071k-mastertype = 'TABU'.

* Add config to transport
  gt_e071k-objname = gt_e071k-mastername = '/PSYNG/SW_REMCON'.
  LOOP AT gt_remcon WHERE sel = 'X'.
    MOVE-CORRESPONDING gt_remcon TO ls_remcon.
    MOVE ls_remcon TO gt_e071k-tabkey.
    APPEND gt_e071k.
  ENDLOOP.

  SELECT SINGLE * INTO ls_e070 FROM e070
                WHERE trkorr = g_trkorr.

  SELECT SINGLE * INTO ls_e07t FROM e07t
                WHERE trkorr = g_trkorr.

  SORT gt_e071 BY pgmid object obj_name.
  DELETE ADJACENT DUPLICATES FROM gt_e071
                             COMPARING pgmid object obj_name.
  SORT gt_e071k BY pgmid object objname tabkey.
  DELETE ADJACENT DUPLICATES FROM gt_e071k
                             COMPARING pgmid object objname tabkey.

  CALL FUNCTION 'TRINT_MODIFY_COMM'
       EXPORTING
            wi_called_by_editor            = 'X'
            wi_e070                        = ls_e070
            wi_e07t                        = ls_e07t
            wi_lock_sort_flag              = 'X'
            wi_save_user                   = 'X'
            wi_sel_e071                    = 'X'
            wi_sel_e071k                   = 'X'
            wi_sel_e07t                    = space
       TABLES
            wt_e071                        = gt_e071
            wt_e071k                       = gt_e071k
       EXCEPTIONS
            chosen_project_closed          = 1
            e070_insert_error              = 2
            e070_update_error              = 3
            e071k_insert_error             = 4
            e071k_update_error             = 5
            e071_insert_error              = 6
            e071_update_error              = 7
            e07t_insert_error              = 8
            e07t_update_error              = 9
            e070c_insert_error             = 10
            e070c_update_error             = 11
            locked_entries                 = 12
            locked_object_not_deleted      = 13
            ordername_forbidden            = 14
            order_change_but_locked_object = 15
            order_released                 = 16
            order_user_locked              = 17
            tr_check_keysyntax_error       = 18
            no_authorization               = 19
            wrong_client                   = 20 "#EC SAST_CI_GEN_CHECK
            unallowed_source_client        = 21
            unallowed_user                 = 22
            unallowed_trfunction           = 23
            unallowed_trstatus             = 24
            no_systemname                  = 25
            no_systemtype                  = 26
            OTHERS                         = 27.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " add_to_transport
