*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_105
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
REPORT /psyng/sw_155 MESSAGE-ID /psyng/sw  LINE-SIZE 132.
TABLES: /psyng/mcusrgrp, /psyng/mcauditor, /psyng/mcuser,
        /psyng/conflict, /psyng/mchdr,/psyng/swsodorgm, rfcdes,
        /psyng/swaudhdr,/psyng/ex_caobj_lock, usr21.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/sw_125.
TYPE-POOLS: slis.
DATA: g_ucomm         TYPE sy-ucomm,
      g_userassign    TYPE i,
      g_groupassign   TYPE i,
      g_roleassign    TYPE i,
      g_dynnr         LIKE sy-dynnr,
      gf_sp_installed TYPE flag,
      l_appl          TYPE /psyng/application,
      gf_mit_by_org   TYPE c.

TYPES : BEGIN OF typ_usr02_remote  ,
          rfcdest TYPE rfcdest.
          INCLUDE STRUCTURE  usr02.
        TYPES : END OF typ_usr02_remote,
        BEGIN OF iduser_typ,
          bname   LIKE usr02-bname,
          idbname LIKE usr02-bname,
        END OF iduser_typ ,
        BEGIN OF idusers_typ,
          bname LIKE usr02-bname,
        END OF idusers_typ,

        tt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp,
        tt_mcrole TYPE TABLE OF /psyng/mcrole,
        tt_mccarole TYPE TABLE OF /psyng/mccarole,

        tt1_mcusrgrp TYPE TABLE OF /psyng/sw_mcusrgrp,
        tt1_mcrole TYPE TABLE OF /psyng/sw_mcrole,
        tt1_mccarole TYPE TABLE OF /psyng/sw_mccarole.


DATA: BEGIN OF mcuser OCCURS 0,
        mark              TYPE flag,
        rfcdest           TYPE rfcdest,
        type,   "C = Critical Auth, S = SOD Conflict
        contid            LIKE /psyng/mcuser-contid,
        contdesc          LIKE /psyng/mchdr-description,
        mittype           LIKE /psyng/mchdr-type,
        mittype_text      LIKE /psyng/sw_mctype-text,
        mit_icon          LIKE icon-id,
        assn_type         LIKE /psyng/mcuser-approved,
        conid             LIKE /psyng/mcuser-conid,
        condesc           LIKE /psyng/conflict-description,
        asg_usr           LIKE /psyng/mcuser-approved,
        asg_grp           LIKE /psyng/mcuser-approved,
        asg_rol           LIKE /psyng/mcuser-approved,
        class             LIKE /psyng/mcusrgrp-class,
        userid            LIKE /psyng/mcuser-userid,
        name_text         LIKE adrp-name_text,
        company           LIKE /psyng/sw_uinfo-company,
        compshort         LIKE /psyng/sw_uinfo-company,
        department        LIKE /psyng/sw_uinfo-department,
        central_uid       LIKE /psyng/sw_uinfo-central_uid,
        vrsio(3), "LIKE /PSYNG/MCUSER-VRSIO,
        auditor           LIKE /psyng/mcuseraud-auditor,
        auditor_name_text LIKE adrp-name_text,
        audcompany        LIKE /psyng/mcauditor-company,
        from_date         LIKE /psyng/mcuser-from_date,
        to_date           LIKE /psyng/mcuser-to_date,
*        obsolete          LIKE /psyng/mcuser-approved,
        org_abb           LIKE /psyng/mcuser-org_abb,
        agr_name          LIKE agr_define-agr_name, "name of role when
                                                    "role assignment
        assn_class        LIKE usr02-class, "usergroup when
                                            "usergroup assignment
      END OF mcuser.
DATA: gt_mcuser LIKE mcuser OCCURS 0 WITH HEADER LINE.
DATA: g_action_idx TYPE sy-tabix.
DATA: gt_mcuser_ca LIKE mcuser OCCURS 0 WITH HEADER LINE.
DATA: g_system_msg(80) TYPE c,
      gt_uinfo         TYPE TABLE OF /psyng/sw_uinfo_remote WITH
                         HEADER LINE,

      gt_user_mapping  TYPE TABLE OF /psyng/sw_user_mapping
       WITH HEADER LINE.

DATA : BEGIN OF gt_testca OCCURS 0,
         gt_mcuser1 LIKE mcuser,
         swaudid    LIKE /psyng/swaudhdr-swaudid,
       END OF gt_testca.

FIELD-SYMBOLS : <uinfo> TYPE /psyng/sw_uinfo_remote,
                <map>   TYPE /psyng/sw_user_mapping,
                <mcuser> LIKE mcuser.
DATA: l_sort TYPE slis_t_sortinfo_alv.
DATA: gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: gf_hide_org            TYPE flag,
      gf_central_uid         TYPE flag,
      gt_rfcdest             TYPE TABLE OF rfcdes
      WITH HEADER LINE,
      lf_answer(1)           TYPE c,
      gf_dflt_enhance_matrix TYPE flag,
      gt_rpoug_auth_fail     TYPE TABLE OF /psyng/sw_uinfo
      WITH HEADER LINE,
      g_current_user         TYPE sy-uname. "C0700
DATA: curr_variant  LIKE  rsvar-variant,
      vari_desc     TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text     LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA:gf_job_active  TYPE c,
     gf_email_alert TYPE c,
     gf_wbstats     TYPE c,
     exit_proc.
CONSTANTS:ta_def_job_txt TYPE btcjob
VALUE 'SW: Mass Mitigation Expire'.


SELECTION-SCREEN: BEGIN OF BLOCK bywhat WITH FRAME TITLE text-004.
SELECT-OPTIONS:   userid FOR /psyng/mcuser-userid,  "user ID
                  s_class FOR /psyng/mcusrgrp-class,   "User grp
                  s_comp   FOR mcuser-company,
                  s_depart FOR mcuser-department,
                  s_cuid  FOR  mcuser-central_uid MODIF ID cus
                  NO-DISPLAY,
*                  xusrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
*                              /psyng/sw_rfcsh, "RFC destinations
                  contid FOR /psyng/mchdr-contid,  "control ID
                  auditor FOR usr21-bname, "/psyng/mcuser-userid,
                  valid_fr FOR /psyng/mcuser-from_date,
                  valid_to FOR /psyng/mcuser-to_date.

*--Arpan C0881 : starts
*-- User type & valid user screen
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN INCLUDE BLOCKS b_usr.
*--Arpan C0881 : End

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: sodcon  AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(20) text-180 FOR FIELD sodcon.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: conid FOR /psyng/conflict-conid.  "conflict ID

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: criaut AS CHECKBOX DEFAULT ' '.
SELECTION-SCREEN COMMENT 3(30) text-181 FOR FIELD criaut.
SELECTION-SCREEN END OF LINE.
"Critical Auth ID
SELECT-OPTIONS:   swaudid FOR /psyng/swaudhdr-swaudid.

SELECTION-SCREEN: SKIP 1.
PARAMETERS :      sodvrsio LIKE /psyng/conflict-vrsio .

*BOC AKUMAR PN12569
*Added this to enable expire mitigations from remote systems.
SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest
 MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
*EOC AKUMAR PN12569

SELECTION-SCREEN: SKIP 1.



SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: expcn AS CHECKBOX DEFAULT ' ' USER-COMMAND exp.
SELECTION-SCREEN COMMENT 3(45) text-186 FOR FIELD expcn.
SELECTION-SCREEN END OF LINE.
*SELECTION-SCREEN: SKIP 1.
SELECT-OPTIONS: s_system FOR /psyng/ex_caobj_lock-sysid
NO-DISPLAY MATCHCODE OBJECT /psyng/ex_system MODIF ID rem."EN
SELECTION-SCREEN: END OF BLOCK bywhat.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====
* Additional selection requirements.
SELECTION-SCREEN: BEGIN OF BLOCK mass WITH FRAME TITLE text-190.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_disply RADIOBUTTON GROUP rb_m DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(45) text-192 FOR FIELD p_disply.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_expire RADIOBUTTON GROUP rb_m.
SELECTION-SCREEN COMMENT 3(45) text-193 FOR FIELD p_expire.
SELECTION-SCREEN END OF LINE.

*BOC C1159 CGUPTA 19/09/2023
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_notify RADIOBUTTON GROUP rb_m.
SELECTION-SCREEN COMMENT 3(45) text-220 FOR FIELD p_notify.
SELECTION-SCREEN END OF LINE.
*EOC C1159 CGUPTA 19/09/2023

SELECTION-SCREEN: END OF BLOCK mass.
SELECTION-SCREEN: BEGIN OF BLOCK back WITH FRAME TITLE text-191.
SELECTION-SCREEN: COMMENT  1(78) text-187.
SELECTION-SCREEN: COMMENT /1(78) text-188.
SELECTION-SCREEN: COMMENT /1(78) text-189.
*SELECTION-SCREEN: SKIP 2.
*SELECTION-SCREEN: COMMENT 1(75) s_cmt MODIF ID cm1.
PARAMETERS : s_cmt TYPE flag NO-DISPLAY.
SELECTION-SCREEN: SKIP.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-194 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-195 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.
SELECTION-SCREEN: END OF BLOCK back.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====

*====[ C0704 - Create Mass Mitigating Control Expiration ]====
* Remove all the SOD analysis
PARAMETERS : obscheck TYPE flag NO-DISPLAY,
             obsexp   TYPE flag NO-DISPLAY,
             ignsp    TYPE flag NO-DISPLAY.
*
PARAMETERS: orgchk   NO-DISPLAY DEFAULT ' '.
SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb NO-DISPLAY.
*
PARAMETERS p_enhanc NO-DISPLAY. "ruleset
*
PARAMETERS :
  erroles NO-DISPLAY DEFAULT ' ' MODIF ID exe,
  excl_er NO-DISPLAY DEFAULT ' ' MODIF ID exe.
*
PARAMETERS : p_local TYPE flag NO-DISPLAY DEFAULT 'X' MODIF ID rem.
*
PARAMETERS : p_remote TYPE flag NO-DISPLAY DEFAULT ' '
                                           MODIF ID rem.
*
PARAMETERS : p_cross TYPE flag NO-DISPLAY DEFAULT ' ' MODIF ID rem.
*
PARAMETERS : p_locusr NO-DISPLAY          MODIF ID rem.
*
PARAMETERS : p_remonl NO-DISPLAY
                                         MODIF ID rem.
*
PARAMETERS p_abap NO-DISPLAY DEFAULT 'X'
                                   MODIF ID rem."EN.
*BOC AKUMAR PN12569
*Commented this here and used above
*SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest
*NO-DISPLAY MATCHCODE OBJECT
*/psyng/sw_rfcsh_coll MODIF ID rem.
*
*EOC AKUMAR PN12569

PARAMETERS p_nabap NO-DISPLAY MODIF ID rem.
SELECT-OPTIONS: s_appl FOR l_appl NO-DISPLAY
MATCHCODE OBJECT
/psyng/ex_application
 MODIF ID rem."EN.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====

PARAMETERS : no_disp TYPE flag NO-DISPLAY.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-low.
  PERFORM f4_department CHANGING s_depart-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-high.
  PERFORM f4_department CHANGING s_depart-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-low.
  PERFORM f4_company USING 'S_COMP-LOW' CHANGING s_comp-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-high.
  PERFORM f4_company USING 'S_COMP-HIGH' CHANGING s_comp-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.


INITIALIZATION.
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700
  PERFORM exelog.
  PERFORM get_initial_config.
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.

*---Default config param for enhanced sod matrix checkbox
  se_config_param 'DFLT_ENHANCE_MATRIX' gf_dflt_enhance_matrix.
  IF gf_dflt_enhance_matrix = 'Y' OR gf_dflt_enhance_matrix = 'X'.
    IF p_enhanc IS INITIAL.
      p_enhanc = 'X'.
    ENDIF.
  ELSE.
    CLEAR p_enhanc.
  ENDIF.
*--Check if SP is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module    = 'SP'
    IMPORTING
      e_installed = gf_sp_installed.

AT SELECTION-SCREEN.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====
  PERFORM user_command.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====
  g_ucomm = sy-ucomm.
  PERFORM check_input.
  IF sodcon = space AND criaut = space.
    MESSAGE w113(/psyng/sw) WITH text-182.
  ENDIF.

  IF p_local = space AND p_remote = space AND p_cross = space.
    MESSAGE w113(/psyng/sw) WITH text-183.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  DATA : g_inp , g_inp1 TYPE c.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====
* PERFORM check_job_status.
*====[ C0704 - Create Mass Mitigating Control Expiration ]====
  IF obscheck = 'X'.
    g_inp = '1'.
  ELSE.
    g_inp = '0'.
  ENDIF.

  IF p_remonl = 'X'.
    CLEAR : p_local, p_cross.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'P_LOCAL' OR 'P_CROSS'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
    p_remote = 'X'.
    IF xusrrfc[] IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for remote analysis'(184).
    ENDIF.
  ELSE.
    p_local = 'X'.
  ENDIF.

  IF p_cross = 'X'.
    IF xusrrfc[] IS INITIAL AND p_nabap IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for Cross system analysis'(185).
    ENDIF.
  ENDIF.

  IF p_remonl = 'X'.
    CLEAR : p_local, p_cross.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'P_LOCAL' OR 'P_CROSS'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
  ENDIF.


  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'OBSEXP'.
        screen-input = g_inp.
        MODIFY SCREEN.
      WHEN 'IGNSP'.
        IF gf_sp_installed = 'X'.
          screen-invisible = 0.
          screen-active    = 1.
          screen-input     = g_inp.
        ELSE.
          screen-invisible = 1.
          screen-active    = 0.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR'
        OR 'OUTVDATE'.
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
    IF screen-name = 'ORGLVL-LOW' OR screen-name = 'ORGLVL-HIGH'.
      IF orgchk NE 'X'.
        screen-input    = 0.
      ELSE.
        screen-input    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    IF screen-group1 = 'CUS'.
      IF gf_central_uid = 'X'.
        screen-invisible = 0.
        screen-active    = 1.
      ELSE.
        screen-invisible = 1.
        screen-active    = 0.
      ENDIF.

      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  DATA:
    g_installed      TYPE /psyng/bapiflagx,
    g_module_version TYPE  /psyng/prog_vrsio,
    g_swconfig       TYPE /psyng/swconfig.

*--Check if ER is installed/ deactivate ER buttons
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'ER'
    IMPORTING
      e_installed      = g_installed
      e_module_version = g_module_version.
  IF g_installed <> 'X' OR g_module_version < '3.0'.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
  CLEAR : g_installed, g_module_version.


*-- Check if EN is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'EN'
    IMPORTING
      e_installed      = g_installed
      e_module_version = g_module_version.
  LOOP AT SCREEN.
    IF g_installed <> 'X'.
      IF screen-name = 'P_NABAP' OR
*      screen-name = 'P_ABAP'
*      OR screen-name = '%_P_ABAP_%_APP_%-TEXT' OR
       screen-name = '%_P_NABAP_%_APP_%-TEXT'
      OR screen-name = 'S_APPL-LOW'
      OR screen-name = 'S_APPL-HIGH'
      OR screen-name = '%_S_APPL_%_APP_%-TEXT'
*   OR screen-name = '%_S_APPL_%_APP_%-OPTI_PUSH'
      OR screen-name =  '%_S_APPL_%_APP_%-VALU_PUSH'
      OR screen-name =  '%_S_SYSTEM_%_APP_%-TEXT'

      OR screen-name = 'S_SYSTEM-LOW'
      OR screen-name = 'S_SYSTEM-HIGH'
   OR screen-name = '%_S_SYSTEM_%_APP_%-VALU_PUSH'
      OR screen-name = '%_S_SYSTEM_%_APP_%-VALU_PUSH'.
*        screen-group2 = 'EN'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.


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
  exelog sy-repid ''.
  IF exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (sy-repid)                        "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_155
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET curr_variant .
  ENDIF.
  PERFORM get_rfc_destinations.
  IF sodcon = 'X' OR criaut = 'X'.
    PERFORM get_users.
  ENDIF.

  IF sodcon = 'X'.
    PERFORM get_mc_content.
  ENDIF.

  IF criaut = 'X'.
    PERFORM get_miti_cri_auths.
    APPEND LINES OF gt_mcuser_ca TO mcuser.
  ENDIF.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH text-001.
  ELSE.
    IF mcuser[] IS INITIAL AND p_notify IS INITIAL.
      MESSAGE s002(/psyng/sw) WITH
      'No Mitigation data found for the'(037)
      'corressponding input.'(038).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.
  IF no_disp IS INITIAL.
    PERFORM remove_not_needed_usergoups.
    IF sy-batch = 'X'.
      PERFORM process_background.
    ELSE.
      PERFORM output_alv.
    ENDIF.
  ENDIF.


*  IF obscheck = 'X'.
*    PERFORM check_for_mitigations.
**--Check if any assignments are obsolete
*    READ TABLE mcuser WITH KEY obsolete = 'X'
*    TRANSPORTING NO FIELDS.
*    IF sy-subrc <> 0.
*      MESSAGE s002(/psyng/sw) WITH
*      'No user Mitigation Assignments found.'(089).
*    ELSE.
*      IF obsexp = 'X'.
*        IF sy-binpt IS INITIAL AND sy-batch IS INITIAL AND
*        no_disp IS INITIAL.
*          CALL FUNCTION 'POPUP_TO_CONFIRM'
*            EXPORTING
*              text_question         = text-q01
*              text_button_1         = text-021
*              icon_button_1         = 'ICON_OKAY'
*              text_button_2         = text-022
*              icon_button_2         = 'ICON_CANCEL'
*              default_button        = '2'
*              display_cancel_button = space
*            IMPORTING
*              answer                = lf_answer
*            EXCEPTIONS
*              text_not_found        = 1
*              OTHERS                = 2.
*          IF sy-subrc <> 0.
*            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*          ENDIF.
*        ELSE.
*          lf_answer = '1'.
*        ENDIF.
*
*        IF lf_answer = '1'.
*          mcuser-mark = 'X'.
*          MODIFY mcuser TRANSPORTING mark WHERE obsolete = 'X'.
*          PERFORM expire_all_marked_mit.
*          mcuser-mark = ' '.
*          MODIFY mcuser TRANSPORTING mark WHERE obsolete = 'X'.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  get_mc_content
*&---------------------------------------------------------------------*
FORM get_mc_content.
  DATA: lt_conflicts TYPE  TABLE OF /psyng/conflict.

  DATA : lt_uinfo           TYPE TABLE OF /psyng/sw_uinfo_remote WITH
                          HEADER LINE,
         l_usercount        TYPE i,
         lt_user_mapping    TYPE TABLE OF /psyng/sw_user_mapping,
         lt_user_range      TYPE TABLE OF /psyng/sw_sel_opts_xubname
                          WITH HEADER LINE,
         lt_user_range_part TYPE TABLE OF /psyng/sw_sel_opts_xubname
                          WITH HEADER LINE,

         l_local_sys        TYPE rfcdes,
         l_fromdate         TYPE dats,
         l_todate           TYPE dats,
         lt_assignment_part
                          TYPE TABLE OF /psyng/mitigation_assignment
                          WITH HEADER LINE,
         l_system_msg(80)   TYPE c,
         l_sytabix          TYPE sy-tabix,
         l_map_tabix        TYPE sy-tabix.
  FREE : lt_uinfo[].
  REFRESH : lt_uinfo[].

*--Load mitigations
  IF expcn = 'X'.
    CLEAR l_fromdate.
    CLEAR l_todate   .

  ELSE.
    l_fromdate = sy-datum.
    l_todate   = sy-datum.
  ENDIF.
* add local system to list of rfc destinations
  IF p_remonl NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
    gt_rfcdest-rfcoptions = l_local_sys.
    APPEND gt_rfcdest.
  ENDIF.



  SORT gt_user_mapping BY target_rfc source_bname.
  LOOP AT gt_rfcdest.
    REFRESH : lt_user_range[],
              lt_assignment_part[].

    lt_user_range-sign   = 'I'.
    lt_user_range-option = 'EQ'.

    IF s_class[]  IS INITIAL AND
       s_comp[]   IS INITIAL AND
       s_depart[] IS INITIAL AND
       s_cuid[]   IS INITIAL AND
       usrtype[]  IS INITIAL.
*--If no user master info restrictions are entered,
*users that don't
*  exist will also be loaded, so use the full username range from
*  selection screen.
      lt_user_range[] = userid[].
      IF lt_user_range[] IS INITIAL.
        lt_user_range-low = '*'.
        lt_user_range-option = 'CP'.
        APPEND lt_user_range.
      ENDIF.
    ELSE.
      LOOP AT gt_uinfo ASSIGNING <uinfo>.
        READ TABLE gt_user_mapping WITH KEY
         target_rfc   =  l_local_sys
         source_bname = <uinfo>-bname
         BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_map_tabix = sy-tabix.
          LOOP AT gt_user_mapping ASSIGNING <map>
          FROM l_map_tabix.
            IF <map>-target_rfc   <> l_local_sys OR
               <map>-source_bname <> <uinfo>-bname.
              EXIT.
            ENDIF.
            lt_user_range-low = <uinfo>-bname.
            COLLECT lt_user_range.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDIF.

*--Load mitigations for this system.
    IF gt_rfcdest-rfcoptions = l_local_sys.

      WHILE NOT lt_user_range[] IS INITIAL.
        REFRESH lt_user_range_part.
        REFRESH lt_assignment_part.
        APPEND LINES OF lt_user_range FROM 1 TO 2500
        TO lt_user_range_part.
        DELETE lt_user_range FROM 1 TO 2500.

        CALL FUNCTION '/PSYNG/SW_071'
          EXPORTING
            i_vrsio      = sodvrsio
            i_start_date = l_fromdate
            i_end_date   = l_todate
          TABLES
            it_users     = lt_user_range_part
            it_confs     = conid
            it_contid    = contid
            et_mcusers   = lt_assignment_part.
        DELETE lt_assignment_part WHERE NOT from_date
        IN valid_fr OR NOT to_date IN valid_to.
        PERFORM convert_to_output
          TABLES
            lt_assignment_part
*            lt_conflicts
            lt_uinfo
          USING
            gt_rfcdest.
      ENDWHILE.
    ELSE.
      SORT gt_user_mapping BY target_rfc source_bname.
      LOOP AT gt_uinfo ASSIGNING <uinfo>.
        READ TABLE gt_user_mapping WITH KEY
        target_rfc =  gt_rfcdest-rfcoptions
        source_bname = <uinfo>-bname
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_sytabix = sy-tabix.
          LOOP AT gt_user_mapping ASSIGNING <map>
          FROM l_sytabix.
            lt_user_range-low = <uinfo>-bname.
            COLLECT lt_user_range.
            IF <map>-target_rfc NE gt_rfcdest-rfcoptions OR
             <map>-source_bname NE <uinfo>-bname.
              EXIT.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDLOOP.

      WHILE NOT lt_user_range[] IS INITIAL.
        REFRESH lt_user_range_part.
        REFRESH lt_assignment_part.
        APPEND LINES OF lt_user_range FROM 1 TO 2500
        TO lt_user_range_part.
        DELETE lt_user_range FROM 1 TO 2500.
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
        CALL FUNCTION '/PSYNG/SW_071'
          DESTINATION gt_rfcdest-rfcdest
          EXPORTING
            i_vrsio               = sodvrsio
            i_start_date          = l_fromdate
            i_end_date            = l_todate
          TABLES
            it_users              = lt_user_range_part
            it_confs              = conid
            it_contid             = contid
            et_mcusers            = lt_assignment_part
          EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e03
              gt_rfcdest-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e03
              gt_rfcdest-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ELSE.
          DELETE lt_assignment_part WHERE NOT from_date
                                    IN valid_fr
                                    OR NOT to_date IN valid_to.

          PERFORM convert_to_output
          TABLES
            lt_assignment_part
*            lt_conflicts
            lt_uinfo
          USING
            gt_rfcdest.
        ENDIF.
      ENDWHILE.
    ENDIF.
  ENDLOOP.

  DELETE gt_rfcdest WHERE rfcoptions = l_local_sys.

ENDFORM.                    " get_mc_content
*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
FORM output_alv.
  DATA: program         LIKE sy-repid,            "For ALV call
        i_fieldcat_alv  TYPE slis_t_fieldcat_alv, "For ALV call
        alv_layout      TYPE slis_layout_alv,     "For ALV call
        wa_fieldcat_alv TYPE slis_fieldcat_alv,
        ls_variant      TYPE disvariant.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_layout-box_fieldname = 'MARK'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'MCUSER'
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

  wa_fieldcat_alv-seltext_l = text-088.
  wa_fieldcat_alv-seltext_m = text-088.
  wa_fieldcat_alv-seltext_s = text-012.
  wa_fieldcat_alv-reptext_ddic = text-012.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CONTDESC'.



  wa_fieldcat_alv-seltext_l = text-024.
  wa_fieldcat_alv-seltext_m = text-024.
  wa_fieldcat_alv-seltext_s = text-023.
  wa_fieldcat_alv-reptext_ddic = text-024.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.


  wa_fieldcat_alv-seltext_l = text-008.
  wa_fieldcat_alv-seltext_m = text-008.
  wa_fieldcat_alv-seltext_s = text-008.
  wa_fieldcat_alv-reptext_ddic = text-008.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'VRSIO'.
