FUNCTION /psyng/sw_036.
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
*"     VALUE(I_BYSIMU) TYPE  FLAG OPTIONAL
*"     VALUE(I_LOCAL_SOD) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ADVANCED_ROLE_SIMU) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_SHONOSOD) TYPE  FLAG DEFAULT ''
*"     VALUE(I_COMPOSITE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SINGLE_ROLES) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_SHOMIT) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_ASSIGNED_ROLES) TYPE  FLAG OPTIONAL
*"     VALUE(I_ABAP) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_NABAP) TYPE  FLAG OPTIONAL
*"     VALUE(I_CFG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(I_ORG_FIELD) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(O_TOTALROLES) TYPE  INT4
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      IT_ROLES STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_ROLES_SIMU STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_CONFS STRUCTURE  /PSYNG/SW_SEL_OPTS_CONID OPTIONAL
*"      IT_SENS STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      OT_ROUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      OT_ROUTPUT_SUM STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_CONFLICT STRUCTURE  /PSYNG/CONFLICT OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
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
*"      IT_APPL STRUCTURE  /PSYNG/RANGE_APPL OPTIONAL
*"      IT_SYSID STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      IT_ORGLVL STRUCTURE  /PSYNG/RANGE_DORG_ABB OPTIONAL
*"      IT_ROLE_BA STRUCTURE  /PSYNG/RANGE_BUSAREA_ROLE OPTIONAL
*"      IT_FAOBJ_ORG STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_036'.
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
        c_func_en_009(13) TYPE c VALUE '/PSYNG/EX_009',
        l_max_auths TYPE i value '50000',
        lt_auths_part type table of /PSYNG/UNIQUEAUTHS,
        lt_unique_roles    type table of usla04,"HBHALLA(13/02/25)
        ls_unique_roles    type          usla04."HBHALLA(13/02/25)

**BOC : UMITTAL SMUD issue
*TYPES : BEGIN OF ty_role_t,
*          role_id TYPE /PSYNG/REF_KEY,
*        END OF ty_role_t.
*DATA : lt_role_t TYPE STANDARD TABLE OF ty_role_t,
*       ls_role_t TYPE ty_role_t.
*DATA : lt_role_name TYPE STANDARD TABLE OF /psyng/ex_ref01,
*       ls_role_name TYPE /psyng/ex_ref01,
*       c_tab_en(15)      TYPE c VALUE '/PSYNG/EX_REF01'.
*DATA: lv_table_name TYPE string,
*      lt_data TYPE REF TO data,
*      lt_table TYPE REF TO data,
*      lr_fieldcat TYPE lvc_t_fcat.
*FIELD-SYMBOLS: <lt_table> TYPE STANDARD TABLE,
*               <ls_table> TYPE any.
*
*lv_table_name = '/PSYNG/EX_REF01'.  " Pass table name dynamically
*EOC : UMITTAL SMUD issue
  FIELD-SYMBOLS : <rout> LIKE routdet3.

 FREE :  gt_roles,gt_roles_simu,gt_confs,gt_sens,gt_risk,gt_routput_sum,
         gt_routput, roleauth, roletcode, cf, ft,gt_orglvl,
         GT_SYSTEMAUTHS.


*assign imported and table parameters to global variables / tables
  gt_roles[]      = it_roles[].
  gt_roles_simu[] = it_roles_simu[].
  gt_confs[]      = it_confs[].
  gt_sens[]       = it_sens[].
  gt_risk[]       = it_risk[].
  g_vrsio         = vrsio.
  g_org_check     = org_check.
  g_rchdatf       = i_rchdatf.
  g_rchdatt       = i_rchdatt.
  g_simu_rfc      = i_simu_rfc.
  g_xstb_fm       = xstb_fm.
  g_bysimu        = i_bysimu.
  g_enh_fm        = enh_fm.
  gt_orglvl       = it_orglvl[].
  gt_functran_no_enh[] = it_functran_no_enh[].
    gf_org_field = i_org_field. "AKUMAR OPL645
  gt_faobj_org[] = it_faobj_org[]. "AKUMAR OPL645
*refresh global tables
  REFRESH : routdet[], routdet2[],routdet3[],routdet4[],routdet5[],
            gt_routput[],gt_routput_sum[],uniqueauths[],itcd[],
            itcdaut[],roleauth[],roletcode[].
  CLEAR : g_return.
  PERFORM fill_internal_tables
    TABLES
          IT_ROLE_BA
    USING i_local_sod
          i_composite_roles
          i_single_roles
          i_assigned_roles
          I_NABAP
          I_CFG_SET
          i_org_field "AKUMAR OPL645.
          CHANGING gt_faobj_org. "AKUMAR OPL645
  IF i_local_sod IS INITIAL.
