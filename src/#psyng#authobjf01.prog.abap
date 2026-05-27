*----------------------------------------------------------------------*
* INCLUDE PROGRAM       : /PSYNG/AUTHOBJF01
* AUTHOR                : Security Weaver, LLC
* RELEASE               : 1.0.1.0
* DATE OF RELEASE       :
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_from_database
*&---------------------------------------------------------------------*
*       Get from database
*----------------------------------------------------------------------*
FORM get_from_database.
  DATA: lt_functtran2 TYPE TABLE OF /psyng/functtran WITH HEADER LINE.
* Get data
  SELECT * FROM /psyng/faobj2
           INTO CORRESPONDING FIELDS OF gt_faobj
           WHERE vrsio  = p_vrsio
             AND funid IN s_funid.

    SELECT SINGLE ttext FROM tstct
                 INTO gt_faobj-ttext
                 WHERE tcode = gt_faobj-tcode AND
                       sprsl = sy-langu.

    SELECT SINGLE ttext FROM tobjt
                 INTO gt_faobj-otext
                 WHERE object = gt_faobj-object AND
                       langu = sy-langu.

    SELECT SINGLE description FROM /psyng/function
                       INTO gt_faobj-description
                       WHERE function = gt_faobj-funid
                         AND vrsio    = p_vrsio.

    PERFORM get_field_name USING gt_faobj-field
                           CHANGING gt_faobj-ddtext.
    APPEND gt_faobj.
    CLEAR gt_faobj.
  ENDSELECT.

*--HANA Code fix
  SORT gt_faobj.
* Find any additional rows from /PSYNG/FUNCTTRAN
  SELECT functionid tcode INTO (gt_faobj-funid, gt_faobj-tcode)
         FROM /psyng/functtran
         WHERE functionid IN s_funid
           AND vrsio       = p_vrsio.

    READ TABLE gt_faobj WITH KEY funid = gt_faobj-funid
                                 tcode = gt_faobj-tcode
                        TRANSPORTING NO FIELDS
                        BINARY SEARCH.
    IF sy-subrc <> 0.
*     Function description
      SELECT SINGLE description INTO gt_faobj-description
               FROM /psyng/function
              WHERE function = gt_faobj-funid
                AND vrsio    = p_vrsio.

*     Transaction text
      SELECT SINGLE ttext INTO gt_faobj-ttext FROM tstct
              WHERE sprsl = sy-langu
                AND tcode = gt_faobj-tcode.

      PERFORM get_field_name USING gt_faobj-field
                             CHANGING gt_faobj-ddtext.
      APPEND gt_faobj.
      CLEAR gt_faobj.
    ENDIF.
  ENDSELECT.

*--add type, fioriid, appname
  IF NOT gt_faobj[] IS INITIAL.
    SELECT * FROM /psyng/functtran INTO TABLE lt_functtran2
      FOR ALL ENTRIES IN gt_faobj
       WHERE functionid   = gt_faobj-funid
        AND vrsio = p_vrsio.
  ENDIF.
  LOOP AT lt_functtran2.
    READ TABLE gt_faobj WITH KEY tcode = lt_functtran2-tcode.
    IF sy-subrc = 0.
      gt_faobj-fioriid = lt_functtran2-fioriid.
      gt_faobj-type = lt_functtran2-type.
      PERFORM get_appname USING    gt_faobj-fioriid
                         CHANGING gt_faobj-appname.
      MODIFY gt_faobj TRANSPORTING fioriid appname type
        WHERE tcode = lt_functtran2-tcode.
    ENDIF.
  ENDLOOP.
  PERFORM prepare_for_tree.
ENDFORM.                    " get_from_database

*&---------------------------------------------------------------------*
*&      Form  prepare_for_tree
*&---------------------------------------------------------------------*
*       Prepare internal table for tree
*----------------------------------------------------------------------*
FORM prepare_for_tree.
  DATA: l_tcode_count TYPE i,
        l_obj_count   TYPE i,
        l_rec_num     TYPE i.

* Count transaction and object nodes and get field descriptions
  SORT gt_faobj BY funid tcode object valueset field val_from.
  LOOP AT gt_faobj.
    AT NEW tcode.
      ADD 1 TO l_tcode_count.
    ENDAT.

    AT NEW object.
      ADD 1 TO l_obj_count.
    ENDAT.

    gt_faobj-tnode = l_tcode_count.
    gt_faobj-onode = l_obj_count.

    ADD 1 TO l_rec_num.
    gt_faobj-rec_num = l_rec_num.
    MODIFY gt_faobj.
  ENDLOOP.
ENDFORM.                    " prepare_for_tree

*&---------------------------------------------------------------------*
*&      Form  refresh_tree
*&---------------------------------------------------------------------*
*       Delete all nodes and refresh tree
*----------------------------------------------------------------------*
FORM refresh_tree.
  PERFORM remember_tree_node_state.
  CALL METHOD g_tree->delete_all_nodes.
  REFRESH: gt_node, gt_item.
  PERFORM prepare_for_tree.
  PERFORM build_node_and_item_table.

  CALL METHOD g_tree->add_nodes_and_items
    EXPORTING
      node_table                     = gt_node
      item_table                     = gt_item
      item_table_structure_name      = 'MTREEITM'
    EXCEPTIONS
      failed                         = 1
      cntl_system_error              = 2
      error_in_tables                = 3
      dp_error                       = 4
      table_structure_name_not_found = 5.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

  PERFORM apply_remembered_node_state.
ENDFORM.                    " refresh_tree

*&---------------------------------------------------------------------*
*&      Form  CREATE_AND_INIT_TREE
*&---------------------------------------------------------------------*
*       Create and fill tree object
*----------------------------------------------------------------------*
FORM create_and_init_tree.
  DATA: ll_event  TYPE cntl_simple_event,
        lt_events TYPE cntl_simple_events,
        l_header  TYPE treev_hhdr.

* create a container for the tree control
  CREATE OBJECT g_custom_container
    EXPORTING
      " the container is linked to the custom control with the
      " name 'TREE_CONTAINER' on the dynpro
      container_name = 'TREE_CONTAINER'
    EXCEPTIONS
      cntl_error = 1
      cntl_system_error = 2
      create_error = 3
      lifetime_error = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* setup the hierarchy header
  l_header-heading = text-010.    " heading
  l_header-width = 100.           " width: 100 characters

* create a tree control

* After construction, the control contains one column in the
* hierarchy area. The name of this column
* is defined via the constructor parameter HIERACHY_COLUMN_NAME.
  CREATE OBJECT g_tree
    EXPORTING
      parent                      = g_custom_container
      node_selection_mode     = cl_gui_column_tree=>node_sel_mode_single
      item_selection              = 'X'
      hierarchy_column_name       = 'FUNID'
      hierarchy_header            = l_header
    EXCEPTIONS
      cntl_system_error           = 1
      create_error                = 2
      failed                      = 3
      illegal_node_selection_mode = 4
      illegal_column_name         = 5
      lifetime_error              = 6.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* define the events which will be passed to the backend
* Button click
  ll_event-eventid = cl_gui_column_tree=>eventid_button_click.
  ll_event-appl_event = 'X'.
  APPEND ll_event TO lt_events.
* Item double-click
  ll_event-eventid = cl_gui_column_tree=>eventid_item_double_click.
  ll_event-appl_event = 'X'.
  APPEND ll_event TO lt_events.

  CALL METHOD g_tree->set_registered_events
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
  SET HANDLER g_application->handle_button_click FOR g_tree.
  SET HANDLER g_application->item_double_click FOR g_tree.

* insert two additional columns
* VALUEFROM
  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'VALUEFROM'
      width                        = 21
      alignment                    = cl_gui_column_tree=>align_left
      header_text                  = text-001
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      illegal_alignment            = 4
      different_column_types       = 5
      cntl_system_error            = 6
      failed                       = 7
      predecessor_column_not_found = 8.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* VALUETO
  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'VALUETO'
      width                        = 21
      alignment                    = cl_gui_column_tree=>align_left
      header_text                  = text-002
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      illegal_alignment            = 4
      different_column_types       = 5
      cntl_system_error            = 6
      failed                       = 7
      predecessor_column_not_found = 8.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* OBJ_OR
  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'OBJ_OR'
      width                        = 10
      alignment                    = cl_gui_column_tree=>align_center
      header_text                  = text-014
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      illegal_alignment            = 4
      different_column_types       = 5
      cntl_system_error            = 6
      failed                       = 7
      predecessor_column_not_found = 8.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* INFO
  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'INFO'
      width                        = 8
      alignment                    = cl_gui_column_tree=>align_left
      header_text                  = text-000
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      illegal_alignment            = 4
      different_column_types       = 5
      cntl_system_error            = 6
      failed                       = 7
      predecessor_column_not_found = 8.
  IF sy-subrc <> 0.
    MESSAGE a000.
  ENDIF.

* add some nodes to the tree control
* NOTE: the tree control does not store data at the backend. If an
* application wants to access tree data later, it must store the
* tree data itself.

  PERFORM build_node_and_item_table.

  CALL METHOD g_tree->add_nodes_and_items
    EXPORTING
      node_table                     = gt_node
      item_table                     = gt_item
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
ENDFORM.                    " CREATE_AND_INIT_TREE

*&---------------------------------------------------------------------*
*&      Form  build_node_and_item_table
*&---------------------------------------------------------------------*
*       Build the node table.
*----------------------------------------------------------------------*
FORM build_node_and_item_table.
  DATA: l_node_key_tcode  TYPE treev_node-node_key,
        l_node_key_object TYPE treev_node-node_key,
        l_node_key_vs     TYPE treev_node-node_key,
        l_tnode           TYPE i,
        l_onode           TYPE i,
        l_obj_or          TYPE /psyng/faobj2-obj_or,
        l_type            TYPE /psyng/tcodetype,
        l_fioriid         TYPE /psyng/sw_fioria-fioriid,
        l_appname         TYPE /psyng/sw_fioria-appname.

* The items of the nodes:
  LOOP AT gt_faobj.
    l_tnode = gt_faobj-tnode.
    l_onode = gt_faobj-onode.
    l_obj_or = gt_faobj-obj_or.
    l_type   = gt_faobj-type.
    l_fioriid = gt_faobj-fioriid.
    l_appname = gt_faobj-appname.
    AT NEW description.
      PERFORM insert_funid USING gt_faobj-funid gt_faobj-description.
    ENDAT.

*   Node with key 'tcode'
    AT NEW ttext.
      PERFORM insert_tcode USING l_tnode
                                 gt_faobj-funid
                                 gt_faobj-tcode
                                 gt_faobj-ttext
                                 l_type
                                 l_fioriid
                                 l_appname
                           CHANGING l_node_key_tcode.
    ENDAT.

*   Object
    AT NEW otext.
*     Node with key 'OBJECT'
      CHECK NOT gt_faobj-object IS INITIAL.
      PERFORM insert_object USING l_onode l_node_key_tcode
                                  gt_faobj-object gt_faobj-otext
                                  l_obj_or
                            CHANGING l_node_key_object.
    ENDAT.

*   Values
    AT NEW valueset.
      CHECK NOT gt_faobj-valueset IS INITIAL.
      PERFORM insert_value_set USING gt_faobj-valueset l_node_key_object
                                              gt_faobj-onode
                                        CHANGING l_node_key_vs.
    ENDAT.

    PERFORM insert_values USING gt_faobj l_node_key_vs.
  ENDLOOP.
ENDFORM.                    " build_node_and_item_table

