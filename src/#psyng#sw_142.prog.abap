REPORT /psyng/sw_142 MESSAGE-ID /psyng/sw.
TABLES: /psyng/swconfig.
DATA: gf_data_change(1)     TYPE c,
      g_delete_click(1)     TYPE c,
      gf_dispchg(1)         TYPE c,
      gf_check_changed_data TYPE char1,
      g_dc_protocol         TYPE REF TO cl_alv_changed_data_protocol.
CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.
INCLUDE /psyng/sw_142_cl1.
DEFINE add_column.

  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  gs_fieldcat-no_out = &6.
*  gs_fieldcat-col_opt = 'X'.
*  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  if not &8 = ''.
    gs_fieldcat-style      = &8.
  else.
    gs_fieldcat-style      = '0000'.
  endif.
  gs_fieldcat-LOWERCASE   = &9.
  append gs_fieldcat to &4.
END-OF-DEFINITION.

DEFINE add_sort.
  gs_sort-up   = 'X'.
  add 1 to gs_sort-spos .
  gs_sort-fieldname = &1.
  append gs_sort to gt_sort.

END-OF-DEFINITION.

*CONSTANTS: gc_display(1) TYPE c VALUE 'D',
*           gc_change(1)  TYPE c VALUE 'C'.

*--data declare
*---field catalog
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
DATA: p_cat     TYPE char40,
      p_fpar    TYPE char40,
      gt_cat_dd TYPE vrm_values,
      gt_par_dd TYPE vrm_values.

*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
DATA: gt_fieldcat   TYPE lvc_t_fcat,
      gt_sort       TYPE lvc_t_sort,
      gs_sort       TYPE lvc_s_sort,
      gs_fieldcat   TYPE lvc_s_fcat,
      gs_layout     TYPE lvc_s_layo,
*      gf_dispchg(1) TYPE c,
      gr_alvgrid    TYPE REF TO cl_gui_alv_grid,
      gr_ccontainer TYPE REF TO cl_gui_custom_container,
      ls_celltab    TYPE lvc_s_styl,
      gt_celltab    TYPE lvc_t_styl.
DATA: BEGIN OF gt_config OCCURS 10.
        INCLUDE STRUCTURE /psyng/se_config_param.
        DATA :  info_icon(20)   TYPE c,
        revert_icon(20) TYPE c,
        drop_down       TYPE i,
        mtext           TYPE natxt,
        sel(1)          TYPE c,
        celltab         TYPE lvc_t_styl,
      END OF gt_config,
      gt_config_chg TYPE TABLE OF /psyng/se_config_param,
      gt_delete     TYPE TABLE OF /psyng/se_config_param,
      gt_dropdown   TYPE  lvc_t_drop.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
DATA: gt_config_all LIKE TABLE OF gt_config,
      ls_conf       LIKE LINE OF gt_config_all.
*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
*---Selection screen
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN:SKIP 1.
PARAMETERS: p_system TYPE /psyng/swcfgsys-sysid.
SELECTION-SCREEN:SKIP 1.
*SELECTION-SCREEN: BEGIN OF LINE.
SELECT-OPTIONS: so_param FOR /psyng/swconfig-param.
*SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: END OF BLOCK b1.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.


START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  CREATE OBJECT gr_event_handler.
  gf_dispchg = gc_display.
  PERFORM get_data.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
  gt_config_all[] = gt_config[].
*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
  CALL SCREEN '0100'.



*---------------------------------------------------------------------*
*       MODULE STATUS_0100 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  PERFORM set_status.
  SET TITLEBAR '0100' WITH p_system.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
  PERFORM populate_filter_dropdowns.
*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0100 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  DATA: lf_answer(1)  TYPE c,
        lf_valid      TYPE flag,
        ls_config_chg LIKE LINE OF gt_config_chg.
  gf_check_changed_data = 'X'.
  CALL METHOD gr_alvgrid->check_changed_data.
  CLEAR gf_check_changed_data.
  CASE sy-ucomm.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
    WHEN 'CAT_CHG'.
     CLEAR p_fpar.
      " Do NOT call apply_filter here
      " PBO will automatically call populate_filter_dropdowns
      " which rebuilds parameter dropdown filtered by p_cat
    WHEN 'APPLY_FLT'.
      PERFORM apply_filter.
      IF gr_alvgrid IS NOT INITIAL.
        CALL METHOD gr_alvgrid->refresh_table_display.
      ENDIF.
*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
    WHEN 'BACK'.
      PERFORM exit.
    WHEN 'SAVE'.

*----deleted param
      IF g_delete_click = 'X'.
        APPEND LINES OF gt_delete TO gt_config_chg.
      ENDIF.

*-- inserted rows
      LOOP AT gt_config WHERE maintained <> 'X' AND sel = 'X'.
        ls_config_chg-param = gt_config-param.
        ls_config_chg-value = gt_config-value.
        ls_config_chg-maintained = gt_config-maintained.
        APPEND ls_config_chg TO gt_config_chg.
      ENDLOOP.
      DELETE gt_config_chg WHERE param IS INITIAL.
      PERFORM validate_all CHANGING lf_valid.
      PERFORM save_data USING lf_valid.

