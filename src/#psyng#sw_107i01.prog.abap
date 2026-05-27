*----------------------------------------------------------------------*
* Report  /PSYNG/SW_107I01                                             *
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
* INPUT MODULE FOR TABSTRIP 'TS_MAIN': GETS ACTIVE TAB
MODULE ts_main_active_tab_get INPUT.
  g_ok_code = sy-ucomm.
  CASE g_ok_code.
    WHEN c_ts_main-tab1.
      g_ts_main-pressed_tab = c_ts_main-tab1.
    WHEN c_ts_main-tab2.
      g_ts_main-pressed_tab = c_ts_main-tab2.
      PERFORM get_texts.
    WHEN OTHERS.
*      DO NOTHING
  ENDCASE.

  CLEAR: g_ok_code, sy-ucomm.
ENDMODULE.

*&spwizard: input module for tc 'TC_CONFIG'. do not change this line!
*&spwizard: modify table
MODULE tc_config_modify INPUT.
  MODIFY gt_config INDEX tc_config-current_line.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  tc_config_new  INPUT
*&---------------------------------------------------------------------*
*       Insert new parameter into configuration
*----------------------------------------------------------------------*
MODULE tc_config_new INPUT.
  READ TABLE gt_config INTO gs_config INDEX tc_config-current_line.

  IF gs_config-param <> space.
    APPEND gs_config TO gt_delete.
  ENDIF.
ENDMODULE.                 " tc_config_new  INPUT

*&spwizard: input modul for tc 'TC_CONFIG'. do not change this line!
*&spwizard: mark table
MODULE tc_config_mark INPUT.
  IF tc_config-line_sel_mode = 1.
    LOOP AT gt_config INTO gs_config WHERE sel = 'X'.
      gs_config-sel = ''.
      MODIFY gt_config FROM gs_config TRANSPORTING sel.
    ENDLOOP.
  ENDIF.

  MODIFY gt_config INDEX tc_config-current_line TRANSPORTING sel.
ENDMODULE.

*&---------------------------------------------------------------------*
*&      Module  exit  INPUT
*&---------------------------------------------------------------------*
*       Handle exit commands
*----------------------------------------------------------------------*
MODULE exit INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " exit  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1000  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 1000
*----------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  DATA: l_tabix      TYPE sy-tabix.

  CLEAR:gf_insert.
  g_ok_code = sy-ucomm.
  CASE g_ok_code.
    WHEN 'INSR'.                       "insert row
      PERFORM fcode_insert_row USING    'TC_CONFIG'
                                        'GT_CONFIG'.
*vk 4/10/18 make custom paramter editable only on insert
      gf_insert = 'X'.
*End of changes

    WHEN 'DELE'.                       "delete row
      PERFORM fcode_delete_row USING    'TC_CONFIG'
                                        'GT_CONFIG'.

    WHEN 'P--' OR                      "top of list
         'P-'  OR                      "previous page
         'P+'  OR                      "next page
         'P++'.                        "bottom of list
      PERFORM compute_scrolling_in_tc USING 'TC_CONFIG'
                                            g_ok_code.

    WHEN 'REVERT'.                     "Revert to default
      PERFORM revert_single.

    WHEN 'INFO'.                       "Show info for parameter
      PERFORM show_info.

    WHEN 'REV_ALL'.                    "Revert all records
      PERFORM revert_all.

    WHEN 'SAVE'.                       "Save record
      PERFORM save_cfg.
    when 'CDOCS'.
      submit /PSYNG/SW_108 via selection-screen
        with p_conf = 'X'
        AND RETURN.
    WHEN 'TRANSPORT'.                  "Transport record(s)
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_tconfg = 'X'
             AND RETURN.

    WHEN 'DISPCHG'.                    "Toggle display / change mode
      PERFORM display_change.
