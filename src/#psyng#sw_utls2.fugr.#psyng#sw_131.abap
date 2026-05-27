FUNCTION /PSYNG/SW_131.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_GLOBLE_VRSIO) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_SOD_VERSION) TYPE  /PSYNG/SWSODVERS-VRSIO
*"     VALUE(E_VALID) TYPE  FLAG
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_131'.
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

if i_globle_vrsio = 'X'.
data l_value TYPE /psyng/swconfig-value.
  se_config_param 'DFLT_GLOBAL_VERSION' l_value.

*--check if sod version is dummy
  select SINGLE mandt into sy-mandt
       from /psyng/conflict
    where vrsio = l_value.
    if sy-subrc = 0.
      e_valid = 'X'.
      endif.

*   Check if this version is still valid
    SELECT SINGLE mandt INTO sy-mandt     "#EC CI_SEL_NESTED
                 FROM /psyng/swsodvers
                  WHERE vrsio = l_value.
    IF sy-subrc = 0.
      e_sod_version = l_value.
      EXIT.
    ENDIF.
  else.
  CALL FUNCTION '/PSYNG/SW_034'
   IMPORTING
     e_vrsio       = e_sod_version.
endif.


ENDFUNCTION.
