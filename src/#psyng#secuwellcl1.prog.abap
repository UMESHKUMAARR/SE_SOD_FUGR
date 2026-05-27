*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SECUWELLCL1
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*
*----------------------------------------------------------------------*

*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SECUWELLCL1                                         *
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       CLASS lcl_dragdropdataobject DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_dragdropdataobject DEFINITION.
  PUBLIC SECTION.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_application DEFINITION.

  PUBLIC SECTION.
    METHODS:
      handle_left_tree_drag
        FOR EVENT on_drag_multiple
        OF cl_gui_simple_tree
        IMPORTING node_key_table drag_drop_object,
      handle_right_tree_drop
        FOR EVENT on_drop
        OF cl_gui_simple_tree
        IMPORTING node_key drag_drop_object,
      handle_left_tree_drop_complete
        FOR EVENT on_drop_complete_multiple
        OF cl_gui_simple_tree
        IMPORTING node_key_table drag_drop_object.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.

  METHOD handle_left_tree_drag.
    DATA: dataobj TYPE REF TO lcl_dragdropdataobject.

    " create the data object
    " the data object contains information about the dragged
    " object. Here: text of the node
    CREATE OBJECT dataobj .
    drag_drop_object->object = dataobj.
  ENDMETHOD.

  METHOD handle_right_tree_drop.
    DATA: local_node_table TYPE node_table_type,
          new_node         TYPE /psyng/mtrees,
          lt_node_keys     TYPE treev_nks.


    IF gf_dispchg = gc_display.
      MESSAGE i151(/psyng/sw).
      CALL METHOD drag_drop_object->abort.
      EXIT.
    ENDIF.

    CALL METHOD g_left_tree->get_selected_nodes
        CHANGING
          node_key_table               = lt_node_keys
        EXCEPTIONS
          cntl_system_error            = 1
          dp_error                     = 2
          failed                       = 3
          multiple_node_selection_only = 4
          OTHERS                       = 5.

    LOOP AT lt_node_keys INTO new_node-node_key.
      CASE g_yx_sectab-pressed_tab.
        WHEN c_yx_sectab-tab4.
          SELECT SINGLE description saptechname      "#EC CI_SEL_NESTED
                        INTO (/psyng/rolehdr-description,
                              /psyng/rolehdr-saptechname)
                        FROM /psyng/rolehdr
                        WHERE roleid = new_node-node_key.

          IF gf_disp_pfcg IS INITIAL.
            CONCATENATE new_node-node_key '-' /psyng/rolehdr-description
                                INTO new_node-text.
          ELSE.
            CONCATENATE new_node-node_key '-' /psyng/rolehdr-saptechname
                                INTO new_node-text.
          ENDIF.

          READ TABLE i_prole WITH KEY roleid = new_node-node_key
                             TRANSPORTING NO FIELDS.
        WHEN c_yx_sectab-tab5.
          SELECT SINGLE description                  "#EC CI_SEL_NESTED
                     INTO /psyng/position-description
                        FROM /psyng/position
                        WHERE positionid = new_node-node_key.
          CONCATENATE new_node-node_key ' -' /psyng/position-description
                              INTO new_node-text.

          READ TABLE j_prole WITH KEY positionid = new_node-node_key
                             TRANSPORTING NO FIELDS.
      ENDCASE.

      IF sy-subrc = 0.
        CONTINUE.
      ENDIF.

      " add a new node to the right tree
      " the node is inserted as last child of the
      " node on which was dropped
      new_node-relatkey = node_key.
      new_node-relatship = cl_gui_simple_tree=>relat_last_child.
      APPEND new_node TO local_node_table.
      " store node in global node table
      APPEND new_node TO right_node_table.
    ENDLOOP.

    IF NOT local_node_table[] IS INITIAL.
      CALL METHOD g_right_tree->add_nodes
        EXPORTING
          table_structure_name = '/PSYNG/MTREES'
          node_table           = local_node_table
        EXCEPTIONS
          failed                         = 1
          error_in_node_table            = 2
          dp_error                       = 3
          table_structure_name_not_found = 4
          OTHERS                         = 5.
      IF sy-subrc <> 0.
