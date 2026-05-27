*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_AUTO_ORG
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_auto_org.
TABLES : rfcdes.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

DATA : gr_table          TYPE REF TO data,
       gr_table2         TYPE REF TO data,
       gt_sort           TYPE lvc_t_sort,
       gt_sort2          TYPE lvc_t_sort,
       gt_filter         TYPE lvc_t_filt,
       gt_filter2        TYPE lvc_t_filt,
       gf_is_erp         TYPE flag,
       g_alv_status(10)  TYPE c VALUE 'SUMMARY',
       g_bukrs         TYPE /PSYNG/DORG_ABB,
       g_field           TYPE string,
       gs_fieldcat       TYPE lvc_s_fcat,
       go_alvgrid        TYPE REF TO cl_gui_alv_grid,
       go_ccontainer     TYPE REF TO cl_gui_custom_container,
       go_alvgrid2       TYPE REF TO cl_gui_alv_grid,
       go_ccontainer2    TYPE REF TO cl_gui_custom_container,
       gt_fieldcat       TYPE lvc_t_fcat,
       gs_layout         TYPE lvc_s_layo,
       gs_layout2        TYPE lvc_s_layo.
DATA : gt_rfcdes         TYPE TABLE OF rfcdes WITH HEADER LINE.
DATA : gt_exc_toolbar TYPE ui_functions.
DATA : BEGIN OF gt_output OCCURS 0,
          country(20)        TYPE c,
          rfcdest        TYPE rfcdest.
INCLUDE        STRUCTURE /psyng/swsodorgm.
DATA :
          label          TYPE xutext,
          icon           TYPE icon_d,
          check          TYPE flag,
          manual         TYPE flag,
          toggled        TYPE flag,
END OF gt_output.

DATA : gt_output_temp LIKE TABLE OF gt_output WITH HEADER LINE.

DATA :
       gf_dispchg(1)      TYPE c,
       gc_display(1) TYPE c VALUE 'D',
       gc_change(1)  TYPE c VALUE 'C'.

FIELD-SYMBOLS :
       <fs_dynfield>     TYPE ANY,
       <fs_tab_orig> TYPE STANDARD TABLE.

CONSTANTS :
  c_icon_green           TYPE icon_d VALUE '@08@',
  c_icon_red             TYPE icon_d VALUE '@09@',
  c_fm_001               TYPE rs38l_fnam VALUE '/PSYNG/SW_AO_004',
  c_fm_002               TYPE rs38l_fnam VALUE '/PSYNG/SW_AO_002',
  c_fm_003               TYPE rs38l_fnam VALUE '/PSYNG/SW_AO_003'.

*--MACROS
DEFINE next_sort.
  add 1 to l_idx.
  ls_sort-spos      = l_idx .
  ls_sort-fieldname = &1 .
  ls_sort-up        = 'X' . "A to Z
  ls_sort-subtot    = 'X'.
  append ls_sort to et_sort .
END-OF-DEFINITION.

DEFINE hidefield.
  ls_fcat-no_out    = 'X'.
  modify pt_fieldcat from ls_fcat
                    transporting
                     no_out
                   where
                      fieldname = &1.
END-OF-DEFINITION.

DEFINE next.
  add 1 to l_colpos.
  ls_fcat-col_pos    = l_colpos.
  modify pt_fieldcat from ls_fcat
                    transporting
                     col_pos
                   where
                      fieldname = &1.
END-OF-DEFINITION.

DEFINE checkbox.
  ls_fcat-checkbox = 'X'.
  modify et_fieldcat from ls_fcat
   transporting checkbox
   where fieldname = &1.
END-OF-DEFINITION.

DEFINE adjust_text.
  clear ls_fcat.
  ls_fcat-seltext   = &2.
  ls_fcat-coltext   = &2.
  ls_fcat-fieldname = &1.
  ls_fcat-drdn_field = &5.
  if not &3 is initial.
    ls_fcat-outputlen = &3.
  endif.
  read table pt_fieldcat with key fieldname = &1
  transporting no fields.
  if sy-subrc = 0.
    modify pt_fieldcat from ls_fcat
                      transporting
                        seltext
                        coltext
                        outputlen
                     where
                        fieldname = &1.
  else.
    add 1 to l_colpos.
    ls_fcat-col_pos    = l_colpos.
    ls_fcat-outputlen = &3.
    ls_fcat-inttype   = &4.
    append ls_fcat to pt_fieldcat.
  endif.
END-OF-DEFINITION.

DEFINE get_dyn_value.
  assign component &1 of structure &2 to <fs_dynfield>.
  &3 = <fs_dynfield>.
  unassign <fs_dynfield>.
END-OF-DEFINITION.

DEFINE add_column.
  if &1 = 'X'.
    gs_fieldcat-hotspot   = &2.
    gs_fieldcat-fieldname = &3.
    gs_fieldcat-seltext   = &4.
    gs_fieldcat-coltext   = &4.
    gs_fieldcat-intlen    = &6.
    gs_fieldcat-outputlen = &6.
    gs_fieldcat-fix_column = 'X'.
    gs_fieldcat-lowercase = 'X'.
    gs_fieldcat-edit = &7.
    gs_fieldcat-emphasize = '0004'.
    append gs_fieldcat to &5.
  endif.
END-OF-DEFINITION.

DEFINE dyn_value.
  assign component &1 of structure &3 to <fs_dynfield>.
  <fs_dynfield> =  &2.
  unassign <fs_dynfield>.
END-OF-DEFINITION.

DEFINE count_all_occurences.
  delete gt_output where not varbl = &1.
  sort gt_output by low.
  delete adjacent duplicates from gt_output comparing low.

  &2 = 0.
  loop at gt_output where varbl = &1 and check = 'X'.
    add 1 to &2.
  endloop.
END-OF-DEFINITION.

DEFINE count_company_occurences.
  &3 = 0.
  loop at gt_output where abb = &1 and varbl = &2 and ( check = 'X' or
                                                        manual = 'X' ) .
    add 1 to &3.
  endloop.

*--check if there are any that are not checked
  read table gt_output with key
    abb = &1
    varbl = &2
    check = ''.
  if sy-subrc = 0.
    &4 = 'X'.
  endif.

*-- Check if there is any value manual
  read table gt_output with key
  abb = &1
  varbl = &2
  manual = 'X'.
  if sy-subrc = 0.
    &5 = 'X'.
  endif.
END-OF-DEFINITION.


*-- Check original Count
DEFINE count_original_occurences.
  &3 = 0.
  loop at gt_output where abb = &1 and varbl = &2 and manual = ' '.
    add 1 to &3.
  endloop.
END-OF-DEFINITION.

*-- Check original
DEFINE count_original_all.
  delete gt_output where not varbl = &1.
  sort gt_output by low.
  delete adjacent duplicates from gt_output comparing low.

  &2 = 0.
  loop at gt_output where varbl = &1 and manual = ' '.
    add 1 to &2.
  endloop.
END-OF-DEFINITION.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       Event Handler for Summary Table                               *
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION.
  PUBLIC SECTION .
    METHODS:
*--Hotspot click control
  handle_hotspot_click
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no.
  PRIVATE SECTION.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       Event Handler for Summary Table                               *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION .
*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
  ENDMETHOD .
ENDCLASS .

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       Event Handler for Details Table                               *
*---------------------------------------------------------------------*
CLASS lcl_event_handler_2 DEFINITION .
  PUBLIC SECTION .
    METHODS:
