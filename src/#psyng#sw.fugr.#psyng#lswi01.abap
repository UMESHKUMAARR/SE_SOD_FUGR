*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/LSWI01                                              *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  user_command_1000  INPUT
*&---------------------------------------------------------------------*
MODULE user_command_1000 INPUT.
  CASE sy-ucomm.
    WHEN 'PREV'.
      LEAVE TO SCREEN 0.

    WHEN 'DISPTXN'.
      REFRESH gt_tstct.
      CLEAR tc_tstct-lines.
      READ TABLE gt_funct WITH KEY sel = 'X'.

      CHECK sy-subrc = 0.

* Get list of tcodes to use in for all entries clause in select!
      DATA : BEGIN OF lt_tcodes OCCURS 0,
                tcode TYPE tcode,
             END OF lt_tcodes,
             ls_tcode LIKE LINE OF lt_tcodes,
             ls_tcode_range LIKE LINE OF gr_tcode,
             lt_tcode_range LIKE TABLE OF ls_tcode_range.
      FIELD-SYMBOLS : <tstct> LIKE LINE OF gt_tstct.
      REFRESH : lt_tcode_range[].
      LOOP AT gr_tcode INTO ls_tcode_range.
        IF ls_tcode_range-option = 'EQ' AND ls_tcode_range-sign = 'I'.
          ls_tcode-tcode = ls_tcode_range-low.
          APPEND ls_tcode TO lt_tcodes.
        ELSE.
          APPEND ls_tcode_range TO lt_tcode_range.
        ENDIF.
      ENDLOOP.
*    select the ranges
      IF NOT lt_tcode_range[] IS INITIAL.
        SELECT tcode FROM tstc
            APPENDING TABLE lt_tcodes
            WHERE tcode IN  lt_tcode_range .
      ENDIF.
*    delete unnecessary lines
      DELETE lt_tcodes WHERE NOT tcode  IN gr_tcode.
      SORT lt_tcodes.
      DELETE ADJACENT DUPLICATES FROM lt_tcodes.
*    select tcodes in function and within range of tcodes
      IF NOT lt_tcodes[] IS INITIAL.
        SELECT /psyng/functtran~tcode tstct~ttext INTO TABLE gt_tstct
          FROM /psyng/functtran
*        INNER JOIN tstct
         LEFT OUTER JOIN tstct

            ON /psyng/functtran~tcode = tstct~tcode AND
            tstct~sprsl = sy-langu
          FOR ALL entries IN lt_tcodes
          WHERE
            /psyng/functtran~vrsio = /psyng/conflict-vrsio
            AND /psyng/functtran~functionid = gt_funct-function
            AND /psyng/functtran~tcode = lt_tcodes-tcode.
*           AND tstct~sprsl = sy-langu.
      ENDIF.
*     SELECT tstct~tcode tstct~ttext INTO TABLE gt_tstct
*       FROM /psyng/functtran
*      INNER JOIN tstct
*         ON /psyng/functtran~tcode = tstct~tcode
*       WHERE
*         /psyng/functtran~vrsio = /psyng/conflict-vrsio
*         AND /psyng/functtran~functionid = gt_funct-function
*         AND /psyng/functtran~tcode IN gr_tcode
*         AND tstct~sprsl = sy-langu.
      LOOP AT gt_tstct ASSIGNING <tstct> WHERE ttext = '' .
*            --TCOde does not exist in this system
        IF <tstct>-tcode  CP
            /psyng/sw_cl_constants=>placeholder_tcode_prefix.
          <tstct>-ttext =
          'Placeholder for objectlevel analysis'(035).
        ELSE.
          <tstct>-ttext =
          'Tcode for cross system analysis'(036).
        ENDIF.
      ENDLOOP.

      FREE : lt_tcodes[], lt_tcode_range[].
      DESCRIBE TABLE gt_tstct LINES tc_tstct-lines.

  ENDCASE.
ENDMODULE.                 " user_command_1000  INPUT

*&---------------------------------------------------------------------*
*&      Module  gt_funct_mark  INPUT
*&---------------------------------------------------------------------*
MODULE gt_funct_mark INPUT.
  LOOP AT gt_funct WHERE sel = 'X'.
    gt_funct-sel = space.
    MODIFY gt_funct.
  ENDLOOP.

  READ TABLE gt_funct INDEX tc_funct-current_line.
  gt_funct-sel = 'X'.
  MODIFY gt_funct INDEX tc_funct-current_line.
ENDMODULE.                 " gt_funct_mark  INPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_1100  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 1100
*----------------------------------------------------------------------*
MODULE user_command_1100 INPUT.
  CASE sy-ucomm.
    WHEN 'PREV'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " user_command_1100  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1200 INPUT.

  CASE sy-ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_1200  INPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_1201  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_1201 INPUT.
  SET SCREEN 0.
  LEAVE SCREEN.
ENDMODULE.                 " USER_COMMAND_1201  INPUT
