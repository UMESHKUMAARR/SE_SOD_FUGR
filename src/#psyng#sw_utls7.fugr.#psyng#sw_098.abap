FUNCTION /psyng/sw_098.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_HIST_START) TYPE  DATS OPTIONAL
*"     VALUE(I_HIST_END) TYPE  DATS OPTIONAL
*"     VALUE(IF_USE_TA) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      IT_RESULTS STRUCTURE  /PSYNG/SW_SOD_OUTPUT_ORG OPTIONAL
*"      IT_FUNCRESULTS STRUCTURE  /PSYNG/SW_OUTPUT_ORG OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"----------------------------------------------------------------------
DATA : lf_by_function TYPE flag,
       lf_by_conflict TYPE flag,
       lf_TA_installed type flag,
       lf_ta_v21       type flag,
       l_ta_version    type /PSYNG/PROG_VRSIO,
       lT_FUNCTTRAN    TYPE TABLE OF /PSYNG/FUNCTTRAN,
       lT_services     TYPE TABLE OF /PSYNG/FUNCTTRAN.

*Odubey Case# 21246 2021/10/20
*--check the TA integration and disable based on parameter
data: l_disable_ta type flag,
      l_cfg_value TYPE /psyng/param_value.

call function '/PSYNG/SW_GET_CONFIG'
       exporting
            i_parameter = 'TA_DISPLAY_HISTORY'
       importing
            e_value     = l_cfg_value.


  IF l_cfg_value = 'N'.
    l_disable_ta = 'X'.
  ELSE.
   CLEAR l_disable_ta.
  ENDIF.
*---end change

*--Check if TA is installed
  perform check_ta_installed changing lf_ta_installed lf_ta_v21 l_ta_version.
  if not lf_ta_installed = 'X'.
    clear if_use_ta.
  endif.

*--Get the tcodes from the object details
  lt_functtran[] = IT_FUNCTTRAN[].
  perform get_tcodes_from_objects
    tables
      IT_FAOBJ
      lt_functtran.
  perform get_services_from_objects
    tables
      IT_FAOBJ
      lt_services.


  IF NOT it_results IS REQUESTED OR it_results[] IS INITIAL.
    lf_by_function = 'X'.
  ELSE.
    lf_by_conflict = 'X'.
  ENDIF.

  PERFORM get_default_dates USING
                                     if_use_ta
                            CHANGING i_hist_start
                                     i_hist_end.

  IF lf_by_conflict = 'X'.
    IF if_use_ta IS INITIAL.
      PERFORM stat_analysis
      TABLES
        it_results
        lt_functtran
        it_confdet
      USING
        i_hist_start
        i_hist_end
        i_vrsio.
    ELSE.
      PERFORM ta_stat_analysis
      TABLES
        it_results
        lt_functtran
        lt_services
        it_confdet
      USING
        i_hist_start
        i_hist_end
        i_vrsio
        lf_ta_v21
        l_ta_version.
    ENDIF.
  ELSEIF lf_by_function = 'X'.
    IF if_use_ta IS INITIAL.
      PERFORM stat_analysis_func
      TABLES
        it_funcresults
        lt_functtran
      USING
        i_hist_start
        i_hist_end
        i_vrsio.
    ELSE.
      PERFORM ta_stat_analysis_func
      TABLES
        it_funcresults
        lt_functtran
        lt_services
      USING
        i_hist_start
        i_hist_end
        i_vrsio
        lf_ta_v21
        l_ta_version.
    ENDIF.

  ENDIF.



ENDFUNCTION.
