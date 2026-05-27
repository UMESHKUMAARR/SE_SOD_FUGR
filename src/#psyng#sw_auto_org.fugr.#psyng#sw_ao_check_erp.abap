FUNCTION /PSYNG/SW_AO_CHECK_ERP.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(EF_IS_ERP) TYPE  FLAG
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_AO_CHECK_ERP'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026


  DATA : ls_type TYPE ddtypekind.
*--Check if the local system is an ERP system and if we can execute
* the logic in this system
  EF_IS_ERP = 'X'.
  CALL FUNCTION 'FUNCTION_EXISTS'
       EXPORTING
            funcname           = '/PSYNG/SW_AO_001'
       EXCEPTIONS
            function_not_exist = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    CLEAR EF_IS_ERP.
  ELSE.
*--Double check, perhaps FM is imported, but can't be used
    CALL FUNCTION 'DDIF_TYPEINFO_GET'
         EXPORTING
              typename = 'T001'
         IMPORTING
              typekind = ls_type.
    IF ls_type IS INITIAL.
      CLEAR EF_IS_ERP.
    ENDIF.
  ENDIF.
ENDFUNCTION.
