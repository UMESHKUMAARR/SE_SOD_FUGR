*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_114
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
REPORT /psyng/sw_114.
TABLES : /psyng/function,
         /psyng/swsodorgm,
*         /psyng/dorg,
          fupararef,
          agr_prof,
          agr_define,
          tstc,
          tobjt.

DATA : gt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
       gt_usobt TYPE TABLE OF usobt WITH HEADER LINE,
       gt_texts TYPE TABLE OF /psyng/texts WITH HEADER LINE,
       gt_funhdr TYPE TABLE OF /psyng/function WITH HEADER LINE,
       gt_dorgvalu TYPE TABLE OF /psyng/bc_dorgvalu WITH HEADER LINE,
       g_rolename TYPE agr_name,
       g_all_rolename TYPE agr_name,
*       gt_usobt TYPE TABLE OF usobt WITH HEADER LINE,
       gt_usobt_c TYPE TABLE OF usobt_c WITH HEADER LINE,
       gt_usorg TYPE TABLE OF usorg  WITH HEADER LINE,
       gs_org TYPE /psyng/bc_dorg.

DATA: gv_curr_report LIKE  rsvar-report,
      gv_curr_variant LIKE  rsvar-variant,
      gt_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      exit_proc.
DATA: gv_program         LIKE sy-repid,
      gf_org_with_star TYPE flag.

DATA: gs_agr_define  TYPE          agr_define,
      gs_agr_texts   TYPE          agr_texts,
      gt_agr_texts   TYPE TABLE OF agr_texts,
      gt_agr_tcodes  TYPE TABLE OF agr_tcodes,
      gs_agr_tcodes  TYPE          agr_tcodes,
      gt_field_values TYPE TABLE OF pt1251 WITH HEADER LINE,
      gt_auth        TYPE TABLE OF pt1250 WITH HEADER LINE,
      gt_org         TYPE TABLE OF pt1252  WITH HEADER LINE,
      g_len TYPE i,
      gf_invalid TYPE flag.

DATA : g_name TYPE char30,
       gt_usobt_temp LIKE TABLE OF gt_usobt,
       gt_usobtc_temp LIKE TABLE OF gt_usobt_c.

DATA: g_node  TYPE i,
       gv_auth(10) TYPE c,
       gv_authcount(2) TYPE c,
       gv_issue TYPE c.

DATA: g_profile_name LIKE usr10-profn.

DATA: gv_variant LIKE vari-variant.
DATA: gt_rsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: gt_varit TYPE varit OCCURS 0 WITH HEADER LINE.

DATA : BEGIN OF gt_org1 OCCURS 0,
       abb TYPE /psyng/dorg_abb,
       END OF gt_org1,
       gt_tab_org TYPE dd02l-tabname VALUE '/PSYNG/DORG'.

*Selection Screen

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETER:rolename(10) TYPE c VISIBLE LENGTH 10,
          sodvrsio TYPE /psyng/vrsio.
SELECT-OPTIONS function FOR /psyng/function-function.
SELECTION-SCREEN SKIP 1.
*PARAMETER: p_der AS CHECKBOX.
*SELECT-OPTIONS s_org FOR gs_org-abb.


SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME .
*SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b07.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-025 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-026 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-002 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-001 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN: END OF BLOCK bgd_o.

INITIALIZATION.
*  PERFORM check_rd.

AT SELECTION-SCREEN.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
  ENDIF.
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
*  PERFORM check_rd.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  gv_program = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (gv_program)                      "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET gv_curr_variant .
  ENDIF.


  PERFORM get_data.
  PERFORM create_role.
*  IF p_der = 'X'.
*    CLEAR gf_org_with_star.
*    PERFORM create_derived_roles.
*  ENDIF.

*  IF p_der NE 'X'.
*    gf_org_with_star = 'X'.
*  ENDIF.

