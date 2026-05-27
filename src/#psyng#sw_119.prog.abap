REPORT /psyng/sw_119 .
TYPE-POOLS:slis.
TABLES : /psyng/sw_uinfo,
         /psyng/conflict,
         /psyng/function,
         /psyng/busarea,
         /psyng/bus_proce,
         /psyng/critcodes,
         /psyng/swaudhdr,
         /psyng/sw_cntca,
         rfcdes.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

DATA: gt_irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.

DATA: g_program         LIKE sy-repid,                   "For ALV call
      g_exit_proc,
      gf_central_uid TYPE flag,
      g_ucomm LIKE sy-ucomm,
      gt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname,
      gt_cntuse TYPE TABLE OF /psyng/sw_cntuse,
      g_analyzed_users TYPE i.
DATA: g_curr_variant LIKE  rsvar-variant,
      gt_output_sod  TYPE TABLE OF /psyng/sw_sod_output_org WITH HEADER
        LINE,
      gt_output_ca  TYPE TABLE OF /psyng/sw_sod_output_org WITH HEADER
      LINE,
      gt_output_ct TYPE TABLE OF /psyng/sw_sod_output_org WITH HEADER
      LINE.
*--Structures for ALV Field Catalog
DATA : BEGIN OF gt_sodoutput OCCURS 0,
  sel       TYPE flag,
  company   LIKE /psyng/sw_uinfo-company,
  department LIKE /psyng/sw_uinfo-department,
  bname     LIKE usr02-bname,
  name_text LIKE /psyng/sw_uinfo-name_text,
  class     LIKE usr02-class,
  conid     LIKE /psyng/conflict-conid,
  condesc   LIKE /psyng/conflict-description,
  imp       LIKE /psyng/conflict-imp,
  impsort   TYPE i,
  contid    LIKE /psyng/conflict-contid,
  origin    like /psyng/conflict-contid, "LOCAL/REMOTE/CROSS
  END OF gt_sodoutput.
DATA : BEGIN OF gt_caoutput OCCURS 0,
  sel       TYPE flag,
  company   LIKE /psyng/sw_uinfo-company,
  department LIKE /psyng/sw_uinfo-department,
  bname     LIKE usr02-bname,
  name_text LIKE /psyng/sw_uinfo-name_text,
  class     LIKE usr02-class,
  sysclient LIKE /psyng/sw_cntca-sysclient,
  swaudid   LIKE /psyng/swaudhdr-swaudid,
  condesc   LIKE /psyng/swaudhdr-description,
  imp       LIKE /psyng/swaudhdr-imp,
  impsort   TYPE i,
  origin    like /psyng/conflict-contid, "LOCAL/REMOTE/CROSS
  contid    LIKE /psyng/conflict-contid,
  END OF gt_caoutput.
DATA : BEGIN OF gt_ctoutput OCCURS 0,
  sel       TYPE flag,
  company   LIKE /psyng/sw_uinfo-company,
  department LIKE /psyng/sw_uinfo-department,
  bname     LIKE usr02-bname,
  name_text LIKE /psyng/sw_uinfo-name_text,
  class     LIKE usr02-class,
  sysclient LIKE /psyng/sw_cntca-sysclient,
  tcode     LIKE tstct-tcode,
  condesc   LIKE /psyng/swaudhdr-description,
  imp       LIKE /psyng/swaudhdr-imp,
  impsort   TYPE i,
  origin    like /psyng/conflict-contid, "LOCAL/REMOTE/CROSS
  END OF gt_ctoutput,
  g_current_user TYPE sy-uname. "C0700


*---Remote Block
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) rem_but
  USER-COMMAND rem_but .
SELECTION-SCREEN COMMENT 16(50) text-b02 .
SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest  MODIF ID rem.

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


SELECTION-SCREEN: END OF BLOCK rem_o.


*---User Block
SELECTION-SCREEN: BEGIN OF BLOCK user_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) user_but USER-COMMAND user_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .

SELECT-OPTIONS: userlist FOR /psyng/sw_uinfo-bname MODIF ID usr,
                pclass   FOR /psyng/sw_uinfo-class MODIF ID usr,
                s_comp   FOR /psyng/sw_uinfo-company     MODIF ID usr,
                s_depart FOR /psyng/sw_uinfo-department  MODIF ID usr.
*                s_cuid   FOR  /psyng/sw_uinfo-central_uid
*                                                   MODIF ID usr.

PARAMETERS: validusr AS CHECKBOX DEFAULT ' '       MODIF ID usr.
SELECTION-SCREEN: END OF BLOCK user_o.



*  ---Conflict Block
SELECTION-SCREEN: BEGIN OF BLOCK con_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) con_but USER-COMMAND con_but.
SELECTION-SCREEN COMMENT 16(50) text-b03.

*--Analysis types
PARAMETERS :
  sod TYPE flag RADIOBUTTON GROUP at DEFAULT 'X'
                USER-COMMAND      at MODIF ID con,
  p_aa  TYPE flag RADIOBUTTON GROUP at MODIF ID con,
  p_ct  TYPE flag RADIOBUTTON GROUP at MODIF ID con.
SELECTION-SCREEN : SKIP 1.
SELECT-OPTIONS:
*--SOD Analysos options
   sa_confs   FOR /psyng/conflict-conid    MODIF ID cos,
   sa_pappa   FOR /psyng/busarea-busarea   MODIF ID cos,
   sa_proca   FOR /psyng/bus_proce-subarea MODIF ID cos,
   sa_owner  FOR /psyng/conflict-owner     MODIF ID cos,
   sa_csens   FOR /psyng/conflict-imp      MODIF ID cos,
   sa_risk    FOR /psyng/conflict-risk     MODIF ID cos,
   sa_mit  FOR /psyng/conflict-contid      MODIF ID cos.
