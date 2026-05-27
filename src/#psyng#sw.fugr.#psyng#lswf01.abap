*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSWF01                                              *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  init_editor
*&---------------------------------------------------------------------*
*       Initialize editor
*----------------------------------------------------------------------*
FORM init_editor.
  DATA: l_text       TYPE TABLE OF char80.
  STATICS: l_text_reload TYPE /psyng/flagx,
           lo_textedit   TYPE REF TO cl_gui_textedit,
           lo_container  TYPE REF TO cl_gui_custom_container.


  IF l_text_reload = space.
    l_text_reload = 'X'.

*   create control container
    IF lo_textedit IS INITIAL.
      CREATE OBJECT lo_container
        EXPORTING
          container_name              = 'STEXTEDITO1'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.

*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT lo_textedit
        EXPORTING
          parent                     = lo_container
wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
wordwrap_to_linebreak_mode = cl_gui_textedit=>false
EXCEPTIONS
OTHERS                     = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.

    CALL METHOD lo_textedit->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.

    CALL METHOD lo_textedit->set_toolbar_mode
      EXPORTING
        toolbar_mode           = '0'
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.


  ENDIF.

  l_text[] = gt_text[].

* fill with text
  CALL METHOD lo_textedit->set_text_as_r3table
    EXPORTING
      table           = l_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.
ENDFORM.                    " init_editor
*&---------------------------------------------------------------------*
*&      Form  sw_029_receive_SW_026
*&---------------------------------------------------------------------*
*       Receive results from function module /PSYNG/SW_026 that is being
*       called from /PSYNG/SW_029
*----------------------------------------------------------------------*
FORM sw_029_receive_sw_026 USING i_taskname.
  DATA : lt_tcode        TYPE   TABLE OF  tstc.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_026'
  TABLES
    i_tcodes       = lt_tcode
     o_tcodes       = gt_result_sw_026
  EXCEPTIONS
        resource_failure      = 1
        communication_failure = 2
        system_failure        = 3.
  IF sy-subrc <> 0.
    gf_sw_026_failed = 'X'.
  ENDIF.

  .
  DELETE gt_tasks_sw_029 WHERE taskname = i_taskname.
  MESSAGE s142(/psyng/sw) WITH 'TSTCP'.
ENDFORM.                    " sw_029_receive_SW_026
*&---------------------------------------------------------------------*
*&      Form  SW_029_receive_SW_027
*&---------------------------------------------------------------------*
*       Receive results from function module /PSYNG/SW_027 that is being
*       called from /PSYNG/SW_029
*----------------------------------------------------------------------*
FORM sw_029_receive_sw_027 USING i_taskname.
  DATA : lt_tcode        TYPE   TABLE OF  tstc.

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_027'
  TABLES
    i_tcodes       = lt_tcode
     o_tcodes       = gt_result_sw_027
  EXCEPTIONS
        resource_failure      = 1
        communication_failure = 2
        system_failure        = 3.
  IF sy-subrc <> 0.
    gf_sw_027_failed = 'X'.
  ENDIF.
  DELETE gt_tasks_sw_029 WHERE taskname = i_taskname.
  MESSAGE s142(/psyng/sw) WITH 'CROSS'.

ENDFORM.                    " SW_029_receive_SW_027

*&---------------------------------------------------------------------*
*&      Form  update_history
*&---------------------------------------------------------------------*
*       Papulate history table
*----------------------------------------------------------------------*
FORM update_history USING    i_tabname
                             i_hdrfld
                             i_dtlfld
                             i_oldval
                             i_newval
                             p_vrsio
                             i_status.
* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  /psyng/history-tabname = i_tabname.
  /psyng/history-hdrfld = i_hdrfld.
  /psyng/history-dtlfld = i_dtlfld.
  /psyng/history-oldval = i_oldval.
  /psyng/history-newval = i_newval.
  /psyng/history-vrsio  = p_vrsio.
  /psyng/history-status = i_status.
  /psyng/history-create_dat = sy-datum.
  /psyng/history-create_tim = sy-uzeit.
  /psyng/history-create_usr = l_current_user. "sy-uname. "C0700
  MODIFY /psyng/history.
  CLEAR /psyng/history.
ENDFORM.                    " update_history

*&---------------------------------------------------------------------*
*&      Form  get_spp_value
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_PP_AUTH_CALLTRANSACTION  text
*----------------------------------------------------------------------*
FORM get_spp_value CHANGING p_l_pp_auth_calltransaction.
*20110526 SF 1772 - Added exception handling
  DATA : ls_prop       TYPE tpfypropty,
         l_usrval(60)  TYPE c,
         l_profval(60) TYPE c,
         lt_parmvalues TYPE TABLE OF parmvalues,
         ls_paramvalue TYPE parmvalues.
  ls_paramvalue-param_name = 'auth/check/calltransaction'.
  APPEND ls_paramvalue TO lt_parmvalues.
  CALL FUNCTION 'PFL_GET_PARAMETER'
    TABLES
      parameter_table = lt_parmvalues
    EXCEPTIONS
      OTHERS          = 1.
  IF sy-subrc = 0.
    READ TABLE lt_parmvalues INDEX 1 INTO ls_paramvalue.
    IF sy-subrc = 0.
      p_l_pp_auth_calltransaction = ls_paramvalue-user_value.
    ELSE.
      p_l_pp_auth_calltransaction = 0.
    ENDIF.
  ELSE.
    p_l_pp_auth_calltransaction = 0.
  ENDIF.
ENDFORM.                    " get_spp_value

*&---------------------------------------------------------------------
*
*&      Form  update_changedocu
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------