*-------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data.

  SELECT * FROM /psyng/function
  INTO TABLE gt_funhdr
  WHERE function IN function AND vrsio = sodvrsio.
  IF sy-subrc = 0.
    SELECT tcode functionid FROM /psyng/functtran
    INTO CORRESPONDING FIELDS OF TABLE gt_functtran
    WHERE functionid IN function AND vrsio = sodvrsio.

    IF sy-subrc = 0.
      SELECT * FROM /psyng/texts INTO TABLE gt_texts
       WHERE textname IN function
       AND object = 'F'
       AND vrsio = sodvrsio
       AND spras = sy-langu
       ORDER BY line.
    ENDIF.

  ELSE.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

*  CHECK NOT s_org[] IS INITIAL.
*  SELECT abb FROM (gt_tab_org) INTO TABLE gt_org1
*   WHERE abb IN s_org.
*  IF sy-subrc NE 0.
*    MESSAGE s002(/psyng/sw) WITH 'Invalid Org. Level'(031).
*    LEAVE LIST-PROCESSING.
*  ENDIF.
*
*  SELECT * FROM usorg INTO TABLE gt_usorg.
ENDFORM.                    " get_data
*&---------------------------------------------------------------------*
*&      Form  create_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_role.
  DATA: lt_tcodes  TYPE STANDARD TABLE OF twbtcode WITH HEADER LINE,
         l_rolename TYPE agr_name,
         l_roledesc TYPE agr_texts-text,
         l_roledesc1 TYPE agr_texts-text,
         l_roledesc2 TYPE agr_texts-text,
         l_date(10) TYPE c,
         l_time(8) TYPE c,
         l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 05.04.22 for C0700
*         gf_org_with_star TYPE flag.


  IF NOT gt_functtran[] IS INITIAL.
    SORT gt_functtran BY functionid.

    LOOP AT gt_functtran.
      CLEAR lt_tcodes.
      lt_tcodes-tcode = gt_functtran-tcode.
      APPEND lt_tcodes.
      AT END OF functionid.
        IF sodvrsio IS INITIAL OR sodvrsio EQ '000'.
          sodvrsio = '000'.
        ENDIF.
        CONCATENATE rolename gt_functtran-functionid '_' sodvrsio
        INTO g_rolename.
*   create role description
       READ TABLE gt_funhdr WITH KEY function = gt_functtran-functionid.
        CONCATENATE 'Function role : '
        gt_funhdr-description
        INTO l_roledesc SEPARATED BY space.

        l_roledesc1 =
        'Role generated by Security Weaver - Separations Enforcer'.
        WRITE sy-datum TO l_date.
        WRITE sy-uzeit TO l_time.
        CONCATENATE l_date l_time l_current_user "sy-uname C0700
         INTO l_roledesc2
        SEPARATED BY space.

** Check FM Parameters to diffrentiate 4.6 & ECC

        SELECT SINGLE funcname FROM fupararef        "#EC CI_SEL_NESTED
        INTO fupararef-funcname
        WHERE funcname = 'PRGN_RFC_CREATE_ACTIVITY_GROUP'
        AND paramtype EQ 'I'
        AND parameter = 'NO_CHECK_ON_TCODES'.
** 4.6
        IF sy-subrc = 0.
   CALL FUNCTION 'PRGN_RFC_CREATE_ACTIVITY_GROUP' "#EC SAST_CI_GEN_CHECK
     EXPORTING
       activity_group                      = g_rolename
       activity_group_text                 = l_roledesc
       comment_text_line_1                 = l_roledesc1
       comment_text_line_2                 = l_roledesc2
*   COMMENT_TEXT_LINE_3                 = ' '
*   COMMENT_TEXT_LINE_4                 = ' '
*   PROFILE_NAME                        = ' '
*   PROFILE_TEXT                        = ' '
       org_levels_with_star                = 'X'
       no_popup_for_org_levels             = 'X'
       unmaintained_fields_with_star       = ' '
       template                            = ' '
*   EXTERNAL_AUTH_DATA                  = ' '
*   ONLY_TCODE_ASSIGNMENT               = ' '
          no_check_on_tcodes                  = 'X'
     TABLES
         tcodes                              = lt_tcodes
