*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT_SYS_WIDE_ORG
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/sodreport_sys_wide_org MESSAGE-ID /psyng/sw
LINE-SIZE 132.
CLASS /psyng/sw_cl_constants DEFINITION LOAD.
TABLES: /psyng/conflict,
        /psyng/busarea,
        /psyng/bus_proce,
        /psyng/swsodorgm,
        /psyng/swresusr,
        rfcdes,
        ust04,
        usr21,
        /psyng/sw_uinfo,
        /psyng/ex_caobj_lock,
        usr05.
TABLES: usr02,agr_define.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_200.
*INCLUDE /psyng/sw_113 .
INCLUDE /psyng/sw_125.
INCLUDE /psyng/basis_exelog.

TYPE-POOLS: slis.                                      "For ALV call

* Max work processes controlled by Security Weaver
CONSTANTS: max_wp TYPE i VALUE '4'.
*Background job variables'
DATA: g_curr_variant         LIKE  rsvar-variant,
      g_vari_desc            TYPE varid OCCURS 0 WITH HEADER LINE,
      g_vari_contents        LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      g_vari_text            LIKE varit OCCURS 0 WITH HEADER LINE,
      gf_cfg_set_enabled     TYPE flag,
      gf_dflt_enhance_matrix TYPE flag,
      gf_mit_by_org          TYPE flag.

DATA: g_variant LIKE vari-variant.
DATA: gs_variant TYPE disvariant.
DATA : g_varexist     TYPE c VALUE space.
*global variables
DATA: gt_irsparams         TYPE rsparams OCCURS 0 WITH HEADER LINE,
      g_repeat_hdr_bkgdjob TYPE flag,
      gf_pages             TYPE i,
      g_options_set        TYPE flag,
      g_tabname            TYPE dd02l-tabname,
      g_usrpar TYPE usr05-parid.

DATA : gt_output TYPE TABLE OF /psyng/sw_sod_output_org.
DATA : gt_mcuser  TYPE TABLE OF /psyng/mitigation_assignment
       WITH HEADER LINE,
       gt_rfcdes  TYPE TABLE OF rfcdes WITH HEADER LINE,
       gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE.
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      g_alv_layout    TYPE slis_layout_alv,            "For ALV call
      g_alv_grid_titl TYPE lvc_title.                  "For ALV call
DATA: g_program      LIKE sy-repid,                   "For ALV call
      g_exit_proc,
      gf_central_uid TYPE flag.

DATA: gt_isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA: sel(1)        TYPE c,           "selected row by user in ALV grid
      class         LIKE usr02-class,
      company       LIKE /psyng/sw_uinfo-company,
      compshort     LIKE /psyng/sw_uinfo-company,
      department    LIKE /psyng/sw_uinfo-department,
      central_uid   LIKE /psyng/sw_uinfo-central_uid,
      ustyp         LIKE usr02-ustyp,
      bname         LIKE ust04-bname,
      name_text     LIKE adrp-name_text,
      conid         LIKE /psyng/conflict-conid,
      description   LIKE /psyng/conflict-description,
      imp           LIKE /psyng/1stoutput_u-imp,
      impsort       TYPE n,
      contid        LIKE /psyng/1stoutput_u-contid,
      inactive      LIKE /psyng/mchdr-inactive,
      auditor       LIKE /psyng/mcuser-auditor,
      from_date     LIKE /psyng/mcuser-from_date,
      to_date       LIKE /psyng/mcuser-to_date,
      mit_icon      LIKE icon-id,
      enhanced      TYPE c, "flag for enhanced ruleset
      simu          TYPE c, "flag for simulated conflict
      er            TYPE c, "flag for ER conflict
      origin(12)    TYPE c, "LOCAL/REMOTE/CROSS
      level2        TYPE c,
      level3        TYPE c,
      level4        TYPE c,
      simu_after    TYPE c,
      simu_before   TYPE c,
      abb           LIKE /psyng/sw_sod_output_org-org_abb,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF 1stoutput.

TYPES: BEGIN OF ty_1stoutput,
  sel(1)        TYPE c,           "selected row by user in ALV grid
      class         LIKE usr02-class,
      company       LIKE /psyng/sw_uinfo-company,
      compshort     LIKE /psyng/sw_uinfo-company,
      department    LIKE /psyng/sw_uinfo-department,
      central_uid   LIKE /psyng/sw_uinfo-central_uid,
      ustyp         LIKE usr02-ustyp,
      bname         LIKE ust04-bname,
      name_text     LIKE adrp-name_text,
      conid         LIKE /psyng/conflict-conid,
      description   LIKE /psyng/conflict-description,
      imp           LIKE /psyng/1stoutput_u-imp,
      impsort       TYPE n,
      contid        LIKE /psyng/1stoutput_u-contid,
      inactive      LIKE /psyng/mchdr-inactive,
      auditor       LIKE /psyng/mcuser-auditor,
      from_date     LIKE /psyng/mcuser-from_date,
      to_date       LIKE /psyng/mcuser-to_date,
      mit_icon      LIKE icon-id,
      enhanced      TYPE c, "flag for enhanced ruleset
      simu          TYPE c, "flag for simulated conflict
      er            TYPE c, "flag for ER conflict
      origin(12)    TYPE c, "LOCAL/REMOTE/CROSS
      level2        TYPE c,
      level3        TYPE c,
      level4        TYPE c,
      simu_after    TYPE c,
      simu_before   TYPE c,
      abb           LIKE /psyng/sw_sod_output_org-org_abb,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol,  " Cell color
  END OF ty_1stoutput,

  tt_1stoutput TYPE TABLE OF ty_1stoutput.

*  BOC AKUMAR User nationality PN11272
TYPES: BEGIN OF ty_usrpar,
         parid TYPE usr05-parid,
         parva TYPE /psyng/parva_tt,
       END OF ty_usrpar.
*  EOC AKUMAR User nationality PN11272

*BOC:HBHALLA (PN-4550) (11/07/25)
TYPES: BEGIN OF ty_values ,
         line(255) TYPE c.
TYPES :       END OF ty_values.
*EOC:HBHALLA (PN-4550) (11/07/25)

DATA:  1stoutput1 TYPE TABLE OF ty_1stoutput.

*--Table with users per conflict
DATA: BEGIN OF gs_userpercon_output.
DATA: conid       LIKE /psyng/conflict-conid,
      description LIKE /psyng/conflict-description,
      imp         LIKE /psyng/1stoutput_u-imp,
      impsort     TYPE n,
      numusers    TYPE i,
      abb         LIKE /psyng/sw_sod_output_org-org_abb.
DATA: END OF gs_userpercon_output.
DATA : gt_userpercon_output LIKE SORTED TABLE OF gs_userpercon_output
WITH UNIQUE KEY conid description impsort imp abb
WITH HEADER LINE.
DATA: BEGIN OF user_info OCCURS 0,
        bname TYPE usr02-bname,
        class TYPE usr02-class,
      END OF user_info.

DATA: BEGIN OF it_conid OCCURS 0,
        conid TYPE /psyng/conflict-conid,
        owner TYPE /psyng/conflict-owner,
      END OF it_conid.

DATA : gt_conid TYPE TABLE OF /psyng/sw_sel_opts_conid.
DATA: wa_conid     TYPE /psyng/sw_sel_opts_conid,
      g_button_set TYPE flag.

DATA: gt_enh_con LIKE STANDARD TABLE OF /psyng/sw_enh_usr_con INITIAL
SIZE 0 WITH HEADER LINE.
DATA: tusercount TYPE i.
DATA: gt_simuagrs LIKE STANDARD TABLE OF /psyng/sw_sod_remote_roles
INITIAL
 SIZE 0 WITH HEADER LINE.
DATA: gt_fields           TYPE rfc_db_fld OCCURS 0 WITH HEADER LINE,
      gt_data             TYPE tab512 OCCURS 0 WITH HEADER LINE,
      data_agrs           TYPE tab512 OCCURS 0 WITH HEADER LINE,
      gf_hide_org         TYPE /psyng/bapiflagx,
      gf_use_sec_obj      TYPE c,
      gf_company_longtext TYPE /psyng/bapiflagx,

      gf_st_missing_auth  TYPE /psyng/bapiflagx,
      lt_conowner         TYPE TABLE OF /psyng/conowner WITH HEADER LINE
      ,
      lt_cuscon           TYPE TABLE OF /psyng/sw_cuscon WITH HEADER
      LINE,
      lt_conpmit          TYPE TABLE OF /psyng/conpmit WITH HEADER LINE,
      gf_missing_auth     TYPE flag,
      g_ucomm             LIKE sy-ucomm,
      gt_removed_roles    TYPE TABLE OF /psyng/sw_removed_roles
      WITH HEADER LINE.
*--Global Data for Removed Roles Popup
DATA : gr_alvgrid             TYPE REF TO cl_gui_alv_grid,
       gc_custom_control_name TYPE scrfname VALUE 'CC_ALV',
       gr_ccontainer          TYPE REF TO cl_gui_custom_container,
       gt_fieldcat            TYPE lvc_t_fcat,
       gs_layout              TYPE lvc_s_layo.

DATA : gt_mchdr            TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
       g_rfcdest_local     TYPE rfcdes-rfcdest,
       g_mit_message,
       g_tcode_exe_message,
       gf_out_nohienh(1)   TYPE c,
       gf_showpcom(1)      TYPE c,
       g_warnig_msg(1)     TYPE c,
       g_preconfig         TYPE /psyng/swcfgset-setid,
       g_dynnr             TYPE sy-dynnr,
       gt_usrfields           TYPE TABLE OF dfies, "HBHALLA
       gs_usrfields           TYPE dfies, "HBHALLA
       gt_usrvalues           TYPE TABLE OF ty_values, "HBHALLA
       gs_usrvalues           TYPE ty_values, "HBHALLA
       gt_return_tab       TYPE TABLE OF ddshretval, "HBHALLA
       gs_return_tab       TYPE ddshretval.          "HBHALLA

DATA :
  lt_rpoug_auth_fail    TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
  gf_auth_fail          TYPE /psyng/bapiflagx,
  gt_role_addition_simu TYPE TABLE OF /psyng/sw_role_addition_simu
  WITH HEADER LINE,
  gt_role_removal_simu  TYPE TABLE OF /psyng/sw_role_removal_simu
  WITH HEADER LINE,
  gt_role_addition_simu_en TYPE TABLE OF /psyng/ex_role_addition_simu
  WITH HEADER LINE,
 gs_role_addition_simu_en TYPE  /psyng/ex_role_addition_simu,
  gt_role_removal_simu_en  TYPE TABLE OF  /psyng/en_role_removal_simu
  WITH HEADER LINE,
  gs_role_removal_simu_en TYPE /psyng/en_role_removal_simu,
  gf_first_time         TYPE flag,
  l_appl                TYPE /psyng/application,
  lf_set_invalid        TYPE flag,
  lf_set_nocover        TYPE flag,
  lf_set_mismatch       TYPE flag,
  gf_use_ta_drilldown   TYPE flag.
DATA:
  g_installed      TYPE /psyng/bapiflagx,
  g_rev_mapping      TYPE /psyng/param_value, "HBHALLA (PN-4769)
  g_module_version TYPE  /psyng/prog_vrsio,
  g_swconfig       TYPE /psyng/swconfig,
  g_am_installed   TYPE flag,
  gf_its           TYPE flag, "called from webserver
  lf_include_local TYPE flag,
  g_current_user   TYPE sy-uname, "C0700
  g_usr_seloption   TYPE /psyng/xubname,
  gt_selscrpar TYPE TABLE OF rsparams, "C1102
  gt_usrpar        TYPE TABLE OF ty_usrpar,
  gt_en_userlist TYPE TABLE OF /psyng/range_bname,"HBHALLA(PN-4774)
  gs_usrpar        TYPE ty_usrpar.
FIELD-SYMBOLS : <fs_role_addtion> TYPE /psyng/ex_role_addition_simu,
               <fs_role_removal> TYPE  /psyng/en_role_removal_simu.
*DATA: usertype TYPE /psyng/xuustyp.
DATA : g_org_field TYPE flag.                               "opl645 GG
DATA : ls_state TYPE /psyng/usr_displ. "HBHALLA(PN-17036)(05/01/26)

*---User Block
SELECTION-SCREEN: BEGIN OF BLOCK user_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) user_but USER-COMMAND user_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

*SELECT-OPTIONS: userlist FOR g_usr_seloption "usr02-bname
SELECT-OPTIONS: userlist FOR usr02-bname
                       MODIF ID usr,
                pclass   FOR usr02-class           MODIF ID usr.
SELECT-OPTIONS  s_usrpar FOR usr05-parva        MODIF ID usr.
"AKUMAR PN11272
SELECT-OPTIONS:
                s_comp   FOR 1stoutput-company     MODIF ID usr,
                s_depart FOR 1stoutput-department  MODIF ID usr,
                s_cuid   FOR  /psyng/sw_uinfo-central_uid
                                                   MODIF ID usr,
                s_kostl  FOR /psyng/swresusr-kostl MODIF ID usr
                MATCHCODE OBJECT /psyng/kostl,
                s_role   FOR agr_define-agr_name   MODIF ID usr,
                s_prof   FOR ust04-profile         MODIF ID usr.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: END OF BLOCK user_o.
*  ---Conflict Block
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
PARAMETERS:   cuscon AS CHECKBOX DEFAULT ' ' MODIF ID con
USER-COMMAND cus_con .
*  Version selection
PARAMETERS:  sodvrsio LIKE /psyng/conflict-vrsio
MEMORY ID /psyng/vrsio                  MODIF ID con.
* Configuration Set Selection
PARAMETERS : cfgset   TYPE /psyng/seconfid MODIF ID con.
SELECTION-SCREEN: END OF BLOCK con_o.

*---Remote Block
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) rem_but
  USER-COMMAND rem_but .
*Parameter : p_se type flag defa
SELECTION-SCREEN COMMENT 16(50) text-b02 .
*  --Conflict origin
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-170    MODIF ID rem.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X' MODIF ID rem.
SELECTION-SCREEN COMMENT 24(10) text-173 FOR FIELD p_local
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag DEFAULT ' '
                                          MODIF ID rem.
SELECTION-SCREEN COMMENT 37(10) text-174 FOR FIELD p_remote
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag DEFAULT ' ' MODIF ID rem.
SELECTION-SCREEN COMMENT 51(20) text-175 FOR FIELD p_cross
                                           MODIF ID rem.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN : POSITION 04.
PARAMETERS : p_locusr AS CHECKBOX          MODIF ID rem.
SELECTION-SCREEN COMMENT 8(45) text-162 FOR FIELD p_locusr
                                           MODIF ID rem.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
*  Only analyze remote systems
SELECTION-SCREEN : POSITION 04.
PARAMETERS : p_remonl AS CHECKBOX USER-COMMAND remo
                                           MODIF ID rem.
SELECTION-SCREEN COMMENT 8(45) text-179 FOR FIELD p_remonl
                                           MODIF ID rem.
SELECTION-SCREEN END OF LINE.

PARAMETERS p_abap AS CHECKBOX USER-COMMAND abap DEFAULT 'X'
                                   MODIF ID rem."EN.

SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.

PARAMETERS p_nabap AS CHECKBOX USER-COMMAND abap MODIF ID rem."EN.
SELECT-OPTIONS: s_appl FOR l_appl
MATCHCODE OBJECT
/psyng/ex_application MEMORY ID /psyng/application
MODIF ID rem."EN.

SELECT-OPTIONS: s_system FOR /psyng/ex_caobj_lock-sysid
MATCHCODE OBJECT
/psyng/ex_system MEMORY ID /psyng/system
MODIF ID rem."EN
SELECTION-SCREEN: END OF BLOCK rem_o.
*--Simulation Block
SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME.
SELECTION-SCREEN PUSHBUTTON  01(6) simu_but USER-COMMAND simu_but.
SELECTION-SCREEN COMMENT 16(50) text-b06 .
SELECTION-SCREEN INCLUDE BLOCKS b_sim.
SELECTION-SCREEN PUSHBUTTON  01(6) esm_but USER-COMMAND esm_but.
SELECTION-SCREEN COMMENT 16(50) text-b10 .
SELECTION-SCREEN INCLUDE BLOCKS e_sim.
SELECTION-SCREEN: END OF BLOCK sim_o.


*--SOD Live Block
SELECTION-SCREEN: BEGIN OF BLOCK live_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) liv_but USER-COMMAND liv_but.
SELECTION-SCREEN COMMENT 16(50) text-b08 .
SELECTION-SCREEN INCLUDE BLOCKS b_live.
SELECTION-SCREEN: END OF BLOCK live_o.



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
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shotree   RADIOBUTTON GROUP g6 MODIF ID out.
SELECTION-SCREEN: COMMENT 4(55) text-o61 FOR FIELD shotree
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shosimp   RADIOBUTTON GROUP g6 MODIF ID out.
SELECTION-SCREEN: COMMENT 4(55) text-o62 FOR FIELD shosimp
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK res.

*-- Layout Selection
SELECTION-SCREEN: BEGIN OF BLOCK layo WITH FRAME TITLE text-o63.
PARAMETERS: p_layo TYPE slis_vari MODIF ID out.
PARAMETERS: p_dlayo TYPE slis_vari MODIF ID out.
PARAMETERS: p_slayo TYPE slis_vari MODIF ID out.
SELECTION-SCREEN: END OF BLOCK layo.


PARAMETERS:
  xmc      AS CHECKBOX DEFAULT ' ' MODIF ID out,
  shonosod AS CHECKBOX DEFAULT ' ' MODIF ID out
             USER-COMMAND nosod,
  pcolor   AS CHECKBOX DEFAULT ' ' MODIF ID out
             USER-COMMAND pcolor,
  showcomp AS CHECKBOX DEFAULT ' ' MODIF ID out
             USER-COMMAND showcomp,
  showpcom AS CHECKBOX DEFAULT ' ' MODIF ID out,
  odt      AS CHECKBOX DEFAULT 'X' MODIF ID out.

SELECTION-SCREEN: END OF BLOCK out_o.
*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 16(50) text-b05.
PARAMETERS :
  erroles AS CHECKBOX DEFAULT ' ' MODIF ID exe USER-COMMAND er1,
  excl_er AS CHECKBOX DEFAULT ' ' MODIF ID exe USER-COMMAND er2,
  ustb    AS CHECKBOX DEFAULT ' '     MODIF ID exe,
  orgchk  AS CHECKBOX DEFAULT ' ' USER-COMMAND org
                                   MODIF ID exe.
SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb
                                   MODIF ID exe.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 3(27) text-085 FOR FIELD p_enhanc
                                   MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 34(45) text-086 FOR FIELD p_hienhn
                                   MODIF ID exe.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe_o.


*---Technical Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK txe_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) txe_but USER-COMMAND txe_but.
SELECTION-SCREEN COMMENT 16(50) text-b09.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0' MODIF ID txe.

SELECTION-SCREEN: COMMENT 3(65) text-008
                                    MODIF ID txe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : defgrp TYPE flag  RADIOBUTTON GROUP ppro DEFAULT 'X'
                                    MODIF ID txe.
SELECTION-SCREEN: COMMENT 3(27) text-090 FOR FIELD defgrp
                                    MODIF ID txe.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : specgrp TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID txe.
SELECTION-SCREEN: COMMENT 3(27) text-089 FOR FIELD specgrp
                                   MODIF ID txe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pgroup TYPE rzlli_apcl MODIF ID txe.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS : specsrv TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID txe.
SELECTION-SCREEN: COMMENT 3(27) text-088 FOR FIELD specsrv
                                   MODIF ID txe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pserver LIKE msxxlist-name MODIF ID txe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  30(20) text-002 USER-COMMAND gpsv
                                       MODIF ID txe.
SELECTION-SCREEN: END OF LINE.
PARAMETERS : upp TYPE i                MODIF ID txe.

SELECTION-SCREEN: END OF BLOCK txe_o.


*---Background Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b07 .
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-001.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-019 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-020 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN: END OF BLOCK cblk.

SELECTION-SCREEN: END OF BLOCK bgd_o.
*--Hidden parameters
*-- These parameters has to be used in Auth Help only
PARAMETERS : p_locsod TYPE flag    NO-DISPLAY DEFAULT 'X',
*            RFC Destination to read SOD Matrix from
             p_sodrfc TYPE rfcdest NO-DISPLAY,
             p_first  TYPE flag    NO-DISPLAY,
             p_upc    TYPE flag    NO-DISPLAY,
             p_its    TYPE flag    NO-DISPLAY, "called from its
             p_lvl3   TYPE flag    NO-DISPLAY.

LOAD-OF-PROGRAM.
  p_first = 'X'.
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
  se_config_param 'USR_PARAM_FIELD_NAME' g_usrpar.
  se_config_param   'SOD_REV_USR_MAPPING' g_rev_mapping. "HBHALLA
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
    EXPORTING
      i_repid = '/PSYNG/SODREPORT_SYS_WIDE_ORG'.

  PERFORM set_button_icons.
  PERFORM get_initial_config.
  g_program = sy-repid.

**--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.
*--Check if conflicts should be reported by Org Area
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.
  IF gf_mit_by_org = 'X' OR gf_mit_by_org = 'Y'.
    gf_mit_by_org = 'X'.
  ELSE.
    CLEAR gf_mit_by_org.
  ENDIF.
*  GG opl645 start
  se_config_param 'CONSIDER_ORG_FIELD' g_org_field .
  IF g_org_field EQ 'Y' OR g_org_field EQ 'X'.
    g_org_field = 'X'.
  ELSE.
    CLEAR g_org_field.
  ENDIF.
*  GG opl645 end

*Begin of change:HBHALLA (PN-17036) (05/01/26)
  CLEAR g_swconfig.
  se_config_param 'EN_INTEGRATION' g_swconfig-value.

 IF g_swconfig-value <> 'Y'.
    CLEAR  ls_state-expanded.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = 'ESM_BUT'.
  ls_state-group_name  = 'ESM_BUT'.
  ls_state-ucomm       = 'ESM_BUT'.

  PERFORM collapse USING esm_but.

  MODIFY /psyng/usr_displ FROM ls_state.
  IF sy-subrc = 0.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
  ENDIF.
 ENDIF.
*End of change:HBHALLA (PN-17036) (05/01/26)

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_local.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_remote.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_cross.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-low.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-high.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-low.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-high.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.

*BOC:HBHALLA (PN-4550) (11/07/25)
AT SELECTION-SCREEN ON VALUE-REQUEST FOR userlist-low.
  PERFORM userlist_value_low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR userlist-high.
  PERFORM userlist_value_high.
*EOC:HBHALLA (PN-4550) (11/07/25)

AT SELECTION-SCREEN.

  IF sy-ucomm = 'ADVSIM'.              "#EC SAST_CI_GEN_CHECK (HBHALLA)
    CALL FUNCTION '/PSYNG/SW_080'
      TABLES
        et_bname = userlist.
    EXIT.
  ENDIF.

*--check warning msg for config set & versio
  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    IF sy-ucomm IS INITIAL.
      lf_include_local = 'X'.
      IF p_remonl = 'X'.
        CLEAR lf_include_local.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid         = cfgset
          i_vrsio         = sodvrsio
          if_show_warning = 'X'
          if_local_system = lf_include_local
        TABLES
          it_rfcdest      = xusrrfc.
    ENDIF.
  ENDIF.

  PERFORM check_input.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
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



  CONCATENATE sy-sysid sy-mandt INTO g_rfcdest_local.
*-- if enter Target RFC on Add or RFC Destination for Role on Removal
*--and if do not have "Cross System (RFC)" entered then provide error

  IF  bysimu = 'X' AND xusrrfc[] IS INITIAL.

    IF NOT ar_rfcd1 IS INITIAL
        AND NOT ar_rfcd1 = 'LOCAL'
        AND NOT ar_rfcd1 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT ar_rfcd2 IS INITIAL
        AND NOT ar_rfcd2 = 'LOCAL'
        AND NOT  ar_rfcd2 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT ar_rfcd3 IS INITIAL
         AND NOT ar_rfcd3 = 'LOCAL'
        AND NOT  ar_rfcd3 = g_rfcdest_local .
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT ar_rfcd4 IS INITIAL
         AND NOT ar_rfcd4 = 'LOCAL'
        AND NOT  ar_rfcd4 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.
  ENDIF.

  IF byrsimu = 'X' AND xusrrfc[] IS INITIAL.
    IF NOT rr_rfc_1 IS INITIAL
         AND NOT rr_rfc_1 = 'LOCAL'
        AND NOT  rr_rfc_1 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT rr_rfc_2 IS INITIAL
         AND NOT rr_rfc_2 = 'LOCAL'
        AND NOT  rr_rfc_2 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT rr_rfc_3 IS INITIAL
         AND NOT rr_rfc_3 = 'LOCAL'
        AND NOT  rr_rfc_3 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

    IF NOT rr_rfc_4 IS INITIAL
         AND NOT rr_rfc_4 = 'LOCAL'
        AND NOT  rr_rfc_4 = g_rfcdest_local.
      MESSAGE w140 WITH text-201.
    ENDIF.

  ENDIF.



  LOOP AT SCREEN.
*--Disable Show no SOD when conflict ID's are restricted
    IF  screen-name CS 'SPCONFS'
    OR screen-name CS 'S_RISK'
    OR screen-name CS 'COWNER'
    OR screen-name CS 'PAPPA'
    OR screen-name CS 'CPRMIT'
    OR screen-name CS 'CSENS'
    OR screen-name CS 'PROCA'.
      IF NOT spconfs[] IS INITIAL OR
           NOT s_risk[] IS INITIAL  OR
           NOT cowner[] IS INITIAL  OR
           NOT pappa[] IS INITIAL   OR
           NOT cprmit[] IS INITIAL  OR
           NOT csens[] IS INITIAL OR
           NOT proca[] IS INITIAL.
        IF shonosod = 'X'.
          MESSAGE s002 WITH 'Showing user without conflict not allowed'.
          STOP.
        ENDIF.
      ENDIF.
    ENDIF.
    IF screen-name = 'P_NABAP' .
      IF p_nabap = 'X' AND p_abap <> 'X'.
        IF showcomp = 'X'.
          CLEAR showcomp.
          MESSAGE w002 WITH text-013 text-014.
          STOP.
        ENDIF.
      ENDIF.
      IF p_nabap = 'X'.
        IF p_enhanc = 'X'.
          CLEAR p_enhanc.
          MESSAGE w002 WITH text-015 text-014.
          STOP.
        ENDIF.
        IF p_hienhn = 'X'.
          CLEAR p_hienhn.
          MESSAGE w002 WITH text-015 text-014.
          STOP.
        ENDIF.
        IF orgchk = 'X' AND p_nabap = 'X'.
          CLEAR p_nabap.
          MESSAGE w002 WITH text-022 text-014.
          STOP.
        ENDIF.
        IF cuscon = 'X'.
          CLEAR cuscon.
          MESSAGE w002 WITH text-016 text-014.
          STOP.
        ENDIF.
        IF byrsimu = 'X' AND p_abap <> 'X' AND p_nabap = 'X'.
          CLEAR byrsimu.
          MESSAGE w002 WITH text-018 text-014.
          STOP.
        ENDIF.
        IF lvl3 = 'X' OR lvl2 = 'X'.
          CLEAR:lvl2,lvl3.
          lvl1 = 'X'.
          MESSAGE w002 WITH text-021 text-014.
          STOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

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

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_layo.
  PERFORM f4_alv_variant CHANGING p_layo.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_dlayo.
  PERFORM f4_dalv_variant CHANGING p_dlayo.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_slayo.
  PERFORM f4_alv_variant CHANGING p_slayo.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_usrpar-low.
  PERFORM f4_usrpar USING 'S_USRPAR-LOW' CHANGING s_usrpar-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_usrpar-high.
  PERFORM f4_usrpar USING 'S_USRPAR-HIGH' CHANGING s_usrpar-high.


AT SELECTION-SCREEN OUTPUT.

*--Check if Configuration Set functionality is enabled.
*  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
*    gf_cfg_set_enabled = 'X'.
    IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio      = 'X'
          i_cfgvrsio   = sodvrsio
        IMPORTING
          e_config_set = cfgset.
    ENDIF.
*  ELSE.
*    CLEAR gf_cfg_set_enabled.
  ENDIF.

  PERFORM handle_button.
  PERFORM handle_sections.
*-- Check EN integeration parmaeter
  CLEAR g_swconfig.
  se_config_param 'EN_INTEGRATION' g_swconfig-value.

*--Check if ER is installed/ deactivate ER buttons
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'ER'
    IMPORTING
      e_installed      = g_installed
      e_module_version = g_module_version.
  IF g_installed EQ 'X'.
    IF  g_module_version CP '*Q*'.
      LOOP AT SCREEN.
        IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
          screen-input = 1.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ELSEIF g_module_version < '3.0'.
      LOOP AT SCREEN.
        IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
          screen-input = 0.
          MODIFY SCREEN.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ELSE.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-input = 0.
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
*-- Check if AM is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module    = 'AM'
    IMPORTING
      e_installed = g_am_installed.




  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN '001'.
        AUTHORITY-CHECK OBJECT 'S_BTCH_ADM'
        ID 'BTCADMIN' FIELD 'Y'.
        IF sy-subrc <> 0.
          screen-invisible = '1'.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'LIV'.
        CASE screen-name.

*--LEVEL 2 or 3  : Show all level 2  options
          WHEN 'HIDESTD'  OR 'B_LIV2'.
            IF lvl1 = 'X'.
              screen-invisible = 1.
              screen-active    = 0.
              CLEAR hidestd.
            ELSE.
              IF liv_but(3) = '@3T'.
                screen-invisible = 0.
                screen-active    = 1.
              ENDIF.
            ENDIF.
            MODIFY SCREEN.
*--It doesn't seem possible to hide the comments attached to these dates
*  so we don't hide but disable
          WHEN  'LVL2ST' OR 'LVL2ED'.
            IF lvl1 = 'X'.
*              screen-invisible = 1.
              screen-input    = 0.
*                CLEAR: lvl2st,lvl2ed.
            ELSE.
*              screen-invisible = 0.
              screen-input    = 1.
            ENDIF.
            MODIFY SCREEN.
*--LEVEL 3 : Show all level 3 and three options
          WHEN  'LVL3_CD' OR 'LVL3_TL'.
            IF lvl3 <> 'X'.
              screen-invisible = 1.
              screen-active    = 0.
            ELSE.
              IF liv_but(3) = '@3T'.
                screen-invisible = 0.
                screen-active    = 1.
              ENDIF.
            ENDIF.
            MODIFY SCREEN.
        ENDCASE.

