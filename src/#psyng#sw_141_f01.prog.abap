*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_141_F01                                          *
*----------------------------------------------------------------------*

FORM display_alv_100.

  CLEAR gs_layout.
  REFRESH : gt_fieldcat,gt_sort.

*----Preparing field catalog.
  add_column:
  '' 'SYSTID' 'System'(c01) gt_fieldcat 6 ''  '' '' '',
  '' 'SYS_TYPE' 'System Type'(c31) gt_fieldcat 10 ''  '' '' '',
  '' 'SYS_DESCRIPTION' 'System Description'(c37)
  gt_fieldcat 40 'X' '' '' '',
  '' 'SYS_CATEGORY' 'System Category'(c32) gt_fieldcat 15 '' '' '' '',
  '' 'CAT_DESCRIPTION' 'Category Description'(c38)
  gt_fieldcat 40 'X' '' '' '',
  '' 'LAST_CHECK' 'Last Check'(c02) gt_fieldcat  10 '' '' '' '',
  '' 'RFC_VALID' 'RFC Valid'(c03) gt_fieldcat  6 '' '' '' 'X',
  '' 'VERSION' 'SE Version'(c04) gt_fieldcat  10 '' '' '' '',
*  'X' 'SODVRSIO_NR' 'SOD Matrix'(c05)    "--C0006
  'X' 'SODVRSIO_NR' 'SOD Matrices'(c05)                     "++C0006
  gt_fieldcat  10 '' '' '' '',
  '' 'DFLT_VRSIO' 'Default SOD Version'(c35) gt_fieldcat 8
  ''  '' '' '',
*  'X' 'CFGSET_NR' 'Configuration Set'(c06) gt_fieldcat   "--C0006
  'X' 'CFGSET_NR' 'Configuration Sets'(c06) gt_fieldcat     "++C0006
  10  ''  '' '' '',
  '' 'LSR_AID' 'Latest Stored Result'(c07) gt_fieldcat
  10  ''  '' '' '',
  '' 'LSR_DATE' 'LSR Date'(c08) gt_fieldcat 10  ''  '' '' '',
  '' 'LSR_USER' 'LSR User'(c09) gt_fieldcat 12  '' '' '' '',
  '' 'LSR_VRSIO' 'LSR Version'(c10) gt_fieldcat 10 ''  '' '' '',
  '' 'SETID' 'LSR Config. Set'(c11) gt_fieldcat 10  ''  '' '' '',
  '' 'USERS_ANALYZED' 'LSR Users'(c12) gt_fieldcat 10  ''  '' '' '',
  '' 'CONFLICTED_USERS' 'LSR Conflicted Users'(c13) gt_fieldcat 10
  ''  '' '' '',
  '' 'CONFIG' 'Config.'(c15) gt_fieldcat 15  ''  ''
    cl_gui_alv_grid=>mc_style_button '',
  '' 'AUDIT' 'Audit'(c14) gt_fieldcat 10  ''  ''
    cl_gui_alv_grid=>mc_style_button '',
  '' 'API_LOGGING' 'API Logging'(c36) gt_fieldcat 15  ''  ''
    cl_gui_alv_grid=>mc_style_button '',
  '' 'DIAGNOSTIC' 'Diagnostics'(c16) gt_fieldcat 15 ''  ''
    cl_gui_alv_grid=>mc_style_button ''.

  IF gr_alvgrid IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_ccontainer
      EXPORTING
        container_name              = 'CC_ALV'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
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
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.

  SET HANDLER gr_event_handler->handle_before_user_command
                                                   FOR gr_alvgrid.
  SET HANDLER gr_event_handler->button_click FOR gr_alvgrid.
  SET HANDLER gr_event_handler->handle_hotspot_click   FOR gr_alvgrid.


*----Preparing layout structure
  gs_layout-sel_mode = 'A'. " for selection bar
  gs_layout-zebra = 'X'.
  gs_layout-cwidth_opt = 'X'.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
  CALL METHOD gr_alvgrid->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_output[]
      it_fieldcatalog               = gt_fieldcat
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM display_alv_101                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM display_alv_101.
  CLEAR gs_layout.
  REFRESH : gt_fieldcat,gt_sort.

