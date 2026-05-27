*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_ANALYSIS_RES
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_analysis_res .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BATCH_ID) TYPE  /PSYNG/BATCH_ID OPTIONAL
*"     VALUE(ANALYSIS_RUN) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(IF_DEF_RUN) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_DIRECT_ASSN_ONLY) TYPE  FLAG OPTIONAL
*"     VALUE(IF_EXCLUDE_MITIGATED) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(E_ANALYSIS_RUN) TYPE  /PSYNG/SERESID
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      USERS STRUCTURE  /PSYNG/SW_USERLIST OPTIONAL
*"      ET_USERS STRUCTURE  /PSYNG/USERCONCOUNT OPTIONAL
*"      ET_OUTPUTDET STRUCTURE  /PSYNG/OUTPUTDET OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
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
* EOC by RGUPTA for C0743
  CALL FUNCTION '/PSYNG/SW_API_I_ANALYSIS_RES'
       EXPORTING
            request_id           = request_id
            batch_id             = batch_id
            analysis_run         = analysis_run
            if_def_run           = if_def_run
            logging_flag         = logging_flag
            IF_DIRECT_ASSN_ONLY  = IF_DIRECT_ASSN_ONLY
            IF_EXCLUDE_MITIGATED = IF_EXCLUDE_MITIGATED
            IF_LOCAL             = IF_LOCAL
       IMPORTING
            e_analysis_run       = e_analysis_run
            es_sod_matrix        = es_sod_matrix
            es_config_set        = es_config_set
            return               = return
       TABLES
            users                = users
            et_users             = et_users
            et_outputdet         = et_outputdet
            et_return            = et_return
            IT_SYSTEMS           = IT_SYSTEMS.
  exelog_api '/PSYNG/SW_API_ANALYSIS_RES' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)
ENDFUNCTION.
