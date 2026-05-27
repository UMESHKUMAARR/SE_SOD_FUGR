*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_137
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  21/04/2020   Gurpinder   C0014       D67K902682                     *
*----------------------------------------------------------------------*
REPORT /psyng/sw_137 MESSAGE-ID /psyng/sw .
INCLUDE : /psyng/basis_exelog.
DATA ls_node.
TABLES: usr02.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME'.
CONSTANTS: gc_active_state        TYPE r3state VALUE 'A',
           gc_import_param        TYPE rs38l_kind VALUE 'I',
           gc_export_param        TYPE rs38l_kind VALUE 'E',
           gc_company_address_str TYPE rs38l_typ VALUE 'USCOMP'.
TYPES: BEGIN OF ty_swrescon,
         userindex TYPE /psyng/seres_userindex,
         conindex  TYPE /psyng/seres_conindex,
       END OF ty_swrescon.
TYPES : ttree_item   LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY,
        tsodorgm     LIKE STANDARD TABLE OF /psyng/swsodorgm
        WITH DEFAULT KEY INITIAL SIZE 0   ,
        ttyp_comprol TYPE SORTED TABLE OF /psyng/swresucom
                       WITH NON-UNIQUE KEY roleindex,
        ttyp_profile TYPE SORTED TABLE OF /psyng/swresprol
                             WITH UNIQUE KEY profindex,
        ttyp_roles   TYPE SORTED TABLE OF /psyng/swresirol
                       WITH UNIQUE KEY roleindex.
*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
TYPES : tt_usercon TYPE TABLE OF /psyng/swrescon ,
        tt_confun  TYPE TABLE OF /psyng/swrescfun.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
DATA : go_tree       TYPE REF TO cl_gui_column_tree,
       go_cust_cont  TYPE REF TO cl_gui_custom_container,
       go_html       TYPE REF TO cl_gui_html_viewer,
       go_html_cont  TYPE REF TO cl_gui_custom_container,
       gt_node       TYPE treev_ntab,
       gt_item       TYPE ttree_item,
       gt_conflict   TYPE TABLE OF /psyng/swresicon WITH HEADER LINE,
       gt_user       TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
       gt_system     TYPE SORTED TABLE OF /psyng/swresisys
                    WITH HEADER LINE
                    WITH UNIQUE KEY sysindex,
       gt_sysinfo    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
       gt_varel      TYPE TABLE OF /psyng/faobj2
                    WITH HEADER LINE,
       g_usercon_id  TYPE i,
       g_confun_id   TYPE i,
       g_auth_id     TYPE i,
       g_bname_id    TYPE i,
       g_aid_exist   TYPE flag,
       g_dynnr       TYPE sy-dynnr,
       g_node_key    TYPE tv_nodekey,
       g_aid         TYPE /psyng/swreshdr-aid,
       g_summary_del TYPE flag,
       BEGIN OF gt_sodorgm OCCURS 0,
         sysid   TYPE /psyng/sysid,
         sodorgm TYPE tsodorgm,
       END OF gt_sodorgm,
       gs_hdr               TYPE /psyng/swreshdr,
       gf_node_has_children TYPE flag.
*---toolbar expand/find options data declare
DATA: gr_exp_bname         TYPE flag,
      gr_exp_conid         TYPE flag,
      gr_exp_funid         TYPE flag,
*     BOC by GSINGH for C0765
      gr_exp_old           TYPE flag,
      gr_exp_file          TYPE flag,
      gr_exp_server        TYPE flag,
      gf_server_path(200),       "TYPE filename-fileintern,
      gf_users_count       TYPE i,
      gv_out_users         TYPE i,
*     EOC by GSINGH for C0765
      gf_exp_bname         TYPE /psyng/swreshdr-bname,
      gf_exp_conid         TYPE /psyng/conflict-conid,
      gf_exp_funid         TYPE /psyng/function-function,
      gr_fnd_bname         TYPE flag,
      gr_fnd_conid         TYPE flag,
      gr_fnd_funid         TYPE flag,
      gf_fnd_bname         TYPE /psyng/swreshdr-bname,
      gf_fnd_conid         TYPE /psyng/conflict-conid,
      gf_fnd_funid         TYPE /psyng/function-function,

*      C0526
      gf_sort_bname        TYPE char40,
      gr_sort_bname        TYPE flag,
      gf_sort_conf         TYPE char40,
      gr_sort_conf         TYPE flag,
      g_sort_clicked       TYPE flag,

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
*        aid      TYPE /psyng/swreshdr-aid,
        bname     TYPE /psyng/swreshdr-bname,
        conid     TYPE /psyng/conflict-conid,
        confnum   TYPE /psyng/nr_conflicts,
        mitinum   TYPE /psyng/nr_conflicts,
        mitigated TYPE flag,
        funid     TYPE /psyng/faobj2-funid,
        comp_agr  TYPE agr_define-agr_name,
        agr_name  TYPE agr_define-agr_name,
        profname  TYPE agr_prof-profile,
        sysid     TYPE /psyng/sw_rfcdes-systid,
        tcode     TYPE /psyng/faobj2-tcode,
        auth      TYPE /psyng/seres_authdetail-auth,
        object    TYPE /psyng/faobj2-object,
        field     TYPE /psyng/faobj2-field,
        von       TYPE /psyng/seres_authdetail-von,
        bis       TYPE /psyng/seres_authdetail-bis,
        abb       TYPE /psyng/seres_authdetail-abb,
        origin    TYPE c LENGTH 12, "B16609 for C0633
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
        class     TYPE xuclass,
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
        deprtmnt  TYPE /PSYNG/SWRESUSR-department,
                                           "HBHALLA(PN-15675)(08/10/25)
      END OF gt_output_alv,
      g_alv_count    LIKE sy-tabix,
      g_current_user TYPE sy-uname. "C0700

*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
TYPES: BEGIN OF lt_output_alv,
        bname     TYPE /psyng/swreshdr-bname,
        conid     TYPE /psyng/conflict-conid,
        confnum   TYPE /psyng/nr_conflicts,
        mitinum   TYPE /psyng/nr_conflicts,
        mitigated TYPE flag,
        funid     TYPE /psyng/faobj2-funid,
        comp_agr  TYPE agr_define-agr_name,
        agr_name  TYPE agr_define-agr_name,
        profname  TYPE agr_prof-profile,
        sysid     TYPE /psyng/sw_rfcdes-systid,
        tcode     TYPE /psyng/faobj2-tcode,
        auth      TYPE /psyng/seres_authdetail-auth,
        object    TYPE /psyng/faobj2-object,
        field     TYPE /psyng/faobj2-field,
        von       TYPE /psyng/seres_authdetail-von,
        bis       TYPE /psyng/seres_authdetail-bis,
        abb       TYPE /psyng/seres_authdetail-abb,
        origin    TYPE c LENGTH 12,
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
        class     TYPE xuclass,
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
        deprtmnt  TYPE /PSYNG/SWRESUSR-department,
                                           "HBHALLA(PN-15675)(08/10/25)
      END OF lt_output_alv.
DATA: ls_output_alv TYPE lt_output_alv.
DATA: lv_comp_agr  TYPE agr_define-agr_name.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
*--OPL518 START
TYPES : BEGIN OF ty_excel_header,
          col_name TYPE c LENGTH 30,
        END OF ty_excel_header,

        tt_excel_header TYPE TABLE OF ty_excel_header.
DATA: gt_excel_header     TYPE TABLE OF ty_excel_header.
*--OPL518 END
INCLUDE /psyng/sw_137_classes.
INCLUDE /psyng/sw_137_macros.
INCLUDE /psyng/sw_config.
TABLES : /psyng/conflict,/psyng/swreshdr,/psyng/swresusr .
DATA : go_application TYPE REF TO lcl_application.

RANGES : r_bname FOR usr02-bname,
         gr_conflicts FOR gt_conflict-conindex.


SELECTION-SCREEN: BEGIN OF BLOCK res WITH FRAME.
PARAMETERS : p_aid TYPE /psyng/swreshdr-aid OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK res.
SELECTION-SCREEN: BEGIN OF BLOCK usr WITH FRAME.
SELECT-OPTIONS :
             s_bname FOR usr02-bname,
             s_kostl FOR /psyng/swresusr-kostl
                         MATCHCODE OBJECT /psyng/kostl,
             s_class FOR usr02-class,
             s_comp  FOR /psyng/swresusr-company,
             s_dep   FOR /psyng/swresusr-department.
*-- User type & valid user screen
PARAMETERS: validusr AS CHECKBOX DEFAULT ' '  MODIF ID usr
 USER-COMMAND usr_fil.
SELECT-OPTIONS : usrtype FOR /psyng/swresusr-ustyp MODIF ID usr.

*BOC:HBHALLA (PN-6926)(23/04/25)
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
SELECTION-SCREEN COMMENT 1(79) text-100 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: exlckusr AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-102 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: outvdate AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-101 MODIF ID usr.
SELECTION-SCREEN END OF LINE.
*EOC:HBHALLA (PN-6926)(23/04/25)

SELECTION-SCREEN: END OF BLOCK usr.
SELECTION-SCREEN: BEGIN OF BLOCK con WITH FRAME.
SELECT-OPTIONS :
             s_conid FOR /psyng/conflict-conid.
PARAMETERS p_mitcon TYPE flag AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK con.
* BOC by RGUPTA on 16.03.22 for C0633
SELECTION-SCREEN: BEGIN OF BLOCK gp4 WITH FRAME TITLE text-g04.
*  --Conflict origin
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-170    MODIF ID rem.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X' MODIF ID rem.
SELECTION-SCREEN COMMENT 24(10) text-173 FOR FIELD p_local
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag DEFAULT 'X'
                                           MODIF ID rem.
SELECTION-SCREEN COMMENT 37(10) text-174 FOR FIELD p_remote
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag DEFAULT 'X' MODIF ID rem.
SELECTION-SCREEN COMMENT 51(20) text-175 FOR FIELD p_cross
                                           MODIF ID rem.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK gp4.
* EOC by RGUPTA on 16.03.22 for C0633
SELECTION-SCREEN: BEGIN OF BLOCK gp WITH FRAME TITLE text-g01.
PARAMETERS :
  p_gclass TYPE flag RADIOBUTTON GROUP g1,
  p_gkostl TYPE flag RADIOBUTTON GROUP g1,
  p_gcomp  TYPE flag RADIOBUTTON GROUP g1,
  p_gdep   TYPE flag RADIOBUTTON GROUP g1,
  p_nogrp  TYPE flag RADIOBUTTON GROUP g1.
SELECTION-SCREEN: END OF BLOCK gp.

SELECTION-SCREEN: BEGIN OF BLOCK gp1 WITH FRAME TITLE text-g02.
PARAMETERS :
  p_fun    TYPE flag RADIOBUTTON GROUP g2,
  p_rolpro TYPE flag RADIOBUTTON GROUP g2,
  p_orgvar TYPE flag RADIOBUTTON GROUP g2.
SELECTION-SCREEN: END OF BLOCK gp1.

SELECTION-SCREEN: BEGIN OF BLOCK gp2 WITH FRAME TITLE text-g03.
PARAMETERS : p_all   TYPE flag RADIOBUTTON GROUP g3 DEFAULT 'X'
USER-COMMAND u01, "all
p_uswc  TYPE flag RADIOBUTTON GROUP g3,     "with conflict
p_uswoc TYPE flag RADIOBUTTON GROUP g3 .   "w/o conflict
SELECT-OPTIONS: s_unum FOR /psyng/swresusr-nr_conflicts MODIF ID us1,
                s_umnum FOR /psyng/swresusr-nr_mitigated MODIF ID us1.

PARAMETERS: p_flag TYPE c NO-DISPLAY. "HBHALLA (PN-13137 Issue 6)

SELECTION-SCREEN: END OF BLOCK gp2.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_aid.
  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
    EXPORTING
      tabname     = '/PSYNG/SWRESHDR'
      fieldname   = 'AID'
      searchhelp  = '/PSYNG/SERESID'
      dynpprog    = sy-cprog
      dynpnr      = '1000'
      dynprofield = 'P_AID'
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             field_not_found   = 1
             no_help_for_field = 2
             inconsistent_help = 3
             no_values_found   = 4
             OTHERS          = 5 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-low.
  PERFORM f4_company USING 'S_COMP-LOW' CHANGING s_comp-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-high.
  PERFORM f4_company USING 'S_COMP-HIGH' CHANGING s_comp-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_dep-low.
  PERFORM f4_department USING 'S_DEP-LOW' CHANGING s_dep-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_dep-high.
  PERFORM f4_department USING 'S_DEP-HIGH' CHANGING s_dep-high.

AT SELECTION-SCREEN OUTPUT.
  IF p_uswoc EQ 'X'.
    LOOP AT SCREEN.
      IF screen-group1 EQ 'US1'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
  LOOP AT SCREEN.

*BOC:HBHALLA (PN-6926)(23/04/25)
**    CASE screen-name.
**      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH'.
**        IF validusr = 'X'.
**          PERFORM set_def_usrtype.
**          screen-input = 0.
**        ELSE.
**          PERFORM get_config_usr.
**          screen-input    = 1.
**        ENDIF.
**        MODIFY SCREEN.

    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
*          CLEAR exlckusr.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag. "HBHALLA (PN-13137 ISSUE 6) (14/05/25)
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
*EOC:HBHALLA (PN-6926)(23/04/25)

    ENDCASE.
  ENDLOOP.

INITIALIZATION.
* BOC by RGUPTA on 28.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
    EXPORTING
      i_repid = '/PSYNG/SW_137'.

  DATA: swconfig TYPE /psyng/swconfig.
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.

  IF swconfig-value = 'Y'.
    validusr = 'X'.
    exlckusr = 'X'. "HBHALLA (PN-13137 ISSUE5) (14/05/25)
    outvdate = 'X'. "HBHALLA (PN-13137 ISSUE5) (14/05/25)
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
  ENDIF.

*BOC:HBHALLA (PN-13137 ISSUE5) (14/05/25)
  IF validusr IS INITIAL.
*  -- Default locked users
    CLEAR swconfig.
    se_config_param 'DFLT_EXCLUDE_LOCKED' swconfig-value.

    IF swconfig-value = 'Y'.
      exlckusr = 'X'.
    ELSEIF swconfig-value = 'N'.
      exlckusr = ' '.
    ENDIF.

*  -- Default expired users
    CLEAR swconfig.
    se_config_param 'DFLT_EXCL_OUT_VALID' swconfig-value.
    IF swconfig-value = 'Y'.
      outvdate = 'X'.
    ELSEIF swconfig-value = 'N'.
      outvdate = ' '.
    ENDIF.
  ENDIF.
*EOC:HBHALLA (PN-13137 ISSUE5) (14/05/25)

** BOC by RGUPTA on 25.03.22
*AT SELECTION-SCREEN.
*
*  IF p_local IS INITIAL
*    OR p_remote IS INITIAL
*    OR p_cross IS INITIAL.
*    MESSAGE w002 WITH 'Conflict origin filter not supported'(027)
*    'for SOD analysis executed in'(028)
*    'Separations Enforcer versions before 4.6'(029).
*  ENDIF.
** EOC by RGUPTA on 25.03.22
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
      i_aid      = p_aid
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
* Define the events which will be passed to the backend
  ls_event-eventid    = cl_gui_column_tree=>eventid_expand_no_children.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.
  ls_event-eventid    = cl_gui_column_tree=>eventid_link_click.
  ls_event-appl_event = 'X'.
  APPEND ls_event TO lt_events.
*   ls_event-eventid    = cl_gui_column_tree=>ITEM_SELECTION.
*   ls_event-appl_event = 'X'.
*   APPEND ls_event TO lt_events.


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
      header_text                  = 'Header Data'(030)
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
*BOC:HBHALLA (PN-15675) (08/10/25)
  tree_col 'DEPRTMNT' 13 'Department'(t11).
*EOC:HBHALLA (PN-15675) (08/10/25)
  tree_col 'CONFNUM' 13 'Conflicts'(t09).
  IF p_mitcon EQ 'X'.
    tree_col: 'MITINUM' 23 'Mitigated Conflicts'(t10),
              'MITIGATED' 13 'Mitigated'(t08).
  ENDIF.
*--Add data columns
  tree_col :
*    'AGR_NAME' 35 'Role'(c01),
*    'COMP_AGR' 35 'Composite Role'(c08),
    'PROFILE'  18 'Profile'(t02),
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
                    'USERINDEX',
                    'CONINDEX',
                    'FUNINDEX',
                    'GROUPNAME',
                    'PROFINDEX',
                    'SYSINDEX'.
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
         l_systemid       TYPE /psyng/sysid, "C1102 AKUMAR
         lv_con TYPE /psyng/nr_conflicts,
         lv_con_abb TYPE /psyng/nr_conflicts,
         lv_usrcon_count TYPE i,
         lv_dummy TYPE /psyng/swresuabb-aid.
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
*  CALL METHOD lo_doc->initialize_document.
*  CALL METHOD lo_doc->add_text EXPORTING text  = 'Test'
*                                  sap_style = 'HEADING'.

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

*HBHALLA: (03/11/23) BEGIN OF BOC
  DATA: l_origin(50) TYPE c,
        l_local(10)  TYPE c,
        l_remote(10) TYPE c,
        l_cross(10)  TYPE c.


  l_local = 'Local'(h50)."text-h50.
  l_remote = 'Remote'(h51).
  l_cross = 'Cross'(h52).


*IF p_local = 'X'.
*  CONCATENATE l_origin l_local INTO l_origin SEPARATED BY space.
*ENDIF.
*
*
*IF p_remote = 'X'.
*  CONCATENATE l_origin l_remote INTO l_origin SEPARATED BY space.
*ENDIF.
*
*IF p_cross = 'X'.
*  CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY space.
*ENDIF.
*HBHALLA:(04/12/23) BEGIN OF BOC.
  IF p_local = 'X'.
    CONCATENATE l_origin l_local INTO l_origin.
    IF p_local = 'X' AND p_remote = 'X'.
      CONCATENATE l_origin l_remote INTO l_origin SEPARATED BY ' & '.
      IF p_local = 'X' AND p_remote = 'X' AND p_cross = 'X'.
        CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
      ENDIF.
    ELSEIF p_local = 'X' AND p_cross = 'X'.
      CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
    ENDIF.

  ELSEIF p_remote = 'X'.
    CONCATENATE l_origin l_remote INTO l_origin.
    IF p_remote = 'X' AND p_cross = 'X'.
      CONCATENATE l_origin l_cross INTO l_origin SEPARATED BY ' & '.
    ENDIF.

  ELSEIF p_cross = 'X'.
    CONCATENATE l_origin l_cross INTO l_origin.
  ENDIF.
*END OF CHANGE.
*END OF CHANGE.

*BOC AKUMAR 18.08.2025
  CLEAR lv_dummy.
  SELECT SINGLE aid
         INTO lv_dummy
         FROM /psyng/swresuabb
         WHERE aid = p_aid.

  IF sy-subrc = 0. "org check 'X'.

    lv_con_abb = gs_hdr-conflicts.

    CLEAR lv_usrcon_count.
    SELECT COUNT(*)
      INTO lv_usrcon_count
      FROM /psyng/swrescon
      WHERE aid = p_aid.

    IF sy-subrc = 0 AND lv_usrcon_count > 0.
      lv_con = lv_usrcon_count.
    ELSE.
      CLEAR lv_con.
    ENDIF.

  ELSE.

    CLEAR lv_con_abb.
    lv_con = gs_hdr-conflicts.

  ENDIF.
*EOC AKUMAR 18.08.2025

  add_header_line :
    'Result ID:'            l_res_txt
    'User Date & System:'          l_userdate,

    'SOD Version:'          l_vrsio_txt
    'Users Analyzed:'       gs_hdr-users_analyzed,

    'Configuration Set:'    l_set_txt
    'Conflicts:'            lv_con, "AKUMAR

    'Config Set Published:' l_set_pub
    'Conflict Origin:'      l_origin, "HBHALLA

    'Config Set Changed:'   l_set_chg
    'Total Conflicts(abbreviations)'   lv_con_abb. "AKUMAR

*  WRITE ls_hdr-start_date TO l_date.
*  r_bname-sign = 'I'.
*  r_bname-option = 'EQ'.
*  r_bname-low = ls_hdr-bname.
*  COLLECT r_bname.
*  CALL FUNCTION '/PSYNG/BC_011'
*       TABLES
*            it_bname = r_bname
*            et_uidn  = lt_uidn.
*  READ TABLE lt_uidn INDEX 1.
*  CONCATENATE  'Analysis' p_aid 'Executed on' l_date
*               'by' ls_hdr-bname '(' lt_uidn-name_text ')'
*               INTO g_header1 SEPARATED BY space.
*  CLEAR l_date.
*  l_con_count = ls_hdr-users_analyzed.
*  CONDENSE l_con_count.
*  CONCATENATE l_con_count 'Users Analysed' INTO g_header2
*              SEPARATED BY space.
*  CLEAR l_con_count.
*  l_con_count = ls_hdr-conflicts.
*  l_date = ls_hdr-conflicted_users.
*  CONDENSE: l_con_count,l_date.
*  CONCATENATE l_con_count 'Conflicts in' l_date 'Users'
*              INTO g_header3 SEPARATED BY space.
*  CLEAR: l_date, l_con_count.
*
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
         l_bname_id        TYPE i,
         l_node_id         TYPE string,
         ls_hdr            TYPE /psyng/swreshdr,
         l_desc            TYPE string,
         l_head            TYPE string,
         l_icon            TYPE icon_d,
         lt_users          TYPE TABLE OF /psyng/swresusr
                           WITH HEADER LINE,
         l_group_id        TYPE i,
         l_groupnode_type  TYPE string,
         l_groupnode_value TYPE string,
         l_groupnode_text  TYPE /psyng/longtext,
         ls_groupgrptext   TYPE usgrpt-text,
         l_fname           TYPE tfdir-funcname,
         l_aid             TYPE char10,
         l_con_count(10)   TYPE c,

         lt_sodorgm        TYPE TABLE OF /psyng/swsodorgm
                           WITH HEADER LINE,
         l_num_actual_con  TYPE /psyng/nr_conflicts,
         l_numcon_part     TYPE i.

  RANGES :
    lr_users      FOR gt_user-userindex,
    lr_users_part FOR gt_user-userindex,
    lr_users_all  FOR gt_user-userindex,
    r_bname       FOR usr02-bname,
    lr_usertype   FOR /psyng/swresusr-ustyp.

*BOC:HBHALLA (PN-6926) (24/04/25)
  DATA: i_include_locked     TYPE flag,
        i_include_expire     TYPE flag,
        lt_rem_users         TYPE TABLE OF usr02,
        lt_lcl_users         TYPE TABLE OF usr02,
        et_users             TYPE TABLE OF usr02,
        ls_usr02             TYPE usr02,
        lt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
                  WITH HEADER LINE,
        lt_stored_users TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
        ls_user_range TYPE /psyng/sw_sel_opts_xubname,
        lt_bname TYPE TABLE OF /psyng/sw_sel_opts_xubname,
        l_system TYPE rfcdest,
        l_tabix  TYPE sy-tabix."HBHALLA (05/08/25)

*EOC:HBHALLA (PN-6926) (24/04/25)

*---users type
* IF validusr IS INITIAL.
  lr_usertype[] = usrtype[].
*  ELSE.
*    lr_usertype-sign = 'I'.
*    lr_usertype-option = 'EQ'.
*    lr_usertype-low = 'A'.
*    APPEND lr_usertype.
*  ENDIF.

  lr_users-sign     = 'I'. lr_users-option     = 'EQ'.
  gr_conflicts-sign = 'I'. gr_conflicts-option = 'EQ'.

*--Systems
  SELECT * FROM /psyng/swresisys INTO TABLE gt_system
    WHERE aid  = p_aid.
  IF NOT gt_system[] IS INITIAL.
    SELECT * FROM /psyng/sw_rfcdes INTO TABLE gt_sysinfo
    FOR ALL ENTRIES IN
      gt_system WHERE systid = gt_system-sysid.
  ENDIF.
