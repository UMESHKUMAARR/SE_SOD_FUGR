*----------------------------------------------------------------------*
***INCLUDE LZSW_REVIEW_SCREENF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  tcod_exe_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM tcod_exe_det.
  IF NOT gw_summary-userid IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_MC_SHOW_EXECUTION'
         EXPORTING
              i_bname      = gw_summary-userid
              i_start_date = g_from_date
              i_end_date   = g_to_date
              i_vrsio      = g_vrsio
              i_conid      = g_conid
              i_swaudid    = gcaid.
  ELSE.
    MESSAGE i002(/psyng/sw) WITH
    'Execution Details are only supported for'(e01)
    'User Assignments'(e02).
  ENDIF.

ENDFORM.                    " tcod_exe_det
*&---------------------------------------------------------------------*
*&      Form  tcod_chg_made
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM tcod_chg_made.
  IF NOT gw_summary-userid IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_MC_SHOW_CHANGES'
         EXPORTING
              i_bname      = gw_summary-userid
              i_start_date = g_from_date
              i_end_date   = g_to_date
              i_vrsio      = g_vrsio
              i_conid      = g_conid
              i_swaudid    = gcaid.
  ELSE.
    MESSAGE i002(/psyng/sw) WITH
    'Change Details are only supported for'(e03)
    'User Assignments'(e02).
  ENDIF.
ENDFORM.                    " tcod_chg_made
*&---------------------------------------------------------------------*
*&      Form  am_alerts_open
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM am_alerts_open.
  CALL FUNCTION '/PSYNG/SW_MC_SHOW_AMALERTS'
       EXPORTING
            i_bname      = gw_summary-userid
            i_start_date = g_from_date
            i_end_date   = g_to_date
            i_vrsio      = g_vrsio
            i_conid      = g_conid
            i_swaudid    = gcaid.

ENDFORM.                    " am_alerts_open
*&---------------------------------------------------------------------*
*&      Form  call_sod_rep
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_sod_rep.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  iseltab-selname = 'USERLIST'.       "Call from Summary
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_user.
  APPEND iseltab.

  iseltab-selname = 'USRTYPE'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'A'.
  APPEND iseltab.

  iseltab-selname = 'SPCONFS'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_conid.
  APPEND iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_vrsio.
  APPEND iseltab.

  iseltab-selname = 'LVL1'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'LVL3ST'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_from_date.
  APPEND iseltab.

  iseltab-selname = 'LVL3ED'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_to_date.
  APPEND iseltab.

  iseltab-selname = 'XMC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SHOSUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ''.
  APPEND iseltab.

  iseltab-selname = 'SHODET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  SUBMIT /psyng/sodreport_sys_wide_org WITH SELECTION-TABLE iseltab
AND RETURN.



ENDFORM.                    " call_sod_rep
*&---------------------------------------------------------------------*
*&      Form  call_ca_rep
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_ca_rep.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  iseltab-selname = 'PBNAME'.       "Call from Summary
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_user.
  APPEND iseltab.

  iseltab-selname = 'USRTYPE'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'A'.
  APPEND iseltab.

  iseltab-selname = 'PAUDID'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gcaid.
  APPEND iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_vrsio.
  APPEND iseltab.

  iseltab-selname = 'SUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ''.
  APPEND iseltab.

  iseltab-selname = 'DET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'XMC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  SUBMIT /psyng/sw_crit_auths WITH SELECTION-TABLE iseltab
AND RETURN.

ENDFORM.                    " call_ca_rep
*&---------------------------------------------------------------------*
*&      Form  attach_open
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM attach_open.
  gs_signoff = gw_summary .
  CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
   EXPORTING
     if_signoff               = 'X'
     if_list                  = 'X'
     i_mcid                   = g_contid
     is_signoff               = gs_signoff
*   IMPORTING
*     EF_HAS_ATTACHMENTS       =
*     E_NR_ATTACHMENTS         =
   EXCEPTIONS
     invalid_input            = 1
     not_implemented          = 2
     gos_failure              = 3
     OTHERS                   = 4
            .
  IF sy-subrc <> 0.
    MESSAGE e002(/psyng/sw) WITH 'Loading attachments failed.'(e05).
  ENDIF.

