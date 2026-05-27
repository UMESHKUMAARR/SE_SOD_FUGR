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
FUNCTION /psyng/sw_cr_get_all_conids.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      CONFLICT STRUCTURE  /PSYNG/CONFLICT
*"      OWNER STRUCTURE  /PSYNG/CONOWNER OPTIONAL
*"      CONPMIT STRUCTURE  /PSYNG/CONPMIT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_GET_ALL_CONIDS'.
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
  SELECT * FROM /psyng/conflict
           INTO CORRESPONDING FIELDS OF conflict
           WHERE vrsio = vrsio.

    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
             ID 'ACTVT' FIELD '03'
             ID 'Y&SW_CONID' FIELD conflict-conid
             ID 'Y&SW_VRSIO' FIELD vrsio.

    CHECK sy-subrc = 0.
    APPEND conflict.

  ENDSELECT.

if not conflict[] is initial.
  select * from /PSYNG/CONOWNER
  into table owner
  for all entries in conflict
  where
    vrsio = conflict-vrsio and
    conid = conflict-conid.
if conpmit is requested.
  select * from /PSYNG/CONPMIT
  into table CONPMIT
  for all entries in conflict
  where
    vrsio = conflict-vrsio and
    conid = conflict-conid.
endif.
endif.

ENDFUNCTION.
