*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_HTTP_TOOLS
*&---------------------------------------------------------------------*
*--Constants
CONSTANTS:
  c_json_empty_skip    TYPE flag VALUE 'X',
  c_json_empty_include TYPE flag VALUE ' '.
*--Global Data
DATA : gf_testmode    TYPE flag,
       go_http_client TYPE REF TO if_http_client,
       gt_messages    TYPE TABLE OF bapiret2 WITH HEADER LINE,
       g_debug_flag   TYPE flag,
       g_timeout_seconds TYPE i VALUE -1.
*--Data to be used in http macros only
DATA :
  lm_entity       TYPE REF TO if_http_entity,
  lm_xresponse    TYPE xstring,
  lm_response     TYPE REF TO if_http_response,
  lmo_conv        TYPE REF TO cl_abap_conv_in_ce,
  lm_str          TYPE string.
DEFINE get_con_attribute.
  clear &2.
  clear lm_f_atr_found.
  read table IT_CON_ATTR with key name = &1.
  if sy-subrc = 0.
    &2 = IT_CON_ATTR-value.
    lm_f_atr_found = 'X'.
  else.
*--Check if the attribute exist split over multiple records _1, _2 ...)
   lm_idx = 1.
*   lm_attr_name = &1 && '_' && lm_idx.
   CONCATENATE &1 '_' lm_idx into lm_attr_name.
   read table IT_CON_ATTR with key name = lm_attr_name.
   if sy-subrc = 0.
     lm_f_atr_found = 'X'.
     lm_attr_val_prt = IT_CON_ATTR-value.
   else.
     clear lm_attr_val_prt.
   endif.
   while not lm_attr_val_prt is initial.
*     &2 = &2 && lm_attr_val_prt.
     CONCATENATE &2 lm_attr_val_prt into &2.
     add 1 to lm_idx.
*     lm_attr_name = &1 && '_' && lm_idx.
     CONCATENATE &1 '_' lm_idx into lm_attr_name.
     read table IT_CON_ATTR with key name = lm_attr_name.
     if sy-subrc = 0.
       lm_attr_val_prt = IT_CON_ATTR-value.
     else.
         clear lm_attr_val_prt.
     endif.
   endwhile.
  endif.
*--If parameter not defined, and there is a default, set it
  if lm_f_atr_found is initial and &3 is not initial.
    &2 = &3.
  endif.
 debug 'I' gt_messages 'Configuration ' &1 &2  '' .
END-OF-DEFINITION.

DEFINE enmsg.
  clear &2.
  case &1.
    when 'E'.
      MESSAGE e160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
    when 'I'.
      MESSAGE i160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
    when others.
      MESSAGE s160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
  endcase.
  &2-type = &1.
  lm_str = &5.
  &2-MESSAGE_V1 = &3.
  &2-MESSAGE_V2 = &4.
  if strlen( lm_str ) > 50.
    &2-MESSAGE_V3 = lm_str(50).
    &2-MESSAGE_V4 = lm_str+50.
  else.
    &2-MESSAGE_V3 = &5.
    &2-MESSAGE_V4 = &6.
  endif.

  concatenate sy-datum sy-uzeit into &2-PARAMETER separated by space.
  append &2.
  COMMIT WORK.
END-OF-DEFINITION.
DEFINE debug.
  if g_debug_flag = 'X'.
  case &1.
    when 'E'.
      MESSAGE e160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
    when 'I'.
      MESSAGE i160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
    when others.
      MESSAGE s160(/psyng/sw) WITH &3 &4 &5 &6
      into &2-message.
  endcase.
  &2-type = &1.
  lm_str = &5.
  &2-MESSAGE_V1 = &3.
  &2-MESSAGE_V2 = &4.
  if strlen( lm_str ) > 50.
    &2-MESSAGE_V3 = lm_str(50).
    &2-MESSAGE_V4 = lm_str+50.
  else.
    &2-MESSAGE_V3 = &5.
    &2-MESSAGE_V4 = &6.
  endif.
  concatenate sy-datum sy-uzeit into &2-PARAMETER separated by space.
  append &2.
  COMMIT WORK.
  endif.