*--users

*BOC:HBHALLA (PN-6926) (24/04/25)

  IF validusr IS INITIAL.
    IF exlckusr = 'X'.
      CLEAR i_include_locked.
    ELSE.
      i_include_locked = 'X'.
    ENDIF.

    IF outvdate = 'X'.
      CLEAR i_include_expire.
    ELSE.
      i_include_expire = 'X'.
    ENDIF.
  ENDIF.

  CONCATENATE sy-sysid sy-mandt INTO l_system.

  APPEND LINES OF s_bname TO lt_bname.

  LOOP AT gt_sysinfo.
    IF gt_sysinfo-systid <> l_system.
*BOC:HBHALLA (29/11/24) PN-7118 - SE VF Scan changes
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
*EOC:HBHALLA (29/11/24) PN-7118 - SE VF Scan changes
      CALL FUNCTION '/PSYNG/SW_041'
        DESTINATION gt_sysinfo-rfcdest
        EXPORTING
          i_validuser       = validusr
          i_include_locked  = i_include_locked
          i_include_expired = i_include_expire
        TABLES
          et_users          = lt_rem_users
          it_userlist       = lt_bname
          it_grouplist      = s_class
          it_usertype       = lr_usertype
*            it_actgroups      = s_actgroups
*            it_profile        = s_profile
          it_costcenter     = s_kostl
        EXCEPTIONS
             communication_failure = 1
             system_failure        = 2
             OTHERS                = 3.          "#EC SAST_CI_GEN_CHECK
* <-- PN-7118 - SE VF Scan changes - HBHALLA - 2024-11-29
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before code compiler
*   is not picking it up
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
          WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
          WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
        ENDCASE.
      ENDIF.
      LOOP AT lt_rem_users INTO ls_usr02.
        APPEND ls_usr02 TO et_users.
        CLEAR ls_usr02.
      ENDLOOP.
    ELSE.
      CALL FUNCTION '/PSYNG/SW_041'
        EXPORTING
          i_validuser       = validusr
          i_include_locked  = i_include_locked
          i_include_expired = i_include_expire
        TABLES
          et_users          = lt_lcl_users
              it_userlist       = lt_bname
              it_grouplist      = s_class
              it_usertype       = lr_usertype
*            it_actgroups      = s_actgroups
*            it_profile        = s_profile
              it_costcenter     = s_kostl.
      LOOP AT lt_lcl_users INTO ls_usr02.
        APPEND ls_usr02 TO et_users.
        CLEAR ls_usr02.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  FREE: lt_rem_users, lt_lcl_users.

  SORT et_users.
  DELETE ADJACENT DUPLICATES FROM et_users COMPARING ALL FIELDS.

*EOC:HBHALLA (PN-6926) (24/04/25)

  IF p_all = 'X'.
    SELECT * FROM /psyng/swresusr INTO TABLE gt_user
      WHERE    aid         = p_aid AND
               bname       IN s_bname AND
               class       IN s_class AND
               kostl       IN s_kostl AND
               company     IN s_comp AND
               department  IN s_dep AND
               nr_conflicts IN s_unum AND
               nr_mitigated IN s_umnum AND
               ustyp        IN lr_usertype.

*BOC:HBHALLA (PN-14607) (05/08/25)
    LOOP AT gt_user.
      l_tabix = sy-tabix.
      READ TABLE et_users WITH KEY bname = gt_user-bname BINARY SEARCH
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_user[] INDEX l_tabix.
      ENDIF.
    ENDLOOP.
*EOC:HBHALLA (PN-14607) (05/08/25)

  ELSEIF p_uswc = 'X'.
    IF s_unum IS NOT INITIAL
    OR s_umnum IS NOT INITIAL.
      SELECT * FROM /psyng/swresusr INTO TABLE gt_user
            WHERE    aid         = p_aid AND
                     bname       IN s_bname AND
                     class       IN s_class AND
                     kostl       IN s_kostl AND
                     company     IN s_comp AND
                     department  IN s_dep  AND
                     nr_conflicts IN s_unum AND
                     nr_mitigated IN s_umnum AND
                     ustyp        IN lr_usertype.

*BOC:HBHALLA (PN-14607) (05/08/25)
      LOOP AT gt_user.
        l_tabix = sy-tabix.
        READ TABLE et_users WITH KEY bname = gt_user-bname BINARY SEARCH
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE gt_user[] INDEX l_tabix.
        ENDIF.
      ENDLOOP.
*EOC:HBHALLA (PN-14607) (05/08/25)

    ELSE.
      SELECT * FROM /psyng/swresusr INTO TABLE gt_user
            WHERE    aid        = p_aid AND
                     bname       IN s_bname AND
                     class       IN s_class AND
                     kostl       IN s_kostl AND
                     company     IN s_comp AND
                     department  IN s_dep  AND
                     ustyp        IN lr_usertype AND
                     nr_conflicts > 0 .

*BOC:HBHALLA (PN-14607) (05/08/25)
      LOOP AT gt_user.
        l_tabix = sy-tabix.
        READ TABLE et_users WITH KEY bname = gt_user-bname BINARY SEARCH
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE gt_user[] INDEX l_tabix.
        ENDIF.
      ENDLOOP.
*EOC:HBHALLA (PN-14607) (05/08/25)

    ENDIF.
  ELSE.
    SELECT * FROM /psyng/swresusr INTO TABLE gt_user
          WHERE    aid      = p_aid AND
                   bname       IN s_bname AND
                   class       IN s_class AND
                   kostl       IN s_kostl AND
                   company     IN s_comp AND
                   department  IN s_dep  AND
                   ustyp        IN lr_usertype.
*                   nr_conflicts = 0.

*BOC:HBHALLA (PN-14607) (05/08/25)
    LOOP AT gt_user.
      l_tabix = sy-tabix.
      READ TABLE et_users WITH KEY bname = gt_user-bname BINARY SEARCH
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_user[] INDEX l_tabix.
      ENDIF.
    ENDLOOP.
*EOC:HBHALLA (PN-14607) (05/08/25)

    LOOP AT gt_user.
      l_num_actual_con = gt_user-nr_conflicts - gt_user-nr_mitigated.
      IF l_num_actual_con > 0.
        DELETE gt_user.
      ENDIF.
    ENDLOOP.
    IF gt_user[] IS INITIAL.
      SELECT SINGLE COUNT(*) FROM /psyng/swresusr INTO l_numcon_part
              WHERE aid = p_aid AND
                   nr_conflicts = 0.
      IF l_numcon_part = 0.
        l_aid = p_aid.
        SHIFT l_aid LEFT DELETING LEADING '0'.
        MESSAGE s002 WITH
       'Users without conflict are not stored'(x12)
       'in the analysis'(x13)
       l_aid.
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.
*--Create the root node
  SELECT SINGLE * FROM /psyng/swreshdr INTO ls_hdr
         WHERE aid = p_aid.
* BOC by RGUPTA for C0633
*    Odubey 20/02/2024 PN3805
  IF ls_hdr-se_version CS 'Q'.
  ELSE.
    IF ls_hdr-se_version < '4.6'
      AND ( p_local IS INITIAL
      OR p_remote IS INITIAL
      OR p_cross IS INITIAL ).
      MESSAGE s002 WITH 'Conflict origin filter not supported'(027)
      'for SOD analysis executed in'(028)
      'Separations Enforcer versions before 4.6'(029)
      DISPLAY LIKE 'W'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
* EOC by RGUPTA for C0633
  gs_hdr = ls_hdr.
  CONCATENATE ls_hdr-description ls_hdr-bname
              ls_hdr-start_date  ls_hdr-start_time
              INTO l_desc SEPARATED BY space.

  CONCATENATE 'Result ID'(r01) p_aid INTO l_head SEPARATED BY space.

  IF  s_bname  IS INITIAL
  AND s_class  IS INITIAL
  AND s_kostl  IS INITIAL
  AND s_comp   IS INITIAL
  AND s_dep    IS INITIAL
  AND s_unum   IS INITIAL
  AND s_umnum  IS INITIAL
  AND lr_usertype[] IS INITIAL "HBHALLA
  AND gt_user[] IS INITIAL.
    leaf_node gt_node gt_item '' 'R' 'DATA' l_desc l_head '@FN@' ''.
    g_summary_del = 'X'.
    EXIT.
  ENDIF.
  child_node gt_node gt_item '' 'R' 'DATA' l_desc l_head '' ''.
  LOOP AT gt_user.
    lr_users-low = gt_user-userindex.
    APPEND lr_users.
  ENDLOOP.
*--Conflicts
  SELECT * FROM /psyng/swresicon INTO TABLE gt_conflict
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

  IF NOT s_conid[] IS INITIAL AND p_uswc = 'X'.
*--Filter by conflicts was used, remove users that don't have any of
*these conflicts
DATA : lt_rescon        TYPE HASHED TABLE OF /psyng/swrescon WITH UNIQUE
KEY userindex,
lt_rescon_nosort TYPE TABLE OF /psyng/swrescon.
    lr_users_all[] = lr_users[].
    REFRESH : lt_rescon.
    WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
      REFRESH : lr_users_part , lt_rescon_nosort.
      APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
      DELETE lr_users_all FROM 1 TO 5000.
      SELECT DISTINCT userindex FROM /psyng/swrescon
        INTO CORRESPONDING FIELDS OF TABLE lt_rescon_nosort
         WHERE
          aid       =   p_aid AND
          userindex IN  lr_users_part AND
          conindex  IN  gr_conflicts.
      INSERT LINES OF lt_rescon_nosort INTO TABLE lt_rescon.
    ENDWHILE.
    FREE : lr_users_part ,lr_users_all.
    LOOP AT lr_users.
      READ TABLE lt_rescon WITH TABLE KEY userindex = lr_users-low
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE gt_user WHERE userindex = lr_users-low.
        DELETE lr_users WHERE low = lr_users-low.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--If include mitigated conflicts is not selected,
**--remove users that don't have any of unmitigated conflict
**--Also remove conflicts; if not present in any user
  IF p_mitcon IS INITIAL.
    DATA : lt_rescon_usr        TYPE SORTED TABLE OF ty_swrescon
           WITH NON-UNIQUE KEY userindex,
           lt_rescon_usr_nosort TYPE TABLE OF ty_swrescon.
    DATA  lt_rescon_tmp TYPE SORTED TABLE OF ty_swrescon
          WITH NON-UNIQUE KEY conindex.
    IF NOT s_conid[] IS INITIAL.
      lr_users_all[] = lr_users[].

      WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
        REFRESH : lr_users_part , lt_rescon_usr_nosort.
        APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
        DELETE lr_users_all FROM 1 TO 5000.
        SELECT userindex conindex FROM /psyng/swrescon
          INTO TABLE lt_rescon_usr_nosort
           WHERE
            aid       =   p_aid AND
            userindex IN  lr_users_part AND
            conindex  IN gr_conflicts AND
            mitigated = p_mitcon.
        INSERT LINES OF lt_rescon_usr_nosort INTO TABLE lt_rescon_usr.
      ENDWHILE.
      FREE : lr_users_part ,lr_users_all, lt_rescon_usr_nosort.

    ELSE.
* BOC by RGUPTA for C0583 on 10th Jan, 2022
      lr_users_all[] = lr_users[].

      WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
        REFRESH : lr_users_part , lt_rescon_usr_nosort.
        APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
        DELETE lr_users_all FROM 1 TO 5000.
* EOC by RGUPTA for C0583 on 10th Jan, 2022
        SELECT userindex conindex FROM /psyng/swrescon
          INTO TABLE lt_rescon_usr_nosort "lt_rescon_usr  by RGUPTA
           WHERE
            aid       =   p_aid AND
            userindex IN  lr_users_part AND "lr_users AND by RGUPTA
            mitigated = p_mitcon.
* BOC by RGUPTA for C0583 on 10th Jan, 2022
        INSERT LINES OF lt_rescon_usr_nosort INTO TABLE lt_rescon_usr.
      ENDWHILE.
      FREE : lr_users_part ,lr_users_all, lt_rescon_usr_nosort.
* EOC by RGUPTA for C0583 on 10th Jan, 2022
    ENDIF.
    IF p_uswc EQ 'X'.
      LOOP AT lr_users.
        READ TABLE lt_rescon_usr WITH TABLE KEY userindex = lr_users-low
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE gt_user WHERE userindex = lr_users-low.
          DELETE lr_users WHERE low = lr_users-low.
        ENDIF.
      ENDLOOP.
    ENDIF.
    lt_rescon_tmp = lt_rescon_usr.
    LOOP AT gt_conflict.
 READ TABLE lt_rescon_tmp WITH TABLE KEY conindex = gt_conflict-conindex
 TRANSPORTING NO FIELDS.
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

*--Load variable elements in SOD Matrix
  SELECT * FROM /psyng/faobj2 INTO TABLE gt_varel WHERE
    vrsio     = ls_hdr-sodvrsio AND
    val_from  LIKE '/PSYNG/$%'
    ORDER BY funid tcode object field val_from.

*--Load Org Elements in SOD Matrix
  FREE : gt_sodorgm.
  LOOP AT gt_system.
    CALL FUNCTION '/PSYNG/SW_AO_READ_VALUES'
      EXPORTING
        i_vrsio      = ls_hdr-sodvrsio
        i_setid      = ls_hdr-setid
        i_sysid      = gt_system-sysid
      TABLES
        et_swsodorgm = lt_sodorgm.
    SORT lt_sodorgm BY object varbl.
    DELETE ADJACENT DUPLICATES FROM lt_sodorgm COMPARING object varbl.
    gt_sodorgm-sysid = gt_system-sysid.
    gt_sodorgm-sodorgm[] = lt_sodorgm[].
    APPEND gt_sodorgm.
  ENDLOOP.
  SORT gt_sodorgm BY sysid.
  IF gt_user[] IS INITIAL.
    MESSAGE s002 WITH
    'No users match selection criteria'(x04).
    LEAVE LIST-PROCESSING.
  ENDIF.
  IF p_nogrp <> 'X'.
*--Handle correct grouping
    lt_users[] = gt_user[].
    CASE 'X'.
      WHEN p_gclass.
*--Group by usergroup
        l_icon = '@ID@'.
        l_groupnode_type = 'CLASS'.
        SORT lt_users BY class.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING class.
      WHEN p_gkostl.
*--Group by Cost Center
        l_icon = '@BL@'.
        l_groupnode_type = 'KOSTL'.
        SORT lt_users BY kostl.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING kostl.
      WHEN p_gcomp.
*--Group by Company
        l_icon = '@D9@'.
        l_groupnode_type = 'COMPANY'.
        SORT lt_users BY company.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING company.
      WHEN p_gdep.
*--Group By Department
        l_icon = '@JS@'.
        l_groupnode_type = 'DEPARTMENT'.
        SORT lt_users BY department.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING department.
    ENDCASE.
    IF lt_users[] IS INITIAL.
      MESSAGE s002 WITH
      'No users match selection criteria'(x04).
      LEAVE LIST-PROCESSING.

    ELSE.

      LOOP AT lt_users.
        CASE 'X'.
          WHEN p_gclass.
*--Group by usergroup
            l_groupnode_value = lt_users-class.
            PERFORM get_text_usergroup
              USING lt_users-class
              CHANGING l_groupnode_text.
          WHEN p_gkostl.
*--Group by Cost Center
            l_groupnode_value = lt_users-kostl.
            PERFORM get_text_kostl
              USING    lt_users-kostl
              CHANGING l_groupnode_text.
          WHEN p_gcomp.
*--Group by Company
            l_groupnode_value = lt_users-company.
            PERFORM get_text_company
              USING lt_users-company
                    l_groupnode_text.
          WHEN p_gdep.
*--Group By Department
            l_groupnode_value = lt_users-department.
*        Department is a free text field
            l_groupnode_text =  lt_users-department.
        ENDCASE.

        ADD 1 TO l_group_id.
        child_node gt_node gt_item 'R_DATA' 'G' l_group_id
        l_groupnode_value l_groupnode_text  l_icon ''.
        hidden_column gt_item ls_node-node_key
          'NODETYPE'   'GROUP'.
        hidden_column gt_item ls_node-node_key
          'GROUPNAME'  l_groupnode_value.
      ENDLOOP.

    ENDIF.
  ENDIF.

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
    IF p_nogrp = 'X'
    AND g_summary_del IS INITIAL.
*  --No grouping was requested
*    show all user nodes
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
  DATA: lt_resultset TYPE TABLE OF /psyng/swreshdr.

  IF sy-ucomm = 'EXIT' OR sy-ucomm = 'BACK'.

    SET SCREEN 0.
    LEAVE SCREEN.

*--C0526
  ELSEIF sy-ucomm = 'SORT'.
    IF  p_nogrp = 'X'.
      CALL SCREEN '0401' STARTING AT 10 1.
    ELSE.
      MESSAGE i002(/psyng/sw) WITH
      'Sorting only supported in No Grouping'(I30).
    ENDIF.
*-- end
  ELSEIF sy-ucomm = 'EXPAND'.
    CALL SCREEN '0101' STARTING AT 10 1.

  ELSEIF sy-ucomm = 'FIND'.
    CLEAR: g_start_pos, g_start_con_pos.
    CALL SCREEN '0102' STARTING AT 10 1.
  ELSEIF sy-ucomm = 'FINDNEXT'.
    IF g_start_pos IS INITIAL.
      IF gf_fnd_bname IS INITIAL.
     MESSAGE i002(/psyng/sw) WITH 'There is no find performed yet'(i01).
      ELSE.
        MESSAGE s002(/psyng/sw) WITH 'No match found'(i02).
      ENDIF.
    ELSE.
      PERFORM find_node USING g_start_pos g_start_con_pos.
    ENDIF.
  ELSEIF sy-ucomm = 'EXPORT'.
* BOC by GSINGH for C0765
* Commented the old form as we need to enhance the export functionality
*    PERFORM export_data_to_alv.
* Get the user selected node id from the tree
    PERFORM get_sel_node.
    IF NOT g_node_key IS INITIAL.
* Call the new screen to display the different export options
      CALL SCREEN '0103' STARTING AT 10 1.
* If node is not selected, display the message.
    ELSE.
 MESSAGE s002(/psyng/sw) WITH 'Select any node to export the data'(i33).
    ENDIF.
*   EOC by GSINGH
  ELSEIF sy-ucomm = 'ANA_DTL'.
    SELECT * FROM /psyng/swreshdr INTO TABLE lt_resultset
    WHERE aid = p_aid.
*---show popup with detail
    IF NOT lt_resultset[] IS INITIAL.
      CALL FUNCTION '/PSYNG/SW_STORED_RSLT_DETAILS'
        EXPORTING
          i_aid        = p_aid
        TABLES
          it_resultset = lt_resultset.
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
  DATA : ls_bname   TYPE mtreeitm,
         lt_usercon TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
         ls_node    TYPE treev_node,
         ls_item    TYPE mtreeitm,
         lt_node    TYPE treev_ntab,
         lt_item    TYPE ttree_item,
         lt_users   TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
         l_icon     TYPE icon_d.

*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
    IF p_nogrp <> 'X'.
      READ TABLE gt_item INTO ls_bname
           WITH KEY node_key  = i_node_key
                    item_name = 'GROUPNAME'.
    ENDIF.

    IF g_sort_clicked = 'X'. " C0526 start
      REFRESH lt_users.
    ENDIF.   " end

    lt_users[] = gt_user[].
    CASE 'X'.
      WHEN p_gclass.
*  --Group by usergroup
        DELETE lt_users WHERE class <> ls_bname-text.
      WHEN p_gkostl.
*  --Group by Cost Center
        DELETE lt_users WHERE kostl <> ls_bname-text.
      WHEN p_gcomp.
*  --Group by Company
        DELETE lt_users WHERE company <> ls_bname-text.
      WHEN p_gdep.
*  --Group By Department
        DELETE lt_users WHERE department <> ls_bname-text.
      WHEN p_nogrp.
*  --No gropuping, all users
    ENDCASE.
*  *--Create the user nodes

    IF g_sort_clicked IS INITIAL.
      SORT lt_users BY nr_conflicts DESCENDING
                       nr_mitigated DESCENDING
                       bname.
*---C0526 start
    ELSE.
      IF gr_sort_bname = 'X'.
        IF gf_sort_bname = 'ASC'.
          SORT lt_users BY bname ASCENDING.
        ELSE.
          SORT lt_users BY bname DESCENDING.
        ENDIF.
      ELSE.
        IF gf_sort_conf = 'ASC'.
          SORT lt_users BY nr_conflicts ASCENDING.
        ELSE.
          SORT lt_users BY nr_conflicts DESCENDING.
        ENDIF.
      ENDIF.
      CLEAR g_sort_clicked.
    ENDIF.
*---C0526 end

    LOOP AT lt_users.
      IF lt_users-locked = 'X'.
        l_icon = '@06@'.
      ELSE.
        l_icon = '@07@'.
      ENDIF.
      ADD 1 TO g_bname_id.
      IF lt_users-nr_conflicts > 0 OR
         lt_users-nr_mitigated > 0.
        IF lt_users-nr_conflicts = lt_users-nr_mitigated
        AND p_mitcon IS INITIAL.
*  -- non expandable node

          leaf_node_inactive
            lt_node
            lt_item
            i_node_key
            'B'
            g_bname_id
            lt_users-bname
            lt_users-name_text
            '@A0@'
             l_icon.

*Begin of Addition <HBHALLA> PN-15675 27/10/2025
          CLEAR ls_item.
          g_mac_dum_str = g_bname_id.
          CONCATENATE 'B' '_' g_mac_dum_str INTO ls_node-node_key.

          IF NOT lt_users-department IS INITIAL.
            ls_item-node_key  = ls_node-node_key.
            ls_item-item_name = 'DEPRTMNT'.
            ls_item-class     = cl_gui_column_tree=>item_class_text.
            g_mac_dum_str     = lt_users-department.
            ls_item-text      = g_mac_dum_str.
*        --Inactive
            ls_item-style =   cl_gui_column_tree=>style_inactive.
            APPEND ls_item TO lt_item.
          ENDIF.
          CLEAR ls_item-style.
*End of Addition <HBHALLA> PN-15675 27/10/2025

          text_column lt_item ls_node-node_key
             'CONFNUM'   lt_users-nr_conflicts '' 'X'.
        ELSE.
*  -- add expandable node
          child_node lt_node lt_item i_node_key 'B' g_bname_id
              lt_users-bname lt_users-name_text  '@A0@' l_icon.
*Begin of Addition <HBHALLA> PN-15675 27/10/2025
          IF NOT lt_users-department IS INITIAL.
            text_column lt_item ls_node-node_key
             'DEPRTMNT'   lt_users-department '' ' '.
          ENDIF.
*End of Addition <HBHALLA> PN-15675 27/10/2025
          IF NOT lt_users-nr_conflicts IS INITIAL.
            text_column lt_item ls_node-node_key
             'CONFNUM'   lt_users-nr_conflicts '' ' '.
          ENDIF.
          IF NOT lt_users-nr_mitigated IS INITIAL
          AND p_mitcon EQ 'X'.
            text_column lt_item ls_node-node_key
              'MITINUM'   lt_users-nr_mitigated '' ' '.
          ENDIF.
        ENDIF.
      ELSE.
*  -- non expandable node
        leaf_node_inactive
        lt_node
        lt_item
        i_node_key
        'B'
        g_bname_id
        lt_users-bname
        lt_users-name_text
        '@A0@'
        l_icon.

*Begin of Addition <HBHALLA> PN-15675 27/10/2025
        CLEAR ls_item.
        g_mac_dum_str = g_bname_id.
        CONCATENATE 'B' '_' g_mac_dum_str INTO ls_node-node_key.

        IF NOT lt_users-department IS INITIAL.
          ls_item-node_key  = ls_node-node_key.
          ls_item-item_name = 'DEPRTMNT'.
          ls_item-class     = cl_gui_column_tree=>item_class_text.
          g_mac_dum_str     = lt_users-department.
          ls_item-text      = g_mac_dum_str.
*      --Inactive
          ls_item-style =   cl_gui_column_tree=>style_inactive.
          APPEND ls_item TO lt_item.
        ENDIF.
        CLEAR ls_item-style.
