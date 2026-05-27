*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_FREQUENCY_MAINT
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*



PROGRAM /psyng/sw_frequency_maint.

DATA : gf_dispchg VALUE 'D',
       gc_display VALUE 'D',
       active,
       gf_populated,
       g_tc_lines TYPE sy-loopc,
       gf_answer TYPE c.

DATA :BEGIN OF gt_freqtxt OCCURS 0.
DATA : mandt TYPE mandt,
       freq TYPE /psyng/freq,
       numdays(3) TYPE c,
       lang TYPE sy-langu,
       text(255) TYPE c,
       mark(1) TYPE c,
END OF gt_freqtxt.

DATA: gt_repid     TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE,
      gt_freqtxt_1 TYPE TABLE OF /psyng/sw_freq WITH HEADER LINE,
      gt_freqtxt_2 TYPE TABLE OF /psyng/sw_freqt WITH HEADER LINE.


DATA : g_tabname TYPE tabname,
       gc_change TYPE c VALUE 'C' ,
       g_prev_ucomm TYPE sy-ucomm,
       g_curr_line TYPE i,
       gs_freqtxt_wa LIKE LINE OF gt_freqtxt,
       gs_freqtxt_wa1 LIKE LINE OF gt_freqtxt.

DATA : gf_freqtxt_data_change TYPE /psyng/bapiflagx.

TYPES: BEGIN OF ty_freq,
       freq TYPE /psyng/sw_freq-freq,
       numdays TYPE /psyng/sw_freq-numdays,
       lang TYPE /psyng/sw_freqt-lang,
       text TYPE /psyng/sw_freqt-text,
       END OF ty_freq.

CONTROLS tc_freqtxt TYPE TABLEVIEW USING SCREEN 0100.

DATA : gt_freqt TYPE /psyng/sw_freqt OCCURS 0.

*&---------------------------------------------------------------------*
*&      Module  get_freqtxt_details  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_freqtxt_details OUTPUT.

  IF gf_populated IS INITIAL.
    IF gt_freqtxt[] IS INITIAL.
      g_tabname = '/psyng/sw_freq'.

      SELECT * FROM /psyng/sw_freq
               INTO CORRESPONDING FIELDS OF TABLE
               gt_freqtxt_1.


      SELECT * FROM /psyng/sw_freqt      "#EC CI_NOFIRST
       INTO CORRESPONDING FIELDS OF TABLE
        gt_freqtxt_2
               WHERE lang = sy-langu.


      LOOP AT gt_freqtxt_1.
        READ TABLE gt_freqtxt_2 WITH KEY freq = gt_freqtxt_1-freq.
        IF sy-subrc = 0.
          MOVE-CORRESPONDING gt_freqtxt_1 TO gt_freqtxt.
          MOVE-CORRESPONDING gt_freqtxt_2 TO gt_freqtxt.
          APPEND gt_freqtxt.
        ENDIF.
      ENDLOOP.

    ENDIF.
    gf_populated = 'X'.
    IF gf_dispchg = gc_change.
      PERFORM enqueue.                 "Lock table in change mode
    ENDIF.
  ENDIF.
  DESCRIBE TABLE gt_freqtxt LINES tc_freqtxt-lines.
  PERFORM display_change.

  SET CURSOR FIELD 'GT_FREQTXT-FREQ' LINE tc_freqtxt-current_line.

ENDMODULE.                 " get_freqtxt_details  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  gt_freqtxt_get_lines  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE gt_freqtxt_get_lines OUTPUT.

  g_tc_lines = sy-loopc.
  PERFORM display_change.

  IF gf_dispchg = gc_change AND g_prev_ucomm = 'INSERT'
  AND g_curr_line = tc_freqtxt-current_line.
    LOOP AT SCREEN.
      CHECK screen-group1 = 'INS' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.

ENDMODULE.                 " gt_freqtxt_get_lines  OUTPUT


*&---------------------------------------------------------------------*
*&      Form  display_change
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_change.

  IF gf_dispchg = gc_display.                    "Display

    LOOP AT SCREEN.

      IF  active = 'X'.
        CASE screen-name.
          WHEN 'ACTIVE'.

            screen-input = 1.
          WHEN 'INACTIVE'.
            screen-input = 0.
        ENDCASE.
      ELSE.
        CASE screen-name.
          WHEN 'ACTIVE'.
            screen-input = 0.
          WHEN 'INACTIVE'.
            screen-input = 1.
        ENDCASE.
      ENDIF.

      CHECK screen-group1 = 'MOD' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                          "Change
    LOOP AT SCREEN.

      IF  active = 'X'.
        CASE screen-name.
          WHEN 'ACTIVE'.

            screen-input = 0.
          WHEN 'INACTIVE'.
            screen-input = 1.
        ENDCASE.
      ELSE.
        CASE screen-name.
          WHEN 'ACTIVE'.
            screen-input = 1.
          WHEN 'INACTIVE'.
            screen-input = 0.
        ENDCASE.
      ENDIF.

      CHECK screen-group1 = 'MOD' AND screen-input = 0.
      screen-input = 1.

      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " display_change


