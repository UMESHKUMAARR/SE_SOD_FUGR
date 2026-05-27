*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_BRIDGEF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  READ_PCLOUD_CONFLICTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_RETURN  text
*      <--P_ET_RESPONSE  text
*----------------------------------------------------------------------*
FORM read_pcloud_con CHANGING et_pbridge_con TYPE tt_pbridge_con.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_con TYPE TABLE OF ty_pbridge_res_con,
      ls_con TYPE ty_pbridge_res_con,
      ls_req_con TYPE ty_pbridge_req_con,
      ls_pbridge_con TYPE /psyng/api_conf,
      lv_http_status TYPE string.

*--Prepare API request data
  ls_req_con-ruleset_id = g_plcvrs.

*--Prepare API url
  CONCATENATE g_endpoint 'BridgeRulesetSEConflictHeaders' INTO
   l_url.

*--Initialize the client
  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

*--Handle the authentication popup
  PERFORM authentication_popup USING gf_testmode g_username g_password.

*--Add header field
  http_add_header_field: 'Content-Type' 'application/json'.

*--Set json body
  http_set_json_body ls_req_con c_json_empty_skip.

*--Send request
  http_send_request l_url if_http_request=>co_request_method_post.

*--Get response
  http_get_response l_json_response lt_con ''.

*--Get http status
  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    IF NOT lt_con IS INITIAL.
      LOOP AT lt_con INTO ls_con.
        CLEAR ls_pbridge_con.
        MOVE-CORRESPONDING ls_con TO ls_pbridge_con.
        APPEND ls_pbridge_con TO et_pbridge_con.
      ENDLOOP.
    ELSE.
      enmsg 'I' gt_messages 'Conflicts not available ' '& '
                                   'Status code is ' lv_http_status.
    ENDIF.
  ELSE.
    CLEAR: g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Conflicts not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_PBRIDGE_CFG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_CFG_DETIAL  text
*      <--P_G_HOST  text
*      <--P_G_PORT  text
*      <--P_G_SCHEME  text
*      <--P_G_ENDPOINT  text
*      <--P_G_USERNAME  text
*      <--P_G_PASSWORD  text
*      <--P_G_SYSTEMID  text
*----------------------------------------------------------------------*
FORM get_connector_param  CHANGING g_host
                               g_port
                               g_scheme
                               g_username
                               g_password.

  DATA:
        ls_cfg TYPE /psyng/bridgecfg,
        lt_cfg TYPE TABLE OF /psyng/bridgecfg.
*        l_pass TYPE c LENGTH 55,
*        l_host TYPE c LENGTH 255,
*       l_user TYPE c LENGTH 255,
*       l_pass TYPE c LENGTH 255,
*       l_port TYPE c LENGTH 255.

  CALL FUNCTION '/PSYNG/SW_BRIDGE_GET_CFG'
   IMPORTING
     e_host        = g_host
     e_port        = g_port
     e_user        = g_username
     e_pass        = g_password.

  IF g_host IS INITIAL.
    g_host = 'pathbridge.stage.appsiangrc.com'.
  ENDIF.

  IF g_port IS INITIAL.
    g_port = '443'.
  ENDIF.

  IF g_username IS INITIAL.
    g_username = 'api_en'.
  ENDIF.

*  SELECT *
*         FROM /psyng/bridgecfg
*         INTO TABLE lt_cfg.
*  IF sy-subrc = 0.
*    LOOP AT lt_cfg INTO ls_cfg.
*      CASE ls_cfg-param.
*        WHEN 'Hostname'.
*          g_host = ls_cfg-value.
*        WHEN 'Username'.
*          g_username = ls_cfg-value.
*        WHEN 'Password'.
*          PERFORM decrypt_password USING ls_cfg-value
*                     CHANGING l_pass.
*          g_password = l_pass.
*        WHEN 'Port'.
*          g_port = ls_cfg-value.
*      ENDCASE.
*    ENDLOOP.
*  ELSE.
*    CLEAR: g_host, g_username, g_password, g_port.
*  ENDIF.

  g_scheme = 2.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  AUTHENTICATION_POPUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GF_TESTMODE  text
*      -->P_G_USERNAME  text
*      -->P_G_PASSWORD  text
*----------------------------------------------------------------------*
FORM authentication_popup  USING    gf_testmode TYPE flag
                                    g_username  TYPE string
                                    g_password  TYPE string.

  IF gf_testmode IS INITIAL.
    go_http_client->propertytype_logon_popup =
                                           go_http_client->co_disabled.
  ENDIF.
  CALL METHOD go_http_client->authenticate
    EXPORTING
      username = g_username
      password = g_password.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HTTP_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LV_HTTP_STATUS  text
*----------------------------------------------------------------------*
FORM http_status  CHANGING lv_http_status TYPE string.

  lv_http_status = go_http_client->response->get_header_field(
                                                       '~status_code' ).

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_PCLOUD_CONFLICTS_TXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_CONFLICTS_TXT[]  text
*----------------------------------------------------------------------*
FORM read_pcloud_con_txt  CHANGING et_pbridge_con_txt TYPE
                                                     tt_pbridge_con_txt.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_con_txt TYPE TABLE OF ty_res_pbridge_con_txt,
      ls_con_txt TYPE ty_res_pbridge_con_txt,
      ls_req_con_txt TYPE ty_pbridge_req_con,
      ls_pbridge_con_txt TYPE /psyng/api_conf_txt,
      lv_http_status TYPE string.

*--Prepare API request data
  ls_req_con_txt-ruleset_id = g_plcvrs.

*--Prepare API url
  CONCATENATE g_endpoint 'BridgeRulesetSEConflictTexts' INTO l_url.

*--Initialize the client
  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

*--Handle the authentication popup
  PERFORM authentication_popup USING gf_testmode g_username g_password.

*--Add header field
  http_add_header_field: 'Content-Type' 'application/json'.