END-OF-DEFINITION.

DEFINE http_init_client.
  if gf_testmode is initial.
*--Initialize the client if not already done
  if go_http_client is initial.
    CALL METHOD cl_http_client=>create
    EXPORTING
      host               = g_host
      service            = g_port
      scheme             = g_scheme
    IMPORTING
      client             = go_http_client
    EXCEPTIONS
      argument_not_found = 1
      internal_error     = 2
      plugin_not_active  = 3
      OTHERS             = 4. "#EC SAST_CI_GEN_CHECK
    if sy-subrc <> 0.
      case sy-subrc.
          when 1.
            debug 'I' gt_messages 'cl_http_client=>create'
'argument_not_found' '' '' .
          when 2.
            debug 'I' gt_messages 'cl_http_client=>create'
'internal_error' '' '' .
          when 3.
            debug 'I' gt_messages 'cl_http_client=>create'
'plugin_not_active' '' '' .
          when 4.
            debug 'I' gt_messages 'cl_http_client=>create'
'undetermined error in http_init_client' '' '' .
     endcase.
     perform debug_http_error.
    else.

    endif.
  endif.
  go_http_client->refresh_request( ).
*  go_http_client->request->if_http_entity~SET_HEADER_FIELD( name =
*'Accept' value = 'application/json;charset=utf8').
  endif.
END-OF-DEFINITION.
DEFINE http_add_form_field.
  if gf_testmode is initial.
    go_http_client->request->if_http_entity~set_form_field( name = &1
value = &2 ).
  endif.
END-OF-DEFINITION.
FORM m_http_set_json_body
    USING i_data
          i_compress TYPE flag.
data l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.
  CALL METHOD (l_json_class)=>('SERIALIZE')
    EXPORTING
      data     = i_data
      compress = i_compress "skip empty fields
    RECEIVING
      r_json   = lm_str. "#EC PATHLOCK_CI_DYN_ACCES


  IF gf_testmode IS INITIAL.
    go_http_client->request->if_http_entity~set_cdata( data = lm_str ).
    debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .
  ENDIF.

ENDFORM.
DEFINE http_set_json_body.
  perform m_http_set_json_body
    using &1
          &2.
*  CALL METHOD /ui2/cl_json=>serialize
*      EXPORTING
*        data        = &1
*        compress    = &2 "skip empty fields
*      receiving
*        r_json      = lm_str.
*
*
*  if gf_testmode is initial.
*    go_http_client->request->if_http_entity~SET_CDATA( data = lm_str ).
*    debug 'I' gt_messages '/ui2/cl_json=>serialize'    lm_str '' '' .
*  endif.
END-OF-DEFINITION.
DEFINE http_add_header_field.
  if gf_testmode is initial.

CALL METHOD go_http_client->request->IF_HTTP_ENTITY~SET_HEADER_FIELD
       EXPORTING
         name  = &1
         value = &2. "#EC SAST_CI_GEN_CHECK
endif.
END-OF-DEFINITION.
DEFINE http_get_response_header_field.
  if gf_testmode is initial.
    &2 =  go_http_client->response->IF_HTTP_ENTITY~GET_HEADER_FIELD(
name = &1 ).
  endif.
END-OF-DEFINITION.

DEFINE http_get_cookie.
  if gf_testmode is initial.
    CALL METHOD go_http_client->response->IF_HTTP_ENTITY~get_cookie
      EXPORTING
        name    = &1
      IMPORTING
        value   = &2. "#EC SAST_CI_GEN_CHECK

  endif.
END-OF-DEFINITION.
DEFINE http_set_cookie.
  if gf_testmode is initial.
    go_http_client->response->IF_HTTP_ENTITY~SET_COOKIE( name = &1
value = &2 ).
  endif.
END-OF-DEFINITION.

DEFINE encode_html_params.
  CALL METHOD cl_http_utility=>escape_url
    EXPORTING
      unescaped = &1
    receiving
      escaped   = &1.
