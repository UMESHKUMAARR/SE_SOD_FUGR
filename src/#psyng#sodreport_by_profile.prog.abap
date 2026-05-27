REPORT /psyng/sodreport_by_profile . "#EC SAST_CI_GEN_CHECK
INCLUDE /psyng/sw_config.
TABLES: agr_prof, /psyng/conflict.
TYPE-POOLS:slis.
CONSTANTS: gc_service  TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name TYPE xufield  VALUE 'SRV_NAME'.
DATA : BEGIN OF gt_prof_detail OCCURS 0,
         profile TYPE ust10s-profn,
         objct   TYPE ust12-objct,
         auth    TYPE ust12-auth,
         field   TYPE ust12-field,
         von     TYPE ust12-von,
         bis     TYPE  ust12-bis,
       END OF gt_prof_detail.

DATA: BEGIN OF gt_final OCCURS 0,
        profile       LIKE ust10s-profn,
        ptext         LIKE usr11-ptext,
        imp           LIKE /psyng/conflict-imp,
        conid         LIKE /psyng/conflict-conid,
        description   LIKE /psyng/conflict-description,
        risk          LIKE /psyng/conflict-risk,
        isort         TYPE i,
        enhanced      TYPE c,           "flag for enhanced ruleset
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
      END OF gt_final.

DATA: BEGIN OF gt_det_final OCCURS 0,
        agr_name      TYPE agr_define-agr_name,
        description   TYPE /psyng/conflict-description,
        conid         TYPE /psyng/conflict-conid,
        functionid    TYPE /psyng/function-function,
        tcode         TYPE /psyng/functtran-tcode,
        objct         TYPE ust10s-objct,
        org_abb       LIKE /psyng/swsodorgm-abb,
        auth          TYPE ust12-auth,
        field         TYPE agr_1251-field,
        von           TYPE agr_1251-low,
        bis           TYPE agr_1251-high,
        child_agr     TYPE agr_agrs-child_agr,
        enhanced      TYPE c, "flag for enhanced ruleset
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
      END OF gt_det_final.

DATA: BEGIN OF gt_comp_singles OCCURS 0,
        composite TYPE ust10c-profn,
        profn     TYPE ust10c-profn,
        objct     TYPE usr12-objct,
        auth      TYPE usr12-auth,
      END OF gt_comp_singles.

*DATA : lt_comp_singles_temp LIKE TABLE OF gt_comp_singles.

DATA:  BEGIN OF gt_ftcodes OCCURS 0,
         tcode LIKE sy-tcode,
       END OF gt_ftcodes.

DATA : BEGIN OF gt_analyzed_prof OCCURS 0,
         comp_prof TYPE ust10c-profn,
         profile   TYPE ust10c-profn,
         composite TYPE flag,
       END OF gt_analyzed_prof.

DATA: gt_output            TYPE TABLE OF /psyng/sw_out_routput WITH
HEADER LINE,
      gt_output_sum        TYPE TABLE OF /psyng/sw_out_routput WITH
      HEADER LINE,
      gt_proftcode         TYPE TABLE OF /psyng/usertcode WITH HEADER
      LINE,
      gt_profauth          TYPE TABLE OF agr_1251 WITH HEADER LINE,
      gt_profauth_temp     TYPE TABLE OF agr_1251 WITH HEADER LINE,
      gt_condet            TYPE TABLE OF /psyng/conflict WITH HEADER
      LINE,
      gt_proftext          TYPE TABLE OF usr11 WITH HEADER LINE,
      gt_single_profs      TYPE TABLE OF ust10s WITH HEADER LINE,
      gt_comp_profs        TYPE TABLE OF ust10c WITH HEADER LINE,
      gt_confs             TYPE TABLE OF /psyng/conflict WITH HEADER
      LINE,
      gt_roles             TYPE TABLE OF /psyng/range_agr_name WITH
      HEADER LINE,
      gt_outputdet         TYPE TABLE OF /psyng/sw_out_routdet3 WITH
      HEADER LINE,
      g_fr_low             TYPE ust12-von,
      g_to_high            TYPE ust12-von,
      g_dest               LIKE rfcdes-rfcdest,
      gt_fieldcat_alv      TYPE slis_t_fieldcat_alv,
      gt_fieldcat_det      TYPE slis_t_fieldcat_alv,
      g_ucomm              LIKE sy-ucomm,
      g_color              TYPE lvc_s_colo,
      g_dynnr              LIKE sy-dynnr,
      g_cc                 TYPE lvc_t_scol WITH HEADER LINE,
      gf_pages             TYPE i,
      g_repeat_hdr_bkgdjob TYPE flag,
      g_exit_proc,
      g_program            LIKE sy-repid,
      g_curr_variant       LIKE  rsvar-variant,
      g_variant            LIKE vari-variant,
      g_vari_desc          TYPE varid OCCURS 0 WITH HEADER LINE,
      g_vari_contents      LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      g_vari_text          LIKE varit OCCURS 0 WITH HEADER LINE,
      r_irsparams          TYPE rsparams OCCURS 0 WITH HEADER LINE,
*      g_repeat_hdr_bkgdjob TYPE flag,
*      gf_pages TYPE i,
      gf_options_set       TYPE flag,
      g_tabname            TYPE dd02l-tabname,
      g_current_user TYPE sy-uname. "C0700


*-----------------Selection Screen-------------------------------*

*--Profile Block
SELECTION-SCREEN: BEGIN OF BLOCK profile_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) prof_but USER-COMMAND prof_but.
SELECTION-SCREEN COMMENT 10(50) text-h01 .

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  63(15) text-053 USER-COMMAND verify_p
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-001 MODIF ID pro.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS: prof FOR agr_prof-profile MODIF ID pro
                MATCHCODE OBJECT prof_single_composite_active.
SELECTION-SCREEN: END OF LINE.
**Checkboxes
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : sinprof TYPE flag DEFAULT 'X' MODIF ID pro.
SELECTION-SCREEN: COMMENT 7(47) text-002 FOR FIELD sinprof
                                         MODIF ID pro.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : comprof TYPE flag DEFAULT 'X' MODIF ID pro.
SELECTION-SCREEN: COMMENT 7(47) text-003 FOR FIELD comprof
                                         MODIF ID pro.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : asign_p TYPE flag DEFAULT ' ' MODIF ID pro.
SELECTION-SCREEN: COMMENT 7(47) text-004 FOR FIELD asign_p
                                        MODIF ID pro.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK profile_o.

*--Conflict Block

SELECTION-SCREEN: BEGIN OF BLOCK con_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) con_but USER-COMMAND con_but.
SELECTION-SCREEN COMMENT 10(50) text-h02 .
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-005 MODIF ID con.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:  spconfs FOR /psyng/conflict-conid MODIF ID con.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-006 MODIF ID con.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:  sens FOR /psyng/conflict-imp MODIF ID con.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-007 MODIF ID con.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS:  s_risk FOR /psyng/conflict-risk MODIF ID con.
SELECTION-SCREEN: END OF LINE.
*  Version selection
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(24) text-008 MODIF ID con.
SELECTION-SCREEN: POSITION 28.
PARAMETERS:  sodvrsio LIKE /psyng/conflict-vrsio
MEMORY ID /psyng/vrsio MODIF ID con. "SOD Version
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK con_o.



*---Output Block
SELECTION-SCREEN: BEGIN OF BLOCK out_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) out_but USER-COMMAND out_but.
SELECTION-SCREEN COMMENT 10(50) text-h03 .

SELECTION-SCREEN: BEGIN OF BLOCK res WITH FRAME TITLE text-o05.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shosum RADIOBUTTON GROUP g6 DEFAULT 'X'
                                          MODIF ID out
                   USER-COMMAND show.  "SOD conflict