*----------------------------------------------------------------------*
*   INCLUDE TABLECONTROL_FORMS                                         *
*----------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  USER_OK_TC                                               *
*&---------------------------------------------------------------------*
FORM user_ok_tc USING    p_tc_name TYPE dynfnam
                         p_table_name
                         p_mark_name
                CHANGING p_ok LIKE sy-ucomm.
  DATA: l_filename TYPE rlgrap-filename,
        l_noedit   TYPE /psyng/swsodvers-noedit,
        lv_valuset_and TYPE flag, "(++)UMITTAL IBS Valueset AND rel
        ll_faobj   TYPE /psyng/faobj2,
        lt_faobj   TYPE TABLE OF /psyng/faobj2, "HBHALLA
        l_chng_rec TYPE i, "HBHALLA
        lv_change  TYPE c, "HBHALLA (11/04/25)
        lt_chng_faobj TYPE TABLE OF /psyng/faobj2
        WITH HEADER LINE, "HBHALLA
* BOC by RGUPTA on 28.03.22 for C0700
  l_current_user TYPE sy-uname.
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
*&SPWIZARD: Table control specific operations                          *
*&SPWIZARD: execute general and TC specific operations                 *
  CASE p_ok.
    WHEN 'INSR'.                       "insert row
      PERFORM fcode_insert_row USING    p_tc_name
                                        p_table_name.
      CLEAR p_ok.

    WHEN 'DELE'.                       "delete row
      PERFORM fcode_delete_row USING    p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'P--' OR                      "top of list
         'P-'  OR                      "previous page
         'P+'  OR                      "next page
         'P++'.                        "bottom of list
      PERFORM compute_scrolling_in_tc USING p_tc_name
                                            p_ok.
      CLEAR p_ok.

    WHEN 'MARK'.                       "mark all filled lines
      PERFORM fcode_tc_mark_lines USING p_tc_name
                                        p_table_name
                                        p_mark_name.
      CLEAR p_ok.

    WHEN 'DMRK'.                       "demark all filled lines
      PERFORM fcode_tc_demark_lines USING p_tc_name
                                          p_table_name
                                          p_mark_name.
      CLEAR p_ok.

    WHEN 'DISPCHG'.                   "Toggle display and change modes
      IF gf_dispchg = gc_display.

        sec_actvt = act_change.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                 ID 'ACTVT'      FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD p_vrsio
                 ID 'Y&SW_FUNCT' FIELD gt_faobj-funid.
        IF sy-subrc NE 0.
          MESSAGE e108(/psyng/sw) WITH text-e10 text-e12
                                       gt_faobj-funid.
        ENDIF.

*       Check if version can be edited
        SELECT SINGLE noedit INTO l_noedit FROM /psyng/swsodvers
                      WHERE vrsio = p_vrsio.
        IF l_noedit = 'X'.
          MESSAGE i134(/psyng/sw) WITH p_vrsio.
          EXIT.
        ENDIF.
*--> BOC UMITTAL 11.03.2025 IBS Valueset AND relation
        CLEAR lv_valuset_and.
        SELECT SINGLE valueset_and INTO lv_valuset_and
            FROM /psyng/vrs_and
                      WHERE vrsio = p_vrsio.
        IF sy-subrc EQ 0 AND
          lv_valuset_and = 'X'.
          MESSAGE i353(/psyng/sw) WITH p_vrsio.
        ENDIF.
*--> EOC UMITTAL 11.03.2025 IBS Valueset AND relation
        gf_dispchg = gc_change.

*       Lock Function ID
        LOOP AT gt_faobj.
          AT NEW funid.
            CALL FUNCTION 'ENQUEUE_/PSYNG/FAOBJ'
                 EXPORTING
                      funid          = gt_faobj-funid
                      vrsio          = p_vrsio
                 EXCEPTIONS
                      foreign_lock   = 1
                      system_failure = 2
                      OTHERS         = 3.
            IF sy-subrc <> 0 AND sy-msgv1 <> l_current_user."HBHALLA
              gf_dispchg = gc_display.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDAT.
        ENDLOOP.

        PERFORM refresh_tree.
      ELSE.
        sec_actvt = act_display.
        AUTHORITY-CHECK OBJECT 'Y&SW_FUNCH'
                 ID 'ACTVT'      FIELD sec_actvt
                 ID 'Y&SW_VRSIO' FIELD p_vrsio
                 ID 'Y&SW_FUNCT' FIELD gt_faobj-funid.
        IF sy-subrc NE 0.
          MESSAGE e108(/psyng/sw) WITH text-e11 text-e12
                                        gt_faobj-funid.
        ENDIF.

*       If data was changed, ask if user wants to exit without saving
        DESCRIBE TABLE gt_changes LINES sy-tfill.
        IF sy-tfill > 0.
          g_answer = '1'.

          CALL FUNCTION 'POPUP_TO_CONFIRM'
               EXPORTING
                    text_question         = text-q03
                    text_button_1         = text-003
                    icon_button_1         = 'ICON_OKAY'
                    text_button_2         = text-004
                    icon_button_2         = 'ICON_CANCEL'
                    default_button        = '2'
                    display_cancel_button = space
               IMPORTING
                    answer                = g_answer
               EXCEPTIONS
                    text_not_found        = 1
                    OTHERS                = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

          CHECK g_answer = '1'.
          REFRESH gt_changes.

*         Unlock Function ID
          LOOP AT gt_faobj.
            AT NEW funid.
              CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
                   EXPORTING
                        funid = gt_faobj-funid
                        vrsio = p_vrsio.
            ENDAT.
          ENDLOOP.

*         Reload table and tree
          REFRESH gt_faobj.
          PERFORM get_from_database.
        ELSE.
*         Unlock Function ID
          LOOP AT gt_faobj.
            AT NEW funid.
              CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
                   EXPORTING
                        funid = gt_faobj-funid
                        vrsio = p_vrsio.
            ENDAT.
          ENDLOOP.
        ENDIF.

        PERFORM refresh_tree.
        gf_dispchg = gc_display.
      ENDIF.

    WHEN 'TRANSFER'.                   "Save value set to tree
      PERFORM save_value_set.

    WHEN 'FIND'.                       "Find
      PERFORM find_node USING 0.

    WHEN 'FINDNEXT'.                   "Find next
      PERFORM find_node USING g_start_pos.

    WHEN 'UPLD'.                       "Upload
      PERFORM get_filename CHANGING l_filename.
      CHECK NOT l_filename IS INITIAL.
      PERFORM upload USING l_filename.

    WHEN 'UPLDALL'.                    "Upload all
      CALL FUNCTION 'POPUP_TO_CONFIRM'
           EXPORTING
                titlebar              = text-t01
                text_question         = text-q02
                text_button_1         = text-003
                icon_button_1         = 'ICON_OKAY'
                text_button_2         = text-004
                icon_button_2         = 'ICON_CANCEL'
                default_button        = '2'
                display_cancel_button = space
           IMPORTING
                answer                = g_answer
           EXCEPTIONS
                text_not_found        = 1
                OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      CHECK g_answer = '1'.
      PERFORM get_filename CHANGING l_filename.
      CHECK NOT l_filename IS INITIAL.

      REFRESH gt_faobj.
      PERFORM upload USING l_filename.

    WHEN 'DNLD'.                       "Download
      REFRESH gt_file.
      CLEAR g_node_key.

*     Get selected node and download
      CALL METHOD g_tree->get_selected_node
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
        MESSAGE i398(00) WITH text-e01 text-e07.
        EXIT.
      ENDIF.

*     Choose only selected nodes and their children
      CASE g_node_key(1).
        WHEN 'T'.                      "Transaction
          LOOP AT gt_faobj WHERE tnode = g_node_key+1.
            MOVE-CORRESPONDING gt_faobj TO gt_file.
            APPEND gt_file.
          ENDLOOP.

        WHEN 'O'.                      "Object
          LOOP AT gt_faobj WHERE onode = g_node_key+1.
            MOVE-CORRESPONDING gt_faobj TO gt_file.
            APPEND gt_file.
          ENDLOOP.

        WHEN 'G'.                      "Value set
          LOOP AT gt_faobj WHERE valueset = g_node_key+3.
            MOVE-CORRESPONDING gt_faobj TO gt_file.
            APPEND gt_file.
          ENDLOOP.

        WHEN 'V'.                      "Value
          READ TABLE gt_faobj WITH KEY rec_num = g_node_key+1.
          MOVE-CORRESPONDING gt_faobj TO gt_file.
          APPEND gt_file.

        WHEN OTHERS.                   "Function ID
          LOOP AT gt_faobj WHERE funid = g_node_key.
            MOVE-CORRESPONDING gt_faobj TO gt_file.
            APPEND gt_file.
          ENDLOOP.
      ENDCASE.

      PERFORM download.
      REFRESH gt_file.

    WHEN 'DNLDALL'.                    "Download all
      REFRESH gt_file.
      LOOP AT gt_faobj.
        MOVE-CORRESPONDING gt_faobj TO gt_file.
        APPEND gt_file.
      ENDLOOP.

      PERFORM download.
      REFRESH gt_file.

    WHEN 'SAVE'.                      "Save changes
      LOOP AT gt_changes.
        tcode = sy-cprog.
        utime = sy-uzeit.
        udate = sy-datum.
        username = l_current_user. "sy-uname. C0700
        cdoc_planned_or_real = 'R'.
        cdoc_upd_object = upd_psyng_faobj = 'D'.

*BOC:HBHALLA
*       Store all rows for this object
SELECT * FROM /psyng/faobj2 INTO TABLE lt_chng_faobj " #EC CI_SEL_NESTED
     WHERE vrsio  = p_vrsio
       AND funid  = gt_changes-funid
       AND tcode  = gt_changes-tcode
       AND object = gt_changes-object.
*EOC:HBHALLA

*       Delete all rows for this object
SELECT * FROM /psyng/faobj2 " #EC CI_SEL_NESTED
     WHERE vrsio  = p_vrsio
       AND funid  = gt_changes-funid
       AND tcode  = gt_changes-tcode
       AND object = gt_changes-object.



  CONCATENATE /psyng/faobj2-funid /psyng/faobj2-tcode
              /psyng/faobj2-object /psyng/faobj2-valueset
              /psyng/faobj2-field /psyng/faobj2-val_from
              /psyng/faobj2-val_to /psyng/faobj2-vrsio
*BOC UMITTAL PN7301 Change history for AND OR btn and fields 09/01/2026
              /psyng/faobj2-obj_or
              /psyng/faobj2-fld_and
*EOC UMITTAL PN7301 Change history for AND OR btn and fields 09/01/2026
              INTO objectid SEPARATED BY '|'.
  PERFORM cd_call_psyng_faobj.
  DELETE  /psyng/faobj2.
ENDSELECT.
*       Insert new rows
        CHECK NOT gt_changes-object IS INITIAL.
        cdoc_upd_object = upd_psyng_faobj = 'I'.

*BOC:HBHALLA (25/11/24) PN-4547

*BOC:HBHALLA (08/04/25)
 LOOP AT gt_chng_rec WHERE object = gt_changes-object.
    READ TABLE gt_faobj WITH KEY funid    = gt_chng_rec-funid
                                 tcode    = gt_chng_rec-tcode
                                 object   = gt_chng_rec-object
                                 valueset = gt_chng_rec-valueset
                                 field    = gt_chng_rec-field
                                 val_from = gt_chng_rec-val_from
                                 val_to   = gt_chng_rec-val_to
          TRANSPORTING ALL FIELDS.
     IF sy-subrc = 0.
        gt_chng_rec-rec_num = gt_faobj-rec_num.
       MODIFY gt_chng_rec.
     ENDIF.
 ENDLOOP.
