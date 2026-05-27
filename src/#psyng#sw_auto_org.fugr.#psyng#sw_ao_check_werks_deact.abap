FUNCTION /psyng/sw_ao_check_werks_deact.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_BUKRS) TYPE  /PSYNG/TCODE_BKPF
*"     VALUE(I_WERKS) TYPE  /PSYNG/TCODE_BKPF
*"  TABLES
*"      IT_ORGVALUES STRUCTURE  /PSYNG/SWCFGOE
*"      ET_DEACTIVATE STRUCTURE  /PSYNG/SWCFGOE
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_CHECK_WERKS_DEACT'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA : ls_tadir TYPE tadir,
         lf_t024e TYPE flag,
         lf_t024w TYPE flag,
         lf_tvswz TYPE flag,
         BEGIN OF lt_ekorg OCCURS 0,
           ekorg(4) TYPE c,
         END OF lt_ekorg,
         BEGIN OF lt_ekorg_bukrs OCCURS 0,
           ekorg(4) TYPE c,
         END OF lt_ekorg_bukrs,
         BEGIN OF lt_ekorg_werks OCCURS 0,
           ekorg(4) TYPE c,
         END OF lt_ekorg_werks,
         BEGIN OF lt_werks OCCURS 0,
           werks(4) TYPE c,
         END OF lt_werks,
         BEGIN OF lt_vstel OCCURS 0,
           vstel(4) TYPE c,
         END OF lt_vstel,
         BEGIN OF lt_vstel_werks OCCURS 0,
           vstel(4) TYPE c,
         END OF lt_vstel_werks.

*--Check if Tables exist
  SELECT SINGLE obj_name FROM tadir
  INTO CORRESPONDING FIELDS OF ls_tadir
  WHERE object = 'TABL' AND obj_name = 'T024E'.
  IF sy-subrc = 0.
    lf_t024e = 'X'.
  ENDIF.
  SELECT SINGLE obj_name FROM tadir
  INTO CORRESPONDING FIELDS OF ls_tadir
  WHERE object = 'TABL' AND obj_name = 'T024W'.
  IF sy-subrc = 0.
    lf_t024w = 'X'.
  ENDIF.
  SELECT SINGLE obj_name FROM tadir
  INTO CORRESPONDING FIELDS OF ls_tadir
  WHERE object = 'TABL' AND obj_name = 'TVSWZ'.
  IF sy-subrc = 0.
    lf_tvswz = 'X'.
  ENDIF.
  IF lf_t024e = 'X'.
    ls_tadir-obj_name = 'T024W'.
*--   find all ekorg tied to this werks
    SELECT ekorg FROM (ls_tadir-obj_name) INTO TABLE lt_ekorg
"#EC SAST_CI_GEN_CHECK
      WHERE werks = i_werks.
  ENDIF.
*-- find all VSTEl tied to this werks
  IF lf_tvswz = 'X'.
    ls_tadir-obj_name = 'TVSWZ'.
    SELECT vstel FROM (ls_tadir-obj_name) INTO TABLE lt_vstel
"#EC SAST_CI_GEN_CHECK
      WHERE werks = i_werks.
  ENDIF.

*-- check which ekorgs are tied to the BUKRS
  IF NOT lt_ekorg[] IS INITIAL .
    IF lf_t024e = 'X'.
      ls_tadir-obj_name = 'T024E'.
      SELECT ekorg FROM (ls_tadir-obj_name) INTO TABLE lt_ekorg_bukrs
"#EC SAST_CI_GEN_CHECK
        FOR ALL ENTRIES IN  lt_ekorg WHERE
          bukrs =  i_bukrs AND
          ekorg =  lt_ekorg-ekorg.
      IF sy-subrc = 0.
        LOOP AT lt_ekorg_bukrs.
          DELETE lt_ekorg WHERE ekorg = lt_ekorg_bukrs-ekorg.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.



  IF NOT lt_ekorg[] IS INITIAL OR NOT lt_vstel[] IS INITIAL.
*--     check which other plants are in this BUKRS (that are active)
    LOOP AT it_orgvalues WHERE abb    = i_bukrs AND
                               varbl  = 'WERKS' AND
                               active = 'X'.
      lt_werks-werks = it_orgvalues-value.
      APPEND lt_werks.
    ENDLOOP.

  ENDIF.

  IF NOT lt_werks[] IS INITIAL.
    SORT lt_werks.
    DELETE ADJACENT DUPLICATES FROM lt_werks.
*--Don't disable ekorgs tied to other plants
    IF lf_t024w = 'X'.
      ls_tadir-obj_name = 'T024W'.
      SELECT ekorg FROM (ls_tadir-obj_name) INTO TABLE lt_ekorg_werks
"#EC SAST_CI_GEN_CHECK
        FOR ALL ENTRIES IN  lt_werks WHERE
          werks =  lt_werks-werks.
      IF sy-subrc = 0.
        LOOP AT lt_ekorg_werks.
          DELETE lt_ekorg WHERE ekorg = lt_ekorg_werks-ekorg.
        ENDLOOP.
      ENDIF.
    ENDIF.
*--Don't disable VSTELS tied to other plants
    IF lf_tvswz = 'X' AND NOT lt_vstel[] IS INITIAL.
      ls_tadir-obj_name = 'TVSWZ'.
      SELECT vstel FROM (ls_tadir-obj_name) INTO TABLE lt_vstel_werks
"#EC SAST_CI_GEN_CHECK
        FOR ALL ENTRIES IN  lt_werks WHERE
          werks =  lt_werks-werks.
      IF sy-subrc = 0.
        LOOP AT lt_vstel_werks.
          DELETE lt_vstel WHERE vstel = lt_vstel_werks-vstel.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.
*--Now lt_ekorg has all ekorgs that should be deactivated for this company code
  LOOP AT lt_ekorg.
    READ TABLE it_orgvalues WITH KEY abb    = i_bukrs
                                     varbl  = 'EKORG'
                                     value  = lt_ekorg-ekorg
                                     active = 'X'.
    IF sy-subrc = 0.
      APPEND it_orgvalues TO et_deactivate.
    ENDIF.
  ENDLOOP.
*--Now lt_vstel has all vstels that should be deactivated for this company code
  LOOP AT lt_vstel.
    READ TABLE it_orgvalues WITH KEY abb    = i_bukrs
                                     varbl  = 'VSTEL'
                                     value  = lt_vstel-vstel
                                     active = 'X'.
    IF sy-subrc = 0.
      APPEND it_orgvalues TO et_deactivate.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.
