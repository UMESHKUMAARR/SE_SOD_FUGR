FUNCTION /psyng/sw_cr_copy_remote_funid.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(SOURCEFUNCTIONID) TYPE  /PSYNG/FUNCTION_ID
*"     VALUE(TARGETFUNCTIONID) TYPE  /PSYNG/FUNCTION_ID
*"     VALUE(RFCDEST) TYPE  RFCDES-RFCDEST
*"     VALUE(SOURCEVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(TARGETVRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(FUNID_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_HDR_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_TC_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_TXT_COPIED) TYPE  CHAR1
*"  EXCEPTIONS
*"      TARGET_FUNID_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      TARGET_ALREADY_EXISTS
*"      SOURCE_FUNCTION_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"      INVALID_RFC
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_REMOTE_FUNID'.
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
  DATA: wa_function LIKE /psyng/function.
  DATA: wa_texts LIKE /psyng/texts.
  DATA: texts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE.
  DATA: functtran TYPE STANDARD TABLE OF /psyng/functtran
        WITH HEADER LINE.
  DATA: faobj TYPE STANDARD TABLE OF /psyng/faobj2
        WITH HEADER LINE.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  funid_copied = 'N'.
  funid_hdr_copied = 'N'.
  funid_tc_copied = 'N'.
  funid_txt_copied = 'N'.

  IF targetfunctionid IS INITIAL.
    RAISE target_funid_not_specified.
    "EXIT.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD targetvrsio
           ID 'Y&SW_FUNCT' FIELD targetfunctionid.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE * FROM rfcdes WHERE rfcdest = rfcdest.
  IF sy-subrc NE 0.
    RAISE invalid_rfc.
  ENDIF.

  SELECT SINGLE mandt           "#EC CI_SEL_NESTED
    INTO g_mandt
     FROM /psyng/function
      WHERE function = targetfunctionid
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
  CALL FUNCTION '/PSYNG/SW_CR_READ_FUNCTIONID'
    DESTINATION rfcdest
       EXPORTING
            i_vrsio                 = sourcevrsio
            functionid            = sourcefunctionid
       IMPORTING
            wa_function           = wa_function
       TABLES
            texts                 = texts
            functtran             = functtran
            faobj                 = faobj
       EXCEPTIONS
            function_doesnt_exist = 1
            not_authorized        = 2
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  CASE sy-subrc .
    WHEN 1.
      RAISE source_function_doesnt_exist.
    WHEN 2.
      RAISE not_authorized_to_display.
    WHEN OTHERS.
  ENDCASE.

  wa_function-function = targetfunctionid.
  wa_function-vrsio    = targetvrsio.
  wa_function-create_usr = l_current_user."sy-uname. C0700
  wa_function-create_dat = sy-datum.
  wa_function-create_tim = sy-uzeit.
  CLEAR: wa_function-change_usr, wa_function-change_dat,
         wa_function-change_tim.

  LOOP AT texts.
    texts-textname = targetfunctionid.
    texts-vrsio    = targetvrsio.
    MODIFY texts.
  ENDLOOP.

  LOOP AT functtran.
    functtran-functionid = targetfunctionid.
    functtran-vrsio      = targetvrsio.
    MODIFY functtran.
  ENDLOOP.

  LOOP AT faobj.
    faobj-funid = targetfunctionid.
    faobj-vrsio = targetvrsio.
    MODIFY faobj.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
       EXPORTING
            wa_function                  = wa_function
            i_vrsio                        = targetvrsio
       IMPORTING
            funid_added                  = funid_copied
            funid_hdr_added              = funid_hdr_copied
            funid_tc_added               = funid_tc_copied
            funid_txt_added              = funid_txt_copied
       TABLES
            texts                        = texts
            functtran                    = functtran
            faobj                        = faobj
       EXCEPTIONS
            target_not_specified         = 1
            not_authorized               = 2
            function_already_exists      = 3
*            source_function_doesnt_exist = 4
            OTHERS                       = 5.

  CASE sy-subrc.
    WHEN 1.
      RAISE target_funid_not_specified.
    WHEN 2.
      RAISE not_authorized.
    WHEN 3.
      RAISE function_already_exists.
*    WHEN 4.
*      RAISE source_function_doesnt_exist.
    WHEN OTHERS.
  ENDCASE.

ENDFUNCTION.
