*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_FIORIAF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  fieldcatalog_services
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fieldcatalog_services.

  DATA: ls_field_cat TYPE lvc_s_fcat.
*----Preparing layout structure
  gs_layout_services-zebra      = 'X'.
  gs_layout_services-cwidth_opt = 'X'.
  IF gf_edit IS INITIAL.
    gs_layout_services-no_toolbar = 'X'.
  ENDIF.
*----Preparing field catalog

  ls_field_cat-fieldname = 'PROJECT'.
  ls_field_cat-tabname   = 'GT_ODATA'.
  ls_field_cat-coltext   = 'Odata Service'(t01).
  ls_field_cat-col_pos   = 1.
  ls_field_cat-f4availabl = 'X'.
  ls_field_cat-ref_field = 'PROJECT'.
  ls_field_cat-ref_table = '/IWBEP/I_SBD_PR'.
  ls_field_cat-rollname = '/IWBEP/SBDM_PROJECT'.
  ls_field_cat-dd_roll = '/IWBEP/SBDM_PROJECT'.
  IF NOT gf_edit IS INITIAL.
    ls_field_cat-edit    = 'X'.
  ENDIF.
  APPEND ls_field_cat TO gt_field_cat_services.
  CLEAR ls_field_cat.

  ls_field_cat-fieldname = 'ODATASERVICEVERS'.
  ls_field_cat-tabname   = 'GT_ODATA'.
  ls_field_cat-coltext   = 'Version'(t02).
  ls_field_cat-col_pos   = 2.
  IF NOT gf_edit IS INITIAL.
    ls_field_cat-edit    = 'X'.
  ENDIF.
  APPEND ls_field_cat TO gt_field_cat_services.
  CLEAR ls_field_cat.

  ls_field_cat-fieldname = 'SU24'.
  ls_field_cat-tabname   = 'GT_ODATA'.
  ls_field_cat-coltext   = 'SU24'(t03).
  ls_field_cat-col_pos   = 3.
  ls_field_cat-hotspot   = 'X'.
  APPEND ls_field_cat TO gt_field_cat_services.

ENDFORM.                    " fieldcatalog_services
*&---------------------------------------------------------------------*
*&      Form  display_alv_services
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_services.

  DATA: ls_stable   TYPE lvc_s_stbl.
  IF go_alvgrid_services IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_services
      EXPORTING
        container_name              = 'CC_ALV_SER'
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
    CREATE OBJECT go_alvgrid_services
      EXPORTING
        i_parent          = go_container_services
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
**Exclude toolbar buttons
*    PERFORM exculde_toolbar.

    SET HANDLER go_event_handler->handle_hotspot_click
    FOR go_alvgrid_services.

    SET HANDLER go_event_handler->data_changed_finished
    FOR go_alvgrid_services.

    SET HANDLER go_event_handler->data_changed
    FOR go_alvgrid_services.

    CALL METHOD go_alvgrid_services->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

    CALL METHOD go_alvgrid_services->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

*--Call ALV
    CALL METHOD go_alvgrid_services->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout_services
        it_toolbar_excluding          = gt_exc_toolbar
      CHANGING
        it_outtab                     = gt_odata
        it_fieldcatalog               = gt_field_cat_services
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE.
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD go_alvgrid_services->refresh_table_display
      EXPORTING
        i_soft_refresh = 'X'
        is_stable      = ls_stable
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2.
  ENDIF .

ENDFORM.                    " display_alv_services
*&---------------------------------------------------------------------*
*&      Form  display_alv_notes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_notes.

  DATA: ls_stable   TYPE lvc_s_stbl.
  IF go_alvgrid_notes IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_notes
      EXPORTING
        container_name              = 'CC_ALV_NOTES'
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
    CREATE OBJECT go_alvgrid_notes
      EXPORTING
        i_parent          = go_container_notes
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*Exclude toolbar buttons
    PERFORM exculde_toolbar.

    SET HANDLER go_event_notes->data_changed_finished
    FOR go_alvgrid_notes.

    SET HANDLER go_event_notes->data_changed
    FOR go_alvgrid_notes.

    CALL METHOD go_alvgrid_notes->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

    CALL METHOD go_alvgrid_notes->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.

*--Call ALV
    CALL METHOD go_alvgrid_notes->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout_notes
        it_toolbar_excluding          = gt_exc_toolbar
        it_hyperlink                  = gt_hype
      CHANGING
        it_outtab                     = gt_notes
        it_fieldcatalog               = gt_field_cat_notes
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ELSE.
    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD go_alvgrid_notes->refresh_table_display
      EXPORTING
        i_soft_refresh = 'X'
        is_stable      = ls_stable
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2.
  ENDIF .

