FUNCTION /PSYNG/INTERFACE_CUS_CONFLICT.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     VALUE(EF_HAS_CONFLICT) TYPE  /PSYNG/BAPIFLAGX
*"----------------------------------------------------------------------
* Custom conflicts are maintained in table /PSYNG/SW_CUSCON.

* Add logic for custom conflict
* If this user has the conflict, set EF_HAS_CONFLICT = 'X'.
* Else set EF_HAS_CONFLICT = space.
ENDFUNCTION.
