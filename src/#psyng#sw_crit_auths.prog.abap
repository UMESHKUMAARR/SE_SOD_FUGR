* Report  /PSYNG/SW_CRIT_AUTHS                                         *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT  /psyng/sw_crit_auths MESSAGE-ID /psyng/sw LINE-SIZE 195.
CONSTANTS: max_wp TYPE i VALUE '4'.
TABLES: usr02,agr_define,/psyng/ex_caobj_lock.
INCLUDE /psyng/sw_113.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/sw_125.
INCLUDE /psyng/sw_crit_auths_top.


DATA:g_dynnr        TYPE sy-dynnr,
gf_dflt_enhance_matrix TYPE flag,
gt_map_tcode_screen TYPE TABLE OF /psyng/tcode_screen WITH
HEADER LINE.


SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-005.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: pbname   FOR usr02-bname,
                s_class  FOR usr02-class,
                s_comp   FOR output-company,
                s_depart FOR output-department.
SELECT-OPTIONS: s_cuid   FOR  /psyng/sw_uinfo-central_uid MODIF ID cus,
                s_role   FOR agr_define-agr_name,
                s_prof   FOR  ust04-profile .

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: SKIP 1.
PARAMETERS: xmc      AS CHECKBOX DEFAULT ' ',"show mitigating controls
            shonoca  AS CHECKBOX DEFAULT ' ', "show users w/o conflicts
            showcomp AS CHECKBOX DEFAULT ' ' USER-COMMAND showcomp,
            showpcom AS CHECKBOX DEFAULT ' ' MODIF ID out,
            erroles  AS CHECKBOX DEFAULT ' ' USER-COMMAND er1,
            excl_er  AS CHECKBOX DEFAULT ' ' USER-COMMAND er2.
*--Dynamic Enhancement
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 3(27) text-168 FOR FIELD p_enhanc
                                   MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 34(45) text-169 FOR FIELD p_hienhn
                                   MODIF ID exe.
SELECTION-SCREEN END OF LINE.



SELECTION-SCREEN: SKIP 1.
PARAMETERS : sodvrsio LIKE /psyng/conflict-vrsio MEMORY ID /psyng/vrsio.
SELECT-OPTIONS: paudid FOR /psyng/swaudc2-swaudid,
                s_imp FOR /psyng/swaudhdr-imp,
                s_owner FOR /psyng/swaudhdr-owner,
                s_barea FOR /psyng/swaudhdr-busarea.

SELECTION-SCREEN: END OF BLOCK exe.
*--Cross System/Remote
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) rem_but
  USER-COMMAND rem_but .
SELECTION-SCREEN COMMENT 16(40) text-121.
PARAMETERS : p_abap AS CHECKBOX USER-COMMAND se DEFAULT 'X'
                                           MODIF ID rem.

"RFC destination for remote analysis
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN : POSITION 4.
PARAMETERS: onlyrem  AS CHECKBOX USER-COMMAND remo
                                 MODIF ID rem.
SELECTION-SCREEN COMMENT 7(35) text-122 FOR FIELD onlyrem
                                          MODIF ID rem.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.

PARAMETERS p_nabap AS CHECKBOX USER-COMMAND en
                                   MODIF ID rem.
SELECT-OPTIONS: s_appl FOR /psyng/ex_caobj_lock-appl
MATCHCODE OBJECT /psyng/ex_application
MODIF ID rem.
SELECT-OPTIONS: s_system FOR /psyng/ex_caobj_lock-sysid
MATCHCODE OBJECT /psyng/ex_system
MODIF ID rem.
SELECTION-SCREEN: END OF BLOCK rem_o.

*--Simulation Block
SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME.
SELECTION-SCREEN PUSHBUTTON  01(6) simu_but USER-COMMAND simu_but.
SELECTION-SCREEN COMMENT 16(50) text-b06 .
SELECTION-SCREEN INCLUDE BLOCKS b_sim.
SELECTION-SCREEN: END OF BLOCK sim_o.



SELECTION-SCREEN: BEGIN OF BLOCK out WITH FRAME TITLE text-009.
SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS: sum RADIOBUTTON GROUP out1 DEFAULT 'X' USER-COMMAND a.
SELECTION-SCREEN: COMMENT 4(30) text-054.

SELECTION-SCREEN: POSITION 35.
PARAMETERS: det RADIOBUTTON GROUP out1.              "Detailed output
SELECTION-SCREEN: COMMENT 37(30) text-055.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK out.


*SELECTION-SCREEN: BEGIN OF BLOCK test WITH FRAME TITLE text-056.
*PARAMETERS: fm_old RADIOBUTTON GROUP fm.
*PARAMETERS: fm_new RADIOBUTTON GROUP fm.
*SELECTION-SCREEN: END OF BLOCK test.


SELECTION-SCREEN: BEGIN OF BLOCK pblk WITH FRAME TITLE text-094.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0'.

SELECTION-SCREEN: COMMENT 3(65) text-110.
SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : defgrp TYPE flag  RADIOBUTTON GROUP ppro DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(27) text-111 FOR FIELD defgrp.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : specgrp TYPE flag  RADIOBUTTON GROUP ppro.
SELECTION-SCREEN: COMMENT 3(27) text-112 FOR FIELD specgrp.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pgroup TYPE rzlli_apcl. "server group
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS : specsrv TYPE flag  RADIOBUTTON GROUP ppro.
SELECTION-SCREEN: COMMENT 3(27) text-113 FOR FIELD specsrv.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pserver LIKE msxxlist-name. "server name (40 chars in 4.7)
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  30(20) text-114 USER-COMMAND gpsv.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:SKIP 1 .


PARAMETERS:ustb AS CHECKBOX DEFAULT ' '. "Update Scan table

PARAMETERS: odt AS CHECKBOX DEFAULT ' '. "output data to screen
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o01.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o02.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o03.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o04.
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK pblk.

************************************
***********************************
SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-t11.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t06.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t07.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-t09 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-t10 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK blk3.
*************************************
*--Hidden parameters
PARAMETERS :
*--  RFC Destination to read SOD Matrix from
*-- This Parameter is only for Auth Help call
             p_sodrfc TYPE rfcdest NO-DISPLAY.


AT SELECTION-SCREEN OUTPUT.

  PERFORM handle_button.
  PERFORM handle_sections.

*--Check if ER is installed/ deactivate ER buttons
  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.


  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          screen-input = 1.
*          p_hienhn = 'X'.
        ENDIF.
        MODIFY SCREEN.
*Hide paralell processing options if detailed or tree output is selected
      WHEN 'WP' OR 'DEFGRP' OR 'SPECGRP' OR 'PGROUP'
            OR 'PSERVER' OR 'UPP'.
        IF sum = 'X'.
          screen-input  = '1'.
        ELSE.
          CLEAR : wp, pserver, pgroup.
          screen-input = '0'.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'SHONOCA'.
        IF NOT paudid[] IS INITIAL OR
           NOT s_imp[] IS INITIAL  OR
           NOT s_owner[] IS INITIAL OR
           NOT s_barea[] IS INITIAL.
          screen-input = 0.
          MODIFY SCREEN.
               IF shonoca = 'X'.
          CLEAR shonoca.
          MESSAGE w398(00) WITH text-c07.
        ENDIF.
        ENDIF.
        IF det = 'X'.
          screen-input = '0'.
          IF shonoca = 'X'.
            CLEAR shonoca.
            MESSAGE w398(00) WITH text-c07.
          ENDIF.
          ELSE.
            IF paudid[] IS INITIAL AND
            s_imp[] IS INITIAL  AND
            s_owner[] IS INITIAL AND
            s_barea[] IS INITIAL.
              screen-input = 1.
            ENDIF.
          ENDIF.
          MODIFY SCREEN.

       WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
          IF validusr = 'X'.
            exlckusr = 'X'.
            outvdate = 'X'.
*          CLEAR exlckusr.
            PERFORM set_def_usrtype.
            screen-input = 0.
            CLEAR p_flag.
          ELSE.
            PERFORM get_config_usr.
            screen-input    = 1.
          ENDIF.
          MODIFY SCREEN.
        WHEN 'SHOWCOMP'.
          IF gf_showpcom = 'X'.
*          screen-active = 0.
            screen-invisible = 1.
          ELSE.
*          screen-active = 1.
            screen-invisible = 0.
          ENDIF.
          IF p_nabap = 'X' AND showcomp = 'X'.
            CLEAR showcomp.
            MESSAGE w002 WITH text-032 text-033.
          ENDIF.
          MODIFY SCREEN.

          MODIFY SCREEN.

        WHEN 'SHOWPCOM'.
          IF gf_showpcom = ' '.
*          screen-active = 0.
            screen-invisible = 1.
          ELSE.
*          screen-active = 1.
            screen-invisible = 0.
          ENDIF.
          MODIFY SCREEN.

      ENDCASE.
*--Disable Application and System field if Non Abap is not selected
      IF screen-name CS 'S_APPL-' OR
         screen-name CS 'S_SYSTEM-'.

        IF p_nabap IS INITIAL..
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      ENDIF.

    ENDLOOP.

*  B8708 changes begin .
    LOOP AT SCREEN.
      IF screen-name = 'P_NABAP'.
        IF p_nabap = ' '.
          CLEAR : s_appl,s_system.
          REFRESH : s_appl[],s_system[].
        ENDIF.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.
* B8708 changes End.


INITIALIZATION.
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700
  PERFORM set_button_icons.
  PERFORM get_initial_config.
*---Default config param for enhanced sod matrix checkbox
  se_config_param 'DFLT_ENHANCE_MATRIX' gf_dflt_enhance_matrix.
  IF gf_dflt_enhance_matrix = 'Y' OR gf_dflt_enhance_matrix = 'X'.
    IF p_enhanc IS INITIAL.
      p_enhanc = 'X'.
       ENDIF.
    ELSE.
      CLEAR p_enhanc.
     ENDIF.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-low.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-high.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-low.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-high.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR pserver.
  PERFORM disp_total_servers_for_sel.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pgroup.
  PERFORM disp_total_server_groups.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-low.
  PERFORM f4_company USING 'S_COMP-LOW' CHANGING s_comp-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-high.
  PERFORM f4_company USING 'S_COMP-HIGH' CHANGING s_comp-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-low.
  PERFORM f4_department USING 'S_DEPART-LOW' CHANGING s_depart-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-high.
  PERFORM f4_department USING 'S_DEPART-HIGH' CHANGING s_depart-high.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-low.
  PERFORM f4_central_uid USING 'S_CUID-LOW' CHANGING s_cuid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-high.
  PERFORM f4_central_uid USING 'S_CUID-HIGH' CHANGING s_cuid-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN.
  SET PARAMETER ID '/PSYNG/VRSIO' FIELD sodvrsio.
  IF screen-name = 'P_NABAP' AND p_nabap = 'X'.
    IF showcomp = 'X'.
      CLEAR showcomp.
      MESSAGE w002 WITH text-013 text-014.
      STOP.
    ENDIF.
  ENDIF.

*************************************
  IF onlyrem = 'X'.
    IF remrfc[] IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for remote analysis'(024).
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
  ENDIF.
  PERFORM check_input.
  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    p_hienhn = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.

****Only remote analysis Check
  IF sy-ucomm = 'REMO'.
    IF onlyrem = 'X'.
      IF remrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.
  CASE sy-ucomm.
    WHEN 'ER1'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR excl_er.
      ENDIF.
    WHEN 'ER2'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR erroles.
      ENDIF.
  ENDCASE.

  LOOP AT SCREEN.
*--Disable Show no SOD when conflict ID's are restricted

    IF  screen-name CS 'PAUDID'
    OR screen-name CS 'S_OWNER'
    OR screen-name CS 'S_IMP'
    OR screen-name CS 'S_BAREA'.
      IF NOT paudid[] IS INITIAL OR
         NOT s_imp[] IS INITIAL  OR
         NOT s_owner[] IS INITIAL OR
         NOT s_barea[] IS INITIAL.


        IF shonoca = 'X'.
          MESSAGE s398(00) WITH text-c07.
          STOP.
        ENDIF.
      ENDIF.
    ENDIF.
*

  ENDLOOP.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.
*************************************
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
  DATA : lf_dont_update_scan TYPE flag,
         lf_dont_output_to_screen TYPE flag,
         lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
         lf_error TYPE flag,
         lt_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu,
         lt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu.


  DATA :       gt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles
       WITH HEADER LINE.

  SET PARAMETER ID '/PSYNG/VRSIO' FIELD sodvrsio.

*************************************
  program = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.
  exelog sy-repid ''.
  CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
*-- Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

  IF ustb IS INITIAL.
    lf_dont_update_scan = 'X'.
  ENDIF.

  IF odt IS INITIAL.
    lf_dont_output_to_screen = 'X'.
  ENDIF.

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

  PERFORM vaildate_other_fields.
  PERFORM get_critauths_from_selection.

  DATA : lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest.
  lt_rfcdest[] = remrfc[].

  IF sum = 'X'.
*-- Simulation Before and After Logic
    IF bysimu = 'X' OR byrsimu = 'X'.
      lt_role_addition_simu[] = gt_role_addition_simu[].
      lt_role_removal_simu[] = gt_role_removal_simu[].
      PERFORM before_after_simulation
      TABLES lt_role_removal_simu
             lt_role_addition_simu.
      EXIT.
    ENDIF.

*-- Analysis Without simulation

    FREE : gt_removed_roles.
    CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
         EXPORTING
              i_validuser        = validusr
              i_outvdate         = outvdate
              i_exlckusr         = exlckusr
              i_vrsio            = sodvrsio
              i_shomit           = xmc
              i_enh              = p_enhanc
              i_hienh            = p_hienhn
              i_wp               = wp
              i_xstb             = lf_dont_update_scan
              i_xstb_func        = 'X'
              i_pserver          = pserver
              i_group            = pgroup
              i_shonoca          = shonoca
              i_output           = lf_dont_output_to_screen
              i_remote_only      = onlyrem
              i_er_roles         = erroles
              i_exclude_er_roles = excl_er
              i_matrix_rfc       = p_sodrfc
              i_nonabap          = p_nabap
              i_abap             = p_abap
         IMPORTING
              e_usercount        = g_nr_users_analyzed
              ef_missing_auth    = gf_missing_auth_ugroup
              ef_st_missing_auth = gf_st_missing_auth
         TABLES
              it_usertype        = usrtype
              it_users           = pbname
              it_actgroups       = s_role
              it_profiles        = s_prof
              it_usergroup       = s_class
              it_ca              = paudid
              et_outputdet       = gt_output
              it_department      = s_depart
              it_company         = s_comp
              it_central_uid     = s_cuid
              et_mitigations     = gt_mccauser
              et_rpoug_auth_fail = gt_rpoug_auth_fail
              it_user_rfc        = lt_rfcdest
              et_return          = lt_return
              it_sense           = s_imp
              it_owners          = s_owner
              it_busarea         = s_barea
              et_enh_fun         = gt_enh_fun
              it_appl            = s_appl
              it_sysid           = s_system.

*--Handle Errors
    LOOP AT lt_return.
      IF lt_return-type = 'E'.
        lf_error = 'X'.
        lt_return-type = 'W'.
      ENDIF.
      MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
      WITH lt_return-message.
    ENDLOOP.
    IF lf_error = 'X'.
      MESSAGE ID '/PSYNG/SW' TYPE 'E' NUMBER '140'
      WITH 'Fatal errors have occured.'(e04).
    ENDIF.

*  --If removal simulation was done, but no roles were removed.
*  display a message
    IF byrsimu = 'X' AND gt_removed_roles[] IS INITIAL.
      MESSAGE i002 WITH
      'No users had the roles for which'(192)
      'removal was simulated'(191).
    ENDIF.

    IF NOT lf_dont_output_to_screen = 'X'.
      PERFORM reformat_output.
      PERFORM output_using_alv.
    ENDIF.
    EXIT.
  ENDIF.

  IF det = 'X'.
    lt_role_addition_simu[] = gt_role_addition_simu[].
    lt_role_removal_simu[] = gt_role_removal_simu[].
    CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC_DETAIL'
         EXPORTING
              i_validuser           = validusr
              i_outvdate            = outvdate
              i_exlckusr            = exlckusr
              i_vrsio               = sodvrsio
              i_shomit              = xmc
              i_bysimu              = bysimu
              i_showcomp            = showcomp
              i_showpcom            = showpcom
              i_hienh               = p_hienhn
              i_xstb                = 'X'
              i_remote_only         = onlyrem
              i_er_roles            = erroles
              i_exclude_er_roles    = excl_er
              i_matrix_rfc          = p_sodrfc
              i_nonabap             = p_nabap
              i_abap                = p_abap
         IMPORTING
              e_usercount           = g_nr_users_analyzed
         TABLES
              it_usertype           = usrtype
              it_users              = pbname
              it_actgroups          = s_role
              it_profiles           = s_prof
              it_usergroup          = s_class
              it_ca                 = paudid
              et_outputdet          = gt_output_det
              et_enh_tcodes         = gt_enh_tcodes
              it_department         = s_depart
              it_company            = s_comp
              it_central_uid        = s_cuid
              it_simu_role_removal  = lt_role_removal_simu
              it_simu_role_addition = lt_role_addition_simu
              it_user_rfc           = lt_rfcdest
              et_return             = lt_return
              it_sense              = s_imp
              it_owners             = s_owner
              it_busarea            = s_barea
              it_appl               = s_appl
              it_sysid              = s_system
              et_map_tcode_screen   = gt_map_tcode_screen.



    SORT gt_enh_tcodes.
    DELETE ADJACENT DUPLICATES FROM gt_enh_tcodes.
*--For Binary Search
    SORT gt_enh_tcodes BY calling_tcode.

    IF NOT lf_dont_output_to_screen = 'X'.
      PERFORM reformat_output_detail.
      PERFORM alv_output_det.
    ENDIF.
    EXIT.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  create_det_outrec
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_UINFO_SORTED  text
*      -->P_<O_DET>  text
*      <--P_OUTPUTDET  text
*----------------------------------------------------------------------*
FORM create_det_outrec USING    i_uinfo TYPE /psyng/sw_uinfo_remote
                                i_det TYPE /psyng/sw_outputdet3
                       CHANGING e_outputdet LIKE outputdet.
  DATA: cc  TYPE lvc_s_scol,
color TYPE lvc_s_colo.
  CLEAR outputdet.
  e_outputdet-bname      = i_uinfo-bname.
  e_outputdet-rfcdest    = i_det-rfcdest.
  e_outputdet-swaudid    = i_det-conid.
  e_outputdet-tcode      = i_det-tcode.
  e_outputdet-objct      = i_det-objct.
  e_outputdet-auth       = i_det-auth.
  e_outputdet-field      = i_det-field.
  e_outputdet-von        = i_det-von.
  e_outputdet-bis        = i_det-bis.
  e_outputdet-child_agr  = i_det-agr_name.
  e_outputdet-comp_agr   = i_det-comp_agr.
  e_outputdet-er         = i_det-er.
  e_outputdet-simu       = i_det-simu.
  e_outputdet-ustyp      = i_uinfo-ustyp.
  IF p_enhanc = 'X' .
