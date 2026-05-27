FUNCTION /psyng/sw_mc_email_wf_callback .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_TOKEN) TYPE  /PSYNG/TEXT25 OPTIONAL
*"     VALUE(I_DECISION) TYPE  /PSYNG/TEXT25 OPTIONAL
*"     VALUE(I_USERNAME) TYPE  XUBNAME OPTIONAL
*"     VALUE(I_BODY) TYPE  STRING OPTIONAL
*"     VALUE(IT_ATTACH_DATA) TYPE  /PSYNG/SW_EMAIL_ATTACH_DATA_TT
*"       OPTIONAL
*"  TABLES
*"      IT_PARAMETERS STRUCTURE  /PSYNG/EMAIL_PARAMETER
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_MC_EMAIL_WF_CALLBACK'.
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

  DATA : ls_se_token TYPE /psyng/se_emldec.
  DATA : l_decision  TYPE /psyng/se_emldec,
         lt_logging  TYPE TABLE OF /psyng/bc_emllog WITH HEADER LINE.

  DATA: ls_config    TYPE /psyng/er_config_param.
  DATA : lt_decision TYPE TABLE OF /psyng/se_emldec WITH HEADER LINE,
         l_rfcdest TYPE rfcdes-rfcdest,
         ls_central_rfc TYPE /psyng/er_config_param,
         l_message    TYPE sm04dic-popupmsg,
         part1(10),

         l_sysid TYPE sy-sysid,
         l_linenr TYPE menu_num_5,
         ls_text_append(240) TYPE  c,
         l_date(10) TYPE c,
         l_time(8) TYPE c,
         lt_text_append TYPE TABLE OF string,
         l_len TYPE i,
         l_rest TYPE string,
         l_contid TYPE /psyng/mcrvwhdr-contid,
         l_signoffid TYPE /psyng/mcrvwsgn-signoffid,
         ls_mcrvwhdr TYPE /psyng/mcrvwhdr,
         l_justification_added TYPE flag,
         l_attachment_added    TYPE flag,
         l_justification_required TYPE flag,
         l_attachment_required    TYPE flag,

         ls_signoff TYPE /psyng/mcrvwsgn,
         l_borident TYPE borident,
         ls_assignment_dummy TYPE /psyng/mitigation_assignment.
  lt_logging-modul = 'SE'.

*--Get RFC destination to E-Mail SIgnoff System
  se_config_param 'APPROVAL_CENTRAL_SYS' l_rfcdest.

*--Load decision Record
  SELECT SINGLE *
  FROM /psyng/se_emldec
  INTO ls_se_token
  WHERE token  = i_token
  AND userid   = i_username
  AND decision = i_decision.
  IF sy-subrc <> 0.
    lt_logging-type       = 'E'.
    lt_logging-paramname  = 'ERROR'.
    lt_logging-paramvalue = 'Problem with Token'.
    APPEND lt_logging.
  ELSE.
    IF i_decision CP 'SO*'.
      MOVE ls_se_token-objectkey TO  ls_signoff-signoffid.
*--Get the signoff record
      SELECT SINGLE * FROM /psyng/mcrvwsgn INTO  ls_signoff
            WHERE signoffid = ls_signoff-signoffid.
      IF sy-subrc  <> 0.
        lt_logging-type       = 'E'.
        lt_logging-paramname  = 'ERROR'.
        lt_logging-paramvalue = 'Invalid Signoff Id'.
        APPEND lt_logging.
      ELSE.
*--Get the mitigation header info (justification or attachment required)
        SELECT SINGLE * FROM /psyng/mcrvwhdr INTO ls_mcrvwhdr
               WHERE contid =  ls_signoff-contid.
        l_attachment_required    = ls_mcrvwhdr-manual_attach.
        l_justification_required = ls_mcrvwhdr-manual_just.
*--Get object ID for signoff record
        PERFORM create_obj_id
              USING
                 ls_signoff-contid
                 ''
                 ''
                 'X'
                 ls_assignment_dummy
                 ls_signoff
              CHANGING
                 l_borident-objkey.

        IF NOT i_body IS INITIAL.
