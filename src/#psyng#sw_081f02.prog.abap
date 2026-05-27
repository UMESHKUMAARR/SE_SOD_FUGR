*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_081F01                                           *
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  CREATE_AND_INIT_TREE
*&---------------------------------------------------------------------*
*       Create and initialize tree objects
*----------------------------------------------------------------------*
FORM create_and_init_tree.
  DATA: lt_node   TYPE treev_ntab,
        lt_item   TYPE t_item_table,
        lt_events TYPE cntl_simple_events,
        ls_event  TYPE cntl_simple_event.

* create a container for the tree control
  CREATE OBJECT go_container
    EXPORTING
      container_name              = 'G_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* create a list tree control
  CREATE OBJECT go_tree
    EXPORTING
      parent                      = go_container
      node_selection_mode       = cl_gui_list_tree=>node_sel_mode_single
      item_selection              = 'X'
      with_headers                = ' '
    EXCEPTIONS
      cntl_system_error           = 1
      create_error                = 2
      failed                      = 3
      illegal_node_selection_mode = 4
      lifetime_error              = 5.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* define the events which will be passed to the backend
  " node double click
  ls_event-eventid = cl_gui_list_tree=>eventid_node_double_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.
  " item double click
  ls_event-eventid = cl_gui_list_tree=>eventid_item_double_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.

  CALL METHOD go_tree->set_registered_events
    EXPORTING
      events                    = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* assign event handlers in the application class to each desired event
  SET HANDLER go_application->handle_node_double_click FOR go_tree.
  SET HANDLER go_application->handle_item_double_click FOR go_tree.

  PERFORM build_node_and_item_table CHANGING lt_node lt_item.

  CALL METHOD go_tree->add_nodes_and_items
    EXPORTING
      node_table                     = lt_node
      item_table                     = lt_item
      item_table_structure_name      = 'MTREEITM'
    EXCEPTIONS
      failed                         = 1
      cntl_system_error              = 3
      error_in_tables                = 4
      dp_error                       = 5
      table_structure_name_not_found = 6.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.
ENDFORM.                               " CREATE_AND_INIT_TREE

*&---------------------------------------------------------------------*
*&      Form  build_node_and_item_table
*&---------------------------------------------------------------------*
*       Build the node and item tables
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_node_and_item_table CHANGING et_node TYPE treev_ntab
                                        et_item TYPE t_item_table.


  IF p_cfunc = 'X'.
    PERFORM build_tree_function CHANGING et_node et_item.
  ENDIF.
  IF p_cconf = 'X'.
    PERFORM build_tree_conflict CHANGING et_node et_item.
  ENDIF.
  IF p_ctran = 'X'.
    PERFORM build_tree_crit_tcodes CHANGING et_node et_item.
  ENDIF.
  IF p_cauth = 'X'.
    PERFORM build_tree_crit_auths CHANGING et_node et_item.
  ENDIF.
  IF p_crole = 'X'.
    PERFORM build_tree_crit_roles CHANGING et_node et_item.
  ENDIF.
  IF p_cprof = 'X'.
    PERFORM build_tree_crit_profs CHANGING et_node et_item.
  ENDIF.
ENDFORM.                               " build_node_and_item_table

*&---------------------------------------------------------------------*
*&      Form  build_tree_function
*&---------------------------------------------------------------------*
*       Build the tree for functions
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_function CHANGING et_node TYPE treev_ntab
                                  et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <func> TYPE /psyng/function.


  CLEAR ls_node.
  ls_node-node_key = 'ZZFUNCTION'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZFUNCDIFF'.
  ls_node-relatkey = 'ZZFUNCTION'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZFUNCTION'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h12.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZFUNCDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_lfunction ASSIGNING <func>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'FD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZFUNCDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <func>-function.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLFUNCNOEX'.
  ls_node-relatkey = 'ZZFUNCTION'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLFUNCNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmfunction ASSIGNING <func>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'FL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLFUNCNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <func>-function.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRFUNCNOEX'.
  ls_node-relatkey = 'ZZFUNCTION'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRFUNCNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmfunction ASSIGNING <func>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'FR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRFUNCNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <func>-function.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMEFUNC'.
  ls_node-relatkey = 'ZZFUNCTION'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMEFUNC'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_sfunction ASSIGNING <func>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'FS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMEFUNC'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <func>-function.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_function