END-OF-DEFINITION.
DEFINE http_send_request.
  if gf_testmode is initial.


    cl_http_utility=>set_request_uri( request = go_http_client->request
                                      uri     = &1  ).
    go_http_client->request->set_method( &2 ).
    debug 'I' gt_messages 'cl_http_utility=>set_request_uri'    &2 &1
'' .
    perform debug_http_error.
  endif.
END-OF-DEFINITION.

DEFINE http_get_response.
  perform f_http_get_response
    using &3
    changing
        &1
        &2.
END-OF-DEFINITION.
DEFINE http_get_odata_response.
  perform f_http_get_odata_response
    using &3
    changing
        &1
        &2.
END-OF-DEFINITION.

DEFINE json_get_field.
  try.
    lm_attr_name = &2.
    translate lm_attr_name to upper case.
    assign component lm_attr_name of structure  &1 to &3.
  catch CX_SY_CONVERSION_ERROR  into lmo_exc.
      lm_str = lmo_Exc->get_text( ).
      message lm_str type 'S'.
      enmsg 'E' gt_messages lm_str &2 '' '' .
  endtry.
END-OF-DEFINITION.
FORM f_http_get_response
  USING
          i_testdata TYPE string
  CHANGING
          e_text_response TYPE string
          e_data.
  DATA : lo_ref        TYPE REF TO cx_root,
         l_ex_text     TYPE string,
         l_ex_longtext TYPE string,
         l_jsonD_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON'.
  IF gf_testmode = 'X'.
*--Use mocked up JSON data
    e_text_response = i_testdata.
  ENDIF.
  IF gf_testmode IS INITIAL.
    debug 'I' gt_messages 'http_client->send'    '' '' '' .

    CALL METHOD go_http_client->send
      EXPORTING
        timeout                    = g_timeout_seconds
      EXCEPTIONS
        http_communication_failure = 1
        http_invalid_state         = 2
        http_processing_failed     = 3
        OTHERS                     = 4.
    IF sy-subrc = 0.
      debug 'I' gt_messages 'http_client->receive'    '' '' '' .
      CALL METHOD go_http_client->receive
        EXCEPTIONS
          http_communication_failure = 1
          http_invalid_state         = 2
          http_processing_failed     = 3
          OTHERS                     = 4.
      IF sy-subrc = 0.
        lm_response = go_http_client->response.
        PERFORM debug_response_error.
        lm_entity ?= lm_response.
* BOC AKUMAR CVA scan fix DT:05-05-2026
        lm_xresponse = lm_entity->get_data(
             vscan_scan_always = space
         ).
* EOC AKUMAR CVA scan fix DT:05-05-2026
        debug 'I' gt_messages 'cl_abap_conv_in_ce->read' 'xresponse='
lm_xresponse '' .
        TRY.
            CALL METHOD cl_abap_conv_in_ce=>create
              EXPORTING
                encoding    = 'UTF-8'
                endian      = 'L'
                ignore_cerr = 'X'
                replacement = '#'
                input       = lm_xresponse
              RECEIVING
                conv        = lmo_conv.

            CALL METHOD lmo_conv->read
              IMPORTING
                data = e_text_response.
            debug 'I' gt_messages 'cl_abap_conv_in_ce->read'
'text_response=' e_text_response '' .
          CATCH cx_sy_codepage_converter_init
cx_sy_conversion_codepage cx_parameter_invalid_type INTO lo_ref.

            l_ex_longtext = lo_ref->get_longtext( ).
            l_ex_text = lo_ref->get_text( ).
            debug 'I' gt_messages 'cl_abap_conv_in_ce' 'exception'
                  l_ex_text
                  l_ex_longtext .
        ENDTRY.
      ELSE.
        CASE sy-subrc.
          WHEN 1.
            debug 'I' gt_messages 'http_client->receive'
'http_communication_failure' '' '' .
          WHEN 2.
            debug 'I' gt_messages 'http_client->receive'
'http_invalid_state' '' '' .
          WHEN 3.
            debug 'I' gt_messages 'http_client->received'
