***INCLUDE /PSYNG/SW_084F01 .
*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get all data from database
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * INTO TABLE gt_sodvers FROM /psyng/swsodvers
         ORDER BY PRIMARY KEY.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       Lock table for editing
*----------------------------------------------------------------------*
FORM enqueue.
  CHECK gf_auth_mode = gc_change.

  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
    EXPORTING
      tabname        = '/PSYNG/SWSODVERS'
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
  CHECK gf_auth_mode = gc_change.

  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
    EXPORTING
      tabname = '/PSYNG/SWSODVERS'.
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
      CHECK ( screen-group1 = 'MOD' AND screen-input = 0 )
      OR ( gt_sodvers[] IS INITIAL AND screen-group1 = 'KEY' ).
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
  DATA: ls_sodvers LIKE LINE OF gt_sodvers,
        lt_sodvers LIKE TABLE OF gt_sodvers WITH HEADER LINE,
        l_tabix    TYPE i.

* Check authority for this specific version
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
           ID 'ACTVT' FIELD '02'
           ID 'Y&SW_VRSIO' FIELD gt_sodvers-vrsio.
  IF sy-subrc <> 0.
    MESSAGE e108 WITH 'edit version'(000) gt_sodvers-vrsio.
    EXIT.
  ENDIF.

* Check for duplicates
  IF ok_code = 'SAVE'.
    lt_sodvers[] = gt_sodvers[].
    LOOP AT gt_sodvers.
      IF gt_sodvers-vdesc IS INITIAL.
        MESSAGE e106 WITH text-001.
      ENDIF.

      l_tabix = sy-tabix.
      LOOP AT lt_sodvers WHERE vrsio = gt_sodvers-vrsio.
        IF sy-tabix <> l_tabix.
          MESSAGE e101.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ELSE.
    IF gt_sodvers-vdesc IS INITIAL.
      MESSAGE e106 WITH text-001.
    ENDIF.

    LOOP AT gt_sodvers INTO ls_sodvers WHERE vrsio = gt_sodvers-vrsio.
      IF sy-tabix <> tc_sodvers-current_line.
        MESSAGE e101.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " validate

*&---------------------------------------------------------------------*
*&      Form  delete_versions
*&---------------------------------------------------------------------*
*       Delete SOD versions.  When deleting version header, also delete
*       from all other tables (except history tables) where version
*       exists.
*----------------------------------------------------------------------*
FORM delete_versions.
  LOOP AT gt_del.
*   Check that this version wasn't re-added
    READ TABLE gt_sodvers WITH KEY vrsio = gt_del-vrsio
               TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    CALL FUNCTION '/PSYNG/SW_085'
      EXPORTING
        i_vrsio = gt_del-vrsio.
  ENDLOOP.
ENDFORM.                    " delete_versions


*&---------------------------------------------------------------------*
*&      Form  copy_entire_version
*&---------------------------------------------------------------------*
*       Copy all entries for the selected version
*----------------------------------------------------------------------*
FORM copy_entire_version.
  DATA: l_vrsio TYPE /psyng/swsodvers-vrsio,
        l_limit TYPE i.

  CLEAR l_limit.
  LOOP AT gt_sodvers WHERE sel = 'X' .
    l_limit = l_limit + 1.
  ENDLOOP.

  IF l_limit <> 1.
    MESSAGE s002(/psyng/sw) WITH text-007.
    EXIT.
  ELSE.
    LOOP AT gt_sodvers WHERE sel = 'X'.
      l_vrsio = gt_sodvers-vrsio.
      EXIT.
    ENDLOOP.
    SUBMIT /psyng/sw_080 VIA SELECTION-SCREEN
           WITH p_svrsio = l_vrsio
           AND RETURN.
  ENDIF.
ENDFORM.                    " copy_entire_version

