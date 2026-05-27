REPORT /psyng/sw_050 .

DATA : BEGIN OF gt_swsodorgm OCCURS 0.
        INCLUDE STRUCTURE /psyng/swsodorgm.
DATA : END OF gt_swsodorgm,
       gf_dispchg(1)      TYPE c.
.
CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C'.


*-- Global data definitions for ALV
*--- ALV Grid instance reference
DATA gr_alvgrid TYPE REF TO cl_gui_alv_grid .
*--- Name of the custom control added on the screen
DATA gc_custom_control_name TYPE scrfname VALUE 'CC_ALV' .
*--- Custom container instance reference
DATA gr_ccontainer TYPE REF TO cl_gui_custom_container .
*--- Field catalog table
DATA gt_fieldcat TYPE lvc_t_fcat .
*--- Layout structure
DATA gs_layout TYPE lvc_s_layo .

*---------------------------------------------------------------------*
*       CLASS lcl_event_handler DEFINITION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler DEFINITION .
  PUBLIC SECTION .
    METHODS:
*--To add new functional buttons to the ALV toolbar
     handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
                IMPORTING e_object e_interactive          ,
*--To implement user commands
     handle_user_command
            FOR EVENT user_command OF cl_gui_alv_grid
                IMPORTING e_ucomm                         ,
*--Search help
     handle_on_f4
            FOR EVENT onf4 OF cl_gui_alv_grid
                IMPORTING e_fieldname es_row_no   er_event_data,

*---  Data Changed
      data_changed FOR EVENT data_changed OF cl_gui_alv_grid
                   IMPORTING er_data_changed.
  PRIVATE SECTION.
ENDCLASS.
*---------------------------------------------------------------------*
*       CLASS lcl_event_handler IMPLEMENTATION
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
CLASS lcl_event_handler IMPLEMENTATION .


*--Handle Toolbar
  METHOD handle_toolbar.
    PERFORM handle_toolbar USING e_object e_interactive .
  ENDMETHOD .
*--Handle User Command
  METHOD handle_user_command .
    PERFORM handle_user_command USING e_ucomm .
  ENDMETHOD.
  METHOD handle_on_f4 .

    PERFORM f4_help USING e_fieldname es_row_no .
    er_event_data->m_event_handled = 'X' .

  ENDMETHOD .
  METHOD data_changed.
*    DATA: ls_mod_cells TYPE lvc_s_modi,
*          ls_protocol  TYPE lvc_s_msg1.
*
*    REFRESH er_data_changed->mt_protocol.
*
*    LOOP AT er_data_changed->mt_mod_cells INTO ls_mod_cells
*               WHERE fieldname = 'ABB'.
**    READ TABLE er_data_changed->mt_inserted_rows
**                 WITH KEY fieldname = 'ABB'
**                 TRANSPORTING NO FIELDS.
*
*      IF ls_mod_cells-value IS INITIAL.
*        ls_protocol-msgid     = '00'.
*        ls_protocol-msgno     = 007.
*        ls_protocol-msgty     = 'E'.
*        ls_protocol-fieldname = ls_mod_cells-fieldname.
*        ls_protocol-row_id    = ls_mod_cells-row_id.
*        APPEND ls_protocol TO er_data_changed->mt_protocol.
*        MESSAGE e208(00) WITH 'Abbreviation cannot be blank.'.
*        EXIT.
*      ENDIF.
*    ENDLOOP.
  ENDMETHOD.
ENDCLASS .
DATA gr_event_handler TYPE REF TO  lcl_event_handler .
*--Registering handler methods to handle ALV Grid events

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
  CREATE OBJECT gr_event_handler .

  gf_dispchg = gc_display.
  PERFORM check_authorization
              USING
                 gf_dispchg.

  SELECT * FROM /psyng/swsodorgm
  INTO CORRESPONDING FIELDS OF TABLE gt_swsodorgm.
  SORT gt_swsodorgm.
  CALL SCREEN '0100'.
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
  SET TITLEBAR 'TITLE_0100'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'UPLOAD'.
      SUBMIT /psyng/sw_073 VIA SELECTION-SCREEN AND RETURN.
      PERFORM display_alv.
    WHEN 'SAVE'.
      PERFORM save_data.
    WHEN 'DISPCHANGE'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.

      ELSE.                            "Change mode to DISPLAY
        gf_dispchg = gc_display.
        SELECT * INTO TABLE gt_swsodorgm FROM /psyng/swsodorgm.
        SORT gt_swsodorgm.
      ENDIF.
      PERFORM display_alv.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv OUTPUT.
  PERFORM display_alv .
