*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_API_I_SOD_BY_ROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_api_i_sod_by_refrole.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(REQUEST_ID) TYPE  /PSYNG/REQUEST_ID OPTIONAL
*"     VALUE(BATCH_ID) TYPE  /PSYNG/BATCH_ID OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_DEF_VRSIO) TYPE  FLAG OPTIONAL
*"     VALUE(CONFIG_SET) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_DEF_CONF) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ORG_CHECK) TYPE  FLAG OPTIONAL
*"     VALUE(LOGGING_FLAG) TYPE  FLAG OPTIONAL
*"     VALUE(IF_LOCAL) TYPE  FLAG DEFAULT 'X'
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SE_ROLE_REF OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_IMP STRUCTURE  /PSYNG/SW_SEL_OPTS_IMP OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_ORGLVL STRUCTURE  /PSYNG/RANGE_DORG_ABB OPTIONAL
*"----------------------------------------------------------------------
  DATA : lt_return       TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_logging     TYPE flag,
         l_results     TYPE i,
         l_roles_in    TYPE string,
         l_roles_out   TYPE string,
         l_roles_ana_i type i,
         l_roles_con_i type i,
         l_roles_con_o type string,
         l_conflicts   TYPE string,
         l_object      TYPE /psyng/longtext,
         lt_output     TYPE TABLE OF /psyng/sw_out_routput,
         lf_continue   TYPE flag,
         lt_ref_roles  TYPE TABLE OF /psyng/bc_agr_name
                       WITH HEADER LINE,
         lt_1251       TYPE TABLE OF agr_1251 WITH HEADER LINE,
         lt_1251_star  TYPE TABLE OF agr_1251 WITH HEADER LINE,

         lt_roles      TYPE TABLE OF /psyng/sw_sod_remote_roles
                       WITH HEADER LINE,
         lt_enroles    TYPE TABLE OF /psyng/en_role_addition_simu
                       WITH HEADER LINE,
         l_counter    type MENU_NUM_6,
         l_timestamp  TYPE TIMESTAMPL,
         l_firstrole   type agr_name.
  FIELD-SYMBOLS : <1251> TYPE agr_1251.
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn.
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
     ID 'ACTVT' FIELD '03'
     ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
  IF sy-subrc <> 0.
  ls_return-type = 'E'.
  ls_return-message
   = 'You are not authorized to analyze the results'(002).
  APPEND ls_return TO et_return.
  CLEAR ls_return.
  EXIT.
  ENDIF.
* EOC by RGUPTA for C0743
  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME   FIELD g_start.

*--Refresh global variables
  REFRESH gt_routput_sum.
  lf_continue = 'X'.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
*--Number of input roles
  DELETE ADJACENT DUPLICATES FROM roles COMPARING ALL FIELDS.
  DESCRIBE TABLE roles LINES l_roles_in.
  if l_roles_in > 0.
    read table roles index 1.
    l_firstrole = roles-agr_name.
  endif.

*--Get default version if asked; do validation of version
  PERFORM get_default_sod
    TABLES
      lt_return
    USING
      if_def_vrsio
    CHANGING
      vrsio
      es_sod_matrix
      lf_continue.
*--Get default config set if asked; do validation of config set
  IF lf_continue = 'X'.
    PERFORM get_last_config_set
      TABLES
        lt_return
        it_systems
      USING
        es_sod_matrix-vrsio
        if_def_conf
        if_local
      CHANGING
        config_set
        es_config_set
        lf_continue.
  ENDIF.
*--Check if any input conflict exists
  IF lf_continue = 'X'.
    PERFORM check_input_conflicts
     TABLES it_conid
            it_imp
            lt_return
      USING vrsio
   CHANGING lf_continue.
  ENDIF.
  IF lf_continue = 'X'.

*--Load the reference roles
*--AND
*--Put list of roles in /PSYNG/SW_SOD_REMOTE_ROLES structure

    lt_roles-rfcdest = 'LOCAL'.
    LOOP AT roles.
      lt_roles-agr_name = roles-agr_name.
      APPEND lt_roles.
      IF roles-reference = 'X'.
        lt_ref_roles-agr_name = roles-agr_name.
        APPEND lt_ref_roles.
      ENDIF.
    ENDLOOP.
    IF lf_continue = 'X'.
*--Validate the Roles
      PERFORM api_validate_roles
        TABLES lt_roles
               lt_return
      CHANGING lf_continue.
    ENDIF.
    IF lf_continue = 'X'.
      IF NOT lt_ref_roles[] IS INITIAL.
*--Handle Reference roles :
*  replace the org placeholders
*--will pass to sod role analysis as advanced simulation
        CALL FUNCTION '/PSYNG/BC_GET_ROLE_AUTH_DETLS'
             EXPORTING
                  if_include_auth    = 'X'
                  if_get_org_details = ''
             TABLES
                  it_roles           = lt_ref_roles
                  ot_1251            = lt_1251.
*--Replace all org placeholders in reference roles with *
        LOOP AT lt_1251 ASSIGNING <1251> where deleted <> 'X'.

          add 1 to l_counter.
          <1251>-counter = l_counter.
          IF <1251>-low CP '$*'.
            lt_1251_star = <1251>.
            add 1 to l_counter.
            lt_1251_star-counter  = l_counter.
            lt_1251_star-low      = '*'.
            lt_1251_star-high     = ''.
            lt_1251_star-modified = 'M'.
            append lt_1251_star.
          else.
            append <1251> to lt_1251_star.
          ENDIF.
        ENDLOOP.
        lt_1251[] = lt_1251_star[].
      ENDIF.

**--Get conflicts for roles in input structure
      PERFORM role_based_sod_analysis
       TABLES lt_roles
              lt_enroles
              it_conid
              it_imp
              et_output
              lt_return
              lt_1251
              it_orglvl
        USING vrsio
              config_set
              'X'
              ''
              if_org_check
              'X' "advanced simulation.
      CHANGING
            l_roles_ana_i."nr of analyzed roles

    ENDIF.
  ENDIF.
*--Prepare the return messages
  CALL FUNCTION '/PSYNG/SW_API_I_HANDLE_ERROR'
       IMPORTING
            es_return = return
       TABLES
            it_return = lt_return
            et_return = et_return.
*--Log this interface call
  IF logging_flag = 'X'
  OR logging_flag = '1'.
*--Get logging configuration
    se_config_param 'APILOG_SOD_BY_REFROL' l_logging.
    IF l_logging = 'Y'.
      DESCRIBE TABLE et_output LINES l_results.
      l_conflicts = l_results.
*--Number of roles in output
      lt_output = et_output[].
      sort lt_output by agr_name.
      delete adjacent duplicates from lt_output comparing agr_name.
      DESCRIBE TABLE lt_output LINES l_roles_con_i.
      l_roles_con_o = l_roles_con_i.
      l_roles_out   = l_roles_ana_i.
      condense : l_roles_con_o , l_roles_out.
      CONCATENATE l_roles_in l_roles_out l_roles_con_o l_conflicts l_firstrole
      INTO l_object SEPARATED BY ' / '.

      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              batch_id        " Blank batch ID
              '/PSYNG/SW_API_SOD_BY_REFROLE'
              l_results
              return
              l_object
              l_timestamp.
    ENDIF.
  ENDIF.
  MESSAGE s002(/psyng/sw) WITH 'Analysis Complete'(001).
*--Commit work to trigger update task FM
  COMMIT WORK.
ENDFUNCTION.