*   HIERARCHY_NODES                     =
*   HIERARCHY_TEXTS                     =
      EXCEPTIONS
          activity_group_already_exists       = 1
          activity_group_enqueued             = 2
          namespace_problem                   = 3
          illegal_characters                  = 4
          error_when_creating_actgroup        = 5
          profile_name_exists                 = 6
          profile_not_in_namespace            = 7
          no_tcodes_selected                  = 8
          illegal_tcodes                      = 9
          not_authorized                      = 10
          profgen_tables_not_updated          = 11
          error_when_generating_profile       = 12
          OTHERS                              = 13
                      .
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE e002(/psyng/sw) WITH 'Role already Exists'(005).
              WHEN 2.
                MESSAGE e002(/psyng/sw) WITH 'Role is locked'(006).
              WHEN 3.
                MESSAGE e002(/psyng/sw) WITH 'Role name incorrect'(007).
              WHEN 4.
            MESSAGE e002(/psyng/sw) WITH 'Role Illegal characters'(008).
              WHEN 5.
           MESSAGE e002(/psyng/sw) WITH 'Error when creating Role'(009).
              WHEN 6.
                MESSAGE e002(/psyng/sw) WITH 'Profile name exists'(010).
              WHEN 7.
          MESSAGE e002(/psyng/sw) WITH 'Profile not in name space'(011).
              WHEN 8.
                MESSAGE e002(/psyng/sw) WITH 'No Transactions'(012).
              WHEN 9.
               MESSAGE e002(/psyng/sw) WITH 'Illegal transactions'(013).
              WHEN 10.
            MESSAGE e002(/psyng/sw) WITH ' You are not authorized'(014).
              WHEN 11.
          MESSAGE e002(/psyng/sw) WITH 'PROFGEN table not updated'(015).
              WHEN 12.
      MESSAGE e002(/psyng/sw) WITH 'Error when generating profile'(016).
              WHEN 13.
                MESSAGE e002(/psyng/sw) WITH 'Unknown error'(017).
            ENDCASE.
          ELSE.
            MESSAGE i002(/psyng/sw) WITH 'Function Role :'(018)
                                           g_rolename
                                          'Succesfully created .'(019).
            MESSAGE i113(/psyng/sw) WITH text-020 text-021.
          ENDIF.
          REFRESH lt_tcodes.
          CLEAR : l_roledesc, l_roledesc1,l_roledesc2.

**   ECC
        ELSE.
          REFRESH : gt_agr_tcodes,
                    gt_usobtc_temp,
                    gt_usobt_c,
                    gt_field_values,
                    gt_usobt,
                    gt_auth,
                    gt_org.

          CLEAR :   gt_agr_tcodes,
                    gt_usobtc_temp,
                    gt_usobt_c,
                    gt_field_values,
                    gt_usobt,
                    gt_auth,
                    gt_org,
                    "l_roledesc,
                    "l_roledesc1,
                    "l_roledesc2,
                    gs_agr_tcodes.

          IF NOT lt_tcodes[] IS INITIAL.
            gs_agr_tcodes-type = 'TR'.
            LOOP AT lt_tcodes.
              gs_agr_tcodes-tcode = lt_tcodes-tcode.
              PERFORM check_tcode USING gf_invalid.
              IF gf_invalid = 'X'.
                CONTINUE.
              ENDIF.
              APPEND gs_agr_tcodes TO gt_agr_tcodes.
            ENDLOOP.
          ENDIF.

          REFRESH lt_tcodes.

          IF gt_agr_tcodes[] IS INITIAL.
            MESSAGE s002(/psyng/sw) WITH 'No Transactions'(012).
            CONTINUE.
          ENDIF.

* Check authorisation for role creation
        CALL FUNCTION 'PRGN_AUTH_ACTIVITY_GROUP' "#EC SAST_CI_GEN_CHECK
             EXPORTING
                  activity_group = g_rolename
                  action_create  = 'X'
                  message_output = SPACE
             EXCEPTIONS
                  not_authorized = 1
                  OTHERS         = 2.
          IF sy-subrc NE 0.
            MESSAGE e002(/psyng/sw) WITH ' You are not authorized'(014).
          ENDIF.

