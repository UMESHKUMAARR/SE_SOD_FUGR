FUNCTION /PSYNG/SW_VE_SEARCH_EXIT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCR_TAB_T OPTIONAL
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     REFERENCE(SHLP) TYPE  SHLP_DESCR_T
*"     REFERENCE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------
data : lt_varel type table of /psyng/sw_varel with header line.
case callcontrol-step.
  when 'DISP'.
    loop at record_tab.
      lt_varel = record_tab .
      append lt_varel.
    endloop.
    sort lt_varel by var_element.
    delete adjacent duplicates from lt_varel comparing var_element.
    refresh : RECORD_TAB.
    loop at lt_varel.
      record_tab = lt_varel.
      append record_tab.
    endloop.
  when 'EXIT'.
*--No changes
endcase.



ENDFUNCTION.
