REPORT /psyng/sw_126 .
INCLUDE :
   /psyng/basis_exelog,
   /psyng/sw_config.
TABLES : /psyng/sw_varvr.
DATA : g_varel_vrsio       LIKE /psyng/sw_varvr-varel_vrsio,
       g_varel_vrdesc      LIKE /psyng/sw_varvr-description,
       g_new_vrsio         TYPE /psyng/ve_vrsio,
       g_new_vrdesc(132)   TYPE c,
       g_newvrsio_t        TYPE c,
       gf_data_changed     TYPE flag,
       g_rfcdest           TYPE rfcdest.

DATA: BEGIN OF gt_func OCCURS 0,
        fcode LIKE rsmpe-func,
      END OF gt_func.

DATA : BEGIN OF gt_sw_varel OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_varel.
DATA : icon                TYPE icon_d,
       icon_1              TYPE icon_d.
DATA : END OF gt_sw_varel,
       gf_dispchg(1)       TYPE c,
       gt_sort             TYPE lvc_t_sort,
       gs_fieldcat         TYPE lvc_s_fcat.

FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.

DATA : BEGIN OF gt_detail OCCURS 0,
       var_element         TYPE /psyng/sw_varel-var_element,
       field               TYPE /psyng/sw_varel-field,
       value               TYPE /psyng/sw_varel-val_from,
       END OF gt_detail.


CONSTANTS: gc_display(1)   TYPE c VALUE 'D',
           gc_change(1)    TYPE c VALUE 'C'.

DEFINE add_column.
  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lowercase = 'X'.
  if gf_dispchg =  gc_change.
    gs_fieldcat-edit = &6.
  endif.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-checkbox  = &8.
  append gs_fieldcat to &4.
END-OF-DEFINITION.





*-- Global data definitions for ALV
*--- ALV Grid instance reference
DATA : gr_alvgrid TYPE REF TO cl_gui_alv_grid,
       gr_alvgrid2 TYPE REF TO cl_gui_alv_grid.
*--- Name of the custom control added on the screen
DATA: gc_custom_control_name TYPE scrfname VALUE 'CC_ALV',
      gc_custom_control_name2 TYPE scrfname VALUE 'DETAIL'  .
*--- Custom container instance reference
DATA: gr_ccontainer TYPE REF TO cl_gui_custom_container,
      gr_ccontainer2 TYPE REF TO cl_gui_custom_container .
*--- Field catalog table
DATA gt_fieldcat TYPE lvc_t_fcat .
*--- Layout structure
DATA : gs_layout     TYPE lvc_s_layo,
       gs_layout_sum TYPE lvc_s_layo .

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
*--Hotspot click control
  handle_hotspot_click
  FOR EVENT hotspot_click OF cl_gui_alv_grid
  IMPORTING e_row_id e_column_id es_row_no,
*--Override commands
    handle_before_user_command
    FOR EVENT before_user_command OF cl_gui_alv_grid
    IMPORTING e_ucomm,
    handle_data_changed
      FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING er_data_changed
                e_onf4
                e_onf4_before
                e_onf4_after.
*                sender.


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
*    er_event_data->m_event_handled = 'X' .
  ENDMETHOD.
*--Handle Before User Command
  METHOD handle_before_user_command .
    CASE e_ucomm .
      WHEN '&INFO' .
        CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
             EXPORTING
                  dokname = '/PSYNG/SE_VAREL_DOC'.
        CALL METHOD gr_alvgrid->set_user_command
        EXPORTING i_ucomm = space.
    ENDCASE .
  ENDMETHOD .

*--Handle Hotspot Click
  METHOD handle_hotspot_click .
    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
  ENDMETHOD .
  METHOD handle_data_changed.
    DATA: lo_data_changed    TYPE REF TO cl_alv_changed_data_protocol.
    gf_data_changed = 'X'.
    IF (  er_data_changed IS INITIAL ).
      CREATE OBJECT lo_data_changed
        EXPORTING
          i_calling_alv = gr_alvgrid.
    ELSE.
      lo_data_changed = er_data_changed.
    ENDIF.
    PERFORM validate_alv_data USING lo_data_changed.
  ENDMETHOD.
ENDCLASS .
DATA gr_event_handler TYPE REF TO  lcl_event_handler .
*--Registering handler methods to handle ALV Grid events

INITIALIZATION.
  exelog sy-repid ''.
  PERFORM init_varel_rules.

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
                 gf_dispchg
                 g_varel_vrsio.

  PERFORM select_rules_version USING  g_varel_vrsio.

  PERFORM get_varel_data.

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
  DATA : lf_continue TYPE flag,
         l_modified type i.

  CLEAR lf_continue.
  CASE sy-ucomm.
    WHEN 'EXIT' or 'CANCEL' or 'BACK'.
     CALL METHOD gr_alvgrid->check_changed_data.
      PERFORM has_data_changed
                  CHANGING
                     lf_continue.
      IF lf_continue = 'X'.
        SET SCREEN 0.
        LEAVE SCREEN.
      ENDIF.
    WHEN 'REFRESH' OR 'ENTER'.
      PERFORM has_data_changed
                  CHANGING
                     lf_continue.
      IF lf_continue = 'X'.
        PERFORM select_rules_version USING g_varel_vrsio.
        REFRESH gt_sw_varel.
        PERFORM get_varel_data.
        PERFORM display_alv.
      ENDIF.
    WHEN 'UPLOAD'.
      PERFORM has_data_changed
                  CHANGING
                     lf_continue.
      IF lf_continue = 'X'.
        SUBMIT /psyng/sw_127
        WITH vvrsio = g_varel_vrsio
        VIA SELECTION-SCREEN AND RETURN.
        PERFORM display_alv.
      ENDIF.
    WHEN 'SAVE'.
      PERFORM save_data.
    WHEN 'NEWVRSIO'.
      PERFORM has_data_changed
                  CHANGING
                     lf_continue.
      IF lf_continue = 'X'.
        g_newvrsio_t = 'N'.
        CLEAR: /psyng/sw_varvr-varel_vrsio,
           /psyng/sw_varvr-description.
        CALL SCREEN '0200' STARTING AT 5 5.
      ENDIF.
    WHEN 'COPYVRSIO'.
      PERFORM has_data_changed
                  CHANGING
                     lf_continue.
      IF lf_continue = 'X'.
        g_newvrsio_t = 'C'.
        CLEAR: /psyng/sw_varvr-varel_vrsio,
           /psyng/sw_varvr-description.
        CALL SCREEN '0200' STARTING AT 5 5.
      ENDIF.
    WHEN 'DELVRSIO'.
      PERFORM delete_version.
    WHEN 'DISPCHANGE'.
      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
      ELSE.                            "Change mode to DISPLAY
        PERFORM has_data_changed
                    CHANGING
                       lf_continue.
        IF lf_continue = 'X'.
          gf_dispchg = gc_display.
          REFRESH gt_sw_varel.
          PERFORM get_varel_data.
        ENDIF.
      ENDIF.
      PERFORM display_alv.
     WHEN 'INFO'.
      CALL FUNCTION 'DOCU_CALL'
         EXPORTING
          displ                   = 'X'
          displ_mode              = '2'
          id                      = 'RE'
          langu                   = sy-langu
          object                  = '/PSYNG/SW_126'
          typ                     = 'E'
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             WRONG_NAME = 1
             OTHERS     = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

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
  REFRESH : gt_fieldcat,gt_sort.
