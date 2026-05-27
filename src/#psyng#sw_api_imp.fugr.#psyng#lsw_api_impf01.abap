*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_API_IMPF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_default_sod
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ET_RETURN      Table for messages
*      <--ES_SOD_MATRIX  SOD Matrix
*      <--EF_CONTINUE    Continue flag
*----------------------------------------------------------------------*
FORM get_default_sod
TABLES   et_return     STRUCTURE bapiret2
USING    if_def_vrsio  TYPE flag
CHANGING e_vrsio       TYPE /psyng/sodvrsio
         es_sod_matrix TYPE /psyng/swsodvers
         ef_continue   TYPE flag.

  DATA :   l_dflt_vrsio  TYPE /psyng/param.
  IF if_def_vrsio = 'X'.
*--Get default version
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF NOT l_dflt_vrsio IS INITIAL.
      log_v et_return 'I' 'DEFAULT_VERSION'
        'SOD Matrix version used :' 'DFLT_GLOBAL_VERSION'
        l_dflt_vrsio l_dflt_vrsio ''.
      e_vrsio = l_dflt_vrsio.
*--return info on SOD Matrix
      SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
      WHERE vrsio = e_vrsio.
      IF sy-subrc <> 0.
        log_v et_return 'E' 'INVALIDVERSION'
        'SOD Matrix version is invalid ' e_vrsio '.' e_vrsio ''.
        CLEAR ef_continue.
      ENDIF.
    ELSE.
      log et_return 'E' 'NO_DEFAULT_VERSION'
        'No Default SOD Matrix defined in ' 'DFLT_GLOBAL_VERSION' '' ''.
      CLEAR ef_continue.
    ENDIF.
  ELSE.
*--return info on SOD Matrix
    SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
    WHERE vrsio = e_vrsio.
    IF sy-subrc <> 0.
      log_v et_return 'E' 'INVALIDVERSION'
      'SOD Matrix version is invalid ' e_vrsio '.' e_vrsio ''.
      CLEAR ef_continue.
    ENDIF.
  ENDIF.

ENDFORM.                    " get_default_sod
*&---------------------------------------------------------------------*
*&      Form  get_last_config_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <->ET_RETURN      Table for messages
*      -->I_VRSIO        Version
*      <--ES_CONFIG_SET  Last configuration set
*----------------------------------------------------------------------*
FORM get_last_config_set TABLES   et_return     STRUCTURE bapiret2
                                  it_systems    STRUCTURE
                                  /psyng/swcfgsys
                         USING    i_vrsio       TYPE /psyng/sodvrsio
                                  if_def_conf   TYPE flag
                                  if_local      TYPE flag
                         CHANGING config_set    TYPE /psyng/seconfid
                                  es_config_set TYPE /psyng/swcfgset
                                  ef_continue   TYPE flag.

  DATA: lf_cfg_set_enabled TYPE flag,
        lt_rfcdest         TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH
        HEADER LINE,
        lt_dest            TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER
        LINE.

  IF NOT it_systems[] IS INITIAL.
*--Load RFC Destinations for requested systems
    SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_dest FOR ALL ENTRIES IN
    it_systems WHERE
      systid = it_systems-sysid.
    lt_rfcdest-sign   = 'I'.
    lt_rfcdest-option = 'EQ'.
    LOOP AT lt_dest.
      IF NOT lt_dest-rfcdest IS INITIAL OR if_local IS INITIAL.
        "local system is handled by parameter
        "if_local if it's set,
        "otherwise allow it
        lt_rfcdest-low = lt_dest-rfcdest.
        APPEND lt_rfcdest.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled = 'X'.
    CLEAR et_return.
    log et_return 'I' 'CFG_SET_ENABLED'
       'Configuration Set functionality enabled'
       'CFG_SET_ENABLED = X' '' ''.
    IF if_def_conf = 'X'.
*  --Get default Configuration Set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio         = 'X'
          i_cfgvrsio      = i_vrsio
          if_local_system = if_local
        IMPORTING
          e_config_set    = es_config_set-setid
          ef_success      = ef_continue
        TABLES
          et_return       = et_return
          it_rfcdest      = lt_rfcdest.
      IF ef_continue = 'X'.
        config_set = es_config_set-setid.
      ENDIF.
    ENDIF.
*  --Validate Configuration Set and get details
    IF ef_continue = 'X'.
      SELECT SINGLE *  INTO es_config_set FROM /psyng/swcfgset
       WHERE setid  = config_set.
      IF sy-subrc <> 0.
        CLEAR et_return.
        log_v et_return 'E' 'INVALIDCONFSET'
          'Configuration Set Does not exist.' config_set ''
          config_set ''.
*--If config set was not specified, allow analysis to continue
        IF NOT config_set IS INITIAL.
          CLEAR ef_continue.
        ENDIF.
      ENDIF.
    ENDIF.
  ELSE.
    CLEAR et_return.
    log et_return 'I' 'CFG_SET_DISABLED'
      'Configuration Set functionality Disabled'
      'CFG_SET_ENABLED <> X' '' ''.
  ENDIF.

ENDFORM.                    " get_last_config_set
*&---------------------------------------------------------------------*
*&      Form  api_validate_roles
*&---------------------------------------------------------------------*
*       Validate that each role exists and the destinations
*       are reachable.
*       Any issues are returned as a W(warning) message.
*       If no valid roles are found, the FM doing the actual SOD
*       analysis will return an E (error).
*----------------------------------------------------------------------*
*      -->P_ROLES  text
*      -->P_LT_RETURN  text
*----------------------------------------------------------------------*
FORM api_validate_roles
TABLES   et_roles    STRUCTURE /psyng/sw_sod_remote_roles
         et_return   STRUCTURE bapiret2
CHANGING ef_continue TYPE      flag.

  FIELD-SYMBOLS: <role>    TYPE /psyng/sw_sod_remote_roles.
  DATA : lt_unique_rfcs   TYPE TABLE OF /psyng/sw_sod_remote_roles,
         ls_unique_rfcs   TYPE /psyng/sw_sod_remote_roles,
         l_rfc            TYPE rfcdest,
         lt_role_names    TYPE TABLE OF agr_define,
         l_system_msg(72) TYPE c,
         l_in_cnt         TYPE i,
         l_out_cnt        TYPE i,
         l_agr_name       TYPE agr_name.
  RANGES: lr_roles         FOR l_agr_name.
  CHECK NOT et_roles[] IS INITIAL.
*--Populate RFC destinations with LOCAL if left blank
  LOOP AT et_roles ASSIGNING <role>.
    IF <role>-rfcdest IS INITIAL.
      <role>-rfcdest = 'LOCAL'.
    ENDIF.
  ENDLOOP.
*--Check if the roles exist, if not add error message
  lt_unique_rfcs = et_roles[].
  SORT lt_unique_rfcs BY rfcdest.
  DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs COMPARING rfcdest.
  LOOP AT lt_unique_rfcs INTO ls_unique_rfcs.
    REFRESH : lr_roles, lt_role_names.
    lr_roles-sign   = 'I'.
    lr_roles-option = 'EQ'.
    LOOP AT et_roles WHERE rfcdest = ls_unique_rfcs-rfcdest.
      lr_roles-low  = et_roles-agr_name.
      APPEND lr_roles.
    ENDLOOP.
    l_rfc = ls_unique_rfcs-rfcdest.
    IF l_rfc = 'LOCAL'.
      CLEAR l_rfc.
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

    CALL FUNCTION '/PSYNG/SW_102'
      DESTINATION l_rfc
      TABLES
        it_roles_range        = lr_roles
        et_roles              = lt_role_names
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      log_v et_return 'W' 'ROLERFCFAIL' 'Unable to validate roles on '
                         ls_unique_rfcs-rfcdest  l_system_msg
                         ls_unique_rfcs-rfcdest ''.
      DELETE et_roles[] WHERE rfcdest = ls_unique_rfcs-rfcdest.
    ELSE.
      DESCRIBE TABLE lr_roles      LINES l_in_cnt.
      DESCRIBE TABLE lt_role_names LINES l_out_cnt.
      IF l_out_cnt EQ 0.
        DELETE et_roles[] WHERE rfcdest = ls_unique_rfcs-rfcdest.
      ELSEIF l_in_cnt <> l_out_cnt.
*--Some roles not found
        SORT lt_role_names BY agr_name.
        LOOP AT lr_roles.
          READ TABLE lt_role_names WITH KEY agr_name = lr_roles-low
          BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            log_v et_return 'W' 'INVALIDROLE' 'Invalid Role '
                            ls_unique_rfcs-rfcdest lr_roles-low
                            ls_unique_rfcs-rfcdest lr_roles-low.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF et_roles[] IS INITIAL.
    log_v et_return 'E' 'NOSIMUROLES'
      'No Roles exist.' '' ''
      '' ''.
    CLEAR ef_continue.
  ENDIF.
ENDFORM.                    " api_validate_roles
FORM api_validate_input
TABLES   et_return     STRUCTURE bapiret2
         it_rfcdest    STRUCTURE /psyng/sw_sel_opts_rfcdest
USING    if_def_vrsio  TYPE flag
         if_def_conf   TYPE flag
         if_local      TYPE flag
CHANGING vrsio         TYPE /psyng/sodvrsio
         config_set    TYPE /psyng/seconfid
         es_config_set TYPE /psyng/swcfgset
         es_sod_matrix TYPE /psyng/swsodvers
         ef_continue   TYPE flag
.

  DATA : l_dflt_vrsio       TYPE /psyng/param,
         lf_cfg_set_enabled TYPE flag.
  IF if_def_vrsio = 'X'.
*--Use default global version
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF NOT l_dflt_vrsio IS INITIAL.
      log_v et_return 'I' 'DEFAULT_VERSION'
        'SOD Matrix version used :' 'DFLT_GLOBAL_VERSION'
        l_dflt_vrsio l_dflt_vrsio ''.
      vrsio = l_dflt_vrsio.
    ELSE.
      log et_return 'E' 'NO_DEFAULT_VERSION'
        'No Default SOD Matrix defined in ' 'DFLT_GLOBAL_VERSION' '' ''.
      CLEAR ef_continue.
    ENDIF.
  ELSE.
    SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
    WHERE vrsio = vrsio.
    IF sy-subrc <> 0.
      log et_return 'E' 'INVALIDVERSION'
      'SOD Matrix version is invalid ' vrsio '.' ''.
      CLEAR ef_continue.
    ENDIF.
  ENDIF.
  CHECK ef_continue = 'X'.
*--return info on SOD Matrix
  SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
  WHERE vrsio = vrsio.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled = 'X'.
    log et_return 'I' 'CFG_SET_ENABLED'
       'Configuration Set functionality enabled'
       'CFG_SET_ENABLED = X' '' ''.

    IF if_def_conf = 'X'.
*  --Use default Configuration Set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio          = 'X'
          i_cfgvrsio       = vrsio
          if_local_system  = if_local
        IMPORTING
          e_config_set = es_config_set-setid
          ef_success   = ef_continue
        TABLES
          et_return    = et_return
          it_rfcdest   = it_rfcdest.
      IF ef_continue = 'X'.
        config_set = es_config_set-setid.
      ENDIF.
    ENDIF.
*  --Validate Configuration Set
    IF ef_continue = 'X'.
      SELECT SINGLE *  INTO es_config_set FROM /psyng/swcfgset
       WHERE setid  = config_set.
      IF sy-subrc <> 0.
        log_v et_return 'E' 'INVALIDCONFSET'
          'Configuration Set Does not exist.' config_set ''
          config_set ''.
        CLEAR ef_continue.
      ENDIF.
    ENDIF.
  ELSE.
    log et_return 'I' 'CFG_SET_DISABLED'
      'Configuration Set functionality Disabled'
      'CFG_SET_ENABLED <> X' '' ''.
  ENDIF.

ENDFORM.                    " api_validate_input

