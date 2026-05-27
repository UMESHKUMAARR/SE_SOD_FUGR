*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_157_CREATE_CONFIGF01.
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  CREATE_CONFIG_SET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_config_set .
  DATA : lt_sysrfc        TYPE TABLE OF ty_system,
         l_varel_version  TYPE /psyng/param_value,
         l_varel_version1 TYPE /psyng/sodvrsio,
         l_sod_version    TYPE /psyng/swsodvers-vrsio,
         lt_systems       TYPE TABLE OF /psyng/swcfgsys,
         lt_org_values    TYPE TABLE OF /psyng/swcfgoe,
         ls_org_values    TYPE /psyng/swcfgoe,
         lt_ve_values     TYPE TABLE OF /psyng/swcfgve,
         ls_ve_values     TYPE /psyng/swcfgve,
         lt_ao_list       TYPE TABLE OF /psyng/sw_ao_list,
         lt_ao_list_sel   TYPE TABLE OF /psyng/sw_ao_list,
         ls_ao_list       TYPE /psyng/sw_ao_list,
         lt_ve_list       TYPE TABLE OF /psyng/sw_ve_list,
         ls_ve_list       TYPE /psyng/sw_ve_list,
         lf_success       TYPE flag,
         lt_selections    TYPE TABLE OF /psyng/swcfsel,
         ls_selections    TYPE /psyng/swcfsel,
         lt_org_element   TYPE TABLE OF /psyng/swcfgoe,
         ls_org_element   TYPE /psyng/swcfgoe,
         lt_ve_element    TYPE TABLE OF /psyng/swcfgve,
         ls_ve_element    TYPE /psyng/swcfgve,
         lr_varel         TYPE TABLE OF /psyng/range_se_varel,
         ls_varel         TYPE /psyng/range_se_varel,
         ls_s_system      LIKE LINE OF s_system,
         ls_system        LIKE LINE OF lt_sysrfc,
*        ls_s_system LIKE LINE OF lt_sysrfc,
         ls_sw_rfcdes     TYPE /psyng/sw_rfcdes,
         lt_sw_rfcdes     TYPE TABLE OF /psyng/sw_rfcdes,
         ls_systems1      TYPE /psyng/swcfgsys,
         l_configset      TYPE /psyng/seconfid,
         l_configsetname  TYPE /psyng/longtextfield,
         l_mess           LIKE sy-uline,
         lt_lpc_values    TYPE TABLE OF /psyng/sw_cfgset_read_values
              WITH HEADER LINE,
         l_lpc_name       TYPE /psyng/longtextfield,
         l_lpc_id         TYPE /psyng/seconfid,
         ls_header        TYPE /psyng/swcfgset,
         lf_valid         TYPE c,
         l_sysid          TYPE c LENGTH 6,
         l_str            TYPE string,
         l_invalid_vrsio  TYPE flag,
         l_no_cfgset_exist TYPE flag.

*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
  DATA : lv_dflt_sod_vers       TYPE /psyng/swsodvers-vrsio,
          lv_dflt_sod_vers_f    TYPE /psyng/swsodvers-vrsio,
          lv_dflt_lpc_name      TYPE /psyng/longtextfield,
          lv_dflt_lpc_id        TYPE /psyng/seconfid,
          ls_dflt_header        TYPE /psyng/swcfgset,
          lt_dflt_selections    TYPE TABLE OF /psyng/swcfsel,
          ls_dflt_selections    TYPE /psyng/swcfsel,
    lt_dflt_lpc_values          TYPE TABLE OF
                                     /psyng/sw_cfgset_read_values
                                     WITH HEADER LINE,
    lv_dflt_varel_vers          TYPE /psyng/param_value,
    lv_dflt_varel_vers1         TYPE /psyng/sodvrsio,
    lt_dflt_ao_list             TYPE TABLE OF /psyng/sw_ao_list,
    lt_dflt_ao_list_sel         TYPE TABLE OF /psyng/sw_ao_list,
    ls_dflt_ao_list             TYPE /psyng/sw_ao_list,
    lt_dflt_ve_list             TYPE TABLE OF /psyng/sw_ve_list,
    ls_dflt_ve_list             TYPE /psyng/sw_ve_list,
    lv_dflt_invalid_vrsio       TYPE flag,
    lv_dflt_no_cfgset_exist     TYPE flag.
  DATA : lt_final_selec LIKE lt_selections,
               lv_flag TYPE flag.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

  CONSTANTS : lc_dflt_varel_version TYPE /psyng/param
                                   VALUE 'DFLT_VAREL_VERSION'.

*--Getting rfc destination for system
  SELECT  *
                FROM /psyng/sw_rfcdes
                INTO TABLE lt_sw_rfcdes
                WHERE systid IN s_system.
  IF sy-subrc = 0.
    LOOP AT lt_sw_rfcdes INTO ls_sw_rfcdes.
      ls_system-sysid = ls_sw_rfcdes-systid.
      ls_system-rfcdest = ls_sw_rfcdes-rfcdest.
      APPEND ls_system TO lt_sysrfc.
      CLEAR ls_sw_rfcdes.
    ENDLOOP.
  ELSE.
    MESSAGE s137 WITH  'System is not maintained'(i02)
                              ' in RFC Destinations.'(i03).

    LEAVE LIST-PROCESSING.
  ENDIF.

