*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_138_F01                                          *
*----------------------------------------------------------------------*

FORM display_alv_100.
  DATA:   lt_filter TYPE lvc_t_filt,
          ls_filter TYPE lvc_s_filt.
  IF NOT gf_grid_initialized = 'X'.
    CLEAR gs_layout.
    REFRESH : gt_fieldcat,gt_sort.
*----Preparing field catalog.
    add_column:
    'X' 'AID' 'Result ID'(c01) gt_fieldcat 10 ''  '' '' '',
    '' 'DESCRIPTION' 'Description'(c08) gt_fieldcat 25  ''  '' '' '',
    'X' 'USERS_ANALYZED' 'Users Analyzed'(c12)
    gt_fieldcat  10 '' '' '' '',
    'X' 'CONFLICTED_USERS' 'Conflicted Users'(c16)
       gt_fieldcat  10 '' '' '' '',
    'X' 'UNCONFLICTED_USERS' 'Un-Conflicted Users'(c17)
       gt_fieldcat  10 '' '' '' '',

    'X' 'CONFLICTS' 'Conflicts'(c13) gt_fieldcat 10  ''  '' '' '',
    '' 'SODVRSIO' 'SOD Version'(c09) gt_fieldcat 5  ''  '' '' '',
    '' 'SETID' 'Configuration Set'(c10) gt_fieldcat 10  ''  '' '' '',
    '' 'NO_RESTRICTIONS' 'No Restrictions'(c14) gt_fieldcat 10
    '' '' '' 'X',
    '' 'FINISHED' 'Finished'(c21) gt_fieldcat
    10 ''  '' '' 'X',
    '' 'BNAME' 'User ID'(c02) gt_fieldcat 12 ''  '' '' '',
    '' 'NAME_TEXT' 'User Name'(c03) gt_fieldcat 15
    ''  '' '' '',
    '' 'START_DATE' 'Start Date'(c04) gt_fieldcat 10
      ''  '' '' '',
    '' 'START_TIME' 'Start Time'(c05) gt_fieldcat 10
      ''  '' '' '',
    '' 'END_DATE' 'End Date'(c06) gt_fieldcat 10
      'X'  '' '' '',
    '' 'END_TIME' 'End Time'(c07) gt_fieldcat 10
      'X'  '' '' '',
    '' 'DELETE_DATE' 'Retention Date'(c11) gt_fieldcat 10
    ''  '' '' '',
    '' 'SYSID' 'System'(c15) gt_fieldcat
    10 ''  '' '' '',
    '' 'SE_VERSION' 'SE Version'(c22) gt_fieldcat
    10 ''  '' '' '',
    '' 'DURATION' 'Duration'(c19) gt_fieldcat
    16 'X'  '' '' '',
    '' 'DET_JOB_SUCCESS' 'Succesfull Detailed Jobs'(c18) gt_fieldcat
    10 'X'  '' '' '',
    '' 'DET_JOB_FAILED' 'Failed Detailed Jobs'(c20) gt_fieldcat
    10 'X'  '' '' '',
    '' 'SUMMARY_DATA' 'Summary Available'(c29) gt_fieldcat 10 'X'  '' '' 'X',
    '' 'DETAIL_DATA' 'Details Available'(c30) gt_fieldcat 10 'X'  '' '' 'X'
    .

    add_sort '1' 'AID'.
    add_sort '2' 'BNAME'.
    add_sort '3' 'NAME_TEXT'.
    add_sort '4' 'START_DATE'.
    add_sort '5' 'START_TIME'.
    add_sort '6' 'END_DATE'.
    add_sort '7' 'END_TIME'.
    add_sort '8' 'SODVRSIO'.
    add_sort '9' 'SETID'.
    add_sort '10' 'DELETE_DATE'.
*  ENDIF.
*----Preparing layout structure
    gs_layout-sel_mode = 'A'. " for selection bar
    gs_layout-zebra = 'X'.

    gf_grid_initialized = 'X'.

*---sort output table only when load alv first time
    SORT gt_resultset DESCENDING BY aid.

  ELSE.
    CALL METHOD gr_alvgrid->get_sort_criteria
      IMPORTING
        et_sort = gt_sort.
*      clear g_clk_refresh.

    CALL METHOD gr_alvgrid->get_frontend_layout
      IMPORTING
        es_layout = gs_layout.


    CALL METHOD gr_alvgrid->get_frontend_fieldcatalog
      IMPORTING
        et_fieldcatalog = gt_fieldcat.


  ENDIF.