*        ENDIF.
    ENDCASE.
    IF screen-name = 'P_NABAP' OR screen-name = 'P_ABAP'
    OR screen-name = '%_P_ABAP_%_APP_%-TEXT'
    OR screen-name = '%_P_NABAP_%_APP_%-TEXT'
    OR screen-name = 'S_APPL-LOW'
    OR screen-name = 'S_APPL-HIGH'
    OR screen-name = '%_S_APPL_%_APP_%-TEXT'
*   OR screen-name = '%_S_APPL_%_APP_%-OPTI_PUSH'
    OR screen-name =  '%_S_APPL_%_APP_%-VALU_PUSH'
    OR screen-name =  '%_S_SYSTEM_%_APP_%-TEXT'

    OR screen-name = 'S_SYSTEM-LOW'
    OR screen-name = 'S_SYSTEM-HIGH'
*   OR screen-name = '%_S_SYSTEM_%_APP_%-OPTI_PUSH'
    OR screen-name = '%_S_SYSTEM_%_APP_%-VALU_PUSH'
    OR screen-name = 'EBYSIMU'

    OR screen-name = 'AR_SYSS1'
    OR screen-name = 'AR_SYSD1'
    OR screen-name = 'AE_ROL_1-LOW'
    OR screen-name = 'AE_ROL_1-HIGH'

    OR screen-name = 'AR_SYSS2'
    OR screen-name = 'AR_SYSD2'
    OR screen-name = 'AE_ROL_2-LOW'
    OR screen-name = 'AE_ROL_2-HIGH'

    OR screen-name = 'AR_SYSS3'
    OR screen-name = 'AR_SYSD3'
    OR screen-name = 'AE_ROL_3-LOW'
    OR screen-name = 'AE_ROL_3-HIGH'

    OR screen-name = 'AR_SYSS4'
    OR screen-name = 'AR_SYSD4'
    OR screen-name = 'AE_ROL_4-LOW'
    OR screen-name = 'AE_ROL_4-HIGH'



     OR screen-name = 'EBRSIMU'
     OR screen-name = 'RR_SYS_1'
     OR screen-name = 'EN_ROL_1-LOW'
     OR screen-name = 'EN_ROL_1-HIGH'
     OR screen-name = 'RR_SYS_2'
     OR screen-name = 'EN_ROL_2-LOW'
     OR screen-name = 'EN_ROL_2-HIGH'
     OR screen-name = 'RR_SYS_3'
     OR screen-name = 'EN_ROL_3-LOW'
     OR screen-name = 'EN_ROL_3-HIGH'
     OR screen-name = 'RR_SYS_4'
     OR screen-name = 'EN_ROL_4-LOW'
     OR screen-name = 'EN_ROL_4-HIGH'
    .
      screen-group2 = 'EN'.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name = 'LVL4'.
      IF g_am_installed <> 'X'.
        screen-invisible = 1.
        screen-active    = 0.
        CLEAR lvl4.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.


*---- Hide Standard Conflict on Level 2 and 3
    IF screen-name = 'HIDESTD'.
      IF lvl2 = 'X' OR lvl3 = 'X' OR lvl4 = 'X'.
        IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
          screen-active = 0.
          CLEAR : hidestd.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDIF.

**-- Layout selection
*-- Summary Layout
    IF screen-name CS 'P_LAYO'.
      IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
        screen-active = 0.
        CLEAR : p_layo.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

*-- Detail Layout
    IF screen-name CS 'P_DLAYO'.
      IF shosum = 'X' OR shotree = 'X' OR shosimp = 'X'.
        screen-active = 0.
        CLEAR : p_dlayo.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
*-- Simplified view Layout
    IF screen-name CS 'P_SLAYO'.
      IF shosum = 'X' OR shotree = 'X' OR shodet = 'X'.
        screen-active = 0.
        CLEAR : p_slayo.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    CASE screen-name.

      WHEN 'P_LOCAL' OR 'P_REMOTE' OR 'P_CROSS'.
        IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
          screen-input = 0.
*          Commented by:UMITTAL 03/07/2024 PN-4771
*          CLEAR : p_local, p_remote, p_cross.
        ELSE.
          screen-input = 1.
          IF NOT p_remote = 'X'
          AND NOT p_local = 'X'
          AND NOT p_cross = 'X'.
            IF NOT p_remonl = 'X'.
*              p_local = 'X'."Commented by:UMITTAL 03/07/2024 PN-4771
            ELSE.
*              p_remote = 'X'."Commented by:UMITTAL 03/07/2024 PN-4771
            ENDIF.
          ENDIF.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'USTB'.
*--Don't allow update scan table when detailed or tree output selected
        IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
          screen-input = 0.
          CLEAR ustb.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'PCOLOR'.
        IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
          screen-input = 0.
          CLEAR pcolor.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'SHOTREE'.
        IF pcolor = 'X'.
          screen-input = 0.
          CLEAR : shodet, shotree,shosimp.
          shosum  = 'X'.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'SHODET'.
        IF pcolor = 'X'.
          screen-input = 0.
          CLEAR : shodet, shotree,shosimp.
          shosum  = 'X'.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'SHOSIMP'.
        IF pcolor = 'X'.
          screen-input = 0.
          CLEAR : shodet, shotree,shosimp.
          shosum  = 'X'.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
*        IF gf_out_nohienh <> 'X'.
          screen-input = 1.
          IF p_first = 'X'.
            CLEAR p_first.
            p_hienhn = 'X'.
          ENDIF.
*         ENDIF.
        ENDIF.
        IF p_nabap = 'X' AND p_hienhn = 'X'.
          CLEAR p_hienhn.
          MODIFY SCREEN.
          MESSAGE w002 WITH text-015 text-014.
        ENDIF.


      WHEN 'P_ENHANC'.
        IF p_nabap = 'X' AND p_enhanc = 'X'.
          CLEAR p_enhanc.
          MODIFY SCREEN.
          MESSAGE w002 WITH text-015 text-014.
        ENDIF.



      WHEN 'CUSCON'.
        IF p_nabap = 'X' AND cuscon = 'X'.
          CLEAR cuscon.
          MODIFY SCREEN.
          MESSAGE w002 WITH text-016 text-014.
        ENDIF.

*      when 'ORGCHK'.
*        if p_nabap = 'X'.
*          clear
*          endif.


      WHEN 'BYRSIMU'.
        IF p_nabap = 'X' AND byrsimu = 'X' AND p_abap <> 'X'.
*          CLEAR byrsimu.
*          MODIFY SCREEN.
*          MESSAGE w002 WITH text-018 text-014.
        ENDIF.



      WHEN 'SHONOSOD'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT spconfs[] IS INITIAL OR
           NOT s_risk[] IS INITIAL  OR
           NOT cowner[] IS INITIAL  OR
           NOT pappa[] IS INITIAL   OR
           NOT cprmit[] IS INITIAL  OR
           NOT csens[] IS INITIAL OR
           NOT proca[] IS INITIAL.
          screen-input = 0.
          MODIFY SCREEN.

          IF shonosod = 'X'.
            CLEAR shonosod.
            MESSAGE w002 WITH
            'Showing user without conflict not allowed'.
          ENDIF.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

*--Disable Show no SOD when detailed output is requested
        IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
          screen-input  = '0'.
          IF shonosod = 'X'.
            CLEAR shonosod.
            MESSAGE w002 WITH
            'Showing user without conflict not allowed'.
          ENDIF.
        ELSE.
          IF spconfs[] IS INITIAL AND s_risk[] IS INITIAL
         AND cowner[] IS INITIAL AND pappa[] IS INITIAL AND
         cprmit[] IS INITIAL AND csens[] IS INITIAL AND proca[] IS
         INITIAL.
            screen-input  = '1'.
          ENDIF.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'ORGCHK'.
        IF gf_hide_org = 'X'.
          screen-active = 0.
        ELSE.
          screen-active = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'ORGLVL-LOW' OR 'ORGLVL-HIGH'.
        IF orgchk = 'X'.
          screen-input = 1.
        ELSE.
          REFRESH : orglvl.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
*Hide paralell processing options if detailed or tree output  selected
      WHEN 'WP' OR 'DEFGRP' OR 'SPECGRP' OR 'PGROUP'
            OR 'PSERVER' OR 'UPP'.
        IF shosum = 'X'.
          screen-input  = '1'.
        ELSE.
          CLEAR : wp, pserver, pgroup.
          screen-input = '0'.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.

    IF  screen-name CS 'S_CUID'.
      IF gf_central_uid = 'X'.
        screen-active    = 1.
*          screen-invisible = 0.
      ELSE.
        screen-active    = 0.
*          screen-invisible = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name = 'P_LOCAL'.
*--Disable "Local" if "Remote only" is checked.
      IF p_remonl = 'X'.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.


    CASE screen-name.
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
        IF p_nabap = 'X' AND showcomp = 'X' AND p_abap <> 'X'.
          CLEAR showcomp.
          MESSAGE w002 WITH text-013 text-014.
        ENDIF.
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

  ENDLOOP.

  LOOP AT SCREEN.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND screen-name CS 'CFGSET'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.


    IF g_usrpar IS INITIAL AND screen-name CS 'S_USRPAR'.
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
              OR screen-name = 'S_SYSTEM-LOW'
              OR screen-name = 'S_SYSTEM-HIGH'
              OR screen-name = 'EBYSIMU'
                OR screen-name = 'AR_SYSS1'
*Role addition simulaton EN
    OR screen-name = 'AR_SYSD1'
    OR screen-name = 'AE_ROL_1-LOW'
    OR screen-name = 'AE_ROL_1-HIGH'

    OR screen-name = 'AR_SYSS2'
    OR screen-name = 'AR_SYSD2'
    OR screen-name = 'AE_ROL_2-LOW'
    OR screen-name = 'AE_ROL_2-HIGH'

    OR screen-name = 'AR_SYSS3'
    OR screen-name = 'AR_SYSD3'
    OR screen-name = 'AE_ROL_3-LOW'
    OR screen-name = 'AE_ROL_3-HIGH'

    OR screen-name = 'AR_SYSS4'
    OR screen-name = 'AR_SYSD4'
    OR screen-name = 'AE_ROL_4-LOW'
    OR screen-name = 'AE_ROL_4-HIGH'

*ROle removal simulaton EN
     OR screen-name = 'EBRSIMU'
     OR screen-name = 'RR_SYS_1'
     OR screen-name = 'EN_ROL_1-LOW'
     OR screen-name = 'EN_ROL_1-HIGH'
     OR screen-name = 'RR_SYS_2'
     OR screen-name = 'EN_ROL_2-LOW'
     OR screen-name = 'EN_ROL_2-HIGH'
     OR screen-name = 'RR_SYS_3'
     OR screen-name = 'EN_ROL_3-LOW'
     OR screen-name = 'EN_ROL_3-HIGH'
     OR screen-name = 'RR_SYS_4'
     OR screen-name = 'EN_ROL_4-LOW'
     OR screen-name = 'EN_ROL_4-HIGH'.
                screen-input    = 0.
              ELSE.
                screen-input    = 1.
              ENDIF.
            ENDIF.
          ELSE.
            screen-invisible = 1.
            screen-active    = 0.
            REFRESH: s_appl,s_system.
          ENDIF.
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
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*Begin of change:HBHALLA (PN-17036) (09/01/26)
  CLEAR g_swconfig.
  se_config_param 'EN_INTEGRATION' g_swconfig-value.

 IF g_swconfig-value = 'N'.
  CLEAR: p_nabap,ebysimu, ebrsimu.
 ENDIF.
*End of change:HBHALLA (PN-17036) (09/01/26)

*EOC UMITTAL SE VF scan changes-25/11/2024
  DATA: l_rev_mapping      TYPE /psyng/param_value.
  se_config_param   'SOD_REV_USR_MAPPING' l_rev_mapping.
  IF l_rev_mapping EQ 'Y'.
    PERFORM reverse_mapping_nonabap.
  ENDIF.

  IF p_lvl3 = 'X'.
*--change conid and bname of 1stoutput-
    READ TABLE userlist INDEX 1.
    1stoutput-bname = userlist-low.
    READ TABLE spconfs INDEX 1.
    1stoutput-conid = spconfs-low.
    1stoutput-level3 = 'X'.
    1stoutput-level2 = 'X'.
    lvl3 = 'X'.

    PERFORM level3_details USING 1stoutput.
    EXIT.
  ENDIF.
  gf_its = p_its.
  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    lf_include_local = 'X'.
    IF p_remonl = 'X'.
      CLEAR lf_include_local.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
        i_setid            = cfgset
        i_vrsio            = sodvrsio
        if_show_warning    = 'X'
        if_local_system    = lf_include_local
      IMPORTING
        ef_wrong_version   = lf_set_invalid
        ef_missing_system  = lf_set_nocover
        ef_system_mismatch = lf_set_mismatch
      TABLES
        it_rfcdest         = xusrrfc.
    IF lf_set_invalid  = 'X' OR
       lf_set_nocover  = 'X' .
      EXIT.
    ENDIF.
  ENDIF.


  IF orgchk = 'X'.
    exelog sy-repid 'ORGCHECK'.
  ELSE.
    exelog sy-repid 'NO_ORGCHECK'.
  ENDIF.


*--SF CASE 2727
*  Ensure default values are set for radio buttons
  IF shosum  IS INITIAL AND
     shodet  IS INITIAL AND
     shotree IS INITIAL AND
     shosimp IS INITIAL.
    shosum = 'X'.
  ENDIF.
  IF defgrp  IS INITIAL AND
     specgrp  IS INITIAL AND
     specsrv IS INITIAL.
    defgrp = 'X'.
  ENDIF.

  IF g_exit_proc = 'Y'.

    SUBMIT (g_program)                       "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(11/12/24)
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.
*--Display information about parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid = g_program.

  MESSAGE s398(00) WITH  'Start of Selection'(171).
  COMMIT WORK.

  DATA : lf_dont_update_scan      TYPE flag,
         lf_dont_output_to_screen TYPE flag,
         lt_return                TYPE TABLE OF bapiret2 WITH HEADER
         LINE,
         lf_error                 TYPE flag,
         lf_warning               TYPE flag,
         lt_role_removal_simu     TYPE TABLE OF
         /psyng/sw_role_removal_simu,
         lt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu,

          lt_role_removal_simu_en     TYPE TABLE OF
         /psyng/en_role_removal_simu,
         lt_role_addition_simu_en
         TYPE TABLE OF /psyng/ex_role_addition_simu
         .

*-- Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT xusrrfc[] IS INITIAL.
    PERFORM rfc_validations.
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
  IF ebysimu EQ 'X'.
    PERFORM prepare_role_addition_simu_en
       TABLES lt_role_addition_simu_en.
    gt_role_addition_simu_en[] = lt_role_addition_simu_en.
  ENDIF.

  IF ebrsimu EQ 'X'.
    PERFORM prepare_role_removal_simu_en
         TABLES lt_role_removal_simu_en.
    gt_role_removal_simu_en[] = lt_role_removal_simu_en[].
  ENDIF.

  CONSTANTS:
        c_func_en_read_appsys(30) TYPE c
                                    VALUE '/PSYNG/EX_CR_READ_APPSYS'.
  DATA :lt_appl              TYPE TABLE OF /psyng/range_appl
                              WITH HEADER LINE,
        lt_sysid             TYPE TABLE OF /psyng/range_sysid
                              WITH HEADER LINE,
       lt_syshdr       TYPE TABLE OF /psyng/ex_syshdr_st
                       WITH HEADER LINE.                     .
  IF ebrsimu EQ 'X' OR ebysimu EQ 'X'.
    CALL FUNCTION c_func_en_read_appsys      "#EC PATHLOCK_CI_DYN_ACCES
          TABLES
            it_applications = s_appl
            it_systems      = s_system
*        et_apphdr       = lt_apphdr
            et_syshdr       = lt_syshdr.

  ENDIF.


  IF NOT gt_role_removal_simu_en[] IS INITIAL.
    LOOP AT gt_role_removal_simu_en ASSIGNING <fs_role_removal>.
      READ TABLE  lt_syshdr WITH KEY sysid = <fs_role_removal>-sysid.
      IF sy-subrc EQ 0.
        <fs_role_removal>-appl = lt_syshdr-appl.
      ELSE.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
 WITH
 'Maintain System ID under NON-ABAP App. Section'(e44).
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF NOT gt_role_addition_simu_en[] IS INITIAL.
    LOOP AT gt_role_addition_simu_en ASSIGNING <fs_role_addtion>.

      READ TABLE lt_syshdr WITH KEY
           sysid = <fs_role_addtion>-target_sysid.
      IF sy-subrc EQ 0.
        <fs_role_addtion>-appl = lt_syshdr-appl.

      ELSE.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
WITH
'Maintain Target Sys ID under NON-ABAP App. Section'(e43).

        LEAVE LIST-PROCESSING.
**        error message
      ENDIF.

    ENDLOOP.
  ENDIF.
  PERFORM get_conflicts_from_selection.
  PERFORM vaildate_other_fields.

*  BOC AKUMAR C1454
  REFRESH gt_usrpar.
  IF g_usrpar IS NOT INITIAL AND s_usrpar IS NOT INITIAL.
    gs_usrpar-parid = g_usrpar.
    gs_usrpar-parva = s_usrpar[].
    APPEND gs_usrpar TO gt_usrpar.
    CLEAR gs_usrpar.
  ENDIF.
*  EOC AKUMAR C1454

*--Detailed/Summary?
  IF shosum IS INITIAL.
    PERFORM detailed_sod_analysis
      USING
        1stoutput
        'X'.
  ELSE.
    IF ustb IS INITIAL.
      lf_dont_update_scan = 'X'.
    ENDIF.
    IF odt IS INITIAL.
      lf_dont_output_to_screen = 'X'.
    ENDIF.

*--Perform the SOD Scan

    MESSAGE s398(00) WITH  'Calling /PSYNG/SW_SOD_SCAN_FUNC'(172).
    COMMIT WORK.


**--Only if remote and cross are selected,
**  pass rfc destinations to FM
    DATA : lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest.
    lt_rfcdest[] = xusrrfc[].

*-- Simulation Before and After Logic
    IF bysimu = 'X' OR byrsimu = 'X' OR
     ebysimu = 'X' OR   ebrsimu = 'X'.
      lt_role_addition_simu[] = gt_role_addition_simu[].
      lt_role_removal_simu[] = gt_role_removal_simu[].
      lt_role_addition_simu_en[] = gt_role_addition_simu_en[].
      lt_role_removal_simu_en[] = gt_role_removal_simu_en[].
      PERFORM before_after_simulation
      TABLES lt_role_removal_simu
             lt_role_addition_simu
             lt_role_removal_simu_en
             lt_role_addition_simu_en.
      EXIT.
    ENDIF.

*-- SOD analysis Without Simulation

    FREE : gt_removed_roles.
    CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      EXPORTING
        i_org_check           = orgchk
        i_validuser           = validusr
        i_exlckusr            = exlckusr
        i_outvdate            = outvdate
*       I_ALLUG               =
        i_vrsio               = sodvrsio
        i_config_set          = cfgset
        i_cuscon              = cuscon
        i_function_details    = ' '
        i_shomit              = xmc
        i_enh                 = p_enhanc
        i_hienh               = p_hienhn
        i_wp                  = wp
        i_xstb                = lf_dont_update_scan
        i_pserver             = pserver
        i_max_upp             = upp
        i_shonosod            = shonosod
        i_locsod              = p_locsod
        i_locusr              = p_locusr
        i_output              = odt
        i_remote_only         = p_remonl
        i_er_roles            = erroles
        i_exclude_er_roles    = excl_er
*Analyze users with sap_all in detail
        i_analyze_sap_all     = 'X'
        i_level_2             = lvl2
        i_level_2_start       = lvl2st
        i_level_2_end         = lvl2ed
        i_level_3             = lvl3
        i_level_3_start       = lvl2st "only use one single timeframe
        i_level_3_end         = lvl2ed "only use one single timeframe
        i_level_3_changedocs  = lvl3_cd
        i_level_3_tablog      = lvl3_tl
        i_level_4             = lvl4
        i_level_4_start       = lvl2st "only use one single timeframe
        i_level_4_end         = lvl2ed "only use one single timeframe
        i_matrix_rfc          = p_sodrfc
        i_nonabap             = p_nabap
        i_abap                = p_abap
        if_mit_by_org         = gf_mit_by_org
        it_usrpar             = gt_usrpar
         i_org_field           = g_org_field "opl 645 GG

      IMPORTING
        e_usercount           = tusercount
        ef_missing_auth       = gf_missing_auth
        ef_st_missing_auth    = gf_st_missing_auth
      TABLES
        it_users              = userlist
        it_usergroup          = pclass
        it_actgroups          = s_role
        it_profiles           = s_prof
        it_usertype           = usrtype
        it_costcenter         = s_kostl
        it_confs              = gt_conid
        et_outputdet          = gt_output
        it_user_rfc           = lt_rfcdest "xusrrfc
*       it_simu_role_rfc      = simuagrs
        et_enh_con            = gt_enh_con
        it_orglvl             = orglvl
        it_risk               = s_risk
        it_department         = s_depart
        it_company            = s_comp
        it_central_uid        = s_cuid
        et_mitigations        = gt_mcuser
        et_rfcdes             = gt_rfcdes
        et_return             = lt_return
*--Role Removal Simulation
        it_simu_role_removal  = lt_role_removal_simu
        et_simu_removed_roles = gt_removed_roles
*--Role Addition Simulation
        it_simu_role_addition = lt_role_addition_simu
        et_rpoug_auth_fail    = lt_rpoug_auth_fail
*--EN Integration
        it_appl               = s_appl
        it_sysid              = s_system
        it_en_users           = gt_en_userlist "HBHALLA(PN-4774)
        .
*--Handle Errors (unless report called from ITS)
    IF gf_its IS INITIAL.
      LOOP AT lt_return.
        IF lt_return-type = 'E'.
          "this is not considered a real "error"
          IF lt_return-id = 'NOUSERS'.
            lf_warning = 'X'.
*Begin of Addition:HBHALLA(PN-18556)(31/03/26)
          ELSEIF lt_return-id = 'S_RFC'.
            lf_warning = 'X'.
*End of Addition:HBHALLA(PN-18556)(31/03/26)
          ELSE.
            lf_error   = 'X'.
          ENDIF.
          lt_return-type = 'S'.
        ENDIF.
        IF lf_warning = 'X'.
*Begin of Addition:HBHALLA(PN-18556)(31/03/26)
         IF lt_return-id = 'NOUSERS'.
          MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
          WITH lt_return-message.
          LEAVE LIST-PROCESSING.
         ELSE.
          MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '089'
          DISPLAY LIKE 'E' WITH lt_return-message.
          LEAVE LIST-PROCESSING.
         ENDIF.
*End of Addition:HBHALLA(PN-18556)(31/03/26)
        ENDIF.
      ENDLOOP.
      CALL FUNCTION '/PSYNG/SW_INFO_BAPIRET'
        TABLES
          it_bapiret2       = lt_return.

      IF lf_error = 'X'.
        MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
        WITH 'Fatal errors have occured.'(e04).
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
*--Handle output
*---SODLive
    IF hidestd = 'X'.
      DELETE gt_output WHERE level2 IS INITIAL AND
                             level3 IS INITIAL AND
                             level4 IS INITIAL.
    ENDIF.

*--Filter Conflict origin
* BOC by RGUPTA on 15.03.22 for C0633

*    IF p_local <> 'X'.
*      DELETE gt_output WHERE origin = 1.
*    ENDIF.
*    IF p_remote <> 'X'.
*      DELETE gt_output WHERE origin = 2.
*    ENDIF.
*    IF p_cross <> 'X'.
*      DELETE gt_output WHERE origin = 3.
*    ENDIF.
    IF p_local = 'X' AND p_remote IS INITIAL
      AND p_cross IS INITIAL.
      DELETE gt_output WHERE origin = 2
                          OR origin = 3
                          OR origin = 5.
    ELSEIF p_local = 'X' AND p_remote = 'X'
      AND p_cross IS INITIAL.
      DELETE gt_output WHERE origin = 3.
    ELSEIF p_local = 'X' AND p_remote IS INITIAL
      AND p_cross = 'X'.
      DELETE gt_output WHERE origin = 2.
    ELSEIF p_local IS INITIAL AND p_remote = 'X'
      AND p_cross IS INITIAL.
      DELETE gt_output WHERE origin = 1
                          OR origin = 3
                          OR origin = 4.
    ELSEIF p_local IS INITIAL AND p_remote = 'X'
      AND p_cross = 'X'.
      DELETE gt_output WHERE origin = 1.
    ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
      AND p_cross = 'X'.
      DELETE gt_output WHERE origin = 1
                          OR origin = 2.
    ENDIF.
* EOC by RGUPTA on 15.03.22 for C0633
    PERFORM get_mc_header_data.

*  --If removal simulation was done, but no roles were removed.
*  display a message
    IF byrsimu = 'X' AND gt_removed_roles[] IS INITIAL.
      MESSAGE i002 WITH
      'No users had the roles for which'(192)
      'removal was simulated'(191).
    ENDIF.
    IF NOT lf_dont_output_to_screen = 'X'.
      PERFORM reformat_output.
      IF p_upc = 'X'.
        PERFORM show_users_per_conflict.
      ELSE.
        PERFORM output_using_alv.
      ENDIF.
    ENDIF.
  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  reformat_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM reformat_output.
  FIELD-SYMBOLS : <in> TYPE /psyng/sw_sod_output_org.
  DATA : ls_output    LIKE LINE OF 1stoutput,
         l_ustyp(20),
         l_mit_rfcdes TYPE rfcdes-rfcdest.
  DATA: cc           TYPE lvc_s_scol,
        color        TYPE lvc_s_colo,
        seperator(3) TYPE c VALUE ' - '.

  CONCATENATE sy-sysid sy-mandt INTO l_mit_rfcdes.

  IF xmc = 'X' AND gf_mit_by_org <> 'X'.
*--MIT_BY_ORG is disabled, ignore ORG_ABB field in mitigations
    gt_mcuser-org_abb = ''.
    MODIFY  gt_mcuser TRANSPORTING org_abb WHERE org_abb <> ''.
    SORT gt_mcuser.
    DELETE ADJACENT DUPLICATES FROM gt_mcuser.
  ENDIF.

  REFRESH : 1stoutput[].
  LOOP AT gt_output ASSIGNING <in>.
    REFRESH : ls_output-color_cell.
*---SODLive
    ls_output-level2      = <in>-level2.
    ls_output-level3      = <in>-level3.
    ls_output-level4      = <in>-level4.
    ls_output-class       = <in>-class.
    ls_output-ustyp       = <in>-ustyp.
    ls_output-company     = <in>-company.
    ls_output-compshort   = <in>-company.
    PERFORM get_comp_name
                CHANGING
                   <in>-company
                   ls_output-company.

    ls_output-department  = <in>-department.
    ls_output-central_uid = <in>-central_uid.

    ls_output-bname       = <in>-bname.
    ls_output-name_text   = <in>-name_text.
    ls_output-conid       = <in>-conid.
    ls_output-description = <in>-condesc.
    ls_output-imp         = <in>-imp.
    ls_output-impsort     = <in>-impsort.
    ls_output-contid      = <in>-contid.
    ls_output-simu        = <in>-simu.
    ls_output-er          = <in>-er.
    ls_output-simu_after  = <in>-simu_after.
    ls_output-simu_before = <in>-simu_before.
    ls_output-origin      = <in>-origin.
    IF gf_mit_by_org = 'X' AND orgchk = 'X'.
      ls_output-abb = <in>-org_abb.
    ELSE.
      CLEAR ls_output-abb.
    ENDIF.

    IF pcolor = 'X'.
      IF NOT ls_output-contid IS INITIAL.
        CLEAR: ls_output-color_cell, ls_output-color_line.
        color-col = '5'.   "Green
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname = 'IMP'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'CONTID'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'AUDITOR'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'FROM_DATE'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'TO_DATE'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'SIMU'.
        APPEND cc TO ls_output-color_cell.
        cc-fname = 'ORIGIN'.
        APPEND cc TO ls_output-color_cell.
      ELSE.
        CASE <in>-imp.
          WHEN 'CRITICAL'.
            color-col = '6'.   "Red
            color-int = '0'.   "Intensified
            color-inv = '1'.   "Inverse
            cc-fname  = 'IMP'.
            cc-color = color.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'CONID'.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'DESCRIPTION'.
            APPEND cc TO ls_output-color_cell.
          WHEN 'HIGH'.
            color-col = '6'.   "Red
            color-int = '1'.   "Intensified
            color-inv = '0'.   "Inverse
            cc-fname  = 'IMP'.
            cc-color = color.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'CONID'.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'DESCRIPTION'.
            APPEND cc TO ls_output-color_cell.
          WHEN 'MEDIUM'.
            color-col = '6'.   "Red
            color-int = '0'.   "Un-Intensified
            color-inv = '0'.   "Inverse
            cc-fname  = 'IMP'.
            cc-color  = color.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'CONID'.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'DESCRIPTION'.
            APPEND cc TO ls_output-color_cell.
          WHEN 'LOW'.
            color-col = '3'.   "Yellow
            color-int = '0'.   "Un-Intensified
            color-inv = '0'.   "Inverse
            cc-fname  = 'IMP'.
            cc-color  = color.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'CONID'.
            APPEND cc TO ls_output-color_cell.
            cc-fname = 'DESCRIPTION'.
            APPEND cc TO ls_output-color_cell.

        ENDCASE.
      ENDIF.
    ENDIF.

    CASE <in>-origin.
      WHEN 1.
        ls_output-origin = 'Local'(173).
      WHEN 2.
        ls_output-origin = 'Remote'(174).
      WHEN 3.
        ls_output-origin = 'Cross'(175).
* BOC by RGUPTA on 15.03.22 for C0633
      WHEN 4.
        ls_output-origin = 'Local&Cross'(202).
      WHEN 5.
        ls_output-origin = 'Remote&Cross'(203).
      WHEN 6.
        ls_output-origin = 'L&R&C'(204).
* EOC by RGUPTA on 15.03.22 for C0633
    ENDCASE.

    READ TABLE gt_enh_con WITH KEY bname = <in>-bname
                                   conid = <in>-conid.
    IF sy-subrc = 0.
      ls_output-enhanced = 'X'.
      IF p_hienhn = 'X'.
        DELETE ls_output-color_cell WHERE fname = 'CONID'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'CONID'.
        APPEND cc TO ls_output-color_cell.
      ENDIF.
    ENDIF.

    IF xmc = 'X' AND NOT ls_output-contid IS INITIAL."Output mit. contrl
