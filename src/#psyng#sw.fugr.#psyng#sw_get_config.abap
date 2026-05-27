FUNCTION /psyng/sw_get_config.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_PARAMETER) TYPE  /PSYNG/PARAM OPTIONAL
*"     VALUE(IF_INFO) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(E_CONFIG) TYPE  /PSYNG/SE_CONFIG_PARAM
*"     VALUE(E_VALUE) TYPE  /PSYNG/PARAM_VALUE
*"  TABLES
*"      ET_CONFIG STRUCTURE  /PSYNG/SE_CONFIG_PARAM OPTIONAL
*"      ET_VALUELIST STRUCTURE  /PSYNG/SE_CONFIG_PARAM_LIST OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_CONFIG'.
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
  TYPES : BEGIN OF ty_ttree,
            id TYPE hier_treeg,
          END OF ty_ttree.

**Global Work area Declaration
  DATA: g_wa_config LIKE LINE OF et_config,
        lt_cfg_sort TYPE SORTED TABLE OF /psyng/se_config_param
                    WITH UNIQUE KEY param,
        lt_vrsio    TYPE TABLE OF /psyng/swsodvers WITH HEADER LINE,
        lt_varvr    TYPE TABLE OF /psyng/sw_varvr WITH HEADER LINE,
        lt_fms      TYPE TABLE OF fupararef WITH HEADER LINE,
lt_cfgsets  TYPE SORTED TABLE OF /psyng/swcfgset WITH UNIQUE KEY sodvrsio,
lt_events   TYPE btc_t_evtinfo,
ls_event    TYPE btc_s_evtinfo,
  lt_paramid TYPE TABLE OF tpara,
  ls_paramid TYPE tpara.
  DATA: lt_ttree TYPE TABLE OF ty_ttree,
        ls_ttree TYPE ty_ttree.
  DEFINE param.
    if &1 = i_parameter or
          i_parameter is initial.

      read table lt_cfg_sort into g_wa_config
                             with TABLE key param = &1
                             transporting value.

      if sy-subrc = 0.  "Parameter defined
        g_wa_config-default  = &2.      "Default Value
        g_wa_config-category = &3.      "Parameter Category
        g_wa_config-maintained = 'X'.   "Record exists in db
        modify lt_cfg_sort from g_wa_config transporting
          default
          category
          maintained
        where
          param = &1.
        clear g_wa_config.
      else.             "Parameter not defined
        g_wa_config-param    = &1.
        g_wa_config-default  = &2 .     "Default Value
        g_wa_config-category = &3.      "Parameter Category
        clear g_wa_config-maintained.   "Record does not exist in DB
        g_wa_config-value    = g_wa_config-default.
        insert g_wa_config into table lt_cfg_sort.
      endif.
*--Assign custom category for parameters that have no category
      g_wa_config-category = 'Custom'(p00).
      modify lt_cfg_sort from g_wa_config transporting
        category
        where category = ''.
    endif.
  END-OF-DEFINITION.



  REFRESH: et_config.
  IF i_parameter IS INITIAL.
    SELECT * FROM /psyng/swconfig                       "#EC CI_NOWHERE
        INTO CORRESPONDING FIELDS OF TABLE lt_cfg_sort.
  ELSE.
    SELECT * FROM /psyng/swconfig
        INTO CORRESPONDING FIELDS OF TABLE lt_cfg_sort
        WHERE param = i_parameter.
  ENDIF.