**--- sort
**--when sort first and click on refresh
*if g_clk_refresh = 'X'.
*CALL METHOD gr_alvgrid->get_sort_criteria
*  IMPORTING
*    ET_SORT = gt_sort.
*    clear g_clk_refresh.
*else.
*---create filters

  REFRESH lt_filter.
  PERFORM create_filter_alv  TABLES lt_filter.

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

*---- set Events
    SET HANDLER gr_event_handler->handle_toolbar FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_before_user_command
                                                    FOR gr_alvgrid.
    SET HANDLER gr_event_handler->handle_hotspot_click   FOR gr_alvgrid.
  ENDIF .
*.

*--e.g. initial sorting criteria, initial filtering criteria, excluding
*--functions
  CALL METHOD gr_alvgrid->set_table_for_first_display
    EXPORTING
      is_layout                     = gs_layout
    CHANGING
      it_outtab                     = gt_resultset[]
      it_fieldcatalog               = gt_fieldcat
      it_filter                     = lt_filter[]
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
 i_interactive.


  DATA: ls_toolbar  TYPE stb_button.
*  DELETE i_object->mt_toolbar WHERE function <> space.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'DELETE' TO ls_toolbar-function.
  MOVE 'Delete'(010) TO ls_toolbar-text.
  MOVE 'Delete'(010) TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 1.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'DISP_DTL' TO ls_toolbar-function.
  MOVE 'Display Details'(011) TO ls_toolbar-text.
  MOVE 'Display Details'(011) TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 2.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'DISP_RES' TO ls_toolbar-function.
  MOVE 'Display Results'(012) TO ls_toolbar-text.
  MOVE 'Display Results'(012) TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 3.

  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'COMP_RES' TO ls_toolbar-function.
  MOVE 'Compare Results'(013) TO ls_toolbar-text.
  MOVE 'Compare Results'(013) TO ls_toolbar-quickinfo.
  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 4.

* add push button to the alv tool bar
  CLEAR ls_toolbar.
  MOVE 0 TO ls_toolbar-butn_type.
  MOVE 'REFRESH' TO ls_toolbar-function.
  MOVE 'Refresh' TO ls_toolbar-text.
  MOVE 'Refresh' TO ls_toolbar-quickinfo.
  MOVE ' '       TO ls_toolbar-disabled.
  MOVE '@42@'    TO ls_toolbar-icon.
  INSERT ls_toolbar INTO i_object->mt_toolbar INDEX 5.

*  CLEAR ls_toolbar.
*  MOVE 0 TO ls_toolbar-butn_type.
*  MOVE 'NEW_ANA' TO ls_toolbar-function.
*  MOVE 'New Analysis'(013) TO ls_toolbar-text.
*  MOVE 'New Analysis'(013) TO ls_toolbar-quickinfo.
*  MOVE ' ' TO ls_toolbar-disabled.                          "#EC NOTEXT
*  INSERT ls_toolbar INTO  i_object->mt_toolbar INDEX 4.
  DELETE i_object->mt_toolbar WHERE function CS '&LOCAL&'.
ENDFORM .

*---------------------------------------------------------------------*
*       FORM fill_filters_dropdown                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_dropdown_values.
  TYPE-POOLS vrm.
  DATA: lt_value     TYPE vrm_values WITH HEADER LINE,
        ls_filter    TYPE lvc_s_filt,
        lt_swresisys TYPE TABLE OF /psyng/swresisys WITH HEADER LINE.
  DATA: BEGIN OF lt_system OCCURS 0,
          sysid(10) TYPE c,
        END OF lt_system.


  IF NOT gt_resultset[] IS INITIAL.
    lt_value-text = 'Today'.
    lt_value-key  = 'Today'.
    APPEND lt_value.
    lt_value-text = 'This Week'.
    lt_value-key  = 'This Week'.
    APPEND lt_value.
    lt_value-text = 'This Month'.
    lt_value-key  = 'This Month'.
    APPEND lt_value.
    lt_value-text = 'This Year'.
    lt_value-key  = 'This Year'.
    APPEND lt_value.
    lt_value-text = 'All Time'.
    lt_value-key  = 'All Time'.
    APPEND lt_value.
    DELETE lt_value WHERE key IS INITIAL.

    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = 'G_FLTR_ANA_STRT_IN'
        values          = lt_value[]
      EXCEPTIONS
        id_illegal_name = 1
        OTHERS          = 2.
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Illegal id Name'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)
    REFRESH lt_value.

