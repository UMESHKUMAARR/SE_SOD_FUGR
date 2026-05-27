*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_152_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_100 .

  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.
  IF gt_fieldcat_comp IS INITIAL.
*----Preparing field catalog.
    add_column:
    '' 'CONID' 'Conflict ID'(c23) gt_fieldcat_comp 12 ''  '' '' '',
    '' 'DESCRIPTION' 'Risk Description'(c24) gt_fieldcat_comp 200  ''  '' '' '',
    '' 'BUSAREA' 'Application'(c25)
    gt_fieldcat_comp  4 '' '' '' '',
    '' 'CONFLICTS_TOTAL' '' gt_fieldcat_comp 10 'X'  '' '' '',
    'X' 'CONFLICTS_NEW' 'New Conflicts'(c26)
       gt_fieldcat_comp  10 '' '' '' '',
    'X' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
       gt_fieldcat_comp  10 '' '' '' '',
    '' 'SENSITIVITY' 'Sensitivity'(c28) gt_fieldcat_comp 8  ''  '' '' ''.
*----Preparing layout structure
    gs_layout_comp-zebra = 'X'.
    gs_layout_comp-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort IS INITIAL.
    add_sort '1' 'CONFLICTS_NEW' '' 'X'.
    add_sort '2' 'CONFLICTS_REM' '' 'X'.
    add_sort '3' 'CONID' 'X' ''.
    add_sort '4' 'DESCRIPTION' 'X' ''.
    add_sort '5' 'BUSAREA' 'X' ''.
    add_sort '6' 'SENSITIVITY' 'X' ''.
  ENDIF.

  IF go_alvgrid_comp IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_comp
      EXPORTING
        container_name              = 'CC_ALV_COMP'
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
    CREATE OBJECT go_alvgrid_comp
      EXPORTING
        i_parent          = go_container_comp
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
    ENDIF.
    SET HANDLER gr_event_handler_comp->handle_hotspot_click
    FOR go_alvgrid_comp.
    SET HANDLER gr_event_handler_comp->handle_toolbar
    FOR go_alvgrid_comp.
    SET HANDLER gr_event_handler_comp->handle_before_user_command
    FOR go_alvgrid_comp.
*--Exclude unneeded buttons
  ls_toolbar = '&INFO'.
  APPEND ls_toolbar TO lt_toolbar.
*--Call ALV
    CALL METHOD go_alvgrid_comp->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout_comp
        it_toolbar_excluding          = lt_toolbar
      CHANGING
        it_outtab                     = gt_detail
        it_fieldcatalog               = gt_fieldcat_comp
        it_sort                       = gt_sort
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.

  IF go_html IS INITIAL.
    PERFORM init_html.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_comp                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_comp USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
        lr_role   TYPE RANGE OF agr_name,
        ls_detail TYPE /psyng/sw_kpi_new_conflicts,
        lsr_conid LIKE LINE OF lr_conid,
        lsr_role  LIKE LINE OF lr_role,
        ls_roles  TYPE /psyng/sw_sod_det_ana.
  READ TABLE gt_detail INTO ls_detail INDEX i_row_id-index.
  IF i_column_id = 'CONFLICTS_NEW'.
    CHECK NOT ls_detail-conflicts_new IS INITIAL.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      lsr_conid-low = ls_detail-conid.
      APPEND lsr_conid TO lr_conid.
*Prepare range of users
      lsr_role-sign   = 'I'.
      lsr_role-option = 'EQ'.
      LOOP AT gt_newconflict_roles INTO ls_roles
        WHERE conid = ls_detail-conid.
        lsr_role-low = ls_roles-agr_name.
        APPEND lsr_role TO lr_role.
      ENDLOOP.
      SUBMIT /psyng/sw_150
           WITH p_aid = g_latest_aid
           WITH s_conid IN lr_conid
           WITH s_role  IN lr_role
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ELSEIF i_column_id = 'CONFLICTS_REM'.
    CHECK NOT ls_detail-conflicts_rem IS INITIAL.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      lsr_conid-low = ls_detail-conid.
      APPEND lsr_conid TO lr_conid.