*     Get mitigation assignment info
      IF orgchk = 'X'. "HBHALLA (PN-6548)
        LOOP AT gt_mcuser WHERE
                         contid  = ls_output-contid  AND
                         conid   = ls_output-conid   AND
                         userid  = ls_output-bname   AND
                         vrsio   = sodvrsio          AND
                         org_abb = ls_output-abb     AND
                         from_date LE sy-datum       AND
                         to_date   GE sy-datum .
          ls_output-auditor   = gt_mcuser-auditor.
          ls_output-from_date = gt_mcuser-from_date.
          ls_output-to_date   = gt_mcuser-to_date.
          CASE gt_mcuser-type.
            WHEN '1'.
              ls_output-mit_icon = '@EK@'.
            WHEN '2'.
              ls_output-mit_icon = '@ID@'.
            WHEN '4'.
              ls_output-mit_icon = '@F8@'.
          ENDCASE.
          EXIT."first valid one is ok.
        ENDLOOP.
*BOC:HBHALLA (PN-6548)
      ELSE.
        LOOP AT gt_mcuser WHERE
                         contid  = ls_output-contid  AND
                         conid   = ls_output-conid   AND
                         userid  = ls_output-bname   AND
                         vrsio   = sodvrsio          AND
                         from_date LE sy-datum       AND
                         to_date   GE sy-datum .
          ls_output-auditor   = gt_mcuser-auditor.
          ls_output-from_date = gt_mcuser-from_date.
          ls_output-to_date   = gt_mcuser-to_date.
          CASE gt_mcuser-type.
            WHEN '1'.
              ls_output-mit_icon = '@EK@'.
            WHEN '2'.
              ls_output-mit_icon = '@ID@'.
            WHEN '4'.
              ls_output-mit_icon = '@F8@'.
          ENDCASE.
          EXIT."first valid one is ok.
        ENDLOOP.
      ENDIF.
*EOC:HBHALLA (PN-6548)
      IF sy-subrc <> 0 .
*       Mitigation is assigned to user group instead of user
        SELECT SINGLE auditor from_date to_date      "#EC CI_SEL_NESTED
                    INTO (ls_output-auditor, ls_output-from_date,
                       ls_output-to_date)
                 FROM /psyng/mcusrgrp
                WHERE contid = ls_output-contid
                  AND conid  = ls_output-conid
                  AND class  = ls_output-class
        AND vrsio  = sodvrsio.

* when conflict has all org mitigated but to see individual oaa in
*   selection filter
* Changes start rgupta
        IF gf_mit_by_org = 'X' AND orgchk = 'X' AND
          ls_output-auditor IS INITIAL.
          LOOP AT gt_mcuser WHERE
                       contid  = ls_output-contid  AND
                  conid   = ls_output-conid   AND
                  userid  = ls_output-bname   AND
                  vrsio   = sodvrsio          AND
                  org_abb = space     AND
                  from_date LE sy-datum       AND
                  to_date   GE sy-datum  AND
                  type      = '1' .
            ls_output-auditor   = gt_mcuser-auditor.
            ls_output-from_date = gt_mcuser-from_date.
            ls_output-to_date   = gt_mcuser-to_date.
*        ls_output-type      = gt_mcuser-type.
            ls_output-mit_icon = '@EK@'.
            EXIT."first valid one is ok.
          ENDLOOP.
        ENDIF. " end

      ENDIF.
    ENDIF.
    APPEND ls_output TO 1stoutput.
    CLEAR: ls_output.
  ENDLOOP.
ENDFORM.                    " reformat_output



*&---------------------------------------------------------------------*
*&      Form  handle_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA : l_temp TYPE i.

  PERFORM update_mid_status.




  DATA: ls_variant TYPE disvariant.
  DATA: ls_swconfig_bkgd_job TYPE /psyng/swconfig.
  DATA: ls_line_count TYPE i.

* REPEAT_HDR_BKGDJOB Flag Check
  IF sy-batch EQ 'X'.
    se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.

    IF ls_swconfig_bkgd_job-value = 'N'.
      CLEAR g_repeat_hdr_bkgdjob.
      DESCRIBE TABLE 1stoutput LINES ls_line_count.
      PERFORM set_print_param USING ls_line_count.
    ELSE.
      g_repeat_hdr_bkgdjob = 'X'.
      DESCRIBE TABLE 1stoutput LINES ls_line_count.
      l_temp = ls_line_count / sy-srows.
      gf_pages = trunc( l_temp ).
      l_temp = frac( l_temp ).
      IF l_temp > 0.
        gf_pages = gf_pages + 1.
      ENDIF.

    ENDIF.
  ENDIF.

  PERFORM set_output_variant.


  CONCATENATE sy-title text-093 sodvrsio
              INTO sy-title SEPARATED BY space.
  g_alv_layout-box_fieldname = 'SEL'.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.
*  alv_layout-variant = p_layo.

  MOVE 'COLOR_CELL' TO g_alv_layout-coltab_fieldname.
  MOVE 'COLOR_LINE' TO g_alv_layout-info_fieldname.
  PERFORM build_alv_catalog.
  PERFORM build_sort_table.
  PERFORM adjust_columns.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
      i_grid_title             = g_alv_grid_titl
      i_callback_program       = g_program
      i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      it_sort                  = gt_isort
      i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
      is_layout                = g_alv_layout
      it_fieldcat              = i_fieldcat_alv
      i_save                   = 'A'
      is_variant               = gs_variant
    TABLES
      t_outtab                 = 1stoutput.

ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

*Begin of Addition: HBHALLA (PN-15675) (Issue2) (07/11/25)
  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
*   12/13/08  Start
  l_sort-subtot = 'X'.
*   12/13/08  End
  APPEND l_sort TO gt_isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'COMPANY'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'COMPSHORT'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '5'.
  l_sort-fieldname = 'DEPARTMENT'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'CENTRAL_UID'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '7'.
  l_sort-fieldname = 'USTYP'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

*  l_sort-spos = '7'.
*  l_sort-fieldname = 'BNAME'.
*  l_sort-tabname = '1STOUTPUT'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO gt_isort.
*End of Addition: HBHALLA (PN-15675) (Issue2) (07/11/25)

  l_sort-spos = '8'.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'IMPSORT'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '10'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = '1STOUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.


  IF gf_mit_by_org = 'X' AND orgchk = 'X'.
    l_sort-spos = '11'.
    l_sort-fieldname = 'CONID'.
    l_sort-tabname   = '1STOUTPUT'.
    l_sort-up        = 'X'.
    APPEND l_sort TO gt_isort.
    l_sort-spos = '12'.
    l_sort-fieldname = 'DESCRIPTION'.
    l_sort-tabname   = '1STOUTPUT'.
    l_sort-up        = 'X'.
    APPEND l_sort TO gt_isort.
    l_sort-spos = '13'.
    l_sort-fieldname = 'ABB'.
    l_sort-tabname   = '1STOUTPUT'.
    l_sort-up        = 'X'.
    APPEND l_sort TO gt_isort.
  ENDIF.



ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  adjust_columns
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  CLEAR wa_fieldcat_alv.


*  wa_fieldcat_alv-col_pos = '3'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'IMP'.
*  wa_fieldcat_alv-col_pos = '4'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'CONID'.
*  wa_fieldcat_alv-col_pos = '5'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'DESCRIPTION'.
*--Dhorions 20101109 - Set correct column positions
  wa_fieldcat_alv-col_pos = '1'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CLASS'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'COMPANY'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'DEPARTMENT'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CENTRAL_UID'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'USTYP'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'BNAME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'NAME_TEXT'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'IMP'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CONID'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'DESCRIPTION'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'SIMU'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'SIMU_BEFORE'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'SIMU_AFTER'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'ENHANCED'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'ORIGIN'.



ENDFORM.                    " adjust_columns
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
      i_internal_tabname = '1STOUTPUT'
      i_inclname         = g_program
    CHANGING
      ct_fieldcat        = i_fieldcat_alv.

*BOC:HBHALLA (PN-4769)
  IF l_rev_mapping EQ 'Y'.
    LOOP AT i_fieldcat_alv INTO wa_fieldcat_alv.
      IF wa_fieldcat_alv-fieldname =    'CENTRAL_UID'.
        wa_fieldcat_alv-seltext_s =     'MappedUser'(224).
        wa_fieldcat_alv-seltext_m =    'Mapped User'(225).
        wa_fieldcat_alv-seltext_l =    'Mapped User'(225).
        wa_fieldcat_alv-reptext_ddic = 'Mapped User'(225).
        MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING
                           seltext_l
                           seltext_m
                           seltext_s
                           reptext_ddic
        WHERE fieldname = 'CENTRAL_UID'.
      ENDIF.
    ENDLOOP.
  ENDIF.
*EOC:HBHALLA (PN-4769)

  wa_fieldcat_alv-key = ' '.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  wa_fieldcat_alv-hotspot   = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'BNAME'.
  CLEAR wa_fieldcat_alv-hotspot.

  wa_fieldcat_alv-seltext_l = text-h02.
  wa_fieldcat_alv-seltext_m = text-h02.
  wa_fieldcat_alv-seltext_s = text-h02.
  wa_fieldcat_alv-reptext_ddic = text-h02.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic

                   WHERE
                      fieldname = 'NAME_TEXT'.
  wa_fieldcat_alv-seltext_l = text-h07.
  wa_fieldcat_alv-seltext_m = text-h07.
  wa_fieldcat_alv-seltext_s = text-h07.
  wa_fieldcat_alv-reptext_ddic = text-h07.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'CONTID'.

  wa_fieldcat_alv-seltext_l = text-h25.
  wa_fieldcat_alv-seltext_m = text-h25.
  wa_fieldcat_alv-seltext_s = text-h25.
  wa_fieldcat_alv-reptext_ddic = text-h25.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-tech = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                      tech
                   WHERE
                      fieldname = 'INACTIVE'.

  CLEAR wa_fieldcat_alv-hotspot.

  wa_fieldcat_alv-seltext_l = text-h20.
  wa_fieldcat_alv-seltext_m = text-h20.
  wa_fieldcat_alv-seltext_s = text-h20.
  wa_fieldcat_alv-reptext_ddic = text-h20.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDITOR'.

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

  wa_fieldcat_alv-seltext_m = text-h31.
  wa_fieldcat_alv-seltext_s = text-h31.
  wa_fieldcat_alv-reptext_ddic = text-h31.
  wa_fieldcat_alv-seltext_l = text-h31.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TO_DATE'.

  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.
*--DHORIONS 20130508 - Change : Company Short text is always visible
*                      by default,  Long text is hidden.

  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'COMPANY'.
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Company'(h26).
  wa_fieldcat_alv-seltext_m = 'Company'(h26).
  wa_fieldcat_alv-seltext_s = 'Company'(h26).
  wa_fieldcat_alv-reptext_ddic = 'Company'(h26).
*  wa_fieldcat_alv-no_out = 'X'.
  CLEAR wa_fieldcat_alv-no_out.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE fieldname = 'COMPSHORT'.


  wa_fieldcat_alv-seltext_l = text-h19.
  wa_fieldcat_alv-seltext_m = text-h19.
  wa_fieldcat_alv-seltext_s = text-h19.
  wa_fieldcat_alv-reptext_ddic = text-h19.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.

* Hide column IMPSORT
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-seltext_l = 'Sensitivity sort'(159).
  wa_fieldcat_alv-seltext_m = 'Sensitivity sort'(159).
  wa_fieldcat_alv-seltext_s = 'Sens. sort'(160).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity sort'(159).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMPSORT'.

  IF xmc = space.
* If user doesn't want to see the MC IDs, hide colum CONTID
    CLEAR wa_fieldcat_alv.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE fieldname = 'CONTID'
                        OR fieldname = 'AUDITOR'
                        OR fieldname = 'FROM_DATE'
                        OR fieldname = 'TO_DATE'
                        OR fieldname = 'MIT_ICON'.
  ENDIF.

  IF p_enhanc = 'X'.
*if highlight enhanced ruleset is selected, add this field to the alv
    wa_fieldcat_alv-seltext_l      = text-157.
    wa_fieldcat_alv-seltext_m      = text-157.
    wa_fieldcat_alv-seltext_s      = text-157.
    wa_fieldcat_alv-reptext_ddic   = text-157.
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



  IF xusrrfc[] IS INITIAL.
    wa_fieldcat_alv-no_out = '1'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-170.
  wa_fieldcat_alv-seltext_m      = text-170.
  wa_fieldcat_alv-seltext_s      = text-170.
  wa_fieldcat_alv-lowercase      = 'X'.
  IF xusrrfc[] IS INITIAL AND p_nabap IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.


  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      lowercase
                   WHERE
                      fieldname = 'ORIGIN'.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l      = text-176.
  wa_fieldcat_alv-seltext_m      = text-176.
  wa_fieldcat_alv-seltext_s      = text-176.
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.

  IF bysimu <> 'X' AND byrsimu <> 'X'
    AND ebysimu <> 'X' AND ebrsimu <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'SIMU'.

  wa_fieldcat_alv-seltext_l      = text-200.
  wa_fieldcat_alv-seltext_m      = text-200.
  wa_fieldcat_alv-seltext_s      = text-200.
  wa_fieldcat_alv-hotspot        = 'X' .
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                   TRANSPORTING
                     seltext_l
                     seltext_m
                     seltext_s
                     no_out
                     checkbox
                     just
                     hotspot
                  WHERE
                     fieldname = 'SIMU_AFTER'.

  wa_fieldcat_alv-seltext_l      = text-199.
  wa_fieldcat_alv-seltext_m      = text-199.
  wa_fieldcat_alv-seltext_s      = text-199.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                   TRANSPORTING
                     seltext_l
                     seltext_m
                     seltext_s
                     no_out
                     checkbox
                     just
                     hotspot
                  WHERE
                     fieldname = 'SIMU_BEFORE'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
         TRANSPORTING
           do_sum
         WHERE
           fieldname = 'CONID'.

  IF l_rev_mapping EQ 'N'. "HBHALLA (PN-4769)
    IF gf_central_uid IS INITIAL.
      wa_fieldcat_alv-no_out = 'X'.
      MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                        TRANSPORTING
                          no_out
                       WHERE
                          fieldname = 'CENTRAL_UID'.
    ENDIF.  "HBHALLA (PN-4769)
  ENDIF.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l      = 'Emergency Repair'(182).
  wa_fieldcat_alv-seltext_m      = 'Emergency Repair'(182).
  wa_fieldcat_alv-seltext_s      = 'Emergency Repair'(182).
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.
  IF erroles <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'ER'.

*---SODLive
  wa_fieldcat_alv-seltext_l  = 'Transactions/Services Executed'(l10).
  wa_fieldcat_alv-seltext_m  = 'Tcodes/Services Exe'(l16).
  wa_fieldcat_alv-seltext_s  = 'TCD/SR Exe'(l15).
  wa_fieldcat_alv-checkbox   = 'X'.
  wa_fieldcat_alv-just       = 'X'.
  wa_fieldcat_alv-hotspot    = 'X'.

  IF lvl2 <> 'X' AND lvl3 <> 'X' AND lvl4 <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'LEVEL2'.

  wa_fieldcat_alv-seltext_l      = 'Changes'(l11).
  wa_fieldcat_alv-seltext_m      = 'Changes'(l11).
  wa_fieldcat_alv-seltext_s      = 'Changes'(l11).
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.
  wa_fieldcat_alv-hotspot        = 'X'.

  IF  lvl3 <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'LEVEL3'.

  wa_fieldcat_alv-seltext_l      = 'Conflict Executed'(l13).
  wa_fieldcat_alv-seltext_m      = 'Conflict Executed'(l13).
  wa_fieldcat_alv-seltext_s      = 'SOD Exe'(l14).
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.
  wa_fieldcat_alv-hotspot        = 'X'.

  IF  lvl4 <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'LEVEL4'.

  IF gf_mit_by_org <> 'X' OR orgchk <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  wa_fieldcat_alv-seltext_l = 'Organizational Area Abbr.'(211).
  wa_fieldcat_alv-seltext_m = 'Org Area Abbr. '(212).
  wa_fieldcat_alv-seltext_s = 'Abbr.'(213).
  wa_fieldcat_alv-checkbox  = 'X'.
  wa_fieldcat_alv-just      = 'X'.
  wa_fieldcat_alv-hotspot   = 'X'.
  wa_fieldcat_alv-ddic_outputlen = 4. "RGUPTA
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    seltext_l
                    seltext_m
                    seltext_s
                    no_out
                    just
                    ddic_outputlen "RGUPTA
                 WHERE
                    fieldname = 'ABB'.

*--C0221 The columns that are not relevant and are hidden,
*  can be removed from the ALV Catalog
  DELETE i_fieldcat_alv WHERE no_out = 'X' AND
  (
   fieldname = 'LEVEL2' OR
   fieldname = 'LEVEL3' OR
   fieldname = 'LEVEL4' OR
   fieldname = 'ER'     OR
   fieldname = 'SIMU'   OR
   fieldname = 'SIMU_BEFORE' OR
   fieldname = 'SIMU_AFTER'
   ).



ENDFORM.                    " build_alv_catalog

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


  IF xmc IS INITIAL.
    lt_func-fcode = 'MITIGATE'.
    APPEND lt_func.
    lt_func-fcode = 'DEL_MIT'.
    APPEND lt_func.
  ELSE.
*-- Check config if this check is required or not
    IF gf_use_sec_obj = 'X'.
*-- Check Create/Modify Authority
      AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT' FIELD '22'
           ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc NE 0.
        AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
              ID 'ACTVT' FIELD '23'
              ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
              ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc NE 0.
          lt_func-fcode = 'MITIGATE'.
          APPEND lt_func.
        ENDIF.
      ENDIF.

      AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
          ID 'ACTVT' FIELD '24'
          ID 'CLASS'      FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
          ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc NE 0.
        lt_func-fcode = 'DEL_MIT'.
        APPEND lt_func.
      ENDIF.
    ENDIF.
  ENDIF.
  IF byrsimu IS INITIAL .
*    AND ebrsimu IS INITIAL.
    lt_func-fcode = 'ROLEREMDET'.
    APPEND lt_func.
  ENDIF.

  IF gf_auth_fail IS INITIAL.
    lt_func-fcode = 'FAILEDUSER'.
    APPEND lt_func.
  ENDIF.

*--AKUMAR C1132 22/09/2023 START
  IF lvl3 IS INITIAL.
    lt_func-fcode = 'CHANGEDET'.
    APPEND lt_func.
  ENDIF.
*--AKUMAR C1132 22/09/2023 END

  lt_func-fcode = '&XINT'.
  APPEND lt_func.
  SET PF-STATUS 'SUMMARY' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary

*&---------------------------------------------------------------------*
*&      Form  USER_DOUBLE_CLICK_ON_SUMRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                  rs_selfield TYPE slis_selfield.
  DATA: l_name TYPE char100.

  DATA: iseltab          TYPE STANDARD TABLE OF  rsparams WITH HEADER
  LINE,
        l_contid         TYPE /psyng/mchdr-contid,
        l_count          TYPE i,
        l_mit_count      TYPE i,
        l_line(100)      TYPE c,
        l_user_name      TYPE /psyng/bc_uidn-name_text,
        ls_mcuser        TYPE /psyng/mitigation_assignment,
        ls_mcu           TYPE /psyng/mcuser,
        ls_return        TYPE bapireturn,
        lf_answer(1)     TYPE c,
        ls_mchdr         TYPE /psyng/mchdr,
        lt_mcusersave    TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_uinfo         TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        lf_was_collapsed TYPE flag,
        l_rsimu          TYPE flag,
        l_simu           TYPE flag,
        l_rsimu_en          TYPE flag,
        l_simu_en           TYPE flag,
        l_parva          TYPE usr05-parva,
        l_uname          LIKE sy-uname,
        l_sod            TYPE /psyng/swsodvers-vrsio.


  STATICS: lt_mcuser_all TYPE TABLE OF /psyng/mitigation_assignment.


  CASE r_ucomm.
    WHEN 'UPC'.
      PERFORM show_users_per_conflict.
      EXIT.
    WHEN 'SODLIVE'.
      IF liv_but <> '@3T'.
        lf_was_collapsed = 'X'.
        PERFORM expand USING liv_but.
      ENDIF.
      CALL SCREEN '0103' STARTING AT 10 10.
      IF lf_was_collapsed = 'X'.
        PERFORM collapse USING liv_but.
      ENDIF.
      CLEAR lf_was_collapsed.
      EXIT.

    WHEN 'FAILEDUSER'.
      PERFORM show_user_grp_cmp_invalid.
      EXIT.

    WHEN 'SELSCRINFO'.
*--AKUMAR : 17/08/2023 C1102 This case is implemented to see the
*--selection screen values in run time
      PERFORM show_sel_scr_info.

    WHEN 'CHANGEDET'.
*--AKUMAR BOC : 30/08/2023 C1132
*--This case is implemented to solve time out issue in SOD Live
*--(Changes Detail) feature.
      DATA: no_changes TYPE flag.
      LOOP AT 1stoutput WHERE sel = 'X' AND level3 <> 'X'.
        no_changes = 'X'.
      ENDLOOP.
      IF no_changes = 'X'.
        MESSAGE i135 WITH
        'Select only those records where changes exist'(216).
      ELSE.
        REFRESH 1stoutput1.
        LOOP AT 1stoutput WHERE sel = 'X'.
          APPEND 1stoutput TO 1stoutput1.
        ENDLOOP.
        DESCRIBE TABLE 1stoutput1.
        IF sy-tfill = 0.
          MESSAGE i135 WITH
                            'No record is selected'(217).
        ELSEIF sy-tfill = 1.
          MESSAGE i135 WITH
                       'You must have to select multiple records'(218).
        ELSE.
          CALL SCREEN 2002
        STARTING AT 115 2
            ENDING AT 155 5.
        ENDIF.
      ENDIF.
*--AKUMAR EOC : 30/08/2023 C1132


    WHEN 'ROLESIMU'.
*--DHORIONS : 2013/09/22 I don't see any reason for this, so removed it
*--DHORIONS : 2014/04/16 Added this again, it is intended to make sure
* navigating back and forth between simulated and non simulated ALV's is
* accurare
*--Backup current simulation options
      DATA : l_bysimu   TYPE flag,
             l_byrsimu  TYPE flag,
             l_rolerfc  LIKE rfcdes-rfcdest,
             l_rr_rfc_1 LIKE rfcdes-rfcdest,
             l_rr_rfc_2 LIKE rfcdes-rfcdest,
             l_rr_rfc_3 LIKE rfcdes-rfcdest,
             l_rr_rfc_4 LIKE rfcdes-rfcdest,
             l_ar_rfcs1 LIKE rfcdes-rfcdest,
             l_ar_rfcd1 LIKE rfcdes-rfcdest,
             l_ar_rfcs2 LIKE rfcdes-rfcdest,
             l_ar_rfcd2 LIKE rfcdes-rfcdest,
             l_ar_rfcs3 LIKE rfcdes-rfcdest,
             l_ar_rfcd3 LIKE rfcdes-rfcdest,
             l_ar_rfcs4 LIKE rfcdes-rfcdest,
             l_ar_rfcd4 LIKE rfcdes-rfcdest,
             l_parva_exists TYPE sy-subrc.
      RANGES : l_simurols FOR agr_define-agr_name,
             l_rr_rol_1 FOR  agr_define-agr_name,
             l_rr_rol_2 FOR  agr_define-agr_name,
             l_rr_rol_3 FOR  agr_define-agr_name,
             l_rr_rol_4 FOR  agr_define-agr_name,
             l_ar_rol_1 FOR  agr_define-agr_name,
             l_ar_rol_2 FOR  agr_define-agr_name,
             l_ar_rol_3 FOR  agr_define-agr_name,
             l_ar_rol_4 FOR  agr_define-agr_name.
      l_bysimu    = bysimu.
      l_byrsimu   = byrsimu.
      l_rolerfc   = rolerfc.
      l_rr_rfc_1  = rr_rfc_1.
      l_rr_rfc_2  = rr_rfc_2.
      l_rr_rfc_3  = rr_rfc_3.
      l_rr_rfc_4  = rr_rfc_4.

      l_ar_rfcs1  = ar_rfcs1.
      l_ar_rfcd1  = ar_rfcd1.
      l_ar_rfcs2  = ar_rfcs2.
      l_ar_rfcd2  = ar_rfcd2.
      l_ar_rfcs3  = ar_rfcs3.
      l_ar_rfcd3  = ar_rfcd3.
      l_ar_rfcs4  = ar_rfcs4.
      l_ar_rfcd4  = ar_rfcd4.



      l_simurols[]    = simurols[].
      l_rr_rol_1[]  = rr_rol_1[].
      l_rr_rol_2[]  = rr_rol_2[].
      l_rr_rol_3[]  = rr_rol_3[].
      l_rr_rol_4[]  = rr_rol_4[].

      l_ar_rol_1[]  = ar_rol_1[].
      l_ar_rol_2[]  = ar_rol_2[].
      l_ar_rol_3[]  = ar_rol_3[].
      l_ar_rol_4[]  = ar_rol_4[].
*





*      call screen '0101' starting at 10 10.
      IF simu_but <> '@3T'.
        lf_was_collapsed = 'X'.
        PERFORM expand USING simu_but.
      ENDIF.
      CALL SCREEN '0101' STARTING AT 10 10.
      IF lf_was_collapsed = 'X'.
        PERFORM collapse USING simu_but.
      ENDIF.
      CLEAR lf_was_collapsed.
*--restore previous selections
      bysimu    = l_bysimu.
      byrsimu   = l_byrsimu.
      rolerfc   = l_rolerfc.
      rr_rfc_1  = l_rr_rfc_1.
      rr_rfc_2  = l_rr_rfc_2.
      rr_rfc_3  = l_rr_rfc_3.
      rr_rfc_4  = l_rr_rfc_4.

      ar_rfcs1  = l_ar_rfcs1.
      ar_rfcd1  = l_ar_rfcd1.
      ar_rfcs2  = l_ar_rfcs2.
      ar_rfcd2  = l_ar_rfcd2.
      ar_rfcs3  = l_ar_rfcs3.
      ar_rfcd3  = l_ar_rfcd3.
      ar_rfcs4  = l_ar_rfcs4.
      ar_rfcd4  = l_ar_rfcd4.


      simurols[]    = l_simurols[].
      rr_rol_1[]  = l_rr_rol_1[].
      rr_rol_2[]  = l_rr_rol_2[].
      rr_rol_3[]  = l_rr_rol_3[].
      rr_rol_4[]  = l_rr_rol_4[].

      ar_rol_1[]  = l_ar_rol_1[].
      ar_rol_2[]  = l_ar_rol_2[].
      ar_rol_3[]  = l_ar_rol_3[].
      ar_rol_4[]  = l_ar_rol_4[].
      EXIT.
    WHEN 'ROLEREMDET'.
      CALL SCREEN '0102' STARTING AT 10 10.
      EXIT.

    WHEN 'MITIGATE'.                   "Add/edit mitigation control
      PERFORM mitigate.
      EXIT.

    WHEN 'DEL_MIT'.                    "Delete mitigation control
      LOOP AT 1stoutput WHERE sel = 'X'.
        IF 1stoutput-contid IS INITIAL.
          MESSAGE e123 WITH 1stoutput-bname 1stoutput-conid.
        ENDIF.

        ADD 1 TO l_count.

*       Check for multiple mitigation assignments
        CLEAR l_mit_count.
        LOOP AT gt_mcuser WHERE userid  = 1stoutput-bname
                            AND conid   = 1stoutput-conid
                            AND org_abb = 1stoutput-abb
                            AND to_date => sy-datum
                            AND type  = '1'.
          ADD 1 TO l_mit_count.
        ENDLOOP.

        IF l_mit_count > 1.
*         Must not do this within loop - short dumps
          EXIT.
        ENDIF.

        READ TABLE gt_mcuser WITH KEY userid = 1stoutput-bname
                                 conid   = 1stoutput-conid
                                 contid  = 1stoutput-contid
                                 org_abb = 1stoutput-abb.
        IF gt_mcuser-type <> '1'.
          CASE gt_mcuser-type.
            WHEN '2'.
*             Can't remove control assigned to usergroup
              MESSAGE e163.
            WHEN '3'.
*             Can't remove control assigned to critical Auths
              MESSAGE e165.
            WHEN '4'.
              MESSAGE e166.
          ENDCASE.

        ENDIF.

        IF gf_use_sec_obj = 'X'.
*-- Check Create/Modify Authority
          IF NOT 1stoutput-class IS INITIAL.
            AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
               ID 'ACTVT' FIELD '24'
               ID 'CLASS' FIELD 1stoutput-class
               ID 'Y&SW_VRSIO' FIELD sodvrsio
               ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
               ID 'Y&SW_CONID' FIELD gt_mcuser-conid
               ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
               ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
            IF sy-subrc NE 0.
              MESSAGE e108 WITH 'Delete'(e01)
                               'this Mitigation assignment'(e03).
            ENDIF.
          ENDIF.

          IF 1stoutput-company IS INITIAL.
            AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
             ID 'ACTVT' FIELD '24'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD sodvrsio
             ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
             ID 'Y&SW_CONID' FIELD gt_mcuser-conid
             ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
          ELSE.
            AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
                 ID 'ACTVT' FIELD '24'
                 ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
                 ID 'Y&SW_VRSIO' FIELD sodvrsio
                 ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
                 ID 'Y&SW_CONID' FIELD gt_mcuser-conid
                 ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
                 ID 'Y&SW_COMP'  FIELD 1stoutput-company.
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

          IF 1stoutput-company IS INITIAL.
            AUTHORITY-CHECK OBJECT 'Y&SW_MITG'
              ID 'ACTVT'      FIELD '06'
              ID 'Y&SW_VRSIO' FIELD sodvrsio
              ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
              ID 'Y&SW_CONID' FIELD gt_mcuser-conid
              ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
              ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
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
                   ID 'Y&SW_CNTID' FIELD gt_mcuser-contid
                   ID 'Y&SW_CONID' FIELD gt_mcuser-conid
                   ID 'Y&SW_BNAME' FIELD gt_mcuser-userid
                   ID 'Y&SW_COMP'  FIELD 1stoutput-company.
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

        ls_mcuser = gt_mcuser.
        ls_mcuser-vrsio = sodvrsio.
      ENDLOOP.

      IF l_count <> 1.
        MESSAGE e018.
      ENDIF.

      IF l_mit_count > 1.
*       Call popup screen for multiple assignments - short dumps
        PERFORM mitigate.
        EXIT.
      ENDIF.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          text_question         = text-q01
          text_button_1         = text-029
          icon_button_1         = 'ICON_OKAY'
          text_button_2         = text-030
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

      ls_mcuser-vrsio = sodvrsio.
      MOVE-CORRESPONDING ls_mcuser TO ls_mcu.
      APPEND ls_mcu TO lt_mcusersave.

      ls_mchdr-contid = ls_mcuser-contid.

