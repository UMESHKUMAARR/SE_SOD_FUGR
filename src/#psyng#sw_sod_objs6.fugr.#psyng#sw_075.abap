FUNCTION /PSYNG/SW_075.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      T_RESULTS STRUCTURE  /PSYNG/SW_OUT_ROUTPUT
*"----------------------------------------------------------------------

*--This is a sample implementation of a function module for user exit
*  in the role sod analysis.  The use of this user exit can be
*  configured using configuration parameter SW_REM_ROLE_FILTER


*--Example : only report each conflict once per role regardless of
*            System where it originates
sort T_RESULTS by agr_name conid.
delete adjacent duplicates from  T_RESULTS comparing agr_name conid.

ENDFUNCTION.
