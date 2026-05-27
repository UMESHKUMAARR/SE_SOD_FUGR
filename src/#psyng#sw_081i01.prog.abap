*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081I01                                           *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  PAI_0100  INPUT
*&---------------------------------------------------------------------*
*       PAI for screen 100
*----------------------------------------------------------------------*
MODULE pai_0100 INPUT.
* CL_GUI_CFW=>DISPATCH must be called if events are registered
* that trigger PAI
* this method calls the event handler method of an event
  CALL METHOD cl_gui_cfw=>dispatch
    IMPORTING return_code = g_return_code.
  IF g_return_code <> cl_gui_cfw=>rc_noevent.
    " a control event occured => exit PAI
    CLEAR sy-ucomm.
    EXIT.
  ENDIF.

  CASE sy-ucomm.
    WHEN 'BACK'.                       "Leave program
      IF NOT go_container IS INITIAL.
        " destroy tree container (detroys contained tree control, too)
        CALL METHOD go_container->free
          EXCEPTIONS
            cntl_system_error = 1
            cntl_error        = 2.
        IF sy-subrc <> 0.
          MESSAGE a000.
        ENDIF.

        CLEAR: go_container, go_tree.
      ENDIF.
*      CLEAR sy-ucomm.
*      CALL SELECTION-SCREEN 1000.
*      IF sy-ucomm NE 'CRET'.
        SET SCREEN 0.
*      ENDIF.
*      LEAVE SCREEN.

    WHEN 'EXPND'.                      "Expand selected node
*     Get selected node and expand
      CALL METHOD go_tree->get_selected_node
           IMPORTING
                node_key                   = g_node_key
           EXCEPTIONS
                failed                     = 1
                single_node_selection_only = 2
                cntl_system_error          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF g_node_key IS INITIAL.
        MESSAGE i398(00) WITH text-e01 text-e02.
        EXIT.
      ENDIF.

      CALL METHOD go_tree->expand_node
           EXPORTING
                node_key            = g_node_key
                expand_subtree      = 'X'
           EXCEPTIONS
                failed              = 1
                illegal_level_count = 2
                cntl_system_error   = 3
                node_not_found      = 4
                cannot_expand_leaf  = 5.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'EXPNDALL'.                   "Expand all nodes
      CALL METHOD go_tree->expand_root_nodes
           EXPORTING
                expand_subtree = 'X'
           EXCEPTIONS
                failed              = 1
                illegal_level_count = 2
                cntl_system_error   = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'COLLPS'.                     "Collapse selected node
*     Get selected node and collapse
      CALL METHOD go_tree->get_selected_node
           IMPORTING
                node_key                   = g_node_key
           EXCEPTIONS
                failed                     = 1
                single_node_selection_only = 2
                cntl_system_error          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF g_node_key IS INITIAL.
        MESSAGE i398(00) WITH text-e01 text-e02.
        EXIT.
      ENDIF.

      CALL METHOD go_tree->collapse_subtree
           EXPORTING
                node_key          = g_node_key
           EXCEPTIONS
                failed            = 1
                node_not_found    = 2
                cntl_system_error = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'COLLPSALL'.                  "Collapse all nodes
      CALL METHOD go_tree->collapse_all_nodes
           EXCEPTIONS
                failed            = 1
                cntl_system_error = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
  ENDCASE.

  CLEAR sy-ucomm.
ENDMODULE.                 " pai_0100  INPUT