*--Read RFC destination
      READ TABLE gt_rfcdes WITH KEY rfcoptions = gt_mcuser-rfcdest.
      IF sy-subrc <> 0 OR gt_rfcdes-rfcdest = 'LOCAL'.
        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcuser            = lt_mcusersave
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            OTHERS               = 4.
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
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
        CALL FUNCTION '/PSYNG/SW_CR_ADD_MIT_CONTROLS'
          DESTINATION gt_rfcdes-rfcdest
          EXPORTING
            is_mchdr             = ls_mchdr
            if_del_assgn_only    = 'X'
          TABLES
            it_mcuser            = lt_mcusersave
          EXCEPTIONS
            target_not_specified = 1
            not_authorized       = 2
            locked               = 3
            system_failure        = 4
            communication_failure = 5
            OTHERS               = 6.            "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      ENDIF.

      CASE sy-subrc.
        WHEN 1.
          MESSAGE e106 WITH 'Control ID'(183).
        WHEN 2.
          MESSAGE e108 WITH 'save mitigation controls'(184).
        WHEN 3.
          MESSAGE e113 WITH text-183 ls_mchdr-contid
                            'is currently locked'(185).
        WHEN 4.
          MESSAGE e113 WITH 'Communication failure'(t02).
        WHEN 5.
          MESSAGE e113 WITH 'System failure'(t03).
        WHEN 6.
          MESSAGE e113 WITH 'Unable to save'(186) text-183
                                ls_mchdr-contid.

      ENDCASE.

      MESSAGE s117.
*--Reflect the changes in the output
      DELETE gt_mcuser WHERE userid  = 1stoutput-bname  AND
                             conid   = 1stoutput-conid  AND
                             contid  = 1stoutput-contid AND
                             org_abb = 1stoutput-abb.

      CLEAR:  gt_mcuser-contid,
              gt_mcuser-auditor,
              gt_mcuser-from_date,
              gt_mcuser-to_date,
              gt_mcuser-type,
              gt_mcuser-org_abb.

      READ TABLE gt_mcuser WITH KEY userid  = 1stoutput-bname
                                    conid   = 1stoutput-conid
                                    org_abb = 1stoutput-abb
                           TRANSPORTING contid
                                        auditor
                                        from_date
                                        to_date type.
      1stoutput-contid    = gt_mcuser-contid.
      1stoutput-auditor   = gt_mcuser-auditor.
      1stoutput-from_date = gt_mcuser-from_date.
      1stoutput-to_date   = gt_mcuser-to_date.
      CASE gt_mcuser-type.
        WHEN '1'.
          1stoutput-mit_icon = '@EK@'.
        WHEN '2'.
          1stoutput-mit_icon = '@ID@'.
        WHEN '4'.
          1stoutput-mit_icon = '@F8@'.
        WHEN OTHERS.
          CLEAR 1stoutput-mit_icon.
      ENDCASE.
      MODIFY 1stoutput TRANSPORTING contid auditor from_date to_date
                       mit_icon WHERE sel = 'X'.
*--Refresh the ALV
      PERFORM refresh_output.
      MESSAGE s002(/psyng/sw) WITH 'Mitigation Update Saved.'.
      g_mit_message = 'X'.
      EXIT.
  ENDCASE.

  CASE rs_selfield-fieldname.
    WHEN 'MIT_ICON'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      IF 1stoutput-contid IS INITIAL.
        MESSAGE e123 WITH 1stoutput-bname 1stoutput-conid.
      ENDIF.
      PERFORM show_mit_details USING 1stoutput.
      EXIT.
    WHEN 'LEVEL2'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      PERFORM level2_details USING 1stoutput.
      g_tcode_exe_message = 'X'.
      EXIT.
    WHEN 'LEVEL3'.
      DATA: g_answer(1)        TYPE c.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      IF 1stoutput-level3 = 'X'.
        CALL SCREEN 2001
        STARTING AT 115 11
            ENDING AT 155 15.
      ENDIF.
      EXIT.

    WHEN 'LEVEL4'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      PERFORM level4_details USING 1stoutput.
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
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
      EXIT.

    WHEN 'AUDITOR'.
      CHECK rs_selfield-value <> space.
      1stoutput-bname = rs_selfield-value.
      PERFORM get_user_name USING 1stoutput-bname
                            CHANGING l_user_name.

      CHECK NOT l_user_name IS INITIAL.
      CONCATENATE rs_selfield-value '=' l_user_name INTO l_line
                  SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-h20
          text_question         = l_line
          text_button_1         = 'OK'(000)
          icon_button_1         = 'ICON_SYSTEM_OKAY'
          text_button_2         = text-030
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '1'
          display_cancel_button = ' '.
      EXIT.

    WHEN 'SIMU_AFTER'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      IF 1stoutput-simu_after <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
         'This conflict doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11)
         .
        EXIT.
      ELSE.
        READ TABLE 1stoutput INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0 AND 1stoutput-conid <> text-071.
        PERFORM detailed_sod_analysis
          USING
            1stoutput
            ''.
        EXIT.
      ENDIF.

    WHEN 'SIMU_BEFORE'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      IF 1stoutput-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This conflict didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE 1stoutput INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0 AND 1stoutput-conid <> text-071.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.
        IF bysimu = 'X' .
          l_simu = 'X'.
          CLEAR bysimu.
        ENDIF.
*        for EN conflict before simulation
        IF ebrsimu EQ 'X'.
          l_rsimu_en = 'X'.
          CLEAR ebrsimu.
        ENDIF.
        IF ebysimu EQ 'X'.
          l_simu_en = 'X'.
          CLEAR ebysimu.
        ENDIF.
*         *****
        PERFORM detailed_sod_analysis
          USING
            1stoutput
            ''.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.
        IF l_simu = 'X'.
          bysimu = 'X'.
        ENDIF.
        IF l_simu_en = 'X'.
          ebysimu = 'X'.
        ENDIF.

        IF l_rsimu_en = 'X'.
          ebrsimu = 'X'.
        ENDIF.
        EXIT.
      ENDIF.

    WHEN 'CONID'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0 AND 1stoutput-conid <> text-071.
      IF bysimu = 'X' OR byrsimu = 'X' OR
         ebysimu EQ 'X' OR ebrsimu EQ 'X'.
        IF 1stoutput-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
               'This conflict doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      PERFORM detailed_sod_analysis
        USING
          1stoutput
          ''.


    WHEN 'BNAME'.
      READ TABLE 1stoutput INDEX rs_selfield-tabindex.
      l_name = 1stoutput-bname.
      SUBMIT  /psyng/se_object_drilldown
      WITH
        name   = l_name
      WITH
        r_user = 'X'
      AND RETURN.

  ENDCASE.







ENDFORM.   "USER_DOUBLE_CLICK_ON_SUMRY

*&---------------------------------------------------------------------*
*&      Form  disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM disp_total_servers_for_sel.
  DATA: l_title(20).
  DATA l_btchost LIKE msxxlist-host.
  MOVE text-064 TO l_title.

  CALL FUNCTION 'SLWY_SELECT_BTC_SERVER'
    EXPORTING
      select_title   = l_title
    CHANGING
      btc_host       = l_btchost
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
        lt_dest2   LIKE TABLE OF lt_dest WITH HEADER LINE,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        lt1_dest   LIKE TABLE OF lt_dest WITH HEADER LINE,
        lt_remrfc  TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
LINE,
        r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
        LINE.
  DATA: swconfig TYPE /psyng/swconfig.

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
    MESSAGE w398(00) WITH text-091 wp text-092.
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
    MESSAGE e208(00) WITH text-031.
  ENDIF.
  PERFORM check_server_is_valid.
  IF sy-ucomm = 'SCJB'.
    g_exit_proc = 'Y'.
    PERFORM schedule_back_job.

    EXIT.
  ENDIF.

  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.






*Remote only analysis
  IF sy-ucomm = 'REMO'.
    IF p_remonl = 'X'.
      CLEAR : p_local, p_cross.
      p_remote = 'X'.
      IF xusrrfc[] IS INITIAL AND p_nabap IS INITIAL.
        MESSAGE w140 WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ELSE.
      p_local = 'X'.
    ENDIF.
  ENDIF.


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


*--SOD Live date validation
  IF ( NOT lvl2ed IS  INITIAL AND lvl2ed < lvl2st )  OR
     ( NOT lvl3ed IS  INITIAL AND lvl3ed < lvl3st ).
    MESSAGE w140 WITH
    'Invalid date range'(e06).
  ELSE.
    IF lvl2 = 'X' OR lvl3 = 'X'.
*Get correct TA dates
      se_config_param 'TA_DISPLAY_HISTORY' swconfig-value.
      IF swconfig-value = 'Y'.
*--Validate the date range
        DATA : l_start TYPE dats,
               l_end   TYPE dats.
        PERFORM get_available_dates
                    CHANGING
                       l_start
                       l_end.
        IF lvl2ed > l_end OR
           lvl2st < l_start.
          MESSAGE w160 WITH
          'Invalid date range. Available'(e07)
                l_start ' - ' l_end.
*--If the end date is later than what's available
*  change the end date to what's available
          IF lvl2ed >     l_end.
            lvl2ed = l_end.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDIF.
  ENDIF.


ENDFORM.                    " check_input


*---------------------------------------------------------------------*
*       FORM get_available_dates                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_START                                                       *
*  -->  E_END                                                         *
*---------------------------------------------------------------------*
FORM get_available_dates CHANGING e_start e_end.

  CONSTANTS:lf_his_date_fm TYPE rs38l-name VALUE '/PSYNG/BC_USRHIS_029'.
  STATICS : l_start TYPE dats,
            l_end   TYPE dats.
  IF l_start IS INITIAL AND l_end IS INITIAL.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = lf_his_date_fm
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc = 0.
      CALL FUNCTION lf_his_date_fm           "#EC PATHLOCK_CI_DYN_ACCES
              IMPORTING
                e_startdate = e_start
                e_enddate   = e_end.
*-- 3.1ps3 TA is installed but job hasnt run even for first time
      IF e_start IS INITIAL AND e_end IS INITIAL.
        PERFORM get_history_dates
                  USING
                     e_start
                     e_end.

      ENDIF.
    ELSE.
*--NO TA
      PERFORM get_history_dates
                  USING
                     e_start
                     e_end.

    ENDIF.

    l_start = e_start.
    l_end   = e_end.
  ELSE.
    e_start = l_start.
    e_end   = l_end.
  ENDIF.
ENDFORM.                    " populate_avail_ta

*---------------------------------------------------------------------*
*       FORM get_history_dates                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_START                                                       *
*  -->  E_END                                                         *
*---------------------------------------------------------------------*
FORM get_history_dates USING e_start e_end.
  DATA: 1stmonth TYPE sy-datum, lastmont TYPE sy-datum.
  DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
  WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
    TABLES
      idirectory = idirectory.

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF e_start IS INITIAL OR 1stmonth > idirectory-startdate.
      e_start = idirectory-startdate.
    ENDIF.
*    IF e_end < idirectory-startdate.
*      e_end = idirectory-startdate.
*
*    ENDIF.
  ENDLOOP.
  e_end = sy-datum - 1.
ENDFORM.                    " get_history_months


*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA : l_start TYPE dats,
         l_end   TYPE dats,
         l_days  TYPE i.
  DATA: swconfig TYPE /psyng/swconfig.

*Get correct TA dates
  se_config_param 'TA_DISPLAY_HISTORY' swconfig-value.
  IF swconfig-value = 'Y'.
    PERFORM get_available_dates
              CHANGING
                 l_start
                 l_end.
    l_days = l_end - l_start.
    IF l_days GT 30.
      l_start = l_end - 30.
    ENDIF.
    lvl2ed = lvl3ed = l_end.
    lvl2st = lvl3st = l_start.
  ELSE.
*--Set default SOD live dates
    lvl2ed = sy-datum - 1.
    lvl3ed = sy-datum - 1.
    lvl2st = sy-datum - 30.
    lvl3st = sy-datum - 30.
  ENDIF.
  CLEAR swconfig.

  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
    IMPORTING
      e_vrsio = sodvrsio.

*Update Scan Table
  CLEAR swconfig.
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.
  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSEIF swconfig-value = 'N'.
    ustb = ' '.
  ENDIF.
  CLEAR swconfig.

*Valid & Dialog Users only
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    IF usrtype[] IS INITIAL.
      PERFORM set_def_usrtype.
    ENDIF.
    validusr = ' '.
  ENDIF.
  CLEAR swconfig.

*Show Mitigated Conflicts
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.
  IF swconfig-value = 'Y'.
    xmc = 'X'.
  ELSEIF swconfig-value = 'N'.
    xmc = ' '.
  ENDIF.
  CLEAR swconfig.

*Also show output for no SODs
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_NO_SOD' swconfig-value.
  IF swconfig-value = 'Y'.
    shonosod = 'X'.
  ELSEIF swconfig-value = 'N'.
    shonosod = ' '.
  ENDIF.
  CLEAR swconfig.

*Highlight conflicts
  CLEAR swconfig.
  se_config_param 'DFLT_LIGT_COLOR' swconfig-value.
  IF swconfig-value = 'Y'.
    pcolor = 'X'.
  ELSEIF swconfig-value = 'N'.
    pcolor = ' '.
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

**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    orgchk = ' '.
  ENDIF.
  CLEAR swconfig.

*Use Local Sod Matrix : if not defined, user central matrix
  CLEAR swconfig.
  se_config_param 'DFLT_LOCAL_SOD' swconfig-value.
  IF swconfig-value = 'Y'.
    p_locsod = 'X'.
  ELSE.
    p_locsod = ' '.
  ENDIF.
  CLEAR swconfig.

*Only analyze local users in cross system analysis
  CLEAR swconfig.
  se_config_param 'DFLT_LOCAL_USR' swconfig-value.
  IF swconfig-value = 'Y'.
    p_locusr = 'X'.
  ELSE.
    p_locusr = ' '.
  ENDIF.
  CLEAR swconfig.

*-- Show Composite profiles

  se_config_param 'USE_ROLES' swconfig-value.
  IF swconfig-value = 'N'.
    gf_showpcom = 'X'.
  ELSE.
    gf_showpcom = ' '.
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

*-- New Mitigation Assignment Check
*--Hide Org Level Check option
  se_config_param 'MIT_ASGN_AUTH_CHECK' swconfig-value.
  IF swconfig-value = '2'.
    gf_use_sec_obj = 'X'.
  ELSE.
    gf_use_sec_obj = ' '.
  ENDIF.
  CLEAR swconfig.

*-- ER Button

  g_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO g_tabname FROM dd02l
                WHERE tabname  = g_tabname
  AND as4local = 'A'.                            "#EC SAST_CI_GEN_CHECK
  IF sy-subrc = 0.
    se_config_param 'DFLT_INCLUDE_ER' swconfig-value.
    IF swconfig-value = 'Y'.
      erroles = 'X'.
    ELSE.
      erroles = ' '.
    ENDIF.
    CLEAR swconfig.
  ENDIF.

*--Drill down from Level 2 SOD Live to TA
  se_config_param 'TA_DISPLAY_HISTORY' swconfig-value.
  IF swconfig-value = 'N'.
    CLEAR gf_use_ta_drilldown.
  ELSE.
    gf_use_ta_drilldown = 'X'.
  ENDIF.


*--Central User ID search Help
*--Check what FM is configured for Central Userid information
  DATA : ls_fmname TYPE rs38l_fnam.


  se_config_param 'SW_CENTRAL_USR_FM' swconfig-value.
  IF sy-subrc = 0.
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


*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*           WHERE name = '/PSYNG/USER_XRFC'
*    AND type = 'S'.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO xusrrfc.
      xusrrfc-option = lt_tvarv-opti.
      APPEND xusrrfc.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_initial_config
*&---------------------------------------------------------------------*
*&      Form  check_server_is_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_server_is_valid.
  DATA: ilist TYPE STANDARD TABLE OF msxxlist WITH HEADER LINE.
  DATA: l_srvexist, l_messagetxt(80).

  CHECK NOT pserver IS INITIAL.
  CALL FUNCTION 'TH_SERVER_LIST'
*   EXPORTING
*     SERVICES             = 255
    TABLES
      list           = ilist
    EXCEPTIONS
      no_server_list = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT ilist.
    CHECK ilist-name = pserver.
    l_srvexist = 'Y'.
  ENDLOOP.
  CONCATENATE text-065 pserver text-066
              INTO l_messagetxt SEPARATED BY space.
  IF l_srvexist IS INITIAL.
    SET CURSOR FIELD 'PSERVER'.
    MESSAGE e208(00) WITH l_messagetxt.
  ENDIF.
ENDFORM.                    " check_server_is_valid
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.


  CLEAR: curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = g_curr_variant
      vari_desc     = g_vari_desc
    TABLES
      vari_contents = g_vari_contents
      vari_text     = g_vari_text.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = text-041.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = l_jobname
        in_repvarnt = g_curr_variant
        in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.
ENDFORM.                    " schedule_back_job
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid       = g_program
      if_no_logging = 'X'
    TABLES
      et_params     = gt_irsparams.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_next_variant_id.
*  DATA: oldnumber(7)   TYPE n, oldnumber_c(7).
*
*  CLEAR: g_variant, g_vari_desc.
*  REFRESH: g_vari_desc.
*  SELECT  variant INTO g_variant FROM varid
*
*  WHERE report = sy-repid   AND
*        variant LIKE '/PSYNG/%' AND NOT
*        variant LIKE '/PSYNG/Z%'
*  ORDER BY variant DESCENDING.
*    oldnumber = g_variant+7(7).
*    EXIT.
*  ENDSELECT.
*  IF sy-subrc NE 0.
*    g_variant = '/PSYNG/0000000'.
*  ELSE.
*    oldnumber = oldnumber + 1.
*    MOVE oldnumber TO oldnumber_c.
*    CONCATENATE text-081 oldnumber_c INTO g_variant.
*  ENDIF.

*C017 Odubey 29/11/2021
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
    EXPORTING
      i_report        = sy-repid
   IMPORTING
     e_variant       = g_variant.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.                    " get_next_variant_id

*---------------------------------------------------------------------*
*       USER-TOP-OF-PAGE                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM user-top-of-page.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_exedate        TYPE char10,
        l_exetime(8)     TYPE c,
        c_tusercount(6)  TYPE c,
        c_usercount(6)   TYPE c,
        c_averagecon(4)  TYPE c,
        l_alv_grid_titl2 TYPE lvc_title,
        lt_output        LIKE TABLE OF 1stoutput WITH HEADER LINE,
        ls_cfg_set       TYPE /psyng/swcfgset,
        l_str            TYPE string,
        l_int            TYPE i,
        c_totalcon       TYPE string,
        c_beforesimucon  TYPE string,
        l_from_date      TYPE char10,
        l_to_date        TYPE char10,
        l_systemid       TYPE /psyng/sysid, "C1102 AKUMAR
        l_origin(50)     TYPE c, "HBHALLA (03/11/23)
        l_local(10)      TYPE c, "HBHALLA (03/11/23)
        l_remote(10)     TYPE c, "HBHALLA (03/11/23)
        l_cross(10)      TYPE c. "HBHALLA (03/11/23)

  STATICS :
    l_msg_displayed  TYPE flag,
    l_totals_counted TYPE flag,
    l_usercount      TYPE i,
    l_conflictcount  TYPE i,
    l_concount_bs    TYPE i, "before simulation
    l_averagecon     TYPE i,
    l_pages          TYPE c,
    l_pgcnt          TYPE i.

*1STOUTPUT data
  REFRESH header[].
  IF l_totals_counted IS INITIAL.
    CLEAR: l_usercount, l_averagecon,
           g_alv_grid_titl, l_conflictcount.
    lt_output[]  = 1stoutput[].
    SORT lt_output BY bname conid.
    LOOP AT lt_output.
      CHECK lt_output-conid <> '----'(071).

      AT NEW  bname.
        l_usercount = l_usercount + 1.
      ENDAT.

      IF bysimu = 'X' OR byrsimu = 'X' OR
       ebysimu = 'X'  OR ebrsimu = 'X'.
        IF lt_output-simu_after = 'X'.
          l_conflictcount = l_conflictcount + 1.
        ENDIF.
        IF lt_output-simu_before = 'X'.
          l_concount_bs = l_concount_bs + 1.
        ENDIF.
      ELSE.
        l_conflictcount = l_conflictcount + 1.
      ENDIF.
    ENDLOOP.
    FREE : lt_output.
    DATA : lt_1stoutput_count_users LIKE TABLE OF 1stoutput.
    IF lt_1stoutput_count_users[] IS INITIAL.
      lt_1stoutput_count_users[] = 1stoutput[].
      SORT lt_1stoutput_count_users[] BY bname.
      DELETE ADJACENT DUPLICATES FROM
        lt_1stoutput_count_users COMPARING bname.
    ENDIF.
    l_totals_counted = 'X'.
  ENDIF.
* Case 2071 : Divide by zero
  IF l_usercount > 0.
    l_averagecon   = l_conflictcount / l_usercount.
  ENDIF.
  c_usercount     = l_usercount.
  c_averagecon    = l_averagecon.
  c_tusercount    = tusercount.
  c_totalcon      = l_conflictcount.
  c_beforesimucon = l_concount_bs.
  CONCATENATE  c_tusercount text-059 text-060 c_averagecon text-061
              c_usercount text-062
              INTO l_alv_grid_titl2 SEPARATED BY space.
  CONDENSE l_alv_grid_titl2.


*TITLE AREA
  wa-typ = text-072.
  wa-info = text-h09.
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
  WRITE sy-datum TO l_exedate.


  wa-typ = 'S'.
  wa-key = text-h10.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR


  CONCATENATE g_current_user"sy-uname C0700
   text-h11 l_exedate l_exetime text-h47 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.


*NEXT LINE.
  wa-typ = text-073.
  wa-key = text-h12.
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.

*HBHALLA:(03/11/23) BEGIN OF BOC.
  l_local = text-h50.
  l_remote = text-h51.
  l_cross = text-h52.
  wa-typ = 'S'.
  wa-key = text-h49.

*HBHALLA:(04/12/23) BEGIN OF BOC.
  IF p_local = 'X'.
    CONCATENATE l_origin l_local INTO l_origin.
    IF p_local = 'X' AND p_remote = 'X'.
      CONCATENATE l_origin l_remote INTO l_origin SEPARATED BY ' & '.
      IF p_local = 'X' AND p_remote = 'X' AND p_cross = 'X'.
        CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
      ENDIF.
    ELSEIF p_local = 'X' AND p_cross = 'X'.
      CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
    ENDIF.

  ELSEIF p_remote = 'X'.
    CONCATENATE l_origin l_remote INTO l_origin.
    IF p_remote = 'X' AND p_cross = 'X'.
      CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
    ENDIF.

  ELSEIF p_cross = 'X'.
    CONCATENATE l_origin l_cross INTO l_origin.
  ENDIF.
*END OF CHANGE.


  wa-info = l_origin.
  APPEND wa TO header.
*END OF CHANGE.

  IF xmc = 'X'.
    PERFORM add_miti_info_to_sumline USING header.
  ENDIF.


  IF bysimu = 'X' OR byrsimu = 'X' OR
      ebysimu = 'X'  OR ebrsimu = 'X'.
*--Before Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'Before simulation'(h38).
    CONCATENATE c_beforesimucon 'Conflicts'(h40)
    INTO wa-info SEPARATED BY space .
    APPEND wa TO header.
*--After Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'After simulation'(h39).
    CONCATENATE c_totalcon 'Conflicts'(h40)
    INTO wa-info SEPARATED BY space .
    APPEND wa TO header.
  ENDIF.

  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    wa-typ = text-073.
    wa-key = text-h28.
    CONDENSE l_pages NO-GAPS.
    wa-info = l_pages.
    APPEND wa TO header.
  ENDIF.
*---Historical Time frame
  IF lvl1 IS INITIAL.
    wa-typ = 'S'.
    wa-key = 'SOD Live Date Range:'(H45).
    WRITE lvl2st TO l_from_date.
    WRITE lvl2ed TO l_to_date.

    CONCATENATE l_from_date 'to'(h46) l_to_date INTO wa-info
    SEPARATED BY space.
    APPEND wa TO header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header
      i_logo             = '/PSYNG/SE_LOGO'.
*--Only output messages for each page when not in background mode.
  IF ( sy-batch  IS INITIAL AND sy-binpt IS INITIAL )
     OR  l_msg_displayed IS INITIAL.
    IF gf_missing_auth = space.
      IF g_mit_message IS INITIAL
      AND g_tcode_exe_message IS INITIAL.
        IF bysimu = 'X' OR byrsimu = 'X'.
          MESSAGE s398(00) WITH
 'Number of SOD conflicts found after simulation  :'(210)
l_conflictcount.
        ELSE.
          MESSAGE s398(00) WITH
          'Number of SOD conflicts found  :'(l09) l_conflictcount.
        ENDIF.
      ENDIF.
    ELSE.
      gf_auth_fail = 'X'.
      MESSAGE w190(/psyng/sw).
    ENDIF.

    IF gf_st_missing_auth = 'X'.
      MESSAGE w191(/psyng/sw).
    ENDIF.

    l_msg_displayed = 'X'.
    COMMIT WORK.
  ENDIF.

  CLEAR g_mit_message.
  CLEAR g_tcode_exe_message.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_simulation_roles_for_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM get_simulation_roles_for_role.
*  DATA: wa_iagr_define TYPE /psyng/sw_sod_remote_roles,
*        l_rfc_error(150) TYPE c.
*
*  IF rolerfc = space.
*    SELECT agr_name INTO wa_iagr_define-agr_name FROM agr_define WHERE
*                                                 agr_name IN simurols
*                                                 AND attributes <> 'X'.
***      agrs-agr_name = wa_iagr_define-agr_name.
*      wa_iagr_define-agr_name = wa_iagr_define-agr_name.
*      wa_iagr_define-rfcdest = 'LOCAL'.
*      INSERT wa_iagr_define INTO TABLE gt_simuagrs.
*    ENDSELECT.
*  ELSEIF rolerfc <> space.
*    gt_fields-fieldname = 'AGR_NAME'.
*    APPEND gt_fields.
*    gt_fields-fieldname = 'PARENT_AGR'.
*    APPEND gt_fields.
*    CALL FUNCTION 'RFC_READ_TABLE'
*      DESTINATION rolerfc
*      EXPORTING
*        query_table                = 'AGR_DEFINE'
*      TABLES
**     options                    =  "FOR NOW GET ALL ENTRIES.
*        fields                     = gt_fields
*        data                       = gt_data
*       EXCEPTIONS
*         system_failure        = 1 MESSAGE l_rfc_error
*         communication_failure = 2 MESSAGE l_rfc_error
*         OTHERS                = 3 .
*    IF sy-subrc <> 0.
*      PERFORM report_rfc_error USING l_rfc_error.
*    ENDIF.
*
*    LOOP AT gt_data.
*      gt_simuagrs-rfcdest = rolerfc.
*      gt_simuagrs-agr_name = gt_data-wa+0(30).
*      IF gt_simuagrs-agr_name IN simurols.
*        APPEND gt_simuagrs.
*      ENDIF.
*    ENDLOOP.
*
*
**DHORIONS 2012/06/07 : Commenting this out, it prevents simulating
** composite roles on a remote system
**    REFRESH fields.
**    fields-fieldname = 'AGR_NAME'.
**    APPEND fields.
**    CALL FUNCTION 'RFC_READ_TABLE'
**      DESTINATION rolerfc
**      EXPORTING
**        query_table                = 'AGR_AGRS'
**      TABLES
***     options                    =  "FOR NOW GET ALL ENTRIES.
**        fields                     = fields
**        data                       = data_agrs
**       EXCEPTIONS
**         system_failure        = 1 MESSAGE l_rfc_error
**         communication_failure = 2 MESSAGE l_rfc_error
**         OTHERS                = 3 .
**    IF sy-subrc <> 0.
**      PERFORM report_rfc_error USING l_rfc_error rolerfc.
**    ENDIF.
**
**    LOOP AT data_agrs.
**      LOOP AT simuagrs WHERE agr_name = data_agrs-wa+0(30).
**        DELETE simuagrs.
**      ENDLOOP.
**    ENDLOOP.
*  ENDIF.    "rolerfc = space
*
**   check if roles that were requested exist
*  IF rolerfc IS INITIAL.
*    LOOP AT simurols WHERE sign = 'I' AND option = 'EQ'.
*      READ TABLE gt_simuagrs WITH KEY agr_name = simurols-low.
*      IF sy-subrc <> 0.
*        MESSAGE i154(/psyng/sw) WITH simurols-low.
**   Simulated role & does not exist.
*
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
*
*ENDFORM.                    " get_simulation_roles_for_role

*&---------------------------------------------------------------------*
*&      Form  report_rfc_error
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_RFC_ERROR  text
*      -->P_ROLERFC  text
*----------------------------------------------------------------------*
FORM report_rfc_error USING  rolerfc.
  MESSAGE i113(/psyng/sw) WITH  rolerfc text-e02.
  STOP.

ENDFORM.                    " report_rfc_error
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
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " disp_total_server_groups

*&---------------------------------------------------------------------*
*&      Form  load_user_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USER_RFC  text
*      -->P_ET_RETURN  text
*----------------------------------------------------------------------*
FORM load_user_rfc
    TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.


  IF NOT it_user_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
    WHERE rfcdest IN it_user_rfc.
  ENDIF.

ENDFORM.                    " validate_user_rfc
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
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr..
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
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
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
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
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr.

*--Check what FM is configured for search help for department
  se_config_param 'SW_DEPART_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
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
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
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

  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr.


  CLEAR ls_config_fm.
*--Check what FM is configured for Central Userid information
  se_config_param 'SW_CENTRAL_USR_FM' ls_config_fm-value.

  IF NOT ls_config_fm IS INITIAL.
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
    ELSE..
      l_repid = sy-repid.
      l_dynnr = sy-dynnr.
*Get Central Userid information as search help
      CALL FUNCTION ls_fmname                "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
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
*---------------------------------------------------------------------*
*       FORM refresh_output                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM refresh_output.
  CONSTANTS : lc_fld(33) VALUE '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.

*  DATA : l_fld TYPE string.
* Refresh the grid with the new data
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.
*  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*  ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <g_grid>."HBHALLA
*  ASSIGN  (l_fld) TO <g_grid>."HBHALLA
  ASSIGN  (lc_fld) TO <g_grid>.              "#EC PATHLOCK_CI_DYN_ACCES
  CALL METHOD <g_grid>->refresh_table_display.
ENDFORM.                    " refresh_output

