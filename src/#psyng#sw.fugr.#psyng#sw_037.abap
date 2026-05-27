FUNCTION /psyng/sw_037.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"  TABLES
*"      IT_SIMUAGRS STRUCTURE  AGR_DEFINE OPTIONAL
*"----------------------------------------------------------------------
DATA: l_function TYPE adcp-function.


  CHECK NOT it_simuagrs[] IS INITIAL.

* Get function from user master
  SELECT SINGLE adcp~function INTO l_function
    FROM usr21 INNER JOIN adcp
      ON usr21~addrnumber = adcp~addrnumber
     AND usr21~persnumber = adcp~persnumber
   WHERE usr21~bname = i_bname.

  CHECK NOT l_function IS INITIAL.

* Compare function to simulation role names
  LOOP AT it_simuagrs.
    IF it_simuagrs-agr_name+8(2) <> l_function.
      ef_has_conflict = 'X'.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFUNCTION.
