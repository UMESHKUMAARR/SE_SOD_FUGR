FUNCTION /psyng/sw_cr_copy_remote_conid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCECONFLICTID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(TARGETCONFLICTID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(RFCDEST) TYPE  RFCDES-RFCDEST
*"     VALUE(TARGETVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(SOURCEVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(CONID_COPIED) TYPE  CHAR1
*"     VALUE(CONID_HDR_COPIED) TYPE  CHAR1
*"     VALUE(CONID_TC_COPIED) TYPE  CHAR1
*"     VALUE(CONID_TXT_COPIED) TYPE  CHAR1
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      TARGET_ALREADY_EXISTS
*"      NOT_AUTHORIZED
*"      SOURCE_CONFLICT_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"      DEPENDENT_FUNID_DOESNT_EXIST
*"      INVALID_RFC
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_REMOTE_CONID'.
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

  DATA: wa_conflict LIKE /psyng/conflict.
  DATA: wa_function LIKE /psyng/function.
  DATA: wa_texts LIKE /psyng/texts.
  DATA: texts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE.
  DATA: confdet TYPE STANDARD TABLE OF /psyng/confdet
        WITH HEADER LINE.
*  DATA lt_function TYPE STANDARD TABLE OF /psyng/function WITH HEADER
*LINE.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  conid_copied = 'N'.
  conid_hdr_copied = 'N'.
  conid_tc_copied = 'N'.
  conid_txt_copied = 'N'.

  SELECT SINGLE * FROM rfcdes WHERE rfcdest = rfcdest.
  IF sy-subrc NE 0.
    RAISE invalid_rfc.
  ENDIF.

  IF targetconflictid IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_CONID' FIELD targetconflictid
           ID 'Y&SW_VRSIO' FIELD targetvrsio.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.


  SELECT SINGLE mandt
    INTO g_mandt
     FROM /psyng/conflict
      WHERE conid = targetconflictid
        AND vrsio = targetvrsio.
  IF sy-subrc EQ 0.
    RAISE target_already_exists.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
  CALL FUNCTION '/PSYNG/SW_CR_READ_CONFLICTID'
    DESTINATION rfcdest
       EXPORTING
            i_vrsio                      = sourcevrsio
            conflictid                   = sourceconflictid
       IMPORTING
            wa_conflict                  = wa_conflict
       TABLES
            texts                        = texts
            confdet                      = confdet
       EXCEPTIONS
            source_conflict_doesnt_exist = 1
            not_authorized_to_display    = 2
            OTHERS                       = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  CASE sy-subrc .
    WHEN 1.
      RAISE source_conflict_doesnt_exist.
    WHEN 2.
      RAISE not_authorized_to_display.
  ENDCASE.

*  SELECT function FROM /psyng/function
*           INTO CORRESPONDING FIELDS OF TABLE lt_function
*           WHERE vrsio  = targetvrsio.

  LOOP AT confdet.
    SELECT SINGLE function FROM /psyng/function    "#EC CI_SEL_NESTED
           INTO wa_function-function
           WHERE function = confdet-functionid
           AND   vrsio    = targetvrsio.

*    READ TABLE lt_function WITH KEY function = confdet-functionid
*TRANSPORTING NO FIELDS.

    CHECK sy-subrc NE 0.
    RAISE dependent_funid_doesnt_exist.
  ENDLOOP.

  wa_conflict-conid = targetconflictid.
  wa_conflict-vrsio = targetvrsio.
  wa_conflict-create_usr = l_current_user. "sy-uname. C0700
  wa_conflict-create_dat = sy-datum.
  wa_conflict-create_tim = sy-uzeit.
  CLEAR: wa_conflict-change_usr, wa_conflict-change_dat,
         wa_conflict-change_tim.

  LOOP AT texts.
    texts-textname = targetconflictid.
    texts-vrsio    = targetvrsio.
    MODIFY texts.
  ENDLOOP.

  LOOP AT confdet.
    confdet-conid = targetconflictid.
    confdet-vrsio = targetvrsio.
    MODIFY confdet.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
       EXPORTING
            i_vrsio               = targetvrsio
            wa_conflict           = wa_conflict
       IMPORTING
            conid_added           = conid_copied
            conid_hdr_added       = conid_hdr_copied
*            conid_tc_added        = conid_tc_copied
            conid_txt_added       = conid_txt_copied
       TABLES
            texts                 = texts
            confdet               = confdet
       EXCEPTIONS
            target_not_specified  = 1
            target_already_exists = 2
            not_authorized        = 3
            OTHERS                = 4.
  CASE sy-subrc.
    WHEN 1.
      RAISE target_not_specified.
    WHEN 2.
      RAISE target_already_exists.
    WHEN 3.
      RAISE not_authorized.
    WHEN OTHERS.
  ENDCASE.


ENDFUNCTION.
