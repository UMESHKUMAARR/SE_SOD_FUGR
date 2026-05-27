*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_GENERAL_INFO
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_general_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ALL_VERSIONS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_ALL_RUNS) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(SYS_ID) TYPE  SYSYSID
*"     VALUE(SYS_CLIENT) TYPE  SYMANDT
*"     VALUE(SYS_INST_NR) TYPE  CHAR10
*"     VALUE(SE_VRSIO) TYPE  /PSYNG/PROG_VRSIO
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ANALYSIS_RUN) TYPE  /PSYNG/SERESID
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      ET_SWSODVERS STRUCTURE  /PSYNG/SWSODVERS OPTIONAL
*"      ET_CONFIG_SET STRUCTURE  /PSYNG/SWCFGSET OPTIONAL
*"      ET_SET_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_RESHDR STRUCTURE  /PSYNG/SWRESHDR OPTIONAL
*"      ET_RES_SYSTEMS STRUCTURE  /PSYNG/SWRESISYS OPTIONAL
*"----------------------------------------------------------------------


  DATA : lt_return     TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         l_vrsio       TYPE /psyng/sodvrsio,
         l_config_set  TYPE /psyng/seconfid,
         lt_ana_header TYPE TABLE OF /psyng/swreshdr,
         ls_ana_header TYPE /psyng/swreshdr,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_logging     TYPE flag,
         l_results     TYPE int4,
         l_object      TYPE /psyng/longtext,
         l_sdate       TYPE /psyng/start_date,
         l_str_date    TYPE char10,
         l_se_vrsio    TYPE char12,
         lf_continue   TYPE flag,
         l_timestamp   TYPE TIMESTAMPL.
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
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
* EOC by RGUPTA for C0743
  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME   FIELD g_start.

  lf_continue  = 'X'.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
*--Move System details ID and client
  sys_id     = sy-sysid(3).
  sys_client = sy-mandt.
*--Move installation number
  CALL FUNCTION 'SLIC_GET_LICENCE_NUMBER'
       IMPORTING
            license_number = sys_inst_nr.
*--Get Program version of Separations Enforcer
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'SE'
       IMPORTING
            e_module_version = se_vrsio.
*--Get Information about the global default SOD Matrix
  PERFORM get_default_sod
    TABLES
      lt_return
    USING
      'X'
    CHANGING
      l_vrsio
      es_sod_matrix
      lf_continue.
*--Get Information about the latest published Configuration Set
  IF lf_continue = 'X'
  OR if_all_versions = 'X'.
    PERFORM get_last_config_set
      TABLES
        lt_return
        IT_SYSTEMS
      USING
        l_vrsio
        'X'
        IF_LOCAL
      CHANGING
        l_config_set
        es_config_set
        lf_continue.
  ENDIF.
   perform general_info_load_all_sys
    tables et_res_systems
           ET_RESHDR
           it_systems
    using
           if_local.

*--Get RunID of the latest unrestricted run of Stored SOD results
  IF lines( ET_RESHDR ) > 0.
    lt_ana_header[] = ET_RESHDR[].
    delete lt_ana_header where (
                                end_date EQ '00000000' AND
                                end_time EQ '000000'
                               )
                               OR
                               (
                                SETID    <> l_config_set or
                                sodvrsio <> l_vrsio or
                                NO_RESTRICTIONS <> 'X'
                               ).

    SORT lt_ana_header BY aid DESCENDING.
    READ TABLE lt_ana_header INTO ls_ana_header INDEX 1.
    IF sy-subrc = 0.
      analysis_run = ls_ana_header-aid.
      l_sdate      = ls_ana_header-start_date.
      IF NOT l_sdate IS INITIAL.
        CALL FUNCTION 'CONVERT_DATE_TO_EXTERNAL'
             EXPORTING
                  date_internal = l_sdate
             IMPORTING
                  date_external = l_str_date
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             DATE_INTERNAL_IS_INVALID = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDIF.
    ENDIF.
  ENDIF.
  if analysis_run is initial.
    log lt_return 'W' 'NO_COMPLETE_CHECK'
          'No Analysis of all conflicts for all users found' ''
          '' ''.
  ENDIF.

  if if_all_runs <> 'X'.
       refresh et_reshdr.
       refresh et_res_systems.
  endif.

*--Get all Versions and all configuration sets
  IF if_all_versions EQ 'X'.
    SELECT *
      FROM /psyng/swsodvers
      INTO TABLE et_swsodvers.
    IF sy-subrc EQ 0.
      SORT et_swsodvers BY vrsio.
    ENDIF.

    SELECT *
      FROM /psyng/swcfgset
      INTO TABLE et_config_set.
    IF sy-subrc EQ 0.
      SORT et_config_set BY setid.
    ENDIF.

    LOOP AT lt_return
      WHERE id EQ 'NO_DEFAULT_VERSION'
         OR id EQ 'NOGLOBALCONFSET'.
      lt_return-type = 'W'.
      MODIFY lt_return.
    ENDLOOP.
  ENDIF.
*--Return the systems inside the configuration set(s)
  select * from /psyng/swcfgsys into table ET_SET_SYSTEMS  where setid = es_config_set-setid.
  if ET_SET_SYSTEMS is requested.
    if et_config_set[] is not initial.
      select * from /psyng/swcfgsys appending table ET_SET_SYSTEMS for all entries in et_config_set where setid = et_config_set-setid.
    endif.
  endif.
  sort ET_SET_SYSTEMS by setid sysid.


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
    se_config_param 'APILOG_GENERAL_INFO' l_logging.
    IF l_logging = 'Y'.
      IF return-type EQ 'S'
      OR return-type EQ 'W'.
        l_results = 1.
      ENDIF.
      IF NOT se_vrsio IS INITIAL.
        CONCATENATE 'SE' se_vrsio INTO l_se_vrsio.
      ENDIF.
      CONCATENATE l_se_vrsio l_vrsio l_config_set
                  analysis_run l_str_date INTO l_object
                  SEPARATED BY ' / '.
      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              ''              " Blank batch ID
              '/PSYNG/SW_API_GENERAL_INFO'
              l_results
              return
              l_object
              l_timestamp.
    ENDIF.
  ENDIF.
*--Commit work to trigger update task FM
  COMMIT WORK.
ENDFUNCTION.
