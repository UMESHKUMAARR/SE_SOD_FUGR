FUNCTION /PSYNG/SW_025.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SWSODVERS-VRSIO
*"     REFERENCE(I_NOEDIT) TYPE  /PSYNG/BAPIFLAGX DEFAULT 'X'
*"----------------------------------------------------------------------
* Validate version
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                WHERE vrsio = i_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e113(/psyng/sw) WITH text-e01.
  ENDIF.

* Check NOEDIT value (X or space)
  IF i_noedit <> 'X' AND i_noedit <> space.
    MESSAGE e113(/psyng/sw) WITH text-e02.
  ENDIF.

  UPDATE /psyng/swsodvers SET noedit = i_noedit
                          WHERE vrsio = i_vrsio.
ENDFUNCTION.
