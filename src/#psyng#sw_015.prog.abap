*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_015
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_015 LINE-SIZE 255.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.
TABLES: usr02.

DATA: BEGIN OF itbtcp OCCURS 0 .
DATA:   jobname LIKE tbtcp-jobname,
        sdluname LIKE tbtcp-sdluname,  "scheduler id
        sch_name LIKE adrp-name_text,  "scheduler name
        authcknam LIKE tbtcp-authcknam, "auth user id
        auth_name LIKE adrp-name_text,  "auth user name
        stepcount LIKE tbtcp-stepcount,
        progname LIKE tbtcp-progname,
        sdldate LIKE tbtcp-sdldate,
        sdltime LIKE tbtcp-sdltime,
      END OF itbtcp.

DATA: gf_missing_auth_ugroup TYPE /psyng/bapiflagx.


TYPE-POOLS: slis.                                      "For ALV call
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: gs_sort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_gltgb TYPE sy-datum.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      g_current_user TYPE sy-uname. "C0700
SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-003.
SELECT-OPTIONS:   pbnames FOR usr02-bname,  "schedular user ID
                  pbnamea FOR usr02-bname.  "auth user ID

SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER:   shodiff AS CHECKBOX DEFAULT 'X' .  "show all
SELECTION-SCREEN: COMMENT 3(70) text-006.
SELECTION-SCREEN: END OF LINE.
*PARAMETER:   validusr AS CHECKBOX USER-COMMAND usr_fil.
*"Valid and Dialog users only
*
*SELECT-OPTIONS : usrtype FOR usertype MODIF ID usr .
*PARAMETERS: exlckusr AS CHECKBOX DEFAULT 'X'  MODIF ID usr.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: END OF BLOCK exe.

SELECTION-SCREEN: BEGIN OF BLOCK job WITH FRAME TITLE text-004.
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 20(4) text-002.
SELECTION-SCREEN: COMMENT 23(4) text-002.
*SELECTION-SCREEN: POSITION 28.
SELECTION-SCREEN: POSITION 33.
PARAMETER:   pjsd LIKE sy-datum.  "From date
*SELECTION-SCREEN: COMMENT 48(2) text-005.
SELECTION-SCREEN: COMMENT 52(4) text-005.
SELECTION-SCREEN: POSITION 58.
PARAMETER:   pjed LIKE sy-datum.  "From date
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK job.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM init_screen.
*  PERFORM set_def_usrtype.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          PERFORM set_def_usrtype.
          exlckusr = 'X'.
          outvdate = 'X'.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.


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
***********************************
**RKANAKA ADDED CODE ON 08/02/2011
** Validate dates
  IF pjsd > pjed.
    MESSAGE s106(/psyng/sw) WITH text-e05.
    LEAVE LIST-PROCESSING.

  ENDIF.
* **RKANAKA ADDED CODE ON 08/02/2011
***********************************

  PERFORM get_user_data.