*--Set json body
  http_set_json_body ls_req_con_txt c_json_empty_skip.

*--Send request
  http_send_request l_url if_http_request=>co_request_method_post.

*--Get response
  http_get_response l_json_response lt_con_txt ''.

  PERFORM http_status CHANGING lv_http_status.
  IF lv_http_status = '200'.
    IF NOT lt_con_txt IS INITIAL.
      LOOP AT lt_con_txt INTO ls_con_txt.
        CLEAR ls_pbridge_con_txt.
        MOVE-CORRESPONDING ls_con_txt TO ls_pbridge_con_txt.
        APPEND ls_pbridge_con_txt TO et_pbridge_con_txt.
      ENDLOOP.
    ELSE.
      enmsg 'I' gt_messages 'Conflict texts not available ' '& '
                                   'Status code is ' lv_http_status.
    ENDIF.
  ELSE.
    CLEAR: g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Conflict texts not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_PCLOUD_CON_DETAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_CON_DETAIL[]  text
*----------------------------------------------------------------------*
FORM read_pcloud_con_detail  CHANGING
                       et_pbridge_con_detail TYPE tt_pbridge_con_detail.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_con_detail TYPE TABLE OF ty_pbridge_res_con_details,
      ls_con_detail TYPE ty_pbridge_res_con_details,
      ls_req_con_detail TYPE ty_pbridge_req_con,
      ls_pbridge_con_detail TYPE /psyng/api_conf_details,
      lv_http_status TYPE string.

*--Prepare API request data
  ls_req_con_detail-ruleset_id = g_plcvrs.

*--Prepare API url
  CONCATENATE g_endpoint 'BridgeRulesetSEConflictDetails' INTO l_url.

*--Initialize the client
  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

*--Handle the authentication popup
  PERFORM authentication_popup USING gf_testmode g_username g_password.

*--Add header field
  http_add_header_field: 'Content-Type' 'application/json'.

*--Set json body
  http_set_json_body ls_req_con_detail c_json_empty_skip.

*--Send request
  http_send_request l_url if_http_request=>co_request_method_post.

*--Get response
  http_get_response l_json_response lt_con_detail ''.

*--Get http status
  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    IF NOT lt_con_detail IS INITIAL.
      LOOP AT lt_con_detail INTO ls_con_detail.
        CLEAR ls_pbridge_con_detail.
        MOVE-CORRESPONDING ls_con_detail TO ls_pbridge_con_detail.
        APPEND ls_pbridge_con_detail TO et_pbridge_con_detail.
      ENDLOOP.
    ELSE.
      enmsg 'I' gt_messages 'Conflict details not available ' '& '
                                   'Status code is ' lv_http_status.
    ENDIF.
  ELSE.
    CLEAR: g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Conflict details not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_PBRIDGE_FUN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_PBRIDGE_FUN[]  text
*----------------------------------------------------------------------*
FORM read_pbridge_fun  CHANGING et_pbridge_fun TYPE tt_pbridge_fun.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_fun TYPE TABLE OF ty_res_pbridge_fun,
      ls_fun TYPE ty_res_pbridge_fun,
      ls_req_fun TYPE ty_req_pbridge_fun,
      ls_pbridge_fun TYPE /psyng/pbridge_fun,
      lv_http_status TYPE string.

  ls_req_fun-ruleset_id = g_plcvrs.

*  l_url = g_endpoint && 'BridgeRulesetSEFunctionHeaders'.
  CONCATENATE g_endpoint 'BridgeRulesetSEFunctionHeaders' INTO l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_fun c_json_empty_skip.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response lt_fun ''.

  PERFORM http_status CHANGING lv_http_status.

  IF NOT lt_fun IS INITIAL.
    LOOP AT lt_fun INTO ls_fun.
      CLEAR ls_pbridge_fun.
      MOVE-CORRESPONDING ls_fun TO ls_pbridge_fun.
      APPEND ls_pbridge_fun TO et_pbridge_fun.
    ENDLOOP.
*    enmsg 'S' gt_messages 'Functions pulled ' '& '
*                                 'Status code is ' lv_http_status.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Functions not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_PBRIDGE_FUN_DETAIL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_PBRIDGE_FUN_DETAIL[]  text
*----------------------------------------------------------------------*
FORM read_pbridge_fun_detail USING i_sysid
              CHANGING et_pbridge_fun_detail TYPE tt_pbridge_fun_detail.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_fun_detail TYPE TABLE OF ty_res_pbridge_fun_detail,
      ls_fun_detail TYPE ty_res_pbridge_fun_detail,
      ls_req_fun_detail TYPE ty_req_pbridge_fun_detail,
      ls_pbridge_fun_detail TYPE /psyng/pbridge_func_detail,
      lv_http_status TYPE string.

  ls_req_fun_detail-systemid = i_sysid.
  ls_req_fun_detail-ruleset_id = g_plcvrs.

*  l_url = g_endpoint && 'BridgeRulesetSEFunctionActivities'.
  CONCATENATE g_endpoint 'BridgeRulesetSEFunctionActivities' INTO
      l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_fun_detail c_json_empty_skip.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response lt_fun_detail ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    IF NOT lt_fun_detail IS INITIAL.
      LOOP AT lt_fun_detail INTO ls_fun_detail.
        CLEAR ls_pbridge_fun_detail.
        MOVE-CORRESPONDING ls_fun_detail TO ls_pbridge_fun_detail.
        APPEND ls_pbridge_fun_detail TO et_pbridge_fun_detail.
      ENDLOOP.
