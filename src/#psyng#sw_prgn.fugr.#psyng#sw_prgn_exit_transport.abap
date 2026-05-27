FUNCTION /PSYNG/SW_PRGN_EXIT_TRANSPORT.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(CORRNR) LIKE  E070-TRKORR
*"     VALUE(TASK) LIKE  E070-TRKORR
*"  TABLES
*"      ACTIVITY_GROUPS STRUCTURE  AGR_DEFINE OPTIONAL
*"----------------------------------------------------------------------
*This FM is valid for SAP versions lower than EHP6.
  STATICS : lf_config_checked TYPE flag,
            lf_check_active   TYPE flag,
            l_sod_version     TYPE /psyng/sodvrsio VALUE '000',
            lt_dummy          TYPE TABLE OF AGR_DEFINE,
            lf_dummy          type flag.

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
  perform analyze_role tables ACTIVITY_GROUPS
                       using '' 'PFCG' l_sod_version 'X'
                       changing lf_dummy.
ENDFUNCTION.