*--CA analysis Options
SELECT-OPTIONS :
    ca_audid FOR /psyng/swaudhdr-swaudid  MODIF ID coa,
    ca_barea FOR /psyng/swaudhdr-busarea  MODIF ID coa,
    ca_owner FOR /psyng/swaudhdr-owner    MODIF ID coa,
    ca_imp   FOR /psyng/swaudhdr-imp      MODIF ID coa.
*--Critical Tcode analysis Options
SELECT-OPTIONS :
    ta_tcode  FOR /psyng/critcodes-tcode   MODIF ID cot,
    ta_busar  FOR /psyng/critcodes-busarea MODIF ID cot,
    ta_owner  FOR /psyng/critcodes-owner   MODIF ID cot,
    ta_imp    FOR /psyng/critcodes-imp     MODIF ID cot.

*  Version selection
PARAMETERS:      sodvrsio LIKE /psyng/conflict-vrsio
MEMORY ID /psyng/vrsio                  MODIF ID con.
PARAMETERS:      xmc TYPE flag AS CHECKBOX MODIF ID con.

SELECTION-SCREEN: END OF BLOCK con_o.





INITIALIZATION.
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700
  PERFORM set_button_icons.
  PERFORM exelog.
  PERFORM get_initial_config.
  g_program = sy-repid.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR xusrrfc-low.
  PERFORM f4_system USING 'XUSRRFC-LOW' CHANGING xusrrfc-low .
AT SELECTION-SCREEN ON VALUE-REQUEST FOR xusrrfc-high.
  PERFORM f4_system USING 'XUSRRFC-HIGH' CHANGING xusrrfc-high .

AT SELECTION-SCREEN OUTPUT.

  PERFORM handle_button.
  PERFORM handle_sections.
  PERFORM handle_analysis_option.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN '001'.
        AUTHORITY-CHECK OBJECT 'S_BTCH_ADM'
        ID 'BTCADMIN' FIELD 'Y'.
        IF sy-subrc <> 0.
          screen-invisible = '1'.
          MODIFY SCREEN.
        ENDIF.
    ENDCASE.
    IF  screen-name CS 'S_CUID'.
      IF gf_central_uid = 'X'.
        screen-active    = 1.
      ELSE.
        screen-active    = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.


AT SELECTION-SCREEN.
  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.


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
  IF g_exit_proc = 'Y'.

*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_119
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.
  EXELOG sy-repid ''.
*--Select users to analyze
  CALL FUNCTION '/PSYNG/SW_116'
       EXPORTING
            i_validuser   = validusr
            i_vrsio       = sodvrsio
       TABLES
            it_users      = userlist
            it_usergroup  = pclass
            it_company    = s_comp
            it_department = s_depart
            it_systems    = xusrrfc
            et_user_range = gt_user_range
            et_cntuse     = gt_cntuse.

*--Start analysis
  CASE 'X'.
    WHEN sod.
*--SOD Analysis
      PERFORM sod_analysis.
    WHEN p_aa.
*--Critical Authorization Analysis
      PERFORM ca_analysis.
    WHEN p_ct.
*--Critical Transaction Analysis
      PERFORM ct_analysis.

  ENDCASE.

*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'USER_BUT' 'X' CHANGING user_but .
  PERFORM init_but USING 'CON_BUT'  'X' CHANGING con_but .
  PERFORM init_but USING 'REM_BUT'  'X' CHANGING rem_but .

  PERFORM handle_sections.
ENDFORM.                    " set_button_icons

*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USER_BUT  text
*      <--P_'USER_BUT'  text
*      <--P_'X'  text
*----------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE /psyng/usr_displ,
         l_exp TYPE flag.
  SELECT SINGLE * INTO ls_state
  FROM /psyng/usr_displ
  WHERE
    bname = g_current_user AND "sy-uname AND C0700
    repid = sy-repid AND
    button_name = i_name.
  IF sy-subrc = 0.
    l_exp = ls_state-expanded.
  ELSE.
    l_exp = i_default_expanded.
  ENDIF.

  IF l_exp = 'X'.
    PERFORM expand CHANGING i_button.
  ELSE.
    PERFORM collapse CHANGING i_button.
  ENDIF.

ENDFORM.                    " init_but



*---------------------------------------------------------------------*
*       FORM toggle                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*---------------------------------------------------------------------*
FORM toggle USING i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM expand CHANGING button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*      text   =  text-b01
*      info   = text-x02
      name   = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result = button
*BOC:HBHALLA (03/12/24)
       EXCEPTIONS
            ICON_NOT_FOUND = 1
            OUTPUTFIELD_TOO_SHORT = 2
            OTHERS     = 3.
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw)
               WITH 'Icon name unknown to system'.
            WHEN 2.
               MESSAGE s002(/psyng/sw)
            WITH 'Length of field (RESULT) is too small'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)
ENDFORM.                    " expand
*&---------------------------------------------------------------------*
*&      Form  collapse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REM_BUT  text
*----------------------------------------------------------------------*
FORM collapse CHANGING    button.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*      text   =  text-b01
*      info   = text-x01
      name   = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result = button