*--if config table has sel = 'X' means inserted new records
*---for custom param
      READ TABLE gt_config WITH KEY
           maintained = ' '
           sel        = 'X'.
      IF sy-subrc = 0.
        PERFORM get_data.
        CALL METHOD gr_alvgrid->refresh_table_display.
      ENDIF.
    WHEN 'TRANSPORT'.
      SUBMIT /psyng/sw_048 VIA SELECTION-SCREEN
             WITH p_tconfg = 'X'
             AND RETURN.
    WHEN 'CDOCS'.
      PERFORM call_change_history.
    WHEN 'REV_ALL'.
      PERFORM revert_all.
    WHEN 'VALIDATE'.
      PERFORM validate_all CHANGING lf_valid.
      IF lf_valid = 'X'.
        MESSAGE s002 WITH
        'All configuration parameter values are valid.'(w02).
      ENDIF.
    WHEN 'CREATE'.
      DATA: l_row_no  TYPE lvc_s_roid,
            ls_stable TYPE lvc_s_stbl.

      REFRESH :gt_celltab[].
      ls_celltab-fieldname = 'CATEGORY'.
      ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
      APPEND ls_celltab TO gt_celltab.
      ls_celltab-fieldname = 'DEFAULT'.
      ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
      APPEND ls_celltab TO gt_celltab.
      ls_celltab-fieldname = 'MTEXT'.
      ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
      APPEND ls_celltab TO gt_celltab.
      ls_celltab-fieldname = 'PARAM'.
      ls_celltab-style = cl_gui_alv_grid=>mc_style_enabled.
      APPEND ls_celltab TO gt_celltab.
      gt_config-sel = 'X'.
      gt_config-category = 'Custom'."do not assign text element
      gt_config-celltab =  gt_celltab[].
      APPEND gt_config.

      ls_stable-row = 'X'.
      ls_stable-col = 'X'.
      CALL METHOD gr_alvgrid->refresh_table_display
        EXPORTING
          i_soft_refresh = 'X'
          is_stable      = ls_stable
        EXCEPTIONS
          finished       = 1
          OTHERS         = 2.

*  Get the added row index and set the active window
      DESCRIBE TABLE gt_config LINES l_row_no-row_id.
      CALL METHOD gr_alvgrid->set_current_cell_via_id
        EXPORTING
          is_row_no = l_row_no.

    WHEN 'DELETE'.
      g_delete_click = 'X'.
      DATA: lt_rows   TYPE lvc_t_row,
            ls_row    LIKE LINE OF lt_rows,
            ls_delete LIKE LINE OF gt_config_chg,
            l_rows    TYPE i.
*----get selected row
      CALL METHOD gr_alvgrid->get_selected_rows
        IMPORTING
          et_index_rows = lt_rows.
      DESCRIBE TABLE lt_rows LINES l_rows.
      IF lt_rows[] IS INITIAL.
        MESSAGE s002 WITH 'Please select a row'(e20).
      ELSEIF l_rows > 1.
        MESSAGE s002 WITH
              'Only one row at a time can be deleted'(e22).
      ELSE.
        READ TABLE lt_rows INTO ls_row
              INDEX 1.
        READ TABLE gt_config INDEX ls_row-index.
*----only delete custom param
        IF NOT gt_config-category IS INITIAL AND
          gt_config-category <> 'Custom'.
          MESSAGE i002 WITH
      'Only Custom Parameters Can be Deleted'(e21).
        ELSE.
          ls_delete-param = gt_config-param.
          ls_delete-value = gt_config-value.
          ls_delete-category = gt_config-category.
          ls_delete-maintained = gt_config-maintained.
          APPEND ls_delete TO gt_delete.
          DELETE gt_config INDEX ls_row-index.
        ENDIF.
      ENDIF.
      CALL METHOD gr_alvgrid->refresh_table_display.
  ENDCASE.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE display_alv_100 OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_alv_100 OUTPUT.
  PERFORM display_alv_100.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM display_alv_100                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv_100.

  DATA: ls_stable   TYPE lvc_s_stbl.
  FIELD-SYMBOLS: <fs_fieldcat> TYPE lvc_s_fcat.
  CLEAR gs_layout.



*  READ TABLE gt_fieldcat ASSIGNING <fs_fieldcat>
*  WITH KEY fieldname = 'VALUE'.
*  IF sy-subrc EQ 0.
*    IF gf_dispchg = gc_change.
*      <fs_fieldcat>-edit = 'X'.
*    ELSE.
*      CLEAR <fs_fieldcat>-edit.
*    ENDIF.
*    <fs_fieldcat>-drdn_field = 'DROP_DOWN'.
*  ENDIF.

  IF gr_alvgrid IS INITIAL .

    REFRESH : gt_fieldcat,gt_sort.
