*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SOD_SYSWIDE_BYROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sod_syswide_byrole MESSAGE-ID /psyng/sw
NO STANDARD PAGE HEADING LINE-SIZE 170.
TABLES : agr_define,
         /psyng/conflict,
         usr21,
         rfcdes,
         /psyng/ex_sod_role_det,
         /psyng/ex_caobj_lock,
         /psyng/busarea,
         /psyng/bus_proce,
         /psyng/swsodorgm,
         /PSYNG/BC_BA_00.
INCLUDE  /psyng/sw_config.
INCLUDE  /psyng/sw_113.

TYPES: BEGIN OF typ_itcd,
         tcode              LIKE /psyng/psswtcd-tcode,
         rfcdest            LIKE rfcdes-rfcdest,
       END OF typ_itcd.
INCLUDE  /psyng/sod_syswide_byrole_top.

DATA : gt_return            TYPE TABLE OF bapiret2 WITH HEADER LINE,
       gf_cfg_set_enabled   TYPE flag,
       gf_dflt_enhance_matrix TYPE flag,
       g_en_enable          TYPE flag,
       g_dynnr              TYPE sy-dynnr,
       gt_faobj_system      TYPE /psyng/sw_tab_sys_faobj,
       gt_ao_sys            TYPE /psyng/sw_tab_sys_ao,
       lf_set_invalid       type flag,
       lf_set_nocover       type flag,
       lf_set_mismatch      type flag,
       lf_include_local     type flag,
       ls_ba_role           type /PSYNG/BC_BA_00,
       g_current_user       TYPE sy-uname,"C0700
       gt_selscrpar TYPE TABLE OF rsparams,"C1102
       g_alv_layout    TYPE slis_layout_alv.           "For ALV call
*---Selection Screen

*--Role Block
SELECTION-SCREEN: BEGIN OF BLOCK role_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) role_but USER-COMMAND role_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  63(12) text-198 USER-COMMAND verify_r
                                      MODIF ID rol.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-009 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS: role FOR agr_define-agr_name MODIF ID rol.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-084 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
select-options : rba for /PSYNG/BC_BA_00-busarea MODIF ID rol.
"(++)HBHALLA(PN-17817)(19/02/26)(Collapse button)
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-013 MODIF ID rol.
SELECTION-SCREEN: POSITION 28.
PARAMETERS:   rchdatf LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN: COMMENT 47(3) text-014 MODIF ID rol.
SELECTION-SCREEN: POSITION 53.
PARAMETERS:   rchdatt LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN PUSHBUTTON  65(10) text-019 USER-COMMAND shrl
MODIF ID rol.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : singrol TYPE flag DEFAULT 'X' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-161 FOR FIELD singrol
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : comprol TYPE flag DEFAULT 'X' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-162 FOR FIELD comprol
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : asign_r TYPE flag DEFAULT ' ' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-166 FOR FIELD asign_r
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK role_o.
*--Conflict Block

SELECTION-SCREEN: BEGIN OF BLOCK con_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) con_but USER-COMMAND con_but.
SELECTION-SCREEN COMMENT 16(50) text-b03 .
SELECT-OPTIONS:
   spconfs FOR /psyng/conflict-conid    MODIF ID con,
   pappa   FOR /psyng/busarea-busarea   MODIF ID con,
   proca   FOR /psyng/bus_proce-subarea MODIF ID con,
   cowner  FOR /psyng/conflict-owner    MODIF ID con,
   csens   FOR /psyng/conflict-imp      MODIF ID con,
   s_risk  FOR /psyng/conflict-risk     MODIF ID con,
   cprmit  FOR /psyng/conflict-contid   MODIF ID con.

*  Version selection
PARAMETERS:  sodvrsio LIKE /psyng/conflict-vrsio
MEMORY ID /psyng/vrsio                  MODIF ID con.

PARAMETERS : cfgset   TYPE /psyng/seconfid MODIF ID con.
SELECTION-SCREEN: END OF BLOCK con_o.


*--Remote Block
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) rem_but
  USER-COMMAND rem_but .
SELECTION-SCREEN COMMENT 16(50) text-b02  .
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : ronlyrem TYPE flag USER-COMMAND remo MODIF ID rem.
SELECTION-SCREEN: COMMENT 7(47) text-075 FOR FIELD ronlyrem
                                         MODIF ID rem.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER : p_abap AS CHECKBOX DEFAULT 'X' USER-COMMAND abap
MODIF ID rem.
SELECTION-SCREEN: COMMENT 4(28) text-o24 FOR FIELD p_abap
                                          MODIF ID rem.
SELECTION-SCREEN: POSITION 34.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(20) text-159 MODIF ID rem.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
"RFC destination for remote analysis
SELECTION-SCREEN: END OF LINE.

*-- SE 3.4 - EN 2.1 Integration Piece
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER : p_nabap AS CHECKBOX USER-COMMAND aba1
 MODIF ID rem.
SELECTION-SCREEN: COMMENT 4(28) text-o23 FOR FIELD p_nabap
                                          MODIF ID rem.
SELECTION-SCREEN: POSITION 34.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS : s_appl FOR /psyng/ex_caobj_lock-appl MODIF ID rem,
                 s_sys  FOR /psyng/ex_caobj_lock-sysid MODIF ID rem.

SELECTION-SCREEN: END OF BLOCK rem_o.

*--Simulation Block
SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) simu_but USER-COMMAND simu_but.
SELECTION-SCREEN COMMENT 16(50) text-b06 .

SELECTION-SCREEN INCLUDE BLOCKS b_sim.

SELECTION-SCREEN: END OF BLOCK sim_o.

*---Output Block
SELECTION-SCREEN: BEGIN OF BLOCK out_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) out_but USER-COMMAND out_but.
SELECTION-SCREEN COMMENT 16(50) text-b04 .

SELECTION-SCREEN: BEGIN OF BLOCK res WITH FRAME TITLE text-o05.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shosum RADIOBUTTON GROUP g6 DEFAULT 'X'
                                          MODIF ID out
                   USER-COMMAND show.  "SOD conflict
SELECTION-SCREEN: COMMENT 4(28) text-o10 FOR FIELD shosum
                                          MODIF ID out.
SELECTION-SCREEN: POSITION 34.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shodet   RADIOBUTTON GROUP g6 MODIF ID out.
SELECTION-SCREEN: COMMENT 4(50) text-o22 FOR FIELD shodet
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK res.
PARAMETERS : xmc      AS CHECKBOX DEFAULT ' ' MODIF ID out.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : shonosod TYPE flag MODIF ID out.
SELECTION-SCREEN: COMMENT 3(50) text-076 FOR FIELD shonosod
                                         MODIF ID out.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: pcolor AS CHECKBOX DEFAULT ' ' MODIF ID out
USER-COMMAND pcolor.
SELECTION-SCREEN: COMMENT 3(30) text-000 FOR FIELD pcolor
                                         MODIF ID out.
SELECTION-SCREEN: END OF LINE.
parameters :
  odt      AS CHECKBOX DEFAULT ' ' MODIF ID out.
SELECTION-SCREEN: END OF BLOCK out_o.


*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 16(50) text-b05.
PARAMETERS: ustb AS CHECKBOX DEFAULT ' '   MODIF ID exe,
            orgchk AS CHECKBOX DEFAULT ' ' USER-COMMAND org
                                           MODIF ID exe.
SELECT-OPTIONS
            orglvl  FOR /psyng/swsodorgm-abb
                                           MODIF ID exe.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance MODIF ID exe.
SELECTION-SCREEN COMMENT 3(30) text-155 MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX MODIF ID exe.
SELECTION-SCREEN COMMENT 36(50) text-156 MODIF ID exe.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe_o.

SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
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

*--Hidden parameters

PARAMETERS: varntnam LIKE varid-variant NO-DISPLAY,
            p_first TYPE flag NO-DISPLAY.

LOAD-OF-PROGRAM.
  p_first = 'X'.
**--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.

*---Default config param for enhanced sod matrix checkbox
  se_config_param 'DFLT_ENHANCE_MATRIX' gf_dflt_enhance_matrix.
  IF gf_dflt_enhance_matrix = 'Y' OR gf_dflt_enhance_matrix = 'X'.
    IF p_enhanc IS INITIAL.
      p_enhanc = 'X'.
    ENDIF.
  ELSE.
    CLEAR p_enhanc.
  ENDIF.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM set_button_icons.
  PERFORM exelog.
  PERFORM get_initial_config.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high.


AT SELECTION-SCREEN.
  PERFORM check_input.
  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.
  IF ronlyrem = 'X'.
    IF remrfc[] IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for remote analysis'(180).
    ENDIF.
  ENDIF.

  LOOP AT SCREEN.
    IF screen-name = 'P_NABAP' AND p_nabap = 'X'.
      IF byrsimu = 'X' OR bysimu = 'X'.
*        CLEAR: byrsimu, bysimu.
        clear p_nabap.
        screen-input = 0.
        MODIFY SCREEN.
        MESSAGE w002 WITH text-181 text-182.
      else.
         screen-input = 1.
         MODIFY SCREEN.
*        STOP.
      ENDIF.

    ENDIF.
  ENDLOOP.

*--check warning msg for config set & versio
  IF NOT gf_cfg_set_enabled IS INITIAL.
     if sy-ucomm is initial.
*--Check Config Set
*      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
*           EXPORTING
*                i_setid         = cfgset
*                i_vrsio         = sodvrsio
*                if_show_warning = 'X'.
      lf_include_local = 'X'.
      if ronlyrem = 'X'.
        clear lf_include_local.
      endif.
     CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
            i_setid         = cfgset
            i_vrsio         = sodvrsio
            if_show_warning = 'X'
            IF_LOCAL_SYSTEM = lf_include_local
       TABLES
         IT_RFCDEST         = remrfc.

    ENDIF.
  ENDIF.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

AT SELECTION-SCREEN OUTPUT. " ON RADIOBUTTON GROUP G2.


  DATA:
        g_installed TYPE /psyng/bapiflagx,
        g_module_version TYPE  /psyng/prog_vrsio,
        g_swconfig TYPE /psyng/swconfig.
*--Check if Configuration Set functionality is enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
      DATA l_vrsio TYPE /psyng/sodvrsio.
*Get sod version default
*      CALL FUNCTION '/PSYNG/SW_034'
*           IMPORTING
*                e_vrsio = l_vrsio.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
           EXPORTING
                i_vrsio      = 'X'
                i_cfgvrsio   = sodvrsio "l_vrsio
           IMPORTING
                e_config_set = cfgset.
    ENDIF.
  ENDIF.

*-- Check EN integeration parmaeter
  CLEAR g_swconfig.
  se_config_param 'EN_INTEGRATION' g_swconfig-value.

*-- Check if EN is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'EN'
       IMPORTING
            e_installed      = g_installed
            e_module_version = g_module_version.

  PERFORM handle_button.
  PERFORM handle_sections.

  LOOP AT SCREEN.
    CASE screen-name .
      WHEN 'PCOLOR'.
        IF shodet = 'X'.
          screen-input = 0.
          CLEAR pcolor.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'SHODET'.
        IF pcolor = 'X'.
          screen-input = 0.
          CLEAR shodet.
          shosum  = 'X'.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'PCOLOR' .
        screen-input = 1 .
      WHEN 'SHONOSOD'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT spconfs[] IS INITIAL OR NOT s_risk[] IS INITIAL
        OR NOT csens[] IS INITIAL.
          IF shonosod = 'X'.
            CLEAR shonosod.
            screen-input = 0.
            MESSAGE w398(00) WITH text-c03.
          ENDIF.

          screen-input = 0.
          CLEAR shonosod.
        ELSE.
          screen-input = 1.
        ENDIF.
*--Disable Show no SOD when detailed output is requested
        IF shodet = 'X'.
          screen-input  = '0'.
          IF shonosod = 'X'.
            CLEAR shonosod.
            MESSAGE w398(00) WITH text-c03.
          ENDIF.
        ELSE.
          IF spconfs[] IS INITIAL
          AND s_risk[] IS INITIAL
          AND csens[] IS INITIAL.

            screen-input  = '1'.
          ENDIF.
        ENDIF.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          screen-input = 1.
          IF p_first = 'X'.
            CLEAR p_first.
            p_hienhn = 'X'.
          ENDIF.
        ENDIF.
      WHEN 'ORGCHK'.
        IF gf_hide_org = 'X'.
          screen-active = 0.
        ELSE.
          screen-active = 1.
        ENDIF.
      WHEN 'ORGLVL-LOW' OR 'ORGLVL-HIGH'.
        IF orgchk = 'X'.
          screen-input = 1.
        ELSE.
          REFRESH : orglvl.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.

*--Single/Composite role options
      WHEN 'COMPROL'.
        IF bysimu = 'X'.
          comprol = 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'SINGROL'.
        IF bysimu = 'X'.
          singrol = 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN .

    IF screen-group1 = '001'.
      AUTHORITY-CHECK OBJECT 'S_BTCH_ADM'
      ID 'BTCADMIN' FIELD 'Y'.
      IF sy-subrc <> 0.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF screen-name = 'P_NABAP' OR screen-name = 'P_ABAP'
    OR screen-name = '%_P_ABAP_%_APP_%-TEXT'
    OR screen-name = '%_P_NABAP_%_APP_%-TEXT'
    OR screen-name = 'S_APPL-LOW'
    OR screen-name = 'S_APPL-HIGH'
    OR screen-name = '%_S_APPL_%_APP_%-TEXT'
    OR screen-name =  '%_S_APPL_%_APP_%-VALU_PUSH'
    OR screen-name =  '%_S_SYS_%_APP_%-TEXT'

    OR screen-name = 'S_SYS-LOW'
    OR screen-name = 'S_SYS-HIGH'
    OR screen-name = '%_S_SYS_%_APP_%-VALU_PUSH'.
      screen-group2 = 'EN'.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

  LOOP AT SCREEN.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND screen-name CS 'CFGSET'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.
    CASE screen-group2.
      WHEN 'EN'.
*-- EN Integration
        IF g_swconfig-value <> 'Y'.
          screen-invisible = 1.
          screen-active    = 0.
        ELSE.
          IF g_installed = 'X' AND g_module_version GT '2.0PS3'.
            IF p_nabap IS INITIAL.
              IF screen-name = 'S_APPL-LOW'
              OR screen-name = 'S_APPL-HIGH'
              OR screen-name = 'S_SYS-LOW'
              OR screen-name = 'S_SYS-HIGH'.
                screen-input    = 0.
              ELSE.
                screen-input    = 1.
              ENDIF.
            ENDIF.
          ELSE.
            screen-invisible = 1.
            screen-active    = 0.
            REFRESH: s_appl,s_sys.
          ENDIF.
        ENDIF.
