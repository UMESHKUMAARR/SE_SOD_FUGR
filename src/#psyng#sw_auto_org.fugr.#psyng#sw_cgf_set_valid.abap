FUNCTION /psyng/sw_cgf_set_valid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(IF_SHOW_WARNING) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL_SYSTEM) TYPE  FLAG OPTIONAL
*"     VALUE(IF_CALLED_FROM_OVW_REPORT) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_VALID) TYPE  FLAG
*"     VALUE(EF_WRONG_VERSION) TYPE  FLAG
*"     VALUE(EF_UNPUBLISHED) TYPE  FLAG
*"     VALUE(EF_MISSING_SYSTEM) TYPE  FLAG
*"     VALUE(EF_SYSTEM_MISMATCH) TYPE  FLAG
*"  TABLES
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_RFCDEST STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CGF_SET_VALID'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  DATA : ls_set                 TYPE /psyng/swcfgset,
         l_exact_match          TYPE /psyng/param_value,
         lt_set_systems         TYPE SORTED TABLE OF /psyng/swcfgsys
                                WITH UNIQUE KEY sysid WITH HEADER LINE,
         l_cnt_matching_systems TYPE i,
         l_cnt_analyzed_systems TYPE i,
         l_cnt_total_systems    TYPE i.
  CLEAR : ef_wrong_version, ef_unpublished,
  g_100_msg_1,g_100_msg_2, g_100_msg_3.

*--Determine if an exact match on systems should be considered
  se_config_param  'CFG_SET_EXACT_MATCH' l_exact_match.
*--fill systems table
  PERFORM load_analyzed_systems
    TABLES it_systems
           it_rfcdest
    USING if_local_system.
  ef_valid = 'X'.
  SELECT SINGLE * FROM /psyng/swcfgset INTO ls_set WHERE
    setid = i_setid.
  IF sy-subrc <> 0.
    CLEAR ef_valid.
    IF if_show_warning = 'X'.
      MESSAGE i026(/psyng/sw) WITH i_setid INTO g_100_msg_1.
    ENDIF.
  ELSE.
    IF ls_set-sodvrsio <> i_vrsio.
      CLEAR ef_valid.
      ef_wrong_version = 'X'.
      IF if_show_warning = 'X'.
        MESSAGE i027(/psyng/sw) WITH i_setid i_vrsio INTO g_100_msg_1.
      ENDIF.
    ENDIF.
    IF ls_set-published <> 'X'.
      CLEAR ef_valid.
      ef_unpublished = 'X'.
      IF if_show_warning = 'X'.
        MESSAGE i025(/psyng/sw) WITH i_setid INTO g_100_msg_2.
      ENDIF.
    ENDIF.
  ENDIF.
*--Match the systems with the config set
SELECT * FROM /psyng/swcfgsys INTO TABLE lt_set_systems WHERE setid = i_setid.
  LOOP AT  it_systems.
    ADD 1 TO l_cnt_analyzed_systems.
READ TABLE lt_set_systems WITH TABLE KEY sysid = it_systems-sysid TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      ADD 1 TO l_cnt_matching_systems.
    ENDIF.
  ENDLOOP.
  IF l_cnt_matching_systems <> l_cnt_analyzed_systems.
*-- some of the analyzed systems are not in the Configuration Set
    ef_missing_system = 'X'.
    CLEAR ef_valid.
    IF if_show_warning = 'X'.
      MESSAGE i031(/psyng/sw)  INTO g_100_msg_3.
    ENDIF.
  ENDIF.
  IF l_exact_match = 'Y'.
*--Check if the configuration set only contains all systems that are being analyzed
    l_cnt_total_systems = lines( lt_set_systems ).
    IF l_cnt_total_systems    <> l_cnt_analyzed_systems OR
       l_cnt_matching_systems <> l_cnt_analyzed_systems.
      ef_system_mismatch = 'X'.
      CLEAR ef_valid.
      IF if_show_warning = 'X' AND
        if_called_from_ovw_report IS INITIAL.
        MESSAGE i032(/psyng/sw)  INTO g_100_msg_3.
      ENDIF.
    ENDIF.
  ENDIF.
*-- odubey 17.07.2023 Opl588
  IF NOT if_called_from_ovw_report IS INITIAL.
    CLEAR ef_system_mismatch.
    CLEAR if_show_warning.
    ef_valid = 'X'.
  ENDIF.
*end

  IF ef_wrong_version   = 'X' OR
     ef_unpublished     = 'X' OR
     ef_system_mismatch = 'X' OR
     ef_missing_system  = 'X' OR
     ef_valid          <> 'X'.
    g_100_setid         = i_setid.
    g_100_vrsio         = i_vrsio.
    g_100_show_warning  = if_show_warning.
    g_100_valid         = ef_valid.
    g_100_wrong_version = ef_wrong_version.
    g_100_unpublished   = ef_unpublished.
    g_100_missingsystem = ef_missing_system.
    g_system_mismatch   = ef_system_mismatch.
*        try.
    IF sy-batch EQ 'X' OR
       NOT if_called_from_ovw_report IS INITIAL.
    ELSE.
      CALL SCREEN '0100' STARTING AT 10 10.
    ENDIF.
*          CATCH cx_sy_send_dynpro_no_receiver.
*--If this is called from a web report, don't try to show the screen.
*ENDTRY.
ef_wrong_version = g_100_wrong_version.
ENDIF.
ENDFUNCTION.
