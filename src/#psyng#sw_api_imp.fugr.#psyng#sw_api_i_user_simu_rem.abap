*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_SOD_BY_USER_N_SIMU
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_user_simu_rem.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BNAME) LIKE  USR02-BNAME OPTIONAL
*"     VALUE(XMC_FM) TYPE  CHAR1 OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  FLAG OPTIONAL
*"     VALUE(I_ENHANC) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_ABAP) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_NOABAP) TYPE  FLAG OPTIONAL
*"     VALUE(I_ROLE_DETAILS) TYPE  FLAG OPTIONAL
*"     VALUE(I_SHOWCOMP) TYPE  FLAG DEFAULT ''
*"     VALUE(I_VALIDUSER) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_EXLCKUSR) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_EXOUTVAL) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(I_LOCUSR) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_REMOTE_ONLY) TYPE  FLAG DEFAULT ''
*"     VALUE(I_CALLING_FM) TYPE  FUNCNAME OPTIONAL
*"     VALUE(IF_SIMU_BEFORE_AFTER) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SW_SOD_REMOTE_ROLES OPTIONAL
*"      1STOUTPUT_FM STRUCTURE  /PSYNG/1STOUTPUT_U OPTIONAL
*"      ET_SIMU_RESULTS STRUCTURE  /PSYNG/SW_API_SOD_USER_SIMU OPTIONAL
*"      IT_EN_ROLES STRUCTURE  /PSYNG/EN_ROLE_ADDITION_SIMU OPTIONAL
*"      IT_APPL STRUCTURE  /PSYNG/RANGE_APPL OPTIONAL
*"      IT_SYSID STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      ET_OUTPUTDET STRUCTURE  /PSYNG/SW_OUTPUTDET3 OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_USER_RFC STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"      IT_SIMU_ROLE_ADDITION STRUCTURE  /PSYNG/SW_ROLE_ADDITION_SIMU
*"       OPTIONAL
*"      IT_BNAMES STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"----------------------------------------------------------------------

*--> BOC PN 11269 - ATC fixes - HBHALLA - 21/01/25
  CONSTANTS: lc_fname TYPE rs38l_fnam
  VALUE '/PSYNG/SW_API_I_USER_SIMU_REM'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e089(/psyng/sw) WITH lc_fname.
  ENDIF.

*--> EOC PN 11269 - ATC fixes - HBHALLA - 21/01/25

  DATA : lt_users      TYPE TABLE OF /psyng/sw_sel_opts_xubname
                      WITH HEADER LINE,
         lt_return     TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         lt_res        TYPE TABLE OF /psyng/sw_sod_output_org
                      WITH HEADER LINE,
         lt_simu_after TYPE TABLE OF /psyng/sw_api_sod_user_simu
                      WITH HEADER LINE,
        lt_conid      TYPE TABLE OF /psyng/range_conid WITH HEADER LINE,
        l_start_date  TYPE dats,
        l_start_time  TYPE tims,
        l_logging     TYPE flag,
        l_results     TYPE int4,
        l_object      TYPE /psyng/longtext,
        lf_continue   TYPE flag,
        l_timestamp   TYPE timestampl,
        lf_local      TYPE flag,
        lt_rpoug_fail TYPE TABLE OF /psyng/sw_uinfo,"RGUPTA on 08Mar22
        ls_return    TYPE bapireturn, "RGUPTA on 08Mar22
  l_org_field TYPE flag, "OPL645
        swconfig TYPE /psyng/swconfig."OPL645
  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME   FIELD g_start.

  FIELD-SYMBOLS :
    <detail> TYPE /psyng/sw_outputdet3,
    <simu>   TYPE /psyng/sw_api_sod_user_simu.
* BOC by RGUPTA for C0743
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
     ID 'ACTVT' FIELD '03'
     ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
    ls_return-type = 'E'.
    ls_return-message
     = 'You are not authorized to analyze the results'(002).
    APPEND ls_return TO et_return.
    CLEAR ls_return.
    EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  lf_continue = 'X'.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
  FREE : lt_users,lt_res,lt_return,1stoutput_fm.
  lt_users-sign   = 'I'.
  lt_users-option = 'EQ'.
  lt_users-low    = bname. "Required
  APPEND lt_users.
  APPEND LINES OF it_bnames TO lt_users.
  SORT lt_users.
  DELETE ADJACENT DUPLICATES FROM lt_users.
  lf_continue = 'X'.