*&---------------------------------------------------------------------*
*&      Form  mitigate
*&---------------------------------------------------------------------*
*       Edit mitigation assignments
*----------------------------------------------------------------------*
FORM mitigate.
  DATA:  lt_mcuser        TYPE TABLE OF /psyng/mitigation_assignment
         WITH HEADER LINE,
         ls_mcuser        TYPE /psyng/mitigation_assignment,
         lt_users         TYPE TABLE OF /psyng/sw_sel_opts_xubname
                       WITH HEADER LINE,
         lt_confs         TYPE TABLE OF /psyng/sw_sel_opts_conid
                       WITH HEADER LINE,
         lt_mcuser_all    TYPE TABLE OF /psyng/mitigation_assignment,
         lf_noconf_msg    TYPE /psyng/bapiflagx,
         lt_sw_uinfo      TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE
         ,
         l_system_msg(80),
         lt_simu_roles    TYPE TABLE OF /psyng/sw_sod_remote_roles WITH
HEADER LINE,
         lt_unique_rfcs   TYPE TABLE OF /psyng/sw_role_addition_simu
         WITH
             HEADER LINE,
         lt_role_names    TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_uinfo         TYPE TABLE OF /psyng/sw_uinfo_remote WITH
         HEADER LINE,
         lt_usgrp         TYPE TABLE OF usgrp WITH HEADER LINE,
         lf_display       TYPE /psyng/bapiflagx.


  lt_users-sign   = lt_confs-sign   = 'I'.
  lt_users-option = lt_confs-option = 'EQ'.
  LOOP AT 1stoutput WHERE sel = 'X'.
    IF 1stoutput-conid = 'ALL'.
      MESSAGE e019.
    ENDIF.
*
    IF gf_use_sec_obj = 'X'.
      READ TABLE lt_usgrp WITH KEY usergroup = 1stoutput-class.
      IF sy-subrc NE 0.
*-- Check Create/Modify Authority
        IF NOT 1stoutput-class IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
           ID 'ACTVT' FIELD '22'
           ID 'CLASS' FIELD 1stoutput-class
           ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
          IF sy-subrc NE 0.
            AUTHORITY-CHECK OBJECT 'Y&SW_MSU2'
               ID 'ACTVT' FIELD '23'
               ID 'CLASS' FIELD 1stoutput-class
               ID 'Y&SW_BNAME' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_CNTID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_COMP'  FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_CONID' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
            IF sy-subrc NE 0.
              lt_usgrp-usergroup = 1stoutput-class.
              APPEND lt_usgrp.
              MESSAGE i108 WITH
              'mitigate users of User group : '(215) 1stoutput-class.
              CONTINUE.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

    READ TABLE lt_usgrp WITH KEY usergroup = 1stoutput-class.
    CHECK sy-subrc NE 0.
    lt_users-low = 1stoutput-bname.
    APPEND lt_users.

    lt_uinfo-bname = 1stoutput-bname.
    APPEND lt_uinfo.

    lt_confs-low = 1stoutput-conid.
    APPEND lt_confs.
  ENDLOOP.
  IF sy-subrc <> 0.
    MESSAGE i135 WITH
    'Please select at least 1 record to mitigate.'(214).
  ENDIF.
  CHECK NOT lt_users[] IS INITIAL.

  IF bysimu = 'X'.

    RANGES : range_roles FOR agr_define-agr_name.
    lt_unique_rfcs[] = gt_role_addition_simu[].
    SORT lt_unique_rfcs BY source_rfcdest.
    DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs COMPARING
    source_rfcdest.

    LOOP AT lt_unique_rfcs.
      REFRESH : range_roles.
      LOOP AT gt_role_addition_simu
      WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
        MOVE-CORRESPONDING gt_role_addition_simu TO range_roles.
        APPEND range_roles.
      ENDLOOP.

      IF lt_unique_rfcs-source_rfcdest IS INITIAL OR
           lt_unique_rfcs-source_rfcdest = 'LOCAL'.
*--Get list of roles matching range
        CALL FUNCTION '/PSYNG/SW_102'
          TABLES
            it_roles_range = range_roles
            et_roles       = lt_role_names.

        lt_simu_roles-rfcdest =  lt_unique_rfcs-source_rfcdest.

        LOOP AT lt_role_names.
          lt_simu_roles-agr_name = lt_role_names-agr_name.
          APPEND lt_simu_roles.
        ENDLOOP.
      ELSE.
*--Get list of roles matching range
        lt_simu_roles-rfcdest =  lt_unique_rfcs-source_rfcdest.
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
          DESTINATION lt_unique_rfcs-source_rfcdest
          TABLES
            it_roles_range = range_roles
            et_roles       = lt_role_names.      "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        LOOP AT lt_role_names.
          lt_simu_roles-agr_name = lt_role_names-agr_name.
          APPEND lt_simu_roles.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDIF.

  SORT lt_users.
  DELETE ADJACENT DUPLICATES FROM lt_users COMPARING ALL FIELDS.

  SORT lt_confs.
  DELETE ADJACENT DUPLICATES FROM lt_confs COMPARING ALL FIELDS.
*--Reload mitigations
  ls_mcuser-vrsio = sodvrsio.
  LOOP AT gt_rfcdes.
    IF gt_rfcdes-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_071'
        EXPORTING
          i_vrsio      = sodvrsio
          i_start_date = '00000000'
          i_end_date   = '00000000'
        TABLES
          it_users     = lt_users
          it_confs     = lt_confs
          et_mcusers   = lt_mcuser
*         it_simu_roles_rfc = lt_simu_roles
          it_uinfo     = lt_uinfo.
    ELSE.
      READ TABLE gt_rfcdest WITH KEY rfcdest = gt_rfcdes-rfcdest.
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
        CALL FUNCTION '/PSYNG/SW_071'
          DESTINATION gt_rfcdes-rfcdest
          EXPORTING
            i_vrsio               = sodvrsio
            i_start_date          = '00000000'
            i_end_date            = '00000000'
          TABLES
            it_users              = lt_users
            it_confs              = lt_confs
            et_mcusers            = lt_mcuser
*           it_simu_roles_rfc     = lt_simu_roles
            it_uinfo              = lt_uinfo
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
              text-e05
              gt_rfcdes-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e05
              gt_rfcdes-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.

    APPEND LINES OF lt_mcuser TO lt_mcuser_all.
    REFRESH lt_mcuser.
  ENDLOOP.
*


  CLEAR lf_noconf_msg.
  LOOP AT 1stoutput WHERE sel = 'X'.
    READ TABLE lt_usgrp WITH KEY usergroup = 1stoutput-class.
    CHECK sy-subrc NE 0.
    IF 1stoutput-conid = '----'.
      IF lf_noconf_msg IS INITIAL.
        MESSAGE i021.
        lf_noconf_msg = 'X'.
      ENDIF.
      CONTINUE.
    ENDIF.

    LOOP AT lt_mcuser_all INTO lt_mcuser
            WHERE userid = 1stoutput-bname
              AND conid  = 1stoutput-conid
              AND vrsio  = sodvrsio
              AND org_abb = 1stoutput-abb.
      APPEND lt_mcuser.
    ENDLOOP.

*   Check if there are any records from the present or future
    LOOP AT lt_mcuser WHERE userid = 1stoutput-bname
                        AND conid  = 1stoutput-conid
                        AND vrsio  = sodvrsio
                        AND to_date >= sy-datum
                        AND type = 1
                        AND org_abb = 1stoutput-abb.
      EXIT.
    ENDLOOP.

    IF sy-subrc <> 0.
      CLEAR ls_mcuser .
      ls_mcuser-vrsio   = sodvrsio.
      CONCATENATE sy-sysid sy-mandt INTO ls_mcuser-rfcdest.
      ls_mcuser-conid   = 1stoutput-conid.
      ls_mcuser-userid  = 1stoutput-bname.
      ls_mcuser-org_abb = 1stoutput-abb.
      APPEND ls_mcuser TO lt_mcuser.
    ENDIF.
  ENDLOOP.

  IF sy-subrc <> 0 OR lt_mcuser[] IS INITIAL.
    MESSAGE e146.
  ENDIF.

* get all users and their companies as they are defined (locally or
* remotely) and displayed in output
  CLEAR lt_sw_uinfo.
  REFRESH lt_sw_uinfo.
  LOOP AT 1stoutput WHERE sel = 'X'.
    AT NEW bname.
      lt_sw_uinfo-bname = 1stoutput-bname.
*      lt_sw_uinfo-company = 1stoutput-company.
*Compshort contains company ID, while company field contains long text
      lt_sw_uinfo-company = 1stoutput-compshort.

      APPEND lt_sw_uinfo.
    ENDAT.
  ENDLOOP.
  SORT lt_sw_uinfo BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_sw_uinfo COMPARING bname.


  CALL FUNCTION '/PSYNG/SW_076'
    EXPORTING
      if_display          = ' '
      if_call_from_report = 'X'
      if_upd_scan_tab     = ustb
      if_upd_scan_enh     = p_enhanc
    TABLES
      it_mcuser           = lt_mcuser
      it_rfcdest          = gt_rfcdes
      it_sw_uinfo         = lt_sw_uinfo.

*--Reload mitigations
  ls_mcuser-vrsio = sodvrsio.
  REFRESH : lt_mcuser_all[].
  LOOP AT gt_rfcdes.
    IF gt_rfcdes-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_071'
        EXPORTING
          i_vrsio           = sodvrsio
          i_start_date      = '00000000'
          i_end_date        = '00000000'
        TABLES
          it_users          = lt_users
          it_confs          = lt_confs
          et_mcusers        = lt_mcuser
          it_simu_roles_rfc = lt_simu_roles
          it_uinfo          = lt_uinfo.
    ELSE.
      READ TABLE gt_rfcdest WITH KEY rfcdest = gt_rfcdes-rfcdest.
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
        CALL FUNCTION '/PSYNG/SW_071'
          DESTINATION gt_rfcdes-rfcdest
          EXPORTING
            i_vrsio               = sodvrsio
            i_start_date          = '00000000'
            i_end_date            = '00000000'
          TABLES
            it_users              = lt_users
            it_confs              = lt_confs
            et_mcusers            = lt_mcuser
            it_simu_roles_rfc     = lt_simu_roles
            it_uinfo              = lt_uinfo
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
              text-e05
              gt_rfcdes-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e05
              gt_rfcdes-rfcdest.
          ENDCASE.
          COMMIT WORK.
        ENDIF.
      ENDIF.
    ENDIF.

    APPEND LINES OF lt_mcuser TO lt_mcuser_all.
    REFRESH lt_mcuser.
  ENDLOOP.
  lt_mcuser[] = lt_mcuser_all[].

  LOOP AT lt_mcuser.
    READ TABLE gt_mchdr WITH KEY contid = lt_mcuser-contid.
    IF gt_mchdr-inactive = 'X'.
      DELETE lt_mcuser WHERE contid = gt_mchdr-contid.
    ENDIF.
  ENDLOOP.


*--Reflect the changes in the output
  SORT lt_mcuser BY userid conid type contid DESCENDING.
  LOOP AT 1stoutput WHERE sel = 'X'.
    DELETE gt_mcuser WHERE userid = 1stoutput-bname
                       AND conid  = 1stoutput-conid
                       AND vrsio  = sodvrsio.
*--Store all mitigations in memory (including future ones)
    LOOP AT lt_mcuser WHERE userid     = 1stoutput-bname
                        AND conid      = 1stoutput-conid.
      MOVE-CORRESPONDING lt_mcuser TO gt_mcuser.
      APPEND gt_mcuser.
    ENDLOOP.
*--Show all current mitigations on screen
    LOOP AT lt_mcuser WHERE userid     = 1stoutput-bname
                        AND conid      = 1stoutput-conid
                        AND org_abb    = 1stoutput-abb
                        AND from_date <= sy-datum
                        AND to_date   >= sy-datum.

      1stoutput-contid    = lt_mcuser-contid.
      1stoutput-auditor   = lt_mcuser-auditor.
      1stoutput-from_date = lt_mcuser-from_date.
      1stoutput-to_date   = lt_mcuser-to_date.
      CASE lt_mcuser-type.
        WHEN '1'.
          1stoutput-mit_icon = '@EK@'.
        WHEN '2'.
          1stoutput-mit_icon = '@ID@'.
        WHEN '4'.
          1stoutput-mit_icon = '@F8@'.
      ENDCASE.

      EXIT.
    ENDLOOP.
    IF sy-subrc <> 0.
      CLEAR: 1stoutput-contid, 1stoutput-auditor, 1stoutput-from_date,
             1stoutput-to_date,1stoutput-mit_icon.
    ENDIF.

    MODIFY 1stoutput TRANSPORTING
      contid auditor from_date to_date mit_icon.
  ENDLOOP.

*  MESSAGE s002(/psyng/sw) WITH 'Mitigation Update Saved.'.
  g_mit_message = 'X'.
*--Refresh the ALV
  PERFORM refresh_output.
ENDFORM.                    " mitigate

*&---------------------------------------------------------------------*
*&      Form  get_user_name
*&---------------------------------------------------------------------*
*       Get user name
*----------------------------------------------------------------------*
*      -->I_BNAME      User ID
*      <--E_USER_NAME  User name
*----------------------------------------------------------------------*
FORM get_user_name USING    i_bname TYPE /psyng/bc_uidn-bname
              CHANGING e_user_name TYPE /psyng/bc_userid_name-name_full.
  TYPES: BEGIN OF t_user,
           userid    TYPE /psyng/user,
           name_text TYPE /psyng/bc_uidn-name_text,
         END OF t_user.

  STATICS: lt_user TYPE HASHED TABLE OF t_user WITH UNIQUE KEY userid.

  DATA: ls_user     TYPE t_user,
        lt_username LIKE TABLE OF /psyng/bc_userid_name
                    WITH HEADER LINE.


  READ TABLE lt_user INTO ls_user WITH TABLE KEY userid = i_bname.
  IF sy-subrc = 0.
    e_user_name = ls_user-name_text.
    EXIT.
  ENDIF.

  lt_username-bname = i_bname.
  APPEND lt_username.

  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
    EXPORTING
      no_email = 'X'
    TABLES
      username = lt_username.

  READ TABLE lt_username INDEX 1.
  e_user_name       = lt_username-name_full.
  ls_user-userid    = i_bname.
  ls_user-name_text = e_user_name.
  INSERT ls_user INTO TABLE lt_user.
ENDFORM.                    " get_user_name
*&---------------------------------------------------------------------*
*&      Form  add_miti_info_to_sumline
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM add_miti_info_to_sumline USING header TYPE slis_t_listheader.

  DATA: lf_tot_confs     TYPE i,       "total conflicts in int
        lf_tot_confsc(8) TYPE c,   "total conflicts in char
        lf_tot_mits      TYPE i,        "total mitigations in int
        lf_tot_mitsc(8)  TYPE c,    "total mitigations in char
        wa               TYPE slis_listheader,
        alv_grid_titl2   TYPE lvc_title.

* get total number of conflicts and mitigations
  LOOP AT 1stoutput WHERE conid <> '----'.
    ADD 1 TO lf_tot_confs.
    CHECK NOT 1stoutput-contid IS INITIAL .
    ADD 1 TO lf_tot_mits.
  ENDLOOP.

  WRITE lf_tot_confs TO lf_tot_confsc.
  WRITE lf_tot_mits TO lf_tot_mitsc.

  CONCATENATE lf_tot_confsc text-094 lf_tot_mitsc text-095
              INTO alv_grid_titl2 SEPARATED BY space.

  wa-typ = text-073.
  wa-key = text-h21.
  wa-info = alv_grid_titl2.
  APPEND wa TO header.

ENDFORM.                    " add_miti_info_to_sumline

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

  STATICS: lt_comp      TYPE HASHED TABLE OF t_comp WITH UNIQUE KEY comp
  ,
           l_fm_checked TYPE flag.

  CHECK l_fm_checked IS INITIAL OR gf_company_longtext = 'X'.
  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
  se_config_param 'SW_MGMT_COMP_NAME_FM' l_value.
  IF sy-subrc = 0 AND NOT l_value IS INITIAL.
    l_fmname = l_value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = l_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*     Configured FM does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
              'Cannot determine SW_MGMT_COMP_NAME_FM with FM '
              l_fmname '. FM doesn''t exist'.
    ELSE.
      gf_company_longtext = 'X'.
    ENDIF.
  ELSE.
    EXIT.
    CLEAR gf_company_longtext.
  ENDIF.
*--Only call FM when configured
  IF NOT l_fmname IS INITIAL.
    CALL FUNCTION l_fmname                   "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
      EXPORTING
        i_company   = i_company
      IMPORTING
        e_comp_name = e_comp_name.

    ls_comp-comp = i_company.
    ls_comp-name = e_comp_name.
    INSERT ls_comp INTO TABLE lt_comp.
  ENDIF.
  l_fm_checked = 'X'.
ENDFORM.                    " get_comp_name


*--SE2.6 - Handling of collapsible sections in selection screen
*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'USER_BUT' 'X' CHANGING user_but .
  PERFORM init_but USING 'REM_BUT'  '' CHANGING rem_but  .
  PERFORM init_but USING 'CON_BUT'  '' CHANGING con_but  .
  PERFORM init_but USING 'OUT_BUT'  '' CHANGING out_but  .
  PERFORM init_but USING 'EXE_BUT'  '' CHANGING exe_but  .
  PERFORM init_but USING 'TXE_BUT'  '' CHANGING txe_but  .
  PERFORM init_but USING 'SIMU_BUT'  '' CHANGING simu_but .
  PERFORM init_but USING 'ESM_BUT'  '' CHANGING esm_but .

  PERFORM init_but USING 'BGD_BUT'  '' CHANGING bgd_but  .
  PERFORM init_but USING 'LIV_BUT'  '' CHANGING liv_but  .


  PERFORM handle_sections.
ENDFORM.                    " set_button_icons

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
         l_exp    TYPE flag.
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
  DATA : ls_state TYPE /psyng/usr_displ,
         ls_swconfig       TYPE /psyng/swconfig.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

*Begin of change:HBHALLA (PN-17036) (05/01/26)
  CLEAR ls_swconfig.
  se_config_param 'EN_INTEGRATION' ls_swconfig-value.

  IF i_button(3) <> '@3T'.
   IF i_name <> 'ESM_BUT' OR ls_swconfig-value = 'Y'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
    CLEAR g_button_set.
   ENDIF.
*End of change:HBHALLA (PN-17036) (05/01/26)
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
    g_button_set = 'X'.
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
*     text       = text-b01
*     info       = text-x02
      name       = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result     = button
    EXCEPTIONS
      icon_not_found = 1
      outputfiled_too_short = 2
      OTHERS     = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
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
*     text       = text-b01
*     info       = text-x01
      name       = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result     = button
    EXCEPTIONS
      icon_not_found = 1
      outputfiled_too_short = 2
      OTHERS     = 3.
  "(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " collapse
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
    WHEN 'USER_BUT'.
      PERFORM toggle USING user_but 'USER_BUT'.
    WHEN 'REM_BUT'.
      PERFORM toggle USING rem_but 'REM_BUT'.
    WHEN 'CON_BUT'.
      PERFORM toggle USING con_but 'CON_BUT'.
    WHEN 'OUT_BUT'.
      PERFORM toggle USING out_but 'OUT_BUT'.
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
    WHEN 'TXE_BUT'.
      PERFORM toggle USING txe_but 'TXE_BUT'.
    WHEN 'SIMU_BUT'.
      PERFORM toggle USING simu_but 'SIMU_BUT'.
    WHEN 'ESM_BUT'.
      PERFORM toggle USING esm_but 'ESM_BUT'.
    WHEN 'LIV_BUT'.
      PERFORM toggle USING liv_but 'LIV_BUT'.
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
  PERFORM handle_section USING  user_but 'USR'.
  PERFORM handle_section USING  rem_but  'REM'.
  PERFORM handle_section USING  con_but  'CON'.
  PERFORM handle_section USING  out_but  'OUT'.
  PERFORM handle_section USING  exe_but  'EXE'.
  PERFORM handle_section USING  txe_but  'TXE'.
  PERFORM handle_section USING  simu_but  'SIM'.
  PERFORM handle_section USING  esm_but  'ESM'.
  PERFORM handle_section USING  bgd_but  'BGD'.
  PERFORM handle_section USING  liv_but  'LIV'.
ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  detailed_sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1STOUTPUT_CONID  text
*----------------------------------------------------------------------*
FORM detailed_sod_analysis
  USING
    is_output LIKE 1stoutput
    if_all    TYPE flag.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
         ls_conid TYPE /psyng/sw_sel_opts_conid.
***** Print Parameters fo Backround Job
  DATA: lwa_params TYPE pri_params,
        lv_valid   TYPE c.
  DATA: gs_swconfig_bkgd_job TYPE /psyng/swconfig,
        l_line_count         TYPE i VALUE 65.
  CLEAR: lwa_params, lv_valid.
  PERFORM export_dates_2_memory.

  IF if_all IS INITIAL.
*--User clicked on Conflict ID in summary output
    iseltab-selname = 'PBNAME'.    "user ID
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = is_output-bname.
    APPEND iseltab.
    iseltab-selname = 'SPCONFS'.   "specific onflicts
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = is_output-conid.
    APPEND iseltab.
    iseltab-selname = 'BYUSER'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    iseltab-selname = 'SHODET'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
    iseltab-selname = 'SHOSUM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ' '.
    APPEND iseltab.

    iseltab-selname = 'ERROLES'.
    iseltab-kind = 'P'.
    iseltab-sign = 'I'.
    iseltab-option = 'EQ'.
    iseltab-low  = erroles.
    APPEND iseltab.

    iseltab-selname = 'EXCL_ER'.
    iseltab-kind = 'P'.
    iseltab-sign = 'I'.
    iseltab-option = 'EQ'.
    iseltab-low  = excl_er.
    APPEND iseltab.


    iseltab-selname = 'P_SODRFC'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_sodrfc  .
    APPEND iseltab.


    IF gf_mit_by_org = 'X' AND NOT is_output-abb IS INITIAL.
      iseltab-selname = 'ORGLVL'.
      iseltab-kind    = 'Q'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = is_output-abb .
      APPEND iseltab.
    ENDIF.

*Begin of Addition:HBHALLA (PN-15675) (Issue6) (14/11/25)
      iseltab-selname = 'PCLASS'.
      iseltab-kind    = 'S'.
      iseltab-sign    = pclass-sign.
      iseltab-option  = pclass-option.
      iseltab-low     = pclass-low.
      iseltab-high    = pclass-high.
      APPEND iseltab.

      iseltab-selname = 'S_DEPART'.
      iseltab-kind    = 'S'.
      iseltab-sign    = s_depart-sign.
      iseltab-option  = s_depart-option.
      iseltab-low     = s_depart-low.
      iseltab-high    = s_depart-high.
      APPEND iseltab.
*End of Addition:HBHALLA (PN-15675) (Issue6) (14/11/25)


  ELSE.


    iseltab-selname = 'USTB'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ustb.
    APPEND iseltab.

    iseltab-selname = 'SHODET'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = shodet.
    APPEND iseltab.
    iseltab-selname = 'SHOTREE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = shotree.
    APPEND iseltab.
    iseltab-selname = 'SHOSUM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = shosum.
    APPEND iseltab.

    iseltab-selname = 'SHOSIMP'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = shosimp.
    APPEND iseltab.

    iseltab-selname = 'BYALL'. "all user related options
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
*--Conflict Selection
    PERFORM get_conflicts_from_selection.
    LOOP AT gt_conid INTO ls_conid.
      iseltab-selname = 'SPCONFS'.
      iseltab-kind    = 'S'.
      iseltab-sign    = ls_conid-sign.
      iseltab-option  = ls_conid-option.
      iseltab-low     = ls_conid-low.
      iseltab-high    = ls_conid-high.
      APPEND iseltab.
    ENDLOOP.


*--User Selection
    IF NOT userlist[] IS INITIAL.
      LOOP AT userlist .
        iseltab-selname = 'PBNAME'.
        iseltab-kind    = 'S'.
        iseltab-sign    = userlist-sign.
        iseltab-option  = userlist-option.
        iseltab-low     = userlist-low.
        iseltab-high    = userlist-high.
        APPEND iseltab.
      ENDLOOP.
    ELSE.
      iseltab-selname = 'PBNAME'.
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'CP'.
      iseltab-low     = '*'.
*     iseltab-high    = gh.
      APPEND iseltab.
    ENDIF.
    LOOP AT pclass .
      iseltab-selname = 'PCLASS'.
      iseltab-kind    = 'S'.
      iseltab-sign    = pclass-sign.
      iseltab-option  = pclass-option.
      iseltab-low     = pclass-low.
      iseltab-high    = pclass-high.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT s_comp .
      iseltab-selname = 'S_COMP'.
      iseltab-kind    = 'S'.
      iseltab-sign    = s_comp-sign.
      iseltab-option  = s_comp-option.
      iseltab-low     = s_comp-low.
      iseltab-high    = s_comp-high.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT s_depart .
      iseltab-selname = 'S_DEPART'.
      iseltab-kind    = 'S'.
      iseltab-sign    = s_depart-sign.
      iseltab-option  = s_depart-option.
      iseltab-low     = s_depart-low.
      iseltab-high    = s_depart-high.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT s_cuid .
      iseltab-selname = 'S_CUID'.
      iseltab-kind    = 'S'.
      iseltab-sign    = s_cuid-sign.
      iseltab-option  = s_cuid-option.
      iseltab-low     = s_cuid-low.
      iseltab-high    = s_cuid-high.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT s_kostl .
      iseltab-selname = 'S_KOSTL'.
      iseltab-kind    = 'S'.
      iseltab-sign    = s_kostl-sign.
      iseltab-option  = s_kostl-option.
      iseltab-low     = s_kostl-low.
      iseltab-high    = s_kostl-high.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.

  LOOP AT usrtype .
    iseltab-selname = 'USRTYPE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = usrtype-sign.
    iseltab-option  = usrtype-option.
    iseltab-low     = usrtype-low.
    iseltab-high    = usrtype-high.
    APPEND iseltab.
  ENDLOOP.



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

**** en role simulation start : GG******
**** role addtion********
*--Role addition Simulation


  iseltab-selname = 'EBYSIMU'.     " By Simulate
  iseltab-kind = 'P'.
  iseltab-sign = 'I'.
  iseltab-option = 'EQ'.
  iseltab-low = ebysimu.
  APPEND iseltab.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.

  iseltab-selname = 'AR_SYSS1'.
  iseltab-low     =  ar_syss1.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSD1'.
  iseltab-low     =  ar_sysd1.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSS2'.
  iseltab-low     =  ar_syss2.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSD2'.
  iseltab-low     =  ar_sysd2.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSS3'.
  iseltab-low     =  ar_syss3.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSD3'.
  iseltab-low     =  ar_sysd3.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSS4'.
  iseltab-low     =  ar_syss4.
  APPEND iseltab.

  iseltab-selname = 'AR_SYSD4'.
  iseltab-low     =  ar_sysd4.
  APPEND iseltab.

  LOOP AT ae_rol_1.
    iseltab-selname = 'AE_ROL_1'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ae_rol_1 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT ae_rol_2.
    iseltab-selname = 'AE_ROL_2'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ae_rol_2 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT ae_rol_3.
    iseltab-selname = 'AE_ROL_3'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ae_rol_3 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  LOOP AT ae_rol_4.
    iseltab-selname = 'AE_ROL_4'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ae_rol_4 TO iseltab.
    APPEND iseltab.
  ENDLOOP.


*--Role Removal Simulation for en
  iseltab-selname = 'EBRSIMU'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ebrsimu.
  APPEND iseltab.

  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.

  iseltab-selname = 'RR_SYS_1'.
  iseltab-low     =  rr_sys_1.
  APPEND iseltab.

  iseltab-selname = 'RR_SYS_2'.
  iseltab-low     =  rr_sys_2.
  APPEND iseltab.

  iseltab-selname = 'RR_SYS_3'.
  iseltab-low     =  rr_sys_3.
  APPEND iseltab.

  iseltab-selname = 'RR_SYS_4'.
  iseltab-low     =  rr_sys_4.
  APPEND iseltab.

  LOOP AT en_rol_1.
    iseltab-selname = 'EN_ROL_1'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING en_rol_1 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT en_rol_2.
    iseltab-selname = 'EN_ROL_2'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING en_rol_2 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT en_rol_3.
    iseltab-selname = 'EN_ROL_3'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING en_rol_3 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT en_rol_4.
    iseltab-selname = 'EN_ROL_4'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING en_rol_4 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

****en role simulation end : GG

  iseltab-selname = 'SHOWCOMP'.  "Show composite role(s)
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = showcomp.
  APPEND iseltab.
  iseltab-selname = 'VALIDUSR'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = validusr.
  APPEND iseltab.

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


  iseltab-selname = 'XMC'.       "ignore mitigating controls
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = xmc.
  APPEND iseltab.
  iseltab-selname = 'P_ENHANC'.        "Include enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.
  iseltab-selname = 'ORGCHK'.       "Use Org Level Check
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = orgchk.
  APPEND iseltab.

  iseltab-selname = 'P_REMONL'.       "Only Analyze Remote Systems
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_remonl.
  APPEND iseltab.


  iseltab-selname = 'P_LOCUSR'.       "Only AnalyzeUsers that
  "exist locally
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_locusr.
  APPEND iseltab.


  iseltab-selname = 'BYSIMU'.     " By Simulate
  iseltab-kind = 'P'.
  iseltab-sign = 'I'.
  iseltab-option = 'EQ'.
  iseltab-low = bysimu.
  APPEND iseltab.

  iseltab-selname = 'ROLERFC'.  " RFC destination for Role
  iseltab-kind = 'P'.
  iseltab-sign = 'I'.
  iseltab-option = 'EQ'.
  iseltab-low = rolerfc.
  APPEND iseltab.

  LOOP AT simurols .                  " simu role
    iseltab-selname = 'SIMUROLS'.
    iseltab-kind    = 'S'.
    iseltab-sign    = simurols-sign.
    iseltab-option  = simurols-option.
    iseltab-low     = simurols-low.
    iseltab-high    = simurols-high.
    APPEND iseltab.
  ENDLOOP.
  IF xusrrfc[] IS INITIAL.
