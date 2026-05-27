*----------------------------------------------------------------------*
* Report  /PSYNG/SW_107O01                                             *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
* OUTPUT MODULE FOR TABSTRIP 'TS_MAIN': SETS ACTIVE TAB
MODULE ts_main_active_tab_set OUTPUT.
  ts_main-activetab = g_ts_main-pressed_tab.
  CASE g_ts_main-pressed_tab.
    WHEN c_ts_main-tab1.
      g_ts_main-subscreen = '1002'.

      REFRESH gt_func.
      IF gf_dispchg = gc_display.
        gt_func-fcode = 'SAVE'.
        APPEND gt_func.
        gt_func-fcode = 'INSR'.
        APPEND gt_func.
        gt_func-fcode = 'DELE'.
        APPEND gt_func.
        gt_func-fcode = 'REV_ALL'.
        APPEND gt_func.
      ENDIF.

      SET PF-STATUS '1000' EXCLUDING gt_func.

    WHEN c_ts_main-tab2.
      g_ts_main-subscreen = '2000'.
      SET PF-STATUS '2000'.

    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.

  IF gf_dispchg = gc_display.
    SET TITLEBAR '100'.
  ELSE.
    SET TITLEBAR '101'.
  ENDIF.
ENDMODULE.

*&spwizard: output module for tc 'TC_CONFIG'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_config_change_tc_attr OUTPUT.

  IF NOT g_curs_line IS INITIAL.
    SET CURSOR 1 g_curs_line.
    CLEAR g_curs_line.
  ENDIF.

  CLEAR: g_ok_code, sy-ucomm.
  DESCRIBE TABLE gt_config LINES tc_config-lines.
ENDMODULE.

*&spwizard: output module for tc 'TC_CONFIG'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_config_get_lines OUTPUT.
  g_tc_config_lines = sy-loopc.
  PERFORM toggle_display_change.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  dispchg  OUTPUT
*&---------------------------------------------------------------------*
*       Set screen for display or change mode
*----------------------------------------------------------------------*
MODULE dispchg OUTPUT.
  PERFORM toggle_display_change.
ENDMODULE.                 " dispchg  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  hide_stuff  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE hide_stuff OUTPUT.
*  LOOP AT SCREEN.
*    CHECK screen-name = 'G_TXT_USR_INACT'
*       OR screen-name = 'G_VAL_USR_INACT'
*       OR screen-name = 'G_LANG_USR_INACT'
*       OR screen-name = 'G_EDT_USR_INACT'
*       OR screen-name = 'G_MSG_USR_INACT'.
*    screen-input = 0.
*    screen-invisible = 1.
*    MODIFY SCREEN.
*  ENDLOOP.

ENDMODULE.                 " hide_stuff  OUTPUT

MODULE STATUS_1001 OUTPUT.
SET PF-STATUS '101'.
 ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  STATUS_2000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.
 SET PF-STATUS '2000'.
  IF gf_dispchg = gc_display.
    SET TITLEBAR '100'.
  ELSE.
    SET TITLEBAR '101'.
  ENDIF.

ENDMODULE.
