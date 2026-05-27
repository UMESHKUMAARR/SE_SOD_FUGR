FUNCTION /psyng/sw_014.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"----------------------------------------------------------------------
  data : l_mandt type sy-mandt.
  SELECT SINGLE adr6~client INTO l_mandt    "#EC CI_SEL_NESTED
    FROM usr21 INNER JOIN adr6
      ON usr21~addrnumber = adr6~addrnumber
     AND usr21~persnumber = adr6~persnumber
   WHERE usr21~bname = i_bname.

  IF sy-subrc <> 0.
    ef_has_conflict = 'X'.
  ENDIF.
ENDFUNCTION.