*---Om 3.5 Start
    WHEN 'ASORT'.
      sort_type = 'A'.
      PERFORM sort_col_cnf USING sort_type.

    WHEN 'DSORT'.
      sort_type = 'D'.
      PERFORM sort_col_cnf USING sort_type.

    WHEN 'FIND' OR 'FINDNEXT'.
      IF g_ok_code = 'FIND'.
        CLEAR: gl_config.
        CALL SCREEN 1001 STARTING AT 3 10.
        CHECK sy-ucomm = 'CONTINUE'.
      ENDIF.
      IF gl_config-category IS INITIAL AND gl_config-param IS INITIAL
      AND gl_config-value IS INITIAL.
        MESSAGE e106(/psyng/sw) WITH text-e01.
      ENDIF.

      LOOP AT gt_config WHERE sel = gc_select.
        CLEAR gt_config-sel.
        MODIFY gt_config INDEX sy-tabix.
        l_tabix = sy-tabix + 1.
      ENDLOOP.

      IF g_ok_code = 'FIND'.
        l_tabix = 1.
      ENDIF.
      LOOP AT gt_config FROM l_tabix.
        IF NOT gl_config-category IS INITIAL.
          CHECK gt_config-category = gl_config-category.
        ENDIF.

        IF NOT gl_config-param IS INITIAL.
          CHECK gt_config-param = gl_config-param.
        ENDIF.

        IF NOT gl_config-value IS INITIAL.
          CHECK gt_config-value = gl_config-value.
        ENDIF.

        gt_config-sel = gc_select.
        MODIFY gt_config INDEX sy-tabix.
        tc_config-top_line = sy-tabix.
        EXIT.
      ENDLOOP.

      READ TABLE gt_config WITH KEY sel = gc_select
                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        MESSAGE i103(/psyng/sw).
      ENDIF.

    WHEN 'FILTER'.
      DATA:       lt_config LIKE TABLE OF gt_config WITH HEADER LINE.

      CLEAR: gl_config, l_tabix.
      CALL SCREEN 1001 STARTING AT 3 10.
      CHECK sy-ucomm = 'CONTINUE'.
      RANGES: r_category FOR /psyng/se_config_param-category,
              r_value FOR /psyng/se_config_param-value,
              r_param   FOR /psyng/se_config_param-param.
   refresh: r_category, r_value, r_param.
*--Collect Search value in Ranges
      IF NOT gl_config-category IS INITIAL.
        IF  gl_config-category CS '*'.
          r_category-sign = 'I'.
          r_category-option = 'CP'.
        ELSE.
          r_category-sign = 'I'.
          r_category-option = 'EQ'.
        ENDIF.
        r_category-low = gl_config-category.
        COLLECT r_category.
      ENDIF.

      IF NOT gl_config-param IS INITIAL.
        IF  gl_config-param CS '*'.
          r_param-sign = 'I'.
          r_param-option = 'CP'.
        ELSE.
          r_param-sign = 'I'.
          r_param-option = 'EQ'.
        ENDIF.
        r_param-low = gl_config-param.
        COLLECT r_param.
      ENDIF.

      IF NOT gl_config-value IS INITIAL.
        IF  gl_config-value CS '*'.
          r_value-sign = 'I'.
          r_value-option = 'CP'.
        ELSE.
          r_value-sign = 'I'.
          r_value-option = 'EQ'.
        ENDIF.
        r_value-low = gl_config-value.
        COLLECT r_value.
      ENDIF.

      REFRESH gt_config.
      LOOP AT gt_config_tmp WHERE category IN r_category
                                  AND param IN r_param
                                  AND value IN r_value.
        MOVE-CORRESPONDING gt_config_tmp TO gt_config.
        APPEND gt_config.
      ENDLOOP.
*--- End
  ENDCASE.

  CLEAR: g_ok_code, sy-ucomm.
ENDMODULE.                 " USER_COMMAND_1000  INPUT

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_2000  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 2000
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.
  g_ok_code = sy-ucomm.
  CASE g_ok_code.
    WHEN 'DISPCHG'.                    "Toggle display / change mode
      PERFORM display_change.

    WHEN 'VAL_MIT_ASSGN'.              "Validate text
      PERFORM get_txt_lang USING g_txt_mit_assgn
                           CHANGING g_lang_mit_assgn
                                    g_msg_mit_assgn.

    WHEN 'VAL_MIT_REMIND'.             "Validate text
      PERFORM get_txt_lang USING g_txt_mit_remind
                           CHANGING g_lang_mit_remind
                                    g_msg_mit_remind.

