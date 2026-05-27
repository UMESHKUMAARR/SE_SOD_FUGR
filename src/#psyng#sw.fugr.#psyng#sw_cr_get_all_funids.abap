*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_041
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

FUNCTION /psyng/sw_cr_get_all_funids .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      FUNCTION STRUCTURE  /PSYNG/FUNCTION
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_GET_ALL_FUNIDS'.
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

  SELECT * FROM /psyng/function
           INTO CORRESPONDING FIELDS OF function
           WHERE vrsio = vrsio.

    AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_VRSIO' FIELD vrsio
             ID 'Y&SW_FUNCT' FIELD function-function.

    CHECK sy-subrc = 0.
    APPEND function.

  ENDSELECT.

ENDFUNCTION.