*--Import parameter Validation
  IF i_remote_only IS INITIAL.
    lf_local = 'X'.
  ENDIF.
  PERFORM api_validate_input
  TABLES
      lt_return
      it_user_rfc
    USING
      if_def_vrsio
      if_def_conf
      lf_local
    CHANGING
      vrsio
      config_set
      es_config_set
      es_sod_matrix
      lf_continue.

  IF lf_continue = 'X'.
*--Validate the Roles
    PERFORM api_validate_roles
      TABLES roles
             lt_return
      CHANGING
             lf_continue.
*--Move simulated roles to correct structure
    LOOP AT roles.
      it_simu_role_addition-source_rfcdest = roles-rfcdest.
      CLEAR it_simu_role_addition-target_rfcdest.
      it_simu_role_addition-sign           = 'I'.
      it_simu_role_addition-option         = 'EQ'.
      it_simu_role_addition-low            = roles-agr_name.
      CLEAR it_simu_role_addition-high.
      APPEND it_simu_role_addition.
    ENDLOOP.

*--BOC AKUMAR OPL645
*--Consider org field
    CLEAR swconfig.
    se_config_param 'CONSIDER_ORG_FIELD' swconfig-value.
    IF swconfig-value = 'Y'.
      l_org_field = 'X'.
    ELSEIF swconfig-value = 'N'.
      l_org_field = ' '.
    ENDIF.
    CLEAR swconfig.
*--EOC AKUMAR OPL645

*--Execute a Before Simulation analysis if requested and return results in ET_SIMU_RESULTS
    IF if_simu_before_after  = 'X'.
      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
        EXPORTING
          i_vrsio            = vrsio
          i_config_set       = config_set
          i_enh              = i_enhanc
          i_analyze_sap_all  = 'X'
          i_shomit           = xmc_fm
          i_abap             = i_abap
          i_nonabap          = i_noabap
          i_validuser        = i_validuser
          i_exlckusr         = i_exlckusr
          i_outvdate         = i_exoutval
          i_org_check        = if_org_check
          i_locusr           = i_locusr
          i_remote_only      = i_remote_only
          i_org_field        = l_org_field "OPL645
        TABLES
          it_users           = lt_users
          it_confs           = it_conid
          it_appl            = it_appl
          it_sysid           = it_sysid
          it_user_rfc        = it_user_rfc
          et_outputdet       = lt_res
          et_return          = lt_return
          et_rpoug_auth_fail = lt_rpoug_fail.
      LOOP AT lt_res WHERE imp IN it_imp.
        MOVE-CORRESPONDING lt_res TO et_simu_results.
        et_simu_results-description = lt_res-condesc.
        et_simu_results-before_simu = 'X'.
        APPEND et_simu_results.
      ENDLOOP.
      SORT et_simu_results BY bname conid.
    ENDIF.
*--Summary SOD Analysis
    CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      EXPORTING
        i_vrsio               = vrsio
        i_config_set          = config_set
        i_enh                 = i_enhanc
        i_analyze_sap_all     = 'X'
        i_shomit              = xmc_fm
        i_abap                = i_abap
        i_nonabap             = i_noabap
        i_validuser           = i_validuser
        i_exlckusr            = i_exlckusr
        i_outvdate            = i_exoutval
        i_org_check           = if_org_check
        i_locusr              = i_locusr
        i_remote_only         = i_remote_only
        i_org_field        = l_org_field "OPL645
      TABLES
        it_en_roles           = it_en_roles
*       it_simu_role_rfc      = roles
        it_simu_role_addition = it_simu_role_addition
        it_users              = lt_users
        it_confs              = it_conid
        it_appl               = it_appl
        it_sysid              = it_sysid
        it_user_rfc           = it_user_rfc
        et_outputdet          = lt_res
        et_return             = lt_return
        et_rpoug_auth_fail    = lt_rpoug_fail.
    LOOP AT lt_res WHERE imp IN it_imp.
      MOVE-CORRESPONDING lt_res TO 1stoutput_fm.
      1stoutput_fm-description = lt_res-condesc.
      APPEND 1stoutput_fm.
      IF if_simu_before_after  = 'X'.
        READ TABLE et_simu_results WITH KEY bname = lt_res-bname
                                            conid = lt_res-conid
                                   BINARY SEARCH
                                   ASSIGNING <simu>.
        IF sy-subrc = 0.
          <simu>-after_simu = 'X'.
        ELSE.
          MOVE-CORRESPONDING lt_res TO lt_simu_after.
          lt_simu_after-description = lt_res-condesc.
          lt_simu_after-after_simu = 'X'.
          APPEND lt_simu_after.
        ENDIF.
      ENDIF.
    ENDLOOP.
    IF if_simu_before_after  = 'X'.
      APPEND LINES OF lt_simu_after TO et_simu_results.
      SORT et_simu_results.
    ENDIF.
