*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_097O01                                           *
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       MODULE TC_REMCON_change_tc_attr OUTPUT                        *
*---------------------------------------------------------------------*
MODULE tc_remcon_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_remcon LINES tc_remcon-lines.

  IF gf_dispchg = gc_change.
    SET PF-STATUS 'MAIN'.
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
    SET PF-STATUS 'MAIN' EXCLUDING gt_excfunc.
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
    SET PF-STATUS 'MAIN' EXCLUDING gt_excfunc.
  ENDIF.

  PERFORM dispchg.
  SET TITLEBAR 'MAIN'.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE TC_REMCON_get_lines OUTPUT                             *
*---------------------------------------------------------------------*
MODULE tc_remcon_get_lines OUTPUT.
  g_tc_lines = sy-loopc.
  PERFORM dispchg.
ENDMODULE.
