*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_143
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  30/01/2020   Gurpinder   C0006       P33K940178                     *
*----------------------------------------------------------------------*

REPORT /psyng/sw_143 MESSAGE-ID /psyng/sw.
TABLES: /psyng/swcfgset.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_143_top.
INCLUDE /psyng/sw_143_cli.


*---Selection screen
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
*SELECTION-SCREEN:SKIP 1.
PARAMETERS: p_system TYPE /psyng/swcfgsys-sysid.
*SELECTION-SCREEN:SKIP 1.
SELECT-OPTIONS: so_vrsio FOR /psyng/swcfgset-sodvrsio,
                so_setid FOR /psyng/swcfgset-setid.
SELECTION-SCREEN: END OF BLOCK b1.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_system.
  PERFORM f4_system USING 'P_SYSTEM' CHANGING p_system.

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
  CREATE OBJECT gr_event_handler.
  PERFORM load_data.
  CALL SCREEN '0100'.
*---------------------------------------------------------------------*
*       MODULE status_0100 OUTPUT                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '0100'.
  IF p_system IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO p_system.
  ENDIF.
  SET TITLEBAR '0100' WITH p_system.
ENDMODULE.


*---------------------------------------------------------------------*
*       MODULE USER_COMMAND_0100 INPUT                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM load_data                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_data.
  DATA: lt_cfgset TYPE TABLE OF /psyng/sw_configset WITH HEADER LINE,
        ls_swrfcdes TYPE /psyng/sw_rfcdes,
        l_system_msg(72) TYPE c,
        l_globle_vrsio TYPE /psyng/param_value,             "++C0006
        l_vrsio        TYPE /psyng/sodvrsio.                "++C0006

  IF p_system IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO p_system.
  ENDIF.

*  SELECT SINGLE * FROM /psyng/sw_rfcdes INTO ls_swrfcdes
*  WHERE systid = p_system.
  SELECT * UP TO 1 ROWS
  FROM /psyng/sw_rfcdes INTO ls_swrfcdes
  WHERE systid = p_system.
  ENDSELECT.
  IF sy-subrc = 0.
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
    CALL FUNCTION '/PSYNG/SW_CGFSET_DTL'
    DESTINATION ls_swrfcdes-rfcdest
     TABLES
       et_cfgset         = lt_cfgset
       it_versio           = so_vrsio
       it_cfgset_range     = so_setid
     EXCEPTIONS
        communication_failure = 1
        system_failure        = 2
        OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
*BOC:HBHALLA (03/12/24)
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
*EOC:HBHALLA (03/12/24)

  ENDIF.
  LOOP AT lt_cfgset.
    MOVE-CORRESPONDING lt_cfgset TO gt_cfgset.
    APPEND gt_cfgset.
  ENDLOOP.
*--Begin of C0006
*--Highlight latest published set of global default SOD Matrix with
*--blue line
  se_config_param 'DFLT_GLOBAL_VERSION' l_globle_vrsio.
  l_vrsio = l_globle_vrsio.
  SORT gt_cfgset BY sodvrsio change_date DESCENDING.
  READ TABLE gt_cfgset WITH KEY sodvrsio = l_vrsio
                                published = 'X'.
  IF sy-subrc = 0.
    gt_cfgset-color_line = gc_blue_color.
    MODIFY gt_cfgset TRANSPORTING color_line WHERE
          setid = gt_cfgset-setid.
  ENDIF.
  SORT gt_cfgset BY sodvrsio setid.
*--Begin of C0006
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_system                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDNAME                                                     *
*  -->  E_VALUE                                                       *
*---------------------------------------------------------------------*
FORM f4_system USING    fieldname
                 CHANGING e_value.

  DATA: BEGIN OF lt_values OCCURS 0,
            line(255) TYPE c,
          END OF lt_values.
  DATA: lt_fields    TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return    TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_sw_rfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sw_rfcdes.
  LOOP AT lt_sw_rfcdes.
    lt_values-line = lt_sw_rfcdes-rfcdest.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-rfcname.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-description.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-systid.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_type.
    APPEND lt_values.
    lt_values-line = lt_sw_rfcdes-sys_category.
    APPEND lt_values.

  ENDLOOP.

  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCDEST'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'RFCNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'DESCRIPTION'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYSTID'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_TYPE'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
  lt_fields-fieldname = 'SYS_CATEGORY'.
  APPEND lt_fields.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'SYSTID'
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
  e_value = lt_return-fieldval.
