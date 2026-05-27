
*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_030
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
REPORT /psyng/sw_030 LINE-SIZE 255 NO STANDARD PAGE HEADING.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

TABLES: /psyng/criprof, usr02 , rfcdes.

TYPE-POOLS: slis.                                      "For ALV call
Include /psyng/sw_030_top.


*-- Selection Screen

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-000.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(28) text-001.
SELECT-OPTIONS: userlist FOR usr02-bname.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(28) text-017.
SELECT-OPTIONS: s_class FOR usr02-class.
SELECTION-SCREEN: END OF LINE.

*RFC destination for remote analysis
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(28) text-047.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: END OF LINE.



*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:remote AS CHECKBOX USER-COMMAND remo DEFAULT ' '.
SELECTION-SCREEN: COMMENT 3(50) text-049.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: SKIP 2.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(28) text-002.
SELECT-OPTIONS: profiles FOR /psyng/criprof-profile.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS s_owner FOR /psyng/criprof-owner.
SELECT-OPTIONS s_imp FOR /psyng/criprof-imp.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(28) text-016.
SELECTION-SCREEN POSITION 33.
PARAMETERS: sodvrsio LIKE /psyng/conflict-vrsio.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 1(30) snstxt.
*SELECT-OPTIONS: sens FOR /psyng/criprof-imp.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.
  PERFORM initialize.
*  PERFORM set_def_usrtype.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR profiles-low.
  PERFORM f4_ctprof CHANGING profiles-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR profiles-high.
  PERFORM f4_ctprof CHANGING profiles-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

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

AT SELECTION-SCREEN.

  PERFORM at_selection_screen.

****Only remote analysis Check
  IF sy-ucomm = 'REMO'.
    IF remote = 'X'.
      IF remrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.


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
  IF NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

*--get RFC destination.
*  PERFORM get_rfc_destinations.

* add local system to list of rfc destinations
  IF remote NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO g_local_sys.
    gt_rfcdest-rfcoptions = g_local_sys.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.


*--Get Users
  PERFORM get_users_in_question.

  IF NOT gt_uinfo[] IS INITIAL.
    gt_uinfo_temp[] = gt_uinfo[].
    SORT gt_uinfo_temp BY rfcdest bname.
    DELETE ADJACENT DUPLICATES FROM gt_uinfo_temp
      COMPARING rfcdest bname.

    DESCRIBE TABLE gt_uinfo_temp LINES g_usercount.


*-- Get Critical Profile configed in system
    PERFORM get_users_with_crit_profiles.
*-- Get all Critical profile from all system.
    PERFORM get_data_by_user.
