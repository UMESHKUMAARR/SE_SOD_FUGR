*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_135_O01                                          *
*----------------------------------------------------------------------*


MODULE status_0100 OUTPUT.
  IF gf_dispchg = gc_display.
    gt_func-fcode = 'SAVE'.
    APPEND gt_func.
    gt_func-fcode = 'CREATE'.
    APPEND gt_func.
    gt_func-fcode = 'PUBLISH'.
    APPEND gt_func.
    SET PF-STATUS '0135' EXCLUDING gt_func.
  ELSE.
    SET PF-STATUS '0135'.
  ENDIF.
  SET TITLEBAR '0100'.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE status_0105 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0105 OUTPUT.
  IF gf_dispchg = gc_display.
    SET PF-STATUS '0105' EXCLUDING 'TOGGLE_ALL'.
  ELSE.
    SET PF-STATUS '0105'.
  ENDIF.
  SET TITLEBAR '0105'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  TAB_APPL_ACTIVE_TAB_SET  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tab_appl_active_tab_set OUTPUT.
  tab_appl-activetab = g_tab_appl-pressed_tab.
  CASE g_tab_appl-pressed_tab.
    WHEN c_tab_appl-tab1.
      g_tab_appl-subscreen = '0101'.
    WHEN c_tab_appl-tab2.
      g_tab_appl-subscreen = '0102'.
    WHEN c_tab_appl-tab3.
      g_tab_appl-subscreen = '0103'.
    WHEN c_tab_appl-tab4.
      g_tab_appl-subscreen = '0104'.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_system_selection_alv OUTPUT                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_system_selection_alv OUTPUT.
  PERFORM display_system_selection_alv.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_system_selection_alv OUTPUT                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_102_1_alv OUTPUT.
  PERFORM display_102_1_alv.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_103_2_alv OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_102_2_alv OUTPUT.
  PERFORM display_102_2_alv.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_103_alv OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_103_alv OUTPUT.
  PERFORM display_103_alv.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_104_alv OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_104_alv OUTPUT.
  PERFORM display_104_alv.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_data OUTPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_data OUTPUT.
  DATA: lt_swcfgsys TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        ls_configset2 TYPE /psyng/swcfgset,
        lf_continue TYPE flag,
        l_answer.

  IF gf_dispchg <> gc_change."'X'.
    PERFORM authorization_check
      USING    /psyng/swcfgset-setid 'D'
      CHANGING lf_continue.
  ELSE.
    PERFORM authorization_check
      USING    /psyng/swcfgset-setid 'E'
      CHANGING lf_continue.
  ENDIF.
  IF lf_continue <> 'X'.
    CLEAR /psyng/swcfgset.
  ELSEIF gf_set_loaded IS INITIAL.
    PERFORM confirm_exit CHANGING l_answer.
    IF l_answer <> '1'.
      CLEAR : sy-ucomm.
      /psyng/swcfgset-setid = g_loaded_set.
    ELSE.
      CLEAR : gf_data_change, gf_screen_change.

      SELECT SINGLE * FROM /psyng/swcfgset INTO ls_configset2
        WHERE setid = /psyng/swcfgset-setid.
      IF sy-subrc = 0.
        CLEAR :
          g_published,
          g_invalid,
          /psyng/swcfgset-create_user,
          /psyng/swcfgset-create_date,
          /psyng/swcfgset-create_time,
          /psyng/swcfgset-change_user,
          /psyng/swcfgset-change_date,
          /psyng/swcfgset-change_time,
          /psyng/swcfgset-published.
*    --- Check publish
        PERFORM  check_publish.
        CLEAR:g_disp_inact,g_varbl_inact.
        PERFORM get_existing_config_set_data.
      ELSE.
        IF gf_data_change <> 'X'.
          CLEAR: /psyng/swcfgset-description.
        ENDIF.
        CLEAR :
        g_published,
          /psyng/swcfgset-create_user,
          /psyng/swcfgset-create_date,
          /psyng/swcfgset-create_time,
          /psyng/swcfgset-change_user,
          /psyng/swcfgset-change_date,
          /psyng/swcfgset-change_time,
          /psyng/swcfgset-published.
        if not /psyng/swcfgset-setid is INITIAL.
       MESSAGE S002(/psyng/sw) WITH
            'Invalid Configuration Set'(i03).
       endif.
       g_invalid = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_data_102 OUTPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_data_102 OUTPUT.
  exelog sy-repid 'ELEMENTS'.

  DATA: lt_ao_list TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
         lt_ve_list TYPE TABLE OF /psyng/sw_ve_list WITH HEADER LINE,
         ls_config TYPE /psyng/se_config_param.