SELECTION-SCREEN: COMMENT 4(28) text-009 FOR FIELD shosum
                                          MODIF ID out.
SELECTION-SCREEN: POSITION 34.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: shodet   RADIOBUTTON GROUP g6 MODIF ID out.
SELECTION-SCREEN: COMMENT 4(50) text-010 FOR FIELD shodet
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK res.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: pcolor AS CHECKBOX DEFAULT ' ' MODIF ID out
USER-COMMAND pcolor.
SELECTION-SCREEN: COMMENT 3(30) text-011 FOR FIELD pcolor
                                         MODIF ID out.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS : shonosod TYPE flag MODIF ID out.
SELECTION-SCREEN: COMMENT 3(50) text-012 FOR FIELD shonosod
                                         MODIF ID out.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK out_o.

PARAMETERS : p_detsum TYPE flag  NO-DISPLAY DEFAULT ''.

*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 10(50) text-h04.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance MODIF ID exe.
SELECTION-SCREEN COMMENT 3(30) text-013 MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX MODIF ID exe.
SELECTION-SCREEN COMMENT 36(50) text-014 MODIF ID exe.
SELECTION-SCREEN END OF LINE.

PARAMETERS: orgchk AS CHECKBOX DEFAULT ' ' MODIF ID exe.

SELECTION-SCREEN: END OF BLOCK exe_o.

*-- Background Processing Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b07.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-031 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-032 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-033 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-034 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN: END OF BLOCK bgd_o.

**--Hidden parameters

PARAMETERS: p_first TYPE flag NO-DISPLAY.

LOAD-OF-PROGRAM.
  p_first = 'X'.
*------------------------Initialization----------------------------*
INITIALIZATION.
  PERFORM set_button_icons.
  PERFORM exelog.
  PERFORM get_initial_config.
  g_program = sy-repid.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

*---------------------- At selection screen------------------------*
AT SELECTION-SCREEN.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.
  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.
  PERFORM check_input.

  IF comprof IS INITIAL AND sinprof IS INITIAL.
*    IF sy-batch IS INITIAL.
    MESSAGE e208(00) WITH
    'Select either Composite or Single profiles or both'(020).
*    ENDIF.
  ENDIF.
*-------------------At selection screen output----------------------*
AT SELECTION-SCREEN OUTPUT.
  PERFORM handle_button.
  PERFORM handle_sections.

  LOOP AT SCREEN.
    CASE screen-name .
      WHEN 'PCOLOR'.
        IF shodet = 'X'.
          screen-input = 0.
          CLEAR pcolor.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'SHODET'.
        IF p_detsum IS INITIAL.
          IF pcolor = 'X'.
            screen-input = 0.
            CLEAR shodet.
            shosum  = 'X'.
          ELSE.
            screen-input = 1.
          ENDIF.
          MODIFY SCREEN.
        ENDIF.
      WHEN 'PCOLOR' .
*        IF shosum = 'X' .
        screen-input = 1 .
*        ELSE.
*          screen-input = 0 .
*        ENDIF.
      WHEN 'SHONOSOD'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT spconfs[] IS INITIAL OR NOT s_risk[] IS INITIAL
        OR NOT sens[] IS INITIAL.
          IF shonosod = 'X'.
            CLEAR shonosod.
            screen-input = 0.
            MESSAGE w398(00) WITH text-c01.
          ENDIF.

          screen-input = 0.
          CLEAR shonosod.
        ELSE.
          screen-input = 1.
        ENDIF.
*--Disable Show no SOD when detailed output is requested
        IF shodet = 'X'.
          screen-input  = '0'.
          IF shonosod = 'X'.
            CLEAR shonosod.
            MESSAGE w398(00) WITH text-c01.
          ENDIF.
        ELSE.
          IF spconfs[] IS INITIAL
          AND s_risk[] IS INITIAL
          AND sens[] IS INITIAL.
            screen-input  = '1'.
          ENDIF.
        ENDIF.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          IF p_detsum <> 'X'.
            screen-input = 1.
            IF p_first = 'X'.
              CLEAR p_first.
              p_hienhn = 'X'.
            ENDIF.

          ENDIF.
        ENDIF.

    ENDCASE.

    IF screen-group1 = '001'.
      AUTHORITY-CHECK OBJECT 'S_BTCH_ADM'
      ID 'BTCADMIN' FIELD 'Y'.
      IF sy-subrc <> 0.
        screen-invisible = '1'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
    MODIFY SCREEN .
  ENDLOOP.

*---------------------Start of Selection------------------*

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
  DATA : l_vrsio    TYPE /psyng/sodvrsio,
         l_date(10) TYPE c,
         l_profile  TYPE agr_prof-profile.
  IF g_exit_proc = 'Y'.

    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(11/12/24)
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.


  WRITE sy-datum TO l_date.
*-- Field Validations
*--Validation of SOD version
  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  IF sy-subrc NE 0.
    MESSAGE i135(/psyng/sw) WITH 'SOD Version does not exist.'(195).
    LEAVE LIST-PROCESSING.
  ENDIF.


  IF shosum = 'X'.
*--Get auth objects and values
    PERFORM get_prof_data.
*    IF gt_profauth[] IS INITIAL.
*      MESSAGE s000(00) WITH 'No Data Found'(023).
*      EXIT.
*    ENDIF.

    SORT gt_analyzed_prof.
    DELETE ADJACENT DUPLICATES FROM gt_analyzed_prof COMPARING ALL
    FIELDS.

*--SOD analysis summary mode
    CALL FUNCTION '/PSYNG/SW_036'
      EXPORTING
        vrsio                 = sodvrsio
        i_simu_rfc            = 'X'
        xstb_fm               = 'X'
        org_check             = orgchk
        enh_fm                = p_enhanc
        i_bysimu              = ''
        i_local_sod           = 'X'
        i_advanced_role_simu  = 'X'
        i_shonosod            = shonosod
        i_composite_roles     = ''
        i_single_roles        = ''
        i_shomit              = ''
        i_assigned_roles      = ''
      TABLES
        it_roles              = gt_roles
        it_confs              = spconfs
        it_sens               = sens
        it_risk               = s_risk
        ot_routput            = gt_output
        ot_routput_sum        = gt_output_sum
        it_advanced_role_simu = gt_profauth.

*--Get conid risk and sensitivity
    if not gt_output_sum[] is initial.
      SELECT conid risk imp description FROM /psyng/conflict
      INTO CORRESPONDING FIELDS OF TABLE gt_condet
       FOR ALL ENTRIES IN gt_output_sum
        WHERE conid = gt_output_sum-conid
        AND vrsio = sodvrsio.
    endif.
*- Get profile texts
    SELECT langu profn ptext FROM usr11
     INTO CORRESPONDING FIELDS OF TABLE gt_proftext
       WHERE profn IN prof.

    LOOP AT gt_analyzed_prof.
      CLEAR l_profile.
      IF gt_analyzed_prof-composite = 'X'.
        l_profile = gt_analyzed_prof-comp_prof.
      ELSE.
        l_profile = gt_analyzed_prof-profile.
      ENDIF.
      LOOP AT gt_output_sum WHERE agr_name = l_profile.
        CLEAR: gt_final, gt_condet, gt_proftext.

*-- Check if the profile is a part of composite profile we analyzed
        IF gt_analyzed_prof-composite = 'X'.
          READ TABLE gt_analyzed_prof WITH KEY
                                 comp_prof = gt_output_sum-agr_name
                                 composite = 'X'.
          IF sy-subrc = 0.
            gt_final-profile = gt_analyzed_prof-comp_prof.
          ELSE.
            READ TABLE gt_analyzed_prof WITH KEY
                                   profile = gt_output_sum-agr_name.
            IF sy-subrc = 0.
              gt_final-profile = gt_analyzed_prof-profile.
            ENDIF.
          ENDIF.
        ELSE.
          gt_final-profile = gt_analyzed_prof-profile.
        ENDIF.

        gt_final-conid = gt_output_sum-conid.
