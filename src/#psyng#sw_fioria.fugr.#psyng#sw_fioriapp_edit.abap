FUNCTION /psyng/sw_fioriapp_edit.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_FIORIID) TYPE  /PSYNG/SW_FIORIID OPTIONAL
*"----------------------------------------------------------------------

  DATA: lf_not_found TYPE flag.

*--Initialize global variables
  PERFORM refresh_global_variables.

*-- Set flag to edit the Custom Apps
  gf_edit = 'X'.

  IF NOT i_fioriid IS INITIAL
  AND i_fioriid+(1) NE 'Z'.
    MESSAGE i252(s#)
    WITH 'You can only edit Custom Fiori App starting with Z'(t10).
    RETURN.
  ENDIF.
*--Load data
  PERFORM load_data_for_edit USING    i_fioriid
                             CHANGING lf_not_found.
*--Define new fiori app
  IF NOT lf_not_found IS INITIAL.
    /psyng/sw_fioria-fioriid = i_fioriid.
  ENDIF.
*--Load field catalogs
  PERFORM load_fieldcat.

  CALL SCREEN 100 STARTING AT 5 1
                  ENDING AT 125 24.

ENDFUNCTION.