*---Traversing each system
  LOOP AT lt_sysrfc INTO ls_system.
    msg 'Analysis Started for'(o01) ls_system-sysid '' '' .
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
* ---check for latest published configset from remote system
    CALL FUNCTION '/PSYNG/SW_CONFIGSET_SAVE'
      DESTINATION ls_system-rfcdest
      EXPORTING
        i_configset_read      = 'X'
        i_read_modified_only  = pf_trsfr
        i_read_selections     = 'X'
        i_versio              = sodvrsio
        i_global_dflt_sod     = pf_dflt
      IMPORTING
        e_configset           = l_lpc_id
        e_configset_name      = l_lpc_name
        e_configsethdr        = ls_header
         e_invalid_vrsio       = l_invalid_vrsio
        e_sod_version         = l_sod_version
        e_no_cfgset_exist     = l_no_cfgset_exist
      TABLES
        et_configset          = lt_lpc_values
        et_selections         = lt_selections
      EXCEPTIONS
        resource_failure      = 1
        communication_failure = 2 MESSAGE l_mess
        system_failure        = 3 MESSAGE l_mess
        OTHERS                = 4.               "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
      alv_logs ls_system l_mess '' ''.
    ENDIF.

*---Opl 594
    IF l_invalid_vrsio = 'X'.
      alv_logs ls_system-sysid 'Invalid SOD version'(e12)
              '' l_sod_version.
      ADD 1 TO g_error_systems.
    ENDIF.
*--- Opl 600 27/10/2023 ODUBEY
    IF l_no_cfgset_exist = 'X' AND
     ( NOT pf_trsfr IS INITIAL OR NOT pf_cpyl IS INITIAL ).
      alv_logs ls_system-sysid
   'No ConfigSet exist that can be taken as source'(e13)
              '' l_sod_version.
      ADD 1 TO g_error_systems.
    ENDIF.

*---Opl 600 odubey 18/01/24
    IF l_no_cfgset_exist = 'X' AND
    pf_trsfr IS INITIAL AND  pf_cpyl IS INITIAL.
*----clear the field as nothig to copy from source
      CLEAR l_no_cfgset_exist.
    ENDIF.
*-- End
    IF l_invalid_vrsio IS INITIAL AND
       l_no_cfgset_exist IS INITIAL. "Opl600
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
*--Default varel version on target system
      CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
        DESTINATION ls_system-rfcdest
        EXPORTING
          i_parameter           = lc_dflt_varel_version
        IMPORTING
          e_value               = l_varel_version
        EXCEPTIONS
          resource_failure      = 1
          communication_failure = 2 MESSAGE l_mess
          system_failure        = 3 MESSAGE l_mess
          OTHERS                = 4.             "#EC SAST_CI_GEN_CHECK

      IF sy-subrc <> 0.
        MESSAGE w002(/psyng/sw) WITH
        'Error Reading configuration parameter '(000)
  lc_dflt_varel_version.
      ELSE.
*--Get maintained variable elements for rule version
        l_varel_version1 = l_varel_version.
      ENDIF.

*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
      IF p_inval IS INITIAL.
        "As p_inval checkbox is un-selected, so fetch all org level
        "values of Default SOD version and keep it handy.
        "from selection screen.
        CLEAR lv_dflt_sod_vers.
        "Fetch default SOD Version number
        CALL FUNCTION '/PSYNG/SW_131'
         DESTINATION ls_system-rfcdest
         EXPORTING
            i_globle_vrsio        = 'X'
         IMPORTING
           e_sod_version          = lv_dflt_sod_vers
           e_valid                = lf_valid
         EXCEPTIONS
           resource_failure      = 1
           communication_failure = 2 MESSAGE l_mess
           system_failure        = 3 MESSAGE l_mess
           OTHERS                = 4.            "#EC SAST_CI_GEN_CHECK

        "Fetch latest publish cfg set id for default SOD version found
        "above and also modifications within.
        CALL FUNCTION '/PSYNG/SW_CONFIGSET_SAVE'
            DESTINATION ls_system-rfcdest
            EXPORTING
              i_configset_read      = 'X'
              i_read_modified_only  = pf_trsfr
              i_read_selections     = 'X'
              i_versio              = lv_dflt_sod_vers
              i_global_dflt_sod     = pf_dflt
            IMPORTING
              e_configset           = lv_dflt_lpc_id
              e_configset_name      = lv_dflt_lpc_name
              e_configsethdr        = ls_dflt_header
              e_invalid_vrsio       = lv_dflt_invalid_vrsio
              e_sod_version         = lv_dflt_sod_vers_f
              e_no_cfgset_exist     = lv_dflt_no_cfgset_exist
            TABLES
              et_configset          = lt_lpc_values
              et_selections         = lt_dflt_selections
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
              OTHERS                = 4.         "#EC SAST_CI_GEN_CHECK

*--Fetch Default varel version on target system
        CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
          DESTINATION ls_system-rfcdest
          EXPORTING
            i_parameter           = lc_dflt_varel_version
          IMPORTING
            e_value               = lv_dflt_varel_vers
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
            OTHERS                = 4.           "#EC SAST_CI_GEN_CHECK

        IF sy-subrc <> 0.
          MESSAGE w002(/psyng/sw) WITH
          'Error Reading configuration parameter '(000)
          lc_dflt_varel_version.
        ELSE.
