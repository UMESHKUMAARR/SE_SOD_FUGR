*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_NAV_CON_TOP
*&---------------------------------------------------------------------*

DATA : l_uname TYPE xubname,
       l_parva        TYPE usr05-parva,
       l_parva_exists LIKE sy-subrc,
       g_dynnr               TYPE sy-dynnr,
       l_sod          TYPE /psyng/sodvrsio.

DATA : g_macro_cfg_value TYPE /psyng/param_value,
       g_macro_cfg_param TYPE /psyng/param.
*--Get the value of a configuration parameter
*  Usage Example : se_config_param 'ORG_LEVEL' l_value.
DEFINE se_config_param.
  g_macro_cfg_param = &1.
  call function '/PSYNG/SW_GET_CONFIG'           "#EC SAST_CI_GEN_CHECK
       exporting
            i_parameter = g_macro_cfg_param
       importing
            e_value     = g_macro_cfg_value
       exceptions
*            CALL_FUNCTION_NOT_FOUND    = 1
*            CALL_FUNCTION_PARM_MISSING = 2
*            others                     = 3.
            others                     = 1.
  move g_macro_cfg_value to &2.
END-OF-DEFINITION.
