FUNCTION-POOL /psyng/sw_fioria.             "MESSAGE-ID ..

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION FINAL.
  PUBLIC SECTION .
    METHODS:
*--Hotspot click control
      handle_hotspot_click
                    FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id,

*-- Data Changed Finished
      data_changed_finished
                    FOR EVENT data_changed_finished OF cl_gui_alv_grid
        IMPORTING e_modified,

      data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.

  PRIVATE SECTION.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_event_notes DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_notes DEFINITION FINAL.
  PUBLIC SECTION .
    METHODS:
*-- Data Changed Finished
      data_changed_finished
                    FOR EVENT data_changed_finished OF cl_gui_alv_grid
        IMPORTING e_modified,

      data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed.

  PRIVATE SECTION.
ENDCLASS.

*##NEEDED
DATA: go_event_handler TYPE REF TO lcl_event_handler,
      go_event_notes   TYPE REF TO lcl_event_notes.

CONSTANTS: gc_fname   TYPE rs38l-name VALUE 'SU2X_MAINTAIN_SINGLE',
           gc_tabname TYPE tabname VALUE 'USOBHASH'.

TYPE-POOLS: shlp.
TABLES: /psyng/sw_fioria,
        /psyng/sw_fiorit.

TYPES: BEGIN OF ty_odata,
         project          TYPE char30, "/iwbep/sbdm_project,
         odataservicevers TYPE char10,
         su24             TYPE char4,
       END OF ty_odata,

       BEGIN OF ty_notes,
         note        TYPE n LENGTH 10,
         link        TYPE n LENGTH 10,
         link_handle TYPE int4,
       END OF ty_notes,

       BEGIN OF ty_hash_value,
         name TYPE char30,
         type TYPE char2,
       END OF ty_hash_value,

       BEGIN OF ty_fcodes,
         fcode TYPE gui_code,
       END OF ty_fcodes,

       ty_text(30000) TYPE c.
*##NEEDED
DATA: gt_fioriapp      TYPE TABLE OF /psyng/sw_fioria,
      gt_fioriodata    TYPE TABLE OF /psyng/sw_fiorio,
      gt_fioritext     TYPE TABLE OF /psyng/sw_fiorit,
      gt_fiorinote     TYPE TABLE OF /psyng/sw_fiorin,
      gt_odata         TYPE TABLE OF ty_odata,
      gt_notes         TYPE TABLE OF ty_notes,
      gs_fiori_id_name TYPE char255,
      gs_role_desc     TYPE so_text255,
      gs_more_info_url TYPE char255,
      gt_text          TYPE TABLE OF ty_text.
*##NEEDED
DATA: gt_field_cat_services TYPE lvc_t_fcat,
      gs_layout_services    TYPE lvc_s_layo,
      go_alvgrid_services   TYPE REF TO cl_gui_alv_grid,
      go_container_services TYPE REF TO cl_gui_custom_container,
      gt_field_cat_notes    TYPE lvc_t_fcat,
      gs_layout_notes       TYPE lvc_s_layo,
      go_alvgrid_notes      TYPE REF TO cl_gui_alv_grid,
      go_container_notes    TYPE REF TO cl_gui_custom_container,
      go_container_text     TYPE REF TO cl_gui_custom_container,
      go_text_editor        TYPE REF TO cl_gui_textedit,
      gt_hype               TYPE lvc_t_hype,
      gf_edit               TYPE flag,
      gf_load_new_app       TYPE flag,
      gt_exc_toolbar        TYPE ui_functions.

*-- FUNCTION CODES FOR TABSTRIP 'FIORI_APP_DET'
CONSTANTS: BEGIN OF gc_fiori_app_det,
             tab1 LIKE sy-ucomm VALUE 'FIORI_APP_DET_FC1',
             tab2 LIKE sy-ucomm VALUE 'FIORI_APP_DET_FC2',
             tab3 LIKE sy-ucomm VALUE 'FIORI_APP_DET_FC3',
             tab4 LIKE sy-ucomm VALUE 'FIORI_APP_DET_FC4',
           END OF gc_fiori_app_det.
*-- DATA FOR TABSTRIP 'FIORI_APP_DET'
CONTROLS:  fiori_app_det TYPE TABSTRIP.
*##NEEDED
DATA:      BEGIN OF gs_fiori_app_det,
             subscreen   LIKE sy-dynnr,
             prog        LIKE sy-repid VALUE '/PSYNG/SAPLSW_FIORIA',
             pressed_tab LIKE sy-ucomm VALUE gc_fiori_app_det-tab1,
           END OF gs_fiori_app_det.
*##NEEDED
DATA:      ok_code LIKE sy-ucomm.
