*----------------------------------------------------------------------*
***INCLUDE ZARP_RES_ACC_PUB_CONFIG_SETF01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CREATE_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_fieldcat CHANGING gt_fieldcat TYPE lvc_t_fcat.

  FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.

  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
    EXPORTING
      i_structure_name       = '/PSYNG/SW_CNFACC'
    CHANGING
      ct_fieldcat            = gt_fieldcat
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      <fcat>-edit = 'X'.
    ELSE.
      CLEAR <fcat>-edit.
    ENDIF.

    CASE <fcat>-fieldname.

      WHEN 'USERNAME'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                 = <fcat>-reptext = 'User'(H01).
      WHEN 'SIGN'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'Sign'(H02).
        <fcat>-f4availabl = 'X'.
      WHEN 'OPTON'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'Option'(H03).
        <fcat>-f4availabl = 'X'.
      WHEN 'SYSIDLOW'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'System ID low'(H04).
*        <fcat>-f4availabl = 'X'.
      WHEN 'SYSIDHIGH'.
        <fcat>-scrtext_l = <fcat>-scrtext_m = <fcat>-scrtext_s
                         = <fcat>-reptext = 'System ID high'(H05).
*        <fcat>-f4availabl = 'X'.
      WHEN OTHERS.

    ENDCASE.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_OBJECTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_objects
              CHANGING g_cust_cont TYPE REF TO cl_gui_custom_container
                       g_alv_grid TYPE REF TO cl_gui_alv_grid.

  CREATE OBJECT g_cust_cont
    EXPORTING
      container_name = 'CUST_CONT'.

  CREATE OBJECT g_alv_grid
    EXPORTING
      i_parent = g_cust_cont.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv .

  DATA : lt_functions TYPE ui_functions,
         ls_layout    TYPE lvc_s_layo.

  PERFORM create_fieldcat CHANGING gt_fieldcat.
  PERFORM layout CHANGING ls_layout.

  IF g_alv_grid IS INITIAL.

    PERFORM create_objects CHANGING g_cust_cont g_alv_grid.
    PERFORM remove_tb_buttons TABLES lt_functions.
    PERFORM set_handlers.
    PERFORM register_events.

    CALL METHOD g_alv_grid->set_table_for_first_display
      EXPORTING
        is_layout                     = ls_layout
        it_toolbar_excluding          = lt_functions
      CHANGING
        it_outtab                     = gt_res_access
        it_fieldcatalog               = gt_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
           WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ELSE.

    CALL METHOD g_alv_grid->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD g_alv_grid->set_frontend_layout
      EXPORTING
        is_layout = ls_layout.

    CALL METHOD g_alv_grid->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDIF.

  PERFORM set_f4_enabled_fields.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data CHANGING gt_res_access TYPE tt_res_access.
  REFRESH gt_res_access.
  SELECT username
         sign
         opton
         sysidlow
         sysidhigh
         FROM /psyng/sw_cnfacc
         INTO TABLE gt_res_access.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_USER_COMMAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_UCOMM  text
*----------------------------------------------------------------------*
FORM handle_user_command  USING i_ucomm TYPE sy-ucomm.

  CASE i_ucomm.

    WHEN 'DISPCHG'.

      IF gf_dispchg = gc_display.
        gf_dispchg = gc_change.
      ELSE.
        gf_dispchg = gc_display.
        PERFORM get_data CHANGING gt_res_access.
      ENDIF.
* BOC by GSINGH on 06.02.2023 for B17166 - Adding authorization check
      PERFORM check_authorization
                  USING
                     gf_dispchg.
* EOC by GSINGH.
      PERFORM set_status.
      PERFORM display_alv.

    WHEN 'INSR'.

*--Insert new row in ALV
      PERFORM add_row.

    WHEN 'DELE'.

