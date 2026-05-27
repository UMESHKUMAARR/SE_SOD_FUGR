*----------------------------------------------------------------------*
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*//
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_145 MESSAGE-ID /psyng/sw NO STANDARD PAGE HEADING.
INCLUDE /psyng/sw_config.
TYPE-POOLS : shlp, slis, icon.
CONSTANTS: gc_application_area TYPE char10 VALUE 'BUSAREA',
           gc_process_area     TYPE char10 VALUE 'SUBAREA',
           gc_risk             TYPE char10 VALUE 'RISK',
           gc_sys_type         TYPE char10 VALUE 'SYS_TYPE',
           gc_sys_cat          TYPE char10 VALUE 'SYS_CAT'.
TABLES: /psyng/function,     "SW: Function Definition
        /psyng/conflict,     "SW: Conflict Header
        /psyng/critcodes,    "SW: Critical Tcodes
        /psyng/swaudhdr,     "SW: Critical Auths Header
        /psyng/criroles,     "SW: Critical Roles
        /psyng/criprof,      "SW: Critical Profiles
        /psyng/sw_cuscon,    "SW: Custom Conflicts
        /psyng/swconfig,     "SW: Config Params
        /psyng/sw_excltx,    "SW: Calling tcode For dyn. SOD Matrix enh.
        /psyng/sw_excdtx,    "SW: Called Tcodes exc from SOD Matrix enh.
        rfcdes,
        /psyng/swcfgoe,      "SE: Configuration Set - Org Element Values
        /psyng/sw_varel,     "SW: Variable Element Rules
*        /psyng/sw_freq,      "SW: Frequencies
*        /psyng/sw_freqt,     "SW: Frequency Texts
        /psyng/busarea,      "SW: Application Areas
        /psyng/bus_proce,    "SW: Business process
*        /psyng/sw_prj01,     "SW: Project
*        /psyng/sw_sta01,     "SW: Status
*        /psyng/swsodorgm,    "SW: Org levels
        /psyng/sw_risk,      "SW: Risk Scenario
        /psyng/sw_systyp,
        /psyng/sw_syscat,
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
        /psyng/mcuser,
        /psyng/mcusrgrp,
        /psyng/mccauser,
        /psyng/mccarole,
        /psyng/mcrole.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
*        /psyng/sw_mctype,    "SW: Mitigation type
*        /psyng/mcrvwhdr,
*        /psyng/sw_sysfun.    "SW: Function System Filters

*--Type for F4 help
TYPES: BEGIN OF ty_values,
         line(255) TYPE c,
       END OF   ty_values,
*--Type for display output of messages encountered
       BEGIN OF ty_log,
         config_type TYPE char30,
         source      TYPE rfcdes-rfcdest,
         target      TYPE rfcdes-rfcdest,
         type_icon   TYPE icon-id.
         INCLUDE STRUCTURE bapiret2.
       TYPES: END OF ty_log.

DATA :
  g_ucomm    TYPE sy-ucomm,
  g_field    TYPE char15,
  gt_confdet TYPE TABLE OF /psyng/confdet,
  gs_confdet TYPE /psyng/confdet,
  g_svrsio   TYPE /psyng/swsodvers-vrsio,
  g_tvrsio   TYPE /psyng/swsodvers-vrsio.

DATA: gt_function      TYPE TABLE OF /psyng/function WITH HEADER LINE,
      gt_functtran     TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
      gt_faobj         TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
      gt_conflict      TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
      gt_critcodes     TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
      gt_swaudhdr      TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
      gt_swaudc        TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
      gt_criroles      TYPE TABLE OF /psyng/criroles WITH HEADER LINE,
      gt_criprof       TYPE TABLE OF /psyng/criprof WITH HEADER LINE,
      gt_texts         TYPE TABLE OF /psyng/texts WITH HEADER LINE,
      gt_cuscon        TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
      gt_conowner      TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
      gs_swsodvers     TYPE /psyng/swsodvers,
      g_program        TYPE sy-repid,
      gt_confil        TYPE TABLE OF /psyng/sw_syscon,
      gt_funfil        TYPE TABLE OF /psyng/sw_sysfun,
      gt_tcodefil      TYPE TABLE OF /psyng/sw_systcd,
      gt_authfil       TYPE TABLE OF /psyng/sw_sysca,
      gt_swsodorgo     TYPE TABLE OF /psyng/swsodorgo,
      gt_log           TYPE TABLE OF ty_log,
      g_append_flag    TYPE c,
      g_overwrite_flag TYPE c,
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      gs_mit_text      TYPE /psyng/mc_usertext_tt,
      gt_mchdr         TYPE TABLE OF /psyng/mchdr    WITH HEADER LINE,
      gt_mcrvwhdr      TYPE TABLE OF /psyng/mcrvwhdr WITH HEADER LINE,
      gt_mcuser        TYPE TABLE OF /psyng/mcuser   WITH HEADER LINE,
      gt_mctext        TYPE TABLE OF /psyng/mcrvwtxt WITH HEADER LINE,
      gt_mcusrgrp      TYPE TABLE OF /psyng/mcusrgrp WITH HEADER LINE,
      gt_mcrole        TYPE TABLE OF /psyng/mcrole   WITH HEADER LINE,
      gt_mccarole      TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
      gt_mccauser      TYPE TABLE OF /psyng/mccauser WITH HEADER LINE,
      gt_mctran        TYPE TABLE OF /psyng/mctran   WITH HEADER LINE,
      gt_mcrepid       TYPE TABLE OF /psyng/mcrepid  WITH HEADER LINE,
      gt_mcauditor     TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
DATA: gt_config         TYPE TABLE OF /psyng/se_config_param,
      gt_ve_rule_ver    TYPE TABLE OF /psyng/sw_varvr,
      gt_ve_rules       TYPE TABLE OF /psyng/sw_varel,
      gt_calling_tcodes TYPE TABLE OF /psyng/sw_excltx,
      gt_called_tcodes  TYPE TABLE OF /psyng/sw_excdtx,
      gt_config_header  TYPE TABLE OF /psyng/swcfgset,
      gt_varel          TYPE TABLE OF /psyng/swcfgve,
      gt_systems        TYPE TABLE OF /psyng/swcfgsys,
      gt_org            TYPE TABLE OF /psyng/swcfgoe,
      gt_elements       TYPE TABLE OF /psyng/swcfsel,
      gt_busarea        TYPE TABLE OF /psyng/busarea,
      gt_subarea        TYPE TABLE OF /psyng/bus_proce,
      gt_risk           TYPE TABLE OF /psyng/sw_risk,
      gt_sys_type       TYPE TABLE OF /psyng/sw_systyp,
      gt_sys_cat        TYPE TABLE OF /psyng/sw_syscat.

INITIALIZATION.
  g_program = sy-repid.

  SELECTION-SCREEN BEGIN OF BLOCK header WITH FRAME.
*--Block remote system
  SELECTION-SCREEN BEGIN OF BLOCK remsys WITH FRAME TITLE text-t15.
  SELECTION-SCREEN BEGIN OF LINE.
  PARAMETERS: p_pull RADIOBUTTON GROUP g1 USER-COMMAND radi DEFAULT 'X'.
  SELECTION-SCREEN COMMENT 3(38) text-r01.
  PARAMETERS: p_push RADIOBUTTON GROUP g1.
  SELECTION-SCREEN COMMENT 44(38) text-r02.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(14) text-p01 MODIF ID par.
  PARAMETER p_rfcdst LIKE rfcdes-rfcdest MATCHCODE OBJECT
   /psyng/sw_rfcsh_coll MODIF ID par.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN BEGIN OF LINE.
  SELECTION-SCREEN COMMENT 1(14) text-p01 MODIF ID sel.
  SELECT-OPTIONS: s_rfcdst FOR rfcdes-rfcdest MATCHCODE OBJECT
   /psyng/sw_rfcsh_coll NO INTERVALS MODIF ID sel.
  SELECTION-SCREEN END OF LINE.
  SELECTION-SCREEN END OF BLOCK remsys.
*--Block delete target object before save
  SELECTION-SCREEN BEGIN OF BLOCK overwr WITH FRAME TITLE text-t16.
  SELECTION-SCREEN BEGIN OF LINE.
  PARAMETERS: p_deltar AS CHECKBOX USER-COMMAND exp.
  SELECTION-SCREEN COMMENT 4(35) text-r03 FOR FIELD p_deltar.
  SELECTION-SCREEN END OF LINE.

  SELECTION-SCREEN END OF BLOCK overwr.
  PARAMETERS: p_test AS CHECKBOX DEFAULT 'X'.
  SELECTION-SCREEN END OF BLOCK header.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  SELECTION-SCREEN BEGIN OF BLOCK append WITH FRAME TITLE text-t29.
  SELECTION-SCREEN: BEGIN OF LINE.
  PARAMETERS: p_ins RADIOBUTTON GROUP i USER-COMMAND ins MODIF ID wtr.
  SELECTION-SCREEN COMMENT 3(60) p_cmi MODIF ID wtr FOR FIELD p_ins.
  SELECTION-SCREEN: END OF LINE.
  SELECTION-SCREEN: BEGIN OF LINE.
  PARAMETERS: p_fowrt RADIOBUTTON GROUP i MODIF ID wtr.
  SELECTION-SCREEN COMMENT 3(60) p_cmo MODIF ID wtr FOR FIELD p_fowrt.
  SELECTION-SCREEN: END OF LINE.
  SELECTION-SCREEN END OF BLOCK append.

  SELECTION-SCREEN BEGIN OF BLOCK version WITH FRAME TITLE text-t10.
  PARAMETERS: p_vrsio TYPE char3 MEMORY ID /psyng/vrsio MODIF ID vrs.
  SELECTION-SCREEN END OF BLOCK version.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion



  SELECTION-SCREEN COMMENT 1(60) text-c00.

*-- Matrix Block
  SELECTION-SCREEN BEGIN OF BLOCK matrix WITH FRAME TITLE text-t17.
  PARAMETERS: p_matrix AS CHECKBOX USER-COMMAND mat.

*--Block conflict repository
  SELECTION-SCREEN BEGIN OF BLOCK conrep WITH FRAME TITLE text-t01.
  PARAMETERS: p_tvhead AS CHECKBOX MODIF ID dis.

  SELECTION-SCREEN BEGIN OF BLOCK function WITH FRAME TITLE text-t02.
  PARAMETERS: p_tfunct AS CHECKBOX USER-COMMAND ufunc MODIF ID dis.
  SELECT-OPTIONS: s_funct FOR /psyng/function-function.
  PARAMETER p_fnfltr AS CHECKBOX.
  SELECTION-SCREEN END OF BLOCK function.

  SELECTION-SCREEN BEGIN OF BLOCK conflict WITH FRAME TITLE text-t03.
  PARAMETERS: p_tconid AS CHECKBOX USER-COMMAND ucon MODIF ID dis.
  SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid.
  PARAMETERS: p_confun AS CHECKBOX USER-COMMAND ucf.
  PARAMETER p_cnfltr AS CHECKBOX.
  PARAMETER p_torgo AS CHECKBOX.
  PARAMETERS: p_tcscon AS CHECKBOX USER-COMMAND uccon MODIF ID dis.
  SELECT-OPTIONS: s_cuscon FOR /psyng/sw_cuscon-conid.
  SELECTION-SCREEN END OF BLOCK conflict.

  SELECTION-SCREEN BEGIN OF BLOCK crittran WITH FRAME TITLE text-t06.
  PARAMETERS: p_ttcode AS CHECKBOX USER-COMMAND uctcode MODIF ID dis.
  SELECT-OPTIONS: s_tcode FOR /psyng/critcodes-tcode.
  PARAMETER p_ctfltr AS CHECKBOX.
  SELECTION-SCREEN END OF BLOCK crittran.

  SELECTION-SCREEN BEGIN OF BLOCK critauth WITH FRAME TITLE text-t07.
  PARAMETERS: p_taudid AS CHECKBOX USER-COMMAND ucauth MODIF ID dis.
  SELECT-OPTIONS: s_audid FOR /psyng/swaudhdr-swaudid.
  PARAMETER p_cafltr AS CHECKBOX.
  SELECTION-SCREEN END OF BLOCK critauth.

  SELECTION-SCREEN BEGIN OF BLOCK critrole WITH FRAME TITLE text-t08.
  PARAMETERS: p_tagrnm AS CHECKBOX USER-COMMAND ucrole MODIF ID dis.
  SELECT-OPTIONS: s_agrnam FOR /psyng/criroles-agr_name.
  SELECTION-SCREEN END OF BLOCK critrole.

  SELECTION-SCREEN BEGIN OF BLOCK critprof WITH FRAME TITLE text-t09.
  PARAMETERS: p_tprof AS CHECKBOX USER-COMMAND ucprof MODIF ID dis.
  SELECT-OPTIONS: s_prof FOR /psyng/criprof-profile.
  SELECTION-SCREEN END OF BLOCK critprof.
  SELECTION-SCREEN END OF BLOCK conrep.
*  SELECTION-SCREEN BEGIN OF BLOCK mitigation WITH FRAME TITLE text-t18.
*  PARAMETERS: p_del_mt AS CHECKBOX USER-COMMAND mdel MODIF ID dis.
*  SELECTION-SCREEN END OF BLOCK mitigation.
  SELECTION-SCREEN END OF BLOCK matrix.


*BOC UMITTAL PN-5186 : Control Mitigation Deletion
  SELECTION-SCREEN BEGIN OF BLOCK mitigation WITH FRAME TITLE text-t27.
  PARAMETERS : p_miti AS CHECKBOX USER-COMMAND miti MODIF ID tcr .
  SELECT-OPTIONS: s_mitid FOR /psyng/mcuser-contid MODIF ID mcr.

  SELECTION-SCREEN BEGIN OF BLOCK mitictrlusr WITH FRAME TITLE text-t22.
  PARAMETERS: p_mitusr AS CHECKBOX USER-COMMAND ctrlusr MODIF ID mcr.
*  SELECT-OPTIONS: s_mitid1 FOR /PSYNG/MCUSER-CONTID . "MODIF ID MCR.
  SELECT-OPTIONS: s_con1 FOR /psyng/mcuser-conid. . "MODIF ID MCR.
  SELECT-OPTIONS: s_usrid1 FOR /psyng/mcuser-userid ."MODIF ID MCR.
  SELECTION-SCREEN END OF BLOCK mitictrlusr .


  SELECTION-SCREEN BEGIN OF BLOCK mitictrlusrgrp WITH FRAME TITLE
  text-t23.
  PARAMETERS: p_usrgrp AS CHECKBOX USER-COMMAND ctrlusrgrp MODIF ID mcr.
