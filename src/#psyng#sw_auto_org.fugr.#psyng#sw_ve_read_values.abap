FUNCTION /PSYNG/SW_VE_READ_VALUES.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/SYSID OPTIONAL
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(IF_ANALYSIS) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_FAOBJ2 STRUCTURE  /PSYNG/FAOBJ2
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_VAREL STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"      IT_RFCDEST STRUCTURE  RFCDES OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_READ_VALUES'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

data : lf_cfg_set_enabled type flag,
       l_varel_vrsio      type /PSYNG/VE_VRSIO,
       ls_rule            type /PSYNG/SW_VARVR,
       lt_elements        type table of /PSYNG/RANGE_SE_VAREL
                          with header line,
       lt_values          type table of /PSYNG/SWCFGVE
                          with header line,
       lt_systems         type table of /PSYNG/SWCFGSYS
                          with header line,
       ls_configset       type /PSYNG/SWCFGSET,
       LT_FAOBJ2          type table of /PSYNG/FAOBJ2 with header line,
       l_idx              like sy-tabix,
       l_placeholder      type xuvalue.
  EF_SUCCESS = 'X'.
*--Check if SOD Matrix contains ANY variable elements
  loop at ET_FAOBJ2 where val_from CP '/PSYNG/$*'.
    exit.
  endloop.
  if sy-subrc <> 0.
    clear EF_SUCCESS.
  endif.
  check EF_SUCCESS = 'X'.
*--Collect all elements that are used
  lt_elements-sign   = 'I'.
  lt_elements-option = 'EQ'.

  loop at ET_FAOBJ2 where val_from CP '/PSYNG/$*'.
    lt_elements-low =  ET_FAOBJ2-val_from.
    collect lt_elements.
  endloop.

*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled IS INITIAL.
*--Default Variable Elements Rules Version is used
  se_config_param 'DFLT_VAREL_VERSION' l_varel_vrsio.
*--Validate this version exists
    select single * from /PSYNG/SW_VARVR into ls_rule
    where VAREL_VRSIO = l_varel_vrsio.
    if sy-subrc <> 0.
      log et_return 'E' 'INVALID_RULE_VERSION'
        'Variable Element Rules defined in'
        'DFLT_VAREL_VERSION'
        'does not exist.'   l_varel_vrsio .
      CLEAR ef_success.
    endif.
    check ef_success = 'X'.
      lt_systems-sysid = i_sysid.
      append lt_systems.
      CALL FUNCTION '/PSYNG/SW_VE_READ'
        EXPORTING
         IF_ANALYZE                = 'X'
          i_setid                  = 0
         I_VAREL_VRSIO             = l_varel_vrsio
       IMPORTING
         EF_SUCCESS                = ef_success
       TABLES
         ET_VE_VALUES              = lt_values
         ET_RETURN                 = et_return
         IT_SYSTEMS                = lt_systems
         it_rfcdest                = it_rfcdest
         IT_ANALYZE_ELEMENTS       = lt_elements.
  ELSE.
*  --Validate the set exists
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_configset
    WHERE setid = i_setid.
    IF sy-subrc <> 0.
      log et_return 'E' 'INVALID_SET' 'Configuration Set' i_setid
                                      'does not exist.'
                                      ''.
      CLEAR ef_success.
    ENDIF.
    if ef_success = 'X'.
      lt_systems-sysid = i_sysid.
      append lt_systems.
      CALL FUNCTION '/PSYNG/SW_VE_READ'
        EXPORTING
         IF_READ                   = 'X'
         i_setid                   = I_SETID
       IMPORTING
         EF_SUCCESS                = ef_success
       TABLES
         ET_VE_VALUES              = lt_values
         ET_RETURN                 = et_return
         IT_SYSTEMS                = lt_systems
         IT_ANALYZE_ELEMENTS       = lt_elements.

    endif.
  ENDIF.
  check ef_success = 'X'.
*--Apply values to SOD Matrix
    delete lt_values where sysid  <> I_SYSID.
    delete lt_values where active <> 'X'.
    sort lt_values by var_element.
    loop at ET_FAOBJ2 where val_from CP '/PSYNG/$*'.
      l_placeholder = et_faobj2-val_from.
      read table lt_values with key var_element = et_faobj2-val_from
      binary search transporting no fields.
      if sy-subrc = 0.
        l_idx = sy-tabix.
        loop at lt_values from l_idx.
          if not lt_values-var_element = et_faobj2-val_from.
            exit.
          endif.
          lt_faobj2 = ET_FAOBJ2.
          lt_faobj2-val_from = lt_values-value.
          append lt_faobj2.
        endloop.
      else.
*--Not a single value is maintained for this placeholder
*--In case of an SOD Analysis (and not when displaying the SOD Matrix)
*--No users should be found to have this function
*--we replace the placeholder with "/PSYNG/$INVALIDVE$"
*  in fm /PSYNG/SW_COMPARE_RANGES this will be recognized and no auth will match this value
        if IF_ANALYSIS = 'X'.
          lt_faobj2 = ET_FAOBJ2.
          lt_faobj2-val_from = '/PSYNG/$INVALIDVE$'.
          append lt_faobj2.
        endif.
      endif.
    endloop.
**--Delete all the placeholders
    delete   ET_FAOBJ2 where val_from CP '/PSYNG/$*'.
    append lines of lt_faobj2 to et_faobj2.
    sort et_faobj2.

ENDFUNCTION.