*****************************************************
*--Initialize all parameters
  param :
  '31_26_CROSS_COMPAT'   'Y'                'Legacy'(p01),
  'DASHBOARD_ACTIVE'     'N'                'Dashboard'(p03),
  'DASHBOARD_WIDGET2'    'SE_PIE_CONFLICTS' 'Dashboard'(p03),
  'DASHBOARD_WIDGET1'    'EMPLOYEESTATUS'   'Dashboard'(p03),

  'DFLT_ADVSIM_WILDCARD' 'N'                'Defaults'(p04),
  'DFLT_CON_MA_EMAIL'    ''                 'Defaults'(p04),
  'DFLT_EXCLUDE_LOCKED'	 'Y'                'Defaults'(p04),
  'DFLT_EXCL_OUT_VALID'	 'Y'                'Defaults'(p04),
  'DFLT_GLOBAL_VERSION'	 '000'              'Defaults'(p04),
  'DFLT_VAREL_VERSION'   '000'              'Defaults'(p04),
  'DFLT_INCLUDE_ER'      'N'                'Defaults'(p04),
  'DFLT_LIGT_COLOR'      'N'                'Defaults'(p04),
  'DFLT_LOCAL_SOD'       'N'                'Defaults'(p04),
  'DFLT_LOCAL_USR'       'N'                'Defaults'(p04),
  'DFLT_MAX_USER_SCAN'   '0'                'Defaults'(p04),
  'DFLT_MIT_MA_EMAIL'	   ''                 'Defaults'(p04),
  'DFLT_ORG_LEVEL_CHECK' 'N'                'Defaults'(p04),
  'DFLT_SHOW_COMPOSITE'	 'N'                'Defaults'(p04),
  'DFLT_SHO_MIT_CONS'	   'N'                'Defaults'(p04),
  'DFLT_SHO_NO_SOD'  	   'N'                'Defaults'(p04),
  'DFLT_SHO_SCAN_RSLT'   'Y'                'Defaults'(p04),
  'DFLT_UPD_SCAN_TBL'	   'N'                'Defaults'(p04),
  'DFLT_VALID_DIALOG'	   'Y'                'Defaults'(p04),
  'DFLT_VAREL_SKIPVAL'   'N'                'Defaults'(p04),
  'DFLT_VAREL_TEST'      'N'                'Defaults'(p04),
  'DFLT_STORE_RET_DAYS'  '31'               'Defaults'(p04),
  'DFLT_STORE_R_DAYS_S'  '31'               'Defaults'(p04),
  'DFLT_STORE_R_DAYS_D'  '31'               'Defaults'(p04),
  'DFLT_ST_ROL_RET_DAYS' '31'               'Defaults'(p04),
  'DFLT_ST_RORET_DAYS_S' '31'               'Defaults'(p04),
  'DFLT_ST_RORET_DAYS_D' '31'               'Defaults'(p04),
  'DFLT_STORE_SOD_DESC'  'SE SOD Analysis'  'Defaults'(p04),
  'DFLT_ST_ROL_SOD_DESC' 'SE Role SOD Analysis' 'Defaults'(p04),
  'DFLT_STORE_NOCON_USR' 'N'                 'Defaults'(p04),
  'DFLT_STORE_NOCON_ROL' 'N'                 'Defaults'(p04),
  'DFLT_ENHANCE_MATRIX'  ''                  'Defaults'(p04),
*  'HIDE_ORG_ANALYSIS'  'N'                'Defaults'(p04),
  'DFLT_STOR_DET_BTCH'   '50'                'Defaults'(p04),
  'DFLT_ST_ROL_DET_BTCH' '50'                'Defaults'(p04),
  'DFLT_STOR_SUM_BTCH'   '1000'              'Defaults'(p04),
  'DFLT_ST_ROL_SUM_BTCH' '1000'              'Defaults'(p04),
  'DFLT_STOR_SUM_PAR'    '2'                 'Defaults'(p04),
  'DFLT_USER_COMP_VIEW'  'C'                 'Defaults'(p04),
  'DFLT_ROLE_COMP_VIEW'  'C'                 'Defaults'(p04),
  'DFLT_INACT_LOCK'     '60'                 'Defaults'(p04),
  'DFLT_INACT_EXP'     '90'                  'Defaults'(p04),
  'DFLT_INACT_DEL'   '180'                   'Defaults'(p04),
  'DFLT_TCOD_VALIDATION' 'Y'                 'Defaults'(p04),

  'LEVEL3_CHDR_INDEX'	   ''                  'Performance'(p10),
  'DET_SOD_BATCH_SIZE'   '50'                'Performance'(p10),
  'AUTHCOMP_BUFFERSIZE'  '50000'             'Performance'(p10),


  'MIT_APRV_EQ_USR_MSG'	 'E'                 'Mitigations'(P08),
  'MIT_ASGN_AUTH_CHECK'	 '1'                 'Mitigations'(P08),
  'MIT_ATTACH_URL'       ''                  'Mitigations'(P08),
  'MIT_AUDT_EQ_USR_MSG'	 'E'                 'Mitigations'(P08),
  'MIT_AUDT_HDR_LIST'	   'N'                 'Mitigations'(P08),
  'MIT_CON_DEFINED_ONLY' 'N'                 'Mitigations'(P08),
  'MIT_VALID_FOR_CON'	   'W'                 'Mitigations'(P08),
  'SW_REMOTE_MITIGATION' 'N'                 'Mitigations'(P08),
  'SW_MIT_BY_ROLE'       '0'                 'Mitigations'(P08),
  'SW_MIT_SIGNOFF_TEXT'  '/PSYNG/SW_MIT_SIGNOFF_TEXT'
                                             'Mitigations'(P08),
  'MIT_DFLT_REV_TEXT'    '/PSYNG/MIT_DFLT_REV_TEXT'
                                             'Mitigations'(P08),
