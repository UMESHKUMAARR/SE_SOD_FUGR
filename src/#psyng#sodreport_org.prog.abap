*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SODREPORT_ORG
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  21/04/2020   Gurpinder   C0014       D67K902674                     *
*----------------------------------------------------------------------*

REPORT /psyng/sodreport NO STANDARD PAGE HEADING LINE-SIZE 170
                        MESSAGE-ID /psyng/sw. "#EC SAST_CI_GEN_CHECK

TABLES:
  /psyng/conflict,
  usr21,
  usr02,
  agr_define,
  rfcdes,
  /psyng/swsodorgm,
  /psyng/sw_uinfo,
  /psyng/ex_caobj_lock,
  ust04.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_113.
TYPE-POOLS: slis.                                      "For ALV call
CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME'.

TYPES: BEGIN OF ty_functtran,
         functionid TYPE /psyng/function_id,
         tcode      TYPE tcode,
         fioriid    TYPE /psyng/sw_fioriid,
         appname    TYPE /psyng/sw_fioriname,
       END OF   ty_functtran,

       BEGIN OF ty_fioria,
         fioriid TYPE /psyng/sw_fioriid,
         appname TYPE /psyng/sw_fioriname,
       END OF   ty_fioria.

CLASS /psyng/sw_cl_constants DEFINITION LOAD.
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      alv_grid_titl   TYPE lvc_title.                  "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv
                      WITH HEADER LINE.                     "#EC NEEDED
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort              TYPE slis_sortinfo_alv,
      gt_enh_tcodes       TYPE TABLE OF /psyng/sw_par_tcode_output,
      g_dynnr             TYPE sy-dynnr,
      gt_map_tcode_screen TYPE TABLE OF /psyng/tcode_screen
      WITH HEADER LINE,
      gf_cfg_set_enabled  TYPE flag.

DATA: gt_filter_role_detail TYPE slis_t_filter_alv,
      gf_org_fields_display TYPE flag VALUE 'X'.

DATA: pertext(200),        "Progress indicator text
      exit_proc,
      gf_hide_org            TYPE /psyng/bapiflagx,
      gf_org_field type flag. "AKUMAR OPL645
DATA : gf_central_uid TYPE flag.                            "#EC NEEDED
*Background job variables
DATA: curr_report  LIKE  rsvar-report,
      curr_variant LIKE  rsvar-variant,
      vari_desc    TYPE varid OCCURS 0                      "#EC NEEDED
      WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: ivarit TYPE varit OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF s_text ,                                     "OCCURS 0,
        text LIKE tline-tdline,
      END OF s_text.

DATA  i_text LIKE s_text OCCURS 0 WITH HEADER LINE.

TYPES : BEGIN OF type_agr_define.
          INCLUDE STRUCTURE agr_define.
          TYPES : rfcdest TYPE rfcdest,
        END OF type_agr_define.
DATA: wa_iagr_define TYPE type_agr_define.

DATA: simuagrs TYPE  type_agr_define OCCURS 0 WITH HEADER LINE.

DATA: irfc LIKE rfcdes OCCURS 0 WITH HEADER LINE.

TYPES: BEGIN OF typ_routdet,
         agr_name      LIKE agr_define-agr_name,
         isort         TYPE i,
         imp           LIKE /psyng/conflict-imp,
         conid         LIKE /psyng/conflict-conid,     "details
         risk          LIKE /psyng/conflict-risk,
         functionid    LIKE /psyng/functtran-functionid,
         rfcdest       LIKE rfcdes-rfcdest,
         tcode         LIKE ust12-von, "LIKE /psyng/faobj2-tcode,
         objct         LIKE ust12-objct,
         org_abb       LIKE /psyng/swsodorgm-abb, "org level reporting
         auth          LIKE ust12-auth,
         field         LIKE ust12-field,
         von           LIKE ust12-von,
         bis           LIKE ust12-bis,
         child_agr     LIKE agr_agrs-child_agr,
         description   LIKE /psyng/conflict-description,
         simu          TYPE c,
         enhanced      TYPE c, "flag for enhanced ruleset
         color_line(4) TYPE c,           " Line color
         color_cell    TYPE lvc_t_scol,  " Cell color
         appl          TYPE /psyng/ex_caobj_lock-appl,
         org_type      TYPE i,
       END OF typ_routdet.

DATA: routdet3 TYPE typ_routdet OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF routdet4 OCCURS 0,
        agr_name      LIKE agr_define-agr_name,  "composite role
        isort         TYPE i,
        imp           LIKE /psyng/conflict-imp,
        conid         LIKE /psyng/conflict-conid,    "details
        risk          LIKE /psyng/conflict-risk,
        functionid    LIKE /psyng/functtran-functionid,
        rfcdest       LIKE rfcdes-rfcdest,
        tcode         LIKE ust12-von, "LIKE /psyng/faobj2-tcode,
        objct         LIKE ust12-objct,
        org_abb       LIKE /psyng/swsodorgm-abb, "org level reporting
        auth          LIKE ust12-auth,
        field         LIKE ust12-field,
        von           LIKE ust12-von,
        bis           LIKE ust12-bis,
        child_agr     LIKE agr_agrs-child_agr,   "single role
        description   LIKE /psyng/conflict-description,
        simu          TYPE c,
        enhanced      TYPE c, "flag for enhanced ruleset
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
        appl          TYPE /psyng/ex_caobj_lock-appl,
        org_type      TYPE i,
      END OF routdet4.
DATA: BEGIN OF r_output_det_text OCCURS 0,
        agr_name       LIKE agr_define-agr_name,  "composite role
        agrdesc        LIKE agr_texts-text,
        isort          TYPE i,
        imp            LIKE /psyng/conflict-imp,
        conid          LIKE /psyng/conflict-conid,    "details
        risk           LIKE /psyng/conflict-risk,
        functionid     LIKE /psyng/functtran-functionid,
        fundesc        LIKE /psyng/function-description,
        rfcdest        LIKE rfcdes-rfcdest,
        tcode          LIKE ust12-von, "LIKE /psyng/faobj2-tcode,
        tcodedesc      LIKE /psyng/sw_fioria-appname, "tstct-ttext,
        objct          LIKE ust12-objct,
        objctdesc      LIKE tobjt-ttext,
        org_abb        LIKE /psyng/swsodorgm-abb, "org level reporting
        auth           LIKE ust12-auth,
        field          LIKE ust12-field,
        von            LIKE ust12-von,
        bis            LIKE ust12-bis,
        child_agr      LIKE agr_agrs-child_agr,   "single role
        child_agr_desc LIKE agr_texts-text,
        description    LIKE /psyng/conflict-description,
        simu           TYPE c,
        enhanced       TYPE c, "flag for enhanced ruleset
        color_line(4)  TYPE c,           " Line color
        color_cell     TYPE lvc_t_scol,  " Cell color
        appl           TYPE /psyng/ex_caobj_lock-appl,
        org_type       TYPE i,
      END OF r_output_det_text.

DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.

DATA: BEGIN OF r1stoutput OCCURS 10.            "Table to output 1st
DATA: rfcdest       TYPE rfcdest,
      agr_name      LIKE agr_define-agr_name,
      imp           LIKE /psyng/conflict-imp,
      isort         TYPE i,
      conid         LIKE /psyng/conflict-conid,
      description   LIKE /psyng/conflict-description,
      risk          LIKE /psyng/conflict-risk,
      simu          TYPE c,
      enhanced      TYPE c, "flag for enhanced ruleset
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol,  " Cell color
      appl          TYPE /psyng/ex_caobj_lock-appl.
DATA: END OF r1stoutput.

DATA: conflictcount   TYPE i,
      averagecon      TYPE i,
      c_averagecon(4) TYPE c,
      trolecount      TYPE i,
      c_trolecount(6) TYPE c,
      c_rolecount(6)  TYPE c,
      g_persa         TYPE /psyng/persa,
      go_classtype    TYPE REF TO cl_abap_typedescr.        "#EC NEEDED

DATA: wa_swconfig TYPE /psyng/swconfig.
DATA : l_rfc_with_searchhelp TYPE /psyng/rfcdest.
DATA: g_agrname_dtlclk TYPE agr_define-agr_name,
      g_role_popup     TYPE agr_define-agr_name.
DATA : usertype   TYPE /psyng/xuustyp,
       gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       ls_ba_role TYPE /psyng/bc_ba_00.

DATA: cc                    TYPE lvc_t_scol
              WITH HEADER LINE,                             "#EC NEEDED
      color                 TYPE lvc_s_colo,
      lt_role_removal_simu
        TYPE TABLE OF /psyng/sw_role_removal_simu,
      lt_role_addition_simu
        TYPE TABLE OF /psyng/sw_role_addition_simu,
      lt_enh_con            TYPE TABLE OF /psyng/sw_enh_usr_con
                             WITH HEADER LINE,
      l_tcode(40)           TYPE c,
      g_current_user        TYPE sy-uname. "C0700

*BOC : UMITTAL SMUD issue
DATA: gt_role_range TYPE RANGE OF agr_define-agr_name.
" Define range table
*EOC : UMITTAL SMUD issue
SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-003.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: byuser RADIOBUTTON GROUP g1 USER-COMMAND radi DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 4(25) text-007 FOR FIELD byuser.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:   pbname FOR usr02-bname.  "user ID
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(25) text-018.
SELECT-OPTIONS:   xusrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh. "RFC destinations for
SELECTION-SCREEN: END OF LINE.
SELECT-OPTIONS:  s_role FOR agr_define-agr_name MODIF ID usr,
                 s_prof FOR  ust04-profile MODIF ID usr.


SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : p_locusr AS CHECKBOX.       "use local users only for cross
SELECTION-SCREEN COMMENT 7(60) text-162 FOR FIELD p_locusr."sys analys
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
*Only analyze remote systems
SELECTION-SCREEN: POSITION 4.

PARAMETERS : p_remonl AS CHECKBOX USER-COMMAND remo.
SELECTION-SCREEN COMMENT 7(45) text-181 FOR FIELD p_remonl.
SELECTION-SCREEN END OF LINE.


SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: byugrp   RADIOBUTTON GROUP g1.
SELECTION-SCREEN: COMMENT 4(25) text-008 FOR FIELD byugrp.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:   pclass FOR usr02-class.  "user group
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: bypa   RADIOBUTTON GROUP g1.
SELECTION-SCREEN: COMMENT 4(25) text-017 FOR FIELD bypa.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:   pwerks FOR g_persa.       "personnel area
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: byrole   RADIOBUTTON GROUP g1.
SELECTION-SCREEN: COMMENT 4(25) text-009 FOR FIELD byrole.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS: role FOR agr_define-agr_name. "role
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(25) text-173.
SELECT-OPTIONS:   xrolerfc FOR l_rfc_with_searchhelp MATCHCODE OBJECT
/psyng/sw_rfcsh."RFC dest. for
SELECTION-SCREEN: END OF LINE.                 "roles


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(25) text-013.
SELECTION-SCREEN: POSITION 33.
PARAMETERS:   rchdatf LIKE agr_define-change_dat. "role change date from
SELECTION-SCREEN: COMMENT 52(6) text-014.
SELECTION-SCREEN: POSITION 58.
PARAMETERS:   rchdatt LIKE agr_define-change_dat. "role change date To
*************************************************
SELECTION-SCREEN: END OF LINE.
**************************************************
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 53.
SELECTION-SCREEN PUSHBUTTON  67(12) text-019 USER-COMMAND shrl.
SELECTION-SCREEN: END OF LINE.
**********************************************************
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : ronlyrem TYPE flag.
SELECTION-SCREEN: COMMENT 7(47) text-174 FOR FIELD ronlyrem.
SELECTION-SCREEN: END OF LINE.
PARAMETERS : comprol TYPE flag AS CHECKBOX,
             singrol TYPE flag AS CHECKBOX,
             assgn_r TYPE flag AS CHECKBOX.

SELECTION-SCREEN: END OF BLOCK exe.
*--SE3.1 : Include selection screen for simulation from external report
*(/psyng/sw_113)
SELECTION-SCREEN INCLUDE BLOCKS b_sim.

SELECTION-SCREEN: BEGIN OF BLOCK res WITH FRAME TITLE text-005.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shosum RADIOBUTTON GROUP g2 DEFAULT 'X'
                   USER-COMMAND show.  "SOD conflict
SELECTION-SCREEN: COMMENT 4(28) text-010 FOR FIELD shosum.    "summary

SELECTION-SCREEN: POSITION 34.
PARAMETERS: pcolor AS CHECKBOX DEFAULT ' '. "Highlight conflicts
SELECTION-SCREEN: COMMENT 36(30) text-000 FOR FIELD pcolor.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shodet   RADIOBUTTON GROUP g2.  "SOD conflict detail
SELECTION-SCREEN: COMMENT 4(50) text-022 FOR FIELD shodet.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shotree   RADIOBUTTON GROUP g2. " sod Conflict detail Tree
SELECTION-SCREEN: COMMENT 4(55) text-161 FOR FIELD shotree.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shosimp   RADIOBUTTON GROUP g2.
SELECTION-SCREEN: COMMENT 4(55) text-215 FOR FIELD shosimp.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN SKIP 1.


*-- Layout Selection
SELECTION-SCREEN: BEGIN OF BLOCK layo WITH FRAME TITLE text-216.
PARAMETERS: p_layo TYPE slis_vari MODIF ID out.
PARAMETERS: p_dlayo TYPE slis_vari MODIF ID out.
SELECTION-SCREEN: END OF BLOCK layo.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance. "Enhanced ruleset
SELECTION-SCREEN COMMENT 3(30) text-155.
PARAMETERS p_hienhn AS CHECKBOX.
SELECTION-SCREEN COMMENT 36(49) text-156.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(27) text-023.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:  spconfs FOR /psyng/conflict-conid. "Specific Conflicts
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-012.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:  sens FOR /psyng/conflict-imp. "Sensitivity
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-175.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS: s_risk FOR /psyng/conflict-risk. "Risk scenario
SELECTION-SCREEN: END OF LINE.
*Version selection
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-154.
SELECTION-SCREEN: POSITION 33.
PARAMETERS:  sodvrsio LIKE /psyng/conflict-vrsio
MEMORY ID /psyng/vrsio. "SOD Version
SELECTION-SCREEN: END OF LINE.
*Version selection

PARAMETERS: validusr AS CHECKBOX DEFAULT ' '  MODIF ID usr
 USER-COMMAND usr_fil.
