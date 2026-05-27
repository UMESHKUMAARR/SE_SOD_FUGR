FUNCTION /PSYNG/SW_MC_REVIEW_SCREEN.
*"----------------------------------------------------------------------
*"*"Local interface:
*"       IMPORTING
*"             REFERENCE(I_DETAILS) TYPE  /PSYNG/SW_MC_REVIEW_REPORT
*"             REFERENCE(I_SUMMARY) TYPE  /PSYNG/MCRVWSGN
*"----------------------------------------------------------------------
  REFRESH : gt_texttab.
  PERFORM  init_values.
  CLEAR: gw_details, gw_summary.
  gw_details = i_details.
  gw_summary = i_summary.
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.

  CALL SCREEN 9001 STARTING AT 5 5.


ENDFUNCTION.