* Arpan START
  'MIT_DEL_EXPIRE_ONLY' 'Y'                  'Mitigations'(P08),
* Arpan END

*BOC C1159 CGUPTA 20/09/2023
  'MIT_ASGN_NOTIFY_DAYS' '30'                'Mitigations'(P08),
*EOC C1159 CGUPTA 20/09/2023

  'ORG_LEVEL'            ''                 'Org. Analysis'(P09),
  'ORG_LVL_RES_MOD'      ''                 'Org. Analysis'(P09),
  'ORG_LVL_OVERRIDE'     'N'                'Org. Analysis'(P09),
  'HIDE_ORG_ANALYSIS'	   'N'                'Org. Analysis'(P09),
  'MIT_BY_ORG'           'N'                'Org. Analysis'(P09),
  'CONSIDER_ORG_AREA'    'N'                'Org. Analysis'(P09), "C0766
  'ADVSIMU_ORG_FULLAUTH' 'N'                'Org. Analysis'(P09), "C0752
  'CONSIDER_ORG_FIELD'   'Y'                'Org. Analysis'(P09), "AKUMAR OPL645

  'CFG_SET_PUBLISHEVENT'  ''                 'Config. Set'(P12),
  'CFG_SET_ENABLED'	      'N'                'Config. Set'(P12),
  'CFG_SET_AUTOPARSE'     'N'                'Config. Set'(P12),
  'ORG_VAL_FABKL'         'Y'                'Config. Set'(P12),
  'CFG_SET_HIDE_ABB'      'N'                'Config. Set'(P12),
  'CFG_SET_ORG_SHOW_TOT'  'Y'                'Config. Set'(P12),
  'ORG_DET_HIER'          'N'                'Config. Set'(P12),
*--Default checkboxes for Org levels in Config set maintenance
  'ORG_DFLT_BUKRS'        'Y'                'Config. Set'(P12),
  'ORG_DFLT_EKORG'        ''                 'Config. Set'(P12),
  'ORG_DFLT_WERKS'        ''                 'Config. Set'(P12),
  'ORG_DFLT_VKORG'        ''                 'Config. Set'(P12),
  'ORG_DFLT_GSBER'        ''                 'Config. Set'(P12),
  'ORG_DFLT_SPART'        ''                 'Config. Set'(P12),
  'ORG_DFLT_VTWEG'        ''                 'Config. Set'(P12),
  'ORG_DFLT_KKBER'        ''                 'Config. Set'(P12),
  'ORG_DFLT_VSTEL'        ''                 'Config. Set'(P12),
  'ORG_DFLT_IWERK'        ''                 'Config. Set'(P12),
*--Default checkboxes for Variable Elements in Config Set maintenance
  'VAR_DFLT_001'          ''                 'Config. Set'(P12),
  'VAR_DFLT_002'          ''                 'Config. Set'(P12),