*----Preparing field catalog.
  PERFORM prepare_field_catalog CHANGING gt_fieldcat.
  PERFORM prepare_sort CHANGING gt_sort.

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
*    Refresh gr_ccontainer[].

*----Preparing layout structure
    PERFORM prepare_layout CHANGING gs_layout_sum.
    PERFORM prepare_layout CHANGING gs_layout.

    SET HANDLER gr_event_handler->handle_user_command FOR gr_alvgrid  .
    SET HANDLER gr_event_handler->handle_toolbar FOR gr_alvgrid       .
    SET HANDLER gr_event_handler->handle_on_f4 FOR gr_alvgrid .
    SET HANDLER gr_event_handler->handle_data_changed FOR gr_alvgrid .

    SET HANDLER gr_event_handler->handle_hotspot_click FOR gr_alvgrid .
    SET HANDLER gr_event_handler->handle_before_user_command FOR
gr_alvgrid .
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
        it_outtab                     = gt_sw_varel[]
        it_fieldcatalog               = gt_fieldcat
    it_sort                       =    gt_sort
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
  DATA: lt_f4 TYPE lvc_t_f4 WITH HEADER LINE ,
  wa_f4 LIKE LINE OF lt_f4.
  FREE : lt_f4.

  wa_f4-fieldname = 'VAR_ELEMENT'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

  wa_f4-fieldname = 'ELEMENT'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

  wa_f4-fieldname = 'TABNAME'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

  wa_f4-fieldname = 'FIELD'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

  wa_f4-fieldname = 'V_SIGN'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

  wa_f4-fieldname = 'V_OPTION'.
  wa_f4-register  = 'X' .
  wa_f4-getbefore = 'X' .
  INSERT wa_f4 INTO TABLE lt_f4.

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

  add_column ' ' 'VAR_ELEMENT' 'Variable Element Name'
                                           pt_fieldcat 40 'X'  'X' ''.
  add_column 'X' 'ICON_1'   'Element Details' pt_fieldcat 10 '' '' '' .
  add_column ' ' 'VALUESET' 'Value Set'    pt_fieldcat 5 'X' 'X' ''.
  add_column 'X' 'ICON'     'Value Set Details' pt_fieldcat 10 '' '' ''.

  add_column ' ' 'ELEMENT'  'Auth.Field'   pt_fieldcat 15 'X' 'X' ''.
  add_column '' 'OUTPUTFLAG' 'Output'      pt_fieldcat 5 'X' '' 'X'.
  add_column ' ' 'TABNAME'   'Table Name'  pt_fieldcat 20 'X' 'X' ''.

  add_column ' ' 'FIELD'     'Field Name'  pt_fieldcat 15 'X' 'X' ''.
  add_column ' ' 'JOINFLAG'  'Join'        pt_fieldcat 5 'X' '' 'X'.
  add_column ' ' 'V_SIGN'    'Sign'        pt_fieldcat 5 'X' 'X' ''.
  add_column ' ' 'V_OPTION'  'Option'      pt_fieldcat 5 'X' 'X' ''.
  add_column ' ' 'VAL_FROM'  'Low'         pt_fieldcat 61 'X' '' ''.
  add_column ' ' 'VAL_TO'    'High'        pt_fieldcat 61 'X' '' ''.

  LOOP AT pt_fieldcat ASSIGNING <fcat>.
    CASE <fcat>-fieldname.
      WHEN 'TABNAME'.
*        <fcat>-ref_table = '/PSYNG/SW_VAREL'.
    ENDCASE.

*--- somehow in display mode fieldcat edit is not clear
*--- so making the same

 IF ( <fcat>-fieldname = 'VAR_ELEMENT' OR <fcat>-fieldname = 'VALUESET'
     OR <fcat>-fieldname = 'ELEMENT' OR <fcat>-fieldname = 'OUTPUTFLAG'
       OR <fcat>-fieldname = 'TABNAME' OR <fcat>-fieldname = 'FIELD'
       OR <fcat>-fieldname = 'JOINFLAG' OR <fcat>-fieldname = 'V_SIGN'
      OR <fcat>-fieldname = 'V_OPTION' OR <fcat>-fieldname = 'VAL_FROM'
       OR <fcat>-fieldname = 'VAL_TO' )
       AND ( gf_dispchg = gc_change ) .
      <fcat>-edit = 'X'.
    ELSE.
      CLEAR <fcat>-edit.
    ENDIF.
  ENDLOOP.

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
  ps_layout-grid_title = 'Maintain Variable Element Rules'(020) .
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
  DATA : lt_varel TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
       ls_version TYPE /psyng/sw_varvr,
       ls_authx TYPE authx,
       ls_dd02l TYPE dd02l.
*       lf_warning_shown type flag.
  TYPES:BEGIN OF ty_dd03l,
            tabname TYPE dd03l-tabname,
            fieldname TYPE dd03l-fieldname,
          END OF ty_dd03l.
  DATA: ls_dd03l TYPE dd03l.

  REFRESH lt_varel.
  CALL METHOD gr_alvgrid->check_changed_data.
*     Delete all rows wrt rule versio
*  DELETE  FROM /psyng/sw_varel CLIENT SPECIFIED
*  WHERE mandt = sy-mandt.
  DELETE gt_sw_varel WHERE var_element = space.
  SORT gt_sw_varel.
  DELETE ADJACENT DUPLICATES FROM gt_sw_varel.

**--- validations
  LOOP AT gt_sw_varel.
    IF NOT gt_sw_varel-element IS INITIAL.
*--No validation, should work on systems where fields don't exist
*      SELECT SINGLE fieldname INTO ls_authx
*            FROM authx WHERE fieldname =  gt_sw_varel-element.
*      IF sy-subrc <> 0.
**--Show a warning when auth field not correct
*        if lf_warning_shown <> 'X'.
*          MESSAGE w138(/psyng/sw) WITH
*          'Invalid Authorization Field'(v01).
*          lf_warning_shown = 'X'.
*        endif.
*      ENDIF.
    ELSE.
      MESSAGE e138(/psyng/sw) WITH 'Blank Authorization'(v05).
    ENDIF.

*    IF NOT gt_sw_varel-tabname IS INITIAL.
*--No validation, should work on systems where fields don't exist
*      SELECT SINGLE tabname INTO ls_dd02l
*      FROM dd02l WHERE tabname = gt_sw_varel-tabname.
*      IF sy-subrc <> 0.
*
**--Show a warning when auth field not correct
*        if lf_warning_shown <> 'X'.
*          MESSAGE w138(/psyng/sw) WITH 'Invalid Table'(v02).
*          lf_warning_shown = 'X'.
*        endif.
*
*      ENDIF.
*    ENDIF.

    IF NOT gt_sw_varel-field IS INITIAL.
