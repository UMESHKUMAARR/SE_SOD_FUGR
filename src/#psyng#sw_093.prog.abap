*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_093
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  20/02/2020   Gurpinder   C0025       P33K940507                     *
*----------------------------------------------------------------------*

REPORT /psyng/sw_093 NO STANDARD PAGE HEADING
LINE-SIZE 255."#EC SAST_CI_GEN_CHECK
*********************************************************
***************** tables ********************************
*********************************************************
TABLES: usr02, /psyng/swsodvers, e070.
TYPE-POOLS :ustyp.
*--Type for F4 help
TYPES: BEGIN OF ty_values,
         line(255) TYPE c,
       END OF   ty_values.
********************************************************
**************** DATA DECLEARATION *********************
********************************************************
DATA: BEGIN OF gt_usr_tab OCCURS 0,
        bname TYPE usr02-bname,
      END OF gt_usr_tab.

DATA: BEGIN OF g_role_tab OCCURS 0,
        agr_name TYPE agr_define-agr_name,
      END OF g_role_tab.

DATA: BEGIN OF gt_usr_rol OCCURS 0,
        agr_name TYPE agr_users-agr_name,
        uname TYPE agr_users-uname,
      END OF gt_usr_rol.

DATA: BEGIN OF g_profile OCCURS 0,
        profn TYPE usr10-profn,
      END OF g_profile.

DATA: BEGIN OF gt_usr_pro OCCURS 0,
        bname TYPE ust04-bname,
        profile TYPE ust04-profile,
      END OF gt_usr_pro.

DATA: BEGIN OF gt_auth OCCURS 0,
        auth TYPE usr12-auth,
      END OF gt_auth.

DATA: BEGIN OF gt_auth_usr OCCURS 0,
        profile TYPE ust04-profile,
      END OF gt_auth_usr.
DATA: gt_auth_usr_dum LIKE STANDARD TABLE OF  gt_auth_usr WITH HEADER
      LINE.

DATA: gt_auth_pro TYPE ustyp_t_profiles WITH HEADER LINE,
      gt_auth_pro_fi TYPE ustyp_t_profiles WITH HEADER LINE.

DATA: BEGIN OF gt_comp_role OCCURS 0,
        agr_name TYPE agr_agrs-agr_name,
      END OF gt_comp_role.
DATA: BEGIN OF gt_corol_usr OCCURS 0,
        agr_name TYPE agr_users-agr_name,
        uname TYPE agr_users-uname,
      END OF gt_corol_usr.


DATA: g_usr_cnt TYPE i,
      g_vlid_usr_cnt TYPE i ,
      g_role_cnt TYPE i,
      g_usr_role TYPE i,
      g_usr_no_role TYPE i,
      g_role_usr TYPE i,
      g_role_no_usr TYPE i,
      g_prof_cnt TYPE i,
      g_pro_usr TYPE i,
      g_pro_no_usr TYPE i,
      g_usr_pro TYPE i,
      g_usr_no_pro TYPE i,
      g_auth TYPE i,
      g_auth_no_usr TYPE i,
      g_auth_usr TYPE i,
      g_comp_rol TYPE i,
      g_comp_rol1 TYPE i,
      g_corol_usr TYPE i,
      g_corol_no_usr TYPE i,
      g_sinrol TYPE i,
      g_sinrol_usr TYPE i,
      g_sinrol_n_usr TYPE i,
      g_prnt_role TYPE i,
      g_prnt_usr TYPE i,
      g_prnt_n_usr TYPE i,
      g_drv_rol TYPE i,
      g_drvrol_usr TYPE i,
      g_drvrol_n_usr TYPE i,
      g_avg_drv TYPE p DECIMALS 2 ,
      g_comp TYPE i,
      g_sing_rol TYPE i,
      g_sing_rol1 TYPE i,
      g_avg_srol TYPE p DECIMALS 2,
      g_tot_rol TYPE i,
      g_tot_usr TYPE i,
      g_avg_rol_usr TYPE p DECIMALS 2,
      g_avg_pro_usr TYPE p DECIMALS 2,
      g_avg_pro_rol TYPE p DECIMALS 2,
      g_avg_tcd_rol TYPE p DECIMALS 2,
      g_avg_auth_rol TYPE p DECIMALS 2,
      g_au_usr TYPE i,
      g_avg_auth_usr TYPE p DECIMALS 2.

DATA: g_curr_report LIKE  rsvar-report,
g_curr_variant LIKE  rsvar-variant,
gt_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE.
DATA: g_variant LIKE vari-variant.
DATA: gt_irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: gt_ivarit TYPE varit OCCURS 0 WITH HEADER LINE.
DATA: exit_proc.
DATA: g_program         LIKE sy-repid.
*SE4.3
DATA: gt_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
      g_system_msg(72) TYPE c.

