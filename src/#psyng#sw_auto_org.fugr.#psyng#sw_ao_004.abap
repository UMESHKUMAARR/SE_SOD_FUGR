FUNCTION /PSYNG/SW_AO_004.
*"----------------------------------------------------------------------
*"*"Local interface:
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
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_VALUES STRUCTURE  /PSYNG/SW_ORG_VALUES_TEXT OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_004'.
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

define add_message.
  clear ET_RETURN.
  ET_RETURN-type    = &1.
  ET_RETURN-message = &2.
  append et_return.
end-of-definition.
concatenate sy-sysid sy-mandt into et_swsodorgm-sysid.

data : lf_values type flag.
if et_values is requested.
  lf_values = 'X'.
endif.

*--Add messages about which field are implemented and which are not
if if_bukrs = 'X'.
*--Load Company Codes (BUKRS)
     perform load_bukrs
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values       .
endif.
if  if_vkorg = 'X'.
*--Load Sales Orgs (VKORG) linked to Company Code (BUKRS)
     perform load_vkorg
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values
       IF_VAL_CAL.

endif.
if if_werks = 'X'.
*--Load Plants (WERKS) linked to Company Code  (BUKRS)
     perform load_werks_rel
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values
       IF_VAL_CAL.
endif.
if if_ekorg = 'X'.
*--Load Purchase Orgs (EKORG) linked to Company Code (BUKRS)
*--Load Purchase Orgs (EKORG) linked to Plant (WERKS)
     perform load_ekorg_rel
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.
endif.


if  if_spart = 'X'.
*--Load Divisions (SPART) linked to Sales Orgs (VKORG)
     perform load_spart
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.
endif.
if  if_vtweg = 'X'.
*--Load Distribution Channels (VTWEG) linked to Sales Orgs (VKORG)
     perform load_vtweg
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.
endif.


if  if_gsber = 'X'.
     perform load_gsber
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.
endif.
if  if_kokrs = 'X'.
     perform load_kokrs
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.

endif.
if  if_kkber = 'X'.
     perform load_kkber
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values.

endif.
if if_vstel = 'X'.
     perform load_vstel
     tables
       et_swsodorgm
       et_return
       et_values
      using
       lf_values
       IF_VAL_CAL.


endif.

sort et_swsodorgm by abb varbl value.
sort et_values.
delete adjacent duplicates from et_swsodorgm.
delete adjacent duplicates from et_values.

ENDFUNCTION.
