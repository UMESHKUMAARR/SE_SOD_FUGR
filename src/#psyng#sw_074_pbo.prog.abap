*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_074_PBO .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module STATUS_0100 output.
  SET PF-STATUS '100'.
  perform toggle_display_change.
endmodule.                 " STATUS_0100  OUTPUT

*&spwizard: output module for tc 'TC_EXCLUDE'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
module TC_EXCLUDE_change_tc_attr output.
  describe table GT_TC_EXCLUDE lines TC_EXCLUDE-lines.
endmodule.

*&spwizard: output module for tc 'TC_EXCLUDE'. do not change this line!
*&spwizard: get lines of tablecontrol
module TC_EXCLUDE_get_lines output.
  g_TC_EXCLUDE_lines = sy-loopc.
endmodule.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module STATUS_0200 output.
  gt_excfunc-func = 'INSR'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DELE'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DWNLD'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'UPLD'.
  APPEND gt_excfunc.
  SET PF-STATUS '100' EXCLUDING gt_excfunc.

endmodule.                 " STATUS_0200  OUTPUT