END-OF-SELECTION.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF itbtcp[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.

  SORT itbtcp BY sdldate ASCENDING  sdltime ASCENDING.
  PERFORM build_sort_table.
  PERFORM alv_output.


*&---------------------------------------------------------------------*
*&      Form  init_screen
*&---------------------------------------------------------------------*
FORM init_screen.
  DATA : l_value TYPE /psyng/param_value.

*--Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' l_value.
  IF l_value = 'Y'.
    validusr = 'X'.
  ELSEIF l_value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR l_value.

*-- Inititalize start date and end date
  IF pjsd IS INITIAL.
    pjsd = '18010101'.  "initialize start date as Jan 01, 1801
  ENDIF.
  IF pjed IS INITIAL.
    pjed = '99991231'.
  ENDIF.

  PERFORM exelog.
ENDFORM.                    " init_screen

*&---------------------------------------------------------------------*
*&      Form  get_user_data
*&---------------------------------------------------------------------*
FORM get_user_data.
  DATA: l_reject       TYPE /psyng/bapiflagx,
        l_dsp_mng_lock TYPE /psyng/swconfig-value,
        l_dsp_slf_lock TYPE /psyng/swconfig-value,
        wa_tbtcp       TYPE tbtcp.
  DATA : lt_itbtcp TYPE TABLE OF tbtcp WITH HEADER LINE.
*  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
*************************************
**RKANAKA ADDED CODE ON 10/02/2011
  DATA:BEGIN OF lt_usr02,
       bname LIKE usr02-bname,
       END OF lt_usr02.
**RKANAKA ADDED CODE ON 10/02/2011
***************************************

  DATA :  i_include_locked TYPE flag,
          i_include_expire TYPE flag,
          wa_usr02 TYPE usr02.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE.

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
            i_validuser      = validusr
            i_include_locked = i_include_locked
            i_include_expired = i_include_expire
       TABLES
            et_users         = lt_users
            it_userlist      = pbnames
*            it_grouplist     = s_class
            it_usertype      = usrtype.
*
  CHECK NOT lt_users[] IS INITIAL.

*  LOOP AT lt_users.
*    wa_usr02-bname = lt_users-bname.
*    wa_usr02-class = lt_users-class.
*    INSERT wa_usr02 INTO TABLE iusr02 .
*  ENDLOOP.

*  SELECT * FROM tbtcp
*        INTO  TABLE lt_itbtcp
*        FOR ALL ENTRIES IN lt_users
*        WHERE sdluname  EQ lt_users-bname
*          AND authcknam IN pbnamea AND
*              sdldate GE pjsd AND
*              sdldate LE pjed.

  SELECT jobname     "#EC CI_NOFIELD
         sdluname
         authcknam
         stepcount
         progname
         sdldate
         sdltime
       FROM tbtcp
        INTO CORRESPONDING FIELDS OF TABLE lt_itbtcp
        FOR ALL ENTRIES IN lt_users
        WHERE sdluname  EQ lt_users-bname
          AND authcknam IN pbnamea AND
              sdldate GE pjsd AND
              sdldate LE pjed.


*DHO 20101202

  IF sy-subrc EQ 0.

    LOOP AT lt_itbtcp.
      lt_uinfo-bname = lt_itbtcp-sdluname.
      APPEND lt_uinfo.
    ENDLOOP.
    SORT lt_uinfo BY bname.
    DELETE ADJACENT DUPLICATES FROM lt_uinfo COMPARING bname.
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
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
        IF sy-subrc <> 0.
          gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
          gt_rpoug_auth_fail-class   = lt_uinfo-class.
          gt_rpoug_auth_fail-company = lt_uinfo-company.
          APPEND gt_rpoug_auth_fail.
          CLEAR gt_rpoug_auth_fail.
          DELETE lt_itbtcp WHERE sdluname = lt_uinfo-bname.
          gf_missing_auth_ugroup = 'X'.
        ENDIF.
      ELSEIF NOT lt_uinfo-class IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
          ID 'CLASS' FIELD lt_uinfo-class
          ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
          gt_rpoug_auth_fail-class   = lt_uinfo-class.
          gt_rpoug_auth_fail-company = lt_uinfo-company.
          APPEND gt_rpoug_auth_fail.
          CLEAR gt_rpoug_auth_fail.
          DELETE lt_itbtcp WHERE sdluname = lt_uinfo-bname.
          gf_missing_auth_ugroup = 'X'.
        ENDIF.
      ELSEIF NOT lt_uinfo-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
        IF sy-subrc <> 0.
          gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
          gt_rpoug_auth_fail-class   = lt_uinfo-class.
          gt_rpoug_auth_fail-company = lt_uinfo-company.
          APPEND gt_rpoug_auth_fail.
          CLEAR gt_rpoug_auth_fail.
          DELETE lt_itbtcp WHERE sdluname = lt_uinfo-bname.
          gf_missing_auth_ugroup = 'X'.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  LOOP AT lt_itbtcp INTO wa_tbtcp.

    CLEAR l_reject.

*      IF validusr = 'X'.
*        CALL FUNCTION '/PSYNG/CHECK_VALID_DIALOG_USER'
*             EXPORTING
*                  i_bname        = wa_tbtcp-sdluname
*                  i_dsp_mng_lock = l_dsp_mng_lock
*                  i_dsp_slf_lock = l_dsp_slf_lock
*             IMPORTING
*                  e_reject       = l_reject.
*      ENDIF.
**DHO 20101202
**    PERFORM check_ugroup_auth USING wa_tbtcp-sdluname
**                              CHANGING l_reject.
*      CHECK l_reject IS INITIAL.

    IF shodiff = 'X'.
      IF wa_tbtcp-authcknam <> wa_tbtcp-sdluname.
        MOVE-CORRESPONDING wa_tbtcp TO itbtcp.
        APPEND itbtcp.
      ENDIF.
    ELSE.
      MOVE-CORRESPONDING wa_tbtcp TO itbtcp.
      APPEND itbtcp.
    ENDIF.
  ENDLOOP.
*  ENDSELECT.
*  ENDIF.

ENDFORM.                    " get_user_data
*&---------------------------------------------------------------------*
*&      Form  alv_output
*&---------------------------------------------------------------------*
FORM alv_output.
  DATA: alv_layout      TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl   TYPE lvc_title,                  "For ALV call
        ls_variant      TYPE disvariant.


  PERFORM get_usernames.

  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'ITBTCP'
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

*  MOVE text-009 TO alv_grid_titl.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_grid_title             = alv_grid_titl
            i_callback_program       = program
            i_callback_top_of_page = 'ALV_HEADER'
            is_layout                = alv_layout
            i_callback_pf_status_set = 'PF_STATUS'
            it_sort                  = gs_sort
            i_callback_user_command  = 'USER_DOUBLE_CLICK'
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = itbtcp
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2.
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " alv_output


*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status USING it_extab TYPE slis_t_extab.
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  SET PF-STATUS 'SW_015' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary

*---------------------------------------------------------------------*
*       FORM user_double_click                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exelog.
  DATA: task_name(8),
        exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  MOVE sy-uzeit TO task_name.
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    STARTING NEW TASK task_name DESTINATION IN GROUP DEFAULT
    TABLES
     exelog         = exelog.
  COMMIT WORK.

ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_usernames
*&---------------------------------------------------------------------*
FORM get_usernames.
  DATA: username TYPE STANDARD TABLE OF /psyng/bc_userid_name
        WITH HEADER LINE.

  LOOP AT itbtcp.
    username-bname = itbtcp-sdluname.
    APPEND username.
    username-bname = itbtcp-authcknam.
    APPEND username.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       EXPORTING
            no_email = 'X'
       TABLES
            username = username.

  LOOP AT itbtcp.
    READ TABLE username WITH KEY bname = itbtcp-sdluname BINARY SEARCH.
    IF sy-subrc = 0.
      itbtcp-sch_name = username-name_full.
    ENDIF.

    READ TABLE username WITH KEY bname = itbtcp-authcknam BINARY SEARCH.
    IF sy-subrc = 0.
      itbtcp-auth_name = username-name_full.
    ENDIF.
    MODIFY itbtcp.
  ENDLOOP.

  REFRESH: username.
ENDFORM.                    " get_usernames
*&---------------------------------------------------------------------*
*&      Form  change_catalog_texts
*&---------------------------------------------------------------------*
FORM change_catalog_texts.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = text-010.
  wa_fieldcat_alv-seltext_m = text-010.
  wa_fieldcat_alv-seltext_s = text-011.
  wa_fieldcat_alv-reptext_ddic = text-010.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SDLUNAME'.

  wa_fieldcat_alv-seltext_l = text-012.
  wa_fieldcat_alv-seltext_m = text-012.
  wa_fieldcat_alv-seltext_s = text-013.
  wa_fieldcat_alv-reptext_ddic = text-012.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SCH_NAME'.

  wa_fieldcat_alv-seltext_l = text-014.
  wa_fieldcat_alv-seltext_m = text-014.
  wa_fieldcat_alv-seltext_s = text-015.
  wa_fieldcat_alv-reptext_ddic = text-014.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUTHCKNAM'.

  wa_fieldcat_alv-seltext_l = text-016.
  wa_fieldcat_alv-seltext_m = text-016.
  wa_fieldcat_alv-seltext_s = text-017.
  wa_fieldcat_alv-reptext_ddic = text-016.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUTH_NAME'.

  wa_fieldcat_alv-seltext_l = text-018.
  wa_fieldcat_alv-seltext_m = text-018.
  wa_fieldcat_alv-seltext_s = text-019.
  wa_fieldcat_alv-reptext_ddic = text-018.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SDLTIME'.

  wa_fieldcat_alv-seltext_l = text-020.
  wa_fieldcat_alv-seltext_m = text-020.
  wa_fieldcat_alv-seltext_s = text-021.
  wa_fieldcat_alv-reptext_ddic = text-020.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SDLDATE'.
ENDFORM.                    " update_column_names

*&---------------------------------------------------------------------*
*&      Form  check_ugroup_auth
*&---------------------------------------------------------------------*
*       Check authority to user group
*----------------------------------------------------------------------*
*      -->I_BNAME   User ID
*      <--E_REJECT  Reject record?  X = Reject, Space = Keep
*----------------------------------------------------------------------*
FORM check_ugroup_auth USING    i_bname TYPE usr02-bname
                       CHANGING e_reject TYPE /psyng/bapiflagx.
*STATICS: BEGIN OF lt_user OCCURS 0,
*           bname  TYPE usr02-bname,
*           reject TYPE /psyng/bapiflagx,
*         END OF lt_user,
*
*         BEGIN OF lt_ugroup OCCURS 0,
*           class  TYPE usr02-class,
*           reject TYPE /psyng/bapiflagx,
*         END OF lt_ugroup.
*
*DATA: l_class        TYPE usr02-class,
*      l_user_tabix   TYPE i,
*      l_ugroup_tabix TYPE i.
*
** Check if user has already been found
*  READ TABLE lt_user WITH KEY bname = i_bname BINARY SEARCH.
*  IF sy-subrc = 0.
*    e_reject = lt_user-reject.
*    EXIT.
*  ENDIF.
*
*  l_user_tabix = sy-tabix.
*
*  SELECT SINGLE class INTO l_class FROM usr02
*                WHERE bname = i_bname.
*
** Check if user group has already been found
*  READ TABLE lt_ugroup WITH KEY class = l_class BINARY SEARCH.
*  IF sy-subrc = 0.
*    lt_user-bname  = i_bname.
*    lt_user-reject = lt_ugroup-reject.
*    INSERT lt_user INDEX l_user_tabix.
*
*    e_reject = lt_ugroup-reject.
*    EXIT.
*  ENDIF.
*
*  l_ugroup_tabix = sy-tabix.
*
*  IF NOT l_class IS INITIAL.
**DHO 20101202
**    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
**             ID 'CLASS' FIELD l_class.
*    IF sy-subrc <> 0.
*      gf_missing_auth_ugroup = 'X'.
*      lt_ugroup-reject       = 'X'.
*      lt_user-reject         = 'X'.
*      e_reject               = 'X'.
*    ENDIF.
*  ENDIF.
*
*  lt_user-bname = i_bname.
*  INSERT lt_user INDEX l_user_tabix.
*  lt_ugroup-class = l_class.
*  INSERT lt_ugroup INDEX l_ugroup_tabix.
ENDFORM.                    " check_ugroup_auth
*&---------------------------------------------------------------------*
*&      Form  set_def_usrtype
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM set_def_usrtype.
*  REFRESH usrtype.
*  CLEAR usrtype.
*  usrtype-sign = 'I'.
*  usrtype-option = 'EQ'.
*  usrtype-low = 'A'.
*  APPEND usrtype.
*ENDFORM.                    " set_def_usrtype
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

  SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
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
    SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
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
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA : alv_layout      TYPE slis_layout_alv,
            alv_grid_titl   TYPE lvc_title,
            i_fieldcat_alv  TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: gs_variant TYPE disvariant.

  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  REFRESH i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
          i_grid_title          = alv_grid_titl
          is_layout             = alv_layout
          it_fieldcat           = i_fieldcat_alv
          i_save                = 'A'
          is_variant            = gs_variant
   	TABLES
          t_outtab              = gt_rpoug_auth_fail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'JOBNAME'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'SDLUNAME'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'SCH_NAME'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'AUTHCKNAM'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'AUTH_NAME'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'STEPCOUNT'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'PROGNAME'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'SDLDATE'.
  l_sort-tabname = 'ITBTCP'.
  l_sort-up = 'X'.
  APPEND l_sort TO gs_sort.


ENDFORM.                    " build_sort_table


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: lt_header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_count TYPE i,
        exetime(8) TYPE c,
        exedate TYPE char10,
        temp(90),
        alv_grid_titl TYPE lvc_title.


  MOVE text-009 TO alv_grid_titl.

  wa-typ = 'H'.
  wa-info = alv_grid_titl.
  APPEND wa TO lt_header.

*User & Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname C0700
   text-h04 exedate exetime
              INTO wa-info SEPARATED BY SPACE.
  APPEND wa TO lt_header.

    CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = lt_header.
 ENDFORM.