*----Preparing field catalog.
  add_column
  '' 'VRSIO' 'Version'(c17) gt_fieldcat 7 ''  '' '' ''.
  add_column:
  '' 'NOEDIT' 'No Edit'(c18) gt_fieldcat 7  ''  '' '' 'X',
  '' 'VDESC' 'Description'(c19) gt_fieldcat  30 '' '' '' '',
  '' 'FUNC_CNT' 'Functions'(c20) gt_fieldcat  10 '' '' '' '',
  '' 'CON_CNT' 'Conflicts'(c21)  gt_fieldcat  10 '' '' '' '',
  '' 'CRIAUTH_CNT' 'Critical Authorizations'(c22) gt_fieldcat
  15  ''  '' '' '',
  '' 'CRITXN_CNT' 'Critical Transaction'(c23) gt_fieldcat
  15  ''  '' '' '',
  '' 'CSTMCON_CNT' 'Custom Conflicts'(c24) gt_fieldcat
  15  ''  '' '' '',
  '' 'CRIROLES_CNT' 'Critical Roles'(c25) gt_fieldcat
  15  '' '' '' '',
  '' 'CRIPROF_CNT' 'Critical Profiles'(c26) gt_fieldcat
  15 ''  '' '' '',
  '' 'MITASSIGN_CNT' 'Mitigation Assignments'(c27) gt_fieldcat
  15  ''  '' '' '',
  'X' 'CFGSET_CNT' 'Config. Sets'(c28) gt_fieldcat 10  'X'  '' '' ''.


  IF gr_alvgrid_101 IS INITIAL .
*----Creating custom container instance
    CREATE OBJECT gr_container_101
      EXPORTING
        container_name              = 'MAT_OVERVIEW'
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
*----Creating ALV Grid instance
    CREATE OBJECT gr_alvgrid_101
      EXPORTING
        i_parent          = gr_container_101
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        OTHERS            = 5.
    IF sy-subrc <> 0.
*--Exception handling
    ENDIF.
  ENDIF.
*----Preparing layout structure
  gs_layout-zebra = 'X'.
  MOVE 'COLOR_LINE' TO  gs_layout-info_fname.
*  gs_layout-info_fieldname = 'COLOR_LINE'.
*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
  CALL METHOD gr_alvgrid_101->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_sodovrview[]
      it_fieldcatalog               = gt_fieldcat
*       it_filter                    = lt_filter[]
*      it_sort                       = gt_sort
    EXCEPTIONS
      invalid_parameter_combination = 1
      program_error                 = 2
      too_many_lines                = 3
      OTHERS                        = 4.
  IF sy-subrc <> 0.
*--Exception handling
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM load_data                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_data.
  DATA: lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_systyp   TYPE TABLE OF /psyng/sw_systyp,
        lt_syscat   TYPE TABLE OF /psyng/sw_syscat,
        ls_systyp   TYPE /psyng/sw_systyp,
        ls_syscat   TYPE /psyng/sw_syscat,
*        lt_output_tmp LIKE TABLE OF /psyng/swadmovw WITH HEADER LINE,
*        l_system_msg(72) TYPE c,
  lt_overview TYPE TABLE OF /psyng/swadmovw WITH HEADER LINE.
