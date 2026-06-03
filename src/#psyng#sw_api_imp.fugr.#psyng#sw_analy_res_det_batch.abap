FUNCTION /psyng/sw_analy_res_det_batch.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BATCH_ID) TYPE  /PSYNG/BATCH_ID OPTIONAL
*"     VALUE(ANALYSIS_RUN) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(IF_DEF_RUN) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_EXCLUDE_MITIGATED) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CLEAR_PREV) TYPE  FLAG OPTIONAL
*"     VALUE(I_BATCH_SIZE) TYPE  INT4 OPTIONAL
*"  EXPORTING
*"     VALUE(E_ANALYSIS_RUN) TYPE  /PSYNG/SERESID
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"     VALUE(E_BATCHES_CREATED) TYPE  INT4
*"     VALUE(E_ROWS_WRITTEN) TYPE  INT4
*"     VALUE(E_USERS_PROCESSED) TYPE  INT4
*"  TABLES
*"      USERS STRUCTURE  /PSYNG/SW_USERLIST OPTIONAL
*"      ET_USERS STRUCTURE  /PSYNG/USERCONCOUNT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_OUTPUTDET_N STRUCTURE  /PSYNG/SW_OUTPUTDET OPTIONAL
*"----------------------------------------------------------------------

*----------------------------------------------------------------------*
* Data declarations
*----------------------------------------------------------------------*
  DATA: lt_return        TYPE TABLE OF bapiret2 WITH HEADER LINE,
        ls_result_set    TYPE /psyng/swreshdr,
        l_vrsio          TYPE /psyng/sodvrsio,
        l_config_set     TYPE /psyng/seconfid,
        l_start_date     TYPE dats,
        l_start_time     TYPE tims,
        l_logging        TYPE flag,
        l_results        TYPE int4,
        l_str_results    TYPE char20,
        l_users_in       TYPE string,
        l_users_con      TYPE string,
        l_firstuser      TYPE string,
        l_lastuser       TYPE string,
        l_object         TYPE /psyng/longtext,
        lf_continue      TYPE flag,
        l_dflt_vrsio     TYPE /psyng/param,
        l_timestamp      TYPE timestampl,
        l_return         TYPE bapireturn,
        ls_return        TYPE bapireturn,
        l_lines          TYPE sy-tabix,
        l_batch_size     TYPE i,
        l_batch_size_p   TYPE /psyng/param,
        ls_track         TYPE /psyng/sw_det_t,
        l_max_seq        TYPE i,
        lv_seq           TYPE i,
        lv_msg           TYPE string,
        lv_aid_c         TYPE char20,
        lv_bat_c         TYPE char10,
        lv_row_c         TYPE char20,
        lv_usr_c         TYPE char10,
        lv_flags         TYPE string,
        lt_active        TYPE TABLE OF string,   "for flag string
        lv_joined        TYPE string,            "for flag string
        lv_dir_assgn     TYPE flag.

*----------------------------------------------------------------------*
* Authority Check
*----------------------------------------------------------------------*
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_ANALY_RES_DET_BATCH'.
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '03'.

  IF sy-subrc <> 0.
    CLEAR ls_return.
    ls_return-type    = 'E'.
    ls_return-message =
      'You are not authorized to analyze the results'(002).
    APPEND ls_return TO et_return.
    return = ls_return.
    EXIT.
  ENDIF.

  lf_continue = 'X'.
  "To use composite roles , create a import
  "parameter if_direct_assn_only eith type flag
  " and pass as 'X' and in PERFORM get_analy_res_det_batch.

  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME FIELD g_start.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.

*----------------------------------------------------------------------*
* Resolve batch size
*----------------------------------------------------------------------*
  IF i_batch_size > 0.
    l_batch_size = i_batch_size.
  ELSE.
    se_config_param 'APIDET_BATCH_SIZE' l_batch_size_p.
    IF l_batch_size_p IS NOT INITIAL.
      l_batch_size = l_batch_size_p.
    ELSE.
      l_batch_size = 1000.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Capture first/last user for logging
*----------------------------------------------------------------------*
  IF logging_flag = 'X' OR logging_flag = '1'.
    READ TABLE users INDEX 1.
    IF sy-subrc = 0.
      l_firstuser = users-bname.
    ENDIF.
    DESCRIBE TABLE users LINES l_lines.
    IF l_lines > 0.
      READ TABLE users INDEX l_lines.
      IF sy-subrc = 0.
        l_lastuser = users-bname.
      ENDIF.
    ENDIF.
  ENDIF.

  SORT users BY bname.
  DELETE ADJACENT DUPLICATES FROM users COMPARING bname.
  DESCRIBE TABLE users LINES l_users_in.