*      enmsg 'S' gt_messages 'Function details pulled ' '& '
*                                   'Status code is ' lv_http_status.
    ELSE.
 enmsg 'I' gt_messages 'Function details not found ' 'for ' 'system ID '
                                   i_sysid.
    ENDIF.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Function detail not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_PBRIDGE_FUN_OBJ
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_EF_SUCCESS  text
*      <--P_ET_PBRIDGE_FUN_OBJ[]  text
*----------------------------------------------------------------------*
FORM read_pbridge_fun_obj  USING i_sysid
  CHANGING et_pbridge_fun_obj TYPE tt_pbridge_fun_obj.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      lt_fun_obj TYPE TABLE OF ty_res_pbridge_fun_obj,
      ls_fun_obj TYPE ty_res_pbridge_fun_obj,
      ls_req_fun_obj TYPE ty_req_pbridge_fun_obj,
      ls_pbridge_fun_obj TYPE /psyng/sw_pbridge_fun_obj,
      lv_http_status TYPE string.

  ls_req_fun_obj-systemid = i_sysid.
  ls_req_fun_obj-ruleset_id = g_plcvrs.

*  l_url = g_endpoint && 'BridgeRulesetSEFunctionObjects'.
  CONCATENATE g_endpoint 'BridgeRulesetSEFunctionObjects' INTO
    l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_fun_obj c_json_empty_skip.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response lt_fun_obj ''.

  PERFORM http_status CHANGING lv_http_status.
  IF lv_http_status = '200'.
    IF NOT lt_fun_obj IS INITIAL.
      LOOP AT lt_fun_obj INTO ls_fun_obj.
        CLEAR ls_pbridge_fun_obj.
        MOVE-CORRESPONDING ls_fun_obj TO ls_pbridge_fun_obj.
        APPEND ls_pbridge_fun_obj TO et_pbridge_fun_obj.
      ENDLOOP.
*      enmsg 'S' gt_messages 'Function objects pulled ' '& '
*                                   'Status code is ' lv_http_status.
    ELSE.
 enmsg 'I' gt_messages 'Function objects not found ' 'for ' 'system ID '
                                   i_sysid.
    ENDIF.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Function objects not pulled ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_SCHEMA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_schema USING schema_b64 TYPE string
                         l_schema_count TYPE i.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      ls_res_schema TYPE ty_schema_res,
      ls_req_schema TYPE ty_schema_req,
      lv_http_status TYPE string,
      l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM create_request_data USING schema_b64
                              CHANGING ls_req_schema.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
   EXPORTING
     data        = ls_req_schema
     compress    = c_json_empty_skip "skip empty fields
     pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
   RECEIVING
     r_json      = lm_str.                   "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.
*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_schema ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages 'Schema successfully uploaded ' 'with'
                                 l_schema_count 'schemas'.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Schema not uploaded' ''
                                 '' ''.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_REQUEST_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_SCHEMA  text
*----------------------------------------------------------------------*
FORM create_request_data USING schema_b64 TYPE string
                         CHANGING ls_req_schema TYPE ty_schema_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_schema-api_key = 'key'.

  ls_fileupld-filename = 'Schemas.csv'.
  ls_fileupld-content  = schema_b64.
  APPEND ls_fileupld TO ls_req_schema-fileuploads.
  CLEAR ls_fileupld.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_ACTVT_GRP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_actvt_grp USING group_b64 TYPE string
                      l_group_count TYPE i.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      ls_res_actvt_grp TYPE ty_actvt_grp_res,
      ls_req_actvt_grp TYPE ty_actvt_grp_req,
      lv_http_status TYPE string,
      l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_actvtgrp_req_data USING group_b64
                                CHANGING ls_req_actvt_grp.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
      EXPORTING
        data        = ls_req_actvt_grp
        compress    = c_json_empty_skip "skip empty fields
        pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
      RECEIVING
        r_json      = lm_str.                "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.
*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_actvt_grp ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages 'Activity group successfully uploaded ' 'with'
                                 l_group_count 'groups'.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Activity group not uploaded ' '' '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_ACTVTGRP_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_ACTVT_GRP  text
*----------------------------------------------------------------------*
FORM crt_actvtgrp_req_data USING group_b64 TYPE string
                        CHANGING ls_req_actvt_grp TYPE ty_actvt_grp_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_actvt_grp-api_key = 'key'.

  ls_fileupld-filename = 'Groups.csv'.
  ls_fileupld-content  = group_b64.

  APPEND ls_fileupld TO ls_req_actvt_grp-fileuploads.
  CLEAR ls_fileupld.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_RULES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_rules USING rule_b64 TYPE string
                        lf_rules_ovrwrt TYPE flag
                        l_rule_count TYPE i.

  DATA:
      l_url TYPE string,
      l_json_response  TYPE string,
      ls_res_rules TYPE ty_rules_res,
      ls_req_rules TYPE ty_rules_req,
      lv_http_status TYPE string,
      l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_rules_req_data USING rule_b64
                                   lf_rules_ovrwrt
                             CHANGING ls_req_rules.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_rules
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES


  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str WITH
                                  'UseOverideMethod'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
*  REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str WITH
*                                                    'UseOverideMethod'.
  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_rules ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages 'Rules successfully uploaded ' 'with'
                                 l_rule_count 'rules'.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Rules not uploaded ' ''
                                 '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_RULES_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_RULES  text
