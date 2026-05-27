*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_135_I01                                          *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  TAB_APPL_ACTIVE_TAB_GET_PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE tab_appl_active_tab_get_pai INPUT.
  CASE sy-ucomm.
    WHEN c_tab_appl-tab1.
*      IF gf_screen_change <> 'X'.
*        g_tab_appl-pressed_tab = c_tab_appl-tab1.
*      ELSE.
*        CLEAR l_answer.
*        PERFORM confirm_exit CHANGING l_answer.
*        IF l_answer <> '1'.
*          CLEAR: sy-ucomm.
*          EXIT.
*        ELSE.
*          CLEAR: gf_screen_change, gf_data_change.
      g_tab_appl-pressed_tab = c_tab_appl-tab1.
*        ENDIF.
*      ENDIF.

    WHEN c_tab_appl-tab2.
*      IF gf_screen_change <> 'X'.
*        g_tab_appl-pressed_tab = c_tab_appl-tab2.
*      ELSE.
*        CLEAR l_answer.
*        PERFORM confirm_exit CHANGING l_answer.
*        IF l_answer <> '1'.
*          CLEAR: sy-ucomm.
*          EXIT.
*        ELSE.
*          CLEAR: gf_screen_change, gf_data_change.
      g_tab_appl-pressed_tab = c_tab_appl-tab2.
*        ENDIF.
*      ENDIF.

    WHEN c_tab_appl-tab3.
*      IF gf_screen_change <> 'X'.
*        g_tab_appl-pressed_tab = c_tab_appl-tab3.
*         ELSE.
*        CLEAR l_answer.
*        PERFORM confirm_exit CHANGING l_answer.
*        IF l_answer <> '1'.
*          CLEAR: sy-ucomm.
*          EXIT.
*        ELSE.
*          CLEAR: gf_screen_change, gf_data_change.
      g_tab_appl-pressed_tab = c_tab_appl-tab3.
*        ENDIF.
*      ENDIF.
    WHEN c_tab_appl-tab4.
*      IF gf_screen_change <> 'X'.
*        g_tab_appl-pressed_tab = c_tab_appl-tab4.
*         ELSE.
*        CLEAR l_answer.
*        PERFORM confirm_exit CHANGING l_answer.
*        IF l_answer <> '1'.
*          CLEAR: sy-ucomm.
*          EXIT.
*        ELSE.
*          CLEAR: gf_screen_change, gf_data_change.
      g_tab_appl-pressed_tab = c_tab_appl-tab4.
*        ENDIF.
*      ENDIF.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0100 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  DATA: l_dynnr      TYPE sy-dynnr,
        l_ucomm      LIKE sy-ucomm,
        l_runcount   TYPE i,
        l_rolecount  TYPE i,
        if_continue  TYPE flag,
        l_valid      TYPE flag,
        l_setid_temp TYPE /psyng/swcfgset-setid.
  CLEAR l_ucomm.
  CLEAR l_dynnr.
  l_dynnr = sy-dynnr.
  l_ucomm = sy-ucomm.
  CASE l_ucomm.
    WHEN 'F1'.
      CALL FUNCTION 'DOCU_CALL'
        EXPORTING
*         CMOD_ENTRANCE           = ' '
          displ      = 'X'
          displ_mode = '2'
*         DYNPRO_FOR_THLPF        = ' '
*         FDNAME_FOR_THLPF        = ' '
          id         = 'RE'
          langu      = sy-langu
          object     = '/PSYNG/SW_135'
*         PROGRAM_FOR_THLPF       = ' '
*         SHORTTEXT  = ' '
          typ        = 'E'
*         SUPPRESS_EDIT           = ' '
*         USE_SEC_LANGU           = ' '
*         FORCE_EDITOR            = ' '
*         EXTENSION_MODE          = ' '
*         TEMPLATE_ID             = ' '
*         TEMPLATE_OBJECT         = ' '
*         TEMPLATE_TYP            = ' '
*         USE_NOTE_TEMPLATE       = ' '
*         DISPLAY_SHORTTEXT       = ' '
*       IMPORTING
*         SAVETEXT   =
*         EXIT_CODE  =
       EXCEPTIONS
         WRONG_NAME = 1
         OTHERS     = 2
        .
      IF sy-subrc <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

    WHEN 'DISPCHG'.

