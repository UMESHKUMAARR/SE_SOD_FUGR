*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_RFC_MAINTAIN_ALV
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/se_maintain_corg MESSAGE-ID /psyng/sw.
CLASS lcl_event_receiver DEFINITION DEFERRED.

DATA : BEGIN OF gt_swcorg OCCURS 0.
        INCLUDE STRUCTURE /psyng/swsodorgo.
DATA : END OF gt_swcorg,
       gs_swcorg LIKE LINE OF gt_swcorg,
       gf_dispchg(1)      TYPE c.
DATA : gt_exc_toolbar TYPE ui_functions.
.
CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.

DATA: go_alvgrid        TYPE REF TO cl_gui_alv_grid,
      go_container      TYPE REF TO cl_gui_custom_container,
      go_evt_recv       TYPE REF TO lcl_event_receiver,
      gs_layout         TYPE lvc_s_layo,
      gf_data_change(1) TYPE c.


*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF t_del_corg,
             corg TYPE /psyng/swsodorgo,
             index   TYPE i,
           END OF t_del_corg.

    DATA: lt_del_corg TYPE TABLE OF t_del_corg,
          l_index    TYPE i.

    METHODS:
      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
                     IMPORTING e_object e_interactive,
      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
                          IMPORTING e_ucomm,
      data_changed FOR EVENT data_changed OF cl_gui_alv_grid
                   IMPORTING er_data_changed.

ENDCLASS.

*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver IMPLEMENTATION.

*---------------------------------------------------------------------*
*       METHOD data_changed
*---------------------------------------------------------------------*
*      -->ER_DATA_CHANGED
*---------------------------------------------------------------------*
  METHOD data_changed.
*    DATA: ls_mod_cells TYPE lvc_s_modi,
*          ls_del_rows  TYPE lvc_s_moce,
*          ls_protocol  TYPE lvc_s_msg1,
*          ls_corg      LIKE LINE OF gt_swcorg,
*          ls_del_rfc   TYPE t_del_rfc,
*          l_msg_txt(80) TYPE c,
*          l_rfcdest TYPE rfcdes-rfcdest.
*
*    REFRESH er_data_changed->mt_protocol.

*****    Check RFC Destination Exist in SM59
*
*    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
*           WHERE fieldname = 'RFCDEST'.
*      READ TABLE er_data_changed->mt_inserted_rows
*                 WITH KEY row_id = ls_mod_cells-row_id
*                 TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*
*      SELECT SINGLE rfcdest FROM rfcdes INTO l_rfcdest
*      WHERE rfcdest = ls_mod_cells-value.
*      IF sy-subrc NE 0 AND
*      NOT l_rfcdest IS INITIAL. "empty RFC dest is ok for local system
*        ls_mod_cells-error = 'X'.
*
*        MODIFY er_data_changed->mt_mod_cells FROM ls_mod_cells
*                       INDEX ls_mod_cells-row_id TRANSPORTING error.
*        DELETE er_data_changed->mt_good_cells
*                WHERE fieldname = ls_mod_cells-fieldname
*                   AND row_id =  ls_mod_cells-row_id.
*
*        ls_protocol-msgid     = '/PSYNG/BASIS'.
*        ls_protocol-msgno     = '038'.
*        ls_protocol-msgty     = 'E'.
*        ls_protocol-msgv1     = 'RFC Destination'.
*        ls_protocol-msgv2     = ls_mod_cells-value.
*        ls_protocol-fieldname = ls_mod_cells-fieldname.
*        ls_protocol-row_id    = ls_mod_cells-row_id.
*        APPEND ls_protocol TO er_data_changed->mt_protocol.
*        MESSAGE i012(/psyng/basis) WITH ls_mod_cells-value
*        ' - Invalid RFC Destination'.
*        EXIT.
*      ENDIF.
*
*    ENDLOOP.
*
*
*** Check for the existing Entries
*    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
*            WHERE fieldname = 'RFCDEST'
*              AND value    <> space.
*     LOOP AT gt_swrfcdes INTO ls_rfc WHERE rfcdest =
*ls_mod_cells-value
*             .
*        IF sy-tabix <> ls_mod_cells-row_id.
*          ls_mod_cells-error = 'X'.
*          MODIFY er_data_changed->mt_mod_cells FROM ls_mod_cells
*                 INDEX ls_mod_cells-row_id TRANSPORTING error.
*          DELETE er_data_changed->mt_good_cells
*                 WHERE fieldname = ls_mod_cells-fieldname.
*          ls_protocol-msgid     = '/PSYNG/BASIS'.
*          ls_protocol-msgno     = '038'.
*          ls_protocol-msgty     = 'E'.
*          ls_protocol-fieldname = ls_mod_cells-fieldname.
*          ls_protocol-row_id    = ls_mod_cells-row_id.
*          APPEND ls_protocol TO er_data_changed->mt_protocol.
*          MESSAGE i038(/psyng/basis).
*          CONTINUE.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*
*    gf_data_change = 'X'.
  ENDMETHOD.
