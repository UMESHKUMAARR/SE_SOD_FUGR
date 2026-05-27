*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_LOCCFGI01 .
*----------------------------------------------------------------------*
*&spwizard: input module for tc 'TC_ORGNR_UG'. do not change this line!
*&spwizard: modify table
MODULE tc_orgnr_ug_modify INPUT.
  CHECK sy-ucomm <> 'EXIT'.

  IF sy-ucomm = 'TC_ORGNR_UG_DELE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    gt_orgnr_ug-sel = 'X'.
    MODIFY gt_orgnr_ug FROM gt_orgnr_ug INDEX tc_orgnr_ug-current_line
           TRANSPORTING sel.
    EXIT.
  ENDIF.

  PERFORM validate_100.
  MODIFY gt_orgnr_ug INDEX tc_orgnr_ug-current_line.
  IF sy-subrc <> 0.
    APPEND gt_orgnr_ug.
  ENDIF.

  gf_data_change = 'X'.
ENDMODULE.

*&spwizard: input modul for tc 'TC_ORGNR_UG'. do not change this line!
*&spwizard: mark table
MODULE tc_orgnr_ug_mark INPUT.
DATA: g_tc_orgnr_ug_wa2 LIKE LINE OF gt_orgnr_ug.

  IF tc_orgnr_ug-line_sel_mode = 1.
    LOOP AT gt_orgnr_ug INTO g_tc_orgnr_ug_wa2 WHERE sel = 'X'.
      g_tc_orgnr_ug_wa2-sel = ''.
      MODIFY gt_orgnr_ug FROM g_tc_orgnr_ug_wa2 TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_orgnr_ug INDEX tc_orgnr_ug-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_ORGNR_UG'. do not change this line!
*&spwizard: process user command
MODULE tc_orgnr_ug_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_ORGNR_UG'
                              'GT_ORGNR_UG'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.

*&spwizard: input module for tc 'TC_ORGNR_ADR'. do not change this line!
*&spwizard: modify table
MODULE tc_orgnr_adr_modify INPUT.
  CHECK sy-ucomm <> 'EXIT'.

  IF sy-ucomm = 'TC_ORGNR_ADR_DELE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    gt_orgnr_adr-sel = 'X'.
    MODIFY gt_orgnr_adr FROM gt_orgnr_adr
           INDEX tc_orgnr_adr-current_line
           TRANSPORTING sel.
    EXIT.
  ENDIF.

  PERFORM validate_200.
  MODIFY gt_orgnr_adr INDEX tc_orgnr_adr-current_line.
  IF sy-subrc <> 0.
    APPEND gt_orgnr_adr.
  ENDIF.

  gf_data_change = 'X'.
ENDMODULE.

*&spwizard: input modul for tc 'TC_ORGNR_ADR'. do not change this line!
*&spwizard: mark table
MODULE tc_orgnr_adr_mark INPUT.
DATA: g_tc_orgnr_adr_wa2 LIKE LINE OF gt_orgnr_adr.

  IF tc_orgnr_adr-line_sel_mode = 1.
    LOOP AT gt_orgnr_adr INTO g_tc_orgnr_adr_wa2 WHERE sel = 'X'.
      g_tc_orgnr_adr_wa2-sel = ''.
      MODIFY gt_orgnr_adr FROM g_tc_orgnr_adr_wa2 TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_orgnr_adr INDEX tc_orgnr_adr-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_ORGNR_ADR'. do not change this line!
*&spwizard: process user command
MODULE tc_orgnr_adr_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_ORGNR_ADR'
                              'GT_ORGNR_ADR'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.

*&spwizard: input module for tc 'TC_LOCCFG'. do not change this line!
*&spwizard: modify table
MODULE tc_loccfg_modify INPUT.
  MODIFY gt_loccfg INDEX tc_loccfg-current_line.
  IF sy-subrc <> 0.
    APPEND gt_loccfg.
  ENDIF.

  gf_data_change = 'X'.
ENDMODULE.

*&spwizard: input modul for tc 'TC_LOCCFG'. do not change this line!
*&spwizard: mark table
MODULE tc_loccfg_mark INPUT.
DATA: g_tc_loccfg_wa2 LIKE LINE OF gt_loccfg.

  IF tc_loccfg-line_sel_mode = 1.
    LOOP AT gt_loccfg INTO g_tc_loccfg_wa2 WHERE sel = 'X'.
      g_tc_loccfg_wa2-sel = ''.
      MODIFY gt_loccfg FROM g_tc_loccfg_wa2 TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_loccfg INDEX tc_loccfg-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_LOCCFG'. do not change this line!
*&spwizard: process user command
MODULE tc_loccfg_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_LOCCFG'
                              'GT_LOCCFG'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.

*&spwizard: input module for tc 'TC_ORGNR_USR'. do not change this line!
*&spwizard: modify table
MODULE tc_orgnr_usr_modify INPUT.
  CHECK sy-ucomm <> 'EXIT'.

  IF sy-ucomm = 'TC_ORGNR_USR_DELE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
    gt_orgnr_usr-sel = 'X'.
    MODIFY gt_orgnr_usr FROM gt_orgnr_usr
           INDEX tc_orgnr_usr-current_line
           TRANSPORTING sel.
    EXIT.
  ENDIF.

  PERFORM validate_400.
  MODIFY gt_orgnr_usr INDEX tc_orgnr_usr-current_line.
  IF sy-subrc <> 0.
    APPEND gt_orgnr_usr.
  ENDIF.

  gf_data_change = 'X'.
ENDMODULE.

*&spwizard: input modul for tc 'TC_ORGNR_USR'. do not change this line!
*&spwizard: mark table
MODULE tc_orgnr_usr_mark INPUT.
DATA: g_tc_orgnr_usr_wa2 LIKE LINE OF gt_orgnr_usr.
  IF tc_orgnr_usr-line_sel_mode = 1.
     LOOP AT gt_orgnr_usr INTO g_tc_orgnr_usr_wa2 WHERE sel = 'X'.
       g_tc_orgnr_usr_wa2-sel = ''.
       MODIFY gt_orgnr_usr FROM g_tc_orgnr_usr_wa2 TRANSPORTING sel.
     ENDLOOP.
  ENDIF.

  MODIFY gt_orgnr_usr INDEX tc_orgnr_usr-current_line TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_ORGNR_USR'. do not change this line!
*&spwizard: process user command
MODULE tc_orgnr_usr_user_command INPUT.
  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_ORGNR_USR'
                              'GT_ORGNR_USR'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  f4_addrnumber  INPUT
*&---------------------------------------------------------------------*
*       F4 Value help for Address number
*----------------------------------------------------------------------*
MODULE f4_addrnumber INPUT.
  PERFORM f4_addrnumber CHANGING gt_orgnr_adr-addrnumber.
ENDMODULE.                 " f4_addrnumber  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9000  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 9000
*----------------------------------------------------------------------*
MODULE user_command_9000 INPUT.
  IF sy-ucomm = 'CONTINUE'.
    IF ok_code = 'UPLD'.          "Upload
     PERFORM upload_file.
    ELSE.                         "Download
      PERFORM download_file.
    ENDIF.
  ENDIF.
  clear ok_code.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " user_command_9000  INPUT
