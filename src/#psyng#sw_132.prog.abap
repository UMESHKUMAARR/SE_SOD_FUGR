*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_132
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/132.
TYPE-POOLS: slis.
INCLUDE : /PSYNG/SW_CONFIG.
TABLES: /psyng/mcrvwsgn, /psyng/sw_mc_review_report.
TYPES:  t_layout   TYPE slis_layout_alv.

DATA: gw_fieldcat TYPE  slis_t_fieldcat_alv WITH HEADER LINE,
      gt_fieldcat TYPE slis_t_fieldcat_alv.

DATA: gt_summary TYPE STANDARD TABLE OF /psyng/mcrvwsgn,
      gt_details TYPE  /psyng/sw_mc_review_report OCCURS 0,
      gw_details  TYPE /psyng/sw_mc_review_report,
      gw_summary  TYPE /psyng/mcrvwsgn,
      g_program    LIKE sy-repid.

DATA: BEGIN OF gt_mcauditor OCCURS 0.
        INCLUDE STRUCTURE /psyng/mcauditor.
DATA:   comp_name(20) TYPE c,
        sel TYPE /psyng/flagx,
      END OF gt_mcauditor.
DATA: gi_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      g_dynnr LIKE sy-dynnr,
      gs_signoff TYPE /psyng/mcrvwsgn.
DATA: gt_list TYPE TABLE OF /psyng/mcrvwtxt WITH HEADER LINE,
      gt_detail TYPE TABLE OF /psyng/mcrvwtxt WITH HEADER LINE.

DATA : g_container   TYPE REF TO cl_gui_custom_container,
       text_editor TYPE REF TO cl_gui_textedit,
       lt_texttab  TYPE soli_tab.
DATA: gt_isort TYPE STANDARD TABLE OF slis_sortinfo_alv,
      lf_disable TYPE flag.
DATA :
BEGIN OF new_line,
        x(2) TYPE x VALUE '0D0A',
END OF new_line,
BEGIN OF new_line2,
        x(2) TYPE x VALUE '0A0A',
END OF new_line2,
 go_just_container   TYPE REF TO cl_gui_custom_container,
       go_just_editor TYPE REF TO cl_gui_textedit,
       gt_just_text   TYPE TABLE OF /psyng/longtextfield
       WITH HEADER LINE,
s_new_line(2) TYPE c,
s_new_line2(2) TYPE c,
gf_mit_by_org type c,
g_current_user type sy-uname. "C0629

SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: PUSHBUTTON 71(10) text-020 USER-COMMAND cli2.
SELECTION-SCREEN: END OF LINE.
SELECT-OPTIONS: s_id  FOR /psyng/mcrvwsgn-SIGNOFFID.
SELECT-OPTIONS: s_rev FOR /psyng/mcrvwsgn-auditor.
SELECT-OPTIONS: s_sod FOR /psyng/sw_mc_review_report-vrsio.
SELECT-OPTIONS: s_per FOR /psyng/mcrvwsgn-from_date.
SELECT-OPTIONS: s_mit FOR /psyng/mcrvwsgn-contid.
PARAMETERS: p_uns AS CHECKBOX DEFAULT 'X',
            p_ars AS CHECKBOX,
            p_mrs AS CHECKBOX.
SELECTION-SCREEN: END OF BLOCK b1.

SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE text-t02.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_uas TYPE flag AS CHECKBOX DEFAULT 'X' USER-COMMAND chk.
SELECTION-SCREEN COMMENT 3(20) text-uas .
SELECTION-SCREEN : POSITION 30.
SELECT-OPTIONS: s_uas FOR /psyng/mcrvwsgn-userid MODIF ID uas.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_ras TYPE flag AS CHECKBOX DEFAULT 'X' USER-COMMAND ch.
SELECTION-SCREEN COMMENT 3(20) text-ras .
SELECTION-SCREEN : POSITION 30.
SELECT-OPTIONS: s_ras FOR /psyng/mcrvwsgn-agr_name MODIF ID ras.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_cus TYPE flag AS CHECKBOX DEFAULT 'X' USER-COMMAND ch.
SELECTION-SCREEN COMMENT 3(20) text-cus .
SELECTION-SCREEN : POSITION 30.
SELECT-OPTIONS: s_cus FOR /psyng/mcrvwsgn-userid MODIF ID cus.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : p_crs TYPE flag AS CHECKBOX DEFAULT 'X' USER-COMMAND ch.
SELECTION-SCREEN COMMENT 3(20) text-crs .
SELECTION-SCREEN : POSITION 30.
SELECT-OPTIONS: s_crs FOR /psyng/mcrvwsgn-agr_name MODIF ID crs.
SELECTION-SCREEN: END OF LINE.