FORM update_changedocu.

*DATA: LS_FUNCTIONEMPTY TYPE /PSYNG/FUNCTION,
*      LS_FUNCTTRANEMPTY TYPE /PSYNG/FUNCTTRAN,
*      LS_FAOBJ2EMPTY TYPE /PSYNG/FAOBJ2,
*      LS_FTEXTSEMPTY TYPE /PSYNG/TEXTS.
*
*CLEAR: LS_FUNCTIONEMPTY, LS_FUNCTTRANEMPTY, LS_FAOBJ2EMPTY,
*       LS_FTEXTSEMPTY.
*
*CALL FUNCTION '/PSYNG/FUNCTS_WRITE_DOCUMENT'
*  EXPORTING
*    objectid                      = OBJECTID
*    tcode                         = TCODE
*    utime                         = UTIME
*    udate                         = UDATE
*    username                      = USERNAME
*    PLANNED_CHANGE_NUMBER         = PLANNED_CHANGE_NUMBER
*    OBJECT_CHANGE_INDICATOR       = CDOC_UPD_OBJECT
*    PLANNED_OR_REAL_CHANGES       = CDOC_PLANNED_OR_REAL
*    NO_CHANGE_POINTERS            = CDOC_NO_CHANGE_POINTERS
*    UPD_ICDTXT_FUNCTS             = UPD_ICDTXT_FUNCTS
*    n_psyng_faobj2                = LS_FAOBJ2EMPTY
*    o_psyng_faobj2                = /PSYNG/FAOBJ2
*    UPD_PSYNG_FAOBJ2              = UPD_PSYNG_FAOBJ2
*    n_psyng_function              = LS_FUNCTIONEMPTY
*    o_psyng_function              = /PSYNG/FUNCTION
*    UPD_PSYNG_FUNCTION            = UPD_PSYNG_FUNCTION
*    n_psyng_functtran             = LS_FUNCTTRANEMPTY
*    o_psyng_functtran             = /PSYNG/FUNCTTRAN
*    UPD_PSYNG_FUNCTTRAN           = UPD_PSYNG_FUNCTTRAN
*    n_psyng_texts                 = LS_FTEXTSEMPTY
*    o_psyng_texts                 = /PSYNG/TEXTS
*    UPD_PSYNG_TEXTS               = UPD_PSYNG_TEXTS
*
*  tables
*    icdtxt_functs                 = ICDTXT_FUNCTS
*          .
*CLEAR: planned_change_number.

ENDFORM.                    " update_changedocu
*&---------------------------------------------------------------------*
*&      Form  init_editor_1200
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_editor_1200.
  DATA: l_text  LIKE TABLE OF gt_text.

  STATICS: l_text_reload TYPE /psyng/flagx,
           lo_textedit   TYPE REF TO cl_gui_textedit,
           lo_container  TYPE REF TO cl_gui_custom_container.


  IF l_text_reload = space.
    l_text_reload = 'X'.

*   create control container
    IF lo_textedit IS INITIAL.
      CREATE OBJECT lo_container
        EXPORTING
          container_name              = 'CRITCODETXT'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.

*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT lo_textedit
        EXPORTING
          parent                     = lo_container
wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
wordwrap_to_linebreak_mode = cl_gui_textedit=>false
EXCEPTIONS
OTHERS                     = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.

    CALL METHOD lo_textedit->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

  l_text[] = gt_text[].

* fill with text
  CALL METHOD lo_textedit->set_text_as_r3table
    EXPORTING
      table           = l_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDFORM.                    " init_editor_1200
*&---------------------------------------------------------------------*
*&      Form  init_editor_1201
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_editor_1201.
  DATA: l_text  LIKE TABLE OF gt_text.

  STATICS: l_text_reload TYPE /psyng/flagx,
           lo_textedit   TYPE REF TO cl_gui_textedit,
           lo_container  TYPE REF TO cl_gui_custom_container.


  IF l_text_reload = space.
    l_text_reload = 'X'.

*   create control container
    IF lo_textedit IS INITIAL.
      CREATE OBJECT lo_container
        EXPORTING
          container_name              = 'CRITAUTH'
        EXCEPTIONS
          cntl_error                  = 1
          cntl_system_error           = 2
          create_error                = 3
          lifetime_error              = 4
          lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.

*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT lo_textedit
        EXPORTING
          parent                     = lo_container
wordwrap_mode              = cl_gui_textedit=>wordwrap_at_fixed_position
wordwrap_to_linebreak_mode = cl_gui_textedit=>false
EXCEPTIONS
OTHERS                     = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.

    CALL METHOD lo_textedit->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

  l_text[] = gt_text[].

* fill with text
  CALL METHOD lo_textedit->set_text_as_r3table
    EXPORTING
      table           = l_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDFORM.                    " init_editor_1201


