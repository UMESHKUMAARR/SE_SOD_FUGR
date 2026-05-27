*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_031
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
REPORT /psyng/sw_031 LINE-SIZE 255 NO STANDARD PAGE HEADING.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_125.
TABLES: /psyng/criroles,  usr02, rfcdes, usr05.

TYPE-POOLS: slis.                                      "For ALV call

TYPES: BEGIN OF typ_usr02,
         class TYPE usr02-class,
         bname TYPE usr02-bname,
       END OF typ_usr02.

DATA : gt_critrole TYPE TABLE OF /psyng/criroles WITH HEADER LINE.
DATA : gt_agr_user TYPE TABLE OF agr_users WITH HEADER LINE.
RANGES : users FOR usr02-bname.
DATA : iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: icriroles TYPE SORTED TABLE OF /psyng/criroles
               WITH UNIQUE KEY agr_name WITH HEADER LINE,
      iagr_users TYPE STANDARD TABLE OF agr_users WITH HEADER LINE.
DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y'.

DATA: BEGIN OF output OCCURS 0,
        agr_name LIKE agr_users-agr_name,
        agr_text LIKE agr_texts-text,
        rfcdest LIKE rfcdes-rfcdest,
        imp LIKE /psyng/criprof-imp,
        owner LIKE /psyng/criprof-owner,
        bname LIKE usr02-bname,
        name LIKE /psyng/bc_userid_name-name_full,
        imporder,
      END OF output.
DATA: wa_output LIKE LINE OF output.

*Start of Reference User
DATA: iusrefus1 TYPE STANDARD TABLE OF usrefus WITH HEADER LINE.
*end of Reference user.
DATA: BEGIN OF gt_text OCCURS 0,
        text TYPE /psyng/texts-text,
      END OF gt_text.

TYPES: BEGIN OF t_critrole,
          agr_name TYPE agr_texts-agr_name,
          agr_text TYPE agr_texts-text,
          imp TYPE /psyng/criroles-imp,
          owner TYPE /psyng/criroles-owner,
*          description TYPE /psyng/criroles-description,
*         flag,       "flag for mark column
       END OF t_critrole.

TYPES: BEGIN OF ty_usrpar,
         parid TYPE usr05-parid,
         parva TYPE /psyng/parva_tt,
       END OF ty_usrpar.

DATA gs_critrole TYPE t_critrole.
DATA : gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       gt_usrroleprof TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
       gt_usrroleprof_part TYPE TABLE OF /psyng/usertcode WITH HEADER
LINE,
      gt_agr_txt TYPE STANDARD TABLE OF agr_texts WITH HEADER LINE.

*DATA: gt_username TYPE STANDARD TABLE OF /psyng/bc_userid_name
*          WITH HEADER LINE.

DATA : BEGIN OF gt_username OCCURS 0,
       rfcdest TYPE rfcdes-rfcdest.
        INCLUDE STRUCTURE /psyng/bc_userid_name.
DATA : END OF gt_username.

DATA : gt_username_part TYPE TABLE OF /psyng/bc_userid_name WITH HEADER
LINE.

DATA: l_gltgb TYPE sy-datum,
g_usercount TYPE i.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
DATA : g_local_sys TYPE rfcdes-rfcoptions,
       gt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE,
       gt_uinfo_temp TYPE TABLE OF /psyng/sw_uinfo_remote
                     WITH HEADER LINE,
       ls_ba_role    TYPE /psyng/bc_ba_00,
       g_current_user TYPE sy-uname, "C0700
       g_usrpar TYPE usr05-parid,
       gt_usrpar TYPE TABLE OF ty_usrpar,
       gs_usrpar TYPE ty_usrpar.


SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-000.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: userlist FOR usr02-bname.
SELECT-OPTIONS: s_class  FOR usr02-class.
SELECT-OPTIONS s_usrpar FOR usr05-parva MODIF ID usr.

*RFC destination for remote analysis
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(28) text-047.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: END OF LINE.



*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

PARAMETERS:remote AS CHECKBOX USER-COMMAND remo DEFAULT ' '.


SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: roles FOR /psyng/criroles-agr_name,
                rba FOR ls_ba_role-busarea,
                s_owner FOR /psyng/criroles-owner,
                s_imp FOR /psyng/criroles-imp.