*----------------------------------------------------------------------*
FORM crt_rules_req_data USING rule_b64 TYPE string
                              lf_rules_ovrwrt TYPE flag
                        CHANGING ls_req_rules TYPE ty_rules_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_rules-api_key = 'key'.

  ls_fileupld-filename = 'Rules.csv'.
  ls_fileupld-content  = rule_b64.
  APPEND ls_fileupld TO ls_req_rules-fileuploads.
  CLEAR ls_fileupld.

  IF lf_rules_ovrwrt = 'X'.
    ls_req_rules-useoveridemethod = abap_true.
  ELSE.
    ls_req_rules-useoveridemethod = abap_false.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_ACTVT_MOD_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_actvt_mod_values USING actmodval_b64 TYPE string
                                   l_mode_count TYPE i.
  DATA:
        l_url TYPE string,
        l_json_response  TYPE string,
        ls_res_actvt_mod_val TYPE ty_actvt_mod_val_res,
        ls_req_actvt_mod_val TYPE ty_actvt_mod_val_req,
        lv_http_status TYPE string,
        l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_actvt_mod_val_req_data USING actmodval_b64
                                     CHANGING ls_req_actvt_mod_val.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_actvt_mod_val
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES


  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_actvt_mod_val ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages
    'Activity mode values successfully uploaded ' 'with'
                                 l_mode_count 'modes' .
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Activity mode values not uploaded ' '' '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_ACTVT_MOD_VAL_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_ACTVT_MOD_VAL  text
*----------------------------------------------------------------------*
FORM crt_actvt_mod_val_req_data USING actmodval_b64 TYPE string
                             CHANGING ls_req_actvt_mod_val TYPE
                                          ty_actvt_mod_val_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_actvt_mod_val-api_key = 'key'.

  ls_fileupld-filename = 'Activity Mode Values.csv'.
  ls_fileupld-content  = actmodval_b64.
  APPEND ls_fileupld TO ls_req_actvt_mod_val-fileuploads.
  CLEAR ls_fileupld.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_ACTVT_MOD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_actvt_mod USING actvtmod_b64 TYPE string
                            if_actvtmod_ovrwrt TYPE flag
                            i_system TYPE /psyng/bridge_system.

  DATA:
        l_url TYPE string,
        l_json_response  TYPE string,
        ls_res_actvt_mod TYPE  ty_sd_actvt_mod_res,
        ls_req_actvt_mod TYPE  ty_sd_actvt_mod_req,
        lv_http_status TYPE string,
        l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_actvt_mod_req_data USING actvtmod_b64
                                       if_actvtmod_ovrwrt
                                       i_system
                                 CHANGING ls_req_actvt_mod.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_actvt_mod
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'systemname' IN lm_str
      WITH 'systemName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str WITH
                                  'UseOverideMethod'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.




*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
*  REPLACE ALL OCCURRENCES OF 'systemname' IN lm_str WITH 'systemName'.
*  REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str
*                                                WITH 'UseOverideMethod'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_actvt_mod ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages
    'Activity mode successfully uploaded' '' '' ''.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Activity mode not uploaded' '' '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_ACTVT_MOD_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_ACTVT_MOD  text
*----------------------------------------------------------------------*
FORM crt_actvt_mod_req_data USING actvtmod_b64 TYPE string
                                lf_actvtmod_ovrwrt TYPE flag
                                i_system TYPE /psyng/bridge_system
                    CHANGING ls_req_actvt_mod TYPE  ty_sd_actvt_mod_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_actvt_mod-api_key = 'key'.
  ls_req_actvt_mod-systemname = i_system.

  ls_fileupld-filename = 'Activity Mode.csv'.
  ls_fileupld-content  = actvtmod_b64.
  APPEND ls_fileupld TO ls_req_actvt_mod-fileuploads.
  CLEAR ls_fileupld.

  IF lf_actvtmod_ovrwrt = 'X'.
    ls_req_actvt_mod-useoveridemethod = 'true'.
  ELSE.
    ls_req_actvt_mod-useoveridemethod = 'false'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_GRP_CMP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM upload_grp_cmp USING grpcmp_b64 TYPE string
                          if_grpcmp_ovrwrt TYPE flag
                          i_system TYPE /psyng/bridge_system.

  DATA:
        l_url TYPE string,
        l_json_response  TYPE string,
        ls_res_grp_cmp TYPE  ty_sd_grp_cmp_res,
        ls_req_grp_cmp TYPE  ty_sd_grp_cmp_req,
        lv_http_status TYPE string,
        l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_grp_cmp_req_data USING grpcmp_b64
                                     if_grpcmp_ovrwrt
                                     i_system
                               CHANGING ls_req_grp_cmp.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_grp_cmp
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'systemname' IN lm_str
      WITH 'systemName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str WITH
                                  'UseOverideMethod'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.



*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
*  REPLACE ALL OCCURRENCES OF 'systemname' IN lm_str WITH 'systemName'.
*  REPLACE ALL OCCURRENCES OF 'useoveridemethod' IN lm_str
*                                                WITH 'UseOverideMethod'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_grp_cmp ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages
    'Group components successfully uploaded ' ''
                                 '' ''.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Group components not uploaded ' ''
                                 '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_GRP_CMP_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_REQ_GRP_CMP  text
*----------------------------------------------------------------------*
FORM crt_grp_cmp_req_data  USING grpcmp_b64 TYPE string
                                 lf_grpcmp_ovrwrt TYPE flag
                                 i_system TYPE /psyng/bridge_system
                       CHANGING ls_req_grp_cmp TYPE ty_sd_grp_cmp_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_grp_cmp-api_key = 'key'.
  ls_req_grp_cmp-systemname = i_system.

  ls_fileupld-filename = 'Groups Components.csv'.
  ls_fileupld-content  = grpcmp_b64.
  APPEND ls_fileupld TO ls_req_grp_cmp-fileuploads.
  CLEAR ls_fileupld.

  IF lf_grpcmp_ovrwrt = 'X'.
    ls_req_grp_cmp-useoveridemethod = 'true'.
  ELSE.
    ls_req_grp_cmp-useoveridemethod = 'false'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DECRYPT_PASSWORD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_CFG_VALUE  text
*      <--P_L_PASS  text
*----------------------------------------------------------------------*
FORM decrypt_password USING    im_encrypted_password
                      CHANGING ch_decrypted_password.
* We use a simple 'Vigenere-Chiffre' (but with a long key) and
* add a accumulated index to it.
* By now the encrypted and the decrypted password have the same
* length (32)

  DATA:
    l_index            TYPE i,
    l_number           TYPE i,
    l_key_val          TYPE i,
    l_passwd_val       TYPE i,
    l_accumulate       TYPE i.

  CLEAR ch_decrypted_password.

  l_index      = 0.
  l_accumulate = 0.
