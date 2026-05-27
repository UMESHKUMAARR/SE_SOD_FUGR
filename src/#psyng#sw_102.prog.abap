*----------------------------------------------------------------------*
* Report  /PSYNG/SW_102                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_102.

TYPES: t_node_table LIKE TABLE OF mtreesnode,
       t_tree_item  LIKE TABLE OF mtreeitm.
TABLES : /psyng/mchdr.

CLASS lcl_application DEFINITION DEFERRED.
CLASS cl_gui_cfw DEFINITION LOAD.

DATA: go_cust_container TYPE REF TO cl_gui_custom_container,
      go_tree           TYPE REF TO cl_gui_column_tree,
      g_node_key        TYPE tv_nodekey,
      gt_hdr            TYPE TABLE OF /psyng/mchdr,
      gt_auditor        TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE,
      gt_tran           TYPE TABLE OF /psyng/mctran,
      gt_repid          TYPE TABLE OF /psyng/mcrepid,
      gt_type           TYPE TABLE OF /psyng/sw_mctype,
      gt_conpmit        TYPE TABLE OF /psyng/conpmit WITH HEADER LINE.

DATA: BEGIN OF gt_freqtext OCCURS 0,
        freq TYPE /psyng/sw_freq-freq,
        text   TYPE /psyng/sw_freqt-text,
        lang   TYPE /psyng/sw_freqt-lang,
      END OF gt_freqtext.
TYPES: item_table_type LIKE STANDARD TABLE OF mtreeitm
       WITH DEFAULT KEY.

DATA: BEGIN OF gt_conflict OCCURS 0,
        conid  TYPE /psyng/conflict-conid,
        vrsio  TYPE /psyng/conflict-vrsio,
        contid TYPE /psyng/conflict-contid,
        company TYPE /psyng/conpmit-company,
      END OF gt_conflict.
DATA: g_application TYPE REF TO lcl_application,
node_table TYPE treev_ntab,
g_item_name TYPE tv_itmname,
item_table TYPE item_table_type,
item TYPE mtreeitm,
g_ok_code TYPE sy-ucomm,
gt_item   TYPE t_tree_item,
g_dynnr LIKE sy-dynnr.


DATA: BEGIN OF gt_output OCCURS 0,
        contid      LIKE /psyng/mchdr-contid,
        description LIKE /psyng/mchdr-description,
        approver    LIKE /psyng/mchdr-approver,
        type        LIKE /psyng/mchdr-type,
        text        LIKE /psyng/sw_mctype-text,
        auditor     LIKE /psyng/mcauditor-auditor,
        company     LIKE /psyng/mcauditor-company,
        tcode       LIKE /psyng/mctran-tcode,
        tfreq       LIKE dd07t-ddtext,
        repid       LIKE /psyng/mcrepid-repid,
        rfreq       LIKE dd07t-ddtext,
        conid       LIKE /psyng/conflict-conid,
        vrsio       LIKE /psyng/conflict-vrsio,
        mitcompany  LIKE /psyng/conpmit-company,
      END OF gt_output.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_contid FOR gt_output-contid,
                s_appr   FOR /psyng/mchdr-approver,
                s_type   FOR gt_output-type.
SELECTION-SCREEN SKIP.
PARAMETERS: p_conf AS CHECKBOX DEFAULT 'X' USER-COMMAND conf.
SELECT-OPTIONS: s_vrsio FOR gt_output-vrsio.
SELECTION-SCREEN END OF BLOCK blk1.

INITIALIZATION.
  PERFORM exelog.



*AT SELECTION-SCREEN.
*  LOOP AT SCREEN.
*  CHECK screen-name = 'S_APPR'.
*    REFRESH : s_appr.
*    MODIFY SCREEN.
*  ENDLOOP.
*-------------------- AT SELECTION-SCREEN OUTPUT ----------------------*
AT SELECTION-SCREEN OUTPUT.
* Don't allow input of SOD version if conflicts are not included

  LOOP AT SCREEN.

    CHECK screen-name = 'S_VRSIO-LOW' OR screen-name = 'S_VRSIO-HIGH'.
    IF p_conf = 'X'.
      screen-input = 1.
    ELSE.

      REFRESH s_vrsio.
      screen-input = 0.
    ENDIF.

    MODIFY SCREEN.
  ENDLOOP.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_contid-low.