*---------------------------------------------------------------------*
*       FORM tcode_has_auth_check                                     *
*---------------------------------------------------------------------*
*--CALL TRANSACTION statement has a new addition WITH AUTHORITY CHECK
*  starting from SAP release 750.
*  Info : https://goo.gl/6H29Tt
*  When an auth check if performed before transaction is called,
*  don't consider it for dynamic sod matrix enhancement
*---------------------------------------------------------------------*
*  -->  I_INCLUDE                                                     *
*  -->  I_TCODE                                                       *
*  -->  E_AUTH_CHECK                                                  *
*---------------------------------------------------------------------*
FORM tcode_has_auth_check USING
  i_include
  i_tcode
    CHANGING
  e_auth_check.
  CLEAR e_auth_check.
  CHECK sy-saprl GE '750'.
  TYPES: BEGIN OF t_tcode_calls,
           include LIKE cross-include,
           tcode   LIKE sy-tcode,
           auth    TYPE flag,
         END OF t_tcode_calls.
  STATICS : lt_tcode_calls TYPE HASHED TABLE OF t_tcode_calls WITH
  UNIQUE KEY include tcode WITH HEADER LINE.
  DATA : lt_relevant TYPE TABLE OF sstmnt WITH HEADER LINE,
         lt_tokens   TYPE TABLE OF stoken WITH HEADER LINE,
         lt_levels   LIKE slevel OCCURS 0 WITH HEADER LINE,
         l_statement TYPE string.
  DATA: BEGIN OF lt_report OCCURS 0,
          line(256) TYPE c,
        END OF lt_report.
  DATA : lt_statements  LIKE lt_report OCCURS 0 WITH HEADER LINE.

  READ TABLE lt_tcode_calls WITH TABLE KEY include = i_include
                                           tcode   = i_tcode.
  IF sy-subrc = 0.
    e_auth_check = lt_tcode_calls-auth.
  ELSE.

    lt_statements = 'CALL'.
    APPEND  lt_statements.
    lt_statements = 'AUTHORITY'.
    APPEND  lt_statements.


    CLEAR e_auth_check.
    READ REPORT i_include INTO lt_report.
    CHECK sy-subrc = 0.
    SCAN ABAP-SOURCE lt_report KEYWORDS FROM lt_statements
      TOKENS INTO lt_tokens
      STATEMENTS INTO  lt_relevant
      WITH INCLUDES.
    LOOP AT lt_relevant.
      CLEAR l_statement.
      LOOP AT lt_tokens FROM lt_relevant-from TO lt_relevant-to.
        CONCATENATE l_statement lt_tokens-str INTO l_statement.
      ENDLOOP.
      CONDENSE l_statement NO-GAPS.
      TRANSLATE l_statement TO UPPER CASE.
      CHECK l_statement CS 'CALLTRANSACTION'.
      CHECK l_statement CS i_tcode.
      IF l_statement CS 'WITHOUTAUTHORITY-CHECK'.
        CLEAR e_auth_check.
        EXIT.
*--If there's one call without an auth check, return no auth check
      ELSE.
        e_auth_check = 'X'.
      ENDIF.
    ENDLOOP.
    lt_tcode_calls-include = i_include.
    lt_tcode_calls-tcode   = i_tcode.
    lt_tcode_calls-auth    = e_auth_check.
    INSERT TABLE lt_tcode_calls.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  api_handle_error
*&---------------------------------------------------------------------*
*       Determine Error codes for API FM's :
*       /PSYNG/SW_SOD_BY_ROLE_COMBO
*       /PSYNG/SW_SOD_BY_USER_N_SIMU
*----------------------------------------------------------------------*
*      <--P_RETURN  text
*      -->P_LT_RETURN  text
*----------------------------------------------------------------------*
FORM api_handle_error TABLES   it_return STRUCTURE bapiret2
                               et_return STRUCTURE bapireturn
                      CHANGING es_return TYPE      bapireturn
                      .
  FIELD-SYMBOLS : <ret> TYPE  bapiret2.
  DATA: l_count TYPE balmnr.
  SORT it_return BY type.
  LOOP AT it_return ASSIGNING <ret>.
*--Assign a Unique nr to each type of error
    CASE <ret>-id.
      WHEN 'NOCONFLICTS'.
        <ret>-log_no = '1'.
      WHEN 'NOUSERS'.
        <ret>-log_no = '2'.
      WHEN 'NOVERSION'.
        <ret>-log_no = '3'.
      WHEN 'NOCONFIGSET'.
        <ret>-log_no = '4'.
      WHEN 'NOSIMUROLES'.
        <ret>-log_no = '5'.
      WHEN 'INVALIDVERSION'.
        <ret>-log_no = '6'.
      WHEN 'INVALIDCONFSET'.
        <ret>-log_no = '7'.
      WHEN 'NOGLOBALCONFSET'.
        <ret>-log_no = '8'.
      WHEN 'INVALIDROLE'.
        <ret>-log_no = '9'.
      WHEN 'ROLERFCFAIL'.
        <ret>-log_no = '10'.
      WHEN 'DEFAULT_VERSION'.
        <ret>-log_no = '11'.
      WHEN 'NO_DEFAULT_VERSION'.
        <ret>-log_no = '12'.
      WHEN 'CFG_SET_ENABLED'.
        <ret>-log_no = '13'.
      WHEN 'CFG_SET_DISABLED'.
        <ret>-log_no = '14'.
      WHEN OTHERS.
*--Fall back to the first characters of the id of the message.
        MOVE <ret>-id TO es_return-code.
    ENDCASE.
    ADD 1 TO l_count.
    IF <ret>-type CO 'EW'.
      IF es_return-type <> 'E'.
*--Fill return structure if not already filled with error
        MOVE-CORRESPONDING <ret> TO es_return.
        es_return-log_no = <ret>-id.
        es_return-code   = <ret>-log_no .
        es_return-log_msg_no = l_count.
      ENDIF.
    ENDIF.
*--Convert to BAPIRETURN structure
    MOVE-CORRESPONDING <ret> TO et_return.
    et_return-log_no = <ret>-id.
    et_return-code   = <ret>-log_no .
    et_return-log_msg_no = l_count.
    APPEND et_return.
  ENDLOOP.

  IF es_return IS INITIAL.
    es_return-type    = 'S'.
    es_return-message = 'Success'.
    es_return-code    = '0'.
    es_return-log_no  = 'SUCCESS'.
    es_return-log_msg_no = l_count + 1.
    APPEND es_return TO et_return.
  ENDIF.

