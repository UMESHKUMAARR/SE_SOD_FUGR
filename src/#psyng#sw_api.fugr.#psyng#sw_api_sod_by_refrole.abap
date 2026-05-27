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
FUNCTION /PSYNG/SW_API_SOD_BY_REFROLE.
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
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SE_ROLE_REF OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
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
CALL FUNCTION '/PSYNG/SW_API_I_SOD_BY_REFROLE'
 EXPORTING
   REQUEST_ID          = REQUEST_ID
   BATCH_ID            = BATCH_ID
   VRSIO               = VRSIO
   IF_DEF_VRSIO        = IF_DEF_VRSIO
   CONFIG_SET          = CONFIG_SET
   IF_DEF_CONF         = IF_DEF_CONF
   IF_ORG_CHECK        = IF_ORG_CHECK
   LOGGING_FLAG        = LOGGING_FLAG
   IF_LOCAL            = IF_LOCAL
 IMPORTING
   ES_SOD_MATRIX       = ES_SOD_MATRIX
   ES_CONFIG_SET       = ES_CONFIG_SET
   RETURN              = RETURN
 TABLES
   ROLES               = ROLES
   IT_CONID            = IT_CONID
   IT_IMP              = IT_IMP
   ET_OUTPUT           = ET_OUTPUT
   ET_RETURN           = ET_RETURN
   IT_SYSTEMS          = IT_SYSTEMS.

  exelog_api '/PSYNG/SW_API_SOD_BY_REFROLE' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)
ENDFUNCTION.