*        READ TABLE gt_output WITH KEY conid = gt_final-conid
*        BINARY SEARCH TRANSPORTING NO FIELDS.
*        IF sy-subrc = 0.
        gt_final-enhanced = gt_output_sum-enhanced.
*        ENDIF.
*--add profile text

        READ TABLE gt_proftext WITH KEY profn = gt_final-profile
                                        langu = sy-langu.
        IF sy-subrc = 0.
          gt_final-ptext = gt_proftext-ptext.
        ENDIF.
*--add conflict details
        READ TABLE gt_condet WITH KEY conid = gt_output_sum-conid.
        IF sy-subrc = 0.
          gt_final-imp = gt_condet-imp.
          gt_final-risk = gt_condet-risk.
          gt_final-description = gt_condet-description.
        ELSE.
          CONCATENATE
 'No SOD issues based on SOD matrix defined in Security Weaver on '(030)
      l_date INTO
          gt_final-description SEPARATED BY space.
        ENDIF.
*--If highlight dynamically enhanced conflicts is checked
        IF p_hienhn = 'X'.
          IF gt_final-enhanced = 'X'.
            DELETE gt_final-color_cell
                   WHERE fname = 'CONID'.
            g_color-col = '7'.   "Orange
            g_color-int = '1'.   "Intensified
            g_color-inv = '0'.   "Inverse
            g_cc-color  = g_color.
            g_cc-fname  = 'CONID'.
            APPEND g_cc TO gt_final-color_cell.
            g_cc-fname  = 'TCODE'.
            APPEND g_cc TO gt_final-color_cell.
          ENDIF.
        ENDIF.
*-- Color scheme for highlighting conflicts
        IF pcolor = 'X'.
          CASE gt_final-imp.
            WHEN 'HIGH'.
              gt_final-isort = '1'.
              g_color-col = '6'.   "Red
              g_color-int = '1'.   "Intensified
              g_color-inv = '0'.   "Inverse
              g_cc-fname = 'IMP'.
              g_cc-color = g_color.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'CONID'.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'DESCRIPTION'.
              APPEND g_cc TO gt_final-color_cell.
*        1stoutput-color_line = 'C600'.
            WHEN 'MEDIUM'.
              gt_final-isort = '2'.
              g_color-col = '6'.   "Red
              g_color-int = '0'.   "Un-Intensified
              g_color-inv = '0'.   "Inverse
              g_cc-fname = 'IMP'.
              g_cc-color = g_color.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'CONID'.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'DESCRIPTION'.
              APPEND g_cc TO gt_final-color_cell.
*        1stoutput-color_line = 'C300'.
            WHEN 'LOW'.
              gt_final-isort = '3'.
              g_color-col = '3'.   "Yellow
              g_color-int = '0'.   "Un-Intensified
              g_color-inv = '0'.   "Inverse
              g_cc-fname = 'IMP'.
              g_cc-color = g_color.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'CONID'.
              APPEND g_cc TO gt_final-color_cell.
              g_cc-fname = 'DESCRIPTION'.
              APPEND g_cc TO gt_final-color_cell.
          ENDCASE.
        ENDIF.
*        IF pcolor <> 'X'.   "if user doesn't want to see the conflicts
*          CLEAR gt_final-color_line.   "highlighted in colors
*          CLEAR gt_final-color_cell.
*        ENDIF.

        READ TABLE gt_final WITH KEY profile = gt_final-profile
                                     conid   = gt_final-conid.
        CHECK sy-subrc NE 0.
        APPEND gt_final.
      ENDLOOP.
    ENDLOOP.
    MESSAGE s000(00) WITH 'Analysis Complete'.
    SORT gt_final.
    PERFORM alv_output.
*    ENDIF.
  ELSE.
*------------------Detail Analysis-----------------*
*--Get auth objects and values
    PERFORM get_prof_data.
    IF gt_profauth[] IS INITIAL.
      MESSAGE s000(00) WITH 'No Data Found'(023).
      EXIT.
    ENDIF.

    SORT gt_analyzed_prof.
    DELETE ADJACENT DUPLICATES FROM gt_analyzed_prof COMPARING ALL
    FIELDS.

*--Detailed output
    CALL FUNCTION '/PSYNG/SW_083'
      EXPORTING
        i_bysimu              = ''
        i_sodvrsio            = sodvrsio
        i_enhanc              = p_enhanc
        i_orgchk              = orgchk
        i_hienhn              = p_hienhn
        i_shonosod            = shonosod
        i_advanced_role_simu  = 'X'
        i_composite_roles     = ''
        i_single_roles        = ''
        i_shomit              = ''
        i_assigned_roles      = ''
      TABLES
        it_roles              = gt_roles
        it_conflicts          = spconfs
        it_sens               = sens
        it_risk               = s_risk
        et_outputdet          = gt_outputdet
        it_advanced_role_simu = gt_profauth.

    IF gt_outputdet[] IS INITIAL.
      MESSAGE s000(00) WITH 'No Data Found'(023).
    ELSE.
      LOOP AT gt_analyzed_prof.
        CLEAR l_profile.
        IF gt_analyzed_prof-composite = 'X'.
          l_profile = gt_analyzed_prof-comp_prof.
        ELSE.
          l_profile = gt_analyzed_prof-profile.
        ENDIF.
        LOOP AT gt_outputdet WHERE agr_name = l_profile.
          MOVE-CORRESPONDING gt_outputdet TO gt_det_final.
          IF gt_analyzed_prof-composite = 'X'.
            READ TABLE gt_analyzed_prof WITH KEY
                                       comp_prof = gt_outputdet-agr_name
                                       composite = 'X'.
            IF sy-subrc = 0.
              gt_det_final-agr_name = gt_analyzed_prof-comp_prof.
            ELSE.
              READ TABLE gt_analyzed_prof WITH KEY
                                     profile = gt_outputdet-agr_name.
              IF sy-subrc = 0.
                gt_det_final-agr_name = gt_analyzed_prof-profile.
                CLEAR gt_det_final-child_agr.
              ENDIF.
            ENDIF.
          ELSE.
            gt_det_final-agr_name = gt_analyzed_prof-profile.
            CLEAR gt_det_final-child_agr.
          ENDIF.
*-- Highlight Enhanced
          IF p_hienhn = 'X'.
            CLEAR : g_cc,g_color.
            IF gt_det_final-enhanced = 'X'.
              DELETE gt_det_final-color_cell
                     WHERE fname = 'CONID' OR fname = 'TCODE'.
              g_color-col = '7'.   "Orange
              g_color-int = '1'.   "Intensified
              g_color-inv = '0'.   "Inverse
              g_cc-color  = g_color.
              g_cc-fname  = 'CONID'.
              APPEND g_cc TO gt_det_final-color_cell.
*              r1stoutput-color_cell[] =  gt_det_final-color_cell[].
              g_cc-fname  = 'TCODE'.
              APPEND g_cc TO gt_det_final-color_cell.
            ENDIF.
          ENDIF.

          APPEND gt_det_final.
          CLEAR gt_det_final.

        ENDLOOP.
      ENDLOOP.
      MESSAGE s000(00) WITH 'Analysis Complete'.
      PERFORM alv_output_det.
    ENDIF.

  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'PROF_BUT' 'X' CHANGING prof_but .
  PERFORM init_but USING 'CON_BUT'  '' CHANGING con_but  .
  PERFORM init_but USING 'OUT_BUT'  '' CHANGING out_but  .
  PERFORM init_but USING 'EXE_BUT'  '' CHANGING exe_but  .
  PERFORM init_but USING 'BGD_BUT'  '' CHANGING bgd_but  .
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
         l_exp    TYPE flag.
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
*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
*----------------------------------------------------------------------*
FORM expand CHANGING button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*     text       = text-b01
*     info       = text-x02
      name       = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result     = button
    EXCEPTIONS
  "(++)BOC UMITTAL SE VF scan-25/11/2024
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  collapse
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
*----------------------------------------------------------------------*
FORM collapse CHANGING    button.

  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*     text       = text-b01
