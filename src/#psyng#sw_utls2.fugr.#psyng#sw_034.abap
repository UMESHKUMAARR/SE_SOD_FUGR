FUNCTION /psyng/sw_034.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     REFERENCE(E_VRSIO) TYPE  /PSYNG/SWSODVERS-VRSIO
*"----------------------------------------------------------------------
DATA: l_parva TYPE usr05-parva,
      l_value TYPE /psyng/swconfig-value.
* BOC by RGUPTA on 08.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 08.04.22 for C0700

* Get user's default version
  SELECT SINGLE parva INTO l_parva FROM usr05
                WHERE bname = l_current_user "sy-uname C0700
                  AND parid = '/PSYNG/VRSIO'.

  IF sy-subrc = 0 AND l_parva <> space.
*   Check if this version is still valid
    SELECT SINGLE mandt INTO sy-mandt     "#EC CI_SEL_NESTED
          FROM /psyng/swsodvers
                  WHERE vrsio = l_parva.
    IF sy-subrc = 0.
      e_vrsio = l_parva.
      EXIT.
    ENDIF.
  ENDIF.

* If user's version is not found or not valid, get global default
  se_config_param 'DFLT_GLOBAL_VERSION' l_value.
*   Check if this version is still valid
    SELECT SINGLE mandt INTO sy-mandt     "#EC CI_SEL_NESTED
                 FROM /psyng/swsodvers
                  WHERE vrsio = l_value.
    IF sy-subrc = 0.
      e_vrsio = l_value.
      EXIT.
    ENDIF.
ENDFUNCTION.