*--Get selected rows
      PERFORM delete_row.

    WHEN '&INFO' .
      CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
        EXPORTING
          dokname = '/PSYNG/SE_CONFSETACC_SCR_DOC'.
      CALL METHOD g_alv_grid->set_user_command
        EXPORTING
          i_ucomm = space.

    WHEN OTHERS.

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_STATUS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_status .
  DATA : lt_exclude TYPE TABLE OF sy-ucomm WITH HEADER LINE.

  IF gf_dispchg = gc_display.
    lt_exclude = 'SAVE'.
    APPEND lt_exclude.
    SET PF-STATUS 'PF_STATUS_100' EXCLUDING lt_exclude.
  ELSE.
    SET PF-STATUS 'PF_STATUS_100'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXIT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exit .
  SET SCREEN 0.
  LEAVE SCREEN.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SAVE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data .

  TYPES : BEGIN OF ty_sw_rfcdes,
            systid TYPE /psyng/sw_rfcdes-systid,
          END OF ty_sw_rfcdes.

  DATA : lt_res_access TYPE TABLE OF /psyng/sw_cnfacc
        with HEADER LINE,
         lt_sw_rfcdes  TYPE TABLE OF ty_sw_rfcdes,
         ls_usr02      TYPE usr02,
         ls_sw_rfcdes  TYPE ty_sw_rfcdes,
         lv_error(50)  TYPE c, "Validation error message
         lf_pattern1   TYPE flag,
         lf_pattern2   TYPE flag,
         lf_save       TYPE c VALUE 'X'. "Validation check

  RANGES :
*--Valid sign values
  lr_sign FOR gs_res_access-sign,
*--Valid option values
   lr_opton FOR gs_res_access-opton,
*--Valid system IDs
   lr_systid FOR gs_res_access-sysidlow.

  CALL METHOD g_alv_grid->check_changed_data.

*--
  lr_sign-sign = 'I'.
  lr_sign-option = 'EQ'.
  lr_sign-low = 'I'.
  APPEND lr_sign.

  lr_sign-low = 'E'.
  APPEND lr_sign.
*--

*--
  lr_opton-sign = 'I'.
  lr_opton-option = 'EQ'.
  lr_opton-low = 'EQ'.
  APPEND lr_opton.

  lr_opton-low = 'BT'.
  APPEND lr_opton.
  lr_opton-low = 'CP'.
  APPEND lr_opton.
  lr_opton-low = 'NE'.
  APPEND lr_opton.
  lr_opton-low = 'GE'.
  APPEND lr_opton.
  lr_opton-low = 'GT'.
  APPEND lr_opton.
  lr_opton-low = 'LE'.
  APPEND lr_opton.
  lr_opton-low = 'LT'.
  APPEND lr_opton.
  lr_opton-low = 'NP'.
  APPEND lr_opton.

*--
  SELECT systid
         FROM /psyng/sw_rfcdes
         INTO TABLE lt_sw_rfcdes.

  LOOP AT lt_sw_rfcdes INTO ls_sw_rfcdes.
    CLEAR lr_systid.
    lr_systid-sign = 'I'.
    lr_systid-option = 'EQ'.
    lr_systid-low = ls_sw_rfcdes-systid.
    APPEND lr_systid.
  ENDLOOP.

  lr_systid-low = ' '.
  APPEND lr_systid.
*--

*--Data validation
  CLEAR gs_res_access.
  LOOP AT gt_res_access INTO gs_res_access.

    SELECT SINGLE *
                  FROM usr02
                  INTO ls_usr02
                  WHERE bname = gs_res_access-username.
    IF sy-subrc NE 0.
      CLEAR lv_error.
      CONCATENATE gs_res_access-username ' Invalid user'(003) INTO
                                                             lv_error.
      CLEAR lf_save.
      MESSAGE lv_error TYPE 'I'.
      EXIT.
    ENDIF.

    PERFORM pattern_check USING gs_res_access-sysidlow
                      CHANGING lf_pattern1.

    PERFORM pattern_check USING gs_res_access-sysidhigh
                  CHANGING lf_pattern2.

    IF NOT gs_res_access-sign IN lr_sign.
      CLEAR lv_error.
      CONCATENATE gs_res_access-sign ' Invalid sign'(004) INTO lv_error.
      CLEAR lf_save.
      MESSAGE lv_error TYPE 'I'.
      EXIT.
    ELSEIF NOT gs_res_access-opton IN lr_opton.
      CLEAR lv_error.
      CONCATENATE gs_res_access-opton ' Invalid option'(005) INTO
                                                               lv_error.
      CLEAR lf_save.
      MESSAGE lv_error TYPE 'I'.
      EXIT.
    ELSEIF NOT gs_res_access-sysidlow IN lr_systid AND lf_pattern1 IS
INITIAL.

      CLEAR lv_error.
      CONCATENATE gs_res_access-sysidlow ' Invalid system ID low'(006)
                                                      INTO lv_error.

      CLEAR lf_save.
      MESSAGE lv_error TYPE 'I'.
      EXIT.

    ELSEIF NOT gs_res_access-sysidhigh IN lr_systid AND lf_pattern2 IS
