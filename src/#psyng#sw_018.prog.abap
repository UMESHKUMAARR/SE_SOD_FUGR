*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/ER_REPORT_USAGE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_018 .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

TABLES: usr02, agr_users, usr10.

TYPE-POOLS: slis.                                      "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv.            "For ALV call

*DATA: iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE.
DATA: iagr_users TYPE STANDARD TABLE OF agr_users WITH HEADER LINE.
DATA: iust04 TYPE STANDARD TABLE OF ust04 WITH HEADER LINE.
DATA: iagr_1016 TYPE STANDARD TABLE OF agr_1016 WITH HEADER LINE.

DATA: g_reject       TYPE /psyng/bapiflagx,
      g_dsp_mng_lock TYPE /psyng/swconfig-value,
      g_dsp_slf_lock TYPE /psyng/swconfig-value,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: BEGIN OF users OCCURS 0.
DATA:   class LIKE usr02-class,
        bname LIKE usr02-bname,
        name_text  LIKE adrp-name_text,
        agr_name LIKE agr_users-agr_name,
        profile  LIKE usr10-profn,
        trdat    LIKE usr02-trdat,
      END OF users.

DATA users2 LIKE TABLE OF users WITH HEADER LINE.


DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
        yusloc   TYPE x VALUE '40',     "Locked by Administrator
        yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
DATA : l_uflagx TYPE x.

TYPES: BEGIN OF typ_usr02,
         bname TYPE usr02-bname,
         class TYPE usr02-class,
         trdat TYPE usr02-trdat,
       END OF typ_usr02.

DATA:
    iusr02       TYPE HASHED TABLE OF typ_usr02 WITH UNIQUE KEY bname
                                                 WITH HEADER LINE,
    lt_uidn      TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE,
    wa_usr02     TYPE typ_usr02,
    l_gltgv      TYPE usr02-gltgv,
    l_gltgb      TYPE usr02-gltgb,
    l_ustyp      TYPE usr02-ustyp,
    l_uflag      TYPE usr02-uflag.

RANGES: lt_bname FOR /psyng/bc_uidn-bname.

DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE,
       i_include_locked TYPE flag,
       i_include_expire TYPE flag.



SELECTION-SCREEN: BEGIN OF BLOCK prms WITH FRAME TITLE text-004.

SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS:   pbname FOR usr02-bname,  "user ID
                  pclass FOR usr02-class,  "user group
                  prole  FOR agr_users-agr_name,  "role
                  pprof  FOR usr10-profn.  "profile
SELECTION-SCREEN SKIP.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.
SELECTION-SCREEN: END OF BLOCK prms .



*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

*------------------------- AT SELECTION-SCREEN ------------------------*

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

*------------------------ START OF SELECTION------------------------*
START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  IF validusr IS INITIAL.
    IF exlckusr = 'X'.
      CLEAR i_include_locked.
    ELSE.
      i_include_locked = 'X'.
    ENDIF.

    IF outvdate = 'X'.
      CLEAR i_include_expire.
    ELSE.
      i_include_expire = 'X'.
    ENDIF.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_041'
       EXPORTING
            i_validuser       = validusr
            i_include_locked  = i_include_locked
            i_include_expired = i_include_expire
       TABLES
            et_users          = lt_users
            it_userlist       = pbname
            it_grouplist      = pclass
            it_usertype       = usrtype.

  CHECK NOT lt_users[] IS INITIAL.

  LOOP AT lt_users.
    wa_usr02-bname = lt_users-bname.
    wa_usr02-class = lt_users-class.
    wa_usr02-trdat = lt_users-trdat.
    INSERT wa_usr02 INTO TABLE iusr02 .
  ENDLOOP.

  LOOP AT iusr02.
    lt_uinfo-bname = iusr02-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
*       VRSIO                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.
  if not iusr02[] is initial.
    SELECT agr_name  uname FROM agr_users
             INTO CORRESPONDING FIELDS OF TABLE iagr_users
             FOR ALL ENTRIES IN iusr02
             WHERE uname = iusr02-bname AND
             agr_name IN prole AND
             from_dat LE sy-datum AND
             to_dat GE sy-datum.
  endif.
  IF NOT iagr_users[] IS INITIAL.
    SELECT agr_name profile FROM agr_1016
             INTO CORRESPONDING FIELDS OF TABLE iagr_1016
             FOR ALL ENTRIES IN iagr_users
             WHERE agr_name EQ iagr_users-agr_name
*----Changed by JS
             AND   profile IN pprof.
    if not iusr02[] is initial.
      SELECT bname profile FROM ust04
               INTO CORRESPONDING FIELDS OF TABLE iust04
               FOR ALL ENTRIES IN iusr02
               WHERE bname = iusr02-bname AND
               profile IN pprof.
    endif.
  ENDIF.

  LOOP AT iusr02.
    users-class = iusr02-class.
    users-trdat = iusr02-trdat.
    LOOP AT iagr_users WHERE uname = iusr02-bname.
      MOVE-CORRESPONDING iusr02 TO users.
      users-agr_name = iagr_users-agr_name.
      IF NOT iagr_1016[] IS INITIAL.
        READ TABLE iagr_1016 WITH KEY agr_name = iagr_users-agr_name.
        IF sy-subrc = 0.