*              ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.
***********************************************************************
START-OF-SELECTION.

*BOC UMITTAL ATC check SIEMENS 11/02/25
AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.
*EOC UMITTAL ATC check SIEMENS 11/02/25
  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
*        CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
*             EXPORTING
*                  i_setid          = cfgset
*                  i_vrsio          = sodvrsio
*                  if_show_warning  = 'X'
*             IMPORTING
*                  ef_wrong_version = lf_set_invalid.
*--Check Config Set
      lf_include_local = 'X'.
      if ronlyrem = 'X'.
        clear lf_include_local.
      endif.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
            i_setid            = cfgset
            i_vrsio            = sodvrsio
            if_show_warning    = 'X'
            IF_LOCAL_SYSTEM    = lf_include_local
        IMPORTING
            ef_wrong_version   = lf_set_invalid
            EF_MISSING_SYSTEM  = lf_set_nocover
            EF_SYSTEM_MISMATCH = lf_set_mismatch
       TABLES
         IT_RFCDEST            = remrfc.
    IF lf_set_invalid  = 'X' or
       lf_set_nocover  = 'X'.
      EXIT.
    ENDIF.

  ENDIF.


*--Clear system filter buffer when a new analysis starts
  CALL FUNCTION '/PSYNG/SW_124'
       EXPORTING
            if_clear_buffer = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  DATA : lt_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu,
         lt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu.
  FREE gt_return.
  CLEAR g_warning_msg.
  program = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.
*--Display information about parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid = program.

*-- Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

*-- Report Title
  CONCATENATE sy-title text-154 sodvrsio
              INTO sy-title SEPARATED BY space.


  REFRESH : gt_role_removal_simu,gt_role_addition_simu.
  IF byrsimu = 'X'.
*--prepare table for role removal simulation
    PERFORM prepare_role_removal_simu
      TABLES lt_role_removal_simu.
    gt_role_removal_simu[] = lt_role_removal_simu[].
  ENDIF.
  IF bysimu = 'X'.
*--3.1 prepare table for role removal simulation
    PERFORM prepare_role_addition_simu
      TABLES lt_role_addition_simu.
    gt_role_addition_simu[] = lt_role_addition_simu[].
  ENDIF.

*--Field Validations
  PERFORM get_conflicts_from_selection.
  PERFORM validate_other_fields.

  IF p_nabap = 'X' AND singrol IS INITIAL AND comprol = 'X'.
    CLEAR p_nabap.
    MESSAGE i002 WITH
    'Composite Roles not supported on NON-ABAP systems.'(n01)
    'Only ABAP systems will be analyzed.'(n02).
  ENDIF.

  IF NOT shosum IS INITIAL.
*--Summary Analysis
      lt_role_addition_simu[] = gt_role_addition_simu[].
      lt_role_removal_simu[] = gt_role_removal_simu[].
      PERFORM summary_analysis_with_simu
      TABLES lt_role_removal_simu
             lt_role_addition_simu
      USING
        bysimu
        byrsimu.
      EXIT.
  ELSE.
*--Detailed Analysis
    PERFORM detailed_sod_analysis
      USING
        routdet3
        'X'.

  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_input.
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest,
        lt_dest2 LIKE TABLE OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
         lt_remrfc TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
LINE.

  RANGES: lr_dest FOR rfcdes-rfcdest.

  IF sy-ucomm = 'ADVSIM'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    CALL FUNCTION '/PSYNG/SW_080'
         TABLES
              et_srole = role
              et_crole = role.
    EXIT.
  ENDIF.

  IF sy-ucomm = 'SHRL'.
    PERFORM show_roles_based_on_dates.
  ENDIF.

*  IF bysimu = 'X' AND simurols IS INITIAL AND sy-ucomm+0(1) <> '%' AND
*                                              sy-ucomm <> 'RADI'.
*    SET CURSOR FIELD 'SIMUROLS-LOW'.
*    MESSAGE e208(00) WITH text-032.
*  ENDIF.
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

* SE 3.2 - Verify Roles
  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    EXIT.
  ENDIF.


  IF  NOT rchdatf IS INITIAL.
    IF rchdatt IS INITIAL .
      rchdatt = '99991231'.
    ENDIF.
    IF rchdatf > rchdatt.
      SET CURSOR FIELD 'RCHDATT'.
      MESSAGE e650(db).
    ENDIF.
  ELSEIF role IS INITIAL AND sy-ucomm+0(1) <> '%' AND
                               sy-ucomm <> 'SHRL' AND
                               sy-ucomm <> 'RADI' AND
                               sy-ucomm NP '*BUT' AND
                               sy-ucomm <> 'SHOW'.
  ENDIF.

  IF comprol IS INITIAL AND singrol IS INITIAL.
    IF sy-batch IS INITIAL.
      MESSAGE e208(00) WITH
      'Select either Composite or Single Roles or both'(163).
    ELSE.
*--If old variants are used that have none of these options,
*  select both
      MESSAGE s208(00) WITH
      'Analyzing Composite and Single Roles'(164).
    ENDIF.
  ENDIF.

  IF shodet = 'X' AND role IS INITIAL AND rchdatf IS INITIAL.
    SET CURSOR FIELD 'ROLE-LOW'.
    MESSAGE e208(00) WITH 'Please enter Role(s)'(165).
  ENDIF.
*  endif.
  IF byrsimu = 'X' AND ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' )
"#EC SAST_CI_GEN_CHECK (HBHALLA)
  AND
    rr_rol_1[] IS INITIAL AND
    rr_rol_2[] IS INITIAL AND
    rr_rol_3[] IS INITIAL AND
    rr_rol_4[] IS INITIAL.
    MESSAGE w140 WITH
    'Please enter role(s) for simulation'(181).
  ENDIF.

  IF bysimu = 'X' AND ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' )
"#EC SAST_CI_GEN_CHECK (HBHALLA)
  AND
    ar_rol_1[] IS INITIAL AND
    ar_rol_2[] IS INITIAL AND
    ar_rol_3[] IS INITIAL AND
    ar_rol_4[] IS INITIAL.
    MESSAGE w140 WITH
    'Please enter role(s) for simulation'(178).
*HBHALLA: Created & alloted correct text element
  ENDIF.



ENDFORM.                    " check_input

*
*---------------------------------------------------------------------*
*       FORM get_remote_results                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_remote_results USING taskname.
  DATA : lt_routput_sum   TYPE TABLE OF /psyng/sw_out_routput,
         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
         WITH HEADER LINE,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i,
         lt_mitigations TYPE TABLE OF /psyng/mitigation_assignment.

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_036'

     IMPORTING
       o_totalroles          = l_numroles
     TABLES
       ot_routput_sum        = lt_routput_sum
       et_simu_removed_roles = lt_removed_roles
       et_mitigations        = lt_mitigations
      EXCEPTIONS
       communication_failure = 1 MESSAGE l_system_msg
       system_failure        = 2 MESSAGE l_system_msg
       OTHERS                = 3.
  IF sy-subrc = 0.
    APPEND LINES OF lt_routput_sum TO gt_routput_sum.
    APPEND LINES OF lt_removed_roles TO gt_removed_roles.
    APPEND LINES OF lt_mitigations TO gt_mitigations.

    FREE : lt_routput_sum,lt_removed_roles,lt_mitigations .
    ADD l_numroles TO trolecount.
  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.

        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg
        INTO gt_return-message.
        COLLECT gt_return.

      WHEN 3.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.

        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        INTO gt_return-message.
        COLLECT gt_return.
    ENDCASE.

  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.

ENDFORM.



*&---------------------------------------------------------------------*
*&      Form  ROLE_DOUBLE_CLICK_ON_SUMRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA :  lf_was_collapsed TYPE flag,
          l_rsimu        TYPE flag,
          l_uname        LIKE sy-uname,
          l_contid       TYPE /psyng/mchdr-contid,
          l_parva        TYPE usr05-parva,
          l_sod          TYPE /psyng/swsodvers-vrsio,
          l_parva_exists like sy-subrc.

  CASE r_ucomm.
    WHEN 'ROLESIMU'.
      IF simu_but <> '@3T'.
        lf_was_collapsed = 'X'.
        PERFORM expand USING simu_but.
      ENDIF.
      CALL SCREEN '0101' STARTING AT 10 10.
      IF lf_was_collapsed = 'X'.
        PERFORM collapse USING simu_but.
      ENDIF.
      EXIT.
    WHEN 'ROLEREMDET'.
      CALL SCREEN '0102' STARTING AT 10 10.
      EXIT.
     WHEN 'SELSCRINFO'.
*--HBHALLA : 26/10/2023
*--selection screen values in run time
      PERFORM show_sel_scr_info.
  ENDCASE.

  CASE rs_selfield-fieldname.
    WHEN 'MIT_ICON'.
      READ TABLE routdet3 INDEX rs_selfield-tabindex.
      IF routdet3-contid IS INITIAL.
        MESSAGE e123 WITH routdet3-agr_name routdet3-conid.
      ENDIF.
      PERFORM show_mit_details USING routdet3.
      EXIT.

    WHEN 'SIMU_AFTER'.
      READ TABLE routdet3 INDEX rs_selfield-tabindex.
      IF routdet3-simu_after <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
         'This conflict doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11)
         .
        EXIT.
      ELSE.
        READ TABLE routdet3 INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0 AND routdet3-conid <> '----'.
        PERFORM detailed_sod_analysis
          USING
            routdet3
            ''.
        EXIT.
      ENDIF.

    WHEN 'SIMU_BEFORE'.
      READ TABLE routdet3 INDEX rs_selfield-tabindex.
      IF routdet3-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This conflict didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE routdet3 INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0 AND routdet3-conid <> '----'.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.
        PERFORM detailed_sod_analysis
          USING
            routdet3
            ''.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.

        EXIT.
      ENDIF.

    WHEN 'CONID'.
      READ TABLE routdet3 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0 AND routdet3-conid <> '----'.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF routdet3-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
               'This conflict doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      PERFORM detailed_sod_analysis
        USING
          routdet3
          ''.
      EXIT.
    WHEN 'CONTID'.

      CHECK rs_selfield-value <> space.
      l_contid = rs_selfield-value.
      l_uname = g_current_user."sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      l_parva_exists = sy-subrc.
      IF l_parva_exists = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname 0.

      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD rs_selfield-value.
      g_dynnr = '0211'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA : l_jobname TYPE btcjob.
  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = variant
            vari_desc     = vari_desc
       TABLES
            vari_contents = irsparams
            vari_text     = ivarit
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = text-069.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = curr_variant
              in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_back_job
*&---------------------------------------------------------------------*
*&      Form  show_roles_based_on_dates
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM show_roles_based_on_dates.
  DATA: tagr_define LIKE agr_define OCCURS 0 WITH HEADER LINE.
  DATA: ifield_dif LIKE field_dif OCCURS 0 WITH HEADER LINE.
*  DATA : ifield_dif TYPE TABLE OF help_value WITH HEADER LINE,
*  data_tab TYPE TABLE OF char50 WITH HEADER LINE.
  DATA: lv_header(80),
        lv_count TYPE i,
        lv_count_char(9).
  DATA: lt_roles TYPE TABLE OF /psyng/comp_role_tcode,
        ls_roles TYPE /psyng/comp_role_tcode,
        lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_range_roles TYPE /psyng/range_agr_name.

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH text-070.
    EXIT.
  ENDIF.
  REFRESH tagr_define.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
              i_get_actual_data = 'X'
         TABLES
              it_roles          = role
              it_ba             = rba
              et_roles          = lt_roles.
    ls_range_roles-sign   = 'I'.
    ls_range_roles-option = 'EQ'.
  LOOP AT lt_roles INTO ls_roles.
    ls_range_roles-low = ls_roles-agr_name.
    APPEND ls_range_roles TO lt_range_roles.
  ENDLOOP.
  IF lt_range_roles IS NOT INITIAL.
  SELECT agr_name create_dat change_usr change_dat change_tim
             INTO CORRESPONDING FIELDS OF wa_iagr_define
             FROM agr_define
             WHERE agr_name IN lt_range_roles.
    IF rchdatf IS INITIAL.
      INSERT wa_iagr_define INTO TABLE tagr_define.
    ELSE.
      IF wa_iagr_define-change_dat IS INITIAL.
        CHECK wa_iagr_define-create_dat >= rchdatf AND
              wa_iagr_define-create_dat <= rchdatt.
        INSERT wa_iagr_define INTO TABLE tagr_define.
      ELSE.
        CHECK wa_iagr_define-change_dat >= rchdatf AND
              wa_iagr_define-change_dat <= rchdatt.
        INSERT wa_iagr_define INTO TABLE tagr_define.
      ENDIF.
    ENDIF.
  ENDSELECT.
  ENDIF.

  IF NOT tagr_define[] IS INITIAL.
  ifield_dif-tabname = 'AGR_DEFINE'.
  ifield_dif-fieldname = 'PARENT_AGR'.
  ifield_dif-no_display = 'X'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_USR'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_DAT'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_TIM'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_TMP'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CHANGE_TMP'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'ATTRIBUTES'.
  APPEND ifield_dif.

  DESCRIBE TABLE tagr_define LINES lv_count.
  MOVE lv_count TO lv_count_char.
  CONCATENATE lv_count_char text-134 INTO lv_header
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
       EXPORTING
            header         = lv_header
            tabname        = 'AGR_DEFINE'
            display_only   = 'X'
            endless        = 'X'
            display_toggle = 'X'
            no_insert      = 'X'
            no_delete      = 'X'
            no_move        = 'X'
            no_undo        = 'X'
            no_button      = 'X'
            x_end          = 90
       TABLES
            table          = tagr_define
            fielddif       = ifield_dif
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             NO_MORE_TABLES   = 1
             TOO_MANY_FIELDS = 2
             NAMETAB_NOT_VALID = 3
             HANDLE_NOT_VALID  = 4
             OTHERS          = 5 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  ELSE.
    MESSAGE i002 WITH 'No valid roles found'(n03).
    EXIT.
  ENDIF.

ENDFORM.                    " show_roles_based_on_dates

