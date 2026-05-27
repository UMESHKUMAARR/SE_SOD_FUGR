***INCLUDE /PSYNG/SW_CONFIG.

DATA : g_macro_cfg_value TYPE /psyng/param_value,
       g_macro_cfg_param TYPE /PSYNG/PARAM.
*--Get the value of a configuration parameter
*  Usage Example : se_config_param 'ORG_LEVEL' l_value.
DEFINE se_config_param.
  g_macro_cfg_param = &1.
  call function '/PSYNG/SW_GET_CONFIG' "#EC SAST_CI_GEN_CHECK
       exporting
            i_parameter = g_macro_cfg_param
       importing
            e_value     = g_macro_cfg_value
       exceptions
*            CALL_FUNCTION_NOT_FOUND    = 1
*            CALL_FUNCTION_PARM_MISSING = 2
*            others                     = 3.
            others                     = 1.
       if sy-subrc <> 0.
        CASE sy-subrc.
*         WHEN 1.
*         message w002(/psyng/sw) with
*         'Function "/PSYNG/SW_GET_CONFIG" does not exist'.
*         WHEN 2.
*         message w002(/psyng/sw) with
*         'Error Reading configuration parameter ' &1.
         WHEN OTHERS.
         message w002(/psyng/sw) with
         'Unknown Error'.
        ENDCASE.
       endif.
  move g_macro_cfg_value to &2.
END-OF-DEFINITION.
