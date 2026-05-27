FUNCTION /psyng/sw_copy_ver_desc.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IVERSIO) TYPE  /PSYNG/SWSODVERS-VRSIO
*"  TABLES
*"      ET_VERSIO STRUCTURE  /PSYNG/SWSODVERS
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_COPY_VER_DESC'.
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
  IF NOT iversio IS INITIAL.

    SELECT * INTO TABLE et_versio
                  FROM /psyng/swsodvers
                 WHERE vrsio = iversio.

  ELSE.

    SELECT * INTO TABLE et_versio "#EC CI_NOWHERE
                  FROM /psyng/swsodvers.
  ENDIF.

ENDFUNCTION.