*--Get maintained variable elements for rule version
          lv_dflt_varel_vers1 = lv_dflt_varel_vers.
        ENDIF.
      ELSE.
        "As p_inval checkbox is selected, so now we have to copy all
        "org level values of Default SOD version to given SOD version
        "from selection screen.
        IF  l_lpc_id IS INITIAL.
          "LPC ID initial means there is no published config set
          CLEAR l_sod_version.
          CALL FUNCTION '/PSYNG/SW_131'
            DESTINATION ls_system-rfcdest
            EXPORTING
               i_globle_vrsio        = 'X'
            IMPORTING
              e_sod_version          = l_sod_version
              e_valid                = lf_valid
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
             OTHERS                 = 4.         "#EC SAST_CI_GEN_CHECK

          CALL FUNCTION '/PSYNG/SW_CONFIGSET_SAVE'
              DESTINATION ls_system-rfcdest
              EXPORTING
                i_configset_read      = 'X'
                i_read_modified_only  = pf_trsfr
                i_read_selections     = 'X'
                i_versio              = l_sod_version
                i_global_dflt_sod     = pf_dflt
              IMPORTING
                e_configset           = l_lpc_id
                e_configset_name      = l_lpc_name
                e_configsethdr        = ls_header
                e_invalid_vrsio       = l_invalid_vrsio
                e_sod_version         = l_sod_version
                e_no_cfgset_exist     = l_no_cfgset_exist
              TABLES
                et_configset          = lt_lpc_values
                et_selections         = lt_selections
              EXCEPTIONS
                resource_failure      = 1
                communication_failure = 2 MESSAGE l_mess
                system_failure        = 3 MESSAGE l_mess
               OTHERS                = 4.        "#EC SAST_CI_GEN_CHECK

        ENDIF.
      ENDIF.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025


      IF  l_lpc_id IS INITIAL.
        IF NOT pf_dflt IS INITIAL.
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
*--Default SOD version on target system
          CALL FUNCTION '/PSYNG/SW_131'
            DESTINATION ls_system-rfcdest
            EXPORTING
               i_globle_vrsio        = 'X'
            IMPORTING
              e_sod_version          = l_sod_version
               e_valid               = lf_valid
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
             OTHERS                = 4.          "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
              WHEN 2.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 3.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
          IF lf_valid IS INITIAL.
            CLEAR l_str.
            ADD 1 TO g_error_systems.
            l_sysid = ls_system-sysid.
            CONCATENATE 'Version:' l_sod_version
            INTO l_str SEPARATED BY space.

            alv_logs l_sysid
            'not allowed for creation of ConfigSet'(k14)
             '' l_sod_version.
            CONCATENATE l_str 'in' l_sysid
          'is not allowed for creation of ConfigSet'(k01) INTO
          l_str.
            msg l_str '' l_sysid  '' .
            CLEAR l_str.
          ENDIF.
          CHECK lf_valid = 'X'.
        ENDIF.

*--if something entered in remote version
        IF pf_dflt IS INITIAL.
          l_sod_version = sodvrsio.
        ENDIF.

*---if latest published configset doesnot exist
        IF l_lpc_id IS INITIAL.
          REFRESH lt_selections.
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
*--Get maintained org elements for SOD version
        CALL FUNCTION '/PSYNG/SW_AO_002'
          DESTINATION ls_system-rfcdest
          EXPORTING
            i_sodvrsio            = l_sod_version
          TABLES
            et_list               = lt_ao_list
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
           OTHERS                = 4.            "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.

        CALL FUNCTION '/PSYNG/SW_VE_LIST'
          DESTINATION ls_system-rfcdest
          EXPORTING
            i_varel_vrsio         = l_varel_version1
            i_sodvrsio            = l_sod_version
            if_parse_matrix       = 'X'
          TABLES
            et_variable_elements  = lt_ve_list
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
           OTHERS                = 4.            "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

*--Selected org elements and variable elements
        LOOP AT lt_ao_list INTO ls_ao_list.
          ls_org_element-varbl = ls_ao_list-varbl.
          APPEND ls_org_element TO lt_org_element.
          CLEAR  ls_org_element.

          ls_selections-type = 'ORG'.
          ls_selections-varbl = ls_ao_list-field.
          ls_selections-sel = ls_ao_list-selected.
          APPEND ls_selections TO lt_selections.
          CLEAR: ls_selections,ls_ao_list.
        ENDLOOP.

        LOOP AT lt_ve_list INTO ls_ve_list.
          ls_ve_element-var_element = ls_ve_list-var_element.
          APPEND ls_ve_element TO lt_ve_element.
          CLEAR ls_ve_element.

          ls_selections-type = 'VE'.
          ls_selections-varbl = ls_ve_list-var_element.
          ls_selections-sel = ls_ve_list-selected.
          APPEND ls_selections TO lt_selections.
          CLEAR : ls_selections, ls_ve_list.
        ENDLOOP.

*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
*--Get maintained org elements for default SOD version
        IF p_inval IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_AO_002'
            DESTINATION ls_system-rfcdest
            EXPORTING
              i_sodvrsio            = lv_dflt_sod_vers_f
            TABLES
              et_list               = lt_dflt_ao_list
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
            OTHERS                = 4.           "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
              WHEN 2.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 3.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.

          CALL FUNCTION '/PSYNG/SW_VE_LIST'
            DESTINATION ls_system-rfcdest
            EXPORTING
              i_varel_vrsio         = lv_dflt_varel_vers1
              i_sodvrsio            = lv_dflt_sod_vers_f
              if_parse_matrix       = 'X'
            TABLES
              et_variable_elements  = lt_dflt_ve_list
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
            OTHERS                = 4.           "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
              WHEN 2.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 3.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
        ENDIF.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

      ELSE.

        IF NOT pf_dflt IS INITIAL.