*     info       = text-x01
      name       = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result     = button
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             ICON_NOT_FOUND = 1
             OUTPUTFIELD_TOO_SHORT          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " collapse
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exelog.
  DATA: lt_exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  lt_exelog-mandt         = sy-mandt.
  lt_exelog-repid         = sy-repid.
  lt_exelog-uname         = g_current_user."sy-uname. C0700
  lt_exelog-datum         = sy-datum.
  lt_exelog-uzeit         = sy-uzeit.
  APPEND lt_exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
      exelog = lt_exelog.
  COMMIT WORK.

*  DATA: licn TYPE sy-datum VALUE '20080331'.
*  IF sy-datum > licn.
*    MESSAGE e208(00) WITH
*       'License expired. Contact Security Weaver, LLC'.
*  ENDIF.

ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: ls_swconfig TYPE /psyng/swconfig,
        l_table(6)  TYPE c,
        lt_tvarv    TYPE TABLE OF tvarv WITH HEADER LINE.

*Highlight conflicts
  se_config_param 'DFLT_LIGT_COLOR' ls_swconfig-value.
  IF ls_swconfig-value = 'Y'.
    pcolor = 'X'.
  ELSEIF ls_swconfig-value = 'N'.
    pcolor = ' '.
  ENDIF.
  CLEAR ls_swconfig.


ENDFORM.                    " get_initial_config
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
    WHEN 'PROF_BUT'.
      PERFORM toggle USING prof_but 'PROF_BUT'.
    WHEN 'CON_BUT'.
      PERFORM toggle USING con_but 'CON_BUT'.
    WHEN 'OUT_BUT'.
      PERFORM toggle USING out_but 'OUT_BUT'.
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but 'BGD_BUT'.

  ENDCASE.
  CLEAR g_ucomm.

ENDFORM.                    " handle_button
*&---------------------------------------------------------------------*
*&      Form  toggle
*&---------------------------------------------------------------------*
*       ...
*----------------------------------------------------------------------*
*  -->  I_BUTTON
*----------------------------------------------------------------------*
FORM toggle USING i_button i_name.

  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user."sy-uname. C0700
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
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.

  PERFORM handle_section USING  prof_but 'PRO'.
  PERFORM handle_section USING  con_but  'CON'.
  PERFORM handle_section USING  out_but  'OUT'.
  PERFORM handle_section USING  exe_but  'EXE'.
  PERFORM handle_section USING  bgd_but  'BGD'.

ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  handle_section
*&---------------------------------------------------------------------*
*       .......
*----------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME
*----------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.
  DATA : l_collapse TYPE flag.

  LOOP AT SCREEN .
    IF screen-group1 = i_section_name.
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
*&      Form  get_prof_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_prof_data.
  DATA : lt_comp_singles_temp LIKE TABLE OF gt_comp_singles.
  DATA: BEGIN OF lt_assigned OCCURS 0,
          profile TYPE ust04-profile,
        END OF lt_assigned.

  DATA: BEGIN OF lt_auths OCCURS 0,
          auth TYPE ust12-auth,
        END OF lt_auths.

  REFRESH lt_assigned.
  CONCATENATE sy-sysid sy-mandt INTO g_dest.
*--get all the single profiles
  IF sinprof EQ 'X'.
    SELECT profn
           objct
           auth
    FROM ust10s
       INTO CORRESPONDING FIELDS OF TABLE gt_single_profs
         WHERE profn IN prof
         AND aktps   = 'A'.

*-- When assigned profile only checked
    IF asign_p EQ 'X'.
      IF NOT gt_single_profs[] IS INITIAL.
        SELECT profile FROM ust04 INTO TABLE lt_assigned
         FOR ALL ENTRIES IN gt_single_profs
         WHERE profile = gt_single_profs-profn.
      ENDIF.

*-- Delete unassigned profile
      LOOP AT gt_single_profs.
        READ TABLE lt_assigned
            WITH KEY profile = gt_single_profs-profn.
        IF sy-subrc NE 0.
          DELETE gt_single_profs WHERE profn = gt_single_profs-profn.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.

  LOOP AT gt_single_profs.
    gt_analyzed_prof-profile = gt_single_profs-profn.
    COLLECT gt_analyzed_prof.

    gt_roles-sign = 'I'.
    gt_roles-option = 'EQ'.
    gt_roles-low = gt_single_profs-profn.
    COLLECT gt_roles.

    lt_auths-auth = gt_single_profs-auth.
    COLLECT lt_auths.
  ENDLOOP.
*--Get all composite profiles and their single profiles
  IF comprof EQ 'X'.
    PERFORM get_composite_sub_profiles.
  ENDIF.

  SORT gt_roles BY low.
  DELETE ADJACENT DUPLICATES FROM gt_roles COMPARING low.

*--get the data for single profiles
  IF NOT gt_single_profs[] IS INITIAL.
*-- Get All the auths

    SELECT objct
          auth
          field
          von
          bis
   FROM ust12
       INTO CORRESPONDING FIELDS OF TABLE gt_prof_detail
          FOR ALL ENTRIES IN gt_single_profs
            WHERE
                objct = gt_single_profs-objct AND
                auth = gt_single_profs-auth
                AND aktps   = 'A'.
  ENDIF.

*--Compile the auth data in adv simulation format

  LOOP AT gt_single_profs.
    LOOP AT gt_prof_detail WHERE objct = gt_single_profs-objct
                                 AND auth = gt_single_profs-auth .
      CLEAR gt_profauth.
      gt_profauth-agr_name = gt_single_profs-profn.
      gt_profauth-object    = gt_prof_detail-objct.
      gt_profauth-auth     = gt_prof_detail-auth.
      gt_profauth-field    = gt_prof_detail-field.
      gt_profauth-low     = gt_prof_detail-von.
      gt_profauth-high      = gt_prof_detail-bis.
      APPEND gt_profauth.
    ENDLOOP.
  ENDLOOP.


*-- Get all the details of the single profiles of the composite role
  REFRESH gt_prof_detail.
  IF NOT gt_comp_singles[] IS INITIAL.
    lt_comp_singles_temp[] = gt_comp_singles[].
    SORT lt_comp_singles_temp BY objct auth.
    DELETE ADJACENT DUPLICATES FROM
    lt_comp_singles_temp COMPARING objct auth.
    if not lt_comp_singles_temp[] is initial.
      SELECT objct
             auth
             field
             von
               bis
        FROM ust12
            INTO CORRESPONDING FIELDS OF TABLE gt_prof_detail
               FOR ALL ENTRIES IN lt_comp_singles_temp
                 WHERE
                     objct = lt_comp_singles_temp-objct AND
                     auth = lt_comp_singles_temp-auth
                     AND aktps   = 'A'.
        REFRESH :lt_comp_singles_temp.
    endif.
  ENDIF.


*--Compile the auth data in adv simulation format
  LOOP AT gt_comp_singles.
    LOOP AT gt_prof_detail WHERE objct = gt_comp_singles-objct
                                 AND auth = gt_comp_singles-auth .
      CLEAR gt_profauth.
      gt_profauth-agr_name = gt_comp_singles-composite.
      gt_profauth-object    = gt_prof_detail-objct.
      gt_profauth-auth     = gt_prof_detail-auth.
      gt_profauth-field    = gt_prof_detail-field.
      gt_profauth-low     = gt_prof_detail-von.
      gt_profauth-high      = gt_prof_detail-bis.
      APPEND gt_profauth.
    ENDLOOP.
  ENDLOOP.
