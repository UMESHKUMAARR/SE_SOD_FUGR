*&---------------------------------------------------------------------* "#EC SAST_CI_GEN_CHECK
*& Report  /PSYNG/Z_SODREPORT_ORG_45
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sodreport_org_usr MESSAGE-ID /psyng/sw.

TYPE-POOLS : slis.
TABLES : /psyng/conflict,usr02,/psyng/sw_uinfo,usr21,
         agr_define,rfcdes,/psyng/swsodorgm,ust04,/psyng/ex_caobj_lock, usr05.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_200.
*INCLUDE /psyng/sw_113.
CONSTANTS :
  cf_show_texts      TYPE flag VALUE 'X',
  cf_dont_show_texts TYPE flag VALUE ''.
FIELD-SYMBOLS : <macro_fs_dynfield>   TYPE any.
DEFINE dyn_value.
  has_field &1.
  if sy-subrc = 0.
    assign component &1 of structure &3 to <macro_fs_dynfield>.
    <macro_fs_dynfield> =  &2.
    unassign <macro_fs_dynfield>.
  endif.
END-OF-DEFINITION.
DEFINE get_dyn_value.
  has_field &1.
  if sy-subrc = 0.
    assign component &1 of structure &2 to <macro_fs_dynfield>.
    &3 = <macro_fs_dynfield>.
    unassign <macro_fs_dynfield>.
  endif.
END-OF-DEFINITION.

TYPES :
  BEGIN OF typ_texts,
    type TYPE fieldname,
    id   TYPE string,
    text TYPE string,
  END OF typ_texts,

  BEGIN OF typ_ref01,
    ref_key   TYPE /psyng/ref_key,
    key_val   TYPE /psyng/key_val,
    key_index TYPE i,
  END OF typ_ref01.

DATA: BEGIN OF typ_text ,
   text LIKE tline-tdline,
   END OF typ_text.

DATA :
  i_text LIKE typ_text OCCURS 0 WITH HEADER LINE,
  gt_alv_fieldcat       TYPE slis_t_fieldcat_alv,
  gt_alv_sort           TYPE STANDARD TABLE OF slis_sortinfo_alv,
  gs_alv_layout         TYPE slis_layout_alv,
  gr_table_out          TYPE REF TO data,
  lt_results            TYPE TABLE OF /psyng/sw_outputdet3
                        WITH HEADER LINE,
  lr_rec                TYPE REF TO data,
  lt_fields_value TYPE TABLE OF typ_ref01 WITH HEADER LINE,
  lt_elements_value TYPE TABLE OF typ_ref01,
  lt_action_value TYPE TABLE OF typ_ref01,
  g_usertype            TYPE /psyng/xuustyp,
  g_persa               TYPE /psyng/persa,
  l_local_sys           TYPE rfcdest,
  gf_his_user           TYPE /psyng/bapiflagx,
  gf_his_any            TYPE /psyng/bapiflagx,
  gf_his_all            TYPE /psyng/bapiflagx,
  gt_enh_tcodes         TYPE TABLE OF /psyng/sw_par_tcode_output,
  totalusers2           TYPE usr02 OCCURS 0 WITH HEADER LINE,
  gt_uinfo_remote       TYPE TABLE OF /psyng/sw_uinfo_remote,
  lt_simuagrs           TYPE TABLE OF /psyng/simu_agrs WITH HEADER LINE,
  gt_mcuser             TYPE TABLE OF /psyng/mitigation_assignment
                        WITH HEADER LINE,
  lt_role_removal_simu  TYPE TABLE OF /psyng/sw_role_removal_simu,
  lt_role_addition_simu TYPE TABLE OF /psyng/sw_role_addition_simu,
lt_role_removal_simu_en TYPE TABLE OF /psyng/en_role_removal_simu,
lt_functtran            TYPE TABLE OF /psyng/functtran "HBHALLA
                        WITH HEADER LINE,
lt_role_addition_simu_en TYPE TABLE OF /psyng/ex_role_addition_simu,
  lt_enh_con            TYPE TABLE OF /psyng/sw_enh_usr_con
                        WITH HEADER LINE,
  gt_map_tcode_screen   TYPE TABLE OF /psyng/tcode_screen
                        WITH HEADER LINE,
  mode                  TYPE string,
  gf_show_texts         TYPE flag,
  gt_texts              TYPE HASHED TABLE OF typ_texts
                        WITH UNIQUE KEY type id
                        WITH HEADER LINE,
  gt_rfcdest            TYPE TABLE OF rfcdes WITH HEADER LINE,
  g_program             LIKE sy-repid,
  g_usercount           TYPE i, "conflicted users
  g_totalusercount      TYPE i, "analyzed users
  g_concount            TYPE i, "conflicts
  g_mitconcount         TYPE i, "mitigated conflicts
  l_conusr              TYPE string,
  gf_cfg_set_enabled    TYPE flag,
  gf_mit_by_org         TYPE c,
  g_dynnr               TYPE sy-dynnr,
  g_his_begda           TYPE sy-datum,
  g_his_endda           TYPE sy-datum,
  g_his_avail_beg       TYPE d,
  g_his_avail_end       TYPE d,
  gf_show_only_stcode   TYPE /psyng/bapiflagx,
  gs_selfield           TYPE slis_selfield,
  gf_mstdate            TYPE dats,
  gf_meddate            TYPE dats,
  gf_funcount           TYPE i,
  gt_filter_user_detail TYPE slis_t_filter_alv,
  gf_org_fields_display TYPE flag VALUE 'X',
  go_struct             TYPE REF TO cl_abap_structdescr,
  go_table              TYPE REF TO cl_abap_tabledescr,
  gs_variant            TYPE disvariant,
  lt_rolid TYPE STANDARD TABLE OF  /psyng/range_rolid,
  ls_rolid TYPE /psyng/range_rolid,
  g_current_user        TYPE sy-uname, "RGUPTA for C0700
  g_usrpar TYPE usr05-parid,"C1454
  gt_usrpar TYPE TABLE OF /psyng/sw_par_va_id,
gs_usrpar TYPE /psyng/sw_par_va_id..
CONSTANTS:
      c_func_en_read_appsys(30) TYPE c
                                  VALUE '/PSYNG/EX_CR_READ_APPSYS',
      c_type(1) TYPE c VALUE 'F'. "HBHALLA
DATA : lt_syshdr       TYPE TABLE OF /psyng/ex_syshdr_st
                    WITH HEADER LINE.
FIELD-SYMBOLS : <fs_role_addition> TYPE /psyng/ex_role_addition_simu,
               <fs_role_removal> TYPE /psyng/en_role_removal_simu,
               <fs_fiorid>       TYPE /PSYNG/SW_FIORIID,"HBHALLA
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
               <fs_deprt>       TYPE /psyng/sw_uinfo_remote-department,
               <fs_class>       TYPE /psyng/sw_uinfo_remote-class.
*End of Addition <HBHALLA> PN-15675 27/10/2025
data : g_org_field type flag,
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
       ls_deprt TYPE /psyng/sw_uinfo_remote,
       ls_class TYPE /psyng/sw_uinfo_remote.
*End of Addition <HBHALLA> PN-15675 27/10/2025
*--Proposed Remediation Table
DATA: BEGIN OF gt_suggout OCCURS 10,
        bname       LIKE ust04-bname,
        conid       LIKE /psyng/conflict-conid,
        description LIKE /psyng/conflict-description,
        exetcode    TYPE i,
        exeother    TYPE i,
        functionid  LIKE /psyng/functtran-functionid,
        fundesc     LIKE /psyng/function-description,
        rfcdest     LIKE rfcdes-rfcdest,
        agr_name    LIKE agr_prof-agr_name,
        agrdesc     LIKE agr_texts-text,
        comp_agr    LIKE agr_prof-agr_name,
      END OF gt_suggout.

FIELD-SYMBOLS : <gt_output> TYPE STANDARD TABLE,
                <gs_output> TYPE any.
DEFINE has_field.
  read table gt_alv_fieldcat with key fieldname = &1
  binary search transporting no fields.
END-OF-DEFINITION.
*--Selection Screen
SELECT-OPTIONS :
  pbname   FOR usr21-bname,
  spconfs  FOR /psyng/conflict-conid,
  pclass   FOR usr02-class,
  s_comp   FOR /psyng/sw_uinfo-company,
  s_depart FOR /psyng/sw_uinfo-department,
  s_cuid   FOR /psyng/sw_uinfo-central_uid,
  s_kostl  FOR usr21-kostl,
  usrtype  FOR g_usertype,
  s_role   FOR agr_define-agr_name,
  xusrrfc  FOR rfcdes-rfcdest,
  orglvl   FOR /psyng/swsodorgm-abb,
  s_prof   FOR  ust04-profile,
  s_appl   FOR /psyng/ex_caobj_lock-appl,
  s_sysid  FOR /psyng/ex_caobj_lock-sysid,
  sens     FOR /psyng/conflict-imp,
  s_risk   FOR /psyng/conflict-risk,
  pwerks   FOR g_persa,
  s_usrpar FOR usr05-parva
.


PARAMETERS :
  sodvrsio LIKE /psyng/conflict-vrsio,
  shonosod TYPE flag,
  shopcom  TYPE flag,
  p_dlayo  TYPE slis_vari,
  cfgset   TYPE /psyng/seconfid,
  p_shtext TYPE flag,
  erroles  TYPE flag,
  excl_er  TYPE flag,
  p_sodrfc TYPE rfcdest,
  ustb     TYPE flag,
  shosimp  TYPE flag,
  shodet   TYPE flag,
  shotree  TYPE flag,
  showcomp TYPE flag,
  showpcom TYPE flag,
  validusr TYPE flag,
  exlckusr TYPE flag,
  outvdate TYPE flag,
  xmc      TYPE flag,
  p_enhanc TYPE flag,
  p_hienhn TYPE flag,
  orgchk   TYPE flag,
  p_remonl TYPE flag,
  p_locusr TYPE flag,
  p_caldet TYPE flag,
  p_nabap  TYPE flag,
  p_abap   TYPE flag,
  p_noprin TYPE flag,
  pcolor   TYPE flag,
  p_shhis  TYPE flag,
  p_usrpar TYPE usr05-parva.
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
  se_config_param 'USR_PARAM_FIELD_NAME' g_usrpar.
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
*--Check if mitigation by org level is enabled
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.
* BOC by RGUPTA on 28.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
*GG opl 645 start
se_config_param 'CONSIDER_ORG_FIELD' g_org_field.
if g_org_field eq 'Y' or g_org_field eq 'X'.
g_org_field = 'X'.
endif.
*GG opl 645 end

START-OF-SELECTION.
*Begin of Addition:HBHALLA(PN-18556)(10/04/26)
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_081'.
DATA lv_auth_fail TYPE flag.
*End of Addition:HBHALLA(PN-18556)(10/04/26)

*BOC UMITTAL ATC check SIEMENS 11/02/25
  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.
*EOC UMITTAL ATC check SIEMENS 11/02/25
  g_program = sy-repid.
*-- Check RFC destinations
  PERFORM rfc_validations.

*--BOC AKUMAR C1454
  IF g_usrpar IS NOT INITIAL AND s_usrpar IS NOT INITIAL.
    gs_usrpar-parid = g_usrpar.
    gs_usrpar-parva = s_usrpar[].
    APPEND gs_usrpar TO gt_usrpar.
    CLEAR gs_usrpar.
  ENDIF.
*--EOC AKUMAR C1454

  IF byrsimu = 'X'.
*--prepare table for role removal simulation
    PERFORM prepare_role_removal_simu
      TABLES lt_role_removal_simu.
  ENDIF.
  IF bysimu = 'X'.
*--prepare table for role removal simulation
    PERFORM prepare_role_addition_simu
      TABLES lt_role_addition_simu.
  ENDIF.

  IF ebysimu EQ 'X'.
*--prepare table for role removal simulation for EN
    PERFORM prepare_role_addition_simu_en
       TABLES lt_role_addition_simu_en.

  ENDIF.

  IF ebrsimu EQ 'X'.
*--prepare table for role removal simulation for EN
    PERFORM prepare_role_removal_simu_en
         TABLES lt_role_removal_simu_en.

  ENDIF.

  IF ebrsimu EQ 'X' OR ebysimu EQ 'X'.
    CALL FUNCTION c_func_en_read_appsys      "#EC PATHLOCK_CI_DYN_ACCES
                TABLES
                  it_applications = s_appl
                  it_systems      = s_sysid
