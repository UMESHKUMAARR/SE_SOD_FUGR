*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_CONFLICT_LIST
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_conflict_list.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CON_DETAILS) TYPE  FLAG OPTIONAL
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

  DATA : lt_return     TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_logging     TYPE flag,
         l_results     TYPE int4,
         l_object      TYPE /psyng/longtext,
         l_str_results TYPE char20,
         l_api_name    TYPE rs38l_fnam,
         lf_continue   TYPE flag,
         l_timestamp   TYPE TIMESTAMPL.
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT'      FIELD '03'
             ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD vrsio.
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message = 'You are not authorized to process the data'(003).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  GET TIME STAMP FIELD l_timestamp.


  DATA: lf_cfg_set_enabled TYPE flag.

  GET RUN TIME FIELD g_start.

  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
**--Do validation of import parameter
**--And also get Information about the global default SOD Matrix
  PERFORM get_default_sod
    TABLES
      lt_return
    USING
      if_def_vrsio
    CHANGING
      vrsio
      es_sod_matrix
      lf_continue.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled = 'X'.
    CLEAR lt_return.
    log lt_return 'I' 'CFG_SET_ENABLED'
       'Configuration Set functionality enabled'
       'CFG_SET_ENABLED = X' '' ''.
  ELSE.
    CLEAR lt_return.
    log lt_return 'I' 'CFG_SET_DISABLED'
      'Configuration Set functionality Disabled'
      'CFG_SET_ENABLED <> X' '' ''.
  ENDIF.
*--Get all conflicts in SOD matrix
  CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CONIDS'
       EXPORTING
            vrsio    = vrsio
       TABLES
            conflict = et_conflict.
  SORT et_conflict BY conid.
  IF NOT it_conid[] IS INITIAL.
    DELETE et_conflict WHERE NOT conid IN it_conid.
  ENDIF.
*--Get conflict details
  IF et_confdet IS REQUESTED
  AND NOT et_conflict[] IS INITIAL.
    SELECT * FROM /psyng/confdet INTO TABLE et_confdet
    FOR ALL ENTRIES IN et_conflict
    WHERE conid = et_conflict-conid
      AND vrsio = et_conflict-vrsio.
  ENDIF.
*--Get transactions or placeholders of the functions
  IF et_functtran IS REQUESTED
  AND NOT et_confdet[] IS INITIAL.
    SELECT * FROM /psyng/functtran INTO TABLE et_functtran
    FOR ALL ENTRIES IN et_confdet
    WHERE functionid = et_confdet-functionid
      AND vrsio = et_confdet-vrsio.
  ENDIF.
*--Get objects of the functions
  IF et_faobj IS REQUESTED
  AND NOT et_functtran[] IS INITIAL.
    SELECT * FROM /psyng/faobj2 INTO TABLE et_faobj
    FOR ALL ENTRIES IN et_functtran
    WHERE vrsio = et_functtran-vrsio
      AND funid = et_functtran-functionid
      AND tcode = et_functtran-tcode.
  ENDIF.
*--Prepare the return messages
  CALL FUNCTION '/PSYNG/SW_API_I_HANDLE_ERROR'
       IMPORTING
            es_return = return
       TABLES
            it_return = lt_return
            et_return = et_return.
*--Log this interface call
  IF logging_flag = 'X'
  OR logging_flag = '1'.
*--Get logging configuration
    IF if_con_details IS INITIAL.
      se_config_param 'APILOG_CONFLICT_LIST' l_logging.
      l_api_name = '/PSYNG/SW_API_CONFLICT_LIST'.
    ELSE.
      se_config_param 'APILOG_CONFLICT_DET' l_logging.
      l_api_name = '/PSYNG/SW_API_CONFLICTDETAILS'.
    ENDIF.
    IF l_logging = 'Y'.
      DESCRIBE TABLE et_conflict LINES l_results.
      l_str_results = l_results.
      CONDENSE l_str_results.
      CONCATENATE vrsio l_str_results INTO l_object
        SEPARATED BY ' / '.
      IF NOT if_con_details IS INITIAL.
        DESCRIBE TABLE et_confdet LINES l_results.
        l_str_results = l_results.
        CONDENSE l_str_results.
        CONCATENATE l_object l_str_results INTO l_object
          SEPARATED BY ' / '.
        DESCRIBE TABLE et_functtran LINES l_results.
        l_str_results = l_results.
        CONDENSE l_str_results.
        CONCATENATE l_object l_str_results INTO l_object
          SEPARATED BY ' / '.
        DESCRIBE TABLE et_faobj LINES l_results.
        l_str_results = l_results.
        CONDENSE l_str_results.
        CONCATENATE l_object l_str_results INTO l_object
          SEPARATED BY ' / '.
      ENDIF.
      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              ''              " Blank batch ID
              l_api_name
              l_results
              return
              l_object
              l_timestamp.
    ENDIF.
  ENDIF.
*--Commit work to trigger update task FM
  COMMIT WORK.

ENDFUNCTION.
