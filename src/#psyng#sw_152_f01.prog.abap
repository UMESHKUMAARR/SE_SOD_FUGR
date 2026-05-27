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
gc_space 'CONID' 'Conflict ID'(c23) gt_fieldcat_comp 12 gc_space  gc_space gc_space gc_space,
gc_space 'DESCRIPTION' 'Risk Description'(c24) gt_fieldcat_comp 200  gc_space  gc_space gc_space gc_space,
gc_space 'BUSAREA' 'Application'(c25)
gt_fieldcat_comp  4 gc_space gc_space gc_space gc_space,
gc_space 'CONFLICTS_TOTAL' gc_space gt_fieldcat_comp 10 'X'  gc_space gc_space gc_space,
'X' 'CONFLICTS_NEW' 'New Conflicts'(c26)
gt_fieldcat_comp  10 gc_space gc_space gc_space gc_space,
'X' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
gt_fieldcat_comp  10 gc_space gc_space gc_space gc_space,
gc_space 'SENSITIVITY' 'Sensitivity'(c28) gt_fieldcat_comp 8  gc_space  gc_space gc_space gc_space.
*----Preparing layout structure
    gs_layout-zebra = 'X'.
    gs_layout-cwidth_opt = 'X'.
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
*--Exclude unneeded buttons
  ls_toolbar = '&INFO'.
  APPEND ls_toolbar TO lt_toolbar.

  SET HANDLER gr_event_handler_comp->handle_hotspot_click
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_toolbar
  FOR go_alvgrid_comp.
  SET HANDLER gr_event_handler_comp->handle_before_user_command
  FOR go_alvgrid_comp.
*--Call ALV
  CALL METHOD go_alvgrid_comp->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
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
i_column_id TYPE lvc_s_col.

  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
        lr_bname  TYPE RANGE OF xubname,
        ls_detail TYPE /psyng/sw_kpi_new_conflicts,
        lsr_conid LIKE LINE OF lr_conid,
        lsr_bname LIKE LINE OF lr_bname,
        ls_users  TYPE /psyng/sw_sod_det_ana.
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
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      LOOP AT gt_newconflict_users INTO ls_users
        WHERE conid = ls_detail-conid.
        lsr_bname-low = ls_users-bname.
        APPEND lsr_bname TO lr_bname.
      ENDLOOP.
      SUBMIT /psyng/sw_137
           WITH p_aid = g_latest_aid
           WITH s_conid IN lr_conid
           WITH s_bname IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
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
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      LOOP AT gt_remconflict_users INTO ls_users
        WHERE conid = ls_detail-conid.
        lsr_bname-low = ls_users-bname.
        APPEND lsr_bname TO lr_bname.
      ENDLOOP.
      SUBMIT /psyng/sw_137
           WITH p_aid = g_pre_aid
           WITH s_conid IN lr_conid
           WITH s_bname IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun = ' '
           WITH p_orgvar = 'X'
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
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

         ls_latest_hdr   TYPE /psyng/swreshdr,
         ls_pre_hdr      TYPE /psyng/swreshdr,
         l_userdate      TYPE string,
         l_userdate_pre  TYPE string,
         l_date(10)      TYPE c,
         lt_uidn         TYPE TABLE OF /psyng/bc_uidn
                         WITH HEADER LINE,
         ls_detail       LIKE LINE OF gt_detail,
         ls_detail_user_view LIKE LINE OF gt_detail_user_view,
         l_new_con_tot   TYPE /psyng/nr_conflicts,
         l_rem_con_tot   TYPE /psyng/nr_conflicts,
         l_mac_text(255) TYPE c,
*         l_i_resid       TYPE i,
*         l_i_setid       TYPE i,
         l_vrsio_txt     TYPE /psyng/desc132,
         l_vrsio_txt_pre TYPE /psyng/desc132,
         l_res_txt       TYPE string,
         l_res_txt_pre   TYPE string.
*         l_set_pub       TYPE string,
*         l_set_chg       TYPE /psyng/desc132,
*         l_set_txt       TYPE /psyng/desc132,
*         ls_cfg_set      TYPE /psyng/swcfgset.
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
                 sap_emphasis = 'STRONG'.  "#EC SAST_CI_GEN_CHECK
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
*  SELECT *
*    FROM /psyng/swreshdr
*    INTO TABLE lt_hdr
*    WHERE aid EQ g_latest_aid
*       OR aid EQ g_pre_aid.
*  IF sy-subrc EQ 0.
  SORT gt_hdr BY aid.
  READ TABLE gt_hdr INTO ls_pre_hdr
    WITH KEY aid = g_pre_aid
    BINARY SEARCH.
  READ TABLE gt_hdr INTO ls_latest_hdr
    WITH KEY aid = g_latest_aid
    BINARY SEARCH.
