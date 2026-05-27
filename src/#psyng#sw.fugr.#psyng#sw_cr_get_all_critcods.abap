FUNCTION /psyng/sw_cr_get_all_critcods.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      CRITCODES STRUCTURE  /PSYNG/CRITCODES
*"----------------------------------------------------------------------

  SELECT * FROM /psyng/critcodes
           INTO CORRESPONDING FIELDS OF critcodes
           WHERE vrsio = vrsio.

    AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO' FIELD vrsio.

    CHECK sy-subrc = 0.
    APPEND critcodes.

  ENDSELECT.

ENDFUNCTION.