*&---------------------------------------------------------------------*
*&      Form  build_tree_conflict
*&---------------------------------------------------------------------*
*       Build the tree for conflicts
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_conflict CHANGING et_node TYPE treev_ntab
                                  et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <conf> TYPE /psyng/conflict.


  CLEAR ls_node.
  ls_node-node_key = 'ZZCONFLICT'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZCONFDIFF'.
  ls_node-relatkey = 'ZZCONFLICT'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCONFLICT'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h13.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCONFDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_lconflict ASSIGNING <conf>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'CD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZCONFDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <conf>-conid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLCONFNOEX'.
  ls_node-relatkey = 'ZZCONFLICT'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLCONFNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmconflict ASSIGNING <conf>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'CL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLCONFNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <conf>-conid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRCONFNOEX'.
  ls_node-relatkey = 'ZZCONFLICT'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRCONFNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmconflict ASSIGNING <conf>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'CR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRCONFNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <conf>-conid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMECONF'.
  ls_node-relatkey = 'ZZCONFLICT'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMECONF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_sconflict ASSIGNING <conf>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'CS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMECONF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <conf>-conid.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_conflict

*&---------------------------------------------------------------------*
*&      Form  build_tree_crit_tcodes
*&---------------------------------------------------------------------*
*       Build the tree for critical tcodes
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_crit_tcodes CHANGING et_node TYPE treev_ntab
                                     et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <tran> TYPE /psyng/critcodes.


  CLEAR ls_node.
  ls_node-node_key = 'ZZCRITCODES'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZTCODEDIFF'.
  ls_node-relatkey = 'ZZCRITCODES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCRITCODES'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h14.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZTCODEDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_ldcritcodes ASSIGNING <tran>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'TD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZTCODEDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <tran>-tcode.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLTCODENOEX'.
  ls_node-relatkey = 'ZZCRITCODES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLTCODENOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmtran ASSIGNING <tran>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'TL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLTCODENOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <tran>-tcode.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRTCODENOEX'.
  ls_node-relatkey = 'ZZCRITCODES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRTCODENOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmtran ASSIGNING <tran>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'TR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRTCODENOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <tran>-tcode.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMETCODE'.
  ls_node-relatkey = 'ZZCRITCODES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMETCODE'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_stran ASSIGNING <tran>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'TS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMETCODE'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <tran>-tcode.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_crit_tcodes

*&---------------------------------------------------------------------*
*&      Form  build_tree_crit_auths
*&---------------------------------------------------------------------*
*       Build the tree for critical authorizations
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_crit_auths CHANGING et_node TYPE treev_ntab
                                    et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <auth> TYPE /psyng/swaudhdr.


  CLEAR ls_node.
  ls_node-node_key = 'ZZCRIAUTHS'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZAUTHDIFF'.
  ls_node-relatkey = 'ZZCRIAUTHS'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCRIAUTHS'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h15.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZAUTHDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_ldauth ASSIGNING <auth>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'AD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZAUTHDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <auth>-swaudid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLAUTHNOEX'.
  ls_node-relatkey = 'ZZCRIAUTHS'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLAUTHNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmauth ASSIGNING <auth>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'AL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLAUTHNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <auth>-swaudid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRAUTHNOEX'.
  ls_node-relatkey = 'ZZCRIAUTHS'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRAUTHNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmauth ASSIGNING <auth>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'AR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRAUTHNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <auth>-swaudid.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMEAUTH'.
  ls_node-relatkey = 'ZZCRIAUTHS'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMEAUTH'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_sauth ASSIGNING <auth>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'AS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMEAUTH'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <auth>-swaudid.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_crit_auths

*&---------------------------------------------------------------------*
*&      Form  build_tree_crit_roles
*&---------------------------------------------------------------------*
*       Build the tree for critical roles
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_crit_roles CHANGING et_node TYPE treev_ntab
                                    et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <role> TYPE /psyng/criroles.


  CLEAR ls_node.
  ls_node-node_key = 'ZZCRIROLES'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZROLEDIFF'.
  ls_node-relatkey = 'ZZCRIROLES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCRIROLES'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h16.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZROLEDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_ldrole ASSIGNING <role>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'RD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZROLEDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <role>-agr_name.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLROLENOEX'.
  ls_node-relatkey = 'ZZCRIROLES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLROLENOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmrole ASSIGNING <role>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'RL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLROLENOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <role>-agr_name.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRROLENOEX'.
  ls_node-relatkey = 'ZZCRIROLES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRROLENOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmrole ASSIGNING <role>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'RR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRROLENOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <role>-agr_name.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMEROLE'.
  ls_node-relatkey = 'ZZCRIROLES'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMEROLE'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_srole ASSIGNING <role>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'RS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMEROLE'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <role>-agr_name.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_crit_roles