*-- Store the body of the e-mail as the justification
          CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
               EXPORTING
                    if_signoff           = 'X'
                    if_add               = 'X'
                    i_mcid               = ls_signoff-contid
                    is_assignment        = ls_assignment_dummy
                    is_signoff           = ls_signoff
                    i_justification_text = i_body
                    i_bname              = I_USERNAME
               EXCEPTIONS
                    invalid_input        = 1
                    OTHERS               = 2.
          IF sy-subrc <> 0.
            lt_logging-type       = 'E'.
            lt_logging-paramname  = 'ERROR'.
            lt_logging-paramvalue = 'Saving justification Failed'.
            APPEND lt_logging.
          ENDIF.
          l_justification_added = 'X'.
*-- Store any attachments that were provided
          IF NOT it_attach_data IS INITIAL.
            l_borident-objtype = '/PSYNG/SEM'.
            CALL FUNCTION '/PSYNG/BC_ATTACH_EMAIL_TO_SAP'
                 EXPORTING
                      i_borident     = l_borident
                      it_attach_data = it_attach_data.
            l_attachment_added = 'X'.
          ENDIF.

*--If the mandatory information is provided, mark the signoff record
*  as manually signed off
          IF
            (
              (
                l_justification_added     = 'X' AND
                l_justification_required  = 'X'
               )
               OR
               ( l_justification_required <> 'X' )
            )
            AND
            (
              (
                l_attachment_added     = 'X' AND
                l_attachment_required  = 'X'
               )
               OR
               ( l_attachment_required <> 'X' )
            ).

            UPDATE /psyng/mcrvwsgn SET
                                    signoff_date      = sy-datum
                                    signoff_time      = sy-uzeit
                                    signoff_complete  = 'X'
                                    signoff_type      = 'M'
                               WHERE signoffid   = ls_signoff-signoffid.


** 3. Invalidate all tokens related to this decision
**Get all the related decisions
            SELECT *
              FROM /psyng/se_emldec
              INTO CORRESPONDING FIELDS OF TABLE lt_decision
              WHERE sw_module =  ls_se_token-sw_module
              AND   objectkey =  ls_se_token-objectkey.

            LOOP AT lt_decision.
               CHECK NOT (
                 lt_decision-token    = i_token AND
                 lt_decision-decision = i_decision AND
                 lt_decision-userid   = i_username
                 ).

*--Invalidate the decisions
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
              CALL FUNCTION '/PSYNG/BC_029'
              DESTINATION l_rfcdest
                EXPORTING
                  i_username        = lt_decision-userid
                  i_decision        = lt_decision-decision
                  i_token           = lt_decision-token
                  i_sysid           = sy-sysid
                  i_mandt           = sy-mandt
                EXCEPTIONS
                  decision_required = 1
                  token_required    = 2
                  OTHERS            = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

              IF sy-subrc <> 0.
                MOVE-CORRESPONDING lt_decision TO lt_logging.
                lt_logging-type       = 'E'.
                lt_logging-paramname  = 'ERROR'.
                CASE sy-subrc.
                  WHEN 1.
                    lt_logging-paramvalue =
                    'Invalidate Decision failed: DECISION_REQUIRED'.
                  WHEN 2.
                    lt_logging-paramvalue =
                    'Invalidate Decision failed: TOKEN_REQUIRED'.
                  WHEN OTHERS.
                    lt_logging-paramvalue =
                    'Invalidate Decision failed: UNKNOWN_ERROR'.
                ENDCASE.
                APPEND lt_logging.
              ENDIF.
            ENDLOOP.
*--Delete the processed decisions from the SE Decision table
            DELETE
                FROM /psyng/se_emldec
                WHERE sw_module =  ls_se_token-sw_module
                AND   objectkey =  ls_se_token-objectkey.
*4. Log Decision


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
            CALL FUNCTION '/PSYNG/BC_030'
            DESTINATION l_rfcdest
                 TABLES
                      it_log = lt_logging. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFUNCTION.
