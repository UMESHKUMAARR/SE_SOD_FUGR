FUNCTION /psyng/sw_api_i_get_config_set.
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
*"     VALUE(IF_CONFIG_DISTRI) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(ES_SET) TYPE  /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(RETURN) TYPE  BAPIRETURN
*"  TABLES
*"      IT_CONFIG_SET STRUCTURE  /PSYNG/RANGE_CONFID OPTIONAL
*"      ET_VAREL STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"      ET_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_ORG STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      ET_ELEMENTS STRUCTURE  /PSYNG/SWCFSEL OPTIONAL
*"      ET_CONFIG_HEADER STRUCTURE  /PSYNG/SWCFGSET OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"----------------------------------------------------------------------
  DATA : lf_continue   TYPE flag VALUE 'X',
         l_logging     TYPE flag,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_results     TYPE int4,
         l_org         TYPE string,
         l_varel       TYPE string,
         l_systems     TYPE string,
         l_object      TYPE /psyng/longtext,
         lt_return     TYPE TABLE OF bapiret2,
         l_timestamp   TYPE TIMESTAMPL.
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_CFGST'
            ID 'ACTVT' FIELD '03'
            ID 'Y&SW_SETID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message
   = 'You are not authorized to analyze the results'(002).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME FIELD g_start.
*--If ranges of configuration set passed
  IF NOT if_config_distri IS INITIAL.
*--Read config. set header
    SELECT * FROM /psyng/swcfgset
      INTO TABLE et_config_header
     WHERE setid IN it_config_set.
    IF  sy-subrc EQ 0
    AND NOT et_config_header[] IS INITIAL.
      SORT et_config_header BY setid.
*--Read Systems
      SELECT * FROM /psyng/swcfgsys
        INTO TABLE et_systems
         FOR ALL ENTRIES IN et_config_header
       WHERE setid = et_config_header-setid.
*--Read Org Elements
      SELECT * FROM /psyng/swcfgoe
        INTO TABLE et_org
         FOR ALL ENTRIES IN et_config_header
       WHERE setid = et_config_header-setid.
      IF sy-subrc EQ 0.
        SORT et_org BY setid abb varbl sysid value.
      ENDIF.
*--Read Variable Elements
      SELECT * FROM /psyng/swcfgve
        INTO TABLE et_varel
         FOR ALL ENTRIES IN et_config_header
       WHERE setid = et_config_header-setid.
      IF sy-subrc EQ 0.
        SORT et_varel BY setid var_element sysid value.
      ENDIF.
*--Read selected elements
      SELECT * FROM /psyng/swcfsel
        INTO TABLE et_elements
         FOR ALL ENTRIES IN et_config_header
       WHERE setid = et_config_header-setid.
    ENDIF.
  ELSE.
    l_start_date = sy-datum.
    l_start_time = sy-uzeit.

    PERFORM configset_api_validate_input
                TABLES
                   lt_return
                   it_systems
                USING
                   if_def_vrsio
                   if_def_conf
                   if_local
                CHANGING
                   vrsio
                   config_set
                   es_set
                   es_sod_matrix
                   lf_continue.

    IF lf_continue = 'X'.
*--Read Org Elements
      IF NOT if_inactive IS INITIAL.
*--Read all elements
        SELECT * FROM /psyng/swcfgoe INTO TABLE et_org
        WHERE setid = es_set-setid
        ORDER BY abb varbl value.
      ELSE.
*--Read only active elements
        SELECT * FROM /psyng/swcfgoe INTO TABLE et_org
        WHERE setid = es_set-setid
          AND active = 'X'
        ORDER BY abb varbl value.
      ENDIF.
*--Read Variable Elements
      IF NOT if_inactive IS INITIAL.
*--Read all elements
        SELECT * FROM /psyng/swcfgve INTO TABLE et_varel
        WHERE setid = es_set-setid
        ORDER BY var_element sysid value.
      ELSE.
*--Read only active elements
        SELECT * FROM /psyng/swcfgve INTO TABLE et_varel
        WHERE setid = es_set-setid
          AND active = 'X'
        ORDER BY var_element sysid value.
      ENDIF.
*--Read Systems
      SELECT * FROM /psyng/swcfgsys INTO TABLE
          et_systems WHERE setid = es_set-setid.
*--Read selected elements
      IF et_elements IS REQUESTED.
        SELECT * FROM /psyng/swcfsel INTO TABLE et_elements
          WHERE setid = es_set-setid.
      ENDIF.
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
      se_config_param 'APILOG_CONFIG_SET' l_logging.
      IF l_logging = 'Y'.
        IF return-type EQ 'S'
        OR return-type EQ 'W'.
          l_results = 1.
        ENDIF.
        DESCRIBE TABLE et_org      LINES l_org.
        DESCRIBE TABLE et_varel    LINES l_varel.
        DESCRIBE TABLE et_systems  LINES l_systems.

        CONCATENATE config_set l_org l_varel l_systems
        INTO l_object SEPARATED BY ' / '.

        PERFORM create_logging_entry
          USING l_start_date
                l_start_time
                request_id
                ''
                '/PSYNG/SW_API_GET_CONFIG_SET'
                l_results
                return
                l_object
                l_timestamp.
      ENDIF.
    ENDIF.
*--Commit work to trigger update task FM
    COMMIT WORK.
  ENDIF.
ENDFUNCTION.