*--No validation, should work on systems where fields don't exist
*      SELECT SINGLE tabname fieldname INTO ls_dd03l
*        FROM dd03l WHERE tabname =  gt_sw_varel-tabname
*                     AND fieldname = gt_sw_varel-field.
*      IF sy-subrc <> 0.
**--Show a warning when field not correct
*        if lf_warning_shown <> 'X'.
*          MESSAGE w138(/psyng/sw) WITH
*            'Invalid Field:'(v02) gt_sw_varel-field .
*          lf_warning_shown = 'X'.
*        endif.
*
*      ENDIF.
    ENDIF.

    IF gt_sw_varel-v_sign IS INITIAL.
      MESSAGE e138(/psyng/sw) WITH
           'Sign Value is Empty'(v03).
    ENDIF.
    IF gt_sw_varel-v_option IS INITIAL.
      MESSAGE e138(/psyng/sw) WITH
           'Option value is Empty'(v04).
    ENDIF.

  ENDLOOP.


*     Insert from internal table
  LOOP AT gt_sw_varel.
    MOVE-CORRESPONDING gt_sw_varel TO lt_varel.
    lt_varel-varel_vrsio =  g_varel_vrsio.
    APPEND lt_varel.
  ENDLOOP.

  DELETE  FROM /psyng/sw_varel
  WHERE varel_vrsio = g_varel_vrsio.
  COMMIT WORK.

  MODIFY /psyng/sw_varel FROM TABLE lt_varel.
*--Also save version Header
  ls_version-varel_vrsio = g_varel_vrsio.
  ls_version-description = g_varel_vrdesc.
  MODIFY /psyng/sw_varvr FROM ls_version.

  COMMIT WORK.
  MESSAGE s120(/psyng/sw).
*   Data Saved
  PERFORM get_varel_data.

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
  MOVE 'Display/Change'(021) TO ls_toolbar-quickinfo.
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
  DATA : lf_continue TYPE flag.
  CASE i_ucomm.
    WHEN 'EXIT'.
  PERFORM dequeue.
*      PERFORM has_data_changed
*                  CHANGING
*                     lf_continue.
*      IF lf_continue = 'X'.
*        SET SCREEN 0.
*        LEAVE SCREEN.
*      ENDIF.

      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'SAVE'.
      PERFORM save_data.
    WHEN 'DISPCHANGE'.

      IF gf_dispchg = gc_display.      "Change mode to CHANGE
        gf_dispchg = gc_change.
        PERFORM check_authorization USING gf_dispchg g_varel_vrsio.
        PERFORM enqueue.
      ELSE.                            "Change mode to DISPLAY

        PERFORM has_data_changed
                    CHANGING
                       lf_continue.
        IF  lf_continue = 'X'.
          PERFORM dequeue.
          gf_dispchg = gc_display.
*        SELECT * INTO TABLE gt_sw_varel                 "#EC CI_NOWHERE
*                                                        "#EC CI_NOFIELD
*                                                        "#EC CI_NOFIRST
*        FROM /psyng/sw_varel
*        where varel_vrsio = g_varel_vrsio.
*        SORT gt_sw_varel.
          PERFORM get_varel_data.
        ENDIF.
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
  FIELD-SYMBOLS : <row> LIKE LINE OF  gt_sw_varel.

  DATA :lt_dd07 TYPE TABLE OF dd07v WITH HEADER LINE.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_stable TYPE  lvc_s_stbl,
        ls_authx TYPE authx,
        ls_dd01v TYPE  dd01v,
        l_objname TYPE ddobjname.
  DATA : lt_dd04t TYPE TABLE OF dd04t WITH HEADER LINE,
         lt_dd03t TYPE TABLE OF dd03t WITH HEADER LINE,
         lt_dd02t TYPE TABLE OF dd02t WITH HEADER LINE.
  DATA:   BEGIN OF lt_varbl OCCURS 0,
          var_element TYPE /psyng/sw_varel-var_element,
          END OF lt_varbl,
         l_tabname type tabname.
  READ TABLE gt_sw_varel ASSIGNING <row> INDEX is_row_no-row_id.

  CASE i_fieldname.

    WHEN 'VALUESET'.
    WHEN 'V_SIGN'.

      lt_values-line = 'I'.
      APPEND lt_values.
      lt_values-line = 'E'.
      APPEND lt_values.

      lt_fields-tabname   = '/PSYNG/SW_VAREL'.
      lt_fields-fieldname = 'V_SIGN'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'V_SIGN'
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
        <row>-v_sign = lt_return-fieldval.
      ENDIF.

    WHEN 'V_OPTION'.

      lt_values-line = 'EQ'.
      APPEND lt_values.
      lt_values-line = 'NE'.
      APPEND lt_values.
      lt_values-line = 'BT'.
      APPEND lt_values.
      lt_values-line = 'GE'.
      APPEND lt_values.
      lt_values-line = 'GT'.
      APPEND lt_values.
      lt_values-line = 'LE'.
      APPEND lt_values.
      lt_values-line = 'LT'.
      APPEND lt_values.
      lt_values-line = 'CP'.
      APPEND lt_values.
      lt_values-line = 'NP'.
      APPEND lt_values.

      lt_fields-tabname   = '/PSYNG/SW_VAREL'.
      lt_fields-fieldname = 'V_OPTION'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'V_OPTION'
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
        <row>-v_option = lt_return-fieldval.
      ENDIF.

    WHEN 'TABNAME'.
    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
      EXPORTING
        tabname                   = '/PSYNG/SW_VAREL'
        fieldname                 = 'TABNAME'
*       SEARCHHELP                = ' '
*       SHLPPARAM                 = ' '
*       DYNPPROG                  = ' '
*       DYNPNR                    = ' '
*       DYNPROFIELD               = ' '
*       STEPL                     = 0
*       VALUE                     = ' '
*       MULTIPLE_CHOICE           = ' '
*       DISPLAY                   = ' '
*       SUPPRESS_RECORDLIST       = ' '
*       CALLBACK_PROGRAM          = ' '
*       CALLBACK_FORM             = ' '
     TABLES
       RETURN_TAB                = lt_return
     EXCEPTIONS
       FIELD_NOT_FOUND           = 1
       NO_HELP_FOR_FIELD         = 2
       INCONSISTENT_HELP         = 3
       NO_VALUES_FOUND           = 4
       OTHERS                    = 5
              .
      IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
      AND gf_dispchg = gc_change.
        READ TABLE lt_return INDEX 1.
        <row>-tabname = lt_return-fieldval.
      ENDIF.

    WHEN 'VAR_ELEMENT'.
      SELECT DISTINCT var_element FROM  /psyng/sw_varel INTO TABLE "#EC CI_NOWHERE
     lt_varbl.

      DELETE lt_varbl WHERE var_element EQ space.
