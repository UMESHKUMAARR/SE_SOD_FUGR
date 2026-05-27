*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_SOD_BY_ROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_sod_by_role.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BATCH_ID) TYPE  /PSYNG/BATCH_ID OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  FLAG OPTIONAL
*"     VALUE(I_ABAP) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_NOABAP) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SW_SOD_REMOTE_ROLES
*"      IT_EN_ROLES STRUCTURE  /PSYNG/EN_ROLE_ADDITION_SIMU OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_ORGLVL STRUCTURE  /PSYNG/RANGE_DORG_ABB OPTIONAL
*"----------------------------------------------------------------------
*Call the implementation of this API
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
  CALL FUNCTION '/PSYNG/SW_API_I_SOD_BY_ROLE'
       EXPORTING
            request_id    = request_id
            batch_id      = batch_id
            vrsio         = vrsio
            if_def_vrsio  = if_def_vrsio
            config_set    = config_set
            if_def_conf   = if_def_conf
            i_abap        = i_abap
            i_noabap      = i_noabap
            if_org_check  = if_org_check
            logging_flag  = logging_flag
            if_local      = if_local
       IMPORTING
            es_sod_matrix = es_sod_matrix
            es_config_set = es_config_set
            return        = return
       TABLES
            roles         = roles
            it_en_roles   = it_en_roles
            it_conid      = it_conid
            it_imp        = it_imp
            it_systems    = it_systems
            et_output     = et_output
            et_return     = et_return
            it_orglvl     = it_orglvl.

  exelog_api '/PSYNG/SW_API_SOD_BY_ROLE' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)


ENDFUNCTION.
