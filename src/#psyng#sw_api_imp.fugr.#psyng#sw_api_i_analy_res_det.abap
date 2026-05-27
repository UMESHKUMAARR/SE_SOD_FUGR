*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_ANALYSIS_RES
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_analy_res_det.
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
*"     VALUE(IF_LOCAL) TYPE  FLAG OPTIONAL
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
*"      ET_OUTPUTDET_N STRUCTURE  /PSYNG/SW_OUTPUTDET
*"----------------------------------------------------------------------

  DATA : lt_return     TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         ls_result_set TYPE /psyng/swreshdr,
         l_vrsio       TYPE /psyng/sodvrsio,
         l_config_set  TYPE /psyng/seconfid,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_logging     TYPE flag,
         l_results     TYPE int4,
         l_str_results TYPE char20,
         l_users_in    TYPE string,
         l_firstuser   TYPE string,
         l_lastuser    TYPE string,
         l_users_con   TYPE string,
         l_object      TYPE /psyng/longtext,
         lt_outputdet  TYPE TABLE OF /psyng/outputdet,
         lt_outputdet1  TYPE TABLE OF /psyng/sw_outputdet,
         lf_continue   TYPE flag,
         l_dflt_vrsio  TYPE /psyng/param,
         l_timestamp   TYPE timestampl,
         l_return      TYPE bapireturn,
         ls_return TYPE bapireturn.


*----------------------------------------------------------------------
*-----------------------AUTHORITY-CHECK--------------------------------
*----------------------------------------------------------------------
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    ls_return-type = 'E'.
    ls_return-message
    = 'You are not authorized to analyze the results'(002).
    APPEND ls_return TO et_return.
    CLEAR ls_return.
    EXIT.
  ENDIF.

  lf_continue = 'X'.

*----------------------------------------------------------------------
*-----------------------LOGGING----------------------------------------
*----------------------------------------------------------------------
  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME   FIELD g_start.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
  IF logging_flag = 'X'
  OR logging_flag = '1'.
    LOOP AT users.
      IF sy-tabix = 1.
        l_firstuser = users-bname.
      ENDIF.
    ENDLOOP.
    l_lastuser = users-bname.
    LOOP AT et_users.
      ADD et_users-count TO l_results.
    ENDLOOP.
    l_str_results = l_results.
    CONDENSE l_str_results.
  ENDIF.


*--Number of input users
  DELETE ADJACENT DUPLICATES FROM users COMPARING ALL FIELDS.
  DESCRIBE TABLE users LINES l_users_in.

*----------------------------------------------------------------------
*--------------------GET RESULTS OF LAST STORAGE ID--------------------
*----------------------------------------------------------------------
  IF if_def_run = 'X'.
*--Get last SE Results Storage ID
    CALL FUNCTION '/PSYNG/SW_API_GENERAL_INFO'
     EXPORTING
       if_local              = if_local
     IMPORTING
       analysis_run          = analysis_run
       return                = l_return
     TABLES
       it_systems            = it_systems
       et_return             = et_return.
*    if not l_return is initial.
*      move-corresponding l_return to lt_return.
*      append lt_return.
*    endif.
  ENDIF.

*----------------------------------------------------------------------
*--------------------HEADER DETAILS OF RESULT ID-----------------------
*----------------------------------------------------------------------
  IF lf_continue = 'X'.
    SELECT SINGLE * FROM /psyng/swreshdr
      INTO ls_result_set
      WHERE aid = analysis_run.
    IF sy-subrc NE 0.
      log lt_return 'E' 'NO_RUN'
            'Analysis run does not exist' ''
            '' ''.
      CLEAR lf_continue.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------
*-----------------------SOD VERSION DETAIL-----------------------------
*----------------------------------------------------------------------
  IF lf_continue = 'X'.
    l_vrsio = ls_result_set-sodvrsio.
    PERFORM get_default_sod
      TABLES
        lt_return
      USING
        ' '
      CHANGING
        l_vrsio
        es_sod_matrix
        lf_continue.
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF l_dflt_vrsio = es_sod_matrix-vrsio.
      log lt_return 'I' 'DEFAULT_VERSION'
            'Default SOD matrix version was used.' ''
            '' ''.
    ENDIF.
  ENDIF.


*----------------------------------------------------------------------
*---------------------------CONFIG-SET DETAIL--------------------------
*----------------------------------------------------------------------
  IF lf_continue = 'X'.
    l_config_set = ls_result_set-setid.
    PERFORM get_last_config_set
      TABLES
        lt_return
        it_systems
      USING
        l_vrsio
        ' '
        if_local
      CHANGING
        l_config_set
        es_config_set
        lf_continue.
  ENDIF.
*----------------------------------------------------------------------
*-------------------------GET DETAILED OUTPUT--------------------------
*----------------------------------------------------------------------
  IF lf_continue = 'X'.
    PERFORM get_output
    TABLES users
      et_users
      et_outputdet_n
      lt_return
      USING analysis_run
            if_exclude_mitigated
            if_direct_assn_only
      CHANGING
            l_results.
    e_analysis_run = analysis_run.
  ENDIF.

*--Get conflicts, function and respective roles for input users
*--and for input analysis run
*  IF lf_continue = 'X'.
*    PERFORM get_output_details
*     TABLES users
*            et_users
*            et_outputdet
*            lt_return
*      USING analysis_run
*            l_vrsio
*            if_direct_assn_only
*            if_exclude_mitigated
*      CHANGING
*            l_results.
*    e_analysis_run = analysis_run.
*  ENDIF.
*--Prepare the return messages
  CALL FUNCTION '/PSYNG/SW_API_I_HANDLE_ERROR'
       IMPORTING
            es_return = return
       TABLES
            it_return = lt_return
            et_return = et_return.
  SORT et_return.
  DELETE ADJACENT DUPLICATES FROM et_return.
*--Log this interface call
  IF logging_flag = 'X'
  OR logging_flag = '1'.
*--Get logging configuration
    se_config_param 'APILOG_ANALYSIS_RES' l_logging.
    IF l_logging = 'Y'.
*--Number of users with conflicts
      DESCRIBE TABLE et_users LINES l_users_con.

      l_str_results = l_results.
      CONDENSE : l_str_results, l_users_con.
CONCATENATE analysis_run l_users_in l_users_con l_str_results l_firstuser l_lastuser
INTO l_object SEPARATED BY ' / '.

      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              batch_id
              '/PSYNG/SW_API_ANALYSIS_RES_DET'
              l_results
              return
              l_object
              l_timestamp.
    ENDIF.
  ENDIF.
*--Commit work to trigger update task FM
  COMMIT WORK.

ENDFUNCTION.