*  SELECT-OPTIONS: s_mitid2 FOR /PSYNG/MCUSRGRP-CONTID." MODIF ID MCD.
  SELECT-OPTIONS: s_con2 FOR /psyng/mcusrgrp-conid. ."MODIF ID MCD.
  SELECT-OPTIONS: s_usrgrp FOR /psyng/mcusrgrp-class ." MODIF ID MCD.
  SELECTION-SCREEN END OF BLOCK mitictrlusrgrp .

  SELECTION-SCREEN BEGIN OF BLOCK mitictrlassrol WITH FRAME TITLE
  text-t26.
  PARAMETERS: p_assrol AS CHECKBOX USER-COMMAND ctrlassrol MODIF ID mcr.
*  SELECT-OPTIONS: s_mitid5 FOR /PSYNG/MCROLE-CONTID ." MODIF ID MCD.
  SELECT-OPTIONS: s_con3 FOR /psyng/mcrole-conid."MODIF ID MCD.
  SELECT-OPTIONS: s_rl_nm1 FOR /psyng/mcrole-agr_name."  MODIF ID MCD.
  SELECTION-SCREEN END OF BLOCK mitictrlassrol .


  SELECTION-SCREEN BEGIN OF BLOCK miticriauthusr WITH FRAME TITLE
  text-t24.
  PARAMETERS: p_autusr AS CHECKBOX USER-COMMAND criauthusr MODIF ID mcr.
*  SELECT-OPTIONS: s_mitid3 FOR /PSYNG/MCCAUSER-CONTID."  MODIF ID MCD.
  SELECT-OPTIONS: s_wadid1 FOR /psyng/mccauser-swaudid ."MODIF ID MCD.
  SELECT-OPTIONS: s_usrid2 FOR /psyng/mccauser-userid ." MODIF ID MCD.
  SELECTION-SCREEN END OF BLOCK miticriauthusr .


  SELECTION-SCREEN BEGIN OF BLOCK miticriauthrol WITH FRAME TITLE
  text-t25.
  PARAMETERS: p_autrol AS CHECKBOX USER-COMMAND criauthrol MODIF ID mcr.
*  SELECT-OPTIONS: s_mitid4 FOR /PSYNG/MCCAROLE-CONTID  ."MODIF ID MCD.
  SELECT-OPTIONS: s_wadid2 FOR /psyng/mccarole-swaudid ."MODIF ID MCD.
  SELECT-OPTIONS: s_rl_nm FOR /psyng/mccarole-agr_name ." MODIF ID MCD.
  SELECTION-SCREEN END OF BLOCK miticriauthrol .
  SELECTION-SCREEN END OF BLOCK mitigation.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
*--Block configuration
  SELECTION-SCREEN BEGIN OF BLOCK config WITH FRAME TITLE text-t11.
  PARAMETERS: p_tconfg AS CHECKBOX USER-COMMAND uconfig.
  SELECT-OPTIONS s_confg FOR /psyng/swconfig-param.

*PARAMETER p_tproj  AS CHECKBOX USER-COMMAND uproj MODIF ID hid.
*SELECT-OPTIONS s_tproj FOR /psyng/sw_prj01-project MODIF ID hid.
*
*PARAMETER p_tstat  AS CHECKBOX USER-COMMAND ustat MODIF ID hid.
*SELECT-OPTIONS s_tstat FOR /psyng/sw_sta01-status MODIF ID hid.
*
*PARAMETER p_torglv AS CHECKBOX USER-COMMAND uorg.
*SELECT-OPTIONS s_torgla FOR /psyng/swsodorgm-abb.
*SELECT-OPTIONS s_torglo FOR /psyng/swsodorgm-object.
*SELECT-OPTIONS s_torglv FOR /psyng/swsodorgm-varbl.
*
*PARAMETER p_trisk  AS CHECKBOX USER-COMMAND urisk.
*SELECT-OPTIONS s_trisk FOR /psyng/sw_risk-risk.
*
*PARAMETER p_tmityp AS CHECKBOX USER-COMMAND umityp.
*SELECT-OPTIONS s_tmityp FOR /psyng/sw_mctype-type.
*
*PARAMETER p_tfreq  AS CHECKBOX USER-COMMAND ufreq.
*SELECT-OPTIONS s_tfreq FOR /psyng/sw_freq-freq.

  PARAMETER p_velemt  AS CHECKBOX USER-COMMAND uelemt.
  SELECTION-SCREEN BEGIN OF BLOCK ve WITH FRAME.
  PARAMETER : p_ve_hdr TYPE flag.
  SELECT-OPTIONS s_vevrs FOR /psyng/sw_varel-varel_vrsio.
  SELECT-OPTIONS s_velemt  FOR /psyng/sw_varel-var_element.
  SELECTION-SCREEN END OF BLOCK ve.
  PARAMETER p_dynam  AS CHECKBOX USER-COMMAND dynam.
  SELECT-OPTIONS: s_ctcode FOR /psyng/sw_excltx-low,
                 s_ctcod1 FOR /psyng/sw_excdtx-called_tcode.

  PARAMETER p_cnfset  AS CHECKBOX USER-COMMAND cnfset.
  SELECT-OPTIONS: s_setid FOR /psyng/swcfgoe-setid.

  PARAMETERS :p_tapar  AS CHECKBOX USER-COMMAND uarea.
  SELECT-OPTIONS : s_tapar FOR /psyng/busarea-busarea.

  PARAMETER   p_tprocr AS CHECKBOX USER-COMMAND ubpro.
  SELECT-OPTIONS s_tprocr FOR /psyng/bus_proce-subarea.

  PARAMETER   p_tsyst AS CHECKBOX USER-COMMAND usyst.
  SELECT-OPTIONS s_tsyst FOR /psyng/sw_systyp-sys_type.

  PARAMETER   p_tsysc AS CHECKBOX USER-COMMAND usysc.
  SELECT-OPTIONS s_tsysc FOR /psyng/sw_syscat-sys_category.

  PARAMETER p_trisk  AS CHECKBOX USER-COMMAND urisk.
  SELECT-OPTIONS s_trisk FOR /psyng/sw_risk-risk.

  SELECTION-SCREEN END OF BLOCK config.


*--------------------- AT SELECTION-SCREEN OUTPUT ---------------------*
AT SELECTION-SCREEN OUTPUT.
  PERFORM at_selection_screen_output.

*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_vrsio.
  PERFORM f4_vrsio CHANGING p_vrsio.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_funct-low.
  PERFORM f4_function CHANGING s_funct-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_funct-high.
  PERFORM f4_function CHANGING s_funct-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_conid-low.
  PERFORM f4_conflicts CHANGING s_conid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_conid-high.
  PERFORM f4_conflicts CHANGING s_conid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_audid-low.
  PERFORM f4_crit_auth CHANGING s_audid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_audid-high.
  PERFORM f4_crit_auth CHANGING s_audid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuscon-low.
  PERFORM f4_cuscon CHANGING s_cuscon-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuscon-high.
  PERFORM f4_cuscon CHANGING s_cuscon-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-low.
  PERFORM f4_ctcode CHANGING s_tcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tcode-high.
  PERFORM f4_ctcode CHANGING s_tcode-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agrnam-low.
  PERFORM f4_ctrole CHANGING s_agrnam-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_agrnam-high.
  PERFORM f4_ctrole CHANGING s_agrnam-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_prof-low.
  PERFORM f4_ctprof CHANGING s_prof-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_prof-high.
  PERFORM f4_ctprof CHANGING s_prof-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_confg-low.
  PERFORM f4_config CHANGING s_confg-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_confg-high.
  PERFORM f4_config CHANGING s_confg-high.

**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tstat-low.
**  PERFORM f4_status CHANGING s_tstat-low.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tstat-high.
**  PERFORM f4_status CHANGING s_tstat-high.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglo-low.
**  PERFORM f4_orglvlo CHANGING s_torglo-low.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglo-high.
**  PERFORM f4_orglvlo CHANGING s_torglo-high.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglv-low.
**  PERFORM f4_orglvl CHANGING s_torglv-low.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_torglv-high.
**  PERFORM f4_orglvl CHANGING s_torglv-high.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tfreq-low.
**  PERFORM f4_frequency CHANGING s_tfreq-low.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tfreq-high.
**  PERFORM f4_frequency CHANGING s_tfreq-high.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tproj-low.
**  PERFORM f4_project CHANGING s_tproj-low.
**
**AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tproj-high.
**  PERFORM f4_project CHANGING s_tproj-high.
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_vevrs-low.
  PERFORM f4_rule_versions CHANGING s_vevrs-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_vevrs-high.
  PERFORM f4_rule_versions CHANGING s_vevrs-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_velemt-low.
  PERFORM f4_elements CHANGING s_velemt-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_velemt-high.
  PERFORM f4_elements CHANGING s_velemt-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcod1-low.
  PERFORM f4_called_tcode CHANGING s_ctcod1-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcod1-high.
  PERFORM f4_called_tcode CHANGING s_ctcod1-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcode-low.
  PERFORM f4_calling_tcode CHANGING s_ctcode-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_ctcode-high.
  PERFORM f4_calling_tcode CHANGING s_ctcode-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_setid-low.
  PERFORM f4_setid CHANGING s_setid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_setid-high.
  PERFORM f4_setid CHANGING s_setid-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tapar-low.
  PERFORM f4_app_area CHANGING s_tapar-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tapar-high.
  PERFORM f4_app_area CHANGING s_tapar-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tprocr-low.
  PERFORM f4_bus_proc CHANGING s_tprocr-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tprocr-high.
  PERFORM f4_bus_proc CHANGING s_tprocr-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tsyst-low.
  PERFORM f4_sys_type CHANGING s_tsyst-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tsyst-high.
  PERFORM f4_sys_type CHANGING s_tsyst-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tsysc-low.
  PERFORM f4_sys_cat CHANGING s_tsysc-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_tsysc-high.
  PERFORM f4_sys_cat CHANGING s_tsysc-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_trisk-low.
  PERFORM f4_risk CHANGING s_trisk-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_trisk-high.
  PERFORM f4_risk CHANGING s_trisk-high.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
*  PERFORM validate_sod_version.
  PERFORM at_selection_screen.

*------------------------- START-OF-SELECTION -------------------------*
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
*  upon Execution, when the "include relevant functions" checkbox is
*  on, we should gather all function ID at that point in case Conflict
*  IDs changed.
  IF  p_matrix EQ 'X'
  AND p_confun EQ 'X'.
    PERFORM get_relevant_funcs.
  ENDIF.
*--Transfer configuration
  PERFORM transfer_configuration.
*--Display log of messages
  PERFORM display_output.


*&---------------------------------------------------------------------*
*&      Form  f4_cuscon
*&---------------------------------------------------------------------*
*       F4 help for Custom Conflict ID
*----------------------------------------------------------------------*
*      <--E_CUSCON  Custom Conflict ID
*----------------------------------------------------------------------*
FORM f4_cuscon CHANGING e_conid TYPE /psyng/sw_cuscon-conid.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_cuscon TYPE TABLE OF /psyng/sw_cuscon,
        ls_cuscon TYPE /psyng/sw_cuscon.


  ls_fields-tabname   = '/PSYNG/SW_CUSCON'.
  ls_fields-fieldname = 'CONID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'CDESC'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'FUNCT'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        i_vrsio    = p_vrsio
        if_cus_con = 'X'
      TABLES
        et_cus_con = lt_cuscon.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_cuscon
      FROM /psyng/sw_cuscon WHERE vrsio = p_vrsio.
  ENDIF.
  LOOP AT lt_cuscon INTO ls_cuscon.
    ls_values-line = ls_cuscon-conid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cuscon-cdesc.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cuscon-funct.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cuscon-busarea.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONID'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_conid = ls_return-fieldval.
ENDFORM.                                                    " f4_conid

**** F4 help for critical tcodes

FORM f4_ctcode CHANGING e_tcode TYPE /psyng/critcodes-tcode.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF help_value,
        ls_fields TYPE help_value,
        lt_ctcode TYPE TABLE OF /psyng/cri_tcodes_f4,
        ls_ctcode TYPE /psyng/cri_tcodes_f4.

  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        i_vrsio       = p_vrsio
        if_crit_tcode = 'X'
      TABLES
        et_crit_tcode = lt_ctcode.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT a~tcode
           a~vrsio
           a~owner
           a~imp
           b~ttext INTO TABLE lt_ctcode
           FROM /psyng/critcodes AS a INNER JOIN tstct AS b
           ON a~tcode EQ b~tcode
           WHERE vrsio = p_vrsio.
  ENDIF.

  ls_fields-tabname    = '/PSYNG/CRITCODES'.
  ls_fields-fieldname  = 'TCODE'.
  ls_fields-selectflag = 'X'.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname    = 'TSTCT'.
  ls_fields-fieldname  = 'TTEXT'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname    = '/PSYNG/CRITCODES'.
  ls_fields-fieldname  = 'VRSIO'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname  = 'IMP'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname  = 'OWNER'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  LOOP AT lt_ctcode INTO ls_ctcode.
    ls_values-line = ls_ctcode-tcode.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_ctcode-ttext.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_ctcode-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_ctcode-imp.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_ctcode-owner.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t14
    IMPORTING
      select_value              = e_tcode
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

ENDFORM.                                                    " f4_conid


**** F4 help for critical roles

FORM f4_ctrole CHANGING e_role TYPE /psyng/criroles-agr_name.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF help_value,
        ls_fields TYPE help_value,
        lt_crole  TYPE TABLE OF /psyng/cri_roles_f4,
        ls_crole  TYPE /psyng/cri_roles_f4.

  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        i_vrsio      = p_vrsio
        if_crit_role = 'X'
      TABLES
        et_crit_role = lt_crole.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT a~agr_name
           a~vrsio
           a~owner
           a~imp
           b~text INTO TABLE lt_crole
           FROM /psyng/criroles AS a INNER JOIN agr_texts AS b
           ON a~agr_name EQ b~agr_name
           WHERE vrsio = p_vrsio
             AND line EQ space.
  ENDIF.

  REFRESH: lt_fields, lt_values.
  ls_fields-tabname   = '/PSYNG/CRIROLES'.
  ls_fields-fieldname = 'AGR_NAME'.
  ls_fields-selectflag = 'X'.
  APPEND ls_fields TO lt_fields.
  ls_fields-tabname   = 'AGR_TEXTS'.
  ls_fields-fieldname = 'TEXT'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = '/PSYNG/CRIROLES'.
  ls_fields-fieldname = 'VRSIO'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'IMP'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'OWNER'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  LOOP AT lt_crole INTO ls_crole.
    ls_values-line = ls_crole-agr_name.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_crole-text.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_crole-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_crole-imp.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_crole-owner.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t13
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

ENDFORM.                                                    " f4_conid


**** F4 help for critical profile