SELECT-OPTIONS : usrtype FOR usertype MODIF ID usr.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
SELECTION-SCREEN COMMENT 1(79) text-100 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: exlckusr AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-102.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: outvdate AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-101.
SELECTION-SCREEN END OF LINE.

PARAMETERS: showcomp AS CHECKBOX DEFAULT space,
            showpcom AS CHECKBOX DEFAULT space.
PARAMETERS: xmc      AS CHECKBOX DEFAULT ' ',
"ignore mitigating controls
            shonosod AS CHECKBOX DEFAULT ' ',  "show users w/o conflicts
            ustb     AS CHECKBOX DEFAULT ' ', "update SCAN table
            erroles  AS CHECKBOX DEFAULT ' ', "Include Pre-Approved
            excl_er  AS CHECKBOX DEFAULT ' ',
            orgchk   AS CHECKBOX DEFAULT ' ' USER-COMMAND org,
*           don't show progress indicator
            p_noprin TYPE flag NO-DISPLAY DEFAULT ' '.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-176.
SELECTION-SCREEN: POSITION 30.
SELECT-OPTIONS:
orglvl  FOR /psyng/swsodorgm-abb ."org level  abbreviation
SELECTION-SCREEN: END OF LINE.


*--Conflict origin
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-172.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X'.
SELECTION-SCREEN : COMMENT 24(10) text-131 FOR FIELD p_local.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag DEFAULT ' '.
SELECTION-SCREEN COMMENT 37(10) text-132 FOR FIELD p_remote.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag DEFAULT ' '.
SELECTION-SCREEN COMMENT 51(20) text-171 FOR FIELD p_cross.

SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK res.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-006.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-025.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-026.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-002 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-001 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.
*--Hidden parameters for when report is called from other report
PARAMETERS:
  varntnam    LIKE varid-variant              , "NO-DISPLAY,
  byall       TYPE flag                       , "NO-DISPLAY,
* RFC Destination to read SOD Matrix from
  p_sodrfc    TYPE rfcdest,
  p_caldet(1) TYPE c                          , "NO-DISPLAY,
  p_nabap     TYPE flag                       , "NO-DISPLAY,
  p_abap      TYPE flag                       , "NO-DISPLAY,
  cfgset      TYPE /psyng/seconfid            , "NO-DISPLAY,
  p_shtext    TYPE flag,
  p_shhis     TYPE flag. "NO-DISPLAY.
SELECT-OPTIONS:
  s_comp      FOR /psyng/sw_uinfo-company     NO-DISPLAY,
  s_depart    FOR /psyng/sw_uinfo-department  NO-DISPLAY,
  s_cuid      FOR /psyng/sw_uinfo-central_uid NO-DISPLAY,
  s_appl      FOR /psyng/ex_caobj_lock-appl   NO-DISPLAY,
  s_sysid     FOR /psyng/ex_caobj_lock-sysid  NO-DISPLAY,
  s_kostl     FOR usr21-kostl                 NO-DISPLAY,
  s_rba       FOR ls_ba_role-busarea.

SELECTION-SCREEN: BEGIN OF BLOCK hblox WITH FRAME TITLE text-233.
SELECTION-SCREEN: BEGIN OF BLOCK hblo1 WITH FRAME TITLE text-235.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-l03
  MODIF ID hb
  FOR FIELD h_stdt.
SELECTION-SCREEN : POSITION 34.
PARAMETERS : h_stdt TYPE dats
  MODIF ID hb .
SELECTION-SCREEN COMMENT 46(3) text-l04
  MODIF ID hb
  FOR FIELD h_eddt.
SELECTION-SCREEN : POSITION 57.
PARAMETERS : h_eddt TYPE dats
  MODIF ID hb DEFAULT l_yesterday.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK hblo1.

SELECTION-SCREEN: BEGIN OF BLOCK hblo2 WITH FRAME TITLE text-234.
PARAMETERS :
  h_usr TYPE flag AS CHECKBOX,
  h_any TYPE flag AS CHECKBOX,
  h_all TYPE flag AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK hblo2.
PARAMETERS : h_tcdo TYPE flag.
SELECTION-SCREEN: END OF BLOCK hblox.

INITIALIZATION.
  PERFORM exelog.
  PERFORM get_initial_config.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = gc_erp_class
    RECEIVING
      p_descr_ref    = go_classtype
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  IF sy-subrc <> 0.
*   Remove Personnel Area from screen
    LOOP AT SCREEN.
      CHECK screen-name CS 'PWERKS' OR screen-name CS 'BYPA'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.



*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
    IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        IMPORTING
          e_config_set = cfgset.
    ENDIF.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.


AT SELECTION-SCREEN.
  PERFORM check_input.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.

AT SELECTION-SCREEN OUTPUT. " ON RADIOBUTTON GROUP G2.
*BOC : UMITTAL SMUD issue
  CLEAR gt_role_range[].
  gt_role_range[] = role[].
*EOC : UMITTAL SMUD issue
  LOOP AT SCREEN.

**-- Layout selection
    IF screen-name CS 'P_LAYO'.
      IF shodet = 'X' OR shotree = 'X' OR shosimp = 'X'.
        screen-active = 0.
        CLEAR : p_layo.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name CS 'P_DLAYO'.
      IF shosum = 'X' OR shotree = 'X' OR shosimp = 'X'.
        screen-active = 0.
        CLEAR : p_dlayo.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.



    CASE screen-name .
      WHEN 'SHOTREE'.
        IF NOT byrole IS INITIAL." AND NOT shotree IS INITIAL.
*         tree can not be used for role analysis
          IF NOT shotree IS INITIAL.
            shodet = 'X'.
            CLEAR shotree.
          ENDIF.
          screen-input = 0 .
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'PCOLOR' .
        IF shosum = 'X' .
          screen-input = 1 .
        ELSE.
          CLEAR pcolor.
          screen-input = 0 .
        ENDIF.

      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          IF p_caldet <> 'X'.
            screen-input = 1.
            p_hienhn = 'X'.
          ENDIF.
        ENDIF.

      WHEN 'SHOWCOMP'.
        IF shosum = 'X'.
          CLEAR showcomp.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'SHONOSOD'.
        IF NOT spconfs[] IS INITIAL.
          screen-input = 0.
          CLEAR shonosod.
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'ORGCHK'.
        IF gf_hide_org = 'X'.
          screen-active = 0.
        ELSE.
          screen-active = 1.
        ENDIF.

      WHEN 'P_LOCAL' OR 'P_REMOTE' OR 'P_CROSS'.
        IF byrole = 'X'.
          screen-input = 0.
          p_local = p_remote = p_cross = ''.
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'ORGLVL-LOW' OR 'ORGLVL-HIGH'.
        IF orgchk = 'X'.
          screen-input = 1.
        ELSE.
          REFRESH : orglvl.
          screen-input = 0.
        ENDIF.
    ENDCASE.

    IF screen-group1 = '001'.
      AUTHORITY-CHECK OBJECT 'S_BTCH_ADM'
      ID 'BTCADMIN' FIELD 'Y'.
      IF sy-subrc <> 0.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    MODIFY SCREEN .
  ENDLOOP.

*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR pwerks-low.
*  PERFORM f4_werks CHANGING pwerks-low.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR pwerks-high.
*  PERFORM f4_werks CHANGING pwerks-high.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
*  PERFORM f4_usrtype CHANGING usrtype-low.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
*  PERFORM f4_usrtype CHANGING usrtype-high.
*
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
*--Apply parameter REPEAT_HDR_BKGDJOB to increase page size in spool
*  so page headers are not repeated
  CALL FUNCTION '/PSYNG/SW_BG_JOB_PRINT_PARAMS'.
  program = sy-repid.
  IF exit_proc = 'Y'.
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.
*BOC : UMITTAL SMUD issue
  CLEAR role[].
  role[] = gt_role_range[].
*EOC : UMITTAL SMUD issue
*-- Check RFC destinations
  IF     bysimu = 'X'
  OR     byrsimu = 'X'
  OR NOT xusrrfc[]  IS INITIAL
  OR NOT xrolerfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.


  CONCATENATE sy-title text-154 sodvrsio
              INTO sy-title SEPARATED BY space.
  DATA: "date(10),
    lt_simuagrs      TYPE TABLE OF /psyng/simu_agrs WITH HEADER LINE,
*        l_rfcdest TYPE rfcdest,
    l_system_msg(72) TYPE c.                                "#EC NEEDED
  LOOP AT simuagrs.
    MOVE-CORRESPONDING simuagrs TO lt_simuagrs .
    APPEND lt_simuagrs .
  ENDLOOP.

  CASE 'X'.
    WHEN byuser OR byugrp OR bypa.
    WHEN byrole.

      IF byrsimu = 'X'.
*    --prepare table for role removal simulation
        PERFORM prepare_role_removal_simu
          TABLES lt_role_removal_simu.
      ENDIF.
      IF bysimu = 'X'.
*--3.1 prepare table for role removal simulation
        PERFORM prepare_role_addition_simu
          TABLES lt_role_addition_simu.
      ENDIF.

      PERFORM vaildate_other_fields TABLES lt_role_addition_simu
                                         lt_role_removal_simu.

*      PERFORM role_based_sod_analysis.
      DATA : lt_routputdet TYPE TABLE OF /psyng/sw_out_routdet3.
      FREE : lt_routputdet.
      CALL FUNCTION '/PSYNG/SW_083'
        EXPORTING
          i_noprin              = p_noprin
          i_bysimu              = bysimu
          i_showcomp            = showcomp
          i_orgchk              = orgchk
          i_sodvrsio            = sodvrsio
          i_config_set          = cfgset
          i_enhanc              = p_enhanc
          i_hienhn              = p_hienhn
          i_xmc                 = xmc
          i_shonosod            = shonosod
          i_ustb                = ustb
          i_shosum              = ' ' "shosum
          i_rolerfc             = rolerfc
          i_advanced_role_simu  = ' '
          i_ronlyrem            = ronlyrem
          i_rchdatt             = rchdatt
          i_rchdatf             = rchdatf
          i_composite_roles     = comprol
          i_single_roles        = singrol
          i_shomit              = xmc
          i_assigned_roles      = assgn_r
          i_abap                = p_abap
          i_nabap               = p_nabap
          i_org_field           = gf_org_field "AKUMAR
        IMPORTING
          e_rolecount           = trolecount
        TABLES
          it_roles              = role
          it_rfcdest            = xrolerfc
          it_simurols           = simurols
          it_conflicts          = spconfs
          it_sens               = sens
          it_risk               = s_risk
          it_orglvl             = orglvl
          et_outputdet          = lt_routputdet
          et_enh_tcodes         = gt_enh_tcodes
          et_simuagrs           = lt_simuagrs
          et_enh_con            = lt_enh_con
          it_simu_role_removal  = lt_role_removal_simu
          it_simu_role_addition = lt_role_addition_simu
          it_appl               = s_appl
          it_sysid              = s_sysid
          et_map_tcode_screen   = gt_map_tcode_screen
          it_role_ba            = s_rba.


      PERFORM output_roles
        TABLES
         lt_routputdet
         lt_enh_con.


      MESSAGE s398(00) WITH text-083 '' '' ''.
  ENDCASE.

*  PERFORM wrap_up.
*^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
***********************************************************************

TOP-OF-PAGE.
  CASE 'X'.
    WHEN byuser OR byugrp OR bypa.
      WRITE:/ text-086 COLOR 5, /5 text-012 COLOR 6,
          /10 text-087 COLOR 7, /15 text-088 COLOR 1,
          /20 text-089 COLOR 2, /25 text-090,
          /30 text-091, /35 text-092, /40 text-093,
          /45 text-094, 86 text-095, 127 text-096, 158 text-097.
      ULINE.
    WHEN byrole.
      WRITE:/ text-096 COLOR 5, /5 text-087 COLOR 7,
          /10 text-088 COLOR 1, /15 text-090,
          /20 text-089 COLOR 2,
          /25 text-091, /30 text-092, /40 text-093,
          51 text-094, 92 text-095, 133 text-098.
      ULINE.
  ENDCASE.
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_input.
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest.

  IF sy-ucomm = 'ADVSIM'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    CALL FUNCTION '/PSYNG/SW_080'
      TABLES
        et_bname = pbname.
    EXIT.
  ENDIF.

  IF byuser = 'X' AND pbname IS INITIAL AND
    sy-ucomm+0(1) <> '%' AND    sy-ucomm <> 'RADI'.
    IF s_comp IS INITIAL AND s_depart IS INITIAL AND
      s_cuid IS INITIAL AND  pclass IS INITIAL.
      SET CURSOR FIELD 'PBNAME-LOW'.
      MESSAGE e208(00) WITH text-028.
    ENDIF.
  ELSEIF byugrp = 'X' AND pclass IS INITIAL AND
         sy-ucomm+0(1) <> '%' AND sy-ucomm <> 'RADI'.
    SET CURSOR FIELD 'PCLASS-LOW'.
    MESSAGE e208(00) WITH text-030.
  ENDIF.
  IF byrole = 'X'.
    IF  NOT rchdatf IS INITIAL.
      IF rchdatt IS INITIAL .
        rchdatt = '99991231'.
      ENDIF.
      IF rchdatf > rchdatt.
        SET CURSOR FIELD 'RCHDATT'.
        MESSAGE e650(db).
      ENDIF.
    ENDIF.
    IF sy-ucomm = 'SHRL'.
      PERFORM show_roles_based_on_dates.
    ENDIF.
  ENDIF.       "byrole = 'X'
  IF bypa = 'X' AND pwerks IS INITIAL AND sy-ucomm+0(1) <> '%' AND
                                            sy-ucomm <> 'RADI'.
    SET CURSOR FIELD 'PWERKS-LOW'.
    MESSAGE e208(00) WITH text-033.
  ENDIF.
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

*Remote only analysis
  IF sy-ucomm = 'REMO'.
    IF p_remonl = 'X'.
      CLEAR :p_local,p_cross.
      p_remote = 'X'.
      IF lt_dest[] IS INITIAL.
        MESSAGE w140 WITH
        'Please enter RFC destinations for remote analysis'(182).

      ENDIF.
    ELSE.
      p_local = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " check_input




