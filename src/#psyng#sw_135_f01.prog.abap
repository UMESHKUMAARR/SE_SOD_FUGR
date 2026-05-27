*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_135_F01                                          *
*----------------------------------------------------------------------*

FORM display_system_selection_alv.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat.
*----Preparing field catalog.
  add_column: ' ' 'SEL' 'Selected'(h01) gt_fieldcat 12 'X'  '' '' 'X',
               ' ' 'SYSID' 'System ID'(h02) gt_fieldcat 32 '' '' '' '',
               ' ' 'RFCDEST' 'RFC Destination '(h03) gt_fieldcat 32 ''
                '' '' ''.


  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      IF <fcat>-fieldname =  'SEL' AND
      NOT /psyng/swcfgset-setid IS INITIAL.
*----  enable edit if setid is not initial
        <fcat>-edit = 'X'.
      ENDIF.
    ELSE.
      CLEAR <fcat>-edit.
    ENDIF.
  ENDLOOP.

  IF gr_alvgrid_sys IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_sys
      EXPORTING
        container_name              = 'SYS_101'
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
    CREATE OBJECT gr_alvgrid_sys
      EXPORTING
        i_parent          = gr_ccontainer_sys
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
*    PERFORM prepare_layout USING 'A' CHANGING gs_layout .
    SET HANDLER gr_event_handler_sys->handle_toolbar FOR gr_alvgrid_sys.
*    SET HANDLER gr_event_handler_sys->handle_data_changed
*                  FOR gr_alvgrid_sys.
    SET HANDLER gr_event_handler_sys->handle_user_command
                                                    FOR gr_alvgrid_sys.
    SET HANDLER gr_event_handler_sys->data_changed   FOR gr_alvgrid_sys.

*.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_sys->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_systems[]
        it_fieldcatalog               = gt_fieldcat
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_sys->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_sys->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_103_1_alv                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_102_1_alv.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat.
*----Preparing field catalog.
  add_column: ' ' 'SELECTED' 'Selected'(h01) gt_fieldcat 12
               ''  '' '' 'X',
               ' ' 'DEFAULT' 'Default'(h04) gt_fieldcat 10 '' '' '' 'X',
               ' ' 'VARBL' 'Organizational Element '(h05) gt_fieldcat 32
               '' '' '' '',
               ' ' 'DESCRIPTION' 'Description '(h06)     gt_fieldcat 60
               '' '' '' ''.


  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      IF <fcat>-fieldname =  'SELECTED' AND
    NOT /psyng/swcfgset-setid IS INITIAL.
*----  enable edit if setid is not initial .
        <fcat>-edit = 'X'.
        <fcat>-hotspot = 'X'.

      ENDIF.
    ELSE.
      CLEAR: <fcat>-edit,<fcat>-hotspot.
    ENDIF.
  ENDLOOP.

  IF gr_alvgrid_ele1 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_ele1
      EXPORTING
        container_name              = 'ELE_102'
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
    CREATE OBJECT gr_alvgrid_ele1
      EXPORTING
        i_parent          = gr_ccontainer_ele1
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
*    PERFORM prepare_layout USING 'A' CHANGING gs_layout .
    SET HANDLER gr_event_handler_ele1->handle_toolbar FOR
gr_alvgrid_ele1.
    SET HANDLER gr_event_handler_ele1->handle_data_changed
                      FOR gr_alvgrid_ele1.
   SET HANDLER gr_event_handler_ele1->data_changed  FOR gr_alvgrid_ele1.
    SET HANDLER gr_event_handler_ele1->handle_hotspot_click_102
     FOR gr_alvgrid_ele1.
    SET HANDLER gr_event_handler_ele1->handle_user_command
                                    FOR gr_alvgrid_ele1.


*--functions
    CALL METHOD gr_alvgrid_ele1->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_element1[]
        it_fieldcatalog               = gt_fieldcat
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_ele1->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_ele1->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_102_2_alv                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_102_2_alv.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat.
*----Preparing field catalog.
  add_column: ' ' 'SELECTED' 'Selected'(h01) gt_fieldcat 12 ''  '' ''
                'X',
                ' ' 'DEFAULT' 'Default'(h04) gt_fieldcat 10 '' '' ''
                 'X',
                ' ' 'VAR_ELEMENT' 'Organizational Element '(h05)
                 gt_fieldcat 32 '' '' '' '',
                ' ' 'DESCRIPTION' 'Description '(h06)     gt_fieldcat 60
                '' '' '' ''.

  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      IF <fcat>-fieldname =  'SELECTED' AND
                   NOT /psyng/swcfgset-setid IS INITIAL.
*----  enable edit if setid is not initial .
        <fcat>-edit = 'X'.
        <fcat>-hotspot = 'X'.
      ENDIF.
    ELSE.
      CLEAR: <fcat>-edit , <fcat>-hotspot.
    ENDIF.
  ENDLOOP.

  IF gr_alvgrid_ele2 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_ele2
      EXPORTING
        container_name              = 'VAR_ELE'
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
    CREATE OBJECT gr_alvgrid_ele2
      EXPORTING
        i_parent          = gr_ccontainer_ele2
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure

*    PERFORM prepare_layout USING 'A' CHANGING gs_layout .
    SET HANDLER gr_event_handler_ele2->handle_toolbar FOR
gr_alvgrid_ele2.
    SET HANDLER gr_event_handler_ele2->handle_data_changed
                      FOR gr_alvgrid_ele2.
    SET HANDLER gr_event_handler_ele2->handle_hotspot_click_102_2
    FOR gr_alvgrid_ele2.
    SET HANDLER gr_event_handler_ele2->handle_user_command
                                                    FOR gr_alvgrid_ele2.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_ele2->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_element2[]
        it_fieldcatalog               = gt_fieldcat
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_ele2->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_ele2->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_103_alv                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_103_alv.
  CLEAR gs_layout.
  DATA :
    lt_filter    TYPE lvc_t_filt,
    ls_filter    TYPE lvc_s_filt,
    is_stable    TYPE lvc_s_stbl,
    lf_hide_abbr TYPE flag.
  se_config_param 'CFG_SET_HIDE_ABB' lf_hide_abbr.
  IF lf_hide_abbr = 'Y' OR lf_hide_abbr = 'X'.
    lf_hide_abbr = 'X'.
  ENDIF.

**** Overview
  PERFORM display_overview_alv.

*****  Details
  REFRESH : gt_fieldcat.
*----Preparing field catalog.
  add_column :
  ' ' 'ABB'   'ORG Area Abb.'(h07)  gt_fieldcat 12 '' '' '' '',
  'X' 'BUKRS' 'Company Code'(h08)   gt_fieldcat 12 '' '' '' '',
  ' ' 'LABEL' 'Description '(h06)   gt_fieldcat 12 '' '' '' ''.


  READ TABLE gt_output WITH KEY varbl = 'VKORG'.
  IF sy-subrc = 0.
    add_column
    'X' 'VKORG' 'Sales Org'(h09)      gt_fieldcat 12 '' '' '' ''.
  ENDIF.
  READ TABLE gt_output WITH KEY varbl = 'EKORG'.
  IF sy-subrc = 0.
    add_column
    'X' 'EKORG' 'Purchase Org'(h10)    gt_fieldcat 12 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'WERKS'.
  IF sy-subrc = 0.
    add_column
    'X' 'WERKS' 'Plant'(h11)            gt_fieldcat 6 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'GSBER'.
  IF sy-subrc = 0.
    add_column
    'X' 'GSBER' 'Business Area'(h12)    gt_fieldcat 13 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'SPART'.
  IF sy-subrc = 0.
    add_column
    'X' 'SPART' 'Division'(h33)        gt_fieldcat 12 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'VTWEG'.
  IF sy-subrc = 0.
    add_column
   'X' 'VTWEG' 'Distribution Channel'(h34)   gt_fieldcat 15 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'KKBER'.
  IF sy-subrc = 0.
    add_column
    'X' 'KKBER' 'Credit Control Area'(h35)   gt_fieldcat 15 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'KOKRS'.
  IF sy-subrc = 0.
    add_column
    'X' 'KOKRS' 'Control Area'(h36)   gt_fieldcat 10 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'VSTEL'.
  IF sy-subrc = 0.
    add_column
    'X' 'VSTEL' 'Shipping Point'(h37)   gt_fieldcat 10 '' '' '' ''.
  ENDIF.

  add_column
  '' 'TOGGLE' 'Toggle'(h13)             gt_fieldcat 6  'X' '' '' 'X'.

  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change AND
        <fcat>-fieldname =  'TOGGLE'.
*----  enable edit if setid is not initial .
      <fcat>-edit   = 'X'.
      <fcat>-hotspot = 'X'.
    ELSE.
      CLEAR: <fcat>-edit.
    ENDIF.
*--Hide the ABB column
    IF <fcat>-fieldname = 'ABB' AND lf_hide_abbr = 'X'.
      <fcat>-no_out = 'X'.
    ENDIF.
  ENDLOOP.




*--If the "Display Inactive Values" checkbox is not checked, don't
*  display the inactive values.  We apply a filter to the ALV to hide
*  them.
  DELETE lt_filter WHERE fieldname = 'TOGGLE'.
  IF g_disp_inact IS INITIAL.
    ls_filter-fieldname = 'TOGGLE'.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = ''.
    APPEND ls_filter TO lt_filter.

  ENDIF.

  IF gr_alvgrid_org IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_org
      EXPORTING
        container_name              = 'ORG_103'
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
    CREATE OBJECT gr_alvgrid_org
      EXPORTING
        i_parent          = gr_ccontainer_org
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
    SET HANDLER gr_event_handler_org->handle_toolbar1
                FOR gr_alvgrid_org.
    SET HANDLER gr_event_handler_org->handle_user_command
                FOR gr_alvgrid_org.
    SET HANDLER gr_event_handler_org->handle_hotspot_click
                FOR gr_alvgrid_org.
    SET HANDLER gr_event_handler_org->data_changed
                FOR gr_alvgrid_org.
    SET HANDLER gr_event_handler_org->handle_before_user_command
                FOR gr_alvgrid_org.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_org->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_organization[]
        it_fieldcatalog               = gt_fieldcat
        it_filter                     = lt_filter[]
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_org->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_org->set_filter_criteria
      EXPORTING
        it_filter                 = lt_filter
      EXCEPTIONS
        no_fieldcatalog_available = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.

*is_stable = 'XX'.
    CALL METHOD gr_alvgrid_org->refresh_table_display
*    exporting
*    is_stable      =   is_stable   " With Stable Rows/Columns
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_104_alv                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_104_alv.
  DATA: lt_filter TYPE lvc_t_filt,
        ls_filter TYPE lvc_s_filt.

  CLEAR gs_layout.
  REFRESH : gt_fieldcat, gt_sort, lt_filter.
  DATA : lt_groups TYPE TABLE OF lvc_s_sgrp WITH HEADER LINE.
*----Preparing field catalog.
  add_column:
  '' 'VAR_ELEMENT' 'Variable Element'(h14) gt_fieldcat 25 'X' 'X' '' '',
  '' 'SYSID'       'System'(h32)          gt_fieldcat 12 'X'  'X' '' '',
  '' 'VALUE'       'Value'(h15)           gt_fieldcat 20 'X'  '' '' '',
  '' 'VTEXT'       'Text'(ht1)           gt_fieldcat 30 ''  '' '' '',
  '' 'MODIFIED'    'Modified'(h16)        gt_fieldcat 12 ''  '' '' 'X',
  '' 'ACTIVE'      'Active'(h17)          gt_fieldcat 12 'X' '' '' 'X'.
*--In display mode, group fields
*  IF gf_dispchg <> gc_change.
*    add_column:
*     '' 'CNT'         'Count'                gt_fieldcat 12 '' '' '' ''
*.
*    set_alv_group : gt_fieldcat 'VAR_ELEMENT' '0001',
*                    gt_fieldcat 'CNT' '0001'.
*    lt_groups-sp_group = '0001'.
*    lt_groups-text     = 'Variable Element'.
*    APPEND lt_groups.
*    gs_layout-totals_bef = 'X'.
*    gs_layout-no_colexpd = 'X'.
*    DATA : ls_sort TYPE lvc_s_sort.
*    ls_sort-up     = 'X'.
*    ls_sort-spos   = '1'.
*    ls_sort-group  = 'UL'.
*    ls_sort-subtot = 'X'.
*    ls_sort-expa   = ''.
*
*    ls_sort-fieldname = 'VAR_ELEMENT'.
*    APPEND ls_sort TO gt_sort.
*
*    ADD 1 TO ls_sort-spos.
*    ls_sort-fieldname = 'SYSID'.
*    ls_sort-expa      = 'X'.
*    APPEND ls_sort TO gt_sort.
*    CLEAR :  ls_sort-group,ls_sort-subtot.
*    ADD 1 TO ls_sort-spos.
*    ls_sort-fieldname = 'VALUE'.
*    APPEND ls_sort TO gt_sort.
*  ENDIF.
*



  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change AND
      NOT /psyng/swcfgset-setid IS INITIAL.
      IF
         <fcat>-fieldname =  'VAR_ELEMENT' OR
          <fcat>-fieldname =  'SYSID' OR
          <fcat>-fieldname =  'VALUE' OR
          <fcat>-fieldname =  'ACTIVE'.

        <fcat>-edit = 'X'.
        IF <fcat>-fieldname =  'ACTIVE'.
          <fcat>-hotspot = 'X'.
        ENDIF.
      ENDIF.
    ELSE.
      CLEAR: <fcat>-edit, <fcat>-hotspot.
    ENDIF.
  ENDLOOP.

