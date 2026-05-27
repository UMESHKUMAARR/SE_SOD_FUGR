*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_SOD_SUM_ROLE
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_sod_sum_role MESSAGE-ID /psyng/sw
LINE-SIZE 132.  "#EC SAST_CI_GEN_CHECK
INCLUDE /psyng/basis_exelog.
TYPE-POOLS:slis.
TABLES: agr_define,/psyng/conflict.
DATA:  gt_agr_define TYPE HASHED TABLE OF agr_define
                     WITH UNIQUE KEY agr_name WITH HEADER LINE.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv,
lf_initialized TYPE flag,
      g_current_user TYPE sy-uname. "C0700
DEFINE add_sel.
  &1-selname = &2.
  &1-kind    = &3.
  &1-sign    = &4.
  &1-option  = &5.
  &1-low     = &6.
  &1-high    = &7.
  append &1.
END-OF-DEFINITION.

INCLUDE /psyng/sw_config.
*INCLUDE /psyng/sw_125.

DATA: wa_gt_agr_define  TYPE agr_define.
DATA:  gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      g_role_count TYPE i.
RANGES : gr_conid FOR /psyng/conflict-conid.
DATA: scandt TYPE STANDARD TABLE OF /psyng/syscandt WITH HEADER LINE.
DATA: gt_function TYPE STANDARD TABLE OF /psyng/function WITH HEADER
LINE.
DATA: gt_iusgrpt TYPE STANDARD TABLE OF usgrpt WITH HEADER LINE.
DATA: gt_conflict TYPE STANDARD TABLE OF /psyng/conflict WITH HEADER
LINE,
      gt_conflict_sorted TYPE HASHED TABLE OF /psyng/conflict
      WITH UNIQUE KEY conid
      WITH HEADER LINE .
DATA: gt_cuscon TYPE STANDARD TABLE OF /psyng/sw_cuscon
      WITH HEADER LINE.
DATA: go_classtype TYPE REF TO cl_abap_typedescr,
      gs_config    TYPE /psyng/swconfig,
      g_i_fieldcat_alv  TYPE slis_t_fieldcat_alv,
      g_lmit_count TYPE i,
      g_lconf_count TYPE i,
      g_laverage_count TYPE i,
      g_lconf_countc(6) TYPE c,
      g_role_countc(6) TYPE c,
      g_laverage_countc(4) TYPE c,
      ls_ba_role           type /PSYNG/BC_BA_00.
DATA :
gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       gt_conid TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
       lt_cuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE.

*-- Selection Screen
SELECTION-SCREEN: BEGIN OF BLOCK sel WITH FRAME TITLE text-001.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  63(12) text-198 USER-COMMAND verify_r
                                      MODIF ID rol.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-009 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS: s_role FOR agr_define-agr_name MODIF ID rol.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-084 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
select-options : rba for ls_ba_role-busarea.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(23) text-013 MODIF ID rol.
*SELECTION-SCREEN: POSITION 32.
PARAMETERS:   rchdatf LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN: COMMENT 47(3) text-014 MODIF ID rol.
SELECTION-SCREEN: POSITION 53.
PARAMETERS:   rchdatt LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN PUSHBUTTON  65(10) text-019 USER-COMMAND shrl
MODIF ID rol.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : singrol TYPE flag DEFAULT 'X' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-161 FOR FIELD singrol
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : comprol TYPE flag DEFAULT 'X' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-162 FOR FIELD comprol
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.


SELECTION-SCREEN: POSITION 4.
PARAMETERS : asign_r TYPE flag DEFAULT ' ' MODIF ID rol.
SELECTION-SCREEN: COMMENT 7(47) text-166 FOR FIELD asign_r
                                         MODIF ID rol.
SELECTION-SCREEN: END OF LINE.

PARAMETERS : sodvrsio LIKE /psyng/conflict-vrsio.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid,
                s_busa  FOR /psyng/conflict-busarea,
                s_imp   FOR /psyng/conflict-imp,
                s_risk  FOR /psyng/conflict-risk.
