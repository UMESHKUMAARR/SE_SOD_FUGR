*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_097I01                                           *
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       MODULE TC_REMCON_modify INPUT                                 *
*---------------------------------------------------------------------*
MODULE tc_remcon_modify INPUT.
  PERFORM validate.

  MODIFY gt_remcon INDEX tc_remcon-current_line.
  IF sy-subrc <> 0.
    APPEND gt_remcon.
  ENDIF.

  gf_data_change = 'X'.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE TC_REMCON_mark INPUT                                   *
*---------------------------------------------------------------------*
MODULE tc_remcon_mark INPUT.
  IF tc_remcon-line_sel_mode = 1.
    LOOP AT gt_remcon INTO gs_remcon WHERE sel = 'X'.
      gs_remcon-sel = ''.
      MODIFY gt_remcon FROM gs_remcon TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_remcon INDEX tc_remcon-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_REMCON'. do not change this line!
*&spwizard: process user command
MODULE tc_remcon_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_REMCON'
                              'GT_REMCON'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
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
                  text_question         = text-003
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

      IF gf_answer = 1.
        PERFORM dequeue.
        LEAVE PROGRAM.
      ENDIF.

    WHEN 'CANCEL'.
      PERFORM dequeue.
      LEAVE PROGRAM.
  ENDCASE.
ENDMODULE.                 " exit  INPUT
