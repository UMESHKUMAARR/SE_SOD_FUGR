FUNCTION /PSYNG/SW_106.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      ET_TABLE_INFO STRUCTURE  /PSYNG/SW_LEVEL3_TABINFO
*"      ET_TABLE_KEYS STRUCTURE  /PSYNG/SW_LEVEL3_KEYS
*"      ET_DBLOG STRUCTURE  /PSYNG/DBLOG
*"      IT_DETAILS STRUCTURE  /PSYNG/SW_LEVEL3_DETAILS
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_106'.
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

  PERFORM get_db_change_log
              TABLES
                 it_details
                 et_dblog
                 ET_TABLE_KEYS
                 ET_TABLE_INFO.
ENDFUNCTION.
