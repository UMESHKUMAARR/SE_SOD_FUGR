FUNCTION /psyng/func_role_analysis.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(ENH_FM) TYPE  FLAG OPTIONAL
*"     VALUE(I_RCHDATF) TYPE  MENU_DATE OPTIONAL
*"     VALUE(I_RCHDATT) TYPE  MENU_DATE OPTIONAL
*"     VALUE(I_SIMU_RFC) TYPE  RFCDEST OPTIONAL
*"     VALUE(XSTB_FM) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_LOCAL_SOD) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ADVANCED_ROLE_SIMU) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_SHONOSOD) TYPE  FLAG DEFAULT ''
*"     VALUE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SHOMIT) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ASSIGNED_ROLES) TYPE  FLAG OPTIONAL
*"     VALUE(I_CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"  EXPORTING
*"     VALUE(O_TOTALROLES) TYPE  INT4
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_ROLE_BA STRUCTURE  /PSYNG/RANGE_BUSAREA_ROLE OPTIONAL
*"      IT_ROLES_SIMU STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_FUNC STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      IT_OWNER STRUCTURE  /PSYNG/SW_SEL_OPTS_CONFOWNER OPTIONAL
*"      IT_BUSAREA STRUCTURE  /PSYNG/SW_SEL_OPTS_BUS_AREA OPTIONAL
*"      OT_ROUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      OT_ROUTPUT_SUM STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FUNCTIONS STRUCTURE  /PSYNG/FUNCTION OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM OPTIONAL
*"      IT_TCODES STRUCTURE  /PSYNG/SW_PAR_TCODE_OUTPUT OPTIONAL
*"      IT_FUNCTRAN_NO_ENH STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_SIMUROLE_AUTH STRUCTURE  /PSYNG/ROLEAUTH OPTIONAL
*"      IT_SIMUROLE_TCODE STRUCTURE  /PSYNG/ROLETCODE OPTIONAL
*"      IT_SIMUROLE_TCDAUT STRUCTURE  /PSYNG/PSSWTCDAUT OPTIONAL
*"      IT_RISK STRUCTURE  /PSYNG/RANGE_RISK OPTIONAL
*"      IT_ADVANCED_ROLE_SIMU STRUCTURE  AGR_1251 OPTIONAL
*"      IT_SIMU_ROLE_REMOVAL STRUCTURE  /PSYNG/SW_ROLE_REMOVAL_SIMU
*"       OPTIONAL
*"      ET_SIMU_REMOVED_ROLES STRUCTURE  /PSYNG/SW_REMOVED_ROLES_ROLE
*"       OPTIONAL
*"      ET_MITIGATIONS STRUCTURE  /PSYNG/MITIGATION_ASSIGNMENT OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/FUNC_ROLE_ANALYSIS'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

*Local variables
  DATA: objectcount_fm TYPE  i,
        concount_fm    TYPE  i,
        byobject       TYPE char10,
        rfcdest LIKE rfcdes-rfcdest,
        ls_routput TYPE /psyng/sw_out_routput,
        lt_mcrole    TYPE TABLE OF /psyng/mcrole WITH HEADER LINE,
        lt_mccarole  TYPE TABLE OF /psyng/mccarole WITH HEADER LINE,
        lt_simu_roles_for_mit TYPE TABLE OF /psyng/sw_sod_remote_roles
                WITH HEADER LINE,
        lt_functions TYPE TABLE OF /psyng/function WITH HEADER LINE,
        l_conf_number TYPE i.

DATA:  lt_conflict_local TYPE TABLE OF /psyng/conflict,
       lt_confdet_local TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
       lt_functtran_local TYPE TABLE OF /psyng/functtran,
       lt_faobj_local TYPE TABLE OF /psyng/faobj2,
       lt_swsodorgm_local TYPE TABLE OF /psyng/swsodorgm,
       lt_functran_no_enh_local TYPE TABLE OF /psyng/functtran,
       lt_tcodes_local TYPE TABLE OF /psyng/sw_par_tcode_output.


  FIELD-SYMBOLS : <rout> LIKE routdet3.


 FREE :  gt_roles,gt_roles_simu,gt_confs,gt_sens,gt_risk,gt_routput_sum,
      gt_routput, roleauth, roletcode, cf, ft.


