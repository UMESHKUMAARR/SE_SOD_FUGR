*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_142_CL1                                          *
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
*-- Button click
      button_click
                    FOR EVENT button_click OF cl_gui_alv_grid
        IMPORTING es_col_id es_row_no,
*-- User Command
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
                          IMPORTING e_ucomm,
*-- Data Changed
      data_changed FOR EVENT data_changed OF cl_gui_alv_grid
                   IMPORTING er_data_changed
                             e_ucomm,

*--Hotspot click control
  handle_hotspot_click
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no.

  PRIVATE SECTION.
ENDCLASS.


*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.
*--Handle Toolbar
  METHOD handle_toolbar.
    DATA: ls_toolbar TYPE stb_button.
    ls_toolbar-function  = 'DISPCHG'.
    ls_toolbar-icon      = '@3I@'.
    ls_toolbar-quickinfo = 'Display/Change'(000).
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 1.
*    if gf_dispchg = gc_display.
    DELETE e_object->mt_toolbar WHERE function CS '&LOCAL&'.
*    endif.
    DELETE e_object->mt_toolbar WHERE function eq '&INFO'."hide info icon
    DELETE e_object->mt_toolbar WHERE function eq '&CHECK'."hide check entries
  ENDMETHOD.

*--Handle Before User Command
  METHOD handle_before_user_command .

  ENDMETHOD.

  METHOD button_click.
    PERFORM button_click USING es_col_id es_row_no.
  ENDMETHOD.

  METHOD handle_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

  METHOD data_changed.
    PERFORM data_changed USING er_data_changed e_ucomm.
  ENDMETHOD.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
*    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
  ENDMETHOD .

ENDCLASS.

DATA: gr_event_handler  TYPE REF TO  lcl_event_handler.