*--Default SOD version on target system
          CALL FUNCTION '/PSYNG/SW_131'
            DESTINATION ls_system-rfcdest
              EXPORTING
               i_globle_vrsio       = 'X'
            IMPORTING
              e_sod_version         = l_sod_version
              e_valid               = lf_valid
            EXCEPTIONS
              resource_failure      = 1
              communication_failure = 2 MESSAGE l_mess
              system_failure        = 3 MESSAGE l_mess
             OTHERS                = 4.          "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
              WHEN 2.
                MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
              WHEN 3.
                MESSAGE s002(/psyng/sw) WITH 'System failure'.
              WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
            ENDCASE.
          ENDIF.
          IF lf_valid IS INITIAL.
            ADD 1 TO g_error_systems.
            CLEAR l_str.
            l_sysid = ls_system-sysid.
            CONCATENATE 'Version:' l_sod_version
            INTO l_str SEPARATED BY space.
*          MESSAGE s002(/psyng/sw) WITH
*            l_str 'in' l_sysid
*            'is not allowed for creation of ConfigSet'(k01).
            alv_logs l_sysid
            'not allowed for creation of ConfigSet'(k14)
             '' l_sod_version.

            CONCATENATE l_str 'in' l_sysid
            'is not allowed for creation of ConfigSet'(k01) INTO
            l_str.
            msg l_str '' l_sysid  '' .
            CLEAR l_str.
          ENDIF.
          CHECK lf_valid = 'X'.
        ELSE.
          l_sod_version = sodvrsio.
        ENDIF.

        LOOP AT lt_selections INTO ls_selections.
          CASE ls_selections-type.
            WHEN 'ORG'.
              ls_ao_list-field = ls_selections-varbl.
              ls_ao_list-selected = ls_selections-sel.
              APPEND ls_ao_list TO lt_ao_list.

            WHEN 'VE'.
              ls_ve_list-var_element = ls_selections-varbl.
              ls_ve_list-selected = ls_selections-sel.
              APPEND ls_ve_list TO lt_ve_list.

          ENDCASE.
        ENDLOOP.
*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

        IF p_inval EQ space.
          LOOP AT lt_dflt_selections INTO ls_dflt_selections.
            CASE ls_dflt_selections-type.
              WHEN 'ORG'.
                ls_dflt_ao_list-field = ls_dflt_selections-varbl.
                ls_dflt_ao_list-selected = ls_dflt_selections-sel.
                APPEND ls_dflt_ao_list TO lt_dflt_ao_list.

              WHEN 'VE'.
                ls_dflt_ve_list-var_element = ls_dflt_selections-varbl.
                ls_dflt_ve_list-selected = ls_dflt_selections-sel.
                APPEND ls_dflt_ve_list TO lt_dflt_ve_list.

            ENDCASE.
          ENDLOOP.
        ENDIF.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

      ENDIF.


*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
*---- as p_inval checkbox is unselected so we have to match org level
*---- data for dflt and non dflt SOD version.
    IF l_lpc_id IS INITIAL.
      IF p_inval IS INITIAL.
        CLEAR  lt_final_selec[].
        lt_final_selec[] = lt_selections[].
        CLEAR : ls_selections,
                ls_dflt_selections.
        LOOP AT lt_selections INTO ls_selections.
          READ TABLE lt_dflt_selections INTO ls_dflt_selections
           WITH KEY type = ls_selections-type
                    varbl = ls_selections-varbl
                    sel   = ls_selections-sel.
          "If data mismatch, exit the code with error
          IF sy-subrc NE 0.
            lv_flag = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

      IF lv_flag EQ 'X'.
        alv_logs ls_system-sysid
                  'Org Level Data Mismatch'(o05)
                      ''   l_sod_version.
        alv_logs ls_system-sysid
                  'Configuration Set not created'(o06)
                      ''   l_sod_version.
        CONTINUE.
      ENDIF.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

      REFRESH lt_systems.
      ls_systems1-sysid = ls_system-sysid.
      APPEND ls_systems1 TO lt_systems.
*---combine all system in each set
      IF pf_cmbn = 'X'.
        msg 'Combining all systems'(o02) '' '' '' .
        LOOP AT s_system INTO ls_s_system.
          ls_systems1-sysid = ls_s_system-low.
          APPEND ls_systems1 TO lt_systems.
        ENDLOOP.
      ENDIF.

*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
      IF l_lpc_id IS INITIAL.
*      IF p_inval IS INITIAL.
*--Analyze org elements for default SOD verison
        lt_ao_list_sel[] = lt_dflt_ao_list[].
        CALL FUNCTION '/PSYNG/SW_AO_READ'
        DESTINATION ls_system-rfcdest
        EXPORTING
          if_analyze            = 'X'
*        i_setid               = 0
          if_validate           = 'X'
         i_skip_validate     = 'X'
        TABLES
          et_org_values         = lt_org_values
          it_analyze_elements   = lt_ao_list_sel
          it_systems            = lt_systems
        EXCEPTIONS
          resource_failure      = 1
          communication_failure = 2 MESSAGE l_mess
          system_failure        = 3 MESSAGE l_mess
         OTHERS                = 4.              "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.

        LOOP AT lt_dflt_ve_list INTO ls_dflt_ve_list WHERE
          selected ='X'.
          ls_varel-sign = 'I'.
          ls_varel-option = 'EQ'.
          ls_varel-low = ls_dflt_ve_list-var_element.
          APPEND ls_varel TO lr_varel.
          CLEAR ls_varel.
        ENDLOOP.

*--Analyze variable elements
        CALL FUNCTION '/PSYNG/SW_VE_READ'
          DESTINATION ls_system-rfcdest
          EXPORTING
            if_analyze            = 'X'
            i_varel_vrsio         = lv_dflt_varel_vers1
            i_setid               = 0
            if_include_inactive   = 'X'
            if_validate           = 'X'
            if_skip_invalate      = 'X'
          TABLES
            et_ve_values          = lt_ve_values
            it_systems            = lt_systems
            it_analyze_elements   = lr_varel
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
          OTHERS                = 4.             "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.
      ELSE.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