* encrypt the maximal length of the decrypted password, not just the
* filled part of the decrypted password
  DO co_password_length TIMES.                  "#EC PATHLOCK_CI_NO_DOS
*   check out the index in the key
    PERFORM character_search
        USING
           co_password_characters
           co_key+l_index(1)
        CHANGING
           l_key_val.
*   check out the index in the encrypted password
    PERFORM character_search
        USING
           co_password_characters
           im_encrypted_password+l_index(1)
        CHANGING
           l_passwd_val.
*   calculate the index of the character for the encrypted password
    l_number = ( l_passwd_val - l_accumulate - l_key_val ) MOD
            co_number_of_characters.
    ch_decrypted_password+l_index(1) =
            co_password_characters+l_number(1).
    l_index = l_index + 1.
*   Accumulate the index of the characters in the decrypted password
    l_accumulate = l_accumulate + l_number.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHARACTER_SEARCH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CO_PASSWORD_CHARACTERS  text
*      -->P_CO_KEY+L_INDEX(1)  text
*      <--P_L_KEY_VAL  text
*----------------------------------------------------------------------*
FORM character_search  USING   im_string
                               im_character
                      CHANGING ch_pos             TYPE i.

  DATA:
    l_index            TYPE i,
    l_length           TYPE i.

*  DESCRIBE FIELD im_string LENGTH l_length.
  l_length = strlen( im_string ).

  ch_pos     = -1.
  l_index    =  0.
  DO l_length TIMES.                            "#EC PATHLOCK_CI_NO_DOS
    IF im_string+l_index(1) = im_character.
      ch_pos = l_index.
      EXIT.
    ENDIF.
    l_index = l_index + 1.
  ENDDO.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_MIT_HEADERS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_mit_headers USING i_use_push
      CHANGING et_mit_cont_head TYPE /psyng/sw_mit_cont_head_plc_tt.

  DATA:
    l_url TYPE string,
    l_json_response  TYPE string,
    ls_req_body TYPE ty_req_body_sysdep, "Request body
    lv_http_status TYPE string.

  CONCATENATE g_endpoint 'BridgeSEControlHeaders' INTO
   l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_body c_json_empty_skip.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response et_mit_cont_head ''.

  PERFORM http_status CHANGING lv_http_status.

  IF i_use_push IS INITIAL.
    IF lv_http_status = '200'.
      enmsg 'S'
      gt_messages 'Mitigation control headers pulled successfully ' ''
                                   '' ''.
    ELSE.
      enmsg 'E'
  gt_messages 'Mitigation control headers not pulled successfully ' ''
                               '' ''.
    ENDIF.

  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PUSH_MITIGATION_DEFINITIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_CONTROL_HEADERS  text
*----------------------------------------------------------------------*
FORM push_mitigation_definitions TABLES et_messages STRUCTURE bapiret2
                               et_mchdr STRUCTURE /psyng/mchdr
                                                USING i_control_headers.

  DATA: lt_mcdef TYPE TABLE OF ty_mcdef,
        ls_mcdef TYPE ty_mcdef,
        ls_mchdr TYPE /psyng/mchdr,
        lt_mcdef_csv TYPE TABLE OF ty_csv,
        mcdef_b64 TYPE string.

*  Fetch mitigation data from SE
  PERFORM get_mcdef USING i_control_headers CHANGING lt_mcdef.

*  Convert mitigation control data into csv file
  PERFORM mcdef_csv USING lt_mcdef CHANGING lt_mcdef_csv.

*  Convert csv file to base64
  PERFORM csv_to_b64 USING lt_mcdef_csv
                     CHANGING mcdef_b64.

*  Call upload api
  CALL FUNCTION '/PSYNG/SW_WRT_RULE_PBRIDGE_SI'
   EXPORTING
     if_mit_cont_header        = i_control_headers
     i_mcdef_b64               = mcdef_b64
    TABLES
      et_messages               = et_messages.

*  See details after pushing configuration
  LOOP AT lt_mcdef INTO ls_mcdef.
    ls_mchdr-contid  = ls_mcdef-title.
    ls_mchdr-description  = ls_mcdef-short_des.
    APPEND ls_mchdr TO et_mchdr.
    CLEAR ls_mchdr.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_MCDEF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_CONTROL_HEADERS  text
*      <--P_LT_MCDEF  text
*----------------------------------------------------------------------*
FORM get_mcdef  USING    i_control_headers
                CHANGING lt_mcdef TYPE tt_mcdef.

  TYPES: plc_cont_range_typ
             TYPE RANGE OF /psyng/sw_mit_cont_header_plc-control,

         BEGIN OF ty_text ,
         textname LIKE /psyng/sw_mit_cont_header_plc-control,
        text LIKE agr_texts-text,
        END OF ty_text.

  DATA: lt_mc_head_plc TYPE /psyng/sw_mit_cont_head_plc_tt,
        ls_mc_head_plc TYPE /psyng/sw_mit_cont_header_plc,
        lt_logs TYPE TABLE OF bapiret2,
        lt_plc_cont_range TYPE plc_cont_range_typ,
        ls_plc_cont_range TYPE LINE OF plc_cont_range_typ,
        lt_se_mchdr TYPE TABLE OF /psyng/mchdr,
        ls_se_mchdr TYPE /psyng/mchdr,
        ls_mcdef TYPE ty_mcdef,
        lt_text TYPE TABLE OF ty_text.

  FIELD-SYMBOLS <fs_text> LIKE LINE OF lt_text.

*  Read existing mitigation controls from PLC
  CALL FUNCTION '/PSYNG/SW_PULL_MIT_CONT_PLC'
   EXPORTING
     i_control_headers          = i_control_headers
     i_use_push                 = 'X'
   IMPORTING
     et_mit_cont_head_plc       = lt_mc_head_plc
   TABLES
     et_messages                = lt_logs.

