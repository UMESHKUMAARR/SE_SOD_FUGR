***INCLUDE /PSYNG/SW_084O01 .
*&spwizard: output module for tc 'TC_SODVERS'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_sodvers_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_sodvers LINES tc_sodvers-lines.
  PERFORM dispchg.
ENDMODULE.

*&spwizard: output module for tc 'TC_SODVERS'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_sodvers_get_lines OUTPUT.
  g_lines = sy-loopc.

* No editing of version 000 or 999
  IF ( gt_sodvers-vrsio = '000' OR gt_sodvers-vrsio = '999' )
  AND NOT gt_sodvers-vdesc IS INITIAL.
    LOOP AT SCREEN.
      CHECK screen-group1 = 'MOD' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
* Row just inserted
  ELSEIF gt_sodvers-vrsio = '000' AND gt_sodvers-vdesc IS INITIAL
  AND NOT gt_sodvers[] IS INITIAL.
    LOOP AT SCREEN.
      CHECK screen-group1 = 'KEY'.
      screen-input = 1.
      MODIFY screen.
    ENDLOOP.
  ELSE.
    PERFORM dispchg.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       Set PBO status for screen 100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET TITLEBAR 'MAIN'.

  REFRESH gt_excfunc.
  IF gf_dispchg = gc_change.           "Change mode
    IF gf_del_auth <> 'X'.             "No delete authority
      gt_excfunc-func = 'DELE'.
      APPEND gt_excfunc.
    ENDIF.
  ELSE.                                "Display
    IF gf_auth_mode = gc_display.      "Display only
      gt_excfunc-func = 'DISPCHG'.
      APPEND gt_excfunc.
    ENDIF.

    gt_excfunc-func = 'SAVE'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'INSR'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'DELE'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'MARK'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'DMRK'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'COPY'.
    APPEND gt_excfunc.
  ENDIF.

  SET PF-STATUS 'MAIN' EXCLUDING gt_excfunc.
ENDMODULE.                 " STATUS_0100  OUTPUT
