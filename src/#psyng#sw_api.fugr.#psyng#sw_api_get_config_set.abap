FUNCTION /psyng/sw_api_get_config_set.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  /PSYNG/BAPIFLAGX DEFAULT 'X'
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_INACTIVE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(ES_SET) TYPE  /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(RETURN) TYPE  BAPIRETURN
*"  TABLES
*"      ET_VAREL STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"      ET_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_ORG STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"----------------------------------------------------------------------
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
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
  CALL FUNCTION '/PSYNG/SW_API_I_GET_CONFIG_SET'
       EXPORTING
            request_id    = request_id
            logging_flag  = logging_flag
            config_set    = config_set
            if_def_conf   = if_def_conf
            vrsio         = vrsio
            if_def_vrsio  = if_def_vrsio
            if_inactive   = if_inactive
            if_local      = if_local
       IMPORTING
            es_set        = es_set
            es_sod_matrix = es_sod_matrix
            return        = return
       TABLES
            IT_SYSTEMS    = IT_SYSTEMS
            et_varel      = et_varel
            et_systems    = et_systems
            et_org        = et_org
            et_return     = et_return.
  exelog_api '/PSYNG/SW_API_GET_CONFIG_SET' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)

ENDFUNCTION.
