*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_104
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_104 MESSAGE-ID /psyng/sw.
TABLES: /psyng/conflict."SW: Conflict Header
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.

TYPE-POOLS: slis.
CONSTANTS: max_wp TYPE i VALUE '4'.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME'.
DATA: g_agrname_dtlclk TYPE agr_define-agr_name,
      g_role_popup     TYPE agr_define-agr_name,
      gf_org_field type flag. "AKUMAR OPL645

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
TYPES: BEGIN OF t_faobj_tree,
         object   TYPE /psyng/faobj2-object,
         otext    TYPE tobjt-ttext,
         auth     TYPE agr_1251-auth,
         onode    TYPE i,
         anode    TYPE i,
         field    TYPE /psyng/faobj2-field,
         ddtext   TYPE dd04t-ddtext,
         val_from TYPE /psyng/faobj2-val_from,
         val_to   TYPE /psyng/faobj2-val_to,
         sel      TYPE c,
         rec_num  TYPE i,
       END OF t_faobj_tree.

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
DATA: BEGIN OF gt_output_detail OCCURS 0,
        type(10)      TYPE c,
        bname         LIKE usr02-bname,
        agr_name      LIKE agr_define-agr_name,  "composite role
        isort         TYPE i,
        imp           LIKE /psyng/conflict-imp,
        impsort       TYPE /psyng/sw_adv_simu_outputdet_u-impsort,
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
        appl          TYPE /psyng/ex_caobj_lock-appl,
        org_type      TYPE i,
        comp_agr      LIKE agr_define-agr_name,
        profile       LIKE agr_prof-profile,
        simu          TYPE c,
        enhanced      TYPE c, "flag for enhanced ruleset

        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
      END OF gt_output_detail.
DATA : gs_output_detail LIKE LINE OF gt_output_detail.
DATA : g_conflictcount_usr  TYPE i,
       g_conflictcount_role TYPE i.
DATA: program         LIKE sy-repid.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort              TYPE slis_sortinfo_alv.
DATA: gt_advanced_role_sim   TYPE TABLE OF agr_1251 WITH HEADER LINE,
      gt_advanced_role_sim_c TYPE TABLE OF agr_1251 WITH HEADER LINE,
      gt_output              TYPE TABLE OF /psyng/sw_adv_simu_output
                           WITH HEADER LINE,
      gt_useroutput          TYPE TABLE OF /psyng/sw_outputdet3
                           WITH HEADER LINE,
     gt_useroutput_alv      TYPE TABLE OF /psyng/sw_adv_simu_outputdet_u
                          WITH HEADER LINE,
     gt_roleoutput          TYPE TABLE OF /psyng/sw_out_routdet3
                          WITH HEADER LINE,
     gt_roleoutput_bsimu      TYPE TABLE OF /psyng/sw_out_routdet3
                          WITH HEADER LINE,
     gt_roleoutput_asimu     TYPE TABLE OF /psyng/sw_out_routdet3
                          WITH HEADER LINE,
     gt_roleoutput_alv      TYPE TABLE OF /psyng/sw_adv_simu_outputdet_r
                          WITH HEADER LINE,
     gt_croleoutput_alv    TYPE TABLE OF /psyng/sw_adv_simu_outputdet_r,
     "Added by AKUMAR for OPL568
     gt_faobj_tree          TYPE t_faobj_tree OCCURS 0 WITH HEADER LINE,
     g_rolename             LIKE agr_define-agr_name,
     g_ok_code              LIKE sy-ucomm,
     gt_imp                 TYPE TABLE OF /psyng/sw_sel_opts_imp,
     gt_conid               TYPE TABLE OF /psyng/sw_sel_opts_conid
                          WITH HEADER LINE,
     gt_srole               TYPE TABLE OF /psyng/range_agr_name
                          WITH HEADER LINE,
     gt_crole               TYPE TABLE OF /psyng/range_agr_name
                          WITH HEADER LINE,
     gt_bname               TYPE TABLE OF /psyng/range_bname
                          WITH HEADER LINE,
     gt_results_user        TYPE TABLE OF /psyng/sw_sod_output_org,
     gt_results_role        TYPE TABLE OF /psyng/sw_out_routput,
     gt_enh_users           TYPE TABLE OF /psyng/sw_enh_usr_con,
     gt_roles_to_analyze    TYPE TABLE OF /psyng/range_agr_name WITH
HEADER LINE,
     gf_simu_role.

DATA : gt_comp_roles      TYPE TABLE OF agr_agrs WITH HEADER LINE,
       gf_cfg_set_enabled TYPE flag,
       g_warning_msg(1)   TYPE c,
       g_preconfig        TYPE /psyng/swcfgset-setid,
          l_system_msg(72) TYPE c..

DATA : gt_results_user_before TYPE TABLE OF /psyng/sw_sod_output_org
                              WITH HEADER LINE,
       gt_results_user_after  TYPE TABLE OF /psyng/sw_sod_output_org
                              WITH HEADER LINE,
       ls_output              TYPE /psyng/sw_sod_output_org,
       gt_results_role_before TYPE TABLE OF /psyng/sw_out_routput WITH
HEADER LINE,
       gt_results_role_after  TYPE TABLE OF /psyng/sw_out_routput WITH
HEADER LINE,
       ls_output_role         TYPE /psyng/sw_out_routput.

DATA : i_composite TYPE flag,
       gv_i_single TYPE flag,
       g_dynnr     LIKE sy-dynnr.

DATA : lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
       lt_func         TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
       lt_faobj        TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
       lf_set_invalid  TYPE flag,
       lf_set_nocover  TYPE flag,
       lf_set_mismatch TYPE flag,
       lt_unique_roles    type table of usla04,"HBHALLA(13/02/25)
       ls_unique_roles    type          usla04,"HBHALLA(13/02/25)
   gs_variant      TYPE disvariant, "Changes by RGUPTA on 25th Nov, 2021
   g_current_user  TYPE sy-uname. "C0700
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      alv_grid_titl   TYPE lvc_title.
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv
                      WITH HEADER LINE.
DATA: gt_filter_role_detail TYPE slis_t_filter_alv,
      gf_org_fields_display TYPE flag VALUE 'X',
      gt_filter_user_detail TYPE slis_t_filter_alv,
      gf_org_fields_user_display TYPE flag VALUE 'X',
      gt_filter_mix_detail TYPE slis_t_filter_alv,
      gf_org_fields_mix_display TYPE flag VALUE 'X',
      gf_sum_to_det TYPE flag,
      gf_advsimu_org_fullauth TYPE /psyng/param_value.

DATA: gf_user_det      TYPE flag,
      gf_role_det      TYPE flag,
      gf_user_role_det TYPE flag.

FIELD-SYMBOLS: <res_user> TYPE /psyng/sw_sod_output_org,
               <res_role> TYPE /psyng/sw_out_routput.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t00.
PARAMETERS: p_vrsio LIKE /psyng/conflict-vrsio MEMORY ID /psyng/vrsio.
PARAMETERS : cfgset   TYPE /psyng/seconfid.
SELECT-OPTIONS: s_imp FOR /psyng/conflict-imp.
PARAMETERS: p_orgchk AS CHECKBOX,
            p_shomit AS CHECKBOX,
            p_hilite AS CHECKBOX,
            excl_er  AS CHECKBOX DEFAULT ' '.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance.
SELECTION-SCREEN COMMENT 3(29) text-027 FOR FIELD p_enhanc.
PARAMETERS p_hienhn AS CHECKBOX.
SELECTION-SCREEN COMMENT 35(45) text-028 FOR FIELD p_hienhn.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blki WITH FRAME TITLE text-091.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_srole AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(25) text-c00 FOR FIELD p_srole.
SELECT-OPTIONS: s_srole FOR g_rolename.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_crole AS CHECKBOX.
SELECTION-SCREEN COMMENT 3(25) text-c01 FOR FIELD p_crole.
SELECT-OPTIONS: s_crole FOR g_rolename.
SELECTION-SCREEN END OF LINE.


SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_user AS CHECKBOX USER-COMMAND usr.
SELECTION-SCREEN COMMENT 3(25) text-c02 FOR FIELD p_user.
SELECT-OPTIONS: s_user FOR /psyng/conflict-owner.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK blki.

*SELECTION-SCREEN BEGIN OF BLOCK out_o WITH FRAME.
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
*selection-SCREEN end of BLOCK out_o .
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME TITLE text-t13.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0' MODIF ID exe.

SELECTION-SCREEN: COMMENT 3(65) text-008
                                    MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : defgrp TYPE flag  RADIOBUTTON GROUP ppro DEFAULT 'X'
                                    MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-090 FOR FIELD defgrp
                                    MODIF ID exe.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : specgrp TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-089 FOR FIELD specgrp
                                   MODIF ID exe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pgroup TYPE rzlli_apcl MODIF ID exe.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS : specsrv TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-088 FOR FIELD specsrv
                                   MODIF ID exe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pserver LIKE msxxlist-name MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  30(20) text-002 USER-COMMAND gpsv
                                       MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
PARAMETERS : upp TYPE i                MODIF ID exe.
SELECTION-SCREEN: END OF BLOCK exe_o.


PARAMETERS: p_agrnam LIKE agr_define-agr_name NO-DISPLAY,
            p_cagr   LIKE agr_define-agr_name NO-DISPLAY.

*------------------------ START-OF-SELECTION --------------------------*
INITIALIZATION.
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
*    IMPORT gt_advanced_role_sim FROM DATABASE moni(db) ID 'ADVSIM'.
*    IMPORT gt_faobj_tree FROM DATABASE moni(db) ID 'FAOBJ'.
  IMPORT gt_advanced_role_sim FROM MEMORY ID 'ADVSIM'.
  IMPORT gt_faobj_tree FROM MEMORY ID 'FAOBJ'.
*    FREE MEMORY ID 'FAOBJ'.
*    FREE MEMORY ID 'ADVSIM'.
  PERFORM get_initial_config.
  PERFORM exelog.

*---check if ADVSIMU_ORG_FULLAUTH is enabled
  se_config_param 'ADVSIMU_ORG_FULLAUTH'  gf_advsimu_org_fullauth.

**--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
*    IF cfgset IS INITIAL.
**--   default to the latest published configuration set (highest nr)
*      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
*           EXPORTING
*                i_vrsio      = 'X'
*                i_cfgvrsio   = p_vrsio
*           IMPORTING
*                e_config_set = cfgset.
*    ENDIF.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.

  g_ok_code = 'CRET'.
  EXPORT g_ok_code TO MEMORY ID 'OK_CODE'.
*  Om 17/05/2023
  IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
    CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      EXPORTING
        i_vrsio      = 'X'
        i_cfgvrsio   = p_vrsio
      IMPORTING
        e_config_set = cfgset.
  ENDIF.
*  End

AT SELECTION-SCREEN.
  PERFORM check_input.

  IF NOT gf_cfg_set_enabled IS INITIAL .
    IF sy-ucomm IS INITIAL .
*--Check Config Set
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid         = cfgset
          i_vrsio         = p_vrsio
          if_show_warning = 'X'
          if_local_system = 'X'.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pserver.
  PERFORM disp_total_servers_for_sel.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pgroup.
  PERFORM disp_total_server_groups.

AT SELECTION-SCREEN OUTPUT.

  IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
    CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      EXPORTING
        i_vrsio      = 'X'
        i_cfgvrsio   = p_vrsio
      IMPORTING
        e_config_set = cfgset.
  ENDIF.

  LOOP AT SCREEN.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND screen-name CS 'CFGSET'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.

    CASE screen-name.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          screen-input = 1.
          p_hienhn = 'X'.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'EXCL_ER'.
        IF p_user <> 'X'.
          CLEAR excl_er.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'P_HILITE'.
        IF shodet = 'X'.
          screen-input = 0.
          CLEAR p_hilite.
        ELSE.
          screen-input = 1.
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
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  DATA: lt_roles_simulated TYPE TABLE OF /psyng/range_agr_name,
        ls_roles_simulated TYPE /psyng/range_agr_name.
  program = sy-repid.
  exelog sy-repid ''.
* BOC by RGUPTA on 25th Nov, 2021
  gs_variant-report = sy-repid.
  gs_variant-handle = '0000'.
* EOC by RGUPTA on 25th Nov, 2021
  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
        i_setid            = cfgset
        i_vrsio            = p_vrsio
        if_show_warning    = 'X'
        if_local_system    = 'X'
      IMPORTING
        ef_wrong_version   = lf_set_invalid
        ef_missing_system  = lf_set_nocover
        ef_system_mismatch = lf_set_mismatch.
    IF lf_set_invalid  = 'X' OR
       lf_set_nocover  = 'X' .
      EXIT.
    ENDIF.
  ENDIF.


  CLEAR : g_conflictcount_usr,g_conflictcount_role.
  CLEAR g_warning_msg.
* Get data from function SW_080
*  IMPORT gt_advanced_role_sim FROM DATABASE moni(db) ID 'ADVSIM'.

*BOC:HBHALLA (13/02/25)(PN-11674)
 LOOP AT gt_advanced_role_sim.
   AT NEW agr_name.
    ls_unique_roles-agr_name = gt_advanced_role_sim-agr_name.
    append ls_unique_roles to lt_unique_roles.
    clear ls_unique_roles.
   ENDAT.
 ENDLOOP.



  call function '/PSYNG/PROF_AUTH_CONCAT'
    tables
      it_unique_roles = lt_unique_roles
      et_auths        = gt_advanced_role_sim
    exceptions
      others          = 1.
  if sy-subrc <> 0.
    case sy-subrc.
      when others.
        message e002(/psyng/sw) with 'Unknown Error'(t03).
    endcase.
  endif.

 refresh lt_unique_roles.
*EOC:HBHALLA (13/02/25)(PN-11674)

  FIELD-SYMBOLS : <auth> TYPE agr_1251.
  ls_roles_simulated-sign   = 'I'.
  ls_roles_simulated-option = 'EQ'.
  LOOP AT gt_advanced_role_sim ASSIGNING <auth>.
    IF <auth>-mandt IS INITIAL.
      <auth>-mandt = sy-mandt.
    ENDIF.
    ls_roles_simulated-low = <auth>-agr_name.
    APPEND ls_roles_simulated TO lt_roles_simulated.
  ENDLOOP.
  SORT lt_roles_simulated.
  DELETE ADJACENT DUPLICATES FROM lt_roles_simulated
  COMPARING ALL FIELDS.
*--Get the name of the simulated role
*  READ TABLE gt_advanced_role_sim INDEX 1.
  LOOP AT lt_roles_simulated INTO ls_roles_simulated.
    AT NEW low.
*  IF sy-subrc = 0.
     g_rolename = ls_roles_simulated-low."gt_advanced_role_sim-agr_name.
*  ENDIF.

*--Find impacted Single Roles
      IF p_srole = 'X'.
*     i_single = 'X'.
        PERFORM find_impacted_single_roles
          TABLES s_srole
                 gt_srole
          USING  g_rolename.

*--Apply the role changes to the derived roles
        IF NOT gt_srole[] IS INITIAL.
          PERFORM apply_adv_sim_to_derived
            TABLES
              gt_advanced_role_sim
              gt_srole
            USING g_rolename.
        ENDIF.
      ENDIF.

*--Find impacted Composite Roles
      IF p_crole = 'X'.
*  i_composite = 'X'.
        PERFORM find_impacted_composite_roles
          TABLES
                 s_crole
                 gt_crole
          USING  g_rolename.
      ENDIF.

*--Find impacted Users
      IF p_user = 'X'.
        PERFORM find_impacted_users
          TABLES
                  s_user
                  gt_bname
                  gt_advanced_role_sim
          USING
                  g_rolename.
      ENDIF.
    ENDAT.
  ENDLOOP.