*--Highlighting and toggling Org and Variable Elements in Reports
  'CFG_SET_HIGHLIGHT'	    'N'                'Config. Set'(P12),
  'CFG_SET_SHOW_DFLT'	    'Y'                'Config. Set'(P12),
  'CFG_SET_EXACT_MATCH'   'N'                'Config. Set'(P12),
*--ARPAN 28.09.2022 STARTS
  'CFG_SET_DIST_REST'     'N'                'Config. Set'(P12),
*--ARPAN 28.09.2022 ENDS

  'REP_USR_LOK_DSP_MGR'	  'N'                'User Master Data'(p06),
  'REP_USR_LOK_DSP_SLF'	  'Y'                'User Master Data'(p06),
  'FM_MAP_USER'           '/PSYNG/SW_061'    'User Master Data'(p06),
   'SOD_REV_USR_MAPPING'   'N'                'User Master Data'(p06),
  'SOD_SINGLE_COMPANY'    ''                 'User Master Data'(p06),
  'SW_CENTRAL_USR_FM'	    '/PSYNG/SW_088'    'User Master Data'(p06),
  'SW_COMPANY_SHLP_FM'    '/PSYNG/SW_074'    'User Master Data'(p06),
  'SW_DEPART_SHLP_FM'	    '/PSYNG/SW_077'    'User Master Data'(p06),
  'SW_LOCAL_SYSTEM_SORT'  ''                 'User Master Data'(p06),
  'SW_MGMT_COMPANY_FM'    '/PSYNG/SW_069'    'User Master Data'(p06),
  'SW_MGMT_COMP_NAME_FM'  '/PSYNG/SW_086'    'User Master Data'(p06),
  'SW_MGMT_DEPARTMENT_F'  '/PSYNG/SW_070'    'User Master Data'(p06),
  'USR_PARAM_FIELD_NAME'  ''    'User Master Data'(p06),


  'ROLES_IMP_DERIVED'	    'N'                'Reporting Options'(p11),
  'SCAN_NO_VERIFICATION'  ''                 'Reporting Options'(p11),
  'SE_CENTRAL_RFC'        ''                 'Reporting Options'(p11),
  'SW_054_CROSS'          'Y'                'Reporting Options'(p11),
  'SW_054_LOCAL'          'Y'                'Reporting Options'(p11),
  'SW_054_REMOTE'         'N'                'Reporting Options'(p11),
  'SW_056_RFC_DEST'       ''                 'Reporting Options'(p11),
  'SW_DFLT_RFC_DEST'      ''                 'Reporting Options'(p11),
  'SW_ENH_LOCAL_FILT'	    'N'                'Reporting Options'(p11),
  'SW_ENH_SCAN_TBL'       'N'                'Reporting Options'(p11),
*  'SW_PROFILE_CHECK'  	''                 'Reporting Options'(p11),
  'AREA_MENU'             '/PSYNG/SW_001'    'Reporting Options'(p11),
  'SW_REM_ROLE_FILTER' 	  ''                 'Reporting Options'(p11),
  'SW_ROLES_POS_USRASGN'  'N'                'Reporting Options'(p11),
  'USE_ROLES'             'Y'                'Reporting Options'(p11),
  'REPEAT_HDR_BKGDJOB'    'N'                'Reporting Options'(p11),
  'SOD_EXPORT_ALV_LIMIT'  '1000000'          'Reporting Options'(p11),
  'SW_ENH_BUFFER'	        'N'                'Reporting Options'(p11),
  'SW_ENH_BUFFER_DAYS'    '7'                'Reporting Options'(p11),

  'SW_MGMT_NUM_WEEKS'	    '8'                'Risk Visualizer'(p07),
  'SW_MGMT_REPORTING'	    'N'                'Risk Visualizer'(p07),
  'SW_MGMT_VRSIO'         ''                 'Risk Visualizer'(p07),




  'SW_TRP_ADD_CHECK'       ''                 'Integration'(p05),
  'SW_TRP_REL_CHECK'       ''                 'Integration'(p05),
  'SW_TRP_REL_ENFORCE'     ''                 'Integration'(p05),
  'SW_USERSAVE_CHECK'	     ''                 'Integration'(p05),
  'EN_INTEGRATION'         'Y'                'Integration'(p05),
  'SW_INTEGRATION_VRSIO'   ''                 'Integration'(p05),
  'SW_PROFILE_CHECK'       ''                 'Integration'(p05),
  'FIORI_SOD_VERSION'      ''                 'Integration'(p05),
  'TA_ROLE_EFF'            'Y'                'Integration'(p05),
  'TA_DISPLAY_HISTORY'     'Y'                'Integration'(p05),