PARAMETERS:     sodvrsio LIKE /psyng/conflict-vrsio.
SELECTION-SCREEN: END OF BLOCK exe.

INITIALIZATION.

  se_config_param 'USR_PARAM_FIELD_NAME' g_usrpar.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.
  PERFORM initialize.
  PERFORM set_def_usrtype.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR roles-low.
  PERFORM f4_ctrole CHANGING roles-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR roles-high.
  PERFORM f4_ctrole CHANGING roles-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_usrpar-low.
  PERFORM f4_usrpar USING 'S_USRPAR-LOW' CHANGING s_usrpar-low. "HBHALLA

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_usrpar-high.
  PERFORM f4_usrpar USING 'S_USRPAR-HIGH' CHANGING s_usrpar-high.

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

  LOOP AT SCREEN.
    IF g_usrpar IS INITIAL AND screen-name CS 'S_USRPAR'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF remote = 'X'.
    IF remrfc[] IS INITIAL.
      MESSAGE w140(/psyng/sw) WITH
      'Please enter RFC destinations for remote analysis'(180).
    ENDIF.
  ENDIF.


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
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  IF NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.



* add local system to list of rfc destinations
  IF remote NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO g_local_sys.
    gt_rfcdest-rfcoptions = g_local_sys.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.

  IF g_usrpar IS NOT INITIAL AND s_usrpar IS NOT INITIAL.
    gs_usrpar-parid = g_usrpar.
    gs_usrpar-parva = s_usrpar[].
    APPEND gs_usrpar TO gt_usrpar.
    CLEAR gs_usrpar.
  ENDIF.

*-- Get Users
  PERFORM get_users_in_question.

*-- Get all Critical profile from all system.
  IF NOT gt_uinfo[] IS INITIAL.
    gt_uinfo_temp[] = gt_uinfo[].
    SORT gt_uinfo_temp BY rfcdest bname.
    DELETE ADJACENT DUPLICATES FROM gt_uinfo_temp
      COMPARING rfcdest bname.

    DESCRIBE TABLE gt_uinfo_temp LINES g_usercount.

    PERFORM get_users_with_critical_roles.
    PERFORM get_data_by_user.
*--fill other data
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

  PERFORM output_via_alv.

*&---------------------------------------------------------------------*
*&      Form  get_users_in_question
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_users_in_question.
  DATA: yulock     TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  DATA: wa_usr02 TYPE usr02,
        l_gltgv  TYPE usr02-gltgv,
        l_gltgb  TYPE usr02-gltgb,
        l_ustyp  TYPE usr02-ustyp,
        l_uflag  TYPE usr02-uflag,
        i_include_locked TYPE flag,
        i_include_expire TYPE flag.


  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_USER_INFO_NEW'
       EXPORTING
            i_validuser   = validusr
            i_exlckusr    = exlckusr
            i_outvdate    = outvdate
            i_remote_only = remote
            it_usrpar     = gt_usrpar
       TABLES
            it_users      = userlist
            it_usergroup  = s_class
            it_usertype   = usrtype
            it_user_rfc   = remrfc
            et_uinfo      = lt_uinfo.

  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

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
ENDFORM.                    " get_users_in_question
*&---------------------------------------------------------------------*
*&      Form  get_users_profiles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_users_roles.
  IF  iusr02[] IS INITIAL.
    MESSAGE s146(/psyng/sw).
*   No Data Selected
    LEAVE LIST-PROCESSING.
  ELSE.
    DATA: username TYPE STANDARD TABLE OF /psyng/bc_userid_name
          WITH HEADER LINE,
          wa_usr02 TYPE usr02.


* REFERENCE USER begin of addition 1
    SELECT bname refuser FROM usrefus
      INTO CORRESPONDING FIELDS OF TABLE iusrefus1
      FOR ALL ENTRIES IN iusr02 WHERE bname = iusr02-bname AND
      refuser NE space.                          "#EC SAST_CI_GEN_CHECK

* add reference users to the list of users to get profiles for
    LOOP AT iusrefus1.
      wa_usr02-bname = iusrefus1-refuser.
      wa_usr02-class = 'REFUSER'.
      INSERT wa_usr02 INTO TABLE iusr02.
    ENDLOOP.