*    e_outputdet-enhanced  = <o_det>-enhanced.
    IF p_hienhn = 'X'." and e_outputdet-enhanced = 'X'.
      READ TABLE gt_enh_tcodes WITH KEY
      calling_tcode = e_outputdet-tcode
      TRANSPORTING NO FIELDS BINARY SEARCH.
      IF sy-subrc = 0.
        e_outputdet-enhanced = 'X'.
        DELETE e_outputdet-color_cell
               WHERE fname = 'SWAUDID' OR fname = 'TCODE'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'SWAUDID'.
        APPEND cc TO e_outputdet-color_cell.
        cc-fname  = 'TCODE'.
        APPEND cc TO e_outputdet-color_cell.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " create_det_outrec

*---------------------------------------------------------------------*
*       FORM create_out_rec                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_SUM                                                         *
*  -->  I_UINFO                                                       *
*  -->  I_NUMRES                                                      *
*  -->  E_OUTPUT                                                      *
*---------------------------------------------------------------------*
FORM create_out_rec USING i_sum TYPE /psyng/sw_output_org
                          i_uinfo TYPE /psyng/sw_uinfo_remote
                          i_numres TYPE i
                    CHANGING
                          e_output LIKE output.
  DATA: cc  TYPE lvc_s_scol,
      color TYPE lvc_s_colo.
  CLEAR e_output.
  e_output-rfcdest   = i_sum-rfcdest.
  e_output-swaudid   = i_sum-funid.


  e_output-er        = i_sum-er.
  e_output-simu      = i_sum-simu.
  e_output-persa     = i_uinfo-persa.
  e_output-pernr     = i_uinfo-pernr.
  e_output-kostl     = i_uinfo-kostl.
  e_output-class     = i_uinfo-class.
  e_output-company   = i_uinfo-company.
  e_output-compshort = i_uinfo-company.
  PERFORM get_comp_name
        CHANGING
           i_uinfo-company
           e_output-company.
  e_output-department = i_uinfo-department.
  e_output-central_uid = i_uinfo-central_uid.

  e_output-bname     = i_uinfo-bname.
  e_output-name_text = i_uinfo-name_text.
  e_output-ustyp = i_uinfo-ustyp.
*  code Commented by Shekhar 14/09/2013 SE 3.1 Development
*  Start

*  e_output-uflag     = i_uinfo-uflag.
*  e_output-trdat     = i_uinfo-trdat.
*  e_output-sodcount  = i_uinfo-sodcount.
* End
*  --Check if this is a result of dynamic enhancement
  IF p_enhanc = 'X' .
    READ TABLE gt_enh_fun WITH KEY bname = e_output-bname
                                   funid = i_sum-funid
    TRANSPORTING NO FIELDS BINARY SEARCH.
    IF sy-subrc = 0.
      e_output-enhanced = 'X'.
      IF p_hienhn = 'X'.
*  --Highlight CA
        DELETE output-color_cell WHERE fname = 'SWAUDID'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'SWAUDID'.
        APPEND cc TO e_output-color_cell.
      ENDIF.
    ENDIF.
  ENDIF.
*  --Prevent Process from timing out.
  DATA : l_mod TYPE i.
  ADD 1 TO i_numres.
  l_mod = i_numres MOD 1500.
  IF l_mod = 0 AND i_numres GE 1500.
    CALL FUNCTION '/PSYNG/BASIS_GET_WPINFO'
         EXPORTING
              i_commit_pct = 20.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  create_noca_rec
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_REMOTE_ANAL_RFC_RFCOPTIONS  text
*      -->P_LT_UINFO_SORTED  text
*      <--P_OUTPUT  text
*----------------------------------------------------------------------*
FORM create_noca_rec USING    i_rfcdesc TYPE rfcoptions
                              i_uinfo   TYPE /psyng/sw_uinfo_remote
                     CHANGING e_output  LIKE output.
  DATA : l_date(12).
  CLEAR e_output.
  e_output-swaudid   = '----'.
  CONCATENATE
  'No Critical authorizations based on SOD matrix'(n01)
  'defined in Security Weaver on'(n02)
  l_date
  INTO e_output-description SEPARATED BY space.
  e_output-rfcdest   = i_rfcdesc.
  e_output-persa     = i_uinfo-persa.
  e_output-pernr     = i_uinfo-pernr.
  e_output-kostl     = i_uinfo-kostl.
  e_output-class     = i_uinfo-class.
  e_output-company   = i_uinfo-company.
  e_output-compshort = i_uinfo-company.
**  IF e_output-company IS INITIAL.
  PERFORM get_comp_name
        CHANGING
           i_uinfo-company
           e_output-company.
*  ENDIF.
  e_output-department  = i_uinfo-department.
  e_output-central_uid = i_uinfo-central_uid.

  e_output-bname     = i_uinfo-bname.
  e_output-name_text = i_uinfo-name_text.
*  code Commented by Shekhar 14/09/2013 SE 3.1 Development
*  Start
*  e_output-uflag     = i_uinfo-uflag.
*  e_output-trdat     = i_uinfo-trdat.
*  e_output-sodcount  = i_uinfo-sodcount.
* Endfix
ENDFORM.                    " create_noca_rec


*---------------------------------------------------------------------*
*       FORM exelog                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  alv_output_sum
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_output_sum.
  DATA : l_idx TYPE sy-tabix.
  SORT swaudhdr BY swaudid.

  LOOP AT output WHERE swaudid NE '----'.
    READ TABLE swaudhdr WITH KEY swaudid = output-swaudid
                                 BINARY SEARCH.
    l_idx = sy-tabix.
    IF sy-subrc <> 0.
*B8710 - A CA that isn't defined in SE should not be deleted
      IF p_nabap <> 'X'.
        DELETE output WHERE swaudid = output-swaudid.
        CONTINUE.
      ELSE.
        CLEAR swaudhdr.
      ENDIF.
    ENDIF.

*      CHECK sy-subrc = 0.
    output-description = swaudhdr-description.
    output-imp = swaudhdr-imp.
    output-owner = swaudhdr-owner.
    SELECT SINGLE text FROM /psyng/busarea           "#EC CI_SEL_NESTED
     INTO output-barea
    WHERE busarea = swaudhdr-busarea.
    IF sy-subrc NE 0.
      CLEAR output-barea.
    ENDIF.
    MODIFY output.
  ENDLOOP.

  PERFORM build_alv_catalog_sum.
  PERFORM output_using_alv_sum.

ENDFORM.                    " alv_output_sum

*&---------------------------------------------------------------------*
*&      Form  alv_output_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_output_det.
  SORT swaudhdr BY swaudid.
  LOOP AT outputdet.
    READ TABLE swaudhdr WITH KEY swaudid = outputdet-swaudid
                                 BINARY SEARCH.
    CHECK sy-subrc = 0.
    outputdet-description = swaudhdr-description.
    outputdet-imp = swaudhdr-imp.
    outputdet-owner = swaudhdr-owner.
    SELECT SINGLE text FROM /psyng/busarea           "#EC CI_SEL_NESTED
     INTO outputdet-barea
    WHERE busarea = swaudhdr-busarea.
    IF sy-subrc NE 0.
      CLEAR outputdet-barea.
    ENDIF.
    MODIFY outputdet.
  ENDLOOP.

  PERFORM build_alv_catalog_det.
  PERFORM output_using_alv_det.
ENDFORM.                    " alv_output_det



*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_sum
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog_sum.
  program = sy-repid.
  REFRESH: i_fieldcat_alv.
  CLEAR: i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = program
            i_internal_tabname     = 'OUTPUT'
            i_inclname             = program
       CHANGING
            ct_fieldcat            = i_fieldcat_alv
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.

  IF sy-subrc <> 0.

  ENDIF.

* Manually building the field catalog, since
* REUSE_ALV_FIELDCATALOG_MERGE is not working properly

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos = '2'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos = '6'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '7'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING col_pos
  WHERE  fieldname = 'NAME_TEXT'.

  wa_fieldcat_alv-col_pos = '8'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING col_pos
  WHERE  fieldname = 'USTYP'.

  wa_fieldcat_alv-col_pos = '0'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING col_pos
  WHERE  fieldname = 'KOSTL'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname   = 'SWAUDID'.
  wa_fieldcat_alv-col_pos = '9'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'IMP'.
*  wa_fieldcat_alv-col_pos = '11'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000008'.
  wa_fieldcat_alv-ddic_outputlen = '000008'.
*  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'OWNER'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000008'.
  wa_fieldcat_alv-ddic_outputlen = '000008'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'PERNR'.
*  wa_fieldcat_alv-col_pos = '9'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'N'.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-intlen = '000008'.
  wa_fieldcat_alv-ddic_outputlen = '000008'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'CONTID'.
*  wa_fieldcat_alv-col_pos = '10'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000006'.
  wa_fieldcat_alv-ddic_outputlen = '000006'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


*Simulation Checkbox
  CLEAR wa_fieldcat_alv.
  IF bysimu IS INITIAL AND byrsimu IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  wa_fieldcat_alv-fieldname = 'SIMU'.
  wa_fieldcat_alv-col_pos = '15'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.

  wa_fieldcat_alv-seltext_m = 'Simulation'(s01).
  wa_fieldcat_alv-seltext_s = 'Simulation'(s01).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

*  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'SIMU_BEFORE'.
  wa_fieldcat_alv-col_pos = '16'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-hotspot = 'X'.
  wa_fieldcat_alv-seltext_m = 'Simu Before'(s04).
  wa_fieldcat_alv-seltext_s = 'Before'(s04).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

*  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'SIMU_AFTER'.
  wa_fieldcat_alv-col_pos = '17'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-hotspot = 'X'.
  wa_fieldcat_alv-seltext_m = 'Simu After'(s05).
  wa_fieldcat_alv-seltext_s = 'After'(s05).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

*ER Checkbox
  CLEAR wa_fieldcat_alv.
  IF erroles IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-fieldname = 'ER'.
  wa_fieldcat_alv-col_pos = '18'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-seltext_m = 'ER Role'(s02).
  wa_fieldcat_alv-seltext_s = 'ER Role'(s02).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

*Enhanced Checkbox
  CLEAR wa_fieldcat_alv.
  IF p_enhanc IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-fieldname = 'ENHANCED'.
  wa_fieldcat_alv-col_pos = '19'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-seltext_m = 'Enhanced'(s03).
  wa_fieldcat_alv-seltext_s = 'Enhanced'(s03).
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  SORT i_fieldcat_alv BY col_pos.
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '20'.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      col_pos
                   WHERE
                      fieldname = 'PERNR'.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'KOSTL'.

  wa_fieldcat_alv-seltext_l = text-038.
  wa_fieldcat_alv-seltext_m = text-038.
  wa_fieldcat_alv-seltext_s = text-038.
  wa_fieldcat_alv-reptext_ddic = text-038.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.


  wa_fieldcat_alv-seltext_l = text-039.
  wa_fieldcat_alv-seltext_m = text-039.
  wa_fieldcat_alv-seltext_s = text-039.
  wa_fieldcat_alv-reptext_ddic = text-040.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CLASS'.
*--DHORIONS 20130508 - Change : Company Short text is always visible
*                      by default,  Long text is hidden.
  wa_fieldcat_alv-col_pos = '12'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                     TRANSPORTING
                       col_pos
                    WHERE
                       fieldname = 'DESCRIPTION'.

  wa_fieldcat_alv-seltext_m = 'Company Long Text'(160).
  wa_fieldcat_alv-seltext_s = 'Company Long Text'(160).
  wa_fieldcat_alv-seltext_l = 'Company Long Text'(160).
  wa_fieldcat_alv-reptext_ddic = 'Company Long Text'(160).
  wa_fieldcat_alv-col_pos = '3'.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                      no_out
                   WHERE
                      fieldname = 'COMPANY'.

  wa_fieldcat_alv-seltext_m = 'Company'(175).
  wa_fieldcat_alv-seltext_s = 'Company'(175).
  wa_fieldcat_alv-seltext_l = 'Company'(175).
  wa_fieldcat_alv-reptext_ddic = 'Company'(175).
  wa_fieldcat_alv-col_pos = '3'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'COMPSHORT'.



  wa_fieldcat_alv-seltext_m = text-161.
  wa_fieldcat_alv-seltext_s = text-161.
  wa_fieldcat_alv-reptext_ddic = text-161.
  wa_fieldcat_alv-seltext_l = text-161.
  wa_fieldcat_alv-col_pos = '4'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'DEPARTMENT'.







  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-fieldname = 'MIT_ICON'.
  wa_fieldcat_alv-col_pos = '25'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-seltext_l = text-h29.
  wa_fieldcat_alv-seltext_m = text-h30.
  wa_fieldcat_alv-seltext_s = text-h30.
  wa_fieldcat_alv-reptext_ddic = text-h30.
  wa_fieldcat_alv-icon    = 'X'.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                      tabname
                      inttype
                      intlen
                      ddic_outputlen
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      icon
                      hotspot
                      no_out
                   WHERE
                      fieldname = 'MIT_ICON'.


  wa_fieldcat_alv-seltext_m = text-050.
  wa_fieldcat_alv-seltext_l = text-050.
  wa_fieldcat_alv-seltext_s = text-051.
  wa_fieldcat_alv-reptext_ddic = text-052.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SWAUDID'.

  wa_fieldcat_alv-seltext_m = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-seltext_s = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-seltext_l = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-col_pos = '11'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat_alv-seltext_m = 'Application Area'(183).
  wa_fieldcat_alv-seltext_s = 'Application Area'(183).
  wa_fieldcat_alv-reptext_ddic = 'Application Area'(183).
  wa_fieldcat_alv-seltext_l = 'Application Area'(183).
  wa_fieldcat_alv-col_pos = '13'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'BAREA'.

  wa_fieldcat_alv-seltext_m = text-162.
  wa_fieldcat_alv-seltext_s = text-162.
  wa_fieldcat_alv-reptext_ddic = text-162.
  wa_fieldcat_alv-seltext_l = text-162.
  wa_fieldcat_alv-col_pos = '5'.
  IF gf_central_uid = 'X'.
    CLEAR wa_fieldcat_alv-no_out.
  ELSE.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                      no_out
                   WHERE
                      fieldname = 'CENTRAL_UID'.


  wa_fieldcat_alv-seltext_m = 'Owner User ID'(177).
  wa_fieldcat_alv-seltext_s = 'Owner'(177).
  wa_fieldcat_alv-reptext_ddic = 'Owner'(177).
  wa_fieldcat_alv-seltext_l = 'Owner'(177).
  wa_fieldcat_alv-col_pos = '14'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'OWNER'.


  wa_fieldcat_alv-seltext_m = text-103.
  wa_fieldcat_alv-seltext_l = text-103.
  wa_fieldcat_alv-seltext_s = text-104.
  wa_fieldcat_alv-reptext_ddic = text-103.
  wa_fieldcat_alv-col_pos = '10'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'RFCDEST'.

  wa_fieldcat_alv-seltext_m = text-057.
  wa_fieldcat_alv-seltext_s = text-057.
  wa_fieldcat_alv-reptext_ddic = text-057.
  wa_fieldcat_alv-seltext_l = text-057.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TO_DATE'.

  wa_fieldcat_alv-seltext_m = text-106.
  wa_fieldcat_alv-seltext_l = text-106.
  wa_fieldcat_alv-seltext_s = text-107.
  wa_fieldcat_alv-reptext_ddic = text-106.
  wa_fieldcat_alv-col_pos = '19'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'CONTID'.

  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING no_out
                        WHERE fieldname = 'SEL'.

  wa_fieldcat_alv-seltext_l = text-h00.
  wa_fieldcat_alv-seltext_m = text-h00.
  wa_fieldcat_alv-seltext_s = text-h00.
  wa_fieldcat_alv-reptext_ddic = text-h00.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDITOR'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'APPL'.
  wa_fieldcat_alv-col_pos = '26'.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
*    wa_fieldcat_alv-intlen = '000012'.
*    wa_fieldcat_alv-ddic_outputlen = '000012'.
  wa_fieldcat_alv-seltext_l = 'Application'.
  wa_fieldcat_alv-seltext_m = 'Application'.
  wa_fieldcat_alv-seltext_s = 'Appl'.
  IF p_nabap IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  SORT i_fieldcat_alv BY col_pos.
  IF xmc IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING no_out
                          WHERE fieldname = 'CONTID'
                             OR fieldname = 'AUDITOR'
                             OR fieldname = 'FROM_DATE'
                             OR fieldname = 'TO_DATE'
                             OR fieldname = 'MIT_ICON'.
  ENDIF.
ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog_det.

  REFRESH: i_fieldcat_alv_det.
  program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = program
            i_internal_tabname     = 'OUTPUTDET'
            i_inclname             = program
       CHANGING
            ct_fieldcat            = i_fieldcat_alv_det
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.

  IF sy-subrc <> 0.

  ENDIF.


* Manually building the rest of the field catalog
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos = '1'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
  wa_fieldcat_alv-seltext_m = text-038.
  wa_fieldcat_alv-seltext_s = text-038.
  wa_fieldcat_alv-reptext_ddic = text-038.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'SWAUDID'.
  wa_fieldcat_alv-col_pos = '2'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-seltext_m = text-050.
  wa_fieldcat_alv-seltext_s = text-051.
  wa_fieldcat_alv-reptext_ddic = text-052.
** Making Hotspot enable as of SE 3.1 - HS
  wa_fieldcat_alv-hotspot = 'X'.
**
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'USTYP'.
  wa_fieldcat_alv-col_pos = '3'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-seltext_m = text-186.
  wa_fieldcat_alv-seltext_s = text-186.
  wa_fieldcat_alv-reptext_ddic = text-186.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'IMP'.
  wa_fieldcat_alv-col_pos = '4'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000008'.
  wa_fieldcat_alv-ddic_outputlen = '000008'.
  wa_fieldcat_alv-seltext_m = text-176.
  wa_fieldcat_alv-seltext_s = text-176.
  wa_fieldcat_alv-reptext_ddic = text-176.
*** Making Hotspot enable as of SE 3.1 - HS
*  wa_fieldcat_alv-hotspot = 'X'.
***
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-fieldname = 'BAREA'.
*  wa_fieldcat_alv-col_pos = '4'.
*  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '000100'.
*  wa_fieldcat_alv-ddic_outputlen = '000100'.
*  wa_fieldcat_alv-seltext_m = text-183.
*  wa_fieldcat_alv-seltext_s = text-183.
*  wa_fieldcat_alv-reptext_ddic = text-183.
*  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.
**
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'OWNER'.
  wa_fieldcat_alv-col_pos = '5'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-seltext_m = text-177.
  wa_fieldcat_alv-seltext_s = text-177.
  wa_fieldcat_alv-reptext_ddic = text-177.
*** Making Hotspot enable as of SE 3.1 - HS
*  wa_fieldcat_alv-hotspot = 'X'.
***
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.



*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-fieldname = 'DESCRIPTION'.
*  wa_fieldcat_alv-col_pos = '3'.
*  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '200'(062).
*  wa_fieldcat_alv-ddic_outputlen = '200'(062).
*  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'TCODE'.
  wa_fieldcat_alv-col_pos = '6'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '20'(057).
  wa_fieldcat_alv-ddic_outputlen = '20'(057).
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'OBJCT'.
  wa_fieldcat_alv-col_pos = '6'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000010'.
  wa_fieldcat_alv-ddic_outputlen = '000010'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'AUTH'.
  wa_fieldcat_alv-col_pos = '7'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