*SELECT-OPTIONS:
**                s_ras FOR /psyng/mcrvwsgn-agr_name,
*                s_cus FOR /psyng/mcrvwsgn-userid,
*                s_crs FOR /psyng/mcrvwsgn-agr_name.

SELECTION-SCREEN: END OF BLOCK b2.

INITIALIZATION.

*--odubey 27.01.2022  C0629
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
*--end
AT SELECTION-SCREEN OUTPUT.

  DEFINE macro_clear_sel.
    if lf_disable = 'X' and screen-input = '1'.
      refresh &1.
      &1-sign   = 'E'.
      &1-option = 'CP'.
      &1-low    = '*'.
      append &1.
    elseif lf_disable <> 'X' and screen-input = '0' .
      delete &1 where
        SIGN   = 'E'  and
        OPTION = 'CP' and
        LOW    = '*'.
*      refresh &1.
    endif.
  END-OF-DEFINITION.

  LOOP AT SCREEN.
    CLEAR lf_disable.
    CASE screen-group1.
      WHEN 'UAS'.
        IF p_uas <> 'X'.
          lf_disable = 'X'.
        ENDIF.
        macro_clear_sel s_uas.
      WHEN 'RAS'.
        IF p_ras <> 'X'.
          lf_disable = 'X'.
        ENDIF.
        macro_clear_sel s_ras.
      WHEN 'CUS'.
        IF p_cus <> 'X'.
          lf_disable = 'X'.
        ENDIF.
        macro_clear_sel s_cus.
      WHEN 'CRS'.
        IF p_crs <> 'X'.
          lf_disable = 'X'.
        ENDIF.
        macro_clear_sel s_crs.

    ENDCASE.

    IF lf_disable = 'X'.
      screen-input = '0'.
    ENDIF.
    MODIFY SCREEN.

  ENDLOOP.


AT SELECTION-SCREEN.
  IF sy-ucomm = 'CLI2'.
    REFRESH s_rev.
    CLEAR s_rev.
    s_rev-low =  g_current_user. "sy-uname.
    s_rev-sign = 'I'.
    s_rev-option = 'EQ'.
    APPEND s_rev.
  ENDIF.

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
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.
  PERFORM get_data.
*  PERFORM build_data.

END-OF-SELECTION.
  PERFORM build_fieldcat.
  PERFORM adjust_fieldcat.
  PERFORM build_sort_table.
  PERFORM display_data.
*&---------------------------------------------------------------------*
*&      Form  GET_DATA
*&---------------------------------------------------------------------*
*       get data
*----------------------------------------------------------------------*
FORM get_data.
  DATA: v_unrev TYPE flag,
        v_aurev TYPE flag,
        v_marev TYPE flag.
  DATA: lt_summary TYPE STANDARD TABLE OF /psyng/mcrvwsgn,
        lt_details TYPE  /psyng/sw_mc_review_report OCCURS 0.
  MOVE: p_uns TO v_unrev,
        p_ars TO v_aurev,
        p_mrs TO v_marev.
  CALL FUNCTION '/PSYNG/SW_MC_REVIEW_REPORT'
       EXPORTING
            if_unreviewed   = v_unrev
            if_autoreviewed = v_aurev
            if_manreviewed  = v_marev
            i_bname         = g_current_user "sy-uname
       TABLES
            it_signoffid    = s_id
            it_auditor      = s_rev
            it_period       = s_per
            it_soduser      = s_uas
            it_causer       = s_cus
            it_sodrole      = s_ras
            it_carole       = s_crs
            it_versions     = s_sod
            it_contid       = s_mit
            et_summary      = gt_summary
            et_details      = gt_details.

  IF sy-subrc NE 0.

  ENDIF.
ENDFORM.                    " GET_DATA
*&---------------------------------------------------------------------*
*&      Form  BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_fieldcat.
  g_program = sy-repid.
  REFRESH gt_fieldcat.
*  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
*       EXPORTING
*            i_program_name     = g_program
*            i_internal_tabname = 'GT_DETAILS'
*            i_inclname         = g_program
*       CHANGING
*            ct_fieldcat        = gt_fieldcat[].µ

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
*            i_program_name     = g_program
            i_structure_name = '/PSYNG/SW_MC_REVIEW_REPORT'
*            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gt_fieldcat[]
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
ENDFORM.                    " BUILD_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_DATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_data.
  DATA : ls_alv_layout TYPE slis_layout_alv,
         ls_variant    TYPE disvariant.
  g_program = sy-repid.
  SORT gt_details BY auditor auditor_name contid contid_desc vrsio
       assign_type assign_id assign_desc target_type target_id
       target_desc from_date to_date tcode_executed changes_made
       am_alerts_open signoff_date signoff_time signoff_complete
       just attachment review signoff_type.