*        l_subrc LIKE sy-subrc.
  REFRESH gt_output.
  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes.

  IF NOT lt_swrfcdes[] IS INITIAL.
    SELECT * FROM /psyng/swadmovw INTO TABLE lt_overview
    FOR ALL ENTRIES IN lt_swrfcdes
    WHERE systid = lt_swrfcdes-systid.

    SELECT * FROM /psyng/sw_systyp INTO TABLE lt_systyp
    FOR ALL ENTRIES IN lt_swrfcdes
    WHERE sys_type = lt_swrfcdes-sys_type.

    SELECT * FROM /psyng/sw_syscat INTO TABLE lt_syscat
    FOR ALL ENTRIES IN lt_swrfcdes
    WHERE sys_category = lt_swrfcdes-sys_category.
  ENDIF.

  LOOP AT lt_swrfcdes.
    READ TABLE lt_overview WITH KEY systid = lt_swrfcdes-systid.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING  lt_overview TO gt_output.
    ENDIF.
    READ TABLE lt_systyp INTO ls_systyp
    WITH KEY sys_type = lt_swrfcdes-sys_type.
    IF sy-subrc = 0.
      gt_output-sys_description = ls_systyp-sys_description.
    ENDIF.
    READ TABLE lt_syscat INTO ls_syscat
    WITH KEY sys_category = lt_swrfcdes-sys_category.
    IF sy-subrc = 0.
      gt_output-cat_description = ls_syscat-cat_description.
    ENDIF.
    gt_output-systid  =   lt_swrfcdes-systid.
    gt_output-sys_type = lt_swrfcdes-sys_type.
    gt_output-sys_category =  lt_swrfcdes-sys_category.
    gt_output-audit           = 'Audit'(o01).
    gt_output-config          = 'Configuration'(o02).
    gt_output-diagnostic      = 'Performance Diagnostics'(o03).
    gt_output-api_logging     = 'API Logging'(c36).
    APPEND gt_output.
    CLEAR gt_output.
  ENDLOOP.
  SORT gt_output BY systid.
  DELETE ADJACENT DUPLICATES FROM gt_output COMPARING systid.
  FREE: lt_swrfcdes, lt_overview.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_data_101                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_data_101 USING i_system TYPE /psyng/sw_rfcdes-systid.
  DATA: ls_rfcdes TYPE /psyng/sw_rfcdes,
        l_system_msg(72) TYPE c,
        l_globle_vrsio TYPE /psyng/param_value,
        l_vrsio TYPE /psyng/sodvrsio.

  REFRESH gt_sodovrview.
*  SELECT SINGLE * FROM /psyng/sw_rfcdes INTO ls_rfcdes
*  WHERE systid = i_system.

  SELECT * UP TO 1 ROWS
    FROM /psyng/sw_rfcdes INTO ls_rfcdes
  WHERE systid = i_system.
  ENDSELECT.

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
*---SOD matrix count detail like function, conflict etc
  CALL FUNCTION '/PSYNG/SW_SOD_MATRIX_COUNT_DTL'
  DESTINATION ls_rfcdes-rfcdest
   TABLES
     et_countinfo         = gt_sodovrview
   EXCEPTIONS
    communication_failure = 1 MESSAGE l_system_msg
    system_failure        = 2 MESSAGE l_system_msg
    OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1 OR 2.
        MESSAGE s012(/psyng/basis) WITH 'Unable to reach'(m01)
        i_system l_system_msg.
      WHEN 3.
        MESSAGE s012(/psyng/basis) WITH
        'Unable to reach get SOD Matrix from'(m02)
        i_system.
    ENDCASE.
  ENDIF.
*---Highligh globle version
  se_config_param 'DFLT_GLOBAL_VERSION' l_globle_vrsio.
  l_vrsio = l_globle_vrsio.
  READ TABLE gt_sodovrview WITH KEY vrsio = l_vrsio.
  IF sy-subrc = 0.
    gt_sodovrview-color_line = 'C410'.
    MODIFY gt_sodovrview TRANSPORTING color_line WHERE
          vrsio = l_globle_vrsio.
  ENDIF.
ENDFORM.