*---system

    IF NOT gt_resultset[] IS INITIAL.
      SELECT * FROM /psyng/swresisys INTO TABLE lt_swresisys
      FOR ALL ENTRIES IN gt_resultset
      WHERE aid = gt_resultset-aid.
    ENDIF.
    SORT lt_swresisys BY sysid.
    DELETE ADJACENT DUPLICATES FROM lt_swresisys COMPARING sysid.
    LOOP AT lt_swresisys.
      lt_system-sysid = lt_swresisys-sysid.
      COLLECT lt_system.
    ENDLOOP.

*    LOOP AT gt_resultset.
*      SPLIT gt_resultset-sysid AT ',' INTO TABLE lt_system.
*      COLLECT lt_system.
*    ENDLOOP.

    LOOP AT lt_system.
      CONDENSE lt_system-sysid.
      lt_value-text = lt_system-sysid.
      lt_value-key  = lt_system-sysid.
      COLLECT lt_value.
    ENDLOOP.

    IF NOT lt_system[] IS INITIAL.
      lt_value-text = 'All Systems'.
      lt_value-key  = 'All Systems'.
      APPEND lt_value.
    ENDIF.
    DELETE lt_value WHERE key IS INITIAL.
    CALL FUNCTION 'VRM_SET_VALUES'
      EXPORTING
        id              = 'G_FLTR_SYSTEM'
        values          = lt_value[]
      EXCEPTIONS
        id_illegal_name = 1
        OTHERS          = 2.
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Illegal id Name'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)
    REFRESH lt_value.

  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_user_name                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BNAME                                                       *
*  -->  TYPE/PSYNG/SWRESHDR-BNAME                                     *
*  -->  E_NAME                                                        *
*---------------------------------------------------------------------*
FORM get_user_name USING    i_bname TYPE usr02-bname
                   CHANGING e_name TYPE ad_namtext.


  STATICS: lt_user TYPE HASHED TABLE OF /psyng/bc_uidn
                  WITH UNIQUE KEY bname.
  DATA: lt_uidn  TYPE TABLE OF /psyng/bc_uidn,
        lt_bname TYPE TABLE OF /psyng/sw_sel_opts_xubname
                 WITH HEADER LINE,
        ls_user  TYPE /psyng/bc_uidn.

  CLEAR: e_name.

*---if user text already in lt_user then exit
  READ TABLE lt_user INTO ls_user WITH TABLE KEY bname = i_bname.
  IF sy-subrc = 0.
    CONCATENATE ls_user-name_first ls_user-name_last
                INTO e_name SEPARATED BY space.
    EXIT.
  ENDIF.

  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.
  lt_bname-low    = i_bname.
  APPEND lt_bname.

*---user text
  CALL FUNCTION '/PSYNG/BC_011'
    TABLES
      it_bname = lt_bname
      et_uidn  = lt_uidn.

  READ TABLE lt_uidn INTO ls_user INDEX 1.
  CONCATENATE ls_user-name_first ls_user-name_last
              INTO e_name SEPARATED BY space.
  INSERT ls_user INTO TABLE lt_user.
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

  DATA: lt_resultset TYPE TABLE OF /psyng/swreshdr WITH HEADER LINE.
  READ TABLE gt_resultset INDEX i_row_id-index.
  IF i_column_id = 'AID'.
    REFRESH lt_resultset.
    MOVE-CORRESPONDING gt_resultset TO lt_resultset.
    APPEND lt_resultset.

*----AID (resultset) details screen
    CALL FUNCTION '/PSYNG/SW_STORED_RSLT_DETAILS'
      EXPORTING
        i_aid        = gt_resultset-aid
      TABLES
        it_resultset = lt_resultset.

  ELSEIF i_column_id = 'CONFLICTS'.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      if gt_resultset-summary_data = 'X'.
        SUBMIT /psyng/sw_137
             WITH p_aid = gt_resultset-aid
             VIA SELECTION-SCREEN AND RETURN.
      else.
        MESSAGE s033(/psyng/sw).
*   Stored results are not available to display.
      endif.
    ENDIF.