*--Add something  to XUSRRFC because otherwise
*  default rfc destinations will be used
    iseltab-selname = 'XUSRRFC'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'E'.
    iseltab-option  = 'CP'.
    iseltab-low     = '*'.
    CLEAR iseltab-high    .
    APPEND iseltab.
  ELSE.
    LOOP AT xusrrfc .                  "Cross system analysis
      iseltab-selname = 'XUSRRFC'.
      iseltab-kind    = 'S'.
      iseltab-sign    = xusrrfc-sign.
      iseltab-option  = xusrrfc-option.
      iseltab-low     = xusrrfc-low.
      iseltab-high    = xusrrfc-high.
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
  iseltab-selname = 'P_HIENHN'.       "higlight enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_hienhn.
  APPEND iseltab.

  LOOP AT orglvl .                  "Org Level Filter
    iseltab-selname = 'ORGLVL'.
    iseltab-kind    = 'S'.
    iseltab-sign    = orglvl-sign.
    iseltab-option  = orglvl-option.
    iseltab-low     = orglvl-low.
    iseltab-high    = orglvl-high.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'ERROLES'.       "Include ER-Roles
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = erroles.
  APPEND iseltab.

  iseltab-selname = 'EXCL_ER'.       "Include ER-Roles
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = excl_er.
  APPEND iseltab.


  iseltab-selname = 'SHOWPCOM'.       "Layout for detail out
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = showpcom.
  APPEND iseltab.


  iseltab-selname = 'P_DLAYO'.       "Layout for detail out
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  CASE 'X'.
    WHEN shodet.
      iseltab-low     = p_dlayo.
    WHEN shosimp.
      iseltab-low     = p_slayo.
  ENDCASE.
  APPEND iseltab.
*  p_dlayo

  LOOP AT s_role .                  " Roles for User
    iseltab-selname = 'S_ROLE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = s_role-sign.
    iseltab-option  = s_role-option.
    iseltab-low     = s_role-low.
    iseltab-high    = s_role-high.
    APPEND iseltab.
  ENDLOOP.

  LOOP AT s_prof .                  "Profiles for users
    iseltab-selname = 'S_PROF'.
    iseltab-kind    = 'S'.
    iseltab-sign    = s_prof-sign.
    iseltab-option  = s_prof-option.
    iseltab-low     = s_prof-low.
    iseltab-high    = s_prof-high.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'P_CALDET'.       "Call from Summary
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'P_ABAP'.       "Analyze SE systems
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_abap.
  APPEND iseltab.
  IF p_nabap = 'X'.
    iseltab-selname = 'P_NABAP'.       "EN analysis
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_nabap.
    APPEND iseltab.
    LOOP AT s_appl.
      iseltab-selname = 'S_APPL'.       "Application
      iseltab-kind    = 'S'.
      iseltab-sign    = s_appl-sign.
      iseltab-option  = s_appl-option.
      iseltab-low     = s_appl-low.
      iseltab-high     = s_appl-high.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT s_system.
      iseltab-selname = 'S_SYSID'.       "System
      iseltab-kind    = 'S'.
      iseltab-sign    = s_system-sign.
      iseltab-option  = s_system-option.
      iseltab-low     = s_system-low.
      iseltab-high     = s_system-high.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.


  iseltab-selname = 'CFGSET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = cfgset.
  APPEND iseltab.

*BOC AKUMAR C1454: User nationality
*  iseltab-selname = 'P_USRPAR'.
*  iseltab-kind    = 'P'.
*  iseltab-sign    = 'I'.
*  iseltab-option  = 'EQ'.
*  iseltab-low     = p_usrpar.
*  APPEND iseltab.
*EOC AKUMAR C1454

  LOOP AT s_usrpar.
    iseltab-selname = 'S_USRPAR'.
    iseltab-kind    = 'S'.
    iseltab-sign    = s_usrpar-sign.
    iseltab-option  = s_usrpar-option.
    iseltab-low     = s_usrpar-low.
    iseltab-high     = s_usrpar-high.
    APPEND iseltab.
  ENDLOOP.


  IF sy-batch IS INITIAL.
    SUBMIT  /psyng/sodreport_org_usr
      WITH SELECTION-TABLE iseltab
      AND RETURN.
  ELSE.
    se_config_param 'REPEAT_HDR_BKGDJOB' gs_swconfig_bkgd_job-value.

    IF gs_swconfig_bkgd_job-value = 'N'.
      l_line_count = 999999. "Setting Maximum line count to avoid
      "headers in spool.
    ENDIF.
    CALL FUNCTION 'GET_PRINT_PARAMETERS'
      EXPORTING
        in_parameters          = lwa_params
        layout                 = 'X_65_132'
        line_count             = l_line_count
        line_size              = 132
        no_dialog              = 'X'
      IMPORTING
        out_parameters         = lwa_params
        valid                  = lv_valid
      EXCEPTIONS
        archive_info_not_found = 1
        invalid_print_params   = 2
        invalid_archive_params = 3
        OTHERS                 = 4.

    CHECK sy-subrc EQ 0.
    SUBMIT /psyng/sodreport_org_usr TO SAP-SPOOL
        SPOOL   PARAMETERS lwa_params
        ARCHIVE PARAMETERS lv_valid
        WITHOUT SPOOL DYNPRO
        WITH SELECTION-TABLE iseltab AND RETURN.
  ENDIF.
ENDFORM.                    " detailed_sod_analysis
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

FORM prepare_role_addition_simu_en TABLES   et_role_addition_simu
STRUCTURE
                                          /psyng/ex_role_addition_simu.
