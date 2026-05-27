FUNCTION /PSYNG/SW_AO_GET_VALUE_TEXT.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_FIELD) TYPE  XUFIELD
*"     VALUE(I_VALUE) TYPE  XUVALUE
*"     VALUE(I_LANGU) TYPE  SYLANGU DEFAULT SY-LANGU
*"  EXPORTING
*"     VALUE(E_TEXT) TYPE  XUTEXT
*"  TABLES
*"      ET_TEXT STRUCTURE  /PSYNG/SW_ORG_VALUES_TEXT OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_GET_VALUE_TEXT'.
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


data : lf_all type flag.
if ET_TEXT is requested.
*--If this table is requested, texts for all possible values
*  for this field are returned so the calling source doesn't need to
*  make too many rfc connections
  lf_all = 'X'.
endif.

perform get_value_text
  tables   ET_TEXT
  using    i_field
           i_value
           I_LANGU
           lf_all
  changing e_text
  .
ENDFUNCTION.