*Prepare range of users
      lsr_role-sign   = 'I'.
      lsr_role-option = 'EQ'.
      LOOP AT gt_remconflict_roles INTO ls_roles
        WHERE conid = ls_detail-conid.
        lsr_role-low = ls_roles-agr_name.
        APPEND lsr_role TO lr_role.
      ENDLOOP.
      SUBMIT /psyng/sw_150
           WITH p_aid = g_pre_aid
           WITH s_conid IN lr_conid
           WITH s_role IN lr_role
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INIT_HTML
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_html .
  DATA : lo_doc          TYPE REF TO cl_dd_document,
         lo_table        TYPE REF TO cl_dd_table_element,
         lo_col_key      TYPE REF TO cl_dd_area,
         lo_col_info     TYPE REF TO cl_dd_area,
         lo_col_key2     TYPE REF TO cl_dd_area,
         lo_col_info2    TYPE REF TO cl_dd_area,
         lo_col_key3     TYPE REF TO cl_dd_area,
         lo_col_info3    TYPE REF TO cl_dd_area,

         ls_latest_hdr   TYPE /psyng/swrrshdr,
         ls_pre_hdr      TYPE /psyng/swrrshdr,
         l_userdate      TYPE string,
         l_userdate_pre  TYPE string,
         l_date(10)      TYPE c,
         lt_uidn         TYPE TABLE OF /psyng/bc_uidn
                         WITH HEADER LINE,
         ls_detail       LIKE LINE OF gt_detail,
         ls_detail_role_view LIKE LINE OF gt_detail_role_view,
         l_new_con_tot   TYPE /psyng/nr_conflicts,
         l_rem_con_tot   TYPE /psyng/nr_conflicts,
         l_mac_text(255) TYPE c,
         l_vrsio_txt     TYPE /psyng/desc132,
         l_vrsio_txt_pre TYPE /psyng/desc132,
         l_res_txt       TYPE string,
         l_res_txt_pre   TYPE string.
  RANGES : r_bname FOR usr02-bname.
* Create a container for the tree control
  CREATE OBJECT go_html_cont
    EXPORTING
      container_name              = 'HTML_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
*    MESSAGE a000(/psyng/seam).
  ENDIF.
  CREATE OBJECT go_html
    EXPORTING
      parent = go_html_cont.

  CREATE OBJECT lo_doc
    EXPORTING
      style = 'ALV_GRID'.

  DEFINE add_header_line.

    l_mac_text = &1.
    condense l_mac_text.
    call method lo_col_key->add_text
      exporting text  = l_mac_text
               sap_emphasis = 'STRONG'. "#EC SAST_CI_GEN_CHECK
    call method lo_col_key->new_line.
    call method lo_col_info->add_gap exporting width  = 6.
    l_mac_text = &2.
    call method lo_col_info->add_text exporting text  = l_mac_text.
    call method lo_col_info->new_line.
    l_mac_text = &3.
    call method lo_col_key2->add_gap exporting width  = 6.

    call method lo_col_key2->add_text exporting text  = l_mac_text
                                         sap_emphasis = 'STRONG'.
    call method lo_col_key2->new_line.
    call method lo_col_info2->add_gap exporting width  = 6.
    l_mac_text = &4.
    call method lo_col_info2->add_text exporting text  = l_mac_text.
    call method lo_col_info2->new_line.

    l_mac_text = &5.
    call method lo_col_key3->add_gap exporting width  = 6.

    call method lo_col_key3->add_text exporting text  = l_mac_text
                                         sap_emphasis = 'STRONG'.
    call method lo_col_key3->new_line.
    call method lo_col_info3->add_gap exporting width  = 6.
    l_mac_text = &6.
    call method lo_col_info3->add_text exporting text  = l_mac_text.
    call method lo_col_info3->new_line.

  END-OF-DEFINITION.

