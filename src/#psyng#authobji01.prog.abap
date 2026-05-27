*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUTHOBJI01
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  PAI_0400  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_100 INPUT.
  DATA: return_code TYPE i.
* CL_GUI_CFW=>DISPATCH must be called if events are registered
* that trigger PAI
* this method calls the event handler method of an event
  CALL METHOD cl_gui_cfw=>dispatch
    IMPORTING return_code = return_code.
  IF return_code <> cl_gui_cfw=>rc_noevent.
    " a control event occured => exit PAI

    CLEAR g_ok_code.
    EXIT.
  ENDIF.

  CLEAR g_ok_code.
ENDMODULE.                 " PAI_0100  INPUT

*&spwizard: input module for tc 'TC_seltab'. do not change this line!
*&spwizard: modify table
MODULE tc_seltab_modify INPUT.
  PERFORM get_field_name USING gt_select-field
                         CHANGING gt_select-ddtext.
  MODIFY gt_select INDEX tc_seltab-current_line.
*BOC:HBHALLA(PN-4547)
  READ TABLE gt_select INDEX tc_seltab-current_line.
  APPEND gt_select TO gt_chng_rec.
*EOC:HBHALLA(PN-4547)

ENDMODULE.

*&spwizard: input modul for tc 'TC_seltab'. do not change this line!
*&spwizard: mark table
MODULE tc_seltab_mark INPUT.
  DATA: g_tc_seltab_wa2 LIKE LINE OF gt_select.

  IF tc_seltab-line_sel_mode = 1 AND gt_select-sel = 'X'.
    LOOP AT gt_select INTO g_tc_seltab_wa2 WHERE sel = 'X'.
      g_tc_seltab_wa2-sel = ''.
      MODIFY gt_select FROM g_tc_seltab_wa2 TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_select INDEX tc_seltab-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_seltab'. do not change this line!
*&spwizard: process user command
MODULE tc_seltab_user_command INPUT.
  g_ok_code = sy-ucomm.
  CLEAR sy-ucomm.
  PERFORM user_ok_tc USING    'TC_SELTAB'
                              'GT_SELECT'
                              'SEL'
                     CHANGING g_ok_code.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  f4_object  INPUT
*&---------------------------------------------------------------------*
*       F4 help for authorization object
*----------------------------------------------------------------------*
MODULE f4_object INPUT.
  refresh : gt_fields.
  gt_fields-tabname = 'TOBJT'.
  gt_fields-fieldname = 'OBJECT'.
  gt_fields-selectflag = 'X'.
  APPEND gt_fields.
  gt_fields-tabname = 'TOBJT'.
  gt_fields-fieldname = 'TTEXT'.
  gt_fields-selectflag = ''.
  APPEND gt_fields.

* Get values / text for authorization object
  SELECT * INTO gl_tobjt FROM tobjt WHERE langu = sy-langu.
    gt_values-line = gl_tobjt-object.
    APPEND gt_values.
    gt_values-line = gl_tobjt-ttext.
    APPEND gt_values.
  ENDSELECT.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = text-t03
       IMPORTING
            select_value              = g_search_object
       TABLES
            fields                    = gt_fields
            valuetab                  = gt_values
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDMODULE.                 " f4_object  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_field  INPUT
*&---------------------------------------------------------------------*
*       F4 help for authorization field
*----------------------------------------------------------------------*
MODULE f4_field INPUT.
  PERFORM f4_field CHANGING gt_select-field.
ENDMODULE.                 " f4_field  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_low_value  INPUT
*&---------------------------------------------------------------------*
*       F4 help for authorization low value
*----------------------------------------------------------------------*
MODULE f4_low_value INPUT.
  PERFORM f4_value CHANGING gt_select-val_from.
ENDMODULE.                 " f4_low_value  INPUT

*&---------------------------------------------------------------------*
*&      Module  f4_high_value  INPUT
*&---------------------------------------------------------------------*
*       F4 help for authorization high value
*----------------------------------------------------------------------*
MODULE f4_high_value INPUT.
  PERFORM f4_value CHANGING gt_select-val_to.
ENDMODULE.                 " f4_high_value  INPUT

*&---------------------------------------------------------------------*
*&      Module  clear_start_pos  INPUT
*&---------------------------------------------------------------------*
*       Clear starting position for searching
*----------------------------------------------------------------------*
MODULE clear_start INPUT.
  CLEAR: g_start_pos, g_start_onode, g_start_tnode, g_start_funid.
ENDMODULE.                 " clear_start_pos  INPUT

*&---------------------------------------------------------------------*
*&      Module  exit  INPUT
*&---------------------------------------------------------------------*
*       Exit program
*----------------------------------------------------------------------*
MODULE exit INPUT.
  DESCRIBE TABLE gt_changes LINES sy-tfill.
  IF sy-tfill > 0.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar                    = text-012
        text_question               = text-q03
        text_button_1               = text-003
        icon_button_1               = 'ICON_OKAY'
        text_button_2               = text-004
        icon_button_2               = 'ICON_CANCEL'
        default_button              = '2'
        display_cancel_button       = space
      IMPORTING
        answer                      = g_answer
      EXCEPTIONS
        text_not_found              = 1
        OTHERS                      = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    CHECK g_answer = '1'.
  ENDIF.

  PERFORM free_tree.
  LEAVE PROGRAM.
ENDMODULE.                 " exit  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0900  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 900
*----------------------------------------------------------------------*
MODULE user_command_0900 INPUT.
  CASE sy-ucomm.
    WHEN 'CONTINUE' OR 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0900  INPUT
