FUNCTION /psyng/sw_fioriapp_show.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_FIORIID) TYPE  /PSYNG/SW_FIORIID OPTIONAL
*"  EXCEPTIONS
*"      NOT_FOUND
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_FIORIAPP_SHOW'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  DATA: lf_not_found TYPE flag.

*--Initialize global variables
  PERFORM refresh_global_variables.
*--Load data
  PERFORM load_data_for_edit USING    i_fioriid
                             CHANGING lf_not_found.
  IF lf_not_found IS INITIAL.
*--Load field catalogs
    PERFORM load_fieldcat.

    CALL SCREEN 100 STARTING AT 5 1
                    ENDING AT 125 24.
  ELSE.
*##RAISE_OK
    RAISE not_found.
  ENDIF.

ENDFUNCTION.