*&---------------------------------------------------------------------*
*&      Form  compare_versions
*&---------------------------------------------------------------------*
*       Compare version
*----------------------------------------------------------------------*
FORM compare_versions.
  DATA: l_lvrsio TYPE /psyng/swsodvers-vrsio,
        l_rvrsio TYPE /psyng/swsodvers-vrsio,
        l_lfound TYPE /psyng/bapiflagx,
        l_rfound TYPE /psyng/bapiflagx,
        l_limit  TYPE i.

  CLEAR l_limit.
  LOOP AT gt_sodvers WHERE sel = 'X' .
    l_limit = l_limit + 1.
  ENDLOOP.

  IF l_limit > 2.
    MESSAGE s002(/psyng/sw) WITH text-006.
    EXIT.
  ELSE.
    LOOP AT gt_sodvers WHERE sel = 'X'.
      IF l_lfound IS INITIAL.
        l_lvrsio = gt_sodvers-vrsio.
        l_lfound = 'X'.
      ELSEIF l_rfound IS INITIAL.
        l_rvrsio = gt_sodvers-vrsio.
        l_rfound = 'X'.
      ENDIF.
    ENDLOOP.


    SUBMIT /psyng/sw_081 VIA SELECTION-SCREEN
           WITH p_lvrsio = l_lvrsio
           WITH p_rvrsio = l_rvrsio
           AND RETURN.
  ENDIF.
ENDFORM.                    " compare_versions

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
  DATA: ls_sodvers TYPE /psyng/swsodvers,
        ls_vrsio_o TYPE /psyng/swsodvers,
        ls_vrsio_n TYPE /psyng/swsodvers,
        l_objid    TYPE cdhdr-objectid,
        lt_cdtxt   TYPE TABLE OF cdtxt,
        l_current_user TYPE sy-uname. "C0700

*-END OF LOCAL DATA----------------------------------------------------*
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
* execute general and TC specific operations                           *
  CASE p_ok.
    WHEN 'INSR'.                      "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name.

    WHEN 'DELE'.                      "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.

    WHEN 'P--' OR                     "top of list
         'P-'  OR                     "previous page
         'P+'  OR                     "next page
         'P++'.                       "bottom of list
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
      PERFORM fcode_sort_tc USING p_tc_name
                                  p_ok.

    WHEN 'COPY'.                       "Copy entire version
      PERFORM copy_entire_version.

    WHEN 'COMPARE'.                    "Compare versions
      PERFORM compare_versions.

    WHEN 'DISPCHG'.                    "Toggle display <-> change modes
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
        PERFORM enqueue.
      ELSE.                            "Change mode to DISPLAY
*       If data was changed, ask if user wants to exit without saving
        IF gf_data_change = 'X'.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              text_question         = text-q01
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

          CHECK gf_answer = '1'.
        ENDIF.

        gf_dispchg = gc_display.
        PERFORM dequeue.
        PERFORM get_data.
        CLEAR gf_data_change.
      ENDIF.

    WHEN 'SAVE'.                       "Save table
      LOOP AT gt_sodvers.
        ls_sodvers = gt_sodvers.
        l_objid = gt_sodvers-vrsio.

*-------when new entry
        IF gt_sodvers-mandt IS INITIAL.
          ls_vrsio_n = ls_sodvers.
          INSERT /psyng/swsodvers FROM ls_sodvers.  "#EC CI_IMUD_NESTED
          CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
            EXPORTING
              objectid                = l_objid
              tcode                   = sy-tcode
              utime                   = sy-uzeit
              udate                   = sy-datum
              username                = l_current_user"sy-uname C0700
              planned_change_number   = ' '
              object_change_indicator = 'I'
              planned_or_real_changes = 'R'
              no_change_pointers      = ' '
*             UPD_ICDTXT_VRSIO        = ' '
              n_psyng_swsodvers       = ls_vrsio_n
              o_psyng_swsodvers       = ls_vrsio_o
              upd_psyng_swsodvers     = 'I'
            TABLES
              icdtxt_vrsio            = lt_cdtxt.
          else.
*---- when made any changes and click on save
            read table gt_change with key
                               vrsio = gt_sodvers-vrsio.
            if sy-subrc = 0.
              select single * from /psyng/swsodvers into
                ls_vrsio_o where vrsio = gt_sodvers-vrsio.

            MODIFY /psyng/swsodvers FROM ls_sodvers.    "#EC CI_IMUD_NESTED
              ls_vrsio_n = gt_change.
              CALL FUNCTION '/PSYNG/VRSIO_WRITE_DOCUMENT'
              EXPORTING
                objectid                = l_objid
                tcode                   = sy-tcode
                utime                   = sy-uzeit
                udate                   = sy-datum
                username                = l_current_user"sy-uname C0700
                planned_change_number   = ' '
                object_change_indicator = 'U'
                planned_or_real_changes = 'R'
                no_change_pointers      = ' '