*         MESSAGE A000.
      ENDIF.

      CALL METHOD g_right_tree->expand_root_nodes
           EXPORTING
                expand_subtree      = 'X'
           EXCEPTIONS
                failed              = 1
                illegal_level_count = 2
                cntl_system_error   = 3.
    ENDIF.
  ENDMETHOD.

  METHOD handle_left_tree_drop_complete.
    FIELD-SYMBOLS: <nodekey> TYPE tv_nodekey.


    LOOP AT node_key_table ASSIGNING <nodekey>.
      IF user = 'X'. "#EC SAST_CI_GEN_CHECK
        u_role-positionid = <nodekey>.
        APPEND u_role TO j_prole.
        SORT j_prole.
        DELETE ADJACENT DUPLICATES FROM j_prole.

        SELECT pdet~roleid INTO p_role-roleid        "#EC CI_SEL_NESTED
          FROM /psyng/usrdet AS udet INNER JOIN /psyng/posndet AS pdet
            ON udet~positionid = pdet~positionid
         WHERE udet~userid = <nodekey>.

          APPEND p_role TO i_prole.
        ENDSELECT.
      ELSE.
        p_role-roleid = <nodekey>.
        APPEND p_role TO i_prole.
      ENDIF.
    ENDLOOP.

    PERFORM populate_transactions.
    PERFORM populate_conflict.
    PERFORM populate_conflict2.
    CLEAR u_role.
    CLEAR p_role.
  ENDMETHOD.
ENDCLASS.

*For System filter configuration GUI

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

*--To implement user commands
      handle_user_command
                    FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm,

*--Search help
      handle_on_f4
                    FOR EVENT onf4 OF cl_gui_alv_grid
        IMPORTING e_fieldname es_row_no   er_event_data.



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

*--Handle User Command
  METHOD handle_user_command .
    CASE sy-dynnr.
      WHEN '0908'.
        CASE e_ucomm.
          WHEN 'EXIT'.
            SET SCREEN 0.
            LEAVE SCREEN.
          WHEN 'SAVE'.
            PERFORM save_syscon_data.

          WHEN 'DISPCHANGE'.

            IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
              IF gf_dispchg = gc_change.
                gf_dispchg1 = gc_change.
              ENDIF.
            ELSE.                            "Change mode to DISPLAY
              gf_dispchg1 = gc_display.
              PERFORM get_syscon_existing_data.
            ENDIF.
            PERFORM display_confltr_alv.
        ENDCASE.

      WHEN '0909'.
        CASE e_ucomm.
          WHEN 'EXIT'.
            SET SCREEN 0.
            LEAVE SCREEN.
          WHEN 'SAVE'.
            PERFORM save_sysfun_data.
          WHEN 'DISPCHANGE'.
            IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
              IF gf_dispchg = gc_change.
                gf_dispchg1 = gc_change.
              ENDIF.
            ELSE.                            "Change mode to DISPLAY
              gf_dispchg1 = gc_display.
              PERFORM get_sysfun_existing_data.
            ENDIF.
            PERFORM display_funfltr_alv.
        ENDCASE.

      WHEN '0910'.
        CASE e_ucomm.
          WHEN 'EXIT'.
            SET SCREEN 0.
            LEAVE SCREEN.
          WHEN 'SAVE'.
            PERFORM save_sysca_data.
          WHEN 'DISPCHANGE'.
            IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
              IF gf_dispchg = gc_change.
                gf_dispchg1 = gc_change.
              ENDIF.
            ELSE.                            "Change mode to DISPLAY
              gf_dispchg1 = gc_display.
              PERFORM get_sysca_existing_data.
            ENDIF.
            PERFORM display_cafltr_alv.
        ENDCASE.

      WHEN '0911'.
        CASE e_ucomm.
          WHEN 'EXIT'.
            SET SCREEN 0.
            LEAVE SCREEN.
          WHEN 'SAVE'.
            PERFORM save_systcd_data.
          WHEN 'DISPCHANGE'.
            IF gf_dispchg1 = gc_display.      "Change mode to CHANGE
              IF gf_dispchg = gc_change.
                gf_dispchg1 = gc_change.
              ENDIF.
            ELSE.                            "Change mode to DISPLAY
              gf_dispchg1 = gc_display.
              PERFORM get_systcd_existing_data.
            ENDIF.
            PERFORM display_tcdfltr_alv.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.


  METHOD handle_on_f4 .
    PERFORM f4_help USING e_fieldname es_row_no .
    er_event_data->m_event_handled = 'X'.
  ENDMETHOD.

ENDCLASS.

DATA: gr_event_handler  TYPE REF TO  lcl_event_handler,
      gr_event_handler_fun TYPE REF TO lcl_event_handler,
      gr_event_handler_ca TYPE REF TO lcl_event_handler,
      gr_event_handler_tcd TYPE REF TO lcl_event_handler,
      gr_event_handler_audit TYPE REF TO lcl_event_handler.
