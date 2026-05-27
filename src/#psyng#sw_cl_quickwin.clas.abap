class /PSYNG/SW_CL_QUICKWIN definition
  public
  final
  create public .

*"* public components of class /PSYNG/SW_CL_QUICKWIN
*"* do not include other source files here!!!
public section.

  methods GET_COMBINATIONS_RECURSIVE
    importing
      !SEARCH_TABLE type /PSYNG/SW_SOD_DET_ANA_T .
  methods GET_CONFLICT_TCODE_GROUPS .
protected section.
*"* protected components of class /PSYNG/SW_CL_QUICKWIN
*"* do not include other source files here!!!
private section.
*"* private components of class /PSYNG/SW_CL_QUICKWIN
*"* do not include other source files here!!!
ENDCLASS.



CLASS /PSYNG/SW_CL_QUICKWIN IMPLEMENTATION.


method GET_COMBINATIONS_RECURSIVE.
data : wa_line type /PSYNG/SW_SOD_DET_ANA.
*  loop at
*SEARCH_TABLE


endmethod.


method GET_CONFLICT_TCODE_GROUPS.
* ...
endmethod.
ENDCLASS.
