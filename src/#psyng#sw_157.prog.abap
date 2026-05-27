*&---------------------------------------------------------------------*
*& REPORT  DISTRIBUTION OF CONFIG SET
*&
*&---------------------------------------------------------------------*
*&
*&
*&---------------------------------------------------------------------*
REPORT /psyng/sw_157 MESSAGE-ID /psyng/sw."#EC SAST_CI_GEN_CHECK
TABLES: /psyng/sw_rfcdes, /psyng/sw_cnfacc.
TYPE-POOLS: slis.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_157_top. " GLOBAL DECLARATION
INCLUDE /psyng/sw_157_ss.  " SELECTION SCREEN
INCLUDE /psyng/sw_157_create_configf01.

AT SELECTION-SCREEN.

  CASE sy-ucomm.
    WHEN 'SCJB'.
      g_exit_proc = 'Y'.
      PERFORM schedule_back_job.
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

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_157
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.

*---authority check when report not executed in test mode
  IF pf_tstmd IS INITIAL.
    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'DISTCON'.
    IF sy-subrc <> 0.
      MESSAGE s108 WITH 'Distribute Configuration Set'(e01).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.


* BOC by GSINGH on 09.02.2023 - adding screen validations for Config
* set description/checkbox
  IF pf_cpyl IS NOT INITIAL AND p_desc IS NOT INITIAL.
    MESSAGE s137 WITH 'Either Select Copy from Latest Published'(e02)
                 'Config Set checkbox or Enter description only'(e03).
    LEAVE LIST-PROCESSING.
  ELSEIF pf_cpyl IS INITIAL AND p_desc IS INITIAL.
    MESSAGE s137 WITH 'Either Select Copy from Latest Published'(e02)
                      'Config Set checkbox or Enter description'(e04).
    LEAVE LIST-PROCESSING.
  ENDIF.
* EOC by GSINGH

*-- Check RFC destinations
  IF NOT s_system[] IS INITIAL.
    clear g_rfc_error.
    PERFORM rfc_validations.
  ENDIF.
*BOC by GSINGH on 08.02.2023 for B17172 -Adding system access check
*before creating Config Set
  PERFORM check_system_access.
  IF if_access_check IS INITIAL.
    MESSAGE i138(/psyng/sw) WITH
               'User has no access to create Config Set in '(i00)
               'entered system(s)'(i01).
    EXIT.
  ENDIF.
*   EOC by GSINGH.
* if single system entered and combined checkbox is not checked stop
  IF pf_cmbn = 'X'.
    DESCRIBE TABLE s_system LINES sy-tfill.
    IF sy-tfill < 2.
      MESSAGE s113 WITH 'Combine all systems is possible with'(i10)
                    'more than one systems!'(i11).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
if g_rfc_error is INITIAL.
  PERFORM create_config_set.
endif.
  IF p_alv = 'X'.
    IF NOT gt_output[] IS INITIAL.
      PERFORM create_and_display_alv.
*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
    ELSE.
      PERFORM display_logs.
*BOC UMITTAL BOSCH : Tfr cfg set for dflt/non-dflt SOD vers 11/11/2025
    ENDIF.
  ELSE.
    PERFORM display_logs.
  ENDIF.