*&---------------------------------------------------------------------*
*&      Form  role_based_sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_VRSIO  text
*      -->P_CONFIG_SET  text
*      -->P_I_ABAP  text
*      -->P_I_NOABAP  text
*      -->P_IF_ORG_CHECK  text
*      -->P_ROLES  text
*      -->P_IT_EN_ROLES  text
*      -->P_IT_CONID  text
*      -->P_IT_IMP  text
*      -->P_ET_OUTPUT  text
*      -->P_LT_RETURN  text
*----------------------------------------------------------------------*
FORM role_based_sod_analysis
TABLES it_roles    STRUCTURE /psyng/sw_sod_remote_roles
       it_en_roles STRUCTURE /psyng/en_role_addition_simu
       it_conid    STRUCTURE /psyng/range_conid
       it_imp      STRUCTURE /psyng/sw_sel_opts_imp
       et_output   STRUCTURE /psyng/sw_out_routput
       et_return   STRUCTURE bapiret2
       it_adv_simu STRUCTURE agr_1251
       it_orglvl   STRUCTURE /psyng/range_dorg_abb
 USING i_vrsio      TYPE /psyng/sodvrsio
       i_config_set TYPE /psyng/seconfid
       i_abap       TYPE flag
       i_noabap     TYPE flag
       if_org_check TYPE flag
       if_adv_simu  TYPE flag
 CHANGING
      e_analyzed_roles TYPE i.
  CLEAR e_analyzed_roles.
  DATA : lt_routput_sum TYPE TABLE OF /psyng/sw_out_routput,
         ls_rfcdes      TYPE rfcdes,
         l_local_sod    TYPE flag.

  DATA : lt_conflict        TYPE TABLE OF /psyng/conflict,
         ls_conflict        TYPE /psyng/conflict,
         lt_confdet         TYPE TABLE OF /psyng/confdet,
         lt_functtran       TYPE TABLE OF /psyng/functtran,
         lt_faobj           TYPE TABLE OF /psyng/faobj2,
         lt_swsodorgm       TYPE TABLE OF /psyng/swsodorgm,
         lt_tcodes          TYPE TABLE OF /psyng/sw_par_tcode_output,
         lt_functran_no_enh TYPE TABLE OF /psyng/functtran,
         lt_confdet_sys     TYPE TABLE OF /psyng/confdet,
         lt_con_sys         TYPE TABLE OF /psyng/conflict,
         lt_functtran_sys   TYPE TABLE OF /psyng/functtran,
         lt_faobj_sys       TYPE TABLE OF /psyng/faobj2,
         l_system           TYPE /psyng/rfcname,
         lt_conflict_sys    TYPE /psyng/swt_sys_filt_conflict,
         lt_rfc_sel         TYPE STANDARD TABLE OF
                            /psyng/sw_sel_opts_rfcdest,
         ls_rfc_sel         TYPE /psyng/sw_sel_opts_rfcdest,
         lt_rfc             TYPE STANDARD TABLE OF rfcdes,
         lt_role_sel        TYPE STANDARD TABLE OF
                            /psyng/sw_sel_opts_agr_name,
         lt_role_nabap      TYPE STANDARD TABLE OF
                            /psyng/sw_sel_opts_agr_name,
         ls_role_sel        TYPE /psyng/sw_sel_opts_agr_name,
         lt_appl            TYPE STANDARD TABLE OF
                            /psyng/range_appl,
         ls_appl            TYPE /psyng/range_appl,
         lt_sysid           TYPE STANDARD TABLE OF /psyng/range_sysid,
         ls_sysid           TYPE /psyng/range_sysid,
         ls_roles           TYPE /psyng/sw_sod_remote_roles,
         ls_en_roles        TYPE /psyng/en_role_addition_simu,
         lt_faobj_system    TYPE /psyng/sw_tab_sys_faobj,
         ls_faobj_system    TYPE /psyng/sw_sys_faobj,
         ls_ao_sys          TYPE /psyng/sw_sys_ao,
         lt_ao_sys          TYPE /psyng/sw_tab_sys_ao,
         l_system_msg(80)   TYPE c,
         l_analyzed_roles   TYPE i,
         lt_faobj_org TYPE TABLE OF /psyng/faobj2,          "OPL645
         l_org_field        TYPE flag,                      "OPL645
         swconfig TYPE /psyng/swconfig.                     "OPL645

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

*--Prepare ranges for role and rfc
*  Loop AT it_roles into ls_roles.
  ls_role_sel-sign   = 'I'.
  ls_role_sel-option = 'EQ'.

  ls_rfc_sel-sign    = 'I'.
  ls_rfc_sel-option  = 'EQ'.
  SORT it_roles.
  LOOP AT it_roles INTO ls_roles.
    AT NEW rfcdest.
      ls_rfc_sel-low = ls_roles-rfcdest.
      APPEND ls_rfc_sel TO lt_rfc_sel.
    ENDAT.
*    ls_role_sel-low = ls_roles-agr_name.
*    APPEND ls_role_sel TO lt_role_sel.
  ENDLOOP.
  DELETE lt_rfc_sel WHERE low = 'LOCAL'.
*--Prepare ranges for role and application/system
  SORT it_en_roles BY appl sysid.
  ls_appl-sign   = 'I'.
  ls_appl-option = 'EQ'.

  ls_sysid-sign   = 'I'.
  ls_sysid-option = 'EQ'.
  LOOP AT it_en_roles INTO ls_en_roles.
    MOVE-CORRESPONDING ls_en_roles TO ls_role_sel.
    APPEND ls_role_sel TO lt_role_nabap.
    ls_appl-low  = ls_en_roles-appl.
    APPEND ls_appl  TO lt_appl.
    ls_sysid-low = ls_en_roles-sysid.
    APPEND ls_sysid TO lt_sysid.
  ENDLOOP.
*--Get RFC details
  PERFORM get_rfc_details
   TABLES lt_rfc_sel
          lt_rfc.
  l_local_sod = 'X'.
*--Always load Matrix here for applying system filters
*--Load Local SOD Matrix
  CALL FUNCTION '/PSYNG/SW_028'
    EXPORTING
      i_orgcheck         = if_org_check
      i_vrsio            = i_vrsio
      i_orphan_functions = i_noabap
      i_config_set       = i_config_set
      if_analysis        = 'X'
      i_org_field        = l_org_field                      "OPL645
    IMPORTING
      et_faobj_sys       = lt_faobj_system[]
      et_swsodorgm_sys   = lt_ao_sys[]
    TABLES
      it_spconfs         = it_conid
      it_imp             = it_imp
      et_conflict        = lt_conflict
      et_confdet         = lt_confdet
      et_functtran       = lt_functtran
      et_faobj           = lt_faobj
      et_swsodorgm       = lt_swsodorgm
      et_tcodes          = lt_tcodes
      et_functran_no_enh = lt_functran_no_enh
      it_rfcdest         = lt_rfc
       et_faobj_org       = lt_faobj_org.                    "OPL645
  CLEAR l_local_sod. "we will use the loaded sod matrix on all
  "systems (including local to prevent
  "loading twice)
*--Apply the System filter for conflicts
*  Load, for each conflict, all relevant systems
  CONCATENATE sy-sysid sy-mandt INTO ls_rfcdes-rfcoptions.
  APPEND ls_rfcdes TO lt_rfc.

  CALL FUNCTION '/PSYNG/SW_124'
    EXPORTING
      if_conflict     = 'X'
      i_vrsio         = i_vrsio
    IMPORTING
      et_conflict_sys = lt_conflict_sys[]
    TABLES
      it_conf_rfcdest = lt_rfc
      it_conflicts    = lt_conflict
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options     = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Remote Role Analysis
  IF NOT lt_rfc IS INITIAL.

    IF i_abap = 'X'.
      LOOP AT lt_rfc INTO ls_rfcdes.
        REFRESH lt_routput_sum.
        REFRESH lt_role_sel.
*--Filter Functions by system
        l_system           = ls_rfcdes-rfcoptions.
        lt_functtran_sys[] = lt_functtran[].
        lt_confdet_sys[]   = lt_confdet[].
*--Variable Elements, get the correct values for the remote system
        READ TABLE lt_faobj_system INTO ls_faobj_system
        WITH KEY rfcdest = ls_rfcdes-rfcoptions.
        IF sy-subrc = 0.
          lt_faobj_sys[] = ls_faobj_system-faobj[].
        ENDIF.
*--Org Elements, get the correct values for the system
        CLEAR ls_ao_sys.
        READ TABLE lt_ao_sys INTO ls_ao_sys
        WITH KEY rfcdest = ls_rfcdes-rfcoptions.

        REFRESH : lt_con_sys.
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
            if_functions  = 'X'
            i_system      = l_system
            i_application = 'SAP'
            i_vrsio       = i_vrsio
          TABLES
            it_functtran  = lt_functtran_sys
            it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options   = 1
             OTHERS                 = 2 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.

        LOOP AT lt_conflict INTO ls_conflict.
          READ TABLE lt_conflict_sys WITH TABLE KEY
            conid = ls_conflict-conid rfcdest = ls_rfcdes-rfcoptions
            TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            APPEND ls_conflict TO lt_con_sys.
          ELSE.
            DELETE lt_confdet_sys WHERE conid = ls_conflict-conid.
          ENDIF.
        ENDLOOP.
        IF ls_rfcdes-rfcdest IS INITIAL.
          LOOP AT it_roles INTO ls_roles
          WHERE rfcdest = 'LOCAL'.
            ls_role_sel-low = ls_roles-agr_name.
            APPEND ls_role_sel TO lt_role_sel.
          ENDLOOP.
          IF lt_role_sel IS INITIAL.
            CONTINUE.
          ENDIF.
        ELSE.
          LOOP AT it_roles INTO ls_roles
          WHERE rfcdest = ls_rfcdes-rfcdest.
            ls_role_sel-low = ls_roles-agr_name.
            APPEND ls_role_sel TO lt_role_sel.
          ENDLOOP.
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

        CALL FUNCTION '/PSYNG/SW_036'
          DESTINATION ls_rfcdes-rfcdest
          EXPORTING
            vrsio                 = i_vrsio
            i_cfg_set             = i_config_set
            org_check             = if_org_check
            i_local_sod           = l_local_sod
            i_advanced_role_simu  = if_adv_simu
            i_org_field           = l_org_field             "OPL645
          IMPORTING
            o_totalroles          = l_analyzed_roles
          TABLES
            it_roles              = lt_role_sel
            it_confs              = it_conid
            it_sens               = it_imp
            it_conflict           = lt_con_sys
            it_confdet            = lt_confdet_sys
            it_functtran          = lt_functtran_sys
            it_faobj              = lt_faobj_sys
            it_swsodorgm          = ls_ao_sys-swsodorgm[]
            it_tcodes             = lt_tcodes
            it_functran_no_enh    = lt_functran_no_enh
            it_advanced_role_simu = it_adv_simu
            ot_routput_sum        = lt_routput_sum
            it_faobj_org          = lt_faobj_org            "OPL645
            it_orglvl             = it_orglvl
          EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        ADD l_analyzed_roles TO e_analyzed_roles.
        CLEAR l_analyzed_roles.
        APPEND LINES OF lt_routput_sum TO gt_routput_sum.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF i_noabap = 'X'.
*--Local ABAP applications are already analysed.
    CLEAR i_abap.
    DATA : l_local_rfc TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
*--Filter Functions by system
    l_system           = l_local_rfc.
    lt_functtran_sys[] = lt_functtran[].
    lt_faobj_sys[]     = lt_faobj[].
    lt_confdet_sys[]   = lt_confdet[].
    REFRESH : lt_con_sys.
*--Variable Elements, get the correct values for the remote system
    READ TABLE lt_faobj_system INTO ls_faobj_system
    WITH KEY rfcdest = l_local_rfc.
    IF sy-subrc = 0.
      lt_faobj_sys[] = ls_faobj_system-faobj[].
    ENDIF.
*--Org Elements, get the correct values for the system
    CLEAR ls_ao_sys.
    READ TABLE lt_ao_sys INTO ls_ao_sys
    WITH KEY rfcdest = l_local_rfc.

    CALL FUNCTION '/PSYNG/SW_124'
      EXPORTING
        if_functions  = 'X'
        i_system      = l_system
        i_application = 'SAP'
        i_vrsio       = i_vrsio
      TABLES
        it_functtran  = lt_functtran_sys
        it_faobj      = lt_faobj_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options        = 1
             OTHERS                 = 2 .
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.

    LOOP AT lt_conflict INTO ls_conflict.
      READ TABLE lt_conflict_sys WITH TABLE KEY
        conid = ls_conflict-conid rfcdest = l_system
        TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND ls_conflict TO lt_con_sys.
      ELSE.
        DELETE lt_confdet_sys WHERE conid = ls_conflict-conid.
      ENDIF.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_036'
      EXPORTING
        vrsio              = i_vrsio
        org_check          = if_org_check
        i_nabap            = i_noabap
        i_abap             = i_abap
        i_local_sod        = l_local_sod
        i_org_field        = l_org_field                    "OPL645
      IMPORTING
        o_totalroles       = l_analyzed_roles
      TABLES
        it_roles           = lt_role_nabap
        it_confs           = it_conid
        it_sens            = it_imp
        it_conflict        = lt_con_sys
        it_confdet         = lt_confdet_sys
        it_functtran       = lt_functtran_sys
        it_faobj           = lt_faobj_sys
        it_swsodorgm       = lt_swsodorgm
        it_tcodes          = lt_tcodes
        it_functran_no_enh = lt_functran_no_enh
        ot_routput_sum     = lt_routput_sum
        it_appl            = lt_appl
        it_sysid           = lt_sysid
        it_faobj_org       = lt_faobj_org                  "OPL645
        it_orglvl             = it_orglvl.
    ADD l_analyzed_roles TO e_analyzed_roles.
    CLEAR l_analyzed_roles.

    APPEND LINES OF lt_routput_sum TO gt_routput_sum.
  ENDIF.

  APPEND LINES OF gt_routput_sum TO et_output.
  SORT et_output BY agr_name conid.
