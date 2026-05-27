FUNCTION /psyng/sw_check_swrole_exists.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(PROLEID) LIKE  /PSYNG/ROLEHDR-ROLEID
*"  EXPORTING
*"     REFERENCE(EXISTS)
*"----------------------------------------------------------------------
  data : l_mandt type sy-mandt.
  exists = 'N'.

  SELECT SINGLE mandt
  FROM /psyng/rolehdr
  INTO l_mandt
  WHERE roleid = proleid.

  CHECK sy-subrc = 0.

  exists = 'Y'.

ENDFUNCTION.
