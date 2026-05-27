*&---------------------------------------------------------------------*
*& Report  /PSYNG/BRIDGE_SE_SYNCH_RULES
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/bridge_se_synch_rules MESSAGE-ID /psyng/sw.

*--Report global variables
INCLUDE /psyng/bridge_synch_rules_top.

*--Report selection screen
INCLUDE /psyng/bridge_synch_rules_ss.

*--Report subroutines include
INCLUDE /psyng/brdge_synch_rules_cf01.

INITIALIZATION.

data: gs_functxt TYPE smp_dyntxt.

  gs_functxt-icon_id   = icon_configuration.
  gs_functxt-quickinfo = 'Maintain configuration'(153).
  gs_functxt-icon_text = 'Maintain configuration'(153).
  sscrfields-functxt_01 = gs_functxt.

*  sscrfields-functxt_01 = 'Maintain configuration'(153).
  gs_functxt-icon_id   = icon_configuration.
  gs_functxt-quickinfo = 'Maintain Sensitivity'(210).
  gs_functxt-icon_text = 'Maintain Sensitivity'(210).
  sscrfields-functxt_02 = gs_functxt.
*  sscrfields-functxt_02 = 'Maintain Sensitivity'(210).

*--Calling read system API For systemID and system name search help
*--purpose
  CALL FUNCTION '/PSYNG/SW_READ_PBRIDGE_SYSTEMS'
    IMPORTING
      ef_success        = gf_sysid_success
    TABLES
      et_pbridge_system = gt_pbridge_sys.

  g_program = sy-repid.

*--Handling Report selection screen expand buttons
  PERFORM set_button_icons.

*--Search help for system ID field
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sysid.
  PERFORM f4_systemid USING gt_pbridge_sys.

*--Search help for system name field
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_sys.
  PERFORM f4_sysname USING gt_pbridge_sys.

*--Search help for PLC ruleset field
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_plcvrs.
  PERFORM f4_plcvrs.

AT SELECTION-SCREEN.
  CASE sscrfields-ucomm.
    WHEN'FC01'.
      gf_dischg = gc_display.
      CALL SCREEN 100.
    WHEN 'FC02'.
      SUBMIT /psyng/sw_sync_senstivity_plc AND RETURN.
  ENDCASE.

  CASE sy-ucomm.
    WHEN 'ONLI' OR 'SCJB'.                       "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (06/12/24)

      IF p_plcvrs IS INITIAL.
        MESSAGE e160 WITH 'PLC ruleset value is required'(209).
      ENDIF.

      IF p_pull EQ 'X'.
        IF p_func IS INITIAL AND
           p_conf IS INITIAL AND
           p_val <> 'X' AND
          p_mc_def IS INITIAL AND
          p_mc_ass IS INITIAL.
          MESSAGE e160 WITH 'Select at least one checkbox'(T06).
        ENDIF.
        IF p_sysid IS INITIAL.
          IF p_func = 'X' OR p_val = 'X'.
            MESSAGE e160 WITH 'System ID is mandatory'(T12).
          ENDIF.
        ELSE.
          IF p_func = 'X' OR p_val = 'X'.
            PERFORM verify_sysid USING gt_pbridge_sys
                                 CHANGING gf_sysid_valid.
            IF gf_sysid_valid IS INITIAL.
              MESSAGE e160 WITH 'System ID does not exist'(T14).
            ENDIF.
          ENDIF.
        ENDIF.
        IF p_vrsio EQ 000.
          MESSAGE e160 WITH
          'You are not allowed to pull data into SOD version '(T11)
                p_vrsio.
        ELSEIF p_vrsio EQ 999.
          MESSAGE e160 WITH
      'You are not allowed to pull data into SOD version '(T11) p_vrsio.
        ENDIF.
        IF p_crtver IS INITIAL.
          SELECT SINGLE mandt INTO client FROM /psyng/swsodvers
          WHERE vrsio = p_vrsio.
          IF sy-subrc <> 0.
            MESSAGE e156 WITH p_vrsio.
          ENDIF.
        ELSEIF p_crtver = 'X'.
          SELECT SINGLE mandt INTO client FROM /psyng/swsodvers
          WHERE vrsio = p_vrsio.
          IF sy-subrc = 0.
            MESSAGE e160 WITH 'SOD version already exist'(T10).
          ELSE.
            AUTHORITY-CHECK OBJECT 'Y&SW_VRSIO'
         ID 'ACTVT' FIELD '01'
         ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
            IF sy-subrc <> 0.
              MESSAGE w108 WITH 'Create SOD Versions'(014).
              LEAVE LIST-PROCESSING.
            ENDIF.
            IF p_text IS INITIAL AND p_crtver EQ 'X'.
              MESSAGE e155.
            ELSE.
              PERFORM crt_new_vers USING p_vrsio p_text.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
      IF p_push EQ 'X'.
        SELECT SINGLE mandt INTO client FROM /psyng/swsodvers
        WHERE vrsio = p_vrsio.
        IF sy-subrc <> 0.
          MESSAGE e156 WITH p_vrsio.
        ENDIF.

        IF p_schema IS INITIAL AND
           p_group IS INITIAL AND
           p_rule IS INITIAL AND
           p_actmod IS INITIAL AND
           p_uacmod IS INITIAL AND
           p_grpcmp IS INITIAL AND
          p_mc_d1 IS INITIAL AND
          p_mc_a1 IS INITIAL.
          MESSAGE e160 WITH 'Select at least one checkbox'(T06).
        ENDIF.

        IF p_sysdp EQ 'X'.
          IF p_sys IS INITIAL AND p_sysdp EQ 'X'.
            MESSAGE e160 WITH 'System name mandatory'(T07).
          ELSEIF p_sys IS NOT INITIAL AND p_sysdp EQ 'X'.
            PERFORM verify_sysname USING gt_pbridge_sys
                                 CHANGING gf_sysname_valid.
            IF gf_sysname_valid IS INITIAL.
              MESSAGE e160
              WITH 'System name does not exist'(T15).
            ENDIF.
          ENDIF.
        ENDIF.

      ENDIF.
      IF sy-ucomm = 'SCJB'.
        g_exit_proc = 'Y'.
        PERFORM schedule_back_job.
      ENDIF.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
  ENDCASE.
  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

