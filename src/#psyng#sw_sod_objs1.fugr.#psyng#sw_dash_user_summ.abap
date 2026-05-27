FUNCTION /PSYNG/SW_DASH_USER_SUMM.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(DIA_USERS_FM) TYPE  I
*"     VALUE(USR_CRI_AUTH_FM) TYPE  I
*"     VALUE(AVG_CRI_AUTH_FM) TYPE  I
*"     VALUE(USR_CRI_TCODE_FM) TYPE  I
*"     VALUE(AVG_CRI_TCODE_FM) TYPE  I
*"----------------------------------------------------------------------

*--This object is Obbsolete as of 2021/05/10 - SE4.5PS3
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_DASH_USER_SUMM'.
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
