FUNCTION /PSYNG/VRSIO_F4_EXIT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCR_TAB_T
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR_T
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_vrsio_display,
           vrsio   TYPE /psyng/sodvrsio,
           vdesc   TYPE /psyng/desc132,
           default TYPE /psyng/bapiflagx,
         END OF ty_vrsio_display.

  DATA: lt_vrsio_display TYPE TABLE OF ty_vrsio_display,
        ls_vrsio_display TYPE ty_vrsio_display.
  FIELD-SYMBOLS: <fs_vrsio_display> TYPE ty_vrsio_display,
                 <fs_fielddescr>    TYPE dfies.

  DATA: ls_record_tab TYPE seahlpres,
        ls_selopt     TYPE ddshselopt,
        l_dflt_vrsio  TYPE /psyng/param.

  RANGES :
    lr_vrsio       FOR /psyng/swsodvers-vrsio,
    lr_vdesc       FOR /psyng/swsodvers-vdesc,
    lr_default     FOR /psyng/swsodvers-noedit.

*--create ranges
  LOOP AT shlp-selopt INTO ls_selopt.
    CASE ls_selopt-shlpfield.
      WHEN 'VRSIO'.
        MOVE-CORRESPONDING ls_selopt TO lr_vrsio.
        COLLECT lr_vrsio.
      WHEN 'VDESC'.
        MOVE-CORRESPONDING ls_selopt TO lr_vdesc.
        COLLECT lr_vdesc.
      WHEN 'DEFAULT'.
        MOVE-CORRESPONDING ls_selopt TO lr_default.
        COLLECT lr_default.
    ENDCASE.
  ENDLOOP.

  LOOP AT shlp-fielddescr ASSIGNING <fs_fielddescr>.
    IF <fs_fielddescr>-fieldname EQ 'DEFAULT'.
      <fs_fielddescr>-headlen   = 16.
      <fs_fielddescr>-scrlen1   = 16.
      <fs_fielddescr>-scrlen2   = 16.
      <fs_fielddescr>-scrlen3   = 16.
      <fs_fielddescr>-reptext   = 'Default Version'(t01).
      <fs_fielddescr>-scrtext_s = 'Default'(t02).
      <fs_fielddescr>-scrtext_m = 'Default Version'(t01).
      <fs_fielddescr>-scrtext_l = 'Default Version'(t01).
    ENDIF.
  ENDLOOP.

  IF callcontrol-step = 'SELECT'.
*--Restrict the values on user input
    CALL FUNCTION 'F4UT_RESULTS_MAP'
         EXPORTING
              source_structure   = '/PSYNG/SWSODVERS'
              apply_restrictions = 'X'
         TABLES
              shlp_tab           = shlp_tab
              record_tab         = record_tab
              source_tab         = lt_vrsio_display
         CHANGING
              shlp               = shlp
              callcontrol        = callcontrol
         EXCEPTIONS
              illegal_structure  = 1
              OTHERS             = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

  callcontrol-top_shlp = '/PSYNG/VRSIO_F4_EXIT'.
  callcontrol-sortoff = 'X'.
  IF callcontrol-top_shlp = '/PSYNG/VRSIO_F4_EXIT'.
    IF callcontrol-step = 'DISP'.
*---Get DB record
      SELECT vrsio vdesc
      INTO CORRESPONDING FIELDS OF TABLE lt_vrsio_display
      FROM /psyng/swsodvers
      WHERE vrsio IN lr_vrsio
        AND vdesc IN lr_vdesc.
      SORT lt_vrsio_display BY vrsio.
*--Get default version
      se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
      READ TABLE lt_vrsio_display ASSIGNING <fs_vrsio_display>
        WITH KEY vrsio = l_dflt_vrsio
        BINARY SEARCH.
      IF sy-subrc EQ 0.
        <fs_vrsio_display>-default = 'X'.
      ENDIF.
      SORT lt_vrsio_display BY vrsio.
      LOOP AT lt_vrsio_display INTO ls_vrsio_display.
        IF ls_vrsio_display-default IN lr_default.
          MOVE ls_vrsio_display TO ls_record_tab.
          APPEND ls_record_tab TO record_tab.
          CLEAR ls_record_tab.
          CLEAR ls_vrsio_display.
        ENDIF.
      ENDLOOP.
      SORT record_tab.
    ENDIF.
  ENDIF.


ENDFUNCTION.
