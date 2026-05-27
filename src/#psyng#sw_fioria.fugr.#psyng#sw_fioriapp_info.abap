FUNCTION /psyng/sw_fioriapp_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_SAVE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_SUCCESS) TYPE  FLAG
*"  TABLES
*"      IT_FIORIIDS STRUCTURE  /PSYNG/RANGE_FIORIID OPTIONAL
*"      ET_FIORIAPP STRUCTURE  /PSYNG/SW_FIORIA OPTIONAL
*"      ET_FIORIODATA STRUCTURE  /PSYNG/SW_FIORIO OPTIONAL
*"      ET_FIORITEXT STRUCTURE  /PSYNG/SW_FIORIT OPTIONAL
*"      ET_FIORINOTE STRUCTURE  /PSYNG/SW_FIORIN OPTIONAL
*"  EXCEPTIONS
*"      NOTHING_FOUND
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_FIORIAPP_INFO'.
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
*--update in db
    IF i_save = 'X'.
      PERFORM  save_in_db
         TABLES
               et_fioriapp
                et_fioriodata
                et_fioritext
                et_fiorinote
                CHANGING e_success.

else.
*--Fetch fiori app info
  SELECT *
    FROM /psyng/sw_fioria
    INTO TABLE et_fioriapp
   WHERE fioriid IN it_fioriids.
*--If no records found
  IF sy-subrc NE 0.
*##RAISE_OK
    RAISE nothing_found.
  ELSE.

*--Fetch odata service data
      SELECT *
        FROM /psyng/sw_fiorio
        INTO TABLE et_fioriodata
       WHERE fioriid IN it_fioriids.
*--Fetch fiori texts
      SELECT *
        FROM /psyng/sw_fiorit
        INTO TABLE et_fioritext
       WHERE fioriid IN it_fioriids.
*--Fetch snote related to fiori apps
      IF et_fiorinote IS REQUESTED.
        SELECT *
          FROM /psyng/sw_fiorin
          INTO TABLE et_fiorinote
         WHERE fioriid IN it_fioriids.
      ENDIF.
  ENDIF.
   endif.
ENDFUNCTION.