* Check role name validity
   CALL FUNCTION 'PRGN_CHECK_NAMESPACE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
        EXPORTING
             activity_group         = g_rolename
        IMPORTING
             soft_namespace_problem = gv_issue
        EXCEPTIONS
             namespace_error        = 1
             illegal_characters     = 2
             OTHERS                 = 3.

          IF sy-subrc EQ 1 OR gv_issue NE space.
            MESSAGE e002(/psyng/sw) WITH 'Role name incorrect'(007).
          ELSEIF sy-subrc EQ 2.
            MESSAGE e002(/psyng/sw) WITH 'Role Illegal characters'(008).
          ENDIF.

** Check role name already exist or not

          SELECT SINGLE * FROM agr_define WHERE agr_name = g_rolename.
          IF sy-subrc = 0.
            MESSAGE e002(/psyng/sw) WITH 'Role already Exists'(005).
          ENDIF.

* Role creation
          CLEAR: gs_agr_define, gs_agr_texts.
          REFRESH gt_agr_texts.

* Definition
          gs_agr_define-mandt      = sy-mandt.
          gs_agr_define-agr_name   = g_rolename.
          gs_agr_define-create_dat = sy-datum.
          gs_agr_define-create_tim = sy-uzeit.
          gs_agr_define-create_usr = l_current_user. "sy-uname. C0700
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
          CALL FUNCTION 'FUNCTION_EXISTS'
            EXPORTING
              funcname                 = 'PRGN_RFC_CREATE_AGR_MULTIPLE'
           EXCEPTIONS
             function_not_exist       = 1
             OTHERS                   = 2
                    .
          IF sy-subrc <> 0.
        MESSAGE s002(/psyng/sw) WITH 'PRGN_RFC_CREATE_AGR_MULTIPLE'(100)
          'does not exist'(101) DISPLAY LIKE 'E'.
            LEAVE LIST-PROCESSING.
          ELSE.
            CALL FUNCTION 'PRGN_RFC_CREATE_AGR_MULTIPLE'
            EXPORTING
              activity_group                      = g_rolename
           EXCEPTIONS
             activity_group_already_exists       = 1
             invalid_inheriting_role             = 2
             activity_group_enqueued             = 3
             namespace_problem                   = 4
             illegal_characters                  = 5
             error_when_creating_actgroup        = 6
             not_authorized                      = 7
             OTHERS                              = 8.
            IF sy-subrc <> 0.
              MESSAGE 'An exception Occured While creating role'(003)
                TYPE 'S'
                DISPLAY LIKE 'E'.
              LEAVE LIST-PROCESSING.
            ENDIF.
          ENDIF.

*          INSERT agr_define FROM gs_agr_define.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
* Change document
        CALL FUNCTION 'PRGN_CHANGEDOCUMENT_WRITE' "#EC SAST_CI_GEN_CHECK
             EXPORTING
                  activity_group = g_rolename
                  upd_agr_define = 'I'
                  n_agr_define   = gs_agr_define.

* Setting COLL_AGR flag
     CALL FUNCTION 'PRGN_SET_COLLECTIVE_AGR_FLAG' "#EC SAST_CI_GEN_CHECK
          EXPORTING
               activity_group      = g_rolename
               collective_agr_flag = space.

* Other attributes
         CALL FUNCTION 'PRGN_SET_AGR_ATTRIBUTES' "#EC SAST_CI_GEN_CHECK
              EXPORTING
                   activity_group    = g_rolename
                   master_language   = sy-langu
                   responsible_user  = l_current_user "sy-uname C0700
                   development_class = SPACE.
*--2020/10/02 - No need to delete this flag as it was never set
*          DELETE FROM agr_flags WHERE agr_name  = g_rolename
*                                AND   flag_type = 'DEVCLASS'.

* Insert in Texts in role
*          DELETE FROM agr_texts WHERE agr_name = g_rolename.
          gs_agr_texts-mandt    = sy-mandt.
          gs_agr_texts-agr_name = g_rolename.
          gs_agr_texts-spras    = sy-langu.