DEFINE get_system.
  refresh gt_rfcdes.
  clear gt_rfcdes.
  select * from /psyng/sw_rfcdes into table gt_rfcdes
  where systid = &1.
  if sy-subrc eq 0.
    read table gt_rfcdes index 1.
  endif.
END-OF-DEFINITION.
*end

**********************************************************
*************   SELECTION SCREEN *************************
**********************************************************
SELECTION-SCREEN : BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
PARAMETERS: p_system TYPE /psyng/swcfgsys-sysid.
PARAMETERS: p_vrsin LIKE /psyng/swsodvers-vrsio.
SELECTION-SCREEN: SKIP 1.

PARAMETERS: p_ginfo AS CHECKBOX DEFAULT 'X',
            p_cpu AS CHECKBOX DEFAULT 'X',
            p_mat AS CHECKBOX DEFAULT 'X',
            p_dia AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS  p_tab AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(40) text-s01 FOR FIELD p_tab.
SELECTION-SCREEN: END OF LINE.
PARAMETERS: p_tabse AS CHECKBOX DEFAULT 'X',
            p_tp  AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_sod AS CHECKBOX DEFAULT 'X'.
*  max users to select for SOD scan
SELECTION-SCREEN COMMENT 3(30) text-098.
PARAMETERS: p_maxus TYPE i DEFAULT '500'.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN : END OF BLOCK b1.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-067.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-068.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-069.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-070 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-071 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.

INITIALIZATION.
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = p_vrsin.


******************************************************
**         selection screen Validation               *
******************************************************
AT SELECTION-SCREEN.
  SELECT SINGLE *
  FROM /psyng/swsodvers
  WHERE vrsio = p_vrsin.
  IF sy-subrc <> 0.
    MESSAGE e156(/psyng/sw).
  ENDIF.
  CLEAR exit_proc .
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

* Selection screen fields can only handle 5000 entries
* See SOD Scan FM call
  IF p_sod = 'X'.
    IF p_maxus > 4500.
      p_maxus = '4500'.
      SET CURSOR FIELD 'P_MAXUS'.
      MESSAGE e208(00) WITH text-099.
    ELSEIF p_maxus < 20.
      p_maxus = '20'.
      SET CURSOR FIELD 'P_MAXUS'.
      MESSAGE e208(00) WITH text-101.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vrsin.
  PERFORM f4_vrsio CHANGING p_vrsin.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name .
      WHEN 'P_MAXUS'.
        IF p_sod IS INITIAL.
          screen-input = 0 .
        ELSE.
          screen-input = 1.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN .
  ENDLOOP.

******************************************************************
****************** START OF SELECTION ****************************
******************************************************************
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
  g_program = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.

*--get system's rfc
  get_system p_system.

  IF p_ginfo = 'X'.
    PERFORM gen_info.
  ENDIF.
  IF p_cpu = 'X'.
    PERFORM cpu_cal.
  ENDIF.
  IF p_mat = 'X'.
    PERFORM matrix_cal.
  ENDIF.
  IF p_dia = 'X'.
    PERFORM security_environment.
  ENDIF.
  IF p_tab = 'X'.
    PERFORM table_cal.
  ENDIF.
  IF p_tabse = 'X'.
    PERFORM table_se_cal.
  ENDIF.
  IF p_tp = 'X'.
    PERFORM display_sw_tps.
  ENDIF.
  IF p_sod = 'X'.
    PERFORM sod_mat.
  ENDIF.