*-- Hotspot click control
  handle_hotspot_click
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no ,
*---  Data Changed
  data_changed FOR EVENT data_changed OF cl_gui_alv_grid
                   IMPORTING er_data_changed,
  data_changed_finished
         FOR EVENT data_changed_finished OF cl_gui_alv_grid
         IMPORTING e_modified,
  handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
                     IMPORTING e_object e_interactive,
  handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
                          IMPORTING e_ucomm.
  PRIVATE SECTION.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       Event Handler for Details Table                               *
*---------------------------------------------------------------------*
CLASS lcl_event_handler_2 IMPLEMENTATION.

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click_2 USING e_row_id e_column_id es_row_no
.
  ENDMETHOD .

  METHOD data_changed.

    DATA: ls_mod_cells TYPE lvc_s_modi,
        ls_del_rows  TYPE lvc_s_moce,
        ls_protocol  TYPE lvc_s_msg1,
        l_country TYPE string,
        l_varbl TYPE string,
        l_field TYPE string.

    FIELD-SYMBOLS : <l_ins_row> TYPE ANY,
                    <tab> TYPE STANDARD TABLE,
                    <wa> TYPE ANY,
                    <fs_dynfield1> TYPE ANY,
                    <fs_o> TYPE ANY,
                    <fs_tab> TYPE STANDARD TABLE.

    ASSIGN gr_table2->* TO <fs_tab>.

    REFRESH er_data_changed->mt_protocol.
  ENDMETHOD.

  METHOD data_changed_finished.
    DATA: ls_stable TYPE lvc_s_stbl.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD go_alvgrid2->refresh_table_display
        EXPORTING
          i_soft_refresh = 'X'
          is_stable      = ls_stable
        EXCEPTIONS
          finished       = 1
          OTHERS         = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

  ENDMETHOD.

  METHOD handle_toolbar.
    DATA: ls_toolbar TYPE stb_button.


    CLEAR ls_toolbar.
    ls_toolbar-function  = 'DISPCHG'.
    ls_toolbar-icon      = '@3I@'.
    ls_toolbar-quickinfo = 'Display/Change'(000).
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 1.
    IF gf_dispchg = gc_display.
      DELETE e_object->mt_toolbar WHERE function CS '&LOCAL&'.
    ENDIF.
  ENDMETHOD.

  METHOD handle_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.
ENDCLASS .

DATA : go_event_handler  TYPE REF TO lcl_event_handler,
     go_event_handler2 TYPE REF TO lcl_event_handler_2.

*--Selection Screen


SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME TITLE text-t03.
SELECT-OPTIONS: s_rfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll  .
*  Only analyze remote systems
PARAMETERS : p_remonl AS CHECKBOX USER-COMMAND remo.
SELECTION-SCREEN: END OF BLOCK rem_o.

SELECTION-SCREEN: BEGIN OF BLOCK fields_o WITH FRAME TITLE text-t01.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(10) text-t04 FOR FIELD sodvrsio
                                 MODIF ID exe.

PARAMETERS :
sodvrsio   TYPE /psyng/sodvrsio MEMORY ID /psyng/vrsio.
SELECTION-SCREEN PUSHBUTTON  30(25) text-t05 USER-COMMAND parse.
SELECTION-SCREEN: END OF LINE.

PARAMETERS :
p_bukrs  TYPE flag DEFAULT 'X' ,
p_ekorg  TYPE flag ,
p_werks  TYPE flag ,
p_vkorg  TYPE flag ,
p_vkorgv TYPE flag,
p_gsber  TYPE flag ,
p_spart  TYPE flag,
p_vtweg  TYPE flag,
p_kkber  TYPE flag,
p_kokrs  TYPE flag,
p_vstel  TYPE flag.
SELECTION-SCREEN: END OF BLOCK fields_o.



SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME TITLE text-t07.
PARAMETERS : p_clear AS CHECKBOX.
PARAMETERS : p_upd AS CHECKBOX.
SELECTION-SCREEN : BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  2(25) text-t08 USER-COMMAND current.
SELECTION-SCREEN : END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe_o.
*--Set this to X when calling report to not select default version
parameters : p_nodefv type flag no-display.

INITIALIZATION.
*Get sod version default
  if not p_nodefv = 'X'.
    CALL FUNCTION '/PSYNG/SW_034'
         IMPORTING
              e_vrsio = sodvrsio.
  endif.
perform parsematrix.


AT SELECTION-SCREEN.
  IF sy-ucomm = 'PARSE'.
    PERFORM parsematrix.
  ENDIF.
  IF sy-ucomm = 'CURRENT'.
    SUBMIT /psyng/sw_050 AND RETURN.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_BUKRS'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
    IF screen-name = 'P_REMONL'.
*--If the local system is not an erp system,
*  It cannot be analyzed.
      IF gf_is_erp <> 'X'.
        p_remonl = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

INITIALIZATION.
  DATA : ls_type TYPE ddtypekind.
*--Check if the local system is an ERP system and if we can execute
* the logic in this system
  gf_is_erp = 'X'.
  CALL FUNCTION 'FUNCTION_EXISTS'
       EXPORTING
            funcname           = '/PSYNG/SW_AO_001'
       EXCEPTIONS
            function_not_exist = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    CLEAR gf_is_erp.
  ELSE.
*--Double check, perhaps FM is imported, but can't be used
    CALL FUNCTION 'DDIF_TYPEINFO_GET'
         EXPORTING
              typename = 'T001'
         IMPORTING
              typekind = ls_type.
    IF ls_type IS INITIAL.
      CLEAR gf_is_erp.
    ENDIF.
  ENDIF.


START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
  gf_dispchg = gc_display.
  PERFORM load_rfc
          TABLES s_rfc
                 gt_rfcdes
          USING p_remonl.

  if p_upd = 'X'.
    EXELOG sy-repid 'UPDATE'.
  else.
    EXELOG sy-repid ''.
  endif.
  PERFORM load_data.
  CALL SCREEN '0001'.
*&---------------------------------------------------------------------*
*&      Form  load_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_S_RFC  text
*      -->P_LT_RFCDES  text
*----------------------------------------------------------------------*
FORM load_rfc
    TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes
    USING
      i_remonly TYPE flag.
  .
  DATA : l_rfcdest TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys TYPE rfcdest,
         l_continue type flag,
         l_cancel   type flag
         .
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  IF NOT it_user_rfc[] IS INITIAL.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup       = 'X'
            i_module      = 'SE'
            I_MIN_VERSION = '3.1'
       IMPORTING
            e_cancel   = l_cancel
            e_continue = l_continue
       TABLES
            it_rfcdes  = it_user_rfc.
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.
*--Load RFC destinations
    SELECT rfcdest FROM rfcdes
           INTO CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_user_rfc.
  ENDIF.
  IF i_remonly <> 'X'.
*--Include local system
    et_rfcdes-rfcdest = ''.
    APPEND et_rfcdes.
  ENDIF.
*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
  AND rfcdest <> ''.
* If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.