*---check if config set exist
        SELECT SINGLE setid INTO l_setid_temp
          FROM /psyng/swcfgset WHERE
          setid = /psyng/swcfgset-setid.
        IF sy-subrc <> 0.
          g_invalid = 'X'.
          else.
            clear g_invalid.
        ENDIF.


      IF g_published = 'X'.
        MESSAGE s002(/psyng/sw) WITH
       'Published config. set cannot be edited'(p01).
      elseif not /psyng/swcfgset-setid is INITIAL and
        g_invalid = 'X'.
       MESSAGE S002(/psyng/sw) WITH
            'Invalid Configuration Set'(i03).
      ELSE.
**---Check auth before go in change mode
        PERFORM authorization_check
            USING    /psyng/swcfgset-setid 'E'
            CHANGING if_continue.

        IF gf_dispchg = gc_display.
          IF if_continue = 'X'.
            gf_dispchg = gc_change.
          ENDIF.
        ELSE.
          PERFORM confirm_exit CHANGING l_answer.
          IF l_answer <> '1'.
            EXIT.
            CLEAR sy-ucomm.
          ELSE.
            CLEAR : gf_data_change, gf_screen_change.
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ENDIF.
    WHEN 'SAVE'.
      l_valid = 'X'.
      IF NOT /psyng/swcfgset-setid IS INITIAL.
*  check if setid is not saved in db
        SELECT SINGLE setid INTO l_setid_temp
          FROM /psyng/swcfgset WHERE
          setid = /psyng/swcfgset-setid.
        IF sy-subrc <> 0.
          CLEAR l_valid.
        ENDIF.

*if created new setid and not saved yet
*--is valid setid
        SELECT SINGLE setid INTO l_setid_temp
          FROM /psyng/swcfgid WHERE
          setid =  /psyng/swcfgset-setid.
        IF sy-subrc = 0.
          l_valid = 'X'.
        ENDIF.
      ENDIF.

      IF l_valid = 'X'.
        PERFORM save_data.
      ELSE.
         MESSAGE e002(/psyng/sw) WITH
            'Invalid Configuration Set ID.'(i01)
            'Data cannot be saved'(i02).
      ENDIF.

    WHEN 'DELETE'.
      IF NOT /psyng/swcfgset-setid IS INITIAL.
        CLEAR l_answer.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Delete Configuration Set'(q16)
            text_question         = 'Are you sure you want to delete this Configuration Set'(q15)
            text_button_1         = 'Yes'(q13)
            icon_button_1         = '@0V@'
            text_button_2         = 'No'(q14)
            icon_button_2         = '@2O@'
            default_button        = '2'
            display_cancel_button = 'X'
          IMPORTING
            answer                = l_answer
          EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CHECK l_answer = '1'.

*---check auth to delete using 02 actvt
        AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
             ID 'ACTVT'      FIELD '02'
             ID 'Y&SW_SETID' FIELD /psyng/swcfgset-setid.
        IF sy-subrc = 0.
*--Check if Analysis Runs for this config set ID exist,
*  If so, don't allow deletion
          SELECT COUNT(*) INTO l_runcount FROM /psyng/swreshdr "#EC CI_NOFIELD
          WHERE setid = /psyng/swcfgset-setid.

*--- Check for roles
          SELECT COUNT(*) INTO l_rolecount FROM
            /psyng/swrrshdr                             "#EC CI_NOFIELD
            WHERE setid = /psyng/swcfgset-setid.

          IF l_runcount > 0 OR l_rolecount > 0.
            l_runcount = l_runcount + l_rolecount.
            MESSAGE e002(/psyng/sw) WITH
            'Configuration Set can not be deleted.'(b01)
            l_runcount 'analysis results exist.'(b02).

          ELSE.
            PERFORM delete_configset_header.
            PERFORM delete_configset_other_data.
            COMMIT WORK.
            MESSAGE s002(/psyng/sw) WITH text-005.
            CLEAR: /psyng/swcfgset, gt_organization1.
            REFRESH: gt_organization, gt_organization1,
                     gt_variable1, gt_output.
          ENDIF.
        ELSE.
          MESSAGE ID '/PSYNG/SW'  TYPE 'W' NUMBER 108
            WITH
              'delete'(a06)
              'Config Set'(a01)
              /psyng/swcfgset-setid ''.
        ENDIF.
      ENDIF.

    WHEN 'CREATE'.
      PERFORM create_setid.
    WHEN 'PUBLISH'.