*---convert into upper case
      LOOP AT lt_varbl.
        TRANSLATE lt_varbl TO UPPER CASE.
        MODIFY lt_varbl.
      ENDLOOP.
      SORT lt_varbl BY var_element.
      DELETE ADJACENT DUPLICATES FROM lt_varbl COMPARING var_element.

      LOOP AT lt_varbl.
        lt_values-line = lt_varbl-var_element.
        APPEND lt_values.
      ENDLOOP.

      FREE : lt_varbl.
      lt_fields-tabname   = '/PSYNG/SW_VAREL'.
      lt_fields-fieldname = 'VAR_ELEMENT'.
      APPEND lt_fields.

      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'VAR_ELEMENT'
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
        <row>-var_element = lt_return-fieldval.
      ENDIF.

    WHEN 'ELEMENT'.
     SELECT authx~rollname  dd04t~ddtext FROM dd04t INNER JOIN authx ON
                                       authx~rollname =  dd04t~rollname
                            INTO CORRESPONDING FIELDS OF TABLE lt_dd04t
          WHERE dd04t~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
      LOOP AT lt_dd04t.
        lt_values-line = lt_dd04t-rollname.
        APPEND lt_values.
        lt_values-line = lt_dd04t-ddtext.
        APPEND lt_values.

      ENDLOOP.

      FREE : lt_dd07.
      lt_fields-tabname   = 'AUTHX'.
      lt_fields-fieldname = 'ROLLNAME'.
      APPEND lt_fields.
      lt_fields-tabname   = 'DD04T'.
      lt_fields-fieldname = 'DDTEXT'.
      APPEND lt_fields.
      CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
           EXPORTING
                retfield        = 'ROLLNAME'
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
        <row>-element = lt_return-fieldval.
      ENDIF.
    WHEN 'FIELD'.
*--Search help on the field of the table associated with this auth field
*1.Get the table
      READ TABLE gt_sw_varel INDEX is_row_no-row_id.
      IF sy-subrc = 0 AND NOT gt_sw_varel-element IS INITIAL.
        FREE : lt_dd07.
        lt_fields-tabname   = 'DD03T'.
        lt_fields-fieldname = 'FIELDNAME'.
        APPEND lt_fields.
        lt_fields-tabname   = 'DD03T'.
        lt_fields-fieldname = 'DDTEXT'.
        APPEND lt_fields.


*1.Get the table name
        SELECT SINGLE * FROM authx INTO ls_authx
        WHERE fieldname =  gt_sw_varel-element."#EC SAST_CI_GEN_CHECK
        IF ls_authx-checktable IS INITIAL.
          l_objname =  gt_sw_varel-element.
          CALL FUNCTION 'DDIF_DOMA_GET'
               EXPORTING
                    name          = l_objname
               IMPORTING
                    dd01v_wa      = ls_dd01v
               EXCEPTIONS
                    illegal_input = 1
                    OTHERS        = 2.
          IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          ls_authx-checktable = ls_dd01v-entitytab.
        ENDIF.
*2. Get the fields of that table
        SELECT dd03l~fieldname  dd03t~ddtext FROM dd03l
        LEFT JOIN dd03t ON
                  dd03l~tabname   = dd03t~tabname   AND
                  dd03l~fieldname = dd03t~fieldname AND
                  dd03t~ddlanguage = sy-langu
         INTO CORRESPONDING FIELDS OF TABLE lt_dd03t
   WHERE dd03l~tabname = ls_authx-checktable."#EC SAST_CI_GEN_CHECK
*--Get the missing labels
        IF NOT lt_dd03t[] IS INITIAL.
          SELECT rollname ddtext FROM dd04t
          INTO CORRESPONDING FIELDS OF TABLE lt_dd04t
          FOR ALL ENTRIES IN lt_dd03t
          WHERE rollname = lt_dd03t-fieldname
          AND ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK
          SORT lt_dd04t BY rollname.
        ENDIF.
        LOOP AT lt_dd03t.
          lt_values-line = lt_dd03t-fieldname.
          APPEND lt_values.
          IF lt_dd03t-ddtext IS INITIAL.
           READ TABLE lt_dd04t WITH KEY rollname  =  lt_dd03t-fieldname
                                                          BINARY SEARCH.
            IF sy-subrc = 0.
              lt_dd03t-ddtext = lt_dd04t-ddtext.
            ENDIF.
          ENDIF.
          lt_values-line = lt_dd03t-ddtext.
          APPEND lt_values.
        ENDLOOP.

        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
             EXPORTING
                  retfield        = 'FIELDNAME'
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
          <row>-field = lt_return-fieldval.
        ENDIF.

      ENDIF.
  ENDCASE.