*EOC:HBHALLA (08/04/25)

      LOOP AT gt_faobj WHERE funid  = gt_changes-funid
                         AND tcode  = gt_changes-tcode
                         AND object = gt_changes-object.
       LOOP AT lt_chng_faobj
                  WHERE    funid    = gt_faobj-funid
                    AND    tcode    = gt_faobj-tcode
                    AND    object   = gt_faobj-object
                    AND    valueset = gt_faobj-valueset
                    AND    field    = gt_faobj-field.
         IF lt_chng_faobj-obj_or <> gt_faobj-obj_or
           OR lt_chng_faobj-fld_and <> gt_faobj-fld_and.
           APPEND gt_faobj TO gt_chng_rec.
         ENDIF.
       ENDLOOP.
      ENDLOOP.
   SORT gt_chng_rec.
   DELETE ADJACENT DUPLICATES FROM gt_chng_rec
   COMPARING funid tcode object valueset field.
*EOC:HBHALLA (25/11/24) PN-4547

*BOC:HBHALLA(PN-12804 Case-4) (11/04/25)
*To Check if the current entry of gt_changes is a change or new addition

  CLEAR lv_change.

   READ TABLE lt_chng_faobj WITH KEY funid  = gt_changes-funid
                                     tcode  = gt_changes-tcode
                                     object = gt_changes-object.
   IF sy-subrc = 0.
     lv_change = 'X'.
   ENDIF.
*EOC:HBHALLA(PN-12804 Case-4) (11/04/25)

 IF gt_chng_rec[] IS NOT INITIAL AND lv_change = 'X'."HBHALLA(11/04/25)
       LOOP AT gt_chng_rec WHERE object = gt_changes-object."HBHALLA
        LOOP AT gt_faobj WHERE funid  = gt_changes-funid
                           AND tcode  = gt_changes-tcode
                           AND object = gt_changes-object.

          MOVE-CORRESPONDING gt_faobj TO ll_faobj.
          ll_faobj-vrsio      = p_vrsio.
*BOC:HBHALLA(PN-4547)
          CLEAR l_chng_rec.
    READ TABLE gt_chng_rec WITH KEY funid    = gt_faobj-funid
                                    tcode    = gt_faobj-tcode
                                    object   = gt_faobj-object
                                    valueset = gt_faobj-valueset
                                    field    = gt_faobj-field
                                    val_from = gt_faobj-val_from
                                    val_to   = gt_faobj-val_to
     TRANSPORTING ALL FIELDS. "HBHALLA (08/04/25)
   IF sy-subrc = 0.
        l_chng_rec = 1.
   ENDIF.

    READ TABLE lt_chng_faobj WITH KEY funid    = gt_faobj-funid
                                      tcode    = gt_faobj-tcode
                                      object   = gt_faobj-object
                                      valueset = gt_faobj-valueset
                                      field    = gt_faobj-field
     TRANSPORTING ALL FIELDS.
   IF sy-subrc = 0.

*BOC:HBHALLA (08/04/25)
*For entries added inside of change object
     READ TABLE gt_faobj WITH KEY funid    = lt_chng_faobj-funid
                                  tcode    = lt_chng_faobj-tcode
                                  object   = lt_chng_faobj-object
                                  valueset = lt_chng_faobj-valueset
                                  field    = lt_chng_faobj-field
                                  val_from = lt_chng_faobj-val_from
                                  val_to   = lt_chng_faobj-val_to.
     IF sy-subrc <> 0 OR l_chng_rec <> 1.
*EOC:HBHALLA (08/04/25)

        ll_faobj-create_usr = lt_chng_faobj-create_usr. "sy-uname. C0700
        ll_faobj-create_dat = lt_chng_faobj-create_dat.
        ll_faobj-create_tim = lt_chng_faobj-create_tim.

        IF gt_faobj-rec_num = gt_chng_rec-rec_num.
**       AND NOT ( ll_faobj-val_from <> lt_chng_faobj-val_from "HBHALLA
**       AND ll_faobj-val_to = lt_chng_faobj-val_to ).        "HBHALLA
        ll_faobj-change_usr = l_current_user. "sy-uname. C0700
        ll_faobj-change_dat = sy-datum.
        ll_faobj-change_tim = sy-uzeit.
        ELSEIF l_chng_rec <> 1.
        ll_faobj-change_usr = lt_chng_faobj-change_usr.
        ll_faobj-change_dat = lt_chng_faobj-change_dat.
        ll_faobj-change_tim = lt_chng_faobj-change_tim.
**        ELSE. "HBHALLA (08/04/25)
**        CONTINUE. "HBHALLA (08/04/25)
        ENDIF.

***BOC:HBHALLA (08/04/25)
**     ELSE.
**   IF NOT ( ll_faobj-val_from = gt_chng_rec-val_from
**   AND ll_faobj-val_to = gt_chng_rec-val_to ).
**     ll_faobj-create_usr = lt_chng_faobj-create_usr. "sy-uname. C0700
**     ll_faobj-create_dat = lt_chng_faobj-create_dat.
**     ll_faobj-create_tim = lt_chng_faobj-create_tim.
**     ll_faobj-change_usr = lt_chng_faobj-change_usr.
**     ll_faobj-change_dat = lt_chng_faobj-change_dat.
**     ll_faobj-change_tim = lt_chng_faobj-change_tim.
**
   ELSE.
     ll_faobj-create_usr = l_current_user. "sy-uname. C0700
     ll_faobj-create_dat = sy-datum.
     ll_faobj-create_tim = sy-uzeit.
   ENDIF.
**     ENDIF.
***EOC:HBHALLA (08/04/25)

  ELSE.
      ll_faobj-create_usr = l_current_user. "sy-uname. C0700
      ll_faobj-create_dat = sy-datum.
      ll_faobj-create_tim = sy-uzeit.
  ENDIF.

***       IF /psyng/faobj2-create_usr IS INITIAL.
***        ll_faobj-create_usr = l_current_user. "sy-uname. C0700
***        ll_faobj-create_dat = sy-datum.
***        ll_faobj-create_tim = sy-uzeit.
***       ELSE.
***        ll_faobj-create_usr = /psyng/faobj2-create_usr. "sy-uname.
**C0700
***        ll_faobj-create_dat = /psyng/faobj2-create_dat.
***        ll_faobj-create_tim = /psyng/faobj2-create_tim.
***        IF gt_faobj-rec_num = gt_chng_rec-rec_num.
***        ll_faobj-change_usr = l_current_user. "sy-uname. C0700
***        ll_faobj-change_dat = sy-datum.
***        ll_faobj-change_tim = sy-uzeit.
***        ELSEIF /psyng/faobj2-change_usr IS NOT INITIAL.
***        ll_faobj-change_usr = /psyng/faobj2-change_usr.
***        ll_faobj-change_dat = /psyng/faobj2-change_dat.
***        ll_faobj-change_tim = /psyng/faobj2-change_tim.
***        ENDIF.
***       ENDIF.

*********** Changed by sgottapu on 12.09.2008 ******************

          ll_faobj-mandt = sy-mandt.

          IF ll_faobj-object > space.

           MOVE ll_faobj TO /psyng/faobj2.
           INSERT INTO /psyng/faobj2 VALUES ll_faobj.
           "#EC CI_IMUD_NESTED

          ENDIF.


          CONCATENATE ll_faobj-funid ll_faobj-tcode
                      ll_faobj-object ll_faobj-valueset ll_faobj-field
                      ll_faobj-val_from ll_faobj-val_to p_vrsio
*BOC UMITTAL PN7301 Change history for AND OR btn and fields 09/01/2026
                      ll_faobj-obj_or
                      ll_faobj-fld_and
*BOC UMITTAL PN7301 Change history for AND OR btn and fields 09/01/2026
                      INTO objectid SEPARATED BY '|'.

*BOC:HBHALLA (05/12/24)PN-7296
    READ TABLE lt_faobj WITH KEY funid    = ll_faobj-funid
                                 tcode    = ll_faobj-tcode
                                 object   = ll_faobj-object
                                 valueset = ll_faobj-valueset
                                 field    = ll_faobj-field
                                 val_from = ll_faobj-val_from
                                 val_to   = ll_faobj-val_to
    TRANSPORTING NO FIELDS.
           IF SY-SUBRC <> 0.
                    PERFORM cd_call_psyng_faobj1.
              APPEND ll_faobj TO lt_faobj.
           ENDIF.
*EOC:HBHALLA (05/12/24)PN-7296
          CLEAR ll_faobj. "HBHALLA

        ENDLOOP.
       ENDLOOP. "HBHALLA
 ELSE.
        LOOP AT gt_faobj WHERE funid  = gt_changes-funid
                           AND tcode  = gt_changes-tcode
                           AND object = gt_changes-object.

          MOVE-CORRESPONDING gt_faobj TO ll_faobj.
          ll_faobj-vrsio      = p_vrsio.
          ll_faobj-create_usr = l_current_user. "sy-uname. C0700
          ll_faobj-create_dat = sy-datum.
          ll_faobj-create_tim = sy-uzeit.

          ll_faobj-mandt = sy-mandt.

          IF ll_faobj-object > space.

           MOVE ll_faobj TO /psyng/faobj2.
           INSERT INTO /psyng/faobj2 VALUES ll_faobj.
           "#EC CI_IMUD_NESTED

          ENDIF.


          CONCATENATE ll_faobj-funid ll_faobj-tcode
                      ll_faobj-object ll_faobj-valueset ll_faobj-field
                      ll_faobj-val_from ll_faobj-val_to p_vrsio
*BOC UMITTAL Capture Change history for AND OR buttons 09/01/2026
              ll_faobj-fld_and
              ll_faobj-obj_or
*EOC UMITTAL Capture Change history for AND OR buttons 09/01/2026
                      INTO objectid SEPARATED BY '|'.


          PERFORM cd_call_psyng_faobj1.
          CLEAR ll_faobj. "HBHALLA

*********** Changed by sgottapu on 12.09.2008 ******************

        ENDLOOP.
 ENDIF.
*EOC:HBHALLA(PN-4547)
      ENDLOOP.

      MESSAGE s120(/psyng/sw).  " Data Saved
      COMMIT WORK.
      REFRESH: gt_changes, gt_chng_rec,lt_faobj. "HBHALLA

    WHEN 'EXPND'.                     "Expand selected node
*     Get selected node and expand
      CALL METHOD g_tree->get_selected_node
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
        MESSAGE i398(00) WITH text-e01 text-e07.
        EXIT.
      ENDIF.

      CALL METHOD g_tree->expand_node
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

    WHEN 'EXPNDALL'.                  "Expand all nodes
      CALL METHOD g_tree->expand_root_nodes
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

    WHEN 'COLLPS'.                    "Collapse selected node
*     Get selected node and collapse
      CALL METHOD g_tree->get_selected_node
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
        MESSAGE i398(00) WITH text-e01 text-e07.
        EXIT.
      ENDIF.

      CALL METHOD g_tree->collapse_subtree
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

    WHEN 'COLLPSALL'.                 "Collapse all nodes
      CALL METHOD g_tree->collapse_all_nodes
           EXCEPTIONS
                failed            = 1
                cntl_system_error = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'GETALL'.                    "Get all function ID's
      REFRESH s_funid.

*     Unlock original function ID's
      LOOP AT gt_faobj.
        AT NEW funid.
          CALL FUNCTION 'DEQUEUE_/PSYNG/FAOBJ'
               EXPORTING
                    funid = gt_faobj-funid
                    vrsio = p_vrsio.
        ENDAT.
      ENDLOOP.

*     Reload table and tree
      REFRESH gt_faobj.
      PERFORM get_from_database.

      CALL METHOD g_tree->collapse_all_nodes
           EXCEPTIONS
             failed            = 1
             cntl_system_error = 2
             OTHERS            = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      PERFORM refresh_tree.

      IF gf_dispchg = gc_change.