FORM f4_ctprof CHANGING e_prof TYPE /psyng/criprof-profile.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF help_value,
        ls_fields TYPE help_value,
        lt_cprof  TYPE TABLE OF /psyng/cri_prof_f4,
        ls_cprof  TYPE /psyng/cri_prof_f4.

  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        i_vrsio      = p_vrsio
        if_crit_prof = 'X'
      TABLES
        et_crit_prof = lt_cprof.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT a~profile
           a~vrsio
           a~owner
           a~imp
           b~ptext INTO TABLE lt_cprof
           FROM /psyng/criprof AS a INNER JOIN usr11 AS b
           ON a~profile EQ b~profn
           WHERE vrsio = p_vrsio.
  ENDIF.

  REFRESH: lt_fields, lt_values.
  ls_fields-tabname   = '/PSYNG/CRIPROF'.
  ls_fields-fieldname = 'PROFILE'.
  ls_fields-selectflag = 'X'.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = 'USR11'.
  ls_fields-fieldname = 'PTEXT'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = '/PSYNG/CRIPROF'.
  ls_fields-fieldname = 'VRSIO'.
  ls_fields-selectflag = ''.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'IMP'.
  ls_fields-selectflag = ''.
  APPEND ls_fields TO lt_fields.

  ls_fields-fieldname = 'OWNER'.
  ls_fields-selectflag = ' '.
  APPEND ls_fields TO lt_fields.

  LOOP AT lt_cprof INTO ls_cprof.
    ls_values-line = ls_cprof-profile.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cprof-ptext.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cprof-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cprof-imp.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_cprof-owner.
    APPEND ls_values TO lt_values.

  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
    EXPORTING
      titel                     = text-t12
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

ENDFORM.                                                    " f4_conid

*&---------------------------------------------------------------------*
*&      Form  f4_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_PROF_LOW  text
*----------------------------------------------------------------------*
FORM f4_config CHANGING e_config TYPE /psyng/swconfig-param.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_config TYPE TABLE OF /psyng/swconfig,
        ls_config TYPE /psyng/swconfig.

  ls_fields-tabname   = '/PSYNG/SWCONFIG'.
  ls_fields-fieldname = 'PARAM'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VALUE'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_config = 'X'
      TABLES
        et_config = lt_config.                   "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_config
      FROM /psyng/swconfig ORDER BY param.
  ENDIF.

  LOOP AT lt_config INTO ls_config.
    ls_values-line = ls_config-param.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_config-value.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'PARAM'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_config = ls_return-fieldval.

ENDFORM.                                                    " f4_config
***&--------------------------------------------------------------------
*-
***
***&      Form  f4_status
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***      <--P_S_TSTAT_LOW  text
***---------------------------------------------------------------------
*-
***
**FORM f4_status CHANGING e_stat TYPE /psyng/sw_sta01-status .
**  DATA: BEGIN OF lt_values OCCURS 0,
**              line(255) TYPE c,
**            END OF lt_values.
**
**  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
**        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
**        ls_status TYPE /psyng/sw_sta01.
**
**
**  ls_fields-tabname   = '/PSYNG/SW_STA01'.
**  ls_fields-fieldname = 'STATUS'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'TEXT'.
**  APPEND ls_fields TO lt_fields.
**
*** Get values for popup
**  SELECT * INTO ls_status FROM /psyng/sw_sta01 ORDER BY status.
**
**    ls_values-line = ls_status-status.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_status-text.
**    APPEND ls_values TO lt_values.
**  ENDSELECT.
**
**
**  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
**       EXPORTING
**            retfield        = 'STATUS'
**       TABLES
**            value_tab       = lt_values
**            field_tab       = lt_fields
**            return_tab      = lt_return
**       EXCEPTIONS
**            parameter_error = 1
**            no_values_found = 2
**            OTHERS          = 3.
**  IF sy-subrc <> 0.
**    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**  ENDIF.
**
**  READ TABLE lt_return INTO ls_return INDEX 1.
**  e_stat = lt_return-fieldval.
**
**ENDFORM.                                                    "
*f4_status
***&--------------------------------------------------------------------
*-
***
***&      Form  f4_orglvl
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***      <--P_S_TORGLV_HIGH  text
***---------------------------------------------------------------------
*-
***
**FORM f4_orglvl CHANGING e_org TYPE /psyng/swsodorgm-varbl.
**  DATA: BEGIN OF lt_values OCCURS 0,
**              line(255) TYPE c,
**            END OF lt_values.
**
**  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
**        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
**        ls_orglvl TYPE /psyng/swsodorgm.
**
**
**  ls_fields-tabname   = '/PSYNG/SWSODORGM'.
**  ls_fields-fieldname = 'ABB'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'OBJECT'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'VARBL'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'LOW'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'HIGH'.
**  APPEND ls_fields TO lt_fields.
**
*** Get values for popup
**  SELECT * INTO ls_orglvl FROM /psyng/swsodorgm ORDER BY abb.
**
**    ls_values-line = ls_orglvl-abb.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-object.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-varbl.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-low.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-high.
**    APPEND ls_values TO lt_values.
**  ENDSELECT.
**
**
**  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
**       EXPORTING
**            retfield        = 'VARBL'
**       TABLES
**            value_tab       = lt_values
**            field_tab       = lt_fields
**            return_tab      = lt_return
**       EXCEPTIONS
**            parameter_error = 1
**            no_values_found = 2
**            OTHERS          = 3.
**  IF sy-subrc <> 0.
**    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**  ENDIF.
**
**  READ TABLE lt_return INTO ls_return INDEX 1.
**  e_org = lt_return-fieldval.
**
**ENDFORM.                                                    "
*f4_orglvl
***&--------------------------------------------------------------------
*-
***
***&      Form  f4_frequency
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***      <--P_S_TFREQ_LOW  text
***---------------------------------------------------------------------
*-
***
**FORM f4_frequency CHANGING e_freq TYPE /psyng/sw_freq-freq .
**  DATA: BEGIN OF lt_values OCCURS 0,
**              line(255) TYPE c,
**            END OF lt_values.
**
**  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
**        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
**        lt_freq TYPE TABLE OF /psyng/sw_freq WITH HEADER LINE,
**        lt_ftext TYPE TABLE OF /psyng/sw_freqt WITH HEADER LINE.
**
**
**  ls_fields-tabname   = '/PSYNG/SW_FREQ'.
**  ls_fields-fieldname = 'FREQ'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'NUMDAYS'.
**  APPEND ls_fields TO lt_fields.
**
**  ls_fields-tabname   = '/PSYNG/SW_FREQT'.
**  ls_fields-fieldname = 'TEXT'.
**  APPEND ls_fields TO lt_fields.
**
*** Get values for popup
**  SELECT * INTO TABLE lt_freq FROM /psyng/sw_freq
**  WHERE freq IS not NULL.
**
**  SELECT * INTO TABLE lt_ftext FROM /psyng/sw_freqt
**  FOR ALL ENTRIES IN lt_freq WHERE freq = lt_freq-freq.
**
**  SORT lt_freq BY freq.
**
**  LOOP AT lt_freq.
**    ls_values-line = lt_freq-freq.
**    APPEND ls_values TO lt_values.
**    ls_values-line = lt_freq-numdays.
**    APPEND ls_values TO lt_values.
**    READ TABLE lt_ftext WITH KEY freq = lt_freq-freq. "lang = sy-langu
*.
**    IF sy-subrc = 0.
**      ls_values-line = lt_ftext-text.
**      APPEND ls_values TO lt_values.
**    ELSE.
**      ls_values-line = ''.
**      APPEND ls_values TO lt_values.
**    ENDIF.
**  ENDLOOP.
**
**
**  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
**       EXPORTING
**            retfield        = 'FREQ'
**       TABLES
**            value_tab       = lt_values
**            field_tab       = lt_fields
**            return_tab      = lt_return
**       EXCEPTIONS
**            parameter_error = 1
**            no_values_found = 2
**            OTHERS          = 3.
**  IF sy-subrc <> 0.
**    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**  ENDIF.
**
**  READ TABLE lt_return INTO ls_return INDEX 1.
**  e_freq = lt_return-fieldval.
**
**ENDFORM.                    " f4_frequency
***&--------------------------------------------------------------------
*-
***
***&      Form  f4_orglvlo
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***      <--P_S_TORGLV_LOW  text
***---------------------------------------------------------------------
*-
***
**FORM f4_orglvlo CHANGING e_orgo TYPE /psyng/swsodorgm-object .
**  DATA: BEGIN OF lt_values OCCURS 0,
**               line(255) TYPE c,
**             END OF lt_values.
**
**  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
**        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
**        ls_orglvl TYPE /psyng/swsodorgm.
**
**
**  ls_fields-tabname   = '/PSYNG/SWSODORGM'.
**  ls_fields-fieldname = 'ABB'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'OBJECT'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'VARBL'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'LOW'.
**  APPEND ls_fields TO lt_fields.
**  ls_fields-fieldname = 'HIGH'.
**  APPEND ls_fields TO lt_fields.
**
*** Get values for popup
**  SELECT * INTO ls_orglvl FROM /psyng/swsodorgm ORDER BY abb.
**
**    ls_values-line = ls_orglvl-abb.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-object.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-varbl.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-low.
**    APPEND ls_values TO lt_values.
**    ls_values-line = ls_orglvl-high.
**    APPEND ls_values TO lt_values.
**  ENDSELECT.
**
**
**  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
**       EXPORTING
**            retfield        = 'OBJECT'
**       TABLES
**            value_tab       = lt_values
**            field_tab       = lt_fields
**            return_tab      = lt_return
**       EXCEPTIONS
**            parameter_error = 1
**            no_values_found = 2
**            OTHERS          = 3.
**  IF sy-subrc <> 0.
**    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
**            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
**  ENDIF.
**
**  READ TABLE lt_return INTO ls_return INDEX 1.
**  e_orgo = lt_return-fieldval.
**
**ENDFORM.                    " f4_orglvlo

*&---------------------------------------------------------------------*
*&      Form  get_relevant_funcs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_relevant_funcs.
  REFRESH : gt_confdet.

  IF p_pull EQ 'X'.
*--- Call RFC to get relavant function IDs
*-- Call RFC to get relavant function IDs from remote system
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_GET_REL_FUNCTIONS'
      DESTINATION p_rfcdst
      EXPORTING
        i_vrsio    = g_svrsio
      TABLES
        it_conid   = s_conid
        et_confdet = gt_confdet.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSEIF p_push EQ 'X'.
*--- Get relavant function IDs from local system
    SELECT DISTINCT functionid FROM /psyng/confdet
    INTO CORRESPONDING FIELDS OF TABLE gt_confdet
    WHERE conid IN s_conid
    AND vrsio = p_vrsio.
  ENDIF.
  IF NOT gt_confdet[] IS INITIAL.
    s_funct-sign = 'I'.
    s_funct-option = 'EQ'.
    LOOP AT gt_confdet INTO gs_confdet.
      READ TABLE s_funct WITH KEY low =
  gs_confdet-functionid BINARY SEARCH TRANSPORTING NO FIELDS .
      IF sy-subrc NE 0.
        s_funct-low = gs_confdet-functionid.
        APPEND s_funct.
      ENDIF.
    ENDLOOP.
    SORT s_funct.
    DELETE ADJACENT DUPLICATES FROM s_funct COMPARING ALL FIELDS.
  ENDIF.
ENDFORM.                    " get_relevant_funcs
*&---------------------------------------------------------------------*
*&      Form  f4_function
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_FUNCT_LOW  text
*----------------------------------------------------------------------*
FORM f4_function CHANGING e_funid TYPE /psyng/function-function.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_function TYPE TABLE OF /psyng/function,
        ls_function TYPE /psyng/function,
        l_type      TYPE dd01v-datatype.
*
  ls_fields-tabname   = '/PSYNG/FUNCTION'.
  ls_fields-fieldname = 'FUNCTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'OWNER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_function = 'X'
      TABLES
        et_function = lt_function.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_function
      FROM /psyng/function.
  ENDIF.

  LOOP AT lt_function INTO ls_function.
    ls_values-line = ls_function-vrsio.
    CALL FUNCTION 'NUMERIC_CHECK'
      EXPORTING
        string_in = ls_values-line
      IMPORTING
        htype     = l_type.
    IF l_type NE 'NUMC'.
      CONTINUE.
    ENDIF.
    ls_values-line = ls_function-function.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-owner.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_function-busarea.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'FUNCTION'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_FUNCTION'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_funid = ls_return-fieldval.

ENDFORM.                    " f4_function

*&---------------------------------------------------------------------*
*&      Form  f4_conflicts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_CONID_LOW  text
*----------------------------------------------------------------------*
FORM f4_conflicts CHANGING e_conid TYPE /psyng/conflict-conid.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_conflict TYPE TABLE OF /psyng/conflict,
        ls_conflict TYPE /psyng/conflict,
        l_type      TYPE dd01v-datatype.

*
  ls_fields-tabname   = '/PSYNG/CONFLICT'.
  ls_fields-fieldname = 'CONID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'IMP'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'INACTIVE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'OWNER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'CONTID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'RISK'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SUBAREA'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_conflict = 'X'
      TABLES
        et_conflict = lt_conflict.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_conflict
      FROM /psyng/conflict.
  ENDIF.

  LOOP AT lt_conflict INTO ls_conflict.
    ls_values-line = ls_conflict-vrsio.
    CALL FUNCTION 'NUMERIC_CHECK'
      EXPORTING
        string_in = ls_values-line
      IMPORTING
        htype     = l_type.
    IF l_type NE 'NUMC'.
      CONTINUE.
    ENDIF.
    ls_values-line = ls_conflict-conid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-imp.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-inactive.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-owner.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-busarea.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-contid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-risk.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_conflict-subarea.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'CONID'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_CONID'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_conid = ls_return-fieldval.

ENDFORM.                    " f4_conflicts
*&---------------------------------------------------------------------*
*&      Form  f4_crit_auth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_AUDID_LOW  text
*----------------------------------------------------------------------*
FORM f4_crit_auth CHANGING e_swaudid TYPE /psyng/swaudhdr-swaudid .
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_swaud  TYPE TABLE OF /psyng/swaudhdr,
        ls_swaud  TYPE /psyng/swaudhdr,
        l_type    TYPE dd01v-datatype.

*
  ls_fields-tabname   = '/PSYNG/SWAUDHDR'.
  ls_fields-fieldname = 'SWAUDID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TCODE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'OWNER'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'IMP'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_crit_auth = 'X'
      TABLES
        et_crit_auth = lt_swaud.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_swaud
      FROM /psyng/swaudhdr.
  ENDIF.

  LOOP AT lt_swaud INTO ls_swaud.
    ls_values-line = ls_swaud-vrsio.
    CALL FUNCTION 'NUMERIC_CHECK'
      EXPORTING
        string_in = ls_values-line
      IMPORTING
        htype     = l_type.
    IF l_type NE 'NUMC'.
      CONTINUE.
    ENDIF.
    ls_values-line = ls_swaud-swaudid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_swaud-vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_swaud-tcode.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_swaud-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_swaud-owner.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_swaud-imp.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield         = 'SWAUDID'
      callback_program = g_program
      callback_form    = 'F4CALLBACK_AUTH'
    TABLES
      value_tab        = lt_values
      field_tab        = lt_fields
      return_tab       = lt_return
    EXCEPTIONS
      parameter_error  = 1
      no_values_found  = 2
      OTHERS           = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_swaudid = ls_return-fieldval.