**--**--**--
*---------------------
* LOOP AT gt_comp_profs.
*    LOOP AT gt_prof_detail WHERE objct = gt_comp_profs-objct
*                                 AND auth = gt_comp_profs-auth .
*      CLEAR gt_profauth.
*      gt_profauth-agr_name = gt_comp_profs-profn.
*      gt_profauth-object    = gt_prof_detail-objct.
*      gt_profauth-auth     = gt_prof_detail-auth.
*      gt_profauth-field    = gt_prof_detail-field.
*      gt_profauth-low     = gt_prof_detail-von.
*      gt_profauth-high      = gt_prof_detail-bis.
*      APPEND gt_profauth.
*    ENDLOOP.
*  ENDLOOP.

ENDFORM.                    " get_prof_data
*&---------------------------------------------------------------------*
*&      Form  alv_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_output.
  DATA: ls_fieldcat_alv      TYPE slis_fieldcat_alv,
        lt_fieldcat_alv      TYPE slis_t_fieldcat_alv,
        l_sort               TYPE slis_sortinfo_alv,
        ls_alv_layout        TYPE slis_layout_alv,
        lt_sort              TYPE STANDARD TABLE OF slis_sortinfo_alv,
        ls_variant           TYPE disvariant,
        l_program            LIKE sy-repid,
        ls_swconfig_bkgd_job TYPE /psyng/swconfig,
        ls_line_count        TYPE i,
        l_temp               TYPE i,
        gt_final_temp        LIKE TABLE OF gt_final.
  IF sy-batch EQ 'X'.
    se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.

    IF ls_swconfig_bkgd_job-value = 'N'.
      CLEAR g_repeat_hdr_bkgdjob.
      DESCRIBE TABLE gt_final LINES ls_line_count.
      PERFORM set_print_param USING ls_line_count.
    ELSE.
      g_repeat_hdr_bkgdjob = 'X'.
      DESCRIBE TABLE gt_final LINES ls_line_count.
      l_temp = ls_line_count / sy-srows.
      gf_pages = trunc( l_temp ).
      l_temp = frac( l_temp ).
      IF l_temp > 0.
        gf_pages = gf_pages + 1.
      ENDIF.

    ENDIF.
  ENDIF.

  l_program = sy-repid.
  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.
*-- For highlight conflicts
  MOVE 'COLOR_LINE' TO ls_alv_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO ls_alv_layout-coltab_fieldname.

  PERFORM build_alv_catalog.
*--Sorting
  l_sort-spos = '1'.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'PTEXT'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'RISK'.
  l_sort-tabname =  'GT_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

*--Now sort GT_FINAL by the same fields
  SORT gt_final BY profile ptext imp conid  description.
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page   = 'ALV_HEADER'
      i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      i_callback_program       = l_program
      it_sort                  = lt_sort
      i_callback_user_command  = 'PROFILE_DOUBLE_CLICK_ON_SUMRY'
      is_layout                = ls_alv_layout
      it_fieldcat              = gt_fieldcat_alv
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = gt_final
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " alv_output


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: lt_header           TYPE slis_t_listheader,
        ls_wa               TYPE slis_listheader,
        l_exedate(10),
        l_exetime(8)        TYPE c,
        l_prof_count        TYPE i,
        l_conf_count        TYPE i,
        l_average_count     TYPE i,
        l_average_countc(6) TYPE c,
        l_prof_countc(6)    TYPE c,
        l_conf_countc(6)    TYPE c,
        l_alv_grid_titl2    TYPE lvc_title.


  STATICS :  l_pgcnt             TYPE i,
             l_pages             TYPE c,
             l_profcon_countc(6) TYPE c,
             l_profcon_count     TYPE i.
*  SORT gt_final BY profile.
  LOOP AT gt_analyzed_prof."gt_final.
    AT NEW  profile.
      l_prof_count = l_prof_count + 1.
    ENDAT.
  ENDLOOP.

  LOOP AT gt_final.
    AT NEW  profile.
      l_profcon_count = l_profcon_count + 1.
    ENDAT.
    CHECK gt_final-conid <> 'NONE'(071).
    CHECK gt_final-conid NE space .

    l_conf_count = l_conf_count + 1.
  ENDLOOP.

  IF l_prof_count > 0.
    l_average_count = l_conf_count / l_profcon_count.
  ENDIF.

  l_average_countc = l_average_count.
  l_prof_countc = l_prof_count.
  l_conf_countc = l_conf_count.
  l_average_countc  = l_average_count .
  l_profcon_countc = l_profcon_count.

  CONCATENATE l_prof_countc 'prof(s) analyzed'(h06)
           'Avg'(h07) l_average_countc 'Conf(s) in'(h08)
            l_profcon_countc 'prof(s)'(h09)
            INTO l_alv_grid_titl2 SEPARATED BY space.

*-- Header
  ls_wa-typ = 'H'.
  ls_wa-info = 'SOD Profile Analysis Summary Report'(h10).
  APPEND ls_wa TO lt_header.

*- Version
  ls_wa-typ  = 'S'.
  ls_wa-key  = 'SOD version:'(h11).
  SELECT SINGLE vdesc INTO ls_wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  ls_wa-info INTO ls_wa-info SEPARATED BY
space.
  APPEND ls_wa TO lt_header.

*--User & Date

  ls_wa-typ = 'S'.
  ls_wa-key = 'User & Date:'(h12).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

  CONCATENATE g_current_user"sy-uname C0700
   text-h13 l_exedate l_exetime
              INTO ls_wa-info SEPARATED BY space.
  APPEND ls_wa TO lt_header.

  ls_wa-typ = 'S'.
  ls_wa-key = 'Summary:'(h05).
  ls_wa-info = l_alv_grid_titl2.
  APPEND ls_wa TO lt_header.


  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    ls_wa-typ = 'S'.
    ls_wa-key = text-h28.
    CONDENSE l_pages NO-GAPS.
    ls_wa-info = l_pages.
    APPEND ls_wa TO lt_header.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog.

  DATA: ls_fieldcat_alv TYPE slis_fieldcat_alv,
        l_sort          TYPE slis_sortinfo_alv.

  DATA: program         LIKE sy-repid.                   "For ALV call

*build ALV catalog
  program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'GT_FINAL'
      i_inclname         = program
    CHANGING
      ct_fieldcat        = gt_fieldcat_alv
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

  IF p_enhanc = 'X'.
*  if highlight enhanced ruleset is selected, add this field to the alv
    ls_fieldcat_alv-seltext_l      = text-025.
    ls_fieldcat_alv-seltext_m      = text-025.
    ls_fieldcat_alv-seltext_s      = text-025.
    ls_fieldcat_alv-reptext_ddic   = text-025.
    ls_fieldcat_alv-checkbox       = 'X'.
    ls_fieldcat_alv-just       = 'X'.
    MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                     WHERE
                        fieldname = 'ENHANCED'.
  ELSE.
    DELETE gt_fieldcat_alv WHERE fieldname = 'ENHANCED'.
  ENDIF.


  ls_fieldcat_alv-no_out = 'X'.
  MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'ISORT'.

**  ls_fieldcat_/alv-no_out = 'X'.
*  MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
*                    TRANSPORTING
*                      no_out
*                   WHERE
*                      fieldname = 'RISK'.

*  ls_fieldcat_alv-no_out = 'X'.
*  MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
*                    TRANSPORTING
*                      no_out
*                   WHERE
*                      fieldname = 'ENHANCED'.


  ls_fieldcat_alv-hotspot = 'X'.
  MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'CONID'.
