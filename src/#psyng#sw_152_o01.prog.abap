*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_152_O01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  DATA: l_latest_aid TYPE char10,
        l_pre_aid    TYPE char10.
  l_latest_aid = g_latest_aid.
  l_pre_aid    = g_pre_aid.
  SHIFT l_latest_aid LEFT DELETING LEADING '0'.
  SHIFT l_pre_aid LEFT DELETING LEADING '0'.
  SET PF-STATUS 'PF0100'.
  SET TITLEBAR 'T0100' WITH l_latest_aid l_pre_aid.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV_100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_100 OUTPUT.
*Display ALV
  IF g_view EQ 'C'.
    PERFORM display_alv_100.
  ELSEIF g_view EQ 'U'.
    PERFORM display_alv_usrv_100.
  ELSEIF g_view EQ 'UC'.
    PERFORM display_alv_usrconv_100 TABLES gt_detail_usrcon_view.
  ENDIF.
ENDMODULE.
