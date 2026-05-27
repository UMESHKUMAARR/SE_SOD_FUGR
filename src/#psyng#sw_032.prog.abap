*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_032
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_032 .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

TABLES: usr02.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv,
      gf_reject TYPE /psyng/bapiflagx,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: BEGIN OF gt_output OCCURS 0,
        bname LIKE usr02-bname,
        bname_full LIKE  /psyng/bc_userid_name-name_full,
        class LIKE usr02-class,
        status(10),
        ustyp LIKE usr02-ustyp,
        aname LIKE usr02-aname,
        aname_full LIKE  /psyng/bc_userid_name-name_full,
        erdat LIKE usr02-erdat,
        trdat LIKE usr02-trdat,
      END OF gt_output.

DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y'.

DATA: gt_username TYPE STANDARD TABLE OF /psyng/bc_userid_name
      WITH HEADER LINE.
DATA:   g_yulock   TYPE x VALUE '80',     "Locked by incorrect login
        g_yusloc   TYPE x VALUE '40',     "Locked by Administrator
        g_yugloc   TYPE x VALUE '20'.    "Locked by global Administrator
DATA : g_uflagx TYPE x.
DATA : gt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
DATA : gt_users TYPE TABLE OF usr02 WITH HEADER LINE,
       gf_include_locked TYPE flag,
       gf_include_expire TYPE flag.

TYPES: BEGIN OF typ_usr02,
       bname TYPE usr02-bname,
       class TYPE usr02-class,
       aname TYPE usr02-aname,
       erdat TYPE usr02-erdat,
       uflag TYPE usr02-uflag,
       ustyp TYPE usr02-ustyp,
       trdat TYPE usr02-trdat,
       END OF typ_usr02.

DATA: gt_usr02 TYPE HASHED TABLE OF typ_usr02 WITH UNIQUE KEY bname
                                                       WITH HEADER LINE.
DATA: wa_usr02 LIKE LINE OF gt_usr02,
      g_current_user TYPE sy-uname. "C0700
SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-004.
SELECT-OPTIONS: userlist FOR usr02-bname,
                s_class  FOR usr02-class.
*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.
SELECTION-SCREEN: SKIP 2.

SELECT-OPTIONS: creator FOR usr02-bname.
SELECT-OPTIONS: dates   FOR sy-datum.
SELECTION-SCREEN: END OF BLOCK exe.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.
  dates-sign = 'I'. dates-option = 'BT'.
  dates-low = sy-datum - 7. dates-high = sy-datum. APPEND dates.
  PERFORM get_initial_config.

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

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

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
      CLEAR gf_include_locked.
    ELSE.
      gf_include_locked = 'X'.
    ENDIF.

    IF outvdate = 'X'.
      CLEAR gf_include_expire.
    ELSE.
      gf_include_expire = 'X'.
    ENDIF.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_041'
       EXPORTING
            i_validuser       = validusr
            i_include_locked  = gf_include_locked
            i_include_expired = gf_include_expire
       TABLES
            et_users          = gt_users
            it_userlist       = userlist
            it_grouplist      = s_class
            it_usertype       = usrtype.

  IF NOT gt_users[] IS INITIAL.
    DELETE gt_users WHERE NOT erdat IN dates.
    DELETE gt_users WHERE NOT aname IN creator.


    LOOP AT gt_users.
      wa_usr02-bname = gt_users-bname.
      wa_usr02-class = gt_users-class.
      wa_usr02-erdat = gt_users-erdat.
      wa_usr02-aname = gt_users-aname.
      wa_usr02-uflag = gt_users-uflag.
      wa_usr02-ustyp = gt_users-ustyp.
      wa_usr02-trdat = gt_users-trdat.
      INSERT wa_usr02 INTO TABLE gt_usr02 .
    ENDLOOP.

    LOOP AT gt_usr02.
      CLEAR gf_reject.
      PERFORM check_ugroup_auth USING gt_usr02-class
                                CHANGING gf_reject.
      CHECK gf_reject IS INITIAL.

      MOVE-CORRESPONDING gt_usr02 TO gt_output.

*--Sf CASE 1405
      g_uflagx = gt_usr02-uflag.
      IF g_uflagx O g_yusloc OR "locked by admin
         g_uflagx O g_yugloc OR "locked by CUA admin
         g_uflagx  O g_yulock.  "self locked
        gt_output-status = text-003.
      ELSE.
        gt_output-status = text-005.
      ENDIF.
      APPEND gt_output.
      CLEAR gt_output.
    ENDLOOP.