*&---------------------------------------------------------------------*
*&      Form  ROLE_DOUBLE_CLICK_ON_SUMRY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_double_click_on_sumry
    USING r_ucomm LIKE sy-ucomm                             "#EC CALLED
                                                            "#EC NEEDED
    rs_selfield TYPE slis_selfield.
  DATA: ls_variant TYPE disvariant.

  READ TABLE r1stoutput INDEX rs_selfield-tabindex.
  CHECK sy-subrc = 0.
  REFRESH routdet4.
  LOOP AT routdet3 WHERE agr_name  = r1stoutput-agr_name AND
                           conid   = r1stoutput-conid AND
                           rfcdest = r1stoutput-rfcdest.
    MOVE-CORRESPONDING routdet3 TO routdet4.
    APPEND routdet4.
  ENDLOOP.
  SORT routdet4 BY agr_name conid functionid tcode
                   objct auth child_agr.

*check to see if the customer wants to see the output details in ALV
*format or standard list
  se_config_param 'SW_SOD_REPO_DETAIL' wa_swconfig-value.
  IF wa_swconfig-value = 'LIST'.
*   Since a customer doesn't have the latest support packs for
*   ALV output we have to print info in standard list format
    MESSAGE i030 WITH 'SW_SOD_REPO_DETAIL'.
*   This functionality is no longer supported : & .
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'ROUTDET4'
      i_inclname         = program
    CHANGING
      ct_fieldcat        = i_fieldcat_alv2
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

  wa_fieldcat_alv-key = ' '.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.

  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DESCRIPTION'.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CHILD_AGR'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'AGR_NAME'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.

  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'RISK'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FUNCTIONID'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'OBJCT'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FIELD'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'VON'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'BIS'.

  wa_fieldcat_alv-seltext_l = text-099.
  wa_fieldcat_alv-seltext_m = text-099.
  wa_fieldcat_alv-seltext_s = text-216.
  wa_fieldcat_alv-reptext_ddic = text-099.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CHILD_AGR'.
  wa_fieldcat_alv-seltext_l = text-218.
  wa_fieldcat_alv-seltext_m = text-218.
  wa_fieldcat_alv-seltext_s = text-103.
  wa_fieldcat_alv-reptext_ddic = text-218.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.
  wa_fieldcat_alv-seltext_l = text-104.
  wa_fieldcat_alv-seltext_m = text-105.
  wa_fieldcat_alv-seltext_s = text-105.
  wa_fieldcat_alv-reptext_ddic = text-104.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'VON'.
  wa_fieldcat_alv-seltext_l = text-106.
  wa_fieldcat_alv-seltext_m = text-107.
  wa_fieldcat_alv-seltext_s = text-107.
  wa_fieldcat_alv-reptext_ddic = text-106.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BIS'.
  wa_fieldcat_alv-seltext_l = text-217.
  wa_fieldcat_alv-seltext_m = text-093.
  wa_fieldcat_alv-seltext_s = text-093.
  wa_fieldcat_alv-reptext_ddic = text-217.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FIELD'.
  wa_fieldcat_alv-seltext_l =  text-103.
  wa_fieldcat_alv-seltext_m = text-109.
  wa_fieldcat_alv-seltext_s = text-110.
  wa_fieldcat_alv-reptext_ddic = text-109.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCODE'.
*delete the color columns
  DELETE i_fieldcat_alv2 WHERE fieldname = 'COLOR_LINE'.
  DELETE i_fieldcat_alv2 WHERE fieldname = 'COLOR_CELL'.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'ISORT'.
*no key fields
  wa_fieldcat_alv-key = ' '.
  MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  IF bysimu = 'X'.
    wa_fieldcat_alv-seltext_l = text-115.
    wa_fieldcat_alv-seltext_m = text-115.
    wa_fieldcat_alv-seltext_s = text-116.
    wa_fieldcat_alv-reptext_ddic = text-115.
    wa_fieldcat_alv-checkbox     = 'X'.
    wa_fieldcat_alv-just    = 'X'.
    MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                     WHERE
                        fieldname = 'SIMU'.
  ELSE.
    DELETE i_fieldcat_alv2 WHERE fieldname = 'SIMU'.
  ENDIF.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  IF p_enhanc = 'X'.

*  if highlight enhanced ruleset is selected, add this field to the alv
    wa_fieldcat_alv-seltext_l      = text-157.
    wa_fieldcat_alv-seltext_m      = text-158.
    wa_fieldcat_alv-seltext_s      = text-158.
    wa_fieldcat_alv-reptext_ddic   = text-217.
    wa_fieldcat_alv-checkbox       = 'X'.
    wa_fieldcat_alv-just       = 'X'.
    MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
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
    DELETE i_fieldcat_alv2 WHERE fieldname = 'ENHANCED'.
  ENDIF.
  IF orgchk IS INITIAL.
* hide column org_abb
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv2 FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'ORG_ABB'.

  ENDIF.

  CONCATENATE r1stoutput-agr_name text-119 r1stoutput-conid text-120
                                  INTO alv_grid_titl SEPARATED BY space.

  PERFORM build_role_sort_order  USING 'DET'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title             = alv_grid_titl
      it_sort                  = isort
      i_callback_program       = program
      i_callback_user_command  = 'ROLE_DOUBLE_CLICK_ON_DETL'
      i_callback_pf_status_set = 'SET_PF_STATUS'
      is_layout                = alv_layout
      it_fieldcat              = i_fieldcat_alv2
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = routdet4
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.  "ROLE_DOUBLE_CLICK_ON_SUMRY

*&---------------------------------------------------------------------*
*&      Form  ROLE_DOUBLE_CLICK_ON_DETL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_double_click_on_detl                              "#EC CALLED
  USING r_ucomm LIKE sy-ucomm
  rs_selfield TYPE slis_selfield.

  DATA:        l_hashcode     TYPE xupname.

  CASE r_ucomm.
    WHEN 'SHOW_TEXTS'.
      PERFORM output_role_details_with_texts.
      EXIT.
    WHEN 'TOGGLE_ORG'.
      PERFORM toggle_alv_role_org.
      EXIT.
  ENDCASE.
  CHECK r_ucomm = '&IC1'."drilldown
  DATA:wa_routdet4 LIKE LINE OF  routdet4,
       l_sod       TYPE /psyng/swsodvers-vrsio,
       l_uname     LIKE sy-uname,
       l_parva     TYPE usr05-parva,
       l_tcode     TYPE xutcode,
       l_system    TYPE /psyng/system,
       l_screen_id TYPE /psyng/user_right."++ UMITTAL PN6783 22/10/24

  DATA: agr_name       LIKE agr_define-agr_name,
*        line(80),
        answer,
        authfield      LIKE authx-fieldname,      "auth field
        iobjct         LIKE tobj-objct,
        l_risktext     LIKE /psyng/sw_risk-text,
        l_parva_exists LIKE sy-subrc.


  CASE rs_selfield-fieldname.
    WHEN 'CONID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      l_parva_exists = sy-subrc.
      IF l_parva_exists = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname 0.
      SET PARAMETER ID '/PSYNG/CON' FIELD rs_selfield-value.
      g_dynnr = '0202'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion
        USING l_sod l_uname l_parva_exists.
    WHEN 'TCODE'.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      l_tcode  = rs_selfield-value.
      l_system = routdet4-rfcdest.
*BOC UMITTAL PN6783 22/10/24
      l_screen_id = rs_selfield-value.
*      IF routdet4-appl NE 'SAP'.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
          EXPORTING
            i_tcode     = l_tcode
            i_vrsio     = sodvrsio
            i_funid     = routdet4-functionid
            if_non_abap = p_nabap
            i_appl      = routdet4-appl
            i_system    = l_system
            i_screen_id = l_screen_id.
*      ELSE.
**EOC UMITTAL PN6783 22/10/24
*          CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
*          EXPORTING
*            i_tcode     = l_tcode
*            i_vrsio     = sodvrsio
*            i_funid     = routdet4-functionid
*            if_non_abap = p_nabap
*            i_appl      = routdet4-appl
*            i_system    = l_system.
*      ENDIF. "++UMITTAL PN6783 22/10/24

    WHEN 'RISK'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE text INTO l_risktext FROM /psyng/sw_risk
                    WHERE risk = rs_selfield-value.
      CHECK sy-subrc = 0.

      CONCATENATE rs_selfield-value '=' l_risktext INTO l_risktext
                  SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-175
          text_question         = l_risktext
          text_button_1         = text-129
          icon_button_1         = 'ICON_SYSTEM_OKAY'
          text_button_2         = text-122
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '1'
          display_cancel_button = space
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'FIELD'.
      CHECK rs_selfield-value <> space.
      authfield = rs_selfield-value.
*BOC UMITTAL D67K934963 13-Nov-2024 PN-6783
"Display Pop up for Non ABAP
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF routdet4-appl EQ 'SAP' OR
         routdet4-appl EQ '' .
        CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
          EXPORTING
            fieldname = authfield.

      ELSE.
*EOC UMITTAL D67K934963 13-Nov-2024 PN-6783
        SUBMIT  /psyng/se_object_drilldown
        WITH r_field = 'X'
        WITH name = rs_selfield-value
        WITH p_appl   = routdet4-appl
        AND RETURN.
        EXIT.
      ENDIF. "(++)UMITTAL D67K934963 13-Nov-2024 PN-6783

    WHEN 'FUNCTIONID'.
      CHECK rs_selfield-value <> space.
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
      SET PARAMETER ID '/PSYNG/FUN' FIELD rs_selfield-value.
      g_dynnr = '0201'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion
        USING l_sod l_uname l_parva_exists.



    WHEN 'OBJCT'.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.

      IF routdet4-appl EQ 'SAP' OR "(++) UMITTAL D67K934963 PN-6783
         routdet4-appl EQ ''.
       iobjct = rs_selfield-value.
       CALL FUNCTION 'SUSR_SHOW_OBJECT'
         EXPORTING
           object  = iobjct
           eu_mode = ' '.
*BOC UMITTAL D67K934963 13-Nov-2024 PN-6783
"Display Pop up for Non ABAP
      ELSE.
        SUBMIT  /psyng/se_object_drilldown
        WITH r_object = 'X'
        WITH name = rs_selfield-value
        WITH p_appl   = routdet4-appl
        AND RETURN.
        EXIT.
      ENDIF.
*EOC UMITTAL D67K934963 13-Nov-2024 PN-6783
    WHEN 'VON'.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF routdet4-appl EQ 'SAP' OR "(++) UMITTAL D67K934963 PN-6783
         routdet4-appl EQ ''.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  routdet4-objct EQ  gc_service
      AND routdet4-field  EQ gc_srv_name.
        l_hashcode = routdet4-von.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode      = l_hashcode
            if_show_message = 'X'
          EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
        EXPORTING
          i_object        = routdet4-objct
          i_field         = routdet4-field
          i_value         = routdet4-von
          if_show_message = 'X'.
*BOC UMITTAL D67K934963 13-Nov-2024 PN-6783
"Display Pop up for Non ABAP
      ELSE.
        CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Value From Key & Actual Value'
           txt1          = rs_selfield-value
           txt2          = ''.
        EXIT.
      ENDIF.
*EOC UMITTAL D67K934963 13-Nov-2024 PN-6783
    WHEN 'BIS'.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.

      IF routdet4-appl EQ 'SAP' OR "(++) UMITTAL D67K934963 PN-6783
         routdet4-appl EQ ''.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  routdet4-objct EQ  gc_service
      AND routdet4-field  EQ gc_srv_name.
        l_hashcode = routdet4-bis.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode      = l_hashcode
            if_show_message = 'X'
          EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
        EXPORTING
          i_object        = routdet4-objct
          i_field         = routdet4-field
          i_value         = routdet4-bis
          if_show_message = 'X'.
*BOC UMITTAL D67K934963 13-Nov-2024 PN-6783
"Display Pop up for Non ABAP
      ELSE.
        CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
           titel         = 'Value From Key & Actual Value'
           txt1          = rs_selfield-value
           txt2          = ''.
        EXIT.
*EOC UMITTAL D67K934963 13-Nov-2024 PN-6783

      ENDIF."(++)UMITTAL D67K934963 13-Nov-2024 PN-6783
    WHEN 'PROFILE'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU02'.
      ELSE.
        SET PARAMETER ID 'XUP' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU02'.
      ENDIF.


    WHEN 'AGR_NAME' OR  'CHILD_AGR'.
      CLEAR g_agrname_dtlclk.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      agr_name = rs_selfield-value.
      CLEAR answer.
      DATA: "userresponse,
        l_installed   TYPE /psyng/bapiflagx,
        l_sysid       TYPE /psyng/system,
        l_rolid       TYPE /psyng/ex_rolhdr_st-rolid,
        ls_role_value TYPE /psyng/ex_rolid_value.

      IF routdet4-appl <> 'SAP' AND NOT routdet4-appl IS INITIAL.

* -- 2022/02/14 Odubey SE-EN
        l_rolid = agr_name.
        l_sysid = routdet4-rfcdest.
        CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
          EXPORTING
            i_rolid        = l_rolid
            i_appl         = routdet4-appl
            i_sysid        = l_sysid
          IMPORTING
            es_rolid_value = ls_role_value
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             SOURCE_ROLID_DOESNT_EXIST = 1
             NOT_AUTHORIZED_TO_DISPLAY = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        CLEAR answer.
        CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'      "#EC FB_OLDED
          EXPORTING
            defaultoption     = '1'
            diagnosetext1     = l_rolid
            diagnosetext2     = ls_role_value-key_val "text-058
            diagnosetext3     = ls_role_value-rdesc "text-058
            textline1         = text-058
            textline3         = text-219
            text_option1      = text-061
            text_option2      = text-036
            icon_text_option1 = 'ICON_CHECK'
            icon_text_option2 = 'ICON_SYSTEM_CANCEL'
            titel             = text-061
            cancel_display    = ''
          IMPORTING
            answer            = answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             OTHERS          = 1.
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        CASE answer.
          WHEN '1'.
            PERFORM role_sod_analysis_en_detail USING agr_name
                                                     routdet4-rfcdest
                                                     routdet4-appl
                                                     sodvrsio.
          WHEN '2'.
            EXIT.
        ENDCASE.
      ELSE.

*     Om 14.08.2018 adding Role Usase Matrix button if TA installed
        CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
          EXPORTING
            i_module    = 'TA'
          IMPORTING
            e_installed = l_installed.

        IF l_installed = 'X'.
          g_agrname_dtlclk = agr_name.
          CALL SCREEN 9005 STARTING AT 5 5
                             ENDING AT 85 16.

        ELSE.

          CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
            EXPORTING
              defaultoption     = '1'
              diagnosetext1     = agr_name
              diagnosetext2     = text-057
              diagnosetext3     = text-058
              textline1         = text-059
              text_option1      = text-060
              text_option2      = text-061
              icon_text_option1 = 'ICON_DISPLAY'
              icon_text_option2 = 'ICON_CHECK'
              titel             = text-062
              cancel_display    = 'X'
            IMPORTING
              answer            = answer.

          CASE answer.
            WHEN '1'.
              PERFORM display_role_in_pfcg USING agr_name.
            WHEN '2'.
              PERFORM role_sod_analysis_from_details USING agr_name
                                                       routdet4-rfcdest.
          ENDCASE.
        ENDIF. " ta Install endif
      ENDIF.

  ENDCASE.
  CLEAR : r_ucomm, sy-ucomm.
  EXIT.
