*----------------------------------------------------------------------*
* Report  /PSYNG/SW_098                                                *
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
REPORT /psyng/sw_098 MESSAGE-ID /psyng/sw.

CLASS lcl_event_receiver DEFINITION DEFERRED.

CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.

DATA: go_alvgrid        TYPE REF TO cl_gui_alv_grid,
      go_container      TYPE REF TO cl_gui_custom_container,
      go_evt_recv       TYPE REF TO lcl_event_receiver,
      gt_risk           TYPE TABLE OF /psyng/sw_risk,
      gs_layout         TYPE lvc_s_layo,
      gf_dispchg(1)     TYPE c,
      gf_data_change(1) TYPE c.

*---------------------------------------------------------------------*
*       CLASS lcl_event_receiver DEFINITION
*---------------------------------------------------------------------*
CLASS lcl_event_receiver DEFINITION.
  PUBLIC SECTION.
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
    DATA: ls_mod_cells TYPE lvc_s_modi,
          ls_protocol  TYPE lvc_s_msg1,
          ls_risk      LIKE LINE OF gt_risk.


    REFRESH er_data_changed->mt_protocol.
    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
            WHERE fieldname = 'RISK'
              AND value    <> space.

      TRANSLATE ls_mod_cells-value TO UPPER CASE.
      LOOP AT gt_risk INTO ls_risk WHERE risk = ls_mod_cells-value.
        IF sy-tabix <> ls_mod_cells-row_id.
          ls_mod_cells-error = 'X'.
          MODIFY er_data_changed->mt_mod_cells FROM ls_mod_cells
                 INDEX ls_mod_cells-row_id TRANSPORTING error.
          DELETE er_data_changed->mt_good_cells
                 WHERE fieldname = ls_mod_cells-fieldname.
          ls_protocol-msgid     = '/PSYNG/BASIS'.
          ls_protocol-msgno     = '038'.
          ls_protocol-msgty     = 'E'.
          ls_protocol-fieldname = ls_mod_cells-fieldname.
          ls_protocol-row_id    = ls_mod_cells-row_id.
          APPEND ls_protocol TO er_data_changed->mt_protocol.
          MESSAGE i038(/psyng/basis).
        ENDIF.
      ENDLOOP.
    ENDLOOP.

    gf_data_change = 'X'.
  ENDMETHOD.

*---------------------------------------------------------------------*
*       METHOD handle_toolbar
*---------------------------------------------------------------------*
*      -->E_OBJECT
*      -->E_INTERACTIVE
*---------------------------------------------------------------------*
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

*---------------------------------------------------------------------*
*       METHOD handle_user_command
*---------------------------------------------------------------------*
*      -->E_UCOMM
*---------------------------------------------------------------------*
  METHOD handle_user_command.
    PERFORM handle_user_command USING e_ucomm.
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
  CREATE OBJECT go_evt_recv.
  gf_dispchg = gc_display.
  PERFORM check_authorization.
  PERFORM get_data.
  CALL SCREEN '0100'.

*&---------------------------------------------------------------------*
*&      Module  status_0100  OUTPUT
*&---------------------------------------------------------------------*
*       Set status for screen 100
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET TITLEBAR 'MAIN'.
  SET PF-STATUS 'MAIN'.
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
  DATA: lt_fieldcat TYPE lvc_t_fcat.


  PERFORM prepare_field_catalog TABLES lt_fieldcat.

  IF go_alvgrid IS INITIAL.
    CREATE OBJECT go_container
      EXPORTING
        container_name              = 'ALV_CONT'
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

    gs_layout-zebra      = 'X'.
    gs_layout-cwidth_opt = 'X'.
    CALL METHOD go_alvgrid->set_table_for_first_display
      EXPORTING
        is_layout                     = gs_layout
      CHANGING
        it_outtab                     = gt_risk[]
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

    CALL METHOD go_alvgrid->refresh_table_display
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2.
  ENDIF.
