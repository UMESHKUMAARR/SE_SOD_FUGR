FUNCTION /psyng/sw_ve_read.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(IF_READ) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ANALYZE) TYPE  FLAG OPTIONAL
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID
*"     VALUE(I_VAREL_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_INCLUDE_INACTIVE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_VALIDATE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_READ_TEXTS) TYPE  FLAG OPTIONAL
*"     VALUE(IF_SKIP_VALIDATE) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_VE_VALUES STRUCTURE  /PSYNG/SWCFGVE OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS OPTIONAL
*"      IT_ANALYZE_ELEMENTS STRUCTURE  /PSYNG/RANGE_SE_VAREL OPTIONAL
*"      IT_RFCDEST STRUCTURE  RFCDES OPTIONAL
*"      ET_TEXTS STRUCTURE  /PSYNG/SW_VE_VALUES_TEXT OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_VE_READ'.
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

  DATA : ls_configset TYPE /psyng/swcfgset,
         lf_cfg_set_enabled TYPE flag.
  ef_success = 'X'.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.

*--Validate the import parameters
  IF if_read = if_analyze OR ( if_read <> 'X' AND if_analyze <> 'X' ).
    log et_return 'E' 'PARAMETERS' 'Exactly one of the parameters'
                                   'IF_READ and IF_ANALYZE'
                                   'Should have the value X' ''.
    CLEAR ef_success.
  ENDIF.
*--Validate the set exists (if lf_cfg_set_enabled = X)
  IF if_skip_validate IS INITIAL.
    IF lf_cfg_set_enabled = 'X'.
      SELECT SINGLE * FROM /psyng/swcfgset INTO ls_configset
      WHERE setid = i_setid.
      IF sy-subrc <> 0.
        log et_return 'E' 'INVALID_SET' 'Configuration Set' i_setid
                                        'does not exist.'
                                        ''.
        CLEAR ef_success.
      ELSE.
        IF if_analyze = 'X' AND ls_configset-published = 'X'
        AND if_validate = ''.
          log et_return 'E' 'ALREADY_PUBLISHED'
                            'Analysis not allowed for Published Set'
                            '' '' ''.
          CLEAR ef_success.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  CHECK ef_success = 'X'.


  CASE 'X'.
    WHEN if_analyze.
**--Analyze the variable elements for this configuration set
      PERFORM analyze_ve_elements
        TABLES
          et_ve_values
          et_return
          it_systems
          it_analyze_elements
          it_rfcdest
        USING
          i_setid
          i_varel_vrsio
          if_include_inactive
        CHANGING
          ef_success.

    WHEN if_read.
*--read the stored variable element values for this configuration set
      PERFORM read_ve_elements
        TABLES
          et_ve_values
          et_return
        USING
          i_setid
        CHANGING
          ef_success.
  ENDCASE.
  IF if_read_texts = 'X'.
*--Return the labels for variable element fields that support it
    PERFORM get_varel_text
      TABLES
        et_ve_values
        et_texts
      USING
        i_setid.
  ENDIF.


ENDFUNCTION.