*End of Addition <HBHALLA> PN-15675 27/10/2025

      ENDIF.

      hidden_column lt_item ls_node-node_key
        'NODETYPE'   'BNAME'.
      hidden_column lt_item ls_node-node_key
        'USERINDEX'  lt_users-userindex.

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
      MESSAGE e002(/psyng/sw) WITH 'Adding User nodes to tree failed'.
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


*&---------------------------------------------------------------------*
*&      Form  expand_bname
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_NODE_KEY  text
*----------------------------------------------------------------------*
FORM expand_bname USING    i_node_key TYPE tv_nodekey.
  DATA : ls_bname       TYPE mtreeitm,
         lt_usercon     TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
         ls_node        TYPE treev_node,
         ls_item        TYPE mtreeitm,
         lt_node        TYPE treev_ntab,
         lt_item        TYPE ttree_item,
         l_cdescription TYPE /psyng/rskdsc,
         lt_conflicts   TYPE TABLE OF /psyng/swresicon WITH HEADER LINE,
         lv_origin      TYPE c LENGTH 12. "RGUPTA for C0633
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.
  IF gf_node_has_children <> 'X'.
    READ TABLE gt_item INTO ls_bname
         WITH KEY node_key  = i_node_key
                  item_name = 'USERINDEX'.
*--User Conflicts
    IF p_mitcon EQ 'X'.
      SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
               WHERE aid       =  p_aid AND
                     userindex =  ls_bname-text AND
                     conindex  IN gr_conflicts.
    ELSE.
      SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
               WHERE aid       =  p_aid AND
                     userindex =  ls_bname-text AND
                     conindex  IN gr_conflicts AND
                     mitigated = p_mitcon.
    ENDIF.
    SORT lt_usercon BY conindex.
*--Collect the conflicts sorted by conflict ID
    REFRESH : lt_conflicts.
    LOOP AT lt_usercon.
      READ TABLE gt_conflict WITH KEY conindex = lt_usercon-conindex.
      APPEND gt_conflict TO lt_conflicts.
    ENDLOOP.
    SORT lt_conflicts BY conid.
*BOC UMITTAL 29/09/2025 Do not Expand users with no conflicts
    CHECK NOT lt_conflicts[] IS INITIAL.
*EOC UMITTAL 29/09/2025 Do not Expand users with no conflicts
    LOOP AT lt_conflicts.
      READ TABLE lt_usercon WITH KEY conindex = lt_conflicts-conindex
      BINARY SEARCH.
* BOC by RGUPTA on 25.03.22
      IF lt_usercon-origin IS NOT INITIAL.
        IF p_local = 'X' AND p_remote IS INITIAL
         AND p_cross IS INITIAL
         AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
            OR lt_usercon-origin = 5 ).
          CONTINUE.
        ELSEIF p_local = 'X' AND p_remote = 'X'
         AND p_cross IS INITIAL
         AND lt_usercon-origin = 3.
          CONTINUE.
        ELSEIF p_local = 'X' AND p_remote IS INITIAL
         AND p_cross = 'X'
         AND lt_usercon-origin = 2.
          CONTINUE.
        ELSEIF p_local IS INITIAL AND p_remote = 'X'
         AND p_cross IS INITIAL
         AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
            OR lt_usercon-origin = 4 ).
          CONTINUE.
        ELSEIF p_local IS INITIAL AND p_remote = 'X'
         AND p_cross = 'X'
         AND lt_usercon-origin = 1.
          CONTINUE.
        ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
         AND p_cross = 'X'
         AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
          CONTINUE.
        ENDIF.
      ENDIF.
* EOC by RGUPTA on 25.03.22
      ADD 1 TO g_usercon_id.
      PERFORM get_text_conflict USING    lt_conflicts-conid
                                CHANGING l_cdescription.

      child_node lt_node lt_item i_node_key 'C'
              g_usercon_id lt_conflicts-conid l_cdescription '@9O@' '' .
      IF  p_mitcon EQ 'X'
      AND NOT lt_usercon-mitigated IS INITIAL.
        link_column lt_item ls_node-node_key
              'MITIGATED'   lt_usercon-mitigated ''.
      ENDIF.
* BOC by RGUPTA on 22.03.22 for C0633
      IF NOT lt_usercon-origin IS INITIAL.
        CASE lt_usercon-origin.
          WHEN '1'.
            lv_origin = 'Local'(021).
          WHEN '2'.
            lv_origin = 'Remote'(022).
          WHEN 3.
            lv_origin = 'Cross'(023).
          WHEN 4.
            lv_origin = 'Local&Cross'(024).
          WHEN 5.
            lv_origin = 'Remote&Cross'(025).
          WHEN 6.
            lv_origin = 'L&R&C'(026).
        ENDCASE.
        text_column lt_item ls_node-node_key
         'CONFNUM'   lv_origin '' ' '.
      ENDIF.
* EOC by RGUPTA on 22.03.22 for C0633
      hidden_column lt_item ls_node-node_key
        'NODETYPE'   'USERCON'.
      hidden_column lt_item ls_node-node_key
        'CONINDEX' lt_usercon-conindex.

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

ENDFORM.                    " expand_bname


*---------------------------------------------------------------------*
*       FORM expand_usercon                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_usercon USING    i_node_key TYPE tv_nodekey.
  DATA : ls_con         TYPE mtreeitm,
         lt_confun      TYPE TABLE OF /psyng/swrescfun WITH HEADER LINE,
         ls_function    TYPE /psyng/swresifun,
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
    SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
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

ENDFORM.                    " expand_bname

*---------------------------------------------------------------------*
*       FORM expand_function                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_NODE_KEY                                                    *
*---------------------------------------------------------------------*
FORM expand_function USING    i_node_key TYPE tv_nodekey.
  DATA : ls_fun         TYPE mtreeitm,
         ls_con         TYPE mtreeitm,
         ls_user        TYPE mtreeitm,
         lt_funprof     TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
"Added by : UMITTAL C1342 D67K931619 14/05/2024
         lt_fprprof     TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
         lt_usrprof     TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
         lt_profrole    TYPE SORTED TABLE OF /psyng/swresprol
                     WITH HEADER LINE WITH UNIQUE KEY profindex,
         lt_roles       TYPE SORTED TABLE OF /psyng/swresirol
                     WITH HEADER LINE WITH UNIQUE KEY roleindex,
         lt_comprole    TYPE SORTED TABLE OF /psyng/swresucom
                     WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
*       sorting lt_comprole by compindex instead of roleindex,
         ls_role        TYPE /psyng/swresirol,
         ls_comprole    TYPE /psyng/swresirol,
         lt_profiles    TYPE TABLE OF /psyng/swresipro,
         lt_authdet     TYPE TABLE OF /psyng/seres_authdetail
                     WITH HEADER LINE,
         lt_authdet_all TYPE TABLE OF /psyng/seres_authdetail
                     WITH HEADER LINE,
         ls_function    TYPE /psyng/swresifun,
         ls_node        TYPE treev_node,
         ls_item        TYPE mtreeitm,
         lt_node        TYPE treev_ntab,
         ls_connode     TYPE treev_node,
         ls_funnode     TYPE treev_node,
         ls_usernode    TYPE treev_node,
         lt_item        TYPE ttree_item,
         lt_role_nodes TYPE ttree_item,
         l_funindex     TYPE /psyng/seres_funindex,
         l_userinndex   TYPE /psyng/seres_userindex,
         lt_funprofile  TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
         lt_expand      TYPE treev_nks,
         lt_orgabb      TYPE  TABLE OF /psyng/swresiabb
         WITH HEADER LINE ,
         l_numfun       TYPE i,
         lf_duplicate_nodes TYPE flag, "P&G AKUMAR
"Added by : UMITTAL C1342 D67K931619 14/05/2024
         l_inst         TYPE /psyng/bapiflagx,
         l_new_se_vrs   TYPE flag,
         l_se_vrsion    TYPE /psyng/prog_vrsio,
         lt_uabb TYPE TABLE OF /psyng/swresuabb. "HBHALLA

  RANGES : lr_funid FOR l_funindex.
*--Check if this node already has children, if not, don't expand.
  exit_if_has_children i_node_key.

  APPEND i_node_key TO lt_expand.
  IF gf_node_has_children <> 'X'.
*--Get function index value
    READ TABLE gt_item INTO ls_fun
         WITH KEY node_key  = i_node_key
                  item_name = 'FUNINDEX'.
*--Get the userid, 2 nodes up
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
    INTO ls_usernode
    WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
    READ TABLE gt_item INTO ls_user
       WITH KEY node_key  = ls_usernode-node_key
                item_name = 'USERINDEX'.
*--Get the user's profiles for this function
    l_funindex = ls_fun-text.
    l_userinndex = ls_user-text.


*--Get the org area abreviations
* for this function
* for this user
* for this conflict

*--Get the range of functions for this conflicy
    SELECT funindex AS low FROM /psyng/swrescfun
    INTO CORRESPONDING FIELDS OF TABLE lr_funid
     WHERE aid      = g_aid AND
           conindex = ls_con-text.

    lr_funid-sign   = 'I'.
    lr_funid-option = 'EQ'.
    MODIFY    lr_funid  FROM lr_funid
      TRANSPORTING sign option
      WHERE sign IS INITIAL .

    DESCRIBE TABLE lr_funid LINES l_numfun.



    SELECT i~org_abb COUNT( DISTINCT u~funindex ) AS abbindex
    FROM /psyng/swresiabb AS i
    INNER JOIN /psyng/swresuabb AS u ON
       u~aid            = i~aid AND
       u~abbindex       = i~abbindex
    INTO CORRESPONDING FIELDS OF
      TABLE lt_orgabb

      WHERE u~aid       = p_aid AND
            u~userindex = l_userinndex AND
            u~funindex  IN lr_funid
      GROUP BY i~org_abb.

*BOC:HBHALLA (PN-13314) (Org values not visible with config set)
    SELECT * FROM /psyng/swresuabb INTO TABLE lt_uabb WHERE aid = p_aid.

    LOOP AT lr_funid.
      READ TABLE lt_uabb WITH KEY funindex = lr_funid-low
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        l_numfun = l_numfun - 1.
      ENDIF.
    ENDLOOP.
*EOC:HBHALLA (PN-13314) (27/05/25)

    DELETE lt_orgabb WHERE abbindex <> l_numfun.
    SORT lt_orgabb BY org_abb.

*--Get the function's profiles


*--One step approach with joins
*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
    CLEAR l_se_vrsion.
    SELECT SINGLE se_version INTO l_se_vrsion
      FROM /psyng/swreshdr
      WHERE aid = g_aid.
    IF l_se_vrsion > '4.7PS2C' OR
       l_se_vrsion CA 'Q' .

      CLEAR l_new_se_vrs.
      l_new_se_vrs = 'X'.
*--- we should add the same logic in export to ALV, export to server
*--- export to file and API's also.
      SELECT * FROM /psyng/swresfpr
      INTO TABLE lt_fprprof
      WHERE aid       = p_aid AND
            userindex = l_userinndex AND
            funindex  = l_funindex.
    ELSE.
      CLEAR l_new_se_vrs.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
      SELECT * FROM /psyng/swresupr  AS up
      INNER JOIN /psyng/swresfpr AS fp
        ON
          fp~aid          = up~aid AND
          fp~profileindex = up~profileindex AND
          fp~sys          = up~sys
      INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
      WHERE fp~aid          = p_aid AND
             up~userindex    = l_userinndex AND
             fp~funindex     = l_funindex.
    ENDIF. "++Added by:UMITTAL C1342 D67K931619 14/05/2024


*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
    IF l_new_se_vrs EQ 'X'.
*--Get the roles
      IF NOT lt_fprprof[] IS INITIAL.

        SELECT * FROM /psyng/swresipro
          INTO TABLE lt_profiles
          FOR ALL ENTRIES IN lt_fprprof
          WHERE aid       = p_aid AND
*                sys       = lt_usrprof-sys and
                profindex = lt_fprprof-profileindex.

        SELECT * FROM /psyng/swresprol
          INTO TABLE lt_profrole
          FOR ALL ENTRIES IN lt_fprprof
          WHERE aid       = p_aid AND
*               sys       = lt_usrprof-sys and
                profindex = lt_fprprof-profileindex.
        IF NOT lt_profrole[] IS INITIAL.
          SELECT * FROM /psyng/swresirol
            INTO TABLE lt_roles
            FOR ALL ENTRIES IN lt_profrole
            WHERE aid = p_aid AND
                  roleindex = lt_profrole-roleindex.
          IF NOT lt_roles[] IS INITIAL.
*  --Get any composite role through which these roles may be assigned
            SELECT * FROM /psyng/swresucom
              INTO TABLE lt_comprole
              FOR ALL ENTRIES IN lt_roles WHERE
                aid       = p_aid              AND
                userindex = l_userinndex       AND
                roleindex = lt_roles-roleindex AND
                compindex <> 0.
            IF NOT lt_comprole[] IS INITIAL.
              SELECT * FROM /psyng/swresirol
                APPENDING TABLE lt_roles
                FOR ALL ENTRIES IN lt_comprole
                  WHERE aid = p_aid AND
                        roleindex = lt_comprole-compindex.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

    ELSE.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
*--Get the roles
      IF NOT lt_usrprof[] IS INITIAL.

        SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
          FOR ALL ENTRIES IN
            lt_usrprof
        WHERE aid       = p_aid AND
*              sys       = lt_usrprof-sys and
              profindex = lt_usrprof-profileindex.

        SELECT * FROM /psyng/swresprol
        INTO TABLE lt_profrole
        FOR ALL ENTRIES IN lt_usrprof
        WHERE aid       = p_aid AND
*              sys       = lt_usrprof-sys and
              profindex = lt_usrprof-profileindex.
        IF NOT lt_profrole[] IS INITIAL.
          SELECT * FROM /psyng/swresirol
          INTO TABLE lt_roles
          FOR ALL ENTRIES IN lt_profrole
            WHERE aid = p_aid AND
                  roleindex = lt_profrole-roleindex.
          IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
            SELECT * FROM /psyng/swresucom
            INTO TABLE lt_comprole
            FOR ALL ENTRIES IN lt_roles WHERE
              aid = p_aid AND
              userindex = l_userinndex AND
              roleindex = lt_roles-roleindex AND
              compindex <> 0.
            IF NOT lt_comprole[] IS INITIAL.
              SELECT * FROM /psyng/swresirol
              APPENDING TABLE lt_roles
              FOR ALL ENTRIES IN lt_comprole
                WHERE aid = p_aid AND
                      roleindex = lt_comprole-compindex.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF."++Added by : UMITTAL C1342 D67K931619 14/05/2024

*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
    IF l_new_se_vrs EQ 'X'.
      LOOP AT lt_fprprof.
        REFRESH : lt_authdet.
        CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
          EXPORTING
            i_aid             = p_aid
            i_sys             = lt_fprprof-sys
            i_funindex        = l_funindex
            i_profileindex    = lt_fprprof-profileindex
          TABLES
            et_profiledetails = lt_authdet.
        APPEND LINES OF lt_authdet TO lt_authdet_all.
        REFRESH : lt_authdet.
      ENDLOOP.
    ELSE.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
      LOOP AT lt_usrprof.
        REFRESH : lt_authdet.
        CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
          EXPORTING
            i_aid             = p_aid
            i_sys             = lt_usrprof-sys
            i_funindex        = l_funindex
            i_profileindex    = lt_usrprof-profileindex
          TABLES
            et_profiledetails = lt_authdet.
        APPEND LINES OF lt_authdet TO lt_authdet_all.
*    MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
*    APPEND gt_output_alv.
        REFRESH : lt_authdet.
      ENDLOOP.
    ENDIF. "++Added by:UMITTAL C1342 D67K931619 14/05/2024

    PERFORM add_function_detail_nodes
    TABLES
      lt_authdet_all
      lt_profiles
      lt_node
      lt_item
      lt_orgabb
    USING
      lt_expand[]
      i_node_key
      lt_comprole[]
      lt_profrole[]
      lt_roles[].

*C1052 AKUMAR BOC
    PERFORM check_duplicate_nodes USING lt_item
*--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024
                                        lt_roles[]
                                        lt_profrole[]
*--End of insert : UMITTAL C1342 D67K931619 14/05/2024

                                  CHANGING lf_duplicate_nodes
                                           lt_role_nodes.

    IF lf_duplicate_nodes EQ 'X'.
      PERFORM merge_duplicate_nodes CHANGING lt_node
                                             lt_item
                                             lt_role_nodes.
    ENDIF.
*C1052 AKUMAR EOC

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
  CALL METHOD go_tree->expand_nodes
    EXPORTING
      node_key_table = lt_expand.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.                    " expand_bname



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
         ls_usernode TYPE treev_node,
         ls_fun      TYPE mtreeitm,
         ls_user     TYPE mtreeitm,
         ls_prof     TYPE mtreeitm,
         ls_sys      TYPE mtreeitm,
         ls_obj      TYPE mtreeitm,
         ls_tcode    TYPE mtreeitm,
         ls_field    TYPE mtreeitm,
         l_sysindex  TYPE i,
         l_funindex  TYPE i,
         l_profindex TYPE i,
         lt_authdet  TYPE TABLE OF /psyng/seres_authdetail
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
         WITH KEY node_key  = ls_funnode-relatkey
                  item_name = 'FUNINDEX'.
*--Possibly this is a composite role, go one more level up
    IF sy-subrc <> 0.
      READ TABLE gt_node
      INTO ls_funnode
      WITH KEY node_key = ls_funnode-relatkey.

*  --Get function index value
      READ TABLE gt_item INTO ls_fun
           WITH KEY node_key  = ls_funnode-relatkey
                    item_name = 'FUNINDEX'.
    ENDIF.

    READ TABLE gt_node
    INTO ls_connode
    WITH KEY node_key = ls_funnode-relatkey.

    READ TABLE gt_node
    INTO ls_usernode
    WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
    READ TABLE gt_item INTO ls_user
       WITH KEY node_key  = ls_usernode-node_key
                item_name = 'USERINDEX'.
*--Get the profile
    READ TABLE gt_item INTO ls_prof
         WITH KEY node_key  = i_node_key
                  item_name = 'PROFINDEX'.
*--Get the system
    READ TABLE gt_item INTO ls_sys
         WITH KEY node_key  = i_node_key
                  item_name = 'SYSINDEX'.

    l_funindex  = ls_fun-text.
    l_sysindex  = ls_sys-text.
    l_profindex = ls_prof-text.

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




    CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
      EXPORTING
        i_aid             = p_aid
        i_sys             = l_sysindex
        i_funindex        = l_funindex
        i_profileindex    = l_profindex
      TABLES
        et_profiledetails = lt_authdet.
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
      MESSAGE e002(/psyng/sw) WITH 'Adding User nodes to tree failed'.
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
         ls_usernode TYPE treev_node,
         ls_fun      TYPE mtreeitm,
         ls_user     TYPE mtreeitm,
         ls_prof     TYPE mtreeitm,
         ls_sys      TYPE mtreeitm,
         ls_obj      TYPE mtreeitm,
         ls_tcode    TYPE mtreeitm,
         ls_field    TYPE mtreeitm,
         l_sysindex  TYPE i,
         l_funindex  TYPE i,
         l_profindex TYPE i,
         lt_authdet  TYPE TABLE OF /psyng/seres_authdetail
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
         WITH KEY node_key  = ls_funnode-relatkey
                  item_name = 'FUNINDEX'.
*--Possibly this is a composite role, go one more level up
    IF sy-subrc <> 0.
      READ TABLE gt_node
      INTO ls_funnode
      WITH KEY node_key = ls_funnode-relatkey.

*  --Get function index value
      READ TABLE gt_item INTO ls_fun
           WITH KEY node_key  = ls_funnode-relatkey
                    item_name = 'FUNINDEX'.
    ENDIF.

*--Get the userid, 2 nodes up
*  READ TABLE gt_node
*  INTO ls_funnode
*  WITH KEY node_key = ls_funnode-node_key.

    READ TABLE gt_node
    INTO ls_connode
    WITH KEY node_key = ls_funnode-relatkey.

    READ TABLE gt_node
    INTO ls_usernode
    WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
    READ TABLE gt_item INTO ls_user
       WITH KEY node_key  = ls_usernode-node_key
                item_name = 'USERINDEX'.
*--Get the profile
    READ TABLE gt_item INTO ls_prof
         WITH KEY node_key  = i_node_key
                  item_name = 'PROFINDEX'.
*--Get the system
    READ TABLE gt_item INTO ls_sys
         WITH KEY node_key  = i_node_key
                  item_name = 'SYSINDEX'.

    l_funindex  = ls_fun-text.
    l_sysindex  = ls_sys-text.
    l_profindex = ls_prof-text.

*--Get abb
    READ TABLE gt_item INTO ls_obj
         WITH KEY node_key  = i_node_key
                  item_name = 'DATA'.


    CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
      EXPORTING
        i_aid             = p_aid
        i_sys             = l_sysindex
        i_funindex        = l_funindex
        i_profileindex    = l_profindex
      TABLES
        et_profiledetails = lt_authdet.
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
      MESSAGE e002(/psyng/sw) WITH 'Adding User nodes to tree failed'.
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
TABLES   it_authdet_all STRUCTURE  /psyng/seres_authdetail
         it_profiles    STRUCTURE  /psyng/swresipro
         et_node        STRUCTURE  treev_node
         et_item        STRUCTURE  mtreeitm
         it_abb         STRUCTURE  /psyng/swresiabb

USING
         et_expand      TYPE treev_nks
         i_parent       TYPE tv_nodekey
         it_comprole    TYPE ttyp_comprol
         it_profrole    TYPE ttyp_profile
         it_roles       TYPE ttyp_roles
         .
  DATA : ls_comprole      LIKE LINE OF it_comprole,
         ls_profrole      LIKE LINE OF it_profrole,
         ls_role          LIKE LINE OF it_roles,
         ls_node          TYPE treev_node,
         ls_item          TYPE mtreeitm,
         l_comp_role_text TYPE agr_texts-text,
         l_destination    TYPE rfcdes-rfcdest,
         l_pre_comprole   TYPE agr_define-agr_name,
         lt_comprole      TYPE TABLE OF /psyng/swresucom
              WITH HEADER LINE.
*---check for function detail level expand
  CHECK p_fun <> 'X'.

  CLEAR l_destination.
*--sorting it_comprole by compindex
  lt_comprole[] = it_comprole[].
  SORT lt_comprole BY compindex.

  LOOP AT lt_comprole   INTO ls_comprole.
    ADD 1 TO g_auth_id.
    READ TABLE it_roles WITH TABLE KEY roleindex = ls_comprole-compindex
                                                           INTO ls_role.
*--    destination
    READ TABLE it_authdet_all INDEX 1.

    SELECT SINGLE rfcdest FROM /psyng/sw_rfcdes INTO (l_destination)
    WHERE systid = it_authdet_all-sysid.
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
    CALL FUNCTION '/PSYNG/BC_021'
      DESTINATION l_destination
      EXPORTING
        i_agr_name = ls_role-agr_name
      IMPORTING
        e_text     = l_comp_role_text
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


*---role profile checkbox checked in expand option
*    IF p_rolpro = 'X'.
*      leaf_node et_node et_item i_parent 'CR' g_auth_id
*             ls_role-agr_name l_comp_role_text '@M7@' ''.
*    ELSE.
    IF l_pre_comprole <> ls_role-agr_name.
      child_node et_node et_item i_parent 'CR' g_auth_id
         ls_role-agr_name l_comp_role_text '@M7@' ''.
      APPEND ls_node-node_key TO et_expand.
      l_pre_comprole = ls_role-agr_name.
    ENDIF.
*--Add child roles
    PERFORM add_role_nodes
    TABLES
        it_authdet_all
        it_profiles
        et_node
        et_item
        it_abb
      USING
        et_expand[]
        ls_node-node_key
        ls_comprole-roleindex
        it_comprole[]
        it_profrole[]
        it_roles[].

  ENDLOOP.
  FREE lt_comprole.
