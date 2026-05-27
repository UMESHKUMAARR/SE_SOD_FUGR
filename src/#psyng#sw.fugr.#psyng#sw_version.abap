FUNCTION /PSYNG/SW_VERSION.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     VALUE(E_MODULE) TYPE  /PSYNG/SW_MODULE
*"     REFERENCE(E_MODULE_NAME) TYPE  TTEXT_STCT
*"     VALUE(E_MODULE_VERSION) TYPE  /PSYNG/PROG_VRSIO
*"----------------------------------------------------------------------



  CONSTANTS:lc_module TYPE /psyng/sw_module VALUE 'SE',
            lc_version TYPE /psyng/prog_vrsio VALUE '2026Q1'.

  DATA: l_text  TYPE dd07t-ddtext.
  e_module = lc_module.
  e_module_version = lc_version.



  SELECT SINGLE ddtext INTO l_text FROM dd07t
                WHERE domname    = '/PSYNG/SW_MODULE'
                  AND ddlanguage = sy-langu
                  AND as4local   = 'A'
                  AND domvalue_l = lc_module.
  IF sy-subrc <> 0.
    SELECT SINGLE ddtext INTO l_text FROM dd07t
                  WHERE domname    = '/PSYNG/SW_MODULE'
                    AND ddlanguage = 'EN'
                    AND as4local   = 'A'
                    AND domvalue_l = lc_module.
  ENDIF.
  e_module_name = l_text.
ENDFUNCTION.