*  Create range of controls fetched from PLC and use it to fetch delta
*  controls from SE
  REFRESH lt_plc_cont_range.
  LOOP AT lt_mc_head_plc INTO ls_mc_head_plc.
    ls_plc_cont_range-sign = 'I'.
    ls_plc_cont_range-option = 'EQ'.
    ls_plc_cont_range-low = ls_mc_head_plc-control.
    APPEND ls_plc_cont_range TO lt_plc_cont_range.
    CLEAR ls_plc_cont_range-low.
  ENDLOOP.

*  Get mitigation controls from SE which do not exist on PLC
  SELECT * FROM /psyng/mchdr                            "#EC CI_NOWHERE
      INTO TABLE lt_se_mchdr
    WHERE contid NOT IN lt_plc_cont_range.

*  Create range of delta controls and use to fetch long description
  REFRESH lt_plc_cont_range.
  LOOP AT lt_se_mchdr INTO ls_se_mchdr.
    ls_plc_cont_range-sign = 'I'.
    ls_plc_cont_range-option = 'EQ'.
    ls_plc_cont_range-low = ls_se_mchdr-contid.
    APPEND ls_plc_cont_range TO lt_plc_cont_range.
    CLEAR ls_plc_cont_range-low.
  ENDLOOP.

*  Long text
  SELECT  textname line text INTO CORRESPONDING FIELDS OF TABLE lt_text
          FROM /psyng/texts
          WHERE textname IN lt_plc_cont_range
           AND   object   = 'M'
           AND   spras    = sy-langu
           ORDER BY line.

  LOOP AT lt_se_mchdr INTO ls_se_mchdr.
    ls_mcdef-title = ls_se_mchdr-contid.
    ls_mcdef-short_des = ls_se_mchdr-description.
*    ls_mcdef-auto_lev = 'Documentation Only'.

    IF ls_se_mchdr-type EQ 'SOD'.
      CONCATENATE 'Mitigation Type:' 'High.' INTO ls_mcdef-long_des
      SEPARATED BY space.
    ELSEIF ls_se_mchdr-type EQ 'MAN'.
      CONCATENATE 'Mitigation Type:' 'Manual Mitigation.'
      INTO ls_mcdef-long_des SEPARATED BY space.
    ELSEIF ls_se_mchdr-type EQ 'SEMI'.
      CONCATENATE 'Mitigation Type:' 'Semi Automated.'
      INTO ls_mcdef-long_des SEPARATED BY space.
    ELSE.
      CONCATENATE 'Mitigation Type:' 'Not Defined.'
            INTO ls_mcdef-long_des SEPARATED BY space.
    ENDIF.

    DO.
      READ TABLE lt_text ASSIGNING <fs_text>
                                WITH KEY textname = ls_se_mchdr-contid.
      IF sy-subrc = 0.
        IF ls_mcdef-long_des IS INITIAL.
          ls_mcdef-long_des = <fs_text>-text.
        ELSE.
          CONCATENATE ls_mcdef-long_des <fs_text>-text
          INTO ls_mcdef-long_des SEPARATED BY space.
        ENDIF.
        CLEAR <fs_text>.
      ELSE.
        EXIT.
      ENDIF.
    ENDDO.

    APPEND ls_mcdef TO lt_mcdef.
    CLEAR ls_mcdef.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  MCDEF_CSV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_MCDEF  text
*      <--P_LT_MCDEF_CSV  text
*----------------------------------------------------------------------*
FORM mcdef_csv  USING    lt_mcdef TYPE tt_mcdef
                CHANGING lt_mcdef_csv TYPE tt_csv.

  DATA:
          ls_mcdef_csv TYPE ty_csv,
          ls_mcdef TYPE ty_mcdef.

* Column headings
  CONCATENATE 'Title'(001)
              'Short Description'(002)
              'Long Description'(003)
              'Procedure'(004)
              'Automation Level'(005)
              'Report to send automatically'(006)
              'Control Time Scope'(007)
              'Performer'(008)
              'Owner'(009)
              'Email Message Template'(010)
              'Business Process Workflow Type'(011)
              'Report Split By Column'(012)
              INTO ls_mcdef_csv-line
              SEPARATED BY ';'.
  APPEND ls_mcdef_csv TO lt_mcdef_csv.
  CLEAR ls_mcdef_csv.

  LOOP AT lt_mcdef INTO ls_mcdef.
    CONCATENATE ls_mcdef-title
           ls_mcdef-short_des
          ls_mcdef-long_des
          ls_mcdef-procedure
          ls_mcdef-auto_lev
          ls_mcdef-rpt_send_auto
          ls_mcdef-ctl_time_scope
          ls_mcdef-performer
          ls_mcdef-owner
          ls_mcdef-email_msg_temp
          ls_mcdef-bpw
          ls_mcdef-rsc
          INTO ls_mcdef_csv-line
          SEPARATED BY ';'.
    APPEND ls_mcdef_csv TO lt_mcdef_csv.
    CLEAR ls_mcdef_csv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CSV_TO_B64
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_MCDEF_CSV  text
*      <--P_MCDEF_B64  text
*----------------------------------------------------------------------*
FORM csv_to_b64  USING    lt_csv TYPE tt_csv
                 CHANGING base64 TYPE string.

  DATA:
          lv_str_x TYPE xstring.

  CALL FUNCTION 'SCMS_TEXT_TO_XSTRING'
  IMPORTING
    buffer   = lv_str_x
  TABLES
    text_tab = lt_csv
"(++)BOC AKUMAR SE VF scan-19/12/2024
  EXCEPTIONS
    failed = 1
    OTHERS = 2.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  "(++)EOC AKUMAR SE VF scan-19/12/2024.

  IF lv_str_x IS NOT INITIAL.
    CALL FUNCTION 'SCMS_BASE64_ENCODE_STR'
      EXPORTING
        input         = lv_str_x
     IMPORTING
       output        = base64.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_MIT_DEF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_MCDEF_B64  text
