FUNCTION /psyng/sw_ve_003.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(I_VAREL_VRSIO) TYPE  /PSYNG/VE_VRSIO
*"     REFERENCE(IF_LOCAL_CONFIG) TYPE  /PSYNG/BAPIFLAGX DEFAULT 'X'
*"     VALUE(IF_INCLUDE_INACTIVE) TYPE  FLAG OPTIONAL
*"  TABLES
*"      ET_RETURN STRUCTURE  BAPIRET2
*"      IT_ELEMENTS STRUCTURE  /PSYNG/RANGE_SE_VAREL
*"      ET_VALUES STRUCTURE  /PSYNG/SWCFGVE
*"      IT_SYSTEMS STRUCTURE  /PSYNG/SWCFGSYS
*"      IT_VAREL STRUCTURE  /PSYNG/SW_VAREL OPTIONAL
*"      IT_RFCDEST STRUCTURE  RFCDES OPTIONAL
*"----------------------------------------------------------------------

  DATA : lt_systems    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
         lt_sys_values TYPE TABLE OF /psyng/swcfgve,
         l_system_msg(80)  type c.

  IF NOT it_systems[] IS INITIAL.
    SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_systems
    FOR ALL ENTRIES IN it_systems WHERE
      systid = it_systems-sysid.
  ENDIF.
  IF lt_systems[] IS INITIAL.

*--Check if systems are provided in IT_RFCDEST table
    loop at it_systems.
      read table it_rfcdest with key rfcoptions = it_systems-sysid.
      if sy-subrc = 0.
        lt_systems-systid  = it_systems-sysid.
        lt_systems-rfcdest = it_rfcdest-rfcdest.
        append lt_systems.
      endif.
    endloop.
    IF lt_systems[] IS INITIAL.
      log et_return 'W' 'VAREL_NOSYSTEMS'
      'No systems defined' '' '' ''.
    ENDIF.
  ELSE.
*--Select variable elements rules
    IF if_local_config = 'X'.
    if not it_elements[] is initial.
      SELECT * FROM /psyng/sw_varel INTO TABLE it_varel
      WHERE varel_vrsio = i_varel_vrsio AND var_element IN it_elements.
      endif.
    ELSE.
*--Use it_varel as passed to FM
      DELETE it_varel WHERE NOT var_element  IN it_elements OR
                            varel_vrsio <>  i_varel_vrsio.
    ENDIF.
  ENDIF.
  IF it_varel[] IS INITIAL.
    log et_return 'W' 'VAREL_NORULES'
    'No Variable Elements rules defined' '' '' ''.

  ELSE.
*--Analyze the rules on all provided systems and merge the results
    LOOP AT lt_systems.
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
      CALL FUNCTION '/PSYNG/SW_VE_002'
      DESTINATION lt_systems-rfcdest
       EXPORTING
*       I_VRSIO                    =
*       I_VAREL_VRSIO              =
*       I_SYSID                    =
*       IF_LOCAL_CONFIG            = ''
         if_ignore_sod_matrix       = 'X'
         IF_INCLUDE_INACTIVE      = IF_INCLUDE_INACTIVE
       TABLES
*       IT_FAOBJ2                  =
         et_return                  = et_return
         it_varel                   = it_varel
         et_values                  = lt_sys_values
       exceptions
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      if sy-subrc <> 0.
        log et_return 'W' 'VAREL_RFC_FAILED'
        'Unable to analyze variable element rules on '
        lt_systems-rfcdest ':' l_system_msg.
      endif.
      APPEND LINES OF lt_sys_values TO et_values.
      REFRESH : lt_sys_values.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
