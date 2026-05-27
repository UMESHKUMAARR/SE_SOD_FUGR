FUNCTION /psyng/sw_get_plc_ruleset_ids.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(ET_PLC_RSETS) TYPE  /PSYNG/SW_PLCRSET_TT
*"  EXCEPTIONS
*"      NO_DATA_FOUND
*"----------------------------------------------------------------------

  DATA:
        l_url TYPE string,
        lv_http_status TYPE string,
        ls_api_req TYPE ty_api_rulset_req,
        l_json_response  TYPE string,
        lt_rulsets TYPE TABLE OF ty_api_ruleset_res,
        ls_rulsets TYPE ty_api_ruleset_res,
        ls_plc_rset TYPE /psyng/sw_plcrset.

  REFRESH et_plc_rsets.

*--Get connector configuration
  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

*--Prepare API request data
  ls_api_req-pageoffset = 0.
  ls_api_req-pagesize = 1000.

*--Prepare API url
  CONCATENATE g_endpoint 'BridgeRulesetSERulesets' INTO l_url.

*--Initialize the client
  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

*--Handle the authentication popup
  PERFORM authentication_popup USING gf_testmode g_username g_password.

*--Add header field
  http_add_header_field: 'Content-Type' 'application/json'.

*--Set json body
  http_set_json_body ls_api_req c_json_empty_include.

*--Send request
  http_send_request l_url if_http_request=>co_request_method_post.

*--Get response
  http_get_response l_json_response lt_rulsets ''.

*--Get http status
  PERFORM http_status CHANGING lv_http_status.

*--Add ruleset ID values to final table
  IF lt_rulsets IS NOT INITIAL.
    LOOP AT lt_rulsets INTO ls_rulsets.
      ls_plc_rset-rulesetid = ls_rulsets-ruleset_id.
      ls_plc_rset-description = ls_rulsets-description.
      ls_plc_rset-inactive = ls_rulsets-inactive.
      APPEND ls_plc_rset TO et_plc_rsets.
      CLEAR ls_plc_rset.
    ENDLOOP.
  ELSE.
    RAISE no_data_found.
  ENDIF.

ENDFUNCTION.