*&---------------------------------------------------------------------*
*&      Form  build_tree_crit_profs
*&---------------------------------------------------------------------*
*       Build the tree for critical profiles
*----------------------------------------------------------------------*
*      <--ET_NODE  Tree nodes
*      <--ET_ITEM  Tree items
*----------------------------------------------------------------------*
FORM build_tree_crit_profs CHANGING et_node TYPE treev_ntab
                                    et_item TYPE t_item_table.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i.

  FIELD-SYMBOLS: <prof> TYPE /psyng/criprof.


  CLEAR ls_node.
  ls_node-node_key = 'ZZCRIPROF'." Key of the node
  ls_node-hidden   = ' '.       " The node is visible,
  ls_node-disabled = ' '.       " selectable,
  ls_node-isfolder = 'X'.       " a folder.
  APPEND ls_node TO et_node.

  CLEAR ls_node.
  ls_node-node_key = 'ZZPROFDIFF'.
  ls_node-relatkey = 'ZZCRIPROF'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZCRIPROF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h17.
  APPEND ls_item TO et_item.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZPROFDIFF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h18.
  APPEND ls_item TO et_item.

  LOOP AT gt_ldprof ASSIGNING <prof>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'PD' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZPROFDIFF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <prof>-profile.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZLPROFNOEX'.
  ls_node-relatkey = 'ZZCRIPROF'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZLPROFNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_lvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_rmprof ASSIGNING <prof>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'PL' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZLPROFNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <prof>-profile.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZRPROFNOEX'.
  ls_node-relatkey = 'ZZCRIPROF'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZRPROFNOEX'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  CONCATENATE text-h07 p_rvrsio INTO ls_item-text SEPARATED BY space.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_lmprof ASSIGNING <prof>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'PR' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZRPROFNOEX'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <prof>-profile.
    APPEND ls_item TO et_item.
  ENDLOOP.

  CLEAR ls_node.
  ls_node-node_key = 'ZZSAMEPROF'.
  ls_node-relatkey = 'ZZCRIPROF'.
  ls_node-relatship = cl_gui_list_tree=>relat_last_child.
  ls_node-isfolder = 'X'.
  APPEND ls_node TO et_node.

  CLEAR ls_item.
  ls_item-node_key  = 'ZZSAMEPROF'.
  ls_item-item_name = '1'.
  ls_item-class     = cl_gui_list_tree=>item_class_text.
  ls_item-alignment = cl_gui_list_tree=>align_auto.
  ls_item-font      = cl_gui_list_tree=>item_font_prop.
  ls_item-text      = text-h19.
  APPEND ls_item TO et_item.

  CLEAR l_index.
  LOOP AT gt_sprof ASSIGNING <prof>.
    ADD 1 TO l_index.

    CLEAR ls_node.
    ls_node-node_key = l_index.
    CONDENSE ls_node-node_key.
    CONCATENATE 'PS' ls_node-node_key INTO ls_node-node_key.
    ls_node-relatkey  = 'ZZSAMEPROF'.
    ls_node-relatship = cl_gui_list_tree=>relat_last_child.
    ls_node-n_image   = '@10@'.
    APPEND ls_node TO et_node.

    CLEAR ls_item.
    ls_item-node_key  = ls_node-node_key.
    ls_item-item_name = l_index.
    CONDENSE ls_item-item_name.
    ls_item-class     = cl_gui_list_tree=>item_class_text.
    ls_item-alignment = cl_gui_list_tree=>align_auto.
    ls_item-font      = cl_gui_list_tree=>item_font_prop.
    ls_item-text      = <prof>-profile.
    APPEND ls_item TO et_item.
  ENDLOOP.
ENDFORM.                    " build_tree_crit_profs

