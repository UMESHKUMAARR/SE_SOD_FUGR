FUNCTION /psyng/sw_dash_auth_env.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(T_AUTH_FM) TYPE  I
*"     VALUE(T_AUTH_SOD_FM) TYPE  I
*"     VALUE(A_AUTH_USER_FM) TYPE  I
*"     VALUE(A_AUTH_USER_SOD_FM) TYPE  I
*"----------------------------------------------------------------------

*--This object is Obbsolete as of 2021/05/10 - SE4.5PS3
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_DASH_AUTH_ENV'.
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