*       Lock all function ID's
        LOOP AT gt_faobj.
          AT NEW funid.
            CALL FUNCTION 'ENQUEUE_/PSYNG/FAOBJ'
                 EXPORTING
                      funid          = gt_faobj-funid
                      vrsio          = p_vrsio
                 EXCEPTIONS
                      foreign_lock   = 1
                      system_failure = 2
                      OTHERS         = 3.
            IF sy-subrc <> 0.
              gf_dispchg = gc_display.
              MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                      WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.
          ENDAT.
        ENDLOOP.
      ENDIF.
  ENDCASE.
ENDFORM.                              " USER_OK_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_INSERT_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_insert_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_lines_name       LIKE feld-name.
  DATA l_selline          LIKE sy-stepl.
  DATA l_line             TYPE i.
  DATA l_table_name       LIKE feld-name.
  FIELD-SYMBOLS <tc>                 TYPE cxtab_control.
  FIELD-SYMBOLS <table>              TYPE STANDARD TABLE.
  FIELD-SYMBOLS <lines>              TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

 ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
"not headerline

*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_lines_name.

  ASSIGN (l_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

*&SPWIZARD: get current line                                           *
  GET CURSOR LINE l_selline.
  IF sy-subrc <> 0.                   " append line to table
    l_selline = <tc>-lines + 1.
*&SPWIZARD: set top line                                               *
    IF l_selline > <lines>.
      <tc>-top_line = l_selline - <lines> + 1 .
    ELSE.
      <tc>-top_line = 1.
    ENDIF.
  ELSE.                               " insert line into table
    l_selline = <tc>-top_line + l_selline - 1.
  ENDIF.
*&SPWIZARD: set new cursor line                                        *
  l_line = l_selline - <tc>-top_line + 1.

*&SPWIZARD: insert initial line                                        *

  READ TABLE gt_select INDEX 1.
  CLEAR: gt_select-field, gt_select-val_from, gt_select-val_to.
  INSERT gt_select INTO <table> INDEX l_selline.

  <tc>-lines = <tc>-lines + 1.
*&SPWIZARD: set cursor                                                 *
  SET CURSOR LINE l_line.
ENDFORM.                              " FCODE_INSERT_ROW

*&---------------------------------------------------------------------*
*&      Form  FCODE_DELETE_ROW                                         *
*&---------------------------------------------------------------------*
FORM fcode_delete_row
              USING    p_tc_name           TYPE dynfnam
                       p_table_name
                       p_mark_name.

*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

 ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body
  ASSIGN (l_table_name) TO <table>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

*&SPWIZARD: delete marked lines                                        *
  DESCRIBE TABLE <table> LINES <tc>-lines.

  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    IF <mark_field> = 'X'.
      DELETE <table> INDEX syst-tabix.
      IF sy-subrc = 0.
        <tc>-lines = <tc>-lines - 1.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                              " FCODE_DELETE_ROW

*&---------------------------------------------------------------------*
*&      Form  COMPUTE_SCROLLING_IN_TC
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*      -->P_OK       ok code
*----------------------------------------------------------------------*
FORM compute_scrolling_in_tc USING    p_tc_name
                                      p_ok.
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_tc_new_top_line     TYPE i.
  DATA l_tc_name             LIKE feld-name.
  DATA l_tc_lines_name       LIKE feld-name.
  DATA l_tc_field_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <lines>      TYPE i.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
*&SPWIZARD: get looplines of TableControl                              *
  CONCATENATE 'G_' p_tc_name '_LINES' INTO l_tc_lines_name.

  ASSIGN (l_tc_lines_name) TO <lines>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)


*&SPWIZARD: is no line filled?                                         *
  IF <tc>-lines = 0.
*&SPWIZARD: yes, ...                                                   *
    l_tc_new_top_line = 1.
  ELSE.
*&SPWIZARD: no, ...                                                    *
    CALL FUNCTION 'SCROLLING_IN_TABLE'
         EXPORTING
              entry_act             = <tc>-top_line
              entry_from            = 1
              entry_to              = <tc>-lines
              last_page_full        = 'X'
              loops                 = <lines>
              ok_code               = p_ok
              overlapping           = 'X'
         IMPORTING
              entry_new             = l_tc_new_top_line
         EXCEPTIONS
"(++)BOC UMITTAL SE VF scan-25/11/2024
              no_entry_or_page_act  = 1
              no_entry_to           = 2
              no_ok_code_or_page_go = 3
"(++)EOC UMITTAL SE VF scan-25/11/2024
              OTHERS                = 4.
"(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
           MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                   WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024
  ENDIF.

*&SPWIZARD: get actual tc and column                                   *
  GET CURSOR FIELD l_tc_field_name
             AREA  l_tc_name.

  IF syst-subrc = 0.
    IF l_tc_name = p_tc_name.
*&SPWIZARD: et actual column                                           *
      SET CURSOR FIELD l_tc_field_name LINE 1.
    ENDIF.
  ENDIF.

*&SPWIZARD: set the new top line                                       *
  <tc>-top_line = l_tc_new_top_line.
ENDFORM.                              " COMPUTE_SCROLLING_IN_TC

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_MARK_LINES
*&---------------------------------------------------------------------*
*       marks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_mark_lines USING p_tc_name
                               p_table_name
                               p_mark_name.
*&SPWIZARD: EGIN OF LOCAL DATA-----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

*&SPWIZARD: mark all filled lines                                      *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = 'X'.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  FCODE_TC_DEMARK_LINES
*&---------------------------------------------------------------------*
*       demarks all TableControl lines
*----------------------------------------------------------------------*
*      -->P_TC_NAME  name of tablecontrol
*----------------------------------------------------------------------*
FORM fcode_tc_demark_lines USING p_tc_name
                                 p_table_name
                                 p_mark_name .
*&SPWIZARD: BEGIN OF LOCAL DATA----------------------------------------*
  DATA l_table_name       LIKE feld-name.

  FIELD-SYMBOLS <tc>         TYPE cxtab_control.
  FIELD-SYMBOLS <table>      TYPE STANDARD TABLE.
  FIELD-SYMBOLS <wa>.
  FIELD-SYMBOLS <mark_field>.
*&SPWIZARD: END OF LOCAL DATA------------------------------------------*

  ASSIGN (p_tc_name) TO <tc>."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

*&SPWIZARD: get the table, which belongs to the tc                     *
  CONCATENATE p_table_name '[]' INTO l_table_name. "table body

  ASSIGN (l_table_name) TO <table>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

  "not headerline

*&SPWIZARD: demark all filled lines                                    *
  LOOP AT <table> ASSIGNING <wa>.

*&SPWIZARD: access to the component 'FLAG' of the table header         *
    ASSIGN COMPONENT p_mark_name OF STRUCTURE <wa> TO <mark_field>.

    <mark_field> = space.
  ENDLOOP.
ENDFORM.                                          "fcode_tc_mark_lines

*&---------------------------------------------------------------------*
*&      Form  save_value_set
*&---------------------------------------------------------------------*
*       Delete and re-add node to tree, and save entire value set
*----------------------------------------------------------------------*
FORM save_value_set.
  DATA: l_onode(10) TYPE c,
        l_valueset  TYPE /psyng/faobj2-valueset,
        ls_faobj    TYPE t_faobj,
        l_lowercase TYPE dd04l-lowercase.


  CHECK NOT g_node_key IS INITIAL.

  SPLIT g_node_key+1 AT '|' INTO l_onode l_valueset.
  LOOP AT gt_faobj WHERE onode = l_onode
                     AND valueset = l_valueset.
    PERFORM mark_changes USING gt_faobj-funid gt_faobj-tcode
                               gt_faobj-object.
  ENDLOOP.
  ls_faobj-funid = gt_faobj-funid.
  ls_faobj-description = gt_faobj-description.
  ls_faobj-tcode = gt_faobj-tcode.
  ls_faobj-ttext = gt_faobj-ttext.
  ls_faobj-fioriid = gt_faobj-fioriid.
  ls_faobj-appname = gt_faobj-appname.
  ls_faobj-type = gt_faobj-type.
  ls_faobj-rec_num = gt_faobj-rec_num.
  DELETE gt_faobj WHERE onode = l_onode
                    AND valueset = l_valueset.

* Check for case sensitivity of each field
  gf_uppercase = 'X'.
  LOOP AT gt_select.
    CLEAR l_lowercase.
    SELECT SINGLE dd04l~lowercase INTO l_lowercase   "#EC CI_SEL_NESTED
             FROM authx INNER JOIN dd04l
               ON authx~rollname = dd04l~rollname
            WHERE authx~fieldname = gt_select-field
              AND dd04l~as4local  = 'A'. "#EC SAST_CI_GEN_CHECK

    IF l_lowercase IS INITIAL.
      TRANSLATE gt_select-val_from TO UPPER CASE.
      TRANSLATE gt_select-val_to   TO UPPER CASE.
      MODIFY gt_select TRANSPORTING val_from val_to.
    ELSE.
      CLEAR gf_uppercase.
    ENDIF.

    APPEND gt_select TO gt_faobj.
  ENDLOOP.

* If no values exist, delete value set
  IF gt_select[] IS INITIAL.
    APPEND gt_faobj TO gt_del_vs.
  ENDIF.
  READ TABLE gt_faobj WITH KEY tcode = ls_faobj-tcode.
  IF sy-subrc NE 0.
  APPEND ls_faobj TO gt_faobj.
  ENDIF.

  PERFORM refresh_tree.
ENDFORM.                    " save_value_set

*&---------------------------------------------------------------------*
*&      Form  insert_funid
*&---------------------------------------------------------------------*
*       Insert function ID into tree
*----------------------------------------------------------------------*
*      -->I_FUNID     Function ID
*      -->I_DESCRIPT  Function description
*----------------------------------------------------------------------*
FORM insert_funid USING    i_funid TYPE /psyng/faobj2-funid
                           i_descript TYPE /psyng/function-description.
  DATA: ll_node TYPE treev_node,
        ll_item TYPE mtreeitm.

* Node with key 'FUNID'
  ll_node-node_key = i_funid." Key of the node
  CLEAR ll_node-relatkey.    " Special case: A root node has no parent
  CLEAR ll_node-relatship.   " node.
  ll_node-hidden = ' '.      " The node is visible,
  ll_node-disabled = ' '.    " selectable,
  ll_node-isfolder = 'X'.    " a folder.
  CLEAR ll_node-n_image.     " Folder-/ Leaf-Symbol in state "closed":
  " use default.
  CLEAR ll_node-exp_image.   " Folder-/ Leaf-Symbol in state "open":
  " use default
  CLEAR ll_node-expander.
  APPEND ll_node TO gt_node.

* Node with key 'FUNID'
  CLEAR ll_item.
  ll_item-node_key = i_funid.
  ll_item-item_name = 'FUNID'.         " Item of Column 'FUNID'
  ll_item-class = cl_gui_column_tree=>item_class_text. " Text Item
  CONCATENATE '(' i_descript ')' INTO i_descript.
  CONCATENATE i_funid i_descript
              INTO ll_item-text SEPARATED BY space.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = i_funid.
  ll_item-item_name = 'VALUEFROM'.     " Item of Column 'VALUEFROM'
  ll_item-class = cl_gui_column_tree=>item_class_text.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = i_funid.
  ll_item-item_name = 'VALUETO'.       " Item of Column 'VALUETO'
  ll_item-class = cl_gui_column_tree=>item_class_text.
  APPEND ll_item TO gt_item.
ENDFORM.                    " insert_funid

