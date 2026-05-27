REPORT /psyng/sw_120.

START-OF-SELECTION.
*BOC AKUMAR SE VF scan changes-12/04/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024
MESSAGE s002(/psyng/sw) WITH 'This functionality is Obsolete as of SE4.5PS3'.
leave list-processing.
*   & & & &

*TABLES : usr02,rfcdes.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.
*
*CONSTANTS: max_wp TYPE i VALUE '4'.
*
*data : g_bname type xubname,
*       g_JOB_PERIOD type  /PSYNG/SW_CNT_PERIODTYPE,
*       g_JOB_IMMEDIATE type flag,
*       g_JOB_PERIODIC type flag,
*       g_JOB_PERIOD_NUMBER type i,
*       g_JOB_START_DATE type dats,
*       g_JOB_START_TIME type tims.
*
*
*
*selection-screen begin of screen 1010 as subscreen.
*SELECTION-SCREEN: BEGIN OF BLOCK act_o WITH FRAME TITLE text-t01.
*PARAMETERS : p_init  TYPE flag RADIOBUTTON GROUP g1 ,
*             p_updat TYPE flag RADIOBUTTON GROUP g1 DEFAULT 'X'.
*SELECTION-SCREEN: BEGIN OF LINE.
*
*SELECTION-SCREEN: COMMENT 1(50) text-188.
*SELECTION-SCREEN: END OF LINE.
*
*PARAMETERS : p_sod  TYPE flag AS CHECKBOX default 'X' ,
*             p_ca   TYPE flag AS CHECKBOX default 'X',
*             p_tc   TYPE flag AS CHECKBOX default 'X'.
*
*
*SELECTION-SCREEN: END OF BLOCK act_o .
*SELECTION-SCREEN: BEGIN OF BLOCK usr_o WITH FRAME TITLE text-t02.
*SELECT-OPTIONS : s_bname FOR usr02-bname.
*PARAMETERS :    p_active TYPE flag AS CHECKBOX default 'X',
*                p_vrsio  TYPE /psyng/sodvrsio.
*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS: p_wp(1) TYPE n DEFAULT '0' MODIF ID exe.
*
*SELECTION-SCREEN: COMMENT 3(65) text-008
*                                    MODIF ID exe.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS : p_defgrp TYPE flag  RADIOBUTTON GROUP ppro DEFAULT 'X'
*                                    MODIF ID exe.
*SELECTION-SCREEN: COMMENT 3(27) text-090 FOR FIELD p_defgrp
*                                    MODIF ID exe.
*SELECTION-SCREEN: END OF LINE.
*
*
*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS : p_specgr TYPE flag  RADIOBUTTON GROUP ppro
*                                   MODIF ID exe.
*SELECTION-SCREEN: COMMENT 3(27) text-089 FOR FIELD p_specgr
*                                   MODIF ID exe.
*SELECTION-SCREEN: POSITION 30.
*PARAMETERS: pgroup TYPE rzlli_apcl MODIF ID exe.
*SELECTION-SCREEN: END OF LINE.
*
*SELECTION-SCREEN: BEGIN OF LINE.
*
*PARAMETERS : specsrv TYPE flag  RADIOBUTTON GROUP ppro
*                                   MODIF ID exe.
*SELECTION-SCREEN: COMMENT 3(27) text-088 FOR FIELD specsrv
*                                   MODIF ID exe.
*SELECTION-SCREEN: POSITION 30.
*PARAMETERS: pserver LIKE msxxlist-name MODIF ID exe.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN PUSHBUTTON  30(20) text-002 USER-COMMAND gpsv
*                                       MODIF ID exe.
*SELECTION-SCREEN: END OF LINE.
*PARAMETERS : upp TYPE i                MODIF ID exe DEFAULT '5000'.
*SELECTION-SCREEN: END OF BLOCK usr_o .
*SELECTION-SCREEN: BEGIN OF BLOCK rfc_o WITH FRAME TITLE text-t03.
*PARAMETERS: rfcs TYPE rfcdes-rfcdest MATCHCODE OBJECT
*/psyng/sw_rfcsh MODIF ID rem.
*SELECTION-SCREEN: END OF BLOCK rfc_o .
*selection-screen end of screen 1010.
*
*
*INITIALIZATION.
*EXELOG sy-repid ''.
*
**---------------------------------------------------------------------*
**       CLASS lcl_event_handler DEFINITION
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
*CLASS lcl_event_handler DEFINITION .
*  PUBLIC SECTION .
*    METHODS:
**--To add new functional buttons to the ALV toolbar
**    handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
**    IMPORTING e_object e_interactive ,
***--To implement user commands
**    handle_user_command
**    FOR EVENT user_command OF cl_gui_alv_grid
**    IMPORTING e_ucomm ,
***--Hotspot click control
**    handle_hotspot_click
**    FOR EVENT hotspot_click OF cl_gui_alv_grid
**    IMPORTING e_row_id e_column_id es_row_no ,
***--Double-click control
**    handle_double_click
**    FOR EVENT double_click OF cl_gui_alv_grid
**    IMPORTING e_row e_column ,
***--To be triggered before user commands
**    handle_before_user_command
**    FOR EVENT before_user_command OF cl_gui_alv_grid
**    IMPORTING e_ucomm ,
***--To be triggered after user commands
**    handle_after_user_command
**    FOR EVENT context_menu_request OF cl_gui_alv_grid
**    IMPORTING e_object
***--Controlling data changes when ALV Grid is editable
**    handle_data_changed
**    FOR EVENT data_changed OF cl_gui_alv_grid
**    IMPORTING er_data_changed
***--To be triggered after data changing is finished
**    handle_data_changed_finished
**    FOR EVENT data_changed_finished OF cl_gui_alv_grid
**    IMPORTING e_modified ,
***--To control menu buttons
**    handle_menu_button
**    FOR EVENT menu_button OF cl_gui_alv_grid
**    IMPORTING e_oject e_ucomm ,
**--To control button clicks
**ES_COL_ID Type  LVC_S_COL
**ES_ROW_NO Type  LVC_S_ROID
*    handle_button_click
*    FOR EVENT button_click OF cl_gui_alv_grid
*    IMPORTING ES_COL_ID ES_ROW_NO .
*  PRIVATE SECTION.
*ENDCLASS.
**---------------------------------------------------------------------*
**       CLASS lcl_event_handler IMPLEMENTATION
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
*CLASS lcl_event_handler IMPLEMENTATION .
***--Handle Toolbar
**  METHOD handle_toolbar.
**    PERFORM handle_toolbar USING e_object e_interactive .
**  ENDMETHOD .
***--Handle Hotspot Click
**  METHOD handle_hotspot_click .
**    PERFORM handle_hotspot_click USING e_row_id e_column_id es_row_no .
**  ENDMETHOD .
***--Handle Double Click
**  METHOD handle_double_click .
**    PERFORM handle_double_click USING e_row e_column es_row_no .
**  ENDMETHOD .
***--Handle User Command
**  METHOD handle_user_command .
**    PERFORM handle_user_command USING e_ucomm .
**  ENDMETHOD.
***--Handle After User Command
**  METHOD handle_context_menu_request .
**    PERFORM handle_context_menu_request USING e_object .
**  ENDMETHOD.
***--Handle Before User Command
**  METHOD handle_before_user_command .
**    PERFORM handle_before_user_command USING e_ucomm .
**  ENDMETHOD .
***--Handle Data Changed
**  METHOD handle_data_changed .
**    PERFORM handle_data_changed USING er_data_changed .
**  ENDMETHOD.
***--Handle Data Changed Finished
**  METHOD handle_data_changed_finished .
**    PERFORM handle_data_changed_finished USING e_modified .
**  ENDMETHOD .
***--Handle Menu Buttons
**  METHOD handle_menu_button .
**    PERFORM handle_menu_button USING e_object e_ucomm .
**  ENDMETHOD .
**--Handle Button Click
*  METHOD handle_button_click .
*    PERFORM handle_button_click USING ES_COL_ID ES_ROW_NO .
*  ENDMETHOD .
*ENDCLASS .
*DATA : gr_alvgrid TYPE REF TO cl_gui_alv_grid,
*       gr_alv_container TYPE REF TO cl_gui_custom_container,
*       gt_fieldcat TYPE lvc_t_fcat,
*       gs_layout TYPE lvc_s_layo,
*       gt_sort TYPE lvc_t_sort,
*       g_period_type TYPE /psyng/sw_cnt_periodtype value 'WEEK',
*       g_num    TYPE i value 1,
*       gr_event_handler TYPE REF TO lcl_event_handler,
*       g_central_system type rfcdest.
*DATA :  BEGIN OF gt_overview OCCURS 1,
*    vrsio         TYPE /psyng/sodvrsio,
*    sysclient     TYPE rfcdest,
*    sod_date      TYPE /psyng/text40,
*    sod_realdate  TYPE dats,
*    sod_realtime  TYPE tims,
*    sod_users     TYPE i,
*    ca_date       TYPE /psyng/text40,
*    ca_realdate   TYPE dats,
*    ca_realtime   TYPE tims,
*    ca_users      TYPE i,
*    ct_date       TYPE /psyng/text40,
*    ct_realdate   TYPE dats,
*    ct_realtime   TYPE tims,
*    ct_users      TYPE i,
*    totalusers    TYPE i,
*    button        TYPE /psyng/char35,
*    cellcolors    TYPE lvc_t_scol,
*    cellstyles    TYPE lvc_t_styl,
*  END OF gt_overview.
*DATA :  BEGIN OF gt_summary OCCURS 1,
*    vrsio         TYPE /psyng/sodvrsio,
*    sysclient     TYPE rfcdest,
*    sod_date      TYPE /psyng/text40,
*    ca_date       TYPE /psyng/text40,
*    ct_date       TYPE /psyng/text40,
*  END OF gt_summary.
*
*
INCLUDE /psyng/sw_120o01.
INCLUDE /psyng/sw_120i01.
*
*
**&---------------------------------------------------------------------*
**&      Form  load_data
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM load_data.
*  DATA : lt_overview LIKE TABLE OF gt_overview WITH HEADER LINE,
*         lt_systems  LIKE TABLE OF gt_summary WITH HEADER LINE,
*         l_time TYPE tims,
*         l_date TYPE dats,
*         ls_time(8) TYPE c,
*         ls_date(10) TYPE c,
*         l_initial_date TYPE string,
*         l_days TYPE i,
*         l_minutes type i,
*         l_highldate TYPE dats,
*         l_highltime type tims,
*         l_datestr TYPE /psyng/text40,
*         ls_style TYPE lvc_s_styl,
*         lt_rfcdes type table of /PSYNG/SW_RFCDES with header line,
*         l_sys   type string,
*         l_mandt type string,
*         l_len type i.
*
*  WRITE l_date TO ls_date .
*  WRITE l_time TO ls_time.
*  CONCATENATE ls_date ls_time INTO l_initial_date
*  SEPARATED BY space.
*
*  REFRESH : gt_overview.
*  DATA : BEGIN OF lt_summary OCCURS 0,
*      date          TYPE dats,
*      time          TYPE tims,
*      users         TYPE i,
*      END OF lt_summary.
*   DATA   ls_cellcolor TYPE lvc_s_scol.
*
*  SELECT
*    DISTINCT sysclient vrsio
*    FROM /psyng/sw_cntusv
*    INTO CORRESPONDING FIELDS OF
*    TABLE lt_systems.
*
*
*  LOOP AT lt_systems.
*    lt_overview-sysclient = lt_systems-sysclient.
*    lt_overview-vrsio     = lt_systems-vrsio.
*
**--total user count
*    SELECT SINGLE usercount AS totalusers      "#EC CI_SEL_NESTED
*    FROM /psyng/sw_cntust
*    INTO lt_overview-totalusers
*    WHERE sysclient = lt_systems-sysclient.
**--SOD analysis info
*    SELECT sod_date AS date sod_time AS time     "#EC CI_SEL_NESTED
*    COUNT( DISTINCT userid ) AS users
*    FROM /psyng/sw_cntusa
*    INTO CORRESPONDING FIELDS OF TABLE lt_summary
*    WHERE sysclient = lt_systems-sysclient AND
*            vrsio     = lt_systems-vrsio
*    GROUP by sod_date sod_time.
*    LOOP AT lt_summary.
*      WRITE lt_summary-date TO ls_date .
*      WRITE lt_summary-time TO ls_time.
*      CONCATENATE ls_date ls_time INTO lt_overview-sod_date
*      SEPARATED BY space.
*      lt_overview-sod_users = lt_summary-users.
*      lt_overview-sod_realdate = lt_summary-date.
*      lt_overview-sod_realtime = lt_summary-time.
*      APPEND lt_overview.
*    ENDLOOP.
*
**--CA analysis info
*    SELECT ca_date AS date ca_time AS time      "#EC CI_SEL_NESTED
*    COUNT( DISTINCT userid ) AS users
*    FROM /psyng/sw_cntusa
*    INTO CORRESPONDING FIELDS OF TABLE lt_summary
*    WHERE sysclient = lt_systems-sysclient AND
*            vrsio     = lt_systems-vrsio
*    GROUP by ca_date ca_time.
*    LOOP AT lt_summary.
*      WRITE lt_summary-date TO ls_date .
*      WRITE lt_summary-time TO ls_time.
*      CONCATENATE ls_date ls_time INTO lt_overview-ca_date
*      SEPARATED BY space.
*      lt_overview-ca_users = lt_summary-users.
*      lt_overview-ca_realdate = lt_summary-date.
*      lt_overview-ca_realtime = lt_summary-time.
*
*      APPEND lt_overview.
*    ENDLOOP.
*    CLEAR : lt_overview-ca_date,
*            lt_overview-ca_users,
*            lt_overview-cellcolors.
**--CT analysis info
*    SELECT ct_date AS date ct_time AS time      "#EC CI_SEL_NESTED
*    COUNT( DISTINCT userid ) AS users
*    FROM /psyng/sw_cntusa
*    INTO CORRESPONDING FIELDS OF TABLE lt_summary
*    WHERE sysclient = lt_systems-sysclient AND
*            vrsio     = lt_systems-vrsio
*    GROUP by ct_date ct_time.
*    LOOP AT lt_summary.
*      WRITE lt_summary-date TO ls_date .
*      WRITE lt_summary-time TO ls_time.
*      CONCATENATE ls_date ls_time INTO lt_overview-ct_date
*      SEPARATED BY space.
*      lt_overview-ct_users = lt_summary-users.
*      lt_overview-ct_realdate = lt_summary-date.
*      lt_overview-ct_realtime = lt_summary-time.
*      APPEND lt_overview.
*
*    ENDLOOP.
*    CLEAR : lt_overview-ct_date, lt_overview-ct_users.
*  ENDLOOP.
**--LT_OVERVIEW can contain up to 3 rows for each time the update was ran
**  group this into 1 record.
*  DATA : lt_overview2 LIKE TABLE OF gt_summary WITH HEADER LINE.
**--Collect unique dates
*  LOOP AT lt_overview.
*    lt_overview2-sysclient = lt_overview-sysclient.
*    lt_overview2-vrsio     = lt_overview-vrsio.
*    lt_overview2-sod_date = lt_overview-sod_date.
*    COLLECT lt_overview2.
*    lt_overview2-sod_date = lt_overview-ca_date.
*    COLLECT lt_overview2.
*    lt_overview2-sod_date = lt_overview-ct_date.
*    COLLECT lt_overview2.
*  ENDLOOP.
*  DELETE lt_overview2 WHERE
*  sod_date IS initial OR sod_date = l_initial_date.
**--All three were analyzed
*
*
*
*
**--Also get any empty systems
*  SELECT
*    DISTINCT *
*    FROM /PSYNG/SW_RFCDES
*    INTO CORRESPONDING FIELDS OF
*    TABLE lt_rfcdes.
*
*  loop at lt_rfcdes.
**--If there are any systems defined that appear to be related
** to central directory   (have the format sysclient)
** and there's no data for these yet, add them to the list anyway
*    l_len = strlen( lt_rfcdes-rfcname ).
*    if l_len  = 6.
*      l_sys = lt_rfcdes-rfcname(3).
*      l_mandt = lt_rfcdes-rfcname+3(3).
*      if l_mandt co '0123456789'.
*        read table lt_overview2 with key sysclient =  lt_rfcdes-rfcname.
*        if sy-subrc <> 0.
*          clear gt_overview.
*          lt_overview2-sysclient = lt_rfcdes-rfcname.
*          append lt_overview2.
*        endif.
*      endif.
*    endif.
*  endloop.
*
*
*  LOOP AT lt_overview2.
*    CLEAR gt_overview.
*    gt_overview-sysclient = lt_overview2-sysclient.
*    gt_overview-vrsio = lt_overview2-vrsio.
*    SELECT SINGLE usercount FROM /psyng/sw_cntust   "#EC CI_SEL_NESTED
*    INTO gt_overview-totalusers
*    WHERE sysclient = lt_overview2-sysclient.
*
*    READ TABLE lt_overview WITH KEY
*      sysclient = lt_overview2-sysclient
*      vrsio     = lt_overview2-vrsio
*      sod_date  = lt_overview2-sod_date.
*    IF sy-subrc = 0.
*      gt_overview-sod_date = lt_overview-sod_date.
*      gt_overview-sod_users = lt_overview-sod_users.
*      gt_overview-sod_realdate = lt_overview-sod_realdate.
*      gt_overview-sod_realtime = lt_overview-sod_realtime.
*    ENDIF.
*    READ TABLE lt_overview WITH KEY
*      sysclient = lt_overview2-sysclient
*      vrsio     = lt_overview2-vrsio
*      ca_date  = lt_overview2-sod_date.
*    IF sy-subrc = 0.
*      gt_overview-ca_date = lt_overview-ca_date.
*      gt_overview-ca_users = lt_overview-ca_users.
*      gt_overview-ca_realdate = lt_overview-ca_realdate.
*      gt_overview-ca_realtime = lt_overview-ca_realtime.
*    ENDIF.
*    READ TABLE lt_overview WITH KEY
*      sysclient = lt_overview2-sysclient
*      vrsio     = lt_overview2-vrsio
*      ct_date  = lt_overview2-sod_date.
*    IF sy-subrc = 0.
*      gt_overview-ct_date = lt_overview-ct_date.
*      gt_overview-ct_users = lt_overview-ct_users.
*      gt_overview-ct_realdate = lt_overview-ct_realdate.
*      gt_overview-ct_realtime = lt_overview-ct_realtime.
*    ENDIF.
*
*
*
*
**--Highlighting code
*    CASE  g_period_type.
*      WHEN 'MINUTE'.
*        l_minutes = g_num.
*      WHEN 'HOUR'.
*        l_minutes = g_num * 60.
*      WHEN 'DAY'.
*        l_days = g_num.
*      WHEN 'WEEK'.
*        l_days = g_num * 7.
*      WHEN 'MONTH'.
*        l_days = g_num * 30.
*      WHEN 'YEAR'.
*        l_days = g_num * 365.
*    ENDCASE.
*    IF l_days > 0.
*      l_highldate = sy-datum - l_days.
*      IF NOT gt_overview-sod_realdate IS INITIAL.
*
*        if gt_overview-sod_realdate  <  l_highldate.
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'SOD_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      IF NOT gt_overview-ca_realdate IS INITIAL.
*
*        if gt_overview-ca_realdate  <  l_highldate.
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'CA_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      IF NOT gt_overview-ct_realdate IS INITIAL.
*        if gt_overview-ct_realdate  <  l_highldate.
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'CT_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      if gt_overview-totalusers is initial.
*        ls_cellcolor-fname = 'SYSCLIENT' .
*        ls_cellcolor-color-col = '6' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      endif.
*    elseif l_minutes > 0.
*      l_highldate = sy-datum - l_days.
*      l_highltime = sy-uzeit - ( l_minutes * 60 ).
*      IF NOT gt_overview-sod_realdate IS INITIAL.
*        if gt_overview-sod_realdate  <  l_highldate
*           or
*           ( gt_overview-sod_realdate =  l_highldate and
*             gt_overview-sod_realtime < l_highltime ).
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'SOD_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      IF NOT gt_overview-ca_realdate IS INITIAL.
*
*        if gt_overview-ca_realdate  <  l_highldate
*           or
*           ( gt_overview-ca_realdate =  l_highldate and
*             gt_overview-ca_realtime < l_highltime ).
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'CA_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      IF NOT gt_overview-ct_realdate IS INITIAL.
*       if gt_overview-ct_realdate  <  l_highldate
*           or
*           ( gt_overview-ct_realdate =  l_highldate and
*             gt_overview-ct_realtime < l_highltime ).
*          ls_cellcolor-color-col = '6' ."red
*        else.
*          ls_cellcolor-color-col = '5' ."green
*        endif.
*        ls_cellcolor-fname = 'CT_DATE' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      ENDIF.
*      if gt_overview-totalusers is initial.
*        ls_cellcolor-fname = 'SYSCLIENT' .
*        ls_cellcolor-color-col = '6' .
*        ls_cellcolor-color-int = '1' .
*        APPEND ls_cellcolor TO gt_overview-cellcolors .
*      endif.
*
*    ENDIF.
*    APPEND gt_overview.
*    REFRESH :gt_overview-cellcolors.
*  ENDLOOP.
*
*
*
**--Add button to list
*
*  ls_style-fieldname = 'BUTTON' .
*  ls_style-style = cl_gui_alv_grid=>mc_style_button .
*  APPEND ls_style TO gt_overview-cellstyles.
*  MODIFY gt_overview  TRANSPORTING cellstyles WHERE button = ''.
*
*  gt_overview-button = 'Update'(b01).
*  MODIFY gt_overview  TRANSPORTING button WHERE button = ''.
*ENDFORM.                    " load_data
**&---------------------------------------------------------------------*
**&      Form  show_grid
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM show_grid.
*  IF gr_alvgrid IS INITIAL .
*    CREATE OBJECT gr_alv_container
*    EXPORTING
*      container_name = 'G_ALV_CONT'
*    EXCEPTIONS
*      cntl_error = 1
*      cntl_system_error = 2
*      create_error = 3
*      lifetime_error = 4
*      lifetime_dynpro_dynpro_link = 5
*      others = 6 .
*    IF sy-subrc <> 0.
**--Exception handling
*    ENDIF.
*    CREATE OBJECT gr_alvgrid
*      EXPORTING
*        i_parent = gr_alv_container
*      EXCEPTIONS
*        error_cntl_create = 1
*        error_cntl_init = 2
*        error_cntl_link = 3
*        error_dp_create = 4
*        others = 5 .
**--Preparing field catalog.
*    PERFORM prepare_field_catalog CHANGING gt_fieldcat .
**--Preparing layout structure
*    PERFORM prepare_layout CHANGING gs_layout .
*    PERFORM prepare_sort_table CHANGING gt_sort.
*    SET HANDLER gr_event_handler->handle_button_click FOR gr_alvgrid.
*
*
*    CALL METHOD gr_alvgrid->set_table_for_first_display
*      EXPORTING
**     I_BUFFER_ACTIVE =
**     I_CONSISTENCY_CHECK =
**     I_STRUCTURE_NAME =
**     IS_VARIANT =
**     I_SAVE =
**     I_DEFAULT = 'X'
*      is_layout = gs_layout
**     IS_PRINT =
**     IT_SPECIAL_GROUPS =
**     IT_TOOLBAR_EXCLUDING =
**     IT_HYPERLINK =
*      CHANGING
*      it_outtab = gt_overview[]
*      it_fieldcatalog = gt_fieldcat
*      it_sort = gt_sort
**     IT_FILTER =
*      EXCEPTIONS
*        invalid_parameter_combination = 1
*        program_error = 2
*        too_many_lines = 3
*        OTHERS = 4 .
*  ELSE .
*    CALL METHOD gr_alvgrid->refresh_table_display
**   EXPORTING
**   IS_STABLE =
**   I_SOFT_REFRESH =
*    EXCEPTIONS
*      finished = 1
*      OTHERS = 2 .
*    IF sy-subrc <> 0.
**  --Exception handling
*    ENDIF.
*  ENDIF .
*ENDFORM.                    " show_grid
**&---------------------------------------------------------------------*
**&      Form  prepare_field_catalog
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      <--P_GT_FIELDCAT  text
**----------------------------------------------------------------------*
*FORM prepare_field_catalog CHANGING pt_fieldcat TYPE lvc_t_fcat .
**    sysclient     TYPE rfcdest,
**    vrsio         TYPE /psyng/sodvrsio,
**    totalusers    TYPE i,
**    analyzedusers TYPE i,
**    sod_date      TYPE dats,
**    sod_time      TYPE tims,
**    ca_date       TYPE dats,
**    ca_time       TYPE tims,
**    ct_date       TYPE dats,
**    ct_time       TYPE tims,
*
*  DATA ls_fcat TYPE lvc_s_fcat .
*  ls_fcat-fieldname = 'SYSCLIENT' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '15' .
*  ls_fcat-coltext   = 'Source System'(a01) .
*  ls_fcat-seltext   = 'Source System'(a01) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*  ls_fcat-fieldname = 'VRSIO' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '10' .
*  ls_fcat-coltext   = 'Sod Version'(a02) .
*  ls_fcat-seltext   = 'Sod Version'(a02) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*  ls_fcat-fieldname = 'TOTALUSERS' .
*  ls_fcat-inttype   = 'I' .
*  ls_fcat-outputlen = '10' .
*  ls_fcat-coltext   = 'Total User Count'(a03) .
*  ls_fcat-seltext   = 'Total User Count'(a03) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*
*  ls_fcat-fieldname = 'SOD_USERS' .
*  ls_fcat-inttype   = 'I' .
*  ls_fcat-outputlen = '7' .
*  ls_fcat-coltext   = 'SOD Users'(a10) .
*  ls_fcat-seltext   = 'SOD Users'(a10) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*
*  ls_fcat-fieldname = 'SOD_DATE' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '25' .
*  ls_fcat-coltext   = 'SOD Analysis'(a05) .
*  ls_fcat-seltext   = 'SOD Analysis'(a05) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*  ls_fcat-fieldname = 'CA_USERS' .
*  ls_fcat-inttype   = 'I' .
*  ls_fcat-outputlen = '7' .
*  ls_fcat-coltext   = 'CA Users'(a11) .
*  ls_fcat-seltext   = 'CA Users'(a11) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*  ls_fcat-fieldname = 'CA_DATE' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '25' .
*  ls_fcat-coltext   = 'Critical Auth Analysis'(a07) .
*  ls_fcat-seltext   = 'Critical Auth Analysise'(a07) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*  ls_fcat-fieldname = 'CT_USERS' .
*  ls_fcat-inttype   = 'I' .
*  ls_fcat-outputlen = '7' .
*  ls_fcat-coltext   = 'CT Users'(a12) .
*  ls_fcat-seltext   = 'CT Users'(a12) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*
*
*  ls_fcat-fieldname = 'CT_DATE' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '25' .
*  ls_fcat-coltext   = 'Critical Transaction Analysis'(a09) .
*  ls_fcat-seltext   = 'Critical Transaction Analysis'(a09) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*
*  ls_fcat-fieldname = 'BUTTON' .
*  ls_fcat-inttype   = 'C' .
*  ls_fcat-outputlen = '20' .
*  ls_fcat-coltext   = 'Update'(b01) .
*  ls_fcat-seltext   = 'Update'(b01) .
*  APPEND ls_fcat TO pt_fieldcat .
*
*
*
*
*ENDFORM.                    " prepare_field_catalog
**&---------------------------------------------------------------------*
**&      Form  prepare_layout
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      <--P_GS_LAYOUT  text
**----------------------------------------------------------------------*
*FORM prepare_layout CHANGING ps_layout TYPE lvc_s_layo.
*  ps_layout-zebra = 'X' .
*  ps_layout-ctab_fname = 'CELLCOLORS'.
*  ps_layout-stylefname = 'CELLSTYLES' .
**  ps_layout-smalltitle = 'X' .
*ENDFORM.                    " prepare_layout
*
**---------------------------------------------------------------------*
**       FORM prepare_sort_table                                       *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  PT_SORT                                                       *
**---------------------------------------------------------------------*
*FORM prepare_sort_table CHANGING pt_sort TYPE lvc_t_sort .
*  DATA ls_sort TYPE lvc_s_sort .
*  ls_sort-up = 'X' .
*  ls_sort-down = space .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'VRSIO' .
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'SYSCLIENT' .
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'SOD_DATE' .
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'CA_DATE' .
*  APPEND ls_sort TO pt_sort .
*
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'CT_DATE' .
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'TOTALUSERS' .
*  APPEND ls_sort TO pt_sort .
*
*  ls_sort-up = space .
*  ls_sort-down = 'X' .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'SOD_USERS' .
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'CA_USERS'.
*  APPEND ls_sort TO pt_sort .
*
*  ADD 1 TO ls_sort-spos.
*  ls_sort-fieldname = 'CT_USERS' .
*  APPEND ls_sort TO pt_sort .
*
*
*ENDFORM. " prepare_sort_table
**&---------------------------------------------------------------------*
**&      Form  update_alv
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*FORM update_alv.
*  PERFORM load_data.
*  PERFORM show_grid.
*ENDFORM.                    " update_alv
**&---------------------------------------------------------------------*
**&      Form  handle_button_click
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**      -->P_E_OBJECT  text
**      -->P_E_UCOMM  text
**----------------------------------------------------------------------*
*FORM handle_button_click USING
*    ES_COL_ID  Type  LVC_S_COL
*    ES_ROW_NO  Type  LVC_S_ROID.
*  rfcs = g_central_system.
*  read table gt_overview index es_row_no-ROW_ID.
*  p_vrsio = gt_overview-vrsio.
*  call screen '0200' STARTING AT 10 5.
*
*ENDFORM.                    " handle_button_click