* Short text
          gs_agr_texts-line     = 0.
          IF l_roledesc NE space.
            gs_agr_texts-text = l_roledesc .
          ENDIF.
          APPEND gs_agr_texts TO gt_agr_texts.
** Change document for short text
*          CALL FUNCTION 'PRGN_CHANGEDOCUMENT_WRITE'
*               EXPORTING
*                    activity_group = g_rolename
*                    upd_agr_texts  = 'I'
*               TABLES
*                    n_agr_texts    = gt_agr_texts.


          IF l_roledesc1 EQ space AND
             l_roledesc2 EQ space .
**  Do nothing
          ELSE.

*   Line 1
            gs_agr_texts-line = 1.
            gs_agr_texts-text = l_roledesc1.
            APPEND gs_agr_texts TO gt_agr_texts.
*   Line 2
            gs_agr_texts-line = 2.
            gs_agr_texts-text = l_roledesc2.
            APPEND gs_agr_texts TO gt_agr_texts.
          ENDIF.

*          INSERT agr_texts FROM TABLE gt_agr_texts.
          CALL FUNCTION 'PRGN_RFC_CHANGE_TEXTS' "#EC SAST_CI_GEN_CHECK
            EXPORTING
              activity_group                      = g_rolename
*     NO_DIALOG                           = 'X'
*     REQUEST                             =
*   IMPORTING
*     NEW_REQUEST                         =
            TABLES
              texts                               = gt_agr_texts
*     RETURN                              =
           EXCEPTIONS
             activity_group_enqueued             = 1
             activity_group_does_not_exist       = 2
             namespace_problem                   = 3
             not_authorized                      = 4
             wrong_language                      = 5
             OTHERS                              = 6
                              .
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.


          SORT gt_agr_tcodes BY type tcode.
          DELETE ADJACENT DUPLICATES FROM gt_agr_tcodes
          COMPARING type tcode.

      CALL FUNCTION 'PRGN_1221_SAVE_TRANSACTIONS' "#EC SAST_CI_GEN_CHECK
           EXPORTING
                activity_group = g_rolename
                display_status = space
           TABLES
                i_agr_tcodes   = gt_agr_tcodes.

*  Get Next Available Profile name

  CALL FUNCTION 'PRGN_PROFILE_NAME_GET' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            act_objid        = ' '
            prefix_letter    = 'C'
       IMPORTING
            act_profile_name = g_profile_name.

          agr_prof-agr_name  = g_rolename.
          agr_prof-langu     = sy-langu.
          agr_prof-profile   = g_profile_name.
          agr_prof-ptext     = 'Profile for role'(023).
          g_len = strlen( agr_prof-ptext ) + 1.
          WRITE agr_prof-agr_name TO agr_prof-ptext+g_len.
*          MODIFY agr_prof.

          gv_auth = g_profile_name(10).
          gv_authcount = '00'.

* Fetch Authorizations for corresponding tcodes from table USOBT_C


          LOOP AT gt_agr_tcodes INTO gs_agr_tcodes.
            g_name = gs_agr_tcodes-tcode.

            SELECT * FROM usobt_c INTO TABLE gt_usobtc_temp
            WHERE name = g_name
            AND type = 'TR'.
            IF sy-subrc = 0.
              APPEND LINES OF gt_usobtc_temp TO gt_usobt_c.
              REFRESH gt_usobtc_temp.
            ENDIF.

*****  Field values for S_TCODE
            gt_field_values-object = 'S_TCODE'.
            gt_field_values-field = 'TCD'.
            gt_field_values-neu    = 'O'.
            gt_field_values-modified   = 'S'.
            CONCATENATE gv_auth gv_authcount INTO gt_field_values-auth .
            gt_field_values-low = gs_agr_tcodes-tcode.
            APPEND gt_field_values.

          ENDLOOP.

          LOOP AT gt_usobt_c.
            MOVE-CORRESPONDING gt_usobt_c TO gt_usobt.
            APPEND gt_usobt.
          ENDLOOP.

          SORT gt_usobt BY name type object field low high .
          DELETE ADJACENT DUPLICATES FROM gt_usobt
          COMPARING name type object field low high.



