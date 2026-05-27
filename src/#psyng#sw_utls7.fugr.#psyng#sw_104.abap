FUNCTION /psyng/sw_104.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      ET_DETAILS STRUCTURE  /PSYNG/SW_LEVEL3_DISPLAY OPTIONAL
*"      IT_DETAILS STRUCTURE  /PSYNG/SW_LEVEL3_DETAILS OPTIONAL
*"      IT_RFC STRUCTURE  RFCDES OPTIONAL
*"----------------------------------------------------------------------
* The IT_RFC table must contain the SYSIDMANDT concatenated in the
* RFCOPTIONS field, so the correct details can be read on the correct
* system !
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_104'.
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

  DATA : lt_dblog TYPE TABLE OF /psyng/dblog,
         lt_cdpos TYPE TABLE OF cdpos,
         lt_tabinfo TYPE TABLE OF /psyng/sw_level3_tabinfo
                    WITH HEADER LINE,
         lt_keys    TYPE TABLE OF /psyng/sw_level3_keys
                    WITH HEADER LINE,
         lt_details TYPE TABLE OF /psyng/sw_level3_details
                    WITH HEADER LINE,
         l_local    TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local.
  IF it_rfc[] IS INITIAL.
    it_rfc-rfcoptions = l_local.
    APPEND it_rfc.
  ENDIF.
*--Load details from respective systems
  LOOP AT it_rfc.
*--Process Change Documents
    REFRESH : lt_details.
    LOOP AT it_details WHERE system = it_rfc-rfcoptions AND
                             type EQ 'CHANGEDOC'.
      APPEND it_details TO lt_details.
    ENDLOOP.
    IF it_rfc-rfcoptions = l_local.
      CALL FUNCTION '/PSYNG/SW_105'
           TABLES
                et_table_info = lt_tabinfo
                et_table_keys = lt_keys
                et_cdpos      = lt_cdpos
                it_details    = lt_details.
    ELSE.
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
      CALL FUNCTION '/PSYNG/SW_105'
      DESTINATION it_rfc-rfcdest
        TABLES
          et_table_info       = lt_tabinfo
          et_table_keys       = lt_keys
          et_cdpos            = lt_cdpos
          it_details          = lt_details."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ENDIF.
    LOOP AT lt_details.
      PERFORM add_changedoc_data
        TABLES
          et_details
          lt_cdpos
          lt_tabinfo
          lt_keys
        USING lt_details.
    ENDLOOP.

*--Process Table Logging
    REFRESH : lt_details.
    LOOP AT it_details WHERE system = it_rfc-rfcoptions AND
                             type EQ 'TABLOG'.
      APPEND it_details TO lt_details.
    ENDLOOP.
    IF it_rfc-rfcoptions = l_local.
      CALL FUNCTION '/PSYNG/SW_106'
           TABLES
                et_table_info = lt_tabinfo
                et_table_keys = lt_keys
                et_dblog      = lt_dblog
                it_details    = lt_details.
    ELSE.
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
      CALL FUNCTION '/PSYNG/SW_106'
      DESTINATION it_rfc-rfcdest
        TABLES
                et_table_info = lt_tabinfo
                et_table_keys = lt_keys
                et_dblog      = lt_dblog
                it_details    = lt_details."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    ENDIF.
    LOOP AT lt_details.
      CONDENSE lt_details-logkey NO-GAPS.
      PERFORM add_tablog_data
        TABLES
          et_details
          lt_dblog
          lt_tabinfo
          lt_keys
        USING lt_details.
    ENDLOOP.
    FREE : lt_tabinfo, lt_keys,lt_dblog,lt_cdpos.
  ENDLOOP.
ENDFUNCTION.