ENDFORM.                    " role_based_sod_analysis
*&---------------------------------------------------------------------*
*&      Form  get_rfc_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_RFC_SEL  text
*      -->P_LT_RFC  text
*----------------------------------------------------------------------*
FORM get_rfc_details
TABLES   it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
         et_rfcdes   STRUCTURE rfcdes.

  DATA : l_rfcdest        TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c.

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
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
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
*If 2 rfc destinations point to the same system-client,
*we still only output the results once.
*Any rfc destination pointing to the local system will be ignored
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
  DELETE      et_rfcdes WHERE rfcoptions = l_rfcdest.

ENDFORM.                    " get_rfc_details
*&---------------------------------------------------------------------*
*&      Form  check_input_conflicts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_CONID  text
*      -->P_LT_RETURN  text
*      <--P_LF_CONTINUE  text
*----------------------------------------------------------------------*
FORM check_input_conflicts
TABLES   it_conid  STRUCTURE /psyng/range_conid
         it_imp    STRUCTURE /psyng/sw_sel_opts_imp
         et_return STRUCTURE bapiret2
USING    i_vrsio     TYPE /psyng/sodvrsio
CHANGING ef_continue TYPE flag.

  DATA: l_count TYPE i.
  IF NOT it_conid IS INITIAL
  OR NOT it_imp   IS INITIAL.
    SELECT SINGLE COUNT( * )
      FROM /psyng/conflict
      INTO l_count
     WHERE conid IN it_conid
       AND vrsio = i_vrsio
       AND imp   IN it_imp.
    IF sy-subrc NE 0.
      log et_return 'E' 'NOCONFLICTS'
      'No conflict ID(s) match the selection' '' '' ''.
      CLEAR ef_continue.
    ENDIF.
  ENDIF.

ENDFORM.                    " check_input_conflicts
*&---------------------------------------------------------------------*
*&      Form  get_output_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_USERS  text
*      -->P_ET_USERS  text
*      -->P_ET_OUTPUTDET  text
*      -->P_LT_RETURN  text
*      -->P_ANALYSIS_RUN  text
*----------------------------------------------------------------------*
FORM get_output_details
TABLES it_users             STRUCTURE /psyng/sw_userlist
       et_users             STRUCTURE /psyng/userconcount
       et_outputdet         STRUCTURE /psyng/outputdet
       et_return            STRUCTURE bapiret2
USING  i_analysis_run       TYPE /psyng/seresid
       i_vrsio              TYPE /psyng/sodvrsio
       if_direct_assn_only  TYPE flag
       if_exclude_mitigated TYPE flag
CHANGING
       e_result_count       TYPE i.

  DATA   :
    lt_user         TYPE HASHED TABLE OF ty_users
                   WITH UNIQUE KEY aid userindex,
    lt_user_tmp     TYPE TABLE OF ty_users,
    ls_user         TYPE ty_users,
    lt_conflict     TYPE HASHED TABLE OF /psyng/swresicon
                   WITH UNIQUE KEY aid conindex,
    ls_conflict     TYPE /psyng/swresicon,
    lt_conhead      TYPE HASHED TABLE OF ty_conhead
                   WITH UNIQUE KEY conid vrsio,
    ls_conhead      TYPE ty_conhead,
    lt_usercon      TYPE TABLE OF /psyng/swrescon,
    ls_usercon      TYPE /psyng/swrescon,
    lt_confun       TYPE TABLE OF /psyng/swrescfun,
    ls_confun       TYPE /psyng/swrescfun,
    lt_function     TYPE HASHED TABLE OF /psyng/swresifun
                   WITH UNIQUE KEY aid funindex,
    ls_function     TYPE /psyng/swresifun,
    lt_usrprof      TYPE TABLE OF /psyng/swresupr,
    ls_usrprof      TYPE /psyng/swresupr,
    lt_usrprof2     TYPE TABLE OF /psyng/swresupr,
    lt_funprofile   TYPE TABLE OF /psyng/swresfpr,
    ls_funprofile   TYPE /psyng/swresfpr,
    lt_profrole     TYPE SORTED TABLE OF /psyng/swresprol
                   WITH UNIQUE KEY sys profindex,
    ls_profrole     TYPE /psyng/swresprol,
    lt_roles        TYPE SORTED TABLE OF /psyng/swresirol
                   WITH UNIQUE KEY roleindex,
    ls_roles        TYPE /psyng/swresirol,
    lt_comprole     TYPE SORTED TABLE OF /psyng/swresucom
                   WITH NON-UNIQUE KEY userindex roleindex,
    ls_comprole     TYPE /psyng/swresucom,
    l_comp_agrname  TYPE agr_name,
    lt_comp_agrname TYPE TABLE OF agr_name WITH HEADER LINE,
    lt_resusr       TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
    lf_continue     TYPE flag,
    lf_direct_role  TYPE flag,
*--Begin of Insert :  UMITTAL C1342 D67K931619 14/05/2024
    l_inst          TYPE /psyng/bapiflagx,
    l_se_vrsion     TYPE /psyng/prog_vrsio,
    lt_fprprof      TYPE TABLE OF /psyng/swresfpr,
    ls_fprprof      TYPE /psyng/swresfpr,
    l_new_se_vrs    TYPE flag.
*--End of insert : UMITTAL C1342 D67K931619 14/05/2024

  FIELD-SYMBOLS:
    <confun>          TYPE /psyng/swrescfun .
  RANGES :
    lr_userindex      FOR /psyng/swrescon-userindex,
    lr_userindex_all  FOR /psyng/swrescon-userindex,
    lr_userindex_part FOR /psyng/swrescon-userindex,
    lr_funindex       FOR /psyng/swrescfun-funindex,
    lr_profindex      FOR /psyng/swresupr-profileindex,
    lr_profindex_all  FOR /psyng/swresupr-profileindex,
    lr_profindex_part FOR /psyng/swresupr-profileindex,
    lr_sys            FOR /psyng/swresupr-sys,
    lr_uname          FOR usr02-bname.
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
**-- IF SE version is more then 4.7PS2C , use logic where
**-- user index and function index both are captured
**-- from /psyng/swresfpr table else previous logic
  CLEAR l_new_se_vrs.
  SELECT SINGLE se_version INTO l_se_vrsion
     FROM /psyng/swreshdr
     WHERE aid = i_analysis_run.
  IF l_se_vrsion > '4.7PS2C' OR
     l_se_vrsion CA 'Q' .
    l_new_se_vrs = 'X'.
  ELSE.
    CLEAR l_new_se_vrs.
  ENDIF.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
  lf_continue = 'X'.
*--Put input roles in ranges
  SORT it_users.
  DELETE ADJACENT DUPLICATES FROM it_users COMPARING ALL FIELDS.
  lr_uname-sign = 'I'. lr_uname-option = 'EQ'.
  LOOP AT it_users.
    lr_uname-low = it_users-bname.
    APPEND lr_uname.
  ENDLOOP.

*--users
  lr_userindex-sign  = 'I'. lr_userindex-option = 'EQ'.
  SELECT aid userindex bname nr_conflicts
    FROM /psyng/swresusr INTO TABLE lt_user
   WHERE aid   = i_analysis_run
     AND bname IN lr_uname.
  IF sy-subrc EQ 0.
    LOOP AT lt_user INTO ls_user.
      lr_userindex-low = ls_user-userindex.
      APPEND lr_userindex.
    ENDLOOP.
    lt_user_tmp = lt_user.
*--Validate if all input user exits in analysis result users
    SORT lt_user_tmp BY bname.
    LOOP AT it_users.
      READ TABLE lt_user_tmp WITH KEY bname = it_users-bname
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
*--One of the users doesn’t exist
        log_v et_return 'W' 'INVALIDUSER'
       'User' it_users-bname 'does not exist' it_users-bname ''.
      ENDIF.
    ENDLOOP.
    FREE lt_user_tmp.
  ELSE.
*-- No users match the selection
    log et_return 'E' 'NOUSERS'
    'No Users match the selection' '' '' ''.
    CLEAR lf_continue.
  ENDIF.

  CHECK NOT lf_continue IS INITIAL.
*-- get user conflict
  IF NOT lr_userindex[] IS INITIAL.
    lr_userindex_all[] = lr_userindex[].
    WHILE NOT lr_userindex[] IS INITIAL.
      APPEND LINES OF lr_userindex FROM 1 TO 5000
      TO lr_userindex_part.
      DELETE lr_userindex FROM 1 TO 5000.
      IF if_exclude_mitigated = 'X'.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       =  i_analysis_run    AND
                         userindex IN lr_userindex_part AND
                         mitigated = ''.
      ELSE.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       =  i_analysis_run AND
                         userindex IN lr_userindex_part.
      ENDIF.
*--Get counts of conflicts for users
      SELECT nr_conflicts  bname  FROM /psyng/swresusr
          APPENDING CORRESPONDING FIELDS OF TABLE lt_resusr
          WHERE aid = i_analysis_run AND
          userindex IN lr_userindex_part.

      REFRESH : lr_userindex_part[].
    ENDWHILE.
    LOOP AT lt_resusr.
      et_users-count = lt_resusr-nr_conflicts.
      et_users-uname = lt_resusr-bname.
      ADD et_users-count TO e_result_count.
      APPEND et_users.
    ENDLOOP.
    FREE: lt_resusr.
    lr_userindex[] = lr_userindex_all[].
  ENDIF.
  FREE : lr_userindex_part, lr_userindex_all.
  IF NOT lt_usercon IS INITIAL.
*--get conflicts
    SELECT * FROM /psyng/swresicon INTO TABLE lt_conflict
    FOR ALL ENTRIES IN lt_usercon
             WHERE aid       = i_analysis_run AND
                   conindex  = lt_usercon-conindex.
*--Get sensitivity levels for conflicts
    IF NOT lt_conflict IS INITIAL.
      SELECT conid vrsio imp
        FROM /psyng/conflict INTO TABLE lt_conhead
      FOR ALL ENTRIES IN lt_conflict
               WHERE conid     = lt_conflict-conid AND
                     vrsio     = i_vrsio.
    ENDIF.
*--User's Conflict functions
    SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
    FOR ALL ENTRIES IN lt_usercon
             WHERE aid       =  i_analysis_run AND
                   conindex  = lt_usercon-conindex.
    IF NOT lt_confun IS INITIAL.
      SELECT  * FROM /psyng/swresifun INTO TABLE lt_function
      FOR ALL ENTRIES IN lt_confun
           WHERE aid      = i_analysis_run AND
                 funindex = lt_confun-funindex.
    ENDIF.
  ENDIF.
  LOOP AT lt_confun ASSIGNING <confun>.
    lr_funindex-sign   = 'I'.
    lr_funindex-option = 'EQ'.
    lr_funindex-low    = <confun>-funindex.
    APPEND lr_funindex.
  ENDLOOP.
*--Approach with multiple selects, optimize use of indexes
*--Get all profiles user has
  IF NOT lr_userindex[] IS INITIAL.
    lr_userindex_all[] = lr_userindex[].
    WHILE NOT lr_userindex[] IS INITIAL.
      APPEND LINES OF lr_userindex FROM 1 TO 5000
      TO lr_userindex_part.
      DELETE lr_userindex FROM 1 TO 5000.
*--"Begin if insert : UMITTAL C1342 D67K931619 14/05/2024
      IF l_new_se_vrs EQ 'X'.
        SELECT * FROM  /psyng/swresfpr
          APPENDING TABLE lt_fprprof
          WHERE aid          = i_analysis_run AND
                userindex    IN lr_userindex_part.

      ELSE.