*assign imported and table parameters to global variables / tables
  gt_roles[]      = it_roles[].
  gt_roles_simu[] = it_roles_simu[].
*  gt_confs[]      = it_confs[].
*  gt_sens[]       = it_sens[].
*  gt_risk[]       = it_risk[].
  g_vrsio         = vrsio.
  g_org_check     = org_check.
  g_rchdatf       = i_rchdatf.
  g_rchdatt       = i_rchdatt.
  g_simu_rfc      = i_simu_rfc.
  g_xstb_fm       = xstb_fm.
*  g_bysimu        = i_bysimu.
  g_enh_fm        = enh_fm.
*  gt_functran_no_enh[] = it_functran_no_enh[].
*refresh global tables
  REFRESH : routdet[], routdet2[],routdet3[],routdet4[],routdet5[],
            gt_routput[],gt_routput_sum[],uniqueauths[],itcd[],
            itcdaut[],roleauth[],roletcode[].
  CLEAR : g_return.
  PERFORM fill_internal_tables_func
    TABLES
        IT_ROLE_BA
    USING
        i_local_sod
        i_composite_roles
        i_single_roles
        i_assigned_roles.
  IF i_local_sod IS INITIAL.
*--The SOD matrix that we will use is passed to the FM
    conflict[]  = it_conflict[].
    confdet[]   = it_confdet[].
    functtran[] = it_functtran[].
    faobj[]     = it_faobj[].
    swsodorgm[] = it_swsodorgm[].
    gt_enh_tcodes[] = it_tcodes[].
    confs2[] = confdet[].
    lt_functions[] = it_functions[].
*   Remove rows with no object
    DELETE faobj WHERE object = space.
  ELSE.

    SELECT * FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE lt_functions
    WHERE vrsio    = vrsio
      AND busarea  IN it_busarea
      AND function IN it_func
      AND owner    IN it_owner.

    IF NOT lt_functions[] IS INITIAL.

*  *--Load Local SOD Matrix
      CALL FUNCTION '/PSYNG/SW_028'
           EXPORTING
                i_vrsio            = vrsio
                i_orphan_functions = 'X'
                i_enhance          = ENH_FM
                i_orgcheck         = org_check
                i_config_set       = i_config_set
                IF_ANALYSIS        = 'X'
           TABLES
                et_conflict        = lt_conflict_local
                et_confdet         = lt_confdet_local
                et_functtran       = lt_functtran_local
                et_faobj           = lt_faobj_local
                et_swsodorgm       = lt_swsodorgm_local
                et_tcodes          = gt_enh_tcodes.

    conflict[]  = lt_conflict_local[].
    confdet[]   = lt_confdet_local[].
    functtran[] = lt_functtran_local[].
    faobj[]     = lt_faobj_local[].
    swsodorgm[] = lt_swsodorgm_local[].


*--Delete unwanted functions
*      SORT confdet BY functionid.
      LOOP AT confdet.
        READ TABLE lt_functions
        WITH KEY function = confdet-functionid.
        IF sy-subrc <> 0.
          DELETE functtran WHERE
          functionid = confdet-functionid.
          DELETE faobj WHERE
          funid = confdet-functionid.
          DELETE confdet WHERE "#EC CI_SORTSEQ
          functionid = confdet-functionid.
        ELSE.
          IF confdet-conid IS INITIAL.
            l_conf_number = l_conf_number + 1.
            confdet-conid = l_conf_number + 1.
            MODIFY confdet.
          ENDIF.
        ENDIF.
      ENDLOOP.