*--Adjust ALV Layout
  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program      = g_program
            i_callback_user_command = 'USER_COMMAND'
            is_layout               = ls_alv_layout
            it_fieldcat             = gt_fieldcat
            it_sort                 = gt_isort
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = gt_details
       EXCEPTIONS
            program_error           = 1
            OTHERS                  = 2.
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " DISPLAY_DATA

*---------------------------------------------------------------------*
*       FORM USER_COMMAND                                             *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                     rs_selfield TYPE slis_selfield..
  DATA:   l_uname        LIKE sy-uname,
          l_contid TYPE /psyng/mchdr-contid,
          l_parva        TYPE usr05-parva,
          l_sod          TYPE /psyng/swsodvers-vrsio.

*  CHECK rs_selfield-value <> space.
  READ TABLE gt_details INTO gw_details INDEX rs_selfield-tabindex.
  READ TABLE gt_summary INTO gw_summary WITH KEY signoffid =
                                                 gw_details-signoffid.

  CASE r_ucomm.
    WHEN '&IC1'.
      CASE rs_selfield-fieldname.
        WHEN 'CONTID'.
          PERFORM conf_det USING rs_selfield-value.
        WHEN  'ASSIGN_ID'.
          CASE gw_summary-type.
            WHEN '1' OR '2'.
              PERFORM call_sod_rep.
            WHEN '3'.
              PERFORM call_ca_rep.
            WHEN '4'.
              IF gw_summary-userid IS INITIAL.
                PERFORM call_sod_rep_role.
              ELSE.
*--Assigned to user through role
                PERFORM call_sod_rep.
              ENDIF.
            WHEN '5'.
              IF gw_summary-userid IS INITIAL.
                PERFORM call_ca_rep_role.
              ELSE.
*--Assigned to user through role
                PERFORM call_ca_rep.
              ENDIF.
          ENDCASE.
        WHEN  'CHANGES_MADE'.
          IF gw_details-changes_made = ''.
            MESSAGE i002(/psyng/sw) WITH text-t16.
          ELSE.
            PERFORM tcod_chg_made.
          ENDIF.

        WHEN   'TCODE_EXECUTED'.
          IF gw_details-tcode_executed = ''.
            MESSAGE i002(/psyng/sw) WITH text-t15.
          ELSE.
            PERFORM tcod_exe_det.
          ENDIF.
        WHEN   'AM_ALERTS_OPEN'.
          PERFORM am_alerts_open.

        WHEN   'ATTACHMENT'.
          PERFORM attach_open.

        WHEN   'JUST'.
          IF rs_selfield-value <> ''.
            PERFORM just_open.
          ENDIF.
        WHEN 'REVIEW'.
          IF rs_selfield-value <> ''.
*            IF sy-uname EQ gw_details-auditor. "C0700
            IF g_current_user EQ gw_details-auditor. "C0700
              PERFORM disp_rev.
            ENDIF.
          ENDIF.
        WHEN 'SIGNOFF_TYPE'.
          CASE gw_details-signoff_type.
            WHEN '@BM@'.
              MESSAGE i008(/psyng/sw).
*               Manual Mitigation Signoff
            WHEN '@6K@'.
              MESSAGE i009(/psyng/sw).
*               Automated Mitigation Signoff
          ENDCASE.
        WHEN 'AUDITOR'.
          PERFORM drilldown_su01 USING gw_details-auditor.
        WHEN 'TARGET_ID'.
          PERFORM drilldown_target_id
            USING gw_details
                  gw_summary.

      ENDCASE.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ADJUST_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM adjust_fieldcat.

  DEFINE set_hotspot.
    clear gw_fieldcat.
    gw_fieldcat-hotspot = 'X'.
    modify gt_fieldcat from gw_fieldcat
                      transporting
                        hotspot
                     where
                        fieldname = &1.
  END-OF-DEFINITION.
  DEFINE set_checkbox.
    clear gw_fieldcat.
    gw_fieldcat-checkbox = 'X'.
    gw_fieldcat-edit     = ''.
    modify gt_fieldcat from gw_fieldcat
                      transporting
                        checkbox
                     where
                        fieldname = &1.
  END-OF-DEFINITION.

*--Set hotspot fields
  set_hotspot :
    'AUDITOR',
*    'AUDITOR_NAME',
    'CONTID',
    'ASSIGN_ID',
    'TARGET_ID',