SELECTION-SCREEN: SKIP 1.


SELECTION-SCREEN: END OF BLOCK sel.


SELECTION-SCREEN: BEGIN OF BLOCK disp WITH FRAME TITLE text-029.
PARAMETERS : p_o_con TYPE flag RADIOBUTTON GROUP g2 USER-COMMAND a
DEFAULT 'X'.
PARAMETERS : p_o_rol TYPE flag RADIOBUTTON GROUP g2.
PARAMETERS : p_o_det TYPE flag RADIOBUTTON GROUP g2.
PARAMETERS : p_con   TYPE flag AS CHECKBOX DEFAULT 'X',
             p_none  TYPE flag AS CHECKBOX DEFAULT 'X',
             p_noinf TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN : SKIP 1.


SELECTION-SCREEN: END OF BLOCK disp.


SELECTION-SCREEN: BEGIN OF BLOCK prer WITH FRAME TITLE text-002.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-003.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-004.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-005.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: END OF BLOCK prer .
PARAMETERS : drill TYPE flag NO-DISPLAY. "marks if this is a drilldown
*....
TYPES: BEGIN OF typ_roletxt,
         agr_name LIKE /psyng/user_role_exe-agr_name,
         text LIKE agr_texts-text,
       END OF typ_roletxt.

DATA: gt_roletxt TYPE SORTED TABLE OF typ_roletxt
      WITH UNIQUE KEY agr_name
      WITH HEADER LINE.
DATA: gt_scandt TYPE STANDARD TABLE OF /psyng/syscandt2
      WITH HEADER LINE.

DATA: BEGIN OF output_con OCCURS 0,
        busarea LIKE /psyng/conflict-busarea,
        imp LIKE /psyng/conflict-imp,
        conid LIKE /psyng/conflict-conid,
        con_text LIKE /psyng/conflict-description,
        count TYPE i,
     END OF output_con.
DATA: BEGIN OF output_role OCCURS 0,
          agr_name LIKE /psyng/syscandt2-agr_name,
          text LIKE agr_texts-text,
        count TYPE i,
     END OF output_role.
DATA: BEGIN OF output_detail OCCURS 0,
          agr_name LIKE /psyng/syscandt2-agr_name,
          text LIKE agr_texts-text,
        busarea LIKE /psyng/conflict-busarea,
        imp LIKE /psyng/conflict-imp,
        conid LIKE /psyng/conflict-conid,
        con_text LIKE /psyng/conflict-description,
        count TYPE i,
     END OF output_detail.
DATA: BEGIN OF gt_agr OCCURS 0,
        agr_name TYPE agr_name,
     END OF gt_agr.

INITIALIZATION.
*  PERFORM exelog.
* BOC by RGUPTA for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA for C0700
AT SELECTION-SCREEN.
  PERFORM check_input.

AT SELECTION-SCREEN OUTPUT.

*If the configuration setting SW_ENH_SCAN_TBL = Y,
*The radiobuttons to choose between standard and enhanced ruleset
*are shown
  se_config_param 'SW_ENH_SCAN_TBL' gs_config-value.
  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'P_CON' OR 'P_NONE' OR 'P_NOINF'.
        IF p_o_det <> 'X'.
          screen-input    = 0.
        ELSE.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.

    ENDCASE.


  ENDLOOP.



START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

refresh : gt_agr_define.

  SELECT      conid owner description busarea imp
  FROM       /psyng/conflict
  INTO CORRESPONDING FIELDS OF TABLE gt_conid
  WHERE vrsio   = sodvrsio
  AND conid     IN s_conid
  AND imp       IN s_imp
  AND risk      IN s_risk
  AND busarea   IN s_busa.
  MESSAGE s002 WITH 'Loading Conflict Definitions'.
  COMMIT WORK.

*--Also select the custom conflicts

  SELECT conid busarea imp cdesc FROM /psyng/sw_cuscon
  APPENDING CORRESPONDING FIELDS OF TABLE lt_cuscon
  WHERE vrsio = sodvrsio
  AND   inactive <> 'X'
  AND   conid IN s_conid
  AND   imp   IN s_imp
  AND   busarea IN s_busa.

  IF gt_conid[] IS INITIAL AND lt_cuscon[] IS INITIAL
  AND p_noinf IS INITIAL.