*BOC:HBHALLA (03/12/24)
       EXCEPTIONS
            ICON_NOT_FOUND = 1
            OUTPUTFIELD_TOO_SHORT = 2
            OTHERS     = 3.
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw)
               WITH 'Icon name unknown to system'.
            WHEN 2.
               MESSAGE s002(/psyng/sw)
            WITH 'Length of field (RESULT) is too small'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)

ENDFORM.                    " collapse
*&---------------------------------------------------------------------*
*&      Form  handle_button
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_button.
  CASE g_ucomm.
    WHEN 'USER_BUT'.
      PERFORM toggle USING user_but 'USER_BUT'.
    WHEN 'CON_BUT'.
      PERFORM toggle USING con_but 'CON_BUT'.
    WHEN 'REM_BUT'.
      PERFORM toggle USING rem_but 'REM_BUT'.
  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.                    " handle_button
*---------------------------------------------------------------------*
*       FORM toggle_section                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME                                                *
*---------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.
  DATA : l_collapse TYPE flag,
         l_pattern TYPE string.
  CONCATENATE i_section_name '*' INTO l_pattern.
  LOOP AT SCREEN .
    IF screen-group1 CP l_pattern.
      IF i_button(3) <> '@3T'.
        screen-invisible = 1.
        screen-active    = 0.
        l_collapse = 'X'.
      ELSE.
        screen-invisible = 0.
        screen-active    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " toggle_section
*&---------------------------------------------------------------------*
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  user_but 'USR'.
  PERFORM handle_section USING  con_but  'CO'.
  PERFORM handle_section USING  rem_but  'REM'.


ENDFORM.                    " handle_sections

*---------------------------------------------------------------------*
*       FORM exelog                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.


ENDFORM.                    " exelog


*---------------------------------------------------------------------*
*       FORM get_initial_config                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_initial_config.
*--Set default SOD live dates

  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = sodvrsio.

  DATA: swconfig TYPE /psyng/swconfig,
        l_tabname  TYPE dd02l-tabname.


*Valid & Dialog Users only
  CLEAR swconfig.
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR swconfig.

*Show Mitigated Conflicts
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.

  IF swconfig-value = 'Y'.
    xmc = 'X'.
  ELSEIF swconfig-value = 'N'.
    xmc = ' '.
  ENDIF.
  CLEAR swconfig.

*--Central User ID search Help
*--Check what FM is configured for Central Userid information
  DATA : ls_fmname TYPE rs38l_fnam.
  se_config_param 'SW_CENTRAL_USR_FM' swconfig-value.

  IF not swconfig-value is initial.
    ls_fmname = swconfig-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
         EXPORTING
              funcname           = ls_fmname
         EXCEPTIONS
              function_not_exist = 1
              OTHERS             = 2.
    IF sy-subrc = 0.
      gf_central_uid = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " get_initial_config


*---------------------------------------------------------------------*
*       FORM handle_analysis_option                                   *
*---------------------------------------------------------------------*
*       Show/hide appropriate selection criteria based on analysis type
*---------------------------------------------------------------------*
FORM handle_analysis_option.
  LOOP AT SCREEN .
*--SOD Analysis
    IF screen-group1 = 'COS'.
      IF sod <> 'X'.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
*--Auth Analysis
    IF screen-group1 = 'COA'.
      IF p_aa <> 'X'.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
*--Tcode Analysis
    IF screen-group1 = 'COT'.
      IF p_ct <> 'X'.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    if screen-name = 'P_CROSS' and sod <> 'X'.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
     endif.
  ENDLOOP.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM sod_analysis.
  DATA :
  lt_fieldcat     TYPE slis_t_fieldcat_alv,
  lt_sort         TYPE STANDARD TABLE OF slis_sortinfo_alv,
  alv_layout      TYPE slis_layout_alv,
  alv_grid_titl   TYPE lvc_title,
  ls_variant      TYPE disvariant.
  CALL FUNCTION '/PSYNG/SW_112'
       EXPORTING
            i_validuser      = validusr
            i_vrsio          = sodvrsio
            i_details        = 'X'
            if_local         = p_local
            if_remote        = p_remote
            if_cross         = p_cross
       IMPORTING
            e_users_analyzed = g_analyzed_users
       TABLES
            it_conid         = sa_confs
            it_owner         = sa_owner
            it_imp           = sa_csens
            it_risk          = sa_risk
            it_contid        = sa_mit
            it_systems       = xusrrfc
            et_output        = gt_output_sod
            it_users         = gt_user_range
            it_busarea       = sa_pappa
            it_procarea      = sa_proca
            it_cntuse        = gt_cntuse.

  LOOP AT gt_output_sod.
    MOVE-CORRESPONDING gt_output_sod TO gt_sodoutput.
    CASE gt_output_sod-imp.
      WHEN 'LOW'.
        gt_sodoutput-impsort = 4.
      WHEN 'MEDIUM'.
        gt_sodoutput-impsort = 3.
      WHEN 'HIGH'.
        gt_sodoutput-impsort = 2.
      WHEN 'CRITICAL'.
        gt_sodoutput-impsort = 1.
    ENDCASE.
    case gt_output_sod-origin.
      when '1'.
        gt_sodoutput-origin = 'Local'(o01).
      when '2'.
        gt_sodoutput-origin = 'Remote'(o02).
      when '3'.
        gt_sodoutput-origin = 'Cross'(o03).

    endcase.
    APPEND gt_sodoutput.
  ENDLOOP.
  FREE : gt_output_sod.


  PERFORM create_alv_fieldcat_sod TABLES  lt_fieldcat lt_sort.
  CONCATENATE 'Central SOD Analysis - Version'(t01)
              sodvrsio
  INTO sy-title SEPARATED BY space.
  alv_layout-box_fieldname = 'SEL'.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
            i_grid_title             = alv_grid_titl
            i_callback_program       = g_program
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            it_sort                  = lt_sort
            i_callback_user_command  = 'SOD_DRILLDOWN'
            is_layout                = alv_layout
            it_fieldcat              = lt_fieldcat[]
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_sodoutput
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " sod_analysis

