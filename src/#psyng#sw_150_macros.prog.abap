*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_137_MACROS                                       *
*----------------------------------------------------------------------*
DATA : g_mac_dum_str    TYPE string.
define exit_if_has_children.
  clear gf_node_has_children.
  read table gt_node with key relatkey = &1
  transporting no fields.
  if sy-subrc = 0.
   gf_node_has_children = 'X'.
  endif.
end-of-definition.
DEFINE child_node.
  g_mac_dum_str = &5.
  clear ls_node.
  concatenate &4 '_' g_mac_dum_str into ls_node-node_key.
  ls_node-relatkey = &3.
  ls_node-relatship = cl_gui_column_tree=>relat_last_child.
  ls_node-isfolder  = 'X'.
  ls_node-expander  = 'X'.
  if not &8 = ''.
    ls_node-n_image     = &8.
    ls_node-exp_image   = &8.
  else.
  endif.
  append ls_node to &1.
*--Also create DATA (text) item
  clear ls_item.
  ls_item-node_key  = ls_node-node_key.
  ls_item-item_name = 'DATA'.
  ls_item-class     = cl_gui_column_tree=>item_class_link.
  ls_item-text      = &6.
*--Icon for node text
  if not &9 = ''.
    ls_item-t_image     = &9.
  endif.
  append ls_item to &2.
  clear ls_item.
  if not &7 is initial.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = 'HEADER'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.
    g_mac_dum_str     = &7.
    ls_item-text      = g_mac_dum_str.
    append ls_item to &2.
  endif.
END-OF-DEFINITION.
DEFINE leaf_node.
  g_mac_dum_str = &5.
  clear ls_node.
*    ls_node-node_key = &3.
  concatenate &4 '_' g_mac_dum_str into ls_node-node_key.
  ls_node-relatkey = &3.
  ls_node-relatship = cl_gui_column_tree=>relat_last_child.
  ls_node-isfolder  = ''.
  ls_node-expander  = ''.
  if not &8 = ''.
    ls_node-n_image     = &8.
    ls_node-exp_image   = &8.
  else.
  endif.
  append ls_node to &1.
*--Also create DATA (text) item
  clear ls_item.
  ls_item-node_key  = ls_node-node_key.
  ls_item-item_name = 'DATA'.
  ls_item-class     = cl_gui_column_tree=>item_class_link.
  ls_item-text      = &6.
*--Icon for node text
  if not &9 = ''.
    ls_item-t_image     = &9.
  endif.
  append ls_item to &2.
  clear ls_item.
  if not &7 is initial.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = 'HEADER'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.
    g_mac_dum_str     = &7.
    ls_item-text      = g_mac_dum_str.
    append ls_item to &2.
  endif.
END-OF-DEFINITION.
DEFINE leaf_node_inactive.
  g_mac_dum_str = &5.
  clear ls_node.
  concatenate &4 '_' g_mac_dum_str into ls_node-node_key.
  ls_node-relatkey = &3.
  ls_node-relatship = cl_gui_column_tree=>relat_last_child.
  ls_node-isfolder  = ''.
  ls_node-expander  = ''.
  if not &8 = ''.
    ls_node-n_image     = &8.
    ls_node-exp_image   = &8.
  else.
  endif.
  append ls_node to &1.
*--Also create DATA (text) item
  clear ls_item.
  ls_item-node_key  = ls_node-node_key.
  ls_item-item_name = 'DATA'.
  ls_item-class     = cl_gui_column_tree=>item_class_link.
  ls_item-text      = &6.
*--Inactive
  ls_item-style =   cl_gui_column_tree=>style_inactive.
*--Icon for node text
  if not &9 = ''.
    ls_item-t_image     = &9.
  endif.
  append ls_item to &2.
  clear ls_item.
  if not &7 is initial.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = 'HEADER'.
    ls_item-class     = cl_gui_column_tree=>item_class_text.
    g_mac_dum_str     = &7.
    ls_item-text      = g_mac_dum_str.
*--Inactive
    ls_item-style =   cl_gui_column_tree=>style_inactive.
    append ls_item to &2.
  endif.
  clear ls_item-style.
END-OF-DEFINITION.
DEFINE text_column.
  clear ls_item.
  ls_item-node_key  = &2.
  ls_item-item_name = &3.
  ls_item-class     = cl_gui_column_tree=>item_class_text.
  g_mac_dum_str     = &4.
  ls_item-text      = g_mac_dum_str .
  condense ls_item-text.
*--Icon for node text
  if not &5 = ''.
    ls_item-t_image     = &5.
  endif.
*--Inactive
  if &6 eq 'X'.
  ls_item-style =   cl_gui_column_tree=>style_inactive.
  endif.
  append ls_item to &1.
  clear ls_item-style.
END-OF-DEFINITION.
DEFINE link_column.
  clear ls_item.
  ls_item-node_key  = &2.
  ls_item-item_name = &3.
  ls_item-class     = cl_gui_column_tree=>item_class_link.
  g_mac_dum_str     = &4.
  ls_item-text      = g_mac_dum_str .
  condense ls_item-text.
*--Icon for node text
  if not &5 = ''.
    ls_item-t_image     = &5.
  endif.
  append ls_item to &1.
END-OF-DEFINITION.
DEFINE link_column_style.
  clear ls_item.
  ls_item-node_key  = &2.
  ls_item-item_name = &3.
  ls_item-class     = cl_gui_column_tree=>item_class_link.
  g_mac_dum_str     = &4.
  ls_item-text      = g_mac_dum_str .
  condense ls_item-text.
*--Icon for node text
  if not &5 = ''.
    ls_item-t_image     = &5.
  endif.
  ls_item-style = &6.
  append ls_item to &1.
END-OF-DEFINITION.

DEFINE hidden_column.
  clear ls_item.
  ls_item-node_key  = &2.
  ls_item-item_name = &3.
  g_mac_dum_str     = &4.
  ls_item-text      = g_mac_dum_str .
  ls_item-hidden    = 'X'.
  append ls_item to &1.
END-OF-DEFINITION.
*--macro to get column value
DATA : ls_macro_item LIKE LINE OF gt_item.

DEFINE tree_get_col_val.
  read table gt_item with key node_key  = &1
                               item_name = &2
  into ls_macro_item transporting text.
  &3 = ls_macro_item-text.
END-OF-DEFINITION.
