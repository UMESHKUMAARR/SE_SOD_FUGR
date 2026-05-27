*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_UTLS2F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  init_editor
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_editor.
  DATA: l_text       TYPE TABLE OF char80.      "Added RKANAKA(02-01-08)
  STATICS: l_text_reload TYPE /psyng/flagx,
           lo_textedit   TYPE REF TO cl_gui_textedit,
           lo_container  TYPE REF TO cl_gui_custom_container.


  IF l_text_reload = space.
    l_text_reload = 'X'.

*   create control container
    IF lo_textedit IS INITIAL.
      CREATE OBJECT lo_container
          EXPORTING
              container_name              = 'STEXTEDITOR'
          EXCEPTIONS
              cntl_error                  = 1
              cntl_system_error           = 2
              create_error                = 3
              lifetime_error              = 4
              lifetime_dynpro_dynpro_link = 5.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.

*   create calls constructor, which initializes, creats and links
*    a TextEdit Control
      CREATE OBJECT lo_textedit
        EXPORTING
           parent = lo_container
           wordwrap_mode = cl_gui_textedit=>wordwrap_at_fixed_position
           wordwrap_to_linebreak_mode = cl_gui_textedit=>false
        EXCEPTIONS
            others = 1.

      IF sy-subrc NE 0.
        MESSAGE e802(bmen).
      ENDIF.
    ENDIF.

    CALL METHOD lo_textedit->set_readonly_mode
          EXPORTING
            readonly_mode          = cl_gui_textedit=>true
          EXCEPTIONS
            error_cntl_call_method = 1
            invalid_parameter      = 2.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
  ENDIF.

  l_text[] = gt_text[].

* fill with text
  CALL METHOD lo_textedit->set_text_as_r3table
    EXPORTING
      table           = l_text
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDFORM.                    " init_editor
