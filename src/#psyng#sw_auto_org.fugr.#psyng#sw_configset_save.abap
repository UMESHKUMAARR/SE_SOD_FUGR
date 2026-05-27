FUNCTION /psyng/sw_configset_save.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_CONFIGSET_READ) TYPE  FLAG OPTIONAL
*"     VALUE(I_READ_MODIFIED_ONLY) TYPE  FLAG OPTIONAL
*"     VALUE(I_SAVE_HEADER) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SAVE_SYSTEM) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SAVE_SELECTION) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SAVE_OE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SAVE_VE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_PUBLISH) TYPE  FLAG OPTIONAL
*"     VALUE(IS_CONFIGSET) TYPE  /PSYNG/SWCFGSET OPTIONAL
*"     VALUE(IF_DESCRIPTION) TYPE  FLAG OPTIONAL
*"     VALUE(I_DESC) TYPE  /PSYNG/LONGTEXTFIELD OPTIONAL
*"     VALUE(I_READ_SELECTIONS) TYPE  FLAG OPTIONAL
*"     VALUE(I_VERSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_GLOBAL_DFLT_SOD) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"     VALUE(E_CONFIGSET) TYPE  /PSYNG/SECONFID
*"     VALUE(E_CONFIGSET_NAME) TYPE  /PSYNG/LONGTEXTFIELD
*"     VALUE(E_CONFIGSETHDR) TYPE  /PSYNG/SWCFGSET
*"     VALUE(E_INVALID_VRSIO) TYPE  FLAG
*"     VALUE(E_SOD_VERSION) TYPE  /PSYNG/SODVRSIO
*"     VALUE(E_NO_CFGSET_EXIST) TYPE  FLAG
*"  TABLES
*"      IT_VE_ELEMENT STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"      IT_SELECTIONS STRUCTURE  /PSYNG/SWCFSEL OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_ORG_ELEMENT STRUCTURE  /PSYNG/SWCFGOE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_CONFIGSET STRUCTURE  /PSYNG/SW_CFGSET_READ_VALUES OPTIONAL
*"      ET_SELECTIONS STRUCTURE  /PSYNG/SWCFSEL OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_CONFIGSET_SAVE'.
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

  CONSTANTS: gc_read_values TYPE char1 VALUE 'X'.
  DATA: lt_var_elements  TYPE TABLE OF /psyng/swcfgve,
        lt_org_values    TYPE TABLE OF /psyng/swcfgoe.

  FIELD-SYMBOLS:
         <fs_var_elements> TYPE /psyng/swcfgve,
         <fs_org_values>   TYPE /psyng/swcfgoe.

  ef_success = 'X'.

*---AUTHORITY-CHECK
if I_CONFIGSET_READ is INITIAL.
  AUTHORITY-CHECK OBJECT 'Y&SW_CFGST'
  ID 'ACTVT' FIELD '02'
  ID 'Y&SW_SETID' FIELD ''."(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
    MESSAGE s108(/psyng/sw) WITH text-e20 INTO et_return-message.
    CLEAR ef_success.
  ENDIF.
   ENDIF.

  CHECK ef_success = 'X'.
  IF i_configset_read IS INITIAL.
*---Create New Configset ID
    IF is_configset IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_CFG_GET_NEW_SETID'
         IMPORTING
           setid = g_set_id.
      e_configset = g_set_id.
    ENDIF.

    IF i_save_header = 'X'.
      PERFORM save_configset_header USING
                        if_description i_desc I_VERSIO
                        i_global_dflt_sod.
      e_configset_name = i_desc.
    ENDIF.

*---Save selected systems /psyng/swcgfsys
    IF if_save_system = 'X'.
      PERFORM save_configset_systems TABLES it_systems.
    ENDIF.


*--Save the selected org elements and variable elements
    IF if_save_selection = 'X'.
      PERFORM save_oe_ve TABLES it_selections.
    ENDIF.

*---Save org level values for configuration set
    IF if_save_oe = 'X'.
      CALL FUNCTION '/PSYNG/SW_AO_SAVE'
        EXPORTING
          i_setid             = g_set_id
       IMPORTING
         ef_success          = ef_success
       TABLES
         it_org_values       = it_org_element.
    ENDIF.