ENDFORM.                    " api_handle_error
*&---------------------------------------------------------------------*
*&      Form  validate_sod_matrix
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_VRSIO  text
*      <--P_EF_INVALID_VERSION  text
*----------------------------------------------------------------------*
FORM validate_sod_matrix USING    i_vrsio
                         CHANGING ef_invalid_version.
  SELECT SINGLE vrsio INTO i_vrsio FROM /psyng/swsodvers
   WHERE vrsio = i_vrsio.
  IF sy-subrc <> 0.
    ef_invalid_version = 'X'.
  ELSE.
    CLEAR ef_invalid_version.
  ENDIF.
ENDFORM.                    " validate_sod_matrix
*&---------------------------------------------------------------------*
*&      Form  api_validate_roles
*&---------------------------------------------------------------------*
*       Validate that each role exists and the destinations
*       are reachable.
*       Any issues are returned as a W(warning) message.
*       If no valid roles are found, the FM doing the actual SOD
*       analysis will return an E (error).
*----------------------------------------------------------------------*
*      -->P_ROLES  text
*      -->P_LT_RETURN  text
*----------------------------------------------------------------------*
FORM api_validate_roles
TABLES   et_roles  STRUCTURE /psyng/sw_sod_remote_roles
         et_return STRUCTURE bapiret2.
  FIELD-SYMBOLS:
          <role>         TYPE          /psyng/sw_sod_remote_roles.
  DATA :  lt_unique_rfcs   TYPE TABLE OF /psyng/sw_sod_remote_roles
                         WITH HEADER LINE,
          l_rfc            TYPE rfcdest,
          lt_role_names    TYPE TABLE OF agr_define
                         WITH HEADER LINE,
          l_system_msg(72) TYPE c,
          l_in_cnt         TYPE i,
          l_out_cnt        TYPE i,
          l_agr_name       TYPE agr_name.
  RANGES : range_roles   FOR l_agr_name.
*--Populate RFC destinations with LOCAL if left blank
  LOOP AT et_roles ASSIGNING <role>.
    IF <role>-rfcdest IS INITIAL.
      <role>-rfcdest = 'LOCAL'.
    ENDIF.
  ENDLOOP.
*--Check if the roles exist, if not add error message
  lt_unique_rfcs[] = et_roles[].
  SORT lt_unique_rfcs BY rfcdest.
  DELETE ADJACENT DUPLICATES FROM  lt_unique_rfcs COMPARING rfcdest.
  LOOP AT lt_unique_rfcs .
    REFRESH : range_roles, lt_role_names.
    range_roles-sign   = 'I'.
    range_roles-option = 'EQ'.
    LOOP AT et_roles WHERE rfcdest = lt_unique_rfcs-rfcdest.
      range_roles-low  = et_roles-agr_name.
      APPEND range_roles.
    ENDLOOP.
    l_rfc = lt_unique_rfcs-rfcdest.
    IF l_rfc = 'LOCAL'.
      CLEAR l_rfc.
    ENDIF.


*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

    CALL FUNCTION '/PSYNG/SW_102'
      DESTINATION l_rfc
      TABLES
        it_roles_range        = range_roles
        et_roles              = lt_role_names
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      log_v et_return 'W' 'ROLERFCFAIL' 'Unable to validate roles on '
                         lt_unique_rfcs-rfcdest  l_system_msg
                         lt_unique_rfcs-rfcdest ''.
      DELETE et_roles WHERE rfcdest = lt_unique_rfcs-rfcdest.
    ELSE.
      DESCRIBE TABLE range_roles   LINES l_in_cnt.
      DESCRIBE TABLE lt_role_names LINES l_out_cnt.
      IF l_in_cnt <> l_out_cnt.
*--Some roles not found
        SORT lt_role_names BY agr_name.
        LOOP AT   range_roles.
          READ TABLE lt_role_names WITH KEY agr_name = range_roles-low
          BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            log_v et_return 'W' 'INVALIDROLE' 'Invalid Role. '
                            lt_unique_rfcs-rfcdest range_roles-low
                            lt_unique_rfcs-rfcdest range_roles-low.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " api_validate_roles
*&---------------------------------------------------------------------*
*&      Form  api_validate_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IF_DEF_VRSIO  text
*      -->P_IF_DEF_CONF  text
*      <--P_VRSIO  text
*      <--P_CONFIG_SET  text
*      <--P_ES_CONFIG_SET  text
*      <--P_ES_SOD_MATRIX  text
*      <--P_LF_CONTINUE  text
*      -->P_LT_RETURN  text
*      -->P_CHECK  text
*      -->P_LF_CONTINUE  text
*      -->P_=  text
*      -->P_'X'  text
*----------------------------------------------------------------------*
FORM api_validate_input
TABLES   et_return     STRUCTURE bapiret2
USING    if_def_vrsio  TYPE flag
         if_def_conf   TYPE flag
CHANGING vrsio         TYPE /psyng/sodvrsio
         config_set    TYPE /psyng/seconfid
         es_config_set TYPE /psyng/swcfgset
         es_sod_matrix TYPE /psyng/swsodvers
         ef_continue   TYPE flag
.

  DATA : l_dflt_vrsio       TYPE /psyng/param,
         lf_cfg_set_enabled TYPE flag.
  IF if_def_vrsio = 'X'.