*&---------------------------------------------------------------------*
*&      Form  insert_tcode
*&---------------------------------------------------------------------*
*       Insert transaction into tree
*----------------------------------------------------------------------*
*      -->I_TCODE_COUNT      Transaction counter
*      -->I_FUNID            Function ID
*      -->I_TCODE            Transaction code
*      -->I_TTEXT            Transaction text
*      <--E_NODE_KEY_OBJECT  Node key for object
*----------------------------------------------------------------------*
FORM insert_tcode USING    i_tcode_count TYPE i
                           i_funid TYPE /psyng/faobj2-funid
                           i_tcode TYPE /psyng/faobj2-tcode
                           i_ttext TYPE tstct-ttext
                           i_type TYPE /psyng/functtran-type
                           i_fioriid TYPE /psyng/sw_fioria-fioriid
                           i_appname TYPE /psyng/sw_fioria-appname
                   CHANGING e_node_key_tcode TYPE treev_node-node_key.
  DATA: ll_node TYPE treev_node,
        ll_item TYPE mtreeitm.

  e_node_key_tcode = i_tcode_count.
  CONDENSE e_node_key_tcode.
  CONCATENATE 'T' e_node_key_tcode INTO e_node_key_tcode.
  ll_node-node_key = e_node_key_tcode.
* Node is inserted as child of the node with key 'FUNID'.
  ll_node-relatkey = i_funid.
  ll_node-relatship = cl_gui_column_tree=>relat_last_child.
  ll_node-hidden = ' '.
  ll_node-disabled = ' '.
  ll_node-isfolder = 'X'.
  CASE i_type.
    WHEN 'F'.
      ll_node-n_image = '@8S@'.
      ll_node-exp_image = '@8S@'.
    WHEN 'T'.
      ll_node-n_image = '@CS@'.
      ll_node-exp_image = '@CS@'.
    WHEN 'P'.
      ll_node-n_image = '@0O@'.
      ll_node-exp_image = '@0O@'.
  ENDCASE.
*  CLEAR ll_node-n_image.
*  CLEAR ll_node-exp_image.
  CLEAR ll_node-expander.
  APPEND ll_node TO gt_node.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_tcode.
  ll_item-item_name = 'FUNID'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  IF i_type = 'F'.
    CONCATENATE '(' i_appname ')' INTO i_appname.
    CONCATENATE i_fioriid i_appname
                INTO ll_item-text SEPARATED BY space.
  ELSE.
    CONCATENATE '(' i_ttext ')' INTO i_ttext.
    CONCATENATE i_tcode i_ttext
                INTO ll_item-text SEPARATED BY space.
  ENDIF.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_tcode.
  ll_item-item_name = 'VALUEFROM'.

  IF gf_dispchg = gc_change.
    ll_item-class = cl_gui_column_tree=>item_class_button.
    ll_item-text = text-005.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_tcode.
  ll_item-item_name = 'VALUETO'.

  IF gf_dispchg = gc_change.
    ll_item-class = cl_gui_column_tree=>item_class_button.
    ll_item-text = text-006.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.
ENDFORM.                    " insert_tcode

*&---------------------------------------------------------------------*
*&      Form  insert_object
*&---------------------------------------------------------------------*
*       Insert authorization object into tree
*----------------------------------------------------------------------*
*      -->I_OBJ_COUNT        Object counter
*      -->I_NODE_KEY_TCODE   Node key for transaction
*      -->I_OBJECT           Object name
*      -->I_OTEXT            Object text
*      <--E_NODE_KEY_OBJECT  Node key for object
*----------------------------------------------------------------------*
FORM insert_object USING    i_obj_count TYPE i
                            i_node_key_tcode TYPE treev_node-node_key
                            i_object TYPE /psyng/faobj2-object
                            i_otext TYPE tobjt-ttext
                            i_obj_or TYPE /psyng/faobj2-obj_or
                   CHANGING e_node_key_object TYPE treev_node-node_key.
  DATA: ll_node TYPE treev_node,
        ll_item TYPE mtreeitm.

  e_node_key_object = i_obj_count.
  CONDENSE e_node_key_object.
  CONCATENATE 'O' e_node_key_object INTO e_node_key_object.
  ll_node-node_key = e_node_key_object. " Key of the node
* Node is inserted as child of the node with key 'tcode'.
  ll_node-relatkey = i_node_key_tcode.
  ll_node-relatship = cl_gui_column_tree=>relat_last_child.
  ll_node-hidden = ' '.
  ll_node-disabled = ' '.
  ll_node-isfolder = 'X'.
  CLEAR ll_node-n_image.
  CLEAR ll_node-exp_image.
  CLEAR ll_node-expander.
  APPEND ll_node TO gt_node.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_object.
  ll_item-item_name = 'FUNID'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  CONCATENATE '(' i_otext ')' INTO i_otext.
  CONCATENATE i_object i_otext
              INTO ll_item-text SEPARATED BY space.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_object.
  ll_item-item_name = 'VALUEFROM'.

  IF gf_dispchg = gc_change.
    ll_item-t_image = '@17@'.
    ll_item-class = cl_gui_column_tree=>item_class_button.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_object.
  ll_item-item_name = 'VALUETO'.

  IF gf_dispchg = gc_change.
    ll_item-class = cl_gui_column_tree=>item_class_button.
    ll_item-text = text-013.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_object.
  ll_item-item_name = 'OBJ_OR'.

  IF gf_dispchg = gc_change.
    ll_item-class = cl_gui_column_tree=>item_class_button.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  IF i_obj_or = 'OR'.
    ll_item-text = text-016.
  ELSE.
    ll_item-text = text-015.
  ENDIF.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key  = e_node_key_object.
  ll_item-item_name = 'INFO'.
  ll_item-class     = cl_gui_column_tree=>item_class_button.
  ll_item-t_image   = '@0S@'.
  APPEND ll_item TO gt_item.
ENDFORM.                    " insert_object

*&---------------------------------------------------------------------*
*&      Form  insert_value_set
*&---------------------------------------------------------------------*
*       Insert new value set into tree
*----------------------------------------------------------------------*
*      -->I_VALUESET         Value set number
*      -->I_NODE_KEY_OBJECT  Node key for object
*      -->I_ONODE            Object node
*      <--E_NODE_KEY_VS      Node key for valueset
*----------------------------------------------------------------------*
FORM insert_value_set USING     i_valueset TYPE /psyng/faobj2-valueset
                                i_node_key_object
                                            TYPE treev_node-node_key
                                i_onode TYPE i
                      CHANGING  e_node_key_vs TYPE treev_node-node_key.
  DATA: ll_node TYPE treev_node,
        ll_item TYPE mtreeitm.

* Node with key 'VALUES'
  e_node_key_vs = i_onode.
  CONDENSE e_node_key_vs.
  CONCATENATE 'G' e_node_key_vs '|' i_valueset
              INTO e_node_key_vs.
  ll_node-node_key = e_node_key_vs. " Key of the node
* Node is inserted as child of the node with key 'OBJECT'.
  ll_node-relatkey = i_node_key_object.
  ll_node-relatship = cl_gui_column_tree=>relat_last_child.
  ll_node-hidden = ' '.
  ll_node-disabled = ' '.
  ll_node-isfolder = ' '.
  CLEAR ll_node-n_image.
  CLEAR ll_node-exp_image.
  ll_node-expander = 'X'.
  APPEND ll_node TO gt_node.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_vs.
  ll_item-item_name = 'FUNID'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  CONDENSE ll_item-text.
  CONCATENATE text-008 i_valueset INTO ll_item-text SEPARATED BY space.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_vs.
  ll_item-item_name = 'VALUEFROM'.

  IF gf_dispchg = gc_change.
    ll_item-t_image = '@0Z@'.
    ll_item-class = cl_gui_column_tree=>item_class_button.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = e_node_key_vs.
  ll_item-item_name = 'VALUETO'.

  IF gf_dispchg = gc_change.
    ll_item-t_image = '@18@'.
    ll_item-class = cl_gui_column_tree=>item_class_button.
  ELSE.
    ll_item-class = cl_gui_column_tree=>item_class_text.
  ENDIF.

  APPEND ll_item TO gt_item.
ENDFORM.                    " insert_value_set

*&---------------------------------------------------------------------*
*&      Form  insert_values
*&---------------------------------------------------------------------*
*       Insert actual authorization values
*----------------------------------------------------------------------*
*      -->IS_FAOBJ
*      -->I_NODE_KEY_VS  Node key for valueset
*----------------------------------------------------------------------*
FORM insert_values USING    is_faobj TYPE t_faobj
                            i_node_key_vs TYPE treev_node-node_key.
  DATA: ll_node    TYPE treev_node,
        ll_item    TYPE mtreeitm,
        l_node_key TYPE treev_node-node_key.


  l_node_key = is_faobj-rec_num.
  CONDENSE l_node_key.
  CONCATENATE 'V' l_node_key INTO l_node_key.
  CLEAR ll_node.
  ll_node-node_key = l_node_key.
  ll_node-relatkey = i_node_key_vs.
  ll_node-relatship = cl_gui_column_tree=>relat_last_child.

  IF is_faobj-fld_and IS INITIAL.
    ll_node-n_image = '@GC@'.          "Or (Default)
  ELSE.
    ll_node-n_image = '@GB@'.          "And
  ENDIF.

  APPEND ll_node TO gt_node.

* Items of node
  CLEAR ll_item.
  ll_item-node_key = l_node_key.
  ll_item-item_name = 'FUNID'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  IF NOT is_faobj-ddtext IS INITIAL.
    CONCATENATE '(' is_faobj-ddtext ')' INTO is_faobj-ddtext.
  ENDIF.
  CONCATENATE is_faobj-field is_faobj-ddtext
              INTO ll_item-text SEPARATED BY space.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = l_node_key.
  ll_item-item_name = 'VALUEFROM'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  ll_item-text = is_faobj-val_from.
  APPEND ll_item TO gt_item.

  CLEAR ll_item.
  ll_item-node_key = l_node_key.
  ll_item-item_name = 'VALUETO'.
  ll_item-class = cl_gui_column_tree=>item_class_text.
  ll_item-text = is_faobj-val_to.
  APPEND ll_item TO gt_item.
ENDFORM.                    " insert_values

*&---------------------------------------------------------------------*
*&      Form  find_node
*&---------------------------------------------------------------------*
*       Find node of tree
*----------------------------------------------------------------------*
*      -->I_START_POS    Starting position
*----------------------------------------------------------------------*
FORM find_node USING    i_start_pos TYPE i.
  RANGES: lr_funid  FOR /psyng/faobj2-funid,
          lr_tcode  FOR /psyng/faobj2-tcode,
          lr_object FOR /psyng/faobj2-object.

  DATA: l_tabix TYPE sy-tabix.


  IF g_search_funid IS INITIAL AND g_search_tcode IS INITIAL AND
     g_search_object IS INITIAL.
    MESSAGE e398(00) WITH text-e02.
  ENDIF.

  IF NOT g_search_funid IS INITIAL.
    lr_funid-sign = 'I'.
    lr_funid-low = g_search_funid.

    IF g_search_funid CS '*'.
      lr_funid-option = 'CP'.
    ELSE.
      lr_funid-option = 'EQ'.
    ENDIF.

    APPEND lr_funid.
  ENDIF.

  IF NOT g_search_tcode IS INITIAL.
    lr_tcode-sign = 'I'.
    lr_tcode-low = g_search_tcode.

    IF g_search_tcode CS '*'.
      lr_tcode-option = 'CP'.
    ELSE.
      lr_tcode-option = 'EQ'.
    ENDIF.

    APPEND lr_tcode.
  ENDIF.

  IF NOT g_search_object IS INITIAL.
    lr_object-sign = 'I'.
    lr_object-low = g_search_object.

    IF g_search_object CS '*'.
      lr_object-option = 'CP'.
    ELSE.
      lr_object-option = 'EQ'.
    ENDIF.

    APPEND lr_object.
  ENDIF.

  LOOP AT gt_faobj FROM i_start_pos
                   WHERE funid IN lr_funid
                     AND tcode IN lr_tcode
                     AND object IN lr_object.

    l_tabix = sy-tabix.

    IF i_start_pos <> 0.
      CHECK l_tabix > i_start_pos.
    ENDIF.

    g_start_pos = l_tabix.