*--Selection of conflicts showed no conflicts
  MESSAGE i135(/psyng/sw) WITH 'No Conflict ID(s) match selection'(033).
    LEAVE LIST-PROCESSING.
  ELSE.
*--Create a conflict range
    gr_conid-sign   = 'I'.
    gr_conid-option = 'EQ'.
    LOOP AT gt_conid.
      gr_conid-low = gt_conid-conid.
      APPEND gr_conid.
    ENDLOOP.
    LOOP AT lt_cuscon.
      gr_conid-low = lt_cuscon-conid.
      APPEND gr_conid.
    ENDLOOP.
  ENDIF.
  PERFORM filter_role.
*--Summary Output Mode
  IF p_o_con = 'X'.
*--Log execution.
    exelog sy-repid 'CONFLICTSUMMARY'.
*--Execute
    PERFORM conflict_summary.
  ELSEIF p_o_rol = 'X'.
*--Log execution.
    exelog sy-repid 'ROLESUMMARY'.
    PERFORM role_summary.
  ELSE.
*--Log execution.
    exelog sy-repid 'DETAILS'.
*--Detailed output mode
    IF p_con = 'X'.

      MESSAGE s002 WITH 'Loading Conflicts from Scan table'.
      COMMIT WORK.
*get all users WITH c
    ENDIF.
    PERFORM conflict_detail.
  ENDIF.
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

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_role_count                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_role_count.

  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
       EXPORTING
            i_composite_roles = comprol
            i_single_roles    = singrol
            i_assigned_roles  = asign_r
            i_rchdatf         = rchdatf
            i_rchdatt         = rchdatt
       IMPORTING
            e_count           = g_role_count
       TABLES
            it_roles          = s_role
            it_ba             = rba.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  conflict_summary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conflict_summary.
  FIELD-SYMBOLS : <out> LIKE output_con.

  PERFORM load_conflict_scan.

  LOOP AT gt_scandt.
    READ TABLE gt_agr_define WITH TABLE KEY
    agr_name = gt_scandt-agr_name.
    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.
    gt_agr-agr_name = gt_scandt-agr_name.
    output_con-conid = gt_scandt-conid.
    output_con-count = 1.
    ADD 1 TO g_lconf_count.
    COLLECT gt_agr.
    COLLECT output_con.
  ENDLOOP.
*--Add conflict Texts
  gt_conflict_sorted[] = gt_conid[].
  LOOP AT output_con ASSIGNING <out>.
    READ TABLE gt_conflict_sorted
    WITH TABLE KEY conid = <out>-conid.
    IF sy-subrc = 0.
      <out>-con_text = gt_conflict_sorted-description.
      <out>-busarea  = gt_conflict_sorted-busarea.
      <out>-imp      = gt_conflict_sorted-imp.

    ELSE.
*       custom conflict
      READ TABLE gt_cuscon WITH KEY conid = <out>-conid
      BINARY SEARCH.
      IF sy-subrc = 0.
        <out>-con_text = gt_cuscon-cdesc.
        <out>-busarea  = gt_cuscon-busarea.
        <out>-imp      = gt_cuscon-imp.
      ENDIF.
    ENDIF.
  ENDLOOP.

  PERFORM output_alv_con.

ENDFORM.                    " conflict_summary

*---------------------------------------------------------------------*
*       FORM LOAD_CONFLICT_SCAN                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM load_conflict_scan.

  SELECT * FROM /psyng/syscandt2
         INTO CORRESPONDING FIELDS OF TABLE gt_scandt
         WHERE agr_name IN s_role AND
               vrsio =  sodvrsio AND
               conid IN gr_conid.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM output_alv_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM output_alv_con.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT_CON'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table_con.
  PERFORM adjust_columns_con.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER_CON'
*            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_CLICK_CON'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output_con
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