*               UPD_ICDTXT_VRSIO        = ' '
                n_psyng_swsodvers       = ls_vrsio_n
                o_psyng_swsodvers       = ls_vrsio_o
                upd_psyng_swsodvers     = 'U'
              TABLES
                icdtxt_vrsio            = lt_cdtxt.
                endif.
        ENDIF.
        clear: ls_vrsio_n, ls_vrsio_o.
      ENDLOOP.

      PERFORM delete_versions.
      COMMIT WORK.
      IF sy-subrc = 0.
        MESSAGE s002(/psyng/sw) WITH 'Data Saved'(012).
      ENDIF.
      CLEAR: gf_data_change, gt_change.
      refresh gt_change.
  ENDCASE.
ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
               USING    p_tc_name           TYPE dynfnam
                        p_table_name             .

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_selline          LIKE sy-stepl.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

* get the table, which belongs to the tc                               *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
"not headerline

* get current line
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line and new cursor line                           *
    IF l_selline > g_lines.
      <tc>-top_line = l_selline - g_lines + 1.
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

  gf_data_change = 'X'.
ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA: l_table_name LIKE feld-name,
        l_answer(1)  TYPE c,
        lf_dup_found TYPE /psyng/bapiflagx,
        ls_sodvers   LIKE LINE OF gt_sodvers,
        l_ques(100)  TYPE c,
        l_index      TYPE sy-tabix.

  FIELD-SYMBOLS: <tc>           TYPE cxtab_control,
                 <table>        TYPE STANDARD TABLE,
                 <wa>,
                 <mark_field>,
                 <noedit_field>,
                 <vrsio_field>,
                 <vrsio>        TYPE /psyng/swsodvers-vrsio,
                 <fs>.
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

**SE 3.1 System Testing Bug No : 2691
** Check Atleast one entry is marked to be deleted
  READ TABLE <table> ASSIGNING <wa> WITH KEY (p_mark_name) = 'X'.
  IF sy-subrc NE 0.
    MESSAGE e002(/psyng/sw) WITH 'Please Select an Entry.'(011).
  ENDIF.
** End**
  ASSIGN COMPONENT 'VRSIO' OF STRUCTURE <wa> TO <vrsio>.
  IF <vrsio> = '000' OR <vrsio> = '999'.
    MESSAGE e002(/psyng/sw)
    WITH 'This is reserved version by SW,cannot be deleted'(013).
  ENDIF.
*--Validate no stored results exist
  PERFORM validate_deletion
    USING <vrsio>.


  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = text-q02
      text_button_1         = text-004
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = text-005
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = l_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CHECK l_answer = '1'.

  LOOP AT <table> ASSIGNING <wa>.
    ASSIGN COMPONENT 'NOEDIT' OF STRUCTURE <wa> TO <noedit_field>.
    ASSIGN COMPONENT 'VRSIO' OF STRUCTURE <wa> TO <vrsio_field>.
**    *   access to the component 'FLAG' of the table header
**     *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

**SE 3.1 System Testing Bug No : 2692
** Table invalid index Dump : Pass the Tble index to local variable then
** use local variable to delete table entry because at 'pop up to
** confirm' sy-tabix is got cleared
    l_index = sy-tabix.
** End

    IF <mark_field> = 'X'.

*      CALL FUNCTION 'POPUP_TO_CONFIRM'
*           EXPORTING
*                text_question         = text-q02
*                text_button_1         = text-004
*                icon_button_1         = 'ICON_OKAY'
*                text_button_2         = text-005
*                icon_button_2         = 'ICON_CANCEL'
*                default_button        = '2'
*                display_cancel_button = space
*           IMPORTING
*                answer                = l_answer
*           EXCEPTIONS
*                text_not_found        = 1
*                OTHERS                = 2.
*      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*      ENDIF.
*
*      CHECK l_answer = '1'.

*     Check authority for this specific version
      AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
               ID 'ACTVT' FIELD '06'
               ID 'Y&SW_VRSIO' FIELD <vrsio_field>.
      IF sy-subrc <> 0.
        MESSAGE i108 WITH 'delete version'(010) <vrsio_field>.
        EXIT.
      ENDIF.

      IF <noedit_field> = 'X'.
        CONCATENATE  <vrsio_field> text-008 INTO l_ques.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            text_question         = l_ques
            text_button_1         = text-004
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-005
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = space
          IMPORTING
            answer                = l_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        IF l_answer NE '1'.
          MESSAGE s002(/psyng/sw) WITH text-009.
          CONTINUE.
        ENDIF.

      ENDIF.



      ASSIGN COMPONENT 'VRSIO' OF STRUCTURE <wa> TO <vrsio>.
      IF <vrsio> = '000' OR <vrsio> = '999'.