*---- 29.05.2019 change start
*----Filter for alv. By defualt there is no filter in system and element
*---- and only active values are displayed

  DELETE lt_filter WHERE fieldname = 'VAR_ELEMENT' OR
                         fieldname = 'SYSID'
                         OR fieldname = 'ACTIVE'.
  PERFORM create_filter_varbl_alv  TABLES lt_filter.
*----end

  IF gr_alvgrid_var IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_var
      EXPORTING
        container_name              = 'VAR_104'
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
    CREATE OBJECT gr_alvgrid_var
      EXPORTING
        i_parent          = gr_ccontainer_var
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
*    PERFORM prepare_layout USING 'A' CHANGING gs_layout .
    SET HANDLER gr_event_handler_var->handle_user_command
                                          FOR gr_alvgrid_var.
    SET HANDLER gr_event_handler_var->handle_toolbar2 FOR
      gr_alvgrid_var.
    SET HANDLER gr_event_handler_var->handle_on_f4 FOR gr_alvgrid_var.
    SET HANDLER gr_event_handler_var->handle_hotspot_click_104
                                            FOR gr_alvgrid_var.
    SET HANDLER gr_event_handler_var->data_changed FOR
    gr_alvgrid_var.
    SET HANDLER gr_event_handler_var->handle_before_user_command1
    FOR gr_alvgrid_var.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_var->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
*       it_special_groups             = lt_groups[]
      CHANGING
        it_outtab                     = gt_variable1[]
        it_fieldcatalog               = gt_fieldcat
        it_filter                     = lt_filter[]
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.


  ELSE .
    CALL METHOD gr_alvgrid_var->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
*       it_special_groups             = lt_groups[]
      CHANGING
        it_outtab                     = gt_variable1[]
        it_fieldcatalog               = gt_fieldcat
        it_filter                     = lt_filter[]
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.

*    CALL METHOD gr_alvgrid_var->set_frontend_fieldcatalog
*      EXPORTING
*        it_fieldcatalog = gt_fieldcat.
*
*    if gf_dispchg = gc_change.
**
*      CALL METHOD gr_alvgrid_org->set_filter_criteria
*      EXPORTING
*        it_filter                 = lt_filter
*      EXCEPTIONS
*        NO_FIELDCATALOG_AVAILABLE = 1
*        others                    = 2.
*
*    CALL METHOD gr_alvgrid_var->refresh_table_display.
*     ENDIF.
  ENDIF .

*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE,
        wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.

  wa_f4-fieldname = 'VAR_ELEMENT'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .
  wa_f4-fieldname = 'SYSID'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4 .

  CALL METHOD gr_alvgrid_var->register_f4_for_fields
    EXPORTING
      it_f4 = lt_f4[].
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_toolbar                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar  USING
       i_object TYPE REF TO cl_alv_event_toolbar_set i_interactive.
  DELETE i_object->mt_toolbar WHERE NOT function IS INITIAL.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_toolbar1                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar1  USING
       i_object TYPE REF TO cl_alv_event_toolbar_set i_interactive.
  DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
*--  remove other non relevant buttons from tool bar
  DELETE i_object->mt_toolbar WHERE function = '&GRAPH'
                                OR function = '&PRINT_BACK'
                                OR function = '&MB_SUBTOT'
                                OR function = '&MB_SUM'
                                OR function = '&MB_VIEW'.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_toolbar2                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar2  USING
       i_object TYPE REF TO cl_alv_event_toolbar_set i_interactive.

  DATA: ls_toolbar  TYPE stb_button.
  CLEAR ls_toolbar.

*  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
*  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 1.
  IF gf_dispchg = gc_display.
    DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
  ENDIF.
  DELETE i_object->mt_toolbar WHERE function = '&LOCAL&CUT'
                             OR     function = '&LOCAL&DELETE_ROW'
                             OR     function = '&GRAPH'
                                OR function = '&PRINT_BACK'
                                OR function = '&MB_SUBTOT'
                                OR function = '&MB_SUM'
                                OR function = '&MB_VIEW'.
*                                or function is INITIAL.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM Create_action                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_DYNNR                                                       *
*---------------------------------------------------------------------*
FORM create_setid.
  DATA :l_num_sys TYPE i.
  CLEAR: g_setid, /psyng/swcfgset-description.
  CALL FUNCTION '/PSYNG/SW_CFG_GET_NEW_SETID'
    IMPORTING
      setid = g_setid.
  /psyng/swcfgset-setid = g_setid.
  /psyng/swcfgset-create_date = sy-datum.
  /psyng/swcfgset-create_time = sy-uzeit.
  /psyng/swcfgset-create_user = g_current_user."sy-uname. C0700
  /psyng/swcfgset-change_date = sy-datum.
  /psyng/swcfgset-change_time = sy-uzeit.
  /psyng/swcfgset-change_user = g_current_user."sy-uname. C0700

*--Set default variable elements rule version
  se_config_param 'DFLT_VAREL_VERSION' /psyng/swcfgset-varel_vrsio.
*--Set default SOD version
  CALL FUNCTION '/PSYNG/SW_034'
    IMPORTING
      e_vrsio = /psyng/swsodvers-vrsio.
  /psyng/swsodvers-vrsio = g_vrsio.

  gf_set_loaded = 'X'.
  CLEAR : gf_ve_loaded ,
          gf_sys_loaded,
          gf_ao_loaded,
          gf_vs_loaded.
*          gf_element_loaded.
  g_loaded_set = g_setid.
  REFRESH : gt_output, gt_organization, gt_organization1,gt_systems,
            gt_variable1.
  PERFORM get_system_against_setid.
  gf_sys_loaded = 'X'.
*--If there's just one system, select it by default
  DESCRIBE TABLE gt_systems LINES l_num_sys.
  IF l_num_sys = 1.
    gt_systems-sel = 'X'.
    MODIFY gt_systems TRANSPORTING sel WHERE sel <> 'X'.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_existing_sys                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_existing_sys.
  DATA: lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.
  REFRESH: gt_systems, lt_sw_rfcdes.
  CLEAR: gt_systems, lt_sw_rfcdes.
  SELECT * FROM /psyng/sw_rfcdes INTO CORRESPONDING FIELDS OF TABLE
  lt_sw_rfcdes.
  PERFORM update_sysid TABLES lt_sw_rfcdes.

  LOOP AT lt_sw_rfcdes.
    MOVE-CORRESPONDING lt_sw_rfcdes TO gt_systems.
    gt_systems-sysid = lt_sw_rfcdes-systid.
    READ TABLE gt_systems WITH KEY sysid = lt_sw_rfcdes-systid.
    IF sy-subrc <> 0.
      APPEND gt_systems.
    ENDIF.
  ENDLOOP.

  IF lt_sw_rfcdes[] IS INITIAL.
    gt_systems-sel = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO gt_systems-sysid.
    APPEND gt_systems.
  ENDIF.
  gf_sys_loaded = 'X'.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_existing_config_set_data                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_existing_config_set_data.
  DATA lt_swcfgset TYPE /psyng/swcfgset.
  CLEAR lt_swcfgset.
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    SELECT SINGLE * FROM /psyng/swcfgset INTO
    lt_swcfgset WHERE setid = /psyng/swcfgset-setid.
    IF NOT lt_swcfgset IS INITIAL.
      /psyng/swcfgset-create_user       = lt_swcfgset-create_user.
      /psyng/swcfgset-create_date       = lt_swcfgset-create_date.
      /psyng/swcfgset-create_time       = lt_swcfgset-create_time.
      /psyng/swcfgset-change_user       = lt_swcfgset-change_user.
      /psyng/swcfgset-change_date       = lt_swcfgset-change_date.
      /psyng/swcfgset-change_time       = lt_swcfgset-change_time.
      /psyng/swsodvers-vrsio            = lt_swcfgset-sodvrsio.
      IF gf_data_change IS INITIAL.
        MOVE-CORRESPONDING lt_swcfgset TO /psyng/swcfgset.
*        /psyng/swcfgset-description       = lt_swcfgset-description.
      ENDIF.
      CLEAR : gf_ve_loaded,
              gf_sys_loaded,
              gf_ao_loaded,
              gf_vs_loaded.

      gf_set_loaded = 'X'.
      g_loaded_set = /psyng/swcfgset-setid.
*--Load the selected/selectable elements
*  ---Load Selected Elements
      PERFORM load_selected_elements.
*  ---load varable rule
      PERFORM load_rules_for_selection.
*  ---load org rule
      PERFORM load_rules_for_org_sel.
    ENDIF.
  ENDIF.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM load_data_103                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_data_103.
  IF gf_ao_loaded IS INITIAL.
*---set previous config id
*--- if data changed then no need to refresh
    IF NOT /psyng/swcfgset IS INITIAL.

      IF gv_prev_setid = /psyng/swcfgset-setid AND
      gv_inactive_data_change IS INITIAL AND gv_org_analysis IS INITIAL.
        CLEAR gv_prev_setid.
        REFRESH gt_organization.
      ENDIF.

      IF gv_prev_setid IS INITIAL.
        gv_prev_setid = /psyng/swcfgset-setid.
      ENDIF.

      IF gt_organization[] IS INITIAL AND gv_org_analysis IS INITIAL.
        PERFORM load_103_existing_data.
      ENDIF.

      IF /psyng/swcfgset-setid <> gv_prev_setid AND
       gv_inactive_data_change IS INITIAL AND
    NOT /psyng/swcfgset-setid IS INITIAL AND gv_org_analysis IS INITIAL.
        REFRESH gt_organization.
        PERFORM load_103_existing_data.
      ENDIF.
      CLEAR: gv_org_analysis,  gv_inactive_data_change.
    ELSE.
      REFRESH: gt_organization, gt_organization1.
      CLEAR gt_organization1.
    ENDIF.
  ELSE.
    PERFORM calculate_org_values_occurance.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_overview_alv                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_overview_alv.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat.
  READ TABLE gt_organization1 INDEX 1.
  add_column:
     'X' 'BUKRS' 'Company Code'(h08)    gt_fieldcat 12 '' '' '' ''.

  READ TABLE gt_output WITH KEY varbl = 'VKORG'.
  IF sy-subrc = 0.
    add_column
    'X' 'VKORG' 'Sales Org'(h09)       gt_fieldcat 10 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'EKORG'.
  IF sy-subrc = 0.
    add_column
    'X' 'EKORG' 'Purchase Org'(h10)    gt_fieldcat 12 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'WERKS'.
  IF sy-subrc = 0.
    add_column
    'X' 'WERKS' 'Plant'(h11)           gt_fieldcat 6 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'GSBER'.
  IF sy-subrc = 0.
    add_column
    'X' 'GSBER' 'Business Area'(h12)   gt_fieldcat 13 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'SPART'.
  IF sy-subrc = 0.
    add_column
      'X' 'SPART' 'Division'(h33)   gt_fieldcat 20 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'VTWEG'.
  IF sy-subrc = 0.
    add_column
   'X' 'VTWEG' 'Distribution Channel'(h34)   gt_fieldcat 20 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'KKBER'.
  IF sy-subrc = 0.
    add_column
    'X' 'KKBER' 'Credit Control Area'(h35)   gt_fieldcat 20 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'KOKRS'.
  IF sy-subrc = 0.
    add_column
      'X' 'KOKRS' 'Control Area'(h36)   gt_fieldcat 15 '' '' '' ''.
  ENDIF.

  READ TABLE gt_output WITH KEY varbl = 'VSTEL'.
  IF sy-subrc = 0.
    add_column
      'X' 'VSTEL' 'Shipping Point'(h37)   gt_fieldcat 15 '' '' '' ''.
  ENDIF.

  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    CLEAR: <fcat>-edit.
  ENDLOOP.

  IF gr_alvgrid_org1 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_org1
      EXPORTING
        container_name              = 'ORG_103_02'
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
    CREATE OBJECT gr_alvgrid_org1
      EXPORTING
        i_parent          = gr_ccontainer_org1
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
  SET HANDLER gr_event_handler_org1->handle_toolbar FOR gr_alvgrid_org1.
    SET HANDLER gr_event_handler_org1->handle_hotspot_click_dtl
                 FOR gr_alvgrid_org1.

    gs_layout-ctab_fname  = 'CELLSTYLES'.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_org1->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_organization1[]
        it_fieldcatalog               = gt_fieldcat
*       it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_org1->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_org1->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .
ENDFORM.


*---------------------------------------------------------------------*
*       FORM publish_config_set                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM publish_config_set.
  DATA : lf_continue  TYPE flag,
         l_setid_temp TYPE /psyng/seconfid.
  PERFORM authorization_check
    USING /psyng/swcfgset-setid 'P'
    CHANGING lf_continue.

  DATA ls_config TYPE /psyng/se_config_param.

  IF NOT /psyng/swcfgset-setid IS INITIAL.

*--- allow to publish when Atleast description should be maintain
    IF /psyng/swcfgset-description IS INITIAL.
      MESSAGE s002(/psyng/sw) WITH
      'Please maintain description of Configset'(015).
    ELSE.

*--- Save configset if not saved yet
      SELECT SINGLE setid FROM /psyng/swcfgset INTO  l_setid_temp
        WHERE setid =  /psyng/swcfgset-setid.
      IF sy-subrc <> 0
        OR NOT gt_organization[] IS INITIAL OR
        NOT gt_variable1[] IS INITIAL .
        PERFORM save_data.
        CLEAR l_setid_temp.
      ENDIF.