ENDFORM.                    " output_alv

*---------------------------------------------------------------------*
*       FORM build_sort_table_con                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table_con.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ' '.
  APPEND l_sort TO isort.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM adjust_columns_con                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM adjust_columns_con.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.
  wa_fieldcat_alv-seltext_l = text-h20.
  wa_fieldcat_alv-seltext_m = text-h20.
  wa_fieldcat_alv-seltext_s = text-h20.
  wa_fieldcat_alv-reptext_ddic = text-h20.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_COUNT'.
*--Add hotspots
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    hotspot
                WHERE fieldname = 'BUSAREA' OR
                      fieldname = 'CONID'.
*--Enable subtotal counting
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    do_sum
                WHERE fieldname = 'COUNT'.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM alv_header_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header_con.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_exedate(10),
        l_exetime(8) TYPE c,
        l_alv_grid_titl2   TYPE lvc_title,
        l_role_total TYPE i,
        l_role_totalc(20) TYPE c,
        l_mandt TYPE sy-mandt,
        l_sysid TYPE sy-sysid,
        l_systemid TYPE /psyng/sysid. "C1102 AKUMAR

  IF g_role_count IS INITIAL.
    PERFORM get_role_count.
  ENDIF.
*  g_lconf_count = g_lconf_count + g_lmit_count.

  DESCRIBE TABLE gt_agr LINES l_role_total.
  IF g_role_count > 0.
    g_laverage_count = g_lconf_count / l_role_total.
  ENDIF.

  g_laverage_countc = g_laverage_count.
  g_role_countc = l_role_total.
*  g_lmit_countc = g_lmit_count.
  g_lconf_countc = g_lconf_count.
  l_role_totalc = g_role_count.


  wa-typ = 'H'.
  wa-info = 'Segregation of Duties Summary Report'(h01).
  APPEND wa TO header.

*--sysid mandt
  CALL FUNCTION 'SCCR_GET_RELEASE_NR'
       IMPORTING
            sysid = l_sysid
            mandt = l_mandt. "#EC SAST_CI_GEN_CHECK
  wa-typ = 'S'.
  wa-key = 'System:'(h34).
  CONCATENATE l_sysid l_mandt INTO wa-info.
  CONDENSE wa-info.
  APPEND wa TO header.

  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date

  wa-typ = 'S'.
  wa-key = text-h11.
  WRITE sy-datum TO l_exedate.
*  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
*              INTO exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

   CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

*  CONCATENATE sy-uname text-h12 l_exedate l_exetime "C0700
  CONCATENATE g_current_user text-h12 l_exedate l_exetime
  text-199 l_systemid "C0700
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CONCATENATE  l_role_totalc 'Role(s) analyzed.'(h24)
            INTO l_alv_grid_titl2 SEPARATED BY space.
  CONDENSE l_alv_grid_titl2.

  wa-typ = 'S'.
  wa-key = 'Summary:'(h23).
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.


  CONCATENATE 'Avg'(h30) g_laverage_countc 'SOD Conflict(s) in'(h25)
           g_role_countc 'role(s)'(h29)
           INTO l_alv_grid_titl2 SEPARATED BY space.
  wa-typ = 'S'.
  wa-key = ''.
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.



*--Add some of the selection criteria to the header,
*  but only if it was a drilldown
  DATA : l_linecount TYPE i.