*-- delete the color columns
  DELETE gt_fieldcat_alv WHERE fieldname = 'COLOR_LINE'.
  DELETE gt_fieldcat_alv WHERE fieldname = 'COLOR_CELL'.

*-- no key fields
  ls_fieldcat_alv-key = ' '.
  MODIFY gt_fieldcat_alv FROM ls_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.

ENDFORM.                    " build_alv_catalog

*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*

FORM pf_status_summary USING it_extab TYPE slis_t_extab.
*  DATA: BEGIN OF lt_func OCCURS 0,
*          fcode LIKE rsmpe-func,
*        END OF lt_func.
*
*
*  IF byrsimu IS INITIAL.
*    lt_func-fcode = 'ROLEREMDET'.
*    APPEND lt_func.
*  ENDIF.
*
*  lt_func-fcode = '&XINT'.
*  APPEND lt_func.
  SET PF-STATUS 'SUMMARY'." EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  get_composite_sub_profiles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_composite_sub_profiles.
  DATA: lt_single TYPE TABLE OF ust10s WITH HEADER LINE,
        lt_sub    TYPE TABLE OF /psyng/profinfo WITH HEADER LINE.
  DATA: BEGIN OF lt_subprofiles OCCURS 0,
          composite  TYPE ust10c-profn,
          subprofile TYPE ust10c-subprof,
        END OF lt_subprofiles.

  DATA: BEGIN OF lt_assigned OCCURS 0,
          profile TYPE ust04-profile,
        END OF lt_assigned.

*--Select sub profiles for composite profiles

  SELECT profn
         subprof
     FROM ust10c
     INTO CORRESPONDING FIELDS OF TABLE gt_comp_profs
       WHERE profn IN prof
       AND aktps   = 'A'.

  SORT gt_comp_profs.
  DELETE ADJACENT DUPLICATES FROM gt_comp_profs COMPARING profn.


*-- When assigned profile only checked
  IF asign_p EQ 'X'.
    IF NOT gt_comp_profs[] IS INITIAL.
      SELECT profile FROM ust04 INTO TABLE lt_assigned
       FOR ALL ENTRIES IN gt_comp_profs
       WHERE profile = gt_comp_profs-profn.
    ENDIF.

*-- Delete unassigned profiles
    LOOP AT gt_comp_profs.
      READ TABLE lt_assigned WITH KEY profile = gt_comp_profs-profn.
      IF sy-subrc NE 0.
        DELETE gt_comp_profs WHERE profn = gt_comp_profs-profn.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--Get all single profiles
*--Using this FM as subprofiles could be composite as well
  LOOP AT gt_comp_profs.
    REFRESH lt_sub.
    CLEAR lt_sub.
    CALL FUNCTION '/PSYNG/SW_GET_SINGLE_PROFS'
      EXPORTING
        profname = gt_comp_profs-profn
      TABLES
        profinfo = lt_sub
*       IUST10C  =
      .
    LOOP AT lt_sub.
      lt_subprofiles-composite = gt_comp_profs-profn.
      lt_subprofiles-subprofile = lt_sub-profn.
      APPEND lt_subprofiles.

*      gt_analyzed_prof-profile = lt_sub-profn.
      gt_analyzed_prof-comp_prof = gt_comp_profs-profn.
      gt_analyzed_prof-composite = 'X'.
      COLLECT gt_analyzed_prof.

    ENDLOOP.
  ENDLOOP.

*--Fill all the roles composite

*  LOOP AT gt_comp_profs.
*    READ TABLE gt_roles WITH KEY low = gt_comp_profs-profn.
*    IF sy-subrc <> 0.
*      gt_roles-sign = 'I'.
*      gt_roles-option = 'EQ'.
*      gt_roles-low = gt_comp_profs-profn.
*      APPEND gt_roles.
*    ENDIF.
*  ENDLOOP.

  LOOP AT lt_subprofiles.
    READ TABLE gt_roles WITH KEY low = lt_subprofiles-composite.
    IF sy-subrc <> 0.
      gt_roles-sign = 'I'.
      gt_roles-option = 'EQ'.
      gt_roles-low = lt_subprofiles-composite.
      COLLECT gt_roles.
    ENDIF.
  ENDLOOP.

  IF NOT lt_subprofiles[] IS INITIAL.
*--Get objects/auths for single profiles
    SELECT profn
         objct
         auth
    FROM ust10s
     INTO CORRESPONDING FIELDS OF TABLE lt_single
        FOR ALL ENTRIES IN lt_subprofiles
         WHERE profn = lt_subprofiles-subprofile
           AND aktps   = 'A'.
  ENDIF.

*  LOOP AT lt_single.
*    MOVE-CORRESPONDING lt_single TO gt_single_profs.
*    APPEND gt_single_profs.
*  ENDLOOP.
**--**--**--**--
  LOOP AT lt_subprofiles.
    LOOP AT lt_single WHERE profn = lt_subprofiles-subprofile.
      gt_comp_singles-composite =  lt_subprofiles-composite.
      gt_comp_singles-profn = lt_single-profn.
      gt_comp_singles-objct = lt_single-objct.
      gt_comp_singles-auth = lt_single-auth.
      APPEND gt_comp_singles.
    ENDLOOP.
  ENDLOOP.
**--**--**--
ENDFORM.                    " get_composite_sub_profiles
*&---------------------------------------------------------------------*
*&      Form  alv_output_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM alv_output_det.
  DATA: ls_fieldcat_alv TYPE slis_fieldcat_alv,
        lt_fieldcat_alv TYPE slis_t_fieldcat_alv,
        l_sort          TYPE slis_sortinfo_alv,
        ls_alv_layout   TYPE slis_layout_alv,
        lt_sort         TYPE STANDARD TABLE OF slis_sortinfo_alv,
        ls_variant      TYPE disvariant,
        l_program       LIKE sy-repid,
        l_grid_title    TYPE lvc_title.

  REFRESH lt_sort.
  l_program = sy-repid.
  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.
*-- For highlight conflicts
  MOVE 'COLOR_LINE' TO ls_alv_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO ls_alv_layout-coltab_fieldname.

  PERFORM build_alv_catalog_det.
*--Sorting
  l_sort-spos = '1'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OBJCT'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AUTH'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELD'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VON'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BIS'.
  l_sort-tabname =  'GT_DET_FINAL'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.



*  ADD 1 TO l_sort-spos.
*  l_sort-fieldname = 'CHILD_AGR'.
*  l_sort-tabname =  'GT_DET_FINAL'.
*  l_sort-up = 'X'.
*  APPEND l_sort TO lt_sort.

  l_grid_title = 'Details: Profile(s) with SOD Conflicts'(049).
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title             = l_grid_title
*     i_callback_top_of_page   = 'ALV_HEADER'
      i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      i_callback_program       = l_program
      i_callback_user_command  = 'PROFILE_DOUBLE_CLICK_ON_DETL'
      it_sort                  = lt_sort
*     i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
      is_layout                = ls_alv_layout
      it_fieldcat              = gt_fieldcat_det
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = gt_det_final
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " alv_output_det
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog_det.
  DATA: ls_fieldcat_alv  TYPE slis_fieldcat_alv.