*    'ASSIGN_TYPE',
    'TCODE_EXECUTED',
    'CHANGES_MADE',
    'AM_ALERTS_OPEN',
    'SIGNOFF_COMPLETE',
    'REVIEW',
    'ATTACHMENT',
    'JUST',
    'SIGNOFF_TYPE'.
*--Set checkbox fields.
  set_checkbox :
    'TCODE_EXECUTED',
    'CHANGES_MADE',
    'AM_ALERTS_OPEN',
    'SIGNOFF_COMPLETE'.
*--Remove Org field if not needed
  if gf_mit_by_org <> 'Y'.
    delete gt_fieldcat where fieldname = 'ORG_ABB'.
  endif.
ENDFORM.                    " ADJUST_FIELDCAT
*&---------------------------------------------------------------------*
*&      Form  CALL_SOD_REP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_sod_rep.
  DATA : lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  lt_iseltab-selname = 'USERLIST'.       "Call from Summary
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-target_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'USRTYPE'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'A'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SPCONFS'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-assign_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SODVRSIO'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_summary-vrsio.
  APPEND lt_iseltab.


  lt_iseltab-selname = 'LVL1'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'LVL3ST'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-from_date.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'LVL3ED'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-to_date.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'XMC'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SHOSUM'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = ''.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SHODET'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.



  if not gw_details-org_abb is INITIAL.
*--Org check for specific org
      lt_iseltab-selname = 'ORGCHK'.
      lt_iseltab-kind    = 'P'.
      lt_iseltab-sign    = 'I'.
      lt_iseltab-option  = 'EQ'.
      lt_iseltab-low     = 'X'.
      APPEND lt_iseltab.
      lt_iseltab-selname = 'ORGLVL'.
      lt_iseltab-kind    = 'S'.
      lt_iseltab-sign    = 'I'.
      lt_iseltab-option  = 'EQ'.
      lt_iseltab-low     = gw_details-org_abb.
      APPEND lt_iseltab.
  endif.
  SUBMIT /psyng/sodreport_sys_wide_org
         WITH SELECTION-TABLE lt_iseltab
         AND RETURN.


ENDFORM.                    " CALL_SOD_REP
*---------------------------------------------------------------------*
*       FORM call_sod_rep_role                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM call_sod_rep_role.
  DATA : lt_iseltab  TYPE STANDARD TABLE OF  rsparams
                     WITH HEADER LINE.

  lt_iseltab-selname = 'ROLE'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-target_id.
  APPEND lt_iseltab.


  lt_iseltab-selname = 'SPCONFS'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-assign_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SODVRSIO'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_summary-vrsio.
  APPEND lt_iseltab.


  lt_iseltab-selname = 'XMC'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SHOSUM'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = ''.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SHODET'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  SUBMIT /psyng/sod_syswide_byrole
          WITH SELECTION-TABLE lt_iseltab
          AND RETURN.


ENDFORM.                    " CALL_SOD_REP

*&---------------------------------------------------------------------*
*&      Form  CALL_CA_REP
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM call_ca_rep.
  DATA : lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  lt_iseltab-selname = 'PBNAME'.       "Call from Summary
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-target_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'USRTYPE'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'A'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'PAUDID'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-assign_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SODVRSIO'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_summary-vrsio.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SUM'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = ''.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'DET'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'XMC'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.


  SUBMIT /psyng/sw_crit_auths
         WITH SELECTION-TABLE lt_iseltab
          AND RETURN.
ENDFORM.                    " CALL_CA_REP



*---------------------------------------------------------------------*
*       FORM call_ca_rep_role                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM call_ca_rep_role.
  DATA : lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  lt_iseltab-selname = 'ROLES'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-target_id.
  APPEND lt_iseltab.



  lt_iseltab-selname = 'PAUDID'.
  lt_iseltab-kind    = 'S'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_details-assign_id.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SODVRSIO'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = gw_summary-vrsio.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'SUM'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = ''.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'DET'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.

  lt_iseltab-selname = 'P_SHOMIT'.
  lt_iseltab-kind    = 'P'.
  lt_iseltab-sign    = 'I'.
  lt_iseltab-option  = 'EQ'.
  lt_iseltab-low     = 'X'.
  APPEND lt_iseltab.


  SUBMIT /psyng/sw_crit_auths_byrole
        WITH SELECTION-TABLE lt_iseltab
        AND RETURN.
ENDFORM.                    " CALL_CA_REP