*----------------------------------------------------------------------*
FORM upload_mit_def  USING  mcdef_b64 TYPE string.

  DATA:
          l_url TYPE string,
          l_json_response  TYPE string,
          ls_res_mcdef TYPE ty_actvt_mod_val_res, "same type
          ls_req_mcdef TYPE ty_actvt_mod_val_req, "same type
          lv_http_status TYPE string,
          l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_mcdef_req_data USING mcdef_b64
                                     CHANGING ls_req_mcdef.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_mcdef
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.


*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_mcdef ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages
    'Mitigation definitions successfully uploaded ' '& '
                                 'Status code is ' lv_http_status.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Mitigation definitions not uploaded ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_MCDEF_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MCDEF_B64  text
*      <--P_LS_REQ_MCDEF  text
*----------------------------------------------------------------------*
FORM crt_mcdef_req_data  USING    mcdef_b64 TYPE string
                         CHANGING ls_req_mcdef TYPE
                                          ty_actvt_mod_val_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_mcdef-api_key = 'key'.

  ls_fileupld-filename = 'Process Controls.csv'.
  ls_fileupld-content  = mcdef_b64.
  APPEND ls_fileupld TO ls_req_mcdef-fileuploads.
  CLEAR ls_fileupld.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PUSH_MIT_ASSIGNMENTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_MESSAGES  text
*      -->P_I_CONTROL_ASSIGN  text
*----------------------------------------------------------------------*
FORM push_mit_assignments  TABLES   et_messages STRUCTURE bapiret2
                                et_mcuser STRUCTURE /psyng/da_sw_mcuser
                           USING    i_control_assign
                                    i_vrsio.

  DATA : lt_mchdr  TYPE TABLE OF /psyng/da_mchdr,
         lt_mcuser TYPE TABLE OF /psyng/da_sw_mcuser,
         ls_mcuser TYPE /psyng/da_sw_mcuser,
         lt_mcassign TYPE TABLE OF ty_mcassign,
         ls_mcassign TYPE ty_mcassign,
         lt_mcassign_csv TYPE TABLE OF ty_csv,
          mcassign_b64 TYPE string.

*  Fetch mitigation user assignments from SE for particular version
  PERFORM get_mcassign USING i_vrsio CHANGING lt_mcassign.

*  Convert mitigation assignment data into csv file
  PERFORM mcassign_csv USING lt_mcassign CHANGING lt_mcassign_csv.

*  Convert csv file to base64
  PERFORM csv_to_b64 USING lt_mcassign_csv
                     CHANGING mcassign_b64.

*  Call upload api
  CALL FUNCTION '/PSYNG/SW_WRT_RULE_PBRIDGE_SI'
   EXPORTING
     if_mit_assign             = i_control_assign
     i_mcassign_b64            = mcassign_b64
    TABLES
      et_messages               = et_messages.

*  See details after pushing configuration
  LOOP AT lt_mcassign INTO ls_mcassign.
    ls_mcuser-userid = ls_mcassign-empid.
    ls_mcuser-conid = ls_mcassign-comb_name.


    DO.
     REPLACE ALL OCCURRENCES OF '-' IN ls_mcassign-date_from WITH space.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
    ls_mcuser-from_date = ls_mcassign-date_from.

    DO.
      REPLACE ALL OCCURRENCES OF '-' IN ls_mcassign-date_to WITH space.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
    ls_mcuser-to_date = ls_mcassign-date_to.


*    REPLACE ALL OCCURRENCES OF '-' IN ls_mcassign-date_from WITH space.
*    ls_mcuser-from_date = ls_mcassign-date_from.
*
*    REPLACE ALL OCCURRENCES OF '-' IN ls_mcassign-date_to WITH space.
*    ls_mcuser-to_date = ls_mcassign-date_to.
    APPEND ls_mcuser TO et_mcuser.
    CLEAR ls_mcuser.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_MCASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_MCASSIGN  text
*----------------------------------------------------------------------*
FORM get_mcassign USING i_vrsio CHANGING lt_mcassign TYPE tt_mcassign.

  DATA : lt_mchdr  TYPE TABLE OF /psyng/da_mchdr,
         lt_mcuser TYPE TABLE OF /psyng/da_sw_mcuser,
         ls_mcuser TYPE /psyng/da_sw_mcuser,
         ls_mchdr  TYPE /psyng/da_mchdr,
         ls_mcassign TYPE ty_mcassign,
         lt_mc_assign TYPE /psyng/sw_mit_emp_vlation_tt,
         ls_mc_assign TYPE /psyng/sw_mit_emp_vlation_plc,
         l_date TYPE char8,
         l_n_date TYPE char10,
         l_yr TYPE char4,
         l_mnth TYPE char2,
         l_day TYPE char2,
         l_hyphen TYPE c VALUE '-'.


  CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'
   EXPORTING
     i_vrsio         = i_vrsio
   TABLES
     mcuser          = lt_mcuser
     mchdr           = lt_mchdr.

*  Get mitigation controls from PLC
  CALL FUNCTION '/PSYNG/SW_PULL_MIT_CONT_PLC'
   EXPORTING
     i_control_assign           = 'X'
     i_use_push                 = 'X'
   IMPORTING
     et_mit_cont_assign         = lt_mc_assign.

  LOOP AT lt_mcuser INTO ls_mcuser.

    READ TABLE lt_mc_assign INTO ls_mc_assign
                            WITH KEY employeeid = ls_mcuser-userid
                                         risk = ls_mcuser-conid.
* Only push mitigation which does not exist on PLC
    IF sy-subrc NE 0.