ENDFORM.                    " attach_open
*&---------------------------------------------------------------------*
*&      Form  attach_create
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM attach_create.
  gs_signoff = gw_summary.
  CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
       EXPORTING
            if_signoff      = 'X'
            if_add          = 'X'
            i_mcid          = g_contid
            is_signoff      = gs_signoff
       EXCEPTIONS
            invalid_input   = 1
            not_implemented = 2
            gos_failure     = 3
            OTHERS          = 4.
  IF sy-subrc <> 0.
    MESSAGE e002(/psyng/sw) WITH 'Creating attachment failed.'(e04).
  ENDIF.

ENDFORM.                    " attach_create

*&---------------------------------------------------------------------*
*&      Form  ASSIGN_VALUES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM assign_values.

  g_from_date = gw_details-from_date.
  g_to_date   = gw_details-to_date.


  CLEAR :  g_user, g_user_nm, g_agr_name,g_agr_desc.
  IF NOT gw_summary-userid IS INITIAL.
    g_user      = gw_details-target_id.
    g_user_nm   = gw_details-target_desc.
  ENDIF.
  IF NOT gw_summary-agr_name IS INITIAL.
    g_agr_name  = gw_summary-agr_name.
  ENDIF.

  CASE gw_summary-type .
    WHEN '1' OR '0' OR ''.
      g_assign_type = 'User Assignment'(t11).
      g_user      = gw_details-target_id.
      g_user_nm   = gw_details-target_desc.
    WHEN '2'.
      g_assign_type = 'Usergroup Assignment'(t12).
    WHEN '3'.
      g_assign_type = 'Critical Auth User Assignment'(t14).
      g_crauth_desc = gw_details-assign_desc.
      g_user        = gw_details-target_id.
      g_user_nm     = gw_details-target_desc.
    WHEN '4'.
      g_assign_type = 'Role Assignment'(t15).
      IF gw_summary-userid IS INITIAL.
        g_agr_name    = gw_details-target_id.
        g_agr_desc    = gw_details-target_desc.
      ENDIF.
    WHEN '5'.
      g_assign_type = 'Critical Auth Role Assignment'(t17).
      IF gw_summary-userid IS INITIAL.
        g_agr_name    = gw_details-target_id.
        g_agr_desc    = gw_details-target_desc.
      ENDIF.
  ENDCASE.

*g_assign_type = gw_details-assign_type.

*
  g_vrsio     = gw_details-vrsio.
  g_conid     = gw_summary-conid.
  g_org_abb   = gw_details-org_abb.
  g_conid_nm  = gw_details-assign_desc.
  gcaid       = gw_summary-swaudid.
  g_contid    = gw_details-contid.
  g_auditor   = gw_details-auditor.
  g_auditor_nm = gw_details-auditor_name.
  g_mit_desc = gw_details-contid_desc.
  IF gw_details-tcode_executed <> space.
    g_cexe = 'X'.
  ENDIF.
  IF gw_details-changes_made <> space.
    g_cchg = 'X'.
  ENDIF.
  IF gw_details-am_alerts_open <> space.
    g_coam = 'X'.
  ENDIF.
* Justification/ attach. reqd
  SELECT SINGLE manual_just manual_attach FROM /psyng/mcrvwhdr INTO
    (g_cjust, g_catt) WHERE contid = gw_details-contid.
  g_ctype = gw_summary-type.