*--The SOD matrix that we will use is passed to the FM
    conflict[]  = it_conflict[].
    confdet[]   = it_confdet[].
    functtran[] = it_functtran[].
    faobj[]     = it_faobj[].
    swsodorgm[] = it_swsodorgm[].
    gt_enh_tcodes[] = it_tcodes[].
    confs2[] = confdet[].
*   Remove rows with no object
    DELETE faobj WHERE object = space.

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

*--Load Role Mitigation Assignments
  PERFORM load_mitigations TABLES lt_mcrole
                                  lt_mccarole
                                  lt_simu_roles_for_mit.


  IF gt_roles_simu[] IS INITIAL.
* make sure we are not getting ALL roles as simulated roles
* use I CP * to do that
    CLEAR g_bysimu.
  ENDIF.

  IF g_bysimu = 'X'.
    PERFORM get_simulation_roles_for_role.
  ENDIF.
  DESCRIBE TABLE iagr_define LINES o_totalroles.

  CONCATENATE sy-sysid sy-mandt INTO rfcdest.

  IF i_advanced_role_simu IS INITIAL.
    IF i_abap = 'X'.
      MESSAGE s002 WITH 'Loading Role Content'.
      commit work.


      PERFORM get_roles_data
        TABLES et_return
               faobj
               it_simu_role_removal
               et_simu_removed_roles.
    ENDIF.
  ELSE.
    MESSAGE s002 WITH 'Loading Advanced Simulation Content'.
    commit work.

*BOC:HBHALLA (13/02/25)(PN-11674)
 LOOP AT it_advanced_role_simu.
   AT NEW agr_name.
    ls_unique_roles-agr_name = it_advanced_role_simu-agr_name.
    append ls_unique_roles to lt_unique_roles.
    clear ls_unique_roles.
   ENDAT.
 ENDLOOP.



  call function '/PSYNG/PROF_AUTH_CONCAT'
    tables
      it_unique_roles = lt_unique_roles
      et_auths        = it_advanced_role_simu
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

*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
  DATA :  lt_match_user_auth TYPE STANDARD TABLE OF
                    /psyng/match_usr,
          lt_match_user_auth_t TYPE STANDARD TABLE OF
                    /psyng/match_usr.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025

  faobj_fm[] = faobj[].
  PERFORM get_org_level_auth
  tables IT_SIMUROLE_AUTH.
  ."get org level authorizations

*--SE4.0 - Don't analyze all auths at once, to preserve memory
  while not uniqueauths[] is initial.
    refresh lt_auths_part.
    append lines of uniqueauths from 1 to l_max_auths to lt_auths_part.
    delete uniqueauths from 1 to l_max_auths.
    CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
         EXPORTING
              i_advanced_role_simu  = i_advanced_role_simu
         TABLES
              tcd                   = itcd2
              faobj                 = faobj_fm
              functtran             = functtran
              tcdaut                = itcdaut_fm
              uniqueauths           = lt_auths_part
              it_advanced_role_simu = it_advanced_role_simu
              it_simu_add_roleauth  = lt_userauth
*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
              et_match_user_out     = lt_match_user_auth_t.

  APPEND LINES OF lt_match_user_auth_t to lt_match_user_auth.
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025.
    SORT: faobj.
    LOOP AT itcdaut_fm.
      MOVE-CORRESPONDING itcdaut_fm TO wa_itcdaut.
      CLEAR: wa_itcdaut-field, wa_itcdaut-von, wa_itcdaut-bis.
      INSERT wa_itcdaut INTO TABLE itcdaut.
    ENDLOOP.
    CLEAR itcdaut_fm.
    FREE itcdaut_fm.
  endwhile.
  free : lt_auths_part, uniqueauths.

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
* Get org level auths for roles from simulation and
* advanced simulation
  PERFORM get_org_auth_simu_roles
    tables it_simurole_auth
           IT_ADVANCED_ROLE_SIMU.


*--END When content of simulated roles is passed, add it to appriate
*  internal tables here.


**Get org level auths for roles from advanced simulation
*  if I_ADVANCED_ROLE_SIMU = 'X'.
*    PERFORM get_org_auth_simu_roles.
*  endif.

  PERFORM compare_soddef_with_auth_role