*  FIELD-SYMBOLS : <row> LIKE LINE OF  gt_SW_VAREL.
*  DATA : l_repid LIKE sy-repid,
*         l_dynnr LIKE sy-dynnr,
*         l_disp TYPE flag,
*         lt_returntab TYPE TABLE OF ddshretval WITH HEADER LINE,
*         ls_stable TYPE  lvc_s_stbl,
*         l_fname TYPE lvc_fname,
*         ls_authx TYPE authx,
*         ls_dd35l TYPE dd35l.
*  DATA: BEGIN OF lt_values OCCURS 0,
*          line(255) TYPE c,
*        END OF lt_values.
*  DATA : BEGIN OF lt_shelp OCCURS 0,
*            field TYPE xufield,
*         END OF lt_shelp,
*         lt_authx TYPE TABLE OF authx WITH HEADER LINE.
*  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
*        lt_usorg TYPE TABLE OF usorg,
*              lt_return TYPE TABLE OF ddshretval WITH HEADER LINE.
*
*  l_repid = sy-repid.
*  l_dynnr = sy-dynnr.
*  IF gf_dispchg = gc_change.
*    CLEAR l_disp.
*  ELSE.
*    l_disp = 'X'.
*  ENDIF.
*  READ TABLE gt_SW_VAREL INDEX is_row_no-row_id ASSIGNING <row>.
*
*  IF i_fieldname = 'LOW' OR i_fieldname = 'HIGH'.
*    l_fname = <row>-field.
*    SELECT SINGLE * FROM authx INTO ls_authx WHERE fieldname = l_fname.
*    CHECK sy-subrc = 0.
*    IF NOT ls_authx-checktable IS INITIAL AND
*    ls_authx-rollname IS INITIAL.
*      CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
*           EXPORTING
*                tabname           = ls_authx-checktable
*                fieldname         = l_fname
*                dynpprog          = l_repid
*                dynpnr            = l_dynnr
*                display           = l_disp
*           TABLES
*                return_tab        = lt_returntab
*           EXCEPTIONS
*                field_not_found   = 1
*                no_help_for_field = 2
*                inconsistent_help = 3
*                no_values_found   = 4
*                OTHERS            = 5.
*      IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
*      AND gf_dispchg = gc_change.
*        READ TABLE lt_returntab INDEX 1.
**        <row>-object = lt_returntab-fieldval.
*        CASE i_fieldname.
*          WHEN 'LOW'.
*            <row>-val_from = lt_returntab-fieldval.
*          WHEN 'HIGH'.
*            <row>-val_to   = lt_returntab-fieldval.
*        ENDCASE.
*      ENDIF.
*    ELSEIF NOT ls_authx-rollname IS INITIAL.
*      DATA :lt_dd07 TYPE TABLE OF dd07v WITH HEADER LINE.
*      FREE : lt_dd07.
*      lt_fields-tabname   = 'DD07V'.
*      lt_fields-fieldname = 'DOMVALUE_L'.
*      APPEND lt_fields.
*      lt_fields-tabname   = 'DD07V'.
*      lt_fields-fieldname = 'DDTEXT'.
*      APPEND lt_fields.
*
*      CALL FUNCTION 'DDIF_DOMA_GET'
*           EXPORTING
*                name      = ls_authx-rollname
*                langu     = sy-langu
*           TABLES
*                dd07v_tab = lt_dd07.
*      IF sy-subrc = 0 AND NOT lt_dd07[] IS INITIAL.
*        LOOP AT lt_dd07.
*          lt_values-line = lt_dd07-domvalue_l.
*          APPEND lt_values.
*          lt_values-line = lt_dd07-ddtext.
*          APPEND lt_values.
*        ENDLOOP.
*        CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*             EXPORTING
*                  retfield        = 'DOMVALUE_L'
*             TABLES
*                  value_tab       = lt_values
*                  field_tab       = lt_fields
*                  return_tab      = lt_return
*             EXCEPTIONS
*                  parameter_error = 1
*                  no_values_found = 2
*                  OTHERS          = 3.
*        IF sy-subrc <> 0.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDIF.
*        IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
*        AND gf_dispchg = gc_change.
*          READ TABLE lt_return INDEX 1.
*          CASE i_fieldname.
*            WHEN 'LOW'.
*              <row>-val_from = lt_return-fieldval.
*            WHEN 'HIGH'.
*              <row>-val_to   = lt_return-fieldval.
*          ENDCASE.
*
*
*        ENDIF.
*
*      ELSE.
*        SELECT SINGLE * FROM dd35l
*        INTO ls_dd35l
*        WHERE tabname = ls_authx-checktable
*        .
*        CHECK sy-subrc = 0.
*        CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
*       EXPORTING
*            tabname           = ls_authx-checktable
*            fieldname         = l_fname
*            searchhelp        = ls_dd35l-shlpname
*            dynpprog          = l_repid
*            dynpnr            = l_dynnr
**            value             = l_val
**            multiple_choice   = 'X'
*              display           = l_disp
*
*       TABLES
*            return_tab        = lt_returntab
*       EXCEPTIONS
*            field_not_found   = 1
*            no_help_for_field = 2
*            inconsistent_help = 3
*            no_values_found   = 4
*            OTHERS            = 5.
*        IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
*        AND gf_dispchg = gc_change.
*          READ TABLE lt_returntab INDEX 1.
*          CASE i_fieldname.
*            WHEN 'LOW'.
*              <row>-val_from = lt_returntab-fieldval.
*            WHEN 'HIGH'.
*              <row>-val_to   = lt_returntab-fieldval.
*          ENDCASE.
*        ENDIF.
*
*
*
*      ENDIF.
*
*
*    ENDIF.
*
*  ENDIF.

*  IF i_fieldname = 'OBJECT'.
*    CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
*         EXPORTING
*              tabname           = 'USOBX'
*              fieldname         = i_fieldname
*              dynpprog          = l_repid
*              dynpnr            = l_dynnr
*              display           = l_disp
*         TABLES
*              return_tab        = lt_returntab
*         EXCEPTIONS
*              field_not_found   = 1
*              no_help_for_field = 2
*              inconsistent_help = 3
*              no_values_found   = 4
*              OTHERS            = 5.
*    IF sy-subrc = 0 AND NOT lt_returntab[] IS INITIAL
*    AND gf_dispchg = gc_change.
*      READ TABLE lt_returntab INDEX 1.
*      <row>-object = lt_returntab-fieldval.
*    ENDIF.
*
*  ENDIF.

*  IF i_fieldname = 'FIELD'.
*    SELECT * FROM usorg INTO TABLE lt_usorg.
*    CHECK NOT lt_usorg IS INITIAL.
*    lt_fields-tabname   = 'TOBJ'.
*    lt_fields-fieldname = 'OBJCT'.
*    APPEND lt_fields.
*
*    lt_fields-tabname   = 'USORG'.
*    lt_fields-fieldname = 'FIELD'.
*    APPEND lt_fields.
*
*    lt_fields-tabname   = 'DD04T'.
*    lt_fields-fieldname = 'DDTEXT'.
*    APPEND lt_fields.
*
*    SELECT * FROM AUTHX INTO TABLE lt_authx.
*    LOOP AT lt_authx.
*        lt_values-line = lt_authx-fieldname.
*        APPEND lt_values.
*        SELECT SINGLE dd04t~ddtext        "#EC CI_SEL_NESTED
*          INTO lt_values-line
*                FROM authx INNER JOIN dd04t
*                  ON authx~rollname   = dd04t~rollname
*               WHERE authx~fieldname  = lt_authx-fieldname
*                 AND dd04t~ddlanguage = sy-langu.
*        APPEND lt_values.
*    endloop.
*
*    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
*         EXPORTING
*              retfield        = 'FIELD'
*         TABLES
*              value_tab       = lt_values
*              field_tab       = lt_fields
*              return_tab      = lt_return
*         EXCEPTIONS
*              parameter_error = 1
*              no_values_found = 2
*              OTHERS          = 3.
*    IF sy-subrc <> 0.
*      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*              WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*    ENDIF.
*    IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL
*    AND gf_dispchg = gc_change.
*      READ TABLE lt_return INDEX 1.
*      <row>-FIELD = lt_return-fieldval.
*    ENDIF.
*
*
*
*  ENDIF.
*
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
            tabname        = '/PSYNG/SW_VAREL'
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
            tabname = '/PSYNG/SW_VAREL'.
ENDFORM.                    " dequeue


*---------------------------------------------------------------------*
*       FORM handle_before_user_command                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_UCOMM                                                       *
*---------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  check_authorization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GF_DISPCHG  text
*----------------------------------------------------------------------*
FORM check_authorization USING    if_dispchg
                                  i_vrsio.
  DATA : l_actvt(2) TYPE c,
         l_msg TYPE string.
  IF if_dispchg = gc_display.
    l_actvt = '03'."display
    l_msg = 'Display'(a01).
  ELSE.
    l_actvt = '02'."change
    l_msg = 'Change'(a02).

  ENDIF.

  AUTHORITY-CHECK OBJECT 'Y&SW_VERUL'
         ID 'ACTVT' FIELD l_actvt
         ID 'Y&SW_VEVRS' FIELD i_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH l_msg
    'Variable Element Rules version'(a03) i_vrsio.
*   You are not authorized to & & & &

  ENDIF.

ENDFORM.                    " check_authorization

