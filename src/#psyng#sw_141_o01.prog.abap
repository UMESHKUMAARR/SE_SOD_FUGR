*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_141_O01                                          *
*----------------------------------------------------------------------*

MODULE status_0100 OUTPUT.

  DATA: BEGIN OF lt_func OCCURS 0,
        fcode LIKE rsmpe-func,
      END OF lt_func.

  DATA : lf_cfg_set_dist_rest TYPE flag,
        lf_cfgset_enable  TYPE flag.

  se_config_param 'CFG_SET_DIST_REST' lf_cfg_set_dist_rest.
  se_config_param 'CFG_SET_ENABLED' lf_cfgset_enable.

  IF lf_cfg_set_dist_rest EQ 'N'.
    lt_func-fcode = 'PUBACCESS'.
    APPEND lt_func.
  ENDIF.

  IF lf_cfgset_enable = 'N'.
    lt_func-fcode = 'PUBLISH'.
    APPEND lt_func.
    READ TABLE lt_func WITH KEY
           fcode = 'PUBACCESS'.
    IF sy-subrc <> 0.
      lt_func-fcode = 'PUBACCESS'.
      APPEND lt_func.
    ENDIF.
  ENDIF.

  SET PF-STATUS '0100' EXCLUDING lt_func.
  SET TITLEBAR '0100'.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE STATUS_0101                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  DATA : l_sysid TYPE /psyng/sw_rfcdes-systid.
  CLEAR l_sysid.
  SET PF-STATUS '0101'.

  IF gt_output-systid IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO l_sysid.
  ELSE.
    l_sysid = gt_output-systid.
  ENDIF.
  SET TITLEBAR '0101' WITH gt_output-systid.
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
*       MODULE display_alv_101 OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_alv_101 OUTPUT.
  PERFORM display_alv_101.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_data OUTPUT                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE load_data OUTPUT.
  PERFORM load_data.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE load_data_101 OUTPUT                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*MODULE load_data_101 OUTPUT.
*  PERFORM load_data_101.
*ENDMODULE.

*MODULE status_0102 OUTPUT.
*  SET PF-STATUS '0102'.
*ENDMODULE.
