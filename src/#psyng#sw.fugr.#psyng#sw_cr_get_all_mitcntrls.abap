FUNCTION /psyng/sw_cr_get_all_mitcntrls.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      MCREPID STRUCTURE  /PSYNG/MCREPID OPTIONAL
*"      MCTRAN STRUCTURE  /PSYNG/MCTRAN OPTIONAL
*"      MCUSER STRUCTURE  /PSYNG/MCUSER OPTIONAL
*"      MCAUDITOR STRUCTURE  /PSYNG/MCAUDITOR OPTIONAL
*"      MCUGROUP STRUCTURE  /PSYNG/MCUSRGRP OPTIONAL
*"      TEXTS STRUCTURE  /PSYNG/TEXTS OPTIONAL
*"      MCHDR STRUCTURE  /PSYNG/MCHDR OPTIONAL
*"      MCROLE STRUCTURE  /PSYNG/MCROLE OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'.
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

  DATA : lt_mchdr  TYPE TABLE OF /psyng/mchdr  WITH HEADER LINE,
         lt_mctran TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
         lt_mcuser TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
         lt_mcauditor
                   TYPE TABLE OF /psyng/mcauditor
                                               WITH HEADER LINE,
         lt_mcugroup
                   TYPE TABLE OF /psyng/mcusrgrp
                                               WITH HEADER LINE,
         lt_mcrole TYPE TABLE OF /psyng/mcrole WITH HEADER LINE,
         lt_texts  TYPE TABLE OF /psyng/texts  WITH HEADER LINE,
         lt_mcrepid TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE.

  SELECT * FROM /psyng/mchdr  "#EC CI_NOWHERE
      INTO TABLE lt_mchdr.    "#EC CI_SEL_NESTED
  LOOP AT lt_mchdr.
    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
         EXPORTING
              contid                      = lt_mchdr-contid
              i_vrsio                     = i_vrsio
         IMPORTING
              mchdr                       = lt_mchdr
         TABLES
              mcrepid                     = lt_mcrepid
              mctran                      = lt_mctran
              mcuser                      = lt_mcuser
              mcauditor                   = lt_mcauditor
              mcugroup                    = lt_mcugroup
              mcrole                      = lt_mcrole
              texts                       = lt_texts
         EXCEPTIONS
              mit_control_id_doesnt_exist = 1
              not_authorized_to_display   = 2
              OTHERS                      = 3.
    IF sy-subrc = 0.
      APPEND lt_mchdr TO mchdr.
      APPEND LINES OF lt_mcrepid TO mcrepid.
      APPEND LINES OF lt_mctran TO mctran.
      APPEND LINES OF lt_mcuser TO mcuser.
      APPEND LINES OF lt_mcauditor TO mcauditor.
      APPEND LINES OF lt_mcugroup TO mcugroup.
      APPEND LINES OF lt_mcrole TO mcrole.
      APPEND LINES OF lt_texts TO texts.
      FREE : lt_mcrepid,
             lt_mctran,
             lt_mcuser,
             lt_mcauditor,
             lt_mcugroup,
             lt_mcrole,
             lt_texts.

    ENDIF.

  ENDLOOP.





ENDFUNCTION.
