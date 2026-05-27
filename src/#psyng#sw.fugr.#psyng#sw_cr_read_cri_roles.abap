FUNCTION /psyng/sw_cr_read_cri_roles.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CRIROLES-VRSIO OPTIONAL
*"  TABLES
*"      CRIROLES STRUCTURE  /PSYNG/CRIROLES
*"  EXCEPTIONS
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_CRI_ROLES'.
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
  AUTHORITY-CHECK OBJECT 'Y&SW_CTROL'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO' FIELD i_vrsio.

  IF sy-subrc NE 0.
    RAISE not_authorized_to_display.
  ENDIF.

  REFRESH: criroles.

  SELECT * FROM /psyng/criroles INTO TABLE criroles
         WHERE vrsio = i_vrsio.
ENDFUNCTION.