*--Add single roles that are directly assigned
*  LOOP AT it_profrole INTO ls_profrole.
*    READ TABLE it_comprole WITH KEY roleindex = ls_profrole-roleindex
*    TRANSPORTING NO FIELDS.
  LOOP AT it_roles INTO ls_role.
*--Check if it's not a composite role
    READ TABLE it_comprole WITH KEY compindex = ls_role-roleindex
    TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Check if it's not assigned through composite role
     READ TABLE it_comprole WITH TABLE KEY roleindex = ls_role-roleindex
                                                 TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
*--Not assigned through composite
        PERFORM add_role_nodes
        TABLES
            it_authdet_all
            it_profiles
            et_node
            et_item
            it_abb
        USING
            et_expand[]
            i_parent
*          ls_profrole-roleindex
            ls_role-roleindex
            it_comprole[]
            it_profrole[]
            it_roles[].
      ENDIF.
    ENDIF.
  ENDLOOP.
*--Add directly assigned profiles
*@MD@
  LOOP AT it_profiles.
    READ TABLE it_profrole WITH KEY
      profindex = it_profiles-profindex
    TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      PERFORM add_profile_nodes
                  TABLES
                     it_authdet_all
                     it_profiles
                     et_node
                     et_item
                     it_abb
                  USING
                     et_expand[]
                     i_parent
                     it_profiles-profindex
                     it_comprole
                     it_profrole
                     it_roles.

    ENDIF.
  ENDLOOP.
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
  TABLES   it_authdet       STRUCTURE  /psyng/seres_authdetail
           it_profiles      STRUCTURE  /psyng/swresipro
           et_node          STRUCTURE  treev_node
           et_item          STRUCTURE  mtreeitm
           it_abb           STRUCTURE  /psyng/swresiabb
  USING    et_expand        TYPE       treev_nks
           i_parent         TYPE       tv_nodekey
           i_roleindex      TYPE       /psyng/seres_roleindex
           it_comprole      TYPE       ttyp_comprol
           it_profrole      TYPE       ttyp_profile
           it_roles         TYPE       ttyp_roles.

  DATA : ls_comprole        LIKE LINE OF it_comprole,
         ls_profrole        LIKE LINE OF it_profrole,
         ls_role            LIKE LINE OF it_roles,
         ls_node            TYPE treev_node,
         ls_item            TYPE mtreeitm,
         l_role_key         TYPE tv_nodekey,
         l_single_role_text TYPE agr_texts-text,
         l_rfctext          TYPE /psyng/sw_rfcdes-description,
         lt_varels          TYPE TABLE OF /psyng/seres_authdetail
                            WITH HEADER LINE,
         lt_orgs            TYPE TABLE OF /psyng/seres_authdetail
                            WITH HEADER LINE,
         l_type             TYPE string,
         ls_sodorgm         TYPE /psyng/swsodorgm,
         l_destination      TYPE /psyng/sw_rfcdes-rfcdest.

  READ TABLE it_roles WITH TABLE KEY roleindex = i_roleindex
  INTO ls_role.
  ADD 1 TO g_auth_id.

*--Role text
  READ TABLE it_authdet INDEX 1.
  PERFORM get_destination_system
    USING it_authdet-sysid
    CHANGING l_destination.
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
  CALL FUNCTION '/PSYNG/BC_021'
    DESTINATION l_destination
    EXPORTING
      i_agr_name = ls_role-agr_name
    IMPORTING
      e_text     = l_single_role_text
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF p_rolpro = 'X'.
    leaf_node et_node et_item i_parent 'SR' g_auth_id
                 ls_role-agr_name l_single_role_text '@IC@' ''.
  ELSE.
    child_node et_node et_item i_parent 'SR' g_auth_id
               ls_role-agr_name l_single_role_text '@IC@' ''.
    l_role_key = ls_node-node_key.
  ENDIF.

  CHECK p_orgvar = 'X'.

  LOOP AT it_profrole INTO ls_profrole
  WHERE roleindex = i_roleindex .
    READ TABLE it_profiles WITH KEY profindex = ls_profrole-profindex.


    LOOP AT it_authdet WHERE profname = it_profiles-profname.
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
      READ TABLE gt_sodorgm WITH KEY sysid = it_authdet-sysid
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
              l_role_key
              it_authdet
              lt_varels-von
              ls_profrole-profindex
            CHANGING
              ls_node.
          ENDIF.
        WHEN 'A'."Normal Authorization
          PERFORM add_auth_node
            TABLES
              et_node
              et_item
            USING
              l_role_key
              it_authdet
            CHANGING
              ls_node.
        WHEN 'O'. "Organizational Element
          lt_orgs      = it_authdet.
          lt_orgs-object = ''.
          lt_orgs-von    = ''.
          lt_orgs-bis    = ''.
          lt_orgs-field  = ''.
          lt_orgs-auth   = ''.
          lt_orgs-tcode  = ''.
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
                l_role_key
                it_authdet
                lt_orgs-abb
                ls_profrole-profindex
              CHANGING
                ls_node.
            ENDIF.
          ENDIF.
      ENDCASE.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " add_role_nodes
*---------------------------------------------------------------------*
*       FORM add_profile_nodes                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_AUTHDET                                                    *
*  -->  IT_PROFILES                                                   *
*  -->  ET_NODE                                                       *
*  -->  ET_ITEM                                                       *
*  -->  ET_EXPAND                                                     *
*  -->  I_PARENT                                                      *
*  -->  I_PROFILEINDEX                                                *
*  -->  IT_COMPROLE                                                   *
*  -->  IT_PROFROLE                                                   *
*  -->  IT_ROLES                                                      *
*---------------------------------------------------------------------*
FORM add_profile_nodes
  TABLES   it_authdet       STRUCTURE  /psyng/seres_authdetail
           it_profiles      STRUCTURE  /psyng/swresipro
           et_node          STRUCTURE  treev_node
           et_item          STRUCTURE  mtreeitm
           it_abb           STRUCTURE  /psyng/swresiabb
  USING    et_expand        TYPE       treev_nks
           i_parent         TYPE       tv_nodekey
           i_profileindex   TYPE       /psyng/seres_profindex
           it_comprole      TYPE       ttyp_comprol
           it_profrole      TYPE       ttyp_profile
           it_roles         TYPE       ttyp_roles.

  DATA : ls_comprole LIKE LINE OF it_comprole,
         ls_profrole LIKE LINE OF it_profrole,
         ls_profile  LIKE LINE OF it_profiles,
         ls_node     TYPE treev_node,
         ls_item     TYPE mtreeitm,
         l_prof_key  TYPE tv_nodekey,
         l_text      TYPE string,
         lt_varels   TYPE TABLE OF /psyng/seres_authdetail
                            WITH HEADER LINE,
         lt_orgs     TYPE TABLE OF /psyng/seres_authdetail
                            WITH HEADER LINE,
         l_prof_text TYPE usr11-ptext,
         l_type      TYPE string,
         ls_sodorgm  TYPE /psyng/swsodorgm.

  READ TABLE it_profiles WITH  KEY profindex = i_profileindex
  INTO ls_profile.
  ADD 1 TO g_auth_id.


*--profile text
  SELECT SINGLE ptext FROM usr11 INTO (l_prof_text) WHERE
      langu = sy-langu
  AND profn = ls_profile-profname.

  IF p_rolpro = 'X'.
    leaf_node et_node et_item i_parent 'PR' g_auth_id
               ls_profile-profname l_prof_text '@MD@' ''.
  ELSE.
    child_node et_node et_item i_parent 'PR' g_auth_id
               ls_profile-profname l_prof_text '@MD@' ''.
  ENDIF.

  l_prof_key = ls_node-node_key.

*---Om Comment 23.09.2019
  CHECK p_orgvar = 'X'.
  LOOP AT it_authdet WHERE profname = it_profiles-profname.
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
    READ TABLE gt_sodorgm WITH KEY sysid = it_authdet-sysid
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
        READ TABLE lt_varels WITH KEY table_line = lt_varels.
        IF sy-subrc <> 0.
          COLLECT lt_varels.
          PERFORM add_varel_node
           TABLES
            et_node
            et_item
          USING
            l_prof_key
            it_authdet
            lt_varels-von
            i_profileindex
          CHANGING
            ls_node.
        ENDIF.
      WHEN 'A'."Normal Authorization
        PERFORM add_auth_node
          TABLES
            et_node
            et_item
          USING
            l_prof_key
            it_authdet
          CHANGING
            ls_node.
      WHEN 'O'. "Organizational Element
        lt_orgs       = it_authdet.
        lt_orgs-object  = ''.
        lt_orgs-von     = ''.
        lt_orgs-bis     = ''.
        lt_orgs-field   = ''.
        lt_orgs-auth    = ''.
        lt_orgs-tcode   = ''.
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
              l_prof_key
              it_authdet
              lt_orgs-abb
              i_profileindex
            CHANGING
              ls_node.
          ENDIF.
        ENDIF.
    ENDCASE.
  ENDLOOP.
ENDFORM.                    " add_profile_nodes

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

  CLEAR: gf_fnd_bname, gf_fnd_conid, gf_fnd_funid.
ENDMODULE.
*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0101 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  DATA: ls_user     LIKE LINE OF gt_user,
        ls_item     LIKE LINE OF gt_item,
        l_tabix     TYPE sy-tabix,
        ls_swrescon TYPE /psyng/swrescon.

  CASE sy-ucomm.
    WHEN 'CANCEL'.
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
        lr_bname FOR usr02-bname.

  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'SEARCH'.
*      IF g_fnd_ucomm = 'FINDNEXT'.
*        PERFORM find_node USING g_start_pos.
*      ELSE.
      PERFORM find_node USING 0 0.
*      ENDIF.
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
        ls_usernode      TYPE treev_node,
        ls_rolnode       TYPE treev_node,
        lt_users_alv     TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
        ls_items         TYPE mtreeitm,
        lt_funprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
*--Added by : UMITTAL C1342 D67K931619 14/05/2024
        lt_fprprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
        lt_usrprof       TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_usrprof2      TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_profrole      TYPE SORTED TABLE OF /psyng/swresprol
                         WITH HEADER LINE WITH UNIQUE KEY profindex,
        lt_roles         TYPE SORTED TABLE OF /psyng/swresirol
                         WITH HEADER LINE WITH UNIQUE KEY roleindex,
        lt_comprole      TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        lt_comprole_part TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        ls_comp          LIKE LINE OF lt_comprole,
        ls_role          TYPE /psyng/swresirol,
        ls_comprole      TYPE /psyng/swresirol,
       lt_profiles      TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
       lt_authdet       TYPE TABLE OF /psyng/seres_authdetail
                        WITH HEADER LINE,
       lt_authdet_all   TYPE TABLE OF /psyng/seres_authdetail
                    WITH HEADER LINE,
       ls_function      TYPE /psyng/swresifun,
       l_funindex       TYPE /psyng/seres_funindex,
       l_userinndex     TYPE /psyng/seres_userindex,
       lt_funprofile    TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
       lt_confun        TYPE TABLE OF /psyng/swrescfun WITH HEADER LINE,
       lt_function      TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
       lt_usercon       TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
       l_continue       TYPE flag,
       l_user_count     TYPE i,
*       BOC by GSINGH for C0765
*        lf_ask_export    TYPE flag VALUE 'X',
*        lf_ask_export    TYPE flag,
*       EOC by GSINGH
       lf_use_alv       TYPE flag,
       l_max_alv_s      TYPE string,
       l_max_alv        TYPE i,
       lf_cancel_export TYPE flag,
*--Added by : UMITTAL C1342 D67K931619 14/05/2024
       l_inst         TYPE /psyng/bapiflagx,
       l_se_vrsion    TYPE /psyng/prog_vrsio,
       l_new_se_vrs   TYPE flag,
       lv_tabix       TYPE sy-tabix,
       ls_authdet     TYPE /psyng/seres_authdetail.




  FIELD-SYMBOLS: <swresusr> TYPE /psyng/swresusr,
                 <confun>   TYPE /psyng/swrescfun.
  RANGES: lr_userindex FOR /psyng/swrescon-userindex,
          lr_userindex_all FOR /psyng/swrescon-userindex,
          lr_userindex_part FOR /psyng/swrescon-userindex,
          lr_funindex  FOR /psyng/swrescfun-funindex,
          lr_profindex FOR /psyng/swresupr-profileindex,
          lr_sys       FOR /psyng/swresupr-sys.

**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
  CLEAR l_new_se_vrs.
  SELECT SINGLE se_version INTO l_se_vrsion
    FROM /psyng/swreshdr
    WHERE aid = g_aid.
  IF l_se_vrsion > '4.7PS2C' OR
     l_se_vrsion CA 'Q' .

    l_new_se_vrs = 'X'.
  ELSE.
    CLEAR l_new_se_vrs.
  ENDIF.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
  se_config_param 'SOD_EXPORT_ALV_LIMIT' l_max_alv_s.
  IF l_max_alv_s CO '0123456789'.
*Code Changes for B17121 by GSINGH - Hnadling Short Dump due to large
*number value in Config Parameter
    IF l_max_alv_s > '1000000'.
      MESSAGE
     'Parameter SOD_EXPORT_ALV_LIMIT current value cannot be greater ' &
     'than default value'(e11)
     TYPE 'E'.
    ELSE.
      l_max_alv = l_max_alv_s.
    ENDIF.
*   End of changes for B17121
  ELSE.
    l_max_alv = 1000000.
  ENDIF.

  REFRESH: gt_output_alv, lt_users_alv.
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
  lt_users_alv[] = gt_user[].
  CASE g_node_key(1).
    WHEN 'G'.
*Parent node (1st) of tree
      READ TABLE gt_item INTO ls_items
             WITH KEY node_key  = g_node_key
                      item_name = 'GROUPNAME'.
      CASE 'X'.
        WHEN p_gclass.
*--Group by usergroup
          DELETE lt_users_alv WHERE class <> ls_items-text.
        WHEN p_gkostl.
*--Group by Cost Center
          DELETE lt_users_alv WHERE kostl <> ls_items-text.
        WHEN p_gcomp.
*--Group by Company
          DELETE lt_users_alv WHERE company <> ls_items-text.
        WHEN p_gdep.
*--Group By Department
          DELETE lt_users_alv WHERE department <> ls_items-text.
      ENDCASE.

    WHEN 'B'.
*Bname node
      READ TABLE gt_item INTO ls_items
           WITH KEY node_key  = g_node_key
                    item_name = 'DATA'.
      DELETE lt_users_alv WHERE bname <> ls_items-text.
    WHEN 'C'.
*Conflict node
      READ TABLE gt_node INTO ls_connode
                    WITH KEY node_key = g_node_key.
      READ TABLE gt_item INTO ls_items
       WITH KEY node_key  = ls_connode-relatkey
                item_name = 'DATA'.
      IF sy-subrc = 0.
        DELETE lt_users_alv WHERE bname <> ls_items-text.
      ENDIF.
    WHEN 'F'.
*Function node
*--Get function index value
      READ TABLE gt_item INTO ls_fun
           WITH KEY node_key  = g_node_key
                    item_name = 'FUNINDEX'.
*--Get the userid, 2 nodes up
      READ TABLE gt_node
      INTO ls_funnode
      WITH KEY node_key = g_node_key.

      READ TABLE gt_node
      INTO ls_connode
      WITH KEY node_key = ls_funnode-relatkey.

      READ TABLE gt_node
      INTO ls_usernode
      WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
      READ TABLE gt_item INTO ls_items
         WITH KEY node_key  = ls_usernode-node_key
                  item_name = 'USERINDEX'.
      DELETE lt_users_alv WHERE userindex <> ls_items-text.
  ENDCASE.

*---Warning if nr of users > 50
  DESCRIBE TABLE lt_users_alv LINES l_user_count.
  l_continue = 'X'.
  IF l_user_count > 50.
    CLEAR l_continue.
    PERFORM advise_syswide_analysis
    CHANGING  l_continue.
  ENDIF.

  IF l_continue = 'X'.
*---collect user index
    LOOP AT lt_users_alv ASSIGNING <swresusr>.
      lr_userindex-sign = 'I'.
      lr_userindex-option = 'EQ'.
      lr_userindex-low = <swresusr>-userindex.
      APPEND lr_userindex.
    ENDLOOP.
*-- get user conflict
    IF NOT lr_userindex[] IS INITIAL.
      lr_userindex_all[] = lr_userindex[].
      WHILE NOT lr_userindex[] IS INITIAL.
        APPEND LINES OF lr_userindex FROM 1 TO 5000
        TO lr_userindex_part.
        DELETE lr_userindex FROM 1 TO 5000.
        IF p_mitcon EQ 'X'.
          SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                     WHERE aid       =  p_aid AND
                           userindex IN lr_userindex_part AND
                           conindex  IN gr_conflicts.
        ELSE.
          SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                     WHERE aid       =  p_aid AND
                           userindex IN lr_userindex_part AND
                           conindex  IN gr_conflicts AND
                           mitigated = p_mitcon.
        ENDIF.
        REFRESH : lr_userindex_part[].
      ENDWHILE.
      lr_userindex[] = lr_userindex_all[].
    ENDIF.
    FREE : lr_userindex_part, lr_userindex_all.

*---if conflict node selected, delete others
    IF g_node_key(1) = 'C'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'CONINDEX'.
      IF sy-subrc = 0.
        DELETE lt_usercon WHERE conindex <> ls_fun-text.
      ENDIF.
    ENDIF.

*--User's Conflict functions
    IF NOT lt_usercon[] IS INITIAL.
      SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
      FOR ALL ENTRIES IN lt_usercon
               WHERE aid       =  p_aid AND
                     conindex  = lt_usercon-conindex.
      IF NOT lt_confun[] IS INITIAL.
        SELECT  * FROM /psyng/swresifun INTO TABLE lt_function
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
            DELETE lt_usercon WHERE conindex <> ls_fun-text.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

* if role node selected, delete others
    IF g_node_key(1) = 'S'.
      READ TABLE gt_node INTO ls_rolnode
    WITH KEY node_key = g_node_key.
      IF sy-subrc = 0.
        READ TABLE gt_item INTO ls_fun
              WITH KEY
                      node_key  = ls_rolnode-relatkey
                       item_name = 'FUNINDEX'.
        IF sy-subrc = 0.
          DELETE lr_funindex WHERE low <> ls_fun-text.
        ENDIF.
      ENDIF.
    ENDIF.

*--Approach with multiple selects, optimize use of indexes
*--Get all profiles user has
*--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
*BOC:HBHALLA (PN-14658)(Issue-3)(08/08/25)
*Dump while exporting to ALV due to user index in ranges
    IF l_new_se_vrs EQ 'X'.
      IF lr_userindex[] IS NOT INITIAL.
        SELECT * FROM /psyng/swresfpr
            INTO TABLE lt_fprprof
            FOR ALL ENTRIES IN lr_userindex
                WHERE aid    =  p_aid AND
*                    userindex    IN lr_userindex.
                      userindex = lr_userindex-low.
      ENDIF.
    ELSE.
*--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
      IF lr_userindex[] IS NOT INITIAL.
        SELECT * FROM /psyng/swresupr
        INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
            FOR ALL ENTRIES IN lr_userindex
        WHERE aid          = p_aid AND
*            userindex    IN lr_userindex.
                      userindex = lr_userindex-low.
      ENDIF.
    ENDIF. "Added by: UMITTAL C1342 D67K931619 14/05/2024
*EOC:HBHALLA (PN-14658)(Issue-3)(08/08/25)
*--For these profiles,
*  get the ones that relate to the functions we care about
    lr_profindex-sign   = 'I'.
    lr_profindex-option = 'EQ'.
    MOVE-CORRESPONDING lr_profindex TO lr_sys.
    LOOP AT lt_usrprof.
      lr_profindex-low = lt_usrprof-profileindex.
      APPEND lr_profindex.
      lr_sys-low = lt_usrprof-sys.
      APPEND lr_sys.
    ENDLOOP.
    SORT lr_profindex BY low.
    SORT lr_sys BY low.
    DELETE ADJACENT DUPLICATES FROM  lr_profindex COMPARING low.
    DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.

    SELECT * FROM /psyng/swresfpr
    INTO TABLE lt_funprofile
    WHERE
      aid = p_aid AND
      sys IN lr_sys AND
*      funindex IN lr_funindex AND
      profileindex IN lr_profindex.

    IF g_node_key(1) = 'F'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'FUNINDEX'.
      IF sy-subrc = 0.
        DELETE lt_funprofile WHERE funindex <> ls_fun-text.
      ENDIF.
    ENDIF.

    SORT lt_funprofile BY sys profileindex.
    IF l_new_se_vrs IS INITIAL."UMITTAL C1342 D67K931619
      LOOP AT lt_usrprof.
        READ TABLE lt_funprofile WITH KEY
          sys           = lt_usrprof-sys
          profileindex  = lt_usrprof-profileindex
        BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          APPEND lt_usrprof TO lt_usrprof2.
        ENDIF.
      ENDLOOP.
      lt_usrprof[] =   lt_usrprof2[].
      FREE lt_usrprof2[].
    ENDIF.  "UMITTAL  C1342 D67K931619 14/05/2024

**--Get the roles
**--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024

    IF l_new_se_vrs EQ 'X'. "Get indexes from FPR table
      IF NOT lt_fprprof[] IS INITIAL.
        SELECT * FROM /psyng/swresipro
          INTO TABLE lt_profiles
           FOR ALL ENTRIES IN lt_fprprof
           WHERE aid       = p_aid AND
*              sys       = lt_usrprof-sys and
                 profindex = lt_fprprof-profileindex.

        SELECT * FROM /psyng/swresprol
          INTO TABLE lt_profrole
          FOR ALL ENTRIES IN lt_fprprof
          WHERE aid       = p_aid AND
                sys       = lt_fprprof-sys AND
                profindex = lt_fprprof-profileindex.

        IF NOT lt_profrole[] IS INITIAL.
          SELECT * FROM /psyng/swresirol
            INTO TABLE lt_roles
            FOR ALL ENTRIES IN lt_profrole
            WHERE aid = p_aid AND
                  roleindex = lt_profrole-roleindex.
          IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
*BOC:HBHALLA (PN-14658) (Issue3) (08/08/25)
            IF NOT lr_userindex[] IS INITIAL.
              lr_userindex_all[] = lr_userindex[].
              WHILE NOT lr_userindex[] IS INITIAL.
                APPEND LINES OF lr_userindex FROM 1 TO 5000
                TO lr_userindex_part.
                DELETE lr_userindex FROM 1 TO 5000.
                SELECT * FROM /psyng/swresucom
*              INTO TABLE lt_comprole
                  INTO TABLE lt_comprole_part
                  FOR ALL ENTRIES IN lt_roles
                  WHERE aid = p_aid AND
*                    userindex IN lr_userindex AND
                        userindex IN lr_userindex_part AND
                        roleindex = lt_roles-roleindex.

                LOOP AT lt_comprole_part.
                  INSERT lt_comprole_part INTO TABLE lt_comprole.
                ENDLOOP.

                REFRESH : lr_userindex_part[],lt_comprole_part[].
              ENDWHILE.
              lr_userindex[] = lr_userindex_all[].
            ENDIF.
            FREE : lr_userindex_part, lr_userindex_all.
*EOC:HBHALLA (PN-14658) (Issue3) (08/08/25)
            IF lt_comprole[] IS NOT INITIAL.
              DELETE lt_comprole[] WHERE compindex IS INITIAL
                                      OR compindex EQ 0.
            ENDIF.
            IF NOT lt_comprole[] IS INITIAL.
              SELECT * FROM /psyng/swresirol
              APPENDING TABLE lt_roles
              FOR ALL ENTRIES IN lt_comprole
                WHERE aid = p_aid AND
                      roleindex = lt_comprole-compindex.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.

    ELSE.
**--End of insert : UMITTAL C1342 D67K931619 14/05/2024
      IF NOT lt_usrprof[] IS INITIAL.

        SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
          FOR ALL ENTRIES IN
            lt_usrprof
        WHERE aid       = p_aid AND