*  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'FIELD'.
  wa_fieldcat_alv-col_pos = '7'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000010'.
  wa_fieldcat_alv-ddic_outputlen = '000010'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'VON'.
  wa_fieldcat_alv-col_pos = '8'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000018'.
  wa_fieldcat_alv-ddic_outputlen = '000018'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'BIS'.
  wa_fieldcat_alv-col_pos = '9'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000018'.
  wa_fieldcat_alv-ddic_outputlen = '000018'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'CHILD_AGR'.
  wa_fieldcat_alv-col_pos = '10'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000030'.
  wa_fieldcat_alv-ddic_outputlen = '000030'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

*Simulation Checkbox
  CLEAR wa_fieldcat_alv.
  IF bysimu IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  wa_fieldcat_alv-fieldname = 'SIMU'.
  wa_fieldcat_alv-col_pos = '14'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-seltext_m = 'Simulation'(s01).
  wa_fieldcat_alv-seltext_s = 'Simulation'(s01).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
*ER Checkbox
  CLEAR wa_fieldcat_alv.
  IF erroles IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  wa_fieldcat_alv-fieldname = 'ER'.
  wa_fieldcat_alv-col_pos = '15'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-seltext_m = 'ER Role'(s02).
  wa_fieldcat_alv-seltext_s = 'ER Role'(s02).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

*Enhanced Checkbox
  CLEAR wa_fieldcat_alv.
  IF p_enhanc IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-fieldname = 'ENHANCED'.
  wa_fieldcat_alv-col_pos = '16'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  wa_fieldcat_alv-seltext_m = 'Enhanced'(s03).
  wa_fieldcat_alv-seltext_s = 'Enhanced'(s03).

  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.


  wa_fieldcat_alv-seltext_m = 'Application Area'(183).
  wa_fieldcat_alv-seltext_s = 'Application Area'(183).
  wa_fieldcat_alv-reptext_ddic = 'Application Area'(183).
*  wa_fieldcat_alv-hotspot = 'X'.

  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
*                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
*                      hotspot
                   WHERE
                      fieldname = 'BAREA'.

  wa_fieldcat_alv-seltext_m = 'TCode'(063).
  wa_fieldcat_alv-seltext_s = 'TCode'(063).
  wa_fieldcat_alv-reptext_ddic = 'TCode'(063).
  wa_fieldcat_alv-hotspot = 'X'.

  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.

  wa_fieldcat_alv-seltext_m = 'Auth.object'(064).
  wa_fieldcat_alv-seltext_s = 'Auth.object'(064).
  wa_fieldcat_alv-reptext_ddic = 'Auth.object'(064).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'OBJCT'.


  wa_fieldcat_alv-seltext_m = 'Authorization'(065).
  wa_fieldcat_alv-seltext_s = 'Authorization'(065).
  wa_fieldcat_alv-reptext_ddic = 'Authorization'(065).
  wa_fieldcat_alv-hotspot = ' '.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'AUTH'.

  wa_fieldcat_alv-seltext_m  = 'Field'(069).
  wa_fieldcat_alv-seltext_s    =  'Field'(069).
  wa_fieldcat_alv-reptext_ddic =  'Field'(069).
  wa_fieldcat_alv-hotspot = 'X'.

  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'FIELD'.



  wa_fieldcat_alv-seltext_m = 'From'(066).
  wa_fieldcat_alv-seltext_s = 'From'(066).
  wa_fieldcat_alv-reptext_ddic = 'From'(066).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'VON'.


  wa_fieldcat_alv-seltext_m = 'To'(067).
  wa_fieldcat_alv-seltext_s =  'To'(067).
  wa_fieldcat_alv-reptext_ddic = 'To'(067).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'BIS'.

*  wa_fieldcat_alv-seltext_m = 'Role'(068).
*  wa_fieldcat_alv-seltext_s =  'Role'(068).
*  wa_fieldcat_alv-reptext_ddic = 'Role'(068).
*  wa_fieldcat_alv-hotspot = 'X'.
*  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                      hotspot
*                   WHERE
*                      fieldname = 'CHILD_AGR'
*                      OR
*                      fieldname = 'COMP_AGR'.

  wa_fieldcat_alv-seltext_m = 'Single Role'(068).
  wa_fieldcat_alv-seltext_s =  'Single Role'(068).
  wa_fieldcat_alv-reptext_ddic = 'Single Role'(068).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'CHILD_AGR'.

  wa_fieldcat_alv-seltext_m = 'Composite Role'(088).
  wa_fieldcat_alv-seltext_s =  'Composite Role'(088).
  wa_fieldcat_alv-reptext_ddic = 'Composite Role'(088).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'COMP_AGR'.


  wa_fieldcat_alv-hotspot = 'X'.
  wa_fieldcat_alv-key = ''.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                      key
                   WHERE
                      fieldname = 'PROFILE'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'RFCDEST'.
  wa_fieldcat_alv-col_pos = '3'.
*  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '000032'.
*  wa_fieldcat_alv-ddic_outputlen = '000006'.
*  wa_fieldcat_alv-hotspot = 'X'.

  wa_fieldcat_alv-seltext_m = text-103.
  wa_fieldcat_alv-seltext_s = text-104.
  wa_fieldcat_alv-reptext_ddic = text-103.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
*                      hotspot
                      col_pos
                   WHERE
                      fieldname = 'RFCDEST'.

  IF showcomp IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'COMP_AGR'.
  ENDIF.

  IF showpcom = space.
*   If user not showing composite profiles, hide column COMP_PROF
    CLEAR wa_fieldcat_alv.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'COMP_PROF'.
  ELSE.
    CLEAR wa_fieldcat_alv.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                      WHERE
                        fieldname = 'CHILD_AGR'.

    wa_fieldcat_alv-seltext_l      = 'Composite profile'(230).
    wa_fieldcat_alv-seltext_m      = 'Composite Profile'(230).
    wa_fieldcat_alv-seltext_s      = 'Composite Profile'(230).
    wa_fieldcat_alv-hotspot        = 'X'.
    wa_fieldcat_alv-key = ' '.

    MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        hotspot
                        key
                     WHERE
                        fieldname = 'COMP_PROF'.
  ENDIF.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'APPL'.
  wa_fieldcat_alv-col_pos = '23'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
  wa_fieldcat_alv-seltext_m = 'Application'.
  wa_fieldcat_alv-seltext_s = 'Application'.
  IF p_nabap = ''.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

ENDFORM.                    " build_alv_catalog_det

*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv_sum.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.
  DATA: ls_swconfig_bkgd_job TYPE /psyng/swconfig.
  DATA: ls_line_count TYPE i.
  DATA : l_temp TYPE i.

  alv_layout-box_fieldname = 'SEL'.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_grid_titl = text-053.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.

  PERFORM build_sort_table_sum.
*  PERFORM adjust_columns_sum.


* REPEAT_HDR_BKGDJOB Flag Check
  IF sy-batch EQ 'X'.
    se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.
    IF ls_swconfig_bkgd_job-value = 'N'.
      CLEAR g_repeat_hdr_bkgdjob.
      DESCRIBE TABLE output LINES ls_line_count.
      PERFORM set_print_param USING ls_line_count.
    ELSE.
      g_repeat_hdr_bkgdjob = 'X'.
      DESCRIBE TABLE output LINES ls_line_count.
      l_temp = ls_line_count / sy-srows.
      gf_pages = trunc( l_temp ).
      l_temp = frac( l_temp ).
      IF l_temp > 0.
        gf_pages = gf_pages + 1.
      ENDIF.
    ENDIF.

  ENDIF.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'SUM_HEADER'
            i_grid_title             = alv_grid_titl
            i_callback_program       = program
            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            it_sort                  = isort
            i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUM'
            is_layout                = alv_layout
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = output.

ENDFORM.                    " output_using_alv

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

  IF xmc IS INITIAL.
    lt_func-fcode = 'MITIGATE'.
    APPEND lt_func.
    lt_func-fcode = 'DEL_MIT'.
    APPEND lt_func.
  ELSE.
*-- Check config if this check is required or not
    IF gf_use_sec_obj = 'X'.
*-- Check Create/Modify Authority
      AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
       ID 'ACTVT' FIELD '22'
       ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
*      ID 'Y&SW_CONID' "(--)BOC UMITTAL SE VF scan-25/11/2024
       ID 'Y&SW_SWAUD' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       "(++)BOC UMITTAL SE VF scan-25/11/2024
       ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
          ID 'ACTVT' FIELD '23'
          ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
*         ID 'Y&SW_CONID' DUMMY "(--)BOC UMITTAL SE VF scan-25/11/2024
          ID 'Y&SW_SWAUD' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          "(++)BOC UMITTAL SE VF scan-25/11/2024
          ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc NE 0.
          lt_func-fcode = 'MITIGATE'.
          APPEND lt_func.
        ENDIF.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
   ID 'ACTVT' FIELD '24'
   ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
   ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
   ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
   ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
*   ID 'Y&SW_CONID' DUMMY "(--)BOC UMITTAL SE VF scan-25/11/2024
   ID 'Y&SW_SWAUD' FIELD '' "(++)BOC UMITTAL SE VF scan-25/11/2024
   ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc NE 0.
        lt_func-fcode = 'DEL_MIT'.
        APPEND lt_func.
      ENDIF.
    ENDIF.

  ENDIF.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FAILEDUSER'.
    APPEND lt_func.
  ENDIF.

  SET PF-STATUS 'SUMMARY' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary

*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv_det.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  alv_grid_titl = text-053.

  PERFORM build_sort_table_det.
  PERFORM adjust_columns_det.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title             = alv_grid_titl
            i_callback_program       = program
            it_sort                  = isortdet
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_DET'
            is_layout                = alv_layout
            it_fieldcat              = i_fieldcat_alv_det
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = outputdet.

ENDFORM.                    " output_using_alv

*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table_sum.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'COMPSHORT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'DEPARTMENT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'CENTRAL_UID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'USTYP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'SWAUDID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '10'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '11'.
  l_sort-fieldname = 'BAREA'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '12'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '13'.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '14'.
  l_sort-fieldname = 'COMPANY'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table_det.
  DATA: l_sort TYPE slis_sortinfo_alv.


  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.



  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SWAUDID'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BAREA'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OBJCT'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AUTH'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELD'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VON'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BIS'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CHILD_AGR'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'COMP_AGR'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.
*
*  ADD 1 TO l_sort-spos.
*  l_sort-fieldname = 'COMPANY'.
*  l_sort-tabname = 'OUTPUT'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO isortdet.
*
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'USTYP'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'COMP_PROF'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'APPL'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.


ENDFORM.                    " build_sort_table_det

*&---------------------------------------------------------------------*
*&      Form  adjust_columns
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns_sum.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '1'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'CLASS'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'COMPANY'.
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '3'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DEPARTMENT'.



  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '4'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'BNAME'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '5'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'NAME_TEXT'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '6'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'SWAUDID'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '7'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DESCRIPTION'.




*  code Commented by Shekhar 14/09/2013 SE 3.1 Development
*  Start

*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '8'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'UFLAG'.
*
*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '9'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'TRDAT'.
*
*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '10'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'SODCOUNT'.
* End
ENDFORM.                    " adjust_columns
*&---------------------------------------------------------------------*
*&      Form  adjust_columns_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '1'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'SWAUDID'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'BNAME'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-key = ''.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname = 'COMP_AGR'.



ENDFORM.                    " adjust_columns

*---------------------------------------------------------------------*
*       FORM user_double_click_on_det                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click_on_det USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.

  DATA : answer,line(80),
         lv_iobjct    LIKE tobj-objct,
         lv_authfield LIKE authx-fieldname,
         agr_name TYPE agr_name,
         i_auth LIKE /psyng/swaudhdr-swaudid,
         l_uname        LIKE sy-uname,
         l_contid TYPE /psyng/mchdr-contid,
         l_parva        TYPE usr05-parva,
         l_sod          TYPE /psyng/swsodvers-vrsio,
         lf_screen      TYPE /psyng/bapiflagx,
         l_table_en(20) TYPE c,
         wa_outputdet   LIKE LINE OF outputdet,
         l_system       TYPE /PSYNG/SYSTEM,
         l_tcode        TYPE XUTCODE,
         l_fm_read_roles(32) VALUE '/PSYNG/SW_CR_READ_ROLES_EN',
         ls_rolehdr TYPE  /psyng/ex_rolhdr_st,
         ls_rolid TYPE /psyng/ex_rolhdr_st,
         userresponse.



  CASE r_ucomm.

    WHEN 'FAILEDUSER'.
      PERFORM show_user_grp_cmp_invalid.
      EXIT.
  ENDCASE.


  CASE rs_selfield-fieldname.
    WHEN 'SWAUDID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/SW_CRIT_AUTH' FIELD rs_selfield-value.
      g_dynnr = '0209'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.
    WHEN 'BNAME'.
      CLEAR answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
           EXPORTING
                defaultoption     = '1'
                diagnosetext1     =
     'You can view User Master Record (in transaction SU01) or'(070)
                diagnosetext2     =
     'view user''s transaction code execution history'(071)

                textline1         =
     'View user master or history?'(072)
                text_option1      =
     'User Master'(073)
                text_option2      =
     'User History'(074)
                icon_text_option1 = 'ICON_TBH'
                icon_text_option2 = 'ICON_HISTORY'
                titel             =
     'User Master or Transaction History'(075)
                cancel_display    = 'X'
           IMPORTING
                answer            = answer.

      CASE answer.
        WHEN '1'.
*          AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
          IF sy-subrc = 1.
            SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
            CALL TRANSACTION 'SU01'.
          ELSE.
