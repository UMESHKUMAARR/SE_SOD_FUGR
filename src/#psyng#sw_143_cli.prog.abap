*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_143_CLI                                          *
*----------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION .
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


CLASS lcl_event_handler IMPLEMENTATION.
*--Handle Toolbar
  METHOD handle_toolbar.
*    PERFORM handle_toolbar USING e_object e_interactive .
  ENDMETHOD.

*--Handle Before User Command
  METHOD handle_before_user_command .

      ENDMETHOD.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
*++C0006
  ENDMETHOD .

ENDCLASS.

DATA gr_event_handler TYPE REF TO  lcl_event_handler.
