FUNCTION /PSYNG/SW_097.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      ET_MCROLE STRUCTURE  /PSYNG/MCROLE
*"      ET_MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_097'.
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
data  lt_simu_roles_for_mit type table of /psyng/sw_sod_remote_roles.
g_vrsio = i_vrsio.
PERFORM load_mitigations
            TABLES
               et_mcrole
               et_mccarole
               lt_simu_roles_for_mit.


ENDFUNCTION.