*-- Role with profile
          users-profile = iagr_1016-profile.
          APPEND users.
          DELETE iust04 WHERE bname = iusr02-bname AND
                                profile = iagr_1016-profile.
        ELSE.
*-- Roles without profile
          APPEND users.
        ENDIF.
      ENDIF.
    ENDLOOP.


    CLEAR users-agr_name.

    LOOP AT iust04 WHERE bname = iusr02-bname.
    READ TABLE iagr_1016 WITH KEY profile = iust04-profile.
    IF sy-subrc EQ 0.
      MOVE-CORRESPONDING iusr02 TO users.
      users-profile = iust04-profile.
      APPEND users.
    ENDIF.
    ENDLOOP.
    CLEAR users-profile.
  ENDLOOP.

  PERFORM fill_user_name.



  IF users[] IS INITIAL.
    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s398(00) WITH text-001.
    ELSE.
      MESSAGE s174(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.

  ELSE.

    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s398(00) WITH text-001.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.



  PERFORM output_alv.

*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_alv.
  DATA: program    LIKE sy-repid,
        ls_variant TYPE disvariant.


  program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'USERS'
            i_inclname         = program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  CHECK sy-subrc = 0.
  PERFORM change_catalog_texts.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_layout-get_selinfos = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title       = text-002
            i_callback_program = program
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = users
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    "OUTPUT_ALV

*&---------------------------------------------------------------------*
*&      Form  fill_user_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_user_name.
  DATA: lt_username TYPE STANDARD TABLE OF /psyng/bc_userid_name
                    WITH HEADER LINE.

  LOOP AT iusr02.
    lt_username-bname = iusr02-bname.
    APPEND lt_username.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       EXPORTING
            no_email = 'X'
       TABLES
            username = lt_username.

  LOOP AT users.
    READ TABLE lt_username WITH KEY bname = users-bname.
    CHECK sy-subrc = 0.
    users-name_text = lt_username-name_full.
    MODIFY users.
  ENDLOOP.

ENDFORM.                    " fill_user_name
*&---------------------------------------------------------------------*
*&      Form  change_catalog_texts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_catalog_texts.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = text-003.
  wa_fieldcat_alv-seltext_m = text-003.
  wa_fieldcat_alv-seltext_s = text-005.
  wa_fieldcat_alv-reptext_ddic = text-003.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TRDAT'.

  wa_fieldcat_alv-seltext_l = text-006.
  wa_fieldcat_alv-seltext_m = text-006.
  wa_fieldcat_alv-seltext_s = text-007.
  wa_fieldcat_alv-reptext_ddic = text-006.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

ENDFORM.                    " change_catalog_texts
*&---------------------------------------------------------------------*
*&      Form  f4_usrtype
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USRTYPE_LOW  text
*----------------------------------------------------------------------*
FORM f4_usrtype CHANGING p_usrtype_low.
  DATA: BEGIN OF ls_data,
                  value TYPE domvalue_l,
                  dtext TYPE val_text,
                END OF ls_data,
                lt_data   LIKE TABLE OF ls_data,
                lth_return TYPE TABLE OF ddshretval,
                wah_return LIKE LINE OF lth_return.

  SELECT a~domvalue_l AS value b~ddtext AS dtext
    INTO CORRESPONDING FIELDS OF TABLE lt_data
    FROM dd07l AS a INNER JOIN dd07t AS b
    ON a~domname = b~domname
    AND a~as4local = b~as4local
    AND a~valpos = b~valpos
    AND a~as4vers = b~as4vers
    WHERE a~domname = '/PSYNG/XUUSTYP'
    AND b~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK

  IF   lt_data[] IS INITIAL.
*--Fallback to English
    SELECT a~domvalue_l AS value b~ddtext AS dtext
      INTO CORRESPONDING FIELDS OF TABLE lt_data
      FROM dd07l AS a INNER JOIN dd07t AS b
      ON a~domname = b~domname
      AND a~as4local = b~as4local
      AND a~valpos = b~valpos
      AND a~as4vers = b~as4vers
      WHERE a~domname = '/PSYNG/XUUSTYP'
      AND b~ddlanguage = 'EN'."#EC SAST_CI_GEN_CHECK
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'VALUE'
            value_org       = 'S'
            window_title    = 'Title'
       TABLES
            value_tab       = lt_data
            return_tab      = lth_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = wah_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_initial_config.
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    IF usrtype[] IS INITIAL.
      PERFORM set_def_usrtype.
    ENDIF.
    validusr = ' '.
  ENDIF.
ENDFORM.                    " get_initial_config