*--"End of insert: UMITTAL C1342 D67K931619 14/05/2024
        SELECT * FROM /psyng/swresupr
        APPENDING TABLE lt_usrprof
        WHERE aid          = i_analysis_run AND
              userindex    IN lr_userindex_part.
      ENDIF."Added by : UMITTAL C1342 D67K931619 14/05/2024
      REFRESH : lr_userindex_part[].
    ENDWHILE.
    lr_userindex[] = lr_userindex_all[].
  ENDIF.
  FREE : lr_userindex_part, lr_userindex_all.
*--For these profiles,
*  get the ones that relate to the functions we care about
  lr_profindex-sign   = 'I'.
  lr_profindex-option = 'EQ'.
  MOVE-CORRESPONDING lr_profindex TO lr_sys.
  LOOP AT lt_usrprof INTO ls_usrprof.
    lr_profindex-low = ls_usrprof-profileindex.
    APPEND lr_profindex.
    lr_sys-low = ls_usrprof-sys.
    APPEND lr_sys.
  ENDLOOP.
  SORT lr_profindex BY low.
  SORT lr_sys       BY low.
  DELETE ADJACENT DUPLICATES FROM lr_profindex COMPARING low.
  DELETE ADJACENT DUPLICATES FROM lr_sys       COMPARING low.

  IF NOT lr_profindex[] IS INITIAL.
    lr_profindex_all[] = lr_profindex[].
    WHILE NOT lr_profindex[] IS INITIAL.
      APPEND LINES OF lr_profindex FROM 1 TO 5000
      TO lr_profindex_part.
      DELETE lr_profindex FROM 1 TO 5000.
      SELECT * FROM /psyng/swresfpr
      APPENDING TABLE lt_funprofile
      WHERE
        aid          = i_analysis_run AND
        sys          IN lr_sys AND
        funindex     IN lr_funindex AND
        profileindex IN lr_profindex_part.
      REFRESH : lr_profindex_part[].
    ENDWHILE.
    lr_profindex[] = lr_profindex_all[].
  ENDIF.
  FREE : lr_profindex_part, lr_profindex_all.
  "UMITTAL C1342 D67K931619 14/05/2024
  IF l_new_se_vrs IS INITIAL.
    SORT lt_funprofile BY sys profileindex.
    LOOP AT lt_usrprof INTO ls_usrprof.
      READ TABLE lt_funprofile WITH KEY
        sys           = ls_usrprof-sys
        profileindex  = ls_usrprof-profileindex
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND ls_usrprof TO lt_usrprof2.
      ENDIF.
    ENDLOOP.
    lt_usrprof =   lt_usrprof2.
    FREE lt_usrprof2.
  ENDIF."UMITTAL C1342 D67K931619 14/05/2024

*BOC UMITTAL C1342 D67K931619 14/05/2024
**--Get the roles
  IF l_new_se_vrs EQ 'X'.
    IF NOT lt_fprprof[] IS INITIAL.
      SELECT * FROM /psyng/swresprol
      INTO TABLE lt_profrole
      FOR ALL ENTRIES IN lt_fprprof
      WHERE aid       = i_analysis_run AND
            sys       = lt_fprprof-sys AND
            profindex = lt_fprprof-profileindex.
      IF NOT lt_profrole[] IS INITIAL.
        SELECT * FROM /psyng/swresirol
          INTO TABLE lt_roles
          FOR ALL ENTRIES IN lt_profrole
            WHERE aid       = i_analysis_run AND
                  roleindex = lt_profrole-roleindex.
        IF NOT lt_roles[] IS INITIAL.
*  --Get any composite role through which these roles may be assigned
          IF NOT lr_userindex[] IS INITIAL.
            lr_userindex_all[] = lr_userindex[].
            WHILE NOT lr_userindex[] IS INITIAL.
              APPEND LINES OF lr_userindex FROM 1 TO 5000
              TO lr_userindex_part.
              DELETE lr_userindex FROM 1 TO 5000.
              SELECT * FROM /psyng/swresucom
              APPENDING TABLE lt_comprole
              FOR ALL ENTRIES IN lt_roles WHERE
                aid       = i_analysis_run AND
                sys       IN lr_sys AND
                userindex IN lr_userindex_part AND
                roleindex = lt_roles-roleindex.
              REFRESH : lr_userindex_part[].
            ENDWHILE.
            lr_userindex[] = lr_userindex_all[].
          ENDIF.
          FREE : lr_userindex_part, lr_userindex_all.
          IF NOT lt_comprole[] IS INITIAL.
            SELECT * FROM /psyng/swresirol
            APPENDING TABLE lt_roles
            FOR ALL ENTRIES IN lt_comprole
              WHERE aid       = i_analysis_run AND
                    roleindex = lt_comprole-compindex.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ELSE.
*EOC  UMITTAL C1342 D67K931619 14/05/2024
**--Get the roles
    IF NOT lt_usrprof IS INITIAL.

      SELECT * FROM /psyng/swresprol
      INTO TABLE lt_profrole
      FOR ALL ENTRIES IN lt_usrprof
      WHERE aid       = i_analysis_run AND
            sys       = lt_usrprof-sys AND
            profindex = lt_usrprof-profileindex.
      IF NOT lt_profrole IS INITIAL.
        SELECT * FROM /psyng/swresirol
        INTO TABLE lt_roles
        FOR ALL ENTRIES IN lt_profrole
          WHERE aid       = i_analysis_run AND
                roleindex = lt_profrole-roleindex.
        IF NOT lt_roles IS INITIAL.
*  --Get any composite role through which these roles may be assigned
          IF NOT lr_userindex[] IS INITIAL.
            lr_userindex_all[] = lr_userindex[].
            WHILE NOT lr_userindex[] IS INITIAL.
              APPEND LINES OF lr_userindex FROM 1 TO 5000
              TO lr_userindex_part.
              DELETE lr_userindex FROM 1 TO 5000.
              SELECT * FROM /psyng/swresucom
              APPENDING TABLE lt_comprole
              FOR ALL ENTRIES IN lt_roles WHERE
                aid       = i_analysis_run AND
                sys       IN lr_sys AND
                userindex IN lr_userindex_part AND
                roleindex = lt_roles-roleindex.
              REFRESH : lr_userindex_part[].
            ENDWHILE.
            lr_userindex[] = lr_userindex_all[].
          ENDIF.
          FREE : lr_userindex_part, lr_userindex_all.
          IF NOT lt_comprole IS INITIAL.
            SELECT * FROM /psyng/swresirol
            APPENDING TABLE lt_roles
            FOR ALL ENTRIES IN lt_comprole
              WHERE aid       = i_analysis_run AND
                    roleindex = lt_comprole-compindex.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF."++UMITTAL C1342 D67K931619 14/05/2024

  "++UMITTAL C1342 D67K931619 14/05/2024
  IF l_new_se_vrs EQ 'X'.

    SORT: lt_usercon    BY userindex conindex,
          lt_confun     BY conindex funindex,
          lt_usrprof    BY sys userindex profileindex,
          lt_funprofile BY sys profileindex.

    CLEAR : ls_confun,ls_fprprof,ls_usercon.
    LOOP AT lt_confun INTO ls_confun.
      CLEAR et_outputdet.
      LOOP AT lt_fprprof INTO ls_fprprof WHERE funindex =
      ls_confun-funindex.
        LOOP AT lt_usercon INTO ls_usercon
              WHERE userindex = ls_fprprof-userindex AND
                    conindex  = ls_confun-conindex.
*     userid
          READ TABLE lt_user INTO ls_user
          WITH TABLE KEY aid       = i_analysis_run
                         userindex = ls_usercon-userindex.
          IF sy-subrc = 0.
            et_outputdet-uname = ls_user-bname.
          ENDIF.
*     Conflicts
          READ TABLE lt_conflict INTO ls_conflict
          WITH TABLE KEY aid       = i_analysis_run
                         conindex  = ls_confun-conindex.
          IF sy-subrc = 0.
            et_outputdet-conid = ls_conflict-conid.
*     Get sensitivity level
            READ TABLE lt_conhead INTO ls_conhead
            WITH TABLE KEY conid = ls_conflict-conid
                           vrsio = i_vrsio.
            IF sy-subrc = 0.
              et_outputdet-imp = ls_conhead-imp.
            ENDIF.
          ENDIF.
*     function
          READ TABLE lt_function INTO ls_function
          WITH TABLE KEY aid      = i_analysis_run
                         funindex = ls_confun-funindex.
          IF sy-subrc = 0.
            et_outputdet-functionid = ls_function-funid.
          ENDIF.
*     Role
          READ TABLE lt_profrole INTO ls_profrole
            WITH KEY sys       = ls_fprprof-sys
                     profindex = ls_fprprof-profileindex
          BINARY SEARCH.
          IF sy-subrc = 0.
            READ TABLE lt_roles INTO ls_roles
              WITH KEY roleindex = ls_profrole-roleindex
              BINARY SEARCH.
            IF sy-subrc EQ 0.
              et_outputdet-agr_name = ls_roles-agr_name.
            ENDIF.
*     Composite Role
            READ TABLE lt_comprole
              WITH TABLE KEY userindex = ls_usercon-userindex
                             roleindex = ls_profrole-roleindex
                             TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              LOOP AT lt_comprole INTO ls_comprole FROM sy-tabix.
                IF ls_comprole-userindex <> ls_usercon-userindex OR
                   ls_comprole-roleindex <> ls_profrole-roleindex.
                  EXIT.
                ENDIF.
                READ TABLE lt_roles INTO ls_roles
                    WITH KEY roleindex  = ls_comprole-compindex
                    BINARY SEARCH.
                IF sy-subrc = 0.
                  l_comp_agrname = ls_roles-agr_name.
                  COLLECT l_comp_agrname INTO lt_comp_agrname.
                ENDIF.
              ENDLOOP.
              IF if_direct_assn_only = 'X'.
                READ TABLE lt_comprole INTO ls_comprole
                  WITH KEY userindex = ls_usercon-userindex
                          roleindex  = ls_profrole-roleindex
                          compindex  = 0.
                IF sy-subrc = 0.
                  lf_direct_role = 'X'.
                ELSE.
                  CLEAR lf_direct_role.
                ENDIF.
              ENDIF.
            ELSE.
              CLEAR l_comp_agrname.
              REFRESH : lt_comp_agrname.
              lf_direct_role = 'X'.
            ENDIF.
          ELSE.
            CLEAR l_comp_agrname.
            REFRESH : lt_comp_agrname.
          ENDIF.
          IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X'.
            APPEND et_outputdet.
          ENDIF.
          IF NOT lt_comp_agrname[] IS INITIAL.
            LOOP AT lt_comp_agrname.
              et_outputdet-agr_name = lt_comp_agrname.
              APPEND et_outputdet.
            ENDLOOP.
            REFRESH : lt_comp_agrname.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

  ELSE.
    "++UMITTAL C1342 D67K931619 14/05/2024
    SORT:
          lt_usercon    BY conindex,
          lt_confun     BY conindex funindex,
          lt_usrprof    BY sys userindex profileindex,
          lt_funprofile BY funindex.

    LOOP AT lt_confun INTO ls_confun.
      CLEAR et_outputdet.
      LOOP AT lt_funprofile INTO ls_funprofile
        WHERE funindex = ls_confun-funindex.
        LOOP AT lt_usercon INTO ls_usercon
          WHERE conindex = ls_confun-conindex.
          READ TABLE lt_usrprof INTO ls_usrprof
          WITH KEY
            sys          = ls_funprofile-sys
            userindex    = ls_usercon-userindex
            profileindex = ls_funprofile-profileindex
            BINARY SEARCH.
          CHECK sy-subrc = 0.
*   userid
          READ TABLE lt_user INTO ls_user
          WITH TABLE KEY aid       = i_analysis_run
                         userindex = ls_usercon-userindex.
          IF sy-subrc = 0.
            et_outputdet-uname = ls_user-bname.
          ENDIF.
*   Conflicts
          READ TABLE lt_conflict INTO ls_conflict
          WITH TABLE KEY aid       = i_analysis_run
                         conindex = ls_confun-conindex.
          IF sy-subrc = 0.
            et_outputdet-conid = ls_conflict-conid.