*--Use default global version
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF NOT l_dflt_vrsio IS INITIAL.
      log_v et_return 'I' 'DEFAULT_VERSION'
        'SOD Matrix version used :' 'DFLT_GLOBAL_VERSION'
        l_dflt_vrsio l_dflt_vrsio ''.
      vrsio = l_dflt_vrsio.
    ELSE.
      log et_return 'E' 'NO_DEFAULT_VERSION'
        'No Default SOD Matrix defined in ' 'DFLT_GLOBAL_VERSION' '' ''.
      CLEAR ef_continue.
    ENDIF.
  ELSE.
    SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
    WHERE vrsio = vrsio.
    IF sy-subrc <> 0.
      log et_return 'E' 'INVALIDVERSION'
      'SOD Matrix version is invalid ' vrsio '.' ''.
      CLEAR ef_continue.
    ENDIF.
  ENDIF.
  CHECK ef_continue = 'X'.
*--return info on SOD Matrix
  SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
  WHERE vrsio = vrsio.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled = 'X'.
    log et_return 'I' 'CFG_SET_ENABLED'
       'Configuration Set functionality enabled'
       'CFG_SET_ENABLED = X' '' ''.

    IF if_def_conf = 'X'.
*  --Use default Configuration Set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio      = 'X'
          i_cfgvrsio   = vrsio
        IMPORTING
          e_config_set = es_config_set-setid
          ef_success   = ef_continue
        TABLES
          et_return    = et_return.
      IF ef_continue = 'X'.
        config_set = es_config_set-setid.
      ENDIF.
    ENDIF.
*  --Validate Configuration Set
    IF ef_continue = 'X'.
      SELECT SINGLE *  INTO es_config_set FROM /psyng/swcfgset
       WHERE setid  = config_set.
      IF sy-subrc <> 0.
        log_v et_return 'E' 'INVALIDCONFSET'
          'Configuration Set Does not exist.' config_set ''
          config_set ''.
        CLEAR ef_continue.
      ENDIF.
    ENDIF.
  ELSE.
    log et_return 'I' 'CFG_SET_DISABLED'
      'Configuration Set functionality Disabled'
      'CFG_SET_ENABLED <> X' '' ''.
  ENDIF.

ENDFORM.                    " api_validate_input
**&---------------------------------------------------------------------*
**&      Form  create_logging_entry
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_L_START_DATE  text
**      -->P_L_START_TIME  text
**      -->P_REQUEST_ID  text
**      -->P_BATCH_ID   text
**      -->P_API   text
**      -->P_L_RESULTS  text
**      -->P_RETURN  text
**      -->P_USER   text
**----------------------------------------------------------------------*
*FORM create_logging_entry
*USING i_start_date TYPE dats
*      i_start_time TYPE tims
*      i_request_id TYPE /psyng/request_id
*      i_batch_id   TYPE /psyng/batch_id
*      i_api        TYPE rs38l_fnam
*      i_results    TYPE int4
*      i_return     TYPE bapireturn
*      i_object     TYPE /psyng/longtext
*      i_timestamp  type timestampl.
*
*  DATA: l_runtime TYPE /psyng/dec11.
**  GET RUN TIME FIELD g_stop.
**  l_runtime = ( g_stop - g_start ) / 1000.
*
**--Call logging FM
*  CALL FUNCTION '/PSYNG/BASIS_CREATE_LOGGING' IN UPDATE TASK
*       EXPORTING
*            i_date        = i_start_date
*            i_time        = i_start_time
*            i_request_id  = i_request_id
*            i_batch_id    = i_batch_id
*            i_api         = i_api
*            i_bname       = sy-uname
*            i_results     = i_results
*            i_return_code = i_return-code
*            i_return_type = i_return-type
*            i_message     = i_return-message
*            i_runtime     = l_runtime
*            i_object      = i_object
*            i_timestamp   = i_timestamp.
*ENDFORM.                    " create_logging_entry
*&---------------------------------------------------------------------*
*&      Form  add_param_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_CONFIG  text
*----------------------------------------------------------------------*
FORM add_param_info TABLES
  et_config STRUCTURE /psyng/se_config_param.
  FIELD-SYMBOLS : <cfg> TYPE /psyng/se_config_param.
