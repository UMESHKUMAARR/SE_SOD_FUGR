FUNCTION /PSYNG/SW_CR_COPY_MIT_CONTROLS .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCEMITIGATIONID) TYPE  /PSYNG/CONTID
*"     VALUE(TARGETMITIGATIONID) TYPE  /PSYNG/CONTID
*"  EXPORTING
*"     VALUE(MITID_COPIED) TYPE  CHAR1
*"     VALUE(MITID_REP_COPIED) TYPE  CHAR1
*"     VALUE(MITID_AUD_COPIED) TYPE  CHAR1
*"     VALUE(MITID_TC_COPIED) TYPE  CHAR1
*"     VALUE(MITID_TXT_COPIED) TYPE  CHAR1
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      TARGET_ALREADY_EXISTS
*"      SOURCE_MITIGATION_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_MIT_CONTROLS'.
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
  DATA: wa_mchdr       TYPE /psyng/mchdr.
  DATA: lt_texts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE,
        lt_mcauditor   TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
        lt_mctran      TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
        lt_mcrepid     TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE.


  mitid_copied = 'N'.
  mitid_rep_copied = 'N'.
  mitid_aud_copied = 'N'.
  mitid_tc_copied = 'N'.
  mitid_txt_copied = 'N'.

  IF targetmitigationid IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
           ID 'ACTVT'      FIELD '01'
           ID 'Y&SW_CNTID' FIELD targetmitigationid
           ID 'Y&SW_VRSIO' dummy.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE mandt INTO g_mandt FROM /psyng/mchdr
                WHERE contid = sourcemitigationid.
  IF sy-subrc NE 0.
    RAISE source_mitigation_doesnt_exist.
  ENDIF.

  SELECT SINGLE mandt INTO g_mandt FROM /psyng/mchdr
                WHERE contid = targetmitigationid.
  IF sy-subrc = 0.
    RAISE target_already_exists.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
    EXPORTING
      contid                            = sourcemitigationid
*     I_VRSIO                           =
   IMPORTING
     mchdr                             = wa_mchdr
   TABLES
     mcrepid                           = lt_mcrepid
     mctran                            = lt_mctran
*     MCUSER                            =
     mcauditor                         =  lt_mcauditor
*     MCUGROUP                          =
*     MCCAUSER                          =
*     MCROLE                            =
     texts                             =  lt_texts
   EXCEPTIONS
     mit_control_id_doesnt_exist       = 1
     not_authorized_to_display         = 2
     OTHERS                            = 3.
  CASE sy-subrc .
    WHEN 1.
      RAISE source_mitigation_doesnt_exist.
    WHEN 2.
      RAISE not_authorized_to_display.
    WHEN OTHERS.
  ENDCASE.

  wa_mchdr-contid = targetmitigationid.

  LOOP AT lt_texts.
    lt_texts-textname = targetmitigationid.
    MODIFY lt_texts.
  ENDLOOP.

  LOOP AT lt_mctran.
    lt_mctran-contid = targetmitigationid.
    MODIFY lt_mctran.
  ENDLOOP.

  LOOP AT lt_mcrepid.
    lt_mcrepid-contid = targetmitigationid.
    MODIFY lt_mcrepid.
  ENDLOOP.

  LOOP AT lt_mcauditor.
    lt_mcauditor-contid = targetmitigationid.
    MODIFY lt_mcauditor.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
       EXPORTING
            is_mchdr             = wa_mchdr
       IMPORTING
            ef_mchdr_added       = mitid_copied
            ef_mcauditor_added   = mitid_aud_copied
            ef_mctran_added      = mitid_tc_copied
            ef_mcrepid_added     = mitid_rep_copied
            ef_text_added        = mitid_txt_copied
       TABLES
            it_mcauditor         = lt_mcauditor
            it_mctran            = lt_mctran
            it_mcrepid           = lt_mcrepid
            it_texts             = lt_texts
       EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.


  CASE sy-subrc.
    WHEN 1.
      RAISE target_not_specified.
    WHEN 2.
      RAISE not_authorized.
    WHEN OTHERS.
  ENDCASE.

ENDFUNCTION.
