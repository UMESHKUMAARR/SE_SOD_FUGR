*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_FIORIAI01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE sy-ucomm.
    WHEN 'PICK'.
      CALL FUNCTION 'CALL_BROWSER' "##FM_SUBRC_OK
           EXPORTING
                url                    = gs_more_info_url
           EXCEPTIONS
                frontend_not_supported = 1
                frontend_error         = 2
                prog_not_found         = 3
                no_batch               = 4
                unspecified_error      = 5
                OTHERS                 = 6."#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'CREATE'.
      PERFORM create_new_fioriid.
    WHEN 'DELETE'.
      PERFORM delete_fiori_id.
    WHEN 'SAVE'.
*--Save in DB tables
      PERFORM save_data.
    WHEN OTHERS.
  ENDCASE.
  CLEAR sy-ucomm.
ENDMODULE.                 " USER_COMMAND_0100  INPUT

* INPUT MODULE FOR TABSTRIP 'FIORI_APP_DET': GETS ACTIVE TAB
MODULE fiori_app_det_active_tab_get INPUT.
  ok_code = sy-ucomm.
  CASE ok_code.
    WHEN gc_fiori_app_det-tab1.
      gs_fiori_app_det-pressed_tab = gc_fiori_app_det-tab1.
    WHEN gc_fiori_app_det-tab2.
      gs_fiori_app_det-pressed_tab = gc_fiori_app_det-tab2.
    WHEN gc_fiori_app_det-tab3.
      gs_fiori_app_det-pressed_tab = gc_fiori_app_det-tab3.
    WHEN gc_fiori_app_det-tab4.
      gs_fiori_app_det-pressed_tab = gc_fiori_app_det-tab4.
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  validate_fioriid  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE validate_fioriid INPUT.

  PERFORM validate_fioriid.

ENDMODULE.                 " validate_fioriid  INPUT
*&---------------------------------------------------------------------*
*&      Module  get_text_0101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE get_text_0101 INPUT.

  CHECK NOT gf_edit IS INITIAL.
  IF gf_load_new_app IS INITIAL.
    REFRESH gt_text.
    CALL METHOD go_text_editor->get_text_as_stream
      IMPORTING
        text                   = gt_text
      EXCEPTIONS
        error_dp               = 1
        error_cntl_call_method = 2
        OTHERS                 = 3
            .
    IF sy-subrc <> 0.
    ENDIF.
  ELSE.
    CLEAR gf_load_new_app.
  ENDIF.
ENDMODULE.                 " get_text_0101  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_0102  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0102 INPUT.
  CALL METHOD go_alvgrid_services->check_changed_data.
ENDMODULE.                 " user_command_0102  INPUT
*&---------------------------------------------------------------------*
*&      Module  user_command_0104  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0104 INPUT.
  CALL METHOD go_alvgrid_notes->check_changed_data.
ENDMODULE.                 " user_command_0104  INPUT
*&---------------------------------------------------------------------*
*&      Module  cancel_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE cancel_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      gs_fiori_app_det-pressed_tab = gc_fiori_app_det-tab1.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
  CLEAR sy-ucomm.
ENDMODULE.                 " cancel_0100  INPUT
