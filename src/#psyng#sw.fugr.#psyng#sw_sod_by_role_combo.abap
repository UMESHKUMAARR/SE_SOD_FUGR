*----------------------------------------------------------------------*
* FM                    : /PSYNG/SW_SOD_BY_ROLE_COMBO
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_sod_by_role_combo .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  FLAG OPTIONAL
*"     VALUE(I_ENHANC) TYPE  FLAG DEFAULT ' '
*"     VALUE(I_ABAP) TYPE  FLAG DEFAULT 'X'
*"     VALUE(I_NOABAP) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(I_VALIDUSER) TYPE  FLAG OPTIONAL
*"     VALUE(I_OUTVDATE) TYPE  FLAG OPTIONAL
*"     VALUE(I_ANALYZE_SAP_ALL) TYPE  CHAR1 OPTIONAL
*"     VALUE(I_EXCLUDE_ER_ROLES) TYPE  FLAG OPTIONAL
*"     VALUE(IF_MIT_BY_ORG) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"  TABLES
*"      1STOUTPUT_FM STRUCTURE  /PSYNG/1STOUTPUT_U OPTIONAL
*"      ROLES STRUCTURE  /PSYNG/SW_SOD_REMOTE_ROLES OPTIONAL
*"      IT_EN_ROLES STRUCTURE  /PSYNG/EN_ROLE_ADDITION_SIMU OPTIONAL
*"      IT_APPL STRUCTURE  /PSYNG/RANGE_APPL OPTIONAL
*"      IT_SYSID STRUCTURE  /PSYNG/RANGE_SYSID OPTIONAL
*"      IT_USER_RFC STRUCTURE  /PSYNG/SW_SEL_OPTS_RFCDEST OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_SOD_BY_ROLE_COMBO'.
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
  CHECK NOT roles[] IS INITIAL OR NOT it_en_roles[] IS INITIAL.

  DATA : lt_dum       TYPE TABLE OF /psyng/sw_sel_opts_xubname
                      WITH HEADER LINE,
         lt_outputdet TYPE TABLE OF /psyng/sw_sod_output_org,
         lt_return    TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         lf_continue  TYPE flag.
  FIELD-SYMBOLS :
          <out>  TYPE /psyng/sw_sod_output_org,
          <role> TYPE /psyng/sw_sod_remote_roles.
  lt_dum-low    = '000000000000'.
  lt_dum-sign   = 'I'.
  lt_dum-option = 'EQ'.
  APPEND lt_dum.
*--Import parameter Validation
  lf_continue = 'X'.
  PERFORM api_validate_input
  TABLES
      lt_return
    USING
      if_def_vrsio
      if_def_conf
    CHANGING
      vrsio
      config_set
      es_config_set
      es_sod_matrix
      lf_continue.
  IF lf_continue = 'X'.
*--Validate the Roles
    PERFORM api_validate_roles
      TABLES roles
             lt_return.
    CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
         EXPORTING
              i_validuser      = i_validuser
              i_outvdate       = i_outvdate
              i_vrsio          = vrsio
              i_config_set     = config_set
              i_analyze_sap_all = i_analyze_sap_all
              i_output         = 'X'
              i_enh            = i_enhanc
              i_exclude_er_roles = i_exclude_er_roles
              i_abap           = i_abap
              i_nonabap        = i_noabap
              i_org_check      = if_org_check
              if_mit_by_org    = if_mit_by_org
         TABLES
              et_outputdet     = lt_outputdet
              IT_USER_RFC      = IT_USER_RFC
              it_simu_role_rfc = roles
              it_en_roles      = it_en_roles
              it_users         = lt_dum
              it_appl          = it_appl
              it_sysid         = it_sysid
              et_return        = lt_return.
  ENDIF.
  LOOP AT lt_outputdet ASSIGNING <out>.
    MOVE-CORRESPONDING <out> TO 1stoutput_fm .
    1stoutput_fm-description = <out>-condesc.
    APPEND 1stoutput_fm .
  ENDLOOP.
  PERFORM api_handle_error
    TABLES   lt_return
             et_return
    CHANGING return.

  exelog_api '/PSYNG/SW_SOD_BY_ROLE_COMBO' ''.

ENDFUNCTION.