*   If "Find Next" was chosen, check that each value is after the last
*   value that was found.
    IF NOT lr_object[] IS INITIAL.
      g_node_key = gt_faobj-onode.
      CONDENSE g_node_key.
      CONCATENATE 'O' g_node_key INTO g_node_key.
      CHECK g_node_key <> g_start_onode.
      g_start_onode = g_node_key.
    ELSEIF NOT lr_tcode[] IS INITIAL.
      g_node_key = gt_faobj-tnode.
      CONDENSE g_node_key.
      CONCATENATE 'T' g_node_key INTO g_node_key.
      CHECK g_node_key <> g_start_tnode.
      g_start_tnode = g_node_key.
    ELSE.
      g_node_key = gt_faobj-funid.
      CHECK g_node_key <> g_start_funid.
      g_start_funid = g_node_key.
    ENDIF.

*   Expand and highlight found node
    CALL METHOD g_tree->set_selected_node
         EXPORTING
              node_key                   = g_node_key
         EXCEPTIONS
              failed                     = 1
              single_node_selection_only = 2
              node_not_found             = 3
              cntl_system_error          = 4
              OTHERS                     = 5.
    IF sy-subrc <> 0.
      MESSAGE i103(/psyng/sw).
    ENDIF.

    EXIT.
  ENDLOOP.

  IF sy-subrc <> 0.
    MESSAGE i103(/psyng/sw).
  ENDIF.

  CLEAR g_node_key.
ENDFORM.                    " find_node

*&---------------------------------------------------------------------*
*&      Form  upload
*&---------------------------------------------------------------------*
*       Upload data from file
*----------------------------------------------------------------------*
*      -->I_FILENAME  File name
*----------------------------------------------------------------------*
FORM upload USING i_filename TYPE rlgrap-filename.

  DATA : l_filename TYPE string,
         l_msgv     TYPE bapiret2-message_v1.


  l_filename = i_filename.

  REFRESH gt_file.
*BOC:HBHALLA (097)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '60'.
  IF sy-subrc = 0.
  CALL FUNCTION 'GUI_UPLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = l_filename
            filetype                = 'ASC'
            has_field_separator     = 'X'
            dat_mode                = ' '
       TABLES
            data_tab                = gt_file
       EXCEPTIONS
            file_open_error         = 1
            file_read_error         = 2
            no_batch                = 3
            gui_refuse_filetransfer = 4
            invalid_type            = 5
            no_authority            = 6
            unknown_error           = 7
            bad_data_format         = 8
            header_not_allowed      = 9
            separator_not_allowed   = 10
            header_too_long         = 11
            unknown_dp_error        = 12
            access_denied           = 13
            dp_out_of_memory        = 14
            disk_full               = 15
            dp_timeout              = 16
            OTHERS                  = 17.
  IF sy-subrc <> 0.
    l_msgv = l_filename.
    CALL FUNCTION '/PSYNG/BC_004'
         EXPORTING
              i_subrc = sy-subrc
              i_msgty = 'I'
              i_msgv1 = l_msgv.
  ENDIF.
  ENDIF.
*EOC:HBHALLA (097)

* Get texts
  LOOP AT gt_file.
    CLEAR gt_faobj.

*   Check for existing row
    READ TABLE gt_faobj WITH KEY funid    = gt_file-funid
                                 tcode    = gt_file-tcode
                                 object   = gt_file-object
                                 valueset = gt_file-valueset
                                 field    = gt_file-field
                                 val_from = gt_file-val_from
                                 val_to   = gt_file-val_to.
    IF sy-subrc = 0.
      MESSAGE e101(/psyng/sw).
    ENDIF.

    MOVE-CORRESPONDING gt_file TO gt_faobj.

*   Function text
    SELECT SINGLE description                        "#EC CI_SEL_NESTED
                INTO gt_faobj-description
                  FROM /psyng/function
                  WHERE function = gt_file-funid
                    AND vrsio    = p_vrsio.

*   Transaction text
    SELECT SINGLE ttext INTO gt_faobj-ttext          "#EC CI_SEL_NESTED
                FROM tstct
                  WHERE sprsl = sy-langu
                    AND tcode = gt_file-tcode.

*   Object text
    SELECT SINGLE ttext INTO gt_faobj-otext          "#EC CI_SEL_NESTED
                FROM tobjt
                  WHERE langu  = sy-langu
                    AND object = gt_file-object.

*   Field name
    PERFORM get_field_name USING gt_file-field
                           CHANGING gt_faobj-ddtext.

    APPEND gt_faobj.
    PERFORM mark_changes USING gt_faobj-funid gt_faobj-tcode
                               gt_faobj-object.
  ENDLOOP.

* Refresh entire tree
  PERFORM refresh_tree.
  REFRESH gt_file.
ENDFORM.                    " upload

*&---------------------------------------------------------------------*
*&      Form  download
*&---------------------------------------------------------------------*
*       Download data to file
*----------------------------------------------------------------------*
FORM download.
  DATA: l_filename TYPE rlgrap-filename,
        l_msgv      TYPE bapiret2-message_v1,
        ls_filename TYPE string.

  PERFORM get_filename CHANGING l_filename.
  CHECK NOT l_filename IS INITIAL.

  ls_filename = l_filename.

*BOC:HBHALLA (096)
  AUTHORITY-CHECK OBJECT  'S_GUI'
                   ID      'ACTVT'
                   FIELD   '61'.
 IF sy-subrc = 0.
  CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
       EXPORTING
            filename                = ls_filename
            filetype                = 'ASC'
            write_field_separator   = 'X'
            dat_mode                = ' '
       TABLES
            data_tab                = gt_file
       EXCEPTIONS
            file_write_error        = 1
            no_batch                = 2
            gui_refuse_filetransfer = 3
            invalid_type            = 4
            no_authority            = 5
            unknown_error           = 6
            header_not_allowed      = 7
            separator_not_allowed   = 8
            filesize_not_allowed    = 9
            header_too_long         = 10
            dp_error_create         = 11
            dp_error_send           = 12
            dp_error_write          = 13
            unknown_dp_error        = 14
            access_denied           = 15
            dp_out_of_memory        = 16
            disk_full               = 17
            dp_timeout              = 18
            file_not_found          = 19
            dataprovider_exception  = 20
            control_flush_error     = 21
            OTHERS                  = 22.
  IF sy-subrc <> 0.
    l_msgv = l_filename.
    CALL FUNCTION '/PSYNG/BC_003'
         EXPORTING
              i_subrc = sy-subrc
              i_msgty = 'I'
              i_msgv1 = l_msgv.
  ENDIF.
ENDIF.
*EOC:HBHALLA (096)

ENDFORM.                    " download

*&---------------------------------------------------------------------*
*&      Form  get_filename
*&---------------------------------------------------------------------*
*       Prompt user for file name
*----------------------------------------------------------------------*
*      <--E_FILENAME  File name
*----------------------------------------------------------------------*
FORM get_filename CHANGING e_filename TYPE rlgrap-filename.
  CALL FUNCTION 'WS_FILENAME_GET'
       EXPORTING
            mask             = ',*.*,*.*.'
            mode             = 'O'
            title            = text-t02
       IMPORTING
            filename         = e_filename
       EXCEPTIONS
            inv_winsys       = 1
            no_batch         = 2
            selection_cancel = 3
            selection_error  = 4
            OTHERS           = 5.
  IF sy-subrc <> 0 AND sy-subrc <> 3.
    MESSAGE e398(00) WITH text-e03.
  ENDIF.
ENDFORM.                    " get_filename

*&---------------------------------------------------------------------*
*&      Form  get_field_name
*&---------------------------------------------------------------------*
*       Get field name from data dictionary
*----------------------------------------------------------------------*
*      -->I_FIELD   Field name
*      <--E_DDTEXT  Short text for field
*----------------------------------------------------------------------*
FORM get_field_name USING    i_field TYPE /psyng/faobj2-field
                    CHANGING e_ddtext TYPE dd04t-ddtext.

  TYPES: BEGIN OF typ_field,
           field  TYPE /psyng/faobj2-field,
           ddtext TYPE dd04t-ddtext,
         END OF typ_field.

 STATICS: lt_field TYPE HASHED TABLE OF typ_field WITH UNIQUE KEY field.
  DATA: ls_field TYPE typ_field.


  CLEAR e_ddtext.
  READ TABLE lt_field INTO ls_field WITH TABLE KEY field = i_field.
  IF sy-subrc = 0.
    e_ddtext = ls_field-ddtext.
  ELSE.
    SELECT SINGLE dd04t~ddtext INTO ls_field-ddtext  "#EC CI_SEL_NESTED
             FROM authx INNER JOIN dd04t
               ON authx~rollname = dd04t~rollname
            WHERE authx~fieldname = i_field
              AND dd04t~ddlanguage = sy-langu.

    CHECK sy-subrc = 0.
    ls_field-field = i_field.
    INSERT ls_field INTO TABLE lt_field.
    e_ddtext = ls_field-ddtext.
  ENDIF.
ENDFORM.                    " get_field_name

FORM get_appname USING    i_fioriid TYPE /psyng/sw_fioria-fioriid
                    CHANGING e_appname TYPE /psyng/sw_fioria-appname.
  TYPES: BEGIN OF typ_appname,
           fioriid TYPE /psyng/sw_fioria-fioriid,
           appname TYPE /psyng/sw_fioria-appname,
         END OF typ_appname.

STATICS: lt_appname TYPE HASHED TABLE OF typ_appname WITH UNIQUE KEY
fioriid.
  DATA: ls_appname TYPE typ_appname.
  CLEAR e_appname.
  READ TABLE lt_appname INTO ls_appname WITH TABLE KEY
                    fioriid = i_fioriid.
  IF sy-subrc = 0.
    e_appname = ls_appname-appname.
  ELSE.
    SELECT SINGLE appname INTO ls_appname-appname    "#EC CI_SEL_NESTED
      FROM /psyng/sw_fioria WHERE
      fioriid = i_fioriid."#EC SAST_CI_GEN_CHECK
    CHECK sy-subrc = 0.
    ls_appname-fioriid = i_fioriid.
    INSERT ls_appname INTO TABLE lt_appname.
    e_appname = ls_appname-appname.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  mark_changes
*&---------------------------------------------------------------------*
*       Keep track of changes for saving later
*----------------------------------------------------------------------*
*      -->I_FUNID   Function ID
*      -->I_TCODE   Transaction code
*      -->I_OBJECT  Authorization object
*----------------------------------------------------------------------*
FORM mark_changes USING    i_funid  TYPE /psyng/faobj2-funid
                           i_tcode  TYPE /psyng/faobj2-tcode
                           i_object TYPE /psyng/faobj2-object.
  gt_changes-funid  = i_funid.
  gt_changes-tcode  = i_tcode.
  gt_changes-object = i_object.
  COLLECT gt_changes.
ENDFORM.                    " mark_changes