*            AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01D'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
            IF sy-subrc = 1.
              SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
              CALL TRANSACTION 'SU01D'.
            ELSE.
              MESSAGE e077(s#) WITH 'SU01D'.
            ENDIF.
          ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        WHEN '2'.

          DATA: lv_userresponse, lv_1stmon(7), lv_lastmon(7).

          CLEAR: ifields.
          REFRESH: ifields.

          PERFORM get_history_months USING lv_1stmon lv_lastmon.

          ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
          ifields-fieldname = 'MMYYYYS'.
          ifields-fieldtext = text-119.
          ifields-value = lv_1stmon.
          APPEND ifields.
          ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
          ifields-fieldname = 'MMYYYYE'.
          ifields-fieldtext = text-120.
          ifields-value = lv_lastmon.
          APPEND ifields.

          CLEAR lv_userresponse.
          CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
               EXPORTING
                    formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
                    programname       = '/PSYNG/SODREPORT_ORG'
                    popup_title       =
               'Restrict months (available displayed)'(076)
                    ok_pushbuttontext = 'Continue'(077)
               IMPORTING
                    returncode        = lv_userresponse
               TABLES
                    fields            = ifields
               EXCEPTIONS
                    error_in_fields   = 1
                    OTHERS            = 2.

          IF sy-subrc <> 0.
            MESSAGE e208(00) WITH 'Error when calling pop-up'(078).
          ENDIF.

          CHECK lv_userresponse NE 'A'.  "check to see user doesn'tabort

         READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                                  fieldname = 'MMYYYYS'.
          CHECK NOT ifields-value IS INITIAL.
          lv_1stmon = ifields-value.

         READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                                  fieldname = 'MMYYYYE'.
          CHECK NOT ifields-value IS INITIAL.
          lv_lastmon = ifields-value.

          SUBMIT /psyng/sw_017
                  WITH pbname = rs_selfield-value
                  WITH 1stmon = lv_1stmon
                  WITH lastmon = lv_lastmon
                  WITH validusr = ' '
                  AND RETURN.

      ENDCASE.
    WHEN 'TCODE'.
      CHECK rs_selfield-value <> '*'."only for real tcodes
      READ TABLE outputdet INTO  wa_outputdet
                       INDEX rs_selfield-tabindex.
      l_system = wa_outputdet-rfcdest.
      l_tcode  = wa_outputdet-tcode.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
         i_tcode           = l_tcode
         IF_NON_ABAP       = p_nabap
         I_APPL            = wa_outputdet-appl
         I_SYSTEM          = l_system.

    WHEN 'OBJCT'.
      CHECK rs_selfield-value <> space.
      READ TABLE outputdet INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      lv_iobjct = rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
           EXPORTING
                object  = lv_iobjct
                eu_mode = ' '.
    WHEN 'FIELD'.
      CHECK rs_selfield-value <> space.
      lv_authfield = rs_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
           EXPORTING
                fieldname = lv_authfield.

    WHEN 'VON' OR 'BIS'.
      CHECK rs_selfield-value <> space.
      READ TABLE outputdet INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
        EXPORTING
          fieldname             = outputdet-field
          object                = outputdet-objct
*       IMPORTING
*         SEL_VALUE             =
        EXCEPTIONS
          field_not_found       = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    WHEN 'CHILD_AGR' OR 'COMP_AGR'.
      agr_name = rs_selfield-value.
      READ TABLE outputdet INDEX rs_selfield-tabindex.
      IF outputdet-appl <> 'SAP'.
        CLEAR answer.
        ls_rolehdr-rolid = agr_name.
        ls_rolehdr-appl = outputdet-appl.
        ls_rolehdr-sysid = outputdet-rfcdest.
        CALL FUNCTION l_fm_read_roles "#EC PATHLOCK_CI_DYN_ACCES
             EXPORTING
                  i_rolid                   = ls_rolehdr-rolid
                  i_appl                    = ls_rolehdr-appl
                  i_sysid                   = ls_rolehdr-sysid
             IMPORTING
                  es_rolid                  = ls_rolid
             EXCEPTIONS
                  source_rolid_doesnt_exist = 1
                  not_authorized_to_display = 2
                  OTHERS                    = 3.
        IF sy-subrc <> 0.
          CLEAR ls_rolid.
        ENDIF.

        CONCATENATE agr_name '-' ls_rolid-rdesc INTO line.
        CLEAR ls_rolid.


        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  titlebar              = rs_selfield-value
                  text_question         = line
                  text_button_1         = text-129
                  icon_button_1         = 'ICON_SYSTEM_OKAY'
                  text_button_2         = text-080
                  icon_button_2         = 'ICON_SYSTEM_CANCEL'
                  default_button        = '1'
                  display_cancel_button = ' '
             IMPORTING
                  answer                = answer.

      ELSE.
        DATA: l_repid LIKE sy-repid,
        pertext(200).
        DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.


        CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
             EXPORTING
                  defaultoption     = '1'
                  diagnosetext1     = agr_name
                  diagnosetext2     = text-201
                  diagnosetext3     = text-202
                  textline1         = text-203
                  text_option1      = text-205
                  text_option2      = text-206
                  icon_text_option1 = 'ICON_DISPLAY'
                  icon_text_option2 = 'ICON_CHECK'
                  titel             = text-203
                  cancel_display    = 'X'
             IMPORTING
                  answer            = answer.
        CASE answer.
          WHEN '1'.
*       CHECK outputdet4-rfcdest+0(3) = sy-sysid AND  "Show only if role
*          outputdet4-rfcdest+3(3) = sy-mandt.     "in current system

  CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
*    STARTING NEW TASK 'PFCG'
       EXPORTING
            agr_name = agr_name
       EXCEPTIONS
            agr_not_found = 1
            OTHERS        = 2.
            IF sy-subrc <> 0.
              IF sy-subrc = 1.
                CLEAR pertext.
                CONCATENATE text-207 text-208
                           INTO pertext SEPARATED BY space.
                MESSAGE i208(00) WITH pertext.
              ELSEIF sy-subrc = 2.
                CONCATENATE text-209 text-208 text-210
                           INTO pertext SEPARATED BY space.
                MESSAGE i208(00) WITH pertext.
              ENDIF.
            ENDIF.
          WHEN '2'.
            DATA: dflt_rfc LIKE /psyng/swconfig-value.

            CLEAR: ifields.
            REFRESH: ifields.

            se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
            IF ifields[] IS INITIAL.
              ifields-tabname = 'RFCDES'.
              ifields-fieldname = 'RFCDEST'.
              ifields-fieldtext = text-213.
              IF NOT dflt_rfc IS INITIAL.
                ifields-value = dflt_rfc.
              ENDIF.
              APPEND ifields.
            ENDIF.

            CLEAR userresponse.
            l_repid = sy-repid.
            CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
                 EXPORTING
                    formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
                      programname       = l_repid
                      popup_title       = text-211
                      ok_pushbuttontext = text-212
                 IMPORTING
                      returncode        = userresponse
                 TABLES
                      fields            = ifields
                 EXCEPTIONS
                      error_in_fields   = 1
                      OTHERS            = 2.

            IF sy-subrc <> 0.
              MESSAGE e208(00) WITH text-214.
            ENDIF.

            CHECK userresponse NE 'A'."#EC SAST_CI_GEN_CHECK
             "check to see user doesn't abort

            READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                        fieldname = 'RFCDEST'.

*          CHECK NOT ifields-value IS INITIAL.
            IF ifields-value IS INITIAL.
              MESSAGE w208(00) WITH text-215.
            ENDIF.
          SELECT SINGLE * FROM rfcdes WHERE rfcdest = ifields-value AND
                                              rfctype = '3'.
            IF sy-subrc EQ 0.
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
              CALL FUNCTION 'PRGN_SHOW_EDIT_AGR'
                  DESTINATION ifields-value
                   EXPORTING
                        agr_name = agr_name
               EXCEPTIONS
                 agr_not_found         = 1
                 SYSTEM_FAILURE        = 2
                 COMMUNICATION_FAILURE = 3
                 OTHERS              = 4 ."#EC SAST_CI_GEN_CHECK
              IF sy-subrc = 1.
                CLEAR pertext.
                CONCATENATE text-207 text-208
                           INTO pertext SEPARATED BY space.
                MESSAGE i208(00) WITH pertext.
              ELSEIF sy-subrc = 4.
                CONCATENATE text-209 text-208 text-210
                           INTO pertext SEPARATED BY space.
                MESSAGE i208(00) WITH pertext.
              ENDIF.
            ELSE.
              CLEAR pertext.
              CONCATENATE text-213 ifields-value text-216
                                       INTO pertext SEPARATED BY space.
              MESSAGE i208(00) WITH pertext.
            ENDIF.

          WHEN OTHERS.

        ENDCASE.


      ENDIF.
    WHEN 'PROFILE' OR 'COMP_PROF'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU02'.
      ELSE.
        SET PARAMETER ID 'XUP' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU02'.
      ENDIF.
  ENDCASE.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM user_double_click_on_sum                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click_on_sum USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.

  DATA:  l_contid TYPE /psyng/mchdr-contid,
         l_rsimu TYPE flag,
         l_simu TYPE flag,
         l_uname        LIKE sy-uname,
         l_parva        TYPE usr05-parva,
         l_sod          TYPE /psyng/swsodvers-vrsio.



  CASE r_ucomm.
    WHEN 'MITIGATE'.                   "Add/edit mitigation control
      PERFORM mitigate.

      EXIT.
    WHEN 'DEL_MIT'.                    "Delete mitigation control
      PERFORM delete_mit_assn.

      EXIT.

    WHEN 'FAILEDUSER'.
      PERFORM show_user_grp_cmp_invalid.
      EXIT.

    WHEN 'ROLEREMDET'.
      CALL SCREEN '0102' STARTING AT 10 10.
      EXIT.

  ENDCASE.

***** Drill Down to Mitigation Screen SE 3.1 Development ITEM NO C42-3
***** Code by Shekhar 17/09/2013

  CASE rs_selfield-fieldname.

    WHEN 'CONTID'.
      CHECK rs_selfield-value <> space.
      l_contid = rs_selfield-value.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
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
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.

    WHEN 'MIT_ICON'.
      READ TABLE output INDEX rs_selfield-tabindex.
      IF output-mit_icon IS INITIAL.
        MESSAGE e123 WITH output-bname output-swaudid.
      ENDIF.
      PERFORM show_mit_details USING output.
      EXIT.

    WHEN 'CONTID'.
      l_contid = rs_selfield-value.
      CHECK NOT l_contid IS INITIAL.
*--Read mitigation info
      READ TABLE output INDEX rs_selfield-tabindex.
      READ TABLE gt_mccauser WITH KEY userid = output-bname
                                 swaudid  = output-swaudid
                                 contid = output-contid.

*--Read RFC destination
      READ TABLE gt_rfcdes WITH KEY rfcoptions = gt_mccauser-rfcdest.
      IF sy-subrc <> 0.
        lt_remote_anal_rfc-rfcdest = 'LOCAL'.
      ENDIF.

      CALL FUNCTION '/PSYNG/SW_058'
           EXPORTING
                i_contid        = l_contid
                i_rfcdest       = lt_remote_anal_rfc-rfcdest
           EXCEPTIONS
                invalid_control = 1
                OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      EXIT.

    WHEN 'SIMU_AFTER'.
      READ TABLE output INDEX rs_selfield-tabindex.
      IF output-simu_after <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
         'This Critical Auth doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11)
         .
        EXIT.
      ELSE.
        READ TABLE output INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0.
        PERFORM detail_crit_auths.
        EXIT.
      ENDIF.

    WHEN 'SIMU_BEFORE'.
      READ TABLE output INDEX rs_selfield-tabindex.
      IF output-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This Critical Auth didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE output INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.

        IF bysimu = 'X'.
          l_simu = 'X'.
          CLEAR bysimu.
        ENDIF.

        PERFORM detail_crit_auths.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.
        IF l_simu = 'X'.
          bysimu = 'X'.
        ENDIF.
      ENDIF.
      EXIT.

    WHEN 'SWAUDID'.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF output-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
              'This Critical Auth doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      PERFORM detail_crit_auths.
      EXIT.

  ENDCASE.





ENDFORM.

*---------------------------------------------------------------------*
*       SUM_HEADER                                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*

FORM sum_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_exedate TYPE char10,
        lv_exetime(8) TYPE c,
        lv_average       TYPE i,
        c_tusercount(6)  TYPE c,
        c_usercount(6)   TYPE c,
        c_uniqueauthcount(6)   TYPE c,
        c_authcount(6)    type c,
        c_authcount_bs(6) type c,

        c_averagecon(4)  TYPE c,
        alv_grid_titl2   TYPE lvc_title.              "For ALV call
  STATICS : "lf_totals_counted TYPE flag,
            usercount TYPE i,    "Progress indicator flag
            lv_uniqueauthcount TYPE i,
            lv_cauthcount    TYPE i,
            lv_cauthcount_bs TYPE i,"beore simu
            l_msg_displayed TYPE flag,
            l_pages TYPE c,
            l_pgcnt TYPE i.

  DATA  : lv_tusercount TYPE i.
  tusercount = g_nr_users_analyzed.

*1STOUTPUT data
  DATA : lv_oldbname TYPE xubname.

  IF gf_totals_counted IS INITIAL.
    CLEAR: lv_oldbname, usercount, lv_average, lv_cauthcount.

    LOOP AT output.
      CHECK output-swaudid <> ' ' AND output-swaudid <> '----'.
      if byrsimu IS INITIAL AND bysimu IS INITIAL.
        lv_cauthcount = lv_cauthcount + 1.
      else.
        if output-simu_after = 'X'.
          lv_cauthcount = lv_cauthcount + 1.
        endif.
        if output-simu_before = 'X'.
          lv_cauthcount_bs = lv_cauthcount_bs + 1.
        endif.
      endif.
    ENDLOOP.
    DATA : lv_output_count_users LIKE TABLE OF output.
    IF lv_output_count_users[] IS INITIAL.
      lv_output_count_users[] = output[].
      SORT lv_output_count_users[] BY bname.
      DELETE lv_output_count_users WHERE swaudid = '----'.
      DELETE ADJACENT DUPLICATES FROM
        lv_output_count_users COMPARING bname.

    ENDIF.
    DESCRIBE TABLE lv_output_count_users LINES usercount.

    DATA : output_count_unique_auths LIKE TABLE OF output.
    IF output_count_unique_auths[] IS INITIAL.
      output_count_unique_auths[] = output[].
      SORT output_count_unique_auths[] BY bname swaudid.
      DELETE output_count_unique_auths WHERE swaudid = '----'.
      DELETE ADJACENT DUPLICATES FROM
        output_count_unique_auths COMPARING bname swaudid.

    ENDIF.
    DESCRIBE TABLE output_count_unique_auths LINES lv_uniqueauthcount.


    gf_totals_counted = 'X'.

  ENDIF.

  IF usercount > 0.
    lv_average      = lv_cauthcount / usercount.
  ELSE.
    lv_average = 0.
  ENDIF.
  c_usercount  = usercount.
  c_averagecon = lv_average.
  c_tusercount = tusercount.
  CONCATENATE c_tusercount 'user(s) analyzed.'(089)
              'Avg'(090) c_averagecon
              'Crit. Auth(s) in'(091)
              c_usercount 'user(s)'(092)
              INTO alv_grid_titl2 SEPARATED BY space.
  CONDENSE alv_grid_titl2.

*TITLE AREA
  wa-typ = 'H'.
  wa-info =
  'SW: Critical Authorizations User Analysis Results'' Summary'(084).
  APPEND wa TO header.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

*Date
  WRITE sy-datum TO lv_exedate.
  wa-typ = 'S'.
  wa-key = 'User & Date'(085).
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
                INTO lv_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user "sy-uname C0700
   'on'(086) lv_exedate lv_exetime
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.





  wa-typ = 'S'.
  wa-key = 'Summary:'(087).
  wa-info = alv_grid_titl2.
  APPEND wa TO header.

  IF xmc = 'X'.
    DATA : l_tot_conf TYPE i,
           l_tot_conf_c(8) TYPE c,
           l_tot_mit_c(8) TYPE c.

*  l_tot_conf = g_numres + g_nummit.
    l_tot_conf = lv_cauthcount.
    l_tot_conf_c = l_tot_conf.
    l_tot_mit_c = g_nummit.
    CONCATENATE l_tot_conf_c
    'Critical Auth.(s) out of which'(163)
    l_tot_mit_c
    'mitigated '(165)
    INTO wa-info SEPARATED BY space.
    CLEAR wa-key." = 'Summary:'(164).
    APPEND wa TO header.
  ENDIF.
  IF NOT remrfc[] IS INITIAL.
*--Unique auths
    c_uniqueauthcount = lv_uniqueauthcount.
    CONCATENATE c_uniqueauthcount
    'unique Critical Authorizations found for Users'(166)
    INTO  wa-info SEPARATED BY space.
    CLEAR wa-key."
    APPEND wa TO header.
  ENDIF.


  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    wa-typ = text-184.
    wa-key = text-185.
    CONDENSE l_pages NO-GAPS.
    wa-info = l_pages.
    APPEND wa TO header.
  ENDIF.

  IF bysimu = 'X' OR byrsimu = 'X'.
*--Before Simulation Numbers
    c_authcount    = lv_cauthcount.
    c_authcount_bs = lv_cauthcount_bs.

    wa-typ  = 'S'.
    wa-key  = 'Before simulation'(h38).
    concatenate c_authcount_bs  'Critical Auths'(h40)
    into wa-info separated by space .
    APPEND wa TO header.
*--After Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'After simulation'(h39).
    concatenate c_authcount 'Critical Auths'(h40)
    into wa-info separated by space .
    APPEND wa TO header.
  endif.



  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header
            i_logo             = 'Z_3SW_LOGO_JPG'.

*  **********************************
*--Only output messages for each page when not in background mode.
  IF ( sy-batch  IS INITIAL AND sy-binpt IS INITIAL )
     OR  l_msg_displayed IS INITIAL.
    IF gf_missing_auth_ugroup = space.
      IF g_mit_message IS INITIAL.
        MESSAGE s398(00) WITH
        'Analysis Complete.'(083).
      ENDIF.
    ELSE.
      MESSAGE s398(00) WITH
      'Analysis Complete.'(083)
      'Missing some usergroup authorizations'(013).
    ENDIF.
    IF gf_st_missing_auth = 'X'.
      MESSAGE w191(/psyng/sw).
    ENDIF.
    IF NOT gf_missing_auth_ugroup IS INITIAL.
      gf_auth_fail = 'X'.
      MESSAGE w190(/psyng/sw).
    ENDIF.
    l_msg_displayed = 'X'.
    COMMIT WORK.
  ENDIF.




ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: l_tabname  TYPE dd02l-tabname,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Get sod version default
*  GET PARAMETER ID '/PSYNG/VRSIO' FIELD sodvrsio.
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = sodvrsio.

  DATA: swconfig TYPE /psyng/swconfig.

*-- Show Composite profiles
  se_config_param 'USE_ROLES' swconfig-value.
  IF swconfig-value = 'N'.
    gf_showpcom = 'X'.
  ELSE.
    gf_showpcom = ' '.
  ENDIF.
  CLEAR swconfig.

*Update Scan Table
  CLEAR swconfig.
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.
  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSE.
    ustb = ' '.
  ENDIF.
  CLEAR swconfig.

*Valid & Dialog Users only
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
    exlckusr = 'X'.
    outvdate = 'X'.
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
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

*-- New Mitigation Assignment Check
  se_config_param 'MIT_ASGN_AUTH_CHECK' swconfig-value.
  IF swconfig-value = '2'.
    gf_use_sec_obj = 'X'.
  ELSE.
    gf_use_sec_obj = ' '.
  ENDIF.
  CLEAR swconfig.

*-- Show Composite Roles/Profiles Checked or unchecked by default
  se_config_param 'DFLT_SHOW_COMPOSITE' swconfig-value.
  IF gf_showpcom IS INITIAL.
    IF swconfig-value = 'Y'.
      showcomp = 'X'.
    ELSE.
      showcomp = ' '.
    ENDIF.
  ELSE.
    IF swconfig-value = 'Y'.
      showpcom = 'X'.
    ELSE.
      showpcom = ' '.
    ENDIF.
  ENDIF.

  CLEAR swconfig.


*-- ER Button

  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc = 0.
    se_config_param 'DFLT_INCLUDE_ER' swconfig-value.
    IF swconfig-value = 'Y'.
      erroles = 'X'.
    ELSE.
      erroles = ' '.
    ENDIF.
    CLEAR swconfig.
  ENDIF.

*--Central User ID search Help
*--Check what FM is configured for Central Userid information
  DATA : ls_fmname    TYPE rs38l_fnam,
         lf_visible   TYPE flag.


  se_config_param 'SW_CENTRAL_USR_FM' swconfig-value.
  IF NOT swconfig-value IS INITIAL.
    ls_fmname = swconfig-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      lf_visible = 'X'.
      gf_central_uid = 'X'.
    ENDIF.
  ENDIF.
  LOOP AT SCREEN.
    IF screen-group1 = 'CUS'.
      IF lf_visible = 'X'.
        screen-invisible = 0.
        screen-active   = 1.
      ELSE.
        screen-invisible = 1.
        screen-active   = 0.

      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

* Default RFC
  IF remrfc[] IS INITIAL.
    IF sy-saprl >= '620'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ELSE.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ENDIF.

*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv
*           FROM (l_tabname)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO remrfc.
      remrfc-option = lt_tvarv-opti.
      APPEND remrfc.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_initial_config

*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report.


  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = curr_variant
            vari_desc     = vari_desc
       TABLES
            vari_contents = vari_contents
            vari_text     = vari_text.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = text-t12  "'Critical Authorizations'
              in_repvarnt = curr_variant
              in_report   = curr_report.
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
FORM get_next_variant_id.
*  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

*  SELECT variant INTO variant FROM varid WHERE report = sy-repid AND
*                           variant LIKE '/PSYNG/%'
*    AND NOT   variant LIKE '/PSYNG/Z%'
*  ORDER BY variant DESCENDING.
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

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.

ENDFORM.                    " get_next_variant_id

*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.

  REFRESH : irsparams.
*Select options


  LOOP AT pbname.
    irsparams-selname = 'PBNAME'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING pbname TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_class.
    irsparams-selname = 'S_CLASS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_class TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT paudid.
    irsparams-selname = 'PAUDID'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING paudid TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_imp.
    irsparams-selname = 'S_IMP'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_imp TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_owner.
    irsparams-selname = 'S_OWNER'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_owner TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_barea.
    irsparams-selname = 'S_BAREA'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_barea TO irsparams.
    APPEND irsparams.
  ENDLOOP.



  LOOP AT remrfc.
    irsparams-selname = 'REMRFC'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING remrfc TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT remrfc.
    irsparams-selname = 'REMRFC'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING remrfc TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT simurols.
    irsparams-selname = 'SIMUROLS'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING simurols TO irsparams.
    APPEND irsparams.
  ENDLOOP.
* **************************************
*Parameters

  irsparams-selname = 'WP'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = wp.
  APPEND irsparams.

  irsparams-selname = 'PGROUP'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = pgroup.
  APPEND irsparams.

  irsparams-selname = 'PSERVER'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = pserver.
  APPEND irsparams.

  irsparams-selname = 'SPECGRP'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = specgrp.
  APPEND irsparams.

  irsparams-selname = 'SPECSRV'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = specsrv.
  APPEND irsparams.

  irsparams-selname = 'ROLERFC'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = rolerfc.
  APPEND irsparams.


  irsparams-selname = 'ONLYREM'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = onlyrem.
  APPEND irsparams.

  irsparams-selname = 'ERROLES'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = erroles.
  APPEND irsparams.

  irsparams-selname = 'EXCL_ER'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = excl_er.
  APPEND irsparams.


  irsparams-selname = 'BYSIMU'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = bysimu.
  APPEND irsparams.

  irsparams-selname = 'SHOWCOMP'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = showcomp.
  APPEND irsparams.

  irsparams-selname = 'USTB'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = ustb.
  APPEND irsparams.


  irsparams-selname = 'SODVRSIO'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = sodvrsio.
  APPEND irsparams.

  irsparams-selname = 'ONLYREM'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = onlyrem.
  APPEND irsparams.

  irsparams-selname  = 'XMC'.
  irsparams-kind     = 'P'.
  irsparams-sign     = 'I'.
  irsparams-option   = 'EQ'.
  irsparams-low      = xmc.
  APPEND irsparams.


  irsparams-selname = 'DET'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = det.
  APPEND irsparams.

  irsparams-selname = 'SUM'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = sum.
  APPEND irsparams.

  irsparams-selname = 'VALIDUSR'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = validusr.
  APPEND irsparams.

  irsparams-selname = 'EXLCKUSR'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = exlckusr.
  APPEND irsparams.

  irsparams-selname = 'OUTVDATE'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = outvdate.
  APPEND irsparams.

  irsparams-selname = 'USTB'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = ustb.
  APPEND irsparams.

  irsparams-selname = 'ODT'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = odt.
  APPEND irsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  load_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REMRFC  text
*      -->P_LT_REMOTE_ANAL_RFC  text
*----------------------------------------------------------------------*
FORM load_rfc
    TABLES
      it_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_rfc.
  ENDIF.

  SORT et_rfcdes BY rfcdest.
  LOOP AT et_rfcdes.
    FREE : lt_dest.
    lt_dest-rfcdest = et_rfcdes-rfcdest.
    APPEND lt_dest.
    CALL FUNCTION 'RFC_WALK_THRU_TEST'
         EXPORTING
              test_in      = l_rfc_test
         TABLES
              destinations = lt_dest
              log          = lt_rfc_log.
    LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
      PERFORM report_rfc_error USING
      lt_rfc_log-rfcdest lt_rfc_log-rfclog.
    ENDLOOP.
  ENDLOOP.

  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          'Error calling system:'(e05)
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          'Error calling system:'(e05)
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
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
*&      Form  load_local_swauds
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_LOCAL_SWAUDHDR  text
*      -->P_LT_LOCAL_SCWAUDC  text
*----------------------------------------------------------------------*
FORM load_local_swauds TABLES
    lt_conflict  STRUCTURE /psyng/conflict
    lt_functtran STRUCTURE /psyng/functtran
    lt_faobj     STRUCTURE /psyng/faobj2
    lt_confdet   STRUCTURE /psyng/confdet
    lt_local_swaudhdr STRUCTURE /psyng/swaudhdr
    lt_local_scwaudc  STRUCTURE /psyng/swaudc2
    lt_enh_tcodes STRUCTURE /psyng/sw_par_tcode_output.
  DATA : l_numtcodes TYPE i.
  FIELD-SYMBOLS : <swaudc> TYPE /psyng/swaudc2.
*  data : lt_local_swaudhdr type table of /psyng/swaudhdr
*          with header line,
*         lt_local_scwaudc type table of /psyng/swaudc2
*         with header line.
  SELECT * FROM /psyng/swaudhdr
            INTO TABLE lt_local_swaudhdr
            WHERE swaudid IN paudid AND
                  imp IN s_imp AND
                  owner IN s_owner AND
                  busarea IN s_barea AND
                  vrsio = sodvrsio.

  SORT : lt_local_swaudhdr.
*--DHORIONS 2014/06/11 - Delete empty records if present
  DELETE lt_local_swaudhdr WHERE swaudid IS initial.

  IF NOT lt_local_swaudhdr[] IS INITIAL.
    SELECT * FROM /psyng/swaudc2
     INTO  TABLE lt_local_scwaudc
     FOR ALL ENTRIES IN lt_local_swaudhdr
     WHERE vrsio = sodvrsio
     AND swaudid = lt_local_swaudhdr-swaudid
     AND tcode   = lt_local_swaudhdr-tcode
     AND field <> ''. "#EC SAST_CI_GEN_CHECK
  ENDIF.

  SORT lt_local_scwaudc BY swaudid.

*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.
  LOOP AT lt_local_swaudhdr.
    lt_conflict-conid       = lt_local_swaudhdr-swaudid.
    APPEND lt_conflict.
    lt_confdet-conid        = lt_local_swaudhdr-swaudid.
    lt_confdet-functionid   = lt_local_swaudhdr-swaudid.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_local_swaudhdr-swaudid.
    IF lt_local_swaudhdr-tcode = '*'.
*--Case 2975 : Improve performance when tcode = * and
*              exactly 1 tcode is in
*              the critical authorization.
      l_numtcodes = 0.
      LOOP AT lt_local_scwaudc WHERE
                               swaudid = lt_local_swaudhdr-swaudid AND
                               object  = 'S_TCODE' AND
                               field   = 'TCD' AND
                               val_to  = ''.
        IF lt_local_scwaudc-val_from NS '*'.
          ADD 1 TO l_numtcodes.
          lt_functtran-tcode = lt_local_scwaudc-val_from.
        ELSE.
*--more then 1
          l_numtcodes = 2.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF l_numtcodes <> 1.
        ADD 1 TO l_placeholder_counter.
        CONCATENATE '/PSYNG/-SWAUD' l_placeholder_counter
        INTO lt_functtran-tcode.
      ENDIF.
    ELSE.
      lt_functtran-tcode    = lt_local_swaudhdr-tcode.
*--Also update the details
      LOOP AT lt_local_scwaudc ASSIGNING <swaudc>
                               WHERE
                               swaudid = lt_local_swaudhdr-swaudid.
        <swaudc>-tcode =  lt_local_swaudhdr-tcode.
      ENDLOOP.
    ENDIF.
    APPEND lt_functtran.
    LOOP AT lt_local_scwaudc WHERE swaudid = lt_local_swaudhdr-swaudid.
      MOVE-CORRESPONDING lt_local_scwaudc TO lt_faobj.
*--Case 2975 : Improve performance by converting ranges where
*              high = low
*              to exact values.
      IF lt_faobj-val_from = lt_faobj-val_to.
        CLEAR lt_faobj-val_to.
      ENDIF.
      lt_faobj-funid = lt_functtran-functionid.
      lt_faobj-tcode = lt_functtran-tcode.
      APPEND lt_faobj.
    ENDLOOP.
  ENDLOOP.
*Tcode enhancement
  IF p_enhanc = 'X' AND det = 'X'."Summary analysis will
    "automatically do enhancement
    CALL FUNCTION '/PSYNG/SW_065'
         EXPORTING
              i_vrsio      = sodvrsio
         TABLES
              it_functtran = lt_functtran
              it_faobj     = lt_faobj
              et_tcodes    = lt_enh_tcodes.
  ENDIF.

ENDFORM.                    " load_local_swauds
*&---------------------------------------------------------------------*
*&      Form  f4_company
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_COMP_LOW  text
*----------------------------------------------------------------------*
FORM f4_company USING    fieldname
                CHANGING e_comp
                .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid LIKE sy-repid,
         l_dynnr LIKE sy-dynnr.
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_config_fm-value.
  IF NOT ls_config_fm-value IS INITIAL.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
       EXPORTING
            i_dynpro    = l_dynnr
            i_dynpprog  = l_repid
            i_fieldname = fieldname
       CHANGING
            e_company   = e_comp.

ENDFORM.                    " f4_company
*&---------------------------------------------------------------------*
*&      Form  f4_department
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_DEPART_HIGH  text
*----------------------------------------------------------------------*
FORM f4_department  USING    fieldname
                    CHANGING e_department .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid LIKE sy-repid,
         l_dynnr LIKE sy-dynnr.

*--Check what FM is configured for search help for department
  se_config_param 'SW_DEPART_SHLP_FM' ls_config_fm-value.
  IF NOT ls_config_fm-value IS INITIAL.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_077'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.

  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
       EXPORTING
            i_dynpro     = l_dynnr
            i_dynpprog   = l_repid
            i_fieldname  = fieldname
       CHANGING
            e_department = e_department.
ENDFORM.                    " f4_department
*&---------------------------------------------------------------------*
*&      Form  f4_central_uid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0065   text
*      <--P_S_ACCNT_HIGH  text
*----------------------------------------------------------------------*
FORM f4_central_uid USING    fieldname
                CHANGING e_accnt.

  DATA :  ls_config_fm TYPE /psyng/swconfig,
          ls_fmname    TYPE rs38l_fnam,
          l_repid LIKE sy-repid,
          l_dynnr LIKE sy-dynnr.


  CLEAR ls_config_fm.
*--Check what FM is configured for Central Userid information

  se_config_param 'SW_CENTRAL_USR_FM' ls_config_fm-value.

  IF NOT ls_config_fm-value IS INITIAL.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_CENTRAL_USR_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ELSE.
      l_repid = sy-repid.
      l_dynnr = sy-dynnr.
*Get Central Userid information as search help
      CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
           EXPORTING
                i_dynpro       = l_dynnr
                i_dynpprog     = l_repid
                i_fieldname    = fieldname
                if_search_help = 'X'
           CHANGING
                e_central_uid  = e_accnt.

    ENDIF.
  ENDIF.

ENDFORM.                    " f4_central_uid
*&---------------------------------------------------------------------*
*&      Form  get_comp_name
*&---------------------------------------------------------------------*
*       Get user's company name from company ID
*----------------------------------------------------------------------*
*      <->I_COMPANY    Company ID
*      <--E_COMP_NAME  Company Name
*----------------------------------------------------------------------*
FORM get_comp_name CHANGING i_company   "TYPE  /psyng/sw_uinfo-company
                            e_comp_name ."TYPE  /psyng/sw_uinfo-company.

  TYPES: BEGIN OF t_comp,
           comp TYPE /psyng/mcauditor-company,
           name TYPE /psyng/mcauditor-company,
         END OF t_comp.

  DATA: l_value  TYPE /psyng/swconfig-value,
        l_fmname TYPE rs38l_fnam,
        ls_comp  TYPE t_comp.

  STATICS: lt_comp TYPE HASHED TABLE OF t_comp WITH UNIQUE KEY comp,
           l_fm_checked TYPE flag.

  CHECK l_fm_checked IS INITIAL OR gf_company_longtext = 'X'.
  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
  se_config_param 'SW_MGMT_COMP_NAME_FM' l_value.
  IF NOT l_value IS INITIAL.
    l_fmname = l_value.
    IF NOT l_fmname IS INITIAL.
      CALL FUNCTION 'FUNCTION_EXISTS'
           EXPORTING
                funcname           = l_fmname
           EXCEPTIONS
                function_not_exist = 1
                OTHERS             = 2.
      IF sy-subrc <> 0.
*       Configured FM does not exist, use none
        CLEAR l_fmname.
        MESSAGE s113(/psyng/sw) WITH
                'Cannot determine SW_MGMT_COMP_NAME_FM with FM '
                l_fmname '. FM doesn''t exist'.
      ELSE.
        gf_company_longtext = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    EXIT.
    CLEAR gf_company_longtext.
  ENDIF.
  IF NOT l_fmname IS INITIAL.
    CALL FUNCTION l_fmname "#EC PATHLOCK_CI_DYN_ACCES
         EXPORTING
              i_company   = i_company
         IMPORTING
              e_comp_name = e_comp_name.

    ls_comp-comp = i_company.
    ls_comp-name = e_comp_name.
    INSERT ls_comp INTO TABLE lt_comp.
    l_fm_checked = 'X'.
  ENDIF.
ENDFORM.                    " get_comp_name
*&---------------------------------------------------------------------*
*&      Form  disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM disp_total_servers_for_sel.
  DATA: lv_title(20).
  DATA lv_btchost LIKE msxxlist-host.
  MOVE text-064 TO lv_title.

  CALL FUNCTION 'SLWY_SELECT_BTC_SERVER'
       EXPORTING
            select_title   = lv_title
       CHANGING
            btc_host       = lv_btchost
            btc_server     = pserver
       EXCEPTIONS
            no_server_list = 1
            wrong_host     = 2
            wrong_choice   = 3
            OTHERS         = 4.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*&      Form  get_server_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_server_name.
  CALL FUNCTION 'TH_GET_ACTIVE_SERVER'
       EXPORTING
            tabname        = ''
            local_tabname  = ''
       IMPORTING
            server         = pserver
       EXCEPTIONS
            no_server_list = 1
            no_server      = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  specsrv = 'X'.
  CLEAR : specgrp , defgrp.
ENDFORM.                    " get_server_name
*---------------------------------------------------------------------*
*       FORM check_input                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM check_input.
  DATA: BEGIN OF lt_dest OCCURS 0,
            rfcdest TYPE rfcdes-rfcdest,
          END OF lt_dest,
          lt_dest2 LIKE TABLE OF lt_dest WITH HEADER LINE,
         lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
         l_rfc_test TYPE rfctest,
         lt1_dest LIKE TABLE OF lt_dest WITH HEADER LINE,
         lt_remrfc TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
LINE.

*--Check paralell processing info
  IF specsrv = 'X'.
    CLEAR pgroup.
  ENDIF.
  IF specgrp = 'X'.
    CLEAR pserver.
  ENDIF.
  IF defgrp = 'X'.
    CLEAR : pgroup, pserver.
  ENDIF.
  DATA : l_req_wp TYPE num1.
  l_req_wp = wp.
  CALL FUNCTION '/PSYNG/BASIS_RFC_CHECK'
       EXPORTING
            i_pserver = pserver
            i_group   = pgroup
            i_no_msg  = 'X'
       CHANGING
            wp        = wp.
  IF l_req_wp > wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE w398(00) WITH text-115 wp text-116.
  ENDIF.

  RANGES: lr_dest FOR rfcdes-rfcdest.

  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'GPSV'.
    PERFORM get_server_name.
  ENDIF.
  IF wp GT max_wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE e208(00) WITH text-117.
  ENDIF.
  PERFORM check_server_is_valid.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
    EXIT.
  ENDIF.


* Check RFC destinations
*  IF  bysimu = 'X'
*  OR  byrsimu = 'X'
*  OR NOT remrfc[] IS INITIAL.
*
*
*
*    APPEND LINES OF remrfc[] TO lr_dest.
*
*    IF NOT lr_dest[] IS INITIAL.
*      SELECT rfcdest INTO TABLE lt_dest FROM rfcdes
*                WHERE rfcdest IN lr_dest.
*      IF sy-subrc NE 0.
*        MESSAGE i135 WITH 'Invalid RFC Destination(s)'(196).
*        LEAVE LIST-PROCESSING.
*      ENDIF.
*    ENDIF.
*
*
**--Role Simulation Destinations
*    lt_dest-rfcdest = ar_rfcd1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd3.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd4.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs3.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs4.
*    APPEND lt_dest.
**--Role Removal  Simulation Destinations
*    lt_dest-rfcdest    = rr_rfc_1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = rr_rfc_2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = rr_rfc_3.
*    APPEND lt_dest.
*
*    SORT lt_dest BY rfcdest.
*    LOOP AT lt_dest WHERE rfcdest <> '' AND rfcdest <> 'LOCAL'.
*      CLEAR lt_dest2.
*      APPEND lt_dest TO lt_dest2.
*      FREE : lt_rfc_log.
*      CALL FUNCTION 'RFC_WALK_THRU_TEST'
*        EXPORTING
*          test_in            = l_rfc_test
**         IMPORTING
**           TEST_OUT           =
*        TABLES
*          destinations       = lt_dest2
*          log                = lt_rfc_log.
*      LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*        PERFORM report_rfc_error USING
*        lt_rfc_log-rfcdest lt_rfc_log-rfclog .
*      ENDLOOP.
*      lt_remrfc-sign = 'I'.
*      lt_remrfc-option = 'EQ'.
*      lt_remrfc-low = lt_dest-rfcdest.
*      APPEND lt_remrfc.
*    ENDLOOP.
*  ENDIF.
*
*
*  FREE : gt_rfcdest.
*  PERFORM load_role_rfc
*              TABLES
*                 lt_remrfc
*                 gt_rfcdest.

*
*  LOOP AT lt_dest2.
*    gt_rfcdest-rfcdest = lt_dest2-rfcdest.
*    APPEND gt_rfcdest.
*  ENDLOOP.



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
    'Please enter role(s) for simulation'(181).
  ENDIF.









** Check RFC destinations
*  IF ( bysimu = 'X' AND NOT rolerfc IS INITIAL )
*  OR NOT remrfc[] IS INITIAL.
*
*    APPEND LINES OF remrfc TO lr_dest.
*    IF bysimu = 'X' AND NOT rolerfc IS INITIAL.
*      lr_dest-sign   = 'I'.
*      lr_dest-option = 'EQ'.
*      lr_dest-low    = rolerfc.
*      APPEND lr_dest.
*    ENDIF.
*
*    LOOP AT lr_dest.
*      CLEAR lt1_dest-rfcdest.
*      SELECT SINGLE rfcdest INTO lt1_dest-rfcdest FROM rfcdes
*             WHERE rfcdest = lr_dest-low.
*      IF sy-subrc = 0.
*        CLEAR lt1_dest-rfcdest.
*        CHECK NOT lr_dest-high IS INITIAL.
*        SELECT SINGLE rfcdest INTO lt1_dest-rfcdest FROM rfcdes
*               WHERE rfcdest = lr_dest-high.
*        IF sy-subrc <> 0.
*          MESSAGE e004(sr).
*        ENDIF.
*      ELSE.
*        MESSAGE e004(sr).
*      ENDIF.
*    ENDLOOP.
*
*    SELECT rfcdest INTO TABLE lt_dest FROM rfcdes
*              WHERE rfcdest IN lr_dest.
*
*    LOOP AT lt_dest.
*      CLEAR lt_dest2.
*      APPEND lt_dest TO lt_dest2.
*      FREE : lt_rfc_log.
*      CALL FUNCTION 'RFC_WALK_THRU_TEST'
*        EXPORTING
*          test_in            = l_rfc_test
**         IMPORTING
**           TEST_OUT           =
*        TABLES
*          destinations       = lt_dest2
*          log                = lt_rfc_log.
*      LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*        PERFORM report_rfc_error USING
*        lt_rfc_log-rfcdest lt_rfc_log-rfclog.
*      ENDLOOP.
*    ENDLOOP.
*  ENDIF.


  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.
*
*  IF bysimu = 'X' AND simurols[] IS INITIAL AND
*  ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' ).
*    MESSAGE e140(/psyng/sw) WITH
*    'Please enter role(s) for simulation'(181).
*    IF sy-batch = 'X'.
*      exit_proc = 'Y'.
*    ENDIF.
**    LEAVE LIST-PROCESSING.
*  ENDIF.



ENDFORM.                    " check_input
*&---------------------------------------------------------------------*
*&      Form  check_server_is_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_server_is_valid.
  DATA: ilist TYPE STANDARD TABLE OF msxxlist WITH HEADER LINE.
  DATA: srvexist, messagetxt(80).

  CHECK NOT pserver IS INITIAL.
  CALL FUNCTION 'TH_SERVER_LIST'
*   EXPORTING
*     SERVICES             = 255
    TABLES
      list                 = ilist
   EXCEPTIONS
     no_server_list       = 1
     OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT ilist.
    CHECK ilist-name = pserver.
    srvexist = 'Y'.
  ENDLOOP.
  CONCATENATE text-065 pserver text-066
              INTO messagetxt SEPARATED BY space.
  IF srvexist IS INITIAL.
    SET CURSOR FIELD 'PSERVER'.
    MESSAGE e208(00) WITH messagetxt.
  ENDIF.
ENDFORM.                    " check_server_is_valid
*&---------------------------------------------------------------------*
*&      Form  disp_total_server_groups
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM disp_total_server_groups.
  DATA BEGIN OF f4ftab OCCURS 0.
          INCLUDE STRUCTURE help_value.
  DATA END OF f4ftab.
  DATA:
    BEGIN OF f4vtab OCCURS 0,
      line(100),
    END OF f4vtab.

  REFRESH f4ftab.
  REFRESH f4vtab.

  SELECT classname FROM rzllitab INTO TABLE f4vtab
                   WHERE grouptype = 'S'.

  SORT f4vtab.
  DELETE ADJACENT DUPLICATES FROM f4vtab.
  f4ftab-tabname    = 'RZLLITAB'.
  f4ftab-fieldname  = 'CLASSNAME'.
  f4ftab-selectflag = 'X'.
  APPEND f4ftab.
  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       IMPORTING
            select_value              = pgroup
       TABLES
            fields                    = f4ftab
            valuetab                  = f4vtab
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
*BOC:HBHALLA (04/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Table field not listed in the Dict'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'During selection, only transfer of'.
             WHEN 3.
                MESSAGE s002(/psyng/sw)
             WITH 'No field selected for transfer'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)

ENDFORM.                    " disp_total_server_groups

*&---------------------------------------------------------------------*
*&      Form  check_resources
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_WP  text
*      -->P_I_PSERVER  text
*----------------------------------------------------------------------*
FORM check_resources
  CHANGING
  i_pserver TYPE msxxlist-name
  i_group   TYPE rzlli_apcl
  i_wp TYPE num1.

  CALL FUNCTION '/PSYNG/BASIS_RFC_CHECK'
       EXPORTING
            i_pserver           = i_pserver
            i_group             = i_group
       CHANGING
            wp                  = i_wp
       EXCEPTIONS
            use_group_or_server = 1
            OTHERS              = 2.
  IF sy-subrc <> 0.
    MESSAGE w398(00) WITH
    'Wrong parameters : use only RFC group OR server'(w03).
    i_wp = 0.
  ENDIF.
ENDFORM.                    " check_resources
*&---------------------------------------------------------------------*
*&      Form  mitigate
*&---------------------------------------------------------------------*
*       Edit mitigation assignments
*----------------------------------------------------------------------*
FORM mitigate.
  DATA:  lt_mcuser     TYPE TABLE OF /psyng/mitigation_assignment
                       WITH HEADER LINE,
         ls_mcuser     TYPE /psyng/mitigation_assignment,
         lt_users      TYPE TABLE OF /psyng/sw_sel_opts_xubname
                       WITH HEADER LINE,
         lt_auds       TYPE TABLE OF /psyng/range_swaudid
                       WITH HEADER LINE,
         lt_mcuser_all TYPE TABLE OF /psyng/mitigation_assignment,
         lf_noconf_msg TYPE /psyng/bapiflagx,
         lt_sw_uinfo   TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         l_local_system TYPE rfcdes,
         l_parent_agr TYPE agr_define-agr_name,
         lt_mccarole TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
         lt_uinfo_mit TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER
LINE,
         lt_simu_roles_for_mit TYPE TABLE OF /psyng/sw_sod_remote_roles
                                    WITH HEADER LINE.
  RANGES lt_agr_range FOR agr_define-agr_name.
  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu WITH
  HEADER LINE,
  lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_usgrp TYPE TABLE OF usgrp WITH HEADER LINE,
  lf_display TYPE /psyng/bapiflagx.




*  REFRESH lt_remote_anal_rfc.

  CONCATENATE sy-sysid sy-mandt INTO l_local_system .
  lt_users-sign   = lt_auds-sign   = 'I'.
  lt_users-option = lt_auds-option = 'EQ'.
  LOOP AT output WHERE sel = 'X'.
    IF output-swaudid = 'ALL'.
      MESSAGE e019.
    ENDIF.

    IF gf_use_sec_obj = 'X'.
      READ TABLE lt_usgrp WITH KEY usergroup = output-class.
      IF sy-subrc NE 0.
*-- Check Create/Modify Authority
        IF NOT output-class IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
       ID 'ACTVT' FIELD '22'
       ID 'CLASS' FIELD output-class
       ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
*       ID 'Y&SW_CONID' DUMMY "(--)BOC UMITTAL SE VF scan-25/11/2024
       ID 'Y&SW_SWAUD' FIELD '' "(++)BOC UMITTAL SE VF scan-25/11/2024
       ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc NE 0.
    AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
         ID 'ACTVT' FIELD '23'
         ID 'CLASS' FIELD output-class
         ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
         ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
*        ID 'Y&SW_CONID' DUMMY "(--)BOC UMITTAL SE VF scan-25/11/2024
         ID 'Y&SW_SWAUD' FIELD '' "(++)BOC UMITTAL SE VF scan-25/11/2024
         ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
            IF sy-subrc NE 0.
              lt_usgrp-usergroup = output-class.
              APPEND lt_usgrp.
              MESSAGE i108 WITH
              'mitigate users of User group : ' output-class.
              CONTINUE.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    READ TABLE lt_usgrp WITH KEY usergroup = output-class.
    CHECK sy-subrc NE 0.

*    CHECK output-rfcdest = l_local_system.
    lt_users-low = output-bname.
    APPEND lt_users.
    lt_auds-low = output-swaudid.
    APPEND lt_auds.

    lt_remote_anal_rfc-rfcdest = output-rfcdest.
    APPEND lt_remote_anal_rfc.

  ENDLOOP.

  CHECK NOT lt_users[] IS INITIAL.

  SORT lt_remote_anal_rfc BY rfcdest.
  DELETE ADJACENT DUPLICATES FROM lt_remote_anal_rfc COMPARING rfcdest.
* Reload mitigations
  ls_mcuser-vrsio = sodvrsio.
*  only local assignments
  LOOP AT lt_remote_anal_rfc.
    IF lt_remote_anal_rfc-rfcdest = l_local_system OR
       lt_remote_anal_rfc-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_096'
           EXPORTING
                i_vrsio      = sodvrsio
                i_start_date = '00000000'
                i_end_date   = '00000000'
           TABLES
                it_users     = lt_users
                it_auds      = lt_auds
                et_mcusers   = lt_mcuser
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             OTHERS     = 1.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)
    ELSE.
      CALL FUNCTION '/PSYNG/SW_096'
           DESTINATION lt_remote_anal_rfc-rfcdest
           EXPORTING
                i_vrsio      = sodvrsio
                i_start_date = '00000000'
                i_end_date   = '00000000'
           TABLES
                it_users     = lt_users
                it_auds      = lt_auds
                et_mcusers   = lt_mcuser
                 EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3."#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e04
            lt_remote_anal_rfc-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e04
            lt_remote_anal_rfc-rfcdest.
        ENDCASE.
        COMMIT WORK.
      ENDIF.
    ENDIF.

    APPEND LINES OF lt_mcuser TO lt_mcuser_all.
    REFRESH lt_mcuser.

  ENDLOOP.

  CLEAR lf_noconf_msg.
  LOOP AT output WHERE sel = 'X'.
    IF output-swaudid = '----'.
      IF lf_noconf_msg IS INITIAL.
        MESSAGE i021.
        lf_noconf_msg = 'X'.
      ENDIF.
      CONTINUE.
    ENDIF.


    LOOP AT lt_mcuser_all INTO lt_mcuser
            WHERE userid  = output-bname
              AND swaudid = output-swaudid
              AND rfcdest = output-rfcdest
              AND vrsio   = sodvrsio.
