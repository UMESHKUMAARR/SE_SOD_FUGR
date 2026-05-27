*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_CONFLICT_LIST
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_conflictdetails.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      IT_CONID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      ET_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      ET_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      ET_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      ET_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"----------------------------------------------------------------------
*Call the implementation of this API
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD '03'
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD vrsio.
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message = 'You are not authorized to process the data'(002).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  CALL FUNCTION '/PSYNG/SW_API_I_CONFLICT_LIST'
       EXPORTING
            request_id     = request_id
            vrsio          = vrsio
            if_def_vrsio   = if_def_vrsio
            logging_flag   = logging_flag
            if_con_details = 'X'
       IMPORTING
            es_sod_matrix = es_sod_matrix
            return        = return
       TABLES
            it_conid      = it_conid
            et_conflict   = et_conflict
            et_confdet    = et_confdet
            et_functtran  = et_functtran
            et_faobj      = et_faobj
            et_return     = et_return.
  exelog_api '/PSYNG/SW_API_CONFLICTDETAILS' ''."#EC SAST_CI_GEN_CHECK
*HBHALLA: Variable used in WHERE clause is not constant,
*so it can't be fixed.(17/12/24)

ENDFUNCTION.
