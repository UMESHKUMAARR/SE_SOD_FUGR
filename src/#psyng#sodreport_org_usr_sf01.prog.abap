*----------------------------------------------------------------------*
***INCLUDE /PSYNG/Z_SODREPORT_ORG_45_SF01.
*----------------------------------------------------------------------*
CLASS lcl_application DEFINITION.

  PUBLIC SECTION.
    METHODS:
      handle_item_double_click
      FOR EVENT item_double_click
                  OF cl_gui_column_tree
        IMPORTING node_key item_name,
      handle_button_click
      FOR EVENT button_click
                  OF cl_gui_column_tree
        IMPORTING node_key item_name.
  PRIVATE SECTION.
    DATA: item      TYPE mtreeitm,
          node      TYPE treev_node,
          agr_name  TYPE agr_name,
          line(80),
          authfield TYPE xufield,
          iobjct    TYPE xuobject,
          l_value   TYPE xuvalue,
          itcode    TYPE tcode,
          l_conid   TYPE /psyng/conflict_id,
          l_mitid   TYPE /psyng/propcontid,
          l_usrid   TYPE xubname,
          l_ugrp    TYPE xuclass,
          lt_tcodes TYPE TABLE OF /psyng/range_tcode,
          wa_tcodes TYPE /psyng/range_tcode.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS LCL_APPLICATION IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*



DATA: g_application TYPE REF TO lcl_application.
CONTROLS : tree_col TYPE TABLEVIEW USING SCREEN '9004'.
TYPES: BEGIN OF typ_outdet1,      "Table containing SOD details
         class        LIKE usgrpt-usergroup,
         bname        LIKE ust04-bname,     "For appending each user
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,    "details
         description  LIKE /psyng/conflict-description,
         functionid   LIKE /psyng/functtran-functionid,
         agr_name     LIKE agr_prof-agr_name,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         profile      LIKE ust04-profile,
         comp_agr     LIKE agr_agrs-agr_name,
         simu         TYPE c,
         enhanced     TYPE c, "flag for enhanced ruleset
         org_abb      LIKE /psyng/swsodorgm-abb,"Org level reporting
       END OF typ_outdet1.

TYPES: item_table_type LIKE STANDARD TABLE OF mtreeitm
       WITH DEFAULT KEY.
TYPES : BEGIN OF tree_final,      "Table containing SOD tree
          class       LIKE usgrpt-usergroup, "*
          text        LIKE usgrpt-text, " *
          bname       LIKE ust04-bname,
          "for a user and conflict only
          name_text   LIKE adrp-name_text,  "*
          imp         LIKE /psyng/conflict-imp,
          conid       LIKE /psyng/conflict-conid,
          "this is to be used
          description LIKE /psyng/conflict-description,
          functionid  LIKE /psyng/functtran-functionid,   "when a user
          fun_des     LIKE /psyng/function-description,
          tcode       LIKE /psyng/faobj2-tcode, "parent tcode of auth
          ttext       LIKE /psyng/sw_fioria-appname, "tstct-ttext,
          rfcdest     LIKE rfcdes-rfcdest,                "in summary
          rfcdoc1     LIKE rfcdoc-rfcdoc1,
          objct       LIKE ust12-objct,
          obj_des     LIKE tobjt-ttext,
          agr_name    LIKE agr_prof-agr_name,             "double-clicks
          rtext       LIKE agr_texts-text,
          org_abb     LIKE /psyng/swsodorgm-abb,
          auth        LIKE ust12-auth,
          field       LIKE ust12-field,
          von         LIKE ust12-von,
          bis         LIKE ust12-bis,
          profile     LIKE ust04-profile,
          comp_agr    LIKE agr_agrs-agr_name,
          crtext      LIKE agr_texts-text,
          simu        TYPE c,
          enhanced    TYPE c, "flag for enhanced ruleset
          all_user    TYPE i,   " *
          u_ttl_cnf   TYPE i,
          u_hgh_cnt   TYPE i,
          u_mdm_cnt   TYPE i,
          u_low_cnt   TYPE i,
          u_crit_cnt  TYPE i,
          con_enh     TYPE c,
          con_simu    TYPE c,
          mitgn       LIKE /psyng/conflict-contid,
          all_tcd     TYPE i,
          t_enh       TYPE c,
          t_simu      TYPE c,
          o_enh       TYPE c,
          o_simu      TYPE c,
          totl_auth   TYPE i,
        END OF tree_final.
DATA:
  g_custom_container TYPE REF TO cl_gui_custom_container,
  g_tree             TYPE REF TO cl_gui_column_tree,
  go_html            TYPE REF TO cl_gui_html_viewer,
  go_html_cont       TYPE REF TO cl_gui_custom_container,
  g_ok_code          TYPE sy-ucomm,
  g_col_order        TYPE treev_cona,
  g_node_key         TYPE tv_nodekey,
  node_table         TYPE treev_ntab,
  g_item_name        TYPE tv_itmname,
  item_table         TYPE item_table_type,
  ifields            TYPE STANDARD TABLE OF sval WITH HEADER LINE,
  wa_ifields         TYPE  sval,
  BEGIN OF gt_cuscon OCCURS 0,
    conid TYPE /psyng/sw_cuscon-conid,
    funct TYPE /psyng/sw_cuscon-funct,
    cdesc TYPE /psyng/sw_cuscon-cdesc,
    imp   TYPE /psyng/sw_cuscon-imp,
  END OF gt_cuscon,
  wa_gt_cuscon    LIKE gt_cuscon,
  tree_outputdet4 TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
                      WITH HEADER LINE,
  g_wa_tree_1     TYPE tree_final,
  tree_class      TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
      WITH HEADER LINE,
  tree_bname      TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
       WITH HEADER LINE,
  tree_sen        TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
         WITH HEADER LINE,
  tree_confct     TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
      WITH HEADER LINE,
  tree_functn     TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
      WITH HEADER LINE,
  tree_tcd        TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
         WITH HEADER LINE,
  tree_rfcdest    TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
     WITH HEADER LINE,
  tree_objct      TYPE STANDARD TABLE OF tree_final INITIAL SIZE 0
       WITH HEADER LINE,
  item            TYPE mtreeitm,
  prog_indi_mode,
  node_key TYPE tv_nodekey,
  BEGIN OF colitab OCCURS 0,
       col_name TYPE string,
       col_title TYPE string,
       width TYPE i,
     END OF colitab,
     l_copy_node TYPE treev_nks,
     flg_del_column,
     sel,
      g_agrname_dtlclk,
   g_dnld TYPE STANDARD TABLE OF typ_outdet1 INITIAL SIZE 0 WITH
      HEADER LINE,
     g_flg_lst_sel,
     dn_file LIKE  rlgrap-filename VALUE 'c:\temp\sw_sod.csv',
     g_lst_class        LIKE usgrpt-usergroup,
      g_lst_bname        LIKE ust04-bname,
      g_lst_imp          LIKE /psyng/conflict-imp,
      g_lst_conid        LIKE /psyng/conflict-conid,
      g_lst_functionid   LIKE /psyng/functtran-functionid,
      g_lst_tcode        LIKE /psyng/faobj2-tcode,
      g_lst_rfcdest      LIKE rfcdes-rfcdest,
      g_lst_objct        LIKE ust12-objct,
      g_lst_node_key,
      sel_idx LIKE sy-tabix.

CLASS lcl_application IMPLEMENTATION.
  METHOD  handle_item_double_click.
    DATA :
      l_node_key   LIKE g_node_key,
      l_repid      LIKE sy-repid,
      l_hashcode   TYPE xupname,
      l_fioriid    TYPE /psyng/sw_fioriid,
      l_functionid TYPE /psyng/function_id,
      l_tcode      TYPE tcode,
      wa_node1     LIKE LINE OF node_table,
      wa_node2     LIKE LINE OF node_table,
      wa_item1     TYPE mtreeitm,
      l_authfield  TYPE fieldname,
      l_uname      TYPE xubname,
      l_parva      TYPE usr05-parva,
      l_sod        TYPE /psyng/sodvrsio,
      l_parva_exists type sy-subrc.
    CONSTANTS:
      lc_service  TYPE xuobject VALUE 'S_SERVICE',
      lc_srv_name TYPE xufield  VALUE 'SRV_NAME'.



    g_node_key = node_key.
    g_item_name = item_name.
    DATA: answer.
    READ TABLE item_table INTO item WITH KEY node_key = g_node_key
    item_name = g_item_name.
    IF sy-subrc = 0.
*---User
      IF g_node_key+0(1) = 'U' AND g_item_name = 'COL1'.
        SUBMIT  /psyng/se_object_drilldown
        WITH r_user = 'X'
        WITH name = item-text
        AND RETURN.
        EXIT.
*---Conflict Id
      ELSEIF g_node_key+0(1) = 'C' AND g_item_name = 'COL1'.

        l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
        SELECT SINGLE parva INTO l_parva FROM usr05
                   WHERE bname = l_uname
                     AND parid = '/PSYNG/VRSIO'.
        l_parva_exists = sy-subrc.
        IF l_parva_exists = 0 AND l_parva <> space.
          l_sod = l_parva.
        ENDIF.

        PERFORM set_default_sodversion USING sodvrsio l_uname 0.
        SET PARAMETER ID '/PSYNG/CON' FIELD item-text.
        g_dynnr = '0202'.
        EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
