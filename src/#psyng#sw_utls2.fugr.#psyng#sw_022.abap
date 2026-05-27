FUNCTION /PSYNG/SW_022.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(BNAME) TYPE  XUBNAME
*"  EXPORTING
*"     REFERENCE(ORGNR) TYPE  /PSYNG/ORGNR
*"  EXCEPTIONS
*"      NO_ORGNR_ASSIGNED
*"      USER_NOT_FOUND
*"----------------------------------------------------------------------
* Sample Code commented
*data : l_bname type xubname.
*select single bname into l_bname from usr02 where bname = bname.
*if sy-subrc <> 0.
*  RAISE USER_NOT_FOUND.
*else.
**--------------------------------------------------------
**decide which organisation number to assign to this user.
**--------------------------------------------------------
**in this sample function we use the first letter of the
** username to decide the organisation number.
**--------------------------------------------------------
*  translate l_bname to UPPER CASE.
*  if l_bname(1) LT  'D'.
*     orgnr = '0000000001'.
*  elseif l_bname(1) LT 'H'.
*         orgnr = '0000000002'.
*  elseif l_bname(1) LT 'L'.
*         orgnr = '0000000003'.
*  elseif l_bname(1) LT 'P'.
*         orgnr = '0000000003'.
*  elseif  l_bname(1) LT 'T'.
*         orgnr = '0000000004'.
*  else.
**  If there is no direct link between the user and the
**  organisation number
**  Raise the correct exception
**  If there is  a record in table /psyng/orgnr_usr it will be deleted
*    RAISE NO_ORGNR_ASSIGNED.
*  endif.
*endif.
RAISE NO_ORGNR_ASSIGNED.
ENDFUNCTION.