*--Application Area Drilldown
  IF NOT s_busa[] IS INITIAL.
    DESCRIBE TABLE s_busa LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_busa.
        wa-typ = 'S'.
        wa-key = 'Application Area:'(h40).
        IF s_busa-sign = 'I' AND s_busa-option = 'EQ'.
          wa-info = s_busa-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*--Conflict
  IF NOT s_conid[] IS INITIAL.
    DESCRIBE TABLE s_conid LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_conid.
        wa-typ = 'S'.
        wa-key = 'Conflict ID:'(h32).
        IF s_conid-sign = 'I' AND s_conid-option = 'EQ'.
          wa-info = s_conid-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE w190(/psyng/sw).
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM user_click_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_click_con USING r_ucomm LIKE sy-ucomm
                      rs_selfield TYPE slis_selfield.
  DATA :  lt_seltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  READ TABLE output_con INDEX rs_selfield-tabindex.

  CASE rs_selfield-fieldname.
    WHEN 'BUSAREA'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'S_BUSA' OR selname = 'P_O_CON'.
      add_sel lt_seltab 'S_BUSA'  'S' 'I' 'EQ' rs_selfield-value ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' ''  ''.
      add_sel lt_seltab 'P_O_ROL' 'P' 'I' 'EQ' 'X' ''.
      add_sel lt_seltab 'P_FLAG'  'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_role WITH SELECTION-TABLE lt_seltab
      AND RETURN.
    WHEN 'CONID'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'S_CONID' OR selname = 'P_O_CON'.
      DELETE lt_seltab WHERE selname = 'S_RISK'.
      add_sel lt_seltab 'S_CONID' 'S' 'I' 'EQ' rs_selfield-value ''.
*      add_sel lt_seltab 'S_RISK'  'S' 'I' 'EQ' output_con-imp ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' ''  ''.
      add_sel lt_seltab 'P_O_ROL' 'P' 'I' 'EQ' 'X' ''.
      add_sel lt_seltab 'P_FLAG'  'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_role WITH SELECTION-TABLE lt_seltab
      AND RETURN.
  ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM user_click_role                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_click_role USING r_ucomm LIKE sy-ucomm
                      rs_selfield TYPE slis_selfield.
  DATA :  lt_seltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  READ TABLE output_role INDEX rs_selfield-tabindex.

*  CASE rs_selfield-fieldname.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'S_ROLE'.
      add_sel lt_seltab 'S_ROLE'  'S' 'I' 'EQ' output_role-agr_name ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' ''  ''.
      add_sel lt_seltab 'P_O_ROL' 'P' 'I' 'EQ' ''  ''.
      add_sel lt_seltab 'P_O_DET' 'P' 'I' 'EQ' 'X' ''.
      add_sel lt_seltab 'P_FLAG'  'P' 'I' 'EQ' 'X' ''.

      SUBMIT /psyng/sw_sod_sum_role WITH SELECTION-TABLE lt_seltab
      AND RETURN.
*  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_current_selection                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SELTAB                                                     *
*---------------------------------------------------------------------*
FORM get_current_selection TABLES et_seltab STRUCTURE rsparams.



  CALL FUNCTION 'RS_REFRESH_FROM_SELECTOPTIONS'
       EXPORTING
            curr_report     = '/PSYNG/SW_SOD_SUM_ROLE'
       TABLES
            selection_table = et_seltab
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             NOT_FOUND = 1
             NO REPORT = 2
             OTHERS    = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ROLE_summary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_summary.
  FIELD-SYMBOLS : <out> LIKE output_role.

  PERFORM load_conflict_scan.
  LOOP AT gt_scandt.
    READ TABLE gt_agr_define WITH TABLE KEY
    agr_name = gt_scandt-agr_name.
    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.
    gt_agr-agr_name = gt_scandt-agr_name.
    output_role-agr_name = gt_scandt-agr_name.
    output_role-count = 1.
    ADD 1 TO g_lconf_count.
    COLLECT gt_agr.
    COLLECT output_role.
  ENDLOOP.
*--Add Role Texts
  PERFORM get_role_text.
  SORT output_role BY agr_name.

  LOOP AT output_role ASSIGNING <out>.
    READ TABLE gt_roletxt
    WITH TABLE KEY agr_name = <out>-agr_name.
    IF sy-subrc = 0.
      <out>-text = gt_roletxt-text.
    ENDIF.
  ENDLOOP.

  PERFORM output_alv_role.

ENDFORM.                    " ROLE_summary