*&---------------------------------------------------------------------*
*&      Form  show_tree_details
*&---------------------------------------------------------------------*
*       Show the detail of the node that was chosen on the tree
*----------------------------------------------------------------------*
*      -->i_NODE_KEY  Tree node key
*----------------------------------------------------------------------*
FORM show_tree_details USING    i_node_key TYPE tv_nodekey.
  CLEAR: g_lid, g_rid, g_ldesc, g_rdesc, g_linactive, g_rinactive,
         g_limp, g_rimp, g_lowner, g_rowner, g_lbusarea, g_rbusarea,
         g_lid2, g_rid2, gt_ldetail[], gt_rdetail[], gt_lobject[],
         gt_robject[].

* The first character of the node key tells what type of data to display
  CASE i_node_key(1).
    WHEN 'F'.                "Functions
      PERFORM display_tree_function USING i_node_key.
    WHEN 'C'.                "Conflicts
      PERFORM display_tree_conflict USING i_node_key.
    WHEN 'T'.                "Critical Tcodes
      PERFORM display_tree_crit_tcodes USING i_node_key.
    WHEN 'A'.                "Critical Auths
      PERFORM display_tree_crit_auths USING i_node_key.
    WHEN 'R'.                "Critical Roles
      PERFORM display_tree_crit_roles USING i_node_key.
    WHEN 'P'.                "Critical Profiles
      PERFORM display_tree_crit_profs USING i_node_key.
  ENDCASE.
ENDFORM.                    " show_tree_details

*&---------------------------------------------------------------------*
*&      Form  display_tree_function
*&---------------------------------------------------------------------*
*       Display function details from the selected function in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_function USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail,
        ls_obj    TYPE t_object.

  FIELD-SYMBOLS: <lfunc> TYPE /psyng/function,
                 <rfunc> TYPE /psyng/function,
                 <obj>   TYPE /psyng/faobj2.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_lfunction ASSIGNING <lfunc> INDEX l_index.
      READ TABLE gt_rfunction ASSIGNING <rfunc> INDEX l_index.
      g_lid      = <lfunc>-function.
      g_rid      = <rfunc>-function.
      g_ldesc    = <lfunc>-description.
      g_rdesc    = <rfunc>-description.
      g_lowner   = <lfunc>-owner.
      g_rowner   = <rfunc>-owner.
      g_lbusarea = <lfunc>-busarea.
      g_rbusarea = <rfunc>-busarea.

      LOOP AT gt_ldtran WHERE functionid = <lfunc>-function.
        ls_detail-tcode = gt_ldtran-tcode.
        APPEND ls_detail TO gt_ldetail.
      ENDLOOP.

      LOOP AT gt_rdtran WHERE functionid = <rfunc>-function.
        ls_detail-tcode = gt_rdtran-tcode.
        APPEND ls_detail TO gt_rdetail.
      ENDLOOP.

      LOOP AT gt_ldfaobj ASSIGNING <obj> WHERE funid = <lfunc>-function.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_lobject.
      ENDLOOP.

      LOOP AT gt_rdfaobj ASSIGNING <obj> WHERE funid = <rfunc>-function.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_robject.
      ENDLOOP.

    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmfunction ASSIGNING <rfunc> INDEX l_index.
      g_rid      = <rfunc>-function.
      g_rdesc    = <rfunc>-description.
      g_rowner   = <rfunc>-owner.
      g_rbusarea = <rfunc>-busarea.

      LOOP AT gt_rdtran WHERE functionid = <rfunc>-function.
        ls_detail-tcode = gt_rdtran-tcode.
        APPEND ls_detail TO gt_rdetail.
      ENDLOOP.

      LOOP AT gt_rdfaobj ASSIGNING <obj> WHERE funid = <rfunc>-function.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_robject.
      ENDLOOP.

    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmfunction ASSIGNING <lfunc> INDEX l_index.
      g_lid      = <lfunc>-function.
      g_ldesc    = <lfunc>-description.
      g_lowner   = <lfunc>-owner.
      g_lbusarea = <lfunc>-busarea.

      LOOP AT gt_ldtran WHERE functionid = <lfunc>-function.
        ls_detail-tcode = gt_ldtran-tcode.
        APPEND ls_detail TO gt_ldetail.
      ENDLOOP.

      LOOP AT gt_ldfaobj ASSIGNING <obj> WHERE funid = <lfunc>-function.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_lobject.
      ENDLOOP.

    WHEN 'S'.                "Similar
      READ TABLE gt_sfunction ASSIGNING <lfunc> INDEX l_index.
      g_lid      = <lfunc>-function.
      g_rid      = <lfunc>-function.
      g_ldesc    = <lfunc>-description.
      g_rdesc    = <lfunc>-description.
      g_lowner   = <lfunc>-owner.
      g_rowner   = <lfunc>-owner.
      g_lbusarea = <lfunc>-busarea.
      g_rbusarea = <lfunc>-busarea.
  ENDCASE.