*----------------------------------------------------------------------*
* Resolve ANALYSIS_RUN if IF_DEF_RUN set
*----------------------------------------------------------------------*
  IF if_def_run = 'X'.
    CALL FUNCTION '/PSYNG/SW_API_GENERAL_INFO'
      EXPORTING
        if_local     = if_local
      IMPORTING
        analysis_run = analysis_run
        return       = l_return
      TABLES
        it_systems   = it_systems
        et_return    = et_return.
  ENDIF.

*----------------------------------------------------------------------*
* Validate AID exists
*----------------------------------------------------------------------*
  IF lf_continue = 'X'.
    SELECT SINGLE sodvrsio setid
      FROM /psyng/swreshdr
      INTO CORRESPONDING FIELDS OF ls_result_set
      WHERE aid = analysis_run.
    IF sy-subrc NE 0.
      log lt_return 'E' 'NO_RUN'
            'Analysis run does not exist' '' '' ''.
      CLEAR lf_continue.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Resolve SOD matrix version
*----------------------------------------------------------------------*
  IF lf_continue = 'X'.
    l_vrsio = ls_result_set-sodvrsio.
    PERFORM get_default_sod
      TABLES lt_return
      USING  ' '
      CHANGING l_vrsio es_sod_matrix lf_continue.
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF l_dflt_vrsio = es_sod_matrix-vrsio.
      log lt_return 'I' 'DEFAULT_VERSION'
            'Default SOD matrix version was used.' '' '' ''.
    ENDIF.
  ENDIF.

*----------------------------------------------------------------------*
* Resolve config set
*----------------------------------------------------------------------*
  IF lf_continue = 'X'.
    l_config_set = ls_result_set-setid.
    PERFORM get_last_config_set
      TABLES lt_return it_systems
      USING  l_vrsio ' ' if_local
      CHANGING l_config_set es_config_set lf_continue.
  ENDIF.

  CHECK lf_continue = 'X'.

  e_analysis_run = analysis_run.

*----------------------------------------------------------------------*
* JOB LOG: START banner — inlined, no helper FORM
*----------------------------------------------------------------------*
  WRITE analysis_run TO lv_aid_c LEFT-JUSTIFIED.
  CONDENSE lv_aid_c.
*
** Build compact flag string — only active flags shown
*  REFRESH lt_active.
*  IF if_direct_assn_only  = 'X'. APPEND `DIRECT_ASSN`    TO lt_active.
*ENDIF.
*  IF if_exclude_mitigated = 'X'. APPEND `EXCL_MITIGATED` TO lt_active.
*ENDIF.
*  IF if_clear_prev        = 'X'. APPEND `CLEAR_PREV`     TO lt_active.
*ENDIF.
*  IF lt_active IS INITIAL.
*    lv_flags = 'Flags: none'.
*  ELSE.
*    CONCATENATE LINES OF lt_active INTO lv_joined SEPARATED BY ' '.
*    CONCATENATE 'Flags:' lv_joined INTO lv_flags SEPARATED BY ' '.
*  ENDIF.
*
** e.g. "START  AID: 0000001209  Flags: CLEAR_PREV"
*  CONCATENATE 'START  AID:' lv_aid_c lv_flags
*    INTO lv_msg SEPARATED BY '  '.
*
*  CLEAR ls_return.
*  ls_return-type    = 'S'.
*  ls_return-message = lv_msg.
*  APPEND ls_return TO lt_return.
*  APPEND ls_return TO et_return.

*----------------------------------------------------------------------*
* Clear previous DB data if IF_CLEAR_PREV = 'X'
*----------------------------------------------------------------------*
  IF if_clear_prev = 'X'.

    SELECT SINGLE total_batch
      INTO l_max_seq
      FROM /psyng/sw_det_t
      WHERE aid = analysis_run.           "#EC CI_GENBUFF

    IF sy-subrc <> 0 OR l_max_seq = 0.
      SELECT MAX( batch_seq )
        INTO l_max_seq
        FROM /psyng/sw_resdet
        WHERE aid = analysis_run.         "#EC CI_GENBUFF
    ENDIF.

*   JOB LOG: CLEAR confirmation — inlined
    IF l_max_seq > 0.
      WRITE l_max_seq TO lv_bat_c LEFT-JUSTIFIED.
      CONDENSE lv_bat_c.