*---------------------------------------------------------------------*
*       FORM CONFLICT_DRILLDOWN                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_UCOMM                                                       *
*  -->  IS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM sod_drilldown USING i_ucomm LIKE sy-ucomm
                              is_selfield TYPE slis_selfield.
 DATA : lt_destinations TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_systems      TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
           lt_params       TYPE rsparams OCCURS 0 WITH HEADER LINE,
           l_local_sys     LIKE lt_destinations-rfcname,
           lf_rem_only     TYPE flag.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CASE is_selfield-fieldname.
    WHEN 'CONID'.
      READ TABLE gt_sodoutput INDEX is_selfield-tabindex.

*--Get systems
      SELECT DISTINCT  sysclient AS rfcname  FROM /psyng/sw_cntfun
      INTO CORRESPONDING FIELDS OF TABLE lt_systems
      WHERE sysclient IN xusrrfc.
*--Get destinations
      CHECK NOT lt_systems[] IS INITIAL.

      SELECT * FROM /psyng/sw_rfcdes      "#EC CI_NO_TRANSFORM
      INTO TABLE lt_destinations
      FOR ALL ENTRIES IN lt_systems WHERE
      rfcname = lt_systems-rfcname.

*--Fill selection screen
      lf_rem_only = 'X'.
*--Check if local system is included
      READ TABLE lt_systems WITH KEY rfcname =  l_local_sys.
      IF sy-subrc = 0.
        CLEAR lf_rem_only.
      ENDIF.


      lt_params-selname = 'SHODET'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.

      lt_params-selname = 'SHOSUM'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = ' '.
      APPEND lt_params.

      lt_params-selname = 'SHOTREE'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = ' '.
      APPEND lt_params.

      lt_params-selname = 'P_LOCAL'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.

      lt_params-selname = 'P_REMOTE'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.

      lt_params-selname = 'P_CROSS'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.



      lt_params-selname = 'VALIDUSR'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = validusr.
      APPEND lt_params.

      lt_params-selname = 'XMC'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = xmc.
      APPEND lt_params.


      lt_params-selname = 'SODVRSIO'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = sodvrsio.
      APPEND lt_params.

      lt_params-selname = 'SPCONFS'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_sodoutput-conid.
      APPEND lt_params.

      lt_params-selname = 'USERLIST'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_sodoutput-bname.
      APPEND lt_params.



      LOOP AT lt_destinations.
        lt_params-selname = 'XUSRRFC'.
        lt_params-kind = 'P'.
        lt_params-sign = 'I'.
        lt_params-option = 'EQ'.
        lt_params-low = lt_destinations-rfcdest.
        APPEND lt_params.
      ENDLOOP.
      lt_params-selname = 'P_REMONLY'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = lf_rem_only.
      APPEND lt_params.

      SUBMIT /psyng/sodreport_sys_wide_org
      WITH SELECTION-TABLE lt_params AND RETURN.


  ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM ca_drilldown                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_UCOMM                                                       *
*  -->  IS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM ca_drilldown USING i_ucomm LIKE sy-ucomm
                              is_selfield TYPE slis_selfield.
 DATA : lt_destinations TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_systems      TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
           lt_params       TYPE rsparams OCCURS 0 WITH HEADER LINE,
           l_local_sys     LIKE lt_destinations-rfcname,
           lf_rem_only     TYPE flag.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CASE is_selfield-fieldname.
    WHEN 'SWAUDID'.
      READ TABLE gt_caoutput INDEX is_selfield-tabindex.

*--Get system
      SELECT DISTINCT  sysclient AS rfcname  FROM /psyng/sw_cntca
      INTO CORRESPONDING FIELDS OF TABLE lt_systems
      WHERE sysclient = gt_caoutput-sysclient.
*--Get destinations
      CHECK NOT lt_systems[] IS INITIAL.

      SELECT * FROM /psyng/sw_rfcdes     "#EC CI_NO_TRANSFORM
      INTO TABLE lt_destinations
      FOR ALL ENTRIES IN lt_systems WHERE
      rfcname = lt_systems-rfcname.
*--Fill selection screen
      lf_rem_only = 'X'.
*--Check if local system is included
      READ TABLE lt_systems WITH KEY rfcname =  l_local_sys.
      IF sy-subrc = 0.
        CLEAR lf_rem_only.
      ENDIF.
      lt_params-selname = 'DET'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.

      lt_params-selname = 'SUM'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = ' '.
      APPEND lt_params.

      lt_params-selname = 'VALIDUSR'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = validusr.
      APPEND lt_params.

      lt_params-selname = 'XMC'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = xmc.
      APPEND lt_params.


      lt_params-selname = 'SODVRSIO'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = sodvrsio.
      APPEND lt_params.

      lt_params-selname = 'PAUDID'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_caoutput-swaudid.
      APPEND lt_params.

      lt_params-selname = 'PBNAME'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_caoutput-bname.
      APPEND lt_params.

      LOOP AT lt_destinations.
        IF l_local_sys <> lt_destinations-rfcname.
          lt_params-selname = 'REMRFC'.
          lt_params-kind = 'P'.
          lt_params-sign = 'I'.
          lt_params-option = 'EQ'.
          lt_params-low = lt_destinations-rfcdest.
          APPEND lt_params.
        ENDIF.
      ENDLOOP.

      lt_params-selname = 'ONLYREM'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = lf_rem_only.
      APPEND lt_params.


      SUBMIT /psyng/sw_crit_auths
      WITH SELECTION-TABLE lt_params AND RETURN.


  ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM ct_drilldown                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_UCOMM                                                       *