** Create one auth entry for S_TCODE
*            lt_auth-node     = lt_auth-node + 1.
          gt_auth-object   = 'S_TCODE'.
          gt_auth-modified = 'S'.
          gt_auth-neu      = 'O'.
          CONCATENATE gv_auth gv_authcount INTO gt_auth-auth .
          PERFORM check_auth_desc USING gt_auth-object
                                  CHANGING gt_auth-atext.
          APPEND gt_auth.


*Inserting authorizations and field values for all other objects
          LOOP AT gt_usobt.
            AT NEW object.
*            CLEAR gv_authcount.
*            SHIFT gv_authcount RIGHT DELETING TRAILING space.
*            TRANSLATE gv_authcount USING ' 0'.
              PERFORM check_auth_desc USING gt_usobt-object
                                      CHANGING gt_auth-atext.

              CONCATENATE gv_auth gv_authcount INTO gt_auth-auth.
*            lt_auth-node     = lt_auth-node + 1.
              gt_auth-object   = gt_usobt-object.
              gt_auth-modified = 'S'.
              gt_auth-neu      = 'O'.
*            lt_auth-auth     = wa_rolefinal-auth.
              APPEND gt_auth.
            ENDAT.

            PERFORM check_org_values.

            gt_field_values-object = gt_usobt-object.
            gt_field_values-field  = gt_usobt-field.
            gt_field_values-auth   = gt_auth-auth.
            gt_field_values-low    = gt_usobt-low.
            gt_field_values-high   = gt_usobt-high.
            gt_field_values-neu    = 'O'.
            gt_field_values-modified   = 'S'.
            APPEND gt_field_values.

          ENDLOOP.

          CLEAR gt_auth.

          SORT gt_auth BY object auth.
          DELETE ADJACENT DUPLICATES FROM gt_auth COMPARING object auth.

*Save Auth Data*

         CALL FUNCTION 'PRGN_1250_SAVE_AUTH_DATA' "#EC SAST_CI_GEN_CHECK
              EXPORTING
                   activity_group = g_rolename
              TABLES
                   auth_data      = gt_auth
              EXCEPTIONS
                   OTHERS         = 1.
*BOC:HBHALLA (03/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (03/12/24)

          SORT gt_field_values.
          DELETE ADJACENT DUPLICATES FROM gt_field_values
          COMPARING ALL FIELDS.

*Save Field Values*

      CALL FUNCTION 'PRGN_1251_SAVE_FIELD_VALUES' "#EC SAST_CI_GEN_CHECK
           EXPORTING
                activity_group = g_rolename
           TABLES
                field_values   = gt_field_values.


*Fill Org. Level with Star

        CALL FUNCTION 'PRGN_1252_SAVE_ORG_LEVELS' "#EC SAST_CI_GEN_CHECK
             EXPORTING
                  activity_group = g_rolename
             TABLES
                  org_levels     = gt_org
*BOC:HBHALLA (03/12/24)
                       EXCEPTIONS
                            OTHERS         = 1.
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (03/12/24)


*Commit Work*

   CALL FUNCTION 'PRGN_UPDATE_DATABASE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
        EXCEPTIONS
             OTHERS = 1.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)

      CALL FUNCTION 'PRGN_CLEAR_BUFFER' "#EC SAST_CI_GEN_CHECK (HBHALLA)
           EXCEPTIONS
                OTHERS = 1.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)

*Generate a Profile*

    CALL FUNCTION 'SUPRN_PROFILE_BATCH' "#EC SAST_CI_GEN_CHECK (HBHALLA)
         EXPORTING
              act_objid             = g_rolename
              enqueue               = 'X'
         EXCEPTIONS
              objid_not_found       = 1
              no_authorization      = 2
              generation_not_active = 3
              empty_authorizations  = 4
              enqueue_failed        = 5
              not_generated         = 6
              OTHERS                = 7.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ELSE.
            MESSAGE i002(/psyng/sw) WITH text-018 g_rolename text-019.
            MESSAGE i113(/psyng/sw) WITH text-020 text-021.
          ENDIF.
        ENDIF.
      ENDAT.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " create_role