AT SELECTION-SCREEN OUTPUT.
  PERFORM handle_button.
  PERFORM handle_sections.
  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'P_CRTVER'.
        IF p_pull EQ 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
          CLEAR p_crtver.
        ENDIF.
      WHEN 'P_TEXT'.
        IF p_crtver = 'X'.
          IF p_pull EQ 'X'.
            screen-input = 1.
          ENDIF.
        ELSE.
          screen-input = 0.
          CLEAR p_text.
        ENDIF.
    ENDCASE.

    CASE screen-group1.
      WHEN 'M1'.
        IF p_pull EQ 'X'.
          screen-active = 1.
        ELSE.
          screen-active = 0.
          CLEAR : p_func, p_conf, p_val, p_sysid, p_mc_def, p_mc_ass.
        ENDIF.
      WHEN 'M2'.
        IF p_push EQ 'X'.
          screen-active = 1.
          CLEAR: p_text.
        ELSE.
          screen-active = 0.
          CLEAR: p_schema,p_group, p_rule, p_roride, p_actmod, p_sys,
          p_uacmod, p_amorde, p_grpcmp, p_gcorde, p_mc_d1, p_mc_a1.
        ENDIF.
    ENDCASE.

    CASE screen-name.
      WHEN 'P_RORIDE'.
        IF p_rule = 'X' AND p_sysind EQ 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
          CLEAR p_roride.
        ENDIF.
      WHEN 'P_AMORDE'.
        IF p_uacmod = 'X' AND p_sysdp EQ 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
          CLEAR p_amorde.
        ENDIF.
      WHEN 'P_GCORDE'.
        IF p_grpcmp = 'X' AND p_sysdp EQ 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
          CLEAR p_gcorde.
        ENDIF.
      WHEN 'P_SYSID'.
        IF p_func EQ 'X' OR p_val = 'X'. "Today
          screen-input = 1.
        ELSE.
          screen-input = 0.
          CLEAR p_sysid.
        ENDIF.
      WHEN 'P_FUNC'.
        IF p_val = 'X'.
          screen-input = 0.
          CLEAR p_func.
        ELSE.
          screen-input = 1.
        ENDIF.
      WHEN 'P_CONF'.
        IF p_val = 'X'.
          screen-input = 0.
          CLEAR p_conf.
        ELSE.
          screen-input = 1.
        ENDIF.
*--System independent checkboxes
      WHEN 'P_SCHEMA'.
        IF p_sysind NE 'X'.
          screen-input = 0.
          CLEAR p_schema.
        ENDIF.
      WHEN 'P_GROUP'.
        IF p_sysind NE 'X'.
          screen-input = 0.
          CLEAR p_group.
        ENDIF.
      WHEN 'P_RULE'.
        IF p_sysind NE 'X'.
          screen-input = 0.
          CLEAR p_rule.
        ENDIF.
      WHEN 'P_ACTMOD'.
        IF p_sysind NE 'X'.
          screen-input = 0.
          CLEAR p_actmod.
        ENDIF.
*--System dependent checkboxes
      WHEN 'P_SYS'.
        IF p_sysdp NE 'X'.
          screen-input = 0.
          CLEAR p_sys.
        ENDIF.
      WHEN 'P_UACMOD'.
        IF p_sysdp NE 'X'.
          screen-input = 0.
          CLEAR p_uacmod.
        ENDIF.
      WHEN 'P_GRPCMP'.
        IF p_sysdp NE 'X'.
          screen-input = 0.
          CLEAR p_grpcmp.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN.
  ENDLOOP.

START-OF-SELECTION.

*BOC : AKUMAR 11-29-2024
*--Added authority check
  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH sy-repid.
    EXIT.
  ENDIF.
*EOC : AKUMAR 11-29-2024

  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
    SUBMIT (g_program)                       "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(10/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.

  CASE 'X'.

    WHEN p_pull.

*--Sync ruleset from PLC to SE
      PERFORM sync_rul_f_plc.

*-Sync mitigations from PLC to SE
      PERFORM sync_mc_f_plc.

*--Logs
      IF p_val <> 'X'.
        PERFORM alv_logs.
      ENDIF.

    WHEN p_push.

*--Sync ruleset from SE to PLC
      PERFORM sync_rul_t_plc.

*--Sync mitigations from SE to PLC
      PERFORM sync_mc_t_plc.

*--Logs
      PERFORM alv_logs.

  ENDCASE.