*  'SW_SAST_DATA_EVENT'     'Y'                 'Integration'(p05),
*BOC AKUMAR SE ABAC
'SE_ABAC_INTEGRATION'     'N'  'Integration'(p05),
*EOC AKUMAR SE ABAC

*BOC UMITTAL SE-CAC Integration
'SE_CAC_INTEGRATION'     'N'  'Integration'(p05),
*EOC UMITTAL SE-CAC Integration

'SW_MIT_ASG_NOTIF_OID'   '/PSYNG/SW_MIT_ASSIGNMENT_EMAIL'
                                             'E-Mail'(p13),
'SW_MIT_REMIND_EMAIL'	   '/PSYNG/SW_MIT_REMIND_EMAIL'
                                             'E-Mail'(p13),
*BOC C1159 CGUPTA 21/09/2023
'SW_MIT_EXPIRE_EMAIL'	   '/PSYNG/SW_MIT_ASSIGNMENT_EXPIRE_EMAIL'
                                             'E-Mail'(p13),
*EOC C1159 CGUPTA 21/09/2023

'SW_MIT_SIGNOFF_EMAIL'   '/PSYNG/SW_MIT_SIGNOFF_EMAIL'
                                             'E-Mail'(p13),
'SW_USR_INACTIV_EMAIL'   '/PSYNG/SW_USER_INACTIVITY'
                                             'E-Mail'(p13),
'APPROVAL_CENTRAL_SYS'   ''                  'E-Mail'(p13),
'CFGGSET_COMP_EMAIL'     '/PSYNG/SW_CONFIG_SET_COMPARE'
                                             'E-Mail'(p13),
'CFGGSET_COMP_ADDR'      ''
                                             'E-Mail'(p13),

'SW_CSS_EMAIL'           '/PSYNG/BC_EMAIL_CSS'
                                             'E-Mail'(p13),

'APILOG_GENERAL_INFO'    'N'                 'Logging'(p14),
'APILOG_ANALYSIS_RES'    'N'                 'Logging'(p14),
'APILOG_CONFLICT_LIST'   'N'                 'Logging'(p14),
'APILOG_CONFLICT_DET'    'N'                 'Logging'(p14),
'APILOG_SOD_BY_ROLE'     'N'                 'Logging'(p14),
'APILOG_SOD_BY_USER'     'N'                 'Logging'(p14),
'APILOG_CONFIG_SET'      'N'                 'Logging'(p14),
'APILOG_SOD_BY_REFROL'   'N'                 'Logging'(p14),
'APILOG_SODREFROLCOMB'   'N'                 'Logging'(p14),
'APILOG_SOD_BY_USER_R'   'N'                 'Logging'(p14),

'FIORI_SOD_KPI_A_PAT'    ''                  'Fiori'(p15),
'FIORI_SOD_KPI_A_LBL'    ''                  'Fiori'(p15),
'FIORI_SOD_KPI_B_PAT'    ''                  'Fiori'(p15),
'FIORI_SOD_KPI_B_LBL'    ''                  'Fiori'(p15),
'FIORI_SOD_VERSION'      ''                  'Fiori'(p15).




  DEFINE dropdown.
    et_valuelist-PARAM = &1.
    et_valuelist-value = &2.
    append et_valuelist.
  END-OF-DEFINITION.
  DEFINE yesno.
    et_valuelist-PARAM = &1.
    et_valuelist-value = 'Y'.
    append et_valuelist.
    et_valuelist-value = 'N'.
    append et_valuelist.
  END-OF-DEFINITION.
  DEFINE vrsio.
    et_valuelist-PARAM = &1.
    loop at lt_vrsio.
      et_valuelist-value = lt_vrsio-vrsio.
      append et_valuelist.
    endloop.
  END-OF-DEFINITION.
  DEFINE varvr.
    et_valuelist-PARAM = &1.
    loop at lt_varvr.
      et_valuelist-value = lt_varvr-VAREL_VRSIO.
      append et_valuelist.
    endloop.
  END-OF-DEFINITION.
  DEFINE fm.
    et_valuelist-PARAM = &1.
    refresh : lt_fms.