'http_processing_failed' '' '' .
          WHEN 4.
            debug 'I' gt_messages
'http_client->receive' 'undetermined error in http_client->receive' ''
'' .
        ENDCASE.

        PERFORM debug_http_error.
      ENDIF.
    ELSE.
      CASE sy-subrc.
        WHEN 1.
          debug 'I' gt_messages 'http_client->send'
'http_communication_failure' '' '' .
        WHEN 2.
          debug 'I' gt_messages 'http_client->send'
'http_invalid_state' '' '' .
        WHEN 3.
          debug 'I' gt_messages 'http_client->send'
'http_processing_failed' '' '' .
        WHEN 4.
          debug 'I' gt_messages 'http_client->send'
 'undetermined error in http_client->send' '' '' .
      ENDCASE.

      PERFORM debug_http_error.

    ENDIF.

  ENDIF.
  TRY.
*--Remove characters we don't need (tab, cr_lf and newline)
 DO.
   REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>horizontal_tab
   IN e_text_response WITH ''.
   IF sy-subrc NE 0. EXIT. ENDIF.
 ENDDO.

*      REPLACE ALL OCCURRENCES OF
*cl_abap_char_utilities=>horizontal_tab IN e_text_response WITH ''.

 DO.
   REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
   IN e_text_response WITH ''.
   IF sy-subrc NE 0. EXIT. ENDIF.
 ENDDO.
*      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>cr_lf
* IN e_text_response WITH ''.

 DO.
    REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline
    IN e_text_response WITH ''.
   IF sy-subrc NE 0. EXIT. ENDIF.
 ENDDO.
*      REPLACE ALL OCCURRENCES OF cl_abap_char_utilities=>newline
* IN e_text_response WITH ''.
*      (l_jsonD_class)=>('DESERIALIZE')
*       EXPORTING json = e_text_response
*            CHANGING data =   e_data .
      CALL METHOD  (l_jsonD_class)=>('DESERIALIZE')
        EXPORTING
          json             = e_text_response
        CHANGING
          data             = e_data."#EC PATHLOCK_CI_DYN_ACCES

    CATCH cx_sy_move_cast_error.
      MESSAGE e160(/psyng/sw) WITH 'Invalid Json'.
      debug 'I' gt_messages '/ui2/cl_json=>deserialize'
'cx_sy_move_cast_error' '' '' .

  ENDTRY.