INITIAL..
      CLEAR lv_error.
      CONCATENATE gs_res_access-sysidhigh
      ' Invalid system ID high'(007) INTO lv_error.
      CLEAR lf_save.
      MESSAGE lv_error TYPE 'I'.
      EXIT.
    ENDIF.
  ENDLOOP.
  IF lf_save = 'X'.

    SORT gt_res_access.
    DELETE ADJACENT DUPLICATES FROM gt_res_access COMPARING ALL FIELDS.

    DELETE FROM /psyng/sw_cnfacc.

    loop at gt_res_access into gs_res_access.
      MOVE-CORRESPONDING gs_res_access to lt_res_access.
      append lt_res_access.
      clear: gs_res_access, lt_res_access.
      endloop.
*    MOVE-CORRESPONDING gt_res_access TO lt_res_access.
    INSERT /psyng/sw_cnfacc FROM TABLE lt_res_access.
    gf_dispchg = gc_change.

    MESSAGE s113(/psyng/basis) WITH 'Data saved successfully'(008).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_HELP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_FIELDNAME  text
*      -->P_ES_ROW_NO  text
*----------------------------------------------------------------------*
FORM f4_help USING i_fieldname TYPE lvc_fname
                       is_row_no TYPE lvc_s_roid.

  DATA : lt_values TYPE TABLE OF ty_values,
         lt_fields TYPE TABLE OF dfies,
         lt_return TYPE TABLE OF ddshretval,
         ls_return TYPE ddshretval.

  FIELD-SYMBOLS: <fs_res_access> LIKE LINE OF gt_res_access.

  READ TABLE gt_res_access ASSIGNING <fs_res_access>
  INDEX is_row_no-row_id.
  CHECK sy-subrc = 0.

  CASE i_fieldname.

    WHEN 'SIGN'.

      gf_sign = 'X'.
      REFRESH : lt_values, lt_fields.
      PERFORM prepare_value_table CHANGING lt_values.
      PERFORM prepare_field_table CHANGING lt_fields.
      CLEAR gf_sign.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'SIGN'
        TABLES
          value_tab       = lt_values
          field_tab       = lt_fields
          return_tab      = lt_return
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        IF lt_return IS NOT INITIAL AND gf_dispchg = gc_change.
          CLEAR ls_return.
          READ TABLE lt_return INTO ls_return INDEX 1.
          <fs_res_access>-sign = ls_return-fieldval.
        ENDIF.
      ENDIF.

      CALL METHOD g_alv_grid->refresh_table_display
        EXCEPTIONS
          finished = 1
          OTHERS   = 2.

      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.


    WHEN 'OPTON'.

      gf_opton = 'X'.
      REFRESH : lt_values, lt_fields.
      PERFORM prepare_value_table CHANGING lt_values.
      PERFORM prepare_field_table CHANGING lt_fields.
      CLEAR gf_opton.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'OPTON'
        TABLES
          value_tab       = lt_values
          field_tab       = lt_fields
          return_tab      = lt_return
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        IF lt_return IS NOT INITIAL AND gf_dispchg = gc_change.
          CLEAR ls_return.
          READ TABLE lt_return INTO ls_return INDEX 1.
          <fs_res_access>-opton = ls_return-fieldval.
        ENDIF.
      ENDIF.

      CALL METHOD g_alv_grid->refresh_table_display
        EXCEPTIONS
          finished = 1
          OTHERS   = 2.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'SYSIDLOW'.

      gf_sysidlow = 'X'.
      REFRESH : lt_values, lt_fields.
      PERFORM prepare_value_table CHANGING lt_values.
      PERFORM prepare_field_table CHANGING lt_fields.
      CLEAR gf_sysidlow.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'SYSIDLOW'
        TABLES
          value_tab       = lt_values
          field_tab       = lt_fields
          return_tab      = lt_return
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        IF lt_return IS NOT INITIAL AND gf_dispchg = gc_change.
          CLEAR ls_return.
          READ TABLE lt_return INTO ls_return INDEX 1.
          <fs_res_access>-sysidlow = ls_return-fieldval.
        ENDIF.
      ENDIF.

      CALL METHOD g_alv_grid->refresh_table_display
        EXCEPTIONS
          finished = 1
          OTHERS   = 2.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'SYSIDHIGH'.

      gf_sysidhigh = 'X'.
      REFRESH : lt_values, lt_fields.
      PERFORM prepare_value_table CHANGING lt_values.
      PERFORM prepare_field_table CHANGING lt_fields.
      CLEAR gf_sysidhigh.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
        EXPORTING
          retfield        = 'SYSIDHIGH'
        TABLES
          value_tab       = lt_values
          field_tab       = lt_fields
          return_tab      = lt_return
        EXCEPTIONS
          parameter_error = 1
          no_values_found = 2
          OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        IF lt_return IS NOT INITIAL AND gf_dispchg = gc_change.
          CLEAR ls_return.
          READ TABLE lt_return INTO ls_return INDEX 1.
          <fs_res_access>-sysidhigh = ls_return-fieldval.
        ENDIF.
      ENDIF.

      CALL METHOD g_alv_grid->refresh_table_display
        EXCEPTIONS
          finished = 1
          OTHERS   = 2.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN OTHERS.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_F4_ENABLED_FIELDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_f4_enabled_fields .

  DATA : lt_f4 TYPE lvc_t_f4,
         wa_f4 LIKE LINE OF lt_f4.