*      ENDLOOP.

      DELETE ADJACENT DUPLICATES FROM confdet COMPARING functionid.
    ENDIF.


  ENDIF.


  DATA: l_tcode_validation TYPE /psyng/param_value.
  se_config_param   'DFLT_TCOD_VALIDATION' l_tcode_validation.
  IF l_tcode_validation EQ 'Y'.
*--Validate that tcodes in SOD Matrix exist
  CALL FUNCTION '/PSYNG/SW_120'
       TABLES
            it_functtran = functtran
            it_faobj     = faobj.
  ENDIF.

*-- Collect Simulated roles for mitigation.
  LOOP AT it_simurole_auth.
    AT NEW agr_name.
      lt_simu_roles_for_mit-agr_name = it_simurole_auth-agr_name.
      APPEND lt_simu_roles_for_mit.
    ENDAT.
  ENDLOOP.


  IF gt_roles_simu[] IS INITIAL.
* make sure we are not getting ALL roles as simulated roles
* use I CP * to do that
    CLEAR g_bysimu.
  ENDIF.

*  IF g_bysimu = 'X'.
*    PERFORM get_simulation_roles_for_role.
*  ENDIF.
  DESCRIBE TABLE iagr_define LINES o_totalroles.

  CONCATENATE sy-sysid sy-mandt INTO rfcdest.

  IF i_advanced_role_simu IS INITIAL.
    PERFORM get_roles_data
      TABLES et_return
             faobj
             it_simu_role_removal
             et_simu_removed_roles.
  ELSE.
    PERFORM get_advanced_simu_auths
    TABLES
      it_advanced_role_simu
      et_return
      it_roles
      faobj
      it_simu_role_removal
      et_simu_removed_roles.
  ENDIF.

  DATA : lt_userauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE.

  LOOP AT roleauth .
    uniqueauths-rfcdest = rfcdest.
    uniqueauths-objct   = roleauth-objct.
    uniqueauths-auth    = roleauth-auth.
    APPEND uniqueauths.
  ENDLOOP.
  LOOP AT it_simurole_auth.
    uniqueauths-rfcdest = rfcdest.
    uniqueauths-objct   = it_simurole_auth-objct.
    uniqueauths-auth    = it_simurole_auth-auth.
    APPEND uniqueauths.

    MOVE-CORRESPONDING it_simurole_auth TO lt_userauth.
    APPEND lt_userauth.
  ENDLOOP.


  SORT uniqueauths.
  DELETE ADJACENT DUPLICATES FROM uniqueauths COMPARING ALL FIELDS.

  LOOP AT roletcode.
    wa_itcd-tcode = roletcode-tcode.
    wa_itcd-rfcdest = roletcode-rfcdest.
    INSERT wa_itcd INTO TABLE itcd.
  ENDLOOP.
  LOOP AT it_simurole_tcode.
    wa_itcd-tcode = it_simurole_tcode-tcode.
    wa_itcd-rfcdest = rfcdest.
    INSERT wa_itcd INTO TABLE itcd.
  ENDLOOP.

  itcd2[] = itcd[].

  LOOP AT faobj.
    READ TABLE itcd WITH KEY tcode = faobj-tcode
                                     BINARY SEARCH
                                     TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    DELETE faobj.


  ENDLOOP.

  REFRESH : tobjs3,tobjs2,tobjs1.
  CLEAR wa_tobjs1.

  LOOP AT faobj.
    MOVE-CORRESPONDING faobj TO wa_tobjs1.
    INSERT wa_tobjs1 INTO TABLE tobjs3.
  ENDLOOP.
  tobjs1[] = tobjs3[].
  tobjs2[] = tobjs3[].

  LOOP AT functtran.
    READ TABLE itcd WITH KEY tcode = functtran-tcode
                                     BINARY SEARCH
                                     TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE functtran WHERE tcode = functtran-tcode.
    ENDIF.
  ENDLOOP.



  SORT: functtran, faobj.
  DATA : faobj_fm LIKE TABLE OF faobj.
  faobj_fm[] = faobj[].
  CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
       EXPORTING
            i_advanced_role_simu  = i_advanced_role_simu
       TABLES
            tcd                   = itcd2
            faobj                 = faobj_fm
            functtran             = functtran
            tcdaut                = itcdaut_fm
            uniqueauths           = uniqueauths
            it_advanced_role_simu = it_advanced_role_simu
            it_simu_add_roleauth  = lt_userauth.


  SORT: faobj.

  LOOP AT itcdaut_fm.
    MOVE-CORRESPONDING itcdaut_fm TO wa_itcdaut.
    CLEAR: wa_itcdaut-field, wa_itcdaut-von, wa_itcdaut-bis.
    INSERT wa_itcdaut INTO TABLE itcdaut.
  ENDLOOP.
  CLEAR itcdaut_fm.
  FREE itcdaut_fm.