ENDFORM.   "ROLE_DOUBLE_CLICK_ON_DETL
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report               = curr_report
      curr_variant              = variant
      vari_desc                 = vari_desc
    TABLES
      vari_contents             = irsparams
      vari_text                 = ivarit
    EXCEPTIONS
      illegal_report_or_variant = 1
      illegal_variantname       = 2
      not_authorized            = 3
      not_executed              = 4
      report_not_existent       = 5
      report_not_supplied       = 6
      variant_exists            = 7
      variant_locked            = 8
      OTHERS                    = 9.

  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    MESSAGE e208(00) WITH text-e03.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = text-069
        in_repvarnt = curr_variant
        in_report   = curr_report
      EXCEPTIONS
        OTHERS      = 1.
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
  DATA: tagr_define TYPE type_agr_define OCCURS 0 WITH HEADER LINE.
  DATA: ifield_dif LIKE field_dif OCCURS 0 WITH HEADER LINE.
  DATA: header(80), count TYPE i, count_char(9).

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH text-070.
    EXIT.
  ENDIF.
  REFRESH tagr_define.
  SELECT agr_name create_dat change_usr change_dat change_tim
             INTO CORRESPONDING FIELDS OF wa_iagr_define
             FROM agr_define
             WHERE agr_name IN role.
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

  DESCRIBE TABLE tagr_define LINES count.
  MOVE count TO count_char.
  CONCATENATE count_char text-134 INTO header
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
    EXPORTING
      header            = header
      tabname           = 'AGR_DEFINE'
      display_only      = 'X'
      endless           = 'X'
      display_toggle    = 'X'
      no_insert         = 'X'
      no_delete         = 'X'
      no_move           = 'X'
      no_undo           = 'X'
      no_button         = ' '
      x_end             = 90
    TABLES
      table             = tagr_define
      fielddif          = ifield_dif
    EXCEPTIONS
      no_more_tables    = 1
      too_many_fields   = 2
      nametab_not_valid = 3
      handle_not_valid  = 4
      OTHERS            = 5.
  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-e04.
  ENDIF.

ENDFORM.                    " show_roles_based_on_dates

*---------------------------------------------------------------------*
*       ROLE-TOP-OF-PAGE                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM role-top-of-page.                                      "#EC CALLED
                                                         "#EC FD_HYPHEN
  DATA: header      TYPE slis_t_listheader,
        wa          TYPE slis_listheader,
        exedate(10),
        lv_exetime(8) TYPE c,
        oldagr_name LIKE agr_define-agr_name,
        oldrfcdest  TYPE rfcdest,
        rolecount   TYPE i,
         l_str            TYPE string,
        l_int            TYPE i,
        ls_cfg_set       TYPE /psyng/swcfgset,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

  CLEAR: oldagr_name, rolecount, averagecon,
         alv_grid_titl, conflictcount.
  LOOP AT r1stoutput.
    IF r1stoutput-agr_name <> oldagr_name
       OR r1stoutput-rfcdest <> oldrfcdest.
      CHECK r1stoutput-conid <> '----'.
      rolecount = rolecount + 1.
      oldagr_name = r1stoutput-agr_name.
      oldrfcdest  = r1stoutput-rfcdest.
    ENDIF.
    CHECK r1stoutput-conid <> '----'.
    conflictcount = conflictcount + 1.
  ENDLOOP.
  averagecon   = conflictcount / rolecount.
  c_rolecount  = rolecount.
  c_averagecon = averagecon.
  c_trolecount = trolecount.
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
*--Version
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
* *--Date
  wa-typ = 'S'.
  wa-key = text-140.

  WRITE sy-datum TO exedate.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
            INTO lv_exetime SEPARATED BY ':'.

*  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
*              INTO exedate.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user"sy-uname C0700
  text-141 exedate lv_exetime text-236 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*NEXT LINE.
  wa-typ = 'S'.
  wa-key = text-142.
  wa-info = alv_grid_titl.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header
      i_logo             = 'Z_3SW_LOGO_JPG'.
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
      exelog = exelog.
  COMMIT WORK.


ENDFORM.                    " exelog

*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH irsparams.

*Parameters
  irsparams-selname = 'BYUSER'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = byuser.
  APPEND irsparams.

  irsparams-selname = 'BYUGRP'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = byugrp.
  APPEND irsparams.

  irsparams-selname = 'BYPA'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = bypa.
  APPEND irsparams.

  irsparams-selname = 'BYROLE'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = byrole.
  APPEND irsparams.

  irsparams-selname = 'RCHDATF'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = rchdatf.
  APPEND irsparams.

  irsparams-selname = 'RCHDATT'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = rchdatt.
  APPEND irsparams.

  irsparams-selname = 'BYSIMU'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = bysimu.
  APPEND irsparams.

  irsparams-selname = 'ROLERFC'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = rolerfc.
  APPEND irsparams.

  irsparams-selname = 'SHOSUM'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = shosum.
  APPEND irsparams.

  irsparams-selname = 'SHODET'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = shodet.
  APPEND irsparams.

  irsparams-selname = 'SHOWCOMP'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = showcomp.
  APPEND irsparams.

  irsparams-selname = 'VALIDUSR'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = validusr.
  APPEND irsparams.

  irsparams-selname = 'SHONOSOD'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = shonosod.
  APPEND irsparams.

  irsparams-selname = 'XMC'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = xmc.
  APPEND irsparams.

  irsparams-selname = 'VARNTNAM'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = varntnam.
  APPEND irsparams.

  irsparams-selname = 'USTB'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = ustb.
  APPEND irsparams.

  irsparams-selname = 'PCOLOR'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'. irsparams-low = pcolor.
  APPEND irsparams.

  irsparams-selname = 'RONLYREM'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = ronlyrem.
  APPEND irsparams.


*--Add new parameters for Origin filter
  irsparams-selname = 'P_CROSS'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = p_cross.
  APPEND irsparams.

  irsparams-selname = 'P_LOCAL'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = p_local.
  APPEND irsparams.

  irsparams-selname = 'P_REMOTE'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low  = p_remote.
  APPEND irsparams.

  irsparams-selname = 'P_LOCUSR'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low  = p_locusr.
  APPEND irsparams.



*Select options

  LOOP AT orglvl.
    irsparams-selname = 'ORGLVL'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING orglvl TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT pbname.
    irsparams-selname = 'PBNAME'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING pbname TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT xusrrfc.
    irsparams-selname = 'XUSRRFC'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING xusrrfc TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT pclass.
    irsparams-selname = 'PCLASS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING pclass TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT pwerks.
    irsparams-selname = 'PWERKS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING pwerks TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT role.
    irsparams-selname = 'ROLE'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING role TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT simurols.
    irsparams-selname = 'SIMUROLS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING simurols TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT spconfs.
    irsparams-selname = 'SPCONFS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING spconfs TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT sens.
    irsparams-selname = 'SENS'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING sens TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT xrolerfc.
    irsparams-selname = 'XROLERFC'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING xrolerfc TO irsparams.
    APPEND irsparams.
  ENDLOOP.


ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7)   TYPE n, oldnumber_c(7).

  CLEAR: variant, ivarit, vari_desc.
  REFRESH: ivarit, vari_desc.

  SELECT variant INTO variant FROM varid
                     WHERE report = sy-repid AND
                           variant LIKE '/PSYNG/%'
     ORDER BY variant DESCENDING..
    oldnumber = variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
  ENDIF.

  ivarit-langu = sy-langu.
  ivarit-report = sy-repid.
  ivarit-variant = variant.
  ivarit-vtext = text-146.
  APPEND ivarit.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.
ENDFORM.                    " get_next_variant_id
*---------------------------------------------------------------------*
*       FORM build_role_sort_order                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_role_sort_order USING type.
  CLEAR: l_sort, isort.
  REFRESH: isort.
  IF type = 'SUM'.
    l_sort-spos = '1'.
    l_sort-fieldname = 'RFCDEST'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '2'.
    l_sort-fieldname = 'AGR_NAME'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '3'.
    l_sort-fieldname = 'ISORT'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '4'.
    l_sort-fieldname = 'IMP'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '5'.
    l_sort-fieldname = 'CONID'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '6'.
    l_sort-fieldname = 'DESCRIPTION'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '7'.
    l_sort-fieldname = 'RISK'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
  ELSEIF type = 'DET'.
    l_sort-spos = '1'.
    l_sort-fieldname = 'RFCDEST'.
    l_sort-tabname = '1STOUTPUT'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '2'.
    l_sort-fieldname = 'AGR_NAME'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '3'.
    l_sort-fieldname = 'ISORT'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '4'.
    l_sort-fieldname = 'IMP'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '5'.
    l_sort-fieldname = 'CONID'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '6'.
    l_sort-fieldname = 'RISK'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '7'.
    l_sort-fieldname = 'FUNCTIONID'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '8'.
    l_sort-fieldname = 'RFCDEST'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '9'.
    l_sort-fieldname = 'TCODE'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '10'.
    l_sort-fieldname = 'OBJCT'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '11'.
    l_sort-fieldname = 'AUTH'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '12'.
    l_sort-fieldname = 'FIELD'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '13'.
    l_sort-fieldname = 'VON'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '14'.
    l_sort-fieldname = 'BIS'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '15'.
    l_sort-fieldname = 'CHILD_AGR'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '16'.
    l_sort-fieldname = 'DESCRIPTION'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '17'.
    l_sort-fieldname = 'APPL'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

*Role details with text
  ELSEIF type = 'TEXT'.
    l_sort-spos = '1'.
    l_sort-fieldname = 'RFCDEST'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '2'.
    l_sort-fieldname = 'AGR_NAME'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '4'.
    l_sort-fieldname = 'AGRDESC'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '5'.
    l_sort-fieldname = 'ISORT'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '6'.
    l_sort-fieldname = 'IMP'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '7'.
    l_sort-fieldname = 'CONID'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '8'.
    l_sort-fieldname = 'RISK'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '9'.
    l_sort-fieldname = 'FUNCTIONID'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '10'.
    l_sort-fieldname = 'FUNDESC'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '12'.
    l_sort-fieldname = 'TCODE'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '13'.
    l_sort-fieldname = 'TCODEDESC'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '14'.
    l_sort-fieldname = 'OBJCT'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '15'.
    l_sort-fieldname = 'OBJCTDESC'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

    l_sort-spos = '16'.
    l_sort-fieldname = 'AUTH'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '17'.
    l_sort-fieldname = 'FIELD'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '18'.
    l_sort-fieldname = 'VON'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '19'.
    l_sort-fieldname = 'BIS'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '20'.
    l_sort-fieldname = 'CHILD_AGR'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '21'.
    l_sort-fieldname = 'CHILD_AGR_DESC'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.
    l_sort-spos = '22'.
    l_sort-fieldname = 'DESCRIPTION'.
    l_sort-tabname = 'OUTPUTDET4'.
    l_sort-up = 'X'.
    APPEND l_sort TO isort.

  ENDIF.
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
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: swconfig  TYPE /psyng/swconfig,
        l_tabname TYPE dd02l-tabname,
        lt_tvarv  TYPE TABLE OF tvarv WITH HEADER LINE.

*Update Scan Table
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.
  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSEIF swconfig-value = 'N'.
    ustb = ' '.
  ENDIF.
  CLEAR swconfig.

*Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR swconfig.

*Show Mitigated Conflicts
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.
  IF swconfig-value = 'Y'.
    xmc = 'X'.
  ELSEIF swconfig-value = 'N'.
    xmc = ' '.
  ENDIF.
  CLEAR swconfig.

*Also show output for no SODs
  se_config_param 'DFLT_SHO_NO_SOD' swconfig-value.

  IF swconfig-value = 'Y'.
    shonosod = 'X'.
  ELSEIF swconfig-value = 'N'.
    shonosod = ' '.
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
  DATA : ls_fmname    TYPE rs38l_fnam.
  se_config_param 'SW_CENTRAL_USR_FM' ls_fmname.
  IF NOT ls_fmname IS INITIAL.
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
*--Check if ER is installed
  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'
                  AND as4vers  = '0000'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES'.
        screen-invisible = 0.
        screen-invisible = 1.
        screen-active   = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    se_config_param 'DFLT_INCLUDE_ER' swconfig-value.
    IF swconfig-value = 'Y'.
      erroles = 'X'.
    ELSE.
      erroles = ' '.
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
*           FROM (l_tabname)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'."#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO xusrrfc.
      xusrrfc-option = lt_tvarv-opti.
      APPEND xusrrfc.
    ENDLOOP.
  ENDIF.

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
FORM role_sod_analysis_from_details USING agr_name
                                           rfcdest .

  DATA l_rfcdest TYPE rfcdest.
*--Case 17382 - Correct RFC destination(if any) should be passed
  READ TABLE gt_rfcdest WITH KEY rfcoptions = rfcdest.
  IF sy-subrc = 0.
    l_rfcdest = gt_rfcdest-rfcdest.
  ELSE.
    CLEAR l_rfcdest.
  ENDIF.
  SUBMIT /psyng/sod_syswide_byrole
          WITH role      = agr_name
          WITH orgchk    = orgchk
          WITH p_enhanc  = p_enhanc
          WITH p_hienhn  = p_hienhn
          WITH sodvrsio  = sodvrsio
          WITH cfgset    = cfgset
          WITH remrfc    = l_rfcdest
          WITH ronlyrem  = ronlyrem
          AND RETURN.
ENDFORM.                    " role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*&      Form  display_role_in_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_role_in_pfcg USING agr_name LIKE agr_define-agr_name.
  DATA: answer,
        l_repid LIKE sy-repid.


  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-147
      diagnosetext2     = text-064
      diagnosetext3     = text-130
      textline1         = text-075
      text_option1      = text-131
      text_option2      = text-132
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-075
      cancel_display    = 'X'
    IMPORTING
      answer            = answer.

  CASE answer.
    WHEN '1'.

   CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