** Conflicts on the basis of selection screen inputs
  IF NOT s_imp[] IS INITIAL.
    gt_conid-sign   = 'I'.
    gt_conid-option = 'EQ'.
    SELECT conid INTO gt_conid-low FROM /psyng/conflict
           WHERE vrsio  = p_vrsio
             AND   imp IN s_imp.
      APPEND gt_conid.
    ENDSELECT.
    IF sy-subrc NE 0.
      MESSAGE s150(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  IF gt_srole[] IS INITIAL
  AND gt_crole[] IS INITIAL
  AND gt_bname[] IS INITIAL.
    MESSAGE s002 WITH 'No impacted users or roles found'.
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF shosum EQ 'X'.
*--Analyze impacted users
    IF p_user = 'X'.
      IF gt_bname[] IS INITIAL.
        MESSAGE s002 WITH 'No impacted users found'(000).
      ELSE.

*-- Before Analysis
        CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
          EXPORTING
            i_org_check          = p_orgchk
            i_vrsio              = p_vrsio
            i_config_set         = cfgset
            i_shomit             = p_shomit
            i_enh                = p_enhanc
            i_hienh              = p_hienhn
            i_xstb               = 'X'
            i_xstb_func          = 'X'
            i_output             = 'X'
            i_advanced_role_simu = 'X'
            i_analyze_sap_all    = 'X'
            i_wp                 = wp
            i_pserver            = pserver
            i_max_upp            = upp
            i_exclude_er_roles   = excl_er
            i_org_field          = gf_org_field "AKUMAR OPL645
          TABLES
            it_users             = gt_bname
            it_confs             = gt_conid
            et_outputdet         = gt_results_user_before
            et_enh_con           = gt_enh_users.
*                it_advanced_role_simu = gt_advanced_role_sim.

*-- After Analysis
        CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
          EXPORTING
            i_org_check           = p_orgchk
            i_vrsio               = p_vrsio
            i_config_set          = cfgset
            i_shomit              = p_shomit
            i_enh                 = p_enhanc
            i_hienh               = p_hienhn
            i_xstb                = 'X'
            i_xstb_func           = 'X'
            i_output              = 'X'
            i_advanced_role_simu  = 'X'
            i_analyze_sap_all     = 'X'
            i_wp                  = wp
            i_pserver             = pserver
            i_max_upp             = upp
            i_exclude_er_roles    = excl_er
            i_org_field           = gf_org_field "AKUMAR OPL645
          TABLES
            it_users              = gt_bname
            it_confs              = gt_conid
            et_outputdet          = gt_results_user_after
            et_enh_con            = gt_enh_users
            it_advanced_role_simu = gt_advanced_role_sim.

*-- Process output.
        SORT  gt_results_user_after  BY bname conid.
        SORT  gt_results_user_before BY bname conid.
*  Delete gt_results_user_after where simu <> 'X'.
        REFRESH : gt_output.

        LOOP AT gt_results_user_after.
          CLEAR ls_output.
          MOVE-CORRESPONDING gt_results_user_after TO ls_output.
          READ TABLE gt_results_user_before
          WITH KEY conid = gt_results_user_after-conid
                   bname = gt_results_user_after-bname.
*        BINARY SEARCH TRANSPORTING NO FIELDS.
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

          APPEND ls_output TO gt_results_user.
        ENDLOOP.

        LOOP AT gt_results_user_before.
          CLEAR ls_output.
          MOVE-CORRESPONDING gt_results_user_before TO ls_output.
          READ TABLE gt_results_user_after
          WITH KEY conid = gt_results_user_before-conid
                   bname = gt_results_user_before-bname.
*        BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
*--Conflict is removed
            ls_output-simu_before = 'X'.
            CLEAR ls_output-simu_after.
            IF ls_output-simu_after <> ls_output-simu_before.
              ls_output-simu = 'X'.
            ELSE.
              CLEAR ls_output-simu.
            ENDIF.
            APPEND ls_output TO gt_results_user.
          ENDIF.
        ENDLOOP.



        SORT gt_enh_users BY bname conid.
        LOOP AT gt_results_user ASSIGNING <res_user>.
          CLEAR gt_output.
          gt_output-type = 'USER'.
          MOVE-CORRESPONDING <res_user> TO gt_output.
*  --   Check for enhanced conflicts
          READ TABLE gt_enh_users WITH KEY bname = <res_user>-bname
                                           conid = <res_user>-conid
                                           BINARY SEARCH
                                           TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            gt_output-enhanced = 'X'.
          ENDIF.

          APPEND gt_output.
          ADD 1 TO g_conflictcount_usr.
          FREE <res_user>.
        ENDLOOP.

        FREE: gt_results_user.
      ENDIF.
    ENDIF.

    IF p_srole = 'X' OR p_crole = 'X'.
      IF p_srole = 'X'.
        APPEND LINES OF gt_srole TO gt_roles_to_analyze.
      ENDIF.
      IF p_crole = 'X'.
        APPEND LINES OF gt_crole TO gt_roles_to_analyze.
      ENDIF.

** get conflict details from the Matrix
*    PERFORM get_functtran_objs.

      IF gt_roles_to_analyze[] IS INITIAL.
        MESSAGE s002 WITH 'No impacted roles found'(001).
      ELSE.
*advanced_simu_click
        DATA :rs_selfield TYPE slis_selfield.

*---Before analysis
        CALL FUNCTION '/PSYNG/SW_036'
          EXPORTING
            vrsio                = p_vrsio
            org_check            = p_orgchk
            enh_fm               = p_enhanc
            i_advanced_role_simu = 'X'
            i_cfg_set            = cfgset
*         I_COMPOSITE_ROLES    = i_composite
*         i_single_roles       = i_single
            i_shomit             = p_shomit
            i_org_field          = gf_org_field "AKUMAR OPL645
          TABLES
            it_sens              = s_imp
            it_roles             = gt_roles_to_analyze
            ot_routput_sum       = gt_results_role_before.
*                it_advanced_role_simu = gt_advanced_role_sim.

*-- After analysis
        CALL FUNCTION '/PSYNG/SW_036'
          EXPORTING
            vrsio                 = p_vrsio
            org_check             = p_orgchk
            enh_fm                = p_enhanc
            i_advanced_role_simu  = 'X'
*         I_COMPOSITE_ROLES     = i_composite
*         i_single_roles        = i_single
            i_shomit              = p_shomit
            i_cfg_set             = cfgset
            i_org_field          = gf_org_field "AKUMAR OPL645
          TABLES
            it_sens               = s_imp
            it_roles              = gt_roles_to_analyze
            ot_routput_sum        = gt_results_role_after
            it_advanced_role_simu = gt_advanced_role_sim.

*-- Process Output
        SORT  gt_results_role_after  BY agr_name conid.
        SORT  gt_results_role_before BY agr_name conid.
*  Delete gt_results_role_after where simu <> 'X'.
        REFRESH : gt_results_role.

        LOOP AT gt_results_role_after.
          CLEAR ls_output_role.
          MOVE-CORRESPONDING gt_results_role_after TO ls_output_role.
          READ TABLE gt_results_role_before
          WITH KEY conid = gt_results_role_after-conid
                   agr_name = gt_results_role_after-agr_name.
*        BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
*--Conflict is added
            ls_output_role-simu_after = 'X'.
            CLEAR ls_output_role-simu_before.
          ELSE.
*--Conflict is unchanged
            ls_output_role-simu_after = 'X'.
            ls_output_role-simu_before = 'X'.
          ENDIF.
          IF ls_output_role-simu_after <> ls_output_role-simu_before.
            ls_output_role-simu = 'X'.
          ELSE.
            CLEAR ls_output_role-simu.
          ENDIF.
          APPEND ls_output_role TO gt_results_role.
        ENDLOOP.

        LOOP AT gt_results_role_before.
          CLEAR ls_output_role.
          MOVE-CORRESPONDING gt_results_role_before TO ls_output_role.
          READ TABLE gt_results_role_after
          WITH KEY conid = gt_results_role_before-conid
          agr_name = gt_results_role_before-agr_name.
*        BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
*--Conflict is removed
            ls_output_role-simu_before = 'X'.
            CLEAR ls_output_role-simu_after.
            IF ls_output_role-simu_after <> ls_output_role-simu_before.
              ls_output_role-simu = 'X'.
            ELSE.
              CLEAR ls_output_role-simu.
            ENDIF.
            APPEND ls_output_role TO gt_results_role.
          ENDIF.
        ENDLOOP.

        LOOP AT gt_results_role ASSIGNING <res_role>.
          IF p_srole NE 'X'.
            READ TABLE gt_comp_roles
            WITH KEY agr_name = <res_role>-agr_name.
            IF sy-subrc NE 0.
              CONTINUE.
            ENDIF.
          ENDIF.
          CLEAR gt_output.
          gt_output-type = 'ROLE'.
          MOVE-CORRESPONDING <res_role> TO gt_output.
          gt_output-condesc = <res_role>-description.
          APPEND gt_output.
          ADD 1 TO g_conflictcount_role.
          FREE <res_role>.
        ENDLOOP.
      ENDIF.
    ENDIF.
**--Output nr of conflicts found
*   describe table gt_output lines g_conflictcount.
*   MESSAGE s398(00) WITH
*   'Number of SOD conflicts found  :'(l09) g_conflictcount.
*   commit work.

    LOOP AT gt_output.
      IF gt_output-agr_title IS INITIAL.
        SELECT SINGLE text FROM agr_texts INTO gt_output-agr_title
        WHERE agr_name = gt_output-agr_name
        AND line = '00000'
        AND spras = sy-langu.
        IF sy-subrc NE 0.
          CLEAR gt_output-agr_title.
        ENDIF.
        MODIFY gt_output TRANSPORTING agr_title
        WHERE agr_name = gt_output-agr_name.
      ENDIF.
    ENDLOOP.
  ENDIF.
  MESSAGE s398(00) WITH text-083.
*  rs_selfield-fieldname = 'ROLE'.
  IF shodet EQ  'X'.
    IF p_srole = 'X'.
      APPEND LINES OF gt_srole TO gt_roles_to_analyze.
    ENDIF.
    IF p_crole = 'X'.
      APPEND LINES OF gt_crole TO gt_roles_to_analyze.
    ENDIF.
    PERFORM detail_view.
    MESSAGE s398(00) WITH text-083.
  ELSE.

    PERFORM output.
    MESSAGE s398(00) WITH text-083.
  ENDIF.



*&---------------------------------------------------------------------*
*&      Form  apply_adv_sim_to_derived
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ADVANCED_ROLE_SIM  text
*      -->P_LT_SROLE  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM apply_adv_sim_to_derived TABLES et_advanced_role_sim
                                         STRUCTURE agr_1251
                                     it_srole
                                        STRUCTURE /psyng/range_agr_name
USING  i_rolename TYPE agr_name                                        .

  DATA : lt_orig_role TYPE TABLE OF agr_1251 WITH HEADER LINE,
         lt_new_auths TYPE TABLE OF agr_1251,
         lt_simu_role TYPE TABLE OF agr_1251,
         lt_52        TYPE TABLE OF agr_1252 WITH HEADER LINE,
         ls_new_auth  TYPE agr_1251,
         l_agr_name   TYPE agr_name,
         lf_isorg     TYPE flag.

  FIELD-SYMBOLS : <orig> TYPE agr_1251,
                  <new>  TYPE agr_1251.


  lt_simu_role[] = et_advanced_role_sim[].
*--SE4.5PS3 - Assume derived role is up to date, and apply the simulated
*changes
  LOOP AT it_srole WHERE low <> i_rolename.
    LOOP AT lt_simu_role ASSIGNING <orig>.
      ls_new_auth = <orig>.
      ls_new_auth-agr_name = it_srole-low.
      APPEND ls_new_auth TO lt_new_auths.
    ENDLOOP.
  ENDLOOP.

*  SELECT * FROM agr_1251 INTO TABLE lt_orig_role
*         WHERE agr_name IN it_srole
*           AND deleted = ' '.
*
*  SELECT * FROM agr_1252 INTO TABLE lt_52
*         WHERE agr_name IN it_srole.
*
*  SORT lt_orig_role BY agr_name.
*  LOOP AT lt_orig_role ASSIGNING <orig>.
*    l_agr_name = <orig>-agr_name.
**  --Check if corresponding record exists in simulated role
*    READ TABLE lt_simu_role ASSIGNING <new>
*      WITH KEY
*        agr_name = i_rolename
*        object  = <orig>-object
*        field   = <orig>-field
*        low     = <orig>-low
*        high    = <orig>-high.
*    IF sy-subrc = 0 AND <orig>-low(1) <> '$'.
**  --Still exists
*      APPEND <orig> TO lt_new_auths.
*    ELSE.
**  --doesn't exist in simulated role, so ignore record
*    ENDIF.
*    ls_new_auth-agr_name = <orig>-agr_name.
*    AT END OF agr_name.
**  --Add any new auths to derived role
*      LOOP AT lt_simu_role ASSIGNING <new>.
*        READ TABLE lt_orig_role
*             WITH KEY
*               object = <new>-object
*               field  = <new>-field
*               low     = <new>-low
*               high    = <new>-high
*       TRANSPORTING NO FIELDS.
*        IF sy-subrc <> 0.
**  --This is a new authorization, add it if it's not an org level auth
*          FREE : lf_isorg.
*          LOOP AT lt_orig_role
*               WHERE
*               object = <new>-object AND
*                 field  = <new>-field.
*            IF  lt_orig_role-low(1) = '$'.
*              lf_isorg = 'X'.
*            ENDIF.
*          ENDLOOP.
*          IF NOT lf_isorg = 'X'.
*            ls_new_auth = <new>.
**--It's possible this isn't a new auth, but a change of a bvalue within
*an auth that changed,
**  we need to record this with the auth id of the derived role
*            READ TABLE lt_orig_role
*             WITH KEY
*               object   = <new>-object
*               field    = <new>-field
*               counter  = <new>-counter
*               agr_name = l_agr_name
*               transporting auth.
*            if sy-subrc = 0.
*              ls_new_auth-auth = lt_orig_role-auth.
*            endif.
*            ls_new_auth-agr_name = l_agr_name.
*            APPEND ls_new_auth TO lt_new_auths.
*          ENDIF.
*        ENDIF.
*      ENDLOOP.
*    ENDAT.
*  ENDLOOP.

  APPEND LINES OF lt_new_auths TO lt_simu_role.
  SORT lt_simu_role BY agr_name.
  et_advanced_role_sim[] = lt_simu_role[].
ENDFORM.                    " apply_adv_sim_to_derived

*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       Output to ALV
*----------------------------------------------------------------------*
FORM output.
  DATA: ls_variant      TYPE disvariant,
        ls_repid        TYPE sy-repid,
        lt_fieldcatalog TYPE slis_t_fieldcat_alv,
        ls_fieldcatalog TYPE slis_fieldcat_alv,
        ls_layout       TYPE slis_layout_alv,
        lt_sort         TYPE TABLE OF slis_sortinfo_alv,
        ls_sort         TYPE slis_sortinfo_alv,
        ls_cc           TYPE lvc_s_scol,
        ls_color        TYPE lvc_s_colo.

  FIELD-SYMBOLS: <out> LIKE LINE OF gt_output.


  ls_repid = sy-repid.

  IF p_hilite = 'X'.
    LOOP AT gt_output ASSIGNING <out>.
      IF NOT <out>-contid IS INITIAL.
        CLEAR: <out>-color_cell, <out>-color_line.
        ls_color-col = '5'.   "Green
        ls_color-int = '1'.   "Intensified
        ls_color-inv = '0'.   "Inverse
        ls_cc-fname = 'IMP'.
        ls_cc-color  = ls_color.
        APPEND ls_cc TO <out>-color_cell.
        ls_cc-fname = 'CONID'.
        APPEND ls_cc TO <out>-color_cell.
        ls_cc-fname = 'CONDESC'.
        APPEND ls_cc TO <out>-color_cell.
        ls_cc-fname = 'CONTID'.
        APPEND ls_cc TO <out>-color_cell.
        CONTINUE.
      ENDIF.

      CASE <out>-imp.
        WHEN 'HIGH'.
          ls_color-col = '6'.   "Red
          ls_color-int = '0'.   "Un-Intensified
          ls_color-inv = '0'.   "Inverse
          ls_cc-fname  = 'IMP'.
          ls_cc-color  = ls_color.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONID'.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONDESC'.
          APPEND ls_cc TO <out>-color_cell.
        WHEN 'MEDIUM'.
          ls_color-col = '6'.   "Green
          ls_color-int = '0'.   "Un-Intensified
          ls_color-inv = '1'.   "Inverse
          ls_cc-fname  = 'IMP'.
          ls_cc-color  = ls_color.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONID'.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONDESC'.
          APPEND ls_cc TO <out>-color_cell.
        WHEN 'LOW'.
          ls_color-col = '3'.   "Yellow
          ls_color-int = '0'.   "Un-Intensified
          ls_color-inv = '0'.   "Inverse
          ls_cc-fname  = 'IMP'.
          ls_cc-color  = ls_color.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONID'.
          APPEND ls_cc TO <out>-color_cell.
          ls_cc-fname = 'CONDESC'.
          APPEND ls_cc TO <out>-color_cell.
      ENDCASE.
    ENDLOOP.
  ENDIF.
  IF p_hienhn = 'X'.
    LOOP AT gt_output ASSIGNING <out>.
      IF <out>-type = 'USER'.
        READ TABLE gt_enh_users WITH KEY bname = <out>-bname
                                       conid = <out>-conid
                                TRANSPORTING  NO FIELDS.
        IF sy-subrc = 0.
          <out>-enhanced = 'X'.
        ENDIF.
      ENDIF.
      IF <out>-enhanced = 'X'.
        DELETE <out>-color_cell WHERE fname = 'CONID'.
        ls_color-col = '7'.   "Orange
        ls_color-int = '1'.   "Intensified
        ls_color-inv = '0'.   "Inverse
        ls_cc-color  = ls_color.
        ls_cc-fname  = 'CONID'.
        APPEND ls_cc TO <out>-color_cell.
      ENDIF.
    ENDLOOP.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/PSYNG/SW_ADV_SIMU_OUTPUT'
    CHANGING
      ct_fieldcat            = lt_fieldcatalog
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ls_fieldcatalog-hotspot = 'X'.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
  TRANSPORTING hotspot WHERE fieldname = 'CONID'.

  ls_fieldcatalog-no_out = 'X'.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
  TRANSPORTING no_out WHERE fieldname = 'IMPSORT'.
  DELETE lt_fieldcatalog WHERE fieldname EQ 'IMPSORT'.
  ls_fieldcatalog-seltext_l    = 'User ID'(h00).
  ls_fieldcatalog-seltext_m    = 'User ID'(h00).
  ls_fieldcatalog-seltext_s    = 'User ID'(h00).
  ls_fieldcatalog-reptext_ddic = 'User ID'(h00).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'BNAME'.

  ls_fieldcatalog-seltext_l    = 'User Name'(h01).
  ls_fieldcatalog-seltext_m    = 'User Name'(h01).
  ls_fieldcatalog-seltext_s    = 'User Name'(h01).
  ls_fieldcatalog-reptext_ddic = 'User Name'(h01).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'NAME_TEXT'.

  ls_fieldcatalog-seltext_l    = 'Company'(h02).
  ls_fieldcatalog-seltext_m    = 'Company'(h02).
  ls_fieldcatalog-seltext_s    = 'Company'(h02).
  ls_fieldcatalog-reptext_ddic = 'Company'(h02).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'COMPANY'.

  IF p_shomit = 'X'.
    ls_fieldcatalog-seltext_l    = 'Mitigation ID'(h03).
    ls_fieldcatalog-seltext_m    = 'Mitigation ID'(h03).
    ls_fieldcatalog-seltext_s    = 'Mitigation ID'(h03).
    ls_fieldcatalog-reptext_ddic = 'Mitigation ID'(h03).
    ls_fieldcatalog-hotspot = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
                         hotspot
           WHERE fieldname = 'CONTID'.
  ELSE.
    ls_fieldcatalog-no_out = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
           WHERE fieldname = 'CONTID'.
  ENDIF.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  IF p_enhanc = 'X'.
    CLEAR ls_fieldcatalog-no_out.
  ELSE.
    ls_fieldcatalog-no_out = 'X'.
  ENDIF.
  ls_fieldcatalog-checkbox = 'X'.
  ls_fieldcatalog-just = 'X'.
  ls_fieldcatalog-seltext_l    = 'Enhanced'(h09).
  ls_fieldcatalog-seltext_m    = 'Enhanced'(h09).
  ls_fieldcatalog-seltext_s    = 'Enhanced'(h09).
  ls_fieldcatalog-reptext_ddic = 'Enhanced'(h09).

  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING just checkbox seltext_l seltext_m seltext_s
                      reptext_ddic no_out
         WHERE fieldname = 'ENHANCED'.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  ls_fieldcatalog-checkbox     = 'X'.
  ls_fieldcatalog-just     = 'X'.
  ls_fieldcatalog-seltext_l    = 'Simulation'(h08).
  ls_fieldcatalog-seltext_m    = 'Simulation'(h08).
  ls_fieldcatalog-seltext_s    = 'Simulation'(h08).
  ls_fieldcatalog-reptext_ddic = 'Simulation'(h08).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING just checkbox seltext_l seltext_m seltext_s
                      reptext_ddic
         WHERE fieldname = 'SIMU'.

  ls_fieldcatalog-seltext_l = text-117.
  ls_fieldcatalog-seltext_m = text-117.
  ls_fieldcatalog-seltext_s = text-117.
  ls_fieldcatalog-reptext_ddic = text-117.
  ls_fieldcatalog-checkbox     = 'X'.
  ls_fieldcatalog-just       = 'X'.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'SIMU_BEFORE'.

  ls_fieldcatalog-seltext_l = text-118.
  ls_fieldcatalog-seltext_m = text-118.
  ls_fieldcatalog-seltext_s = text-118.
  ls_fieldcatalog-reptext_ddic = text-118.
  ls_fieldcatalog-checkbox     = 'X'.
  ls_fieldcatalog-just       = 'X'.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                   WHERE
                      fieldname = 'SIMU_AFTER'.
  CLEAR ls_fieldcatalog.
  ls_fieldcatalog-hotspot = 'X'.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING hotspot
         WHERE fieldname = 'CONID'.

  ls_sort-spos      = '1'.
  ls_sort-fieldname = 'TYPE'.
  ls_sort-tabname   = 'GT_OUTPUT'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '2'.
  ls_sort-fieldname = 'AGR_NAME'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '3'.
  ls_sort-fieldname = 'AGR_TITLE'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '4'.
  ls_sort-fieldname = 'COMPANY'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '5'.
  ls_sort-fieldname = 'DEPARTMENT'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '6'.
  ls_sort-fieldname = 'CLASS'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '7'.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '8'.
  ls_sort-fieldname = 'NAME_TEXT'.
  APPEND ls_sort TO lt_sort.
*  ls_sort-spos      = '9'.
*  ls_sort-fieldname = 'IMPSORT'.
*  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '9'.
  ls_sort-fieldname = 'IMP'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '10'.
  ls_sort-fieldname = 'CONID'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '11'.
  ls_sort-fieldname = 'ENHANCED'.
  APPEND ls_sort TO lt_sort.


  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
  MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.
*  gs_variant-handle = gs_variant-handle + 1.
  "Changes by RGUPTA on 25th Nov, 2021
  gs_variant-handle = 1. "Changes by AKUMAR OPL568
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page   = 'ADVSIMU_TOP_OF_PAGE'
      i_callback_program       = ls_repid
      i_callback_pf_status_set = 'ADVSIMU_PF_SUMSTA'
      it_sort                  = lt_sort
      i_callback_user_command  = 'ADVANCED_SIMU_CLICK'
      is_layout                = ls_layout
      it_fieldcat              = lt_fieldcatalog
      i_save                   = 'A'
is_variant               = gs_variant
"ls_variant "Changes by RGUPTA on 25th Nov, 2021
TABLES
t_outtab                 = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " output

*&---------------------------------------------------------------------*
*&      Form  find_impacted_single_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SROLE  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM find_impacted_single_roles
  TABLES   it_srole   STRUCTURE /psyng/range_agr_name
           et_sroles  STRUCTURE /psyng/range_agr_name
  USING    i_rolename TYPE      agr_name.


  DATA : lt_derived_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_srole         TYPE TABLE OF /psyng/range_agr_name.

  lt_srole[] = it_srole[].
  DELETE lt_srole WHERE low = i_rolename.

  SELECT agr_name parent_agr FROM agr_define
         INTO CORRESPONDING FIELDS OF TABLE lt_derived_roles
         WHERE parent_agr =  i_rolename
         AND agr_name IN lt_srole.


  et_sroles-sign   = 'I'.
  et_sroles-option = 'EQ'.
  LOOP AT lt_derived_roles.
    et_sroles-low = lt_derived_roles-agr_name.
    APPEND et_sroles.
  ENDLOOP.
*--Add the role itsself
  IF i_rolename IN it_srole.
    et_sroles-low = i_rolename.
    APPEND et_sroles.
  ENDIF.
  SORT et_sroles.
  DELETE ADJACENT DUPLICATES FROM et_sroles.
ENDFORM.                    " find_impacted_single_roles

*&---------------------------------------------------------------------*
*&      Form  find_impacted_composite_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_CROLE  text
*      -->P_LT_CROLE  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM find_impacted_composite_roles
  TABLES   it_crole   STRUCTURE /psyng/range_agr_name
           et_croles  STRUCTURE /psyng/range_agr_name
  USING    i_rolename TYPE      agr_name.

  DATA:
    lt_parent_roles  TYPE TABLE OF agr_agrs WITH HEADER LINE,
  lt_derived_roles TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE.

*--Find all derived roles
  PERFORM find_impacted_single_roles
              TABLES
                 lt_derived_roles
                 lt_derived_roles
              USING
                 i_rolename.

* Mark changes in all the derived roles
* Only append simulated changes for derived roles
* if not done earlier, i.e. p_srole is blank
  IF NOT lt_derived_roles[] IS INITIAL
  AND p_srole IS INITIAL.
    PERFORM apply_adv_sim_to_derived
            TABLES
              gt_advanced_role_sim
              lt_derived_roles
            USING i_rolename.

  ENDIF.

  lt_derived_roles-sign = 'I'.
  lt_derived_roles-option = 'EQ'.
  lt_derived_roles-low = i_rolename.
  APPEND lt_derived_roles.

  SELECT agr_name child_agr FROM agr_agrs
  INTO CORRESPONDING FIELDS OF TABLE lt_parent_roles
  WHERE
    child_agr IN lt_derived_roles  AND
    agr_name  IN it_crole          AND
    attributes <> 'X'. "X means NOT ACTIVE!!!

  gt_comp_roles[] = lt_parent_roles[].

  et_croles-sign   = 'I'.
  et_croles-option = 'EQ'.
  LOOP AT lt_parent_roles.
    et_croles-low = lt_parent_roles-agr_name.
    APPEND et_croles.
  ENDLOOP.


  SORT et_croles.
  DELETE ADJACENT DUPLICATES FROM et_croles.
ENDFORM.                    " find_impacted_composite_roles

*&---------------------------------------------------------------------*
*&      Form  find_impacted_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_BNAME  text
*      -->P_LT_BNAME  text
*      -->P_L_ROLENAME  text
*----------------------------------------------------------------------*
FORM find_impacted_users TABLES  it_bname STRUCTURE /psyng/range_bname
                                 et_bname STRUCTURE /psyng/range_bname
                                 it_advanced_role_sim STRUCTURE agr_1251

                         USING    i_rolename TYPE agr_name.

  DATA : lt_agr_users TYPE TABLE OF agr_users WITH HEADER LINE,
      lt_srole     TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE,
      lt_srole_dum TYPE TABLE OF /psyng/range_agr_name
      WITH HEADER LINE.


*get the derived roles
  PERFORM find_impacted_single_roles
    TABLES lt_srole_dum
           lt_srole
    USING  i_rolename.
* Mark changes in all the derived roles
* Only append simulated changes for derived roles
* if not done earlier, i.e. p_srole is blank
  IF p_srole IS INITIAL
  AND p_crole IS INITIAL
  AND lt_srole[] IS NOT INITIAL.
    PERFORM apply_adv_sim_to_derived
      TABLES
        it_advanced_role_sim
        lt_srole
      USING  i_rolename.
  ENDIF.

  SELECT uname FROM agr_users INTO
    CORRESPONDING FIELDS OF TABLE lt_agr_users
  WHERE
    uname    IN it_bname AND
    agr_name IN lt_srole AND
    from_dat <= sy-datum AND
    to_dat   >=  sy-datum.
  et_bname-sign   = 'I'.
  et_bname-option = 'EQ'.

  LOOP AT lt_agr_users.
    et_bname-low = lt_agr_users-uname.
    APPEND et_bname.
  ENDLOOP.

  SORT et_bname.
  DELETE ADJACENT DUPLICATES FROM et_bname.
ENDFORM.                    " find_impacted_users

*---------------------------------------------------------------------*
*       FORM advsimu_pf_status                                        *
*---------------------------------------------------------------------*
*       Create buttons for advanced simulation summary screen         *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM advsimu_pf_status USING it_extab TYPE slis_t_extab.

  DATA : BEGIN OF lt_fcode OCCURS 0,
           fcode LIKE rsmpe-func,
         END OF lt_fcode.
  IF NOT gf_simu_role IS INITIAL.
    lt_fcode-fcode = 'SHOWSIMDET'.
    APPEND lt_fcode.
  ENDIF.
  IF  gt_roleoutput[] IS INITIAL
  AND gt_useroutput[] IS INITIAL.
    lt_fcode-fcode = 'SHOW_TEXTS'.
    APPEND lt_fcode.

    lt_fcode-fcode = 'TOGGLE_ORG'.
    APPEND lt_fcode.
  ENDIF.

  SET PF-STATUS 'ADVSIMUOUT' EXCLUDING lt_fcode.
  CLEAR gf_simu_role.
ENDFORM.                    " advsimu_pf_status

*---------------------------------------------------------------------*
*       FORM advsimu_top_of_page                                      *
*---------------------------------------------------------------------*
*       Create header for advanced simulation summary screen          *
*---------------------------------------------------------------------*
FORM advsimu_top_of_page.
  DATA: lt_header     TYPE slis_t_listheader,
        ls_header     TYPE slis_listheader,
        lv_exetime(8) TYPE c,
        lv_exedate    TYPE char10,
        ls_cfg_set    TYPE /psyng/swcfgset,
        l_str         TYPE string,
        l_int         TYPE i,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

  ls_header-typ  = 'H'.
  ls_header-info = 'Advanced Role Simulation'(t03).
  APPEND ls_header TO lt_header.
  ls_header-typ  = 'S'.
  WRITE sy-datum TO lv_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
        INTO lv_exetime SEPARATED BY ':'.
  ls_header-key  = 'User Date & System:'(h11).
*  CONCATENATE sy-uname text-094 lv_exedate lv_exetime INTO "C0700

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user text-094 lv_exedate lv_exetime
  text-235 l_systemid INTO "C0700
ls_header-info
  SEPARATED BY space.
  APPEND ls_header TO lt_header.

  ls_header-key  = 'SOD Version:'(h12).
*  ls_header-info = p_vrsio.
  SELECT SINGLE vdesc INTO ls_header-info FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  ls_header-info
     INTO ls_header-info SEPARATED BY space.
  APPEND ls_header TO lt_header.

*--Configuration Set
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid = cfgset.
    ls_header-typ  = 'S'.
    ls_header-key  = 'Configuration Set:'(h32).
    l_int = cfgset.
    l_str = l_int.
    CONDENSE l_str.
    CONCATENATE l_str ' : '
    ls_cfg_set-description INTO ls_header-info SEPARATED BY space.
    APPEND ls_header TO lt_header.
    ls_header-key  = 'Config Set Published:'(h33).
    IF ls_cfg_set-published = 'X'.
      ls_header-info = 'Yes'(h34).
    ELSE.
      ls_header-info = 'No'(h35).
    ENDIF.
    APPEND ls_header TO lt_header.
    ls_header-key  = 'Config Set Changed :'(h36).
    WRITE ls_cfg_set-change_date TO ls_header-info.
    CONCATENATE ls_header-info 'by'(h37) ls_cfg_set-change_user
    INTO ls_header-info SEPARATED BY space.
    APPEND ls_header TO lt_header.

  ENDIF.

  ls_header-key  = 'Simulated Role:'(h13).
  ls_header-info = p_agrnam.
  IF NOT p_cagr IS INITIAL.
    CONCATENATE ls_header-info '(' p_cagr ')'
                INTO ls_header-info SEPARATED BY space.
  ENDIF.
  APPEND ls_header TO lt_header.

  IF p_user = 'X'.
    ls_header-key  = 'Conflicts in Users:'(h19).
    ls_header-info = g_conflictcount_usr.
    APPEND ls_header TO lt_header.
  ENDIF.
  IF p_srole = 'X' OR p_crole = 'X'.
    ls_header-key  = 'Conflicts in Roles:'(h20).
    ls_header-info = g_conflictcount_role.
    APPEND ls_header TO lt_header.
  ENDIF.


  IF p_enhanc = 'X'.
    ls_header-key  = 'Matrix:'(h17).
    ls_header-info = 'Dynamically Enhanced'(h18).
    APPEND ls_header TO lt_header.
  ENDIF.



  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.


ENDFORM.                    " advsimu_top_of_page

*---------------------------------------------------------------------*
*       FORM ADVANCED_SIMU_CLICK                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM advanced_simu_click USING r_ucomm LIKE sy-ucomm
                                rs_selfield TYPE slis_selfield.
  DATA : lt_users     TYPE TABLE OF /psyng/range_bname WITH HEADER LINE,
         lt_conflicts TYPE TABLE OF /psyng/range_conid WITH HEADER LINE,
      lt_roles     TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE.
  DATA: l_repid         TYPE sy-repid,
        ls_variant      TYPE disvariant,
        ls_layout       TYPE slis_layout_alv,
        lt_sort         TYPE TABLE OF slis_sortinfo_alv,
        ls_sort         TYPE slis_sortinfo_alv,
        lt_fieldcatalog TYPE slis_t_fieldcat_alv,
        ls_fieldcatalog TYPE slis_fieldcat_alv,
        ls_cc           TYPE lvc_s_scol,
        ls_color        TYPE lvc_s_colo,
        l_uname         LIKE sy-uname,
        l_contid        TYPE /psyng/mchdr-contid,
        l_parva         TYPE usr05-parva,
        l_sod           TYPE /psyng/swsodvers-vrsio,
        l_parva_exists  LIKE sy-subrc,
        lf_composite    TYPE flag,
        swconfig type /psyng/swconfig, "AKUMAR OPL645
        lt_adv_sim_tmp  TYPE TABLE OF agr_1251 WITH HEADER LINE.

*BOC AKUMAR OPL645
  clear swconfig.
  se_config_param 'CONSIDER_ORG_FIELD' swconfig-value.
  if swconfig-value = 'Y'.
    gf_org_field = 'X'.
  elseif swconfig-value = 'N'.
    gf_org_field = ' '.
  endif.
  clear swconfig.
*EOC AKUMAR OPL645

  CASE r_ucomm.
    WHEN 'SHOWSIMDET'.
      PERFORM show_role_simu.
      EXIT.
  ENDCASE.
  CASE rs_selfield-fieldname.
*BOC:HBHALLA (R3-CASE6) (PN-11675) (OPL647)
    WHEN 'SIMU'.
      EXIT.
*EOC:HBHALLA (R3-CASE6) (PN-11675) (OPL647)
    WHEN 'CONTID'.
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

      PERFORM set_default_sodversion USING p_vrsio l_uname 0.
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
  ENDCASE.
  FREE: lt_users, lt_conflicts, gt_useroutput, lt_roles.
  READ TABLE gt_output INDEX rs_selfield-tabindex.
  CHECK sy-subrc = 0.

  lt_conflicts-sign = 'I'.
  lt_conflicts-option = 'EQ'.
  lt_conflicts-low = gt_output-conid.
  APPEND lt_conflicts.
* BOC by RGUPTA on 18th Feb 22 for B16473
  IF rs_selfield-fieldname = 'SIMU_AFTER' AND
     gt_output-simu_after IS INITIAL.
    MESSAGE i002(/psyng/sw) WITH
         'This conflict doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11).
    EXIT.
  ELSEIF rs_selfield-fieldname = 'SIMU_BEFORE' AND
    gt_output-simu_before IS INITIAL.
    MESSAGE i002(/psyng/sw) WITH
       'This conflict didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
    EXIT.
*BOC:HBHALLA (17/02/25) PN-11675 (CASE-6)
  ELSEIF rs_selfield-fieldname = 'CONID' AND
     gt_output-simu_after IS INITIAL.
    MESSAGE i002(/psyng/sw) WITH
         'This conflict doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11).
    EXIT.
*EOC:HBHALLA (17/02/25) PN-11675 (CASE-6)
  ENDIF.
* EOC by RGUPTA on 18th Feb 22 for B16473
  CASE gt_output-type.
    WHEN 'USER'.
      lt_users-sign = 'I'.
      lt_users-option = 'EQ'.
      lt_users-low = gt_output-bname.
      APPEND lt_users.
      FREE: gt_useroutput.

*BOC AKUMAR PN6072 26/08/2024
      IF rs_selfield-fieldname = 'SIMU_BEFORE'.
        CALL FUNCTION '/PSYNG/SW_081'
                  EXPORTING
                    i_byuser              = 'X'
                    i_orgchk              = p_orgchk
                    i_sodvrsio            = p_vrsio
                    i_enhanc              = p_enhanc
                    i_hienhn              = p_hienhn
                    i_shosum              = ' '
                    i_exclude_er_roles    = excl_er
                    i_xmc                 = p_shomit
                    i_config_set          = cfgset
                  TABLES
                    it_bname              = lt_users
                    it_conflicts          = lt_conflicts
                    et_outputdet          = gt_useroutput
"(++)BOC UMITTAL SE VF scan-25/11/2024
                   EXCEPTIONS
                     USER_CANCELLED          = 1
                     OTHERS                 = 2 .
           IF sy-subrc <> 0.
                MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ELSE.
        CALL FUNCTION '/PSYNG/SW_081'
          EXPORTING
            i_byuser              = 'X'
            i_orgchk              = p_orgchk
            i_sodvrsio            = p_vrsio
            i_enhanc              = p_enhanc
            i_hienhn              = p_hienhn
            i_shosum              = ' '
            i_advanced_role_simu  = 'X'
            i_exclude_er_roles    = excl_er
            i_xmc                 = p_shomit
            i_config_set          = cfgset
          TABLES
            it_bname              = lt_users
            it_conflicts          = lt_conflicts
            et_outputdet          = gt_useroutput
            it_advanced_role_simu = gt_advanced_role_sim[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             USER_CANCELLED          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDIF.
*EOC AKUMAR PN6072
      FREE : gt_useroutput_alv.
      LOOP AT gt_useroutput.
        CLEAR gt_useroutput_alv.
        MOVE-CORRESPONDING gt_useroutput TO gt_useroutput_alv.
        IF gt_useroutput_alv-enhanced = 'X'.
          DELETE gt_useroutput_alv-color_cell WHERE fname = 'CONID'.
          ls_color-col = '7'.   "Orange
          ls_color-int = '1'.   "Intensified
          ls_color-inv = '0'.   "Inverse
          ls_cc-color  = ls_color.
          ls_cc-fname  = 'CONID'.
          APPEND ls_cc TO gt_useroutput_alv-color_cell.
          ls_cc-fname  = 'TCODE'.
          APPEND ls_cc TO gt_useroutput_alv-color_cell.
        ENDIF.
        APPEND gt_useroutput_alv.
      ENDLOOP.

      CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = '/PSYNG/SW_ADV_SIMU_OUTPUTDET_U'
        CHANGING
          ct_fieldcat            = lt_fieldcatalog
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      ls_fieldcatalog-hotspot      = 'X'.
      ls_fieldcatalog-seltext_l    = 'User ID'(h00).
      ls_fieldcatalog-seltext_m    = 'User ID'(h00).
      ls_fieldcatalog-seltext_s    = 'User ID'(h00).
      ls_fieldcatalog-reptext_ddic = 'User ID'(h00).

      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BNAME'.

      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'TCODE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'FUNCTIONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'OBJCT'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'PROFILE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'RISK'.

      ls_fieldcatalog-col_pos = 4.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING col_pos
             WHERE fieldname = 'DESCRIPTION'.

*----05/05/2023 om OPL572
      ls_fieldcatalog-seltext_l    = 'Comp. Role'(h40).
      ls_fieldcatalog-seltext_m    = 'Comp. Role'(h40).
      ls_fieldcatalog-seltext_s    = 'Comp. Role'(h40).
      ls_fieldcatalog-reptext_ddic = 'Comp. Role'(h40).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'COMP_AGR'.
*----END
      ls_fieldcatalog-seltext_l    = 'Field'(h04).
      ls_fieldcatalog-seltext_m    = 'Field'(h04).
      ls_fieldcatalog-seltext_s    = 'Field'(h04).
      ls_fieldcatalog-reptext_ddic = 'Field'(h04).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'FIELD'.

      ls_fieldcatalog-seltext_l    = 'From'(h05).
      ls_fieldcatalog-seltext_m    = 'From'(h05).
      ls_fieldcatalog-seltext_s    = 'From'(h05).
      ls_fieldcatalog-reptext_ddic = 'From'(h05).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'VON'.
      ls_fieldcatalog-seltext_l    = 'To'(h06).
      ls_fieldcatalog-seltext_m    = 'To'(h06).
      ls_fieldcatalog-seltext_s    = 'To'(h06).
      ls_fieldcatalog-reptext_ddic = 'To'(h06).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BIS'.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
      ls_fieldcatalog-checkbox     = 'X'.
      ls_fieldcatalog-just         = 'X'.
      ls_fieldcatalog-seltext_l    = text-118.
      ls_fieldcatalog-seltext_m    = text-118.
      ls_fieldcatalog-seltext_s    = text-118.
      ls_fieldcatalog-reptext_ddic = text-118.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox just seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'SIMU'.

      IF p_enhanc = 'X'.
        CLEAR ls_fieldcatalog-no_out.
      ELSE.
        ls_fieldcatalog-no_out = 'X'.
      ENDIF.

      ls_fieldcatalog-seltext_l    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_m    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_s    = 'Enhanced'(h07).
      ls_fieldcatalog-reptext_ddic = 'Enhanced'(h07).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox seltext_l seltext_m seltext_s
                          reptext_ddic no_out
             WHERE fieldname = 'ENHANCED'.


      ls_fieldcatalog-no_out = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
             WHERE fieldname = 'IMPSORT'.

*--Don't show the org_type field ever
      ls_fieldcatalog-no_out = 'X'.
      ls_fieldcatalog-seltext_l = 'Org Output Type'.
      ls_fieldcatalog-seltext_m = 'Org Output Type'.
      ls_fieldcatalog-seltext_s = 'Org Type'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          no_out
                       WHERE
                          fieldname = 'ORG_TYPE'.

      ls_sort-spos      = '1'.
      ls_sort-fieldname = 'BNAME'.
      ls_sort-tabname   = 'GT_USEROUTPUT'.
      ls_sort-up        = 'X'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '2'.
      ls_sort-fieldname = 'ORG_ABB'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '3'.
      ls_sort-fieldname = 'IMPSORT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '4'.
      ls_sort-fieldname = 'IMP'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '5'.
      ls_sort-fieldname = 'CONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '6'.
      ls_sort-fieldname = 'DESCRIPTION'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '7'.
      ls_sort-fieldname = 'RISK'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '8'.
      ls_sort-fieldname = 'FUNCTIONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '9'.
      ls_sort-fieldname = 'COMP_AGR'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '10'.
      ls_sort-fieldname = 'AGR_NAME'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '11'.
      ls_sort-fieldname = 'RFCDEST'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '12'.
      ls_sort-fieldname = 'TCODE'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '13'.
      ls_sort-fieldname = 'OBJCT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '14'.
      ls_sort-fieldname = 'AUTH'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '15'.
      ls_sort-fieldname = 'FIELD'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '16'.
      ls_sort-fieldname = 'VON'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '17'.
      ls_sort-fieldname = 'BIS'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '18'.
      ls_sort-fieldname = 'PROFILE'.
      APPEND ls_sort TO lt_sort.

      l_repid                     = sy-repid.
      ls_layout-zebra             = 'X'.
      ls_layout-colwidth_optimize = 'X'.
      MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
      MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.


      MESSAGE s398(00) WITH text-083.
*      gs_variant-handle = gs_variant-handle + 1.
      "Changes by RGUPTA on 25th Nov, 2021
      gs_variant-handle = 2. "Changes by AKUMAR OPL568
      gf_sum_to_det = 'X'.
      PERFORM toggle_alv_user_init.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_callback_program       = l_repid
          i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
          it_sort                  = lt_sort
          i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
          is_layout                = ls_layout
          it_fieldcat              = lt_fieldcatalog
          it_filter                = gt_filter_user_detail
          i_save                   = 'A'
is_variant               = gs_variant
"ls_variant Changes by RGUPTA on 25th Nov, 2021
TABLES
t_outtab                 = gt_useroutput_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'ROLE'.
      lt_roles-sign   = 'I'.
      lt_roles-option = 'EQ'.
      lt_roles-low    = gt_output-agr_name.
      APPEND lt_roles.
      FREE : gt_roleoutput,gt_roleoutput_alv.
      IF rs_selfield-fieldname = 'SIMU_BEFORE'.
        CALL FUNCTION '/PSYNG/SW_083'
          EXPORTING
            i_orgchk              = p_orgchk
            i_sodvrsio            = p_vrsio
            i_enhanc              = p_enhanc
            i_hienhn              = p_hienhn
            i_shomit              = p_shomit
            i_config_set          = cfgset
            i_org_field  = gf_org_field "AKUMAR OPL645
          TABLES
            it_roles              = lt_roles
            it_conflicts          = lt_conflicts
            et_outputdet          = gt_roleoutput.
      ELSE.
*BOC AKUMAR OPL647 02/04/2025
        refresh lt_adv_sim_tmp.
        lt_adv_sim_tmp[] = gt_advanced_role_sim[].
*EOC AKUMAR OPL647 02/04/2025
        READ TABLE gt_advanced_role_sim INDEX 1.
        CALL FUNCTION '/PSYNG/SW_083'
          EXPORTING
            i_orgchk              = p_orgchk
            i_sodvrsio            = p_vrsio
            i_enhanc              = p_enhanc
            i_hienhn              = p_hienhn
            i_advanced_role_simu  = 'X'
            i_shomit              = p_shomit
            i_config_set          = cfgset
            i_org_field           = gf_org_field "AKUMAR OPL645
          TABLES
            it_roles              = lt_roles
            it_conflicts          = lt_conflicts
            et_outputdet          = gt_roleoutput
*            it_advanced_role_simu = gt_advanced_role_sim.
            it_advanced_role_simu = lt_adv_sim_tmp.
      ENDIF.
      LOOP AT gt_roleoutput.
        CLEAR gt_roleoutput_alv.
        MOVE-CORRESPONDING gt_roleoutput TO gt_roleoutput_alv.
        IF gt_roleoutput_alv-enhanced = 'X'.
          DELETE gt_roleoutput_alv-color_cell WHERE fname = 'CONID'.
          ls_color-col = '7'.   "Orange
          ls_color-int = '1'.   "Intensified
          ls_color-inv = '0'.   "Inverse
          ls_cc-color  = ls_color.
          ls_cc-fname  = 'CONID'.
          APPEND ls_cc TO gt_roleoutput_alv-color_cell.
          ls_cc-fname  = 'TCODE'.
          APPEND ls_cc TO gt_roleoutput_alv-color_cell.
        ENDIF.
        APPEND gt_roleoutput_alv.
      ENDLOOP.


      CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = '/PSYNG/SW_ADV_SIMU_OUTPUTDET_R'
        CHANGING
          ct_fieldcat            = lt_fieldcatalog
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      ls_fieldcatalog-no_out = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
             WHERE fieldname = 'ISORT'.

      ls_fieldcatalog-hotspot = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'AGR_NAME'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'TCODE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'FUNCTIONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'OBJCT'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CHILD_AGR'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'RISK'.

      ls_fieldcatalog-col_pos = 4.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING col_pos
             WHERE fieldname = 'DESCRIPTION'.

*      05/05/2023 Om Opl572
      ls_fieldcatalog-seltext_l    = 'Child Role'(h30).
      ls_fieldcatalog-seltext_m    = 'Child Role'(h30).
      ls_fieldcatalog-seltext_s    = 'Child Role'(h30).
      ls_fieldcatalog-reptext_ddic = 'Child Role'(h30).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'CHILD_AGR'.

      ls_fieldcatalog-seltext_l    = 'Single/Comp. Role'(h31).
      ls_fieldcatalog-seltext_m    = 'Single/Comp. Role'(h31).
      ls_fieldcatalog-seltext_s    = 'Single/Comp. Role'(h31).
      ls_fieldcatalog-reptext_ddic = 'Single/Comp. Role'(h31).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'AGR_NAME'.
*      end

      ls_fieldcatalog-seltext_l    = 'Field'(h04).
      ls_fieldcatalog-seltext_m    = 'Field'(h04).
      ls_fieldcatalog-seltext_s    = 'Field'(h04).
      ls_fieldcatalog-reptext_ddic = 'Field'(h04).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'FIELD'.

      ls_fieldcatalog-seltext_l    = 'From'(h05).
      ls_fieldcatalog-seltext_m    = 'From'(h05).
      ls_fieldcatalog-seltext_s    = 'From'(h05).
      ls_fieldcatalog-reptext_ddic = 'From'(h05).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'VON'.

      ls_fieldcatalog-seltext_l    = 'To'(h06).
      ls_fieldcatalog-seltext_m    = 'To'(h06).
      ls_fieldcatalog-seltext_s    = 'To'(h06).
      ls_fieldcatalog-reptext_ddic = 'To'(h06).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BIS'.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
      ls_fieldcatalog-checkbox     = 'X'.
      ls_fieldcatalog-just         = 'X'.
      ls_fieldcatalog-seltext_l    = text-118.
      ls_fieldcatalog-seltext_m    = text-118.
      ls_fieldcatalog-seltext_s    = text-118.
      ls_fieldcatalog-reptext_ddic = text-118.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox just seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'SIMU'.

      IF p_enhanc = 'X'.
        CLEAR ls_fieldcatalog-no_out.
      ELSE.
        ls_fieldcatalog-no_out = 'X'.
      ENDIF.

      ls_fieldcatalog-seltext_l    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_m    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_s    = 'Enhanced'(h07).
      ls_fieldcatalog-reptext_ddic = 'Enhanced'(h07).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox seltext_l seltext_m seltext_s
                          reptext_ddic no_out
             WHERE fieldname = 'ENHANCED'.

      ls_fieldcatalog-no_out = 'X'.
      ls_fieldcatalog-seltext_l = 'Org Output Type'.
      ls_fieldcatalog-seltext_m = 'Org Output Type'.
      ls_fieldcatalog-seltext_s = 'Org Type'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          no_out
                       WHERE
                          fieldname = 'ORG_TYPE'.

      ls_sort-spos      = '1'.
      ls_sort-fieldname = 'AGR_NAME'.
      ls_sort-tabname   = 'GT_ROLEOUTPUT'.
      ls_sort-up        = 'X'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '2'.
      ls_sort-fieldname = 'ISORT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '3'.
      ls_sort-fieldname = 'IMP'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '4'.
      ls_sort-fieldname = 'CONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '5'.
      ls_sort-fieldname = 'DESCRIPTION'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '6'.
      ls_sort-fieldname = 'RISK'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '7'.
      ls_sort-fieldname = 'FUNCTIONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '8'.
      ls_sort-fieldname = 'RFCDEST'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '9'.
      ls_sort-fieldname = 'TCODE'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '10'.
      ls_sort-fieldname = 'OBJCT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '11'.
      ls_sort-fieldname = 'ORG_ABB'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '12'.
      ls_sort-fieldname = 'AUTH'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '13'.
      ls_sort-fieldname = 'FIELD'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '14'.
      ls_sort-fieldname = 'VON'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '15'.
      ls_sort-fieldname = 'BIS'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '16'.
      ls_sort-fieldname = 'CHILD_AGR'.
      APPEND ls_sort TO lt_sort.

      l_repid                     = sy-repid.
      ls_layout-zebra             = 'X'.
      ls_layout-colwidth_optimize = 'X'.
      MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
      MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.

      MESSAGE s398(00) WITH text-083.
*      gs_variant-handle = gs_variant-handle + 1.
*      "Changes by RGUPTA on 25th Nov, 2021
      PERFORM check_composite_role USING gt_output-agr_name
            CHANGING lf_composite.
      gf_sum_to_det = 'X'.
      PERFORM toggle_alv_role_init.
      IF lf_composite <> 'X'.
        gs_variant-handle = 3. "Changes by AKUMAR OPL568
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_callback_program       = l_repid
            i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
            it_sort                  = lt_sort
            i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
            is_layout                = ls_layout
            it_fieldcat              = lt_fieldcatalog
            it_filter                = gt_filter_role_detail
            i_save                   = 'A'
             is_variant               = gs_variant

          TABLES
          t_outtab                 = gt_roleoutput_alv
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
        gs_variant-handle = 5.
        gt_croleoutput_alv[] = gt_roleoutput_alv[].
        CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
          EXPORTING
            i_callback_program       = l_repid
            i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
            it_sort                  = lt_sort
            i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
            is_layout                = ls_layout
            it_fieldcat              = lt_fieldcatalog
            it_filter                = gt_filter_role_detail
            i_save                   = 'A'
            is_variant               = gs_variant
          TABLES
            t_outtab                 = gt_croleoutput_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      ENDIF.
*   EOC AKUMAR OPL568
  ENDCASE.
  REFRESH : gt_roleoutput_alv,gt_useroutput_alv,gt_croleoutput_alv.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM ADV_SIMU_DTL_CLICK                                       *
*---------------------------------------------------------------------*
*       Click on advanced simulation detailed screen                  *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM adv_simu_dtl_click USING    r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: l_conid        TYPE /psyng/sw_outputdet3-conid,
        l_field        TYPE authx-fieldname,
        l_field_tobj   TYPE tobj-fiel1,
        l_objct        TYPE tobj-objct,
        l_agr_name     TYPE /psyng/sw_out_routdet3-agr_name,
        l_risktext     TYPE /psyng/sw_risk-text,
        l_line(80)     TYPE c,
        l_retcode      TYPE c,
        l_1stmon(7)    TYPE c,
        l_lastmon(7)   TYPE c,
        lf_answer(1)   TYPE c,
        ls_useroutput  TYPE /psyng/sw_outputdet3,
        ls_roleoutput  TYPE /psyng/sw_out_routdet3,
       lt_tcodes      TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE,
       ls_tcodes      TYPE /psyng/range_tcode,
       lt_fields      TYPE TABLE OF sval WITH HEADER LINE,
       functionid     TYPE slis_selfield-value,
       lv_answer(1)   TYPE c,
       l_sod          TYPE /psyng/swsodvers-vrsio,
       l_uname        LIKE sy-uname,
       l_parva        TYPE usr05-parva,
       l_dynnr        LIKE sy-dynnr,
       l_parva_exists LIKE sy-subrc.
  DATA l_val          TYPE xuvalue.

  FIELD-SYMBOLS: <role> TYPE /psyng/sw_out_routdet3,
                 <user> TYPE /psyng/sw_outputdet3.

  CASE r_ucomm.

    WHEN 'SHOW_TEXTS'.
      PERFORM output_role_details_with_texts.
      EXIT.
    WHEN 'TOGGLE_ORG'.
      CASE gt_output-type.
        WHEN 'ROLE'.
          PERFORM toggle_alv_role_org.
        WHEN 'USER'.
          PERFORM toggle_alv_user_org.
        WHEN OTHERS.
          IF gf_role_det EQ 'X'.
            PERFORM toggle_alv_role_org.
          ELSEIF gf_user_det EQ 'X'.
            PERFORM toggle_alv_user_org.
          ELSEIF gf_user_role_det EQ 'X'.
            PERFORM toggle_alv_mix_org.
          ENDIF.
      ENDCASE.
      EXIT.
    WHEN 'SHOWSIMDET'.
      PERFORM show_role_simu.
      EXIT.
  ENDCASE.

  CASE rs_selfield-fieldname.
    WHEN 'BNAME'.
      CLEAR lf_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
        EXPORTING
          defaultoption     = '1'
          diagnosetext1     = text-036
          diagnosetext2     = text-037
          textline1         = 'View user master or history?'(041)
          text_option1      = 'User Master'(042)
          text_option2      = 'User History'(043)
          icon_text_option1 = 'ICON_TBH'
          icon_text_option2 = 'ICON_HISTORY'
          titel             = text-044
          cancel_display    = 'X'
        IMPORTING
          answer            = lv_answer.

      CASE lv_answer.
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
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
          ENDIF.

        WHEN '2'.
          CLEAR: lt_fields.
          REFRESH: lt_fields.

          PERFORM get_history_months USING l_1stmon l_lastmon.

          lt_fields-tabname   = '/PSYNG/SW_SEL_MON_YEAR'.
          lt_fields-fieldname = 'MMYYYYS'.
          lt_fields-fieldtext = 'From (MM/YYYY)'(045).
          lt_fields-value     = l_1stmon.
          APPEND lt_fields.
          lt_fields-tabname   = '/PSYNG/SW_SEL_MON_YEAR'.
          lt_fields-fieldname = 'MMYYYYE'.
          lt_fields-fieldtext = 'To (MM/YYYY)'(046).
          lt_fields-value     = l_lastmon.
          APPEND lt_fields.

          CLEAR l_retcode.
          CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
            EXPORTING
              formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
              programname       = '/PSYNG/SODREPORT_ORG'
        popup_title       = 'Restrict months (available displayed)'(047)
        ok_pushbuttontext = 'Continue'(048)
      IMPORTING
        returncode        = l_retcode
      TABLES
        fields            = lt_fields
      EXCEPTIONS
        error_in_fields   = 1
        OTHERS            = 2.

          IF sy-subrc <> 0.
            MESSAGE e208(00) WITH 'Error when calling pop-up'(e05).
          ENDIF.

          CHECK l_retcode NE 'A'.  "check to see user doesn't abort

          READ TABLE lt_fields
                     WITH KEY tabname   = '/PSYNG/SW_SEL_MON_YEAR'
                              fieldname = 'MMYYYYS'.
          CHECK NOT lt_fields-value IS INITIAL.
          l_1stmon = lt_fields-value.

          READ TABLE lt_fields
                     WITH KEY tabname   = '/PSYNG/SW_SEL_MON_YEAR'
                              fieldname = 'MMYYYYE'.
          CHECK NOT lt_fields-value IS INITIAL.
          l_lastmon = lt_fields-value.

          SUBMIT /psyng/sw_017
                  WITH pbname   = rs_selfield-value
                  WITH 1stmon   = l_1stmon
                  WITH lastmon  = l_lastmon
                  WITH validusr = ' '
                  AND RETURN.
      ENDCASE.

    WHEN 'AGR_NAME' OR 'CHILD_AGR'.
      CHECK rs_selfield-value <> space.
      READ TABLE gt_roleoutput INDEX rs_selfield-tabindex
                 TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
      l_agr_name = rs_selfield-value.

      CLEAR lf_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
        EXPORTING
          defaultoption     = '1'
          diagnosetext1     = l_agr_name
          diagnosetext2     = text-037
          diagnosetext3     = text-038
          textline1         = text-040
          text_option1      = 'Display Role'(049)
          text_option2      = 'SOD Analysis'(050)
          icon_text_option1 = 'ICON_DISPLAY'
          icon_text_option2 = 'ICON_CHECK'
          titel             = 'Display role or perform SOD check'(051)
          cancel_display    = 'X'
        IMPORTING
          answer            = lf_answer.

      CASE lf_answer.
        WHEN '1'.
          PERFORM display_role_in_pfcg USING l_agr_name.
        WHEN '2'.
          SUBMIT /psyng/sodreport_org
                  WITH role     = l_agr_name
                  WITH byuser   = ' '
                  WITH orgchk   = p_orgchk
                  WITH p_enhanc = p_enhanc
                  WITH p_hienhn = p_hienhn
                  WITH byrole   = 'X'
                  WITH shosum   = 'X'
                  WITH singrol  = 'X'
                  WITH sodvrsio = p_vrsio
                  AND RETURN.
      ENDCASE.

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

      PERFORM set_default_sodversion USING p_vrsio l_uname 0.
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


    WHEN 'TCODE'.
      SELECT ttext FROM tstct INTO l_line
            WHERE sprsl = sy-langu
              AND tcode = rs_selfield-value.
        EXIT.
      ENDSELECT.

      CLEAR lf_answer.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = rs_selfield-value
          text_question         = l_line
          text_button_1         = 'Execute'(029)
          icon_button_1         = 'ICON_EXECUTE_OBJECT'
          text_button_2         = 'Cancel'(030)
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '2'
          display_cancel_button = space
        IMPORTING
          answer                = lf_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      CHECK lf_answer = '1'.

      AUTHORITY-CHECK OBJECT 'S_TCODE'
               ID 'TCD' FIELD rs_selfield-value.
      IF sy-subrc = 0.
*       Check if transaction exists
        SELECT SINGLE tcode FROM tstc INTO rs_selfield-value
                      WHERE tcode = rs_selfield-value.
        IF sy-subrc = 0.
          CALL TRANSACTION rs_selfield-value."#EC PATHLOCK_CI_DYN_ACCES
        ELSE.
          MESSAGE s398(00) WITH 'Transaction does not exist'(031).
        ENDIF.
      ELSE.
        MESSAGE s398(00) WITH 'Not authorized to run transaction'(032).
      ENDIF.

    WHEN 'FIELD'.
      CHECK rs_selfield-value <> space.
      l_field = rs_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
        EXPORTING
          fieldname = l_field.




    WHEN 'RISK'.
      CHECK rs_selfield-value <> space.
      SELECT SINGLE text INTO l_risktext FROM /psyng/sw_risk
                    WHERE risk = rs_selfield-value.
      CHECK sy-subrc = 0.

      CONCATENATE rs_selfield-value '=' l_risktext INTO l_risktext
                  SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Risk Scenario'(035)
          text_question         = l_risktext
          text_button_1         = 'OK'(034)
          icon_button_1         = 'ICON_SYSTEM_OKAY'
          text_button_2         = 'Cancel'(030)
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '1'
          display_cancel_button = space
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found         = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'FUNCTIONID'.
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

      PERFORM set_default_sodversion USING p_vrsio l_uname 0.
      SET PARAMETER ID '/PSYNG/FUN' FIELD rs_selfield-value.
      l_dynnr = '0201'.
      EXPORT g_dynnr FROM l_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname l_parva_exists.

    WHEN 'OBJCT'.
      CHECK rs_selfield-value <> space.

      CASE gt_output-type.
        WHEN 'ROLE'.
          READ TABLE gt_roleoutput INTO ls_roleoutput
                     INDEX rs_selfield-tabindex.

        WHEN 'USER'.
          READ TABLE gt_useroutput INTO ls_useroutput
                     INDEX rs_selfield-tabindex.
        WHEN OTHERS.
          IF gf_user_det EQ 'X'.
            READ TABLE gt_useroutput INTO ls_useroutput
                       INDEX rs_selfield-tabindex.
          ELSEIF gf_role_det EQ 'X'.
            READ TABLE gt_roleoutput INTO ls_roleoutput
                       INDEX rs_selfield-tabindex.
          ELSEIF gf_user_role_det EQ 'X'.
            READ TABLE gt_output_detail
                       INDEX rs_selfield-tabindex.
          ENDIF.
      ENDCASE.

      CHECK sy-subrc = 0.
      l_objct = rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
        EXPORTING
          object  = l_objct
          eu_mode = ' '.

    WHEN 'VON' OR 'BIS'.
      CHECK rs_selfield-value <> space.

      CASE gt_output-type.
        WHEN 'ROLE'.
          READ TABLE gt_roleoutput INTO ls_roleoutput
                     INDEX rs_selfield-tabindex.
          l_field_tobj = ls_roleoutput-field.
          l_objct = ls_roleoutput-objct.
        WHEN 'USER'.
          READ TABLE gt_useroutput INTO ls_useroutput
                     INDEX rs_selfield-tabindex.
          l_field_tobj = ls_useroutput-field.
          l_objct = ls_useroutput-objct.
        WHEN OTHERS.
          IF gf_user_det EQ 'X'.
            READ TABLE gt_useroutput INTO ls_useroutput
                       INDEX rs_selfield-tabindex.
            l_field_tobj = ls_useroutput-field.
            l_objct = ls_useroutput-objct.
          ELSEIF gf_role_det EQ 'X'.
            READ TABLE gt_roleoutput INTO ls_roleoutput
                       INDEX rs_selfield-tabindex.
            l_field_tobj = ls_roleoutput-field.
            l_objct = ls_roleoutput-objct.
          ELSEIF gf_user_role_det EQ 'X'.
            READ TABLE gt_output_detail
                       INDEX rs_selfield-tabindex.
            l_field_tobj = gt_output_detail-field.
            l_objct = gt_output_detail-objct.
          ENDIF.
      ENDCASE.

      CHECK sy-subrc = 0.
*BOC by GSINGH on 08.02.2023 by GSINGH for B17163 - Display OData
*Service details on drill down
      IF l_field_tobj = 'SRV_NAME' AND l_objct = 'S_SERVICE'.
        DATA lv_hash TYPE xupname.
*--Odata Service
        lv_hash =    rs_selfield-value.
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode      = lv_hash
            if_show_message = 'X'
          EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
        IF sy-subrc = 0.
        ENDIF.
*       EOC by GSINGH.
      ELSEIF l_objct = 'S_TCODE' AND l_field_tobj = 'TCD'.
*--Transaction
        SUBMIT  /psyng/se_object_drilldown
         WITH r_tcode  = 'X'
         WITH p_object = 'S_TCODE'
         WITH name     = rs_selfield-value
         AND RETURN.
      ELSE.
*--Other Object
        l_val = rs_selfield-value.
        CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
          EXPORTING
            i_object        = l_objct
            i_field         = l_field_tobj
            i_value         = l_val
            if_show_message = 'X'.
      ENDIF.
    WHEN 'PROFILE'.
      CHECK rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU02'.
      ELSE.
        SET PARAMETER ID 'XUP' FIELD rs_selfield-value.
        CALL TRANSACTION 'SU02'.
      ENDIF.
  ENDCASE.
ENDFORM.                    " adv_simu_dtl_click

*&---------------------------------------------------------------------*
*&      Form  display_role_in_pfcg
*&---------------------------------------------------------------------*
*       Display role in PFCG (local or remote)
*----------------------------------------------------------------------*
*      -->I_AGR_NAME  Role name
*----------------------------------------------------------------------*
FORM display_role_in_pfcg USING    i_agr_name TYPE agr_define-agr_name.
  DATA: lf_answer(1)     TYPE c,
        l_repid          LIKE sy-repid,
        l_retcode(1)     TYPE c,
        l_rfctype        TYPE rfcdes-rfctype,
        l_dflt_rfc       LIKE /psyng/swconfig-value,
        l_pertext(200)   TYPE c,
        lt_fields        TYPE TABLE OF sval WITH HEADER LINE,
        l_system_msg(80) TYPE c.


  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-072
      diagnosetext2     = text-073
      diagnosetext3     = text-074
      textline1         = 'Display local or remote role?'(075)
      text_option1      = 'Local'(076)
      text_option2      = 'Remote'(077)
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = 'Display local or remote role?'(075)
      cancel_display    = 'X'
    IMPORTING
      answer            = lf_answer.

  CASE lf_answer.
    WHEN '1'.
  CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      agr_name = i_agr_name.

    WHEN '2'.
      CLEAR: lt_fields.
      REFRESH: lt_fields.

      se_config_param 'SW_DFLT_RFC_DEST' l_dflt_rfc.
      IF lt_fields[] IS INITIAL.
        lt_fields-tabname   = 'RFCDES'.
        lt_fields-fieldname = 'RFCDEST'.
        lt_fields-fieldtext = 'RFC Destination'(078).
        IF NOT l_dflt_rfc IS INITIAL.
          lt_fields-value = l_dflt_rfc.
        ENDIF.
        APPEND lt_fields.
      ENDIF.

      CLEAR l_retcode.
      CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
        EXPORTING
          formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
          programname       = '/PSYNG/SODREPORT_ORG'
          popup_title       = 'Advanced role simulation'(079)
          ok_pushbuttontext = 'Continue'(048)
        IMPORTING
          returncode        = l_retcode
        TABLES
          fields            = lt_fields
        EXCEPTIONS
          error_in_fields   = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH 'Error when calling pop-up'(e05).
      ENDIF.

      CHECK l_retcode NE 'A'.  "check to see user doesn't abort

      READ TABLE lt_fields WITH KEY tabname   = 'RFCDES'
                                    fieldname = 'RFCDEST'.

      IF lt_fields-value IS INITIAL.
        MESSAGE w208(00) WITH
                'Specify a RFC destination for remote lookup'(e06).
      ENDIF.

      SELECT SINGLE rfctype INTO l_rfctype FROM rfcdes
                    WHERE rfcdest = lt_fields-value
                      AND rfctype = '3'.
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
          DESTINATION lt_fields-value
          EXPORTING
            agr_name      = i_agr_name
          EXCEPTIONS
            agr_not_found = 1
            SYSTEM_FAILURE = 2
            COMMUNICATION_FAILURE = 3
            OTHERS        = 4. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc = 1.
          CLEAR l_pertext.
          CONCATENATE 'Role does not exist in'(080) lt_fields-value
                                    INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.

        ELSEIF sy-subrc = 4.
          CONCATENATE 'Could not open role in'(081)
                      lt_fields-value
                      'check authorizations in RFC Dest.'(085)
                      INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.
        ENDIF.
      ELSE.
        CLEAR l_pertext.
        CONCATENATE 'RFC Destination'(078)
                    lt_fields-value
                    'does not exist'(e01)
                    INTO l_pertext SEPARATED BY space.
        MESSAGE i208(00) WITH l_pertext.
      ENDIF.
  ENDCASE.
ENDFORM.                    " display_role_in_pfcg

*&---------------------------------------------------------------------*
*&      Form  get_history_months
*&---------------------------------------------------------------------*
*       Get dates of available history
*----------------------------------------------------------------------*
*      -->E_1STMON   First month
*      -->E_LASTMON  Last month
*----------------------------------------------------------------------*
FORM get_history_months USING    e_1stmon
                                 e_lastmon.
  DATA: l_1stmonth   TYPE sy-datum,
        l_lastmont   TYPE sy-datum,
        lt_directory TYPE TABLE OF /psyng/sw_dates WITH HEADER LINE.


  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
    TABLES
      idirectory = lt_directory.

  LOOP AT lt_directory.
    IF l_1stmonth IS INITIAL OR l_1stmonth > lt_directory-startdate.
      l_1stmonth = lt_directory-startdate.
    ENDIF.
    IF l_lastmont < lt_directory-startdate.
      l_lastmont = lt_directory-startdate.
    ENDIF.
  ENDLOOP.

  CONCATENATE l_1stmonth+4(2) '/' l_1stmonth(4) INTO e_1stmon.
  CONCATENATE l_lastmont+4(2) '/' l_lastmont(4) INTO e_lastmon.
ENDFORM.                    " get_history_months

*&---------------------------------------------------------------------*
*&      Form  show_role_simu
*&---------------------------------------------------------------------*
*       Show advanced role simulations
*----------------------------------------------------------------------*
FORM show_role_simu.
  DATA: ls_variant      TYPE disvariant,
        l_repid         TYPE sy-repid,
        ls_layout       TYPE slis_layout_alv,
        lt_sort         TYPE TABLE OF slis_sortinfo_alv,
        ls_sort         TYPE slis_sortinfo_alv,
        lt_fieldcatalog TYPE slis_t_fieldcat_alv,
        ls_fieldcatalog TYPE slis_fieldcat_alv,
        lt_simu_role    TYPE TABLE OF /psyng/authobj WITH HEADER LINE.


  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/PSYNG/AUTHOBJ'
    CHANGING
      ct_fieldcat            = lt_fieldcatalog
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

*--Load roles contents again if flag is enabled
*if gf_ADVSIMU_ORG_FULLAUTH = 'Y'.
*  LOOP AT gt_sroles WHERE sel = 'X'.
*          SELECT object auth field low high
*            INTO (gt_faobj_tree-object, gt_faobj_tree-auth,
*                  gt_faobj_tree-field, gt_faobj_tree-val_from,
*                  gt_faobj_tree-val_to)
*            FROM agr_1251
*           WHERE agr_name = gt_sroles-child_agr
*             AND deleted  = space.
*
*            APPEND gt_faobj_tree.
*          ENDSELECT.
*
*          SELECT varbl low high APPENDING TABLE gt_1252 FROM agr_1252
*                 WHERE agr_name = gt_sroles-child_agr.
*        ENDLOOP.
*  else.

*  IMPORT gt_faobj_tree FROM DATABASE moni(db) ID 'FAOBJ'.
*endif.

  LOOP AT gt_faobj_tree.
    MOVE-CORRESPONDING gt_faobj_tree TO lt_simu_role.
    APPEND lt_simu_role.
  ENDLOOP.

  gf_simu_role = 'X'.

  ls_fieldcatalog-seltext_l    = text-t01.
  ls_fieldcatalog-seltext_m    = text-t01.
  ls_fieldcatalog-seltext_s    = text-t01.
  ls_fieldcatalog-reptext_ddic = text-t01.
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'OBJECT'.

  ls_fieldcatalog-seltext_l    = 'Object description'(h15).
  ls_fieldcatalog-seltext_m    = 'Object description'(h15).
  ls_fieldcatalog-seltext_s    = 'Object description'(h15).
  ls_fieldcatalog-reptext_ddic = 'Object description'(h15).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'OTEXT'.

  ls_fieldcatalog-seltext_l    = 'Authorization'(h14).
  ls_fieldcatalog-seltext_m    = 'Authorization'(h14).
  ls_fieldcatalog-seltext_s    = 'Authorization'(h14).
  ls_fieldcatalog-reptext_ddic = 'Authorization'(h14).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'AUTH'.

  ls_fieldcatalog-seltext_l    = 'Field'(h04).
  ls_fieldcatalog-seltext_m    = 'Field'(h04).
  ls_fieldcatalog-seltext_s    = 'Field'(h04).
  ls_fieldcatalog-reptext_ddic = 'Field'(h04).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'FIELD'.

  ls_fieldcatalog-seltext_l    = 'Field description'(h16).
  ls_fieldcatalog-seltext_m    = 'Field description'(h16).
  ls_fieldcatalog-seltext_s    = 'Field description'(h16).
  ls_fieldcatalog-reptext_ddic = 'Field description'(h16).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'DDTEXT'.

  ls_fieldcatalog-seltext_l    = 'From'(h05).
  ls_fieldcatalog-seltext_m    = 'From'(h05).
  ls_fieldcatalog-seltext_s    = 'From'(h05).
  ls_fieldcatalog-reptext_ddic = 'From'(h05).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'VAL_FROM'.

  ls_fieldcatalog-seltext_l    = 'To'(h06).
  ls_fieldcatalog-seltext_m    = 'To'(h06).
  ls_fieldcatalog-seltext_s    = 'To'(h06).
  ls_fieldcatalog-reptext_ddic = 'To'(h06).
  MODIFY lt_fieldcatalog FROM ls_fieldcatalog
         TRANSPORTING seltext_l seltext_m seltext_s reptext_ddic
         WHERE fieldname = 'VAL_TO'.

  ls_sort-spos      = '1'.
  ls_sort-fieldname = 'OBJECT'.
  ls_sort-tabname   = 'LT_SIMU_ROLE'.
  ls_sort-up        = 'X'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '2'.
  ls_sort-fieldname = 'OTEXT'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '3'.
  ls_sort-fieldname = 'AUTH'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '4'.
  ls_sort-fieldname = 'FIELD'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '5'.
  ls_sort-fieldname = 'DDTEXT'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '6'.
  ls_sort-fieldname = 'VAL_FROM'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos      = '7'.
  ls_sort-fieldname = 'VAL_TO'.
  APPEND ls_sort TO lt_sort.

  l_repid                     = sy-repid.
  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.
*  gs_variant-handle = gs_variant-handle + 1.
*  "Changes by RGUPTA on 25th Nov, 2021
  gs_variant-handle = 4. "Changes by AKUMAR OPL568
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = l_repid
      i_callback_top_of_page   = 'ADVSIMU_TOP_OF_PAGE'
      i_callback_pf_status_set = 'ADVSIMU_PF_SIMSTA'
*     i_callback_pf_status_set = 'ADVSIMUDET_PF_STATUS'
      it_sort                  = lt_sort
      is_layout                = ls_layout
      it_fieldcat              = lt_fieldcatalog
      i_save                   = 'A'
is_variant               = gs_variant
"ls_variant Changes by RGUPTA on 25th Nov, 2021
TABLES
t_outtab                 = lt_simu_role
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " show_role_simu
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA : l_tabname  TYPE dd02l-tabname.
*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
    IMPORTING
      e_vrsio = p_vrsio.

  DATA: swconfig TYPE /psyng/swconfig.
*Show Mitigated Conflicts
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.
  IF swconfig-value = 'Y'.
    p_shomit = 'X'.
  ELSEIF swconfig-value = 'N'.
    p_shomit = ' '.
  ENDIF.
  CLEAR swconfig.


**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    p_orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    p_orgchk = ' '.
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

*--Check if ER is installed
  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-invisible = 0.
        screen-invisible = 1.
        screen-active   = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
  ENDIF.
ENDFORM.                    " get_initial_config
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
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
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_input.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.


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
      wp        = wp
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             USE_GROUP_OR_SERVER    = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF l_req_wp > wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE w398(00) WITH 'Only'(093) wp 'processes available.'(092).
  ENDIF.

  IF sy-ucomm = 'GPSV'.
    PERFORM get_server_name.
  ENDIF.
  IF wp GT max_wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE e208(00) WITH 'Specific Server'(003).
  ENDIF.
  PERFORM check_server_is_valid.

ENDFORM.                    " check_input
*&---------------------------------------------------------------------*
*&      Form  get_server_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
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
*&---------------------------------------------------------------------*
*&      Form  check_server_is_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_server_is_valid.
  DATA: ilist TYPE STANDARD TABLE OF msxxlist WITH HEADER LINE.
  DATA: srvexist, messagetxt(80).

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
    srvexist = 'Y'.
  ENDLOOP.
  CONCATENATE 'Server'(065)
              pserver
              'does not exist; check name'(066)
              INTO messagetxt SEPARATED BY space.
  IF srvexist IS INITIAL.
    SET CURSOR FIELD 'PSERVER'.
    MESSAGE e208(00) WITH messagetxt.
  ENDIF.

ENDFORM.                    " check_server_is_valid
*&---------------------------------------------------------------------*
*&      Form  disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM disp_total_servers_for_sel.
  DATA: lv_title(20).
  DATA lv_btchost LIKE msxxlist-host.
  MOVE 'Select server :'(064) TO lv_title.

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
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SOD  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname
                                  l_delete TYPE sy-subrc.
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
  IF l_delete <> 0.
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
  .

ENDFORM.                    " set_default_sodversion

FORM detail_view.
  DATA : lt_users     TYPE TABLE OF /psyng/range_bname WITH HEADER LINE,
        lt_conflicts TYPE TABLE OF /psyng/range_conid WITH HEADER LINE,
      lt_roles     TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE.
  DATA: l_repid         TYPE sy-repid,
        ls_variant      TYPE disvariant,
        ls_layout       TYPE slis_layout_alv,
        lt_sort         TYPE TABLE OF slis_sortinfo_alv,
        ls_sort         TYPE slis_sortinfo_alv,
        lt_fieldcatalog TYPE slis_t_fieldcat_alv,
        ls_fieldcatalog TYPE slis_fieldcat_alv,
        ls_cc           TYPE lvc_s_scol,
        ls_color        TYPE lvc_s_colo,
        l_uname         LIKE sy-uname,
        l_contid        TYPE /psyng/mchdr-contid,
        l_parva         TYPE usr05-parva,
        l_sod           TYPE /psyng/swsodvers-vrsio,
        l_parva_exists  LIKE sy-subrc.

  FREE: lt_users, lt_conflicts, gt_useroutput, lt_roles.

  IF  p_user =  'X'.
    lt_users[] = gt_bname[].
    FREE: gt_useroutput.

    IF lt_users[] IS INITIAL.
        MESSAGE s002 WITH 'No impacted users found'(000).
    ELSE.

      CALL FUNCTION '/PSYNG/SW_081'
        EXPORTING
          i_byuser              = 'X'
          i_orgchk              = p_orgchk
          i_sodvrsio            = p_vrsio
          i_enhanc              = p_enhanc
          i_hienhn              = p_hienhn
          i_shosum              = ' '
          i_advanced_role_simu  = 'X'
          i_exclude_er_roles    = excl_er
          i_xmc                 = p_shomit
          i_config_set          = cfgset
          i_org_field           = gf_org_field "AKUMAR OPL645
        TABLES
          it_sens               = s_imp
          it_bname              = lt_users
          it_conflicts          = lt_conflicts
          et_outputdet          = gt_useroutput
          it_advanced_role_simu = gt_advanced_role_sim[]
  "(++)BOC UMITTAL SE VF scan-25/11/2024
             EXCEPTIONS
               USER_CANCELLED          = 1
               OTHERS                 = 2 .
     IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.


   ENDIF. "(++)EOC UMITTAL USER is blank-03/01/2025.
    FREE : gt_useroutput_alv.
    LOOP AT gt_useroutput.
      CLEAR gt_useroutput_alv.
      MOVE-CORRESPONDING gt_useroutput TO gt_useroutput_alv.
      IF gt_useroutput_alv-enhanced = 'X'.
        DELETE gt_useroutput_alv-color_cell WHERE fname = 'CONID'.
        ls_color-col = '7'.   "Orange
        ls_color-int = '1'.   "Intensified
        ls_color-inv = '0'.   "Inverse
        ls_cc-color  = ls_color.
        ls_cc-fname  = 'CONID'.
        APPEND ls_cc TO gt_useroutput_alv-color_cell.
        ls_cc-fname  = 'TCODE'.
        APPEND ls_cc TO gt_useroutput_alv-color_cell.
      ENDIF.
      APPEND gt_useroutput_alv.
    ENDLOOP.
    IF p_crole IS INITIAL AND p_srole IS INITIAL.
      CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = '/PSYNG/SW_ADV_SIMU_OUTPUTDET_U'
        CHANGING
          ct_fieldcat            = lt_fieldcatalog
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      ls_fieldcatalog-hotspot      = 'X'.
      ls_fieldcatalog-seltext_l    = 'User ID'(h00).
      ls_fieldcatalog-seltext_m    = 'User ID'(h00).
      ls_fieldcatalog-seltext_s    = 'User ID'(h00).
      ls_fieldcatalog-reptext_ddic = 'User ID'(h00).

      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BNAME'.

      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'TCODE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'FUNCTIONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'OBJCT'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'PROFILE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'RISK'.

      ls_fieldcatalog-col_pos = 4.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING col_pos
             WHERE fieldname = 'DESCRIPTION'.

      ls_fieldcatalog-seltext_l    = 'Field'(h04).
      ls_fieldcatalog-seltext_m    = 'Field'(h04).
      ls_fieldcatalog-seltext_s    = 'Field'(h04).
      ls_fieldcatalog-reptext_ddic = 'Field'(h04).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'FIELD'.

      ls_fieldcatalog-seltext_l    = 'From'(h05).
      ls_fieldcatalog-seltext_m    = 'From'(h05).
      ls_fieldcatalog-seltext_s    = 'From'(h05).
      ls_fieldcatalog-reptext_ddic = 'From'(h05).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'VON'.
      ls_fieldcatalog-seltext_l    = 'To'(h06).
      ls_fieldcatalog-seltext_m    = 'To'(h06).
      ls_fieldcatalog-seltext_s    = 'To'(h06).
      ls_fieldcatalog-reptext_ddic = 'To'(h06).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BIS'.

      ls_fieldcatalog-seltext_l    = 'Single/Child Role'(m40).
      ls_fieldcatalog-seltext_m    = 'Single/Child Role'(m40).
      ls_fieldcatalog-seltext_s    = 'Single/Child Role'(m40).
      ls_fieldcatalog-reptext_ddic = 'Single/Child Role'(m40).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'CHILD_AGR'.

      ls_fieldcatalog-seltext_l    = 'Composite Role'(M41).
      ls_fieldcatalog-seltext_m    = 'Composite Role'(M41).
      ls_fieldcatalog-seltext_s    = 'Composite Role'(M41).
      ls_fieldcatalog-reptext_ddic = 'Composite Role'(M41).
      ls_fieldcatalog-no_out = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING no_out seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'COMP_AGR'.

*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
      ls_fieldcatalog-checkbox     = 'X'.
      ls_fieldcatalog-just         = 'X'.
      ls_fieldcatalog-seltext_l    = text-118. "'Simulation'(h08).
      ls_fieldcatalog-seltext_m    = text-118."'Simulation'(h08).
      ls_fieldcatalog-seltext_s    = text-118."'Simulation'(h08).
      ls_fieldcatalog-reptext_ddic = text-118."'Simulation'(h08).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox just seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'SIMU'.

      IF p_enhanc = 'X'.
        CLEAR ls_fieldcatalog-no_out.
      ELSE.
        ls_fieldcatalog-no_out = 'X'.
      ENDIF.

      ls_fieldcatalog-seltext_l    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_m    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_s    = 'Enhanced'(h07).
      ls_fieldcatalog-reptext_ddic = 'Enhanced'(h07).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox seltext_l seltext_m seltext_s
                          reptext_ddic no_out
             WHERE fieldname = 'ENHANCED'.


      ls_fieldcatalog-no_out = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
             WHERE fieldname = 'IMPSORT'.

*--Don't show the org_type field ever
      ls_fieldcatalog-no_out = 'X'.
      ls_fieldcatalog-seltext_l = 'Org Output Type'.
      ls_fieldcatalog-seltext_m = 'Org Output Type'.
      ls_fieldcatalog-seltext_s = 'Org Type'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          no_out
                       WHERE
                          fieldname = 'ORG_TYPE'.

      ls_sort-spos      = '1'.
      ls_sort-fieldname = 'BNAME'.
      ls_sort-tabname   = 'GT_USEROUTPUT'.
      ls_sort-up        = 'X'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '2'.
      ls_sort-fieldname = 'ORG_ABB'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '3'.
      ls_sort-fieldname = 'IMPSORT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '4'.
      ls_sort-fieldname = 'IMP'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '5'.
      ls_sort-fieldname = 'CONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '6'.
      ls_sort-fieldname = 'DESCRIPTION'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '7'.
      ls_sort-fieldname = 'RISK'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '8'.
      ls_sort-fieldname = 'FUNCTIONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '9'.
      ls_sort-fieldname = 'COMP_AGR'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '10'.
      ls_sort-fieldname = 'AGR_NAME'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '11'.
      ls_sort-fieldname = 'RFCDEST'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '12'.
      ls_sort-fieldname = 'TCODE'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '13'.
      ls_sort-fieldname = 'OBJCT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '14'.
      ls_sort-fieldname = 'AUTH'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '15'.
      ls_sort-fieldname = 'FIELD'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '16'.
      ls_sort-fieldname = 'VON'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '17'.
      ls_sort-fieldname = 'BIS'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '18'.
      ls_sort-fieldname = 'PROFILE'.
      APPEND ls_sort TO lt_sort.

      l_repid                     = sy-repid.
      ls_layout-zebra             = 'X'.
      ls_layout-colwidth_optimize = 'X'.
      MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
      MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.


      MESSAGE s398(00) WITH text-083.
      gs_variant-handle = 2. "Changes by RGUPTA on 25th Nov, 2021
      gf_user_det = 'X'.
      PERFORM toggle_alv_user_init.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_callback_program       = l_repid
          i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
          it_sort                  = lt_sort
          i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
          is_layout                = ls_layout
          it_fieldcat              = lt_fieldcatalog
          it_filter                = gt_filter_user_detail
          i_save                   = 'A'
          is_variant               = gs_variant
*"ls_variant Changes by RGUPTA on 25th Nov, 2021
  TABLES
         t_outtab                 = gt_useroutput_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      CLEAR gf_user_det.
      MESSAGE s398(00) WITH text-083.
    ENDIF.
  ENDIF.
*  IF  gt_output-type = 'ROLE'.
  IF p_crole EQ 'X' OR p_srole  EQ 'X'.
*    lt_roles-sign   = 'I'.
*    lt_roles-option = 'EQ'.
*    lt_roles-low    = gt_output-agr_name.
*    APPEND lt_roles.
    READ TABLE gt_advanced_role_sim INDEX 1.
    FREE : gt_roleoutput,gt_roleoutput_alv.
    CALL FUNCTION '/PSYNG/SW_083'
     EXPORTING
       i_orgchk              = p_orgchk
       i_sodvrsio            = p_vrsio
       i_enhanc              = p_enhanc
       i_hienhn              = p_hienhn
*        i_advanced_role_simu  = 'X'
       i_shomit              = p_shomit
       i_config_set          = cfgset
       i_org_field           = gf_org_field "AKUMAR OPL645
     TABLES
       it_sens               = s_imp
       it_roles              = gt_roles_to_analyze
       it_conflicts          = lt_conflicts
       et_outputdet          = gt_roleoutput_bsimu.
*       it_advanced_role_simu = gt_advanced_role_sim.

    CALL FUNCTION '/PSYNG/SW_083'
      EXPORTING
        i_orgchk              = p_orgchk
        i_sodvrsio            = p_vrsio
        i_enhanc              = p_enhanc
        i_hienhn              = p_hienhn
        i_advanced_role_simu  = 'X'
        i_shomit              = p_shomit
        i_config_set          = cfgset
        i_refresh_auth        = 'X'"(++)UMITTAL OPL-640 24/02/2025
        i_org_field           = gf_org_field "AKUMAR OPL645
      TABLES
        it_sens               = s_imp
        it_roles              = gt_roles_to_analyze
        it_conflicts          = lt_conflicts
        et_outputdet          = gt_roleoutput_asimu
       it_advanced_role_simu = gt_advanced_role_sim.
    SORT gt_roleoutput_asimu BY agr_name conid.
    SORT gt_roleoutput_bsimu BY agr_name conid.
    LOOP AT gt_roleoutput_asimu.
      READ TABLE gt_roleoutput_bsimu
              WITH KEY agr_name = gt_roleoutput_asimu-agr_name
                        conid   = gt_roleoutput_asimu-conid
                        BINARY SEARCH.
      IF sy-subrc EQ 0.
        CLEAR gt_roleoutput_asimu-simu.
      ENDIF.
      APPEND gt_roleoutput_asimu TO gt_roleoutput.

    ENDLOOP.
    FREE: gt_roleoutput_bsimu,gt_roleoutput_asimu.
*  LOOP AT gt_roleoutput_bsimu.
*      READ TABLE gt_roleoutput_asimu
*              WITH KEY agr_name = gt_roleoutput_asimu-agr_name
*                        conid   = gt_roleoutput_asimu-conid
*                        BINARY SEARCH.
*      IF sy-subrc ne 0.
*        gt_roleoutput_bsimu-simu = 'X'.
*         APPEND gt_roleoutput_bsimu TO gt_roleoutput.
*      ENDIF.
*
*
*    ENDLOOP.


    LOOP AT gt_roleoutput.
      CLEAR gt_roleoutput_alv.
      MOVE-CORRESPONDING gt_roleoutput TO routdet4.
      routdet4-appl = 'SAP'.
      APPEND routdet4.
      MOVE-CORRESPONDING gt_roleoutput TO gt_roleoutput_alv.
      IF gt_roleoutput_alv-enhanced = 'X'.
        DELETE gt_roleoutput_alv-color_cell WHERE fname = 'CONID'.
        ls_color-col = '7'.   "Orange
        ls_color-int = '1'.   "Intensified
        ls_color-inv = '0'.   "Inverse
        ls_cc-color  = ls_color.
        ls_cc-fname  = 'CONID'.
        APPEND ls_cc TO gt_roleoutput_alv-color_cell.
        ls_cc-fname  = 'TCODE'.
        APPEND ls_cc TO gt_roleoutput_alv-color_cell.
      ENDIF.
      APPEND gt_roleoutput_alv.
    ENDLOOP.

    IF p_user IS INITIAL.
      CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
        EXPORTING
          i_structure_name       = '/PSYNG/SW_ADV_SIMU_OUTPUTDET_R'
        CHANGING
          ct_fieldcat            = lt_fieldcatalog
        EXCEPTIONS
          inconsistent_interface = 1
          program_error          = 2
          OTHERS                 = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      ls_fieldcatalog-no_out = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
             WHERE fieldname = 'ISORT'.

      ls_fieldcatalog-hotspot = 'X'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'AGR_NAME'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'TCODE'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'FUNCTIONID'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'OBJCT'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'CHILD_AGR'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
             WHERE fieldname = 'RISK'.

      ls_fieldcatalog-col_pos = 4.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING col_pos
             WHERE fieldname = 'DESCRIPTION'.

      ls_fieldcatalog-seltext_l    = 'Field'(h04).
      ls_fieldcatalog-seltext_m    = 'Field'(h04).
      ls_fieldcatalog-seltext_s    = 'Field'(h04).
      ls_fieldcatalog-reptext_ddic = 'Field'(h04).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'FIELD'.

      ls_fieldcatalog-seltext_l    = 'From'(h05).
      ls_fieldcatalog-seltext_m    = 'From'(h05).
      ls_fieldcatalog-seltext_s    = 'From'(h05).
      ls_fieldcatalog-reptext_ddic = 'From'(h05).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'VON'.

      ls_fieldcatalog-seltext_l    = 'To'(h06).
      ls_fieldcatalog-seltext_m    = 'To'(h06).
      ls_fieldcatalog-seltext_s    = 'To'(h06).
      ls_fieldcatalog-reptext_ddic = 'To'(h06).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING hotspot seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'BIS'.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
      ls_fieldcatalog-checkbox     = 'X'.
      ls_fieldcatalog-just         = 'X'.
      ls_fieldcatalog-seltext_l    = text-118."'Simulation'(h08).
      ls_fieldcatalog-seltext_m    = text-118."'Simulation'(h08).
      ls_fieldcatalog-seltext_s    = text-118."'Simulation'(h08).
      ls_fieldcatalog-reptext_ddic = text-118."'Simulation'(h08).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox just seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'SIMU'.


      ls_fieldcatalog-seltext_l    = 'Single/Child Role'(099).
      ls_fieldcatalog-seltext_m    = 'Single/Child Role'(099).
      ls_fieldcatalog-seltext_s    = 'Single Role'(216).
      ls_fieldcatalog-reptext_ddic = 'Single/Child Role'(099).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING seltext_l seltext_m seltext_s
                          reptext_ddic
             WHERE fieldname = 'CHILD_AGR'.
      IF p_enhanc = 'X'.
        CLEAR ls_fieldcatalog-no_out.
      ELSE.
        ls_fieldcatalog-no_out = 'X'.
      ENDIF.

      ls_fieldcatalog-seltext_l    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_m    = 'Enhanced'(h07).
      ls_fieldcatalog-seltext_s    = 'Enhanced'(h07).
      ls_fieldcatalog-reptext_ddic = 'Enhanced'(h07).
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
             TRANSPORTING checkbox seltext_l seltext_m seltext_s
                          reptext_ddic no_out
             WHERE fieldname = 'ENHANCED'.
*--Don't show the org_type field ever
      ls_fieldcatalog-no_out = 'X'.
      ls_fieldcatalog-seltext_l = 'Org Output Type'.
      ls_fieldcatalog-seltext_m = 'Org Output Type'.
      ls_fieldcatalog-seltext_m = 'Org Output Type'.
      MODIFY lt_fieldcatalog FROM ls_fieldcatalog
                        TRANSPORTING
                          seltext_l
                          seltext_m
                          seltext_s
                          no_out
                       WHERE
                          fieldname = 'ORG_TYPE'.

      ls_sort-spos      = '1'.
      ls_sort-fieldname = 'AGR_NAME'.
      ls_sort-tabname   = 'GT_ROLEOUTPUT'.
      ls_sort-up        = 'X'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '2'.
      ls_sort-fieldname = 'ISORT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '3'.
      ls_sort-fieldname = 'IMP'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '4'.
      ls_sort-fieldname = 'CONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '5'.
      ls_sort-fieldname = 'DESCRIPTION'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '6'.
      ls_sort-fieldname = 'RISK'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '7'.
      ls_sort-fieldname = 'FUNCTIONID'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '8'.
      ls_sort-fieldname = 'RFCDEST'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '9'.
      ls_sort-fieldname = 'TCODE'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '10'.
      ls_sort-fieldname = 'OBJCT'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '11'.
      ls_sort-fieldname = 'ORG_ABB'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '12'.
      ls_sort-fieldname = 'AUTH'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '13'.
      ls_sort-fieldname = 'FIELD'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '14'.
      ls_sort-fieldname = 'VON'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '15'.
      ls_sort-fieldname = 'BIS'.
      APPEND ls_sort TO lt_sort.
      ls_sort-spos      = '16'.
      ls_sort-fieldname = 'CHILD_AGR'.
      APPEND ls_sort TO lt_sort.

      l_repid                     = sy-repid.
      ls_layout-zebra             = 'X'.
      ls_layout-colwidth_optimize = 'X'.
      MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
      MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.

      MESSAGE s398(00) WITH text-083.
      gs_variant-handle = 2. "Changes by RGUPTA on 25th Nov, 2021
      gf_role_det = 'X'.
*--If Configuration set functionality is enabled,
* prepare info for toggling variable and org values.
      PERFORM toggle_alv_role_init.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          i_callback_program       = l_repid
          i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
          it_sort                  = lt_sort
          i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
          is_layout                = ls_layout
          it_fieldcat              = lt_fieldcatalog
          it_filter                = gt_filter_role_detail
          i_save                   = 'A'
  is_variant               = gs_variant
*"ls_variant "Changes by RGUPTA on 25th Nov, 2021
  TABLES
  t_outtab                 = gt_roleoutput_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      CLEAR gf_role_det.
      REFRESH : gt_roleoutput_alv,gt_useroutput_alv.
    ENDIF.
    MESSAGE s398(00) WITH text-083.
  ENDIF.
  IF p_user EQ 'X' AND
        ( p_crole EQ 'X' OR p_srole  EQ 'X' ).

    LOOP AT gt_roleoutput_alv.
      MOVE-CORRESPONDING gt_roleoutput_alv TO gs_output_detail.
      gs_output_detail-type = 'Role'.
      APPEND gs_output_detail TO gt_output_detail.

    ENDLOOP.

    LOOP AT gt_useroutput_alv.
      MOVE-CORRESPONDING gt_useroutput_alv TO gs_output_detail.
      gs_output_detail-type = 'User'.
*BOC:HBHALLA (R3:CASE4) (PN-11675)
      gs_output_detail-child_agr = gt_useroutput_alv-agr_name.
*EOC:HBHALLA (R3:CASE4) (PN-11675)
      APPEND gs_output_detail TO gt_output_detail.
    ENDLOOP.
    ls_layout-zebra             = 'X'.
    ls_layout-colwidth_optimize = 'X'.
    MOVE 'COLOR_CELL' TO ls_layout-coltab_fieldname.
    MOVE 'COLOR_LINE' TO ls_layout-info_fieldname.
    FREE : i_fieldcat_alv.
*  'GT_OUTPUT_DETAIL'.
    REFRESH lt_fieldcatalog[].
    CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
      EXPORTING
        i_program_name     = program
        i_internal_tabname = 'GT_OUTPUT_DETAIL'
        i_inclname         = program
      CHANGING
        ct_fieldcat        = lt_fieldcatalog
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

    ls_fieldcatalog-no_out = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
           WHERE fieldname = 'ORG_TYPE'.

    ls_fieldcatalog-no_out = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING no_out
           WHERE fieldname = 'ISORT'.
    ls_fieldcatalog-seltext_l    = 'SOD Type'(h21).
    ls_fieldcatalog-seltext_m    = 'SOD Type'(h21).
    ls_fieldcatalog-seltext_s    = 'SOD Type'(h21).
    ls_fieldcatalog-reptext_ddic = 'SOD Type'(h21).

    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING hotspot seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'TYPE'.
    ls_fieldcatalog-hotspot      = 'X'.
    ls_fieldcatalog-seltext_l    = 'User ID'(h00).
    ls_fieldcatalog-seltext_m    = 'User ID'(h00).
    ls_fieldcatalog-seltext_s    = 'User ID'(h00).
    ls_fieldcatalog-reptext_ddic = 'User ID'(h00).

    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING hotspot seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'BNAME'.

    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'AGR_NAME'.

    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'BNAME'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'CONID'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'TCODE'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'FUNCTIONID'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'OBJCT'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'CHILD_AGR'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'RISK'.

    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING hotspot
           WHERE fieldname = 'PROFILE'.
    ls_fieldcatalog-col_pos = 4.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog TRANSPORTING col_pos
           WHERE fieldname = 'DESCRIPTION'.

    ls_fieldcatalog-seltext_l    = 'Field'(h04).
    ls_fieldcatalog-seltext_m    = 'Field'(h04).
    ls_fieldcatalog-seltext_s    = 'Field'(h04).
    ls_fieldcatalog-reptext_ddic = 'Field'(h04).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING hotspot seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'FIELD'.

    ls_fieldcatalog-seltext_l    = 'From'(h05).
    ls_fieldcatalog-seltext_m    = 'From'(h05).
    ls_fieldcatalog-seltext_s    = 'From'(h05).
    ls_fieldcatalog-reptext_ddic = 'From'(h05).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING hotspot seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'VON'.

    ls_fieldcatalog-seltext_l    = 'To'(h06).
    ls_fieldcatalog-seltext_m    = 'To'(h06).
    ls_fieldcatalog-seltext_s    = 'To'(h06).
    ls_fieldcatalog-reptext_ddic = 'To'(h06).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING hotspot seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'BIS'.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
    ls_fieldcatalog-checkbox     = 'X'.
    ls_fieldcatalog-just         = 'X'.
    ls_fieldcatalog-seltext_l    = text-118."'Simulation'(h08).
    ls_fieldcatalog-seltext_m    = text-118."'Simulation'(h08).
    ls_fieldcatalog-seltext_s    = text-118."'Simulation'(h08).
    ls_fieldcatalog-reptext_ddic = text-118."'Simulation'(h08).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING checkbox just seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'SIMU'.

    IF p_enhanc = 'X'.
      CLEAR ls_fieldcatalog-no_out.
    ELSE.
      ls_fieldcatalog-no_out = 'X'.
    ENDIF.

    ls_fieldcatalog-seltext_l    = 'Enhanced'(h07).
    ls_fieldcatalog-seltext_m    = 'Enhanced'(h07).
    ls_fieldcatalog-seltext_s    = 'Enhanced'(h07).
    ls_fieldcatalog-reptext_ddic = 'Enhanced'(h07).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING checkbox seltext_l seltext_m seltext_s
                        reptext_ddic no_out
           WHERE fieldname = 'ENHANCED'.
    ls_fieldcatalog-seltext_l    = 'Single/Child Role'(099).
    ls_fieldcatalog-seltext_m    = 'Single/Child Role'(099).
    ls_fieldcatalog-seltext_s    = 'Single Role'(216).
    ls_fieldcatalog-reptext_ddic = 'Single/Child Role'(099).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING  seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'CHILD_AGR'.

    ls_fieldcatalog-seltext_l    = 'Comp. Role'(m43).
    ls_fieldcatalog-seltext_m    = 'Comp. Role'(m43).
    ls_fieldcatalog-seltext_s    = 'Comp. Role'(m43).
    ls_fieldcatalog-reptext_ddic = 'Comp. Role'(m43).
    ls_fieldcatalog-no_out = 'X'.
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING  no_out seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'COMP_AGR'.

    ls_fieldcatalog-seltext_l    = 'Application'(233).
    ls_fieldcatalog-seltext_m    = 'Application'(233).
    ls_fieldcatalog-seltext_s    = 'App'(234).
    ls_fieldcatalog-reptext_ddic = 'Application'(233).
    MODIFY lt_fieldcatalog FROM ls_fieldcatalog
           TRANSPORTING  seltext_l seltext_m seltext_s
                        reptext_ddic
           WHERE fieldname = 'APPL'.
    DELETE lt_fieldcatalog WHERE fieldname = 'COLOR_LINE'.
    DELETE lt_fieldcatalog WHERE fieldname = 'COLOR_CELL'.
    ls_sort-spos      = '1'.
    ls_sort-fieldname = 'TYPE'.
    ls_sort-tabname   = 'GT_OUTPUT_DETAIL'.
    ls_sort-up        = 'X'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '2'.
    ls_sort-fieldname = 'BNAME'.
    ls_sort-tabname   = 'GT_OUTPUT_DETAIL'.
    ls_sort-up        = 'X'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '3'.
    ls_sort-fieldname = 'AGR_NAME'.
    ls_sort-tabname   = 'GT_OUTPUT_DETAIL'.
    ls_sort-up        = 'X'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '4'.
    ls_sort-fieldname = 'ISORT'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '5'.
    ls_sort-fieldname = 'IMP'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '6'.
    ls_sort-fieldname = 'CONID'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '7'.
    ls_sort-fieldname = 'DESCRIPTION'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '8'.
    ls_sort-fieldname = 'RISK'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '9'.
    ls_sort-fieldname = 'FUNCTIONID'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '10'.
    ls_sort-fieldname = 'RFCDEST'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '11'.
    ls_sort-fieldname = 'TCODE'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '12'.
    ls_sort-fieldname = 'OBJCT'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '13'.
    ls_sort-fieldname = 'ORG_ABB'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '14'.
    ls_sort-fieldname = 'AUTH'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '15'.
    ls_sort-fieldname = 'FIELD'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '16'.
    ls_sort-fieldname = 'VON'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '17'.
    ls_sort-fieldname = 'BIS'.
    APPEND ls_sort TO lt_sort.
    ls_sort-spos      = '18'.
    ls_sort-fieldname = 'CHILD_AGR'.
    APPEND ls_sort TO lt_sort.
*    sort lt_sort by fieldname.

    l_repid                     = sy-repid.

    gs_variant-handle = 2.
    gf_user_role_det = 'X'.
    PERFORM toggle_alv_mix_init.
    CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
  EXPORTING
    i_callback_program       = l_repid
    i_callback_pf_status_set = 'ADVSIMU_PF_STATUS'
    it_sort                  = lt_sort
    i_callback_user_command  = 'ADV_SIMU_DTL_CLICK'
    is_layout                = ls_layout
    it_fieldcat              = lt_fieldcatalog
    it_filter                = gt_filter_mix_detail
    i_save                   = 'A'
    is_variant               = gs_variant
  TABLES
     t_outtab                = gt_output_detail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    CLEAR gf_user_role_det.
    MESSAGE s398(00) WITH text-083.
  ENDIF.
ENDFORM.

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

*++BOC UMITTAL 16/04/24 PN-4356 D67K931016
*Filling the routdet4 table for the
*SHOW TEXT button not showing details
*in summary mode in Advanced Role simulation
  IF routdet4 IS INITIAL.
    LOOP AT gt_roleoutput_alv.
      MOVE-CORRESPONDING gt_roleoutput_alv TO routdet4.
      routdet4-appl = 'SAP'.
      APPEND routdet4.
    ENDLOOP.
*BOC:HBHALLA :PN-11675 (CASE8) (OPL647)
    LOOP AT gt_useroutput_alv.
          MOVE-CORRESPONDING gt_useroutput_alv TO routdet4.
          routdet4-appl = 'SAP'.
          APPEND routdet4.
    ENDLOOP.
  SORT routdet4.
  DELETE ADJACENT DUPLICATES FROM routdet4.
*EOC:HBHALLA :PN-11675 (CASE8) (OPL647)
  ENDIF.
*++EOC UMITTAL 16/04/24 PN-4356 D67K931016
*--Move to output table with texts and collect unique names
  FREE : r_output_det_text.
  LOOP AT routdet4.
    MOVE-CORRESPONDING routdet4 TO r_output_det_text.
    IF routdet4-appl = 'SAP'.
*       OR p_nabap IS INITIAL.
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
*        LOOP AT gt_rfcdest.
        CALL FUNCTION '/PSYNG/BC_021'
*            DESTINATION gt_rfcdest-rfcdest
          EXPORTING
            i_agr_name            = lt_agr_names-agr_name
          IMPORTING
            e_text                = lt_agr_texts-text
          EXCEPTIONS
            communication_failure = 1 "MESSAGE l_system_msg
            system_failure        = 2 "MESSAGE l_system_msg
            OTHERS                = 3.
        IF sy-subrc = 0.
          IF NOT   lt_agr_texts-text IS INITIAL.
            INSERT TABLE lt_agr_texts.
            EXIT.
          ENDIF.
        ENDIF.
*        ENDLOOP.
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
        AND vrsio      EQ p_vrsio
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
*  IF p_nabap = 'X'. "Add screen id description
*    IF NOT lt_screen[] IS INITIAL.
*      l_table_en = '/PSYNG/EX_URHDR'.
*      SELECT usrrt udesc sysid appl FROM (l_table_en)
*      INTO TABLE lt_screen_texts
*      FOR ALL ENTRIES IN lt_screen
*      WHERE usrrt = lt_screen-usrrt
*            AND appl = lt_screen-appl
*             AND
*              (
*                ( sysid = lt_screen-sysid AND sysdep = 'X' )
*                OR
*                ( sysid = 'ALL' AND sysdep <> 'X' )
*              ).
*
*      LOOP AT lt_screen_texts.
*        lt_tcode_texts-tcode = lt_screen_texts-usrrt.
*        lt_tcode_texts-ttext = lt_screen_texts-udesc.
*        lt_tcode_texts-sysid = lt_screen_texts-sysid.
*        lt_tcode_texts-appl = lt_screen_texts-appl.
*        APPEND lt_tcode_texts.
*      ENDLOOP.
*    ENDIF.
*  ENDIF.

  IF NOT lt_func_names[] IS INITIAL.
    SELECT function description FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE lt_func_texts
    FOR ALL ENTRIES IN lt_func_names
    WHERE
    function = lt_func_names-function AND
    vrsio    = p_vrsio.
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
  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
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
*---------------------------------------------------------------------*
***** REPEAT_HDR_BKGDJOB Flag Check
*---------------------------------------------------------------------*
*  IF gf_prevent_hdr = 'X'.
*    DESCRIBE TABLE 1stoutput LINES ls_line_count.
*    PERFORM set_print_param USING ls_line_count.
*  ENDIF.
*---------------------------------------------------------------------*
  gs_variant-handle = 2.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = program
     it_sort                  = isort
      i_callback_user_command  = 'ROLE_DOUBLE_CLICK_ON_DETL'
      i_callback_pf_status_set = 'SET_PF_STATUS'
      is_layout                = alv_layout
      it_fieldcat              = i_fieldcat_alv
      i_save                   = 'A'
      is_variant               = gs_variant"ls_variant
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
  wa_fieldcat_alv-seltext_m = text-593.
  wa_fieldcat_alv-seltext_s = text-593.
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
  DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
*  IF bysimu = 'X'.
*    wa_fieldcat_alv-seltext_l = text-115.
*    wa_fieldcat_alv-seltext_m = text-115.
*    wa_fieldcat_alv-seltext_s = text-116.
*    wa_fieldcat_alv-reptext_ddic = text-115.
*    wa_fieldcat_alv-checkbox     = 'X'.
*    wa_fieldcat_alv-just     = 'X'.
*    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                      TRANSPORTING
*                        seltext_l
*                        seltext_m
*                        seltext_s
*                        reptext_ddic
*                        checkbox
*                        just
*                     WHERE
*                        fieldname = 'SIMU'.
*  ELSE.
*   DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
*  ENDIF.

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
*  IF orgchk IS INITIAL.
** hide column org_abb
*    wa_fieldcat_alv-no_out = 'X'.
*    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                      TRANSPORTING
*                        no_out
*                     WHERE
*                        fieldname = 'ORG_ABB'.
*
*  ENDIF.


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
*  IF p_nabap IS INITIAL.
*    wa_fieldcat_alv-no_out = 'X'.
*
*  ENDIF.
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
  wa_fieldcat_alv-no_out  = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                      no_out
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
       l_system    TYPE /psyng/system.

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

      PERFORM set_default_sodversion USING p_vrsio l_uname 0.
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
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
          i_tcode     = l_tcode
          i_vrsio     = p_vrsio
          i_funid     = routdet4-functionid
*          if_non_abap = p_nabap
          i_appl      = routdet4-appl
          i_system    = l_system.

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
             text_not_found          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'FIELD'.
      CHECK rs_selfield-value <> space.
      authfield = rs_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
        EXPORTING
          fieldname = authfield.


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

      PERFORM set_default_sodversion USING p_vrsio l_uname 0.
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
      iobjct = rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
        EXPORTING
          object  = iobjct
          eu_mode = ' '.

    WHEN 'VON'.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
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

    WHEN 'BIS'.
      CHECK rs_selfield-value <> space.
      READ TABLE routdet4 INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
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
*      CLEAR g_agrname_dtlclk.
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
             SOURCE_ROLID_DOESNT_EXIST  = 1
             NOT_AUTHORIZED_TO_DISPLAY  = 2
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
            answer            = answer.

        CASE answer.
          WHEN '1'.
            PERFORM role_sod_analysis_en_detail USING agr_name
                                                     routdet4-rfcdest
                                                     routdet4-appl
                                                     p_vrsio.
          WHEN '2'.
            EXIT.
        ENDCASE.
      ELSE.

*     Om 14.08.2018 adding Role Usase Matrix button if TA installed
*        CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
*          EXPORTING
*            i_module    = 'TA'
*          IMPORTING
*            e_installed = l_installed.
*
*        IF l_installed = 'X'.
*          g_agrname_dtlclk = agr_name.
*          CALL SCREEN 9005 STARTING AT 5 5
*                             ENDING AT 85 16.
*
*        ELSE.

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
*        ENDIF. " ta Install endif
      ENDIF.

  ENDCASE.
  CLEAR : r_ucomm, sy-ucomm.
  EXIT.
ENDFORM.   "ROLE_DOUBLE_CLICK_ON_DETL

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

FORM role_sod_analysis_from_details USING agr_name
                                           rfcdest .

  DATA l_rfcdest TYPE rfcdest.
**--Case 17382 - Correct RFC destination(if any) should be passed
*  READ TABLE gt_rfcdest WITH KEY rfcoptions = rfcdest.
*  IF sy-subrc = 0.
*    l_rfcdest = gt_rfcdest-rfcdest.
*  ELSE.
*    CLEAR l_rfcdest.
*  ENDIF.
  SUBMIT /psyng/sod_syswide_byrole
          WITH role      = agr_name
          WITH orgchk    = p_orgchk
          WITH p_enhanc  = p_enhanc
          WITH p_hienhn  = p_hienhn
          WITH sodvrsio  = p_vrsio
          WITH cfgset    = cfgset
          WITH remrfc    = l_rfcdest
          WITH ronlyrem  = ' '
          AND RETURN.
ENDFORM.                    " role_sod_analysis_from_details

FORM toggle_alv_role_org.
  IF gf_org_fields_display = 'X'.
    CLEAR gf_org_fields_display.
  ELSE.
    gf_org_fields_display = 'X'.
  ENDIF.
  PERFORM toggle_alv_role_org_filter USING gf_org_fields_display.
ENDFORM.
FORM toggle_alv_user_org.
  IF gf_org_fields_user_display = 'X'.
    CLEAR gf_org_fields_user_display.
  ELSE.
    gf_org_fields_user_display = 'X'.
  ENDIF.
  PERFORM toggle_alv_user_org_filter USING gf_org_fields_user_display.
ENDFORM.
FORM toggle_alv_mix_org.
  IF gf_org_fields_mix_display = 'X'.
    CLEAR gf_org_fields_mix_display.
  ELSE.
    gf_org_fields_mix_display = 'X'.
  ENDIF.
  PERFORM toggle_alv_mix_org_filter USING gf_org_fields_mix_display.
ENDFORM.

FORM toggle_alv_role_org_filter
  USING    if_show TYPE flag.
  DATA : l_fld          TYPE string,
         lt_filter      TYPE lvc_t_filt,
         ls_filter      TYPE lvc_s_filt,
         ls_fm_filter   TYPE slis_filter_alv,
        lt_nroldet_out LIKE TABLE OF gt_roleoutput_alv WITH HEADER LINE,
         lt_color_orgph TYPE lvc_t_scol,
         lt_color_varph TYPE lvc_t_scol,
         lt_color_org   TYPE lvc_t_scol,
         lt_color_var   TYPE lvc_t_scol,
         ls_color_cell  TYPE lvc_s_scol,
         lf_highlight   TYPE flag.
  STATICS : st_faobj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
            st_org     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
            st_checked TYPE flag.
  FIELD-SYMBOLS : <nroldet_out> LIKE gt_roleoutput_alv.
  CONSTANTS :
*normal field, non org or var element
    c_org_type_normal TYPE i VALUE 0,
*org or var element  with actual value
    c_org_type_org    TYPE i VALUE 1,
*org or var element  with placeholder value ($ORG or /PSYNG/$VAREL
    c_org_type_orgph  TYPE i VALUE 3,

    lc_fld(33) VALUE '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*--If this is the first time, get fields to be toggled
  IF st_checked IS INITIAL
  OR gf_sum_to_det IS NOT INITIAL.
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
        vrsio      = p_vrsio
      TABLES
        faobj_fm   = st_faobj.
*        spconfs_fm = spconfs.
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
    LOOP AT gt_roleoutput_alv ASSIGNING <nroldet_out>.
      <nroldet_out>-org_type = c_org_type_normal.
      READ TABLE st_org WITH KEY varbl = <nroldet_out>-field
      BINARY SEARCH TRANSPORTING varbl.
      IF sy-subrc = 0.
        <nroldet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_org TO <nroldet_out>-color_cell.
        lt_nroldet_out = <nroldet_out>.
        CLEAR : lt_nroldet_out-von,
                lt_nroldet_out-bis,
                lt_nroldet_out-simu,
                lt_nroldet_out-enhanced,
                lt_nroldet_out-org_abb.
        CONCATENATE '$' st_org-varbl INTO   lt_nroldet_out-von.
        lt_nroldet_out-org_type = c_org_type_orgph.
        lt_nroldet_out-color_cell[] = lt_color_orgph[].
        APPEND lt_nroldet_out.
      ENDIF.
*--We are not taking function/tcode into account yet
      READ TABLE st_faobj WITH KEY field  = <nroldet_out>-field
                                   object = <nroldet_out>-objct
                                   funid  = <nroldet_out>-functionid
                                   tcode  = <nroldet_out>-tcode
      BINARY SEARCH TRANSPORTING val_from.
      IF sy-subrc = 0.
        <nroldet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_var TO <nroldet_out>-color_cell.
        lt_nroldet_out = <nroldet_out>.
        CLEAR : lt_nroldet_out-von,
                lt_nroldet_out-bis,
                lt_nroldet_out-simu,
                lt_nroldet_out-enhanced,
                lt_nroldet_out-org_abb.
        lt_nroldet_out-von = st_faobj-val_from.
        lt_nroldet_out-org_type = c_org_type_orgph.
        lt_nroldet_out-color_cell[] = lt_color_varph[].
        APPEND lt_nroldet_out.
      ENDIF.
*      ENDIF.
    ENDLOOP.
    SORT lt_nroldet_out.
    DELETE ADJACENT DUPLICATES FROM lt_nroldet_out.
    APPEND LINES OF lt_nroldet_out TO gt_roleoutput_alv.
  ENDIF.
* Get a reference to the GRID
  FIELD-SYMBOLS <grid> TYPE REF TO cl_gui_alv_grid.
  IF gf_sum_to_det IS INITIAL.
*    l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*    ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <grid>."HBHALLA
    ASSIGN  (lc_fld) TO <grid>."#EC PATHLOCK_CI_DYN_ACCES
    IF <grid> IS ASSIGNED.
*  --Get the existing filter
      CALL METHOD <grid>->get_filter_criteria
        IMPORTING
          et_filter = lt_filter[].
      DELETE lt_filter WHERE fieldname = 'ORG_TYPE' .
    ENDIF.
  ENDIF.
  IF if_show <> 'X'.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = 'GT_ROLEOUTPUT_ALV'.
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
    ls_filter-tabname   = 'GT_ROLEOUTPUT_ALV'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_orgph.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ENDIF.
*--Apply the new filter
  IF gf_sum_to_det IS INITIAL.
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
  IF gf_sum_to_det IS INITIAL.
    IF <grid> IS ASSIGNED.
      CALL METHOD <grid>->refresh_table_display.
    ENDIF.
  ENDIF.
  CLEAR gf_sum_to_det.
ENDFORM.                    " toggle_alv_role_org_filter

FORM check_composite_role  USING    VALUE(role) TYPE agr_name
                           CHANGING lf_composite TYPE flag.

  SELECT SINGLE mandt
                FROM agr_agrs
                INTO sy-mandt
                WHERE agr_name = role.
  IF sy-subrc = 0.
    lf_composite = 'X'.
  ELSE.
    CLEAR lf_composite.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TOGGLE_ALV_ROLE_INIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM toggle_alv_role_init .
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
ENDFORM.
FORM toggle_alv_user_init .
  DATA : lf_show TYPE flag.
  IF gf_cfg_set_enabled = 'X'.
    se_config_param 'CFG_SET_SHOW_DFLT' lf_show.
    IF lf_show = 'Y'.
      PERFORM toggle_alv_user_org_filter USING 'X'.
      gf_org_fields_user_display = 'X'.
    ELSE.
      PERFORM toggle_alv_user_org_filter USING ''.
      CLEAR gf_org_fields_user_display.
    ENDIF.
  ENDIF.
ENDFORM.
FORM toggle_alv_mix_init .
  DATA : lf_show TYPE flag.
  IF gf_cfg_set_enabled = 'X'.
    se_config_param 'CFG_SET_SHOW_DFLT' lf_show.
    IF lf_show = 'Y'.
      PERFORM toggle_alv_mix_org_filter USING 'X'.
      gf_org_fields_mix_display = 'X'.
    ELSE.
      PERFORM toggle_alv_mix_org_filter USING ''.
      CLEAR gf_org_fields_mix_display.
    ENDIF.
  ENDIF.
ENDFORM.
FORM toggle_alv_user_org_filter
  USING    if_show TYPE flag.
  DATA : l_fld          TYPE string,
         lt_filter      TYPE lvc_t_filt,
         ls_filter      TYPE lvc_s_filt,
         ls_fm_filter   TYPE slis_filter_alv,
        lt_nusrdet_out LIKE TABLE OF gt_useroutput_alv WITH HEADER LINE,
         lt_color_orgph TYPE lvc_t_scol,
         lt_color_varph TYPE lvc_t_scol,
         lt_color_org   TYPE lvc_t_scol,
         lt_color_var   TYPE lvc_t_scol,
         ls_color_cell  TYPE lvc_s_scol,
         lf_highlight   TYPE flag.
  STATICS : st_faobj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
            st_org     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
            st_checked_user TYPE flag.
  FIELD-SYMBOLS : <nusrdet_out> LIKE gt_useroutput_alv.
  CONSTANTS :
*normal field, non org or var element
    c_org_type_normal TYPE i VALUE 0,
*org or var element  with actual value
    c_org_type_org    TYPE i VALUE 1,
*org or var element  with placeholder value ($ORG or /PSYNG/$VAREL
    c_org_type_orgph  TYPE i VALUE 3,

    lc_fld(33) VALUE '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID' .
*--If this is the first time, get fields to be toggled
  IF st_checked_user IS INITIAL
  OR gf_sum_to_det IS NOT INITIAL.
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
    IF st_faobj[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
        EXPORTING
          vrsio      = p_vrsio
        TABLES
          faobj_fm   = st_faobj.
*        spconfs_fm = spconfs.
      DELETE st_faobj WHERE NOT val_from CP '/PSYNG/$*'.
      SORT st_faobj BY field object funid tcode.
      DELETE ADJACENT DUPLICATES FROM st_faobj
      COMPARING field object funid tcode.
    ENDIF.
*--Org Elements
    IF st_org[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_AO_READ'
        EXPORTING
          if_read       = 'X'
          i_setid       = cfgset
        TABLES
          et_org_values = st_org.
      DELETE st_org WHERE active <> 'X'.
      SORT st_org BY varbl.
      DELETE ADJACENT DUPLICATES FROM st_org.
    ENDIF.
    st_checked_user = 'X'.
    LOOP AT gt_useroutput_alv ASSIGNING <nusrdet_out>.
      <nusrdet_out>-org_type = c_org_type_normal.
      READ TABLE st_org WITH KEY varbl = <nusrdet_out>-field
      BINARY SEARCH TRANSPORTING varbl.
      IF sy-subrc = 0.
        <nusrdet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_org TO <nusrdet_out>-color_cell.
        lt_nusrdet_out = <nusrdet_out>.
        CLEAR : lt_nusrdet_out-von,
                lt_nusrdet_out-bis,
                lt_nusrdet_out-simu,
                lt_nusrdet_out-enhanced,
                lt_nusrdet_out-org_abb.
        CONCATENATE '$' st_org-varbl INTO   lt_nusrdet_out-von.
        lt_nusrdet_out-org_type = c_org_type_orgph.
        lt_nusrdet_out-color_cell[] = lt_color_orgph[].
        APPEND lt_nusrdet_out.
      ENDIF.
*--We are not taking function/tcode into account yet
      READ TABLE st_faobj WITH KEY field  = <nusrdet_out>-field
                                   object = <nusrdet_out>-objct
                                   funid  = <nusrdet_out>-functionid
                                   tcode  = <nusrdet_out>-tcode
      BINARY SEARCH TRANSPORTING val_from.
      IF sy-subrc = 0.
        <nusrdet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_var TO <nusrdet_out>-color_cell.
        lt_nusrdet_out = <nusrdet_out>.
        CLEAR : lt_nusrdet_out-von,
                lt_nusrdet_out-bis,
                lt_nusrdet_out-simu,
                lt_nusrdet_out-enhanced,
                lt_nusrdet_out-org_abb.
        lt_nusrdet_out-von = st_faobj-val_from.
        lt_nusrdet_out-org_type = c_org_type_orgph.
        lt_nusrdet_out-color_cell[] = lt_color_varph[].
        APPEND lt_nusrdet_out.
      ENDIF.
*      ENDIF.
    ENDLOOP.
    SORT lt_nusrdet_out.
    DELETE ADJACENT DUPLICATES FROM lt_nusrdet_out.
    APPEND LINES OF lt_nusrdet_out TO gt_useroutput_alv.
  ENDIF.
* Get a reference to the GRID
  FIELD-SYMBOLS <grid> TYPE REF TO cl_gui_alv_grid.
  IF gf_sum_to_det IS INITIAL.
*    l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*    ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <grid>."HBHALLA
    ASSIGN  (lc_fld) TO <grid>."#EC PATHLOCK_CI_DYN_ACCES
    IF <grid> IS ASSIGNED.
*  --Get the existing filter
      CALL METHOD <grid>->get_filter_criteria
        IMPORTING
          et_filter = lt_filter[].
      DELETE lt_filter WHERE fieldname = 'ORG_TYPE' .
    ENDIF.
  ENDIF.
  IF if_show <> 'X'.
*--Filter out the fields that should be hidden
    ls_filter-fieldname = 'ORG_TYPE'.
    ls_filter-tabname   = 'GT_USEROUTPUT_ALV'.
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
    ls_filter-tabname   = 'GT_ROLEOUTPUT_ALV'.
    ls_filter-ref_field = 'ORG_TYPE'.
    ls_filter-ref_table = ''.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  c_org_type_orgph.
    CONDENSE ls_filter-low.
    APPEND ls_filter TO lt_filter.
  ENDIF.
*--Apply the new filter
  IF gf_sum_to_det IS INITIAL.
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
  ENDIF.
  REFRESH : gt_filter_user_detail.
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

    APPEND ls_fm_filter TO gt_filter_user_detail.
  ENDLOOP.
  IF gf_sum_to_det IS INITIAL.
    IF <grid> IS ASSIGNED.
      CALL METHOD <grid>->refresh_table_display.
    ENDIF.
  ENDIF.
  CLEAR gf_sum_to_det.
ENDFORM.                    " toggle_alv_role_org_filter
FORM toggle_alv_mix_org_filter
  USING    if_show TYPE flag.
  DATA : l_fld          TYPE string,
         lt_filter      TYPE lvc_t_filt,
         ls_filter      TYPE lvc_s_filt,
         ls_fm_filter   TYPE slis_filter_alv,
        lt_nmixdet_out LIKE TABLE OF gt_output_detail WITH HEADER LINE,
         lt_color_orgph TYPE lvc_t_scol,
         lt_color_varph TYPE lvc_t_scol,
         lt_color_org   TYPE lvc_t_scol,
         lt_color_var   TYPE lvc_t_scol,
         ls_color_cell  TYPE lvc_s_scol,
         lf_highlight   TYPE flag.
  STATICS : st_faobj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
            st_org     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
            st_checked_mix TYPE flag.
  FIELD-SYMBOLS : <nmixdet_out> LIKE gt_output_detail.
  CONSTANTS :
*normal field, non org or var element
    c_org_type_normal TYPE i VALUE 0,
*org or var element  with actual value
    c_org_type_org    TYPE i VALUE 1,
*org or var element  with placeholder value ($ORG or /PSYNG/$VAREL
    c_org_type_orgph  TYPE i VALUE 3,
    lc_fld(33) VALUE '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*--If this is the first time, get fields to be toggled
  IF st_checked_mix IS INITIAL.
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
    IF st_faobj[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG'
        EXPORTING
          vrsio      = p_vrsio
        TABLES
          faobj_fm   = st_faobj.
*        spconfs_fm = spconfs.
      DELETE st_faobj WHERE NOT val_from CP '/PSYNG/$*'.
      SORT st_faobj BY field object funid tcode.
      DELETE ADJACENT DUPLICATES FROM st_faobj
      COMPARING field object funid tcode.
    ENDIF.
*--Org Elements
    IF st_org[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_AO_READ'
        EXPORTING
          if_read       = 'X'
          i_setid       = cfgset
        TABLES
          et_org_values = st_org.
      DELETE st_org WHERE active <> 'X'.
      SORT st_org BY varbl.
      DELETE ADJACENT DUPLICATES FROM st_org.
    ENDIF.
    st_checked_mix = 'X'.
    LOOP AT gt_output_detail ASSIGNING <nmixdet_out>.
      <nmixdet_out>-org_type = c_org_type_normal.
      READ TABLE st_org WITH KEY varbl = <nmixdet_out>-field
      BINARY SEARCH TRANSPORTING varbl.
      IF sy-subrc = 0.
        <nmixdet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_org TO <nmixdet_out>-color_cell.
        lt_nmixdet_out = <nmixdet_out>.
        CLEAR : lt_nmixdet_out-von,
                lt_nmixdet_out-bis,
                lt_nmixdet_out-simu,
                lt_nmixdet_out-enhanced,
                lt_nmixdet_out-org_abb.
        CONCATENATE '$' st_org-varbl INTO   lt_nmixdet_out-von.
        lt_nmixdet_out-org_type = c_org_type_orgph.
        lt_nmixdet_out-color_cell[] = lt_color_orgph[].
        APPEND lt_nmixdet_out.
      ENDIF.
*--We are not taking function/tcode into account yet
      READ TABLE st_faobj WITH KEY field  = <nmixdet_out>-field
                                   object = <nmixdet_out>-objct
                                   funid  = <nmixdet_out>-functionid
                                   tcode  = <nmixdet_out>-tcode
      BINARY SEARCH TRANSPORTING val_from.
      IF sy-subrc = 0.
        <nmixdet_out>-org_type = c_org_type_org.
        APPEND LINES OF lt_color_var TO <nmixdet_out>-color_cell.
        lt_nmixdet_out = <nmixdet_out>.
        CLEAR : lt_nmixdet_out-von,
                lt_nmixdet_out-bis,
                lt_nmixdet_out-simu,
                lt_nmixdet_out-enhanced,
                lt_nmixdet_out-org_abb.
        lt_nmixdet_out-von = st_faobj-val_from.
        lt_nmixdet_out-org_type = c_org_type_orgph.
        lt_nmixdet_out-color_cell[] = lt_color_varph[].
        APPEND lt_nmixdet_out.
      ENDIF.
*      ENDIF.
    ENDLOOP.
    SORT lt_nmixdet_out.
    DELETE ADJACENT DUPLICATES FROM lt_nmixdet_out.
    APPEND LINES OF lt_nmixdet_out TO gt_output_detail.
  ENDIF.
* Get a reference to the GRID
  FIELD-SYMBOLS <grid> TYPE REF TO cl_gui_alv_grid.
*  l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
*  ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <grid>."HBHALLA
  ASSIGN  (lc_fld) TO <grid>."#EC PATHLOCK_CI_DYN_ACCES

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
    ls_filter-tabname   = 'GT_OUTPUT_DETAIL'.
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
    ls_filter-tabname   = 'GT_OUTPUT_DETAIL'.
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
  REFRESH : gt_filter_mix_detail.
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

    APPEND ls_fm_filter TO gt_filter_mix_detail.
  ENDLOOP.
  IF <grid> IS ASSIGNED.
    CALL METHOD <grid>->refresh_table_display.
  ENDIF.
ENDFORM.                    " toggle_alv_mix_org_filter
FORM advsimu_pf_sumsta USING it_extab TYPE slis_t_extab.

  DATA : BEGIN OF lt_fcode OCCURS 0,
           fcode LIKE rsmpe-func,
         END OF lt_fcode.
  IF NOT gf_simu_role IS INITIAL.
    lt_fcode-fcode = 'SHOWSIMDET'.
    APPEND lt_fcode.
  ENDIF.

  lt_fcode-fcode = 'SHOW_TEXTS'.
  APPEND lt_fcode.

  lt_fcode-fcode = 'TOGGLE_ORG'.
  APPEND lt_fcode.

  SET PF-STATUS 'ADVSIMUOUT' EXCLUDING lt_fcode.
  CLEAR gf_simu_role.
ENDFORM.                    " advsimu_pf_status
FORM advsimu_pf_simsta USING it_extab TYPE slis_t_extab.

  DATA : BEGIN OF lt_fcode OCCURS 0,
           fcode LIKE rsmpe-func,
         END OF lt_fcode.

  lt_fcode-fcode = 'SHOWSIMDET'.
  APPEND lt_fcode.

  lt_fcode-fcode = 'SHOW_TEXTS'.
  APPEND lt_fcode.

  lt_fcode-fcode = 'TOGGLE_ORG'.
  APPEND lt_fcode.

  SET PF-STATUS 'ADVSIMUOUT' EXCLUDING lt_fcode.
  CLEAR gf_simu_role.
ENDFORM.                    " advsimu_pf_status
