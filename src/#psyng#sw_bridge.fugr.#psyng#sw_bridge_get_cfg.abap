FUNCTION /PSYNG/SW_BRIDGE_GET_CFG.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  EXPORTING
*"     REFERENCE(E_HOST) TYPE  STRING
*"     REFERENCE(E_PORT) TYPE  STRING
*"     REFERENCE(E_USER) TYPE  STRING
*"     REFERENCE(E_PASS) TYPE  STRING
*"----------------------------------------------------------------------

  DATA:
        lt_cfg TYPE TABLE OF /psyng/bridgecfg,
        ls_cfg TYPE /psyng/bridgecfg,
        l_pass TYPE c LENGTH 55.

  SELECT *
    FROM /psyng/bridgecfg
    INTO TABLE lt_cfg.

  IF sy-subrc = 0.
    LOOP AT lt_cfg INTO ls_cfg.
      IF ls_cfg-param = 'Hostname'.
        e_host = ls_cfg-value.
      ELSEIF ls_cfg-param = 'Username'.
        e_user = ls_cfg-value.
      ELSEIF ls_cfg-param = 'Password'.
        PERFORM decrypt_password USING ls_cfg-value
                                 CHANGING l_pass.
        e_pass = l_pass.
      ELSEIF ls_cfg-param = 'Port'.
        e_port = ls_cfg-value.
      ENDIF.
    ENDLOOP.
  ELSE.
    CLEAR: e_host, e_user, e_pass, e_port.
  ENDIF.



ENDFUNCTION.
