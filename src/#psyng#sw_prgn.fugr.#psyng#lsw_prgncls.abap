*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSW_PRGNCLS                                         *
*----------------------------------------------------------------------*
CLASS lcl_event_handler_100 DEFINITION.
  PUBLIC SECTION .
    METHODS:
*handle_user_command
*FOR EVENT user_command OF cl_gui_alv_grid
*IMPORTING e_ucomm.
    handle_hotspot_click
      FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING e_row_id e_column_id es_row_no,
    handle_print_top_of_list
      FOR EVENT print_top_of_list OF cl_gui_alv_grid .
PRIVATE SECTION.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler_100 IMPLEMENTATION .
*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_role_conid_click
      USING e_row_id e_column_id es_row_no .
  ENDMETHOD .
  METHOD handle_print_top_of_list.
    perform top_of_list_roles.
  ENDMETHOD .
ENDCLASS.


CLASS lcl_event_handler_200 DEFINITION.
  PUBLIC SECTION .
    METHODS:
*handle_user_command
*FOR EVENT user_command OF cl_gui_alv_grid
*IMPORTING e_ucomm.
    handle_hotspot_click
    FOR EVENT hotspot_click OF cl_gui_alv_grid
    IMPORTING e_row_id e_column_id es_row_no,
    handle_print_top_of_list
      FOR EVENT print_top_of_list OF cl_gui_alv_grid.
  PRIVATE SECTION.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler_200 IMPLEMENTATION .
*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_user_conid_click
      USING e_row_id e_column_id es_row_no .
  ENDMETHOD .
  METHOD handle_print_top_of_list.
    perform top_of_list_users.
  ENDMETHOD .

ENDCLASS.