*              sys       = lt_usrprof-sys and
              profindex = lt_usrprof-profileindex.

        SELECT * FROM /psyng/swresprol
        INTO TABLE lt_profrole
        FOR ALL ENTRIES IN lt_usrprof
        WHERE aid       = p_aid AND
              sys       = lt_usrprof-sys AND
              profindex = lt_usrprof-profileindex.
        IF NOT lt_profrole[] IS INITIAL.
          SELECT * FROM /psyng/swresirol
          INTO TABLE lt_roles
          FOR ALL ENTRIES IN lt_profrole
            WHERE aid = p_aid AND
                  roleindex = lt_profrole-roleindex.
          IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
            SELECT * FROM /psyng/swresucom
            INTO TABLE lt_comprole
            FOR ALL ENTRIES IN lt_roles WHERE
              aid = p_aid AND
*            userindex = l_userinndex AND
              userindex IN lr_userindex AND
              roleindex = lt_roles-roleindex.
* BOC by RGUPTA on 25.07.22 for #22227
            IF lt_comprole[] IS NOT INITIAL.
              DELETE lt_comprole[] WHERE compindex IS INITIAL
                                      OR compindex EQ 0.
            ENDIF.
* EOC by RGUPTA on 25.07.22 for #22227
            IF NOT lt_comprole[] IS INITIAL.
              SELECT * FROM /psyng/swresirol
              APPENDING TABLE lt_roles
              FOR ALL ENTRIES IN lt_comprole
                WHERE aid = p_aid AND
                      roleindex = lt_comprole-compindex.
            ENDIF.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF. "Added by : UMITTAL C1342 D67K931619 14/05/2024
*---Macro to get only uniq record when org/var option not selected
    DEFINE export_only_uniq_value.
      check p_orgvar <> 'X'.

      if p_fun = 'X'.
       read table gt_output_alv with key  bname = &1 "lt_users_alv-bname
                                            conid = &2"gt_conflict-conid
                                          funid = &3."lt_function-funid.
        if sy-subrc = 0.
          clear gt_output_alv.
        else.
          add 1 to g_alv_count.
          append gt_output_alv.
        endif.

      endif.

      if p_rolpro  = 'X'.
       read table gt_output_alv with key  bname = &1 "lt_users_alv-bname
                                            conid = &2"gt_conflict-conid
                                           funid = &3"lt_function-funid.
                                              agr_name = &4
                                              profname = &5.
        if sy-subrc = 0.
          clear gt_output_alv.
        else.
          add 1 to g_alv_count.
          append gt_output_alv.
          clear gt_output_alv. "Changes by RGUPTA on 30th Nov,2021
        endif.
      endif.
    END-OF-DEFINITION.


    SORT lt_usrprof BY sys userindex profileindex.
*Added by : UMITTAL C1342 D67K931619 14/05/2024
    SORT lt_fprprof BY sys userindex profileindex.
    SORT lt_usercon BY userindex conindex.
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
    IF l_new_se_vrs EQ 'X'.
      LOOP AT lt_confun.
        CLEAR gt_output_alv.
*--get function index
        LOOP AT lt_fprprof WHERE funindex = lt_confun-funindex.
*--"get user and conflict index
          LOOP AT lt_usercon WHERE userindex = lt_fprprof-userindex
          AND
                                   conindex  = lt_confun-conindex .
            IF lt_usercon-origin IS NOT INITIAL.
              IF p_local = 'X' AND p_remote IS INITIAL
               AND p_cross IS INITIAL
               AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
                  OR lt_usercon-origin = 5 ).
                CONTINUE.
              ELSEIF p_local = 'X' AND p_remote = 'X'
               AND p_cross IS INITIAL
               AND lt_usercon-origin = 3.
                CONTINUE.
              ELSEIF p_local = 'X' AND p_remote IS INITIAL
               AND p_cross = 'X'
               AND lt_usercon-origin = 2.
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote = 'X'
               AND p_cross IS INITIAL
               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
                  OR lt_usercon-origin = 4 ).
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote = 'X'
               AND p_cross = 'X'
               AND lt_usercon-origin = 1.
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
               AND p_cross = 'X'
               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
                CONTINUE.
              ENDIF.
            ENDIF.
*     userid
            READ TABLE lt_users_alv WITH KEY userindex =
            lt_usercon-userindex.
            IF sy-subrc = 0.
              gt_output_alv-bname   = lt_users_alv-bname.
*BOC:HBHALLA (PN-15675) (08/10/25)
              gt_output_alv-deprtmnt   = lt_users_alv-department.
*EOC:HBHALLA (PN-15675) (08/10/25)
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
              gt_output_alv-class   = lt_users_alv-class.
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
              gt_output_alv-confnum = lt_users_alv-nr_conflicts.
              gt_output_alv-mitinum = lt_users_alv-nr_mitigated.
            ENDIF.
*     Conflicts
            READ TABLE gt_conflict WITH KEY conindex =
            lt_confun-conindex.
            IF sy-subrc = 0.
              gt_output_alv-conid     = gt_conflict-conid.
              gt_output_alv-mitigated = lt_usercon-mitigated.
              CASE lt_usercon-origin.
                WHEN 1.
                  gt_output_alv-origin = 'Local'(173).
                WHEN 2.
                  gt_output_alv-origin = 'Remote'(174).
                WHEN 3.
                  gt_output_alv-origin = 'Cross'(175).
                WHEN 4.
                  gt_output_alv-origin = 'Local&Cross'(202).
                WHEN 5.
                  gt_output_alv-origin = 'Remote&Cross'(203).
                WHEN 6.
                  gt_output_alv-origin = 'L&R&C'(204).
              ENDCASE.
            ENDIF.
*     function
            READ TABLE lt_function WITH KEY funindex =
            lt_confun-funindex.
            IF sy-subrc = 0.
              gt_output_alv-funid = lt_function-funid.
            ENDIF.

            IF p_fun <> 'X'.
*     profiles
              READ TABLE lt_profiles WITH KEY
                            profindex = lt_fprprof-profileindex.
              IF sy-subrc = 0.
                gt_output_alv-profname = lt_profiles-profname.
              ENDIF.

*    * Role
              READ TABLE lt_profrole WITH KEY
                         profindex = lt_fprprof-profileindex.
              IF sy-subrc = 0.
                READ TABLE lt_roles WITH KEY
                  roleindex = lt_profrole-roleindex.
                gt_output_alv-agr_name = lt_roles-agr_name.
*    * Composite Role
                LOOP AT lt_comprole WHERE userindex =
                lt_fprprof-userindex
                                     AND  roleindex =
                                     lt_profrole-roleindex.
                  READ TABLE lt_roles WITH KEY
                               roleindex  = lt_comprole-compindex.
                  IF sy-subrc = 0.
                    gt_output_alv-comp_agr = lt_roles-agr_name.
                    lv_comp_agr  = gt_output_alv-comp_agr.
                  ENDIF.
                  READ TABLE gt_output_alv WITH KEY
                  bname    = lt_users_alv-bname
                  conid    = gt_conflict-conid
                  funid    = lt_function-funid
                  comp_agr = gt_output_alv-comp_agr
                  agr_name = gt_output_alv-agr_name
                  profname = gt_output_alv-profname.
                  IF sy-subrc <> 0.
                    APPEND gt_output_alv.
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
                    CLEAR lv_tabix.
                    lv_tabix = sy-tabix.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
                    ADD 1 TO g_alv_count.
                  ENDIF.
                ENDLOOP.
*  CLEAR: gt_output_alv-comp_agr. "HBHALLA(PN-15751)(12/01/26)
*Clearing comp_agr was creating 2 entries in output table,
*one with comp_agr and another without it.
              ENDIF.
              IF  p_rolpro = 'X'.
                export_only_uniq_value lt_users_alv-bname
                gt_conflict-conid
            lt_function-funid  gt_output_alv-agr_name
            lt_profiles-profname.
              ENDIF.
            ENDIF.

*    --- call macro only if org/var expand o/p option not selected
            IF p_fun = 'X'.
              export_only_uniq_value lt_users_alv-bname
              gt_conflict-conid
                                lt_function-funid  '' ''.
            ENDIF.

*     ---- don't go for detail if expand level not selected org/var
            IF p_orgvar = 'X'.
              REFRESH : lt_authdet.
              CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
                EXPORTING
                  i_aid             = p_aid
                  i_sys             = lt_fprprof-sys
                  i_funindex        = lt_confun-funindex
                  i_profileindex    = lt_fprprof-profileindex
                TABLES
                  et_profiledetails = lt_authdet.

              LOOP AT lt_authdet.
                MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
                ADD 1 TO g_alv_count.
                APPEND gt_output_alv.
                IF g_alv_count > l_max_alv.
*    --The export contains more data than can be handled in
*      the memory of the sap session
*      Download the data in separate files
                  IF lf_ask_export = 'X'.
                    MESSAGE i012.
                  ENDIF.
*The amount of data is too large to export at once and will be split
                  PERFORM export_to_file USING    lf_ask_export
                                         CHANGING lf_cancel_export.
                  IF lf_cancel_export = 'X'.
                    EXIT.
                  ENDIF.
                  CLEAR : lf_ask_export,
                          g_alv_count.
                ENDIF.
**--Begin of Insert : UMITTAL C1342 D67K931619 14/05/2024
                IF NOT lt_comprole[] IS INITIAL.
                  READ TABLE gt_output_alv WITH KEY
                  bname    = lt_users_alv-bname
                  conid    = gt_conflict-conid
                  funid    = lt_function-funid
                  comp_agr = lv_comp_agr
                  agr_name = gt_output_alv-agr_name
                  profname = gt_output_alv-profname.
                  IF sy-subrc EQ 0.
                    READ TABLE lt_authdet INTO ls_authdet WITH KEY
                    funid = gt_output_alv-funid
                    profname = gt_output_alv-profname.
                    IF sy-subrc EQ 0.
                      CLEAR ls_output_alv.
                      ls_output_alv = gt_output_alv.
                      MOVE-CORRESPONDING ls_authdet TO ls_output_alv
                      .
                      IF NOT lv_tabix IS INITIAL.
                        MODIFY gt_output_alv FROM ls_output_alv
                        INDEX lv_tabix .
                      ENDIF.
                    ENDIF.
                  ENDIF.
                ENDIF.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
              ENDLOOP.
              CLEAR gt_output_alv.
            ENDIF.
            FREE : lt_authdet.
            IF lf_cancel_export = 'X'.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF lf_cancel_export = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lf_cancel_export = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.

    ELSE.
**--End of Insert : UMITTAL C1342 D67K931619 14/05/2024
      LOOP AT lt_confun.
        CLEAR gt_output_alv.
        LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
          LOOP AT lt_usercon WHERE conindex = lt_confun-conindex.
* BOC for B16609 for C0633
            IF lt_usercon-origin IS NOT INITIAL.
              IF p_local = 'X' AND p_remote IS INITIAL
               AND p_cross IS INITIAL
               AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
                  OR lt_usercon-origin = 5 ).
                CONTINUE.
              ELSEIF p_local = 'X' AND p_remote = 'X'
               AND p_cross IS INITIAL
               AND lt_usercon-origin = 3.
                CONTINUE.
              ELSEIF p_local = 'X' AND p_remote IS INITIAL
               AND p_cross = 'X'
               AND lt_usercon-origin = 2.
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote = 'X'
               AND p_cross IS INITIAL
               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
                  OR lt_usercon-origin = 4 ).
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote = 'X'
               AND p_cross = 'X'
               AND lt_usercon-origin = 1.
                CONTINUE.
              ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
               AND p_cross = 'X'
               AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
                CONTINUE.
              ENDIF.
            ENDIF.
* EOC for B16609 for C0633
            READ TABLE lt_usrprof WITH KEY
              sys          = lt_funprofile-sys
              userindex    = lt_usercon-userindex
              profileindex = lt_funprofile-profileindex
              BINARY SEARCH.
            CHECK sy-subrc = 0.
* userid
      READ TABLE lt_users_alv WITH KEY userindex = lt_usercon-userindex.
            IF sy-subrc = 0.
              gt_output_alv-bname = lt_users_alv-bname.
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
              gt_output_alv-class   = lt_users_alv-class.
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
              gt_output_alv-confnum = lt_users_alv-nr_conflicts.
              gt_output_alv-mitinum = lt_users_alv-nr_mitigated.
            ENDIF.
* Conflicts
          READ TABLE gt_conflict WITH KEY conindex = lt_confun-conindex.
            IF sy-subrc = 0.
              gt_output_alv-conid = gt_conflict-conid.
              gt_output_alv-mitigated = lt_usercon-mitigated.
* BOC for B16609 for C0633
              CASE lt_usercon-origin.
                WHEN 1.
                  gt_output_alv-origin = 'Local'(173).
                WHEN 2.
                  gt_output_alv-origin = 'Remote'(174).
                WHEN 3.
                  gt_output_alv-origin = 'Cross'(175).
                WHEN 4.
                  gt_output_alv-origin = 'Local&Cross'(202).
                WHEN 5.
                  gt_output_alv-origin = 'Remote&Cross'(203).
                WHEN 6.
                  gt_output_alv-origin = 'L&R&C'(204).
              ENDCASE.
* EOC for B16609 for C0633
            ENDIF.
* function
          READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
            IF sy-subrc = 0.
              gt_output_alv-funid = lt_function-funid.
            ENDIF.

            IF p_fun <> 'X'.
* profiles
              READ TABLE lt_profiles WITH KEY
                            profindex = lt_usrprof-profileindex.
              IF sy-subrc = 0.
                gt_output_alv-profname = lt_profiles-profname.
              ENDIF.

** Role
              READ TABLE lt_profrole WITH KEY
                         profindex = lt_usrprof-profileindex.
              IF sy-subrc = 0.
                READ TABLE lt_roles WITH KEY
                  roleindex = lt_profrole-roleindex.
                gt_output_alv-agr_name = lt_roles-agr_name.
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
              LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
                                 AND  roleindex = lt_profrole-roleindex.
                  READ TABLE lt_roles WITH KEY
               roleindex  = lt_comprole-compindex.
                  IF sy-subrc = 0.
                    gt_output_alv-comp_agr = lt_roles-agr_name.
                  ENDIF.
            READ TABLE gt_output_alv WITH KEY bname = lt_users_alv-bname
                                              conid = gt_conflict-conid
                                              funid = lt_function-funid
                                       comp_agr = gt_output_alv-comp_agr
                                       agr_name = gt_output_alv-agr_name
                                      profname = gt_output_alv-profname.
                  IF sy-subrc <> 0.
                    APPEND gt_output_alv.
                    ADD 1 TO g_alv_count.
                  ENDIF.
                ENDLOOP.
                CLEAR: gt_output_alv-comp_agr.
              ENDIF.
              IF  p_rolpro = 'X'.
             export_only_uniq_value lt_users_alv-bname gt_conflict-conid
         lt_function-funid  gt_output_alv-agr_name lt_profiles-profname.
              ENDIF.
            ENDIF.

*--- call macro only if org/var expand o/p option not selected
            IF p_fun = 'X'.
             export_only_uniq_value lt_users_alv-bname gt_conflict-conid
                               lt_function-funid  '' ''.
            ENDIF.

* ---- don't go for detail if expand level not selected org/var
            IF p_orgvar = 'X'.
              REFRESH : lt_authdet.
              CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
                EXPORTING
                  i_aid             = p_aid
                  i_sys             = lt_usrprof-sys
                  i_funindex        = lt_confun-funindex
                  i_profileindex    = lt_usrprof-profileindex
                TABLES
                  et_profiledetails = lt_authdet.

              LOOP AT lt_authdet.
                MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
                ADD 1 TO g_alv_count.
                APPEND gt_output_alv.
*              clear gt_output_alv. "RGUPTA
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
              CLEAR gt_output_alv. "RGUPTA
            ENDIF.
*          endloop.
            FREE : lt_authdet.
            IF lf_cancel_export = 'X'.
              EXIT.
            ENDIF.
          ENDLOOP.
          IF lf_cancel_export = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lf_cancel_export = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF. " Added by : UMITTAL C1342 D67K931619 14/05/2024
*--free some memory
    FREE :     lt_users_alv,
               lt_funprof ,
               lt_usrprof ,
               lt_usrprof2,
               lt_profrole,
               lt_roles   ,
               lt_comprole,
               lt_profiles ,
               lt_authdet  ,
               lt_authdet_all ,
               lt_funprofile ,
               lt_confun   ,
               lt_function,
               lt_usercon  .

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
                 'BNAME'     'User ID'(c02)        1  12,
                 'CONFNUM'   'Conflicts'(t09)      2  15,
                 'MITINUM'   'Mitigated Conflicts'(t10) 3  15,
                 'CONID'     'Conflict'(c03)       4  12,
                 'MITIGATED' 'Mitigated'(t08)      5  9,
                 'FUNID'     'Function'(c04)       6  12,
                 'COMP_AGR'  'Composite Role'(c15) 7  30,
                 'AGR_NAME'  'Role'(c05)           8  30,
                 'PROFNAME'  'Profile'(c06)        9  15,
                 'SYSID'     'System'(c07)         10  10,
                 'TCODE'     'Tcode'(c08)          11  20,
                 'ABB'       'Abbr.'(c14)          12 10,
                 'AUTH'      'Authorization'(c09)  13 15,
                 'OBJECT'    'Object'(c10)         14 15,
                 'FIELD'     'Field'(c11)          15 15,
                 'VON'       'Value From'(c12)     16 15,
                 'BIS'       'Value To'(c13)       17 15,
                 'ORIGIN'    'Origin'(c16)         18 12, "C0633
*BOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
                 'CLASS'     'User Group'(c17)     19  12,
*EOC UMITTAL - 02/07/2025 - Add Usergroup to ALV o/p
*BOC:HBHALLA (PN-15675) (08/10/25)
                 'DEPRTMNT'  'Department'(t11)     20  40.
*EOC:HBHALLA (PN-15675) (08/10/25)
  IF p_mitcon IS INITIAL.
    hide_column:  'MITIGATED',
                  'MITINUM'.
  ENDIF.
*---sort alv
  sort_alv: "'AID'      '1',
            'BNAME'     '1',
            'CONFNUM'   '2',
            'MITINUM'   '3',
            'CONID'     '4',
            'MITIGATED' '5',
            'FUNID'     '6',
            'COMP_AGR'  '7',
            'AGR_NAME'  '8',
            'PROFNAME'  '9',
            'SYSID'     '10',
            'TCODE'     '11',
            'ABB'       '12',
            'AUTH'      '13',
            'OBJECT'    '14',
            'FIELD'     '15',
            'VON'       '16',
            'ORIGIN'    '17'. "C0633

*-- Hide unwanted node if child node selected
  SPLIT g_node_key AT '_' INTO l_nodetype l_rest.
  CASE l_nodetype.
    WHEN 'C'. " conflict
      lt_fieldcat-no_out = 'X'.
      MODIFY lt_fieldcat TRANSPORTING no_out WHERE fieldname = 'BNAME'
                                                OR fieldname = 'CONFNUM'
                                               OR fieldname = 'MITINUM'.
    WHEN 'F'. "function
      lt_fieldcat-no_out = 'X'.
      MODIFY lt_fieldcat TRANSPORTING no_out WHERE fieldname = 'BNAME'
                                             OR    fieldname = 'CONID'
                                                OR fieldname = 'CONFNUM'
                                                OR fieldname = 'MITINUM'
                                             OR fieldname = 'MITIGATED'.
    WHEN 'S'. " Role
      lt_fieldcat-no_out = 'X'.
     MODIFY lt_fieldcat TRANSPORTING no_out WHERE    fieldname = 'BNAME'
                                                  OR fieldname = 'CONID'
                                                 OR fieldname = 'FUNID'
                                                OR fieldname = 'CONFNUM'
                                                OR fieldname = 'MITINUM'
                                             OR fieldname = 'MITIGATED'.
  ENDCASE.

*---selected o/p expand level
  IF p_fun = 'X'.
    hide_column:  'COMP_AGR',
                  'AGR_NAME',
                  'PROFNAME',
                  'SYSID',
                  'TCODE',
                  'ABB',
                  'AUTH',
                  'OBJECT',
                  'FIELD',
                  'VON',
                  'BIS'.

  ENDIF.

  IF p_rolpro = 'X'.
    hide_column:  'SYSID',
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
*BOC UMITTAL SE206Q1:PN-6663:Enable Save layout btn
*in Stored User Anlsys
      i_save             = 'A'
*EOC UMITTAL SE206Q1:PN-6663:Enable Save layout btn
*in Stored User Anlsys
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
  DATA: ls_swrescon     TYPE /psyng/swrescon,
        ls_node         LIKE LINE OF gt_node,
        ls_connode      LIKE LINE OF gt_node,
        ls_funnode      LIKE LINE OF gt_node,
        l_groupname     TYPE scrpcha72,
        lt_expanded     TYPE HASHED TABLE OF tv_nodekey
                         WITH UNIQUE KEY table_line
                         WITH HEADER LINE,
        lt_users        TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
        lt_usercon      TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
        ls_function     TYPE  /psyng/swresifun,
        lt_confun       TYPE TABLE OF /psyng/swrescfun
                         WITH HEADER LINE,
        lt_conflict     TYPE TABLE OF /psyng/swrescfun
                         WITH HEADER LINE,
        ls_node_con     TYPE treev_node,
        ls_item         TYPE mtreeitm,
        lt_node         TYPE treev_ntab,
        lt_item         TYPE ttree_item,
        l_text          TYPE scrpcha72,
        l_conindex      TYPE scrpcha72,
        l_funindex      TYPE scrpcha72,
        l_tabix         TYPE i,
        lt_match_users  TYPE TABLE OF /psyng/swresusr
                        WITH HEADER LINE,
        l_start_con_pos TYPE i,
        lf_found        TYPE flag.

  l_start_con_pos = i_start_con_pos.
  ADD 1 TO l_start_con_pos.
  CLEAR: ls_user.
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

  IF gr_fnd_bname = 'X'.

    READ TABLE gt_user INTO ls_user  WITH KEY
          bname = gf_fnd_bname.

    IF sy-subrc = 0.
      CASE 'X'.
        WHEN p_gclass.
*      --Group by usergroup
          l_groupname =  ls_user-class.
        WHEN p_gkostl.
*      --Group by Cost Center
          l_groupname =  ls_user-kostl.
        WHEN p_gcomp.
*      --Group by Company
          l_groupname =  ls_user-company.
        WHEN p_gdep.
*      --Group By Department
          l_groupname =  ls_user-department.
      ENDCASE.

*  expand upto 1 level to load tree

      READ TABLE gt_item INTO ls_item
                  WITH KEY item_name = 'GROUPNAME'
                           text      = l_groupname.
      IF sy-subrc EQ 0.
        READ TABLE lt_expanded WITH TABLE KEY
                   table_line =  ls_item-node_key.
        IF sy-subrc <> 0.
*---group node is not expanded yet
          PERFORM expand_group USING ls_item-node_key.
          lt_expanded = ls_item-node_key.
          INSERT TABLE lt_expanded.
        ENDIF.
      ENDIF.
      l_text = ls_user-userindex.
      CONDENSE l_text.
      READ TABLE gt_item INTO ls_item
         WITH KEY  item_name = 'USERINDEX'
                   text      = l_text.

      IF sy-subrc = 0.
        PERFORM expand_bname   USING ls_item-node_key.
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching User found'(x05).
    ENDIF.

  ELSEIF gr_fnd_conid = 'X'.
    READ TABLE gt_conflict WITH KEY conid = gf_fnd_conid.
    IF sy-subrc = 0.
      l_conindex = gt_conflict-conindex.
      IF p_mitcon EQ 'X'.
        SELECT  * FROM /psyng/swrescon INTO TABLE lt_usercon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid.
      ELSE.
        SELECT  * FROM /psyng/swrescon INTO TABLE lt_usercon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid
              AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_usercon[] IS INITIAL.
*---- collect all users which having search conflict
        lt_users[] = lt_usercon[].
        SORT lt_users BY userindex.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING userindex.
        PERFORM get_matching_users
          TABLES
            lt_users
            lt_match_users.
        LOOP AT lt_match_users FROM i_start_pos.

          l_tabix = sy-tabix.
          IF i_start_pos <> 0.
            CHECK l_tabix > i_start_pos.
          ENDIF.
          g_start_pos = l_tabix.

          CASE 'X'.
            WHEN p_gclass.
