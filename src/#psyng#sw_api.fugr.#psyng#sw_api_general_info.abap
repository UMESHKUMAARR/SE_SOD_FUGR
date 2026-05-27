*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_GENERAL_INFO
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_general_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ALL_VERSIONS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_ALL_RUNS) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(SYS_ID) TYPE  SYSYSID
*"     VALUE(SYS_CLIENT) TYPE  SYMANDT
*"     VALUE(SYS_INST_NR) TYPE  CHAR10
*"     VALUE(SE_VRSIO) TYPE  /PSYNG/PROG_VRSIO
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ANALYSIS_RUN) TYPE  /PSYNG/SERESID
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      ET_SWSODVERS STRUCTURE  /PSYNG/SWSODVERS OPTIONAL
*"      ET_CONFIG_SET STRUCTURE  /PSYNG/SWCFGSET OPTIONAL
*"      ET_SET_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_RESHDR STRUCTURE  /PSYNG/SWRESHDR OPTIONAL
*"      ET_RES_SYSTEMS STRUCTURE  /PSYNG/SWRESISYS OPTIONAL
*"----------------------------------------------------------------------
*Call the implementation of this API
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message
   = 'You are not authorized to analyze the results'(001).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_CFGST'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_SETID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message
   = 'You are not authorized to analyze the results'(001).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  CALL FUNCTION '/PSYNG/SW_API_I_GENERAL_INFO'
    EXPORTING
      request_id      = request_id
      logging_flag    = logging_flag
      if_all_versions = if_all_versions
      if_local        = if_local
      if_all_runs     = if_all_runs
    IMPORTING
      sys_id          = sys_id
      sys_client      = sys_client "#EC SAST_CI_GEN_CHECK
      sys_inst_nr     = sys_inst_nr
      se_vrsio        = se_vrsio
      es_sod_matrix   = es_sod_matrix
      es_config_set   = es_config_set
      analysis_run    = analysis_run
      return          = return
    TABLES
      et_return       = et_return
      et_swsodvers    = et_swsodvers
      et_config_set   = et_config_set
      et_set_systems  = et_set_systems
      it_systems      = it_systems
      et_reshdr       = et_reshdr
      et_res_systems  = et_res_systems.

  exelog_api '/PSYNG/SW_API_GENERAL_INFO' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)
ENDFUNCTION.