*-- conflicted users
  ELSEIF i_column_id = 'CONFLICTED_USERS'.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      if gt_resultset-summary_data = 'X'.
        SUBMIT /psyng/sw_137
             WITH p_aid = gt_resultset-aid
             WITH p_all = ''
             WITH p_uswc = 'X'
             VIA SELECTION-SCREEN AND RETURN.
      else.
        MESSAGE s033(/psyng/sw).
*   Stored results are not available to display.
      endif.
    ENDIF.
*-- unconflicted users
  ELSEIF i_column_id = 'UNCONFLICTED_USERS'.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      if gt_resultset-summary_data = 'X'.
        SUBMIT /psyng/sw_137
             WITH p_aid = gt_resultset-aid
             WITH p_all = ''
             WITH p_uswoc = 'X'
             VIA SELECTION-SCREEN AND RETURN.
      else.
        MESSAGE s033(/psyng/sw).
*   Stored results are not available to display.
      endif.
    ENDIF.

  ELSEIF i_column_id = 'USERS_ANALYZED'.
*--authority check
    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
              ID 'ACTVT' FIELD '03'.
    IF sy-subrc <> 0.
      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
          WITH
            'Display Results'(a01).
    ELSE.
      if gt_resultset-summary_data = 'X'.
        SUBMIT /psyng/sw_137
             WITH p_aid = gt_resultset-aid
             WITH p_all = 'X'
             VIA SELECTION-SCREEN AND RETURN.
      else.
        MESSAGE s033(/psyng/sw).
*   Stored results are not available to display.
      endif.
    ENDIF.

  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM create_filter_alv                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_FILTER                                                     *
*---------------------------------------------------------------------*
FORM create_filter_alv  TABLES et_filter TYPE lvc_t_filt.
  DATA: ls_filter    TYPE lvc_s_filt,
        l_date_high  LIKE sy-datum,
        lt_swresisys TYPE TABLE OF /psyng/swresisys WITH HEADER LINE.

  DATA: BEGIN OF lt_system OCCURS 0,
          sysid(10) TYPE c,
        END OF lt_system.
  REFRESH lt_swresisys.
*---system
  IF NOT g_fltr_system IS INITIAL.

    IF NOT gt_resultset[] IS INITIAL.
      SELECT * FROM /psyng/swresisys INTO TABLE lt_swresisys
      FOR ALL ENTRIES IN gt_resultset
      WHERE aid = gt_resultset-aid.
    ENDIF.
    SORT lt_swresisys BY sysid.
    DELETE ADJACENT DUPLICATES FROM lt_swresisys COMPARING sysid.

    LOOP AT lt_swresisys.
      lt_system-sysid = lt_swresisys-sysid.
      COLLECT lt_system.
    ENDLOOP.
*    LOOP AT gt_resultset.
*      IF gt_resultset-sysid CS ',' .
*        SPLIT gt_resultset-sysid AT ',' INTO TABLE lt_system.
*      ELSE.
*        lt_system-sysid = gt_resultset-sysid.
*        APPEND lt_system.
*      ENDIF.
*    ENDLOOP.
*    SORT lt_system BY sysid.
*    DELETE ADJACENT DUPLICATES FROM lt_system COMPARING sysid.

    LOOP AT lt_system WHERE sysid = g_fltr_system.
      ls_filter-fieldname = 'SYSID'.
      ls_filter-sign      = 'I'.
      ls_filter-option    = 'CP'.
      CONCATENATE '*' lt_system-sysid '*' INTO lt_system-sysid.
      ls_filter-low       = lt_system-sysid.
      COLLECT ls_filter INTO et_filter.
    ENDLOOP.
  ENDIF.
  IF g_fltr_system = 'All Systems'.
    DELETE et_filter WHERE fieldname = 'SYSID'.
  ENDIF.
*---started by
  IF NOT /psyng/swreshdr-bname IS INITIAL.
    ls_filter-fieldname = 'BNAME'.
    ls_filter-sign      = 'I'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = /psyng/swreshdr-bname.
    COLLECT ls_filter INTO et_filter.
  ENDIF.
**---no restriction
  IF NOT /psyng/swreshdr-no_restrictions IS INITIAL.
    ls_filter-fieldname = 'NO_RESTRICTIONS'.
    ls_filter-sign      = 'I'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       =  /psyng/swreshdr-no_restrictions.
    APPEND ls_filter TO et_filter.
  ENDIF.
