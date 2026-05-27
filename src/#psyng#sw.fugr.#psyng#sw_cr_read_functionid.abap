FUNCTION /psyng/sw_cr_read_functionid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(FUNCTIONID) TYPE  /PSYNG/FUNCTION_ID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(WA_FUNCTION) TYPE  /PSYNG/FUNCTION
*"  TABLES
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"  EXCEPTIONS
*"      FUNCTION_DOESNT_EXIST
*"      NOT_AUTHORIZED
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_FUNCTIONID'.
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
  data : l_mandt type sy-mandt.
  DATA: wa_texts LIKE /psyng/texts.

  SELECT SINGLE mandt
    FROM /psyng/function
     INTO l_mandt
      WHERE function = functionid
       AND vrsio    = i_vrsio.

  IF sy-subrc NE 0.
    RAISE function_doesnt_exist.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_FUNCT' FIELD functionid.
  IF sy-subrc <> 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * FROM /psyng/function INTO CORRESPONDING FIELDS OF
         wa_function WHERE function = functionid
                       AND vrsio    = i_vrsio.

  SELECT * FROM /psyng/texts
           APPENDING TABLE texts
           WHERE textname = functionid
           AND   object   = 'F'
           AND   vrsio    = i_vrsio.
  SORT texts.  DELETE ADJACENT DUPLICATES FROM texts.

  SELECT * FROM /psyng/functtran
           APPENDING TABLE functtran
           WHERE functionid = functionid
             AND vrsio      = i_vrsio.

  SELECT * FROM /psyng/faobj2
           APPENDING TABLE faobj
           WHERE vrsio = i_vrsio
             AND funid = functionid.
ENDFUNCTION.
