FUNCTION /psyng/sw_read_api_func.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_TESTMODE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_FUN) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_FUN_OBJ) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PBRIDGE_FUN_DETAIL) TYPE  FLAG OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/API_SYSID
*"     VALUE(I_PLCVRS) TYPE  /PSYNG/SW_PLC_RULESET
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2
*"      ET_PBRIDGE_FUN STRUCTURE  /PSYNG/PBRIDGE_FUN
*"      ET_PBRIDGE_FUN_DETAIL STRUCTURE  /PSYNG/PBRIDGE_FUNC_DETAIL
*"      ET_PBRIDGE_FUN_OBJ STRUCTURE  /PSYNG/SW_PBRIDGE_FUN_OBJ
*"  EXCEPTIONS
*"      NO_DATA_FOUND
*"----------------------------------------------------------------------
  DATA: l_total_functions TYPE i.

  g_plcvrs = i_plcvrs.

  ef_success = 'X'.
  REFRESH : gt_messages.

  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

  IF if_pbridge_fun = 'X'.
    PERFORM read_pbridge_fun CHANGING et_pbridge_fun[].
  ENDIF.

  IF if_pbridge_fun_detail = 'X'.
    PERFORM read_pbridge_fun_detail USING i_sysid
                              CHANGING et_pbridge_fun_detail[].
  ENDIF.

  IF if_pbridge_fun_obj = 'X'.
    PERFORM read_pbridge_fun_obj USING i_sysid
                              CHANGING et_pbridge_fun_obj[].
  ENDIF.

  DESCRIBE TABLE et_pbridge_fun LINES l_total_functions.

  IF et_pbridge_fun[] IS INITIAL
  OR et_pbridge_fun_detail[] IS INITIAL
  OR et_pbridge_fun_obj[] IS INITIAL.
    DELETE gt_messages WHERE type = 'S'.
    CLEAR ef_success.
    RAISE no_data_found.
  ELSE.
    enmsg 'S' gt_messages 'Function data successfully ' 'pulled with'
                                      l_total_functions 'functions'.
  ENDIF.

  APPEND LINES OF gt_messages TO et_messages.
  REFRESH gt_messages.

ENDFUNCTION.
