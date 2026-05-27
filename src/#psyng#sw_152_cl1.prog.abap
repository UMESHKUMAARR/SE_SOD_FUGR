*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_152_CL1
*&---------------------------------------------------------------------*
CLASS lcl_event_handler_comp DEFINITION .
  PUBLIC SECTION .
    METHODS:
*--To add new functional buttons to the ALV toolbar
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

      handle_before_user_command
                    FOR EVENT before_user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,
*--Hotspot click control
      handle_hotspot_click
                    FOR EVENT hotspot_click OF cl_gui_alv_grid
        IMPORTING e_row_id e_column_id.
  PRIVATE SECTION.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler_comp IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler_comp IMPLEMENTATION.
*--Handle Toolbar
  METHOD handle_toolbar.
    PERFORM handle_toolbar USING e_object.
  ENDMETHOD.

*--Handle Before User Command
  METHOD handle_before_user_command .

    gt_detail_usrcon_view_hide = gt_detail_usrcon_view.
    DELETE gt_detail_usrcon_view_hide WHERE pre_aid EQ gc_con_identified
                                      AND lat_aid EQ gc_con_identified.
    CASE e_ucomm.
      WHEN 'UVIEW'.
*Switch to User View
        g_view = 'U'.
        PERFORM display_alv_usrv_100.
      WHEN 'CVIEW'.
*Switch to Conflict View
        g_view = 'C'.
        PERFORM display_alv_100.
      WHEN 'UCVIEW'.
*Switch to User Conflict View
        g_view = 'UC'.
        PERFORM display_alv_usrconv_100 TABLES gt_detail_usrcon_view.
      WHEN 'HIDE'.
*Hide conflicts that were identified in both analysis.
        IF g_hide IS INITIAL.
        g_hide = 'X'.
        PERFORM display_alv_usrconv_100 TABLES gt_detail_usrcon_view_hide.
        ELSE.
        CLEAR g_hide.
        PERFORM display_alv_usrconv_100 TABLES gt_detail_usrcon_view.
        ENDIF.
      WHEN 'SELECT'.
        PERFORM change_selection_criteria.
    ENDCASE.

  ENDMETHOD.
*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    IF g_view EQ 'C'.
PERFORM handle_hotspot_click_comp USING e_row_id e_column_id.
    ELSEIF g_view EQ 'U'.
PERFORM handle_hotspot_click_usrv USING e_row_id e_column_id.
    ELSEIF g_view EQ 'UC'.
PERFORM handle_hotspot_click_usrconv USING e_row_id e_column_id.
    ENDIF.
  ENDMETHOD .

ENDCLASS.

DATA: gr_event_handler_comp  TYPE REF TO  lcl_event_handler_comp.