ENDFORM.

*---------------------------------------------------------------------*
*       MODULE display_alv_100 OUTPUT                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
MODULE display_alv_100 OUTPUT.
  PERFORM display_alv_100.
ENDMODULE.

*---------------------------------------------------------------------*
*       FORM display_alv_100                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv_100.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat,gt_sort.
*----Preparing field catalog.
  add_column:
  '' 'SODVRSIO' 'Version'(c01) gt_fieldcat 10 ''  '' '' '',
*  '' 'SETID' 'Configuration Set'(c02) gt_fieldcat 15  ''  '' '' '',
*--C0006
  'X' 'SETID' 'Configuration Set'(c02) gt_fieldcat 15  ''  '' '' '',
*++C0006
  '' 'PUBLISHED' 'Published'(c03) gt_fieldcat  10 '' '' '' 'X',
  '' 'CHANGE_DATE' 'Last Change Date'(c04) gt_fieldcat  15 '' '' '' '',
  '' 'CHANGE_TIME' 'Last Change Time'(c05) gt_fieldcat  10 '' '' '' '',
  '' 'DESCRIPTION' 'Description'(c06) gt_fieldcat  25 '' '' '' '',
  '' 'CHANGE_USER' 'User'(c07) gt_fieldcat  12 '' '' '' '',
  '' 'SYSTEM' 'System'(c08) gt_fieldcat  40 '' '' '' ''.
*--SORT the grid
  add_sort:
  '1' 'SODVRSIO',
  '2' 'SETID'.

  IF gr_alvgrid IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_container
      EXPORTING
        container_name              = 'CC_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent          = gr_container
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.
*----Preparing layout structure
  gs_layout-sel_mode = 'A'. " for selection bar
  gs_layout-zebra = 'X'.
  MOVE 'COLOR_LINE' TO  gs_layout-info_fname.               "++C0006


  SET HANDLER gr_event_handler->handle_hotspot_click   FOR gr_alvgrid.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
  CALL METHOD gr_alvgrid->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_cfgset[]
      it_fieldcatalog               = gt_fieldcat
*     it_filter                     = lt_filter[]
      it_sort                       = gt_sort
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.
*Begin of C0006
*&---------------------------------------------------------------------*
*&      Form  handle_hotspot_click
*&---------------------------------------------------------------------*
*       Display config set details
*----------------------------------------------------------------------*
*      -->P_E_ROW_ID  text
*      -->P_E_COLUMN_ID  text
*      -->P_ES_ROW_NO  text
*----------------------------------------------------------------------*
FORM handle_hotspot_click
USING i_row_id TYPE lvc_s_row
      i_column_id TYPE lvc_s_col
      is_row_no TYPE lvc_s_roid.

  READ TABLE gt_cfgset INDEX i_row_id-index.
  PERFORM load_config_details USING gt_cfgset-setid.
  IF NOT gt_config_detail IS INITIAL.
    CALL SCREEN '0101'.
  ELSE.
*--Display message that no details for config set
    MESSAGE s002 WITH 'Configuration set'(t02) gt_cfgset-setid
    'does not contain any values on System'(t03) p_system.
  ENDIF.
ENDFORM.                    " handle_hotspot_click
*&---------------------------------------------------------------------*
*&      Module  status_0101  OUTPUT
*&---------------------------------------------------------------------*
*       User interface for screen of config details
*----------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS '0101'.
  SET TITLEBAR '0101' WITH p_system gt_cfgset-setid.
ENDMODULE.                 " status_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  display_alv_101  OUTPUT
*&---------------------------------------------------------------------*
*       Display ALV of config details
*----------------------------------------------------------------------*
MODULE display_alv_101 OUTPUT.
  PERFORM display_alv_101.
ENDMODULE.                 " display_alv_101  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  display_alv_101
*&---------------------------------------------------------------------*
*       Display ALV of config details
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_101.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat,gt_sort.

