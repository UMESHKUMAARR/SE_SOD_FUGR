class /PSYNG/SW_RULESET_LOGGER definition
  public
  final
  create public .

public section.

  types:
    BEGIN OF ty_alv_log_line,
        msg_type(1) TYPE c,
        work_step   TYPE string,
        message     TYPE string,
        key         TYPE string,
      END OF ty_alv_log_line .
  types:
    BEGIN OF ty_log_line,
        work_step TYPE string,
        key       TYPE string.
        INCLUDE TYPE symsg.
      TYPES: END OF ty_log_line .
  types:
    ty_alv_log_table TYPE STANDARD TABLE OF ty_alv_log_line WITH DEFAULT KEY .
  types:
    ty_log_table TYPE STANDARD TABLE OF ty_log_line WITH DEFAULT KEY .

  methods ADD_LOG_LINE
    importing
      !I_WORK_STEP type STRING
      !I_MSGTY type SYMSGTY
      !I_MSGID type SYMSGID optional
      !I_MSGNO type SYMSGNO
      !I_MSGV1 type SYMSGV optional
      !I_MSGV2 type SYMSGV optional
      !I_MSGV3 type SYMSGV optional
      !I_MSGV4 type SYMSGV optional
      !I_KEY type STRING optional .
  methods DISPLAY_LOG .
protected section.
private section.

  data MESSAGES type TY_LOG_TABLE .
  constants MSG_CLASS type SYMSGID value '/PSYNG/SW_RULESET'."#NO_TEXT.
ENDCLASS.



CLASS /PSYNG/SW_RULESET_LOGGER IMPLEMENTATION.


  METHOD add_log_line.

    DATA: lv_log_line TYPE me->ty_log_line.

    CLEAR lv_log_line.
    lv_log_line-work_step = i_work_step.
    lv_log_line-msgty     = i_msgty.
    IF i_msgid <> ''.
      lv_log_line-msgid = i_msgid.
    ELSE.
      lv_log_line-msgid = me->msg_class.
    ENDIF.
    lv_log_line-msgno = i_msgno.
    lv_log_line-msgv1 = i_msgv1.
    lv_log_line-msgv2 = i_msgv2.
    lv_log_line-msgv3 = i_msgv3.
    lv_log_line-msgv4 = i_msgv4.
    lv_log_line-key   = i_key.

    APPEND lv_log_line TO me->messages.
  ENDMETHOD.


  METHOD display_log.
    FIELD-SYMBOLS: <fs_log_line> TYPE me->ty_log_line.
    DATA: ls_alv_log_line  TYPE me->ty_alv_log_line.
    DATA: lt_alv_log_table TYPE me->ty_alv_log_table.

    DATA: o_alv           TYPE REF TO cl_salv_table.
    DATA: o_alv_functions TYPE REF TO cl_salv_functions.
    DATA: o_alv_display   TYPE REF TO cl_salv_display_settings.
    DATA: o_alv_columns   TYPE REF TO cl_salv_columns_table.
    DATA: o_alv_column    TYPE REF TO cl_salv_column.

    LOOP AT me->messages ASSIGNING <fs_log_line>.

      MESSAGE ID <fs_log_line>-msgid TYPE <fs_log_line>-msgty NUMBER <fs_log_line>-msgno
           WITH <fs_log_line>-msgv1 <fs_log_line>-msgv2 <fs_log_line>-msgv3 <fs_log_line>-msgv4
           INTO ls_alv_log_line-message.

      ls_alv_log_line-msg_type = <fs_log_line>-msgty.
      ls_alv_log_line-work_step = <fs_log_line>-work_step.
      ls_alv_log_line-key = <fs_log_line>-key.

      APPEND ls_alv_log_line TO lt_alv_log_table.

    ENDLOOP.

    cl_salv_table=>factory(
      IMPORTING
        r_salv_table = o_alv
      CHANGING
        t_table = lt_alv_log_table
    ).

    o_alv_functions = o_alv->get_functions( ).
    o_alv_functions->set_all( abap_false ).

    o_alv_display = o_alv->get_display_settings( ).
    o_alv_display->set_list_header( text-001 ).
    o_alv_display->set_striped_pattern( abap_true ).

    o_alv_columns = o_alv->get_columns( ).
    o_alv_columns->set_optimize( 'X' ).

    o_alv_column ?= o_alv_columns->get_column( 'MSG_TYPE' ).
    o_alv_column->set_long_text( text-002 ).
    o_alv_column ?= o_alv_columns->get_column( 'WORK_STEP' ).
    o_alv_column->set_long_text( text-003 ).
    o_alv_column ?= o_alv_columns->get_column( 'MESSAGE' ).
    o_alv_column->set_long_text( text-004 ).
    o_alv_column ?= o_alv_columns->get_column( 'KEY' ).
    o_alv_column->set_long_text( text-005 ).

    o_alv->display( ).

  ENDMETHOD.
ENDCLASS.
