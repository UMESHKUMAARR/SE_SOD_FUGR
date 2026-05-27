FUNCTION /psyng/sw_100.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_HIST_START) TYPE  DATS OPTIONAL
*"     VALUE(I_HIST_END) TYPE  DATS OPTIONAL
*"  TABLES
*"      IT_RESULTS STRUCTURE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"      IT_USERS STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_CONFS STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"----------------------------------------------------------------------

  CONSTANTS : l_fmname(28) TYPE c VALUE '/PSYNG/SEAM_GET_USER_DETAILS'.
  DATA : lt_am_alerts TYPE TABLE OF /psyng/seam_output_user
                      WITH HEADER LINE,
         lt_dates     TYPE TABLE OF /psyng/sw_sel_opts_date
                      WITH HEADER LINE,
         lf_am_installed TYPE flag,
         l_am_vrsio   TYPE /psyng/prog_vrsio.
  FIELD-SYMBOLS  :
  <res> LIKE LINE OF it_results.
*--Check if AM is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'AM'
       IMPORTING
            e_installed      = lf_am_installed
            e_module_version = l_am_vrsio.

  IF lf_am_installed  = 'X' AND l_am_vrsio >= '1.2'.
    MESSAGE s002(/psyng/sw) WITH 'Level 4 Analysis Started'.
    lt_dates-sign   = 'I'.
    lt_dates-option = 'BT'.
    lt_dates-low    = i_hist_start.
    lt_dates-high   = i_hist_end.
    APPEND lt_dates.
* --Collect all alerts from AM
    CALL FUNCTION l_fmname "#EC PATHLOCK_CI_DYN_ACCES
         TABLES
              et_output     = lt_am_alerts
              it_createdate = lt_dates
              it_username   = it_users
              it_conflict   = it_confs.
*  --Remove the ones for different SOD Matrix Version
    DELETE lt_am_alerts WHERE vrsio <> i_vrsio.

    SORT lt_am_alerts BY bname conid.
    DELETE ADJACENT DUPLICATES FROM lt_am_alerts COMPARING bname conid.
*--Mark the conflict as Level 4 in output
    LOOP AT it_results ASSIGNING <res>.
      READ TABLE lt_am_alerts WITH KEY
      bname = <res>-bname
      conid = <res>-conid
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        <res>-level4 = 'X'.
      ENDIF.
    ENDLOOP.
   MESSAGE s002(/psyng/sw) WITH 'Level 4 Analysis Completed'.
  else.
*   MESSAGE s002(/psyng/sw) WITH 'Level 4 Analysis not executed'
*                     'AM Not Installed or version to low'.
  ENDIF.
ENDFUNCTION.
