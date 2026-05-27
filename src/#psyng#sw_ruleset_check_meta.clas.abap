class /PSYNG/SW_RULESET_CHECK_META definition
  public
  inheriting from /PSYNG/SW_ACL_RULESET_CHECK
  final
  create public .

public section.

  methods CHECK_CONFLICT_DETAILS
    redefinition .
  methods CHECK_CONFLICT_HEADER
    redefinition .
  methods CHECK_CONFLICT_TEXT
    redefinition .
  methods CHECK_FUNCTION_DETAILS
    redefinition .
  methods CHECK_FUNCTION_HEADER
    redefinition .
  methods CHECK_FUNCTION_TEXT
    redefinition .
  methods CHECK_MATRIX_DETAILS
    redefinition .
  methods CHECK_MATRIX_HEADER
    redefinition .
  methods CHECK_MATRIX_TEXT
    redefinition .
  methods CHECK_PROBLEM_HEADER
    redefinition .
  methods CHECK_PROCESS_HEADER
    redefinition .
  methods CHECK_PROCESS_TEXT
    redefinition .
  methods CHECK_SEARCH_RULE_DETAILS
    redefinition .
  methods CHECK_SEARCH_RULE_HEADER
    redefinition .
  methods CHECK_SEARCH_RULE_TEXT
    redefinition .
  methods CHECK_PROBLEM_TEXT
    redefinition .
protected section.
private section.
ENDCLASS.



CLASS /PSYNG/SW_RULESET_CHECK_META IMPLEMENTATION.