ENDFORM.                    " display_tree_function

*&---------------------------------------------------------------------*
*&      Form  display_tree_conflict
*&---------------------------------------------------------------------*
*       Display conflict details from the selected conflict in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_conflict USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail.

  FIELD-SYMBOLS: <lconf> TYPE /psyng/conflict,
                 <rconf> TYPE /psyng/conflict.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_lconflict ASSIGNING <lconf> INDEX l_index.
      READ TABLE gt_rconflict ASSIGNING <rconf> INDEX l_index.
      g_lid      = <lconf>-conid.
      g_rid      = <rconf>-conid.
      g_ldesc    = <lconf>-description.
      g_rdesc    = <rconf>-description.
      g_lowner   = <lconf>-owner.
      g_rowner   = <rconf>-owner.
      g_lbusarea = <lconf>-busarea.
      g_rbusarea = <rconf>-busarea.
      g_limp     = <lconf>-imp.
      g_rimp     = <rconf>-imp.
      g_lid2     = <lconf>-contid.
      g_rid2     = <rconf>-contid.

      IF <lconf>-inactive = space.
        g_linactive = text-003.
      ELSE.
        g_linactive = text-004.
      ENDIF.

      IF <rconf>-inactive = space.
        g_rinactive = text-003.
      ELSE.
        g_rinactive = text-004.
      ENDIF.

      LOOP AT gt_lddet WHERE conid = <lconf>-conid.
        ls_detail-functionid = gt_lddet-funid.
        APPEND ls_detail TO gt_ldetail.
      ENDLOOP.

      LOOP AT gt_rddet WHERE conid = <rconf>-conid.
        ls_detail-functionid = gt_rddet-funid.
        APPEND ls_detail TO gt_rdetail.
      ENDLOOP.

    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmconflict ASSIGNING <rconf> INDEX l_index.
      g_rid      = <rconf>-conid.
      g_rdesc    = <rconf>-description.
      g_rowner   = <rconf>-owner.
      g_rbusarea = <rconf>-busarea.
      g_rimp     = <rconf>-imp.
      g_rid2     = <rconf>-contid.

      IF <rconf>-inactive = space.
        g_rinactive = text-003.
      ELSE.
        g_rinactive = text-004.
      ENDIF.

      LOOP AT gt_rddet WHERE conid = <rconf>-conid.
        ls_detail-functionid = gt_rddet-funid.
        APPEND ls_detail TO gt_rdetail.
      ENDLOOP.

    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmconflict ASSIGNING <lconf> INDEX l_index.
      g_lid      = <lconf>-conid.
      g_ldesc    = <lconf>-description.
      g_lowner   = <lconf>-owner.
      g_lbusarea = <lconf>-busarea.
      g_limp     = <lconf>-imp.
      g_lid2     = <lconf>-contid.

      IF <lconf>-inactive = space.
        g_linactive = text-003.
      ELSE.
        g_linactive = text-004.
      ENDIF.

      LOOP AT gt_lddet WHERE conid = <lconf>-conid.
        ls_detail-functionid = gt_lddet-funid.
        APPEND ls_detail TO gt_ldetail.
      ENDLOOP.

    WHEN 'S'.                "Similar
      READ TABLE gt_sconflict ASSIGNING <lconf> INDEX l_index.
      g_lid      = <lconf>-conid.
      g_rid      = <lconf>-conid.
      g_ldesc    = <lconf>-description.
      g_rdesc    = <lconf>-description.
      g_lowner   = <lconf>-owner.
      g_rowner   = <lconf>-owner.
      g_lbusarea = <lconf>-busarea.
      g_rbusarea = <lconf>-busarea.
      g_limp     = <lconf>-imp.
      g_rimp     = <lconf>-imp.
      g_lid2     = <lconf>-contid.
      g_rid2     = <lconf>-contid.

      IF <lconf>-inactive = space.
        g_linactive = text-003.
        g_rinactive = text-003.
      ELSE.
        g_linactive = text-004.
        g_rinactive = text-004.
      ENDIF.
  ENDCASE.
ENDFORM.                    " display_tree_conflict