*&---------------------------------------------------------------------*
*&      Form  TOGGLE_DISPLAY_CHANGE
*&---------------------------------------------------------------------*
*       Toggle screen fields between display and change modes
*----------------------------------------------------------------------*
FORM toggle_display_change.
  DATA: BEGIN OF lt_excfunc OCCURS 0,
          func TYPE rsmpe-func,
        END OF lt_excfunc.

  IF gf_dispchg = gc_display.                    "Display
    lt_excfunc-func = 'SAVE'. APPEND lt_excfunc.
    lt_excfunc-func = 'UPLD'. APPEND lt_excfunc.
    lt_excfunc-func = 'UPLDALL'. APPEND lt_excfunc.

    IF s_funid[] IS INITIAL.
      lt_excfunc-func = 'GETALL'. APPEND lt_excfunc.
    ENDIF.

    SET PF-STATUS 'MAIN' EXCLUDING lt_excfunc.

    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 1.
      screen-input = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ELSE.                                          "Change
    IF s_funid[] IS INITIAL.
      SET PF-STATUS 'MAIN' EXCLUDING 'GETALL'.
    ELSE.
      SET PF-STATUS 'MAIN'.
    ENDIF.

    LOOP AT SCREEN.
      CHECK screen-group1 = '001' AND screen-input = 0.
      screen-input = 1.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " TOGGLE_DISPLAY_CHANGE

*&---------------------------------------------------------------------*
*&      Form  free_tree
*&---------------------------------------------------------------------*
*       Free tree object
*----------------------------------------------------------------------*
FORM free_tree.
  IF NOT g_custom_container IS INITIAL.
    " destroy tree container (detroys contained tree control, too)
    CALL METHOD g_custom_container->free
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2.
    IF sy-subrc <> 0.
      MESSAGE a000.
    ENDIF.
    CLEAR: g_custom_container, g_tree.
  ENDIF.
ENDFORM.                    " free_tree

***********************************************************************
FORM cd_call_psyng_faobj                   .
  IF   ( upd_psyng_faobj                    NE space )
    OR ( upd_icdtxt_faobj           NE space )
  .
    DATA : ls_faobj2empty TYPE /psyng/faobj2,
           ls_faobjempty TYPE /psyng/faobj.
    CLEAR ls_faobj2empty.
    CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
         EXPORTING
              objectid                = objectid
              tcode                   = tcode
              utime                   = utime
              udate                   = udate
              username                = username
              planned_change_number   = planned_change_number
              object_change_indicator = cdoc_upd_object
              planned_or_real_changes = cdoc_planned_or_real
              no_change_pointers      = cdoc_no_change_pointers
              n_psyng_faobj           = ls_faobjempty
              o_psyng_faobj           = ls_faobjempty
              o_psyng_faobj2          = /psyng/faobj2
              n_psyng_faobj2          = ls_faobj2empty
              upd_psyng_faobj2        = upd_psyng_faobj
              upd_icdtxt_faobj        = upd_icdtxt_faobj
         TABLES
              icdtxt_faobj            = icdtxt_faobj.



  ENDIF.
  CLEAR planned_change_number.
ENDFORM.
***********************************************************************
*&---------------------------------------------------------------------*
*&      Form  cd_call_psyng_faobj1
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*

*********** Changed by sgottapu on 12.09.2008 ******************

FORM cd_call_psyng_faobj1.

  IF   ( upd_psyng_faobj                    NE space )
    OR ( upd_icdtxt_faobj           NE space )
  .
    DATA : ls_faobj2empty TYPE /psyng/faobj2,
           ls_faobjempty TYPE /psyng/faobj.
    CLEAR ls_faobj2empty.

    CALL FUNCTION '/PSYNG/FAOBJ_WRITE_DOCUMENT' IN UPDATE TASK
         EXPORTING
              objectid                = objectid
              tcode                   = tcode
              utime                   = utime
              udate                   = udate
              username                = username
              planned_change_number   = planned_change_number
              object_change_indicator = cdoc_upd_object
              planned_or_real_changes = cdoc_planned_or_real
              no_change_pointers      = cdoc_no_change_pointers
              n_psyng_faobj           = ls_faobjempty
              o_psyng_faobj           = ls_faobjempty
              o_psyng_faobj2          = ls_faobj2empty
              n_psyng_faobj2          = /psyng/faobj2
              upd_psyng_faobj2        = upd_psyng_faobj
              upd_icdtxt_faobj        = upd_icdtxt_faobj
         TABLES
              icdtxt_faobj            = icdtxt_faobj.
  ENDIF.
  CLEAR planned_change_number.

ENDFORM.                    " cd_call_psyng_faobj1

*&---------------------------------------------------------------------*
*&      Form  get_object_fields
*&---------------------------------------------------------------------*
*       Get fields for authorization object
*----------------------------------------------------------------------*
*      <->ES_TOBJ  Authorization object
*----------------------------------------------------------------------*
FORM get_object_fields CHANGING es_tobj TYPE tobj.
  STATICS: lt_tobj TYPE HASHED TABLE OF tobj WITH UNIQUE KEY objct.


  READ TABLE lt_tobj INTO es_tobj WITH TABLE KEY objct = es_tobj-objct.
  CHECK sy-subrc <> 0.

  SELECT SINGLE * INTO es_tobj FROM tobj WHERE objct = es_tobj-objct.
  CHECK sy-subrc = 0.
  INSERT es_tobj INTO TABLE lt_tobj.
ENDFORM.                    " get_object_fields

*&---------------------------------------------------------------------*
*&      Form  remember_tree_node_state
*&---------------------------------------------------------------------*
*       Keep track of current status of tree
*----------------------------------------------------------------------*
FORM remember_tree_node_state.
  DATA: l_nodeid   TYPE tv_nodekey,
        l_valueset TYPE /psyng/faobj2-valueset.

  FIELD-SYMBOLS: <node> TYPE tv_nodekey.

  check not gt_faobj[] is initial. "no nodes exist
  REFRESH: gt_node_state.

* Get expanded nodes
  CALL METHOD g_tree->get_expanded_nodes
    CHANGING
      node_key_table    = gt_keys[]
    EXCEPTIONS
      cntl_system_error = 1
      dp_error          = 2
      failed            = 3
      OTHERS            = 4.

  IF sy-subrc = 0.
    CLEAR gt_node_state.
    gt_node_state-expanded = 'X'.
    LOOP AT gt_keys ASSIGNING <node>.
      READ TABLE gt_faobj WITH KEY funid = <node>.
      IF sy-subrc = 0.
        gt_node_state-funid = gt_node_state-node_key = <node>.
        APPEND gt_node_state.
        CONTINUE.
      ENDIF.

      CASE <node>(1).
        WHEN 'T'.                 "Transaction
          l_nodeid = <node>+1.
          READ TABLE gt_faobj WITH KEY tnode = l_nodeid.
          CHECK sy-subrc = 0.
          MOVE-CORRESPONDING gt_faobj TO gt_node_state.
        WHEN 'O'.                 "Object
          l_nodeid = <node>+1.
          READ TABLE gt_faobj WITH KEY onode = l_nodeid.
          CHECK sy-subrc = 0.
          MOVE-CORRESPONDING gt_faobj TO gt_node_state.
        WHEN 'G'.                 "Valueset
          SPLIT <node> AT '|' INTO l_nodeid l_valueset.
          READ TABLE gt_faobj WITH KEY onode    = l_nodeid+1
                                       valueset = l_valueset.
          CHECK sy-subrc = 0.
          MOVE-CORRESPONDING gt_faobj TO gt_node_state.
      ENDCASE.

      gt_node_state-node_key = <node>.
      APPEND gt_node_state.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " remember_tree_node_state

*&---------------------------------------------------------------------*
*&      Form  apply_remembered_node_state
*&---------------------------------------------------------------------*
*       Apply status of tree back now that it has been refreshed
*----------------------------------------------------------------------*
FORM apply_remembered_node_state.
  DATA: ls_node LIKE LINE OF gt_node.

* Collapse all nodes
  REFRESH gt_keys.
  LOOP AT gt_node INTO ls_node.
    gt_keys = ls_node-node_key.
    APPEND gt_keys.
  ENDLOOP.

  CALL METHOD g_tree->collapse_nodes
    EXPORTING
      node_key_table = gt_keys[].

  REFRESH: gt_keys[].
  LOOP AT gt_node_state WHERE expanded = 'X'.
    IF gt_node_state-tnode IS INITIAL.
      READ TABLE gt_faobj WITH KEY funid = gt_node_state-funid.
      CHECK sy-subrc = 0.

      gt_keys = gt_node_state-node_key.
      APPEND gt_keys.
      CONTINUE.
    ELSE.
      READ TABLE gt_faobj WITH KEY funid    = gt_node_state-funid
                                   tcode    = gt_node_state-tcode
                                   object   = gt_node_state-object
                                   valueset = gt_node_state-valueset.
      CHECK sy-subrc = 0.
    ENDIF.

    CASE gt_node_state-node_key(1).
      WHEN 'T'.                   "Transaction
        gt_keys = gt_faobj-tnode.
        CONDENSE gt_keys.
        CONCATENATE 'T' gt_keys INTO gt_keys.
      WHEN 'O'.                   "Object
        gt_keys = gt_faobj-onode.
        CONDENSE gt_keys.
        CONCATENATE 'O' gt_keys INTO gt_keys.
      WHEN 'G'.                   "Valueset
        gt_keys = gt_faobj-onode.
        CONDENSE gt_keys.
        CONCATENATE 'G' gt_keys '|' gt_faobj-valueset INTO gt_keys.
    ENDCASE.

    APPEND gt_keys.
  ENDLOOP.

  CALL METHOD g_tree->expand_nodes
    EXPORTING
      node_key_table = gt_keys[].
ENDFORM.                    " apply_remembered_node_state

*&---------------------------------------------------------------------*
*&      Form  f4_value
*&---------------------------------------------------------------------*
*       F4 help for authorization value
*----------------------------------------------------------------------*
*      <--E_VALUE  Value
*----------------------------------------------------------------------*
FORM f4_value CHANGING e_value TYPE /psyng/faobj2-val_from.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: l_repid    TYPE sy-repid,
        l_dynnr    TYPE sy-dynnr,
        l_disp     TYPE /psyng/flag,
        l_fname    TYPE lvc_fname,
        l_shlpname TYPE dd35l-shlpname,
        l_line     TYPE i,
        ls_authx   TYPE authx,
        lt_dd07    TYPE TABLE OF dd07v WITH HEADER LINE,
        lt_fields  TYPE TABLE OF dfies WITH HEADER LINE,
        lt_return  TYPE TABLE OF ddshretval WITH HEADER LINE,
        step_loop  LIKE sy-stepl,
        i_dynpfields LIKE dynpread OCCURS 0 WITH HEADER LINE,
        lt_returnvalues TYPE TABLE OF ddshretval WITH HEADER LINE,
        i_val TYPE tprorg1-low,
        k_f4_for_co_action(30) TYPE c VALUE 'K_F4_FOR_CO_ACTION',
        lt_tactt LIKE tactt OCCURS 100 WITH HEADER LINE,
        lt_english_tactt LIKE tactt OCCURS 0 WITH HEADER LINE,
        lt_tactz LIKE tactz OCCURS 100 WITH HEADER LINE.

  DATA: BEGIN OF h_fval OCCURS 100,
          actvt         LIKE usobt-low,
          ltext         LIKE tactt-ltext,
          mark,
        END OF h_fval.


  GET CURSOR LINE l_line.
  l_line = tc_seltab-top_line + l_line - 1.

  READ TABLE gt_select INDEX l_line.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  IF gf_dispchg = gc_change.
    CLEAR l_disp.
  ELSE.
    l_disp = 'X'.
  ENDIF.

  l_fname = gt_select-field.


  SELECT SINGLE * FROM authx INTO ls_authx WHERE fieldname = l_fname.
  CHECK sy-subrc = 0.

  IF NOT ls_authx-checktable IS INITIAL
  AND ls_authx-rollname IS INITIAL.
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
         EXPORTING
              tabname           = ls_authx-checktable
              fieldname         = l_fname
              dynpprog          = l_repid
              dynpnr            = l_dynnr
              display           = l_disp
         TABLES
              return_tab        = lt_return
         EXCEPTIONS
              field_not_found   = 1
              no_help_for_field = 2
              inconsistent_help = 3
              no_values_found   = 4
              OTHERS            = 5.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
    AND gf_dispchg = gc_change.
      READ TABLE lt_return INDEX 1.
      e_value = lt_return-fieldval.
    ENDIF.

  ELSEIF NOT ls_authx-rollname IS INITIAL.
    FREE: lt_dd07.
    lt_fields-tabname   = 'DD07V'.
    lt_fields-fieldname = 'DOMVALUE_L'.
    APPEND lt_fields.
    lt_fields-tabname   = 'DD07V'.
    lt_fields-fieldname = 'DDTEXT'.
    APPEND lt_fields.

    CALL FUNCTION 'DDIF_DOMA_GET'
         EXPORTING
              name      = ls_authx-rollname
              langu     = sy-langu
         TABLES
              dd07v_tab = lt_dd07