*   Get sensitivity level
            READ TABLE lt_conhead INTO ls_conhead
            WITH TABLE KEY conid = ls_conflict-conid
                           vrsio = i_vrsio.
            IF sy-subrc = 0.
              et_outputdet-imp = ls_conhead-imp.
            ENDIF.
          ENDIF.
*   function
          READ TABLE lt_function INTO ls_function
          WITH TABLE KEY aid      = i_analysis_run
                         funindex = ls_confun-funindex.
          IF sy-subrc = 0.
            et_outputdet-functionid = ls_function-funid.
          ENDIF.
*   Role
          READ TABLE lt_profrole INTO ls_profrole
            WITH KEY sys       = ls_usrprof-sys
                     profindex = ls_usrprof-profileindex
          BINARY SEARCH.
          IF sy-subrc = 0.
            READ TABLE lt_roles INTO ls_roles
            WITH KEY roleindex = ls_profrole-roleindex
            BINARY SEARCH.
            IF sy-subrc EQ 0.
              et_outputdet-agr_name = ls_roles-agr_name.
            ENDIF.
*   Composite Role
            READ TABLE lt_comprole ".INTO ls_comprole
            WITH TABLE KEY userindex = ls_usercon-userindex
                     roleindex = ls_profrole-roleindex
                     TRANSPORTING NO FIELDS.
            IF sy-subrc = 0.
              LOOP AT lt_comprole INTO ls_comprole FROM sy-tabix.
                IF ls_comprole-userindex <> ls_usercon-userindex OR
                   ls_comprole-roleindex <> ls_profrole-roleindex.
                  EXIT.
                ENDIF.
                READ TABLE lt_roles INTO ls_roles
                WITH KEY roleindex  = ls_comprole-compindex
                BINARY SEARCH.
                IF sy-subrc = 0.
                  l_comp_agrname = ls_roles-agr_name.
                  COLLECT l_comp_agrname INTO lt_comp_agrname.
                ENDIF.
              ENDLOOP.
              IF if_direct_assn_only = 'X'.
                READ TABLE lt_comprole INTO ls_comprole
                  WITH KEY userindex = ls_usercon-userindex
                          roleindex  = ls_profrole-roleindex
                          compindex  = 0.
                IF sy-subrc = 0.
                  lf_direct_role = 'X'.
                ELSE.
                  CLEAR lf_direct_role.
*                    refresh : lt_comp_agrname.
                ENDIF.
              ENDIF.
            ELSE.
              CLEAR l_comp_agrname.
              REFRESH : lt_comp_agrname.
              lf_direct_role = 'X'.
            ENDIF.
          ELSE.
            CLEAR l_comp_agrname.
            REFRESH : lt_comp_agrname.
          ENDIF.
          IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X'.
            APPEND et_outputdet.
          ENDIF.
          IF NOT lt_comp_agrname[] IS INITIAL.
            LOOP AT lt_comp_agrname.
              et_outputdet-agr_name = lt_comp_agrname.
              APPEND et_outputdet.
            ENDLOOP.
            REFRESH : lt_comp_agrname.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDIF."++UMITTAL C1342 D67K931619 14/05/2024
  SORT et_outputdet.
  DELETE ADJACENT DUPLICATES FROM et_outputdet COMPARING ALL FIELDS.



ENDFORM.                    " get_output_details
*&---------------------------------------------------------------------*
*&      Form  create_logging_entry
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_START_DATE  text
*      -->P_L_START_TIME  text
*      -->P_L_API  text
*      -->P_L_RESULTS  text
*      -->P_L_USER  text
*----------------------------------------------------------------------*
FORM create_logging_entry
USING i_start_date TYPE dats
      i_start_time TYPE tims
      i_request_id TYPE /psyng/request_id
      i_batch_id   TYPE /psyng/batch_id
      i_api        TYPE rs38l_fnam
      i_results    TYPE int4
      i_return     TYPE bapireturn
      i_object     TYPE /psyng/longtext
      i_timestamp  TYPE timestampl.

  DATA: l_runtime TYPE /psyng/dec11.
* BOC by RGUPTA on 07.04.22 for C0700
  DATA: l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 07.04.22 for C0700
  GET RUN TIME FIELD g_stop.
  l_runtime = ( g_stop - g_start ) / 1000.

*--Call logging FM
  CALL FUNCTION '/PSYNG/BASIS_CREATE_LOGGING' IN UPDATE TASK
    EXPORTING
      i_date        = i_start_date
      i_time        = i_start_time
      i_request_id  = i_request_id
      i_batch_id    = i_batch_id
      i_api         = i_api
      i_bname       = l_current_user "C0700
      i_results     = i_results
      i_return_code = i_return-code
      i_return_type = i_return-type
      i_message     = i_return-message
      i_runtime     = l_runtime
      i_object      = i_object
      i_timestamp   = i_timestamp.
ENDFORM.                    " create_logging_entry



*---------------------------------------------------------------------*
*       FORM configset_api_validate_input                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_RETURN                                                     *
*  -->  IF_DEF_VRSIO                                                  *
*  -->  IF_DEF_CONF                                                   *
*  -->  VRSIO                                                         *
*  -->  CONFIG_SET                                                    *
*  -->  ES_CONFIG_SET                                                 *
*  -->  ES_SOD_MATRIX                                                 *
*  -->  EF_CONTINUE                                                   *
*---------------------------------------------------------------------*
FORM configset_api_validate_input
TABLES   et_return     STRUCTURE bapiret2
         it_systems    STRUCTURE /psyng/swcfgsys
USING    if_def_vrsio  TYPE flag
         if_def_conf   TYPE flag
         if_local      TYPE flag
CHANGING vrsio         TYPE /psyng/sodvrsio
         config_set    TYPE /psyng/seconfid
         es_config_set TYPE /psyng/swcfgset
         es_sod_matrix TYPE /psyng/swsodvers
         ef_continue   TYPE flag
.

  DATA : l_dflt_vrsio       TYPE /psyng/param,
         lf_cfg_set_enabled TYPE flag,
         lt_rfcdest         TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
         WITH HEADER LINE,
         lt_dest            TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER
         LINE.

  IF NOT it_systems[] IS INITIAL.
*--Load RFC Destinations for requested systems
    SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_dest FOR ALL ENTRIES IN
    it_systems WHERE
      systid = it_systems-sysid.
    lt_rfcdest-sign   = 'I'.
    lt_rfcdest-option = 'EQ'.
    LOOP AT lt_dest.
      IF NOT lt_dest-rfcdest IS INITIAL OR if_local IS INITIAL.
        "local system is handled by parameter
        "if_local if it's set,
        "otherwise allow it
        lt_rfcdest-low = lt_dest-rfcdest.
        APPEND lt_rfcdest.
      ENDIF.
    ENDLOOP.
  ENDIF.


  IF if_def_vrsio = 'X'.
*--Use default global version
    se_config_param 'DFLT_GLOBAL_VERSION' l_dflt_vrsio.
    IF NOT l_dflt_vrsio IS INITIAL.
      log_v et_return 'I' 'DEFAULT_VERSION'
        'SOD Matrix version used :' 'DFLT_GLOBAL_VERSION'
        l_dflt_vrsio l_dflt_vrsio ''.
      vrsio = l_dflt_vrsio.
    ELSE.
      log et_return 'E' 'NO_DEFAULT_VERSION'
        'No Default SOD Matrix defined in ' 'DFLT_GLOBAL_VERSION' '' ''.
      CLEAR ef_continue.
    ENDIF.
  ELSE.
  ENDIF.
  CHECK ef_continue = 'X'.
*--return info on SOD Matrix
  SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
  WHERE vrsio = vrsio.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled = 'X'.
    log et_return 'I' 'CFG_SET_ENABLED'
       'Configuration Set functionality enabled'
       'CFG_SET_ENABLED = X' '' ''.

    IF if_def_conf = 'X'.
*  --Use default Configuration Set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio         = 'X'
          i_cfgvrsio      = vrsio
          if_local_system = if_local
        IMPORTING
          e_config_set = es_config_set-setid
          ef_success   = ef_continue
        TABLES
          it_rfcdest   = lt_rfcdest
          et_return    = et_return.
      IF ef_continue = 'X'.
        config_set = es_config_set-setid.
      ENDIF.
    ENDIF.
*  --Validate Configuration Set
    IF ef_continue = 'X'.
      SELECT SINGLE *  INTO es_config_set FROM /psyng/swcfgset
       WHERE setid  = config_set.
      IF sy-subrc <> 0.
        log_v et_return 'E' 'INVALIDCONFSET'
          'Configuration Set Does not exist.' config_set ''
          config_set ''.
        CLEAR ef_continue.
      ENDIF.
*--Get version corresponding to config set
      SELECT SINGLE * INTO es_sod_matrix FROM /psyng/swsodvers
      WHERE vrsio = es_config_set-sodvrsio.
      IF sy-subrc <> 0.
        log et_return 'E' 'INVALIDVERSION'
        'SOD Matrix version is invalid ' vrsio '.' ''.
        CLEAR ef_continue.
      ENDIF.

    ENDIF.
  ELSE.
    log et_return 'I' 'CFG_SET_DISABLED'
      'Configuration Set functionality Disabled'
      'CFG_SET_ENABLED <> X' '' ''.
  ENDIF.

ENDFORM.                    " api_validate_input
*&---------------------------------------------------------------------*
*&      Form  GENERAL_INFO_LOAD_ALL_SYS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_SET_SYSTEMS  text
*      -->P_IT_SYSTEMS  text
*      -->P_IF_LOCAL  text
*----------------------------------------------------------------------*
FORM general_info_load_all_sys
  TABLES
    et_res_systems STRUCTURE /psyng/swresisys
    et_res_hdr     STRUCTURE /psyng/swreshdr
    it_systems     STRUCTURE /psyng/swcfgsys
  USING
    if_local       TYPE flag.


*--Get all analysis runs for the specified set of systems
*  for all versions, all config sets
  DATA : lt_ana_all     TYPE SORTED TABLE OF /psyng/swreshdr WITH HEADER
  LINE
                        WITH UNIQUE KEY aid,
         lt_ana_all_sys TYPE SORTED TABLE OF /psyng/swresisys WITH
         HEADER LINE
                        WITH UNIQUE KEY aid sysid,
         lt_sys_input   TYPE SORTED TABLE OF /psyng/swresisys WITH
         HEADER LINE
                        WITH UNIQUE KEY sysid,
         lt_sys_ana     TYPE SORTED TABLE OF /psyng/swresisys WITH
         HEADER LINE
                        WITH UNIQUE KEY sysid,
         l_exact_match  TYPE /psyng/param_value,
         lf_missing_sys TYPE flag.

*--Determine if an exact match on systems should be considered
  se_config_param  'CFG_SET_EXACT_MATCH' l_exact_match.

  IF if_local = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO it_systems-sysid .
    APPEND it_systems.
  ENDIF.
  IF NOT it_systems[] IS INITIAL.
    SORT it_systems.
    DELETE ADJACENT DUPLICATES FROM it_systems.
    SELECT * FROM /psyng/swresisys INTO TABLE lt_ana_all_sys
      FOR ALL ENTRIES IN it_systems WHERE
        sysid = it_systems-sysid.                       "#EC CI_NOFIRST
  ELSE.
*--No systems provided, all runs in scope
    SELECT * FROM /psyng/swresisys
        INTO TABLE lt_ana_all_sys.                      "#EC CI_NOWHERE
  ENDIF.
  IF NOT lt_ana_all_sys[] IS INITIAL.
    LOOP AT it_systems.
      lt_sys_input-sysid = it_systems-sysid.
      INSERT TABLE lt_sys_input.
    ENDLOOP.
    SELECT * FROM /psyng/swreshdr INTO TABLE lt_ana_all FOR ALL
    ENTRIES IN lt_ana_all_sys
      WHERE aid = lt_ana_all_sys-aid.
*--now get all systems for these analysis
    IF NOT lt_ana_all[] IS INITIAL.
      SELECT * FROM /psyng/swresisys INTO TABLE lt_ana_all_sys
        FOR ALL ENTRIES IN lt_ana_all WHERE
          aid = lt_ana_all-aid.
    ENDIF.
    LOOP AT lt_ana_all.
      REFRESH : lt_sys_ana.
      CLEAR lf_missing_sys.
      LOOP AT lt_ana_all_sys WHERE aid = lt_ana_all-aid.
        lt_sys_ana-sysid = lt_ana_all_sys-sysid.
        INSERT TABLE lt_sys_ana.
      ENDLOOP.
      IF lt_sys_ana[] = lt_sys_input[].
