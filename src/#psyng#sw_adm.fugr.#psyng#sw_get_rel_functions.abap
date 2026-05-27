FUNCTION /PSYNG/SW_GET_REL_FUNCTIONS.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      ET_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_REL_FUNCTIONS'.
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
*--Get relavant function IDs
          SELECT DISTINCT functionid
          FROM /psyng/confdet
          INTO CORRESPONDING FIELDS OF TABLE et_confdet
          WHERE conid IN it_conid
          AND   vrsio = i_vrsio.

ENDFUNCTION.