*&---------------------------------------------------------------------*
*&      Form  TCOD_EXE_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM tcod_chg_made.
  IF NOT gw_summary-userid IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_MC_SHOW_CHANGES'
         EXPORTING
              i_bname      = gw_summary-userid
              i_start_date = gw_details-from_date
              i_end_date   = gw_details-to_date
              i_vrsio      = gw_summary-vrsio
              i_conid      = gw_summary-conid
              i_swaudid    = gw_summary-swaudid.
  ELSE.
    MESSAGE i002(/psyng/sw) WITH
    'Change Details are only supported for'(e03)
    'User Assignments'(e02).
  ENDIF.
ENDFORM.                    " TCOD_EXE_DET
*&---------------------------------------------------------------------*
*&      Form  TCOD_EXE_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM tcod_exe_det.
  IF NOT gw_summary-userid IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_MC_SHOW_EXECUTION'
         EXPORTING
              i_bname      = gw_summary-userid
              i_start_date = gw_details-from_date
              i_end_date   = gw_details-to_date
              i_vrsio      = gw_summary-vrsio
              i_conid      = gw_summary-conid
              i_swaudid    = gw_summary-swaudid.
  ELSE.
    MESSAGE i002(/psyng/sw) WITH
    'Execution Details are only supported for'(e01)
    'User Assignments'(e02).
  ENDIF.
ENDFORM.                    " TCOD_EXE_DET
*&---------------------------------------------------------------------*
*&      Form  AM_ALERTS_OPEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM am_alerts_open.
  CALL FUNCTION '/PSYNG/SW_MC_SHOW_AMALERTS'
       EXPORTING
            i_bname      = gw_summary-userid
            i_start_date = gw_details-from_date
            i_end_date   = gw_details-to_date
            i_vrsio      = gw_summary-vrsio
            i_conid      = gw_summary-conid
            i_swaudid    = gw_summary-swaudid.
ENDFORM.                    " AM_ALERTS_OPEN
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_gw_summary_VRSIO  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.

  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.
  .

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  ATTACH_OPEN
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM attach_open.

  gs_signoff = gw_summary.
  CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
   EXPORTING
*     IF_HEADER                =
*     IF_ASSIGNMENT            =
     if_signoff               = 'X'
     if_list                  = 'X'
*     IF_ADD                   =
*     IF_CHECK                 =
     i_mcid                   = gw_details-contid
*     IS_ASSIGNMENT            =
     is_signoff               = gs_signoff
*   IMPORTING
*     EF_HAS_ATTACHMENTS       =
*     E_NR_ATTACHMENTS         =
   EXCEPTIONS
     invalid_input            = 1
     not_implemented          = 2
     gos_failure              = 3
     OTHERS                   = 4
            .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " ATTACH_OPEN
*&---------------------------------------------------------------------*
*&      Form  just_open
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM just_open.
  DATA: lt_text TYPE TABLE OF solisti1 WITH HEADER LINE,

        BEGIN OF ls_editor_text,
          tdformat TYPE tdformat,
          tdline(132) TYPE c,
        END OF ls_editor_text,
        lt_editor_text LIKE TABLE OF ls_editor_text WITH HEADER LINE,
        lt_texts LIKE TABLE OF ls_editor_text WITH HEADER LINE,
        lw_detail LIKE LINE OF gt_detail,
        len TYPE i,
        l TYPE i,
       out TYPE string,
       l_line(255) TYPE c,
       l_string1 TYPE string,
       l_newline TYPE string,
       l_newline2 TYPE string,
       l_string2 type string,
       l_date(10) TYPE c,
       l_time(8) TYPE c,
       l_full_name type /psyng/bc_uidn-name_text.

  gs_signoff = gw_summary.
  refresh :  gt_just_text.
  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
    EXPORTING
        if_signoff                 = 'X'
        if_list                    = 'X'
      i_mcid                     = gw_details-contid
      is_signoff                 = gs_signoff
    TABLES
      et_list                    = gt_list
      et_details                 = gt_detail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INVALID_INPUT   = 1
             NOT_IMPLEMENTED = 2
             GOS_FAILURE     = 3
             OTHERS          = 4 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
*  PERFORM init_new_line.
*--Create one long string with all the text
  LOOP AT gt_list.
    gt_just_text =
'----------------------------------------------------------------------'
.
append gt_just_text.
    SELECT SINGLE name_text FROM /psyng/bc_uidn INTO
           l_full_name WHERE bname =  gt_list-createuser.

    WRITE gt_list-createdate TO l_date.
    WRITE gt_list-createtime TO l_time.
    CONCATENATE 'User :'(a02) l_full_name '(' gt_list-createuser ')'

    INTO l_string1  SEPARATED BY space.
    gt_just_text = l_string1.
    append gt_just_text.
    CONCATENATE 'Timestamp : '(a01) l_time l_date '.'
    INTO l_string1  SEPARATED BY space.
    gt_just_text = l_string1.
    append gt_just_text.

    clear l_string1.
    gt_just_text =