*  -->  IS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM ct_drilldown USING i_ucomm LIKE sy-ucomm
                              is_selfield TYPE slis_selfield.
 DATA : lt_destinations TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_systems      TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
           lt_params       TYPE rsparams OCCURS 0 WITH HEADER LINE,
           l_local_sys     LIKE lt_destinations-rfcname,
           lf_rem_only     TYPE flag.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE gt_ctoutput INDEX is_selfield-tabindex.

*--Get system
      SELECT DISTINCT  sysclient AS rfcname  FROM /psyng/sw_cntca
      INTO CORRESPONDING FIELDS OF TABLE lt_systems
      WHERE sysclient = gt_ctoutput-sysclient.
*--Get destinations
      CHECK NOT lt_systems[] IS INITIAL.

      SELECT * FROM /psyng/sw_rfcdes     "#EC CI_NO_TRANSFORM
      INTO TABLE lt_destinations
      FOR ALL ENTRIES IN lt_systems WHERE
      rfcname = lt_systems-rfcname.
*--Fill selection screen
      lf_rem_only = 'X'.
*--Check if local system is included
      READ TABLE lt_systems WITH KEY rfcname =  l_local_sys.
      IF sy-subrc = 0.
        CLEAR lf_rem_only.
      ENDIF.
      lt_params-selname = 'ALVDET'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = 'X'.
      APPEND lt_params.

      lt_params-selname = 'ALVSUM'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = ' '.
      APPEND lt_params.

      lt_params-selname = 'VALIDUSR'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = validusr.
      APPEND lt_params.

      lt_params-selname = 'XMC'. lt_params-kind = 'P'.
      lt_params-sign = 'I'. lt_params-option = 'EQ'.
      lt_params-low = xmc.
      APPEND lt_params.


      lt_params-selname = 'SODVRSIO'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = sodvrsio.
      APPEND lt_params.

      lt_params-selname = 'TCODES'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_ctoutput-tcode.
      APPEND lt_params.

      lt_params-selname = 'UID'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = gt_ctoutput-bname.
      APPEND lt_params.

      LOOP AT lt_destinations.
        IF l_local_sys <> lt_destinations-rfcname.
          lt_params-selname = 'REMRFC'.
          lt_params-kind = 'P'.
          lt_params-sign = 'I'.
          lt_params-option = 'EQ'.
          lt_params-low = lt_destinations-rfcdest.
          APPEND lt_params.
        ENDIF.
      ENDLOOP.

      lt_params-selname = 'REMOTE'.
      lt_params-kind = 'P'.
      lt_params-sign = 'I'.
      lt_params-option = 'EQ'.
      lt_params-low = lf_rem_only.
      APPEND lt_params.


      SUBMIT /psyng/cri_tcode_list
      WITH SELECTION-TABLE lt_params AND RETURN.


  ENDCASE.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  create_alv_fieldcat_sod
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FIELDCAT  text
*      -->P_LT_SORT  text
*----------------------------------------------------------------------*
FORM create_alv_fieldcat_sod
TABLES   et_fieldcat TYPE slis_t_fieldcat_alv
         et_sort     TYPE slis_t_sortinfo_alv.
  DATA : ls_fcat TYPE slis_fieldcat_alv,
         ls_sort TYPE slis_sortinfo_alv.
  REFRESH : et_fieldcat, et_sort.
  g_program = sy-repid.
