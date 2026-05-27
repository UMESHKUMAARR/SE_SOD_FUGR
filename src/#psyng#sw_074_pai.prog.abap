***INCLUDE /PSYNG/SW_074_PAI .
*&spwizard: input module for tc 'TC_EXCLUDE'. do not change this line!
*&spwizard: modify table
MODULE tc_exclude_modify INPUT.
  MODIFY gt_tc_exclude
    FROM gs_tc_exclude
    INDEX tc_exclude-current_line.

* append data from table control to internal table
 IF SY-SUBRC NE 0.
    APPEND GS_TC_EXCLUDE TO GT_TC_EXCLUDE.
    ENDIF.

  gf_data_change = 'X'.

ENDMODULE.

*&spwizard: input modul for tc 'TC_EXCLUDE'. do not change this line!
*&spwizard: mark table
MODULE tc_exclude_mark INPUT.
  DATA: g_tc_exclude_wa2 LIKE LINE OF gt_tc_exclude.
  IF tc_exclude-line_sel_mode = 1.
    LOOP AT gt_tc_exclude INTO g_tc_exclude_wa2
      WHERE sel = 'X'.
      g_tc_exclude_wa2-sel = ''.
      MODIFY gt_tc_exclude
        FROM g_tc_exclude_wa2
        TRANSPORTING sel.
    ENDLOOP.
  ENDIF.
  MODIFY gt_tc_exclude
    FROM gs_tc_exclude
    INDEX tc_exclude-current_line
    TRANSPORTING sel.
ENDMODULE.

*&spwizard: input module for tc 'TC_EXCLUDE'. do not change this line!
*&spwizard: process user command
MODULE tc_exclude_user_command INPUT.

  ok_code = sy-ucomm.
  PERFORM user_ok_tc USING    'TC_EXCLUDE'
                              'GT_TC_EXCLUDE'
                              'SEL'
                     CHANGING ok_code.
  sy-ucomm = ok_code.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  f4_TYPE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_type INPUT.
  PERFORM f4_type CHANGING gs_tc_exclude-type.

ENDMODULE.                 " f4_TYPE  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_FILE  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE f4_file INPUT.
  PERFORM f4_file CHANGING g_filename.
ENDMODULE.                 " f4_FILE  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  IF sy-ucomm = 'CONTINUE'.
    IF ok_code = 'UPLD'.          "Upload
      PERFORM upload_file.
    ELSE.                         "Download
      PERFORM download_file.
    ENDIF.
  ENDIF.
  CLEAR ok_code.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*&      Module  f4_SIGN  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
module f4_SIGN input.
  perform f4_sign CHANGING gs_tc_exclude-sign.
endmodule.                 " f4_SIGN  INPUT