* BOC by RGUPTA on 8th March 22
    IF lt_rpoug_fail[] IS NOT INITIAL.
      ls_return-type = 'E'.
      ls_return-message = 'Authority check Y&SW_RPOUG failed'(e01).
      APPEND ls_return TO et_return[].
    ENDIF.
* EOC by RGUPTA on 8th March 22
*-- Detailed SOD Analysis to identify roles causing the Conflict
    IF i_role_details = 'X'.
      LOOP AT lt_res.
        lt_conid-sign   = 'I'.
        lt_conid-option = 'EQ'.
        lt_conid-low    = lt_res-conid.
        COLLECT lt_conid.
      ENDLOOP.
*      CHECK NOT lt_conid[] IS INITIAL.
      IF NOT lt_conid[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_081'
          EXPORTING
            i_byuser              = 'X'
            i_bysimu              = 'X'
            i_nonabap             = i_noabap
            i_abap                = i_abap
            i_sodvrsio            = vrsio
            i_config_set          = config_set
            i_showcomp            = i_showcomp
            i_enhanc              = i_enhanc
            i_xmc                 = xmc_fm
*the summary already confirmed the orgs between the functions match
*           i_orgchk              = if_org_check
            i_noprin              = 'X'
            i_locusr              = i_locusr
            i_remote_only         = i_remote_only
             i_org_field        = l_org_field "OPL645
          TABLES
            it_en_roles           = it_en_roles
            it_appl               = it_appl
            it_sysid              = it_sysid
            it_bname              = lt_users
            it_sens               = it_imp
            it_conflicts          = lt_conid
            et_outputdet          = et_outputdet
            it_simu_role_addition = it_simu_role_addition
            it_rfcdest            = it_user_rfc
          EXCEPTIONS
            user_cancelled        = 1
            OTHERS                = 2.
        IF sy-subrc = 0.
*--Remove all details not related to Roles
          SORT et_outputdet
            BY bname conid functionid agr_name comp_agr.
          DELETE ADJACENT DUPLICATES FROM et_outputdet
            COMPARING bname conid functionid agr_name comp_agr.
          LOOP AT et_outputdet ASSIGNING <detail>.
            CLEAR: <detail>-org_abb,
                   <detail>-tcode,
                   <detail>-objct,
                   <detail>-auth,
                   <detail>-field,
                   <detail>-von,
                   <detail>-bis,
                   <detail>-profile,
                   <detail>-comp_prof,
                   <detail>-simu,
                   <detail>-enhanced,
                   <detail>-er,
                   <detail>-exe_user,
                   <detail>-exe_role,
                   <detail>-exe_der.
            IF it_user_rfc[] IS INITIAL.
              CLEAR : <detail>-rfcdest.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
*--Prepare the return messages
  CALL FUNCTION '/PSYNG/SW_API_I_HANDLE_ERROR'
    IMPORTING
      es_return = return
    TABLES
      it_return = lt_return
      et_return = et_return.

*--Log this interface call
  IF logging_flag = 'X'
  OR logging_flag = '1'.
*--Get logging configuration
    IF i_calling_fm IS INITIAL.
      i_calling_fm = '/PSYNG/SW_SOD_BY_USER_N_SIMU'.
    ENDIF.
    CASE i_calling_fm.
      WHEN '/PSYNG/SW_SOD_BY_USER_N_SIMU'.
        se_config_param 'APILOG_SOD_BY_USER' l_logging.
      WHEN '/PSYNG/SW_API_USER_SIMU_REM'.
        se_config_param 'APILOG_SOD_BY_USER_R' l_logging.
    ENDCASE.
    IF l_logging = 'Y'.
      DESCRIBE TABLE 1stoutput_fm LINES l_results.
      l_object = bname.

      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              ''              " Blank batch ID
              i_calling_fm
              l_results
              return
              l_object
              l_timestamp.
    ENDIF.
  ENDIF.
*--Commit work to trigger update task FM
  COMMIT WORK.

ENDFUNCTION.