ENDFORM.
*FORM f_http_get_odata_response
*  USING
*          i_testdata TYPE string
*  CHANGING
*          e_text_response TYPE string
*          e_data.
*  DATA : lo_ref           TYPE REF TO cx_root,
*         l_ex_text        TYPE string,
*         l_ex_longtext    TYPE string,
*         lo_odata_mapper  TYPE REF TO /iwfnd/cl_sutil_odata_mapper,
*         lo_xml_helper    TYPE REF TO /iwfnd/cl_sutil_xml_helper,
*         lt_business_data TYPE /iwfnd/sutil_xml_data_t.
*  IF gf_testmode = 'X'.
**--Use mocked up JSON data
*    e_text_response = i_testdata.
*  ENDIF.
*  IF gf_testmode IS INITIAL.
*    debug 'I' gt_messages 'http_client->send'    '' '' '' .
*
*    CALL METHOD go_http_client->send
*      EXPORTING
*        timeout                    = 1000
*      EXCEPTIONS
*        http_communication_failure = 1
*        http_invalid_state         = 2
*        http_processing_failed     = 3
*        OTHERS                     = 4.
*    IF sy-subrc = 0.
*      debug 'I' gt_messages 'http_client->receive'    '' '' '' .
*      CALL METHOD go_http_client->receive
*        EXCEPTIONS
*          http_communication_failure = 1
*          http_invalid_state         = 2
*          http_processing_failed     = 3
*          OTHERS                     = 4.
*      IF sy-subrc = 0.
*        lm_response = go_http_client->response.
*        PERFORM debug_response_error.
*        lm_entity ?= lm_response.
*        lm_xresponse = lm_entity->get_data( ).
*        debug 'I' gt_messages 'cl_abap_conv_in_ce->read' 'xresponse='
*lm_xresponse '' .
*      ELSE.
*        CASE sy-subrc.
*          WHEN 1.
*            debug 'I' gt_messages 'http_client->receive'
*'http_communication_failure' '' '' .
*          WHEN 2.
*            debug 'I' gt_messages 'http_client->receive'
*'http_invalid_state' '' '' .
*          WHEN 3.
*            debug 'I' gt_messages 'http_client->received'
*'http_processing_failed' '' '' .
*          WHEN 4.
*            debug 'I' gt_messages 'http_client->receive'
*'undetermined error in http_client->receive' '' '' .
*        ENDCASE.
*
*        PERFORM debug_http_error.
*      ENDIF.
*    ELSE.
*      CASE sy-subrc.
*        WHEN 1.
*          debug 'I' gt_messages 'http_client->send'
*'http_communication_failure' '' '' .
*        WHEN 2.
*          debug 'I' gt_messages 'http_client->send'
*'http_invalid_state' '' '' .
*        WHEN 3.
*          debug 'I' gt_messages 'http_client->send'
*'http_processing_failed' '' '' .
*        WHEN 4.
*          debug 'I' gt_messages 'http_client->send'
*'undetermined error in http_client->send' '' '' .
*      ENDCASE.
*
*      PERFORM debug_http_error.
*
*    ENDIF.
*
*  ENDIF.
*
**--Convert to string for debuggging
*  TRY.
*      CALL METHOD cl_abap_conv_in_ce=>create
*        EXPORTING
*          encoding    = 'UTF-8'
*          endian      = 'L'
*          ignore_cerr = 'X'
*          replacement = '#'
*          input       = lm_xresponse
*        RECEIVING
*          conv        = lmo_conv.
*
*      CALL METHOD lmo_conv->read
*        IMPORTING
*          data = e_text_response.
*      debug 'I' gt_messages 'cl_abap_conv_in_ce->read'
*'text_response=' e_text_response '' .
*    CATCH cx_sy_codepage_converter_init cx_sy_conversion_codepage
*cx_parameter_invalid_type INTO lo_ref.
*
*      l_ex_longtext = lo_ref->get_longtext( ).
*      l_ex_text = lo_ref->get_text( ).
*      debug 'I' gt_messages 'cl_abap_conv_in_ce' 'exception'
*            l_ex_text
*            l_ex_longtext .
*  ENDTRY.
*
*
*  DATA : l_error_text TYPE string.
*  CREATE OBJECT lo_odata_mapper.
**    CALL METHOD lo_odata_mapper->get_business_data
**      EXPORTING
**        iv_xdoc         = lm_xresponse
**      IMPORTING
**        et_busi_data    =  lt_business_data
***        ev_payload_type =
***        ev_base_url     =
**        ev_error_text   = l_ex_text.
*  DATA : l_typ TYPE c.
*  FIELD-SYMBOLS : <field>  TYPE any,
*                  <table>  TYPE STANDARD TABLE,
*                  <struct> TYPE any.
*  ASSIGN e_data->* TO <field> .
*  DESCRIBE FIELD <field> TYPE l_typ.
*  IF l_typ = 'h'. "TABLE
*    ASSIGN e_data->* TO <table> .
*    CALL METHOD lo_odata_mapper->convert_to_abap
*      EXPORTING
*        iv_xdoc       = lm_xresponse
*      IMPORTING
*        ed_data       = <table>
*        ev_error_text = l_error_text.
*  ELSEIF l_typ = 'v'."DEEP STRUCTURE
*    ASSIGN e_data->* TO <struct> .
*    CALL METHOD lo_odata_mapper->convert_to_abap
*      EXPORTING
*        iv_xdoc       = lm_xresponse
*      IMPORTING
*        ed_data       = <struct>
*        ev_error_text = l_error_text.
*
*  ENDIF.
*
*
*
**    CALL METHOD lo_odata_mapper->convert_structure
**      EXPORTING
**        it_xml_data   =
***      IMPORTING
***        ed_data       =
***        ev_error_text =
**        .
*
*
**    perform parse_odata_business_data
**      using lt_business_data[]
**      changing e_data.
*ENDFORM.
DEFINE json_deserialize.
*  TRY.
*      /ui2/cl_json=>deserialize( EXPORTING json = &1 CHANGING data =
*&2 ).
**    CATCH cx_sy_move_cast_error into data(e).
***      MESSAGE e001(00) WITH 'Invalid Json'.
**      lm_str = e->IF_MESSAGE~GET_TEXT( ).
**      debug 'I' gt_messages '/ui2/cl_json=>deserialize'
*'cx_sy_move_cast_error' lm_str '' .
*
*  ENDTRY.
  perform f_json_deserialize using &1 changing &2.