ENDFORM.                    " validate_user_rfc
*&---------------------------------------------------------------------*
*&      Form  load_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM load_data.
  DATA : lt_swsodorgm TYPE TABLE OF /PSYNG/SWCFGOE WITH HEADER LINE,
         lt_bapiret2 TYPE TABLE OF bapiret2 WITH HEADER LINE,
         lt_values   TYPE TABLE OF /psyng/sw_org_values_text
         WITH HEADER LINE.
  REFRESH :  lt_swsodorgm, lt_values, lt_bapiret2.
  LOOP AT gt_rfcdes.
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

    CALL FUNCTION c_fm_001 "#EC PATHLOCK_CI_DYN_ACCES
      DESTINATION gt_rfcdes-rfcdest
     EXPORTING
       if_bukrs           = p_bukrs
       if_ekorg           = p_ekorg
       if_werks           = p_werks
       if_vkorg           = p_vkorg
       if_val_cal         = p_vkorgv
       if_gsber           = p_gsber
       if_spart           = p_spart
       if_vtweg           = p_vtweg
       if_kkber           = p_kkber
       if_kokrs           = p_kokrs
       if_vstel           = p_vstel
      TABLES
        et_swsodorgm      = lt_swsodorgm
       et_return          = lt_bapiret2
       et_values          = lt_values
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
       EXCEPTIONS
         SYSTEM_FAILURE = 1
         COMMUNICATION_FAILURE = 2
         OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
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

    SORT lt_values BY field low.

    LOOP AT lt_swsodorgm.
      CLEAR gt_output.
      gt_output-check   = 'X'.
      gt_output-icon    = c_icon_green.
      gt_output-rfcdest = gt_rfcdes-rfcoptions.
      MOVE-CORRESPONDING lt_swsodorgm TO gt_output.
      gt_output-low = lt_swsodorgm-value.
      READ TABLE lt_values WITH KEY field = lt_swsodorgm-varbl
                                    low   = lt_swsodorgm-value
                                    BINARY SEARCH
                                    TRANSPORTING vtext
                                    .
      IF sy-subrc = 0.
        gt_output-label = lt_values-vtext.
      ENDIF.
      APPEND gt_output.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " load_data

INCLUDE /PSYNG/SW_AUTO_ORG_REL_PBO.
*INCLUDE /psyng/sw_auto_org_pbo.
*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv.
*--Prepare data for output depending on output mode.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE.
  REFRESH : gt_fieldcat.
  CASE g_alv_status.
    WHEN 'SUMMARY'.
      PERFORM create_summary_table CHANGING gr_table gt_fieldcat.
      ASSIGN gr_table->* TO <fs_tab>.
      PERFORM init_screen_1 USING <fs_tab>.
    WHEN 'DETAIL'.
      PERFORM create_detail_table CHANGING gr_table2 gt_fieldcat.
      ASSIGN gr_table2->* TO <fs_tab>.
      PERFORM init_screen_2  USING <fs_tab>.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " display_alv

*---------------------------------------------------------------------*
*       FORM init_screen_1                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABLE                                                      *
*---------------------------------------------------------------------*
FORM init_screen_1 USING it_table.
*  DATA : lt_sort TYPE lvc_t_sort.
  IF NOT go_alvgrid IS INITIAL .
    CALL METHOD go_alvgrid->get_filter_criteria
      IMPORTING
        et_filter = gt_filter.
    CALL METHOD go_alvgrid->get_sort_criteria
      IMPORTING
        et_sort = gt_sort.
    CALL METHOD go_alvgrid->free.
  ENDIF.

  IF gt_sort[] IS INITIAL.
*--Create the initial sort table?
  ENDIF.

  IF go_ccontainer IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_ccontainer
    EXPORTING
      container_name = 'CC_ALV'
    EXCEPTIONS
      cntl_error = 1
      cntl_system_error = 2
      create_error = 3
      lifetime_error = 4
      lifetime_dynpro_dynpro_link = 5
      others = 6 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.
*----Creating ALV Grid instance
  CREATE OBJECT go_alvgrid
  EXPORTING
    i_parent = go_ccontainer
  EXCEPTIONS
    error_cntl_create = 1
    error_cntl_init = 2
    error_cntl_link = 3
    error_dp_create = 4
    others = 5 .

  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
  CREATE OBJECT go_event_handler.
  SET HANDLER go_event_handler->handle_hotspot_click
  FOR go_alvgrid .
*  SET HANDLER go_event_handler->set_fixed_rows_public
*  FOR go_alvgrid .
*----Preparing layout structure
  PERFORM prepare_layout CHANGING gs_layout .
  gs_layout-info_fname = 'INFO'.
  CALL METHOD go_alvgrid->set_table_for_first_display
  EXPORTING
    is_layout = gs_layout
  CHANGING
    it_outtab       = it_table
    it_fieldcatalog = gt_fieldcat
    it_sort         = gt_sort
    it_filter       = gt_filter
    EXCEPTIONS
    invalid_parameter_combination = 1
    program_error = 2
    too_many_lines = 3
    OTHERS = 4 .
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
*       FORM init_screen_2                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_TABLE                                                      *
*---------------------------------------------------------------------*
FORM init_screen_2 USING it_table.
*  DATA : lt_sort TYPE lvc_t_sort.
  IF NOT go_alvgrid2 IS INITIAL .
    CALL METHOD go_alvgrid2->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_enter.

    CALL METHOD go_alvgrid2->register_edit_event
      EXPORTING
        i_event_id = cl_gui_alv_grid=>mc_evt_modified.


    CALL METHOD go_alvgrid2->get_filter_criteria
      IMPORTING
        et_filter = gt_filter2.

    CALL METHOD go_alvgrid2->get_sort_criteria
      IMPORTING
        et_sort = gt_sort2.
    CALL METHOD go_alvgrid2->free.
  ENDIF.

  IF go_ccontainer2 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_ccontainer2
    EXPORTING
      container_name = 'CC_ALV2'
    EXCEPTIONS
      cntl_error = 1
      cntl_system_error = 2
      create_error = 3
      lifetime_error = 4
      lifetime_dynpro_dynpro_link = 5
      others = 6 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.
*----Creating ALV Grid instance
*  IF go_alvgrid2 IS INITIAL.
  CREATE OBJECT go_alvgrid2
  EXPORTING
    i_parent = go_ccontainer2
  EXCEPTIONS
    error_cntl_create = 1
    error_cntl_init = 2
    error_cntl_link = 3
    error_dp_create = 4
    others = 5 .
*  ENDIF.

  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
  CREATE OBJECT go_event_handler2.
  SET HANDLER go_event_handler2->handle_hotspot_click
  FOR go_alvgrid2.
  SET HANDLER go_event_handler2->handle_user_command FOR go_alvgrid2.
  SET HANDLER go_event_handler2->handle_toolbar FOR go_alvgrid2.
  SET HANDLER go_event_handler2->data_changed FOR go_alvgrid2.
  SET HANDLER go_event_handler2->data_changed_finished
                FOR go_alvgrid2..
*----Preparing layout structure
  PERFORM prepare_layout CHANGING gs_layout2.

  PERFORM exculde_toolbar.
  gs_layout2-info_fname = 'INFO'.
  CALL METHOD go_alvgrid2->set_table_for_first_display
  EXPORTING
    is_layout = gs_layout2
    it_toolbar_excluding = gt_exc_toolbar
  CHANGING
    it_outtab       = it_table
    it_fieldcatalog = gt_fieldcat
    it_sort         = gt_sort2
    it_filter       = gt_filter2
    EXCEPTIONS
    invalid_parameter_combination = 1
    program_error = 2
    too_many_lines = 3
    OTHERS = 4 .
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

  IF gf_dispchg = 'D'.
    CALL METHOD go_alvgrid2->set_ready_for_input
        EXPORTING i_ready_for_input = 0.
  ELSE.
    CALL METHOD go_alvgrid2->set_ready_for_input
  EXPORTING i_ready_for_input = 1.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM prepare_field_catalog                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  PT_FIELDCAT                                                   *