*---------------------------------------------------------------------*
*       FORM get_role_text                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_role_text.

  RANGES lt_role FOR /psyng/syscandt2-agr_name.

  IF p_noinf IS INITIAL.
    lt_role-sign = 'I'.
    lt_role-option = 'EQ'.
    LOOP AT gt_agr.
      lt_role-low = gt_agr-agr_name.
      APPEND lt_role.
    ENDLOOP.
  ELSE.
    lt_role[] = s_role[].
  ENDIF.
  SELECT agr_name text
         INTO (gt_roletxt-agr_name, gt_roletxt-text)
         FROM agr_texts
         WHERE agr_name IN lt_role AND
               spras = sy-langu   AND
               line = '00000'
               .
    INSERT gt_roletxt INTO TABLE gt_roletxt.
  ENDSELECT.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM output_alv_role                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM output_alv_role.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT_ROLE'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table_role.
  PERFORM adjust_columns_role.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER_CON'
*            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_CLICK_ROLE'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output_role
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

ENDFORM.                    " output_alv

*---------------------------------------------------------------------*
*       FORM build_sort_table_role                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table_role.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname   = 'OUTPUT_ROLE'.
  l_sort-up        = 'X'.
*  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM adjust_columns_role                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM adjust_columns_role.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.

*--Add hotspots
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    hotspot
                WHERE fieldname = 'AGR_NAME'.
*--Enable subtotal counting
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    do_sum
                WHERE fieldname = 'COUNT'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  conflict_detail
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conflict_detail.
  FIELD-SYMBOLS : <out> LIKE  output_detail.
*  PERFORM load_conflict_scan.
  PERFORM load_conflict_opt.
  LOOP AT gt_scandt.
    READ TABLE gt_agr_define WITH TABLE KEY
    agr_name = gt_scandt-agr_name.
    IF sy-subrc NE 0.
      CONTINUE.
    ENDIF.
    gt_agr-agr_name = gt_scandt-agr_name.
    output_detail-agr_name = gt_scandt-agr_name.
    output_detail-conid = gt_scandt-conid.
    output_detail-count = 1.
    ADD 1 TO g_lconf_count.
    COLLECT gt_agr.
    COLLECT output_detail.
  ENDLOOP.
*--Add conflict and role Texts
  PERFORM get_role_text.
  IF p_noinf = 'X'.
    LOOP AT gt_roletxt.
      READ TABLE gt_agr_define WITH TABLE KEY
      agr_name = gt_roletxt-agr_name.
      IF sy-subrc NE 0.
        CONTINUE.
      ENDIF.
      READ TABLE gt_agr WITH KEY agr_name = gt_roletxt-agr_name.
      IF sy-subrc NE 0.
        clear output_detail.
        output_detail-agr_name = gt_roletxt-agr_name.
        output_detail-text = gt_roletxt-text.
        APPEND output_detail.
        DELETE gt_roletxt.
      ENDIF.

    ENDLOOP.
  ENDIF.

  gt_conflict_sorted[] = gt_conid[].
  LOOP AT output_detail ASSIGNING <out>.
    READ TABLE gt_conflict_sorted
    WITH TABLE KEY conid = <out>-conid.
    IF sy-subrc = 0.
      <out>-con_text = gt_conflict_sorted-description.
      <out>-busarea  = gt_conflict_sorted-busarea.
      <out>-imp      = gt_conflict_sorted-imp.

    ELSE.
*--Custom conflict
      READ TABLE gt_cuscon WITH KEY conid = <out>-conid
      BINARY SEARCH.
      IF sy-subrc = 0.
        <out>-con_text = gt_cuscon-cdesc.
        <out>-busarea  = gt_cuscon-busarea.
        <out>-imp      = gt_cuscon-imp.
      ENDIF.
    ENDIF.
*--Add role name
    READ TABLE gt_roletxt
    WITH TABLE KEY agr_name = <out>-agr_name.
    IF sy-subrc = 0.
      <out>-text = gt_roletxt-text.
    ENDIF.
  ENDLOOP.

  PERFORM output_alv_role_dtl.


ENDFORM.                    " conflict_detail
*&---------------------------------------------------------------------*
*&      Form  load_conflict_opt
*&---------------------------------------------------------------------*