ENDFORM.                    " ASSIGN_VALUES
*&---------------------------------------------------------------------*
*&      Form  GET_TEXT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_text.
  DATA: lv_txt_id LIKE /psyng/mcrvwhdr-dflt_review.
  DATA: lt_list TYPE TABLE OF /psyng/mcrvwtxt,
        lt_detail TYPE TABLE OF /psyng/mcrvwtxt,
        lw_detail LIKE LINE OF lt_detail.
  DATA: lt_mcrvhdr TYPE TABLE OF /psyng/mcrvwhdr,
        lw_mcrvhdr TYPE /psyng/mcrvwhdr,
        lv_langu TYPE sy-langu,
        lt_line TYPE TABLE OF tline,
        lw_line LIKE LINE OF lt_line.

  IF text_editor IS INITIAL.

    CREATE OBJECT container EXPORTING container_name = 'TXTBOX'.

    CREATE OBJECT text_editor EXPORTING parent            = container
                                        wordwrap_mode     =
    cl_gui_textedit=>wordwrap_at_fixed_position
               wordwrap_to_linebreak_mode = cl_gui_textedit=>true
               max_number_chars           = 1024.

    CALL METHOD text_editor->set_toolbar_mode
         EXPORTING
           toolbar_mode           = cl_gui_textedit=>false
         EXCEPTIONS
           error_cntl_call_method = 1
           invalid_parameter      = 2
           OTHERS                 = 3 .
    IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.
  IF gt_texttab[] IS INITIAL.
*****to put some text in the text editor.
    SELECT SINGLE * FROM /psyng/mcrvwhdr INTO lw_mcrvhdr
    WHERE contid = gw_details-contid.
    IF sy-subrc = 0.
      lv_langu = sy-langu.
      CALL FUNCTION 'READ_TEXT'
           EXPORTING
                id                      = 'ST'
                language                = lv_langu
                name                    = lw_mcrvhdr-dflt_review
                object                  = 'TEXT'
           TABLES
                lines                   = lt_line
           EXCEPTIONS
                id                      = 1
                language                = 2
                name                    = 3
                not_found               = 4
                object                  = 5
                reference_check         = 6
                wrong_access_to_archive = 7
                OTHERS                  = 8.
      IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.
      REFRESH gt_texttab.
      LOOP AT lt_line INTO lw_line.
        gw_texttab-line = lw_line-tdline.
        APPEND gw_texttab TO gt_texttab.
        CLEAR gw_texttab.
      ENDLOOP.
      CLEAR lw_detail.
      REFRESH lt_detail.
      CALL METHOD text_editor->set_text_as_r3table
        EXPORTING
          table           = gt_texttab       "
        EXCEPTIONS
          error_dp        = 1
          error_dp_create = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
      ENDIF.
      CALL METHOD cl_gui_cfw=>flush
                 EXCEPTIONS
                   OTHERS = 1.
    ENDIF.
  ENDIF.

ENDFORM.                    " GET_TEXT
*&---------------------------------------------------------------------*
*&      Form  create_sign_off
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_sign_off.

  DATA: l_att_exist TYPE flag,
        l_just_exist TYPE flag,
        lt_texttab TYPE soli_tab.
  DATA: lt_text TYPE TABLE OF solisti1,
        ls_text LIKE LINE OF lt_text,
        l_string TYPE string,
        ls_texttab LIKE LINE OF gt_texttab,
        l_stext_modified TYPE i.
  DATA  lt_mit_editor_new_reset TYPE TABLE OF /psyng/longtextfield.