*****update publilsh check box
      UPDATE /psyng/swcfgset SET published = 'X'
              WHERE setid = /psyng/swcfgset-setid.

      IF sy-subrc = 0.
        g_published = 'X'.
        MESSAGE s002(/psyng/sw) WITH text-p01.

        CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
          EXPORTING
            i_parameter = 'CFG_SET_PUBLISHEVENT'
          IMPORTING
            e_config    = ls_config.

***   Raise event if configured
        CHECK NOT ls_config-value IS INITIAL.
        CALL FUNCTION 'BP_EVENT_RAISE'
          EXPORTING
            eventid                = ls_config-value
            eventparm              = /psyng/swcfgset-setid
          EXCEPTIONS
            bad_eventid            = 1
            eventid_does_not_exist = 2
            eventid_missing        = 3
            raise_failed           = 4
            OTHERS                 = 5.
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE i002(/psyng/sw) WITH 'Event'(e00)
                                           ls_config-value
                                           'does not exist.'(e02)
                                           'Create in SM62'(e03).
            WHEN OTHERS.
              MESSAGE i002(/psyng/sw) WITH 'Event'(e00)
                                           ls_config-value
                                           'creation failed.'(e04).
          ENDCASE.
        ELSE.
*        MESSAGE s002(/psyng/sw) WITH 'Event'(e00) ls_config-value
*                                     'was raised'(002).
          MESSAGE s002(/psyng/sw) WITH text-p01.
        ENDIF.
      ELSE.
        MESSAGE s002(/psyng/sw) WITH text-e01.
      ENDIF.
*--Reload the set in display mode
      CLEAR :
        gf_set_loaded,
        gf_data_change,
        gf_screen_change.
      gf_dispchg = gc_display.
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_system_against_setid                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_system_against_setid.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  PERFORM update_sysid TABLES lt_sw_rfcdes.
  SELECT * FROM /psyng/swcfgsys INTO TABLE
      lt_swcfgsys WHERE setid = /psyng/swcfgset-setid.

****show alv systems for selected setid
  REFRESH : gt_systems.
  LOOP AT lt_sw_rfcdes.
    READ TABLE lt_swcfgsys WITH KEY sysid = lt_sw_rfcdes-systid.
    IF sy-subrc = 0.
      gt_systems-sel = 'X'.
    ELSE.
      CLEAR gt_systems-sel.
    ENDIF.
    MOVE-CORRESPONDING lt_sw_rfcdes TO gt_systems.
    gt_systems-sysid = lt_sw_rfcdes-systid.
    APPEND gt_systems.
  ENDLOOP.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_configset_header                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_configset_header.
****    Insert into config set
  DATA lt_swcfgset1 TYPE /psyng/swcfgset.
  SELECT SINGLE * FROM /psyng/swcfgset INTO  lt_swcfgset1
  WHERE setid =  /psyng/swcfgset-setid.
  IF sy-subrc = 0.
    gs_swcfgset-change_user = g_current_user."sy-uname. C0700
    gs_swcfgset-change_date = sy-datum.
    gs_swcfgset-change_time = sy-uzeit.
    gs_swcfgset-setid = /psyng/swcfgset-setid.
    gs_swcfgset-create_user = lt_swcfgset1-create_user.
    gs_swcfgset-create_date = lt_swcfgset1-create_date.
    gs_swcfgset-create_time = lt_swcfgset1-create_time.

  ELSE.
    gs_swcfgset-create_user = g_current_user."sy-uname. C0700
    gs_swcfgset-create_date = sy-datum.
    gs_swcfgset-create_time = sy-uzeit.
    gs_swcfgset-setid = g_setid.
  ENDIF.
  gs_swcfgset-sodvrsio    = /psyng/swsodvers-vrsio.
  gs_swcfgset-description = /psyng/swcfgset-description.

**  element selection variable vrsio
  gs_swcfgset-varel_vrsio = /psyng/swcfgset-varel_vrsio.
  MODIFY /psyng/swcfgset FROM gs_swcfgset.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM parse_sod_matrix                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM parse_sod_matrix.
  DATA :
    lt_ao_list TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
    lt_ve_list TYPE TABLE OF /psyng/sw_ve_list WITH HEADER LINE,
    l_tabix    TYPE sy-tabix.

  REFRESH:lt_ao_list, lt_ve_list.
***org element
  CALL FUNCTION '/PSYNG/SW_AO_002'
    EXPORTING
      i_sodvrsio       = /psyng/swsodvers-vrsio
*            don't pass set, we only want values based on SOD matrix
*     i_setid          = /psyng/swcfgset-setid
    TABLES
      et_list          = lt_ao_list
    EXCEPTIONS
      version_no_exist = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
*--Sod Matrix version doesn't exist
    MESSAGE i020(/psyng/sw) WITH
      'SOD Matrix Version'(v01)
      /psyng/swsodvers-vrsio.
  ELSE.

    LOOP AT lt_ao_list.
      READ TABLE gt_element1 WITH KEY varbl = lt_ao_list-field.
      IF sy-subrc = 0.
        l_tabix = sy-tabix.
        gt_element1-selected = lt_ao_list-selected.
        READ TABLE gt_selections WITH KEY type = 'ORG'
                                          varbl = gt_element1-varbl.
        IF sy-subrc = 0 AND sy-ucomm <> 'PARSE_SOD'.
          gt_element1-selected = gt_selections-sel.
        ENDIF.
        gt_element1-default = lt_ao_list-default.
        MODIFY gt_element1 INDEX l_tabix TRANSPORTING selected default.
      ENDIF.
    ENDLOOP.

*---variable element
*----selected field already implemented in FM
    REFRESH gt_element2.
    CALL FUNCTION '/PSYNG/SW_VE_LIST'
      EXPORTING
        i_varel_vrsio          = /psyng/swcfgset-varel_vrsio
        i_sodvrsio             = /psyng/swsodvers-vrsio
        if_parse_matrix        = 'X'
*            don't pass set, we only want values based on SOD matrix
*       i_setid                = /psyng/swcfgset-setid
      TABLES
        et_variable_elements   = lt_ve_list
      EXCEPTIONS
        rules_version_no_exist = 1
        OTHERS                 = 2.
    IF sy-subrc <> 0.
*--Sod Matrix version doesn't exist
      MESSAGE i020(/psyng/sw) WITH
        'Variable Element Rules Version'(v01)
        /psyng/swcfgset-varel_vrsio.

    ELSE.


      LOOP AT lt_ve_list.
        MOVE-CORRESPONDING lt_ve_list TO gt_element2.
        READ TABLE gt_selections WITH KEY type = 'VE'
                                        varbl = gt_element2-var_element.
        IF sy-subrc = 0 AND sy-ucomm <> 'PARSE_SOD'.
          gt_element2-selected = gt_selections-sel.
        ENDIF.
        APPEND gt_element2.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM delete_configset_header                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM delete_configset_header.
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    DELETE FROM /psyng/swcfgset WHERE setid = /psyng/swcfgset-setid.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM Load_rules_for_selection                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_rules_for_selection.
  DATA : lt_ve_list TYPE TABLE OF /psyng/sw_ve_list WITH HEADER LINE.
  CALL FUNCTION '/PSYNG/SW_VE_LIST'
    EXPORTING
      i_varel_vrsio          = /psyng/swcfgset-varel_vrsio
      i_sodvrsio             = /psyng/swsodvers-vrsio
      i_setid                = /psyng/swcfgset-setid
    TABLES
      et_variable_elements   = lt_ve_list
    EXCEPTIONS
      rules_version_no_exist = 1
      OTHERS                 = 2.
  IF sy-subrc <> 0 AND NOT /psyng/swcfgset-setid
    IS INITIAL.
*--Sod Matrix version doesn't exist
    MESSAGE i020(/psyng/sw) WITH
      'Variable Element Rules Version'(v01)
      /psyng/swcfgset-varel_vrsio.

  ELSE.
    REFRESH : gt_element2.
    LOOP AT lt_ve_list.
      MOVE-CORRESPONDING lt_ve_list TO gt_element2.
      READ TABLE gt_selections WITH KEY type = 'VE'
                                        varbl = gt_element2-var_element.
      IF sy-subrc = 0.
        gt_element2-selected = gt_selections-sel.
      ENDIF.
      APPEND gt_element2.
    ENDLOOP.
    SORT gt_element2 BY default selected var_element.

*---if setid is blank, defaul & selected value should not checked
    IF /psyng/swcfgset-setid IS INITIAL.
      gt_element2-selected = ' '.
      gt_element2-default =  ' '.
      MODIFY gt_element2 TRANSPORTING selected default
      WHERE  NOT var_element IS INITIAL.
    ENDIF.

  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_alv_org_detail                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv_org_detail.

  CLEAR gs_layout.
  REFRESH gt_organization2.
**** detail data
  DATA :
    lt_bukrs         LIKE TABLE OF gt_output WITH HEADER LINE,
    l_cnt            TYPE i,
    l_field          TYPE string,
    l_abb            TYPE /psyng/dorg_abb,
    lt_filter        TYPE lvc_t_filt,
    ls_filter        TYPE lvc_s_filt,
    lf_hide_abbr_dtl TYPE flag.

*---get parameter value to hide abb field
  se_config_param 'CFG_SET_HIDE_ABB' lf_hide_abbr_dtl.
  IF lf_hide_abbr_dtl = 'Y' OR lf_hide_abbr_dtl = 'X'.
    lf_hide_abbr_dtl = 'X'.
  ENDIF.

*--- if click on overview field
  IF g_hotspot_click = 'X'.
    lt_bukrs[] = gt_output_dtl[].
  ELSE.
    lt_bukrs[] = gt_output[].
  ENDIF.
  SORT lt_bukrs BY abb.
*  CLEAR g_hotspot_click.

  LOOP AT lt_bukrs.
    READ TABLE gt_output WITH KEY varbl = 'BUKRS'
               abb   = lt_bukrs-abb.
    gt_organization2-country = lt_bukrs-abb.
    gt_organization2-bukrs = gt_output-abb.
    gt_organization2-desc = gt_output-label.
    gt_organization2-varbl = lt_bukrs-varbl  .

    CASE lt_bukrs-varbl.
      WHEN 'BUKRS'.
        gt_organization2-field = 'Company Code'.
      WHEN 'EKORG'.
        gt_organization2-field = 'Purchasing Organization'.
      WHEN 'WERKS'.
        gt_organization2-field = 'Plant'.
      WHEN 'VKORG'.
        gt_organization2-field = 'Sales Organization'.
      WHEN 'GSBER'.
        gt_organization2-field = 'Business Area'.
      WHEN 'SPART'.
        gt_organization2-field = 'Division'.
      WHEN 'VTWEG'.
        gt_organization2-field = 'Distribution Channel'.
      WHEN 'KKBER'.
        gt_organization2-field = 'Credit Control Area'  .
      WHEN 'KOKRS'.
        gt_organization2-field = 'Control Area'.
      WHEN 'VSTEL'.
        gt_organization2-field = 'Shipping Point'.
    ENDCASE.
    gt_organization2-value = lt_bukrs-low .
    gt_organization2-sysid = lt_bukrs-sysid .
    gt_organization2-label = lt_bukrs-label .
    gt_organization2-check = lt_bukrs-check .
    APPEND gt_organization2.
  ENDLOOP.


  DATA: ls_sort TYPE lvc_s_sort.
  REFRESH : gt_fieldcat, gt_sort.
*----Preparing field catalog.
  add_column:
  ' ' 'COUNTRY' 'Org. Area Abb'(h24)   gt_fieldcat 15 '' '' '' '',
  ' ' 'VARBL' 'Field'(h25)             gt_fieldcat 10 '' '' '' '',
  ' ' 'FIELD' 'Field Name'(h26)        gt_fieldcat 10 '' '' '' '',
  ' ' 'SYSID' 'System'(h32)            gt_fieldcat 6 '' '' '' '',
  ' ' 'VALUE' 'Value'(h27)             gt_fieldcat 6  '' '' '' '',
  ' ' 'LABEL' 'Value Description'(h28) gt_fieldcat 32 '' '' '' '',
  ' ' 'BUKRS' 'Company Code'(h29)      gt_fieldcat 20 '' '' '' '',
  ' ' 'DESC' 'Description'(h30)        gt_fieldcat 30 '' '' '' '',
  'X' 'CHECK' 'Toggle'(h31)            gt_fieldcat 8  '' '' '' 'X'.

  LOOP AT gt_fieldcat ASSIGNING <fcat>.
    IF <fcat>-fieldname =  'CHECK' AND gf_dispchg = gc_change.
      <fcat>-hotspot = 'X'.
      <fcat>-edit = 'X'.
    ELSE.
      CLEAR: <fcat>-edit, <fcat>-hotspot.
    ENDIF.

*--Hide the ABB column
    IF <fcat>-fieldname = 'COUNTRY' AND lf_hide_abbr_dtl = 'X'.
      <fcat>-no_out = 'X'.
    ENDIF.
  ENDLOOP.

*--Create a sort table
  IF gt_sort[] IS INITIAL.
    ls_sort-up   = 'X'.
    ls_sort-spos = '1'.
    ls_sort-fieldname = 'COUNTRY'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'VARBL'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'FIELD'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'SYSID'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'VALUE'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'LABEL'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'BUKRS'.
    APPEND ls_sort TO gt_sort.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'DESC'.
    APPEND ls_sort TO gt_sort.

  ENDIF.