END-OF-DEFINITION.
FORM f_json_deserialize
    USING    i_json
    CHANGING e_data.

  data: l_json_class     TYPE seoclass-clsname VALUE '/UI2/CL_JSON',
        e type string.
  TRY.

CALL METHOD (l_json_class)=>('DESERIALIZE')
  EXPORTING
    json             = i_json
  CHANGING
    data             = e_data. "#EC PATHLOCK_CI_DYN_ACCES

*      /ui2/cl_json=>deserialize( EXPORTING json = i_json CHANGING data
*=  e_data ).

    CATCH cx_sy_move_cast_error.
*      MESSAGE e001(00) WITH 'Invalid Json'.
     MESSAGE e160(/psyng/sw) WITH 'Invalid Json'.
      debug 'I' gt_messages '/ui2/cl_json=>deserialize'
'cx_sy_move_cast_error' '' '' .

  ENDTRY.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DEBUG_HTTP_ERROR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM debug_http_error .
  DATA : l_subrc TYPE sysubrc,
         l_msg   TYPE string.
  IF NOT go_http_client IS INITIAL.
    CALL METHOD go_http_client->get_last_error
      IMPORTING
        code    = l_subrc
        message = l_msg.
    IF NOT l_subrc IS INITIAL.
      debug 'E' gt_messages 'http client error' l_subrc l_msg '' .
    ENDIF.
  ELSE.
    debug 'I' gt_messages 'go_http_client is initial' '' '' ''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DEBUG_RESPONSE_ERROR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM debug_response_error .
  DATA : l_subrc  TYPE sysubrc,
         l_reason TYPE string.
  IF NOT go_http_client->response IS INITIAL.
    CALL METHOD go_http_client->response->get_last_error
      RECEIVING
        rc = l_subrc.

    IF NOT l_subrc IS INITIAL.
      debug 'I' gt_messages 'http response code' l_subrc  '' ''.
    ENDIF.
    CALL METHOD go_http_client->response->get_status
      IMPORTING
        code   = l_subrc
        reason = l_reason.
    IF NOT l_subrc IS INITIAL OR NOT l_reason IS INITIAL.
      IF l_subrc = '200'.
        debug 'I' gt_messages 'http response status' l_subrc  l_reason
''.
      ELSE.
        enmsg 'E' gt_messages 'http response status' l_subrc  l_reason
''.
      ENDIF.
    ENDIF.
  ELSE.
    debug 'I' gt_messages 'go_http_client->response is initial' '' ''
