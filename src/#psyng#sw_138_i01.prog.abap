*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_138_I01                                          *
*----------------------------------------------------------------------*

MODULE check_setid_warning INPUT.
*--check warning msg for config set & versio
  IF g_preconfig <> /psyng/swreshdr-setid.
    CLEAR g_warning_msg.
  ENDIF.

  IF g_warning_msg IS INITIAL.
*--Check Config Set
    g_warning_msg = 'X'.
    g_preconfig = /psyng/swreshdr-setid.

    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
        i_setid         = /psyng/swreshdr-setid
        i_vrsio         = /psyng/swreshdr-sodvrsio
        if_show_warning = 'X'.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0100 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
* BOC by RGUPTA on 28.03.22 for C0700
DATA: l_current_user type sy-uname.

  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
  CASE sy-ucomm.
    WHEN 'MINE'.
      CLEAR /psyng/swreshdr-bname.
      /psyng/swreshdr-bname = l_current_user. "sy-uname. C0700
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'LCL_SYS'.
      CONCATENATE sy-sysid sy-mandt INTO g_fltr_system.
    WHEN 'NEW_ANA'.
      SUBMIT /psyng/sw_140

              VIA SELECTION-SCREEN
              with p_vrsio = g_vrsio
              AND RETURN.

      REFRESH gt_resultset.
      PERFORM load_data_100.
      CALL METHOD gr_alvgrid->refresh_table_display
        EXPORTING
          i_soft_refresh = 'X'
        EXCEPTIONS
          finished       = 1
          OTHERS         = 2.
    WHEN 'INFO'.
      CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
        EXPORTING
          dokname = '/PSYNG/SW_138'.

  ENDCASE.
ENDMODULE.
