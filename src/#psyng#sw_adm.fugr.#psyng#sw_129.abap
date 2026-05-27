FUNCTION /PSYNG/SW_129.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_REFERENCE_FM) TYPE  FUNCNAME OPTIONAL
*"  TABLES
*"      IT_PARAMS STRUCTURE  FUPARAREF OPTIONAL
*"      ET_FUNCTIONS STRUCTURE  FUPARAREF
*"----------------------------------------------------------------------
*--Find FM's that have the combination of parameters provided in IT_PARAMS.
*  Or that have the same signature of FM I_REFERENCE_FM.
*  only the PARAMETER, PARAMTYPE and STRUCTURE fields will be analyzed
data : lt_fms type table of fupararef with header line,
      begin of lt_cnt occurs 0,
        funcname type funcname,
        matches type I,
      end of lt_cnt,
      l_cnt_params type i.
if not i_reference_fm is initial.
  select * from FUPARAREF into table it_PARAMS
    where funcname = I_REFERENCE_FM.
endif.
if not  it_params[] is initial.
  sort it_params.
  delete adjacent duplicates from it_params.
  describe table it_params lines l_cnt_params.
  select * from FUPARAREF into table lt_fms
    for all entries in IT_PARAMS where
*    ( funcname like 'Y%' or funcname like 'Z%' or funcname like '/%' ) AND
    r3state = 'A' and
    PARAMETER = IT_PARAMS-PARAMETER and
    PARAMTYPE = IT_PARAMS-PARAMTYPE and
    STRUCTURE = IT_PARAMS-STRUCTURE.
 sort lt_fms by funcname parameter.
 loop at lt_fms where  funcname CP 'Y*' or "ignore sap standard FM's
                       funcname CP 'Z*' or
                       funcname CP '/*'.
   lt_cnt-funcname = lt_fms-funcname.
   lt_cnt-matches  = 1.
   collect lt_cnt.
 endloop.
endif.
delete lt_cnt where matches <> l_cnt_params.
free : ET_FUNCTIONS.
loop at lt_cnt.
  et_functions-funcname = lt_cnt-funcname.
  append et_functions.
endloop.

ENDFUNCTION.