*
*  DATA : lt_contid TYPE TABLE OF /psyng/mchdr-contid.
*  DATA: lt_return TYPE STANDARD TABLE OF ddshretval,
*        wa_return LIKE LINE OF lt_return.
*
*  SELECT contid FROM /psyng/mchdr INTO TABLE lt_contid.
*
*  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*       EXPORTING
*            retfield     = 'CONTID'
*            value_org    = 'S'
*            dynpprog     = sy-repid
*            dynpnr       = sy-dynnr
*            window_title = 'Control ID'
*       TABLES
*            value_tab    = lt_contid
*            return_tab   = lt_return.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.

*----------------------------------------------------------------------*
* Start Local Class for Tree format
*----------------------------------------------------------------------*
*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*

CLASS lcl_application DEFINITION.

  PUBLIC SECTION.
    METHODS:
      handle_item_double_click
        FOR EVENT item_double_click
        OF cl_gui_column_tree
        IMPORTING node_key item_name.

     ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_application IMPLEMENTATION.
  METHOD  handle_item_double_click.
    DATA : l_node_key LIKE g_node_key,
           l_repid    LIKE sy-repid,
           wa_node1 LIKE LINE OF node_table,
           wa_node2 LIKE LINE OF node_table,
           wa_item1 TYPE mtreeitm,
           l_authfield TYPE fieldname,
           l_parva        TYPE usr05-parva,
           l_sod          TYPE /psyng/swsodvers-vrsio,
           l_uname        LIKE sy-uname,
           l_pos TYPE i.




    g_node_key = node_key.
    g_item_name = item_name.
    DATA: answer.
    READ TABLE gt_item INTO item WITH KEY node_key = g_node_key
    item_name = g_item_name.
    IF sy-subrc = 0.
*---Mitigation ID
      IF g_node_key+0(1) = 'M' AND g_item_name = 'Column1'.

       CHECK item-text <> space.

       IF item-text CA space.
        l_pos = sy-fdpos. "Getting offset
       ENDIF.

       item-text = item-text+0(l_pos).
*      l_uname = sy-uname.
*-- Get user's default version
*      SELECT SINGLE parva INTO l_parva FROM usr05
*                 WHERE bname = l_uname
*                   AND parid = '/PSYNG/VRSIO'.
*      IF sy-subrc = 0 AND l_parva <> space.
*        l_sod = l_parva.
*      ENDIF.

*      PERFORM set_default_sodversion USING s_vrsio l_uname.
      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD item-text .
      g_dynnr = '0211'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
**-- Set back to Default
*      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.


      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
*------------------------ START-OF-SELECTION --------------------------*
START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  PERFORM get_data.
  PERFORM build_output.
  CREATE OBJECT g_application.
  CALL SCREEN 2000.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get mitigation data
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * INTO TABLE gt_hdr FROM /psyng/mchdr
         WHERE contid   IN s_contid
           AND approver IN s_appr
           AND type     IN s_type
         ORDER BY PRIMARY KEY.

*Delete incorrect data
  DELETE gt_hdr WHERE contid = ''.
  CHECK NOT gt_hdr[] IS INITIAL.

  SELECT * INTO TABLE gt_type FROM /psyng/sw_mctype
         ORDER BY PRIMARY KEY.

  SELECT * INTO TABLE gt_auditor FROM /psyng/mcauditor
         FOR ALL ENTRIES IN gt_hdr
         WHERE contid = gt_hdr-contid
         ORDER BY PRIMARY KEY.

  SELECT * INTO TABLE gt_tran FROM /psyng/mctran
         FOR ALL ENTRIES IN gt_hdr
         WHERE contid = gt_hdr-contid
         ORDER BY PRIMARY KEY.

  SELECT * INTO TABLE gt_repid FROM /psyng/mcrepid
         FOR ALL ENTRIES IN gt_hdr
         WHERE contid = gt_hdr-contid
         ORDER BY PRIMARY KEY.

  IF p_conf = 'X'.
    SELECT conid vrsio contid
    INTO CORRESPONDING FIELDS OF TABLE gt_conflict
           FROM /psyng/conflict
           FOR ALL ENTRIES IN gt_hdr
           WHERE contid  = gt_hdr-contid
             AND contid <> space
             AND vrsio  IN s_vrsio.
    SORT gt_conflict BY contid.

    SELECT conid vrsio contid company FROM /psyng/conpmit
    INTO CORRESPONDING FIELDS OF TABLE gt_conpmit
     FOR ALL ENTRIES IN gt_hdr
        WHERE contid  = gt_hdr-contid
             AND contid <> space
             AND vrsio  IN s_vrsio.
  ENDIF.

  LOOP AT gt_conpmit.