*--If the "Display Inactive Values" checkbox is not checked, don't
*  display the inactive values.  We apply a filter to the ALV to hide
*  them.
  REFRESH lt_filter.

  IF g_disp_inact IS INITIAL.
    ls_filter-fieldname = 'CHECK'.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = ''.
    APPEND ls_filter TO lt_filter.

  ENDIF.

  IF gr_alvgrid_org2 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer_org2
      EXPORTING
        container_name              = 'ORG_ALV_DTL'
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
    CREATE OBJECT gr_alvgrid_org2
      EXPORTING
        i_parent          = gr_ccontainer_org2
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Preparing layout structure
*    PERFORM prepare_layout USING 'A' CHANGING gs_layout .
    SET HANDLER gr_event_handler_org2->handle_toolbar1
                FOR gr_alvgrid_org2.
    SET HANDLER gr_event_handler_org2->handle_hotspot_click_dtl2
                FOR  gr_alvgrid_org2.
*.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid_org2->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_organization2[]
        it_fieldcatalog               = gt_fieldcat
        it_sort                       = gt_sort
        it_filter                     = lt_filter[]
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE .
    CALL METHOD gr_alvgrid_org2->set_frontend_fieldcatalog
      EXPORTING
        it_fieldcatalog = gt_fieldcat.

    CALL METHOD gr_alvgrid_org2->set_filter_criteria
      EXPORTING
        it_filter                 = lt_filter
      EXCEPTIONS
        no_fieldcatalog_available = 1
        OTHERS                    = 2.
    IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


    CALL METHOD gr_alvgrid_org2->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF .

ENDFORM.

*---------------------------------------------------------------------*
*       FORM calculate_org_values_occurance                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM calculate_org_values_occurance.
  DATA: lt_bukrs       LIKE TABLE OF gt_output WITH HEADER LINE,
        l_cnt_disp(10) TYPE c,
        l_cnt_orig(10) TYPE c,
        l_cnt(10)      TYPE c,
        l_txt(50)      TYPE c,
        lt_cellstyles  TYPE lvc_t_scol,
        ls_cellstyle   TYPE lvc_s_scol,
        lt_temp_count  LIKE TABLE OF gt_output WITH HEADER LINE,
        l_total        TYPE i,
        l_active       TYPE i,
        l_total_c(10)  TYPE c,
        l_active_c(10) TYPE c.


  lt_bukrs[] = gt_output[].
  DELETE lt_bukrs WHERE varbl <> 'BUKRS'.
  SORT lt_bukrs BY abb.
  DELETE ADJACENT DUPLICATES FROM lt_bukrs COMPARING abb.
  gt_output_temp[] = gt_output[].

*  --Load the data into the summary table
***-- Overview alv calculation to display
  REFRESH gt_organization1.
  IF gt_organization1[] IS INITIAL.
****company code
    count_field :
      'BUKRS'  gt_organization1-bukrs,
      'VKORG'  gt_organization1-vkorg,
      'EKORG'  gt_organization1-ekorg,
      'WERKS'  gt_organization1-werks,
      'GSBER'  gt_organization1-gsber,
      'SPART'  gt_organization1-spart,
      'VTWEG'  gt_organization1-vtweg,
      'KKBER'  gt_organization1-kkber,
      'KOKRS'  gt_organization1-kokrs,
      'VSTEL'  gt_organization1-vstel.
    APPEND gt_organization1.
  ENDIF.



  REFRESH gt_organization.

*--Add record per  company codes.
  lt_bukrs[] = gt_output[].
  DELETE lt_bukrs WHERE varbl <> 'BUKRS'.
  SORT lt_bukrs BY abb.
  DELETE ADJACENT DUPLICATES FROM lt_bukrs COMPARING abb.
  DATA : lf_unckeched TYPE flag,
         lf_manual    TYPE flag,
         lf_init      TYPE flag.
  lf_init = 'X'.
  LOOP AT lt_bukrs WHERE varbl = 'BUKRS'.
    CLEAR gt_organization.
    MOVE-CORRESPONDING lt_bukrs TO gt_organization.
    gt_organization-bukrs = lt_bukrs-low.
    gt_organization-label = lt_bukrs-label.
    count_field_company :
*     'BUKRS'  gt_organization-bukrs gt_organization-bukrs,
    'VKORG'  gt_organization-bukrs gt_organization-vkorg lf_init,
    'EKORG'  gt_organization-bukrs gt_organization-ekorg '',"lf_init,
    'WERKS'  gt_organization-bukrs gt_organization-werks '',"lf_init,
    'GSBER'  gt_organization-bukrs gt_organization-gsber '',"lf_init,
    'SPART'  gt_organization-bukrs gt_organization-spart '',"lf_init,
    'VTWEG'  gt_organization-bukrs gt_organization-vtweg '',"lf_init,
    'KKBER'  gt_organization-bukrs gt_organization-kkber '',"lf_init,
    'KOKRS'  gt_organization-bukrs gt_organization-kokrs '',"lf_init,
    'VSTEL'  gt_organization-bukrs gt_organization-vstel ''."lf_init.

    highlight_org_sum gt_organization-bukrs :
      'BUKRS', 'VKORG', 'EKORG','WERKS', 'GSBER', 'SPART', 'VTWEG',
      'KKBER','KOKRS', 'VSTEL'  .
    CLEAR lf_init.



*--Check if the company code is completely disabled
    CLEAR gt_organization-selected.
    READ TABLE gt_output
      WITH KEY
*      Not sure: active field should always check by bukrs
*      need discussion
      varbl = 'BUKRS'
      abb = gt_organization-bukrs.
    IF sy-subrc = 0.
      gt_organization-toggle   =  gt_output-check.
    ENDIF.
    APPEND gt_organization.
  ENDLOOP.

  IF NOT gr_alvgrid_org1 IS INITIAL.
    CALL METHOD gr_alvgrid_org1->refresh_table_display
      EXCEPTIONS
        finished = 1
        OTHERS   = 2.

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM popup_confirm                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_ANS                                                         *
*---------------------------------------------------------------------*
FORM popup_confirm CHANGING l_ans TYPE flag.
  DATA : l_ques   TYPE string,
         l_numorg TYPE i,
         l_numvar TYPE i.
*--Check if any data is stored for this set
  SELECT SINGLE COUNT( * ) INTO l_numorg FROM /psyng/swcfgoe
  WHERE setid = /psyng/swcfgset-setid.
  SELECT SINGLE COUNT( * ) INTO l_numvar FROM /psyng/swcfgve
  WHERE setid = /psyng/swcfgset-setid.

  IF l_numvar > 0 OR l_numorg > 0.
    l_ques =
    'This will overwrite all currently stored values for this set'(q10).
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Analyze Org Elements'(q12)
        text_question         = l_ques
        text_button_1         = 'Yes'(q13)
        icon_button_1         = '@0V@'
        text_button_2         = 'No'(q14)
        icon_button_2         = '@2O@'
        default_button        = '2'
        display_cancel_button = 'X'
      IMPORTING
        answer                = l_ans
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ELSE.
    l_ans = 1.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM check_publish                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM check_publish.
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    SELECT SINGLE published INTO (g_published)
    FROM /psyng/swcfgset WHERE
                      setid = /psyng/swcfgset-setid.
    /psyng/swcfgset-published = g_published.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_user_command_0101                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_UCOMM                                                       *
*---------------------------------------------------------------------*
FORM handle_user_command_0101 USING l_ucomm LIKE sy-ucomm.
  CALL METHOD gr_alvgrid_sys->check_changed_data.
  REFRESH gt_sel_systems.
***  collect all selected systems
  LOOP AT gt_systems WHERE sel = 'X'.
    gt_sel_systems-setid = /psyng/swcfgset-setid.
    gt_sel_systems-sysid = gt_systems-sysid.
    APPEND gt_sel_systems.
  ENDLOOP.
  SORT gt_sel_systems BY sysid.
  DELETE ADJACENT DUPLICATES FROM gt_sel_systems COMPARING sysid.

  CASE l_ucomm.
    WHEN 'DELETE'.


    WHEN 'SAVE'.
      REFRESH lt_swcfgsys.
  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_user_command_0102                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_UCOMM                                                       *
*---------------------------------------------------------------------*
FORM handle_user_command_0102 USING l_ucomm LIKE sy-ucomm.

****Collect org elements
  CALL METHOD gr_alvgrid_ele1->check_changed_data.
  REFRESH: gt_sel_ao_list, r_varel.
  LOOP AT gt_element1 WHERE selected = 'X'.
    gt_sel_ao_list-field = gt_element1-varbl.
    gt_sel_ao_list-selected = 'X'.
    APPEND gt_sel_ao_list.
  ENDLOOP.

****Collect variable elements
  CALL METHOD gr_alvgrid_ele2->check_changed_data.

  LOOP AT gt_element2 WHERE selected = 'X'.
    r_varel-sign = 'I'.
    r_varel-option = 'EQ'.
    r_varel-low = gt_element2-var_element.
    APPEND r_varel.
  ENDLOOP.


  DATA l_ans1(1) TYPE c.
  IF sy-ucomm = 'PARSE_SOD'.
    PERFORM parse_sod_matrix.
    g_sod_parse = 'X'.
    CLEAR gf_vs_loaded.
  ELSEIF sy-ucomm = 'ANA_RULES'.

    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/sw_varvr
                       WHERE varel_vrsio = /psyng/swcfgset-varel_vrsio.
    IF sy-subrc = 0.
      CLEAR l_ans1.
      PERFORM popup_confirm CHANGING l_ans1.
      IF l_ans1 = '1'.
        PERFORM analyse_oganizational_values.
        PERFORM analyse_variable_values.

*---Assign org and veriable analysis flag
        gv_conbine_analysis = 'X'.
        gv_org_analysis = gv_conbine_analysis.
        gv_variable_analysis = gv_conbine_analysis.
        MESSAGE s002(/psyng/sw) WITH text-008.
      ELSE.
        CLEAR gf_vs_loaded.
      ENDIF.
    ELSE.
      MESSAGE s351(/psyng/sw) WITH /psyng/swcfgset-varel_vrsio.
    ENDIF.
  ENDIF.
  CLEAR sy-ucomm.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_user_command_0103                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_UCOMM                                                       *
*---------------------------------------------------------------------*
FORM handle_user_command_0103 USING l_ucomm LIKE sy-ucomm.
  DATA:lt_output           LIKE TABLE OF gt_output WITH HEADER LINE,
   lt_analyze_elements TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
   lt_org_values       TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
lt_texts            TYPE TABLE OF /psyng/sw_org_values_text WITH HEADER LINE,
l_ans(1)            TYPE c,
l_setid             TYPE /psyng/swcfgset-setid,
l_number_of_lines   TYPE i.

  CLEAR l_setid.

  CALL METHOD gr_alvgrid_org->check_changed_data.

  CASE sy-ucomm.
    WHEN 'ANA_ORG'.
      CLEAR l_ans.
      PERFORM popup_confirm CHANGING l_ans.
      IF l_ans = '1'.
        PERFORM analyse_oganizational_values.
        gv_org_analysis = 'X'.
      ENDIF.
    WHEN 'ALL_DTL'.
      g_disp_inact_all_dtl = 'X'.
      CLEAR g_hotspot_click.
      IF g_disp_inact = 'X'.
        CALL SCREEN '0105'.
      ELSE.
        gt_output_inactive[] = gt_output[].
        DELETE gt_output WHERE check <> 'X'.
        CALL SCREEN '0105'.
        gt_output[] = gt_output_inactive[].
      ENDIF.
    WHEN  'INACTIVE'.
      REFRESH: gt_organization1, gt_organization.
      PERFORM calculate_org_values_occurance.
      PERFORM display_103_alv.
      IF g_disp_inact = 'X'.
        MESSAGE s002(/psyng/sw) WITH
        'Data Loaded, for both Active and Inactive Values'(006).
      ELSE.
        MESSAGE s002(/psyng/sw) WITH 'Active Values Only'(007).
      ENDIF.
  ENDCASE.
  CLEAR sy-ucomm.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_user_command_0104                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_UCOMM                                                       *
*---------------------------------------------------------------------*
FORM handle_user_command_0104 USING l_ucomm LIKE sy-ucomm.
  DATA: l_ans(1) TYPE c.
  CALL METHOD gr_alvgrid_var->check_changed_data.


  CASE sy-ucomm.
    WHEN 'ANA_VAR'.
      PERFORM popup_confirm CHANGING l_ans.
      IF l_ans = '1'.
        gv_variable_analysis = 'X'.
        PERFORM analyse_variable_values.
      ENDIF.
    WHEN 'INACTIVE'.
      IF g_varbl_inact = 'X'.
        MESSAGE s002(/psyng/sw) WITH
                'Data Loaded, for both Active and Inactive Values'(006).
      ELSE.
        MESSAGE s002(/psyng/sw) WITH 'Active Values Only'(007).
      ENDIF.

  ENDCASE.
  CLEAR sy-ucomm.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  DATA: is_stable      TYPE lvc_s_stbl,
        l_bukrs_active TYPE flag,
         ls_check LIKE LINE OF gt_output.
  IF gt_output_check[] IS INITIAL.
    gt_output_check[] = gt_output[].
  ENDIF.

  IF i_column_id <> 'TOGGLE' AND i_column_id <> 'ACTIVE'.
    REFRESH gt_output_dtl.
    READ TABLE gt_organization INDEX i_row_id-index.
    gt_output_dtl[] = gt_output[].