*        et_apphdr       = lt_apphdr
                  et_syshdr       = lt_syshdr.
  ENDIF.
  IF NOT lt_role_addition_simu_en[] IS INITIAL.
    LOOP AT lt_role_addition_simu_en ASSIGNING <fs_role_addition>.
      READ TABLE lt_syshdr WITH KEY
        sysid = <fs_role_addition>-target_sysid.
      IF sy-subrc EQ 0.
        <fs_role_addition>-appl = lt_syshdr-appl.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF NOT lt_role_removal_simu_en[] IS INITIAL.
    LOOP AT lt_role_removal_simu_en ASSIGNING <fs_role_removal>.
      READ TABLE  lt_syshdr WITH KEY sysid = <fs_role_removal>-sysid.
      IF sy-subrc EQ 0.
        <fs_role_removal>-appl = lt_syshdr-appl.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF p_shtext = abap_true.
    gf_show_texts = cf_show_texts.
  ELSE.
    gf_show_texts = cf_dont_show_texts.
  ENDIF.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CALL FUNCTION '/PSYNG/SW_081'
    EXPORTING
      i_byuser              = ''
      i_byugrp              = ''
      i_byall               = 'X'
      i_noprin              = p_noprin
      i_bysimu              = bysimu
      i_showcomp            = showcomp
      i_showpcom            = showpcom
      i_validusr            = validusr
      i_exlckusr            = exlckusr
      i_outvdate            = outvdate
      i_orgchk              = orgchk
      i_sodvrsio            = sodvrsio
      i_config_set          = cfgset
      i_enhanc              = p_enhanc
      i_locusr              = p_locusr
      i_bypa                = ''
      i_hienhn              = p_hienhn
      i_xmc                 = xmc
      i_shonosod            = shonosod
      i_nonabap             = p_nabap
      i_abap                = p_abap
      i_ustb                = ustb
      i_shosum              = ''
      i_rolerfc             = rolerfc
      i_advanced_role_simu  = ' '
      i_remote_only         = p_remonl
      i_er_roles            = erroles
      i_exclude_er_roles    = excl_er
      i_matrix_rfc          = p_sodrfc
      if_simpview           = shosimp
      it_usrpar             = gt_usrpar
      i_org_field           = g_org_field "GG opl645

    IMPORTING
      e_auth_fail           = lv_auth_fail
    "(++)HBHALLA(PN-18556)(10/04/26)

    TABLES
      it_rfcdest            = xusrrfc
      it_simurols           = simurols
      it_bname              = pbname
      it_usertype           = usrtype
      it_actgroups          = s_role
      it_profiles           = s_prof
      it_class              = pclass
      it_conflicts          = spconfs
      it_sens               = sens
      it_risk               = s_risk
      it_persa              = pwerks
      it_orglvl             = orglvl
      it_department         = s_depart
      it_company            = s_comp
      it_central_uid        = s_cuid
      it_costcenter         = s_kostl
      it_appl               = s_appl
      it_sysid              = s_sysid
      et_outputdet          = lt_results
      et_enh_tcodes         = gt_enh_tcodes
      et_users              = totalusers2
      et_uinfo              = gt_uinfo_remote
      et_simuagrs           = lt_simuagrs
      et_mcuser             = gt_mcuser
      it_simu_role_removal  = lt_role_removal_simu
      it_simu_role_addition = lt_role_addition_simu
      et_enh_con            = lt_enh_con
      et_map_tcode_screen   = gt_map_tcode_screen
   it_simu_role_addition_en = lt_role_addition_simu_en
   it_simu_role_removal_en  = lt_role_removal_simu_en
*BOC:HBHALLA (PN-4026) (07/03/25)
   it_functtran             = lt_functtran
*EOC:HBHALLA (PN-4026) (07/03/25)
    EXCEPTIONS
      user_cancelled        = 1.

  CHECK sy-subrc = 0. "RGUPTA on 16th Dec, 2021
*--Count analyzed users
*-- instead of gt_uinfo_remote using totalusers2 as gt_uinfo_remote
*-- can have duplicates bname

*BOC:HBHALLA (PN-13530) (12/06/25)
***  IF totalusers2[] IS INITIAL.
***    MESSAGE ID '/PSYNG/SW' TYPE 'S' NUMBER '140'
***    WITH 'No Users Match the selection.'.
***    LEAVE LIST-PROCESSING.
***  ENDIF.
*EOC:HBHALLA (PN-13530) (12/06/25)

*Begin of Addition:HBHALLA(PN-18556)(10/04/26)
  IF lv_auth_fail = 'X'.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
*End of Addition:HBHALLA(PN-18556)(10/04/26)

  DESCRIBE TABLE totalusers2 LINES g_totalusercount.

  CASE 'X'.
    WHEN shosimp.
      mode = 'SIMPLE'.
    WHEN shodet.
      mode = 'DET'.
    WHEN shotree.
      mode = 'TREE'.
  ENDCASE.
*--Create a dynamic table that only contains the fields we
*  will show on the screen.
  PERFORM create_output_table
    USING mode
          gf_show_texts
    CHANGING
           gr_table_out
           gt_alv_fieldcat[]
           gs_alv_layout.

  ASSIGN gr_table_out->* TO <gt_output>.
  CREATE DATA lr_rec LIKE LINE OF <gt_output>.
  ASSIGN lr_rec->* TO <gs_output>.

  SORT lt_results BY bname conid functionid rfcdest
   tcode objct field von bis agr_name .
  IF mode = 'SIMPLE'.
    IF orgchk = 'X'.
* Added COMP_AGR by RGUPTA on 6th Dec, 2021 for C0529
      SORT lt_results BY bname conid functionid rfcdest
       tcode comp_agr agr_name org_abb.
      DELETE ADJACENT DUPLICATES FROM lt_results COMPARING
        bname conid functionid rfcdest tcode comp_agr agr_name
        org_abb.
    ELSE.
      SORT lt_results BY bname conid functionid rfcdest tcode
       comp_agr agr_name .
      DELETE ADJACENT DUPLICATES FROM lt_results COMPARING
        bname conid functionid rfcdest tcode comp_agr agr_name.
    ENDIF.
  ENDIF.
  IF h_tcdo = 'X' AND mode = 'DET'."hide everything except tcode
    DELETE lt_results WHERE objct <> 'S_TCODE' AND field <> 'TCD'.
  ENDIF.



  LOOP AT lt_results.
*--Count users and conflicts
    AT NEW bname.
      ADD 1 TO g_usercount.
    ENDAT.
    CONCATENATE lt_results-bname lt_results-conid  INTO l_conusr.
    ON CHANGE OF l_conusr.
      ADD 1 TO g_concount.
    ENDON.
*--move to output table
    MOVE-CORRESPONDING lt_results TO <gs_output>.
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
    CLEAR ls_class.
    READ TABLE gt_uinfo_remote
    WITH KEY bname   = lt_results-bname
             rfcdest = lt_results-rfcdest
    INTO ls_class  TRANSPORTING class.
     IF sy-subrc = 0.
      ASSIGN COMPONENT 'CLASS' OF STRUCTURE
       <gs_output> TO <fs_class>.
       <fs_class> = ls_class-class.
     ENDIF.
    IF <fs_class> IS ASSIGNED.
      UNASSIGN <fs_class>.
    ENDIF.

    CLEAR ls_deprt.
    READ TABLE gt_uinfo_remote
    WITH KEY bname   = lt_results-bname
             rfcdest = lt_results-rfcdest
    INTO ls_deprt TRANSPORTING department.
    IF sy-subrc = 0.
     ASSIGN COMPONENT 'DEPARTMENT' OF STRUCTURE
      <gs_output> TO <fs_deprt>.
      <fs_deprt> = ls_deprt-department.
    ENDIF.
    IF <fs_deprt> IS ASSIGNED.
      UNASSIGN <fs_deprt>.
    ENDIF.
*End of Addition <HBHALLA> PN-15675 27/10/2025
*BOC:HBHALLA (PN-4026) (07/03/25)
  IF lt_results-tcode CP
        /psyng/sw_cl_constants=>placeholder_tcode_prefix.
    READ TABLE lt_functtran WITH KEY tcode = lt_results-tcode
                           FUNCTIONID = LT_RESULTS-FUNCTIONID
                           type       =  c_type
                           vrsio      =  sodvrsio
    TRANSPORTING ALL FIELDS.
      IF sy-subrc = 0.
*   MOVE-CORRESPONDING lt_functtran TO <gs_output>.
    ASSIGN COMPONENT 'FIORIID' OF STRUCTURE
    <gs_output> TO <fs_fiorid>.
    <fs_fiorid> = lt_functtran-fioriid.
      ENDIF.
   CLEAR lt_functtran.
   UNASSIGN <fs_fiorid>.
  ENDIF.

    APPEND <gs_output> TO <gt_output>.
    CLEAR <gs_output>.
*EOC:HBHALLA (PN-4026) (07/03/25)

*---Collect all role id key for EN
    IF p_nabap = 'X'.
      ls_rolid-sign = 'I'.
      ls_rolid-option = 'EQ'.
      ls_rolid-low = lt_results-agr_name.
      COLLECT ls_rolid INTO lt_rolid.
    ENDIF.
  ENDLOOP.


  FREE : lt_results.
*--Handle EN (non-ABAP) specific functionality.
  PERFORM handle_non_abap.
*--Handle Highlighting
  PERFORM handle_highlights.
*--Handle Mitigations
  PERFORM handle_mitigations.
*--Handle Historical Data
  PERFORM handle_historical_data.
*--Add all required texts
  IF gf_show_texts = 'X'.
    PERFORM collect_texts.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      PERFORM add_texts_to_fs.
    ENDLOOP.
  ENDIF.

*--Create Sort Table
  PERFORM create_sort_table.

  CASE mode.
    WHEN 'TREE'.
      PERFORM output_using_alv_tree.
    WHEN 'DET' OR 'SIMPLE'.
      PERFORM output_using_alv.
  ENDCASE.

**********************************************************************
* Collect all texts that may be needed, we'll load for each unique
* item the text only once
* Text will only be collected for those fields present in table
*  gt_alv_fieldcat
* gt_alv_fieldcat is a standard table sorted by fieldname
**********************************************************************
FORM collect_texts.
  DEFINE add_text.
*--Add the text to global hashed text table for fast lookup
    gt_texts-type = &1.
    gt_texts-id   = &2.
    gt_texts-text = &3.
    insert table gt_texts.
  END-OF-DEFINITION.
  TYPES :
    BEGIN OF ty_fioria,
      fioriid TYPE /psyng/sw_fioriid,
      appname TYPE /psyng/sw_fioriname,
    END OF   ty_fioria,
    BEGIN OF ty_functtran,
      functionid TYPE /psyng/function_id,
      tcode      TYPE tcode,
      fioriid    TYPE /psyng/sw_fioriid,
      appname    TYPE /psyng/sw_fioriname,
    END OF   ty_functtran,
    BEGIN OF ty_screen_texts ,
      usrrt TYPE /psyng/user_right,
      udesc TYPE /psyng/user_right_desc,
      appl  TYPE /psyng/ex_caobj_lock-appl,
      sysid TYPE /psyng/ex_caobj_lock-sysid,
    END OF ty_screen_texts.
  DATA :
    l_appl           TYPE /psyng/application,
    l_system TYPE /psyng/system,
    lt_agr_names_sap TYPE TABLE OF agr_name WITH HEADER LINE,
    BEGIN OF lt_agr_names_en OCCURS 0,
      appl  TYPE /psyng/application,
      sysid TYPE /psyng/system,
      rolid TYPE /psyng/key_val,
    END OF lt_agr_names_en,
    BEGIN OF lt_tcodes OCCURS 0,
      tcode TYPE tstct-tcode,
      ttext TYPE tstct-ttext,
    END OF lt_tcodes,

        BEGIN OF lt_uinfo_en OCCURS 0,
      appl  TYPE /psyng/application,
      sysid TYPE /psyng/system,
      bname TYPE /psyng/ex_user_id,
    END OF lt_uinfo_en,

    lt_agr_texts    TYPE SORTED TABLE OF agr_texts
                    WITH UNIQUE KEY agr_name
                    WITH HEADER LINE,
    lt_obj_names    TYPE TABLE OF tobjt WITH HEADER LINE,
    lt_obj_texts    TYPE SORTED TABLE OF tobjt WITH HEADER LINE
                  WITH UNIQUE KEY object,
    lt_func_names   TYPE TABLE OF /psyng/function WITH HEADER LINE,
   lt_func_texts   TYPE SORTED TABLE OF /psyng/function WITH HEADER LINE
                 WITH UNIQUE KEY function,
   lt_tcode_texts  LIKE SORTED TABLE OF lt_tcodes WITH UNIQUE KEY tcode
                 WITH HEADER LINE,
   lt_functtran    TYPE TABLE OF ty_functtran WITH HEADER LINE,
 lt_fioria       TYPE HASHED TABLE OF ty_fioria WITH UNIQUE KEY fioriid,
 ls_fioria       TYPE ty_fioria,
 l_fioritcd      TYPE string,
 lt_screen_texts TYPE HASHED TABLE OF ty_screen_texts
                 WITH UNIQUE KEY usrrt appl sysid
                 WITH HEADER LINE,
 l_text_id TYPE string,
 l_rolid TYPE /psyng/ex_rolhdr_st-rolid,
 l_rolid_value TYPE /psyng/key_val,
 ls_role_value TYPE /psyng/ex_rolid_value,
 BEGIN OF lt_screen OCCURS 0,
   usrrt TYPE /psyng/user_right,
   appl  TYPE /psyng/ex_caobj_lock-appl,
   sysid TYPE /psyng/ex_caobj_lock-sysid,
 END OF lt_screen,
 l_tabname_usrrt(20) TYPE c,
 lt_bnames_sap TYPE TABLE OF xubname WITH HEADER LINE,
  lt_uinfo             TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
  lt_uinfo1             TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
  ls_uinfo             TYPE /psyng/sw_uinfo,
  it_appl TYPE TABLE OF /psyng/range_appl WITH HEADER LINE,
  it_sysid TYPE TABLE OF /psyng/range_sysid WITH HEADER LINE,
  lt_sel_users TYPE TABLE OF /psyng/range_ex_bname WITH HEADER LINE,
 lt_uinfo_en_det     TYPE TABLE OF /psyng/ex_usrhdr_st WITH HEADER LINE.

  DATA: l_sysid TYPE /psyng/system,   "HBHALLA (PN-6797)
        lv_system TYPE /psyng/system, "HBHALLA (PN-6797)
 lt_uinfo_remote TYPE TABLE OF /psyng/sw_uinfo_remote,
                      "HBHALLA (PN-6797)
 ls_namtext TYPE /psyng/sw_uinfo_remote.  "HBHALLA (PN-6797)

  FIELD-SYMBOLS: <fs_functtran> TYPE ty_functtran.