* Add defaults and SW-defined flags
* Add defaults and SW-defined flags
  LOOP AT et_config ASSIGNING <cfg>.
    CASE <cfg>-param.
      WHEN 'AREA_MENU'.
        <cfg>-info_msg    = '001'.

      WHEN 'DFLT_GLOBAL_VERSION'.
        <cfg>-info_msg    = '002'.
      WHEN 'DFLT_LIGT_COLOR'.
        <cfg>-info_msg    = '003'.
      WHEN 'DFLT_LOCAL_SOD'.
        <cfg>-info_msg    = '004'.
      WHEN 'DFLT_INCLUDE_ER'.
        <cfg>-info_msg    = '047'.
      WHEN 'DFLT_LOCAL_USR'.
        <cfg>-info_msg    = '005'.
      WHEN 'DFLT_SHO_MIT_CONS'.
        <cfg>-info_msg    = '007'.
      WHEN 'DFLT_SHO_NO_SOD'.
        <cfg>-info_msg    = '008'.
      WHEN 'REP_USR_LOK_DSP_MGR'.
        <cfg>-info_msg    = '014'.
      WHEN 'SW_054_REMOTE'.
        <cfg>-info_msg    = '018'.
      WHEN 'SW_ENH_LOCAL_FILT'.
        <cfg>-info_msg    = '022'.
      WHEN 'SW_MIT_REMIND_EMAIL'.
        <cfg>-info_msg    = '048'.
      WHEN 'SW_ENH_SCAN_TBL'.
        <cfg>-info_msg    = '023'.
      WHEN 'HIDE_ORG_ANALYSIS'.
        <cfg>-info_msg    = '025'.
      WHEN 'SW_MGMT_REPORTING'.
        <cfg>-info_msg    = '030'.
      WHEN 'SW_REMOTE_MITIGATION'.
        <cfg>-info_msg    = '033'.
      WHEN 'MIT_AUDT_HDR_LIST'.
        <cfg>-info_msg    = '037'.
      WHEN 'MIT_VALID_FOR_CON'.
        <cfg>-info_msg    = '060'.
      WHEN 'DFLT_ADVSIM_WILDCARD'.
        <cfg>-info_msg    = '038'.
      WHEN 'DFLT_SHO_SCAN_RSLT'.
        <cfg>-info_msg    = '009'.
      WHEN 'REP_USR_LOK_DSP_SLF'.
        <cfg>-info_msg    = '015'.
      WHEN 'SW_054_CROSS'.
        <cfg>-info_msg    = '016'.
      WHEN 'SW_054_LOCAL'.
        <cfg>-info_msg    = '017'.
      WHEN 'DFLT_MAX_USER_SCAN'.
        <cfg>-info_msg    = '006'.
      WHEN 'FM_MAP_USER'.
        <cfg>-info_msg    = '012'.
      WHEN 'SW_COMPANY_SHLP_FM'.
        <cfg>-info_msg    = '027'.
      WHEN 'SW_MGMT_COMPANY_FM'.
        <cfg>-info_msg    = '028'.
      WHEN 'SW_MGMT_DEPARTMENT_F'.
        <cfg>-info_msg    = '029'.
      WHEN 'MIT_APRV_EQ_USR_MSG'.
        <cfg>-info_msg    = '035'.
      WHEN 'MIT_AUDT_EQ_USR_MSG'.
        <cfg>-info_msg    = '036'.
      WHEN 'SW_CENTRAL_USR_FM'.
        <cfg>-info_msg    = '040'.
      WHEN 'SW_DEPART_SHLP_FM'.
        <cfg>-info_msg    = '044'.
      WHEN 'SW_MGMT_COMP_NAME_FM'.
        <cfg>-info_msg    = '045'.
      WHEN 'DFLT_UPD_SCAN_TBL'.
        <cfg>-info_msg    = '010'.
      WHEN 'DFLT_VALID_DIALOG'.
        <cfg>-info_msg    = '011'.
      WHEN 'SW_MIT_SIGNOFF_TEXT'.
        <cfg>-info_msg    = '076'.
      WHEN 'SW_MIT_SIGNOFF_EMAIL'.
        <cfg>-info_msg    = '077'.
      WHEN 'MIT_DFLT_REV_TEXT'.
        <cfg>-info_msg    = '078'.
      WHEN 'FIORI_SOD_VERSION'.
        <cfg>-info_msg    = '079'.
      WHEN 'REPEAT_HDR_BKGDJOB'.
        <cfg>-info_msg    = '024'.
      WHEN 'SW_MGMT_VRSIO'.
        <cfg>-info_msg = '031'.
      WHEN'SW_MIT_ASG_NOTIF_OID'.
        <cfg>-info_msg    = '032'.
      WHEN 'SW_REM_ROLE_FILTER'.
        <cfg>-info_msg = '034'.
      WHEN 'SOD_SINGLE_COMPANY'.
        <cfg>-info_msg = '039'.
      WHEN 'SW_LOCAL_SYSTEM_SORT'.
        <cfg>-info_msg = '041'.
      WHEN 'DFLT_CON_MA_EMAIL'.
        <cfg>-info_msg = '042'.
      WHEN 'DFLT_MIT_MA_EMAIL'.
        <cfg>-info_msg = '043'.
      WHEN 'SW_056_RFC_DEST'.
        <cfg>-info_msg = '019'.
      WHEN 'SW_DFLT_RFC_DEST'.
        <cfg>-info_msg = '021'.
      WHEN 'SW_MIT_BY_ROLE'.
        <cfg>-info_msg = '046'.
      WHEN 'SW_MGMT_NUM_WEEKS'.
        <cfg>-info_msg = '049'.
      WHEN 'MIT_ATTACH_URL' .
        <cfg>-info_msg = '050'.
      WHEN 'SW_USR_INACTIV_EMAIL'.
        <cfg>-info_msg = '147'.