*---------------------------------------------------------------------*
*       FORM button_click                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  COL_ID                                                        *
*  -->  ROW_NO                                                        *
*---------------------------------------------------------------------*
FORM button_click  USING    col_id
                            row_no STRUCTURE lvc_s_roid.

  DATA: ls_swrfcdes TYPE /psyng/sw_rfcdes.

  READ TABLE gt_output INDEX row_no-row_id.
  CASE col_id.
    WHEN 'AUDIT'.
      SUBMIT /psyng/car
           WITH p_system = gt_output-systid AND RETURN.

    WHEN 'CONFIG'.
      SUBMIT /psyng/sw_142
      WITH p_system = gt_output-systid AND RETURN.

    WHEN 'DIAGNOSTIC'. "'diagnostic'.
      SUBMIT /psyng/sw_093
        WITH p_system = gt_output-systid
        VIA SELECTION-SCREEN AND RETURN.

    WHEN 'API_LOGGING'.
      SELECT * UP TO 1 ROWS
      FROM /psyng/sw_rfcdes INTO ls_swrfcdes
      WHERE systid = gt_output-systid.
      ENDSELECT.
      IF ls_swrfcdes-rfcdest IS INITIAL.
        SUBMIT /psyng/basis_log_api
          VIA SELECTION-SCREEN AND RETURN.
      ELSE.
        SUBMIT /psyng/basis_log_api
          WITH p_remote = 'X'
          WITH p_local  = ''
          WITH p_rfcsys = ls_swrfcdes-rfcdest
          VIA SELECTION-SCREEN AND RETURN.
      ENDIF.

  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM handle_hotspot_click                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_ROW_ID                                                      *
*  -->  I_COLUMN_ID                                                   *
*  -->  IS_ROW_NO                                                     *
*---------------------------------------------------------------------*
FORM handle_hotspot_click USING i_row_id TYPE lvc_s_row
i_column_id TYPE lvc_s_col
is_row_no TYPE lvc_s_roid.

  READ TABLE gt_output INDEX i_row_id-index.
  CASE i_column_id.
    WHEN 'SODVRSIO_NR'.
      PERFORM load_data_101 USING gt_output-systid.
      IF NOT gt_sodovrview[] IS INITIAL.
        CALL SCREEN '0101'.
      ENDIF.
    WHEN 'CFGSET_NR'.
      SUBMIT /psyng/sw_143
         WITH p_system = gt_output-systid AND RETURN.
  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM reload_refreshed_data_100                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
**FORM reload_refreshed_data_100.
**  SELECT * FROM /psyng/swadmovw INTO CORRESPONDING
**  FIELDS OF TABLE gt_output.
**ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  distribute_configuration
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM distribute_configuration.

  DATA: lt_rsparams TYPE TABLE OF rsparams WITH HEADER LINE,
        lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
   WHERE systid IN gr_system.

  DELETE lt_swrfcdes[] WHERE rfcdest EQ ' '.

  lt_rsparams-selname = 'P_PULL'.
  lt_rsparams-kind    = 'P'.
  lt_rsparams-sign    = 'I'.
  lt_rsparams-option  = 'EQ'.
  lt_rsparams-low     = ' '.
  APPEND lt_rsparams.
  CLEAR lt_rsparams.

  lt_rsparams-selname = 'P_PUSH'.
  lt_rsparams-kind    = 'P'.
  lt_rsparams-sign    = 'I'.
  lt_rsparams-option  = 'EQ'.
  lt_rsparams-low     = 'X'.
  APPEND lt_rsparams.
  CLEAR lt_rsparams.

  LOOP AT lt_swrfcdes.
    lt_rsparams-selname = 'S_RFCDST'.
    lt_rsparams-kind    = 'S'.
    lt_rsparams-sign    = 'I'.
    lt_rsparams-option  = 'EQ'.
    lt_rsparams-low     = lt_swrfcdes-rfcdest.
    APPEND lt_rsparams.
    CLEAR lt_rsparams.
  ENDLOOP.

  SUBMIT /psyng/sw_145 VIA SELECTION-SCREEN
                     WITH SELECTION-TABLE lt_rsparams[]
                     AND RETURN.