*--The analysis is for the exact set of systems requested
        APPEND lt_ana_all TO et_res_hdr.
      ELSE.
        IF l_exact_match <> 'Y'.
          LOOP AT lt_sys_input.
            READ TABLE lt_sys_ana WITH TABLE KEY sysid =
            lt_sys_input-sysid.
            IF sy-subrc <> 0.
*--This system wasn't in the analysis
              lf_missing_sys = 'X'.
            ENDIF.
          ENDLOOP.
        ELSE.
*--The analysis doesn't match set of systems analyzed
          lf_missing_sys = 'X'.
        ENDIF.
        IF lf_missing_sys IS INITIAL.
          APPEND lt_ana_all TO et_res_hdr.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDIF.
  IF NOT et_res_hdr[] IS INITIAL.
*--Return all systems foir matching analysis
    SELECT * FROM /psyng/swresisys INTO TABLE et_res_systems
      FOR ALL ENTRIES IN et_res_hdr WHERE
        aid = et_res_hdr-aid.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GENERAL_ROLE_INFO_LOAD_ALL_SYS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_RES_SYSTEMS  text
*      -->P_ET_RESHDR  text
*      -->P_IT_SYSTEMS  text
*      -->P_IF_LOCAL  text
*----------------------------------------------------------------------*
FORM general_role_info_load_all_sys
  TABLES
    et_rrs_hdr     STRUCTURE /psyng/swrrshdr
    it_systems     STRUCTURE /psyng/swcfgsys
  USING
    if_local       TYPE flag.


*--Get all analysis runs for the specified set of systems
*  for all versions, all config sets
  DATA :lt_ana_role_all     TYPE SORTED TABLE OF /psyng/swrrshdr
        WITH HEADER LINE WITH UNIQUE KEY aid.

  IF if_local = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO it_systems-sysid .
    APPEND it_systems.
  ENDIF.

  IF NOT it_systems[] IS INITIAL.
    SELECT * FROM /psyng/swrrshdr
      INTO TABLE lt_ana_role_all
      FOR ALL ENTRIES IN it_systems
      WHERE sysid = it_systems-sysid.
  ELSE.
    SELECT * FROM /psyng/swrrshdr
      INTO TABLE lt_ana_role_all
      WHERE aid <> space.
  ENDIF.

*  APPEND LINES OF lt_ana_role_all TO et_rrs_hdr.
  et_rrs_hdr[] = lt_ana_role_all[].

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_OUTPUTDET1  text
*----------------------------------------------------------------------*
FORM get_output  TABLES it_users STRUCTURE /psyng/sw_userlist
                        et_users STRUCTURE /psyng/userconcount
                        lt_output STRUCTURE /psyng/sw_outputdet
                        et_return  STRUCTURE bapiret2

                 USING i_analysis_run TYPE /psyng/seresid
                       if_exclude_mitigated TYPE flag
                       if_direct_assn_only  TYPE flag
                 CHANGING e_result_count       TYPE i.

  DATA:
*BEGIN OF gt_output_alv OCCURS 0,
**        aid      TYPE /psyng/swreshdr-aid,
*          bname     TYPE /psyng/swreshdr-bname,
*          conid     TYPE /psyng/conflict-conid,
*          confnum   TYPE /psyng/nr_conflicts,
*          mitinum   TYPE /psyng/nr_conflicts,
*          mitigated TYPE flag,
*          funid     TYPE /psyng/faobj2-funid,
*          comp_agr  TYPE agr_define-agr_name,
*          agr_name  TYPE agr_define-agr_name,
*          profname  TYPE agr_prof-profile,
*          sysid     TYPE /psyng/sw_rfcdes-systid,
*          tcode     TYPE /psyng/faobj2-tcode,
*          auth      TYPE /psyng/seres_authdetail-auth,
*          object    TYPE /psyng/faobj2-object,
*          field     TYPE /psyng/faobj2-field,
*          von       TYPE /psyng/seres_authdetail-von,
*          bis       TYPE /psyng/seres_authdetail-bis,
*          abb       TYPE /psyng/seres_authdetail-abb,
*          origin    TYPE c LENGTH 12, "B16609 for C0633
**BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
*          class     TYPE xuclass,
**EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
*          deprtmnt  TYPE /psyng/swresusr-department,
*                                            "HBHALLA(PN-15675)(
*08/10/25)
*       END OF gt_output_alv,
       g_alv_count    LIKE sy-tabix,
       g_current_user TYPE sy-uname. "C0700

  DATA: l_new_se_vrs TYPE flag,
        l_se_vrsion TYPE /psyng/prog_vrsio,
        lf_continue TYPE flag,
        lt_user_tmp     TYPE TABLE OF ty_users,
        lt_user         TYPE HASHED TABLE OF ty_users
                   WITH UNIQUE KEY aid userindex WITH HEADER LINE,
        ls_user         TYPE ty_users,
        lt_usercon      TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
        ls_usercon      TYPE /psyng/swrescon,
        lt_resusr       TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
        lt_confun        TYPE TABLE OF /psyng/swrescfun WITH HEADER
LINE,
       lt_function      TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
       lt_fprprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
       lt_usrprof       TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
       ls_usrprof      TYPE /psyng/swresupr,
       lt_funprofile   TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
       ls_funprofile   TYPE /psyng/swresfpr,
       lt_profiles      TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
       lt_profrole      TYPE SORTED TABLE OF /psyng/swresprol
                         WITH HEADER LINE WITH UNIQUE KEY profindex,
       lt_roles         TYPE SORTED TABLE OF /psyng/swresirol
                         WITH HEADER LINE WITH UNIQUE KEY roleindex,
               lt_comprole      TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        lt_comprole_part TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        lt_users_alv     TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
gt_conflict   TYPE TABLE OF /psyng/swresicon WITH HEADER LINE,
lv_comp_agr  TYPE agr_define-agr_name,
lv_tabix       TYPE sy-tabix,
lt_authdet       TYPE TABLE OF /psyng/seres_authdetail
                        WITH HEADER LINE,
ls_authdet     TYPE /psyng/seres_authdetail,
ls_output_alv LIKE LINE OF lt_output,
lt_funprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
lt_usrprof2      TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
lt_authdet_all   TYPE TABLE OF /psyng/seres_authdetail
                    WITH HEADER LINE,
lt_conflict     TYPE HASHED TABLE OF /psyng/swresicon
                   WITH UNIQUE KEY aid conindex WITH HEADER LINE,
    ls_conflict     TYPE /psyng/swresicon,
    lf_direct_role  TYPE flag,
    lf_profauth TYPE flag,
    lt_system     TYPE SORTED TABLE OF /psyng/swresisys
                    WITH HEADER LINE
                    WITH UNIQUE KEY sysindex,
    lt_sysinfo    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
    loc_system TYPE rfcdest,
    lt_bname TYPE TABLE OF /psyng/sw_sel_opts_xubname,
    ls_bname TYPE /psyng/sw_sel_opts_xubname,
    lt_rem_users         TYPE TABLE OF usr02,
    lt_lcl_users         TYPE TABLE OF usr02,
    ls_usr02             TYPE usr02,
    lt_user1             TYPE TABLE OF usr02,
    l_tabix  TYPE sy-tabix.

  FIELD-SYMBOLS: <swresusr> TYPE /psyng/swresusr,
                   <confun>   TYPE /psyng/swrescfun.

  RANGES: lr_uname FOR usr02-bname,
          lr_userindex FOR /psyng/swrescon-userindex,
          lr_userindex_part FOR /psyng/swrescon-userindex,
          lr_userindex_all FOR /psyng/swrescon-userindex,
          lr_funindex  FOR /psyng/swrescfun-funindex,
          lr_profindex FOR /psyng/swresupr-profileindex,
          lr_profindex_all  FOR /psyng/swresupr-profileindex,
          lr_profindex_part FOR /psyng/swresupr-profileindex,
          lr_sys            FOR /psyng/swresupr-sys.

*-----------------------------------------------------------------------
*--------------------SE4.7PS2C VERSION CHECK----------------------------
*-----------------------------------------------------------------------
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
  CLEAR l_new_se_vrs.
  SELECT SINGLE se_version INTO l_se_vrsion
    FROM /psyng/swreshdr
    WHERE aid = i_analysis_run.
  IF l_se_vrsion > '4.7PS2C' OR
     l_se_vrsion CA 'Q' .

    l_new_se_vrs = 'X'.
  ELSE.
    CLEAR l_new_se_vrs.
  ENDIF.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024

  lf_continue = 'X'.

*-----------------------------------------------------------------------
*--------------------GET USERS STORED IN RUN ID-------------------------
*-----------------------------------------------------------------------
*--Take API input users in range
  SORT it_users.
  DELETE ADJACENT DUPLICATES FROM it_users COMPARING ALL FIELDS.
  lr_uname-sign = 'I'. lr_uname-option = 'EQ'.
  LOOP AT it_users.
    lr_uname-low = it_users-bname.
    APPEND lr_uname.
  ENDLOOP.

  lr_userindex-sign = 'I'. lr_userindex-option = 'EQ'.
  SELECT aid
         userindex
         bname
         nr_conflicts
         department
         class
         nr_mitigated
         FROM /psyng/swresusr INTO TABLE lt_user
         WHERE aid = i_analysis_run AND
               bname IN lr_uname. "Performance improvement point
  IF sy-subrc = 0.

*--User existance check in system

    SELECT * FROM /psyng/swresisys INTO TABLE lt_system
      WHERE aid  = i_analysis_run.
    IF NOT lt_system[] IS INITIAL.
      SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sysinfo
      FOR ALL ENTRIES IN
        lt_system WHERE systid = lt_system-sysid.
    ENDIF.

    CONCATENATE sy-sysid sy-mandt INTO loc_system.

    ls_bname-sign = 'I'.
    ls_bname-option = 'EQ'.
    LOOP AT it_users.
      ls_bname-low = it_users-bname.
      APPEND ls_bname TO lt_bname.
    ENDLOOP.
    CLEAR it_users.

    LOOP AT lt_sysinfo.
      IF lt_sysinfo-systid <> loc_system.
*BOC:HBHALLA (29/11/24) PN-7118 - SE VF Scan changes
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
*EOC:HBHALLA (29/11/24) PN-7118 - SE VF Scan changes
        CALL FUNCTION '/PSYNG/SW_041'
          DESTINATION lt_sysinfo-rfcdest
*In future if these parameters will be included in API interface that
*uncomment these parameters.
          EXPORTING
*            i_validuser       = validusr
            i_include_locked  = 'X'
            i_include_expired = 'X'
          TABLES
            et_users          = lt_rem_users
            it_userlist       = lt_bname
*            it_grouplist      = s_class
*            it_usertype       = lr_usertype
*            it_actgroups      = s_actgroups
*            it_profile        = s_profile
*            it_costcenter     = s_kostl
          EXCEPTIONS
               communication_failure = 1
               system_failure        = 2
              OTHERS                = 3.         "#EC SAST_CI_GEN_CHECK
* <-- PN-7118 - SE VF Scan changes - HBHALLA - 2024-11-29
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before code compiler
*   is not picking it up
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.
        LOOP AT lt_rem_users INTO ls_usr02.
          APPEND ls_usr02 TO lt_user1.
          CLEAR ls_usr02.
        ENDLOOP.
      ELSE.
        CALL FUNCTION '/PSYNG/SW_041'
          EXPORTING
*            i_validuser       = validusr
            i_include_locked  = 'X'
            i_include_expired = 'X'
          TABLES
            et_users          = lt_lcl_users
                it_userlist       = lt_bname.
*                it_grouplist      = s_class
*                it_usertype       = lr_usertype
*            it_actgroups      = s_actgroups
*            it_profile        = s_profile
*                it_costcenter     = s_kostl.
        LOOP AT lt_lcl_users INTO ls_usr02.
          APPEND ls_usr02 TO lt_user1.
          CLEAR ls_usr02.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

    FREE: lt_rem_users, lt_lcl_users.

    SORT lt_user1.
    DELETE ADJACENT DUPLICATES FROM lt_user1 COMPARING ALL FIELDS.

    LOOP AT lt_user INTO ls_user.
      l_tabix = sy-tabix.
      READ TABLE lt_user1 WITH KEY bname = ls_user-bname BINARY SEARCH
            TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE lt_user WHERE bname = ls_user-bname.
      ENDIF.
    ENDLOOP.



    LOOP AT lt_user INTO ls_user.
      lr_userindex-low = ls_user-userindex.
      APPEND lr_userindex.
    ENDLOOP.
    lt_user_tmp = lt_user[].