ENDMODULE.                 " DISPLAY_ALV  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  display_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv.
*----Preparing field catalog.
  PERFORM prepare_field_catalog CHANGING gt_fieldcat .

  IF gr_alvgrid IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer
      EXPORTING
        container_name              = gc_custom_control_name
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent          = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.

    CALL METHOD gr_alvgrid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_enter.
    CALL METHOD gr_alvgrid->register_edit_event
        EXPORTING
          i_event_id = cl_gui_alv_grid=>mc_evt_modified.

*----Preparing layout structure
    PERFORM prepare_layout CHANGING gs_layout .
    SET HANDLER gr_event_handler->handle_user_command FOR gr_alvgrid  .
    SET HANDLER gr_event_handler->handle_toolbar FOR gr_alvgrid       .
*    SET HANDLER gr_event_handler->data_changed FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_on_f4 FOR gr_alvgrid .
*----Here will be additional preparations
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
    CALL METHOD gr_alvgrid->set_table_for_first_display
      EXPORTING
*    I_BUFFER_ACTIVE               =
*    I_CONSISTENCY_CHECK           =
*    I_STRUCTURE_NAME              =
*    IS_VARIANT                    =
*    I_SAVE                        =
*    I_DEFAULT                     = 'X'
        is_layout                     = gs_layout
*    IS_PRINT                      =
*    IT_SPECIAL_GROUPS             =
*    IT_TOOLBAR_EXCLUDING          =
*    IT_HYPERLINK                  =
      CHANGING
        it_outtab                     = gt_swsodorgm[]
        it_fieldcatalog               = gt_fieldcat
*    IT_SORT                       =
*    IT_FILTER                     =
  EXCEPTIONS
    invalid_parameter_combination = 1
    program_error                 = 2
    too_many_lines                = 3
    OTHERS                        = 4 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.

  ELSE .
    CALL METHOD gr_alvgrid->set_frontend_fieldcatalog
          EXPORTING
            it_fieldcatalog = gt_fieldcat    .

    CALL METHOD gr_alvgrid->refresh_table_display
*  EXPORTING
*    IS_STABLE      =
*    I_SOFT_REFRESH =
      EXCEPTIONS
        finished       = 1
        OTHERS         = 2 .

    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.

  ENDIF .


*--Set f4 enabled fields (Sorted Table!!)
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE .
  FREE : lt_f4.
  lt_f4-fieldname = 'HIGH'.
  lt_f4-register  = 'X' .
  lt_f4-getbefore = 'X' .
  APPEND lt_f4 .

  lt_f4-fieldname = 'LOW'.
  lt_f4-register  = 'X' .
  lt_f4-getbefore = 'X' .
  APPEND lt_f4 .

  lt_f4-fieldname = 'OBJECT'.
  lt_f4-register  = 'X' .
  lt_f4-getbefore = 'X' .
  APPEND lt_f4 .
  lt_f4-fieldname = 'VARBL'.
  lt_f4-register  = 'X' .
  lt_f4-getbefore = 'X' .
  APPEND lt_f4 .


  CALL METHOD gr_alvgrid->register_f4_for_fields
    EXPORTING
      it_f4  = lt_f4[] .


ENDFORM.                    " display_alv


*---------------------------------------------------------------------*
*       FORM prepare_field_catalog                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  PT_FIELDCAT                                                   *
*---------------------------------------------------------------------*
FORM prepare_field_catalog CHANGING pt_fieldcat TYPE lvc_t_fcat .
  DATA ls_fcat TYPE lvc_s_fcat .
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
*-Exception handling
  ENDIF.
  LOOP AT pt_fieldcat INTO ls_fcat .
    IF gf_dispchg =  gc_change.
      ls_fcat-edit = 'X'.
    ELSE.
      CLEAR ls_fcat-edit.
    ENDIF.

    CASE ls_fcat-fieldname .
      WHEN 'OBJECT' .
        ls_fcat-f4availabl = 'X'.
        ls_fcat-outputlen = 15.
      WHEN 'VARBL'.
        ls_fcat-f4availabl = 'X'.
        ls_fcat-outputlen = 15.

      WHEN 'LOW'  .
        ls_fcat-coltext   = 'Low value'(001) .
        ls_fcat-seltext   = 'Low value'(001) .
        ls_fcat-f4availabl = 'X'.

      WHEN 'HIGH'  .
        ls_fcat-coltext   = 'High value'(002) .
        ls_fcat-seltext   = 'High value'(002) .
        ls_fcat-f4availabl = 'X'.
    ENDCASE .
    MODIFY pt_fieldcat FROM ls_fcat .
  ENDLOOP .