'----------------------------------------------------------------------'
.
append gt_just_text.

    LOOP AT gt_detail WHERE
      objectid    = gt_list-objectid   AND
      createuser  = gt_list-createuser AND
      createdate  = gt_list-createdate AND
      createtime  = gt_list-createtime .
      l_string2 = gt_detail-text.
      condense l_string2.
      CONCATENATE l_string1 l_string2
       INTO l_string1.
      gt_just_text = l_string1.
      append gt_just_text.
      clear l_string1.
    ENDLOOP.
  ENDLOOP.
  CALL SCREEN 0100 STARTING AT 3 3.
ENDFORM.                    " just_open
*&---------------------------------------------------------------------*
*&      Form  DISP_REV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM disp_rev.
  DATA : lt_signoffids TYPE TABLE OF /psyng/range_mc_singoffid
                       WITH HEADER LINE,
         lt_details TYPE TABLE OF /psyng/sw_mc_review_report
         WITH HEADER LINE,
         l_fld TYPE string,
         ls_stable TYPE lvc_s_stbl.
  FIELD-SYMBOLS :
      <record> TYPE /psyng/sw_mc_review_report,
      <g_grid> TYPE REF TO cl_gui_alv_grid.


  CALL FUNCTION '/PSYNG/SW_MC_REVIEW_SCREEN'
       EXPORTING
            i_details = gw_details
            i_summary = gw_summary.
*--Refresh the ALV with the updated record
  lt_signoffids-sign   = 'I'.
  lt_signoffids-option = 'EQ'.
  lt_signoffids-low    = gw_summary-signoffid.
  APPEND lt_signoffids.
  READ TABLE gt_details WITH KEY signoffid = gw_summary-signoffid
  ASSIGNING <record>.
*--Get updated record
  CALL FUNCTION '/PSYNG/SW_MC_REVIEW_REPORT'
   EXPORTING
     if_unreviewed         = 'X'
     if_autoreviewed       = 'X'
     if_manreviewed        = 'X'
     i_bname               = g_current_user "sy-uname
   TABLES
     it_signoffid          = lt_signoffids
*   ET_SUMMARY            =
     et_details            = lt_details.

  READ TABLE lt_details INDEX 1.
  IF sy-subrc = 0.
    <record> = lt_details.
*--Update ALV grid
    l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
    ls_stable-row    = 'X'.
    ls_stable-col    = 'X'.
    ASSIGN  ('(SAPLSLVC_FULLSCREEN)GT_GRID-GRID') TO <g_grid>."HBHALLA
    CALL METHOD <g_grid>->refresh_table_display(
     is_stable = ls_stable ).
  ENDIF.




ENDFORM.                    " DISP_REV
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_9001 INPUT.
  CALL METHOD text_editor->get_text_as_r3table
      IMPORTING
        table           = lt_texttab       "
      EXCEPTIONS
        error_dp        = 1
        error_dp_create = 2
        OTHERS          = 3.
  IF sy-subrc <> 0.
  ENDIF.


  CASE sy-ucomm.
    WHEN '&F03'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      LEAVE TO SCREEN 0.
    WHEN 'BTNCANC'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      LEAVE TO SCREEN 0.
    WHEN 'EXIT'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      LEAVE TO SCREEN 0.
    WHEN 'BTNTEXE'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      PERFORM tcod_exe_det.
    WHEN 'BTNTCHG'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      PERFORM tcod_chg_made.
    WHEN 'BTNOPAM'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      PERFORM am_alerts_open.
    WHEN 'BTNCDET'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      CASE gw_summary-type.
        WHEN '1'.
          PERFORM call_sod_rep.
        WHEN '3'.
          PERFORM call_ca_rep.
        WHEN '4'.
          PERFORM call_sod_rep_role.
        WHEN '5'.
          PERFORM call_ca_rep_role.
      ENDCASE.
    WHEN 'BTNADSP'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      PERFORM attach_open.
    WHEN 'BTNACRT'. "#EC SAST_CI_GEN_CHECK (HBHALLA)
      PERFORM attach_create.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_9001  INPUT
*&---------------------------------------------------------------------*
*&      Form  CONF_DET
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conf_det USING p_val.
  DATA:   l_uname        LIKE sy-uname,
            l_contid TYPE /psyng/mchdr-contid,
            l_parva        TYPE usr05-parva,
            l_sod          TYPE /psyng/swsodvers-vrsio.

  l_uname = g_current_user . "sy-uname.
