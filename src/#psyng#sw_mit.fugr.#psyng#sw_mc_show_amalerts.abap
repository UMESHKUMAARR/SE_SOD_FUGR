FUNCTION /PSYNG/SW_MC_SHOW_AMALERTS.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_BNAME) TYPE  XUBNAME
*"     REFERENCE(I_START_DATE) TYPE  DATS
*"     REFERENCE(I_END_DATE) TYPE  DATS
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_CONID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(I_SWAUDID) TYPE  /PSYNG/SWAUDID
*"----------------------------------------------------------------------
  DATA: iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
        lf_am_installed TYPE flag,
        l_am_vrsio   TYPE /psyng/prog_vrsio.

  if i_conid is initial.
    MESSAGE w002(/psyng/sw) WITH
    'AM alerts are not available for Critical Authorizations'.
    exit.
  endif.

*--Check if AM is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'AM'
       IMPORTING
            e_installed      = lf_am_installed
            e_module_version = l_am_vrsio.

  IF lf_am_installed  = 'X' AND l_am_vrsio > '1.0'.
    iseltab-selname = 'P_USRSUM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.

    iseltab-selname = 'S_BNAME'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_bname.
    APPEND iseltab.

    iseltab-selname = 'S_CONID'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_conid.
    APPEND iseltab.

    iseltab-selname = 'S_DATE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'BT'.
    iseltab-low     = I_START_DATE.
    iseltab-high    = I_END_DATE.
    APPEND iseltab.

    SUBMIT /PSYNG/SEAM_018
    WITH SELECTION-TABLE iseltab AND RETURN.
  ELSE.
   MESSAGE s002(/psyng/sw) WITH
     'Automated Mitigations is not installed or version to low'.
  ENDIF.

ENDFUNCTION.