*--Validate if all API input users exist in stored analysis results
    SORT lt_user_tmp BY bname.
    LOOP AT it_users.
      READ TABLE lt_user_tmp WITH KEY bname = it_users-bname
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc NE 0.
*--One of the users doesn’t exist
        log_v et_return 'W' 'INVALIDUSER'
       'User' it_users-bname 'does not exist' it_users-bname ''.
      ENDIF.
    ENDLOOP.
    FREE lt_user_tmp.
  ELSE.
*-- No users match the selection
    log et_return 'E' 'NOUSERS'
    'No Users match the selection' '' '' ''.
    CLEAR lf_continue.
  ENDIF.

  CHECK NOT lf_continue IS INITIAL.
*-----------------------------------------------------------------------
*---------------GET USERS'S CONFLICT STORED IN RUN ID-------------------
*-----------------------------------------------------------------------
  IF NOT lr_userindex[] IS INITIAL.
    lr_userindex_all[] = lr_userindex[].
    WHILE NOT lr_userindex[] IS INITIAL.
      APPEND LINES OF lr_userindex FROM 1 TO 5000 TO lr_userindex_part.
      DELETE lr_userindex FROM 1 TO 5000.
      IF if_exclude_mitigated = 'X'.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       =  i_analysis_run    AND
                         userindex IN lr_userindex_part AND
                         mitigated = ''.
      ELSE.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
            WHERE aid       =  i_analysis_run AND
                  userindex IN lr_userindex_part.
      ENDIF.
*--Get counts of conflicts for users
      SELECT nr_conflicts  bname  FROM /psyng/swresusr
          APPENDING CORRESPONDING FIELDS OF TABLE lt_resusr
          WHERE aid = i_analysis_run AND
          userindex IN lr_userindex_part.

      REFRESH : lr_userindex_part[].
    ENDWHILE.
    LOOP AT lt_resusr.
      et_users-count = lt_resusr-nr_conflicts.
      et_users-uname = lt_resusr-bname.
      ADD et_users-count TO e_result_count.
      APPEND et_users.
    ENDLOOP.
    FREE: lt_resusr.
    lr_userindex[] = lr_userindex_all[].
  ENDIF.
  FREE : lr_userindex_part, lr_userindex_all.

*-----------------------------------------------------------------------
*-----------GET USER'S CONFLICT FUNCTIONS STORED IN RUN ID--------------
*-----------------------------------------------------------------------
  IF NOT lt_usercon[] IS INITIAL.

    SELECT * FROM /psyng/swresicon INTO TABLE lt_conflict
    FOR ALL ENTRIES IN lt_usercon
             WHERE aid       = i_analysis_run AND
                   conindex  = lt_usercon-conindex.

    SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
    FOR ALL ENTRIES IN lt_usercon
             WHERE aid       =  i_analysis_run AND
                   conindex  = lt_usercon-conindex.
    IF NOT lt_confun[] IS INITIAL.
      SELECT  * FROM /psyng/swresifun INTO TABLE lt_function
      FOR ALL ENTRIES IN lt_confun
           WHERE aid      = i_analysis_run AND
                 funindex = lt_confun-funindex.
    ENDIF.
  ENDIF.
  LOOP AT lt_confun ASSIGNING <confun>.
    lr_funindex-sign = 'I'.
    lr_funindex-option = 'EQ'.
    lr_funindex-low = <confun>-funindex.
    APPEND lr_funindex.
  ENDLOOP.

*-----------------------------------------------------------------------
*-----------------------GET USER PROFILES-------------------------------
*-----------------------------------------------------------------------
*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
*BOC:HBHALLA (PN-14658)(Issue-3)(08/08/25)
*Dump while exporting to ALV due to user index in ranges
  IF l_new_se_vrs EQ 'X'.
    IF lr_userindex[] IS NOT INITIAL.
      SELECT * FROM /psyng/swresfpr
          INTO TABLE lt_fprprof
          FOR ALL ENTRIES IN lr_userindex
              WHERE aid    = i_analysis_run AND
*                    userindex    IN lr_userindex.
                    userindex = lr_userindex-low.
    ENDIF.
  ELSE.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
    IF lr_userindex[] IS NOT INITIAL.
      SELECT * FROM /psyng/swresupr
      INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
          FOR ALL ENTRIES IN lr_userindex
      WHERE aid          = i_analysis_run AND
*            userindex    IN lr_userindex.
                    userindex = lr_userindex-low.
    ENDIF.
  ENDIF. "Added by: UMITTAL C1342 D67K931619 14/05/2024
*EOC:HBHALLA (PN-14658)(Issue-3)(08/08/25)

*--For these profiles,
*  get the ones that relate to the functions we care about
  lr_profindex-sign   = 'I'.
  lr_profindex-option = 'EQ'.
  MOVE-CORRESPONDING lr_profindex TO lr_sys.
  LOOP AT lt_usrprof INTO ls_usrprof.
    lr_profindex-low = ls_usrprof-profileindex.
    APPEND lr_profindex.
    lr_sys-low = ls_usrprof-sys.
    APPEND lr_sys.
  ENDLOOP.
  SORT lr_profindex BY low.
  SORT lr_sys       BY low.
  DELETE ADJACENT DUPLICATES FROM lr_profindex COMPARING low.
  DELETE ADJACENT DUPLICATES FROM lr_sys       COMPARING low.

  IF NOT lr_profindex[] IS INITIAL.
    lr_profindex_all[] = lr_profindex[].
    WHILE NOT lr_profindex[] IS INITIAL.
      APPEND LINES OF lr_profindex FROM 1 TO 5000
      TO lr_profindex_part.
      DELETE lr_profindex FROM 1 TO 5000.
      SELECT * FROM /psyng/swresfpr
      APPENDING TABLE lt_funprofile
      WHERE
        aid          = i_analysis_run AND
        sys          IN lr_sys AND
        funindex     IN lr_funindex AND
        profileindex IN lr_profindex_part.
      REFRESH : lr_profindex_part[].
    ENDWHILE.
    lr_profindex[] = lr_profindex_all[].
  ENDIF.
  FREE : lr_profindex_part, lr_profindex_all.

*-----------------------------------------------------------------------
*-------------------------------GET ROLES-------------------------------
*-----------------------------------------------------------------------
**--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024

  IF l_new_se_vrs EQ 'X'. "Get indexes from FPR table
    IF NOT lt_fprprof[] IS INITIAL.
      SELECT * FROM /psyng/swresipro
        INTO TABLE lt_profiles
         FOR ALL ENTRIES IN lt_fprprof
         WHERE aid       = i_analysis_run AND
*              sys       = lt_usrprof-sys and
               profindex = lt_fprprof-profileindex.

      SELECT * FROM /psyng/swresprol
        INTO TABLE lt_profrole
        FOR ALL ENTRIES IN lt_fprprof
        WHERE aid       = i_analysis_run AND
              sys       = lt_fprprof-sys AND
              profindex = lt_fprprof-profileindex.

      IF NOT lt_profrole[] IS INITIAL.
        SELECT * FROM /psyng/swresirol
          INTO TABLE lt_roles
          FOR ALL ENTRIES IN lt_profrole
          WHERE aid = i_analysis_run AND
                roleindex = lt_profrole-roleindex.
        IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
*BOC:HBHALLA (PN-14658) (Issue3) (08/08/25)
          IF NOT lr_userindex[] IS INITIAL.
            lr_userindex_all[] = lr_userindex[].
            WHILE NOT lr_userindex[] IS INITIAL.
              APPEND LINES OF lr_userindex FROM 1 TO 5000
              TO lr_userindex_part.
              DELETE lr_userindex FROM 1 TO 5000.
              SELECT * FROM /psyng/swresucom
*              INTO TABLE lt_comprole
                INTO TABLE lt_comprole_part
                FOR ALL ENTRIES IN lt_roles
                WHERE aid = i_analysis_run AND
*                    userindex IN lr_userindex AND
                      userindex IN lr_userindex_part AND
                      roleindex = lt_roles-roleindex.

              LOOP AT lt_comprole_part.
                INSERT lt_comprole_part INTO TABLE lt_comprole.
              ENDLOOP.

              REFRESH : lr_userindex_part[],lt_comprole_part[].
            ENDWHILE.
            lr_userindex[] = lr_userindex_all[].
          ENDIF.
          FREE : lr_userindex_part, lr_userindex_all.
*EOC:HBHALLA (PN-14658) (Issue3) (08/08/25)
          IF lt_comprole[] IS NOT INITIAL.
            DELETE lt_comprole[] WHERE compindex IS INITIAL
                                    OR compindex EQ 0.
          ENDIF.
          IF NOT lt_comprole[] IS INITIAL.
            SELECT * FROM /psyng/swresirol
            APPENDING TABLE lt_roles
            FOR ALL ENTRIES IN lt_comprole
              WHERE aid = i_analysis_run AND
                    roleindex = lt_comprole-compindex.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

  ELSE.
**--End of insert : UMITTAL C1342 D67K931619 14/05/2024
    IF NOT lt_usrprof[] IS INITIAL.

      SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
        FOR ALL ENTRIES IN
          lt_usrprof
      WHERE aid       = i_analysis_run AND
*              sys       = lt_usrprof-sys and
            profindex = lt_usrprof-profileindex.

      SELECT * FROM /psyng/swresprol
      INTO TABLE lt_profrole
      FOR ALL ENTRIES IN lt_usrprof
      WHERE aid       = i_analysis_run AND
            sys       = lt_usrprof-sys AND
            profindex = lt_usrprof-profileindex.
      IF NOT lt_profrole[] IS INITIAL.
        SELECT * FROM /psyng/swresirol
        INTO TABLE lt_roles
        FOR ALL ENTRIES IN lt_profrole
          WHERE aid = i_analysis_run AND
                roleindex = lt_profrole-roleindex.
        IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
          SELECT * FROM /psyng/swresucom
          INTO TABLE lt_comprole
          FOR ALL ENTRIES IN lt_roles WHERE
            aid = i_analysis_run AND
*            userindex = l_userinndex AND
            userindex IN lr_userindex AND
            roleindex = lt_roles-roleindex.
* BOC by RGUPTA on 25.07.22 for #22227
          IF lt_comprole[] IS NOT INITIAL.
            DELETE lt_comprole[] WHERE compindex IS INITIAL
                                    OR compindex EQ 0.
          ENDIF.
* EOC by RGUPTA on 25.07.22 for #22227
          IF NOT lt_comprole[] IS INITIAL.
            SELECT * FROM /psyng/swresirol
            APPENDING TABLE lt_roles
            FOR ALL ENTRIES IN lt_comprole
              WHERE aid = i_analysis_run AND
                    roleindex = lt_comprole-compindex.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF. "Added by : UMITTAL C1342 D67K931619 14/05/2024

*-----------------------------------------------------------------------
*----------------------------FINAL OUTPUT-------------------------------
*-----------------------------------------------------------------------
  SORT lt_usrprof BY sys userindex profileindex.
*Added by : UMITTAL C1342 D67K931619 14/05/2024
  SORT lt_fprprof BY sys userindex profileindex.
  SORT lt_usercon BY userindex conindex.
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
  IF l_new_se_vrs EQ 'X'.
    LOOP AT lt_confun.
      CLEAR lt_output.
*--get function index
      LOOP AT lt_fprprof WHERE funindex = lt_confun-funindex.
*--"get user and conflict index
        LOOP AT lt_usercon WHERE userindex = lt_fprprof-userindex
        AND
                                 conindex  = lt_confun-conindex .
*Later origin filter
*            IF lt_usercon-origin IS NOT INITIAL.
*              IF p_local = 'X' AND p_remote IS INITIAL
*               AND p_cross IS INITIAL
*               AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
*                  OR lt_usercon-origin = 5 ).
*                CONTINUE.
*              ELSEIF p_local = 'X' AND p_remote = 'X'
*               AND p_cross IS INITIAL
*               AND lt_usercon-origin = 3.
*                CONTINUE.
*              ELSEIF p_local = 'X' AND p_remote IS INITIAL
*               AND p_cross = 'X'
*               AND lt_usercon-origin = 2.
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote = 'X'
*               AND p_cross IS INITIAL
*               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
*                  OR lt_usercon-origin = 4 ).
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote = 'X'
*               AND p_cross = 'X'
*               AND lt_usercon-origin = 1.
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
*               AND p_cross = 'X'
*               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
*                CONTINUE.
*              ENDIF.
*            ENDIF.
*     userid
          READ TABLE lt_user WITH KEY userindex =
          lt_usercon-userindex.
          IF sy-subrc = 0.
            lt_output-bname   = lt_user-bname.
