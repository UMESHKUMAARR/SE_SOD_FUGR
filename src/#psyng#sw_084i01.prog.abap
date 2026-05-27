***INCLUDE /PSYNG/SW_084I01 .
*&spwizard: input module for tc 'TC_SODVERS'. do not change this line!
*&spwizard: modify table
MODULE tc_sodvers_modify INPUT.
  PERFORM validate.
  MODIFY gt_sodvers INDEX tc_sodvers-current_line.
  IF sy-subrc <> 0.
    APPEND gt_sodvers.
  ENDIF.
gt_change = gt_sodvers.
append gt_change.
  gf_data_change = 'X'.
ENDMODULE.

*&spwizard: input modul for tc 'TC_SODVERS'. do not change this line!
*&spwizard: mark table
MODULE tc_sodvers_mark INPUT.
  IF tc_sodvers-line_sel_mode = 1.
    LOOP AT gt_sodvers INTO gs_tc_sodvers WHERE sel = 'X'.
      gs_tc_sodvers-sel = ''.
      MODIFY gt_sodvers FROM gs_tc_sodvers TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_sodvers INDEX tc_sodvers-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_SODVERS'. do not change this line!
*&spwizard: process user command
MODULE tc_sodvers_user_command INPUT.
  ok_code = sy-ucomm.
  CLEAR sy-ucomm.
  PERFORM user_ok_tc USING    'TC_SODVERS'
                              'GT_SODVERS'
                              'SEL'
                     CHANGING ok_code.
  IF NOT ok_code = 'INSR'.
    CLEAR ok_code.
  ENDIF.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  exit  INPUT
*&---------------------------------------------------------------------*
*       Exit transaction
*----------------------------------------------------------------------*
MODULE exit INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      gf_answer = 1.

*     If data was changed, ask if user wants to exit without saving
      IF gf_data_change = 'X'.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
             EXPORTING
                  text_question         = text-q01
                  text_button_1         = text-004
                  icon_button_1         = 'ICON_CHECKED'
                  text_button_2         = text-005
                  icon_button_2         = 'ICON_INCOMPLETE'
                  default_button        = '2'
                  display_cancel_button = ' '
             IMPORTING
                  answer                = gf_answer
             EXCEPTIONS
                  text_not_found        = 1
                  OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.

      IF gf_answer = '1'.
        PERFORM dequeue.
        LEAVE PROGRAM.
      ENDIF.

    WHEN 'CANCEL'.
      PERFORM dequeue.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.                 " exit  INPUT
