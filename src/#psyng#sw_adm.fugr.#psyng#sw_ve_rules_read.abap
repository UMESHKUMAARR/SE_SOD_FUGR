FUNCTION /psyng/sw_ve_rules_read.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_VE_HDR) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_VE_VRSIO STRUCTURE  /PSYNG/RANGE_SE_VE_VRSIO OPTIONAL
*"      IT_VAREL STRUCTURE  /PSYNG/RANGE_SE_VAREL OPTIONAL
*"      ET_VE_RULE_VER STRUCTURE  /PSYNG/SW_VARVR OPTIONAL
*"      ET_VE_RULES STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_RULES_READ'.
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
*--Get Variable Element Rules
  SELECT *
    FROM /psyng/sw_varel
    INTO TABLE et_ve_rules
   WHERE varel_vrsio IN it_ve_vrsio
     AND var_element IN it_varel.

  IF NOT if_ve_hdr IS INITIAL.
    SELECT *
      FROM /psyng/sw_varvr
      INTO TABLE et_ve_rule_ver
     WHERE varel_vrsio IN it_ve_vrsio.
  ENDIF.

ENDFUNCTION.