*&---------------------------------------------------------------------*
*&      Form  check_rd
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM check_rd.
*  DATA : l_dd02l TYPE dd02l.
*
*  SELECT SINGLE tabname
*    FROM dd02l
*    INTO CORRESPONDING FIELDS OF l_dd02l
*    WHERE tabname = '/PSYNG/DR_VRSIO'.
*  IF sy-subrc NE 0.
*    LOOP AT SCREEN.
**      IF screen-name = 'P_DER'.
**        screen-input = 0.
**        screen-invisible = 1.
**        MODIFY SCREEN.
**      ENDIF.
*      IF screen-name = 'S_ORG-LOW'
*      OR screen-name = 'S_ORG-HIGH'
*      OR screen-name = '%_S_ORG_%_APP_%-VALU_PUSH'
*      OR screen-name = '%_S_ORG_%_APP_%-TEXT'.
*        screen-input = 0.
*        screen-invisible = 1.
*        MODIFY SCREEN.
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
*
*ENDFORM.                    " check_rd
*&---------------------------------------------------------------------*
*&      Form  create_derived_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM create_derived_roles.
*  PERFORM create_all_role.
*ENDFORM.                    " create_derived_roles
*&---------------------------------------------------------------------*
*&      Form  create_all_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM create_all_role.
*  DATA : l_agr_define TYPE TABLE OF agr_define WITH HEADER LINE.
*
*  CONCATENATE g_rolename '_ALL' INTO g_all_rolename.
*  CONDENSE g_all_rolename.
*
*  CALL FUNCTION 'PRGN_COPY_ACTIVITY_GROUP'
*    EXPORTING
*      source_activity_group       = g_rolename
*      target_activity_group       = g_all_rolename
**   WITH_USER_ASSIGNMENT        = ' '
*   EXCEPTIONS
*     action_cancelled            = 1
*     not_authorized              = 2
*     target_already_exists       = 3
*     source_does_not_exist       = 4
*     internal_error              = 5
*     OTHERS                      = 6
*            .
*  IF sy-subrc <> 0.
*    CASE sy-subrc.
*      WHEN 1.
*        MESSAGE e002(/psyng/sw) WITH text-043.
*      WHEN 2.
*        MESSAGE e002(/psyng/sw) WITH text-039.
*      WHEN 3.
*        MESSAGE e002(/psyng/sw) WITH text-044.
*      WHEN 4.
*        MESSAGE e002(/psyng/sw) WITH text-045.
*      WHEN 5.
*        MESSAGE e002(/psyng/sw) WITH text-046.
*      WHEN 6.
*        MESSAGE e002(/psyng/sw) WITH text-040.
*    ENDCASE.
*  ELSE.
*    PERFORM generate_profile.
*    SELECT SINGLE * FROM agr_define INTO l_agr_define WHERE agr_name =
*    g_all_rolename.
*
*    l_agr_define-parent_agr = g_rolename.
**    APPEND l_agr_define.
*
*    MODIFY agr_define FROM l_agr_define.
*
*    RANGES : s_role FOR agr_define-agr_name.
*
*    s_role-sign = 'I'.
*    s_role-option = 'EQ'.
*    s_role-low = g_all_rolename.
*    APPEND s_role.
*
*
*
*    SUBMIT /psyng/deriver WITH roles IN s_role
*                          WITH areas IN s_org
*                          AND RETURN.
*  ENDIF.
*
*
*ENDFORM.                    " create_all_role
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA : l_jobname TYPE btcjob.
  CLEAR: gv_curr_report, gv_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  gv_curr_report = sy-repid.
  gv_curr_variant = gv_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = gv_curr_report
            curr_variant  = gv_variant
            vari_desc     = gt_vari_desc
       TABLES
            vari_contents = gt_rsparams
            vari_text     = gt_varit
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          illegal_report_or_variant = 1
          illegal_variantname = 2
          not_authorized = 3
          not_executed = 4
          report_not_existent = 5
          report_not_supplied = 6
          variant_exists = 7
          variant_locked = 8
          OTHERS = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = 'Role From Function ID'(069).
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = gv_curr_variant
              in_report   = gv_curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_back_job
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: lv_oldnumber(7) TYPE n,
        lv_oldnumber_c(7).

  CLEAR: gv_variant, gt_varit, gt_vari_desc.
  REFRESH: gt_varit, gt_vari_desc.

  SELECT variant INTO gv_variant FROM varid
                     WHERE report = sy-repid AND
                           variant LIKE '/PSYNG/%'
     ORDER BY variant DESCENDING.
    lv_oldnumber = gv_variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    gv_variant = '/PSYNG/0000000'.
  ELSE.
    lv_oldnumber = lv_oldnumber + 1.
    MOVE lv_oldnumber TO lv_oldnumber_c.
    CONCATENATE '/PSYNG/' lv_oldnumber_c INTO gv_variant.
  ENDIF.

  gt_varit-langu = sy-langu.
  gt_varit-report = sy-repid.
  gt_varit-variant = gv_variant.
  gt_varit-vtext = 'Dynamically created'(146).
  APPEND gt_varit.

  gt_vari_desc-report = sy-repid.
  gt_vari_desc-variant = gv_variant.
  APPEND gt_vari_desc.

ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH gt_rsparams.


  gt_rsparams-selname = 'ROLES'.
  gt_rsparams-kind = 'S'.
  gt_rsparams-low = g_all_rolename.
  APPEND gt_rsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  generate_profile
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM generate_profile.
  CALL FUNCTION 'SUPRN_PROFILE_BATCH'  "#EC SAST_CI_GEN_CHECK (HBHALLA)
     EXPORTING
       act_objid                   = g_all_rolename
     EXCEPTIONS
       objid_not_found             = 1
       no_authorization            = 2
       generation_not_active       = 3
       empty_authorizations        = 4
       enqueue_failed              = 5
       not_generated               = 6
       OTHERS                      = 7.

  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e002(/psyng/sw) WITH text-049.
      WHEN 2.
        MESSAGE e002(/psyng/sw) WITH text-039.
      WHEN 3.
        MESSAGE e002(/psyng/sw) WITH text-050.
      WHEN 4.
        MESSAGE e002(/psyng/sw) WITH text-051.
      WHEN 5.
        MESSAGE e002(/psyng/sw) WITH text-052.
      WHEN 6.
        MESSAGE e002(/psyng/sw) WITH text-053.
      WHEN 7.
        MESSAGE e002(/psyng/sw) WITH text-040.
    ENDCASE.
  ENDIF.

