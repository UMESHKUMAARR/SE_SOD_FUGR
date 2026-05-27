*----------------------------------------------------------------------
*
*   INCLUDE /PSYNG/LSWO01
*
*----------------------------------------------------------------------
*
*&---------------------------------------------------------------------
*
*&      Module  init_1000  OUTPUT
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
MODULE init_1000 OUTPUT.
  SET PF-STATUS '1000'.
  PERFORM init_editor.
  DESCRIBE TABLE gt_tstct LINES tc_tstct-lines.
  DESCRIBE TABLE gt_funct LINES tc_funct-lines.
ENDMODULE.                 " init_1000  OUTPUT

*&---------------------------------------------------------------------
*
*&      Module  init_1100  OUTPUT
*&---------------------------------------------------------------------
*
*       PBO for screen 1100
*----------------------------------------------------------------------
*
MODULE init_1100 OUTPUT.
  SET PF-STATUS '1000'.
  PERFORM init_editor.

  DESCRIBE TABLE gt_mctran LINES tc_mctran-lines.
  DESCRIBE TABLE gt_mcauditor LINES tc_mcauditor-lines.
  DESCRIBE TABLE gt_mcrepid LINES tc_mcrepid-lines.


ENDMODULE.                 " init_1100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_critrans  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_critrans OUTPUT.
*  REFRESH gt_critrans.
  CLEAR tc_critcode-lines.
  READ TABLE gt_critcodes INDEX 1.
  SET TITLEBAR '300'
  WITH  'SW: Critical Transaction Report - SOD version'(t01)
  g_vrsio.
  SET PF-STATUS '1000'.
  PERFORM init_editor_1200.
  DESCRIBE TABLE gt_critcodes LINES tc_critcode-lines.

ENDMODULE.                 " init_critrans  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_1201  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_1201 OUTPUT.
  SET PF-STATUS '1201'.
  PERFORM init_editor_1201.
ENDMODULE.                 " init_1201  OUTPUT