ENDFORM.                    " distribute_configuration
*&---------------------------------------------------------------------*
*&      Form  Validate Config Set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_config_set.

  DATA: lt_rsparams TYPE TABLE OF rsparams WITH HEADER LINE,
        lt_swrfcdes TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE.

  SELECT * INTO TABLE lt_swrfcdes FROM /psyng/sw_rfcdes
   WHERE systid IN gr_system.
  READ TABLE lt_swrfcdes WITH KEY rfcdest = ' '.
  IF sy-subrc NE 0.
    lt_rsparams-selname = 'P_REMON'.
    lt_rsparams-kind    = 'P'.
    lt_rsparams-sign    = 'I'.
    lt_rsparams-option  = 'EQ'.
    lt_rsparams-low     = 'X'.
    APPEND lt_rsparams.
    CLEAR lt_rsparams.
  ENDIF.
  DELETE lt_swrfcdes[] WHERE rfcdest EQ ' '.

  LOOP AT lt_swrfcdes.
    lt_rsparams-selname = 'S_SYSTEM'.
    lt_rsparams-kind    = 'S'.
    lt_rsparams-sign    = 'I'.
    lt_rsparams-option  = 'EQ'.
    lt_rsparams-low     = lt_swrfcdes-rfcdest.
    APPEND lt_rsparams.
    CLEAR lt_rsparams.
  ENDLOOP.

  SUBMIT /psyng/sw_146 VIA SELECTION-SCREEN
                     WITH SELECTION-TABLE lt_rsparams[]
                     AND RETURN.

ENDFORM.                    " Validate_Config_set
*&---------------------------------------------------------------------*
*&      Form  PUBLISH_CONFIG_SET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM publish_config_set .

  DATA: lt_rsparams TYPE TABLE OF rsparams WITH HEADER LINE,
        ls_sys LIKE LINE OF gr_system.

  LOOP AT gr_system INTO ls_sys.
    lt_rsparams-selname = 'S_SYSTEM'.
    lt_rsparams-kind    = 'S'.
    lt_rsparams-sign    = 'I'.
    lt_rsparams-option  = 'EQ'.
    lt_rsparams-low     = ls_sys-low.
    APPEND lt_rsparams .
    CLEAR lt_rsparams.
  ENDLOOP.

  SUBMIT /psyng/sw_157 VIA SELECTION-SCREEN
                                WITH SELECTION-TABLE lt_rsparams[]
                                AND RETURN.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ACCESS_CHECK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GR_SYSTEM  text
*      <--P_LF_ACCESS_CHECK  text
*----------------------------------------------------------------------*
FORM access_check  USING    gr_system TYPE tt_system
                   CHANGING lf_access_check TYPE flag
                            lv_invalid_system type
                                                /psyng/range_sysid-low.


  RANGES : lr_system FOR /psyng/range_sysid.

  DATA : lt_sw_cnfacc TYPE TABLE OF /psyng/sw_cnfacc,
         ls_sw_cnfacc TYPE /psyng/sw_cnfacc,
         l_login_user TYPE sy-uname,
         ls_sys LIKE LINE OF gr_system,
         ls_system LIKE LINE OF lr_system.

  l_login_user = sy-uname.

  SELECT *
         FROM /psyng/sw_cnfacc
         INTO TABLE  lt_sw_cnfacc
         WHERE username = l_login_user.

  IF sy-subrc = 0.

    LOOP AT lt_sw_cnfacc INTO ls_sw_cnfacc.
      ls_system-sign = ls_sw_cnfacc-sign.
      ls_system-option = ls_sw_cnfacc-opton.
      ls_system-low = ls_sw_cnfacc-sysidlow.
      ls_system-high = ls_sw_cnfacc-sysidhigh.
      APPEND ls_system TO lr_system.
    ENDLOOP.

    LOOP AT gr_system INTO ls_sys.

      IF NOT ls_sys-low IN lr_system.
        lv_invalid_system = ls_sys-low.
        CLEAR lf_access_check.
        EXIT.
      ELSE.
        lf_access_check = 'X'.
      ENDIF.

    ENDLOOP.

  ELSE.

    CLEAR lf_access_check.
  ENDIF.

ENDFORM.
