*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_138_CL1                                          *
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
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.
*--Handle Toolbar
  METHOD handle_toolbar.
    PERFORM handle_toolbar USING e_object e_interactive .
  ENDMETHOD.

*--Handle Before User Command
  METHOD handle_before_user_command .

    DATA: l_row_no     TYPE lvc_t_roid,
          ls_row_no    TYPE lvc_s_roid,
          w_lines      TYPE i,
          ls_resultset LIKE LINE OF gt_resultset,
          lt_resultst  TYPE TABLE OF /psyng/swreshdr,
          l_vrsio      TYPE /psyng/sodvrsio,
          ls_aid       LIKE LINE OF gr_aid.
    DATA: lt_sort TYPE lvc_t_sort.
*    ranges: lr_aid FOR /psyng/swreshdr-aid.

    IF e_ucomm = '&INFO'.
      CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
        EXPORTING
          dokname = '/PSYNG/SW_138'.

    ELSEIF e_ucomm = 'DELETE'.
*---Get selected row
      CALL METHOD gr_alvgrid->get_selected_rows
        IMPORTING
          et_row_no = l_row_no.
      DESCRIBE TABLE l_row_no LINES w_lines.
      IF w_lines = 0.
        MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
      ELSE.
        REFRESH gr_aid.
        LOOP AT l_row_no INTO ls_row_no.
          READ TABLE gt_resultset INTO ls_resultset
                 INDEX  ls_row_no-row_id.
          IF sy-subrc = 0.
            ls_aid-sign = 'I'.
            ls_aid-option = 'EQ'.
            ls_aid-low = ls_resultset-aid.
            APPEND ls_aid TO gr_aid.
          ENDIF.
        ENDLOOP.
*---call report sw_139 with selected row
        SUBMIT /psyng/sw_139
       WITH so_aid IN gr_aid
       VIA SELECTION-SCREEN AND RETURN.

        REFRESH gt_resultset.
*        PERFORM load_data_100.
**        DELETE gt_resultset INDEX ls_row_no-row_id.
*        CALL METHOD gr_alvgrid->refresh_table_display
*                EXPORTING
*                  i_soft_refresh = 'X'
*                EXCEPTIONS
*                  finished       = 1
*                  OTHERS         = 2.
*        CALL SCREEN '0100'.

        PERFORM load_data_100.

        CALL METHOD gr_alvgrid->get_sort_criteria
          IMPORTING
            et_sort = lt_sort.
        PERFORM display_alv_100.
      ENDIF.

    ELSEIF e_ucomm = 'DISP_DTL'. " Details
*---Get selected row
      CALL METHOD gr_alvgrid->get_selected_rows
        IMPORTING
          et_row_no = l_row_no.
      DESCRIBE TABLE l_row_no LINES w_lines.
      IF w_lines = 0.
        MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
      ELSEIF w_lines > 1.
        MESSAGE s002(/psyng/sw) WITH
        'Please select only a single record'(e01).
      ELSE.
        READ TABLE l_row_no INTO ls_row_no INDEX 1.
        IF sy-subrc = 0.
          READ TABLE gt_resultset  INTO ls_resultset
                        INDEX  ls_row_no-row_id.
          APPEND ls_resultset TO lt_resultst.
*---- Details screen
          CALL FUNCTION '/PSYNG/SW_STORED_RSLT_DETAILS'
            EXPORTING
              i_aid        = ls_resultset-aid
            TABLES
              it_resultset = lt_resultst.
        ENDIF.
      ENDIF.

*---refresh
    ELSEIF e_ucomm = 'REFRESH'.
      REFRESH gt_resultset.
*      PERFORM load_data_100.
*      CALL METHOD gr_alvgrid->refresh_table_display
*              EXPORTING
*                i_soft_refresh = 'X'
*              EXCEPTIONS
*                finished       = 1
*                OTHERS         = 2.
*      CALL SCREEN '0100'.

      g_clk_refresh = 'X'.
*CALL METHOD gr_alvgrid->get_sort_criteria
*  IMPORTING
*    ET_SORT = lt_sort.

      PERFORM load_data_100.
      PERFORM display_alv_100.

    ELSEIF e_ucomm = 'DISP_RES'.
*---Get selected row
      CALL METHOD gr_alvgrid->get_selected_rows
        IMPORTING
          et_row_no = l_row_no.
      DESCRIBE TABLE l_row_no LINES w_lines.
      IF w_lines = 0.
        MESSAGE s002(/psyng/sw) WITH 'Please select an entry'(e00).
      ELSEIF w_lines > 1.
        MESSAGE s002(/psyng/sw) WITH
        'Please select only a single record'(e01).
      ELSE.
        READ TABLE l_row_no INTO ls_row_no INDEX 1.
        IF sy-subrc = 0.
          READ TABLE gt_resultset  INTO ls_resultset
                        INDEX  ls_row_no-row_id.
*---call report sw_137 with selected row
          SUBMIT /psyng/sw_137
         WITH p_aid = ls_resultset-aid
         VIA SELECTION-SCREEN AND RETURN.
        ENDIF.
      ENDIF.
    ELSEIF e_ucomm = 'COMP_RES'.
*---Get selected row
      CALL METHOD gr_alvgrid->get_selected_rows
        IMPORTING
          et_row_no = l_row_no.
      DESCRIBE TABLE l_row_no LINES w_lines.
      IF w_lines NE 2.
        MESSAGE s002(/psyng/sw) WITH 'Please select two entries for comparison'(e02).
      ELSE.
        REFRESH gt_detail.
        CLEAR: g_latest_aid, g_pre_aid.
        LOOP AT l_row_no INTO ls_row_no.
          READ TABLE gt_resultset INTO ls_resultset
                 INDEX  ls_row_no-row_id.
          IF sy-subrc = 0.
            IF g_pre_aid IS INITIAL.
              g_pre_aid = ls_resultset-aid.
              l_vrsio   = ls_resultset-sodvrsio.
            ELSE.
              g_latest_aid = ls_resultset-aid.
            ENDIF.
          ENDIF.
        ENDLOOP.

        SUBMIT /psyng/sw_152
          WITH p_laid = g_latest_aid
          WITH p_paid = g_pre_aid
          AND RETURN.
      ENDIF.
    ENDIF.

  ENDMETHOD.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
  ENDMETHOD .

ENDCLASS.

DATA: gr_event_handler  TYPE REF TO  lcl_event_handler.