*-- Get user's default version
  SELECT SINGLE parva INTO l_parva FROM usr05
           WHERE bname = l_uname
             AND parid = '/PSYNG/VRSIO'.

  IF sy-subrc = 0 AND l_parva <> space.
    l_sod = l_parva.
  ENDIF.

  PERFORM set_default_sodversion USING gw_summary-vrsio l_uname.

  SET PARAMETER ID '/PSYNG/SW_MIT' FIELD p_val.
  g_dynnr = '0211'.
  EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
  IF sy-subrc <> 0.
    MESSAGE e077(s#) WITH '/PSYNG/SE'.
  else.
    CALL TRANSACTION '/PSYNG/SE'.
  endif.
ENDFORM.                    " CONF_DET

*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'AUDITOR'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'AUDITOR_NAME'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'CONTID'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.


  l_sort-spos = '4'.
  l_sort-fieldname = 'CONTID_DESC'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.


  l_sort-spos = '5'.
  l_sort-fieldname = 'VRSIO'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.


  l_sort-spos = '6'.
  l_sort-fieldname = 'ASSIGN_TYPE'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.


  l_sort-spos = '7'.
  l_sort-fieldname = 'ASSIGN_ID'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '8'.
  l_sort-fieldname = 'ASSIGN_DESC'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '9'.
  l_sort-fieldname = 'TARGET_TYPE'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '10'.
  l_sort-fieldname = 'TARGET_ID'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '11'.
  l_sort-fieldname = 'TARGET_DESC'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '12'.
  l_sort-fieldname = 'FROM_DATE'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '13'.
  l_sort-fieldname = 'TO_DATE'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '14'.
  l_sort-fieldname = 'SIGNOFF_DATE'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.

  l_sort-spos = '15'.
  l_sort-fieldname = 'SIGNOFF_TIME'.
  l_sort-tabname = 'ET_DETAILS'.
  l_sort-up = 'X'.
  APPEND l_sort TO gt_isort.
ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  attach_create
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM attach_create.
  gs_signoff-signoffid = gw_details-signoffid.
  CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
   EXPORTING
*     IF_HEADER                =
*     IF_ASSIGNMENT            =
     if_signoff               = 'X'
*     IF_LIST                  =
     if_add                   = 'X'
*     IF_CHECK                 =
     i_mcid                   = gw_details-contid
*     IS_ASSIGNMENT            =
     is_signoff               = gs_signoff
*   IMPORTING
*     EF_HAS_ATTACHMENTS       =
*     E_NR_ATTACHMENTS         =
   EXCEPTIONS
     invalid_input            = 1
     not_implemented          = 2
     gos_failure              = 3
     OTHERS                   = 4
            .
  IF sy-subrc <> 0.
* MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " attach_create
*&---------------------------------------------------------------------*
*&      Form  JUST_CREATE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM just_create.
  gs_signoff-signoffid = gw_details-signoffid.
  CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
  EXPORTING
*     IF_HEADER                  =
*     IF_ASSIGNMENT              =
      if_signoff                 = 'X'
      if_add                     = 'X'
*       IF_LIST                    =
*     IF_CHECK                   =
    i_mcid                     = gw_details-contid
*     IS_ASSIGNMENT              =
    is_signoff                 = gs_signoff
*     I_JUSTIFICATION_TEXT       =
*   IMPORTING
*     EF_HAS_JUSTIFICATION       =
*     E_NR_JUSTIFICATION         =
*   TABLES
*     ET_LIST                    = ET_LIST
*     ET_DETAILS                 = ET_DETAIL
*     IT_TEXT                    =
   EXCEPTIONS
     INVALID_INPUT              = 1
     NOT_IMPLEMENTED            = 2
     GOS_FAILURE                = 3
     OTHERS                     = 4
           .
  IF sy-subrc <> 0.
   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
           WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " JUST_CREATE
*&---------------------------------------------------------------------*
*&      Form  drilldown_assign_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GW_DETAILS  text
*----------------------------------------------------------------------*
*FORM drilldown_assign_id
*USING    is_details TYPE /psyng/sw_mc_review_report
*         is_summary TYPE /psyng/mcrvwsgn.
*
*  IF NOT is_summary-conid IS INITIAL.
*    PERFORM drilldown_conid USING is_summary-conid is_summary-vrsio.
*  ELSE.
*    PERFORM drilldown_swaudid USING is_summary-swaudid is_summary-vrsio
*.
*  ENDIF.
*ENDFORM.                    " drilldown_assign_id

*---------------------------------------------------------------------*
*       FORM drilldown_target_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_DETAILS                                                    *
*  -->  IS_SUMMARY                                                    *
*---------------------------------------------------------------------*
FORM drilldown_target_id
USING    is_details TYPE /psyng/sw_mc_review_report
         is_summary TYPE /psyng/mcrvwsgn.

  IF NOT is_summary-userid IS INITIAL.
    PERFORM drilldown_su01 USING is_summary-userid.
  ELSE.
    PERFORM drilldown_pfcg USING is_summary-agr_name.
  ENDIF.
ENDFORM.                    " drilldown_assign_id
*&---------------------------------------------------------------------*
*&      Form  drilldown_su01
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IS_SUMMARY_USERID  text
*----------------------------------------------------------------------*
FORM drilldown_su01 USING    i_bname TYPE xubname.
  AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
  IF sy-subrc <> 0.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SU01D'.
    ELSE.
      SET PARAMETER ID 'XUS' FIELD i_bname.
      CALL TRANSACTION 'SU01D'.
    ENDIF.
  ELSE.
    SET PARAMETER ID 'XUS' FIELD i_bname.
    CALL TRANSACTION 'SU01'.
  ENDIF.

ENDFORM.                    " drilldown_su01
*&---------------------------------------------------------------------*
*&      Form  drilldown_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IS_SUMMARY_AGR_NAME  text
*----------------------------------------------------------------------*
FORM drilldown_pfcg USING    i_agr_name TYPE agr_name.
  CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            agr_name      = i_agr_name
       EXCEPTIONS
            agr_not_found = 1
            OTHERS        = 2.
*BOC:HBHALLA (03/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw)
                WITH 'Role not found'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (03/12/24)

ENDFORM.                    " drilldown_pfcg

*---------------------------------------------------------------------*
*       FORM init_new_line                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM init_new_line.
  DATA : l_class_name(24) TYPE c VALUE 'CL_ABAP_CHAR_UTILITIES',
         l_attr_name(7)  TYPE c VALUE 'NEWLINE',
         l_class_ref(33)  TYPE c.
  FIELD-SYMBOLS: <attr> TYPE ANY,
                 <attr2> TYPE ANY.
  IF s_new_line IS INITIAL.
    CONCATENATE l_class_name '=>' l_attr_name INTO l_class_ref.
    ASSIGN (l_class_ref) TO <attr>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(17/12/24)
    IF sy-subrc <> 0.
*CL_ABAP_CHAR_UTILITIES=>NEWLINE doesn't exist (4.6c system)
      ASSIGN new_line TO <attr>.
      ASSIGN new_line2 TO <attr2>.

    ENDIF.
    MOVE <attr> TO s_new_line.
    ASSIGN new_line2 TO <attr2>.
    MOVE <attr2> TO s_new_line2.

  ENDIF.
ENDFORM.                    " init_new_line
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS 'STATUS_0100'.
*  SET TITLEBAR 'xxx'.
  PERFORM init_justification_text.
ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.
  IF sy-ucomm = 'BACK'.
    SET SCREEN 0.
    LEAVE SCREEN.
  ENDIF.
ENDMODULE.                 " USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*&      Form  init_justification_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM init_justification_text.

  IF go_just_editor IS INITIAL.

    CREATE OBJECT go_just_container
    EXPORTING container_name = 'C_JUST_TEXT'.

    CREATE OBJECT go_just_editor
    EXPORTING
    parent            = go_just_container
    wordwrap_mode     = cl_gui_textedit=>wordwrap_at_fixed_position
    wordwrap_to_linebreak_mode
                      = cl_gui_textedit=>true
     max_number_chars = 99999.

    CALL METHOD go_just_editor->set_toolbar_mode
         EXPORTING
           toolbar_mode           = cl_gui_textedit=>false
         EXCEPTIONS
           error_cntl_call_method = 1
           invalid_parameter      = 2
           OTHERS                 = 3 .
    IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
    CALL METHOD go_just_editor->set_readonly_mode
         EXPORTING
           READONLY_MODE          = cl_gui_textedit=>true
         EXCEPTIONS
           error_cntl_call_method = 1
           invalid_parameter      = 2
           OTHERS                 = 3 .
    IF sy-subrc <> 0.
*   MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
*              WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
    ENDIF.
  ENDIF.
  CALL METHOD go_just_editor->set_text_as_stream
    EXPORTING
      text            = gt_just_text[]
    EXCEPTIONS
      error_dp        = 1
      error_dp_create = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
  ENDIF.
  CALL METHOD cl_gui_cfw=>flush
             EXCEPTIONS
               OTHERS = 1.
*  ENDIF.

ENDFORM.                    " init_justification_text