*  CLEAR wa_f4.
*  wa_f4-fieldname = 'USERNAME'.
*  wa_f4-register  = 'X' .
*  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SIGN'.
  wa_f4-register  = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'OPTON'.
  wa_f4-register  = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SYSIDLOW'.
  wa_f4-register  = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  wa_f4-fieldname = 'SYSIDHIGH'.
  wa_f4-register  = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD g_alv_grid->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ADD_ROW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM add_row.

  CLEAR gs_res_access.
  INSERT gs_res_access INTO gt_res_access INDEX 1.

  CALL METHOD g_alv_grid->refresh_table_display
    EXCEPTIONS
      finished = 1
      OTHERS   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DELETE_ROW
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_row .

*--Declare internal table to store index of selected rows
  DATA: lt_selected_rows TYPE lvc_t_row,
        ls_selected_rows TYPE lvc_s_row,
        ls_res_access    TYPE ty_res_access.

*--FM to get the selected rows
  CALL METHOD g_alv_grid->get_selected_rows
    IMPORTING
      et_index_rows = lt_selected_rows.

  CLEAR ls_selected_rows.

*--Deleting records from ALV table one by one.
  LOOP AT lt_selected_rows INTO ls_selected_rows.
    READ TABLE gt_res_access INTO ls_res_access INDEX
                                                ls_selected_rows-index.
    DELETE FROM /psyng/sw_cnfacc WHERE username =
                                                ls_res_access-username.
    DELETE gt_res_access INDEX ls_selected_rows-index.
  ENDLOOP.

*--Refreshing table
  CALL METHOD g_alv_grid->refresh_table_display
    EXCEPTIONS
      finished = 1
      OTHERS   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  MESSAGE s113(/psyng/basis) WITH 'Records deleted successfully'(009).

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  REMOVE_TB_BUTTONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FUNCTIONS  text
*----------------------------------------------------------------------*
FORM remove_tb_buttons  TABLES   pt_functions TYPE ui_functions.

  DATA ls_exclude_functions TYPE ui_func.
*BOC by GSINGH on 07.02.2023 for B16164 - Info icon needs to be added on
*the screen. Commenting the below code
*  ls_exclude_functions = cl_gui_alv_grid=>mc_fc_info.
*  APPEND ls_exclude_functions TO pt_functions.
*  CLEAR  ls_exclude_functions.
* EOC by GSINGH
  ls_exclude_functions = cl_gui_alv_grid=>mc_fc_graph.
  APPEND ls_exclude_functions TO pt_functions.
  CLEAR  ls_exclude_functions.

  ls_exclude_functions = cl_gui_alv_grid=>mc_mb_sum.
  APPEND ls_exclude_functions TO pt_functions.
  CLEAR  ls_exclude_functions.

  ls_exclude_functions = cl_gui_alv_grid=>mc_mb_variant.
  APPEND ls_exclude_functions TO pt_functions.
  CLEAR  ls_exclude_functions.

  ls_exclude_functions = cl_gui_alv_grid=>mc_mb_view.
  APPEND ls_exclude_functions TO pt_functions.
  CLEAR  ls_exclude_functions.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  LAYOUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LS_LAYOUT  text
*----------------------------------------------------------------------*
FORM layout  CHANGING ls_layout TYPE lvc_s_layo.
  ls_layout-zebra = 'X'.
  ls_layout-cwidth_opt = 'X'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_HANDLERS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_handlers .
  SET HANDLER gr_event_handler->handle_toolbar FOR g_alv_grid.
  SET HANDLER gr_event_handler->handle_user_command FOR g_alv_grid.
  SET HANDLER gr_event_handler->handle_on_f4 FOR g_alv_grid.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PREPARE_VALUE_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LF_SIGN  text