*--When content of simulated roles is passed, add it to appriate
*  internal tables here.
  LOOP AT iagr_define.

    LOOP AT it_simurole_auth.
      simuagrs-agr_name = it_simurole_auth-agr_name.
      APPEND simuagrs.
      it_simurole_auth-child_agr = it_simurole_auth-agr_name.
      it_simurole_auth-agr_name  = iagr_define-agr_name.
      it_simurole_auth-rfcdest   = rfcdest.
      it_simurole_auth-simu      = 'X'.
      INSERT it_simurole_auth INTO TABLE roleauth.

    ENDLOOP.
    LOOP AT it_simurole_tcode.
      simuagrs-agr_name = it_simurole_tcode-agr_name.
      APPEND simuagrs.
      it_simurole_tcode-child_agr = it_simurole_tcode-agr_name.
      it_simurole_tcode-agr_name  = iagr_define-agr_name.
      it_simurole_tcode-rfcdest   = rfcdest.
      it_simurole_tcode-simu      = 'X'.
      INSERT it_simurole_tcode INTO TABLE roletcode.
    ENDLOOP.
  ENDLOOP.

  LOOP AT it_simurole_tcdaut.
    MOVE-CORRESPONDING it_simurole_tcdaut TO wa_itcdaut.
    wa_itcdaut-rfcdest = rfcdest.
    INSERT wa_itcdaut INTO TABLE itcdaut.
  ENDLOOP.
*--END When content of simulated roles is passed, add it to appriate
*  internal tables here.


  PERFORM get_org_level_auth
    tables IT_SIMUROLE_AUTH."get org level authorizations
  FREE : it_simurole_auth, it_simurole_tcdaut,it_simurole_tcode.

  PERFORM compare_func_with_auth_role.

  IF i_shonosod = 'X'.
    PERFORM report_roles_without_functions.
  ENDIF.
*Move results to output table.
  ot_routput[] = gt_routput[].
  ot_routput_sum[] = gt_routput_sum[].


*--Get the role names
  SORT gt_routput_sum BY agr_name.
  DELETE ADJACENT DUPLICATES FROM gt_routput_sum COMPARING agr_name.
  DATA : lt_agr_names TYPE TABLE OF agr_texts WITH HEADER LINE.
  IF NOT gt_routput_sum[] IS INITIAL.
    SELECT agr_name text FROM agr_texts INTO
    CORRESPONDING FIELDS OF  TABLE lt_agr_names
    FOR ALL ENTRIES IN gt_routput_sum
    WHERE
    agr_name = gt_routput_sum-agr_name AND
    spras = sy-langu AND
    line < 1.
  ENDIF.
  FREE gt_routput_sum.

  LOOP AT lt_agr_names.
    ot_routput_sum-agr_text = lt_agr_names-text.
    MODIFY ot_routput_sum
    TRANSPORTING agr_text
    WHERE agr_name = lt_agr_names-agr_name.
  ENDLOOP.
  return = g_return.
  MOVE-CORRESPONDING g_return TO et_return.
  et_return-id = g_return-code(2).
  et_return-number = g_return-code+2.
  APPEND et_return.
ENDFUNCTION.