*  ENDIF.
  IF g_view EQ 'C' OR g_view EQ 'UC'.
    LOOP AT gt_detail INTO ls_detail.
      l_new_con_tot = l_new_con_tot + ls_detail-conflicts_new.
      l_rem_con_tot = l_rem_con_tot + ls_detail-conflicts_rem.
    ENDLOOP.
  ELSEIF g_view EQ 'U'.
    LOOP AT gt_detail_user_view INTO ls_detail_user_view.
      l_new_con_tot = l_new_con_tot + ls_detail_user_view-conflicts_new.
      l_rem_con_tot = l_rem_con_tot + ls_detail_user_view-conflicts_rem.
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

    'Total New Conflicts:'(t05)  l_new_con_tot
    'Total Remediated Conflicts:'(t06) l_rem_con_tot
    '' ''.

*    'Total new conflicts found in Latest Result ID:' l_new_con_tot
*    '' '',
*
*    'Total remediated conflicts which were present in Previous Result ID:' l_rem_con_tot
*    '' ''.

*    'Configuration Set:'    l_set_txt
*    'Conflicts:'            gs_hdr-conflicts,
*
*    'Config Set Published:' l_set_pub
*    ''                      '',
*    'Config Set Changed:'   l_set_chg
*    ''                      ''.
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

FORM navigate_to_details
    USING
       p_conid TYPE /psyng/conflict_id
       p_new   TYPE flag
       p_old   TYPE flag.
  DATA : ls_row      TYPE lvc_s_row,
         l_column_id TYPE lvc_s_col.
*         ls_row_no   TYPE lvc_s_roid.

  READ TABLE gt_detail WITH KEY conid = p_conid TRANSPORTING NO FIELDS.
  ls_row-index      = sy-tabix.
*  ls_row_no-row_id  = ls_row-index.
  IF p_new = 'X'.
    l_column_id = 'CONFLICTS_NEW'.
  ELSE.
    l_column_id = 'CONFLICTS_REM'.
  ENDIF.
  PERFORM handle_hotspot_click_comp
              USING
                 ls_row
                 l_column_id.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_usrv                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_usrv USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col.

  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
        lr_bname  TYPE RANGE OF xubname,
        ls_detail TYPE /psyng/sw_usrview_new_rem_conf,
        lsr_conid LIKE LINE OF lr_conid,
        lsr_bname LIKE LINE OF lr_bname,
        ls_users  TYPE /psyng/sw_sod_det_ana.

  READ TABLE gt_detail_user_view
  INTO ls_detail INDEX i_row_id-index.
*--prepare user type
*   perform usr_type .

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
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      lsr_bname-low = ls_detail-bname.
      APPEND lsr_bname TO lr_bname.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      LOOP AT gt_newconflict_users INTO ls_users
        WHERE bname = ls_detail-bname.
        lsr_conid-low = ls_users-conid.
        APPEND lsr_conid TO lr_conid.
      ENDLOOP.

      SUBMIT /psyng/sw_137
           WITH p_aid = g_latest_aid
           WITH s_conid  IN lr_conid
           WITH s_bname  IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun    = ' '
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
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
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      lsr_bname-low = ls_detail-bname.
      APPEND lsr_bname TO lr_bname.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      LOOP AT gt_remconflict_users INTO ls_users
        WHERE bname = ls_detail-bname.
        lsr_conid-low = ls_users-conid.
        APPEND lsr_conid TO lr_conid.
      ENDLOOP.
      SUBMIT /psyng/sw_137
           WITH p_aid = g_pre_aid
           WITH s_conid IN lr_conid
           WITH s_bname IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun = ' '
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ALV_USRV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_usrv_100.

  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func.

  IF gt_fieldcat_usrv IS INITIAL.
*----Preparing field catalog.
    add_column:
gc_space 'BNAME' 'User'(c01) gt_fieldcat_usrv 12 gc_space  gc_space gc_space gc_space,
gc_space 'FULLNAME' 'User Name'(c02) gt_fieldcat_usrv 80  gc_space  gc_space gc_space gc_space,
gc_space 'USERGROUP' 'User Group'(c03)
gt_fieldcat_usrv  12 gc_space gc_space gc_space gc_space,
gc_space 'USERGROUPNAME' 'User Group Name'(c04)
gt_fieldcat_usrv  60 gc_space gc_space gc_space gc_space,
gc_space 'CONFLICTS_TOTAL' gc_space gt_fieldcat_usrv 10 'X'  gc_space gc_space gc_space,
'X' 'CONFLICTS_NEW' 'New Conflicts'(c26)
gt_fieldcat_usrv  10 gc_space gc_space gc_space gc_space,
'X' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
gt_fieldcat_usrv  10 gc_space gc_space gc_space gc_space.
*----Preparing layout structure
    gs_layout-zebra = 'X'.
    gs_layout-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort_usrv IS INITIAL.
    add_sort '1' 'CONFLICTS_NEW' '' 'X'.
    add_sort '2' 'CONFLICTS_REM' '' 'X'.
    add_sort '3' 'BNAME' 'X' ''.
    add_sort '4' 'FULLNAME' 'X' ''.
    add_sort '5' 'USERGROUP' 'X' ''.
    add_sort '6' 'USERGROUPNAME' 'X' ''.
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
      is_layout                     = gs_layout
      it_toolbar_excluding          = lt_toolbar
    CHANGING
      it_outtab                     = gt_detail_user_view
      it_fieldcatalog               = gt_fieldcat_usrv
      it_sort                       = gt_sort_usrv
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
 i_object TYPE REF TO cl_alv_event_toolbar_set.

  DATA: ls_toolbar  TYPE stb_button.

*  CLEAR ls_toolbar.
*  MOVE 0 TO ls_toolbar-butn_type.
*  MOVE 'SWITCH' TO ls_toolbar-function.
*  MOVE 'Switch View'(c05) TO ls_toolbar-text.
*  MOVE 'Switch User/Conflict View'(c06)
*  TO ls_toolbar-quickinfo.
*  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
*  APPEND ls_toolbar TO i_object->mt_toolbar.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'UVIEW' TO ls_toolbar-function.
  MOVE 'User View'(t08) TO ls_toolbar-text.
  MOVE 'Switch to user view'(t09)
  TO ls_toolbar-quickinfo.
  IF g_view EQ 'U'.
    MOVE 'X' TO ls_toolbar-disabled.                        "#EC NOTEXT
  ENDIF.
  APPEND ls_toolbar TO i_object->mt_toolbar.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'CVIEW' TO ls_toolbar-function.
  MOVE 'Conflict View'(t10) TO ls_toolbar-text.
  MOVE 'Switch to Conflict view'(t11)
  TO ls_toolbar-quickinfo.
  IF g_view EQ 'C'.
    MOVE 'X' TO ls_toolbar-disabled.                        "#EC NOTEXT
  ENDIF.
  APPEND ls_toolbar TO i_object->mt_toolbar.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'UCVIEW' TO ls_toolbar-function.
  MOVE 'User Conflict View'(t12) TO ls_toolbar-text.
  MOVE 'Switch to User Conflict view'(t13)
  TO ls_toolbar-quickinfo.
  IF g_view EQ 'UC'.
    MOVE 'X' TO ls_toolbar-disabled.                        "#EC NOTEXT
  ENDIF.
  APPEND ls_toolbar TO i_object->mt_toolbar.

*--In user conflict view; button to hide conflicts identified in both analysis
  IF g_view EQ 'UC'.
    CLEAR ls_toolbar.
    MOVE 0 TO ls_toolbar-butn_type.
    MOVE 'HIDE' TO ls_toolbar-function.
    IF g_hide IS INITIAL.
   MOVE 'Hide Conflicts found in both analysis'(t15) TO ls_toolbar-text.
      MOVE 'Hide Conflicts'(t14)
      TO ls_toolbar-quickinfo.
    ELSE.
   MOVE 'Show Conflicts found in both analysis'(t16) TO ls_toolbar-text.
      MOVE 'Show Conflicts'(t17)
      TO ls_toolbar-quickinfo.
    ENDIF.
    APPEND ls_toolbar TO i_object->mt_toolbar.
  ENDIF.

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
*&      Form  DISPLAY_ALV_USRCONV_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_usrconv_100
  TABLES it_detail_usrcon_view LIKE gt_detail_usrcon_view.
  DATA: lt_toolbar TYPE ui_functions,
        ls_toolbar TYPE ui_func,
        l_pre_aid  TYPE c LENGTH 22,
        l_latest_aid  TYPE c LENGTH 22.

  IF gt_fieldcat_usrconv IS INITIAL.
    l_pre_aid = g_pre_aid.
    SHIFT l_pre_aid LEFT DELETING LEADING '0'.
    l_latest_aid = g_latest_aid.
    SHIFT l_latest_aid LEFT DELETING LEADING '0'.
    CONCATENATE 'Result-ID'(t07) l_pre_aid  INTO l_pre_aid
    SEPARATED BY space.
    CONCATENATE 'Result-ID'(t07) l_latest_aid  INTO l_latest_aid
    SEPARATED BY space.