*----Preparing field catalog.
  add_column
  '' 'TYPE' 'Type'(c09) gt_fieldcat 15 ''  '' '' ''.
  add_column:
  '' 'ABB' 'Company Code'(c10) gt_fieldcat 10  ''  '' '' '',
  '' 'VAR_ELEMENT' 'Element'(c11) gt_fieldcat 40 '' '' '' '',
  '' 'VALUE' 'Value'(c12) gt_fieldcat  40 '' '' '' '',
  '' 'MODIFIED' 'Modified'(c13) gt_fieldcat 9 '' '' '' 'X',
  '' 'ACTIVE' 'Active'(c14) gt_fieldcat 7 '' '' '' 'X',
  '' 'SYSID' 'System'(c15) gt_fieldcat 7 '' '' '' ''.

*--SORT the grid
  add_sort:
  '1' 'TYPE',
  '2' 'ABB',
  '3' 'VAR_ELEMENT',
  '4' 'SYSID'.

  IF go_alvgrid_101 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT go_container_101
      EXPORTING
        container_name              = 'SET_DETAILS'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        others                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT go_alvgrid_101
      EXPORTING
        i_parent          = go_container_101
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.
*----Preparing layout structure
  gs_layout-zebra = 'X'.
*  gs_layout-cwidth_opt = 'X'.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
  CALL METHOD go_alvgrid_101->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_config_detail
      it_fieldcatalog               = gt_fieldcat
      it_sort                       = gt_sort
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
ENDFORM.                    " display_alv_101
*&---------------------------------------------------------------------*
*&      Module  user_command_0101  INPUT
*&---------------------------------------------------------------------*
*       At user command of screen config details
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE sy-ucomm.
    WHEN 'BACK'.
      SET SCREEN 0.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " user_command_0101  INPUT
*&---------------------------------------------------------------------*
*&      Form  load_config_details
*&---------------------------------------------------------------------*
*       Load details of config set
*----------------------------------------------------------------------*
*      -->P_GT_CFGSET_SETID  text
*----------------------------------------------------------------------*
FORM load_config_details USING i_setid TYPE /psyng/seconfid.

  DATA: lt_var_elements  TYPE TABLE OF /psyng/swcfgve,
        lt_org_values    TYPE TABLE OF /psyng/swcfgoe,
        ls_config_detail TYPE ty_config_detail,
        ls_swrfcdes      TYPE /psyng/sw_rfcdes.

  FIELD-SYMBOLS:
          <fs_var_elements> TYPE /psyng/swcfgve,
          <fs_org_values>   TYPE /psyng/swcfgoe.

  SELECT * UP TO 1 ROWS
  FROM /psyng/sw_rfcdes INTO ls_swrfcdes
  WHERE systid = p_system.
  ENDSELECT.

  REFRESH gt_config_detail.
*--Fetch variable element values for input config set id
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
  CALL FUNCTION '/PSYNG/SW_VE_READ'
       DESTINATION ls_swrfcdes-rfcdest
       EXPORTING
            if_read      = gc_read_values
            i_setid      = i_setid
       TABLES
            et_ve_values = lt_var_elements
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
*--Fetch Org values for input config set id
  CALL FUNCTION '/PSYNG/SW_AO_READ'
       DESTINATION ls_swrfcdes-rfcdest
       EXPORTING
            if_read       = gc_read_values
            i_setid       = i_setid
       TABLES
            et_org_values = lt_org_values
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
*--Prepare data
  LOOP AT lt_var_elements ASSIGNING <fs_var_elements>.
    ls_config_detail-type        = 'Var. Element'(c16).
    ls_config_detail-var_element = <fs_var_elements>-var_element.
    ls_config_detail-value       = <fs_var_elements>-value.
    ls_config_detail-active      = <fs_var_elements>-active.
    ls_config_detail-modified    = <fs_var_elements>-modified.
    ls_config_detail-sysid       = <fs_var_elements>-sysid.
    APPEND ls_config_detail TO gt_config_detail.
    CLEAR ls_config_detail.
  ENDLOOP.

  LOOP AT lt_org_values ASSIGNING <fs_org_values>.
    ls_config_detail-type        = 'Org Element'(c17).
    ls_config_detail-abb         = <fs_org_values>-abb.
    ls_config_detail-var_element = <fs_org_values>-varbl.
    ls_config_detail-value       = <fs_org_values>-value.
    ls_config_detail-active      = <fs_org_values>-active.
    ls_config_detail-modified    = <fs_org_values>-modified.
    ls_config_detail-sysid       = <fs_org_values>-sysid.
    APPEND ls_config_detail TO gt_config_detail.
    CLEAR ls_config_detail.
  ENDLOOP.

ENDFORM.                    " load_config_details
*End of C0006
