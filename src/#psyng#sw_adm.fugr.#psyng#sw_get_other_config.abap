FUNCTION /psyng/sw_get_other_config.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_READ_BUSAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_READ_SUBAREA) TYPE  FLAG OPTIONAL
*"     VALUE(IF_READ_RISK) TYPE  FLAG OPTIONAL
*"     VALUE(IF_READ_SYS_TYPE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_READ_SYS_CAT) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_BUSAREA STRUCTURE  /PSYNG/SW_SEL_OPTS_BUS_AREA OPTIONAL
*"      IT_SUBAREA STRUCTURE  /PSYNG/SW_SEL_OPTS_SUB_AREA OPTIONAL
*"      IT_RISK STRUCTURE  /PSYNG/RANGE_RISK OPTIONAL
*"      IT_SYS_TYPE STRUCTURE  /PSYNG/SW_SEL_OPTS_SYS_TYPE OPTIONAL
*"      IT_SYS_CAT STRUCTURE  /PSYNG/SW_SEL_OPTS_SYS_CAT OPTIONAL
*"      ET_BUSAREA STRUCTURE  /PSYNG/BUSAREA OPTIONAL
*"      ET_SUBAREA STRUCTURE  /PSYNG/BUS_PROCE OPTIONAL
*"      ET_RISK STRUCTURE  /PSYNG/SW_RISK OPTIONAL
*"      ET_SYS_TYPE STRUCTURE  /PSYNG/SW_SYSTYP OPTIONAL
*"      ET_SYS_CAT STRUCTURE  /PSYNG/SW_SYSCAT OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_OTHER_CONFIG'.
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

*--Get application areas
  IF NOT if_read_busarea IS INITIAL.
    SELECT *
      FROM /psyng/busarea
      INTO TABLE et_busarea
      WHERE busarea IN it_busarea.
  ENDIF.
*--Get process areas
  IF NOT if_read_subarea IS INITIAL.
    SELECT *
      FROM /psyng/bus_proce
      INTO TABLE et_subarea
      WHERE subarea IN it_subarea.
  ENDIF.
*--Get risks
  IF NOT if_read_risk IS INITIAL.
    SELECT *
      FROM /psyng/sw_risk
      INTO TABLE et_risk
      WHERE risk IN it_risk.
  ENDIF.
*--Get system types
  IF NOT if_read_sys_type IS INITIAL.
    SELECT *
      FROM /psyng/sw_systyp
      INTO TABLE et_sys_type
      WHERE sys_type IN it_sys_type.
  ENDIF.
*--Get system category
  IF NOT if_read_sys_cat IS INITIAL.
    SELECT *
      FROM /psyng/sw_syscat
      INTO TABLE et_sys_cat
      WHERE sys_category IN it_sys_cat.
  ENDIF.

ENDFUNCTION.
