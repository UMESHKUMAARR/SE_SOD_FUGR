*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_150
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_150 MESSAGE-ID /psyng/sw.
TABLES: agr_define, usr02.
INCLUDE : /psyng/basis_exelog.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME'.
TYPES: BEGIN OF ty_swrrscon,
         roleindex TYPE /psyng/seres_roleindex,
         conindex  TYPE /psyng/seres_conindex,
       END OF ty_swrrscon.
TYPES : ttree_item LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY,
        tsodorgm   LIKE STANDARD TABLE OF /psyng/swsodorgm
          WITH DEFAULT KEY INITIAL SIZE 0.

*--C0765 START
TYPES : BEGIN OF ty_excel_header,
          col_name TYPE c LENGTH 30,
        END OF ty_excel_header,

        tt_excel_header TYPE TABLE OF ty_excel_header.
*--C0765 START

DATA : go_tree       TYPE REF TO cl_gui_column_tree,
       go_cust_cont  TYPE REF TO cl_gui_custom_container,
       go_html       TYPE REF TO cl_gui_html_viewer,
       go_html_cont  TYPE REF TO cl_gui_custom_container,
       gt_node       TYPE treev_ntab,
       gt_item       TYPE ttree_item,
       gt_conflict   TYPE TABLE OF /psyng/swrrsicon WITH HEADER LINE,
       gt_role       TYPE TABLE OF /psyng/swrrsrol WITH HEADER LINE,
       gt_sysinfo    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
       gt_varel      TYPE TABLE OF /psyng/faobj2
                    WITH HEADER LINE,
       g_rolecon_id  TYPE i,
       g_confun_id   TYPE i,
       g_auth_id     TYPE i,
       g_role_id     TYPE i,
       g_aid_exist   TYPE flag,
       g_dynnr       TYPE sy-dynnr,
       g_node_key    TYPE tv_nodekey,
       g_aid         TYPE /psyng/swrrshdr-aid,
       g_summary_del TYPE flag,
       BEGIN OF gt_sodorgm OCCURS 0,
         sysid   TYPE /psyng/sysid,
         sodorgm TYPE tsodorgm,
       END OF gt_sodorgm,
       gs_hdr               TYPE /psyng/swrrshdr,
       gf_node_has_children TYPE flag.
*---toolbar expand/find options data declare
DATA: gr_exp_role          TYPE flag,
      gr_exp_conid         TYPE flag,
      gr_exp_funid         TYPE flag,
      gf_exp_role          TYPE /psyng/swrrsrol-agr_name,
      gf_exp_conid         TYPE /psyng/conflict-conid,
      gf_exp_funid         TYPE /psyng/function-function,
      gr_fnd_role          TYPE flag,
      gr_fnd_conid         TYPE flag,
      gr_fnd_funid         TYPE flag,
      gf_fnd_role          TYPE /psyng/swrrsrol-agr_name,
      gf_fnd_conid         TYPE /psyng/conflict-conid,
      gf_fnd_funid         TYPE /psyng/function-function,
      g_nxtlvl_click_first TYPE flag,
      g_header1(100)       TYPE c,
      g_header2(100)       TYPE c,
      g_header3(100)       TYPE c,
      g_start_pos          TYPE i,
      g_start_con_pos      TYPE i,
      g_fnd_ucomm          LIKE sy-ucomm,
      g_start_fnode        TYPE tv_nodekey,
      gf_first_time_click  TYPE flag.
DATA: BEGIN OF gt_func OCCURS 0,
        fcode LIKE rsmpe-func,
      END OF gt_func.
DATA: BEGIN OF s_text ,
        text LIKE tline-tdline,
      END OF s_text.
DATA  i_text LIKE s_text OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF gt_output_alv OCCURS 0,
        agr_name  TYPE agr_define-agr_name,
        conid     TYPE /psyng/conflict-conid,
        confnum   TYPE /psyng/nr_conflicts,
        mitinum   TYPE /psyng/nr_conflicts,
        mitigated TYPE flag,
        funid     TYPE /psyng/faobj2-funid,
        childrole TYPE agr_define-agr_name,
        sysid     TYPE /psyng/sw_rfcdes-systid,
        tcode     TYPE /psyng/faobj2-tcode,
        auth      TYPE /psyng/serrs_authdetail-auth,
        object    TYPE /psyng/faobj2-object,
        field     TYPE /psyng/faobj2-field,
        von       TYPE /psyng/serrs_authdetail-von,
        bis       TYPE /psyng/serrs_authdetail-bis,
        abb       TYPE /psyng/serrs_authdetail-abb,
      END OF gt_output_alv,
      g_alv_count LIKE sy-tabix.
DATA: gt_roles_info  TYPE TABLE OF /psyng/comp_role_tcode,
      ls_ba_role     TYPE /psyng/bc_ba_00,
      g_current_user TYPE sy-uname. "C0700

*     BOC by AKUMAR for C0765
DATA : gr_exp_alv          TYPE flag,
       gr_exp_file         TYPE flag,
       gr_exp_server       TYPE flag,
       gt_excel_header     TYPE TABLE OF ty_excel_header,
       gf_server_path(200) TYPE c,      "TYPE filename-fileintern,
       gf_roles_count      TYPE i.
*     EOC by AKUMAR for C0765

INCLUDE /psyng/sw_150_classes.
INCLUDE /psyng/sw_150_macros.
INCLUDE /psyng/sw_config.
TABLES : /psyng/conflict,/psyng/swrrshdr,/psyng/swrrsrol.
DATA : go_application TYPE REF TO lcl_application.

RANGES : r_bname      FOR usr02-bname,
         gr_conflicts FOR gt_conflict-conindex.

SELECTION-SCREEN: BEGIN OF BLOCK res WITH FRAME.
PARAMETERS : p_aid TYPE /psyng/swrrshdr-aid OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK res.
SELECTION-SCREEN: BEGIN OF BLOCK rol WITH FRAME.
SELECT-OPTIONS :
   s_role  FOR agr_define-agr_name,
   rba     FOR ls_ba_role-busarea.

PARAMETERS :
  p_comp TYPE flag DEFAULT 'X',
  p_sing TYPE flag DEFAULT 'X',
  p_assr TYPE flag.
SELECTION-SCREEN: END OF BLOCK rol.

SELECTION-SCREEN: BEGIN OF BLOCK con WITH FRAME.
SELECT-OPTIONS s_conid FOR /psyng/conflict-conid.
PARAMETERS p_mitcon TYPE flag AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK con.

SELECTION-SCREEN: BEGIN OF BLOCK gp1 WITH FRAME TITLE text-g02.
PARAMETERS :
  p_fun    TYPE flag RADIOBUTTON GROUP g2,
*             p_rolpro TYPE flag RADIOBUTTON GROUP g2,
  p_orgvar TYPE flag RADIOBUTTON GROUP g2.
SELECTION-SCREEN: END OF BLOCK gp1.

SELECTION-SCREEN: BEGIN OF BLOCK gp2 WITH FRAME TITLE text-g03.
PARAMETERS : p_all   TYPE flag RADIOBUTTON GROUP g3 DEFAULT 'X', "all
             p_rswc  TYPE flag RADIOBUTTON GROUP g3,     "with conflict
             p_rswoc TYPE flag RADIOBUTTON GROUP g3 .   "w/o conflict
SELECT-OPTIONS: s_rnum FOR /psyng/swrrsrol-nr_conflicts MODIF ID rol,
                s_rmnum FOR /psyng/swrrsrol-nr_mitigated MODIF ID rol.
SELECTION-SCREEN: END OF BLOCK gp2.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_aid.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = '/PSYNG/SWRRSHDR'
      fieldname   = 'AID'
      searchhelp  = '/PSYNG/SERRSID'
      dynpprog    = sy-cprog
      dynpnr      = '1000'
      dynprofield = 'P_AID'
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          field_not_found = 1
          no_help_for_field = 2
          inconsistent_help = 3
          no_values_found  = 4
          OTHERS = 5.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.

AT SELECTION-SCREEN OUTPUT.
  IF p_rswoc EQ 'X'.
    LOOP AT SCREEN.
      IF screen-group1 EQ 'ROL'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

AT SELECTION-SCREEN.

  IF p_comp IS INITIAL AND p_sing IS INITIAL.
    MESSAGE e208(00) WITH
    'Select either Composite or Single Roles or both'(001).
  ENDIF.

INITIALIZATION.

*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
    EXPORTING
      i_repid = '/PSYNG/SW_150'.
*
* BOC by RGUPTA for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA for C0700
START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
        WITH
          'Display Results'(a01).
    LEAVE LIST-PROCESSING.
  ENDIF.
  exelog sy-repid ''.

