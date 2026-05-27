*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_IMPORT_F01
*&---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  VAILDATE_FILE_PATH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM vaildate_file_path .

IF p_upload IS INITIAL.
  MESSAGE 'Please enter file path'(T01)
  TYPE 'W' DISPLAY LIKE 'E'.
  LEAVE LIST-PROCESSING.
ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SEL_SCREEN_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sel_screen_output .
  LOOP AT SCREEN.

    IF screen-group1 EQ 'TDA'.
      IF p_meta EQ 'X'.
*        screen-input = 1.
        screen-active = 1.
        screen-invisible = 0.
      ELSE.
*        screen-input = 0.
        screen-active = 0.
        screen-invisible = 1.
      ENDIF.
    ENDIF.
    MODIFY SCREEN.
  ENDLOOP.
ENDFORM.