*--Load Field Catalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_SODOUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = et_fieldcat[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Hide impsort field
  ls_fcat-fieldname = 'IMPSORT'.
  ls_fcat-no_out    = 'X'.
  MODIFY et_fieldcat
   FROM ls_fcat
   TRANSPORTING no_out
   WHERE fieldname = ls_fcat-fieldname.
*--Hide mitigation field if not requested
  IF xmc <> 'X'.
    ls_fcat-fieldname = 'CONTID'.
    ls_fcat-no_out    = 'X'.
    MODIFY et_fieldcat
     FROM ls_fcat
     TRANSPORTING no_out
     WHERE fieldname = ls_fcat-fieldname.
  ENDIF.

*--Correct label for department field
  ls_fcat-seltext_m    = 'Department'(a01).
  ls_fcat-seltext_s    = 'Department'(a01).
  ls_fcat-reptext_ddic = 'Department'(a01).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.
*--Correct label for origin field
  ls_fcat-seltext_m    = 'Origin'(a03).
  ls_fcat-seltext_s    = 'Origin'(a03).
  ls_fcat-reptext_ddic = 'Origin'(a03).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ORIGIN'.
*--Hotspots
  ls_fcat-hotspot    = 'X'.
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.


*--Create Sort Table
  ls_sort-tabname   = 'GT_SODOUTPUT'.
  ls_sort-up        = 'X'.
  ls_sort-spos      = '0'.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CLASS'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'COMPANY'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'DEPARTMENT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'NAME_TEXT'.
  APPEND ls_sort TO et_sort.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMPSORT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMP'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONID'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONTID'.
  APPEND ls_sort TO et_sort.





ENDFORM.                    " create_alv_fieldcat_sod
*&---------------------------------------------------------------------*
*&      Form  ca_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ca_analysis.
  DATA :
  lt_fieldcat     TYPE slis_t_fieldcat_alv,
  lt_sort         TYPE STANDARD TABLE OF slis_sortinfo_alv,
  alv_layout      TYPE slis_layout_alv,
  alv_grid_titl   TYPE lvc_title,
  ls_variant      TYPE disvariant.

  CALL FUNCTION '/PSYNG/SW_117'
       EXPORTING
            i_validuser      = validusr
            i_vrsio          = sodvrsio
            i_details        = 'X'
            i_show_mitigated = xmc
            if_local         = p_local
            if_remote        = p_remote
       IMPORTING
            e_users_analyzed = g_analyzed_users
       TABLES
            it_swaudid       = ca_audid
            it_owner         = ca_owner
            it_imp           = ca_imp
            it_systems       = xusrrfc
            et_output        = gt_output_ca
            it_users         = gt_user_range
            it_busarea       = ca_barea
            it_cntuse        = gt_cntuse.


  LOOP AT gt_output_ca.
    MOVE-CORRESPONDING gt_output_ca TO gt_caoutput.
    gt_caoutput-swaudid   = gt_output_ca-conid.
    gt_caoutput-sysclient = gt_output_ca-rfcdest."#EC SAST_CI_GEN_CHECK
    CASE gt_output_ca-imp.
      WHEN 'LOW'.
        gt_caoutput-impsort = 4.
      WHEN 'MEDIUM'.
        gt_caoutput-impsort = 3.
      WHEN 'HIGH'.
        gt_caoutput-impsort = 2.
      WHEN 'CRITICAL'.
        gt_caoutput-impsort = 1.
    ENDCASE.
    case gt_output_ca-origin.
      when '1'.
        gt_caoutput-origin = 'Local'(o01).
      when '2'.
        gt_caoutput-origin = 'Remote'(o02).
    endcase.

    APPEND gt_caoutput.
  ENDLOOP.
  FREE : gt_output_ca.



  PERFORM create_alv_fieldcat_ca TABLES  lt_fieldcat lt_sort.
  CONCATENATE 'Central Critical Authorization Analysis - Version'(t02)
              sodvrsio
  INTO sy-title SEPARATED BY space.
  alv_layout-box_fieldname = 'SEL'.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
            i_grid_title             = alv_grid_titl
            i_callback_program       = g_program
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            it_sort                  = lt_sort
            i_callback_user_command  = 'CA_DRILLDOWN'
            is_layout                = alv_layout
            it_fieldcat              = lt_fieldcat[]
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_caoutput
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " ca_analysis


*&---------------------------------------------------------------------*
*&      Form  create_alv_fieldcat_sod
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_FIELDCAT  text
*      -->P_LT_SORT  text
*----------------------------------------------------------------------*
FORM create_alv_fieldcat_ca
TABLES   et_fieldcat TYPE slis_t_fieldcat_alv
         et_sort     TYPE slis_t_sortinfo_alv.
  DATA : ls_fcat TYPE slis_fieldcat_alv,
         ls_sort TYPE slis_sortinfo_alv.
  REFRESH : et_fieldcat, et_sort.
  g_program = sy-repid.
*--Load Field Catalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_CAOUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = et_fieldcat[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Hide impsort field
  ls_fcat-fieldname = 'IMPSORT'.
  ls_fcat-no_out    = 'X'.
  MODIFY et_fieldcat
   FROM ls_fcat
   TRANSPORTING no_out
   WHERE fieldname = ls_fcat-fieldname.
*--Hide mitigation field if not requested
  IF xmc <> 'X'.
    ls_fcat-fieldname = 'CONTID'.
    ls_fcat-no_out    = 'X'.
    MODIFY et_fieldcat
     FROM ls_fcat
     TRANSPORTING no_out
     WHERE fieldname = ls_fcat-fieldname.
  ENDIF.

*--Correct label for department field
  ls_fcat-seltext_m    = 'Department'(a01).
  ls_fcat-seltext_s    = 'Department'(a01).
  ls_fcat-reptext_ddic = 'Department'(a01).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.
*--Correct label for origin field
  ls_fcat-seltext_m    = 'Origin'(a03).
  ls_fcat-seltext_s    = 'Origin'(a03).
  ls_fcat-reptext_ddic = 'Origin'(a03).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ORIGIN'.

*--Correct label for System field
  ls_fcat-seltext_m    = 'Source System'(a02).
  ls_fcat-seltext_s    = 'Source System'(a02).
  ls_fcat-reptext_ddic = 'Source System'(a02).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SYSCLIENT'.


*--Hotspots
  ls_fcat-hotspot    = 'X'.
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'SWAUDID'.


*--Create Sort Table
  ls_sort-tabname   = 'GT_CAOUTPUT'.
  ls_sort-up        = 'X'.
  ls_sort-spos      = '0'.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CLASS'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'COMPANY'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'DEPARTMENT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO et_sort.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'NAME_TEXT'.
  APPEND ls_sort TO et_sort.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMPSORT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMP'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'SYSCLIENT'.
  APPEND ls_sort TO et_sort.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'SWAUDID'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CONTID'.
  APPEND ls_sort TO et_sort.



ENDFORM.                    " create_alv_fieldcat_sod
*&---------------------------------------------------------------------*
*&      Form  ct_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM ct_analysis.
  DATA :
  lt_fieldcat     TYPE slis_t_fieldcat_alv,
  lt_sort         TYPE STANDARD TABLE OF slis_sortinfo_alv,
  alv_layout      TYPE slis_layout_alv,
  alv_grid_titl   TYPE lvc_title,
  ls_variant      TYPE disvariant.

  CALL FUNCTION '/PSYNG/SW_118'
       EXPORTING
            i_validuser      = validusr
            i_vrsio          = sodvrsio
            i_details        = 'X'
            if_local         = p_local
            if_remote        = p_remote
       IMPORTING
            e_users_analyzed = g_analyzed_users
       TABLES
            it_tcode         = ta_tcode
            it_owner         = ta_owner
            it_imp           = ta_imp
            it_systems       = xusrrfc
            et_output        = gt_output_ct
            it_users         = gt_user_range
            it_busarea       = ta_busar
            it_cntuse        = gt_cntuse.


  LOOP AT gt_output_ct.
    MOVE-CORRESPONDING gt_output_ct TO gt_ctoutput.
    gt_ctoutput-tcode     = gt_output_ct-conid.
   gt_ctoutput-sysclient = gt_output_ct-rfcdest."#EC SAST_CI_GEN_CHECK
    CASE gt_output_ct-imp.
      WHEN 'LOW'.
        gt_ctoutput-impsort = 4.
      WHEN 'MEDIUM'.
        gt_ctoutput-impsort = 3.
      WHEN 'HIGH'.
        gt_ctoutput-impsort = 2.
      WHEN 'CRITICAL'.
        gt_ctoutput-impsort = 1.
    ENDCASE.
    case gt_output_ct-origin.
      when '1'.
        gt_ctoutput-origin = 'Local'(o01).
      when '2'.
        gt_ctoutput-origin = 'Remote'(o02).
    endcase.

    APPEND gt_ctoutput.
  ENDLOOP.
  FREE : gt_output_ct.



  PERFORM create_alv_fieldcat_ct TABLES  lt_fieldcat lt_sort.
  CONCATENATE 'Central Critical Transaction Analysis - Version'(t03)
              sodvrsio
  INTO sy-title SEPARATED BY space.
  alv_layout-box_fieldname = 'SEL'.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_callback_top_of_page   = 'USER-TOP-OF-PAGE'
            i_grid_title             = alv_grid_titl
            i_callback_program       = g_program
*            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            it_sort                  = lt_sort
            i_callback_user_command  = 'CT_DRILLDOWN'
            is_layout                = alv_layout
            it_fieldcat              = lt_fieldcat[]
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_ctoutput
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " ct_analysis


*---------------------------------------------------------------------*
*       FORM create_alv_fieldcat_ct                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_FIELDCAT                                                   *
*  -->  ET_SORT                                                       *
*---------------------------------------------------------------------*
FORM create_alv_fieldcat_ct
TABLES   et_fieldcat TYPE slis_t_fieldcat_alv
         et_sort     TYPE slis_t_sortinfo_alv.
  DATA : ls_fcat TYPE slis_fieldcat_alv,
         ls_sort TYPE slis_sortinfo_alv.
  REFRESH : et_fieldcat, et_sort.
  g_program = sy-repid.
*--Load Field Catalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_CTOUTPUT'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = et_fieldcat[]
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Hide impsort field
  ls_fcat-fieldname = 'IMPSORT'.
  ls_fcat-no_out    = 'X'.
  MODIFY et_fieldcat
   FROM ls_fcat
   TRANSPORTING no_out
   WHERE fieldname = ls_fcat-fieldname.

*--Correct label for department field
  ls_fcat-seltext_m    = 'Department'(a01).
  ls_fcat-seltext_s    = 'Department'(a01).
  ls_fcat-reptext_ddic = 'Department'(a01).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.
*--Correct label for origin field
  ls_fcat-seltext_m    = 'Origin'(a03).
  ls_fcat-seltext_s    = 'Origin'(a03).
  ls_fcat-reptext_ddic = 'Origin'(a03).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ORIGIN'.

*--Correct label for System field
  ls_fcat-seltext_m    = 'Source System'(a02).
  ls_fcat-seltext_s    = 'Source System'(a02).
  ls_fcat-reptext_ddic = 'Source System'(a02).
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SYSCLIENT'.

*--Hotspots
  ls_fcat-hotspot    = 'X'.
  MODIFY et_fieldcat FROM ls_fcat
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.


*--Create Sort Table
  ls_sort-tabname   = 'GT_CTOUTPUT'.
  ls_sort-up        = 'X'.
  ls_sort-spos      = '0'.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'CLASS'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'COMPANY'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'DEPARTMENT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO et_sort.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'NAME_TEXT'.
  APPEND ls_sort TO et_sort.



  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMPSORT'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'IMP'.
  APPEND ls_sort TO et_sort.

  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'SYSCLIENT'.
  APPEND ls_sort TO et_sort.


  ADD 1 TO ls_sort-spos.
  ls_sort-fieldname = 'TCODE'.
  APPEND ls_sort TO et_sort.



ENDFORM.                    " create_alv_fieldcat_sod
*&---------------------------------------------------------------------*
*&      Form  f4_system
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0640   text
*      <--P_S_COMP_HIGH  text
*----------------------------------------------------------------------*
form f4_system using    i_sys
               changing e_xusrrfc.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values,
        lt_fields TYPE TABLE OF dfies      WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        l_sys LIKE LINE OF xusrrfc,
        lt_systs type table of /PSYNG/SW_RFCDES with header line.



    lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
    lt_fields-fieldname = 'RFCNAME'.
    APPEND lt_fields.
    lt_fields-tabname   = '/PSYNG/SW_RFCDES'.
    lt_fields-fieldname = 'DESCRIPTION'.
    APPEND lt_fields.


    select distinct
    sysclient as rfcname  "#EC SAST_CI_GEN_CHECK
    description
    from /PSYNG/SW_CNTUSE inner join /PSYNG/SW_RFCDES on
    /PSYNG/SW_CNTUSE~sysclient = /PSYNG/SW_RFCDES~rfcname
    into corresponding fields of table lt_systs.

    loop at lt_systs.
      lt_values-line = lt_systs-rfcname.
      append lt_values.
      lt_values-line = lt_systs-description.
      append lt_values.
    endloop.

    CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
         EXPORTING
              retfield        = 'RFCNAME'
              value           = i_sys
              multiple_choice = 'X'

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
    IF sy-subrc = 0 AND NOT lt_return[] IS INITIAL.
*      READ TABLE lt_return INDEX 1.
*      e_xusrrfc = lt_return-fieldval.
     LOOP AT lt_return WHERE fieldname = 'RFCNAME'.
      l_sys-sign = 'I'.
      l_sys-option = 'EQ'.
      l_sys-low = lt_return-fieldval.
      IF sy-tabix = 1.
        xusrrfc = l_sys.
      ENDIF.
      APPEND l_sys TO xusrrfc.
    ENDLOOP.
*--delete duplicates
    SORT xusrrfc.
    DELETE ADJACENT DUPLICATES FROM xusrrfc.
*--Get all the fields of the selection screen and submit the report
*  to present the pushbutton "Multiple selection" with green light on
*  the selection screen
    PERFORM fill_sel_screen_fields_to_tab.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program)
*    SUBMIT /PSYNG/SW_119
*EOC UMITTAL SE VF scan changes-25/11/2024
      WITH SELECTION-TABLE gt_irsparams
    VIA SELECTION-SCREEN. "#EC PATHLOCK_CI_DYN_ACCES



    ENDIF.
endform.                    " f4_system

FORM fill_sel_screen_fields_to_tab.
  REFRESH : gt_irsparams.
*Select options
  LOOP AT xusrrfc.
    gt_irsparams-selname = 'XUSRRFC'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING XUSRRFC TO gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT USERLIST.
    gt_irsparams-selname = 'USERLIST'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING USERLIST TO gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT PCLASS.
    gt_irsparams-selname = 'PCLASS'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING PCLASS TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


  LOOP AT S_COMP.
    gt_irsparams-selname = 'S_COMP'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING S_COMP TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


    LOOP AT S_DEPART.
    gt_irsparams-selname = 'S_DEPART'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING S_DEPART TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


    LOOP AT SA_CONFS.
    gt_irsparams-selname = 'SA_CONFS'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_CONFS TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_PAPPA.
    gt_irsparams-selname = 'SA_PAPPA'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_PAPPA TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_PROCA.
    gt_irsparams-selname = 'SA_PROCA'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_PROCA TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_OWNER.
    gt_irsparams-selname = 'SA_OWNER'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_OWNER TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_CSENS.
    gt_irsparams-selname = 'SA_CSENS'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_CSENS TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_RISK.
    gt_irsparams-selname = 'SA_RISK'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_RISK TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT SA_MIT.
    gt_irsparams-selname = 'SA_MIT'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING SA_MIT TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


  LOOP AT CA_AUDID.
    gt_irsparams-selname = 'CA_AUDID'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING CA_AUDID TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT CA_BAREA.
    gt_irsparams-selname = 'CA_BAREA'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING CA_BAREA TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


  LOOP AT CA_OWNER.
    gt_irsparams-selname = 'CA_OWNER'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING CA_OWNER TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT CA_IMP.
    gt_irsparams-selname = 'CA_IMP'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING CA_IMP TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


  LOOP AT TA_TCODE.
    gt_irsparams-selname = 'TA_TCODE'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING TA_TCODE TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

 LOOP AT TA_BUSAR.
    gt_irsparams-selname = 'TA_BUSAR'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING TA_BUSAR TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.


  LOOP AT TA_OWNER.
    gt_irsparams-selname = 'TA_OWNER'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING TA_OWNER TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.

  LOOP AT TA_IMP.
    gt_irsparams-selname = 'TA_IMP'.
    gt_irsparams-kind = 'S'.
    MOVE-CORRESPONDING TA_IMP TO  gt_irsparams.
    APPEND gt_irsparams.
  ENDLOOP.








  gt_irsparams-kind    = 'P'.
  gt_irsparams-option  = 'EQ'.
  gt_irsparams-KIND    = 'I'.
  gt_irsparams-HIGH    = ''.

  gt_irsparams-selname = 'P_LOCAL'.
  gt_irsparams-low     = p_local.
  append gt_irsparams.

  gt_irsparams-selname = 'P_REMOTE'.
  gt_irsparams-low     = p_remote.
  append gt_irsparams.

  gt_irsparams-selname = 'P_CROSS'.
  gt_irsparams-low     = p_cross.
  append gt_irsparams.

  gt_irsparams-selname = 'SOD'.
  gt_irsparams-low     = SOD.
  append gt_irsparams.


  gt_irsparams-selname = 'AA'.
  gt_irsparams-low     = p_AA.
  append gt_irsparams.


  gt_irsparams-selname = 'CT'.
  gt_irsparams-low     = p_CT.
  append gt_irsparams.

  gt_irsparams-selname = 'VALIDUSR'.
  gt_irsparams-low     = VALIDUSR.
  append gt_irsparams.





endform.
