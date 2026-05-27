FUNCTION /psyng/sw_cr_copy_conflictid.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCECONFLICTID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(TARGETCONFLICTID) TYPE  /PSYNG/CONFLICT_ID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/CONFLICT-VRSIO OPTIONAL
*"     VALUE(L_COPY_DISPLAY_MODE) TYPE  FLAG OPTIONAL
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
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_CONFLICTID'.
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
  DATA: wa_conflict LIKE /psyng/conflict,
        wa_function like /psyng/function,
        wa_texts LIKE /psyng/texts.
  DATA: texts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE.
  DATA: confdet TYPE STANDARD TABLE OF /psyng/confdet
        WITH HEADER LINE,
        conowner type standard table of /PSYNG/CONOWNER with header line
.
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

  IF targetconflictid IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.


  SELECT SINGLE mandt INTO l_mandt FROM /psyng/conflict
            WHERE conid = sourceconflictid
            AND vrsio = i_vrsio.
  IF sy-subrc NE 0.
    RAISE source_conflict_doesnt_exist.
  ENDIF.


  SELECT SINGLE mandt INTO l_mandt FROM /psyng/conflict
            WHERE conid = targetconflictid
            AND vrsio = i_vrsio.
  IF sy-subrc EQ 0.
    RAISE target_already_exists.
  ENDIF.

if L_COPY_DISPLAY_MODE is INITIAL.

    AUTHORITY-CHECK OBJECT 'Y&SW_CONFH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_CONID' FIELD targetconflictid
           ID 'Y&SW_VRSIO' FIELD i_vrsio.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.
  endif.

  CALL FUNCTION '/PSYNG/SW_CR_READ_CONFLICTID'
       EXPORTING
            conflictid                   = sourceconflictid
            i_vrsio                      = i_vrsio
       IMPORTING
            wa_conflict                  = wa_conflict
       TABLES
            texts                        = texts
            confdet                      = confdet
            conowner                     = conowner
       EXCEPTIONS
            source_conflict_doesnt_exist = 1
            not_authorized_to_display    = 2
            OTHERS                       = 3.

  CASE sy-subrc .
    WHEN 1.
      RAISE source_conflict_doesnt_exist.
    WHEN 2.
      RAISE not_authorized_to_display.
  ENDCASE.

  LOOP AT confdet.
    SELECT SINGLE function FROM /psyng/function
           INTO wa_function-function
           WHERE function = confdet-functionid
             AND vrsio    = i_vrsio.
    CHECK sy-subrc NE 0.
    RAISE dependent_funid_doesnt_exist.
  ENDLOOP.

  wa_conflict-conid = targetconflictid.
  wa_conflict-create_usr = l_current_user. "sy-uname. C0700
  wa_conflict-create_dat = sy-datum.
  wa_conflict-create_tim = sy-uzeit.
  CLEAR: wa_conflict-change_usr, wa_conflict-change_dat,
         wa_conflict-change_tim.

  LOOP AT texts.
    texts-textname = targetconflictid.
    MODIFY texts.
  ENDLOOP.

  LOOP AT confdet.
    confdet-conid = targetconflictid.
    MODIFY confdet.
  ENDLOOP.

  loop at conowner.
    conowner-conid = targetconflictid.
    modify conowner.
  endloop.

  CALL FUNCTION '/PSYNG/SW_CR_ADD_CONFLICTID'
       EXPORTING
            wa_conflict           = wa_conflict
            i_vrsio               = i_vrsio
       IMPORTING
            conid_added           = conid_copied
            conid_hdr_added       = conid_hdr_copied
            conid_fun_added       = conid_tc_copied
            conid_txt_added       = conid_txt_copied
       TABLES
            texts                 = texts
            confdet               = confdet
            conowner              = conowner
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
