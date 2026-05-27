FUNCTION /psyng/sw_incompatible_objects.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SYSID) TYPE  /PSYNG/API_SYSID
*"  TABLES
*"      ET_INCOM_OBJ STRUCTURE  /PSYNG/INCO_OBJECT
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"  EXCEPTIONS
*"      NO_DATA_FOUND
*"----------------------------------------------------------------------
  DATA: lt_messages_con TYPE TABLE OF bapiret2,
          lt_messages_fun TYPE TABLE OF bapiret2,
          lf_success_con TYPE flag,
          lf_success_fun TYPE flag,
          lt_b_con TYPE TABLE OF /psyng/api_conf,
          lt_b_con_txt TYPE TABLE OF /psyng/api_conf_txt,
          lt_b_con_det TYPE TABLE OF /psyng/api_conf_details,
          lt_b_fun  TYPE TABLE OF /psyng/pbridge_fun,
          lt_b_fun_det TYPE TABLE OF /psyng/pbridge_func_detail,
          lt_b_fun_obj TYPE TABLE OF /psyng/pbridge_fun_obj,
          l_len TYPE i,
          ls_incom_obj TYPE /psyng/inco_object.

  DATA:
        l_url TYPE string,
        l_json_response  TYPE string,
        lt_res_incmp_obj TYPE TABLE OF ty_res_pbridge_incmp_obj,
        ls_res_incmp_obj TYPE ty_res_pbridge_incmp_obj,
        ls_req_incmp_obj TYPE ty_req_pbridge_incmp_obj,
        lv_http_status TYPE string.

*Read incompatible objects from pathlock bridge
  PERFORM get_connector_param CHANGING g_host g_port g_scheme
                                       g_username g_password.

  ls_req_incmp_obj-pageoffset = 0.
  ls_req_incmp_obj-pagesize = 10.
  ls_req_incmp_obj-systemid = i_sysid.

*  l_url = g_endpoint && 'BridgeRulesetSEIncompatibleObjects'.
  CONCATENATE g_endpoint 'BridgeRulesetSEIncompatibleObjects' INTO
    l_url.

  CLEAR go_http_client.
  http_init_client.                              "#EC SAST_CI_GEN_CHECK

  PERFORM authentication_popup USING gf_testmode g_username g_password.

  http_add_header_field: 'Content-Type' 'application/json'.

  http_set_json_body ls_req_incmp_obj c_json_empty_include.

  http_send_request l_url if_http_request=>co_request_method_post.

  http_get_response l_json_response lt_res_incmp_obj ''.

  PERFORM http_status CHANGING lv_http_status.

  IF lt_res_incmp_obj IS NOT INITIAL.
    LOOP AT lt_res_incmp_obj INTO ls_res_incmp_obj.
      ls_incom_obj-row_count = sy-tabix.
      ls_incom_obj-issuelocation = ls_res_incmp_obj-issuelocation.
      ls_incom_obj-issue = ls_res_incmp_obj-issue.
      APPEND ls_incom_obj TO et_incom_obj.
    ENDLOOP.
  ELSE.
    RAISE no_data_found.
  ENDIF.

*  IF lv_http_status = '200' AND lt_res_incmp_obj IS NOT INITIAL.
**---read bridge matrix
*    CALL FUNCTION '/PSYNG/SW_READ_API_CONF'
*          EXPORTING
*            if_pbridge_con              = 'X'
*            if_pbridge_con_txt          = 'X'
*            if_pbridge_con_detail       = 'X'
*         IMPORTING
*           ef_success                   =  lf_success_con
*          TABLES
*            et_messages                 = lt_messages_con
*            et_pbridge_con              = lt_b_con
*            et_pbridge_con_txt          = lt_b_con_txt
*            et_pbridge_con_detail       = lt_b_con_det.
*    et_return[] = lt_messages_con[].
*
*    CALL FUNCTION '/PSYNG/SW_READ_API_FUNC'
*         EXPORTING
*           if_pbridge_fun              = 'X'
*           if_pbridge_fun_obj          = 'X'
*           if_pbridge_fun_detail       = 'X'
*           i_sysid                     = i_sysid
*        IMPORTING
*          ef_success                  =  lf_success_fun
*         TABLES
*           et_messages                 = lt_messages_fun
*           et_pbridge_fun              = lt_b_fun
*           et_pbridge_fun_detail       = lt_b_fun_det
*           et_pbridge_fun_obj          = lt_b_fun_obj.
*    et_return[] = lt_messages_fun[].
*
**----validate matrix from SE
** conflict
*data ls_b_con like line of lt_b_con.
*    LOOP AT lt_b_con INTO ls_b_con.
*
*      concate_string:
*
*    ls_b_con-conid 12 'ConID:' ls_b_con-conid 'Conflict length is >
*12',
*   ls_b_con-imp 8 'Sensitivity:' ls_b_con-imp 'App area length is > 8',
*   ls_b_con-busarea 4 'App area:' ls_b_con-busarea
*   'Conflict length is > 4'.
*    ENDLOOP.
*
**  function details
*data ls_b_con_det like line of lt_b_con_det.
*    LOOP AT lt_b_con_det INTO ls_b_con_det.
*      concate_string:
*       ls_b_con_det-conid 12 'ConID:' ls_b_con_det-conid
*      'Conflict ID length is > 12',
*       ls_b_con_det-functionid 12 'Function:' ls_b_con_det-functionid
*      'Function ID length is > 12'.
*    ENDLOOP.
*
**-- function
*data ls_b_fun like line of lt_b_fun.
*    LOOP AT lt_b_fun INTO ls_b_fun.
*      concate_string:
*    ls_b_fun-function 12 'Function:' ls_b_fun-function
*    'Function length is > 12'.
*    ENDLOOP.
*
** function detail
*data ls_b_fun_det like line of lt_b_fun_det.
*    LOOP AT  lt_b_fun_det INTO ls_b_fun_det.
*      concate_string:
*      ls_b_fun_det-functionid 12 'Function:' ls_b_fun_det-functionid
*      'Function length is > 12',
*      ls_b_fun_det-tcode 12 'Tcode:' ls_b_fun_det-tcode
*      'Tcode length is > 20'.
*    ENDLOOP.
*  ELSE.
*  ENDIF.


ENDFUNCTION.