*      --Group by usergroup
              l_groupname =  lt_match_users-class.
            WHEN p_gkostl.
*      --Group by Cost Center
              l_groupname =  lt_match_users-kostl.
            WHEN p_gcomp.
*      --Group by Company
              l_groupname =  lt_match_users-company.
            WHEN p_gdep.
*      --Group By Department
              l_groupname =  lt_match_users-department.
          ENDCASE.

*--Expand the group if not expanded yet
          READ TABLE gt_item INTO ls_item
            WITH KEY item_name = 'GROUPNAME'
                     text      = l_groupname.
          IF sy-subrc EQ 0.
            READ TABLE lt_expanded WITH TABLE KEY
                       table_line =  ls_item-node_key.
            IF sy-subrc <> 0.
*---group node is not expanded yet
              PERFORM expand_group USING ls_item-node_key.
              lt_expanded = ls_item-node_key.
              INSERT TABLE lt_expanded.
            ENDIF.
          ENDIF.

          l_text = lt_match_users-userindex.
          CONDENSE l_text.
          READ TABLE gt_item INTO ls_item
             WITH KEY  item_name = 'USERINDEX'
                       text      = l_text.

          IF sy-subrc = 0.
            PERFORM expand_bname   USING ls_item-node_key.
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
                PERFORM expand_usercon USING ls_item-node_key.
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
    SELECT * FROM /psyng/swrescfun INTO TABLE lt_confun WHERE
      aid = p_aid AND funindex = ls_function-funindex.
    l_funindex = ls_function-funindex.
    lt_conflict[] = lt_confun[].
    SORT lt_conflict BY conindex.
    DELETE ADJACENT DUPLICATES FROM lt_conflict COMPARING conindex.
*--Get all users that have this conflict
    IF NOT lt_confun[] IS INITIAL.
      IF p_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex.
      ELSE.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex
                AND mitigated = p_mitcon.
      ENDIF.
*--Get all the orgs that contain these users
      lt_users[] = lt_usercon[].
      SORT lt_users BY userindex.
      DELETE ADJACENT DUPLICATES FROM lt_users COMPARING userindex.

      PERFORM get_matching_users
        TABLES
          lt_users
          lt_match_users.

      CASE 'X'.
        WHEN p_gclass.
*--Group by usergroup
          SORT lt_match_users BY class bname.
        WHEN p_gkostl.
*--Group by Cost Center
          SORT lt_match_users BY kostl bname.
        WHEN p_gcomp.
*--Group by Company
          SORT lt_match_users BY company bname.
        WHEN p_gdep.
*--Group By Department
          SORT lt_match_users BY department bname.
      ENDCASE.
*      if i_start_pos > 1.
      LOOP AT lt_match_users FROM i_start_pos.
        g_start_pos = sy-tabix.

        CASE 'X'.
          WHEN p_gclass.
*      --Group by usergroup
            l_groupname =  lt_match_users-class.
          WHEN p_gkostl.
*      --Group by Cost Center
            l_groupname =  lt_match_users-kostl.
          WHEN p_gcomp.
*      --Group by Company
            l_groupname =  lt_match_users-company.
          WHEN p_gdep.
*      --Group By Department
            l_groupname =  lt_match_users-department.
        ENDCASE.

*--Expand the group if not expanded yet
        READ TABLE gt_item INTO ls_item
          WITH KEY item_name = 'GROUPNAME'
                   text      = l_groupname.
        IF sy-subrc EQ 0.
          READ TABLE lt_expanded WITH TABLE KEY
            table_line =  ls_item-node_key.
          IF sy-subrc <> 0.
*     group node is not expanded yet
            PERFORM expand_group USING ls_item-node_key.
            lt_expanded = ls_item-node_key.
            INSERT TABLE lt_expanded.
          ENDIF.
        ENDIF.
*--Expand all the user nodes
        l_text = lt_match_users-userindex.
        CONDENSE l_text.
        READ TABLE gt_item INTO ls_item
           WITH KEY  item_name = 'USERINDEX'
                     text      = l_text.
        IF sy-subrc = 0.
          PERFORM expand_bname   USING ls_item-node_key.
          LOOP AT lt_confun FROM l_start_con_pos.
            g_start_con_pos = sy-tabix.
            READ TABLE lt_usercon WITH KEY
              userindex = lt_match_users-userindex
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
                  PERFORM expand_usercon USING ls_item-node_key.
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
  DATA : ls_bname       TYPE mtreeitm,
         lt_usercon     TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
         lt_users       TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
         ls_node        TYPE treev_node,
         ls_node_con    TYPE treev_node,
         ls_item        TYPE mtreeitm,
         lt_node        TYPE treev_ntab,
         lt_item        TYPE ttree_item,
         l_cdescription TYPE /psyng/rskdsc,
         i_node_key     TYPE tv_nodekey,
         ls_function    TYPE  /psyng/swresifun,
         lt_confun      TYPE TABLE OF /psyng/swrescfun
                        WITH HEADER LINE,
         lt_conflict    TYPE TABLE OF /psyng/swrescfun
                        WITH HEADER LINE,
         lt_expanded    TYPE HASHED TABLE OF tv_nodekey
                        WITH UNIQUE KEY table_line
                        WITH HEADER LINE,
         l_text         TYPE scrpcha72,
         l_groupname    TYPE scrpcha72.

  IF NOT gf_exp_bname IS INITIAL OR NOT gf_exp_conid IS INITIAL
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


  IF gr_exp_bname = 'X'.
    READ TABLE gt_user INTO ls_user  WITH KEY
        bname = gf_exp_bname.

    IF sy-subrc = 0.
      CASE 'X'.
        WHEN p_gclass.
*--Group by usergroup
          READ TABLE gt_item INTO ls_item
          WITH KEY text = ls_user-class.
        WHEN p_gkostl.
*--Group by Cost Center
          READ TABLE gt_item INTO ls_item
          WITH KEY text = ls_user-kostl.
        WHEN p_gcomp.
*--Group by Company
          READ TABLE gt_item INTO ls_item
          WITH KEY text = ls_user-company.
        WHEN p_gdep.
*--Group By Department
          READ TABLE gt_item INTO ls_item
          WITH KEY text = ls_user-department.
      ENDCASE.
*  expand upto 1 level to load tree
      IF NOT ls_item-node_key IS INITIAL." no grouping
        PERFORM expand_group   USING ls_item-node_key.
      ENDIF.
      READ TABLE gt_item INTO ls_item WITH KEY
                text = ls_user-bname.

*   expand user
      PERFORM expand_bname   USING ls_item-node_key.
*--all conflict assigned to user
      IF p_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
            WHERE aid = p_aid AND userindex = ls_user-userindex
              AND conindex IN gr_conflicts.
      ELSE.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
            WHERE aid = p_aid AND userindex = ls_user-userindex
              AND conindex IN gr_conflicts AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_usercon[] IS INITIAL.
        LOOP AT lt_usercon.
          l_text = lt_usercon-conindex.
          CONDENSE l_text.
          READ TABLE gt_item INTO ls_item
                           WITH KEY  item_name = 'CONINDEX'
                                     text      = l_text.

          PERFORM expand_usercon USING ls_item-node_key.
        ENDLOOP.
        MESSAGE s002 WITH 'Nodes expanded'(x09).
      ELSE.
        MESSAGE s002 WITH 'User doesn’t have any conflict'(x15).
      ENDIF.
    ELSE.
      MESSAGE s002 WITH 'No matching User found'(x05).
    ENDIF.
  ENDIF.

  IF gr_exp_conid = 'X'.
    READ TABLE gt_conflict WITH KEY conid = gf_exp_conid.
    IF sy-subrc = 0.
      IF p_mitcon EQ 'X'.
        SELECT  * FROM /psyng/swrescon INTO TABLE lt_usercon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid.
      ELSE.
        SELECT  * FROM /psyng/swrescon INTO TABLE lt_usercon WHERE
            conindex = gt_conflict-conindex
              AND aid = p_aid AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_usercon[] IS INITIAL.
*---- collect all users
        lt_users[] = lt_usercon[].
        SORT lt_users BY userindex.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING userindex.
        LOOP AT gt_user.
          READ TABLE lt_users WITH KEY userindex = gt_user-userindex
            BINARY SEARCH.
          IF sy-subrc = 0.
            CASE 'X'.
              WHEN p_gclass.
*      --Group by usergroup
                l_groupname =  gt_user-class.
              WHEN p_gkostl.
*      --Group by Cost Center
                l_groupname =  gt_user-kostl.
              WHEN p_gcomp.
*      --Group by Company
                l_groupname =  gt_user-company.
              WHEN p_gdep.
*      --Group By Department
                l_groupname =  gt_user-department.
            ENDCASE.

*--Expand the group if not expanded yet
            IF NOT l_groupname IS INITIAL."no grouping
              READ TABLE gt_item INTO ls_item
                WITH KEY item_name = 'GROUPNAME'
                         text      = l_groupname.

              READ TABLE lt_expanded WITH TABLE KEY
                         table_line =  ls_item-node_key.
              IF sy-subrc <> 0.
*       group node is not expanded yet
                PERFORM expand_group USING ls_item-node_key.
                lt_expanded = ls_item-node_key.
                INSERT TABLE lt_expanded.
              ENDIF.
            ENDIF.
            l_text = lt_users-userindex.
            CONDENSE l_text.
            READ TABLE gt_item INTO ls_item
               WITH KEY  item_name = 'USERINDEX'
                         text      = l_text.

            IF sy-subrc = 0.
              PERFORM expand_bname   USING ls_item-node_key.
*--Expand all the conflict nodes
              LOOP AT gt_node INTO ls_node_con
               WHERE relatkey = ls_item-node_key.
                LOOP AT lt_usercon WHERE userindex = lt_users-userindex.
*--Get child node key?
                  l_text = lt_usercon-conindex.
                  CONDENSE l_text.
                  READ TABLE gt_item INTO ls_item
                     WITH KEY  node_key  = ls_node_con-node_key
                               item_name = 'CONINDEX'
                               text      = l_text.
                  IF sy-subrc = 0.
                    PERFORM expand_usercon USING ls_item-node_key.
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
    SELECT * FROM /psyng/swrescfun INTO TABLE lt_confun WHERE
      aid = p_aid AND conindex IN gr_conflicts
      AND funindex = ls_function-funindex.
    lt_conflict[] = lt_confun[].
    SORT lt_conflict BY conindex.
    DELETE ADJACENT DUPLICATES FROM lt_conflict COMPARING conindex.
*--Get all users that have this conflict
    IF NOT lt_confun[] IS INITIAL.
      IF p_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex.
      ELSE.
        SELECT * FROM /psyng/swrescon INTO TABLE lt_usercon
          FOR ALL ENTRIES IN lt_confun
          WHERE aid = p_aid AND conindex = lt_confun-conindex
            AND mitigated = p_mitcon.
      ENDIF.
      IF NOT lt_usercon[] IS INITIAL.
*--Get all the orgs that contain these users
        lt_users[] = lt_usercon[].
        SORT lt_users BY userindex.
        DELETE ADJACENT DUPLICATES FROM lt_users COMPARING userindex.
        LOOP AT gt_user.
          READ TABLE lt_users WITH KEY userindex = gt_user-userindex
          BINARY SEARCH.
          IF sy-subrc = 0.
            CASE 'X'.
              WHEN p_gclass.
*      --Group by usergroup
                l_groupname =  gt_user-class.
              WHEN p_gkostl.
*      --Group by Cost Center
                l_groupname =  gt_user-kostl.
              WHEN p_gcomp.
*      --Group by Company
                l_groupname =  gt_user-company.
              WHEN p_gdep.
*      --Group By Department
                l_groupname =  gt_user-department.
            ENDCASE.


*--Expand the group if not expanded yet
            IF NOT l_groupname IS INITIAL." no grouping
              READ TABLE gt_item INTO ls_item
                WITH KEY item_name = 'GROUPNAME'
                         text      = l_groupname.

              READ TABLE lt_expanded WITH TABLE KEY
                table_line =  ls_item-node_key.
              IF sy-subrc <> 0.
*       group node is not expanded yet
                PERFORM expand_group USING ls_item-node_key.
                lt_expanded = ls_item-node_key.
                INSERT TABLE lt_expanded.
              ENDIF.
            ENDIF.
*--Expand all the user nodes
*  loop at lt_users.
            l_text = lt_users-userindex.
            CONDENSE l_text.
            READ TABLE gt_item INTO ls_item
               WITH KEY  item_name = 'USERINDEX'
                         text      = l_text.
            IF sy-subrc = 0.
              PERFORM expand_bname   USING ls_item-node_key.
*--Expand all the conflict nodes
              LOOP AT gt_node INTO ls_node_con
               WHERE relatkey = ls_item-node_key.
                LOOP AT lt_usercon WHERE userindex = lt_users-userindex.
*--Get child node key?
                  l_text = lt_usercon-conindex.
                  CONDENSE l_text.
                  READ TABLE gt_item INTO ls_item
                     WITH KEY  node_key  = ls_node_con-node_key
                               item_name = 'CONINDEX'
                               text      = l_text.
                  IF sy-subrc = 0.
                    PERFORM expand_usercon USING ls_item-node_key.
                    LOOP AT gt_node INTO ls_node
                     WHERE relatkey = ls_item-node_key.
                 LOOP AT lt_confun WHERE conindex = lt_usercon-conindex.
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
      visible           = 'X'
    EXCEPTIONS
      cntl_error        = 1
      cntl_system_error = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*            WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.
  CLEAR : gf_exp_conid, gf_exp_funid, gf_exp_bname.
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
    is_authdet       TYPE /psyng/seres_authdetail
  CHANGING
    es_node          TYPE treev_node.

  DATA : ls_node TYPE treev_node,
         l_text  TYPE string.
  ls_node = es_node."for use in macro
  ADD 1 TO g_auth_id.

  PERFORM get_text_system
    USING is_authdet-sysid
    CHANGING l_text.


  leaf_node et_node et_item i_key 'A' g_auth_id
  is_authdet-auth l_text '@C9@' '' .
  link_column et_item ls_node-node_key :
          'PROFILE'   is_authdet-profname ''.
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
    is_authdet       TYPE /psyng/seres_authdetail
    i_varel          TYPE xuval
    i_profindex      TYPE i
  CHANGING
    es_node          TYPE treev_node.
  DATA : ls_node TYPE treev_node.
  ls_node = es_node."for use in macro

  ADD 1 TO g_auth_id.
  child_node et_node et_item i_key 'V' g_auth_id
  i_varel i_varel '@GP@' '' .
  hidden_column et_item ls_node-node_key
  'NODETYPE'   'VAREL'.
  hidden_column et_item ls_node-node_key
  'PROFINDEX'   i_profindex.
  READ TABLE gt_system WITH KEY sysid = is_authdet-sysid.
  IF sy-subrc = 0.
    hidden_column et_item ls_node-node_key
    'SYSINDEX'   gt_system-sysindex.
  ENDIF.

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
    is_authdet       TYPE /psyng/seres_authdetail
    i_org            TYPE /psyng/dorg_abb
    i_profindex      TYPE i
  CHANGING
    es_node          TYPE treev_node.
  DATA : ls_node TYPE treev_node.
  ls_node = es_node."for use in macro

  ADD 1 TO g_auth_id.
  child_node et_node et_item i_key 'V' g_auth_id
  i_org i_org '@BN@' '' .
  hidden_column et_item ls_node-node_key
  'NODETYPE'   'ORG'.
  hidden_column et_item ls_node-node_key
  'PROFINDEX'   i_profindex.
  READ TABLE gt_system WITH KEY sysid = is_authdet-sysid.
  IF sy-subrc = 0.
    hidden_column et_item ls_node-node_key
    'SYSINDEX'   gt_system-sysindex.
  ENDIF.

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
MODULE f4_bname INPUT.
  IF sy-dynnr = '0101'.
    PERFORM f4_bname USING 'EXP'.
  ELSE.
    PERFORM f4_bname USING 'FND'.
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
FORM f4_bname USING i_type TYPE usr02-bname.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  LOOP AT gt_user.
    lt_values-line = gt_user-bname.
    APPEND lt_values.
    lt_values-line = gt_user-name_text.
    APPEND lt_values.
  ENDLOOP.

  lt_fields-tabname   = 'USR02'.
  lt_fields-fieldname = 'BNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SWRESUSR'.
  lt_fields-fieldname = 'NAME_TEXT'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'BNAME'
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
      gf_exp_bname = lt_return-fieldval.
    ELSE.
      gf_fnd_bname = lt_return-fieldval.
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_conid                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TYPE                                                        *
*---------------------------------------------------------------------*
FORM f4_conid USING i_type TYPE usr02-bname.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        l_conid_desc TYPE /psyng/conflict-description,
        l_sod        TYPE /psyng/conflict-vrsio.

  SELECT SINGLE sodvrsio FROM /psyng/swreshdr INTO (l_sod)
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
    WHEN  'B_'.
      PERFORM expand_bname    USING i_key.
    WHEN  'C_'.
      PERFORM expand_usercon  USING i_key.
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
        lt_swresifun TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
        l_conid_desc TYPE /psyng/conflict-description,
        l_sod        TYPE /psyng/conflict-vrsio.
  SELECT * FROM /psyng/swresifun INTO TABLE lt_swresifun
  WHERE aid = p_aid.

  SELECT SINGLE sodvrsio FROM /psyng/swreshdr INTO (l_sod)
  WHERE aid = p_aid.
  LOOP AT lt_swresifun.
    lt_values-line = lt_swresifun-funid.
    APPEND lt_values.
    SELECT SINGLE description FROM /psyng/function INTO
    (l_conid_desc) WHERE function  = lt_swresifun-funid
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
*BOC:HBHALLA (03/12/24)
        EXCEPTIONS
             authorization_missing = 1
             OTHERS     = 2.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
        WITH 'Authorization Missing'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (03/12/24)
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
      name             = '/PSYNG/SW_I000002'
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
*BOC:HBHALLA (06/12/24)
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Object Not Found'.
          WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
        ENDCASE.
      ENDIF.
*EOC:HBHALLA (06/12/24)
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
*       SHELLSTYLE         =
        parent             = meditor_container
*       LIFETIME           =
*       SAPHTMLP           =
*       UIFLAG             =
*       NAME               =
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
FORM get_destination_system USING    i_sysid
                     CHANGING e_destination.
  STATICS : st_rfcdes TYPE HASHED TABLE OF /psyng/sw_rfcdes
                        WITH HEADER LINE
                        WITH UNIQUE KEY systid.
  READ TABLE st_rfcdes WITH TABLE KEY systid = i_sysid.
  IF sy-subrc = 0.
    e_destination = st_rfcdes-rfcdest.
  ELSE.

    SELECT SINGLE systid rfcdest FROM /psyng/sw_rfcdes
      INTO CORRESPONDING FIELDS OF st_rfcdes
      WHERE systid = i_sysid.
    INSERT TABLE st_rfcdes.
    e_destination = st_rfcdes-rfcdest.
  ENDIF.
ENDFORM.                    " get_destination_system

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
                  CHANGING es_function TYPE /psyng/swresifun.
  STATICS : st_function TYPE HASHED TABLE OF /psyng/swresifun
                        WITH HEADER LINE
                        WITH UNIQUE KEY funid.
  READ TABLE st_function WITH TABLE KEY funid = i_funid
  INTO es_function.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM /psyng/swresifun INTO es_function WHERE
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
                  CHANGING es_function TYPE /psyng/swresifun.
  STATICS : st_function TYPE HASHED TABLE OF /psyng/swresifun
                        WITH HEADER LINE
                        WITH UNIQUE KEY funindex.
  READ TABLE st_function WITH TABLE KEY funindex = i_funindex
  INTO es_function.
  IF sy-subrc <> 0.
    SELECT SINGLE * FROM /psyng/swresifun INTO es_function WHERE
      aid = p_aid AND funindex = i_funindex.
    INSERT es_function INTO TABLE st_function.
  ENDIF.

ENDFORM.                    " get_function

*&---------------------------------------------------------------------*
*&      Form  get_text_kostl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USERS_KOSTL  text
*      <--P_L_GROUPNODE_TEXT  text
*----------------------------------------------------------------------*
FORM get_text_kostl USING    i_kostl
                    CHANGING e_text.
  TYPES : BEGIN OF typ_cskt,
            kostl TYPE kostl,
            ktext TYPE ktext,
          END OF typ_cskt.
  STATICS : st_kostl         TYPE HASHED TABLE OF typ_cskt
                        WITH HEADER LINE
                        WITH UNIQUE KEY kostl,
            st_table_checked TYPE flag,
            st_table_exists  TYPE flag.
*  DATA : ls_dd02l TYPE dd02l,
*         l_kostl TYPE kostl,
  DATA : lf_exists TYPE flag.
  READ TABLE st_kostl WITH TABLE KEY kostl = i_kostl.
  IF sy-subrc <> 0.
    READ TABLE gt_sysinfo WITH KEY rfcdest = ''
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
*--Local system in focus
      st_kostl-kostl = i_kostl.
      CALL FUNCTION '/PSYNG/BASIS_KOSTL_TEXT'
        EXPORTING
          i_kostl   = st_kostl-kostl
          i_spras   = sy-langu
        IMPORTING
          e_text    = st_kostl-ktext
          ef_exists = lf_exists.
    ENDIF.

    IF lf_exists <> 'X'.
*--not found yet
      LOOP AT gt_sysinfo WHERE rfcdest <> ''.
        st_kostl-kostl = i_kostl.
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
        CALL FUNCTION '/PSYNG/BASIS_KOSTL_TEXT'
          DESTINATION gt_sysinfo-rfcdest
          EXPORTING
            i_kostl   = st_kostl-kostl
            i_spras   = sy-langu
          IMPORTING
            e_text    = st_kostl-ktext
            ef_exists = lf_exists
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF lf_exists = 'X'.
          EXIT."found in a system.
        ENDIF.
      ENDLOOP.
    ENDIF.
    st_kostl-kostl = i_kostl.
    INSERT TABLE st_kostl.
  ELSE.
    st_kostl-kostl = i_kostl.
    st_kostl-ktext = i_kostl.
    INSERT TABLE st_kostl.
  ENDIF.
*if   st_kostl-ktext is initial.
*  e_text = st_kostl-ktext.
*endif.
  e_text = st_kostl-ktext.

*  ELSE.
**--There is no text table for Cost Center
*    e_text = i_kostl.
*  ENDIF.
ENDFORM.                    " get_text_kostl
*---------------------------------------------------------------------*
*       FORM f4_company                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_COMP                                                        *
*---------------------------------------------------------------------*
FORM f4_company USING    fieldname
                CHANGING e_comp
                .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr..
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro    = l_dynnr
      i_dynpprog  = l_repid
      i_fieldname = fieldname
    CHANGING
      e_company   = e_comp.

ENDFORM.                    " f4_company
*&---------------------------------------------------------------------*
*&      Form  f4_department
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_DEPART_HIGH  text
*----------------------------------------------------------------------*
FORM f4_department  USING    fieldname
                    CHANGING e_department .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr.

*--Check what FM is configured for search help for department
  se_config_param 'SW_DEPART_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_077'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro     = l_dynnr
      i_dynpprog   = l_repid
      i_fieldname  = fieldname
    CHANGING
      e_department = e_department.

ENDFORM.                    " f4_department
*&---------------------------------------------------------------------*
*&      Form  get_text_usergroup
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USERS_CLASS  text
*      <--P_L_GROUPNODE_TEXT  text
*----------------------------------------------------------------------*
FORM get_text_usergroup USING    i_class
                        CHANGING e_text.
  DATA : lf_exists TYPE flag,
         l_class   TYPE xuclass,
         l_txt     TYPE xutext.
  l_class = i_class.
  READ TABLE gt_sysinfo WITH KEY rfcdest = ''
  TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
