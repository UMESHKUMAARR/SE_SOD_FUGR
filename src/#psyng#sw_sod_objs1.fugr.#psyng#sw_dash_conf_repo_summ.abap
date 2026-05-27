FUNCTION /psyng/sw_dash_conf_repo_summ.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CONFLICT-VRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(T_CONFLICTS_FM) TYPE  F
*"     VALUE(T_FUNCTIONS_FM) TYPE  F
*"     VALUE(T_CRI_TCODE_FM) TYPE  F
*"     VALUE(T_CRI_AUTH_FM) TYPE  F
*"     VALUE(A_FUN_CON_FM) TYPE  F
*"     VALUE(A_TCODE_FUN_FM) TYPE  F
*"     VALUE(A_VAL_TCODE_FM) TYPE  F
*"----------------------------------------------------------------------
*--This object is Obbsolete as of 2021/05/10 - SE4.5PS3
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_DASH_CONF_REPO_SUMM'.
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
ENDFUNCTION.