*       Check for duplicates
        LOOP AT gt_sodvers INTO ls_sodvers
                WHERE vrsio = gt_sodvers-vrsio.
          IF sy-tabix <> tc_sodvers-current_line.
            lf_dup_found = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.

        IF lf_dup_found IS INITIAL.
          MESSAGE e153 WITH <vrsio>.
        ENDIF.
      ENDIF.

      gt_del-vrsio = <vrsio>.

      DELETE <table> INDEX l_index.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.

        IF gt_del-vrsio <> '000' AND gt_del-vrsio <> '999'.
          COLLECT gt_del.
        ENDIF.
      ENDIF.

      gf_data_change = 'X'.
*    ELSE.
*      MESSAGE e002(/psyng/sw) WITH 'Please Select an Entry.'.
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
FORM compute_scrolling_in_tc USING    p_tc_name TYPE dynfnam
                                      p_ok TYPE sy-ucomm.
*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
*-END OF LOCAL DATA----------------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
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
        loops          = g_lines
        ok_code        = p_ok
        overlapping    = 'X'
      IMPORTING
        entry_new      = l_tc_new_top_line
      EXCEPTIONS
       NO_ENTRY_OR_PAGE_ACT  = 01
       NO_ENTRY_TO    = 02
       NO_OK_CODE_OR_PAGE_GO = 03
        OTHERS         = 04.
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
FORM fcode_tc_mark_lines USING p_tc_name TYPE dynfnam
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
FORM fcode_tc_demark_lines USING p_tc_name TYPE dynfnam
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
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_SORT_TC
*&---------------------------------------------------------------------*
*       Dynamically sort internal table
*----------------------------------------------------------------------*
*      -->I_TC_NAME  Name of table control
*      -->I_OK       User command
*----------------------------------------------------------------------*
FORM fcode_sort_tc USING    i_tc_name TYPE dynfnam
                            i_ok TYPE sy-ucomm.
  DATA: l_table  TYPE dd02d-tabname,
        l_column TYPE dd03d-fieldname.

  FIELD-SYMBOLS: <tc>   TYPE cxtab_control,
                 <cols> TYPE cxtab_column.


  ASSIGN (i_tc_name) TO <tc>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  LOOP AT <tc>-cols ASSIGNING <cols> WHERE selected = 'X'.
    SPLIT <cols>-screen-name AT '-' INTO l_table l_column.
    IF i_ok = 'SORTA'.
      SORT gt_sodvers BY (l_column).
    ELSE.
      SORT gt_sodvers BY (l_column) DESCENDING.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " FCODE_SORT_TC
*&---------------------------------------------------------------------*
*&      Form  validate_deletion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_<VRSIO>  text
*----------------------------------------------------------------------*
FORM validate_deletion USING   i_vrsio TYPE /psyng/sodvrsio.
  DATA : ls_reshdr TYPE /psyng/swreshdr,
         ls_rrshdr TYPE /psyng/swrrshdr,
         ls_set    TYPE /psyng/swcfgset.

*--Ensure no stored user results exist
  SELECT SINGLE * FROM /psyng/swreshdr
  INTO ls_reshdr
  WHERE sodvrsio = i_vrsio.
  IF sy-subrc = 0.
    MESSAGE e028(/psyng/sw)
    WITH i_vrsio.
  ENDIF.
*--Ensure no stored role results exist
  SELECT SINGLE * FROM /psyng/swrrshdr
  INTO ls_rrshdr
  WHERE sodvrsio = i_vrsio."#EC CI_NOFIELD
  IF sy-subrc = 0.
    MESSAGE e028(/psyng/sw)
    WITH i_vrsio.
  ENDIF.
*--Ensure no Config Sets exist
  SELECT SINGLE * FROM /psyng/swcfgset
  INTO ls_set
  WHERE sodvrsio = i_vrsio.
  IF sy-subrc = 0.
    MESSAGE e029(/psyng/sw)
    WITH i_vrsio.
  ENDIF.


ENDFORM.                    " validate_deletion