*****************************************
**RKANAKA Added on 09/02/2011
  IF p_ginfo = '' AND p_cpu = '' AND p_mat = ''
   AND p_dia = ''  AND p_tab = ''   AND p_tp = ''
   AND p_sod = '' AND p_tabse = ''.
    MESSAGE s116(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
**RKANAKA Added on 09/02/2011
*****************************************
  SKIP 5.
  WRITE:/ text-107, / text-107, / text-106.
  MESSAGE s113(/psyng/sw) WITH text-107.
  MESSAGE s113(/psyng/sw) WITH text-107.
  MESSAGE s113(/psyng/sw) WITH text-106.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Form  MATRIX_CAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM matrix_cal.


  DATA: ls_mat_cal TYPE /psyng/sw_cal_sodmatrix,
         l_text1 TYPE string,
         l_text2 TYPE string.

  DEFINE print_mat_cal.
    skip.
    split ls_mat_cal-&1 at ':' into l_text1 l_text2.
    write:/3 l_text1 color 2,81 l_text2 color 7.
    skip.
  END-OF-DEFINITION.

*---get matrix info from remote
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
  DESTINATION gt_rfcdes-rfcdest
       EXPORTING
            i_sodvrsio      = p_vrsin
            i_matrix_object = 'X'
       IMPORTING
            e_matrix_cal    = ls_mat_cal
       EXCEPTIONS
            communication_failure = 1 MESSAGE g_system_msg
            system_failure        = 2 MESSAGE g_system_msg
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


*---Output section
  IF sy-subrc = 0.
    SKIP 2.
    WRITE:/60 text-111 COLOR 1.
    SKIP 2.
    IF gt_rfcdes-rfcdest IS INITIAL.
      WRITE:/3 'System'(118),10 ':',12 'Local'(119).
    ELSE.
      WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
    ENDIF.
    SKIP 2.
    SPLIT ls_mat_cal-sodversion AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 COLOR 2,81 l_text2 COLOR 7.
    SKIP 2.
    SPLIT ls_mat_cal-totalconflicts AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 COLOR 2,81 l_text2 COLOR 7.

    print_mat_cal: activeconflicts,
                   avgfunconflict,
                   functions,
                   avgtxnfunction,
                   unique_txn,
                   funtxn_combi,
                   avgobjtxnfaobj2,
                   avgobjfaobj2,
                   unique_auth,
                   funtxnobj_combi,
                   sysauth_matrix,
                   s_profiles,
                   roles.
  ENDIF.
ENDFORM.                    " MATRIX_CAL
*&---------------------------------------------------------------------*
*&      Form  Security_Environment
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM security_environment.

  DATA: ls_sec_info TYPE /psyng/sw_security_info,
        l_text1 TYPE string,
        l_text2 TYPE string.
*--- output section
  DEFINE print_mat_cal.
    skip.
    split ls_sec_info-&1 at ':' into l_text1 l_text2.
    write:/3 l_text1 color 2, 80 l_text2 color 7.
    skip.
  END-OF-DEFINITION.

  DEFINE print_mat_cal_74.
    skip.
    split ls_sec_info-&1 at ':' into l_text1 l_text2.
    write:/3 l_text1 color 2, 80 l_text2 color 7.
    skip.
  END-OF-DEFINITION.

*-----get security info from remote
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
    DESTINATION gt_rfcdes-rfcdest
   EXPORTING
     i_security_enviroment       = 'X'
   IMPORTING
     e_sec_info                  = ls_sec_info
   EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*---output section
  IF sy-subrc = 0.
    SKIP 2.
    WRITE:/60 text-066 COLOR 1.
    SKIP 2.
    IF gt_rfcdes-rfcdest IS INITIAL.
      WRITE:/3 'System'(118),10 ':',12 'Local'(119).
    ELSE.
      WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
    ENDIF.
    SKIP 2.

    SPLIT ls_sec_info-usr_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 COLOR 2,80 l_text2 COLOR 7.

    print_mat_cal: vusr_count, role_count, usr_role,
                usr_no_role, role_usr, role_no_usr,
                prof_count, prof_usr, prof_no_usr,
                usr_prof, usr_no_prof,auth_count,
                auth_usr, auth_no_usr, comp_role,
                comprole_usr, comprole_no_usr, sinrole,
                sinrole_usr, sinrol_n_usr, prnt_role,
                prnt_usr, prnt_n_usr, drv_role, drvrol_usr,
                drvrol_n_usr.

    print_mat_cal_74: avg_drv,avg_srole,
                    avg_role_usr, avg_prof_usr,
                    avg_auth_usr, avg_prof_role,
                    avg_tcd_role, avg_auth_role.
  ENDIF.

ENDFORM.                    " Security_Environment
*&---------------------------------------------------------------------*
*&      Form  TABLE_CAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM table_cal.

  DATA:
        l_agr_count TYPE /psyng/longtextfield,
        l_usr_count TYPE /psyng/longtextfield,
        lf_not_auth TYPE flag,
        lf_oracle   TYPE flag,
        lt_agr_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
        lt_usr_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
        l_text1 TYPE string,
        l_text2 TYPE string,
        ls_summary type /psyng/sw_table_text.

*--- get table size info from remote
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
    DESTINATION gt_rfcdes-rfcdest
   EXPORTING
     i_tables_size               = 'X'
   IMPORTING
     e_agr_count                 = l_agr_count
     e_usr_count                 = l_usr_count
     ef_not_auth                 = lf_not_auth
     ef_oracle                   = lf_oracle
   TABLES
     et_agr_tab                  = lt_agr_tab
     et_usr_tab                  = lt_usr_tab
  EXCEPTIONS
     communication_failure       = 1 MESSAGE g_system_msg
     system_failure              = 2 MESSAGE g_system_msg
     OTHERS                      = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*----output section agr table
  IF sy-subrc = 0.
    SKIP 2.
    WRITE:/60 text-112 COLOR 1.
    SKIP 2.
    IF gt_rfcdes-rfcdest IS INITIAL.
      WRITE:/3 'System'(118),10 ':',12 'Local'(119).
    ELSE.
      WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
    ENDIF.
    SKIP.
    IF NOT lf_not_auth IS INITIAL.
      WRITE:/3
'Tables Size Details are not fetched due to missing authorization'(116).
    ENDIF.
    IF lf_oracle IS INITIAL.
      WRITE:/3
      'Table Size Details only available for Oracle Database'(117).
    ENDIF.
    SKIP.
    SPLIT l_agr_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.
    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
        clear ls_summary.

    LOOP AT lt_agr_tab.
      WRITE:/3 lt_agr_tab-tabname , 25 lt_agr_tab-ddtext,
      85 lt_agr_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_agr_tab-s_type,
      114 lt_agr_tab-kbytes LEFT-JUSTIFIED,
      129 lt_agr_tab-blocks LEFT-JUSTIFIED,
      140 lt_agr_tab-extents LEFT-JUSTIFIED.
      add lt_agr_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_agr_tab-kbytes  to ls_summary-kbytes.
      add lt_agr_tab-blocks  to ls_summary-blocks.
      add lt_agr_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).

