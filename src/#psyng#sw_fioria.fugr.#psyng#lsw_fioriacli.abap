*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSW_FIORIACLI                                       *
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id.
  ENDMETHOD.

  METHOD data_changed_finished .
    PERFORM data_changed_finished USING e_modified.
  ENDMETHOD.

    METHOD data_changed.
    DATA: ls_mod_cells TYPE lvc_s_modi,
          ls_del_rows  TYPE lvc_s_moce,
          ls_protocol  TYPE lvc_s_msg1,
          ls_odata     LIKE LINE OF gt_odata.

    REFRESH er_data_changed->mt_protocol.
** Check for the existing Entries
    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
            WHERE fieldname = 'PROJECT'
              AND value    <> space.
     TRANSLATE ls_mod_cells-value TO UPPER CASE.
     LOOP AT gt_odata INTO ls_odata WHERE project = ls_mod_cells-value
                 .
        IF sy-tabix <> ls_mod_cells-row_id.
          ls_mod_cells-error = 'X'.
          MODIFY er_data_changed->mt_mod_cells FROM ls_mod_cells
                 INDEX ls_mod_cells-row_id TRANSPORTING error.
          DELETE er_data_changed->mt_good_cells
                 WHERE fieldname = ls_mod_cells-fieldname.
          ls_protocol-msgid     = '/PSYNG/BASIS'.
          ls_protocol-msgno     = '038'.
          ls_protocol-msgty     = 'E'.
          ls_protocol-fieldname = ls_mod_cells-fieldname.
          ls_protocol-row_id    = ls_mod_cells-row_id.
          APPEND ls_protocol TO er_data_changed->mt_protocol.
          MESSAGE i038(/psyng/basis).
          CONTINUE.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_event_notes IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_notes IMPLEMENTATION.

  METHOD data_changed_finished .
    PERFORM data_changed_notes USING e_modified.
  ENDMETHOD.

    METHOD data_changed.
    DATA: ls_mod_cells TYPE lvc_s_modi,
          ls_del_rows  TYPE lvc_s_moce,
          ls_protocol  TYPE lvc_s_msg1,
          ls_notes     LIKE LINE OF gt_notes.

    REFRESH er_data_changed->mt_protocol.
** Check for the existing Entries
    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
            WHERE fieldname = 'NOTE'
              AND value    <> space.
     LOOP AT gt_notes INTO ls_notes WHERE note = ls_mod_cells-value
                 .
        IF sy-tabix <> ls_mod_cells-row_id.
          ls_mod_cells-error = 'X'.
          MODIFY er_data_changed->mt_mod_cells FROM ls_mod_cells
                 INDEX ls_mod_cells-row_id TRANSPORTING error.
          DELETE er_data_changed->mt_good_cells
                 WHERE fieldname = ls_mod_cells-fieldname.
          ls_protocol-msgid     = '/PSYNG/BASIS'.
          ls_protocol-msgno     = '038'.
          ls_protocol-msgty     = 'E'.
          ls_protocol-fieldname = ls_mod_cells-fieldname.
          ls_protocol-row_id    = ls_mod_cells-row_id.
          APPEND ls_protocol TO er_data_changed->mt_protocol.
          MESSAGE i038(/psyng/basis).
          CONTINUE.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