*-- Fill other data
    PERFORM build_output.
  ENDIF.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF output[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.
*  PERFORM get_users_profiles.
  PERFORM output_via_alv.

*&---------------------------------------------------------------------*
*&      Form  get_users_in_question
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_users_in_question.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  DATA: "la_usr02 TYPE usr02,
        l_gltgv  TYPE usr02-gltgv,
        l_gltgb  TYPE usr02-gltgb,
        l_ustyp  TYPE usr02-ustyp,
        l_uflag  TYPE usr02-uflag,
        i_include_locked TYPE flag,
        i_include_expire TYPE flag.

*  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
*  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE.
*
*  IF validusr IS INITIAL.
*    IF exlckusr = 'X'.
*      CLEAR i_include_locked.
*    ELSE.
*      i_include_locked = 'X'.
*    ENDIF.
*
*    IF outvdate = 'X'.
*      CLEAR i_include_expire.
*    ELSE.
*      i_include_expire = 'X'.
*    ENDIF.
*  ENDIF.
*  CALL FUNCTION '/PSYNG/SW_041'
*       EXPORTING
*            i_validuser       = validusr
*            i_include_locked  = i_include_locked
*            i_include_expired = i_include_expire
*       TABLES
*            et_users          = lt_users
*            it_userlist       = userlist
*            it_grouplist      = s_class
*            it_usertype       = usrtype.
**
*  CHECK NOT lt_users[] IS INITIAL.
*
*  LOOP AT lt_users.
*    la_usr02-bname = lt_users-bname.
*    la_usr02-class = lt_users-class.
*    INSERT la_usr02 INTO TABLE iusr02 .
*  ENDLOOP.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_USER_INFO_NEW'
       EXPORTING
            i_validuser   = validusr
            i_exlckusr    = exlckusr
            i_outvdate    = outvdate
            i_remote_only = remote
       TABLES
            it_users      = userlist
            it_usergroup  = s_class
            it_usertype   = usrtype
            it_user_rfc   = remrfc
            et_uinfo      = lt_uinfo.

  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.


*  IF validusr IS INITIAL.
**    SELECT class bname INTO TABLE iusr02
**           FROM usr02
**           WHERE bname IN users
**             AND class IN s_class.
*    SELECT class bname INTO TABLE iusr02
*          FROM usr02
*          WHERE bname IN userlist
*            AND class IN s_class.
*
*  ELSE.
*    PERFORM get_sw_repo_conifg.
*    SELECT class bname gltgv gltgb ustyp uflag
*           INTO (la_usr02-class, la_usr02-bname, l_gltgv, l_gltgb,
*                 l_ustyp, l_uflag)
*           FROM usr02
*           WHERE bname IN userlist
*             AND class IN s_class
*             AND ustyp = 'A'.
*
*      IF l_gltgv IS INITIAL.  "valid from date
*        l_gltgv = '00010101'.
*      ENDIF.
*      IF l_gltgb IS INITIAL.  "valid to date
*        l_gltgb = '99991231'.
*      ENDIF.
*      IF l_gltgv <= sy-datum AND l_gltgb >= sy-datum.
**--Sf CASE 1405
*        l_uflagx = l_uflag."unicode
*        IF l_uflagx O yusloc OR "locked by admin
*           l_uflagx O yugloc.   "locked by CUA admin
**      --User is locked by Local or Global Administrator
*          IF dsp_mng_lock = 'Y'.
*            INSERT la_usr02 INTO TABLE iusr02.
*          ENDIF.
*        ELSEIF l_uflagx O yulock.
**      --User is locked by failed logins
*          IF dsp_slf_lock = 'Y'.
*            INSERT la_usr02 INTO TABLE iusr02.
*          ENDIF.
*        ELSE.
**      --User is active
*          INSERT la_usr02 INTO TABLE iusr02.
*        ENDIF.

*        CASE l_uflag.
*          WHEN 0.   "user ID unlocked
*            INSERT la_usr02 INTO TABLE iusr02.
*          WHEN 64.  "user ID locked by system manager
*            IF dsp_mng_lock = 'Y'.
*              INSERT la_usr02 INTO TABLE iusr02.
*            ENDIF.
*          WHEN 128. "user ID locked due to incorrect logins
*            IF dsp_slf_lock = 'Y'.
*              INSERT la_usr02 INTO TABLE iusr02.
*            ENDIF.
*        ENDCASE.

*      ENDIF.
*    ENDSELECT.
*  ENDIF.
*DHO 20101202
*  LOOP AT iusr02 INTO la_usr02.
*    AT NEW class.
*      CHECK NOT la_usr02-class IS INITIAL.
*      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*               ID 'CLASS' FIELD la_usr02-class.
*      IF sy-subrc <> 0.
*        gf_missing_auth_ugroup = 'X'.
*        DELETE iusr02 WHERE class = la_usr02-class.
*      ENDIF.
*    ENDAT.
*  ENDLOOP.
*DHO 20101202


*  CHECK NOT iusr02[] IS INITIAL.
*  LOOP AT iusr02.
*    lt_uinfo-bname = iusr02-bname.
*    APPEND lt_uinfo.
*  ENDLOOP.
*  CALL FUNCTION '/PSYNG/SW_USER_INFO'
*   EXPORTING
*     vrsio                    = sodvrsio
**       ENHANCED_SCANTABLE       = ''
*     i_name_only              = 'X'
*     i_mr_company             = 'X'
*    TABLES
*      sw_uinfo                 = lt_uinfo.

  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.

  gt_uinfo[] = lt_uinfo[].
*  IF  iusr02[] IS INITIAL.
**-- Do nothing
*  ELSE.
*
** REFERENCE USER begin of addition 1
*    IF NOT iusr02 IS INITIAL.
*      SELECT bname refuser FROM usrefus
*        INTO CORRESPONDING FIELDS OF TABLE iusrefus1
*        FOR ALL ENTRIES IN iusr02 WHERE
*        refuser NE space AND
*        bname = iusr02-bname.
*    ENDIF.
*
** add reference users to the list of users to get profiles for
*    LOOP AT iusrefus1.
*      la_usr02-bname = iusrefus1-refuser.
*      la_usr02-class = 'REFUSER'.
*      INSERT la_usr02 INTO TABLE iusr02.
*    ENDLOOP.
** REFERENCE USER end of addition 1
*
**    SELECT * FROM ust04
**             INTO CORRESPONDING FIELDS OF TABLE iust04
**             FOR ALL ENTRIES IN iusr02 WHERE bname = iusr02-bname.
*
*    LOOP AT iusr02.
*      gt_username-bname = iusr02-bname.
*      APPEND gt_username.
*    ENDLOOP.
*
*    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
*         EXPORTING
*              no_email = 'X'
*         TABLES
*              username = gt_username.
*  ENDIF.

ENDFORM.                    " get_users_in_question
**&---------------------------------------------------------------------
**
**&      Form  get_users_profiles
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
*FORM get_users_profiles.
*
*  IF  iusr02[] IS INITIAL.
*    MESSAGE s146(/psyng/sw).
*    LEAVE LIST-PROCESSING.
**   No Data Selected
*
*  ELSE.
*    DATA: username TYPE STANDARD TABLE OF /psyng/bc_userid_name
*          WITH HEADER LINE,
*          la_usr02 TYPE usr02,
*          icriprof TYPE SORTED TABLE OF /psyng/criprof
*                   WITH UNIQUE KEY profile WITH HEADER LINE,
*          iust04   TYPE STANDARD TABLE OF ust04 WITH HEADER LINE.
*
*
**    SELECT * FROM /psyng/criprof
**             INTO CORRESPONDING FIELDS OF TABLE icriprof
**             WHERE profile IN profiles
**             AND   vrsio   =  sodvrsio
***           AND
***                 imp IN sens
**             ORDER BY profile.
*
** REFERENCE USER begin of addition 1
*    IF NOT iusr02 IS INITIAL.
*      SELECT bname refuser FROM usrefus
*        INTO CORRESPONDING FIELDS OF TABLE iusrefus1
*        FOR ALL ENTRIES IN iusr02 WHERE
*        refuser NE space AND
*        bname = iusr02-bname.
*    ENDIF.
*
** add reference users to the list of users to get profiles for
*    LOOP AT iusrefus1.
*      la_usr02-bname = iusrefus1-refuser.
*      la_usr02-class = 'REFUSER'.
*      INSERT la_usr02 INTO TABLE iusr02.
*    ENDLOOP.
** REFERENCE USER end of addition 1
*
**    SELECT * FROM ust04
**             INTO CORRESPONDING FIELDS OF TABLE iust04
**             FOR ALL ENTRIES IN iusr02 WHERE bname = iusr02-bname.
*
*    LOOP AT iusr02.
*      username-bname = iusr02-bname.
*      APPEND username.
*    ENDLOOP.
*
*    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
*         EXPORTING
*              no_email = 'X'
*         TABLES
*              username = username.
*
*    LOOP AT gt_ust04.
*      READ TABLE iusr02 WITH KEY bname = gt_ust04-bname.
*      IF sy-subrc NE 0.
*        CONTINUE.
*      ENDIF.
*      READ TABLE gt_critprof WITH KEY profile = gt_ust04-profile
*                 TRANSPORTING imp owner.
*      CHECK sy-subrc = 0.  "check profile is critical profile?
*      MOVE-CORRESPONDING gt_ust04 TO output.
*      output-imp = gt_critprof-imp.
*      output-owner = gt_critprof-owner.
*      CASE output-imp.
*        WHEN 'HIGH'.
*          output-imporder = 1.
*        WHEN 'MEDIUM'.
*          output-imporder = 2.
*        WHEN 'LOW'.
*          output-imporder = 3.
*        WHEN OTHERS.
*      ENDCASE.
*      READ TABLE username WITH KEY bname = gt_ust04-bname BINARY SEARCH
*.
*      IF sy-subrc = 0.
*        output-name = username-name_full.
*      ENDIF.
*      APPEND output.
*    ENDLOOP.
*
** REFERENCE USER begin of addition 2
*    LOOP AT iusrefus1.
*      LOOP AT output INTO wa_output WHERE bname = iusrefus1-refuser.
*        wa_output-bname = iusrefus1-bname.
*        READ TABLE username WITH KEY bname = wa_output-bname
*             BINARY SEARCH.
*        IF sy-subrc = 0.
*          wa_output-name = username-name_full.
*        ENDIF.
*        INSERT wa_output INTO TABLE output.
*      ENDLOOP.
*    ENDLOOP.
*
** remove reference users from the list of users
*    LOOP AT iusr02 WHERE class = 'REFUSER'.
*      DELETE output WHERE bname = iusr02-bname.
*    ENDLOOP.
** REFERENCE USER end of addition 2
*
*    SORT output BY imporder profile bname.
*    DELETE ADJACENT DUPLICATES FROM output.
*  ENDIF.
*ENDFORM.                    " get_users_profiles
*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
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
*&      Form  output_via_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_via_alv.
  DATA: alv_layout    TYPE slis_layout_alv,
        alv_grid_titl TYPE lvc_title,
        ls_variant    TYPE disvariant.


  PERFORM build_alv_catalog.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'Users with critical profiles'(004) TO alv_grid_titl.

  PERFORM build_sort_table.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER'
            i_grid_title             = alv_grid_titl
            i_callback_program       = g_program
            it_sort                  = gisort
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_DOUBLE_CLICK'
            is_layout                = alv_layout
            it_fieldcat              = gi_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = output
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


  SET PF-STATUS 'SW_030' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  g_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gi_fieldcat_alv
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

*  wa_fieldcat_alv-seltext_l = text-011.
*  wa_fieldcat_alv-seltext_m = text-011.
*  wa_fieldcat_alv-seltext_s = text-012.
*  wa_fieldcat_alv-reptext_ddic = text-011.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'PROFILE'.



* Hide column IMPSORT
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'IMPORDER'.

  wa_fieldcat_alv-seltext_l = 'Sensitivity'(011).
  wa_fieldcat_alv-seltext_m = 'Sensitivity'(011).
  wa_fieldcat_alv-seltext_s = 'Sens'(012).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity'(011).
*--Hiding this field because it's not maintainable from Crit. Prof tab
*--- Making this visible as of SE 3.1 ---***** HS
*  wa_fieldcat_alv-no_out = 'X'.
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
*                      no_out
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat_alv-seltext_l = 'User Full Name'(013).
  wa_fieldcat_alv-seltext_m = 'User Name'(014).
  wa_fieldcat_alv-seltext_s = 'Name'(015).
  wa_fieldcat_alv-reptext_ddic = 'User Name'(014).
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'NAME'.

  wa_fieldcat_alv-seltext_l = 'User ID'(018).
  wa_fieldcat_alv-seltext_m = 'User ID'(018).
  wa_fieldcat_alv-seltext_s = 'User ID'(018).
  wa_fieldcat_alv-reptext_ddic = 'User ID'(018).
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-seltext_l = 'Profile Text'(020).
  wa_fieldcat_alv-seltext_m = 'Profile Text'(020).
  wa_fieldcat_alv-seltext_s = 'Profile Text'(020).
  wa_fieldcat_alv-reptext_ddic = 'Profile Text'(020).
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'PROF_TXT'.


  wa_fieldcat_alv-seltext_l = 'System/Client'(019).
  wa_fieldcat_alv-seltext_m = 'System/Client'(019).
  wa_fieldcat_alv-seltext_s = 'System/Client'(019).
  wa_fieldcat_alv-reptext_ddic = 'System/Client'(019).
  MODIFY gi_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.


ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'IMPORDER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'PROF_TXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.


  l_sort-spos = '5'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.


  l_sort-spos = '7'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'NAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gisort.

ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_count TYPE i,
        lv_exetime(8) TYPE c,
        lv_exedate TYPE char10,
        c_count TYPE string,
        c_usercount(6) TYPE c,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  wa-typ = 'H'.
  wa-info = 'Users with Critical Profiles'(h01).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO lv_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO lv_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname C0700
   text-h04 lv_exedate lv_exetime INTO wa-info
  SEPARATED BY space.
*  wa-info = l_date.
  APPEND wa TO header.

*Summary.
  wa-typ = 'S'.
  wa-key = 'Summary'(h05).
  c_usercount = g_usercount.
  CONCATENATE c_usercount text-h06 INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_users_with_crit_profiles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_with_crit_profiles.


**** Creating list of user those who have critical roles assigned
  SELECT * FROM /psyng/criprof                     "#EC CI_NO_TRANSFORM
             INTO TABLE gt_critprof
             WHERE profile IN profiles
             AND owner IN s_owner
             AND imp IN s_imp
             AND   vrsio = sodvrsio
             ORDER BY profile.
* Commented by shekhar , In this case we get users those assigned into
*local system only
*IF sy-subrc = 0.
*    SELECT * FROM ust04 INTO TABLE gt_ust04
*    FOR ALL ENTRIES IN gt_critprof WHERE
*    profile EQ gt_critprof-profile
*    AND bname IN userlist.              " Filter By usernam
*
*    IF sy-subrc = 0.
*
*      users-sign = 'I'.
*      users-option = 'EQ'.
*      LOOP AT gt_ust04.
*        users-low = gt_ust04-bname.
*        APPEND users.
*      ENDLOOP.
*
*      SORT users.
*      DELETE ADJACENT DUPLICATES FROM users.
*    ELSE.
*      MESSAGE s146(/psyng/sw).
*      LEAVE LIST-PROCESSING.
*    ENDIF.
*  ELSE.
*    MESSAGE s146(/psyng/sw).
*    LEAVE LIST-PROCESSING.
*  ENDIF.

*****Get Profile Texts
  IF NOT gt_critprof[] IS INITIAL.

    SELECT * FROM usr11 INTO TABLE gt_usr11
              FOR ALL ENTRIES IN gt_critprof
                WHERE profn = gt_critprof-profile.

  ENDIF.

ENDFORM.                    " get_users_with_crit_profiles
*&---------------------------------------------------------------------*
*&      Form  f4_ctprof
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_PROFILES_LOW  text
*----------------------------------------------------------------------*
FORM f4_ctprof CHANGING e_prof TYPE /psyng/criprof-profile.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctprof TYPE /psyng/criprof,
        lt_cprof TYPE TABLE OF /psyng/criprof WITH HEADER LINE.

  DATA : BEGIN OF cprof OCCURS 0,
  ptext TYPE usr11-ptext.
          INCLUDE STRUCTURE /psyng/criprof.
  DATA END OF cprof.

*    SELECT * INTO ls_ctprof FROM /psyng/criprof
*                          WHERE vrsio = p_vrsio
*                          ORDER BY profile.
*     move-corresponding ls_ctprof to cprof.
*  SELECT a~profile
*         a~vrsio
**         a~description
*         a~imp
*         a~owner
*         b~ptext INTO CORRESPONDING FIELDS OF TABLE cprof
*         FROM /psyng/criprof AS a INNER JOIN usr11 AS b
*         ON a~profile EQ b~profn
*         WHERE vrsio = sodvrsio
*           AND langu EQ sy-langu.

SELECT * FROM /psyng/criprof INTO TABLE lt_cprof WHERE vrsio = sodvrsio.

  LOOP AT lt_cprof.
    MOVE-CORRESPONDING lt_cprof TO cprof.
    SELECT SINGLE ptext FROM usr11 INTO (cprof-ptext)
    WHERE profn = lt_cprof-profile
    AND langu = sy-langu.
    IF sy-subrc NE 0.
      cprof-ptext =  'Profile for Cross system analysis'(061).
    ENDIF.
    APPEND cprof.
  ENDLOOP.


  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/CRIPROF'.
  lt_fields-fieldname = 'PROFILE'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-tabname   = 'USR11'.
  lt_fields-fieldname = 'PTEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRIPROF'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ''.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ''.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'DESCRIPTION'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.



  LOOP AT cprof.
    lt_values-line = cprof-profile.
    APPEND lt_values.
    lt_values-line = cprof-ptext.
    APPEND lt_values.
    lt_values-line = cprof-vrsio.
    APPEND lt_values.
    lt_values-line = cprof-imp.
    APPEND lt_values.
    lt_values-line = cprof-owner.
    APPEND lt_values.
*    lt_values-line = cprof-description.
*    APPEND lt_values.

  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = 'Critical Pofiles'(t12)
       IMPORTING
            select_value              = e_prof
       TABLES
            fields                    = lt_fields
            valuetab                  = lt_values
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


* Get values for popup
*  SELECT * INTO ls_ctprof FROM /psyng/criprof
*                          WHERE vrsio = sodvrsio
*                          ORDER BY profile.
*    lt_values-line = ls_ctprof-profile.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-vrsio.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-imp.
*    APPEND lt_values.
*    lt_values-line = ls_ctprof-owner.
*    APPEND lt_values.
*  ENDSELECT.
*
*
*  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*       EXPORTING
*            retfield        = 'PROFILE'
*       TABLES
*            value_tab       = lt_values
*            field_tab       = lt_fields
*            return_tab      = lt_return
*       EXCEPTIONS
*            parameter_error = 1
*            no_values_found = 2
*            OTHERS          = 3.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*  READ TABLE lt_return INDEX 1.
*  e_prof = lt_return-fieldval.
ENDFORM.
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

  DATA : i_profile LIKE /psyng/criprof-profile.
  DATA:l_desc TYPE /psyng/texts-text.
*  DATA : s_text TYPE usr11-ptext.
  DATA: BEGIN OF s_text OCCURS 0 ,
      text LIKE agr_texts-text,
      END OF s_text.
  CASE rs_selfield-fieldname.
    WHEN 'PROFILE'.

      CHECK rs_selfield-value <> space.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      i_profile = rs_selfield-value.
      REFRESH: gt_text.
      CLEAR gs_critprof.

      SELECT SINGLE * FROM /psyng/criprof
      INTO CORRESPONDING FIELDS OF gs_critprof
      WHERE profile = i_profile AND vrsio = sodvrsio.

      IF sy-subrc = 0.
        SELECT line text FROM /psyng/texts
                INTO corresponding fields of TABLE s_text
                WHERE textname = i_profile
                AND   object   = 'P'
                AND   vrsio    = sodvrsio
                AND   spras    = sy-langu
                order by line.
        IF sy-subrc = 0.
          gt_text[] = s_text[].
        ENDIF.
      ENDIF.

      IF gs_critprof-ptext IS INITIAL.
        SELECT SINGLE ptext FROM usr11
        INTO  gs_critprof-ptext
        WHERE profn = i_profile AND aktps = 'A'.
        IF sy-subrc NE 0.
          gs_critprof-ptext = 'Profile for Cross System Analysis'(061).
        ENDIF.
      ENDIF.

* gt_critprof-text = s_text.

*  g_vrsio = sodvrsio.
      CALL SCREEN 1202 STARTING AT 20 3.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  init_1202  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_1202 OUTPUT.
  SET PF-STATUS '1202'.
  PERFORM init_editor_1202.
ENDMODULE.                 " init_1202  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  init_editor_1202
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_editor_1202.
  DATA: l_text  LIKE TABLE OF gt_text.

  STATICS: l_text_reload TYPE /psyng/flagx,
           lo_textedit   TYPE REF TO cl_gui_textedit,
           lo_container  TYPE REF TO cl_gui_custom_container.


  IF l_text_reload = space.
    l_text_reload = 'X'.

*   create control container
    IF lo_textedit IS INITIAL.
      CREATE OBJECT lo_container
          EXPORTING
              container_name              = 'CC_PROF'
          EXCEPTIONS
              cntl_error                  = 1
              cntl_system_error           = 2
              create_error                = 3
              lifetime_error              = 4
              lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.

*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT lo_textedit
        EXPORTING
           parent = lo_container
           wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
           wordwrap_to_linebreak_mode = cl_gui_textedit=>false
        EXCEPTIONS
            others = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.

    CALL METHOD lo_textedit->set_readonly_mode
          EXPORTING
            readonly_mode          = cl_gui_textedit=>true
          EXCEPTIONS
            error_cntl_call_method = 1
            invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

  l_text[] = gt_text[].

* fill with text
  CALL METHOD lo_textedit->set_text_as_r3table
    EXPORTING
      table           = l_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDFORM.                    " init_editor_1202
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1202  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1202 INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " USER_COMMAND_1202  INPUT
*&---------------------------------------------------------------------*
*&      Form  get_data_by_user
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data_by_user.

  DATA : l_local_sys TYPE rfcdes-rfcdest,
           lt_objs  TYPE TABLE OF /psyng/sw_xuobject,
           ls_obj   TYPE /psyng/sw_xuobject,
           ls_tcode TYPE /psyng/sw_tcode,
           lt_tcodes TYPE TABLE OF /psyng/sw_tcode.


  LOOP AT gt_rfcdest.
    IF gt_rfcdest-rfcdest = 'LOCAL'.

      LOOP AT gt_uinfo WHERE rfcdest = g_local_sys.
        iusr02-bname = gt_uinfo-bname.
        APPEND iusr02.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/SW_GET_USER_ROLES_PROF'
       EXPORTING
*       I_ROLE                =
         i_profile             = 'X'
        TABLES
          it_users              = iusr02
          it_profs              = gt_critprof
          et_userroleprof       = gt_usrroleprof_part.

    ELSE.
      LOOP AT gt_uinfo WHERE rfcdest = gt_rfcdest-rfcoptions.
        iusr02-bname = gt_uinfo-bname.
        APPEND iusr02.
      ENDLOOP.
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

      CALL FUNCTION '/PSYNG/SW_GET_USER_ROLES_PROF'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
*       I_ROLE                =
        i_profile             = 'X'
       TABLES
         it_users              = iusr02
         it_profs              = gt_critprof
         et_userroleprof       = gt_usrroleprof_part
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ENDIF.
    APPEND LINES OF gt_usrroleprof_part TO gt_usrroleprof.
    REFRESH gt_usrroleprof_part.
    REFRESH iusr02.

  ENDLOOP.



ENDFORM.                    " get_data_by_user
*&---------------------------------------------------------------------*
*&      Form  get_rfc_destinations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_rfc_destinations.

  DATA : l_rfcdest TYPE rfcdes-rfcdest,
           l_system_msg(80) TYPE c,
           l_local_sys TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT gt_rfcdest ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--Delete any RFC pointing to the local system.
  SORT gt_rfcdest BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM gt_rfcdest COMPARING rfcoptions.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  gt_rfcdest WHERE rfcoptions = l_local_sys
AND rfcdest <> 'LOCAL'.


ENDFORM.                    " get_rfc_destinations
*&---------------------------------------------------------------------*
*&      Form  build_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_output.

  SORT gt_uinfo BY rfcdest bname.


  LOOP AT gt_rfcdest.
    LOOP AT gt_usrroleprof WHERE rfcdest = gt_rfcdest-rfcoptions.

      output-profile = gt_usrroleprof-profn.
* fill profile text
      READ TABLE gt_usr11 WITH KEY profn = gt_usrroleprof-profn
                                   langu = sy-langu.
      IF sy-subrc EQ 0.
        output-prof_txt = gt_usr11-ptext.
      ELSE.
        output-prof_txt = 'Profile for Cross System Analysis'(061).
      ENDIF.
      CLEAR gt_usr11-ptext.
      output-rfcdest = gt_usrroleprof-rfcdest.

* fill sensitivity & owner
      READ TABLE gt_critprof WITH KEY profile = gt_usrroleprof-profn.
      IF sy-subrc EQ 0.
        output-imp = gt_critprof-imp.
        output-owner = gt_critprof-owner.
      ENDIF.
      output-bname = gt_usrroleprof-bname.

* fill username.
      READ TABLE gt_uinfo WITH KEY
                        bname = gt_usrroleprof-bname
                        rfcdest = gt_usrroleprof-rfcdest.
*                        BINARY SEARCH.
      IF sy-subrc EQ 0.
        output-name = gt_uinfo-name_text.
      ENDIF.
      APPEND output.

    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " build_output

*&---------------------------------------------------------------------*
*&      Form  at_selection_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM at_selection_screen.

*  CHECK NOT remrfc[] IS INITIAL.
*  DATA : l_rfcdest TYPE rfcdes-rfcdest,
*           l_system_msg(80) TYPE c,
*           l_local_sys TYPE rfcdest.
*  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.
*
*  SELECT rfcdest INTO TABLE gt_rfcdest FROM rfcdes
*         WHERE rfcdest IN remrfc.
*  IF sy-subrc <> 0.
*    MESSAGE e004(sr).
*  ENDIF.


ENDFORM.                    " at_selection_screen
*&---------------------------------------------------------------------*
*&      Form  initialize
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize.

ENDFORM.                    " initialize
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
             gi_fieldcat_alv  TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: ls_variant TYPE disvariant.

  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  REFRESH gi_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO gi_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  APPEND wa_fieldcat_alv TO gi_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO gi_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
          i_grid_title          = alv_grid_titl
          is_layout             = alv_layout
          it_fieldcat           = gi_fieldcat_alv
          i_save                = 'A'
          is_variant            = ls_variant
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
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
       r_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE.


  APPEND LINES OF remrfc TO r_rfcs.
  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup    = 'X'
            i_module   = 'SE'
       IMPORTING
            e_continue = l_continue
       TABLES
            it_rfcdes  = r_rfcs.
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
      it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc."#EC SAST_CI_GEN_CHECK
  ENDIF.

  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.


ENDFORM.                    " load_role_rfc

FORM get_users_count.
  DATA : l_numb TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local type flag value 'X'.

  IF remote = 'X'.
    clear lv_local.
  endif.
  IF exlckusr EQ 'X'.
    CLEAR lv_exlckusr.
  ELSEIF exlckusr IS INITIAL.
    lv_exlckusr = 'X'.
  ENDIF.

  IF outvdate EQ 'X'.
    CLEAR lv_outvdate.
  ELSEIF outvdate IS INITIAL.
    lv_outvdate = 'X'.
  ENDIF.

CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
 EXPORTING
   I_VALIDUSER             = validusr
   I_INCLUDE_LOCKED        = lv_exlckusr
   I_INCLUDE_EXPIRED       = lv_outvdate
   IF_LOCAL_SYSTEM         = lv_local
   IF_SHOW_MESSAGE         = 'X'
 IMPORTING
   E_USERCOUNT             = l_numb
 TABLES
   IT_USERLIST             = userlist
   IT_GROUPLIST            = s_class
   IT_USERTYPE             = usrtype
*   IT_ACTGROUPS            = s_role
*   IT_PROFILE              = s_prof
   IT_RFCRANGE             = remrfc
*   IT_RFCLIST              =
*   IT_DEPARTMENT           = s_depart
*   IT_COMPANY              = s_comp
*   IT_CUID                 = s_cuid
   .

ENDFORM.                    " get_users_count