*-- find all FM's with the same signature
    CALL FUNCTION '/PSYNG/SW_129'
     EXPORTING
       I_REFERENCE_FM       = &2
      TABLES
        et_functions        = lt_fms.
       delete lt_fms where funcname np 'Y*'
                       and funcname np 'Z*'
                       and funcname np '/*'.
    loop at lt_fms.
      et_valuelist-value = lt_fms-funcname.
      append et_valuelist.
    endloop.
  END-OF-DEFINITION.
  DEFINE sysevents.
*--Get all evenets defined by the customer (so not standard sap events)
    et_valuelist-PARAM = &1.
    refresh : lt_events.
     CALL METHOD cl_batch_event=>get_all
      IMPORTING
        e_events = lt_events.
    loop at lt_events into ls_event where systemevent = ''.
      et_valuelist-value = ls_event-EVENTID.
      append et_valuelist.
    endloop.
  END-OF-DEFINITION.

  IF et_valuelist IS REQUESTED.
*--Define dropdown values for the yes/no parameters
    yesno : 'CFG_SET_AUTOPARSE',
            'CFG_SET_ENABLED',
            'CFG_SET_HIDE_ABB',
            'CFG_SET_HIGHLIGHT',
            'CFG_SET_ORG_SHOW_TOT',
            'CFG_SET_SHOW_DFLT',
            'ORG_DET_HIER',
            'ORG_DFLT_BUKRS',
            'ORG_DFLT_EKORG',
            'ORG_DFLT_GSBER',
            'ORG_DFLT_IWERK',
            'ORG_DFLT_KKBER',
            'ORG_DFLT_SPART',
            'ORG_DFLT_VKORG',
            'ORG_DFLT_VSTEL',
            'ORG_DFLT_VTWEG',
            'ORG_DFLT_WERKS',
            'ORG_VAL_FABKL',
            'DASHBOARD_ACTIVE',
            'DFLT_ADVSIM_WILDCARD',
            'DFLT_CON_MA_EMAIL',
            'DFLT_ENHANCE_MATRIX',
            'DFLT_EXCLUDE_LOCKED',
            'DFLT_EXCL_OUT_VALID',
            'DFLT_INCLUDE_ER',
            'DFLT_LIGT_COLOR',
            'DFLT_LOCAL_SOD',
            'DFLT_LOCAL_USR',
            'DFLT_MIT_MA_EMAIL',
            'DFLT_ORG_LEVEL_CHECK',
            'DFLT_SHOW_COMPOSITE',
            'DFLT_SHO_MIT_CONS',
            'DFLT_SHO_NO_SOD',
            'DFLT_SHO_SCAN_RSLT',
            'DFLT_STORE_NOCON_ROL',
            'DFLT_STORE_NOCON_USR',
            'DFLT_UPD_SCAN_TBL',
            'DFLT_VALID_DIALOG',
            'DFLT_VAREL_SKIPVAL',
            'DFLT_VAREL_TEST',
            'EN_INTEGRATION',
            'SW_PROFILE_CHECK',
            'SW_TRP_ADD_CHECK',
            'SW_TRP_REL_CHECK',
            'SW_TRP_REL_ENFORCE',
            'SW_USERSAVE_CHECK',
            'TA_DISPLAY_HISTORY',
            'TA_ROLE_EFF',
            '31_26_CROSS_COMPAT',
            'APILOG_ANALYSIS_RES',
            'APILOG_CONFIG_SET',
            'APILOG_CONFLICT_DET',
            'APILOG_CONFLICT_LIST',
            'APILOG_GENERAL_INFO',
            'APILOG_SODREFROLCOMB',
            'APILOG_SOD_BY_REFROL',
            'APILOG_SOD_BY_ROLE',
            'APILOG_SOD_BY_USER',
            'APILOG_SOD_BY_USER_R',
            'MIT_AUDT_HDR_LIST',
            'MIT_CON_DEFINED_ONLY',
            'SW_REMOTE_MITIGATION',
            'HIDE_ORG_ANALYSIS',
            'ORG_LVL_OVERRIDE',
            'REPEAT_HDR_BKGDJOB',
            'ROLES_IMP_DERIVED',
            'SCAN_NO_VERIFICATION',
            'SW_054_CROSS',
            'SW_054_LOCAL',
            'SW_054_REMOTE',
            'SW_ENH_BUFFER',
            'SW_ENH_LOCAL_FILT',
            'SW_ENH_SCAN_TBL',
            'SW_REM_ROLE_FILTER',
            'SW_ROLES_POS_USRASGN',
            'USE_ROLES',
            'REP_USR_LOK_DSP_MGR',
            'REP_USR_LOK_DSP_SLF',
            'SOD_SINGLE_COMPANY',
            'CFG_SET_EXACT_MATCH',
            'SW_MGMT_REPORTING',
            'MIT_BY_ORG',
            'CONSIDER_ORG_AREA', "C0766
            'CFG_SET_DIST_REST', "C0788
            'MIT_DEL_EXPIRE_ONLY',
            'ADVSIMU_ORG_FULLAUTH', "C0752',
            'SE_ABAC_INTEGRATION'," SE ABAC
            'SOD_REV_USR_MAPPING',
            'DFLT_TCOD_VALIDATION',
            'SE_CAC_INTEGRATION'."*(++)UMITTAL SE-CAC Integration

    dropdown  'CONSIDER_ORG_FIELD' : 'Y', 'N'. "AKUMAR OPL645
    dropdown  'DFLT_ROLE_COMP_VIEW' : 'R', 'C'.
    dropdown  'DFLT_USER_COMP_VIEW' : 'C', 'U', 'UC'.
    dropdown  'MIT_APRV_EQ_USR_MSG' : 'E','W','S'.
    dropdown  'MIT_AUDT_EQ_USR_MSG' : 'E','W','S'.
    dropdown  'MIT_VALID_FOR_CON'   : 'E','W','S'.
    dropdown  'MIT_ASGN_AUTH_CHECK' : '1', '2'.
    dropdown  'LEVEL3_CHDR_INDEX'  : '573864_OBJECTCLAS'.
    dropdown  'SW_MIT_BY_ROLE'      : '0', '1', '2', '3'.
    dropdown  'DASHBOARD_WIDGET1'   : 'BIGPICTUREGRID',
                                      'COMPLIANCESTATUS',
                                      'CONFLICT_AGE',
                                      'CONFLICTMIT',
                                      'CONFLICTOWNER',
                                      'CONFLICTSUM',
                                      'CONFLICTSUMGRID',
                                      'CRITAUTH',
                                      'EMPLOYEESTATUS',
                                      'FUNCTIONMATRIX',
                                      'MITIGATIONSUMMARY',
                                      'MITIGATIONTPIE',
                                      'ROLESUM',
                                      'SE_PIE_CONFLICTS',
                                      'SEKPI_CONFLICTS',
                                      'TOPROLES',
                                      'TOPUSERS',
                                      'USERSTATUS',
                                      'USERVIOLATION'.
    dropdown  'DASHBOARD_WIDGET2'   : 'BIGPICTUREGRID',
                                      'COMPLIANCESTATUS',
                                      'CONFLICT_AGE',
                                      'CONFLICTMIT',
                                      'CONFLICTOWNER',
                                      'CONFLICTSUM',
                                      'CONFLICTSUMGRID',
                                      'CRITAUTH',
                                      'EMPLOYEESTATUS',
                                      'FUNCTIONMATRIX',
                                      'MITIGATIONSUMMARY',
                                      'MITIGATIONTPIE',
                                      'ROLESUM',
                                      'SE_PIE_CONFLICTS',
                                      'SEKPI_CONFLICTS',
                                      'TOPROLES',
                                      'TOPUSERS',
                                      'USERSTATUS',
                                      'USERVIOLATION'.