*           STARTING NEW TASK 'PFCG'
     EXPORTING
       agr_name      = agr_name
     EXCEPTIONS
       agr_not_found = 1
       OTHERS        = 2.
      IF sy-subrc <> 0.
        IF sy-subrc = 1.
          CLEAR pertext.
          CONCATENATE text-076 text-188
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-077 text-188 text-078
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ENDIF.
    WHEN '2'.
      DATA: userresponse, dflt_rfc LIKE /psyng/swconfig-value.

      CLEAR: ifields.
      REFRESH: ifields.

      se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
      IF ifields[] IS INITIAL.
        ifields-tabname = 'RFCDES'.
        ifields-fieldname = 'RFCDEST'.
        ifields-fieldtext = text-090.
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
          popup_title       = text-066
          ok_pushbuttontext = text-127
        IMPORTING
          returncode        = userresponse
        TABLES
          fields            = ifields
        EXCEPTIONS
          error_in_fields   = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH text-067.
      ENDIF.

      CHECK userresponse NE 'A'."#EC SAST_CI_GEN_CHECK
        "check to see user doesn't abort

      READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                  fieldname = 'RFCDEST'.

      IF ifields-value IS INITIAL.
        MESSAGE w208(00) WITH text-068.
      ENDIF.
      SELECT SINGLE * FROM rfcdes WHERE rfcdest = ifields-value AND
                                        rfctype = '3'.
      IF sy-subrc EQ 0.
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
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
            agr_name      = agr_name
          EXCEPTIONS
            SYSTEM_FAILURE        = 1
            COMMUNICATION_FAILURE = 2
            agr_not_found         = 3
            OTHERS                = 4. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up

        IF sy-subrc EQ 1.
           MESSAGE i002(/psyng/sw) WITH 'System failure'(z02).
        ELSEIF sy-subrc = 2.
           MESSAGE i002(/psyng/sw) WITH 'Communication failure'(z01).
        ELSEIF sy-subrc = 3.
*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          CLEAR pertext.
          CONCATENATE text-076 ifields-value
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 4.
          CONCATENATE text-077 ifields-value text-078
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ELSE.
        CLEAR pertext.
        CONCATENATE text-090 ifields-value text-133
                                 INTO pertext SEPARATED BY space.
        MESSAGE i208(00) WITH pertext.
      ENDIF.

    WHEN OTHERS.

  ENDCASE.

ENDFORM.                    " display_role_in_pfcg
*&---------------------------------------------------------------------*
*&      Form  get_history_months
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_history_months USING fstmon lastmon.
  DATA: fstmonth TYPE sy-datum, lastmont TYPE sy-datum.
  DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
        WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
    TABLES
      idirectory = idirectory.

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF fstmonth IS INITIAL OR fstmonth > idirectory-startdate.
      fstmonth = idirectory-startdate.
    ENDIF.
    IF lastmont < idirectory-startdate.
      lastmont = idirectory-startdate.
    ENDIF.
  ENDLOOP.

  CONCATENATE fstmonth+4(2) '/' fstmonth(4) INTO fstmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.
ENDFORM.                    " get_history_months

*&---------------------------------------------------------------------*
*&      Form  advise_syswide_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM advise_syswide_analysis CHANGING continue.
  DATA: lt_decidetext   TYPE TABLE OF tline WITH HEADER LINE,
        lt_decidehtml   TYPE TABLE OF htmlline WITH HEADER LINE,
        l_head          TYPE thead,
        lt_parmvalues   TYPE TABLE OF parmvalues,
        ls_paramvalue   TYPE parmvalues,
        l_max_runtime   TYPE wpelzeit,
        l_runtime_param TYPE i.
*  DATA:  lt_seltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  FIELD-SYMBOLS : <line> TYPE tline.


*don't show popup in batch mode
  IF  NOT sy-batch IS INITIAL OR NOT sy-binpt IS INITIAL.
    continue = 'X'.
  ELSE.
*--Get max time for workprocess
    ls_paramvalue-param_name = 'rdisp/max_wprun_time'.
    APPEND ls_paramvalue TO lt_parmvalues.
    CALL FUNCTION 'PFL_GET_PARAMETER'
      TABLES
        parameter_table = lt_parmvalues
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             AUTHORIZATION_MISSING   = 1
             OTHERS          = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    READ TABLE lt_parmvalues INDEX 1 INTO ls_paramvalue.
    IF ls_paramvalue-user_value CS 'H' OR
      ls_paramvalue-user_value CS 'M'.
*--Later versions of SAP allow H for hours and M for minutes
*  in this parameter
      IF ls_paramvalue-user_value CS 'H'.
        SEARCH ls_paramvalue-user_value FOR 'H'.
        l_runtime_param = ls_paramvalue-user_value(sy-fdpos).
        l_max_runtime = l_runtime_param * 3600.
      ELSE.
        SEARCH ls_paramvalue-user_value FOR 'M'.
        l_runtime_param = ls_paramvalue-user_value(sy-fdpos).
        l_max_runtime = l_runtime_param * 60.
      ENDIF.
    ELSE.
      l_max_runtime    = ls_paramvalue-user_value.
    ENDIF.


*--Get text
    CALL FUNCTION 'DOC_OBJECT_GET'
      EXPORTING
        class            = 'TX'
        name             = '/PSYNG/SW_I000001'
        appendix         = 'X'
      IMPORTING
        header           = l_head
      TABLES
        itf_lines        = lt_decidetext
      EXCEPTIONS
        object_not_found = 1
        OTHERS           = 2.
    IF sy-subrc <> 0.
      IF sy-langu <> 'E'.
*       Try in English
        CALL FUNCTION 'DOC_OBJECT_GET'
          EXPORTING
            class            = 'TX'
            name             = '/PSYNG/SW_I000001'
            language         = 'E'
            appendix         = 'X'
          IMPORTING
            header           = l_head
          TABLES
            itf_lines        = lt_decidetext
          EXCEPTIONS
            object_not_found = 1
            OTHERS           = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
      ENDIF.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    ENDIF.
*--replace placeholders
*[rdisp/max_wprun_time]
    LOOP AT lt_decidetext ASSIGNING <line>.
      REPLACE '[rdisp/max_wprun_time]'  WITH l_max_runtime
                                        INTO <line>-tdline.
    ENDLOOP.
*--convert to html
    CALL FUNCTION 'CONVERT_ITF_TO_HTML'
      EXPORTING
*       I_CODEPAGE     =
        i_header       = l_head
        i_bgcolor      = '#FEFEEE'
      TABLES
        t_itf_text     = lt_decidetext
        t_html_text    = lt_decidehtml
      EXCEPTIONS
        syntax_check   = 1
        replace        = 2
        illegal_header = 3
        OTHERS         = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    REFRESH i_text.
    LOOP AT lt_decidehtml.
      i_text = lt_decidehtml-tdline.
      APPEND i_text.
    ENDLOOP.

    CALL SCREEN 400 STARTING AT 2 2.




    IF sy-ucomm <> 'NO'. "continue
      continue = 'X'.
    ELSE. "sys wide or cancel
      CLEAR continue.
      EXIT.
    ENDIF.
  ENDIF.

ENDFORM.                    " advise_syswide_analysis

*----------------------------------------------------------------------*
* Start forms for Tree format
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  set_pf_status
*&---------------------------------------------------------------------*
*     Add tree button to alv toolbar of alv list output
*----------------------------------------------------------------------*
FORM set_pf_status USING rt_extab TYPE slis_t_extab.
  DATA : lt_extab TYPE slis_t_extab,
         ls_extab LIKE LINE OF lt_extab.

  IF NOT gf_cfg_set_enabled = 'X'.
*--Toggline org and variable elements is only available
*  if configuration set functionality is enabled
    ls_extab-fcode = 'TOGGLE_ORG'.
    APPEND ls_extab TO lt_extab.
    APPEND ls_extab TO rt_extab.

  ENDIF.
  IF byrole = 'X'.
    lt_extab[] = rt_extab[].
    ls_extab-fcode = 'SOD_TREE'.
    APPEND ls_extab TO lt_extab.
*  hide "Proposed Remediation" button and Historical usage
    ls_extab-fcode = 'EASY'.
    APPEND ls_extab TO lt_extab.
    ls_extab-fcode = 'HIST'.
    APPEND ls_extab TO lt_extab.
**  Hide Simplified View
    ls_extab-fcode = 'SIMP'.
    APPEND ls_extab TO lt_extab.
    SET PF-STATUS 'SOD_TREE' EXCLUDING lt_extab.


  ELSE.
  ENDIF.
ENDFORM. "SET_PF_STATUS




*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_9005 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_9005 INPUT.
  DATA: l_sod   TYPE /psyng/swsodvers-vrsio,
        l_uname LIKE sy-uname,
        l_parva TYPE usr05-parva.

  CLEAR: l_sod, l_uname, l_parva.
  CASE sy-ucomm.
    WHEN '1'.
      l_uname = g_current_user."sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.
*      SUBMIT /psyng/bc_role_matrix VIA SELECTION-SCREEN
*                   WITH vrsio = l_sod
*                   WITH role = g_agrname_dtlclk
*                   AND RETURN.
* Replace with a NEW report.
*SE: C0639, Improve selection screen Users & Roles vs. Matrix
      SUBMIT /psyng/sw_roles_matrix VIA SELECTION-SCREEN
                WITH vrsio = l_sod
                WITH roles = g_agrname_dtlclk
                AND RETURN.

    WHEN '2'.
      PERFORM display_role_in_pfcg USING g_agrname_dtlclk.

    WHEN '3'.
      PERFORM role_sod_analysis_from_details USING
                  g_agrname_dtlclk
                                 routdet4-rfcdest.
    WHEN '4'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.

  ENDCASE.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Form  output_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ENH_CON  text
*----------------------------------------------------------------------*
FORM output_roles TABLES   it_outputdet STRUCTURE /psyng/sw_out_routdet3
      it_enh_con STRUCTURE /psyng/sw_enh_usr_con.           "#EC NEEDED
  DATA: BEGIN OF lt_enh_con OCCURS 0,
          agr_name TYPE agr_name,
          conid    TYPE /psyng/conflict-conid,
        END OF lt_enh_con,
        ls_variant TYPE disvariant,
        l_tcd      TYPE tcode.
*        ls_line_count TYPE i.
  LOOP AT it_outputdet.

*-- Change to EN tcodes length 40 chars

    MOVE-CORRESPONDING it_outputdet TO routdet3.
    IF p_nabap = 'X'.
      l_tcd = routdet3-tcode.
      READ TABLE gt_map_tcode_screen WITH KEY tcode = l_tcd .
      IF sy-subrc = 0.
        CLEAR l_tcode.
        l_tcode = gt_map_tcode_screen-usrrt.
      ENDIF.
      IF routdet3-appl <> 'SAP'.
        routdet3-tcode = l_tcode.
      ENDIF.

    ENDIF.

    APPEND routdet3.
    IF routdet3-enhanced = 'X'.
      lt_enh_con-agr_name = routdet3-agr_name.
      lt_enh_con-conid    = routdet3-conid.
      COLLECT lt_enh_con.
    ENDIF.
    IF routdet3-simu = 'X'.
      simuagrs-agr_name = routdet3-agr_name.
      COLLECT simuagrs.
    ENDIF.

  ENDLOOP.
  SORT routdet3.
  LOOP AT routdet3.
    CLEAR r1stoutput.
    r1stoutput-agr_name    = routdet3-agr_name.
    r1stoutput-conid       = routdet3-conid.
    r1stoutput-description = routdet3-description.
    r1stoutput-risk        = routdet3-risk.
    r1stoutput-imp         = routdet3-imp.
    r1stoutput-rfcdest     = routdet3-rfcdest.
    r1stoutput-appl        = routdet3-appl.


    IF bysimu = 'X'.
      IF routdet3-simu = 'X'.
        r1stoutput-simu = 'X'.
      ENDIF.
    ENDIF.
    IF p_hienhn = 'X'.

      IF routdet3-enhanced = 'X'.
        DELETE routdet3-color_cell
               WHERE fname = 'CONID' OR fname = 'TCODE'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'CONID'.
        APPEND cc TO routdet3-color_cell.
        r1stoutput-color_cell[] =  routdet3-color_cell[].
        cc-fname  = 'TCODE'.
        APPEND cc TO routdet3-color_cell.
        MODIFY routdet3 TRANSPORTING color_cell enhanced.



      ENDIF.
    ENDIF.
    APPEND r1stoutput.

  ENDLOOP.
*--Sort by simu descending so record with simu flag is not deleted
  SORT r1stoutput BY
  rfcdest agr_name conid ASCENDING
  simu DESCENDING enhanced DESCENDING.




  DELETE ADJACENT DUPLICATES FROM r1stoutput
  COMPARING rfcdest agr_name conid.





*Higlighting of conflicts
  LOOP AT r1stoutput.
    CASE r1stoutput-imp.
      WHEN 'HIGH'.
        r1stoutput-isort = '1'.
        color-col = '6'.   "Red
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO r1stoutput-color_cell.
      WHEN 'MEDIUM'.
        r1stoutput-isort = '2'.
        color-col = '6'.   "Red
        color-int = '0'.   "Un-Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO r1stoutput-color_cell.
      WHEN 'LOW'.
        r1stoutput-isort = '3'.
        color-col = '3'.   "Yellow
        color-int = '0'.   "Un-Intensified
        color-inv = '0'.   "Inverse
        cc-fname = 'IMP'.
        cc-color = color.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'CONID'.
        APPEND cc TO r1stoutput-color_cell.
        cc-fname = 'DESCRIPTION'.
        APPEND cc TO r1stoutput-color_cell.
    ENDCASE.
    IF pcolor <> 'X'.   "if user doesn't want to see the conflicts
      CLEAR r1stoutput-color_line.   "highlighted in colors
      CLEAR r1stoutput-color_cell.
    ENDIF.
*   Highlight conflicts in enhanced ruleset
    IF p_hienhn = 'X' AND shosum = 'X'.
      READ TABLE lt_enh_con WITH KEY agr_name = r1stoutput-agr_name
                                     conid = r1stoutput-conid
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        r1stoutput-enhanced = 'X'.
        DELETE r1stoutput-color_cell WHERE fname = 'CONID'.
        color-col = '7'.   "Orange
        color-int = '1'.   "Intensified
        color-inv = '0'.   "Inverse
        cc-color  = color.
        cc-fname  = 'CONID'.
        APPEND cc TO r1stoutput-color_cell.
      ENDIF.
    ENDIF.

    MODIFY r1stoutput.
  ENDLOOP.
