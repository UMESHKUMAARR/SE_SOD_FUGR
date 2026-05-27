FUNCTION /psyng/sw_ao_read_values.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(I_SETID) TYPE  /PSYNG/SECONFID OPTIONAL
*"     VALUE(I_SYSID) TYPE  /PSYNG/SYSID OPTIONAL
*"  EXPORTING
*"     VALUE(EF_SUCCESS) TYPE  FLAG
*"  TABLES
*"      ET_SWSODORGM STRUCTURE  /PSYNG/SWSODORGM
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"----------------------------------------------------------------------

  DATA :lf_cfg_set_enabled TYPE flag,
       lt_setvalues       TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
        lt_tobj            TYPE TABLE OF tobj WITH HEADER LINE,
        l_idx              LIKE sy-tabix,
        ls_configset       TYPE /psyng/swcfgset,
        lt_found_objects   type table of xuobject with header line,
        l_rfcdest type rfcdes-rfcdest.
  ef_success = 'X'.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' lf_cfg_set_enabled.
  IF lf_cfg_set_enabled = 'X' OR lf_cfg_set_enabled = 'Y'.
    lf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR lf_cfg_set_enabled.
  ENDIF.
  IF lf_cfg_set_enabled IS INITIAL.
*--Read the values of the /psyng/swsodorgm table
*  and don't use config set functionality
    SELECT * FROM /psyng/swsodorgm INTO TABLE et_swsodorgm.
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
*--Validate SYSID is provided
    IF i_sysid IS INITIAL.
      log et_return 'E' 'NO_SYSID'    'System ID is mandatory' ''
                                      '' ''.
      CLEAR ef_success.
    ENDIF.
    CHECK ef_success = 'X'.
*--Read the config set values, and apply to the SOD Matrix
    SELECT * FROM /psyng/swcfgoe INTO TABLE lt_setvalues
    WHERE
      setid  = i_setid AND
      sysid  = i_sysid AND
      active = 'X'.
    IF NOT lt_setvalues[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_AO_002'
           EXPORTING
                i_sodvrsio       = i_vrsio
           TABLES
                et_tobj          = lt_tobj
           EXCEPTIONS
                version_no_exist = 1
                OTHERS           = 2.
*BOC:HBHALLA (06/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
             WITH 'SOD Matrix version doesnt exist'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (06/12/24)
*---Start of Changes by GSINGH on 20.01.2023 P&G stored role issue for remote system(Case#22616) - Code Merge into SE 4.7
*---Read Auth objects from the remote system
       if lt_tobj[] is initial.
       select single rfcdest from /psyng/sw_rfcdes into
       l_rfcdest where systid = i_sysid.
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

       CALL FUNCTION '/PSYNG/SW_AO_002'
         destination l_rfcdest
           EXPORTING
                i_sodvrsio       = i_vrsio
           TABLES
                et_tobj          = lt_tobj
           EXCEPTIONS
                version_no_exist = 1
                SYSTEM_FAILURE = 2
                COMMUNICATION_FAILURE = 3
                OTHERS           = 4. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
       endif.
*----end of changes by GSINGH
      IF sy-subrc <> 0.
        CLEAR ef_success.
        CASE sy-subrc.
          WHEN 1.
            log et_return 'E' 'INVALID_MATRIX'
                              'SOD Matrix version'
                              i_vrsio 'does not exist' ''.
          WHEN 4.
            log et_return 'E' 'AUTO_ORG_ERROR'
                              'Error during applying set to sod Matrix'
                              i_vrsio '-' i_setid .
        ENDCASE.
      ENDIF.
      SORT lt_tobj BY fiel1.
      SORT lt_setvalues BY varbl.
*  --For each org value that is in the set,
*    create a record for each object that is in this SOD Matrix.
      LOOP AT lt_setvalues.
        MOVE-CORRESPONDING lt_setvalues TO et_swsodorgm.
        et_swsodorgm-low = lt_setvalues-value.
        READ TABLE lt_tobj WITH KEY fiel1 = lt_setvalues-varbl
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_idx = sy-tabix.

          LOOP AT lt_tobj FROM l_idx.
            IF lt_tobj-fiel1 <> lt_setvalues-varbl.
              EXIT.
            ENDIF.
            lt_found_objects = lt_tobj-objct.
            collect lt_found_objects.
            et_swsodorgm-object = lt_tobj-objct.
            APPEND et_swsodorgm.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
*--SE 4.3
*--If there is an object for which no values were added because there
*  are none (active) in the set, we still want to consider that object
*  org relevant
      sort lt_found_objects by table_line.
      loop at lt_tobj.
          read table lt_found_objects with key
            table_line = lt_tobj-objct
            binary search transporting no fields.
            if sy-subrc <> 0.
*--Add a value without an org abb for this object
              clear et_swsodorgm.
              et_swsodorgm-low    = lt_setvalues-varbl.
              et_swsodorgm-object = lt_tobj-objct.
              APPEND et_swsodorgm.
            endif.
      endloop.
    ELSE.
      log et_return 'W' 'NO_ORG_VALUES'
                     'No Org values found in set for this system'
                     i_setid '-' i_sysid .
    ENDIF.
  ENDIF.
ENDFUNCTION.
