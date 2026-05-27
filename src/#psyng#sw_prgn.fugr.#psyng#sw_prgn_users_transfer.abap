FUNCTION /psyng/sw_prgn_users_transfer .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      ACTIVITY_GROUPS STRUCTURE  STR_AGRS OPTIONAL
*"----------------------------------------------------------------------
*Only the new added roles are in the ACTIVITY_GROUPS table
*the COLL_AGR flag determines if this is direct assignment
*There is no indicator if we're adding or removing this role, so we need
*to find this out from the agr_users table :
* - if the record is already there with the same dates : we're removing
* - if the record is already there with different dates : we're updating
* - if the record is not there yet, we're adding.
*After a commit happens, the changes are saved, so whenever a message
*is displayed, the agr_users table contains the new roles


*--To ensure this only get's called when adding roles to users in SU01
*--The command and tcode is checked.
  CHECK sy-ucomm = 'UPD' AND sy-tcode = 'SU01'. "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)

  STATICS : lf_config_checked TYPE flag,
            lf_check_active   TYPE flag,
            l_sod_version     TYPE /psyng/sodvrsio VALUE '000',
            lt_dummy          TYPE TABLE OF agr_define,
            lf_dummy          TYPE flag.

  DATA: ls_swconfig  TYPE /psyng/swconfig.
  IF lf_config_checked IS INITIAL.
    se_config_param 'SW_USERSAVE_CHECK' ls_swconfig-value.
    lf_config_checked = 'X'.
    IF ls_swconfig-value = 'Y' OR ls_swconfig-value = 'X'.
      lf_check_active = 'X'.
     se_config_param 'SW_INTEGRATION_VRSIO' l_sod_version.
    ENDIF.
  ENDIF.
  CHECK lf_check_active = 'X'.
  PERFORM analyze_user TABLES activity_groups
                       USING  'SU01' l_sod_version.








ENDFUNCTION.