*--Analyze org elements
        lt_ao_list_sel[] = lt_ao_list[].
        CALL FUNCTION '/PSYNG/SW_AO_READ'
          DESTINATION ls_system-rfcdest
          EXPORTING
            if_analyze            = 'X'
*        i_setid               = 0
            if_validate           = 'X'
           i_skip_validate     = 'X'
          TABLES
            et_org_values         = lt_org_values
            it_analyze_elements   = lt_ao_list_sel
            it_systems            = lt_systems
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
          OTHERS                = 4.             "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

        LOOP AT lt_ve_list INTO ls_ve_list WHERE
          selected ='X'.
          ls_varel-sign = 'I'.
          ls_varel-option = 'EQ'.
          ls_varel-low = ls_ve_list-var_element.
          APPEND ls_varel TO lr_varel.
          CLEAR ls_varel.
        ENDLOOP.

*--Analyze variable elements
        CALL FUNCTION '/PSYNG/SW_VE_READ'
          DESTINATION ls_system-rfcdest
          EXPORTING
            if_analyze            = 'X'
            i_varel_vrsio         = l_varel_version1
            i_setid               = 0
            if_include_inactive   = 'X'
            if_validate           = 'X'
            if_skip_invalate      = 'X'
          TABLES
            et_ve_values          = lt_ve_values
            it_systems            = lt_systems
            it_analyze_elements   = lr_varel
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
          OTHERS                = 4.             "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE s002(/psyng/sw) WITH 'Resource Failure'.
            WHEN 2.
              MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
            WHEN 3.
              MESSAGE s002(/psyng/sw) WITH 'System failure'.
            WHEN OTHERS.
              MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
        ENDIF.
      ENDIF. "(++)UMITTAL BOSCH : Tfr cfg set 11/11/2025
*----transfer values
      IF pf_trsfr = 'X'.
        msg 'Performing transfer values'(o03) '' '' '' .
        LOOP AT lt_lpc_values.
          CASE lt_lpc_values-type.
*----When Last published config set value is for an ORG element

            WHEN 'ORG'.
              MOVE-CORRESPONDING lt_lpc_values TO ls_org_element.
              ls_org_element-varbl = lt_lpc_values-var_element.
*----When element is active in last changed published config set

              CASE lt_lpc_values-active.
                WHEN 'X'.
*----Read the Org Values table, if the Value is not Active then Modify
* the fields to MODIFIED= 'X' and ACTIVE = 'X'.
                  READ TABLE lt_org_values INTO ls_org_values WITH KEY
                                       sysid = lt_lpc_values-sysid
                                       abb = lt_lpc_values-abb
                                     varbl = lt_lpc_values-var_element
                                     value = lt_lpc_values-value.
                  IF sy-subrc = 0 AND ls_org_values-active <> 'X'.
                   MODIFY lt_org_values FROM ls_org_element TRANSPORTING
                                        active  modified WHERE
                                        sysid = ls_org_element-sysid AND
                                        abb   = ls_org_element-abb AND
                                        varbl = ls_org_element-varbl AND
                                     value = ls_org_element-value.
*----Else Add the records to the Org Values table
                  ELSEIF sy-subrc <> 0.
                    APPEND ls_org_element TO lt_org_values.
                  ENDIF.
*----When element is not active in last changed published config set
                WHEN OTHERS.
*----Read the VE table, if the Value present then Modify the fields to
* MODIFIED= 'X' and ACTIVE = ''.
                  READ TABLE lt_org_values WITH KEY
                                       sysid = lt_lpc_values-sysid
                                       abb = lt_lpc_values-abb
                                   varbl = lt_lpc_values-var_element
                                   value = lt_lpc_values-value
                                   TRANSPORTING NO FIELDS.
                  IF sy-subrc = 0.
                   MODIFY lt_org_values FROM ls_org_element TRANSPORTING
                                         active  modified WHERE
                                        sysid = ls_org_element-sysid AND
                                        abb   = ls_org_element-abb AND
                                        varbl = ls_org_element-varbl AND
                                        value = ls_org_element-value.
                  ENDIF.
              ENDCASE.
*----When Last published config set value is for a Variable element

            WHEN OTHERS.
              MOVE-CORRESPONDING lt_lpc_values TO ls_ve_element.
              ls_ve_element-var_element = lt_lpc_values-var_element.
              CASE lt_lpc_values-active.
*----When element is active in last changed published config set

                WHEN 'X'.
*----Read the VE table,if the Value is not Active then Modify the fields
* to MODIFIED= 'X' and ACTIVE = 'X'
                  READ TABLE lt_ve_values INTO ls_ve_values WITH KEY
                                     sysid = lt_lpc_values-sysid
                             var_element = lt_lpc_values-var_element
                             value = lt_lpc_values-value.

                  IF sy-subrc = 0 AND ls_ve_values-active <> 'X'.
                    MODIFY lt_ve_values FROM ls_ve_element TRANSPORTING
                                             active  modified WHERE
                                       sysid = ls_ve_element-sysid AND
                           var_element = ls_ve_element-var_element  AND
                                 value = ls_ve_element-value.
*----Else Add the records to the Variable elements(VE) table

                  ELSEIF sy-subrc <> 0.
                    APPEND ls_ve_element TO lt_ve_values.
                  ENDIF.