ENDFORM.                    " f4_crit_auth
*&---------------------------------------------------------------------*
*&      Form  f4_elements
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_VELEMT_LOW  text
*----------------------------------------------------------------------*
FORM f4_elements CHANGING e_elements TYPE /psyng/sw_varel-var_element.

  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_elements TYPE TABLE OF /psyng/sw_varel,
        ls_elements TYPE /psyng/sw_varel.


  ls_fields-tabname   = '/PSYNG/SW_VAREL'.
  ls_fields-fieldname = 'VAR_ELEMENT'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_elements = 'X'
      TABLES
        it_vevrs    = s_vevrs
        et_elements = lt_elements.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT DISTINCT var_element  FROM /psyng/sw_varel
    INTO CORRESPONDING FIELDS OF TABLE lt_elements
    WHERE varel_vrsio IN s_vevrs.
  ENDIF.

  LOOP AT lt_elements INTO ls_elements.
    ls_values-line = ls_elements-var_element.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VAR_ELEMENT'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_elements = ls_return-fieldval.

ENDFORM.                    " f4_elements


*---------------------------------------------------------------------*
*       FORM f4_called_tcode                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TCODE                                                       *
*---------------------------------------------------------------------*
FORM f4_called_tcode CHANGING e_tcode TYPE
                  /psyng/sw_excdtx-called_tcode.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_excdtx TYPE TABLE OF /psyng/sw_excdtx,
        ls_excdtx TYPE /psyng/sw_excdtx.


  ls_fields-tabname   = '/PSYNG/SW_EXCDTX'.
  ls_fields-fieldname = 'CALLED_TCODE'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_called_tcodes = 'X'
      TABLES
        et_called_tcodes = lt_excdtx.            "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_excdtx FROM /psyng/sw_excdtx.
  ENDIF.
  LOOP AT lt_excdtx INTO ls_excdtx.
    ls_values-line = ls_excdtx-called_tcode.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CALLED_TCODE'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_tcode = ls_return-fieldval.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_called_tcode                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_TCODE                                                       *
*---------------------------------------------------------------------*
FORM f4_calling_tcode CHANGING e_tcode TYPE
                  /psyng/sw_excltx-low.

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_excltx TYPE TABLE OF /psyng/sw_excltx,
        ls_excltx TYPE /psyng/sw_excltx.


  ls_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  ls_fields-fieldname = 'SIGN'.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  ls_fields-fieldname = 'TYPE'.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  ls_fields-fieldname = 'LOW'.
  APPEND ls_fields TO lt_fields.

  ls_fields-tabname   = '/PSYNG/SW_EXCLTX'.
  ls_fields-fieldname = 'HIGH'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_calling_tcodes = 'X'
      TABLES
        et_calling_tcodes = lt_excltx.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_excltx FROM /psyng/sw_excltx.
  ENDIF.

  LOOP AT lt_excltx INTO ls_excltx.
    ls_values-line = ls_excltx-sign.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_excltx-type.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_excltx-low.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_excltx-high.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'LOW'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_tcode = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  f4_vrsio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_SVRSIO  text
*----------------------------------------------------------------------*
FORM f4_vrsio CHANGING e_vrsio TYPE char3 .

  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF help_value,
        ls_fields TYPE help_value,
        lt_vrsio  TYPE TABLE OF /psyng/swsodvers,
        ls_vrsio  TYPE /psyng/swsodvers.

  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_vrsio = 'X'
      TABLES
        et_vrsio = lt_vrsio.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT vrsio vdesc FROM /psyng/swsodvers
    INTO CORRESPONDING FIELDS OF TABLE lt_vrsio.
  ENDIF.

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
*&---------------------------------------------------------------------*
*&      Form  select_data
*&---------------------------------------------------------------------*
*       Select all data from source version
*----------------------------------------------------------------------*
FORM select_data
USING    i_rfcdst          TYPE rfcdest
CHANGING ef_ne_matrix      TYPE flag
         ef_read_matrix    TYPE flag
         ef_no_mat_found   TYPE flag.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  ef_read_matrix = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.

*^^^ ============================================================ ^^^^^^
*   Prevent fetching all data when particular checkbox is not selected
*^^^ ============================================================ ^^^^^^
*IF p_matrix EQ 'X'. "(++) UMITTAL PN-5186 : Control Mitigation Deletion
  IF p_taudid <> 'X'.
    REFRESH s_audid.
    s_audid-sign = 'I'.
    s_audid-option = 'EQ'.
    s_audid-low = ' '.
    APPEND s_audid.
  ENDIF.

  IF p_tcscon <> 'X'.
    s_cuscon-sign = 'I'.
    s_cuscon-option = 'EQ'.
    s_cuscon-low = ' '.
    APPEND s_cuscon.
  ENDIF.
  IF p_tprof <> 'X'.
    s_prof-sign = 'I'.
    s_prof-option = 'EQ'.
    s_prof-low = ' '.
    APPEND s_prof.
  ENDIF.
  IF p_tagrnm <> 'X'.
    s_agrnam-sign = 'I'.
    s_agrnam-option = 'EQ'.
    s_agrnam-low = ' '.
    APPEND s_agrnam.
  ENDIF.
  IF p_ttcode <> 'X'.
    s_tcode-sign = 'I'.
    s_tcode-option = 'EQ'.
    s_tcode-low = ' '.
    APPEND s_tcode.
  ENDIF.

  IF p_tconid <> 'X'.
    s_conid-sign = 'I'.
    s_conid-option = 'EQ'.
    s_conid-low = ' '.
    APPEND s_conid.
  ENDIF.
  IF p_tfunct <> 'X'.
    s_funct-sign = 'I'.
    s_funct-option = 'EQ'.
    s_funct-low = ' '.
    APPEND s_funct.
  ENDIF.
* ENDIF. "(++) UMITTAL PN-5186 : Control Mitigation Deletion


*BOC UMITTAL PN-5186 : Control Mitigation Deletion

  IF p_miti <> 'X'.
    s_mitid-sign = 'I'.
    s_mitid-option = 'EQ'.
    s_mitid-low = ' '.
    APPEND s_mitid.
  ENDIF.

*  IF p_miti EQ 'X'.
  IF p_mitusr <> 'X'.
    s_con1-sign = 'I'.
    s_con1-option = 'EQ'.
    s_con1-low = ' '.
    APPEND s_con1.

    s_usrid1-sign = 'I'.
    s_usrid1-option = 'EQ'.
    s_usrid1-low = ' '.
    APPEND s_usrid1.

  ENDIF.

  IF p_usrgrp <> 'X'.
    s_con2-sign = 'I'.
    s_con2-option = 'EQ'.
    s_con2-low = ' '.
    APPEND s_con2.

    s_usrgrp-sign = 'I'.
    s_usrgrp-option = 'EQ'.
    s_usrgrp-low = ' '.
    APPEND s_usrgrp.

  ENDIF.


  IF p_assrol <> 'X'.
    s_con3-sign = 'I'.
    s_con3-option = 'EQ'.
    s_con3-low = ' '.
    APPEND s_con3.

    s_rl_nm1-sign = 'I'.
    s_rl_nm1-option = 'EQ'.
    s_rl_nm1-low = ' '.
    APPEND s_rl_nm1.

  ENDIF.

  IF p_autusr <> 'X'.
    s_wadid1-sign = 'I'.
    s_wadid1-option = 'EQ'.
    s_wadid1-low = ' '.
    APPEND s_wadid1.

    s_usrid2-sign = 'I'.
    s_usrid2-option = 'EQ'.
    s_usrid2-low = ' '.
    APPEND s_usrid2.

  ENDIF.

  IF p_autrol <> 'X'.
    s_wadid2-sign = 'I'.
    s_wadid2-option = 'EQ'.
    s_wadid2-low = ' '.
    APPEND s_wadid2.

    s_rl_nm-sign = 'I'.
    s_rl_nm-option = 'EQ'.
    s_rl_nm-low = ' '.
    APPEND s_rl_nm.

  ENDIF.
*  ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion

*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


  CALL FUNCTION '/PSYNG/SW_051'
    DESTINATION l_rfcdst
    EXPORTING
      i_vrsio           = g_svrsio
    IMPORTING
      es_swsodvers      = gs_swsodvers
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      et_user_mit_text  = gs_mit_text
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
    TABLES
      it_funid          = s_funct
      it_conid          = s_conid
      it_contid         = s_mitid
      "(++)UMITTAL PN-5186 : Control Mitigation Deletion
      it_tcode          = s_tcode
      it_audid          = s_audid
      it_agr            = s_agrnam
      it_profil         = s_prof
      it_cuscon         = s_cuscon
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      it_con1           = s_con1
      it_usrid1         = s_usrid1
      it_con2           = s_con2
      it_usrgrp         = s_usrgrp
      it_con3           = s_con3
      it_rol_nam1       = s_rl_nm1
      it_ca_objid       = s_wadid1
      it_usrid2         = s_usrid2
      it_ca_objid2      = s_wadid2
      it_rol_nam        = s_rl_nm
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
      et_function       = gt_function
      et_functtran      = gt_functtran
      et_faobj          = gt_faobj
      et_conflict       = gt_conflict
      et_confdet        = gt_confdet
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      et_mchdr          = gt_mchdr    "Mitigating Controls Header
      et_mcrvwhdr       = gt_mcrvwhdr "Mitigating Controls Review Header
      et_mcuser         = gt_mcuser   "Mitigating Users
      et_mcusrgrp       = gt_mcusrgrp "Mitigating User Groups
      et_mcrole         = gt_mcrole   "Mitigating Roles
      et_mccarole       = gt_mccarole "Mitigating CA roles
      et_mccauser       = gt_mccauser "Mitigating CA users
      et_mctran         = gt_mctran   "Transactions
      et_mcrepid        = gt_mcrepid  "Programs
      et_mcauditor      = gt_mcauditor " Auditors