*--Drop down for USR_PARAM_FIELD_NAME
    SELECT paramid
      FROM tpara
      INTO TABLE lt_paramid.
    IF sy-subrc = 0.
      LOOP AT lt_paramid INTO ls_paramid.
        dropdown  'USR_PARAM_FIELD_NAME' ls_paramid-paramid.
      ENDLOOP.
    ENDIF.

*Get Area Menus defined by customer
    SELECT id FROM ttree
      INTO TABLE lt_ttree
     WHERE type = 'BMENU'
       AND responsibl NE 'SAP'.
    IF sy-subrc EQ 0.
      LOOP AT lt_ttree INTO ls_ttree.
        dropdown  'AREA_MENU' ls_ttree-id.
      ENDLOOP.
    ENDIF.
    sysevents : 'CFG_SET_PUBLISHEVENT'.
*--Dropdown values for all params that have SOD Matrix Version
    SELECT * FROM /psyng/swsodvers INTO TABLE lt_vrsio. "#EC CI_NOWHERE
    vrsio : 'FIORI_SOD_VERSION',
            'SW_INTEGRATION_VRSIO',
            'SW_MGMT_VRSIO'.
*--If config set functionality is enabled, only versions with a published config set are allowed.
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'CFG_SET_ENABLED'
      IMPORTING
        e_value     = g_wa_config-value.
    IF g_wa_config-value = 'Y'.
