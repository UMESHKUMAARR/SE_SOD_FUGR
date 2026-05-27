FUNCTION /psyng/sw_130.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(IS_SWBUTTABS) LIKE  /PSYNG/SWBUTTABS STRUCTURE
*"        /PSYNG/SWBUTTABS
*"  EXPORTING
*"     REFERENCE(RETURN) TYPE  BAPIRETURN
*"----------------------------------------------------------------------

  INSERT /psyng/swbuttabs FROM is_swbuttabs.
  IF sy-subrc EQ 0.
    return-type    = 'S'.
    return-message = 'Entry saved'(s74).
  ELSE.
    return-type    = 'E'.
    return-message = 'Entry not saved'(e25).
  ENDIF.


ENDFUNCTION.