ENDFORM.                    " display_alv_notes
*&---------------------------------------------------------------------*
*&      Form  fieldcatalog_notes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fieldcatalog_notes.

  DATA: ls_field_cat TYPE lvc_s_fcat.
*----Preparing layout structure
  gs_layout_notes-zebra      = 'X'.
  gs_layout_notes-cwidth_opt = 'X'.
  IF gf_edit IS INITIAL.
    gs_layout_notes-no_toolbar = 'X'.
  ENDIF.
*----Preparing field catalog
  ls_field_cat-fieldname = 'NOTE'.
  ls_field_cat-tabname   = 'GT_NOTES'.
  ls_field_cat-coltext   = 'Note nr'(t04).
  ls_field_cat-col_pos    = 1.
  IF NOT gf_edit IS INITIAL.
    ls_field_cat-edit    = 'X'.
  ENDIF.
  APPEND ls_field_cat TO gt_field_cat_notes.
  CLEAR ls_field_cat.
  ls_field_cat-fieldname = 'LINK'.
  ls_field_cat-tabname   = 'GT_NOTES'.
  ls_field_cat-coltext   = 'Link'(t05).
  ls_field_cat-col_pos   = 2.
  ls_field_cat-web_field = 'LINK_HANDLE'.
  APPEND ls_field_cat TO gt_field_cat_notes.
  CLEAR ls_field_cat.

ENDFORM.                    " fieldcatalog_notes
*&---------------------------------------------------------------------*
*&      Form  load_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_data.
  DATA: ls_fioritext  TYPE /psyng/sw_fiorit,
        ls_fioriodata TYPE /psyng/sw_fiorio,
        ls_fiorinote  TYPE /psyng/sw_fiorin,
        ls_odata      TYPE ty_odata,
        ls_notes      TYPE ty_notes,
        ls_text       TYPE ty_text.

  CLEAR: gs_fiori_id_name, /psyng/sw_fiorit.
  REFRESH gt_text.
  READ TABLE gt_fioriapp INTO /psyng/sw_fioria INDEX 1.
  IF sy-subrc EQ 0.
*--Build Fiori ID and name
    CONCATENATE /psyng/sw_fioria-fioriid /psyng/sw_fioria-appname
    INTO gs_fiori_id_name SEPARATED BY ' - '.
*--Read description of technical catalog
*##WARN_OK
    READ TABLE gt_fioritext INTO /psyng/sw_fiorit
    WITH KEY fioriid   = /psyng/sw_fioria-fioriid
             textfield = 'TECCATDESC'
             linenr    = 1.
*--Read description of business role
*##WARN_OK
    READ TABLE gt_fioritext INTO ls_fioritext
    WITH KEY fioriid   = /psyng/sw_fioria-fioriid
             textfield = 'BUSROLDESC'
             linenr    = 1.
    IF sy-subrc EQ 0.
      gs_role_desc = ls_fioritext-text.
    ENDIF.
*--Build description text of app Id
    LOOP AT gt_fioritext INTO ls_fioritext
    WHERE fioriid   = /psyng/sw_fioria-fioriid
      AND textfield = 'APPDESC'.
      CONCATENATE ls_text ls_fioritext-text INTO ls_text.
    ENDLOOP.
    WHILE sy-subrc EQ 0.
      REPLACE '\n' INTO ls_text WITH cl_abap_char_utilities=>cr_lf.
    ENDWHILE.
    APPEND ls_text TO gt_text.

  ENDIF.

*--Load Odata ALV table
  REFRESH gt_odata.
  LOOP AT gt_fioriodata INTO ls_fioriodata.
    MOVE-CORRESPONDING ls_fioriodata TO ls_odata.
    ls_odata-project = ls_fioriodata-odataservicename.
    ls_odata-su24 = 'SU24'.
    APPEND ls_odata TO gt_odata.
  ENDLOOP.

  REFRESH gt_notes.
*--Load Notes ALV table
  LOOP AT gt_fiorinote INTO ls_fiorinote.
    ls_notes-note = ls_fiorinote-note.
    ls_notes-link = ls_fiorinote-note.
    APPEND ls_notes TO gt_notes.
  ENDLOOP.

*--Build URL for more info
  CONCATENATE
  'https://fioriappslibrary.hana.ondemand'(t06)
  '.com/sap/fix/externalViewer/#?appId='(t07)
  /psyng/sw_fioria-fioriid
  INTO gs_more_info_url.

*--Fill Hyperlink Table
  PERFORM fill_hyperlink.