*----Preparing field catalog.
    add_column:
    '' 'CATEGORY'    'Category'(c01)      gt_fieldcat 20 '' '' '' '',
    '' 'PARAM'       'Parameters'(c02)    gt_fieldcat 25  ''  '' '' '',
    '' 'INFO_ICON'   'Info.'(c05)         gt_fieldcat 5 '' ''
                     cl_gui_alv_grid=>mc_style_button '',
    '' 'DEFAULT'     'Default Value'(c03) gt_fieldcat 40 '' '' '' 'X'.
    IF gf_dispchg = gc_change.
      add_column:
      '' 'REVERT_ICON' 'Revert'(c06)        gt_fieldcat 5 '' ''
                       cl_gui_alv_grid=>mc_style_button ''.
    ENDIF.
    add_column:
    '' 'VALUE'       'Current Value'(c04) gt_fieldcat 40 '' '' '' 'X',
    '' 'MTEXT'       'Description'(c07)          gt_fieldcat 72 '' '' ''
    'X'.

    .
*--Prepare sort criteria
    add_sort : 'CATEGORY', 'PARAM'.

    LOOP AT gt_fieldcat ASSIGNING <fs_fieldcat>.
      CASE <fs_fieldcat>-fieldname.
        WHEN 'DEFAULT' OR 'CATEGORY' OR 'PARAM' OR
             'VALUE' OR 'DROP_DOWN' OR 'MTEXT'.
          IF <fs_fieldcat>-fieldname = 'VALUE'.
            <fs_fieldcat>-drdn_field = 'DROP_DOWN'.
          ENDIF.
          <fs_fieldcat>-edit = 'X'.
        WHEN OTHERS.
          <fs_fieldcat>-edit = ' '.
      ENDCASE.
    ENDLOOP.

*----Creating custom container instance
    CREATE OBJECT gr_ccontainer
      EXPORTING
        container_name              = 'CC_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent          = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.


    SET HANDLER gr_event_handler->button_click FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_toolbar FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_user_command FOR gr_alvgrid.
    SET HANDLER gr_event_handler->data_changed FOR gr_alvgrid.
*----Preparing layout structure
*    gs_layout-sel_mode = 'A'. " for selection bar
    gs_layout-zebra = 'X'.
    gs_layout-stylefname = 'CELLTAB'.
    CALL METHOD gr_alvgrid->set_drop_down_table
      EXPORTING
        it_drop_down = gt_dropdown.


