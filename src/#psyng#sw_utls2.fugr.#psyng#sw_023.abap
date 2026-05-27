FUNCTION /psyng/sw_023.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCR_TAB_T
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR_T
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------
  DATA: ltab    TYPE TABLE OF /psyng/swsodorgm,
        l_tabix TYPE i,
        ls_opt TYPE ddshselopt.
    RANGES: r_org_val FOR /psyng/swsodorgm-abb.
    DATA: ls_ddshiface TYPE ddshiface.


  IF callcontrol-step <> 'DISP'.
    EXIT.
  ENDIF.
*"----------------------------------------------------------------------
* STEP DISP     (Display values)
*"----------------------------------------------------------------------
* We want to display only unique org levels
  IF callcontrol-step = 'DISP'.
*    SELECT * INTO TABLE ltab FROM /psyng/swsodorgm.

*filter data based on user input
*MMEHTO 03032018
*--------------------------------------

    LOOP AT shlp-selopt INTO ls_opt.
      CASE ls_opt-shlpfield.
        WHEN 'ABB'.
          r_org_val-sign = ls_opt-sign.
          r_org_val-option = ls_opt-option.
          r_org_val-low = ls_opt-low.
          r_org_val-high = ls_opt-high.
          COLLECT  r_org_val.
      ENDCASE.
    ENDLOOP.

    SELECT * INTO TABLE ltab FROM /psyng/swsodorgm
    WHERE abb IN r_org_val.


    SORT ltab BY abb.
    DELETE ADJACENT DUPLICATES FROM ltab COMPARING abb.
    REFRESH record_tab[].
    APPEND LINES OF ltab TO record_tab.
    free ltab[].

    DESCRIBE TABLE record_tab LINES sy-tfill.
    IF sy-tfill > callcontrol-maxrecords.
      l_tabix = callcontrol-maxrecords + 1.
      LOOP AT record_tab FROM l_tabix.
        DELETE record_tab.
      ENDLOOP.
    ENDIF.

    EXIT.
  ENDIF.
ENDFUNCTION.