*--- us* tables
    SKIP 2.
    SPLIT l_usr_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.
    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
        clear ls_summary.

    LOOP AT lt_usr_tab.
      WRITE:/3 lt_usr_tab-tabname , 25 lt_usr_tab-ddtext,
      85 lt_usr_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_usr_tab-s_type,
      114 lt_usr_tab-kbytes LEFT-JUSTIFIED,
      129 lt_usr_tab-blocks LEFT-JUSTIFIED,
      140 lt_usr_tab-extents LEFT-JUSTIFIED.
      add lt_usr_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_usr_tab-kbytes  to ls_summary-kbytes.
      add lt_usr_tab-blocks  to ls_summary-blocks.
      add lt_usr_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).

  ENDIF.
ENDFORM.                    " TABLE_CAL
*&---------------------------------------------------------------------*
*&      Form  GEN_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM gen_info.
  DATA:server LIKE msxxlist-name,
       l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
    DESTINATION gt_rfcdes-rfcdest
       EXPORTING
            i_general_info        = 'X'
       IMPORTING
            e_server              = server
       EXCEPTIONS
            communication_failure = 1  MESSAGE  g_system_msg
            system_failure        = 2  MESSAGE  g_system_msg
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  SKIP 2.
  WRITE:/60 text-053 COLOR 1.
  SKIP 2.
  IF gt_rfcdes-rfcname IS INITIAL.
    WRITE:/3 'System'(118),22 ':',24 'Local'(119).
  ELSE.
    WRITE:/3 text-118,22 ':',24 gt_rfcdes-rfcname.
  ENDIF.
  SKIP.
  WRITE:/3 text-050,22 ':',24 server.
  SKIP.
  WRITE:/3 text-051,22 ':',24 l_current_user."sy-uname. C0700
  SKIP.
  WRITE:/3 text-052,22 ':',24 sy-datum.

ENDFORM.                    " GEN_INFO
*&---------------------------------------------------------------------*
*&      Form  cpu_cal
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM cpu_cal.
  DATA: l_text1 TYPE string,
        l_text2 TYPE string.
  DATA: is_cpu_cal TYPE  /psyng/sw_cpu_calcu_info.