*--Collect unique items we need texts for
  LOOP AT <gt_output> ASSIGNING <gs_output>.
    has_field 'APPLICATION'.
    IF sy-subrc = 0.
      get_dyn_value 'APPLICATION' <gs_output> l_appl.
      IF l_appl IS INITIAL.
        l_appl = 'SAP'.
      ENDIF.
      IF l_appl <> 'SAP'.
        SORT gt_map_tcode_screen BY tcode.
      ENDIF.
    ELSE.
      l_appl = 'SAP'.
    ENDIF.
*-- Collect Role Names
    has_field 'AGR_DESC'.
    IF sy-subrc = 0.
      IF l_appl = 'SAP'.
        get_dyn_value 'AGR_NAME' <gs_output> lt_agr_names_sap.
        COLLECT lt_agr_names_sap.
      ELSE.
        lt_agr_names_en-appl  = l_appl.
        get_dyn_value 'RFCDEST' <gs_output> lt_agr_names_en-sysid.
        get_dyn_value 'AGR_NAME' <gs_output> lt_agr_names_en-rolid.
        COLLECT lt_agr_names_en.
      ENDIF.
    ENDIF.
*--Collect object names
    has_field 'OBJCTDESC'.
    IF sy-subrc = 0.
      IF l_appl = 'SAP'.
        get_dyn_value 'OBJCT' <gs_output> lt_obj_names-object.
        COLLECT lt_obj_names.
      ENDIF.
    ENDIF.
*--Collect function names
    has_field 'FUNDESC'.
    IF sy-subrc = 0.
      get_dyn_value 'FUNCTIONID' <gs_output> lt_func_names-function.
      COLLECT lt_func_names.
    ENDIF.
*--Collect tcodes
    has_field 'TCODEDESC'.
    IF sy-subrc = 0.
      IF l_appl = 'SAP'.
        get_dyn_value 'TCODE' <gs_output> lt_tcodes-tcode.
        COLLECT lt_tcodes.
      ELSE.
        lt_screen-appl = l_appl.
        get_dyn_value 'RFCDEST' <gs_output> lt_screen-sysid.
        get_dyn_value 'TCODE'   <gs_output> lt_screen-usrrt.
        COLLECT lt_screen.
      ENDIF.
    ENDIF.
*BOC:HBHALLA(PN-4772)
    CONCATENATE sy-sysid sy-mandt INTO lv_system.
    lt_uinfo_remote = gt_uinfo_remote.
    DELETE lt_uinfo_remote WHERE name_text IS INITIAL.
*EOC:HBHALLA(PN-4772)
*BOC AKUMAR PN3723
    has_field 'BNAME_DESC'.
    IF sy-subrc = 0.
      IF l_appl = 'SAP'.
        get_dyn_value 'BNAME' <gs_output> lt_uinfo-bname.
*EOC:HBHALLA(PN-4772)
        get_dyn_value 'RFCDEST' <gs_output> l_sysid.
        CLEAR: lt_uinfo-name_text,ls_namtext.
        READ TABLE lt_uinfo_remote INTO ls_namtext
        WITH KEY bname = lt_uinfo-bname rfcdest = l_sysid.
*        TRANSPORTING name_text INTO ls_namtext-name_text.
        IF sy-subrc = 0.
          lt_uinfo-name_text = ls_namtext-name_text.
        ENDIF.
*EOC:HBHALLA(PN-4772)
        COLLECT lt_uinfo.
      ELSE.
        lt_agr_names_en-appl  = l_appl.
        get_dyn_value 'RFCDEST' <gs_output> lt_uinfo_en-sysid.
        get_dyn_value 'BNAME' <gs_output> lt_uinfo_en-bname.
*BOC:HBHALLA(PN-4772)
        CLEAR: lt_uinfo_en_det-full_name,ls_namtext.
        READ TABLE lt_uinfo_remote INTO ls_namtext
          WITH KEY bname = lt_uinfo_en-bname rfcdest = lv_system.
*        TRANSPORTING name_text INTO ls_namtext.
        IF sy-subrc = 0.
          get_dyn_value 'BNAME' <gs_output> lt_uinfo_en_det-bname.
          lt_uinfo_en_det-full_name = ls_namtext-name_text.
          COLLECT lt_uinfo_en_det.
        ENDIF.
*EOC:HBHALLA(PN-4772)
        COLLECT lt_uinfo_en.
      ENDIF.
    ENDIF.
*EOC AKUMAR PN3723
  ENDLOOP.
*--Store texts in a global hashed table  with type(fieldname?), id, text
*  For EN texts, the id is id+appl+sys

*BOC AKUMAR PN3723
*--Load user names for sap
  IF NOT lt_uinfo[] IS INITIAL.

    LOOP AT lt_uinfo INTO ls_uinfo.

      IF ls_uinfo-name_text IS INITIAL.
        REFRESH lt_uinfo1.
        APPEND ls_uinfo TO lt_uinfo1.

        CALL FUNCTION '/PSYNG/SW_USER_INFO'
          EXPORTING
            i_name_only     = 'X'
          TABLES
            sw_uinfo        = lt_uinfo1.

        IF lt_uinfo1[] IS NOT INITIAL.
          READ TABLE lt_uinfo1 INTO ls_uinfo INDEX 1.
          add_text 'BNAME_DESC' ls_uinfo-bname ls_uinfo-name_text.
        ELSE."User name not found locally,
          "try to get it from remote system

          APPEND ls_uinfo TO lt_uinfo1.
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
            CALL FUNCTION '/PSYNG/SW_USER_INFO'  "#EC SAST_CI_GEN_CHECK
              DESTINATION gt_rfcdest-rfcdest
              EXPORTING
                i_name_only     = 'X'
              TABLES
                sw_uinfo        = lt_uinfo1
           EXCEPTIONS
           system_failure = 1
           communication_failure = 2
           OTHERS = 3.                           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
            READ TABLE lt_uinfo1 INTO ls_uinfo INDEX 1.
            IF NOT ls_uinfo-name_text IS INITIAL.
              add_text 'BNAME_DESC' ls_uinfo-bname ls_uinfo-name_text.
              EXIT.
            ENDIF.
          ENDLOOP.

        ENDIF.
*BOC:HBHALLA(PN-4772)
      ELSE.
        add_text 'BNAME_DESC' ls_uinfo-bname ls_uinfo-name_text.
      ENDIF.
*EOC:HBHALLA(PN-4772)
    ENDLOOP.
  ENDIF.

*--Load user names for non sap

  IF lt_uinfo_en_det[] IS INITIAL.
*BOC:HBHALLA(PN-4772)
    IF p_nabap = 'X'.
      LOOP AT lt_uinfo_en.
        REFRESH lt_uinfo1.
        lt_uinfo1-bname = lt_uinfo_en-bname.
        APPEND lt_uinfo1.
        CALL FUNCTION '/PSYNG/SW_USER_INFO'
          EXPORTING
            i_name_only     = 'X'
          TABLES
            sw_uinfo        = lt_uinfo1.
        IF lt_uinfo1[] IS NOT INITIAL.
          READ TABLE lt_uinfo1 INTO ls_uinfo INDEX 1.
          add_text 'BNAME_DESC' ls_uinfo-bname ls_uinfo-name_text.
        ENDIF.
      ENDLOOP.
    ELSE.
*EOC:HBHALLA(PN-4772)
      IF NOT lt_uinfo_en[] IS INITIAL.

        it_appl-sign = 'I'.
        it_appl-option = 'EQ'.

        it_sysid-sign = 'I'.
        it_sysid-option = 'EQ'.

        lt_sel_users-sign = 'I'.
        lt_sel_users-option = 'EQ'.

        LOOP AT lt_uinfo_en.

          REFRESH lt_uinfo_en_det.

          get_dyn_value 'APPLICATION' <gs_output> it_appl-low.
          get_dyn_value 'RFCDEST' <gs_output> it_sysid-low.
          get_dyn_value 'BNAME'   <gs_output> lt_sel_users-low.

          APPEND it_appl.
          APPEND it_sysid.
          APPEND lt_sel_users.

          CALL FUNCTION '/PSYNG/EX_GET_USERS'
             TABLES
                  it_appl  = it_appl
                  it_sysid = it_sysid
                  it_bname = lt_sel_users
                  et_users = lt_uinfo_en_det.

          CONCATENATE lt_uinfo_en-bname it_appl-low it_sysid-low INTO
                                                      lt_uinfo_en-bname.

          READ TABLE lt_uinfo_en_det INDEX 1.
          IF NOT lt_uinfo_en_det-full_name IS INITIAL.
            add_text 'BNAME_DESC' lt_uinfo_en-bname
                                            lt_uinfo_en_det-full_name.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
*BOC:HBHALLA(PN-4772)
  ELSE.
    LOOP AT lt_uinfo_en_det.
      IF NOT lt_uinfo_en_det-full_name IS INITIAL.
        add_text 'BNAME_DESC' lt_uinfo_en_det-bname
                                        lt_uinfo_en_det-full_name.
      ENDIF.
    ENDLOOP.
  ENDIF.
*EOC:HBHALLA(PN-4772)
*EOC AKUMAR PN3723

*--Load role names for sap
  IF NOT lt_agr_names_sap[] IS INITIAL.
    SELECT agr_name text FROM agr_texts
       INTO CORRESPONDING FIELDS OF TABLE lt_agr_texts
       FOR ALL ENTRIES IN lt_agr_names_sap
       WHERE
       spras = sy-langu AND
       line  = 0 AND
       agr_name = lt_agr_names_sap-table_line.
                                                          "#EC CI_SUBRC
    LOOP AT lt_agr_names_sap.
     READ TABLE lt_agr_texts WITH TABLE KEY agr_name = lt_agr_names_sap.
      IF sy-subrc = 0.
        add_text 'AGR_DESC' lt_agr_names_sap lt_agr_texts-text.
      ELSE."Role name not found locally,
        "try to get it from remote system

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
              i_agr_name = lt_agr_names_sap
            IMPORTING
              e_text     = lt_agr_texts-text
            EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS             = 3.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF NOT lt_agr_texts-text IS INITIAL.
            add_text 'AGR_DESC' lt_agr_names_sap lt_agr_texts-text.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ENDIF.

*---odubey 2022/01/10 EN role text
  IF NOT lt_agr_names_en[] IS INITIAL.
    LOOP AT lt_agr_names_en.
*      get_dyn_value 'APPLICATION' <gs_output> l_appl.
*      get_dyn_value 'RFCDEST' <gs_output> l_system.
*      get_dyn_value 'AGR_NAME'   <gs_output> l_rolid_value.
*      l_rolid.
      CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
          EXPORTING