*BOC C1159 CGUPTA 20/09/2023
     WHEN 'VAL_MIT_REMIND'.             "Validate text
      PERFORM get_txt_lang USING g_txt_mit_notify
                           CHANGING g_lang_mit_notify
                                    g_msg_mit_notify.
*EOC C1159 CGUPTA 20/09/2023


    WHEN 'VAL_MIT_URL'.             "Validate text
      PERFORM get_txt_lang USING g_txt_mit_url
                             CHANGING g_lang_mit_url
                                      g_msg_mit_url.

    WHEN 'VAL_USR_INACT'.
      PERFORM get_txt_lang USING g_txt_usr_inact
                             CHANGING g_lang_usr_inact
                                      g_msg_usr_inact.
    WHEN 'VAL_MIT_SOFF'.              "Validate signoff
      PERFORM get_txt_lang USING g_txt_mit_soff
                             CHANGING g_lang_mit_soff
                                      g_msg_mit_soff.

    WHEN 'VAL_CNF_COMP'.              "Configuration Set Comparison
      PERFORM get_txt_lang USING g_txt_cnf_comp
                             CHANGING g_lang_cnf_comp
                                      g_msg_cnf_comp.

    WHEN 'EDT_MIT_ASSGN'.              "Edit text
      REFRESH gt_tline.
      gt_tline-tdline = 'Mitigation Assignment Email'(010).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_mit_assgn g_lang_mit_assgn.

    WHEN 'EDT_MIT_REMIND'.             "Edit text
      REFRESH gt_tline.
      gt_tline-tdline = 'Mitigation Reminder Email'(011).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_mit_remind g_lang_mit_remind.

    when 'EDT_MIT_NOTIFY'.
      refresh gt_tline.
      gt_tline-tdline = 'Mitigation Assignment Expiration Email'(015).
      append gt_tline.
      PERFORM edit_text using G_TXT_MIT_NOTIFY G_LANG_MIT_NOTIFY.

    WHEN 'EDT_MIT_URL'.             "Edit text
      REFRESH gt_tline.
      gt_tline-tdline = 'Mitigation URL'(012).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_mit_url g_lang_mit_url.

    WHEN 'EDT_USR_INACT'.
      REFRESH gt_tline.
      gt_tline-tdline = 'User Inactivity Email'(013).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_usr_inact g_lang_usr_inact.

    WHEN 'EDT_MIT_SOFF'.
      REFRESH gt_tline.
      gt_tline-tdline = 'Mitigation Signoff E-Mail'(020).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_mit_soff g_lang_mit_soff.
    WHEN 'EDT_CNF_COMP'.
      REFRESH gt_tline.
      gt_tline-tdline = 'Configuration Set Comparison E-Mail'(021).
      APPEND gt_tline.
      PERFORM edit_text USING g_txt_cnf_comp g_lang_cnf_comp.
    WHEN 'DISPCHG'.                    "Toggle display / change mode
      PERFORM display_change.

    WHEN 'SO10'.                       "Go to transaction SO10
      AUTHORITY-CHECK OBJECT 'S_TCODE'
               ID 'TCD' FIELD 'SO10'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SO10'.
      ENDIF.

      CALL TRANSACTION 'SO10'.

    WHEN OTHERS.                       "Validate all texts
      PERFORM get_txt_lang USING g_txt_mit_assgn
                           CHANGING g_lang_mit_assgn
                                    g_msg_mit_assgn.
  ENDCASE.

  CLEAR: g_ok_code, sy-ucomm.
ENDMODULE.                 " USER_COMMAND_2000  INPUT

*---------------------------------------------------------------------*
*       MODULE user_command_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_1001 INPUT.
  CASE sy-ucomm.
    WHEN 'CONTINUE' OR 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.

MODULE f4_category INPUT.
  PERFORM f4_help_Category CHANGING gt_config-category.
ENDMODULE.

MODULE f4_param INPUT.
  PERFORM f4_help_param CHANGING gt_config-param.
ENDMODULE.

MODULE f4_value INPUT.
  PERFORM f4_help_value CHANGING gt_config-value.
ENDMODULE.