*--get cpu cal from remote system
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
  DESTINATION gt_rfcdes-rfcdest
   EXPORTING
     i_sodvrsio                  = p_vrsin
     i_cpu_performance           = 'X'
   IMPORTING
     e_cpu_calculation           = is_cpu_cal
    EXCEPTIONS
            communication_failure = 1 MESSAGE g_system_msg
            system_failure        = 2 MESSAGE g_system_msg
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  SKIP 2.
  WRITE:/60 text-072 COLOR 1.
  SKIP 2.
  IF gt_rfcdes-rfcdest IS INITIAL.
    WRITE:/3 'System'(118),10 ':',12 'Local'(119).
  ELSE.
    WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
  ENDIF.
  SKIP.
  WRITE:/3 text-073 COLOR 2.
  SKIP.
  l_text2 = is_cpu_cal-total_run_text.
  l_text1 = is_cpu_cal-total_run_time.
  WRITE:/3 text-074,20 l_text1 COLOR 6.
  SKIP .
  WRITE:/10 l_text1,96 l_text2 COLOR 7.
  SKIP .

  l_text1 = is_cpu_cal-aggre_selecttext.
  l_text2 = is_cpu_cal-aggre_selecttime.
  WRITE:/10 l_text1 ,96 l_text2 COLOR 7.
  SKIP .
  l_text1 = is_cpu_cal-faobj2_resulttext.
  l_text2 = is_cpu_cal-faobj2_resultcnt.
  WRITE:/10 l_text1 ,96 l_text2 COLOR 7.
  SKIP.
  l_text1 = is_cpu_cal-ust04_seltext.
  l_text2 = is_cpu_cal-ust04_seltime.
  WRITE:/10 l_text1 ,96 l_text2 COLOR 7.
  SKIP 2.
  WRITE:/3 text-082 COLOR 2.
  SKIP .
  l_text1 = is_cpu_cal-cpu_tot_runtimetext.
  l_text2 = is_cpu_cal-cpu_tot_runtime.
  WRITE:/3 l_text1,20 l_text2 COLOR 6.


ENDFORM.                    " cpu_cal

*&---------------------------------------------------------------------*
*&      Form  get_random_number
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_RANDAM  text
*----------------------------------------------------------------------*
FORM get_random_number CHANGING p_randam TYPE i.
  CALL FUNCTION 'QF05_RANDOM_INTEGER'
       EXPORTING
            ran_int_max   = 100
            ran_int_min   = 1
       IMPORTING
            ran_int       = p_randam
       EXCEPTIONS
            invalid_input = 1
            OTHERS        = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " get_random_number
*&---------------------------------------------------------------------*
*&      Form  SOD_mat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_mat.


  DATA: ls_sod_per TYPE /psyng/sw_sod_performance_cal,
        l_text1 TYPE string ,
        l_text2 TYPE string.
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
      DESTINATION gt_rfcdes-rfcdest
       EXPORTING
            i_sodvrsio        = p_vrsin
            i_maxusers        = p_maxus
            i_sod_matrix_info = 'X'
       IMPORTING
            e_sod_performance = ls_sod_per
      EXCEPTIONS
      communication_failure = 1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc = 0.
    CLEAR: l_text1, l_text2.
***   No Derived logic, performance mode :
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-103.
    COMMIT WORK.
    SKIP 2.
    WRITE:/60 text-087 COLOR 1.
    SKIP 2.
    IF gt_rfcdes-rfcdest IS INITIAL.
      WRITE:/3 'System'(118),10 ':',12 'Local'(119).
    ELSE.
      WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
    ENDIF.
    SKIP.
    WRITE:/3 text-088 COLOR 2.
    l_text1 = ls_sod_per-no_drvd_text.
    l_text2 = ls_sod_per-no_drvd_performance.
    WRITE:/3 l_text1,99 l_text2 COLOR 6.
    CLEAR: l_text1, l_text2.

**Derived logic, performance mode :
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-102.
    COMMIT WORK.
    SKIP 2.
    WRITE:/3 text-090 COLOR 2.
    l_text1 = ls_sod_per-drvd_text.
    l_text2 = ls_sod_per-drvd_perfomance.
    WRITE:/3 l_text1,99 l_text2 COLOR 6.
    CLEAR: l_text1, l_text2.

***   No Derived logic, memory mode :
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-105.
    COMMIT WORK.
    SKIP 2.
    WRITE:/3 text-093 COLOR 2.
    l_text1 = ls_sod_per-no_drvd_mmry_text.
    l_text2 = ls_sod_per-no_drvd_mmry_mode.
    WRITE:/3 l_text1,99 l_text2 COLOR 6.
    CLEAR: l_text1, l_text2.

***** Derived logic, memory mode :
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-107.
    MESSAGE s113(/psyng/sw) WITH text-104.
    COMMIT WORK.
    SKIP 2.
    WRITE:/3 text-094 COLOR 2.
    l_text1 = ls_sod_per-drvd_mmry_text.
    l_text2 = ls_sod_per-drvd_mmry_mode.
    WRITE:/3 l_text1,99 l_text2 COLOR 6.
    CLEAR: l_text1, l_text2.
  ENDIF.