*END dho 09/30/2008 - Higlighting of conflicts


*--Case 2186 : REUSE_ALV FM's need to have this set when called in
* background and submitted from a different report in order to show
* spool output.
  DATA : ls_print TYPE slis_print_alv.
  IF NOT sy-batch IS INITIAL.
    ls_print-print = 'X'.
  ENDIF.



  MESSAGE s208(00) WITH text-083.

*build ALV catalog
  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  IF shosum = 'X'.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = program
        i_internal_tabname = 'R1STOUTPUT'
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
*delete the color columns
    DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_LINE'.
    DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_CELL'.
*no key fields
    wa_fieldcat_alv-key = ' '.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        key
                     WHERE
                        fieldname NE space.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

    IF p_enhanc = 'X'.
*  if highlight enhanced ruleset is selected, add this field to the
      wa_fieldcat_alv-seltext_l      = text-157.
      wa_fieldcat_alv-seltext_m      = text-158.
      wa_fieldcat_alv-seltext_s      = text-158.
      wa_fieldcat_alv-reptext_ddic   = text-217.
      wa_fieldcat_alv-checkbox       = 'X'.
      wa_fieldcat_alv-just      = 'X'.
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
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
    IF bysimu = 'X'.
      wa_fieldcat_alv-seltext_l = text-115.
      wa_fieldcat_alv-seltext_m = text-115.
      wa_fieldcat_alv-seltext_s = text-116.
      wa_fieldcat_alv-reptext_ddic = text-115.
      wa_fieldcat_alv-checkbox     = 'X'.
      wa_fieldcat_alv-just     = 'X'.
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
    ELSE.
      DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
    ENDIF.


    IF NOT xrolerfc[] IS INITIAL.
      CLEAR wa_fieldcat_alv-no_out.
    ELSE.
      wa_fieldcat_alv-no_out = 'X'.
    ENDIF.
    wa_fieldcat_alv-seltext_l = text-218.
    wa_fieldcat_alv-seltext_m = text-218.
    wa_fieldcat_alv-seltext_s = text-103.
    wa_fieldcat_alv-reptext_ddic = text-218.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        no_out
                     WHERE
                        fieldname = 'RFCDEST'.


    PERFORM build_role_sort_order  USING 'SUM'.
    MOVE text-037 TO alv_grid_titl.
*----------------------------------------------------------------------*
***** REPEAT_HDR_BKGDJOB Flag Check
*----------------------------------------------------------------------*
*    IF gf_prevent_hdr = 'X'.
*      DESCRIBE TABLE 1stoutput LINES ls_line_count.
*      PERFORM set_print_param USING ls_line_count.
*    ENDIF.
*----------------------------------------------------------------------*
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
*       i_grid_title            = alv_grid_titl
        i_callback_top_of_page  = 'ROLE-TOP-OF-PAGE'
        it_sort                 = isort
        i_callback_program      = program
        i_callback_user_command = 'ROLE_DOUBLE_CLICK_ON_SUMRY'
        is_layout               = alv_layout
        it_fieldcat             = i_fieldcat_alv
        i_save                  = 'A'
        is_variant              = ls_variant
        is_print                = ls_print
      TABLES
        t_outtab                = r1stoutput
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  ELSEIF shodet = 'X'.

*check to see if the customer wants to see the output details in ALV
*format or standard list
    se_config_param 'SW_SOD_REPO_DETAIL' wa_swconfig-value.
    IF wa_swconfig-value = 'LIST'.
*     Since a customer doesn't have the latest support packs for
*     ALV output we have to print info in standard list format
      MESSAGE i030 WITH 'SW_SOD_REPO_DETAIL'.
    ENDIF.

    routdet4[] = routdet3[].   "better to move to #4 for
    REFRESH routdet3.            "double clicking in ALV
    SORT routdet4 BY agr_name conid functionid tcode
                     objct auth org_abb child_agr.
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = program
        i_internal_tabname = 'ROUTDET4'
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
    PERFORM adjust_role_details_fcat.
    PERFORM build_role_sort_order  USING 'DET'.

*--If Configuration set functionality is enabled,
* prepare info for toggling variable and org values.
    PERFORM toggle_alv_role_init.

    MOVE text-038 TO alv_grid_titl.
    IF sy-batch IS INITIAL.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_grid_title             = alv_grid_titl
          it_sort                  = isort
          i_callback_program       = program
          i_callback_top_of_page   = 'ROLE-TOP-OF-PAGE'
          i_callback_user_command  = 'ROLE_DOUBLE_CLICK_ON_DETL'
          i_callback_pf_status_set = 'SET_PF_STATUS'
          is_layout                = alv_layout
          it_fieldcat              = i_fieldcat_alv
          it_filter                = gt_filter_role_detail
          i_save                   = 'A'
          is_variant               = ls_variant
          is_print                 = ls_print
        TABLES
          t_outtab                 = routdet4
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    ELSE.
*----------------------------------------------------------------------*
***** REPEAT_HDR_BKGDJOB Flag Check
*----------------------------------------------------------------------*
*      IF gf_prevent_hdr = 'X'.
*        DESCRIBE TABLE 1stoutput LINES ls_line_count.
*        PERFORM set_print_param USING ls_line_count.
*      ENDIF.
*----------------------------------------------------------------------*
      CALL FUNCTION 'REUSE_ALV_LIST_DISPLAY'
        EXPORTING
*         I_INTERFACE_CHECK              = ' '
*         I_BYPASSING_BUFFER             =
*         I_BUFFER_ACTIVE                = ' '
*         I_CALLBACK_PROGRAM             = ' '
*         I_CALLBACK_PF_STATUS_SET       = ' '
*         I_CALLBACK_USER_COMMAND        = ' '
*         I_STRUCTURE_NAME               =
          is_layout     = alv_layout
          it_fieldcat   = i_fieldcat_alv
*         IT_EXCLUDING  =
*         IT_SPECIAL_GROUPS              =
*         IT_SORT       =
*         IT_FILTER     =
*         IS_SEL_HIDE   =
*         I_DEFAULT     = 'X'
*         I_SAVE        = ' '
*         IS_VARIANT    =
*         IT_EVENTS     =
*         IT_EVENT_EXIT =
          is_print      = ls_print
*         IS_REPREP_ID  =
*         I_SCREEN_START_COLUMN          = 0
*         I_SCREEN_START_LINE            = 0
*         I_SCREEN_END_COLUMN            = 0
*         I_SCREEN_END_LINE              = 0
*     IMPORTING
*         E_EXIT_CAUSED_BY_CALLER        =
*         ES_EXIT_CAUSED_BY_USER         =
        TABLES
          t_outtab      = routdet4
        EXCEPTIONS
          program_error = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
        MESSAGE e002 WITH 'Error Displaying ALV Grid'(e07) '' '' ''.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.                    " output_roles



FORM output_role_details_with_texts.
  DATA: ls_variant TYPE disvariant.
*--Tables for the unique names
  DATA : lt_agr_names  TYPE TABLE OF agr_texts WITH HEADER LINE,
         lt_obj_names  TYPE TABLE OF tobjt WITH HEADER LINE,
         lt_tcode      TYPE TABLE OF tstct WITH HEADER LINE,
         lt_func_names TYPE TABLE OF /psyng/function WITH HEADER LINE.
*--Tables for the texts
  DATA : lt_agr_texts  TYPE SORTED TABLE OF agr_texts
                                    WITH UNIQUE KEY agr_name
                                    WITH HEADER LINE,
         lt_obj_texts  TYPE TABLE OF tobjt WITH HEADER LINE,
         lt_func_texts TYPE TABLE OF /psyng/function WITH HEADER LINE.
  DATA: BEGIN OF lt_screen_texts OCCURS 0,
          usrrt TYPE /psyng/user_right,
          udesc TYPE /psyng/user_right_desc,
          sysid TYPE /psyng/ex_caobj_lock-sysid,
          appl  TYPE /psyng/ex_caobj_lock-appl,
        END OF lt_screen_texts.
  DATA: BEGIN OF lt_tcode_texts OCCURS 0,
          tcode TYPE tstct-tcode,
          ttext TYPE /psyng/user_right_desc, "tstct-ttext,
          sysid TYPE /psyng/ex_caobj_lock-sysid,
          appl  TYPE /psyng/ex_caobj_lock-appl,
        END OF lt_tcode_texts.


  DATA: BEGIN OF lt_screen OCCURS 0,
          usrrt TYPE /psyng/user_right,
          appl  TYPE /psyng/ex_caobj_lock-appl,
          sysid TYPE /psyng/ex_caobj_lock-sysid,
        END OF lt_screen.
  DATA: "ls_line_count TYPE i,
    l_table_en(20)      TYPE c,
    l_fm_read_roles(32) VALUE '/PSYNG/SW_CR_READ_ROLES_EN',
    ls_rolehdr          TYPE  /psyng/ex_rolhdr_st,
    ls_rolid            TYPE /psyng/ex_rolhdr_st.
  DATA: lt_functtran_src TYPE TABLE OF ty_functtran,
        lt_functtran     TYPE TABLE OF ty_functtran,
        ls_functtran     TYPE ty_functtran,
        lt_fioria        TYPE TABLE OF ty_fioria,
        ls_fioria        TYPE ty_fioria.
  FIELD-SYMBOLS: <fs_functtran> TYPE ty_functtran.
*--Move to output table with texts and collect unique names
  FREE : r_output_det_text.
  LOOP AT routdet4.
    MOVE-CORRESPONDING routdet4 TO r_output_det_text.
    IF routdet4-appl = 'SAP' OR p_nabap IS INITIAL.
      lt_agr_names-agr_name = r_output_det_text-agr_name.
      COLLECT lt_agr_names.
    ELSE.
      ls_rolehdr-rolid = r_output_det_text-agr_name.
      ls_rolehdr-appl = r_output_det_text-appl.
      ls_rolehdr-sysid = r_output_det_text-rfcdest.

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

      r_output_det_text-agrdesc = ls_rolid-rdesc.
      CLEAR ls_rolid.

    ENDIF.
    lt_agr_names-agr_name = r_output_det_text-child_agr.
    COLLECT lt_agr_names.

    lt_obj_names-object = r_output_det_text-objct.
    COLLECT lt_obj_names.

    IF routdet4-auth IS INITIAL.
      lt_screen-appl = r_output_det_text-appl.
      lt_screen-sysid = r_output_det_text-rfcdest.
      lt_screen-usrrt = r_output_det_text-tcode.
      COLLECT lt_screen.
    ELSE.
      lt_tcode-tcode = r_output_det_text-tcode.
      COLLECT lt_tcode.
      ls_functtran-functionid = r_output_det_text-functionid.
      ls_functtran-tcode      = r_output_det_text-tcode.
      COLLECT ls_functtran INTO lt_functtran_src.
      CLEAR ls_functtran.
    ENDIF.
    lt_func_names-function = r_output_det_text-functionid.
    COLLECT lt_func_names.

    APPEND r_output_det_text.
  ENDLOOP.
*--gather all texts
  IF NOT lt_agr_names[] IS INITIAL.
    SELECT agr_name text FROM agr_texts
    INTO CORRESPONDING FIELDS OF TABLE lt_agr_texts
    FOR ALL ENTRIES IN lt_agr_names
    WHERE
    spras = sy-langu AND
    line  = 0 AND
    agr_name = lt_agr_names-agr_name.
    SORT lt_agr_names BY agr_name.
*-- if not all roles names found locally, search in remote systems
    LOOP AT lt_agr_names WHERE agr_name <> ''.
      READ TABLE lt_agr_texts WITH TABLE KEY
        agr_name = lt_agr_names-agr_name
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        CLEAR lt_agr_texts.
        lt_agr_texts-agr_name = lt_agr_names-agr_name.
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
          CALL FUNCTION '/PSYNG/BC_021'
            DESTINATION gt_rfcdest-rfcdest
            EXPORTING
              i_agr_name            = lt_agr_names-agr_name
            IMPORTING
              e_text                = lt_agr_texts-text
            EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc = 0.
            IF NOT   lt_agr_texts-text IS INITIAL.
              INSERT TABLE lt_agr_texts.
              EXIT.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
*if there are roles for which we don't find text in logon language,
*use EN
    LOOP AT lt_agr_names WHERE agr_name <> ''.
      READ TABLE lt_agr_texts WITH TABLE KEY
      agr_name = lt_agr_names-agr_name
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        SELECT agr_name text FROM agr_texts
        APPENDING CORRESPONDING FIELDS OF TABLE lt_agr_texts
        WHERE
        spras    = 'EN' AND
        line     = 0 AND
        agr_name = lt_agr_names-agr_name.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF NOT lt_obj_names[] IS INITIAL.
    SELECT object ttext FROM tobjt
    INTO CORRESPONDING FIELDS OF TABLE  lt_obj_texts
    FOR ALL ENTRIES IN lt_obj_names
    WHERE
    langu = sy-langu AND
    object = lt_obj_names-object.
  ENDIF.
  IF NOT lt_tcode[] IS INITIAL.
    SELECT tcode ttext FROM tstct
    INTO CORRESPONDING FIELDS OF TABLE lt_tcode_texts
    FOR ALL ENTRIES IN lt_tcode
    WHERE
    sprsl = sy-langu AND
    tcode = lt_tcode-tcode.
  ENDIF.
*--Get descriptions of fioriids; if any
  IF NOT lt_functtran_src IS INITIAL.
    SELECT functionid tcode fioriid
      FROM /psyng/functtran
      INTO TABLE lt_functtran
      FOR ALL ENTRIES IN lt_functtran_src
      WHERE functionid EQ lt_functtran_src-functionid
        AND tcode      EQ lt_functtran_src-tcode
        AND vrsio      EQ sodvrsio
        AND type       EQ 'F'.
    IF sy-subrc EQ 0
    AND NOT lt_functtran IS INITIAL.
      SELECT fioriid appname
        FROM /psyng/sw_fioria
        INTO TABLE lt_fioria
        FOR ALL ENTRIES IN lt_functtran
        WHERE fioriid EQ lt_functtran-fioriid.
      IF sy-subrc EQ 0.
        SORT lt_fioria BY fioriid.
        LOOP AT lt_functtran ASSIGNING <fs_functtran>.
          READ TABLE lt_fioria INTO ls_fioria
            WITH KEY fioriid = <fs_functtran>-fioriid
            BINARY SEARCH.
          IF sy-subrc EQ 0.
            <fs_functtran>-appname = ls_fioria-appname.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.
  IF p_nabap = 'X'. "Add screen id description
    IF NOT lt_screen[] IS INITIAL.
      l_table_en = '/PSYNG/EX_URHDR'.