METHOD check_conflict_details.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_conf_d.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_conflict.

    "EMPTY Check
    IF <fs_line>-sod_conflict = '' OR
       <fs_line>-sod_function_1 = '' OR
       ( <fs_line>-sod_function_1 = '' AND <fs_line>-sod_function_2 <> '' ) OR
       ( <fs_line>-sod_function_2 = '' AND <fs_line>-sod_function_3 <> '' ) OR
       ( <fs_line>-sod_function_3 = '' AND <fs_line>-sod_function_4 <> '' ) OR
       ( <fs_line>-sod_function_4 = '' AND <fs_line>-sod_function_5 <> '' ).
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-conflict_header TRANSPORTING NO FIELDS WHERE sod_conflict = <fs_line>-sod_conflict.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'CONFLICT_HEADER'
          i_key = lv_key
      ).
    ENDIF.
    IF <fs_line>-sod_function_1 <> ''.
      LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function_1.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'FUNCTION_HEADER(1)'
            i_key = lv_key
        ).
      ENDIF.
    ENDIF.
    IF <fs_line>-sod_function_2 <> ''.
      LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function_2.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'FUNCTION_HEADER(2)'
            i_key = lv_key
        ).
      ENDIF.
    ENDIF.
    IF <fs_line>-sod_function_3 <> ''.
      LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function_3.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'FUNCTION_HEADER(3)'
            i_key = lv_key
        ).
      ENDIF.
    ENDIF.
    IF <fs_line>-sod_function_4 <> ''.
      LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function_4.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'FUNCTION_HEADER(4)'
            i_key = lv_key
        ).
      ENDIF.
    ENDIF.
    IF <fs_line>-sod_function_5 <> ''.
      LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function_5.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_DETAILS'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'FUNCTION_HEADER(5)'
            i_key = lv_key
        ).
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_conflict_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_conf_h.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_conflict.

    "EMPTY Check
    IF <fs_line>-sod_conflict = '' OR
       <fs_line>-content_comp = '' OR
       <fs_line>-risk_id = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_HEADER'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-conflict_text TRANSPORTING NO FIELDS WHERE sod_conflict = <fs_line>-sod_conflict.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'CONFLICT_TEXT'
          i_key = lv_key
      ).
    ENDIF.
    LOOP AT it_full_data-conflict_details TRANSPORTING NO FIELDS WHERE sod_conflict = <fs_line>-sod_conflict.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'CONFLICT_DETAILS'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_conflict_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_conf_t.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_conflict.

    "EMPTY Check
    IF <fs_line>-sod_conflict = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-description = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/SAST/CL_RULESET_CHECK_META~CHECK_CONFLICT_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-conflict_header TRANSPORTING NO FIELDS WHERE sod_conflict = <fs_line>-sod_conflict.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_CONFLICT_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'CONFLICT_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_function_details.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_func_d.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_function.

    "EMPTY Check
    IF <fs_line>-sod_function = '' OR
       <fs_line>-search_rule = '' .
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_DETAILS'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_DETAILS'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'FUNCTION_HEADER'
          i_key = lv_key
      ).
    ENDIF.
    LOOP AT it_full_data-search_rule_header TRANSPORTING NO FIELDS WHERE search_rule = <fs_line>-search_rule.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_DETAILS'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'SEARCH_RULE_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_function_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_func_h.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_function.

    "EMPTY Check
    IF <fs_line>-sod_function = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_HEADER'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-function_text TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'FUNCTION_TEXT'
          i_key = lv_key
      ).
    ENDIF.
    LOOP AT it_full_data-function_details TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'FUNCTION_DETAILS'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_function_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_func_t.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-sod_function.

    "EMPTY Check
    IF <fs_line>-sod_function = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-description = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-function_header TRANSPORTING NO FIELDS WHERE sod_function = <fs_line>-sod_function.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_FUNCTION_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'FUNCTION_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_matrix_details.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_rule_d.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-rulesetid.

    "EMPTY Check
    IF <fs_line>-rulesetid = '' OR
       <fs_line>-sod_conflict = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_DETAILS'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "BOOLEAN Check
    IF <fs_line>-active <> '' AND <fs_line>-active <> 'X'.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_DETAILS'
          i_msgty = 'E'
          i_msgno = 103
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-matrix_header TRANSPORTING NO FIELDS WHERE rulesetid = <fs_line>-rulesetid.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_DETAILS'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'MATRIX_HEADER'
          i_key = lv_key
      ).
    ENDIF.
    LOOP AT it_full_data-conflict_header TRANSPORTING NO FIELDS WHERE sod_conflict = <fs_line>-sod_conflict.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_DETAILS'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'CONFLICT_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_matrix_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_rule_h.
  DATA: lv_data_lines TYPE i,
        lv_key        TYPE string.

  ev_is_valid = 'X'.

  lv_data_lines = lines( it_check_data ).
  IF lv_data_lines = 1.
    LOOP AT it_check_data ASSIGNING <fs_line>.
      CLEAR lv_key.
      lv_key = <fs_line>-rulesetid.

      "EMPTY Check
      IF <fs_line>-rulesetid = '' OR
         <fs_line>-src_sysid = '' OR
         <fs_line>-src_client = '' OR
         <fs_line>-export_date = '' OR
         <fs_line>-export_time = ''.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_HEADER'
            i_msgty = 'E'
            i_msgno = 100
            i_key = lv_key
        ).
      ENDIF.
      "EXISTENCE Check
      LOOP AT it_full_data-matrix_details TRANSPORTING NO FIELDS WHERE rulesetid = <fs_line>-rulesetid.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_HEADER'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'MATRIX_DETAILS'
            i_key = lv_key
        ).
      ENDIF.
      LOOP AT it_full_data-matrix_text TRANSPORTING NO FIELDS WHERE rulesetid = <fs_line>-rulesetid.
        EXIT.
      ENDLOOP.
      IF sy-subrc <> 0.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
            i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_HEADER'
            i_msgty = 'E'
            i_msgno = 101
            i_msgv1 = 'MATRIX_TEXT'
            i_key = lv_key
        ).
      ENDIF.

    ENDLOOP.
  ELSEIF
    ev_is_valid = ''.
    "Logging
    me->logger->add_log_line(
      EXPORTING
        i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_HEADER'
        i_msgty = 'E'
        i_msgno = 102
        i_key = lv_key
    ).
  ENDIF.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_matrix_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_rule_t.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-rulesetid.

    "EMPTY Check
    IF <fs_line>-rulesetid = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-description = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-matrix_header TRANSPORTING NO FIELDS WHERE rulesetid = <fs_line>-rulesetid.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_MATRIX_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'MATRIX_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_problem_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_risk_h.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.
  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-risk_id.

    IF <fs_line>-risk_id = '' OR
       <fs_line>-severity = '' OR
       <fs_line>-reporting_group = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_HEADER'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-problem_text TRANSPORTING NO FIELDS WHERE risk_id = <fs_line>-risk_id.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'PROBLEM_TEXT'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_problem_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_risk_t.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-risk_id.

    "EMPTY Check
    IF <fs_line>-risk_id = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-short_descriptio = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    IF <fs_line>-problem_text = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_TEXT'
          i_msgty = 'W'
          i_msgno = 114
          i_key = lv_key
      ).
    ENDIF.
    IF <fs_line>-solution_text = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_TEXT'
          i_msgty = 'W'
          i_msgno = 115
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-problem_header TRANSPORTING NO FIELDS WHERE risk_id = <fs_line>-risk_id.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROBLEM_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'PROBLEM_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_process_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_buspro.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-busprocid.

    "EMPTY Check
    IF <fs_line>-busprocid = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROCESS_HEADER'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-bus_process_text TRANSPORTING NO FIELDS WHERE busprocid = <fs_line>-busprocid.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROCESS_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'BUS_PROCESS_TEXT'
          i_key = lv_key
      ).
    ENDIF.

  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.
