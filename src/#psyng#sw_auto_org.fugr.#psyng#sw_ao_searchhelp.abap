FUNCTION /PSYNG/SW_AO_SEARCHHELP.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_CFG_SET) TYPE  /PSYNG/SECONFID
*"  EXPORTING
*"     REFERENCE(E_ORGLVL) TYPE  /PSYNG/DORG_ABB
*"----------------------------------------------------------------------

  DATA : lt_ret TYPE TABLE OF ddshretval WITH HEADER LINE,
         lt_ao  TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
         begin of lt_abb occurs 0,
           abb type /psyng/dorg_abb,
         end of lt_abb,
         lf_cfg_set_enabled TYPE flag.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.

  IF lf_cfg_set_enabled = 'X' or lf_cfg_set_enabled = 'Y'.


    CALL FUNCTION '/PSYNG/SW_AO_READ'
     EXPORTING
       if_read                   = 'X'
       i_setid                   = i_cfg_set
     TABLES
       et_org_values             = lt_ao
            .
    sort lt_ao by abb.
    delete adjacent duplicates from lt_ao comparing abb.
    loop at lt_ao.
      lt_abb-abb = lt_ao-abb.
      append lt_abb.
    endloop.
    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
         EXPORTING
              retfield        = 'ABB'
              value_org       = 'S'
              window_title    = 'Title'
         TABLES
              value_tab       = lt_abb
              return_tab      = lt_ret
         EXCEPTIONS
              parameter_error = 1
              no_values_found = 2
              OTHERS          = 3.
    IF sy-subrc = 0.
      LOOP AT lt_ret.
        E_ORGLVL = lt_ret-fieldval.
      ENDLOOP.
    ENDIF.

  ELSE.
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
         EXPORTING
              tabname           = '/PSYNG/SWSODORGM'
              fieldname         = 'ABB'
         TABLES
              return_tab        = lt_ret
         EXCEPTIONS
              field_not_found   = 1
              no_help_for_field = 2
              inconsistent_help = 3
              no_values_found   = 4
              OTHERS            = 5.
    IF sy-subrc = 0.
      LOOP AT lt_ret.
        e_orglvl = lt_ret-fieldval.
      ENDLOOP.
    ENDIF.

  ENDIF.




ENDFUNCTION.