***---------------------------------------------------------------------
**
***       METHOD handle_toolbar
***---------------------------------------------------------------------
**
***      -->E_OBJECT
***      -->E_INTERACTIVE
***---------------------------------------------------------------------
**
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
**
  ENDMETHOD.

*---------------------------------------------------------------------*
*       METHOD handle_user_command
*---------------------------------------------------------------------*
*      -->E_UCOMM
*---------------------------------------------------------------------*
  METHOD handle_user_command.
    PERFORM handle_user_command USING e_ucomm.
  ENDMETHOD.
ENDCLASS.

INITIALIZATION.

*Begin of Addition:HBHALLA(PN-17933)(02/03/26)
AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORG'.
if sy-subrc <> 0.
AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORGD'.
if sy-subrc <> 0.
AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORGC'.
if sy-subrc <> 0.
  MESSAGE e108(/psyng/sw) WITH
  'Display Custom Org Logic'(e40).
endif.
endif.
endif.
*End of Addition:HBHALLA(PN-17933)(02/03/26)
**  exelog sy-repid ''.
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
  CREATE OBJECT go_evt_recv.
  gf_dispchg = gc_display.
*  PERFORM check_authorization.
  PERFORM get_data.
  CALL SCREEN '0100'.

*&---------------------------------------------------------------------*
*&      Module  status_0100  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for screen 100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET TITLEBAR 'MAIN'.

  PERFORM set_status.
ENDMODULE.                 " status_0100  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  display_alv  OUTPUT
*&---------------------------------------------------------------------*
*       Display ALV on main screen
*----------------------------------------------------------------------*
MODULE display_alv OUTPUT.
  PERFORM display_alv.
ENDMODULE.                 " display_alv  OUTPUT

*&---------------------------------------------------------------------*
*&      Module  user_command_0100  INPUT
*&---------------------------------------------------------------------*
*       Handle user commands for screen 100
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  PERFORM handle_user_command USING sy-ucomm.
ENDMODULE.                 " user_command_0100  INPUT

*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
*       Display ALV
*----------------------------------------------------------------------*
FORM display_alv.
  DATA: lt_fieldcat TYPE lvc_t_fcat,
        ls_stable   TYPE lvc_s_stbl.
**  PERFORM update_sysid USING ''.
  PERFORM prepare_field_catalog TABLES lt_fieldcat.

  IF go_alvgrid IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name              = 'CC_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.

    CREATE OBJECT go_alvgrid
      EXPORTING
        i_parent          = go_container
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.

    CALL METHOD go_alvgrid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_enter.
    CALL METHOD go_alvgrid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_modified.

    SET HANDLER go_evt_recv->handle_user_command FOR go_alvgrid.
    SET HANDLER go_evt_recv->handle_toolbar FOR go_alvgrid.
    SET HANDLER go_evt_recv->data_changed FOR go_alvgrid.
*    SET HANDLER go_evt_recv->data_changed_finished FOR go_alvgrid.

    gs_layout-zebra      = 'X'.
    gs_layout-cwidth_opt = 'X'.

    PERFORM exculde_toolbar.

    CALL METHOD go_alvgrid->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
        it_toolbar_excluding = gt_exc_toolbar
      CHANGING
        it_outtab                     = gt_swcorg[]
        it_fieldcatalog               = lt_fieldcat
      EXCEPTIONS
        invalid_parameter_combination = 1
        program_error                 = 2
        too_many_lines                = 3
        OTHERS                        = 4.
  ELSE.



    CALL METHOD go_alvgrid->set_frontend_fieldcatalog
          EXPORTING
            it_fieldcatalog = lt_fieldcat.

    CALL METHOD go_alvgrid->set_frontend_layout
          EXPORTING
            is_layout = gs_layout.

    ls_stable-row = 'X'.
    ls_stable-col = 'X'.
    CALL METHOD go_alvgrid->refresh_table_display
          EXPORTING
            i_soft_refresh = 'X'
            is_stable      = ls_stable
          EXCEPTIONS
            finished       = 1
            OTHERS         = 2.
  ENDIF.