*---alv header information
    SORT gt_hdr BY aid.
    READ TABLE gt_hdr INTO ls_pre_hdr
      WITH KEY aid = g_pre_aid
      BINARY SEARCH.
    READ TABLE gt_hdr INTO ls_latest_hdr
      WITH KEY aid = g_latest_aid
      BINARY SEARCH.

  IF NOT g_confv IS INITIAL.
  LOOP AT gt_detail INTO ls_detail.
    l_new_con_tot = l_new_con_tot + ls_detail-conflicts_new.
    l_rem_con_tot = l_rem_con_tot + ls_detail-conflicts_rem.
  ENDLOOP.
  ELSE.
    LOOP AT gt_detail_role_view INTO ls_detail_role_view.
      l_new_con_tot = l_new_con_tot + ls_detail_role_view-conflicts_new.
      l_rem_con_tot = l_rem_con_tot + ls_detail_role_view-conflicts_rem.
    ENDLOOP.
  ENDIF.

  WRITE ls_latest_hdr-start_date TO l_date.
  r_bname-sign = 'I'.
  r_bname-option = 'EQ'.
  r_bname-low = ls_latest_hdr-bname.
  COLLECT r_bname.
  r_bname-low = ls_pre_hdr-bname.
  COLLECT r_bname.
  CALL FUNCTION '/PSYNG/BC_011'
    TABLES
      it_bname = r_bname
      et_uidn  = lt_uidn
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             OTHERS     = 1.
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)
  READ TABLE lt_uidn WITH KEY bname = ls_latest_hdr-bname.
  CONCATENATE  ls_latest_hdr-bname '(' lt_uidn-name_text ')'
               'on' l_date
               INTO l_userdate  SEPARATED BY space.
  CLEAR l_date.

  WRITE ls_pre_hdr-start_date TO l_date.
  READ TABLE lt_uidn WITH KEY bname = ls_pre_hdr-bname.
  CONCATENATE  ls_pre_hdr-bname '(' lt_uidn-name_text ')'
               'on' l_date
               INTO l_userdate_pre  SEPARATED BY space.
  CLEAR l_date.

  CALL METHOD lo_doc->add_table
    EXPORTING
      no_of_columns = 6
      with_heading  = ' '
      border        = '0'
    IMPORTING
      table         = lo_table.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_key.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_info.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_key2.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_info2.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_key3.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_info3.
*  l_i_resid = g_latest_aid.
  l_mac_text = g_latest_aid.
  CONDENSE l_mac_text.
  SHIFT l_mac_text LEFT DELETING LEADING '0'.
  CONCATENATE l_mac_text ':' ls_latest_hdr-description INTO l_res_txt SEPARATED
                                                               BY space.
  CLEAR l_mac_text.
  l_mac_text = g_pre_aid.
  CONDENSE l_mac_text.
  SHIFT l_mac_text LEFT DELETING LEADING '0'.
  CONCATENATE l_mac_text ':' ls_pre_hdr-description INTO l_res_txt_pre SEPARATED
                                                               BY space.

*--Get version title
  SELECT SINGLE vdesc INTO l_vrsio_txt FROM /psyng/swsodvers
  WHERE vrsio = ls_latest_hdr-sodvrsio.
  CONCATENATE ls_latest_hdr-sodvrsio ':' l_vrsio_txt INTO l_vrsio_txt
              SEPARATED BY space.

*--Get version title
  SELECT SINGLE vdesc INTO l_vrsio_txt_pre FROM /psyng/swsodvers
  WHERE vrsio = ls_pre_hdr-sodvrsio.
  CONCATENATE ls_pre_hdr-sodvrsio ':' l_vrsio_txt_pre INTO l_vrsio_txt_pre
              SEPARATED BY space.

  add_header_line :
    'Latest Result ID:'(t01)     l_res_txt
    'User & Date:'(t02)          l_userdate
    'SOD Version:'(t03)          l_vrsio_txt,
