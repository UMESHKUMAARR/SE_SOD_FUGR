FUNCTION /PSYNG/SW_128.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_REPID) TYPE  REPID
*"----------------------------------------------------------------------
data : lf_installed type flag,
       l_vrsio     type /PSYNG/PROG_VRSIO.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
 EXPORTING
   I_MODULE               = 'BC'
 IMPORTING
   E_INSTALLED            = lf_installed
   E_MODULE_VERSION       = l_vrsio.
*--Only log execution if BASIS_EXELOG has I_NO_SUMMARY parameter
check lf_installed = 'X' and l_vrsio gt '2020.07A'.

data : lt_exelog  type table of /psyng/exelog with header line.
lt_exelog-mandt         = sy-mandt.
lt_exelog-repid         = i_repid.
lt_exelog-uname         = l_current_user. "sy-uname. C0700
lt_exelog-datum         = sy-datum.
lt_exelog-uzeit         = sy-uzeit.
append lt_exelog.
CALL FUNCTION '/PSYNG/BASIS_EXELOG'
IN BACKGROUND TASK
 EXPORTING
   I_NO_SUMMARY       = 'X'
  TABLES
    exelog            =  lt_exelog.
commit work.





ENDFUNCTION.
