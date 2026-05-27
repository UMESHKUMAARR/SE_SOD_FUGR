*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_138_O01                                          *
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  if  g_loaded_first is initial.
    G_FLTR_ALL_SET = 'X'."default to all config sets
  endif.

*---enable/desable screen field
  LOOP AT SCREEN.
    IF screen-name = '/PSYNG/SWRRSHDR-SODVRSIO'.
      IF g_fltr_all_vrsio = 'X'.
        screen-input = 0.
        CLEAR /psyng/swrrshdr-sodvrsio.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name = '/PSYNG/SWRRSHDR-SETID'.
      IF  g_fltr_all_set = 'X'.
        screen-input = 0.
        CLEAR /psyng/swrrshdr-setid.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  SET PF-STATUS '0100'.
  SET TITLEBAR '100'.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE display_alv_100 OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_alv_100 OUTPUT.
  PERFORM display_alv_100.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_data_100 OUTPUT                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE load_data_100 OUTPUT.
  PERFORM load_data_100.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE fill_dropdown_values OUTPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE fill_dropdown_values OUTPUT.
  PERFORM fill_dropdown_values.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_default_filter OUTPUT                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE load_default_values OUTPUT.

  IF NOT gt_resultset[] IS INITIAL AND g_loaded_first IS INITIAL.
*---system
    g_fltr_system = 'All Systems'.
**---analysis started
    g_fltr_ana_strt_in = 'This Month'.
*--Default sod vrsio
*-- should fill sod version like others report
*      se_config_param 'DFLT_GLOBAL_VERSION' /psyng/swreshdr-sodvrsio.
*    CALL FUNCTION '/PSYNG/SW_034'
*      IMPORTING
*        e_vrsio = /psyng/swrrshdr-sodvrsio.
/psyng/swrrshdr-sodvrsio = g_vrsio.
*--default to the latest published configuration set (highest nr)
    CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      EXPORTING
        i_vrsio      = 'X'
        i_cfgvrsio   = /psyng/swrrshdr-sodvrsio
      IMPORTING
        e_config_set = /psyng/swrrshdr-setid.

    g_loaded_first = 'X'.
  ENDIF.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE f4_bname INPUT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE f4_bname INPUT.
  PERFORM f4_bname.
ENDMODULE.