*    'Total New Conflicts:'  l_new_con_tot,

    'Previous Result ID:'(t04)   l_res_txt_pre
    'User & Date:'(t02)          l_userdate_pre
    'SOD Version:'(t03)          l_vrsio_txt_pre,
*    'Total Remediated Conflicts:' l_rem_con_tot,

*    'SOD Version:'          l_vrsio_txt
*    '' '' '' ''.

    'Total New Conflicts:'(t07)  l_new_con_tot
    'Total Remediated Conflicts:'(t08) l_rem_con_tot
    '' ''.

*--display header info
  CALL METHOD lo_doc->merge_document.
  lo_doc->html_control = go_html.
  CALL METHOD lo_doc->display_document
    EXPORTING
      reuse_control      = 'X'
      parent             = go_html_cont
    EXCEPTIONS
      html_display_error = 1.
  IF sy-subrc NE 0.
     sy-subrc = 0.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NAVIGATE_TO_DETAILS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM navigate_to_details
    using
       p_conid type /psyng/conflict_id
       p_new   type flag
       p_old   type flag.
  data : ls_row      type lvc_s_row,
         l_column_id TYPE lvc_s_col,
         ls_row_no   TYPE lvc_s_roid.

  read table gt_detail with key conid = p_conid transporting no fields.
  ls_row-INDEX      = sy-tabix.
  ls_row_no-ROW_ID  = ls_row-INDEX.
  if p_new = 'X'.
    l_column_id = 'CONFLICTS_NEW'.
  else.
    l_column_id = 'CONFLICTS_REM'.
  endif.
   PERFORM handle_hotspot_click_comp
               USING
                  ls_row
                  l_column_id
                  ls_row_no.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_rolv                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_rolv USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
        lr_role   TYPE RANGE OF agr_name,
        ls_detail TYPE /psyng/sw_rolview_new_rem_conf,
        lsr_conid LIKE LINE OF lr_conid,
        lsr_role  LIKE LINE OF lr_role,
        ls_roles  TYPE /psyng/sw_sod_det_ana.
  READ TABLE gt_detail_role_view
  INTO ls_detail INDEX i_row_id-index.
  IF i_column_id = 'CONFLICTS_NEW'.
    CHECK NOT ls_detail-conflicts_new IS INITIAL.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
*Prepare range of role
      lsr_role-sign   = 'I'.
      lsr_role-option = 'EQ'.
      lsr_role-low = ls_detail-agr_name.
      APPEND lsr_role TO lr_role.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      LOOP AT gt_newconflict_roles INTO ls_roles
        WHERE agr_name = ls_detail-agr_name.
      lsr_conid-low = ls_roles-conid.
      APPEND lsr_conid TO lr_conid.
      ENDLOOP.

      SUBMIT /psyng/sw_150
           WITH p_aid = g_latest_aid
           WITH s_conid IN lr_conid
           WITH s_role  IN lr_role
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ELSEIF i_column_id = 'CONFLICTS_REM'.
    CHECK NOT ls_detail-conflicts_rem IS INITIAL.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
*Prepare range of role
      lsr_role-sign   = 'I'.
      lsr_role-option = 'EQ'.
      lsr_role-low = ls_detail-agr_name.
      APPEND lsr_role TO lr_role.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      LOOP AT gt_remconflict_roles INTO ls_roles
        WHERE agr_name = ls_detail-agr_name.
      lsr_conid-low = ls_roles-conid.
      APPEND lsr_conid TO lr_conid.
      ENDLOOP.
      SUBMIT /psyng/sw_150
           WITH p_aid = g_pre_aid
           WITH s_conid IN lr_conid
           WITH s_role IN lr_role
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_ROLV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_rolv_100.

  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.

  IF gt_fieldcat_rolv IS INITIAL.
*----Preparing field catalog.
    add_column:
    '' 'AGR_NAME' 'Role Name'(c01) gt_fieldcat_rolv 30 ''  '' '' '',
    '' 'AGR_TEXT' 'Role Description'(c02) gt_fieldcat_rolv 80  ''  '' '' '',
    'X' 'CONFLICTS_NEW' 'New Conflicts'(c26)
       gt_fieldcat_rolv  10 '' '' '' '',
    'X' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
       gt_fieldcat_rolv  10 '' '' '' ''.