*---------------------------------------------------------------------*
*       ROLE-TOP-OF-PAGE                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM role-top-of-page.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
*        exedate(10),
        lv_exedate TYPE char10,
        lv_exetime(8) TYPE c,
        oldagr_name LIKE agr_define-agr_name,
        oldrfc TYPE rfcdest,
        lv_rolecount TYPE i,
        gl_rolecount TYPE i,
        gl_avgcon TYPE i,
        ls_cfg_set       TYPE /psyng/swcfgset,
        l_str            TYPE string,
        l_int            TYPE i,
        lv_output_count_roles LIKE TABLE OF routdet3 WITH HEADER LINE,
        l_concount_bs    type i, "before simulation
        c_totalcon       type string,
        c_beforesimucon  type string,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR


  STATICS : l_pages TYPE c,
            l_pgcnt TYPE i .

*1STOUTPUT data
  CLEAR: oldagr_name, lv_rolecount, averagecon,
         alv_grid_titl, conflictcount.
  LOOP AT routdet3.
    IF routdet3-agr_name <> oldagr_name
    OR routdet3-rfcdest <> oldrfc.
      CHECK routdet3-conid <> '----'.
      lv_rolecount = lv_rolecount + 1.
      oldagr_name = routdet3-agr_name.
      oldrfc      = routdet3-rfcdest.
    ENDIF.
    CHECK routdet3-conid <> '----'.
    IF bysimu = 'X' OR byrsimu = 'X'.
      IF routdet3-simu_after = 'X'.
        conflictcount = conflictcount + 1.
      ENDIF.
      IF routdet3-simu_before = 'X'.
        l_concount_bs = l_concount_bs + 1.
      ENDIF.
    ELSE.
      conflictcount = conflictcount + 1.
    ENDIF.
  ENDLOOP.
  averagecon      = conflictcount / lv_rolecount.
  c_rolecount     = lv_rolecount.
  c_averagecon    = averagecon.
  c_trolecount    = trolecount.
  c_totalcon      = conflictcount.
  c_beforesimucon = l_concount_bs.

  CONCATENATE c_trolecount text-143
              text-144 c_averagecon text-137
              c_rolecount text-145
              INTO alv_grid_titl SEPARATED BY space.
  CONDENSE alv_grid_titl.

*TITLE AREA
  wa-typ = 'H'.
  wa-info = text-139.
  APPEND wa TO header.
*BELOW AREA.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*--Configuration Set
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid = cfgset.
    wa-typ  = 'S'.
    wa-key  = 'Configuration Set:'(h32).
    l_int = cfgset.
    l_str = l_int.
    CONDENSE l_str.
    CONCATENATE l_str ' : '
    ls_cfg_set-description INTO wa-info SEPARATED BY space.
    APPEND wa TO header.
    wa-key  = 'Config Set Published:'(h33).
    IF ls_cfg_set-published = 'X'.
      wa-info = 'Yes'(h34).
    ELSE.
      wa-info = 'No'(h35).
    ENDIF.
    APPEND wa TO header.
    wa-key  = 'Config Set Changed :'(h36).
    WRITE ls_cfg_set-change_date TO wa-info.
    CONCATENATE wa-info 'by'(h37) ls_cfg_set-change_user
    INTO wa-info SEPARATED BY space.
    APPEND wa TO header.

  ENDIF.

*Date
  WRITE sy-datum TO lv_exedate.
  wa-typ = 'S'.
  wa-key = text-140.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO lv_exetime SEPARATED BY ':'.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user"sy-uname C0700
   text-141 lv_exedate lv_exetime text-199 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*NEXT LINE.
  wa-typ = 'S'.
  wa-key = 'Summary:'(142).
  wa-info = alv_grid_titl.
  APPEND wa TO header.
  IF bysimu = 'X' OR byrsimu = 'X'.
*--Before Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'Before simulation'(h38).
    concatenate c_beforesimucon 'Conflicts'(h40)
    into wa-info separated by space .
    APPEND wa TO header.
*--After Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'After simulation'(h39).
    concatenate c_totalcon 'Conflicts'(h40)
    into wa-info separated by space .
    APPEND wa TO header.
  endif.


  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    wa-typ = text-167.
    wa-key = text-h28.
    CONDENSE l_pages NO-GAPS.
    wa-info = l_pages.
    APPEND wa TO header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header
            i_logo             = 'Z_3SW_LOGO_JPG'.

  IF ( sy-batch  IS INITIAL AND sy-binpt IS INITIAL ).
    IF gf_st_missing_auth = 'X'.
      MESSAGE w191(/psyng/sw).
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
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


*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH irsparams.
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = program
            if_no_logging = 'X'
       TABLES
            et_params     = irsparams.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
FORM get_next_variant_id.
*  DATA: oldnumber(7) TYPE n, oldnumber_c(7).
*
*  CLEAR: variant, ivarit, vari_desc.
*  REFRESH: ivarit, vari_desc.
*
*  SELECT variant INTO variant FROM varid
*                     WHERE report = sy-repid AND
*                     variant LIKE '/PSYNG/%' AND
*                 NOT variant LIKE '/PSYNG/Z%'
*                   ORDER BY variant DESCENDING.
*    oldnumber = variant+7(7).
*    EXIT.
*  ENDSELECT.
*  IF sy-subrc NE 0.
*    variant = '/PSYNG/0000000'.
*  ELSE.
*    oldnumber = oldnumber + 1.
*    MOVE oldnumber TO oldnumber_c.
*    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
*  ENDIF.

*C017 Odubey 29/11/2021
CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
  EXPORTING
    i_report        = sy-repid
 IMPORTING
   E_VARIANT       = variant.

  ivarit-langu = sy-langu.
  ivarit-report = sy-repid.
  ivarit-variant = variant.
  ivarit-vtext = text-146.
  APPEND ivarit.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.
ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  wrap_up
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM wrap_up.
  IF varntnam <> space.
    CALL FUNCTION 'RS_VARIANT_DELETE'
         EXPORTING
              report             = curr_report
              variant            = varntnam
              flag_confirmscreen = 'X'
*       FLAG_DELALLCLIENT          =
*     IMPORTING
*       VARIANT                    =
     EXCEPTIONS
       not_authorized             = 1
       not_executed               = 2
       no_report                  = 3
       report_not_existent        = 4
       report_not_supplied        = 5
       variant_locked             = 6
       variant_not_existent       = 7
       no_corr_insert             = 8
       variant_protected          = 9
       OTHERS                     = 10.
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE w208(00) WITH text-071.
        WHEN 7.
          MESSAGE w208(00) WITH text-072.
        WHEN OTHERS.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDCASE.
    ENDIF.
  ENDIF.
ENDFORM.                    " wrap_up
*---------------------------------------------------------------------*
*       FORM build_role_sort_order                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_role_sort_order USING type.
  CLEAR: l_sort, isort.
  REFRESH: isort.
  l_sort-spos = '1'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'ISORT'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '5'.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '7'.
  l_sort-fieldname = 'RISK'.
  l_sort-tabname = 'ROUTDET3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  if p_nabap = 'X'.
    l_sort-spos = '8'.
    l_sort-fieldname = 'APPL'.
    l_sort-tabname = 'ROUTDET3'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
  endif.
ENDFORM.                    " build_role_sort_order

*---------------------------------------------------------------------*
*       FORM display_role_of_remote_system                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDS                                                        *
*  -->  CODE                                                          *
*  -->  ERROR                                                         *
*  -->  SHOW_POPUP                                                    *
*---------------------------------------------------------------------*
FORM display_role_of_remote_system TABLES   fields STRUCTURE sval
                   USING    code
                   CHANGING error  STRUCTURE svale show_popup.
  CASE code.
    WHEN 'EXECUTE'.
    WHEN 'EXIT'.
    WHEN 'OK'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.

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
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: swconfig   TYPE /psyng/swconfig,
        l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE,
        l_vrsio    TYPE /psyng/prog_vrsio,
        lf_en TYPE flag.

*-- Get EN data
*  SELECT SINGLE vrsio INTO (l_vrsio) FROM (/psyng/ex_vrsio).
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'EN'
       IMPORTING
            e_installed      = lf_en
            e_module_version = l_vrsio.

  IF lf_en = 'X' AND ( l_vrsio GE '2.0PS3' or l_vrsio cs 'Q') .
*-- Check config Param
    se_config_param 'EN_INTEGRATION' swconfig-value.
    IF swconfig-value = 'Y'.
      g_en_enable = 'X'.
    ELSEIF swconfig-value = 'N'.
      g_en_enable  = ' '.
    ENDIF.
  ENDIF.
  CLEAR swconfig.


*Update Scan Table
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.
  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSEIF swconfig-value = 'N'.
    ustb = ' '.
  ENDIF.
  CLEAR swconfig.

*Highlight conflicts
  se_config_param 'DFLT_LIGT_COLOR' swconfig-value.
  IF swconfig-value = 'Y'.
    pcolor = 'X'.
  ELSEIF swconfig-value = 'N'.
    pcolor = ' '.
  ENDIF.
  CLEAR swconfig.
*--Hide Org Level Check option
  se_config_param 'HIDE_ORG_ANALYSIS' swconfig-value.
  IF swconfig-value = 'Y'.
    gf_hide_org = 'X'.
  ELSEIF swconfig-value = 'N'.
    gf_hide_org = ' '.
  ENDIF.
  CLEAR swconfig.

**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    orgchk = ' '.
  ENDIF.
  CLEAR swconfig.

*Show SOD Scan Output
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_SCAN_RSLT' swconfig-value.
  IF swconfig-value = 'Y'.
    odt = 'X'.
  ELSEIF swconfig-value = 'N'.
    odt = ' '.
  ENDIF.
  CLEAR swconfig.

* Default RFC
  IF remrfc[] IS INITIAL.
    IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ELSE.
*      l_table = 'TVARV'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ENDIF.

*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO remrfc.
      remrfc-option = lt_tvarv-opti.
      APPEND remrfc.
    ENDLOOP.
  ENDIF.
*Show Mitigated Conflicts
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.
  IF swconfig-value = 'Y'.
    xmc = 'X'.
  ELSEIF swconfig-value = 'N'.
    xmc = ' '.
  ENDIF.
  CLEAR swconfig.

*BOC 04-02-2025 AKUMAR OPL645
*Consider org field in risk definition
  clear swconfig.
  se_config_param 'CONSIDER_ORG_FIELD' swconfig-value.
  if swconfig-value = 'Y'.
    gf_org_field = 'X'.
  elseif swconfig-value = 'N'.
    gf_org_field = ' '.
  endif.
  clear swconfig.
*EOC 04-02-2025 AKUMAR OPL645

ENDFORM.                    " get_initial_config

*&---------------------------------------------------------------------*
*&      Form  role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_sod_analysis_from_details USING agr_name .

  SUBMIT /psyng/sodreport_org
          WITH role     = agr_name
          WITH byuser   = ' '
          WITH orgchk   = orgchk
          WITH p_enhanc = p_enhanc
          WITH p_hienhn  = p_hienhn
          WITH byrole   = 'X'
          WITH shosum   = 'X'
          WITH xmc      = xmc
          WITH sodvrsio    = sodvrsio
          WITH p_abap     = p_abap
          WITH p_nabap    = p_nabap
          AND RETURN.

ENDFORM.                    " role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*&      Form  report_rfc_error
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_RFC_ERROR  text
*      -->P_ROLERFC  text
*----------------------------------------------------------------------*
FORM report_rfc_error USING    l_rfc_error
                               rolerfc.
  MESSAGE i113(/psyng/sw) WITH  rolerfc l_rfc_error text-e02.
  STOP.

ENDFORM.                    " report_rfc_error

*&---------------------------------------------------------------------*
*&      Form  load_user_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USER_RFC  text
*      -->P_ET_RETURN  text
*----------------------------------------------------------------------*
FORM load_role_rfc
    TABLES
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
           WHERE rfcdest IN it_role_rfc.
*    IF sy-subrc <> 0.
*      MESSAGE e004(sr).
*    ENDIF.
  ENDIF.

*  LOOP AT et_rfcdes.
*    FREE : lt_dest.
*    lt_dest-rfcdest = et_rfcdes-rfcdest.
*    APPEND lt_dest.
*    CALL FUNCTION 'RFC_WALK_THRU_TEST'
*         EXPORTING
*              test_in      = l_rfc_test
*         TABLES
*              destinations = lt_dest
*              log          = lt_rfc_log.
*    LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*      PERFORM report_rfc_error USING
*      lt_rfc_log-rfcdest lt_rfc_log-rfclog.
*    ENDLOOP.
*  ENDLOOP.

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
*      CASE sy-subrc.
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH
*          text-e01
*          l_rfcdest
*          l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH
*          text-e01
*          l_rfcdest.
*      ENDCASE.
*      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
*Case 2061 - If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
*            ANy rfc destination pointing to the local system will
*            be ignored
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  f4_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_XROLERFC_LOW  text
*----------------------------------------------------------------------*
FORM f4_rfc CHANGING e_rfcdest TYPE rfcdest.
  DATA: table1 LIKE ddshretval OCCURS 0 WITH HEADER LINE.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = ''
            fieldname         = ''
            searchhelp        = 'AL_R3_RFCDEST'
       TABLES
            return_tab        = table1
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    READ TABLE table1 INDEX 1.
    IF sy-subrc = 0.
      e_rfcdest = table1-fieldval.
    ENDIF.
  ENDIF.

ENDFORM.                                                    " f4_rfc
FORM f4_orglvl USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
  EXPORTING
    i_cfg_set       = cfgset
 IMPORTING
   E_ORGLVL        = e_orglvl.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'ROLE_BUT' 'X' CHANGING role_but .
  PERFORM init_but USING 'REM_BUT'  '' CHANGING rem_but  .
  PERFORM init_but USING 'CON_BUT'  '' CHANGING con_but  .
  PERFORM init_but USING 'OUT_BUT'  '' CHANGING out_but  .
  PERFORM init_but USING 'EXE_BUT'  '' CHANGING exe_but  .
  PERFORM init_but USING 'SIMU_BUT' '' CHANGING simu_but .
  PERFORM init_but USING 'BGD_BUT'  '' CHANGING bgd_but  .

ENDFORM.                    " set_button_icons

*&---------------------------------------------------------------------*
*&      Form  handle_button
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_button.
  CASE g_ucomm.
    WHEN 'ROLE_BUT'.
      PERFORM toggle USING role_but 'ROLE_BUT'.
    WHEN 'REM_BUT'.
      PERFORM toggle USING rem_but 'REM_BUT'.
    WHEN 'CON_BUT'.
      PERFORM toggle USING con_but 'CON_BUT'.
    WHEN 'OUT_BUT'.
      PERFORM toggle USING out_but 'OUT_BUT'.
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
    WHEN 'SIMU_BUT'.
      PERFORM toggle USING simu_but 'SIMU_BUT'.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but 'BGD_BUT'.

  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.                    " handle_button
