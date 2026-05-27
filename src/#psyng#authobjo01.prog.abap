*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUTHOBJO01
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
*&      Module  PBO_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_100 OUTPUT.
  IF gf_dispchg = gc_display.
    SET TITLEBAR 'DISP'.
  ELSE.
    SET TITLEBAR 'CHG'.
  ENDIF.

  IF g_tree IS INITIAL.
    " The Tree Control has not been created yet.
    " Create a Tree Control and insert nodes into it.
    PERFORM create_and_init_tree.
  ENDIF.

  PERFORM toggle_display_change.
ENDMODULE.                 " PBO_0100  OUTPUT

*&spwizard: output module for tc 'TC_seltab'. do not change this line!
*&spwizard: update lines for equivalent scrollbar
MODULE tc_seltab_change_tc_attr OUTPUT.
  DESCRIBE TABLE gt_select LINES tc_seltab-lines.

  LOOP AT SCREEN.
    CHECK screen-name = 'LOWERCASE_WARNING'.

    IF gf_uppercase = 'X'.
      screen-invisible = 1.
    ELSE.
      screen-invisible = 0.
    ENDIF.

    MODIFY screen.
  ENDLOOP.
ENDMODULE.

*&spwizard: output module for tc 'TC_seltab'. do not change this line!
*&spwizard: get lines of tablecontrol
MODULE tc_seltab_get_lines OUTPUT.
  g_tc_seltab_lines = sy-loopc.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  STATUS_0900  OUTPUT
*&---------------------------------------------------------------------*
*       Set OK/Cancel status
*----------------------------------------------------------------------*
MODULE status_ok_canc OUTPUT.
  SET PF-STATUS 'OKCANC'.
ENDMODULE.                 " STATUS_0900  OUTPUT