ENDMETHOD.


METHOD check_process_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_busprt.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-busprocid.

    "EMPTY Check
    IF <fs_line>-busprocid = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-description = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROCESS_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-bus_process_header TRANSPORTING NO FIELDS
      WHERE busprocid = <fs_line>-busprocid.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_PROCESS_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'BUS_PROCESS_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_search_rule_details.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_auth_d.
  FIELD-SYMBOLS: <fs_check_entry> TYPE /psyng/sw_auth_d.
  DATA lv_key TYPE string.

  DATA: lv_counter         TYPE i,
        lv_strlow          TYPE string,
        lv_strhigh         TYPE string,
        lv_check_name      TYPE xupname.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-search_rule.

    "EMPTY Check
    "Specific Empty check on low field
    "as it can be blank or non blank based on selecton
    "screen parameter
    " If i_null EQ X, treat low value as error , if not EQ X,"
    "then show as warning and let the processing continue.
*    IF i_null EQ 'X'.
*      IF <fs_line>-low = '' .
*        ev_is_valid = ''.
*        "Logging
*        me->logger->add_log_line(
*          EXPORTING
*  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
*  i_msgty = 'E'
*  i_msgno = 100
*  i_key = lv_key
*).
*      ENDIF.
*
*    ELSE.
*      IF <fs_line>-low = '' .
*        "Logging
*        me->logger->add_log_line(
*          EXPORTING
*  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
*  i_msgty = 'W'
*  i_msgno = 100
*  i_key = lv_key
*).
*      ENDIF.
*    ENDIF.

    IF i_null EQ 'X'.
      "Empty check for all othe rules.
      IF <fs_line>-search_rule = '' OR
         <fs_line>-auth_group = '' OR
         <fs_line>-object = '' OR
         <fs_line>-field = '' OR
         <fs_line>-low = '' OR
         <fs_line>-searchtype = ''.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 100
  i_key = lv_key
).
      ENDIF.
    ELSE.
      "Empty check for all othe rules.
      IF <fs_line>-search_rule = '' OR
         <fs_line>-auth_group = '' OR
         <fs_line>-object = '' OR
         <fs_line>-field = '' OR
*       <fs_line>-low = '' OR
         <fs_line>-searchtype = ''.
        ev_is_valid = ''.
        "Logging
        me->logger->add_log_line(
          EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 100
  i_key = lv_key
).
      ELSE.
        IF <fs_line>-low = '' .
          "Logging
          me->logger->add_log_line(
            EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'W'
  i_msgno = 100
  i_key = lv_key
).
        ENDIF.
      ENDIF.
    ENDIF.
    "EXISTENCE Check
LOOP AT it_full_data-search_rule_header TRANSPORTING NO FIELDS WHERE search_rule = <fs_line>-search_rule.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 101
  i_msgv1 = 'SEARCH_RULE_HEADER'
  i_key = lv_key
).
    ENDIF.

    IF NOT <fs_line>-auth_group CO me->numbers_and_capitalletters.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 105
  i_key = lv_key
).
    ENDIF.

    "Permission group (AKA permission) in search rules
    LOOP AT it_check_data TRANSPORTING NO FIELDS
      WHERE search_rule = <fs_line>-search_rule AND
            auth_group = <fs_line>-auth_group AND
            object <> <fs_line>-object.
      EXIT.
    ENDLOOP.
    IF sy-subrc = 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 106
  i_key = lv_key
).
    ENDIF.

    "(1) Logical operators in search rules: general
    IF <fs_line>-searchtype <> 'AND' AND <fs_line>-searchtype <> 'OR'.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 107
  i_key = lv_key
).
    ENDIF.

    LOOP AT it_check_data TRANSPORTING NO FIELDS
      WHERE search_rule = <fs_line>-search_rule
        AND auth_group  = <fs_line>-auth_group AND
            object      = <fs_line>-object AND
            field <> <fs_line>-field.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0 AND <fs_line>-searchtype <> 'OR'.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 108
  i_key = lv_key
).
    ENDIF.

    IF <fs_line>-field = 'ACTVT' AND
      ( <fs_line>-low CA '*' OR <fs_line>-high CA '*' ).
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'W'
  i_msgno = 109
  i_key = lv_key
).
    ENDIF.

    CLEAR: lv_strlow, lv_strhigh.
    lv_strlow = <fs_line>-low.
    lv_strhigh = <fs_line>-high.
    DO.
      REPLACE ALL OCCURRENCES OF '*' IN lv_strlow WITH '%'.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
