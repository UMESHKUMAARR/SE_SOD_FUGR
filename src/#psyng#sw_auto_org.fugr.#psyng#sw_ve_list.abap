FUNCTION /psyng/sw_ve_list.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VAREL_VRSIO) TYPE  /PSYNG/VE_VRSIO
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_PARSE_MATRIX) TYPE  FLAG OPTIONAL
*"  TABLES
*"      ET_VARIABLE_ELEMENTS STRUCTURE  /PSYNG/SW_VE_LIST
*"  EXCEPTIONS
*"      RULES_VERSION_NO_EXIST
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_LIST'.
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


  DATA : lt_varel    TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
         lt_dfies    TYPE TABLE OF dfies WITH HEADER LINE,
         lt_faobj    TYPE TABLE OF /psyng/faobj2,
         l_fieldname TYPE fieldname,
         lt_values   TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
         lt_defaults type table of /psyng/param_value with header line,
         l_param     type /psyng/param,
         l_paramval  type /psyng/param_value,
         l_cidx      type /psyng/sodvrsio,
         l_vrsio     type /PSYNG/VE_VRSIO.


*--validate the rules version
select single varel_vrsio into l_vrsio
from  /PSYNG/SW_VARVR where varel_vrsio = i_varel_vrsio.
if sy-subrc <> 0.
  RAISE RULES_VERSION_NO_EXIST.
endif.

*--Get used variable elements
  SELECT DISTINCT val_from FROM /psyng/faobj2
  INTO CORRESPONDING FIELDS OF TABLE
  lt_faobj WHERE val_from LIKE '/PSYNG/$%'  AND vrsio = i_sodvrsio
  ORDER BY val_from.

*--Get default variable elements
  l_cidx = '001'.
  while l_cidx le 999.
    concatenate 'VAR_DFLT_' l_cidx into l_param.
    se_config_param l_param l_paramval.
    if not l_paramval is initial.
      append l_paramval to lt_defaults.
    else.
      exit."only consider consecutive param nrs
    endif.
    add 1 to l_cidx.
  endwhile.
  sort lt_defaults.

  SELECT DISTINCT var_element element tabname FROM /psyng/sw_varel
  INTO CORRESPONDING FIELDS OF TABLE lt_varel
  WHERE
    varel_vrsio = i_varel_vrsio AND
    outputflag  = 'X'.

  LOOP AT lt_varel.
    et_variable_elements-var_element = lt_varel-var_element.
*--set default flag based on configuration parameters
*  VAR_DFLT_001 - VAR_DFLT_999
    et_variable_elements-default = ''.
    read table lt_defaults with key table_line = lt_varel-var_element.
    if sy-subrc = 0.
       et_variable_elements-default = 'X'.
    endif.
*--Get field label
    l_fieldname = lt_varel-element.
    CALL FUNCTION 'DDIF_FIELDINFO_GET'
         EXPORTING
              tabname        = lt_varel-tabname
              fieldname      = l_fieldname
         TABLES
              dfies_tab      = lt_dfies
         EXCEPTIONS
              not_found      = 1
              internal_error = 2
              OTHERS         = 3.
    IF sy-subrc = 0.
      READ TABLE lt_dfies INDEX 1.
      CONCATENATE lt_varel-element '-' lt_dfies-scrtext_l
      INTO  et_variable_elements-description SEPARATED BY space.
    ELSE.
      et_variable_elements-description = lt_varel-element.
    ENDIF.
    CLEAR et_variable_elements-selected.
    IF et_variable_elements-default = 'X'.
      et_variable_elements-selected = 'X'.
    ELSE.
* SE4.2f - Never pre-select variable elements
**--Check if this is used in this SOD Matrix
  if IF_PARSE_MATRIX = 'X'.
      READ TABLE lt_faobj WITH KEY val_from = lt_varel-var_element
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        et_variable_elements-selected = 'X'.
      ENDIF.
    endif.
    ENDIF.
    APPEND et_variable_elements.
  ENDLOOP.
  SORT et_variable_elements BY default selected var_element.

*--If there are already values for the provided configuration set
*  that are active, mark these as selected
  IF NOT i_setid IS INITIAL.
    SELECT DISTINCT var_element FROM /psyng/swcfgve
    INTO CORRESPONDING FIELDS OF TABLE lt_values
    WHERE setid = i_setid AND active = 'X'.
    IF NOT lt_values[] IS INITIAL.
      LOOP AT lt_values.
        et_variable_elements-selected = 'X'.
        MODIFY et_variable_elements
        TRANSPORTING selected
        WHERE var_element = lt_values-var_element.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFUNCTION.
