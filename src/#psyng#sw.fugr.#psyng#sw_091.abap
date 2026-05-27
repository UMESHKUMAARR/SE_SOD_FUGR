FUNCTION /PSYNG/SW_091.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IT_CONTID STRUCTURE  /PSYNG/DA_MCHDR
*"      ET_TYPES STRUCTURE  /PSYNG/MITIGATIONTYPE
*"----------------------------------------------------------------------

  if not IT_CONTID[] is initial.
    SELECT m~contid m~type t~text INTO TABLE ET_TYPES
    FROM /psyng/mchdr AS m INNER JOIN /psyng/sw_mctype AS t
    ON m~type = t~type
    FOR ALL ENTRIES IN IT_CONTID
    WHERE m~contid = IT_CONTID-contid.
  else.
*--If IT_CONTID is initial, we want ALL records
    SELECT m~contid m~type t~text INTO TABLE ET_TYPES
    FROM /psyng/mchdr AS m INNER JOIN /psyng/sw_mctype AS t
    ON m~type = t~type.
  endif.



ENDFUNCTION.
