*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_SYNC_SENSTIVITY_PO01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0001  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0001 OUTPUT.

  DATA: ls_stable TYPE lvc_s_stbl.

*--Show/Remove save button
  IF gf_dispchg = gc_change.
    SET PF-STATUS 'STATUS'.
  ELSE.
    SET PF-STATUS 'STATUS' EXCLUDING 'SAVE'.
  ENDIF.
  SET TITLEBAR 'TITLE'.

  " Create controls and fill ALV only once
  IF go_grid IS INITIAL.

    " Load data first
    PERFORM get_sens_data.

    " Create custom container
    CREATE OBJECT go_cc
      EXPORTING
        container_name = 'CC_ALV'.

    " Create ALV grid control inside custom container
    CREATE OBJECT go_grid
      EXPORTING
        i_parent = go_cc.

    " Build field catalog
    CLEAR gs_fcat.
    gs_fcat-fieldname = 'SE_IMP'.
    gs_fcat-coltext   = 'SE sensitivity'(001).
    gs_fcat-scrtext_m   = 'SE sensitivity'(001).
    gs_fcat-scrtext_l   = 'SE sensitivity'(001).
    gs_fcat-edit      = 'X'.
    gs_fcat-col_pos   = 1.
    gs_fcat-lowercase = 'X'.
    gs_fcat-outputlen = 8.
    gs_fcat-ref_table   = '/PSYNG/SWIMPSYNC'.
    gs_fcat-ref_field   = 'SE_IMP'.
    APPEND gs_fcat TO gt_fcat.

    CLEAR gs_fcat.
    gs_fcat-fieldname = 'PLC_IMP'.
    gs_fcat-coltext   = 'PLC sensitivity'(002).
    gs_fcat-scrtext_m = 'PLC sensitivity'(002).
    gs_fcat-scrtext_l = 'PLC sensitivity'(002).
    gs_fcat-edit      = 'X'.
    gs_fcat-col_pos   = 2.
    gs_fcat-lowercase = 'X'.
    gs_fcat-outputlen = 200.
    APPEND gs_fcat TO gt_fcat.

    CLEAR gs_layout.
    gs_layout-cwidth_opt = 'X'.

    " Display ALV
    CALL METHOD go_grid->set_table_for_first_display
      EXPORTING
        is_layout        = gs_layout
      CHANGING
        it_outtab        = gt_sens
        it_fieldcatalog  = gt_fcat.
  ELSE.

    CALL METHOD go_grid->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fcat.

    CALL METHOD go_grid->set_frontend_layout
      EXPORTING
        is_layout = gs_layout.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD go_grid->refresh_table_display
    EXPORTING
      i_soft_refresh = 'X'
      is_stable = ls_stable
    EXCEPTIONS
      finished       = 1
      OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.

  " Editable/Non-editable ALV grid
  IF gf_dispchg = gc_change.
    CALL METHOD go_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.
  ELSE.
    CALL METHOD go_grid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 0.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0001 INPUT.

  DATA: lt_sens_tmp TYPE TABLE OF /psyng/swimpsync,
        ls_sens_tmp TYPE /psyng/swimpsync,
        lf_answer(1) TYPE c,
        lf_dup(1) TYPE c,
        lv_tbix TYPE sy-tabix.

  FIELD-SYMBOLS: <fs_sens> TYPE /psyng/swimpsync.

  CASE sy-ucomm.

    WHEN 'BACK'.
      PERFORM exit_without_save CHANGING lf_answer.
      CHECK lf_answer = '1'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'EXIT' OR 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'SAVE'.
      " Push ALV edits into the internal table
      CALL METHOD go_grid->check_changed_data.

      LOOP AT gt_sens INTO ls_sens_tmp.
        lv_tbix = sy-tabix.
        ADD 1 TO lv_tbix.
        CLEAR lf_dup.
        LOOP AT gt_sens FROM lv_tbix TRANSPORTING NO FIELDS
          WHERE plc_imp = ls_sens_tmp-plc_imp .
          lf_dup = 'X'.
          EXIT.
        ENDLOOP.
        IF lf_dup = 'X'.
          MESSAGE e113(/psyng/sw) WITH text-008 text-009.
        ENDIF.
      ENDLOOP.
      CLEAR lv_tbix.
      " Persist the internal table to DB
      SORT gt_sens BY se_imp.
      DELETE gt_sens WHERE se_imp IS INITIAL OR
                           plc_imp IS INITIAL.

      SELECT se_imp
        plc_imp FROM /psyng/swimpsync
        INTO TABLE lt_sens_tmp.
      IF sy-subrc = 0.
        LOOP AT lt_sens_tmp INTO ls_sens_tmp.
          READ TABLE gt_sens WITH KEY se_imp = ls_sens_tmp-se_imp
                          plc_imp = ls_sens_tmp-plc_imp TRANSPORTING
                          NO FIELDS.
          IF sy-subrc <> 0.
            DELETE FROM /psyng/swimpsync WHERE se_imp =
                                              ls_sens_tmp-se_imp AND
                                       plc_imp = ls_sens_tmp-plc_imp.
          ENDIF.
        ENDLOOP.
      ENDIF.

      MODIFY /psyng/swimpsync FROM TABLE gt_sens.
      IF sy-subrc = 0.
        COMMIT WORK.
        MESSAGE 'Data saved' TYPE 'S'.
      ELSE.
        ROLLBACK WORK.
        MESSAGE 'Save failed' TYPE 'E'.
      ENDIF.


    WHEN 'DISPCHG'.
*      Set change mode Display/Change
      IF gf_dispchg = gc_display.
        gf_dispchg = gc_change.
      ELSE.
        gf_dispchg = gc_display.
      ENDIF.

  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  GET_SENS_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_sens_data.

  SELECT se_imp
         plc_imp
         FROM /psyng/swimpsync
         INTO TABLE gt_sens.
  IF sy-subrc <> 0.
    REFRESH gt_sens.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXIT_WITHOUT_SAVE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LF_ANSWER  text
*----------------------------------------------------------------------*
FORM exit_without_save  CHANGING lf_answer.

  DATA: lt_sens TYPE TABLE OF /psyng/swimpsync,
        lf_data_changed(1) TYPE c.
  lf_answer = '1'.
  CALL METHOD go_grid->check_changed_data.

  SELECT * FROM /psyng/swimpsync INTO TABLE lt_sens.
  IF sy-subrc = 0.
    SORT lt_sens BY se_imp plc_imp.
    LOOP AT gt_sens INTO gs_sens.
      READ TABLE lt_sens WITH KEY se_imp = gs_sens-se_imp
                                  plc_imp = gs_sens-plc_imp
                                  TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        lf_data_changed = 'X'.
        EXIT.
      ELSE.
        CLEAR lf_data_changed.
      ENDIF.
    ENDLOOP.
  ELSE.
    IF gt_sens IS NOT INITIAL.
      lf_data_changed = 'X'.
    ELSE.
      CLEAR lf_data_changed.
    ENDIF.
  ENDIF.

  IF lf_data_changed = 'X'.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar       = 'Confirm Exit'(005)
        text_question  = text-006
        text_button_1  = 'Yes'(003)
        icon_button_1  = 'ICON_OKAY'
        text_button_2  = 'No'(004)
        icon_button_2  = 'ICON_CANCEL'
        default_button = '2'
        display_cancel_button = space
      IMPORTING
        answer         = lf_answer.
  ENDIF.



ENDFORM.
