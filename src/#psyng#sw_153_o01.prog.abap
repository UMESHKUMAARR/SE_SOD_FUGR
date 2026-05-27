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
  IF NOT g_confv IS INITIAL.
  PERFORM display_alv_100.
  ELSE.
    PERFORM display_alv_rolv_100.
  ENDIF.
ENDMODULE.
