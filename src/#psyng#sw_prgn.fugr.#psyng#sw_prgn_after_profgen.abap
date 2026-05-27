FUNCTION /psyng/sw_prgn_after_profgen.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(ACTIVITY_GROUP) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(GENERATED) LIKE  SMENSAPNEW-CUSTOMIZED
*"----------------------------------------------------------------------
  STATICS : lf_config_checked TYPE flag,
            lf_check_active   TYPE flag,
            l_sod_version     TYPE /psyng/sodvrsio VALUE '000',
            lt_dummy          TYPE TABLE OF agr_define,
            lf_dummy          TYPE flag.

*-- We only want to analyze parent role when we generated it
*-- not when we generate the derived roles that are part of it
*-- sy-ucomm is initial (not GEN1 or DBAC) when we genrate derived role
*-- Case 11526 - HS
  CHECK NOT sy-ucomm IS INITIAL.
  DATA: ls_swconfig  TYPE /psyng/swconfig.
  IF lf_config_checked IS INITIAL.
    se_config_param 'SW_PROFILE_CHECK' ls_swconfig-value.
    lf_config_checked = 'X'.
    IF ls_swconfig-value = 'Y' OR ls_swconfig-value = 'X'.
      lf_check_active = 'X'.
      se_config_param 'SW_INTEGRATION_VRSIO' l_sod_version.
    ENDIF.
  ENDIF.
  CHECK lf_check_active = 'X'.
  PERFORM analyze_role TABLES lt_dummy
                       USING activity_group
                       'PFCG' l_sod_version 'X'
                       CHANGING lf_dummy.
ENDFUNCTION.