ENDFORM.                    " SOD_mat
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
  CLEAR: g_curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  g_curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = g_curr_report
            curr_variant  = g_variant
            vari_desc     = gt_vari_desc
       TABLES
            vari_contents = gt_irsparams
            vari_text     = gt_ivarit
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          ILLEGAL_REPORT_OR_VARIANT = 1
          ILLEGAL_VARIANTNAME = 2
          NOT_AUTHORIZED = 3
          NOT_EXECUTED = 4
          REPORT_NOT_EXISTENT = 5
          REPORT_NOT_SUPPLIED = 6
          VARIANT_EXISTS = 7
          VARIANT_LOCKED = 8
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
    l_jobname = text-083.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = g_curr_variant
              in_report   = g_curr_report.
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
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: g_variant, gt_ivarit, gt_vari_desc.
  REFRESH: gt_ivarit, gt_vari_desc.

  SELECT variant INTO g_variant FROM varid
                     WHERE report = sy-repid AND
                           variant LIKE '/PSYNG/%'
     order by variant DESCENDING.
    oldnumber = g_variant+7(7).
    exit.
  ENDSELECT.
  IF sy-subrc NE 0.
    g_variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO g_variant.
  ENDIF.

  gt_ivarit-langu = sy-langu.
  gt_ivarit-report = sy-repid.
  gt_ivarit-variant = g_variant.
  gt_ivarit-vtext = text-084.
  APPEND gt_ivarit.

  gt_vari_desc-report = sy-repid.
  gt_vari_desc-variant = g_variant.
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
  REFRESH gt_irsparams.

*Parameters
  gt_irsparams-selname = 'P_VRSIN'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_vrsin.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_GINFO'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_ginfo.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_CPU'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_cpu.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_MAT'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_mat.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_DIA'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_dia.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_TAB'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_tab.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_SOD'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_sod.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_MAXUS'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_maxus.
  APPEND gt_irsparams.

  gt_irsparams-selname = 'P_TP'.
  gt_irsparams-kind = 'P'.
  gt_irsparams-sign = 'I'.
  gt_irsparams-option = 'EQ'.
  gt_irsparams-low = p_tp.
  APPEND gt_irsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab

*&---------------------------------------------------------------------*
*&      Form  time_conversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_TIME  text
*      <--P_0  text
*      <--P_TEXT1  text
*----------------------------------------------------------------------*
FORM time_conversion CHANGING micosec TYPE i
                              p_text1 TYPE string.

  DATA: l_v_sec TYPE f,
       l_v_msec TYPE f,
       l_v_hrs TYPE f,
       l_v_min TYPE f.

  DATA: l_v_msec1 TYPE i,
        l_v_sec1 TYPE i,
        l_v_min1 TYPE i,
        l_v_hrs1 TYPE i.

  DATA :c_hr(2) TYPE c,
        c_min(2) TYPE c,
        c_sec(2) TYPE c.


  l_v_sec = micosec / 1000000.
  l_v_msec = micosec MOD 1000000.

  l_v_min = l_v_sec MOD 3600.
  l_v_hrs = l_v_sec / 3600.

  IF l_v_min > 60.
    l_v_sec = l_v_min MOD 60.
    l_v_min = l_v_min / 60.
  ELSE.
    l_v_sec = l_v_min.
    l_v_min = 0.
  ENDIF.
  l_v_msec1 = trunc( l_v_msec ).
  l_v_sec1 = trunc( l_v_sec ).
  l_v_min1 = trunc( l_v_min ).
  l_v_hrs1 = trunc( l_v_hrs ).

  p_text1 = l_v_msec1.
  c_sec = l_v_sec1.
  c_min = l_v_min1.
  c_hr = l_v_hrs1.
  CONCATENATE  p_text1 text-075 INTO p_text1 SEPARATED BY space.
  IF NOT l_v_sec1 IS INITIAL.
    CONCATENATE  c_sec text-095 p_text1 INTO p_text1 SEPARATED BY
 space.
  ENDIF.
  IF NOT l_v_min1 IS INITIAL.
    CONCATENATE c_min text-096 p_text1 INTO p_text1 SEPARATED BY
space.
  ENDIF.
  IF NOT l_v_hrs1 IS INITIAL.
    CONCATENATE c_hr text-097 p_text1 INTO p_text1 SEPARATED BY
space.
  ENDIF.


ENDFORM.                    " time_conversion
*&---------------------------------------------------------------------*
*&      Form  display_sw_tps
*&---------------------------------------------------------------------*
*  Display Security Weaver transports in the system
*
*  Security Weaver transports are transports that begin with:
*  P33, P7Q, P37, P7C and SE7
*----------------------------------------------------------------------*
FORM display_sw_tps.
  DATA: l_trkorr  TYPE e070-trkorr,
        l_as4text TYPE e07t-as4text.

  SKIP 2.
  WRITE:/53 text-110 COLOR 1.
  SKIP 2.
  IF gt_rfcdes-rfcdest IS INITIAL.
    WRITE:/ 'System'(118),10 ':',12 'Local'(119).
  ELSE.
    WRITE:/ text-118,10 ':',12 gt_rfcdes-rfcname.
  ENDIF.
  SKIP.
  WRITE:/ text-108 COLOR 5, 23 text-109 COLOR 5.