*---Save variable elements for configuration set
    IF if_save_ve = 'X'.
      CALL FUNCTION '/PSYNG/SW_VE_SAVE'
        EXPORTING
          i_setid            = g_set_id
       TABLES
         it_ve_values       = it_ve_element.
    ENDIF.

*---Publish configuration set
    IF if_publish = 'X'.
      PERFORM publish_cfgset USING i_desc.
    ENDIF.

  ELSE.
*---read configset values
    DATA: l_cfgsetid TYPE /psyng/swcfgset-setid,
         l_vrsio    type /psyng/swcfgset-sodvrsio.

*----get the sod version
    if i_global_dflt_sod = 'X'.
    CALL FUNCTION '/PSYNG/SW_131'
     EXPORTING
       I_GLOBLE_VRSIO       = 'X'
     IMPORTING
       E_SOD_VERSION        = l_vrsio.
*       E_VALID              = lf_valid .
    e_sod_version = l_vrsio.
    else.
*--check if sod version is dummy
      e_sod_version = i_versio.
  select SINGLE mandt into sy-mandt
       from /psyng/conflict
    where vrsio = I_VERSIO.
    if sy-subrc <> 0.
      e_invalid_vrsio = 'X'.
      exit.
      else.
        l_vrsio = i_versio.
      endif.
      endif.

*----get the latest published configset
    SELECT setid description FROM /psyng/swcfgset INTO (l_cfgsetid,
      e_configset_name)
      WHERE SODVRSIO  = l_vrsio and published = 'X'
      ORDER BY setid ASCENDING.
    ENDSELECT.

    SELECT * FROM /psyng/swcfgset INTO e_configsethdr
      WHERE sodvrsio = l_vrsio and published = 'X'
      ORDER BY setid ASCENDING.
    ENDSELECT.

*---C1153 if latest configset not exist for default sod vrsio
    if I_GLOBAL_DFLT_SOD = 'X' and l_cfgsetid is INITIAL.
      E_NO_CFGSET_EXIST = 'X'.
      exit.
      endif.

    CALL FUNCTION '/PSYNG/SW_AO_READ'
     EXPORTING
       if_read                   = gc_read_values
       i_setid                   = l_cfgsetid
     TABLES
       et_org_values             = lt_org_values.

    CALL FUNCTION '/PSYNG/SW_VE_READ'
          EXPORTING
               if_read      = gc_read_values
               i_setid      = l_cfgsetid
          TABLES
               et_ve_values = lt_var_elements.

    LOOP AT lt_org_values ASSIGNING <fs_org_values>.
      et_configset-sysid = <fs_org_values>-sysid.
      et_configset-type  = 'ORG'.
      et_configset-abb   = <fs_org_values>-abb.
      et_configset-var_element  = <fs_org_values>-varbl.
      et_configset-value = <fs_org_values>-value.
      et_configset-active = <fs_org_values>-active.
      et_configset-modified = <fs_org_values>-modified.
      APPEND et_configset.
    ENDLOOP.

    LOOP AT lt_var_elements ASSIGNING <fs_var_elements>.
      et_configset-sysid = <fs_var_elements>-sysid.
      et_configset-type  = 'VE'.
*        ET_CONFIGSET-ABB   = <fs_org_values>-ABB.
      et_configset-var_element = <fs_var_elements>-var_element.
      et_configset-value = <fs_var_elements>-value.
      et_configset-active = <fs_var_elements>-active.
      et_configset-modified = <fs_var_elements>-modified.
      APPEND et_configset.
    ENDLOOP.

    e_configset = l_cfgsetid.
*---when read only modified values
    IF i_read_modified_only = 'X'.
      DELETE et_configset WHERE modified <> 'X'.
    ENDIF.

*-- all selections in latest published configset
    IF i_read_selections = gc_read_values.
      select * from /psyng/swcfsel into table et_selections
        where setid = l_cfgsetid.
    ENDIF.
  ENDIF.
ENDFUNCTION.