''.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPPERCASE_ATTRIBUTES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_ATTRIBUTES  text
*----------------------------------------------------------------------*
*FORM uppercase_attributes
*  TABLES   et_attributes STRUCTURE /psyng/ex_up_attributes.
*  FIELD-SYMBOLS : <attr> TYPE /psyng/ex_up_attributes.
*  LOOP AT et_attributes ASSIGNING <attr>.
*    TRANSLATE <attr>-name TO UPPER CASE.
*  ENDLOOP.
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PARSE_ODATA_BUSINESS_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_E_DATA[]  text
*      -->P_LT_BUSINESS_DATA  text
*----------------------------------------------------------------------*
*FORM parse_odata_business_data
*   USING    it_business_data TYPE /iwfnd/sutil_xml_data_t
*  CHANGING et_data TYPE REF TO data
* .
*  FIELD-SYMBOLS : <bd>     TYPE /iwfnd/sutil_xml_data,
*                  <bdend>  TYPE /iwfnd/sutil_xml_data,
*                  <record> TYPE any,
*                  <field>  TYPE any,
*                  <table>  TYPE STANDARD TABLE,
*                  <struct> TYPE any.
*  DATA : lo_tabledescr  TYPE REF TO cl_abap_tabledescr,
*         lo_structdescr TYPE REF TO cl_abap_structdescr,
*         lt_fields      TYPE abap_compdescr_tab,
*         l_idx          TYPE i,
*         ls_record      TYPE REF TO data,
*         l_fieldname    TYPE string,
*         oref           TYPE REF TO cx_root,
*         lf_table       TYPE flag,
*         lf_struct      TYPE flag,
*         l_typ          TYPE c.
*
*  ASSIGN et_data->* TO <field> .
*  DESCRIBE FIELD <field> TYPE l_typ.
*  IF l_typ = 'h'. "TABLE
*    lf_table = 'X'.
*    ASSIGN et_data->* TO <table> .
*  ELSEIF l_typ = 'v'."DEEP STRUCTURE
*    ASSIGN et_data->* TO <struct> .
*    lf_struct = 'X'.
*  ENDIF.
*  IF lf_table = 'X'.
**--Parse a table
*    lo_tabledescr ?=   cl_abap_tabledescr=>describe_by_data( <table> ).
*    lo_structdescr ?=  lo_tabledescr->get_table_line_type( ).
*    lt_fields[] = lo_structdescr->components.
*    SORT lt_fields BY name.
**--Parse the results part of the odata described by the business data
*
*    LOOP AT   it_business_data ASSIGNING <bd>.
*      IF <bd>-tag_name CP '-entry *'.
**--new record starts
*        IF <record> IS ASSIGNED.
*          APPEND <record> TO <table>.
*        ENDIF.
*        CREATE DATA ls_record TYPE HANDLE lo_structdescr.
*        ASSIGN ls_record->* TO <record>.
*      ENDIF.
*      l_fieldname = <bd>-tag_name.
*      TRANSLATE l_fieldname TO UPPER CASE.
*      READ TABLE lt_fields WITH  KEY name = l_fieldname
*      BINARY SEARCH
*      TRANSPORTING NO FIELDS.
*      IF sy-subrc = 0.
*        ASSIGN COMPONENT l_fieldname
*              OF STRUCTURE <record>
*              TO <field>.
*        <field> = <bd>-tag_value.
*      ENDIF.
*    ENDLOOP.
**--Append the last record
*    IF <record> IS ASSIGNED.
*      APPEND <record> TO <table>.
*    ENDIF.
*  ELSEIF lf_struct = 'X'.
**--Parse a Structure
*    LOOP AT   it_business_data ASSIGNING <bd>.
*    ENDLOOP.
*  ENDIF.
*ENDFORM.
DEFINE remove_host_from_url .
  clear lm_remove.
 case g_scheme.
     when 1.
       lm_remove = 'https://'.
     when 2.
       lm_remove = 'https://'.
 endcase.
* lm_remove = lm_remove && g_host.
 CONCATENATE lm_remove g_host into lm_remove.
 replace lm_remove in &1 with ''.
END-OF-DEFINITION.

*--validation
*---string len
DEFINE get_len.
  l_len = strlen( &1 ).
END-OF-DEFINITION.

*check length
DEFINE concate_string.
  get_len &1.
  if l_len > &2.
    CONCATENATE &3 &4 into
    et_incom_obj-issuelocation SEPARATED BY space.
    error &5 et_incom_obj-issuelocation.
    clear l_len.
    endif.
END-OF-DEFINITION.

*---collect erros
DEFINE error.
  et_incom_obj-issue = &1.
  et_incom_obj-issuelocation = &2.
  append et_incom_obj.
END-OF-DEFINITION.
