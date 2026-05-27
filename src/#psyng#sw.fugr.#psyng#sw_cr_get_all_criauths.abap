FUNCTION /psyng/sw_cr_get_all_criauths.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DETAILS) TYPE  FLAG OPTIONAL
*"  TABLES
*"      SWAUDHDR STRUCTURE  /PSYNG/SWAUDHDR
*"      SWAUDC2 STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"  EXCEPTIONS
*"      NO_AUTHORIZATION
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_GET_ALL_CRIAUTHS'.
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
  SELECT * FROM /psyng/swaudhdr
           INTO CORRESPONDING FIELDS OF swaudhdr
           WHERE vrsio = vrsio.

    AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO' FIELD vrsio
             ID 'Y&SW_AUTID' FIELD swaudhdr-swaudid.

    IF sy-subrc = 0.
      APPEND swaudhdr.
    ELSE.
      RAISE no_authorization.
      "EXIT.
    ENDIF.

  ENDSELECT.
  IF if_details = 'X'.
  check not swaudhdr[] is initial.
*--Also get the details
    SELECT * FROM /psyng/swaudc2
             INTO  TABLE swaudc2
             FOR ALL ENTRIES IN swaudhdr
             WHERE vrsio = vrsio
             AND swaudid = swaudhdr-swaudid
             AND tcode   = swaudhdr-tcode
             AND field <> ''. "ignore blank fields

  ENDIF.
ENDFUNCTION.