*  SELECT e070~trkorr e07t~as4text
*          INTO (l_trkorr, l_as4text)
*          FROM e070
*    INNER JOIN e07t
*            ON e070~trkorr = e07t~trkorr
*         WHERE e070~strkorr = space
*               AND e07t~langu = sy-langu
*               AND (
*                      e070~trkorr LIKE 'P33%' OR
*                      e070~trkorr LIKE 'P7Q%' OR
*                      e070~trkorr LIKE 'P7C%' OR
*
*                      e070~trkorr LIKE 'Y41%' OR
*                      e070~trkorr LIKE 'Y42%' OR
*                      e070~trkorr LIKE 'Y43%' OR
*                      e070~trkorr LIKE 'Y44%' OR
*                      e070~trkorr LIKE 'Y61%' OR
*                      e070~trkorr LIKE 'Y62%' OR
*
*                      e070~trkorr LIKE 'P37%' OR
*                      e070~trkorr LIKE 'SE7%'
*                    )
*         ORDER BY e070~trkorr DESCENDING.
*
*    WRITE:/ l_trkorr, 23 l_as4text.
*
*  ENDSELECT.

  DATA: lt_sw_tr TYPE TABLE OF e07t WITH HEADER LINE.
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
  DESTINATION gt_rfcdes-rfcdest
   EXPORTING
     i_transport                 = 'X'
   TABLES
     et_sw_tr                    = lt_sw_tr
   EXCEPTIONS
     communication_failure = 1 MESSAGE g_system_msg
     system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  LOOP AT lt_sw_tr.
    WRITE:/ lt_sw_tr-trkorr, 23 lt_sw_tr-as4text.
  ENDLOOP.
ENDFORM.                    " display_sw_tps


*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_type.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_category.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SYSTID'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TABLE_CAL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM table_se_cal.

  DATA:
        l_psyng_count  TYPE /psyng/longtextfield,
        l_config_count TYPE /psyng/longtextfield,
        l_mit_count    TYPE /psyng/longtextfield,
        l_res_count    TYPE /psyng/longtextfield,
        lf_not_auth TYPE flag,
        lf_oracle   TYPE flag,
      lt_psyng_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
      lt_config_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
      lt_mit_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
      lt_res_tab TYPE TABLE OF /psyng/sw_table_text WITH HEADER LINE,
        l_text1 TYPE string,
        l_text2 TYPE string,
        ls_summary type /psyng/sw_table_text.

*--- get table size info from remote
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
  CALL FUNCTION '/PSYNG/SW_DIAGNOSTIC_INFO'
    DESTINATION gt_rfcdes-rfcdest
   EXPORTING
     i_se_tables_size            = 'X'
   IMPORTING
     e_psyng_count               = l_psyng_count
     e_config_count              = l_config_count
     e_mit_count                 = l_mit_count
     e_res_count                 = l_res_count
     ef_not_auth                 = lf_not_auth
     ef_oracle                   = lf_oracle
   TABLES
     et_psyng_tab                = lt_psyng_tab
     et_config_tab               = lt_config_tab
     et_mit_tab                  = lt_mit_tab
     et_res_tab                  = lt_res_tab
  EXCEPTIONS
     communication_failure       = 1 MESSAGE g_system_msg
     system_failure              = 2 MESSAGE g_system_msg
     OTHERS                      = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*----output section agr table
  IF sy-subrc = 0.
    SKIP 2.
    WRITE:/60 text-054 COLOR 1.
*---SOD Matrix tables info
    SKIP 2.
    IF gt_rfcdes-rfcdest IS INITIAL.
      WRITE:/3 'System'(118),10 ':',12 'Local'(119).
    ELSE.
      WRITE:/3 text-118,10 ':',12 gt_rfcdes-rfcname.
    ENDIF.
    SKIP.
    IF NOT lf_not_auth IS INITIAL.
      WRITE:/3
'Tables Size Details are not fetched due to missing authorization'(116).
    ENDIF.
    IF lf_oracle IS INITIAL.
      WRITE:/3
      'Table Size Details only available for Oracle Database'(117).
    ENDIF.
    SKIP.
    SPLIT l_psyng_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.

    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
    clear ls_summary.
    LOOP AT lt_psyng_tab.
      WRITE:/3 lt_psyng_tab-tabname , 25 lt_psyng_tab-ddtext,
      85 lt_psyng_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_psyng_tab-s_type,
      114 lt_psyng_tab-kbytes LEFT-JUSTIFIED,
      129 lt_psyng_tab-blocks LEFT-JUSTIFIED,
      140 lt_psyng_tab-extents LEFT-JUSTIFIED.
      add lt_psyng_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_psyng_tab-kbytes  to ls_summary-kbytes.
      add lt_psyng_tab-blocks  to ls_summary-blocks.
      add lt_psyng_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).

