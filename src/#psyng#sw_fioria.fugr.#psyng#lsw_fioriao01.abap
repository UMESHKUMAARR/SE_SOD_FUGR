*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_FIORIAO01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.

  PERFORM status_0100.

ENDMODULE.                 " STATUS_0100  OUTPUT

* OUTPUT MODULE FOR TABSTRIP 'FIORI_APP_DET': SETS ACTIVE TAB
MODULE fiori_app_det_active_tab_set OUTPUT.
  fiori_app_det-activetab = gs_fiori_app_det-pressed_tab.
  CASE gs_fiori_app_det-pressed_tab.
    WHEN gc_fiori_app_det-tab1.
      gs_fiori_app_det-subscreen = '0101'.
    WHEN gc_fiori_app_det-tab2.
      gs_fiori_app_det-subscreen = '0102'.
    WHEN gc_fiori_app_det-tab3.
      gs_fiori_app_det-subscreen = '0103'.
    WHEN gc_fiori_app_det-tab4.
      gs_fiori_app_det-subscreen = '0104'.
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  display_alv_services  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_services OUTPUT.

*Display ALV services
  PERFORM display_alv_services.

ENDMODULE.                 " display_alv_services  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  display_alv_notes  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_notes OUTPUT.

*Display ALV OSS Notes
  PERFORM display_alv_notes.

ENDMODULE.                 " display_alv_notes  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  status_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE edit_text_0101 OUTPUT.
*--Display text
  PERFORM display_text.

ENDMODULE.                 " status_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  switch_mode_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE switch_mode_0101 OUTPUT.

  LOOP AT SCREEN.
    IF screen-name = '/PSYNG/SW_FIORIA-FIORIID'
    OR screen-name = '/PSYNG/SW_FIORIA-APPNAME'
    OR screen-name = '/PSYNG/SW_FIORIA-APPLICATIONTYPE'
    OR screen-name = '/PSYNG/SW_FIORIA-TCODE_MATCH'.
      IF gf_edit IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
    IF screen-name = 'MORE_INFO'.
      IF /psyng/sw_fioria-fioriid+(1) EQ 'Z'
      OR /psyng/sw_fioria-fioriid IS INITIAL.
        screen-active = 0.
      ELSE.
        screen-active = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " switch_mode_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  switch_mode_0103  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE switch_mode_0103 OUTPUT.

  LOOP AT SCREEN.
    IF screen-name = '/PSYNG/SW_FIORIA-BSPNAME'
    OR screen-name = '/PSYNG/SW_FIORIA-BSPAPPURL'
    OR screen-name = '/PSYNG/SW_FIORIA-SEMANTICOBJECT'
    OR screen-name = '/PSYNG/SW_FIORIA-SEMANTICACTION'
    OR screen-name = '/PSYNG/SW_FIORIA-TECHNICALCATNAME'
    OR screen-name = '/PSYNG/SW_FIORIT-TEXT'
    OR screen-name = '/PSYNG/SW_FIORIA-BUSINESSROLENAME'
    OR screen-name = 'GS_ROLE_DESC'.
      IF gf_edit IS INITIAL.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " switch_mode_0103  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  switch_mode_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE switch_mode_0100 OUTPUT.

  LOOP AT SCREEN.
    IF screen-name = 'GS_FIORI_ID_NAME'.
      IF gf_edit IS INITIAL.
        screen-active = 1.
      ELSE.
        screen-active = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDMODULE.                 " switch_mode_0100  OUTPUT