**--- setid
  IF NOT /psyng/swreshdr-setid IS INITIAL.
    ls_filter-fieldname = 'SETID'.
    ls_filter-sign      = 'I'.
    ls_filter-option    = 'EQ'.
    ls_filter-low       = /psyng/swreshdr-setid. "gt_resultset-setid.
    COLLECT ls_filter INTO et_filter.
  ENDIF.
  IF g_fltr_all_set = 'X'.
    DELETE et_filter WHERE fieldname = 'SETID'.
  ENDIF.
***---SOD version
  ls_filter-fieldname = 'SODVRSIO'.
  ls_filter-sign      = 'I'.
  ls_filter-option    = 'EQ'.
  ls_filter-low       = /psyng/swreshdr-sodvrsio.
  COLLECT ls_filter INTO et_filter.
  IF g_fltr_all_vrsio = 'X'.
    DELETE et_filter WHERE fieldname = 'SODVRSIO'.
  ENDIF.
  if gf_show_unavailable is initial.
     delete et_filter WHERE fieldname = 'SUMMARY_DATA'.
     ls_filter-fieldname = 'SUMMARY_DATA'.
     ls_filter-sign      = 'I'.
     ls_filter-option    = 'EQ'.
     ls_filter-low       = 'X'.
     COLLECT ls_filter INTO et_filter.
  endif.
