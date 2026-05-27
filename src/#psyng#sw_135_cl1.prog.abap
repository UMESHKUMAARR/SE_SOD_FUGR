*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_135_CL1                                          *
*----------------------------------------------------------------------*

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION .
  PUBLIC SECTION .
    METHODS:
*--To add new functional buttons to the ALV toolbar
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
****   for display only
handle_toolbar1 FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,
**  for add/delete/append
handle_toolbar2 FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object e_interactive,

 handle_before_user_command
                    FOR EVENT before_user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

 handle_before_user_command1
                    FOR EVENT before_user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

*--To implement user commands
      handle_user_command
                    FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,


***  data change
data_changed FOR EVENT data_changed OF cl_gui_alv_grid
                   IMPORTING er_data_changed
                    e_onf4
                    e_onf4_after sender,

***Handle data change
      handle_data_changed FOR EVENT data_changed OF cl_gui_alv_grid
        IMPORTING er_data_changed e_onf4 e_onf4_after sender,

*--Search help
      handle_on_f4
                    FOR EVENT onf4 OF cl_gui_alv_grid
        IMPORTING e_fieldname es_row_no   er_event_data,

*--Hotspot click control
  handle_hotspot_click
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,

*--Hotspot click control
  handle_hotspot_click_104
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,

*--Hotspot click control
  handle_hotspot_click_dtl
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,
*-- hotspot click control for detail toggle
   handle_hotspot_click_dtl2
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,

*-- hotspot click control for screen 102
   handle_hotspot_click_102
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,

*-- hotspot click control for screen 102_2
   handle_hotspot_click_102_2
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
    PERFORM handle_toolbar USING e_object e_interactive .
  ENDMETHOD .

*--Handle Toolbar1
  METHOD handle_toolbar1.
    PERFORM handle_toolbar1 USING e_object e_interactive .
  ENDMETHOD .

*--Handle Toolbar2
  METHOD handle_toolbar2.
    PERFORM handle_toolbar2 USING e_object e_interactive .
  ENDMETHOD .

*--Handle Before User Command
  METHOD handle_before_user_command .
    IF e_ucomm = '&INFO'.
          PERFORM get_info USING '/PSYNG/SWCFGOE'.

      CALL METHOD gr_alvgrid_org->set_user_command
        EXPORTING
          i_ucomm = space.
    ENDIF.
  ENDMETHOD .

*--Handle Before User Command1
  METHOD handle_before_user_command1 .
    IF e_ucomm = '&INFO'.
           PERFORM get_info USING '/PSYNG/SWCFGVE'.

*      CALL METHOD gr_alvgrid_var->set_user_command
*        EXPORTING
*          i_ucomm = space.
    ENDIF.
  ENDMETHOD .

*--Handle User Command main
  METHOD handle_user_command .
    CASE sy-dynnr.
      WHEN '0101'.
        PERFORM handle_user_command_0101 USING e_ucomm.
      WHEN '0102'.
        PERFORM handle_user_command_0102 USING e_ucomm.
      WHEN '0103'.
        PERFORM handle_user_command_0103 USING e_ucomm.
      WHEN '0104'.
        PERFORM handle_user_command_0104 USING e_ucomm.
    ENDCASE.
  ENDMETHOD.

  METHOD handle_on_f4 .
  PERFORM f4_help USING e_fieldname es_row_no .
*    er_event_data->m_event_handled = 'X'.
  ENDMETHOD.


  METHOD data_changed.
    DATA: ls_mod_cells TYPE lvc_s_modi,
          ls_mod_rows  TYPE lvc_s_moce,
          ls_sel_systems LIKE gt_sel_systems.
    gf_screen_change = 'X'.
    gf_data_change   = 'X'.
  ENDMETHOD.

  METHOD handle_data_changed.
    DATA: lt_mod TYPE TABLE OF lvc_s_modi,
          ls_mod TYPE lvc_s_modi,
          ls_del_rows  TYPE lvc_s_moce,
          ls_variable1 TYPE /psyng/swcfgve.
  ENDMETHOD.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
  ENDMETHOD .

*--Handle Hotspot Click
  METHOD handle_hotspot_click_104 .
    PERFORM handle_hotspot_click_104 USING
            e_row_id e_column_id es_row_no .
  ENDMETHOD .

*--Handle Hotspot Click dtl
  METHOD handle_hotspot_click_dtl .
    PERFORM handle_hotspot_click_dtl USING e_row_id
            e_column_id es_row_no .
  ENDMETHOD .

*--Handle Hotspot Click dtl2
  METHOD handle_hotspot_click_dtl2 .
    PERFORM handle_hotspot_click_dtl2 USING e_row_id
            e_column_id es_row_no .
  ENDMETHOD .

*--Handle Hotspot Click screen 102
  METHOD handle_hotspot_click_102 .
    PERFORM handle_hotspot_click_102 USING e_row_id
            e_column_id es_row_no .
  ENDMETHOD .

*--Handle Hotspot Click screen 102_2
  METHOD handle_hotspot_click_102_2 .
    PERFORM handle_hotspot_click_102_2 USING e_row_id
            e_column_id es_row_no .
  ENDMETHOD .

ENDCLASS .

DATA: gr_event_handler_sys  TYPE REF TO  lcl_event_handler,
      gr_event_handler_ele1  TYPE REF TO  lcl_event_handler,
      gr_event_handler_ele2  TYPE REF TO  lcl_event_handler,
      gr_event_handler_org  TYPE REF TO  lcl_event_handler,
      gr_event_handler_org1 TYPE REF TO  lcl_event_handler,
      gr_event_handler_org2 TYPE REF TO  lcl_event_handler,
      gr_event_handler_var  TYPE REF TO  lcl_event_handler.