*            i_rolid                         = l_rolid
            i_rolid_value                   = lt_agr_names_en-rolid
            i_appl                          = lt_agr_names_en-appl
            i_sysid                         = lt_agr_names_en-sysid
         IMPORTING
           es_rolid_value                  = ls_role_value.

      CONCATENATE lt_agr_names_en-rolid
                  lt_agr_names_en-appl
                  lt_agr_names_en-sysid
      INTO l_text_id.
      IF NOT l_text_id IS INITIAL.
        add_text 'AGR_DESC' l_text_id ls_role_value-rdesc.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--Load object names for SAP
  IF NOT lt_obj_names[] IS INITIAL.
    SELECT object ttext FROM tobjt
    INTO CORRESPONDING FIELDS OF TABLE  lt_obj_texts
    FOR ALL ENTRIES IN lt_obj_names
    WHERE
    langu = sy-langu AND
    object = lt_obj_names-object.
                                                          "#EC CI_SUBRC
    LOOP AT lt_obj_names.
      READ TABLE lt_obj_texts
      WITH TABLE KEY object = lt_obj_names-object.
      IF sy-subrc = 0.
        add_text 'OBJCTDESC'  lt_obj_names-object lt_obj_texts-ttext.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--Load function descriptions
  IF NOT lt_func_names[] IS INITIAL.
    SELECT function description FROM /psyng/function
     INTO CORRESPONDING FIELDS OF TABLE lt_func_texts
     FOR ALL ENTRIES IN lt_func_names
     WHERE
     function = lt_func_names-function AND
     vrsio    = sodvrsio.
                                                          "#EC CI_SUBRC
    LOOP AT lt_func_names.
      READ TABLE lt_func_texts
      WITH TABLE KEY function = lt_func_names-function.
      IF sy-subrc = 0.
        add_text 'FUNDESC'  lt_func_names-function
        lt_func_texts-description.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Load tcode descriptions for SAP
  IF NOT lt_tcodes[] IS INITIAL.
    SELECT tcode ttext FROM tstct
     INTO CORRESPONDING FIELDS OF TABLE lt_tcode_texts
     FOR ALL ENTRIES IN lt_tcodes
     WHERE
     sprsl = sy-langu AND
     tcode = lt_tcodes-tcode.
                                                          "#EC CI_SUBRC
    LOOP AT lt_tcodes.
      READ TABLE lt_tcode_texts WITH TABLE KEY tcode = lt_tcodes-tcode.
      IF sy-subrc = 0.
        add_text 'TCODEDESC'  lt_tcodes-tcode lt_tcode_texts-ttext.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Load tcode descriptions for EN
  IF NOT lt_screen[] IS INITIAL.
    l_tabname_usrrt = '/PSYNG/EX_URHDR'.
SELECT usrrt udesc appl sysid FROM (l_tabname_usrrt) "#EC SAST_CI_GEN_CHECK
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
                                                          "#EC CI_SUBRC
*
    LOOP AT lt_screen.
      CONCATENATE lt_screen-usrrt lt_screen-appl lt_screen-sysid
      INTO gt_texts-id.
      READ TABLE lt_screen_texts WITH TABLE KEY
       usrrt = lt_screen-usrrt
       appl  = lt_screen-appl
       sysid = 'ALL'.
      IF sy-subrc = 0.
        add_text 'TCODEDESC'  gt_texts-id lt_screen_texts-udesc.
      ELSE.
        READ TABLE lt_screen_texts WITH TABLE KEY
         usrrt = lt_screen-usrrt
         appl  = lt_screen-appl
         sysid = lt_screen-sysid.
        IF sy-subrc = 0.
          add_text 'TCODEDESC'  gt_texts-id lt_screen_texts-udesc.

        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Load  Fiori Apps descriptions
  IF NOT lt_func_names[] IS INITIAL.
    SELECT functionid tcode fioriid
        FROM /psyng/functtran
        INTO TABLE lt_functtran
        FOR ALL ENTRIES IN lt_func_names
        WHERE functionid EQ lt_func_names-function "id
          AND vrsio      EQ sodvrsio
          AND type       EQ 'F'.
    IF sy-subrc EQ 0 AND NOT lt_functtran[] IS INITIAL.
      SORT lt_functtran BY functionid tcode fioriid.
      DELETE ADJACENT DUPLICATES FROM lt_functtran
      COMPARING functionid tcode fioriid.
      IF NOT lt_functtran[] IS INITIAL.
        SELECT fioriid appname
          FROM /psyng/sw_fioria
          INTO TABLE lt_fioria
          FOR ALL ENTRIES IN lt_functtran
          WHERE fioriid EQ lt_functtran-fioriid.
        IF sy-subrc EQ 0.
          SORT lt_fioria BY fioriid.
          LOOP AT lt_functtran ASSIGNING <fs_functtran>.
            READ TABLE lt_fioria INTO ls_fioria
        WITH TABLE KEY fioriid = <fs_functtran>-fioriid.
            IF sy-subrc EQ 0.
              <fs_functtran>-appname = ls_fioria-appname.
*--             fiori app descriptions can't be just on tcode,
*              needs to be function and tcode
              CONCATENATE
              <fs_functtran>-functionid
              <fs_functtran>-tcode  INTO
              l_fioritcd.
              add_text 'TCODEDESC'  l_fioritcd ls_fioria-appname.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.


ENDFORM.

**********************************************************************
* Add texts to fields of field symbols <gs_output>.
* Text will only be added for those fields present in table
* gt_alv_fieldcat
* gt_alv_fieldcat is a standard table sorted by fieldname
**********************************************************************
FORM add_texts_to_fs.
  DEFINE get_text.
    has_field &1."is this field being used in the alv grid?
    if sy-subrc = 0.
        gt_texts-type = &1.
        get_dyn_value &2 <gs_output> gt_texts-id.
        read table gt_texts with table key
        "read the text from the collected text table
            type = gt_texts-type
            id   = gt_texts-id.
        if sy-subrc = 0.
           dyn_value &1  gt_texts-text <gs_output>.
           "move text to correct output field
        endif.
    endif.
  END-OF-DEFINITION.
  DEFINE get_text_en.
    has_field &1."is this field being used in the alv grid?
    if sy-subrc = 0.
        gt_texts-type = &1.
        get_dyn_value &2 <gs_output> gt_texts-id.
*        concatenate gt_texts-id l_appl l_system into gt_texts-id.
         concatenate gt_texts-id l_appl l_system into gt_texts-id.
        read table gt_texts with table key
        "read the text from the collected text table
            type = gt_texts-type
            id   = gt_texts-id.
        if sy-subrc = 0.
           dyn_value &1  gt_texts-text <gs_output>.
           "move text to correct output field
        endif.
    endif.
  END-OF-DEFINITION.
*--Tcode Texts for Fiori Apps, not based on one field,
*  but concatenation of functionid and tcode
  DATA : l_funid    TYPE /psyng/function,
         l_tcode    TYPE tcode,
         l_text     TYPE string,
         l_fioritcd TYPE string,
         l_appl     TYPE /psyng/application,
         l_bname TYPE /psyng/ex_user_id, "HBHALLA(PN-4772)
         l_system   TYPE /psyng/system.


  get_text :
       'FUNDESC'   'FUNCTIONID'.

  get_dyn_value 'APPLICATION' <gs_output> l_appl.
  IF l_appl = 'SAP'.
*--Load SAP Specific Texts
    get_text :
         'AGR_DESC'  'AGR_NAME',
         'OBJCTDESC' 'OBJCT',
         'TCODEDESC' 'TCODE',
         'BNAME_DESC' 'BNAME'.                              "PN3723
    has_field 'TCODEDESC'.
    IF sy-subrc = 0.
      get_dyn_value 'TCODEDESC' <gs_output> l_text.
      IF l_text IS INITIAL.
        get_dyn_value 'FUNCTIONID' <gs_output> l_funid.
        get_dyn_value 'TCODE'      <gs_output> l_tcode.
        CONCATENATE l_funid l_tcode INTO l_fioritcd.
        READ TABLE gt_texts WITH TABLE KEY
        "read the text from the collected text table
               type = 'TCODEDESC'
               id   = l_fioritcd.
        IF sy-subrc = 0.
          dyn_value 'TCODEDESC'  gt_texts-text <gs_output>.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
*-- Load EN Texts
    get_dyn_value 'BNAME' <gs_output> l_bname.
    get_dyn_value 'RFCDEST' <gs_output> l_system.
    get_text_en :
        'AGR_DESC'  'AGR_NAME' ,
        'OBJCTDESC' 'OBJCT',
        'TCODEDESC' 'TCODE',
        'BNAME_DESC' 'BNAME'.
*BOC:HBHALLA(PN-4772)
  READ TABLE gt_uinfo_remote WITH KEY bname = l_bname rfcdest = l_system
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      get_text : 'BNAME_DESC' 'BNAME'.
    ENDIF.
*EOC:HBHALLA(PN-4772)
  ENDIF.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  HANDLE_NON_ABAP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_non_abap .
  DATA:lt_apphdr   TYPE TABLE OF /psyng/ex_apphdr_st WITH HEADER LINE,
       lt_syshdr   TYPE TABLE OF /psyng/ex_syshdr_st WITH HEADER LINE,
*       lt_syshdr_h TYPE HASHED TABLE OF /psyng/ex_syshdr_st
*                   WITH UNIQUE KEY sysid
*                   WITH HEADER LINE,
       lt_syshdr_h TYPE STANDARD TABLE OF /psyng/ex_syshdr_st
                   WITH HEADER LINE,
       "(++)HBHALLA(PN-18815)(03/04/26)
       l_rfcdest   TYPE rfcdest,
       l_appl      TYPE /psyng/application,
       l_agr_name  TYPE agr_name,
       l_field     TYPE /psyng/ref_key,
       l_element   TYPE /psyng/ref_key,
       l_object    TYPE xuobject,
       l_valfrm    TYPE /psyng/ref_key,
       lt_delete   TYPE TABLE OF sy-tabix WITH HEADER LINE,
       lt_roles_value TYPE TABLE OF /psyng/ex_rolid_value
       WITH HEADER LINE,
       ls_element_value TYPE typ_ref01,
       ls_action_value TYPE typ_ref01.

  CONSTANTS: c_func_en_read_appsys(30) TYPE c VALUE
           '/PSYNG/EX_CR_READ_APPSYS',
      c_fname_get_key_val TYPE rs38l_fnam VALUE '/PSYNG/EN_GET_REF_VAL'.
  IF p_nabap = 'X'."only if non abap selected
*  -- Get all systems and applications
*    CALL FUNCTION '/PSYNG/EX_CR_READ_APPSYS' "HBHALLA
    CALL FUNCTION c_func_en_read_appsys      "#EC PATHLOCK_CI_DYN_ACCES
          TABLES
            it_applications = s_appl
            it_systems      = s_sysid
            et_apphdr       = lt_apphdr
            et_syshdr       = lt_syshdr.
    SORT lt_syshdr BY sysid.
    INSERT LINES OF lt_syshdr INTO TABLE lt_syshdr_h.
*  --Sort the tcode mapping table
    SORT gt_map_tcode_screen BY tcode.

* ---get roleids values
* odubey 2022/01/11
    CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
     TABLES
       it_appl                         = s_appl
       it_sysid                        = s_sysid
       it_rolid                        = lt_rolid
       et_roles_value                  = lt_roles_value
     EXCEPTIONS
       source_rolid_doesnt_exist       = 1
       not_authorized_to_display       = 2
       OTHERS                          = 3.
    IF sy-subrc <> 0.
*     Implement suitable error handling here
    ENDIF.
    SORT lt_roles_value BY appl sysid rolid.
*--get key values for field
    CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
      EXPORTING
        funcname           = c_fname_get_key_val
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.
*      CALL FUNCTION '/PSYNG/EN_GET_REF_VAL' "HBHALLA
      CALL FUNCTION c_fname_get_key_val      "#EC PATHLOCK_CI_DYN_ACCES
              EXPORTING
                i_tabname              =  '/PSYNG/EX_REF02'
                i_get_all_values       =  'X'
              TABLES
                it_key                 =  lt_fields_value.
      SORT lt_fields_value BY ref_key.
*      start of changes by kamalpreet for C1279
*      CALL FUNCTION '/PSYNG/EN_GET_REF_VAL' "HBHALLA
      CALL FUNCTION c_fname_get_key_val      "#EC PATHLOCK_CI_DYN_ACCES
              EXPORTING
                i_tabname              =  '/PSYNG/EX_REF03'
                i_get_all_values       =  'X'
              TABLES
                it_key                 =  lt_elements_value.
      SORT lt_elements_value BY ref_key.
*      end of changes by kamalpreet for C1279

    ENDIF.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      lt_delete = sy-tabix.
      get_dyn_value 'RFCDEST' <gs_output> l_rfcdest.
      READ TABLE lt_syshdr_h WITH KEY sysid = l_rfcdest
      BINARY SEARCH TRANSPORTING ALL FIELDS.
      "(++)HBHALLA(PN-18815)(03/04/26)
      IF sy-subrc = 0.
        get_dyn_value 'OBJCT' <gs_output> l_object.
        IF l_object = 'S_TCODE'.
*           we don't want to see S_TCODE for non abap
          APPEND lt_delete.
        ELSE.
          dyn_value 'APPLICATION'  lt_syshdr_h-appl <gs_output>.
          get_dyn_value 'TCODE'   <gs_output> gt_map_tcode_screen-tcode.
          READ TABLE gt_map_tcode_screen
          WITH KEY tcode = gt_map_tcode_screen-tcode BINARY SEARCH.
          IF sy-subrc = 0.
            dyn_value 'TCODE'  gt_map_tcode_screen-usrrt <gs_output>.
          ENDIF.
        ENDIF.
        get_dyn_value 'APPLICATION'   <gs_output> l_appl.
        get_dyn_value 'AGR_NAME'   <gs_output> l_agr_name.
        READ TABLE lt_roles_value WITH KEY
                  appl = l_appl
                  sysid = l_rfcdest
                  rolid = l_agr_name BINARY SEARCH.
        IF sy-subrc = 0.
