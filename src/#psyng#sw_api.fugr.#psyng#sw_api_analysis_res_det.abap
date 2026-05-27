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
FUNCTION /psyng/sw_api_analysis_res_det .
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
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_OUTPUTDET STRUCTURE  /PSYNG/SW_OUTPUTDET_1 OPTIONAL
*"----------------------------------------------------------------------

  DATA: ls_return        TYPE bapireturn,
        lt_outputdet_n   TYPE TABLE OF /psyng/sw_outputdet,
        ls_outputdet_n   TYPE          /psyng/sw_outputdet.
*        lt_outputdet_ext TYPE TABLE OF /psyng/sw_outputdet_ext,
*        ls_outputdet_ext TYPE          /psyng/sw_outputdet_ext.
*-----------------------------------------------------------------------

*-----------------------AUTHORITY-CHECK---------------------------------
*-----------------------------------------------------------------------
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


*  CALL FUNCTION '/PSYNG/SW_API_I_ANALY_RES_DET'
*       EXPORTING
*            request_id           = request_id
*            batch_id             = batch_id
*            analysis_run         = analysis_run
*            if_def_run           = if_def_run
*            logging_flag         = logging_flag
*            if_direct_assn_only  = if_direct_assn_only
*            if_exclude_mitigated = if_exclude_mitigated
*            if_local             = if_local
*       IMPORTING
*            e_analysis_run       = e_analysis_run
*            es_sod_matrix        = es_sod_matrix
*            es_config_set        = es_config_set
*            return               = return
*       TABLES
*            users                = users
*            et_users             = et_users
*            et_return            = et_return
*            it_systems           = it_systems
*            et_outputdet_n       = lt_outputdet_n.


  CALL FUNCTION '/PSYNG/SW_API_ANALY_RES_DET_OP'
    EXPORTING
      request_id           = request_id
      batch_id             = batch_id
      analysis_run         = analysis_run
      if_def_run           = if_def_run
      logging_flag         = logging_flag
      if_direct_assn_only  = if_direct_assn_only
      if_exclude_mitigated = if_exclude_mitigated
      if_local             = if_local
    IMPORTING
      e_analysis_run       = e_analysis_run
      es_sod_matrix        = es_sod_matrix
      es_config_set        = es_config_set
      return               = return
    TABLES
      users                = users
      et_users             = et_users
      et_return            = et_return
      it_systems           = it_systems
      et_outputdet_n       = lt_outputdet_n.
*      et_outputdet_ext     = lt_outputdet_ext.


  LOOP AT lt_outputdet_n INTO ls_outputdet_n.
    MOVE-CORRESPONDING ls_outputdet_n TO et_outputdet.
    APPEND et_outputdet.
  ENDLOOP.


*  LOOP AT lt_outputdet_ext INTO ls_outputdet_ext.
*    MOVE-CORRESPONDING ls_outputdet_ext TO et_outputdet_ext.
*    APPEND et_outputdet_ext.
*  ENDLOOP.
*  exelog_api '/PSYNG/SW_API_I_ANALY_RES_DET' ''. "#EC SAST_CI_GEN_CHECK
  exelog_api '/PSYNG/SW_API_ANALY_RES_DET_OP' ''. "#EC SAST_CI_GEN_CHECK
ENDFUNCTION.
