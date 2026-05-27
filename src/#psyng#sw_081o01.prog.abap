*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081O01                                           *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  PBO_0100  OUTPUT
*&---------------------------------------------------------------------*
*       PBO for screen 100
*----------------------------------------------------------------------*
MODULE pbo_0100 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'MAIN' WITH p_lvrsio p_rvrsio.

  IF go_tree IS INITIAL.
    PERFORM create_and_init_tree.
  ENDIF.

  PERFORM init_alv_detail USING g_node_key(2).
  PERFORM init_alv_object USING g_node_key(2).
  PERFORM init_text USING g_node_key(1).

* The first character of the node key tells what type of data to display
  CASE g_node_key(1).
    WHEN space OR 'Z'.
      LOOP AT SCREEN.
        screen-active    = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN 'F'.                "Functions
      LOOP AT SCREEN.
        CHECK screen-name CS 'IMP' OR screen-name CS 'ID2' OR
              screen-name CS 'OBJECT2'.
        screen-active    = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDLOOP.
    WHEN 'C'.                "Conflicts
      g_lid2_text = text-005.
      g_rid2_text = text-005.

    WHEN 'A'.                "Critical Auths
      LOOP AT SCREEN.
        CHECK
*        screen-name CS 'OWNER' OR
        screen-name CS 'BUSAREA'.
*              screen-name CS 'IMP'.
        screen-active    = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDLOOP.

      g_lid2_text = text-006.
      g_rid2_text = text-006.

    WHEN 'T'.
     LOOP AT SCREEN.
        CHECK screen-name CS 'DESC' OR screen-name CS 'ID2' OR
              screen-name CS 'LONGTEXT'.
        screen-active    = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDLOOP.

    when 'R' OR 'P'.  "Critical Tcodes, Roles or Profiles
      LOOP AT SCREEN.
        CHECK screen-name CS 'DESC'
*        OR screen-name CS 'OWNER'
         OR screen-name CS 'BUSAREA' OR screen-name CS 'ID2' OR
              screen-name CS 'LONGTEXT'.
        screen-active    = 0.
        screen-invisible = 1.
        MODIFY SCREEN.
      ENDLOOP.
  ENDCASE.
ENDMODULE.                 " pbo_0100  OUTPUT