ENDFORM .
*---------------------------------------------------------------------*
*       FORM prepare_layout                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  PS_LAYOUT                                                     *
*---------------------------------------------------------------------*
FORM prepare_layout CHANGING ps_layout TYPE lvc_s_layo.

  ps_layout-zebra = 'X' .
  ps_layout-grid_title = 'Maintain Organizational Areas'(005) .
  ps_layout-smalltitle = 'X' .

ENDFORM.                    " prepare_layout
*&---------------------------------------------------------------------*
*&      Form  save_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM save_data.
  CALL METHOD gr_alvgrid->check_changed_data.
*     Delete all rows
*BOC:HBHALLA (17/12/24)
  DELETE  FROM /psyng/swsodorgm
  WHERE abb NE space.
  .
*EOC:HBHALLA (17/12/24)
  COMMIT WORK.
  READ TABLE gt_swsodorgm WITH KEY abb = ''.
  IF sy-subrc = 0.
    MESSAGE e208(00) WITH 'Abbreviation cannot be blank.'(006).
    EXIT.
  ENDIF.
  READ TABLE gt_swsodorgm WITH KEY object = ''.
  IF sy-subrc = 0.
    MESSAGE e208(00) WITH 'Object cannot be blank.'(007).
    EXIT.
  ENDIF.

  READ TABLE gt_swsodorgm WITH KEY varbl = ''.
  IF sy-subrc = 0.
    MESSAGE e208(00) WITH 'Org Level cannot be blank.'(008).
    EXIT.
  ENDIF.

  READ TABLE gt_swsodorgm WITH KEY low = ''.
  IF sy-subrc = 0.
    MESSAGE e208(00) WITH 'Low Value cannot be blank.'(009).
    EXIT.
  ENDIF.


  DELETE gt_swsodorgm WHERE abb = space.

  SORT gt_swsodorgm BY abb object varbl low high.
  DELETE ADJACENT DUPLICATES FROM gt_swsodorgm
  COMPARING abb object varbl low high.
  IF sy-subrc = 0.
    MESSAGE i002(/psyng/sw) WITH 'Duplicate Entries Removed.'.
  ENDIF.

*     Insert from internal table
  MODIFY /psyng/swsodorgm FROM TABLE gt_swsodorgm.
  COMMIT WORK.
  MESSAGE s120(/psyng/sw).
  SELECT * INTO TABLE gt_swsodorgm FROM /psyng/swsodorgm.
  SORT gt_swsodorgm.
  PERFORM display_alv.
*   Data Saved

ENDFORM.                    " save_data

*---------------------------------------------------------------------*
*       FORM handle_toolbar                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_OBJECT                                                      *
*  -->  I_INTERACTIVE                                                 *
*---------------------------------------------------------------------*
FORM handle_toolbar USING
 i_object TYPE REF TO cl_alv_event_toolbar_set
 i_interactive
.

  DATA: ls_toolbar  TYPE stb_button.

*  CLEAR ls_toolbar.
*  MOVE 3 TO ls_toolbar-butn_type.
*  APPEND ls_toolbar TO i_object->mt_toolbar.

  CLEAR ls_toolbar.
  MOVE 'DISPCHANGE' TO ls_toolbar-function.
  MOVE '@3I@' TO ls_toolbar-icon.
  MOVE 'Display/Change'(003) TO ls_toolbar-quickinfo.
*  MOVE 'Display/Change'(003) TO ls_toolbar-text.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
*  APPEND ls_toolbar TO i_object->mt_toolbar.
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 1.
  IF gf_dispchg = gc_display.
    DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
  ENDIF.


ENDFORM .
*&---------------------------------------------------------------------*
*&      Form  handle_user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_UCOMM  text
*----------------------------------------------------------------------*
FORM handle_user_command USING    i_ucomm.
  CASE i_ucomm.
    WHEN 'EXIT'.
      PERFORM dequeue.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'SAVE'.
      PERFORM save_data.
    WHEN 'DISPCHANGE'.

      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
        PERFORM check_authorization USING gf_dispchg.
        PERFORM enqueue.
      ELSE.                            "Change mode to DISPLAY
        PERFORM dequeue.
        gf_dispchg = gc_display.
        SELECT * INTO TABLE gt_swsodorgm FROM /psyng/swsodorgm.
        SORT gt_swsodorgm.
      ENDIF.
      PERFORM display_alv.
  ENDCASE.