ENDFORM.                    " generate_profile
*&---------------------------------------------------------------------*
*&      Form  check_org_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_org_values.
  READ TABLE gt_usorg WITH KEY varbl = gt_usobt-low.
  IF sy-subrc = 0.
    gt_org-varbl = gt_usorg-varbl.
    gt_org-low = '*'.
    APPEND gt_org.
  ENDIF.

ENDFORM.                    " check_org_values
*&---------------------------------------------------------------------*
*&      Form  check_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_tcode USING invalid.
  SELECT SINGLE * FROM tstc WHERE tcode = gs_agr_tcodes-tcode.
  IF sy-subrc <> 0.
    invalid = 'X'.
  ELSE.
    CLEAR invalid.
  ENDIF.

ENDFORM.                    " check_tcode
*&---------------------------------------------------------------------*
*&      Form  check_auth_desc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_AUTH_OBJECT  text
*      <--P_LT_AUTH_ATEXT  text
*----------------------------------------------------------------------*
FORM check_auth_desc USING    p_lt_auth_object
                     CHANGING p_lt_auth_atext.

  SELECT SINGLE ttext INTO (p_lt_auth_atext)
  FROM tobjt
  WHERE object EQ p_lt_auth_object
  AND langu EQ sy-langu.

ENDFORM.                    " check_auth_desc