*---------------------------------------------------------------------*
*       MODULE modify_tc_freqtxt INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE modify_tc_freqtxt INPUT.

  IF gt_freqtxt[] IS INITIAL.
    APPEND gt_freqtxt.
  ELSE.
    MODIFY gt_freqtxt INDEX tc_freqtxt-current_line.
  ENDIF.

ENDMODULE.                 " modify_tc_sptxt  INPUT


*&---------------------------------------------------------------------*
*&      Module  tc_freqtxt_mark  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tc_freqtxt_mark INPUT.

  IF tc_freqtxt-line_sel_mode = 1.
    LOOP AT gt_freqtxt INTO gs_freqtxt_wa WHERE mark = 'X'.
      gs_freqtxt_wa1-mark = ''.
      MODIFY gt_freqtxt FROM gs_freqtxt_wa TRANSPORTING mark.
    ENDLOOP.
  ENDIF.

  MODIFY gt_freqtxt INDEX tc_freqtxt-current_line TRANSPORTING
mark.

ENDMODULE.                 " tc_freqtxt_mark  INPUT



*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '/PSYNG/SWFREQ'.
  SET TITLEBAR '/PSYNG/SWTITLE'.

ENDMODULE.                 " STATUS_0100  OUTPUT



*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  g_prev_ucomm = sy-ucomm.
  CASE sy-ucomm.

    WHEN 'BACK' OR 'CANCEL'..
      CLEAR gf_populated.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'DISPCHNG'.

      IF gf_dispchg = gc_display.      "Change mode to CHANGE

*        PERFORM authority_check_chgdisp USING act_change.
*
*        AUTHORITY-CHECK OBJECT 'Y&SP_RECER'
*            ID 'ACTVT' FIELD '01'.
*        IF sy-subrc <> 0.
*          AUTHORITY-CHECK OBJECT 'Y&SP_DISCH'
*                      ID 'ACTVT' FIELD '02'.
*          IF sy-subrc <> 0.
*            MESSAGE e172(/psyng/sp).
*
*          ENDIF.
*        ENDIF.


        gf_dispchg = gc_change.

        PERFORM enqueue.
      ELSE.                            "Change mode to DISPLAY

*        PERFORM authority_check_chgdisp USING act_display.
        gf_dispchg = gc_display.
        PERFORM dequeue.
      ENDIF.
      CLEAR sy-ucomm.

    WHEN 'INSERT'.

      PERFORM insert_row_into_tc USING  'TC_FREQTXT' 'GT_FREQTXT'.
      CLEAR gf_populated.
      CLEAR gf_freqtxt_data_change.

    WHEN 'DELETE'.

      CLEAR gs_freqtxt_wa1.
      REFRESH : gt_freqtxt_1 , gt_freqtxt_2.

      READ TABLE gt_freqtxt[] INTO gs_freqtxt_wa1 WITH KEY mark = 'X'.

      IF sy-subrc = 0.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = text-t07
                  text_question         = text-q01
                  text_button_1         = text-001
                  icon_button_1         = 'ICON_OKAY'
                  text_button_2         = text-002
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '2'
                  display_cancel_button = space
             IMPORTING
                  answer                = gf_answer
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
        IF gf_answer = 1.
          APPEND gs_freqtxt_wa1  TO gt_freqtxt.

          IF  gf_freqtxt_data_change IS INITIAL.
            gf_freqtxt_data_change = 'X'.
          ENDIF.
          PERFORM delete_row_from_tc
                USING
                  'TC_FREQTXT'
                  'GT_FREQTXT'
                  'MARK'.
        ENDIF.
        CLEAR gf_answer.

      ELSE.
        MESSAGE s168(/psyng/sw).
      ENDIF.

      CLEAR sy-ucomm.

    WHEN 'SASCEND' OR 'SDESCEND'.      "sort column

      PERFORM fcode_sort_tc USING 'tc_freqtxt' 'gt_freqtxt' sy-ucomm.
      CLEAR sy-ucomm.

    WHEN 'SAVE'.
      PERFORM save_0100.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT

*---------------------------------------------------------------------*
*       FORM insert_row_into_tc                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_TC_NAME                                                     *
*  -->  P_TABLE_NAME                                                  *
*---------------------------------------------------------------------*
FORM insert_row_into_tc USING    p_tc_name TYPE dynfnam
                                 p_table_name.

*-BEGIN OF LOCAL DATA--------------------------------------------------*
  DATA l_selline          LIKE sy-stepl.
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
  ASSIGN ('G_TC_LINES') TO <lines>.

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
  g_curr_line = l_selline.

* insert initial line
  INSERT INITIAL LINE INTO <table> INDEX l_selline.
*  APPEND INI
  <tc>-lines = <tc>-lines + 1.
*  g_curr_line = 0.
  SET CURSOR LINE g_curr_line.                              "OFFSET 0.



ENDFORM.                    " insert_row_into_tc