*      and type = '3'.
      APPEND lt_mcuser.
    ENDLOOP.


*   Check if there are any records from the present or future

    SORT lt_mcuser BY userid swaudid vrsio rfcdest to_date.
    LOOP AT lt_mcuser WHERE userid   = output-bname
                            AND swaudid  = output-swaudid
                            AND vrsio    = sodvrsio
                            AND rfcdest = output-rfcdest
                            AND to_date >= sy-datum
                            AND type = 3.
      EXIT.
    ENDLOOP.

    IF sy-subrc <> 0.
      CLEAR ls_mcuser.

      ls_mcuser-vrsio = sodvrsio.
**      CONCATENATE sy-sysid sy-mandt INTO ls_mcuser-rfcdest
      ls_mcuser-rfcdest = output-rfcdest.
      ls_mcuser-swaudid = output-swaudid.
      ls_mcuser-userid  = output-bname.
      ls_mcuser-type    = '3'.
      IF output-mit_icon = '@EK@'.
        ls_mcuser-contid = output-contid.
*      ls_mcuser-CONID =  output-CONID.
        ls_mcuser-auditor = output-auditor.
        ls_mcuser-from_date = output-from_date.
        ls_mcuser-to_date = output-to_date .
      ENDIF.

      COLLECT ls_mcuser INTO lt_mcuser.
    ENDIF.
  ENDLOOP.

  IF sy-subrc <> 0 OR lt_mcuser[] IS INITIAL.
    MESSAGE e146.
  ENDIF.

