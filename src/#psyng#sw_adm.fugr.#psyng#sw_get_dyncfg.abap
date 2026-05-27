FUNCTION /psyng/sw_get_dyncfg.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IT_CALLING_TCODE STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"      IT_CALLED_TCODE STRUCTURE  /PSYNG/RANGE_TCODE OPTIONAL
*"      ET_CALLING_TCODES STRUCTURE  /PSYNG/SW_EXCLTX OPTIONAL
*"      ET_CALLED_TCODES STRUCTURE  /PSYNG/SW_EXCDTX OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_DYNCFG'.
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

*--Get calling tcodes
  SELECT *
    FROM /psyng/sw_excltx
    INTO TABLE et_calling_tcodes
   WHERE low IN it_calling_tcode.

*--Get called tcodes
  SELECT *
    FROM /psyng/sw_excdtx
    INTO TABLE et_called_tcodes
   WHERE called_tcode IN it_called_tcode.

ENDFUNCTION.