SELECT usrrt udesc sysid appl FROM (l_table_en)
"#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
      INTO TABLE lt_screen_texts
      FOR ALL ENTRIES IN lt_screen
      WHERE usrrt = lt_screen-usrrt
            AND appl = lt_screen-appl
             AND
              (
                ( sysid = lt_screen-sysid AND sysdep = 'X' )
                OR
                ( sysid = 'ALL' AND sysdep <> 'X' )
              ).

      LOOP AT lt_screen_texts.
        lt_tcode_texts-tcode = lt_screen_texts-usrrt.
        lt_tcode_texts-ttext = lt_screen_texts-udesc.
        lt_tcode_texts-sysid = lt_screen_texts-sysid.
        lt_tcode_texts-appl = lt_screen_texts-appl.
        APPEND lt_tcode_texts.
      ENDLOOP.
    ENDIF.
  ENDIF.

  IF NOT lt_func_names[] IS INITIAL.
    SELECT function description FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE lt_func_texts
    FOR ALL ENTRIES IN lt_func_names
    WHERE
    function = lt_func_names-function AND
    vrsio    = sodvrsio.
  ENDIF.
*--Put texts in output table
  FIELD-SYMBOLS : <out> LIKE r_output_det_text.
  LOOP AT lt_agr_texts.
*--Role texts
    LOOP AT r_output_det_text ASSIGNING <out>
    WHERE agr_name = lt_agr_texts-agr_name.
      <out>-agrdesc = lt_agr_texts-text.
    ENDLOOP.
*--Child role texts
    LOOP AT r_output_det_text ASSIGNING <out>
      WHERE child_agr = lt_agr_texts-agr_name.
      <out>-child_agr_desc = lt_agr_texts-text.
    ENDLOOP.
  ENDLOOP.

  LOOP AT lt_obj_texts.
    LOOP AT r_output_det_text ASSIGNING <out>
    WHERE objct = lt_obj_texts-object.
      <out>-objctdesc = lt_obj_texts-ttext.
    ENDLOOP.
  ENDLOOP.
  LOOP AT lt_tcode_texts.
    IF NOT lt_tcode_texts-sysid IS INITIAL AND
       NOT lt_tcode_texts-sysid = 'ALL'.
      LOOP AT r_output_det_text ASSIGNING <out>
      WHERE tcode = lt_tcode_texts-tcode
        AND ( rfcdest = lt_tcode_texts-sysid  )
        AND appl = lt_tcode_texts-appl.
        <out>-tcodedesc = lt_tcode_texts-ttext.
      ENDLOOP.

    ELSE.
      LOOP AT r_output_det_text ASSIGNING <out>
      WHERE tcode = lt_tcode_texts-tcode.
        <out>-tcodedesc = lt_tcode_texts-ttext.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  LOOP AT lt_functtran INTO ls_functtran.
    LOOP AT r_output_det_text ASSIGNING <out>
    WHERE functionid = ls_functtran-functionid
      AND tcode      = ls_functtran-tcode.
      <out>-tcodedesc = ls_functtran-appname.
    ENDLOOP.
  ENDLOOP.

  LOOP AT lt_func_texts.
    LOOP AT r_output_det_text ASSIGNING <out>
    WHERE functionid = lt_func_texts-function.
      <out>-fundesc = lt_func_texts-description.
    ENDLOOP.
  ENDLOOP.


*--prepare Field Catalog
  program = sy-repid.
  FREE : i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'R_OUTPUT_DET_TEXT'
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
  PERFORM adjust_role_details_fcat.
  PERFORM build_role_sort_order  USING 'TEXT'.
  SORT r_output_det_text BY agr_name conid functionid tcode
                     objct auth field von bis  .

  PERFORM adjust_columns_for_role_text.
*----------------------------------------------------------------------*
***** REPEAT_HDR_BKGDJOB Flag Check
*----------------------------------------------------------------------*
*  IF gf_prevent_hdr = 'X'.
*    DESCRIBE TABLE 1stoutput LINES ls_line_count.
*    PERFORM set_print_param USING ls_line_count.
*  ENDIF.
*----------------------------------------------------------------------*
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page  = 'ROLE-TOP-OF-PAGE' "AKUMAR PN4449
      i_callback_program       = program
      it_sort                  = isort
      i_callback_user_command  = 'ROLE_DOUBLE_CLICK_ON_DETL'
      i_callback_pf_status_set = 'SET_PF_STATUS'
      is_layout                = alv_layout
      it_fieldcat              = i_fieldcat_alv
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = r_output_det_text
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
*       MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " output_role_details_with_texts
*&---------------------------------------------------------------------*
*&      Form  adjust_role_details_fcat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM adjust_role_details_fcat.
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
                      fieldname = 'PROFILE'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CHILD_AGR'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'AGR_NAME'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FUNCTIONID'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'OBJCT'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FIELD'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'VON'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'BIS'.

  wa_fieldcat_alv-seltext_l = text-099.
  wa_fieldcat_alv-seltext_m = text-099.
  wa_fieldcat_alv-seltext_s = text-216.
  wa_fieldcat_alv-reptext_ddic = text-099.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CHILD_AGR'.
  wa_fieldcat_alv-seltext_l = text-217.
  wa_fieldcat_alv-seltext_m = text-093.
  wa_fieldcat_alv-seltext_s = text-093.
  wa_fieldcat_alv-reptext_ddic = text-217.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FIELD'.
  wa_fieldcat_alv-seltext_l = text-218.
  wa_fieldcat_alv-seltext_m = text-218.
  wa_fieldcat_alv-seltext_s = text-103.
  wa_fieldcat_alv-reptext_ddic = text-218.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.
  wa_fieldcat_alv-seltext_l = text-104.
  wa_fieldcat_alv-seltext_m = text-105.
  wa_fieldcat_alv-seltext_s = text-105.
  wa_fieldcat_alv-reptext_ddic = text-104.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'VON'.
  wa_fieldcat_alv-seltext_l = text-106.
  wa_fieldcat_alv-seltext_m = text-107.
  wa_fieldcat_alv-seltext_s = text-107.
  wa_fieldcat_alv-reptext_ddic = text-106.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BIS'.
  wa_fieldcat_alv-seltext_l = text-109."text-108.
  wa_fieldcat_alv-seltext_m = 'Src Tcode / Screen'(s01).
  wa_fieldcat_alv-seltext_s = 'Source Tcode / Screen ID'(s02)."text-110.
  wa_fieldcat_alv-reptext_ddic = 'Src Tcode / Screen'(s01). "text-109.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCODE'.
  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DESCRIPTION'.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'ISORT'.

  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'RISK'.

*delete the color columns
  DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_LINE'.
  DELETE i_fieldcat_alv WHERE fieldname = 'COLOR_CELL'.
*no key fields
  wa_fieldcat_alv-key = ' '.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.
  IF bysimu = 'X'.
    wa_fieldcat_alv-seltext_l = text-115.
    wa_fieldcat_alv-seltext_m = text-115.
    wa_fieldcat_alv-seltext_s = text-116.
    wa_fieldcat_alv-reptext_ddic = text-115.
    wa_fieldcat_alv-checkbox     = 'X'.
    wa_fieldcat_alv-just     = 'X'.
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
  ELSE.
    DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
  ENDIF.

  IF p_enhanc = 'X'.
*  if highlight enhanced ruleset is selected, add this field to the alv
    wa_fieldcat_alv-seltext_l      = text-157.
    wa_fieldcat_alv-seltext_m      = text-158.
    wa_fieldcat_alv-seltext_s      = text-158.
    wa_fieldcat_alv-reptext_ddic   = text-217.
    wa_fieldcat_alv-checkbox       = 'X'.
    wa_fieldcat_alv-just     = 'X'.
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
  IF orgchk IS INITIAL.
* hide column org_abb
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'ORG_ABB'.

  ENDIF.


  wa_fieldcat_alv-col_pos = '19'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'RFCDEST'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = 20.
  wa_fieldcat_alv-tabname = 'ROUTDET4'.
  wa_fieldcat_alv-fieldname = 'APPL'.
  wa_fieldcat_alv-seltext_l = 'Application'.
  wa_fieldcat_alv-seltext_m = 'Application'.
  wa_fieldcat_alv-seltext_s = 'Application'.
  wa_fieldcat_alv-reptext_ddic = 'Application'.
  IF p_nabap IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.

  ENDIF.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
*--Don't show the org_type field ever
  wa_fieldcat_alv-no_out = 'X'.
  wa_fieldcat_alv-seltext_l = 'Org Output Type'.
  wa_fieldcat_alv-seltext_m = 'Org Output Type'.
  wa_fieldcat_alv-seltext_m = 'Org Output Type'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                   WHERE
                      fieldname = 'ORG_TYPE'.

ENDFORM.                    " adjust_role_details_fcat
*&---------------------------------------------------------------------*
*&      Form  adjust_columns_for_role_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM adjust_columns_for_role_text.
  LOOP AT i_fieldcat_alv INTO wa_fieldcat_alv.
    CLEAR wa_fieldcat_alv-col_pos.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING col_pos.
  ENDLOOP.

  DELETE i_fieldcat_alv WHERE fieldname = 'RISK'
                         AND fieldname = 'ISORT'.

  wa_fieldcat_alv-col_pos = '1'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'AGR_NAME'.
  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'AGRDESC'.

  wa_fieldcat_alv-col_pos = '3'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'CONID'.

  wa_fieldcat_alv-col_pos = '4'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DESCRIPTION'.

  wa_fieldcat_alv-col_pos = '5'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'IMP'.


  wa_fieldcat_alv-col_pos = '6'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'FUNCTIONID'.

  wa_fieldcat_alv-col_pos = '7'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'FUNDESC'.


  wa_fieldcat_alv-col_pos = '8'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'TCODE'.
  wa_fieldcat_alv-seltext_l = 'Transaction Text'(231).
  wa_fieldcat_alv-seltext_m = 'Transaction Text'(231).
  wa_fieldcat_alv-seltext_s = 'Text'(232).
  wa_fieldcat_alv-reptext_ddic = 'Transaction Text'(231).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TCODEDESC'.
  wa_fieldcat_alv-col_pos = '9'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'TCODEDESC'.

  wa_fieldcat_alv-col_pos = '10'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'RFCDEST'.

  wa_fieldcat_alv-col_pos = '10'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'APPL'.


  wa_fieldcat_alv-col_pos = '11'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'OBJCT'.
  wa_fieldcat_alv-col_pos = '12'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'OBJCTDESC'.


  wa_fieldcat_alv-col_pos = '13'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    col_pos
                 WHERE
                    fieldname = 'ORG_ABB'.

  wa_fieldcat_alv-col_pos = '14'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'AUTH'.

  wa_fieldcat_alv-col_pos = '15'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'FIELD'.

  wa_fieldcat_alv-col_pos = '16'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'VON'.

  wa_fieldcat_alv-col_pos = '17'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'BIS'.

  wa_fieldcat_alv-col_pos = '18'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'CHILD_AGR'.

  wa_fieldcat_alv-col_pos = '19'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'CHILD_AGR_DESC'.


  CLEAR: wa_fieldcat_alv.

ENDFORM.                    " adjust_columns_for_role_text
*&---------------------------------------------------------------------*
*&      Form  prepare_role_removal_simu
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*----------------------------------------------------------------------*
FORM prepare_role_removal_simu TABLES   et_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu.

*--2018/01/18 - The RFCDESTINATION shouldn't be replaced by SYSIDMANDT
*  for roles simulated to be removed

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


*&---------------------------------------------------------------------*
*&      Module  status_400  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_400 OUTPUT.
  SET TITLEBAR '400'.

ENDMODULE.                 " status_400  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  init_editor400  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_editor400 OUTPUT.
  DATA: meditor_container TYPE REF TO cl_gui_custom_container.
  DATA: lc_html_viewer TYPE REF TO cl_gui_html_viewer.
  DATA: m_editor_text(132) TYPE c OCCURS 0,
        l_url              TYPE epssurl.

  CONCATENATE g_current_user"sy-uname  C0700
  'SWWARNING' sy-uzeit INTO l_url.
*--Dhorions 20101117 : Sap considers a url with a ":" in it to be an
*  absolute url, so we need to make sure there isn't one
  WHILE l_url CS ':'.
    REPLACE ':' WITH '_' INTO l_url.
  ENDWHILE.
  IF meditor_container IS INITIAL.

*   create control container
    CREATE OBJECT meditor_container
      EXPORTING
        container_name              = 'MTEXTEDITOR'
*       repid                       = g_repid
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
    CREATE OBJECT lc_html_viewer
      EXPORTING
*       SHELLSTYLE         =
        parent             = meditor_container
      EXCEPTIONS
        cntl_error         = 1
        cntl_install_error = 2
        dp_install_error   = 3
        dp_error           = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      MESSAGE e802(bmen).
    ENDIF.


  ENDIF.

*   copy text
  m_editor_text[] = i_text[].
  CALL METHOD lc_html_viewer->load_data
    EXPORTING
      url                  = l_url
    IMPORTING
      assigned_url         = l_url
    CHANGING
      data_table           = m_editor_text
    EXCEPTIONS
      dp_invalid_parameter = 1
      dp_error_general     = 2
      cntl_error           = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
    MESSAGE e802(bmen).
  ENDIF.

  CALL METHOD lc_html_viewer->show_url
    EXPORTING
      url                    = l_url
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.
  IF sy-subrc <> 0.
    MESSAGE e802(bmen).
  ENDIF.



  CALL METHOD cl_gui_cfw=>update_view
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

*   finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDMODULE.                 " init_editor400  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0400 INPUT.
  CALL METHOD lc_html_viewer->finalize.
  CALL METHOD meditor_container->free.
  FREE : meditor_container, lc_html_viewer.

  LEAVE TO SCREEN 0.