* get all users and their companies as they are defined (locally or
* remotely) and displayed in output
  CLEAR lt_sw_uinfo.
  REFRESH lt_sw_uinfo.
  LOOP AT output WHERE sel = 'X'.
    AT NEW bname.
      lt_sw_uinfo-bname = output-bname.
*      lt_sw_uinfo-company = output-company.
*Compshort contains company ID, while company field contains long text

* 5/16/2013 SSANGHA Start of insertion
      lt_sw_uinfo-company = output-compshort.
* 5/16/2013 SSANGHA end of insertion



      APPEND lt_sw_uinfo.
    ENDAT.
  ENDLOOP.

  SORT lt_sw_uinfo BY bname.

  DELETE ADJACENT DUPLICATES FROM lt_sw_uinfo COMPARING bname.

*    IF gf_use_sec_obj = 'X'.
**--2 Means Call from CA user report
*    lf_display = '2'.
*  ELSE.
*    CLEAR lf_display.
*  ENDIF.


  CALL FUNCTION '/PSYNG/SW_076'
       EXPORTING
            if_display      = lf_display
            IF_UPD_SCAN_TAB = ustb
            if_show_criauth = 'X'
            if_call_from_report = 'X'
*--Dhorions : if_maint_all is for maintaining expired mitigations
*             from th report we only want active and future ones
*            if_maint_all    = 'X'
       TABLES
            it_mcuser       = lt_mcuser
            it_rfcdest      = lt_remote_anal_rfc
            it_sw_uinfo     = lt_sw_uinfo.

* Reload mitigations
  ls_mcuser-vrsio = sodvrsio.
  REFRESH : lt_mcuser_all[]. "lt_mcuser[].
  IF lt_remote_anal_rfc[] IS INITIAL.
    APPEND lt_remote_anal_rfc.
  ENDIF.
  LOOP AT lt_remote_anal_rfc.

    IF lt_remote_anal_rfc-rfcdest = l_local_system OR
       lt_remote_anal_rfc-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_096'
           EXPORTING
                i_vrsio      = sodvrsio
                i_start_date = '00000000'
                i_end_date   = '00000000'
           TABLES
                it_users     = lt_users
                it_auds      = lt_auds
                et_mcusers   = lt_mcuser.
    ELSE.
      CALL FUNCTION '/PSYNG/SW_096'
           DESTINATION lt_remote_anal_rfc-rfcdest
           EXPORTING
                i_vrsio      = sodvrsio
                i_start_date = '00000000'
                i_end_date   = '00000000'
           TABLES
                it_users     = lt_users
                it_auds      = lt_auds
                et_mcusers   = lt_mcuser
                EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e04
            lt_remote_anal_rfc-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e04
            lt_remote_anal_rfc-rfcdest.
        ENDCASE.
        COMMIT WORK.
      ENDIF.
    ENDIF.

    APPEND LINES OF lt_mcuser TO lt_mcuser_all.
    REFRESH lt_mcuser.
*    DELETE lt_users INDEX sy-tabix.
*    DELETE lt_auds INDEX sy-tabix.
  ENDLOOP.
  lt_mcuser[] = lt_mcuser_all[].

*--Reflect the changes in the output
  SORT lt_mcuser BY userid swaudid type contid DESCENDING.
  LOOP AT output WHERE sel = 'X'.
    DELETE gt_mccauser WHERE userid  = output-bname
                         AND swaudid = output-swaudid
                         AND vrsio   = sodvrsio
                         AND type = 3.
*--Store all mitigations in memory (including future ones)
    LOOP AT lt_mcuser WHERE userid  = output-bname
                        AND swaudid = output-swaudid.
      READ TABLE gt_mccauser WITH KEY  rfcdest   = lt_mcuser-rfcdest
                                       contid    = lt_mcuser-contid
                                       conid     = lt_mcuser-conid
                                       userid    = lt_mcuser-userid
                                       vrsio     = lt_mcuser-vrsio
                                       auditor   = lt_mcuser-auditor
                                       from_date = lt_mcuser-from_date
                                       to_date   = lt_mcuser-to_date
                                       approved  = lt_mcuser-approved
                                       type      = lt_mcuser-type
                                       class     = lt_mcuser-class
                                       agr_name  = lt_mcuser-agr_name
                                       swaudid   = lt_mcuser-swaudid.
      IF sy-subrc <> 0.
        MOVE-CORRESPONDING lt_mcuser TO gt_mccauser.
        APPEND gt_mccauser.
      ENDIF.
    ENDLOOP.
*--Show all current mitigations on screen
    LOOP AT lt_mcuser WHERE userid     = output-bname
                        AND swaudid    = output-swaudid
                        AND from_date <= sy-datum
                        AND to_date   >= sy-datum
                        AND rfcdest    = output-rfcdest.
*--DHORIONS 2013/05/24 : This isn't necessary and didn't take dates into
* account
*      READ TABLE lt_mcuser WITH KEY userid = output-bname
*                                    swaudid = output-swaudid
*                                    rfcdest = output-rfcdest.
*
      output-contid    = lt_mcuser-contid.
      output-auditor   = lt_mcuser-auditor.
      output-from_date = lt_mcuser-from_date.
      output-to_date   = lt_mcuser-to_date.
      CASE lt_mcuser-type.
        WHEN '3'.
          output-mit_icon = '@EK@'.
        WHEN '5'.
          output-mit_icon = '@F8@'.
      ENDCASE.

      EXIT.
*       MODIFY output TRANSPORTING contid auditor from_date to_date
*     WHERE sel = 'X'.
    ENDLOOP.
    IF sy-subrc <> 0.
      IF output-mit_icon = '@EK@'.
        CLEAR: output-contid, output-auditor, output-from_date,
               output-to_date.
      ENDIF.
    ENDIF.

    MODIFY output INDEX sy-tabix TRANSPORTING contid auditor from_date
to_date mit_icon.
*        WHERE sel = 'X'.


  ENDLOOP.
*--Count the mitigations again
  CLEAR g_nummit.
  LOOP AT output WHERE contid <> ''.
    ADD 1 TO g_nummit.
  ENDLOOP.

  MESSAGE s002(/psyng/sw) WITH 'Mitigation Update Saved.'.
  g_mit_message = 'X'.
*--Refresh the ALV
  PERFORM refresh_output.
ENDFORM.                    " mitigate

*&---------------------------------------------------------------------*
*&      Form  delete_mit_assn
*&---------------------------------------------------------------------*
*       Delete mitigation assignment
*----------------------------------------------------------------------*
FORM delete_mit_assn.
  DATA: l_count      TYPE i,
        l_mit_count  TYPE i,
        lf_answer(1) TYPE c,
        ls_mchdr     TYPE /psyng/mchdr,
        lt_mccauser  TYPE TABLE OF /psyng/mccauser WITH HEADER LINE.

  DELETE ADJACENT DUPLICATES FROM gt_mccauser COMPARING ALL FIELDS .

  LOOP AT output WHERE sel = 'X'.
    IF output-contid IS INITIAL.
      MESSAGE e123 WITH output-bname output-swaudid.
    ENDIF.

    ADD 1 TO l_count.

*   Check for multiple mitigation assignments
    CLEAR l_mit_count.

    LOOP AT gt_mccauser WHERE userid   = output-bname
                          AND swaudid  = output-swaudid
                          AND to_date => sy-datum
                          AND type = 3
                          .
      ADD 1 TO l_mit_count.
    ENDLOOP.

    IF l_mit_count > 1.
*     Must not do this within loop - short dumps
      EXIT.
*    ENDIF.
    ELSEIF l_mit_count = 1.
      READ TABLE gt_mccauser WITH KEY userid  = output-bname
                                     swaudid = output-swaudid
                                     contid  = output-contid.
****<<<<<< SF RWE Case # 3017 Fix

*    IF output-company IS INITIAL.
*      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
*             ID 'ACTVT'      FIELD '06'
*             ID 'Y&SW_VRSIO' FIELD sodvrsio
*             ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
*             ID 'Y&SW_CONID' FIELD gt_mccauser-swaudid
*             ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
*             ID 'Y&SW_COMP'  DUMMY.
*    ELSE.
*      AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
*             ID 'ACTVT'      FIELD '06'
*             ID 'Y&SW_VRSIO' FIELD sodvrsio
*             ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
*             ID 'Y&SW_CONID' FIELD gt_mccauser-swaudid
*             ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
*             ID 'Y&SW_COMP'  FIELD output-company.
*    ENDIF.
      IF gf_use_sec_obj = 'X'.
*-- Check Create/Modify Authority
        IF NOT output-class IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
               ID 'ACTVT' FIELD '24'
               ID 'CLASS' FIELD output-class
                 ID 'Y&SW_VRSIO' FIELD sodvrsio
                 ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
*                   ID 'Y&SW_CONID' FIELD gt_mccauser-conid
                 ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid
                 ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
                 ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
          IF sy-subrc NE 0.
            MESSAGE e108 WITH 'Delete'(e01)
                             'this Mitigation assignment'(e03).
          ENDIF.
        ENDIF.

        IF output-company IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
               ID 'ACTVT' FIELD '24'
               ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_VRSIO' FIELD sodvrsio
               ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
               ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid
               ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
               ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ELSE.
          AUTHORITY-CHECK OBJECT 'Y&SW_MCAU2'
               ID 'ACTVT' FIELD '24'
               ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_VRSIO' FIELD sodvrsio
               ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
               ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid
               ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
               ID 'Y&SW_COMP'  FIELD output-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ENDIF.
        IF sy-subrc <> 0.
          MESSAGE e108 WITH 'Delete'(e01)
                            'this Mitigation assignment'(e03).
        ENDIF.
      ELSE.

        IF output-company IS INITIAL.
AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
       ID 'ACTVT'      FIELD '06'
       ID 'Y&SW_VRSIO' FIELD sodvrsio
       ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
*ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid "(--)BOC UMITTAL SE VF
*scan-25/11/2024
       ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
       ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
       ID 'Y&SW_CONID' FIELD ''."(++)BOC UMITTAL SE VF scan-25/11/2024
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ELSE.
AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
       ID 'ACTVT'      FIELD '06'
       ID 'Y&SW_VRSIO' FIELD sodvrsio
       ID 'Y&SW_CNTID' FIELD gt_mccauser-contid
*ID 'Y&SW_SWAUD' FIELD gt_mccauser-swaudid "(--)BOC UMITTAL SE VF
*scan-25/11/2024
       ID 'Y&SW_BNAME' FIELD gt_mccauser-userid
       ID 'Y&SW_COMP'  FIELD output-company
       ID 'Y&SW_CONID'  FIELD ''."(++)BOC UMITTAL SE VF scan-25/11/2024
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
        ENDIF.
        IF sy-subrc <> 0.
          MESSAGE e108 WITH 'Delete'(e01)
                            'this Mitigation assignment'(e03).
        ENDIF.

      ENDIF.


****<<<<<< SF RWE Case # 3017 End Fix

      IF sy-subrc <> 0.
        MESSAGE e108 WITH 'Delete'(e01)
                          'this Mitigation assignment'(e03).
      ENDIF.
    ENDIF."mit_count = 1
*    ls_mcuser       = gt_mccauser.
*    ls_mcuser-vrsio = sodvrsio.
  ENDLOOP.

  IF l_count <> 1.
    MESSAGE e018.
  ENDIF.

  IF l_mit_count > 1.
*   Call popup screen for multiple assignments - short dumps
    PERFORM mitigate.
    EXIT.
  ELSEIF l_mit_count = 1.