* REFERENCE USER end of addition 1


    LOOP AT iusr02.
      username-bname = iusr02-bname.
      APPEND username.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
         EXPORTING
              no_email = 'X'
         TABLES
              username = username.

    LOOP AT gt_agr_user.
      READ TABLE iusr02 WITH KEY bname = gt_agr_user-uname.
      IF sy-subrc NE 0.
        CONTINUE.
      ENDIF.
      READ TABLE gt_critrole WITH KEY agr_name = gt_agr_user-agr_name
                            TRANSPORTING imp owner.
      CHECK sy-subrc = 0.  "check role is a critical role?
      output-agr_name = gt_agr_user-agr_name.
      output-bname = gt_agr_user-uname.
      output-imp = gt_critrole-imp.
      output-owner = gt_critrole-owner.
      CASE output-imp.
        WHEN 'HIGH'.
          output-imporder = 1.
        WHEN 'MEDIUM'.
          output-imporder = 2.
        WHEN 'LOW'.
          output-imporder = 3.
        WHEN OTHERS.
      ENDCASE.
    READ TABLE username WITH KEY bname = gt_agr_user-uname BINARY SEARCH
                                                                       .
      IF sy-subrc = 0.
        output-name = username-name_full.
      ENDIF.
      APPEND output.
    ENDLOOP.

* REFERENCE USER begin of addition 2
    LOOP AT iusrefus1.
      LOOP AT output INTO wa_output WHERE bname = iusrefus1-refuser.
        wa_output-bname = iusrefus1-bname.
        READ TABLE username WITH KEY bname = wa_output-bname
             BINARY SEARCH.
        IF sy-subrc = 0.
          wa_output-name = username-name_full.
        ENDIF.
        INSERT wa_output INTO TABLE output.
      ENDLOOP.
    ENDLOOP.

* remove reference users from the list of users
    LOOP AT iusr02 WHERE class = 'REFUSER'.
      DELETE output WHERE bname = iusr02-bname.
    ENDLOOP.
* REFERENCE USER end of addition 2

    SORT output BY imporder agr_name bname.
    DELETE ADJACENT DUPLICATES FROM output.
  ENDIF.
ENDFORM.                    " get_users_roles
*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_sw_repo_conifg.
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
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.


  PERFORM build_alv_catalog.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'Users with Critical Roles'(004) TO alv_grid_titl.

  PERFORM build_sort_table.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER'
            i_grid_title             = alv_grid_titl
            i_callback_program       = program
            it_sort                  = isort
            is_layout                = alv_layout
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_DOUBLE_CLICK'
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
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


  SET PF-STATUS 'SW_031' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat LIKE LINE OF i_fieldcat_alv.

  program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'OUTPUT'
            i_inclname         = program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.


  CLEAR wa_fieldcat.
  wa_fieldcat-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'AGR_NAME'.


* Hide column IMPSORT
  CLEAR wa_fieldcat.
  wa_fieldcat-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'IMPORDER'.

  wa_fieldcat-seltext_l = 'Sensitivity'(011).
  wa_fieldcat-seltext_m = 'Sensitivity'(011).
  wa_fieldcat-seltext_s = 'Sens'(012).
  wa_fieldcat-reptext_ddic = 'Sensitivity'(011).
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat-seltext_l = 'User ID'(013).
  wa_fieldcat-seltext_m = 'User ID'(013).
  wa_fieldcat-seltext_s = 'User ID'(013).
  wa_fieldcat-reptext_ddic = 'User ID'(013).
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat-seltext_l = 'User Full Name'(014).
  wa_fieldcat-seltext_m = 'User Name'(015).
  wa_fieldcat-seltext_s = 'Name'(016).
  wa_fieldcat-reptext_ddic = 'User Name'(015).
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'NAME'.

  wa_fieldcat-seltext_l = 'Role Text'(017).
  wa_fieldcat-seltext_m = 'Role Text'(017).
  wa_fieldcat-seltext_s = 'Role Text'(017).
  wa_fieldcat-reptext_ddic = 'Role Text'(017).
  MODIFY i_fieldcat_alv FROM wa_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AGR_TEXT'.

  wa_fieldcat-seltext_l = 'System/Client'(018).
  wa_fieldcat-seltext_m = 'System/Client'(018).
  wa_fieldcat-seltext_s = 'System/Client'(018).
  wa_fieldcat-reptext_ddic = 'System/Client'(018).
  MODIFY i_fieldcat_alv FROM wa_fieldcat
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
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'NAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " build_sort_table
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

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        count TYPE i,
        c_usercount(6) TYPE c,
        exetime(8) TYPE c,
        exedate TYPE char10,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  wa-typ = 'H'.
  wa-info = 'Users with Critical Roles'(h01).
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
  WRITE sy-datum TO exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
                INTO exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname     C0700
   text-h04 exedate exetime
    INTO wa-info SEPARATED BY space.
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
*&      Form  get_users_with_critical_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_with_critical_roles.
  DATA : lt_roles   TYPE TABLE OF /psyng/bc_agr_name  WITH HEADER LINE,
         lt_role_ba TYPE TABLE OF /psyng/busarea_role WITH HEADER LINE.