*    ENDSELECT.
*  ELSE.
*    PERFORM get_sw_repo_conifg.
*    SELECT * FROM usr02 INTO wa_usr02
*                        WHERE bname IN userlist AND
*                              class IN s_class AND
*                              erdat IN dates AND
*                              aname IN creator AND
*                              ustyp = 'A'.
*
*      CLEAR gf_reject.
*      PERFORM check_ugroup_auth USING wa_usr02-class
*                                CHANGING gf_reject.
*      CHECK gf_reject IS INITIAL.
*
*      IF wa_usr02-gltgv IS INITIAL.  "valid from date
*        wa_usr02-gltgv = '00010101'.
*      ENDIF.
*      IF wa_usr02-gltgb IS INITIAL.  "valid to date
*        wa_usr02-gltgb = '99991231'.
*      ENDIF.
*      MOVE-CORRESPONDING wa_usr02 TO output.
*
*      IF wa_usr02-gltgv <= sy-datum AND wa_usr02-gltgb >= sy-datum.
**Sf CASE 1405
*        l_uflagx =  wa_usr02-uflag."unicode
*        IF l_uflagx O yusloc OR "locked by admin
*           l_uflagx O yugloc.   "locked by CUA admin
**      --User is locked by Local or Global Administrator
*           IF dsp_mng_lock = 'Y'.
*             output-status = TEXT-003.
*             APPEND output..
*           ENDIF.
*        ELSEIF l_uflagx O yulock.
**      --User is locked by failed logins
*          IF dsp_slf_lock = 'Y'.
*            output-status = TEXT-003.
*            APPEND output.
*          ENDIF.
*        ELSE.
**      --User is active
*        output-status = TEXT-005.
*        APPEND output.
*        ENDIF.
*        CASE wa_usr02-uflag.
*          WHEN 0.   "user ID unlocked
*            output-status = TEXT-005.
*            APPEND output.
*          WHEN 64.  "user ID locked by system manager
*            IF dsp_mng_lock = 'Y'.
*              output-status = TEXT-003.
*              APPEND output.
*            ENDIF.
*          WHEN 128. "user ID locked due to incorrect logins
*            IF dsp_slf_lock = 'Y'.
*              output-status = text-003.
*              APPEND output.
*            ENDIF.
*        ENDCASE.
*      ENDIF.
*      CLEAR output.
*    ENDSELECT.
*  ENDIF.

    LOOP AT gt_output.
      gt_username-bname = gt_output-bname.
      APPEND gt_username.
      gt_username-bname = gt_output-aname.
      APPEND gt_username.
    ENDLOOP.

    SORT gt_username.
    DELETE ADJACENT DUPLICATES FROM gt_username.

    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
         EXPORTING
              no_email = 'X'
         TABLES
              username = gt_username.
    LOOP AT gt_output.
      READ TABLE gt_username WITH KEY bname = gt_output-bname
           BINARY SEARCH TRANSPORTING name_full.
      IF sy-subrc = 0.
        gt_output-bname_full = gt_username-name_full.
      ENDIF.
      READ TABLE gt_username WITH KEY bname = gt_output-aname
           BINARY SEARCH TRANSPORTING name_full.
      IF sy-subrc = 0.
        gt_output-aname_full = gt_username-name_full.
      ENDIF.
      MODIFY gt_output.
    ENDLOOP.

    SORT gt_output.
  ENDIF.

  IF gt_output[] IS INITIAL.
    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s398(00) WITH text-002.
    ELSE.
      MESSAGE s174(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSE.
    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s398(00) WITH text-002.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.

*  IF gf_missing_auth_ugroup = 'X'.
*    MESSAGE s398(00) WITH text-002.
*  ENDIF.



  PERFORM output_via_alv.

*&---------------------------------------------------------------------*
*&      Form  output_via_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_via_alv.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.


  PERFORM build_alv_catalog.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
*  MOVE text-001 TO alv_grid_titl.

  PERFORM build_sort_table.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_grid_title       = alv_grid_titl
            i_callback_program = g_program
            i_callback_top_of_page = 'ALV_HEADER'
            it_sort            = isort
            is_layout          = alv_layout
            it_fieldcat        = i_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_via_alv

*---------------------------------------------------------------------*
*       FORM build_alv_catalog                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = g_program
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

  wa_fieldcat_alv-seltext_l = text-010.
  wa_fieldcat_alv-seltext_m = text-010.
  wa_fieldcat_alv-seltext_s = text-010.
  wa_fieldcat_alv-reptext_ddic = text-010.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-seltext_l = text-011.
  wa_fieldcat_alv-seltext_m = text-011.
  wa_fieldcat_alv-seltext_s = text-011.
  wa_fieldcat_alv-reptext_ddic = text-011.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME_FULL'.

  wa_fieldcat_alv-seltext_l = text-012.
  wa_fieldcat_alv-seltext_m = text-012.
  wa_fieldcat_alv-seltext_s = text-012.
  wa_fieldcat_alv-reptext_ddic = text-012.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ANAME_FULL'.

  wa_fieldcat_alv-seltext_l = text-013.
  wa_fieldcat_alv-seltext_m = text-013.
  wa_fieldcat_alv-seltext_s = text-013.
  wa_fieldcat_alv-reptext_ddic = text-013.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'STATUS'.

  wa_fieldcat_alv-seltext_l = text-014.
  wa_fieldcat_alv-seltext_m = text-014.
  wa_fieldcat_alv-seltext_s = text-014.
  wa_fieldcat_alv-reptext_ddic = text-014.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ERDAT'.

  wa_fieldcat_alv-seltext_l = text-015.
  wa_fieldcat_alv-seltext_m = text-016.
  wa_fieldcat_alv-seltext_s = text-016.
  wa_fieldcat_alv-reptext_ddic = text-016.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TRDAT'.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM build_sort_table                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'BNAME_FULL'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'STATUS'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'USTYP'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'ANAME'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'ANAME_FULL'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'ERDAT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'TRDAT'.
  l_sort-tabname = 'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_sw_repo_conifg                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_sw_repo_conifg.
  DATA: swconfig TYPE /psyng/swconfig.

  CLEAR: swconfig.
  se_config_param 'REP_USR_LOK_DSP_MGR' swconfig-value.
  IF swconfig-value = 'Y'.
    dsp_mng_lock = 'Y'.
  ENDIF.
  CLEAR swconfig.
  se_config_param 'REP_USR_LOK_DSP_SLF' swconfig-value.
  IF swconfig-value = 'N'.
    dsp_slf_lock = 'N'.
  ENDIF.
ENDFORM.                    " get_sw_repo_conifg

*&---------------------------------------------------------------------*
*&      Form  check_ugroup_auth
*&---------------------------------------------------------------------*
*       Check authority to user group
*----------------------------------------------------------------------*
*      -->I_CLASS   User Group
*      <--E_REJECT  Reject record?  X = Reject, Space = Keep
*----------------------------------------------------------------------*
FORM check_ugroup_auth USING    i_class TYPE usr02-class
                       CHANGING e_reject TYPE /psyng/bapiflagx.
  STATICS: BEGIN OF lt_ugroup OCCURS 0,
             class  TYPE usr02-class,
             reject TYPE /psyng/bapiflagx,
           END OF lt_ugroup.

  DATA: l_ugroup_tabix TYPE i.

* Check if user group has already been found
  READ TABLE lt_ugroup WITH KEY class = i_class BINARY SEARCH.
  IF sy-subrc = 0.
    e_reject = lt_ugroup-reject.
    EXIT.
  ENDIF.

  l_ugroup_tabix = sy-tabix.

  IF NOT i_class IS INITIAL.
*DHO 20101202
*****Case : 3036
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*             ID 'CLASS' FIELD i_class.
*    IF sy-subrc <> 0.
*      gf_missing_auth_ugroup = 'X'.
*      lt_ugroup-reject       = 'X'.
*      e_reject               = 'X'.
*    ENDIF.
  ENDIF.

  lt_ugroup-class = i_class.
  INSERT lt_ugroup INDEX l_ugroup_tabix.
ENDFORM.                    " check_ugroup_auth
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA : l_value TYPE /psyng/param_value.
*Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' l_value.
  IF l_value = 'Y'.
    validusr = 'X'.
  ELSEIF l_value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR l_value.

ENDFORM.                    " get_initial_config
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
               lt_return TYPE TABLE OF ddshretval,
               ls_return LIKE LINE OF lt_return.

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
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = ls_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: lt_header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_count TYPE i,
        l_exetime(8) TYPE c,
        l_exedate TYPE char10,
        temp(90),
        alv_grid_titl TYPE lvc_title.

*  CONCATENATE text-000 lockcountc INTO temp
*              SEPARATED BY space.
*  CONCATENATE temp text-001 expcountc INTO temp
*              SEPARATED BY space.
*  CONCATENATE temp text-002 INTO temp
*              SEPARATED BY space.
*  CONCATENATE temp delcountc INTO temp
*              SEPARATED BY space.
*  CONCATENATE temp ')' INTO temp.

  MOVE text-001 TO alv_grid_titl.

  wa-typ = 'H'.
  wa-info = alv_grid_titl.
  APPEND wa TO lt_header.
*User & Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname      C0700
   text-h04 l_exedate l_exetime
              INTO wa-info SEPARATED BY SPACE.
  APPEND wa TO lt_header.

    CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = lt_header.
 ENDFORM.