*--> BOC UMITTAL IBS SOD PN14272 21/07/2025
*--> Check AND relation between Valuesets for all users
           TABLES  lt_match_user_auth .
*--> EOC UMITTAL IBS SOD PN14272 21/07/2025


*--SE 4.3 - Adapt results based on additional configuration - START
    perform org_override
      tables
            functtran
            faobj
            gt_routput_sum
            swsodorgm
            IT_ADVANCED_ROLE_SIMU
            IT_SIMU_ROLE_REMOVAL
            IT_SIMUROLE_AUTH
            IT_SIMUROLE_TCODE
      using VRSIO
            I_CFG_SET
            org_check.
*--SE 4.3 - Adapt results based on additional configuration - END
  FREE : it_simurole_auth, it_simurole_tcdaut,it_simurole_tcode.



  DATA : wa_output LIKE LINE OF gt_routput_sum.
  wa_output-appl = 'SAP'.
  MODIFY gt_routput_sum FROM wa_output TRANSPORTING appl  WHERE appl IS
initial.

*-- Get EN Data - 3.4
  IF i_nabap = 'X'.
    MESSAGE s002 WITH 'Non-ABAP SOD Analysis'.
    commit work.

    DATA : lt_rolid TYPE TABLE OF /psyng/range_rolid WITH HEADER LINE,
            lt_en_output TYPE TABLE OF /psyng/ex_sod_role_det
            WITH HEADER LINE,
            lt_en_output_con type table of /psyng/ex_sod_role_det
            WITH HEADER LINE,
            lt_roles type table of /psyng/ex_sod_role_det
            WITH HEADER LINE,
            l_en_rolecount TYPE i,
            l_en_vrsio TYPE /psyng/vrsio,
            ls_role_value TYPE /psyng/ex_rolid_value.

    l_en_vrsio = vrsio.

    LOOP AT it_roles.
      MOVE-CORRESPONDING it_roles TO lt_rolid.
      APPEND lt_rolid.
    ENDLOOP.
*--Execute Function Analysis
    CALL FUNCTION c_func_en_009 "#EC PATHLOCK_CI_DYN_ACCES
         EXPORTING
              i_vrsio          = l_en_vrsio
              i_summary        = 'X'
              IF_ASSIGNED_ONLY = i_assigned_roles
         IMPORTING
              e_rolecount      = l_en_rolecount
         TABLES
              it_appl          = it_appl
              it_sysid         = it_sysid
              it_rolid         = lt_rolid
              et_output        = lt_en_output
              it_imp           = it_sens.
    o_totalroles = o_totalroles + l_en_rolecount.
*--Determine conflicts from list of functions
data : lf_con type flag.
sort lt_en_output by appl SYSID rolid funid.
lt_roles[] = lt_en_output[].
sort lt_roles by appl SYSID  rolid.
delete adjacent duplicates from lt_roles comparing appl SYSID  rolid.

**BOC : UMITTAL SMUD issue
*CLEAR lt_role_t.
*LOOP AT lt_roles.
*  ls_role_t-role_id = lt_roles-rolid.
*  APPEND ls_role_t TO lt_role_t.
*ENDLOOP.
*
*IF NOT lt_role_t[] IS INITIAL.
*  SELECT ref_key key_val key_index
*    INTO TABLE lt_role_name
*    FROM /psyng/ex_ref01
*    FOR ALL ENTRIES IN lt_role_t
*    WHERE ref_key = lt_role_t-role_id.
*
*    IF sy-subrc EQ 0.
*      SORT lt_role_name BY ref_key.
*    ENDIF.
*ENDIF.
**EOC : UMITTAL SMUD issue
loop at conflict.
  loop at lt_roles.
    lf_con ='X'.
    loop at confdet where conid = conflict-conid.
     read table lt_en_output with key
           appl   = lt_roles-appl
           SYSID = lt_roles-SYSID
           rolid  = lt_roles-rolid
           funid  = confdet-FUNCTIONID
           binary search
           transporting no fields.
       if sy-subrc <> 0.
         clear lf_con.
         exit. "this function not found
       endif.
    endloop.
*---odubey 2021/01/07 if conflict detail is not present
    if sy-subrc <> 0.
      clear lf_con.
    endif.

    if lf_con = 'X'.
*--All functions found - Add Conflict to output.
**BOC : UMITTAL SMUD issue
*      READ TABLE lt_role_name INTO ls_role_name
*        WITH KEY ref_key = lt_roles-rolid
*        BINARY SEARCH.
*          IF sy-subrc EQ 0.
*            wa_output-agr_name = ls_role_name-key_val.
*          ENDIF.
        wa_output-agr_name    = lt_roles-rolid.