**** Creating list of user those who have critical roles assigned
  SELECT * FROM /psyng/criroles
             INTO TABLE gt_critrole
             WHERE agr_name IN roles
             AND imp IN s_imp
             AND owner IN s_owner
             AND   vrsio = sodvrsio
             ORDER BY agr_name.

  IF NOT rba[] IS INITIAL AND NOT gt_critrole[] IS INITIAL.
    LOOP AT gt_critrole.
      lt_roles-agr_name = gt_critrole-agr_name.
      APPEND lt_roles.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/BC_073'
     TABLES
       it_roles              = lt_roles
       et_busarea_role       = lt_role_ba.
    SORT lt_role_ba BY agr_name.
    LOOP AT gt_critrole.
      READ TABLE lt_role_ba WITH KEY agr_name = gt_critrole-agr_name.
      IF sy-subrc = 0.
        IF lt_role_ba-busarea NOT IN rba.
          DELETE gt_critrole.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF NOT gt_critrole[] IS INITIAL.

    SELECT * FROM agr_texts INTO TABLE gt_agr_txt
              FOR ALL ENTRIES IN gt_critrole
                WHERE agr_name = gt_critrole-agr_name
                AND spras EQ sy-langu
                AND line EQ space.

  ENDIF.


ENDFORM.                    " get_users_with_critical_roles
*&---------------------------------------------------------------------*
*&      Form  f4_ctrole
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_ROLES_LOW  text
*----------------------------------------------------------------------*
FORM f4_ctrole CHANGING e_role TYPE /psyng/criroles-agr_name.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value WITH HEADER LINE,
          lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
          ls_ctrole TYPE /psyng/criroles,
          ls_agrtext TYPE agr_texts,
          lt_crole TYPE TABLE OF /psyng/criroles WITH HEADER LINE.

  DATA : BEGIN OF crole OCCURS 0,
  text TYPE agr_texts-text.
          INCLUDE STRUCTURE /psyng/criroles.
  DATA END OF crole.


*  SELECT a~agr_name
*         a~vrsio
**         a~description
*         a~imp
*         a~owner
*         b~text INTO CORRESPONDING FIELDS OF TABLE crole
*         FROM /psyng/criroles AS a INNER JOIN agr_texts AS b
*         ON a~agr_name EQ b~agr_name
*         WHERE vrsio = sodvrsio
*           AND spras EQ sy-langu
*           AND line EQ space.

SELECT * FROM /psyng/criroles INTO TABLE lt_crole WHERE vrsio = sodvrsio
                                                        .

  LOOP AT lt_crole.
    MOVE-CORRESPONDING lt_crole TO crole.
    SELECT SINGLE text FROM agr_texts INTO (crole-text)
    WHERE agr_name = lt_crole-agr_name
    AND spras = sy-langu
    AND line EQ 0.
    IF sy-subrc NE 0.
      crole-text = 'Role for Cross system analysis'(061).
    ENDIF.
    APPEND crole.
  ENDLOOP.


  REFRESH: lt_fields, lt_values.
  lt_fields-tabname   = '/PSYNG/CRIROLES'.
  lt_fields-fieldname = 'AGR_NAME'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.
  lt_fields-tabname   = 'AGR_TEXTS'.
  lt_fields-fieldname = 'TEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRIROLES'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'DESCRIPTION'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  LOOP AT crole.
    lt_values-line = crole-agr_name.
    APPEND lt_values.
    lt_values-line = crole-text.
    APPEND lt_values.
    lt_values-line = crole-vrsio.
    APPEND lt_values.
    lt_values-line = crole-imp.
    APPEND lt_values.
    lt_values-line = crole-owner.
    APPEND lt_values.