*--Local system in focus
    CALL FUNCTION '/PSYNG/BASIS_USERGROUP_TEXT'
      EXPORTING
        i_class   = l_class
        i_spras   = sy-langu
      IMPORTING
        e_text    = l_txt
        ef_exists = lf_exists.
    e_text = l_txt.
  ENDIF.

  IF lf_exists <> 'X'.
*--not found yet
    LOOP AT gt_sysinfo WHERE rfcdest <> ''.
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
      CALL FUNCTION '/PSYNG/BASIS_USERGROUP_TEXT'
        DESTINATION gt_sysinfo-rfcdest
        EXPORTING
          i_class   = l_class
          i_spras   = sy-langu
        IMPORTING
          e_text    = l_txt
          ef_exists = lf_exists
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      IF lf_exists = 'X'.
        e_text = l_txt.
        EXIT."found in a system.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_text_usergroup
*&---------------------------------------------------------------------*
*&      Form  get_text_company
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USERS_COMPANY  text
*      -->P_L_GROUPNODE_TEXT  text
*----------------------------------------------------------------------*
FORM get_text_company USING    i_company
                               e_text.
  DATA : l_mess(80) TYPE c,
         lf_exists  TYPE flag,
         l_com      TYPE uscomp,
         l_text     TYPE uscomp.
  STATICS : l_valid_fm TYPE flag,
            l_fname    TYPE tfdir-funcname.
  l_com = i_company.
  IF l_valid_fm IS INITIAL.
    PERFORM check_fm_validation CHANGING l_valid_fm
                                         l_fname.
  ENDIF.
  CHECK l_valid_fm EQ 'Y'.
  READ TABLE gt_sysinfo WITH KEY rfcdest = ''
  TRANSPORTING NO FIELDS.
  IF sy-subrc = 0.
*  --Local system in focus
    l_com = i_company.
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
    CALL METHOD /psyng/sw_dynamic_select=>callback
      EXPORTING
        i_fname =  l_fname   " Name of Function Module
        i_com   =  l_com   " Company address, cross-system key
      IMPORTING
        e_text  =  l_text.   " Company address, cross-system key
*    CALL FUNCTION l_fname                    "#EC PATHLOCK_CI_DYN_ACCES
*      EXPORTING
*        i_company   = l_com
*      IMPORTING
*        e_comp_name = l_text
*      EXCEPTIONS
*        OTHERS      = 1.
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
    IF sy-subrc = 0 AND NOT e_text IS INITIAL.
      e_text = l_text.
      lf_exists = 'X'.
    ENDIF.
  ENDIF.
  IF lf_exists <> 'X'.
*    --not found yet
    LOOP AT gt_sysinfo WHERE rfcdest <> ''.
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
*BOC UMITTAL CLEAN CORE FIXES 11/03/2026
    CALL METHOD /psyng/sw_dynamic_select=>callback
      EXPORTING
        i_fname   =  l_fname    " Name of Function Module
        i_rfcdest =  gt_sysinfo-rfcdest
        i_com     =  l_com   " Company address, cross-system key
      IMPORTING
        e_text  =  l_text.   " Company address, cross-system key


*      CALL FUNCTION l_fname                 "#EC PATHLOCK_CI_DYN_ACCES
*        DESTINATION gt_sysinfo-rfcdest
*        EXPORTING
*          i_company             = l_com
*        IMPORTING
*          e_comp_name           = l_text
*        EXCEPTIONS
*          resource_failure      = 1
*          communication_failure = 2 MESSAGE l_mess
*          system_failure        = 3 MESSAGE l_mess
*          OTHERS                = 4.           "#EC SAST_CI_GEN_CHECK
*EOC UMITTAL CLEAN CORE FIXES 11/03/2026
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      IF sy-subrc = 0 AND NOT e_text IS INITIAL.
        lf_exists = 'X'.
        e_text = l_text.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_text_company
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
*&      Form  get_matching_users
*&---------------------------------------------------------------------*
*       Filter the list of all users by the users
*      that have the conflict
*----------------------------------------------------------------------*
*      -->P_GT_USERS  text
*      -->P_LT_MATCH_USERS  text
*----------------------------------------------------------------------*
FORM get_matching_users TABLES
    it_users STRUCTURE /psyng/swrescon
    et_match_users STRUCTURE /psyng/swresusr.
  LOOP AT it_users.
    READ TABLE gt_user WITH KEY userindex = it_users-userindex
    BINARY SEARCH.
    IF sy-subrc = 0.
      APPEND gt_user TO et_match_users.
    ENDIF.
  ENDLOOP.
*--Sort the matching users by trhe grouping and username field
  CASE 'X'.
    WHEN p_gclass.
*--Group by usergroup
      SORT et_match_users BY class bname.
    WHEN p_gkostl.
*--Group by Cost Center
      SORT et_match_users BY kostl bname.
    WHEN p_gcomp.
*--Group by Company
      SORT et_match_users BY company bname.
    WHEN p_gdep.
*--Group By Department
      SORT et_match_users BY department bname.
  ENDCASE.


ENDFORM.                    " get_matching_users
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
* BOC by GSINGH for C0765
         lv_fname_len  TYPE i,
         l_dat_mode    VALUE ' ',
         l_wrt_sep     VALUE '|'.
*BOC AKUMAR OPL518
  DATA: l_nodetype  TYPE string,
          l_rest      TYPE string,
          gv_mask     TYPE char255 VALUE 'XXXXXXXXXXXXXXXXXXXX',
          lv_space    TYPE c VALUE ' '.
*EOC AKUMAR OPL518
*Commented the default if_ask condition, will be passed as per the user
*selection.
*  IF if_ask = 'X'.
* EOC by GSINGH
  CLEAR l_index.
*--Later SAP versions support excel download
  IF sy-saprl < '500'.
    l_ext = 'txt'.
    l_type = 'ASC'.
    l_filter = 'Text files(*.txt)|*.TXT'.
  ELSE.
    l_ext    = 'txt'.
*BOC by GSINGH for C0765 - Changing the file Type to DAT to fix the
*excel file wrong header issue
*    l_type   = 'DBF'.
    l_type   = 'DAT'.
* EOC by GSINGH for C0765
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
*             DIAGNOSE_OBJECT             = ' '
              text_question = 'Do you want to overwrite?'
              text_button_1 = 'Yes'(001)
*             ICON_BUTTON_1 = ' '
              text_button_2 = 'No'(002)
*             ICON_BUTTON_2 = ' '
*             DEFAULT_BUTTON              = '1'
*             DISPLAY_CANCEL_BUTTON       = 'X'
*             USERDEFINED_F1_HELP         = ' '
*             START_COLUMN  = 25
*             START_ROW     = 6
*             POPUP_TYPE    =
            IMPORTING
              answer        = l_answ
*           TABLES
*             PARAMETER     =
           EXCEPTIONS
             text_not_found              = 1
             OTHERS        = 2
            .
          "(++)BOC UMITTAL SE VF scan-25/11/2024
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
*  ENDIF.
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
*BOC by GSINGH for C0765 - Text file download issue and Excel file
*header issue with '.DBF' file type
* Check the file extension
    lv_fname_len = strlen( l_filenamenum ) - 4.
    IF l_filenamenum+lv_fname_len(4) = '.TXT'.
      l_type    = 'ASC'.
      l_wrt_sep = 'X'.
    ELSE.
      l_dat_mode = 'X'.
    ENDIF.
* EOC by GSINGH

* BOC AKUMAR OPL 518
    REFRESH gt_excel_header.
    PERFORM excel_header CHANGING gt_excel_header.

    IF p_mitcon IS INITIAL.
      PERFORM set_mask USING 5 CHANGING gv_mask.
      PERFORM set_mask USING 4 CHANGING gv_mask.
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
      WHEN 'S'. " Role
        PERFORM set_mask USING 1 CHANGING gv_mask.
        PERFORM set_mask USING 2 CHANGING gv_mask.
        PERFORM set_mask USING 6 CHANGING gv_mask.
        PERFORM set_mask USING 3 CHANGING gv_mask.
        PERFORM set_mask USING 4 CHANGING gv_mask.
        PERFORM set_mask USING 5 CHANGING gv_mask.
    ENDCASE.

*---selected o/p expand level
    IF p_fun = 'X'.
      PERFORM set_mask USING 7 CHANGING gv_mask.
      PERFORM set_mask USING 8 CHANGING gv_mask.
      PERFORM set_mask USING 9 CHANGING gv_mask.
      PERFORM set_mask USING 10 CHANGING gv_mask.
      PERFORM set_mask USING 11 CHANGING gv_mask.
      PERFORM set_mask USING 17 CHANGING gv_mask.
      PERFORM set_mask USING 12 CHANGING gv_mask.
      PERFORM set_mask USING 13 CHANGING gv_mask.
      PERFORM set_mask USING 14 CHANGING gv_mask.
      PERFORM set_mask USING 15 CHANGING gv_mask.
      PERFORM set_mask USING 16 CHANGING gv_mask.
    ENDIF.

    IF p_rolpro = 'X'.
      PERFORM set_mask USING 10 CHANGING gv_mask.
      PERFORM set_mask USING 11 CHANGING gv_mask.
      PERFORM set_mask USING 17 CHANGING gv_mask.
      PERFORM set_mask USING 12 CHANGING gv_mask.
      PERFORM set_mask USING 13 CHANGING gv_mask.
      PERFORM set_mask USING 14 CHANGING gv_mask.
      PERFORM set_mask USING 15 CHANGING gv_mask.
      PERFORM set_mask USING 16 CHANGING gv_mask.
    ENDIF.
* EOC AKUMAR OPL 518
*BOC:HBHALLA (096)
    AUTHORITY-CHECK OBJECT  'S_GUI'
                     ID      'ACTVT'
                     FIELD   '61'.
    IF sy-subrc = 0.
      CALL FUNCTION 'GUI_DOWNLOAD'               "#EC SAST_CI_GEN_CHECK
        EXPORTING
          filename                = l_filenamenum
          filetype                = l_type
          write_field_separator   = l_wrt_sep
          dat_mode                = l_dat_mode
          col_select            = 'X'
          col_select_mask       = gv_mask
        TABLES
          data_tab                = gt_output_alv
          fieldnames              = gt_excel_header
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
         l_new    TYPE string,
*BOC:HBHALLA (D67K934268)
         l_num    TYPE string.
  CLEAR l_num.
  l_num = i_num.
  CONDENSE l_num.
*EOC:HBHALLA (D67K934268)
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
  CONCATENATE l_new '-' l_num '.' l_ext INTO e_filename. "HBHALLA
ENDFORM.                    " add_nr_to_filename
*&---------------------------------------------------------------------*
*&      Form  CHECK_FM_VALIDATION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--e_L_VALID_FM  text
*      <--e_L_FNAME  text
*----------------------------------------------------------------------*
FORM check_fm_validation  CHANGING e_l_valid_fm
                                   e_l_fname.
  DATA l_count TYPE i.
*--Do validation of FM name
  se_config_param 'SW_MGMT_COMP_NAME_FM' e_l_fname.
  IF NOT e_l_fname IS INITIAL.
    e_l_valid_fm = 'N'.
*--Check if FM exists
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = e_l_fname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc EQ 0.
*--Check if FM has same interface that is expected
      SELECT COUNT(*) FROM fupararef
      INTO l_count
      WHERE funcname  = e_l_fname AND
            r3state   = gc_active_state AND
            ( paramtype = gc_import_param
           OR paramtype = gc_export_param ) AND
            structure   = gc_company_address_str.
      IF sy-subrc EQ 0
      AND l_count EQ 2.
        e_l_valid_fm = 'Y'.
      ENDIF.
    ENDIF.
  ENDIF.

ENDFORM.

FORM set_def_usrtype.
  REFRESH usrtype.
  CLEAR usrtype.
  IF NOT validusr IS INITIAL.
    usrtype-sign = 'I'.
    usrtype-option = 'EQ'.
    usrtype-low = 'A'.
    APPEND usrtype.
  ENDIF.
ENDFORM.

FORM get_config_usr.
  DATA: lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE,
        l_table(6) TYPE c.

  CHECK p_flag IS INITIAL. "HBHALLA (PN-13137 ISSUE 6) (14/05/25)

*-- Check if anything maintained for usertype in starv
  IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE
      lt_tvarv FROM tvarvc
         WHERE name = '/PSYNG/USERTYPE'
           AND type = 'S'.
  ELSE.
*      l_table = 'TVARV'.
    SELECT * INTO CORRESPONDING FIELDS OF TABLE
      lt_tvarv FROM tvarv
         WHERE name = '/PSYNG/USERTYPE'
           AND type = 'S'.
  ENDIF.

*  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*         WHERE name = '/PSYNG/USERTYPE'
*           AND type = 'S'.

  IF NOT lt_tvarv[] IS INITIAL.
    REFRESH usrtype.
    CLEAR usrtype.
  ENDIF.

  LOOP AT lt_tvarv.
    MOVE-CORRESPONDING lt_tvarv TO usrtype.
    usrtype-option = lt_tvarv-opti.
    APPEND usrtype.
  ENDLOOP.

*  IF usrtype[] IS INITIAL.
*    PERFORM set_def_usrtype.
*  ENDIF.

*BOC:HBHALLA (PN-13137 ISSUE5) (14/05/25)
*-- Default locked users
  CLEAR swconfig.
  se_config_param 'DFLT_EXCLUDE_LOCKED' swconfig-value.
  IF swconfig-value = 'Y'.
    exlckusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    exlckusr = ' '.
  ENDIF.

*-- Default expired users
  CLEAR swconfig.
  se_config_param 'DFLT_EXCL_OUT_VALID' swconfig-value.
  IF swconfig-value = 'Y'.
    outvdate = 'X'.
  ELSEIF swconfig-value = 'N'.
    outvdate = ' '.
  ENDIF.
*EOC:HBHALLA (PN-13137 ISSUE5) (14/05/25)

  p_flag = 'X'. "HBHALLA (PN-13137 ISSUE 6) (14/05/25)

ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0401  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0401 OUTPUT.

  TYPE-POOLS: vrm. "Changes by RGUPTA on 28th Dec 2021

  REFRESH gt_func.

  gt_func-fcode = 'SEARCH'.
  APPEND gt_func.
  gt_func-fcode = 'EXP'.
  APPEND gt_func.

  SET PF-STATUS '0101' EXCLUDING gt_func.