*---------------------------------------------------------------------*
*       FORM has_data_changed                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  EF_CONTINUE                                                   *
*---------------------------------------------------------------------*
FORM has_data_changed CHANGING ef_continue.
  DATA : lf_refresh TYPE flag,
         lf_changes TYPE flag,
         lt_cells TYPE  lvc_t_moce,
         l_answer.
  ef_continue = 'X'.



  IF gf_data_changed = 'X'.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
           titlebar                    =
           'There are unsaved Changes'(c00)
*           DIAGNOSE_OBJECT             = ' '
        text_question               = 'Do you want to continue?'(c03)
           text_button_1               = 'Yes'(c01)
*           ICON_BUTTON_1               = ' '
           text_button_2               = 'No'(c02)
*           ICON_BUTTON_2               = ' '
           default_button              = '2'
           display_cancel_button       = ''
*           USERDEFINED_F1_HELP         = ' '
*           START_COLUMN                = 25
*           START_ROW                   = 6
*           POPUP_TYPE                  =
    IMPORTING
      answer                      = l_answer
*         TABLES
*           PARAMETER                   =
         EXCEPTIONS
           TEXT_NOT_FOUND              = 1
           OTHERS                      = 2.
"(++)BOC UMITTAL SE VF scan-25/11/2024
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_answer = '2'.
      CLEAR ef_continue.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  handle_hotspot_click
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_E_ROW_ID  text
*      -->P_E_COLUMN_ID  text
*      -->P_ES_ROW_NO  text
*----------------------------------------------------------------------*
FORM handle_hotspot_click USING i_row_id TYPE lvc_s_row
                                i_column_id TYPE lvc_s_col
                                is_row_no TYPE lvc_s_roid.
  .

  DATA : lt_faobj TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
         lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
         lt_varel LIKE TABLE OF gt_sw_varel WITH HEADER LINE,
         ls_varel LIKE LINE OF gt_sw_varel,
         l_index TYPE sy-index,
         lf_match TYPE flag,
         lt_values TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
         l_cnt TYPE i,
         l_cnt_s TYPE string,
         l_grid_pos TYPE lvc_s_stbl.
  l_grid_pos-row = i_row_id.
  l_grid_pos-col = i_column_id.
  l_index = i_row_id.
  REFRESH : lt_faobj,gt_detail[],lt_varel[].
  CALL METHOD gr_alvgrid->check_changed_data.
  READ TABLE gt_sw_varel INTO ls_varel INDEX l_index.
  IF sy-subrc = 0 AND NOT ls_varel-var_element IS INITIAL.
    IF i_column_id = 'OUTPUTFLAG'.
      IF gc_change = 'C'.
*--For all records for a table in a valueset,
*  the outputflag should be the same
        MODIFY gt_sw_varel FROM ls_varel
          TRANSPORTING outputflag
          WHERE
          var_element = ls_varel-var_element AND
          tabname     = ls_varel-tabname     AND
          valueset    = ls_varel-valueset
          .
        CALL METHOD gr_alvgrid->refresh_table_display
      EXPORTING
        is_stable      = l_grid_pos
        i_soft_refresh = 'X'
          EXCEPTIONS
            finished       = 1
            OTHERS         = 2 .

        IF sy-subrc <> 0.
*--Exception handling
        ENDIF.
      ENDIF.
    ELSE.
      IF i_column_id = 'ICON'.
*  --Show details for value set
        LOOP AT gt_sw_varel WHERE var_element = ls_varel-var_element
                              AND valueset    = ls_varel-valueset.
          APPEND gt_sw_varel TO lt_varel.

        ENDLOOP.
      ENDIF.
      IF i_column_id = 'ICON_1'.
        CHECK NOT ls_varel-icon_1 = ' '.
*  --Show all details for Variable Element
        LOOP AT gt_sw_varel WHERE var_element = ls_varel-var_element.
          APPEND gt_sw_varel TO lt_varel.
        ENDLOOP.
      ENDIF.
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
      CALL FUNCTION '/PSYNG/SW_VE_002'
           DESTINATION g_rfcdest
           EXPORTING
                i_varel_vrsio        = g_varel_vrsio
                if_ignore_sod_matrix = 'X'
           TABLES
                et_return            = lt_return
                it_varel             = lt_varel
                et_values            = lt_values
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


      REFRESH : gt_detail.

      LOOP AT lt_values.
        gt_detail-var_element = lt_values-var_element.
        gt_detail-field       = ls_varel-element.
        gt_detail-value       = lt_values-value.
        APPEND gt_detail.
      ENDLOOP.
      SORT gt_detail.
      DELETE ADJACENT DUPLICATES FROM gt_detail.
      DESCRIBE TABLE gt_detail LINES l_cnt.
      l_cnt_s = l_cnt.
*  --Set the ALV Grid Title
      IF NOT g_rfcdest IS INITIAL.
        CONCATENATE l_cnt_s 'Variable Element Value(s) for System'(s01)
        g_rfcdest  INTO gs_layout-grid_title SEPARATED BY space.
      ELSE.
        CONCATENATE l_cnt_s 'Variable Element Value(s) for System'(s01)
        'LOCAL'  INTO gs_layout-grid_title SEPARATED BY space.
      ENDIF.

      CALL SCREEN '0101'.
    ENDIF.
  ENDIF.

ENDFORM.                    " handle_hotspot_click
*&---------------------------------------------------------------------*
*&      Form  prepare_sort
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_SORT  text
*----------------------------------------------------------------------*
FORM prepare_sort CHANGING pt_sort TYPE lvc_t_sort.

  DATA : ls_sort TYPE lvc_s_sort.

  ls_sort-up   = 'X'.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'VAR_ELEMENT'.
  APPEND ls_sort TO gt_sort.

*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'ICON_1'.
*  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'VALUESET'.
  APPEND ls_sort TO gt_sort.

*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'ICON'.
*  APPEND ls_sort TO gt_sort.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'ELEMENT'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'JOINFLAG'.
  APPEND ls_sort TO gt_sort.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'TABNAME'.
  APPEND ls_sort TO gt_sort.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'FIELD'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'VAL_FROM'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'VAL_TO'.
  APPEND ls_sort TO gt_sort.


ENDFORM.                    " prepare_sort
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV_detail  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_detail OUTPUT.
  PERFORM display_alv_detail.
ENDMODULE.                 " DISPLAY_ALV_detail  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  display_alv_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_detail.
  DATA: ls_stable TYPE lvc_s_stbl.
  REFRESH: gt_fieldcat,gt_sort.

  PERFORM prepare_detail_catalog CHANGING gt_fieldcat.
  PERFORM prepare_sort_d CHANGING gt_sort.

*----Creating custom container instance
  IF gr_ccontainer2 IS INITIAL.
    CREATE OBJECT gr_ccontainer2
      EXPORTING
        container_name              = 'DETAIL'
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
  ENDIF.

*----Creating ALV Grid instance
  IF gr_alvgrid2 IS INITIAL.
    CREATE OBJECT gr_alvgrid2
      EXPORTING
        i_parent          = gr_ccontainer2
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5 .
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.

  CALL METHOD gr_alvgrid2->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_detail[]
      it_fieldcatalog               = gt_fieldcat
     it_sort                        =  gt_sort
