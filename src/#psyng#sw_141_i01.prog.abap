*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_141_I01                                          *
*----------------------------------------------------------------------*

 MODULE user_command_0100 INPUT.
   DATA: l_row_no TYPE lvc_t_roid,
              ls_row_no TYPE lvc_s_roid,
              w_lines TYPE i,
              ls_sys LIKE LINE OF gr_system,
              ls_output LIKE LINE OF gt_output,
              lf_access_check TYPE flag,
              lv_invalid_system TYPE /psyng/range_sysid-low.

   CASE sy-ucomm.
     WHEN 'BACK'.
       SET SCREEN 0.
       LEAVE SCREEN.

     WHEN 'SM37'.
       AUTHORITY-CHECK OBJECT 'S_TCODE'
               ID 'TCD' FIELD 'SM37'.
       IF sy-subrc <> 0.
         MESSAGE e077(s#) WITH 'SM37'.
       ELSE.
         CALL TRANSACTION 'SM37'.
       ENDIF.

     WHEN 'REFRESH'.
       REFRESH gt_output.
       PERFORM load_data.
       CALL METHOD gr_alvgrid->refresh_table_display
               EXPORTING
                 i_soft_refresh = 'X'
               EXCEPTIONS
                 finished       = 1
                 OTHERS         = 2.
     WHEN 'SCHED'.
       SUBMIT /psyng/sw_144
       VIA SELECTION-SCREEN AND RETURN.
     WHEN 'RFRSH_SEL'.
*---Get selected row
       CALL METHOD gr_alvgrid->get_selected_rows
         IMPORTING
           et_row_no     = l_row_no.
       DESCRIBE TABLE l_row_no LINES w_lines.
       IF w_lines = 0.
         MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
       ELSE.
         REFRESH gr_system.
*-- collect system
         LOOP AT l_row_no INTO ls_row_no.
           READ TABLE gt_output INTO ls_output
                  INDEX  ls_row_no-row_id.
           IF sy-subrc = 0.
             ls_sys-sign = 'I'.
             ls_sys-option = 'EQ'.
             ls_sys-low = ls_output-systid.
             APPEND ls_sys TO gr_system.
           ENDIF.
         ENDLOOP.
*-- call report with system parameter
         PERFORM create_background_job.
       ENDIF.
     WHEN 'DISTRI'.
*---Get selected row
       CALL METHOD gr_alvgrid->get_selected_rows
         IMPORTING
           et_row_no     = l_row_no.
       DESCRIBE TABLE l_row_no LINES w_lines.
       IF w_lines = 0.
         MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
       ELSE.
         REFRESH gr_system.
*-- collect system
         LOOP AT l_row_no INTO ls_row_no.
           READ TABLE gt_output INTO ls_output
                  INDEX  ls_row_no-row_id.
           IF sy-subrc = 0.
             ls_sys-sign = 'I'.
             ls_sys-option = 'EQ'.
             ls_sys-low = ls_output-systid.
             APPEND ls_sys TO gr_system.
           ENDIF.
         ENDLOOP.
*-- call configutation distribution transaction
*---Authorization Check
         AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                ID 'Y&SW_ADMF' FIELD 'DISTCON'.
         IF sy-subrc = 0.
           PERFORM distribute_configuration.
           CLEAR:  sy-ucomm.
         ELSE.
           MESSAGE e108(/psyng/sw) WITH
           'Distribute Configurations'(e37).
         ENDIF.


       ENDIF.
     WHEN 'VALIDATE'.
*---Get selected row
       CALL METHOD gr_alvgrid->get_selected_rows
         IMPORTING
           et_row_no     = l_row_no.
       DESCRIBE TABLE l_row_no LINES w_lines.
       IF w_lines = 0.
         MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
       ELSE.
         REFRESH gr_system.
*-- collect system
         LOOP AT l_row_no INTO ls_row_no.
           READ TABLE gt_output INTO ls_output
                  INDEX  ls_row_no-row_id.
           IF sy-subrc = 0.
             ls_sys-sign = 'I'.
             ls_sys-option = 'EQ'.
             ls_sys-low = ls_output-systid.
             APPEND ls_sys TO gr_system.
           ENDIF.
         ENDLOOP.
*-- call configutation distribution transaction
*---Authorization Check
*      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
*             ID 'Y&SW_ADMF' FIELD 'DISTCON'.
*      IF sy-subrc = 0.
         PERFORM validate_config_set.
         CLEAR:  sy-ucomm.
*      ELSE.
*        MESSAGE e108(/psyng/sw) WITH
*        'Distribute Configurations'(e37).
*      ENDIF.
       ENDIF.

     WHEN 'PUBLISH'.

*--Get selected rows
       REFRESH l_row_no.
       CALL METHOD gr_alvgrid->get_selected_rows
                IMPORTING
                  et_row_no     = l_row_no.

*--Check row is selected or not
       IF l_row_no IS INITIAL.
         MESSAGE e002(/psyng/sw) WITH 'Please select an entry'(e00).
       ELSE.
*--Collect all selected systems
         REFRESH gr_system.
         CLEAR ls_row_no.
         LOOP AT l_row_no INTO ls_row_no.
           CLEAR ls_output.
           READ TABLE gt_output INTO ls_output INDEX ls_row_no-row_id.
           IF sy-subrc = 0.
             ls_sys-sign = 'I'.
             ls_sys-option = 'EQ'.
             ls_sys-low = ls_output-systid.
             APPEND ls_sys TO gr_system.
           ENDIF.
         ENDLOOP.
       ENDIF.

       DATA : l_cfg_set_dist_rest TYPE flag.

       se_config_param 'CFG_SET_DIST_REST' l_cfg_set_dist_rest.
*--Access check /psyng/sw_cnfacc
       IF l_cfg_set_dist_rest = 'Y'.
         PERFORM access_check USING gr_system[]
                              CHANGING lf_access_check
                                       lv_invalid_system.

         IF lf_access_check IS INITIAL.
           MESSAGE i138(/psyng/sw) WITH
                      'User has no access to create Config Set in '(i00)
                      'selected systems'(i01).
           EXIT.
         ENDIF.
       ENDIF.
*--Publish config set
       PERFORM publish_config_set.
     WHEN 'PUBACCESS'.
       SUBMIT /psyng/sw_156 AND RETURN.

   ENDCASE.
 ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
 MODULE user_command_0101 INPUT.
   CASE sy-ucomm.
     WHEN 'BACK'.
       SET SCREEN 0.
       LEAVE SCREEN.
   ENDCASE.
 ENDMODULE.

*---------------------------------------------------------------------*
*       FORM create_background_job                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
 FORM create_background_job.
*-- create variant
   DATA: lt_rsparams TYPE TABLE OF rsparams WITH HEADER LINE,
  lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
  l_variant TYPE raldb_vari.
   DATA : l_tbtco TYPE tbtco,
          l_jobname TYPE btcjob.
   CLEAR lt_rsparams.

   LOOP AT gr_system .
     lt_rsparams-selname = 'SO_SYS'.
     lt_rsparams-kind    = 'S'.
     lt_rsparams-sign    = gr_system-sign.
     lt_rsparams-option  = gr_system-option.
     lt_rsparams-low     = gr_system-low.
     lt_rsparams-high    = gr_system-high.
     APPEND lt_rsparams.
     CLEAR lt_rsparams.
   ENDLOOP.

   CALL FUNCTION '/PSYNG/BASIS_CREATE_VARIANT'
        EXPORTING
             i_report    = '/PSYNG/SW_144'
        IMPORTING
             e_variant   = l_variant
        TABLES
             it_rsparams = lt_rsparams
             et_return   = lt_return
        EXCEPTIONS
             failed      = 1
             OTHERS      = 2.
   IF sy-subrc NE 0.
     CLEAR l_variant.
   ENDIF.
   l_jobname = 'SE - Update System Info'(j01).
   CALL FUNCTION '/PSYNG/BASIS_CREATE_NEW_JOB'
        EXPORTING
             i_jobname                      = l_jobname
             i_report_name                  = '/PSYNG/SW_144'
             i_direct_start                 = 'X'
             i_variant_name                 = l_variant
             i_jobclass                     = 'C'
        IMPORTING
             e_jobcount                     = l_tbtco-jobcount
        EXCEPTIONS
             submit_bad_priparams           = 1
             submit_bad_xpgflags            = 2
             submit_invalid_jobdata         = 3
             submit_jobname_missing         = 4
             submit_job_notex               = 5
             submit_job_failed              = 6
             submit_lock_failed             = 7
             submit_program_missing         = 8
             submit_prog_abap_and_extpg_set = 9
             open_cant_create_job           = 10
             open_invalid_job_data          = 11
             open_jobname_missing           = 12
             close_cant_start_immediate     = 13
             close_invalid_startdate        = 14
             close_jobname_missing          = 15
             close_job_close_failed         = 16
             close_job_nosteps              = 17
             close_job_notex                = 18
             close_lock_failed              = 19
             close_job_failed               = 20
             OTHERS                         = 21.
*          .
   IF sy-subrc <> 0.
     MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
             WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ELSE.
     MESSAGE s002 WITH 'Job Scheduled Successfully'(s10).
   ENDIF.
*


 ENDFORM.