*&---------------------------------------------------------------------*
*&      Form  display_tree_crit_tcodes
*&---------------------------------------------------------------------*
*       Display critical tcodes from the selected tcode in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_crit_tcodes USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail.

  FIELD-SYMBOLS: <ltran> TYPE /psyng/critcodes,
                 <rtran> TYPE /psyng/critcodes.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_ldcritcodes ASSIGNING <ltran> INDEX l_index.
      READ TABLE gt_rdcritcodes ASSIGNING <rtran> INDEX l_index.
      g_lid  = <ltran>-tcode.
      g_rid  = <rtran>-tcode.
      g_limp = <ltran>-imp.
      g_rimp = <rtran>-imp.
      g_lowner   = <ltran>-owner.
      g_rowner   = <rtran>-owner.
      g_lbusarea = <ltran>-busarea.
      g_rbusarea = <rtran>-busarea.


    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmtran ASSIGNING <rtran> INDEX l_index.
      g_rid  = <rtran>-tcode.
      g_rimp = <rtran>-imp.
      g_rbusarea = <rtran>-busarea.
      g_rowner   = <rtran>-owner.

    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmtran ASSIGNING <ltran> INDEX l_index.
      g_lid  = <ltran>-tcode.
      g_limp = <ltran>-imp.
      g_lowner   = <ltran>-owner.
      g_lbusarea = <ltran>-busarea.


    WHEN 'S'.                "Similar
      READ TABLE gt_stran ASSIGNING <ltran> INDEX l_index.
      g_lid  = <ltran>-tcode.
      g_rid  = <ltran>-tcode.
      g_limp = <ltran>-imp.
      g_rimp = <ltran>-imp.
      g_lowner   = <ltran>-owner.
      g_rowner   = <ltran>-owner.
      g_lbusarea = <ltran>-busarea.
      g_rbusarea = <ltran>-busarea.


  ENDCASE.
ENDFORM.                    " display_tree_crit_tcodes

*&---------------------------------------------------------------------*
*&      Form  display_tree_crit_auths
*&---------------------------------------------------------------------*
*       Display critical auths from the selected auth in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_crit_auths USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail,
        ls_obj    TYPE t_object.

  FIELD-SYMBOLS: <lauth> TYPE /psyng/swaudhdr,
                 <rauth> TYPE /psyng/swaudhdr,
                 <obj>   TYPE /psyng/swaudc2.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_ldauth ASSIGNING <lauth> INDEX l_index.
      READ TABLE gt_rdauth ASSIGNING <rauth> INDEX l_index.
      g_lid   = <lauth>-swaudid.
      g_rid   = <rauth>-swaudid.
      g_ldesc = <lauth>-description.
      g_rdesc = <rauth>-description.
      g_lid2  = <lauth>-tcode.
      g_rid2  = <rauth>-tcode.
      g_limp = <lauth>-imp.
      g_rimp = <rauth>-imp.
      g_lowner   = <lauth>-owner.
      g_rowner   = <rauth>-owner.


      LOOP AT gt_ldaudc ASSIGNING <obj> WHERE swaudid = <lauth>-swaudid.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_lobject.
      ENDLOOP.

      LOOP AT gt_rdaudc ASSIGNING <obj> WHERE swaudid = <rauth>-swaudid.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_robject.
      ENDLOOP.

    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmauth ASSIGNING <rauth> INDEX l_index.
      g_rid   = <rauth>-swaudid.
      g_rdesc = <rauth>-description.
      g_rid2  = <rauth>-tcode.
      g_rimp = <rauth>-imp.
      g_rowner   = <rauth>-owner.

      LOOP AT gt_rdaudc ASSIGNING <obj> WHERE swaudid = <rauth>-swaudid.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_robject.
      ENDLOOP.

    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmauth ASSIGNING <lauth> INDEX l_index.
      g_lid   = <lauth>-swaudid.
      g_ldesc = <lauth>-description.
      g_lid2  = <lauth>-tcode.
      g_limp = <lauth>-imp.
      g_lowner   = <lauth>-owner.

      LOOP AT gt_ldaudc ASSIGNING <obj> WHERE swaudid = <lauth>-swaudid.
        MOVE-CORRESPONDING <obj> TO ls_obj.
        APPEND ls_obj TO gt_lobject.
      ENDLOOP.

    WHEN 'S'.                "Similar
      READ TABLE gt_sauth ASSIGNING <lauth> INDEX l_index.
      g_lid   = <lauth>-swaudid.
      g_rid   = <lauth>-swaudid.
      g_ldesc = <lauth>-description.
      g_rdesc = <lauth>-description.
      g_lid2  = <lauth>-tcode.
      g_rid2  = <lauth>-tcode.
      g_limp = <lauth>-imp.
      g_rimp = <lauth>-imp.
      g_lowner   = <lauth>-owner.
      g_rowner   = <lauth>-owner.

  ENDCASE.