*----Read the VE table, if the Value present then Modify the fields to
* MODIFIED = 'X' and ACTIVE = ''.
                WHEN OTHERS.
                  READ TABLE lt_ve_values WITH KEY
                                   sysid = lt_lpc_values-sysid
                             var_element = lt_lpc_values-var_element
                             value = lt_lpc_values-value
                             TRANSPORTING NO FIELDS.
                  IF sy-subrc = 0.
                    MODIFY lt_ve_values FROM ls_ve_element TRANSPORTING
                                                 active  modified WHERE
                                        sysid = ls_ve_element-sysid AND
                           var_element = ls_ve_element-var_element  AND
                                 value = ls_ve_element-value.
                  ENDIF.
              ENDCASE.
          ENDCASE.
        ENDLOOP.
      ENDIF.
*---configset description
      IF pf_cpyl IS INITIAL.
        l_lpc_name = p_desc.
      ENDIF.

*-----create configset
     IF pf_tstmd IS INITIAL." Adding Test mode check before creating the
*                             actual Config Set

        CALL FUNCTION '/PSYNG/SW_CONFIGSET_SAVE'
          DESTINATION ls_system-rfcdest
          EXPORTING
            i_save_header         = 'X'
            if_save_system        = 'X'
            if_save_selection     = 'X'
            if_save_oe            = 'X'
            if_save_ve            = 'X'
            if_publish            = pf_pbset
            if_description        = ''
            i_desc                = l_lpc_name
            i_versio              = l_sod_version
*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
            i_global_dflt_sod     = pf_dflt
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
          IMPORTING
            ef_success            = lf_success
            e_configset           = l_configset
            e_configset_name      = l_configsetname
          TABLES
            it_ve_element         = lt_ve_values
            it_selections         = lt_selections
            it_systems            = lt_systems
            it_org_element        = lt_org_values
          EXCEPTIONS
            resource_failure      = 1
            communication_failure = 2 MESSAGE l_mess
            system_failure        = 3 MESSAGE l_mess
           OTHERS                = 4.            "#EC SAST_CI_GEN_CHECK
        CASE sy-subrc.
          WHEN '0'.
            IF NOT lf_success IS INITIAL.
              msg  l_configset ':' l_configsetname '' .

              gt_logs-system = ls_system-sysid.
              gt_logs-message = l_configsetname.
              gt_logs-setid = l_configset.
              gt_logs-sodvrsio  = l_sod_version.
              APPEND gt_logs.
            ENDIF.
          WHEN '1' OR '2' OR '3'.
            alv_logs ls_system-sysid l_mess ''
                        l_sod_version.
        ENDCASE.
        IF lf_success IS INITIAL.
          msg 'You are not authorized to create Configset'(e14)
           '' '' '' .
          alv_logs ls_system-sysid
                 'You are not authorized to create Configset'(e14)
                     ''   l_sod_version.
          ADD 1 TO g_error_systems.
        ENDIF.
      ENDIF.

*--C1059 add logs 28/06/2023 Odubey
      IF NOT pf_tstmd IS INITIAL AND p_log = 'X'.
        gt_logs-system = ls_system-sysid.
        gt_logs-message = l_configsetname.
        gt_logs-sodvrsio = l_sod_version.
        gt_logs-setid  = l_configset.
        IF gt_logs-message IS INITIAL.
          gt_logs-message = l_lpc_name.
        ENDIF.
        APPEND gt_logs.
      ENDIF.
*---end

*--collect all org  values in output table

      LOOP AT lt_org_values INTO ls_org_element.
        gt_output-target_sysid = ls_system-sysid.
        gt_output-system = ls_org_element-sysid.
        gt_output-setid = l_configset.
* Display latest published Config Set name or eneterd desc. in Test Mode
        IF pf_tstmd IS INITIAL.
          gt_output-description = l_configsetname.
        ELSE.
          gt_output-description = l_lpc_name.
        ENDIF.
        gt_output-type = 'ORG'.
        gt_output-name = ls_org_element-abb.
        gt_output-field = ls_org_element-varbl.
        gt_output-value = ls_org_element-value.
        gt_output-active = ls_org_element-active.
        gt_output-modified = ls_org_element-modified.
        APPEND gt_output.
        CLEAR gt_output.
      ENDLOOP.


*-- collect all ve values in output table
      LOOP AT lt_ve_values INTO ls_ve_element.
        gt_output-target_sysid = ls_system-sysid.
        gt_output-system = ls_ve_element-sysid.
        gt_output-setid = l_configset.
* Display latest published Config Set name or eneterd desc. in Test Mode
        IF pf_tstmd IS INITIAL.
          gt_output-description = l_configsetname.
        ELSE.
          gt_output-description = l_lpc_name.
        ENDIF.
        gt_output-type = 'VE'.
        gt_output-name = ls_ve_element-var_element.
        gt_output-value = ls_ve_element-value.
        gt_output-active = ls_ve_element-active.
        gt_output-modified = ls_ve_element-modified.
        APPEND gt_output.
        CLEAR gt_output.
      ENDLOOP.
*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025

      IF lt_org_values[] IS INITIAL AND
         lt_ve_values[] IS INITIAL.
        gt_logs-system   = ls_system-sysid.
        gt_logs-message  = l_configsetname.
        gt_logs-sodvrsio = l_sod_version.
        gt_logs-setid    = l_configset.
        gt_logs-message = 'No ORG Level Values Copied'(o14).

        APPEND gt_logs.
      ENDIF.
*EOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
      IF lf_success IS INITIAL AND pf_tstmd IS INITIAL.
        REFRESH gt_output.
      ENDIF.
      msg 'End analysis for'(o04)  ls_system-sysid '' '' .