SELECT DISTINCT sodvrsio FROM /psyng/swcfgset INTO CORRESPONDING FIELDS OF TABLE lt_cfgsets WHERE published = 'X'.
      LOOP AT lt_vrsio.
READ TABLE lt_cfgsets WITH TABLE KEY sodvrsio = lt_vrsio-vrsio TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE lt_vrsio.
        ENDIF.
      ENDLOOP.
    ENDIF.
    vrsio : 'DFLT_GLOBAL_VERSION'.
*--Dropdown values for all params that have variable elements version
    SELECT * FROM /psyng/sw_varvr INTO TABLE lt_varvr.  "#EC CI_NOWHERE
    varvr : 'DFLT_VAREL_VERSION'.
*--Dropdown values for parameters that expect a function module name
    fm : 'FM_MAP_USER'          '/PSYNG/SW_061',
         'SW_CENTRAL_USR_FM'    '/PSYNG/SW_088',
         'SW_COMPANY_SHLP_FM'   '/PSYNG/SW_074',
         'SW_DEPART_SHLP_FM'    '/PSYNG/SW_077',
         'SW_MGMT_COMP_NAME_FM' '/PSYNG/SW_086',
         'SW_MGMT_COMPANY_FM'   '/PSYNG/SW_069',
         'SW_MGMT_DEPARTMENT_F' '/PSYNG/SW_070',
         'ORG_LVL_RES_MOD'      '/PSYNG/SW_ORG_LVL_RES_MOD',
         'ORG_LEVEL'            '/PSYNG/SW_122'.



    SORT et_valuelist BY param value.
  ENDIF.

  IF NOT i_parameter IS INITIAL.
    DELETE et_valuelist WHERE param <> i_parameter.
  ENDIF.

  IF NOT i_parameter IS INITIAL.
    LOOP AT lt_cfg_sort INTO g_wa_config WHERE param = i_parameter.
      MOVE-CORRESPONDING g_wa_config TO e_config.
      IF NOT e_config-value IS INITIAL.
        e_value = e_config-value.
      ELSE.
        e_value = e_config-default.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF et_config IS REQUESTED.
    APPEND LINES OF lt_cfg_sort TO et_config.
    SORT et_config BY category param.
  ENDIF.
*--Load messages with information about the parameter
  IF if_info = 'X'.
    PERFORM add_param_info
      TABLES et_config.
  ENDIF.
ENDFUNCTION.
