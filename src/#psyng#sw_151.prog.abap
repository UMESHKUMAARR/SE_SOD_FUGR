REPORT /psyng/sw_151 MESSAGE-ID /psyng/sw. "#EC SAST_CI_GEN_CHECK
TABLES: /psyng/swrrshdr.

DATA: g_curr_variant LIKE  rsvar-variant,
      g_variant LIKE vari-variant,
      gs_variant TYPE disvariant,
      g_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      g_vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      g_vari_text LIKE varit OCCURS 0 WITH HEADER LINE,
      gt_irsparams    TYPE rsparams OCCURS 0 WITH HEADER LINE,
      gt_swrrshdr  TYPE TABLE OF /psyng/swrrshdr WITH HEADER LINE.

DATA: g_answer TYPE flag,
      g_program LIKE sy-repid,
      g_exit_proc,
      g_nrruns TYPE i.

RANGES:  gr_aid FOR /psyng/swrrshdr-aid.
*----Macros
DEFINE msg.
  if sy-batch = 'X'.
    message s002(/psyng/sw) with &1 &2 &3 &4.
    commit work.
  endif.
END-OF-DEFINITION.


*---Selection screen
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN:SKIP 1.
SELECT-OPTIONS: so_aid FOR /psyng/swrrshdr-aid.
*MATCHCODE OBJECT /PSYNG/SERESID.
SELECTION-SCREEN:SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_pretn TYPE flag USER-COMMAND pre.
SELECTION-SCREEN COMMENT 5(65) text-t02 .
SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE text-t04.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_delhdr TYPE flag DEFAULT 'X' USER-COMMAND hdr.
SELECTION-SCREEN COMMENT 5(33) text-t05.
SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_delsum TYPE flag DEFAULT 'X' USER-COMMAND sum.
SELECTION-SCREEN COMMENT 5(14) text-t06.
SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_deldet TYPE flag DEFAULT 'X' USER-COMMAND det.
SELECTION-SCREEN COMMENT 5(14) text-t07 .
SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK hblk WITH FRAME TITLE text-t03.
SELECTION-SCREEN:SKIP 1.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-001 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-002 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.
SELECTION-SCREEN END OF BLOCK hblk .

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF ( screen-name EQ 'P_DELSUM'
    OR screen-name EQ 'P_DELDET' )
    AND p_pretn IS INITIAL
    AND p_delhdr IS NOT INITIAL.
        CLEAR: p_delsum, p_deldet.
        screen-input = 0.
        MODIFY SCREEN.
    ELSEIF screen-name EQ 'P_DELDET'
    AND p_pretn IS INITIAL
    AND p_delsum IS NOT INITIAL.
        CLEAR: p_deldet.
        screen-input = 0.
        MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN.

*---SM37
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.

*----Schedule bck job
  IF sy-ucomm = 'SCJB'.
    g_exit_proc = 'Y'.
    PERFORM schedule_back_job.
    EXIT.
  ENDIF.