*  ENDIF.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
         EXPORTING
              text_question         = text-q01
              text_button_1         = text-029
              icon_button_1         = 'ICON_OKAY'
              text_button_2         = text-027
              icon_button_2         = 'ICON_CANCEL'
              default_button        = '2'
              display_cancel_button = space
         IMPORTING
              answer                = lf_answer
         EXCEPTIONS
              text_not_found        = 1
              OTHERS                = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CHECK lf_answer = '1'.

    ls_mchdr-contid = output-contid.
    MOVE-CORRESPONDING output TO lt_mccauser.
    lt_mccauser-userid = output-bname.
    lt_mccauser-vrsio  = sodvrsio.
    APPEND lt_mccauser.
*--Case 3017 - DHORIONS
    READ TABLE lt_remote_anal_rfc WITH KEY rfcoptions = output-rfcdest.
    IF sy-subrc <> 0 OR lt_remote_anal_rfc-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
           EXPORTING
                is_mchdr             = ls_mchdr
                if_del_assgn_only    = 'X'
           TABLES
                it_mccauser          = lt_mccauser
           EXCEPTIONS
                target_not_specified = 1
                not_authorized       = 2
                locked               = 3
                OTHERS               = 4.
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
         CASE sy-subrc.
           WHEN 1.
              MESSAGE s002(/psyng/sw)
           WITH 'User did not specify target mitigation control'.
           WHEN 2.
              MESSAGE s002(/psyng/sw)
           WITH 'User not authorized to create new mitigation control'.
           WHEN 3.
              MESSAGE s002(/psyng/sw)
           WITH 'Mitigation control is locked'.
           WHEN 4.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
           WHEN 5.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
           WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
         ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
    ELSE.
      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
           DESTINATION lt_remote_anal_rfc-rfcdest
           EXPORTING
                is_mchdr                   = ls_mchdr
                if_del_assgn_only          = 'X'
           TABLES
                it_mccauser                = lt_mccauser
           EXCEPTIONS
                target_not_specified       = 1
                not_authorized             = 2
                locked                     = 3
                COMMUNICATION_FAILURE      = 4
                SYSTEM_FAILURE             = 5
                OTHERS                     = 6. "#EC SAST_CI_GEN_CHECK

*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
         CASE sy-subrc.
           WHEN 1.
              MESSAGE s002(/psyng/sw)
           WITH 'User did not specify target mitigation control'.
           WHEN 2.
              MESSAGE s002(/psyng/sw)
           WITH 'User not authorized to create new mitigation control'.
           WHEN 3.
              MESSAGE s002(/psyng/sw)
           WITH 'Mitigation control is locked'.
           WHEN 4.
              MESSAGE i002(/psyng/sw) WITH 'Communication failure'(z01).
           WHEN 5.
              MESSAGE i002(/psyng/sw) WITH 'System failure'(z02).
           WHEN OTHERS.
              MESSAGE i002(/psyng/sw) WITH 'Unknown Error'(z03).
         ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
    ENDIF.

*  IF output-rfcdest IS INITIAL OR output-rfcdest = 'LOCAL'.
*    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
*         EXPORTING
*              is_mchdr             = ls_mchdr
*              if_del_assgn_only    = 'X'
*         TABLES
*              it_mccauser          = lt_mccauser
*         EXCEPTIONS
*              target_not_specified = 1
*              not_authorized       = 2
*              locked               = 3
*              OTHERS               = 4.
*  ELSE.
*    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
*         DESTINATION output-rfcdest
*         EXPORTING
*              is_mchdr                   = ls_mchdr
*              if_del_assgn_only          = 'X'
*         TABLES
*              it_mccauser                = lt_mccauser
*         EXCEPTIONS
*              target_not_specified       = 1
*              not_authorized             = 2
*              locked                     = 3
*              OTHERS                     = 4.
*  ENDIF.

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE e106 WITH 'Control ID'(006).
        WHEN 2.
          MESSAGE e108 WITH 'delete mitigation assignment'(014).
        WHEN 3.
          MESSAGE e113 WITH text-006 ls_mchdr-contid
                            'is currently locked'(022).
        WHEN 4.
          MESSAGE e113 WITH 'Unable to delete'(023) text-006
                            ls_mchdr-contid.
      ENDCASE.
    ELSE.
      MESSAGE s117.
*--Reflect the changes in the output
      DELETE gt_mccauser WHERE userid  = output-bname
                           AND swaudid = output-swaudid
                           AND contid  = output-contid.

      CLEAR: gt_mccauser-contid, gt_mccauser-auditor,
             gt_mccauser-from_date, gt_mccauser-to_date.
      READ TABLE gt_mccauser WITH KEY userid  = output-bname
                                      swaudid = output-swaudid
                             TRANSPORTING contid auditor from_date
                                          to_date.
      output-contid    = gt_mccauser-contid.
      output-auditor   = gt_mccauser-auditor.
      output-from_date = gt_mccauser-from_date.
      output-to_date   = gt_mccauser-to_date.
      MODIFY output TRANSPORTING contid auditor from_date to_date
                       WHERE sel = 'X'.
    ENDIF.
  ENDIF."ELSE if mit_count = 1

  MESSAGE s002(/psyng/sw) WITH 'Mitigation Update Saved.'.
  g_mit_message = 'X'.
*--Refresh the ALV
  PERFORM refresh_output.

ENDFORM.                    " delete_mit_assn

*---------------------------------------------------------------------*
*       FORM refresh_output                                           *
*---------------------------------------------------------------------*
*       Refresh ALV output                                            *
*---------------------------------------------------------------------*
FORM refresh_output.
  DATA : l_fld TYPE string.
* Refresh the grid with the new data
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.
  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
  ASSIGN  (l_fld) TO <g_grid>."#EC PATHLOCK_CI_DYN_ACCES
  CALL METHOD <g_grid>->refresh_table_display.
ENDFORM.                    " refresh_output
*&---------------------------------------------------------------------*
*&      Form  prepare_simuation_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM prepare_simuation_table.
  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  RANGES : range_roles FOR agr_define-agr_name.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
  IF rolerfc IS INITIAL.
    rolerfc = l_rfcdest.
  ENDIF.

  it_simu_role_addition-source_rfcdest = rolerfc.
  it_simu_role_addition-target_rfcdest = 'LOCAL'.

  LOOP AT simurols.
    MOVE-CORRESPONDING simurols TO it_simu_role_addition.
    APPEND it_simu_role_addition.
  ENDLOOP.

  LOOP AT it_simu_role_addition.
    MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
    APPEND range_roles.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_102'
  DESTINATION rolerfc
       TABLES
            it_roles_range = range_roles
            et_roles       = lt_role_names "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
   EXCEPTIONS
       communication_failure = 1
       system_failure = 2
           OTHERS = 3 .
       IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
           MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
        WHEN 2.
           MESSAGE s002(/psyng/sw) WITH 'System failure'.
        WHEN OTHERS.
           MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
      ENDCASE.
       ENDIF.
*EOC:HBHALLA (04/12/24)

  LOOP AT lt_role_names.

    gt_simu_roles-rfcdest = rolerfc.
    gt_simu_roles-agr_name = lt_role_names-agr_name.
    APPEND gt_simu_roles.
*--Load local role content
*    lt_faobj[] = lt_faobj_local[].
*    lt_functtran[] = lt_functtran_local[].
    REFRESH : lt_roleauth,lt_roletcode.
    CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
    DESTINATION rolerfc
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
              SYSTEM_FAILURE        = 2
              COMMUNICATION_FAILURE = 3
              OTHERS         = 4. "#EC SAST_CI_GEN_CHECK
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Invalid Role'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'(z03).
          ENDCASE.
         ENDIF.

    lt_roleauth-rfcdest = l_rfcdest.
    lt_roletcode-rfcdest = l_rfcdest.
    MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
    MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.
  ENDLOOP.

ENDFORM.                    " prepare_simuation_table
*&---------------------------------------------------------------------*
*&      Form  set_print_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LINE_COUNT  text
*----------------------------------------------------------------------*
FORM set_print_param USING p_line_count.
  p_line_count = p_line_count + 25 .
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
       EXPORTING
            line_count = p_line_count.
ENDFORM.                    " set_print_param
*&----------------------------------------------------------------------
*----------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.


  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  PERFORM build_alv_catalog_user_grp_cmp.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
*            i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
          i_grid_title          = alv_grid_titl
*            i_callback_program     = program
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
*         it_sort                = isort
*            i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
          is_layout             = alv_layout
          it_fieldcat           = i_fieldcat_alv
          i_save                = 'A'
          is_variant            = gs_variant
   	TABLES
          t_outtab              = gt_rpoug_auth_fail
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             PROGRAM_ERROR = 1
             OTHERS     = 3.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Program errors'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)

ENDFORM.                    " show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_user_grp_cmp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM build_alv_catalog_user_grp_cmp.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  program = sy-repid.
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

ENDFORM.                    " build_alv_catalog_user_grp_cmp
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
*BOC:HBHALLA (04/12/24)
       IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
           MESSAGE s002(/psyng/sw) WITH 'Incorrect parameter'.
        WHEN 2.
           MESSAGE s002(/psyng/sw) WITH 'No values found'.
        WHEN OTHERS.
           MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
      ENDCASE.
       ENDIF.
*EOC:HBHALLA (04/12/24)

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = wah_return-fieldval.
  ENDIF.
ENDFORM.                    " f4_usrtype
*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1478   text
*----------------------------------------------------------------------*
FORM show_help  USING    i_dokname.
  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.

ENDFORM.                    " show_help
*&---------------------------------------------------------------------*
*&      Form  show_mit_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OUTPUT  text
*----------------------------------------------------------------------*
FORM show_mit_details USING output LIKE output.

  DATA : l_showuser TYPE flag,
         l_showgroup TYPE flag,
         l_showrole TYPE flag,
         l_showcriauth TYPE flag,
         l_parent_agr TYPE agr_define-agr_name,
         lt_mccarole TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
         lt_mcuser_show LIKE TABLE OF gt_mccauser WITH HEADER LINE.
  RANGES lt_agr_range FOR agr_define-agr_name.
  CLEAR : l_showuser,l_showgroup,l_showrole,lt_mcuser_show[],
l_parent_agr.
  REFRESH: lt_mccarole,lt_mcuser_show.

  LOOP AT gt_mccauser WHERE userid = output-bname
                      AND swaudid  = output-swaudid.
    MOVE-CORRESPONDING gt_mccauser TO lt_mcuser_show.
*    APPEND lt_mcuser_show.
    REFRESH:lt_mccarole,lt_agr_range.
    CASE gt_mccauser-type.
      WHEN '3'.
        l_showcriauth = 'X'.
        APPEND lt_mcuser_show.
      WHEN '5'.
        l_showrole = 'X'.
        l_showcriauth = 'X'.



        SELECT SINGLE parent_agr FROM agr_define     "#EC CI_SEL_NESTED
                 INTO l_parent_agr
                 WHERE agr_name =  gt_mccauser-agr_name.

        IF NOT l_parent_agr IS INITIAL.
          lt_agr_range-sign = 'I'.
          lt_agr_range-option = 'EQ'.

          lt_agr_range-low = l_parent_agr.
          APPEND lt_agr_range.
          lt_agr_range-low = gt_mccauser-agr_name.
          APPEND lt_agr_range.

          SELECT * FROM /psyng/mccarole
                   INTO CORRESPONDING FIELDS OF TABLE lt_mccarole
                   WHERE vrsio     = sodvrsio
                     AND swaudid  = gt_mccauser-swaudid
                     AND contid   = gt_mccauser-contid
                     AND agr_name IN lt_agr_range.

        ENDIF.

        LOOP AT lt_mccarole.
          lt_mcuser_show-agr_name = lt_mccarole-agr_name."l_parent_agr.
          APPEND lt_mcuser_show.
        ENDLOOP.
        IF sy-subrc NE 0.
          APPEND lt_mcuser_show.
        ENDIF.
    ENDCASE.
  ENDLOOP.

  CHECK sy-subrc = 0.
  CALL FUNCTION '/PSYNG/SW_076'
       EXPORTING
            if_display      = '2'
            if_show_role    = l_showrole
            if_show_criauth = l_showcriauth
       TABLES
            it_mcuser       = lt_mcuser_show.

ENDFORM.                    " show_mit_details
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
*&---------------------------------------------------------------------
*
*&      Form  prepare_role_addition_simu
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------
*
FORM prepare_role_addition_simu TABLES   et_role_addition_simu
STRUCTURE
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

ENDFORM.                    " prepare_role_addition_simu
*&---------------------------------------------------------------------
*
*&      Form  before_after_simulation
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------
*
FORM before_after_simulation TABLES   it_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu
                                      it_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu.


  DATA : gt_output_before TYPE TABLE OF /psyng/sw_ca_output_org
                            WITH HEADER LINE,
       gt_output_after TYPE TABLE OF /psyng/sw_ca_output_org
                            WITH HEADER LINE.

  DATA :
     lt_simu_roleauth  TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
     lt_simu_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  lt_simu_roleauth_part  TYPE TABLE OF /psyng/userauth WITH HEADER LINE
 ,
     lt_simu_roletcode_part
     TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
      lt_functtran_local TYPE TABLE OF /psyng/functtran,
      lt_faobj_local TYPE TABLE OF /psyng/faobj2,
      lt_simu_roles_for_mit TYPE TABLE OF /psyng/sw_sod_remote_roles
        WITH HEADER LINE,
     i_enh TYPE flag,
     lt_rfcdes  TYPE TABLE OF rfcdes WITH HEADER LINE,
     ls_output  TYPE /psyng/sw_ca_output_org.


  IF ustb IS INITIAL.
    lf_dont_update_scan = 'X'.
  ENDIF.
  IF odt IS INITIAL.
    lf_dont_output_to_screen = 'X'.
  ENDIF.
  lt_rfcdest[] = remrfc[].

*-- Before Simulation
  FREE : gt_removed_roles.
  CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
       EXPORTING
            i_validuser        = validusr
            i_outvdate         = outvdate
            i_exlckusr         = exlckusr
            i_vrsio            = sodvrsio
            i_shomit           = xmc
            i_enh              = p_enhanc
            i_hienh            = p_hienhn
            i_wp               = wp
            i_xstb             = lf_dont_update_scan
            i_xstb_func        = 'X'
            i_pserver          = pserver
            i_group            = pgroup
            i_shonoca          = shonoca
            i_output           = lf_dont_output_to_screen
            i_remote_only      = onlyrem
            i_er_roles         = erroles
            i_exclude_er_roles = excl_er
            i_matrix_rfc       = p_sodrfc

       IMPORTING
            e_usercount        = g_nr_users_analyzed
            ef_missing_auth    = gf_missing_auth_ugroup
            ef_st_missing_auth = gf_st_missing_auth
       TABLES
            it_usertype        = usrtype
            it_users           = pbname
            it_actgroups       = s_role
            it_profiles        = s_prof
            it_usergroup       = s_class
            it_ca              = paudid
            et_outputdet       = gt_output_before
            it_department      = s_depart
            it_company         = s_comp
            it_central_uid     = s_cuid
*            et_mitigations     = gt_mccauser
            et_rpoug_auth_fail = gt_rpoug_auth_fail
            it_user_rfc        = lt_rfcdest
            et_return          = lt_return
            it_sense           = s_imp
            it_owners          = s_owner
            it_busarea         = s_barea
            et_enh_fun         = gt_enh_fun.

*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
      lt_return-type = 'W'.
    ENDIF.
    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
    WITH lt_return-message.
  ENDLOOP.
  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'E' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
  ENDIF.

*-- After Simulation
  FREE : gt_removed_roles.
  CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
       EXPORTING
            i_validuser        = validusr
            i_outvdate         = outvdate
            i_exlckusr         = exlckusr
            i_vrsio            = sodvrsio
            i_shomit           = xmc
            i_enh              = p_enhanc
            i_hienh            = p_hienhn
            i_wp               = wp
            i_xstb             = lf_dont_update_scan
            i_xstb_func        = 'X'
            i_pserver          = pserver
            i_group            = pgroup
            i_shonoca          = shonoca
            i_output           = lf_dont_output_to_screen
            i_remote_only      = onlyrem
            i_er_roles         = erroles
            i_exclude_er_roles = excl_er
            i_matrix_rfc       = p_sodrfc
       IMPORTING
            e_usercount        = g_nr_users_analyzed
            ef_missing_auth    = gf_missing_auth_ugroup
            ef_st_missing_auth = gf_st_missing_auth
       TABLES
            it_usertype        = usrtype
            it_users           = pbname
            it_actgroups       = s_role
            it_profiles        = s_prof
            it_usergroup       = s_class
            it_ca              = paudid
            et_outputdet       = gt_output_after
            it_department      = s_depart
            it_company         = s_comp
            it_central_uid     = s_cuid
            et_mitigations     = gt_mccauser
            et_rpoug_auth_fail = gt_rpoug_auth_fail
            it_user_rfc        = lt_rfcdest
            et_return          = lt_return
            it_sense           = s_imp
            it_owners          = s_owner
            it_busarea         = s_barea
            et_enh_fun         = gt_enh_fun
*--Role Removal Simulation
            it_simu_role_removal      = it_role_removal_simu
            et_simu_removed_roles     = gt_removed_roles
*--Role Addition Simulation
            it_simu_role_addition     = it_role_addition_simu.


*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
      lt_return-type = 'W'.
    ENDIF.
    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
    WITH lt_return-message.
  ENDLOOP.
  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'E' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
  ENDIF.

*-- Process output.
  SORT  gt_output_after  BY swaudid rfcdest.
  SORT  gt_output_before BY swaudid rfcdest.
*  Delete gt_output_after where simu <> 'X'.
  REFRESH : gt_output.

  LOOP AT gt_output_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_output_after TO ls_output.
    READ TABLE gt_output_before
    WITH KEY swaudid = gt_output_after-swaudid
             rfcdest = gt_output_after-rfcdest
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Conflict is added
      ls_output-simu_after = 'X'.
      CLEAR ls_output-simu_before.
    ELSE.
*--Conflict is unchanged
      ls_output-simu_after = 'X'.
      ls_output-simu_before = 'X'.
    ENDIF.
    IF ls_output-simu_after <> ls_output-simu_before.
      ls_output-simu = 'X'.
    ELSE.
      CLEAR ls_output-simu.
    ENDIF.
    APPEND ls_output TO gt_output.
  ENDLOOP.

  LOOP AT gt_output_before.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_output_before TO ls_output.
    READ TABLE gt_output_after
    WITH KEY swaudid = gt_output_before-swaudid
             rfcdest = gt_output_before-rfcdest

    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Conflict is removed
      ls_output-simu_before = 'X'.
      CLEAR ls_output-simu_after.
      IF ls_output-simu_after <> ls_output-simu_before.
        ls_output-simu = 'X'.
      ELSE.
        CLEAR ls_output-simu.
      ENDIF.
      APPEND ls_output TO gt_output.
    ENDIF.
  ENDLOOP.

  IF byrsimu = 'X' AND gt_removed_roles[] IS INITIAL.
    MESSAGE i002 WITH
    'No users had the roles for which'(192)
    'removal was simulated'(191).
  ENDIF.

  IF NOT lf_dont_output_to_screen = 'X'.
    PERFORM reformat_output.
    PERFORM output_using_alv.
  ENDIF.
  EXIT.