*******************************************
  wa_fieldcat_alv-seltext_l = text-003.
  wa_fieldcat_alv-seltext_m = text-003.
  wa_fieldcat_alv-seltext_s = text-003.
  wa_fieldcat_alv-reptext_ddic = text-003.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDITOR'.

*  IF sodcon = 'X'.
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
                      fieldname = 'CONID'.
*  ENDIF.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                       hotspot
                   WHERE
                      fieldname = 'CONTID'.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                       hotspot
                   WHERE
                      fieldname = 'CONID'.


*  IF criaut = 'X'.
*    wa_fieldcat_alv-seltext_l = text-033.
*    wa_fieldcat_alv-seltext_m = text-032.
*    wa_fieldcat_alv-seltext_s = text-032.
*    wa_fieldcat_alv-reptext_ddic = text-032.
*    wa_fieldcat_alv-hotspot = 'X'.
*    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                      TRANSPORTING
*                        seltext_l
*                        seltext_m
*                        seltext_s
*                        reptext_ddic
*                        hotspot
*                     WHERE
*                        fieldname = 'SWAUDID'.
*  ENDIF.


  wa_fieldcat_alv-seltext_l    = 'Usergroup Assignment'(040).
  wa_fieldcat_alv-seltext_m    = 'Usergroup Assignment'(040).
  wa_fieldcat_alv-seltext_s    = 'Usergroup Assignment'(040).
  wa_fieldcat_alv-reptext_ddic = 'Usergroup Assignment'(040).
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
                      fieldname = 'ASG_GRP'.

  wa_fieldcat_alv-seltext_l    = 'Role Assignment'(041).
  wa_fieldcat_alv-seltext_m    = 'Role Assignment'(041).
  wa_fieldcat_alv-seltext_s    = 'Role Assignment'(041).
  wa_fieldcat_alv-reptext_ddic = 'Role Assignment'(041).
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
                      fieldname = 'ASG_ROL'.



*  DELETE i_fieldcat_alv WHERE fieldname = 'ASG_GRP'.
*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column. This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l = 'User Assignment'(006).
  wa_fieldcat_alv-seltext_m = 'User Assignment'(006).
  wa_fieldcat_alv-seltext_s = 'User Assignment'(006).
  wa_fieldcat_alv-reptext_ddic = 'User Assignment'(006).
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'ASG_USR'.

*  DELETE i_fieldcat_alv WHERE fieldname = 'ASG_ROL'.
*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
  wa_fieldcat_alv-seltext_l = text-007.
  wa_fieldcat_alv-seltext_m = text-007.
  wa_fieldcat_alv-seltext_s = text-007.
  wa_fieldcat_alv-reptext_ddic = text-007.
  wa_fieldcat_alv-checkbox = 'X'.
  wa_fieldcat_alv-just = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'APPROVED'.
***************************************************
  wa_fieldcat_alv-seltext_l = text-009.
  wa_fieldcat_alv-seltext_m = text-009.
  wa_fieldcat_alv-seltext_s = text-009.
  wa_fieldcat_alv-reptext_ddic = text-009.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TYPE'.

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
                      fieldname = 'COMPANY'.

  wa_fieldcat_alv-seltext_l = 'Auditor Company'(026).
  wa_fieldcat_alv-seltext_m = 'Auditor Company'(026).
  wa_fieldcat_alv-seltext_s = 'Auditor Company'(026).
  wa_fieldcat_alv-reptext_ddic = 'Auditor Company'(026).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDCOMPANY'.

  wa_fieldcat_alv-seltext_l = text-087.
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
                      fieldname = 'MITTYPE_TEXT'.
  wa_fieldcat_alv-seltext_l = 'Central user ID'(013).
  wa_fieldcat_alv-seltext_m = 'Central user ID'(013).
  wa_fieldcat_alv-seltext_s = 'Central user ID'(013).
  wa_fieldcat_alv-reptext_ddic = 'Central user ID'(013).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CENTRAL_UID'.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column. This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l    = 'Obsolete'(015).
  wa_fieldcat_alv-seltext_m    = 'Obsolete'(015).
  wa_fieldcat_alv-seltext_s    = 'Obsolete'(015).
  wa_fieldcat_alv-reptext_ddic = 'Obsolete'(015).
  wa_fieldcat_alv-checkbox     = 'X'.
  wa_fieldcat_alv-just    = 'X'.
  IF obscheck IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
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
                      fieldname = 'OBSOLETE'.


  wa_fieldcat_alv-seltext_l    = 'Department'(025).
  wa_fieldcat_alv-seltext_m    = 'Department'(025).
  wa_fieldcat_alv-seltext_s    = 'Department'(025).
  wa_fieldcat_alv-reptext_ddic = 'Department'(025).
  wa_fieldcat_alv-checkbox     = ' '.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.






  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = ' '.
  wa_fieldcat_alv-seltext_l    = 'Short. Comp. name'(027).
  wa_fieldcat_alv-seltext_m    = 'Short. Comp. name'(027).
  wa_fieldcat_alv-seltext_s    = 'Short. Comp. name'(027).
  wa_fieldcat_alv-reptext_ddic = 'Short. Comp. name'(027).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE fieldname = 'COMPSHORT'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-seltext_l    = 'Assigned to Role'(050).
  wa_fieldcat_alv-seltext_m    = 'Assigned to Role'(050).
  wa_fieldcat_alv-seltext_s    = 'Assigned to Role'(050).
  wa_fieldcat_alv-reptext_ddic = 'Assigned to Role'(050).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE fieldname = 'AGR_NAME'.
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-seltext_l    = 'Assigned to User Group'(051).
  wa_fieldcat_alv-seltext_m    = 'Assigned to User Group'(051).
  wa_fieldcat_alv-seltext_s    = 'Assigned to User Group'(051).
  wa_fieldcat_alv-reptext_ddic = 'Assigned to User Group'(051).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE fieldname = 'ASSN_CLASS'.



  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out       = 'X'.
  wa_fieldcat_alv-seltext_l    = 'Assignment Type'(039).
  wa_fieldcat_alv-seltext_m    = 'Assignment Type'(039).
  wa_fieldcat_alv-seltext_s    = 'Assignment Type'(039).
  wa_fieldcat_alv-reptext_ddic = 'Assignment Type'(039).
  wa_fieldcat_alv-fieldname    = 'ASSN_TYPE'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE fieldname = wa_fieldcat_alv-fieldname.
  IF sy-subrc <> 0.
    APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  ENDIF.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out       = ' '.
  wa_fieldcat_alv-hotspot      = 'X'.
  wa_fieldcat_alv-seltext_l    = 'Assignment Type'(039).
  wa_fieldcat_alv-seltext_m    = 'Assignment Type'(039).
  wa_fieldcat_alv-seltext_s    = 'Assignment Type'(039).
  wa_fieldcat_alv-reptext_ddic = 'Assignment Type'(039).
  wa_fieldcat_alv-fieldname    = 'MIT_ICON'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING
                      no_out
                      hotspot
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE fieldname = wa_fieldcat_alv-fieldname.
  IF sy-subrc <> 0.
    APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  ENDIF.

  CLEAR wa_fieldcat_alv.
  IF gf_mit_by_org <> 'Y'.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING
                      no_out
                   WHERE fieldname = 'ORG_ABB'.


  PERFORM build_sort.
***************************************
  IF sy-batch EQ abap_true.
* Execute this in the background creating a spool file.
    CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
      EXPORTING
        i_callback_program       = program
        i_callback_pf_status_set = 'PF_STATUS'
        i_callback_user_command  = 'USER_CLICK'
        is_layout                = alv_layout
        it_fieldcat              = i_fieldcat_alv
        it_sort                  = l_sort
        i_save                   = 'A'
        is_variant               = ls_variant
      TABLES
        t_outtab                 = mcuser
      EXCEPTIONS
        program_error            = 1
        OTHERS                   = 2.
    IF sy-subrc NE 0.
      MESSAGE e002 WITH 'Error Displaying ALV Grid'(e07) '' '' ''.
    ENDIF.


  ELSE.
* Execute this in the forground creating an ALV grid.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_callback_program       = program
        i_callback_pf_status_set = 'PF_STATUS'
        i_callback_top_of_page   = 'ALV_HEADER'
        i_callback_user_command  = 'USER_CLICK'
        is_layout                = alv_layout
        it_fieldcat              = i_fieldcat_alv
        it_sort                  = l_sort
        i_save                   = 'A'
        is_variant               = ls_variant
      TABLES
        t_outtab                 = mcuser
      EXCEPTIONS
        program_error            = 1
        OTHERS                   = 2.
    IF sy-subrc NE 0.
      MESSAGE e002 WITH 'Error Displaying ALV Grid'(e07) '' '' ''.
    ENDIF.

  ENDIF.

ENDFORM.                    " output_alv
*&---------------------------------------------------------------------*
*&      Form  USER_CLICK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_click USING r_ucomm LIKE sy-ucomm
                      rs_selfield TYPE slis_selfield.

  DATA: l_uname  LIKE sy-uname,
        l_contid TYPE /psyng/mchdr-contid,
        l_parva  TYPE usr05-parva,
        l_sod    TYPE /psyng/swsodvers-vrsio.


  IF r_ucomm = 'EXPIRE'.
    PERFORM expire_all_marked_mit.
  ENDIF.

*Arpan 19.12.2022 delete mitigation START
  IF r_ucomm = 'DELETE'.
    PERFORM delete_all_marked_mit.
  ENDIF.
*Arpan 19.12.2022 delete mitigation END

  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE rs_selfield-fieldname.
    WHEN 'CONTID'.
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

      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD rs_selfield-value.
      g_dynnr = '0211'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD'
      FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.

    WHEN 'ASG_USR' OR 'ASG_GRP' OR 'ASG_ROL' OR 'MIT_ICON'.
      DATA : lt_mcuser_show TYPE TABLE OF
            /psyng/mitigation_assignment
            WITH HEADER LINE,
             l_showuser     TYPE flag,
             l_showgroup    TYPE flag,
             l_showrole     TYPE flag,
             lf_showca      TYPE flag,
             l_local_sys TYPE string. "AKUMAR PN12569
      READ TABLE mcuser INDEX rs_selfield-tabindex.
      CLEAR lt_mcuser_show.
      REFRESH : lt_mcuser_show.
      MOVE-CORRESPONDING mcuser TO lt_mcuser_show.

      IF mcuser-type = 'C'.
        lf_showca = 'X'.
        lt_mcuser_show-swaudid = mcuser-conid.
      ENDIF.
      CLEAR : l_showuser, l_showgroup, l_showrole.

      CASE 'X'.
        WHEN mcuser-asg_usr.
          l_showuser = 'X'.
          lt_mcuser_show-type = 1.
        WHEN mcuser-asg_grp.
          l_showgroup = 'X'.
          lt_mcuser_show-type = 2.
        WHEN mcuser-asg_rol.
          l_showrole = 'X'.
          lt_mcuser_show-type = 4.
      ENDCASE.

      CHECK sy-subrc = 0.
      APPEND lt_mcuser_show.

*BOC AKUMAR PN12569
*Uncomment this code when FM 76 will be remote enabled
      CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
      READ TABLE gt_rfcdest WITH KEY rfcoptions = mcuser-rfcdest.

      IF sy-subrc = 0 AND NOT mcuser-rfcdest = l_local_sys.

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

        CALL FUNCTION '/PSYNG/SW_076'
        DESTINATION gt_rfcdest-rfcdest
          EXPORTING
            if_display          = 'X'
            if_call_from_report = 'X'
            if_show_criauth     = lf_showca
            if_show_class       = l_showgroup
            if_show_role        = l_showrole
          TABLES
            it_mcuser           = lt_mcuser_show
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
          EXCEPTIONS
            communication_failure       = 1
            system_failure              = 2
            OTHERS                      = 3. "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      ELSE.

        CALL FUNCTION '/PSYNG/SW_076'
          EXPORTING
            if_display          = 'X'
            if_call_from_report = 'X'
            if_show_criauth     = lf_showca
            if_show_class       = l_showgroup
            if_show_role        = l_showrole
          TABLES
            it_mcuser           = lt_mcuser_show.

      ENDIF.
