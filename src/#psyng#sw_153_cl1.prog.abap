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
        IMPORTING e_row_id e_column_id es_row_no.
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
    PERFORM handle_toolbar USING e_object e_interactive .
  ENDMETHOD.

*--Handle Before User Command
  METHOD handle_before_user_command .

    CASE e_ucomm.
      WHEN 'SWITCH'.
        IF NOT g_confv IS INITIAL.
*Current view is Conflict view; Switch to Role View
          CLEAR g_confv.
          PERFORM display_alv_rolv_100.
        ELSE.
*Current view is Role view; Switch to Conflict View
          g_confv = 'X'.
          PERFORM display_alv_100.
        ENDIF.

*Begin of Addition AKUMAR PN15658 12-11-2025
      WHEN 'SWITCHD'.
        IF g_confv IS INITIAL.
*Current view is role view; Show Role Detail
*          g_confv = 'X'.
          PERFORM display_alv_drolv_100.
        ELSE.
*Current view is conflict view; Show Conflict detail
*          CLEAR g_confv.
          PERFORM display_alv_dconfv_100.
        ENDIF.
*End of Addition

      WHEN 'SELECT'.
        PERFORM change_selection_criteria.
    ENDCASE.

  ENDMETHOD.
*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    IF NOT g_confv IS INITIAL.
PERFORM handle_hotspot_click_comp USING e_row_id e_column_id es_row_no .
    ELSE.
PERFORM handle_hotspot_click_rolv USING e_row_id e_column_id es_row_no .
    ENDIF.
  ENDMETHOD .

ENDCLASS.

DATA: gr_event_handler_comp  TYPE REF TO  lcl_event_handler_comp.