ENDFORM.                    " handle_user_command
*&---------------------------------------------------------------------*
*&      Form  f4_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_FIELDNAME  text
*      -->P_ES_ROW_NO  text
*----------------------------------------------------------------------*
FORM f4_help USING    i_fieldname TYPE lvc_fname
                      is_row_no TYPE lvc_s_roid.
  FIELD-SYMBOLS : <row> LIKE LINE OF  gt_swsodorgm.
  DATA : l_repid LIKE sy-repid,
         l_dynnr LIKE sy-dynnr,
         l_disp TYPE flag,
         lt_returntab TYPE TABLE OF ddshretval WITH HEADER LINE,
         ls_stable TYPE  lvc_s_stbl,
         l_fname TYPE lvc_fname,
         ls_authx TYPE authx,
         ls_dd35l TYPE dd35l.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA : BEGIN OF lt_shelp OCCURS 0,
            field TYPE xufield,
         END OF lt_shelp,
         lt_tobj TYPE TABLE OF tobj WITH HEADER LINE.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_usorg TYPE TABLE OF usorg,
              lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  IF gf_dispchg = gc_change.
    CLEAR l_disp.
  ELSE.
    l_disp = 'X'.
  ENDIF.
  READ TABLE gt_swsodorgm INDEX is_row_no-row_id ASSIGNING <row>.

  IF i_fieldname = 'LOW' OR i_fieldname = 'HIGH'.
    l_fname = <row>-varbl.
    SELECT SINGLE * FROM authx INTO ls_authx WHERE fieldname = l_fname.
    CHECK sy-subrc = 0.
    IF NOT ls_authx-checktable IS INITIAL AND
    ls_authx-rollname IS INITIAL.
      CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
           EXPORTING
                tabname           = ls_authx-checktable
                fieldname         = l_fname
                dynpprog          = l_repid
                dynpnr            = l_dynnr
                display           = l_disp
           TABLES
                return_tab        = lt_returntab
           EXCEPTIONS
                field_not_found   = 1
                no_help_for_field = 2
                inconsistent_help = 3
                no_values_found   = 4
                OTHERS            = 5.
      IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
      AND gf_dispchg = gc_change.
        READ TABLE lt_returntab INDEX 1.
*        <row>-object = lt_returntab-fieldval.
        CASE i_fieldname.
          WHEN 'LOW'.
            <row>-low = lt_returntab-fieldval.
          WHEN 'HIGH'.
            <row>-high = lt_returntab-fieldval.
        ENDCASE.
      ENDIF.
    ELSEIF NOT ls_authx-rollname IS INITIAL.
      DATA :lt_dd07 TYPE TABLE OF dd07v WITH HEADER LINE.
      FREE : lt_dd07.
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
             ILLEGAL_INPUT   = 1
             OTHERS          = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
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
          CASE i_fieldname.
            WHEN 'LOW'.
              <row>-low = lt_return-fieldval.
            WHEN 'HIGH'.
              <row>-high = lt_return-fieldval.
          ENDCASE.


        ENDIF.

      ELSE.
        SELECT SINGLE * FROM dd35l
        INTO ls_dd35l
        WHERE tabname = ls_authx-checktable
        ."#EC SAST_CI_GEN_CHECK
        CHECK sy-subrc = 0.
        CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = ls_authx-checktable
            fieldname         = l_fname
            searchhelp        = ls_dd35l-shlpname
            dynpprog          = l_repid
            dynpnr            = l_dynnr