* OR
*       ls_mc_assign-iscanceled EQ 'X' OR
*       ls_mc_assign-isexpired EQ 'X'.

      ls_mcassign-aprvr = ls_mcuser-auditor.

      ls_mcassign-empid = ls_mcuser-userid.
      ls_mcassign-comb_name = ls_mcuser-conid.

      CLEAR l_n_date.
      l_date = ls_mcuser-from_date.
      l_yr = l_date(4).
      l_mnth = l_date+4(2).
      l_day = l_date+6(2).
      CONCATENATE l_yr l_mnth l_day INTO l_n_date SEPARATED BY l_hyphen.
      ls_mcassign-date_from = l_n_date.

      CLEAR l_n_date.
      l_date = ls_mcuser-to_date.
      l_yr = l_date(4).
      l_mnth = l_date+4(2).
      l_day = l_date+6(2).
      CONCATENATE l_yr l_mnth l_day INTO l_n_date SEPARATED BY l_hyphen.
      ls_mcassign-date_to = l_n_date.

      ls_mcassign-aprvr_res = ls_mcuser-contid.

      APPEND ls_mcassign TO lt_mcassign.
      CLEAR ls_mcassign.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  MCASSIGN_CSV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_MCASSIGN  text
*      <--P_LT_MCASSIGN_CSV  text
*----------------------------------------------------------------------*
FORM mcassign_csv  USING    lt_mcassign TYPE tt_mcassign
                   CHANGING lt_mcassign_csv TYPE tt_csv.

  DATA:
           ls_mcassign_csv TYPE ty_csv,
           ls_mcassign TYPE ty_mcassign.

* Column headings
  CONCATENATE 'Employee Id'
              'Combination Name'
              'Approved By'
              'Approve Reason'
              'Approved From'
              'Approved Until'
              INTO ls_mcassign_csv-line
              SEPARATED BY ';'.
  APPEND ls_mcassign_csv TO lt_mcassign_csv.
  CLEAR ls_mcassign_csv.

  LOOP AT lt_mcassign INTO ls_mcassign.
    CONCATENATE ls_mcassign-empid
           ls_mcassign-comb_name
          ls_mcassign-aprvr
          ls_mcassign-aprvr_res
          ls_mcassign-date_from
          ls_mcassign-date_to
          INTO ls_mcassign_csv-line
          SEPARATED BY ';'.
    APPEND ls_mcassign_csv TO lt_mcassign_csv.
    CLEAR ls_mcassign_csv.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPLOAD_MIT_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_MCASSIGN_B64  text
*----------------------------------------------------------------------*
FORM upload_mit_assign  USING mcassign_b64 TYPE string.

  DATA:
            l_url TYPE string,
            l_json_response  TYPE string,
            ls_res_mcassign TYPE ty_actvt_mod_val_res, "same type
            ls_req_mcassign TYPE ty_actvt_mod_val_req, "same type
            lv_http_status TYPE string,
            l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.

  PERFORM crt_mcassign_req_data USING mcassign_b64
                                     CHANGING ls_req_mcassign.

  l_url = '/app/Portal/BridgeUploadRuleset/api.ashx'.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

*  CALL METHOD /ui2/cl_json=>serialize
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data        = ls_req_mcassign
      compress    = c_json_empty_skip "skip empty fields
      pretty_name = 'L'"/ui2/cl_json=>pretty_mode-low_case
    RECEIVING
      r_json      = lm_str.                  "#EC PATHLOCK_CI_DYN_ACCES

  DO.
  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.

  DO.
    REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.
    IF sy-subrc NE 0. EXIT. ENDIF.
  ENDDO.


*  REPLACE ALL OCCURRENCES OF 'fileuploads' IN lm_str WITH 'fileUploads'.
*  REPLACE ALL OCCURRENCES OF 'filename' IN lm_str WITH 'fileName'.

  go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
  debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response ls_res_mcassign ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lv_http_status = '200'.
    enmsg 'S' gt_messages
    'Mitigation assignments successfully uploaded ' '& '
                                 'Status code is ' lv_http_status.
  ELSE.
    CLEAR g_total_rows.
    DESCRIBE TABLE gt_messages LINES g_total_rows.
    IF g_total_rows <> 0.
      DELETE gt_messages INDEX g_total_rows.
    ENDIF.
    enmsg 'E' gt_messages 'Mitigation assignments not uploaded ' '& '
                                 'Status code is ' lv_http_status.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CRT_MCASSIGN_REQ_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MCASSIGN_B64  text
*      <--P_LS_REQ_MCASSIGN  text
*----------------------------------------------------------------------*
FORM crt_mcassign_req_data  USING    mcassign_b64 TYPE string
                            CHANGING ls_req_mcassign TYPE
                                          ty_actvt_mod_val_req.

  DATA: ls_fileupld TYPE ty_fileupld.

  ls_req_mcassign-api_key = 'key'.

  ls_fileupld-filename = 'Mitigate Violations - Employees.csv'.
  ls_fileupld-content  = mcassign_b64.
  APPEND ls_fileupld TO ls_req_mcassign-fileuploads.
  CLEAR ls_fileupld.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_MIT_ASSIGN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_ET_MIT_CONT_ASSIGN  text
*----------------------------------------------------------------------*
FORM get_mit_assign USING i_use_push CHANGING
                   et_mit_cont_assign TYPE /psyng/sw_mit_emp_vlation_tt.

  DATA:
    l_url TYPE string,
    l_json_response  TYPE string,
    ls_req_body TYPE ty_pbridge_req_con,
    lv_http_status TYPE string.

  CONCATENATE g_endpoint 'BridgeSEMitigatedEmployeeViolations'
                                                           INTO l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_body c_json_empty_skip.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response et_mit_cont_assign ''.

  PERFORM http_status CHANGING lv_http_status.

  IF i_use_push IS INITIAL.
    IF lv_http_status = '200'.
      enmsg 'S'
      gt_messages
      'Mitigation control assignments pulled successfully ' '' '' ''.
    ELSE.
      enmsg 'E'
  gt_messages
          'Mitigation control assignments not pulled successfully ' ''
                             '' ''.
    ENDIF.
  ENDIF.
ENDFORM.
