FUNCTION /psyng/sw_pull_mit_cont_plc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_CONTROL_HEADERS) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_USE_PUSH) TYPE  FLAG OPTIONAL
*"     REFERENCE(I_CONTROL_ASSIGN) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     REFERENCE(ET_MIT_CONT_HEAD_PLC) TYPE
*"        /PSYNG/SW_MIT_CONT_HEAD_PLC_TT
*"     REFERENCE(ET_MIT_CONT_ASSIGN) TYPE  /PSYNG/SW_MIT_EMP_VLATION_TT
*"  TABLES
*"      ET_MESSAGES STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

*--Get connector parameters
  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

*--Pull mitigation control headers
  IF i_control_headers = 'X'.
    PERFORM get_mit_headers USING i_use_push
                                        CHANGING et_mit_cont_head_plc.
  ENDIF.

*--Pull mitigation control assignments
  IF i_control_assign = 'X'.
    PERFORM get_mit_assign USING i_use_push CHANGING et_mit_cont_assign.
  ENDIF.

  APPEND LINES OF gt_messages TO et_messages.


ENDFUNCTION.