*        l_sort           TYPE slis_sortinfo_alv.

  ls_fieldcat_alv-fieldname = 'AGR_NAME'.
  ls_fieldcat_alv-seltext_l = 'Profile'(041).
  ls_fieldcat_alv-col_pos   = 1.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'DESCRIPTION'.
  ls_fieldcat_alv-seltext_l = 'SW:Risk Description'(019).
  ls_fieldcat_alv-col_pos   = 2.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.


  ls_fieldcat_alv-fieldname = 'CONID'.
  ls_fieldcat_alv-seltext_l = 'Con ID'(039).
  ls_fieldcat_alv-col_pos   = 3.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'FUNCTIONID'.
  ls_fieldcat_alv-seltext_l = 'Func.ID'(040).
  ls_fieldcat_alv-col_pos   = 4.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'TCODE'.
  ls_fieldcat_alv-seltext_l = 'Transaction Code'(044).
  ls_fieldcat_alv-col_pos   = 5.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.



  ls_fieldcat_alv-fieldname = 'OBJCT'.
  ls_fieldcat_alv-seltext_l = 'Auth. Object'(045).
  ls_fieldcat_alv-col_pos   = 6.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'AUTH'.
  ls_fieldcat_alv-seltext_l = 'Authorization'(048).
  ls_fieldcat_alv-col_pos   = 7.
*  ls_fieldcat_alv-no_out   = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  IF orgchk IS INITIAL.
* hide column org_abb
    ls_fieldcat_alv-no_out = 'X'.
  ENDIF.
  ls_fieldcat_alv-fieldname = 'ORG_ABB'.
  ls_fieldcat_alv-seltext_l = 'Abbr'(052).
  ls_fieldcat_alv-col_pos   = 8.
*  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'FIELD'.
  ls_fieldcat_alv-seltext_l = 'Field'(046).
  ls_fieldcat_alv-col_pos   = 9.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'VON'.
  ls_fieldcat_alv-seltext_l = 'From'(042).
  ls_fieldcat_alv-col_pos   = 10.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  ls_fieldcat_alv-fieldname = 'BIS'.
  ls_fieldcat_alv-seltext_l = 'To'(043).
  ls_fieldcat_alv-col_pos   = 11.
  ls_fieldcat_alv-hotspot = 'X'.
  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
  CLEAR ls_fieldcat_alv.

  IF p_enhanc = 'X'.
    ls_fieldcat_alv-fieldname = 'ENHANCED'.
    ls_fieldcat_alv-seltext_l = 'Enhanced'(025).
    ls_fieldcat_alv-col_pos   = 12.
    ls_fieldcat_alv-checkbox = 'X'.
    APPEND ls_fieldcat_alv TO gt_fieldcat_det.
    CLEAR ls_fieldcat_alv.
  ENDIF.

*  ls_fieldcat_alv-fieldname = 'CHILD_AGR'.
*  ls_fieldcat_alv-seltext_l = 'Single profile'(050).
*  ls_fieldcat_alv-col_pos   = 11.
*  ls_fieldcat_alv-hotspot = 'X'.
*  APPEND ls_fieldcat_alv TO gt_fieldcat_det.
*  CLEAR ls_fieldcat_alv.

ENDFORM.                    " build_alv_catalog_det


*&---------------------------------------------------------------------*
*&      Form  USER_DOUBLE_CLICK_ON_DETL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM profile_double_click_on_detl USING r_ucomm LIKE sy-ucomm
                                 l_rs_selfield TYPE slis_selfield.

  DATA: lt_tcodes    TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE,
        l_wa_tcodes  LIKE /psyng/range_tcode,
        wa_det_final LIKE LINE OF gt_det_final,
        l_risktext   LIKE /psyng/sw_risk-text,
        l_repid      LIKE sy-repid,
        l_functionid TYPE slis_selfield-value,
        l_fioriid    TYPE /psyng/sw_fioriid,
        l_hashcode   TYPE xupname,
        l_line(80),
        l_answer,
        l_authfield  LIKE authx-fieldname,
        l_iobjct     LIKE tobj-objct,
        l_conid      TYPE /psyng/conflict_id,
        l_field      LIKE  dfies-fieldname,
        l_object     LIKE  dd23l-mconame,
        l_tcode      type xutcode.

  CASE l_rs_selfield-fieldname.
    WHEN 'CONID'.
      MOVE l_rs_selfield-value TO l_conid.
      CHECK NOT l_conid IS INITIAL.
*

*--for the drill down
      CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
        EXPORTING
          i_objecttype = l_rs_selfield-fieldname
          i_objectid   = l_rs_selfield-value
          i_vrsio      = sodvrsio.
    WHEN 'TCODE'.
      READ TABLE gt_det_final INDEX l_rs_selfield-tabindex.
      l_tcode = l_rs_selfield-value.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
         i_tcode           = l_tcode
         I_VRSIO           = sodvrsio
         I_FUNID           = gt_det_final-functionid.

    WHEN 'FIELD'.
      CHECK l_rs_selfield-value <> space.
      l_authfield = l_rs_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
        EXPORTING
          fieldname = l_authfield.

    WHEN 'RISK'.
      CHECK l_rs_selfield-value <> space.
      SELECT SINGLE text INTO l_risktext FROM /psyng/sw_risk
                    WHERE risk = l_rs_selfield-value.
      CHECK sy-subrc = 0.

      CONCATENATE l_rs_selfield-value '=' l_risktext INTO l_risktext
                  SEPARATED BY space.
      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = text-175
          text_question         = l_risktext
          text_button_1         = text-129
          icon_button_1         = 'ICON_SYSTEM_OKAY'
          text_button_2         = text-122
          icon_button_2         = 'ICON_SYSTEM_CANCEL'
          default_button        = '1'
          display_cancel_button = space
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             text_not_found = 1
             OTHERS         = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

    WHEN 'FUNCTIONID'.
      CLEAR l_answer.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
        EXPORTING
          i_objecttype = l_rs_selfield-fieldname
          i_objectid   = l_rs_selfield-value
          i_vrsio      = sodvrsio.

    WHEN 'OBJCT'.
      CHECK l_rs_selfield-value <> space.
      READ TABLE gt_det_final INDEX l_rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_iobjct = l_rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
        EXPORTING
          object  = l_iobjct
          eu_mode = ' '.

    WHEN 'VON'.
      CHECK l_rs_selfield-value <> space.
      READ TABLE gt_det_final INDEX l_rs_selfield-tabindex.
      CHECK sy-subrc = 0.

      l_field  = gt_det_final-field.
      l_object = gt_det_final-objct.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  gt_det_final-objct EQ gc_service
      AND gt_det_final-field EQ gc_srv_name.
        l_hashcode = gt_det_final-von.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode      = l_hashcode
            if_show_message = 'X'
          EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
*      CALL FUNCTION 'SUSR_AUTF_GET_F4_HELP'

*      CALL FUNCTION 'G_HELP_VALUES_GET'

      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
        EXPORTING
          fieldname       = gt_det_final-field
          object          = gt_det_final-objct
        EXCEPTIONS
          field_not_found = 1
          OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'BIS'.
      CHECK l_rs_selfield-value <> space.
      READ TABLE gt_det_final INDEX l_rs_selfield-tabindex.
      CHECK sy-subrc = 0.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  gt_det_final-objct EQ gc_service
      AND gt_det_final-field EQ gc_srv_name.
        l_hashcode = gt_det_final-bis.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode      = l_hashcode
            if_show_message = 'X'
          EXCEPTIONS
            not_found       = 1
            OTHERS          = 2.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
        EXPORTING
          fieldname       = gt_det_final-field
          object          = gt_det_final-objct
        EXCEPTIONS
          field_not_found = 1
          OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'AGR_NAME' OR 'CHILD_AGR'.
      CHECK l_rs_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU02'.
      ELSE.
        SET PARAMETER ID 'XUP' FIELD l_rs_selfield-value.
        CALL TRANSACTION 'SU02'.
      ENDIF.

  ENDCASE.
ENDFORM.  "PROFILE_DOUBLE_CLICK_ON_DETL

*---------------------------------------------------------------------*
*       FORM profile_double_click_on_detl                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  L_RS_SELFIELD                                                 *
*---------------------------------------------------------------------*
FORM profile_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                 l_rs_selfield TYPE slis_selfield.
  CASE l_rs_selfield-fieldname.
    WHEN 'CONID'.