*---Configuration Set tables info
    SKIP 2.
    SPLIT l_config_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.

    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
    clear ls_summary.
    LOOP AT lt_config_tab.
      WRITE:/3 lt_config_tab-tabname , 25 lt_config_tab-ddtext,
      85 lt_config_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_config_tab-s_type,
      114 lt_config_tab-kbytes LEFT-JUSTIFIED,
      129 lt_config_tab-blocks LEFT-JUSTIFIED,
      140 lt_config_tab-extents LEFT-JUSTIFIED.
      add lt_config_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_config_tab-kbytes  to ls_summary-kbytes.
      add lt_config_tab-blocks  to ls_summary-blocks.
      add lt_config_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).

*---Mitigation tables info
    SKIP 2.
    SPLIT l_mit_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.

    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
    clear ls_summary.
    LOOP AT lt_mit_tab.
      WRITE:/3 lt_mit_tab-tabname , 25 lt_mit_tab-ddtext,
      85 lt_mit_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_mit_tab-s_type,
      114 lt_mit_tab-kbytes LEFT-JUSTIFIED,
      129 lt_mit_tab-blocks LEFT-JUSTIFIED,
      140 lt_mit_tab-extents LEFT-JUSTIFIED.
      add lt_mit_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_mit_tab-kbytes  to ls_summary-kbytes.
      add lt_mit_tab-blocks  to ls_summary-blocks.
      add lt_mit_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).

*---SOD Results tables info
    SKIP 2.
    SPLIT l_res_count AT ':' INTO l_text1 l_text2.
    WRITE:/3 l_text1 , l_text2.
    SKIP.
    ULINE 3(144).
    SKIP.

    WRITE:/3 text-120,25 text-057,85 text-065,
           104 'Type', 114 'Size in KB', 129 'Blocks',
           140 'Extents'.
    SKIP.
    ULINE 3(144).
    clear ls_summary.
    LOOP AT lt_res_tab.
      WRITE:/3 lt_res_tab-tabname , 25 lt_res_tab-ddtext,
      85 lt_res_tab-rcd_cnt LEFT-JUSTIFIED, 104 lt_res_tab-s_type,
      114 lt_res_tab-kbytes LEFT-JUSTIFIED,
      129 lt_res_tab-blocks LEFT-JUSTIFIED,
      140 lt_res_tab-extents LEFT-JUSTIFIED.
      add lt_res_tab-rcd_cnt to ls_summary-rcd_cnt.
      add lt_res_tab-kbytes  to ls_summary-kbytes.
      add lt_res_tab-blocks  to ls_summary-blocks.
      add lt_res_tab-extents to ls_summary-extents.
    ENDLOOP.
    ULINE 3(144).
       WRITE:/3 'Total:',
       85 ls_summary-rcd_cnt LEFT-JUSTIFIED, 104 '',
       114 ls_summary-kbytes LEFT-JUSTIFIED,
       129 ls_summary-blocks LEFT-JUSTIFIED,
       140 ls_summary-extents LEFT-JUSTIFIED.
       NEW-LINE.
    ULINE 3(144).


  ENDIF.
ENDFORM.                    " TABLE_SE_CAL
*&---------------------------------------------------------------------*
*&      Form  f4_vrsio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_SVRSIO  text
*----------------------------------------------------------------------*
FORM f4_vrsio CHANGING e_vrsio TYPE /psyng/sodvrsio.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF help_value,
        ls_fields   TYPE help_value,
        lt_vrsio    TYPE TABLE OF /psyng/swsodvers,
        ls_vrsio    TYPE /psyng/swsodvers.

*--Get RFC destinations
  get_system p_system.
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
  CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
  DESTINATION gt_rfcdes-rfcdest
       EXPORTING
            if_vrsio = 'X'
       TABLES
            et_vrsio = lt_vrsio
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


  SORT lt_vrsio BY vrsio ASCENDING.

  ls_fields-tabname   = '/PSYNG/SWSODVERS'.
  ls_fields-fieldname = 'VRSIO'.
  ls_fields-selectflag = 'X'.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'VDESC'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  LOOP AT lt_vrsio INTO ls_vrsio.
    ls_values-line = ls_vrsio-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_vrsio-vdesc.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = text-t15
       IMPORTING
            select_value              = e_vrsio
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

ENDFORM.                                                    " f4_vrsio