*--- for bukrs:  show all fields
    IF i_column_id = 'BUKRS'.
      DELETE gt_output_dtl WHERE  abb NP   gt_organization-abb.

    ELSE.
      DELETE gt_output_dtl WHERE varbl NP i_column_id
                          OR    abb    NP   gt_organization-abb.
    ENDIF.
    g_hotspot_click = 'X'.
    CALL SCREEN '0105'.

  ELSE.
    gf_data_change   = 'X'.
    READ TABLE gt_organization INDEX i_row_id-index.
    IF sy-subrc = 0.

      READ TABLE gt_output
       WITH KEY varbl = 'BUKRS' abb = gt_organization-bukrs.
*       check = 'X'. " only allow if company code activated

      IF sy-subrc = 0.
        IF gt_output-check = 'X'.
          CLEAR  gt_output-check.
          CLEAR gt_organization-toggle.
          gt_output-manual = 'X'.
          MODIFY gt_output
               TRANSPORTING check manual
               WHERE
               abb      = gt_organization-bukrs.
        ELSE.
*          gt_output-check = 'X'.
*          gt_organization-toggle = 'X'.
*
*
**        gt_output-manual = 'X'.
*        MODIFY gt_output
*             TRANSPORTING check manual
*             WHERE
*             abb      = gt_organization-bukrs.
*--16/09/2022 Active only those fields which are
*---exist in customizing table
          LOOP AT gt_output.
            READ TABLE gt_output_check INTO ls_check
                WITH KEY  abb = gt_output-abb
                          low = gt_output-low.
*                          check = 'X'.
            IF sy-subrc = 0.
              gt_output-check = 'X'.
              gt_organization-toggle = 'X'.
              gt_output-manual = 'X'.
              MODIFY gt_output
               TRANSPORTING check manual
               WHERE
               abb      = gt_organization-bukrs AND
               low      = ls_check-low.
            ENDIF.
          ENDLOOP.
        ENDIF.


*---implement: deactivate all records wrt abb value
        MODIFY gt_organization TRANSPORTING toggle
        WHERE abb = gt_output-low.


      ELSE.
        MESSAGE s113(/psyng/sw) WITH
              'Please activate parent company code:'(e11)
              gt_output-abb.
      ENDIF.
*----only active values
      gt_output_inactive[] = gt_output[].
      IF g_disp_inact <> 'X'.
        DELETE gt_output WHERE check <> 'X'.
      ENDIF.

      PERFORM calculate_org_values_occurance.

*---refresh alv with stable row & col
      is_stable-row = 'X'.
      is_stable-col = 'X'.
      CALL METHOD gr_alvgrid_org->refresh_table_display
        EXPORTING
          is_stable = is_stable.  " With Stable Rows/Columns.

      CALL METHOD gr_alvgrid_org1->refresh_table_display
        EXPORTING
          is_stable = is_stable.   " With Stable Rows/Columns.

      gt_output[] = gt_output_inactive[].
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_104                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_104 USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  DATA: is_stable TYPE lvc_s_stbl.



*--- for screen 104
  IF i_column_id = 'ACTIVE'.
*--data change
    gf_data_change   = 'X'.

    READ TABLE gt_variable1 INDEX i_row_id-index.
    IF gt_variable1-active = 'X'.
      CLEAR: gt_variable1-active. ", gt_variable1-modified.
    ELSE.
      gt_variable1-active   = 'X'.
    ENDIF.

*   changing the value of a field that is unmodified makes it modified.
*   Changing the value of a field that is modified makes it unmodified.
    IF gt_variable1-modified = 'X'.
      CLEAR gt_variable1-modified.
    ELSE.
      gt_variable1-modified = 'X'.
    ENDIF.
*    gt_variable1-modified = 'X'.
    MODIFY gt_variable1 INDEX i_row_id-index
    TRANSPORTING modified active.

*---refresh alv with stable row & col
    is_stable-row = 'X'.
    is_stable-col = 'X'.

    CALL METHOD gr_alvgrid_var->refresh_table_display
      EXPORTING
        is_stable = is_stable.   " With Stable Rows/Columns.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_dtl                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_dtl USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  IF i_column_id <> 'TOGGLE' AND i_column_id <> 'ACTIVE'.
    REFRESH gt_output_dtl.
    gt_output_dtl[] = gt_output[].
    DELETE gt_output_dtl WHERE varbl NP i_column_id.
    g_hotspot_click = 'X'.
    CALL SCREEN '0105'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_dtl2                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_dtl2 USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  DATA: l_bukrs(4) TYPE c,
        l_value(4) TYPE c,
        l_field    TYPE string,
        l_sysid    TYPE string,
        is_stable  TYPE lvc_s_stbl,
        ls_org     LIKE LINE OF gt_organization2.

  READ TABLE gt_organization2 INDEX i_row_id-index.

  IF sy-subrc = 0.
    ls_org  = gt_organization2.
    l_bukrs = gt_organization2-bukrs.
    l_field = gt_organization2-varbl.
    l_value = gt_organization2-value.
    l_sysid = gt_organization2-sysid.
    READ TABLE gt_output WITH KEY
                      abb   = l_bukrs
                      varbl = l_field
                      low   = l_value
                      sysid = l_sysid.
    IF gt_organization2-check  = 'X'.
      CLEAR: gt_organization2-check,
      gt_output-check,
      gt_output_dtl-check.
    ELSE.
      gt_organization2-check = 'X'.
      gt_output-check = 'X'.
      gt_output_dtl-check = 'X'.
    ENDIF.
    gt_output-manual = 'X'.
    gt_output_dtl-manual = 'X'.
    gf_data_change   = 'X'.
    MODIFY gt_output
            TRANSPORTING check manual
            WHERE abb   = l_bukrs AND
                  varbl = l_field AND
                  low   = l_value AND
                  sysid = l_sysid.
    MODIFY gt_output_dtl
            TRANSPORTING check manual
            WHERE abb   = l_bukrs AND
                  varbl = l_field AND
                  low   = l_value AND
                  sysid = l_sysid.
    MODIFY gt_organization2 TRANSPORTING check
          WHERE bukrs =   l_bukrs
             AND varbl = l_field
             AND value = l_value
             AND sysid = l_sysid.

*----Allow to activate only if bukrs is activated

    READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                              abb       = l_bukrs.
    IF gt_output-check <> 'X' AND NOT l_field = 'BUKRS'.
      CLEAR: gt_organization2-check,
            gt_output-check,
            gt_output_dtl-check,
            gt_output-manual,
            gt_output_dtl-manual.
      MODIFY gt_output
                  TRANSPORTING check manual
                  WHERE abb   = l_bukrs AND
                        varbl = l_field AND
                        low   = l_value AND
                        sysid = l_sysid.
      MODIFY gt_output_dtl
            TRANSPORTING check manual
            WHERE abb   = l_bukrs AND
                  varbl = l_field AND
                  low   = l_value AND
                  sysid = l_sysid.
      MODIFY gt_organization2 TRANSPORTING check
                  WHERE bukrs =   l_bukrs
                     AND varbl = l_field
                     AND value = l_value
                     AND sysid = l_sysid.
      MESSAGE s113(/psyng/sw) WITH
                    'Please activate parent company code:'(e11)
                    gt_output-abb.
    ELSE.
*--If we were unchecking something, also uncheck dependencies (C0088)
      IF gt_organization2-check IS INITIAL.
        PERFORM
          uncheck_dependant_orgs
          USING ls_org.
      ENDIF.
    ENDIF.

*----Opl539 om 2023/02/20
*--- activate all dependent elements from overview
*---if bukrs is activated
    IF l_field = 'BUKRS'.
      READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                             abb       = l_bukrs.
      IF sy-subrc = 0 AND gt_output-check = 'X'.
        gt_output-check = gt_output-manual =  'X'.
        gt_output_dtl-check = gt_output_dtl-manual = 'X'.
        gt_organization2-check = 'X'.
      ELSE.
        IF gt_output-check IS INITIAL.
          CLEAR: gt_output-check,gt_output-manual, gt_output_dtl-check,
           gt_output_dtl-manual,gt_organization2-check.
        ENDIF.
      ENDIF.

      MODIFY gt_output TRANSPORTING check manual WHERE
                           abb = l_bukrs.
      MODIFY gt_output_dtl TRANSPORTING check manual
      WHERE abb = l_bukrs.
      MODIFY gt_organization2 TRANSPORTING check
      WHERE bukrs = l_bukrs.
    ENDIF.
*  ENDIF.
*---end

*---for details
  is_stable-row = 'X'.
  is_stable-col = 'X'.
  CALL METHOD gr_alvgrid_org2->refresh_table_display
    EXPORTING
      is_stable = is_stable.   " With Stable Rows/Columns.


*--- For smry
*---calculate org_values_occurance
  PERFORM calculate_org_values_occurance.

  CALL METHOD gr_alvgrid_org->refresh_table_display
    EXPORTING
      is_stable = is_stable.   " With Stable Rows/Columns..
ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_102                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_102 USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.
  READ TABLE gt_element1 INDEX i_row_id-index.
  IF gt_element1-default = 'X'.
    gt_element1-selected = 'X'.

  ELSE.
    IF gt_element1-selected = 'X'.
      CLEAR gt_element1-selected.
    ELSE.
      gt_element1-selected = 'X'.
    ENDIF.
    MODIFY gt_element1 TRANSPORTING selected
   WHERE varbl =   gt_element1-varbl.
  ENDIF.
  CALL METHOD gr_alvgrid_ele1->refresh_table_display.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_102_2                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_102_2 USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.
  READ TABLE gt_element2 INDEX i_row_id-index.
  IF gt_element2-default = 'X'.
    gt_element2-selected = 'X'.

  ELSE.
    IF gt_element2-selected = 'X'.
      CLEAR gt_element2-selected.
    ELSE.
      gt_element2-selected = 'X'.
    ENDIF.
    MODIFY gt_element2 TRANSPORTING selected
   WHERE var_element =   gt_element2-var_element.
  ENDIF.
  gf_vs_loaded = 'X'.
  CALL METHOD gr_alvgrid_ele2->refresh_table_display.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM toggle_display                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM toggle_display.
  IF gf_dispchg = gc_display.                    "Display
    LOOP AT SCREEN.
      IF screen-group1 = '002' AND screen-input = 1.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.

  ELSE.
    LOOP AT SCREEN.
      IF screen-group1 = '002' "AND screen-input = 0
      AND  /psyng/swcfgset-setid IS INITIAL.
        screen-input = 0.
*        screen-input = 1.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM perform                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM  load_rules_for_org_sel.

  DATA :
    lt_ao_values TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
    ls_element1  LIKE LINE OF gt_element1.
  REFRESH:lt_ao_values, gt_element1.
  CLEAR gt_element1.
***org element
  CALL FUNCTION '/PSYNG/SW_AO_002'
    EXPORTING
      i_sodvrsio       = /psyng/swsodvers-vrsio
      i_setid          = /psyng/swcfgset-setid
    TABLES
      et_list          = lt_ao_values
    EXCEPTIONS
      version_no_exist = 1
      OTHERS           = 2.

  IF sy-subrc <> 0.
*--Sod Matrix version doesn't exist
    MESSAGE i020(/psyng/sw) WITH
      'SOD Matrix Version'(v02)
      /psyng/swsodvers-vrsio.
  ELSE.
    LOOP AT lt_ao_values.
      MOVE-CORRESPONDING lt_ao_values TO ls_element1.
      ls_element1-varbl = lt_ao_values-field.
*      APPEND gt_element1.
      READ TABLE gt_selections WITH KEY type = 'ORG'
                                        varbl = ls_element1-varbl.
      IF sy-subrc = 0.
        ls_element1-selected = gt_selections-sel.
      ENDIF.

      INSERT ls_element1 INTO TABLE gt_element1.
    ENDLOOP.
    LOOP AT gt_element1 WHERE selected = 'X'.
      gt_sel_ao_list-field = gt_element1-varbl.
      gt_sel_ao_list-selected = 'X'.
      APPEND gt_sel_ao_list.
    ENDLOOP.

*    24.10.2019
*---if setid is blank, defaul & selected value should not checked
    IF /psyng/swcfgset-setid IS INITIAL.
      gt_element1-selected = ' '.
      gt_element1-default =  ' '.
      MODIFY gt_element1 TRANSPORTING selected default
      WHERE  NOT varbl IS INITIAL.
    ENDIF.

  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM analyse_oganizational_values                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM analyse_oganizational_values.
  DATA: lt_org_values TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
 lt_texts      TYPE TABLE OF /psyng/sw_org_values_text WITH HEADER LINE,
 l_setid       TYPE /psyng/swcfgset-setid.

  REFRESH: lt_org_values,lt_texts,gt_organization,
gt_organization1.

*---Analyze the selected Configuration Set
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    l_setid = /psyng/swcfgset-setid.
  ELSE.
    CLEAR l_setid.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_AO_READ'
    EXPORTING
      if_analyze          = 'X'
      i_setid             = l_setid
      if_validate         = 'X'
    TABLES
      et_org_values       = lt_org_values
      et_texts            = lt_texts
      it_analyze_elements = gt_sel_ao_list
      it_systems          = gt_sel_systems.

  REFRESH: gt_output,gt_org_values .
  gt_org_values[] = lt_org_values[].
  SORT lt_texts BY field low.
  LOOP AT lt_org_values.
    CLEAR gt_output.
    gt_output-check   = lt_org_values-active.
    MOVE-CORRESPONDING lt_org_values TO gt_output.
    gt_output-low = lt_org_values-value.
    READ TABLE lt_texts WITH KEY field = lt_org_values-varbl
                                  low   = gt_output-low
                                  BINARY SEARCH
                                  TRANSPORTING vtext.

    IF sy-subrc = 0.
      gt_output-label = lt_texts-vtext.
    ENDIF.
    APPEND gt_output.
  ENDLOOP.