*    REPLACE ALL OCCURRENCES OF '*' IN lv_strlow WITH '%'.

    DO.
      REPLACE ALL OCCURRENCES OF '*' IN lv_strhigh WITH '%'.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
*    REPLACE ALL OCCURRENCES OF '*' IN lv_strhigh WITH '%'.
    IF lv_strlow CP '*%+*' OR lv_strhigh CP '*%+*'.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'E'
  i_msgno = 110
  i_key = lv_key
).
    ENDIF.

    IF <fs_line>-object = 'S_SERVICE' AND
       <fs_line>-field = 'SRV_TYPE' AND
       <fs_line>-low = 'HT'.
      LOOP AT it_check_data ASSIGNING <fs_check_entry>
          WHERE search_rule = <fs_line>-search_rule
             AND auth_group = <fs_line>-auth_group
             AND object = <fs_line>-object
             AND field = 'SRV_NAME'.
        CLEAR: lv_strlow, lv_strhigh, lv_check_name.
        lv_strlow = <fs_check_entry>-low.
        DO.
          REPLACE ALL OCCURRENCES OF '*' IN lv_strlow WITH '%'.
          IF sy-subrc NE 0. EXIT. ENDIF.
        ENDDO.
*        REPLACE ALL OCCURRENCES OF '*' IN lv_strlow WITH '%'.
        IF NOT lv_strlow CP '*%*'.
          SELECT SINGLE name
          FROM usobhash
          INTO lv_check_name
          WHERE name = <fs_check_entry>-low
          AND type = <fs_line>-low.              "#EC SAST_CI_GEN_CHECK

          IF sy-subrc <> 0 OR lv_check_name = ''.
            "Logging
            me->logger->add_log_line(
              EXPORTING
  i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_DETAILS'
  i_msgty = 'W'
  i_msgno = 111
  i_key = lv_key
).
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

  IF <fs_check_entry> IS ASSIGNED.
    UNASSIGN <fs_check_entry>.
  ENDIF.
ENDMETHOD.


METHOD check_search_rule_header.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_auth_h.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-search_rule.

    "EMPTY Check
    IF <fs_line>-search_rule = '' OR
       ( <fs_line>-single_critical = 'X' AND <fs_line>-risk_id = '' ) OR
       <fs_line>-content_comp = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_HEADER'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "BOOLEAN Check
    IF ( <fs_line>-active <> '' AND <fs_line>-active <> 'X' ) OR
       ( <fs_line>-single_critical <> '' AND <fs_line>-single_critical <> 'X' ) OR
       ( <fs_line>-s4hana_inactive <> '' AND <fs_line>-s4hana_inactive <> 'X' ).
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_HEADER'
          i_msgty = 'E'
          i_msgno = 103
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-search_rule_text TRANSPORTING NO FIELDS WHERE search_rule = <fs_line>-search_rule.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'SEARCH_RULE_TEXT'
          i_key = lv_key
      ).
    ENDIF.
    LOOP AT it_full_data-search_rule_details TRANSPORTING NO FIELDS WHERE search_rule = <fs_line>-search_rule.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_HEADER'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'SEARCH_RULE_DETAILS'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.

  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.


METHOD check_search_rule_text.

  FIELD-SYMBOLS: <fs_line> TYPE /psyng/sw_auth_t.
  DATA lv_key TYPE string.

  ev_is_valid = 'X'.

  LOOP AT it_check_data ASSIGNING <fs_line>.
    CLEAR lv_key.
    lv_key = <fs_line>-search_rule.

    "EMPTY Check
    IF <fs_line>-search_rule = '' OR
       <fs_line>-lang = '' OR
       <fs_line>-description = ''.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_TEXT'
          i_msgty = 'E'
          i_msgno = 100
          i_key = lv_key
      ).
    ENDIF.
    "EXISTENCE Check
    LOOP AT it_full_data-search_rule_header TRANSPORTING NO FIELDS WHERE search_rule = <fs_line>-search_rule.
      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      ev_is_valid = ''.
      "Logging
      me->logger->add_log_line(
        EXPORTING
          i_work_step = '/PSYNG/SW_RULESET_CHECK_META~CHECK_SEARCH_RULE_TEXT'
          i_msgty = 'E'
          i_msgno = 101
          i_msgv1 = 'SEARCH_RULE_HEADER'
          i_key = lv_key
      ).
    ENDIF.
  ENDLOOP.
  IF <fs_line> IS ASSIGNED.
    UNASSIGN <fs_line>.
  ENDIF.

ENDMETHOD.
ENDCLASS.
