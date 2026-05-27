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
FUNCTION /psyng/sw_sod_by_user_n_simu.
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
*"     VALUE(IF_SIMU_BEFORE_AFTER) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SW_SOD_REMOTE_ROLES
*"      1STOUTPUT_FM STRUCTURE  /PSYNG/1STOUTPUT_U OPTIONAL
*"      ET_SIMU_RESULTS STRUCTURE  /PSYNG/SW_API_SOD_USER_SIMU OPTIONAL
*"      IT_EN_ROLES STRUCTURE  /PSYNG/EN_ROLE_ADDITION_SIMU OPTIONAL
*"      IT_APPL STRUCTURE  /PSYNG/RANGE_APPL OPTIONAL
*"      IT_SYSID STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      ET_OUTPUTDET STRUCTURE  /PSYNG/SW_OUTPUTDET3 OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_BNAMES STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_BY_USER_N_SIMU'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

*Call the implementation of this API
  CALL FUNCTION '/PSYNG/SW_API_I_USER_SIMU_REM'
    EXPORTING
      request_id           = request_id
      bname                = bname
      xmc_fm               = xmc_fm
      vrsio                = vrsio
      if_def_vrsio         = if_def_vrsio
      config_set           = config_set
      if_def_conf          = if_def_conf
      i_enhanc             = i_enhanc
      i_abap               = i_abap
      i_noabap             = i_noabap
      i_role_details       = i_role_details
      i_showcomp           = i_showcomp
      i_validuser          = i_validuser
      i_exlckusr           = i_exlckusr
      i_exoutval           = i_exoutval
      if_org_check         = if_org_check
      logging_flag         = logging_flag
      i_calling_fm         = '/PSYNG/SW_SOD_BY_USER_N_SIMU'
      if_simu_before_after = if_simu_before_after
    IMPORTING
      return               = return
      es_config_set        = es_config_set
      es_sod_matrix        = es_sod_matrix
    TABLES
      roles                = roles
      1stoutput_fm         = 1stoutput_fm
      et_simu_results      = et_simu_results
      it_en_roles          = it_en_roles
      it_appl              = it_appl
      it_sysid             = it_sysid
      et_outputdet         = et_outputdet
      it_conid             = it_conid
      it_imp               = it_imp
      it_bnames            = it_bnames
      et_return            = et_return.
*--Log the execution of the API
  DATA : l_log_type TYPE /psyng/text30.
  IF i_role_details = 'X'.
    l_log_type = 'Detail'.
  ELSE.
    l_log_type = 'Summary'.
  ENDIF.
  IF if_simu_before_after = 'X'.
    CONCATENATE l_log_type  '-Before/After' INTO l_log_type SEPARATED BY space.
  ENDIF.
  exelog_api '/PSYNG/SW_SOD_BY_USER_N_SIMU' l_log_type.

ENDFUNCTION.
