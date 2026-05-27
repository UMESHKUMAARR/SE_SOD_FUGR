FUNCTION /psyng/sw_ao_005.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IV_VALUES) TYPE  FLAG OPTIONAL
*"     VALUE(IV_EKORG) TYPE  FLAG OPTIONAL
*"     VALUE(IV_VKORG) TYPE  FLAG OPTIONAL
*"  TABLES
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_VALUES STRUCTURE  /PSYNG/SW_ORG_VALUES_TEXT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_005'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026


  DATA : lt_ekorg TYPE TABLE OF t_t024e,
         lt_werks TYPE TABLE OF t_t024w,
         l_ret    TYPE bapireturn1,
         lf_valid TYPE flag,
         ls_tadir TYPE tadir,
         lt_vkorg TYPE TABLE OF t_tvta.
  FIELD-SYMBOLS : <ekorg> TYPE t_t024e,
                  <werks> TYPE t_t024w,
                  <vkorg> TYPE t_tvta.
  CONSTANTS : lc_x(1) TYPE c VALUE 'X'.
*--- When Field selected is EKORG
  IF iv_ekorg = lc_x.
*--Check if Tables exist
    SELECT SINGLE obj_name FROM tadir
    INTO CORRESPONDING FIELDS OF ls_tadir
    WHERE object = 'TABL' AND obj_name = 'T024E'.
    IF sy-subrc = 0 AND ls_tadir-obj_name = 'T024E'.
*  --Load EKORGS
      SELECT ekorg bukrs ekotx FROM (CT_T024E) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_ekorg.

*  --Link to plant
      IF iv_values = lc_x.
        SORT lt_ekorg BY ekorg.
      ENDIF.

      SELECT ekorg werks FROM (CT_T024W) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_werks.
      LOOP AT lt_werks ASSIGNING <werks>.
        lf_valid  = lc_x.
*  --Check if EKORG is valid
*  ( there can be a record in T024W for an ekorg that no longer exists)
        READ TABLE lt_ekorg WITH KEY ekorg = <werks>-ekorg
        ASSIGNING <ekorg>
        BINARY SEARCH.
        IF sy-subrc <> 0.
          CLEAR lf_valid.
          log et_return 'I' 'EKORG'  <werks>-ekorg 'INACTIVE'
                                     'Invalid EKORG linked to plant '
                                     <werks>-werks .

        ELSE.
          IF iv_values = lc_x.
*      --Append text values for displaying
            et_values-field = 'EKORG'.
            et_values-vtext = <ekorg>-ekotx.
            et_values-low   = <werks>-ekorg.
            APPEND et_values.
          ENDIF.
*      --Append records for SWSODORGM Table
          et_swsodorgm-abb    = <ekorg>-ekorg.
          et_swsodorgm-varbl  = 'EKORG'.
          et_swsodorgm-value    = <werks>-ekorg.
          APPEND et_swsodorgm.
          et_swsodorgm-varbl  = 'WERKS'.
          et_swsodorgm-value    = <werks>-werks.
          APPEND et_swsodorgm.
        ENDIF.
      ENDLOOP.
    ELSE.
      log et_return 'I' 'EKORG'  'T042E' 'Table does not exist.'
                                 ''
                                 ''.
    ENDIF.

    IF <ekorg> IS ASSIGNED.
      UNASSIGN <ekorg>.
    ENDIF.

*--- When Field selected is VKORG
  ELSEIF iv_vkorg = lc_x.
*--Check if Tables exist
    SELECT SINGLE obj_name FROM tadir
    INTO CORRESPONDING FIELDS OF ls_tadir
    WHERE object = 'TABL' AND obj_name = 'TVTA'.
    IF sy-subrc = 0 AND ls_tadir-obj_name = 'TVTA'.

      SELECT vkorg spart vtweg FROM (CT_TVTA) "#EC SAST_CI_GEN_CHECK
      INTO CORRESPONDING FIELDS OF TABLE lt_vkorg.

      LOOP AT lt_vkorg ASSIGNING <vkorg>.
*  --Append records for SWSODORGM Table
        CONCATENATE <vkorg>-vkorg '-' <vkorg>-spart '-' <vkorg>-vtweg
        INTO et_swsodorgm-abb.
        et_swsodorgm-varbl  = 'VKORG'.
        et_swsodorgm-value  = <vkorg>-vkorg.
        APPEND et_swsodorgm.
        et_swsodorgm-varbl  = 'SPART'.
        et_swsodorgm-value  = <vkorg>-spart.
        APPEND et_swsodorgm.
        et_swsodorgm-varbl  = 'VTWEG'.
        et_swsodorgm-value  = <vkorg>-vtweg.
        APPEND et_swsodorgm.
      ENDLOOP.
    ELSE.
      log et_return 'I' 'VKORG'  'TVTA' 'Table does not exist.'
                                 ''
                                 ''.
    ENDIF.
    SORT et_swsodorgm.
    DELETE ADJACENT DUPLICATES FROM et_swsodorgm.
    IF <vkorg> IS ASSIGNED.
      UNASSIGN <vkorg>.
    ENDIF.
  ENDIF.
ENDFUNCTION.