*  SET TITLEBAR 'xxx'.

  DATA : "field_id TYPE vrm_id, "Commented by RGUPTA on 28th Dec, 2021
    values TYPE vrm_values,
    value  LIKE LINE OF values.
  REFRESH values.
  IF values[] IS INITIAL.
    value-key = 'ASC'.
    value-text = 'Ascending'.
    APPEND value TO values.
    CLEAR value.
    value-key = 'DSC'.
    value-text = 'Descending'.
    APPEND value TO values.
  ENDIF.
  CLEAR gf_sort_bname.
  CLEAR gf_sort_conf.

  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GF_SORT_BNAME'
      values = values[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             id_illegal_name = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.


  CALL FUNCTION 'VRM_SET_VALUES'
    EXPORTING
      id     = 'GF_SORT_CONF'
      values = values[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             id_illegal_name = 1
             OTHERS         = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0401  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0401 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'SORT'.
      IF gr_sort_bname = 'X' AND gf_sort_bname IS INITIAL.

        MESSAGE i113(/psyng/sw) WITH
     'Please select an option from dropdown'(i31).
      ELSEIF gr_sort_conf = 'X' AND gf_sort_conf IS INITIAL.
        MESSAGE i113(/psyng/sw) WITH
        'Please select an option from dropdown'(i31).
      ELSE.
        PERFORM sorting.
        MESSAGE s113(/psyng/sw) WITH
          'Nodes sorted'(i32).
        SET SCREEN 0.
        LEAVE SCREEN.
      ENDIF.
  ENDCASE.
  CLEAR sy-ucomm.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  SORTING
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sorting .
  g_sort_clicked = 'X'.
  DELETE gt_item WHERE node_key <> 'R_DATA'.
*  DELETE gt_node WHERE relatkey = 'R_DATA'.

*BOC: HBHALLA - C1326
  DELETE gt_node WHERE node_key <> 'R_DATA'.
*END OF CHANGE

*--delete to create new nodes
  CALL METHOD go_tree->delete_all_nodes.
  CALL METHOD cl_gui_cfw=>flush.

*---Add root folder
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

*---add nodes according to sorting option
  PERFORM expand_group USING 'R_DATA'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0103  OUTPUT
*&---------------------------------------------------------------------*
* C0765 by GSINGH - PBO module: Choose Export Options screen
*----------------------------------------------------------------------*
MODULE status_0103 OUTPUT.
*Go back to the inital screen, if Export to server or Cancel button is
*pressed.
  IF sy-ucomm EQ 'EXP_SR'
  OR sy-ucomm EQ 'CANCEL'.
    LEAVE TO SCREEN 0.
  ELSE.
    SET PF-STATUS '0103'.
    SET TITLEBAR '0103'.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0103  INPUT
*&---------------------------------------------------------------------*
* C0765 by GSINGH - PAI module: Choose Export Options screen
*----------------------------------------------------------------------*
MODULE user_command_0103 INPUT.

  DATA : ask_export TYPE flag.

  CASE sy-ucomm.
* Go back to the last screen if user press Cancel button
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
* If user press Ok, check the selected export option
    WHEN 'OK'.
* Export data to alv option slected, pass the data to display ALV
      IF gr_exp_old = 'X'.
        ask_export = 'X'.
        PERFORM export_data_to_alv USING ask_export.
        LEAVE TO SCREEN 0.
*Export data to Local file selected, bypass the ALV logic and save data
*to local file
      ELSEIF gr_exp_file = 'X'.
        ask_export = ' '.
        PERFORM export_data_to_alv USING ask_export.
        LEAVE TO SCREEN 0.
      ELSE.
* Export data to Server option selected, check if Root node is selected.
        IF g_node_key = 'R_DATA'.
*Call next screen to get the server path and user batch size input from
*user
          CALL SCREEN '0104' STARTING AT 10 1.
        ELSE.
* Display error message if root node is not selected
          MESSAGE s002(/psyng/sw) WITH
          'Please select only root node to export full data '(i34)
          'to the server'(i35).
          LEAVE TO SCREEN 0.
        ENDIF.
      ENDIF.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  GET_SEL_NODE
*&---------------------------------------------------------------------*
* C0765 by GSINGH - Get the user selected node
*----------------------------------------------------------------------*
FORM get_sel_node .

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

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXPORT_DATA_TO_SERVER
*&---------------------------------------------------------------------*
* C0765 by GSINGH - Logic: Export data to Server
*----------------------------------------------------------------------*
FORM export_data_to_server .
  DATA: lv_job_released TYPE flag,
        lv_jobcount     TYPE btcjobcnt.

CONSTANTS lc_jobname TYPE btcjob VALUE 'STORED SOD USER RESULTS TO SRVR'
.

* Create a background job for exporting data to server
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
  IF sy-subrc <> 0.
* Implement suitable error handling here
  ELSE.
* Submit the program to execute via background job
    SUBMIT /psyng/sw_158
        VIA JOB lc_jobname
        NUMBER lv_jobcount
      WITH p_aid = p_aid
      WITH p_local = p_local
      WITH p_remote = p_remote
      WITH p_cross = p_cross
      WITH p_fun = p_fun
      WITH p_rolpro = p_rolpro
      WITH p_orgvar = p_orgvar
      WITH p_all = p_all
      WITH p_uswc = p_uswc
      WITH p_spath = gf_server_path
      WITH p_ucount = gf_users_count
      WITH s_bname IN s_bname
      WITH s_kostl IN s_kostl
      WITH s_class IN s_class
      WITH s_comp IN s_comp
      WITH s_dep  IN s_dep
      WITH usrtype IN usrtype
      WITH s_conid IN s_conid
      WITH s_unum IN s_unum
      WITH s_umnum IN s_umnum
      AND RETURN.
* Releasing the background job with immediate effect
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
    IF sy-subrc <> 0.
* Implement suitable error handling here
    ELSEIF lv_job_released = 'X'.
      MESSAGE i002(/psyng/sw) WITH 'Job '(i36) lc_jobname
      'released for exporting data to server'(i37).
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0104  OUTPUT
*&---------------------------------------------------------------------*
* C0765 by GSINGH - PBO module: Export data to server screen
*----------------------------------------------------------------------*
MODULE status_0104 OUTPUT.
  SET PF-STATUS '0104'.
  SET TITLEBAR '0104'.
  DATA : l_max_alv_s TYPE string,
         l_max_alv   TYPE i.
*Get the value of recorss limit for batch size from the Config
*parameter.
  se_config_param 'SOD_EXPORT_ALV_LIMIT' l_max_alv_s.
  IF l_max_alv_s CO '0123456789'.
*Code Changes for B17121 by GSINGH - Hnadling Short Dump due to large
*number value in Config Parameter
    IF l_max_alv_s > '1000000'.
      MESSAGE
     'Parameter SOD_EXPORT_ALV_LIMIT current value cannot be greater ' &
     'than default value'(e11)
     TYPE 'E'.
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
  IF gf_users_count IS INITIAL.
    gf_users_count = l_max_alv.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0104  INPUT
*&---------------------------------------------------------------------*
* C0765 by GSINGH - PAI module: Export data to server screen
*----------------------------------------------------------------------*
MODULE user_command_0104 INPUT.
  DATA: lv_srv_path(128) TYPE c.
  CASE sy-ucomm.
    WHEN 'EXP_SR'.
      CLEAR lv_srv_path.
      lv_srv_path = gf_server_path.
*     Validate if entered application server path exists or not
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
        MESSAGE
'Application Server path does not exist. Kindly enter valid server pa' &
'th.'
TYPE 'I'.
      ENDIF.
    WHEN 'CANCEL'.
      LEAVE TO SCREEN 0.
    WHEN OTHERS.
  ENDCASE.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  GET_SEL_DETAIL_RECORDS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_sel_detail_records .
  DATA: ls_fun           TYPE mtreeitm,
        ls_connode       TYPE treev_node,
        ls_funnode       TYPE treev_node,
        ls_usernode      TYPE treev_node,
        ls_rolnode       TYPE treev_node,
        lt_users_alv     TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
        ls_items         TYPE mtreeitm,
        lt_funprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
        lt_usrprof       TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_usrprof2      TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_profrole      TYPE SORTED TABLE OF /psyng/swresprol
                         WITH HEADER LINE WITH UNIQUE KEY profindex,
        lt_roles         TYPE SORTED TABLE OF /psyng/swresirol
                         WITH HEADER LINE WITH UNIQUE KEY roleindex,
        lt_comprole      TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        ls_comp          LIKE LINE OF lt_comprole,
        ls_role          TYPE /psyng/swresirol,
        ls_comprole      TYPE /psyng/swresirol,
       lt_profiles      TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
       lt_authdet       TYPE TABLE OF /psyng/seres_authdetail
                        WITH HEADER LINE,
       lt_authdet_all   TYPE TABLE OF /psyng/seres_authdetail
                    WITH HEADER LINE,
       ls_function      TYPE /psyng/swresifun,
       l_funindex       TYPE /psyng/seres_funindex,
       l_userinndex     TYPE /psyng/seres_userindex,
       lt_funprofile    TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
       lt_confun        TYPE TABLE OF /psyng/swrescfun WITH HEADER LINE,
       lt_function      TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
       lt_usercon       TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
       l_continue       TYPE flag,
       l_user_count     TYPE i,
*       BOC by GSINGH for C0765
*        lf_ask_export    TYPE flag VALUE 'X',
*        lf_ask_export    TYPE flag,
*       EOC by GSINGH
       lf_use_alv       TYPE flag,
       l_max_alv_s      TYPE string,
       l_max_alv        TYPE i,
       lf_cancel_export TYPE flag.


  FIELD-SYMBOLS: <swresusr> TYPE /psyng/swresusr,
                 <confun>   TYPE /psyng/swrescfun.
  RANGES: lr_userindex FOR /psyng/swrescon-userindex,
          lr_userindex_all FOR /psyng/swrescon-userindex,
          lr_userindex_part FOR /psyng/swrescon-userindex,
          lr_funindex  FOR /psyng/swrescfun-funindex,
          lr_profindex FOR /psyng/swresupr-profileindex,
          lr_sys       FOR /psyng/swresupr-sys.

  se_config_param 'SOD_EXPORT_ALV_LIMIT' l_max_alv_s.
  IF l_max_alv_s CO '0123456789'.
    l_max_alv = l_max_alv_s.
  ELSE.
    l_max_alv = 1000000.
  ENDIF.

  REFRESH: gt_output_alv, lt_users_alv.
*  CLEAR g_node_key.

*     Get selected node
*  CALL METHOD go_tree->get_selected_node
*    IMPORTING
*      node_key                   = g_node_key
*    EXCEPTIONS
*      failed                     = 1
*      single_node_selection_only = 2
*      cntl_system_error          = 3.
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ENDIF.
*
*  IF g_node_key IS INITIAL.
*    MESSAGE i398(00) WITH text-e02 text-e03.
*    EXIT.
*  ENDIF.

*---prepare data table for alv
  lt_users_alv[] = gt_user[].
  CASE g_node_key(1).
    WHEN 'G'.
*Parent node (1st) of tree
      READ TABLE gt_item INTO ls_items
             WITH KEY node_key  = g_node_key
                      item_name = 'GROUPNAME'.
      CASE 'X'.
        WHEN p_gclass.
*--Group by usergroup
          DELETE lt_users_alv WHERE class <> ls_items-text.
        WHEN p_gkostl.
*--Group by Cost Center
          DELETE lt_users_alv WHERE kostl <> ls_items-text.
        WHEN p_gcomp.
*--Group by Company
          DELETE lt_users_alv WHERE company <> ls_items-text.
        WHEN p_gdep.
*--Group By Department
          DELETE lt_users_alv WHERE department <> ls_items-text.
      ENDCASE.

    WHEN 'B'.
*Bname node
      READ TABLE gt_item INTO ls_items
           WITH KEY node_key  = g_node_key
                    item_name = 'DATA'.
      DELETE lt_users_alv WHERE bname <> ls_items-text.
    WHEN 'C'.
*Conflict node
      READ TABLE gt_node INTO ls_connode
                    WITH KEY node_key = g_node_key.
      READ TABLE gt_item INTO ls_items
       WITH KEY node_key  = ls_connode-relatkey
                item_name = 'DATA'.
      IF sy-subrc = 0.
        DELETE lt_users_alv WHERE bname <> ls_items-text.
      ENDIF.
    WHEN 'F'.
*Function node
*--Get function index value
      READ TABLE gt_item INTO ls_fun
           WITH KEY node_key  = g_node_key
                    item_name = 'FUNINDEX'.
*--Get the userid, 2 nodes up
      READ TABLE gt_node
      INTO ls_funnode
      WITH KEY node_key = g_node_key.

      READ TABLE gt_node
      INTO ls_connode
      WITH KEY node_key = ls_funnode-relatkey.

      READ TABLE gt_node
      INTO ls_usernode
      WITH KEY node_key = ls_connode-relatkey.
*--Get user index value
      READ TABLE gt_item INTO ls_items
         WITH KEY node_key  = ls_usernode-node_key
                  item_name = 'USERINDEX'.
      DELETE lt_users_alv WHERE userindex <> ls_items-text.
  ENDCASE.

*---Warning if nr of users > 50
  DESCRIBE TABLE lt_users_alv LINES l_user_count.
  gv_out_users = l_user_count.
  l_continue = 'X'.
  IF l_user_count > 50.
    CLEAR l_continue.
    PERFORM advise_syswide_analysis
    CHANGING  l_continue.
  ENDIF.

  IF l_continue = 'X'.
*---collect user index
    LOOP AT lt_users_alv ASSIGNING <swresusr>.
      lr_userindex-sign = 'I'.
      lr_userindex-option = 'EQ'.
      lr_userindex-low = <swresusr>-userindex.
      APPEND lr_userindex.
    ENDLOOP.
*-- get user conflict
    IF NOT lr_userindex[] IS INITIAL.
      lr_userindex_all[] = lr_userindex[].
      WHILE NOT lr_userindex[] IS INITIAL.
        APPEND LINES OF lr_userindex FROM 1 TO 5000
        TO lr_userindex_part.
        DELETE lr_userindex FROM 1 TO 5000.
        IF p_mitcon EQ 'X'.
          SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                     WHERE aid       =  p_aid AND
                           userindex IN lr_userindex_part AND
                           conindex  IN gr_conflicts.
        ELSE.
          SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                     WHERE aid       =  p_aid AND
                           userindex IN lr_userindex_part AND
                           conindex  IN gr_conflicts AND
                           mitigated = p_mitcon.
        ENDIF.
        REFRESH : lr_userindex_part[].
      ENDWHILE.
      lr_userindex[] = lr_userindex_all[].
    ENDIF.
    FREE : lr_userindex_part, lr_userindex_all.

*---if conflict node selected, delete others
    IF g_node_key(1) = 'C'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'CONINDEX'.
      IF sy-subrc = 0.
        DELETE lt_usercon WHERE conindex <> ls_fun-text.
      ENDIF.
    ENDIF.

*--User's Conflict functions
    IF NOT lt_usercon[] IS INITIAL.
      SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
      FOR ALL ENTRIES IN lt_usercon
               WHERE aid       =  p_aid AND
                     conindex  = lt_usercon-conindex.
      IF NOT lt_confun[] IS INITIAL.
        SELECT  * FROM /psyng/swresifun INTO TABLE lt_function
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
            DELETE lt_usercon WHERE conindex <> ls_fun-text.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDIF.

* if role node selected, delete others
    IF g_node_key(1) = 'S'.
      READ TABLE gt_node INTO ls_rolnode
    WITH KEY node_key = g_node_key.
      IF sy-subrc = 0.
        READ TABLE gt_item INTO ls_fun
              WITH KEY
                      node_key  = ls_rolnode-relatkey
                       item_name = 'FUNINDEX'.
        IF sy-subrc = 0.
          DELETE lr_funindex WHERE low <> ls_fun-text.
        ENDIF.
      ENDIF.
    ENDIF.

*--Approach with multiple selects, optimize use of indexes
*--Get all profiles user has
    SELECT * FROM /psyng/swresupr
    INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
    WHERE aid          = p_aid AND
          userindex    IN lr_userindex.
*--For these profiles,
*  get the ones that relate to the functions we care about
    lr_profindex-sign   = 'I'.
    lr_profindex-option = 'EQ'.
    MOVE-CORRESPONDING lr_profindex TO lr_sys.
    LOOP AT lt_usrprof.
      lr_profindex-low = lt_usrprof-profileindex.
      APPEND lr_profindex.
      lr_sys-low = lt_usrprof-sys.
      APPEND lr_sys.
    ENDLOOP.
    SORT lr_profindex BY low.
    SORT lr_sys BY low.
    DELETE ADJACENT DUPLICATES FROM  lr_profindex COMPARING low.
    DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.

    SELECT * FROM /psyng/swresfpr
    INTO TABLE lt_funprofile
    WHERE
      aid = p_aid AND
      sys IN lr_sys AND
*      funindex IN lr_funindex AND
      profileindex IN lr_profindex.

    IF g_node_key(1) = 'F'.
      READ TABLE gt_item INTO ls_fun
            WITH KEY node_key  = g_node_key
                     item_name = 'FUNINDEX'.
      IF sy-subrc = 0.
        DELETE lt_funprofile WHERE funindex <> ls_fun-text.
      ENDIF.
    ENDIF.

    SORT lt_funprofile BY sys profileindex.
    LOOP AT lt_usrprof.
      READ TABLE lt_funprofile WITH KEY
        sys           = lt_usrprof-sys
        profileindex  = lt_usrprof-profileindex
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND lt_usrprof TO lt_usrprof2.
      ENDIF.
    ENDLOOP.
    lt_usrprof[] =   lt_usrprof2[].
    FREE lt_usrprof2[].

**--Get the roles
    IF NOT lt_usrprof[] IS INITIAL.

      SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
        FOR ALL ENTRIES IN
          lt_usrprof
      WHERE aid       = p_aid AND
*              sys       = lt_usrprof-sys and
            profindex = lt_usrprof-profileindex.

      SELECT * FROM /psyng/swresprol
      INTO TABLE lt_profrole
      FOR ALL ENTRIES IN lt_usrprof
      WHERE aid       = p_aid AND
            sys       = lt_usrprof-sys AND
            profindex = lt_usrprof-profileindex.
      IF NOT lt_profrole[] IS INITIAL.
        SELECT * FROM /psyng/swresirol
        INTO TABLE lt_roles
        FOR ALL ENTRIES IN lt_profrole
          WHERE aid = p_aid AND
                roleindex = lt_profrole-roleindex.
        IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
          SELECT * FROM /psyng/swresucom
          INTO TABLE lt_comprole
          FOR ALL ENTRIES IN lt_roles WHERE
            aid = p_aid AND
*            userindex = l_userinndex AND
            userindex IN lr_userindex AND
            roleindex = lt_roles-roleindex.
* BOC by RGUPTA on 25.07.22 for #22227
          IF lt_comprole[] IS NOT INITIAL.
            DELETE lt_comprole[] WHERE compindex IS INITIAL
                                    OR compindex EQ 0.
          ENDIF.
* EOC by RGUPTA on 25.07.22 for #22227
          IF NOT lt_comprole[] IS INITIAL.
            SELECT * FROM /psyng/swresirol
            APPENDING TABLE lt_roles
            FOR ALL ENTRIES IN lt_comprole
              WHERE aid = p_aid AND
                    roleindex = lt_comprole-compindex.
          ENDIF.
        ENDIF.
      ENDIF.

    ENDIF.

*---Macro to get only uniq record when org/var option not selected
    DEFINE export_only_uniq_value.
      check p_orgvar <> 'X'.

      if p_fun = 'X'.
       read table gt_output_alv with key  bname = &1 "lt_users_alv-bname
                                            conid = &2"gt_conflict-conid
                                          funid = &3."lt_function-funid.
        if sy-subrc = 0.
          clear gt_output_alv.
        else.
          add 1 to g_alv_count.
          append gt_output_alv.
        endif.

      endif.

      if p_rolpro  = 'X'.
       read table gt_output_alv with key  bname = &1 "lt_users_alv-bname
                                            conid = &2"gt_conflict-conid
                                           funid = &3"lt_function-funid.
                                              agr_name = &4
                                              profname = &5.
        if sy-subrc = 0.
          clear gt_output_alv.
        else.
          add 1 to g_alv_count.
          append gt_output_alv.
          clear gt_output_alv. "Changes by RGUPTA on 30th Nov,2021
        endif.
      endif.
    END-OF-DEFINITION.


    SORT lt_usrprof BY sys userindex profileindex.
    LOOP AT lt_confun.
      CLEAR gt_output_alv.
      LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
        LOOP AT lt_usercon WHERE conindex = lt_confun-conindex.
* BOC for B16609 for C0633
          IF lt_usercon-origin IS NOT INITIAL.
            IF p_local = 'X' AND p_remote IS INITIAL
             AND p_cross IS INITIAL
             AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
                OR lt_usercon-origin = 5 ).
              CONTINUE.
            ELSEIF p_local = 'X' AND p_remote = 'X'
             AND p_cross IS INITIAL
             AND lt_usercon-origin = 3.
              CONTINUE.
            ELSEIF p_local = 'X' AND p_remote IS INITIAL
             AND p_cross = 'X'
             AND lt_usercon-origin = 2.
              CONTINUE.
            ELSEIF p_local IS INITIAL AND p_remote = 'X'
             AND p_cross IS INITIAL
             AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
                OR lt_usercon-origin = 4 ).
              CONTINUE.
            ELSEIF p_local IS INITIAL AND p_remote = 'X'
             AND p_cross = 'X'
             AND lt_usercon-origin = 1.
              CONTINUE.
            ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
             AND p_cross = 'X'
             AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
              CONTINUE.
            ENDIF.
          ENDIF.
* EOC for B16609 for C0633
          READ TABLE lt_usrprof WITH KEY
            sys          = lt_funprofile-sys
            userindex    = lt_usercon-userindex
            profileindex = lt_funprofile-profileindex
            BINARY SEARCH.
          CHECK sy-subrc = 0.
* userid
      READ TABLE lt_users_alv WITH KEY userindex = lt_usercon-userindex.
          IF sy-subrc = 0.
            gt_output_alv-bname = lt_users_alv-bname.
            gt_output_alv-confnum = lt_users_alv-nr_conflicts.
            gt_output_alv-mitinum = lt_users_alv-nr_mitigated.
          ENDIF.
* Conflicts
          READ TABLE gt_conflict WITH KEY conindex = lt_confun-conindex.
          IF sy-subrc = 0.
            gt_output_alv-conid = gt_conflict-conid.
            gt_output_alv-mitigated = lt_usercon-mitigated.
* BOC for B16609 for C0633
            CASE lt_usercon-origin.
              WHEN 1.
                gt_output_alv-origin = 'Local'(173).
              WHEN 2.
                gt_output_alv-origin = 'Remote'(174).
              WHEN 3.
                gt_output_alv-origin = 'Cross'(175).
              WHEN 4.
                gt_output_alv-origin = 'Local&Cross'(202).
              WHEN 5.
                gt_output_alv-origin = 'Remote&Cross'(203).
              WHEN 6.
                gt_output_alv-origin = 'L&R&C'(204).
            ENDCASE.
* EOC for B16609 for C0633
          ENDIF.
* function
          READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
          IF sy-subrc = 0.
            gt_output_alv-funid = lt_function-funid.
          ENDIF.

          IF p_fun <> 'X'.
* profiles
            READ TABLE lt_profiles WITH KEY
                          profindex = lt_usrprof-profileindex.
            IF sy-subrc = 0.
              gt_output_alv-profname = lt_profiles-profname.
            ENDIF.

** Role
            READ TABLE lt_profrole WITH KEY
                       profindex = lt_usrprof-profileindex.
            IF sy-subrc = 0.
              READ TABLE lt_roles WITH KEY
                roleindex = lt_profrole-roleindex.
              gt_output_alv-agr_name = lt_roles-agr_name.
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
              LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
                                 AND  roleindex = lt_profrole-roleindex.
                READ TABLE lt_roles WITH KEY
             roleindex  = lt_comprole-compindex.
                IF sy-subrc = 0.
                  gt_output_alv-comp_agr = lt_roles-agr_name.
                ENDIF.
           READ TABLE gt_output_alv WITH KEY  bname = lt_users_alv-bname
                                               conid = gt_conflict-conid
                                               funid = lt_function-funid
                                       comp_agr = gt_output_alv-comp_agr
                                       agr_name = gt_output_alv-agr_name
                                      profname = gt_output_alv-profname.
                IF sy-subrc <> 0.
                  APPEND gt_output_alv.
                  ADD 1 TO g_alv_count.
                ENDIF.
              ENDLOOP.
              CLEAR: gt_output_alv-comp_agr.
            ENDIF.
            IF  p_rolpro = 'X'.
             export_only_uniq_value lt_users_alv-bname gt_conflict-conid
         lt_function-funid  gt_output_alv-agr_name lt_profiles-profname.
            ENDIF.
          ENDIF.

*--- call macro only if org/var expand o/p option not selected
          IF p_fun = 'X'.
            export_only_uniq_value lt_users_alv-bname gt_conflict-conid
                              lt_function-funid  '' ''.
          ENDIF.

* ---- don't go for detail if expand level not selected org/var
          IF p_orgvar = 'X'.
            REFRESH : lt_authdet.
            CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
              EXPORTING
                i_aid             = p_aid
                i_sys             = lt_usrprof-sys
                i_funindex        = lt_confun-funindex
                i_profileindex    = lt_usrprof-profileindex
              TABLES
                et_profiledetails = lt_authdet.

            LOOP AT lt_authdet.
              MOVE-CORRESPONDING lt_authdet TO gt_output_alv.
              ADD 1 TO g_alv_count.
              APPEND gt_output_alv.
*              clear gt_output_alv. "RGUPTA
*              IF g_alv_count > l_max_alv.
**--The export contains more data than can be handled in
**  the memory of the sap session
**  Download the data in separate files
*                IF lf_ask_export = 'X'.
*                  MESSAGE i012.
*                ENDIF.
**   The amount of data is too large to export at once and will be split
*                PERFORM export_to_file USING    lf_ask_export
*                                       CHANGING lf_cancel_export.
*                IF lf_cancel_export = 'X'.
*                  EXIT.
*                ENDIF.
*                CLEAR : lf_ask_export,
*                        g_alv_count.
*              ENDIF.

            ENDLOOP.
            CLEAR gt_output_alv. "RGUPTA
          ENDIF.
*          endloop.
          FREE : lt_authdet.
          IF lf_cancel_export = 'X'.
            EXIT.
          ENDIF.
        ENDLOOP.
        IF lf_cancel_export = 'X'.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF lf_cancel_export = 'X'.
        EXIT.
      ENDIF.
    ENDLOOP.
*--free some memory
    FREE :     lt_users_alv,
               lt_funprof ,
               lt_usrprof ,
               lt_usrprof2,
               lt_profrole,
               lt_roles   ,
               lt_comprole,
               lt_profiles ,
               lt_authdet  ,
               lt_authdet_all ,
               lt_funprofile ,
               lt_confun   ,
               lt_function,
               lt_usercon  .

*---sort and delete duplicates records
    SORT gt_output_alv.
    DELETE ADJACENT DUPLICATES FROM gt_output_alv COMPARING
    ALL FIELDS.

*    IF g_alv_count > 0 AND NOT lf_cancel_export = 'X'.
*      IF lf_ask_export = 'X'."we haven't had to ask for anything yet
*        PERFORM display_alv.
*      ELSE.
**  --Do a direct download, to avoid memory issues with alv
*        PERFORM export_to_file USING    lf_ask_export
*                               CHANGING lf_cancel_export.
*      ENDIF.
*    ENDIF.
  ENDIF.
*  CLEAR g_alv_count.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXCEL_HEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_EXCEL_HEADER  text
*----------------------------------------------------------------------*
FORM excel_header  CHANGING gt_excel_header TYPE tt_excel_header.

  DATA : ls_excel_header TYPE ty_excel_header.


  ls_excel_header-col_name = 'User ID'(c02).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Conflict'(c03).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Conflicts'(t09).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Mitigated Conflicts'(t10).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Mitigated'(t08).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Function'(c04).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Composite Role'(c15).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Role'(c05).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Profile'(c06).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'System'(c07).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Tcode'(c08).
  APPEND ls_excel_header TO gt_excel_header.

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

  ls_excel_header-col_name = 'Abbr.'(c14).
  APPEND ls_excel_header TO gt_excel_header.

  ls_excel_header-col_name = 'Origin'(c16).
  APPEND ls_excel_header TO gt_excel_header.

*BOC:HBHALLA (PN-15675) (08/10/25)
  ls_excel_header-col_name = 'User Group'(c17).
  APPEND ls_excel_header TO gt_excel_header.
*EOC:HBHALLA (PN-15675) (08/10/25)

*BOC:HBHALLA (PN-15675) (08/10/25)
  ls_excel_header-col_name = 'Department'(t11).
  APPEND ls_excel_header TO gt_excel_header.
*EOC:HBHALLA (PN-15675) (08/10/25)

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SET_MASK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GV_MASK  text
*      -->P_4      text
*----------------------------------------------------------------------*
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

*&---------------------------------------------------------------------*
*&      Form  CHECK_DUPLICATE_NODES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ITEM  text
*      <--P_LF_DUPLICATE_NODES  text
*----------------------------------------------------------------------*
FORM check_duplicate_nodes  USING  VALUE(lt_item) TYPE ttree_item
*--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024
                               it_roles           TYPE ttyp_roles
                               it_profrole        TYPE ttyp_profile
*--End of insert : UMITTAL C1342 D67K931619 14/05/2024

                            CHANGING lf_duplicate_nodes TYPE flag
                                     lt_role_nodes TYPE ttree_item.

  DATA: ls_item LIKE LINE OF lt_item,
        lt_item_tmp TYPE ttree_item,
        l_lines TYPE i,
        l_lines1 TYPE i.
*--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024
  DATA: ls_profrole      LIKE LINE OF it_profrole,
        ls_role          LIKE LINE OF it_roles.

  TYPES: BEGIN OF ty_sys,
          role_index    TYPE /psyng/seres_roleindex,
          sys_index     TYPE /psyng/seres_sysindex,
         END OF ty_sys.
  DATA : lt_sys_index TYPE STANDARD TABLE OF ty_sys,
         ls_sys_index TYPE ty_sys.
*--End of insert : UMITTAL C1342 D67K931619 14/05/2024
  REFRESH: lt_item_tmp, lt_role_nodes.
  LOOP AT lt_item INTO ls_item WHERE node_key CS 'SR_'
                                 AND item_name = 'DATA'.
*--Begin of insert : UMITTAL C1342 D67K931619 14/05/2024
    LOOP AT it_roles INTO ls_role WHERE agr_name = ls_item-text.
      LOOP AT it_profrole INTO ls_profrole
                           WHERE roleindex = ls_role-roleindex.
        CLEAR ls_sys_index.
        READ TABLE lt_sys_index INTO ls_sys_index
          WITH KEY sys_index = ls_profrole-sys.
        IF sy-subrc EQ 0.
          APPEND ls_item TO lt_item_tmp.
          CLEAR ls_item.
        ELSE.
          CLEAR ls_sys_index.
          ls_sys_index-sys_index = ls_profrole-sys.
          ls_sys_index-role_index = ls_profrole-roleindex.
          APPEND ls_sys_index TO lt_sys_index.
        ENDIF.
      ENDLOOP.
    ENDLOOP.
    CLEAR lt_sys_index[].
*    APPEND ls_item TO lt_item_tmp.
*--End of insert : UMITTAL C1342 D67K931619 14/05/2024
    CLEAR ls_item.
  ENDLOOP.

  APPEND LINES OF lt_item_tmp TO lt_role_nodes.
  DESCRIBE TABLE lt_item_tmp LINES l_lines.
  SORT lt_item_tmp BY text.

  DELETE ADJACENT DUPLICATES FROM lt_item_tmp COMPARING text.
  DESCRIBE TABLE lt_item_tmp LINES l_lines1.

  IF l_lines NE l_lines1.
    lf_duplicate_nodes = 'X'.
  ELSE.
    CLEAR lf_duplicate_nodes.
  ENDIF.

ENDFORM.                    " CHECK_DUPLICATE_NODES
*&---------------------------------------------------------------------*
*&      Form  MERGE_DUPLICATE_NODES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_LT_NODE  text
*      <--P_LT_ITEM  text
*----------------------------------------------------------------------*
FORM merge_duplicate_nodes  CHANGING lt_node TYPE treev_ntab
                                     lt_item TYPE ttree_item
                                     lt_role_nodes TYPE ttree_item.

  DATA: ls_role_nodes LIKE LINE OF lt_role_nodes,
        ls_role_nodes1 LIKE LINE OF lt_role_nodes,
        l_count TYPE i,
        ls_node LIKE LINE OF lt_node.

  SORT lt_role_nodes BY text.

  LOOP AT lt_role_nodes INTO ls_role_nodes.
    l_count = 1.
    LOOP AT lt_role_nodes FROM sy-tabix INTO ls_role_nodes1 WHERE
    node_key NE ls_role_nodes-node_key AND text = ls_role_nodes-text.
      ADD 1 TO l_count.
      DELETE lt_item WHERE node_key = ls_role_nodes1-node_key.
      LOOP AT lt_node INTO ls_node WHERE relatkey =
      ls_role_nodes1-node_key.
        DELETE lt_item WHERE node_key = ls_node-node_key.
      ENDLOOP.
      DELETE lt_node WHERE relatkey = ls_role_nodes1-node_key OR
      node_key = ls_role_nodes1-node_key.
    ENDLOOP.
    IF l_count GT 1.
      DELETE lt_role_nodes FROM 1 TO l_count.
    ELSE.
      DELETE lt_role_nodes INDEX 1.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " MERGE_DUPLICATE_NODES