*---------------------------------------------------------------------*
FORM prepare_field_catalog CHANGING pt_fieldcat TYPE lvc_t_fcat .

  DATA : ls_fcat TYPE lvc_s_fcat,
         l_colpos TYPE i.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SWSODORGM'
       CHANGING
            ct_fieldcat            = pt_fieldcat[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
  DESCRIBE TABLE pt_fieldcat LINES l_colpos.
  adjust_text 'LABEL'
              'Label'(t01) 30 'C' ''.
  adjust_text 'RFCDEST'
              'System'(t02) 30 'C' ''.

  adjust_text 'ICON'
              'Use'(t06) 3 'C' ''.
  adjust_text 'CHECK'
              'Use'(t06) 3 'C' ''.

  hidefield 'OBJECT'.

  l_colpos = 0.
  next 'RFCDEST'.
  next 'ABB'.
  next 'VARBL'.
  next 'LABEL'.
  next 'LOW'.
  hidefield 'HIGH'.
  ls_fcat-icon = 'X'.
  ls_fcat-hotspot = 'X'.
  ls_fcat-checkbox = 'X'.

  MODIFY pt_fieldcat FROM ls_fcat
                          TRANSPORTING
                            icon
                            hotspot
                         WHERE
                            fieldname = 'ICON'.
  MODIFY pt_fieldcat FROM ls_fcat
                          TRANSPORTING
                            checkbox
                            hotspot
                         WHERE
                            fieldname = 'CHECK'.

ENDFORM .







*---------------------------------------------------------------------*
*       FORM prepare_layout                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_LAYOUT                                                     *
*---------------------------------------------------------------------*
FORM prepare_layout CHANGING is_layout TYPE lvc_s_layo.
  is_layout-zebra = 'X' .
  is_layout-grid_title =
  'Separations Enforcer - Auto Org Level Determination'(l01) .
  is_layout-smalltitle = 'X' .
  is_layout-stylefname = 'CELLSTYLES'.
  is_layout-cwidth_opt = 'X'.
ENDFORM. " prepare_layout


*---------------------------------------------------------------------*
*       FORM prepare_sort_table                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SORT                                                       *
*---------------------------------------------------------------------*
FORM prepare_sort_table CHANGING et_sort TYPE lvc_t_sort .
  DATA : ls_sort TYPE lvc_s_sort,
         l_idx   LIKE sy-tabix.

  REFRESH et_sort.
  l_idx = 0.
  next_sort 'RFCDEST'.
  next_sort 'ABB'.
  next_sort 'VARBL'.
  next_sort 'LABEL'.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM refresh_alv                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM refresh_alv USING i_alv TYPE REF TO cl_gui_alv_grid.
  DATA : ls_stable TYPE  lvc_s_stbl .
  ls_stable-row = 'X'.

  CALL METHOD i_alv->refresh_table_display
   EXPORTING
     is_stable = ls_stable
     i_soft_refresh = 'X'
  EXCEPTIONS
    finished = 1
    OTHERS = 2 .
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
ENDFORM.                    " refresh_alv
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0001 INPUT.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE.
  IF sy-ucomm = 'PROCESS'.
    PERFORM process_configuration.
    SET SCREEN 0.
    LEAVE SCREEN.
  ELSEIF sy-ucomm = 'REFRESH'.
    PERFORM create_summary_table CHANGING gr_table gt_fieldcat.
    ASSIGN gr_table->* TO <fs_tab>.
    PERFORM init_screen_1 USING <fs_tab>.
  ELSEIF sy-ucomm = 'CURRENT'.
    SUBMIT /psyng/sw_050 AND RETURN.
  ELSEIF NOT sy-ucomm IS INITIAL.
*-- exit
    SET SCREEN 0.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.                 " USER_COMMAND_0001  INPUT

*---------------------------------------------------------------------*
*       MODULE user_command_0002 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0002 INPUT.
*BOC UMITTAL ATC fixes for BMW PN1269
  CONSTANTS: lc_ref(7)  VALUE 'REFRESH',
             lc_cur(7)  VALUE 'CURRENT',
             lc_save(4) VALUE 'SAVE',
             lc_back(4) VALUE 'BACK',
             lc_canc(6) VALUE 'CANCEL',
             lc_exit(4) VALUE 'EXIT'.

  IF sy-ucomm = lc_ref.
*  IF sy-ucomm = 'REFRESH'.
    REFRESH : gt_fieldcat.
    PERFORM create_detail_table CHANGING gr_table2 gt_fieldcat.
    ASSIGN gr_table2->* TO <fs_tab>.
    PERFORM init_screen_2 USING <fs_tab>.
*  ELSEIF sy-ucomm = 'CURRENT'.
  ELSEIF sy-ucomm = lc_cur.
    SUBMIT /psyng/sw_050 AND RETURN.
  ELSEIF sy-ucomm = lc_save.
*  ELSEIF sy-ucomm = 'SAVE'.
    CALL METHOD go_alvgrid2->check_changed_data.
    PERFORM save_details.
*  ELSEIF sy-ucomm = 'BACK' OR sy-ucomm = 'CANCEL' OR sy-ucomm = 'EXIT'.
  ELSEIF sy-ucomm = lc_back OR sy-ucomm = lc_canc OR sy-ucomm = lc_exit.
*EOC UMITTAL ATC fixes for BMW PN1269
    PERFORM create_summary_table CHANGING gr_table gt_fieldcat.
    ASSIGN gr_table->* TO <fs_tab>.
    PERFORM init_screen_1 USING <fs_tab>.
*-- exit
    SET SCREEN 0.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.                 " USER_COMMAND_0001  INPUT


*---------------------------------------------------------------------*
*       FORM handle_hotspot_click                                     *
*---------------------------------------------------------------------*
*      Toggle checkbox and traffic light                              *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                  <fs_o> TYPE ANY
                    .
  DATA : lr_rec   TYPE REF TO data,
         l_bukrs TYPE /PSYNG/DORG_ABB,
         lf_check TYPE flag.

  ASSIGN gr_table->* TO <fs_tab>.
  READ TABLE <fs_tab> INDEX i_row_id-index
  ASSIGNING <fs_o>.
  IF sy-subrc = 0.
    get_dyn_value 'BUKRS'  <fs_o>  l_bukrs.
    IF i_column_id <> 'CHECK' AND i_column_id <> 'ICON'.
*  --Show Details
      g_bukrs = l_bukrs.
      g_field = i_column_id-fieldname.
      g_alv_status = 'DETAIL'.
      CALL SCREEN '0002'.
    ELSE.
*  --Disable all records with this ABB
      get_dyn_value 'CHECK'  <fs_o>  lf_check.
      IF lf_check  = 'X'.
        gt_output-icon = c_icon_red.
        CLEAR gt_output-check.
      ELSE.
        gt_output-icon  = c_icon_green.
        gt_output-check = 'X'.
      ENDIF.
      MODIFY gt_output
        TRANSPORTING check icon
        WHERE abb = l_bukrs.
      FREE : gr_table.
      REFRESH : gt_fieldcat.
      PERFORM create_summary_table CHANGING gr_table gt_fieldcat.
      ASSIGN gr_table->* TO <fs_tab>.
      PERFORM init_screen_1 USING <fs_tab>.
    ENDIF.
  ENDIF.
ENDFORM .

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click_2                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click_2 USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                  <fs_o> TYPE ANY
                    .
  DATA : lr_rec   TYPE REF TO data,
         l_bukrs(4) TYPE c,
         lf_check TYPE flag,
         l_value(4) TYPE c,
         l_field    TYPE string,
         l_label TYPE string,
         l_high(4) TYPE c,
         l_count TYPE string.

  ASSIGN gr_table2->* TO <fs_tab>.
  READ TABLE <fs_tab> INDEX i_row_id-index
  ASSIGNING <fs_o>.
  IF sy-subrc = 0.
    IF i_column_id = 'CHECK' OR i_column_id = 'ICON'.
      get_dyn_value 'COUNTRY' <fs_o>  l_bukrs.
      get_dyn_value 'VALUE'   <fs_o>  l_value.
      get_dyn_value 'VARBL'   <fs_o>  l_field.
      get_dyn_value 'CHECK'   <fs_o>  lf_check.
*  --Disable/enable this record
      IF lf_check  = 'X'.
        gt_output-icon = c_icon_red.
        CLEAR gt_output-check.
      ELSE.
        gt_output-icon  = c_icon_green.
        gt_output-check = 'X'.
      ENDIF.
      MODIFY gt_output
        TRANSPORTING check icon
        WHERE abb   = l_bukrs AND
              varbl = l_field AND
              low   = l_value.
      IF sy-subrc NE 0.
        get_dyn_value 'LABEL'  <fs_o>  l_label.
*        get_dyn_value 'HIGH'  <fs_o>  l_high.
        get_dyn_value 'COUNTRY'  <fs_o>  l_count.
        gt_output-country = l_count.
        gt_output-abb = l_bukrs.
        gt_output-varbl = l_field.
        gt_output-low = l_value.
        gt_output-label = l_label.
*        gt_output-high = l_high.
        gt_output-manual = 'X'.
        APPEND gt_output.
      ENDIF.
      FREE : gr_table2.
      REFRESH : gt_fieldcat.
      PERFORM create_detail_table CHANGING gr_table2 gt_fieldcat.
      ASSIGN gr_table2->* TO <fs_tab>.
      PERFORM init_screen_2 USING <fs_tab>.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  process_configuration
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_configuration.
DATA : lt_swsodorgm_in  TYPE TABLE OF /psyng/swsodorgm WITH HEADER LINE,
       lt_swsodorgm_out TYPE TABLE OF /psyng/swsodorgm WITH HEADER LINE.

  LOOP AT gt_output WHERE check = 'X'.
    MOVE-CORRESPONDING gt_output TO lt_swsodorgm_in.
    if gt_output-country is initial.
      PERFORM get_abb_for_bukrs
                  USING
                     gt_output-abb
                  CHANGING
                     gt_output-country.
    endif.
    lt_swsodorgm_in-abb = gt_output-country.
    APPEND lt_swsodorgm_in.
  ENDLOOP.


*--Check if we configured any org area's that aren't in the SOD Matrix
*  and warn the user about that
  DATA :
  lt_orgfield      TYPE TABLE OF /psyng/orgfield WITH HEADER LINE,
  lt_unique_orgs   type table of /psyng/swsodorgm with header line,
  lf_org_not_in_mtrx type flag.
  PERFORM get_matrix_fields
              TABLES
                 lt_orgfield.
  lt_unique_orgs[] = lt_swsodorgm_in[].
  sort lt_unique_orgs by varbl.
  delete adjacent duplicates from lt_unique_orgs comparing varbl.
  sort lt_orgfield by field.
  loop at lt_unique_orgs.
    read table lt_orgfield with key field = lt_unique_orgs-varbl
    binary search transporting no fields.
    if sy-subrc <> 0.
      lf_org_not_in_mtrx = 'X'.
      exit.
    endif.
  endloop.
  if lf_org_not_in_mtrx = 'X'.
    MESSAGE i006(/psyng/sw).
*   Org Areas selected that are not in SOD Matrix will not be added.

  endif.
  PERFORM load_rfc
          TABLES s_rfc
                 gt_rfcdes
          USING p_remonl.
  CALL FUNCTION c_fm_003 "#EC PATHLOCK_CI_DYN_ACCES
       EXPORTING
            i_sodvrsio     = sodvrsio
            i_update_table = p_upd
            i_clear_table  = p_clear
       TABLES
            et_swsodorgm   = lt_swsodorgm_out
            it_swsodorgm   = lt_swsodorgm_in
            it_rfcdes      = gt_rfcdes.
  IF p_upd = 'X'.
    EXELOG sy-repid 'APPLY'.
    MESSAGE s002(/psyng/sw) WITH
    'Org level Values Configuration applied to'(m01)
    'Separations Enforcer'(m02).
  ENDIF.
ENDFORM.                    " process_configuration

form get_matrix_fields tables et_orgfield.
  DATA :
  lt_orgfield      TYPE TABLE OF /psyng/orgfield WITH HEADER LINE,
  lt_faobj         TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
  lt_orgfield_all  TYPE TABLE OF /psyng/orgfield WITH HEADER LINE.

  PERFORM load_rfc
          TABLES s_rfc
                 gt_rfcdes
          USING p_remonl.
*--find all relevant Org Area's for this SOD Matrix version and
*  set appropriate checkboxes
*  IF NOT p_remonl = 'X'.
*    SELECT DISTINCT object FROM /psyng/faobj2
*    INTO CORRESPONDING FIELDS OF TABLE lt_faobj
*    WHERE vrsio = sodvrsio.
*  ENDIF.
*--Parse Matrix on all systems
  LOOP AT gt_rfcdes.
    refresh : lt_faobj.
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

    CALL FUNCTION c_fm_002 "#EC PATHLOCK_CI_DYN_ACCES
         DESTINATION gt_rfcdes-rfcdest
         EXPORTING
              i_sodvrsio = sodvrsio
         TABLES
              et_varbls  = lt_orgfield
              it_faobj   = lt_faobj
         EXCEPTIONS
               SYSTEM_FAILURE = 1
               COMMUNICATION_FAILURE = 2
               VERSION_NO_EXIST = 3
               others           = 4. "#EC SAST_CI_GEN_CHECK
    if sy-subrc <> 0.
      case sy-subrc.
        when 3.
          MESSAGE e002(/psyng/sw) WITH 'SOD Matrix version' sodvrsio
          'not found on ' gt_rfcdes-rfcoptions.
        when 4.
          MESSAGE e002(/psyng/sw) WITH
          'SOD Matrix parsing failed on ' gt_rfcdes-rfcoptions '' ''.
        WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
      endcase.
    endif.
    APPEND LINES OF lt_orgfield TO lt_orgfield_all.
    REFRESH : lt_orgfield.
  ENDLOOP.
  SORT lt_orgfield_all.
  DELETE ADJACENT DUPLICATES FROM lt_orgfield_all.
  lt_orgfield[] = lt_orgfield_all[].
  FREE : lt_orgfield_all.
  et_orgfield[] = lt_orgfield[].
endform.

*---------------------------------------------------------------------*
*       FORM parsematrix                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM parsematrix.
  DATA :
  lt_orgfield      TYPE TABLE OF /psyng/orgfield WITH HEADER LINE.
  PERFORM get_matrix_fields
              TABLES
                 lt_orgfield.


  CLEAR : p_bukrs,
  p_ekorg,
  p_werks,
  p_vkorg,
  p_gsber,
  p_spart,
  p_vtweg,
  p_kkber,
  p_kokrs,
  p_vkorgv.
  p_bukrs = 'X'.
  LOOP AT lt_orgfield.
    IF lt_orgfield-varbl = '$EKORG'.
      p_ekorg = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$VKORG'.
      p_vkorg = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$GSBER'.
      p_gsber = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$SPART'.
      p_spart = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$VTWEG'.
      p_vtweg = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$KKBER'.
      p_kkber = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$WERKS'.
      p_werks = 'X'.
    ENDIF.
    IF lt_orgfield-varbl = '$KOKRS'.
      p_kokrs = 'X'.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " parsematrix
*&---------------------------------------------------------------------*
*&      Form  create_summary_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_<FS_TAB>  text
*      <--P_GR_TABLE  text
*----------------------------------------------------------------------*
FORM create_summary_table CHANGING er_table TYPE REF TO data
                                   et_fieldcat TYPE lvc_t_fcat.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                  <fs_o> TYPE ANY.
  STATICS: st_fieldcat TYPE lvc_t_fcat,
           st_table  TYPE REF TO data.
  DATA : lr_rec   TYPE REF TO data .
  DATA : ls_fcat TYPE lvc_s_fcat,
         ls_sort TYPE lvc_s_sort.
  IF st_fieldcat[] IS INITIAL.
*--Create an output table with only those org fields that
*  are selected as columns
    add_column 'X' ' ' 'COUNTRY'
      'Org. Area Abb.' et_fieldcat 12 ''.
    add_column p_bukrs 'X' 'BUKRS'
      'Company Code'            et_fieldcat 4 ''.
    add_column 'X'     '' 'DESC'
      'Description'             et_fieldcat 50 ''.
    add_column p_ekorg 'X' 'EKORG'
      'Purchasing Organization' et_fieldcat 12  ''.
    add_column p_werks 'X' 'WERKS'
      'Plant'                   et_fieldcat 12  ''.
    add_column p_vkorg 'X' 'VKORG'
      'Sales Organization'      et_fieldcat 12  ''.
    add_column p_gsber 'X' 'GSBER'
      'Business Area'           et_fieldcat 12  ''.
    add_column p_spart 'X' 'SPART'
      'Division'                et_fieldcat 12  ''.
    add_column p_vtweg 'X' 'VTWEG'
      'Distribution Channel'    et_fieldcat 12  ''.
    add_column p_kkber 'X' 'KKBER'
      'Credit Control Area'     et_fieldcat 12  ''.
    add_column p_kokrs 'X' 'KOKRS'
      'Control Area'            et_fieldcat 12  ''.
    add_column p_vstel 'X' 'VSTEL'
      'Shipping Point'          et_fieldcat 12  ''.
    add_column 'X' 'X' 'CHECK'
      'Toggle'                  et_fieldcat 12  ''.
    checkbox 'CHECK'.
    add_column 'X' ' ' 'ICON'
      'Active'                  et_fieldcat 12 ''.
*--Create a  Info column for line colouring
    add_column 'X'     'X' 'INFO'
      ''                        et_fieldcat 12 'X'.
*--Create a sort table if not yet done
    IF gt_sort[] IS INITIAL.
      ls_sort-up   = 'X'.
      ls_sort-spos = '1'.
      ls_sort-fieldname = 'DESC'.
      APPEND ls_sort TO gt_sort.
      ADD 1 TO ls_sort-spos.
      ls_sort-fieldname = 'BUKRS'.

      APPEND ls_sort TO gt_sort.
    ENDIF.
*--Create a dynamic table to contain our data
    CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = et_fieldcat
    IMPORTING
      ep_table                  = er_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
*--Buffer table in static variable
    st_fieldcat[] = et_fieldcat[].
    st_table = er_table.
  ELSE.
*--Use static buffered variable
    et_fieldcat[] = st_fieldcat[].
    er_table = st_table.
  ENDIF.

  ASSIGN er_table->* TO <fs_tab>.
  REFRESH : <fs_tab>.
  CREATE DATA lr_rec LIKE LINE OF <fs_tab>.
  ASSIGN lr_rec->* TO <fs_o>.

  DATA : lt_bukrs LIKE TABLE OF gt_output WITH HEADER LINE,
         l_cnt_disp(10)   TYPE c,
         l_cnt_orig(10)   TYPE c,
         l_cnt(10)    TYPE c,
         l_txt(50)    TYPE c,
         l_bukrs      type string,
         l_ekorg      type string.
  lt_bukrs[] = gt_output[].
  SORT lt_bukrs BY abb.
  DELETE ADJACENT DUPLICATES FROM lt_bukrs COMPARING abb.
*--Load the data into the summary table
*--First record contains the counts for ALL company codes.

  gt_output_temp[] = gt_output[].

  count_all_occurences 'BUKRS' l_cnt.
  gt_output[] = gt_output_temp[].

  dyn_value 'BUKRS' 'ALL' <fs_o>  .
  l_txt  = l_cnt.
  CONDENSE l_txt.
  CONCATENATE space l_txt 'Company Codes' INTO l_txt SEPARATED BY space.
  dyn_value 'DESC'  l_txt <fs_o>  .
  IF p_ekorg = 'X'.
    count_all_occurences 'EKORG' l_cnt_disp.
    count_original_all  'EKORG' l_cnt_orig.
    gt_output[] = gt_output_temp[].
    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'EKORG'  l_cnt <fs_o>  .
  ENDIF.
  IF p_werks = 'X'.
    count_all_occurences 'WERKS' l_cnt_disp.
    count_original_all  'WERKS' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'WERKS'  l_cnt <fs_o>  .
  ENDIF.
  IF p_vkorg = 'X'.
    count_all_occurences 'VKORG' l_cnt_disp.
    count_original_all  'VKORG' l_cnt_orig.
    gt_output[] = gt_output_temp[].
    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'VKORG'  l_cnt <fs_o>  .
  ENDIF.
  IF p_gsber = 'X'.
    count_all_occurences 'GSBER' l_cnt_disp.
    count_original_all  'GSBER' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'GSBER'  l_cnt <fs_o>  .
  ENDIF.
  IF p_spart = 'X'.
    count_all_occurences 'SPART' l_cnt_disp.
    count_original_all  'SPART' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'SPART'  l_cnt <fs_o>  .
  ENDIF.
  IF p_vtweg = 'X'.
    count_all_occurences 'VTWEG' l_cnt_disp.
    count_original_all  'VTWEG' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'VTWEG'  l_cnt <fs_o>  .
  ENDIF.
  IF p_kkber = 'X'.
    count_all_occurences 'KKBER' l_cnt_disp.
    count_original_all  'KKBER' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'KKBER'  l_cnt <fs_o>  .
  ENDIF.
  IF p_kokrs = 'X'.
    count_all_occurences 'KOKRS' l_cnt_disp.
    count_original_all  'KOKRS' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'KOKRS'  l_cnt <fs_o>  .
  ENDIF.
  IF p_vstel = 'X'.
    count_all_occurences 'VSTEL' l_cnt_disp.
    count_original_all  'VSTEL' l_cnt_orig.
    gt_output[] = gt_output_temp[].

    CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
    CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
    dyn_value 'VSTEL'  l_cnt <fs_o>  .
  ENDIF.

  APPEND <fs_o> TO <fs_tab>.

*--Add record per  company codes.
  lt_bukrs[] = gt_output[].
  SORT lt_bukrs BY abb.
  delete adjacent duplicates from lt_bukrs comparing abb.
  DATA : lf_unckeched TYPE flag,
         lf_manual TYPE flag,
         l_country(20) TYPE c.


  LOOP AT lt_bukrs ."WHERE varbl = 'BUKRS'.
    CLEAR : lf_unckeched,lf_manual.
    CLEAR l_country.
    PERFORM get_abb_for_bukrs
     using
                   lt_bukrs-abb
                CHANGING
                   l_country
                  .

    gt_output-country = l_country.
    MODIFY gt_output TRANSPORTING country WHERE varbl = 'BUKRS'
                                          AND abb = lt_bukrs-abb.

    dyn_value 'COUNTRY' l_country <fs_o>.
    dyn_value 'BUKRS' lt_bukrs-abb <fs_o>  .



*--Get the description
    if   lt_bukrs-abb cs '_'.
*--This is a combination of Comp Code and Purch Org
      split lt_bukrs-abb  at '_' into l_bukrs l_ekorg.
      read table gt_output with key varbl = 'BUKRS' low = l_bukrs.
      lt_bukrs-label = gt_output-label.
      read table gt_output with key varbl = 'EKORG' low = l_ekorg.
      concatenate lt_bukrs-label '-' gt_output-label
      into lt_bukrs-label separated by space.
    else.
      read table gt_output with key varbl = 'BUKRS' low = lt_bukrs-abb.
      lt_bukrs-label = gt_output-label.
    endif.

    dyn_value 'DESC'  lt_bukrs-label <fs_o>  .
    IF p_ekorg = 'X'.
  count_company_occurences lt_bukrs-abb 'EKORG' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'EKORG' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'EKORG'  l_cnt <fs_o>  .
    ENDIF.
    IF p_werks = 'X'.
  count_company_occurences lt_bukrs-abb 'WERKS' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'WERKS' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'WERKS'  l_cnt <fs_o>  .
    ENDIF.
    IF p_vkorg = 'X'.
  count_company_occurences lt_bukrs-abb 'VKORG' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'VKORG' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'VKORG'  l_cnt <fs_o>  .
    ENDIF.
    IF p_gsber = 'X'.
  count_company_occurences lt_bukrs-abb 'GSBER' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'GSBER' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'GSBER'  l_cnt <fs_o>  .
    ENDIF.
    IF p_spart = 'X'.
  count_company_occurences lt_bukrs-abb 'SPART' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'SPART' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'SPART'  l_cnt <fs_o>  .
    ENDIF.
    IF p_vtweg = 'X'.
  count_company_occurences lt_bukrs-abb 'VTWEG' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'VTWEG' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'VTWEG'  l_cnt <fs_o>  .
    ENDIF.
    IF p_kkber = 'X'.
  count_company_occurences lt_bukrs-abb 'KKBER' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'KKBER' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'KKBER'  l_cnt <fs_o>  .
    ENDIF.
    IF p_kokrs = 'X'.
  count_company_occurences lt_bukrs-abb 'KOKRS' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'KOKRS' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'KOKRS'  l_cnt <fs_o>  .
    ENDIF.
    IF p_vstel = 'X'.
  count_company_occurences lt_bukrs-abb 'VSTEL' l_cnt_disp lf_unckeched
                                                              lf_manual.
      count_original_occurences lt_bukrs-abb 'VSTEL' l_cnt_orig.
      CONDENSE : l_cnt_disp, l_cnt_orig NO-GAPS.
      CONCATENATE l_cnt_disp l_cnt_orig INTO l_cnt SEPARATED BY '/'.
      dyn_value  'VSTEL'  l_cnt <fs_o>  .
    ENDIF.

    dyn_value  'ICON'  lt_bukrs-icon <fs_o>  .
    dyn_value  'CHECK'  lt_bukrs-check <fs_o>  .
    IF lf_manual = 'X'.
*--If any underlying value is manual, give row a different color
      dyn_value 'INFO' 'C300' <fs_o>.
    ELSE.
      IF lf_unckeched = 'X'.
*--If any underlying value is unchecked, give row a different color
        dyn_value 'INFO' 'C300' <fs_o>.
      ELSE.
        dyn_value 'INFO' 'C200' <fs_o>.
      ENDIF.
    ENDIF.

    APPEND <fs_o> TO <fs_tab>.
  ENDLOOP.

*--Delete Info column for line colouring from field catalog
  DELETE et_fieldcat WHERE fieldname = 'INFO'.


ENDFORM.                    " create_summary_table

*---------------------------------------------------------------------*
*       FORM get_abb_for_bukrs                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  E_COUNTRY                                                     *
*  -->  IMPORTING                                                     *
*  -->  I_ABB                                                         *
*---------------------------------------------------------------------*
FORM get_abb_for_bukrs using i_abb
                       CHANGING e_country
                          .
  DATA : swconfig TYPE /psyng/swconfig,
           l_funcname TYPE rs38l-name.
  CLEAR swconfig.
  se_config_param 'ORG_LEVEL' swconfig-value.

  IF NOT swconfig-value IS INITIAL.
    l_funcname = swconfig-value.
  ELSE.
    l_funcname = '/PSYNG/SW_122'.
  ENDIF.
  CALL FUNCTION 'FUNCTION_EXISTS'
       EXPORTING
            funcname           = l_funcname
       EXCEPTIONS
            function_not_exist = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    CLEAR l_funcname.
  ENDIF.
  IF NOT l_funcname IS INITIAL.
    CALL FUNCTION l_funcname "#EC PATHLOCK_CI_DYN_ACCES
         EXPORTING
              input  = i_abb
         IMPORTING
              output = e_country.
  ELSE.
    e_country = i_abb.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM create_detail_table                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ER_TABLE                                                      *
*---------------------------------------------------------------------*
FORM create_detail_table CHANGING er_table TYPE REF TO data
                                   et_fieldcat TYPE lvc_t_fcat.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                  <fs_o> TYPE ANY
                  .
  DATA : lr_rec   TYPE REF TO data.
  DATA : ls_fcat TYPE lvc_s_fcat,
         l_field TYPE string,
         l_abb   TYPE /PSYNG/DORG_ABB,
         ls_sort TYPE lvc_s_sort.
  STATICS: st_fieldcat TYPE lvc_t_fcat,
           st_table  TYPE REF TO data.
  IF st_fieldcat[] IS INITIAL.

*--Create an output table with only those org fields that
*  are selected as columns
    add_column 'X' '' 'COUNTRY' 'Org. Area Abb.'  et_fieldcat 12 'X'.
    add_column 'X' '' 'VARBL' 'Field'             et_fieldcat 10 'X'.
    add_column 'X' '' 'FIELD' 'Field Name'        et_fieldcat 50 'X'.
    add_column 'X' '' 'VALUE' 'Value'             et_fieldcat 4 'X'.
    add_column 'X' '' 'LABEL' 'Value Description' et_fieldcat 50 'X'.
    add_column 'X' '' 'BUKRS' 'Company Code'      et_fieldcat 4 'X'.
    add_column 'X' '' 'DESC'  'Description'       et_fieldcat 50 'X'.
    add_column 'X' 'X' 'CHECK' 'Toggle'          et_fieldcat 4 'X'.
    checkbox 'CHECK'.
    add_column 'X' ' ' 'ICON'  'Active'          et_fieldcat 4 'X'.
*--Create a  Info column for line colouring
add_column 'X'     'X' 'INFO' ''                      et_fieldcat 4 ' '.
*--Create a dynamic table to contain our data
    CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = et_fieldcat
    IMPORTING
      ep_table                  = er_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                 WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
*--Buffer table in static variable
    st_fieldcat[] = et_fieldcat[].
    st_table = er_table.
  ELSE.
*--Use static buffered variable
    et_fieldcat[] = st_fieldcat[].
    er_table = st_table.
  ENDIF.

*--Create a sort table if not yet done
  IF gt_sort2[] IS INITIAL.
    ls_sort-up   = 'X'.
    ls_sort-spos = '1'.
    ls_sort-fieldname = 'COUNTRY'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'VARBL'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'FIELD'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'VALUE'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'LABEL'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'BUKRS'.
    APPEND ls_sort TO gt_sort2.
    ADD 1 TO ls_sort-spos.
    ls_sort-fieldname = 'DESC'.
    APPEND ls_sort TO gt_sort2.

  ENDIF.


  ASSIGN er_table->* TO <fs_tab>.
  REFRESH : <fs_tab>.
  CREATE DATA lr_rec LIKE LINE OF <fs_tab>.
  ASSIGN lr_rec->* TO <fs_o>.

  DATA : lt_bukrs LIKE TABLE OF gt_output WITH HEADER LINE,
         l_cnt    TYPE i.
  lt_bukrs[] = gt_output[].
  SORT lt_bukrs BY abb.

  IF g_bukrs = 'ALL'.
    l_abb = '*'.
  ELSE.
    l_abb = g_bukrs.
  ENDIF.
  IF g_field = 'BUKRS'.
    l_field = '*'.
  ELSE.
    l_field = g_field.
  ENDIF.
  DELETE
  lt_bukrs WHERE abb   NP l_abb OR
                 varbl NP l_field.
  LOOP AT lt_bukrs.
    READ TABLE gt_output WITH KEY varbl = 'BUKRS'
                                  abb   = lt_bukrs-abb.

    dyn_value 'COUNTRY' gt_output-country <fs_o>.

    dyn_value 'COUNTRY' lt_bukrs-abb <fs_o>.
    dyn_value 'BUKRS' lt_bukrs-abb <fs_o>  .
    dyn_value 'DESC'  gt_output-label <fs_o>  .
    dyn_value 'VARBL' lt_bukrs-varbl <fs_o>.
    CASE lt_bukrs-varbl.
      WHEN 'BUKRS'.
        dyn_value 'FIELD'  'Company Code' <fs_o>.
      WHEN 'EKORG'.
        dyn_value 'FIELD'  'Purchasing Organization' <fs_o>.
      WHEN 'WERKS'.
        dyn_value 'FIELD'  'Plant' <fs_o>.
      WHEN 'VKORG'.
        dyn_value 'FIELD'  'Sales Organization' <fs_o>.
      WHEN 'GSBER'.
        dyn_value 'FIELD'  'Business Area' <fs_o>.
      WHEN 'SPART'.
        dyn_value 'FIELD'  'Division' <fs_o>.
      WHEN 'VTWEG'.
        dyn_value 'FIELD'  'Distribution Channel' <fs_o>.
      WHEN 'KKBER'.
        dyn_value 'FIELD'  'Credit Control Area' <fs_o>.
      WHEN 'KOKRS'.
        dyn_value 'FIELD'  'Control Area' <fs_o>.
      WHEN 'VSTEL'.
        dyn_value 'FIELD'  'Shipping Point' <fs_o>.
    ENDCASE.
    dyn_value 'VALUE' lt_bukrs-low   <fs_o>.
    dyn_value 'LABEL' lt_bukrs-label <fs_o>.
    dyn_value 'ICON'  lt_bukrs-icon  <fs_o>.
    dyn_value 'CHECK' lt_bukrs-check <fs_o>.

    READ TABLE gt_output WITH KEY varbl   = lt_bukrs-varbl
                                   abb    = lt_bukrs-abb
                                   low    = lt_bukrs-low
                                   manual = 'X'.
    IF sy-subrc = 0.
      dyn_value 'INFO' 'C410' <fs_o>.
    ELSE.
      dyn_value 'INFO' ' ' <fs_o>.
    ENDIF.

    APPEND <fs_o> TO <fs_tab>.



  ENDLOOP.

*--Delete Info column for line colouring from field catalog
  DELETE et_fieldcat WHERE fieldname = 'INFO'.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  exculde_toolbar
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM exculde_toolbar.
  DATA: l_func TYPE ui_func.


  REFRESH gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_check.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_detail.
  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_mb_export.
*  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_mb_filter.
*  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_find.
*  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_graph.
*  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_info.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_append_row.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_copy.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_copy_row.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_cut.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_paste.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_paste_new_row.
  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_print.
*  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_refresh.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_mb_sum.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_mb_variant.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_mb_view.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_undo.
  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_loc_insert_row.
*  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid2->mc_fc_loc_delete_row.
  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_sort_asc.
*  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid2->mc_fc_sort_dsc.
*  APPEND l_func TO gt_exc_toolbar.

ENDFORM.                    " exculde_toolbar
*&---------------------------------------------------------------------*
*&      Form  handle_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_UCOMM  text
*----------------------------------------------------------------------*
FORM handle_user_command USING    i_ucomm TYPE sy-ucomm.
  CASE i_ucomm.
    WHEN 'BACK' OR 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
      ELSE.                            "Change mode to DISPLAY
        gf_dispchg = gc_display.
*        PERFORM get_data.
*        CLEAR gf_data_change.
      ENDIF.
      REFRESH : gt_fieldcat.
      PERFORM create_detail_table CHANGING gr_table2 gt_fieldcat.
      ASSIGN gr_table2->* TO <fs_tab>.
      PERFORM init_screen_2 USING <fs_tab>.
*    WHEN 'SAVE'.
*      PERFORM save_details.
  ENDCASE.

ENDFORM.                    " handle_user_command
*&---------------------------------------------------------------------*
*&      Form  save_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_details.
  FIELD-SYMBOLS : <fs_tab> TYPE STANDARD TABLE,
                    <fs_o> TYPE ANY
                      .
  DATA : lr_rec   TYPE REF TO data,
         l_bukrs(4) TYPE c,
         lf_check TYPE flag,
         l_value(4) TYPE c,
         l_field    TYPE string,
         l_label TYPE string,
         l_high(4) TYPE c,
         l_count TYPE string.

  ASSIGN gr_table2->* TO <fs_tab>.

  LOOP AT <fs_tab> ASSIGNING <fs_o>.
    get_dyn_value 'BUKRS'  <fs_o>  l_bukrs.
    get_dyn_value 'VALUE'  <fs_o>  l_value.
    get_dyn_value 'VARBL'  <fs_o>  l_field.
    get_dyn_value 'CHECK'  <fs_o>  lf_check.
    get_dyn_value 'LABEL'  <fs_o>  l_label.
    get_dyn_value 'COUNTRY'  <fs_o>  l_count.

    LOOP AT gt_output WHERE abb   = l_bukrs AND
                            varbl = l_field AND
                            low   = l_value.
    ENDLOOP.
    IF sy-subrc NE 0.
      IF lf_check  = ' '.
        gt_output-icon = c_icon_red.
        CLEAR gt_output-check.
      ELSE.
        gt_output-icon  = c_icon_green.
        gt_output-check = 'X'.
      ENDIF.
      gt_output-country = l_count.
      gt_output-abb = l_bukrs.
      gt_output-varbl = l_field.
      gt_output-low = l_value.
      gt_output-label = l_label.
      gt_output-manual = 'X'.
      APPEND gt_output.
    ENDIF.
  ENDLOOP.
*  FREE : gr_table2.
*  REFRESH : gt_fieldcat.
*  PERFORM create_detail_table CHANGING gr_table2 gt_fieldcat.
*  ASSIGN gr_table2->* TO <fs_tab>.
*  PERFORM init_screen_2 USING <fs_tab>.
ENDFORM.                    " save_details
