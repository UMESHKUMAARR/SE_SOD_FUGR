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
FUNCTION /psyng/sw_api_i_sodrefrolcombo.
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
*"     VALUE(I_FUNCTION_DETAILS) TYPE  FLAG DEFAULT ''
*"     VALUE(I_CON_DET) TYPE  FLAG OPTIONAL
*"     VALUE(I_CON_SUM) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(ES_SOD_MATRIX) LIKE  /PSYNG/SWSODVERS STRUCTURE
*"        /PSYNG/SWSODVERS
*"     VALUE(ES_CONFIG_SET) LIKE  /PSYNG/SWCFGSET STRUCTURE
*"        /PSYNG/SWCFGSET
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      ROLES STRUCTURE  /PSYNG/SE_ROLE_REF OPTIONAL
*"      ET_OUTPUT STRUCTURE  /PSYNG/SW_OUT_ROUTPUT OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRETURN OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      ET_OUTPUT_DET STRUCTURE  /PSYNG/SW_OUTPUTDET3 OPTIONAL
*"----------------------------------------------------------------------
  DATA : lt_return       TYPE TABLE OF  bapiret2 WITH HEADER LINE,
         l_start_date  TYPE dats,
         l_start_time  TYPE tims,
         l_logging     TYPE flag,
         l_results     TYPE i,
         l_roles_in    TYPE string,
         l_roles_out   TYPE string,
         l_conflicts   TYPE string,
         l_object      TYPE /psyng/longtext,
         lf_continue   TYPE flag,
         lt_ref_roles  TYPE TABLE OF /psyng/bc_agr_name
                       WITH HEADER LINE,
         lt_1251       TYPE TABLE OF agr_1251 WITH HEADER LINE,
         lt_1251_star  TYPE TABLE OF agr_1251 WITH HEADER LINE,

         lt_roles      TYPE TABLE OF /psyng/sw_sod_remote_roles
                       WITH HEADER LINE,
         l_counter    TYPE menu_num_6.
  DATA : lt_dum       TYPE TABLE OF /psyng/sw_sel_opts_xubname
                      WITH HEADER LINE,
         lt_outputdet TYPE TABLE OF /psyng/sw_sod_output_org,
         l_timestamp TYPE timestampl,
           l_org_field        TYPE flag,                      "OPL645
         swconfig TYPE /psyng/swconfig.                     "OPL645
  FIELD-SYMBOLS :
            <1251> TYPE agr_1251,
            <out>  TYPE /psyng/sw_sod_output_org.
* BOC by RGUPTA for C0743
  DATA: ls_return TYPE bapireturn,
        lt_simu_role_add TYPE TABLE OF /psyng/sw_role_addition_simu,
        ls_simu_role_add TYPE /psyng/sw_role_addition_simu,
        lt_rfcdes         TYPE TABLE OF /psyng/sw_sel_opts_rfcdest,
        ls_rfcdes         TYPE /psyng/sw_sel_opts_rfcdest,
        lt_outputdet_part TYPE TABLE OF  /psyng/sw_outputdet3.
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

*--BOC AKUMAR OPL645
*--Consider org field
  CLEAR swconfig.
  se_config_param 'CONSIDER_ORG_FIELD' swconfig-value.
  IF swconfig-value = 'Y'.
    l_org_field = 'X'.
  ELSEIF swconfig-value = 'N'.
    l_org_field = ' '.
  ENDIF.
  CLEAR swconfig.
*--EOC AKUMAR OPL645

  GET TIME STAMP FIELD l_timestamp.
  GET RUN TIME   FIELD g_start.
  lt_dum-low    = '000000000000'.
  lt_dum-sign   = 'I'.
  lt_dum-option = 'EQ'.
  APPEND lt_dum.
*--Refresh global variables
  REFRESH gt_routput_sum.
  lf_continue = 'X'.
  l_start_date = sy-datum.
  l_start_time = sy-uzeit.
*--Number of input roles
  DELETE ADJACENT DUPLICATES FROM roles COMPARING ALL FIELDS.
  DESCRIBE TABLE roles LINES l_roles_in.
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

* Begin of Addition AKUMAR PN-15676 16.10.2025
*--Put list of roles in /psyng/sw_role_addition_simu structure
*    ls_simu_role_add-source_rfcdest = 'D67800'.
*    ls_simu_role_add-target_rfcdest = 'D67800'.
    ls_simu_role_add-sign = 'I'.
    ls_simu_role_add-option = 'EQ'.
    LOOP AT roles.
      ls_simu_role_add-low = roles-agr_name.
      APPEND ls_simu_role_add TO lt_simu_role_add.
    ENDLOOP.