ENDFORM.                    " before_after_simulation
*&---------------------------------------------------------------------*
*&      Form  reformat_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reformat_output.
  FIELD-SYMBOLS : <in> TYPE /psyng/sw_ca_output_org.
  DATA : ls_output LIKE LINE OF output.
  DATA: cc  TYPE lvc_s_scol,
        color TYPE lvc_s_colo,
        seperator(3) TYPE c VALUE ' - '.
  REFRESH : output[].
  LOOP AT gt_output ASSIGNING <in>.
    REFRESH : ls_output-color_cell.
    ls_output-ustyp       = <in>-ustyp.
    ls_output-class       = <in>-class.
    ls_output-company     = <in>-company.
    ls_output-compshort   = <in>-company.
    PERFORM get_comp_name
                CHANGING
                   <in>-company
                   ls_output-company.

    ls_output-department  = <in>-department.
    ls_output-central_uid  = <in>-central_uid.
    ls_output-rfcdest     = <in>-rfcdest.
    ls_output-bname       = <in>-bname.
    ls_output-name_text   = <in>-name_text.
    ls_output-swaudid     = <in>-swaudid.
    ls_output-description = <in>-description.
    ls_output-imp         = <in>-imp.
    ls_output-owner         = <in>-owner.
*    ls_output-impsort     = <in>-impsort.
    ls_output-contid      = <in>-contid.
    ls_output-simu        = <in>-simu.
    ls_output-er          = <in>-er.
    ls_output-simu_after  = <in>-simu_after.
    ls_output-simu_before  = <in>-simu_before.
    ls_output-appl  = <in>-appl.

*    CASE <in>-origin.
*      WHEN 1.
*        ls_output-origin = 'Local'(173).
*      WHEN 2.
*        ls_output-origin = 'Remote'(174).
*      WHEN 3.
*        ls_output-origin = 'Cross'(175).
*    ENDCASE.

    READ TABLE gt_enh_fun WITH KEY bname = <in>-bname
                                   funid = <in>-swaudid.
    IF sy-subrc = 0.
      ls_output-enhanced = 'X'.
      IF p_hienhn = 'X'.
        DELETE ls_output-color_cell WHERE fname = 'SWAUDID'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'CONID'.
        APPEND cc TO ls_output-color_cell.
      ENDIF.
    ENDIF.
    IF xmc = 'X' AND NOT ls_output-contid IS INITIAL.
      LOOP AT gt_mccauser WHERE
                         contid = ls_output-contid AND
                         swaudid  = ls_output-swaudid  AND
                         userid = ls_output-bname  AND
                         vrsio  = sodvrsio         AND
                         from_date LE sy-datum     AND
                         to_date   GE sy-datum.
        ls_output-auditor   = gt_mccauser-auditor.
        ls_output-from_date = gt_mccauser-from_date.
        ls_output-to_date   = gt_mccauser-to_date.
        CASE gt_mccauser-type.
          WHEN '3'.
            ls_output-mit_icon = '@EK@'.
          WHEN '5'.
            ls_output-mit_icon = '@F8@'.
        ENDCASE.
        ADD 1 TO g_nummit.
        EXIT."first valid one is ok.
      ENDLOOP.
    ENDIF.
    APPEND ls_output TO output.
    CLEAR: ls_output.
  ENDLOOP.

ENDFORM.                    " reformat_output
*&---------------------------------------------------------------------*
*&      Form  get_critauths_from_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_critauths_from_selection.
*B8710 - There could be non abap CA's that aren't defined in SE
  CHECK p_nabap IS INITIAL.
*DATA : lt_local_swaudhdr TYPE TABLE /psyng/swaudhdr WITH HEADER LINE.
  IF NOT p_sodrfc IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CRIAUTHS'
      DESTINATION p_sodrfc
         EXPORTING
             vrsio            = sodvrsio
         TABLES
             swaudhdr         = swaudhdr
         EXCEPTIONS
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            no_authorization =  3
            OTHERS = 4.   "#EC SAST_CI_GEN_CHECK
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
    IF sy-subrc = 0.
      DELETE swaudhdr WHERE NOT swaudid IN paudid  OR
                            NOT imp     IN s_imp   OR
                            NOT owner   IN s_owner OR
                            NOT busarea IN s_barea.
    ENDIF.
  ELSE.


    SELECT * FROM /psyng/swaudhdr INTO TABLE swaudhdr
                              WHERE vrsio =  sodvrsio
                              AND swaudid IN paudid
                              AND imp IN s_imp
                              AND owner IN s_owner
                              AND busarea IN s_barea.
  ENDIF.
  SORT swaudhdr BY swaudid.


  IF swaudhdr[] IS INITIAL.
*--Selection of conflicts showed no conflicts
    MESSAGE i135 WITH 'No Critical Auth ID(s) match selection'(199).
    LEAVE LIST-PROCESSING.
  ENDIF.


ENDFORM.                    " get_critauths_from_selection
*&---------------------------------------------------------------------*
*&      Form  vaildate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM vaildate_other_fields.
  DATA : l_vrsio TYPE /psyng/sodvrsio,
           l_rfcdest TYPE rfcdes-rfcdest,
           lt_roles TYPE TABLE OF /psyng/bc_agr_name,
           ls_rfcdest LIKE LINE OF lt_rfcdest,
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

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.
  IF p_sodrfc IS INITIAL.
*  --If we use a local sod matrix, validate it exists
    SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
    WHERE vrsio = sodvrsio.
    IF sy-subrc NE 0.
      MESSAGE i135 WITH 'SOD Version does not exist.'(195).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  IF bysimu = 'X'.
*-- Validate Source RFC
    IF NOT ar_rol_1[] IS INITIAL.
      IF NOT ar_rfcs1 = '' AND
         NOT ar_rfcs1 = 'LOCAL' AND
         NOT ar_rfcs1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs1.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.

*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
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
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles l_rfcdest_local ar_rol_1-low.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
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
          append_roles l_rfcdest_local ar_rol_2-low.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
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
          append_roles l_rfcdest_local ar_rol_3-low.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
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
          append_roles l_rfcdest_local ar_rol_4-low.
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
  ENDIF.

*-- Role Removal Simulation

  IF byrsimu = 'X'.
    IF NOT rr_rol_1[] IS INITIAL.
      IF NOT rr_rfc_1 = '' AND
         NOT rr_rfc_1 = 'LOCAL' AND
         NOT rr_rfc_1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_1.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_1-low.
*            DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_1.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_1.
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
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles l_rfcdest_local rr_rol_1-low.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT rr_rol_2[] IS INITIAL.
      IF NOT rr_rfc_2 = '' AND
         NOT rr_rfc_2 = 'LOCAL' AND
         NOT rr_rfc_2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_2.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_2-low.
*            DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_2.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_2.
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
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles l_rfcdest_local rr_rol_2-low.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_3[] IS INITIAL.
      IF NOT rr_rfc_3 = '' AND
         NOT rr_rfc_3 = 'LOCAL' AND
         NOT rr_rfc_3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_3.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_3-low.
*            DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_3.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_3.
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
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles l_rfcdest_local rr_rol_3-low.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_4[] IS INITIAL.
      IF NOT rr_rfc_4 = '' AND
         NOT rr_rfc_4 = 'LOCAL' AND
         NOT rr_rfc_4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_4.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_4-low.
*            DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_4.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_4.
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
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles l_rfcdest_local rr_rol_3-low.
        ENDIF.
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
    ls_fcat-seltext_l = 'Simulated Entries not exist'.
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

ENDFORM.                    " vaildate_other_fields
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv.
  PERFORM alv_output_sum.
ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  reformat_output_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reformat_output_detail.
  DATA :    cc  TYPE lvc_s_scol,
        color TYPE lvc_s_colo,
        l_tcode(40) TYPE c.

  LOOP AT gt_output_det.
*-- Change to EN tcodes length 40 chars
    IF p_nabap = 'X'.
    READ TABLE gt_map_tcode_screen WITH KEY tcode = gt_output_det-tcode.
      IF sy-subrc = 0.
        CLEAR l_tcode.
        l_tcode = gt_map_tcode_screen-usrrt.
      ENDIF.
    ENDIF.

    IF gt_output_det-tcode CS '/PSYNG/-SWAUD'.
      gt_output_det-tcode = '*'.
    ENDIF.
    outputdet-bname      = gt_output_det-bname.
    outputdet-rfcdest    = gt_output_det-rfcdest.
    outputdet-swaudid    = gt_output_det-swaudid.
    outputdet-tcode      = gt_output_det-tcode.
    outputdet-objct      = gt_output_det-objct.
    outputdet-auth       = gt_output_det-auth.
    outputdet-field      = gt_output_det-field.
    outputdet-von        = gt_output_det-von.
    outputdet-bis        = gt_output_det-bis.
    outputdet-child_agr  = gt_output_det-agr_name.
*    outputdet-profile    = gt_output_det-profile.
    outputdet-comp_agr   = gt_output_det-comp_agr.
    outputdet-er         = gt_output_det-er.
    outputdet-simu       = gt_output_det-simu.
    outputdet-ustyp      = gt_output_det-ustype.
    outputdet-profile    = gt_output_det-profile.
    outputdet-comp_prof  = gt_output_det-comp_prof.
    IF gt_output_det-appl IS INITIAL.
      outputdet-appl       = 'SAP'.
    ELSE.
      outputdet-appl       = gt_output_det-appl.
      outputdet-tcode      = l_tcode.
    ENDIF.

    IF p_enhanc = 'X' .
      outputdet-enhanced  = gt_output_det-enhanced.
      IF p_hienhn = 'X'." and e_outputdet-enhanced = 'X'.
        READ TABLE gt_enh_tcodes WITH KEY
        calling_tcode = outputdet-tcode
        TRANSPORTING NO FIELDS BINARY SEARCH.
        IF sy-subrc = 0.
          outputdet-enhanced = 'X'.
          DELETE outputdet-color_cell
                 WHERE fname = 'SWAUDID' OR fname = 'TCODE'.
          color-col = '7'.   "Orange
          color-int = '1'.   "Intensified
          color-inv = '0'.   "Inverse
          cc-color  = color.
          cc-fname  = 'SWAUDID'.
          APPEND cc TO outputdet-color_cell.
          cc-fname  = 'TCODE'.
          APPEND cc TO outputdet-color_cell.
        ENDIF.
      ENDIF.
    ENDIF.

    APPEND outputdet.

  ENDLOOP.
ENDFORM.                    " reformat_output_detail
*&---------------------------------------------------------------------*
*&      Form  get_users_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_count.
  DATA : l_numb TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local type flag value 'X'.

  IF ONLYREM = 'X'.
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
   IT_USERLIST             = pbname
   IT_GROUPLIST            = s_class
   IT_USERTYPE             = usrtype
   IT_ACTGROUPS            = s_role
   IT_PROFILE              = s_prof
   IT_RFCRANGE             = remrfc
*   IT_RFCLIST              =
   IT_DEPARTMENT           = s_depart
   IT_COMPANY              = s_comp
   IT_CUID                 = s_cuid.
ENDFORM.                    "get_users_count
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REMRFC  text
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
           WHERE rfcdest IN it_role_rfc
           AND rfctype = '3'.

    IF sy-subrc <> 0.
*--At this point user has already decided to continue despite incorrect
*   rfc destinations, so don't stop here
      MESSAGE s004(sr).
    ENDIF.
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
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
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



ENDFORM.                    " load_role_rfc

*&---------------------------------------------------------------------*
*&      Form  get_history_months
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_history_months USING 1stmon lastmon.

  DATA: 1stmonth TYPE sy-datum, lastmont TYPE sy-datum.
  DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
        WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = idirectory
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             OTHERS     = 1.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF 1stmonth IS INITIAL OR 1stmonth > idirectory-startdate.
      1stmonth = idirectory-startdate.
    ENDIF.
    IF lastmont < idirectory-startdate.
      lastmont = idirectory-startdate.
    ENDIF.
  ENDLOOP.

  CONCATENATE 1stmonth+4(2) '/' 1stmonth(4) INTO 1stmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.
ENDFORM.                    " get_history_months
*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'SIMU_BUT'  '' CHANGING simu_but .
  PERFORM init_but USING 'SIMU_BUT'  '' CHANGING rem_but .

  PERFORM handle_sections.
ENDFORM.                    " set_button_icons
*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4375   text
*      -->P_4376   text
*      <--P_SIMU_BUT  text
*----------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE /psyng/usr_displ,
         l_exp TYPE flag.
  SELECT SINGLE * INTO ls_state
  FROM /psyng/usr_displ
  WHERE
    bname = g_current_user AND "sy-uname AND C0700
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
*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
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
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT = 2
             OTHERS     = 3.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Icon name unknown to system'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'Length of field (RESULT) is too small'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)
ENDFORM.                    " expand
*&---------------------------------------------------------------------*
*&      Form  collapse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
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
*BOC:HBHALLA (06/12/24)
        EXCEPTIONS
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT = 2
             OTHERS     = 3.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'Icon name unknown to system'.
             WHEN 2.
                MESSAGE s002(/psyng/sw)
             WITH 'Length of field (RESULT) is too small'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)

ENDFORM.                    " collapse
*&---------------------------------------------------------------------*
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  simu_but  'SIM'.
  PERFORM handle_section USING  rem_but  'REM'.
ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  handle_section
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SIMU_BUT  text
*      -->P_4495   text
*----------------------------------------------------------------------*
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

ENDFORM.                    " handle_section
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
    WHEN 'SIMU_BUT'.
      PERFORM toggle USING simu_but 'SIMU_BUT'.
    WHEN 'REM_BUT'.
      PERFORM toggle USING rem_but 'REM_BUT'.

  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.                    " handle_button
*&---------------------------------------------------------------------*
*&      Form  toggle
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SIMU_BUT  text
*      -->P_4553   text
*----------------------------------------------------------------------*
FORM toggle  USING i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
    CLEAR g_button_set.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
    g_button_set = 'X'.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.
ENDFORM.                    " toggle
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
  ENDIF.


  FREE : gt_rfcdest.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  detail_crit_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM detail_crit_auths.
  DATA : iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
*  READ TABLE output INDEX rs_selfield-tabindex.
*  CHECK sy-subrc = 0.
  CHECK NOT output-swaudid = '----'.
  REFRESH : iseltab[].
  CLEAR iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sodvrsio.
  APPEND iseltab.

  iseltab-selname = 'P_ENHANC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.

  iseltab-selname = 'P_HIENHN'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_hienhn.
  APPEND iseltab.


  iseltab-selname = 'XMC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = xmc.
  APPEND iseltab.

  iseltab-selname = 'SHOWCOMP'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = showcomp.
  APPEND iseltab.

  iseltab-selname = 'DET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.

  iseltab-selname = 'VALIDUSR'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = validusr.
  APPEND iseltab.

  iseltab-selname = 'PBNAME'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-bname.
  APPEND iseltab.

  iseltab-selname = 'PAUDID'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-swaudid.
  APPEND iseltab.

  iseltab-selname = 'OWNER'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-owner.
  APPEND iseltab.


  iseltab-selname = 'IMP'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-imp.
  APPEND iseltab.

  LOOP AT usrtype .
    iseltab-selname = 'USRTYPE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = usrtype-sign.
    iseltab-option  = usrtype-option.
    iseltab-low     = usrtype-low.
    iseltab-high    = usrtype-high.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'EXLCKUSR'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = exlckusr.
  APPEND iseltab.

  iseltab-selname = 'OUTVDATE'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = outvdate.
  APPEND iseltab.


  DATA : l_local_rfc TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
  IF output-appl = 'SAP'.
*--Only analyze ABAP
    iseltab-selname = 'P_NABAP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ''.
    iseltab-high    = ''.
    APPEND iseltab.
    iseltab-selname = 'P_ABAP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    iseltab-high    = ''.
    APPEND iseltab.
    IF l_local_rfc <> output-rfcdest.
*--Specific Remote System
      READ TABLE gt_rfcdest WITH KEY rfcoptions =  output-rfcdest.
      IF sy-subrc = 0.
        iseltab-selname = 'REMRFC'.
        iseltab-kind    = 'S'.
        iseltab-sign    = 'I'.
        iseltab-option  = 'EQ'.
        iseltab-low     =  gt_rfcdest-rfcdest.
        APPEND iseltab.
*--Only remote systems
        iseltab-selname = 'ONLYREM'.
        iseltab-kind    = 'P'.
        iseltab-sign    = 'I'.
        iseltab-option  = 'EQ'.
        iseltab-low     = 'X'.
        APPEND iseltab.
      ENDIF.
    ENDIF.
  ELSE.
*--Only analyze NON-ABAP
    iseltab-selname = 'P_NABAP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    iseltab-high    = ''.
    APPEND iseltab.
    iseltab-selname = 'P_ABAP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ''.
    iseltab-high    = ''.
    APPEND iseltab.
*--This specific application and system
    iseltab-selname = 'S_APPL'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = output-appl.
    iseltab-high    = ''.
    APPEND iseltab.
    iseltab-selname = 'S_SYSTEM'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = output-rfcdest.
    iseltab-high    = ''.
    APPEND iseltab.
  ENDIF.

*Simulation
  iseltab-selname = 'BYSIMU'.     " By Simulate
  iseltab-kind = 'P'.
  iseltab-sign = 'I'.
  iseltab-option = 'EQ'.
  iseltab-low = bysimu.
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

*Er Roles
  iseltab-selname = 'ERROLES'.       "Include ER-Roles
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = erroles.
  APPEND iseltab.

  iseltab-selname = 'EXCL_ER'.       "Exclude ER-Assigned-Roles
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = excl_er.
  APPEND iseltab.


  iseltab-selname = 'P_FLAG'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_flag.
  APPEND iseltab.

  iseltab-selname = 'P_SODRFC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_sodrfc.
  APPEND iseltab.


  program = sy-repid.
  SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
    WITH SELECTION-TABLE iseltab AND RETURN.
ENDFORM.                    " detail_crit_auths
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
*&      Form  display_alv_0102
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
*     I_BUFFER_ACTIVE =
*     I_CONSISTENCY_CHECK =
*     I_STRUCTURE_NAME =
*     IS_VARIANT =
*     I_SAVE =
*     I_DEFAULT = 'X'
       is_layout       = gs_layout
*     IS_PRINT =
*     IT_SPECIAL_GROUPS =
*     IT_TOOLBAR_EXCLUDING =
*     IT_HYPERLINK =
     CHANGING
       it_outtab       = gt_removed_roles[]
       it_fieldcatalog = gt_fieldcat
*     IT_SORT =
*     IT_FILTER =
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

ENDFORM.                    " display_alv_0102
*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM prepare_field_catalog_0102 CHANGING et_fieldcat TYPE lvc_t_fcat.
  DATA ls_fcat TYPE lvc_s_fcat .
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_REMOVED_ROLES'
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
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.
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
*&---------------------------------------------------------------------*
*&      Form  role_sod_analysis_en_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AGR_NAME  text
*      -->P_OUTPUTDET_RFCDEST  text
*      -->P_OUTPUTDET_APPL  text
*----------------------------------------------------------------------*
FORM role_sod_analysis_en_detail USING    agr_name
                                          rfcdest
                                          appl.
  SUBMIT /psyng/sod_syswide_byrole
          WITH role     = agr_name
          WITH sodvrsio = sodvrsio
          WITH s_sys    = rfcdest
          WITH s_appl    = appl
          WITH p_nabap  = 'X'
          AND RETURN.
ENDFORM.                    " EN_ROLE_SOD_ANALYSIS_FROM_DETA

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