*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_config[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
    CALL METHOD gr_alvgrid->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

  ELSE.
*    CALL METHOD gr_alvgrid->set_frontend_fieldcatalog
*      EXPORTING
*        it_fieldcatalog = gt_fieldcat.
*
*    CALL METHOD gr_alvgrid->set_frontend_layout
*      EXPORTING
*        is_layout = gs_layout.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD gr_alvgrid->refresh_table_display
      EXPORTING
        i_soft_refresh = 'X'
        is_stable      = ls_stable
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2.
  ENDIF.
  IF gf_dispchg = gc_display.
    CALL METHOD gr_alvgrid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 0.
  ELSE.
    CALL METHOD gr_alvgrid->set_ready_for_input
      EXPORTING
        i_ready_for_input = 1.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_data                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_data.
  DATA:
    lt_swrfcdes      TYPE TABLE OF /psyng/sw_rfcdes    WITH HEADER LINE,
    lt_config_param  TYPE TABLE OF /psyng/se_config_param
                                                       WITH HEADER LINE,
    l_system_msg(72) TYPE c,
    lt_valuelist     TYPE TABLE OF /psyng/se_config_param_list,
    lt_valuesort     TYPE SORTED TABLE OF /psyng/se_config_param_list
                     WITH NON-UNIQUE KEY param         WITH HEADER LINE,
    l_dd_handle      TYPE i,
    ls_drop          TYPE lvc_s_drop,
    ls_str           TYPE string.
  FIELD-SYMBOLS : <conf> LIKE gt_config.
  REFRESH gt_config.

  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
  WHERE systid = p_system.

  READ TABLE lt_swrfcdes INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_PARAMETERS_INFO'
    DESTINATION lt_swrfcdes-rfcdest
    TABLES
      it_param              = so_param
      et_config             = lt_config_param
      et_valuelist          = lt_valuelist
    EXCEPTIONS
      communication_failure = 1
      system_failure        = 2
      OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
*BOC:HBHALLA (03/12/24)
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
      WHEN 2.
        MESSAGE s002(/psyng/sw) WITH 'System failure'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (03/12/24)

*  APPEND LINES OF lt_config_param TO gt_config.
*---styles for enable desable column
  REFRESH :gt_celltab[].
  ls_celltab-fieldname = 'CATEGORY'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  APPEND ls_celltab TO gt_celltab.
  ls_celltab-fieldname = 'DEFAULT'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  APPEND ls_celltab TO gt_celltab.
  ls_celltab-fieldname = 'MTEXT'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  APPEND ls_celltab TO gt_celltab.
  ls_celltab-fieldname = 'PARAM'.
  ls_celltab-style = cl_gui_alv_grid=>mc_style_disabled.
  APPEND ls_celltab TO gt_celltab.

  LOOP AT lt_config_param.
    MOVE-CORRESPONDING lt_config_param TO gt_config.
    gt_config-celltab =  gt_celltab[].
    APPEND gt_config.
    CLEAR gt_config.
  ENDLOOP.

  gt_config-info_icon   = '@0S\Q Information@'.
  gt_config-revert_icon = '@2W\Q Revert@'.
  MODIFY gt_config TRANSPORTING info_icon revert_icon WHERE
   param <> space.
  REFRESH : gt_dropdown.
*--Handle dropdown values
  INSERT LINES OF lt_valuelist INTO TABLE lt_valuesort.
  FREE lt_valuelist.
  LOOP AT gt_config ASSIGNING <conf>.
    READ TABLE lt_valuesort WITH TABLE KEY param = <conf>-param.
    IF sy-subrc = 0.
      ADD 1 TO l_dd_handle.

      ls_drop-handle = l_dd_handle.
      <conf>-drop_down  = ls_drop-handle.
      LOOP AT lt_valuesort FROM sy-tabix.
        IF lt_valuesort-param <> <conf>-param.
          EXIT.
        ENDIF.
        ls_drop-value = lt_valuesort-value.
        APPEND ls_drop TO gt_dropdown.
      ENDLOOP.
    ENDIF.
    CLEAR <conf>-mtext.
    MESSAGE ID '/PSYNG/SW_INF' TYPE 'I' NUMBER <conf>-info_msg INTO
    <conf>-mtext.
*-- now that we show this message in the alv, repeating the name of the
*parameter doesn't make sense
*   remove all variations of it
    IF <conf>-category = 'Custom'.
      <conf>-mtext = 'Custom Parameter'(P01).
    ENDIF.
    CONCATENATE <conf>-param ':' INTO  ls_str SEPARATED BY space.
    REPLACE ls_str WITH '' INTO <conf>-mtext.
    CONCATENATE <conf>-param ':' INTO  ls_str.
    REPLACE ls_str WITH '' INTO <conf>-mtext.
    CONCATENATE <conf>-param '' ':' INTO  ls_str SEPARATED BY space.
    REPLACE ls_str WITH '' INTO <conf>-mtext.

  ENDLOOP.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
  gt_config_all[] = gt_config[].
*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_type.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_category.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'SYSTID'
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
  ENDIF.

  READ TABLE lt_return INDEX 1.
  e_value = lt_return-fieldval.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM button_click                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  COL_ID                                                        *
*  -->  ROW_NO                                                        *
*---------------------------------------------------------------------*
FORM button_click  USING    col_id
                            row_no STRUCTURE lvc_s_roid.
  DATA : lt_changed   TYPE TABLE OF /psyng/se_config_param WITH HEADER
  LINE,
         lt_return    TYPE TABLE OF  bapiret2,
         ls_return    TYPE bapiret2,
         l_answer(1)  TYPE c,
         lt_swrfcdes  TYPE TABLE OF /psyng/sw_rfcdes,
         ls_swrfcdes  TYPE /psyng/sw_rfcdes,
         ls_stable    TYPE lvc_s_stbl,
         ls_help_info TYPE help_info,
         li_dselc     TYPE TABLE OF dselc,
         li_dval      TYPE TABLE OF dval.
  CASE col_id.
    WHEN 'INFO_ICON'.
*--Display the long text of the message linked to the configuration
*parameter
      READ TABLE gt_config INDEX row_no-row_id.
      IF NOT gt_config-info_msg IS INITIAL AND gt_config-info_msg > ''.
        ls_help_info-call      = 'D' .
        ls_help_info-messageid = '/PSYNG/SW_INF' .
        ls_help_info-messagenr = gt_config-info_msg .
        ls_help_info-docuid    = 'NA' .
        CALL FUNCTION 'HELP_START'
          EXPORTING
            help_infos   = ls_help_info
          TABLES
            dynpselect   = li_dselc
            dynpvaluetab = li_dval.
      ELSE.
        MESSAGE i020 WITH 'Information about this parameter'(000).
      ENDIF.
    WHEN 'REVERT_ICON'.
      IF gf_dispchg = gc_change.
        READ TABLE gt_config INDEX row_no-row_id.
        MOVE-CORRESPONDING gt_config TO lt_changed.
        lt_changed-value = lt_changed-default.
        APPEND lt_changed.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Confirm'(001)
            text_question         =
                                    'Do you want to replace the current value with the default value?'(qq1)
            text_button_1         = 'Yes'(002)
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = 'No'(003)
            icon_button_2         = 'ICON_CANCEL'
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

        CHECK l_answer EQ '1'.

        SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
        WHERE systid = p_system.
        READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
          EXCEPTIONS
            invalid_reject_option  = 1
            invalid_reject_state   = 2
            function_not_supported = 3
            internal_error         = 4
            OTHERS                 = 5.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
          DESTINATION ls_swrfcdes-rfcdest
          EXPORTING
            if_test               = ' '
          TABLES
            it_config             = lt_changed
            et_return             = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure        = 1
            communication_failure = 2
            OTHERS                = 3.   "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
            WHEN 2.
              MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
            WHEN OTHERS.
              MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
          ENDCASE.
        ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


        READ TABLE lt_return INTO ls_return
          WITH KEY type = 'E'.
        IF sy-subrc NE 0.
          MESSAGE s120.
        ELSE.
          MESSAGE s002 WITH ls_return-message(50)
          ls_return-message+50(50)
          ls_return-message+100(50) ls_return-message+150(50).
        ENDIF.
        PERFORM get_data.
        ls_stable = 'XX'.
        CALL METHOD gr_alvgrid->refresh_table_display
          EXPORTING
            is_stable = ls_stable
*           i_soft_refresh =
          EXCEPTIONS
            finished  = 1
            OTHERS    = 2.
        IF sy-subrc <> 0.
*         Implement suitable error handling here
        ENDIF.

      ENDIF.
  ENDCASE.
ENDFORM.
FORM revert_all.
  DATA : lt_changed  TYPE TABLE OF /psyng/se_config_param WITH HEADER
  LINE,
         lt_return   TYPE TABLE OF  bapiret2,
         ls_return   TYPE bapiret2,
         l_answer(1) TYPE c,
         lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
         ls_swrfcdes TYPE /psyng/sw_rfcdes.
  IF gf_dispchg = gc_change.
    LOOP AT gt_config .
      MOVE-CORRESPONDING gt_config TO lt_changed.
      IF lt_changed-value <> lt_changed-default.
        lt_changed-value = lt_changed-default.
        APPEND lt_changed.
      ENDIF.
    ENDLOOP.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Confirm'(001)
        text_question         =
                                'Do you want to replace ALL of the current values with the defau' &
                                'lt values?'(qq2)
        text_button_1         = 'Yes'(002)
        icon_button_1         = 'ICON_OKAY'
        text_button_2         = 'No'(003)
        icon_button_2         = 'ICON_CANCEL'
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

    CHECK l_answer EQ '1'.

    SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
    WHERE systid = p_system.
    READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
      EXCEPTIONS
        invalid_reject_option  = 1
        invalid_reject_state   = 2
        function_not_supported = 3
        internal_error         = 4
        OTHERS                 = 5.
    IF sy-subrc NE 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
      DESTINATION ls_swrfcdes-rfcdest
      EXPORTING
        if_test               = ' '
      TABLES
        it_config             = lt_changed
        et_return             = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
      EXCEPTIONS
        system_failure        = 1
        communication_failure = 2
        OTHERS                = 3.   "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
        WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
        WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
      ENDCASE.
    ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


    READ TABLE lt_return INTO ls_return
      WITH KEY type = 'E'.
    IF sy-subrc NE 0.
      MESSAGE s120.
    ELSE.
      MESSAGE s002 WITH ls_return-message(50) ls_return-message+50(50)
      ls_return-message+100(50) ls_return-message+150(50).
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data USING lf_valid TYPE flag.

  DATA: lt_return TYPE TABLE OF  bapiret2,
        ls_return TYPE bapiret2.
  DATA: lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
        ls_swrfcdes TYPE /psyng/sw_rfcdes.

  IF gt_config_chg IS NOT INITIAL.
    SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
    WHERE systid = p_system.

    READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.

    IF g_delete_click = 'X'.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
        DESTINATION ls_swrfcdes-rfcdest
        EXPORTING
          if_delete             = 'X'
          if_test               = ' '
          if_config_screen_call = 'X'
        TABLES
          it_config             = gt_config_chg
          et_return             = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
        EXCEPTIONS
          system_failure        = 1
          communication_failure = 2
          OTHERS                = 3.   "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
          WHEN 2.
            MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
          WHEN OTHERS.
            MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
        ENDCASE.
      ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      REFRESH: gt_config_chg, gt_delete.
      CLEAR g_delete_click.
    ELSE.
*BOC UMITTAL SE VF scan changes-25/11/2024
      CALL FUNCTION 'RFC_CALLBACK_REJECTED'
        EXCEPTIONS
          invalid_reject_option  = 1
          invalid_reject_state   = 2
          function_not_supported = 3
          internal_error         = 4
          OTHERS                 = 5.
      IF sy-subrc NE 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
        DESTINATION ls_swrfcdes-rfcdest
        EXPORTING
          if_test               = ' '
        TABLES
          it_config             = gt_config_chg
          et_return             = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
        EXCEPTIONS
          system_failure        = 1
          communication_failure = 2
          OTHERS                = 3.   "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
          WHEN 2.
            MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
          WHEN OTHERS.
            MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
        ENDCASE.
      ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDIF.
    READ TABLE lt_return INTO ls_return
      WITH KEY type = 'E'.
    IF sy-subrc NE 0.
      IF lf_valid IS NOT INITIAL.
        MESSAGE s120.
      ELSE.
        MESSAGE s002 WITH
        'Not all configuration parameter values are valid.'(w01)
        'Only valid values are saved.'(s01) DISPLAY LIKE 'W'.
      ENDIF.
    ELSE.
      MESSAGE s002 WITH ls_return-message(50) ls_return-message+50(50)
      ls_return-message+100(50) ls_return-message+150(50).
    ENDIF.
    CLEAR gf_data_change.
    REFRESH gt_config_chg.
  ELSEIF lf_valid IS NOT INITIAL
  AND gf_data_change IS INITIAL.
    MESSAGE s002 WITH 'No data changed'(t02).
  ENDIF.

ENDFORM.                    " save_data
*&---------------------------------------------------------------------*
*&      Form  handle_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_UCOMM  text
*----------------------------------------------------------------------*
FORM handle_user_command USING i_ucomm TYPE sy-ucomm.

  DATA: lt_return TYPE TABLE OF  bapiret2,
        ls_return TYPE bapiret2.
  DATA: lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
        ls_swrfcdes TYPE /psyng/sw_rfcdes,
        l_auth_fail TYPE flag.
  CLEAR l_auth_fail.
  CASE i_ucomm.
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
        CHECK gf_dispchg = gc_change.
*--Check authorization on local system
        AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
                 ID 'DICBERCLS' FIELD 'Y&S2'
                 ID 'ACTVT' FIELD '02'.
        IF sy-subrc <> 0.
          l_auth_fail = 'X'.
        ENDIF.

*----Opl 549 om 20230118
        AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                 ID 'Y&SW_ADMF' FIELD 'CFGPARMC'.
        IF sy-subrc <> 0.
          l_auth_fail = 'X'.
        ELSE.
          CLEAR l_auth_fail.
        ENDIF.

        IF NOT l_auth_fail IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                   ID 'Y&SW_ADMF' FIELD 'CFGPARAM'.
          IF sy-subrc <> 0.
            l_auth_fail = 'X'.
          ELSE.
            CLEAR l_auth_fail.
          ENDIF.
        ENDIF.


        IF l_auth_fail = 'X'.
          MESSAGE s108 WITH text-e01.
          gf_dispchg = gc_display.
        ELSE.
*--Check authorization on remote system
          SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
          WHERE systid = p_system.
          READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
          CALL FUNCTION 'RFC_CALLBACK_REJECTED'
            EXCEPTIONS
              invalid_reject_option  = 1
              invalid_reject_state   = 2
              function_not_supported = 3
              internal_error         = 4
              OTHERS                 = 5.
          IF sy-subrc NE 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          CALL FUNCTION '/PSYNG/SW_SAVE_CONFIG'
            DESTINATION ls_swrfcdes-rfcdest
            TABLES
              et_return = lt_return. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


          READ TABLE lt_return INTO ls_return
            WITH KEY type = 'E'.
          IF sy-subrc EQ 0.
            MESSAGE s002 WITH ls_return-message(46)
            ls_return-message+47(50).
            gf_dispchg = gc_display.
          ENDIF.
        ENDIF.
      ELSE.                            "Change mode to DISPLAY
        PERFORM exit_without_save CHANGING lf_answer.
        CHECK lf_answer = '1'.
*--Release lock
        gf_dispchg = gc_display.
        PERFORM get_data.
        CLEAR gf_data_change.
        REFRESH gt_config_chg.
      ENDIF.

      PERFORM display_alv_100.
      PERFORM set_status.
  ENDCASE.

ENDFORM.                    " handle_user_command
*&---------------------------------------------------------------------*
*&      Form  set_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_status.
  DATA : lt_exclude TYPE TABLE OF sy-ucomm WITH HEADER LINE,
         l_local    TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local.
  IF p_system IS INITIAL.
    p_system = l_local.
  ENDIF.

  IF p_system <> l_local.
    lt_exclude = 'TRANSPORT'.
    APPEND lt_exclude.
  ENDIF.
  IF gf_dispchg = gc_change.
    SET PF-STATUS '0100' .
  ELSE.
    lt_exclude = 'CREATE'.
    APPEND lt_exclude.
    lt_exclude = 'DELETE'.
    APPEND lt_exclude.
    lt_exclude = 'VALIDATE'.
    APPEND lt_exclude.
    lt_exclude = 'SAVE'.
    APPEND lt_exclude.
    lt_exclude = 'REV_ALL'.
    APPEND lt_exclude.
    SET PF-STATUS '0100' EXCLUDING lt_exclude.
  ENDIF.
ENDFORM.                    " set_status
*&---------------------------------------------------------------------*
*&      Form  exit_without_save
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LF_ANSWER  text
*----------------------------------------------------------------------*
FORM exit_without_save CHANGING ef_answer.
  ef_answer = '1'.
  CHECK gf_data_change = 'X'.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      text_question         = text-q01
      text_button_1         = text-004
      icon_button_1         = 'ICON_OKAY'
      text_button_2         = text-005
      icon_button_2         = 'ICON_CANCEL'
      default_button        = '2'
      display_cancel_button = space
    IMPORTING
      answer                = ef_answer
    EXCEPTIONS
      text_not_found        = 1
      OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " exit_without_save
*&---------------------------------------------------------------------*
*&      Form  exit
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exit.

  DATA: lf_answer(1) TYPE c.

  PERFORM exit_without_save CHANGING lf_answer.
  CHECK lf_answer = '1'.
  SET SCREEN 0.
  LEAVE SCREEN.

ENDFORM.                    " exit
*&---------------------------------------------------------------------*
*&      Form  data_changed
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ER_data_changed  text
*----------------------------------------------------------------------*
FORM data_changed USING er_data_changed
TYPE REF TO cl_alv_changed_data_protocol
e_ucomm TYPE sy-ucomm.

  DATA: ls_mod_cells  TYPE lvc_s_modi,
        lf_valid      TYPE flag,
        ls_config_chg LIKE LINE OF gt_config_chg.
  FIELD-SYMBOLS : <conf> LIKE gt_config.
  gf_data_change = 'X'.
*  g_dc_protocol = er_data_changed.
  LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
         WHERE fieldname = 'VALUE'.
    READ TABLE gt_config INDEX ls_mod_cells-row_id ASSIGNING <conf>.
    IF sy-subrc EQ 0.
      IF <conf>-value NE ls_mod_cells-value.
        PERFORM validate
        USING
             <conf>-param
             ls_mod_cells
             e_ucomm
        CHANGING

              er_data_changed
              lf_valid .

        IF lf_valid = 'X'.
          <conf>-value = ls_mod_cells-value.
          MOVE-CORRESPONDING <conf> TO ls_config_chg.
          APPEND ls_config_chg TO gt_config_chg.
        ELSE.
          <conf>-value = ls_mod_cells-value.

*           exit.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.
*--Validation

ENDFORM.                    " data_changed
FORM validate_all
  CHANGING ef_valid TYPE flag.
  FIELD-SYMBOLS : <conf> LIKE gt_config.
  DATA : lt_config   TYPE TABLE OF /psyng/se_config_param WITH HEADER
  LINE,
         lt_messages TYPE TABLE OF bapiret2 WITH HEADER LINE,
         lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
         ls_swrfcdes TYPE /psyng/sw_rfcdes,
         l_index     TYPE i.
  ef_valid = 'X'.
  CREATE OBJECT g_dc_protocol
    EXPORTING
*     i_container   = gr_ccontainer
      i_calling_alv = gr_alvgrid.
  g_dc_protocol->refresh_protocol( ).
  LOOP AT gt_config ASSIGNING <conf>.
    lt_config-param = <conf>-param.
    lt_config-value = <conf>-value.
    APPEND lt_config.
  ENDLOOP.
  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
    WHERE systid = p_system.
  READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_VALIDATE_CONFIG'
    DESTINATION ls_swrfcdes-rfcdest
    TABLES
      it_config = lt_config
      et_return = lt_messages. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT lt_messages WHERE type = 'E'.
    READ TABLE gt_config WITH KEY param = lt_messages-parameter
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      l_index = sy-tabix.
      CALL METHOD g_dc_protocol->add_protocol_entry
        EXPORTING
          i_msgid     = '/PSYNG/SW'
          i_msgno     = '002'
          i_msgty     = 'E'
          i_msgv1     = lt_messages-parameter
          i_msgv2     = lt_messages-message
          i_msgv3     = lt_messages-message_v3
          i_fieldname = 'VALUE'
          i_row_id    = l_index.
      CLEAR ef_valid.
    ENDIF.
  ENDLOOP.
  IF sy-subrc = 0.
    CALL METHOD g_dc_protocol->display_protocol
      EXPORTING
*       i_container        = gr_ccontainer
        i_display_toolbar  = 'X'
        i_optimize_columns = 'X'.
    COMMIT WORK.
  ENDIF.
ENDFORM.

FORM validate
USING i_param TYPE /psyng/param
      i_cell  TYPE lvc_s_modi
      i_ucomm TYPE sy-ucomm
CHANGING
        er_data_changed TYPE REF TO cl_alv_changed_data_protocol
        ef_valid TYPE flag.
  DATA : lt_config   TYPE TABLE OF /psyng/se_config_param WITH HEADER
  LINE,
         lt_messages TYPE TABLE OF bapiret2 WITH HEADER LINE,
         l_msg       TYPE string,
         lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
         ls_swrfcdes TYPE /psyng/sw_rfcdes.

  ef_valid = 'X'.
  lt_config-param = i_param.
  lt_config-value = i_cell-value.
  APPEND lt_config.

  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
  WHERE systid = p_system.

  READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.

*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
    EXCEPTIONS
      invalid_reject_option  = 1
      invalid_reject_state   = 2
      function_not_supported = 3
      internal_error         = 4
      OTHERS                 = 5.
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_VALIDATE_CONFIG'
    DESTINATION ls_swrfcdes-rfcdest
    TABLES
      it_config = lt_config
      et_return = lt_messages. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  LOOP AT lt_messages WHERE type = 'E'.
    CLEAR ef_valid.
    IF gf_check_changed_data IS INITIAL.
      CALL METHOD er_data_changed->add_protocol_entry
        EXPORTING
          i_msgid     = '/PSYNG/SW'
          i_msgno     = '002'
          i_msgty     = 'E'
          i_msgv1     = lt_messages-parameter
          i_msgv2     = lt_messages-message
          i_msgv3     = lt_messages-message_v3
          i_fieldname = i_cell-fieldname
          i_row_id    = i_cell-row_id.
    ENDIF.
  ENDLOOP.
  IF gf_check_changed_data IS INITIAL.
    er_data_changed->display_protocol(
         i_display_toolbar  = 'X'
         i_optimize_columns = 'X'
         ).
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CALL_CHANGE_HISTORY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_change_history .

  DATA: lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes,
        ls_swrfcdes TYPE /psyng/sw_rfcdes.

  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
  WHERE systid = p_system.

  READ TABLE lt_swrfcdes INTO ls_swrfcdes INDEX 1.
  IF ls_swrfcdes-rfcdest IS NOT INITIAL.
    SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
      WITH p_conf = 'X'
      WITH p_local = ' '
      WITH p_system = ls_swrfcdes-rfcdest
      AND RETURN.
  ELSE.
    SUBMIT /psyng/sw_108 VIA SELECTION-SCREEN
      WITH p_conf = 'X'
      WITH p_local = 'X'
      WITH p_system = ' '
      AND RETURN.
  ENDIF.

ENDFORM.
*BOC UMITTAL 20/05/2026 Add Dropdown on config param screen
*&---------------------------------------------------------------------*
*&      Form  populate_filter_dropdowns        <-- ADD FROM HERE
*&---------------------------------------------------------------------*
FORM populate_filter_dropdowns.
  DATA: ls_val TYPE vrm_value,
        lt_cat TYPE vrm_values,
        lt_par TYPE vrm_values.

  REFRESH: lt_cat, lt_par.

  "--- Build Category dropdown from full dataset
  ls_val-key  = ''.
  ls_val-text = '-- All Categories --'.
  APPEND ls_val TO lt_cat.

  LOOP AT gt_config_all INTO ls_conf.
    IF ls_conf-category IS NOT INITIAL.
      READ TABLE lt_cat WITH KEY key = ls_conf-category
                        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        ls_val-key  = ls_conf-category.
        ls_val-text = ls_conf-category.
        APPEND ls_val TO lt_cat.
      ENDIF.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_CAT'
      values = lt_cat.

  "--- Build Parameter dropdown filtered by selected category
  ls_val-key  = ''.
  ls_val-text = '-- All Parameters --'.
  APPEND ls_val TO lt_par.

  LOOP AT gt_config_all INTO ls_conf.
    DATA lv_conf_cat TYPE char40.
    DATA lv_p_cat    TYPE char40.
    lv_conf_cat = ls_conf-category.
    lv_p_cat    = p_cat.
    TRANSLATE lv_conf_cat TO UPPER CASE.
    TRANSLATE lv_p_cat    TO UPPER CASE.
    IF p_cat IS INITIAL OR lv_conf_cat = lv_p_cat.
      READ TABLE lt_par WITH KEY key = ls_conf-param
                        TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        ls_val-key  = ls_conf-param.
        ls_val-text = ls_conf-param.
        APPEND ls_val TO lt_par.
      ENDIF.
    ENDIF.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'P_FPAR'
      values = lt_par.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  apply_filter
*&---------------------------------------------------------------------*
FORM apply_filter.

  DATA: lv_cat_upper TYPE char40,
        lv_cat_data  TYPE char40.

  REFRESH gt_config.
  gt_config[] = gt_config_all[].

  " Apply category filter - case insensitive
  IF p_cat IS NOT INITIAL.
    lv_cat_upper = p_cat.
    TRANSLATE lv_cat_upper TO UPPER CASE.
    LOOP AT gt_config.
      lv_cat_data = gt_config-category.
      TRANSLATE lv_cat_data TO UPPER CASE.
      IF lv_cat_data <> lv_cat_upper.
        DELETE gt_config.
      ENDIF.
    ENDLOOP.
  ENDIF.

  " Apply parameter filter - case insensitive
  IF p_fpar IS NOT INITIAL.
    LOOP AT gt_config.
      DATA lv_par_data TYPE char40.
      lv_par_data = gt_config-param.
      TRANSLATE lv_par_data TO UPPER CASE.
      DATA lv_fpar_upper TYPE char40.
      lv_fpar_upper = p_fpar.
      TRANSLATE lv_fpar_upper TO UPPER CASE.
      IF lv_par_data <> lv_fpar_upper.
        DELETE gt_config.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFORM.

*EOC UMITTAL 20/05/2026 Add Dropdown on config param screen