*      <--P_LT_VALUES  text
*----------------------------------------------------------------------*
FORM prepare_value_table CHANGING lt_values TYPE tt_values.

  DATA : ls_values TYPE ty_values.

  IF gf_sign = 'X'.

    ls_values-line = 'I'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'E'.
    APPEND ls_values TO lt_values.

  ELSEIF gf_opton = 'X'.

    ls_values-line = 'EQ'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'BT'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'CP'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'NE'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'GE'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'GT'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'LE'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'LT'.
    APPEND ls_values TO lt_values.
    ls_values-line = 'NP'.
    APPEND ls_values TO lt_values.

  ELSEIF gf_sysidlow = 'X'.

    SELECT systid
     FROM /psyng/sw_rfcdes
     INTO TABLE lt_values
     UP TO 500 ROWS.

  ELSEIF gf_sysidhigh = 'X'.

    SELECT systid
            FROM /psyng/sw_rfcdes
            INTO TABLE lt_values
             UP TO 500 ROWS.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PREPARE_FIELD_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_FIELDS  text
*----------------------------------------------------------------------*
FORM prepare_field_table CHANGING lt_fields TYPE tt_dfies.

  DATA : ls_fields TYPE dfies.

  IF gf_sign = 'X'.

    ls_fields-tabname   = '/PSYNG/SW_CNFACC'.
    ls_fields-fieldname = 'SIGN'.
    APPEND ls_fields TO lt_fields.

  ELSEIF gf_opton = 'X'.

    ls_fields-tabname   = '/PSYNG/SW_CNFACC'.
    ls_fields-fieldname = 'OPTON'.
    APPEND ls_fields TO lt_fields.

  ELSEIF gf_sysidlow = 'X'.

    ls_fields-tabname   = '/PSYNG/SW_CNFACC'.
    ls_fields-fieldname = 'SYSIDLOW'.
    APPEND ls_fields TO lt_fields.

  ELSEIF gf_sysidhigh = 'X'.

    ls_fields-tabname   = '/PSYNG/SW_CNFACC'.
    ls_fields-fieldname = 'SYSIDHIGH'.
    APPEND ls_fields TO lt_fields.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  REGISTER_EVENTS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM register_events .

  CALL METHOD g_alv_grid->register_edit_event
    EXPORTING
      i_event_id = cl_gui_alv_grid=>mc_evt_modified.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  PATTERN_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GS_RES_ACCESS_SYSIDLOW  text
*      <--P_LF_PATTERN  text
*----------------------------------------------------------------------*
FORM pattern_check  USING    VALUE(systid) TYPE /psyng/sw_rfcdes-systid
                    CHANGING lf_pattern TYPE flag.

  DATA : ls_sw_rfcdes TYPE /psyng/sw_rfcdes.

    DO.
    REPLACE ALL OCCURRENCES OF '*' IN systid WITH '%'.
    IF sy-subrc NE 0. EXIT. ENDIF.
    ENDDO.

*  REPLACE ALL OCCURRENCES OF '*' IN systid WITH '%'.

  SELECT SINGLE *
               FROM /psyng/sw_rfcdes
               INTO ls_sw_rfcdes
              WHERE systid LIKE systid.
  IF sy-subrc EQ 0.
    lf_pattern = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_AUTHORIZATION
*&---------------------------------------------------------------------*
* Authorization check added by GSINGH on 06.02.2023 for B17166
*----------------------------------------------------------------------*
FORM check_authorization USING    if_dispchg.
  DATA : l_actvt(2) TYPE c,
         l_msg      TYPE string.
  IF if_dispchg = gc_display.
    l_actvt = '03'."display
    l_msg = 'Display'(a01).
  ELSE.
    l_actvt = '02'."change
    l_msg = 'Change'(a02).

  ENDIF.

  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
          ID 'DICBERCLS' FIELD 'Y&S4'
          ID 'ACTVT' FIELD l_actvt.
  IF sy-subrc <> 0.
    AUTHORITY-CHECK OBJECT 'S_TABU_NAM'
        ID 'TABLE' FIELD '/PSYNG/SW_CNFACC'
        ID 'ACTVT' FIELD l_actvt.
    IF sy-subrc <> 0.
      MESSAGE e108(/psyng/sw) WITH l_msg
      'Maintain Access to Create/Publish Config. Set'(a03).
*   You are not authorized to & & & &
    ENDIF.
  ENDIF.

ENDFORM.