*---delete inactive value for default
*  gt_output_inactive[] = gt_output[].
*  DELETE gt_output WHERE check <> 'X'.
*  CLEAR g_disp_inact.
*  PERFORM calculate_org_values_occurance.
  MESSAGE s002(/psyng/sw) WITH text-008.
*---assign in gt_output again
*  gt_output[] = gt_output_inactive[].
  PERFORM calculate_org_values_occurance.
  gf_ao_loaded = 'X'.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM analyse_variable_values                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM analyse_variable_values.
  DATA l_setid TYPE /psyng/swcfgset-setid.
  DATA: lt_return  TYPE TABLE OF bapiret2,
        lt_values  TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
        lt_system  TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
        lt_ve_text TYPE TABLE OF /psyng/sw_ve_values_text
        WITH HEADER LINE.

  REFRESH: lt_values, lt_return, lt_system, gt_variable1, lt_ve_text.

  IF NOT /psyng/swcfgset-setid IS INITIAL.
    l_setid = /psyng/swcfgset-setid.
  ELSE.
    CLEAR l_setid.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_VE_READ'
    EXPORTING
      if_analyze          = 'X'
      i_setid             = l_setid
      i_varel_vrsio       = /psyng/swcfgset-varel_vrsio
      if_include_inactive = 'X'
      if_validate         = 'X'
      if_read_texts       = 'X'
    TABLES
      et_ve_values        = lt_values
      et_return           = lt_return
      it_systems          = gt_sel_systems
      it_analyze_elements = r_varel
      et_texts            = lt_ve_text.
  gt_variable1-cnt = 1.
  LOOP AT lt_values.
    MOVE-CORRESPONDING lt_values TO gt_variable1.
    READ TABLE lt_ve_text WITH KEY
              sysid       = lt_values-sysid
              var_element = lt_values-var_element
              value       = lt_values-value.
    IF sy-subrc = 0.
      gt_variable1-vtext = lt_ve_text-vtext.
    ELSE.
      CLEAR gt_variable1-vtext.
    ENDIF.
    APPEND gt_variable1.
  ENDLOOP.
  MESSAGE s002(/psyng/sw) WITH text-008.
  gf_ve_loaded = 'X'.

*---set default values for filter
  IF NOT gt_variable1[] IS INITIAL.
    IF /psyng/swcfgve-var_element IS INITIAL.
      /psyng/swcfgve-var_element = 'ALL'.
    ENDIF.
    IF /psyng/swcfgve-sysid IS INITIAL.
      /psyng/swcfgve-sysid = 'ALL'.
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_help                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FIELDNAME                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM f4_help USING    i_fieldname TYPE lvc_fname
                      is_row_no TYPE lvc_s_roid.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields   TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return   TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_varel    TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
        l_fieldname TYPE fieldname,
        lt_dfies    TYPE TABLE OF dfies WITH HEADER LINE,
        lt_rfcdes   TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.
  FIELD-SYMBOLS: <wa_varel> LIKE LINE OF gt_variable1.

  READ TABLE gt_variable1 ASSIGNING <wa_varel> INDEX is_row_no-row_id.
  CASE i_fieldname.

    WHEN 'VAR_ELEMENT'.
  SELECT DISTINCT var_element FROM  /psyng/sw_varel INTO "#EC CI_NOWHERE
  CORRESPONDING FIELDS OF TABLE lt_varel.
        DELETE lt_varel WHERE var_element EQ space.
*---convert into upper case
        LOOP AT lt_varel.
          TRANSLATE lt_varel TO UPPER CASE.
          MODIFY lt_varel.
        ENDLOOP.
        SORT lt_varel BY var_element.
        DELETE ADJACENT DUPLICATES FROM lt_varel COMPARING var_element.
*--Get field label
        LOOP AT lt_varel.
          lt_values-line = lt_varel-var_element.
          APPEND lt_values.
        ENDLOOP.

        lt_fields-tabname   = '/PSYNG/SW_VAREL'.
        lt_fields-fieldname = 'VAR_ELEMENT'.
        APPEND lt_fields.

        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
          EXPORTING
            retfield        = 'VAR_ELEMENT'
          TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
          EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

        IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
                AND gf_dispchg = gc_change.
          READ TABLE lt_return INDEX 1.
          <wa_varel>-var_element = lt_return-fieldval.
        ENDIF.
        CALL METHOD gr_alvgrid_var->refresh_table_display.


      WHEN 'SYSID'.
        SELECT * FROM /psyng/sw_rfcdes
      INTO  TABLE lt_rfcdes.

          LOOP AT lt_rfcdes.
            lt_values-line = lt_rfcdes-rfcdest.
            APPEND lt_values.
            lt_values-line = lt_rfcdes-rfcname.
            APPEND lt_values.
            lt_values-line = lt_rfcdes-description.
            APPEND lt_values.
            lt_values-line = lt_rfcdes-systid.
            APPEND lt_values.
          ENDLOOP.

          lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
          lt_fields-fieldname = 'RFCDEST'.
          APPEND lt_fields.
          lt_fields-tabname = '/PSYNG/SW_RFCDES'.
          lt_fields-fieldname = 'RFCNAME'.
          APPEND lt_fields.
          lt_fields-tabname = '/PSYNG/SW_RFCDES'.
          lt_fields-fieldname = 'DESCRIPTION'.
          APPEND lt_fields.
          lt_fields-tabname = '/PSYNG/SW_RFCDES'.
          lt_fields-fieldname = 'SYSTID'.
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

          IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
                  AND gf_dispchg = gc_change.
            READ TABLE lt_return INDEX 1.
            <wa_varel>-sysid = lt_return-fieldval.
          ENDIF.
          CALL METHOD gr_alvgrid_var->refresh_table_display.

      ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM save_101                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_101.
  CALL METHOD gr_alvgrid_sys->check_changed_data.
  IF NOT /psyng/swcfgset-setid IS INITIAL.

******insert selected systems into db
    LOOP AT gt_systems WHERE sel = 'X'.
      MOVE-CORRESPONDING gt_systems TO lt_swcfgsys.
      lt_swcfgsys-setid = /psyng/swcfgset-setid.
      APPEND lt_swcfgsys.
    ENDLOOP.
* selected system to use in variable elements
    APPEND LINES OF lt_swcfgsys TO gt_sel_systems.
    IF NOT lt_swcfgsys[] IS INITIAL.
*---   delete previous data
      DELETE FROM /psyng/swcfgsys WHERE setid = /psyng/swcfgset-setid.
      MODIFY /psyng/swcfgsys FROM TABLE lt_swcfgsys.
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_103                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_103.
  DATA l_success TYPE flag.
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    REFRESH : gt_org_values.
    LOOP AT gt_output.
      MOVE-CORRESPONDING gt_output TO gt_org_values.
      gt_org_values-value    = gt_output-low.
      gt_org_values-modified = gt_output-manual.
      gt_org_values-active   = gt_output-check.

      APPEND gt_org_values.
    ENDLOOP.

    CALL FUNCTION '/PSYNG/SW_AO_SAVE'
      EXPORTING
        i_setid       = /psyng/swcfgset-setid
      IMPORTING
        ef_success    = l_success
      TABLES
        it_org_values = gt_org_values.
*        IF l_success = 'X'.
*          MESSAGE s002(/psyng/sw) WITH text-004.
*        ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_104                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_104.
  FIELD-SYMBOLS:<wa_variable> LIKE LINE OF gt_variable1.
  DATA: lv_flag        TYPE c,
        lv_tabix       TYPE sy-tabix,
        l_current_line TYPE i,
        ls_var         LIKE LINE OF gt_variable1,
        lt_rfcdes1     TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_sw_varel    TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE.


  CLEAR lv_flag.
  IF NOT /psyng/swcfgset-setid IS INITIAL.

    gt_variable1-setid = /psyng/swcfgset-setid.
    MODIFY gt_variable1 TRANSPORTING setid
              WHERE setid <> /psyng/swcfgset-setid.
*
**---validations
    SELECT * FROM /psyng/sw_rfcdes
       INTO  TABLE lt_rfcdes1.

  SELECT DISTINCT var_element FROM  /psyng/sw_varel INTO "#EC CI_NOWHERE
        CORRESPONDING FIELDS OF TABLE lt_sw_varel.
        DELETE lt_sw_varel WHERE var_element EQ space.

        LOOP AT gt_variable1.
          lv_tabix = sy-tabix.
          l_current_line = sy-tabix.

*----check valid system
          IF NOT gt_variable1-sysid IS INITIAL.
            READ TABLE lt_rfcdes1 WITH KEY systid = gt_variable1-sysid.
            IF sy-subrc <> 0.
              MESSAGE e113(/psyng/basis) WITH 'Invalid system ID'(e05).
              lv_flag = 'X'.
              EXIT.
            ENDIF.
          ENDIF.

*--- variable element

          IF NOT gt_variable1-var_element IS INITIAL.
            READ TABLE lt_sw_varel WITH KEY
                          var_element = gt_variable1-var_element.
            IF sy-subrc <> 0.
        MESSAGE e113(/psyng/basis) WITH 'Invalid Variable Element'(e06).
              lv_flag = 'X'.
              EXIT.
            ENDIF.
          ENDIF.

**---duplicates
*
*      LOOP AT gt_variable1 INTO ls_var FROM lv_tabix
*              WHERE
*                  setid      = gt_variable1-setid
*             AND var_element = gt_variable1-var_element
*             AND sysid       = gt_variable1-sysid
*             AND value       = gt_variable1-value.
*
*        IF sy-tabix <> l_current_line.
*          MESSAGE s038(/psyng/basis).
*          lv_flag = 'X'.
*          EXIT.
*        ENDIF.
*      ENDLOOP.
        ENDLOOP.

        SORT gt_variable1 BY setid var_element sysid value.
        DELETE ADJACENT DUPLICATES FROM gt_variable1 COMPARING setid
          var_element sysid value.

*---save
        IF lv_flag IS INITIAL.
          CALL FUNCTION '/PSYNG/SW_VE_SAVE'
            EXPORTING
              i_setid      = /psyng/swcfgset-setid
            TABLES
              it_ve_values = gt_variable1.
        ENDIF.
      ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM delete_configset_other_data                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM delete_configset_other_data.

  DELETE FROM /psyng/swcfgsys WHERE setid =
                                          /psyng/swcfgset-setid.
  DELETE FROM /psyng/swcfgoe WHERE setid = /psyng/swcfgset-setid.

  DELETE FROM /psyng/swcfgve WHERE setid = /psyng/swcfgset-setid.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_103_existing_data                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_103_existing_data.
 DATA : lt_swsodorgm      TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
        lt_bapiret2       TYPE TABLE OF bapiret2 WITH HEADER LINE,
        lt_values         TYPE TABLE OF /psyng/sw_org_values_text
              WITH HEADER LINE,
        l_number_of_lines TYPE i.

  REFRESH :  lt_swsodorgm, lt_values, lt_bapiret2, gt_output.
  CALL FUNCTION '/PSYNG/SW_AO_READ'
    EXPORTING
      if_read       = 'X'
      i_setid       = /psyng/swcfgset-setid
      if_read_texts = 'X'
    TABLES
      et_org_values = lt_swsodorgm
      et_return     = lt_bapiret2
      et_texts      = lt_values.

  SORT lt_values BY field low.
  LOOP AT lt_swsodorgm.
    CLEAR gt_output.
    gt_output-check   = lt_swsodorgm-active.
    gt_output-manual  = lt_swsodorgm-modified.
    MOVE-CORRESPONDING lt_swsodorgm TO gt_output.
    gt_output-low = lt_swsodorgm-value.
    READ TABLE lt_values WITH KEY field = lt_swsodorgm-varbl
                                  low   = gt_output-low
                                  BINARY SEARCH
                                  TRANSPORTING vtext.

    IF sy-subrc = 0.
      gt_output-label = lt_values-vtext.
    ENDIF.
    APPEND gt_output.
  ENDLOOP.


  PERFORM calculate_org_values_occurance.
  gf_ao_loaded = 'X'.

**----display active value by default
*  gt_output_inactive[] = gt_output[].
*  IF g_disp_inact <> 'X'.
*    DELETE gt_output WHERE check <> 'X'.
*    CLEAR: g_disp_inact.
*  ENDIF.
**---calculate org_values_occurance
*  PERFORM calculate_org_values_occurance.
*  gt_output[] = gt_output_inactive[].
*
ENDFORM.


