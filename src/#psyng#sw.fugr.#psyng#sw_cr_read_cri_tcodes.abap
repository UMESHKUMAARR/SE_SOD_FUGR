FUNCTION /psyng/sw_cr_read_cri_tcodes.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CRITCODES-VRSIO OPTIONAL
*"  TABLES
*"      CRITCODES STRUCTURE  /PSYNG/CRITCODES
*"  EXCEPTIONS
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_CRI_TCODES'.
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
  AUTHORITY-CHECK OBJECT 'Y&SW_CTCOD'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO' FIELD i_vrsio.

  IF sy-subrc NE 0.
    RAISE not_authorized_to_display.
  ENDIF.

  REFRESH: critcodes.

  SELECT * FROM /psyng/critcodes INTO TABLE critcodes
         WHERE vrsio = i_vrsio.
ENDFUNCTION.