**EOC : UMITTAL SMUD issue
*----Odubey 17.01.2022 roleid text
        CALL FUNCTION '/PSYNG/SW_CR_READ_ROLES_EN'
          EXPORTING
            i_rolid                         = lt_roles-rolid
            i_appl                          = lt_roles-appl
            i_sysid                         = lt_roles-sysid
         IMPORTING
           es_rolid_value                  = ls_role_value
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             SOURCE_ROLID_DOESNT_EXIST = 1
             NOT_AUTHORIZED_TO_DISPLAY = 2
             OTHERS                    = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

        wa_output-agr_text    = ls_role_value-rdesc.
        wa_output-conid       = conflict-conid.
        wa_output-description = conflict-DESCRIPTION.
        wa_output-imp         = conflict-imp.
        wa_output-rfcdest     = lt_roles-sysid.
        wa_output-appl        = lt_roles-appl.
        APPEND wa_output TO gt_routput_sum.
    endif.
  endloop.
endloop.
ENDIF.

*--Mark Mitigations in output.
  IF ( NOT lt_mcrole[] IS INITIAL ) OR ( NOT lt_mccarole[] IS INITIAL ).
    MESSAGE s002 WITH 'Applying Mitigations to Results'.
    commit work.

    CONCATENATE sy-sysid sy-mandt INTO et_mitigations-rfcdest.
    SORT lt_mcrole BY agr_name conid.
    SORT lt_mccarole BY agr_name swaudid.
    FIELD-SYMBOLS : <out> LIKE LINE OF gt_routput.
    LOOP AT gt_routput_sum ASSIGNING <out> WHERE appl = 'SAP'.
      READ TABLE lt_mcrole WITH KEY agr_name = <out>-agr_name
                                    conid    = <out>-conid
                                    BINARY SEARCH.
      IF sy-subrc = 0.
        <out>-contid = lt_mcrole-contid.
        MOVE-CORRESPONDING lt_mcrole TO et_mitigations.
        et_mitigations-type = '4'.
        APPEND et_mitigations.
      ELSE.
        READ TABLE lt_mccarole WITH KEY agr_name = <out>-agr_name
                                        swaudid  = <out>-conid
                                        BINARY SEARCH.
        IF sy-subrc = 0.
          <out>-contid = lt_mccarole-contid.
          MOVE-CORRESPONDING lt_mccarole TO et_mitigations.
          et_mitigations-type = '5'.
          APPEND et_mitigations.
        ENDIF.
      ENDIF.

      IF <out>-simu = 'X'.
        READ TABLE lt_mcrole WITH KEY agr_name = <out>-child_agr
                                conid    = <out>-conid
                                BINARY SEARCH.
        IF sy-subrc = 0.
          <out>-contid = lt_mcrole-contid.
          MOVE-CORRESPONDING lt_mcrole TO et_mitigations.
          et_mitigations-type = '4'.
          APPEND et_mitigations.
        ELSE.
          READ TABLE lt_mccarole WITH KEY agr_name = <out>-child_agr
                                          swaudid  = <out>-conid
                                          BINARY SEARCH.
          IF sy-subrc = 0.
            <out>-contid = lt_mccarole-contid.
            MOVE-CORRESPONDING lt_mccarole TO et_mitigations.
            et_mitigations-type = '5'.
            APPEND et_mitigations.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDLOOP.
    IF i_shomit <> 'X'.
      DELETE gt_routput_sum WHERE contid <> ''.
    ENDIF.
  ENDIF.
  IF i_shonosod = 'X'.
    PERFORM report_roles_without_conflict.
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


*--Update stats




  DESCRIBE TABLE iagr_define LINES objectcount_fm.
  SELECT COUNT( * ) FROM /psyng/conflict
         INTO concount_fm
         WHERE conid IN gt_confs
         AND   vrsio = g_vrsio.
  byobject = 'ROLE'.

  CALL FUNCTION '/PSYNG/SW_SOD_UPDATE_STAT'
    IN BACKGROUND TASK
    EXPORTING
      objectcount_fm       = objectcount_fm
      concount_fm          = concount_fm
      byobject             = byobject.
  COMMIT WORK.

  return = g_return.
  MOVE-CORRESPONDING g_return TO et_return.
  et_return-id = g_return-code(2).
  et_return-number = g_return-code+2.
  APPEND et_return.
ENDFUNCTION.
