FUNCTION /psyng/sw_cr_copy_functionid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCEFUNCTIONID) TYPE  /PSYNG/FUNCTION_ID
*"     VALUE(TARGETFUNCTIONID) TYPE  /PSYNG/FUNCTION_ID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/FUNCTION-VRSIO OPTIONAL
*"     VALUE(I_COPY_DISPLAY_MODE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(FUNID_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_HDR_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_TC_COPIED) TYPE  CHAR1
*"     VALUE(FUNID_TXT_COPIED) TYPE  CHAR1
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      TARGET_ALREADY_EXISTS
*"      SOURCE_FUNCTION_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_FUNCTIONID'.
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
  DATA: wa_function LIKE /psyng/function.
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
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

*--Skip the auth check if this flag is = 'X'
if I_COPY_DISPLAY_MODE is INITIAL.
  AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_FUNCT' FIELD targetfunctionid.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.
endif.
  SELECT SINGLE mandt INTO l_mandt FROM /psyng/function
                WHERE function = sourcefunctionid
                  AND vrsio    = i_vrsio.
  IF sy-subrc NE 0.
    RAISE source_function_doesnt_exist.
  ENDIF.

  SELECT SINGLE mandt INTO l_mandt FROM /psyng/function
                WHERE function = targetfunctionid
                  AND vrsio    = i_vrsio.
  IF sy-subrc = 0.
    RAISE target_already_exists.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_CR_READ_FUNCTIONID'
       EXPORTING
            functionid            = sourcefunctionid
            i_vrsio               = i_vrsio
       IMPORTING
            wa_function           = wa_function
       TABLES
            texts                 = texts
            functtran             = functtran
            faobj                 = faobj
       EXCEPTIONS
            function_doesnt_exist = 1
            not_authorized        = 2
            OTHERS                = 3.

  CASE sy-subrc .
    WHEN 1.
      RAISE source_function_doesnt_exist.
    WHEN 2.
      RAISE not_authorized_to_display.
    WHEN OTHERS.
  ENDCASE.

  wa_function-function = targetfunctionid.
  wa_function-create_usr = l_current_user. "sy-uname. C0700
  wa_function-create_dat = sy-datum.
  wa_function-create_tim = sy-uzeit.
  CLEAR: wa_function-change_usr, wa_function-change_dat,
         wa_function-change_tim.

  LOOP AT texts.
    texts-textname = targetfunctionid.
    MODIFY texts.
  ENDLOOP.

  LOOP AT functtran.
    functtran-functionid = targetfunctionid.
    MODIFY functtran.
  ENDLOOP.

  LOOP AT faobj.
    faobj-funid = targetfunctionid.
    MODIFY faobj.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_FUNCTIONID'
       EXPORTING
            wa_function                  = wa_function
            i_vrsio                      = i_vrsio
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
            source_function_doesnt_exist = 4
            OTHERS                       = 5.

  CASE sy-subrc.
    WHEN 1.
      RAISE target_not_specified.
    WHEN 2.
      RAISE not_authorized.
    WHEN 3.
      RAISE target_already_exists.
    WHEN 4.
      RAISE source_function_doesnt_exist.
    WHEN OTHERS.
  ENDCASE.

ENDFUNCTION.
