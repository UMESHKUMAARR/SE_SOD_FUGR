FUNCTION /psyng/sw_cr_read_cri_auths.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SWAUDID) TYPE  /PSYNG/SWAUDID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SWAUDHDR-VRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(WA_SWAUDHDR) TYPE  /PSYNG/SWAUDHDR
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      SWAUDC STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"  EXCEPTIONS
*"      AUTHID_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_CRI_AUTHS'.
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
  DATA: wa_texts LIKE /psyng/texts.


  SELECT SINGLE mandt
    INTO g_mandt
     FROM /psyng/swaudhdr
      WHERE swaudid = swaudid
        AND vrsio = i_vrsio.

  IF sy-subrc NE 0.
    RAISE authid_doesnt_exist.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_AUTID' FIELD swaudid
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
  IF sy-subrc NE 0.
    RAISE not_authorized_to_display.
  ENDIF.

  SELECT SINGLE * FROM /psyng/swaudhdr        "#EC CI_SEL_NESTED
        INTO CORRESPONDING FIELDS OF
         wa_swaudhdr WHERE swaudid = swaudid
                       AND vrsio   = i_vrsio.

  SELECT * FROM /psyng/texts
           APPENDING TABLE texts
           WHERE textname = swaudid
           AND   object   = 'T'
           AND   vrsio    = i_vrsio.
  SORT texts.  DELETE ADJACENT DUPLICATES FROM texts.

  SELECT * FROM /psyng/swaudc2
           APPENDING TABLE swaudc
           WHERE vrsio   = i_vrsio
             AND swaudid = swaudid.
ENDFUNCTION.