EXCEPTIONS
  invalid_parameter_combination = 1
  program_error                 = 2
  too_many_lines                = 3
  OTHERS                        = 4 .
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.


ENDFORM.                    " display_alv_detail
*&---------------------------------------------------------------------*
*&      Form  prepare_detail_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM prepare_detail_catalog CHANGING pt_fieldcat TYPE lvc_t_fcat.
  DATA ls_fcat TYPE lvc_s_fcat .


  ls_fcat-fieldname = 'VAR_ELEMENT'.
  ls_fcat-coltext   = 'Variable Element Name'(003) .
  ls_fcat-seltext   = 'Variable Element Name'(003) .
  ls_fcat-outputlen = 20.
  APPEND ls_fcat TO pt_fieldcat.

  ls_fcat-fieldname = 'FIELD'.
  ls_fcat-seltext   = 'Field'.
  ls_fcat-coltext   = 'Field'.
  ls_fcat-outputlen = 20.
  APPEND ls_fcat TO pt_fieldcat.

  ls_fcat-fieldname = 'VALUE'.
  ls_fcat-seltext   = 'Value'.
  ls_fcat-coltext   = 'Value'.
  ls_fcat-outputlen = 20.
  APPEND ls_fcat TO pt_fieldcat.

ENDFORM.                    " prepare_detail_catalog
*&---------------------------------------------------------------------*
*&      Form  prepare_sort_d
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_SORT  text
*----------------------------------------------------------------------*
FORM prepare_sort_d CHANGING pt_sort TYPE lvc_t_sort.

  DATA : ls_sort TYPE lvc_s_sort.

  ls_sort-up   = 'X'.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'VAR_ELEMENT'.
  APPEND ls_sort TO gt_sort.

  ls_sort-fieldname = 'FIELD'.
  APPEND ls_sort TO gt_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'VALUE'.
  APPEND ls_sort TO gt_sort.

ENDFORM.                    " prepare_sort_d
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK' OR 'CANCEL' OR 'EXIT'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS '0101'.
  SET TITLEBAR '0101'.

ENDMODULE.                 " STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  get_varel_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_varel_data.
  DATA : ls_varel LIKE gt_sw_varel.
  SELECT * FROM /psyng/sw_varel                         "#EC CI_NOWHERE
                                                        "#EC CI_NOFIELD
                                                        "#EC CI_NOFIRST

  INTO CORRESPONDING FIELDS OF TABLE gt_sw_varel
  WHERE varel_vrsio = g_varel_vrsio.
  SORT gt_sw_varel.
  gt_sw_varel-icon = '@FB@'.
  gt_sw_varel-icon_1 = '@FB@'.
  MODIFY gt_sw_varel TRANSPORTING icon icon_1 WHERE icon IS initial.
  CLEAR gf_data_changed.


*--if a record for a table and valueset has the outputflag set to X,
*  it needs to be set for all records in that valueset for that table
  LOOP AT gt_sw_varel INTO ls_varel WHERE outputflag = 'X'.
    MODIFY gt_sw_varel FROM ls_varel
      TRANSPORTING outputflag
      WHERE
      var_element = ls_varel-var_element AND
      tabname     = ls_varel-tabname     AND
      valueset    = ls_varel-valueset.

  ENDLOOP.

ENDFORM.                    " get_varel_data
*&---------------------------------------------------------------------*
*&      Form  select_rules_version
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM select_rules_version USING i_vrsio.
  DATA : ls_version TYPE /psyng/sw_varvr.
  SELECT SINGLE *
  INTO ls_version
  FROM /psyng/sw_varvr
  WHERE varel_vrsio = i_vrsio.

  g_varel_vrsio  = ls_version-varel_vrsio.
  g_varel_vrdesc = ls_version-description.

ENDFORM.                    " select_rules_version
*&---------------------------------------------------------------------*
*&      Module  STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0200 OUTPUT.
  gt_func-fcode = 'OK'.
  APPEND gt_func.
  SET PF-STATUS '0200' EXCLUDING gt_func.
  CASE g_newvrsio_t.
    WHEN 'N'."new
      SET TITLEBAR '0200_CREATE'.
    WHEN 'C'."copy
      SET TITLEBAR '0200_COPY' WITH g_varel_vrsio.
  ENDCASE.

ENDMODULE.                 " STATUS_0200  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0200 INPUT.
  DATA : lt_varel TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN 0.
      LEAVE SCREEN.
    WHEN 'YES'.
      PERFORM create_new_version USING /psyng/sw_varvr-varel_vrsio.
      CASE g_newvrsio_t.
        WHEN 'N'."new
          MESSAGE i002(/psyng/sw) WITH
          'Created new version'  /psyng/sw_varvr-varel_vrsio.
          CLEAR: /psyng/sw_varvr-varel_vrsio,
            /psyng/sw_varvr-description.
        WHEN 'C'."copy
          MESSAGE i002(/psyng/sw) WITH 'Copying version'
          g_varel_vrsio 'to' /psyng/sw_varvr-varel_vrsio.
          lt_varel-varel_vrsio = /psyng/sw_varvr-varel_vrsio.
          CLEAR: /psyng/sw_varvr-varel_vrsio,
            /psyng/sw_varvr-description.
*--Get all data from source
          SELECT * FROM /psyng/sw_varel INTO TABLE lt_varel
          WHERE varel_vrsio = g_varel_vrsio.

          MODIFY  lt_varel
          TRANSPORTING varel_vrsio
          WHERE varel_vrsio <> lt_varel-varel_vrsio.
*--Update the new version
          MODIFY /psyng/sw_varel FROM TABLE   lt_varel.
          COMMIT WORK.
      ENDCASE.
      g_varel_vrsio = /psyng/sw_varvr-varel_vrsio.
      PERFORM select_rules_version USING g_varel_vrsio.

      PERFORM get_varel_data.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0200  INPUT
*&---------------------------------------------------------------------*
*&      Form  create_new_version
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_/PSYNG/SW_VARVR_VAREL_VRSIO  text
*----------------------------------------------------------------------*
FORM create_new_version USING    i_vrsio.

*--Check if already exists
  SELECT SINGLE varel_vrsio INTO i_vrsio
   FROM /psyng/sw_varvr WHERE
   varel_vrsio =  i_vrsio.
  IF sy-subrc = 0.
    MESSAGE e135(/psyng/sw) WITH 'Rules Version'(e01) i_vrsio
                                 'already exists'(e02).
  ELSE.
    PERFORM check_authorization
                USING
                   'X'
                   i_vrsio.
    INSERT /psyng/sw_varvr.
    MESSAGE s135(/psyng/sw) WITH 'Rules Version'(e01) i_vrsio
                                 'created'(e03).

    COMMIT WORK.
  ENDIF.

ENDFORM.                    " create_new_version
*&---------------------------------------------------------------------*
*&      Form  delete_version
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM delete_version.

  DATA : ls_cfg TYPE  /psyng/swcfgset ,
         l_answer .