*      SORT gt_final BY profile conid.
      READ TABLE gt_final INDEX l_rs_selfield-tabindex.
*      with key conid = l_rs_selfield-value.
      CHECK sy-subrc = 0 AND gt_final-conid <> '----'.
      PERFORM detailed_sod_analysis
        USING
          gt_final
          ''.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  detailed_sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_DET_FINAL  text
*      -->P_4112   text
*----------------------------------------------------------------------*
FORM detailed_sod_analysis USING   is_output LIKE gt_final
                                   if_all    TYPE flag.

  DATA:  iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  CLEAR:   iseltab.
  REFRESH: iseltab.


  iseltab-selname = 'PROF'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = is_output-profile.
  APPEND iseltab.


  CLEAR iseltab.
*  LOOP AT spconfs.
  iseltab-selname = 'SPCONFS'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = is_output-conid.
  APPEND iseltab.
*  ENDLOOP.

  CLEAR iseltab.
  LOOP AT sens.
    iseltab-selname = 'SENS'.
    MOVE-CORRESPONDING sens TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  CLEAR iseltab.
  LOOP AT s_risk.
    iseltab-selname = 'S_RISK'.
    MOVE-CORRESPONDING s_risk TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  CLEAR iseltab.
  iseltab-selname = 'COMPROF'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = comprof.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'SINPROF'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sinprof.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'ASSGN_P'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = asign_p.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'SHODET'.    "show details
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'SHOSUM'.    "show details
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'SODVRSIO'.        "SOD Version
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sodvrsio.
  APPEND iseltab.



  CLEAR iseltab.
  iseltab-selname = 'P_DETSUM'.        "Detail
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.


  CLEAR iseltab.
  iseltab-selname = 'ORGCHK'.        "Detail
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = orgchk.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_ENHANC'.       "include enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_HIENHN'.       "higlight enhanced ruleset
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_hienhn.
  APPEND iseltab.

  SUBMIT /psyng/sodreport_by_profile WITH SELECTION-TABLE iseltab AND
  RETURN.
ENDFORM.                    " detailed_sod_analysis
*&---------------------------------------------------------------------*
*&      Form  set_print_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LINE_COUNT  text
*----------------------------------------------------------------------*
FORM set_print_param USING p_line_count.

  p_line_count = p_line_count + 25 .
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
    EXPORTING
      line_count = p_line_count.

ENDFORM.                    " set_print_param
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_input.
  IF g_ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.

  IF g_ucomm = 'SCJB'.
    g_exit_proc = 'Y'.
    PERFORM schedule_back_job.

    EXIT.
  ENDIF.


  IF g_ucomm = 'VERIFY_P'.
    PERFORM get_profiles_count.
    EXIT.
  ENDIF.
ENDFORM.                    " check_input
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: l_curr_report LIKE rsvar-report,
        l_jobname     TYPE btcjob.


  CLEAR: l_curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  l_curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = l_curr_report
      curr_variant  = g_curr_variant
      vari_desc     = g_vari_desc
    TABLES
      vari_contents = g_vari_contents
      vari_text     = g_vari_text
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             ILLEGAL_REPORT_OR_VARIANT   = 1
             ILLEGAL_VARIANTNAME = 2
             NOT_AUTHORIZED = 3
             NOT_EXECUTED   = 4
             REPORT_NOT_EXISTENT   = 5
             REPORT_NOT_SUPPLIED   = 6
             VARIANT_EXISTS  = 7
             VARIANT_LOCKED  = 8
             OTHERS          = 9 .
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = text-051.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = l_jobname
        in_repvarnt = g_curr_variant
        in_report   = l_curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_back_job
*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: l_oldnumber(7)   TYPE n, l_oldnumber_c(7).

  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.

*  SELECT variant INTO variant FROM varid WHERE report = sy-repid AND
*                           variant LIKE '/PSYNG/%' AND NOT
*                           variant LIKE '/PSYNG/Z%'.
*    oldnumber = variant+7(7).
*  ENDSELECT.
  SELECT  variant INTO g_variant FROM varid

  WHERE report = sy-repid   AND
        variant LIKE '/PSYNG/%' AND NOT
        variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    l_oldnumber = g_variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    g_variant = '/PSYNG/0000000'.
  ELSE.
    l_oldnumber = l_oldnumber + 1.
    MOVE l_oldnumber TO l_oldnumber_c.
    CONCATENATE '/PSYNG/' l_oldnumber_c INTO g_variant.
  ENDIF.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH :r_irsparams[].
*Parameters
  LOOP AT prof.
    r_irsparams-kind = 'S'.
    MOVE-CORRESPONDING prof TO r_irsparams.
    APPEND r_irsparams.
  ENDLOOP.

  r_irsparams-selname = 'SINPROF'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'. r_irsparams-option = 'EQ'.
  r_irsparams-low = sinprof.
  APPEND r_irsparams.


  r_irsparams-selname = 'COMPROF'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'. r_irsparams-option = 'EQ'.
  r_irsparams-low = comprof.
  APPEND r_irsparams.

  r_irsparams-selname = 'ASIGN_P'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'. r_irsparams-option = 'EQ'.
  r_irsparams-low = asign_p.
  APPEND r_irsparams.

  LOOP AT spconfs.
    r_irsparams-selname = 'SPCONFS'.
    r_irsparams-kind = 'S'.
    MOVE-CORRESPONDING spconfs TO r_irsparams.
    APPEND r_irsparams.
  ENDLOOP.

  LOOP AT sens.
    r_irsparams-selname = 'SENS'.
    r_irsparams-kind = 'S'.
    MOVE-CORRESPONDING sens TO r_irsparams.
    APPEND r_irsparams.
  ENDLOOP.

  LOOP AT s_risk.
    r_irsparams-selname = 'S_RISK'.
    r_irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_risk TO r_irsparams.
    APPEND r_irsparams.
  ENDLOOP.

  r_irsparams-selname = 'SODVRSIO'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = sodvrsio.
  APPEND r_irsparams.

  r_irsparams-selname = 'SHOSUM'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = shosum.
  APPEND r_irsparams.


  r_irsparams-selname = 'SHODET'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = shodet.
  APPEND r_irsparams.

  r_irsparams-selname = 'PCOLOR'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = pcolor.
  APPEND r_irsparams.

  r_irsparams-selname = 'SHONOSOD'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = shonosod.
  APPEND r_irsparams.

  r_irsparams-selname = 'P_ENHANC'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = p_enhanc.
  APPEND r_irsparams.

  r_irsparams-selname = 'P_HIENHN'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = p_hienhn.
  APPEND r_irsparams.

  r_irsparams-selname = 'ORGCHK'.
  r_irsparams-kind = 'P'.
  r_irsparams-sign = 'I'.
  r_irsparams-option = 'EQ'.
  r_irsparams-low = orgchk.
  APPEND r_irsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  get_profiles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_profiles_count.
  DATA : lt_sing_prof TYPE TABLE OF ust10s WITH HEADER LINE,
         lt_comp_prof TYPE TABLE OF ust10c WITH HEADER LINE,
         lt_assnprof  TYPE TABLE OF ust10s WITH HEADER LINE,
         l_numb       TYPE i.

  CALL FUNCTION '/PSYNG/SW_GET_PROFILE'
    EXPORTING
      i_composite_prof = comprof
      i_single_prof    = sinprof
      i_assigned_prof  = asign_p
    IMPORTING
      e_count          = l_numb
    TABLES
      it_profiles      = prof.



  MESSAGE i137(/psyng/sw)
  WITH 'Number of profile(s) will be analyzed : ' l_numb.

ENDFORM.                    " get_profiles_count