ENDMODULE.                 " user_command_0400  INPUT

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
*&---------------------------------------------------------------------*
*&      Module  status_0300  OUTPUT
*&---------------------------------------------------------------------*
*       Initialize screen 300
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'OKCANC'.
ENDMODULE.                 " status_0300  OUTPUT


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

  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  vaildate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM vaildate_other_fields TABLES et_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu
                           et_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu
                                           .
  DATA : lt_roles        TYPE TABLE OF /psyng/bc_agr_name,
         l_rfcdest_local TYPE rfcdes-rfcdest.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.

  IF bysimu = 'X'.
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
          ENDIF.
        ELSE.
          DELETE et_role_addition_simu WHERE source_rfcdest = ar_rfcs1.
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
*Continue.
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*Continue.
          ENDIF.
        ELSE.
          DELETE et_role_addition_simu WHERE source_rfcdest = ar_rfcs2.
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
*Continue.
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*Continue.
          ENDIF.
        ELSE.
          DELETE et_role_addition_simu WHERE source_rfcdest = ar_rfcs3.
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
*Continue.
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*Continue.
          ENDIF.
        ELSE.
          DELETE et_role_addition_simu WHERE source_rfcdest = ar_rfcs4.
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
*Continue.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*Continue.
          ENDIF.
        ELSE.
*          DELETE et_role_removal_simu WHERE rfcdest = rr_rfc_1.
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
*Continue.
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*Continue.

          ENDIF.
*          DELETE et_role_removal_simu WHERE rfcdest = rr_rfc_2.
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
        IF sy-subrc <> 0.                                   "#EC FB_RC
*         if a role is not found, just proceed
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.                                 "#EC FB_RC
*         if a role is not found, just proceed
          ENDIF.
*          DELETE et_role_removal_simu WHERE rfcdest = rr_rfc_3.
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
        IF sy-subrc <> 0.                                   "#EC FB_RC
*         if a role is not found, just proceed
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
              OTHERS              = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.                                 "#EC FB_RC
*         if a role is not found, just proceed
          ENDIF.
*          DELETE et_role_removal_simu WHERE rfcdest = rr_rfc_4.
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
        IF sy-subrc <> 0.                                   "#EC FB_RC
*         if a role is not found, just proceed
        ENDIF.
      ENDIF.
    ENDIF.


  ENDIF.

ENDFORM.                    " vaildate_other_fields
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
         r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
         WITH HEADER LINE.


  DELETE xusrrfc WHERE sign = 'E'
                    AND   option = 'CP'
                    AND   low = '*'.

  APPEND LINES OF xusrrfc TO r_rfcs.
  APPEND LINES OF xrolerfc TO r_rfcs.

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
      i_popup    = ' '
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

  FREE : irfc.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 irfc.
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
  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc.
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
        e_rfcdest             = l_rfcdest
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
*&      Form  EN_ROLE_SOD_ANALYSIS_FROM_DETA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AGR_NAME  text
*      -->P_ROUTDET4_RFCDEST  text
*----------------------------------------------------------------------*
FORM role_sod_analysis_en_detail USING    agr_name
                                          rfcdest
                                          appl
                                          sodvrsio.
  SUBMIT /psyng/sod_syswide_byrole
          WITH role     = agr_name
          WITH sodvrsio = sodvrsio
          WITH s_sys    = rfcdest
          WITH s_appl    = appl
          WITH p_nabap  = 'X'
          AND RETURN.
ENDFORM.                    " EN_ROLE_SOD_ANALYSIS_FROM_DETA

*&---------------------------------------------------------------------*
*&      Form  show_user_tcode_history
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_RS_SELFIELD_VALUE  text
*----------------------------------------------------------------------*
FORM show_user_tcode_history USING i_bname
                                   i_tcode
                                   i_start TYPE dats
                                   i_end   TYPE dats.


  DATA:
    userresponse,
    1stmon(7),
    lastmon(7),
    lf_ta_installed TYPE flag,
    lf_use_ta_his   TYPE flag,
    lf_config_val   TYPE /psyng/swconfig-value,
    l_repid         LIKE sy-repid.

  se_config_param 'TA_DISPLAY_HISTORY' lf_config_val.
  IF lf_config_val = 'N'.
    CLEAR lf_use_ta_his.
  ELSE.
    lf_use_ta_his = 'X'.
  ENDIF.
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module    = 'TA'
    IMPORTING
      e_installed = lf_ta_installed.

  IF NOT lf_ta_installed = 'X' OR NOT lf_use_ta_his = 'X'.

    CLEAR: ifields.
    REFRESH: ifields.

    PERFORM get_history_months USING 1stmon lastmon.

    ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
    ifields-fieldname = 'MMYYYYS'.
    ifields-fieldtext = 'From (MM/YYYY)'(081).
    ifields-value = 1stmon.
    APPEND ifields.
    ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
    ifields-fieldname = 'MMYYYYE'.
    ifields-fieldtext = 'To (MM/YYYY)'(082).
    ifields-value = lastmon.
    APPEND ifields.

    CLEAR userresponse.
    l_repid = sy-repid.
    CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
      EXPORTING
        formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
        programname       = l_repid
        popup_title       =
                            'Restrict months (available displayed)'(080)
        ok_pushbuttontext = 'Continue'(127)
      IMPORTING
        returncode        = userresponse
      TABLES
        fields            = ifields
      EXCEPTIONS
        error_in_fields   = 1
        OTHERS            = 2.

    IF sy-subrc <> 0.
      MESSAGE e208(00) WITH text-067.
    ENDIF.

    CHECK userresponse NE 'A'. "#EC SAST_CI_GEN_CHECK
     "check to see user doesn't abort

    READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                             fieldname = 'MMYYYYS'.
    CHECK NOT ifields-value IS INITIAL.
    1stmon = ifields-value.

    READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                             fieldname = 'MMYYYYE'.
    CHECK NOT ifields-value IS INITIAL.
    lastmon = ifields-value.
*--Use SE report
    SUBMIT /psyng/sw_017
            WITH pbname = i_bname
            WITH 1stmon = 1stmon
            WITH lastmon = lastmon
            WITH validusr = ' '
            AND RETURN.
  ELSE.
*--Use TA report
    IF i_tcode IS INITIAL.
      SUBMIT /psyng/bc_usrhis_36 VIA SELECTION-SCREEN
              WITH s_users  = i_bname
              WITH validusr = ' '
              AND RETURN.
    ELSE.
*--This was a drilldown on added tcode execution nr's
      SUBMIT /psyng/bc_usrhis_36
              WITH s_users  = i_bname
              WITH validusr = ' '
              WITH s_date BETWEEN i_start AND i_end
              WITH s_tcode  = i_tcode

              AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.                    " show_user_tcode_history
*&---------------------------------------------------------------------*
*&      Form  toggle_alv_role_org
*&---------------------------------------------------------------------*
*       Toggle the org and variable elements in the role detail
*       ALV output
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM toggle_alv_role_org.
  IF gf_org_fields_display = 'X'.
    CLEAR gf_org_fields_display.
  ELSE.
    gf_org_fields_display = 'X'.
  ENDIF.
  PERFORM toggle_alv_role_org_filter USING gf_org_fields_display.
ENDFORM.                    " toggle_alv_role_org

*&---------------------------------------------------------------------*
*&      Form  toggle_alv_role_org_filter
*&---------------------------------------------------------------------*
*       show/hide org and variable elements in the role detail
*       ALV output
*----------------------------------------------------------------------*
FORM toggle_alv_role_org_filter
  USING    if_show TYPE flag.
  DATA : l_fld          TYPE string,
         lt_filter      TYPE lvc_t_filt,
         ls_filter      TYPE lvc_s_filt,
         ls_fm_filter   TYPE slis_filter_alv,
         lt_new_output  LIKE TABLE OF routdet4 WITH HEADER LINE,
         lt_color_orgph TYPE lvc_t_scol,
         lt_color_varph TYPE lvc_t_scol,
         lt_color_org   TYPE lvc_t_scol,
         lt_color_var   TYPE lvc_t_scol,
         ls_color_cell  TYPE lvc_s_scol,
         lf_highlight   TYPE flag.
  STATICS : st_faobj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
            st_org     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
            st_checked TYPE flag.
  FIELD-SYMBOLS : <out> LIKE routdet4.
  CONSTANTS :
*normal field, non org or var element
    c_org_type_normal TYPE i VALUE 0,
*org or var element  with actual value
    c_org_type_org    TYPE i VALUE 1,
*org or var element  with placeholder value ($ORG or /PSYNG/$VAREL
    c_org_type_orgph  TYPE i VALUE 3.


*--If this is the first time, get fields to be toggled
  IF st_checked IS INITIAL.
    se_config_param 'CFG_SET_HIGHLIGHT' lf_highlight.
    IF lf_highlight = 'Y'.
*    --Prepare colors
*    Add some highlighting to the placeholders
*    --Org Placeholders
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '3'.   " yellow
      ls_color_cell-color-int   = '1'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_orgph.
*    --Org Values
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '3'.   "light yellow
      ls_color_cell-color-int   = '0'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_org.
*    --Variable Elements Placeholders
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '4'.   "darker blue
      ls_color_cell-color-int   = '1'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_varph.
*    --Variable Elements
      ls_color_cell-fname       = 'VON'.
      ls_color_cell-color-col   = '4'.   "light blue
      ls_color_cell-color-int   = '0'.
      ls_color_cell-color-inv   = '0'.
      APPEND ls_color_cell TO lt_color_var.
    ENDIF.
*  --Variable Elements
    CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
      EXPORTING
        vrsio      = sodvrsio
      TABLES
        faobj_fm   = st_faobj
        spconfs_fm = spconfs.
    DELETE st_faobj WHERE NOT val_from CP '/PSYNG/$*'.
    SORT st_faobj BY field object funid tcode.
    DELETE ADJACENT DUPLICATES FROM st_faobj
    COMPARING field object funid tcode.
*--Org Elements
    CALL FUNCTION '/PSYNG/SW_AO_READ'
      EXPORTING
        if_read       = 'X'
        i_setid       = cfgset
      TABLES
        et_org_values = st_org.
    DELETE st_org WHERE active <> 'X'.
    SORT st_org BY varbl.
    DELETE ADJACENT DUPLICATES FROM st_org.
    st_checked = 'X'.
*--Adjust the output to include $org and /psyng/$variable entries
    LOOP AT routdet4 ASSIGNING <out>.
      <out>-org_type = c_org_type_normal.
      READ TABLE st_org WITH KEY varbl = <out>-field
      BINARY SEARCH TRANSPORTING varbl.
      IF sy-subrc = 0.
        <out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_org TO <out>-color_cell.
        lt_new_output = <out>.
        CLEAR : lt_new_output-von,
                lt_new_output-bis,
                lt_new_output-simu,
                lt_new_output-enhanced,
                lt_new_output-org_abb.
        CONCATENATE '$' st_org-varbl INTO   lt_new_output-von.
        lt_new_output-org_type = c_org_type_orgph.
        lt_new_output-color_cell[] = lt_color_orgph[].
        APPEND lt_new_output.
      ENDIF.
*--We are not taking function/tcode into account yet
      READ TABLE st_faobj WITH KEY field  = <out>-field
                                   object = <out>-objct
                                   funid  = <out>-functionid
                                   tcode  = <out>-tcode
      BINARY SEARCH TRANSPORTING val_from.
      IF sy-subrc = 0.
        <out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_var TO <out>-color_cell.
        lt_new_output = <out>.
        CLEAR : lt_new_output-von,
                lt_new_output-bis,
                lt_new_output-simu,
                lt_new_output-enhanced,
                lt_new_output-org_abb.
        lt_new_output-von = st_faobj-val_from.
        lt_new_output-org_type = c_org_type_orgph.
        lt_new_output-color_cell[] = lt_color_varph[].
        APPEND lt_new_output.
      ENDIF.
*      ENDIF.
    ENDLOOP.
    SORT lt_new_output.
    DELETE ADJACENT DUPLICATES FROM lt_new_output.
    APPEND LINES OF lt_new_output TO routdet4.
  ENDIF.
* Get a reference to the GRID
  FIELD-SYMBOLS <grid> TYPE REF TO cl_gui_alv_grid.
  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
  ASSIGN (l_fld) TO <grid>."#EC PATHLOCK_CI_DYN_ACCES
  IF <grid> IS ASSIGNED.
*  --Get the existing filter
    CALL METHOD <grid>->get_filter_criteria
      IMPORTING
        et_filter = lt_filter[].
    DELETE lt_filter WHERE fieldname = 'ORG_TYPE' .
  ENDIF.
  IF if_show <> 'X'.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = 'ROUTDET4'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_org.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ELSE.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = 'ROUTDET4'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_orgph.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ENDIF.
*--Apply the new filter
  IF <grid> IS ASSIGNED.
    CALL METHOD <grid>->set_filter_criteria
      EXPORTING
        it_filter                 = lt_filter[]
      EXCEPTIONS
        no_fieldcatalog_available = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE i002 WITH
      'Failed to apply Org and Variable element filter'.
    ENDIF.
  ENDIF.
  REFRESH : gt_filter_role_detail.
  LOOP AT lt_filter INTO ls_filter.
    MOVE-CORRESPONDING ls_filter TO ls_fm_filter.
    ls_fm_filter-sign0         = ls_filter-sign.
    ls_fm_filter-optio         = ls_filter-option.
    ls_fm_filter-valuf         = ls_filter-low.
    ls_fm_filter-valut         = ls_filter-high.
    ls_fm_filter-valuf_int     = ls_filter-low.
    ls_fm_filter-datatype      = ls_filter-datatype.
    ls_fm_filter-ref_fieldname = ls_filter-fieldname.
    ls_fm_filter-ref_tabname   = ls_filter-tabname.

    APPEND ls_fm_filter TO gt_filter_role_detail.
  ENDLOOP.
  IF <grid> IS ASSIGNED.
    CALL METHOD <grid>->refresh_table_display.
  ENDIF.
ENDFORM.                    " toggle_alv_role_org_filter

*&---------------------------------------------------------------------*
*&      Form  toggle_alv_role_init
*&---------------------------------------------------------------------*
* if Configuration set functionality is enabled,
* prepare info for toggling variable and org values.
*----------------------------------------------------------------------*
FORM toggle_alv_role_init.
  DATA : lf_show TYPE flag.
  IF gf_cfg_set_enabled = 'X'.
    se_config_param 'CFG_SET_SHOW_DFLT' lf_show.
    IF lf_show = 'Y'.
      PERFORM toggle_alv_role_org_filter USING 'X'.
      gf_org_fields_display = 'X'.
    ELSE.
      PERFORM toggle_alv_role_org_filter USING ''.
      CLEAR gf_org_fields_display.
    ENDIF.
  ENDIF.
ENDFORM.                    " toggle_alv_user_init
*&---------------------------------------------------------------------*
*&      Module  STATUS_9005  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9005 OUTPUT.
  SET PF-STATUS '9005'.
*  SET TITLEBAR 'xxx'.
ENDMODULE.