FORM load_conflict_opt.
  IF p_con IS INITIAL.
    REFRESH gr_conid[].
  ENDIF.
  IF p_none = 'X'.
    gr_conid-sign   = 'I'.
    gr_conid-option = 'EQ'.
    gr_conid-low = 'NONE'.
    APPEND gr_conid.
  ENDIF.
  IF NOT gr_conid[] IS INITIAL or p_con is initial.
    SELECT * FROM /psyng/syscandt2
         INTO CORRESPONDING FIELDS OF TABLE gt_scandt
         WHERE agr_name IN s_role AND
               vrsio =  sodvrsio AND
               conid IN gr_conid.
  ENDIF.
  IF p_noinf IS INITIAL AND gt_scandt[] IS INITIAL.
    MESSAGE i135(/psyng/sw) WITH
    'No Conflict ID(s)  match selection'(033).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    "load_conflict_opt
*---------------------------------------------------------------------*
*       FORM output_alv_role_dtl
*
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM output_alv_role_dtl.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT_DETAIL'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table_detail.
  PERFORM adjust_columns_detail.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER_CON'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output_detail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

ENDFORM.                    " output_alv_role_dtl

*---------------------------------------------------------------------*
*       FORM build_sort_table_detail                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table_detail.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TEXT'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ''.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ' '.
  APPEND l_sort TO isort.

  l_sort-fieldname = 'CON_TEXT'.
  l_sort-tabname   = 'OUTPUT_DETAIL'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ' '.
  APPEND l_sort TO isort.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM adjust_columns_detail
*
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM adjust_columns_detail.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.

*--Enable subtotal counting
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    do_sum
                WHERE fieldname = 'COUNT'.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_input.

  IF sy-ucomm = 'SHRL'.
    PERFORM show_roles_based_on_dates.
  ENDIF.

  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    EXIT.
  ENDIF.
  IF  NOT rchdatf IS INITIAL.
    IF rchdatt IS INITIAL .
      rchdatt = '99991231'.
    ENDIF.
    IF rchdatf > rchdatt.
      SET CURSOR FIELD 'RCHDATT'.
      MESSAGE e650(db).
    ENDIF.
  ENDIF.

  IF comprol IS INITIAL AND singrol IS INITIAL.
    IF sy-batch IS INITIAL.
      MESSAGE e208(00) WITH
      'Select either Composite or Single Roles or both'(163).
    ELSE.
*--If old variants are used that have none of these options,
*  select both
      MESSAGE s208(00) WITH
      'Analyzing Composite and Single Roles'(164).
    ENDIF.
  ENDIF.

ENDFORM.                    " check_input