*      WHEN 'SCAN_NO_VERIFICATION'.
*        <cfg>-info = '051'.
      WHEN 'SW_PROFILE_CHECK'.
        <cfg>-info_msg = '053'.
      WHEN 'SW_TRP_ADD_CHECK'.
        <cfg>-info_msg = '054'.
      WHEN 'SW_TRP_REL_CHECK'.
        <cfg>-info_msg = '055'.
      WHEN 'SW_TRP_REL_ENFORCE'.
        <cfg>-info_msg = '056'.
      WHEN 'SW_USERSAVE_CHECK'.
        <cfg>-info_msg = '057'.
      WHEN 'DFLT_EXCLUDE_LOCKED'.
        <cfg>-info_msg = '058'.
      WHEN 'DFLT_EXCL_OUT_VALID'.
        <cfg>-info_msg = '059'.
      WHEN 'DFLT_ORG_LEVEL_CHECK'.
        <cfg>-info_msg = '061'.
      WHEN 'ADVSIMU_ORG_FULLAUTH'.
        <cfg>-info_msg = '151'.
      WHEN 'USE_ROLES'.
        <cfg>-info_msg = '062'.
      WHEN '31_26_CROSS_COMPAT'.
        <cfg>-info_msg = '063'.
      WHEN 'SW_ROLES_POS_USRASGN'.
        <cfg>-info_msg = '064'.
      WHEN 'MIT_CON_DEFINED_ONLY'.
        <cfg>-info_msg = '065'.
      WHEN 'MIT_ASGN_AUTH_CHECK'.
        <cfg>-info_msg = '066'.
      WHEN 'DFLT_SHOW_COMPOSITE'.
        <cfg>-info_msg = '067'.
      WHEN 'ROLES_IMP_DERIVED'.
        <cfg>-info_msg = '068'.
      WHEN 'DASHBOARD_ACTIVE'.
        <cfg>-info_msg = '069'.
      WHEN 'DASHBOARD_WIDGET1'.
        <cfg>-info_msg = '070'.
      WHEN 'DASHBOARD_WIDGET2'.
        <cfg>-info_msg = '071'.
      WHEN 'EN_INTEGRATION'.
        <cfg>-info_msg    = '072'.
      WHEN 'ORG_LEVEL'.
        <cfg>-info_msg    = '073'.
      WHEN 'ORG_LVL_RES_MOD'.
        <cfg>-info_msg    = '074'.
      WHEN 'LEVEL3_CHDR_INDEX'.
        <cfg>-info_msg    = '075'.
*--SE4.2
      WHEN 'DFLT_ENHANCE_MATRIX'.
        <cfg>-info_msg    = '091'.
      WHEN 'DFLT_STORE_RET_DAYS'.
        <cfg>-info_msg   = '092'.
      WHEN 'DFLT_STORE_SOD_DESC'.
        <cfg>-info_msg   = '093'.
      WHEN 'DFLT_STORE_NOCON_USR'.
        <cfg>-info_msg    = '096'.
      WHEN 'SOD_EXPORT_ALV_LIMIT'.
        <cfg>-info_msg   = '094'.
*--SE4.1
      WHEN 'DFLT_VAREL_SKIPVAL'.
        <cfg>-info_msg    = '090'.
      WHEN 'DFLT_VAREL_TEST'.
        <cfg>-info_msg    = '110'.

      WHEN 'ORG_DFLT_BUKRS' OR
           'ORG_DFLT_EKORG' OR
           'ORG_DFLT_WERKS' OR
           'ORG_DFLT_VKORG' OR
           'ORG_DFLT_GSBER' OR
           'ORG_DFLT_SPART' OR
           'ORG_DFLT_VTWEG' OR
           'ORG_DFLT_KKBER' OR
           'ORG_DFLT_IWERK' OR
           'ORG_DFLT_VSTEL'.
        <cfg>-info_msg    = '081'.
      WHEN 'VAR_DFLT_001' OR
           'VAR_DFLT_002' .
        <cfg>-info_msg    = '082'.
      WHEN 'VAR_DFLT_003' OR
           'VAR_DFLT_004' OR
           'VAR_DFLT_005' OR
           'VAR_DFLT_006' OR
           'VAR_DFLT_007' OR
           'VAR_DFLT_008' OR
           'VAR_DFLT_009' OR
           'VAR_DFLT_010' .
        <cfg>-info_msg    = '082'.
      WHEN 'CFG_SET_ENABLED'.
        <cfg>-info_msg    = '083'.
      WHEN 'CFG_SET_PUBLISHEVENT'.
        <cfg>-info_msg    = '084'.
      WHEN 'ORG_DET_HIER'.
        <cfg>-info_msg    = '085'.
      WHEN 'ORG_VAL_FABKL'.
        <cfg>-info_msg    = '086'.
      WHEN 'DFLT_VAREL_VERSION'.
        <cfg>-info_msg    = '087'.
      WHEN 'CFG_SET_HIDE_ABB'.
        <cfg>-info_msg    = '088'.
      WHEN 'CFG_SET_ORG_SHOW_TOT'.
        <cfg>-info_msg    = '089'.
      WHEN 'CFG_SET_AUTOPARSE'.
        <cfg>-info_msg    = '095'.
      WHEN 'ORG_LVL_OVERRIDE'.
        <cfg>-info_msg    = '097'.
      WHEN 'APILOG_GENERAL_INFO'.
        <cfg>-info_msg    = '098'.
      WHEN 'APILOG_ANALYSIS_RES'.
        <cfg>-info_msg    = '099'.
      WHEN 'APILOG_CONFLICT_LIST'.
        <cfg>-info_msg    = '100'.
      WHEN 'APILOG_SOD_BY_ROLE'.
        <cfg>-info_msg    = '101'.
      WHEN 'APILOG_SOD_BY_USER'.
        <cfg>-info_msg    = '102'.
      WHEN 'TA_ROLE_EFF'.
        <cfg>-info_msg    = '103'.
      WHEN 'TA_DISPLAY_HISTORY'.
        <cfg>-info_msg    = '104'.
      WHEN 'CFG_SET_HIGHLIGHT'.
        <cfg>-info_msg    = '105'.
      WHEN 'CFG_SET_SHOW_DFLT'.
        <cfg>-info_msg    = '106'.
      WHEN 'DFLT_STOR_DET_BTCH'.
        <cfg>-info_msg    = '107'.
      WHEN 'DFLT_STOR_SUM_BTCH'.
        <cfg>-info_msg    = '108'.
      WHEN 'DFLT_STOR_SUM_PAR'.
        <cfg>-info_msg    = '109'.
      WHEN 'SW_ENH_BUFFER'.
        <cfg>-info_msg    = '111'.
      WHEN 'SW_ENH_BUFFER_DAYS'.
        <cfg>-info_msg    = '112'.
      WHEN 'CFGGSET_COMP_EMAIL'.
        <cfg>-info_msg    = '113'.
      WHEN 'CFGGSET_COMP_ADDR'.
        <cfg>-info_msg    = '114'.
      WHEN 'APILOG_CONFLICT_DET'.
        <cfg>-info_msg    = '115'.
      WHEN 'APILOG_CONFIG_SET'.
        <cfg>-info_msg    = '116'.
      WHEN 'APILOG_SOD_BY_REFROL'.
        <cfg>-info_msg   = '117'.
      WHEN 'SW_CSS_EMAIL'.
        <cfg>-info_msg    = '119'.
      WHEN 'APILOG_SODREFROLCOMB'.
        <cfg>-info_msg    = '118'.
      WHEN 'APILOG_SOD_BY_USER_R'.
        <cfg>-info_msg    = '121'.
      WHEN 'DFLT_ST_ROL_RET_DAYS'.
        <cfg>-info_msg   = '122'.
      WHEN 'DFLT_ST_ROL_SOD_DESC'.
        <cfg>-info_msg   = '123'.
      WHEN 'DFLT_ST_ROL_DET_BTCH'.
        <cfg>-info_msg   = '124'.
      WHEN 'DFLT_ST_ROL_SUM_BTCH'.
        <cfg>-info_msg   = '125'.
      WHEN 'DFLT_STORE_NOCON_ROL'.
        <cfg>-info_msg   = '126'.
      WHEN 'FIORI_SOD_KPI_A_PAT'.
        <cfg>-info_msg   = '127'.
      WHEN 'FIORI_SOD_KPI_A_LBL'.
        <cfg>-info_msg   = '128'.
      WHEN 'FIORI_SOD_KPI_B_PAT'.
        <cfg>-info_msg   = '129'.
      WHEN 'FIORI_SOD_KPI_B_LBL'.
        <cfg>-info_msg   = '130'.
      WHEN 'DFLT_USER_COMP_VIEW'.
        <cfg>-info_msg   = '131'.
      WHEN 'DET_SOD_BATCH_SIZE'.
        <cfg>-info_msg   = '132'.
      WHEN 'DFLT_ROLE_COMP_VIEW'.
        <cfg>-info_msg   = '134'.
      WHEN 'CFG_SET_EXACT_MATCH'.
        <cfg>-info_msg   = '135'.
      WHEN 'DFLT_STORE_R_DAYS_S'.
        <cfg>-info_msg   = '136'.
      WHEN 'DFLT_STORE_R_DAYS_D'.
        <cfg>-info_msg   = '137'.
      WHEN 'DFLT_ST_RORET_DAYS_S'.
        <cfg>-info_msg   = '138'.
      WHEN 'DFLT_ST_RORET_DAYS_D'.
        <cfg>-info_msg   = '139'.
      WHEN 'APPROVAL_CENTRAL_SYS'.
        <cfg>-info_msg   = '133'.
      WHEN 'AUTHCOMP_BUFFERSIZE'.
        <cfg>-info_msg   = '140'.
      WHEN 'SW_INTEGRATION_VRSIO'.
        <cfg>-info_msg   = '141'.
      WHEN 'SCAN_NO_VERIFICATION'.
        <cfg>-info_msg   = '142'.
      WHEN 'SE_CENTRAL_RFC'.
        <cfg>-info_msg   = '143'.
      WHEN 'MIT_BY_ORG'. "C0295 SE4.5PS3
        <cfg>-info_msg   = '144'.
