FUNCTION /psyng/sw_func_user_detail_42 .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_SHOWCOMP) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_SHOWPCOM) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_EXLCKUSR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_VALIDUSR) TYPE  FLAG OPTIONAL
*"     VALUE(IF_OUTVDATE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ORGCHK) TYPE  FLAG DEFAULT ''
*"     VALUE(I_SODVRSIO) TYPE  /PSYNG/SODVRSIO DEFAULT '000'
*"     VALUE(I_CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(I_ORG_FIELD) TYPE  FLAG OPTIONAL
*"     VALUE(I_EXCLUDE_ER_ROLES) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_BNAME STRUCTURE  /PSYNG/RANGE_BNAME OPTIONAL
*"      IT_CONFDET STRUCTURE  /PSYNG/CONFDET OPTIONAL
*"      IT_FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN OPTIONAL
*"      IT_FAOBJ STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM OPTIONAL
*"      ET_OUTPUTDET STRUCTURE  /PSYNG/SW_FUNC_SCAN_DET OPTIONAL
*"      IT_ACTGROUPS STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_PROFILES STRUCTURE  /PSYNG/SW_SEL_OPTS_PROFILE OPTIONAL
*"      IT_USERTYPE STRUCTURE  /PSYNG/SW_SEL_OPTS_USRTYP OPTIONAL
*"      IT_CLASS STRUCTURE  /PSYNG/RANGE_CLASS OPTIONAL
*"      ET_USER_PROF STRUCTURE  /PSYNG/SE_USER_PROF_ROLE OPTIONAL
*"      IT_FAOBJ_ORG STRUCTURE  /PSYNG/FAOBJ2 OPTIONAL
*"      IT_ORGLVL STRUCTURE  /PSYNG/SW_SEL_OPTS_ORG OPTIONAL
*"----------------------------------------------------------------------
* Detailed Function Analysis
* - Only for 1 single system
* - SOD Matrix content has to be passed to the FM
* - Simulation Not Supported
* - Including ER roles not supported
* - Excluding ER roles not supported
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_FUNC_USER_DETAIL_42'.
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

  DATA: lt_users       TYPE STANDARD TABLE OF usr02 WITH HEADER LINE,
        lt_usertcode   TYPE STANDARD TABLE OF /psyng/usertcode,
        lt_userprof    TYPE STANDARD TABLE OF /psyng/userprof,
        lt_userauth    TYPE STANDARD TABLE OF /psyng/userauth,
        lt_systemauths TYPE STANDARD TABLE OF /psyng/psswtcdaut,
        lt_orgauths    TYPE STANDARD TABLE OF /psyng/swsodorgauth,
        lt_tcode_obj   TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_unique_org_abb
                       TYPE TABLE OF /psyng/swsodorgm

                       WITH HEADER LINE,
        lt_org_objects TYPE  TABLE OF /psyng/faobj2

                       WITH HEADER LINE
  .

*--Load Users
  PERFORM get_users_from_selection
    TABLES
      it_bname
      it_class
      it_usertype
      it_actgroups
      it_profiles
      lt_users
    USING
      if_exlckusr
      if_validusr
      if_outvdate.
  DATA : g_macro_cfg_value TYPE /psyng/param_value,
         g_macro_cfg_param TYPE /psyng/param.
*--Get the value of a configuration parameter
*  Usage Example : se_config_param 'ORG_LEVEL' l_value.
  DEFINE se_config_param.
    g_macro_cfg_param = &1.
    call function '/PSYNG/SW_GET_CONFIG'
         exporting
              i_parameter = g_macro_cfg_param
         importing
              e_value     = g_macro_cfg_value
         exceptions
              others      = 1.                   "#EC SAST_CI_GEN_CHECK
  "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
     ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

    if sy-subrc <> 0.
      message w002(/psyng/sw) with
      'Error Reading configuration parameter ' &1.
    endif.
    move g_macro_cfg_value to &2.
  END-OF-DEFINITION.
  DATA: l_tcode_validation TYPE /psyng/param_value.
  se_config_param   'DFLT_TCOD_VALIDATION' l_tcode_validation.
  IF l_tcode_validation EQ 'Y'.
*--Validate the tcodes in the matrix exist
    CALL FUNCTION '/PSYNG/SW_120'
         TABLES
              it_functtran = it_functtran
              it_faobj     = it_faobj.
  ENDIF.
*--Load User's Authorizations
  PERFORM load_user_auths
    TABLES
      it_functtran
      it_faobj
      lt_users
      lt_usertcode
      lt_userprof
      lt_userauth
      USING
      i_exclude_er_roles.
*--Load matching system auths (including org auths)
  PERFORM load_system_auths
    TABLES
      it_faobj
      it_functtran
      lt_userauth
      lt_usertcode
      it_swsodorgm
      lt_systemauths
      lt_orgauths.

*--Create summarized tables to use in analysis
  lt_tcode_obj[] = it_faobj[].
  SORT lt_tcode_obj BY funid tcode object.
  DELETE ADJACENT DUPLICATES FROM lt_tcode_obj
  COMPARING funid tcode object.
  LOOP AT it_swsodorgm.
    lt_org_objects-object = it_swsodorgm-object.
    INSERT TABLE lt_org_objects.
    lt_unique_org_abb-abb = it_swsodorgm-abb.
    INSERT TABLE lt_unique_org_abb.
  ENDLOOP.
  SORT :
    lt_unique_org_abb,
    lt_org_objects.
  DELETE ADJACENT DUPLICATES FROM :
    lt_unique_org_abb,
    lt_org_objects.

*--Sort all necessary tables
  SORT lt_systemauths BY funid tcode objct.
  SORT lt_userauth    BY bname objct auth.
  SORT lt_orgauths    BY auth object.

*--BOC AKUMAR PN-11746 17.06.2025
*--Delete records for abb. which do not satisfy org level filter
  IF it_orglvl[] IS NOT INITIAL.
    DELETE lt_orgauths WHERE abb NOT IN it_orglvl.
  ENDIF.
*--EOC AKUMAR PN-11746

  LOOP AT lt_users.
    PERFORM analyze_user_functions
      TABLES
        it_faobj
        it_functtran
        lt_userauth
        lt_usertcode
        lt_systemauths
        it_swsodorgm
        lt_orgauths
        lt_unique_org_abb
        lt_tcode_obj
        lt_org_objects
        et_outputdet
        it_faobj_org "OPL645
      USING
        lt_users-bname
        i_org_field. "OPL645
  ENDLOOP.
  IF et_user_prof  IS REQUESTED.
*--Return info on which roles profiles belong to
    LOOP AT et_outputdet.
      et_user_prof-bname     = et_outputdet-bname.
      et_user_prof-profile   = et_outputdet-profile.
      et_user_prof-comp_prof = et_outputdet-comp_prof.
      COLLECT et_user_prof.
    ENDLOOP.
    CALL FUNCTION '/PSYNG/SW_USER_PROFILE_ROLE'
         EXPORTING
              if_showcomp  = if_showcomp
         TABLES
              it_user_prof = et_user_prof.

  ENDIF.
ENDFUNCTION.