*---if aid doesn't exist
  CALL FUNCTION '/PSYNG/SW_AID_READ'
    EXPORTING
      i_role_aid = p_aid
      if_role    = 'X'
    IMPORTING
      ef_success = g_aid_exist.
  IF p_aid IS INITIAL.
    CLEAR g_aid_exist.
  ENDIF.
  IF g_aid_exist <> 'X'.
    MESSAGE s002 WITH
    'Entered Analysis ID does not Exist'(e01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  CLEAR: g_fnd_ucomm.
  g_aid = p_aid.
  PERFORM load_results_summary.
  CALL SCREEN '0100'.
*&---------------------------------------------------------------------*
*&      Form  init_tree_100
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_tree_100.
  CREATE OBJECT go_application.

  DATA: ls_event  TYPE cntl_simple_event,
        lt_events TYPE cntl_simple_events,
        ls_header TYPE treev_hhdr,
        lt_header TYPE TABLE OF treev_hhdr.

* Create a container for the tree control
  CREATE OBJECT go_cust_cont
    EXPORTING
      container_name              = 'TREE_CONTAINER'
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5.
  IF sy-subrc <> 0.
*    MESSAGE a000(/psyng/seam).
  ENDIF.

  ls_header-heading = 'Analysis Results'(020).
  ls_header-width   = 100.

  CREATE OBJECT go_tree
    EXPORTING
      parent                      = go_cust_cont
      node_selection_mode         =
                                cl_gui_column_tree=>node_sel_mode_single
  item_selection              = 'X'
  hierarchy_column_name       = 'DATA'
  hierarchy_header            = ls_header
EXCEPTIONS
  cntl_system_error           = 1
  create_error                = 2
  failed                      = 3
  illegal_node_selection_mode = 4
  illegal_column_name         = 5
  lifetime_error              = 6.
  IF sy-subrc <> 0.
*    MESSAGE a000(/psyng/seam).
  ENDIF.

* Define the events which will be passed to the backend
  ls_event-eventid    = cl_gui_column_tree=>eventid_expand_no_children.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.
  ls_event-eventid    = cl_gui_column_tree=>eventid_link_click.
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
*    MESSAGE a000(/psyng/seam).
  ENDIF.

* Assign event handlers in the application class to each desired event
  SET HANDLER go_application->handle_expand FOR go_tree.
  SET HANDLER go_application->handle_link_click FOR go_tree.

* Insert three additional columns
*-- Header Data
  CALL METHOD go_tree->add_column
    EXPORTING
      name                         = 'HEADER'
      width                        = 60
      alignment                    = cl_gui_column_tree=>align_left
      header_text                  = 'Header Data'(023)
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
*    MESSAGE a000(/psyng/seam).
  ENDIF.

  DEFINE tree_col.
    call method go_tree->add_column
        exporting
          name                         = &1
          header_text                  = &3
          width                        = &2
          alignment                    = cl_gui_column_tree=>align_left
        exceptions
          column_exists                = 1
          illegal_column_name          = 2
          too_many_columns             = 3
          illegal_alignment            = 4
          different_column_types       = 5
          cntl_system_error            = 6
          failed                       = 7
          predecessor_column_not_found = 8.
    if sy-subrc <> 0.
*      message a000(/psyng/seam).
    endif.
  END-OF-DEFINITION.
  tree_col: 'CONFNUM' 13 'Conflicts'(t09).
  IF p_mitcon EQ 'X'.
    tree_col: 'MITINUM' 23 'Mitigated Conflicts'(t10),
              'MITIGATED' 13 'Mitigated'(t08).
  ENDIF.
*--Add data columns
  tree_col :
*    'AGR_NAME' 35 'Role'(c01),
*    'COMP_AGR' 35 'Composite Role'(c08),
    'CHILD_ROLE'  18 'Child Role'(t02),
    'TCODE'    20 'Transaction'(t03),
    'OBJECT'   18 'Object'(t04),
    'FIELD'    18 'Field'(t05),
    'VAL_FROM' 30 'Low Value'(t06),
    'VAL_TO'   30 'High Value'(t07).

*--Add a few hidden columns
  DEFINE tree_hidden_col.
    call method go_tree->add_column
        exporting
          name                         = &1
          header_text                  = ''
          hidden                       = 'X'
          width                        = 1
        exceptions
          column_exists                = 1
          illegal_column_name          = 2
          too_many_columns             = 3
          illegal_alignment            = 4
          different_column_types       = 5
          cntl_system_error            = 6
          failed                       = 7
          predecessor_column_not_found = 8.
    if sy-subrc <> 0.
*      message a000(/psyng/seam).
    endif.
  END-OF-DEFINITION.
  tree_hidden_col : 'NODETYPE',
                    'ROLEINDEX',
                    'CONINDEX',
                    'FUNINDEX',
*                    'GROUPNAME',
                    'CHILDINDEX'.
*                    'SYSINDEX'.
  CALL METHOD go_tree->add_nodes_and_items
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
    MESSAGE e002(/psyng/sw) WITH 'Adding nodes to tree failed'.
  ENDIF.

  CALL METHOD go_tree->expand_root_nodes
    EXPORTING
      level_count         = 2
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      OTHERS              = 4.
  IF sy-subrc <> 0.
*    MESSAGE a000(/psyng/seam).
  ENDIF.
ENDFORM.                    " init_tree_100
*---------------------------------------------------------------------*
*       FORM init_html                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
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
         l_i_resid       TYPE i,
         l_i_setid       TYPE i,
         l_vrsio_txt     TYPE /psyng/desc132,
         l_res_txt       TYPE string,
         l_set_pub       TYPE string,
         l_set_chg       TYPE /psyng/desc132,
         l_set_txt       TYPE /psyng/desc132,
         ls_cfg_set      TYPE /psyng/swcfgset,
         l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR
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
*    MESSAGE a000(/psyng/seam).
  ENDIF.
  CREATE OBJECT go_html
    EXPORTING
      parent = go_html_cont.

  CREATE OBJECT lo_doc
    EXPORTING
      style = 'ALV_GRID'.

  DEFINE add_header_line.

    .
    l_mac_text = &1.
    condense l_mac_text.
    call method lo_col_key->add_text
    exporting text  = l_mac_text
          sap_emphasis = 'STRONG'.               "#EC SAST_CI_GEN_CHECK
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

  WRITE gs_hdr-start_date TO l_date.
  r_bname-sign = 'I'.
  r_bname-option = 'EQ'.
  r_bname-low = gs_hdr-bname.
  COLLECT r_bname.
  CALL FUNCTION '/PSYNG/BC_011'
    TABLES
      it_bname = r_bname
      et_uidn  = lt_uidn.
  READ TABLE lt_uidn INDEX 1.

  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
  CONCATENATE  gs_hdr-bname '(' lt_uidn-name_text ')'
               'on' l_date 'in' l_systemid
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
  l_i_resid = p_aid.
  l_i_setid = gs_hdr-setid.
  l_mac_text = p_aid.
  CONDENSE l_mac_text.
  SHIFT l_mac_text LEFT DELETING LEADING '0'.
  CONCATENATE l_mac_text ':' gs_hdr-description INTO l_res_txt SEPARATED
                                                               BY space.
*--Get version title
  SELECT SINGLE vdesc INTO l_vrsio_txt FROM /psyng/swsodvers
  WHERE vrsio = gs_hdr-sodvrsio.
  CONCATENATE gs_hdr-sodvrsio ':' l_vrsio_txt INTO l_vrsio_txt
              SEPARATED BY space.
*--Get Set info
  SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
  WHERE setid = l_i_setid.
  IF ls_cfg_set-published = 'X'.
    l_set_pub = 'Yes'(h34).
  ELSE.
    l_set_pub = 'No'(h35).
  ENDIF.

  l_mac_text = l_i_setid.
  SHIFT l_mac_text LEFT DELETING LEADING '0'.
  CONDENSE l_mac_text.
  CONCATENATE l_mac_text ':'
  ls_cfg_set-description
  INTO l_set_txt
  SEPARATED BY space.

  WRITE ls_cfg_set-change_date TO l_set_chg.
  CONCATENATE l_set_chg 'by'(h37) ls_cfg_set-change_user
  INTO l_set_chg SEPARATED BY space.



  add_header_line :
    'Result ID:'            l_res_txt
    'User Date & System:'          l_userdate,

    'SOD Version:'          l_vrsio_txt
    'Roles Analyzed:'       gs_hdr-roles_analyzed,

    'Configuration Set:'    l_set_txt
    'Conflicts:'            gs_hdr-conflicts,

    'Config Set Published:' l_set_pub
    ''                      '',
    'Config Set Changed:'   l_set_chg
    ''                      ''.
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

*&---------------------------------------------------------------------*
*&      Form  load_results_summary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_results_summary.
  DATA : ls_node           TYPE treev_node,
         ls_item           TYPE mtreeitm,
         l_role_id         TYPE i,
         l_node_id         TYPE string,
         ls_hdr            TYPE /psyng/swrrshdr,
         l_desc            TYPE string,
         l_head            TYPE string,
         l_icon            TYPE icon_d,
         lt_roles          TYPE TABLE OF /psyng/swrrsrol
                           WITH HEADER LINE,
         l_aid             TYPE char10,
         l_group_id        TYPE i,
         l_groupnode_type  TYPE string,
         l_groupnode_value TYPE string,
         l_groupnode_text  TYPE /psyng/longtext,
*         ls_groupgrptext   TYPE usgrpt-text,
         l_fname           TYPE tfdir-funcname,
         l_con_count(10)   TYPE c,
         lt_sodorgm        TYPE TABLE OF /psyng/swsodorgm
                           WITH HEADER LINE,
         l_num_actual_con  TYPE i,
         l_numcon_part     TYPE i.
  DATA: lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_range_roles TYPE /psyng/range_agr_name.

  RANGES :
    lr_roles      FOR gt_role-roleindex.
*    lr_roles_part FOR gt_role-roleindex.
*    r_agr_name    FOR agr_define-agr_name.

  lr_roles-sign     = 'I'. lr_roles-option     = 'EQ'.
  gr_conflicts-sign = 'I'. gr_conflicts-option = 'EQ'.
  ls_range_roles-sign = 'I'. ls_range_roles-option = 'EQ'.
*--roles
  IF p_all = 'X'.
    SELECT * FROM /psyng/swrrsrol INTO TABLE gt_role
             WHERE aid = p_aid AND
                   agr_name    IN s_role AND
                   nr_conflicts IN s_rnum AND
                   nr_mitigated IN s_rmnum.
  ELSEIF p_rswc = 'X'.
    IF s_rnum IS NOT INITIAL
    OR s_rmnum IS NOT INITIAL.
      SELECT * FROM /psyng/swrrsrol INTO TABLE gt_role
               WHERE aid = p_aid AND
                     agr_name    IN s_role AND
                     nr_conflicts IN s_rnum AND
                     nr_mitigated IN s_rmnum.
    ELSE.
      SELECT * FROM /psyng/swrrsrol INTO TABLE gt_role
               WHERE aid = p_aid AND
                     agr_name    IN s_role AND
                     nr_conflicts > 0 .
    ENDIF.
  ELSE.
    SELECT * FROM /psyng/swrrsrol INTO TABLE gt_role
             WHERE aid = p_aid AND
                   agr_name IN s_role.
    "nr_conflicts = 0.
    LOOP AT gt_role.
      l_num_actual_con = gt_role-nr_conflicts - gt_role-nr_mitigated.
      IF l_num_actual_con > 0.
        DELETE gt_role.
      ENDIF.
    ENDLOOP.
    IF gt_role[] IS INITIAL.
      SELECT SINGLE COUNT(*) FROM /psyng/swrrsrol INTO l_numcon_part
              WHERE aid = p_aid AND
                   nr_conflicts = 0.
      IF l_numcon_part = 0.
        l_aid = p_aid.
        SHIFT l_aid LEFT DELETING LEADING '0'.
        MESSAGE s002 WITH
       'Roles without conflict are not stored'(x12)
       'in the analysis'(x13)
        l_aid.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.
  LOOP AT gt_role.
    lr_roles-low = gt_role-roleindex.
    APPEND lr_roles.
    ls_range_roles-low = gt_role-agr_name.
    APPEND ls_range_roles TO lt_range_roles.
  ENDLOOP.

  SELECT SINGLE * FROM /psyng/swrrshdr INTO ls_hdr
         WHERE aid = p_aid.
  gs_hdr = ls_hdr.
*--Create the root node
  CONCATENATE ls_hdr-description ls_hdr-bname
              ls_hdr-start_date  ls_hdr-start_time
              INTO l_desc SEPARATED BY space.

  CONCATENATE 'Result ID'(r01) p_aid INTO l_head SEPARATED BY space.
  IF  s_role  IS INITIAL
  AND s_rnum   IS INITIAL
  AND s_rmnum  IS INITIAL
  AND gt_role[] IS INITIAL.
    leaf_node gt_node gt_item '' 'R' 'DATA' l_desc l_head '@FN@' ''.
    g_summary_del = 'X'.
    EXIT.
  ENDIF.

  child_node gt_node gt_item '' 'R' 'DATA' l_desc l_head '' ''.
*--Systems
  SELECT * FROM /psyng/sw_rfcdes INTO TABLE gt_sysinfo
  WHERE systid = gs_hdr-sysid.
*--Filter roles based on single roles/ comp roles/ assigned roles
  READ TABLE gt_sysinfo INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
  CALL FUNCTION 'RFC_CALLBACK_REJECTED'
       EXCEPTIONS
         invalid_reject_option        = 1
         invalid_reject_state         = 2
         function_not_supported       = 3
         internal_error               = 4
         OTHERS                       = 5
                .
  IF sy-subrc NE 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION gt_sysinfo-rfcdest
    EXPORTING
      i_composite_roles = p_comp
      i_single_roles    = p_sing
      i_assigned_roles  = p_assr
      i_get_actual_data = 'X'
    TABLES
      it_roles          = lt_range_roles
      it_ba             = rba
      et_roles          = gt_roles_info
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
        EXCEPTIONS
          system_failure        = 1
          communication_failure = 2
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
      WHEN 2.
        MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
    ENDCASE.
  ENDIF.
*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025

*EOC:HBHALLA (04/12/24)

  SORT gt_roles_info BY agr_name.

  LOOP AT gt_role.
    READ TABLE gt_roles_info WITH KEY agr_name = gt_role-agr_name
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE gt_role  WHERE agr_name = gt_role-agr_name.
      DELETE lr_roles WHERE low = gt_role-roleindex.
    ENDIF.
  ENDLOOP.

  IF gt_role[] IS INITIAL.
    MESSAGE s002 WITH
   'No roles match selection criteria'(x04).
    LEAVE LIST-PROCESSING.
  ENDIF.

*--Conflicts
  SELECT * FROM /psyng/swrrsicon INTO TABLE gt_conflict
           WHERE aid   =   p_aid AND
                 conid IN  s_conid.
  LOOP AT gt_conflict.
    gr_conflicts-low = gt_conflict-conindex.
    APPEND gr_conflicts.
  ENDLOOP.
  IF gr_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
    gr_conflicts-sign   = 'E'.
    gr_conflicts-option = 'GT'.
    gr_conflicts-low    = '0'.
    APPEND gr_conflicts.
  ENDIF.


  IF NOT s_conid[] IS INITIAL AND p_rswc = 'X'.
*--Filter by conflicts was used, remove roles that don't have any of these conflicts
DATA : lt_rrscon TYPE HASHED TABLE OF /psyng/swrrscon WITH UNIQUE KEY roleindex.
    SELECT DISTINCT roleindex FROM /psyng/swrrscon
      INTO CORRESPONDING FIELDS OF TABLE lt_rrscon
       WHERE
        aid       =   p_aid AND
        roleindex IN  lr_roles AND
        conindex  IN  gr_conflicts.
    LOOP AT lr_roles.
READ TABLE lt_rrscon WITH TABLE KEY roleindex = lr_roles-low TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_role  WHERE roleindex = lr_roles-low.
        DELETE lr_roles WHERE low = lr_roles-low.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--If include mitigated conflicts is not selected,
**--remove roles that don't have any of unmitigated conflict
**--Also remove conflicts; if not present in any role
  IF p_mitcon IS INITIAL.
    DATA : lt_rrscon_rol TYPE SORTED TABLE OF ty_swrrscon
           WITH NON-UNIQUE KEY roleindex,
           lt_rrscon_tmp TYPE SORTED TABLE OF ty_swrrscon
           WITH NON-UNIQUE KEY conindex.
    IF NOT s_conid[] IS INITIAL.
      SELECT roleindex conindex FROM /psyng/swrrscon
        INTO TABLE lt_rrscon_rol
         WHERE
          aid       =   p_aid AND
          roleindex IN  lr_roles AND
          conindex  IN gr_conflicts AND
          mitigated = p_mitcon.
    ELSE.
      SELECT roleindex conindex FROM /psyng/swrrscon
        INTO TABLE lt_rrscon_rol
         WHERE
          aid       =   p_aid AND
          roleindex IN  lr_roles AND
          mitigated = p_mitcon.
    ENDIF.
    IF p_rswc EQ 'X'.
      LOOP AT lr_roles.
READ TABLE lt_rrscon_rol WITH TABLE KEY roleindex = lr_roles-low TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE gt_role WHERE roleindex = lr_roles-low.
          DELETE lr_roles WHERE low = lr_roles-low.
        ENDIF.
      ENDLOOP.
    ENDIF.
    lt_rrscon_tmp = lt_rrscon_rol.
    LOOP AT gt_conflict.
READ TABLE lt_rrscon_tmp WITH TABLE KEY conindex = gt_conflict-conindex TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_conflict WHERE conindex = gt_conflict-conindex.
        DELETE gr_conflicts WHERE low = gt_conflict-conindex.
      ENDIF.
    ENDLOOP.
    IF gr_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
      gr_conflicts-sign   = 'E'.
      gr_conflicts-option = 'GT'.
      gr_conflicts-low    = '0'.
      APPEND gr_conflicts.
    ENDIF.
  ENDIF.
  IF gt_role[] IS INITIAL.
    MESSAGE s002 WITH
    'No roles match selection criteria'(x04).
    LEAVE LIST-PROCESSING.
  ENDIF.
*--Load variable elements in SOD Matrix
  SELECT * FROM /psyng/faobj2 INTO TABLE gt_varel WHERE
    vrsio     = ls_hdr-sodvrsio AND
    val_from  LIKE '/PSYNG/$%'
    ORDER BY funid tcode object field val_from.
*--Load Org Elements in SOD Matrix
  FREE : gt_sodorgm.
  CALL FUNCTION '/PSYNG/SW_AO_READ_VALUES'
    EXPORTING
      i_vrsio      = ls_hdr-sodvrsio
      i_setid      = ls_hdr-setid
      i_sysid      = ls_hdr-sysid "gt_system-sysid
    TABLES
      et_swsodorgm = lt_sodorgm.
  SORT lt_sodorgm BY object varbl.
  DELETE ADJACENT DUPLICATES FROM lt_sodorgm COMPARING object varbl.
  gt_sodorgm-sysid = ls_hdr-sysid."gt_system-sysid.
  gt_sodorgm-sodorgm[] = lt_sodorgm[].
  APPEND gt_sodorgm.
  SORT gt_sodorgm BY sysid.

*  LOOP AT gt_role.
*    ls_range_roles-low = gt_role-agr_name.
*    APPEND ls_range_roles TO lt_range_roles.
*  ENDLOOP.
*  READ TABLE gt_sysinfo INDEX 1.
*  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
*    DESTINATION gt_sysinfo-rfcdest
*    EXPORTING
*      i_composite_roles = 'X'
*      i_single_roles    = 'X'
*      i_get_actual_data = 'X'
*    TABLES
*      it_roles          = lt_range_roles
*      et_roles          = gt_roles_info.
*SORT gt_roles_info BY agr_name.
*  ENDIF.
ENDFORM.                    " load_results_summary

*&---------------------------------------------------------------------*
*&      Module  init_100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE init_100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR  '100'.
  CLEAR sy-ucomm.

  IF go_tree IS INITIAL.
    PERFORM init_tree_100.
*  --No grouping was requested
*    show all roles nodes
    IF g_summary_del IS INITIAL.
      PERFORM expand_group USING 'R_DATA'.
    ENDIF.
  ENDIF.
  IF go_html IS INITIAL.
    PERFORM init_html.
  ENDIF.

ENDMODULE.                 " init_100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  pai_100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE pai_100 INPUT.
  DATA: lt_resultset TYPE TABLE OF /psyng/swrrshdr.

  IF sy-ucomm = 'EXIT'.
    SET SCREEN 0.
    LEAVE SCREEN.

  ELSEIF sy-ucomm = 'EXPAND'.
    CALL SCREEN '0101' STARTING AT 10 1.

  ELSEIF sy-ucomm = 'FIND'.
    CLEAR: g_start_pos, g_start_con_pos,
           gf_fnd_conid, gf_fnd_funid, gf_fnd_role.
    CALL SCREEN '0102' STARTING AT 10 1.
  ELSEIF sy-ucomm = 'FINDNEXT'.
    IF g_start_pos IS INITIAL.
      IF gf_fnd_role IS INITIAL.
     MESSAGE i002(/psyng/sw) WITH 'There is no find performed yet'(i01).
      ELSE.
        MESSAGE s002(/psyng/sw) WITH 'No match found'(i02).
      ENDIF.
    ELSE.
      PERFORM find_node USING g_start_pos g_start_con_pos.
    ENDIF.
  ELSEIF sy-ucomm = 'EXPORT'.
* BOC by AKUMAR for C0765
    PERFORM get_selected_node CHANGING g_node_key.

    IF g_node_key IS INITIAL.
      MESSAGE i398(00) WITH text-e02 text-e03.
      EXIT.
    ELSE.
      CALL SCREEN '0103' STARTING AT 10 1.
    ENDIF.
* EOC by AKUMAR for C0765
  ELSEIF sy-ucomm = 'ANA_DTL'.
    SELECT * FROM /psyng/swrrshdr INTO TABLE lt_resultset
    WHERE aid = p_aid.
*---show popup with detail
    IF NOT lt_resultset[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_STORED_RSLT_DETAILS'
        EXPORTING
          i_role_aid        = p_aid
          if_role           = 'X'
        TABLES
          it_role_resultset = lt_resultset.
    ENDIF.
  ELSEIF sy-ucomm = 'EXP_LVL'.
    PERFORM expand_next_level.
  ENDIF.
ENDMODULE.                 " pai_100  INPUT


*---------------------------------------------------------------------*
*       FORM expand_group                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_group USING    i_node_key TYPE tv_nodekey.
  DATA : ls_role       TYPE mtreeitm,
         lt_rolecon    TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
         ls_node       TYPE treev_node,
         ls_item       TYPE mtreeitm,
         lt_node       TYPE treev_ntab,
         lt_item       TYPE ttree_item,
         lt_roles      TYPE TABLE OF /psyng/swrrsrol WITH HEADER LINE,
         l_icon        TYPE icon_d,
         l_icon_i      TYPE char4,
         ls_roles_info TYPE /psyng/comp_role_tcode.

*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
    lt_roles[] = gt_role[].
**--Create the role nodes
    LOOP AT lt_roles.
      ADD 1 TO g_role_id.
      READ TABLE gt_roles_info INTO ls_roles_info
        WITH KEY agr_name = lt_roles-agr_name
        BINARY SEARCH.
      IF sy-subrc EQ 0.
        IF ls_roles_info-child_agr IS INITIAL.
          l_icon_i = '@IC@'.
        ELSE.
          l_icon_i = '@M7@'.
        ENDIF.
      ENDIF.
      IF lt_roles-nr_conflicts > 0 OR
         lt_roles-nr_mitigated > 0.
        IF lt_roles-nr_conflicts = lt_roles-nr_mitigated
        AND p_mitcon IS INITIAL.
*  -- none expandable node
          leaf_node_inactive lt_node lt_item i_node_key 'S' g_role_id
          lt_roles-agr_name lt_roles-agr_text  l_icon_i l_icon.
          text_column lt_item ls_node-node_key
           'CONFNUM'   lt_roles-nr_conflicts '' 'X'.
        ELSE.
*-- add expandable node
          child_node lt_node lt_item i_node_key 'S' g_role_id
          lt_roles-agr_name lt_roles-agr_text  l_icon_i l_icon.
          IF NOT lt_roles-nr_conflicts IS INITIAL.
            text_column lt_item ls_node-node_key
            'CONFNUM'   lt_roles-nr_conflicts '' ''.
          ENDIF.
          IF NOT lt_roles-nr_mitigated IS INITIAL
          AND p_mitcon EQ 'X'.
            text_column lt_item ls_node-node_key
            'MITINUM'   lt_roles-nr_mitigated '' ''.
          ENDIF.
        ENDIF.
      ELSE.
*-- none expandable node
        leaf_node_inactive lt_node lt_item i_node_key 'S' g_role_id
        lt_roles-agr_name lt_roles-agr_text  l_icon_i l_icon.
      ENDIF.

      hidden_column lt_item ls_node-node_key
        'NODETYPE'   'AGR_NAME'.
      hidden_column lt_item ls_node-node_key
        'ROLEINDEX'  lt_roles-roleindex.

    ENDLOOP.



    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
      MESSAGE e002(/psyng/sw) WITH 'Adding Role nodes to tree failed'.
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.

  CALL METHOD go_tree->expand_node
    EXPORTING
      node_key            = i_node_key
      level_count         = 1
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5
      OTHERS              = 6.
  IF sy-subrc <> 0.

*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " expand_role


*&---------------------------------------------------------------------*
*&      Form  expand_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_NODE_KEY  text
*----------------------------------------------------------------------*
FORM expand_role USING    i_node_key TYPE tv_nodekey.
  DATA : ls_role        TYPE mtreeitm,
         lt_rolecon     TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
         ls_node        TYPE treev_node,
         ls_item        TYPE mtreeitm,
         lt_node        TYPE treev_ntab,
         lt_item        TYPE ttree_item,
         l_cdescription TYPE /psyng/rskdsc,
         lt_conflicts   TYPE TABLE OF /psyng/swrrsicon WITH HEADER LINE.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
    READ TABLE gt_item INTO ls_role
         WITH KEY node_key  = i_node_key
                  item_name = 'ROLEINDEX'.
*--Role Conflicts
    IF p_mitcon EQ 'X'.
      SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
               WHERE aid       =  p_aid AND
                     roleindex =  ls_role-text AND
                     conindex  IN gr_conflicts.
    ELSE.
      SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
               WHERE aid       =  p_aid AND
                     roleindex =  ls_role-text AND
                     conindex  IN gr_conflicts
                 AND mitigated = p_mitcon.
    ENDIF.
    CHECK sy-subrc EQ 0.
    SORT lt_rolecon BY conindex.
*--Collect the conflicts sorted by conflict ID
    REFRESH : lt_conflicts.
    LOOP AT lt_rolecon.
      READ TABLE gt_conflict WITH KEY conindex = lt_rolecon-conindex.
      APPEND gt_conflict TO lt_conflicts.
    ENDLOOP.
    SORT lt_conflicts BY conid.
    LOOP AT lt_conflicts.
      READ TABLE lt_rolecon WITH KEY conindex = lt_conflicts-conindex
      BINARY SEARCH.
      ADD 1 TO g_rolecon_id.
      PERFORM get_text_conflict USING    lt_conflicts-conid
                                CHANGING l_cdescription.


      child_node lt_node lt_item i_node_key 'C'
              g_rolecon_id lt_conflicts-conid l_cdescription '@9O@' '' .
      IF  p_mitcon EQ 'X'
      AND NOT lt_rolecon-mitigated IS INITIAL.
        link_column lt_item ls_node-node_key
              'MITIGATED'   lt_rolecon-mitigated ''.
      ENDIF.

      hidden_column lt_item ls_node-node_key
        'NODETYPE'   'ROLECON'.
      hidden_column lt_item ls_node-node_key
        'CONINDEX' lt_rolecon-conindex.

    ENDLOOP.

    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
    MESSAGE e002(/psyng/sw) WITH 'Adding Conflict nodes to tree failed'.
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.

  CALL METHOD go_tree->expand_node
    EXPORTING
      node_key            = i_node_key
      level_count         = 1
*     EXPAND_SUBTREE      =
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5
      OTHERS              = 6.
  IF sy-subrc <> 0.

*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " expand_role


*---------------------------------------------------------------------*
*       FORM expand_rolecon                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_rolecon USING    i_node_key TYPE tv_nodekey.
  DATA : ls_con         TYPE mtreeitm,
         lt_confun      TYPE TABLE OF /psyng/swrrscfun WITH HEADER LINE,
         ls_function    TYPE /psyng/swrrsifun,
         ls_node        TYPE treev_node,
         ls_item        TYPE mtreeitm,
         lt_node        TYPE treev_ntab,
         lt_item        TYPE ttree_item,
         l_fdescription TYPE /psyng/fundsc.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
    READ TABLE gt_item INTO ls_con
         WITH KEY node_key  = i_node_key
                  item_name = 'CONINDEX'.
*--User Conflict functions
    SELECT * FROM /psyng/swrrscfun  INTO TABLE lt_confun
             WHERE aid       =  p_aid AND
                   conindex  = ls_con-text.
    LOOP AT lt_confun.
      PERFORM get_function_by_index
              USING
                 lt_confun-funindex
              CHANGING
                 ls_function.

      ADD 1 TO g_confun_id.
      PERFORM get_text_function USING ls_function-funid
                                CHANGING l_fdescription.
      IF p_fun = 'X'.
        leaf_node lt_node lt_item i_node_key 'F' g_confun_id
         ls_function-funid l_fdescription '@XC@' '' .
      ELSE.
        child_node lt_node lt_item i_node_key 'F' g_confun_id
        ls_function-funid l_fdescription '@XC@' '' .
      ENDIF.
      hidden_column lt_item ls_node-node_key
        'NODETYPE'   'CONFUN'.
      hidden_column lt_item ls_node-node_key
        'FUNINDEX' lt_confun-funindex.

    ENDLOOP.


    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
    MESSAGE e002(/psyng/sw) WITH 'Adding Function nodes to tree failed'.
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.

  CALL METHOD go_tree->expand_node
    EXPORTING
      node_key            = i_node_key
      level_count         = 1
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5
      OTHERS              = 6.
  IF sy-subrc <> 0.

*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " expand_rolecon

*---------------------------------------------------------------------*
*       FORM expand_function                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_function USING    i_node_key TYPE tv_nodekey.
  DATA : ls_fun       TYPE mtreeitm,
         ls_con       TYPE mtreeitm,
         ls_role      TYPE mtreeitm,
*         lt_roles     TYPE SORTED TABLE OF /psyng/swrrsrol
*                      WITH HEADER LINE WITH UNIQUE KEY roleindex,
*         lt_childrole TYPE SORTED TABLE OF /psyng/swrrsrchd
*                      WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
*       sorting lt_comprole by compindex instead of roleindex,
*         ls_roles     TYPE /psyng/swrrsrol,
*         ls_childrole TYPE /psyng/swrrsichd,
*         lt_profiles TYPE TABLE OF /psyng/swresipro,
         lt_authdet   TYPE TABLE OF /psyng/serrs_authdetail
                      WITH HEADER LINE,
*         lt_authdet_all  TYPE TABLE OF /psyng/seres_authdetail
*                     WITH HEADER LINE,
         ls_function  TYPE /psyng/swrrsifun,
         ls_node      TYPE treev_node,
         ls_item      TYPE mtreeitm,
         lt_node      TYPE treev_ntab,
         ls_connode   TYPE treev_node,
         ls_funnode   TYPE treev_node,
         ls_rolenode  TYPE treev_node,
         lt_item      TYPE ttree_item,
         l_funindex   TYPE /psyng/seres_funindex,
         l_roleinndex TYPE /psyng/seres_roleindex,
*         lt_funprofile TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
         lt_expand    TYPE treev_nks,
         lt_orgabb    TYPE  TABLE OF /psyng/swrrsiabb
          WITH HEADER LINE ,
         l_numfun     TYPE i,
         lt_rabb TYPE TABLE OF /psyng/swrrsrabb. "AKUMAR

  RANGES : lr_funid FOR l_funindex.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  APPEND i_node_key TO lt_expand.

  IF gf_node_has_children <> 'X'.
*--Get function index value
    READ TABLE gt_item INTO ls_fun
         WITH KEY node_key  = i_node_key
                  item_name = 'FUNINDEX'.
*--Get the roleid, 2 nodes up
    READ TABLE gt_node
    INTO ls_funnode
    WITH KEY node_key = i_node_key.

    READ TABLE gt_node
    INTO ls_connode
    WITH KEY node_key = ls_funnode-relatkey.

    READ TABLE gt_item INTO ls_con
         WITH KEY node_key  = ls_connode-node_key
                  item_name = 'CONINDEX'.

    READ TABLE gt_node
    INTO ls_rolenode
    WITH KEY node_key = ls_connode-relatkey.
*--Get role index value
    READ TABLE gt_item INTO ls_role
       WITH KEY node_key  = ls_rolenode-node_key
                item_name = 'ROLEINDEX'.
*--Get the role for this function
    l_funindex = ls_fun-text.
    l_roleinndex = ls_role-text.


*--Get the org area abreviations
* for this function
* for this user
* for this conflict

*--Get the range of functions for this conflicy
    SELECT funindex AS low FROM /psyng/swrrscfun
    INTO CORRESPONDING FIELDS OF TABLE lr_funid
     WHERE aid      = g_aid AND
           conindex = ls_con-text.               "#EC SAST_CI_GEN_CHECK
    lr_funid-sign   = 'I'.
    lr_funid-option = 'EQ'.
    MODIFY    lr_funid  FROM lr_funid
      TRANSPORTING sign option
      WHERE sign IS INITIAL .
    DESCRIBE TABLE lr_funid LINES l_numfun.

    SELECT i~org_abb COUNT( DISTINCT u~funindex ) AS abbindex
    FROM /psyng/swrrsiabb AS i
    INNER JOIN /psyng/swrrsrabb AS u ON
       u~aid            = i~aid AND
       u~abbindex       = i~abbindex
    INTO CORRESPONDING FIELDS OF
      TABLE lt_orgabb

      WHERE u~aid       = p_aid AND
            u~roleindex = l_roleinndex AND
            u~funindex  IN lr_funid
      GROUP BY i~org_abb.                        "#EC SAST_CI_GEN_CHECK

*BOC:AKUMAR (PN-13314)
    SELECT * FROM /psyng/swrrsrabb INTO TABLE lt_rabb WHERE aid = g_aid.

    LOOP AT lr_funid.
      READ TABLE lt_rabb WITH KEY funindex = lr_funid-low
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        l_numfun = l_numfun - 1.
      ENDIF.
    ENDLOOP.
*EOC:AKUMAR (PN-13314)

    DELETE lt_orgabb WHERE abbindex <>    l_numfun.
    SORT lt_orgabb BY org_abb.

**--Get the function's profiles
*
*
**--One step approach with joins
*  SELECT * FROM /psyng/swresupr  AS up
*  INNER JOIN /psyng/swresfpr AS fp
*    ON
*      fp~aid          = up~aid AND
*      fp~profileindex = up~profileindex AND
*      fp~sys          = up~sys
*  INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
*  WHERE fp~aid          = p_aid AND
*         up~userindex    = l_userinndex AND
*         fp~funindex     = l_funindex.


*--Get the roles
*  IF NOT lt_usrprof[] IS INITIAL.
*
*    SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
*      FOR ALL ENTRIES IN
*        lt_usrprof
*    WHERE aid       = p_aid AND
**              sys       = lt_usrprof-sys and
*          profindex = lt_usrprof-profileindex.
*
*    SELECT * FROM /psyng/swresprol
*    INTO TABLE lt_profrole
*    FOR ALL ENTRIES IN lt_usrprof
*    WHERE aid       = p_aid AND
**              sys       = lt_usrprof-sys and
*          profindex = lt_usrprof-profileindex.
*    IF NOT lt_profrole[] IS INITIAL.
*      SELECT * FROM /psyng/swresirol
*      INTO TABLE lt_roles
*      FOR ALL ENTRIES IN lt_profrole
*        WHERE aid = p_aid AND
*              roleindex = lt_profrole-roleindex.
*      IF NOT lt_roles[] IS INITIAL.
**--Get any composite role through which these roles may be assigned
*        SELECT * FROM /psyng/swresucom
*        INTO TABLE lt_comprole
*        FOR ALL ENTRIES IN lt_roles WHERE
*          aid = p_aid AND
*          userindex = l_userinndex AND
*          roleindex = lt_roles-roleindex.
*        IF NOT lt_comprole[] IS INITIAL.
*          SELECT * FROM /psyng/swresirol
*          APPENDING TABLE lt_roles
*          FOR ALL ENTRIES IN lt_comprole
*            WHERE aid = p_aid AND
*                  roleindex = lt_comprole-compindex.
*        ENDIF.
*      ENDIF.
*    ENDIF.

*  ENDIF.

*  LOOP AT lt_usrprof.
    REFRESH : lt_authdet.
    CALL FUNCTION '/PSYNG/SW_SE_ROL_EXPAND_CAUT'
      EXPORTING
        i_aid          = p_aid
        i_funindex     = l_funindex
        i_roleindex    = l_roleinndex
      TABLES
        et_roledetails = lt_authdet.
*    APPEND LINES OF lt_authdet TO lt_authdet_all.

*    MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
*    APPEND gt_output_alv.

*    REFRESH : lt_authdet.

*  ENDLOOP.
    PERFORM add_function_detail_nodes
    TABLES
      lt_authdet
*    lt_profiles
      lt_node
      lt_item
      lt_orgabb
    USING
      lt_expand[]
      i_node_key.
*    lt_comprole[]
*    lt_profrole[]
*    lt_roles[].

    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
     MESSAGE e002(/psyng/sw) WITH 'Adding Function nodes to tree failed'
 .
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.
  CALL METHOD go_tree->expand_nodes
    EXPORTING
      node_key_table = lt_expand.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " expand_function



*---------------------------------------------------------------------*
*       FORM expand_varel                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_varel USING    i_node_key TYPE tv_nodekey.
  DATA : lt_node     TYPE treev_ntab,
         lt_item     TYPE ttree_item,
         ls_funnode  TYPE treev_node,
         ls_connode  TYPE treev_node,
         ls_node     TYPE treev_node,
         ls_rolenode TYPE treev_node,
         ls_fun      TYPE mtreeitm,
         ls_role     TYPE mtreeitm,
*         ls_prof       TYPE mtreeitm,
*         ls_sys        TYPE mtreeitm,
         ls_obj      TYPE mtreeitm,
         ls_tcode    TYPE mtreeitm,
         ls_field    TYPE mtreeitm,
*         l_sysindex    TYPE i,
         l_funindex  TYPE i,
         l_roleindex TYPE i,
         lt_authdet  TYPE TABLE OF /psyng/serrs_authdetail
                     WITH HEADER LINE.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
*--Get the parent funindex,2 levels up
    READ TABLE gt_node
    INTO ls_funnode
    WITH KEY node_key = i_node_key.

    READ TABLE gt_node
    INTO ls_funnode
    WITH KEY node_key = ls_funnode-relatkey.

*--Get function index value
    READ TABLE gt_item INTO ls_fun
         WITH KEY node_key  = ls_funnode-node_key
                  item_name = 'FUNINDEX'.
*--Possibly this is a composite role, go one more level up
*  IF sy-subrc <> 0.
*    READ TABLE gt_node
*    INTO ls_funnode
*    WITH KEY node_key = ls_funnode-relatkey.
*
**  --Get function index value
*    READ TABLE gt_item INTO ls_fun
*         WITH KEY node_key  = ls_funnode-relatkey
*                  item_name = 'FUNINDEX'.
*  ENDIF.

    READ TABLE gt_node
    INTO ls_connode
    WITH KEY node_key = ls_funnode-relatkey.

    READ TABLE gt_node
    INTO ls_rolenode
    WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
    READ TABLE gt_item INTO ls_role
       WITH KEY node_key  = ls_rolenode-node_key
                item_name = 'ROLEINDEX'.
*--Get the profile
*  READ TABLE gt_item INTO ls_prof
*       WITH KEY node_key  = i_node_key
*                item_name = 'PROFINDEX'.
*--Get the system
*  READ TABLE gt_item INTO ls_sys
*       WITH KEY node_key  = i_node_key
*                item_name = 'SYSINDEX'.

    l_funindex  = ls_fun-text.
*  l_sysindex  = ls_sys-text.
    l_roleindex = ls_role-text.

**--Get object
*  READ TABLE gt_item INTO ls_obj
*       WITH KEY node_key  = i_node_key
*                item_name = 'OBJECT'.
**--Get Tcode
*  READ TABLE gt_item INTO ls_tcode
*       WITH KEY node_key  = i_node_key
*                item_name = 'TCODE'.
*--Get Field
    READ TABLE gt_item INTO ls_field
         WITH KEY node_key  = i_node_key
                  item_name = 'FIELD'.




    CALL FUNCTION '/PSYNG/SW_SE_ROL_EXPAND_CAUT'
      EXPORTING
        i_aid          = p_aid
        i_funindex     = l_funindex
        i_roleindex    = l_roleindex
      TABLES
        et_roledetails = lt_authdet.
    LOOP AT lt_authdet.
      IF "lt_authdet-tcode  = ls_tcode-text AND
         "lt_authdet-object = ls_obj-text AND
         lt_authdet-field  = ls_field-text.
        PERFORM add_auth_node
          TABLES
            lt_node
            lt_item
          USING
            i_node_key
            lt_authdet
          CHANGING
            ls_node.

      ENDIF.


    ENDLOOP.





    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
      MESSAGE e002(/psyng/sw) WITH 'Adding Role nodes to tree failed'.
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.

  CALL METHOD go_tree->expand_node
    EXPORTING
      node_key            = i_node_key
      level_count         = 1
*     EXPAND_SUBTREE      =
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5
      OTHERS              = 6.
  IF sy-subrc <> 0.

*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " expand_bname

*---------------------------------------------------------------------*
*       FORM expand_org                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_org USING    i_node_key TYPE tv_nodekey.
  DATA : lt_node     TYPE treev_ntab,
         lt_item     TYPE ttree_item,
         ls_funnode  TYPE treev_node,
         ls_connode  TYPE treev_node,
         ls_node     TYPE treev_node,
         ls_rolenode TYPE treev_node,
         ls_fun      TYPE mtreeitm,
         ls_role     TYPE mtreeitm,
*         ls_prof       TYPE mtreeitm,
*         ls_sys        TYPE mtreeitm,
         ls_obj      TYPE mtreeitm,
         ls_tcode    TYPE mtreeitm,
         ls_field    TYPE mtreeitm,
*         l_sysindex    TYPE i,
         l_funindex  TYPE i,
         l_roleindex TYPE i,
         lt_authdet  TYPE TABLE OF /psyng/serrs_authdetail
                     WITH HEADER LINE.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
*--Get the parent funindex,1 levels up
    READ TABLE gt_node
    INTO ls_funnode
    WITH KEY node_key = i_node_key.

    READ TABLE gt_node
    INTO ls_funnode
    WITH KEY node_key = ls_funnode-relatkey.

*--Get function index value
    READ TABLE gt_item INTO ls_fun
         WITH KEY node_key  = ls_funnode-node_key
                  item_name = 'FUNINDEX'.
*--Possibly this is a composite role, go one more level up
*  IF sy-subrc <> 0.
*    READ TABLE gt_node
*    INTO ls_funnode
*    WITH KEY node_key = ls_funnode-relatkey.
*
**  --Get function index value
*    READ TABLE gt_item INTO ls_fun
*         WITH KEY node_key  = ls_funnode-relatkey
*                  item_name = 'FUNINDEX'.
*  ENDIF.

*--Get the userid, 2 nodes up
*  READ TABLE gt_node
*  INTO ls_funnode
*  WITH KEY node_key = ls_funnode-node_key.

    READ TABLE gt_node
    INTO ls_connode
    WITH KEY node_key = ls_funnode-relatkey.

    READ TABLE gt_node
    INTO ls_rolenode
    WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
    READ TABLE gt_item INTO ls_role
       WITH KEY node_key  = ls_rolenode-node_key
                item_name = 'ROLEINDEX'.
**--Get the profile
*  READ TABLE gt_item INTO ls_prof
*       WITH KEY node_key  = i_node_key
*                item_name = 'PROFINDEX'.
**--Get the system
*  READ TABLE gt_item INTO ls_sys
*       WITH KEY node_key  = i_node_key
*                item_name = 'SYSINDEX'.

    l_funindex  = ls_fun-text.
*  l_sysindex  = ls_sys-text.
    l_roleindex = ls_role-text.

*--Get abb
    READ TABLE gt_item INTO ls_obj
         WITH KEY node_key  = i_node_key
                  item_name = 'DATA'.
**--Get Tcode
*  READ TABLE gt_item INTO ls_tcode
*       WITH KEY node_key  = i_node_key
*                item_name = 'TCODE'.
**--Get Field
*  READ TABLE gt_item INTO ls_field
*       WITH KEY node_key  = i_node_key
*                item_name = 'FIELD'.




    CALL FUNCTION '/PSYNG/SW_SE_ROL_EXPAND_CAUT'
      EXPORTING
        i_aid          = p_aid
        i_funindex     = l_funindex
        i_roleindex    = l_roleindex
      TABLES
        et_roledetails = lt_authdet.
    LOOP AT lt_authdet.
      IF lt_authdet-abb    = ls_obj-text.
        PERFORM add_auth_node
          TABLES
            lt_node
            lt_item
          USING
            i_node_key
            lt_authdet
          CHANGING
            ls_node.

      ENDIF.


    ENDLOOP.





    CALL METHOD go_tree->add_nodes_and_items
      EXPORTING
        node_table                     = lt_node
        item_table                     = lt_item
        item_table_structure_name      = 'MTREEITM'
      EXCEPTIONS
        failed                         = 1
        cntl_system_error              = 2
        error_in_tables                = 3
        dp_error                       = 4
        table_structure_name_not_found = 5.
    IF sy-subrc <> 0.
      MESSAGE e002(/psyng/sw) WITH 'Adding Role nodes to tree failed'.
    ENDIF.
    APPEND LINES OF lt_node TO gt_node.
    APPEND LINES OF lt_item TO gt_item.
  ENDIF.

  CALL METHOD go_tree->expand_node
    EXPORTING
      node_key            = i_node_key
      level_count         = 1
*     EXPAND_SUBTREE      =
    EXCEPTIONS
      failed              = 1
      illegal_level_count = 2
      cntl_system_error   = 3
      node_not_found      = 4
      cannot_expand_leaf  = 5
      OTHERS              = 6.
  IF sy-subrc <> 0.

*     MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*                WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM tree_check_node_type                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*  -->  I_ITEM_NAME                                                   *
*  -->  E_NODE_TYPE                                                   *
*---------------------------------------------------------------------*
FORM tree_check_node_type  USING    i_node_key
                                  i_item_name
                         CHANGING e_node_type.
*  data : ls_item like line of gt_item.
*  read table gt_item with key node_key  = i_node_key
*                               item_name = 'NODETYPE'
*  into ls_item transporting text.
*  e_node_type = ls_item-text.
  tree_get_col_val i_node_key 'NODETYPE'  e_node_type.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  add_function_detail_nodes
*&---------------------------------------------------------------------*
*       Adds all composite and role nodes with their details
*       To the output
*       The values for the variable elements and org areas should not be
*       added yet
*----------------------------------------------------------------------*
*      -->P_LT_AUTHDET_ALL  text
*      -->P_LT_COMPROLE  text
*      -->P_LT_PROFROLE  text
*      -->P_LT_ROLES  text
*      -->P_LT_NODE  text
*      -->P_LT_ITEM  text
*----------------------------------------------------------------------*
FORM add_function_detail_nodes
TABLES   it_authdet_all STRUCTURE  /psyng/serrs_authdetail
*         it_profiles    STRUCTURE  /psyng/swresipro
         et_node        STRUCTURE  treev_node
         et_item        STRUCTURE  mtreeitm
         it_abb         STRUCTURE  /psyng/swresiabb
USING
         et_expand      TYPE treev_nks
         i_parent       TYPE tv_nodekey.
*         it_comprole    TYPE ttyp_comprol
*         it_profrole    TYPE ttyp_profile
*         it_roles       TYPE ttyp_roles.
  DATA : "ls_comprole    LIKE LINE OF it_comprole,
*         ls_profrole    LIKE LINE OF it_profrole,
*         ls_role        LIKE LINE OF it_roles,
    ls_node        TYPE treev_node,
    ls_item        TYPE mtreeitm,
*           l_comp_role_text TYPE agr_texts-text,
    l_destination  TYPE rfcdes-rfcdest,
    l_pre_comprole TYPE agr_define-agr_name,
    lt_comprole    TYPE TABLE OF /psyng/swresucom
  WITH HEADER LINE.
*---check for function detail level expand
  CHECK p_fun <> 'X'.

*  CLEAR l_destination.
*--sorting it_comprole by compindex
*  lt_comprole[] = it_comprole[].
*  SORT lt_comprole BY compindex.

*  LOOP AT lt_comprole   INTO ls_comprole.
*    ADD 1 TO g_auth_id.
*   READ TABLE it_roles WITH TABLE KEY roleindex = ls_comprole-compindex
*                                                          INTO ls_role.
*--    destination
*    READ TABLE it_authdet_all INDEX 1.

*    SELECT SINGLE rfcdest FROM /psyng/sw_rfcdes INTO (l_destination)
*    WHERE systid = it_authdet_all-sysid.
*
*    CALL FUNCTION '/PSYNG/BC_021'
*    DESTINATION l_destination
*         EXPORTING
*              i_agr_name = ls_role-agr_name
*         IMPORTING
*              e_text     = l_comp_role_text.

*---role profile checkbox checked in expand option
*    IF p_rolpro = 'X'.
*      leaf_node et_node et_item i_parent 'CR' g_auth_id
*             ls_role-agr_name l_comp_role_text '@M7@' ''.
*    ELSE.
*    IF l_pre_comprole <> ls_role-agr_name.
*      child_node et_node et_item i_parent 'CR' g_auth_id
*         ls_role-agr_name l_comp_role_text '@M7@' ''.
*      APPEND ls_node-node_key TO et_expand.
*      l_pre_comprole = ls_role-agr_name.
*    ENDIF.
*--Add child roles
*    PERFORM add_role_nodes
*    TABLES
*        it_authdet_all
*        it_profiles
*        et_node
*        et_item
*        it_abb
*      USING
*        et_expand[]
*        ls_node-node_key
*        ls_comprole-roleindex
*        it_comprole[]
*        it_profrole[]
*        it_roles[].

*  ENDLOOP.
*  FREE lt_comprole.
*--Add single roles that are directly assigned
*  LOOP AT it_profrole INTO ls_profrole.
*    READ TABLE it_comprole WITH KEY roleindex = ls_profrole-roleindex
*    TRANSPORTING NO FIELDS.
*  LOOP AT it_roles INTO ls_role.
*--Check if it's not a composite role
*    READ TABLE it_comprole WITH KEY compindex = ls_role-roleindex
*    TRANSPORTING NO FIELDS.
*    IF sy-subrc <> 0.
*--Check if it's not assigned through composite role
*    READ TABLE it_comprole WITH TABLE KEY roleindex = ls_role-roleindex
*                                                TRANSPORTING NO FIELDS.
*      IF sy-subrc <> 0.
*--Not assigned through composite
  PERFORM add_role_nodes
  TABLES
      it_authdet_all
*            it_profiles
      et_node
      et_item
      it_abb
  USING
      et_expand[]
      i_parent.
*          ls_profrole-roleindex
*            ls_role-roleindex.
*            it_comprole[]
*            it_profrole[]
*            it_roles[].
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*--Add directly assigned profiles
*@MD@
*  LOOP AT it_profiles.
*    READ TABLE it_profrole WITH KEY
*      profindex = it_profiles-profindex
*    TRANSPORTING NO FIELDS.
*    IF sy-subrc <> 0.
*      PERFORM add_profile_nodes
*                  TABLES
*                     it_authdet_all
*                     it_profiles
*                     et_node
*                     et_item
*                     it_abb
*                  USING
*                     et_expand[]
*                     i_parent
*                     it_profiles-profindex
*                     it_comprole
*                     it_profrole
*                     it_roles.
*
*    ENDIF.
*  ENDLOOP.
ENDFORM.                    " add_function_detail_nodes
*&---------------------------------------------------------------------*
*&      Form  add_role_nodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_AUTHDET_ALL  text
*      -->P_ET_NODE  text
*      -->P_ET_ITEM  text
*      -->P_ET_NODE_NODE_KEY  text
*      -->P_LS_COMPROLE_ROLEINDEX  text
*      -->P_IT_COMPROLE  text
*      -->P_IT_PROFROLE  text
*      -->P_IT_ROLES  text
*----------------------------------------------------------------------*
FORM add_role_nodes
  TABLES   it_authdet       STRUCTURE  /psyng/serrs_authdetail
*           it_profiles      STRUCTURE  /psyng/swresipro
           et_node          STRUCTURE  treev_node
           et_item          STRUCTURE  mtreeitm
           it_abb           STRUCTURE  /psyng/swresiabb
  USING    et_expand        TYPE       treev_nks
           i_parent         TYPE       tv_nodekey.
*           i_roleindex      TYPE       /psyng/seres_roleindex.
*           it_comprole      TYPE       ttyp_comprol
*           it_profrole      TYPE       ttyp_profile
*           it_roles         TYPE       ttyp_roles.

  DATA : "ls_comprole        LIKE LINE OF it_comprole,
*         ls_profrole        LIKE LINE OF it_profrole,
*         ls_role            LIKE LINE OF it_roles,
    ls_node            TYPE treev_node,
    ls_item            TYPE mtreeitm,
    l_role_key         TYPE tv_nodekey,
    l_single_role_text TYPE agr_texts-text,
    l_rfctext          TYPE /psyng/sw_rfcdes-description,
    lt_varels          TYPE TABLE OF /psyng/serrs_authdetail
                       WITH HEADER LINE,
    lt_orgs            TYPE TABLE OF /psyng/serrs_authdetail
                       WITH HEADER LINE,
    l_type             TYPE string,
    ls_sodorgm         TYPE /psyng/swsodorgm,
    l_destination      TYPE /psyng/sw_rfcdes-rfcdest.

*  READ TABLE it_roles WITH TABLE KEY roleindex = i_roleindex
*  INTO ls_role.
  ADD 1 TO g_auth_id.

*--Role text
*  READ TABLE it_authdet INDEX 1.
*  PERFORM get_destination_system
*    USING it_authdet-sysid
*    CHANGING l_destination.
*
*  CALL FUNCTION '/PSYNG/BC_021'
*  DESTINATION l_destination
*       EXPORTING
*            i_agr_name = ls_role-agr_name
*       IMPORTING
*            e_text     = l_single_role_text.
*  IF p_rolpro = 'X'.
*    leaf_node et_node et_item i_parent 'SR' g_auth_id
*                 ls_role-agr_name l_single_role_text '@IC@' ''.
*  ELSE.
*    child_node et_node et_item i_parent 'SR' g_auth_id
*               ls_role-agr_name l_single_role_text '@IC@' ''.
*    l_role_key = ls_node-node_key.
*  ENDIF.

  CHECK p_orgvar = 'X'.

*  LOOP AT it_profrole INTO ls_profrole
*  WHERE roleindex = i_roleindex .
*    READ TABLE it_profiles WITH KEY profindex = ls_profrole-profindex.


  LOOP AT it_authdet. "WHERE profname = it_profiles-profname.
    l_type = 'A'.
*--check if this is a variable element
    READ TABLE gt_varel WITH KEY
      funid  = it_authdet-funid
      tcode  = it_authdet-tcode
      object = it_authdet-object
      field  = it_authdet-field
      BINARY SEARCH.
    IF sy-subrc = 0.
      l_type = 'V'.
    ENDIF.
    READ TABLE gt_sodorgm WITH KEY sysid = gs_hdr-sysid
    BINARY SEARCH.
    IF sy-subrc = 0.
      READ TABLE gt_sodorgm-sodorgm
        INTO ls_sodorgm
        WITH KEY
        object = it_authdet-object
        varbl = it_authdet-field
        BINARY SEARCH.
      IF sy-subrc = 0.
        l_type = 'O'.
      ENDIF.
    ENDIF.

    CASE l_type.
      WHEN 'V'. "Variable Element

        lt_varels = it_authdet.
        lt_varels-von = gt_varel-val_from.
        lt_varels-auth    = ''.
        lt_varels-tcode   = ''.
        lt_varels-object  = ''.
        READ TABLE lt_varels WITH KEY table_line = lt_varels.
        IF sy-subrc <> 0.
          COLLECT lt_varels.
          PERFORM add_varel_node
           TABLES
            et_node
            et_item
          USING
            i_parent "l_role_key
            it_authdet
            lt_varels-von
*              ls_profrole-profindex
          CHANGING
            ls_node.
        ENDIF.
      WHEN 'A'."Normal Authorization
        PERFORM add_auth_node
          TABLES
            et_node
            et_item
          USING
            i_parent"l_role_key
            it_authdet
          CHANGING
            ls_node.
      WHEN 'O'. "Organizational Element
        lt_orgs      = it_authdet.
        lt_orgs-object  = ''.
        lt_orgs-von    = ''.
        lt_orgs-bis    = ''.
        lt_orgs-field  = ''.
        lt_orgs-auth   = ''.
        lt_orgs-tcode  = ''.
*BOC AKUMAR  PN13164
*If two child roles of same composite role give
*access of functions in same abbreviation then
*in output two different nodes for same abb.
*get created in output, that bug was resolved with
*this change.
        lt_orgs-childrole = ''.
*EOC AKUMAR  PN13164
        READ TABLE it_abb WITH KEY org_abb = it_authdet-abb
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          READ TABLE lt_orgs WITH KEY table_line = lt_orgs.
          IF sy-subrc <> 0.
            COLLECT lt_orgs.
            PERFORM add_org_node
             TABLES
              et_node
              et_item
            USING
              i_parent"l_role_key
              it_authdet
              lt_orgs-abb
*                ls_profrole-profindex
            CHANGING
              ls_node.
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDLOOP.
*  ENDLOOP.
ENDFORM.                    " add_role_nodes

*---------------------------------------------------------------------*
*       FORM set_default_sodversion                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  L_SOD                                                         *
*  -->  L_UNAME                                                       *
*---------------------------------------------------------------------*
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
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.

ENDFORM.                    " set_default_sodversion

*---------------------------------------------------------------------*
*       MODULE STATUS_0101 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  REFRESH gt_func.
  SET TITLEBAR '0101'.
  gt_func-fcode = 'SEARCH'.
  APPEND gt_func.
  SET PF-STATUS '0101' EXCLUDING gt_func.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE STATUS_0102 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0102 OUTPUT.
  REFRESH gt_func.
  SET TITLEBAR '0101'.
  gt_func-fcode = 'EXP'.
  APPEND gt_func.
  SET PF-STATUS '0101' EXCLUDING gt_func.

*  CLEAR: gf_fnd_role, gf_fnd_conid, gf_fnd_funid.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  DATA: ls_role     LIKE LINE OF gt_role,
        ls_item     LIKE LINE OF gt_item,
        l_tabix     TYPE sy-tabix,
        ls_swrrscon TYPE /psyng/swrrscon.

  CASE sy-ucomm.
    WHEN 'CANCEL'.
      CLEAR: gf_exp_conid,gf_exp_funid,
             gf_exp_role.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'EXP'.
      PERFORM expand_node.
  ENDCASE.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE user_command_0102 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0102 INPUT.
*  DATA: "ls_user LIKE LINE OF gt_user,
*        ls_item LIKE LINE OF gt_item,
*        l_tabix TYPE sy-tabix.

  RANGES: lr_funid  FOR /psyng/faobj2-funid,
          lr_conid  FOR /psyng/conflict-conid,
          lr_role   FOR agr_define-agr_name.

  CASE sy-ucomm.
    WHEN 'CANCEL'.
      CLEAR: gf_fnd_role,gf_fnd_funid,
             gf_fnd_conid.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'SEARCH'.
      PERFORM find_node USING 0 0.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM export_data_to_alv                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM export_data_to_alv USING lf_ask_export TYPE flag.
  DATA: ls_fun           TYPE mtreeitm,
        ls_connode       TYPE treev_node,
        ls_funnode       TYPE treev_node,
*        ls_usernode TYPE treev_node,
        ls_rolnode       TYPE treev_node,
        lt_roles_alv     TYPE TABLE OF /psyng/swrrsrol WITH HEADER LINE,
        ls_items         TYPE mtreeitm,
*           lt_funprof  TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
*           lt_usrprof  TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
*           lt_usrprof2 TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
*           lt_profrole TYPE SORTED TABLE OF /psyng/swresprol
*                       WITH HEADER LINE WITH UNIQUE KEY profindex,
*           lt_roles    TYPE SORTED TABLE OF /psyng/swresirol
*                       WITH HEADER LINE WITH UNIQUE KEY roleindex,
*           lt_childrole TYPE SORTED TABLE OF /psyng/swrrsrchd
*                       WITH HEADER LINE WITH NON-UNIQUE KEY childindex,
*           lt_child     TYPE STANDARD TABLE OF /psyng/swrrsichd,
*           ls_child     TYPE /psyng/swrrsichd,
*           ls_role      TYPE /psyng/swrrsrol,
*           ls_childrole TYPE /psyng/swrrsrol,
*          lt_profiles TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
        lt_authdet       TYPE TABLE OF /psyng/serrs_authdetail
                         WITH HEADER LINE,
*           lt_authdet_all  TYPE TABLE OF /psyng/serrs_authdetail
*                       WITH HEADER LINE,
        ls_function      TYPE /psyng/swrrsifun,
        l_funindex       TYPE /psyng/seres_funindex,
        l_roleinndex     TYPE /psyng/seres_roleindex,
*         lt_funprofile TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
       lt_confun        TYPE TABLE OF /psyng/swrrscfun WITH HEADER LINE,
       lt_function      TYPE TABLE OF /psyng/swrrsifun WITH HEADER LINE,
       lt_rolecon       TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
       l_continue       TYPE flag,
       l_role_count     TYPE i,
* BOC by AKUMAR for C0765
*       lf_ask_export    TYPE flag VALUE 'X',
* EOC by AKUMAR for C0765
       lf_use_alv       TYPE flag,
       l_max_alv_s      TYPE string,
       l_max_alv        TYPE i,
       lf_cancel_export TYPE flag.

  FIELD-SYMBOLS: <swrrsrole> TYPE /psyng/swrrsrol,
                 <confun>    TYPE /psyng/swrrscfun.
  RANGES: lr_roleindex FOR /psyng/swrrscon-roleindex,
          lr_roleindex_all FOR /psyng/swrrscon-roleindex,
          lr_roleindex_part FOR /psyng/swrrscon-roleindex,
          lr_funindex  FOR /psyng/swrrscfun-funindex.
*          lr_profindex FOR /psyng/swresupr-profileindex,
*          lr_sys       FOR /psyng/swresupr-sys.

  se_config_param 'SOD_EXPORT_ALV_LIMIT' l_max_alv_s.
  IF l_max_alv_s CO '0123456789'.
*   Code Changes for B17121 by GSINGH - Hnadling Short Dump due to large number value in Config Parameter
    IF l_max_alv_s > '1000000'.
MESSAGE 'Parameter SOD_EXPORT_ALV_LIMIT current value cannot be greater than default value'(e11) TYPE 'E'.
    ELSE.
      l_max_alv = l_max_alv_s.
    ENDIF.
*   End of changes for B17121
  ELSE.
    l_max_alv = 1000000.
  ENDIF.

  REFRESH: gt_output_alv, lt_roles_alv.
  CLEAR g_node_key.

*     Get selected node
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
    MESSAGE i398(00) WITH text-e02 text-e03.
    EXIT.
  ENDIF.

*---prepare data table for alv
  lt_roles_alv[] = gt_role[].
  CASE g_node_key(1).
    WHEN 'G'.
*Parent node (1st) of tree
      READ TABLE gt_item INTO ls_items
             WITH KEY node_key  = g_node_key
                      item_name = 'GROUPNAME'.
    WHEN 'S'.
*Role node
      READ TABLE gt_item INTO ls_items
           WITH KEY node_key  = g_node_key
                    item_name = 'DATA'.
      DELETE lt_roles_alv WHERE agr_name <> ls_items-text.
    WHEN 'C'.
*Conflict node
      READ TABLE gt_node INTO ls_connode
                    WITH KEY node_key = g_node_key.
      READ TABLE gt_item INTO ls_items
       WITH KEY node_key  = ls_connode-relatkey
                item_name = 'DATA'.
      IF sy-subrc = 0.
        DELETE lt_roles_alv WHERE agr_name <> ls_items-text.
      ENDIF.
    WHEN 'F'.
*Function node
*--Get function index value
      READ TABLE gt_item INTO ls_fun
           WITH KEY node_key  = g_node_key
                    item_name = 'FUNINDEX'.
*--Get the roleid, 2 nodes up
      READ TABLE gt_node
      INTO ls_funnode
      WITH KEY node_key = g_node_key.

      READ TABLE gt_node
      INTO ls_connode
      WITH KEY node_key = ls_funnode-relatkey.

      READ TABLE gt_node
      INTO ls_rolnode
      WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
      READ TABLE gt_item INTO ls_items
         WITH KEY node_key  = ls_rolnode-node_key
                  item_name = 'ROLEINDEX'.
      DELETE lt_roles_alv WHERE roleindex <> ls_items-text.
  ENDCASE.

*---Warning if nr of roles > 50
  DESCRIBE TABLE lt_roles_alv LINES l_role_count.
  l_continue = 'X'.
  IF l_role_count > 50.
    CLEAR l_continue.
    PERFORM advise_syswide_analysis
    CHANGING  l_continue.
  ENDIF.

  IF l_continue = 'X'.
*---collect role index
    LOOP AT lt_roles_alv ASSIGNING <swrrsrole>.
      lr_roleindex-sign = 'I'.
      lr_roleindex-option = 'EQ'.
      lr_roleindex-low = <swrrsrole>-roleindex.
      APPEND lr_roleindex.
    ENDLOOP.
*-- get role conflict
    IF NOT lr_roleindex[] IS INITIAL.
      lr_roleindex_all[] = lr_roleindex[].
      WHILE NOT lr_roleindex[] IS INITIAL.
        APPEND LINES OF lr_roleindex FROM 1 TO 5000
        TO lr_roleindex_part.
        DELETE lr_roleindex FROM 1 TO 5000.
        IF p_mitcon EQ 'X'.
          SELECT * FROM /psyng/swrrscon APPENDING TABLE lt_rolecon
                     WHERE aid       =  p_aid AND
                           roleindex IN lr_roleindex_part AND
                           conindex  IN gr_conflicts.
        ELSE.
          SELECT * FROM /psyng/swrrscon APPENDING TABLE lt_rolecon
                     WHERE aid       =  p_aid AND
                           roleindex IN lr_roleindex_part AND
                           conindex  IN gr_conflicts
                       AND mitigated = p_mitcon.
        ENDIF.
        REFRESH : lr_roleindex_part[].
      ENDWHILE.
      lr_roleindex[] = lr_roleindex_all[].
    ENDIF.
    FREE : lr_roleindex_part, lr_roleindex_all.
*---if conflict node selected, delete others
    IF g_node_key(1) = 'C'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'CONINDEX'.
      IF sy-subrc = 0.
        DELETE lt_rolecon WHERE conindex <> ls_fun-text.
      ENDIF.
    ENDIF.

*--Role's Conflict functions
    IF NOT lt_rolecon[] IS INITIAL.
      SELECT * FROM /psyng/swrrscfun  INTO TABLE lt_confun
      FOR ALL ENTRIES IN lt_rolecon
               WHERE aid       =  p_aid AND
                     conindex  = lt_rolecon-conindex.
      IF NOT lt_confun[] IS INITIAL.
        SELECT  * FROM /psyng/swrrsifun INTO TABLE lt_function
        FOR ALL ENTRIES IN lt_confun
             WHERE aid      = p_aid AND
                   funindex = lt_confun-funindex.
      ENDIF.
    ENDIF.
    LOOP AT lt_confun ASSIGNING <confun>.
      lr_funindex-sign = 'I'.
      lr_funindex-option = 'EQ'.
      lr_funindex-low = <confun>-funindex.
      APPEND lr_funindex.
    ENDLOOP.
*---if function node selected, delete others
    IF g_node_key(1) = 'F'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'FUNINDEX'.
      IF sy-subrc = 0.
        DELETE lr_funindex WHERE low <> ls_fun-text.
        DELETE lt_confun WHERE funindex <> ls_fun-text.
*---- delete other conflict
        CLEAR ls_funnode.
        READ TABLE gt_node INTO ls_connode
        WITH KEY node_key  = g_node_key.
        IF sy-subrc = 0.
          READ TABLE gt_item INTO ls_fun
          WITH KEY node_key  = ls_connode-relatkey
                   item_name = 'CONINDEX'.
          IF sy-subrc = 0.
            DELETE lt_rolecon WHERE conindex <> ls_fun-text.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

* if role node selected, delete others
*    IF g_node_key(1) = 'S'.
*      READ TABLE gt_node INTO ls_rolnode
*    WITH KEY node_key = g_node_key.
*      IF sy-subrc = 0.
*        READ TABLE gt_item INTO ls_fun
*              WITH KEY
*                      node_key  = ls_rolnode-relatkey
*                       item_name = 'FUNINDEX'.
*        IF sy-subrc = 0.
*          DELETE lr_funindex WHERE low <> ls_fun-text.
*        ENDIF.
*      ENDIF.
*    ENDIF.

*--Approach with multiple selects, optimize use of indexes
**--Get all profiles user has
*    SELECT * FROM /psyng/swresupr
*    INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
*    WHERE aid          = p_aid AND
*          userindex    IN lr_userindex.
*--For these profiles,
*  get the ones that relate to the functions we care about
*    lr_profindex-sign   = 'I'.
*    lr_profindex-option = 'EQ'.
*    MOVE-CORRESPONDING lr_profindex TO lr_sys.
*    LOOP AT lt_usrprof.
*      lr_profindex-low = lt_usrprof-profileindex.
*      APPEND lr_profindex.
*      lr_sys-low = lt_usrprof-sys.
*      APPEND lr_sys.
*    ENDLOOP.
*    SORT lr_profindex BY low.
*    SORT lr_sys BY low.
*    DELETE ADJACENT DUPLICATES FROM  lr_profindex COMPARING low.
*    DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.

*    SELECT * FROM /psyng/swresfpr
*    INTO TABLE lt_funprofile
*    WHERE
*      aid = p_aid AND
*      sys IN lr_sys AND
**      funindex IN lr_funindex AND
*      profileindex IN lr_profindex.

*    IF g_node_key(1) = 'F'.
*      READ TABLE gt_item INTO ls_fun
*            WITH KEY node_key  = g_node_key
*                     item_name = 'FUNINDEX'.
*      IF sy-subrc = 0.
*        DELETE lt_funprofile WHERE funindex <> ls_fun-text.
*      ENDIF.
*    ENDIF.

*    SORT lt_funprofile BY sys profileindex.
*    LOOP AT lt_usrprof.
*      READ TABLE lt_funprofile WITH KEY
*        sys           = lt_usrprof-sys
*        profileindex  = lt_usrprof-profileindex
*      BINARY SEARCH TRANSPORTING NO FIELDS.
*      IF sy-subrc = 0.
*        APPEND lt_usrprof TO lt_usrprof2.
*      ENDIF.
*    ENDLOOP.
*    lt_usrprof[] =   lt_usrprof2[].
*    FREE lt_usrprof2[].

**--Get the roles
*    IF NOT lt_usrprof[] IS INITIAL.

*      SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
*        FOR ALL ENTRIES IN
*          lt_usrprof
*      WHERE aid       = p_aid AND
**              sys       = lt_usrprof-sys and
*            profindex = lt_usrprof-profileindex.
*
*      SELECT * FROM /psyng/swresprol
*      INTO TABLE lt_profrole
*      FOR ALL ENTRIES IN lt_usrprof
*      WHERE aid       = p_aid AND
*            sys       = lt_usrprof-sys AND
*            profindex = lt_usrprof-profileindex.
*      IF NOT lt_profrole[] IS INITIAL.
*        SELECT * FROM /psyng/swresirol
*        INTO TABLE lt_roles
*        FOR ALL ENTRIES IN lt_profrole
*          WHERE aid = p_aid AND
*                roleindex = lt_profrole-roleindex.
*        IF NOT lt_rolecon[] IS INITIAL.
*--Get any child roles
*          SELECT * FROM /psyng/swrrsrchd
*          INTO TABLE lt_childrole
*          FOR ALL ENTRIES IN lt_rolecon WHERE
*            aid = p_aid AND
**            userindex = l_userinndex AND
**            userindex IN lr_userindex AND
*            roleindex = lt_rolecon-roleindex.
*          IF NOT lt_childrole[] IS INITIAL.
*            SELECT * FROM /psyng/swrrsichd
*            INTO TABLE lt_child
*            FOR ALL ENTRIES IN lt_childrole
*              WHERE aid = p_aid AND
*                    childindex = lt_childrole-childindex.
*          ENDIF.
*        ENDIF.
*      ENDIF.

*    ENDIF.

*---Macro to get only uniq record when org/var option not selected
    DEFINE export_only_uniq_value.
      check p_orgvar <> 'X'.

      if p_fun = 'X'.
    read table gt_output_alv with key agr_name = &1"lt_users_alv-bname
                                         conid = &2"gt_conflict-conid
                                         funid = &3."lt_function-funid.
        if sy-subrc = 0.
          clear gt_output_alv.
        else.
          add 1 to g_alv_count.
          append gt_output_alv.
        endif.

      endif.

*      if p_rolpro  = 'X'.
*      read table gt_output_alv
*       with key agr_name = &1 "lt_users_alv-bname
*                conid = &2"gt_conflict-conid
*                funid = &3"lt_function-funid.
*                agr_name = &4
*                profname = &5.
*        if sy-subrc = 0.
*          clear gt_output_alv.
*        else.
*          add 1 to g_alv_count.
*          append gt_output_alv.
*        endif.
*      endif.
    END-OF-DEFINITION.


*    SORT lt_usrprof BY sys userindex profileindex.
    LOOP AT lt_confun.
      CLEAR gt_output_alv.
*      LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
      LOOP AT lt_rolecon WHERE conindex = lt_confun-conindex.
*          READ TABLE lt_usrprof WITH KEY
*            sys          = lt_funprofile-sys
*            userindex    = lt_usercon-userindex
*            profileindex = lt_funprofile-profileindex
*            BINARY SEARCH.
*          CHECK sy-subrc = 0.
* userid
      READ TABLE lt_roles_alv WITH KEY roleindex = lt_rolecon-roleindex.
        IF sy-subrc = 0.
          gt_output_alv-agr_name = lt_roles_alv-agr_name.
          gt_output_alv-confnum = lt_roles_alv-nr_conflicts.
          gt_output_alv-mitinum = lt_roles_alv-nr_mitigated.
        ENDIF.
* Conflicts
        READ TABLE gt_conflict WITH KEY conindex = lt_confun-conindex.
        IF sy-subrc = 0.
          gt_output_alv-conid = gt_conflict-conid.
          gt_output_alv-mitigated = lt_rolecon-mitigated.
        ENDIF.
* function
        READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
        IF sy-subrc = 0.
          gt_output_alv-funid = lt_function-funid.
        ENDIF.

*          IF p_fun <> 'X'.
* profiles
*            READ TABLE lt_profiles WITH KEY
*                          profindex = lt_usrprof-profileindex.
*            IF sy-subrc = 0.
*              gt_output_alv-profname = lt_profiles-profname.
*            ENDIF.

** Role
*            READ TABLE lt_profrole WITH KEY
*                       profindex = lt_usrprof-profileindex.
*            IF sy-subrc = 0.
*              READ TABLE lt_roles WITH KEY
*                roleindex = lt_profrole-roleindex.
*              gt_output_alv-agr_name = lt_roles-agr_name.
** Composite Role
*              READ TABLE lt_comprole WITH KEY
*                userindex = lt_usercon-userindex
*                roleindex = lt_profrole-roleindex.
*              IF sy-subrc = 0.
*                READ TABLE lt_roles WITH KEY
*                  roleindex  = lt_comprole-compindex.
*                IF sy-subrc = 0.
*                  gt_output_alv-comp_agr = lt_roles-agr_name.
*                ENDIF.
*              ELSE.
*                CLEAR gt_output_alv-comp_agr.
*              ENDIF.
*          LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
*                             AND  roleindex = lt_profrole-roleindex.
*                READ TABLE lt_roles WITH KEY
*             roleindex  = lt_comprole-compindex.
*                IF sy-subrc = 0.
*                  gt_output_alv-comp_agr = lt_roles-agr_name.
*                ENDIF.
*        READ TABLE gt_output_alv WITH KEY  bname = lt_users_alv-bname
*                                            conid = gt_conflict-conid
*                                            funid = lt_function-funid
*                                    comp_agr = gt_output_alv-comp_agr
*                                    agr_name = gt_output_alv-agr_name
*                                   profname = gt_output_alv-profname.
*                IF sy-subrc <> 0.
*                  APPEND gt_output_alv.
*                  ADD 1 TO g_alv_count.
*                ENDIF.
*              ENDLOOP.
*              CLEAR: gt_output_alv-comp_agr.
*            ENDIF.
*            IF  p_rolpro = 'X'.
*           export_only_uniq_value lt_users_alv-bname gt_conflict-conid
*       lt_function-funid  gt_output_alv-agr_name lt_profiles-profname.
*            ENDIF.
*          ENDIF.

*--- call macro only if org/var expand o/p option not selected
        IF p_fun = 'X'.
          export_only_uniq_value lt_roles_alv-agr_name
           gt_conflict-conid lt_function-funid.
        ENDIF.

* ---- don't go for detail if expand level not selected org/var
        IF p_orgvar = 'X'.
          REFRESH : lt_authdet.
          CALL FUNCTION '/PSYNG/SW_SE_ROL_EXPAND_CAUT'
            EXPORTING
              i_aid          = p_aid
*             i_sys          = lt_usrprof-sys
              i_funindex     = lt_confun-funindex
              i_roleindex    = lt_rolecon-roleindex
            TABLES
              et_roledetails = lt_authdet.

          LOOP AT lt_authdet.
            MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
            gt_output_alv-sysid = gs_hdr-sysid.
            ADD 1 TO g_alv_count.
            APPEND gt_output_alv.
            IF g_alv_count > l_max_alv.
*--The export contains more data than can be handled in
*  the memory of the sap session
*  Download the data in separate files
              IF lf_ask_export = 'X'.
                MESSAGE i012.
              ENDIF.
*   The amount of data is too large to export at once and will be split
              PERFORM export_to_file USING    lf_ask_export
                                     CHANGING lf_cancel_export.
              IF lf_cancel_export = 'X'.
                EXIT.
              ENDIF.
              CLEAR : lf_ask_export,
                      g_alv_count.
            ENDIF.

          ENDLOOP.
        ENDIF.
*          endloop.
        FREE : lt_authdet.
*          IF lf_cancel_export = 'X'.
*            EXIT.
*          ENDIF.
*        ENDLOOP.
        IF lf_cancel_export = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lf_cancel_export = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.
*--free some memory
    FREE :     lt_roles_alv,
*               lt_funprof ,
*               lt_usrprof ,
*               lt_usrprof2,
*               lt_profrole,
*               lt_roles,
*               lt_childrole,
*               lt_child,
*               lt_profiles ,
               lt_authdet ,
*               lt_authdet_all ,
*               lt_funprofile ,
               lt_confun,
               lt_function,
               lt_rolecon.

*---sort and delete duplicates records
    SORT gt_output_alv.
    DELETE ADJACENT DUPLICATES FROM gt_output_alv COMPARING
    ALL FIELDS.

    IF g_alv_count > 0 AND NOT lf_cancel_export = 'X'.
      IF lf_ask_export = 'X'."we haven't had to ask for anything yet
        PERFORM display_alv.
      ELSE.
*  --Do a direct download, to avoid memory issues with alv
        PERFORM export_to_file USING    lf_ask_export
                               CHANGING lf_cancel_export.
      ENDIF.
    ENDIF.
  ENDIF.
  CLEAR g_alv_count.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM handle_download_error                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  P_SY_SUBRC                                                    *
*  -->  P_FILENAME                                                    *
*  -->  P_MSG                                                         *
*---------------------------------------------------------------------*
FORM handle_download_error USING    p_sy_subrc
                                    p_filename
                                    p_msg.
  CASE p_sy_subrc.
    WHEN 1.
      MESSAGE i041(/psyng/basis) WITH p_filename p_msg.
    WHEN 2.
      MESSAGE i042(/psyng/basis) WITH p_filename p_msg.
    WHEN 3.
      MESSAGE i043(/psyng/basis) WITH p_filename p_msg.
    WHEN 4.
      MESSAGE i044(/psyng/basis) WITH p_filename p_msg.
    WHEN 5.
      MESSAGE i045(/psyng/basis) WITH p_filename p_msg.
    WHEN 6.
      MESSAGE i046(/psyng/basis) WITH p_filename p_msg.
    WHEN 7 OR 22.
      MESSAGE i047(/psyng/basis) WITH p_filename p_msg.
    WHEN 8.
      MESSAGE i048(/psyng/basis) WITH p_filename p_msg.
    WHEN 9.
      MESSAGE i049(/psyng/basis) WITH p_filename p_msg.
    WHEN 10.
      MESSAGE i050(/psyng/basis) WITH p_filename p_msg.
    WHEN 11.
      MESSAGE i051(/psyng/basis) WITH p_filename p_msg.
    WHEN 12.
      MESSAGE i052(/psyng/basis) WITH p_filename p_msg.
    WHEN 13.
      MESSAGE i053(/psyng/basis) WITH p_filename p_msg.
    WHEN 14.
      MESSAGE i054(/psyng/basis) WITH p_filename p_msg.
    WHEN 15.
      MESSAGE i055(/psyng/basis) WITH p_filename p_msg.
    WHEN 16.
      MESSAGE i056(/psyng/basis) WITH p_filename p_msg.
    WHEN 17.
      MESSAGE i057(/psyng/basis) WITH p_filename p_msg.
    WHEN 18.
      MESSAGE i058(/psyng/basis) WITH p_filename p_msg.
    WHEN 19.
      MESSAGE i059(/psyng/basis) WITH p_filename p_msg.
    WHEN 20.
      MESSAGE i060(/psyng/basis) WITH p_filename p_msg.
    WHEN 21.
      MESSAGE i061(/psyng/basis) WITH p_filename p_msg.
  ENDCASE.

ENDFORM.                    " handle_download_error
*---------------------------------------------------------------------*
*       FORM display_alv                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv.
*--create field catalog
  TYPE-POOLS : slis.
  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv WITH HEADER LINE,
        l_program   LIKE sy-repid,
        lt_sort     TYPE slis_t_sortinfo_alv,
        ls_sort     TYPE slis_sortinfo_alv,
        ls_layout   TYPE slis_layout_alv,
        l_nodetype  TYPE string,
        l_rest      TYPE string,
        lt_exclude  TYPE slis_t_extab,
        ls_exclude  TYPE slis_extab.

  DEFINE alv_fieldcat.
    lt_fieldcat-fieldname = &1.
    lt_fieldcat-seltext_m = &2.
    lt_fieldcat-col_pos = &3.
    lt_fieldcat-outputlen = &4.
    append lt_fieldcat.
    clear lt_fieldcat.
  END-OF-DEFINITION.

  DEFINE sort_alv.
    ls_sort-fieldname = &1.
    ls_sort-spos = &2.
    ls_sort-up = 'X'.
    append ls_sort to lt_sort.
  END-OF-DEFINITION.

  DEFINE hide_column.
    lt_fieldcat-no_out = 'X'.
    modify lt_fieldcat transporting no_out where fieldname = &1..
  END-OF-DEFINITION.
*---create catalog
  alv_fieldcat: "'AID'       'Analysis ID'(c01)    0  10,
                 'AGR_NAME'  'Role ID'(c02)        1  30,
                 'CONFNUM'   'Conflicts'(t09)      2  15,
                 'MITINUM'   'Mitigated Conflicts'(t10) 3  15,
                 'CONID'     'Conflict'(c03)       4  12,
                 'MITIGATED' 'Mitigated'(t08)      5  9,
                 'FUNID'     'Function'(c04)       6  12,
*                 'COMP_AGR'  'Composite Role'(c15) 4  15,
                 'CHILDROLE' 'Child Role'(c05)     7  15,
*                 'PROFNAME'  'Profile'(c06)        6  15,
                 'SYSID'     'System'(c07)         8  10,
                 'TCODE'     'Tcode'(c08)          9  15,
                 'ABB'       'Abbr.'(c14)          10  10,
                 'AUTH'      'Authorization'(c09)  11  15,
                 'OBJECT'    'Object'(c10)         12  15,
                 'FIELD'     'Field'(c11)          13 15,
                 'VON'       'Value From'(c12)     14 15,
                 'BIS'       'Value To'(c13)       15 15.

  IF p_mitcon IS INITIAL.
    hide_column  'MITIGATED'.
  ENDIF.
*---sort alv
  sort_alv: "'AID'      '1',
            'AGR_NAME'  '1',
            'CONFNUM'   '2',
            'MITINUM'   '3',
            'CONID'     '4',
            'MITIGATED' '5',
            'FUNID'     '6',
            'CHILDROLE'  '7',
*            'AGR_NAME'  '5',
*            'PROFNAME'  '6',
            'SYSID'     '8',
            'TCODE'     '9',
            'ABB'       '10',
            'AUTH'      '11',
            'OBJECT'    '12',
            'FIELD'     '13',
            'VON'       '14'.


*-- Hide unwanted node if child node selected
  SPLIT g_node_key AT '_' INTO l_nodetype l_rest.
  CASE l_nodetype.
    WHEN 'C'. " conflict
      lt_fieldcat-no_out = 'X'.
      MODIFY lt_fieldcat TRANSPORTING no_out
      WHERE fieldname = 'AGR_NAME'
         OR fieldname = 'CONFNUM'
         OR fieldname = 'MITINUM'.
    WHEN 'F'. "function
      lt_fieldcat-no_out = 'X'.
      MODIFY lt_fieldcat TRANSPORTING no_out
      WHERE fieldname = 'AGR_NAME'
      OR    fieldname = 'CONID'
      OR    fieldname = 'CONFNUM'
      OR    fieldname = 'MITINUM'
      OR    fieldname = 'MITIGATED'.
*    WHEN 'S'. " Role
*      lt_fieldcat-no_out = 'X'.
*    MODIFY lt_fieldcat TRANSPORTING no_out
*     WHERE    fieldname = 'AGR_NAME'
*     OR fieldname = 'CONID'
*     OR fieldname = 'FUNID' .
  ENDCASE.

*---selected o/p expand level
  IF p_fun = 'X'.
    hide_column:  "'COMP_AGR',
                  "'AGR_NAME',
                  'CHILDROLE',
                  'SYSID',
                  'TCODE',
                  'ABB',
                  'AUTH',
                  'OBJECT',
                  'FIELD',
                  'VON',
                  'BIS'.

  ENDIF.
*--- display alv
  l_program = sy-repid.
  ls_layout-zebra = 'X'.
  ls_layout-colwidth_optimize = 'X'.
*--Exclude unneeded buttons
  ls_exclude-fcode = '&INFO'.
  APPEND ls_exclude TO lt_exclude.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = l_program
      is_layout          = ls_layout
      it_fieldcat        = lt_fieldcat[]
      it_excluding       = lt_exclude[]
      it_sort            = lt_sort[]
    TABLES
      t_outtab           = gt_output_alv
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
ENDFORM.





*---------------------------------------------------------------------*
*       FORM find_node                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_START_POS                                                   *
*---------------------------------------------------------------------*
FORM find_node USING i_start_pos TYPE i
                     i_start_con_pos TYPE i.
  DATA: ls_swrrscon     TYPE /psyng/swrrscon,
        ls_node         LIKE LINE OF gt_node,
        ls_connode      LIKE LINE OF gt_node,
        ls_funnode      LIKE LINE OF gt_node,
*        l_groupname     TYPE scrpcha72,
*        lt_expanded     TYPE HASHED TABLE OF tv_nodekey
*                         WITH UNIQUE KEY table_line
*                         WITH HEADER LINE,
        lt_roles        TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
        lt_rolecon      TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
        ls_function     TYPE  /psyng/swrrsifun,
        lt_confun       TYPE TABLE OF /psyng/swrrscfun
                         WITH HEADER LINE,
        lt_conflict     TYPE TABLE OF /psyng/swrrscfun
                         WITH HEADER LINE,
        ls_node_con     TYPE treev_node,
        ls_item         TYPE mtreeitm,
        lt_node         TYPE treev_ntab,
        lt_item         TYPE ttree_item,
        l_text          TYPE scrpcha72,
        l_conindex      TYPE scrpcha72,
        l_funindex      TYPE scrpcha72,
        l_tabix         TYPE i,
        lt_match_roles  TYPE TABLE OF /psyng/swrrsrol
                        WITH HEADER LINE,
        l_start_con_pos TYPE i,
        lf_found        TYPE flag.

  l_start_con_pos = i_start_con_pos.
  ADD 1 TO l_start_con_pos.
  CLEAR: ls_role.
**--Todo search also work with pattern
*  IF NOT gf_fnd_bname IS INITIAL.
*    lr_bname-sign = 'I'.
*    lr_bname-low = gf_fnd_bname.
*
*    IF gf_fnd_bname CS '*'.
*      lr_bname-option = 'CP'.
*    ELSE.
*      lr_bname-option = 'EQ'.
*    ENDIF.
*
*    APPEND lr_bname.
*  ENDIF.

  IF gr_fnd_role = 'X'.

    READ TABLE gt_role INTO ls_role  WITH KEY
          agr_name = gf_fnd_role.

    IF sy-subrc = 0.
**  expand upto 1 level to load tree
*      READ TABLE gt_item INTO ls_item
*                  WITH KEY item_name = 'GROUPNAME'
*                           text      = l_groupname.
*      READ TABLE lt_expanded WITH TABLE KEY
*                 table_line =  ls_item-node_key.
*      IF sy-subrc <> 0.
**---group node is not expanded yet
*        PERFORM expand_group USING ls_item-node_key.
*        lt_expanded = ls_item-node_key.
*        INSERT TABLE lt_expanded.
*      ENDIF.
      l_text = ls_role-roleindex.
      CONDENSE l_text.
      READ TABLE gt_item INTO ls_item
         WITH KEY  item_name = 'ROLEINDEX'
                   text      = l_text.

      IF sy-subrc = 0.
        PERFORM expand_role   USING ls_item-node_key.
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching Role found'(x05).
    ENDIF.

  ELSEIF gr_fnd_conid = 'X'.
    READ TABLE gt_conflict WITH KEY conid = gf_fnd_conid.
    IF sy-subrc = 0.
      l_conindex = gt_conflict-conindex.
      IF p_mitcon EQ 'X'.
        SELECT  * FROM /psyng/swrrscon INTO TABLE lt_rolecon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid.
      ELSE.
        SELECT  * FROM /psyng/swrrscon INTO TABLE lt_rolecon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid
              AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_rolecon[] IS INITIAL.
*---- collect all users which having search conflict
        lt_roles[] = lt_rolecon[].
        SORT lt_roles BY roleindex.
        DELETE ADJACENT DUPLICATES FROM lt_roles COMPARING roleindex.
        PERFORM get_matching_roles
          TABLES
            lt_roles
            lt_match_roles.
        LOOP AT lt_match_roles FROM i_start_pos.

          l_tabix = sy-tabix.
          IF i_start_pos <> 0.
            CHECK l_tabix > i_start_pos.
          ENDIF.
          g_start_pos = l_tabix.
**--Expand the group if not expanded yet
*        READ TABLE gt_item INTO ls_item
*          WITH KEY item_name = 'GROUPNAME'
*                   text      = l_groupname.
*        READ TABLE lt_expanded WITH TABLE KEY
*                   table_line =  ls_item-node_key.
*        IF sy-subrc <> 0.
**---group node is not expanded yet
*          PERFORM expand_group USING ls_item-node_key.
*          lt_expanded = ls_item-node_key.
*          INSERT TABLE lt_expanded.
*        ENDIF.

          l_text = lt_match_roles-roleindex.
          CONDENSE l_text.
          READ TABLE gt_item INTO ls_item
             WITH KEY  item_name = 'ROLEINDEX'
                       text      = l_text.

          IF sy-subrc = 0.
            PERFORM expand_role   USING ls_item-node_key.
* ----exit from loop if found
            LOOP AT gt_node INTO ls_connode
            WHERE relatkey = ls_item-node_key.
              l_text = l_conindex.
              CONDENSE l_text.
              READ TABLE gt_item INTO ls_item
                 WITH KEY  node_key = ls_connode-node_key
                         item_name = 'CONINDEX'
                           text      = l_text.
              IF sy-subrc = 0.
                PERFORM expand_rolecon USING ls_item-node_key.
                EXIT.
              ENDIF.
            ENDLOOP.
            EXIT.
          ENDIF.
*        ENDIF.
        ENDLOOP.
      ELSE.
        MESSAGE s002 WITH 'No matching Conflict found'(x06).
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching Conflict found'(x06).
    ENDIF.

  ELSEIF gr_fnd_funid = 'X'.
*--Get all conflicts that contain this function
    PERFORM get_function USING gf_fnd_funid
                         CHANGING ls_function.
    SELECT * FROM /psyng/swrrscfun INTO TABLE lt_confun WHERE
      aid = p_aid AND funindex = ls_function-funindex.
    l_funindex = ls_function-funindex.
    lt_conflict[] = lt_confun[].
    SORT lt_conflict BY conindex.
    DELETE ADJACENT DUPLICATES FROM lt_conflict COMPARING conindex.
*--Get all roles that have this conflict
    IF NOT lt_confun[] IS INITIAL.
      IF p_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex.
      ELSE.
        SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex
            AND mitigated = p_mitcon.
      ENDIF.
*--Get all the orgs that contain these users
      lt_roles[] = lt_rolecon[].
      SORT lt_roles BY roleindex.
      DELETE ADJACENT DUPLICATES FROM lt_roles COMPARING roleindex.

      PERFORM get_matching_roles
        TABLES
          lt_roles
          lt_match_roles.
*      if i_start_pos > 1.
      LOOP AT lt_match_roles FROM i_start_pos.
        g_start_pos = sy-tabix.
**--Expand the group if not expanded yet
*        READ TABLE gt_item INTO ls_item
*          WITH KEY item_name = 'GROUPNAME'
*                   text      = l_groupname.
*        READ TABLE lt_expanded WITH TABLE KEY
*          table_line =  ls_item-node_key.
*        IF sy-subrc <> 0.
**     group node is not expanded yet
*          PERFORM expand_group USING ls_item-node_key.
*          lt_expanded = ls_item-node_key.
*          INSERT TABLE lt_expanded.
*        ENDIF.
*--Expand all the user nodes
        l_text = lt_match_roles-roleindex.
        CONDENSE l_text.
        READ TABLE gt_item INTO ls_item
           WITH KEY  item_name = 'ROLEINDEX'
                     text      = l_text.
        IF sy-subrc = 0.
          PERFORM expand_role   USING ls_item-node_key.
          LOOP AT lt_confun FROM l_start_con_pos.
            g_start_con_pos = sy-tabix.
            READ TABLE lt_rolecon WITH KEY
              roleindex = lt_match_roles-roleindex
              conindex  = lt_confun-conindex.
            IF sy-subrc = 0.
*--function found
              LOOP AT gt_node INTO ls_connode
                        WHERE relatkey = ls_item-node_key.
                l_text = lt_confun-conindex.
                CONDENSE l_text.
                READ TABLE gt_item INTO ls_item
                   WITH KEY node_key = ls_connode-node_key
                   item_name = 'CONINDEX'
                   text      = l_text.
                IF sy-subrc = 0.
*--This conflict should be expanded
                  PERFORM expand_rolecon USING ls_item-node_key.
                  lf_found = 'X'.
*--Find the function node
                  l_text = ls_function-funindex.
                  CONDENSE l_text.
                  LOOP AT gt_node  INTO ls_funnode
                    WHERE relatkey  = ls_connode-node_key.
                    READ TABLE gt_item INTO ls_item
                       WITH KEY node_key = ls_funnode-node_key
                       item_name = 'FUNINDEX'
                       text      = l_text.
                    IF sy-subrc = 0.
                      EXIT.
                    ENDIF.
                  ENDLOOP.
                ENDIF.
              ENDLOOP.
              IF lf_found = 'X'.
                EXIT.
              ENDIF.
            ENDIF.
          ENDLOOP.

          IF lf_found = 'X'.
            EXIT.
          ELSE.
            CLEAR : l_start_con_pos,
                    g_start_con_pos .
          ENDIF.
        ENDIF.

      ENDLOOP.
      IF lf_found IS INITIAL.
        MESSAGE s002 WITH 'No matching function found'(x01).
        EXIT.
      ENDIF.

    ELSE.
      MESSAGE s002 WITH 'No matching function found'(x01).
    ENDIF.

  ENDIF.
  IF NOT ls_item-node_key IS INITIAL.
*    highlight found node
    CALL METHOD go_tree->set_selected_node
      EXPORTING
        node_key                   = ls_item-node_key
      EXCEPTIONS
        failed                     = 1
        single_node_selection_only = 2
        node_not_found             = 3
        cntl_system_error          = 4
        OTHERS                     = 5.
*    IF sy-subrc <> 0.
*      MESSAGE i103(/psyng/sw).
*    ENDIF.
  ELSE.
    MESSAGE s002(/psyng/sw) WITH 'No match found'(i02).
  ENDIF.
  IF sy-ucomm <> 'FINDNEXT'.
*    CLEAR: gf_fnd_bname, gf_fnd_conid, gf_fnd_funid.
    SET SCREEN 0.
    LEAVE SCREEN.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM expand_node                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM expand_node.
  DATA : "ls_role        TYPE mtreeitm,
    lt_rolecon     TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
    lt_roles       TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
    ls_node        TYPE treev_node,
    ls_node_con    TYPE treev_node,
    ls_item        TYPE mtreeitm,
    lt_node        TYPE treev_ntab,
    lt_item        TYPE ttree_item,
    l_cdescription TYPE /psyng/rskdsc,
    i_node_key     TYPE tv_nodekey,
    ls_function    TYPE /psyng/swrrsifun,
    lt_confun      TYPE TABLE OF /psyng/swrrscfun
                   WITH HEADER LINE,
    lt_conflict    TYPE TABLE OF /psyng/swrrscfun
                   WITH HEADER LINE,
*    lt_expanded    TYPE HASHED TABLE OF tv_nodekey
*                   WITH UNIQUE KEY table_line
*                   WITH HEADER LINE,
    l_text         TYPE scrpcha72.
*    l_groupname    TYPE scrpcha72.

  IF NOT gf_exp_role IS INITIAL OR NOT gf_exp_conid IS INITIAL
  OR NOT gf_exp_funid IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH
     'Search is empty, Please enter the value'(x07).
    LEAVE LIST-PROCESSING.
  ENDIF.


*--Hide tree control to make expanding faster

  CALL METHOD go_tree->set_visible
    EXPORTING
      visible = ''
*  EXCEPTIONS
*     CNTL_ERROR        = 1
*     CNTL_SYSTEM_ERROR = 2
*     others  = 3
    .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.


  IF gr_exp_role = 'X'.
    READ TABLE gt_role INTO ls_role  WITH KEY
        agr_name = gf_exp_role.
    IF sy-subrc = 0.
*  expand upto 1 level to load tree
*      PERFORM expand_group USING ls_item-node_key.
      READ TABLE gt_item INTO ls_item WITH KEY
                text = ls_role-agr_name.
*   expand role
      PERFORM expand_role   USING ls_item-node_key.
      IF sy-subrc EQ 0.
*--all conflict assigned to role
        IF p_mitcon EQ 'X'.
          SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
              WHERE aid = p_aid AND roleindex = ls_role-roleindex
                AND conindex IN gr_conflicts.
        ELSE.
          SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
              WHERE aid = p_aid AND roleindex = ls_role-roleindex
                AND conindex IN gr_conflicts
                AND mitigated = p_mitcon.
        ENDIF.
        IF NOT lt_rolecon IS INITIAL.
          LOOP AT lt_rolecon.
            l_text = lt_rolecon-conindex.
            CONDENSE l_text.
            READ TABLE gt_item INTO ls_item
                             WITH KEY  item_name = 'CONINDEX'
                                       text      = l_text.

            PERFORM expand_rolecon USING ls_item-node_key.
          ENDLOOP.
          MESSAGE s002 WITH 'Nodes expanded'(x09).
        ELSE.
          MESSAGE s002 WITH 'Role doesn’t have any conflict'(x14).
        ENDIF.
      ELSE.
        MESSAGE s002 WITH 'Role doesn’t have any conflict'(x14).
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching role found'(x05).
    ENDIF.
  ENDIF.

  IF gr_exp_conid = 'X'.
    READ TABLE gt_conflict WITH KEY conid = gf_exp_conid.
    IF sy-subrc = 0.
      IF p_mitcon EQ 'X'.
        SELECT  * FROM /psyng/swrrscon INTO TABLE lt_rolecon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid.
      ELSE.
        SELECT  * FROM /psyng/swrrscon INTO TABLE lt_rolecon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid
              AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_rolecon[] IS INITIAL.
*---- collect all users
        lt_roles[] = lt_rolecon[].
        SORT lt_roles BY roleindex.
        DELETE ADJACENT DUPLICATES FROM lt_roles COMPARING roleindex.
        LOOP AT gt_role.
          READ TABLE lt_roles WITH KEY roleindex = gt_role-roleindex
            BINARY SEARCH.
          IF sy-subrc = 0.
**--Expand the group if not expanded yet
*          READ TABLE gt_item INTO ls_item
*            WITH KEY item_name = 'GROUPNAME'
*                     text      = l_groupname.
*          READ TABLE lt_expanded WITH TABLE KEY
*                     table_line =  ls_item-node_key.
*          IF sy-subrc <> 0.
**     group node is not expanded yet
*            PERFORM expand_group USING ls_item-node_key.
*            lt_expanded = ls_item-node_key.
*            INSERT TABLE lt_expanded.
*          ENDIF.

            l_text = lt_roles-roleindex.
            CONDENSE l_text.
            READ TABLE gt_item INTO ls_item
               WITH KEY  item_name = 'ROLEINDEX'
                         text      = l_text.
            IF sy-subrc = 0.
              PERFORM expand_role   USING ls_item-node_key.
*--Expand all the conflict nodes
              LOOP AT gt_node INTO ls_node_con
               WHERE relatkey = ls_item-node_key.
                LOOP AT lt_rolecon WHERE roleindex = lt_roles-roleindex.
*--Get child node key?
                  l_text = lt_rolecon-conindex.
                  CONDENSE l_text.
                  READ TABLE gt_item INTO ls_item
                     WITH KEY  node_key  = ls_node_con-node_key
                               item_name = 'CONINDEX'
                               text      = l_text.
                  IF sy-subrc = 0.
                    PERFORM expand_rolecon USING ls_item-node_key.
                  ENDIF.
                ENDLOOP.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDLOOP.
        MESSAGE s002 WITH 'Nodes expanded'(x09).
      ELSE.
        MESSAGE s002 WITH 'No matching Conflict found'(x06).
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching Conflict found'(x06).
    ENDIF.

  ENDIF.

  IF gr_exp_funid = 'X'.

    IF p_fun = 'X'.
      MESSAGE s002 WITH 'Expand not possible'(x10).
      SET SCREEN 0.
      LEAVE SCREEN.
      LEAVE LIST-PROCESSING.
    ENDIF.
*--Get all conflicts that contain this function
    PERFORM get_function USING gf_exp_funid
                         CHANGING ls_function.
    SELECT * FROM /psyng/swrrscfun INTO TABLE lt_confun WHERE
      aid = p_aid AND funindex = ls_function-funindex.
    lt_conflict[] = lt_confun[].
    SORT lt_conflict BY conindex.
    DELETE ADJACENT DUPLICATES FROM lt_conflict COMPARING conindex.
*--Get all roles that have this conflict
    IF NOT lt_confun[] IS INITIAL.
      IF p_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex.
      ELSE.
        SELECT * FROM /psyng/swrrscon INTO TABLE lt_rolecon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex
            AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_rolecon[] IS INITIAL.
*--Get all the orgs that contain these users
        lt_roles[] = lt_rolecon[].
        SORT lt_roles BY roleindex.
        DELETE ADJACENT DUPLICATES FROM lt_roles COMPARING roleindex.
        LOOP AT gt_role.
          READ TABLE lt_roles WITH KEY roleindex = gt_role-roleindex
          BINARY SEARCH.
          IF sy-subrc = 0.
**--Expand the group if not expanded yet
*          READ TABLE gt_item INTO ls_item
*            WITH KEY item_name = 'GROUPNAME'
*                     text      = l_groupname.
*          READ TABLE lt_expanded WITH TABLE KEY
*            table_line =  ls_item-node_key.
*          IF sy-subrc <> 0.
**     group node is not expanded yet
*            PERFORM expand_group USING ls_item-node_key.
*            lt_expanded = ls_item-node_key.
*            INSERT TABLE lt_expanded.
*          ENDIF.
*--Expand all the role nodes
*  loop at lt_users.
            l_text = lt_roles-roleindex.
            CONDENSE l_text.
            READ TABLE gt_item INTO ls_item
               WITH KEY  item_name = 'ROLEINDEX'
                         text      = l_text.
            IF sy-subrc = 0.
              PERFORM expand_role   USING ls_item-node_key.
*--Expand all the conflict nodes
              LOOP AT gt_node INTO ls_node_con
               WHERE relatkey = ls_item-node_key.
                LOOP AT lt_rolecon WHERE roleindex = lt_roles-roleindex.
*--Get child node key?
                  l_text = lt_rolecon-conindex.
                  CONDENSE l_text.
                  READ TABLE gt_item INTO ls_item
                     WITH KEY  node_key  = ls_node_con-node_key
                               item_name = 'CONINDEX'
                               text      = l_text.
                  IF sy-subrc = 0.
                    PERFORM expand_rolecon USING ls_item-node_key.
                    LOOP AT gt_node INTO ls_node
                     WHERE relatkey = ls_item-node_key.
                 LOOP AT lt_confun WHERE conindex = lt_rolecon-conindex.
                        l_text = lt_confun-funindex.
                        CONDENSE l_text.
*  --Expand all the function nodes for this conflict for this user
                        READ TABLE gt_item INTO ls_item
                           WITH KEY  node_key  = ls_node-node_key
                                     item_name = 'FUNINDEX'
                                     text      = l_text.
                        IF sy-subrc = 0.
                         PERFORM expand_function USING ls_item-node_key.
                        ENDIF.
                      ENDLOOP.
                    ENDLOOP.
                  ENDIF.
                ENDLOOP.
              ENDLOOP.
            ENDIF.
          ENDIF.
        ENDLOOP.
        MESSAGE s002 WITH 'Nodes expanded'(x09).
      ELSE.
        MESSAGE s002 WITH 'No matching function found'(x01).
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching function found'(x01).
    ENDIF.
  ENDIF.
*--Un-Hide tree control
  CALL METHOD go_tree->set_visible
    EXPORTING
      visible = 'X'
*  EXCEPTIONS
*     CNTL_ERROR        = 1
*     CNTL_SYSTEM_ERROR = 2
*     others  = 3
    .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
*  MESSAGE s002(/psyng/sw) WITH
*  'Selected nodes expanded'(x03).
*  COMMIT WORK.
  CLEAR : gf_exp_conid, gf_exp_funid, gf_exp_role.
  SET SCREEN 0.
  LEAVE SCREEN.

*ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM add_auth_node                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_NODE                                                       *
*  -->  ET_ITEM                                                       *
*  -->  I_KEY                                                         *
*  -->  IS_AUTHDET                                                    *
*  -->  IS_NODE                                                       *
*---------------------------------------------------------------------*
FORM add_auth_node
  TABLES
    et_node          STRUCTURE  treev_node
    et_item          STRUCTURE  mtreeitm
  USING
    i_key            TYPE tv_nodekey
    is_authdet       TYPE /psyng/serrs_authdetail
*    i_parent         TYPE tv_nodekey
  CHANGING
    es_node          TYPE treev_node.

  DATA : ls_node TYPE treev_node,
         l_text  TYPE string.
  ls_node = es_node."for use in macro
  ADD 1 TO g_auth_id.

  PERFORM get_text_system
    USING gs_hdr-sysid
    CHANGING l_text.

  leaf_node et_node et_item i_key 'A' g_auth_id
  is_authdet-auth l_text '@C9@' '' .
  link_column et_item ls_node-node_key :
          'CHILD_ROLE' is_authdet-childrole ''.
  link_column_style  et_item ls_node-node_key
          'TCODE'     is_authdet-tcode  ''
          cl_gui_column_tree=>style_intensified.
  link_column  et_item ls_node-node_key :
          'OBJECT'    is_authdet-object '' ,
          'FIELD'     is_authdet-field  '' .

  link_column et_item ls_node-node_key
          'VAL_FROM'  is_authdet-von ''.
  IF NOT  is_authdet-bis IS INITIAL.
    link_column et_item ls_node-node_key
           'VAL_TO'   is_authdet-bis ''.
  ENDIF.
  es_node = ls_node.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM add_auth_node                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_NODE                                                       *
*  -->  ET_ITEM                                                       *
*  -->  I_KEY                                                         *
*  -->  IS_AUTHDET                                                    *
*  -->  I_VAREL                                                       *
*  -->  ES_NODE                                                       *
*---------------------------------------------------------------------*
FORM add_varel_node
  TABLES
    et_node          STRUCTURE  treev_node
    et_item          STRUCTURE  mtreeitm
  USING
    i_key            TYPE tv_nodekey
    is_authdet       TYPE /psyng/serrs_authdetail
    i_varel          TYPE xuval
*    i_profindex      TYPE i
  CHANGING
    es_node          TYPE treev_node.
  DATA : ls_node TYPE treev_node.
  ls_node = es_node."for use in macro

  ADD 1 TO g_auth_id.
  child_node et_node et_item i_key 'V' g_auth_id
  i_varel i_varel '@GP@' '' .
  hidden_column et_item ls_node-node_key
  'NODETYPE'   'VAREL'.
*  hidden_column et_item ls_node-node_key
*  'PROFINDEX'   i_profindex.
*  READ TABLE gt_system WITH KEY sysid = is_authdet-sysid.
*  IF sy-subrc = 0.
*    hidden_column et_item ls_node-node_key
*    'SYSINDEX'   gt_system-sysindex.
*  ENDIF.

*  link_column et_item ls_node-node_key :
*          'PROFILE'   is_authdet-profname ''.
*  link_column_style  et_item ls_node-node_key
*         'TCODE'     is_authdet-tcode  ''
*        cl_gui_column_tree=>style_intensified.
  link_column  et_item ls_node-node_key :
*        'OBJECT'    is_authdet-object '' ,
        'FIELD'     is_authdet-field  '' .
*  link_column_style  et_item ls_node-node_key
*          'VAL_FROM'  i_varel  ''
*          cl_gui_column_tree=>style_intensified.

  es_node = ls_node.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM add_org_node                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_NODE                                                       *
*  -->  ET_ITEM                                                       *
*  -->  I_KEY                                                         *
*  -->  IS_AUTHDET                                                    *
*  -->  I_ORG                                                         *
*  -->  I_PROFINDEX                                                   *
*  -->  ES_NODE                                                       *
*---------------------------------------------------------------------*
FORM add_org_node
  TABLES
    et_node          STRUCTURE  treev_node
    et_item          STRUCTURE  mtreeitm
  USING
    i_key            TYPE tv_nodekey
    is_authdet       TYPE /psyng/serrs_authdetail
    i_org            TYPE /psyng/dorg_abb
*    i_profindex      TYPE i
  CHANGING
    es_node          TYPE treev_node.
  DATA : ls_node TYPE treev_node.
  ls_node = es_node."for use in macro

  ADD 1 TO g_auth_id.
  child_node et_node et_item i_key 'V' g_auth_id
  i_org i_org '@BN@' '' .
  hidden_column et_item ls_node-node_key
  'NODETYPE'   'ORG'.
*  hidden_column et_item ls_node-node_key
*  'PROFINDEX'   i_profindex.
*  READ TABLE gt_system WITH KEY sysid = is_authdet-sysid.
*  IF sy-subrc = 0.
*    hidden_column et_item ls_node-node_key
*    'SYSINDEX'   gt_system-sysindex.
*  ENDIF.

*  link_column et_item ls_node-node_key :
*          'PROFILE'   is_authdet-profname ''.
*  link_column_style  et_item ls_node-node_key
*         'TCODE'     is_authdet-tcode  ''
*        cl_gui_column_tree=>style_intensified.
*  link_column  et_item ls_node-node_key :
*        'OBJECT'    is_authdet-object '' ,
*        'FIELD'     is_authdet-field  '' .
*  link_column_style  et_item ls_node-node_key
*          'VAL_FROM'  i_org  ''
*          cl_gui_column_tree=>style_intensified.

  es_node = ls_node.

ENDFORM.

*---------------------------------------------------------------------*
*       MODULE f4_bname INPUT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE f4_role INPUT.
  IF sy-dynnr = '0101'.
    PERFORM f4_role USING 'EXP'.
  ELSE.
    PERFORM f4_role USING 'FND'.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE f4_conid INPUT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE f4_conid INPUT.
  IF sy-dynnr = '0101'.
    PERFORM f4_conid USING 'EXP'.
  ELSE.
    PERFORM f4_conid USING 'FND'.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE f4_funid INPUT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE f4_funid INPUT.
  IF sy-dynnr = '0101'.
    PERFORM f4_funid USING 'EXP'.
  ELSE.
    PERFORM f4_funid USING 'FND'.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM f4_bname                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TYPE                                                        *
*---------------------------------------------------------------------*
FORM f4_role USING i_type TYPE agr_define-agr_name.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  LOOP AT gt_role.
    lt_values-line = gt_role-agr_name.
    APPEND lt_values.
    lt_values-line = gt_role-agr_text.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = 'AGR_TEXTS'.
  lt_fields-fieldname = 'AGR_NAME'.
  APPEND lt_fields.
  lt_fields-tabname   = 'AGR_TEXTS'.
  lt_fields-fieldname = 'TEXT'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'AGR_NAME'
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

  READ TABLE lt_return INDEX 1.
  IF sy-subrc = 0.
    IF i_type = 'EXP'.
      gf_exp_role = lt_return-fieldval.
    ELSE.
      gf_fnd_role = lt_return-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.
*
**---------------------------------------------------------------------*
**       FORM f4_conid                                                 *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  I_TYPE                                                        *
**---------------------------------------------------------------------*
FORM f4_conid USING i_type TYPE usr02-bname.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        l_conid_desc TYPE /psyng/conflict-description,
        l_sod        TYPE /psyng/conflict-vrsio.

  SELECT SINGLE sodvrsio FROM /psyng/swrrshdr INTO (l_sod)
  WHERE aid = p_aid.
  LOOP AT gt_conflict.
    lt_values-line = gt_conflict-conid.
    APPEND lt_values.
    SELECT SINGLE description FROM /psyng/conflict INTO
    (l_conid_desc) WHERE conid  = gt_conflict-conid
                   AND vrsio = l_sod.
    lt_values-line = l_conid_desc.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/CONFLICT'.
  lt_fields-fieldname = 'CONID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/CONFLICT'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'CONID'
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

  READ TABLE lt_return INDEX 1.
  IF sy-subrc = 0.
    IF i_type = 'EXP'.
      gf_exp_conid = lt_return-fieldval.
    ELSE.
      gf_fnd_conid = lt_return-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM expand_by_key                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_KEY                                                         *
*---------------------------------------------------------------------*
FORM expand_by_key USING i_key.
  DATA : l_type TYPE string.

  l_type = i_key(2).
  CASE l_type.
    WHEN  'G_'.
      PERFORM expand_group    USING i_key.
    WHEN  'S_'.
      PERFORM expand_role    USING i_key.
    WHEN  'C_'.
      PERFORM expand_rolecon  USING i_key.
    WHEN  'F_'.
      PERFORM expand_function  USING i_key.
    WHEN OTHERS.
      CALL METHOD go_tree->expand_node
        EXPORTING
          node_key            = i_key
        EXCEPTIONS
          failed              = 1
          illegal_level_count = 2
          cntl_system_error   = 3
          node_not_found      = 4
          cannot_expand_leaf  = 5
          OTHERS              = 6.
      IF sy-subrc <> 0.
*--ignore these exceptions

      ENDIF.

  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM expand_collapsed_children                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODEKEY                                                     *
*  -->  IT_EXPANDED                                                   *
*---------------------------------------------------------------------*
FORM expand_collapsed_children
USING i_nodekey   TYPE tv_nodekey
      it_expanded TYPE treev_nks.
  DATA : ls_node   LIKE LINE OF gt_node.


  LOOP AT gt_node INTO ls_node
    WHERE relatkey = i_nodekey AND
          isfolder = 'X'.
*--If we encounter a node that isn't expanded, expand it,
*  else go deeper until we do
    READ TABLE it_expanded WITH KEY table_line = ls_node-node_key
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      PERFORM expand_collapsed_children
      USING ls_node-node_key
            it_expanded.
    ELSE.
*--Not expanded yet, expand now
      PERFORM expand_by_key USING ls_node-node_key.
    ENDIF.
  ENDLOOP.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM expand_next_level                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM expand_next_level.
  DATA: ls_exp_node LIKE LINE OF gt_node,
        ls_expand   LIKE LINE OF gt_node,
        lt_expanded TYPE treev_nks.

*  lt_node[] = gt_node[].

*--Get all expanded node keys
  CALL METHOD go_tree->get_expanded_nodes
*  EXPORTING
*    NO_HIDDEN_NODES   =
    CHANGING
      node_key_table    = lt_expanded
    EXCEPTIONS
      cntl_system_error = 1
      dp_error          = 2
      failed            = 3
      OTHERS            = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  SORT lt_expanded.

  CALL METHOD go_tree->get_selected_node
    IMPORTING
      node_key                   = g_node_key
    EXCEPTIONS
      failed                     = 1
      single_node_selection_only = 2
      cntl_system_error          = 3.
  IF g_node_key IS INITIAL.
*--No node selected, start with root
    READ TABLE gt_node WITH KEY node_key = 'R_DATA'
    INTO ls_exp_node.
    g_node_key = ls_exp_node-node_key.
  ENDIF.
*--If the selected node is not expanded yet, expand it first
  READ TABLE lt_expanded WITH KEY table_line = g_node_key
  BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
    PERFORM expand_collapsed_children
    USING g_node_key
          lt_expanded.
  ELSE.
*--Not expanded yet, expand now
    PERFORM expand_by_key USING g_node_key.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM f4_funid                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TYPE                                                        *
*---------------------------------------------------------------------*
FORM f4_funid USING i_type TYPE usr02-bname.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_swrrsifun TYPE TABLE OF /psyng/swrrsifun WITH HEADER LINE,
        l_conid_desc TYPE /psyng/conflict-description,
        l_sod        TYPE /psyng/conflict-vrsio.
  SELECT * FROM /psyng/swrrsifun INTO TABLE lt_swrrsifun
  WHERE aid = p_aid.

  SELECT SINGLE sodvrsio FROM /psyng/swrrshdr INTO (l_sod)
  WHERE aid = p_aid.
  LOOP AT lt_swrrsifun.
    lt_values-line = lt_swrrsifun-funid.
    APPEND lt_values.
    SELECT SINGLE description FROM /psyng/function INTO
    (l_conid_desc) WHERE function  = lt_swrrsifun-funid
                   AND vrsio = l_sod.
    lt_values-line = l_conid_desc.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/FUNCTION'.
  lt_fields-fieldname = 'FUNCTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/FUNCTION'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'FUNCTION'
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

  READ TABLE lt_return INDEX 1.
  IF sy-subrc = 0.
    IF i_type = 'EXP'.
      gf_exp_funid = lt_return-fieldval.
    ELSE.
      gf_fnd_funid = lt_return-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       MODULE STATUS_0400 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0400 OUTPUT.
  SET PF-STATUS '0400'.
  SET TITLEBAR '400'.
ENDMODULE.
*---------------------------------------------------------------------*
*       FORM advise_syswide_analysis                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM advise_syswide_analysis CHANGING e_continue TYPE flag.
  DATA: lt_decidetext   TYPE TABLE OF tline WITH HEADER LINE,
        lt_decidehtml   TYPE TABLE OF htmlline WITH HEADER LINE,
        l_head          TYPE thead,
        lt_parmvalues   TYPE TABLE OF parmvalues,
        ls_paramvalue   TYPE parmvalues,
        l_max_runtime   TYPE wpelzeit,
        l_runtime_param TYPE i.
  DATA:  lt_seltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  FIELD-SYMBOLS : <line> TYPE tline.


*--Get max time for workprocess
  ls_paramvalue-param_name = 'rdisp/max_wprun_time'.
  APPEND ls_paramvalue TO lt_parmvalues.
  CALL FUNCTION 'PFL_GET_PARAMETER'
    TABLES
      parameter_table = lt_parmvalues
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             authorization_missing = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
  READ TABLE lt_parmvalues INDEX 1 INTO ls_paramvalue.
  IF ls_paramvalue-user_value CS 'H' OR ls_paramvalue-user_value CS 'M'.
*--Later versions of SAP allow H for hours and M for minutes
*  in this parameter
    IF ls_paramvalue-user_value CS 'H'.
      SEARCH ls_paramvalue-user_value FOR 'H'.
      l_runtime_param = ls_paramvalue-user_value(sy-fdpos).
      l_max_runtime = l_runtime_param * 3600.
    ELSE.
      SEARCH ls_paramvalue-user_value FOR 'M'.
      l_runtime_param = ls_paramvalue-user_value(sy-fdpos).
      l_max_runtime = l_runtime_param * 60.
    ENDIF.
  ELSE.
    l_max_runtime    = ls_paramvalue-user_value.
  ENDIF.


*--Get text
  CALL FUNCTION 'DOC_OBJECT_GET'
    EXPORTING
      class            = 'TX'
      name             = '/PSYNG/SW_I000003'
      appendix         = 'X'
    IMPORTING
      header           = l_head
    TABLES
      itf_lines        = lt_decidetext
    EXCEPTIONS
      object_not_found = 1
      OTHERS           = 2.
  IF sy-subrc <> 0.
    IF sy-langu <> 'E'.
*       Try in English
      CALL FUNCTION 'DOC_OBJECT_GET'
        EXPORTING
          class            = 'TX'
          name             = '/PSYNG/SW_I000002'
          language         = 'E'
          appendix         = 'X'
        IMPORTING
          header           = l_head
        TABLES
          itf_lines        = lt_decidetext
        EXCEPTIONS
          object_not_found = 1
          OTHERS           = 2.
*BOC:HBHALLA (04/12/24)
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE s002(/psyng/sw)
            WITH 'Object Not found'.
          WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
        ENDCASE.
      ENDIF.
*EOC:HBHALLA (04/12/24)
    ENDIF.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
  ENDIF.
*--replace placeholders
*[rdisp/max_wprun_time]
  LOOP AT lt_decidetext ASSIGNING <line>.
    REPLACE '[rdisp/max_wprun_time]'  WITH l_max_runtime
                                      INTO <line>-tdline.
  ENDLOOP.
*--convert to html
  CALL FUNCTION 'CONVERT_ITF_TO_HTML'
    EXPORTING
*     I_CODEPAGE     =
      i_header       = l_head
      i_bgcolor      = '#FEFEEE'
    TABLES
      t_itf_text     = lt_decidetext
      t_html_text    = lt_decidehtml
    EXCEPTIONS
      syntax_check   = 1
      replace        = 2
      illegal_header = 3
      OTHERS         = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  REFRESH i_text.
  LOOP AT lt_decidehtml.
    i_text = lt_decidehtml-tdline.
    APPEND i_text.
  ENDLOOP.

  CALL SCREEN 400 STARTING AT 2 2.
  IF sy-ucomm <> 'NO'. "continue
    e_continue = 'X'.
  ELSE. " cancel
    CLEAR e_continue.
    EXIT.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       MODULE init_editor400 OUTPUT                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE init_editor400 OUTPUT.

  DATA: meditor_container TYPE REF TO cl_gui_custom_container.
  DATA: mtext_editor TYPE REF TO cl_gui_textedit.
  DATA: lc_html_viewer TYPE REF TO cl_gui_html_viewer.
  DATA: m_editor_text(132) TYPE c OCCURS 0,
        l_url              TYPE epssurl.

*  CONCATENATE sy-uname 'SWWARNING' sy-uzeit INTO l_url. "C0700
  CONCATENATE g_current_user 'SWWARNING' sy-uzeit INTO l_url. "C0700
*--Dhorions 20101117 : Sap considers a url with a ":" in it to be an
*  absolute url, so we need to make sure there isn't one
  WHILE l_url CS ':'.
    REPLACE ':' WITH '_' INTO l_url.
  ENDWHILE.
  IF meditor_container IS INITIAL.

*   create control container
    CREATE OBJECT meditor_container
      EXPORTING
        container_name              = 'MTEXTEDITOR'
*       repid                       = g_repid
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5.

    IF sy-subrc NE 0.
      MESSAGE e802(bmen).
    ENDIF.
    CREATE OBJECT lc_html_viewer
      EXPORTING
        parent             = meditor_container
      EXCEPTIONS
        cntl_error         = 1
        cntl_install_error = 2
        dp_install_error   = 3
        dp_error           = 4
        OTHERS             = 5.
    IF sy-subrc <> 0.
      MESSAGE e802(bmen).
    ENDIF.


  ENDIF.

*   copy text
  m_editor_text[] = i_text[].
  CALL METHOD lc_html_viewer->load_data
    EXPORTING
      url                  = l_url
*     TYPE                 = 'text'
*     SUBTYPE              = 'html'
*     SIZE                 = 0
    IMPORTING
      assigned_url         = l_url
    CHANGING
      data_table           = m_editor_text
    EXCEPTIONS
      dp_invalid_parameter = 1
      dp_error_general     = 2
      cntl_error           = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
    MESSAGE e802(bmen).
  ENDIF.

  CALL METHOD lc_html_viewer->show_url
    EXPORTING
      url                    = l_url
*     FRAME                  =
*     IN_PLACE               = ' X'
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.
  IF sy-subrc <> 0.
    MESSAGE e802(bmen).
  ENDIF.

  CALL METHOD cl_gui_cfw=>update_view
    EXCEPTIONS
      OTHERS = 1.
  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

*   finally flush
  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc NE 0.
    MESSAGE e802(bmen).
  ENDIF.

ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE user_command_0400 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0400 INPUT.
  CALL METHOD lc_html_viewer->finalize.
  CALL METHOD meditor_container->free.
  FREE : meditor_container, lc_html_viewer.
  LEAVE TO SCREEN 0.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  get_text_conflict
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_CONFLICT_CONID  text
*      <--P_L_DESCRIPTION  text
*----------------------------------------------------------------------*
FORM get_text_conflict USING    i_conid
                       CHANGING e_description.
  STATICS : st_conflict TYPE HASHED TABLE OF /psyng/conflict
                        WITH HEADER LINE
                        WITH UNIQUE KEY conid.
  READ TABLE st_conflict WITH TABLE KEY conid = i_conid.
  IF sy-subrc = 0.
    e_description = st_conflict-description.
  ELSE.

    SELECT SINGLE conid description
      FROM /psyng/conflict INTO CORRESPONDING FIELDS OF st_conflict
                           WHERE vrsio =  gs_hdr-sodvrsio AND
                                 conid = i_conid.
    INSERT TABLE st_conflict.
    e_description = st_conflict-description.
  ENDIF.
ENDFORM.                    " get_text_conflict
*&---------------------------------------------------------------------*
*&      Form  get_text_system
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_AUTHDET_SYSID  text
*      <--P_L_DESTINATION  text
*----------------------------------------------------------------------*
FORM get_text_system USING    i_sysid
                     CHANGING e_destination.
  STATICS : st_rfcdes TYPE HASHED TABLE OF /psyng/sw_rfcdes
                        WITH HEADER LINE
                        WITH UNIQUE KEY systid.
  READ TABLE st_rfcdes WITH TABLE KEY systid = i_sysid.
  IF sy-subrc = 0.
    CONCATENATE i_sysid '-' st_rfcdes-description INTO e_destination
    SEPARATED BY space.
*    e_destination = st_rfcdes-description.
  ELSE.

    SELECT SINGLE systid rfcdest description FROM /psyng/sw_rfcdes
      INTO CORRESPONDING FIELDS OF st_rfcdes
      WHERE systid = i_sysid.
    INSERT TABLE st_rfcdes.
    CONCATENATE i_sysid '-' st_rfcdes-description INTO e_destination
    SEPARATED BY space.
*    e_destination = st_rfcdes-DESCRIPTION.
  ENDIF.
ENDFORM.                    " get_text_system

*---------------------------------------------------------------------*
*       FORM get_destination_system                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_SYSID                                                       *
*  -->  E_DESTINATION                                                 *
*---------------------------------------------------------------------*
*FORM get_destination_system USING    i_sysid
*                     CHANGING e_destination.
*  STATICS : st_rfcdes TYPE HASHED TABLE OF /psyng/sw_rfcdes
*                        WITH HEADER LINE
*                        WITH UNIQUE KEY systid.
*  READ TABLE st_rfcdes WITH TABLE KEY systid = i_sysid.
*  IF sy-subrc = 0.
*    e_destination = st_rfcdes-rfcdest.
*  ELSE.
*
*    SELECT SINGLE systid rfcdest FROM /psyng/sw_rfcdes
*      INTO CORRESPONDING FIELDS OF st_rfcdes
*      WHERE systid = i_sysid.
*    INSERT TABLE st_rfcdes.
*    e_destination = st_rfcdes-rfcdest.
*  ENDIF.
*ENDFORM.                    " get_destination_system

*&---------------------------------------------------------------------*
*&      Form  get_text_function
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_FUNCTION_FUNID  text
*      <--P_L_FDESCRIPTION  text
*----------------------------------------------------------------------*
FORM get_text_function USING    i_funid
                       CHANGING e_description.

  STATICS : st_function TYPE HASHED TABLE OF /psyng/function
                        WITH HEADER LINE
                        WITH UNIQUE KEY function.
  READ TABLE st_function  WITH TABLE KEY function = i_funid.
  IF sy-subrc = 0.
    e_description = st_function-description.
  ELSE.

    SELECT SINGLE function description
      FROM /psyng/function INTO CORRESPONDING FIELDS OF st_function
                           WHERE vrsio    =  gs_hdr-sodvrsio AND
                                 function = i_funid.
    INSERT TABLE st_function.
    e_description = st_function-description.
  ENDIF.



ENDFORM.                    " get_text_function
*&---------------------------------------------------------------------*
*&      Form  get_function
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GF_EXP_FUNID  text
*      <--P_LS_FUNCTION  text
*----------------------------------------------------------------------*
FORM get_function USING    i_funid
                  CHANGING es_function TYPE /psyng/swrrsifun.
  STATICS : st_function TYPE HASHED TABLE OF /psyng/swrrsifun
                        WITH HEADER LINE
                        WITH UNIQUE KEY funid.
  READ TABLE st_function WITH TABLE KEY funid = i_funid
  INTO es_function.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM /psyng/swrrsifun INTO es_function WHERE
      aid = p_aid AND funid = i_funid.
    INSERT es_function INTO TABLE st_function.
  ENDIF.

ENDFORM.                    " get_function

*---------------------------------------------------------------------*
*       FORM get_function_by_index                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FUNINDEX                                                    *
*  -->  ES_FUNCTION                                                   *
*---------------------------------------------------------------------*
FORM get_function_by_index USING    i_funindex
                  CHANGING es_function TYPE /psyng/swrrsifun.
  STATICS : st_function TYPE HASHED TABLE OF /psyng/swrrsifun
                        WITH HEADER LINE
                        WITH UNIQUE KEY funindex.
  READ TABLE st_function WITH TABLE KEY funindex = i_funindex
  INTO es_function.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM /psyng/swrrsifun INTO es_function WHERE
      aid = p_aid AND funindex = i_funindex.
    INSERT es_function INTO TABLE st_function.
  ENDIF.

ENDFORM.                    " get_function
*---------------------------------------------------------------------*
*       FORM display_role_of_remote_system                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDS                                                        *
*  -->  CODE                                                          *
*  -->  ERROR                                                         *
*  -->  SHOW_POPUP                                                    *
*---------------------------------------------------------------------*
FORM display_role_of_remote_system TABLES   fields STRUCTURE sval
                   USING    code
                   CHANGING error  STRUCTURE svale show_popup.
  CASE code.
    WHEN 'EXECUTE'.
    WHEN 'EXIT'.
    WHEN 'OK'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_matching_roles
*&---------------------------------------------------------------------*
*       Filter the list of all roles by the roles
*      that have the conflict
*----------------------------------------------------------------------*
*      -->P_GT_USERS  text
*      -->P_LT_MATCH_USERS  text
*----------------------------------------------------------------------*
FORM get_matching_roles TABLES
    it_roles STRUCTURE /psyng/swrrscon
    et_match_roles STRUCTURE /psyng/swrrsrol.
  LOOP AT it_roles.
    READ TABLE gt_role WITH KEY roleindex = it_roles-roleindex
    BINARY SEARCH.
    IF sy-subrc = 0.
      APPEND gt_role TO et_match_roles.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " get_matching_roles
*&---------------------------------------------------------------------*
*&      Form  export_to_file
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM export_to_file USING if_ask TYPE flag
                    CHANGING ef_cancel.
  STATICS : l_filename TYPE string,
            l_path     TYPE string,
            l_fullpath TYPE string,
            l_act      TYPE i,
            l_ext      TYPE string,
            l_type     TYPE char10,
            l_filter   TYPE string,
            l_title    TYPE string,
            l_index    TYPE i.
  DATA : l_filenamenum TYPE string,
         l_num         TYPE string,
         lf_exists     TYPE flag,
         lf_name_ok    TYPE flag,
         l_answ,
ls_excel_header TYPE c LENGTH 30,"HBHALLA
* BOC by AKUMAR for C0765
         lv_fname_len  TYPE i,
         l_dat_mode    VALUE ' ',
         l_wrt_sep     VALUE '|'.
*  IF if_ask = 'X'.
* EOC by AKUMAR for C0765
*---BOC AKUMAR OPL518
  DATA: l_nodetype  TYPE string,
          l_rest      TYPE string,
          gv_mask     TYPE char255 VALUE 'XXXXXXXXXXXXXXX',
          lv_space    TYPE c VALUE ' '.
*EOC AKUMAR OPL518

*BOC:HBHALLA (PN-12517) (20/04/25)
  DATA : lv_line  TYPE string,
          lv_offset TYPE i,
          lv_final TYPE string,
          lv_xstring TYPE xstring,
          lt_header TYPE STANDARD TABLE OF char250.
*EOC:HBHALLA (PN-12517) (20/04/25)

  CLEAR l_index.
*--Later SAP versions support excel download
  IF sy-saprl < '500'.
    l_ext = 'txt'.
    l_type = 'ASC'.
    l_filter = 'Text files(*.txt)|*.TXT'.
  ELSE.
    l_ext    = 'txt'.
* BOC by AKUMAR for C0765 - Changing the file Type to DAT to fix the excel file wrong header issue
*    l_type   = 'DBF'.
    l_type   = 'DAT'.
* EOC by AKUMAR for C0765
    l_filter = 'Text files(*.txt)|*.TXT|Excel files (*.XLS)|*.XLS'.
  ENDIF.

  CONCATENATE 'SOD Analysis Results - '(f01)
              p_aid INTO  l_filename SEPARATED BY space.
  l_title = 'Save to local file'(f02).
  WHILE NOT lf_name_ok = 'X'.
    CALL METHOD cl_gui_frontend_services=>file_save_dialog
                                       "#EC SAST_CI_GEN_CHECK (HBHALLA)
      EXPORTING
        window_title      = l_title
        default_extension = l_ext
        default_file_name = l_filename
        file_filter       = l_filter
        initial_directory = 'c:\temp\'
      CHANGING
        filename          = l_filename
        path              = l_path
        fullpath          = l_fullpath
        user_action       = l_act
      EXCEPTIONS
        cntl_error        = 1
        error_no_gui      = 2
        OTHERS            = 3.
    IF sy-subrc = 0.
      IF l_act <> 0.
        ef_cancel = 'X'.
        EXIT.
      ENDIF..

      l_filenamenum = l_fullpath.
      l_num = '1'.
      PERFORM add_nr_to_filename
        USING
          l_num
        CHANGING
          l_filenamenum.
      CALL METHOD cl_gui_frontend_services=>file_exist
                                       "#EC SAST_CI_GEN_CHECK (HBHALLA)
        EXPORTING
          file            = l_filenamenum
        RECEIVING
          result          = lf_exists
        EXCEPTIONS
          cntl_error      = 1
          error_no_gui    = 2
          wrong_parameter = 3
          OTHERS          = 4.
      IF sy-subrc <> 0.
      ELSE.
        IF lf_exists <> 'X'.
          lf_name_ok = 'X'.
        ELSE.
          CALL FUNCTION 'POPUP_TO_CONFIRM'
            EXPORTING
              titlebar      = 'File already exists'
              text_question = 'Do you want to overwrite?'
              text_button_1 = 'Yes'(003)
              text_button_2 = 'No'(002)
            IMPORTING
              answer        = l_answ
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          "(++)EOC UMITTAL SE VF scan-25/11/2024.
          IF l_answ = '1'.
            lf_name_ok = 'X'.
          ENDIF.
        ENDIF.
      ENDIF.

    ELSE.
*  --download issue?

    ENDIF.
  ENDWHILE.
*  ENDIF. "C0765
  IF l_act <> 0.
    ef_cancel = 'X'.
  ELSE.
    ADD 1 TO l_index.
    l_num = l_index.
    l_filenamenum = l_fullpath.
    PERFORM add_nr_to_filename
      USING
        l_num
      CHANGING
        l_filenamenum.
    REFRESH gt_excel_header.
    PERFORM excel_header CHANGING gt_excel_header.

    IF p_mitcon IS INITIAL.
      PERFORM set_mask USING 5 CHANGING gv_mask.
    ENDIF.

*-- Hide unwanted node if child node selected
    SPLIT g_node_key AT '_' INTO l_nodetype l_rest.
    CASE l_nodetype.
      WHEN 'C'. " conflict
        PERFORM set_mask USING 1 CHANGING gv_mask.
        PERFORM set_mask USING 3 CHANGING gv_mask.
        PERFORM set_mask USING 4 CHANGING gv_mask.
      WHEN 'F'. "function
        PERFORM set_mask USING 1 CHANGING gv_mask.
        PERFORM set_mask USING 2 CHANGING gv_mask.
        PERFORM set_mask USING 3 CHANGING gv_mask.
        PERFORM set_mask USING 4 CHANGING gv_mask.
        PERFORM set_mask USING 5 CHANGING gv_mask.
*    WHEN 'S'. " Role
*      lt_fieldcat-no_out = 'X'.
*    MODIFY lt_fieldcat TRANSPORTING no_out
*     WHERE    fieldname = 'AGR_NAME'
*     OR fieldname = 'CONID'
*     OR fieldname = 'FUNID' .
    ENDCASE.

*---selected o/p expand level
    IF p_fun = 'X'.
      PERFORM set_mask USING 7 CHANGING gv_mask.
      PERFORM set_mask USING 8 CHANGING gv_mask.
      PERFORM set_mask USING 9 CHANGING gv_mask.
      PERFORM set_mask USING 10 CHANGING gv_mask.
      PERFORM set_mask USING 11 CHANGING gv_mask.
      PERFORM set_mask USING 12 CHANGING gv_mask.
      PERFORM set_mask USING 13 CHANGING gv_mask.
      PERFORM set_mask USING 14 CHANGING gv_mask.
      PERFORM set_mask USING 15 CHANGING gv_mask.
    ENDIF.
* BOC by AKUMAR for C0765 - Text file download issue with '.DBF' file type
* Check the file extension
    lv_fname_len = strlen( l_filenamenum ) - 4.
    IF l_filenamenum+lv_fname_len(4) = '.TXT'.
      l_type    = 'ASC'.
      l_wrt_sep = 'X'.
    ELSE.
      l_dat_mode = 'X'.
    ENDIF.
* EOC by AKUMAR

*BOC:HBHALLA (096)
    AUTHORITY-CHECK OBJECT  'S_GUI'
                     ID      'ACTVT'
                     FIELD   '61'.
    IF sy-subrc = 0.

*BOC:HBHALLA (PN-12517) (20/04/25)
*Fieldnames table creation with column width
*synched with data_tab

      LOOP AT gt_excel_header INTO ls_excel_header.
        lv_offset = sy-tabix - 1.
        IF gv_mask+lv_offset(1) = 'X'.
          CASE lv_offset.
            WHEN 0.
              CONCATENATE lv_final ls_excel_header INTO lv_final.
              CLEAR lv_line.
            WHEN 1.
              CONCATENATE ls_excel_header
              '    ' INTO lv_line.
              CONCATENATE lv_final  lv_line INTO lv_final
              SEPARATED BY '                     ' .
              CLEAR lv_line.
            WHEN 2.
              CONCATENATE ls_excel_header
              ' ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '    '.

              CLEAR lv_line.
            WHEN 3.
              CONCATENATE ls_excel_header "HBHALLA (22/04/25)
              ' ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY ' '.
              CLEAR lv_line.
            WHEN 4.
              CONCATENATE ls_excel_header
              '' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY ''.
              CLEAR lv_line.
            WHEN 5.
              CONCATENATE ls_excel_header
              '    ' INTO lv_line.
              CONCATENATE lv_final lv_line  INTO lv_final
              SEPARATED BY ''.
              CLEAR lv_line.
            WHEN 6.
              CONCATENATE ls_excel_header
              '                    ' INTO lv_line.
              CONCATENATE lv_final lv_line
              INTO lv_final
              SEPARATED BY ' '.
              CLEAR lv_line.
            WHEN 7.
              CONCATENATE ls_excel_header
              '' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '                   '.
              CLEAR lv_line.
            WHEN 8.
              CONCATENATE ls_excel_header
              '               ' INTO lv_line.
              CONCATENATE lv_final lv_line
                INTO lv_final SEPARATED BY '  '.
              CLEAR lv_line.
            WHEN 9.
              CONCATENATE ls_excel_header
              '' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
*           SEPARATED BY '                   ' .
               SEPARATED BY '                  ' . "HBHALLA (22/04/25)
              CLEAR lv_line.
            WHEN 10.
              CONCATENATE ls_excel_header
              '    ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
*           SEPARATED BY '                         '.
               SEPARATED BY ''. "HBHALLA (22/04/25)
              CLEAR lv_line.
            WHEN 11.
              CONCATENATE ls_excel_header
              '     ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '                 '.
              CLEAR lv_line.
            WHEN 12.
              CONCATENATE ls_excel_header
              '' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '         ' .
              CLEAR lv_line.
            WHEN 13.
              CONCATENATE ls_excel_header
              '  ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '  ' .
              CLEAR lv_line.
            WHEN 14.
              CONCATENATE ls_excel_header
              '  ' INTO lv_line.
              CONCATENATE lv_final lv_line INTO lv_final
              SEPARATED BY '  '.
              CLEAR lv_line.
          ENDCASE.
        ENDIF.
      ENDLOOP.

      APPEND lv_final TO lt_header.

*EOC:HBHALLA (PN-12517) (20/04/25)
      IF l_type = 'ASC'. "HBHALLA (22/04/25) (PN-12517)
        CALL FUNCTION 'GUI_DOWNLOAD'             "#EC SAST_CI_GEN_CHECK
          EXPORTING
            filename                = l_filenamenum
            filetype                = l_type
            write_field_separator   = 'X' "HBHALLA
            dat_mode                = ' '
            col_select            = 'X'
            col_select_mask       = gv_mask
          TABLES
            data_tab                = gt_output_alv
           fieldnames               = lt_header "HBHALLA
*       fieldnames               = gt_excel_header "HBHALLA
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
          PERFORM handle_download_error USING sy-subrc l_filenamenum ''.
        ENDIF.
      ELSE. "HBHALLA (22/04/25) (PN-12517)
        CALL FUNCTION 'GUI_DOWNLOAD'             "#EC SAST_CI_GEN_CHECK
          EXPORTING
            filename                = l_filenamenum
            filetype                = l_type
            write_field_separator   = 'X' "HBHALLA
            dat_mode                = ' '
            col_select            = 'X'
            col_select_mask       = gv_mask
          TABLES
            data_tab                = gt_output_alv
*       fieldnames               = lt_header "HBHALLA
           fieldnames               = gt_excel_header "HBHALLA
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
          PERFORM handle_download_error USING sy-subrc l_filenamenum ''.
        ENDIF.
      ENDIF. "HBHALLA (22/04/25) (PN-12517)
    ENDIF.
*EOC:HBHALLA (096)
  ENDIF.
  FREE : gt_output_alv.
ENDFORM.                    " export_to_file
*&---------------------------------------------------------------------*
*&      Form  add_nr_to_filename
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_NUM  text
*      <--P_L_FILENAME  text
*----------------------------------------------------------------------*
FORM add_nr_to_filename USING    i_num
                        CHANGING e_filename.
  DATA : lt_parts TYPE TABLE OF string WITH HEADER LINE,
         l_parts  TYPE i,
         l_ext    TYPE string,
         l_new    TYPE string.
  CONDENSE i_num.
  SPLIT e_filename AT '.' INTO TABLE lt_parts.
  DESCRIBE TABLE lt_parts LINES l_parts.

  LOOP AT lt_parts.
    IF sy-tabix < l_parts.
      IF l_new IS INITIAL.
        CONCATENATE l_new lt_parts  INTO l_new.
      ELSE.
        CONCATENATE l_new '.' lt_parts  INTO l_new.
      ENDIF.
    ELSE.
      l_ext = lt_parts.
    ENDIF.
  ENDLOOP.
  CONCATENATE l_new '-' i_num '.' l_ext INTO e_filename.
ENDFORM.                    " add_nr_to_filename
*&---------------------------------------------------------------------*
*&      Module  STATUS_0103  OUTPUT
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - PBO module: Choose Export Options screen
*----------------------------------------------------------------------*
MODULE status_0103 OUTPUT.
  IF sy-ucomm EQ 'EXP_SR' OR sy-ucomm EQ 'CANCEL'.
    LEAVE TO SCREEN 0.
  ELSE.
    SET PF-STATUS '0103'.
    SET TITLEBAR '0103'.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0103  INPUT
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - PAI module: Choose Export Options screen
*----------------------------------------------------------------------*
MODULE user_command_0103 INPUT.

  DATA : ask_export TYPE flag.

  CASE sy-ucomm.

    WHEN 'OK'.

      IF gr_exp_alv = 'X'.

        ask_export = 'X'.
        PERFORM export_data_to_alv USING ask_export.
        LEAVE TO SCREEN 0.

      ELSEIF gr_exp_file = 'X'.
        ask_export = ' '.
        PERFORM export_data_to_alv USING ask_export.
        LEAVE TO SCREEN 0.
      ELSE.

        IF g_node_key = 'R_DATA'.

          CALL SCREEN '0104' STARTING AT 10 1.

        ELSE.

MESSAGE s002(/psyng/sw) WITH 'Please select only root node to export full data '(i34)
'to the server'(i35).
          LEAVE TO SCREEN 0.

        ENDIF.


      ENDIF.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  GET_SELECTED_NODE
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - Get the user selected node
*----------------------------------------------------------------------*
*      -->P_G_NODE_KEY  text
*----------------------------------------------------------------------*
FORM get_selected_node CHANGING g_node_key TYPE tv_nodekey.

  CLEAR g_node_key.

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

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXCEL_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_EXCEL_HEADER  text
*----------------------------------------------------------------------*
FORM excel_header CHANGING gt_excel_header TYPE tt_excel_header.

  DATA : ls_excel_header TYPE ty_excel_header.


  ls_excel_header-col_name = 'Role ID'(c02).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Conflict'(c03).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Conflicts'(t09).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Mitigated Conflicts'(t10).
  APPEND ls_excel_header TO gt_excel_header.
*
*  ls_excel_header-col_name = 'Conflict'(c03).
*  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Mitigated'(t08).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Function'(c04).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Child Role'(c05).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'System'(c07).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Tcode'(c08).
  APPEND ls_excel_header TO gt_excel_header.

*BOC:HBHALLA (PN-12517) (22/04/25)
*  ls_excel_header-col_name = 'Abbr.'(c14).
*  APPEND ls_excel_header TO gt_excel_header.
*EOC:HBHALLA (PN-12517) (22/04/25)

  ls_excel_header-col_name = 'Authorization'(c09).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Object'(c10).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Field'(c11).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Value From'(c12).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Value To'(c13).
  APPEND ls_excel_header TO gt_excel_header.

*BOC:HBHALLA (PN-12517) (22/04/25)
  ls_excel_header-col_name = 'Abbr.'(c14).
  APPEND ls_excel_header TO gt_excel_header.
*EOC:HBHALLA (PN-12517) (22/04/25)

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0104  OUTPUT
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - PBO module: Export data to server screen
*----------------------------------------------------------------------*
MODULE status_0104 OUTPUT.

  SET PF-STATUS '0104'.
  SET TITLEBAR '0104'.

  DATA : l_max_alv_s TYPE string,
         l_max_alv   TYPE i.
* Get the value of recorss limit for batch size from the Config parameter.
  se_config_param 'SOD_EXPORT_ALV_LIMIT' l_max_alv_s.
  IF l_max_alv_s CO '0123456789'.
*   Code Changes for B17121 by GSINGH - Hnadling Short Dump due to large number value in Config Parameter
    IF l_max_alv_s > '1000000'.
MESSAGE 'Parameter SOD_EXPORT_ALV_LIMIT current value cannot be greater than default value'(e11) TYPE 'E'.
    ELSE.
      l_max_alv = l_max_alv_s.
    ENDIF.
*   End of changes for B17121
  ELSE.
    l_max_alv = 1000000.
  ENDIF.

  IF gf_server_path IS INITIAL.
    gf_server_path = '\\192.168.205.11\Pathlock\SE\'.
  ENDIF.
  IF gf_roles_count IS INITIAL.
    gf_roles_count = l_max_alv.
  ENDIF.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0104  INPUT
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - PAI module: Export data to server screen
*----------------------------------------------------------------------*
MODULE user_command_0104 INPUT.

  DATA: lv_srv_path(128) TYPE c.

  CASE sy-ucomm.

    WHEN 'EXP_SR'.

      CLEAR lv_srv_path.
      lv_srv_path = gf_server_path.
      CALL FUNCTION 'PFL_CHECK_DIRECTORY'
        EXPORTING
          directory_long              = lv_srv_path
        EXCEPTIONS
          pfl_dir_not_exist           = 1
          pfl_permission_denied       = 2
          pfl_cant_build_dataset_name = 3
          pfl_file_not_exist          = 4
          pfl_authorization_missing   = 5
          OTHERS                      = 6.
      IF sy-subrc = 0.
        PERFORM export_data_to_server.
        LEAVE TO SCREEN 0.
      ELSEIF sy-subrc = 1.
MESSAGE 'Application Server path does not exist. Kindly enter valid server path.' TYPE 'I'.
      ENDIF.

    WHEN 'CANCEL'.

      LEAVE TO SCREEN 0.

    WHEN OTHERS.
  ENDCASE.

ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA_TO_SERVER
*&---------------------------------------------------------------------*
* C0765 by AKUMAR - Logic: Export data to Server
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM export_data_to_server .

  DATA : lv_jobcount     TYPE btcjobcnt,
         lv_job_released TYPE flag,
         lf_job_open     TYPE flag,
         lf_job_closed   TYPE flag.
*BOC by GSINGH on 03.02.2023*
*Changing the jobname for consistency between User and Roles Export job
*CONSTANTS lc_jobname TYPE btcjob VALUE 'SOD Role Results Export(Server)'.
CONSTANTS lc_jobname TYPE btcjob VALUE 'STORED SOD ROLE RESULTS TO SRVR'.
* EOC by GSINGH
  PERFORM job_open USING lc_jobname CHANGING lv_jobcount lf_job_open.
  IF lf_job_open IS INITIAL.
* Implement suitable error handling here
  ELSE.
    "submit program
    SUBMIT /psyng/sw_159
      VIA JOB lc_jobname
      NUMBER lv_jobcount
    WITH p_all = p_all
    WITH p_rswc = p_rswc
    WITH p_aid  = p_aid
    WITH p_comp = p_comp
    WITH p_sing = p_sing
    WITH p_assr = p_assr
    WITH p_mitcon = p_mitcon
    WITH p_fun = p_fun
    WITH p_orgvar = 'X'
    WITH p_rswoc = p_rswoc
    WITH s_role IN s_role
    WITH rba IN rba
    WITH s_conid IN s_conid
    WITH s_rnum IN s_rnum
    WITH s_rmnum IN s_rmnum
    WITH p_spath = gf_server_path
    WITH p_rcount = gf_roles_count
    AND RETURN.

PERFORM job_closed USING lv_jobcount lc_jobname CHANGING lv_job_released lf_job_closed.
    IF lf_job_closed IS INITIAL.
* Implement suitable error handling here
    ELSE.
MESSAGE i002(/psyng/sw) WITH 'Job '(i36) lc_jobname 'released for exporting data to server'(i37).
    ENDIF.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  JOB_OPEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LC_JOBNAME  text
*      <--P_LV_JOBCOUNT  text
*      <--P_LF_JOB_OPEN  text
*----------------------------------------------------------------------*
FORM job_open  USING    lc_jobname TYPE btcjob
               CHANGING lv_jobcount TYPE btcjobcnt
                        lf_job_open TYPE flag.

  CALL FUNCTION 'JOB_OPEN'
    EXPORTING
      jobname          = lc_jobname
    IMPORTING
      jobcount         = lv_jobcount
    EXCEPTIONS
      cant_create_job  = 1
      invalid_job_data = 2
      jobname_missing  = 3
      OTHERS           = 4.
  IF sy-subrc = 0.
    lf_job_open = 'X'.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  JOB_CLOSED
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LV_JOBCOUNT  text
*      -->P_LC_JOBNAME  text
*      <--P_LV_JOB_RELEASED  text
*      <--P_LF_JOB_CLOSED  text
*----------------------------------------------------------------------*
FORM job_closed  USING    lv_jobcount TYPE btcjobcnt
                          lc_jobname TYPE btcjob
                 CHANGING lv_job_released TYPE flag
                          lf_job_closed TYPE flag.

  CALL FUNCTION 'JOB_CLOSE'
    EXPORTING
      jobcount             = lv_jobcount
      jobname              = lc_jobname
      strtimmed            = 'X'
    IMPORTING
      job_was_released     = lv_job_released
    EXCEPTIONS
      cant_start_immediate = 1
      invalid_startdate    = 2
      jobname_missing      = 3
      job_close_failed     = 4
      job_nosteps          = 5
      job_notex            = 6
      lock_failed          = 7
      invalid_target       = 8
      OTHERS               = 9.
  IF sy-subrc = 0.
    lf_job_closed = 'X'.
  ENDIF.

ENDFORM.

FORM set_mask  USING   VALUE(pos) TYPE i
               CHANGING gv_mask TYPE char255.

  DATA: lv_str_len TYPE i,
        lv_str2_len TYPE i,
        str1 TYPE string,
        str2 TYPE string,
        str3 TYPE string,
        str4 TYPE string,
        lf_space TYPE flag,
        tmp_mask TYPE string.

  tmp_mask = gv_mask.
  CLEAR gv_mask.
  lv_str_len = strlen( tmp_mask ).
  SUBTRACT 1 FROM pos.
  IF pos = 0.
    CLEAR str1.
  ELSE.
    str1 = tmp_mask+0(pos).
    IF strlen( str1 ) <> pos.
      CONCATENATE str1 space INTO str1 RESPECTING BLANKS.
    ENDIF.
  ENDIF.
  lv_str_len = lv_str_len - pos.
  str2 = tmp_mask+pos(lv_str_len).
  lv_str2_len = strlen( str2 ).
  SUBTRACT 1 FROM lv_str2_len.
  str3 = str2+1(lv_str2_len).
  CONCATENATE space str3 INTO str4 RESPECTING BLANKS.
  CLEAR tmp_mask.
  CONCATENATE str1 str4 INTO tmp_mask RESPECTING BLANKS.
  gv_mask = tmp_mask.
  CLEAR: str1, str2, str3, str4, lf_space.

ENDFORM.