*    ls_rfcdes-sign = 'I'.
*    ls_rfcdes-option = 'EQ'.
*    CONCATENATE sy-sysid sy-mandt INTO ls_rfcdes-low.
*    APPEND ls_rfcdes TO lt_rfcdes.
* End of Addition AKUMAR

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
        LOOP AT lt_1251 ASSIGNING <1251>.

          ADD 1 TO l_counter.
          <1251>-counter = l_counter.
          IF <1251>-low CP '$*'.
            lt_1251_star = <1251>.
            ADD 1 TO l_counter.
            lt_1251_star-counter  = l_counter.
            lt_1251_star-low      = '*'.
            lt_1251_star-high     = ''.
            lt_1251_star-modified = 'M'.
            APPEND lt_1251_star.
          ELSE.
            APPEND <1251> TO lt_1251_star.
          ENDIF.
        ENDLOOP.
        lt_1251[] = lt_1251_star[].
      ENDIF.

* BOC AKUMAR PN-15676 16.10.2025
      IF i_con_sum = 'X'.
**--Get conflicts for roles in input structure
        CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
             EXPORTING
                  i_vrsio              = vrsio
                  i_config_set         = config_set
*--> BOC : UMITTALL:Show Function ID:OPL 645
                  i_function_details = i_function_details
*<-- EOC : UMITTALL:Show Function ID:OPL 645
                  i_output             = 'X'
*              i_enh            = i_enhanc   "No need of enhanced matrix
                  i_abap               = 'X'
                  i_nonabap            = ''
                  i_org_check          = if_org_check
                  i_advanced_role_simu = 'X'   "advanced simulation
                  i_org_field          = l_org_field "OPL645
                  if_mit_by_org        = 'X' "AKUMAR++ PN16222 bug 4
             TABLES
                  et_outputdet          = lt_outputdet
                  it_simu_role_rfc      = lt_roles
*   it_en_roles      = it_en_roles   "No need of non-abap applications
                  it_users              = lt_dum
                  it_advanced_role_simu = lt_1251
*                it_appl              = it_appl
*                it_sysid             = it_sysid
                  et_return             = lt_return.
        SORT lt_outputdet BY conid.
        LOOP AT lt_outputdet ASSIGNING <out>.
          MOVE-CORRESPONDING <out> TO et_output.
          et_output-description = <out>-condesc.
          "(++)UMITTALL:Show Fun ID:OPL 645
          et_output-functionid = <out>-funid.
          APPEND et_output.
        ENDLOOP.
      ENDIF.

      IF i_con_det = 'X'.
        CALL FUNCTION '/PSYNG/SW_081'
                  EXPORTING
                    i_byuser              = 'X'
                    i_bysimu              = 'X'
                    i_showcomp            = 'X'
                    i_config_set          = config_set
                    i_nonabap             = ''
                    i_abap                = 'X'
                    i_sodvrsio            = vrsio
                    i_orgchk              = if_org_check
                    i_advanced_role_simu  = 'X'
                    i_org_field           = l_org_field "OPL645
                    i_api_call            = 'X' "AKUMAR++ PN15676
                  TABLES
                    it_advanced_role_simu = lt_1251
*                    it_rfcdest            = lt_rfcdes[]
                     it_bname              = lt_dum[]
                    et_outputdet          = lt_outputdet_part[]
                    it_simu_role_addition = lt_simu_role_add[]
                  EXCEPTIONS
                    user_cancelled        = 1
                    OTHERS                = 2.
        IF sy-subrc = 0.
          IF NOT lt_outputdet_part[] IS INITIAL.
            et_output_det[] = lt_outputdet_part[].
          ELSE.
            log lt_return 'S' '' 'No data found' '.' '' ''.
          ENDIF.
        ELSE.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                 WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.


      ENDIF.
* EOC AKUMAR

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
    se_config_param 'APILOG_SODREFROLCOMB' l_logging.
    IF l_logging = 'Y'.

* BOC AKUMAR PN-15676 16.10.2025
      IF i_con_sum = 'X'.
        DESCRIBE TABLE et_output LINES l_results.
        l_conflicts = l_results.
      ELSE.
*Logic to calculate total number of unique conflicts
        SORT lt_outputdet_part BY conid.
        DELETE ADJACENT DUPLICATES FROM lt_outputdet_part
        COMPARING conid.
        DESCRIBE TABLE lt_outputdet_part LINES l_results.
        l_conflicts = l_results.
      ENDIF.
* EOC AKUMAR

      CONCATENATE l_roles_in l_conflicts
      INTO l_object SEPARATED BY ' / '.

      PERFORM create_logging_entry
        USING l_start_date
              l_start_time
              request_id
              batch_id        " Blank batch ID
              '/PSYNG/SW_API_SODREFROLCOMBO'
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