*            value             = l_val
*            multiple_choice   = 'X'
              display           = l_disp

       TABLES
            return_tab        = lt_returntab
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.
        IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
        AND gf_dispchg = gc_change.
          READ TABLE lt_returntab INDEX 1.
          CASE i_fieldname.
            WHEN 'LOW'.
              <row>-low = lt_returntab-fieldval.
            WHEN 'HIGH'.
              <row>-high = lt_returntab-fieldval.
          ENDCASE.
        ENDIF.



      ENDIF.


    ENDIF.

  ENDIF.

  IF i_fieldname = 'OBJECT'.
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
         EXPORTING
              tabname           = 'USOBX'
              fieldname         = i_fieldname
              dynpprog          = l_repid
              dynpnr            = l_dynnr
              display           = l_disp
         TABLES
              return_tab        = lt_returntab
         EXCEPTIONS
              field_not_found   = 1
              no_help_for_field = 2
              inconsistent_help = 3
              no_values_found   = 4
              OTHERS            = 5.
    IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
    AND gf_dispchg = gc_change.
      READ TABLE lt_returntab INDEX 1.
      <row>-object = lt_returntab-fieldval.
    ENDIF.

  ENDIF.

  IF i_fieldname = 'VARBL'.
    SELECT * FROM usorg INTO TABLE lt_usorg.
    CHECK NOT lt_usorg IS INITIAL.
    lt_fields-tabname   = 'TOBJ'.
    lt_fields-fieldname = 'OBJCT'.
    APPEND lt_fields.

    lt_fields-tabname   = 'USORG'.
    lt_fields-fieldname = 'FIELD'.
    APPEND lt_fields.

    lt_fields-tabname   = 'DD04T'.
    lt_fields-fieldname = 'DDTEXT'.
    APPEND lt_fields.

    SELECT * FROM tobj INTO TABLE lt_tobj WHERE objct = <row>-object.
    LOOP AT lt_tobj.
*--Field1
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel1
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel1.
        APPEND lt_values.

        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
          INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel1
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.
      ENDIF.
*--Field2
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel2
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel2.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
           INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel2
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
*--Field3
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel3
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel3.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
          INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel3
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
*--Field4
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel4
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel4.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
            INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel4
                 AND dd04t~ddlanguage = sy-langu.
        APPEND lt_values.

      ENDIF.
*--Field5
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel5
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel5.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
            INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel5
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
*--Field6
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel6
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel6.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
             INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel6
                 AND dd04t~ddlanguage = sy-langu.
        APPEND lt_values.

      ENDIF.
*--Field7
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel7
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel7.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
            INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel7
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
*--Field8
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel8
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel8.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
           INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel8
                 AND dd04t~ddlanguage = sy-langu.
        APPEND lt_values.

      ENDIF.
*--Field9
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel9
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel9.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
             INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel9
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
*--Field0
      READ TABLE lt_usorg WITH KEY field = lt_tobj-fiel0
      TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        lt_values-line = <row>-object.
        APPEND lt_values.
        lt_values-line = lt_tobj-fiel0.
        APPEND lt_values.
        SELECT SINGLE dd04t~ddtext                   "#EC CI_SEL_NESTED
             INTO lt_values-line
                FROM authx INNER JOIN dd04t
                  ON authx~rollname = dd04t~rollname
               WHERE authx~fieldname = lt_tobj-fiel0
                 AND dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
        APPEND lt_values.

      ENDIF.
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
      <row>-varbl = lt_return-fieldval.
    ENDIF.



  ENDIF.

  ls_stable-row = 'X'.
  ls_stable-col = 'X'.
  CALL METHOD gr_alvgrid->refresh_table_display
EXPORTING
  is_stable      = ls_stable
*    I_SOFT_REFRESH = 'X'
    EXCEPTIONS
      finished       = 1
      OTHERS         = 2 .

  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.                                                    " f4_help

*---------------------------------------------------------------------*
*       FORM enqueue                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM enqueue.
  CALL FUNCTION 'ENQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname        = '/PSYNG/SWSODORGM'
       EXCEPTIONS
            foreign_lock   = 1
            system_failure = 2
            OTHERS         = 3.
  IF sy-subrc = 0.
    gf_dispchg = gc_change."Change mode
  ELSE.
    MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.

    gf_dispchg = gc_display."Display mode
  ENDIF.
ENDFORM.                    " enqueue
*---------------------------------------------------------------------*
*       FORM dequeue                                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM dequeue.
  CALL FUNCTION 'DEQUEUE_/PSYNG/TABLE'
       EXPORTING
            tabname = '/PSYNG/SWSODORGM'.
ENDFORM.                    " dequeue
*&---------------------------------------------------------------------*
*&      Form  check_authorization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GF_DISPCHG  text
*----------------------------------------------------------------------*
FORM check_authorization USING    if_dispchg.
  DATA : l_actvt(2) TYPE c,
         l_msg TYPE string.
  IF if_dispchg = gc_display.
    l_actvt = '03'."display
    l_msg = 'Display'(a01).
  ELSE.
    l_actvt = '02'."change
    l_msg = 'Change'(a02).

  ENDIF.

  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
          ID 'DICBERCLS' FIELD 'Y&S5'
          ID 'ACTVT' FIELD l_actvt.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH l_msg 'Org. Values'(003).
*   You are not authorized to & & & &

  ENDIF.

ENDFORM.                    " check_authorization