*&---------------------------------------------------------------------*
*&      Form  fcode_sort_tc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0293   text
*      -->P_0294   text
*      -->P_SY_UCOMM  text
*----------------------------------------------------------------------*
FORM fcode_sort_tc USING    value(p_0293)
                            value(p_0294)
                            p_sy_ucomm.

  DATA: l_table   TYPE dd02d-tabname,
         l_column  TYPE dd03d-fieldname,
         l_tabname TYPE dd02d-tabname.

  FIELD-SYMBOLS: <table> TYPE STANDARD TABLE,
                 <tc>    TYPE cxtab_control,
                 <cols>  TYPE cxtab_column.


  ASSIGN (p_0293) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  CONCATENATE p_0294 '[]' INTO l_tabname.
  ASSIGN (l_tabname) TO <table>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  LOOP AT <tc>-cols ASSIGNING <cols> WHERE selected = 'X'.
    SPLIT <cols>-screen-name AT '-' INTO l_table l_column.
    IF p_sy_ucomm = 'SASCEND'.
      SORT <table> BY (l_column).
    ELSE.
      SORT <table> BY (l_column) DESCENDING.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " fcode_sort_tc


*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM enqueue.
  CHECK NOT g_tabname IS INITIAL.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = g_tabname
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    gf_dispchg = gc_display.                "Display mode
  ENDIF.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  dequeue
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dequeue.
  CHECK NOT g_tabname IS INITIAL.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = g_tabname.

ENDFORM.                    " dequeue


*&---------------------------------------------------------------------*
*&      Form  delete_row_from_tc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0445   text
*      -->P_0446   text
*      -->P_0447   text
*----------------------------------------------------------------------*
FORM delete_row_from_tc USING  p_tc_name    TYPE dynfnam
                               p_table_name
                               p_mark_name..

*-BEGIN OF LOCAL
*DATA--------------------------------------------------*
  DATA: l_table_name LIKE feld-name,
        l_tabix      TYPE i,
        l_delflag TYPE i.

  FIELD-SYMBOLS: <tc>          TYPE cxtab_control,
                 <table>       TYPE STANDARD TABLE,
                 <wa>,
                 <mark_field>,
                 <field>.
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
      l_tabix = sy-tabix.

      DELETE <table> INDEX l_tabix.

      LOOP AT gt_freqtxt WHERE mark EQ 'X'.
        gt_freqtxt_1-freq = gt_freqtxt-freq.
        gt_freqtxt_1-numdays = gt_freqtxt-numdays.
        APPEND gt_freqtxt_1.
        gt_freqtxt_2-freq = gt_freqtxt-freq.
        gt_freqtxt_2-text = gt_freqtxt-text.
        APPEND gt_freqtxt_2.
      ENDLOOP.

      SELECT * FROM /psyng/mcrepid     "#EC CI_SEL_NESTED
               INTO CORRESPONDING FIELDS OF TABLE
               gt_repid.

      READ TABLE gt_repid WITH KEY frequency = gt_freqtxt_1-freq.

      IF sy-subrc = 0.
        MESSAGE e171(/psyng/sw).
      ELSE.

      DELETE /psyng/sw_freq FROM TABLE gt_freqtxt_1. "#EC CI_IMUD_NESTED
      DELETE /psyng/sw_freqt FROM TABLE gt_freqtxt_2."#EC CI_IMUD_NESTED


      ENDIF.
      IF sy-subrc = 0.
        MESSAGE s170(/psyng/sw).
        <tc>-lines = <tc>-lines - 1.
        l_delflag = 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF l_delflag <> 1.
    MESSAGE s168(/psyng/sw).
  ELSE.
    l_delflag = 0.
  ENDIF.


ENDFORM.                    " delete_row_from_tc
*&---------------------------------------------------------------------*
*&      Form  save_0100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_0100.
  DATA : i_message TYPE i.
  IF gf_freqtxt_data_change IS INITIAL.

    IF NOT gt_freqtxt[] IS INITIAL.

      DELETE gt_freqtxt WHERE
      freq = space OR
      numdays = space OR
      text = space.

      DELETE  /psyng/sw_freq FROM TABLE gt_freqtxt.

      REFRESH : gt_freqtxt_1 , gt_freqtxt_2.

      LOOP AT gt_freqtxt.
        gt_freqtxt_1-freq = gt_freqtxt-freq.
        gt_freqtxt_1-numdays = gt_freqtxt-numdays.
        APPEND gt_freqtxt_1.
        gt_freqtxt_2-freq = gt_freqtxt-freq.
        gt_freqtxt_2-text = gt_freqtxt-text.
        gt_freqtxt_2-lang = sy-langu.
        APPEND gt_freqtxt_2.
      ENDLOOP.

      MODIFY /psyng/sw_freq FROM TABLE  gt_freqtxt_1.
      MODIFY /psyng/sw_freqt FROM TABLE  gt_freqtxt_2.

      CLEAR gf_freqtxt_data_change.
      i_message = 1.

    ELSE.
      CLEAR gf_freqtxt_data_change.
    ENDIF.

    IF i_message = 1.
      MESSAGE s169(/psyng/sw).
      CLEAR : gf_freqtxt_data_change.

      COMMIT WORK.
      i_message = 0.

    ENDIF.
  ENDIF.

ENDFORM.                                                    " save_0100
