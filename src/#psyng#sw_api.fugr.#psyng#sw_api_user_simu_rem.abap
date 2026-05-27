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
FUNCTION /psyng/sw_api_user_simu_rem.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BNAME) LIKE  USR02-BNAME
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
*"     VALUE(IF_SIMU_BEFORE_AFTER) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"  TABLES
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
*"----------------------------------------------------------------------
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message
   = 'You are not authorized to analyze the results'(001).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
*Call the implementation of this API
  CALL FUNCTION '/PSYNG/SW_API_I_USER_SIMU_REM'
       EXPORTING
            request_id     = request_id
            bname          = bname
            xmc_fm         = xmc_fm
            vrsio          = vrsio
            if_def_vrsio   = if_def_vrsio
            config_set     = config_set
            if_def_conf    = if_def_conf
            i_enhanc       = i_enhanc
            i_abap         = i_abap
            i_noabap       = i_noabap
            i_role_details = i_role_details
            i_showcomp     = i_showcomp
            i_validuser    = i_validuser
            i_exlckusr     = i_exlckusr
            i_exoutval     = i_exoutval
            if_org_check   = if_org_check
            logging_flag   = logging_flag
            i_locusr       = i_locusr
            i_remote_only  = i_remote_only
            I_CALLING_FM   = '/PSYNG/SW_API_USER_SIMU_REM'
            IF_SIMU_BEFORE_AFTER = IF_SIMU_BEFORE_AFTER
       IMPORTING
            return         = return
            es_config_set  = es_config_set
            es_sod_matrix  = es_sod_matrix
       TABLES
            IT_SIMU_ROLE_ADDITION = IT_SIMU_ROLE_ADDITION
            1stoutput_fm          = 1stoutput_fm
            ET_SIMU_RESULTS       = ET_SIMU_RESULTS
            it_en_roles           = it_en_roles
            it_appl               = it_appl
            it_sysid              = it_sysid
            et_outputdet          = et_outputdet
            it_conid              = it_conid
            it_imp                = it_imp
            et_return             = et_return
            it_user_rfc           = it_user_rfc.

  exelog_api '/PSYNG/SW_API_USER_SIMU_REM' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)
ENDFUNCTION.
