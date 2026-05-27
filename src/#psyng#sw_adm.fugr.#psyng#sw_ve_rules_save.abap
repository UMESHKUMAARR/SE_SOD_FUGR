FUNCTION /psyng/sw_ve_rules_save.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_DELETE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      IT_VE_RULE_VER STRUCTURE  /PSYNG/SW_VARVR OPTIONAL
*"      IT_VE_RULES STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_RULES_SAVE'.
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

  DATA: l_message_v1 TYPE symsgv,
        lt_ve_rules  TYPE TABLE OF /psyng/sw_varel.

  SORT it_ve_rules BY varel_vrsio var_element.
  SORT it_ve_rule_ver BY varel_vrsio.
*--Checkauthorization for all VE rule versions
  LOOP AT it_ve_rules.
    AUTHORITY-CHECK OBJECT 'Y&SW_VERUL'
           ID 'ACTVT' FIELD '02'
           ID 'Y&SW_VEVRS' FIELD it_ve_rules-varel_vrsio.
    IF sy-subrc <> 0.
      MESSAGE s108 WITH text-e20 INTO et_return-message.
      l_message_v1 = it_ve_rules-varel_vrsio.
      PERFORM fill_log
       TABLES et_return
        USING 'E' et_return-message
              text-o06 l_message_v1 '' ''.
      DELETE it_ve_rules WHERE varel_vrsio = it_ve_rules-varel_vrsio.
    ENDIF.
  ENDLOOP.

  LOOP AT it_ve_rules.
    APPEND it_ve_rules TO lt_ve_rules.
    AT END OF varel_vrsio.
      READ TABLE it_ve_rule_ver
        WITH KEY varel_vrsio = it_ve_rules-varel_vrsio BINARY SEARCH.
      PERFORM db_changes
       TABLES lt_ve_rules
              et_return
        USING it_ve_rule_ver
              if_delete
              if_test.
      REFRESH lt_ve_rules.
    ENDAT.
  ENDLOOP.

ENDFUNCTION.