ENDFORM.                    " load_data
*&---------------------------------------------------------------------*
*&      Form  display_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_text.

  IF go_text_editor IS INITIAL.

    CREATE OBJECT go_container_text EXPORTING container_name = 'CCTEXT'.

    CREATE OBJECT go_text_editor
      EXPORTING
        parent                     = go_container_text
        wordwrap_mode              =
                                     cl_gui_textedit=>wordwrap_at_fixed_position
        wordwrap_position          = 116
        wordwrap_to_linebreak_mode = cl_gui_textedit=>true.
  ENDIF.

  CALL METHOD go_text_editor->set_toolbar_mode
    EXPORTING
      toolbar_mode           = cl_gui_textedit=>false
    EXCEPTIONS
      error_cntl_call_method = 1
      invalid_parameter      = 2
      OTHERS                 = 3.
  IF sy-subrc <> 0.
  ENDIF.

  CALL METHOD go_text_editor->set_text_as_stream
    EXPORTING
      text            = gt_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
  ENDIF.

  IF gf_edit IS INITIAL.
    CALL METHOD go_text_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>true
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
    ENDIF.
  ELSE.
    CALL METHOD go_text_editor->set_readonly_mode
      EXPORTING
        readonly_mode          = cl_gui_textedit=>false
      EXCEPTIONS
        error_cntl_call_method = 1
        invalid_parameter      = 2
        OTHERS                 = 3.
    IF sy-subrc <> 0.
    ENDIF.
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

ENDFORM.                    " display_text
*&---------------------------------------------------------------------*
*&      Form  fill_hyperlink
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_hyperlink.

  DATA: ls_hype TYPE lvc_s_hype,
        l_count TYPE int4.
  FIELD-SYMBOLS: <fs_notes> TYPE ty_notes.
  REFRESH gt_hype.
  LOOP AT gt_notes ASSIGNING <fs_notes>.
    ADD 1 TO l_count.
    <fs_notes>-link_handle = l_count.
    ls_hype-handle = l_count.
    CONCATENATE
    'https://launchpad.support.sap.com/#/notes/'(t08)
    <fs_notes>-note INTO
    ls_hype-href.
    APPEND ls_hype TO gt_hype.
  ENDLOOP.

ENDFORM.                    " fill_hyperlink
*---------------------------------------------------------------------*
*       FORM handle_hotspot_click                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click USING i_row_id TYPE lvc_s_row.

  DATA: ls_odata      TYPE ty_odata,
        ls_hash_value TYPE ty_hash_value,
        l_tabname     TYPE tabname,
        l_name        TYPE char40.

  READ TABLE gt_odata INTO ls_odata INDEX i_row_id-index.
*- Check existence and Find Function Group
  CALL FUNCTION '/PSYNG/BC_FUNCTION_EXISTS'
    EXPORTING
      funcname           = gc_fname
    EXCEPTIONS
      function_not_exist = 1
      OTHERS             = 2.
  IF sy-subrc EQ 0.
*--Check if DB table exists
    SELECT SINGLE tabname
    INTO l_tabname
    FROM dd02l
    WHERE tabname  = gc_tabname
      AND as4local = 'A'
      AND as4vers  = '0000'. "#EC SAST_CI_GEN_CHECK
    IF sy-subrc EQ 0.
*--Get technical hashcode
      CONCATENATE ls_odata-project
                  '%'
                  ls_odata-odataservicevers
                  '%'
             INTO l_name.
      SELECT name type
      FROM (gc_tabname) "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)
      INTO ls_hash_value
      UP TO 1 ROWS
      WHERE obj_name LIKE l_name.
      ENDSELECT.
*--check if service exists in system
      IF NOT ls_hash_value-name IS INITIAL.
