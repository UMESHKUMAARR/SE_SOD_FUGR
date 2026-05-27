FUNCTION /psyng/sw_parameters_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      IT_PARAM STRUCTURE  /PSYNG/RANGE_PARAM OPTIONAL
*"      ET_CONFIG STRUCTURE  /PSYNG/SE_CONFIG_PARAM OPTIONAL
*"      ET_VALUELIST STRUCTURE  /PSYNG/SE_CONFIG_PARAM_LIST OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_PARAMETERS_INFO'.
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

  DATA: lt_swconfig TYPE TABLE OF /psyng/swconfig WITH HEADER LINE,
        lt_config TYPE TABLE OF /psyng/se_config_param WITH HEADER LINE.
*-- no parameter entered in selection get all
  IF it_param[] IS INITIAL.
    if ET_VALUELIST is requested.
      CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
           EXPORTING
                if_info  = 'X'
           TABLES
                et_config    = et_config
                et_valuelist = et_valuelist.
    else.
      CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
           EXPORTING
                if_info  = 'X'
           TABLES
                et_config = et_config.
    endif.
  ELSE.
*-- get only entered parameter value
    SELECT * FROM /psyng/swconfig INTO TABLE lt_swconfig
    WHERE param IN it_param.

    LOOP AT lt_swconfig.
      CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
           EXPORTING
                i_parameter = lt_swconfig-param
           TABLES
                et_config    = lt_config
                et_valuelist = et_valuelist..
      APPEND LINES OF lt_config TO et_config.

      CLEAR: lt_config, lt_config[].
    ENDLOOP.
  ENDIF.
  FREE: lt_config.

ENDFUNCTION.