*----Preparing field catalog.
    add_column:
gc_space 'BNAME' 'User'(c01) gt_fieldcat_usrconv 12 gc_space  gc_space gc_space gc_space,
gc_space 'CONID' 'Conflict ID'(c23) gt_fieldcat_usrconv 12  gc_space  gc_space gc_space gc_space,
gc_space 'DESCRIPTION' 'Risk Description'(c24) gt_fieldcat_usrconv 200  gc_space  gc_space gc_space gc_space,
'X' 'PRE_AID' l_pre_aid
gt_fieldcat_usrconv  16 gc_space gc_space gc_space gc_space,
'X' 'LAT_AID' l_latest_aid
gt_fieldcat_usrconv  16 gc_space gc_space gc_space gc_space.
*----Preparing layout structure
    gs_layout-zebra = 'X'.
    gs_layout-cwidth_opt = 'X'.
  ENDIF.

  IF gt_sort_usrconv IS INITIAL.
    add_sort '1' 'BNAME' 'X' ''.
    add_sort '2' 'CONID' 'X' ''.
    add_sort '3' 'DESCRIPTION' 'X' ''.
    add_sort '4' 'PRE_AID' 'X' ''.
    add_sort '5' 'LAT_AID' 'X' ''.
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
      is_layout                     = gs_layout
      it_toolbar_excluding          = lt_toolbar
    CHANGING
      it_outtab                     = it_detail_usrcon_view[]
      it_fieldcatalog               = gt_fieldcat_usrconv
      it_sort                       = gt_sort_usrconv
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
*&---------------------------------------------------------------------*
*&      Form  HANDLE_HOTSPOT_CLICK_USRCONV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->I_ROW_ID  text
*      -->I_COLUMN_ID  text
*----------------------------------------------------------------------*
FORM handle_hotspot_click_usrconv USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col.

  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
        lr_bname  TYPE RANGE OF xubname,
        ls_detail TYPE /psyng/sw_botview_new_rem_conf,
        lsr_conid LIKE LINE OF lr_conid,
        lsr_bname LIKE LINE OF lr_bname,
        ls_users  TYPE /psyng/sw_sod_det_ana.
* OPL501 ARPAN 13.04.2023 START
  IF g_hide IS INITIAL.
    READ TABLE gt_detail_usrcon_view
    INTO ls_detail INDEX i_row_id-index.
  ELSE.
    READ TABLE gt_detail_usrcon_view_hide
INTO ls_detail INDEX i_row_id-index.
  ENDIF.
* OPL501 ARPAN 13.04.2023 END
*--prepare user type
*   perform usr_type .
  IF i_column_id = 'PRE_AID'.
    CHECK ls_detail-pre_aid EQ gc_con_identified.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      lsr_bname-low = ls_detail-bname.
      APPEND lsr_bname TO lr_bname.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      lsr_conid-low = ls_detail-conid.
      APPEND lsr_conid TO lr_conid.
      SUBMIT /psyng/sw_137
           WITH p_aid = g_pre_aid
           WITH s_conid  IN lr_conid
           WITH s_bname  IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun    = ' '
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ELSEIF i_column_id = 'LAT_AID'.
    CHECK ls_detail-lat_aid EQ gc_con_identified.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      lsr_bname-sign   = 'I'.
      lsr_bname-option = 'EQ'.
      lsr_bname-low = ls_detail-bname.
      APPEND lsr_bname TO lr_bname.
*Prepare range of conflicts
      lsr_conid-sign   = 'I'.
      lsr_conid-option = 'EQ'.
      lsr_conid-low = ls_detail-conid.
      APPEND lsr_conid TO lr_conid.
      SUBMIT /psyng/sw_137
           WITH p_aid = g_latest_aid
           WITH s_conid IN lr_conid
           WITH s_bname IN lr_bname
           WITH validusr = ' '
           WITH usrtype  IN gr_usrtype
           WITH p_fun = ' '
           WITH p_gclass = ' '
           WITH p_gkostl = ' '
           WITH p_gcomp  = ' '
           WITH p_gdep   = ' '
           WITH p_nogrp  = 'X'
           WITH p_orgvar = 'X'
           AND RETURN.
    ENDIF.
  ENDIF.

ENDFORM.
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
    SUBMIT /psyng/sw_152
      WITH SELECTION-TABLE lt_seltable
      VIA SELECTION-SCREEN.
  ENDIF.

ENDFORM.