*        dyn_value 'AGR_DESC'  lt_roles_value-key_val <gs_output>.
*       C0635 29/03/2022
          dyn_value 'AGR_NAME'  lt_roles_value-key_val <gs_output>.
        ENDIF.
        get_dyn_value 'FIELD'   <gs_output> l_field.
        READ TABLE lt_fields_value WITH KEY
                  ref_key = l_field BINARY SEARCH.
        IF sy-subrc = 0 AND lt_fields_value-key_val IS NOT INITIAL.
    " Commented by kamalpreet for C1279 to show only field value not key
*        CONCATENATE l_field lt_fields_value-key_val INTO
*        lt_fields_value-key_val SEPARATED BY space.
          dyn_value 'FIELD'  lt_fields_value-key_val <gs_output>.
        ENDIF.
*      start of changes by kamalpreet for C1279
        get_dyn_value 'OBJCT'   <gs_output> l_element.
        READ TABLE lt_elements_value INTO ls_element_value WITH KEY
        ref_key  = l_element BINARY SEARCH.
        IF ls_element_value-key_val IS NOT INITIAL AND sy-subrc EQ 0.

          dyn_value 'OBJCT'  ls_element_value-key_val <gs_output>.

        ENDIF.
        CLEAR : ls_element_value,l_element.
*       end of changes by kamalpreet for C1279
*       start of changes by kamalpreet for C1418

        get_dyn_value 'VON'   <gs_output> l_valfrm.
        READ TABLE lt_action_value INTO ls_action_value WITH KEY
        ref_key  = l_valfrm BINARY SEARCH.
        IF ls_action_value-key_val IS NOT INITIAL AND sy-subrc EQ 0.
          dyn_value 'VON'  ls_action_value-key_val <gs_output>.
        ENDIF.
        CLEAR l_valfrm.
*        End of changes by kamalpreet for C1418
      ELSE.
        dyn_value 'APPLICATION'  'SAP' <gs_output>.
      ENDIF.
    ENDLOOP.
    " sort accordingly key_val both elements .
    SORT lt_fields_value BY  key_val.
    SORT lt_elements_value BY key_val.
*   we don't want to see S_TCODE for non abap
    UNASSIGN <gs_output>.
    SORT lt_delete DESCENDING.
    LOOP AT lt_delete.
      DELETE <gt_output> INDEX lt_delete.
    ENDLOOP.
  ELSE.
*--Set application field to SAP for all records
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      dyn_value 'APPLICATION'  'SAP' <gs_output>.
    ENDLOOP.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_HIGHLIGHTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_highlights .
  DATA : l_flag        TYPE flag,
         lt_color_cell TYPE lvc_t_scol,
         ls_color_cell TYPE lvc_s_scol,
         ls_color      TYPE lvc_s_colo.
  IF p_hienhn = 'X' OR pcolor = 'X'.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      IF p_hienhn = 'X'.
        get_dyn_value 'ENHANCED' <gs_output> l_flag.
        IF l_flag = 'X'.
          REFRESH : lt_color_cell.
          ls_color-col = '7'.   "Orange
          ls_color-int = '1'.   "Intensified
          ls_color-inv = '0'.   "Inverse
          ls_color_cell-color = ls_color.
          ls_color_cell-fname = 'CONID'.
          APPEND ls_color_cell TO lt_color_cell.
          ls_color_cell-fname = 'TCODE'.
          APPEND ls_color_cell TO lt_color_cell.
          dyn_value 'COLOR_CELL'  lt_color_cell <gs_output>.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.



FORM rfc_validations.
  DATA : l_continue TYPE flag,
         r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
         WITH HEADER LINE.

  DELETE xusrrfc WHERE    sign = 'E'
                    AND   option = 'CP'
                    AND   low = '*'.

  APPEND LINES OF xusrrfc TO r_rfcs.

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
  r_rfcs-low    = rr_rfc_4.
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

ENDFORM.                    " rfc_validations


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
           WHERE rfcdest IN it_role_rfc.
                                                          "#EC CI_SUBRC
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
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.

      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
*Case 2061 - If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
*            Any rfc destination pointing to the local system will
*            be ignored
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.
ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  CREATE_SORT_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_ALV_SORT  text
*----------------------------------------------------------------------*
FORM create_sort_table.
  DATA : ls_sort TYPE slis_sortinfo_alv.
  DEFINE add_sort.
    read table gt_alv_fieldcat with key fieldname = &1
    binary search transporting no fields.
    if sy-subrc = 0.
*--Add the sort field
      add 1 to ls_sort-spos.
      ls_sort-fieldname = &1.
      ls_sort-up        = 'X'.
      append ls_sort to gt_alv_sort.
    endif.
  END-OF-DEFINITION.

  REFRESH : gt_alv_sort.

  add_sort :
    'BNAME',
    'BNAME_DESC', "PN3723
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
    'CLASS',
    'DEPARTMENT',
*End of Addition <HBHALLA> PN-15675 27/10/2025
    'IMPSORT',
    'IMP',
    'CONID',
    'RISK',
    'DESCRIPTION',
    'FUNCTIONID',
    'FUNDESC',
    'TCODE',
    'TCODEDESC',
    'FIORIID',
    'APPLICATION',
    'RFCDEST',
    'OBJCT',
    'OBJCTDESC',
    'AUTH',
    'FIELD',
    'VON',
    'AGR_NAME',
    'AGR_DESC',
    'COMP_AGR',
    'PROFILE',
    'COMP_PROF',
    'CONTID',
    'MIT_ICON'.
ENDFORM.


FORM alv_top_of_page_prop_rem.
  DATA: header         TYPE slis_t_listheader,
        wa             TYPE slis_listheader,
        alv_grid_titl2 TYPE lvc_title,                "For ALV call
        lf_line(23),
        lf_date(10).
* Body area
  CLEAR wa.
  wa-typ  = 'S'.
  wa-key  = 'Proposed Solution:'(203).
  wa-info =
  'Remove the following roles to remediate the SOD conflict'(201).
  APPEND wa TO header.

  CLEAR wa.
  wa-typ = 'S'.
  IF NOT gf_meddate IS INITIAL.
    wa-key = 'Date range used:'(199).
    WRITE gf_mstdate TO lf_date.
    CONCATENATE lf_date '-' INTO lf_line SEPARATED BY space.
    CLEAR lf_date.
    WRITE gf_meddate TO lf_date.
    CONCATENATE lf_line lf_date INTO lf_line SEPARATED BY space.
    MOVE lf_line TO wa-info.
  ELSE.
    wa-key = 'Date used:'(200).
    WRITE gf_mstdate TO wa-info.
  ENDIF.
  APPEND wa TO header.

  CLEAR wa.
  wa-typ = 'S'.
  wa-key = 'Executed Tcodes:'(202).
  wa-info = gf_funcount.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header
      i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.
FORM alv_top_of_page.

  DATA :
    header          TYPE slis_t_listheader,
    wa              TYPE slis_listheader,
    ls_cfg_set      TYPE /psyng/swcfgset,
    l_str           TYPE string,
    l_int           TYPE i,
    l_exedate       TYPE char10,
    l_exetime(8)    TYPE c,
    c_usercount     TYPE string,
    c_averagecon    TYPE string,
    c_tusercount    TYPE string,
    l_usercount     TYPE i,
    l_averagecon    TYPE i,
    l_conflictcount TYPE i,
    l_conusr        TYPE string,
    l_systemid       TYPE /psyng/sysid.

  STATICS :
  l_msg_displayed  TYPE flag. "HBHALLA

*TITLE AREA
  wa-typ  = 'H'.
  IF shosimp IS INITIAL.
    wa-info = 'SOD Conflict Details : User(s) with SOD conflicts'(053).
  ELSE.
    wa-info = 'SOD Conflict Details : Simplified view'(214).
  ENDIF.
  APPEND wa TO header.
*BELOW AREA.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
                                                          "#EC CI_SUBRC
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*--Configuration Set
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid = cfgset.
                                                          "#EC CI_SUBRC
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
  wa-key = 'User Date & System:'(h10).
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
*  CONCATENATE sy-uname 'on'(h11) l_exedate l_exetime "C0700

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user 'on'(h11) l_exedate l_exetime "C0700
              'in'(h38) l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.


  IF g_usercount > 0.
    l_averagecon   = g_concount / g_usercount.
  ENDIF.
  c_usercount  = g_usercount.
  c_averagecon = l_averagecon.
  c_tusercount = g_totalusercount.
  CONCATENATE  c_tusercount 'User(s) analyzed. Avg'(h16) c_averagecon
               'SOD Conflict(s) in '(h17) c_usercount 'user(s)'(h18)
              INTO wa-info SEPARATED BY space.
  CONDENSE wa-info.

  wa-typ = 'S'.
  wa-key = 'Summary'(h12).
  APPEND wa TO header.

*BOC: HBHALLA
  IF xmc = 'X'.
    PERFORM add_miti_info_to_sumline USING header.
  ENDIF.
*EOC:HBHALLA

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header.

*BOC:;HBHALLA
* --Only output messages for each page when not in background mode.
  IF ( sy-batch  IS INITIAL AND sy-binpt IS INITIAL )
     OR  l_msg_displayed IS INITIAL.

    IF bysimu = 'X' OR byrsimu = 'X'.
      MESSAGE s398(00) WITH
'Number of SOD conflicts found after simulation  :'(210)
g_concount.
    ELSE.
      MESSAGE s398(00) WITH
      'Number of SOD conflicts found  :'(l09) g_concount.
    ENDIF.

    l_msg_displayed = 'X'.
    COMMIT WORK.
  ENDIF.
*EOC:HBHALLA

ENDFORM.



FORM alv_drilldown
    USING
          r_ucomm LIKE sy-ucomm
          rs_selfield TYPE slis_selfield.
*--Respond to Toolbar
  CASE r_ucomm.
    WHEN 'SOD_TREE'.
      PERFORM show_tree_view.
      EXIT.
    WHEN 'EASY'.
      PERFORM populate_avail_ta.
      MOVE rs_selfield TO gs_selfield.
      CALL SCREEN 310 STARTING AT 10 1.
      EXIT.
    WHEN 'SHOW_TEXTS'.
      PERFORM show_texts.
      EXIT.
    WHEN 'HIST'.
      PERFORM populate_avail_ta.
      CALL SCREEN 300 STARTING AT 10 1.
      EXIT.
    WHEN 'SIMP'.
      PERFORM show_simplified_view.
      EXIT.
    WHEN 'TOGGLE_ORG'.
      PERFORM toggle_org_values.
      EXIT.
  ENDCASE.

*--Respond to Drilldown
  CHECK r_ucomm = '&IC1'.
  DATA :
    l_funid        TYPE /psyng/function_id,
    l_appl         TYPE /psyng/application,
    l_sys          TYPE /psyng/rfcdest,
    l_conid        TYPE /psyng/conflict,
    l_tcode        TYPE xutcode,
    l_obj          TYPE xuobject,
    l_fld          TYPE xufield,
    l_hash         TYPE xupname,
    l_srv          TYPE sobj_name,
    l_val          TYPE xuvalue,
    l_riskt        LIKE /psyng/sw_risk-text,
    l_uname        TYPE xubname,
    l_parva        TYPE usr05-parva,
    l_sod          TYPE /psyng/sodvrsio,
    l_mit          TYPE /psyng/contid,
    l_bname        TYPE xubname,
    l_parva_exists LIKE sy-subrc,
    l_rolid_value  TYPE /psyng/key_val,
    ls_roleid      TYPE /psyng/ex_rolhdr_st,
    l_sysid        TYPE /psyng/system,
    ls_element_value TYPE typ_ref01,
    ls_action_value TYPE typ_ref01.


  CONSTANTS:
    lc_service  TYPE xuobject VALUE 'S_SERVICE',
    lc_srv_name TYPE xufield  VALUE 'SRV_NAME'.
  READ TABLE <gt_output> ASSIGNING <gs_output>
   INDEX rs_selfield-tabindex.
  CASE rs_selfield-fieldname.

    WHEN 'MIT_ICON'.
      get_dyn_value  :
       'CONTID'  <gs_output> l_mit,
       'BNAME'   <gs_output> l_bname,
       'CONID'   <gs_output> l_conid.
      IF l_mit IS INITIAL.
        MESSAGE e123 WITH l_bname l_conid.
      ENDIF.
      PERFORM show_mit_details
        USING l_bname l_conid.
      EXIT.

    WHEN 'EXE_USER' .
      IF rs_selfield-value > 0.
        get_dyn_value  :
         'TCODE'  <gs_output>  l_tcode,
         'BNAME'   <gs_output> l_bname.
        PERFORM populate_avail_ta.
        IF g_his_avail_end < h_eddt.
          h_eddt = g_his_avail_end.
        ENDIF.
        IF g_his_avail_beg > h_stdt.
          h_stdt = g_his_avail_beg.
        ENDIF.

        PERFORM show_user_tcode_history
          USING
          l_bname
          l_tcode
          h_stdt
          h_eddt.
      ENDIF.
    WHEN 'CONID'.
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
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
      EXIT.
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
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
      EXIT.
    WHEN 'CONTID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user."sy-uname. C0700