*BOC UMITTAL ATC check SIEMENS 11/02/25
*        IF sy-subrc <> 0.
*          MESSAGE e077(s#) WITH '/PSYNG/SE'.
*        ELSE.
*          CALL TRANSACTION '/PSYNG/SE'.
*        ENDIF.
        IF sy-subrc EQ 0.
          CALL TRANSACTION '/PSYNG/SE'.
        ELSE.
          MESSAGE e077(s#) WITH '/PSYNG/SE'.
        ENDIF.
*EOC UMITTAL ATC check SIEMENS 11/02/25
*-- Set back to Default
        PERFORM set_default_sodversion USING l_sod l_uname
        l_parva_exists.
        EXIT.


*---Auth FROM or TO field
      ELSEIF g_node_key+0(1) = 'A' AND
        ( g_item_name = 'BIS' OR
          g_item_name = 'VON' ).
        CHECK item-text <> space.
        l_hashcode = item-text.
        l_node_key = g_node_key. "the child node
        READ TABLE node_table INTO node WITH KEY node_key = g_node_key.
        IF sy-subrc = 0.
          g_node_key = node-relatkey.
        ENDIF.
        g_item_name = 'COL1'.
        CLEAR: iobjct.
        READ TABLE item_table INTO item WITH KEY node_key = g_node_key
        item_name = g_item_name.
        IF sy-subrc = 0.
          iobjct = item-text.
        ENDIF.
        CLEAR authfield.
        g_item_name = 'FIELD'.
        READ TABLE item_table INTO item WITH KEY node_key = l_node_key
        item_name = g_item_name.
        IF sy-subrc = 0.
          authfield = item-text.
        ENDIF.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
        IF  iobjct    EQ lc_service
        AND authfield EQ lc_srv_name.
*--Displays a popup with the name of the Odata Service
          CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
            EXPORTING
              i_hashcode      = l_hashcode
              if_show_message = 'X'
            EXCEPTIONS
              not_found       = 1
              OTHERS          = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          RETURN.
        ELSEIF iobjct = 'S_TCODE' AND authfield = 'TCD'.
*--Transaction
          SUBMIT  /psyng/se_object_drilldown
           WITH r_tcode  = 'X'
           WITH p_object = 'S_TCODE'
           WITH name     = l_hashcode
           AND RETURN.
        ELSE.
*--Other Object
          l_value = l_hashcode.
          CALL FUNCTION '/PSYNG/SW_AUTH_VALUE_TEXT'
            EXPORTING
              i_object        = iobjct
              i_field         = authfield
              i_value         = l_value
              if_show_message = 'X'.
        ENDIF.


*---Function Id
      ELSEIF g_node_key+0(1) = 'F' AND g_item_name = 'COL1'.
        CHECK item-text <> space.
        SELECT description FROM /psyng/function INTO line
                                    WHERE function = item-text
                                    AND   vrsio    = sodvrsio.
        ENDSELECT.
        CHECK sy-subrc = 0.
        CONCATENATE item-text '=' line INTO line
                    SEPARATED BY space.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = text-128
            text_question         = line
            text_button_1         = text-129
            icon_button_1         = 'ICON_SYSTEM_OKAY'
            text_button_2         = text-122
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '1'
            display_cancel_button = ' '.



*---Transaction code
      ELSEIF g_node_key+0(1) = 'T' AND g_item_name = 'COL1'.

        CHECK item-text <> space.
        l_tcode = item-text.
        l_node_key = g_node_key. "the child node
*--Read parent node
        READ TABLE node_table INTO node WITH KEY node_key = g_node_key.
        IF sy-subrc = 0.
          g_node_key = node-relatkey.
        ENDIF.
        g_item_name = 'COL1'.
        CLEAR: l_functionid.
        READ TABLE item_table INTO item WITH KEY node_key = g_node_key
        item_name = g_item_name.
        IF sy-subrc = 0.
          l_functionid = item-text.
        ENDIF.

        SELECT SINGLE fioriid
          FROM /psyng/functtran
          INTO l_fioriid
          WHERE functionid EQ l_functionid
            AND tcode      EQ l_tcode
            AND vrsio      EQ sodvrsio
            AND type       EQ 'F'.
        IF sy-subrc EQ 0.
          CALL FUNCTION '/PSYNG/SW_FIORIAPP_SHOW'
            EXPORTING
              i_fioriid = l_fioriid
            EXCEPTIONS
              not_found = 1
              OTHERS    = 2.
          IF sy-subrc <> 0.
* Implement suitable error handling here
          ENDIF.
          RETURN.
        ENDIF.

        SELECT ttext FROM tstct INTO line
               WHERE sprsl = sy-langu AND tcode = l_tcode.
          EXIT.
        ENDSELECT.
"#EC CI_SUBRC
        CLEAR answer.
        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = item-text
            text_question         = line
            text_button_1         = text-121
            icon_button_1         = 'ICON_EXECUTE_OBJECT'
            text_button_2         = text-122
            icon_button_2         = 'ICON_SYSTEM_CANCEL'
            default_button        = '2'
            display_cancel_button = ' '
          IMPORTING
            answer                = answer.

        CHECK answer = '1'.

        AUTHORITY-CHECK OBJECT 'S_TCODE'
                 ID 'TCD' FIELD item-text.
        IF sy-subrc = 0.
          SELECT SINGLE tcode FROM tstc INTO itcode
            WHERE tcode = item-text .
          IF sy-subrc = 0.
*BOC UMITTAL CVA FIXES 11/03/2026
    CALL METHOD /psyng/sw_dynamic_select=>dynamic_call_txn
      EXPORTING
        i_tcode =  itcode .
*        CALL TRANSACTION itcode."#EC PATHLOCK_CI_DYN_ACCES
*EOC UMITTAL CVA FIXES 11/03/2026


          ELSE.
            MESSAGE s398(00) WITH text-148.
          ENDIF.
        ELSE.
          MESSAGE s398(00) WITH text-085.
        ENDIF.
*---Authorization object
      ELSEIF g_node_key+0(1) = 'O' AND g_item_name = 'COL1'.
        CHECK item-text <> space.
        iobjct = item-text.
        CALL FUNCTION 'SUSR_SHOW_OBJECT'
          EXPORTING
            object  = iobjct
            eu_mode = ' '.
*---Authorization field

      ELSEIF g_node_key+0(1) = 'A' AND g_item_name = 'FIELD'.

        CHECK item-text <> space.
        authfield = item-text.
        l_authfield = authfield.
        CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
          EXPORTING
            fieldname = l_authfield.

*---Role
      ELSEIF g_node_key+0(1) = 'A' AND ( g_item_name = 'ROLE' OR
      g_item_name = 'COM_AGR' ).
        CHECK item-text <> space.
        agr_name = item-text.
*-- find the rfcdest of the role
        READ TABLE node_table INTO wa_node1 WITH KEY node_key =
        g_node_key.
        IF sy-subrc = 0.
          READ TABLE node_table INTO wa_node2
                    WITH KEY node_key = wa_node1-relatkey.
          IF sy-subrc = 0.
            READ TABLE item_table INTO wa_item1
                    WITH KEY node_key = wa_node2-relatkey.
          ENDIF.
        ENDIF.

        SUBMIT /psyng/se_object_drilldown
         WITH r_role = 'X'
         WITH name    = agr_name
         WITH p_rfc   = wa_item1-text
         WITH p_vrsio = sodvrsio
         WITH cfgset  = cfgset
         AND RETURN.
        EXIT.
*---Profile
      ELSEIF g_node_key+0(1) = 'A' AND g_item_name = 'PRO'.
        CHECK item-text <> space.
        AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
*BOC UMITTAL ATC check SIEMENS 11/02/25
*        IF sy-subrc <> 0.
*          MESSAGE e077(s#) WITH 'SU02'.
*        ELSE.
*          SET PARAMETER ID 'XUP' FIELD item-text.
*          CALL TRANSACTION 'SU02'.
*        ENDIF.
        IF sy-subrc EQ 0.
          SET PARAMETER ID 'XUP' FIELD item-text.
          CALL TRANSACTION 'SU02'.
        ELSE.
          MESSAGE e077(s#) WITH 'SU02'.
        ENDIF.
*EOC UMITTAL ATC check SIEMENS 11/02/25
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD  handle_button_click.
* Mitigation Button click
    g_node_key = node_key.
    g_item_name = item_name.
    IF g_node_key+0(1) = 'C' AND g_item_name = 'COL3'.
      READ TABLE item_table INTO item WITH KEY node_key = g_node_key
      item_name = g_item_name.
      IF sy-subrc = 0.
        CLEAR: line.
        SPLIT item-text AT 'MC ID:' INTO line l_mitid.
      ENDIF.
      CLEAR: l_conid.
      g_item_name = 'COL1'.
      READ TABLE item_table INTO item WITH KEY node_key = g_node_key
      item_name = g_item_name.
      IF sy-subrc = 0.
        IF g_node_key+0(1) = 'C'.
          l_conid = item-text.
        ENDIF.
      ENDIF.

      READ TABLE node_table INTO node WITH KEY node_key = g_node_key.
      IF sy-subrc = 0.
        g_node_key = node-relatkey.
      ENDIF.
      READ TABLE node_table INTO node WITH KEY node_key = g_node_key.
      IF sy-subrc = 0.
        g_node_key = node-relatkey.
      ENDIF.
      READ TABLE item_table INTO item WITH KEY node_key = g_node_key
          item_name = g_item_name.
      IF sy-subrc = 0.
        IF g_node_key+0(1) = 'U'.
          l_usrid = item-text.
        ENDIF.
      ENDIF.
      READ TABLE node_table INTO node WITH KEY node_key =
      g_node_key.
      IF sy-subrc = 0.
        g_node_key = node-relatkey.
      ENDIF.
      READ TABLE item_table INTO item WITH KEY node_key = g_node_key
                      item_name = g_item_name.
      IF sy-subrc = 0.
        IF g_node_key+0(1) = 'G'.
          l_ugrp = item-text.
        ENDIF.
      ENDIF.
    ENDIF.

    CALL FUNCTION '/PSYNG/SW_035'
      EXPORTING
        i_vrsio                        = sodvrsio
        i_conid                        = l_conid
        i_contid                       = l_mitid
        i_bname                        = l_usrid
      EXCEPTIONS
        mit_control_id_doesnt_exist    = 1
        conflict_id_doesnt_exist       = 2
        user_id_doesnt_exist           = 3
        mit_not_asin_to_user_and_class = 4
        OTHERS                         = 5.
    IF sy-subrc <> 0.

** For proper information message for user
      PERFORM handle_exceptions USING sy-subrc l_conid l_mitid l_usrid.
    ENDIF.
*********************************************************************
    CLEAR: l_conid,l_mitid,l_usrid,l_ugrp.

  ENDMETHOD.

ENDCLASS.


FORM show_tree_view .
*  MESSAGE i002(/psyng/sw) WITH
*  'Show Tree View - Not Implemented Yet'.
*--Submit current report with the same parameters,
*      but include the historical data
      CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
        EXPORTING
          i_repid           = g_program
          if_no_logging     = 'X'
          if_ignore_initial = ''
        TABLES
          et_params         = lt_params.
      set_param :
        'SHOTREE' 'X'  '' 'P' 'I' 'EQ',
        'SHODET'  ''  '' 'P' 'I' 'EQ',
        'SHOSIMP' ''  '' 'P' 'I' 'EQ'.
      SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(11/12/24)
       WITH SELECTION-TABLE lt_params AND RETURN.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  PBO_9000  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pbo_9000 OUTPUT.
  SET PF-STATUS 'MAIN'.
  SET TITLEBAR 'MAIN'.
  IF g_tree IS INITIAL.
    PERFORM create_and_init_tree.
  ELSE.
    CALL METHOD g_tree->set_column_order
      EXPORTING
        columns           = g_col_order
      EXCEPTIONS
        cntl_system_error = 1
        dp_error          = 2
        failed            = 3
        column_not_found  = 4
        hierarchy_column  = 5
        wrong_column_set  = 6
        OTHERS            = 7.
    IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.


  ENDIF.

  IF go_html IS INITIAL.
    PERFORM init_html.
  ENDIF.
ENDMODULE.
FORM create_and_init_tree.
  DATA: events           TYPE cntl_simple_events,
        event            TYPE cntl_simple_event,
        hierarchy_header TYPE treev_hhdr.


  CREATE OBJECT g_custom_container
    EXPORTING
      container_name              = 'TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.


* setup the hierarchy header
  hierarchy_header-width = 110.
  hierarchy_header-heading = text-t13.

  CREATE OBJECT g_tree
    EXPORTING
      parent                      = g_custom_container
      node_selection_mode         =
      cl_gui_column_tree=>node_sel_mode_single
      item_selection              = 'X'
      hierarchy_column_name       = 'COL1'
      hierarchy_header            = hierarchy_header
    EXCEPTIONS
      cntl_system_error           = 1
      create_error                = 2
      failed                      = 3
      illegal_node_selection_mode = 4
      illegal_column_name         = 5
      lifetime_error              = 6.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.


  CALL METHOD g_tree->insert_hierarchy_column
    EXPORTING
      name                         = 'COL2'
      predecessor_column           = 'COL1'
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      different_column_types       = 4
      cntl_system_error            = 5
      failed                       = 6
      predecessor_column_not_found = 7
      OTHERS                       = 8.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL METHOD g_tree->insert_hierarchy_column
    EXPORTING
      name                         = 'COL3'
      predecessor_column           = 'COL2'
*     HIDDEN                       =
*     DISABLED                     =
    EXCEPTIONS
      column_exists                = 1
      illegal_column_name          = 2
      too_many_columns             = 3
      different_column_types       = 4
      cntl_system_error            = 5
      failed                       = 6
      predecessor_column_not_found = 7
      OTHERS                       = 8.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL METHOD g_tree->set_alignment
    EXPORTING
      alignment = 15.


* define the events which will be passed to the backend

  event-eventid = cl_gui_column_tree=>eventid_item_double_click.
  event-appl_event = 'X'.
  APPEND event TO events.

  event-eventid = cl_gui_column_tree=>eventid_button_click.
  event-appl_event = 'X'.
  APPEND event TO events.

  CALL METHOD g_tree->set_registered_events
    EXPORTING
      events                    = events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

* assign event handlers in the application class to each desired event

  SET HANDLER g_application->handle_item_double_click FOR g_tree.
  SET HANDLER g_application->handle_button_click FOR g_tree.



  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'FIELD'
      width                        = 21
      header_text                  = text-093
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

  IF orgchk = 'X'.
    CALL METHOD g_tree->add_column
      EXPORTING
        name                         = 'AREA'
        width                        = 35
        header_text                  = text-t15
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
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.
  ENDIF.

  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'VON'
      width                        = 15
      header_text                  = text-105
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'BIS'
      width                        = 15
      header_text                  = text-107
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'ROLE'
      width                        = 45
      header_text                  = text-096
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'RTEXT'
      width                        = 41
      header_text                  = text-t20
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.


  IF showcomp = 'X'.
    CALL METHOD g_tree->add_column
      EXPORTING
        name                         = 'COM_AGR'
        width                        = 40
        header_text                  = text-t14
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
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.
    CALL METHOD g_tree->add_column
      EXPORTING
        name                         = 'CRTEXT'
        width                        = 40
        header_text                  = text-t21
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
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.

  ENDIF.

  CALL METHOD g_tree->add_column
    EXPORTING
      name                         = 'PRO'
      width                        = 39
      header_text                  = text-097
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
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.



  IF p_enhanc = 'X'.
    CALL METHOD g_tree->add_column
      EXPORTING
        name                         = 'EHN'
        width                        = 10
        header_text                  = text-158
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
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.
  ENDIF.
  IF bysimu = 'X'.
    CALL METHOD g_tree->add_column
      EXPORTING
        name                         = 'SIMU'
        width                        = 10
        header_text                  = text-t16
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
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.
  ENDIF.

  PERFORM build_node_and_item_table . "USING NODE_TABLE ITEM_TABLE.

  CALL METHOD g_tree->add_nodes_and_items
    EXPORTING
      node_table                     = node_table
      item_table                     = item_table
      item_table_structure_name      = 'MTREEITM'
    EXCEPTIONS
      failed                         = 1
      cntl_system_error              = 3
      error_in_tables                = 4
      dp_error                       = 5
      table_structure_name_not_found = 6.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

  CALL METHOD g_tree->expand_root_nodes
    EXPORTING
      level_count         = 0
*     EXPAND_SUBTREE      = 'X'
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      OTHERS              = 4.
  IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  CALL METHOD g_tree->get_column_order
    CHANGING
      columns           = g_col_order
    EXCEPTIONS
      cntl_system_error = 1
      dp_error          = 2
      failed            = 3
      OTHERS            = 4.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.




ENDFORM.                    " CREATE_AND_INIT_TREE
FORM init_html.
  DATA : lo_doc          TYPE REF TO cl_dd_document,
         lo_table        TYPE REF TO cl_dd_table_element,
         lo_col_key      TYPE REF TO cl_dd_area,
         lo_col_info     TYPE REF TO cl_dd_area,
         lo_col_key2     TYPE REF TO cl_dd_area,
         lo_col_info2    TYPE REF TO cl_dd_area,

         l_userdate      TYPE string,
         l_date(10)      TYPE c,
         lt_uidn         TYPE TABLE OF /psyng/bc_uidn
                     WITH HEADER LINE,
         l_mac_text(255) TYPE c,
         l_user_date     TYPE string,
         l_exedate       TYPE char10,
         l_exetime(8)    TYPE c,
         l_vrsio_txt     TYPE /psyng/desc132,
         l_set_pub       TYPE string,
         l_sumry_info    TYPE string,
         l_set_chg       TYPE /psyng/desc132,
         l_set_txt       TYPE /psyng/desc132,
         ls_cfg_set      TYPE /psyng/swcfgset,
         c_usercount     TYPE string,
         c_averagecon    TYPE string,
         c_tusercount    TYPE string,
         l_usercount     TYPE i,
         l_averagecon    TYPE i,
         l_conflictcount TYPE i,
         l_conusr        TYPE string,
         l_systemid       TYPE /psyng/sysid, "Odubey
*BOC:HBHALLA
         lf_tot_confsc(8) TYPE c,   "total conflicts in char
         lf_tot_mitsc(8)  TYPE c,    "total mitigations in char
         alv_grid_titl2   TYPE lvc_title.
*EOC:HBHALLA
*  FIELD-SYMBOLS : <det> LIKE outputdet4.
  RANGES r_bname FOR sy-uname.
* Create a container for the tree control
  CREATE OBJECT go_html_cont
    EXPORTING
      container_name              = 'HTML_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
  ENDIF.

  CREATE OBJECT go_html
    EXPORTING
      parent = go_html_cont.

  CREATE OBJECT lo_doc
    EXPORTING
      style = 'ALV_GRID'.

  DEFINE add_header_line.
    l_mac_text = &1.
    condense l_mac_text.
    call method lo_col_key->add_text
          exporting text  = l_mac_text
          sap_emphasis = 'STRONG'.  "#EC SAST_CI_GEN_CHECK
    call method lo_col_key->new_line.
    call method lo_col_info->add_gap exporting width  = 6.
    l_mac_text = &2.
    call method lo_col_info->add_text exporting text  = l_mac_text.
    call method lo_col_info->new_line.
    l_mac_text = &3.
    call method lo_col_key2->add_gap exporting width  = 6.

    call method lo_col_key2->add_text exporting text  = l_mac_text
                                         sap_emphasis = 'STRONG'.
    call method lo_col_key2->new_line.
    call method lo_col_info2->add_gap exporting width  = 6.
    l_mac_text = &4.
    call method lo_col_info2->add_text exporting text  = l_mac_text.
    call method lo_col_info2->new_line.


  END-OF-DEFINITION.

*---alv header information
  r_bname-sign = 'I'.
  r_bname-option = 'EQ'.
  r_bname-low = g_current_user. "sy-uname. C0700
  COLLECT r_bname.
  CALL FUNCTION '/PSYNG/BC_011'
    TABLES
      it_bname = r_bname
      et_uidn  = lt_uidn.
  READ TABLE lt_uidn INDEX 1.
*  CONCATENATE  sy-uname '(' lt_uidn-name_text ')' "C0700
  CONCATENATE  g_current_user '(' lt_uidn-name_text ')' "C0700
               'on' l_date
               INTO l_userdate  SEPARATED BY space.
  CLEAR l_date.

  CALL METHOD lo_doc->add_table
    EXPORTING
      no_of_columns = 4
      with_heading  = ' '
      border        = '0'
    IMPORTING
      table         = lo_table.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_key.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_info.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_key2.
  CALL METHOD lo_table->add_column IMPORTING column = lo_col_info2.
*--Get version title
  SELECT SINGLE vdesc INTO l_vrsio_txt FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
   IF sy-subrc = 0.
  CONCATENATE sodvrsio ':' l_vrsio_txt INTO l_vrsio_txt
              SEPARATED BY space.
   ENDIF.
**--Get Set info
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid =  cfgset.
"#EC CI_SUBRC
    IF ls_cfg_set-published = 'X'.
      l_set_pub = 'Yes'(h34).
    ELSE.
      l_set_pub = 'No'(h35).
    ENDIF.

    l_mac_text = cfgset.
    SHIFT l_mac_text LEFT DELETING LEADING '0'.
    CONDENSE l_mac_text.
    CONCATENATE l_mac_text ':'
    ls_cfg_set-description
    INTO l_set_txt
    SEPARATED BY space.
*
    WRITE ls_cfg_set-change_date TO l_set_chg.
    CONCATENATE l_set_chg 'by'(h37) ls_cfg_set-change_user
    INTO l_set_chg SEPARATED BY space.
*
  ENDIF.
*--date
  WRITE sy-datum TO l_exedate.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
*  CONCATENATE sy-uname 'on'(h11) l_exedate l_exetime "C0700

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 Odubey

  CONCATENATE g_current_user 'on'(h11) l_exedate l_exetime "C0700
 'in' l_systemid  INTO l_user_date SEPARATED BY space.


*---summary
*  SORT outputdet4 BY bname conid.
*  lt_users[] = outputdet4[].
*  DELETE ADJACENT DUPLICATES FROM lt_users COMPARING bname.
*  DESCRIBE TABLE lt_users LINES tusercount.

*  LOOP AT outputdet4 ASSIGNING <det>.
*    CONCATENATE <det>-bname <det>-conid INTO l_conusr.
*    AT NEW bname.
*      ADD 1 TO l_usercount.
*    ENDAT.
*    ON CHANGE OF l_conusr.
*      ADD 1 TO l_conflictcount.
*    ENDON.
*  ENDLOOP.
  IF g_usercount > 0.
    l_averagecon   = g_concount / g_usercount.
  ENDIF.
  c_usercount  = g_usercount.
  c_averagecon = l_averagecon.
  c_tusercount = g_totalusercount.
  CONCATENATE  c_tusercount 'User(s) analyzed. Avg'(h16) c_averagecon
               'SOD Conflict(s) in '(h17) c_usercount 'user(s)'(h18)
              INTO l_sumry_info SEPARATED BY space.
  CONDENSE l_sumry_info.

*BOC:HBHALLA
  WRITE g_concount TO lf_tot_confsc.
  WRITE g_mitconcount TO lf_tot_mitsc.

  CONCATENATE lf_tot_confsc text-094 lf_tot_mitsc text-095
              INTO alv_grid_titl2 SEPARATED BY space.
*EOC:HBHALLA

*--add info
  add_header_line :
    'SOD Version:'          l_vrsio_txt
    ''       ''.
  IF gf_cfg_set_enabled = 'X'.
    add_header_line :
    'Configuration Set:'    l_set_txt
     ''            '',
     'Config Set Published:' l_set_pub
     ''                      '',
     'Config Set Changed:'   l_set_chg
     ''                      ''.
  ENDIF.
  add_header_line :
  'User Date & System'          l_user_date
   ''                 '',
   'Summary:'   l_sumry_info
   ''                      ''.
*BOC:HBHALLA
  IF xmc = 'X'.
   add_header_line :
  'Mitigation Summary:'          alv_grid_titl2
   ''                 ''.
  ENDIF.
*EOC:HBHALLA

*--display header info
  CALL METHOD lo_doc->merge_document.
  lo_doc->html_control = go_html.
  CALL METHOD lo_doc->display_document
    EXPORTING
      reuse_control      = 'X'
      parent             = go_html_cont
    EXCEPTIONS
      html_display_error = 1.

ENDFORM.                    " init_html
FORM build_node_and_item_table .
  REFRESH : item_table,node_table.
  DATA: l_gp_key   TYPE treev_node-node_key,
        l_un_key   TYPE treev_node-node_key,
        l_imp_key  TYPE treev_node-node_key,
        l_con_key  TYPE treev_node-node_key,
        l_fun_key  TYPE treev_node-node_key,
        l_tcd_key  TYPE treev_node-node_key,
        l_rfc_key  TYPE treev_node-node_key,
        l_obj_key  TYPE treev_node-node_key,
        l_auth_key TYPE treev_node-node_key,
        l_sen_h    TYPE i,
        l_sen_m    TYPE i,
        l_sen_l    TYPE i,
        l_sen_c    TYPE i.


  DATA: l_usr_idx LIKE sy-tabix VALUE 1,
        l_imp_idx LIKE sy-tabix VALUE 1,
        l_con_idx LIKE sy-tabix VALUE 1,
        l_fun_idx LIKE sy-tabix VALUE 1,
        l_tcd_idx LIKE sy-tabix VALUE 1,
        l_rfc_idx LIKE sy-tabix VALUE 1,
        l_obj_idx LIKE sy-tabix VALUE 1,
        l_aut_idx LIKE sy-tabix VALUE 1.


  LOOP AT tree_class .
    g_wa_tree_1 = tree_class.
    PERFORM add_group_node USING    g_wa_tree_1
                                         ''
                                CHANGING l_gp_key.

    LOOP AT tree_bname FROM l_usr_idx .
      IF  tree_bname-class <> tree_class-class.
        l_usr_idx = sy-tabix.
        EXIT.
      ELSE.
        g_wa_tree_1 = tree_bname.
        PERFORM add_user_node  USING       g_wa_tree_1
                                           l_gp_key
                               CHANGING l_un_key l_sen_h
                                        l_sen_m l_sen_l l_sen_c .
      ENDIF.
      LOOP AT tree_sen FROM l_imp_idx .
        IF ( tree_sen-class <> tree_class-class
          OR tree_sen-bname <> tree_bname-bname ).
          l_imp_idx = sy-tabix.
          EXIT.
        ELSE.
          g_wa_tree_1 = tree_sen.
          g_wa_tree_1-U_TTL_CNF = tree_bname-U_TTL_CNF.
          PERFORM add_sens_node  USING  g_wa_tree_1  l_un_key
                                        l_sen_h l_sen_m l_sen_l l_sen_c
                                      CHANGING l_imp_key.
        ENDIF.


        LOOP AT tree_confct FROM l_con_idx.
          IF  ( tree_confct-class <> tree_class-class
              OR tree_confct-bname <> tree_bname-bname
              OR tree_confct-imp <> tree_sen-imp ).
            l_con_idx = sy-tabix.
            EXIT.
          ELSE.
            g_wa_tree_1 = tree_confct.
            PERFORM add_conid_node  USING g_wa_tree_1
                                          l_imp_key
                                     CHANGING l_con_key.
          ENDIF.
          LOOP AT tree_functn FROM l_fun_idx.
            IF ( tree_functn-class <> tree_class-class
            OR tree_functn-bname <> tree_bname-bname
            OR tree_functn-imp <> tree_sen-imp
            OR tree_functn-conid <> tree_confct-conid ).
              l_fun_idx = sy-tabix.
              EXIT.
            ELSE.
              g_wa_tree_1 = tree_functn.
              PERFORM add_fun_node  USING g_wa_tree_1
                                    l_con_key
                               CHANGING l_fun_key.
            ENDIF.
            LOOP AT tree_tcd FROM l_tcd_idx.
              IF ( tree_tcd-class <> tree_class-class
                OR tree_tcd-bname <> tree_bname-bname
                OR tree_tcd-imp <> tree_sen-imp
                OR tree_tcd-conid <> tree_confct-conid
                OR  tree_tcd-functionid <> tree_functn-functionid ).
                l_tcd_idx = sy-tabix.
                EXIT.
              ELSE.

                g_wa_tree_1 = tree_tcd.
                PERFORM add_tcd_node  USING g_wa_tree_1
                                       l_fun_key
                                  CHANGING l_tcd_key.
              ENDIF.


              LOOP AT tree_rfcdest FROM l_rfc_idx.
                IF ( tree_rfcdest-class <> tree_class-class
                   OR tree_rfcdest-bname <> tree_bname-bname
                   OR tree_rfcdest-imp <> tree_sen-imp
                   OR tree_rfcdest-conid <> tree_confct-conid
                   OR tree_rfcdest-functionid <> tree_functn-functionid
                   OR tree_rfcdest-tcode <> tree_tcd-tcode ).
                  l_rfc_idx = sy-tabix.
                  EXIT.
                ELSE.

                  g_wa_tree_1 = tree_rfcdest.
                  PERFORM add_rfc_node  USING g_wa_tree_1
                                         l_tcd_key
                                    CHANGING l_rfc_key.
                ENDIF.
                LOOP AT tree_objct FROM l_obj_idx.
                  IF ( tree_objct-class <> tree_class-class
                    OR tree_objct-bname <> tree_bname-bname
                    OR tree_objct-imp <> tree_sen-imp
                    OR tree_objct-conid <> tree_confct-conid
                    OR tree_objct-functionid <> tree_functn-functionid
                    OR tree_objct-tcode <> tree_tcd-tcode
                    OR tree_objct-rfcdest <> tree_rfcdest-rfcdest ).

                    l_obj_idx = sy-tabix.
                    EXIT.
                  ELSE.


                    g_wa_tree_1 = tree_objct .
                    PERFORM add_obj_node  USING g_wa_tree_1
                                           l_rfc_key
                                      CHANGING l_obj_key.
                  ENDIF.
                  LOOP AT tree_outputdet4 FROM l_aut_idx .
                    IF ( tree_outputdet4-class <> tree_class-class
                    OR tree_outputdet4-bname <> tree_bname-bname
                    OR tree_outputdet4-imp <> tree_sen-imp
                    OR tree_outputdet4-conid <> tree_confct-conid
                 OR tree_outputdet4-functionid <> tree_functn-functionid
                    OR tree_outputdet4-tcode <> tree_tcd-tcode
                    OR tree_outputdet4-rfcdest <> tree_rfcdest-rfcdest
                    OR tree_outputdet4-objct <> tree_objct-objct ).
                      l_aut_idx = sy-tabix.
                      EXIT.
                    ELSE.

                      g_wa_tree_1 = tree_outputdet4.
                      PERFORM add_auth_node  USING g_wa_tree_1
                                            l_obj_key
                                       CHANGING l_auth_key.
                    ENDIF.

                  ENDLOOP.
                ENDLOOP.
              ENDLOOP.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " BUILD_NODE_AND_ITEM_TABLE
FORM add_auth_node USING    ps_auth     TYPE tree_final
                            p_relat_key TYPE treev_node-node_key
                   CHANGING p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm.

*Populate node table
  STATICS : l_n_aut(10) TYPE n.
  CONCATENATE 'A' l_n_aut INTO p_node_key.
  l_n_aut = l_n_aut + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  APPEND l_node TO node_table.

*Populate item table
  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-auth.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'ROLE'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-agr_name.
  APPEND l_item TO item_table.

  IF orgchk = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'AREA'.
    l_item-class = cl_gui_column_tree=>item_class_text.
    l_item-text = ps_auth-org_abb.
    APPEND l_item TO item_table.
  ENDIF.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'RTEXT'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-rtext.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'FIELD'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-field.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'VON'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-von.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'BIS'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-bis.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'PRO'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_auth-profile.
  APPEND l_item TO item_table.
  IF showcomp = 'X'.
    CLEAR item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'COM_AGR'.
    l_item-class = cl_gui_column_tree=>item_class_text.
    l_item-text = ps_auth-comp_agr.
    APPEND l_item TO item_table.

    CLEAR item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'CRTEXT'.
    l_item-class = cl_gui_column_tree=>item_class_text.
    l_item-text = ps_auth-crtext.
    APPEND l_item TO item_table.

  ENDIF.
  IF p_enhanc = 'X'.
    CLEAR item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'EHN'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    IF ps_auth-enhanced = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.
  IF bysimu = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'SIMU'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    IF ps_auth-simu = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.

ENDFORM.                    " ADD_AUTH_NODE
FORM add_conid_node USING     ps_conid    TYPE tree_final

                              p_relat_key TYPE treev_node-node_key
                    CHANGING  p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm,
        l_text TYPE string.
*Populate node table
  STATICS : l_n_con(10) TYPE n.
  CONCATENATE 'C' l_n_con INTO p_node_key.
  l_n_con = l_n_con + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate item table
  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  IF ps_conid-con_enh = 'X'.
    l_item-style = cl_gui_column_tree=>style_intensifd_critical.
  ELSE.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
  ENDIF.

  l_item-text = ps_conid-conid.
  APPEND l_item TO item_table.

  CLEAR item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL2'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_negative.
  l_item-text = ps_conid-description.
  APPEND l_item TO item_table.

  IF xmc = 'X' AND ps_conid-mitgn <> ' '.
    CONCATENATE   text-t19 ps_conid-mitgn  INTO l_text.
    CLEAR item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'COL3'.
    l_item-class = cl_gui_column_tree=>item_class_button.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
    l_item-text = l_text.
    APPEND l_item TO item_table.
  ENDIF.
  IF p_enhanc = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'EHN'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
    IF ps_conid-con_enh = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.

  IF bysimu = 'X'.
    CLEAR item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'SIMU'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
    IF ps_conid-con_simu = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.

ENDFORM.                    " ADD_CONID_NODE
FORM add_fun_node USING     ps_funid    TYPE tree_final
                            p_relat_key TYPE treev_node-node_key
                  CHANGING  p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm,
        l_text TYPE string.
*Populate node table
  STATICS : l_n_fun(10) TYPE n.
  CONCATENATE 'F' l_n_fun INTO p_node_key.
  l_n_fun = l_n_fun + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate Item table
  l_text = ps_funid-all_tcd.
  CONCATENATE  '(' l_text text-t11 ')' INTO l_text.
  CLEAR item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_positive.
  l_item-text = ps_funid-functionid.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL2'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_positive.
  l_item-text = ps_funid-fun_des.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL3'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_positive.
  l_item-text = l_text.
  APPEND l_item TO item_table.

ENDFORM.                    " ADD_FUN_NODE
FORM add_group_node USING     ps_group    TYPE tree_final
                              p_relat_key TYPE treev_node-node_key
                    CHANGING  p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm,
        l_text TYPE string.
*Populate Node table
  STATICS : l_n_grp(10) TYPE n.
  CONCATENATE 'G' l_n_grp INTO p_node_key.
  l_n_grp = l_n_grp + 1.
  l_node-node_key = p_node_key.
  CLEAR l_node-relatkey.
  CLEAR l_node-relatship.

  l_node-hidden = ' '.
  l_node-disabled = ' '.
  l_node-isfolder = 'X'.
  CLEAR l_node-n_image.

  CLEAR l_node-exp_image.
  CLEAR l_node-expander.
  APPEND l_node TO node_table.
*Populate Item table
  l_text = ps_group-all_user.
  CONCATENATE  '(' l_text text-t02  INTO l_text .
  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL1'.
  item-class = cl_gui_column_tree=>item_class_text.
  IF ps_group-class = ' '.
    item-text = ' <No User Group> '(168).
  ELSE.
    item-text = ps_group-class.
  ENDIF.
  APPEND item TO item_table.

  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL2'.
  item-class = cl_gui_column_tree=>item_class_text.


  IF ps_group-text = ' '.
    item-text = ' <No user group text>'(169).
  ELSE.
    item-text = ps_group-text.
  ENDIF.
  APPEND item TO item_table.

  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL3'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-text = l_text.
  APPEND item TO item_table.




ENDFORM.                    " add_GROUP_node
FORM add_obj_node USING    ps_obj TYPE tree_final
                           p_relat_key TYPE treev_node-node_key
                  CHANGING p_node_key TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm,
        l_text TYPE string.
*Populate node table
  STATICS : l_n_obj(10) TYPE n.
  CONCATENATE 'O' l_n_obj INTO p_node_key.
  l_n_obj = l_n_obj + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate item table

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_negative.
  l_item-text = ps_obj-objct.
  APPEND l_item TO item_table.

  CLEAR l_item.

  l_item-node_key = p_node_key.
  l_item-item_name = 'COL2'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_negative.
  l_item-text = ps_obj-obj_des.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_text = ps_obj-totl_auth .
  CONCATENATE '(' l_text text-t12   ')'   INTO l_text.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL3'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized_negative.
  l_item-text = l_text.
  APPEND l_item TO item_table.

  IF p_enhanc = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'EHN'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
    IF ps_obj-o_enh = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.


  IF bysimu = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'SIMU'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized_negative.
    IF ps_obj-o_simu = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.
ENDFORM.                    " ADD_OBJ_NODE
FORM add_rfc_node USING    ps_rfc      TYPE tree_final
                           p_relat_key TYPE treev_node-node_key
                  CHANGING p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm.
*Populate node table
  STATICS : l_n_rfc(10) TYPE n.
  CONCATENATE 'R' l_n_rfc INTO p_node_key.
  l_n_rfc = l_n_rfc + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate item table
  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-usebgcolor = 'X'.
  l_item-text = ps_rfc-rfcdest.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL2'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-text = ps_rfc-rfcdest.
  APPEND l_item TO item_table.
*
ENDFORM.                    " ADD_RFC_NODE
FORM add_sens_node USING    ps_sens     TYPE tree_final
                            p_relat_key TYPE treev_node-node_key
                            p_sen_h     TYPE i
                            p_sen_m     TYPE i
                            p_sen_l     TYPE i
                            p_sen_c     TYPE i
                   CHANGING p_node_key  TYPE treev_node-node_key.
  DATA: l_node  TYPE treev_node,
        l_item  TYPE mtreeitm,
        l_text  TYPE string,
        l_text1 TYPE string,
        l_no_sens type i.
*Populate node table
  STATICS : l_n_sen(10) TYPE n.
  CONCATENATE 'S' l_n_sen INTO p_node_key.
  l_n_sen = l_n_sen + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate Item table
  IF ps_sens-imp = 'HIGH'.
    l_text = p_sen_h.
    l_text1 = text-t08.
  ELSEIF ps_sens-imp = 'MEDIUM'.
    l_text = p_sen_m.
    l_text1 = text-t09.
  ELSEIF ps_sens-imp = 'LOW'.
    l_text = p_sen_l.
    l_text1 = text-t10.
  ELSEIF ps_sens-imp = 'CRITICAL'.
    l_text = p_sen_c.
    l_text1 = text-t27.
   ELSE.
    l_no_sens = ps_Sens-U_TTL_CNF - p_sen_h - p_sen_m - p_sen_l -
    p_sen_c.
    l_text  = l_no_sens.
    l_text1 = 'Undefined'(t28).
  ENDIF.
  CONCATENATE  l_text1 '(' l_text text-t07 ')' INTO l_text.
  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL1'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-text = ps_sens-imp.
  APPEND item TO item_table.

  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL2'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-text = l_text.
  APPEND item TO item_table.


ENDFORM.                    " ADD_SENS_NODE
FORM add_tcd_node USING    ps_tcode    TYPE tree_final
                           p_relat_key TYPE treev_node-node_key
                  CHANGING p_node_key  TYPE treev_node-node_key.

  DATA: l_node TYPE treev_node,
        l_item TYPE mtreeitm.
*Populate node table
  STATICS : l_n_tcd(10) TYPE n.
  CONCATENATE 'T' l_n_tcd INTO p_node_key.
  l_n_tcd = l_n_tcd + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate Item table
  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL1'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  IF ps_tcode-t_enh = 'X'.
    l_item-style = cl_gui_column_tree=>style_intensifd_critical.
  ELSE.
    l_item-style = cl_gui_column_tree=>style_emphasized.
  ENDIF.
  l_item-text = ps_tcode-tcode.
  APPEND l_item TO item_table.

  CLEAR l_item.
  l_item-node_key = p_node_key.
  l_item-item_name = 'COL2'.
  l_item-class = cl_gui_column_tree=>item_class_text.
  l_item-style = cl_gui_column_tree=>style_emphasized.
  l_item-text =  ps_tcode-ttext.
  APPEND l_item TO item_table.


  IF p_enhanc = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'EHN'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized.
    IF ps_tcode-t_enh = 'X'.
      l_item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.

  IF bysimu = 'X'.
    CLEAR l_item.
    l_item-node_key = p_node_key.
    l_item-item_name = 'SIMU'.
    l_item-class = cl_gui_column_tree=>item_class_checkbox.
    l_item-style = cl_gui_column_tree=>style_emphasized.
    IF ps_tcode-t_simu = 'X'.
      item-chosen = 'X'.
    ENDIF.
    APPEND l_item TO item_table.
  ENDIF.

ENDFORM.                    " ADD_TCD_NODE
FORM add_user_node USING     ps_user      TYPE tree_final
                             p_relat_key  TYPE treev_node-node_key
                   CHANGING  p_node_key   TYPE treev_node-node_key
                             p_sen_h      TYPE i
                             p_sen_m      TYPE i
                             p_sen_l      TYPE i
                             p_sen_c      TYPE i.
  DATA: l_node   TYPE treev_node,
        l_item   TYPE mtreeitm,
        l_text   TYPE string,
        l_text_h TYPE string,
        l_text_m TYPE string,
        l_text_l TYPE string,
        l_text_c TYPE string.
*Populate node table
  STATICS : l_n_usr(10) TYPE n.
  CONCATENATE 'U' l_n_usr INTO p_node_key.
  l_n_usr = l_n_usr + 1.

  CLEAR l_node.
  l_node-node_key = p_node_key.
  l_node-relatkey = p_relat_key.
  l_node-relatship = cl_gui_column_tree=>relat_last_child.
  l_node-isfolder = 'X'.
  APPEND l_node TO node_table.

*Populate Item table

  l_text = ps_user-u_ttl_cnf.
  IF ps_user-u_hgh_cnt > 0.
    p_sen_h = ps_user-u_hgh_cnt.
    l_text_h = ps_user-u_hgh_cnt.
    CONCATENATE ',' l_text_h text-t08 INTO l_text_h.
  ENDIF.
  IF ps_user-u_mdm_cnt > 0.
    p_sen_m = ps_user-u_mdm_cnt.
    l_text_m = ps_user-u_mdm_cnt.
    CONCATENATE ',' l_text_m text-t09 INTO l_text_m.
  ENDIF.
  IF ps_user-u_low_cnt > 0.
    p_sen_l = ps_user-u_low_cnt.
    l_text_l = ps_user-u_low_cnt.
    CONCATENATE ',' l_text_l text-t10 INTO l_text_l.
  ENDIF.
  IF ps_user-u_crit_cnt > 0.
    p_sen_c = ps_user-u_crit_cnt.
    l_text_c = ps_user-u_crit_cnt.
    CONCATENATE ',' l_text_c text-t27 INTO l_text_c.
  ENDIF.

  CONCATENATE  '(' l_text text-t07 l_text_c l_text_h l_text_m l_text_l
  ')'
                                                            INTO l_text.

  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL1'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-style = cl_gui_column_tree=>style_emphasized.
  item-text = ps_user-bname.
  APPEND item TO item_table.


  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL2'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-style = cl_gui_column_tree=>style_emphasized.
  item-text = ps_user-name_text.
  APPEND item TO item_table.


  CLEAR item.
  item-node_key = p_node_key.
  item-item_name = 'COL3'.
  item-class = cl_gui_column_tree=>item_class_text.
  item-style = cl_gui_column_tree=>style_emphasized.
  item-text = l_text.
  APPEND item TO item_table.
ENDFORM.                    " ADD_USER_NODE

FORM handle_exceptions USING    p_sy_subrc
                                p_l_conid
                                p_l_mitid
                                p_lusrid.


  CASE p_sy_subrc.

    WHEN 1.
      MESSAGE i157(/psyng/sw) WITH text-029 p_l_mitid.
    WHEN 2.
      MESSAGE i158(/psyng/sw) WITH text-029  p_l_conid.
    WHEN 3 .
      MESSAGE i063(/psyng/basis) WITH text-029 p_lusrid.
    WHEN 4.
      MESSAGE i159(/psyng/sw) WITH text-029  p_l_mitid.
  ENDCASE.


ENDFORM.
FORM output_using_alv_tree.
  REFRESH : tree_class ,tree_bname ,tree_sen ,
            tree_confct,tree_functn ,tree_tcd ,tree_rfcdest,
            tree_objct,tree_outputdet4.
  CLEAR :tree_class ,tree_bname ,tree_sen ,tree_confct,
          tree_functn ,tree_tcd ,tree_rfcdest,tree_objct.
  TYPES: BEGIN OF ls_usr_grp,
         class LIKE usgrpt-usergroup,
         text LIKE  usgrpt-text,
         END OF ls_usr_grp.
  TYPES: BEGIN OF ls_tcode_dtl,
         tcode TYPE tstct-tcode,
         ttext TYPE tstct-ttext,
         END OF ls_tcode_dtl.
  TYPES: BEGIN OF ls_rfc_dtls,
         rfcdest TYPE rfcdoc-rfcdest,
         rfcdoc1 TYPE rfcdoc-rfcdoc1,
         END OF ls_rfc_dtls.
  TYPES : BEGIN OF ls_obj_dtl,
          object LIKE tobjt-object,
          ttext LIKE  tobjt-ttext,
          END OF ls_obj_dtl.
  TYPES : BEGIN OF ls_func_dtl,
          function LIKE /psyng/function-function,
          description LIKE /psyng/function-description,
          END OF ls_func_dtl.
  TYPES : BEGIN OF ls_rol_dtl,
          agr_name LIKE agr_define-agr_name,
          rtext LIKE agr_texts-text,
          END OF ls_rol_dtl.
 DATA: lt_usr_grp_dtls TYPE STANDARD TABLE OF ls_usr_grp INITIAL SIZE 0,
       lt_tcode_dtls TYPE STANDARD TABLE OF ls_tcode_dtl INITIAL SIZE 0,
          lt_rfc_dtls TYPE STANDARD TABLE OF ls_rfc_dtls INITIAL SIZE 0,
           lt_obj_dtls TYPE STANDARD TABLE OF ls_obj_dtl INITIAL SIZE 0,
           lt_role_dtl TYPE STANDARD TABLE OF ls_rol_dtl INITIAL SIZE 0,
          lt_fun_dtls TYPE STANDARD TABLE OF ls_func_dtl INITIAL SIZE 0.

  DATA: l_wa_urgup_detl TYPE ls_usr_grp,
        l_wa_tcode_detl TYPE ls_tcode_dtl,
        l_wa_rfc_detl TYPE ls_rfc_dtls,
        l_wa_obj_dtl TYPE ls_obj_dtl,
        l_wa_fun_dtl TYPE ls_func_dtl,
        l_wa_rol_dtl TYPE ls_rol_dtl.
  DATA: l_usr_cnt TYPE i,
        l_t_conid TYPE i,
        l_hgh_cnt TYPE i,
        l_mdm_cnt TYPE i,
        l_low_cnt TYPE i,
        l_crit_cnt TYPE i,
        l_tcd_cnt TYPE i,
        l_auth_cnt TYPE i,
        l_conf_enh TYPE c,
        l_conf_sim TYPE c,
        l_tcod_enh TYPE c,
        l_tcod_sim TYPE c,
        l_objt_enh TYPE c,
        l_objt_sim TYPE c,
        oldbname      TYPE usr02-bname,
        usercount TYPE i,
        averagecon    TYPE i,
        alv_grid_titl   TYPE lvc_title,
        conflictcount TYPE i,
        tusercount    TYPE i..

*temporary tables to store unique :
*- user groups
*- tcodes
*- RFC destinations
*- auth objects
*- functions
*- roles
  DATA : lt_class TYPE SORTED TABLE OF usgrpt WITH UNIQUE KEY usergroup
         WITH HEADER LINE,
         lt_tcode TYPE SORTED TABLE OF tstct WITH UNIQUE KEY tcode
         WITH HEADER LINE,
         lt_rfcdests TYPE SORTED TABLE OF rfcdoc WITH UNIQUE KEY rfcdest
         WITH HEADER LINE,
         lt_objt TYPE SORTED TABLE OF tobjt WITH UNIQUE KEY object
         WITH HEADER LINE,
         lt_function TYPE SORTED TABLE OF /psyng/function
         WITH UNIQUE KEY function       WITH HEADER LINE,
         lt_role TYPE SORTED TABLE OF agr_texts WITH UNIQUE KEY agr_name
         WITH HEADER LINE.

  DATA:    l_fm_read_roles(32) VALUE '/PSYNG/SW_CR_READ_ROLES_EN',
           l_tab_rolid(16) VALUE '/PSYNG/EX_ROLHDR',
           ls_rolehdr TYPE  /psyng/ex_rolhdr_st,
           ls_rolid TYPE /psyng/ex_rolhdr_st.
TYPES: BEGIN OF ty_functtran,
         functionid TYPE /psyng/function_id,
         tcode      TYPE tcode,
         fioriid    TYPE /psyng/sw_fioriid,
         appname    TYPE /psyng/sw_fioriname,
       END OF   ty_functtran,

       BEGIN OF ty_fioria,
         fioriid TYPE /psyng/sw_fioriid,
         appname TYPE /psyng/sw_fioriname,
       END OF   ty_fioria.

  DATA: lt_functtran_src TYPE TABLE OF ty_functtran,
        lt_functtran     TYPE TABLE OF ty_functtran,
        ls_functtran     TYPE ty_functtran,
        lt_fioria        TYPE TABLE OF ty_fioria,
        ls_fioria        TYPE ty_fioria,
        l_appl           TYPE /psyng/application.
  FIELD-SYMBOLS: <fs_functtran> TYPE ty_functtran.

  CLEAR: oldbname, usercount, averagecon,
       alv_grid_titl, conflictcount.
   sort totalusers2 by bname.
*  DESCRIBE TABLE totalusers2 LINES tusercount.
*  DATA : lt_out LIKE TABLE OF outputdet4 WITH HEADER LINE.
*  lt_out[] = outputdet4[].
*  SORT lt_out BY bname conid.
*  DELETE ADJACENT DUPLICATES FROM lt_out COMPARING bname conid.
*  LOOP AT lt_out.
*    AT NEW bname.
*      CHECK lt_out-conid <> '----'.
*      usercount = usercount + 1.
*    ENDAT.
*    CHECK lt_out-conid <> '----'.
*    ADD 1 TO conflictcount.
*  ENDLOOP.
*  FREE : lt_out.
*
*  averagecon   = conflictcount / usercount.
*  c_usercount  = usercount.
*  c_averagecon = averagecon.
*  c_tusercount = tusercount.
*  CONCATENATE c_usercount text-135
*              text-136 c_averagecon text-137
*              c_usercount text-138
*              INTO g_summ SEPARATED BY space.
*  CONDENSE g_summ.
*
*
*  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
*              INTO g_user.
*  CONCATENATE text-140 sy-uname text-141 g_user
*              INTO g_user SEPARATED BY space.
*  CONCATENATE text-142 g_summ INTO g_summ SEPARATED BY space.
  loop at <gt_output> assigning <gs_output>.
*  LOOP AT outputdet4.
    clear tree_outputdet4.
    MOVE-CORRESPONDING  <gs_output> TO tree_outputdet4.
    get_dyn_value 'APPLICATION' <gs_output> l_appl .
    IF l_appl <> 'SAP'.

*Begin of Addition:HBHALLA(PN-18711)(02/04/26)
    SELECT SINGLE rolid FROM (l_tab_rolid)
      INTO ls_rolehdr-rolid
      WHERE appl = l_appl
       AND  sysid = tree_outputdet4-rfcdest
       AND  rdesc = tree_outputdet4-agr_name.

*      ls_rolehdr-rolid = tree_outputdet4-agr_name.
*End of Addition:HBHALLA(PN-18711)(02/04/26)
      ls_rolehdr-appl  = l_appl.
      ls_rolehdr-sysid = tree_outputdet4-rfcdest.

      CALL FUNCTION l_fm_read_roles  "#EC PATHLOCK_CI_DYN_ACCES
           EXPORTING
                i_rolid                   = ls_rolehdr-rolid
                i_appl                    = ls_rolehdr-appl
                i_sysid                   = ls_rolehdr-sysid
           IMPORTING
                es_rolid                  = ls_rolid
           EXCEPTIONS
                source_rolid_doesnt_exist = 1
                not_authorized_to_display = 2
                OTHERS                    = 3.
      IF sy-subrc <> 0.
        CLEAR ls_rolid.
      ENDIF.

      tree_outputdet4-rtext = ls_rolid-rdesc.
      CLEAR ls_rolid.
    ENDIF.

    IF tree_outputdet4-conid = 'ALL'."User has all conflicts,
      "so sensitivity is HIGH
      tree_outputdet4-imp = 'HIGH'.
    ENDIF.
    READ TABLE totalusers2 WITH  KEY bname = tree_outputdet4-bname
    binary search.
    IF sy-subrc = 0.
      tree_outputdet4-class = totalusers2-class.
    ENDIF.
* get unique id's
    lt_class-usergroup = tree_outputdet4-class.
    INSERT TABLE lt_class.
    lt_rfcdests-rfcdest = tree_outputdet4-rfcdest.
    INSERT TABLE lt_rfcdests.
    lt_tcode-tcode = tree_outputdet4-tcode.
    INSERT TABLE lt_tcode.
    ls_functtran-functionid = tree_outputdet4-functionid.
    ls_functtran-tcode      = tree_outputdet4-tcode.
    COLLECT ls_functtran INTO lt_functtran_src.
    CLEAR ls_functtran.
    lt_objt-object = tree_outputdet4-objct.
    INSERT TABLE lt_objt.
    lt_function-function = tree_outputdet4-functionid.
    INSERT TABLE lt_function.
    lt_role-agr_name = tree_outputdet4-agr_name.
    INSERT TABLE lt_role.
    lt_role-agr_name = tree_outputdet4-comp_agr.
    INSERT TABLE lt_role.
*   add result to tree table
    APPEND tree_outputdet4.
    CLEAR: tree_outputdet4.
*    DELETE outputdet4. "conserve some memory

  ENDLOOP.

*  FREE : outputdet4. "release table entirely

* Get user group descriptions
  IF NOT lt_class[] IS INITIAL.
    SELECT usergroup text
    FROM usgrpt
    INTO TABLE lt_usr_grp_dtls
    FOR ALL ENTRIES IN lt_class WHERE usergroup = lt_class-usergroup AND
    sprsl = sy-langu.
      "#EC CI_SUBRC
  ENDIF.
* get tcode descriptions
  IF NOT lt_tcode[] IS INITIAL.
    SELECT tcode ttext
    FROM tstct
    INTO TABLE lt_tcode_dtls
    FOR ALL ENTRIES IN lt_tcode WHERE tcode = lt_tcode-tcode AND
    sprsl = sy-langu.
 "#EC CI_SUBRC
  ENDIF.
*--Get descriptions of fioriids; if any
  IF NOT lt_functtran_src IS INITIAL.
    SELECT functionid tcode fioriid
      FROM /psyng/functtran
      INTO TABLE lt_functtran
      FOR ALL ENTRIES IN lt_functtran_src
      WHERE functionid EQ lt_functtran_src-functionid
        AND tcode      EQ lt_functtran_src-tcode
        AND vrsio      EQ sodvrsio
        AND type       EQ 'F'.
    IF sy-subrc EQ 0
    AND NOT lt_functtran IS INITIAL.
      SELECT fioriid appname
        FROM /psyng/sw_fioria
        INTO TABLE lt_fioria
        FOR ALL ENTRIES IN lt_functtran
        WHERE fioriid EQ lt_functtran-fioriid.
      IF sy-subrc EQ 0.
        SORT lt_fioria BY fioriid.
        LOOP AT lt_functtran ASSIGNING <fs_functtran>.
          READ TABLE lt_fioria INTO ls_fioria
            WITH KEY fioriid = <fs_functtran>-fioriid
            BINARY SEARCH.
          IF sy-subrc EQ 0.
            <fs_functtran>-appname = ls_fioria-appname.
          ENDIF.
        ENDLOOP.
      ENDIF.
      SORT lt_functtran BY functionid tcode.
    ENDIF.
  ENDIF.
* get RFC destination descriptions
  IF NOT lt_rfcdests[] IS INITIAL.
    SELECT rfcdest rfcdoc1
    FROM rfcdoc
    INTO TABLE lt_rfc_dtls
    FOR ALL ENTRIES IN lt_rfcdests WHERE rfcdest = lt_rfcdests-rfcdest
    AND rfclang = sy-langu.
"#EC CI_SUBRC
  ENDIF.
* get auth object descriptions
  IF NOT lt_objt[] IS INITIAL.
    SELECT  object ttext
    FROM tobjt
    INTO TABLE lt_obj_dtls
    FOR ALL ENTRIES IN lt_objt WHERE object = lt_objt-object AND
    langu = sy-langu.
"#EC CI_SUBRC
  ENDIF.
* get function descriptions
  IF NOT lt_function[] IS INITIAL.
    SELECT  function description
    FROM /psyng/function
    INTO TABLE lt_fun_dtls
    FOR ALL ENTRIES IN lt_function WHERE
    function = lt_function-function  AND
    vrsio = sodvrsio.
"#EC CI_SUBRC
  ENDIF.
* get role texts
  IF NOT lt_role[] IS INITIAL.
    SELECT agr_name text
    FROM agr_texts
    INTO TABLE lt_role_dtl
    FOR ALL ENTRIES IN lt_role WHERE agr_name = lt_role-agr_name AND
    spras = sy-langu AND line = 0.
"#EC CI_SUBRC
  ENDIF.

  SORT : lt_usr_grp_dtls, lt_tcode_dtls, lt_rfc_dtls,
         lt_obj_dtls, lt_fun_dtls, lt_role_dtl.

  SORT tree_outputdet4 BY class bname imp conid functionid tcode
  rfcdest objct .
  DATA : ls_tree_outputdet4 LIKE LINE OF tree_outputdet4.
  LOOP AT tree_outputdet4.
    ls_tree_outputdet4-rtext = tree_outputdet4-rtext.
    AT NEW bname.
      CLEAR : tree_outputdet4-mitgn.
    ENDAT.
*--TODO : whhat does this mean, why is this here?
*    READ TABLE 1stoutput WITH KEY conid = tree_outputdet4-conid
*                                  bname = tree_outputdet4-bname.
*    IF sy-subrc = 0.
*      ls_tree_outputdet4-mitgn = 1stoutput-contid.
*    ENDIF.
*
*   CLASS
    AT NEW class.
      READ TABLE lt_usr_grp_dtls INTO l_wa_urgup_detl WITH KEY class =
                                                tree_outputdet4-class.
      IF sy-subrc = 0.
        ls_tree_outputdet4-text = l_wa_urgup_detl-text.
      ENDIF.
      IF tree_outputdet4-class = ' '.
        ls_tree_outputdet4-class = 'ZZZZ'.
      ELSE.
        ls_tree_outputdet4-class = tree_outputdet4-class.
      ENDIF.
    ENDAT.
*   FUNCTION
    AT NEW functionid.
      READ TABLE lt_fun_dtls INTO l_wa_fun_dtl WITH KEY
      function = tree_outputdet4-functionid BINARY SEARCH.
      IF sy-subrc = 0.
        ls_tree_outputdet4-fun_des  = l_wa_fun_dtl-description.
      ENDIF.
    ENDAT.
*   TCODE
    AT NEW tcode.
      READ TABLE lt_functtran INTO ls_functtran
        WITH KEY functionid = tree_outputdet4-functionid
                 tcode      = tree_outputdet4-tcode BINARY SEARCH.
      IF sy-subrc EQ 0.
        ls_tree_outputdet4-ttext  = ls_functtran-appname.
      ELSE.
        READ TABLE lt_tcode_dtls INTO l_wa_tcode_detl WITH KEY tcode  =
                                 tree_outputdet4-tcode BINARY SEARCH.
        IF sy-subrc = 0.
          ls_tree_outputdet4-ttext  = l_wa_tcode_detl-ttext.
        ENDIF.
      ENDIF.
    ENDAT.
*   RFCDEST
    AT NEW rfcdest.
      READ TABLE lt_rfc_dtls INTO l_wa_rfc_detl WITH KEY rfcdest  =
                                 tree_outputdet4-rfcdest BINARY SEARCH.
      IF sy-subrc = 0.
        ls_tree_outputdet4-rfcdoc1  = l_wa_rfc_detl-rfcdoc1.
      ENDIF.
    ENDAT.
*   OBJECT
    AT NEW objct.
      READ TABLE lt_obj_dtls INTO l_wa_obj_dtl WITH KEY object =
                                 tree_outputdet4-objct BINARY SEARCH.
      IF sy-subrc = 0.
        ls_tree_outputdet4-obj_des  = l_wa_obj_dtl-ttext.
      ENDIF.
    ENDAT.
*   ROLE
    AT NEW agr_name.
*    IF tree_outputdet4-rtext IS INITIAL.
      READ TABLE lt_role_dtl INTO l_wa_rol_dtl WITH KEY agr_name =
                         tree_outputdet4-agr_name BINARY SEARCH.
      IF sy-subrc = 0.
        ls_tree_outputdet4-rtext = l_wa_rol_dtl-rtext.
*      ENDIF.
      ENDIF.
    ENDAT.
*  Composite role
    AT NEW comp_agr.
      IF showcomp = 'X'.
        READ TABLE lt_role_dtl INTO l_wa_rol_dtl WITH KEY agr_name =
                      tree_outputdet4-comp_agr BINARY SEARCH.
        IF sy-subrc = 0.
          ls_tree_outputdet4-crtext = l_wa_rol_dtl-rtext.
        ENDIF.
      ENDIF.
    ENDAT.
*   IMP
    AT NEW imp.
      ls_tree_outputdet4-imp = tree_outputdet4-imp.
      IF tree_outputdet4-imp = 'HIGH'.
        REPLACE 'HIGH'  WITH 'NNNN' INTO ls_tree_outputdet4-imp.
      ELSEIF tree_outputdet4-imp = 'MEDIUM'.
        REPLACE 'MEDIUM'  WITH 'OOOO' INTO ls_tree_outputdet4-imp.
      ELSEIF tree_outputdet4-imp = 'LOW'.
        REPLACE 'LOW'  WITH 'PPPP' INTO ls_tree_outputdet4-imp.
      ELSEIF tree_outputdet4-imp = 'CRITICAL'.
        REPLACE 'CRITICAL'  WITH 'MMMM' INTO ls_tree_outputdet4-imp.
      ENDIF.



    ENDAT.
*   move the text fields to the header line
    tree_outputdet4-mitgn = ls_tree_outputdet4-mitgn.
    tree_outputdet4-text = ls_tree_outputdet4-text.
    tree_outputdet4-class = ls_tree_outputdet4-class.
    tree_outputdet4-ttext = ls_tree_outputdet4-ttext.
    tree_outputdet4-fun_des = ls_tree_outputdet4-fun_des.
    tree_outputdet4-rfcdoc1 = ls_tree_outputdet4-rfcdoc1.
    tree_outputdet4-obj_des = ls_tree_outputdet4-obj_des.
    tree_outputdet4-rtext = ls_tree_outputdet4-rtext.
    tree_outputdet4-crtext = ls_tree_outputdet4-crtext.
    tree_outputdet4-imp = ls_tree_outputdet4-imp.
*   update internal table
    MODIFY tree_outputdet4.
*    CLEAR ls_tree_outputdet4.
  ENDLOOP.

  SORT tree_outputdet4 BY class bname imp conid functionid tcode
  rfcdest objct.
  tree_outputdet4-imp = 'LOW'.
  MODIFY  tree_outputdet4 TRANSPORTING imp WHERE imp = 'PPPP' .
  tree_outputdet4-imp = 'MEDIUM'.
  MODIFY  tree_outputdet4 TRANSPORTING imp WHERE imp = 'OOOO' .
  tree_outputdet4-imp = 'HIGH'.
  MODIFY  tree_outputdet4 TRANSPORTING imp WHERE imp = 'NNNN' .
  tree_outputdet4-imp = 'CRITICAL'.
  MODIFY  tree_outputdet4 TRANSPORTING imp WHERE imp = 'MMMM' .


  LOOP AT tree_outputdet4.
    g_wa_tree_1 = tree_outputdet4.
    IF tree_outputdet4-enhanced = 'X'.
      l_conf_enh = 'X'.
      l_tcod_enh = 'X'.
      l_objt_enh = 'X'.
    ENDIF.

    IF tree_outputdet4-simu = 'X'.
      l_conf_sim = 'X'.
      l_tcod_sim = 'X'.
      l_objt_sim = 'X'.
    ENDIF.

    AT END OF auth.
      l_auth_cnt = l_auth_cnt + 1.
    ENDAT.
    AT END OF objct.
      tree_objct  = g_wa_tree_1.
      tree_objct-totl_auth = l_auth_cnt.
      tree_objct-o_enh = l_objt_enh.
      tree_objct-o_simu = l_objt_sim.
      APPEND tree_objct .
      CLEAR : l_auth_cnt,l_objt_enh,l_objt_sim.
    ENDAT.
    AT END OF rfcdest.
      tree_rfcdest = g_wa_tree_1.
      APPEND tree_rfcdest.
    ENDAT.
    AT END OF tcode.
      l_tcd_cnt =  l_tcd_cnt + 1.
      tree_tcd = g_wa_tree_1.
      tree_tcd-t_enh = l_tcod_enh.
      tree_tcd-t_simu = l_tcod_sim.
      APPEND tree_tcd.
      CLEAR : l_tcod_enh,l_tcod_sim.

    ENDAT.
    AT END OF functionid.
      tree_functn = g_wa_tree_1.
      tree_functn-all_tcd = l_tcd_cnt.
      APPEND tree_functn.
      CLEAR l_tcd_cnt.
    ENDAT.
    AT END OF conid.
      l_t_conid = l_t_conid + 1.
      IF tree_outputdet4-imp = 'HIGH'.
        l_hgh_cnt = l_hgh_cnt + 1.
      ELSEIF tree_outputdet4-imp = 'MEDIUM'.
        l_mdm_cnt = l_mdm_cnt + 1.
      ELSEIF tree_outputdet4-imp = 'LOW'.
        l_low_cnt = l_low_cnt + 1.
      ELSEIF tree_outputdet4-imp = 'CRITICAL'.
        l_crit_cnt = l_crit_cnt + 1.
      ENDIF.
      tree_confct = g_wa_tree_1.
      tree_confct-con_enh = l_conf_enh .
      tree_confct-con_simu = l_conf_sim .
      APPEND tree_confct.
      CLEAR :l_conf_enh,l_conf_sim  .

    ENDAT.
    AT END OF imp.
      tree_sen = g_wa_tree_1.
      APPEND tree_sen.
    ENDAT.

    AT END OF bname.
      l_usr_cnt = l_usr_cnt + 1.
      tree_bname = g_wa_tree_1.
      tree_bname-u_ttl_cnf = l_t_conid.
      tree_bname-u_hgh_cnt = l_hgh_cnt.
      tree_bname-u_mdm_cnt = l_mdm_cnt.
      tree_bname-u_low_cnt = l_low_cnt.
      tree_bname-u_crit_cnt = l_crit_cnt.
      APPEND tree_bname.
      CLEAR : l_t_conid,l_hgh_cnt,l_mdm_cnt,l_low_cnt, l_crit_cnt.
    ENDAT.

    AT END OF class.
      tree_class = g_wa_tree_1.
      tree_class-all_user = l_usr_cnt.
      APPEND tree_class.
      CLEAR: l_usr_cnt,tree_class.
    ENDAT.
  ENDLOOP.

  CREATE OBJECT g_application.

  IF p_noprin IS INITIAL.
    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
         EXPORTING
              percentage = 90
              text       = text-t01.
  ENDIF.

  CALL SCREEN 9000.
ENDFORM.                    " output_using_alv_tree
*&---------------------------------------------------------------------*
*&      Module  PAI_9000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_9000 INPUT.
  DATA: l_return_code TYPE i,
        l_wa_copy_node TYPE LINE OF treev_nks.


  CALL METHOD cl_gui_cfw=>dispatch
    IMPORTING return_code = l_return_code.
  IF l_return_code <> cl_gui_cfw=>rc_noevent.
    CLEAR g_ok_code.
    EXIT.
  ENDIF.

  CASE g_ok_code.
    WHEN 'BACK'. " Finish program
      IF NOT g_custom_container IS INITIAL.
        CALL METHOD g_custom_container->free
          EXCEPTIONS
            cntl_system_error = 1
            cntl_error        = 2.
        IF sy-subrc <> 0.
          MESSAGE x208(00) WITH 'ERROR'.
        ENDIF.
        CLEAR g_custom_container.
        CLEAR g_tree.
        LEAVE TO SCREEN 0.
      ENDIF.
    WHEN 'CANCEL'.
      CALL METHOD g_custom_container->free.
      LEAVE PROGRAM.
    WHEN 'LST'.
       perform output_using_alv.


    WHEN 'EXCEL'.
*    hide progress indicator. (for speed)
      prog_indi_mode = 0.
      SET PARAMETER ID 'SIN' FIELD prog_indi_mode.
      COMMIT WORK.
      CALL SCREEN 9002 STARTING AT 5 10.
      prog_indi_mode = 1.
      SET PARAMETER ID 'SIN' FIELD prog_indi_mode.
    WHEN 'EXP'.
      CLEAR : node_key.
      PERFORM node_info CHANGING node_key.
      IF node_key = ' '.

        CALL METHOD g_tree->expand_root_nodes
          EXPORTING
            level_count         = 2
          EXCEPTIONS
            failed              = 1
            illegal_level_count = 2
            cntl_system_error   = 3
            OTHERS              = 4
                .
        IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.
      ELSEIF node_key(1) <> 'A'. "don't expand lowest level node
        CALL METHOD g_tree->expand_node
          EXPORTING
            node_key            = node_key
            level_count         = '8'
            expand_subtree      = 'X'
          EXCEPTIONS
            failed              = 1
            illegal_level_count = 2
            cntl_system_error   = 3
            node_not_found      = 4
            cannot_expand_leaf  = 5
            OTHERS              = 6
                .
        IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.

      ENDIF.
      CLEAR : node_key.

    WHEN 'COL'.
      CLEAR : node_key.
      PERFORM node_info CHANGING node_key.
      IF node_key = ' '.
        CALL METHOD g_tree->collapse_all_nodes
          EXCEPTIONS
            failed            = 1
            cntl_system_error = 2
            OTHERS            = 3
                .
        IF sy-subrc <> 0.
*      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                 WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.
      ELSE.
        CALL METHOD g_tree->collapse_subtree
          EXPORTING
            node_key          = node_key
        EXCEPTIONS
          failed            = 1
          node_not_found    = 2
          cntl_system_error = 3
          OTHERS            = 4
                    .
        IF sy-subrc <> 0.
          MESSAGE w113(/psyng/sw) WITH
          'Please select corresponding Node'(170).
        ENDIF.
      ENDIF.
      CLEAR : node_key.


    WHEN 'LAYOUT'.

      REFRESH : colitab.
      CLEAR: colitab.

      colitab-col_name = 'FIELD'.
      colitab-col_title = text-093.
      colitab-width = '21' .
      APPEND colitab.

      IF orgchk = 'X'.
        colitab-col_name = 'AREA'.
        colitab-col_title = text-t15.
        colitab-width = '35'.
        APPEND colitab.
      ENDIF.

      colitab-col_name = 'VON'.
      colitab-col_title = text-105.
      colitab-width = '15'.
      APPEND colitab.

      colitab-col_name = 'BIS'.
      colitab-col_title = text-107.
      colitab-width = '15'.
      APPEND colitab.

      colitab-col_name = 'ROLE'.
      colitab-col_title = text-096.
      colitab-width = '45'.
      APPEND colitab.

      colitab-col_name = 'RTEXT'.
      colitab-col_title = text-t20.
      colitab-width = '41'.
      APPEND colitab.

      IF showcomp = 'X'.
        colitab-col_name = 'COM_AGR'.
        colitab-col_title = text-t14.
        colitab-width = '40'.
        APPEND colitab.
        colitab-col_name = 'CRTEXT'.
        colitab-col_title = text-t21.
        colitab-width = '40'.
        APPEND colitab.


      ENDIF.

      colitab-col_name = 'PRO'.
      colitab-col_title = text-097.
      colitab-width = '39'.
      APPEND colitab.

      IF p_enhanc = 'X'.
        colitab-col_name = 'EHN'.
        colitab-col_title = text-158.
        colitab-width = '10'.
        APPEND colitab.
      ENDIF.
      IF bysimu = 'X'.
        colitab-col_name = 'SIMU'.
        colitab-col_title = text-t16.
        colitab-width = '10'.
        APPEND colitab.
      ENDIF.


      CALL SCREEN 9004 STARTING AT 5 10.
    WHEN 'TCD'.
      CLEAR: node_key,l_wa_copy_node.
      REFRESH : l_copy_node.
      PERFORM node_info CHANGING node_key.
      IF node_key = ' '.
        CALL METHOD g_tree->expand_root_nodes
              EXPORTING
                level_count         = 6
*            EXPAND_SUBTREE      = 'X'
              EXCEPTIONS
                failed              = 1
                illegal_level_count = 2
                cntl_system_error   = 3
                OTHERS              = 4
                    .

        LOOP AT item_table INTO item WHERE text = 'S_TCODE'.

          l_wa_copy_node = item-node_key.
          APPEND l_wa_copy_node TO l_copy_node.
        ENDLOOP.

        CALL METHOD g_tree->expand_nodes
          EXPORTING
            node_key_table          = l_copy_node
          EXCEPTIONS
            failed                  = 1
            cntl_system_error       = 2
            error_in_node_key_table = 3
            dp_error                = 4
            OTHERS                  = 5
                .
        IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
        ENDIF.
      ELSE.
        l_wa_copy_node = node_key.
        CHECK node_key(1) <> 'A'. "don't expand lowest level node
*       don't expand object nodes either (unless it's an S_TCODE node)
        DATA : lf_expand TYPE flag.
        lf_expand = 'X'.
        IF node_key(1) = 'O'.
          READ TABLE item_table WITH KEY node_key = node_key
                                        text     = 'S_TCODE'
                               TRANSPORTING NO FIELDS.
          IF sy-subrc <> 0.
            CLEAR lf_expand.
          ENDIF.
        ENDIF.
        CHECK lf_expand = 'X'.
        APPEND l_wa_copy_node TO l_copy_node.
*     expand child nodes
        PERFORM expand_tcode_nodes TABLES l_copy_node USING node_key.

        CALL METHOD g_tree->expand_nodes
         EXPORTING
           node_key_table          = l_copy_node
         EXCEPTIONS
           failed                  = 1
           cntl_system_error       = 2
           error_in_node_key_table = 3
           dp_error                = 4
           OTHERS                  = 5
               .
      ENDIF.
  ENDCASE.
  CLEAR g_ok_code.
  ENDMODULE.
  FORM expand_tcode_nodes TABLES   lt_copy_node "structure TV_NODEKEY
                        USING    node_key TYPE tv_nodekey.
  DATA : ls_copy_node TYPE tv_nodekey,
         l_node TYPE treev_node.
  LOOP AT node_table INTO l_node WHERE relatkey = node_key.
    CASE l_node-node_key+0(1).
      WHEN 'O'.
        LOOP AT item_table INTO item WHERE
                  node_key = l_node-node_key AND
                  text     = 'S_TCODE'.
          ls_copy_node = l_node-node_key.
          APPEND ls_copy_node TO lt_copy_node.
        ENDLOOP.
      WHEN 'A'.
*        don't expand lowest level node
      WHEN OTHERS.
        ls_copy_node = l_node-node_key.
        APPEND ls_copy_node TO l_copy_node.
*               nested call to self
        PERFORM expand_tcode_nodes TABLES lt_copy_node
                                   USING ls_copy_node.
    ENDCASE.
  ENDLOOP.

ENDFORM.                    " expand_tcode_nodes
FORM node_info CHANGING node_key TYPE tv_nodekey.
  CALL METHOD g_tree->get_selected_item
       IMPORTING
         node_key          =  node_key
*          ITEM_NAME         =
       EXCEPTIONS
         failed            = 1
         cntl_system_error = 2
         no_item_selection = 3
         OTHERS            = 4.

  IF sy-subrc <> 0.
*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

  IF node_key = ' '.
    CALL METHOD g_tree->get_selected_node
      IMPORTING
          node_key          =  node_key
      EXCEPTIONS
        failed                     = 1
        single_node_selection_only = 2
        cntl_system_error          = 3
        OTHERS                     = 4
            .
    IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.
ENDFORM.                    " NODE_INFO
*&---------------------------------------------------------------------*
*&      Module  STATUS_9004  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_9004 OUTPUT.
  SET PF-STATUS 'COL_DEL'.
  SET TITLEBAR 'COL_TEST'.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9004  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9004 INPUT.
  CASE sy-ucomm.
    WHEN 'OKEY'.
      flg_del_column = 'X'.
    WHEN 'INSER'.
      flg_del_column = '1'.
    WHEN 'EXIT'.
      CLEAR flg_del_column.
      LEAVE TO SCREEN 0.
  ENDCASE.

ENDMODULE.
MODULE delete_col INPUT.
  DATA: item_table_int TYPE item_table_type,
         l_int_item TYPE mtreeitm.
  DATA: l_column TYPE tv_itmname,
         l_col_text TYPE tv_heading.

  l_column = colitab-col_name.
  l_col_text = colitab-col_title.
  TRANSLATE l_col_text+1 TO LOWER CASE.
  IF sel = 'X'.
    IF flg_del_column = 'X'.
      CALL METHOD g_tree->delete_column
       EXPORTING
         column_name       = l_column
       EXCEPTIONS
         failed            = 1
         column_not_found  = 2
         cntl_system_error = 3
         OTHERS            = 4
             .
      IF sy-subrc <> 0.
        MESSAGE w113(/psyng/sw) WITH 'Column'(t25)
        colitab-col_title text-t23.
      ENDIF.
    ENDIF.
    IF flg_del_column = '1'.

      CALL METHOD g_tree->add_column
        EXPORTING
          name                         = l_column
*        HIDDEN                       =
*        DISABLED                     =
*        ALIGNMENT                    =
          width                        = colitab-width
*        WIDTH_PIX                    =
*        HEADER_IMAGE                 =
          header_text                  = l_col_text
*        HEADER_TOOLTIP               =
        EXCEPTIONS
          column_exists                = 1
          illegal_column_name          = 2
          too_many_columns             = 3
          illegal_alignment            = 4
          different_column_types       = 5
          cntl_system_error            = 6
          failed                       = 7
          predecessor_column_not_found = 8
          OTHERS                       = 9
              .
      IF sy-subrc = 1.
        MESSAGE w113(/psyng/sw) WITH 'Column'(t25) l_col_text
        'already exists'(t26).

      ELSEIF sy-subrc = 0.

        LOOP AT item_table INTO item WHERE item_name = l_column.
          l_int_item = item.
          APPEND l_int_item TO item_table_int .
        ENDLOOP.

        CALL METHOD g_tree->add_nodes_and_items
           EXPORTING
*      NODE_TABLE = NODE_TABLE
             item_table = item_table_int
             item_table_structure_name = 'MTREEITM'
           EXCEPTIONS
             failed = 1
             cntl_system_error = 3
             error_in_tables = 4
             dp_error = 5
             table_structure_name_not_found = 6.
        IF sy-subrc <> 0.
          MESSAGE x208(00) WITH 'ERROR'.
        ENDIF.
        REFRESH: item_table_int.

      ENDIF.

    ENDIF.

  ENDIF.


ENDMODULE.                 " DELETE_COL  INPUT
MODULE exit_scn INPUT.
  DATA: g_col_get_ordr TYPE treev_cona,
        g_col_set_order TYPE treev_cona.
  DATA: wa_col_order TYPE LINE OF treev_cona,
        wa_col_get_ordr TYPE LINE OF treev_cona,
        wa_col_set_order TYPE LINE OF treev_cona.
  TYPES : BEGIN OF col_ordr,
          col TYPE LINE OF treev_cona,
          END OF col_ordr.
  DATA: col_lst_ordr TYPE STANDARD TABLE OF col_ordr INITIAL SIZE 0
         WITH HEADER LINE.


  IF flg_del_column = '1' OR flg_del_column = 'X'.
    IF flg_del_column = '1'.
      CALL METHOD g_tree->get_column_order
        CHANGING
          columns           = g_col_get_ordr
       EXCEPTIONS
         cntl_system_error = 1
         dp_error          = 2
         failed            = 3
         OTHERS            = 4
              .
      IF sy-subrc <> 0.
*      MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                 WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

      REFRESH: col_lst_ordr.

      LOOP AT g_col_get_ordr INTO wa_col_get_ordr.
        col_lst_ordr-col = wa_col_get_ordr.
        APPEND col_lst_ordr.
      ENDLOOP.
      REFRESH: g_col_set_order.
      LOOP AT g_col_order INTO wa_col_order.
        READ TABLE col_lst_ordr WITH KEY col = wa_col_order.
        IF sy-subrc = 0.
          wa_col_set_order = wa_col_order.
          APPEND  wa_col_set_order TO g_col_set_order.
        ENDIF.
      ENDLOOP.
      CALL METHOD g_tree->set_column_order
                EXPORTING
                  columns           = g_col_set_order
                EXCEPTIONS
                  cntl_system_error = 1
                  dp_error          = 2
                  failed            = 3
                  column_not_found  = 4
                  hierarchy_column  = 5
                  wrong_column_set  = 6
                  OTHERS            = 7
                      .
      IF sy-subrc <> 0.
*         MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                    WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
      ENDIF.

    ENDIF.

    CLEAR: flg_del_column.
    LEAVE TO SCREEN 0.
  ENDIF.
ENDMODULE.                 " EXIT_SCN  INPUT
MODULE status_9002 OUTPUT.
  SET PF-STATUS 'DWNLD'.
  SET TITLEBAR 'DNLD'.
ENDMODULE.                 " STATUS_9002  OUTPUT
MODULE user_command_9002 INPUT.
*type-pools : TRUXS.
  TYPES l_ty_text_data(4096) TYPE c OCCURS 0.
  DATA : lf_funcname TYPE rs38l-name.
  DATA : l_msgv     TYPE bapiret2-message_v1,
         l_file_name TYPE string.


  DATA : lt_csv TYPE  l_ty_text_data .
  CASE sy-ucomm.
    WHEN 'CON'.

      REFRESH: g_dnld.
      CLEAR: g_dnld,node_key.
      PERFORM node_info CHANGING node_key.
      CLEAR: g_flg_lst_sel.
      IF node_key <> ' '.
        PERFORM get_selected_item_info.
        PERFORM insrt_data_2_dnld.
      ELSE.
        LOOP AT tree_outputdet4.
          PERFORM data_move_2_dnld_tab USING tree_outputdet4.
        ENDLOOP.
      ENDIF.

*--Check if this version supports this
*  NON-ERP does not support excell conversion
      lf_funcname = 'SAP_CONVERT_TO_CSV_FORMAT'.
      CALL FUNCTION 'FUNCTION_EXISTS'
           EXPORTING
                funcname           = lf_funcname
           EXCEPTIONS
                function_not_exist = 1
                OTHERS             = 2.
      IF sy-subrc = 0.

*--Disable extremely slow progress indicator
*hide progress indicator. (for speed).
        prog_indi_mode = 0.
        SET PARAMETER ID 'SIN' FIELD prog_indi_mode.
        COMMIT WORK.

*       Set background mode for performance
        sy-batch = 'X'.
        CALL FUNCTION lf_funcname "#EC PATHLOCK_CI_DYN_ACCES
         EXPORTING
           i_field_seperator          = ','
           i_line_header              = 'X'
           i_filename                 = dn_file
*             I_APPL_KEEP                = ' '
          TABLES
            i_tab_sap_data             =  g_dnld
         CHANGING
           i_tab_converted_data       = lt_csv
         EXCEPTIONS
           conversion_failed          = 1
           OTHERS                     = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*       Reset background mode
        CLEAR sy-batch.

*show progress indicator.
        prog_indi_mode = 1.
        SET PARAMETER ID 'SIN' FIELD prog_indi_mode.
        COMMIT WORK.
        l_file_name = dn_file.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
        CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
             EXPORTING
                  filename                = l_file_name
                  filetype                = 'ASC'
                  write_field_separator   = 'X'
                  dat_mode                = ' '
             TABLES
                  data_tab                = lt_csv
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
          l_msgv = dn_file.
          CALL FUNCTION '/PSYNG/BC_003'
               EXPORTING
                    i_subrc = sy-subrc
                    i_msgty = 'I'
                    i_msgv1 = l_msgv.
        ELSE.
          MESSAGE s113(/psyng/sw) WITH text-t24.
          LEAVE TO SCREEN 0.
        ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
      ELSE.
        l_file_name = dn_file.
*BOC:HBHALLA (096)
   AUTHORITY-CHECK OBJECT  'S_GUI'
                    ID      'ACTVT'
                    FIELD   '61'.
  IF sy-subrc = 0.
        CALL FUNCTION 'GUI_DOWNLOAD' "#EC SAST_CI_GEN_CHECK
             EXPORTING
                  filename                = l_file_name
                  filetype                = 'ASC'
                  write_field_separator   = 'X'
                  dat_mode                = ' '
             TABLES
                  data_tab                = g_dnld
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
          l_msgv = dn_file.
          CALL FUNCTION '/PSYNG/BC_003'
               EXPORTING
                    i_subrc = sy-subrc
                    i_msgty = 'I'
                    i_msgv1 = l_msgv.
        ELSE.
          MESSAGE s113(/psyng/sw) WITH text-t24.
          LEAVE TO SCREEN 0.
        ENDIF.
  ENDIF.
*EOC:HBHALLA (096)
      ENDIF.

    WHEN 'EXIT'.
      LEAVE TO SCREEN 0.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_9002  INPUT
FORM data_move_2_dnld_tab USING    dwnld_outputdet4 TYPE tree_final.

  g_dnld-class = dwnld_outputdet4-class.
  g_dnld-bname = dwnld_outputdet4-bname.
  g_dnld-org_abb = dwnld_outputdet4-org_abb.
  g_dnld-imp = dwnld_outputdet4-imp.
  g_dnld-conid = dwnld_outputdet4-conid.
  g_dnld-functionid = dwnld_outputdet4-functionid.
  g_dnld-comp_agr = dwnld_outputdet4-comp_agr.
  g_dnld-agr_name = dwnld_outputdet4-agr_name .
  g_dnld-rfcdest = dwnld_outputdet4-rfcdest.
  g_dnld-tcode = dwnld_outputdet4-tcode.
  g_dnld-objct = dwnld_outputdet4-objct.
  g_dnld-auth = dwnld_outputdet4-auth.
  g_dnld-field  = dwnld_outputdet4-field .
  g_dnld-von = dwnld_outputdet4-von.
  g_dnld-bis = dwnld_outputdet4-bis.
  g_dnld-profile = dwnld_outputdet4-profile.
  g_dnld-description = dwnld_outputdet4-description.
  g_dnld-simu = dwnld_outputdet4-simu.
  g_dnld-enhanced = dwnld_outputdet4-enhanced.
  APPEND g_dnld.


ENDFORM.                    " DATA_MOVE_2_DNLD_TAB
FORM get_selected_item_info.
  CLEAR: g_lst_class,g_lst_bname,g_lst_imp,g_lst_conid,
  g_lst_node_key,g_flg_lst_sel,g_lst_functionid,g_lst_tcode,
  g_lst_rfcdest,g_lst_objct.
  g_lst_node_key = node_key+0(1).
  CASE node_key+0(1).
    WHEN 'G'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_class INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_class-class.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.
    WHEN 'U'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_bname INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_bname-class.
        g_lst_bname = tree_bname-bname.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.

    WHEN 'S'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_sen INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_sen-class.
        g_lst_bname = tree_sen-bname.
        g_lst_imp = tree_sen-imp.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.

    WHEN 'C'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_confct INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_confct-class.
        g_lst_bname = tree_confct-bname.
        g_lst_imp = tree_confct-imp.
        g_lst_conid = tree_confct-conid.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.
    WHEN 'F'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_functn INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_functn-class.
        g_lst_bname = tree_functn-bname.
        g_lst_imp = tree_functn-imp.
        g_lst_conid = tree_functn-conid.
        g_lst_functionid = tree_functn-functionid.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.
    WHEN 'T'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_tcd INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_tcd-class.
        g_lst_bname = tree_tcd-bname.
        g_lst_imp = tree_tcd-imp.
        g_lst_conid = tree_tcd-conid.
        g_lst_functionid = tree_tcd-functionid.
        g_lst_tcode = tree_tcd-tcode.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.
    WHEN 'R'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_rfcdest INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_rfcdest-class.
        g_lst_bname = tree_rfcdest-bname.
        g_lst_imp = tree_rfcdest-imp.
        g_lst_conid = tree_rfcdest-conid.
        g_lst_functionid = tree_rfcdest-functionid.
        g_lst_tcode = tree_rfcdest-tcode.
        g_lst_rfcdest = tree_rfcdest-rfcdest.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.
    WHEN 'O'.
      sel_idx = node_key+1 + 1.
      READ TABLE tree_objct INDEX sel_idx.
      IF sy-subrc = 0.
        g_lst_class = tree_objct-class.
        g_lst_bname = tree_objct-bname.
        g_lst_imp = tree_objct-imp.
        g_lst_conid = tree_objct-conid.
        g_lst_functionid = tree_objct-functionid.
        g_lst_tcode = tree_objct-tcode.
        g_lst_rfcdest = tree_objct-rfcdest.
        g_lst_objct = tree_objct-objct.
        g_flg_lst_sel = 'X'.
        CLEAR sel_idx.
      ENDIF.



  ENDCASE.

ENDFORM.                    " GET_SELECTED_ITEM_INFO
FORM insrt_data_2_dnld.
  REFRESH: g_dnld.
  CLEAR: g_dnld.
  IF g_lst_node_key = 'G'.
    LOOP AT tree_bname WHERE class = g_lst_class.
      AT END OF bname.
        LOOP AT tree_outputdet4 WHERE bname = tree_bname-bname.
          PERFORM data_move_2_dnld_tab USING tree_outputdet4.
        ENDLOOP.
      ENDAT.
    ENDLOOP.

  ELSEIF g_lst_node_key = 'U' .
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname .
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.
  ELSEIF g_lst_node_key = 'S'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
                                                      g_lst_imp .
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.
  ELSEIF g_lst_node_key = 'C'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
                            g_lst_imp AND conid = g_lst_conid.
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.
  ELSEIF g_lst_node_key = 'F'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
                          g_lst_imp AND conid = g_lst_conid AND
                          functionid = g_lst_functionid.
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.

  ELSEIF g_lst_node_key = 'T'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
                            g_lst_imp AND conid = g_lst_conid AND
                           functionid = g_lst_functionid AND tcode =
                           g_lst_tcode.
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.

  ELSEIF g_lst_node_key = 'R'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
    g_lst_imp AND conid = g_lst_conid AND functionid =
    g_lst_functionid AND tcode = g_lst_tcode AND
    rfcdest = g_lst_rfcdest.
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.
  ELSEIF g_lst_node_key = 'O'.
    LOOP AT tree_outputdet4 WHERE bname = g_lst_bname AND imp =
                               g_lst_imp AND conid = g_lst_conid AND
                                       functionid = g_lst_functionid
                                       AND tcode = g_lst_tcode AND
                                       rfcdest = g_lst_rfcdest AND
                                       objct = g_lst_objct.
      PERFORM data_move_2_dnld_tab USING tree_outputdet4.
    ENDLOOP.
    CLEAR:g_lst_node_key.
  ENDIF.

ENDFORM.                    " INSRT_DATA_2_DNLD