*---if all time then there shouldn't be any filter
*---Convertion of date range acc. to day, week, month, year
  IF NOT g_fltr_ana_strt_in IS INITIAL.
    IF g_fltr_ana_strt_in = 'Today'.
      ls_filter-fieldname = 'START_DATE'.
      ls_filter-sign      = 'I'.
      ls_filter-option    = 'EQ'.
      ls_filter-low       = sy-datum.
      COLLECT ls_filter INTO et_filter.
    ELSE.
      ls_filter-fieldname = 'START_DATE'.
      ls_filter-sign      = 'I'.
      ls_filter-option    = 'BT'.
      ls_filter-high       = sy-datum.
      CLEAR l_date_high.
      CASE g_fltr_ana_strt_in.
        WHEN 'This Week'.
          l_date_high = sy-datum - 7.
          ls_filter-low      = l_date_high.
        WHEN 'This Month'.
          l_date_high = sy-datum - 30.
          ls_filter-low      = l_date_high.
        WHEN 'This Year'.
          l_date_high = sy-datum - 365.
          ls_filter-low      = l_date_high.
      ENDCASE.
      COLLECT ls_filter INTO et_filter.
    ENDIF.

    IF g_fltr_ana_strt_in = 'All Time'.
      DELETE et_filter WHERE fieldname = 'START_DATE'.
    ENDIF.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM f4_bname                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM f4_bname.
  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.
  DATA: lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        lt_reshdr LIKE TABLE OF gt_resultset WITH HEADER LINE.
  REFRESH lt_reshdr.
  lt_reshdr[] = gt_resultset[].
  SORT lt_reshdr BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_reshdr COMPARING bname.

  LOOP AT lt_reshdr .
    lt_values-line = lt_reshdr-bname.
    APPEND lt_values.
    lt_values-line = lt_reshdr-name_text.
    APPEND lt_values.
  ENDLOOP.


  lt_fields-tabname   = '/PSYNG/SWRESHDR'.
  lt_fields-fieldname = 'BNAME'.
  APPEND lt_fields.
  lt_fields-tabname   = '/PSYNG/BC_UIDN'.
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
    /psyng/swreshdr-bname = lt_return-fieldval.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM load_data_100                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_data_100.
  DATA :lt_resultset TYPE TABLE OF /psyng/swreshdr WITH HEADER LINE,
        l_full_name  TYPE ad_namtext,
        lt_swresisys TYPE TABLE OF /psyng/swresisys WITH HEADER LINE.
  REFRESH : lt_resultset, lt_swresisys.
  IF gt_resultset[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_AID_READ'
      EXPORTING
        if_read      = 'X'
      TABLES
        et_resultset = lt_resultset.

*--get system detail
    IF NOT lt_resultset[] IS INITIAL.
      SELECT * FROM /psyng/swresisys INTO TABLE lt_swresisys
      FOR ALL ENTRIES IN lt_resultset
      WHERE aid = lt_resultset-aid
      AND sysid <> space.
    ENDIF.

*-- Odubey 08.11.2019 sort only when alv generate first time
*-- moved this statement into   display_alv perform
*      SORT lt_resultset DESCENDING BY aid.

* Prepare resultset output
    LOOP AT lt_resultset.
      MOVE-CORRESPONDING lt_resultset TO gt_resultset.
*      gt_resultset-end_time = lt_resultset-end_time.

*---User text
      PERFORM get_user_name USING lt_resultset-bname
                      CHANGING l_full_name.

      gt_resultset-name_text = l_full_name .
*--- system contcate separated by ,
      LOOP AT lt_swresisys WHERE aid = lt_resultset-aid.
        CONCATENATE gt_resultset-sysid   ',' lt_swresisys-sysid
                  INTO gt_resultset-sysid SEPARATED BY space.
      ENDLOOP.
      gt_resultset-sysid = gt_resultset-sysid+2.
*--Calculate unconflicted

      gt_resultset-unconflicted_users =
        gt_resultset-users_analyzed - gt_resultset-conflicted_users.

      perform check_available_data
      using
            gt_resultset-aid
      changing
          gt_resultset-summary_data
          gt_resultset-detail_data.

      APPEND gt_resultset.
      CLEAR: l_full_name, gt_resultset-sysid.
    ENDLOOP.
  ENDIF.
ENDFORM.
**&---------------------------------------------------------------------*
**&      Form  DISPLAY_ALV_200
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM display_alv_200 .
*
*  DATA: ls_stable   TYPE lvc_s_stbl.
*
*  IF gt_fieldcat_comp IS INITIAL.
**----Preparing field catalog.
*    add_column:
*    '' 'CONID' 'Conflict ID'(c23) gt_fieldcat_comp 12 ''  '' '' '',
*    '' 'DESCRIPTION' 'Risk Description'(c24) gt_fieldcat_comp 200  ''  '' '' '',
*    '' 'BUSAREA' 'Application'(c25)
*    gt_fieldcat_comp  4 '' '' '' '',
*    '' 'CONFLICTS_TOTAL' '' gt_fieldcat_comp 10 'X'  '' '' '',
*    'X' 'CONFLICTS_NEW' 'New Conflicts'(c26)
*       gt_fieldcat_comp  10 '' '' '' '',
*    'X' 'CONFLICTS_REM' 'Remediated Conflicts'(c27)
*       gt_fieldcat_comp  10 '' '' '' '',
*    '' 'SENSITIVITY' 'Sensitivity'(c28) gt_fieldcat_comp 8  ''  '' '' ''.
**----Preparing layout structure
*    gs_layout_comp-zebra = 'X'.
*    gs_layout_comp-cwidth_opt = 'X'.
*  ENDIF.
*
*  IF go_alvgrid_comp IS INITIAL .
**----Creating custom container instance
*    CREATE OBJECT go_container_comp
*      EXPORTING
*        container_name              = 'CC_ALV_COMP'
*      EXCEPTIONS
*        cntl_error                  = 1
*        cntl_system_error           = 2
*        create_error                = 3
*        lifetime_error              = 4
*        lifetime_dynpro_dynpro_link = 5
*        OTHERS                      = 6.
*    IF sy-subrc <> 0.
**--Exception handling
*    ENDIF.
**----Creating ALV Grid instance
*    CREATE OBJECT go_alvgrid_comp
*      EXPORTING
*        i_parent          = go_container_comp
*      EXCEPTIONS
*        error_cntl_create = 1
*        error_cntl_init   = 2
*        error_cntl_link   = 3
*        error_dp_create   = 4
*        OTHERS            = 5.
*    IF sy-subrc <> 0.
**--Exception handling
*    ENDIF.
*
*    SET HANDLER gr_event_handler_comp->handle_hotspot_click
*    FOR go_alvgrid_comp.
*
**--Call ALV
*    CALL METHOD go_alvgrid_comp->set_table_for_first_display
*      EXPORTING
*        is_layout                     = gs_layout_comp
*      CHANGING
*        it_outtab                     = gt_detail
*        it_fieldcatalog               = gt_fieldcat_comp
*      EXCEPTIONS
*        invalid_parameter_combination = 1
*        program_error                 = 2
*        too_many_lines                = 3
*        OTHERS                        = 4.
*    IF sy-subrc <> 0.
**--Exception handling
*    ENDIF.
*  ELSE.
*    ls_stable-row = 'X'.
*    ls_stable-col = 'X'.
*    CALL METHOD go_alvgrid_comp->refresh_table_display
*      EXPORTING
*        i_soft_refresh = 'X'
*        is_stable      = ls_stable
*      EXCEPTIONS
*        finished       = 1
*        OTHERS         = 2.
*  ENDIF .
*
*ENDFORM.
**---------------------------------------------------------------------*
**       FORM handle_hotspot_click_comp                                *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  I_ROW_ID                                                      *
**  -->  I_COLUMN_ID                                                   *
**  -->  IS_ROW_NO                                                     *
**---------------------------------------------------------------------*
*FORM handle_hotspot_click_comp USING i_row_id TYPE lvc_s_row
*i_column_id TYPE lvc_s_col
*is_row_no TYPE lvc_s_roid.
*
*  DATA: lr_conid  TYPE RANGE OF /psyng/conflict_id,
*        lr_bname  TYPE RANGE OF xubname,
*        ls_detail TYPE /psyng/sw_kpi_new_conflicts,
*        lsr_conid LIKE LINE OF lr_conid,
*        lsr_bname LIKE LINE OF lr_bname,
*        ls_users  TYPE /psyng/sw_sod_det_ana.
*  READ TABLE gt_detail INTO ls_detail INDEX i_row_id-index.
*  IF i_column_id = 'CONFLICTS_NEW'.
*    CHECK NOT ls_detail-conflicts_new IS INITIAL.
**--authority check
*    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
*              ID 'ACTVT' FIELD '03'.
*    IF sy-subrc <> 0.
*      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
*          WITH
*            'Display Results'(a01).
*    ELSE.
*      lsr_conid-sign   = 'I'.
*      lsr_conid-option = 'EQ'.
*      lsr_conid-low = ls_detail-conid.
*      APPEND lsr_conid TO lr_conid.
**Prepare range of users
*      lsr_bname-sign   = 'I'.
*      lsr_bname-option = 'EQ'.
*      LOOP AT gt_newconflict_users INTO ls_users
*        WHERE conid = ls_detail-conid.
*        lsr_bname-low = ls_users-bname.
*        APPEND lsr_bname TO lr_bname.
*      ENDLOOP.
*      SUBMIT /psyng/sw_137
*           WITH p_aid = g_latest_aid
*           WITH s_conid IN lr_conid
*           WITH s_bname IN lr_bname
*           AND RETURN.
*    ENDIF.
*  ELSEIF i_column_id = 'CONFLICTS_REM'.
*    CHECK NOT ls_detail-conflicts_rem IS INITIAL.
**--authority check
*    AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
*              ID 'ACTVT' FIELD '03'.
*    IF sy-subrc <> 0.
*      MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
*          WITH
*            'Display Results'(a01).
*    ELSE.
*      lsr_conid-sign   = 'I'.
*      lsr_conid-option = 'EQ'.
*      lsr_conid-low = ls_detail-conid.
*      APPEND lsr_conid TO lr_conid.
**Prepare range of users
*      lsr_bname-sign   = 'I'.
*      lsr_bname-option = 'EQ'.
*      LOOP AT gt_remconflict_users INTO ls_users
*        WHERE conid = ls_detail-conid.
*        lsr_bname-low = ls_users-bname.
*        APPEND lsr_bname TO lr_bname.
*      ENDLOOP.
*      SUBMIT /psyng/sw_137
*           WITH p_aid = g_pre_aid
*           WITH s_conid IN lr_conid
*           WITH s_bname IN lr_bname
*           AND RETURN.
*    ENDIF.
*  ENDIF.
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CHECK_AVAILABLE_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_RESULTSET_AID  text
*      <--P_GT_RESULTSET_SUMMARY_DATA  text
*      <--P_GT_RESULTSET_DETAILED_DATA  text
*----------------------------------------------------------------------*
FORM check_available_data  USING    i_aid
                           CHANGING ef_summary_data
                                    ef_detailed_data.
  clear : ef_summary_data, ef_detailed_data.
  select single aid from /psyng/swresusr into i_aid where aid = i_aid.
  if sy-subrc = 0.
    ef_summary_data = 'X'.
    select single aid from /psyng/swresiaut into i_aid where aid = i_aid.
    if sy-subrc = 0.
      ef_detailed_data = 'X'.
    endif.
  endif.
ENDFORM.