*--- Popup for the confirmation
      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Publish Configuration Set'(q17)
          text_question         = 'Are you sure you want to publish this Configuration Set'(q18)
          text_button_1         = 'Yes'(q13)
          icon_button_1         = '@0V@'
          text_button_2         = 'No'(q14)
          icon_button_2         = '@2O@'
          default_button        = '2'
          display_cancel_button = 'X'
        IMPORTING
          answer                = l_answer
        EXCEPTIONS
          text_not_found        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK l_answer = '1'.
      PERFORM publish_config_set.

    WHEN 'UPDOWN'.
      AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
           ID 'ACTVT'      FIELD '02'
           ID 'Y&SW_SETID' FIELD /psyng/swcfgset-setid.
      IF sy-subrc = 0.
        SUBMIT /psyng/sw_136
        WITH p_cngset = /psyng/swcfgset-setid
        VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        MESSAGE ID '/PSYNG/SW'  TYPE 'W' NUMBER 108
             WITH
               'Upload/Download'(a07)
               'Config Set'(a01).
      ENDIF.
    WHEN 'COPY'.
*---using 02 actvt
      CHECK NOT /psyng/swcfgset-setid IS INITIAL.
      AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
            ID 'ACTVT'      FIELD '02'
            ID 'Y&SW_SETID' FIELD /psyng/swcfgset-setid.
      IF sy-subrc = 0.
        PERFORM copy_from_existing_cfgset.
      ELSE.
        MESSAGE ID '/PSYNG/SW'  TYPE 'W' NUMBER 108
       WITH
         'copy'(a05)
         'Config Set'(a01)
         /psyng/swcfgset-setid ''.
      ENDIF.
    WHEN 'EXIT'.
      PERFORM confirm_exit CHANGING l_answer.
      IF l_answer <> '1'.
        CLEAR sy-ucomm.
      ELSE.
        SET SCREEN 0.
        LEAVE SCREEN.
      ENDIF.
  ENDCASE.
  CLEAR sy-ucomm.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE f4_setid INPUT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE f4_setid INPUT.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  PERFORM handle_user_command_0101 USING sy-ucomm.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0102 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0102 INPUT.
  PERFORM handle_user_command_0102 USING  sy-ucomm.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0103 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0103 INPUT.
  PERFORM handle_user_command_0103 USING sy-ucomm.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0105 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0105 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      CLEAR g_disp_inact_all_dtl.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN  'INACTIVE'.
*    if someone click on all dtl button then not need to check the
*    flag g_hotspot_click
      IF g_disp_inact_all_dtl IS INITIAL.
        g_hotspot_click = 'X'.
      ENDIF.

      IF g_disp_inact = 'X'.
        MESSAGE s002(/psyng/sw) WITH
                'Data Loaded, for both Active and Inactive Values'(006).
      ELSE.
        MESSAGE s002(/psyng/sw) WITH 'Active Values Only'(007).
      ENDIF.
    WHEN 'TOGGLE_ALL'.
      PERFORM toggle_org_for_all_abb.

  ENDCASE.
  CLEAR sy-ucomm.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0104 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0104 INPUT.
  PERFORM handle_user_command_0104 USING sy-ucomm.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE data_changed INPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE data_changed INPUT.
  IF gf_dispchg = gc_change.
    gf_data_change = 'X'.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE data_changed_setid INPUT                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE data_changed_setid INPUT.
  IF gf_dispchg = gc_change.
    gf_setid_change = 'X'.
  ENDIF.
  CLEAR gf_set_loaded.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE data_changed_103 INPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE data_changed_103 INPUT.
  IF gf_dispchg = gc_change.
    gv_inactive_data_change = 'X'.
  ENDIF.
ENDMODULE.
