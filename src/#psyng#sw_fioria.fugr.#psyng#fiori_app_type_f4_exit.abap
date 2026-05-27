FUNCTION /psyng/fiori_app_type_f4_exit.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      SHLP_TAB TYPE  SHLP_DESCR_TAB_T
*"      RECORD_TAB STRUCTURE  SEAHLPRES
*"  CHANGING
*"     VALUE(SHLP) TYPE  SHLP_DESCR_T
*"     VALUE(CALLCONTROL) LIKE  DDSHF4CTRL STRUCTURE  DDSHF4CTRL
*"----------------------------------------------------------------------

  TYPES: BEGIN OF ty_fioria,
           applicationtype TYPE /psyng/sw_fiori_app_type,
         END OF ty_fioria.

  DATA: lt_fioria TYPE TABLE OF ty_fioria,
        ls_fioria TYPE ty_fioria,
        l_records     TYPE i.

  DATA: ls_record_tab TYPE seahlpres,
        ls_selopt     TYPE ddshselopt.

  RANGES :
     lr_app_type       FOR /psyng/sw_fioria-applicationtype.

*--create ranges
  LOOP AT shlp-selopt INTO ls_selopt.
    CASE ls_selopt-shlpfield.
      WHEN 'APPLICATIONTYPE'.
        MOVE-CORRESPONDING ls_selopt TO lr_app_type.
        COLLECT lr_app_type.
    ENDCASE.
  ENDLOOP.

  IF callcontrol-step = 'SELECT'.
*--Restrict the values on user input
    CALL FUNCTION 'F4UT_RESULTS_MAP'
         EXPORTING
              source_structure   = '/PSYNG/SW_FIORIA'
              apply_restrictions = 'X'
         TABLES
              shlp_tab           = shlp_tab
              record_tab         = record_tab
              source_tab         = lt_fioria
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


  callcontrol-top_shlp = '/PSYNG/FIORI_APP_TYPE_F4_EXIT'.
  callcontrol-sortoff = 'X'.
  IF callcontrol-top_shlp = '/PSYNG/FIORI_APP_TYPE_F4_EXIT'.
    IF callcontrol-step = 'DISP'.

*---Get DB record
      SELECT DISTINCT applicationtype
      INTO TABLE lt_fioria
      FROM /psyng/sw_fioria
      WHERE applicationtype IN lr_app_type.

      SORT lt_fioria BY applicationtype.
      DELETE lt_fioria WHERE applicationtype EQ ''.
      REFRESH record_tab.
      LOOP AT lt_fioria INTO ls_fioria.
        MOVE ls_fioria TO ls_record_tab.
        APPEND ls_record_tab TO record_tab.
        CLEAR ls_record_tab.
        CLEAR ls_fioria.
      ENDLOOP.
*      LOOP AT record_tab INTO record_tab.
*        ls_fioria = record_tab.
*        IF NOT ls_fioria-applicationtype IS INITIAL.
*          APPEND ls_fioria TO lt_fioria.
*        ENDIF.
*      ENDLOOP.
*      SORT lt_fioria BY applicationtype.
*      DELETE ADJACENT DUPLICATES FROM lt_fioria
*      COMPARING applicationtype.
*      REFRESH : record_tab.
*      LOOP AT lt_fioria INTO ls_fioria.
*        record_tab = ls_fioria.
*        APPEND record_tab TO record_tab.
*      ENDLOOP.
      SORT record_tab.
      DESCRIBE TABLE record_tab LINES l_records.
      IF l_records > callcontrol-maxrecords.
        l_records = callcontrol-maxrecords + 1.
        DELETE record_tab FROM l_records.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFUNCTION.
