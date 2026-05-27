*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081CL1                                           *
*----------------------------------------------------------------------*
CLASS gcl_application DEFINITION.
  PUBLIC SECTION.
    METHODS: handle_node_double_click
                 FOR EVENT node_double_click OF cl_gui_list_tree
                 IMPORTING node_key,
             handle_item_double_click
                 FOR EVENT item_double_click OF cl_gui_list_tree
                 IMPORTING node_key item_name.
ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS GCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS gcl_application IMPLEMENTATION.
  METHOD handle_node_double_click.
    " this method handles the node double click event of the tree
    " control instance
    g_node_key = node_key.
    PERFORM show_tree_details USING node_key.
  ENDMETHOD.

  METHOD handle_item_double_click.
    " this method handles the item double click event of the tree
    " control instance
    g_node_key = node_key.
    PERFORM show_tree_details USING node_key.
  ENDMETHOD.
ENDCLASS.
