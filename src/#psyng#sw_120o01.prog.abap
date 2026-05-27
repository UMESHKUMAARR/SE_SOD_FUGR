*----------------------------------------------------------------------*
***INCLUDE /PSYNG/SW_120O01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  MESSAGE e002(/psyng/sw) WITH 'This functionality is Obsolete as of SE4.5PS3'.

*  SET PF-STATUS '0100'.
*  SET TITLEBAR  '0100'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  INIT_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_0100 OUTPUT.
*  DATA : ls_config TYPE /psyng/swconfig.
**--Get name of RFC destination pointing from remote system
**  back to central system
*  se_config_param 'SE_CENTRAL_RFC' ls_config-value.
*  IF NOT ls_config-value IS INITIAL.
*    g_central_system = ls_config-value.
*  ENDIF.
*
*
*  DATA : l_cnt TYPE i.
*  CREATE OBJECT gr_event_handler.
**--Check if there is any data in central repository
*  SELECT COUNT(*) FROM /psyng/sw_cntuse INTO l_cnt "#EC CI_NOWHERE
*                                                   "#EC CI_NOFIELD
*  WHERE userid IS not NULL
*     OR sysclient IS NOT NULL.
*  IF l_cnt = 0.
*    LOOP AT SCREEN.
*      IF screen-group1 = 'CNT'.
**--this button is only relevant for central systems,
**if no data exists in the central directory, disable these buttons.
*        screen-input = '0'.
*        MODIFY SCREEN.
*      ENDIF.
*    ENDLOOP.
*  ENDIF.
*
*  IF l_cnt > 0.
*    PERFORM load_data.
*    PERFORM show_grid.
*  ENDIF.
*
*
*  IF g_num IS INITIAL.
*    g_num = 1.
*  ENDIF.
*  IF g_period_type IS INITIAL.
*    g_period_type = 'WEEK'.
*  ENDIF.
ENDMODULE.                 " INIT_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  MESSAGE s002(/psyng/sw) WITH 'This functionality is Obsolete as of SE4.5PS3'.
*
*  SET PF-STATUS '0200'.
*  SET TITLEBAR '0200' WITH gt_overview-sysclient.
*  LOOP AT SCREEN.
*    IF screen-group1 = 'TIM'.
*      IF NOT g_job_immediate IS INITIAL.
*        screen-invisible = '1'.
*        screen-active    = '0'.
*      ELSE.
*        screen-invisible = '0'.
*        screen-active    = '1'.
*      ENDIF.
*      MODIFY SCREEN.
*    ENDIF.
*    IF screen-group2 = 'PER'.
*      IF g_job_periodic IS INITIAL.
*        screen-invisible = '1'.
*        screen-active    = '0'.
*      ELSE.
*        screen-invisible = '0'.
*        screen-active    = '1'.
*      ENDIF.
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.
*  IF g_job_start_date IS INITIAL.
*    g_job_start_date = sy-datum.
*  ENDIF.
*  IF g_job_period_number IS INITIAL.
*    g_job_period_number = '1'.
*  ENDIF.

ENDMODULE.                 " STATUS_0200  OUTPUT