ENDFORM.                    " display_alv

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get data from database
*----------------------------------------------------------------------*
FORM get_data.
  SELECT * INTO TABLE gt_risk FROM /psyng/sw_risk.
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog
*&---------------------------------------------------------------------*
*       Prepare ALV field catalog
*----------------------------------------------------------------------
*      -->ET_FIELDCAT  Field catalog
*----------------------------------------------------------------------*
FORM prepare_field_catalog TABLES   et_fieldcat STRUCTURE lvc_s_fcat.
  FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.


  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_RISK'
       CHANGING
            ct_fieldcat            = et_fieldcat[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  LOOP AT et_fieldcat ASSIGNING <fcat>.
    IF gf_dispchg = gc_change.
      <fcat>-edit = 'X'.
    ELSE.
      CLEAR <fcat>-edit.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " prepare_field_catalog

*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       Save data to database
*----------------------------------------------------------------------*
FORM save_data.
  CALL METHOD go_alvgrid->check_changed_data.
*BOC:HBHALLA (17/12/24)
  DELETE FROM /psyng/sw_risk WHERE risk NE space.
"#EC SAST_CI_GEN_CHECK
*EOC:HBHALLA (17/12/24)
  DELETE gt_risk WHERE risk = space.
  INSERT /psyng/sw_risk FROM TABLE gt_risk.
  MESSAGE s120.
  COMMIT WORK.
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
    WHEN 'BACK'.
      PERFORM exit_without_save CHANGING lf_answer.
      CHECK lf_answer = '1'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.

    WHEN 'SAVE'.
      PERFORM save_data.
      CLEAR gf_data_change.

    WHEN 'DISPCHG'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
        PERFORM check_authorization.
        CHECK gf_dispchg = gc_change.
        PERFORM enqueue CHANGING lf_lock.
        CHECK lf_lock IS INITIAL.
      ELSE.                            "Change mode to DISPLAY
        PERFORM exit_without_save CHANGING lf_answer.
        CHECK lf_answer = '1'.
        PERFORM dequeue.
        gf_dispchg = gc_display.
        PERFORM get_data.
        CLEAR gf_data_change.
      ENDIF.

      PERFORM display_alv.
  ENDCASE.
ENDFORM.                    " handle_user_command

*&---------------------------------------------------------------------*
*&      Form  enqueue
*&---------------------------------------------------------------------*
*       Lock table
*----------------------------------------------------------------------*
*      <--EF_LOCK  Table locked flag
*----------------------------------------------------------------------*
FORM enqueue CHANGING ef_lock TYPE /psyng/bapiflagx.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SW_RISK'
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

*&---------------------------------------------------------------------*
*&      Form  dequeue
*&---------------------------------------------------------------------*
*       Unlock table
*----------------------------------------------------------------------*
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = '/PSYNG/SW_RISK'.
ENDFORM.                    " dequeue

*&---------------------------------------------------------------------*
*&      Form  check_authorization
*&---------------------------------------------------------------------*
*       Check authorization for table
*----------------------------------------------------------------------*
FORM check_authorization.
  DATA: l_actvt(2) TYPE c,
        l_msg      TYPE string.

  IF gf_dispchg = gc_display.
    l_actvt = '03'."display
    l_msg   = 'Display'(001).
  ELSE.
    l_actvt = '02'."change
    l_msg   = 'Change'(002).
  ENDIF.

  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
          ID 'DICBERCLS' FIELD 'Y&S3'
          ID 'ACTVT' FIELD l_actvt.
  IF sy-subrc <> 0.
    IF gf_dispchg = gc_display.
      MESSAGE e108(/psyng/sw) WITH l_msg 'Risk Scenarios'(003).
    ELSE.
      gf_dispchg = gc_display.
      MESSAGE i108(/psyng/sw) WITH l_msg 'Risk Scenarios'(003).
    ENDIF.
  ENDIF.
ENDFORM.                    " check_authorization

*&---------------------------------------------------------------------*
*&      Form  exit_without_save
*&---------------------------------------------------------------------*
*       Check if the user wants to exit without saving changes
*----------------------------------------------------------------------*
*      <--EF_ANSWER  Answer
*----------------------------------------------------------------------*
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