*---------------------------------------------------------------------*
*       FORM load_existing_variable_element                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_existing_variable_element.
  DATA: lt_return  TYPE TABLE OF bapiret2,
        lt_values  TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
        lt_system  TYPE TABLE OF /psyng/swcfgset WITH HEADER LINE,
        lt_ve_text TYPE TABLE OF /psyng/sw_ve_values_text
            WITH HEADER LINE.

  IF NOT /psyng/swcfgset-setid IS INITIAL.
    SELECT * FROM /psyng/swcfgset INTO TABLE lt_system
    WHERE setid = /psyng/swcfgset-setid.
      IF gt_variable1[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_VE_READ'
          EXPORTING
            if_read       = 'X'
            i_setid       = /psyng/swcfgset-setid
            i_varel_vrsio = /psyng/swcfgset-varel_vrsio
            if_read_texts = 'X'
          TABLES
            et_ve_values  = lt_values
            et_return     = lt_return
            et_texts      = lt_ve_text.

        gt_variable1-cnt = 1.
        LOOP AT lt_values.
          MOVE-CORRESPONDING lt_values TO gt_variable1.
          READ TABLE lt_ve_text WITH KEY
                sysid        = lt_values-sysid
                var_element  = lt_values-var_element
                value        = lt_values-value.
          IF sy-subrc = 0.
            gt_variable1-vtext = lt_ve_text-vtext.
          ENDIF.
          APPEND gt_variable1.
          CLEAR gt_variable1-vtext.
        ENDLOOP.
      ENDIF.
      gf_ve_loaded = 'X'.
    ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_info                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_DOCNAME                                                     *
*---------------------------------------------------------------------*
FORM get_info USING i_docname.
  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
    EXPORTING
      dokname = i_docname.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM confirm_exit                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_ANSWER                                                      *
*---------------------------------------------------------------------*
FORM confirm_exit CHANGING e_answer TYPE char1.
  DATA l_ques TYPE string.
  IF gf_data_change = 'X' OR gf_screen_change = 'X'.
    l_ques = 'Do you want to exit without save?'(q01).

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = ' '
        text_question         = l_ques
        text_button_1         = 'Yes'
        icon_button_1         = '@0V@'
        text_button_2         = 'No'
        icon_button_2         = '@2O@'
        default_button        = '2'
        display_cancel_button = 'X'
      IMPORTING
        answer                = e_answer
      EXCEPTIONS
        text_not_found        = 1
        OTHERS                = 2.
*BOC:HBHALLA (03/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
                WITH 'Diagnosis text not found'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (03/12/24)
  ELSE.
    e_answer = '1'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  authorization_check
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      I_SETID
*      I_ACTION : D = Display   - 03
*                 E = Edit      - 02
*                 P = Publish   - 07
*----------------------------------------------------------------------*
FORM authorization_check USING   i_setid
                                 i_action

                         CHANGING
                                 ef_ok.

*--Commenting to check auth on click of disp/change icon
*  CHECK NOT i_setid IS INITIAL.

  DATA : l_actvt   TYPE xuvalue,
         l_label   TYPE string,
         l_msgtype TYPE c VALUE 'W'.
  CASE i_action.
    WHEN 'D'.
      l_actvt   = '03'.
      l_label   = 'Display'(a02).
    WHEN 'E'.
      l_actvt   = '02'.
      l_label   = 'Edit'(a03).
    WHEN 'P'.
      l_actvt   = '07'.
      l_label   = 'Publish'(a04).
      l_msgtype = 'E'.
  ENDCASE.
  ef_ok = 'X'.
  IF NOT i_setid IS INITIAL.
    AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
             ID 'ACTVT'      FIELD l_actvt
             ID 'Y&SW_SETID' FIELD i_setid.
    IF sy-subrc <> 0.
      CLEAR ef_ok.
      MESSAGE ID '/PSYNG/SW'  TYPE l_msgtype NUMBER 108
       WITH
         l_label
         'Config Set'(a01)
         i_setid ''.
    ENDIF.
  ELSE.
    AUTHORITY-CHECK OBJECT   'Y&SW_CFGST'
             ID 'ACTVT'      FIELD l_actvt
             ID 'Y&SW_SETID' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc <> 0.
      CLEAR ef_ok.
      MESSAGE ID '/PSYNG/SW'  TYPE l_msgtype NUMBER 108
       WITH
         l_label
         'Config Set'(a01).
    ENDIF.
  ENDIF.

ENDFORM.                    " authorization_check

*---------------------------------------------------------------------*
*       FORM update_sysid                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_RFCDEST                                                    *
*---------------------------------------------------------------------*
FORM update_sysid
  TABLES
    it_rfcdest STRUCTURE /psyng/sw_rfcdes.
  DATA : l_system_msg(72) TYPE c,
         l_rfc            TYPE rfcdest.
  FIELD-SYMBOLS : <rec> TYPE /psyng/sw_rfcdes.
*  --Update the SYSTEM ID field
  LOOP AT  it_rfcdest   ASSIGNING <rec>.
    IF <rec>-systid IS INITIAL .
      l_rfc =  <rec>-systid.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
           .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      CALL FUNCTION '/PSYNG/SW_062'
        DESTINATION <rec>-rfcdest
        IMPORTING
          e_rfcdest             = l_rfc
        EXCEPTIONS
          communication_failure = 1
          system_failure        = 2
          OTHERS                = 3."#EC SAST_CI_GEN_CHECK
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
      <rec>-systid = l_rfc.
    ENDIF.
  ENDLOOP.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM create_filter_varbl_alv                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  LT_FILTER                                                     *
*---------------------------------------------------------------------*
FORM create_filter_varbl_alv  TABLES et_filter TYPE lvc_t_filt.
  DATA ls_filter TYPE lvc_s_filt.
  DATA: BEGIN OF lt_elmnt OCCURS 0,
          var_element TYPE /psyng/swcfgve-var_element,
        END OF lt_elmnt.

  DATA: BEGIN OF lt_sysid OCCURS 0,
          sysid TYPE /psyng/swcfgve-sysid,
        END OF lt_sysid.

*---- Take Values correponding to setid
*  SELECT DISTINCT var_element FROM  /psyng/swcfgve INTO
*   TABLE lt_elmnt
*  WHERE setid = /psyng/swcfgset-setid
*  AND   var_element <> /psyng/swcfgve-var_element.
*
*  SELECT DISTINCT sysid FROM  /psyng/swcfgve INTO
*   TABLE lt_sysid
*  WHERE setid = /psyng/swcfgset-setid
*  AND sysid   <> /psyng/swcfgve-sysid.

  LOOP AT gt_variable1 WHERE var_element <> /psyng/swcfgve-var_element.
    lt_elmnt-var_element = gt_variable1-var_element.
    COLLECT lt_elmnt.
  ENDLOOP.

  LOOP AT gt_variable1 WHERE sysid <> /psyng/swcfgve-sysid.
    lt_sysid-sysid = gt_variable1-sysid.
    COLLECT lt_sysid.
  ENDLOOP.


*---prepare filter for element
  LOOP AT lt_elmnt.
    ls_filter-fieldname = 'VAR_ELEMENT'.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = lt_elmnt-var_element.
    APPEND ls_filter TO et_filter.
  ENDLOOP.

*--- Delete filter if selected as all or blank
  IF /psyng/swcfgve-var_element IS INITIAL OR
    /psyng/swcfgve-var_element = 'ALL'.
    DELETE et_filter WHERE fieldname = 'VAR_ELEMENT'.
  ENDIF.

*---prepare filter for sysid
  LOOP AT lt_sysid.
    ls_filter-fieldname = 'SYSID'.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = lt_sysid-sysid.
    APPEND ls_filter TO et_filter.
  ENDLOOP.

  IF /psyng/swcfgve-sysid IS INITIAL OR /psyng/swcfgve-sysid = 'ALL'.
    DELETE et_filter WHERE fieldname = 'SYSID'.
  ENDIF.

*---Filter for inactive/active values
  IF g_varbl_inact IS INITIAL.
    ls_filter-fieldname = 'ACTIVE'.
    ls_filter-sign      = 'E'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = ''.
    APPEND ls_filter TO et_filter.
  ENDIF.

  IF gt_variable1[] IS INITIAL.
    DELETE et_filter WHERE fieldname = 'ACTIVE'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM fill_filters_dropdown                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_filters_dropdown.
  TYPE-POOLS vrm.

  DATA: lt_swcfgve TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
        lt_value   TYPE vrm_values WITH HEADER LINE.
  DATA: BEGIN OF lt_rfcdes OCCURS 0,
          sysid TYPE /psyng/swcfgve-sysid,
        END OF lt_rfcdes.

  REFRESH: lt_swcfgve,  lt_value, lt_rfcdes.
*---Element values for drop down
*  SELECT DISTINCT var_element FROM  /psyng/swcfgve INTO
*   CORRESPONDING FIELDS OF TABLE lt_swcfgve
*   WHERE setid = /psyng/swcfgset-setid.

  IF NOT gt_variable1[] IS INITIAL.
    lt_value-text = 'ALL'.
    lt_value-key  = 'ALL'.
    APPEND lt_value.
  ENDIF.

*  LOOP AT lt_swcfgve.
*    lt_value-text = lt_swcfgve-var_element.
*    lt_value-key = lt_swcfgve-var_element.
*    APPEND lt_value.
*  ENDLOOP.

  LOOP AT gt_variable1.
    lt_value-text = gt_variable1-var_element.
    lt_value-key = gt_variable1-var_element.
    COLLECT lt_value.

    lt_rfcdes-sysid = gt_variable1-sysid.
    COLLECT lt_rfcdes.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id              = '/PSYNG/SWCFGVE-VAR_ELEMENT'
      values          = lt_value[]
    EXCEPTIONS
      id_illegal_name = 1
      OTHERS          = 2.
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Illegal id Name'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)

  REFRESH lt_value.

*---- Sysid values for drop down
*    SELECT DISTINCT sysid FROM  /psyng/swcfgve INTO
*     TABLE lt_rfcdes
*    WHERE setid = /psyng/swcfgset-setid.

  IF NOT gt_variable1[] IS INITIAL.
    lt_rfcdes-sysid = 'ALL'.
    APPEND lt_rfcdes.
  ENDIF.

  LOOP AT lt_rfcdes.
    lt_value-text = lt_rfcdes-sysid.
    lt_value-key = lt_rfcdes-sysid.
    APPEND lt_value.
  ENDLOOP.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id              = '/PSYNG/SWCFGVE-SYSID'
      values          = lt_value[]
    EXCEPTIONS
      id_illegal_name = 1
      OTHERS          = 2.
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Illegal id Name'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)

ENDFORM.


*---------------------------------------------------------------------*
*       FORM f_count_field_company                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_VARBL                                                       *
*  -->  I_ABB                                                         *
*  -->  E_LABEL                                                       *
*---------------------------------------------------------------------*
FORM f_count_field_company
  USING i_varbl
        i_abb
        i_initialize
  CHANGING
        e_label.
  DATA : l_total       TYPE i, l_active TYPE i,
         l_total_c     TYPE string, l_active_c TYPE string,
         lt_temp_count LIKE TABLE OF gt_output WITH HEADER LINE.

  STATICS :
    BEGIN OF st_field_comp_count OCCURS 0,
      varbl  TYPE tprorgvar,
      abb    TYPE /psyng/dorg_abb,
      total  TYPE i,
      active TYPE i,
    END OF st_field_comp_count.
  IF i_initialize = 'X'.
    REFRESH st_field_comp_count.
  ENDIF.
  IF st_field_comp_count[] IS INITIAL.
*--Collect counts per field per abb
    lt_temp_count[] = gt_output[].
    SORT lt_temp_count BY low ASCENDING check DESCENDING.
    DELETE ADJACENT DUPLICATES FROM lt_temp_count
    COMPARING varbl abb low sysid.
    LOOP AT lt_temp_count.
      CLEAR st_field_comp_count.
      st_field_comp_count-varbl = lt_temp_count-varbl.
      st_field_comp_count-abb   = lt_temp_count-abb.
      IF lt_temp_count-check = 'X'.
        st_field_comp_count-active = 1.
      ENDIF.
      st_field_comp_count-total = 1.
      COLLECT st_field_comp_count.
    ENDLOOP.
    SORT st_field_comp_count BY varbl abb.
    CLEAR st_field_comp_count.
  ENDIF.
  READ TABLE st_field_comp_count WITH KEY varbl = i_varbl
                                          abb   = i_abb
       BINARY SEARCH.
  IF sy-subrc = 0.
    l_total  = st_field_comp_count-total.
    l_active = st_field_comp_count-active.
  ENDIF.

  l_total_c  = l_total.
  l_active_c = l_active.
  CONDENSE : l_total_c,l_active_c.
  CONCATENATE l_active_c '/' l_total_c INTO e_label.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  save_102
*&---------------------------------------------------------------------*
*      Save the selected Variable Elements and Org Areas
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_102.
  DATA : lt_selections TYPE TABLE OF /psyng/swcfsel WITH HEADER LINE.
  lt_selections-type  = 'ORG'.
  lt_selections-setid = /psyng/swcfgset-setid.
  LOOP AT gt_element1.
    lt_selections-sel   = gt_element1-selected.
    lt_selections-varbl = gt_element1-varbl.
    COLLECT lt_selections.
  ENDLOOP.
  lt_selections-type = 'VE'.
  LOOP AT gt_element2.
    lt_selections-sel   = gt_element2-selected.
    lt_selections-varbl = gt_element2-var_element.
    COLLECT lt_selections.
  ENDLOOP.
  DELETE FROM /psyng/swcfsel WHERE setid = /psyng/swcfgset-setid.
  COMMIT WORK.
  MODIFY /psyng/swcfsel FROM TABLE lt_selections.
  COMMIT WORK.
  gt_selections[] = lt_selections[].
ENDFORM.                                                    " save_102
*&---------------------------------------------------------------------*
*&      Form  load_selected_elements
*&---------------------------------------------------------------------*
*         Load the selected Variable Elements and Org Areas
*----------------------------------------------------------------------*
FORM load_selected_elements.
  REFRESH : gt_selections.
  SELECT * FROM /psyng/swcfsel INTO TABLE gt_selections
  WHERE setid = /psyng/swcfgset-setid.
    SORT gt_selections BY type varbl.
ENDFORM.                    " load_selected_elements
*&---------------------------------------------------------------------*
*&      Form  toggle_org_for_all_abb
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM toggle_org_for_all_abb.
  DATA : lt_rows   TYPE lvc_t_row,
         lt_roid   TYPE lvc_t_roid,
         ls_row    TYPE lvc_s_row,
         ls_roid   TYPE lvc_s_roid,
         ls_org    LIKE gt_organization2,
         ls_stable TYPE lvc_s_stbl,
         l_parent_inactive TYPE c LENGTH 1.
  FIELD-SYMBOLS : <org> LIKE gt_organization2,
                  <out> LIKE gt_output.
  CLEAR l_parent_inactive.
  CALL METHOD gr_alvgrid_org2->get_selected_rows
    IMPORTING
      et_index_rows = lt_rows
      et_row_no     = lt_roid.
  IF NOT lt_rows[] IS INITIAL.
    LOOP AT lt_rows INTO ls_row.
      READ TABLE gt_organization2 INTO ls_org
           INDEX ls_row-index.
      IF sy-subrc = 0.
        LOOP AT gt_organization2 ASSIGNING <org>
          WHERE varbl = ls_org-varbl AND
              " bukrs   = ls_org-bukrs and
                value = ls_org-value.
          IF <org>-check = 'X'.
            CLEAR <org>-check.
          ELSE.
            <org>-check = 'X'.
          ENDIF.

* ---15/06/2022 Om Opl525
          READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                                     abb = <org>-bukrs.
          IF gt_output-check <> 'X'.
            CLEAR <org>-check.
            l_parent_inactive = 'Y'.
            MESSAGE s113(/psyng/sw) WITH
                    'Please activate parent company code:'(e11)
                    ls_org-bukrs.

          ENDIF.
        ENDLOOP.


        LOOP AT gt_output ASSIGNING <out>
          WHERE  "abb = ls_org-bukrs and
                varbl = ls_org-varbl AND
                low   = ls_org-value.
          IF <out>-check = 'X'.
            CLEAR <out>-check.
          ELSE.
            <out>-check = 'X'.
          ENDIF.
          <out>-manual  = 'X'.
          <out>-toggled = <out>-check.

* ---15/06/2022 Om Opl525
*bec
 READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                                     abb = <out>-abb.
 if gt_output-check <> 'X'.
*end
*          IF l_parent_inactive = 'Y'.
            CLEAR: <out>-check, <out>-manual.
          ENDIF.
        ENDLOOP.
*--for detail screen
        LOOP AT gt_output_dtl ASSIGNING <out>
                  WHERE
                        "abb   = ls_org-bukrs and
                        varbl = ls_org-varbl AND
                        low   = ls_org-value.
          IF <out>-check = 'X'.
            CLEAR <out>-check.
          ELSE.
            <out>-check = 'X'.
          ENDIF.
          <out>-manual  = 'X'.
          <out>-toggled = <out>-check.

* ---15/06/2022 Om Opl525
*          IF l_parent_inactive = 'Y'.
*bec
 READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                                     abb = <out>-abb.
 if gt_output-check <> 'X'.
*end
            CLEAR: <out>-check, <out>-manual.
          ENDIF.
        ENDLOOP.
      ENDIF.
      PERFORM
        uncheck_dependant_orgs
        USING ls_org.
CLEAR l_parent_inactive.
    ENDLOOP.

*---for details
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD gr_alvgrid_org2->refresh_table_display
      EXPORTING
        is_stable = ls_stable.   " With Stable Rows/Columns.

*--- For summary
*---calculate org_values_occurance
    PERFORM calculate_org_values_occurance.
    CALL METHOD gr_alvgrid_org->refresh_table_display
      EXPORTING
        is_stable = ls_stable.   " With Stable Rows/Columns.

  ELSE.
    MESSAGE s002(/psyng/sw) WITH 'No records selected.'(nr1).
  ENDIF.

ENDFORM.                    " toggle_org_for_all_abb

*---------------------------------------------------------------------*
*       FORM copy_from_existing_cfgset                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM copy_from_existing_cfgset.
  DATA: l_pre_setid TYPE /psyng/swcfgset-setid.

  IF gf_set_loaded = 'X'.
    PERFORM get_existing_config_set_data.
    gf_sys_loaded = 'X'.

*---clear flags and refresh internal tables to reload
    CLEAR : gf_ve_loaded ,
            gf_ao_loaded,
            gf_vs_loaded,
            l_pre_setid.
    REFRESH : gt_output, gt_organization, gt_organization1,
              gt_variable1.
    REFRESH : gt_sel_ao_list, r_varel.

*--- collect selected org & Variable values
    LOOP AT gt_element1 WHERE selected = 'X'.
      gt_sel_ao_list-field = gt_element1-varbl.
      gt_sel_ao_list-selected = 'X'.
      APPEND gt_sel_ao_list.
    ENDLOOP.

    LOOP AT gt_element2 WHERE selected = 'X'.
      r_varel-sign = 'I'.
      r_varel-option = 'EQ'.
      r_varel-low = gt_element2-var_element.
      APPEND r_varel.
    ENDLOOP.

*--Do the analysis for previous setid
    PERFORM analyse_oganizational_values.
    PERFORM analyse_variable_values.
*---manually applied modifications
    PERFORM manual_changes_apply.
*---Assign org and veriable analysis flag
    gv_conbine_analysis = 'X'.
    gv_org_analysis = gv_conbine_analysis.
    gv_variable_analysis = gv_conbine_analysis.
    l_pre_setid = /psyng/swcfgset-setid.

*--- configset header data
    SELECT SINGLE varel_vrsio sodvrsio FROM /psyng/swcfgset INTO
        (/psyng/swcfgset-varel_vrsio, /psyng/swsodvers-vrsio)
         WHERE setid = /psyng/swcfgset-setid.

      CONCATENATE 'Copy of'(co2) /psyng/swcfgset-description INTO
  /psyng/swcfgset-description SEPARATED BY space.

*---Create new cfgset
      CLEAR: g_setid.
      CALL FUNCTION '/PSYNG/SW_CFG_GET_NEW_SETID'
        IMPORTING
          setid = g_setid.
      /psyng/swcfgset-setid = g_setid.
      /psyng/swcfgset-create_date = sy-datum.
      /psyng/swcfgset-create_time = sy-uzeit.
      /psyng/swcfgset-create_user = g_current_user."sy-uname. C0700
      /psyng/swcfgset-change_date = sy-datum.
      /psyng/swcfgset-change_time = sy-uzeit.
      /psyng/swcfgset-change_user = g_current_user."sy-uname. C0700
      CLEAR: /psyng/swcfgset-published, g_published. " clear publish
      g_loaded_set = g_setid.

*--save the coppied config set
      PERFORM save_data.
      MESSAGE s002(/psyng/sw) WITH
      'Config. Set'(co3) l_pre_setid
      'Copied to Config. Set'(co4) g_setid.
    ELSE.
      MESSAGE s002(/psyng/sw) WITH
      'Please load an existing Configset.'(co1).
    ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM manual_changes_apply                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM manual_changes_apply.
  DATA : lt_ve_values TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
         lt_oe_values TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE.

*--read elements which are manually modified in previous setid and
*--add if not present or not
*--activated/deactivated

*--Variable element
  SELECT * FROM /psyng/swcfgve INTO TABLE lt_ve_values
    WHERE setid   = /psyng/swcfgset-setid
    AND  modified = 'X'
    ORDER BY var_element sysid value.

    LOOP AT lt_ve_values.
      READ TABLE gt_variable1 WITH KEY
                          var_element = lt_ve_values-var_element
                          sysid       = lt_ve_values-sysid
                          value       = lt_ve_values-value.
      IF sy-subrc <> 0.
        MOVE-CORRESPONDING lt_ve_values TO gt_variable1.
        APPEND gt_variable1.
      ELSE.
        gt_variable1-modified = lt_ve_values-modified.
        gt_variable1-active = lt_ve_values-active.
        MODIFY gt_variable1  TRANSPORTING active modified
        WHERE        var_element = lt_ve_values-var_element
                  AND sysid      = lt_ve_values-sysid
                  AND  value     = lt_ve_values-value.

      ENDIF.
    ENDLOOP.

*--org element
    SELECT * FROM /psyng/swcfgoe INTO TABLE lt_oe_values
     WHERE setid  = /psyng/swcfgset-setid
     AND modified = 'X'
     ORDER BY abb varbl value.
      LOOP AT lt_oe_values.
        READ TABLE gt_output WITH KEY
                        abb     = lt_oe_values-abb
                        varbl   = lt_oe_values-varbl
                        sysid   = lt_oe_values-sysid
                        low     = lt_oe_values-value.
        IF sy-subrc <> 0.
          MOVE-CORRESPONDING lt_oe_values TO gt_output.
          gt_output-check = lt_oe_values-active.
          gt_output-manual = lt_oe_values-modified.
          APPEND gt_output.
        ELSE.
          gt_output-check = lt_oe_values-active.
          gt_output-manual = lt_oe_values-modified.
          MODIFY gt_output TRANSPORTING check manual
          WHERE abb     = lt_oe_values-abb
            AND varbl   = lt_oe_values-varbl
            AND sysid   = lt_oe_values-sysid
            AND low     = lt_oe_values-value.
        ENDIF.
      ENDLOOP.
*--if anything modified reload org values on screen
      IF NOT lt_oe_values[] IS INITIAL.
        PERFORM calculate_org_values_occurance.
      ENDIF.

      FREE: lt_oe_values, lt_ve_values.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM save_data                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM save_data.
  IF NOT /psyng/swcfgset-setid IS INITIAL.
    PERFORM save_configset_header.
    IF NOT gt_systems[] IS INITIAL.
      PERFORM save_101.
    ENDIF.
    IF NOT gt_organization[] IS INITIAL.
      PERFORM save_103.
    ENDIF.
    IF NOT gt_variable1[] IS INITIAL.
      PERFORM save_104.
    ENDIF.
    PERFORM save_102.
    MESSAGE s002(/psyng/sw) WITH text-004.
    CLEAR : gf_data_change, gf_screen_change.
*---using in 102 load data
    gv_save = 'X'.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UNCHECK_DEPENDANT_ORGS
*&---------------------------------------------------------------------*
*       C0088 - Manual deactivation of an OrgElement must deactivate
*               dependent values as well
*       Unchecking PLANT
*           uncheck dependant ekorgs if not directly linked to bukrs
*                                    and not linked to other plant linked to this BUKRS
*           uncheck dependant shipping points if not not linked to other plant linked to this BUKRS
*       Unchecking BUKRS
*           uncheck all dependant orgs
*----------------------------------------------------------------------*
*      -->P_LS_ORG  text
*----------------------------------------------------------------------*
FORM uncheck_dependant_orgs  USING    is_org LIKE gt_organization2.


  DATA : lt_orgvalues     TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
         lt_deactivate    TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
         ls_rfc           TYPE /psyng/sw_rfcdes,
         l_system_msg(72) TYPE     c,
         l_deact          TYPE i.

  CASE is_org-varbl.
    WHEN 'WERKS'.
      LOOP AT gt_output WHERE sysid = is_org-sysid AND
                              abb   = is_org-bukrs AND
                              (
                                varbl = 'WERKS' OR
                                varbl = 'EKORG' OR
                                varbl = 'VSTEL'
                              ).
        MOVE-CORRESPONDING gt_output TO lt_orgvalues.
        lt_orgvalues-active = gt_output-check.
        lt_orgvalues-value  = gt_output-low.
        APPEND lt_orgvalues.
      ENDLOOP.
*  --Get rfc dest for system
SELECT SINGLE * FROM /psyng/sw_rfcdes INTO ls_rfc WHERE systid =  is_org-sysid.
        IF sy-subrc = 0.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
          CALL FUNCTION '/PSYNG/SW_AO_CHECK_WERKS_DEACT'
            DESTINATION ls_rfc-rfcdest
            EXPORTING
              i_bukrs               = is_org-bukrs
              i_werks               = is_org-value
            TABLES
              it_orgvalues          = lt_orgvalues
              et_deactivate         = lt_deactivate
            EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
   MESSAGE w002(/psyng/sw) WITH 'Unable to verify dependant values'(u01)
                                l_system_msg.
          ENDIF.
        ENDIF.
      WHEN 'BUKRS'.
    LOOP AT gt_output WHERE sysid = is_org-sysid AND abb = is_org-bukrs.
          MOVE-CORRESPONDING gt_output TO lt_deactivate.
          lt_deactivate-active = gt_output-check.
          lt_deactivate-value  = gt_output-low.
          APPEND lt_deactivate.
        ENDLOOP.
    ENDCASE.

*  --Now lt_deactivate has all ekorgs and vstels that should be deactivated for this company code
    LOOP AT lt_deactivate.
      CLEAR gt_output-check.
      gt_output-manual = 'X'.
      MODIFY gt_output
          TRANSPORTING check manual
          WHERE abb   = is_org-bukrs        AND
                varbl = lt_deactivate-varbl AND
                low   = lt_deactivate-value AND
                sysid = is_org-sysid.
      CLEAR gt_organization2.
      MODIFY gt_organization2 TRANSPORTING check
            WHERE  bukrs = is_org-bukrs
               AND varbl = lt_deactivate-varbl
               AND value = lt_deactivate-value
               AND sysid = is_org-sysid.
    ENDLOOP.
    l_deact = lines( lt_deactivate ).
    IF l_deact > 0.
      IF l_deact = 1.
MESSAGE s002(/psyng/sw) WITH l_deact 'Dependant value deactivated'(u03).
      ELSE.
MESSAGE s002(/psyng/sw) WITH l_deact 'Dependant values deactivated'(u02).
      ENDIF.
    ENDIF.
*  ENDIF.
ENDFORM.