*  READ TABLE s_appl INDEX 1.
  IF  NOT ae_rol_1[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss1.
    et_role_addition_simu-target_sysid = ar_sysd1.
    LOOP AT ae_rol_1.
      MOVE-CORRESPONDING ae_rol_1 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_2[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss2.
    et_role_addition_simu-target_sysid = ar_sysd2.
    LOOP AT ae_rol_2.
      MOVE-CORRESPONDING ae_rol_2 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_3[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss3.
    et_role_addition_simu-target_sysid = ar_sysd3.
    LOOP AT ae_rol_3.
      MOVE-CORRESPONDING ae_rol_3 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ae_rol_4[] IS  INITIAL.
*    et_role_addition_simu-appl = s_appl-low.
    et_role_addition_simu-source_sysid = ar_syss4.
    et_role_addition_simu-target_sysid = ar_sysd4.
    LOOP AT ae_rol_4.
      MOVE-CORRESPONDING ae_rol_4 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
ENDFORM.

FORM prepare_role_removal_simu_en TABLES   et_role_removal_simu
STRUCTURE
                                          /psyng/en_role_removal_simu.
*  READ TABLE s_appl INDEX 1.
  IF  NOT en_rol_1[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_1.
    LOOP AT en_rol_1.
      MOVE-CORRESPONDING en_rol_1 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT  en_rol_2[] IS INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_2.
    LOOP AT en_rol_2.
      MOVE-CORRESPONDING en_rol_2 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT en_rol_3[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_3.
    LOOP AT en_rol_3.
      MOVE-CORRESPONDING en_rol_3 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT en_rol_4[] IS  INITIAL.
*    et_role_removal_simu-appl  = s_appl-low.
    et_role_removal_simu-sysid = rr_sys_4.
    LOOP AT en_rol_4.
      MOVE-CORRESPONDING en_rol_4 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.

ENDFORM.
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
      SUBMIT /psyng/sodreport_sys_wide_org WITH
      SELECTION-TABLE gt_irsparams AND RETURN.
      SET SCREEN '000'.
      LEAVE SCREEN.

*--Resubmit report
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT


*---------------------------------------------------------------------*
*       MODULE user_command_0103 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0103 INPUT.

  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN '000'.
      LEAVE SCREEN.
    WHEN 'CONTINUE'.
*      PERFORM fill_sel_screen_fields_to_tab.
*      SUBMIT /psyng/sodreport_sys_wide_org WITH
*      SELECTION-TABLE irsparams AND RETURN.
      PERFORM fill_sel_screen_fields_to_tab.
      SUBMIT /psyng/sodreport_sys_wide_org WITH
      SELECTION-TABLE gt_irsparams AND RETURN.
      SET SCREEN '000'.
      LEAVE SCREEN.

*--Resubmit report
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT


*&---------------------------------------------------------------------*
*&      Module  STATUS_0102  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0102 OUTPUT.
  SET PF-STATUS '300' EXCLUDING 'CANCEL'.
*  SET TITLEBAR 'xxx'.

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
*  DATA : lt_remove_role TYPE TABLE OF /psyng/ex_removed_roles,
*        ls_remove_role TYPE /psyng/ex_removed_roles.
  SORT gt_removed_roles.
  DELETE ADJACENT DUPLICATES FROM gt_removed_roles.
  IF gr_alvgrid IS INITIAL .
    CREATE OBJECT gr_ccontainer
      EXPORTING
        container_name              = gc_custom_control_name
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
*    "Error handling
    ENDIF.
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent          = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*    Error handling
    ENDIF.
    PERFORM prepare_field_catalog_0102 CHANGING gt_fieldcat.
    PERFORM prepare_layout_0102        CHANGING gs_layout .
    IF byrsimu EQ 'X' .
*      AND ebrsimu NE 'X'.
      CALL METHOD gr_alvgrid->set_table_for_first_display
        EXPORTING
*       I_BUFFER_ACTIVE               =
*       I_CONSISTENCY_CHECK           =
*       I_STRUCTURE_NAME              =
*       IS_VARIANT                    =
*       I_SAVE                        =
*       I_DEFAULT                     = 'X'
          is_layout                     = gs_layout
*       IS_PRINT                      =
*       IT_SPECIAL_GROUPS             =
*       IT_TOOLBAR_EXCLUDING          =
*       IT_HYPERLINK                  =
        CHANGING
          it_outtab                     = gt_removed_roles[]
          it_fieldcatalog               = gt_fieldcat
*       IT_SORT                       =
*       IT_FILTER                     =
        EXCEPTIONS
          invalid_parameter_combination = 1
          program_error                 = 2
          too_many_lines                = 3
          OTHERS                        = 4.
      IF sy-subrc <> 0.
*    Error handling
      ENDIF.
    ELSE.
*      IF byrsimu EQ 'X' AND ebrsimu EQ 'X'.
*
*        LOOP AT gt_removed_roles.
*          ls_remove_role-bname =  gt_removed_roles-bname.
*          ls_remove_role-rfcdest =  gt_removed_roles-rfcdest.
*          ls_remove_role-key_val =  gt_removed_roles-agr_name.
*          APPEND ls_remove_role TO lt_remove_role.
*        ENDLOOP.
*
*        LOOP AT gt_role_removal_simu_en INTO gs_role_removal_simu_en.
**          ls_remove_role-bname =  gs_role_removal_simu_en-bname.
*          ls_remove_role-appl =  gs_role_removal_simu_en-appl.
*          ls_remove_role-sysid =  gs_role_removal_simu_en-sysid.
*          ls_remove_role-key_val =  gs_role_removal_simu_en-low.
*          APPEND ls_remove_role TO lt_remove_role.
*        ENDLOOP.
*
*      ELSEIF ebrsimu EQ 'X' AND byrsimu NE 'X'.
*        LOOP AT gt_role_removal_simu_en INTO gs_role_removal_simu_en.
**          ls_remove_role-bname =  gs_role_removal_simu_en-bname.
*          ls_remove_role-appl =  gs_role_removal_simu_en-appl.
*          ls_remove_role-sysid =  gs_role_removal_simu_en-sysid.
*          ls_remove_role-key_val =  gs_role_removal_simu_en-low.
*          APPEND ls_remove_role TO lt_remove_role.
*        ENDLOOP.
*      ENDIF.

*      CALL METHOD gr_alvgrid->set_table_for_first_display
*      EXPORTING
**       I_BUFFER_ACTIVE               =
**       I_CONSISTENCY_CHECK           =
**       I_STRUCTURE_NAME              =
**       IS_VARIANT                    =
**       I_SAVE                        =
**       I_DEFAULT                     = 'X'
*        is_layout                     = gs_layout
**       IS_PRINT                      =
**       IT_SPECIAL_GROUPS             =
**       IT_TOOLBAR_EXCLUDING          =
**       IT_HYPERLINK                  =
*      CHANGING
*        it_outtab                     = lt_remove_role[]
*        it_fieldcatalog               = gt_fieldcat
**       IT_SORT                       =
**       IT_FILTER                     =
*      EXCEPTIONS
*        invalid_parameter_combination = 1
*        program_error                 = 2
*        too_many_lines                = 3
*        OTHERS                        = 4.
*      IF sy-subrc <> 0.
**    Error handling
*      ENDIF.
    ENDIF.
  ELSE.
    CALL METHOD gr_alvgrid->refresh_table_display
*     EXPORTING
*     IS_STABLE =
*     I_SOFT_REFRESH =
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

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
  DATA: ls_fcat TYPE lvc_s_fcat,
        l_structure_name TYPE dd02l-tabname .
  l_structure_name = '/PSYNG/SW_REMOVED_ROLES'.
*  IF ebrsimu EQ 'X' AND byrsimu EQ 'X'.
*    l_structure_name = '/PSYNG/EX_REMOVED_ROLES'.
*  ELSEIF byrsimu EQ 'X' AND ebrsimu NE 'X'.
*    l_structure_name = '/PSYNG/SW_REMOVED_ROLES'.
*  ELSEIF ebrsimu EQ 'X' AND byrsimu NE 'X'.
*    l_structure_name = '/PSYNG/EX_REMOVED_ROLES'.
*  ENDIF.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = l_structure_name
    CHANGING
      ct_fieldcat            = et_fieldcat[]
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
*    Error handling
  ENDIF.
*  IF ebrsimu EQ 'X' AND byrsimu NE 'X'.
*    DELETE et_fieldcat WHERE fieldname = 'RFCNAME'.
*  ENDIF.
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
*FORM prepare_data_0102 CHANGING gt_remove_role_all TYPE
*                                        /psyng/ex_removed_roles.
*
*ENDFORM.

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
*&      Form  show_users_per_conflict
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_users_per_conflict.
  FREE : gt_userpercon_output.
  LOOP AT 1stoutput.
    MOVE-CORRESPONDING 1stoutput TO gt_userpercon_output.
    gt_userpercon_output-numusers = 1.
    COLLECT gt_userpercon_output.
  ENDLOOP.


  DATA: ls_variant           TYPE disvariant,
        lt_userpercon_output LIKE TABLE OF gs_userpercon_output.

  lt_userpercon_output[] = gt_userpercon_output[].
  FREE : gt_userpercon_output.

*  CONCATENATE sy-title text-093 sodvrsio
*              INTO sy-title SEPARATED BY space.
  CLEAR g_alv_layout.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.
  PERFORM build_alv_catalog_users_per_co.
  PERFORM build_sort_table_users_per_con.
**  PERFORM adjust_columns_users_per_conflict.
  CLEAR : sy-ucomm, g_ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
      i_grid_title = g_alv_grid_titl
*     i_callback_program       = program
*     i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      it_sort      = gt_isort
*     i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
      is_layout    = g_alv_layout
      it_fieldcat  = i_fieldcat_alv
      i_save       = 'A'
      is_variant   = ls_variant
    TABLES
      t_outtab     = lt_userpercon_output.


ENDFORM.                    " show_users_per_conflict
*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG_USERS_PER_CO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog_users_per_co.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  FREE : i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = g_program
      i_internal_tabname = 'GS_USERPERCON_OUTPUT'
      i_inclname         = g_program
    CHANGING
      ct_fieldcat        = i_fieldcat_alv.

*--Hide column Impsort
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-seltext_l = 'Sensitivity sort'(187).
  wa_fieldcat_alv-seltext_m = 'Sensitivity sort'(187).
  wa_fieldcat_alv-seltext_s = 'Sens. sort'(188).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity sort'(187).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMPSORT'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Number of users'(190).
  wa_fieldcat_alv-seltext_m = 'Users'(189).
  wa_fieldcat_alv-seltext_s = 'Users'(189).
  wa_fieldcat_alv-reptext_ddic = 'Number of users'(190).

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'NUMUSERS'.

  IF gf_mit_by_org <> 'X' OR orgchk <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  wa_fieldcat_alv-seltext_l = 'Organizational Area Abbreviation'(211).
  wa_fieldcat_alv-seltext_m = 'Org Area Abbr. '(212).
  wa_fieldcat_alv-seltext_s = 'Abbr.'(213).
  wa_fieldcat_alv-checkbox  = 'X'.
  wa_fieldcat_alv-just      = 'X'.
  wa_fieldcat_alv-hotspot   = 'X'.
  wa_fieldcat_alv-ddic_outputlen = 4. "RGUPTA on 14-02-22
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    seltext_l
                    seltext_m
                    seltext_s
                    no_out
                    just
                    ddic_outputlen "RGUPTA
                 WHERE
                    fieldname = 'ABB'.


ENDFORM.                    " BUILD_ALV_CATALOG_USERS_PER_CO
*&---------------------------------------------------------------------*
*&      Form  BUILD_SORT_TABLE_USERS_PER_CON
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort_table_users_per_con.
  FREE : gt_isort.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname   = 'GT_USERPERCON_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname   = 'GT_USERPERCON_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname   = 'GT_USERPERCON_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMPSORT'.
  l_sort-tabname   = 'GT_USERPERCON_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'ABB'.
  l_sort-tabname   = 'GT_USERPERCON_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.



ENDFORM.                    " BUILD_SORT_TABLE_USERS_PER_CON
*&---------------------------------------------------------------------*
*&      Form  get_conflicts_from_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_conflicts_from_selection.
*-- Validate Conflict

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
    IF NOT cowner[] IS INITIAL AND NOT it_conid[] IS INITIAL.
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

*---odubey 31.01.2022 start
*--include conflict for multiple propose mitigation
    IF NOT cprmit[] IS INITIAL.
      SELECT conid FROM /psyng/conpmit INTO CORRESPONDING FIELDS OF
        TABLE lt_conpmit WHERE contid IN cprmit
      AND    vrsio  =  sodvrsio.
      LOOP AT lt_conpmit.
        wa_conid-sign = 'I'.
        wa_conid-option = 'EQ'.
        wa_conid-low = lt_conpmit-conid.
        APPEND wa_conid TO gt_conid.
      ENDLOOP.
    ENDIF.


*--Also select the custom conflicts (SF 1697)
    IF cuscon EQ 'X'.
      SELECT conid FROM /psyng/sw_cuscon
      INTO CORRESPONDING FIELDS OF TABLE lt_cuscon
      WHERE vrsio = sodvrsio
      AND   inactive <> 'X'
      AND   conid IN spconfs
      AND   imp   IN csens
      AND   busarea IN pappa.
      LOOP AT lt_cuscon.
        wa_conid-sign = 'I'.
        wa_conid-option = 'EQ'.
        wa_conid-low = lt_cuscon-conid.
        APPEND wa_conid TO gt_conid.
      ENDLOOP.
    ENDIF.
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
*&      Form  set_print_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LINE_COUNT  text
*----------------------------------------------------------------------*
FORM set_print_param USING    p_line_count.
**The following FM will reset the line counts of a page in spool report
**Additinal 25 lines are added to include the number of lines of the
**first header of the output as the p_line_count contains only the
**record numbers of the output table.

  p_line_count = p_line_count + 25 .
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
    EXPORTING
      line_count = p_line_count.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  update_mid_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_mid_status.
  LOOP AT 1stoutput.
    READ TABLE gt_mchdr WITH KEY contid = 1stoutput-contid.
    IF sy-subrc = 0.
      1stoutput-inactive = gt_mchdr-inactive.
      MODIFY 1stoutput.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " update_mid_status
*&---------------------------------------------------------------------*
*&      Form  get_mc_header_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_mc_header_data.
  SELECT * FROM /psyng/mchdr INTO TABLE gt_mchdr.
ENDFORM.                    " get_mc_header_data

*---------------------------------------------------------------------*
*       FORM show_help                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_DOKNAME                                                     *
*---------------------------------------------------------------------*
FORM show_help USING    i_dokname.
  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
    EXPORTING
      dokname = i_dokname.
ENDFORM.                    " show_help

*---------------------------------------------------------------------*
*       FORM level3_details                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OUTPUT                                                      *
*---------------------------------------------------------------------*
FORM level3_details USING    i_output LIKE 1stoutput.

  CHECK i_output-level3 = 'X'.
  DATA : lt_confs   TYPE TABLE OF /psyng/sw_sel_opts_conid
                  WITH HEADER LINE,
         lt_bname   TYPE TABLE OF /psyng/sw_sel_opts_xubname
                  WITH HEADER LINE,
         lt_output  TYPE TABLE OF /psyng/sw_sod_output_org
                  WITH HEADER LINE,
         lt_details TYPE TABLE OF /psyng/sw_level3_details
                  WITH HEADER LINE.

  lt_confs-sign   = 'I'.
  lt_confs-option = 'EQ'.
  lt_confs-low    = 1stoutput-conid.
  APPEND lt_confs.
  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.
  lt_bname-low    = 1stoutput-bname.
  APPEND lt_bname.

*--Only if remote and cross are selected,
*  pass rfc destinations to FM
  DATA : lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest.
  IF NOT p_cross IS INITIAL OR
     NOT p_remote IS INITIAL.
    lt_rfcdest[] = xusrrfc[].
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_org_check          = orgchk
      i_validuser          = validusr
      i_exlckusr           = exlckusr
      i_outvdate           = outvdate
*     I_ALLUG              =
      i_vrsio              = sodvrsio
      i_function_details   = ' '
      i_shomit             = xmc
      i_enh                = p_enhanc
      i_hienh              = p_hienhn
      i_wp                 = wp
      i_xstb               = lf_dont_update_scan
      i_pserver            = pserver
      i_max_upp            = upp
      i_shonosod           = shonosod
      i_locsod             = p_locsod
      i_locusr             = p_locusr
      i_output             = odt
      i_remote_only        = p_remonl
      i_er_roles           = erroles
      i_level_2            = lvl2
      i_level_2_start      = lvl2st
      i_level_2_end        = lvl2ed
      i_level_3            = lvl3
      i_level_3_start      = lvl2st
      i_level_3_end        = lvl2ed
      i_level_3_changedocs = lvl3_cd
      i_level_3_tablog     = lvl3_tl
      i_level_3_details    = 'X'
      i_level_4            = lvl4
      i_level_4_start      = lvl2st "only use one single timeframe
      i_level_4_end        = lvl2ed "only use one single timeframe
*Analyze users with sap_all in detail
      i_analyze_sap_all    = 'X'
      i_nonabap            = p_nabap
      i_abap               = p_abap
    IMPORTING
      e_usercount          = tusercount
      ef_missing_auth      = gf_missing_auth
    TABLES
      it_users             = lt_bname
      it_usertype          = usrtype
      it_confs             = lt_confs
      et_outputdet         = lt_output
      it_user_rfc          = lt_rfcdest "xusrrfc
      it_simu_role_rfc     = gt_simuagrs
*     et_enh_con           = gt_enh_con
      it_orglvl            = orglvl
      it_risk              = s_risk
      it_department        = s_depart
      it_company           = s_comp
      it_central_uid       = s_cuid
      it_costcenter        = s_kostl
      et_mitigations       = gt_mcuser
      et_rfcdes            = gt_rfcdes
      et_return            = lt_return
*--Role Removal Simulation
      it_simu_role_removal = lt_role_removal_simu
*     et_simu_removed_roles    = gt_removed_roles
      et_level3_details    = lt_details
*--EN Integration
      it_appl              = s_appl
      it_sysid             = s_system.
*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
*      lt_return-type = 'W'.
    ENDIF.
*    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
*    WITH lt_return-message.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_INFO_BAPIRET'
    TABLES
      it_bapiret2       = lt_return.

  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
    LEAVE LIST-PROCESSING.
  ENDIF.

*--Output the details
  DATA : lt_display TYPE TABLE OF /psyng/sw_level3_display
  WITH HEADER LINE.
  CALL FUNCTION '/PSYNG/SW_104'
    TABLES
      et_details = lt_display
      it_details = lt_details
      it_rfc     = gt_rfcdes.
  SORT lt_display.
  DELETE ADJACENT DUPLICATES FROM lt_display.
*--Match this to conflicts
  DATA : lt_confdet     TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         lt_display_con TYPE TABLE OF /psyng/sw_level3_display
         WITH HEADER LINE.
  SELECT * FROM /psyng/confdet INTO TABLE lt_confdet WHERE vrsio =
  sodvrsio AND conid IN lt_confs.
  LOOP AT lt_output.
    LOOP AT lt_confdet WHERE conid = lt_output-conid.
      LOOP AT lt_display WHERE bname = lt_output-bname AND
                               funid = lt_confdet-functionid.
        lt_display_con = lt_display.
        lt_display_con-conid = lt_output-conid.
        APPEND lt_display_con.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
  PERFORM level3_alv_output TABLES lt_display_con.
ENDFORM.                    " level3_details
*---------------------------------------------------------------------*
*       FORM level3_alv_output                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DISPLAY                                                    *
*---------------------------------------------------------------------*
FORM level3_alv_output TABLES   it_display STRUCTURE
/psyng/sw_level3_display.

  DATA: isort           TYPE STANDARD TABLE OF slis_sortinfo_alv,
        l_sort          TYPE slis_sortinfo_alv,
        alv_grid_titl   TYPE lvc_title,
        alv_layout      TYPE slis_layout_alv,
        ls_variant      TYPE disvariant,
        program         LIKE sy-repid,
        begindate_c(10),
        enddate_c(10),
        lt_fieldcat_alv TYPE slis_t_fieldcat_alv.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'IT_DISPLAY'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname = 'IT_DISPLAY'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
*  add 1 to l_sort-spos.
*  l_sort-fieldname = 'CONTEXT'.
*  l_sort-tabname = 'IT_DISPLAY'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO isort.
*  add 1 to l_sort-spos.
*  l_sort-fieldname = 'RISK'.
*  l_sort-tabname = 'IT_DISPLAY'.
*  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNID'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DATE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TIME'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TYPE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TABLE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'LOGKEY'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CHANGE_TYPE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELDNAME'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELDTEXT'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VALUE'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'NEWVAL'.
  l_sort-tabname = 'IT_DISPLAY'.
  APPEND l_sort TO isort.


*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*       EXPORTING
*            i_program_name     = program
*            i_internal_tabname = 'IT_DISPLAY'
*            i_inclname         = program
*       CHANGING
*            ct_fieldcat        = i_fieldcat_alv.

  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26) sodvrsio
                                        INTO sy-title SEPARATED BY space
                                        .

  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26)
*               lvl2st
*               'To'(a21)
*               lvl2ed
               sodvrsio
              INTO alv_grid_titl SEPARATED BY space.

  PERFORM level3_fieldcatalog TABLES lt_fieldcat_alv .
  PERFORM level3_add_texts TABLES it_display.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title           = alv_grid_titl
      i_callback_top_of_page = 'LEVEL3_ALV_HEADER'
*     i_callback_user_command = 'HOTSPOT_CLICK'
      i_callback_program     = program
      it_sort                = isort
      is_layout              = alv_layout
      it_fieldcat            = lt_fieldcat_alv
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = it_display.

  CLEAR sy-title.
  CONCATENATE text-193 text-093 sodvrsio
              INTO sy-title SEPARATED BY space.

ENDFORM.                    " level3_alv_output
*---------------------------------------------------------------------*
*       FORM level3_add_texts                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_DISPLAY                                                    *
*---------------------------------------------------------------------*
FORM level3_add_texts
  TABLES it_display STRUCTURE /psyng/sw_level3_display.

  DATA lt_tstct TYPE HASHED TABLE OF tstct
       WITH UNIQUE KEY tcode
  WITH HEADER LINE.
  DATA lt_function TYPE HASHED TABLE OF /psyng/function
       WITH UNIQUE KEY function
  WITH HEADER LINE.

  LOOP AT it_display.
    lt_tstct-tcode = it_display-tcode.
    INSERT lt_tstct INTO TABLE lt_tstct.

    lt_function-function = it_display-funid.
    INSERT lt_function INTO TABLE lt_function.
  ENDLOOP.

  LOOP AT lt_tstct.
    SELECT ttext INTO lt_tstct-ttext FROM tstct
           WHERE sprsl = sy-langu AND  tcode = lt_tstct-tcode.
      MODIFY lt_tstct FROM lt_tstct
             TRANSPORTING ttext
             WHERE tcode = lt_tstct-tcode.
    ENDSELECT.
  ENDLOOP.

  LOOP AT lt_function.
    SELECT description INTO lt_function-description FROM /psyng/function
              WHERE function = lt_function-function AND vrsio = sodvrsio
              .
      MODIFY lt_function FROM lt_function
             TRANSPORTING description
             WHERE function = lt_function-function.
    ENDSELECT.
  ENDLOOP.

  LOOP AT it_display.
    READ TABLE lt_tstct WITH TABLE KEY tcode = it_display-tcode.
    IF sy-subrc = 0.
      it_display-ttext = lt_tstct-ttext.
    ENDIF.

    READ TABLE lt_function WITH TABLE KEY function =
 it_display-funid.
    IF sy-subrc = 0.
      it_display-funtext = lt_function-description.
    ENDIF.
    MODIFY it_display.
  ENDLOOP.

  CLEAR: it_display.

ENDFORM.



*---------------------------------------------------------------------*
*       FORM level3_fieldcatalog                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM level3_fieldcatalog
  TABLES it_fieldcat LIKE i_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

*  LOOP AT it_fieldcat INTO wa_fieldcat_alv.
*    wa_fieldcat_alv-seltext_l = wa_fieldcat_alv-seltext_m =
*                            wa_fieldcat_alv-seltext_s =
*                            wa_fieldcat_alv-reptext_ddic =
*                            wa_fieldcat_alv-fieldname.
*    MODIFY it_fieldcat FROM wa_fieldcat_alv
*                       TRANSPORTING seltext_l seltext_m seltext_s
*                                    reptext_ddic
*                       WHERE fieldname = wa_fieldcat_alv-fieldname.
*  ENDLOOP.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'User ID'(a05).
  wa_fieldcat_alv-seltext_m = 'User ID'(a05).
  wa_fieldcat_alv-seltext_s = 'User ID'(a05).
  wa_fieldcat_alv-reptext_ddic = 'User ID'(a05).
  wa_fieldcat_alv-fieldname    = 'BNAME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Conflict ID'(a06).
  wa_fieldcat_alv-seltext_m = 'Conflict ID'(a06).
  wa_fieldcat_alv-seltext_s = 'Conflict ID'(a06).
  wa_fieldcat_alv-reptext_ddic = 'Conflict ID'(a06).
  wa_fieldcat_alv-fieldname    = 'CONID'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Function ID'(a07).
  wa_fieldcat_alv-seltext_m = 'Function ID'(a07).
  wa_fieldcat_alv-seltext_s = 'Function ID'(a07).
  wa_fieldcat_alv-reptext_ddic = 'Function ID'(a07).
  wa_fieldcat_alv-fieldname    = 'FUNID'.
  APPEND wa_fieldcat_alv TO it_fieldcat.


  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Function Text'(a11).
  wa_fieldcat_alv-seltext_m = 'Function Text'(a11).
  wa_fieldcat_alv-seltext_s = 'Function Text'(a11).
  wa_fieldcat_alv-reptext_ddic = 'Function Text'(a11).
  wa_fieldcat_alv-fieldname    = 'FUNTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.



  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Transaction Code'(a01).
  wa_fieldcat_alv-seltext_m = 'Transaction Code'(a01).
  wa_fieldcat_alv-seltext_s = 'Tcode'(a02).
  wa_fieldcat_alv-reptext_ddic = 'Transaction Code'(a01).
  wa_fieldcat_alv-hotspot      = ' '.
  wa_fieldcat_alv-fieldname    = 'TCODE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.
  CLEAR:wa_fieldcat_alv.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Tcode Text'(a12).
  wa_fieldcat_alv-seltext_m = 'Tcode Text'(a12).
  wa_fieldcat_alv-seltext_s = 'Tcode Text'(a12).
  wa_fieldcat_alv-reptext_ddic = 'Tcode Text'(a12).
  wa_fieldcat_alv-fieldname    = 'TTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Change Type'(a14).
  wa_fieldcat_alv-seltext_m = 'Change Type'(a14).
  wa_fieldcat_alv-seltext_s = 'Change Type'(a14).
  wa_fieldcat_alv-reptext_ddic = 'Change Type'(a14).
  wa_fieldcat_alv-fieldname    = 'TYPE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.



  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Table'(a15).
  wa_fieldcat_alv-seltext_m = 'Table'(a15).
  wa_fieldcat_alv-seltext_s = 'Table'(a15).
  wa_fieldcat_alv-reptext_ddic = 'Table'(a15).
  wa_fieldcat_alv-fieldname    = 'TABLE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Field Name'(a08).
  wa_fieldcat_alv-seltext_m = 'Field Name'(a08).
  wa_fieldcat_alv-seltext_s = 'Field Name'(a08).
  wa_fieldcat_alv-reptext_ddic = 'Field Name'(a08).
  wa_fieldcat_alv-fieldname    = 'FIELDNAME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Field Text'(a09).
  wa_fieldcat_alv-seltext_m = 'Field Text'(a09).
  wa_fieldcat_alv-seltext_s = 'Field Text'(a09).
  wa_fieldcat_alv-reptext_ddic = 'Field Text'(a09).
  wa_fieldcat_alv-fieldname    = 'FIELDTEXT'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Log Key'(a13).
  wa_fieldcat_alv-seltext_m = 'Log Key'(a13).
  wa_fieldcat_alv-seltext_s = 'Log Key'(a13).
  wa_fieldcat_alv-reptext_ddic = 'Log Key'(a13).
  wa_fieldcat_alv-fieldname    = 'LOGKEY'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Date'(a17).
  wa_fieldcat_alv-seltext_m = 'Date'(a17).
  wa_fieldcat_alv-seltext_s = 'Date'(a17).
  wa_fieldcat_alv-reptext_ddic = 'Date'(a17).
  wa_fieldcat_alv-fieldname    = 'DATE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Time'(a16).
  wa_fieldcat_alv-seltext_m = 'Time'(a16).
  wa_fieldcat_alv-seltext_s = 'Time'(a16).
  wa_fieldcat_alv-reptext_ddic = 'Time'(a16).
  wa_fieldcat_alv-fieldname    = 'TIME'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'Change Type'(a10).
  wa_fieldcat_alv-seltext_m = 'Change Type'(a10).
  wa_fieldcat_alv-seltext_s = 'Change Type'(a10).
  wa_fieldcat_alv-reptext_ddic = 'Change Type'(a10).
  wa_fieldcat_alv-fieldname    = 'CHANGE_TYPE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  wa_fieldcat_alv-seltext_l = 'Old Value'(a03).
  wa_fieldcat_alv-seltext_m = 'Old Value'(a03).
  wa_fieldcat_alv-seltext_s = 'Old Value'(a03).
  wa_fieldcat_alv-reptext_ddic = 'Old Value'(a03).
  wa_fieldcat_alv-fieldname    = 'VALUE'.
  APPEND wa_fieldcat_alv TO it_fieldcat.

  CLEAR:wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = 'New Value'(a04).
  wa_fieldcat_alv-seltext_m = 'New Value'(a04).
  wa_fieldcat_alv-seltext_s = 'New Value'(a04).
  wa_fieldcat_alv-reptext_ddic = 'New Value'(a04).
  wa_fieldcat_alv-fieldname    = 'NEWVAL'.
  APPEND wa_fieldcat_alv TO it_fieldcat.














* Adjust column positions
  CLEAR: wa_fieldcat_alv.
* wa_fieldcat_alv-col_pos = '01'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'BNAME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'CONID'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FUNID'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FUNTEXT'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'DATE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TIME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TCODE'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TTEXT'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'TABLE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'LOGKEY'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'CHANGE_TYPE'.

  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FIELDNAME'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'FIELDTEXT'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'VALUE'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos WHERE fieldname = 'NEWVAL'.
  ADD 1 TO wa_fieldcat_alv-col_pos.
  MODIFY it_fieldcat FROM wa_fieldcat_alv
    TRANSPORTING col_pos
    WHERE fieldname = 'TYPE'.                    "#EC SAST_CI_GEN_CHECK

*  CLEAR: wa_fieldcat_alv.
*  wa_fieldcat_alv-outputlen = 10.
*  MODIFY it_fieldcat FROM wa_fieldcat_alv
*    TRANSPORTING outputlen WHERE fieldname = 'FIELDTEXT'.



ENDFORM.

*---------------------------------------------------------------------*
*       FORM level3_alv_header                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM level3_alv_header.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_count          TYPE i,
        c_count          TYPE string,
        l_alv_grid_titl2 TYPE lvc_title,
        l_date(12)       TYPE c.
  .
  wa-typ = 'H'.
  CONCATENATE 'SOD Analysis based on User Changes SOD Ver'(a26)
*               lvl2st
*               'To'(a21)
*               lvl2ed
               sodvrsio
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(a21).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
**Date
*  wa-typ = 'S'.
*  wa-key = 'Date'(a22).
*  WRITE sy-datum TO l_date.
*  wa-info = l_date.
*  APPEND wa TO header.
*Start Date for changes
  wa-typ = 'S'.
  wa-key = 'From'(a23).
  wa-info = lvl2st.
  APPEND wa TO header.
*End Date for changes
  wa-typ = 'S'.
  wa-key = 'To'(a24).
  wa-info = lvl2ed.
  APPEND wa TO header.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  export_dates_2_memory
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM export_dates_2_memory.

  DATA: lf_key(60)     VALUE 'DATES_2B_USED_4_REMEDIATION_PROPOSAL',
        lf_rfc_key(60) VALUE 'RFCS_2B_USED_4_REMEDIATION_PROPOSAL',
        lf_mstdate     TYPE dats,
        lf_meddate     TYPE dats.

  IF lvl3 = 'X'.
    lf_mstdate = lvl3st .
    lf_meddate = lvl3ed .
  ELSEIF lvl2 = 'X'.
    lf_mstdate = lvl2st .
    lf_meddate = lvl2ed .
  ENDIF.

  EXPORT lf_mstdate lf_meddate TO MEMORY ID lf_key .
  EXPORT xusrrfc TO MEMORY ID lf_rfc_key.

ENDFORM.                    " export_dates_2_memory
*&---------------------------------------------------------------------*
*&      Form  level2_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1STOUTPUT  text
*----------------------------------------------------------------------*
FORM level2_details USING   1stoutput LIKE 1stoutput.
  DATA: lf_fmname    TYPE rs38l_fnam,
        l_1stmon(7)  TYPE c,
        l_lastmon(7) TYPE c,
        iseltab      TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

* check if TA 2.x is installed
  MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lf_fmname
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc <> 0 OR gf_use_ta_drilldown <> 'X'.
* TA 2.x is not installed

    CONCATENATE lvl2st+4(2) '/' lvl2st(4)  INTO l_1stmon .
    CONCATENATE lvl2ed+4(2) '/' lvl2ed(4) INTO l_lastmon.

    iseltab-selname = '1STMON'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = l_1stmon.
    APPEND iseltab.
    iseltab-selname = 'LASTMON'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = l_lastmon.
    APPEND iseltab.

    iseltab-selname = 'PBNAME'.    "user ID
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 1stoutput-bname.
    APPEND iseltab.

    iseltab-selname = 'S_CONID'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 1stoutput-conid.
    APPEND iseltab.

    iseltab-selname = 'SODVRSIO'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = sodvrsio.
    APPEND iseltab.

    iseltab-selname = 'P_LOCAL'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_local.
    APPEND iseltab.

    iseltab-selname = 'P_CROSS'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_cross.
    APPEND iseltab.


    iseltab-selname = 'P_REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_remote.
    APPEND iseltab.

    iseltab-selname = 'S_RFC'.
    iseltab-kind    = 'S'.
    LOOP AT xusrrfc.
      iseltab-selname = 'S_RFC'.
      MOVE-CORRESPONDING xusrrfc TO iseltab.
      APPEND iseltab.
    ENDLOOP.

    iseltab-selname = 'REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_remonl.
    APPEND iseltab.


    SUBMIT /psyng/sodreport_by_history
    WITH SELECTION-TABLE iseltab AND RETURN.
  ELSE.
* TA 2.x is Installed


    iseltab-selname = 'S_DATE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'BT'.
    IF lvl2st IS INITIAL AND NOT lvl3st IS INITIAL.
      iseltab-low     = lvl3st.
    ELSE.
      iseltab-low     = lvl2st.
    ENDIF.
    IF lvl2ed IS INITIAL AND NOT lvl3ed IS INITIAL.
      iseltab-high     = lvl3ed.
    ELSE.
      iseltab-high     = lvl2ed.
    ENDIF.
    APPEND iseltab.
    CLEAR iseltab-high.


    iseltab-selname = 'S_USERS'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 1stoutput-bname.
    APPEND iseltab.
* There's no conid field in the sod report in ta2
*    iseltab-selname = 'S_CONID'.
*    iseltab-kind    = 'S'.
*    iseltab-sign    = 'I'.
*    iseltab-option  = 'EQ'.
*    iseltab-low     = 1stoutput-conid.
*    APPEND iseltab.

    iseltab-selname = 'P_SODVRS'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = sodvrsio.
    APPEND iseltab.

    iseltab-selname = 'P_LOCAL'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_local.
    APPEND iseltab.

    iseltab-selname = 'P_CROSS'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_cross.
    APPEND iseltab.


    iseltab-selname = 'P_REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_remote.
    APPEND iseltab.

    iseltab-selname = 'S_RFC'.
    iseltab-kind    = 'S'.
    LOOP AT xusrrfc.
      iseltab-selname = 'S_RFC'.
      MOVE-CORRESPONDING xusrrfc TO iseltab.
      APPEND iseltab.
    ENDLOOP.

    iseltab-selname = 'REMOTE'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = p_remonl.
    APPEND iseltab.

    iseltab-selname = 'S_CONID'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 1stoutput-conid.
    APPEND iseltab.

*--If this level 2 conflict is also a level 3 conflict
*  Ask TA to show the changes
    IF 1stoutput-level3 = 'X'.
      iseltab-selname = 'CHANGES'.
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = 'X'.
      APPEND iseltab.
    ENDIF.

    SUBMIT /psyng/bc_usrhis_37
    WITH SELECTION-TABLE iseltab AND RETURN.

  ENDIF.

ENDFORM.                    " level2_details
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
*
**  exlckusr = 'X'.
*ENDFORM.                    " set_def_usrtype
*&---------------------------------------------------------------------*
*&      Form  f4_alv_variant
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_LAYO  text
*----------------------------------------------------------------------*
FORM f4_alv_variant CHANGING p_layo.
  DATA: ls_variant LIKE disvariant.
  DATA l_not_summary TYPE c.

*  CLEAR l_nof4.
  LOOP AT SCREEN.
    IF screen-name = 'P_LAYO'.
      IF screen-input = 0.
        l_not_summary = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF l_not_summary <> 'X'.
    ls_variant-report   = sy-repid.
  ELSE.
    ls_variant-report   = '/PSYNG/SODREPORT_ORG_USR'.
  ENDIF.
  ls_variant-username = g_current_user."sy-uname. C0700
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = ls_variant
      i_save     = 'A'
    IMPORTING
      es_variant = ls_variant
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc = 0." AND l_nof4 EQ space.
    p_layo = ls_variant-variant.
  ENDIF.

ENDFORM.                    " f4_alv_variant
*&---------------------------------------------------------------------*
*&      Form  alv_variant_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_X_VAREXIST  text
*----------------------------------------------------------------------*
FORM alv_variant_check CHANGING y_varexist TYPE c.

  CALL FUNCTION 'REUSE_ALV_VARIANT_EXISTENCE'
    EXPORTING
      i_save        = 'A'
    CHANGING
      cs_variant    = gs_variant
    EXCEPTIONS
      wrong_input   = 1
      not_found     = 2
      program_error = 3
      OTHERS        = 4.
  IF sy-subrc <> 0.
    CLEAR y_varexist.
  ELSE.
    y_varexist = 'X'.
  ENDIF.

ENDFORM.                    " alv_variant_check
*&---------------------------------------------------------------------*
*&      Form  alv_default_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_VARIANT  text
*      <--P_G_VAREXIST  text
*----------------------------------------------------------------------*
FORM alv_default_check CHANGING y_varexist TYPE c.

  CALL FUNCTION 'REUSE_ALV_VARIANT_DEFAULT_GET'
    EXPORTING
      i_save        = 'A'
    CHANGING
      cs_variant    = gs_variant
    EXCEPTIONS
      wrong_input   = 1
      not_found     = 2
      program_error = 3
      OTHERS        = 4.
  IF sy-subrc <> 0.
    CLEAR y_varexist.
  ELSE.
    y_varexist = 'X'.
  ENDIF.

ENDFORM.                    " alv_default_check
*&---------------------------------------------------------------------*
*&      Form  set_output_variant
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_output_variant.
*-- Set variant
  IF NOT p_layo IS INITIAL.
    gs_variant-report   = sy-repid.
    gs_variant-username = g_current_user."sy-uname. C0700
    gs_variant-variant  = p_layo.
  ENDIF.

*-- Validate List output variants
  IF NOT gs_variant IS INITIAL.
*-- check existence of named variant
    PERFORM alv_variant_check CHANGING g_varexist.
    IF g_varexist IS INITIAL.
      MESSAGE i000(msitem) WITH gs_variant-variant.
    ENDIF.
  ELSE.
*-- check existence of default variant
    PERFORM alv_default_check CHANGING g_varexist.
  ENDIF.

  IF g_varexist IS INITIAL.
    CLEAR gs_variant.
  ENDIF.

ENDFORM.                    " set_output_variant
*&---------------------------------------------------------------------*
*&      Form  f4_dalv_variant
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_P_DLAYO  text
*----------------------------------------------------------------------*
FORM f4_dalv_variant CHANGING p_dlayo.
  DATA: ls_variant LIKE disvariant.
  DATA l_nof4 TYPE c.

  CLEAR l_nof4.
  LOOP AT SCREEN.
    IF screen-name = 'P_DLAYO' OR screen-name = 'P_SLAYO' .
      IF screen-input = 0.
        l_nof4 = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.
  ls_variant-report   = '/PSYNG/SODREPORT_ORG_USR'.
  ls_variant-username = g_current_user."sy-uname. C0700
  CALL FUNCTION 'REUSE_ALV_VARIANT_F4'
    EXPORTING
      is_variant = ls_variant
      i_save     = 'A'
    IMPORTING
      es_variant = ls_variant
    EXCEPTIONS
      OTHERS     = 1.
  IF sy-subrc = 0 AND l_nof4 EQ space.
    p_dlayo = ls_variant-variant.
  ENDIF.

ENDFORM.                    " f4_dalv_variant
*&---------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  CLEAR g_alv_layout.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.
  PERFORM build_alv_catalog_user_grp_cmp.

  CLEAR : sy-ucomm, g_ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
      i_grid_title = g_alv_grid_titl
*     i_callback_program     = program
*     i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
*     it_sort      = isort
*     i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
      is_layout    = g_alv_layout
      it_fieldcat  = i_fieldcat_alv
      i_save       = 'A'
      is_variant   = gs_variant
    TABLES
      t_outtab     = lt_rpoug_auth_fail.


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

  g_program = sy-repid.
  REFRESH i_fieldcat_alv.

*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*       EXPORTING
*            i_program_name     = program
*            i_internal_tabname = 'LT_AUTH_FAIL'
*            i_inclname         = program
*       CHANGING
*            ct_fieldcat        = i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'BNAME'.


  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h27.
  wa_fieldcat_alv-seltext_m = text-h27.
  wa_fieldcat_alv-seltext_s = text-h27.
  wa_fieldcat_alv-reptext_ddic = text-h27.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                   WHERE
*                      fieldname = 'CLASS'.


  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h26.
  wa_fieldcat_alv-seltext_m = text-h26.
  wa_fieldcat_alv-seltext_s = text-h26.
  wa_fieldcat_alv-reptext_ddic = text-h26.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      seltext_l
*                      seltext_m
*                      seltext_s
*                      reptext_ddic
*                      no_out
*                   WHERE
*                      fieldname = 'COMPANY'.
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
        lt_data    LIKE TABLE OF ls_data,
        lth_return TYPE TABLE OF ddshretval,
        wah_return LIKE LINE OF lth_return.

  SELECT a~domvalue_l AS value b~ddtext AS dtext        "#EC CI_NOORDER
    INTO CORRESPONDING FIELDS OF TABLE lt_data
    FROM dd07l AS a INNER JOIN dd07t AS b
    ON a~domname = b~domname
    AND a~as4local = b~as4local
    AND a~valpos = b~valpos
    AND a~as4vers = b~as4vers
    WHERE a~domname = '/PSYNG/XUUSTYP'
  AND b~ddlanguage = sy-langu.                   "#EC SAST_CI_GEN_CHECK
  IF   lt_data[] IS INITIAL.
*--Fallback to English
    SELECT a~domvalue_l AS value b~ddtext AS dtext      "#EC CI_NOORDER
      INTO CORRESPONDING FIELDS OF TABLE lt_data
      FROM dd07l AS a INNER JOIN dd07t AS b
      ON a~domname = b~domname
      AND a~as4local = b~as4local
      AND a~valpos = b~valpos
      AND a~as4vers = b~as4vers
      WHERE a~domname = '/PSYNG/XUUSTYP'
    AND b~ddlanguage = 'EN'.                     "#EC SAST_CI_GEN_CHECK
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

*---------------------------------------------------------------------*
*       FORM f4_orglvl                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_ORGLVL                                                      *
*---------------------------------------------------------------------*
FORM f4_orglvl USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
  CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
    EXPORTING
      i_cfg_set = cfgset
    IMPORTING
      e_orglvl  = e_orglvl.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  show_mit_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1STOUTPUT  text
*----------------------------------------------------------------------*
FORM show_mit_details USING 1stoutput LIKE 1stoutput.
  DATA : l_showuser     TYPE flag,
         l_showgroup    TYPE flag,
         l_showrole     TYPE flag,
         lt_mcuser_show LIKE TABLE OF gt_mcuser WITH HEADER LINE.
  CLEAR : l_showuser,l_showgroup,l_showrole,lt_mcuser_show[].
  REFRESH lt_mcuser_show.
  SORT gt_mcuser BY userid conid type from_date contid org_abb.
  DELETE ADJACENT DUPLICATES FROM gt_mcuser COMPARING
  userid conid type from_date contid org_abb.

  IF orgchk ='X'. "HBHALLA
    LOOP AT gt_mcuser WHERE userid  = 1stoutput-bname
                      AND   conid   = 1stoutput-conid
                      AND   org_abb = 1stoutput-abb.

      MOVE-CORRESPONDING gt_mcuser TO lt_mcuser_show.
      APPEND lt_mcuser_show.

      CASE gt_mcuser-type.
        WHEN '1'.
          l_showuser = 'X'.
        WHEN '2'.
          l_showgroup = 'X'.
        WHEN '4'.
          l_showrole = 'X'.
      ENDCASE.
    ENDLOOP.
*BOC:HBHALLA
  ELSE.
    LOOP AT gt_mcuser WHERE userid  = 1stoutput-bname
                      AND   conid   = 1stoutput-conid.

      MOVE-CORRESPONDING gt_mcuser TO lt_mcuser_show.
      APPEND lt_mcuser_show.

      CASE gt_mcuser-type.
        WHEN '1'.
          l_showuser = 'X'.
        WHEN '2'.
          l_showgroup = 'X'.
        WHEN '4'.
          l_showrole = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDIF.
*EOC:HBHALLA

  CHECK sy-subrc = 0.
  CALL FUNCTION '/PSYNG/SW_076'
    EXPORTING
      if_display          = 'X'
      if_call_from_report = 'X'
      if_show_class       = l_showgroup
      if_show_role        = l_showrole
    TABLES
      it_mcuser           = lt_mcuser_show.


ENDFORM.                    " show_mit_details
*&---------------------------------------------------------------------*
*&      Form  vaildate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM vaildate_other_fields.
  DATA : l_vrsio         TYPE /psyng/sodvrsio,
         l_rfcdest       TYPE rfcdes-rfcdest,
         lt_roles        TYPE TABLE OF /psyng/bc_agr_name,
         ls_rfcdest      LIKE LINE OF lt_rfcdest,
         l_rfcdest_local TYPE rfcdes-rfcdest,
         lt_excluding    TYPE  slis_t_extab,
         ls_excluding    TYPE slis_extab,
         l_repid         LIKE sy-repid,
         lt_fcat         TYPE slis_t_fieldcat_alv,
         ls_fcat         LIKE LINE OF lt_fcat,
         l_exit.

  DATA : BEGIN OF lt_rfc_roles OCCURS 0,
           rfcdest      TYPE rfcdes-rfcdest,
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
*--If we use a local sod matrix, validate it exists
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
              it_agr_name         = ar_rol_1
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

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
              it_agr_name         = ar_rol_2
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
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
              it_agr_name         = ar_rol_3
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
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
              it_agr_name         = ar_rol_4
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
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
              it_agr_name         = rr_rol_1
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
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
              it_agr_name         = rr_rol_2
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
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
              it_agr_name         = rr_rol_3
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

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
              it_agr_name         = rr_rol_4
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

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
*       I_STRUCTURE_NAME = 'BAPIRET2'
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
*&      Form  get_users_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_count.
  DATA : l_numb      TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local    TYPE flag VALUE 'X',
         lt_usrrfc   TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                     WITH HEADER LINE.
  IF p_remonl = 'X'.
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

*--Om 30.02.2020
  lt_usrrfc[] = xusrrfc[].
*--if only users that exist on the local system are to be analyzed
*  don't pass the systems to count the users
  IF  p_locusr = 'X'.
    REFRESH lt_usrrfc.
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
      i_validuser       = validusr
      i_include_locked  = lv_exlckusr
      i_include_expired = lv_outvdate
      if_local_system   = lv_local
      if_show_message   = 'X'
      it_parameters     = gt_usrpar
    IMPORTING
      e_usercount       = l_numb
    TABLES
      it_userlist       = userlist
      it_grouplist      = pclass
      it_usertype       = usrtype
      it_actgroups      = s_role
      it_profile        = s_prof
      it_rfcrange       = lt_usrrfc
      it_department     = s_depart
      it_company        = s_comp
      it_cuid           = s_cuid
      it_costcenter     = s_kostl
      it_en_userlist    = gt_en_userlist."HBHALLA(PN-4774)


  REFRESH lt_usrrfc.
ENDFORM.                    " get_users_count
*&---------------------------------------------------------------------*
*&      Form  before_after_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM before_after_simulation TABLES   it_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu
                                      it_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu
                                      it_role_remove_simu_en STRUCTURE
                                         /psyng/en_role_removal_simu
                                      it_role_addition_simu_en STRUCTURE
                                        /psyng/ex_role_addition_simu.


  .
  DATA : gt_user_con_before TYPE TABLE OF /psyng/sw_sod_output_org
                              WITH HEADER LINE,
         gt_user_con_after  TYPE TABLE OF /psyng/sw_sod_output_org
                              WITH HEADER LINE.

  DATA : lf_dont_update_scan      TYPE flag,
         lf_dont_output_to_screen TYPE flag,
         lt_return                TYPE TABLE OF bapiret2 WITH HEADER
         LINE,
         lf_error                 TYPE flag,
         lt_role_removal_simu     TYPE TABLE OF
         /psyng/sw_role_removal_simu,
         lt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu.
  DATA : lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
         ls_output  TYPE /psyng/sw_sod_output_org.

  IF ustb IS INITIAL.
    lf_dont_update_scan = 'X'.
  ENDIF.
  IF odt IS INITIAL.
    lf_dont_output_to_screen = 'X'.
  ENDIF.
  lt_rfcdest[] = xusrrfc[].

  FREE : gt_removed_roles.

*-- Before analysis
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_org_check          = orgchk
      i_validuser          = validusr
      i_exlckusr           = exlckusr
      i_outvdate           = outvdate
      i_vrsio              = sodvrsio
      i_config_set         = cfgset
      i_cuscon             = cuscon
      i_function_details   = ' '
      i_shomit             = xmc
      i_enh                = p_enhanc
      i_hienh              = p_hienhn
      i_wp                 = wp
      i_xstb               = lf_dont_update_scan
      i_pserver            = pserver
      i_max_upp            = upp
      i_shonosod           = shonosod
      i_locsod             = p_locsod
      i_locusr             = p_locusr
      i_output             = odt
      i_remote_only        = p_remonl
      i_er_roles           = erroles
      i_exclude_er_roles   = excl_er
      i_analyze_sap_all    = 'X'
      i_level_2            = lvl2
      i_level_2_start      = lvl2st
      i_level_2_end        = lvl2ed
      i_level_3            = lvl3
      i_level_3_start      = lvl2st
      i_level_3_end        = lvl2ed
      i_level_3_changedocs = lvl3_cd
      i_level_3_tablog     = lvl3_tl
      i_level_4            = lvl4
      i_level_4_start      = lvl2st
      i_level_4_end        = lvl2ed
      i_matrix_rfc         = p_sodrfc
      i_nonabap            = p_nabap
      i_abap               = p_abap
      if_mit_by_org        = gf_mit_by_org
      it_usrpar             = gt_usrpar
      i_org_field           = g_org_field  "opl 645
    IMPORTING
      e_usercount          = tusercount
      ef_missing_auth      = gf_missing_auth
      ef_st_missing_auth   = gf_st_missing_auth
    TABLES
      it_users             = userlist
      it_usergroup         = pclass
      it_actgroups         = s_role
      it_profiles          = s_prof
      it_usertype          = usrtype
      it_confs             = gt_conid
      et_outputdet         = gt_user_con_before
      it_user_rfc          = lt_rfcdest "xusrrfc
      et_enh_con           = gt_enh_con
      it_orglvl            = orglvl
      it_risk              = s_risk
      it_department        = s_depart
      it_company           = s_comp
      it_central_uid       = s_cuid
      it_costcenter        = s_kostl
      et_mitigations       = gt_mcuser
      et_rfcdes            = gt_rfcdes
      et_return            = lt_return
      et_rpoug_auth_fail   = lt_rpoug_auth_fail
*--EN Integration
      it_appl              = s_appl
      it_sysid             = s_system
      it_en_users           = gt_en_userlist. "HBHALLA(PN-4774)
*      IT_SIMU_ROLE_REMOVAL_EN = it_role_remove_simu_en[]
*      IT_SIMU_ROLE_ADDITION_EN = IT_ROLE_ADDITION_SIMU_EN[].
*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
*      lt_return-type = 'W'.
    ENDIF.
*    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
*    WITH lt_return-message.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_INFO_BAPIRET'
    TABLES
      it_bapiret2       = lt_return.

  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
    LEAVE LIST-PROCESSING.
  ENDIF.


*-- After analysis
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_org_check           = orgchk
      i_validuser           = validusr
      i_exlckusr            = exlckusr
      i_outvdate            = outvdate
      i_vrsio               = sodvrsio
      i_config_set          = cfgset
      i_cuscon              = cuscon
      i_function_details    = ' '
      i_shomit              = xmc
      i_enh                 = p_enhanc
      i_hienh               = p_hienhn
      i_wp                  = wp
      i_xstb                = lf_dont_update_scan
      i_pserver             = pserver
      i_max_upp             = upp
      i_shonosod            = shonosod
      i_locsod              = p_locsod
      i_locusr              = p_locusr
      i_output              = odt
      i_remote_only         = p_remonl
      i_er_roles            = erroles
      i_exclude_er_roles    = excl_er
      i_analyze_sap_all     = 'X'
      i_level_2             = lvl2
      i_level_2_start       = lvl2st
      i_level_2_end         = lvl2ed
      i_level_3             = lvl3
      i_level_3_start       = lvl2st
      i_level_3_end         = lvl2ed
      i_level_3_changedocs  = lvl3_cd
      i_level_3_tablog      = lvl3_tl
      i_level_4             = lvl4
      i_level_4_start       = lvl2st
      i_level_4_end         = lvl2ed
      i_matrix_rfc          = p_sodrfc
      i_nonabap             = p_nabap
      i_abap                = p_abap
      if_mit_by_org         = gf_mit_by_org
      it_usrpar             = gt_usrpar
      i_org_field           = g_org_field  "opl 645
    IMPORTING
      e_usercount           = tusercount
      ef_missing_auth       = gf_missing_auth
      ef_st_missing_auth    = gf_st_missing_auth
    TABLES
      it_users              = userlist
      it_usergroup          = pclass
      it_actgroups          = s_role
      it_profiles           = s_prof
      it_usertype           = usrtype
      it_confs              = gt_conid
      et_outputdet          = gt_user_con_after
      it_user_rfc           = lt_rfcdest "xusrrfc
      et_enh_con            = gt_enh_con
      it_orglvl             = orglvl
      it_risk               = s_risk
      it_department         = s_depart
      it_company            = s_comp
      it_central_uid        = s_cuid
      it_costcenter         = s_kostl
      et_mitigations        = gt_mcuser
      et_rfcdes             = gt_rfcdes
      et_return             = lt_return
*--Role Removal Simulation
      it_simu_role_removal  = it_role_removal_simu
      et_simu_removed_roles = gt_removed_roles
*--Role Addition Simulation
      it_simu_role_addition = it_role_addition_simu
      et_rpoug_auth_fail    = lt_rpoug_auth_fail
*--EN Integration
      it_appl               = s_appl
      it_sysid              = s_system
      it_simu_role_removal_en = it_role_remove_simu_en
      it_simu_role_addition_en  = it_role_addition_simu_en
      it_en_users           = gt_en_userlist. "HBHALLA(PN-4774)
*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
*      lt_return-type = 'W'.
    ENDIF.
*    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '140'
*    WITH lt_return-message.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_INFO_BAPIRET'
  TABLES
    it_bapiret2       = lt_return.

  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
    LEAVE LIST-PROCESSING.
  ENDIF.

*--odubey 27/01/2022 duplicate row with simulation when
*--mit_by_org = N
*--org_abb should be initial as we are not showing in sum mode
  IF gf_mit_by_org IS INITIAL.
    gt_user_con_after-org_abb = ' '.
    MODIFY gt_user_con_after  TRANSPORTING org_abb
    WHERE org_abb IS NOT INITIAL.

    gt_user_con_before-org_abb = ' '.
    MODIFY gt_user_con_before TRANSPORTING org_abb
    WHERE org_abb IS NOT INITIAL.
  ENDIF.

*-- Process output.
  SORT  gt_user_con_after  BY bname conid.
  SORT  gt_user_con_before BY bname conid.
*  Delete gt_user_con_after where simu <> 'X'.
  REFRESH : gt_output.

  LOOP AT gt_user_con_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_user_con_after TO ls_output.
    READ TABLE gt_user_con_before
    WITH KEY conid    = gt_user_con_after-conid
             bname    = gt_user_con_after-bname
             org_abb  = gt_user_con_after-org_abb.
*    BINARY SEARCH TRANSPORTING NO FIELDS.
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

  LOOP AT gt_user_con_before.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_user_con_before TO ls_output.
    READ TABLE gt_user_con_after
    WITH KEY conid   = gt_user_con_before-conid
             bname   = gt_user_con_before-bname
             org_abb = gt_user_con_before-org_abb.
*    BINARY SEARCH TRANSPORTING NO FIELDS.
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


*--Handle output
*---SODLive
  IF hidestd = 'X'.
    DELETE gt_output WHERE level2 IS INITIAL.
  ENDIF.

*--Filter Conflict origin
* BOC for B16606 for C0733
*  IF p_local <> 'X'.
*    DELETE gt_output WHERE origin = 1.
*  ENDIF.
*  IF p_remote <> 'X'.
*    DELETE gt_output WHERE origin = 2.
*  ENDIF.
*  IF p_cross <> 'X'.
*    DELETE gt_output WHERE origin = 3.
*
*  ENDIF.
  IF p_local = 'X' AND p_remote IS INITIAL
         AND p_cross IS INITIAL.
    DELETE gt_output WHERE origin = 2
                        OR origin = 3
                        OR origin = 5.
  ELSEIF p_local = 'X' AND p_remote = 'X'
    AND p_cross IS INITIAL.
    DELETE gt_output WHERE origin = 3.
  ELSEIF p_local = 'X' AND p_remote IS INITIAL
    AND p_cross = 'X'.
    DELETE gt_output WHERE origin = 2.
  ELSEIF p_local IS INITIAL AND p_remote = 'X'
    AND p_cross IS INITIAL.
    DELETE gt_output WHERE origin = 1
                        OR origin = 3
                        OR origin = 4.
  ELSEIF p_local IS INITIAL AND p_remote = 'X'
    AND p_cross = 'X'.
    DELETE gt_output WHERE origin = 1.
  ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
    AND p_cross = 'X'.
    DELETE gt_output WHERE origin = 1
                        OR origin = 2.
  ENDIF.
* EOC for B16606 for C0733
  PERFORM get_mc_header_data.

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
ENDFORM.                    " before_after_simulation
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_REMRFC  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
      it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest,
        lt_rfc_log       TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test       TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc
    AND rfctype = '3'.
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
*       lt_rfc_log-rfclog.
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
      DELETE et_rfcdes.
      CONTINUE.


*      CASE sy-subrc.
**        WHEN 1 OR 2.
**          MESSAGE e398(00) WITH
**          text-e01
**          l_rfcdest
**          l_system_msg.
*          CONTINUE.
**          *        WHEN 3.
**          MESSAGE e398(00) WITH
**          text-e01
**          l_rfcdest.
*          CONTINUE.
*      ENDCASE.
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


ENDFORM.                    " load_role_rfc
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
         r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
         LINE.


  APPEND LINES OF xusrrfc TO r_rfcs.
  r_rfcs-sign   = 'I'.
  r_rfcs-option = 'EQ'.
*--Role Simulation Destinations
  IF bysimu = 'X'.
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
  ENDIF.
*--Role Removal  Simulation Destinations
  IF byrsimu = 'X'.
    r_rfcs-low    = rr_rfc_1.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_2.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_3.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_4.
    APPEND r_rfcs.

  ENDIF.

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
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SOD  text
*      -->P_L_UNAME  text
*      i_delete  : if this has a value <> 0,
*          delete the /PSYNG/VRSIO parameter

*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  i_delete TYPE sy-subrc.
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
  IF i_delete <> 0.
    DELETE lt_param WHERE parid = '/PSYNG/VRSIO'.
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

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  level4_details
*&---------------------------------------------------------------------*
*       Show User Summary in AM Risk Exposure Report
*----------------------------------------------------------------------*
*      -->P_1STOUTPUT  text
*----------------------------------------------------------------------*
FORM level4_details USING    i_1stoutput LIKE 1stoutput.
  DATA: iseltab         TYPE STANDARD TABLE OF  rsparams WITH HEADER
  LINE,
        lf_am_installed TYPE flag,
        l_am_vrsio      TYPE /psyng/prog_vrsio.
  CHECK i_1stoutput-level4 = 'X'.

*--Check if AM is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'AM'
    IMPORTING
      e_installed      = lf_am_installed
      e_module_version = l_am_vrsio.

  IF lf_am_installed  = 'X' AND l_am_vrsio > '1.0'.
    iseltab-selname = 'P_USRSUM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.

    iseltab-selname = 'S_BNAME'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_1stoutput-bname.
    APPEND iseltab.

    iseltab-selname = 'S_CONID'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = i_1stoutput-conid.
    APPEND iseltab.

    iseltab-selname = 'S_DATE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'BT'.
    iseltab-low     = lvl2st.
    iseltab-high    = lvl2ed.
    APPEND iseltab.

    SUBMIT /psyng/seam_018
    WITH SELECTION-TABLE iseltab AND RETURN.
  ELSE.
    MESSAGE s002(/psyng/sw) WITH 'Level 4 Analysis not executed'
                      'AM Not Installed or version to low'.
  ENDIF.
ENDFORM.                    " level4_details
*&---------------------------------------------------------------------*
*&      Form  SHOW_SEL_SCR_INFO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_sel_scr_info .

  TYPES: BEGIN OF ty_selscrpar,
    selname	TYPE rsscr_name,
*    desc TYPE textpooltx,
    kind  TYPE  rsscr_kind,
    sign  TYPE  tvarv_sign,
    option  TYPE  tvarv_opti,
    low(45) TYPE  c,
    high(45)  TYPE  c,
    END OF ty_selscrpar.

  DATA: lv_report TYPE rs38m-programm
                           VALUE '/PSYNG/SODREPORT_SYS_WIDE_ORG',
        lt_field_des TYPE TABLE OF textpool,
        ls_field_des TYPE textpool,
        lt_selscrpar TYPE TABLE OF ty_selscrpar,
        ls_selscrpar TYPE ty_selscrpar,
        lv_string TYPE string.

  FIELD-SYMBOLS: <fs_selscrpar> TYPE rsparams,
                 <fs_selscrpar1> LIKE LINE OF lt_selscrpar.

  "Get selection screen info
  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
    EXPORTING
      curr_report               = g_program
    TABLES
      selection_table           = gt_selscrpar.
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ELSE.
* Deleting unfilled fields
    LOOP AT gt_selscrpar ASSIGNING <fs_selscrpar>.
      IF <fs_selscrpar>-low IS INITIAL AND
         <fs_selscrpar>-high IS INITIAL.
        <fs_selscrpar>-kind = 'Z'.
      ENDIF.
    ENDLOOP.
    DELETE gt_selscrpar WHERE kind = 'Z'.
  ENDIF.

*  LOOP AT gt_selscrpar ASSIGNING <fs_selscrpar>.
*    MOVE-CORRESPONDING <fs_selscrpar> TO ls_selscrpar.
*    APPEND ls_selscrpar TO lt_selscrpar.
*  ENDLOOP.
*
**  Description of selection screen fields
*  CALL FUNCTION 'RS_TEXTPOOL_READ'
*    EXPORTING
*      objectname                 = lv_report
*    TABLES
*      tpool                      = lt_field_des.
*  IF sy-subrc <> 0.
** Implement suitable error handling here
*  ENDIF.
*
*  LOOP AT lt_selscrpar ASSIGNING <fs_selscrpar1>.
*    READ TABLE lt_field_des INTO ls_field_des
*                                 WITH KEY key =
*<fs_selscrpar1>-selname.
*    IF sy-subrc = 0.
*      lv_string = ls_field_des-entry.
*      CONDENSE lv_string.
*      <fs_selscrpar1>-desc = lv_string.
*    ELSE.
*    ENDIF.
*  ENDLOOP.


  "Set layout
  CLEAR g_alv_layout.
  g_alv_layout-zebra = 'X'.
  g_alv_layout-colwidth_optimize = 'X'.

  PERFORM build_alv_catalog_sel_scr_info.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_top_of_page = 'SELSCR_INFO_HEADER'
    i_callback_program     = g_program
    is_layout    = g_alv_layout
    it_fieldcat  = i_fieldcat_alv
  TABLES
    t_outtab     = gt_selscrpar.

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

  FIELD-SYMBOLS <fs_fieldcat> TYPE slis_fieldcat_alv.
  FREE : i_fieldcat_alv.

*  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
*
*  CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'SELNAME'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*
*    CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'KIND'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*
*    CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'SIGN'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*
*    CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'OPTION'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*
*    CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'LOW'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*
*    CLEAR:wa_fieldcat_alv.
*  wa_fieldcat_alv-seltext_l = 'User ID'.
*  wa_fieldcat_alv-seltext_m = 'User ID'.
*  wa_fieldcat_alv-seltext_s = 'User ID'.
*  wa_fieldcat_alv-fieldname    = 'HIGH'.
*  APPEND wa_fieldcat_alv TO i_fieldcat_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
  EXPORTING
    i_program_name     = g_program
    i_structure_name = 'RSPARAMS'
    i_inclname         = g_program
  CHANGING
    ct_fieldcat        = i_fieldcat_alv.

  LOOP AT i_fieldcat_alv ASSIGNING <fs_fieldcat>.
    IF <fs_fieldcat>-fieldname = 'LOW'.
      <fs_fieldcat>-seltext_l = 'Low value'.
      <fs_fieldcat>-seltext_m = 'Low value'.
      <fs_fieldcat>-reptext_ddic = 'Low value'.
    ELSEIF <fs_fieldcat>-fieldname = 'HIGH'.
      <fs_fieldcat>-seltext_l = 'High value'.
      <fs_fieldcat>-seltext_m = 'High value'.
      <fs_fieldcat>-reptext_ddic = 'Low value'.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  level3_detail_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LSTOUTPUT  text
*----------------------------------------------------------------------*
FORM level3_detail_back_job  USING 1stoutput1 TYPE tt_1stoutput.

  DATA:lv_bgd_report LIKE rsvar-report,
      lv_jobname TYPE btcjob,
      lv_variant LIKE vari-variant,
      lv_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      lt_irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE,
      lv_vari_text LIKE varit OCCURS 0 WITH HEADER LINE,
      lt_confs TYPE TABLE OF /psyng/sw_sel_opts_conid
                 WITH HEADER LINE,
      ls_output TYPE ty_1stoutput.

  lv_bgd_report = '/PSYNG/SW_161'.
  lv_jobname = 'SOD LIVE LEVEL3 CHANGES DETAIL'(219).

  CLEAR: lv_variant,lv_vari_desc.
  REFRESH: lv_vari_desc.
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
     EXPORTING
       i_report        = lv_bgd_report
    IMPORTING
       e_variant       = lv_variant.

  lv_vari_desc-report = lv_bgd_report.
  lv_vari_desc-variant = lv_variant.
  APPEND lv_vari_desc.

*--Input data for background job
  REFRESH : lt_irsparams[].
  lt_irsparams-selname = 'P_CROSS'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_cross.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_REMOTE'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_remote.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'VALIDUSR'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = validusr.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'EXLCKUSR'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = exlckusr.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'OUTVDATE'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = outvdate.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'SODVRSIO'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = sodvrsio.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'XMC'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = xmc.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_ENHANC'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_enhanc .
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_HIENHN'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_hienhn.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'WP'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = wp.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'PSERVER'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = pserver.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'UPP'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = upp.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'SHONOSOD'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = shonosod.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_LOCSOD'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_locsod.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_LOCUSR'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_locusr.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'ODT'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = odt.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_REMONL'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_remonl.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'ERROLES'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = erroles.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL2'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl2.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL2ST'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl2st.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL2ED'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl2ed.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL3'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl3.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL3_CD'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl3_cd.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL3_TL'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl3_tl.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'LVL4'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = lvl4.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_NABAP'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_nabap.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'P_ABAP'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = p_abap.
  APPEND lt_irsparams.

  lt_irsparams-selname = 'ORGCHK'.
  lt_irsparams-kind    = 'P'.
  lt_irsparams-sign    = 'I'.
  lt_irsparams-option  = 'EQ'.
  lt_irsparams-low     = orgchk.
  APPEND lt_irsparams.

  LOOP AT xusrrfc .
    lt_irsparams-selname = 'XUSRRFC'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = xusrrfc-sign.
    lt_irsparams-option  = xusrrfc-option.
    lt_irsparams-low     = xusrrfc-low.
    lt_irsparams-high    = xusrrfc-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT usrtype .
    lt_irsparams-selname = 'USRTYPE'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = usrtype-sign.
    lt_irsparams-option  = usrtype-option.
    lt_irsparams-low     = usrtype-low.
    lt_irsparams-high    = usrtype-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_appl.
    lt_irsparams-selname = 'S_APPL'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_appl-sign.
    lt_irsparams-option  = s_appl-option.
    lt_irsparams-low     = s_appl-low.
    lt_irsparams-high    = s_appl-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_system.
    lt_irsparams-selname = 'S_SYSTEM'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_system-sign.
    lt_irsparams-option  = s_system-option.
    lt_irsparams-low     = s_system-low.
    lt_irsparams-high    = s_system-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT ar_rol_2 .
    lt_irsparams-selname = 'AR_ROL_2'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = ar_rol_2-sign.
    lt_irsparams-option  = ar_rol_2-option.
    lt_irsparams-low     = ar_rol_2-low.
    lt_irsparams-high    = ar_rol_2-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_risk.
    lt_irsparams-selname = 'S_RISK'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_risk-sign.
    lt_irsparams-option  = s_risk-option.
    lt_irsparams-low     = s_risk-low.
    lt_irsparams-high    = s_risk-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_depart.
    lt_irsparams-selname = 'S_DEPART'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_depart-sign.
    lt_irsparams-option  = s_depart-option.
    lt_irsparams-low     = s_depart-low.
    lt_irsparams-high    = s_depart-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_comp.
    lt_irsparams-selname = 'S_COMP'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_comp-sign.
    lt_irsparams-option  = s_comp-option.
    lt_irsparams-low     = s_comp-low.
    lt_irsparams-high    = s_comp-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_cuid.
    lt_irsparams-selname = 'S_CUID'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_cuid-sign.
    lt_irsparams-option  = s_cuid-option.
    lt_irsparams-low     = s_cuid-low.
    lt_irsparams-high    = s_cuid-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT s_kostl.
    lt_irsparams-selname = 'S_KOSTL'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = s_kostl-sign.
    lt_irsparams-option  = s_kostl-option.
    lt_irsparams-low     = s_kostl-low.
    lt_irsparams-high    = s_kostl-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT orglvl.
    lt_irsparams-selname = 'ORGLVL'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = orglvl-sign.
    lt_irsparams-option  = orglvl-option.
    lt_irsparams-low     = orglvl-low.
    lt_irsparams-high    = orglvl-high.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT 1stoutput1 INTO ls_output.
    lt_irsparams-selname = 'S_CONF'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = 'I'.
    lt_irsparams-option  = 'EQ'.
    lt_irsparams-low     = ls_output-conid.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT 1stoutput1 INTO ls_output.
    lt_irsparams-selname = 'S_BNAME'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = 'I'.
    lt_irsparams-option  = 'EQ'.
    lt_irsparams-low     = ls_output-bname.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT gt_simuagrs.
    lt_irsparams-selname = 'S_RFCDES'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = 'I'.
    lt_irsparams-option  = 'EQ'.
    lt_irsparams-low     = gt_simuagrs-rfcdest.
    APPEND lt_irsparams.

    lt_irsparams-selname = 'S_AGR'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = 'I'.
    lt_irsparams-option  = 'EQ'.
    lt_irsparams-low     = gt_simuagrs-agr_name.
    APPEND lt_irsparams.
  ENDLOOP.

  LOOP AT gt_role_removal_simu.
    lt_irsparams-selname = 'S_SAGR'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = gt_role_removal_simu-sign.
    lt_irsparams-option  = gt_role_removal_simu-option.
    lt_irsparams-low     = gt_role_removal_simu-low.
    lt_irsparams-high     = gt_role_removal_simu-high.
    APPEND lt_irsparams.

    lt_irsparams-selname = 'S_SRFC'.
    lt_irsparams-kind    = 'S'.
    lt_irsparams-sign    = 'I'.
    lt_irsparams-option  = 'EQ'.
    lt_irsparams-low     = gt_role_removal_simu-rfcdest.
    APPEND lt_irsparams.
  ENDLOOP.

  CALL FUNCTION 'RS_CREATE_VARIANT'
     EXPORTING
       curr_report   = lv_bgd_report
       curr_variant  = lv_variant
       vari_desc     = lv_vari_desc
     TABLES
       vari_contents = lt_irsparams
       vari_text     = lv_vari_text.

  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
    EXPORTING
      in_jobname  = lv_jobname
      in_repvarnt = lv_variant
      in_report   = lv_bgd_report.
  IF sy-subrc <> 0.
*    CALL SCREEN 1000.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_2001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2001 OUTPUT.
  SET PF-STATUS 'PF_2001'.
*  SET TITLEBAR 'xxx'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2001 INPUT.

  CASE sy-ucomm.
    WHEN 'FOREGROUND'.
      PERFORM level3_details USING 1stoutput.
    WHEN 'BACKGROUND'.
      APPEND 1stoutput TO 1stoutput1.
      PERFORM level3_detail_back_job USING 1stoutput1.
    WHEN 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_2002  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2002 OUTPUT.
  SET PF-STATUS 'PF_2002'.
*  SET TITLEBAR 'xxx'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2002  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_2002 INPUT.
  CASE sy-ucomm.
    WHEN 'START'.
      PERFORM level3_detail_back_job USING 1stoutput1.
    WHEN 'CANCEL'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.

FORM selscr_info_header.
  DATA: header           TYPE slis_t_listheader,
        wa               TYPE slis_listheader,
        l_exedate        TYPE char10,
        l_exetime(8)     TYPE c,
        l_systemid       TYPE /psyng/sysid.

*--Header
  wa-typ = text-072.
  wa-info = text-h48.
  APPEND wa TO header.

*--User Date & System
  WRITE sy-datum TO l_exedate.
  wa-typ = 'S'.
  wa-key = text-h10.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user"sy-uname C0700
   text-h11 l_exedate l_exetime text-h47 l_systemid
              INTO wa-info SEPARATED BY space.


  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  REVERSE_MAPPING_NONABAP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reverse_mapping_nonabap.

  CONSTANTS: c_func_ex_get_users(30) TYPE c
  VALUE '/PSYNG/EX_GET_USERS'.
  DATA: lt_sel_users TYPE TABLE OF
        /psyng/range_ex_bname WITH HEADER LINE,
        lt_uinfo_en  TYPE TABLE OF
        /psyng/ex_usrhdr_st WITH HEADER LINE.
  IF p_nabap EQ 'X'
*  AND p_locusr IS INITIAL "Commented HBHALLA (PN-140301) (Only local)
*  AND p_remonl IS INITIAL "Commented HBHALLA (PN-140301) (Issue3)
     AND userlist[] IS NOT INITIAL.

*--pass nonabap users
    LOOP AT userlist.
      lt_sel_users-sign = userlist-sign.
      lt_sel_users-option = userlist-option.
      lt_sel_users-high = userlist-high.
      lt_sel_users-low = userlist-low.
      APPEND lt_sel_users.
    ENDLOOP.

    CALL FUNCTION c_func_ex_get_users        "#EC PATHLOCK_CI_DYN_ACCES
       TABLES
            it_appl  = s_appl
            it_sysid = s_system
            it_class = pclass
            it_bname = lt_sel_users
            et_users = lt_uinfo_en.

    LOOP AT lt_uinfo_en.
      READ TABLE userlist WITH KEY sign = 'I'
                                   option = 'EQ'
                                   low = lt_uinfo_en-bname.
      IF sy-subrc EQ 0.
        IF lt_uinfo_en-basename IS NOT INITIAL.
          userlist-low    = lt_uinfo_en-basename.
          MODIFY userlist FROM userlist INDEX sy-tabix
          TRANSPORTING low.
        ENDIF.
      ELSE.
        IF lt_uinfo_en-basename IS NOT INITIAL.
          userlist-sign   = 'I'.
          userlist-option = 'EQ'.
          userlist-low    = lt_uinfo_en-basename.
*          COLLECT userlist.
          APPEND userlist TO gt_en_userlist. "HBHALLA(PN-4774)
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " REVERSE_MAPPING_NONABAP
*&---------------------------------------------------------------------*
*&      Form  F4_USRPAR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM f4_usrpar USING fieldname
               CHANGING s_usrpar.

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
*&---------------------------------------------------------------------*
*&      Form  USERLIST_VALUE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM userlist_value_low.

  TYPES: BEGIN OF ty_user_addr,
        bname TYPE xubname,
        name_first  TYPE  ad_namefir,
        name_last TYPE  ad_namelas,
        department  TYPE  ad_dprtmnt,
        kostl TYPE  xukostl,
        building  TYPE  ad_bldng_p,
        roomnumber  TYPE  ad_roomnum,
        city1 TYPE  ad_city1,
        post_code1 TYPE  ad_pstcd1,
      END OF ty_user_addr.

  DATA: lt_user_addr TYPE STANDARD TABLE OF ty_user_addr,
        ls_user_addr LIKE LINE OF lt_user_addr.

  DATA: lt_dynpfields TYPE STANDARD TABLE OF dynpread,
        ls_dynpfield  TYPE dynpread,
        lv_user_input_low TYPE xubname,
        lv_user_input_high TYPE xubname.

  CLEAR ls_dynpfield.
  CLEAR lt_dynpfields[].
  ls_dynpfield-fieldname = 'USERLIST-LOW'.
  APPEND ls_dynpfield TO lt_dynpfields.

  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = sy-cprog
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynpfields
    EXCEPTIONS
*BOC UMITTAL SE-ATC Fixes 25/02/2026 PN 16658
      invalid_abapworkarea  = 1
      invalid_dynprofield   = 2
      invalid_dynproname    = 3
      invalid_dynpronummer  = 4
      invalid_request       = 5
      no_fielddescription   = 6
      invalid_parameter     = 7
      undefind_error        = 8
      double_conversion     = 9
      stepl_not_found       = 10
      others                = 11.
  IF sy-subrc <> 0.
    MESSAGE s002 WITH 'Exception Occured'(067) .
  ENDIF.
*EOC UMITTAL SE-ATC Fixes 25/02/2026 PN 16658
  READ TABLE lt_dynpfields INTO ls_dynpfield
  WITH KEY fieldname = 'USERLIST-LOW'.
  IF sy-subrc = 0.
    lv_user_input_low = ls_dynpfield-fieldvalue.
    " <- Here's the actual input user typed
  ENDIF.


  IF lv_user_input_low CP '*'.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
*    REPLACE ALL OCCURRENCES OF '*' IN lv_user_input_low WITH '%'.
    DO.
    REPLACE ALL OCCURRENCES OF '*' IN lv_user_input_low WITH '%'.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
*--> EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.



  TRANSLATE lv_user_input_low TO UPPER CASE.

  CLEAR lt_user_addr[].

 IF lv_user_input_low IS NOT INITIAL.
    SELECT
        a~bname
        c~name_first
        c~name_last
        d~department
        a~kostl
        d~building
        d~roomnumber
        b~city1
        b~post_code1
        INTO CORRESPONDING FIELDS OF TABLE lt_user_addr
        FROM usr21 AS a
        LEFT OUTER JOIN adrc AS b ON a~addrnumber = b~addrnumber
        LEFT OUTER JOIN adrp AS c ON a~persnumber = c~persnumber
        LEFT OUTER JOIN adcp AS d ON a~persnumber = d~persnumber
        LEFT OUTER JOIN uscompany AS e ON a~addrnumber = e~addrnumber
        WHERE a~bname LIKE lv_user_input_low.
  ELSE.
    SELECT
        a~bname
        c~name_first
        c~name_last
        d~department
        a~kostl
        d~building
        d~roomnumber
        b~city1
        b~post_code1
        UP TO 500 ROWS
        INTO CORRESPONDING FIELDS OF TABLE lt_user_addr
        FROM usr21 AS a
        LEFT OUTER JOIN adrc AS b ON a~addrnumber = b~addrnumber
        LEFT OUTER JOIN adrp AS c ON a~persnumber = c~persnumber
        LEFT OUTER JOIN adcp AS d ON a~persnumber = d~persnumber
        LEFT OUTER JOIN uscompany AS e ON a~addrnumber = e~addrnumber
        WHERE a~bname IS NOT NULL.
   ENDIF.


    SORT lt_user_addr ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_user_addr COMPARING ALL FIELDS.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' "#EC SAST_CI_GEN_CHECK
      EXPORTING
        retfield    = 'BNAME'
        dynpprog    = sy-cprog
        dynpnr      = sy-dynnr
        dynprofield = 'USERLIST'
       value_org   = 'S'
*       multiple_choice = 'X'
      TABLES
*        field_tab   = gt_usrfields[]
        value_tab   = lt_user_addr
        return_tab  = gt_return_tab.



ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  USERLIST_VALUE_HIGH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM userlist_value_high .

  TYPES: BEGIN OF ty_user_addr,
        bname TYPE xubname,
        name_first  TYPE  ad_namefir,
        name_last TYPE  ad_namelas,
        department  TYPE  ad_dprtmnt,
        kostl TYPE  xukostl,
        building  TYPE  ad_bldng_p,
        roomnumber  TYPE  ad_roomnum,
        city1 TYPE  ad_city1,
        post_code1 TYPE  ad_pstcd1,
      END OF ty_user_addr.

  DATA: lt_user_addr TYPE STANDARD TABLE OF ty_user_addr,
        ls_user_addr LIKE LINE OF lt_user_addr.

  DATA: lt_dynpfields TYPE STANDARD TABLE OF dynpread,
        ls_dynpfield  TYPE dynpread,
        lv_user_input_low TYPE xubname,
        lv_user_input_high TYPE xubname.

  CLEAR ls_dynpfield.
  CLEAR lt_dynpfields[].

  ls_dynpfield-fieldname = 'USERLIST-HIGH'.
  APPEND ls_dynpfield TO lt_dynpfields.


  CALL FUNCTION 'DYNP_VALUES_READ'
    EXPORTING
      dyname     = sy-cprog
      dynumb     = sy-dynnr
    TABLES
      dynpfields = lt_dynpfields
    EXCEPTIONS
*BOC UMITTAL SE-ATC Fixes 25/02/2026 PN 16658
      invalid_abapworkarea  = 1
      invalid_dynprofield   = 2
      invalid_dynproname    = 3
      invalid_dynpronummer  = 4
      invalid_request       = 5
      no_fielddescription   = 6
      invalid_parameter     = 7
      undefind_error        = 8
      double_conversion     = 9
      stepl_not_found       = 10
      others                = 11.
  IF sy-subrc <> 0.
    MESSAGE s002 WITH 'Exception Occured'(067) .
  ENDIF.
*EOC UMITTAL SE-ATC Fixes 25/02/2026 PN 16658
  READ TABLE lt_dynpfields INTO ls_dynpfield
  WITH KEY fieldname = 'USERLIST-HIGH'.
  IF sy-subrc = 0.
    lv_user_input_high = ls_dynpfield-fieldvalue.
    " <- Here's the actual input user typed
  ENDIF.


  IF lv_user_input_high CP '*'.
*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
*    REPLACE ALL OCCURRENCES OF '*' IN lv_user_input_high WITH '%'.
    DO.
    REPLACE ALL OCCURRENCES OF '*' IN lv_user_input_high WITH '%'.
      IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.
*--> EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
  ENDIF.

  TRANSLATE lv_user_input_high TO UPPER CASE.

    CLEAR lt_user_addr[].

 IF lv_user_input_high IS NOT INITIAL.
    SELECT
        a~bname
        c~name_first
        c~name_last
        d~department
        a~kostl
        d~building
        d~roomnumber
        b~city1
        b~post_code1
        UP TO 500 ROWS
        INTO CORRESPONDING FIELDS OF TABLE lt_user_addr
        FROM usr21 AS a
        LEFT OUTER JOIN adrc AS b ON a~addrnumber = b~addrnumber
        LEFT OUTER JOIN adrp AS c ON a~persnumber = c~persnumber
        LEFT OUTER JOIN adcp AS d ON a~persnumber = d~persnumber
        LEFT OUTER JOIN uscompany AS e ON a~addrnumber = e~addrnumber
        WHERE a~bname LIKE lv_user_input_high.
  ELSE.
    SELECT
        a~bname
        c~name_first
        c~name_last
        d~department
        a~kostl
        d~building
        d~roomnumber
        b~city1
        b~post_code1
        UP TO 500 ROWS
        INTO CORRESPONDING FIELDS OF TABLE lt_user_addr
        FROM usr21 AS a
        LEFT OUTER JOIN adrc AS b ON a~addrnumber = b~addrnumber
        LEFT OUTER JOIN adrp AS c ON a~persnumber = c~persnumber
        LEFT OUTER JOIN adcp AS d ON a~persnumber = d~persnumber
        LEFT OUTER JOIN uscompany AS e ON a~addrnumber = e~addrnumber
        WHERE a~bname IS NOT NULL.
   ENDIF.

    SORT lt_user_addr ASCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_user_addr COMPARING ALL FIELDS.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST' "#EC SAST_CI_GEN_CHECK
      EXPORTING
        retfield    = 'BNAME'
        dynpprog    = sy-cprog
        dynpnr      = sy-dynnr
        dynprofield = 'USERLIST'
       value_org   = 'S'
*       multiple_choice = 'X'
      TABLES
*        field_tab   = gt_usrfields[]
        value_tab   = lt_user_addr
        return_tab  = gt_return_tab.

ENDFORM.