*    READ TABLE gt_auditor WITH KEY contid = gt_conpmit-contid
*                            company = gt_conpmit-company
* TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0 OR gt_conpmit-company IS INITIAL.
      gt_conflict-conid = gt_conpmit-conid.
      gt_conflict-vrsio = gt_conpmit-vrsio.
      gt_conflict-contid = gt_conpmit-contid.
      gt_conflict-company = gt_conpmit-company.
      APPEND gt_conflict.
*    ENDIF.
  ENDLOOP.

  SELECT a~freq b~text b~lang INTO
         CORRESPONDING FIELDS OF TABLE gt_freqtext
         FROM /psyng/sw_freq AS a
         INNER JOIN /psyng/sw_freqt AS b ON a~freq = b~freq
         WHERE lang = sy-langu.

ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  build_output
*&---------------------------------------------------------------------*
*       Build output table
*----------------------------------------------------------------------*
FORM build_output.
  DATA: l_aud_cnt  TYPE i,
        l_tran_cnt TYPE i,
        l_rep_cnt  TYPE i,
        l_con_cnt  TYPE i,
        l_out_cnt  TYPE i.

  FIELD-SYMBOLS: <hdr>  LIKE LINE OF gt_hdr,
                 <type> LIKE LINE OF gt_type,
                 <aud>  LIKE LINE OF gt_auditor,
                 <tran> LIKE LINE OF gt_tran,
                 <rep>  LIKE LINE OF gt_repid,
                 <con>  LIKE LINE OF gt_conflict,
                 <out>  LIKE LINE OF gt_output.


  LOOP AT gt_hdr ASSIGNING <hdr>.
    CLEAR: gt_output, l_aud_cnt, l_tran_cnt, l_rep_cnt, l_con_cnt.
    MOVE-CORRESPONDING <hdr> TO gt_output.

    READ TABLE gt_type ASSIGNING <type> WITH KEY type = <hdr>-type
               BINARY SEARCH.
    IF sy-subrc = 0.
      gt_output-text = <type>-text.
    ENDIF.

    LOOP AT gt_auditor ASSIGNING <aud> WHERE contid = <hdr>-contid.
      MOVE-CORRESPONDING <aud> TO gt_output.
      APPEND gt_output.
      ADD 1 TO l_aud_cnt.
    ENDLOOP.

    CLEAR: gt_output-auditor, gt_output-company, gt_freqtext-text.
    LOOP AT gt_tran ASSIGNING <tran> WHERE contid = <hdr>-contid.
      ADD 1 TO l_tran_cnt.

      IF l_aud_cnt = 0.
        READ TABLE gt_freqtext WITH KEY freq = <tran>-frequency.
        IF sy-subrc = 0.
          gt_output-tfreq = gt_freqtext-text.
        ENDIF.

        gt_output-tcode = <tran>-tcode.
        APPEND gt_output.
      ELSE.
        CLEAR : l_out_cnt, gt_freqtext-text.
        LOOP AT gt_output ASSIGNING <out> WHERE contid = <hdr>-contid.
          ADD 1 TO l_out_cnt.

          IF l_out_cnt = l_tran_cnt.
            <out>-tcode = <tran>-tcode.

            READ TABLE gt_freqtext
                       WITH KEY freq = <tran>-frequency.
            IF sy-subrc = 0.
              <out>-tfreq = gt_freqtext-text.
            ENDIF.
          ENDIF.
        ENDLOOP.

        IF l_out_cnt < l_tran_cnt.
          CLEAR gt_freqtext-text.
          READ TABLE gt_freqtext WITH KEY freq = <tran>-frequency.
          IF sy-subrc = 0.
            gt_output-tfreq = gt_freqtext-text.
          ENDIF.

          gt_output-tcode = <tran>-tcode.
          APPEND gt_output.
        ENDIF.
      ENDIF.
    ENDLOOP.

    CLEAR: gt_output-tcode, gt_output-tfreq, gt_freqtext-text.
    LOOP AT gt_repid ASSIGNING <rep> WHERE contid = <hdr>-contid.
      ADD 1 TO l_rep_cnt.

      IF l_rep_cnt = 0.
        READ TABLE gt_freqtext WITH KEY freq = <rep>-frequency.
        IF sy-subrc = 0.
          gt_output-rfreq = gt_freqtext-text.
        ENDIF.

        gt_output-repid = <rep>-repid.
        APPEND gt_output.
      ELSE.
        CLEAR: l_out_cnt, gt_freqtext-text.
        LOOP AT gt_output ASSIGNING <out> WHERE contid = <hdr>-contid.
          ADD 1 TO l_out_cnt.

          IF l_out_cnt = l_rep_cnt.
            <out>-repid = <rep>-repid.

            READ TABLE gt_freqtext
                       WITH KEY freq = <rep>-frequency.
            IF sy-subrc = 0.
              <out>-rfreq = gt_freqtext-text.
            ENDIF.
          ENDIF.
        ENDLOOP.

        IF l_out_cnt < l_rep_cnt.
          READ TABLE gt_freqtext WITH KEY freq = <rep>-frequency.
          IF sy-subrc = 0.
            gt_output-rfreq = gt_freqtext-text.
          ENDIF.

          gt_output-repid = <rep>-repid.
          APPEND gt_output.
        ENDIF.
      ENDIF.
    ENDLOOP.

    CLEAR: gt_output-repid, gt_output-rfreq.
    LOOP AT gt_conflict ASSIGNING <con> WHERE contid = <hdr>-contid.
      ADD 1 TO l_con_cnt.

      IF l_con_cnt = 0.
        gt_output-conid = <con>-conid.
        gt_output-vrsio = <con>-vrsio.
        gt_output-mitcompany = <con>-company.
        APPEND gt_output.
      ELSE.
        CLEAR l_out_cnt.
        LOOP AT gt_output ASSIGNING <out> WHERE contid = <hdr>-contid.
          ADD 1 TO l_out_cnt.

          IF l_out_cnt = l_con_cnt.
            <out>-conid = <con>-conid.
            <out>-vrsio = <con>-vrsio.
            <out>-mitcompany = <con>-company.
          ENDIF.
        ENDLOOP.

        IF l_out_cnt < l_con_cnt.
          gt_output-conid = <con>-conid.
          gt_output-vrsio = <con>-vrsio.
          gt_output-mitcompany = <con>-company.
          APPEND gt_output.
        ENDIF.
      ENDIF.
    ENDLOOP.