*BOC:HBHALLA (PN-15675) (08/10/25)
            lt_output-deprtmnt   = lt_user-department. "later
*EOC:HBHALLA (PN-15675) (08/10/25)
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
            lt_output-class   = lt_user-class. "Later
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
            lt_output-confnum = lt_user-nr_conflicts.
            lt_output-mitinum = lt_user-nr_mitigated. "Later
          ENDIF.
*     Conflicts
          READ TABLE lt_conflict WITH KEY conindex =
          lt_confun-conindex.
          IF sy-subrc = 0.
            lt_output-conid     = lt_conflict-conid.
            lt_output-mitigated = lt_usercon-mitigated.
            CASE lt_usercon-origin.
              WHEN 1.
                lt_output-origin = 'Local'(173).
              WHEN 2.
                lt_output-origin = 'Remote'(174).
              WHEN 3.
                lt_output-origin = 'Cross'(175).
              WHEN 4.
                lt_output-origin = 'Local&Cross'(202).
              WHEN 5.
                lt_output-origin = 'Remote&Cross'(203).
              WHEN 6.
                lt_output-origin = 'L&R&C'(204).
            ENDCASE.
          ENDIF.
*     function
          READ TABLE lt_function WITH KEY funindex =
          lt_confun-funindex.
          IF sy-subrc = 0.
            lt_output-funid = lt_function-funid.
          ENDIF.

*            IF p_fun <> 'X'. "Later
*     profiles
          READ TABLE lt_profiles WITH KEY
                        profindex = lt_fprprof-profileindex.
          IF sy-subrc = 0.
            lt_output-profname = lt_profiles-profname.
          ENDIF.

*    * Role
          READ TABLE lt_profrole WITH KEY
                     profindex = lt_fprprof-profileindex.
          IF sy-subrc = 0.
            READ TABLE lt_roles WITH KEY
            roleindex = lt_profrole-roleindex.
            lt_output-agr_name = lt_roles-agr_name.
*    * Composite Role
            LOOP AT lt_comprole WHERE userindex =
            lt_fprprof-userindex
            AND  roleindex =
            lt_profrole-roleindex.
              READ TABLE lt_roles WITH KEY
              roleindex  = lt_comprole-compindex.
              IF sy-subrc = 0.
                lt_output-comp_agr = lt_roles-agr_name.
                lv_comp_agr  = lt_output-comp_agr.

*Direct role assignment check
                IF if_direct_assn_only = 'X'.
                  READ TABLE lt_comprole
                    WITH KEY userindex = lt_fprprof-userindex
                            roleindex  = lt_profrole-roleindex
                            compindex  = 0.
                  IF sy-subrc = 0.
                    lf_direct_role = 'X'.
*                arpan added
                  ELSE.
                    CLEAR lf_direct_role.
                  ENDIF.
                ELSE.
                  lf_direct_role = 'X'.
*              arpan added
                ENDIF.

              ENDIF.

              READ TABLE lt_output WITH KEY
              bname    = lt_user-bname
              conid    = lt_conflict-conid
              funid    = lt_function-funid
              comp_agr = lt_output-comp_agr
              agr_name = lt_output-agr_name
              profname = lt_output-profname.
              IF sy-subrc <> 0.
                IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X'.
                  APPEND lt_output.
                ENDIF. "arpan direct role
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
                CLEAR lv_tabix.
                lv_tabix = sy-tabix.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
*                    ADD 1 TO g_alv_count."Later
              ENDIF.
            ENDLOOP.
          ELSE.
            lf_profauth = 'X'.
*  CLEAR: lt_output-comp_agr. "HBHALLA(PN-15751)(12/01/26)
*Clearing comp_agr was creating 2 entries in output table,
*one with comp_agr and another without it.
          ENDIF.
*            IF p_orgvar = 'X'. "later direct role
          IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X' OR
            lf_profauth = 'X' OR lv_comp_agr IS INITIAL.
            REFRESH : lt_authdet.
            CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
            EXPORTING
            i_aid             = i_analysis_run
            i_sys             = lt_fprprof-sys
            i_funindex        = lt_confun-funindex
            i_profileindex    = lt_fprprof-profileindex
            TABLES
            et_profiledetails = lt_authdet.

            LOOP AT lt_authdet.
              MOVE-CORRESPONDING lt_authdet TO lt_output.
              APPEND lt_output.

**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
              IF NOT lt_comprole[] IS INITIAL.
                READ TABLE lt_output WITH KEY
                bname    = lt_user-bname
                conid    = lt_conflict-conid
                funid    = lt_function-funid
                comp_agr = lv_comp_agr
                agr_name = lt_output-agr_name
                profname = lt_output-profname.
                IF sy-subrc EQ 0.
                  READ TABLE lt_authdet INTO ls_authdet WITH KEY
                  funid = lt_output-funid
                  profname = lt_output-profname.
                  IF sy-subrc EQ 0.
                    CLEAR ls_output_alv.
                    ls_output_alv = lt_output.
                    MOVE-CORRESPONDING ls_authdet TO ls_output_alv
                    .
                    IF NOT lv_tabix IS INITIAL.
                      MODIFY lt_output FROM ls_output_alv
                      INDEX lv_tabix .
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
            ENDLOOP.
*            CLEAR :lt_output.
*            ENDIF. "Later
            FREE : lt_authdet.
          ENDIF. "arpan direct role
          CLEAR :lf_direct_role, lf_profauth,  lv_comp_agr, lt_output.
          FREE : lt_authdet.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.

  ELSE.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
    LOOP AT lt_confun.
      CLEAR lt_output.
      LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
        LOOP AT lt_usercon WHERE conindex = lt_confun-conindex.
* BOC for B16609 for C0633
* Later
*            IF lt_usercon-origin IS NOT INITIAL.
*              IF p_local = 'X' AND p_remote IS INITIAL
*               AND p_cross IS INITIAL
*               AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
*                  OR lt_usercon-origin = 5 ).
*                CONTINUE.
*              ELSEIF p_local = 'X' AND p_remote = 'X'
*               AND p_cross IS INITIAL
*               AND lt_usercon-origin = 3.
*                CONTINUE.
*              ELSEIF p_local = 'X' AND p_remote IS INITIAL
*               AND p_cross = 'X'
*               AND lt_usercon-origin = 2.
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote = 'X'
*               AND p_cross IS INITIAL
*               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
*                  OR lt_usercon-origin = 4 ).
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote = 'X'
*               AND p_cross = 'X'
*               AND lt_usercon-origin = 1.
*                CONTINUE.
*              ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
*               AND p_cross = 'X'
*               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
*                CONTINUE.
*              ENDIF.
*            ENDIF.
* EOC for B16609 for C0633
          READ TABLE lt_usrprof WITH KEY
          sys          = lt_funprofile-sys
          userindex    = lt_usercon-userindex
          profileindex = lt_funprofile-profileindex
          BINARY SEARCH.
          CHECK sy-subrc = 0.
* userid
          READ TABLE lt_user WITH KEY userindex = lt_usercon-userindex.
          IF sy-subrc = 0.
            lt_output-bname = lt_user-bname.
            lt_output-deprtmnt   = lt_user-department. "later
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
            lt_output-class   = lt_user-class.
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
            lt_output-confnum = lt_user-nr_conflicts.
            lt_output-mitinum = lt_user-nr_mitigated.
          ENDIF.
* Conflicts
          READ TABLE lt_conflict WITH KEY conindex = lt_confun-conindex.
          IF sy-subrc = 0.
            lt_output-conid = lt_conflict-conid.
            lt_output-mitigated = lt_usercon-mitigated.
* BOC for B16609 for C0633
            CASE lt_usercon-origin.
              WHEN 1.
                lt_output-origin = 'Local'(173).
              WHEN 2.
                lt_output-origin = 'Remote'(174).
              WHEN 3.
                lt_output-origin = 'Cross'(175).
              WHEN 4.
                lt_output-origin = 'Local&Cross'(202).
              WHEN 5.
                lt_output-origin = 'Remote&Cross'(203).
              WHEN 6.
                lt_output-origin = 'L&R&C'(204).
            ENDCASE.
* EOC for B16609 for C0633
          ENDIF.
* function
          READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
          IF sy-subrc = 0.
            lt_output-funid = lt_function-funid.
          ENDIF.

*            IF p_fun <> 'X'. "later
* profiles
          READ TABLE lt_profiles WITH KEY
          profindex = lt_usrprof-profileindex.
          IF sy-subrc = 0.
            lt_output-profname = lt_profiles-profname.
          ENDIF.

** Role
          READ TABLE lt_profrole WITH KEY
          profindex = lt_usrprof-profileindex.
          IF sy-subrc = 0.
            READ TABLE lt_roles WITH KEY
            roleindex = lt_profrole-roleindex.
            lt_output-agr_name = lt_roles-agr_name.
** Composite Role
*              READ TABLE lt_comprole WITH KEY
*                userindex = lt_usercon-userindex
*                roleindex = lt_profrole-roleindex.
*              IF sy-subrc = 0.
*                READ TABLE lt_roles WITH KEY
*                  roleindex  = lt_comprole-compindex.
*                IF sy-subrc = 0.
*                  lt_output-comp_agr = lt_roles-agr_name.
*                ENDIF.
*              ELSE.
*                CLEAR lt_output-comp_agr.
*              ENDIF.
            LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
            AND  roleindex = lt_profrole-roleindex.
              READ TABLE lt_roles WITH KEY
              roleindex  = lt_comprole-compindex.
              IF sy-subrc = 0.
                lt_output-comp_agr = lt_roles-agr_name.
                lv_comp_agr = lt_output-comp_agr.
*Direct role assignment check
                IF if_direct_assn_only = 'X'.
                  READ TABLE lt_comprole
                    WITH KEY userindex = lt_fprprof-userindex
                            roleindex  = lt_profrole-roleindex
                            compindex  = 0.
                  IF sy-subrc = 0.
                    lf_direct_role = 'X'.
*                arpan added
                  ELSE.
                    CLEAR lf_direct_role.
                  ENDIF.
                ELSE.
                  lf_direct_role = 'X'.
*              arpan added
                ENDIF.

              ENDIF.
              READ TABLE lt_output WITH KEY bname = lt_user-bname
                                conid = lt_conflict-conid
                                funid = lt_function-funid
                         comp_agr = lt_output-comp_agr
                         agr_name = lt_output-agr_name
                        profname = lt_output-profname.
              IF sy-subrc <> 0.
                IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X'.
                  APPEND lt_output.
                ENDIF.
              ENDIF.
            ENDLOOP.
            CLEAR: lt_output-comp_agr.
          ELSE.
            lf_profauth = 'X'.
          ENDIF.

          IF lf_direct_role = 'X' OR if_direct_assn_only <> 'X' OR
                      lf_profauth = 'X' OR lv_comp_agr IS INITIAL.
            REFRESH : lt_authdet.
            CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
            EXPORTING
            i_aid             = i_analysis_run
            i_sys             = lt_usrprof-sys
            i_funindex        = lt_confun-funindex
            i_profileindex    = lt_usrprof-profileindex
            TABLES
            et_profiledetails = lt_authdet.

            LOOP AT lt_authdet.
              MOVE-CORRESPONDING lt_authdet TO lt_output.
              ADD 1 TO g_alv_count.
              APPEND lt_output.
            ENDLOOP.
*            CLEAR lt_output. "RGUPTA
          ENDIF.
          CLEAR :lf_direct_role, lf_profauth,  lv_comp_agr, lt_output.
*          endloop.
          FREE : lt_authdet.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDIF. " Added by : UMITTAL C1342 D67K931619 14/05/2024

  SORT lt_output BY bname conid sysid funid.
  DELETE ADJACENT DUPLICATES FROM lt_output COMPARING
ALL FIELDS.

*--free some memory
  FREE :     lt_user,
  lt_funprof ,
  lt_usrprof ,
  lt_usrprof2,
  lt_profrole,
  lt_roles   ,
  lt_comprole,
  lt_profiles ,
  lt_authdet  ,
  lt_authdet_all ,
  lt_funprofile ,
  lt_confun   ,
  lt_function,
  lt_usercon  .

ENDFORM.