ENDFORM.                    " display_alv


*---------------------------------------------------------------------*
*       FORM update_sysid                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IF_ALL                                                        *
*---------------------------------------------------------------------*
**FORM update_sysid USING if_all.
**  DATA : l_system_msg(72) TYPE c,
**         l_rfc TYPE rfcdest.
**  FIELD-SYMBOLS : <rec> LIKE gt_swrfcdes.
***  --Update the SYSTEM ID field
**  LOOP AT  gt_swrfcdes   ASSIGNING <rec>.
**    IF <rec>-systid IS INITIAL OR if_all = 'X'.
**      l_rfc =  <rec>-systid.
**      CALL FUNCTION '/PSYNG/SW_062'
**      DESTINATION <rec>-rfcdest
**       IMPORTING
**         e_rfcdest       = l_rfc
**     EXCEPTIONS
**      communication_failure = 1 MESSAGE l_system_msg
**      system_failure        = 2 MESSAGE l_system_msg
**      OTHERS                = 3.
**      <rec>-systid = l_rfc.
**    ENDIF.
**  ENDLOOP.
**ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get data from database
*----------------------------------------------------------------------*
FORM get_data.

  SELECT * INTO TABLE gt_swcorg FROM /psyng/swsodorgo.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog
*&---------------------------------------------------------------------*
*       Prepare ALV field catalog
*----------------------------------------------------------------------
*      -->ET_FIELDCAT  Field catalog
*----------------------------------------------------------------------*
FORM prepare_field_catalog TABLES   et_fieldcat STRUCTURE lvc_s_fcat.
  DATA: l_repid     TYPE sy-repid,
        lt_fieldcat TYPE slis_t_fieldcat_alv.

  FIELD-SYMBOLS: <fcat> LIKE LINE OF lt_fieldcat.


  l_repid = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = l_repid
            i_internal_tabname     = 'GT_SWCORG'
            i_inclname             = l_repid
       CHANGING
            ct_fieldcat            = lt_fieldcat[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT lt_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      <fcat>-edit = 'X'.
    ENDIF.
    MOVE-CORRESPONDING <fcat> TO et_fieldcat.
    et_fieldcat-ref_field = <fcat>-ref_fieldname.
    et_fieldcat-ref_table = <fcat>-ref_tabname.


    CLEAR et_fieldcat-tech.
    APPEND et_fieldcat.
  ENDLOOP.
  DELETE et_fieldcat WHERE fieldname = 'MANDT'.
ENDFORM.                    " prepare_field_catalog

*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       Save data to database
*----------------------------------------------------------------------*
FORM save_data.
  DATA: ls_swcorg LIKE LINE OF gt_swcorg.

  CALL METHOD go_alvgrid->check_changed_data.

  DATA: lflag_error_type TYPE c,
         lflag_error_con  TYPE c.
  DATA: lt_conflict TYPE STANDARD TABLE OF /psyng/conflict,
        ls_conflict LIKE LINE OF lt_conflict,
        lo_data_changed    TYPE REF TO cl_alv_changed_data_protocol,
        lf_error TYPE flag,
        l_index like sy-tabix.

  CREATE OBJECT lo_data_changed
          EXPORTING
*            I_CONTAINER =
            i_calling_alv = go_alvgrid.
  RANGES : r_field FOR /psyng/swsodorgo-field.
* Get SOD Version & Conflict combination from master table
  IF NOT gt_swcorg[] IS INITIAL.
    SELECT conid vrsio FROM /psyng/conflict
    INTO CORRESPONDING FIELDS OF TABLE lt_conflict
    FOR ALL ENTRIES IN gt_swcorg
    WHERE conid = gt_swcorg-conid AND
          vrsio = gt_swcorg-vrsio.
  ENDIF.
  r_field-sign = 'I'.
  r_field-option = 'EQ'.
  r_field-low = 'EKORG'.
  APPEND r_field.
  CLEAR r_field-low.
  r_field-low = 'VKORG'.
  APPEND r_field.
  CLEAR r_field-low.

  DEFINE add_message.
    lf_error = 'X'.

    call method lo_data_changed->add_protocol_entry
          exporting
            i_msgid     = '/PSYNG/SW'
            i_msgty     = 'E'
            i_msgno     = '002'
            i_msgv1     = &2
            i_msgv2     = &3
            i_msgv3     = &4
            i_msgv4     = &5
            i_fieldname = &1. "#EC SAST_CI_GEN_CHECK
.
  END-OF-DEFINITION.
  CLEAR lf_error.
  LOOP AT gt_swcorg INTO gs_swcorg.
    l_index = sy-tabix.
*--Validate Type
    CASE gs_swcorg-type.
      WHEN 'REL'.
        IF NOT gs_swcorg-field IN r_field.

*            MESSAGE e002 WITH
*  'Only fields VKORG or EKORG are allowed for TYPE = REL'(s01).
          add_message  'TYPE'
            'Only fields VKORG or EKORG are allowed for TYPE '(s01)
            'REL' gs_swcorg-field ''
            .
        ENDIF.
      WHEN 'FIELD'.

      WHEN OTHERS.
        add_message 'TYPE'
          'Only the types REL and FIELD are valid'(s03)
          '' gs_swcorg-type ''.

    ENDCASE.
*--Validate Conflict
    READ TABLE lt_conflict INTO ls_conflict
      WITH KEY conid = gs_swcorg-conid
               vrsio = gs_swcorg-vrsio.
    IF sy-subrc NE 0.
      add_message   'CONID'
        'SOD Matrix Version - Conflict ID do not match'(s02)
        '' gs_swcorg-conid gs_swcorg-vrsio.
    ENDIF.
  ENDLOOP.

  IF lf_error = 'X'.
    CALL METHOD lo_data_changed->display_protocol.
  ELSE.
    PERFORM save_records.
  ENDIF.
ENDFORM.                    " save_data

*&---------------------------------------------------------------------*
*&      Form  handle_user_command
*&---------------------------------------------------------------------*
*       Handle user commands
*----------------------------------------------------------------------*
*      -->I_UCOMM  User command
*----------------------------------------------------------------------*
FORM handle_user_command USING    i_ucomm TYPE sy-ucomm.
  DATA: lf_lock      TYPE /psyng/bapiflagx,
        lf_answer(1) TYPE c.


  CASE i_ucomm.
    WHEN 'BACK' OR 'CANCEL'.
      PERFORM exit_without_save CHANGING lf_answer.
      CHECK lf_answer = '1'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'SAVE'.
      PERFORM save_data.
*      CLEAR gf_data_change.

    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
*Begin of Addition:HBHALLA(PN-17933)(27/02/26)
  AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
   ID 'Y&SW_ADMF' FIELD 'CUSTORG'.
  IF sy-subrc <> 0.
      AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
       ID 'Y&SW_ADMF' FIELD 'CUSTORGC'.
      IF sy-subrc <> 0.
        MESSAGE e108(/psyng/sw) WITH
        'Maintain Custom Org Logic'(e38).
      ELSE.
        gf_dispchg = gc_change.
*        PERFORM check_authorization.
        CHECK gf_dispchg = gc_change.
        PERFORM enqueue CHANGING lf_lock.
        CHECK lf_lock IS INITIAL.
      ENDIF.
   ELSE.
    gf_dispchg = gc_change.
*    PERFORM check_authorization.
    CHECK gf_dispchg = gc_change.
    PERFORM enqueue CHANGING lf_lock.
    CHECK lf_lock IS INITIAL.
   ENDIF.
*End of Addition:HBHALLA(PN-17933)(27/02/26)
      ELSE.                            "Change mode to DISPLAY
        PERFORM exit_without_save CHANGING lf_answer.
        CHECK lf_answer = '1'.
        PERFORM dequeue.
        gf_dispchg = gc_display.
        PERFORM get_data.
        CLEAR gf_data_change.
      ENDIF.

      PERFORM display_alv.
      PERFORM set_status.

  ENDCASE.
ENDFORM.                    " handle_user_command

*&--------------------------------------------------------------------
*&      Form  enqueue
*&--------------------------------------------------------------------
*       Lock table
*---------------------------------------------------------------------
*      <--EF_LOCK  Table locked flag
*---------------------------------------------------------------------
FORM enqueue CHANGING ef_lock TYPE /psyng/bapiflagx.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SWSODORGO'
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE 'I' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ef_lock = 'X'.
  ENDIF.
ENDFORM.                    " enqueue

*&--------------------------------------------------------------------
*&      Form  dequeue
*&--------------------------------------------------------------------
*       Unlock table
*---------------------------------------------------------------------
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = '/PSYNG/SWSODORGO'.
ENDFORM.                    " dequeue

***&--------------------------------------------------------------------
*-
***
***&      Form  check_authorization
***&--------------------------------------------------------------------
*-
***
***       Check authorization for table
***---------------------------------------------------------------------
*-
***
**FORM check_authorization.
***  DATA: l_actvt(2) TYPE c,
***        l_msg      TYPE string.
***
***  IF gf_dispchg = gc_display.
***    l_actvt = '03'."display
***    l_msg   = 'Display'(001).
***  ELSE.
***    l_actvt = '02'."change
***    l_msg   = 'Change'(002).
***  ENDIF.
***
***  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
***          ID 'DICBERCLS' FIELD 'Y&E2'
***          ID 'ACTVT' FIELD l_actvt.
***  IF sy-subrc <> 0.
***    IF gf_dispchg = gc_display.
***      MESSAGE e108 WITH l_msg 'RFC Destinations'(003).
***    ELSE.
***      gf_dispchg = gc_display.
***      MESSAGE i108 WITH l_msg 'RFC Destinations'(003).
***    ENDIF.
***  ENDIF.
**ENDFORM.                    " check_authorization

*&--------------------------------------------------------------------
*&      Form  exit_without_save
*&--------------------------------------------------------------------
*       Check if the user wants to exit without saving changes
*---------------------------------------------------------------------
*      <--EF_ANSWER  Answer
*---------------------------------------------------------------------
FORM exit_without_save CHANGING ef_answer.
  ef_answer = '1'.
  CHECK gf_data_change = 'X'.

  CALL FUNCTION 'POPUP_TO_CONFIRM'
       EXPORTING
            text_question         = text-q01
            text_button_1         = text-004
            icon_button_1         = 'ICON_OKAY'
            text_button_2         = text-005
            icon_button_2         = 'ICON_CANCEL'
            default_button        = '2'
            display_cancel_button = space
       IMPORTING
            answer                = ef_answer
       EXCEPTIONS
            text_not_found        = 1
            OTHERS                = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " exit_without_save

*&--------------------------------------------------------------------
*&      Form  set_status
*&--------------------------------------------------------------------
*       Set PF-STATUS
*---------------------------------------------------------------------
FORM set_status.
  IF gf_dispchg = gc_change.
    SET PF-STATUS 'MAIN'.
  ELSE.
    SET PF-STATUS 'MAIN' EXCLUDING 'SAVE'.
  ENDIF.
ENDFORM.                    " set_status..
***&--------------------------------------------------------------------
*-
***
***&      Form  exculde_toolbar
***&--------------------------------------------------------------------
*-
***
***       text
***---------------------------------------------------------------------
*-
***
***  -->  p1        text
***  <--  p2        text
***---------------------------------------------------------------------
*-
***
FORM exculde_toolbar.
  DATA: l_func TYPE ui_func.


  REFRESH gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_info.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_expcrdata.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_expcrdesig.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_expcrtempl.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_pc_file.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_print.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_view_crystal.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_view_grid.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_mb_view.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_mb_export.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_call_abc.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_graph.
  APPEND l_func TO gt_exc_toolbar.
  l_func = go_alvgrid->mc_fc_filter.
  APPEND l_func TO gt_exc_toolbar.
*  l_func = go_alvgrid->mc_fc_loc_delete_row.
*  APPEND l_func TO gt_exc_toolbar.
**  l_func = go_alvgrid->mc;_next_view.
**  APPEND l_func TO gt_exc_toolbar.

ENDFORM.                    " exculde_toolbar
*&---------------------------------------------------------------------*
*&      Form  save_records
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_records.

*  LOOP AT gt_swcorg INTO gs_swcorg.
*    MODIFY /psyng/swsodorgo FROM gs_swcorg.
*    "#EC CI_IMUD_NESTED
*  ENDLOOP.
  RANGES: lr_vrsio  FOR /psyng/swsodorgo-vrsio.
  DELETE FROM /psyng/swsodorgo WHERE vrsio IN lr_vrsio.
  COMMIT WORK.

  MODIFY /psyng/swsodorgo FROM TABLE gt_swcorg.
  MESSAGE s120(/psyng/sw).
  COMMIT WORK.
ENDFORM.                    " save_records
