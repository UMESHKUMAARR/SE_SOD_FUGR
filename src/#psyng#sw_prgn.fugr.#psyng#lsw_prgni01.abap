*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  IF sy-ucomm = 'CONTINUE'.
    SET SCREEN 000.
    LEAVE SCREEN.
  ELSEIF sy-ucomm = 'STOP' or sy-ucomm = 'CANCEL'.
    gf_stop = 'X'.
    SET SCREEN 000.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.                 " USER_COMMAND_0100  INPUT

MODULE user_command_0200 INPUT.
  IF sy-ucomm = 'CONTINUE'.
    SET SCREEN 000.
    LEAVE SCREEN.
  ELSEIF sy-ucomm = 'STOP' or sy-ucomm = 'CANCEL'.
    gf_stop = 'X'.
    SET SCREEN 000.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