*  IF g_sod_flag IS INITIAL.
*    CALL FUNCTION '/PSYNG/SW_034'
*         IMPORTING
*              e_vrsio = /psyng/swsodvers-vrsio.
*
*    g_sod_flag = 'X'.
*  ENDIF.

*  IF NOT /psyng/swcfgset-setid IS INITIAL AND
*        g_varel_vrsio_flag IS INITIAL .
*    SELECT SINGLE varel_vrsio INTO (/psyng/swcfgset-varel_vrsio)
*     FROM /psyng/swcfgset WHERE
*                       setid = /psyng/swcfgset-setid.
*    g_varel_vrsio_flag = 'X'.
*  ENDIF.

  IF gv_conbine_analysis IS INITIAL AND g_sod_parse IS INITIAL.

*---load varable rule
    IF gf_vs_loaded IS INITIAL. " not selected manually
      PERFORM load_rules_for_selection.
    ENDIF.
*---load org rule
    PERFORM load_rules_for_org_sel.

  ENDIF.
*--If no element selection was done before, and auto parse is configured
*  run the auto parse now
  IF gt_selections[] IS INITIAL AND gf_cfg_set_auto_parse = 'X'.
    PERFORM parse_sod_matrix.
    MESSAGE s002(/psyng/sw) WITH
    'Automatic SOD Matrix Parsing'(ap1).
    COMMIT WORK.
  ENDIF.
  CLEAR: g_sod_parse,
         gv_conbine_analysis, gv_save.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE toggle_display_change OUTPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE toggle_display_change OUTPUT.

  LOOP AT SCREEN.
    IF screen-name CS 'G_ANA_'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.

    IF screen-name EQ '/PSYNG/SWCFGSET-PUBLISHED'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

  IF gf_dispchg = gc_display.                    "Display
    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = '001' AND screen-input = 0.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF g_published = 'X'.
    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
    gf_dispchg = gc_display.
*    MESSAGE s002(/psyng/sw) WITH
*   'Published config. set cannot be edited'(p01).
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE fill_filters_dropdown OUTPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE fill_filters_dropdown OUTPUT.
  PERFORM fill_filters_dropdown.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE get_existing_variable_element OUTPUT                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_variable_element OUTPUT.
  exelog sy-repid 'VARELEMENTS'.
  IF gf_ve_loaded IS INITIAL.
    IF NOT /psyng/swcfgset-setid IS INITIAL.
      IF gv_prev_setid = /psyng/swcfgset-setid AND
      gv_variable_analysis IS INITIAL.
        CLEAR gv_prev_setid.
        REFRESH gt_variable1.
      ENDIF.

      IF gv_prev_setid IS INITIAL.
        gv_prev_setid = /psyng/swcfgset-setid.
      ENDIF.

      IF gt_variable1[] IS INITIAL AND gv_variable_analysis IS INITIAL.
        PERFORM load_existing_variable_element.
      ENDIF.

      IF /psyng/swcfgset-setid <> gv_prev_setid AND
      NOT /psyng/swcfgset-setid IS INITIAL AND
       gv_variable_analysis IS INITIAL.
        REFRESH gt_variable1.
        PERFORM load_existing_variable_element.
      ENDIF.

      CLEAR gv_variable_analysis.
    ELSE.
      REFRESH gt_variable1.
    ENDIF.
*---set default values for filter
    IF NOT gt_variable1[] IS INITIAL.
      IF /psyng/swcfgve-var_element IS INITIAL.
        /psyng/swcfgve-var_element = 'ALL'.
      ENDIF.
      IF /psyng/swcfgve-sysid IS INITIAL.
        /psyng/swcfgve-sysid = 'ALL'.
      ENDIF.
    ENDIF.

  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_data_103 OUTPUT                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_data_103 OUTPUT.
  exelog sy-repid 'ORGELEMENTS'.
  PERFORM load_data_103.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_alv_org_detail OUTPUT                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_alv_org_detail OUTPUT.
  exelog sy-repid 'ORGDETAILS'.
  PERFORM display_alv_org_detail.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE get_existing_system_data OUTPUT
*
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE get_existing_system_data OUTPUT.
  exelog sy-repid 'SYSTEMS'.
  IF  gf_sys_loaded IS INITIAL.
    IF NOT /psyng/swcfgset-setid IS INITIAL .
      REFRESH gt_systems.
      PERFORM get_system_against_setid.
    ELSE.
      REFRESH gt_systems.
    ENDIF.

    IF gt_systems[] IS INITIAL.
      PERFORM get_existing_sys.
      CLEAR g_sys_create_flag.
    ENDIF.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE toggle_display OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE toggle_display OUTPUT.
  PERFORM toggle_display.
ENDMODULE.