*    lt_values-line = crole-description.
*    APPEND lt_values.

  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
           titel                     = 'Critical Roles search help'(t13)
       IMPORTING
            select_value              = e_role
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

  DATA : i_agr LIKE /psyng/criroles-agr_name.
  DATA:l_desc TYPE /psyng/texts-text.
  DATA: BEGIN OF s_text OCCURS 0 ,
        text LIKE agr_texts-text,
        END OF s_text.
  CASE rs_selfield-fieldname.
    WHEN 'AGR_NAME'.

      CHECK rs_selfield-value <> space.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      i_agr = rs_selfield-value.
      REFRESH: gt_text.
      CLEAR gs_critrole.

      SELECT SINGLE * FROM /psyng/criroles
      INTO CORRESPONDING FIELDS OF gs_critrole
      WHERE agr_name = i_agr AND vrsio = sodvrsio.

      IF sy-subrc = 0.
        SELECT line text FROM /psyng/texts
                INTO CORRESPONDING FIELDS OF TABLE s_text
                WHERE textname = i_agr
                AND   object   = 'Q'
                AND   vrsio    = sodvrsio
                AND   spras    = sy-langu
                ORDER BY line.
        IF sy-subrc = 0.
          gt_text[] = s_text[].
        ENDIF.
      ENDIF.


      SELECT SINGLE text FROM agr_texts
      INTO  gs_critrole-agr_text
      WHERE agr_name = i_agr.

* gt_critprof-text = s_text.

*  g_vrsio = sodvrsio.
      CALL SCREEN 1200 STARTING AT 20 3.
  ENDCASE.

ENDFORM.
" f4_conid
*&---------------------------------------------------------------------*
*&      Module  init_1200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_1200 OUTPUT.
  SET PF-STATUS '1200'.
  PERFORM init_editor_1200.
ENDMODULE.                 " init_1200  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  init_editor_1200
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_editor_1200.
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
              container_name              = 'CC_ROLE'
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
            OTHERS = 1.

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

ENDFORM.                    " init_editor_1200
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1200 INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " USER_COMMAND_1200  INPUT

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
         i_role                 =  'X'
*         i_profile             =
        TABLES
          it_users              = iusr02
          it_roles              = gt_critrole
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
        i_role                = 'X'
*        i_profile             =
       TABLES
         it_users              = iusr02
         it_roles              = gt_critrole
  et_userroleprof       = gt_usrroleprof_part
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
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

  LOOP AT gt_rfcdest.
    LOOP AT gt_usrroleprof WHERE rfcdest = gt_rfcdest-rfcoptions.

      output-agr_name = gt_usrroleprof-agr_name.

* fill role text
      READ TABLE gt_agr_txt WITH KEY agr_name = gt_usrroleprof-agr_name
                                     spras = sy-langu.
      IF sy-subrc EQ 0.
        output-agr_text = gt_agr_txt-text.
      ELSE.
        output-agr_text = 'Role for Cross System Analysis'(061).
      ENDIF.
      CLEAR gt_agr_txt-text.
      output-rfcdest = gt_usrroleprof-rfcdest.

* fill sensitivity & owner
     READ TABLE gt_critrole WITH KEY agr_name = gt_usrroleprof-agr_name.

      IF sy-subrc EQ 0.
        output-imp = gt_critrole-imp.
        output-owner = gt_critrole-owner.
      ENDIF.
      output-bname = gt_usrroleprof-bname.

* fill username.
*BOC AKUMAR 06-02-2025 PN11640
      SORT gt_uinfo BY bname rfcdest.