*--Fixes issue where Mitigation Controls are not showing up if they
*--dont have Auditor or Transaction or Program filled in
    IF l_con_cnt IS INITIAL
    AND l_rep_cnt IS INITIAL
    AND l_tran_cnt IS INITIAL
    AND l_aud_cnt IS INITIAL.
     APPEND gt_output.
    ENDIF.

  ENDLOOP.
  IF gt_output[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    " build_output

*&---------------------------------------------------------------------*
*&      Module  status_2000  OUTPUT
*&---------------------------------------------------------------------*
*       Initialize screen 2000
*----------------------------------------------------------------------*
MODULE status_2000 OUTPUT.
  SET TITLEBAR 'MAIN'.
  SET PF-STATUS 'MAIN'.

  IF go_tree IS INITIAL.
    PERFORM create_and_init_tree.
  ENDIF.
ENDMODULE.                 " status_2000  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_2000  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 2000
*----------------------------------------------------------------------*
MODULE user_command_2000 INPUT.
  DATA: l_return_code TYPE i.
    CALL METHOD cl_gui_cfw=>dispatch
    IMPORTING return_code = l_return_code.
  IF l_return_code <> cl_gui_cfw=>rc_noevent.
    CLEAR g_ok_code.
    EXIT.
  ENDIF.


  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANCEL'.           "Exit
      SET SCREEN 0.
      LEAVE SCREEN.

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
ENDMODULE.                 " user_command_2000  INPUT

*&---------------------------------------------------------------------*
*&      Form  create_and_init_tree
*&---------------------------------------------------------------------*
*       Create tree control
*----------------------------------------------------------------------*
FORM create_and_init_tree.
  DATA: lt_node   TYPE treev_ntab,
        lt_item   TYPE t_tree_item,
        ls_event  TYPE cntl_simple_event,
        lt_events TYPE cntl_simple_events,
        ls_header TYPE treev_hhdr.


* Create a container for the tree control
  CREATE OBJECT go_cust_container
    EXPORTING
      container_name              = 'TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE e000(tree_control_msg).
  ENDIF.

* Setup the hierarchy header
  ls_header-heading = 'Mitigation Control / Auditor - Company'(h00).
  ls_header-width   = 100.

  CREATE OBJECT go_tree
    EXPORTING
      parent                      = go_cust_container
      node_selection_mode     = cl_gui_column_tree=>node_sel_mode_single
      item_selection              = 'X'
      hierarchy_column_name       = 'Column1'
      hierarchy_header            = ls_header
    EXCEPTIONS
      cntl_system_error           = 1
      create_error                = 2
      failed                      = 3
      illegal_node_selection_mode = 4
      illegal_column_name         = 5
      lifetime_error              = 6.
  IF sy-subrc <> 0.
    MESSAGE e000(tree_control_msg).
  ENDIF.

  ls_event-eventid = cl_gui_column_tree=>eventid_item_double_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.

CALL METHOD go_tree->set_registered_events
    EXPORTING
      events = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

 SET HANDLER g_application->handle_item_double_click FOR go_tree.

* Column2
  CALL METHOD go_tree->add_column
    EXPORTING
      name                         = 'Column2'
      width                        = 40
      header_text                  = 'Approver / TCode - Frequency'(h01)
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
    MESSAGE e000(tree_control_msg).
  ENDIF.
* Column3
  CALL METHOD go_tree->add_column
    EXPORTING
      name                         = 'Column3'
      width                        = 50
      alignment                    = cl_gui_column_tree=>align_left
      header_text                = 'Mit. Type / Report - Frequency'(h02)
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
    MESSAGE e000(tree_control_msg).
  ENDIF.
* Column4
  IF p_conf = 'X'.
    CALL METHOD go_tree->add_column
      EXPORTING
        name                         = 'Column4'
        width                        = 20
        alignment                    = cl_gui_column_tree=>align_left
        header_text               = 'Conflict / Version / Company'(h03)
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
      MESSAGE e000(tree_control_msg).
    ENDIF.
  ENDIF.

  PERFORM build_node_table TABLES lt_node gt_item.

  CALL METHOD go_tree->add_nodes_and_items
    EXPORTING
      node_table                     = lt_node
      item_table                     = gt_item
      item_table_structure_name      = 'MTREEITM'
    EXCEPTIONS
      failed                         = 1
      cntl_system_error              = 3
      error_in_tables                = 4
      dp_error                       = 5
      table_structure_name_not_found = 6.
  IF sy-subrc <> 0.
    MESSAGE e000(tree_control_msg).
  ENDIF.

  CALL METHOD go_tree->expand_root_nodes
       EXPORTING
            expand_subtree      = 'X'
       EXCEPTIONS
            failed              = 1
            illegal_level_count = 2
            cntl_system_error   = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'W' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " create_and_init_tree

*&---------------------------------------------------------------------*
*&      Form  build_node_table
*&---------------------------------------------------------------------*
*       Build nodes and items table
*----------------------------------------------------------------------*
*      -->ET_NODE  Nodes table
*      -->ET_ITEM  Items table
*----------------------------------------------------------------------*
FORM build_node_table    TABLES et_node TYPE treev_ntab
                                et_item TYPE t_tree_item.
  DATA: ls_node TYPE treev_node,
        ls_item TYPE mtreeitm,
        l_index TYPE i,
        l_index_c TYPE string,
        l_contid_nodekey LIKE treev_node-node_key .


  LOOP AT gt_output.
    l_index = sy-tabix.
*DHORIONS 20130522 - contid is used later to lookup auditor so we
*                    can't change the id
*    CONCATENATE gt_output-contid ' ' INTO gt_output-contid.
*    MODIFY gt_output TRANSPORTING contid.
    AT NEW text.
      CLEAR: ls_node-relatkey, ls_node-relatship, ls_node-n_image,
             ls_node-exp_image, ls_node-expander.
*--DHORIONS 20130522 : Make sure node keys are unique
*      ls_node-node_key = gt_output-contid.
      l_index_c = l_index.
      CONCATENATE 'M_' l_index_c INTO l_contid_nodekey.
      ls_node-node_key = l_contid_nodekey.

      ls_node-isfolder = 'X'.
      ls_node-n_image = 'X'.
      APPEND ls_node TO et_node.

      CLEAR ls_item.
*      ls_item-node_key  = gt_output-contid.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 'Column1'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      CONCATENATE gt_output-contid gt_output-description
            INTO ls_item-text SEPARATED BY space.
      APPEND ls_item TO et_item.

      CLEAR ls_item.
*      ls_item-node_key  = gt_output-contid.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 'Column2'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      ls_item-text      = gt_output-approver.
      APPEND ls_item TO et_item.

      IF NOT gt_output-type IS INITIAL.
        CLEAR ls_item.
*        ls_item-node_key  = gt_output-contid.
        ls_item-node_key  = ls_node-node_key.
        ls_item-item_name = 'Column3'.
        ls_item-class     = cl_gui_column_tree=>item_class_text.
        CONCATENATE gt_output-type gt_output-text
                    INTO ls_item-text SEPARATED BY space.
        APPEND ls_item TO et_item.
      ENDIF.
    ENDAT.

    CLEAR: ls_node-relatship, ls_node-n_image, ls_node-exp_image,
           ls_node-expander, ls_node-isfolder.
*--DHORIONS 20130522 : Make sure node keys are unique
*    ls_node-node_key = l_index.
    l_index_c = l_index.
    CONCATENATE 'A_' l_index_c INTO ls_node-node_key .
    CONDENSE ls_node-node_key.
    ls_node-relatkey = l_contid_nodekey.

    APPEND ls_node TO et_node.

    IF NOT gt_output-auditor IS INITIAL.
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.

      READ TABLE gt_auditor WITH KEY contid = gt_output-contid
                                     auditor = gt_output-auditor.
      IF gt_auditor-ma_email = 'X'.
        ls_item-t_image = '@1S@'.

      ENDIF.

      ls_item-item_name = 'Column1'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      IF NOT gt_output-company IS INITIAL.
        CONCATENATE gt_output-auditor '-' gt_output-company
                    INTO ls_item-text SEPARATED BY space.
      ELSE.
        ls_item-text = gt_output-auditor.

      ENDIF.
      APPEND ls_item TO et_item.
    ENDIF.

    IF NOT gt_output-tcode IS INITIAL.
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 'Column2'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      CONCATENATE gt_output-tcode '-' gt_output-tfreq
                  INTO ls_item-text SEPARATED BY space.
      APPEND ls_item TO et_item.
    ENDIF.

    IF NOT gt_output-repid IS INITIAL.
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 'Column3'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      CONCATENATE gt_output-repid '-' gt_output-rfreq
                  INTO ls_item-text SEPARATED BY space.
      APPEND ls_item TO et_item.
    ENDIF.

    IF p_conf = 'X' AND NOT gt_output-conid IS INITIAL.
      CLEAR ls_item.
      ls_item-node_key  = ls_node-node_key.
      ls_item-item_name = 'Column4'.
      ls_item-class     = cl_gui_column_tree=>item_class_text.
      IF NOT gt_output-mitcompany IS INITIAL.
        CONCATENATE gt_output-conid '-' gt_output-vrsio '-'
  gt_output-mitcompany
                    INTO ls_item-text SEPARATED BY space.
      ELSE.
        CONCATENATE gt_output-conid '-' gt_output-vrsio
 INTO ls_item-text SEPARATED BY space.
      ENDIF.
      APPEND ls_item TO et_item.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " build_node_table
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog

*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.
  .

ENDFORM.                    " set_default_sodversion
