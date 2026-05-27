FUNCTION /psyng/sw_dash_sod_env.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(NM_H_CONFS_FM) TYPE  I
*"     VALUE(NM_M_CONFS_FM) TYPE  I
*"     VALUE(NM_L_CONFS_FM) TYPE  I
*"     VALUE(NM_H_USER_CONF_FM) TYPE  I
*"     VALUE(NM_M_USER_CONF_FM) TYPE  I
*"     VALUE(NM_L_USER_CONF_FM) TYPE  I
*"     VALUE(NMT_USERS_WSOD_FM) TYPE  I
*"     VALUE(M_H_CONFS_FM) TYPE  I
*"     VALUE(M_M_CONFS_FM) TYPE  I
*"     VALUE(M_L_CONFS_FM) TYPE  I
*"     VALUE(OLDEST_SCAN_DATE) TYPE  D
*"----------------------------------------------------------------------

*--This object is Obbsolete as of 2021/05/10 - SE4.5PS3
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_DASH_SOD_ENV'.
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