*---------------------------------------------------------------------*
*       FORM toggle_section                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME                                                *
*---------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.
  DATA : l_collapse TYPE flag.

  LOOP AT SCREEN .
    IF screen-group1 = i_section_name.
      IF i_button(3) <> '@3T'.
        screen-invisible = 1.
        screen-active    = 0.
        l_collapse = 'X'.
      ELSE.
        screen-invisible = 0.
        screen-active    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " toggle_section
*&---------------------------------------------------------------------*
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  role_but 'ROL'.
  PERFORM handle_section USING  rem_but  'REM'.
  PERFORM handle_section USING  con_but  'CON'.
  PERFORM handle_section USING  out_but  'OUT'.
  PERFORM handle_section USING  exe_but  'EXE'.
  PERFORM handle_section USING  simu_but 'SIM'.
  PERFORM handle_section USING  bgd_but  'BGD'.
ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USER_BUT  text
*      <--P_'USER_BUT'  text
*      <--P_'X'  text
*----------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE /psyng/usr_displ,
         l_exp TYPE flag.
  SELECT SINGLE * INTO ls_state
  FROM /psyng/usr_displ
  WHERE
    bname = g_current_user AND"sy-uname AND C0700
    repid = sy-repid AND
    button_name = i_name.
  IF sy-subrc = 0.
    l_exp = ls_state-expanded.
  ELSE.
    l_exp = i_default_expanded.
  ENDIF.

  IF l_exp = 'X'.
    PERFORM expand CHANGING i_button.
  ELSE.
    PERFORM collapse CHANGING i_button.
  ENDIF.

ENDFORM.                    " init_but



*---------------------------------------------------------------------*
*       FORM toggle                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*---------------------------------------------------------------------*
FORM toggle USING i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user."sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM expand CHANGING button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*      text   =  text-b01
*      info   = text-x02
      name   = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result = button
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " expand
*&---------------------------------------------------------------------*
*&      Form  collapse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REM_BUT  text
*----------------------------------------------------------------------*
FORM collapse CHANGING    button.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*      text   =  text-b01
*      info   = text-x01
      name   = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result = button
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " collapse

*&---------------------------------------------------------------------*
*&      Form  SHOW_SEL_SCR_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_sel_scr_info .

FIELD-SYMBOLS: <fs_selscrpar> TYPE rsparams.
  "Get selection screen info
  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
    EXPORTING
      curr_report               = program
    TABLES
      selection_table           = gt_selscrpar
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
            NOT_FOUND = 1
            NO_REPORT = 2
             OTHERS   = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
* Implement suitable error handling here
    else.
* Deleting unfilled fields
    LOOP AT gt_selscrpar ASSIGNING <fs_selscrpar>.
      IF <fs_selscrpar>-low IS INITIAL AND
         <fs_selscrpar>-high IS INITIAL.
        <fs_selscrpar>-kind = 'Z'.
      ENDIF.
    ENDLOOP.
    DELETE gt_selscrpar WHERE kind = 'Z'.
  ENDIF.

  "Set layout
  CLEAR g_alv_layout.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.

  PERFORM build_alv_catalog_sel_scr_info.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_top_of_page = 'SELSCR_INFO_HEADER'
    i_callback_program     = program
    is_layout    = g_alv_layout
    it_fieldcat  = i_fieldcat_alv
  TABLES
    t_outtab     = gt_selscrpar
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG_SEL_SCR_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog_sel_scr_info .
  DATA: ls_selscrpar TYPE rsparams.

  FIELD-SYMBOLS <fs_fieldcat> TYPE slis_fieldcat_alv.
  FREE : i_fieldcat_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name     = program
    i_internal_tabname = 'LS_SELSCRPAR'
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

  LOOP AT i_fieldcat_alv ASSIGNING <fs_fieldcat>.
    IF <fs_fieldcat>-fieldname = 'LOW'.
      <fs_fieldcat>-seltext_l = 'Low value'(205).
      <fs_fieldcat>-seltext_m = 'Low value'(205).
      <fs_fieldcat>-reptext_ddic = 'Low value'(205).
    ELSEIF <fs_fieldcat>-fieldname = 'HIGH'.
      <fs_fieldcat>-seltext_l = 'High value'(206).
      <fs_fieldcat>-seltext_m = 'High value'(206).
      <fs_fieldcat>-reptext_ddic = 'High value'(206).
    ENDIF.
  ENDLOOP.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  detailed_sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM detailed_sod_analysis
  USING
    is_output LIKE routdet3
    if_all    TYPE flag.
  DATA:  iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
**BOC : UMITTAL SMUD issue
*DATA : ls_role_val TYPE /psyng/key_val,
*       lv_role_id TYPE /psyng/ref_key.
**EOC : UMITTAL SMUD issue
  CLEAR:   iseltab.
  REFRESH: iseltab.
  IF if_all <> 'X'.
**BOC : UMITTAL SMUD issue
*    IF p_nabap EQ 'X'.
*      CLEAR ls_role_val.
*      ls_role_val = routdet3-agr_name.
*      SELECT SINGLE ref_key
*          INTO lv_role_id
*          FROM /psyng/ex_ref01
*          WHERE key_val = ls_role_val.
*          IF sy-subrc EQ 0.
*          ENDIF.
*      iseltab-selname = 'ROLE'.    "Role
*      iseltab-kind    = 'S'.
*      iseltab-sign    = 'I'.
*      iseltab-option  = 'EQ'.
*      iseltab-low     = lv_role_id.
*      APPEND iseltab.
*    ELSE.
**EOC : UMITTAL SMUD issue 10-10-2024
      iseltab-selname = 'ROLE'.    "Role
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = routdet3-agr_name.
      APPEND iseltab.
*    ENDIF. "(++)Added by : UMITTAL SMUD issue 10-10-2024
    iseltab-selname = 'SPCONFS'.   "specific onflicts
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = routdet3-conid.
    APPEND iseltab.
*--remote analysis
*--get remote rfc dest based on sysid-client
    DATA rfcdest TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO rfcdest.
    IF routdet3-rfcdest <> rfcdest.
      DATA : l_rfc TYPE rfcdes.
      READ TABLE gt_remote_anal_rfc INTO l_rfc
      WITH KEY rfcoptions = routdet3-rfcdest.
      iseltab-selname = 'XROLERFC'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = l_rfc-rfcdest.
      APPEND iseltab.
      iseltab-selname = 'RONLYREM'.  "only remote (hidden parameter)
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = 'X'.
      APPEND iseltab.
    ENDIF.

  ELSE.
    iseltab-kind = 'S'.
    LOOP AT role.
      iseltab-selname = 'ROLE'.
      MOVE-CORRESPONDING role TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    CLEAR iseltab.
    iseltab-kind = 'S'.
    LOOP AT rba.
      iseltab-selname = 'S_RBA'.
      MOVE-CORRESPONDING rba TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    CLEAR iseltab.
    LOOP AT gt_conid.
      iseltab-selname = 'SPCONFS'.
      MOVE-CORRESPONDING gt_conid TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    CLEAR iseltab.
    LOOP AT remrfc.
      iseltab-selname = 'XROLERFC'.
      MOVE-CORRESPONDING remrfc TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    CLEAR iseltab.
    iseltab-selname = 'RONLYREM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ronlyrem.
    APPEND iseltab.
  ENDIF.
  CLEAR iseltab.
  iseltab-selname = 'COMPROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = comprol.
  APPEND iseltab.
  CLEAR iseltab.
  iseltab-selname = 'SINGROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = singrol.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'ASSGN_R'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = asign_r.
  APPEND iseltab.


  CLEAR iseltab.
  iseltab-selname = 'BYROLE'.    "by role
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.
  iseltab-selname = 'BYUSER'.    "by role
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.

  iseltab-selname = 'SHODET'.    "show details
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.


*--B8102 - The change date range should also be passed
*  to the detailed report
  iseltab-selname = 'RCHDATF'.    "changed from date
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = rchdatf.
  APPEND iseltab.
  iseltab-selname = 'RCHDATT'.    "changed to date
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = rchdatt.
  APPEND iseltab.


  iseltab-selname = 'SHOSUM'.    "show details
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.
  iseltab-selname = 'VALIDUSR'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.
  iseltab-selname = 'XMC'.       "ignore mitigating controls
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = xmc.
  APPEND iseltab.
  iseltab-selname = 'ORGCHK'.       "Use Org Level Check
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = orgchk.
  APPEND iseltab.
  IF orgchk = 'X'.
    LOOP AT orglvl.
      iseltab-selname = 'ORGLVL'.       "Org Level Filter
      iseltab-kind    = 'S'.
      iseltab-sign    = orglvl-sign.
      iseltab-option  = orglvl-option.
      iseltab-low     = orglvl-low.
      iseltab-high    = orglvl-high.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.
  iseltab-selname = 'SODVRSIO'.        "SOD Version
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sodvrsio.
  APPEND iseltab.
  iseltab-selname = 'P_ENHANC'.       "include enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_HIENHN'.       "higlight enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_hienhn.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_NOPRIN'.       "don't show progress indicator
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.


  CLEAR iseltab.
  iseltab-selname = 'USTB'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ustb.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_CALDET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'CFGSET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = cfgset.
  APPEND iseltab.


  CLEAR iseltab.
  iseltab-selname = 'P_ABAP'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  IF if_all = 'X' OR routdet3-appl = 'SAP'.
    iseltab-low     = p_abap.
  ELSE.
    iseltab-low     = ''.
  ENDIF.
  APPEND iseltab.
  IF p_nabap = 'X' .
    CLEAR iseltab.
    iseltab-selname = 'P_NABAP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    IF if_all = 'X' OR routdet3-appl <> 'SAP'.
      iseltab-low     = p_nabap.
    ELSE.
      iseltab-low     = ''.
    ENDIF.
    APPEND iseltab.
    IF if_all = 'X'.
      LOOP AT s_appl.
        iseltab-selname = 'S_APPL'.       "Application
        iseltab-kind    = 'S'.
        iseltab-sign    = s_appl-sign.
        iseltab-option  = s_appl-option.
        iseltab-low     = s_appl-low.
        iseltab-high    = s_appl-high.
        APPEND iseltab.
      ENDLOOP.
    ELSE.
      iseltab-selname = 'S_APPL'.       "Application
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = routdet3-appl.
      iseltab-high    = ''.

      APPEND iseltab.
    ENDIF.
    LOOP AT s_sys.
      iseltab-selname = 'S_SYSID'.       "System
      iseltab-kind    = 'S'.
      iseltab-sign    = s_sys-sign.
      iseltab-option  = s_sys-option.
      iseltab-low     = s_sys-low.
      iseltab-high    = s_sys-high.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.

*simulation
  IF bysimu = 'X'.
    iseltab-selname = 'BYSIMU'.       "use simulation
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
*--Role addition Simulation
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.

    iseltab-selname = 'AR_RFCS1'.
    iseltab-low     =  ar_rfcs1.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCD1'.
    iseltab-low     =  ar_rfcd1.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCS2'.
    iseltab-low     =  ar_rfcs2.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCD2'.
    iseltab-low     =  ar_rfcd2.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCS3'.
    iseltab-low     =  ar_rfcs3.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCD3'.
    iseltab-low     =  ar_rfcd3.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCS4'.
    iseltab-low     =  ar_rfcs4.
    APPEND iseltab.

    iseltab-selname = 'AR_RFCD4'.
    iseltab-low     =  ar_rfcd4.
    APPEND iseltab.

    CLEAR iseltab.

    LOOP AT ar_rol_1.
      iseltab-selname = 'AR_ROL_1'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING ar_rol_1 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT ar_rol_2.
      iseltab-selname = 'AR_ROL_2'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING ar_rol_2 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT ar_rol_3.
      iseltab-selname = 'AR_ROL_3'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING ar_rol_3 TO iseltab.
      APPEND iseltab.
    ENDLOOP.

    LOOP AT ar_rol_4.
      iseltab-selname = 'AR_ROL_4'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING ar_rol_4 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.