*----C0634 SE4.6
      WHEN 'DFLT_INACT_LOCK'.
        <cfg>-info_msg   = '026'.
      WHEN 'DFLT_INACT_EXP'.
        <cfg>-info_msg   = '145'.
      WHEN 'DFLT_INACT_DEL'.
        <cfg>-info_msg   = '146'.
*      when 'SW_USR_INACTIV_EMAIL'.
*       <cfg>-info_msg    = '147'.
* BOC for C0766
      WHEN 'CONSIDER_ORG_AREA'.
        <cfg>-info_msg = '148'.
*--C0788
      WHEN 'CFG_SET_DIST_REST'.
        <cfg>-info_msg = '149'.

      WHEN 'MIT_DEL_EXPIRE_ONLY'.
        <cfg>-info_msg = '150'.

* EOC for C0766

*BOC C1159 CGUPTA 20/09/2023

      WHEN 'MIT_ASGN_NOTIFY_DAYS'.
        <cfg>-info_msg = '152'.
      WHEN 'SW_MIT_EXPIRE_EMAIL'.
        <cfg>-info_msg = '152'.

*EOC C1159 CGUPTA 20/09/2023

*BOC AKUMAR SE ABAC
      WHEN 'SE_ABAC_INTEGRATION'.
        <cfg>-info_msg = '153'.
*EOC AKUMAR SE ABAC
        when 'SOD_REV_USR_MAPPING'.
          <cfg>-info_msg = '154'.
       when 'DFLT_TCOD_VALIDATION'.
       <cfg>-info_msg ='155'.

       When 'USR_PARAM_FIELD_NAME'.
         <cfg>-info_msg = '156'.

*BOC AKUMAR OPL645
       when 'CONSIDER_ORG_FIELD'.
       <cfg>-info_msg ='157'.
*EOC AKUMAR OPL645

*BOC UMITTAL SE-CAC Integration
       WHEN 'SE_CAC_INTEGRATION'.
         <cfg>-info_msg ='158'.
*EOC UMITTAL SE-CAC Integration
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " add_param_info
