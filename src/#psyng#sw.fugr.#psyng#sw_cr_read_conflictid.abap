FUNCTION /psyng/sw_cr_read_conflictid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(CONFLICTID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CONFLICT-VRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(WA_CONFLICT) LIKE  /PSYNG/CONFLICT STRUCTURE
*"        /PSYNG/CONFLICT
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      CONOWNER STRUCTURE  /PSYNG/CONOWNER OPTIONAL
*"      CONPMIT STRUCTURE  /PSYNG/CONPMIT OPTIONAL
*"  EXCEPTIONS
*"      SOURCE_CONFLICT_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_CONFLICTID'.
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

  DATA: wa_texts LIKE /psyng/texts,
        l_config TYPE /psyng/swconfig,
        l_mandt type sy-mandt..

  SELECT SINGLE mandt                                "#EC CI_SEL_NESTED
    INTO l_mandt
     FROM /psyng/conflict
      WHERE conid = conflictid
        AND vrsio = i_vrsio.

  IF sy-subrc NE 0.
    RAISE source_conflict_doesnt_exist.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_CONID' FIELD conflictid
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
  IF sy-subrc <> 0.
    RAISE not_authorized_to_display.
  ENDIF.

  SELECT SINGLE * FROM /psyng/conflict               "#EC CI_SEL_NESTED
      INTO CORRESPONDING FIELDS OF
         wa_conflict WHERE conid = conflictid
                       AND vrsio = i_vrsio.

  SELECT * FROM /psyng/texts                         "#EC CI_SEL_NESTED
           APPENDING TABLE texts
           WHERE textname = conflictid
           AND   object   = 'C'
           AND   vrsio    = i_vrsio.
  SORT texts.  DELETE ADJACENT DUPLICATES FROM texts.

  SELECT * FROM /psyng/confdet                       "#EC CI_SEL_NESTED
           APPENDING TABLE confdet
           WHERE conid = conflictid
             AND vrsio = i_vrsio.
*--Conflict Owners
  SELECT * FROM /psyng/conowner                      "#EC CI_SEL_NESTED
           INTO TABLE conowner
           WHERE conid = conflictid
             AND vrsio = i_vrsio.
  SORT    conowner.

  se_config_param 'MIT_CON_DEFINED_ONLY' l_config-value.

  IF l_config-value IS INITIAL.
    l_config-value = 'N'.
  ENDIF.

  CHECK l_config-value = 'Y'.
*-- Conflict Proposed mitigation
  SELECT * FROM /psyng/conpmit INTO TABLE conpmit
  WHERE conid = conflictid
    AND vrsio = i_vrsio.



ENDFUNCTION.
