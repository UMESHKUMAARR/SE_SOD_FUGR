***INCLUDE /PSYNG/SW_063O01 .
*&spwizard: output module for tc 'TC_CUSCON'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_cuscon_change_tc_attr OUTPUT.
  SET TITLEBAR '100' WITH p_vrsio.

  IF gf_dispchg = gc_change.
    SET PF-STATUS '100'.
  ELSEIF gf_auth_mode = gc_change.
    REFRESH gt_excfunc.
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
    SET PF-STATUS '100' EXCLUDING gt_excfunc.
  ELSE.
    REFRESH gt_excfunc.
    gt_excfunc-func = 'SAVE'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'DISPCHG'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'INSR'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'DELE'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'MARK'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'DMRK'.
    APPEND gt_excfunc.
    gt_excfunc-func = 'TRAN'.
    APPEND gt_excfunc.
    SET PF-STATUS '100' EXCLUDING gt_excfunc.
  ENDIF.

  DESCRIBE TABLE gt_cuscon LINES tc_cuscon-lines.
  PERFORM dispchg.
ENDMODULE.

*&spwizard: output module for tc 'TC_CUSCON'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_cuscon_get_lines OUTPUT.
  g_tc_cuscon_lines = sy-loopc.
  PERFORM dispchg.
ENDMODULE.