*---after processing 1 system old data should be free
      FREE: lt_ve_values, lt_ao_list, lt_selections, lt_systems,
            lt_org_values, lt_lpc_values.
    ENDIF.
    CLEAR l_invalid_vrsio.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_AND_DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_and_display_alv .
  DATA: ls_variant     TYPE disvariant,
        alv_layout     TYPE slis_layout_alv,
        i_fieldcat_alv TYPE slis_t_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
        l_program       LIKE sy-repid.
  alv_layout-zebra = 'X'.
  l_program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = l_program
      i_internal_tabname = 'GT_OUTPUT'
      i_inclname         = l_program
    CHANGING
      ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

*----Customize fieldcat
  DEFINE modify_labels.
    wa_fieldcat_alv-seltext_l = &1.
    wa_fieldcat_alv-seltext_m = &1.
    wa_fieldcat_alv-seltext_s = &1.
    wa_fieldcat_alv-outputlen = &3.
    modify i_fieldcat_alv from wa_fieldcat_alv
    TRANSPORTING outputlen seltext_l seltext_m seltext_s
        where fieldname = &2.
  END-OF-DEFINITION.

  LOOP AT i_fieldcat_alv INTO wa_fieldcat_alv.
    CASE wa_fieldcat_alv-fieldname.
      WHEN 'TARGET_SYSID'.
        modify_labels 'Target System ID'(l01) 'TARGET_SYSID' 15.
      WHEN 'SYSTEM'.
        modify_labels 'Source System ID'(l02) 'SYSTEM' 15.
 "B17179 - Changing the header as per Config Set Details table by GSINGH
      WHEN 'SETID'.
        modify_labels 'Config Set ID'(l03) 'SETID' 15.
      WHEN 'DESCRIPTION'.
        modify_labels 'Config Set Name'(l04) 'DESCRIPTION' 40.
      WHEN 'TYPE'.
        modify_labels 'Type'(l05) 'TYPE' 4.
      WHEN 'NAME'.
        modify_labels 'Name'(l06) 'NAME' 15.
      WHEN 'FIELD'.
        modify_labels 'Field'(l07) 'FIELD' 10.
        wa_fieldcat_alv-reptext_ddic = 'Field'(l07).
        MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
        TRANSPORTING reptext_ddic WHERE fieldname = 'FIELD'.
 "B17179 - Changing the header as per Config Set Details table by gsingh
      WHEN 'VALUE'.
        modify_labels 'Value'(l08) 'VALUE' 10.
      WHEN 'ACTIVE'.
*        modify_labels 'Ative'(l09) 'ACTIVE' 10.
        modify_labels 'Active'(l09) 'ACTIVE' 10.
        "B17179 - Spellings correction of Active by GSINGH
      WHEN 'MODIFIED'.
        modify_labels 'Modified'(l10) 'MODIFIED' 10.
    ENDCASE.
  ENDLOOP.
*--header
*  PERFORM alv_header.

*-- display the grid
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page = 'ALV_HEADER'
      i_callback_program     = l_program
      is_layout              = alv_layout
      it_fieldcat            = i_fieldcat_alv
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_header .
  DATA :
    lt_header TYPE slis_t_listheader,
    ls_header TYPE slis_listheader,
    l_count TYPE c LENGTH 10.
  REFRESH : lt_header.
  CLEAR l_count.
  ls_header-typ  =  'H'.

  ls_header-info =  text-h01.
  APPEND ls_header TO lt_header.


  IF pf_tstmd = 'X'.
    ls_header-typ  =  'A'.

    ls_header-info =  'Test Mode'(h03).
    APPEND ls_header TO lt_header.
  ENDIF.

  IF p_alv = 'X'.
    ls_header-typ  =  'S'.
    ls_header-key = 'Total Nr of systems'(h05).
    ls_header-info =  g_total_ana_systems.
    APPEND ls_header TO lt_header.

    ls_header-typ  =  'S'.
    ls_header-key = 'Error in systems'(h06).
    ls_header-info =  g_error_systems.
    APPEND ls_header TO lt_header.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  RFC_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations .
  DATA: lr_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
         WITH HEADER LINE,
        lt_rfcdes  TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        l_continue TYPE flag,
        lt_bapiret TYPE TABLE OF bapiret2.

  IF NOT s_system[] IS INITIAL.
    SELECT  *   FROM /psyng/sw_rfcdes
                      INTO TABLE lt_rfcdes
                      WHERE systid IN s_system.
  ENDIF.
  LOOP AT lt_rfcdes.
    lr_rfcs-sign = 'I'.
    lr_rfcs-option = 'EQ'.
    lr_rfcs-low = lt_rfcdes-rfcdest.
    ADD 1 TO g_total_ana_systems.
    APPEND  lr_rfcs.
  ENDLOOP.
  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  DATA: l_message(100) TYPE c,
       lt_return TYPE TABLE OF bapiret2
       WITH HEADER LINE,
       l_string TYPE string.
  LOOP AT lr_rfcs.
    CALL FUNCTION '/PSYNG/SW_RFC_CHECK'
      EXPORTING
        i_rfcdest         = lr_rfcs-low
      TABLES
         et_return        = lt_return
     EXCEPTIONS
       failure            = 1
          OTHERS          = 2   .
    IF sy-subrc <> 0.
      READ TABLE lt_return INDEX 1.
      msg lt_return-message '' '' '' .
      l_string = lt_return-message.
      alv_logs lt_rfcdes-systid  l_string '' ''.
      g_rfc_error = 'X'.
* Commenting in SE4.7PS3a
*      delete s_system where low = lr_rfcs-low.
*      CALL FUNCTION 'POPUP_TO_INFORM'
*        EXPORTING
*          titel         = 'Error'
*          txt1          = l_string
*          txt2          = ''
**       TXT3          = ' '
**       TXT4          = ' '
*                .
*      LEAVE LIST-PROCESSING.
      ADD 1 TO g_error_systems.
    ENDIF.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACCESS_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_SYSTEM[]  text
