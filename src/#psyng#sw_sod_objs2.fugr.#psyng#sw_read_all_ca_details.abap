*----------------------------------------------------------------------*
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_read_all_ca_details .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      SWAUDC_FM STRUCTURE  /PSYNG/SWAUDC2 OPTIONAL
*"      SWAUDHDR_FM STRUCTURE  /PSYNG/SWAUDHDR OPTIONAL
*"  EXCEPTIONS
*"      NOT_AUTHORIZED_TO_READ_ALL
*"----------------------------------------------------------------------

  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_AUTID' FIELD '*'
           ID 'Y&SW_VRSIO' FIELD vrsio.

  IF sy-subrc NE 0.
    RAISE not_authorized_to_read_all.
  ENDIF.

  CLEAR: swaudc_fm, swaudhdr_fm.

  REFRESH: swaudc_fm, swaudhdr_fm.

  SELECT * FROM /psyng/swaudc2
           INTO CORRESPONDING FIELDS OF TABLE swaudc_fm
           WHERE vrsio = vrsio.

  SELECT * FROM /psyng/swaudhdr
           INTO CORRESPONDING FIELDS OF TABLE swaudhdr_fm
           WHERE vrsio = vrsio.

ENDFUNCTION.
