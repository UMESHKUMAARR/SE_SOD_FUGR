FUNCTION /PSYNG/SW_CR_GET_ALL_CRIROLES.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      CRIROLES STRUCTURE  /PSYNG/CRIROLES
*"----------------------------------------------------------------------

  SELECT * FROM /psyng/criroles
           INTO CORRESPONDING FIELDS OF table criroles
           WHERE vrsio = vrsio.


ENDFUNCTION.
