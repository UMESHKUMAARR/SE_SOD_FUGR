*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_LOCCFGO01 .
*----------------------------------------------------------------------*
*&spwizard: output module for tc 'TC_ORGNR_UG'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_orgnr_ug_change_tc_attr OUTPUT.
  SET PF-STATUS '100'.
  DESCRIBE TABLE gt_orgnr_ug LINES tc_orgnr_ug-lines.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_ORGNR_UG'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_orgnr_ug_get_lines OUTPUT.
  g_tc_orgnr_ug_lines = sy-loopc.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_ORGNR_ADR'. do not change thisline!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_orgnr_adr_change_tc_attr OUTPUT.
  SET PF-STATUS '100'.
  DESCRIBE TABLE gt_orgnr_adr LINES tc_orgnr_adr-lines.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_ORGNR_ADR'. do not change thisline!
*&spwizard: get lines of tablecontrol
MODULE tc_orgnr_adr_get_lines OUTPUT.
  g_tc_orgnr_adr_lines = sy-loopc.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_LOCCFG'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_loccfg_change_tc_attr OUTPUT.
  SET PF-STATUS '100'.
  DESCRIBE TABLE gt_loccfg LINES tc_loccfg-lines.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_LOCCFG'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_loccfg_get_lines OUTPUT.
  g_tc_loccfg_lines = sy-loopc.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_ORGNR_USR'. do not change thisline!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_orgnr_usr_change_tc_attr OUTPUT.
  SET PF-STATUS '100'.
  DESCRIBE TABLE gt_orgnr_usr LINES tc_orgnr_usr-lines.
  PERFORM toggle_display_change.
ENDMODULE.

*&spwizard: output module for tc 'TC_ORGNR_USR'. do not change thisline!
*&spwizard: get lines of tablecontrol
MODULE tc_orgnr_usr_get_lines OUTPUT.
  g_tc_orgnr_usr_lines = sy-loopc.
  PERFORM toggle_display_change.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  STATUS_9000  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for screen 9000
*----------------------------------------------------------------------*
MODULE status_9000 OUTPUT.
  gt_excfunc-func = 'INSR'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DELE'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'DWNLD'.
  APPEND gt_excfunc.
  gt_excfunc-func = 'UPLD'.
  APPEND gt_excfunc.
  SET PF-STATUS '100' EXCLUDING gt_excfunc.
ENDMODULE.                 " status_9000  OUTPUT
