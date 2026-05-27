*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_SOD_BY_ROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_sodrefrolcombo.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BATCH_ID) TYPE  /PSYNG/BATCH_ID OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_FUNCTION_DETAILS) TYPE  FLAG DEFAULT ''
*"     VALUE(I_CON_DET) TYPE  FLAG OPTIONAL
*"     VALUE(I_CON_SUM) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SE_ROLE_REF OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_OUTPUT_DET STRUCTURE  /PSYNG/SW_OUTPUTDET3 OPTIONAL
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
  CALL FUNCTION '/PSYNG/SW_API_I_SODREFROLCOMBO'
       EXPORTING
            request_id    = request_id
            batch_id      = batch_id
            vrsio         = vrsio
            if_def_vrsio  = if_def_vrsio
            config_set    = config_set
            if_def_conf   = if_def_conf
            if_org_check  = if_org_check
            logging_flag  = logging_flag
            if_local      = if_local
*BOC UMITTAL : PN12771 : Show Function ID : OPL 645
            i_function_details = i_function_details
*EOC UMITTAL : PN12771 : Show Function ID : OPL 645
            i_con_det     = i_con_det "AKUMAR++ PN-15676
            i_con_sum     = i_con_sum "AKUMAR++ PN-15676
       IMPORTING
            es_sod_matrix = es_sod_matrix
            es_config_set = es_config_set
            return        = return
       TABLES
            roles         = roles
            et_output     = et_output
            et_return     = et_return
            it_systems    = it_systems
            et_output_det = et_output_det.

  exelog_api '/PSYNG/SW_API_SODREFROLCOMBO' ''.  "#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)
ENDFUNCTION.