"(++)BOC UMITTAL SE VF scan-25/11/2024
         EXCEPTIONS
           ILLEGAL_INPUT = 1
           OTHERS        = 2 .
    IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024
    IF sy-subrc = 0 AND NOT lt_dd07[] IS INITIAL.
      LOOP AT lt_dd07.
        lt_values-line = lt_dd07-domvalue_l.
        APPEND lt_values.
        lt_values-line = lt_dd07-ddtext.
        APPEND lt_values.
      ENDLOOP.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'DOMVALUE_L'
           TABLES
                value_tab       = lt_values
                field_tab       = lt_fields
                return_tab      = lt_return
           EXCEPTIONS
                parameter_error = 1
                no_values_found = 2
                OTHERS          = 3.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
      AND gf_dispchg = gc_change.
        READ TABLE lt_return INDEX 1.
        e_value = lt_return-fieldval.
      ENDIF.

    ELSE.
*-- To include only allowed values of ACTVT
      IF l_fname = 'ACTVT'.
        REFRESH h_fval.

        SELECT * FROM tactt INTO TABLE lt_tactt WHERE spras = sy-langu.
        SORT lt_tactt BY actvt.
        SELECT * FROM tactt INTO TABLE lt_english_tactt
                       WHERE spras = 'E'.
        LOOP AT lt_english_tactt.
          READ TABLE lt_tactt WITH KEY actvt = lt_english_tactt-actvt
                                                     BINARY SEARCH.
          IF sy-subrc NE 0.
            lt_tactt = lt_english_tactt.
            INSERT lt_tactt INDEX sy-tabix.
          ENDIF.
        ENDLOOP.

        SELECT * FROM tactz INTO TABLE lt_tactz.
        SORT lt_tactz.

        LOOP AT lt_tactt.
          lt_tactt-spras = sy-langu.
          MODIFY lt_tactt.
        ENDLOOP.
        SORT lt_tactt .

        LOOP AT lt_tactt.
          h_fval-actvt      = lt_tactt-actvt.
          h_fval-ltext      = lt_tactt-ltext.

          READ TABLE lt_tactz WITH KEY brobj = gt_select-object
                                      actvt = lt_tactt-actvt
                             BINARY SEARCH.
          IF sy-subrc = 0.
            READ TABLE h_fval
                    WITH KEY actvt = h_fval-actvt BINARY SEARCH.
            IF sy-subrc <> 0.
              INSERT h_fval INDEX sy-tabix.
            ENDIF.
          ENDIF.
        ENDLOOP.

        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
          EXPORTING
            retfield               = 'ACTVT'
            dynpprog               = l_repid
            dynpnr                 = l_dynnr
            dynprofield            = 'GT_SELECT-VAL_FROM'
            value_org              = 'S'
          TABLES
            value_tab              = h_fval[]
            return_tab             = lt_return
         EXCEPTIONS
           parameter_error        = 1
           no_values_found        = 2
           OTHERS                 = 3
                  .
        IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.
        IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
        AND gf_dispchg = gc_change.
          READ TABLE lt_return INDEX 1.
          e_value = lt_return-fieldval.
        ENDIF.
*----------------*
      ELSE." If field other than ACTVT

        SELECT SINGLE shlpname INTO l_shlpname FROM dd35l
        WHERE tabname = ls_authx-checktable."#EC SAST_CI_GEN_CHECK

*      CHECK sy-subrc = 0.
        IF sy-subrc = 0.
          CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
               EXPORTING
                    tabname           = ls_authx-checktable
                    fieldname         = l_fname
                    searchhelp        = l_shlpname
                    dynpprog          = l_repid
                    dynpnr            = l_dynnr
                    display           = l_disp
               TABLES
                    return_tab        = lt_return
               EXCEPTIONS
                    field_not_found   = 1
                    no_help_for_field = 2
                    inconsistent_help = 3
                    no_values_found   = 4
                    OTHERS            = 5.

          IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
          AND gf_dispchg = gc_change.
            READ TABLE lt_return INDEX 1.
            e_value = lt_return-fieldval.
          ENDIF.

        ELSE.

          i_dynpfields-fieldname = 'GT_SELECT-VAL_FROM'.
          APPEND i_dynpfields.

          CALL FUNCTION 'DYNP_GET_STEPL'
               IMPORTING
                    povstepl        = step_loop
               EXCEPTIONS
                    stepl_not_found = 1
                    OTHERS          = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.

          CALL FUNCTION 'DYNP_VALUES_READ'
            EXPORTING
              dyname                         = l_repid
              dynumb                         = l_dynnr
             translate_to_upper             = 'X '
*   REQUEST                        = ' '
*   PERFORM_CONVERSION_EXITS       = ' '
*   PERFORM_INPUT_CONVERSION       = ' '
*   DETERMINE_LOOP_INDEX           = ' '
            TABLES
              dynpfields                     = i_dynpfields
           EXCEPTIONS
             invalid_abapworkarea           = 1
             invalid_dynprofield            = 2
             invalid_dynproname             = 3
             invalid_dynpronummer           = 4
             invalid_request                = 5
             no_fielddescription            = 6
             invalid_parameter              = 7
             undefind_error                 = 8
             double_conversion              = 9
             stepl_not_found                = 10
             OTHERS                         = 11
                    .
          IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
          ENDIF.

          IF gt_select-field = 'CO_ACTION'.
            CALL FUNCTION 'K_F4_FOR_CO_ACTION'
                 EXPORTING
                      object    = gt_select-object
                 IMPORTING
                      co_action = i_val.

            IF sy-subrc EQ 0.
* Filling the RETURN_VALUES table with selected value
              CLEAR lt_returnvalues[].
              lt_returnvalues-fieldname = gt_select-field.
              lt_returnvalues-recordpos = 0001.
              lt_returnvalues-fieldval  = i_val. "Single value
              APPEND lt_returnvalues.
            ELSE.
              MESSAGE e135 WITH text-018. "Action cancelled
            ENDIF.
            EXIT.
          ENDIF.

          CALL FUNCTION 'SUSR_AUTF_GET_F4_HELP'
            EXPORTING
               fieldname             = l_fname
               dyname                = l_repid
               dynumb                = l_dynnr
               dynprofield           = 'GT_SELECT-VAL_FROM'
               povstepl              = step_loop
*   MULTIPLE_CHOICE       = ' '
            TABLES
             dynpfields            = i_dynpfields
              selected_value        = lt_returnvalues
                    .
          IF sy-subrc = 0 AND NOT lt_returnvalues[] IS INITIAL
          AND gf_dispchg = gc_change.
            READ TABLE lt_returnvalues INDEX 1.
            e_value = lt_returnvalues-fieldval.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                                                    " f4_value

*&---------------------------------------------------------------------*
*&      Form  f4_field
*&---------------------------------------------------------------------*
*       F4 help for authorization field
*----------------------------------------------------------------------*
*      <--E_FIELD  Field
*----------------------------------------------------------------------*
FORM f4_field CHANGING e_field TYPE /psyng/faobj2-field.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: l_count        TYPE i,
        l_line         TYPE i,
        l_fieldname(5) TYPE c,
        lt_tobj        TYPE TABLE OF tobj WITH HEADER LINE,
        lt_fields      TYPE TABLE OF dfies WITH HEADER LINE,
        lt_return      TYPE TABLE OF ddshretval WITH HEADER LINE.

  FIELD-SYMBOLS: <field> TYPE tobj-fiel0.


  GET CURSOR LINE l_line.
  l_line = tc_seltab-top_line + l_line - 1.

  READ TABLE gt_select INDEX l_line.

  lt_fields-tabname   = 'TOBJ'.
  lt_fields-fieldname = 'OBJCT'.
  APPEND lt_fields.
  lt_fields-tabname   = 'USORG'.
  lt_fields-fieldname = 'FIELD'.
  APPEND lt_fields.
  lt_fields-tabname   = 'DD04T'.
  lt_fields-fieldname = 'DDTEXT'.
  APPEND lt_fields.

  SELECT * FROM tobj INTO TABLE lt_tobj WHERE objct = gt_select-object.

  LOOP AT lt_tobj.
    CLEAR l_count.
    DO 10 TIMES.
      l_fieldname = l_count.
      CONDENSE l_fieldname.
      CONCATENATE 'FIEL' l_fieldname INTO l_fieldname.

      ASSIGN COMPONENT l_fieldname OF STRUCTURE lt_tobj TO <field>.
"#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)

      IF NOT <field> IS INITIAL.
        lt_values-line = gt_select-object.
        APPEND lt_values.
        lt_values-line = <field>.
        APPEND lt_values.

        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
              INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname  = <field>
                 AND dd04t~ddlanguage = sy-langu.
        APPEND lt_values.
      ENDIF.

      ADD 1 TO l_count.
    ENDDO.
  ENDLOOP.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'FIELD'
       TABLES
            value_tab       = lt_values
            field_tab       = lt_fields
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
  AND gf_dispchg = gc_change.
    READ TABLE lt_return INDEX 1.
    e_field = lt_return-fieldval.
  ENDIF.
ENDFORM.              " f4_field

FORM get_appid_hashkey
  TABLES
    et_usobt STRUCTURE USOBT_C
   USING
      i_appid TYPE /psyng/sw_fioriid.

  TYPES:  BEGIN OF ty_odata,
           odataservicename TYPE /psyng/sw_fiorio-odataservicename,
          END OF ty_odata.
  TYPES: BEGIN OF ty_data,
        sign    TYPE /psyng/range_fioriid-sign,
        option  TYPE /psyng/range_fioriid-option,
        low     TYPE /psyng/sw_fiorio-odataservicename,
        high    TYPE /psyng/sw_fiorio-odataservicename,
    END OF ty_data.

  DATA: lt_odata TYPE TABLE OF ty_odata,
        ls_odata LIKE LINE OF lt_odata,
        lr_odata  TYPE TABLE OF ty_data,
        ls_data LIKE LINE OF lr_odata,
        lt_usobhash type table of usobhash,
        ls_usobhash like line of lt_usobhash,
        ls_usobt    like line of et_usobt.

  SELECT  odataservicename FROM /psyng/sw_fiorio
               INTO TABLE lt_odata
               WHERE fioriid = i_appid.

  LOOP AT lt_odata INTO ls_odata.
    CONCATENATE '*' ls_odata-odataservicename '*'
    INTO ls_data-low.
    ls_data-sign = 'I'.
    ls_data-option = 'CP'.
    APPEND ls_data TO lr_odata.
  ENDLOOP.

  IF NOT lr_odata[] IS INITIAL.
    SELECT name obj_name FROM usobhash INTO
           CORRESPONDING FIELDS OF TABLE
           lt_usobhash
      WHERE obj_name IN lr_odata."#EC SAST_CI_GEN_CHECK
  ENDIF.
  loop at lt_usobhash into ls_usobhash.
    ls_usobt-NAME = ls_usobhash-name.
    append ls_usobt to et_usobt.
    endloop.
ENDFORM.