*--Check if used in any configuration set
  SELECT SINGLE * FROM  /psyng/swcfgset  INTO ls_cfg  WHERE
  varel_vrsio = g_varel_vrsio.
  IF sy-subrc = 0.
    MESSAGE e002(/psyng/sw) WITH
    'Rules version is still used in Configuration Set'(e05)
    ls_cfg-setid
    'Can not be deleted'(e06).
*   & & & &
  ELSE.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
           titlebar                    =
           'Delete Rules Version'(c05)
        text_question               =
        'Are you sure you want to delete this Rules Version?'(c03)
           text_button_1               = 'Yes'(c01)
           text_button_2               = 'No'(c02)
           default_button              = '2'
           display_cancel_button       = ''
    IMPORTING
      answer                      = l_answer
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TEXT_NOT_FOUND          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    IF l_answer = '1'.
      DELETE FROM /psyng/sw_varel WHERE varel_vrsio = g_varel_vrsio.
      DELETE FROM /psyng/sw_varvr WHERE varel_vrsio = g_varel_vrsio.
      COMMIT WORK.
      REFRESH : gt_sw_varel.
      CLEAR : g_varel_vrdesc, g_varel_vrsio .
    ENDIF.
  ENDIF.
ENDFORM.                    " delete_version

*---------------------------------------------------------------------*
*       MODULE validate_rfcdest INPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE validate_rfcdest INPUT.
  DATA l_subrc LIKE sy-subrc.
  IF NOT g_rfcdest IS INITIAL.
    CALL FUNCTION 'CAT_CHECK_RFC_DESTINATION'
      EXPORTING
        rfcdestination       = g_rfcdest
     IMPORTING
*       MSGV1                =
*       MSGV2                =
       rfc_subrc            = l_subrc.

    IF l_subrc <> 0.
      MESSAGE e113(/psyng/sw) WITH 'Invalid RFC Destination'(er1).
    ENDIF.
  ENDIF.
ENDMODULE.

*---------------------------------------------------------------------*
*       MODULE validate_rule_vrsio INPUT                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE validate_rule_vrsio INPUT.
  SELECT SINGLE mandt INTO sy-mandt FROM /psyng/sw_varvr
                    WHERE varel_vrsio = g_varel_vrsio.
  IF sy-subrc <> 0.
    MESSAGE e351(/psyng/sw) WITH g_varel_vrsio.
  ENDIF.
ENDMODULE.
*&---------------------------------------------------------------------*
*&      Form  validate_alv_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LO_DATA_CHANGED  text
*----------------------------------------------------------------------*
FORM validate_alv_data
  USING    io_data_changed TYPE REF TO cl_alv_changed_data_protocol.
  DATA : lf_issues TYPE flag,
         ls_cell TYPE lvc_s_modi.
  FIELD-SYMBOLS : <cell> TYPE   lvc_s_modi.
  DEFINE add_p_entry.
    lf_issues = 'X'.
    call method io_data_changed->add_protocol_entry
       exporting
         i_msgid     = '/PSYNG/SW'
         i_msgty     = &7
         i_msgno     = &2
         i_msgv1     = &5
         i_msgv2     = &6
*              I_MSGV3     =
*              I_MSGV4     =
         i_fieldname = &1
         i_row_id    = &3
         i_tabix     = &4.
  END-OF-DEFINITION.
  refresh : io_data_changed->MT_PROTOCOL.
  LOOP AT io_data_changed->mt_mod_cells ASSIGNING <cell>
  WHERE value <> space.
    CASE <cell>-fieldname.
      WHEN 'V_SIGN'.
        IF <cell>-value <> 'I' AND <cell>-value <> 'E'.
          add_p_entry 'V_SIGN'  '010'
                                <cell>-row_id <cell>-tabix
                                <cell>-value '' 'E'.
          <cell>-error = 'X'.
        ENDIF.
      WHEN 'V_OPTION'.
        IF <cell>-value <> 'EQ' AND <cell>-value <> 'NE' AND
           <cell>-value <> 'BT' AND <cell>-value <> 'GE' AND
           <cell>-value <> 'GT' AND <cell>-value <> 'LE' AND
           <cell>-value <> 'LT' AND <cell>-value <> 'CP' AND
           <cell>-value <> 'NP' .
          add_p_entry 'V_OPTION'  '011'
                                <cell>-row_id <cell>-tabix
                                <cell>-value '' 'E' .
          <cell>-error = 'X'.
        ENDIF.
    ENDCASE.
  ENDLOOP.
*
  IF ( syst-subrc = 0 ).
    CALL METHOD io_data_changed->display_protocol( ).
  ENDIF.

ENDFORM.                    " validate_alv_data


*If this system had variable element rules prior to SE4.1,
*these will be converted to the 4.1 format and a default version
* 000 will be created
FORM init_varel_rules.
  DATA : l_cnt TYPE i,
         ls_version TYPE /psyng/sw_varvr,
         lt_rules TYPE TABLE OF /psyng/sw_varel WITH HEADER LINE,
         lf_problem TYPE flag.
  FIELD-SYMBOLS : <rule> TYPE /psyng/sw_varel.
  SELECT SINGLE COUNT(*) INTO l_cnt FROM /psyng/sw_varvr.
  IF l_cnt = 0.
*--There are no versions yet
    SELECT COUNT(*) INTO l_cnt FROM /psyng/sw_varel. "#EC CI_NOWHERE
    IF l_cnt > 0.
*--Variable elements were defined prior to 4.1 and they are not
*  converted yet.
*  Create a version
      ls_version-varel_vrsio = '000'.
      ls_version-description = 'Default Variable Elements'.
      MODIFY /psyng/sw_varvr FROM ls_version.
      SELECT * FROM /psyng/sw_varel INTO TABLE lt_rules. "#EC CI_NOWHERE
      LOOP AT lt_rules ASSIGNING <rule>.
        <rule>-v_sign   = 'I'.
        IF <rule>-val_to  IS INITIAL.
          <rule>-v_option = 'EQ'.
        ELSE.
          <rule>-v_option = 'BT'.
        ENDIF.
        <rule>-outputflag = 'X'.
*--Get the checktable
        SELECT SINGLE checktable FROM authx
          INTO <rule>-tabname
          WHERE fieldname = <rule>-element.
        IF sy-subrc <> 0.
          lf_problem = 'X'.
        ENDIF.
      ENDLOOP.
      MODIFY /psyng/sw_varel FROM TABLE lt_rules.
      COMMIT WORK.
    IF lf_problem =  'X'.
      MESSAGE i002(/psyng/sw) WITH 'Rules were automatically converted'
      'and stored in Rules Version 000'.
      MESSAGE w002(/psyng/sw) WITH
      'A problem occured when converting the rules'
      'Please manually review the rules.'.
    ELSE.
      MESSAGE i002(/psyng/sw) WITH 'Rules were automatically converted'
      'and stored in Rules Version 000'.
    ENDIF.
    COMMIT WORK.
    ENDIF.
  ENDIF.

*--Default to DFLT_VAREL_VRSIO
  se_config_param 'DFLT_VAREL_VERSION' g_varel_vrsio.

ENDFORM.
