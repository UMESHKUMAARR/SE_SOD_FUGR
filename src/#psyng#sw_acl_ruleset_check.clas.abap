class /PSYNG/SW_ACL_RULESET_CHECK definition
  public
  abstract
  create public .

public section.

  methods CONSTRUCTOR
    importing
      !LOGGER type ref to /PSYNG/SW_RULESET_LOGGER
      !DELETE_DB type BOOLEAN optional .
  methods CHECK_PROCESS_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_BUSPRO_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_PROCESS_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_BUSPRT_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_MATRIX_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_RULE_H_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_MATRIX_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_RULE_T_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_MATRIX_DETAILS
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_RULE_D_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_CONFLICT_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_CONF_H_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_CONFLICT_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_CONF_T_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_CONFLICT_DETAILS
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_CONF_D_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_FUNCTION_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_FUNC_H_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_FUNCTION_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_FUNC_T_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_FUNCTION_DETAILS
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_FUNC_D_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_SEARCH_RULE_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_AUTH_H_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_SEARCH_RULE_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_AUTH_T_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_SEARCH_RULE_DETAILS
  abstract
    importing
      !I_NULL type BOOLEAN optional
      !IT_CHECK_DATA type /PSYNG/SW_AUTH_D_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_PROBLEM_HEADER
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_RISK_H_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_PROBLEM_TEXT
  abstract
    importing
      !IT_CHECK_DATA type /PSYNG/SW_RISK_T_T
      !IT_FULL_DATA type /PSYNG/SW_IMPORT
    exporting
      !EV_IS_VALID type BOOLEAN .
  methods CHECK_ALL
    importing
      !I_CHECK_DATA type /PSYNG/SW_IMPORT
      !I_NULL type BOOLEAN optional
    returning
      value(R_IS_VALID) type BOOLEAN .
protected section.

  data LOGGER type ref to /PSYNG/SW_RULESET_LOGGER .
  data DELETE_DB type BOOLEAN value '' ."#NO_TEXT.
  constants NUMBERS_AND_CAPITALLETTERS type STRING
  value 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789' ."#NO_TEXT.
private section.
ENDCLASS.



CLASS /PSYNG/SW_ACL_RULESET_CHECK IMPLEMENTATION.


  METHOD check_all.

    DATA: lv_valid TYPE boolean.

    r_is_valid = 'X'.


    CLEAR lv_valid.
    me->check_process_header(
      EXPORTING
        it_check_data =  i_check_data-bus_process_header   " SW : Table type for /PSYNG/SW_BUSPRO
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =  lv_valid   " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_process_text(
      EXPORTING
        it_check_data =   i_check_data-bus_process_text  " SW : Table Type for /PSYNG/SW_BUSPRT
        it_full_data  =   i_check_data  " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =   lv_valid  " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.

    CLEAR lv_valid.
    me->check_matrix_header(
      EXPORTING
        it_check_data = i_check_data-matrix_header    " SW : Table Type for /PSYNG/SW_RULE_H
        it_full_data  = i_check_data    " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =  lv_valid   " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_matrix_text(
      EXPORTING
        it_check_data =    i_check_data-matrix_text " SW : Table Type for /PSYNG/SW_RULE_T
        it_full_data  =    i_check_data " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =   lv_valid  " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_matrix_details(
      EXPORTING
        it_check_data =  i_check_data-matrix_details   " SW : Table Type for /PSYNG/SW_RULE_D
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_conflict_header(
      EXPORTING
        it_check_data =  i_check_data-conflict_header   " SW : Table Type for /PSYNG/SW_CONF_H
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_conflict_text(
      EXPORTING
        it_check_data =  i_check_data-conflict_text   " SW : Table Type for /PSYNG/SW_CONF_T
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_conflict_details(
      EXPORTING
        it_check_data =   i_check_data-conflict_details  " SW : Table Type for /PSYNG/SW_CONF_D
        it_full_data  =   i_check_data  " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =  lv_valid   " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_function_header(
      EXPORTING
        it_check_data =  i_check_data-function_header   " SW : Table Type for /PSYNG/SW_FUNC_H
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_function_text(
      EXPORTING
        it_check_data =  i_check_data-function_text   " SW : Table Type for /PSYNG/SW_FUNC_T
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_function_details(
      EXPORTING
        it_check_data =  i_check_data-function_details   " SW : table Type for /PSYNG/SW_FUNC_D
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_search_rule_header(
      EXPORTING
        it_check_data =  i_check_data-search_rule_header   " SW : Table Type for /PSYNG/SW_AUTH_H
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_search_rule_text(
      EXPORTING
        it_check_data = i_check_data-search_rule_text    " SW : Table Type for /PSYNG/SW_AUTH_T
        it_full_data  = i_check_data    " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid     " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_search_rule_details(
      EXPORTING
        i_null        =   i_null
        it_check_data =   i_check_data-search_rule_details
        it_full_data  =   i_check_data
      IMPORTING
        ev_is_valid   =   lv_valid  " Boolean Variable (X=True, -=False, Space=Unknown)
    ).

    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_problem_header(
      EXPORTING
        it_check_data =  i_check_data-problem_header   " SW : Table Type for /PSYNG/SW_RISK_H
        it_full_data  =  i_check_data   " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   = lv_valid    " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.


    CLEAR lv_valid.
    me->check_problem_text(
      EXPORTING
        it_check_data =   i_check_data-problem_text  " SW : Table Type for /PSYNG/SW_RISK_T
        it_full_data  =   i_check_data  " SW: Import structure for IBS XML data
      IMPORTING
        ev_is_valid   =  lv_valid   " Boolean Variable (X=True, -=False, Space=Unknown)
    ).
    IF lv_valid = ''.
      r_is_valid = ''.
    ENDIF.

  ENDMETHOD.


  METHOD constructor.
    me->logger = logger.

    me->delete_db = delete_db.

  ENDMETHOD.
ENDCLASS.