*      et_mctext         = gt_mctext    "Justification Texts
*      et_mctext         = gt_mctext    "Justification Texts
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
      et_critcodes      = gt_critcodes
      et_swaudhdr       = gt_swaudhdr
      et_swaudc         = gt_swaudc
      et_criroles       = gt_criroles
      et_criprof        = gt_criprof
      et_texts          = gt_texts
      et_cuscon         = gt_cuscon
      et_conowner       = gt_conowner
      et_confil         = gt_confil
      et_funfil         = gt_funfil
      et_tcodefil       = gt_tcodefil
      et_authfil        = gt_authfil
      et_swsodorgo      = gt_swsodorgo
    EXCEPTIONS
      version_not_exist = 1
      OTHERS            = 2.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc EQ 1.
    ef_ne_matrix = 'X'.
  ENDIF.
  ef_no_mat_found = 'X'.
  IF  p_tvhead EQ 'X'
  AND NOT gs_swsodvers IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_tfunct EQ 'X'
  AND NOT gt_function[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_tconid EQ 'X'
  AND NOT gt_conflict[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_tcscon EQ 'X'
  AND NOT gt_cuscon[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_ttcode EQ 'X'
  AND NOT gt_critcodes[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_taudid EQ 'X'
  AND NOT gt_critcodes[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_tagrnm EQ 'X'
  AND NOT gt_criroles[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF p_tprof EQ 'X'
  AND NOT gt_criprof[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

*BOC UMITTAL PN-5186 : Control Mitigation Deletion

  IF  p_miti EQ 'X'
  AND NOT gt_mchdr[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_mitusr EQ 'X'
  AND NOT gt_mcuser[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_usrgrp EQ 'X'
  AND NOT gt_mcusrgrp[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_assrol EQ 'X'
  AND NOT gt_mcrole[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_autusr EQ 'X'
  AND NOT gt_mccauser[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.

  IF  p_autrol EQ 'X'
  AND NOT gt_mccarole[] IS INITIAL.
    CLEAR ef_no_mat_found.
    EXIT.
  ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion


ENDFORM.                    " select_data
*&---------------------------------------------------------------------*
*&      Form  at_selection_screen_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM at_selection_screen_output.
  p_cmo = 'Overwrite'(027).
  p_cmi = 'Append'(026).
  IF NOT g_field IS INITIAL.
    SET CURSOR FIELD g_field.
  ENDIF.


  LOOP AT SCREEN.
    IF screen-name CS 'S_FUNCT' OR screen-name CS 'P_FNFLTR'.
      IF p_tfunct = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CONID'
        OR screen-name CS 'P_CNFLTR'
        OR screen-name CS 'P_TORGO'.
      IF p_tconid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'P_CONFUN'.
      IF p_tconid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CUSCON'.
      IF p_tcscon = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TCODE' OR screen-name CS 'P_CTFLTR'.
      IF p_ttcode = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AUDID' OR screen-name CS 'P_CAFLTR'.
      IF p_taudid = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_AGRNAM'.
      IF p_tagrnm = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_PROF'.
      IF p_tprof = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_CONFG'.
      IF p_tconfg = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TAPAR'.
      IF p_tapar = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TPROCR'.
      IF p_tprocr = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TSYST'.
      IF p_tsyst = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ELSEIF screen-name CS 'S_TSYSC'.
      IF p_tsysc = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
*    ELSEIF screen-name CS 'S_TPROJ'.
*      IF p_tproj = space.
*        screen-active = 0.
*        screen-invisible = 1.
*      ELSE.
*        screen-active = 1.
*        screen-invisible = 0.
*      ENDIF.
*    ELSEIF screen-name CS 'S_TSTAT'.
*      IF p_tstat = space.
*        screen-active = 0.
*        screen-invisible = 1.
*      ELSE.
*        screen-active = 1.
*        screen-invisible = 0.
*      ENDIF.
*    ELSEIF screen-name CS 'S_TORGLV'
*        OR screen-name CS 'S_TORGLA'
*        OR screen-name CS 'S_TORGLO'.
*      IF p_torglv = space.
*        screen-active = 0.
*        screen-invisible = 1.
*      ELSE.
*        screen-active = 1.
*        screen-invisible = 0.
*      ENDIF.
    ELSEIF screen-name CS 'S_TRISK'.
      IF p_trisk = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
*    ELSEIF screen-name CS 'S_TMITYP'.
*      IF p_tmityp = space.
*        screen-active = 0.
*        screen-invisible = 1.
*      ELSE.
*        screen-active = 1.
*        screen-invisible = 0.
*      ENDIF.
*    ELSEIF screen-name CS 'S_TFREQ'.
*      IF p_tfreq = space.
*        screen-active = 0.
*        screen-invisible = 1.
*      ELSE.
*        screen-active = 1.
*        screen-invisible = 0.
*      ENDIF.
    ELSEIF screen-name CS 'P_TFUNCT'.
*B8643.
      IF p_tfunct = space.
        REFRESH s_funct[].
        p_fnfltr = space.
      ENDIF.
*END.
      IF p_confun = 'X'.
*        screen-active = 0.
        screen-input = 0.
      ELSE.
*        screen-active = 1.
        screen-input = 1.
      ENDIF.
    ELSEIF screen-name CS 'S_VELEMT'  OR
           screen-name CS 'S_VEVRS'   OR
           screen-name CS 'P_VE_HDR' .
      IF p_velemt = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_SETID'.
      IF p_cnfset = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_CTCOD'.
      IF p_dynam = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'P_TCONID'.
      IF p_tconid = space.
        REFRESH s_conid[].
        p_cnfltr = space.
        p_torgo  = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TTCODE'.
      IF p_ttcode = space.
        REFRESH s_tcode[].
        p_ctfltr = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TAUDID'.
      IF p_taudid  = space.
        REFRESH s_audid[].
        p_cafltr = space.
      ENDIF.
    ELSEIF screen-name CS 'P_TCSCON'.
      IF p_tcscon = space.
        REFRESH s_cuscon[].
      ENDIF.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
    ELSEIF screen-name CS 'S_CON1' OR
           screen-name CS 'S_USRID1'.
      IF p_mitusr EQ space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_CON2' OR
           screen-name CS 'S_USRGRP'.
      IF p_usrgrp EQ space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF  screen-name CS 'S_CON3' OR
            screen-name CS 'S_RL_NM1' .
      IF p_assrol EQ space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

    ELSEIF screen-name CS 'S_WADID1' OR
           screen-name CS 'S_USRID2'.
      IF p_autusr EQ space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.


    ELSEIF screen-name CS 'S_WADID2' OR
           screen-name CS 'S_RL_NM'.
      IF p_autrol EQ space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.

*EOC UMITTAL PN-5186 : Control Mitigation Deletion
    ENDIF.



    IF screen-group1 EQ 'PAR'.
      IF p_push EQ 'X'.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ENDIF.
    IF screen-group1 EQ 'SEL'.
      IF p_pull EQ 'X'.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ENDIF.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion

*    IF screen-group1 EQ 'WRT'.
*      IF p_deltar = 'X'
*      OR p_matrix = ' '.
*        screen-input = 0.
**--When delete checkbox is selected; it will be append only
*        CLEAR p_fowrt.
*        p_ins = 'X'.
*      ELSE.
*        screen-input = 1.
*      ENDIF.
*    ENDIF.
    IF screen-group1 EQ 'WTR'.
      IF p_deltar = 'X'.
        screen-input = 0.
*  --When delete checkbox is selected; it will be append only
        CLEAR p_fowrt.
        p_ins = 'X'.
      ELSE.
        screen-input = 1.
      ENDIF.
    ENDIF.


*    IF screen-group1 EQ 'TCR' .
*      IF p_deltar  EQ 'X'.
*        screen-active = 1.
*        screen-invisible = 0.
***        screen-input = 1 .
*      ELSe.
**        screen-active = 0.
**        screen-invisible = 1.
*        screen-input = 0 .
*      ENDIF.
*    ENDIF.

    IF screen-group1 EQ 'MCR'.
*      IF   p_deltar EQ 'X'  AND
      IF    p_miti EQ 'X'  ..
        screen-active = 1.
        screen-invisible = 0.
      ELSE.
*        screen-active = 1.
        screen-active = 0.
        screen-invisible = 1.
      ENDIF.
    ENDIF.


*    IF screen-group1 EQ 'DIS'.
*      IF p_matrix EQ 'X'.
*        screen-input = 1.
*      ELSE.
*        screen-input = 0.
*      ENDIF.
*    ENDIF.
    IF screen-group1 EQ 'WRT'
    OR screen-group1 EQ 'DIS'.
      IF p_matrix = space.
        screen-active = 0.
        screen-invisible = 1.
      ELSE.
        screen-active = 1.
        screen-invisible = 0.
      ENDIF.
    ENDIF.
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
    MODIFY SCREEN.
  ENDLOOP.

  IF p_tconid = 'X'.
    CHECK p_confun = 'X'.
    CHECK NOT s_conid[] IS INITIAL.
    IF p_pull EQ 'X'.
      g_svrsio = p_vrsio.
*--- Call RFC to get relavant function IDs
*-- Call RFC to get relavant function IDs from remote system
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_GET_REL_FUNCTIONS'
        DESTINATION p_rfcdst
        EXPORTING
          i_vrsio    = g_svrsio
        TABLES
          it_conid   = s_conid
          et_confdet = gt_confdet.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ELSEIF p_push EQ 'X'.
*--- Get relavant function IDs from local system
      SELECT DISTINCT functionid FROM /psyng/confdet
      INTO CORRESPONDING FIELDS OF TABLE gt_confdet
      WHERE conid IN s_conid
      AND vrsio = p_vrsio.
    ENDIF.
    IF NOT gt_confdet[] IS INITIAL.
      s_funct-sign = 'I'.
      s_funct-option = 'EQ'.

      LOOP AT gt_confdet INTO gs_confdet.
        s_funct-low = gs_confdet-functionid.
        APPEND s_funct.
      ENDLOOP.
    ENDIF.
    SORT s_funct BY low.
    DELETE ADJACENT DUPLICATES FROM s_funct COMPARING low.
  ENDIF.
ENDFORM.                    " at_selection_screen_output
*&---------------------------------------------------------------------*
*&      Form  copy_matrix
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM transfer_matrix
USING i_rfcdst TYPE rfcdes-rfcdest.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_TRANSFER_MATRIX'
    DESTINATION l_rfcdst
    EXPORTING
      i_vrsio      = g_tvrsio
      i_swsodvers  = gs_swsodvers
      if_tvhead    = p_tvhead
      if_tfunct    = p_tfunct
      if_tconid    = p_tconid
      if_ttcode    = p_ttcode
      if_taudid    = p_taudid
      if_tagrnm    = p_tagrnm
      if_tprof     = p_tprof
      if_tcscon    = p_tcscon
      if_fnfltr    = p_fnfltr
      if_cnfltr    = p_cnfltr
      if_ctfltr    = p_ctfltr
      if_cafltr    = p_cafltr
      if_torgo     = p_torgo
      if_test      = p_test
      if_append    = p_ins
      if_delete    = p_deltar
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      if_matrix       = p_matrix
      if_mitigation   = p_miti
      if_mitusr       = p_mitusr
      if_usrgrp       = p_usrgrp
      if_assrol       = p_assrol
      if_autusr       = p_autusr
      if_autrol       = p_autrol
      i_mit_text = gs_mit_text
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
    TABLES
      it_function  = gt_function[]
      it_functtran = gt_functtran[]
      it_faobj     = gt_faobj[]
      it_conflict  = gt_conflict[]
      it_confdet   = gt_confdet[]
      it_critcodes = gt_critcodes[]
      it_swaudhdr  = gt_swaudhdr[]
      it_swaudc    = gt_swaudc[]
      it_criroles  = gt_criroles[]
      it_criprof   = gt_criprof[]
      it_texts     = gt_texts[]
      it_cuscon    = gt_cuscon[]
      it_conowner  = gt_conowner[]
      it_confil    = gt_confil[]
      it_funfil    = gt_funfil[]
      it_tcodefil  = gt_tcodefil[]
      it_authfil   = gt_authfil[]
      it_swsodorgo = gt_swsodorgo[]
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      it_mchdr     = gt_mchdr[]    "Mitigating Controls Header
      it_mcrvwhdr  = gt_mcrvwhdr[] "Mitigating Controls Review Header
      it_mcuser    = gt_mcuser[]   "Mitigating Users
      it_mcusrgrp  = gt_mcusrgrp[] "Mitigating User Groups
      it_mcrole    = gt_mcrole[]   "Mitigating Roles
      it_mccarole  = gt_mccarole[] "Mitigating CA roles
      it_mccauser  = gt_mccauser[] "Mitigating CA users
      it_mctran    = gt_mctran[]   "Mitigating Transactions
      it_mcrepid   = gt_mcrepid[]  "Mitigating Programs
      it_mcauditor = gt_mcauditor[] "Mitigating Auditors
      it_mctext    = gt_mctext[]    "Mitigating Justifications
*EOC UMITTAL PN-5186 : Control Mitigation Deletion
      et_return    = lt_return.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT lt_return INTO ls_return.
    IF ls_return-message_v1 CS 'Mitigation'.
      PERFORM fill_log USING 'Mitigation'(c14)  "Configuration type
                           l_source       "Source System
                           l_target       "Target System
                           ls_return.
    ELSE.
    PERFORM fill_log USING 'Matrix'(c03)  "Configuration type
                           l_source       "Source System
                           l_target       "Target System
                           ls_return.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " copy_matrix
*&---------------------------------------------------------------------*
*&      Form  at_selection_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM at_selection_screen.

  DATA:
    l_count TYPE n,
    lt_rfc  TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
    ls_rfc  TYPE /psyng/sw_sel_opts_rfcdest,
    lt_ret  TYPE TABLE OF bapiret2,
    ls_ret  TYPE bapiret2.

  CLEAR: g_ucomm, g_field.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

  g_svrsio = p_vrsio.
  g_tvrsio = p_vrsio.

  CASE g_ucomm.
*BOC UMITTAL PN-5186 : Control Mitigation Deletion
      "Enable/Disable Checkboxes when Delete obj checkbox is selected.
*    WHEN 'EXP'.
*      IF p_deltar EQ 'X'.
*        p_miti = 'X'.
*        p_mitusr = 'X'.
*        p_usrgrp = 'X'.
*        p_autusr = 'X'.
*        p_autrol = 'X'.
*        p_assrol = 'X'.
*      ELSE.
*        CLEAR p_miti.
*        CLEAR :
*        p_mitusr,
*        p_usrgrp,
*        p_autusr,
*        p_autrol,
*        p_assrol .
*      ENDIF.
    "Enable/Disable Checkboxes when Mitigation checkbox is (un)selected.
    WHEN 'MITI'.
*      IF p_miti EQ 'X' AND p_deltar EQ 'X'.
*        p_mitusr = 'X'.
*        p_usrgrp = 'X'.
*        p_autusr = 'X'.
*        p_autrol = 'X'.
*        p_assrol = 'X'.
*      ELSE.
*        CLEAR :
*        p_mitusr,
*        p_usrgrp,
*        p_autusr,
*        p_autrol,
*        p_assrol .
*      ENDIF.
      IF p_miti EQ space.
        CLEAR :
        p_mitusr,
        p_usrgrp,
        p_autusr,
        p_autrol,
        p_assrol .
      ENDIF.

*EOC UMITTAL PN-5186 : Control Mitigation Deletion
*--If relavant function IDs is ticked; get relevant functions
    WHEN 'UCF'.
      IF p_confun = 'X'.
        IF s_conid-low IS INITIAL.
          CLEAR p_confun.
          g_field = 'S_CONID-LOW'.
          MESSAGE s002(/psyng/sw) WITH text-002.
        ELSE.
          IF p_pull EQ 'X'.
*BOC UMITTAL SE VF scan changes-25/11/2024
            CALL FUNCTION 'RFC_CALLBACK_REJECTED'
              EXCEPTIONS
                invalid_reject_option  = 1
                invalid_reject_state   = 2
                function_not_supported = 3
                internal_error         = 4
                OTHERS                 = 5.
            IF sy-subrc NE 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
*-- Call RFC to get relavant function IDs from remote system
            CALL FUNCTION '/PSYNG/SW_GET_REL_FUNCTIONS'
              DESTINATION p_rfcdst
              EXPORTING
                i_vrsio    = g_svrsio
              TABLES
                it_conid   = s_conid
                et_confdet = gt_confdet.         "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          ELSEIF p_push EQ 'X'.
*--get relavant function IDs from local system
            SELECT DISTINCT functionid
            FROM /psyng/confdet
            INTO CORRESPONDING FIELDS OF TABLE gt_confdet
            WHERE conid IN s_conid
            AND vrsio = p_vrsio.
          ENDIF.
          IF NOT gt_confdet[] IS INITIAL.
            s_funct-sign = 'I'.
            s_funct-option = 'EQ'.

            LOOP AT gt_confdet INTO gs_confdet.
              s_funct-low = gs_confdet-functionid.
              APPEND s_funct.
            ENDLOOP.
            p_tfunct = 'X'.
          ENDIF.
        ENDIF.
      ELSE.
        p_tfunct = ' '.
        REFRESH s_funct.
      ENDIF.
*--If matrix checkbox is ticked; enable sub blocks
    WHEN 'MAT'.
      IF p_matrix EQ 'X'.
        p_tvhead = 'X'.
        p_tfunct = 'X'.
        p_fnfltr = 'X'.
        p_tconid = 'X'.
        p_cnfltr = 'X'.
        p_torgo  = 'X'.
        p_tcscon = 'X'.
        p_ttcode = 'X'.
        p_ctfltr = 'X'.
        p_taudid = 'X'.
        p_cafltr = 'X'.
        p_tagrnm = 'X'.
        p_tprof  = 'X'.
*--If matrix checkbox is unticked; disable sub blocks
      ELSE.
        CLEAR:
          p_vrsio,
          p_tvhead,
          p_tfunct,
          p_fnfltr,
          p_tconid,
          p_cnfltr,
          p_torgo,
          p_tcscon,
          p_ttcode,
          p_ctfltr,
          p_taudid,
          p_cafltr,
          p_tagrnm,
          p_tprof.
      ENDIF.
    WHEN space
    OR 'ONLI'.                         "#EC SAST_CI_GEN_CHECK (HBHALLA)
*--Check if remote system is entered; in case of pull
      IF  p_pull   EQ 'X'
      AND p_rfcdst IS INITIAL.
        g_field = 'P_RFCDST'.
        MESSAGE s113(/psyng/sw) WITH text-e01.
        LEAVE SCREEN.
*--Check if remote system exits; in case of pull
      ELSEIF  p_pull EQ 'X'
      AND NOT p_rfcdst IS INITIAL.

        ls_rfc-sign   = 'I'.
        ls_rfc-option = 'EQ'.
        ls_rfc-low    = p_rfcdst.
        APPEND ls_rfc TO lt_rfc.

        CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
          EXPORTING
            i_popup   = 'N'
          TABLES
            it_rfcdes = lt_rfc
            et_return = lt_ret.
        IF NOT lt_ret IS INITIAL.
          g_field = 'P_RFCDST'.
          READ TABLE lt_ret INTO ls_ret INDEX 1.
          MESSAGE s002 WITH ls_ret-message.
          LEAVE SCREEN.
        ENDIF.
      ENDIF.
*--Check if remote system is entered; in case of push
      IF  p_push   EQ 'X'
      AND s_rfcdst IS INITIAL.
        g_field = 'S_RFCDST-LOW'.
        MESSAGE s113(/psyng/sw) WITH text-e01.
        LEAVE SCREEN.
*--If single remote system entered; in case of push
*--Check if it exits
      ELSEIF  p_push   EQ 'X'
      AND NOT s_rfcdst IS INITIAL.
        DESCRIBE TABLE s_rfcdst[] LINES l_count.
        IF l_count EQ 1.
          READ TABLE s_rfcdst INDEX 1.
          ls_rfc-sign   = 'I'.
          ls_rfc-option = 'EQ'.
          ls_rfc-low    = s_rfcdst-low.
          APPEND ls_rfc TO lt_rfc.

          CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
            EXPORTING
              i_popup   = 'N'
            TABLES
              it_rfcdes = lt_rfc
              et_return = lt_ret.
          IF NOT lt_ret IS INITIAL.
            g_field = 'S_RFCDST-LOW'.
            READ TABLE lt_ret INTO ls_ret INDEX 1.
            MESSAGE s002 WITH ls_ret-message.
            LEAVE SCREEN.
          ENDIF.
        ENDIF.
      ENDIF.
*In case of copy matrix
      IF p_matrix EQ 'X'
      OR p_miti EQ 'X'.
        "(++)UMITTAL PN-5186 : Control Mitigation Deletion
*--Check if version is entered
** P_svrsio is chnged form NUMC to C as we cant check for Space or
** initial.
        CONDENSE p_vrsio NO-GAPS.
        SHIFT p_vrsio RIGHT DELETING TRAILING space.
        IF p_vrsio = space.
          g_field = 'P_VRSIO'.
          MESSAGE s002(/psyng/sw) WITH
          'Please Enter SOD version'(028).
          LEAVE SCREEN.
        ELSE.
*--Check if valid version entered
          IF NOT p_vrsio CO '1234567890 '.
            g_field = 'P_VRSIO'.
            MESSAGE s002(/psyng/sw) WITH
            'Please Enter Valid SOD version'(029).
            LEAVE SCREEN.
          ENDIF.
        ENDIF.
      ENDIF.
*--Check atleast one object should be ticked to transfer in matrix box
      IF  p_matrix EQ 'X'
        AND p_tvhead IS INITIAL
        AND p_tfunct IS INITIAL
        AND p_fnfltr IS INITIAL
        AND p_tconid IS INITIAL
        AND p_cnfltr IS INITIAL
        AND p_tcscon IS INITIAL
        AND p_ttcode IS INITIAL
        AND p_ctfltr IS INITIAL
        AND p_taudid IS INITIAL
        AND p_cafltr IS INITIAL
        AND p_tagrnm IS INITIAL
        AND p_tprof IS INITIAL.
        g_field = 'P_MATRIX'.
        MESSAGE s002 WITH
        'Atleast select one object in matrix block'(030)
        'OR untick matrix checkbox'(031).
        LEAVE SCREEN.
      ENDIF.

  ENDCASE.
ENDFORM.                    " at_selection_screen
*&---------------------------------------------------------------------*
*&      Form  transfer_configuration
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM transfer_configuration.

  DATA:
    lf_read_matrix   TYPE flag,
    lf_read_config   TYPE flag,
    lf_read_ve       TYPE flag,
    lf_read_dynam    TYPE flag,
    lf_read_cnfset   TYPE flag,
    lf_read_busarea  TYPE flag,
    lf_read_subarea  TYPE flag,
    lf_read_risk     TYPE flag,
    lf_read_sys_type TYPE flag,
    lf_read_sys_cat  TYPE flag,
    lf_ne_matrix     TYPE flag,
    lf_ne_config     TYPE flag,
    lf_ne_ve         TYPE flag,
    lf_ne_dynam      TYPE flag,
    lf_ne_cnfset     TYPE flag,
    lf_ne_busarea    TYPE flag,
    lf_ne_subarea    TYPE flag,
    lf_ne_risk       TYPE flag,
    lf_ne_sys_type   TYPE flag,
    lf_ne_sys_cat    TYPE flag,
    lf_no_mat_found  TYPE flag,
    ls_return        TYPE bapiret2,
    lt_rfc           TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
    ls_rfc           TYPE /psyng/sw_sel_opts_rfcdest,
    lt_ret           TYPE TABLE OF bapiret2,
    ls_ret           TYPE bapiret2.


*-- Pull the configuration from remote system to Local
  IF p_pull EQ 'X'.
*--Transfer matrix
    IF  p_matrix EQ 'X'
    OR p_miti EQ 'X'."(++)UMITTAL PN-5186 : Control Mitigation Deletion
*--Fetch data from remote system
      PERFORM select_data
        USING p_rfcdst
     CHANGING lf_ne_matrix
              lf_read_matrix
              lf_no_mat_found.
*--If version exits in source system
*--Transfer matrix in local system
      IF  lf_ne_matrix IS INITIAL
      AND lf_no_mat_found IS INITIAL.
        PERFORM transfer_matrix USING ''.
      ELSEIF lf_ne_matrix EQ 'X'.
        ls_return-type    = 'E'.
        ls_return-message = text-e27.
        PERFORM fill_log USING 'Matrix'(c03)  "Configuration type
                               p_rfcdst       "Source System
                               'Local'(c08)        "Target System
                               ls_return.
      ELSEIF lf_no_mat_found EQ 'X'.
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log USING 'Matrix'(c03)  "Configuration type
                               p_rfcdst       "Source System
                               'Local'(c08)        "Target System
                               ls_return.
      ENDIF.
    ENDIF.
*--Transfer configuration parameters
    IF p_tconfg EQ 'X'.
      PERFORM read_configuration
        USING p_rfcdst
      CHANGING lf_ne_config
               lf_read_config.
      IF lf_ne_config IS INITIAL.
        PERFORM transfer_parameters USING ''.
      ELSE.
*--If no configuration parameters found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Configuration Parameter'(c04)  "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer variable elements
    IF p_velemt EQ 'X'.
      PERFORM read_variable_element_rules
        USING p_rfcdst
      CHANGING lf_ne_ve
               lf_read_ve.
      IF lf_ne_ve IS INITIAL.
        PERFORM transfer_ve_rules USING ''.
      ELSE.
*--If no variable element rules found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Variable Element Rules'(c05) "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer dynamic enhancement configuration
    IF p_dynam EQ 'X'.
      PERFORM read_dynamic_config
        USING p_rfcdst
      CHANGING lf_ne_dynam
               lf_read_dynam.
      IF lf_ne_dynam IS INITIAL.
        PERFORM transfer_dynamic_config USING ''.
      ELSE.
*--If no variable element rules found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Dynamic Enhancement Config.'(c06)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer configuration Set
    IF p_cnfset EQ 'X'.
      PERFORM read_config_set
        USING p_rfcdst
      CHANGING lf_ne_cnfset
               lf_read_cnfset.
      IF lf_ne_cnfset IS INITIAL.
        PERFORM transfer_config_set USING ''.
      ELSE.
*--If no configuration set found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Configuration Set'(c07)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer business application area
    IF p_tapar EQ 'X'.
      PERFORM read_busarea
        USING p_rfcdst
      CHANGING lf_ne_busarea
               lf_read_busarea.
      IF lf_ne_busarea IS INITIAL.
        PERFORM transfer_other_config USING ''
                                            gc_application_area.
      ELSE.
*--If no application areas found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Application Area'(c09)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer business process area
    IF p_tprocr EQ 'X'.
      PERFORM read_subarea
        USING p_rfcdst
      CHANGING lf_ne_subarea
               lf_read_subarea.
      IF lf_ne_subarea IS INITIAL.
        PERFORM transfer_other_config USING ''
                                            gc_process_area.
      ELSE.
*--If no process areas found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Process Area'(c10)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer risk scenario
    IF p_trisk EQ 'X'.
      PERFORM read_risk
        USING p_rfcdst
      CHANGING lf_ne_risk
               lf_read_risk.
      IF lf_ne_risk IS INITIAL.
        PERFORM transfer_other_config USING ''
                                            gc_risk.
      ELSE.
*--If no risk scenario found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'Risk Scenario'(c11)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer system type
    IF p_tsyst EQ 'X'.
      PERFORM read_sys_type
        USING p_rfcdst
      CHANGING lf_ne_sys_type
               lf_read_sys_type.
      IF lf_ne_sys_type IS INITIAL.
        PERFORM transfer_other_config USING ''
                                            gc_sys_type.
      ELSE.
*--If no system type found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'System Type'(c12)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Transfer system category
    IF p_tsysc EQ 'X'.
      PERFORM read_sys_cat
        USING p_rfcdst
      CHANGING lf_ne_sys_cat
               lf_read_sys_cat.
      IF lf_ne_sys_cat IS INITIAL.
        PERFORM transfer_other_config USING ''
                                            gc_sys_cat.
      ELSE.
*--If no system type found in source system; raise message
        ls_return-type    = 'E'.
        ls_return-message = text-e28.
        PERFORM fill_log
        USING 'System Category'(c13)   "Configuration type
              p_rfcdst                        "Source System
              'Local'(c08)                         "Target System
              ls_return.
      ENDIF.
    ENDIF.
*--Push the configuration from Local to Remote systems
  ELSEIF p_push EQ 'X'.
    LOOP AT s_rfcdst.
      CLEAR:   ls_rfc, ls_ret.
      REFRESH: lt_rfc, lt_ret.
      ls_rfc-sign   = 'I'.
      ls_rfc-option = 'EQ'.
      ls_rfc-low    = s_rfcdst-low.
      APPEND ls_rfc TO lt_rfc.

      CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
        EXPORTING
          i_popup   = 'N'
        TABLES
          it_rfcdes = lt_rfc
          et_return = lt_ret.
*--If Remote system connection does not exist
      IF NOT lt_ret IS INITIAL.
        READ TABLE lt_ret INTO ls_ret INDEX 1.
        CLEAR ls_return.
        ls_return-type    = 'E'.
        ls_return-message = ls_ret-message.
        PERFORM fill_log USING ''      "Configuration type
                               'Local'(c08)       "Source System
                               s_rfcdst-low  "Target System
                               ls_return.
*--Continue with next remote system
        CONTINUE.
      ENDIF.
*--Transfer Matrix
      IF ( p_matrix  EQ 'X'
    OR p_miti EQ 'X' )"(++)UMITTAL PN-5186 : Control Mitigation Deletion
      AND lf_ne_matrix IS INITIAL
      AND lf_no_mat_found IS INITIAL.
*--Fetch data from local system one time
        IF lf_read_matrix IS INITIAL.
          PERFORM select_data
            USING ''
         CHANGING lf_ne_matrix
                  lf_read_matrix
                  lf_no_mat_found.
        ENDIF.
*--If version exits in source system
*--Transfer matrix in remote system
        IF  lf_ne_matrix IS INITIAL
        AND lf_no_mat_found IS INITIAL.
          PERFORM transfer_matrix USING s_rfcdst-low.
        ELSEIF lf_ne_matrix EQ 'X'.
          CLEAR ls_return.
          ls_return-type    = 'E'.
          ls_return-message = text-e27.
          PERFORM fill_log USING 'Matrix'(c03) "Configuration type
                                 'Local'(c08)       "Source System
                                 s_rfcdst-low  "Target System
                                 ls_return.
        ELSEIF lf_no_mat_found EQ 'X'.
          CLEAR ls_return.
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log USING 'Matrix'(c03) "Configuration type
                                 'Local'(c08)  "Source System
                                 s_rfcdst-low  "Target System
                                 ls_return.
        ENDIF.
      ENDIF.

*--Transfer configuration parameters
      IF  p_tconfg     EQ 'X'
      AND lf_ne_config IS INITIAL.
        IF lf_read_config IS INITIAL.
          PERFORM read_configuration
          USING ''
          CHANGING lf_ne_config
                   lf_read_config.
        ENDIF.
        IF lf_ne_config IS INITIAL.
          PERFORM transfer_parameters USING s_rfcdst-low.
        ELSE.
*--If no configuration parameters found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Configuration Parameter'(c04)  "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                    "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer variable elements
      IF  p_velemt EQ 'X'
      AND lf_ne_ve IS INITIAL.
        IF lf_read_ve IS INITIAL.
          PERFORM read_variable_element_rules
            USING ''
          CHANGING lf_ne_ve
                   lf_read_ve.
        ENDIF.
        IF lf_ne_ve IS INITIAL.
          PERFORM transfer_ve_rules USING s_rfcdst-low.
        ELSE.
*--If no variable element rules found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Variable Element Rules'(c05) "Configuration type
                'Local'(c08)                       "Source System
                s_rfcdst-low                  "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer dynamic configuration
      IF  p_dynam     EQ 'X'
      AND lf_ne_dynam IS INITIAL.
        IF lf_read_dynam IS INITIAL.
          PERFORM read_dynamic_config
            USING ''
          CHANGING lf_ne_dynam
                   lf_read_dynam.
        ENDIF.
        IF lf_ne_dynam IS INITIAL.
          PERFORM transfer_dynamic_config USING s_rfcdst-low.
        ELSE.
*--If no variable element rules found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Dynamic Enhancement Config.'(c06)   "Configuration type
                'Local'(c08)                              "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
*--Transfer configuration Set
      IF  p_cnfset     EQ 'X'
      AND lf_ne_cnfset IS INITIAL.
        IF lf_read_cnfset IS INITIAL.
          PERFORM read_config_set
            USING ''
          CHANGING lf_ne_cnfset
                   lf_read_cnfset.
        ENDIF.
        IF lf_ne_cnfset IS INITIAL.
          PERFORM transfer_config_set USING s_rfcdst-low.
        ELSE.
*--If no configuration set found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Configuration Set'(c07)       "Configuration type
                'Local'(c08)                        "Source System
                s_rfcdst-low                   "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer application areas
      IF  p_tapar     EQ 'X'
      AND lf_ne_busarea IS INITIAL.
        IF lf_read_busarea IS INITIAL.
          PERFORM read_busarea
            USING ''
          CHANGING lf_ne_busarea
                   lf_read_busarea.
        ENDIF.
        IF lf_ne_busarea IS INITIAL.
          PERFORM transfer_other_config USING s_rfcdst-low
                                              gc_application_area.
        ELSE.
*--If no application area found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Application Area'(c09)   "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer process areas
      IF  p_tprocr     EQ 'X'
      AND lf_ne_subarea IS INITIAL.
        IF lf_read_subarea IS INITIAL.
          PERFORM read_subarea
            USING ''
          CHANGING lf_ne_subarea
                   lf_read_subarea.
        ENDIF.
        IF lf_ne_subarea IS INITIAL.
          PERFORM transfer_other_config USING s_rfcdst-low
                                              gc_process_area.
        ELSE.
*--If no process area found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Process Area'(c10)   "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer risk scenario
      IF  p_trisk     EQ 'X'
      AND lf_ne_risk IS INITIAL.
        IF lf_read_risk IS INITIAL.
          PERFORM read_risk
            USING ''
          CHANGING lf_ne_risk
                   lf_read_risk.
        ENDIF.
        IF lf_ne_risk IS INITIAL.
          PERFORM transfer_other_config USING s_rfcdst-low
                                              gc_risk.
        ELSE.
*--If no risk scenario found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'Risk Scenario'(c11)   "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer system type
      IF  p_tsyst     EQ 'X'
      AND lf_ne_sys_type IS INITIAL.
        IF lf_read_sys_type IS INITIAL.
          PERFORM read_sys_type
            USING ''
          CHANGING lf_ne_sys_type
                   lf_read_sys_type.
        ENDIF.
        IF lf_ne_sys_type IS INITIAL.
          PERFORM transfer_other_config USING s_rfcdst-low
                                              gc_sys_type.
        ELSE.
*--If no system type found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'System Type'(c12)   "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
*Transfer system category
      IF  p_tsysc     EQ 'X'
      AND lf_ne_sys_cat IS INITIAL.
        IF lf_read_sys_cat IS INITIAL.
          PERFORM read_sys_cat
            USING ''
          CHANGING lf_ne_sys_cat
                   lf_read_sys_cat.
        ENDIF.
        IF lf_ne_sys_cat IS INITIAL.
          PERFORM transfer_other_config USING s_rfcdst-low
                                              gc_sys_cat.
        ELSE.
*--If no system category found in source system; raise message
          ls_return-type    = 'E'.
          ls_return-message = text-e28.
          PERFORM fill_log
          USING 'System Category'(c13)   "Configuration type
                'Local'(c08)                         "Source System
                s_rfcdst-low                         "Target System
                ls_return.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " transfer_configuration
*&---------------------------------------------------------------------*
*&      Form  fill_log
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4959   text
*      -->P_4960   text
*      -->P_GR_RFCDST  text
*      -->P_LS_RETURN  text
*----------------------------------------------------------------------*
FORM fill_log
USING i_config_type TYPE char30
      i_source      TYPE rfcdest
      i_target      TYPE rfcdest
      is_return     TYPE bapiret2.

  DATA: ls_log TYPE ty_log.

  ls_log-config_type = i_config_type.
  ls_log-source      = i_source.
  ls_log-target      = i_target.
  CASE is_return-type.
    WHEN 'S'."Success
      ls_log-type_icon  =  '@08@'.
    WHEN 'W'."Warning
      ls_log-type_icon  =  '@09@'.
    WHEN 'E'."Error
      ls_log-type_icon  =  '@0A@'.
  ENDCASE.

  MOVE-CORRESPONDING is_return TO ls_log.

  APPEND ls_log TO gt_log.

ENDFORM.                    " fill_log
*&---------------------------------------------------------------------*
*&      Form  display_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_output.
  DATA: ls_variant  TYPE disvariant,
        ls_layout   TYPE slis_layout_alv,
        lt_fieldcat TYPE slis_t_fieldcat_alv,
        l_program   LIKE sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  l_program = sy-repid.

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'SOURCE' ''
          'Source System'(f02).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'TARGET' ''
          'Target System'(f03).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'CONFIG_TYPE' ''
          'Configuration Type'(f01).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'TYPE_ICON' ''
          'Error Type'(f04).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'MESSAGE_V1' ''
          'Object Name 1'(f06).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'MESSAGE_V2' ''
          'Object Value'(f07).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'MESSAGE_V3' ''
          'Object Name 2'(f08).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'MESSAGE_V4' ''
          'Object Value'(f07).

  PERFORM build_fieldcat
   TABLES lt_fieldcat
    USING 'MESSAGE' ''
          'Message'(f05).

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page = 'ALV_HEADER'
      i_callback_program     = l_program
      is_layout              = ls_layout
      it_fieldcat            = lt_fieldcat
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = gt_log
      "(++)BOC UMITTAL SE VF scan-25/11/2024
    EXCEPTIONS
      program_error          = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " display_output
*---------------------------------------------------------------------*
*       FORM ALV_HEADER                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: lt_header TYPE slis_t_listheader,
        ls_header TYPE slis_listheader,
        l_count   TYPE i,
        c_count   TYPE string.
*TITLE AREA
  ls_header-typ = 'H'.
  IF p_pull EQ 'X'.
    ls_header-info = 'Pull Configuration from Remote System'(r01).
  ELSEIF p_push EQ 'X'.
    ls_header-info = 'Push Configuration to Remote System'(r02).
  ENDIF.
  APPEND ls_header TO lt_header.
*SOD Version.
  IF p_matrix EQ 'X'.
    ls_header-typ = 'S'.
    ls_header-key = 'Sod Version'(h03).
    ls_header-info = g_svrsio.
    APPEND ls_header TO lt_header.
  ENDIF.
*Errors
  CLEAR l_count.
  LOOP AT gt_log TRANSPORTING NO FIELDS
    WHERE type_icon = '@0A@'.
    ADD 1 TO l_count.
  ENDLOOP.
  c_count = l_count.
  ls_header-typ = 'S'.
  ls_header-key = 'Errors'(h05).
  ls_header-info = c_count.
  APPEND ls_header TO lt_header.
*Warnings
  CLEAR l_count.
  LOOP AT gt_log TRANSPORTING NO FIELDS
    WHERE type_icon = '@09@'.
    ADD 1 TO l_count.
  ENDLOOP.
  c_count = l_count.
  ls_header-typ = 'S'.
  ls_header-key = 'Warnings'(h06).
  ls_header-info = c_count.
  APPEND ls_header TO lt_header.

  IF p_test = 'X'.
    ls_header-typ  = 'A'.
    ls_header-info = 'Test run'(h07).
    APPEND ls_header TO lt_header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  build_fieldcat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM build_fieldcat
TABLES et_fieldcat TYPE slis_t_fieldcat_alv
USING  i_fieldname TYPE slis_fieldname
       i_icon      TYPE c
       i_seltext_m TYPE dd03p-scrtext_m.
  DATA: ls_fieldcat      TYPE slis_fieldcat_alv.

  ls_fieldcat-fieldname = i_fieldname.
  ls_fieldcat-tabname   = 'GT_LOG'.
  ls_fieldcat-icon      = i_icon.
  ls_fieldcat-seltext_m = i_seltext_m.
  APPEND ls_fieldcat TO et_fieldcat.

ENDFORM.                    " build_fieldcat
*&---------------------------------------------------------------------*
*&      Form  transfer_parameters
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_rfcdst TYPE rfcdes-rfcdest
*----------------------------------------------------------------------*
FORM transfer_parameters
USING i_rfcdst TYPE rfcdes-rfcdest.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_delete = p_deltar
      if_test   = p_test
    TABLES
      it_config = gt_config
      et_return = lt_return.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT lt_return INTO ls_return.
    PERFORM fill_log
    USING 'Configuration Parameter'(c04) "Configuration type
          l_source                       "Source System
          l_target                       "Target System
          ls_return.
  ENDLOOP.

ENDFORM.                    " transfer_parameters
*&---------------------------------------------------------------------*
*&      Form  read_configuration
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4888   text
*----------------------------------------------------------------------*
FORM read_configuration
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_config   TYPE flag
         ef_read_config TYPE flag.

  DATA: ls_config TYPE /psyng/se_config_param.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  ef_read_config = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
    DESTINATION l_rfcdst
    TABLES
      et_config = gt_config.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT gt_config INTO ls_config.
    IF ls_config-param IN s_confg[].
      CONTINUE.
    ENDIF.
    DELETE TABLE gt_config FROM ls_config.
  ENDLOOP.

  IF gt_config IS INITIAL.
    ef_ne_config = 'X'.
  ENDIF.

ENDFORM.                    " read_configuration
*&---------------------------------------------------------------------*
*&      Form  read_variable_element_rules
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_5055   text
*      <--P_LF_READ_VE  text
*----------------------------------------------------------------------*
FORM read_variable_element_rules
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_ve       TYPE flag
         ef_read_ve     TYPE flag.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  ef_read_ve = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_VE_RULES_READ'
    DESTINATION l_rfcdst
    EXPORTING
      if_ve_hdr      = p_ve_hdr
    TABLES
      it_ve_vrsio    = s_vevrs
      it_varel       = s_velemt
      et_ve_rule_ver = gt_ve_rule_ver
      et_ve_rules    = gt_ve_rules.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF  gt_ve_rules    IS INITIAL
  AND gt_ve_rule_ver IS INITIAL.
    ef_ne_ve = 'X'.
  ENDIF.
ENDFORM.                    " read_variable_element_rules
*&---------------------------------------------------------------------*
*&      Form  transfer_ve_rules
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4942   text
*----------------------------------------------------------------------*
FORM transfer_ve_rules
USING i_rfcdst TYPE rfcdes-rfcdest.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_VE_RULES_SAVE'
    DESTINATION l_rfcdst
    EXPORTING
      if_delete      = p_deltar
      if_test        = p_test
    TABLES
      it_ve_rule_ver = gt_ve_rule_ver
      it_ve_rules    = gt_ve_rules
      et_return      = lt_return.                "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  LOOP AT lt_return INTO ls_return.
    PERFORM fill_log
    USING 'Variable Element Rules'(c05) "Configuration type
          l_source                      "Source System
          l_target                      "Target System
          ls_return.
  ENDLOOP.

ENDFORM.                    " transfer_ve_rules
*&---------------------------------------------------------------------*
*&      Form  read_dynamic_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_RFCDST  text
*      <--P_LF_READ_DYNAM  text
*----------------------------------------------------------------------*
FORM read_dynamic_config
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_dynam    TYPE flag
         ef_read_dynam  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  ef_read_dynam = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_DYNCFG'
    DESTINATION l_rfcdst
    TABLES
      it_calling_tcode  = s_ctcode
      it_called_tcode   = s_ctcod1
      et_calling_tcodes = gt_calling_tcodes
      et_called_tcodes  = gt_called_tcodes.      "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF  gt_calling_tcodes IS INITIAL
  AND gt_called_tcodes  IS INITIAL.
    ef_ne_dynam = 'X'.
  ENDIF.

ENDFORM.                    " read_dynamic_config
*&---------------------------------------------------------------------*
*&      Form  transfer_dynamic_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4973   text
*----------------------------------------------------------------------*
FORM transfer_dynamic_config
USING i_rfcdst TYPE rfcdes-rfcdest.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_SAVE_DYNCFG'
    DESTINATION l_rfcdst
    EXPORTING
      if_delete         = p_deltar
      if_test           = p_test
    TABLES
      it_calling_tcodes = gt_calling_tcodes
      it_called_tcodes  = gt_called_tcodes
      et_return         = lt_return.             "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  LOOP AT lt_return INTO ls_return.
    PERFORM fill_log
      USING 'Dynamic Enhancement Config.'(c06)   "Configuration type
            l_source    "Source System
            l_target    "Target System
            ls_return.
  ENDLOOP.
ENDFORM.                    " transfer_dynamic_config
*&---------------------------------------------------------------------*
*&      Form  read_config_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_RFCDST  text
*      <--P_LF_READ_CNFSET  text
*----------------------------------------------------------------------*
FORM read_config_set
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_cnfset   TYPE flag
         ef_read_cnfset TYPE flag.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  ef_read_cnfset = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_API_I_GET_CONFIG_SET'
    DESTINATION l_rfcdst
    EXPORTING
      if_config_distri = 'X'
    TABLES
      it_config_set    = s_setid
      et_varel         = gt_varel
      et_systems       = gt_systems
      et_org           = gt_org
      et_elements      = gt_elements
      et_config_header = gt_config_header.       "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF  gt_varel         IS INITIAL
  AND gt_systems       IS INITIAL
  AND gt_org           IS INITIAL
  AND gt_elements      IS INITIAL
  AND gt_config_header IS INITIAL.
    ef_ne_cnfset = 'X'.
  ENDIF.

ENDFORM.                    " read_config_set
*&---------------------------------------------------------------------*
*&      Form  transfer_config_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_5022   text
*----------------------------------------------------------------------*
FORM transfer_config_set
USING i_rfcdst TYPE rfcdes-rfcdest.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG_SET'
    DESTINATION l_rfcdst
    EXPORTING
      if_delete        = p_deltar
      if_test          = p_test
    TABLES
      it_varel         = gt_varel
      it_systems       = gt_systems
      it_org           = gt_org
      it_elements      = gt_elements
      it_config_header = gt_config_header
      et_return        = lt_return.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  LOOP AT lt_return INTO ls_return.
    PERFORM fill_log
      USING 'Configuration Set'(c07)   "Configuration type
            l_source    "Source System
            l_target    "Target System
            ls_return.
  ENDLOOP.

ENDFORM.                    " transfer_config_set
*&---------------------------------------------------------------------*
*&      Form  f4_rule_versions
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_VAREL_VRSIO  text
*----------------------------------------------------------------------*
FORM f4_rule_versions CHANGING e_varel_vrsio
TYPE /psyng/sw_varvr-varel_vrsio.
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_varvr  TYPE TABLE OF /psyng/sw_varvr,
        ls_varvr  TYPE /psyng/sw_varvr.
*
  ls_fields-tabname   = '/PSYNG/SW_VARVR'.
  ls_fields-fieldname = 'VAREL_VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_rule_versions = 'X'
      TABLES
        et_rule_versions = lt_varvr.             "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_varvr
      FROM /psyng/sw_varvr.
  ENDIF.

  LOOP AT lt_varvr INTO ls_varvr.
    ls_values-line = ls_varvr-varel_vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_varvr-description.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VAREL_VRSIO'
*     callback_program = '/PSYNG/SW_145'
*     callback_form   = 'F4CALLBACK'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_varel_vrsio = ls_return-fieldval.
ENDFORM.                    " f4_rule_versions
*&---------------------------------------------------------------------*
*&      Form  f4_setid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_VAREL_VRSIO  text
*----------------------------------------------------------------------*
FORM f4_setid CHANGING e_setid
TYPE /psyng/swcfgset-setid.
  DATA: lt_values   TYPE TABLE OF ty_values,
        ls_values   TYPE ty_values,
        lt_fields   TYPE TABLE OF dfies,
        ls_fields   TYPE dfies,
        lt_return   TYPE TABLE OF ddshretval,
        ls_return   TYPE ddshretval,
        lt_setid    TYPE TABLE OF /psyng/setid_f4,
        ls_setid    TYPE /psyng/setid_f4,
        lt_swcfgset TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
        lt_swcfgsys TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE.

*
  ls_fields-tabname   = '/PSYNG/SETID_F4'.
  ls_fields-fieldname = 'SETID'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'PUBLISHED'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'DESCRIPTION'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'VAREL_VRSIO'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SYSTEM'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SODVRSIO'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_setid = 'X'
      TABLES
        et_setid = lt_setid.                     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT setid varel_vrsio published description sodvrsio
    INTO CORRESPONDING FIELDS OF TABLE lt_swcfgset
    FROM /psyng/swcfgset.

    IF NOT lt_swcfgset[] IS INITIAL.
      SELECT * FROM /psyng/swcfgsys INTO TABLE lt_swcfgsys
      FOR ALL ENTRIES IN lt_swcfgset
      WHERE setid = lt_swcfgset-setid.
    ENDIF.
*---Process them
    LOOP AT lt_swcfgset.
      MOVE-CORRESPONDING lt_swcfgset TO ls_setid.
      LOOP AT lt_swcfgsys WHERE setid = lt_swcfgset-setid.
        CONCATENATE ls_setid-system   ',' lt_swcfgsys-sysid
        INTO ls_setid-system SEPARATED BY space.
      ENDLOOP.
      ls_setid-system = ls_setid-system+2.
      APPEND ls_setid TO lt_setid.
      CLEAR ls_setid.
    ENDLOOP.
  ENDIF.

  SORT lt_setid DESCENDING BY setid.

  LOOP AT lt_setid INTO ls_setid.
    ls_values-line = ls_setid-setid.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-published.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-description.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-varel_vrsio.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-system.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_setid-sodvrsio.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SETID'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_setid = ls_return-fieldval.
ENDFORM.                                                    " f4_setid

*---------------------------------------------------------------------*
*       FORM f4callback_function                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_function
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/FUNCTION' TO ls_filter-shlpname,
    'VRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form

*---------------------------------------------------------------------*
*       FORM f4callback_conid                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_conid
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/CONFLICT' TO ls_filter-shlpname,
    'VRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form

*---------------------------------------------------------------------*
*       FORM f4callback_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  RECORD_TAB                                                    *
*  -->  SHLP                                                          *
*  -->  CALLCONTROL                                                   *
*---------------------------------------------------------------------*
FORM f4callback_auth
TABLES record_tab STRUCTURE seahlpres
CHANGING shlp TYPE shlp_descr_t
callcontrol LIKE ddshf4ctrl.

  DATA: ls_filter TYPE ddshselopt.

  MOVE: '/PSYNG/SWAUDHDR' TO ls_filter-shlpname,
    'VRSIO' TO ls_filter-shlpfield,
    'I'     TO ls_filter-sign,
    'EQ'    TO ls_filter-option,
    p_vrsio TO ls_filter-low.
  APPEND ls_filter TO shlp-selopt.

ENDFORM.                                                    "F4_form
*&---------------------------------------------------------------------*
*&      Form  F4_APP_AREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--  e_busarea text
*----------------------------------------------------------------------*
FORM f4_app_area  CHANGING e_busarea
TYPE /psyng/busarea-busarea.
  DATA: lt_values  TYPE TABLE OF ty_values,
        ls_values  TYPE ty_values,
        lt_fields  TYPE TABLE OF dfies,
        ls_fields  TYPE dfies,
        lt_return  TYPE TABLE OF ddshretval,
        ls_return  TYPE ddshretval,
        lt_busarea TYPE TABLE OF /psyng/busarea,
        ls_busarea TYPE /psyng/busarea.
*
  ls_fields-tabname   = '/PSYNG/BUSAREA'.
  ls_fields-fieldname = 'BUSAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TEXT'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_busarea = 'X'
      TABLES
        et_busarea = lt_busarea.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_busarea
      FROM /psyng/busarea.
  ENDIF.

  LOOP AT lt_busarea INTO ls_busarea.
    ls_values-line = ls_busarea-busarea.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_busarea-text.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BUSAREA'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_busarea = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_BUS_PROC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_busproc  text
*----------------------------------------------------------------------*
FORM f4_bus_proc  CHANGING e_busproc
TYPE /psyng/bus_proce-subarea.
  DATA: lt_values  TYPE TABLE OF ty_values,
        ls_values  TYPE ty_values,
        lt_fields  TYPE TABLE OF dfies,
        ls_fields  TYPE dfies,
        lt_return  TYPE TABLE OF ddshretval,
        ls_return  TYPE ddshretval,
        lt_busproc TYPE TABLE OF /psyng/bus_proce,
        ls_busproc TYPE /psyng/bus_proce.
*
  ls_fields-tabname   = '/PSYNG/BUS_PROCE'.
  ls_fields-fieldname = 'SUBAREA'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TEXT'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_subarea = 'X'
      TABLES
        et_subarea = lt_busproc.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  ELSE.
    SELECT * INTO TABLE lt_busproc
      FROM /psyng/bus_proce.
  ENDIF.

  LOOP AT lt_busproc INTO ls_busproc.
    ls_values-line = ls_busproc-subarea.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_busproc-text.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SUBAREA'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_busproc = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_SYS_TYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_sys_type  text
*----------------------------------------------------------------------*
FORM f4_sys_type  CHANGING e_sys_type
TYPE /psyng/sw_systyp-sys_type.
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_systyp TYPE TABLE OF /psyng/sw_systyp,
        ls_systyp TYPE /psyng/sw_systyp.
*
  ls_fields-tabname   = '/PSYNG/SW_SYSTYP'.
  ls_fields-fieldname = 'SYS_TYPE'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'SYS_DESCRIPTION'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_sys_type = 'X'
      TABLES
        et_sys_type = lt_systyp.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_systyp
      FROM /psyng/sw_systyp.
  ENDIF.

  LOOP AT lt_systyp INTO ls_systyp.
    ls_values-line = ls_systyp-sys_type.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_systyp-sys_description.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SYS_TYPE'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_sys_type = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_SYS_CAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_sys_cat  text
*----------------------------------------------------------------------*
FORM f4_sys_cat  CHANGING e_sys_cat
TYPE /psyng/sw_syscat-sys_category.
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_syscat TYPE TABLE OF /psyng/sw_syscat,
        ls_syscat TYPE /psyng/sw_syscat.
*
  ls_fields-tabname   = '/PSYNG/SW_SYSCAT'.
  ls_fields-fieldname = 'SYS_CATEGORY'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'CAT_DESCRIPTION'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_sys_cat = 'X'
      TABLES
        et_sys_cat = lt_syscat.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_syscat
      FROM /psyng/sw_syscat.
  ENDIF.

  LOOP AT lt_syscat INTO ls_syscat.
    ls_values-line = ls_syscat-sys_category.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_syscat-cat_description.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SYS_CATEGORY'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_sys_cat = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_RISK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_risk  text
*----------------------------------------------------------------------*
FORM f4_risk  CHANGING e_risk
TYPE /psyng/sw_risk-risk.
  DATA: lt_values TYPE TABLE OF ty_values,
        ls_values TYPE ty_values,
        lt_fields TYPE TABLE OF dfies,
        ls_fields TYPE dfies,
        lt_return TYPE TABLE OF ddshretval,
        ls_return TYPE ddshretval,
        lt_risk   TYPE TABLE OF /psyng/sw_risk,
        ls_risk   TYPE /psyng/sw_risk.
*
  ls_fields-tabname   = '/PSYNG/SW_RISK'.
  ls_fields-fieldname = 'RISK'.
  APPEND ls_fields TO lt_fields.
  ls_fields-fieldname = 'TEXT'.
  APPEND ls_fields TO lt_fields.

* Get values for popup
  IF NOT p_rfcdst IS INITIAL
  AND NOT p_pull IS INITIAL.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_REMOTE_SEARCH_HELPS'
      DESTINATION p_rfcdst
      EXPORTING
        if_risk = 'X'
      TABLES
        et_risk = lt_risk.                       "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ELSE.
    SELECT * INTO TABLE lt_risk
      FROM /psyng/sw_risk.
  ENDIF.

  LOOP AT lt_risk INTO ls_risk.
    ls_values-line = ls_risk-risk.
    APPEND ls_values TO lt_values.
    ls_values-line = ls_risk-text.
    APPEND ls_values TO lt_values.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'RISK'
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

  READ TABLE lt_return INTO ls_return INDEX 1.
  e_risk = ls_return-fieldval.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_BUSAREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->I_RFCDST  text
*      <--EF_NE_BUSAREA  text
*      <--EF_READ_BUSAREA  text
*----------------------------------------------------------------------*
FORM read_busarea
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_busarea    TYPE flag
         ef_read_busarea  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.
  l_rfcdst = i_rfcdst.
  ef_read_busarea = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_OTHER_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_read_busarea = 'X'
    TABLES
      it_busarea      = s_tapar
      et_busarea      = gt_busarea.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF  gt_busarea IS INITIAL.
    ef_ne_busarea = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TRANSFER_OTHER_CONFIG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_6119   text
*----------------------------------------------------------------------*
FORM transfer_other_config
USING i_rfcdst TYPE rfcdes-rfcdest
      i_config_name TYPE char10.

  DATA: lt_return TYPE TABLE OF bapiret2,
        ls_return TYPE bapiret2,
        l_source  TYPE rfcdest,
        l_target  TYPE rfcdest.

  DATA l_rfcdst TYPE rfcdest.

  l_rfcdst = i_rfcdst.

  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
    l_source = p_rfcdst.
    l_target = 'Local'(c08).
  ELSE.
    l_source = 'Local'(c08).
    l_target = l_rfcdst.
  ENDIF.

  CASE i_config_name.
    WHEN gc_application_area.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_SAVE_OTHER_CONFIG'
        DESTINATION l_rfcdst
        EXPORTING
          if_delete  = p_deltar
          if_test    = p_test
          if_busarea = 'X'
        TABLES
          it_busarea = gt_busarea
          et_return  = lt_return.                "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      LOOP AT lt_return INTO ls_return.
        PERFORM fill_log
          USING 'Application Area'(c09)   "Configuration type
                l_source    "Source System
                l_target    "Target System
                ls_return.
      ENDLOOP.
    WHEN gc_process_area.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_SAVE_OTHER_CONFIG'
        DESTINATION l_rfcdst
        EXPORTING
          if_delete  = p_deltar
          if_test    = p_test
          if_subarea = 'X'
        TABLES
          it_subarea = gt_subarea
          et_return  = lt_return.                "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      LOOP AT lt_return INTO ls_return.
        PERFORM fill_log
          USING 'Process Area'(c10)   "Configuration type
                l_source    "Source System
                l_target    "Target System
                ls_return.
      ENDLOOP.
    WHEN gc_risk.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_SAVE_OTHER_CONFIG'
        DESTINATION l_rfcdst
        EXPORTING
          if_delete = p_deltar
          if_test   = p_test
          if_risk   = 'X'
        TABLES
          it_risk   = gt_risk
          et_return = lt_return.                 "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      LOOP AT lt_return INTO ls_return.
        PERFORM fill_log
          USING 'Risk Scenario'(c11)   "Configuration type
                l_source    "Source System
                l_target    "Target System
                ls_return.
      ENDLOOP.
    WHEN gc_sys_type.
      CALL FUNCTION '/PSYNG/SW_SAVE_OTHER_CONFIG'
        DESTINATION l_rfcdst
        EXPORTING
          if_delete   = p_deltar
          if_test     = p_test
          if_sys_type = 'X'
        TABLES
          it_sys_type = gt_sys_type
          et_return   = lt_return.               "#EC SAST_CI_GEN_CHECK

      LOOP AT lt_return INTO ls_return.
        PERFORM fill_log
          USING 'System Type'(c12)   "Configuration type
                l_source    "Source System
                l_target    "Target System
                ls_return.
      ENDLOOP.
    WHEN gc_sys_cat.
      CALL FUNCTION '/PSYNG/SW_SAVE_OTHER_CONFIG'
        DESTINATION l_rfcdst
        EXPORTING
          if_delete  = p_deltar
          if_test    = p_test
          if_sys_cat = 'X'
        TABLES
          it_sys_cat = gt_sys_cat
          et_return  = lt_return.                "#EC SAST_CI_GEN_CHECK

      LOOP AT lt_return INTO ls_return.
        PERFORM fill_log
          USING 'System Category'(c13)   "Configuration type
                l_source    "Source System
                l_target    "Target System
                ls_return.
      ENDLOOP.
    WHEN OTHERS.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_SUBAREA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_RFCDST  text
*      <--ef_NE_SUBAREA  text
*      <--ef_READ_SUBAREA  text
*----------------------------------------------------------------------*
FORM read_subarea
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_subarea    TYPE flag
         ef_read_subarea  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.
  l_rfcdst = i_rfcdst.
  ef_read_subarea = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_OTHER_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_read_subarea = 'X'
    TABLES
      it_subarea      = s_tprocr
      et_subarea      = gt_subarea.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


  IF gt_subarea IS INITIAL.
    ef_ne_subarea = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_RISK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_RFCDST  text
*      <--ef_ne_risk  text
*      <--ef_read_risk  text
*----------------------------------------------------------------------*
FORM read_risk
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_risk    TYPE flag
         ef_read_risk  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.
  l_rfcdst = i_rfcdst.
  ef_read_risk = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_OTHER_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_read_risk = 'X'
    TABLES
      it_risk      = s_trisk
      et_risk      = gt_risk.                    "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF  gt_risk IS INITIAL.
    ef_ne_risk = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_SYSTEM_TYPE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_RFCDST  text
*      <--ef_ne_sys_type     text
*      <--ef_read_sys_type  text
*----------------------------------------------------------------------*
FORM read_sys_type
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_sys_type    TYPE flag
         ef_read_sys_type  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.
  l_rfcdst = i_rfcdst.
  ef_read_sys_type = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_OTHER_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_read_sys_type = 'X'
    TABLES
      it_sys_type      = s_tsyst
      et_sys_type      = gt_sys_type.            "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF  gt_sys_type IS INITIAL.
    ef_ne_sys_type = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  READ_SYS_CAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->i_RFCDST  text
*      <--ef_ne_sys_cat     text
*      <--ef_read_sys_cat  text
*----------------------------------------------------------------------*
FORM read_sys_cat
USING    i_rfcdst       TYPE rfcdes-rfcdest
CHANGING ef_ne_sys_cat    TYPE flag
         ef_read_sys_cat  TYPE flag.

  DATA l_rfcdst TYPE rfcdest.
  l_rfcdst = i_rfcdst.
  ef_read_sys_cat = 'X'.
  IF l_rfcdst IS INITIAL.
    l_rfcdst = 'NONE'.
  ENDIF.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_OTHER_CONFIG'
    DESTINATION l_rfcdst
    EXPORTING
      if_read_sys_cat = 'X'
    TABLES
      it_sys_cat      = s_tsysc
      et_sys_cat      = gt_sys_cat.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF  gt_sys_cat IS INITIAL.
    ef_ne_sys_cat = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  VALIDATE_SOD_VERSION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_sod_version .

  IF ( p_miti EQ 'X' OR
     p_matrix  EQ 'X' ) AND
     p_vrsio IS INITIAL.
    MESSAGE 'Please Enter SOD Version' TYPE 'E' DISPLAY LIKE 'I'.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.