* Attachment required
  IF g_catt = 'X'.
    gs_signoff = gw_summary .
    CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
         EXPORTING
              if_signoff         = 'X'
              if_check           = 'X'
              i_mcid             = g_contid
              is_signoff         = gs_signoff
         IMPORTING
              ef_has_attachments = l_att_exist
         EXCEPTIONS
              invalid_input      = 1
              not_implemented    = 2
              gos_failure        = 3
              OTHERS             = 4.            "#EC SAST_CI_GEN_CHECK
    "(++)BOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    "(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_att_exist <> 'X'.
      MESSAGE i140(/psyng/sw) WITH text-t01.
    ENDIF.
  ELSE.
    l_att_exist = 'X'.
  ENDIF.
*--Get the justification text from the text control
  CALL METHOD text_editor->get_text_as_r3table
                    IMPORTING
                        table = lt_texttab
                    EXCEPTIONS
                        OTHERS = 1.
  IF sy-subrc NE 0.
    MESSAGE e800(bmen).
  ENDIF.
  CALL METHOD cl_gui_cfw=>flush
               EXCEPTIONS
                 OTHERS = 1.
  LOOP AT lt_texttab INTO ls_texttab .
    CONCATENATE l_string ls_texttab-line INTO l_string.
  ENDLOOP.
*   Justification required
  IF g_cjust = 'X'.
*BOC AKUMAR 07-03-2025 PN-11851
    gs_signoff = gw_summary .
*BOC AKUMAR 07-03-2025 PN-11851
    IF l_string IS INITIAL.
      l_just_exist = ''.
      MESSAGE i140(/psyng/sw) WITH text-t02.
    ELSE.
      l_just_exist = 'X'.
    ENDIF.
  ELSE.
    l_just_exist = 'X'.
  ENDIF.
  IF l_just_exist = 'X' AND l_att_exist = 'X'.
*--All pre-requisites are met, store text and register signoff
    IF NOT l_string IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
           EXPORTING
*                if_assignment        = 'X'
                if_signoff           = 'X'
                if_add               = 'X'
                i_mcid               = gw_details-contid
                is_signoff           = gs_signoff
*                i_justification_text = l_string.
          TABLES
                it_text              = lt_texttab
          EXCEPTIONS
                  invalid_input        = 1
                  not_implemented      = 2
                  gos_failure          = 3
                  OTHERS               = 4.
      IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

    ENDIF.

    UPDATE /psyng/mcrvwsgn SET
          signoff_date      = sy-datum
          signoff_time      = sy-uzeit
          signoff_complete  = 'X'
          signoff_type      = 'M'
     WHERE signoffid        = gw_details-signoffid.
    IF sy-subrc = 0.
** Reset text
      REFRESH lt_mit_editor_new_reset .
      CALL METHOD text_editor->set_text_as_r3table
        EXPORTING
          table           = lt_mit_editor_new_reset
        EXCEPTIONS
          error_dp        = 1
          error_dp_create = 2
          OTHERS          = 3.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CALL METHOD cl_gui_cfw=>flush
               EXCEPTIONS
                 OTHERS = 1.
      MESSAGE s140(/psyng/sw) WITH text-t03. "Success
      LEAVE TO SCREEN 0.
    ELSE.
      MESSAGE s140(/psyng/sw) WITH text-t04. "Fail
    ENDIF.
  ENDIF.
ENDFORM.                    " create_sign_off
*&---------------------------------------------------------------------*
*&      Form  init_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_values.
  CLEAR:

   g_from_date ,
      g_to_date,
      g_user,
      g_user_nm,
      g_vrsio,
      g_conid,
      g_agr_name,
      g_agr_desc,
      g_contid,
      g_auditor,
      g_auditor_nm,
      g_mit_desc,
      g_conid_nm,
      g_assign_type,
      g_crauth_desc,
      g_cexe,
      g_cchg,
      g_coam,
      g_cjust,
      g_catt,
      g_ctype,
      gcaid,
      w_lines,
      gw_details,
      gw_summary,
      gw_texttab,
      g_org_abb.
  REFRESH: gt_rfcdes,
           gt_lines,
           gt_texttab.
ENDFORM.                    " init_values
*&---------------------------------------------------------------------*
*&      Form  call_rolesod_rep
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_roleca_rep.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  iseltab-selname = 'ROLES'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_agr_name.
  APPEND iseltab.

  iseltab-selname = 'PAUDID'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gcaid.
  APPEND iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_vrsio.
  APPEND iseltab.

  iseltab-selname = 'COMPROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SINGROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'P_SHOMIT'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ''.
  APPEND iseltab.

  iseltab-selname = 'DET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.


  SUBMIT /psyng/sw_crit_auths_byrole WITH SELECTION-TABLE iseltab
    AND RETURN.
ENDFORM.                    " call_rolesod_rep
*&---------------------------------------------------------------------*
*&      Form  call_rolesod_rep
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_rolesod_rep.

  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  iseltab-selname = 'ROLE'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_agr_name.
  APPEND iseltab.

  iseltab-selname = 'PAUDID'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gcaid.
  APPEND iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = g_vrsio.
  APPEND iseltab.

  iseltab-selname = 'COMPROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SINGROL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'XMC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SHOSUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ''.
  APPEND iseltab.

  iseltab-selname = 'SHODET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  SUBMIT /psyng/sod_syswide_byrole WITH SELECTION-TABLE iseltab
      AND RETURN.

ENDFORM.                    " call_rolesod_rep