*----Preparing layout structure
    gs_layout_rolv-zebra = 'X'.
    gs_layout_rolv-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort_rolv IS INITIAL.
    add_sort '1' 'CONFLICTS_NEW' '' 'X'.
    add_sort '2' 'CONFLICTS_REM' '' 'X'.
    add_sort '3' 'AGR_NAME' 'X' ''.
    add_sort '4' 'AGR_TEXT' 'X' ''.
  ENDIF.

  IF go_alvgrid_comp IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_comp
      EXPORTING
        container_name              = 'CC_ALV_COMP'
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
    CREATE OBJECT go_alvgrid_comp
      EXPORTING
        i_parent          = go_container_comp
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.

  SET HANDLER gr_event_handler_comp->handle_hotspot_click
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_toolbar
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_before_user_command
  FOR go_alvgrid_comp.
*--Exclude unneeded buttons
  ls_toolbar = '&INFO'.
  APPEND ls_toolbar TO lt_toolbar.
*--Call ALV
  CALL METHOD go_alvgrid_comp->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout_rolv
      it_toolbar_excluding          = lt_toolbar
    CHANGING
      it_outtab                     = gt_detail_role_view
      it_fieldcatalog               = gt_fieldcat_rolv
      it_sort                       = gt_sort_rolv
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

  IF go_html IS INITIAL.
    PERFORM init_html.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM handle_toolbar                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar USING
 i_object TYPE REF TO cl_alv_event_toolbar_set
 i_interactive.

  DATA: ls_toolbar  TYPE stb_button.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'SWITCH' TO ls_toolbar-function.
  MOVE 'Switch View'(c05) TO ls_toolbar-text.
  MOVE 'Switch User/Conflict View'(c06)
  TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  APPEND ls_toolbar TO i_object->mt_toolbar.

*Begin of Addition AKUMAR PN15658 12-11-2025
  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'SWITCHD' TO ls_toolbar-function.
  MOVE 'Switch Detail View'(c07) TO ls_toolbar-text.
  MOVE 'Switch User/Conflict View'(c08)
  TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  APPEND ls_toolbar TO i_object->mt_toolbar.
*End of Addition AKUMAR 12-11-2025

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'SELECT' TO ls_toolbar-function.
  MOVE 'Change Selection Criteria'(t18) TO ls_toolbar-text.
  MOVE 'Change Selection Criteria'(t18)
  TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  APPEND ls_toolbar TO i_object->mt_toolbar.

ENDFORM .
*&---------------------------------------------------------------------*
*&      Form  CHANGE_SELECTION_CRITERIA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM change_selection_criteria .

  DATA: lt_seltable TYPE TABLE OF rsparams.

  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
    EXPORTING
      curr_report               = sy-repid
    TABLES
      selection_table           = lt_seltable
   EXCEPTIONS
     not_found                 = 1
     no_report                 = 2
     OTHERS                    = 3
            .
  IF sy-subrc EQ 0.
* Implement suitable error handling here
    SUBMIT /psyng/sw_153
      WITH SELECTION-TABLE lt_seltable
      VIA SELECTION-SCREEN.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_DROLV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_drolv_100 .

  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.

  IF gt_fieldcat_drolv IS INITIAL.
*----Preparing field catalog.
    add_column:
    '' 'AGR_NAME' 'Role Name'(c01) gt_fieldcat_drolv 30 ''  '' '' '',
    '' 'AGR_TEXT' 'Role Description'(c02) gt_fieldcat_drolv 80  ''  '' '' '',
    '' 'CONFLICTS_NEW' 'New Conflicts'(c26)
       gt_fieldcat_drolv  12 '' '' '' '',
    '' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
       gt_fieldcat_drolv  12 '' '' '' ''.