*BOC AKUMAR 06-02-2025 PN11640

      READ TABLE gt_uinfo WITH KEY
                        bname = gt_usrroleprof-bname
                        rfcdest = gt_usrroleprof-rfcdest
                        BINARY SEARCH.
      IF sy-subrc EQ 0.
        output-name = gt_uinfo-name_text.
      ENDIF.
      APPEND output.
      CLEAR output.

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
  DATA : l_value TYPE /psyng/param_value.

*--Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' l_value.
  IF l_value = 'Y'.
    validusr = 'X'.
  ELSEIF l_value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR l_value.
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
    AND b~ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

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
      AND b~ddlanguage = 'EN'.                   "#EC SAST_CI_GEN_CHECK
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
             program_error          = 1
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
           WHERE rfcdest IN it_role_rfc.         "#EC SAST_CI_GEN_CHECK
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
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
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
         lv_local TYPE flag VALUE 'X'.

  IF remote = 'X'.
    CLEAR lv_local.
  ENDIF.
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

  REFRESH gt_usrpar.
  IF g_usrpar IS NOT INITIAL AND s_usrpar IS NOT INITIAL.
    gs_usrpar-parid = g_usrpar.
    gs_usrpar-parva = s_usrpar[].
    APPEND gs_usrpar TO gt_usrpar.
    CLEAR gs_usrpar.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
   EXPORTING
     i_validuser             = validusr
     i_include_locked        = lv_exlckusr
     i_include_expired       = lv_outvdate
     if_local_system         = lv_local
     if_show_message         = 'X'
     it_parameters           = gt_usrpar
   IMPORTING
     e_usercount             = l_numb
   TABLES
     it_userlist             = userlist
     it_grouplist            = s_class
     it_usertype             = usrtype
*   IT_ACTGROUPS            = s_role
*   IT_PROFILE              = s_prof
     it_rfcrange             = remrfc
*   IT_RFCLIST              =
*   IT_DEPARTMENT           = s_depart
*   IT_COMPANY              = s_comp
*   IT_CUID                 = s_cuid
      .

ENDFORM.                    " get_users_count
*&---------------------------------------------------------------------*
*&      Form  F4_USRPAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_usrpar USING fieldname    "HBHALLA
               CHANGING s_usrpar. "HBHALLA
  TYPES: BEGIN OF ty_parva,
      parva TYPE xuvalue,
      END OF ty_parva.

  DATA: lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_data TYPE TABLE OF ty_parva,
        l_repid      LIKE sy-repid,
        l_dynnr      LIKE sy-dynnr,
        dynpfields LIKE dynpread OCCURS 0 WITH HEADER LINE.

* Read value of selection screen field dynamically
  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION 'DYNP_VALUES_READ'
       EXPORTING
            dyname     = l_repid
            dynumb     = l_dynnr
            request    = 'A'
       TABLES
            dynpfields = dynpfields
       EXCEPTIONS
            OTHERS     = 9.
  IF sy-subrc = 0.
    READ TABLE dynpfields WITH KEY fieldname.
  ENDIF.

  RANGES : lr_parva FOR usr05-parva.

  IF NOT dynpfields-fieldvalue IS INITIAL.
    lr_parva-sign = 'I'.
    IF dynpfields-fieldvalue CS '*'.
      lr_parva-option = 'CP'.
    ELSE.
      lr_parva-option = 'EQ'.
    ENDIF.
    TRANSLATE dynpfields-fieldvalue TO UPPER CASE.
    lr_parva-low = dynpfields-fieldvalue.
    APPEND lr_parva.
  ENDIF.

  SELECT parva
  FROM usr05
  INTO TABLE lt_data
  WHERE parid = g_usrpar
    AND parva IN lr_parva.

  SORT lt_data BY parva.
  DELETE ADJACENT DUPLICATES FROM lt_data COMPARING parva.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
  EXPORTING
    retfield        = 'PARVA'
    value_org       = 'S'
    window_title    = 'Title'
  TABLES
    value_tab       = lt_data
    return_tab      = lt_return
  EXCEPTIONS
    parameter_error = 1
    no_values_found = 2
    OTHERS          = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc = 0.
    s_usrpar = ls_return-fieldval.
  ENDIF.
ENDFORM.