*--Role Removal Simulation
  iseltab-selname = 'BYRSIMU'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = byrsimu.
  APPEND iseltab.

  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.

  iseltab-selname = 'RR_RFC_1'.
  iseltab-low     =  rr_rfc_1.
  APPEND iseltab.

  iseltab-selname = 'RR_RFC_2'.
  iseltab-low     =  rr_rfc_2.
  APPEND iseltab.

  iseltab-selname = 'RR_RFC_3'.
  iseltab-low     =  rr_rfc_3.
  APPEND iseltab.

  iseltab-selname = 'RR_RFC_4'.
  iseltab-low     =  rr_rfc_4.
  APPEND iseltab.

  CLEAR iseltab.

  LOOP AT rr_rol_1.
    iseltab-selname = 'RR_ROL_1'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_1 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT rr_rol_2.
    iseltab-selname = 'RR_ROL_2'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_2 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT rr_rol_3.
    iseltab-selname = 'RR_ROL_3'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_3 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT rr_rol_4.
    iseltab-selname = 'RR_ROL_4'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_4 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  SUBMIT /psyng/sodreport_org WITH SELECTION-TABLE iseltab AND RETURN.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  prepare_role_removal_simu
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*----------------------------------------------------------------------*
FORM prepare_role_removal_simu TABLES   et_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu.

  IF  NOT rr_rol_1[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_1.
    LOOP AT rr_rol_1.
      MOVE-CORRESPONDING rr_rol_1 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT  rr_rol_2[] IS INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_2.
    LOOP AT rr_rol_2.
      MOVE-CORRESPONDING rr_rol_2 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_3[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_3.
    LOOP AT rr_rol_3.
      MOVE-CORRESPONDING rr_rol_3 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_4[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_4.
    LOOP AT rr_rol_4.
      MOVE-CORRESPONDING rr_rol_4 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " prepare_role_removal_simu

*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status_summary USING it_extab TYPE slis_t_extab.
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.


  IF byrsimu IS INITIAL.
    lt_func-fcode = 'ROLEREMDET'.
    APPEND lt_func.
  ENDIF.

  lt_func-fcode = '&XINT'.
  APPEND lt_func.
  SET PF-STATUS 'SUMMARY' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Module  STATUS_0102  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0102 OUTPUT.
  SET PF-STATUS '300' EXCLUDING 'CANCEL'.
ENDMODULE.                 " STATUS_0102  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV_0102  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_0102 OUTPUT.
  PERFORM display_alv_0102 .
ENDMODULE.                 " DISPLAY_ALV_0102  OUTPUT

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_0102.
  SORT gt_removed_roles.
  DELETE ADJACENT DUPLICATES FROM gt_removed_roles.
  IF gr_alvgrid IS INITIAL .
    CREATE OBJECT gr_ccontainer
    EXPORTING
      container_name = gc_custom_control_name
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      others                      = 6 .
    IF sy-subrc <> 0.
*    "Error handling
    ENDIF.
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5 .
    IF sy-subrc <> 0.
*    Error handling
    ENDIF.
    PERFORM prepare_field_catalog_0102 CHANGING gt_fieldcat.
    PERFORM prepare_layout_0102        CHANGING gs_layout .
    CALL METHOD gr_alvgrid->set_table_for_first_display
     EXPORTING
       is_layout       = gs_layout
     CHANGING
       it_outtab       = gt_removed_roles[]
       it_fieldcatalog = gt_fieldcat
     EXCEPTIONS
       invalid_parameter_combination = 1
       program_error                 = 2
       too_many_lines                = 3
       OTHERS                        = 4 .
    IF sy-subrc <> 0.
*    Error handling
    ENDIF.
  ELSE.
    CALL METHOD gr_alvgrid->refresh_table_display
*     EXPORTING
*     IS_STABLE =
*     I_SOFT_REFRESH =
      EXCEPTIONS
        finished = 1
        OTHERS   = 2 .

  ENDIF.
ENDFORM.                    " DISPLAY_ALV_0102
*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM prepare_field_catalog_0102 CHANGING et_fieldcat TYPE lvc_t_fcat.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_REMOVED_ROLES_ROLE'
       CHANGING
            ct_fieldcat            = et_fieldcat[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
*    Error handling
  ENDIF.

ENDFORM.                    " prepare_field_catalog_0102
*&---------------------------------------------------------------------*
*&      Form  prepare_layout_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_LAYOUT  text
*----------------------------------------------------------------------*
FORM prepare_layout_0102 CHANGING es_layout TYPE lvc_s_layo.
  es_layout-zebra = 'X' .
  es_layout-grid_title = 'Roles Removed by Simulation' .
ENDFORM.                    " prepare_layout_0102

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0102  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0102 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN '000'.
      LEAVE SCREEN.
    WHEN 'CONTINUE'.
      SET SCREEN '000'.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0102  INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS '300'.


ENDMODULE.                 " STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN '000'.
      LEAVE SCREEN.
    WHEN 'CONTINUE'.
      PERFORM fill_sel_screen_fields_to_tab.
      SUBMIT /psyng/sod_syswide_byrole WITH
      SELECTION-TABLE irsparams AND RETURN.
      SET SCREEN '000'.
      LEAVE SCREEN.

*--Resubmit report
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT

*---------------------------------------------------------------------*
*       FORM prepare_role_addition_simu                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_ROLE_ADDITION_SIMU                                         *
*---------------------------------------------------------------------*
FORM prepare_role_addition_simu TABLES   et_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu.

  IF  NOT ar_rol_1[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs1.
    et_role_addition_simu-target_rfcdest = ar_rfcd1.
    LOOP AT ar_rol_1.
      MOVE-CORRESPONDING ar_rol_1 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_2[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs2.
    et_role_addition_simu-target_rfcdest = ar_rfcd2.
    LOOP AT ar_rol_2.
      MOVE-CORRESPONDING ar_rol_2 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_3[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs3.
    et_role_addition_simu-target_rfcdest = ar_rfcd3.
    LOOP AT ar_rol_3.
      MOVE-CORRESPONDING ar_rol_3 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_4[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs4.
    et_role_addition_simu-target_rfcdest = ar_rfcd4.
    LOOP AT ar_rol_4.
      MOVE-CORRESPONDING ar_rol_4 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.


ENDFORM.                    "

*---------------------------------------------------------------------*
*       FORM load_simulated_role_content                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_SIMU_ROLE_ADDITION                                         *
*  -->  ET_SIMU_ROLEAUTH                                              *
*  -->  ET_SIMU_ROLETCODE                                             *
*  -->  IT_FUNCTRAN_LOCAL                                             *
*  -->  IT_FAOBJ_LOCAL                                                *
*  -->  IT_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_simulated_role_content
TABLES   it_simu_role_addition STRUCTURE /psyng/sw_role_addition_simu
         et_simu_roleauth STRUCTURE /psyng/roleauth
         et_simu_roletcode STRUCTURE /psyng/roletcode
         it_functran_local STRUCTURE /psyng/functtran
         it_faobj_local STRUCTURE /psyng/faobj2
         it_rfcdes STRUCTURE rfcdes.
  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu
                                      WITH HEADER LINE,
  l_agr_name TYPE agr_name,
  lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_faobj TYPE TABLE OF /psyng/faobj2,
  lt_functtran TYPE TABLE OF /psyng/functtran,
  lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  l_rfcdes TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdes.
  RANGES : range_roles FOR l_agr_name.
  lt_unique_rfcs[] = it_simu_role_addition[].
  SORT lt_unique_rfcs BY source_rfcdest.
  DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs
                             COMPARING source_rfcdest.


*  LOOP AT lt_unique_rfcs.

  LOOP AT it_simu_role_addition.
    REFRESH : range_roles.
    MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
    APPEND range_roles.
*    ENDLOOP.
    IF it_simu_role_addition-source_rfcdest IS INITIAL OR
       it_simu_role_addition-source_rfcdest = 'LOCAL' OR
       it_simu_role_addition-source_rfcdest = l_rfcdes.
*--Get list of roles matching range
      CALL FUNCTION '/PSYNG/SW_102'
           TABLES
                it_roles_range = range_roles
                et_roles       = lt_role_names.
      LOOP AT lt_role_names.
*--Load local role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
        REFRESH : lt_roleauth,lt_roletcode.
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
             EXPORTING
                  agr_name       = lt_role_names-agr_name
                  bname          = '000000000000'
             TABLES
                  roleauth       = lt_roleauth
                  roletcode      = lt_roletcode
                  functtran      = lt_functtran
                  faobj          = lt_faobj
             EXCEPTIONS
                  role_not_found = 1
                  OTHERS         = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Update the destination RFCDEST
*        LOOP AT it_simu_role_addition
*        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
*          REFRESH : range_roles.
*          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
*          APPEND range_roles.
        READ TABLE it_rfcdes
        WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
        IF sy-subrc <> 0 AND
        (
          it_simu_role_addition-target_rfcdest = 'LOCAL' OR
          it_simu_role_addition-target_rfcdest = l_rfcdes OR
          it_simu_role_addition-target_rfcdest = ' ' ).
          it_rfcdes-rfcoptions = l_rfcdes.
        ENDIF.
        lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
        lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
        MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.
*        ENDLOOP.

        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
*        APPEND LINES OF lt_roleauth TO et_simu_roleauth.
        ENDLOOP.
        REFRESH lt_roleauth.

        LOOP AT lt_roletcode.
          MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
          APPEND et_simu_roletcode.
        ENDLOOP.
        REFRESH lt_roletcode.

      ENDLOOP.

    ELSE.
*--Get list of roles matching range
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
      CALL FUNCTION '/PSYNG/SW_102'
        DESTINATION it_simu_role_addition-source_rfcdest
        TABLES
          it_roles_range       = range_roles
          et_roles             = lt_role_names. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      LOOP AT lt_role_names.
*--Load remote role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
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
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
        DESTINATION it_simu_role_addition-source_rfcdest
           EXPORTING
                agr_name  = lt_role_names-agr_name
                bname     = '000000000000'
           TABLES
                roleauth  = lt_roleauth
                roletcode = lt_roletcode
                functtran = lt_functtran
                faobj     = lt_faobj
           EXCEPTIONS
                role_not_found = 1
                OTHERS         = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
*--Update the destination RFCDEST
*        LOOP AT it_simu_role_addition
*        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
*          REFRESH : range_roles.
*          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
*          APPEND range_roles.
        READ TABLE it_rfcdes
        WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
        IF sy-subrc <> 0 AND
        (
          it_simu_role_addition-target_rfcdest = 'LOCAL' OR
          it_simu_role_addition-target_rfcdest = l_rfcdes OR
          it_simu_role_addition-target_rfcdest = ' ' ).
          it_rfcdes-rfcoptions = l_rfcdes.
        ENDIF.

        lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
        lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
*--B8106 - If the range contains a composite role, it's possible
*          auth and tcode tables contain roles not in that range
        MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE
        agr_name <> ''.
*        agr_name IN range_roles  .
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE
        agr_name <> ''.
*        agr_name IN range_roles.
*        ENDLOOP.

        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
        ENDLOOP.

        REFRESH lt_roleauth.
        LOOP AT lt_roletcode.
          MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
          APPEND et_simu_roletcode.
        ENDLOOP.
        REFRESH lt_roletcode.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " load_simulated_role_content
*&---------------------------------------------------------------------*
*&      Form  set_print_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LINE_COUNT  text
*----------------------------------------------------------------------*
FORM set_print_param USING    p_line_count.

  p_line_count = p_line_count + 25 .
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
       EXPORTING
            line_count = p_line_count.
ENDFORM.                    " set_print_param

*&---------------------------------------------------------------------*
*&      Form  get_roles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count.
  DATA : lt_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_assnroles TYPE TABLE OF agr_users WITH HEADER LINE,
         l_numb TYPE i,
         l_total_num TYPE i.
  RANGES: idatseltab FOR sy-datum.

  PERFORM rfc_validations.
  CHECK gf_invalid_rfc  IS INITIAL.
  if ronlyrem is initial.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = role
              it_ba             = rba.
    ADD l_numb TO l_total_num.
  endif.
  LOOP AT gt_rfcdest.
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
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION gt_rfcdest-rfcdest
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = role
              it_ba             = rba.  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ADD l_numb TO l_total_num.
  ENDLOOP.

  MESSAGE i002 WITH 'Number of roles(s) will be analyzed : '
  l_total_num.

ENDFORM.                    " get_roles_count
*&---------------------------------------------------------------------*
*&      Form  validate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_other_fields.

  DATA : l_vrsio TYPE /psyng/sodvrsio,
         l_rfcdest TYPE rfcdes-rfcdest,
         lt_roles TYPE TABLE OF /psyng/bc_agr_name,
         ls_rfcdest TYPE /psyng/sw_sel_opts_rfcdest,
         l_rfcdest_local TYPE rfcdes-rfcdest,
                             lt_excluding TYPE  slis_t_extab,
         ls_excluding TYPE slis_extab,
         l_repid          LIKE sy-repid,
         lt_fcat          TYPE slis_t_fieldcat_alv,
         ls_fcat          LIKE LINE OF lt_fcat,
         l_exit.

  DATA : BEGIN OF lt_rfc_roles OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
         agr_name(30) TYPE c,
         END OF lt_rfc_roles.

  DEFINE append_roles.
    if &1 is initial.
      &1 = 'LOCAL'.
    endif.
    lt_rfc_roles-rfcdest = &1.
    lt_rfc_roles-agr_name = &2.
    append lt_rfc_roles.
    clear gt_rfcdest-rfcdest.
  END-OF-DEFINITION.
*--RFC
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.

*--Validation of SOD version
  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  IF sy-subrc NE 0.
    MESSAGE i135 WITH 'SOD Version does not exist.'(195).
    LEAVE LIST-PROCESSING.
  ENDIF.

*--Validation of Add role by Simulation
  IF bysimu = 'X'.
*-- Validate Source RFC
    IF NOT ar_rol_1[] IS INITIAL.
      IF NOT ar_rfcs1 = '' AND
         NOT ar_rfcs1 = 'LOCAL' AND
         NOT ar_rfcs1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs1.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            append_roles gt_rfcdest-rfcdest ar_rol_1-low.

          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs1.
        ENDIF.

      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_1
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          append_roles gt_rfcdest-rfcdest ar_rol_1-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd1 = '' AND
        NOT ar_rfcd1 = 'LOCAL' AND
        NOT ar_rfcd1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd1.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd1.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_2[] IS INITIAL.
      IF NOT ar_rfcs2 = '' AND
         NOT ar_rfcs2 = 'LOCAL' AND
         NOT ar_rfcs2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs2.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_2-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs2.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_2
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest ar_rol_2-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd2 = '' AND
        NOT ar_rfcd2 = 'LOCAL' AND
        NOT ar_rfcd2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd2.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd2.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_3[] IS INITIAL.
      IF NOT ar_rfcs3 = '' AND
         NOT ar_rfcs3 = 'LOCAL' AND
         NOT ar_rfcs3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs3.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_3-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs3.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_3
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest ar_rol_3-low..
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd3 = '' AND
        NOT ar_rfcd3 = 'LOCAL' AND
        NOT ar_rfcd3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd3.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd3.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_4[] IS INITIAL.
      IF NOT ar_rfcs4 = '' AND
         NOT ar_rfcs4 = 'LOCAL' AND
         NOT ar_rfcs4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs4.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_4-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs4.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_4
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest ar_rol_4-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd4 = '' AND
      NOT ar_rfcd4 = 'LOCAL' AND
      NOT ar_rfcd4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd4.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd4.
        ENDIF.
      ENDIF.
    ENDIF.



    IF NOT lt_rfc_roles[] IS INITIAL.

*-- Show Popup
      l_repid = sy-repid.
      ls_fcat-fieldname = 'RFCDEST'.
      ls_fcat-outputlen = '30'.
      ls_fcat-seltext_l = 'RFC Destination'.
      ls_fcat-reptext_ddic  = ls_fcat-seltext_l.

      APPEND ls_fcat TO lt_fcat.

      ls_fcat-fieldname = 'AGR_NAME'.
      ls_fcat-outputlen = '30'.
      ls_fcat-seltext_l = 'Simulated Entry'.
      ls_fcat-reptext_ddic  = ls_fcat-seltext_l.

      APPEND ls_fcat TO lt_fcat.


*--Exclude buttons that are not required
      ls_excluding-fcode = '&IC1'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '&ETA'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '&OUP'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '&ODN'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '%SC+'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '%SC'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '&ILT'.
      APPEND ls_excluding TO lt_excluding.
      ls_excluding-fcode = '&OL0'.
      APPEND ls_excluding TO lt_excluding.

      CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
           EXPORTING
                i_title       = 'Simulated Entries validation'
                i_selection   = ''
                i_zebra       = 'X'
                i_tabname     = 'LT_RFC_ROLES'
*              I_STRUCTURE_NAME = 'BAPIRET2'
                it_fieldcat   = lt_fcat
                it_excluding  = lt_excluding
           IMPORTING
                e_exit        = l_exit
           TABLES
                t_outtab      = lt_rfc_roles

           EXCEPTIONS
                program_error = 1
                OTHERS        = 2.
      IF sy-subrc <> 0.
        MESSAGE e010 WITH
        'Unable to show Simulated entries validation issues'.
      ENDIF.

      IF l_exit = 'X'.
        LEAVE LIST-PROCESSING.
      ELSE.

      ENDIF.
    ENDIF.
  ENDIF.

*-- Role Removal Simulation
  IF byrsimu = 'X'.
    IF NOT rr_rol_1[] IS INITIAL.
      IF NOT rr_rfc_1 = '' AND
         NOT rr_rfc_1 = 'LOCAL' AND
         NOT rr_rfc_1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_1.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
        ELSE.
*          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_1.
*HBHALLA(PN-16972)(13/12/25) (Deletes Removed roles list of rfc)
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_1
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT rr_rol_2[] IS INITIAL.
      IF NOT rr_rfc_2 = '' AND
         NOT rr_rfc_2 = 'LOCAL' AND
         NOT rr_rfc_2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_2.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.

          ENDIF.
*          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_2.
*HBHALLA(PN-16972)(13/12/25) (Deletes Removed roles list of rfc)
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_2
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_3[] IS INITIAL.
      IF NOT rr_rfc_3 = '' AND
         NOT rr_rfc_3 = 'LOCAL' AND
         NOT rr_rfc_3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_3.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
*          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_3.
*HBHALLA(PN-16972)(13/12/25) (Deletes Removed roles list of rfc)
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_3
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_4[] IS INITIAL.
      IF NOT rr_rfc_4 = '' AND
         NOT rr_rfc_4 = 'LOCAL' AND
         NOT rr_rfc_4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_4.
        IF sy-subrc = 0.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
*          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_4.
*HBHALLA(PN-16972)(13/12/25) (Deletes Removed roles list of rfc)
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_4
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " validate_other_fields
*&---------------------------------------------------------------------*
*&      Form  get_conflicts_from_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_conflicts_from_selection.
data : lt_conowner TYPE TABLE OF /psyng/conowner WITH HEADER LINE.
******  SELECT CLASS WRT AREA,Owner,Sensitivity,Mitigation**
  IF NOT pappa[]  IS INITIAL OR
     NOT cowner[] IS INITIAL OR
     NOT csens[]  IS INITIAL OR
     NOT cprmit[] IS INITIAL OR
     NOT proca[]  IS INITIAL OR
     NOT cowner[] IS INITIAL OR
     NOT s_risk[] IS INITIAL OR
     NOT spconfs[] IS INITIAL.
    SELECT      conid owner
    FROM       /psyng/conflict
    INTO TABLE it_conid
    WHERE vrsio   = sodvrsio
    AND conid     IN spconfs
    AND busarea   IN pappa
    AND subarea   IN proca
*    AND owner     IN cowner
    AND imp       IN csens
    AND contid    IN cprmit
    AND risk      IN s_risk.

    REFRESH : gt_conid.
*--Select conflict owners
    IF NOT cowner[] IS INITIAL and not it_conid[] is initial.
      SELECT * FROM /psyng/conowner INTO TABLE lt_conowner
      FOR ALL ENTRIES IN it_conid
      WHERE vrsio = sodvrsio AND
      conid = it_conid-conid AND
      owner IN cowner.
      LOOP AT it_conid.
        IF NOT it_conid-owner IN cowner.
          READ TABLE lt_conowner WITH KEY conid = it_conid-conid.
          IF sy-subrc <> 0.
            DELETE it_conid.
          ENDIF.
        ENDIF.
      ENDLOOP.
    ENDIF.


    LOOP AT it_conid.
      wa_conid-sign = 'I'.
      wa_conid-option = 'EQ'.
      wa_conid-low = it_conid-conid.
      APPEND wa_conid TO gt_conid.
    ENDLOOP.

    IF gt_conid[] IS INITIAL.
*--Selection of conflicts showed no conflicts
      MESSAGE i135 WITH 'No Conflict ID(s) match selection'(177).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSE.
    APPEND LINES OF spconfs TO gt_conid.
  ENDIF.

ENDFORM.                    " get_conflicts_from_selection
*&---------------------------------------------------------------------*
*&      Form  before_after_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------*
FORM summary_analysis_with_simu TABLES
  it_role_removal_simu   STRUCTURE  /psyng/sw_role_removal_simu
  it_role_addition_simu  STRUCTURE  /psyng/sw_role_addition_simu
  using
    i_bysimu             TYPE       FLAG
    i_byrsimu            TYPE       FLAG.
DATA :
  lt_routput_sum         TYPE TABLE OF /psyng/sw_out_routput,
  l_rfcdes               TYPE rfcdes,
  l_taskname             TYPE string,
  l_numroles             TYPE i,
  l_local_sod            TYPE flag,
  l_system_msg(100)      TYPE c,
  lt_role_removal_simu   TYPE TABLE OF /psyng/sw_role_removal_simu
                         WITH HEADER LINE,
  lt_conflict            TYPE TABLE OF  /psyng/conflict
                         WITH HEADER LINE,
  lt_confdet             TYPE TABLE OF  /psyng/confdet,
  lt_functtran      TYPE TABLE OF /psyng/functtran,
  lt_faobj             TYPE TABLE OF  /psyng/faobj2,
  lt_swsodorgm           TYPE TABLE OF  /psyng/swsodorgm,
  lt_tcodes            TYPE TABLE OF  /psyng/sw_par_tcode_output,
  lt_functran_no_enh     TYPE TABLE OF /psyng/functtran,
  lt_syscandt            TYPE TABLE OF /psyng/syscandt2
                         WITH HEADER LINE,
  lt_remote_roles        TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_remote_childroles   TYPE TABLE OF agr_agrs WITH HEADER LINE,
  lt_simu_roleauth       TYPE TABLE OF /psyng/roleauth
                         WITH HEADER LINE,
  lt_simu_roletcode      TYPE TABLE OF /psyng/roletcode
                         WITH HEADER LINE,
  lt_simu_roleauth_part  TYPE TABLE OF /psyng/roleauth
                         WITH HEADER LINE,
  lt_simu_roletcode_part TYPE TABLE OF /psyng/roletcode
                         WITH HEADER LINE,
  lt_roleauth            TYPE TABLE OF /psyng/userauth
                         WITH HEADER LINE,
  lt_roletcode           TYPE TABLE OF /psyng/usertcode
                         WITH HEADER LINE,
  lt_uniqueauths         TYPE TABLE OF /psyng/uniqueauths
                         WITH HEADER LINE,
  lt_itcd                TYPE SORTED TABLE OF typ_itcd
                         WITH UNIQUE KEY tcode rfcdest
                         WITH HEADER LINE,
  lt_itcd2               TYPE STANDARD TABLE OF typ_itcd,
  lt_simu_tcdaut         TYPE TABLE OF /psyng/psswtcdaut,
  lt_removed_roles       TYPE TABLE OF /psyng/sw_removed_roles_role
                         WITH HEADER LINE,
  ls_swconfig_bkgd_job   TYPE /psyng/swconfig,
  ls_line_count          TYPE i,
  lt_mitigations         TYPE TABLE OF /psyng/mitigation_assignment,
  lt_confdet_sys         TYPE TABLE OF /psyng/confdet,
  lt_con_sys             TYPE TABLE OF /psyng/conflict,
  lt_functtran_sys       TYPE TABLE OF /psyng/functtran,
  lt_faobj_sys           TYPE TABLE OF /psyng/faobj2,
  l_system               TYPE /psyng/rfcname,
  lt_conflict_sys        TYPE /psyng/swt_sys_filt_conflict,
  lt_rfc                 TYPE TABLE OF rfcdes WITH HEADER LINE,
  ls_ao_sys              TYPE /psyng/sw_sys_ao,
  ls_faobj_system        TYPE /psyng/sw_sys_faobj,
  lt_faobj_org type table of /psyng/faobj2.
Field-SYmbols : <sum> like line of gt_routput_sum.

  l_local_sod = 'X'.


*--Always load the local SOD Matrix so we can apply system filters
*--Load Local SOD Matrix
  lt_rfc[] = gt_remote_anal_rfc[].
  CALL FUNCTION '/PSYNG/SW_028'
       EXPORTING
            i_orgcheck         = orgchk
            i_vrsio            = sodvrsio
            i_enhance          = p_enhanc
            i_config_set       = cfgset
            i_orphan_functions = p_nabap " empty conflict is relevant
            IF_ANALYSIS        = 'X'
            i_org_field        = gf_org_field "AKUMAR OPL645
       IMPORTING
            et_faobj_sys       = gt_faobj_system
            et_swsodorgm_sys   = gt_ao_sys
       TABLES
            it_spconfs         = gt_conid
*            it_imp             = csens
*            it_risk            = s_risk
            et_conflict        = lt_conflict
            et_confdet         = lt_confdet
            et_functtran       = lt_functtran
            et_faobj           = lt_faobj
            et_swsodorgm       = lt_swsodorgm
            et_tcodes          = lt_tcodes
            et_functran_no_enh = lt_functran_no_enh
            it_rfcdest         = lt_rfc
            et_faobj_org       = lt_faobj_org. "AKUMAR OPL645
*  BOC UMITTAL PN6938 24/10/2024
*  Deleting conflicts which are blank.
    DELETE lt_confdet WHERE conid EQ space.
*  EOC UMITTAL PN6938 24/10/2024
  CLEAR l_local_sod. "we will use the loaded sod matrix on all
  "systems (including local to prevent
  "loading twice)

*--Apply the System filter for conflicts
*  Load, for each conflict, all relevant systems

  CONCATENATE sy-sysid sy-mandt INTO lt_rfc-rfcoptions.
  APPEND lt_rfc.

  CALL FUNCTION '/PSYNG/SW_124'
       EXPORTING
            if_conflict      = 'X'
            i_vrsio          = sodvrsio
       IMPORTING
            et_conflict_sys  = lt_conflict_sys[]
       TABLES
            it_conf_rfcdest  = lt_rfc
            it_conflicts     = lt_conflict
       EXCEPTIONS
            too_many_options = 1
            OTHERS           = 2.
  IF sy-subrc <> 0.
    MESSAGE e138 WITH
    'Applying Conflict filter to conflicts failed'.
  ENDIF.

  IF i_bysimu = 'X'.
*--SE3.1 - Load all simulated roles from their source system
    DATA : l_agr_name TYPE agr_name.
    RANGES : range_roles FOR l_agr_name.
    PERFORM load_simulated_role_content
     TABLES
       it_role_addition_simu
       lt_simu_roleauth
       lt_simu_roletcode
       lt_functtran
       lt_faobj
       gt_remote_anal_rfc.
  ENDIF.

*-- Before SOD analysis
*--Remote Role Analysis

  IF NOT gt_remote_anal_rfc[] IS INITIAL.

    LOOP AT gt_remote_anal_rfc INTO l_rfcdes.
      l_taskname = l_rfcdes-rfcdest.
      ADD 1 TO g_running_tasks.

*--Filter Functions by system
      l_system = l_rfcdes-rfcoptions.
      lt_functtran_sys[] = lt_functtran[].
*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_rfcdes-rfcoptions.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_rfcdes-rfcoptions.


      lt_faobj_sys[]     = lt_faobj[].
      lt_confdet_sys[]   = lt_confdet[].
      REFRESH : lt_con_sys.
      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = sodvrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Don't filter the conflict details, SW_036 will think the conflict
* only contains one function
*           IT_CONFDET          = lt_confdet_sys.
      LOOP AT lt_conflict.
        READ TABLE lt_conflict_sys WITH TABLE KEY
          conid = lt_conflict-conid rfcdest = l_rfcdes-rfcoptions
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          APPEND lt_conflict TO lt_con_sys.
        ELSE.
          DELETE lt_confdet_sys WHERE conid = lt_conflict-conid.
        ENDIF.
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
      CALL FUNCTION '/PSYNG/SW_036'
         STARTING NEW TASK l_taskname
         DESTINATION l_rfcdes-rfcdest
         PERFORMING get_remote_results ON END OF TASK
       EXPORTING
         vrsio             = sodvrsio
         org_check         = orgchk
         enh_fm            = p_enhanc
         i_rchdatf         = rchdatf
         i_rchdatt         = rchdatt
         xstb_fm           = 'X'
         i_local_sod       = l_local_sod
         i_shonosod        = shonosod
         i_composite_roles = comprol
         i_single_roles    = singrol
         i_shomit          = xmc
         i_assigned_roles  = asign_r
         i_cfg_set         = cfgset
         i_org_field       = gf_org_field "AKUMAR OPL645
       TABLES
         it_roles          = role
         it_role_ba        = rba
         it_confs          = gt_conid
*         it_sens           = csens
        it_conflict        = lt_con_sys
        it_confdet         = lt_confdet_sys
        it_functtran       = lt_functtran_sys
        it_faobj           = lt_faobj_sys
        it_swsodorgm       = ls_ao_sys-swsodorgm[]
        it_tcodes          = lt_tcodes
        it_functran_no_enh = lt_functran_no_enh
        it_risk            = s_risk
        it_orglvl          = orglvl
        ot_routput_sum     = lt_routput_sum
        et_mitigations     = lt_mitigations "#EC SAST_CI_GEN_CHECK
        it_faobj_org       = lt_faobj_org. "AKUMAR OPL645
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDLOOP.
  ENDIF.
  IF ronlyrem IS INITIAL.
    DATA : l_local_rfc TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.

*--Filter Functions by system
    l_system = l_local_rfc.
    lt_functtran_sys[] = lt_functtran[].
    lt_faobj_sys[]     = lt_faobj[].
    lt_confdet_sys[]   = lt_confdet[].
    REFRESH : lt_con_sys[].
    CALL FUNCTION '/PSYNG/SW_124'
         EXPORTING
              if_functions  = 'X'
              i_system      = l_system
              i_application = 'SAP'
              i_vrsio       = sodvrsio
         TABLES
              it_functtran  = lt_functtran_sys
              it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Don't filter the conflict details, SW_036 will think the conflict
* only contains one function
*           IT_CONFDET          = lt_confdet_sys.
    LOOP AT lt_conflict.
      READ TABLE lt_conflict_sys WITH TABLE KEY
        conid = lt_conflict-conid rfcdest = l_local_rfc
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND lt_conflict TO lt_con_sys.
      ELSE.
        DELETE lt_confdet_sys WHERE conid = lt_conflict-conid.
      ENDIF.
    ENDLOOP.


    CALL FUNCTION '/PSYNG/SW_036'
         EXPORTING
              vrsio              = sodvrsio
              org_check          = orgchk
              enh_fm             = p_enhanc
              i_rchdatf          = rchdatf
              i_rchdatt          = rchdatt
              xstb_fm            = 'X'
              i_local_sod        = l_local_sod
              i_shonosod         = shonosod
              i_composite_roles  = comprol
              i_single_roles     = singrol
              i_shomit           = xmc
              i_assigned_roles   = asign_r
              I_NABAP            = p_nabap
              i_cfg_set         = cfgset
              i_org_field       = gf_org_field "AKUMAR OPL645
         IMPORTING
              o_totalroles       = l_numroles
         TABLES
              it_roles           = role
              it_role_ba         = rba
              it_roles_simu      = simurols
              it_confs           = gt_conid
*              it_sens            = csens
              it_conflict        = lt_con_sys
              it_confdet         = lt_confdet_sys
              it_functtran       = lt_functtran_sys
              it_faobj           = lt_faobj_sys
              it_swsodorgm       = lt_swsodorgm
              it_tcodes          = lt_tcodes
              it_functran_no_enh = lt_functran_no_enh
              it_risk            = s_risk
              IT_APPL            = s_appl " New
              IT_SYSID           = s_sys  " New
              it_orglvl          = orglvl
              ot_routput_sum     = lt_routput_sum
              et_mitigations     = lt_mitigations
              it_faobj_org       = lt_faobj_org. "AKUMAR OPL645

    APPEND LINES OF lt_routput_sum TO gt_routput_sum_before.
    APPEND LINES OF lt_mitigations TO gt_mitigations.

    FREE : lt_routput_sum,lt_mitigations.
  ENDIF.


  WAIT UNTIL g_running_tasks = 0.

  APPEND LINES OF gt_routput_sum  TO gt_routput_sum_before.
  REFRESH gt_routput_sum.

  LOOP AT gt_return.
    MESSAGE  ID   gt_return-id
             TYPE gt_return-type
             NUMBER  gt_return-number
             WITH
             gt_return-message.
  ENDLOOP.

if i_bysimu = 'X' or i_byrsimu = 'X'.
*-- After Simulation
*--Remote Role Analysis
  CLEAR : trolecount, l_numroles.
  IF NOT gt_remote_anal_rfc[] IS INITIAL.

    LOOP AT gt_remote_anal_rfc INTO l_rfcdes.
      l_taskname = l_rfcdes-rfcdest.
      ADD 1 TO g_running_tasks.

      FREE : lt_role_removal_simu.
      LOOP AT it_role_removal_simu WHERE rfcdest = l_rfcdes-rfcdest.
        APPEND it_role_removal_simu TO lt_role_removal_simu.
      ENDLOOP.
      FREE : lt_removed_roles.

      FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
      LOOP AT lt_simu_roleauth WHERE rfcdest =  l_rfcdes-rfcoptions.
        APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
      ENDLOOP.

      LOOP AT lt_simu_roletcode WHERE rfcdest = l_rfcdes-rfcoptions.
        APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
      ENDLOOP.

*--Filter Functions by system
      l_system = l_rfcdes-rfcoptions.
      lt_functtran_sys[] = lt_functtran[].
*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_rfcdes-rfcoptions.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_rfcdes-rfcoptions.

      lt_confdet_sys[]   = lt_confdet[].
      REFRESH : lt_con_sys[].
      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = sodvrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Don't filter the conflict details, SW_036 will think the conflict
* only contains one function
*           IT_CONFDET          = lt_confdet_sys.
      LOOP AT lt_conflict.
        READ TABLE lt_conflict_sys WITH TABLE KEY
          conid = lt_conflict-conid rfcdest = l_rfcdes-rfcoptions
         TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          APPEND lt_conflict TO lt_con_sys.
        ELSE.
          DELETE lt_confdet_sys WHERE conid = lt_conflict-conid.
        ENDIF.
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
*Begin of Addition:HBHALLA (PN-16972) (13/12/25)
    FREE : lt_role_removal_simu.
    LOOP AT it_role_removal_simu WHERE rfcdest = l_rfcdes-rfcdest.
      APPEND it_role_removal_simu TO lt_role_removal_simu.
    ENDLOOP.
*End of Addition:HBHALLA (PN-16972) (13/12/25)
      CALL FUNCTION '/PSYNG/SW_036'
         STARTING NEW TASK l_taskname
         DESTINATION l_rfcdes-rfcdest
         PERFORMING get_remote_results ON END OF TASK
       EXPORTING
         vrsio                = sodvrsio
         org_check            = orgchk
         enh_fm               = p_enhanc
         i_rchdatf            = rchdatf
         i_rchdatt            = rchdatt
         xstb_fm              = 'X'
         i_local_sod          = l_local_sod
         i_shonosod           = shonosod
         i_composite_roles    = comprol
         i_single_roles       = singrol
         i_shomit             = xmc
         i_assigned_roles     = asign_r
         i_cfg_set            = cfgset
         i_org_field       = gf_org_field "AKUMAR OPL645
       TABLES
         it_roles             = role
         it_role_ba           = rba
         it_confs             = gt_conid
*         it_sens              = csens
         it_conflict          = lt_con_sys
         it_confdet           = lt_confdet_sys
         it_functtran         = lt_functtran_sys
         it_faobj             = lt_faobj_sys
         it_swsodorgm         = ls_ao_sys-swsodorgm[]
         it_tcodes            = lt_tcodes
         it_functran_no_enh   = lt_functran_no_enh
         it_simurole_auth     = lt_simu_roleauth_part
         it_simurole_tcode    = lt_simu_roletcode_part
         it_risk              = s_risk
         it_orglvl            = orglvl
         ot_routput_sum       = lt_routput_sum
         et_mitigations       = lt_mitigations
*--Role Removal Simulation
         it_simu_role_removal = lt_role_removal_simu
         et_simu_removed_roles = lt_removed_roles
         it_faobj_org       = lt_faobj_org. "AKUMAR OPL645
         "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDLOOP.
  ENDIF.
  IF ronlyrem IS INITIAL.
*    DATA : l_local_rfc TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
    FREE : lt_role_removal_simu.
    LOOP AT it_role_removal_simu WHERE rfcdest = 'LOCAL' OR
                                       rfcdest = '' OR
                                       rfcdest = l_local_rfc.
      APPEND it_role_removal_simu TO lt_role_removal_simu.
    ENDLOOP.

    FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
    LOOP AT lt_simu_roleauth WHERE rfcdest = l_local_rfc.
      APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
    ENDLOOP.

    LOOP AT lt_simu_roletcode WHERE rfcdest = l_local_rfc.
      APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
    ENDLOOP.
*--Filter Functions by system
    l_system = l_local_rfc.
    lt_functtran_sys[] = lt_functtran[].
    lt_faobj_sys[]     = lt_faobj[].
    lt_confdet_sys[]   = lt_confdet[].
    REFRESH : lt_con_sys.
    CALL FUNCTION '/PSYNG/SW_124'
         EXPORTING
              if_functions  = 'X'
              i_system      = l_system
              i_application = 'SAP'
              i_vrsio       = sodvrsio
         TABLES
              it_functtran  = lt_functtran_sys
              it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Don't filter the conflict details, SW_036 will think the conflict
* only contains one function
*           IT_CONFDET          = lt_confdet_sys.
    LOOP AT lt_conflict.
      READ TABLE lt_conflict_sys WITH TABLE KEY
        conid = lt_conflict-conid rfcdest = l_local_rfc
TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND lt_conflict TO lt_con_sys.
      ELSE.
        DELETE lt_confdet_sys WHERE conid = lt_conflict-conid.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_036'
         EXPORTING
          vrsio               = sodvrsio
          org_check           = orgchk
          enh_fm              = p_enhanc
          i_rchdatf           = rchdatf
          i_rchdatt           = rchdatt
          xstb_fm             = 'X'
          i_local_sod         = l_local_sod
          i_shonosod          = shonosod
          i_composite_roles   = comprol
          i_single_roles      = singrol
          i_shomit            = xmc
          i_assigned_roles    = asign_r
          i_cfg_set           = cfgset
          i_org_field       = gf_org_field "AKUMAR OPL645
         IMPORTING
              o_totalroles    = l_numroles
         TABLES
              it_roles        = role
              it_role_ba      = rba
              it_roles_simu   = simurols
              it_confs        = gt_conid
*              it_sens         = csens
              it_conflict     = lt_con_sys
              it_confdet      = lt_confdet_sys
              it_functtran    = lt_functtran_sys
              it_faobj        = lt_faobj_sys
              it_swsodorgm    = lt_swsodorgm
              it_tcodes       = lt_tcodes
              it_functran_no_enh = lt_functran_no_enh
              it_simurole_auth   = lt_simu_roleauth_part
              it_simurole_tcode  = lt_simu_roletcode_part
              it_risk         = s_risk
              it_orglvl       = orglvl
              ot_routput_sum  = lt_routput_sum
              et_mitigations  = lt_mitigations
*      --Role Removal Simulation
             it_simu_role_removal	 = lt_role_removal_simu
             et_simu_removed_roles = lt_removed_roles
             it_faobj_org       = lt_faobj_org. "AKUMAR OPL645

    APPEND LINES OF lt_removed_roles TO gt_removed_roles.
    APPEND LINES OF lt_routput_sum TO gt_routput_sum_after.
    APPEND LINES OF lt_mitigations TO gt_mitigations.

    FREE : lt_routput_sum.
  ENDIF.

  WAIT UNTIL g_running_tasks = 0.

  APPEND LINES OF gt_routput_sum  TO gt_routput_sum_after.
  REFRESH gt_routput_sum.

  LOOP AT gt_return.
    MESSAGE  ID   gt_return-id
             TYPE gt_return-type
             NUMBER  gt_return-number
             WITH
             gt_return-message.
  ENDLOOP.
  SORT  gt_routput_sum_after  BY agr_name conid rfcdest.
  "HBHALLA(PN-18555)(27/03/26)
  ENDIF.
  ADD l_numroles TO trolecount.


  SORT  gt_routput_sum_before BY agr_name conid rfcdest.
  "HBHALLA(PN-18555)(27/03/26)
*  Delete gt_routput_sum_after where simu <> 'X'.
  REFRESH : gt_routput_sum.

*--Determine the Before After checkboxes if this is a simulation
  if i_bysimu = 'X' or i_byrsimu = 'X'.
   LOOP AT gt_routput_sum_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_routput_sum_after TO ls_output.
    READ TABLE gt_routput_sum_before
    WITH KEY
    agr_name = gt_routput_sum_after-agr_name"HBHALLA(PN-18555)(27/03/26)
    conid = gt_routput_sum_after-conid
    rfcdest = gt_routput_sum_after-rfcdest"HBHALLA(PN-16972)(13/12/25)
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*  -onflict is added
      ls_output-simu_after = 'X'.
      CLEAR ls_output-simu_before.
    ELSE.
*  -onflict is unchanged
      ls_output-simu_after = 'X'.
      ls_output-simu_before = 'X'.
    ENDIF.
    IF ls_output-simu_after <> ls_output-simu_before.
      ls_output-simu = 'X'.
    ELSE.
      CLEAR ls_output-simu.
    ENDIF.
    APPEND ls_output TO gt_routput_sum.
   ENDLOOP.

  LOOP AT gt_routput_sum_before.
   CLEAR ls_output.
   MOVE-CORRESPONDING gt_routput_sum_before TO ls_output.
   READ TABLE gt_routput_sum_after
   WITH KEY
   agr_name = gt_routput_sum_before-agr_name"HBHALLA(PN-18555)(27/03/26)
   conid = gt_routput_sum_before-conid
   rfcdest = gt_routput_sum_before-rfcdest"HBHALLA(PN-16972)(13/12/25)
   BINARY SEARCH TRANSPORTING NO FIELDS.
   IF sy-subrc <> 0.
* -Conflict is removed
     ls_output-simu_before = 'X'.
     CLEAR ls_output-simu_after.
     IF ls_output-simu_after <> ls_output-simu_before.
       ls_output-simu = 'X'.
     ELSE.
       CLEAR ls_output-simu.
     ENDIF.
     APPEND ls_output TO gt_routput_sum.
   ENDIF.
  ENDLOOP.
  else.
*--After simulation, all conflicts are gone
    gt_routput_sum_before-simu_before = 'X'.
    modify gt_routput_sum_before transporting simu_before
    where simu_before = ''.
    gt_routput_sum[] =  gt_routput_sum_before[].

    refresh gt_routput_sum_before.
  endif.


  DATA : ls_config TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam.
*--Check if a SW_REM_ROLE_FILTER is configured
  se_config_param 'SW_REM_ROLE_FILTER' ls_config-value.
  IF  NOT ls_config-value IS INITIAL .
    ls_fmname = ls_config-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0 .
      CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(12/12/24)
           TABLES
                t_results = gt_routput_sum
           EXCEPTIONS
                OTHERS    = 1.
      IF sy-subrc <> 0.
        MESSAGE w113(/psyng/sw) WITH
        'SW_REM_ROLE_FILTER : error executing configured FM :'(e03)
        ls_fmname.

      ENDIF.
    ELSE.
      MESSAGE w113(/psyng/sw) WITH
      'SW_REM_ROLE_FILTER : configured FM does not exist '(e04)
      ls_fmname .
    ENDIF.
  ENDIF.
  LOOP AT gt_routput_sum ASSIGNING <sum>.
      IF <sum>-simu_after <> <sum>-simu_before.
         <sum>-simu = 'X'.
      ELSE.
        CLEAR <sum>-simu.
      ENDIF.
*--Update Scan Table
    IF ustb = 'X'.
      lt_syscandt-vrsio    = sodvrsio.
      lt_syscandt-agr_name = <sum>-agr_name.
      lt_syscandt-conid    = <sum>-conid.
      APPEND lt_syscandt.
    ENDIF.
    CLEAR routdet3.
    MOVE-CORRESPONDING <sum> TO routdet3.
    IF xmc = 'X'.
      IF <sum>-contid <> ''.
        READ TABLE gt_mitigations WITH KEY
          rfcdest  = <sum>-rfcdest
          agr_name = <sum>-agr_name
          conid    = <sum>-conid
          contid   = <sum>-contid.
        IF sy-subrc = 0.
          MOVE-CORRESPONDING gt_mitigations TO routdet3.
          routdet3-mit_icon = '@F8@'.
        ENDIF.
      ENDIF.
      IF <sum>-simu <> ''.
        READ TABLE gt_mitigations WITH KEY
          rfcdest  = <sum>-rfcdest
          agr_name = <sum>-child_agr
          conid    = <sum>-conid
          contid   = <sum>-contid.
        IF sy-subrc = 0.
          MOVE-CORRESPONDING gt_mitigations TO routdet3.
          routdet3-agr_name = <sum>-agr_name.
          routdet3-mit_icon = '@F8@'.
          routdet3-child_agr = gt_mitigations-agr_name.
        ENDIF.
      ENDIF.
    ENDIF.
    CASE routdet3-imp.
      WHEN 'CRITICAL'.
        routdet3-isort = '1'.
        color-col = '6'.   "Red
        color-int = '0'.   "Intensified
        color-inv = '1'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO routdet3-color_cell.
      WHEN 'HIGH'.
        routdet3-isort = '1'.
        color-col = '6'.   "Red
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO routdet3-color_cell.
      WHEN 'MEDIUM'.
        routdet3-isort = '2'.
        color-col = '6'.   "Red
        color-int = '0'.   "Un-Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO routdet3-color_cell.
      WHEN 'LOW'.
        routdet3-isort = '3'.
        color-col = '3'.   "Yellow
        color-int = '0'.   "Un-Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO routdet3-color_cell.
    ENDCASE.
    IF pcolor <> 'X'.   "if user doesn't want to see the conflicts
      CLEAR routdet3-color_line.   "highlighted in colors
      CLEAR routdet3-color_cell.
    ENDIF.
    IF p_hienhn = 'X'.
      IF routdet3-enhanced = 'X'.
        DELETE routdet3-color_cell
               WHERE fname = 'CONID'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        cc-fname  = 'TCODE'.
        APPEND cc TO routdet3-color_cell.
      ENDIF.
    ENDIF.
    APPEND routdet3.
  ENDLOOP.
  SORT routdet3.

*--Update Scan table
  IF ustb = 'X'.
    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
               ID 'Y&SW_ADMF' FIELD 'SUMMTAB'.
    IF sy-subrc NE 0.
      gf_st_missing_auth = 'X'.
    ELSE.
      CLEAR gf_st_missing_auth.

      DATA : nodelete TYPE flag.
      IF NOT spconfs[] IS INITIAL OR NOT
             csens[]    IS INITIAL.
        nodelete = 'X'.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_UPDATE_SYS_SCAN_INF2'
       EXPORTING
         nodelete       = nodelete
         vrsio          = sodvrsio
        TABLES
          syscandt       = lt_syscandt
          rfcdes         = gt_remote_anal_rfc.
    ENDIF.
  ENDIF.
  if ODT = 'X'.
    MESSAGE s208(00) WITH text-083.
    IF sy-batch EQ 'X'.
      se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.
      IF ls_swconfig_bkgd_job-value = 'N'.
        CLEAR g_repeat_hdr_bkgdjob.
        DESCRIBE TABLE routdet3  LINES ls_line_count.
        PERFORM set_print_param USING ls_line_count.
      ELSE.
        g_repeat_hdr_bkgdjob = 'X'.
      ENDIF.
    ENDIF.


*  build ALV catalog
    program = sy-repid.
    alv_layout-zebra = 'X'.
    alv_layout-colwidth_optimize = 'X'.
    MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.
    MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
         EXPORTING
              i_program_name     = program
              i_internal_tabname = 'ROUTDET3'
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
    wa_fieldcat_alv-hotspot = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        hotspot
                     WHERE
                        fieldname = 'CONID'.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'ISORT'.
*  delete the color columns
    DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_LINE'.
    DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_CELL'.
    DELETE i_fieldcat_alv WHERE fieldname = 'CHILD_AGR'.
*  no key fields
    wa_fieldcat_alv-key = ' '.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        key
                     WHERE
                        fieldname NE space.
*  **********************************************
*    When exporting to spreadsheet, checkboxes appear in the
*               incorrect column.  This can be fixed by setting the
*               'JUSTIFIED' flag.
    IF p_hienhn = 'X'.
*  if highlight enhanced ruleset is selected, add this field to the alv
      wa_fieldcat_alv-seltext_l      = text-157.
      wa_fieldcat_alv-seltext_m      = text-158.
      wa_fieldcat_alv-seltext_s      = text-158.
      wa_fieldcat_alv-reptext_ddic   = text-101.
      wa_fieldcat_alv-checkbox       = 'X'.
      wa_fieldcat_alv-just       = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                          checkbox
                          just
                       WHERE
                          fieldname = 'ENHANCED'.
    ELSE.
      DELETE i_fieldcat_alv WHERE fieldname = 'ENHANCED'.
    ENDIF.
    IF i_bysimu = 'X' OR i_byrsimu = 'X'.
      wa_fieldcat_alv-seltext_l = text-115.
      wa_fieldcat_alv-seltext_m = text-115.
      wa_fieldcat_alv-seltext_s = text-116.
      wa_fieldcat_alv-reptext_ddic = text-115.
      wa_fieldcat_alv-checkbox     = 'X'.
      wa_fieldcat_alv-just       = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                          checkbox
                          just
                       WHERE
                          fieldname = 'SIMU'.

      wa_fieldcat_alv-seltext_l    = text-117.
      wa_fieldcat_alv-seltext_m    = text-117.
      wa_fieldcat_alv-seltext_s    = text-117.
      wa_fieldcat_alv-reptext_ddic = text-117.
      wa_fieldcat_alv-checkbox     = 'X'.
      wa_fieldcat_alv-just         = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                          checkbox
                          just
                       WHERE
                          fieldname = 'SIMU_BEFORE'.

      wa_fieldcat_alv-seltext_l = text-118.
      wa_fieldcat_alv-seltext_m = text-118.
      wa_fieldcat_alv-seltext_s = text-118.
      wa_fieldcat_alv-reptext_ddic = text-118.
      wa_fieldcat_alv-checkbox     = 'X'.
      wa_fieldcat_alv-just       = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                          checkbox
                          just
                       WHERE
                          fieldname = 'SIMU_AFTER'.
    ELSE.
      DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
      DELETE i_fieldcat_alv WHERE fieldname = 'SIMU_BEFORE'.
      DELETE i_fieldcat_alv WHERE fieldname = 'SIMU_AFTER'.
    ENDIF.
    if p_nabap <> 'X'.
      DELETE i_fieldcat_alv WHERE fieldname = 'APPL'.
    endif.
*  **********************************************
*    When exporting to spreadsheet, checkboxes appear in the
*               incorrect column.  This can be fixed by setting the
*               'JUSTIFIED' flag.
    IF NOT remrfc[] IS INITIAL.
      CLEAR wa_fieldcat_alv-no_out  .
    ELSE.
      wa_fieldcat_alv-no_out     = 'X'.
    ENDIF.
    wa_fieldcat_alv-seltext_l = 'System - Client'(073).
    wa_fieldcat_alv-seltext_m = text-073.
    wa_fieldcat_alv-seltext_s = 'Sys-Cli'(074).
    wa_fieldcat_alv-reptext_ddic = text-073.
    wa_fieldcat_alv-checkbox     = ''.
    wa_fieldcat_alv-just         = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                        no_out
                     WHERE
                        fieldname = 'RFCDEST'.

*  --Hide mitigation fields when xmc <> 'X'
    IF xmc <> 'X'.
      wa_fieldcat_alv-no_out = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          no_out
                       WHERE
                             fieldname = 'CONTID'
                          OR fieldname = 'AUDITOR'
                          OR fieldname = 'FROM_DATE'
                          OR fieldname = 'TO_DATE'
                          OR fieldname = 'MIT_ICON'.
    ELSE.
      wa_fieldcat_alv-hotspot = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          hotspot
                       WHERE
                             fieldname = 'CONTID'.

      wa_fieldcat_alv-seltext_m = text-040.
      wa_fieldcat_alv-seltext_s = text-040.
      wa_fieldcat_alv-reptext_ddic = text-040.
      wa_fieldcat_alv-seltext_l = text-040.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                        seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                       WHERE
                          fieldname = 'TO_DATE'.


      wa_fieldcat_alv-seltext_l = text-h29.
      wa_fieldcat_alv-seltext_m = text-h30.
      wa_fieldcat_alv-seltext_s = text-h30.
      wa_fieldcat_alv-reptext_ddic = text-h30.
      wa_fieldcat_alv-icon    = 'X'.
      wa_fieldcat_alv-hotspot = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          reptext_ddic
                          icon
                          hotspot
                       WHERE
                          fieldname = 'MIT_ICON'.

    ENDIF.

    PERFORM build_role_sort_order  USING 'SUM'.
    MOVE text-037 TO alv_grid_titl.
*CLEAR : i_bysimu  ,
*          i_byrsimu , byrsimu, bysimu.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
          i_callback_top_of_page  = 'ROLE-TOP-OF-PAGE'
          it_sort                 = isort
          i_callback_program      = program
          i_callback_user_command = 'ROLE_DOUBLE_CLICK_ON_SUMRY'
          i_callback_pf_status_set = 'PF_STATUS_SUMMARY'

          is_layout               = alv_layout
          it_fieldcat             = i_fieldcat_alv
          i_save                  = 'A'
          is_variant              = ls_variant
     TABLES
          t_outtab                = routdet3
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  endif.

ENDFORM.                    " before_after_simulation
*&---------------------------------------------------------------------*
*&      Form  show_mit_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ROUTDET3  text
*----------------------------------------------------------------------*
FORM show_mit_details USING routdet3 LIKE routdet3.
  DATA : l_showuser TYPE flag,
          l_showgroup TYPE flag,
          l_showrole TYPE flag,
          lt_mitigations_show LIKE TABLE OF gt_mitigations WITH HEADER
 LINE.

  CLEAR : l_showuser,l_showgroup,l_showrole,lt_mitigations_show[].
  IF routdet3-simu = 'X'.
*-- Check for normal role
    LOOP AT gt_mitigations WHERE agr_name = routdet3-agr_name
                   AND conid  = routdet3-conid.

      MOVE-CORRESPONDING gt_mitigations TO lt_mitigations_show.
      APPEND lt_mitigations_show.

      CASE gt_mitigations-type.
        WHEN '1'.
          l_showuser = 'X'.
        WHEN '2'.
          l_showgroup = 'X'.
        WHEN '4'.
          l_showrole = 'X'.
      ENDCASE.
    ENDLOOP.
    IF sy-subrc NE 0.
*-- Check for Simulated roles
      LOOP AT gt_mitigations WHERE agr_name = routdet3-child_agr
                     AND conid  = routdet3-conid.

        MOVE-CORRESPONDING gt_mitigations TO lt_mitigations_show.
        APPEND lt_mitigations_show.

        CASE gt_mitigations-type.
          WHEN '1'.
            l_showuser = 'X'.
          WHEN '2'.
            l_showgroup = 'X'.
          WHEN '4'.
            l_showrole = 'X'.
        ENDCASE.
      ENDLOOP.
    ENDIF.
  ELSE.
    LOOP AT gt_mitigations WHERE agr_name = routdet3-agr_name
                     AND conid  = routdet3-conid.

      MOVE-CORRESPONDING gt_mitigations TO lt_mitigations_show.
      APPEND lt_mitigations_show.

      CASE gt_mitigations-type.
        WHEN '1'.
          l_showuser = 'X'.
        WHEN '2'.
          l_showgroup = 'X'.
        WHEN '4'.
          l_showrole = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDIF.

  CHECK sy-subrc = 0.
  CALL FUNCTION '/PSYNG/SW_076'
       EXPORTING
            if_display    = 'X'
            if_show_class = l_showgroup
            if_show_role  = l_showrole
       TABLES
            it_mcuser     = lt_mitigations_show.

ENDFORM.                    " show_mit_details
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

  CLEAR gf_invalid_rfc.
  APPEND LINES OF remrfc TO r_rfcs.
  r_rfcs-sign   = 'I'.
  r_rfcs-option = 'EQ'.
*--Role Simulation Destinations
  r_rfcs-low = ar_rfcd1.
  APPEND r_rfcs.
  r_rfcs-low    = ar_rfcd2.
  APPEND r_rfcs.
  r_rfcs-low   = ar_rfcd3.
  APPEND r_rfcs.
  r_rfcs-low    = ar_rfcd4.
  APPEND r_rfcs.
  r_rfcs-low    = ar_rfcs1.
  APPEND r_rfcs.
  r_rfcs-low    = ar_rfcs2.
  APPEND r_rfcs.
  r_rfcs-low    = ar_rfcs3.
  APPEND r_rfcs.
  r_rfcs-low   = ar_rfcs4.
  APPEND r_rfcs.
*--Role Removal  Simulation Destinations
  r_rfcs-low    = rr_rfc_1.
  APPEND r_rfcs.
  r_rfcs-low    = rr_rfc_2.
  APPEND r_rfcs.
  r_rfcs-low    = rr_rfc_3.
  APPEND r_rfcs.

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
    gf_invalid_rfc = 'X'.
  ENDIF.

  FREE : gt_rfcdest.
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

  FREE : gt_remote_anal_rfc.
  PERFORM load_role_rfc
              TABLES
                 remrfc
                 gt_remote_anal_rfc.


ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*      -->I_DELETE : if not 0, delete the parameter
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  i_delete type sy-subrc.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.
  if i_delete <> 0.
    delete lt_param where parid = '/PSYNG/VRSIO'.
  endif.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
     EXPORTING
          username   = l_uname
          parameterx = ls_paramx
     TABLES
          parameter  = lt_param
          return     = lt_return.

ENDFORM.                    " set_default_sodversion


FORM selscr_info_header.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_exedate        TYPE char10,
        l_exetime(8)     TYPE c,
        l_systemid       TYPE /psyng/sysid.

*--Header
  wa-typ = text-200.
  wa-info = text-201.
  APPEND wa TO header.

*--User Date & System
  WRITE sy-datum TO l_exedate.
  wa-typ = 'S'.
  wa-key = text-202.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user"sy-uname C0700
   text-203 l_exedate l_exetime text-204 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.

ENDFORM.