*  -- Get user's default version
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
*  -- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.
    WHEN 'RISK'.
      SELECT SINGLE text INTO l_riskt FROM /psyng/sw_risk
                    WHERE risk = rs_selfield-value.
      CHECK sy-subrc = 0.

      CONCATENATE rs_selfield-value '=' l_riskt INTO l_riskt
                  SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Risk Scenario'(175)
          text_question         = l_riskt
          text_button_1         = 'Ok'(129)
          icon_button_1         = 'ICON_SYSTEM_OKAY'
          text_button_2         = 'Cancel'(122)
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '1'
          display_cancel_button = space.
    WHEN 'VON' OR 'BIS'.
      get_dyn_value  :
       'OBJCT'  <gs_output> l_obj,
       'FIELD'  <gs_output> l_fld,
       'APPLICATION' <gs_output> l_appl.
      IF l_appl <> 'SAP'.
        READ TABLE lt_action_value INTO ls_action_value
           WITH KEY key_val+0(60) = rs_selfield-value BINARY SEARCH.
        IF  ls_action_value-ref_key  IS NOT INITIAL AND sy-subrc EQ 0.
          CONCATENATE ls_action_value-ref_key rs_selfield-value
          INTO rs_selfield-value SEPARATED BY space.


          SUBMIT  /psyng/se_object_drilldown
           WITH r_value = 'X'
           WITH name = rs_selfield-value
           WITH p_appl = l_appl
           AND RETURN.
        ELSE.
         MESSAGE s240(s#) WITH 'There is no more information available'.
        ENDIF.
      ELSE.
        IF l_obj = lc_service AND l_fld = lc_srv_name.
*--Odata Service
          l_hash =    rs_selfield-value.
          CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
            EXPORTING
              i_hashcode      = l_hash
              if_show_message = 'X'
            EXCEPTIONS
              not_found       = 1
              OTHERS          = 2.
          IF sy-subrc = 0.
          ENDIF.
        ELSEIF l_obj = 'S_TCODE' AND l_fld = 'TCD'.
*--Transaction
          get_dyn_value  :
                  'FUNCTIONID'  <gs_output> l_funid,
                  'APPLICATION' <gs_output> l_appl,
                  'RFCDEST'     <gs_output> l_sys.
          SUBMIT  /psyng/se_object_drilldown
           WITH r_tcode  = 'X'
           WITH p_object = 'S_TCODE'
           WITH name     = rs_selfield-value
           WITH p_funid  = l_funid
           WITH p_appl   = l_appl
           AND RETURN.
        ELSE.
*--Other Object
          l_val = rs_selfield-value.
          CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
            EXPORTING
              i_object        = l_obj
              i_field         = l_fld
              i_value         = l_val
              if_show_message = 'X'.
        ENDIF.
      ENDIF.
      EXIT.
    WHEN 'TCODE'.
      get_dyn_value  :
       'FUNCTIONID'  <gs_output> l_funid,
       'APPLICATION' <gs_output> l_appl,
       'RFCDEST'     <gs_output> l_sys.
      SUBMIT  /psyng/se_object_drilldown
       WITH r_tcode  = 'X'
       WITH p_object = 'S_TCODE'
       WITH name     = rs_selfield-value
       WITH p_funid  = l_funid
       WITH p_appl   = l_appl
       WITH p_sys    = l_sys
       WITH p_vrsio  = sodvrsio
       AND RETURN.
      EXIT.
    WHEN 'FIELD'.
*      start of changes by kamalpreet for C1279
      get_dyn_value  :
       'APPLICATION' <gs_output> l_appl.
      IF l_appl NE 'SAP'.
READ TABLE lt_fields_value WITH KEY key_val+0(60) = rs_selfield-value BINARY SEARCH.
        IF lt_fields_value-ref_key IS NOT INITIAL AND sy-subrc EQ 0.
CONCATENATE lt_fields_value-ref_key rs_selfield-value INTO rs_selfield-value SEPARATED BY space.
        ENDIF.
      ENDIF.
*     end of changes by kamalpreet for C1279
      SUBMIT  /psyng/se_object_drilldown
       WITH r_field = 'X'
       WITH name = rs_selfield-value
       WITH p_appl = l_appl
       AND RETURN.
      EXIT.
    WHEN 'BNAME'.
      SUBMIT  /psyng/se_object_drilldown
       WITH r_user = 'X'
       WITH name = rs_selfield-value
       AND RETURN.
      EXIT.
    WHEN 'OBJCT'.
      CLEAR l_appl.
      get_dyn_value  :
      'APPLICATION' <gs_output> l_appl.
*      start of change by kamalpreet for c1279
      IF l_appl NE 'SAP'.
        READ TABLE lt_elements_value
          INTO ls_element_value
          WITH KEY key_val+0(60)  = rs_selfield-value
          BINARY SEARCH.
        IF ls_element_value-ref_key IS NOT INITIAL AND sy-subrc EQ 0  .
CONCATENATE ls_element_value-ref_key rs_selfield-value INTO rs_selfield-value SEPARATED BY space.
        ENDIF.
      ENDIF.
*      end of change by kamalpreet for c1279
      SUBMIT  /psyng/se_object_drilldown
       WITH r_object = 'X'
       WITH name = rs_selfield-value
   WITH p_appl   = l_appl " additon of parameter by kamalpreet for C1279
   AND RETURN.
      EXIT.
    WHEN 'PROFILE' OR 'COMP_PROF'.
      SUBMIT /psyng/se_object_drilldown
       WITH r_profi = 'X'
       WITH name = rs_selfield-value
       AND RETURN.
      EXIT.
    WHEN 'AGR_NAME' OR 'COMP_AGR'.
      get_dyn_value  :
       'RFCDEST'     <gs_output> l_sys,
        'APPLICATION' <gs_output> l_appl.
*---Om 2022/04/07
      l_rolid_value = rs_selfield-value.
      l_sysid = l_sys.
      IF l_appl <> 'SAP'.
        CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
         EXPORTING
           i_rolid_value                   = l_rolid_value
           i_appl                          = l_appl
           i_sysid                         = l_sysid
         IMPORTING
           es_rolid                        = ls_roleid
         EXCEPTIONS
           source_rolid_doesnt_exist       = 1
           not_authorized_to_display       = 2
           OTHERS                          = 3
                  .
        IF sy-subrc <> 0.
* Implement suitable error handling here
        ENDIF.
      ELSE.
        ls_roleid-rolid = l_rolid_value.
      ENDIF.

      SUBMIT /psyng/se_object_drilldown
       WITH r_role = 'X'
       WITH name    = ls_roleid-rolid
       WITH p_appl  = l_appl
       WITH p_sys   = l_sys
       WITH p_rfc   = l_sys
       WITH p_vrsio = sodvrsio
       WITH cfgset  = cfgset
       AND RETURN.
      EXIT.
    WHEN 'ENHANCED'.
      CHECK rs_selfield-value = '1'.
      get_dyn_value  :
      'TCODE'    <gs_output> l_tcode,
      'CONID'    <gs_output> l_conid.
      SUBMIT  /psyng/sw_075
         WITH    vrsio    = sodvrsio
         WITH    s_callin = l_tcode
         WITH    conid    = l_conid AND RETURN.
      EXIT.
  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM advise_syswide_analysis                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM advise_syswide_analysis CHANGING continue .
  DATA: lt_decidetext TYPE TABLE OF tline WITH HEADER LINE,
        lt_decidehtml TYPE TABLE OF htmlline WITH HEADER LINE,
        l_head TYPE thead,
        lt_parmvalues TYPE TABLE OF parmvalues,
        ls_paramvalue TYPE parmvalues,
        l_max_runtime TYPE wpelzeit,
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
              parameter_table = lt_parmvalues.
    READ TABLE lt_parmvalues INDEX 1 INTO ls_paramvalue.
  IF ls_paramvalue-user_value CS 'H' OR ls_paramvalue-user_value CS 'M'.
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
*   I_CODEPAGE               =
        i_header                 = l_head
       i_bgcolor                = '#FEFEEE'
      TABLES
        t_itf_text               = lt_decidetext
        t_html_text              = lt_decidehtml
     EXCEPTIONS
       syntax_check             = 1
       replace                  = 2
       illegal_header           = 3
       OTHERS                   = 4
              .
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

ENDFORM.



*          if i_delete  : if this has a value <> 0,
*          delete the /PSYNG/VRSIO parameter
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  i_delete TYPE sy-subrc.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
        lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
        ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param
    FROM usr05                                       "#EC CI_SEL_NESTED
         WHERE bname = l_uname.
                                                          "#EC CI_SUBRC

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


FORM show_mit_details
  USING
     i_bname TYPE xubname
     i_conid TYPE /psyng/conflict.
  DATA : l_showuser     TYPE flag,
         l_showgroup    TYPE flag,
         l_showrole     TYPE flag,
         lt_mcuser_show LIKE TABLE OF gt_mcuser WITH HEADER LINE.
  CLEAR : l_showuser,l_showgroup,l_showrole,lt_mcuser_show[].
  REFRESH lt_mcuser_show.
  SORT gt_mcuser BY userid conid type from_date contid.
  DELETE ADJACENT DUPLICATES FROM gt_mcuser COMPARING
  userid conid type from_date contid.
  LOOP AT gt_mcuser WHERE userid = i_bname
                   AND conid     = i_conid.
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
*&      Form  HANDLE_MITIGATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_mitigations .
  DATA : l_bname  TYPE xubname,
         l_conid  TYPE /psyng/conflict,
         l_icon   LIKE icon-id,
         l_orgabb TYPE /psyng/dorg_abb, "HBHALLA
         l_conusr TYPE string. "HBHALLA
  IF shosimp = 'X' AND NOT gt_mcuser[] IS INITIAL.
    SORT gt_mcuser BY userid conid contid.
    CLEAR g_mitconcount. "HBHALLA
    CLEAR: l_bname,l_conid,l_orgabb. "HBHALLA
    g_mitconcount = 0.   "HBHALLA
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      get_dyn_value  :
         'BNAME'   <gs_output> l_bname,
         'CONID'   <gs_output> l_conid.
*BOC:HBHALLA
      IF orgchk = 'X'.
        get_dyn_value  :
           'ORG_ABB'   <gs_output> l_orgabb.
        IF l_orgabb = '*'.
          READ TABLE gt_mcuser WITH KEY userid = l_bname
                                        conid  = l_conid
                                        org_abb = ' '
                                        BINARY SEARCH.
          IF sy-subrc = 0.
            l_orgabb = ' '.
          ENDIF.
        ELSEIF l_orgabb = ' '.
          READ TABLE gt_mcuser WITH KEY userid = l_bname
                                        conid  = l_conid
                                        org_abb = '*'
                                        BINARY SEARCH.
          IF sy-subrc = 0.
            l_orgabb = '*'.
          ENDIF.
        ENDIF.
      ENDIF.
*EOC:HBHALLA

      CONCATENATE l_bname l_conid  INTO l_conusr.
*BOC:HBHALLA
      IF orgchk = 'X'.
        READ TABLE gt_mcuser WITH KEY userid = l_bname
                                      conid  = l_conid
                                      org_abb = l_orgabb
                                      BINARY SEARCH.
      ELSE.
        READ TABLE gt_mcuser WITH KEY userid = l_bname
                                      conid  = l_conid
                                      BINARY SEARCH.
      ENDIF.
*EOC:HBHALLA
      IF sy-subrc = 0.
        ON CHANGE OF l_conusr.
          g_mitconcount = g_mitconcount + 1. "HBHALLA
        ENDON.
        dyn_value 'CONTID' gt_mcuser-contid  <gs_output>  .
        CLEAR l_icon.
        CASE gt_mcuser-type.
          WHEN '1'.
            l_icon = '@EK@'.
          WHEN '2'.
            l_icon = '@ID@'.
          WHEN '4'.
            l_icon = '@F8@'.
        ENDCASE.
        dyn_value 'MIT_ICON'   l_icon <gs_output>.
      ENDIF.
    ENDLOOP.
*BOC:HBHALLA
  ELSEIF xmc = 'X' AND NOT gt_mcuser[] IS INITIAL.
    SORT gt_mcuser BY userid conid contid.
    CLEAR g_mitconcount.
    CLEAR: l_bname,l_conid,l_orgabb.
    g_mitconcount = 0.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      get_dyn_value  :
         'BNAME'   <gs_output> l_bname,
         'CONID'   <gs_output> l_conid.
      IF orgchk = 'X'.
        get_dyn_value  :
           'ORG_ABB'   <gs_output> l_orgabb.
        IF l_orgabb = '*'.
          READ TABLE gt_mcuser WITH KEY userid = l_bname
                                        conid  = l_conid
                                        org_abb = ' '
                                        BINARY SEARCH.
          IF sy-subrc = 0.
            l_orgabb = ' '.
          ENDIF.
        ELSEIF l_orgabb = ' '.
          READ TABLE gt_mcuser WITH KEY userid = l_bname
                                        conid  = l_conid
                                        org_abb = '*'
                                        BINARY SEARCH.
          IF sy-subrc = 0.
            l_orgabb = '*'.
          ENDIF.
        ENDIF.
      ENDIF.
      CONCATENATE l_bname l_conid  INTO l_conusr.
      IF orgchk = 'X'.
        READ TABLE gt_mcuser WITH KEY userid = l_bname
                                      conid  = l_conid
                                      org_abb = l_orgabb
                                      BINARY SEARCH.
      ELSE.
        READ TABLE gt_mcuser WITH KEY userid = l_bname
                                      conid  = l_conid
                                      BINARY SEARCH.
      ENDIF.
      IF sy-subrc = 0.
        ON CHANGE OF l_conusr.
          g_mitconcount = g_mitconcount + 1.
        ENDON.
      ENDIF.
    ENDLOOP.
  ENDIF.
*EOC:HBHALLA
ENDFORM.


FORM alv_set_pf_status USING rt_extab TYPE slis_t_extab.
  DATA : "lt_extab TYPE slis_t_extab,
         ls_extab LIKE LINE OF rt_extab.

  IF NOT gf_cfg_set_enabled = 'X' OR mode <> 'DET'.
*--Toggle org and variable elements is only available
*  if configuration set functionality is enabled
    ls_extab-fcode = 'TOGGLE_ORG'.
    APPEND ls_extab TO rt_extab.
  ENDIF.

  DATA: lf_fmname TYPE rs38l_fnam.
* check if TA 2.x+ is installed
  MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.
  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lf_fmname
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* if TA 2.x is not installed, hide "Proposed Remediation" button
    ls_extab-fcode = 'EASY'.
    APPEND ls_extab TO rt_extab.
    ls_extab-fcode = 'HIST'.
    APPEND ls_extab TO rt_extab.
  ENDIF.
  IF p_shhis = 'X'.
    ls_extab-fcode = 'HIST'.
    APPEND ls_extab TO rt_extab.
  ENDIF.
  IF shosimp = 'X'.
**  Hide Simplified View
    ls_extab-fcode = 'SIMP'.
    APPEND ls_extab TO rt_extab.
  ENDIF.
  IF p_shtext = 'X'.
    ls_extab-fcode = 'SHOW_TEXTS'.
    APPEND ls_extab TO rt_extab.
  ENDIF.

  SET PF-STATUS 'SOD_ALV_STATUS' EXCLUDING rt_extab.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_HISTORICAL_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_historical_data.
  CHECK p_shhis = 'X'.
  TYPES: BEGIN OF typ_users,
           rfcdest LIKE rfcdes-rfcdest,
           bname   TYPE bname,
         END OF typ_users.
  DATA: lt_unq_users TYPE SORTED TABLE OF typ_users
        WITH UNIQUE KEY rfcdest bname WITH HEADER LINE.
  DATA: lt_src_users TYPE SORTED TABLE OF typ_users
        WITH UNIQUE KEY rfcdest bname WITH HEADER LINE.
  DATA: lt_users TYPE STANDARD TABLE OF /psyng/sw_sel_opts_xubname
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_tcodes,
           rfcdest LIKE rfcdes-rfcdest,
           tcode   TYPE tcode,
         END OF typ_tcodes.
  DATA: lt_unq_tcodes TYPE SORTED TABLE OF typ_tcodes
        WITH UNIQUE KEY rfcdest tcode WITH HEADER LINE.
  DATA: lt_tcodes TYPE STANDARD TABLE OF /psyng/range_tcode
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_roles,
           rfcdest  LIKE rfcdes-rfcdest,
           agr_name TYPE agr_name,
         END OF typ_roles.
  DATA: lt_unq_roles TYPE SORTED TABLE OF typ_roles
        WITH UNIQUE KEY rfcdest agr_name WITH HEADER LINE.
  DATA: lt_roles TYPE STANDARD TABLE OF /psyng/bc_agr_name
        WITH HEADER LINE.
  DATA: lt_bname TYPE STANDARD TABLE OF /psyng/bc_bname
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_user_role,
           rfcdest  LIKE rfcdes-rfcdest,
           agr_name TYPE agr_name,
           bname    TYPE bname,
           id       TYPE id,
         END OF typ_user_role.
  DATA: lt_user_role TYPE SORTED TABLE OF typ_user_role
        WITH UNIQUE KEY rfcdest agr_name bname
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_role_steps,
           id            TYPE id,
           exe_role_user TYPE bname,
         END OF typ_role_steps.
  DATA: lt_role_steps TYPE SORTED TABLE OF typ_role_steps
        WITH UNIQUE KEY id exe_role_user
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_der_steps,
           id           TYPE id,
           exe_der_user TYPE bname,
         END OF typ_der_steps.
  DATA: lt_der_steps TYPE SORTED TABLE OF typ_der_steps
        WITH UNIQUE KEY id exe_der_user
        WITH HEADER LINE.

  TYPES: BEGIN OF typ_execount,
           rfcdest LIKE rfcdes-rfcdest,
           bname   TYPE bname,
           tcode   TYPE tcode,
           count   TYPE i,
         END OF typ_execount.
  DATA: lt_execount TYPE HASHED TABLE OF typ_execount
        WITH UNIQUE KEY rfcdest bname tcode
        WITH HEADER LINE.

  DATA: lt_dates TYPE STANDARD TABLE OF /psyng/sw_sel_opts_date
        WITH HEADER LINE.

  DATA: lt_dhuc00 TYPE STANDARD TABLE OF /psyng/bc_dhuc00
        WITH HEADER LINE.

  DATA: lt_rfcdests TYPE SORTED TABLE OF /psyng/bc_rfcdest
        WITH UNIQUE KEY rfcdest
        WITH HEADER LINE.

  DATA: lf_fmname     TYPE rs38l_fnam,
        lf_parent_agr TYPE agr_name,
        lf_execounter TYPE i,
        lf_sidclient  TYPE rfcdest.

  DATA: wa_dhuc00 TYPE /psyng/bc_dhuc00.

  DATA: ls_variant TYPE disvariant.
  DATA : ls_print TYPE slis_print_alv.
  DATA: ls_line_count TYPE i,
        ls_role_id    TYPE i.


  REFRESH: lt_dates, lt_tcodes, lt_users,
           lt_unq_tcodes, lt_unq_roles, lt_unq_users, lt_src_users,
           lt_user_role,
           lt_role_steps, lt_der_steps,
           lt_dhuc00, lt_execount,lt_bname.

  CLEAR:   lt_dates, lt_tcodes, lt_users,
           lt_unq_tcodes, lt_unq_roles, lt_unq_users, lt_src_users,
           lt_user_role,
           lt_role_steps, lt_der_steps,
           lt_dhuc00, lt_execount,
           wa_dhuc00,
           lf_fmname, lf_parent_agr, lf_execounter,lt_bname.



  CONCATENATE sy-sysid sy-mandt INTO lf_sidclient.


  lt_dates-sign   = 'I'.
  lt_dates-option = 'BT'.
  lt_dates-low    = h_stdt.
  lt_dates-high   = h_eddt.
  INSERT lt_dates INTO TABLE lt_dates.

* get all unique users, roles, tcodes and RFC destinations
  DATA : l_obj      TYPE xuobject,
         l_rfcdest  TYPE rfcdest,
         l_tcode    TYPE xutcode,
         l_agr_name TYPE agr_name,
         l_bname    TYPE xubname.
  LOOP AT <gt_output> ASSIGNING <gs_output>.
    get_dyn_value  :
       'OBJCT'   <gs_output> l_obj,
       'RFCDEST'  <gs_output> l_rfcdest,
       'TCODE'    <gs_output> l_tcode,
       'AGR_NAME' <gs_output> l_agr_name,
       'BNAME'    <gs_output> l_bname.

    IF l_obj <> 'S_TCODE'.
      IF gf_show_only_stcode = 'X'.
        DELETE <gt_output> INDEX sy-tabix.
      ENDIF.
    ENDIF.
    lt_rfcdests-rfcdest = l_rfcdest.
    INSERT lt_rfcdests INTO TABLE lt_rfcdests.
    lt_unq_tcodes-rfcdest = l_rfcdest.
    lt_unq_tcodes-tcode   = l_tcode.
    INSERT lt_unq_tcodes INTO TABLE lt_unq_tcodes.


    lt_unq_roles-rfcdest  = l_rfcdest.
    lt_unq_roles-agr_name = l_agr_name.
    INSERT lt_unq_roles INTO TABLE lt_unq_roles.

    lt_src_users-rfcdest = l_rfcdest.
    lt_src_users-bname   = l_bname.
    INSERT lt_src_users INTO TABLE lt_src_users.

    READ TABLE lt_user_role WITH TABLE KEY
               agr_name = l_agr_name
               rfcdest  = l_rfcdest
               bname    = l_bname.
    CHECK sy-subrc <> 0.
    lt_user_role-rfcdest  = l_rfcdest.
    lt_user_role-bname    = l_bname.
    lt_user_role-agr_name = l_agr_name.
    ADD 1 TO ls_role_id.
    lt_user_role-id = ls_role_id.
    INSERT lt_user_role INTO TABLE lt_user_role.
  ENDLOOP.
  lt_unq_users[] = lt_src_users[].


  LOOP AT lt_rfcdests.
* if history is requested for all users assigned to this role
    IF h_any = 'X'.
      LOOP AT lt_unq_roles WHERE rfcdest = lt_rfcdests-rfcdest .
        REFRESH: lt_bname.
        IF lt_unq_roles-rfcdest = lf_sidclient.
          CALL FUNCTION '/PSYNG/SW_107'
            EXPORTING
              if_role  = lt_unq_roles-agr_name
            TABLES
              ot_users = lt_bname.
        ELSE.
          READ TABLE gt_rfcdest
          WITH KEY rfcoptions = lt_rfcdests-rfcdest.

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
          CALL FUNCTION '/PSYNG/SW_107'
            DESTINATION gt_rfcdest-rfcdest
            EXPORTING
              if_role  = lt_unq_roles-agr_name
            TABLES
              ot_users = lt_bname
            EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS             = 3.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        ENDIF.

        LOOP AT lt_bname.
          lt_unq_users-bname = lt_bname-bname.
          lt_unq_users-rfcdest = lt_unq_roles-rfcdest.
          INSERT lt_unq_users INTO TABLE lt_unq_users.
          LOOP AT lt_user_role WHERE
                               rfcdest = lt_unq_roles-rfcdest AND
                               agr_name = lt_unq_roles-agr_name .
            lt_role_steps-id = lt_user_role-id.
            lt_role_steps-exe_role_user = lt_bname-bname.
            INSERT lt_role_steps INTO TABLE lt_role_steps.
          ENDLOOP.  "lt_user_role
        ENDLOOP.    "lt_bname
      ENDLOOP.   "lt_unq_roles
    ENDIF.

* if history is requested for everyone in role derivation family
    IF h_all = 'X'.
      LOOP AT lt_unq_roles WHERE rfcdest = lt_rfcdests-rfcdest.
        REFRESH: lt_bname.
        IF lt_unq_roles-rfcdest = lf_sidclient.
          CALL FUNCTION '/PSYNG/SW_108'
            EXPORTING
              if_role  = lt_unq_roles-agr_name
            TABLES
              ot_users = lt_bname.
        ELSE.
          READ TABLE gt_rfcdest
          WITH KEY rfcoptions = lt_rfcdests-rfcdest.
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
          CALL FUNCTION '/PSYNG/SW_108'
            DESTINATION gt_rfcdest-rfcdest
            EXPORTING
              if_role  = lt_unq_roles-agr_name
            TABLES
              ot_users = lt_bname
            EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS             = 3.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        ENDIF.
        LOOP AT lt_bname.
          lt_unq_users-rfcdest = lt_unq_roles-rfcdest.
          lt_unq_users-bname = lt_bname-bname.
          INSERT lt_unq_users INTO TABLE lt_unq_users.
          LOOP AT lt_user_role WHERE
                               rfcdest = lt_unq_roles-rfcdest AND
                               agr_name = lt_unq_roles-agr_name
.
            lt_der_steps-id = lt_user_role-id.
            lt_der_steps-exe_der_user = lt_unq_users-bname.
            INSERT lt_der_steps INTO TABLE lt_der_steps.
          ENDLOOP.  "lt_user_role
        ENDLOOP.  "lt_bname
      ENDLOOP.  "lt_unq_roles
    ENDIF.


    CLEAR:lt_users, lt_tcodes, lt_dhuc00, lt_execount.
    REFRESH:lt_users, lt_tcodes, lt_dhuc00, lt_execount.

    lt_users-sign = 'I'.
    lt_users-option = 'EQ'.
    LOOP AT lt_unq_users WHERE rfcdest = lt_rfcdests-rfcdest.
      IF sy-tabix <= 5000.
        lt_users-low = lt_unq_users-bname.
        INSERT lt_users INTO TABLE lt_users.
      ELSE.
        MESSAGE i398(00) WITH text-213.
        EXIT.
      ENDIF.
    ENDLOOP.

    lt_tcodes-sign = 'I'.
    lt_tcodes-option = 'EQ'.
    LOOP AT lt_unq_tcodes WHERE rfcdest = lt_rfcdests-rfcdest.
      lt_tcodes-low = lt_unq_tcodes-tcode.
      INSERT lt_tcodes INTO TABLE lt_tcodes.
    ENDLOOP.

*get tcode execution history for users
    CLEAR lf_fmname.
    MOVE '/PSYNG/BC_USRHIS_018' TO lf_fmname.
    IF lt_rfcdests-rfcdest = lf_sidclient.  "local
*      CALL FUNCTION '/PSYNG/BC_USRHIS_018' "HBHALLA
      CALL FUNCTION lf_fmname                "#EC PATHLOCK_CI_DYN_ACCES
              TABLES
                it_users  = lt_users
                it_date   = lt_dates
                it_tcode  = lt_tcodes
                ot_dhuc00 = lt_dhuc00.
    ELSE.
      READ TABLE gt_rfcdest WITH KEY rfcoptions = lt_rfcdests-rfcdest.
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
      CALL FUNCTION '/PSYNG/BC_USRHIS_018' "HBHALLA
"FM = /PSYNG/BC_USRHIS_018
        DESTINATION gt_rfcdest-rfcdest
        TABLES
          it_users  = lt_users
          it_date   = lt_dates
          it_tcode  = lt_tcodes
          ot_dhuc00 = lt_dhuc00
      EXCEPTIONS
        system_failure = 1
        communication_failure = 2
        OTHERS = 3.                              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ENDIF.

    CHECK NOT lt_dhuc00[] IS INITIAL.

* remove unnecessary data in an effort to increase performance of sort
    wa_dhuc00-mandt = space.                     "#EC SAST_CI_GEN_CHECK
    wa_dhuc00-startdate = space.
    wa_dhuc00-starttime = space.
    MODIFY lt_dhuc00 FROM wa_dhuc00
           TRANSPORTING mandt startdate starttime
           WHERE account NE space.
    SORT lt_dhuc00 BY account tcode.
    LOOP AT lt_dhuc00.
*--DHORIONS 2014/04/22 : We are only interested in dialog steps,
*             not insert/delete/update
      IF lt_dhuc00-insrec = 0 AND
         lt_dhuc00-updrec = 0 AND
         lt_dhuc00-delrec = 0.
        ADD 1 TO lt_execount-count.
      ENDIF.
      AT END OF tcode.
        lt_execount-rfcdest = lt_rfcdests-rfcdest.
        lt_execount-bname = lt_dhuc00-account.
        lt_execount-tcode = lt_dhuc00-tcode.
        INSERT lt_execount INTO TABLE lt_execount.
        CLEAR lt_execount-count.
      ENDAT.
    ENDLOOP.
    FREE: lt_dhuc00.
    LOOP AT <gt_output> ASSIGNING <gs_output>.
      get_dyn_value  :
     'OBJCT'   <gs_output> l_obj,
     'RFCDEST'  <gs_output> l_rfcdest,
     'TCODE'    <gs_output> l_tcode,
     'AGR_NAME' <gs_output> l_agr_name,
     'BNAME'    <gs_output> l_bname.
*     in simplified mode, there may not be a S_TCODE entry
    IF ( l_obj     = 'S_TCODE' OR ( h_tcdo = 'X' AND mode = 'SIMPLE' ) )
       AND
       l_rfcdest = lt_rfcdests-rfcdest.
        IF h_usr = 'X'.
          READ TABLE lt_execount
                     WITH TABLE KEY rfcdest = l_rfcdest
                                      bname = l_bname
                                      tcode = l_tcode.
          IF sy-subrc = 0.
            dyn_value 'EXE_USER'  lt_execount-count <gs_output>.
          ELSE.
            dyn_value 'EXE_USER'  0 <gs_output>.
          ENDIF.
        ENDIF.
        READ TABLE lt_user_role
               WITH TABLE KEY rfcdest = lt_rfcdests-rfcdest
                                bname = l_bname
                             agr_name = l_agr_name.
        CHECK sy-subrc = 0.

        IF h_any = 'X'.
          CLEAR lf_execounter.
          LOOP AT lt_role_steps WHERE id = lt_user_role-id.
            READ TABLE lt_execount WITH TABLE KEY
                       rfcdest = lt_rfcdests-rfcdest
                       bname = lt_role_steps-exe_role_user
                       tcode = l_tcode.
            CHECK sy-subrc = 0 AND lt_execount-bname <> l_bname.
            ADD lt_execount-count TO lf_execounter.
          ENDLOOP.  "lt_role_steps
          IF sy-subrc = 0.
            dyn_value 'EXE_ROLE'  lf_execounter <gs_output>.
          ELSE.
            dyn_value 'EXE_ROLE'  0 <gs_output>.
          ENDIF.
        ENDIF.
        IF h_all = 'X'.
          CLEAR lf_execounter.
          LOOP AT lt_der_steps WHERE id = lt_user_role-id.
            READ TABLE lt_execount WITH TABLE KEY
                       rfcdest = lt_rfcdests-rfcdest
                       bname = lt_der_steps-exe_der_user
                       tcode = l_tcode.
            CHECK sy-subrc = 0 AND lt_execount-bname <> l_bname.
            ADD lt_execount-count TO lf_execounter.
          ENDLOOP.  "lt_der_steps
          IF sy-subrc = 0.
*            outputdet4-exe_der = lf_execounter.
* since ANY users are also included in derived roles' user list,
*             we need
* to remove the ANY count from derived count
            DATA : l_tmp TYPE i.
            get_dyn_value  : 'EXE_ROLE'   <gs_output> l_tmp.
            lf_execounter = lf_execounter - l_tmp.
            dyn_value 'EXE_DER'  lf_execounter <gs_output>.
          ELSE.
            dyn_value 'EXE_DER'  0 <gs_output>.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDFORM.
FORM populate_avail_ta.
  CONSTANTS: lc_meth_g(40)     TYPE c VALUE '/PSYNG/BC_DHUC12',
             lc_meth_c(40)     TYPE c VALUE '/PSYNG/BC_DHUC11',
             lc_tab_hiscfg(20) TYPE c VALUE '/PSYNG/BC_HISCFG',
             lc_tab_dhcudi(20) TYPE c VALUE '/PSYNG/BC_DHCUDI'.

  CONSTANTS:lf_his_date_fm TYPE rs38l-name VALUE '/PSYNG/BC_USRHIS_029'.

  DATA: l_cudc      TYPE /psyng/bc_cudc,
        l_table(40) TYPE c,
        l_meth_type TYPE c.

* Set defaults
  gf_his_user         = 'X'.
  gf_show_only_stcode = 'X'.


* check to see if data has already been collected previously
  CHECK g_his_begda IS INITIAL.
** History dates can be calculated using FM

  CALL FUNCTION 'FUNCTION_EXISTS'
    EXPORTING
      funcname           = lf_his_date_fm
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc = 0.

    CALL FUNCTION lf_his_date_fm             "#EC PATHLOCK_CI_DYN_ACCES
      IMPORTING
        e_startdate = g_his_avail_beg
        e_enddate   = g_his_avail_end.
  ENDIF.

  g_his_endda         = g_his_avail_end.
  g_his_begda         = g_his_avail_end - 30.
ENDFORM.                    " populate_avail_ta
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0300  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0300 INPUT.
  DATA : lt_params TYPE TABLE OF rsparams WITH HEADER LINE.
  FIELD-SYMBOLS : <param> TYPE rsparams.
  CASE sy-ucomm.
    WHEN 'OK'.
      CHECK gf_his_user = 'X' OR gf_his_any = 'X' OR gf_his_all ='X'.
*--Submit current report with the same parameters,
*      but include the historical data
      CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
        EXPORTING
          i_repid           = g_program
          if_no_logging     = 'X'
          if_ignore_initial = ''
        TABLES
          et_params         = lt_params.

      DEFINE set_param.
        read table lt_params assigning <param> with key selname = &1.
       if sy-subrc = 0.
          <param>-low = &2.
       else.
         lt_params-selname = &1.
         lt_params-low     = &2.
         lt_params-high    = &3.
         lt_params-kind    = &4.
         lt_params-sign    = &5.
         lt_params-option  = &6.
         append lt_params.
       endif.
      END-OF-DEFINITION.
      set_param :
        'P_SHHIS' 'X'                 '' 'P' 'I' 'EQ',
        'H_ANY'   gf_his_any          '' 'P' 'I' 'EQ',
        'H_USR'   gf_his_user         '' 'P' 'I' 'EQ',
        'H_ALL'   gf_his_all          '' 'P' 'I' 'EQ',
        'H_STDT'  g_his_begda         '' 'P' 'I' 'EQ',
        'H_EDDT'  g_his_endda         '' 'P' 'I' 'EQ',
        'H_TCDO'  gf_show_only_stcode '' 'P' 'I' 'EQ'.
      SUBMIT (g_program) WITH SELECTION-TABLE lt_params AND RETURN.
                                             "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(11/12/24)

*--Subbmit report with showing the history
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0300  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0300 OUTPUT.
  SET PF-STATUS 'OKCANC'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0310  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0310 INPUT.
  CASE sy-ucomm.
    WHEN 'OK'.
      PERFORM propose_remediation.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.

MODULE status_400 OUTPUT.
  SET TITLEBAR '400'.
  SET PF-STATUS '400'.
ENDMODULE.

MODULE init_editor400 OUTPUT.
  DATA: meditor_container TYPE REF TO cl_gui_custom_container.
  DATA: mtext_editor TYPE REF TO cl_gui_textedit.
  DATA: lc_html_viewer TYPE REF TO cl_gui_html_viewer.
  DATA: m_editor_text(132) TYPE c OCCURS 0,
        l_url              TYPE epssurl.

*  CONCATENATE sy-uname 'SWWARNING' sy-uzeit INTO l_url. "C0700
  CONCATENATE g_current_user 'SWWARNING' sy-uzeit INTO l_url. "C0700
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
*       LIFETIME           =
*       SAPHTMLP           =
*       UIFLAG             =
*       NAME               =
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
*     TYPE                 = 'text'
*     SUBTYPE              = 'html'
*     SIZE                 = 0
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
*     FRAME                  =
*     IN_PLACE               = ' X'
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
ENDMODULE.

MODULE user_command_0400 INPUT.
  CALL METHOD lc_html_viewer->finalize.

  CALL METHOD meditor_container->free.
  FREE : meditor_container, lc_html_viewer.

  LEAVE TO SCREEN 0.

ENDMODULE.

INCLUDE /psyng/sodreport_org_usr_cf01.
*INCLUDE /psyng/z_sodreport_org_45_cf01.

INCLUDE /psyng/sodreport_org_usr_pf01.
*INCLUDE /psyng/z_sodreport_org_45_pf01.

INCLUDE /psyng/sodreport_org_usr_sf01.
*INCLUDE /psyng/z_sodreport_org_45_sf01.
*&---------------------------------------------------------------------*
*&      Form  ADD_MITI_INFO_TO_SUMLINE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_HEADER  text
*----------------------------------------------------------------------*
FORM add_miti_info_to_sumline USING p_header TYPE slis_t_listheader..

  DATA:lf_tot_confsc(8) TYPE c,   "total conflicts in char
       lf_tot_mitsc(8)  TYPE c,    "total mitigations in char
       wa               TYPE slis_listheader,
       l_mit            TYPE /psyng/contid,
       l_prv_mit        TYPE /psyng/contid,
       l_conid          TYPE /psyng/conflict,
       alv_grid_titl2   TYPE lvc_title.

  WRITE g_concount TO lf_tot_confsc.
  WRITE g_mitconcount TO lf_tot_mitsc.

  CONCATENATE lf_tot_confsc text-094 lf_tot_mitsc text-095
              INTO alv_grid_titl2 SEPARATED BY space.

  wa-typ = text-073.
  wa-key = text-h21.
  wa-info = alv_grid_titl2.
  APPEND wa TO p_header.

ENDFORM.
