FUNCTION /psyng/sw_read_pbridge_systems.
*"--------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_PBRIDGE_SYSTEM STRUCTURE  /PSYNG/PBRIDGE_SYSTEMS
*"--------------------------------------------------------------------

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_system TYPE TABLE OF ty_pbridge_systems,
      ls_system TYPE ty_pbridge_systems,
      ls_req_system   TYPE ty_req_system,
      lv_http_status TYPE string,
      ls_sys TYPE /psyng/pbridge_systems.

  ef_success = 'X'.
  REFRESH : gt_messages.

  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

  ls_req_system-systemlow  = '0'.
  ls_req_system-systemhigh = '0'.

*  l_url = g_endpoint && 'BridgeReadSystemsList'.
  CONCATENATE g_endpoint 'BridgeReadSystemsList' into l_url.

  CLEAR go_http_client.
  http_init_client. "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_system c_json_empty_include.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response lt_system ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lt_system IS INITIAL.
    CLEAR ef_success.
  ELSE.
    LOOP AT lt_system INTO ls_system.
      ls_sys-systemid = ls_system-systemid.
      TRANSLATE ls_system-systemname TO UPPER CASE.
      ls_sys-systemname = ls_system-systemname.
      APPEND ls_sys TO et_pbridge_system.
      CLEAR ls_sys.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