*      <--P_LF_ACCESS_CHECK  text
*      <--P_LV_INVALID_SYSTEM  text
*----------------------------------------------------------------------*
FORM access_check  USING    gr_system TYPE tt_system_range
                   CHANGING lf_access_check TYPE flag
                            lv_invalid_system TYPE
                                                /psyng/range_sysid-low..
  RANGES : lr_system FOR /psyng/range_sysid.

  DATA : lt_sw_cnfacc TYPE TABLE OF /psyng/sw_cnfacc,
         ls_sw_cnfacc TYPE /psyng/sw_cnfacc,
         l_login_user TYPE sy-uname,
         ls_sys       LIKE LINE OF gr_system,
         ls_system    LIKE LINE OF lr_system.


  l_login_user = sy-uname.

  SELECT *
         FROM /psyng/sw_cnfacc
         INTO TABLE  lt_sw_cnfacc
         WHERE username = l_login_user.

  IF sy-subrc = 0.

    LOOP AT lt_sw_cnfacc INTO ls_sw_cnfacc.
      ls_system-sign = ls_sw_cnfacc-sign.
      ls_system-option = ls_sw_cnfacc-opton.
      ls_system-low = ls_sw_cnfacc-sysidlow.
      ls_system-high = ls_sw_cnfacc-sysidhigh.
      APPEND ls_system TO lr_system.
    ENDLOOP.

    LOOP AT gr_system INTO ls_sys.

      IF NOT ls_sys-low IN lr_system.
        lv_invalid_system = ls_sys-low.
        CLEAR lf_access_check.
        EXIT.
      ELSE.
        lf_access_check = 'X'.
      ENDIF.

    ENDLOOP.

  ELSE.

    CLEAR lf_access_check.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_SYSTEM_ACCESS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_system_access .
  DATA : l_cfg_set_dist_rest TYPE flag,

         lv_invalid_system   TYPE /psyng/range_sysid-low.

  se_config_param 'CFG_SET_DIST_REST' l_cfg_set_dist_rest.
*--Access check /psyng/sw_cnfacc
  IF l_cfg_set_dist_rest = 'Y'.

    LOOP AT s_system.
      gr_system-sign   = s_system-sign.
      gr_system-option = s_system-option.
      gr_system-low    = s_system-low.
      gr_system-high   = s_system-high.
      APPEND gr_system.
    ENDLOOP.

    PERFORM access_check USING gr_system[]
                         CHANGING if_access_check
                                  lv_invalid_system.
  ELSE.
    if_access_check = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SCHEDULE_BACK_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job .
  DATA: curr_report LIKE rsvar-report,
          l_jobname TYPE btcjob.
  CLEAR: curr_report, g_curr_variant.

  PERFORM create_variant_from_sel.

  curr_report = sy-repid.
  g_curr_variant = g_variant.

  l_jobname = 'SE-Create/Publish ConfigSet'(j01) .
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
       EXPORTING
            in_jobname  = l_jobname
            in_repvarnt = g_curr_variant
            in_report   = curr_report.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_VARIANT_FROM_SEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_variant_from_sel .
  DATA: curr_report LIKE rsvar-report.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = g_curr_variant
            vari_desc     = g_vari_desc
       TABLES
            vari_contents = g_vari_contents
            vari_text     = g_vari_text
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          illegal_report_or_variant = 1
          illegal_variantname = 2
          not_authorized = 3
          not_executed = 4
          report_not_existent = 5
          report_not_supplied = 6
          variant_exists = 7
          variant_locked = 8
          OTHERS = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_NEXT_VARIANT_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id .
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
  SELECT  variant INTO g_variant FROM varid

  WHERE report = sy-repid   AND
        variant LIKE '/PSYNG/%' AND NOT
        variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    oldnumber = g_variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    g_variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO g_variant.
  ENDIF.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILL_SEL_SCREEN_FIELDS_TO_TAB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab .
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = g_program
            if_no_logging = 'X'
       TABLES
            et_params     = gt_irsparams.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_LOGS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_logs .
  DATA: ls_variant     TYPE disvariant,
         alv_layout     TYPE slis_layout_alv,
         i_fieldcat_alv TYPE slis_t_fieldcat_alv.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
        l_program       LIKE sy-repid.
  alv_layout-zebra = 'X'.
*  alv_layout-colwidth_optimize = 'X'.
  l_program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = l_program
      i_internal_tabname = 'GT_LOGS'
      i_inclname         = l_program
    CHANGING
      ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat_alv-outputlen = 10.
  wa_fieldcat_alv-seltext_l = 'System'(m10).
  wa_fieldcat_alv-seltext_m = 'System'(m10).
  wa_fieldcat_alv-seltext_s = 'System'(m10).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
   TRANSPORTING outputlen seltext_l seltext_m seltext_s
          WHERE fieldname = 'SYSTEM'.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-outputlen = 100.
  wa_fieldcat_alv-seltext_l = 'Message'(m11).
  wa_fieldcat_alv-seltext_m = 'Message'(m11).
  wa_fieldcat_alv-seltext_s = 'Message'(m11).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
  TRANSPORTING outputlen seltext_l seltext_m seltext_s
        WHERE fieldname = 'MESSAGE'.

*-- display the grid
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page = 'ALV_HEADER'
      i_callback_program     = l_program
      is_layout              = alv_layout
      it_fieldcat            = i_fieldcat_alv
      i_save                 = 'A'
      is_variant             = ls_variant
    TABLES
      t_outtab               = gt_logs
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.
