FUNCTION /psyng/sw_bg_job_print_params.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"----------------------------------------------------------------------
  DATA: ls_swconfig_bkgd_job TYPE /psyng/swconfig.
  statics : lf_parameter_set type flag.
  if lf_parameter_set is initial.
    IF sy-batch EQ 'X'.
      se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.
      IF ls_swconfig_bkgd_job-value = 'N'.
        CALL FUNCTION 'SET_PRINT_PARAMETERS'
          EXPORTING
            line_count = 999999999.
      ENDIF.
      lf_parameter_set = 'X'.
    ENDIF.
  endif.
ENDFUNCTION.
