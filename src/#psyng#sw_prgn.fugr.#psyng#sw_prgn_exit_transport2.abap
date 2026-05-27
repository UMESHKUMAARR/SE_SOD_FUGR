FUNCTION /PSYNG/SW_PRGN_EXIT_TRANSPORT2.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(CORRNR) LIKE  E070-TRKORR
*"     VALUE(TASK) LIKE  E070-TRKORR
*"  TABLES
*"      ACTIVITY_GROUPS STRUCTURE  /PSYNG/BC_AGR_NAME OPTIONAL
*"----------------------------------------------------------------------
*This FM is valid for EHP6 or higher versions of SAP.
  STATICS : lf_config_checked TYPE flag,
            lf_check_active   TYPE flag,
            l_sod_version     TYPE /psyng/sodvrsio VALUE '000',
            lt_dummy          TYPE TABLE OF AGR_DEFINE,
            lf_dummy          type flag,
            lt_agr_define     type table of agr_define with header line.

  DATA: ls_swconfig  TYPE /psyng/swconfig.
  IF lf_config_checked IS INITIAL.
    se_config_param 'SW_TRP_ADD_CHECK' ls_swconfig-value.
    lf_config_checked = 'X'.
    IF ls_swconfig-value = 'Y' OR ls_swconfig-value = 'X'.
      lf_check_active = 'X'.
      se_config_param 'SW_INTEGRATION_VRSIO' l_sod_version.
    ENDIF.
  ENDIF.
  CHECK lf_check_active = 'X'.
  loop at ACTIVITY_GROUPS.
    lt_agr_define-agr_name = ACTIVITY_GROUPS-agr_name.
    append lt_agr_define.
  endloop.
  perform analyze_role tables lt_agr_define
                       using '' 'PFCG' l_sod_version 'X'
                       changing lf_dummy.
ENDFUNCTION.
