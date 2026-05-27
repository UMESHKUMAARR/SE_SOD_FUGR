FUNCTION /psyng/sw_cr_copy_crit_auths.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(SOURCESWAUDID) TYPE  /PSYNG/SWAUDID
*"     VALUE(TARGETSWAUDID) TYPE  /PSYNG/SWAUDID
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"  EXPORTING
*"     VALUE(CAID_COPIED) TYPE  CHAR1
*"     VALUE(CAID_DET_COPIED) TYPE  CHAR1
*"     VALUE(CAID_TXT_COPIED) TYPE  CHAR1
*"     VALUE(CAID_HDR_COPIED) TYPE  CHAR1
*"  EXCEPTIONS
*"      TARGET_NOT_SPECIFIED
*"      NOT_AUTHORIZED
*"      TARGET_ALREADY_EXISTS
*"      SOURCE_CA_DOESNT_EXIST
*"      NOT_AUTHORIZED_TO_DISPLAY
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CR_COPY_CRIT_AUTHS'.
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
  DATA: wa_swaudhdr       TYPE /psyng/swaudhdr.
  DATA: lt_texts TYPE STANDARD TABLE OF /psyng/texts WITH HEADER LINE,
        lt_swaudc2   TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
        lt_swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE.
* BOC by RGUPTA on 07.04.22 for C0700
DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700

  caid_copied = 'N'.
  caid_det_copied = 'N'.
  caid_txt_copied = 'N'.

  IF targetswaudid IS INITIAL.
    RAISE target_not_specified.
    "EXIT.
  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT' FIELD '01'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_AUTID' FIELD targetswaudid.
  IF sy-subrc NE 0.
    RAISE not_authorized.
  ENDIF.

  SELECT SINGLE mandt INTO g_mandt FROM /psyng/swaudhdr
                WHERE swaudid = sourceswaudid.
  IF sy-subrc NE 0.
    RAISE source_ca_doesnt_exist.
  ENDIF.

  SELECT SINGLE mandt INTO g_mandt FROM /psyng/swaudhdr
  WHERE swaudid = targetswaudid.
  IF sy-subrc = 0.
    RAISE target_already_exists.
  ENDIF.
** Check authority of user to read source CA ID
  AUTHORITY-CHECK OBJECT 'Y&SW_CAUTH'
           ID 'ACTVT' FIELD '03'
           ID 'Y&SW_VRSIO' FIELD i_vrsio
           ID 'Y&SW_AUTID' FIELD sourceswaudid.
  IF sy-subrc NE 0.
    RAISE not_authorized_to_display.
  ENDIF.

** Fetch data of source CA ID

  SELECT SINGLE * FROM /psyng/swaudhdr
  INTO CORRESPONDING FIELDS OF wa_swaudhdr
             WHERE swaudid = sourceswaudid
               AND vrsio = i_vrsio.

  SELECT * FROM /psyng/swaudc2
  INTO CORRESPONDING FIELDS OF TABLE lt_swaudc2
                  WHERE swaudid = sourceswaudid
                    AND vrsio = i_vrsio.

  SELECT * FROM /psyng/texts
  INTO CORRESPONDING FIELDS OF
  TABLE lt_texts WHERE textname = sourceswaudid
                  AND   object   = 'T'
                  AND   vrsio    = i_vrsio
                  order by line.

  SORT lt_texts.
  DELETE ADJACENT DUPLICATES FROM lt_texts.

** copy variables
  wa_swaudhdr-swaudid = targetswaudid.
  wa_swaudhdr-create_usr = l_current_user. "sy-uname. C0700
  wa_swaudhdr-create_dat = sy-datum.
  wa_swaudhdr-create_tim = sy-uzeit.

  CLEAR : wa_swaudhdr-change_usr,
          wa_swaudhdr-change_dat,
          wa_swaudhdr-change_tim.


  LOOP AT lt_texts.
    lt_texts-textname = targetswaudid.
    MODIFY lt_texts.
  ENDLOOP.

  LOOP AT lt_swaudc2.
    lt_swaudc2-swaudid = targetswaudid.
    MODIFY lt_swaudc2.
  ENDLOOP.

** Add to Database

  CALL FUNCTION '/PSYNG/SW_CR_ADD_CRI_AUTHS'
    EXPORTING
      wa_swaudid                  = wa_swaudhdr
     i_vrsio                     = i_vrsio
   IMPORTING
   criauth_added               = caid_copied
     criauth_hdr_added           = caid_hdr_copied
     criauth_txt_added           = caid_txt_copied
     criauth_objs_added          = caid_det_copied
   TABLES
     texts                       = lt_texts
     swaudc2                     = lt_swaudc2
*   HISTORY                     =
   EXCEPTIONS
     target_not_specified        = 1
     not_authorized              = 2
     authid_already_exists       = 3
*   OTHERS                      = 4
            .
  CASE sy-subrc.
    WHEN 1.
      RAISE target_not_specified.
    WHEN 2.
      RAISE not_authorized.
    WHEN OTHERS.
  ENDCASE.

ENDFUNCTION.