*---------------------------------------------------------------------*
*       FORM show_roles_based_on_dates                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM show_roles_based_on_dates.
  DATA: tagr_define LIKE agr_define OCCURS 0 WITH HEADER LINE.
  DATA: ifield_dif LIKE field_dif OCCURS 0 WITH HEADER LINE.
  DATA: lv_header(80),
        lv_count TYPE i,
        lv_count_char(9).

  DATA: lt_roles TYPE TABLE OF /psyng/comp_role_tcode,
        ls_roles TYPE /psyng/comp_role_tcode,
        lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_range_roles TYPE /psyng/range_agr_name.

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH text-070.
    EXIT.
  ENDIF.
  REFRESH tagr_define.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
              i_get_actual_data = 'X'
         TABLES
              it_roles          = s_role
              it_ba             = rba
              et_roles          = lt_roles.
    ls_range_roles-sign   = 'I'.
    ls_range_roles-option = 'EQ'.
  LOOP AT lt_roles INTO ls_roles.
    ls_range_roles-low = ls_roles-agr_name.
    APPEND ls_range_roles TO lt_range_roles.
  ENDLOOP.
  IF lt_range_roles IS NOT INITIAL.
  SELECT agr_name create_dat change_usr change_dat change_tim
             INTO CORRESPONDING FIELDS OF wa_gt_agr_define
             FROM agr_define
             WHERE agr_name IN lt_range_roles.
    IF rchdatf IS INITIAL.
      INSERT wa_gt_agr_define INTO TABLE tagr_define.
    ELSE.
      IF wa_gt_agr_define-change_dat IS INITIAL.
        CHECK wa_gt_agr_define-create_dat >= rchdatf AND
              wa_gt_agr_define-create_dat <= rchdatt.
        INSERT wa_gt_agr_define INTO TABLE tagr_define.
      ELSE.
        CHECK wa_gt_agr_define-change_dat >= rchdatf AND
              wa_gt_agr_define-change_dat <= rchdatt.
        INSERT wa_gt_agr_define INTO TABLE tagr_define.
      ENDIF.
    ENDIF.
  ENDSELECT.
  ENDIF.

  IF NOT tagr_define[] IS INITIAL.
  ifield_dif-tabname = 'AGR_DEFINE'.
  ifield_dif-fieldname = 'PARENT_AGR'.
  ifield_dif-no_display = 'X'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_USR'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_DAT'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_TIM'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CREATE_TMP'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'CHANGE_TMP'.
  APPEND ifield_dif.
  ifield_dif-fieldname = 'ATTRIBUTES'.
  APPEND ifield_dif.

  DESCRIBE TABLE tagr_define LINES lv_count.
  MOVE lv_count TO lv_count_char.
  CONCATENATE lv_count_char text-134 INTO lv_header
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
       EXPORTING
            header         = lv_header
            tabname        = 'AGR_DEFINE'
            display_only   = 'X'
            endless        = 'X'
            display_toggle = 'X'
            no_insert      = 'X'
            no_delete      = 'X'
            no_move        = 'X'
            no_undo        = 'X'
            no_button      = 'X'
            x_end          = 90
       TABLES
            table          = tagr_define
            fielddif       = ifield_dif
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             NO_MORE_TABLES   = 1
             TOO_MANY_FIELDS = 2
             NAMETAB_NOT_VALID = 3
             HANDLE_NOT_VALID  = 4
             OTHERS          = 5 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  ELSE.
    MESSAGE i002 WITH 'No valid roles found'(n03).
    EXIT.
  ENDIF.
ENDFORM.                    " show_roles_based_on_dates
*&---------------------------------------------------------------------*
*&      Form  get_roles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count.
  DATA : l_numb TYPE i.

  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
       EXPORTING
            i_composite_roles = comprol
            i_single_roles    = singrol
            i_assigned_roles  = asign_r
            i_rchdatf         = rchdatf
            i_rchdatt         = rchdatt
       IMPORTING
            e_count           = l_numb
       TABLES
            it_roles          = s_role
            it_ba             = rba.

  MESSAGE i002 WITH 'Number of roles(s) will be analyzed : ' l_numb.

ENDFORM.                    " get_roles_count
*&---------------------------------------------------------------------*
*&      Form  filter_role
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM filter_role.

  DATA: ls_agr_define TYPE agr_define,
        lt_agr_define TYPE TABLE OF agr_define WITH HEADER LINE,
        wa_agr_users TYPE agr_users,
        lt_roles type table of /PSYNG/BUSAREA_ROLE with header line.
*--Get selected roles
  REFRESH gt_agr_define.

*CALL FUNCTION '/PSYNG/SW_GET_ROLES'
CALL FUNCTION '/PSYNG/BC_071'
 EXPORTING
   IF_COMPOSITE       = comprol
   IF_SINGLE          = singrol
   IF_ASSIGNED        = asign_r
   I_CHANGE_FROM_DATE               = rchdatf
   I_CHANGE_TO_DATE               = rchdatt
*   I_GET_ACTUAL_DATA       = 'X'
 TABLES
   IT_ROLES                = s_role
   IT_BUSAREA              = rba
   ET_busarea_ROLE         =  lt_roles.
  loop at  lt_roles.
    ls_agr_define-agr_name = lt_roles-agr_name.
    insert ls_agr_define into table gt_agr_define.
  endloop.
*  insert lines of lt_agr_define into table gt_agr_define.
ENDFORM.                    " filter_role
