*&---------------------------------------------------------------------*
*&  Include           ZARP_RES_ACC_PUB_CONFIG_CLS
*&---------------------------------------------------------------------*

CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION.
    METHODS:

    handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
         IMPORTING e_object,

    handle_user_command
      FOR EVENT before_user_command OF cl_gui_alv_grid
         IMPORTING e_ucomm,

      handle_on_f4
                    FOR EVENT onf4 OF cl_gui_alv_grid
        IMPORTING e_fieldname es_row_no   er_event_data.

ENDCLASS.

CLASS lcl_event_handler IMPLEMENTATION.

  METHOD handle_toolbar.

    DATA: ls_toolbar TYPE stb_button.

    DELETE e_object->mt_toolbar
           WHERE function = g_alv_grid->mc_fc_graph
*              OR function = g_alv_grid->mc_fc_info
              OR function = g_alv_grid->mc_mb_sum
              OR function = g_alv_grid->mc_mb_subtot
              OR function = g_alv_grid->mc_fc_loc_copy
              OR function = g_alv_grid->mc_fc_loc_copy_row
              OR function = g_alv_grid->mc_fc_loc_cut
              OR function = g_alv_grid->mc_fc_loc_paste
              OR function = g_alv_grid->mc_fc_print_back
              OR function = g_alv_grid->mc_fc_detail
              OR function = g_alv_grid->mc_mb_export
              OR function = g_alv_grid->mc_fc_current_variant
              OR function = g_alv_grid->mc_fc_refresh
              OR function = g_alv_grid->mc_fc_loc_append_row
              OR function = g_alv_grid->mc_mb_view
              OR function = g_alv_grid->mc_fc_loc_undo.

    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DISPCHG'.
    ls_toolbar-icon      = '@3I@'.
    ls_toolbar-quickinfo = 'Display/Change'(000).
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 1.

    IF gf_dispchg = gc_display.
      DELETE e_object->mt_toolbar WHERE function CS '&LOCAL&'.
    ENDIF.

  ENDMETHOD.

  METHOD handle_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.

  METHOD handle_on_f4 .
    PERFORM f4_help USING e_fieldname es_row_no.
    er_event_data->m_event_handled = 'X'.
  ENDMETHOD.

ENDCLASS.