INITIALIZATION.
  g_program = sy-repid.

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
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '06'.
  IF sy-subrc <> 0.
    MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
        WITH
          'Delete results'(a01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF g_exit_proc = 'Y'.

*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_151
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.

  PERFORM validation.
  PERFORM get_filter_data_by_selection.
*--- popup should apear only if execute in forground
  IF sy-batch IS INITIAL.
    DATA l_rc_count TYPE i.
    DESCRIBE TABLE gt_swrrshdr LINES l_rc_count.
    IF l_rc_count = 0 .
      MESSAGE s002 WITH 'No analysis run found for deletion'(s04).
      LEAVE LIST-PROCESSING.
    ENDIF.
    PERFORM confirm_popup USING g_answer.
  ENDIF.


  IF sy-batch  = 'X'.
    msg '-->Starting Deletion' '' '' '' .
    PERFORM nr_of_runs.
    msg '#Runs:' g_nrruns '' '' .
    msg '#Conflicts:' /psyng/swrrshdr-conflicts '' '' .
    IF g_nrruns = 0.
      MESSAGE s002 WITH 'No analysis run found for deletion'(s04).
    ENDIF.
    g_answer = '1'. " set delete confirmation popup ans to 1
  ENDIF.

  IF g_answer = '1'.
    PERFORM data_deletion.
  ENDIF.


*---------------------------------------------------------------------*
*       FORM confirm_popup                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM confirm_popup USING e_answer TYPE flag.
  CALL SCREEN 0101 STARTING AT 10 1.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM validation                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM validation.
  DATA: l_valid_aid TYPE flag.

  IF so_aid[] IS INITIAL AND p_pretn IS INITIAL.
    MESSAGE s002 WITH
 'Deleting Multiple Analysis Results'(s01)
 'that have not expired is not allowed'(s02).
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF p_delhdr IS INITIAL
  AND p_deldet IS INITIAL
  AND p_delsum IS INITIAL.
    MESSAGE s002 WITH
 'Atleast choose one option in data selection'(t08).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_filter_data_by_selection                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_filter_data_by_selection.

DATA lf_delete TYPE flag.

  IF NOT so_aid[] IS INITIAL OR NOT p_pretn IS INITIAL.
    SELECT * FROM /psyng/swrrshdr INTO TABLE gt_swrrshdr
    WHERE aid         IN so_aid.
  ENDIF.
  SORT gt_swrrshdr BY aid.
  DELETE ADJACENT DUPLICATES FROM gt_swrrshdr COMPARING aid.

*---Collect aid that needs to be deleted
  LOOP AT gt_swrrshdr.
  IF p_pretn = 'X'.
    CLEAR lf_delete.
    IF p_delhdr = 'X'
    AND gt_swrrshdr-delete_date IS NOT INITIAL
    AND gt_swrrshdr-delete_date LE sy-datum.
        lf_delete = 'X'.
    ELSEIF p_delsum = 'X'
    AND gt_swrrshdr-delete_date_sum IS NOT INITIAL
    AND gt_swrrshdr-delete_date_sum LE sy-datum.
        lf_delete = 'X'.
    ELSEIF p_deldet = 'X'
    AND gt_swrrshdr-delete_date_det IS NOT INITIAL
    AND gt_swrrshdr-delete_date_det LE sy-datum.
        lf_delete = 'X'.
    ENDIF.
    IF lf_delete IS INITIAL.
       DELETE gt_swrrshdr INDEX sy-tabix.
       CONTINUE.
    ENDIF.
  ENDIF.
    gr_aid-sign = 'I'.
    gr_aid-option = 'EQ'.
    gr_aid-low = gt_swrrshdr-aid.
    append gr_aid.
  ENDLOOP.
  if gr_aid[] is initial and gt_swrrshdr[] is initial.
*--Until SE4.5PS2, there could be leftover records in tables  /PSYNG/SWRRSIABB and /PSYNG/SWRRSUABB
*  for result ids that were already deleted
*  This will also take care of cleaning up any data that resulted from a deletion job failing

    if p_delhdr = 'X'.
      select distinct aid from /PSYNG/SWRRSRABB
        into CORRESPONDING FIELDS OF table gt_swrrshdr
        WHERE aid         IN so_aid.
      if not gt_swrrshdr[] is initial.
*--Double check result ID doesn't exist
       loop at gt_swrrshdr.
         select single aid from /psyng/swrrshdr into gt_swrrshdr-aid where aid = gt_swrrshdr-aid.
           if sy-subrc <> 0.
            gr_aid-sign = 'I'.
            gr_aid-option = 'EQ'.
            gr_aid-low = gt_swrrshdr-aid.
            APPEND gr_aid.
           else.
             DELETE gt_swrrshdr INDEX sy-tabix.
             CONTINUE.
           endif.
       endloop.
      endif.
    endif.
    if not gt_swrrshdr[] is initial.
      MESSAGE s002 WITH
      'Data found related to previously deleted analysis IDs'.
      MESSAGE s002 WITH
      'Data cleanup will be executed for these analysis IDs.'.
      loop at gt_swrrshdr.
          MESSAGE s002 WITH '--' gt_swrrshdr-aid.
      endloop.

    endif.
  endif.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob.

*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '06'.
  IF sy-subrc <> 0.
    MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
        WITH
          'Delete results'(a01).
  ELSE.

    CLEAR: curr_report, g_curr_variant.
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
           ILLEGAL_REPORT_OR_VARIANT = 1
           ILLEGAL_VARIANTNAME = 2
           NOT_AUTHORIZED = 3
           NOT_EXECUTED = 4
           REPORT_NOT_EXISTENT = 5
           REPORT_NOT_SUPPLIED = 6
           VARIANT_EXISTS = 7
           VARIANT_LOCKED = 8
           OTHERS = 9.

"(++)EOC UMITTAL SE VF scan-25/11/2024.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      l_jobname = 'SE SOD Analysis Results Deletion'(041).
      CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
           EXPORTING
                in_jobname  = l_jobname
                in_repvarnt = g_curr_variant
                in_report   = curr_report.
      IF sy-subrc <> 0.
        CALL SCREEN 1000.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " schedule_back_job



*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
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
    CONCATENATE text-081 oldnumber_c INTO g_variant.
  ENDIF.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.                    " get_next_variant_id

*---------------------------------------------------------------------*
*       FORM fill_sel_screen_fields_to_tab                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = g_program
            if_no_logging = 'X'
       TABLES
            et_params     = gt_irsparams.
ENDFORM.
*---------------------------------------------------------------------*
*       MODULE STATUS_0101 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS '0101'.
  SET TITLEBAR '0101'.

*---popup information
  PERFORM nr_of_runs.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL' OR 'CONTINUE'.
      CLEAR g_answer.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'CONT'.
      g_answer = '1'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM data_deletion                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM data_deletion.

  DATA:   lt_swrrsifun TYPE TABLE OF /psyng/swrrsifun,
          lt_swrrsrol  TYPE TABLE OF /psyng/swrrsrol,
          lt_swrrsrol_tmp TYPE TABLE OF /psyng/swrrsrol,
          ls_swrrshdr  TYPE /psyng/swrrshdr,
          l_role_count TYPE i,
          l_processed_role TYPE i,
          l_total_role TYPE i.
  DATA: lf_del_hdr TYPE flag,
        lf_del_sum TYPE flag,
        lf_del_det TYPE flag,
        lf_details_deleted TYPE flag,
        lf_sum_deleted TYPE flag,
        lf_header_deleted TYPE flag.
  FIELD-SYMBOLS: <swrrsifun> TYPE /psyng/swrrsifun,
                 <swrrsrol>  TYPE /psyng/swrrsrol.

  RANGES lr_roleindex FOR /psyng/swrrsrol-roleindex.
*--- read relational db to delete large amount of data from

  SELECT * FROM /psyng/swrrsifun INTO TABLE lt_swrrsifun
  WHERE aid IN gr_aid.

*---sort ascending order by funindex
*  SORT lt_swresisys BY sysindex.
  SORT lt_swrrsifun BY funindex.


*---analysis deleting 1 by 1
  LOOP AT gt_swrrshdr.
    lf_del_hdr = 'X'.
    lf_del_sum = 'X'.
    lf_del_det = 'X'.
       IF p_delhdr EQ 'X'.
          IF p_pretn EQ 'X'.
            IF gt_swrrshdr-delete_date GT sy-datum.
               CLEAR lf_del_hdr.
            ENDIF.
          ENDIF.
       ELSE.
               CLEAR lf_del_hdr.
       ENDIF.
       IF p_delsum EQ 'X'.
          IF p_pretn EQ 'X'.
            IF gt_swrrshdr-delete_date_sum GT sy-datum.
               CLEAR lf_del_sum.
            ENDIF.
          ENDIF.
       ELSE.
               CLEAR lf_del_sum.
       ENDIF.
       IF p_deldet EQ 'X'.
          IF p_pretn EQ 'X'.
            IF gt_swrrshdr-delete_date_det GT sy-datum.
               CLEAR lf_del_det.
            ENDIF.
          ENDIF.
       ELSE.
               CLEAR lf_del_det.
       ENDIF.

    IF lf_del_hdr EQ 'X'.
   msg 'Deleting Analysis ID'(n01) gt_swrrshdr-aid 'Completely'(n04) ''.
       lf_del_sum = 'X'.
       lf_del_det = 'X'.
    ELSEIF lf_del_sum EQ 'X'.
    msg 'Deleting Summary and Details for Analysis ID'(n02)
    gt_swrrshdr-aid '' ''.
    lf_del_det = 'X'.
    ELSEIF lf_del_det EQ 'X'.
    msg 'Deleting Details for Analysis ID'(n03) gt_swrrshdr-aid '' ''.
    ENDIF.

    SELECT aid roleindex agr_name FROM /psyng/swrrsrol
    INTO CORRESPONDING FIELDS
  OF TABLE lt_swrrsrol WHERE aid = gt_swrrshdr-aid.
    SORT lt_swrrsrol BY roleindex.
    IF lf_del_det EQ 'X'.
*----delete /psyng/swrrscaut db record
    msg 'Deleting DB records from'(n05) '/psyng/swrrscaut' '' ''.

  msg '|--Analysis ID ' gt_swrrshdr-aid  'System '   gt_swrrshdr-sysid.

      LOOP AT lt_swrrsifun ASSIGNING <swrrsifun>
                      WHERE aid = gt_swrrshdr-aid.
        DELETE FROM /psyng/swrrscaut
         WHERE aid = gt_swrrshdr-aid
           AND funindex = <swrrsifun>-funindex.
        IF sy-subrc = 0.
          COMMIT WORK.
         msg '|---Function ID ' <swrrsifun>-funid '#Records ' sy-dbcnt.
         lf_details_deleted = 'X'.
        ENDIF.
      ENDLOOP.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsitcd' '' ''.
    DELETE FROM /psyng/swrrsitcd
                  WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsiabb' '' ''.
    DELETE FROM /psyng/swrrsiabb
                  WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

     msg 'Deleting DB records from'(n05) '/psyng/swrrsrabb' '' ''.
    DELETE FROM /PSYNG/SWRRSRABB
                  WHERE aid = gt_swrrshdr-aid."#EC SAST_CI_GEN_CHECK
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.




    msg 'Deleting DB records from'(n05) '/psyng/swrrsiobj' '' ''.
    DELETE FROM /psyng/swrrsiobj
            WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsiaut' '' ''.
    DELETE FROM /psyng/swrrsiaut
               WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsifld' '' ''.
    DELETE FROM /psyng/swrrsifld
               WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsrchd' '' ''.
    DELETE FROM /psyng/swrrsrchd
                  WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsichd' '' ''.
    DELETE FROM /psyng/swrrsichd
               WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_details_deleted = 'X'.
    ENDIF.
    ENDIF.

    CLEAR: lt_swrrsrol_tmp[], l_total_role, l_processed_role.
    lt_swrrsrol_tmp[] = lt_swrrsrol[].
    If lf_del_sum EQ 'X'.
    msg 'Deleting DB records from'(n05) '/psyng/swrrscon' '' ''.
    DESCRIBE TABLE lt_swrrsrol_tmp LINES l_total_role.
*---approch: delete in batch of 500 roles at a time
    LOOP AT lt_swrrsrol_tmp ASSIGNING <swrrsrol>.
      lr_roleindex-sign = 'I'.
      lr_roleindex-option = 'EQ'.
      lr_roleindex-low = <swrrsrol>-roleindex.
      APPEND lr_roleindex.
      ADD 1 TO l_processed_role.
      IF sy-tabix EQ 500 OR l_processed_role = l_total_role.
        DELETE FROM /psyng/swrrscon
                                  WHERE aid  = gt_swrrshdr-aid
                                  AND   roleindex IN lr_roleindex.
        IF sy-subrc = 0.
          COMMIT WORK.
          DESCRIBE TABLE lr_roleindex LINES l_role_count.
          msg '|---#Roles ' l_role_count '#Records ' sy-dbcnt.
          lf_sum_deleted = 'X'.
        ENDIF.
        DELETE lt_swrrsrol_tmp WHERE roleindex IN lr_roleindex.
        REFRESH lr_roleindex.
      ENDIF.
    ENDLOOP.

*---Delete other tables records
    msg 'Deleting DB records from'(n05) '/psyng/swrrsrol' '' ''.
    DELETE FROM /psyng/swrrsrol
                  WHERE aid = gt_swrrshdr-aid.
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_sum_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrscfun' '' ''.
    DELETE FROM /psyng/swrrscfun
                  WHERE aid = gt_swrrshdr-aid.

    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_sum_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsicon' '' ''.
    DELETE FROM /psyng/swrrsicon
    WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_sum_deleted = 'X'.
    ENDIF.

    msg 'Deleting DB records from'(n05) '/psyng/swrrsifun' '' ''.
    DELETE FROM /psyng/swrrsifun
                  WHERE aid = gt_swrrshdr-aid.
*
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
      lf_sum_deleted = 'X'.
    ENDIF.
    ENDIF.
    IF lf_del_hdr EQ 'X'.
    msg 'Deleting DB records from'(n05) '/psyng/swrrshdr' '' ''.
    DELETE FROM /psyng/swrrshdr
                  WHERE aid = gt_swrrshdr-aid.
    IF sy-subrc = 0.
      COMMIT WORK.
      msg '|--- ' '#Records ' sy-dbcnt ''.
     msg '**********' '***************' '**********' '***************'.
      msg 'Data Deleted Successfully, ' 'AID:'  gt_swrrshdr-aid ''.
      lf_header_deleted = 'X'.
     msg '**********' '***************' '**********' '***************'.
    ENDIF.
    ENDIF.
    REFRESH : lt_swrrsrol, lt_swrrsrol_tmp.
  ENDLOOP.
  IF sy-batch IS INITIAL.
  IF lf_header_deleted IS NOT INITIAL.
     MESSAGE s002(/psyng/sw) WITH 'Data Deleted Successfully'.
  ELSEIF lf_sum_deleted IS NOT INITIAL.
     MESSAGE s002(/psyng/sw) WITH 'Summary Deleted Successfully'(n07).
  ELSEIF lf_details_deleted IS NOT INITIAL.
     MESSAGE s002(/psyng/sw) WITH 'Details Deleted Successfully'(n06).
  ELSE.
     MESSAGE s002(/psyng/sw) WITH 'Nothing is deleted'(n08).
  ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM confirm_popup_information                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM nr_of_runs.
  DATA: l_records_count TYPE i,
         l_conflict_count TYPE i.

  CLEAR:    g_nrruns,  /psyng/swrrshdr-conflicts.

*---popup information
  DESCRIBE TABLE gt_swrrshdr LINES l_records_count.

  g_nrruns = l_records_count.
  LOOP AT gt_swrrshdr.
    l_conflict_count = l_conflict_count + gt_swrrshdr-conflicts.
  ENDLOOP.
  /psyng/swrrshdr-conflicts = l_conflict_count.
ENDFORM.