*--Check authority check for transaction SU24
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU24'.
        IF sy-subrc <> 0.
          MESSAGE i077(s#) WITH 'SU24'.
        ELSE.
CALL FUNCTION gc_fname "#EC PATHLOCK_CI_DYN_ACCES  "##FM_SUBRC_OK
            EXPORTING
              i_name           = ls_hash_value-name
              i_type           = ls_hash_value-type
            EXCEPTIONS
              parameter_error  = 1
              object_not_exist = 2
              OTHERS           = 3. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        ENDIF.
      ELSE.
        MESSAGE i252(s#)
        WITH 'Odata Service not found in this system'(t09).
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  load_data_for_edit
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_I_FIORIID  text
*----------------------------------------------------------------------*
FORM load_data_for_edit
USING i_fioriid TYPE /psyng/sw_fioriid
CHANGING of_not_found TYPE flag.

  DATA: ls_fioriids TYPE /psyng/range_fioriid,
        lt_fioriids TYPE TABLE OF /psyng/range_fioriid.

  ls_fioriids-sign   = 'I'.
  ls_fioriids-option = 'EQ'.
  ls_fioriids-low    = i_fioriid.
  APPEND ls_fioriids TO lt_fioriids.
*-- Load Fiori App details
  CALL FUNCTION '/PSYNG/SW_FIORIAPP_INFO'
    TABLES
      it_fioriids   = lt_fioriids
      et_fioriapp   = gt_fioriapp
      et_fioriodata = gt_fioriodata
      et_fioritext  = gt_fioritext
      et_fiorinote  = gt_fiorinote
    EXCEPTIONS
      nothing_found = 1
      OTHERS        = 2.
  IF sy-subrc EQ 0.
*--Display the Fiori App Details Screen
    SORT gt_fioritext  BY fioriid textfield linenr.
    SORT gt_fioriodata BY fioriid odataservicename.
    SORT gt_fiorinote  BY fioriid note.
*--Load Data for screen fields
    PERFORM load_data.
  ELSE.
    of_not_found = 'X'.
  ENDIF.

ENDFORM.                    " load_data_for_edit
*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data.
  DATA: lt_fioritext  TYPE TABLE OF /psyng/sw_fiorit,
        ls_fioritext  TYPE /psyng/sw_fiorit,
        lt_fioriodata TYPE TABLE OF /psyng/sw_fiorio,
        ls_fioriodata TYPE /psyng/sw_fiorio,
        lt_fiorinote  TYPE TABLE OF /psyng/sw_fiorin,
        ls_fiorinote  TYPE /psyng/sw_fiorin,
        ls_odata      TYPE ty_odata,
        ls_notes      TYPE ty_notes,
        ls_text       TYPE ty_text,
        l_string      TYPE string,
        lt_text_table TYPE soli_tab,
        ls_text_table TYPE soli.

  IF /psyng/sw_fioria-fioriid IS INITIAL.
    MESSAGE i252(s#)
   WITH 'Please enter App Id'(i01).
  ENDIF.
  CHECK NOT /psyng/sw_fioria-fioriid IS INITIAL.
*--Modify Fiori App information data
  MODIFY /psyng/sw_fioria FROM /psyng/sw_fioria.
*--Build internal table for text fields
*--Store technical catalog description
  IF NOT /psyng/sw_fiorit-text IS INITIAL.
    ls_fioritext-fioriid   = /psyng/sw_fioria-fioriid.
    ls_fioritext-textfield = 'TECCATDESC'.
    ls_fioritext-linenr    = 1.
    ls_fioritext-text      = /psyng/sw_fiorit-text.
    APPEND ls_fioritext TO lt_fioritext.
    CLEAR ls_fioritext.
  ENDIF.
*--Store business role description
  IF NOT gs_role_desc IS INITIAL.
    ls_fioritext-fioriid   = /psyng/sw_fioria-fioriid.
    ls_fioritext-textfield = 'BUSROLDESC'.
    ls_fioritext-linenr    = 1.
    ls_fioritext-text      = gs_role_desc.
    APPEND ls_fioritext TO lt_fioritext.
    CLEAR ls_fioritext.
  ENDIF.
*--Store app description
  CLEAR ls_fioritext.
  LOOP AT gt_text INTO ls_text.
    CONCATENATE l_string ls_text INTO l_string.
  ENDLOOP.
  PERFORM convert_string_to_table
   TABLES lt_text_table
    USING l_string
          255.
  LOOP AT lt_text_table INTO ls_text_table.
    ls_fioritext-fioriid   = /psyng/sw_fioria-fioriid.
    ls_fioritext-textfield = 'APPDESC'.
    ADD 1 TO ls_fioritext-linenr.
    ls_fioritext-text      = ls_text_table-line.
    APPEND ls_fioritext TO lt_fioritext.
  ENDLOOP.
*--delete existing texts in DB
DELETE FROM /psyng/sw_fiorit"#EC SAST_CI_GEN_CHECK(HBHALLA)
 WHERE fioriid EQ /psyng/sw_fioria-fioriid
   AND ( textfield = 'APPDESC'
    OR   textfield = 'TECCATDESC'
    OR   textfield = 'BUSROLDESC' ).
*--Modify table of texts
  MODIFY /psyng/sw_fiorit FROM TABLE lt_fioritext.

*--Save Odata Services information
*--Delete old entries for fioriid
  DELETE FROM /psyng/sw_fiorio
   WHERE fioriid EQ /psyng/sw_fioria-fioriid.
  DELETE gt_odata WHERE project IS INITIAL.
  IF NOT gt_odata IS INITIAL.
    LOOP AT gt_odata INTO ls_odata
      WHERE NOT project IS INITIAL.
      MOVE-CORRESPONDING ls_odata TO ls_fioriodata.
      ls_fioriodata-odataservicename = ls_odata-project.
      ls_fioriodata-fioriid = /psyng/sw_fioria-fioriid.
      APPEND ls_fioriodata TO lt_fioriodata.
      CLEAR ls_fioriodata.
    ENDLOOP.
*--Modify table of odata services
    SORT lt_fioriodata BY fioriid odataservicename.
    DELETE ADJACENT DUPLICATES FROM lt_fioriodata
    COMPARING fioriid odataservicename.
    MODIFY /psyng/sw_fiorio FROM TABLE lt_fioriodata.
  ENDIF.

*--Save notes information
*--Delete old entries for fioriid
  DELETE FROM /psyng/sw_fiorin
   WHERE fioriid EQ /psyng/sw_fioria-fioriid.
  DELETE gt_notes WHERE note IS INITIAL.
  IF NOT gt_notes IS INITIAL.
    LOOP AT gt_notes INTO ls_notes
      WHERE NOT note IS INITIAL.
      MOVE-CORRESPONDING ls_notes TO ls_fiorinote.
      ls_fiorinote-fioriid = /psyng/sw_fioria-fioriid.
      APPEND ls_fiorinote TO lt_fiorinote.
    ENDLOOP.
*--Modify table of odata services
    DELETE ADJACENT DUPLICATES FROM lt_fiorinote
    COMPARING ALL FIELDS.
    INSERT /psyng/sw_fiorin FROM TABLE lt_fiorinote.
  ENDIF.

  MESSAGE i252(s#)
  WITH 'Data is saved'(t13).

ENDFORM.                    " save_data
*&---------------------------------------------------------------------*
*&      Form  convert_string_to_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_TABLES  text
*      -->P_LS_STRING  text
*      -->P_255    text
*----------------------------------------------------------------------*
FORM convert_string_to_table
TABLES et_table         TYPE soli_tab
USING  i_string         TYPE string
       i_tabline_length TYPE i.

  DATA: l_length      TYPE i,
        l_offset      TYPE i,
        l_full_lines  TYPE i,
        l_last_length TYPE i.

* get string length
  l_length = strlen( i_string ).
* get number of full lines
  l_full_lines  = l_length DIV i_tabline_length.
* get length of last line
  l_last_length = l_length MOD i_tabline_length.

* append full lines to output table
  DO l_full_lines TIMES. "#EC PATHLOCK_CI_NO_DOS (HBHALLA)
    et_table = i_string+l_offset(i_tabline_length).
    APPEND et_table TO et_table.
    l_offset = l_offset + i_tabline_length.
  ENDDO.

* append last line to output table
  et_table = i_string+l_offset(l_last_length).
  APPEND et_table TO et_table.

ENDFORM.                    " convert_string_to_table
*&---------------------------------------------------------------------*
*&      Form  exculde_toolbar
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exculde_toolbar.

  DATA: l_func TYPE ui_func.

  IF gt_exc_toolbar IS INITIAL.
    l_func = cl_gui_alv_grid=>mc_fc_info.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_expcrdata.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_expcrdesig.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_expcrtempl.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_pc_file.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_print.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_view_crystal.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_view_grid.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_mb_view.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_mb_export.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_call_abc.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_graph.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_filter.
    APPEND l_func TO gt_exc_toolbar.
    l_func = cl_gui_alv_grid=>mc_fc_loc_undo.
    APPEND l_func TO gt_exc_toolbar.
  ENDIF.

ENDFORM.                    " exculde_toolbar
*&---------------------------------------------------------------------*
*&      Form  data_changed_finished
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_FINISHED  text
*      -->P_ET_GOOD_CELLS  text
*----------------------------------------------------------------------*
FORM data_changed_finished USING i_modified TYPE char01.

  DATA: ls_stable   TYPE lvc_s_stbl.
  FIELD-SYMBOLS: <fs_odata> TYPE ty_odata.

  CHECK NOT i_modified IS INITIAL.
  LOOP AT gt_odata ASSIGNING <fs_odata>.
    IF NOT <fs_odata>-project IS INITIAL.
      <fs_odata>-su24 = 'SU24'.
    ELSE.
      CLEAR <fs_odata>-su24.
    ENDIF.
  ENDLOOP.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  CALL METHOD go_alvgrid_services->refresh_table_display
    EXPORTING
      i_soft_refresh = 'X'
      is_stable      = ls_stable
    EXCEPTIONS
      finished       = 1
      OTHERS         = 2.

ENDFORM.                    " data_changed_finished
*&---------------------------------------------------------------------*
*&      Form  data_changed_notes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_MODIFIED  text
*----------------------------------------------------------------------*
FORM data_changed_notes USING i_modified TYPE char01.

  DATA: ls_hype TYPE lvc_s_hype,
        l_count TYPE int4.
  FIELD-SYMBOLS: <fs_notes> TYPE ty_notes.

  CHECK NOT i_modified IS INITIAL.
  LOOP AT gt_notes ASSIGNING <fs_notes>.
    IF NOT <fs_notes>-note IS INITIAL.
      <fs_notes>-link = <fs_notes>-note.
    ELSE.
      CLEAR <fs_notes>-note.
    ENDIF.
  ENDLOOP.

  REFRESH gt_hype.
  LOOP AT gt_notes ASSIGNING <fs_notes>.
    ADD 1 TO l_count.
    <fs_notes>-link_handle = l_count.
    ls_hype-handle = l_count.
    CONCATENATE
    'https://launchpad.support.sap.com/#/notes/'(t08)
    <fs_notes>-note INTO
    ls_hype-href.
    APPEND ls_hype TO gt_hype.
  ENDLOOP.

*--Call ALV
  CALL METHOD go_alvgrid_notes->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout_notes
      it_toolbar_excluding          = gt_exc_toolbar
      it_hyperlink                  = gt_hype
    CHANGING
      it_outtab                     = gt_notes
      it_fieldcatalog               = gt_field_cat_notes
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.                    " data_changed_notes
*&---------------------------------------------------------------------*
*&      Form  load_fieldcat
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_fieldcat.

*Prepare field catalog for services ALV
  PERFORM fieldcatalog_services.
*Prepare field catalog for OSS Notes ALV
  PERFORM fieldcatalog_notes.
  IF go_event_handler IS INITIAL.
    CREATE OBJECT go_event_handler.
  ENDIF.
  IF go_event_notes IS INITIAL.
    CREATE OBJECT go_event_notes.
  ENDIF.
*Exclude toolbar buttons
  PERFORM exculde_toolbar.

ENDFORM.                    " load_fieldcat
*&---------------------------------------------------------------------*
*&      Form  refresh_global_variables
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM refresh_global_variables.

  REFRESH: gt_fioriapp, gt_fioriodata, gt_fioritext, gt_fiorinote,
           gt_odata, gt_notes, gt_text, gt_field_cat_services,
           gt_field_cat_notes, gt_hype, gt_exc_toolbar.

  CLEAR: gs_fiori_id_name, gs_role_desc, gs_more_info_url,
         /psyng/sw_fioria, /psyng/sw_fiorit,
         gs_layout_services, gs_layout_notes,
         gf_load_new_app, gf_edit.

ENDFORM.                    " refresh_global_variables
*&---------------------------------------------------------------------*
*&      Form  create_new_fioriid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_new_fioriid.

  DATA: lt_fields  TYPE TABLE OF sval,
        ls_field   TYPE sval,
        l_ret_code TYPE c,
        l_answer   TYPE c,
        l_question TYPE char200,
        l_fioriid  TYPE /psyng/sw_fioriid.

  ls_field-tabname   = '/PSYNG/SW_FIORIA'.
  ls_field-fieldname = 'FIORIID'.
  APPEND ls_field TO lt_fields.
  CLEAR ls_field.

  CALL FUNCTION 'POPUP_GET_VALUES'
    EXPORTING
      popup_title     = 'Enter new Fiori App ID'(t14)
    IMPORTING
      returncode      = l_ret_code
    TABLES
      fields          = lt_fields
    EXCEPTIONS
      error_in_fields = 1
      OTHERS          = 2.
  IF sy-subrc EQ 0
  AND l_ret_code IS INITIAL.
    READ TABLE lt_fields INTO ls_field INDEX 1.
    IF sy-subrc EQ 0
    AND NOT ls_field-value IS INITIAL.
*--Check if ID starts with 'Z'
      IF ls_field-value+(1) NE 'Z'.
        MESSAGE i252(s#)
        WITH 'Custom Fiori App ID should start with Z'(t17).
        PERFORM create_new_fioriid.
      ELSE.
*--Check if ID already exits
        l_fioriid = ls_field-value.
        SELECT SINGLE fioriid
          FROM /psyng/sw_fioria
          INTO l_fioriid
         WHERE fioriid EQ l_fioriid.
        IF sy-subrc EQ 0.
          l_question =
       'Fiori App Id & already exists. Do you want to replace it?'(t15).
          REPLACE '&' INTO l_question WITH l_fioriid.
          CONDENSE l_question.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar       = 'Replace Fiori App ID'(t16)
              text_question  = l_question
              text_button_1  = 'Yes'(001)
              text_button_2  = 'No'(002)
            IMPORTING
              answer         = l_answer
            EXCEPTIONS
              text_not_found = 1
              OTHERS         = 2.
          IF sy-subrc EQ 0.
            IF l_answer EQ '1'.
*--Replace fioriid
              /psyng/sw_fioria-fioriid = l_fioriid.
*--Build Fiori ID and name
              CONCATENATE /psyng/sw_fioria-fioriid /psyng/sw_fioria-appname
                                  INTO gs_fiori_id_name SEPARATED BY ' - '.
              PERFORM save_data.
            ELSE.
              PERFORM create_new_fioriid.
            ENDIF.
          ENDIF.
*--If app ID does not exist
        ELSE.
*--Save new fioriid
          /psyng/sw_fioria-fioriid = l_fioriid.
*--Build Fiori ID and name
          CONCATENATE /psyng/sw_fioria-fioriid /psyng/sw_fioria-appname
          INTO gs_fiori_id_name SEPARATED BY ' - '.
          PERFORM save_data.
        ENDIF.
      ENDIF.
    ELSE.
      MESSAGE i252(s#)
     WITH 'Please Enter App ID'(y01).
    ENDIF.
  ENDIF.
ENDFORM.                    " create_new_fioriid
*&---------------------------------------------------------------------*
*&      Form  delete_fiori_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_fiori_id.

  DATA: l_answer   TYPE c,
        l_question TYPE char200.

  l_question =
'This will delete Fiori App Id & completely.'(t19).
  CONCATENATE l_question 'Do you want to proceed?'(t20)
  INTO l_question SEPARATED BY space.
  REPLACE '&' INTO l_question WITH /psyng/sw_fioria-fioriid.
  CONDENSE l_question.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = 'Delete Fiori App ID'(t18)
      text_question  = l_question
      text_button_1  = 'Yes'(001)
      text_button_2  = 'No'(002)
    IMPORTING
      answer         = l_answer
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.
  IF sy-subrc EQ 0.
    IF l_answer EQ '1'.
*--delete fiori id
      DELETE FROM /psyng/sw_fioria
       WHERE fioriid EQ /psyng/sw_fioria-fioriid.
*--delete odata services for this fiori id
      DELETE FROM /psyng/sw_fiorio
       WHERE fioriid EQ /psyng/sw_fioria-fioriid.
*--delete SAP notes for this fiori id
      DELETE FROM /psyng/sw_fiorin
       WHERE fioriid EQ /psyng/sw_fioria-fioriid.
*--delete texts for this fiori id
      DELETE FROM /psyng/sw_fiorit
       WHERE fioriid EQ /psyng/sw_fioria-fioriid.
      REFRESH: gt_odata, gt_notes, gt_text,gt_hype.
      CLEAR: gs_fiori_id_name, gs_role_desc, gs_more_info_url,
             /psyng/sw_fioria, /psyng/sw_fiorit.
      MESSAGE i252(s#)
      WITH 'Data is deleted'(t21).
    ENDIF.
  ENDIF.

ENDFORM.                    " delete_fiori_id
*&---------------------------------------------------------------------*
*&      Form  status_0100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM status_0100.

  DATA: lt_fcodes TYPE STANDARD TABLE OF ty_fcodes,
        ls_fcodes TYPE ty_fcodes,
        l_fioriid TYPE /psyng/sw_fioriid.

  IF gf_edit IS INITIAL.
    MOVE 'SAVE' TO ls_fcodes-fcode.
    APPEND ls_fcodes TO lt_fcodes.
    MOVE 'DELETE' TO ls_fcodes-fcode.
    APPEND ls_fcodes TO lt_fcodes.
    SET PF-STATUS 'PF0100' EXCLUDING lt_fcodes.
    SET TITLEBAR 'TITLE'.
  ELSE.
    SELECT SINGLE fioriid
      FROM /psyng/sw_fioria
      INTO l_fioriid
     WHERE fioriid EQ /psyng/sw_fioria-fioriid.
    IF sy-subrc NE 0.
      MOVE 'DELETE' TO ls_fcodes-fcode.
      APPEND ls_fcodes TO lt_fcodes.
    ENDIF.
    MOVE 'CREATE' TO ls_fcodes-fcode.
    APPEND ls_fcodes TO lt_fcodes.
    SET PF-STATUS 'PF0100' EXCLUDING lt_fcodes.
    SET TITLEBAR 'TITLE02'.
  ENDIF.

ENDFORM.                    " status_0100
*&---------------------------------------------------------------------*
*&      Form  validate_fioriid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_fioriid.
  DATA: l_fioriid    TYPE /psyng/sw_fioriid,
        lf_not_found TYPE flag,
        l_answer     TYPE c,
        l_question   TYPE char200.
*--Validate custom Fiori app naming
**  CLEAR: l_fioriid, lf_not_found.
  CHECK NOT gf_edit IS INITIAL.
  IF NOT /psyng/sw_fioria-fioriid IS INITIAL.
    IF /psyng/sw_fioria-fioriid+(1) NE 'Z'.
      MESSAGE e252(s#)
      WITH 'Custom Fiori App name should start with Z'(t11).
    ELSE.
*--If Custom Fiori App already exits;
      SELECT SINGLE fioriid
        INTO l_fioriid
        FROM /psyng/sw_fioria
       WHERE fioriid EQ /psyng/sw_fioria-fioriid.
      IF sy-subrc EQ 0.
*--Confirm with user if he wants to change the existing one
        l_question =
'Fiori App Id & already exists. Do you want to change it?'(t26).
        REPLACE '&' INTO l_question WITH /psyng/sw_fioria-fioriid.
        CONDENSE l_question.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar       = 'Change Fiori App ID'(t27)
            text_question  = l_question
            text_button_1  = 'Yes'(001)
            text_button_2  = 'No'(002)
          IMPORTING
            answer         = l_answer
          EXCEPTIONS
            text_not_found = 1
            OTHERS         = 2.
        IF sy-subrc EQ 0.
          IF l_answer EQ '1'.
*--If yes; load screen with its data
            l_fioriid = /psyng/sw_fioria-fioriid.
            PERFORM load_data_for_edit USING l_fioriid
                                       CHANGING lf_not_found.
            gf_load_new_app = 'X'.
          ELSE.
            MESSAGE e252(s#)
            WITH 'Input some other Fiori ID'(t28).
          ENDIF.
        ENDIF.
*      ELSE.
*        l_fioriid = /psyng/sw_fioria-fioriid.
*        REFRESH: gt_odata, gt_notes, gt_text,gt_hype.
*        CLEAR: gs_fiori_id_name, gs_role_desc, gs_more_info_url,
*               /psyng/sw_fioria, /psyng/sw_fiorit.
*        /psyng/sw_fioria-fioriid = l_fioriid.
*        gf_load_new_app = 'X'.
      ENDIF.
    ENDIF.
  ELSEIF /psyng/sw_fioria-fioriid IS INITIAL.
    MESSAGE e252(s#)
    WITH 'Please enter mandatory field App Id'(t12).
  ENDIF.

ENDFORM.                    " validate_fioriid

FORM save_in_db
  TABLES
     et_fioriapp STRUCTURE /psyng/sw_fioria
     et_fioriodata STRUCTURE  /psyng/sw_fiorio
     et_fioritext STRUCTURE  /psyng/sw_fiorit
     et_fiorinote  STRUCTURE /psyng/sw_fiorin
  CHANGING e_success.
  READ TABLE et_fioriapp INDEX 1.

  CHECK NOT et_fioriapp-fioriid IS INITIAL.
*--Modify Fiori App information data
  MODIFY /psyng/sw_fioria FROM et_fioriapp.
  IF sy-subrc = 0.
    COMMIT WORK.
    e_success = 'X'.
  ELSE.
    CLEAR e_success.
  ENDIF.

*--delete existing texts in DB
DELETE FROM /psyng/sw_fiorit"#EC SAST_CI_GEN_CHECK(HBHALLA)
 WHERE fioriid EQ et_fioriapp-fioriid
   AND ( textfield = 'APPDESC'
    OR   textfield = 'TECCATDESC'
    OR   textfield = 'BUSROLDESC' ).

*--Modify table of texts
  MODIFY /psyng/sw_fiorit FROM TABLE et_fioritext.
  IF sy-subrc = 0.
    COMMIT WORK.
    e_success = 'X'.
  ELSE.
    CLEAR e_success.
  ENDIF.
*--Save Odata Services information
*--Delete old entries for fioriid
  DELETE FROM /psyng/sw_fiorio
   WHERE fioriid EQ et_fioriapp-fioriid.
*--Modify table of odata services
  SORT et_fioriodata BY fioriid odataservicename.
  DELETE ADJACENT DUPLICATES FROM et_fioriodata
  COMPARING fioriid odataservicename.
  MODIFY /psyng/sw_fiorio FROM TABLE et_fioriodata.
  IF sy-subrc = 0.
    COMMIT WORK.
    e_success = 'X'.
  ELSE.
    CLEAR e_success.
  ENDIF.
*--Save notes information
*--Delete old entries for fioriid
  DELETE FROM /psyng/sw_fiorin
   WHERE fioriid EQ et_fioriapp-fioriid.
*--Modify table of odata services
  DELETE ADJACENT DUPLICATES FROM  et_fiorinote
  COMPARING ALL FIELDS.
  MODIFY /psyng/sw_fiorin FROM TABLE et_fiorinote.
*  INSERT /psyng/sw_fiorin FROM TABLE  et_fiorinote.
  IF sy-subrc = 0.
    COMMIT WORK.
    e_success = 'X'.
  ELSE.
    CLEAR e_success.
  ENDIF.
ENDFORM.
