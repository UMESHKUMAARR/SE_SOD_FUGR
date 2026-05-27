FUNCTION /psyng/sw_cr_read_mit_controls.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(CONTID) TYPE  /PSYNG/CONTID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(MCHDR) LIKE  /PSYNG/MCHDR STRUCTURE  /PSYNG/MCHDR
*"  TABLES
*"      MCREPID STRUCTURE  /PSYNG/MCREPID OPTIONAL
*"      MCTRAN STRUCTURE  /PSYNG/MCTRAN OPTIONAL
*"      MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      MCAUDITOR STRUCTURE  /PSYNG/MCAUDITOR OPTIONAL
*"      MCUGROUP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      MCCAUSER STRUCTURE  /PSYNG/MCCAUSER OPTIONAL
*"      MCCAROLE STRUCTURE  /PSYNG/MCCAROLE OPTIONAL
*"      MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"  EXCEPTIONS
*"      MIT_CONTROL_ID_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_READ_MIT_CONTROLS'.
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

  SELECT SINGLE * FROM /psyng/mchdr     "#EC CI_SEL_NESTED
    INTO mchdr WHERE contid = contid.
  IF sy-subrc NE 0.
    RAISE mit_control_id_doesnt_exist.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_CNTID' FIELD contid
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    CLEAR mchdr.
    RAISE not_authorized_to_display.
  ENDIF.

  SELECT * FROM /psyng/mcrepid INTO TABLE mcrepid  "#EC CI_SEL_NESTED
           WHERE contid = contid.

  SELECT * FROM /psyng/mctran INTO TABLE mctran    "#EC CI_SEL_NESTED
           WHERE contid = contid.

  SELECT * FROM /psyng/mcuser INTO TABLE mcuser   "#EC CI_SEL_NESTED
           WHERE contid = contid
             AND vrsio  = i_vrsio.

  SELECT * FROM /psyng/mcauditor INTO TABLE mcauditor "#EC CI_SEL_NESTED

           WHERE contid = contid.

  SELECT * FROM /psyng/mcusrgrp INTO TABLE mcugroup "#EC CI_SEL_NESTED
           WHERE contid = contid
             AND vrsio  = i_vrsio.

  SELECT * FROM /psyng/mcrole INTO TABLE mcrole "#EC CI_SEL_NESTED
           WHERE contid = contid
             AND vrsio  = i_vrsio.
*** Fetch mitigation assginments to CAs for users
  SELECT * FROM /psyng/mccauser INTO TABLE mccauser  "#EC CI_SEL_NESTED
           WHERE contid = contid
             AND vrsio  = i_vrsio.
*** Fetch mitigation assginments to CAs for roles
  SELECT * FROM /psyng/mccarole INTO TABLE mccarole "#EC CI_SEL_NESTED
           WHERE contid = contid
             AND vrsio  = i_vrsio.

 SELECT text line                              "#EC CI_SEL_NESTED
   INTO CORRESPONDING FIELDS OF TABLE texts FROM
/psyng/texts
         WHERE textname = contid
           AND object   = 'M'
           AND spras    = sy-langu.
  IF texts[] IS INITIAL.
*--Text not available in logon language
    DATA : l_default_lang LIKE sy-langu VALUE 'EN'.
    SELECT * INTO TABLE texts FROM /psyng/texts "#EC CI_SEL_NESTED
           WHERE textname = contid
             AND object   = 'M'
             AND spras    = l_default_lang.
    IF texts[] IS INITIAL.
*--   Also not found in English, use first language found
      SELECT SINGLE spras  INTO l_default_lang  "#EC CI_SEL_NESTED
      FROM /psyng/texts
      WHERE textname = contid
      AND   object   = 'M'.
      IF sy-subrc = 0.
        SELECT * INTO TABLE texts FROM /psyng/texts "#EC CI_SEL_NESTED
               WHERE textname = contid
                 AND object   = 'M'
                 AND spras    = l_default_lang.
      ENDIF.
    ENDIF.
  ENDIF.

  SORT texts.  DELETE ADJACENT DUPLICATES FROM texts.
ENDFUNCTION.