*     e.g. "CLEAR  Removed: 47 batch(es)"
      CONCATENATE 'Removed:' lv_bat_c 'batch(es)'
        INTO lv_msg SEPARATED BY ' '.
    ELSE.
      lv_msg = 'No prior data found — nothing to delete'.
    ENDIF.
*    CLEAR ls_return.
*    ls_return-type    = 'I'.
*    ls_return-message = lv_msg.
*    APPEND ls_return TO lt_return.
*    APPEND ls_return TO et_return.

    DO l_max_seq TIMES.
      lv_seq = sy-index.
      DELETE FROM /psyng/sw_resdet
        WHERE aid       = analysis_run
          AND batch_seq = lv_seq.         "#EC CI_NOFIRST
      COMMIT WORK.
    ENDDO.

    DELETE FROM /psyng/sw_det_t
      WHERE aid = analysis_run.           "#EC CI_NOFIRST
    COMMIT WORK.

  ENDIF.

*----------------------------------------------------------------------*
* BATCH PATH — per-batch [I] progress written inside the FORM
*----------------------------------------------------------------------*
  PERFORM get_analy_res_det_batch
    TABLES
      users
      et_users
      lt_return
    USING
      analysis_run
      if_exclude_mitigated
*      if_direct_assn_only
      ''
      l_batch_size
    CHANGING
      l_results.

*----------------------------------------------------------------------*
* Write tracking table
*----------------------------------------------------------------------*
  SELECT MAX( batch_seq )
    INTO l_max_seq
    FROM /psyng/sw_resdet
    WHERE aid = analysis_run.             "#EC CI_GENBUFF

  IF sy-subrc = 0 AND l_max_seq > 0.

    DELETE FROM /psyng/sw_det_t
      WHERE aid = analysis_run.           "#EC CI_NOFIRST
    CLEAR ls_track.
    SELECT COUNT(*)
      INTO ls_track-total_rows
      FROM /psyng/sw_resdet
      WHERE aid = analysis_run.

    ls_track-aid          = analysis_run.
    ls_track-total_batch  = l_max_seq.
    ls_track-batches_read = 0.
    ls_track-created_on   = sy-datum.
    ls_track-updated_on   = sy-datum.
    INSERT /psyng/sw_det_t FROM ls_track. "#EC CI_SUBRC

    COMMIT WORK.

  ENDIF.

*----------------------------------------------------------------------*
* Populate EXPORTING summary parameters
*----------------------------------------------------------------------*
  e_batches_created = ls_track-total_batch.
  e_rows_written    = ls_track-total_rows.
  DESCRIBE TABLE et_users LINES e_users_processed.

*----------------------------------------------------------------------*
* JOB LOG: DONE / WARN summary — inlined
*----------------------------------------------------------------------*
  WRITE e_batches_created TO lv_bat_c LEFT-JUSTIFIED.
  WRITE e_rows_written    TO lv_row_c LEFT-JUSTIFIED.
  WRITE e_users_processed TO lv_usr_c LEFT-JUSTIFIED.
  CONDENSE: lv_bat_c, lv_row_c, lv_usr_c.

*----------------------------------------------------------------------*
* Error handling — NO SORT, preserves chronological order
*----------------------------------------------------------------------*
  CALL FUNCTION '/PSYNG/SW_API_I_HANDLE_ERROR'
    IMPORTING  es_return = return
    TABLES     it_return = lt_return
               et_return = et_return.

  DELETE ADJACENT DUPLICATES FROM et_return
    COMPARING type message.

*----------------------------------------------------------------------*
* API Logging
*----------------------------------------------------------------------*
  IF logging_flag = 'X' OR logging_flag = '1'.

    se_config_param 'APILOG_ANALYSIS_RES' l_logging.

    IF l_logging = 'Y'.

      DESCRIBE TABLE et_users LINES l_users_con.

      l_str_results = l_results.
      CONDENSE: l_str_results, l_users_con.

      CONCATENATE analysis_run
                  l_users_in
                  l_users_con
                  l_str_results
                  l_firstuser
                  l_lastuser
             INTO l_object
             SEPARATED BY ' / '.

      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              batch_id
              '/PSYNG/SW_ANALY_RES_DET_BATCH'
              l_results
              return
              l_object
              l_timestamp.

    ENDIF.

  ENDIF.

  COMMIT WORK.
ENDFUNCTION.