ENDFORM.                    " display_tree_crit_auths

*&---------------------------------------------------------------------*
*&      Form  display_tree_crit_roles
*&---------------------------------------------------------------------*
*       Display critical roles from the selected role in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_crit_roles USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail.

  FIELD-SYMBOLS: <lrole> TYPE /psyng/criroles,
                 <rrole> TYPE /psyng/criroles.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_ldrole ASSIGNING <lrole> INDEX l_index.
      READ TABLE gt_rdrole ASSIGNING <rrole> INDEX l_index.
      g_lid  = <lrole>-agr_name.
      g_rid  = <rrole>-agr_name.
      g_limp = <lrole>-imp.
      g_rimp = <rrole>-imp.
      g_lowner   = <lrole>-owner.
      g_rowner   = <rrole>-owner.
    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmrole ASSIGNING <rrole> INDEX l_index.
      g_rid  = <rrole>-agr_name.
      g_rimp = <rrole>-imp.
      g_rowner   = <rrole>-owner.
    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmrole ASSIGNING <lrole> INDEX l_index.
      g_lid  = <lrole>-agr_name.
      g_limp = <lrole>-imp.
      g_lowner   = <lrole>-owner.
    WHEN 'S'.                "Similar
      READ TABLE gt_srole ASSIGNING <lrole> INDEX l_index.
      g_lid  = <lrole>-agr_name.
      g_rid  = <lrole>-agr_name.
      g_limp = <lrole>-imp.
      g_rimp = <lrole>-imp.
      g_lowner   = <lrole>-owner.
      g_rowner   = <lrole>-owner.
  ENDCASE.
ENDFORM.                    " display_tree_crit_roles

*&---------------------------------------------------------------------*
*&      Form  display_tree_crit_profs
*&---------------------------------------------------------------------*
*       Display critical profiles from the selected profile in the tree
*----------------------------------------------------------------------*
*      -->I_NODE_KEY  text
*----------------------------------------------------------------------*
FORM display_tree_crit_profs USING    i_node_key TYPE tv_nodekey.
  DATA: l_index   TYPE i,
        ls_detail TYPE t_detail.

  FIELD-SYMBOLS: <lprof> TYPE /psyng/criprof,
                 <rprof> TYPE /psyng/criprof.

* The table index occurs after the second character in the node key
  l_index = i_node_key+2.

* The second character of node key tells what type of data to display
  CASE i_node_key+1(1).
    WHEN 'D'.                "Differences
      READ TABLE gt_ldprof ASSIGNING <lprof> INDEX l_index.
      READ TABLE gt_rdprof ASSIGNING <rprof> INDEX l_index.
      g_lid  = <lprof>-profile.
      g_rid  = <rprof>-profile.
      g_limp = <lprof>-imp.
      g_rimp = <rprof>-imp.
      g_lowner = <lprof>-owner.
      g_rowner = <rprof>-owner.
    WHEN 'L'.                "Missing from the left version
      READ TABLE gt_rmprof ASSIGNING <rprof> INDEX l_index.
      g_rid  = <rprof>-profile.
      g_rimp = <rprof>-imp.
      g_rowner = <rprof>-owner.
    WHEN 'R'.                "Missing from the right version
      READ TABLE gt_lmprof ASSIGNING <lprof> INDEX l_index.
      g_lid  = <lprof>-profile.
      g_limp = <lprof>-imp.
      g_lowner = <lprof>-owner.
    WHEN 'S'.                "Similar
      READ TABLE gt_sprof ASSIGNING <lprof> INDEX l_index.
      g_lid  = <lprof>-profile.
      g_rid  = <lprof>-profile.
      g_limp = <lprof>-imp.
      g_rimp = <lprof>-imp.
      g_lowner = <lprof>-owner.
      g_rowner = <lprof>-owner.
  ENDCASE.
ENDFORM.                    " display_tree_crit_profs