*----Preparing layout structure
    gs_layout_rolv-zebra = 'X'.
    gs_layout_rolv-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort_drolv IS INITIAL.
    add_sort '1' 'CONFLICTS_NEW' '' 'X'.
    add_sort '2' 'CONFLICTS_REM' '' 'X'.
    add_sort '3' 'AGR_NAME' 'X' ''.
    add_sort '4' 'AGR_TEXT' 'X' ''.
  ENDIF.

IF go_alvgrid_comp IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_comp
      EXPORTING
        container_name              = 'CC_ALV_COMP'
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
    CREATE OBJECT go_alvgrid_comp
      EXPORTING
        i_parent          = go_container_comp
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.

  SET HANDLER gr_event_handler_comp->handle_hotspot_click
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_toolbar
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_before_user_command
  FOR go_alvgrid_comp.
*--Exclude unneeded buttons
  ls_toolbar = '&INFO'.
  APPEND ls_toolbar TO lt_toolbar.
*--Call ALV
  CALL METHOD go_alvgrid_comp->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout_rolv
      it_toolbar_excluding          = lt_toolbar
    CHANGING
      it_outtab                     = gt_role_new_rem_con
      it_fieldcatalog               = gt_fieldcat_drolv
      it_sort                       = gt_sort_drolv
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_DCONFV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_dconfv_100 .

DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.

  IF gt_fieldcat_dconfv IS INITIAL.
*----Preparing field catalog.
    add_column:
    '' 'CONID' 'Conflict ID'(c23) gt_fieldcat_dconfv 12 ''  '' '' '',
    '' 'DESCRIPTION' 'Risk Description'(c24) gt_fieldcat_dconfv 200  ''  '' '' '',
    '' 'BUSAREA' 'Application'(c25)
   gt_fieldcat_dconfv  4 '' '' '' '',
*    '' 'CONFLICTS_TOTAL' '' gt_fieldcat_dconfv 10 'X'  '' '' '',
    '' 'ROLE_NEW' 'New Role'(c29)
       gt_fieldcat_dconfv  30 '' '' '' '',
    '' 'ROLE_REM' 'Remediated Role'(c30)
       gt_fieldcat_dconfv  30 '' '' '' '',
    '' 'SENSITIVITY' 'Sensitivity'(c28) gt_fieldcat_dconfv 8  ''  '' '' ''.
*----Preparing layout structure
    gs_layout_comp-zebra = 'X'.
    gs_layout_comp-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort_dconfv IS INITIAL.
    add_sort '1' 'CONFLICTS_NEW' '' 'X'.
    add_sort '2' 'CONFLICTS_REM' '' 'X'.
    add_sort '3' 'CONID' 'X' ''.
    add_sort '4' 'DESCRIPTION' 'X' ''.
    add_sort '5' 'BUSAREA' 'X' ''.
    add_sort '6' 'SENSITIVITY' 'X' ''.
  ENDIF.

  IF go_alvgrid_comp IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_comp
      EXPORTING
        container_name              = 'CC_ALV_COMP'
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
    CREATE OBJECT go_alvgrid_comp
      EXPORTING
        i_parent          = go_container_comp
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
    ENDIF.
    SET HANDLER gr_event_handler_comp->handle_hotspot_click
    FOR go_alvgrid_comp.
    SET HANDLER gr_event_handler_comp->handle_toolbar
    FOR go_alvgrid_comp.
    SET HANDLER gr_event_handler_comp->handle_before_user_command
    FOR go_alvgrid_comp.
*--Exclude unneeded buttons
  ls_toolbar = '&INFO'.
  APPEND ls_toolbar TO lt_toolbar.
*--Call ALV
    CALL METHOD go_alvgrid_comp->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout_comp
        it_toolbar_excluding          = lt_toolbar
      CHANGING
        it_outtab                     = gt_con_new_rem_role
        it_fieldcatalog               = gt_fieldcat_dconfv
        it_sort                       = gt_sort_dconfv
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.


ENDFORM.