*BOC AKUMAR PN12569

    WHEN 'CONID'.
      READ TABLE mcuser INDEX rs_selfield-tabindex.
      IF mcuser-type = 'S'.
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
        SET PARAMETER ID '/PSYNG/CON' FIELD rs_selfield-value.
        g_dynnr = '0202'.
        EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD'
        FIELD '/PSYNG/SE'.
        IF sy-subrc <> 0.
          MESSAGE e077(s#) WITH '/PSYNG/SE'.
        ELSE.
          CALL TRANSACTION '/PSYNG/SE'.
        ENDIF.
*-- Set back to Default
        PERFORM set_default_sodversion USING l_sod l_uname.
      ELSEIF mcuser-type = 'C'.
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
        SET PARAMETER ID '/PSYNG/SW_CRIT_AUTH'
        FIELD rs_selfield-value.
        g_dynnr = '0209'.
        EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
        IF sy-subrc <> 0.
          MESSAGE e077(s#) WITH '/PSYNG/SE'.
        ELSE.
          CALL TRANSACTION '/PSYNG/SE'.
        ENDIF.
*-- Set back to Default
        PERFORM set_default_sodversion USING l_sod l_uname.
      ENDIF.
      EXIT.
  ENDCASE.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort.
  DATA: w_sort TYPE slis_sortinfo_alv.

  w_sort-spos = '1'.
  w_sort-fieldname = 'RFCDEST'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '2'.
  w_sort-fieldname = 'TYPE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '3'.
  w_sort-fieldname = 'CONTID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '4'.
  w_sort-fieldname = 'CONTDESC'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '5'.
  w_sort-fieldname = 'MITTYPE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '6'.
  w_sort-fieldname = 'MITTYPE_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '7'.
  w_sort-fieldname = 'CONID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '8'.
  w_sort-fieldname = 'CONDESC'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '9'.
  w_sort-fieldname = 'CLASS'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '10'.
  w_sort-fieldname = 'USERID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '11'.
  w_sort-fieldname = 'NAME_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '12'.
  w_sort-fieldname = 'COMPSHORT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '13'.
  w_sort-fieldname = 'DEPARTMENT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '14'.
  w_sort-fieldname = 'CENTRAL_UID'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '15'.
  w_sort-fieldname = 'VRSIO'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '16'.
  w_sort-fieldname = 'ASG_USR '.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '18'.
  w_sort-fieldname = 'AUDITOR'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '19'.
  w_sort-fieldname = 'COMPANY'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '20'.
  w_sort-fieldname = 'AUDITOR_NAME_TEXT'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '21'.
  w_sort-fieldname = 'AUDCOMPANY'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.


  w_sort-spos = '22'.
  w_sort-fieldname = 'FROM_DATE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

  w_sort-spos = '23'.
  w_sort-fieldname = 'TO_DATE'.
  w_sort-tabname = 'MCUSER'.
  w_sort-up = 'X'.
  APPEND w_sort TO l_sort.
  CLEAR w_sort.

ENDFORM.                    " BUILD_SORT


*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo_remote
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
            vrsio    TYPE /psyng/sodvrsio,
            class    TYPE xuclass,
            company  TYPE char20,
            rejected TYPE flag,
          END OF typ_rpoug.
  DATA: l_comp TYPE char20.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug
  WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
    lt_rpoug-vrsio = i_vrsio.
    lt_rpoug-class = is_uinfo-class.
    lt_rpoug-company = is_uinfo-company.
    l_comp = is_uinfo-company.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD l_comp.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD l_comp.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.

ENDFORM.                    " check_rpoug_auth

*&---------------------------------------------------------------------*
*&      Form  get_user_comp
*&---------------------------------------------------------------------*
*       Get user's company
*----------------------------------------------------------------------*
*      -->I_BNAME    User ID
*      <--E_COMPANY  Company
*----------------------------------------------------------------------*
FORM get_user_comp USING    i_bname TYPE /psyng/mcauditor-auditor
                            i_rfcdest TYPE rfcdes
                             i_auditor TYPE flag
                   CHANGING e_company TYPE /psyng/mcauditor-company
                            e_uinfo   TYPE /psyng/sw_uinfo_remote.
  TYPES: BEGIN OF t_user.
*           bname   TYPE /psyng/sw_uinfo-bname,
*           company TYPE /psyng/sw_uinfo-company,
           INCLUDE STRUCTURE /psyng/sw_uinfo_remote.
         TYPES: END OF t_user.
  RANGES : lt_class_dum FOR mcuser-class,
         lt_comp_dum  FOR mcuser-company,
         lt_depart_dum FOR mcuser-department,
         lt_cuid_dum  FOR mcuser-central_uid,
         lt_bname FOR mcuser-userid
         .
  DATA : lt_user_mapping_dum TYPE TABLE OF /psyng/sw_user_mapping,
         l_usercount         TYPE i,
         lt_utype_dum        TYPE TABLE OF /psyng/sw_sel_opts_usrtyp.

  STATICS: lt_user TYPE HASHED TABLE OF /psyng/sw_uinfo_remote
  WITH UNIQUE KEY bname.

  DATA: ls_user  TYPE t_user,
        lt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote
        WITH HEADER LINE.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.

  CLEAR e_company.
  READ TABLE lt_user INTO ls_user WITH TABLE KEY bname = i_bname.
  IF sy-subrc = 0.
    e_company = ls_user-company.
    e_uinfo   = ls_user.
    EXIT.
  ELSE.
*--Check if this is a mitigated user and we already have the info
    READ TABLE gt_uinfo INTO ls_user WITH KEY bname = i_bname.
    IF sy-subrc = 0.
      INSERT ls_user INTO TABLE lt_user.
      e_company = ls_user-company.
      e_uinfo   = ls_user.
      EXIT.
    ENDIF.
  ENDIF.

  lt_uinfo-bname = i_bname.
  lt_bname-low = i_bname.
  lt_bname-option = 'EQ'.
  lt_bname-sign = 'I'.
  APPEND lt_bname.

*--Load users
  PERFORM get_user_info
    TABLES
      lt_bname
      lt_class_dum
      lt_comp_dum
      lt_depart_dum
      lt_cuid_dum
      lt_utype_dum
      lt_uinfo
      gt_rfcdest
      lt_user_mapping_dum
    USING
*-- We can Read auditor Info irrespective of User validity
*PS3 Changes
       ' '
       ' '
       ' '
       ' '
       ' '
       sodvrsio
       p_remonl
     CHANGING
       l_usercount.
  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.
  IF i_auditor IS INITIAL.
    PERFORM set_user_master_prio
  TABLES
    lt_uinfo
    gt_rfcdest
    s_comp
    s_depart
    s_class.
  ENDIF.

  READ TABLE lt_uinfo INDEX 1.
  INSERT lt_uinfo INTO TABLE lt_user.
  e_uinfo = lt_uinfo.
  e_company = lt_uinfo-company.
ENDFORM.                    " get_user_comp
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
    IMPORTING
      e_vrsio = sodvrsio.

  DATA: swconfig TYPE /psyng/swconfig.
*Valid & Dialog Users only
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
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

*--Central User ID search Help
*--Check what FM is configured for Central Userid information
  DATA : ls_fmname TYPE rs38l_fnam.


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
      gf_central_uid = 'X'.
    ENDIF.
  ENDIF.

* Default RFC
  IF xusrrfc[] IS INITIAL.
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

*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv
*            FROM (l_table)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO xusrrfc.
      xusrrfc-option = lt_tvarv-opti.
      APPEND xusrrfc.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_initial_config
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_input.
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest,
        lt_dest2   LIKE TABLE OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest.
  RANGES: lr_dest FOR rfcdes-rfcdest.

* Check RFC destinations
  IF NOT xusrrfc[] IS INITIAL.

    APPEND LINES OF xusrrfc TO lr_dest.

    SELECT rfcdest INTO TABLE lt_dest FROM rfcdes
           WHERE rfcdest IN lr_dest.
    IF sy-subrc <> 0.
      MESSAGE e004(sr).
    ENDIF.

    SORT lt_dest BY rfcdest.
    LOOP AT lt_dest.
      CLEAR lt_dest2.
      APPEND lt_dest TO lt_dest2.
      FREE : lt_rfc_log.
      CALL FUNCTION 'RFC_WALK_THRU_TEST'
        EXPORTING
          test_in      = l_rfc_test
*         IMPORTING
*         TEST_OUT     =
        TABLES
          destinations = lt_dest2
          log          = lt_rfc_log.
      LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
        PERFORM report_rfc_error USING
        lt_rfc_log-rfcdest lt_rfc_log-rfclog.
      ENDLOOP.
    ENDLOOP.
  ENDIF.



*****  org level  checck
*  IF sy-ucomm = 'ORG'.
  IF orgchk NE 'X'.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'ORGLVL-LOW' OR 'ORGLVL-HIGH'.
          screen-active = 0.
          MODIFY SCREEN.
        WHEN 'OTHERS'.
          screen-active = 1.
      ENDCASE.
    ENDLOOP.
  ENDIF.
*  ENDIF.
*Remote only analysis

  IF sy-ucomm = 'REMO'.                "#EC SAST_CI_GEN_CHECK (HBHALLA)
    IF p_remonl = 'X'.
      CLEAR : p_local, p_cross.
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'P_LOCAL' OR 'P_CROSS'.
            screen-input = 0.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.
      p_remote = 'X'.
      IF lt_dest[] IS INITIAL.
        MESSAGE w140 WITH
        'Please enter RFC destinations for remote analysis'(184).
      ENDIF.
    ELSE.
      p_local = 'X'.
    ENDIF.
  ENDIF.

  IF p_cross = 'X'.
    IF lt_dest[] IS INITIAL AND p_nabap IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for Cross system analysis'(185).
    ENDIF.
  ENDIF.


ENDFORM.                    " check_input
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
*&      Form  get_rfc_destinations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_rfc_destinations.
  CHECK NOT xusrrfc[] IS INITIAL.
  DATA : l_rfcdest        TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys      TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  SELECT rfcdest INTO TABLE gt_rfcdest FROM rfcdes
         WHERE rfcdest IN xusrrfc.
  IF sy-subrc <> 0.
    MESSAGE e004(sr).
  ENDIF.
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
        e_rfcdest             = l_rfcdest
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
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
*&      Form  get_user_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USERS  text
*      -->P_LT_UINFO  text
*----------------------------------------------------------------------*
FORM get_user_info TABLES
    it_users STRUCTURE /psyng/sw_sel_opts_xubname
    it_usergroup STRUCTURE /psyng/range_class
    it_company STRUCTURE /psyng/range_company
    it_department STRUCTURE /psyng/range_department
    it_central_uid STRUCTURE /psyng/range_central_uid
    it_usertype STRUCTURE /psyng/sw_sel_opts_usrtyp
    et_uinfo STRUCTURE /psyng/sw_uinfo_remote
    it_rfcdes STRUCTURE rfcdes
    et_user_mapping STRUCTURE /psyng/sw_user_mapping
  USING
    i_validuser TYPE flag
    i_exlckusr  TYPE flag
    i_outvdate  TYPE flag
    i_allug     TYPE flag
    i_locusr    TYPE flag
    i_vrsio     TYPE /psyng/sodvrsio
    i_remote_only TYPE flag
  CHANGING e_usercount.




  DATA : l_tusercount_dum     TYPE i,
         lt_usr02             TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_unique_users_dum  TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_iduser_dum        TYPE TABLE OF /psyng/sw_iduser_fm,
         ls_uinfo             TYPE /psyng/sw_uinfo,
         lt_uinfo_remote_map  TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_uinfo             TYPE TABLE OF /psyng/sw_uinfo,
         ls_uinfo_remote      TYPE /psyng/sw_uinfo_remote,
         l_rfcdest            TYPE rfcdest,
         l_usercount          TYPE i,
         lf_match             TYPE flag,
         l_maptabix           LIKE sy-tabix,
         lt_uinfo_sorted      TYPE SORTED TABLE OF
         /psyng/sw_uinfo_remote
         WITH UNIQUE KEY rfcdest bname  WITH HEADER LINE,
         ls_swconfig          TYPE /psyng/swconfig,
         lf_sod_single_comp   TYPE flag,
         lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
         ls_rfc               TYPE rfcdes,
         lf_valid             TYPE flag.
  FIELD-SYMBOLS : <usr02> TYPE /psyng/sw_uinfo_remote,
                  <uinfo> TYPE /psyng/sw_uinfo.

  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF ls_swconfig-value = 'Y'.
    lf_sod_single_comp = 'X'.
  ENDIF.
  MESSAGE s398(00) WITH  'Loading user information'(l19).
  COMMIT WORK.

*--Get all users matching conditions on ALL selected systems
  PERFORM get_selected_users
                TABLES
                   it_users
                   it_usergroup
                   it_rfcdes
                   it_usertype
                   lt_iduser_dum
                   lt_usr02
                   lt_unique_users_dum
                   et_user_mapping
                USING
                   i_validuser
                   i_exlckusr
                   i_outvdate
                   i_allug
                   i_locusr
                   l_tusercount_dum
                   'X' "do user mapping
                   i_remote_only
.
  SORT lt_usr02.
  DELETE ADJACENT DUPLICATES FROM lt_usr02.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*  DESCRIBE TABLE lt_usr02 LINES e_usercount.



  IF lf_sod_single_comp = 'X' AND NOT it_usergroup[]
    IS INITIAL.
    LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
      rfcdest <> l_rfcdest.
      ls_uinfo-bname =  <usr02>-bname.
      ls_uinfo_remote-bname   = <usr02>-bname.
      ls_uinfo_remote-rfcdest = l_rfcdest.
      APPEND ls_uinfo TO lt_uinfo.
      READ TABLE et_user_mapping WITH KEY
      target_rfc   = ls_uinfo_remote-rfcdest
      source_bname = ls_uinfo_remote-bname.
      CHECK NOT sy-subrc = 0.
      APPEND ls_uinfo_remote TO lt_uinfo_remote_map.
    ENDLOOP.
    IF NOT i_remote_only = 'X'.
      ls_rfc-rfcdest = 'LOCAL'.
      IF NOT lt_uinfo_remote_map[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = ls_rfc
          TABLES
            it_users     = lt_uinfo_remote_map
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part TO et_user_mapping.
        FREE : lt_user_mapping_part.
      ENDIF.
    ENDIF.
  ENDIF.
  LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
    rfcdest = l_rfcdest.
    ls_uinfo-bname =  <usr02>-bname.
    APPEND ls_uinfo TO lt_uinfo.
  ENDLOOP.
  SORT lt_uinfo.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

*    FREE : lt_usr02.
*  CHECK NOT lt_uinfo[] IS INITIAL.
  IF NOT lt_uinfo[] IS INITIAL AND NOT i_remote_only = 'X'.
*  --Get local names for users
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
      EXPORTING
        i_name_only     = 'X'
        i_mr_company    = 'X'
        i_mr_department = 'X'
        i_central_uid   = 'X'
      TABLES
        sw_uinfo        = lt_uinfo.

    IF i_validuser = 'X'.
      LOOP AT lt_uinfo ASSIGNING <uinfo>.
        PERFORM is_user_valid CHANGING <uinfo> lf_valid.
        IF lf_valid IS INITIAL.
          DELETE lt_uinfo WHERE bname = <uinfo>-bname.
        ENDIF.
      ENDLOOP.
    ENDIF.

*  DESCRIBE TABLE lt_uinfo LINES e_usercount.

    LOOP AT lt_uinfo ASSIGNING <uinfo>.
      MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
      ls_uinfo_remote-rfcdest = l_rfcdest.
      APPEND ls_uinfo_remote TO et_uinfo.
    ENDLOOP.
  ENDIF.
*  Get user information from remote system(s)
  LOOP AT it_rfcdes WHERE rfcdest <> 'LOCAL'.
    FREE : lt_uinfo.
    IF lf_sod_single_comp = 'X' AND NOT it_usergroup[]
      IS INITIAL.
      LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
        rfcdest <> it_rfcdes-rfcoptions.
        ls_uinfo-bname =  <usr02>-bname.
        ls_uinfo_remote-bname   = <usr02>-bname.
        ls_uinfo_remote-rfcdest = it_rfcdes-rfcoptions.
        APPEND ls_uinfo TO lt_uinfo.
        READ TABLE et_user_mapping WITH KEY
        target_rfc   = ls_uinfo_remote-rfcdest
        source_bname = ls_uinfo_remote-bname.
        CHECK NOT sy-subrc = 0.
        APPEND ls_uinfo_remote TO lt_uinfo_remote_map.
      ENDLOOP.
      ls_rfc-rfcdest = it_rfcdes-rfcdest.
      IF NOT lt_uinfo_remote_map[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = ls_rfc
          TABLES
            it_users     = lt_uinfo_remote_map
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part
                     TO et_user_mapping.
        FREE : lt_user_mapping_part.
      ENDIF.
    ENDIF.
    LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
      rfcdest = it_rfcdes-rfcoptions.
      ls_uinfo-bname =  <usr02>-bname.
      APPEND ls_uinfo TO lt_uinfo.
    ENDLOOP.

    CHECK NOT lt_uinfo[] IS INITIAL.
*    --Get local names for users
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
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
      DESTINATION it_rfcdes-rfcdest
      EXPORTING
        i_name_only           = 'X'
        i_mr_company          = 'X'
        i_mr_department       = 'X'
        i_central_uid         = 'X'
      TABLES
        sw_uinfo              = lt_uinfo
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
          it_rfcdes-rfcdest
          g_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e03
          it_rfcdes-rfcdest.
      ENDCASE.
      COMMIT WORK.
    ENDIF.

    IF i_validuser = 'X'.
      LOOP AT lt_uinfo ASSIGNING <uinfo>.
        PERFORM is_user_valid CHANGING <uinfo> lf_valid.
        IF lf_valid IS INITIAL.
          DELETE lt_uinfo WHERE bname = <uinfo>-bname.
        ENDIF.
      ENDLOOP.
    ENDIF.

    LOOP AT lt_uinfo ASSIGNING <uinfo>.
      MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
*--DHORIONS 20101201 - We don't need the RFC dstination name,
*                      but the
*                      concatenation of system id and client,
*                      which is
*                      stored in RFCOPTIONS field
*     ls_uinfo_remote-rfcdest = it_rfcdes-rfcdest.
      ls_uinfo_remote-rfcdest = it_rfcdes-rfcoptions.
      APPEND ls_uinfo_remote TO et_uinfo.
    ENDLOOP.
  ENDLOOP.
  FREE : lt_usr02.
  SORT et_uinfo BY rfcdest bname.


  it_rfcdes-rfcdest  = 'LOCAL'.
  CONCATENATE sy-sysid sy-mandt INTO it_rfcdes-rfcoptions.
*append it_rfcdes.
  INSERT it_rfcdes INDEX 1.
*--DHORIONS :
  SORT et_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_uinfo
  COMPARING rfcdest bname.
  lt_uinfo_sorted[] = et_uinfo[].
  FREE : et_uinfo[].

  SORT et_user_mapping BY target_bname target_rfc source_bname.
  LOOP AT it_rfcdes.
    LOOP AT lt_uinfo_sorted ASSIGNING <usr02> WHERE
    rfcdest = it_rfcdes-rfcoptions.
      IF NOT <usr02>-department IN it_department OR
         NOT <usr02>-company    IN it_company    OR
         NOT <usr02>-central_uid IN it_central_uid.
        CLEAR lf_match.
        READ TABLE et_user_mapping
        WITH KEY target_bname = <usr02>-bname
                                BINARY SEARCH
                       TRANSPORTING NO FIELDS.
        l_maptabix = sy-tabix.

        LOOP AT et_user_mapping FROM l_maptabix
        WHERE target_bname =  <usr02>-bname AND
                                      target_rfc <> <usr02>-rfcdest.

          READ TABLE lt_uinfo_sorted
          INTO ls_uinfo_remote

          WITH TABLE KEY
           rfcdest = et_user_mapping-target_rfc
           bname   = et_user_mapping-target_bname.
          IF sy-subrc = 0.
            IF  ls_uinfo_remote-department IN it_department AND
                ls_uinfo_remote-company    IN it_company    AND
                ls_uinfo_remote-central_uid IN it_central_uid.
              lf_match = 'X'.
*              append ls_uinfo_remote to et_uinfo.
              APPEND <usr02> TO et_uinfo.
              EXIT.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ELSE.
        APPEND <usr02> TO et_uinfo.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
  DELETE it_rfcdes WHERE rfcdest = 'LOCAL'.
  SORT et_user_mapping BY source_bname target_rfc.
  DATA : lf_reject TYPE flag.



  DESCRIBE TABLE et_uinfo LINES l_usercount.
  ADD l_usercount TO e_usercount.



ENDFORM.                    " get_user_info
*&---------------------------------------------------------------------*
*&      Form  get_selected_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USERS  text
*      -->P_IT_USERGROUP  text
*      -->P_LT_RFCDES  text
*      -->P_LT_USERS  text
*      -->P_I_VALIDUSER  text
*      -->P_I_ALLUG  text
*      -->P_L_TUSERCOUNT  text
*----------------------------------------------------------------------*
FORM get_selected_users
     TABLES
       it_users        STRUCTURE /psyng/sw_sel_opts_xubname
       it_usergroup    STRUCTURE  /psyng/range_class
       it_rfcdes       STRUCTURE rfcdes
       it_usrtype      STRUCTURE /psyng/sw_sel_opts_usrtyp
       it_iduser       STRUCTURE /psyng/sw_iduser_fm
       et_users        STRUCTURE /psyng/sw_uinfo_remote
       et_unique_users STRUCTURE /psyng/sw_uinfo_remote
       et_user_mapping STRUCTURE /psyng/sw_user_mapping
     USING
       i_validuser  TYPE flag
       i_exlckusr   TYPE flag
       i_outvdate   TYPE flag
       i_allug      TYPE flag
       i_locusr     TYPE flag
       e_tusercount TYPE i
       i_do_mapping TYPE flag
       i_remote_only TYPE flag.

  DATA : lt_users             TYPE TABLE OF usr02,
         lt_idusers           TYPE HASHED TABLE OF idusers_typ
                     WITH UNIQUE KEY bname,
         ls_iduser            TYPE idusers_typ,
         lt_local_users       TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_remote_users      TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
         lt_user_mapping_all  TYPE TABLE OF /psyng/sw_user_mapping
         WITH HEADER LINE,
         ls_rfc               TYPE rfcdes,
         lt_users_range       TYPE TABLE OF /psyng/sw_sel_opts_xubname
         WITH HEADER LINE,
         lt_usergroup_range   TYPE TABLE OF /psyng/sw_sel_opts_xubname,
         i_include_locked     TYPE flag,
         i_include_expire     TYPE flag..
  FIELD-SYMBOLS : <usr>    TYPE /psyng/sw_uinfo_remote,
                  <rfc>    TYPE rfcdes,
                  <iduser> TYPE /psyng/sw_iduser_fm,
                  <map>    TYPE /psyng/sw_user_mapping,
                  <usr02>  TYPE usr02.

*--local users
  IF i_validuser IS INITIAL.
    IF i_exlckusr = 'X'.
      CLEAR i_include_locked.
    ELSE.
      i_include_locked = 'X'.
    ENDIF.

    IF i_outvdate = 'X'.
      CLEAR i_include_expire.
    ELSE.
      i_include_expire = 'X'.
    ENDIF.

  ENDIF.

  IF i_remote_only <> 'X'.
    CALL FUNCTION '/PSYNG/SW_041'
      EXPORTING
        i_validuser       = i_validuser
        i_include_locked  = i_include_locked
        i_include_expired = i_include_expire
      TABLES
        et_users          = lt_users
        it_userlist       = it_users
        it_usertype       = it_usrtype
        it_grouplist      = it_usergroup.
    CONCATENATE sy-sysid sy-mandt INTO et_users-rfcdest.

    LOOP AT lt_users ASSIGNING <usr02>.
      MOVE-CORRESPONDING <usr02> TO et_users.
      APPEND et_users.
    ENDLOOP.
*        APPEND LINES OF lt_users TO et_users.
    FREE: lt_users[].
    IF i_do_mapping = 'X'.
*  --Perform user mapping for local users
      ls_rfc-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_060'
        EXPORTING
          i_target_rfc = ls_rfc
        TABLES
          it_users     = et_users
          et_mapping   = lt_user_mapping_part.
      APPEND LINES OF lt_user_mapping_part
                   TO lt_user_mapping_all.
      FREE : lt_user_mapping_part.
    ENDIF.
    lt_local_users[] = et_users[].
  ENDIF.
*--remote users
  IF NOT it_rfcdes[] IS INITIAL.
    LOOP AT it_rfcdes ASSIGNING <rfc>
                          WHERE rfcdest <> 'LOCAL'.
*--If only users that exist locally need to be analyzed, don't use
*  selection screen criteria for the remote users
      IF i_locusr IS INITIAL.
        lt_users_range[] = it_users[].
        lt_usergroup_range[] = it_usergroup[].
      ELSE.
        FREE : lt_users_range[], lt_usergroup_range[].
      ENDIF.

      IF i_do_mapping = 'X'.
*-- Perform User mapping for remote users
        FREE : lt_user_mapping_part.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = <rfc>
          TABLES
            it_users     = lt_local_users
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part
        TO lt_user_mapping_all.
*--Add mapped users to user range
        lt_users_range-sign   = 'I'.
        lt_users_range-option = 'EQ'.
        LOOP AT lt_user_mapping_part ASSIGNING <map>.
          lt_users_range-low = <map>-target_bname.
          APPEND lt_users_range.
        ENDLOOP.
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
          CALL FUNCTION '/PSYNG/SW_041'
            DESTINATION <rfc>-rfcdest
            EXPORTING
              i_validuser           = i_validuser
              i_include_locked      = i_include_locked
              i_include_expired     = i_include_expire
            TABLES
              et_users              = lt_users
              it_userlist           = lt_users_range
              it_usertype           = it_usrtype
              it_grouplist          = it_usergroup
            EXCEPTIONS
              communication_failure = 1 MESSAGE g_system_msg
              system_failure        = 2 MESSAGE g_system_msg
              OTHERS                = 3.         "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1 OR 2.
                MESSAGE e398(00) WITH
                text-e03
                <rfc>-rfcdest
                g_system_msg.
              WHEN 3.
                MESSAGE e398(00) WITH
                text-e03
                <rfc>-rfcdest.
            ENDCASE.
            COMMIT WORK.
          ENDIF.

          LOOP AT lt_users ASSIGNING <usr02>.
            MOVE-CORRESPONDING <usr02> TO et_users.
            et_users-rfcdest = <rfc>-rfcoptions.
            APPEND et_users.
          ENDLOOP.
        ENDIF.
        FREE : lt_user_mapping_part.
      ENDIF.
      REFRESH : lt_users[].
*      APPEND LINES OF lt_users TO et_users.
*--Dhorions 20101013
      IF i_locusr IS INITIAL.
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
        CALL FUNCTION '/PSYNG/SW_041'
          DESTINATION <rfc>-rfcdest
          EXPORTING
            i_validuser           = i_validuser
            i_include_locked      = i_include_locked
            i_include_expired     = i_include_expire
          TABLES
            et_users              = lt_users
            it_userlist           = it_users
            it_usertype           = it_usrtype
            it_grouplist          = it_usergroup
          EXCEPTIONS
            communication_failure = 1 MESSAGE g_system_msg
            system_failure        = 2 MESSAGE g_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e03
              <rfc>-rfcdest
              g_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e03
              <rfc>-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.
        .
        LOOP AT lt_users ASSIGNING <usr02>.
          MOVE-CORRESPONDING <usr02> TO et_users.
          et_users-rfcdest = <rfc>-rfcoptions.
          APPEND et_users.
        ENDLOOP.
      ENDIF.
*-- Perform User mapping for remote users
      LOOP AT lt_users ASSIGNING <usr02>.
        MOVE-CORRESPONDING <usr02> TO lt_remote_users.
        APPEND lt_remote_users.
      ENDLOOP.
      FREE : lt_user_mapping_part.
      CALL FUNCTION '/PSYNG/SW_060'
        EXPORTING
          i_target_rfc = <rfc>
        TABLES
          it_users     = lt_remote_users
          et_mapping   = lt_user_mapping_part.
      APPEND LINES OF lt_user_mapping_part
      TO lt_user_mapping_all.
      FREE : lt_user_mapping_part,lt_remote_users.
*--Dhorions end 20101013
      FREE: lt_users[].

    ENDLOOP.
  ENDIF.


*--check for fake user for role based analysis
  et_users-bname = '000000000000'.
  READ TABLE it_users WITH KEY sign   = 'I'
                               option = 'EQ'
                               low    = et_users-bname.
  IF sy-subrc = 0.
    APPEND  et_users.
    CONCATENATE sy-sysid sy-mandt
    INTO lt_user_mapping_all-target_rfc.
    lt_user_mapping_all-source_bname = et_users-bname.
    lt_user_mapping_all-target_bname = et_users-bname.
    APPEND lt_user_mapping_all.
  ENDIF.
*--delete dupes
  SORT et_users BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_users COMPARING rfcdest bname.

  DESCRIBE TABLE et_users LINES e_tusercount.
  et_unique_users[] = et_users[].
*--Get unique users based on it_idusers
  LOOP AT it_iduser ASSIGNING <iduser>.
    ls_iduser-bname = <iduser>-idbname.
    INSERT ls_iduser INTO TABLE lt_idusers.
  ENDLOOP.
  LOOP AT et_users ASSIGNING <usr>.
    READ TABLE lt_idusers WITH TABLE KEY bname = <usr>-bname
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      DELETE  et_unique_users WHERE bname = <usr>-bname.
    ENDIF.
  ENDLOOP.


  et_user_mapping[] = lt_user_mapping_all[].

ENDFORM.                    " get_selected_users
*&---------------------------------------------------------------------*
*&      Form  is_user_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_UINFO  text
*      <--P_LF_VALID  text
*----------------------------------------------------------------------*
FORM is_user_valid CHANGING is_uinfo TYPE /psyng/sw_uinfo
                            ef_valid.
  STATICS : l_sf_config_checked TYPE flag,
            dsp_mng_lock        VALUE 'N',
            dsp_slf_lock        VALUE 'Y'.
  DATA: swconfig TYPE /psyng/swconfig.
  IF l_sf_config_checked IS INITIAL.
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
    l_sf_config_checked = 'X'.
  ENDIF.


  DATA: yulock TYPE x VALUE '80', "Locked by incorrect login
        yusloc TYPE x VALUE '40', "Locked by Administrator
        yugloc TYPE x VALUE '20'. "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  CLEAR ef_valid.
  IF is_uinfo-gltgv IS INITIAL.
    is_uinfo-gltgv = '00010101'.
  ENDIF.
  IF is_uinfo-gltgb IS INITIAL.
    is_uinfo-gltgb = '99991231'.
  ENDIF.
  IF is_uinfo-gltgv <= sy-datum AND is_uinfo-gltgb >= sy-datum.
*SF Case 1405
    l_uflagx = is_uinfo-uflag."unicode
    IF l_uflagx O yusloc OR "locked by admin
       l_uflagx O yugloc.   "locked by CUA admin
*  --User is locked by Local or Global Administrator
      IF dsp_mng_lock = 'Y'.
        ef_valid = 'X'.
      ENDIF.
    ELSEIF l_uflagx O yulock.
*  --User is locked by failed logins
      IF dsp_slf_lock = 'Y'.
        ef_valid = 'X'.
      ENDIF.
    ELSE.
*  --User is active
      ef_valid = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " is_user_valid
*&---------------------------------------------------------------------*
*&      Form  convert_to_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_RFCDEST  text
*      -->P_LT_ASSIGNMENT_PART  text
*----------------------------------------------------------------------*
FORM convert_to_output
TABLES
  it_assignment STRUCTURE /psyng/mitigation_assignment
*  it_conflicts  STRUCTURE /psyng/conflict
  it_uinfo      STRUCTURE /psyng/sw_uinfo_remote
USING
  i_rfcdest TYPE rfcdes.

  DATA  : lt_conflicts TYPE HASHED  TABLE OF /psyng/conflict
        WITH UNIQUE KEY conid
        WITH HEADER LINE,
          ls_user      TYPE /psyng/sw_uinfo_remote,
          lf_valid     TYPE flag.
  STATICS : lt_types TYPE TABLE OF /psyng/sw_mctype
                     WITH HEADER LINE.
  RANGES : s_user FOR sy-uname.
  DATA : lt_mchdr_s  TYPE HASHED TABLE OF /psyng/mchdr
  WITH HEADER LINE
  WITH UNIQUE KEY contid,
         lt_mchdr    TYPE  TABLE OF /psyng/mchdr,
         l_local_sys TYPE rfcdest,
         lf_reject   TYPE flag.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.


  REFRESH : lt_mchdr_s,lt_mchdr.

  IF lt_types[] IS INITIAL.
*--Get mitigation types, assume they are the same on all systems.
    SELECT * FROM /psyng/sw_mctype                   "#EC CI_SEL_NESTED
      INTO TABLE lt_types.
  ENDIF.

  IF i_rfcdest-rfcoptions = l_local_sys.
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'
      EXPORTING
        i_vrsio = sodvrsio
      TABLES
        mchdr   = lt_mchdr.

  ELSE.
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
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'
      DESTINATION i_rfcdest-rfcdest
      EXPORTING
        i_vrsio               = sodvrsio
      TABLES
        mchdr                 = lt_mchdr
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
          i_rfcdest-rfcdest
          g_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e03
          i_rfcdest-rfcdest.
      ENDCASE.
      COMMIT WORK.
    ENDIF.
  ENDIF.

  RANGES : s_bname FOR sy-uname.
  DATA : lt_1_users TYPE TABLE OF usr02 WITH HEADER LINE.

  SORT lt_mchdr BY contid.
  DELETE ADJACENT DUPLICATES FROM lt_mchdr COMPARING contid.
  lt_mchdr_s[] = lt_mchdr[].

  DATA : lt1_uinfo        TYPE TABLE OF /psyng/sw_uinfo
                          WITH HEADER LINE,
         i_include_locked TYPE flag,
         i_include_expire TYPE flag.

  REFRESH s_bname.
  s_bname-sign = 'I'.
  s_bname-option = 'EQ'.

*-- PS3 Changes Starts
*-- Collect all the users from mitigation assignment
  LOOP AT it_assignment.
    s_bname-low = it_assignment-userid.
    COLLECT s_bname.
  ENDLOOP.

*--authorization checks

*-- Get all the user system wise
*-- Filter out all the mitigated user
  REFRESH lt1_uinfo.
  LOOP AT gt_uinfo WHERE rfcdest = i_rfcdest-rfcoptions
                     AND bname IN s_bname.
    MOVE-CORRESPONDING gt_uinfo TO lt1_uinfo.
    APPEND lt1_uinfo.
  ENDLOOP.



  CLEAR gt_uinfo.
  LOOP AT lt1_uinfo.
    MOVE-CORRESPONDING lt1_uinfo TO gt_uinfo.
    PERFORM check_rpoug_auth USING gt_uinfo sodvrsio
                             CHANGING lf_reject.
    IF lf_reject = 'X'.
      gt_rpoug_auth_fail-bname   = gt_uinfo-bname.
      gt_rpoug_auth_fail-class   = gt_uinfo-class.
      gt_rpoug_auth_fail-company = gt_uinfo-company.
      APPEND gt_rpoug_auth_fail.
      DELETE lt1_uinfo.
      gf_missing_auth_ugroup = 'X'.
      CLEAR gt_rpoug_auth_fail.
    ENDIF.
  ENDLOOP.

*Loop at all types of assignments
  LOOP AT it_assignment." WHERE type = '1'.
*-- This table will have all the valid and authorized users.
    CLEAR lt1_uinfo.
    CHECK it_assignment-auditor IN auditor.
    CLEAR mcuser.
    mcuser-rfcdest   = it_assignment-rfcdest.
    mcuser-contid    = it_assignment-contid.
*--Get mitigation description
    READ TABLE lt_mchdr_s WITH TABLE KEY contid = mcuser-contid.
    IF sy-subrc = 0.
      mcuser-contdesc = lt_mchdr_s-description.
      mcuser-mittype  = lt_mchdr_s-type.
*      mcuser-mittype_text  = lt_mchdr_s-type_text.
      READ TABLE lt_types WITH KEY type = mcuser-mittype.
      IF sy-subrc = 0.
        mcuser-mittype_text = lt_types-text.
      ELSE.
        mcuser-mittype_text
        = 'Not Defined in the system as of now'(211).
      ENDIF.
    ENDIF.
    mcuser-conid     = it_assignment-conid.
*--Get conflict description
    IF i_rfcdest-rfcoptions = l_local_sys.
      CALL FUNCTION '/PSYNG/SW_CR_READ_CONFLICTID'
        EXPORTING
          conflictid                   = mcuser-conid
          i_vrsio                      = sodvrsio
        IMPORTING
          wa_conflict                  = lt_conflicts
        EXCEPTIONS
          source_conflict_doesnt_exist = 1
          not_authorized_to_display    = 2
          OTHERS                       = 3.
      IF sy-subrc NE 0.
        CLEAR lt_conflicts.
      ENDIF.

    ELSE.
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
      CALL FUNCTION '/PSYNG/SW_CR_READ_CONFLICTID'
        DESTINATION i_rfcdest-rfcdest
        EXPORTING
          conflictid                   = mcuser-conid
          i_vrsio                      = sodvrsio
        IMPORTING
          wa_conflict                  = lt_conflicts
        EXCEPTIONS
          system_failure        = 1
          communication_failure = 2
          source_conflict_doesnt_exist = 3
          not_authorized_to_display    = 4
          OTHERS                       = 5.      "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      IF sy-subrc NE 0.
        CLEAR lt_conflicts.
      ENDIF.

    ENDIF.


    mcuser-condesc = lt_conflicts-description.

    mcuser-type = 'S'.

    IF it_assignment-type = '1'.
      mcuser-asg_usr   = 'X'.
      g_userassign = g_userassign + 1.
    ELSEIF it_assignment-type = 2.
      mcuser-asg_grp   = 'X'.
      g_groupassign = g_groupassign + 1.
    ELSE.
      mcuser-asg_rol   = 'X'.
      g_roleassign = g_roleassign + 1.
    ENDIF.

*--Icon for type
    mcuser-assn_type = it_assignment-type .
    CLEAR : mcuser-agr_name, mcuser-assn_class.
    CASE it_assignment-type .
      WHEN '1'.
        mcuser-mit_icon = '@EK@'.
      WHEN '2'.
        mcuser-mit_icon = '@ID@'.
        mcuser-assn_class = it_assignment-class.
      WHEN '4'.
        mcuser-mit_icon = '@F8@'.
        mcuser-agr_name = it_assignment-agr_name.
    ENDCASE.

    mcuser-userid    = it_assignment-userid.
    mcuser-auditor   = it_assignment-auditor.
    mcuser-vrsio     = it_assignment-vrsio.
    mcuser-from_date = it_assignment-from_date.
    mcuser-to_date   = it_assignment-to_date.
    mcuser-org_abb   = it_assignment-org_abb.
* -- Fill User details
    READ TABLE lt1_uinfo WITH KEY bname   = it_assignment-userid.
    IF sy-subrc = 0.
*--Add record with user details
      mcuser-class       = lt1_uinfo-class.
      mcuser-name_text   = lt1_uinfo-name_text.
      mcuser-compshort   = lt1_uinfo-company.
      mcuser-department  = lt1_uinfo-department.
      mcuser-central_uid = lt1_uinfo-central_uid.
    ELSE.
*--User not found on this system, search global user table.
*  possibly due to user master prioritization
      READ TABLE gt_uinfo WITH KEY bname = it_assignment-userid.
      IF sy-subrc = 0.
        mcuser-class       = gt_uinfo-class.
        mcuser-name_text   = gt_uinfo-name_text.
        mcuser-compshort   = gt_uinfo-company.
        mcuser-department  = gt_uinfo-department.
        mcuser-central_uid = gt_uinfo-central_uid.
      ENDIF.
    ENDIF.
    PERFORM get_comp_name
                CHANGING
                   mcuser-compshort
                   mcuser-company.

*--Fill Auditor details
    IF NOT mcuser-auditor IS INITIAL.
      PERFORM get_user_comp USING    mcuser-auditor
                                     i_rfcdest
                                     'X'
                            CHANGING mcuser-audcompany
                                     ls_user.
      mcuser-auditor_name_text  = ls_user-name_text.


*    mcuser-approved  = it_assignment-approved.
      CLEAR ls_user.
      APPEND mcuser.
    ELSE.
*--Dhorions 2013/05/23 : All users are selected.
* The Valid and Dialog users flag is only relevant for
* the SOD and CA scan
*    if validusr is initial.
*--Add record without user details
      CLEAR ls_user.
      APPEND mcuser.
    ENDIF.
  ENDLOOP.



ENDFORM.                    " convert_to_output
*&---------------------------------------------------------------------*
*&      Form  get_comp_name
*&---------------------------------------------------------------------*
*       Get user's company name from company ID
*----------------------------------------------------------------------*
*      <->I_COMPANY    Company ID
*      <--E_COMP_NAME  Company Name
*----------------------------------------------------------------------*
FORM get_comp_name CHANGING i_company    "TYPE    char20
                            e_comp_name ."TYPE  char20.

  TYPES: BEGIN OF t_comp,
           comp TYPE /psyng/mcauditor-company,
           name TYPE /psyng/mcauditor-company,
         END OF t_comp.

  DATA: l_value  TYPE /psyng/swconfig-value,
        l_fmname TYPE rs38l_fnam,
        ls_comp  TYPE t_comp.

  STATICS: lt_comp             TYPE HASHED TABLE OF t_comp
                               WITH UNIQUE KEY comp,
           l_fm_checked        TYPE flag,
           lf_company_longtext TYPE flag.

  CHECK l_fm_checked IS INITIAL OR lf_company_longtext = 'X'.
  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
  se_config_param 'SW_MGMT_COMP_NAME_FM' swconfig-value.
  IF NOT swconfig-value IS INITIAL.
*   l_fmname = l_value.
    l_fmname = swconfig-value.
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
                'Cannot determine SW_MGMT_COMP_NAME_FM with FM '(200)
                l_fmname '. FM doesn''t exist'(201).
      ELSE.
        lf_company_longtext = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR lf_company_longtext.
    EXIT.
  ENDIF.
  IF NOT l_fmname IS INITIAL.
    CALL FUNCTION l_fmname                   "#EC PATHLOCK_CI_DYN_ACCES
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
*&      Form  check_for_obsolete_mitigations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM check_for_mitigations.
*
*
**--Try to reduce the nr of analysis by finding users for which the same
**  conflicts are mitigated.
*  DATA : lt_mcuser LIKE TABLE OF mcuser WITH HEADER LINE,
*         BEGIN OF lt_user OCCURS 0,
*           userid    TYPE xubname,
*           conflicts TYPE string,
*         END OF lt_user,
*         lt_user_unique     LIKE TABLE OF lt_user WITH HEADER LINE,
*         lta_users          LIKE TABLE OF lt_user WITH HEADER LINE,
*         lt_usr             TYPE TABLE OF /psyng/sw_sel_opts_xubname
*                      WITH HEADER LINE,
*         lt_conids          TYPE TABLE OF /psyng/sw_sel_opts_conid
*                      WITH HEADER LINE,
*         lt_results_part    TYPE TABLE OF /psyng/sw_sod_output_org,
*         lt_results_all     TYPE TABLE OF /psyng/sw_sod_output_org,
*         lt_cons            TYPE TABLE OF /psyng/conflict_id
*                            WITH HEADER LINE,
*         l_cnt              TYPE i,
*         lt_auds            TYPE TABLE OF /psyng/range_swaudid
*                            WITH HEADER LINE,
*         lt_mccauser        TYPE TABLE OF /psyng/mitigation_assignment,
*         lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
*         lt_ca_mcuser       LIKE TABLE OF mcuser WITH HEADER LINE,
*         l_rfcdest          TYPE rfcdest,
*         lt_ca_users        TYPE TABLE OF /psyng/sw_sel_opts_xubname
*         WITH HEADER LINE,
*         lt_uinfo           TYPE TABLE OF /psyng/sw_uinfo_remote
*                            WITH HEADER LINE,
*         lt_uinfo_n         TYPE TABLE OF /psyng/sw_uinfo
*         WITH HEADER LINE,
*         l_tabix            TYPE sy-tabix,
*         lf_reject          TYPE flag,
*         lt_output          TYPE TABLE OF /psyng/output
*         WITH HEADER LINE,
*         lt_ca_fm           TYPE TABLE OF /psyng/sw_ca_output_org
*                            WITH HEADER LINE,
*         lt_ca_all          TYPE TABLE OF /psyng/output
*         WITH HEADER LINE.
*
*  FIELD-SYMBOLS : <user>   LIKE lt_user,
*                  <mcuser> LIKE LINE OF mcuser,
*                  <out>    LIKE /psyng/output.
*  lt_mcuser[] = mcuser[].
*  lt_ca_mcuser[] =  mcuser[].
*  SORT lt_mcuser BY userid conid.
*  DELETE ADJACENT DUPLICATES FROM lt_mcuser COMPARING userid conid.
*  LOOP AT lt_mcuser WHERE from_date LE sy-datum
*                      AND to_date GE sy-datum.
*    lt_user-userid = lt_mcuser-userid.
*    COLLECT lt_user.
*
*    lt_uinfo_n-bname = lt_mcuser-userid.
*    APPEND lt_uinfo_n.
*  ENDLOOP.
*  IF sodcon = 'X'.
*    LOOP AT lt_user ASSIGNING <user> .
*      LOOP AT lt_mcuser WHERE userid = <user>-userid.
*        CONCATENATE <user>-conflicts lt_mcuser-conid
*        INTO <user>-conflicts
*        SEPARATED BY space.
*      ENDLOOP.
*    ENDLOOP.
*    SORT lt_user BY conflicts.
*    lt_user_unique[] = lt_user[].
*    DELETE ADJACENT DUPLICATES FROM lt_user_unique COMPARING conflicts.
*    LOOP AT  lt_user_unique.
**--Collect users
*      REFRESH lt_usr.
*      lt_usr-sign    = 'I'.
*      lt_usr-option  = 'EQ'.
*      LOOP AT lt_user WHERE conflicts = lt_user_unique-conflicts.
*        lt_usr-low = lt_user-userid.
*        APPEND lt_usr.
*      ENDLOOP.
**--Collect conflicts
*      REFRESH lt_conids.
*      lt_conids-sign   = 'I'.
*      lt_conids-option = 'EQ'.
*      SPLIT lt_user_unique-conflicts AT  ' ' INTO TABLE lt_cons.
*      LOOP AT lt_cons.
*        lt_conids-low    = lt_cons.
*        APPEND lt_conids.
*      ENDLOOP.
*
*      SORT lt_uinfo_n BY bname.
*      DELETE ADJACENT DUPLICATES FROM lt_uinfo COMPARING bname.
*
*      CALL FUNCTION '/PSYNG/SW_USER_INFO'
*        EXPORTING
*          i_name_only  = 'X'
*          i_mr_company = 'X'
*        TABLES
*          sw_uinfo     = lt_uinfo_n.
*
*
*      LOOP AT lt_uinfo_n.
*        MOVE-CORRESPONDING lt_uinfo_n TO lt_uinfo.
*        PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
*                             CHANGING lf_reject.
*        IF lf_reject = 'X'.
*          gt_rpoug_auth_fail-bname   = lt_uinfo_n-bname.
*          gt_rpoug_auth_fail-class   = lt_uinfo_n-class.
*          gt_rpoug_auth_fail-company = lt_uinfo_n-company.
*          APPEND gt_rpoug_auth_fail.
*          DELETE lt_usr WHERE low = lt_uinfo_n-bname .
*          gf_missing_auth_ugroup = 'X'.
*          CLEAR gt_rpoug_auth_fail.
*        ENDIF.
*      ENDLOOP.
*
**--Execute SOD analysis.
*      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
*        EXPORTING
*          i_org_check        = orgchk
*          i_validuser        = validusr
*          i_exlckusr         = exlckusr
*          i_outvdate         = outvdate
*          i_vrsio            = sodvrsio
*          i_shomit           = 'X'
*          i_enh              = p_enhanc
*          i_analyze_sap_all  = 'X'
*          i_remote_only      = p_remonl
*          i_er_roles         = erroles
*          i_exclude_er_roles = excl_er
*          i_nonabap          = p_nabap
*          i_abap             = p_abap
*        TABLES
*          it_users           = lt_usr
*          et_outputdet       = lt_results_part
*          it_user_rfc        = xusrrfc
*          it_appl            = s_appl
*          it_sysid           = s_system.
*      APPEND LINES OF lt_results_part TO lt_results_all.
*      REFRESH   lt_results_part[].
*    ENDLOOP.
*
**--Filter Conflict origin
*    IF p_local <> 'X'.
*      DELETE lt_results_all WHERE origin = 1.
*    ENDIF.
*    IF p_remote <> 'X'.
*      DELETE lt_results_all WHERE origin = 2.
*    ENDIF.
*    IF p_cross <> 'X'.
*      DELETE lt_results_all WHERE origin = 3.
*    ENDIF.
*
**--Mark obsolete mitigations
*    SORT lt_results_all BY bname conid.
**--Check all Active mitigations to see if they are obsolete
**  (User no longer has conflict)
*    LOOP AT mcuser ASSIGNING <mcuser>
*    WHERE from_date LE sy-datum AND to_date GE sy-datum.
*      l_tabix = sy-tabix.
*
*      READ TABLE gt_rpoug_auth_fail WITH KEY bname = mcuser-userid.
*      CHECK sy-subrc NE 0.
*      CHECK NOT <mcuser>-type = 'C'.
*      READ TABLE lt_results_all WITH KEY
*        bname = <mcuser>-userid
*        conid = <mcuser>-conid
*        BINARY SEARCH
*        TRANSPORTING NO FIELDS.
*      IF sy-subrc <> 0.
*        <mcuser>-obsolete = 'X'.
*        ADD 1 TO l_cnt.
*        MODIFY mcuser FROM <mcuser> INDEX l_tabix.
*      ENDIF.
*    ENDLOOP.
*    MESSAGE s113 WITH l_cnt 'User Mitigations found'(031).
*  ENDIF.
*
*****  CA's obsolete mitigations
*  IF criaut = 'X'.
*    REFRESH lt_uinfo_n.
*    CLEAR l_tabix.
*    lt_ca_users-sign   = 'I'.
*    lt_ca_users-option = 'EQ'.
*
*    lt_auds-sign = 'I'.
*    lt_auds-option = 'EQ'.
*
*    CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*
**--Add Local system to gt_rfcdest.
*    READ TABLE gt_rfcdest WITH KEY rfcoptions = l_rfcdest.
*    IF sy-subrc <> 0.
*      gt_rfcdest-rfcoptions = l_rfcdest.
*      gt_rfcdest-rfcdest = l_rfcdest.
*      APPEND gt_rfcdest.
*    ENDIF.
*
*    LOOP AT gt_rfcdest.
*
*      REFRESH : lt_ca_users, lt_auds.
*      LOOP AT lt_ca_mcuser WHERE type    = 'C' AND
*                                 rfcdest = gt_rfcdest-rfcoptions.
*        lt_ca_users-low = lt_ca_mcuser-userid.
*        lt_auds-low = lt_ca_mcuser-conid.
*        APPEND lt_auds.
*        APPEND lt_ca_users.
*
*        lt_uinfo_n-bname = lt_mcuser-userid.
*        APPEND lt_uinfo_n.
*      ENDLOOP.
*
*      SORT lt_ca_users.
*      DELETE ADJACENT DUPLICATES FROM lt_ca_users
*      COMPARING ALL FIELDS.
*
*      SORT lt_uinfo_n BY bname.
*      DELETE ADJACENT DUPLICATES FROM lt_uinfo_n COMPARING bname.
*
*      CALL FUNCTION '/PSYNG/SW_USER_INFO'
*        EXPORTING
*          i_name_only  = 'X'
*          i_mr_company = 'X'
*        TABLES
*          sw_uinfo     = lt_uinfo_n.
*
*      LOOP AT lt_uinfo_n.
*        MOVE-CORRESPONDING lt_uinfo_n TO lt_uinfo.
*        PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
*                             CHANGING lf_reject.
*        IF lf_reject = 'X'.
*          gt_rpoug_auth_fail-bname   = lt_uinfo_n-bname.
*          gt_rpoug_auth_fail-class   = lt_uinfo_n-class.
*          gt_rpoug_auth_fail-company = lt_uinfo_n-company.
*          APPEND gt_rpoug_auth_fail.
*          DELETE lt_ca_users WHERE low = lt_uinfo_n-bname .
*          gf_missing_auth_ugroup = 'X'.
*          CLEAR gt_rpoug_auth_fail.
*        ENDIF.
*      ENDLOOP.
*
*
*      SORT lt_auds.
*      DELETE ADJACENT DUPLICATES FROM lt_auds COMPARING ALL FIELDS.
**--Check if any users were found
*      CHECK NOT lt_ca_users[] IS INITIAL.
*
*      IF gt_rfcdest-rfcoptions = l_rfcdest.
*        CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
*          EXPORTING
*            i_validuser  = validusr
*            i_vrsio      = sodvrsio
*            i_shomit     = 'X'
**           E_CACOUNT    =
*          TABLES
*            it_users     = lt_ca_users
*            it_ca        = lt_auds
*            et_outputdet = lt_ca_fm.
*        LOOP AT lt_ca_fm.
*          MOVE-CORRESPONDING lt_ca_fm TO lt_output.
*          APPEND lt_output.
*        ENDLOOP.
*        FREE : lt_ca_fm.
*      ELSE.
*
*        CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
*          DESTINATION gt_rfcdest-rfcdest
*          EXPORTING
*            i_validuser           = validusr
*            i_vrsio               = sodvrsio
*            i_shomit              = 'X'
*          TABLES
*            it_users              = lt_ca_users
*            it_ca                 = lt_auds
*            et_outputdet          = lt_ca_fm
*          EXCEPTIONS
*            communication_failure = 1 MESSAGE g_system_msg
*            system_failure        = 2 MESSAGE g_system_msg
*            OTHERS                = 3.
*
*
*
*        IF sy-subrc <> 0.
*          CASE sy-subrc.
*            WHEN 1 OR 2.
*              MESSAGE e398(00) WITH
*              text-e03
*             gt_rfcdest-rfcdest
*             g_system_msg.
*            WHEN 3.
*              MESSAGE e398(00) WITH
*              text-e03
*              gt_rfcdest-rfcdest.
*          ENDCASE.
*          COMMIT WORK.
*        ENDIF.
*        LOOP AT lt_ca_fm.
*          MOVE-CORRESPONDING lt_ca_fm TO lt_output.
*          APPEND lt_output.
*        ENDLOOP.
*        FREE : lt_ca_fm.
*
*        .
*
*      ENDIF.
**DHORIONS 20130527 : CA is specific for one system
*      LOOP AT lt_output ASSIGNING <out>.
*        <out>-rfcdest = gt_rfcdest-rfcoptions.
*      ENDLOOP.
*      APPEND LINES OF lt_output TO lt_ca_all.
*      REFRESH : lt_output.
*    ENDLOOP.
*
**--Check all Active Critical Authorizations to see
** if they are obsolete
**  (User no longer has CA)
**--Case 3028 : sort table for binary search
*    SORT lt_ca_all BY  bname swaudid rfcdest.
*    LOOP AT mcuser ASSIGNING <mcuser>
*     WHERE from_date LE sy-datum AND to_date GE sy-datum.
*      l_tabix = sy-tabix.
*      READ TABLE gt_rpoug_auth_fail WITH KEY bname = mcuser-userid.
*      CHECK sy-subrc NE 0.
*      CHECK NOT <mcuser>-type = 'S'.
*      READ TABLE lt_ca_all WITH KEY
*      bname   = <mcuser>-userid
*      swaudid = <mcuser>-conid
**DHORIONS 20130527 : CA is specific for one system
*      rfcdest = <mcuser>-rfcdest
*      BINARY SEARCH
*      TRANSPORTING NO FIELDS.
*      IF sy-subrc <> 0.
*        <mcuser>-obsolete = 'X'.
*        ADD 1 TO l_cnt.
*        MODIFY mcuser FROM <mcuser> INDEX l_tabix.
*      ENDIF.
*
*    ENDLOOP.
*
*    MESSAGE s113 WITH l_cnt 'User Mitigations found'(031).
*  ENDIF.
**--Unmark all requests pending in SP as being Obsolete
*  PERFORM ignore_sp_pending_requests.
*
*
*ENDFORM.                    " check_for_obsolete_mitigations
*&---------------------------------------------------------------------*
*&      Form  expire_all_mit
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM expire_all_marked_mit.
  DATA : l_ug             TYPE i,
         l_rol            TYPE i,
         l_lines_tot(100) TYPE n,
         l_lines_sub(100) TYPE n,
         l_auth_failed    TYPE flag,
         l_nr_auth_failed TYPE i,
         lc               TYPE string,
         l_sucess         TYPE i,
         l_success_ug     TYPE i,
         l_success_role   TYPE i,
         l_flag           TYPE flag,
         l_mark_value     TYPE flag,
         lv_answer(1)     TYPE c,
         lv_tabix(10)     TYPE n,
         lv_question      TYPE string,
         l_cnt_usr(100)   TYPE n,
         l_sel_usr(100)   TYPE n,
         l_cnt_grp(100)   TYPE n,
         l_sel_grp(100)   TYPE n,
         l_cnt_rol(100)   TYPE n,
         l_sel_rol(100)   TYPE n,
         lf_alrdy_expired TYPE flag.

  LOOP AT mcuser .
    CASE 'X'.
      WHEN  mcuser-asg_usr.
        ADD 1 TO l_cnt_usr.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_usr.
        ENDIF.
      WHEN mcuser-asg_grp.
        ADD 1 TO l_cnt_grp.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_grp.
        ENDIF.
      WHEN mcuser-asg_rol.
        ADD 1 TO l_cnt_rol.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_rol.
        ENDIF.
    ENDCASE.
  ENDLOOP.

* Determine if the user really wants to do Expire these MC.
  IF sy-batch EQ abap_false.
    CLEAR: lv_tabix, sy-tabix.
    READ TABLE mcuser WITH KEY mark = abap_true.
    IF sy-subrc NE 0.  "Any row selected?
      l_mark_value = abap_true. "LOOP will fail.
    ELSE.
*--count the rows by type
*      l_lines_tot = sy-tfill. "current lines in MCUSER.
*      clear l_lines_tot.
*      LOOP AT mcuser TRANSPORTING NO FIELDS WHERE
*                                           to_date NE sy-datum
*                                           AND asg_usr = 'X'.
*        if mcuser-mark = 'X'.
*          ADD 1 TO l_lines_sub. "sub-total lines.
*        endif.
*        add 1 to l_lines_tot.
*      ENDLOOP.
      SHIFT l_cnt_usr LEFT DELETING LEADING '0'.
      SHIFT l_sel_usr LEFT DELETING LEADING '0'.
      SHIFT l_cnt_grp LEFT DELETING LEADING '0'.
      SHIFT l_sel_grp LEFT DELETING LEADING '0'.
      SHIFT l_cnt_rol LEFT DELETING LEADING '0'.
      SHIFT l_sel_rol LEFT DELETING LEADING '0'.
      .

*      SHIFT l_lines_tot LEFT DELETING LEADING '0'.
*      SHIFT l_lines_sub LEFT DELETING LEADING '0'.

*--Any mitigation is already expired or not
*--Arpan C0705: STARTS B17141
      LOOP AT mcuser WHERE mark = 'X' AND to_date LT sy-datum.
        MESSAGE i113 WITH
        'Mitigation already expired'(219).
        lf_alrdy_expired = 'X'.
        CLEAR: l_sel_usr, l_sel_grp, l_sel_rol.
        EXIT.
      ENDLOOP.
*--Arpan C0705: ENDS B17141

      IF l_sel_usr > 0.

*--Arpan C0705: STARTS B17144
        MESSAGE s113 WITH 'Expiring User Mitigation Assignments'(m03).
*--Arpan C0705: ENDS B17144

        CONCATENATE 'Expire'(202) l_sel_usr 'of'(203) l_cnt_usr
       'user mitigation(s)?'(204) INTO lv_question SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar = 'Warning Message'(205)
            text_question         = lv_question
            text_button_1         = 'Yes'
            text_button_2         = 'No'
            default_button        = '2'
            display_cancel_button = space
          IMPORTING
            answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
        CASE lv_answer.
          WHEN '1'.  "Yes
            l_mark_value = abap_true. "Only selected records.
          WHEN '2'.  "No
            CLEAR l_sel_usr.
*            RETURN. "to the ALV grid.
        ENDCASE.
      ELSE.
        CLEAR l_mark_value.
      ENDIF.
    ENDIF.
  ELSE.
    l_mark_value = 'X'. "Selection not possible.
  ENDIF.

*BOC AKUMAR PN12569
  DATA : lt_expire_group TYPE TABLE OF /psyng/sw_mcusrgrp
        WITH HEADER LINE,
         lt_expire_role  TYPE TABLE OF /psyng/sw_mcrole
         WITH HEADER LINE,
         lt_expire_ca_role TYPE TABLE OF /psyng/sw_mccarole
         WITH HEADER LINE.
*EOC AKUMAR PN12569

* Perform the expiration of the selected user mitigations.
*Commented below code for CO705 B17144
*  IF l_mark_value = 'X' AND l_sel_usr > 0.
*    MESSAGE s113 WITH
*'Expiring User Mitigation Assignments'(m03).
*
*  ENDIF.
  LOOP AT mcuser WHERE mark = 'X' AND to_date GE sy-datum.
    g_action_idx = sy-tabix.
    "Assignments that end today (to_date = sy-datum) will
    "not be expired because that would have no effect
    IF mcuser-asg_usr = 'X'. "Mitigation type USER
      IF l_mark_value = 'X'. "users agreed to expire user assignments
        PERFORM expire_mitigation
                    USING
                       mcuser
                    CHANGING
                       l_auth_failed
                       l_flag.
        IF l_flag = 'X'.
***  Do nothing.
        ENDIF.

        IF l_auth_failed = 'X'.
          ADD 1 TO l_nr_auth_failed .
        ELSE.
          IF l_flag <> 'X'.
            ADD 1 TO l_sucess.
          ENDIF.
        ENDIF.
      ENDIF.

    ELSEIF mcuser-asg_grp = 'X'.
*--SOD
      lt_expire_group-contid     = mcuser-contid.
      lt_expire_group-conid      = mcuser-conid.
      lt_expire_group-class      = mcuser-assn_class.
      lt_expire_group-vrsio      = mcuser-vrsio.
      lt_expire_group-auditor    = mcuser-auditor.
      lt_expire_group-from_date  = mcuser-from_date.
      lt_expire_group-to_date    = mcuser-to_date.
      lt_expire_group-rfcdest    = mcuser-rfcdest. "AKUMAR PN12569
      COLLECT lt_expire_group."there could be multiple uses affected
      "by just one assignment.
      ADD 1 TO l_ug.
    ELSE.
      IF mcuser-type = 'S'."SOD Conflict
        lt_expire_role-contid     = mcuser-contid.
        lt_expire_role-conid      = mcuser-conid.
        lt_expire_role-agr_name   = mcuser-agr_name.
        lt_expire_role-vrsio      = mcuser-vrsio.
        lt_expire_role-auditor    = mcuser-auditor.
        lt_expire_role-from_date  = mcuser-from_date.
        lt_expire_role-to_date    = mcuser-to_date.
        lt_expire_role-rfcdest    = mcuser-rfcdest. "AKUMAR PN12569
        COLLECT lt_expire_role."there could be multiple uses affected
        "by just one assignment.
      ELSE.
*--Critical Auth
        lt_expire_ca_role-contid    = mcuser-contid.
        lt_expire_ca_role-swaudid   = mcuser-conid.
        lt_expire_ca_role-agr_name  = mcuser-agr_name.
        lt_expire_ca_role-vrsio     = mcuser-vrsio.
        lt_expire_ca_role-auditor   = mcuser-auditor.
        lt_expire_ca_role-from_date = mcuser-from_date.
        lt_expire_ca_role-to_date   = mcuser-to_date.
        lt_expire_ca_role-rfcdest   = mcuser-rfcdest. "AKUMAR PN12569
        COLLECT lt_expire_ca_role."could be multiple uses affected
        "by just one assignment.
      ENDIF.

      ADD 1 TO l_rol.
    ENDIF.
  ENDLOOP.

  IF lf_alrdy_expired IS INITIAL.
    IF sy-subrc = 0.
      PERFORM refresh_output.
      READ TABLE mcuser INDEX g_action_idx.
    ELSE.
      IF no_disp IS INITIAL.
        MESSAGE i113 WITH
        'Please select at least one user mitigation.'(028).
      ENDIF.
    ENDIF.
  ENDIF.

  IF l_sel_grp > 0.
    MESSAGE s113 WITH 'Expiring Usergroup Mitigation Assignments'(m02).
    lc = l_ug.
    IF sy-batch EQ abap_false.
      CLEAR l_mark_value.
      CONCATENATE 'Expire'(202) l_sel_grp 'of'(203) l_cnt_grp
      'user group mitigation(s)?'(042) INTO lv_question
      SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar    = 'This action may affect multiple users'(048)
          text_question         = lv_question
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CASE lv_answer.
        WHEN '1'.  "Yes
          l_mark_value = abap_true. "Only selected records.
        WHEN '2'.  "No
          CLEAR l_sel_grp .
*            RETURN. "to the ALV grid.
      ENDCASE.
    ELSE.
      l_mark_value = 'X'.
    ENDIF.
    IF l_mark_value = 'X'.
*--User Group Assignments
      LOOP AT lt_expire_group.
        PERFORM expire_sod_ug_mit USING
                      lt_expire_group
                   CHANGING
                      l_auth_failed
                      l_flag.
        IF l_auth_failed = 'X'.
          ADD 1 TO l_nr_auth_failed .
        ENDIF.
        IF l_flag = 'X'.
          ADD 1 TO l_success_ug.
        ENDIF.
      ENDLOOP.
      PERFORM refresh_output. "C0705 B17181 ARPAN 09.02.2023
    ENDIF.

*    MESSAGE i113 WITH
*    lc
*    'Mitigation(s) assignments  cannot be expired,'(019)
*    'because assigned through User Group.'(016).

  ENDIF.
  IF l_sel_rol > 0.
    MESSAGE s113 WITH 'Expiring Role Mitigation Assignments'(m01).
    lc = l_rol.
    CLEAR l_mark_value.
    IF sy-batch EQ abap_false.
      CONCATENATE 'Expire'(202) l_sel_rol 'of'(203) l_cnt_rol
      'role mitigation(s)?'(043) INTO lv_question SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar    = 'This action may affect multiple users'(048)
          text_question         = lv_question
          text_button_1         = 'Yes'
          text_button_2         = 'No'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.
      CASE lv_answer.
        WHEN '1'.  "Yes
          l_mark_value = abap_true. "Only selected records.
        WHEN '2'.  "No
*           RETURN. "to the ALV grid.
          CLEAR l_sel_rol.
      ENDCASE.
    ELSE.
      l_mark_value = abap_true.
    ENDIF.
    IF l_mark_value = 'X'.
*--Role Assignments for SOD
      LOOP AT lt_expire_role.
        PERFORM expire_sod_role_mit USING
                      lt_expire_role
                   CHANGING
                      l_auth_failed
                      l_flag.
        IF l_auth_failed = 'X'.
          ADD 1 TO l_nr_auth_failed .
        ENDIF.
        IF l_flag = 'X'.
          ADD 1 TO l_success_role.
        ENDIF.
      ENDLOOP.
      LOOP AT lt_expire_ca_role.
        PERFORM expire_ca_role_mit USING
                      lt_expire_ca_role
                   CHANGING
                      l_auth_failed
                      l_flag.
        IF l_auth_failed = 'X'.
          ADD 1 TO l_nr_auth_failed .
        ENDIF.
        IF l_flag = 'X'.
          ADD 1 TO l_success_role.
        ENDIF.
      ENDLOOP.
      PERFORM refresh_output. "C0705 B17181 ARPAN 09.02.2023
    ENDIF.

  ENDIF.


  IF l_nr_auth_failed > 0.
    lc = l_nr_auth_failed.
    IF sy-batch EQ abap_false.
      MESSAGE i113 WITH
     lc
     'Mitigation assignments are not expired due to'(017)
     ' insufficient authorization'(018).
    ELSE.
      MESSAGE s113 WITH
    lc
    'Mitigation assignments are not expired due to'(017)
    ' insufficient authorization'(018).
    ENDIF.
  ENDIF.
  lc = l_sucess.
  IF sy-batch EQ abap_false.
    IF l_sucess > 0.
      MESSAGE i113 WITH lc 'User mitigations expired'(020).
    ENDIF.
    IF l_success_ug > 0.
      MESSAGE i113 WITH l_success_ug
      'User Group mitigations expired'(044).
    ENDIF.
    IF l_success_role > 0.
      MESSAGE i113 WITH l_success_role
      'Role mitigations expired'(045).
    ENDIF.
  ELSE.

    MESSAGE s113 WITH l_sucess 'User mitigations expired'(020).
    MESSAGE s113 WITH l_success_ug
    'User Group mitigations expired'(044).
    MESSAGE s113 WITH l_success_role
    'Role mitigations expired'(045).
  ENDIF.


ENDFORM.                    " expire_all_obs_mit
*&---------------------------------------------------------------------*
*&      Form  expire_mitigation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_MCUSER  text
*----------------------------------------------------------------------*
FORM expire_mitigation USING    i_mcuser LIKE mcuser
                       CHANGING e_auth_failed TYPE flag
                                e_flag TYPE flag.

  DATA : ls_mchdr       TYPE /psyng/mchdr,
         ls_assign      TYPE /psyng/mcuser,
         ls_ca_assign   TYPE /psyng/mccauser,
         ls_ca_rl_assgn TYPE /psyng/mccarole,
         lt_mcuser      TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
         lt_mccauser    TYPE TABLE OF /psyng/mccauser WITH HEADER LINE,
         lt_mccarole    TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
         l_local_sys    TYPE string,
         l_comp_short TYPE /psyng/sw_uinfo-company.


  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
*--Check auhthorization
  IF i_mcuser-company IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
    ID 'ACTVT' FIELD '02'
    ID 'Y&SW_VRSIO' FIELD i_mcuser-vrsio
    ID 'Y&SW_CNTID' FIELD i_mcuser-contid
    ID 'Y&SW_CONID' FIELD i_mcuser-conid
    ID 'Y&SW_BNAME' FIELD i_mcuser-userid
    ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ELSE.
    l_comp_short = i_mcuser-compshort.
    AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
    ID 'ACTVT' FIELD '02'
    ID 'Y&SW_VRSIO' FIELD i_mcuser-vrsio
    ID 'Y&SW_CNTID' FIELD i_mcuser-contid
    ID 'Y&SW_CONID' FIELD i_mcuser-conid
    ID 'Y&SW_BNAME' FIELD i_mcuser-userid
    ID 'Y&SW_COMP'  FIELD l_comp_short .
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  ENDIF.
  IF sy-subrc = 0.
    CLEAR e_auth_failed.
  ELSE.
    e_auth_failed = 'X'.
    EXIT.
  ENDIF.

*Read Mitigation
*  SELECT SINGLE * INTO ls_mchdr FROM /psyng/mchdr
*                WHERE contid = i_mcuser-contid.
*
*  SELECT * INTO TABLE lt_mcuser FROM /psyng/mcuser
*         WHERE contid = i_mcuser-contid.
  READ TABLE gt_rfcdest WITH KEY rfcoptions = i_mcuser-rfcdest.
  IF sy-subrc = 0 AND NOT i_mcuser-rfcdest = l_local_sys.
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
    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        contid                      = i_mcuser-contid
        i_vrsio                     = sodvrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mcuser                      = lt_mcuser
        mccauser                    = lt_mccauser
        mccarole                    = lt_mccarole
      EXCEPTIONS
        communication_failure       = 1 MESSAGE g_system_msg
        system_failure              = 2 MESSAGE g_system_msg
        mit_control_id_doesnt_exist = 3
        not_authorized_to_display   = 4
        OTHERS                      = 5.         "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
         gt_rfcdest-rfcdest
         g_system_msg.
        WHEN 3.
          MESSAGE i398(00) WITH
          i_mcuser-contid
          text-e04
          gt_rfcdest-rfcdest.
          e_flag = 'X'.
          EXIT.
        WHEN 4.
          MESSAGE i398(00) WITH
          text-001.
          e_flag = 'X'.
          EXIT.
        WHEN 5.
          MESSAGE e398(00) WITH
            text-e03
           gt_rfcdest-rfcdest
           g_system_msg.

      ENDCASE.
      COMMIT WORK.
    ENDIF.
    .

  ELSE.
    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      EXPORTING
        contid                      = i_mcuser-contid
        i_vrsio                     = sodvrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
*       MCREPID                     =
*       MCTRAN                      =
        mcuser                      = lt_mcuser
        mccauser                    = lt_mccauser
        mccarole                    = lt_mccarole
*       MCAUDITOR                   =
*       MCUGROUP                    =
*       MCROLE                      =
*       TEXTS                       =
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
        OTHERS                      = 3.
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE i398(00) WITH
          i_mcuser-contid
          text-e04
          gt_rfcdest-rfcdest.
          e_flag = 'X'.
          EXIT.
        WHEN 2.
          MESSAGE i398(00) WITH
          text-001.
          e_flag = 'X'.
          EXIT.
      ENDCASE.
    ENDIF.
  ENDIF.

  IF i_mcuser-type = 'S'.
    MOVE-CORRESPONDING i_mcuser TO ls_assign.
*--Set expiration data
    ls_assign-to_date = sy-datum - 1.
    MODIFY lt_mcuser FROM ls_assign TRANSPORTING to_date
                     WHERE contid = ls_assign-contid
                       AND conid  = ls_assign-conid
                       AND userid = ls_assign-userid
                       AND vrsio  = ls_assign-vrsio.
  ELSE.


    MOVE-CORRESPONDING i_mcuser TO ls_ca_assign.
    MOVE-CORRESPONDING i_mcuser TO ls_ca_rl_assgn.
    ls_ca_assign-swaudid = i_mcuser-conid.
    ls_ca_rl_assgn-swaudid = i_mcuser-conid.
**  *--Set expiration data
    ls_ca_assign-to_date = sy-datum - 1.
    MODIFY lt_mccauser FROM ls_ca_assign TRANSPORTING to_date
                    WHERE contid = ls_ca_assign-contid
                      AND swaudid  = ls_ca_assign-swaudid
                      AND userid = ls_ca_assign-userid
                      AND vrsio  = ls_ca_assign-vrsio.

    ls_ca_rl_assgn-to_date = sy-datum - 1.
    MODIFY lt_mccarole FROM ls_ca_rl_assgn TRANSPORTING to_date
                    WHERE contid   = ls_ca_rl_assgn-contid
                      AND swaudid  = ls_ca_rl_assgn-swaudid
                      AND agr_name = ls_ca_rl_assgn-agr_name
                      AND vrsio    = ls_ca_rl_assgn-vrsio.
  ENDIF.


  READ TABLE gt_rfcdest WITH KEY rfcoptions = i_mcuser-rfcdest.
  IF sy-subrc = 0 AND NOT i_mcuser-rfcdest = l_local_sys.
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
    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        is_mchdr             = ls_mchdr
        if_no_email          = 'X'
        if_add_assgn_only    = 'X'
      TABLES
        it_mcuser            = lt_mcuser
        it_mccauser          = lt_mccauser
        it_mccarole          = lt_mccarole
      EXCEPTIONS
        system_failure        = 1
        communication_failure = 2
        target_not_specified = 3
        not_authorized       = 4
        locked               = 5
        OTHERS               = 6.                "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 3.
          MESSAGE e208(00) WITH text-034.
        WHEN 4.
          MESSAGE e208(00) WITH text-035.
        WHEN 5.
          MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
                        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        WHEN OTHERS.
          MESSAGE e208(00) WITH text-036.
      ENDCASE.
    ELSE.
      MESSAGE s007 WITH
        i_mcuser-userid i_mcuser-contid i_mcuser-conid.


    ENDIF.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      EXPORTING
        is_mchdr             = ls_mchdr
        if_no_email          = 'X'
        if_add_assgn_only    = 'X'
      TABLES
        it_mcuser            = lt_mcuser
        it_mccauser          = lt_mccauser
        it_mccarole          = lt_mccarole
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
  ENDIF.
  IF sy-subrc = 0.
    mcuser-to_date = sy-datum - 1.
    MODIFY mcuser TRANSPORTING to_date WHERE
    userid  = i_mcuser-userid   AND
                        conid   = i_mcuser-conid    AND
                        contid  = i_mcuser-contid   AND
                        rfcdest = i_mcuser-rfcdest.

*    ENDIF.
    MESSAGE s007 WITH
      i_mcuser-userid i_mcuser-contid i_mcuser-conid.

  ENDIF.

ENDFORM.                    " expire_mitigation
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


  IF p_disply EQ abap_true.
    lt_func-fcode = '&ALL'.
    APPEND lt_func.
    lt_func-fcode = '&SAL'.
    APPEND lt_func.
    lt_func-fcode = 'EXPIRE'.
    APPEND lt_func.
*Arpan 19.12.2022 Delete mitigation START
    lt_func-fcode = 'DELETE'.
    APPEND lt_func.
*Arpan 19.12.2022 Delete mitigation END
  ENDIF.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  lt_func-fcode = '&XINT'.
  APPEND lt_func.
  SET PF-STATUS 'EXPIRE' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*---------------------------------------------------------------------*
*       FORM refresh_output                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM refresh_output.
  CHECK sy-binpt IS INITIAL AND sy-batch IS INITIAL.

  DATA : l_fld TYPE string.
* Refresh the grid with the new data
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.
  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
  ASSIGN  (l_fld) TO <g_grid>.               "#EC PATHLOCK_CI_DYN_ACCES
  CHECK <g_grid> IS ASSIGNED.
  CALL METHOD <g_grid>->refresh_table_display.
ENDFORM.                    " refresh_output

*&--------------------------------------------------------------------*
*&      Form  set_user_master_prio
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_LT_UINFO_SORTED  text
*---------------------------------------------------------------------*
FORM set_user_master_prio
TABLES   et_uinfo STRUCTURE /psyng/sw_uinfo_remote
         it_rfcdes STRUCTURE rfcdes
         it_company STRUCTURE /psyng/range_company
         it_department STRUCTURE /psyng/range_department
         it_usergroup  STRUCTURE /psyng/range_class.

  DATA: ls_swconfig TYPE /psyng/swconfig,
        lt_rfcdes   TYPE TABLE OF rfcdes WITH HEADER LINE,
        l_local     TYPE rfcdest,
        l_prio      TYPE i.

  FIELD-SYMBOLS : <des> TYPE  rfcdes.
  lt_rfcdes[] = it_rfcdes[].
  CONCATENATE sy-sysid sy-mandt INTO l_local.
*--Determine parameter for priority of systems
*user attributes (company, user group) shall be determined in the
*following sequence:
* The sort key for the local system is determined by the config
* parameter SW_LOCAL_SYSTEM_SORT,
*( if it is not available, the default blank value will be used,
* making
*  the local system always having the highest priority)
*For all remote systems, the sort key that will be used is the RFC
* destination name.

*--Get configured sort criteria for local system
  se_config_param 'SW_LOCAL_SYSTEM_SORT' ls_swconfig-value.

  READ TABLE lt_rfcdes
  ASSIGNING <des>
  WITH KEY rfcoptions = l_local.
  IF sy-subrc <> 0.
    lt_rfcdes-rfcoptions = l_local.
    APPEND lt_rfcdes.
    READ TABLE lt_rfcdes
    ASSIGNING <des>
    WITH KEY rfcoptions = l_local.
  ENDIF.
  IF ls_swconfig-value <> '' AND sy-subrc = 0.
    <des>-rfcdest = ls_swconfig-value.
  ELSE.
    CLEAR <des>-rfcdest.
  ENDIF.
  l_prio = 0.
  SORT lt_rfcdes BY rfcdest.
  LOOP AT lt_rfcdes.
    ADD 1 TO l_prio.
    et_uinfo-sodcount = l_prio.
    MODIFY et_uinfo
    TRANSPORTING sodcount
    WHERE
    rfcdest = lt_rfcdes-rfcoptions.
  ENDLOOP.
*--Only keep record with highest priority for each user
  SORT et_uinfo BY bname sodcount.
  DELETE ADJACENT DUPLICATES FROM  et_uinfo COMPARING bname.

  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF sy-subrc = 0 AND ls_swconfig-value = 'Y'.
*--Only consider one company per user,
*     the one with the highest priority
    DELETE et_uinfo WHERE NOT company    IN it_company.
    DELETE et_uinfo WHERE NOT department IN it_department.
    DELETE et_uinfo WHERE NOT class      IN it_usergroup.
  ENDIF.

ENDFORM.                    " set_user_master_prio

*&--------------------------------------------------------------------*
*&      Form  exelog
*&--------------------------------------------------------------------*
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
      exelog = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*--------------------------------------------------------------------*
*       FORM alv_header                                              *
*--------------------------------------------------------------------*
*       ........                                                     *
*--------------------------------------------------------------------*
FORM alv_header.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_count          TYPE i,
        l_exetime(8)     TYPE c,
        l_exedate        TYPE char10,
        c_usercount(6)   TYPE c,
        c_count          TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12)       TYPE c,
        c_userassign(4)  TYPE c,
        c_groupassign(4) TYPE c,
        c_roleassign(4)  TYPE c.

* Header
  wa-typ = 'H'.
  CASE abap_true.
    WHEN p_disply.
      wa-info = 'Report Mitigation - Display Results'(h00).
    WHEN p_expire.
      wa-info = 'Report Mitigation - Expire/Delete'(h01).
*BOC C1159 CGUPTA 10/10/2023
    WHEN p_notify.
      IF sy-batch NE 'X'.
        PERFORM notify_expiring_mit.
*        MESSAGE s398(00) WITH 'Email Sent'.
        LEAVE TO SCREEN 0.
      ENDIF.
*EOC C1159 CGUPTA 10/10/2023
  ENDCASE.
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : ' wa-info INTO wa-info
  SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO l_exedate.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
                INTO l_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user "sy-uname           C0700
  text-h04 l_exedate l_exetime INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

*Summary.
  wa-typ = 'S'.
  wa-key = 'Summary'(h05).

  c_userassign  = g_userassign.
  c_groupassign = g_groupassign.
  c_roleassign  = g_roleassign.

*  CONCATENATE text-h06 c_userassign  text-h07 c_groupassign
*  text-h08 c_roleassign INTO wa-info SEPARATED BY space.
  CONCATENATE 'MC Assigned to Users:'(h06) c_userassign
  INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CLEAR wa-key.
  CONCATENATE 'MC Assigned to User Groups:'(046) c_groupassign
  INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CONCATENATE 'MC Assigned to Roles:'(047) c_roleassign
  INTO wa-info SEPARATED BY space.
  APPEND wa TO header.



  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE w190(/psyng/sw).
  ENDIF.

ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  get_miti_cri_auths
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*---------------------------------------------------------------------*
FORM get_miti_cri_auths.
  DATA :
    lt_contid          TYPE TABLE OF /psyng/sw_sel_opts_contid,
    lt_users           TYPE TABLE OF /psyng/sw_sel_opts_xubname
                       WITH HEADER LINE,
    ls_mcuser          TYPE /psyng/mitigation_assignment,
    lt_auds            TYPE TABLE OF /psyng/range_swaudid
                       WITH HEADER LINE,
    lt_mcuser          TYPE TABLE OF /psyng/mitigation_assignment
                       WITH HEADER LINE,
    lt_mcuser_all      TYPE TABLE OF /psyng/mitigation_assignment,
    lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
    l_local_system     TYPE rfcdes,
    lt_text_t          TYPE TABLE OF /psyng/texts WITH HEADER LINE,
    t_start_date       TYPE sy-datum,
    t_end_date         TYPE sy-datum,
    lt_auditor         TYPE TABLE OF /psyng/sw_sel_opts_auditor,
    lt_uinfo           TYPE TABLE OF /psyng/sw_uinfo_remote WITH
                          HEADER LINE,
    l_usercount        TYPE i,
    lt_user_mapping    TYPE TABLE OF /psyng/sw_user_mapping,
    ls_user            TYPE /psyng/sw_uinfo_remote,
    l_mittype          TYPE /psyng/sw_mctype-type,
    l_text             TYPE /psyng/sw_mctype-text,
    lt_user_range      TYPE TABLE OF /psyng/sw_sel_opts_xubname
                           WITH HEADER LINE,
    lt_user_range_part TYPE TABLE OF /psyng/sw_sel_opts_xubname
                      WITH HEADER LINE,
    lt_mchdr           TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
    la_swaudhdr        TYPE /psyng/swaudhdr.

  RANGES : s_bname FOR sy-uname.
  DATA : lt_1_users TYPE TABLE OF usr02 WITH HEADER LINE.
  DATA : lt1_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA : lf_reject        TYPE flag,
         i_include_locked TYPE flag,
         i_include_expire TYPE flag.

  REFRESH : s_bname, lt_1_users,lt1_uinfo.
***Load critical Authorizations
  IF expcn = 'X'.
    t_start_date = '00000000'.
    t_end_date = '00000000'.
  ELSE.
    t_start_date = sy-datum.
    t_end_date = sy-datum.
  ENDIF.

  lt_contid[] = contid[].
  lt_auds[] = swaudid[].
  lt_auditor[] =  auditor[].

  IF p_remonl NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO l_local_system.
    gt_rfcdest-rfcoptions = l_local_system.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.

  lt_remote_anal_rfc[] = gt_rfcdest[].

  ls_mcuser-vrsio = sodvrsio.

*-- Analyze system wise
  LOOP AT lt_remote_anal_rfc.
    REFRESH lt_users[].
    REFRESH lt_mcuser[].
    REFRESH lt_mchdr[].

    lt_users-sign   = lt_auds-sign   = 'I'.
    lt_users-option = lt_auds-option = 'EQ'.
    IF s_class[]  IS INITIAL AND
         s_comp[]   IS INITIAL AND
         s_depart[] IS INITIAL AND
         s_cuid[]   IS INITIAL.
      lt_users[] = userid[].
      IF lt_users[] IS INITIAL.
        lt_users-low = '*'.
        lt_users-option = 'CP'.
        APPEND lt_users.
      ENDIF.
    ELSE.

      IF gt_uinfo[] IS INITIAL.
        PERFORM get_users.
      ENDIF.

      FREE : lt_uinfo[].
      REFRESH : lt_uinfo[].
      lt_uinfo[] = gt_uinfo[].
      LOOP AT lt_uinfo.
        lt_users-low = lt_uinfo-bname.
        APPEND lt_users.
      ENDLOOP.
    ENDIF.


    WHILE NOT lt_users[] IS INITIAL.
      REFRESH lt_user_range_part.

      APPEND LINES OF lt_users[] FROM 1 TO 2500 TO
      lt_user_range_part.
      DELETE lt_users[] FROM 1 TO 2500.

*--Load critcal authorization for users
      IF lt_remote_anal_rfc-rfcoptions = l_local_system.
        CALL FUNCTION '/PSYNG/SW_096'
          EXPORTING
            i_vrsio      = sodvrsio
            i_start_date = t_start_date
            i_end_date   = t_end_date
          TABLES
            it_users     = lt_user_range_part[]
            it_auds      = lt_auds[]
            et_mcusers   = lt_mcuser[]
            it_contid    = lt_contid[]
            it_auditor   = lt_auditor[].

      ELSE.
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
        CALL FUNCTION '/PSYNG/SW_096'
          DESTINATION lt_remote_anal_rfc-rfcdest
          EXPORTING
            i_vrsio               = sodvrsio
            i_start_date          = t_start_date
            i_end_date            = t_end_date
          TABLES
            it_users              = lt_user_range_part[]
            it_auds               = lt_auds[]
            et_mcusers            = lt_mcuser[]
            it_contid             = lt_contid[]
            it_auditor            = lt_auditor[]
          EXCEPTIONS
            communication_failure = 1 MESSAGE g_system_msg
            system_failure        = 2 MESSAGE g_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e03
              lt_remote_anal_rfc-rfcdest
              g_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e03
              lt_remote_anal_rfc-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.

      ENDIF.
      DELETE lt_mcuser WHERE NOT from_date IN valid_fr
                            OR NOT to_date IN valid_to.





      IF lt_remote_anal_rfc-rfcoptions = l_local_system.
        CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'
          EXPORTING
            i_vrsio = sodvrsio
          TABLES
            mchdr   = lt_mchdr.
      ELSE.
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
        CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_MITCNTRLS'
          DESTINATION lt_remote_anal_rfc-rfcdest
          EXPORTING
            i_vrsio               = sodvrsio
          TABLES
            mchdr                 = lt_mchdr
          EXCEPTIONS
            communication_failure = 1 MESSAGE g_system_msg
            system_failure        = 2 MESSAGE g_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e03
              lt_remote_anal_rfc-rfcdest
              g_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e03
              lt_remote_anal_rfc-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.
      ENDIF.

      s_bname-sign = 'I'.
      s_bname-option = 'EQ'.

*-- PS3 Changes Starts
*-- Collect all the users from mitigation assignment
      LOOP AT lt_mcuser.
        s_bname-low = lt_mcuser-userid.
        COLLECT s_bname.
      ENDLOOP.

*--Check for valid users
      IF NOT s_bname[] IS INITIAL.
        IF lt_remote_anal_rfc-rfcoptions = l_local_system.

          CALL FUNCTION '/PSYNG/SW_041'
            EXPORTING
              i_validuser       = validusr
              i_include_locked  = i_include_locked
              i_include_expired = i_include_expire
            TABLES
              et_users          = lt_1_users
              it_userlist       = s_bname
              it_usertype       = usrtype.

        ELSE.
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
          CALL FUNCTION '/PSYNG/SW_041'
            DESTINATION lt_remote_anal_rfc-rfcdest
            EXPORTING
              i_validuser       = validusr
              i_include_locked  = i_include_locked
              i_include_expired = i_include_expire
            TABLES
              et_users          = lt_1_users
              it_userlist       = s_bname
              it_usertype       = usrtype
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
            EXCEPTIONS
              system_failure        = 1
              communication_failure = 2
              OTHERS                = 3.         "#EC SAST_CI_GEN_CHECK
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
        ENDIF.
      ENDIF.

      LOOP AT lt_1_users.
        lt1_uinfo-bname = lt_1_users-bname.
        APPEND lt1_uinfo.
      ENDLOOP.


*-- Check for company and user group
      SORT lt1_uinfo BY bname.
      DELETE ADJACENT DUPLICATES FROM lt1_uinfo COMPARING bname.

      IF NOT lt1_uinfo[] IS INITIAL.
        IF lt_remote_anal_rfc-rfcoptions = l_local_system.
          CALL FUNCTION '/PSYNG/SW_USER_INFO'
            EXPORTING
              i_name_only     = 'X'
              i_mr_company    = 'X'
              i_mr_department = 'X'
              i_central_uid   = 'X'
            TABLES
              sw_uinfo        = lt1_uinfo.

        ELSE.
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
          CALL FUNCTION '/PSYNG/SW_USER_INFO'
            DESTINATION lt_remote_anal_rfc-rfcdest
            EXPORTING
              i_name_only           = 'X'
              i_mr_company          = 'X'
              i_mr_department       = 'X'
              i_central_uid         = 'X'
            TABLES
              sw_uinfo              = lt1_uinfo
            EXCEPTIONS
              communication_failure = 1 MESSAGE g_system_msg
              system_failure        = 2 MESSAGE g_system_msg
              OTHERS                = 3.         "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1 OR 2.
                MESSAGE e398(00) WITH
                text-e03
                lt_remote_anal_rfc-rfcdest
                g_system_msg.
              WHEN 3.
                MESSAGE e398(00) WITH
                text-e03
                lt_remote_anal_rfc-rfcdest.
            ENDCASE.
            COMMIT WORK.
          ENDIF.
        ENDIF.
      ENDIF.

*--authorization checks
      LOOP AT lt1_uinfo.
        CLEAR lf_reject.
        MOVE-CORRESPONDING lt1_uinfo TO gt_uinfo.
        PERFORM check_rpoug_auth USING gt_uinfo sodvrsio
                                 CHANGING lf_reject.
        IF lf_reject = 'X'.
          gt_rpoug_auth_fail-bname   = gt_uinfo-bname.
          gt_rpoug_auth_fail-class   = gt_uinfo-class.
          gt_rpoug_auth_fail-company = gt_uinfo-company.
          APPEND gt_rpoug_auth_fail.
          DELETE lt1_uinfo.
          DELETE lt_1_users WHERE bname = gt_uinfo-bname.
          gf_missing_auth_ugroup = 'X'.
          CLEAR gt_rpoug_auth_fail.
        ELSE.
          MOVE-CORRESPONDING lt1_uinfo TO lt_uinfo.
          APPEND lt_uinfo.
        ENDIF.
      ENDLOOP.

      LOOP AT lt_mcuser.
*-- This table will have all the valid and authorized users.
        READ TABLE lt_1_users WITH KEY bname = lt_mcuser-userid.
        IF sy-subrc NE 0.
          CONTINUE.
        ENDIF.




        CLEAR la_swaudhdr.
        CLEAR gt_mcuser_ca.
        MOVE-CORRESPONDING lt_mcuser TO gt_mcuser_ca.
        gt_mcuser_ca-conid = lt_mcuser-swaudid.
        gt_mcuser_ca-type = 'C'.  "critical authorization
*        gt_mcuser_ca-asg_usr = 'X'.
*      --Icon for type
        gt_mcuser_ca-assn_type = lt_mcuser-type .
        CLEAR : gt_mcuser_ca-agr_name, gt_mcuser_ca-assn_class.
        CASE lt_mcuser-type .
          WHEN '3'.
            gt_mcuser_ca-mit_icon = '@EK@'.
            gt_mcuser_ca-asg_usr  ='X'.
            ADD 1 TO g_userassign.
          WHEN '5'.
            gt_mcuser_ca-mit_icon = '@F8@'.
            gt_mcuser_ca-agr_name = lt_mcuser-agr_name.
            gt_mcuser_ca-asg_rol  ='X'.
            ADD 1 TO g_roleassign.
        ENDCASE.

****  Mitigation ID information
        READ TABLE lt_mchdr WITH KEY contid = lt_mcuser-contid.
        CLEAR :gt_mcuser_ca-contdesc,gt_mcuser_ca-mittype,
               gt_mcuser_ca-mittype_text , l_text  .
        IF sy-subrc = 0.
          gt_mcuser_ca-contdesc = lt_mchdr-description.
          gt_mcuser_ca-mittype = lt_mchdr-type.
          SELECT SINGLE text INTO (l_text)           "#EC CI_SEL_NESTED
                FROM /psyng/sw_mctype
            WHERE type = lt_mchdr-type.          "#EC SAST_CI_GEN_CHECK
          IF sy-subrc = 0.
            gt_mcuser_ca-mittype_text = l_text.
          ELSE.
            gt_mcuser_ca-mittype_text =
            'Not Defined in the system as of now'(206).
          ENDIF.
        ENDIF.

        IF lt_remote_anal_rfc-rfcoptions = l_local_system.
          CALL FUNCTION '/PSYNG/SW_CR_READ_CRI_AUTHS'
            EXPORTING
              swaudid                   = lt_mcuser-swaudid
              i_vrsio                   = sodvrsio
            IMPORTING
              wa_swaudhdr               = la_swaudhdr
            EXCEPTIONS
              authid_doesnt_exist       = 1
              not_authorized_to_display = 2
              OTHERS                    = 3.
          IF sy-subrc <> 0.
            CLEAR la_swaudhdr.
*            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
        ELSE.
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
          CALL FUNCTION '/PSYNG/SW_CR_READ_CRI_AUTHS'
            DESTINATION lt_remote_anal_rfc-rfcdest
            EXPORTING
              swaudid                   = lt_mcuser-swaudid
              i_vrsio                   = sodvrsio
            IMPORTING
              wa_swaudhdr               = la_swaudhdr
            EXCEPTIONS
              system_failure        = 1
              communication_failure = 2
              authid_doesnt_exist       = 3
              not_authorized_to_display = 4
              OTHERS                    = 5.     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
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

        ENDIF.

        gt_mcuser_ca-condesc = la_swaudhdr-description.

*     if there is an auditor defined in the assignment table
        IF  gt_mcuser_ca-auditor IS INITIAL.
*     get the auditors in selection screen auditors
          SELECT contid auditor company              "#EC CI_SEL_NESTED
              INTO (/psyng/mcauditor-contid,
                    /psyng/mcauditor-auditor,
                    /psyng/mcauditor-company)
              FROM /psyng/mcauditor
              WHERE contid = gt_mcuser_ca-contid AND
                    auditor IN auditor.

            gt_mcuser_ca-auditor = /psyng/mcauditor-auditor.
            gt_mcuser_ca-audcompany = /psyng/mcauditor-company.
          ENDSELECT.
        ENDIF.

        PERFORM get_user_comp USING    gt_mcuser_ca-auditor
                                       lt_remote_anal_rfc
*-- This X will treat user as an auditor
                                       'X'
                               CHANGING gt_mcuser_ca-audcompany
                                        ls_user.
        gt_mcuser_ca-auditor_name_text  = ls_user-name_text.






**** User information
        READ TABLE lt_uinfo WITH KEY
                            rfcdest = lt_remote_anal_rfc-rfcoptions
                            bname   = lt_mcuser-userid.
        IF sy-subrc <> 0.
          READ TABLE lt_uinfo WITH KEY bname   = lt_mcuser-userid.
        ENDIF.
        IF sy-subrc = 0.
*--Add with user master data

          gt_mcuser_ca-name_text   = lt_uinfo-name_text.
          gt_mcuser_ca-compshort   = lt_uinfo-company.
          PERFORM get_comp_name
                      CHANGING
                         gt_mcuser_ca-compshort
                         gt_mcuser_ca-company.

          gt_mcuser_ca-department  = lt_uinfo-department.
          gt_mcuser_ca-central_uid = lt_uinfo-central_uid.
          gt_mcuser_ca-class       = lt_uinfo-class.

**** Critical Authorization text
          CLEAR ls_user.
          APPEND gt_mcuser_ca.
        ELSE.
*--Dhorions 2013/05/23 : All users are selected.
* The Valid and Dialog users flag is only relevant for
* the SOD and CA scan
*        if validusr is initial.
*--Add without user master data
          CLEAR ls_user.
          APPEND gt_mcuser_ca.
        ENDIF.
      ENDLOOP.
    ENDWHILE.
  ENDLOOP.
ENDFORM.                    " get_miti_cri_auths
*
*&--------------------------------------------------------------------*
*&      Form  get_users
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*---------------------------------------------------------------------*
FORM get_users.
  DATA : lt_uinfo           TYPE TABLE OF /psyng/sw_uinfo_remote WITH
                           HEADER LINE,
         l_usercount        TYPE i,
         lt_user_mapping    TYPE TABLE OF /psyng/sw_user_mapping,
         lt_user_range      TYPE TABLE OF /psyng/sw_sel_opts_xubname
                            WITH HEADER LINE,
         lt_user_range_part TYPE TABLE OF /psyng/sw_sel_opts_xubname
                           WITH HEADER LINE,

         l_local_sys        TYPE rfcdes,
         l_fromdate         TYPE dats,
         l_todate           TYPE dats,
         lt_assignment_part
           TYPE TABLE OF /psyng/mitigation_assignment
           WITH HEADER LINE,
         l_system_msg(80)   TYPE c
         .

*** Load Users
  PERFORM get_user_info
     TABLES
       userid
       s_class
       s_comp
       s_depart
       s_cuid
       usrtype
       lt_uinfo
       gt_rfcdest
       lt_user_mapping
     USING
*--Dhorions 2013/05/23 : All users are selected.
* The Valid and Dialog users flag is only relevant for
* the SOD and CA scan
*--Dhorions 2013/07/11 : Only valid and dialog users' user master data
*is read. Assignments that are not found will be displayed with
*user id
*only
* Sf Case 3496
*        'X'
        validusr
        exlckusr
        outvdate
        ' '
        ' '
        sodvrsio
        p_remonl
      CHANGING
        l_usercount.
  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

  PERFORM set_user_master_prio
TABLES
  lt_uinfo
  gt_rfcdest
  s_comp
  s_depart
  s_class.

  SORT lt_user_mapping BY  source_bname target_rfc.
  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

  gt_uinfo[] = lt_uinfo[].
  gt_user_mapping[] = lt_user_mapping[].

ENDFORM.                    " get_users

*--------------------------------------------------------------------*
*       FORM f4_department                                           *
*--------------------------------------------------------------------*
*       ........                                                     *
*--------------------------------------------------------------------*
*  -->  E_DEPARTMENT                                                 *
*--------------------------------------------------------------------*
FORM f4_department CHANGING e_department .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam.
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
      'Cannot determine SW_COMPANY_SHLP_FM with FM '(207)
      ls_fmname '. FM doesn''t exist'(208).
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_077'.
  ENDIF.


  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    CHANGING
      e_department = e_department.
ENDFORM.                    " f4_department

*&--------------------------------------------------------------------*
*&      Form  f4_company
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      <--P_S_COMP_LOW  text
*---------------------------------------------------------------------*
FORM f4_company USING    fieldname
                CHANGING e_comp
                .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr..
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
      'Cannot determine SW_COMPANY_SHLP_FM with FM '(209)
      ls_fmname '. FM doesn''t exist'(210).
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro    = l_dynnr
      i_dynpprog  = l_repid
      i_fieldname = fieldname
    CHANGING
      e_company   = e_comp.

ENDFORM.                    " f4_company
*&--------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        tex
*---------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA : alv_layout     TYPE slis_layout_alv,
         alv_grid_titl  TYPE lvc_title,
         i_fieldcat_alv TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: ls_variant TYPE disvariant.

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
  wa_fieldcat_alv-seltext_l = text-h27.
  wa_fieldcat_alv-seltext_m = text-h27.
  wa_fieldcat_alv-seltext_s = text-h27.
  wa_fieldcat_alv-reptext_ddic = text-h27.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h26.
  wa_fieldcat_alv-seltext_m = text-h26.
  wa_fieldcat_alv-seltext_s = text-h26.
  wa_fieldcat_alv-reptext_ddic = text-h26.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm, g_ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title = alv_grid_titl
      is_layout    = alv_layout
      it_fieldcat  = i_fieldcat_alv
      i_save       = 'A'
      is_variant   = ls_variant
    TABLES
      t_outtab     = gt_rpoug_auth_fail
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
*&--------------------------------------------------------------------*
*&      Form  f4_usrtype
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      <--P_USRTYPE_LOW  text
*---------------------------------------------------------------------*
FORM f4_usrtype CHANGING p_usrtype_low.
  DATA: BEGIN OF ls_data,
          value TYPE domvalue_l,
          dtext TYPE val_text,
        END OF ls_data,
        lt_data    LIKE TABLE OF ls_data,
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
  IF sy-subrc EQ 0.
    READ TABLE lth_return INTO wah_return INDEX 1.
    IF sy-subrc = 0.
      p_usrtype_low = wah_return-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.                    " f4_usrtype
*&--------------------------------------------------------------------*
*&      Form  remove_not_needed_usergoups
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        tex
*---------------------------------------------------------------------*
FORM remove_not_needed_usergoups.

  LOOP AT mcuser.
    CHECK NOT mcuser-class IN s_class.
    DELETE mcuser.
  ENDLOOP.
ENDFORM.                    " remove_not_needed_usergoups
*&--------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*---------------------------------------------------------------------*
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
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.
  .

ENDFORM.                    " set_default_sodversion
*&--------------------------------------------------------------------*
*&      Form  ignore_sp_pending_requests
*&--------------------------------------------------------------------*
*       Do not consider user Mitigation assignments that are in
**      pending    requests in SP as being obsolete
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM ignore_sp_pending_requests.
*  CHECK gf_sp_installed = 'X' AND ignsp = 'X'.
*  MESSAGE s002 WITH
*  'Checking User Assignments in Pending SP Requests'(sp1).
*
*  DATA : lt_mcuser    TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
*         lt_pending   TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
*         l_nr_pending TYPE i.
*  FIELD-SYMBOLS : <mcuser> LIKE LINE OF mcuser.
*  LOOP AT mcuser.
*    CHECK mcuser-obsolete   = 'X' AND
*          mcuser-type       = 'S' AND
*          mcuser-asg_usr    <> ''.
*    lt_mcuser-vrsio     = mcuser-vrsio.
*    lt_mcuser-contid    = mcuser-contid.
*    lt_mcuser-conid     = mcuser-conid.
*    lt_mcuser-userid    = mcuser-userid.
*    lt_mcuser-auditor   = mcuser-auditor.
*    lt_mcuser-from_date = mcuser-from_date.
*    lt_mcuser-to_date   = mcuser-to_date.
*    APPEND lt_mcuser.
*  ENDLOOP.
*  CALL FUNCTION '/PSYNG/SW_MC_PENDING_IN_SP'
*    TABLES
*      it_assignments = lt_mcuser
*      et_sp_pending  = lt_pending.
*  DESCRIBE TABLE lt_pending LINES l_nr_pending.
*  MESSAGE s002 WITH
*  'Mitigations in Pending SP requests : '(sp2) l_nr_pending.
*  LOOP AT lt_pending.
*    READ TABLE mcuser
*      ASSIGNING <mcuser>
*      WITH KEY
*      obsolete   = 'X'
*      type       = 'S'
*      userid     = lt_pending-userid
*      vrsio      = lt_pending-vrsio
*      contid     = lt_pending-contid
*      conid      = lt_pending-conid
*      auditor    = lt_pending-auditor
*      from_date  = lt_pending-from_date
*      to_date    = lt_pending-to_date.
*    IF sy-subrc = 0.
*      CLEAR <mcuser>-obsolete.
*    ENDIF.
*  ENDLOOP.
*
*
*ENDFORM.                    " ignore_sp_pending_requests
*&--------------------------------------------------------------------*
*&      Form  USER_COMMAND
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*---------------------------------------------------------------------*
FORM user_command .
  CASE sy-ucomm.
    WHEN 'SCJB'.
      exit_proc = 'Y'.
      PERFORM schedule_background_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
  ENDCASE.
ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  CHECK_JOB_STATUS
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*---------------------------------------------------------------------*
FORM check_job_status .
  DATA:ta_job_txt_msg(77) TYPE c,
       l_repid            TYPE repid.
  l_repid = sy-repid.
  PERFORM get_job_name USING l_repid
                             ta_def_job_txt
                       CHANGING ta_job_txt_msg.

  s_cmt = ta_job_txt_msg.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'CM1'.
        screen-intensified = '1'.
        MODIFY SCREEN.
      WHEN 'BGD'.
        IF gf_job_active EQ 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'OUT'.
        screen-active = 0.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.
ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  SCHEDULE_BACKGROUND_JOB
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*---------------------------------------------------------------------*
FORM schedule_background_job .
  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.
  DATA:lt_vari_desc    TYPE TABLE OF varid WITH HEADER LINE,
       ls_variant      LIKE vari-variant,
       ls_prev_variant LIKE vari-variant,
       ls_report       LIKE rsvar-report,
       l_last_id(7).

  CLEAR: curr_report, curr_variant.

  ls_report = sy-repid.

  PERFORM get_next_variant_id  TABLES  lt_vari_desc
                               CHANGING
                                       ls_variant
                                       l_last_id
                                       ls_report.
  curr_report = sy-repid.
  curr_variant = ls_variant.
  REFRESH : vari_contents[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = curr_report
            if_no_logging = 'X'
       TABLES
            et_params     = vari_contents.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = curr_variant
      vari_desc     = lt_vari_desc
    TABLES
      vari_contents = vari_contents
      vari_text     = vari_text
    EXCEPTIONS
      OTHERS        = 1.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = ta_def_job_txt.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = l_jobname
        in_repvarnt = curr_variant
        in_report   = curr_report
      EXCEPTIONS
        OTHERS      = 1.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ELSE.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  GET_JOB_NAME
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_L_REPID  text
*      -->P_TA_DEF_JOB_TXT  text
*      <--P_TA_JOB_TXT_MSG  text
*---------------------------------------------------------------------*
FORM get_job_name USING    i_progname TYPE tbtcp-progname
                           i_default  TYPE tbtcp-jobname
                  CHANGING e_job_msg .
  DATA:t_icon   TYPE icon-id,
       l_freq_h TYPE tbtco-prdhours,
       l_freq_d TYPE tbtco-prddays.
  CLEAR:gf_job_active.

  SELECT SINGLE o~prdhours o~prddays INTO (l_freq_h,l_freq_d)
           FROM tbtcp AS p
          INNER JOIN tbtco AS o
             ON p~jobname  = o~jobname
            AND p~jobcount = o~jobcount
          WHERE p~progname  = i_progname
            AND o~status    = 'S'
            AND o~authckman = sy-mandt.

  IF sy-subrc EQ 0.
    gf_job_active = 'X'.
    t_icon = '@08@'.
    IF NOT l_freq_h IS INITIAL.
      CONCATENATE t_icon
      'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_h 'hours'(s05)
      INTO e_job_msg SEPARATED BY space.
    ELSEIF NOT l_freq_d IS INITIAL.
      CONCATENATE t_icon
      'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_d 'days'(s06)
      INTO e_job_msg SEPARATED BY space.
    ELSE.
      CONCATENATE '@09@'
'History Capture job is not set up with recommended settings.'(s07)
       INTO e_job_msg SEPARATED BY space.
    ENDIF.

  ELSE.
    t_icon = '@0A@'.
    CONCATENATE t_icon
                'History Capture job is not running.'(w01)
                INTO e_job_msg SEPARATED BY space.
  ENDIF.

ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  GET_NEXT_VARIANT_ID
*&--------------------------------------------------------------------*
*       tex
*---------------------------------------------------------------------*
*      -->P_LT_VARI_DESC  text
*      <--P_LS_VARIANT  text
*      <--P_L_LAST_ID  text
*      <--P_LS_REPORT  text
*---------------------------------------------------------------------*
FORM get_next_variant_id TABLES vari_desc STRUCTURE varid
 CHANGING variant LIKE vari-variant
          last_id
          report.
  DATA: oldnumber(7)   TYPE n,newnumber(7) TYPE n, oldnumber_c(7).
*variant
  WAIT UP TO 1 SECONDS. "wait a second to update the last vaiant
  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

  SELECT variant INTO variant FROM varid WHERE
                      report = report AND
                      variant LIKE '/PSYNG/%' AND NOT
                      variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    newnumber = variant+7(7).
    IF newnumber > oldnumber.
      oldnumber = newnumber.
    ENDIF.
  ENDSELECT.
  last_id = oldnumber.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
  ENDIF.

  vari_desc-report = report.
  vari_desc-variant = variant.
  APPEND vari_desc.


ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  EXPIRE_SOD_UG_MIT
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_LT_EXPIRE_GROUP  text
*      <--P_L_AUTH_FAILED  text
*      <--P_L_FLAG  text
*---------------------------------------------------------------------*
FORM expire_sod_ug_mit  USING    is_expire_group TYPE /psyng/sw_mcusrgrp
                        CHANGING e_auth_failed
                                 e_success.
  DATA : l_local_sys TYPE string,
         ls_mchdr    TYPE /psyng/mchdr,
         lt_mcgroup  TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CLEAR : e_success,  e_auth_failed.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_group-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_group-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
          EXPORTING
            contid                      = is_expire_group-contid
            i_vrsio                     = is_expire_group-vrsio
          IMPORTING
            mchdr                       = ls_mchdr
          TABLES
            mcugroup                    = lt_mcgroup
          EXCEPTIONS
            mit_control_id_doesnt_exist = 1
            not_authorized_to_display   = 2
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
            communication_failure       = 3
            system_failure              = 4
            OTHERS                      = 5. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
    IF sy-subrc  = 2.
      e_auth_failed = 'X'.
      EXIT.
    ENDIF.

  ELSE.
    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      EXPORTING
        contid                      = is_expire_group-contid
        i_vrsio                     = is_expire_group-vrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mcugroup                    = lt_mcgroup
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
        OTHERS                      = 3.
    IF sy-subrc  = 2.
      e_auth_failed = 'X'.
      EXIT.
    ENDIF.
  ENDIF.

  MOVE-CORRESPONDING is_expire_group TO lt_mcgroup.
*--Set expiration data
  lt_mcgroup-to_date = sy-datum - 1.
  MODIFY lt_mcgroup TRANSPORTING to_date
                   WHERE contid = is_expire_group-contid
                     AND conid  = is_expire_group-conid
                     AND class  = is_expire_group-class
                     AND vrsio  = is_expire_group-vrsio.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_group-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_group-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        is_mchdr             = ls_mchdr
        if_add_assgn_only    = 'X'
      TABLES
        it_mcusrgrp          = lt_mcgroup
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
        communication_failure       = 4
        system_failure              = 5
        OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      EXPORTING
        is_mchdr             = ls_mchdr
        if_add_assgn_only    = 'X'
      TABLES
        it_mcusrgrp          = lt_mcgroup
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
        OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.

  IF sy-subrc <> 0.
    IF sy-subrc = 2.
      e_auth_failed = 'X'.
    ENDIF.
  ELSE.
    e_success = 'X'.
*BOC C0705 B17181 ARPAN 09.02.2023
    mcuser-to_date = sy-datum - 1.
    MODIFY mcuser TRANSPORTING to_date WHERE
                        class   = is_expire_group-class AND
                        conid   = is_expire_group-conid AND
                        rfcdest = is_expire_group-rfcdest AND
                        contid  = is_expire_group-contid.
*EOC C0705 B17181 ARPAN 09.02.2023
    MESSAGE s007 WITH is_expire_group-class is_expire_group-contid
                                                  is_expire_group-conid.

  ENDIF.



ENDFORM.
*&--------------------------------------------------------------------*
*&      Form  EXPIRE_SOD_ROLE_MIT
*&--------------------------------------------------------------------*
*       text
*---------------------------------------------------------------------*
*      -->P_LT_EXPIRE_ROLE  text
*      <--P_L_AUTH_FAILED  text
*      <--P_L_FLAG  text
*---------------------------------------------------------------------*
FORM expire_sod_role_mit  USING    is_expire_role TYPE /psyng/sw_mcrole
                          CHANGING e_auth_failed
                                   e_success.
  DATA : l_local_sys TYPE string,
         ls_mchdr    TYPE /psyng/mchdr,
         lt_mcrole   TYPE TABLE OF /psyng/mcrole WITH HEADER LINE.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CLEAR : e_success,  e_auth_failed.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_role-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_role-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        contid                      = is_expire_role-contid
        i_vrsio                     = is_expire_role-vrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mcrole                      = lt_mcrole
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
       communication_failure       = 3
       system_failure              = 4
       OTHERS                      = 5. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      EXPORTING
        contid                      = is_expire_role-contid
        i_vrsio                     = is_expire_role-vrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mcrole                      = lt_mcrole
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
        OTHERS                      = 3.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.
  IF sy-subrc  = 2.
    e_auth_failed = 'X'.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING is_expire_role TO lt_mcrole.
*--Set expiration data
  lt_mcrole-to_date = sy-datum - 1.
  MODIFY lt_mcrole TRANSPORTING to_date
                   WHERE contid    = is_expire_role-contid
                     AND conid     = is_expire_role-conid
                     AND agr_name  = is_expire_role-agr_name
                     AND vrsio     = is_expire_role-vrsio.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_role-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_role-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
EXPORTING
  is_mchdr             = ls_mchdr
  if_add_assgn_only    = 'X'
TABLES
  it_mcrole            = lt_mcrole
EXCEPTIONS
  target_not_specified = 1
  not_authorized       = 2
  locked               = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  communication_failure       = 4
  system_failure              = 5
  OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      EXPORTING
        is_mchdr             = ls_mchdr
        if_add_assgn_only    = 'X'
      TABLES
        it_mcrole            = lt_mcrole
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
        OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.

  IF sy-subrc <> 0.
    IF sy-subrc = 2.
      e_auth_failed = 'X'.
    ENDIF.
* Implement suitable error handling here
  ELSE.
    e_success = 'X'.
*BOC C0705 B17181 ARPAN 09.02.2023
    mcuser-to_date = sy-datum - 1.
    MODIFY mcuser TRANSPORTING to_date WHERE
                        agr_name   = is_expire_role-agr_name AND
                        conid   = is_expire_role-conid AND
                        rfcdest = is_expire_role-rfcdest AND
                        contid  = is_expire_role-contid.
*EOC C0705 B17181 ARPAN 09.02.2023
    MESSAGE s007 WITH
    is_expire_role-agr_name
    is_expire_role-contid
    is_expire_role-conid.
  ENDIF.
ENDFORM.
FORM expire_ca_role_mit  USING    is_expire_role TYPE /psyng/sw_mccarole
                          CHANGING e_auth_failed
                                   e_success.
  DATA : l_local_sys TYPE string,
         ls_mchdr    TYPE /psyng/mchdr,
         lt_mcrole   TYPE TABLE OF /psyng/mccarole WITH HEADER LINE.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CLEAR : e_success,  e_auth_failed.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_role-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_role-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        contid                      = is_expire_role-contid
        i_vrsio                     = is_expire_role-vrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mccarole                      = lt_mcrole
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
        communication_failure       = 3
        system_failure              = 4
        OTHERS                      = 5."#EC SAST_CI_GEN_CHECK
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
      EXPORTING
        contid                      = is_expire_role-contid
        i_vrsio                     = is_expire_role-vrsio
      IMPORTING
        mchdr                       = ls_mchdr
      TABLES
        mccarole                      = lt_mcrole
      EXCEPTIONS
        mit_control_id_doesnt_exist = 1
        not_authorized_to_display   = 2
        OTHERS                      = 3.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.

  IF sy-subrc  = 2.
    e_auth_failed = 'X'.
    EXIT.
  ENDIF.

  MOVE-CORRESPONDING is_expire_role TO lt_mcrole.
*--Set expiration data
  lt_mcrole-to_date = sy-datum - 1.
  MODIFY lt_mcrole TRANSPORTING to_date
                   WHERE contid    = is_expire_role-contid
                     AND swaudid   = is_expire_role-swaudid
                     AND agr_name  = is_expire_role-agr_name
                     AND vrsio     = is_expire_role-vrsio.

  READ TABLE gt_rfcdest WITH KEY rfcoptions = is_expire_role-rfcdest.

  IF sy-subrc = 0 AND NOT is_expire_role-rfcdest = l_local_sys.

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

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
    DESTINATION gt_rfcdest-rfcdest
    EXPORTING
      is_mchdr             = ls_mchdr
      if_add_assgn_only    = 'X'
    TABLES
      it_mccarole          = lt_mcrole
    EXCEPTIONS
      target_not_specified        = 1
      not_authorized              = 2
      locked                      = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      communication_failure       = 4
      system_failure              = 5
      OTHERS                      = 6. "#EC SAST_CI_GEN_CHECK
     IF sy-subrc <> 0.
*       MESSAGE ID sy-msgid TYPE sy-msgty
*         NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      EXPORTING
        is_mchdr             = ls_mchdr
        if_add_assgn_only    = 'X'
      TABLES
        it_mccarole          = lt_mcrole
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
        OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.
  IF sy-subrc <> 0.
    IF sy-subrc = 2.
      e_auth_failed = 'X'.
    ENDIF.
* Implement suitable error handling here
  ELSE.
    e_success = 'X'.
*BOC C0705 B17181 ARPAN 09.02.2023
    mcuser-to_date = sy-datum - 1.
    MODIFY mcuser TRANSPORTING to_date WHERE
                        agr_name   = is_expire_role-agr_name AND
                        conid   = is_expire_role-swaudid AND
                        rfcdest = is_expire_role-rfcdest AND
                        contid  = is_expire_role-contid.
*EOC C0705 B17181 ARPAN 09.02.2023
    MESSAGE s007 WITH
    is_expire_role-agr_name
    is_expire_role-contid
    is_expire_role-swaudid.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PROCESS_BACKGROUND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_background .
*--Display information about parameters in job log
  DATA  : l_program TYPE sy-repid.
  l_program = sy-repid.
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid = l_program.
  IF p_disply = 'X'.
    PERFORM output_alv.
  ELSEIF p_notify = 'X'.
    PERFORM notify_expiring_mit.
  ELSE.
*--Mark all records and expire
    mcuser-mark = 'X'.
    MODIFY  mcuser TRANSPORTING mark WHERE mark <> 'X'.
    PERFORM expire_all_marked_mit.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DELETE_ALL_MARKED_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_all_marked_mit .
  DATA : lf_mcusr TYPE flag,
         lf_mcusrgrp TYPE flag,
         lf_mcrole TYPE flag,
         lf_mit_del_expire_only TYPE flag,
         lf_defied TYPE flag,
         lv_tabix TYPE sy-tabix,
         l_cnt_usr(100)   TYPE n, "Total user mitigations
         l_sel_usr(100)   TYPE n, "Total selected user mitigations
         l_cnt_grp(100)   TYPE n, "Total user group mitigations
         l_sel_grp(100)   TYPE n, "Total selected user group mitigations
         l_cnt_rol(100)   TYPE n, "Total role mitigations
         l_sel_rol(100)   TYPE n, "Total selected role mitigations
         l_sucess         TYPE i, "no of successfuly deleted user mit
         l_success_ug     TYPE i, "no of successfuly deleted usrgrp mit
         l_success_role   TYPE i, "no of successfuly deleted role mit
         lf_del_marked TYPE flag. "Controls delete action

  DATA : lt_delete_group TYPE TABLE OF /psyng/sw_mcusrgrp
      WITH HEADER LINE,
       lt_delete_role  TYPE TABLE OF /psyng/sw_mcrole
       WITH HEADER LINE,
       lt_delete_ca_role TYPE TABLE OF /psyng/sw_mccarole
       WITH HEADER LINE.

  se_config_param 'MIT_DEL_EXPIRE_ONLY' lf_mit_del_expire_only.

  PERFORM cfg_para_compliance USING lf_mit_del_expire_only
                              CHANGING lf_defied.

  IF lf_defied = 'X'.
    PERFORM refresh_output.
    EXIT.
  ENDIF.

  PERFORM total_selected_mit CHANGING l_cnt_usr l_sel_usr
                                      l_cnt_grp l_sel_grp
                                      l_cnt_rol l_sel_rol.

  IF sy-batch EQ abap_false.
    IF l_sel_usr > 0.
      PERFORM user_confimation_popup USING l_cnt_usr
                                     CHANGING l_sel_usr lf_del_marked.
    ENDIF.
  ELSE.
    lf_del_marked = 'X'.
  ENDIF.

  LOOP AT mcuser WHERE mark = 'X'.
    g_action_idx = sy-tabix.
    lv_tabix = sy-tabix.
    PERFORM check_mitigation_type CHANGING lf_mcusr lf_mcusrgrp
                                           lf_mcrole.
    IF lf_mcusr = 'X' AND lf_del_marked = 'X'.
      PERFORM delete_user_mit USING lv_tabix CHANGING l_sucess.
      CLEAR lf_mcusr.
    ENDIF.

    IF lf_mcusrgrp = 'X'.
      lt_delete_group-contid     = mcuser-contid.
      lt_delete_group-conid      = mcuser-conid.
      lt_delete_group-class      = mcuser-assn_class.
      lt_delete_group-vrsio      = mcuser-vrsio.
      lt_delete_group-auditor    = mcuser-auditor.
      lt_delete_group-from_date  = mcuser-from_date.
      lt_delete_group-to_date    = mcuser-to_date.
      lt_delete_group-rfcdest    = mcuser-rfcdest.
      COLLECT lt_delete_group.
      CLEAR lf_mcusrgrp.
    ENDIF.

    IF lf_mcrole = 'X'.
      IF mcuser-type = 'S'.
        lt_delete_role-contid     = mcuser-contid.
        lt_delete_role-conid      = mcuser-conid.
        lt_delete_role-agr_name   = mcuser-agr_name.
        lt_delete_role-vrsio      = mcuser-vrsio.
        lt_delete_role-auditor    = mcuser-auditor.
        lt_delete_role-from_date  = mcuser-from_date.
        lt_delete_role-to_date    = mcuser-to_date.
        lt_delete_role-rfcdest    = mcuser-rfcdest.
        COLLECT lt_delete_role.
      ELSE.
        lt_delete_ca_role-contid    = mcuser-contid.
        lt_delete_ca_role-swaudid   = mcuser-conid.
        lt_delete_ca_role-agr_name  = mcuser-agr_name.
        lt_delete_ca_role-vrsio     = mcuser-vrsio.
        lt_delete_ca_role-auditor   = mcuser-auditor.
        lt_delete_ca_role-from_date = mcuser-from_date.
        lt_delete_ca_role-to_date   = mcuser-to_date.
        lt_delete_ca_role-rfcdest   = mcuser-rfcdest.
        COLLECT lt_delete_ca_role.
      ENDIF.
      CLEAR lf_mcrole.
    ENDIF.
  ENDLOOP.

  IF sy-subrc = 0.
    PERFORM refresh_output.
    READ TABLE mcuser INDEX g_action_idx.
  ELSE.
    IF no_disp IS INITIAL.
      MESSAGE i113 WITH
      'Please select at least one user mitigation.'(028).
    ENDIF.
  ENDIF.

  IF l_sel_grp > 0.
    CLEAR lf_del_marked.
    IF sy-batch EQ abap_false.
      PERFORM usrgrp_confimation_popup USING l_cnt_grp
                                     CHANGING l_sel_grp lf_del_marked.
    ELSE.
      lf_del_marked = 'X'.
    ENDIF.

    IF lf_del_marked = 'X'.
      PERFORM delete_usrgrp_mit USING lt_delete_group[]
                                CHANGING l_success_ug.
      PERFORM refresh_output.
    ENDIF.
  ENDIF.

  IF l_sel_rol > 0.
    CLEAR lf_del_marked.
    IF sy-batch EQ abap_false.
      PERFORM role_confirmation_popup USING l_cnt_rol
                                      CHANGING l_sel_rol
                                               lf_del_marked.
    ELSE.
      lf_del_marked = 'X'.
    ENDIF.

    IF lf_del_marked = 'X'.
      PERFORM delete_role_mit USING lt_delete_role[]
                                    lt_delete_ca_role[]
                          CHANGING l_success_role.
      PERFORM refresh_output.
    ENDIF.
  ENDIF.

  PERFORM summary USING l_sucess l_success_ug l_success_role.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_MITIGATION_TYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LF_MCUSR  text
*      <--P_LF_MCUSRGRP  text
*      <--P_LF_MCROLE  text
*----------------------------------------------------------------------*
FORM check_mitigation_type CHANGING lf_mcusr TYPE flag
                                     lf_mcusrgrp TYPE flag
                                     lf_mcrole TYPE flag.
  IF mcuser-asg_usr = 'X'.
    lf_mcusr = 'X'.
  ELSEIF mcuser-asg_grp = 'X'.
    lf_mcusrgrp = 'X'.
  ELSEIF mcuser-asg_rol = 'X'.
    lf_mcrole = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TOTAL_SELECTED_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_CNT_USR  text
*      <--P_L_SEL_USR  text
*      <--P_L_CNT_GRP  text
*      <--P_L_SEL_GRP  text
*      <--P_L_CNT_ROL  text
*      <--P_L_SEL_ROL  text
*----------------------------------------------------------------------*
FORM total_selected_mit  CHANGING l_cnt_usr TYPE n
                                  l_sel_usr TYPE n
                                  l_cnt_grp TYPE n
                                  l_sel_grp TYPE n
                                  l_cnt_rol TYPE n
                                  l_sel_rol TYPE n.

  LOOP AT mcuser .
    CASE 'X'.
      WHEN  mcuser-asg_usr.
        ADD 1 TO l_cnt_usr.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_usr.
        ENDIF.
      WHEN mcuser-asg_grp.
        ADD 1 TO l_cnt_grp.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_grp.
        ENDIF.
      WHEN mcuser-asg_rol.
        ADD 1 TO l_cnt_rol.
        IF mcuser-mark = abap_true.
          ADD 1 TO l_sel_rol.
        ENDIF.
    ENDCASE.
  ENDLOOP.

  SHIFT l_cnt_usr LEFT DELETING LEADING '0'.
  SHIFT l_sel_usr LEFT DELETING LEADING '0'.
  SHIFT l_cnt_grp LEFT DELETING LEADING '0'.
  SHIFT l_sel_grp LEFT DELETING LEADING '0'.
  SHIFT l_cnt_rol LEFT DELETING LEADING '0'.
  SHIFT l_sel_rol LEFT DELETING LEADING '0'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  USER_CONFIMATION_POPUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_CNT_USR  text
*      <--P_L_SEL_USR  text
*      <--P_LF_DEL_MARKED  text
*----------------------------------------------------------------------*
FORM user_confimation_popup  USING    l_cnt_usr TYPE n
                             CHANGING l_sel_usr TYPE n
                                      lf_del_marked TYPE flag.

  DATA : lv_question TYPE string,
        lv_answer(1) TYPE c.

  CONCATENATE 'Delete'(212) l_sel_usr 'of'(203) l_cnt_usr
'user mitigation(s)?'(204) INTO lv_question SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar = 'Warning Message'(205)
      text_question         = lv_question
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  CASE lv_answer.
    WHEN '1'.
      lf_del_marked = 'X'.
    WHEN '2'.
      CLEAR l_sel_usr.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DELETE_USER_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_TABIX  text
*      <--P_L_SUCESS  text
*----------------------------------------------------------------------*
FORM delete_user_mit USING lv_tabix TYPE sy-tabix
                     CHANGING l_sucess TYPE i.

  DATA : lt_mcuser TYPE TABLE OF /psyng/mcuser,
         lt_mccauser TYPE TABLE OF /psyng/mcuser,
         ls_mcuser TYPE /psyng/mcuser,
         ls_mccauser TYPE /psyng/mcuser,
         ls_mchdr  TYPE /psyng/mchdr,
         l_local_sys    TYPE string.

  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.

  ls_mchdr-contid = mcuser-contid.

  REFRESH: lt_mcuser, lt_mccauser.

  IF mcuser-type = 'S'.

    MOVE-CORRESPONDING mcuser TO ls_mcuser.
    APPEND ls_mcuser TO lt_mcuser.

    READ TABLE gt_rfcdest WITH KEY rfcoptions = mcuser-rfcdest.

    IF sy-subrc = 0 AND NOT mcuser-rfcdest = l_local_sys.
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
       EXCEPTIONS
         invalid_reject_option        = 1
         invalid_reject_state         = 2
         function_not_supported       = 3
         internal_error               = 4
         OTHERS                       = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
        EXPORTING
          is_mchdr                  = ls_mchdr
          if_del_assgn_only          = 'X'
        TABLES
          it_mcuser                  = lt_mcuser
        EXCEPTIONS
          target_not_specified       = 1
          not_authorized             = 2
          locked                     = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
            communication_failure       = 4
            system_failure              = 5
            OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc = 0.
        ADD 1 TO l_sucess.
        DELETE mcuser INDEX lv_tabix.
      ENDIF.

    ELSE.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr                  = ls_mchdr
         if_del_assgn_only          = 'X'
       TABLES
         it_mcuser                  = lt_mcuser
       EXCEPTIONS
         target_not_specified       = 1
         not_authorized             = 2
         locked                     = 3
         OTHERS                     = 4
                .
      IF sy-subrc = 0.
        ADD 1 TO l_sucess.
        DELETE mcuser INDEX lv_tabix.
      ENDIF.

    ENDIF.

  ELSE.

    MOVE-CORRESPONDING mcuser TO ls_mccauser.
    APPEND ls_mccauser TO lt_mccauser.

    READ TABLE gt_rfcdest WITH KEY rfcoptions = mcuser-rfcdest.

    IF sy-subrc = 0 AND NOT mcuser-rfcdest = l_local_sys.

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

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
        EXPORTING
          is_mchdr                  = ls_mchdr
          if_del_assgn_only          = 'X'
        TABLES
          it_mccauser                  = lt_mccauser
        EXCEPTIONS
          target_not_specified       = 1
          not_authorized             = 2
          locked                     = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
            communication_failure       = 4
            system_failure              = 5
            OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc = 0.
        ADD 1 TO l_sucess.
        DELETE mcuser INDEX lv_tabix.
      ENDIF.

    ELSE.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
       EXPORTING
        is_mchdr                  = ls_mchdr
        if_del_assgn_only          = 'X'
       TABLES
        it_mccauser                  = lt_mccauser
       EXCEPTIONS
        target_not_specified       = 1
        not_authorized             = 2
        locked                     = 3
        OTHERS                     = 4
            .
      IF sy-subrc = 0.
        ADD 1 TO l_sucess.
        DELETE mcuser INDEX lv_tabix.
      ENDIF.

    ENDIF.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  USRGRP_CONFIMATION_POPUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_CNT_GRP  text
*      <--P_L_SEL_GRP  text
*      <--P_LF_DEL_MARKED  text
*----------------------------------------------------------------------*
FORM usrgrp_confimation_popup  USING l_cnt_grp TYPE n
                               CHANGING l_sel_grp TYPE n
                                        lf_del_marked TYPE flag.

  DATA : lv_question TYPE string,
      lv_answer(1) TYPE c.

  CONCATENATE 'Delete'(212) l_sel_grp 'of'(203) l_cnt_grp
'user group mitigation(s)?'(042) INTO lv_question
SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar    = 'This action may affect multiple users'(048)
      text_question         = lv_question
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  CASE lv_answer.
    WHEN '1'.
      lf_del_marked = abap_true.
    WHEN '2'.
      CLEAR l_sel_grp .
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DELETE_USRGRP_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_DELETE_GROUP  text
*      <--P_L_SUCCESS_UG  text
*----------------------------------------------------------------------*
FORM delete_usrgrp_mit  USING    lt_delete_group TYPE tt1_mcusrgrp
                        CHANGING l_success_ug TYPE i.

  DATA : ls_delete_group TYPE /psyng/sw_mcusrgrp,
        ls_mchdr TYPE /psyng/mchdr,
        lt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp,
        ls_mcusrgrp TYPE /psyng/mcusrgrp,
        l_local_sys    TYPE string.

  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.

  LOOP AT lt_delete_group INTO ls_delete_group.

    REFRESH lt_mcusrgrp.
    ls_mchdr-contid = ls_delete_group-contid.
    MOVE-CORRESPONDING ls_delete_group TO ls_mcusrgrp.
    APPEND ls_mcusrgrp TO lt_mcusrgrp.


    READ TABLE gt_rfcdest WITH KEY rfcoptions = ls_delete_group-rfcdest.

    IF sy-subrc = 0 AND NOT ls_delete_group-rfcdest = l_local_sys.

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

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        is_mchdr             = ls_mchdr
        if_del_assgn_only    = 'X'
      TABLES
        it_mcusrgrp          = lt_mcusrgrp
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
        communication_failure       = 4
        system_failure              = 5
        OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
    ELSE.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = ls_mchdr
          if_del_assgn_only    = 'X'
        TABLES
          it_mcusrgrp          = lt_mcusrgrp
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

    ENDIF.

    IF sy-subrc = 0.
      ADD 1 TO l_success_ug.
      DELETE mcuser WHERE class = ls_delete_group-class AND
      conid   = ls_delete_group-conid AND
      contid  = ls_delete_group-contid AND
      rfcdest = ls_delete_group-rfcdest.
    ENDIF.

  ENDLOOP. "Deleting user group mitigations

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ROLE_CONFIRMATION_POPUP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_CNT_ROL  text
*      <--P_L_SEL_ROL  text
*      <--P_LF_DEL_MARKED  text
*----------------------------------------------------------------------*
FORM role_confirmation_popup  USING    l_cnt_rol TYPE n
                              CHANGING l_sel_rol TYPE n
                                       lf_del_marked TYPE flag.

  DATA : lv_question TYPE string,
    lv_answer(1) TYPE c.

  CONCATENATE 'Delete'(212) l_sel_rol 'of'(203) l_cnt_rol
'role mitigation(s)?'(043) INTO lv_question SEPARATED BY space.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar    = 'This action may affect multiple users'(048)
      text_question         = lv_question
      text_button_1         = 'Yes'
      text_button_2         = 'No'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = lv_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  CASE lv_answer.
    WHEN '1'.
      lf_del_marked = abap_true.
    WHEN '2'.
      CLEAR l_sel_rol.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DELETE_ROLE_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_DELETE_ROLE  text
*      -->P_LT_DELETE_CA_ROLE  text
*      <--P_L_SUCCESS_ROLE  text
*----------------------------------------------------------------------*
FORM delete_role_mit  USING    lt_delete_role TYPE tt1_mcrole
                               lt_delete_ca_role TYPE tt1_mccarole
                      CHANGING l_success_role TYPE i.

  DATA : ls_delete_role TYPE /psyng/sw_mcrole,
         ls_delete_ca_role TYPE /psyng/sw_mccarole,
         ls_mchdr TYPE /psyng/mchdr,
         ls_mccahdr TYPE /psyng/mchdr,
        lt_mcrole TYPE TABLE OF /psyng/mcrole,
        lt_mccarole TYPE TABLE OF /psyng/mccarole,
        ls_mcrole TYPE /psyng/mcrole,
        ls_mccarole TYPE /psyng/mccarole,
        l_local_sys    TYPE string.

  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.

  LOOP AT lt_delete_role INTO ls_delete_role.

    REFRESH lt_mcrole.
    ls_mchdr-contid = ls_delete_role-contid.
    MOVE-CORRESPONDING ls_delete_role TO ls_mcrole.
    APPEND ls_mcrole TO lt_mcrole.

    READ TABLE gt_rfcdest WITH KEY rfcoptions = ls_delete_role-rfcdest.

    IF sy-subrc = 0 AND NOT ls_delete_role-rfcdest = l_local_sys.

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

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
       DESTINATION gt_rfcdest-rfcdest
   EXPORTING
     is_mchdr             = ls_mchdr
     if_del_assgn_only    = 'X'
   TABLES
     it_mcrole            = lt_mcrole
   EXCEPTIONS
     target_not_specified = 1
     not_authorized       = 2
     locked               = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
     communication_failure       = 4
     system_failure              = 5
     OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
    ELSE.

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = ls_mchdr
          if_del_assgn_only    = 'X'
        TABLES
          it_mcrole            = lt_mcrole
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
    ENDIF.

    IF sy-subrc = 0.
      ADD 1 TO l_success_role.
      DELETE mcuser WHERE agr_name = ls_delete_role-agr_name AND
                          conid    = ls_delete_role-conid AND
                          contid   = ls_delete_role-contid AND
                          rfcdest  = ls_delete_role-rfcdest.
    ENDIF.

  ENDLOOP.

  LOOP AT lt_delete_ca_role INTO ls_delete_ca_role.

    REFRESH lt_mccarole.
    ls_mccahdr-contid = ls_delete_ca_role-contid.
    MOVE-CORRESPONDING ls_delete_ca_role TO ls_mccarole.
    APPEND ls_mccarole TO lt_mccarole.


    READ TABLE gt_rfcdest WITH KEY rfcoptions =
ls_delete_ca_role-rfcdest.

    IF sy-subrc = 0 AND NOT ls_delete_ca_role-rfcdest = l_local_sys.

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

      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        is_mchdr             = ls_mccahdr
        if_del_assgn_only    = 'X'
      TABLES
        it_mccarole            = lt_mccarole
      EXCEPTIONS
        target_not_specified = 1
        not_authorized       = 2
        locked               = 3
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
        communication_failure       = 4
        system_failure              = 5
        OTHERS                      = 6."#EC SAST_CI_GEN_CHECK
IF sy-subrc <> 0.
*  MESSAGE ID sy-msgid TYPE sy-msgty
*    NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
ENDIF.

*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733

    ELSE.
      CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
        EXPORTING
          is_mchdr             = ls_mccahdr
          if_del_assgn_only    = 'X'
        TABLES
          it_mccarole            = lt_mccarole
        EXCEPTIONS
          target_not_specified = 1
          not_authorized       = 2
          locked               = 3
          OTHERS               = 4.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty
*          NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
*<-- EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
    ENDIF.
    IF sy-subrc = 0.
      ADD 1 TO l_success_role.
      DELETE mcuser WHERE agr_name = ls_delete_ca_role-agr_name AND
                          conid    = ls_delete_ca_role-swaudid AND
                          contid   = ls_delete_ca_role-contid AND
                          rfcdest = ls_delete_ca_role-rfcdest.
    ENDIF.

  ENDLOOP. "Deleting role mitigations

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SUMMARY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SUCESS  text
*      -->P_L_SUCCESS_UG  text
*      -->P_L_SUCCESS_ROLE  text
*----------------------------------------------------------------------*
FORM summary  USING    l_sucess TYPE i
                       l_success_ug TYPE i
                       l_success_role TYPE i.

  IF sy-batch EQ abap_false.
    IF l_sucess > 0.
      g_userassign = g_userassign - l_sucess.
      MESSAGE i113 WITH l_sucess 'User mitigations deleted'(213).
    ENDIF.
    IF l_success_ug > 0.
      g_groupassign = g_groupassign - l_success_ug.
      MESSAGE i113 WITH l_success_ug
      'User Group mitigations deleted'(214).
    ENDIF.
    IF l_success_role > 0.
      g_roleassign = g_roleassign - l_success_role.
      MESSAGE i113 WITH l_success_role
      'Role mitigations deleted'(215).
    ENDIF.
  ELSE.
    MESSAGE s113 WITH l_sucess 'User mitigations deleted'(213).
    MESSAGE s113 WITH l_success_ug
    'User Group mitigations expired'(214).
    MESSAGE s113 WITH l_success_role
    'Role mitigations expired'(215).
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CFG_PARA_COMPLIANCE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LF_MIT_DEL_EXPIRE_ONLY  text
*      <--P_LF_EXIT  text
*----------------------------------------------------------------------*
FORM cfg_para_compliance  USING    lf_mit_del_expire_only TYPE flag
                          CHANGING lf_defied TYPE flag.

  IF lf_mit_del_expire_only = 'Y'.
    LOOP AT mcuser WHERE mark = 'X'.
      IF mcuser-to_date GT sy-datum.
        MESSAGE i113 WITH
        'Please select only expired mitigations.'(216).
        lf_defied = 'X'.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NOTIFY_EXPIRING_MIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM notify_expiring_mit .

  DATA : ls_mchdr       TYPE /psyng/mchdr,
         lt_mcuser      TYPE TABLE OF /psyng/mcuser,
         ls_mcuser TYPE /psyng/mcuser,
        lt_headers TYPE TABLE OF /psyng/bc_tab_headers WITH HEADER LINE,
        l_tabstyle TYPE sylisel,
        l_tabtitle TYPE text300,
        l_title     TYPE sodocchgi1-obj_descr,
        l_send_templ TYPE thead-tdname,
        l_css_temp TYPE dokhl-object,
        l_subject TYPE so_obj_des,
        l_sysid TYPE sy-sysid,
        l_mandt TYPE sy-mandt,

 BEGIN OF gt_output OCCURS 0,
        object  TYPE char30,
        type   TYPE char20,
        conflict_id  TYPE /psyng/conflict_id,
        version  TYPE /psyng/sodvrsio,
        control_id TYPE /psyng/contid,
        auditor TYPE /psyng/auditor,
        valid_from TYPE datab,
        valid_to TYPE datum,
      END OF gt_output.


  DATA :  lt_email LIKE TABLE OF gt_output WITH HEADER LINE.

  TYPES: BEGIN OF ty_auditor ,
          auditor TYPE xubname,
          END OF ty_auditor.

  TYPES: BEGIN OF ty_contid,
          contid TYPE /psyng/contid,
          END OF ty_contid.

  DATA: lt_auditor     TYPE TABLE OF ty_auditor,
        ls_auditor TYPE ty_auditor,
        lt_contid TYPE TABLE OF ty_contid,
        ls_contid TYPE ty_contid.

  DATA :  lt_auditor_1   TYPE TABLE OF /psyng/bc_userid_name
        WITH HEADER LINE,
          ls_auditor_1 TYPE /psyng/bc_userid_name,
          l_fromdate     TYPE dats,
          l_todate       TYPE dats,
         lt_assignment_part  TYPE TABLE OF /psyng/mitigation_assignment,
         ls_assignment_part TYPE  /psyng/mitigation_assignment,
         lt_assign_expired TYPE TABLE OF /psyng/mitigation_assignment,
         lt_assignment_tab TYPE TABLE OF /psyng/mitigation_assignment,
         lt_user_range_part TYPE TABLE OF /psyng/sw_sel_opts_xubname
                          WITH HEADER LINE,
          lt_uinfo TYPE TABLE OF   /psyng/sw_uinfo_remote,
          ls_uinfo TYPE /psyng/sw_uinfo_remote.

  DATA : lt_email_cont TYPE TABLE OF solisti1.

  DATA: l_value  TYPE /psyng/swconfig-value,
        lv_validday(4) TYPE c,
        lv_date TYPE i,
        l_auditorcount TYPE i,
        lv_days          TYPE c,
        lt_htmlt TYPE /psyng/bc_html_data_t ,
        ls_htmlt TYPE /psyng/bc_html_data,
        l_system TYPE rfcdest,
        lt_adresses TYPE TABLE OF ad_smtpadr WITH HEADER LINE,
        gt_data_htm    TYPE TABLE OF  solisti1 WITH HEADER LINE,
        l_nr_of_days TYPE i,
         lt_usr02  TYPE TABLE OF /psyng/sw_uinfo_remote.


  DATA : lt_mchdr  TYPE TABLE OF /psyng/mchdr  WITH HEADER LINE.

  TYPES: l_auditor TYPE  usr21-bname.

  DEFINE header.
    lt_headers-fld_name = &1.
    lt_headers-fld_txt  = &2.
    append lt_headers.
  END-OF-DEFINITION.
  DEFINE add_placeholder.
    ls_htmlt-placeholder = &1.
    ls_htmlt-text        = &2.
    ls_htmlt-html_table = gt_data_htm[].
    append ls_htmlt to lt_htmlt.
    clear ls_htmlt.
  END-OF-DEFINITION.


**BOC PN-2646  CGUPTA 04/12/2023

**BOC PN-2779  CGUPTA 11/12/2023

  IF userid IS NOT INITIAL OR
    contid IS NOT INITIAL OR conid IS NOT INITIAL OR
    auditor IS NOT INITIAL OR valid_fr IS NOT INITIAL
    OR valid_to IS NOT INITIAL .

    DATA: tab1 TYPE TABLE OF /psyng/mcuser.
    SELECT * FROM /psyng/mcuser INTO TABLE tab1
      WHERE contid IN contid AND
    conid IN conid AND
    userid IN userid  AND
    auditor IN auditor AND
      from_date IN valid_fr AND
      to_date IN valid_to.

    IF sy-subrc NE 0.
      MESSAGE s002(/psyng/sw) WITH
       'No Mitigation data found for the'(037)
       'corressponding input.'(038).
      EXIT.
    ENDIF.

  ENDIF.

  IF s_class IS NOT INITIAL.
    DATA tab2 TYPE TABLE OF /psyng/mcusrgrp.
    SELECT * FROM /psyng/mcusrgrp INTO TABLE tab2
       WHERE  class IN s_class .
    IF sy-subrc NE 0.
      MESSAGE s002(/psyng/sw) WITH
       'No Mitigation data found for the'(037)
       'corressponding input.'(038).
      EXIT.
    ENDIF.

  ENDIF.

  IF swaudid IS NOT INITIAL.

    DATA: tab3 TYPE TABLE OF /psyng/mccauser,
          tab4 TYPE TABLE OF /psyng/mccarole.
    SELECT * FROM /psyng/mccauser INTO TABLE tab3
        WHERE swaudid    IN  swaudid .

    SELECT * FROM /psyng/mccarole INTO TABLE tab4
     WHERE swaudid    IN  swaudid .

    IF tab3[] IS INITIAL AND tab4[] IS INITIAL.
      MESSAGE s002(/psyng/sw) WITH
    'No Mitigation data found for the'(037)
    'corressponding input.'(038).
      EXIT.

    ENDIF.

  ENDIF.

**EOC PN-2779  CGUPTA 11/12/2023

***For Mitigation expiring or expired
  se_config_param 'MIT_ASGN_NOTIFY_DAYS' l_value.
  l_nr_of_days = l_value.


  PERFORM collect_mitigations TABLES lt_assign_expired.
  APPEND LINES OF lt_assign_expired TO lt_assignment_part.

** Check Select option Values for COMPANY



  IF s_comp[] IS NOT INITIAL.
    LOOP AT mcuser[] ASSIGNING <mcuser>.
      READ TABLE s_comp[] TRANSPORTING NO FIELDS
         WITH KEY low = <mcuser>-compshort.
      IF sy-subrc = 0.
        READ TABLE lt_assignment_part INTO ls_assignment_part
        WITH KEY  class = <mcuser>-class
                  contid = <mcuser>-contid
                  conid = <mcuser>-conid
                  auditor = <mcuser>-auditor.
        IF sy-subrc = 0.
          APPEND ls_assignment_part TO lt_assignment_tab.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF sy-subrc NE 0.
      MESSAGE s002(/psyng/sw) WITH
      'No Mitigation data found for the'(037)
      'corressponding input.'(038).
      EXIT.
    ENDIF.

  ENDIF.

** Check Select option Values for DEPARTMENT

  IF s_depart[] IS NOT INITIAL.
    LOOP AT mcuser[] ASSIGNING <mcuser>.
      READ TABLE s_depart[] TRANSPORTING NO FIELDS
         WITH KEY low = <mcuser>-department.
      IF sy-subrc = 0.
        READ TABLE lt_assignment_part INTO ls_assignment_part
        WITH KEY  class = <mcuser>-class
                  contid = <mcuser>-contid
                  conid = <mcuser>-conid
                  auditor = <mcuser>-auditor.
        IF sy-subrc = 0.
          APPEND ls_assignment_part TO lt_assignment_tab.
        ENDIF.
      ENDIF.
    ENDLOOP.

    IF sy-subrc NE 0.
      MESSAGE s002(/psyng/sw) WITH
      'No Mitigation data found for the'(037)
      'corressponding input.'(038).
      EXIT.
    ENDIF.

  ENDIF.

** Check Select option Values for Valid from and Valid TO date

  IF valid_fr[] IS NOT INITIAL OR valid_to[] IS NOT INITIAL.
    DELETE lt_assignment_part WHERE NOT from_date
           IN valid_fr OR NOT to_date IN valid_to.
    lt_assignment_tab[] = lt_assignment_part[].
  ENDIF.

  IF lt_assignment_tab IS NOT INITIAL.

    CLEAR lt_assignment_part.
    lt_assignment_part[] = lt_assignment_tab[].

  ENDIF.

**EOC PN-2646  CGUPTA 04/12/2023


  LOOP AT lt_assignment_part INTO ls_assignment_part.
    APPEND ls_assignment_part-auditor TO lt_auditor.
    CLEAR ls_assignment_part.
  ENDLOOP.


  DELETE ADJACENT DUPLICATES FROM  lt_auditor.


*Get the notification days


  se_config_param 'SW_CSS_EMAIL' l_css_temp.
  se_config_param 'SW_MIT_EXPIRE_EMAIL' l_send_templ.

*---Get system information

  CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
   IMPORTING
     e_rfcdest       = l_system.
  IF NOT l_system IS INITIAL.
    l_mandt = l_system+3(3).                     "#EC SAST_CI_GEN_CHECK
    l_sysid = l_system+0(3).
  ENDIF.

*--Add the table

  header :
     'OBJECT'     'Object'(t01) ,
     'TYPE'        'Type'(t02)    ,
     'CONFLICT_ID'       'Conflict ID'(t03)   ,
     'VERSION'      'Version'(t04)           ,
     'CONTROL_ID'       'Control ID'(t06)   ,
     'AUDITOR'    'Auditor'(t07),
     'VALID_FROM'       'Valid_From'(t08)  ,
     'VALID_TO'  'Valid_To'(t09) .



  LOOP AT lt_auditor INTO ls_auditor.

    LOOP AT lt_assignment_part INTO ls_assignment_part WHERE
                 auditor = ls_auditor-auditor.

      gt_output-conflict_id   = ls_assignment_part-conid.
      gt_output-version  = ls_assignment_part-vrsio.
      gt_output-control_id = ls_assignment_part-contid.
      gt_output-auditor = ls_assignment_part-auditor.
      gt_output-valid_from = ls_assignment_part-from_date.
      gt_output-valid_to  = ls_assignment_part-to_date.

      CASE ls_assignment_part-type.
        WHEN '1'.
          gt_output-type = 'USER'.
          gt_output-object   = ls_assignment_part-userid.
        WHEN '2'.
          gt_output-type ='USERGROUP'.
          gt_output-object   = ls_assignment_part-class.
        WHEN '3'.
          gt_output-type = 'CR AUTH USER'.
          gt_output-object   = ls_assignment_part-userid.
        WHEN '4'.
          gt_output-type = 'ROLE'.
          gt_output-object   = ls_assignment_part-agr_name.
        WHEN '5'.
          gt_output-type = 'CR AUTH ROLE'.
          gt_output-object   = ls_assignment_part-agr_name.
      ENDCASE.

      APPEND gt_output.

    ENDLOOP.

    DELETE ADJACENT DUPLICATES FROM gt_output.

    IF gt_output-auditor IS NOT INITIAL.

      APPEND gt_output-auditor TO lt_auditor_1.
      CLEAR gt_output-auditor.


      CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       EXPORTING
         no_email = ' '
       TABLES
         username = lt_auditor_1.

      READ TABLE lt_auditor_1 INDEX 1.
      IF lt_auditor_1-smtp_addr IS NOT INITIAL.
        MOVE lt_auditor_1-smtp_addr TO lt_adresses.
        APPEND lt_adresses.
      ENDIF.

*Add table data

      CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
               EXPORTING
                    attributes = l_tabstyle
*                  title      = l_title
                    long_title = l_tabtitle
               TABLES
                    i_headers  = lt_headers
                    et_data    = gt_data_htm
                    i_table    = gt_output[].



      ls_htmlt-placeholder = '[MIT_ASSIGN_EXP_SOD_TABLE]'.
      ls_htmlt-tag = 'TABLE'.
      ls_htmlt-html_table = gt_data_htm[].
      APPEND ls_htmlt TO lt_htmlt.
      CLEAR ls_htmlt.

**--Add the placeholders
      add_placeholder : '[AUDITOR_NAME]' lt_auditor_1-name_full  ,
          '[S:Nr_OF_DAYS]'        l_value ,
          '[S:SOD_VERSION]'    gt_output-version  ,
          '[SYSTEM_ID]'         l_sysid  ,
          '[CLIENT_ID]'          l_mandt .



      CALL FUNCTION '/PSYNG/BC_HTML_EMAIL'
           EXPORTING
                header        = 'X'
                style         = l_css_temp "'/PSYNG/BC_EMAIL_CSS'
                template_name = l_send_templ
                auto_subject  = 'X'
                if_send_email = ' '  "don't send the e-mail
           IMPORTING
                e_subject     = l_subject
           TABLES
                et_data       = lt_email_cont
                it_recipients = lt_auditor_1
           CHANGING
                it_data       = lt_htmlt.


      CALL FUNCTION '/PSYNG/BC_036'
      EXPORTING
         i_subject                        = l_subject
         i_sensitivity                    = ''
         i_receiver                       = lt_adresses
        TABLES
          lt_body                         = lt_email_cont
       EXCEPTIONS
         error_sending_email              = 1
         too_many_receivers               = 2
         document_not_sent                = 3
         document_type_not_exist          = 4
         operation_no_authorization       = 5
         parameter_error                  = 6
         x_error                          = 7
         enqueue_error                    = 8
         OTHERS                           = 9.

      IF sy-subrc <> 0.
        MESSAGE e002(/psyng/sw) WITH
        'Sending E-mail failed. /PSYNG/BC_036 - subrc = ' sy-subrc.
      ENDIF.

      l_auditorcount = l_auditorcount + 1.

      CLEAR :lt_auditor_1[],gt_output[],lt_adresses[],lt_htmlt[],
      lt_email_cont[],gt_data_htm[].

    ENDIF.
  ENDLOOP.


  IF sy-batch = 'X'.
    MESSAGE s002(/psyng/sw) WITH 'Email sent to'(217) l_auditorcount
     'Auditors'(218) .
    CLEAR  l_auditorcount.
  ENDIF.

  MESSAGE s398(00) WITH 'Email Sent'(002).


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  COLLECT_EXPIRED_MITIGATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ASSIGN_EXPIRED  text
*----------------------------------------------------------------------*
FORM collect_mitigations TABLES
      et_expired_mit STRUCTURE  /psyng/mitigation_assignment.

  DATA: lt_user TYPE TABLE OF /psyng/mcuser,
        lt_causer TYPE TABLE OF /psyng/mccauser,
        lt_usergrp TYPE TABLE OF /psyng/mcusrgrp,
        ls_usergrp TYPE  /psyng/mcusrgrp,
        ls_user LIKE LINE OF lt_user,
        ls_causer LIKE LINE OF lt_causer,
        lt_role TYPE TABLE OF /psyng/mcrole,
        ls_role TYPE /psyng/mcrole,
        lt_carole TYPE TABLE OF /psyng/mccarole,
        ls_carole TYPE /psyng/mccarole,
        ls_expired_mit TYPE /psyng/mitigation_assignment,
        l_nr_of_days TYPE i,
        l_value  TYPE /psyng/swconfig-value.


  se_config_param 'MIT_ASGN_NOTIFY_DAYS' l_value.
  l_nr_of_days = l_value.

  RANGES: lr_date FOR sy-datum.
  lr_date-sign = 'I'. lr_date-option = 'LE'.
  lr_date-low = sy-datum + l_nr_of_days.
  COLLECT lr_date.


***Get  users
  SELECT * FROM /psyng/mcuser INTO TABLE lt_user
    WHERE vrsio = sodvrsio AND
       userid   IN userid  AND
       contid   IN  contid AND
       conid    IN   conid AND
    auditor     IN   auditor AND
     to_date    IN lr_date.



  LOOP AT lt_user INTO ls_user.
    MOVE-CORRESPONDING ls_user TO ls_expired_mit.
    ls_expired_mit-type = '1'.
    APPEND ls_expired_mit TO et_expired_mit.
  ENDLOOP.


****Get Critical Auth users

  SELECT * FROM /psyng/mccauser INTO TABLE lt_causer
      WHERE vrsio = sodvrsio AND
         userid   IN userid  AND
         contid   IN  contid AND
         swaudid    IN  swaudid AND
      auditor     IN   auditor AND
       to_date    IN lr_date.



  LOOP AT lt_causer INTO ls_causer.
    MOVE-CORRESPONDING ls_user TO ls_expired_mit.
    ls_expired_mit-type = '3'.
    APPEND ls_expired_mit TO et_expired_mit.
  ENDLOOP.

***Get usergroup

  SELECT * FROM /psyng/mcusrgrp INTO TABLE lt_usergrp
     WHERE vrsio = sodvrsio AND
        class IN s_class AND
        contid   IN  contid AND
        conid    IN   conid AND
        auditor     IN   auditor AND
         to_date    IN lr_date.


  LOOP AT lt_usergrp INTO ls_usergrp.
    MOVE-CORRESPONDING ls_usergrp TO ls_expired_mit.
    ls_expired_mit-type = '2'.
    APPEND ls_expired_mit TO et_expired_mit.
  ENDLOOP.

***Get  role

  SELECT * FROM /psyng/mcrole INTO TABLE lt_role
  WHERE vrsio = sodvrsio AND
     contid   IN  contid AND
    conid    IN   conid AND
  auditor     IN   auditor AND
   to_date    IN lr_date.



  LOOP AT lt_role INTO ls_role.
    MOVE-CORRESPONDING ls_role TO ls_expired_mit.
    ls_expired_mit-type = '4'.
    APPEND ls_expired_mit TO et_expired_mit.
  ENDLOOP.

***Get Critical Auth role

  SELECT * FROM /psyng/mccarole INTO TABLE lt_carole
  WHERE vrsio = sodvrsio AND
     contid   IN  contid AND
     swaudid    IN  swaudid AND
  auditor     IN   auditor AND
   to_date    IN lr_date.



  LOOP AT lt_carole INTO ls_carole.
    MOVE-CORRESPONDING ls_carole TO ls_expired_mit.
    ls_expired_mit-type = '5'.
    APPEND ls_expired_mit TO et_expired_mit.
  ENDLOOP.



ENDFORM.
