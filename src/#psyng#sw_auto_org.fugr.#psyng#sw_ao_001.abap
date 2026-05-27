FUNCTION /psyng/sw_ao_001 .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_BUKRS) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_EKORG) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_WERKS) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_VKORG) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_GSBER) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_SPART) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_VTWEG) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_KKBER) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_KOKRS) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_VAL_CAL) TYPE  FLAG DEFAULT 'X'
*"     VALUE(IF_VSTEL) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWCFGOE
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_VALUES STRUCTURE  /PSYNG/SW_ORG_VALUES_TEXT OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_001'.
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

  DEFINE add_message.
    clear et_return.
    et_return-type    = &1.
    et_return-message = &2.
    append et_return.
  END-OF-DEFINITION.
  concatenate sy-sysid sy-mandt into et_swsodorgm-sysid.

  DATA : lf_values TYPE flag.
  IF et_values IS REQUESTED.
    lf_values = 'X'.
  ENDIF.

*--Add messages about which field are implemented and which are not
  IF if_bukrs = 'X'.
*--Load Company Codes (BUKRS)
    PERFORM load_bukrs
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values       .
  ENDIF.
  IF  if_vkorg = 'X'.
*--Load Sales Orgs (VKORG) linked to Company Code (BUKRS)
    PERFORM load_vkorg
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values
      IF_VAL_CAL.

  ENDIF.
  IF if_werks = 'X'.
*--Load Plants (WERKS) linked to Company Code  (BUKRS)
    PERFORM load_werks
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values
      IF_VAL_CAL.
  ENDIF.
  IF if_ekorg = 'X'.
*--Load Purchase Orgs (EKORG) linked to Company Code (BUKRS)
*--Load Purchase Orgs (EKORG) linked to Plant (WERKS)
    PERFORM load_ekorg
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.
  ENDIF.


  IF  if_spart = 'X'.
*--Load Divisions (SPART) linked to Sales Orgs (VKORG)
    PERFORM load_spart
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.
  ENDIF.
  IF  if_vtweg = 'X'.
*--Load Distribution Channels (VTWEG) linked to Sales Orgs (VKORG)
    PERFORM load_vtweg
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.
  ENDIF.


  IF  if_gsber = 'X'.
    PERFORM load_gsber
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.
  ENDIF.
  IF  if_kokrs = 'X'.
    PERFORM load_kokrs
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.

  ENDIF.
  IF  if_kkber = 'X'.
    PERFORM load_kkber
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values.

  ENDIF.

  IF if_vstel = 'X'.
    PERFORM load_vstel
    TABLES
      et_swsodorgm
      et_return
      et_values
     USING
      lf_values
      if_val_cal.


  ENDIF.

  SORT et_swsodorgm BY abb varbl value.
  SORT et_values.
  DELETE ADJACENT DUPLICATES FROM et_swsodorgm.
  DELETE ADJACENT DUPLICATES FROM et_values.

ENDFUNCTION.
