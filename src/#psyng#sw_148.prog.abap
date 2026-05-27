REPORT /psyng/sw_148 MESSAGE-ID /psyng/sw.
TABLES : /psyng/conflict,/psyng/sw_rfcdes,agr_define,"/psyng/swrrsrol
          /psyng/swsodorgm. "HBHALLA
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_148_macros.
INCLUDE /psyng/sw_148_global.
INCLUDE : /psyng/basis_exelog.

DATA :
  gf_cfg_set_enabled       TYPE flag,
  g_exit_proc,
  gf_invalid_rfc           TYPE c,
  curr_variant             LIKE  rsvar-variant,
  g_curr_variant           LIKE  rsvar-variant,
  g_ucomm                  LIKE sy-ucomm,
  g_button_set             TYPE flag,
  l_vrsio                  TYPE /psyng/sodvrsio,
  g_variant                LIKE vari-variant,
  g_vari_desc              TYPE varid OCCURS 0 WITH HEADER LINE,
  g_vari_contents          LIKE rsparams OCCURS 0 WITH HEADER LINE,
  g_vari_text              LIKE varit OCCURS 0 WITH HEADER LINE,
  gt_irsparams             TYPE rsparams OCCURS 0 WITH HEADER LINE,
  g_program                LIKE sy-repid,
  gt_rfcdest               TYPE TABLE OF rfcdes WITH HEADER LINE,
  gt_sum_results           TYPE TABLE OF /psyng/sw_out_routput
                           WITH HEADER LINE,
  g_tasknumber             TYPE i,
  g_tasksrunning           TYPE i,
  g_failedtasks            TYPE i,
  g_totalresults           TYPE i,
  g_count_summary          TYPE sy-tabix,
  g_count_summary_mit      TYPE sy-tabix,
  gt_faobj_system          TYPE /psyng/sw_tab_sys_faobj,
  gt_ao_sys                TYPE /psyng/sw_tab_sys_ao,
  gt_conflict_local        TYPE TABLE OF /psyng/conflict,
 gt_confdet_local         TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
 gt_functtran_local       TYPE TABLE OF /psyng/functtran,
 gt_faobj_local           TYPE TABLE OF /psyng/faobj2,
 gt_swsodorgm_local       TYPE TABLE OF /psyng/swsodorgm,
 gt_functran_no_enh_local
   TYPE TABLE OF /psyng/functtran,
 gt_tcodes_local          TYPE TABLE OF /psyng/sw_par_tcode_output,
g_org_field TYPE flag, "OPL645
 gt_faobj_org TYPE TABLE OF /psyng/faobj2, "OPL645
 BEGIN OF gs_fun_role ,
   funid TYPE /psyng/function_id,
   roles TYPE SORTED TABLE OF agr_name WITH UNIQUE KEY table_line,
 END OF gs_fun_role,
 gt_fun_role LIKE SORTED TABLE OF gs_fun_role WITH HEADER LINE
             WITH UNIQUE KEY  funid,
 BEGIN OF gs_con_role,
   conid TYPE /psyng/conflict_id,
   roles TYPE SORTED TABLE OF agr_name WITH UNIQUE KEY table_line,
 END OF gs_con_role,
 gt_con_role LIKE SORTED TABLE OF gs_con_role WITH HEADER LINE
             WITH UNIQUE KEY  conid,


 BEGIN OF gt_conflicted_roles OCCURS 0,
   role  TYPE agr_name,
   count TYPE i,
 END OF gt_conflicted_roles,
 BEGIN OF gt_mitigated_roles OCCURS 0,
   role  TYPE agr_name,
   count TYPE i,
 END OF gt_mitigated_roles,

 gt_det_results   TYPE TABLE OF /psyng/sw_out_routdet3
                  WITH HEADER LINE,
 g_nr_authdetails TYPE sy-tabix,
 g_warning_msg(1) TYPE c,
 g_preconfig      TYPE /psyng/swcfgset-setid,
 lf_set_invalid   TYPE flag,
 lf_set_nocover   TYPE flag,
 lf_set_mismatch  TYPE flag,
 ls_ba_role       TYPE /psyng/bc_ba_00,
*BOC AKUMAR PN 13164
*Result ID message was not displaying when
*default SOD & Config set enable issue
 g_rpt_succ       TYPE flag,
*EOC AKUMAR
g_current_user TYPE sy-uname. "C0700
RANGES : gr_systems FOR gt_rfcdest-rfcdest.

*BOC:HBHALLA (PN-13164) (08/05/25)
DATA: swconfig TYPE /psyng/swconfig,
      gf_hide_org         TYPE /psyng/bapiflagx.
*EOC:HBHALLA (PN-13164) (08/05/25)

SELECTION-SCREEN: BEGIN OF BLOCK anb WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) anb_but USER-COMMAND anb_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .

PARAMETERS :
  p_desc   TYPE /psyng/longtextfield      MODIF ID anb,
  p_retdet TYPE /psyng/se_retention_days  MODIF ID anb.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-c01 FOR FIELD p_deldet
MODIF ID anb."(++)HBHALLA(PN-17817)(19/02/26)(Collapse button)
PARAMETERS
  p_deldet TYPE sy-datum                  MODIF ID anb.
SELECTION-SCREEN END OF LINE.
PARAMETERS:
  p_retsum TYPE /psyng/se_retention_days  MODIF ID anb.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-c02 FOR FIELD p_delsum
MODIF ID anb."(++)HBHALLA(PN-17817)(19/02/26)(Collapse button)
PARAMETERS
  p_delsum TYPE sy-datum                  MODIF ID anb.
SELECTION-SCREEN END OF LINE.
PARAMETERS:
  p_retday TYPE /psyng/se_retention_days  MODIF ID anb,
  p_deldat TYPE sy-datum                  MODIF ID anb,
  p_storno TYPE flag                      MODIF ID anb.

SELECTION-SCREEN: END OF BLOCK anb.
SELECTION-SCREEN: BEGIN OF BLOCK resb WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) resb_but USER-COMMAND resb_but.
SELECTION-SCREEN COMMENT 16(50) text-b02 .

PARAMETERS :
  p_dflt   TYPE flag USER-COMMAND dflt MODIF ID res,
  p_vrsio  TYPE /psyng/sodvrsio        MODIF ID res,
  p_cfgset TYPE /psyng/seconfid        MODIF ID res.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-003 USER-COMMAND verify_r
                                      MODIF ID res.
SELECTION-SCREEN END OF LINE.
SELECT-OPTIONS :
      s_role    FOR agr_define-agr_name   MODIF ID res,
      rba       FOR ls_ba_role-busarea    MODIF ID res.

PARAMETERS :
  p_comp TYPE flag MODIF ID res DEFAULT 'X',
  p_sing TYPE flag MODIF ID res DEFAULT 'X',
  p_assr TYPE flag MODIF ID res.
SELECT-OPTIONS :
      s_conid   FOR /psyng/conflict-conid MODIF ID res.
SELECTION-SCREEN: END OF BLOCK resb.

SELECTION-SCREEN: BEGIN OF BLOCK sysb WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) sysb_but USER-COMMAND sysb_but.
SELECTION-SCREEN COMMENT 16(50) text-b04 .
PARAMETERS     :
  p_local  TYPE flag USER-COMMAND local MODIF ID sys DEFAULT 'X',
  p_system TYPE /psyng/sw_rfcdes-rfcdest
           MATCHCODE OBJECT /psyng/sw_rfcsh_coll
           MODIF ID sys.
SELECTION-SCREEN: END OF BLOCK sysb.

*BOC:AKUMAR (PN-13164) (10/05/25)
*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 16(50) text-b06.

PARAMETERS: orgchk  AS CHECKBOX DEFAULT ' ' USER-COMMAND org
                                   MODIF ID exe.
SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb
                                   MODIF ID exe.

SELECTION-SCREEN: END OF BLOCK exe_o.
*EOC:AKUMAR (PN-13164) (10/05/25)

SELECTION-SCREEN: BEGIN OF BLOCK anat WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) anat_but USER-COMMAND anat_but.
SELECTION-SCREEN COMMENT 16(50) text-b03 .

PARAMETERS :
  p_dtbtch TYPE i MODIF ID ana,
  p_subtch TYPE i MODIF ID ana,
  p_maxtsk TYPE i MODIF ID ana.
SELECTION-SCREEN: END OF BLOCK anat.

*---Background Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b05 .
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK bgd_o.

PARAMETERS: p_audpl TYPE char40 NO-DISPLAY,
            p_runid TYPE /psyng/sast_numc6 NO-DISPLAY.

INITIALIZATION.
* BOC by RGUPTA on 08.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SW_148'.

  g_program = sy-repid.
  PERFORM set_button_icons.

*--Get default retention period & desription
*-- if someone entered nonnumeric value then default
  IF p_retday IS INITIAL.
    DATA: ls_config TYPE /psyng/se_config_param.
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'DFLT_ST_ROL_RET_DAYS'
      IMPORTING
        e_config    = ls_config.
    IF ls_config-value IS INITIAL.
      p_retday = ls_config-default.
    ELSE.
      IF ls_config-value CO '0123456789 '.
        p_retday  = ls_config-value.
      ELSE.
        p_retday = ls_config-default.
      ENDIF.
    ENDIF.
    CLEAR ls_config.
  ENDIF.

*--Get default retention period for details
*-- if someone entered nonnumeric value then default
  IF p_retdet IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'DFLT_ST_RORET_DAYS_D'
      IMPORTING
        e_config    = ls_config.
    IF ls_config-value IS INITIAL.
      p_retdet = ls_config-default.
    ELSE.
      IF ls_config-value CO '0123456789 '.
        p_retdet  = ls_config-value.
      ELSE.
        p_retdet = ls_config-default.
      ENDIF.
    ENDIF.
    CLEAR ls_config.
  ENDIF.

*--Get default retention period for summary
*-- if someone entered nonnumeric value then default
  IF p_retsum IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'DFLT_ST_RORET_DAYS_S'
      IMPORTING
        e_config    = ls_config.
    IF ls_config-value IS INITIAL.
      p_retsum = ls_config-default.
    ELSE.
      IF ls_config-value CO '0123456789 '.
        p_retsum  = ls_config-value.
      ELSE.
        p_retsum = ls_config-default.
      ENDIF.
    ENDIF.
    CLEAR ls_config.
  ENDIF.

  IF p_desc IS INITIAL.
    se_config_param 'DFLT_ST_ROL_SOD_DESC' p_desc.
  ENDIF.

  se_config_param 'DFLT_ST_ROL_DET_BTCH' p_dtbtch.
  se_config_param 'DFLT_ST_ROL_SUM_BTCH' p_subtch.
  se_config_param 'DFLT_STOR_SUM_PAR'  p_maxtsk.

  se_config_param 'DFLT_STORE_NOCON_ROL' ls_config-value.
  IF ls_config-value = 'Y' OR ls_config-value = 'X'.
    p_storno = 'X'.
  ELSE.
    CLEAR p_storno.
  ENDIF.
*  IF p_dflt = 'X'.
**--Get global default version and latest published set
*    PERFORM get_default_version_set.
*  ELSE.
**  *-- Get user's default version
*    IF p_vrsio = space.
*      CALL FUNCTION '/PSYNG/SW_034'
*        IMPORTING
*          e_vrsio = p_vrsio.
*    ENDIF.
*  --Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'Y' OR gf_cfg_set_enabled = 'X'.
    gf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.
**  --default to the latest published configuration set (highest nr)
*    IF p_cfgset IS INITIAL.
*      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
*        EXPORTING
*          i_vrsio      = 'X'
*          i_cfgvrsio   = p_vrsio
*        IMPORTING
*          e_config_set = p_cfgset.
*    ENDIF.
*  ENDIF.
*BOC OPL645 AKUMAR
*Read value of cfg parameter 'CONSIDER_ORG_FIELD'
  CLEAR ls_config.
  se_config_param 'CONSIDER_ORG_FIELD' ls_config-value.
  IF ls_config-value = 'Y'.
    g_org_field = 'X'.
  ELSE.
    CLEAR g_org_field.
  ENDIF.
*EOC OPL645 AKUMAR

*BOC:HBHALLA (PN-13164) (08/05/25)
*  Hide Org Level Check option
  se_config_param 'HIDE_ORG_ANALYSIS' swconfig-value.
  IF swconfig-value = 'Y'.
    gf_hide_org = 'X'.
  ELSEIF swconfig-value = 'N'.
    gf_hide_org = ' '.
  ENDIF.
  CLEAR swconfig.

**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    orgchk = ' '.
  ENDIF.
  CLEAR swconfig.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high.
*EOC:HBHALLA (PN-13164) (08/05/25)

AT SELECTION-SCREEN  OUTPUT.
  IF p_dflt = 'X'.
*--Get global default version and latest published set
    PERFORM get_default_version_set.
  ELSE.
**  *-- Get user's default version
*    IF p_vrsio = space.
*      CALL FUNCTION '/PSYNG/SW_034'
*        IMPORTING
*          e_vrsio = p_vrsio.
*    ENDIF.

*  --default to the latest published configuration set (highest nr)
    IF gf_cfg_set_enabled = 'X'. "AKUMAR PN13164
      IF p_cfgset IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
          EXPORTING
            i_vrsio      = 'X'
            i_cfgvrsio   = p_vrsio
          IMPORTING
            e_config_set = p_cfgset.
      ENDIF.
    ENDIF.
  ENDIF.
  PERFORM handle_button.
  PERFORM handle_sections.

  IF p_dflt = 'X'.
*--Get global default version and latest published set
    PERFORM get_default_version_set.
  ENDIF.


  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'P_DELDAT'.
        screen-input = '0'.
        MODIFY SCREEN.
        p_deldat = sy-datum + p_retday.
      WHEN 'P_DELDET'.
        screen-input = '0'.
        MODIFY SCREEN.
        p_deldet = sy-datum + p_retdet.
      WHEN 'P_DELSUM'.
        screen-input = '0'.
        MODIFY SCREEN.
        p_delsum = sy-datum + p_retsum.
      WHEN 'P_VRSIO' OR 'P_CFGSET'.
        IF p_dflt = 'X'.
          screen-input = '0'.
        ELSE.
          screen-input = '1'.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'P_SYSTEM'.
        IF p_local = 'X'.
          CLEAR p_system.
          screen-input = '0'.
        ELSE.
          screen-input = '1'.
        ENDIF.
        MODIFY SCREEN.

*BOC:HBHALLA (PN-13164) (08/05/25)
      WHEN 'ORGCHK'.
        IF gf_hide_org = 'X'.
          screen-active = 0.
        ELSE.
          screen-active = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'ORGLVL-LOW' OR 'ORGLVL-HIGH'.
        IF orgchk = 'X'.
          screen-input = 1.
        ELSE.
          REFRESH : orglvl.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
*BOC:HBHALLA (PN-13164) (08/05/25)

    ENDCASE.
  ENDLOOP.

  LOOP AT SCREEN.
*--Hide configuration set selection if not enabled
    IF screen-name CS 'P_CFGSET'.
      IF gf_cfg_set_enabled IS INITIAL.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN.

  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    RETURN.
  ENDIF.

  IF p_comp IS INITIAL AND p_sing IS INITIAL.
    IF sy-batch IS INITIAL.
      MESSAGE e208(00) WITH
      'Select either Composite or Single Roles or both'(001).
    ENDIF.
  ENDIF.

  IF sy-ucomm IS INITIAL.
*--Check Config Set
    IF gf_cfg_set_enabled = 'X'.
      REFRESH : gr_systems.
      gr_systems-sign   = 'I'.
      gr_systems-option = 'EQ'.
      gr_systems-low    = p_system.
      APPEND gr_systems.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid         = p_cfgset
          i_vrsio         = p_vrsio
          if_show_warning = 'X'
          if_local_system = p_local
        TABLES
         it_rfcdest       = gr_systems.
    ENDIF.
  ENDIF.

  CASE sy-ucomm.
    WHEN 'SCJB'.
      g_exit_proc = 'Y'.
      PERFORM schedule_back_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
    WHEN 'DFLT'.
      PERFORM get_default_version_set.
      g_rpt_succ = ' '.
      SET PARAMETER ID 'pid' FIELD g_rpt_succ.
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'P_VRSIO' OR 'P_CFGSET'.
            IF p_dflt = 'X'.
              screen-active = '0'.
            ELSE.
              screen-active = '1'.
            ENDIF.
            MODIFY SCREEN.
        ENDCASE.
      ENDLOOP.
  ENDCASE.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '01'.
  IF sy-subrc NE 0.
    MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
        WITH
          'Start an Analysis'(a01).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF  p_local IS INITIAL
  AND p_system IS INITIAL.
    MESSAGE s002(/psyng/sw)
    WITH 'Please enter system Or Choose local system'(002).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF p_dflt = 'X'.
*--Get global default version and latest published set
    PERFORM get_default_version_set.
    exelog sy-repid 'DEFAULT'.
  ELSE.
    exelog sy-repid ''.
  ENDIF.
*--Validate SOD Matrix
  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
    WHERE vrsio = p_vrsio.
  IF sy-subrc NE 0.
    MESSAGE i135 WITH 'SOD Version does not exist.'(195).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    REFRESH : gr_systems.
    gr_systems-sign   = 'I'.
    gr_systems-option = 'EQ'.
    gr_systems-low    = p_system.
    APPEND gr_systems.
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
        i_setid          = p_cfgset
        i_vrsio          = p_vrsio
        if_show_warning  = 'X'
        if_local_system  = p_local
      IMPORTING
        ef_wrong_version   = lf_set_invalid
        ef_missing_system  = lf_set_nocover
        ef_system_mismatch = lf_set_mismatch
      TABLES
         it_rfcdest       = gr_systems.
    IF lf_set_invalid  = 'X' OR
       lf_set_nocover  = 'X'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

*BOC:HBHALLA (PN-13164) (08/05/25)
  IF orgchk = 'X'.
    exelog sy-repid 'ORGCHECK'.
  ELSE.
    exelog sy-repid 'NO_ORGCHECK'.
  ENDIF.
*EOC:HBHALLA (PN-13164) (08/05/25)

  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program)                       "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_148
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.
*-- Check RFC destinations
  IF NOT p_system IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
  PERFORM validate_job.
  PERFORM 01_prepare_analysis.
  PERFORM 02_load_roles.
  PERFORM 03_analyze.
  WAIT UNTIL g_tasksrunning = 0.
  PERFORM 05_store_results.
  msg '# Detailed Scans executed '  g_tasknumber    '' ''.
  msg '# Detailed Scans FAILED '    g_failedtasks   '' ''.
  msg '# Detailed results '         g_totalresults  '' ''.
  msg '# Summary Results  '         g_count_summary '' ''.
  PERFORM 06_summarize_results USING 'X'.
  IF g_failedtasks = 0.
    msg 'Roles SOD Analysis Complete '      gs_db_header-aid '' ''.
    g_rpt_succ = 'X'.
    SET PARAMETER ID 'pid' FIELD g_rpt_succ.
    IF NOT p_audpl IS INITIAL AND NOT p_runid IS INITIAL.
      PERFORM update_sast_mapping_table.
    ENDIF.
  ELSE.
    MESSAGE e002(/psyng/sw) WITH
    'Some parts of the analysis resulted in an error.'
    'Review the job log.'.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  validate_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_job.
  DATA : lf_answer(1)  TYPE c.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (sy-repid)                        "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_148
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET curr_variant .
  ENDIF.

****-- Check to run report only in background mode and
  IF NOT sy-batch EQ 'X'.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        text_question         =
                         'Report is not meant to run in foreground'(s01)
 text_button_1         = 'Run Anyway'(p02)
 icon_button_1         = 'ICON_OKAY'
 text_button_2         = 'Cancel'(p03)
 icon_button_2         = 'ICON_CANCEL'
 default_button        = '2'
 display_cancel_button = space
IMPORTING
 answer                = lf_answer
EXCEPTIONS
 text_not_found        = 1
 OTHERS                = 2.
*BOC:HBHALLA (03/12/24)
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE s002(/psyng/sw)
          WITH 'Diagnosis text not found'.
        WHEN OTHERS.
          MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
      ENDCASE.
    ENDIF.
*EOC:HBHALLA (03/12/24)
    IF lf_answer <> '1'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

ENDFORM.                    " validate_job
*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.
*--Update the retention date based on days selected
  p_deldat = sy-datum + p_retday.
  p_deldet = sy-datum + p_retdet.
  p_delsum = sy-datum + p_retsum.

*--authority check
  AUTHORITY-CHECK OBJECT 'Y&SW_STORE'
            ID 'ACTVT' FIELD '01'.
  IF sy-subrc <> 0.
    MESSAGE ID '/PSYNG/SW'  TYPE 'S' NUMBER 108
        WITH
          'Start an Analysis'(a01).
  ELSE.
*--Validate SOD Matrix
    SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
      WHERE vrsio = p_vrsio.
    IF sy-subrc NE 0.
      MESSAGE i135 WITH 'SOD Version does not exist.'(195).
      LEAVE LIST-PROCESSING.
    ENDIF.

*--Check Config Set
*    IF NOT gf_cfg_set_enabled IS INITIAL.
**--Check Config Set
*      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
*        EXPORTING
*          i_setid          = p_cfgset
*          i_vrsio          = p_vrsio
*          if_show_warning  = 'X'
*        IMPORTING
*          ef_wrong_version = lf_set_invalid.
*      IF lf_set_invalid = 'X'.
*        EXIT.
*      ENDIF.
*    ENDIF.
    IF NOT gf_cfg_set_enabled IS INITIAL.

*--Check Config Set
      REFRESH : gr_systems.
      gr_systems-sign   = 'I'.
      gr_systems-option = 'EQ'.
      gr_systems-low    = p_system.
      APPEND gr_systems.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid          = p_cfgset
          i_vrsio          = p_vrsio
          if_show_warning  = 'X'
          if_local_system  = p_local
        IMPORTING
          ef_wrong_version   = lf_set_invalid
          ef_missing_system  = lf_set_nocover
          ef_system_mismatch = lf_set_mismatch
        TABLES
           it_rfcdest       = gr_systems.
      IF lf_set_invalid  = 'X' .
        EXIT.
      ENDIF.
    ENDIF.
    CLEAR: curr_report, g_curr_variant.



    PERFORM create_variant_from_sel.

    curr_report = sy-repid.
    g_curr_variant = g_variant.

    l_jobname = p_desc .
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = l_jobname
        in_repvarnt = g_curr_variant
        in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
*    ENDIF.
  ENDIF.
ENDFORM.                    " schedule_back_job
*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7)   TYPE n, oldnumber_c(7).

  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
*  SELECT  variant INTO g_variant FROM varid
*
*  WHERE report = sy-repid   AND
*        variant LIKE '/PSYNG/%' AND NOT
*        variant LIKE '/PSYNG/Z%'
*  ORDER BY variant DESCENDING.
*    oldnumber = g_variant+7(7).
*    EXIT.
*  ENDSELECT.
*  IF sy-subrc NE 0.
*    g_variant = '/PSYNG/0000000'.
*  ELSE.
*    oldnumber = oldnumber + 1.
*    MOVE oldnumber TO oldnumber_c.
*    CONCATENATE '/PSYNG/' oldnumber_c INTO g_variant.
*  ENDIF.

*---C017 Odubey 29/11/2021
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
    EXPORTING
      i_report        = sy-repid
   IMPORTING
     e_variant       = g_variant.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.                    " get_next_variant_id
*---------------------------------------------------------------------*
*       FORM fill_sel_screen_fields_to_tab                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid       = g_program
      if_no_logging = 'X'
    TABLES
      et_params     = gt_irsparams.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  01_prepare_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM 01_prepare_analysis.
  DATA : lt_db_vonbisabb  TYPE STANDARD TABLE OF /psyng/swresvba,
          lt_rfc_range    TYPE STANDARD TABLE OF
                          /psyng/sw_sel_opts_rfcdest,
          ls_rfc_range    TYPE /psyng/sw_sel_opts_rfcdest.
*--Get a new analysis id
  CALL FUNCTION '/PSYNG/SW_SESTORE_NEW_STOREID'
    EXPORTING
      if_role_id = 'X'
    IMPORTING
      rrsid      = g_analysis_id.
*--Initialize the analysis ID in all storage tables
  gt_db_roles-aid             = g_analysis_id.
  gt_db_rolecon-aid           = g_analysis_id.
  gt_db_confun-aid            = g_analysis_id.
  gt_db_rolechild-aid     = g_analysis_id.
  gt_db_rfunabb-aid           = g_analysis_id.
  gt_db_authdetails-aid       = g_analysis_id.
*--Analysis header
  gs_db_header-aid            = g_analysis_id.
  gs_db_header-bname          = g_current_user. "C0700
  gs_db_header-start_date     = sy-datum.
  gs_db_header-start_time     = sy-uzeit.
  gs_db_header-description    = p_desc.
  gs_db_header-sodvrsio       = p_vrsio.
  gs_db_header-setid          = p_cfgset.
  gs_db_header-retention_days = p_retday.
  gs_db_header-ret_days_det = p_retdet. "HBHALLA(13/01/25)
  gs_db_header-ret_days_sum = p_retsum. "HBHALLA(13/01/25)
  gs_db_header-variant_name   = sy-slset.
  IF gs_db_header-variant_name IS INITIAL.
*--If there is no variant used for this analysis,
*  create one and store it
    PERFORM create_variant_from_sel .
    gs_db_header-variant_name = g_variant.
  ENDIF.
*--Add SE Version to Analysis header
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'SE'
    IMPORTING
      e_module_version = gs_db_header-se_version.

*--Load von bis abb index from db
SELECT DISTINCT * FROM /psyng/swresvba INTO TABLE lt_db_vonbisabb "#EC CI_NOWHERE
ORDER BY von bis abb.
  DELETE ADJACENT DUPLICATES FROM lt_db_vonbisabb COMPARING
  von bis abb.
  INSERT LINES OF lt_db_vonbisabb INTO TABLE gt_db_vonbisabb.
  FREE lt_db_vonbisabb.
*--Check if this is an unrestricted analysis
  gs_db_header-no_restrictions = 'X'.
  IF p_assr =  'X'.
    CLEAR gs_db_header-no_restrictions.
  ENDIF.
  IF NOT rba[] IS INITIAL.
*--Restricted by Role Business Area
    LOOP AT rba.
      IF NOT ( rba-sign   = 'I'  AND
               rba-option = 'CP' AND
               rba-low    = '*'  AND
               rba-high   = ''
             ).
        CLEAR gs_db_header-no_restrictions.
        EXIT.
      ENDIF.
    ENDLOOP.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_role[] IS INITIAL.
      LOOP AT s_role.
        IF NOT ( s_role-sign   = 'I'  AND
                 s_role-option = 'CP' AND
                 s_role-low    = '*'  AND
                 s_role-high   = ''
               ).
          CLEAR gs_db_header-no_restrictions.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_conid[] IS INITIAL.
      LOOP AT s_conid.
        IF NOT ( s_conid-sign   = 'I'  AND
                 s_conid-option = 'CP' AND
                 s_conid-low    = '*'  AND
                 s_conid-high   = ''
               ).
          CLEAR gs_db_header-no_restrictions.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*--Validate the batch sizes make sense
  IF p_dtbtch < 1.
    p_dtbtch = 50.
    msg 'Detailed batch size was 0.' 'Defaulted to 50' '' '' .
  ENDIF.
  IF p_subtch < 1.
    p_subtch = 1000.
    msg 'Summary batch size was 0.' 'Defaulted to 1000' '' '' .
  ENDIF.
  IF p_maxtsk < 1.
    p_maxtsk = 2.
    msg 'Parallel Tasks was 0.' 'Defaulted to 2' '' '' .
  ENDIF.
  msg 'Starting Analysis ' gs_db_header-aid '' '' .
*--Print parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid = g_program.
*--Prepare ranges
  IF p_local IS INITIAL.
    ls_rfc_range-sign   = 'I'.
    ls_rfc_range-option = 'EQ'.
    ls_rfc_range-low    = p_system.
    APPEND ls_rfc_range TO lt_rfc_range.
    PERFORM load_rfc
                TABLES
                  lt_rfc_range
                  gt_rfcdest.
*--Add local system to gt_rfcdest.
  ELSE.
    CLEAR gt_rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest-rfcoptions.
    APPEND gt_rfcdest.
  ENDIF.
  READ TABLE gt_rfcdest INDEX 1.
  gs_db_header-sysid = gt_rfcdest-rfcoptions.
*--Register analysis in DB
  MODIFY /psyng/swrrshdr FROM gs_db_header.
  COMMIT WORK.
ENDFORM.                    " 01_prepare_analysis
*---------------------------------------------------------------------*
*       FORM load_rfc                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_RFC                                                        *
*  -->  ET_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_rfc TABLES
     it_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
     et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: l_system_msg(80)  TYPE c,
         l_local_sys      TYPE rfcdest.
  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.

  IF NOT it_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_rfc.
  ENDIF.

  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/SW_062'
      DESTINATION <rfcdes>-rfcdest
      IMPORTING
        e_rfcdest             = l_rfcdest
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.


      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.
ENDFORM.                    " load_role_rfc

*---------------------------------------------------------------------*
*       FORM 02_load_roles                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 02_load_roles.
  DATA : l_role_idx  TYPE sy-tabix.
  DATA : lt_agr_texts TYPE TABLE OF agr_texts,
         ls_agr_texts TYPE agr_texts.
*         lt_agr_users  TYPE TABLE OF ty_agr_users,
*         wa_agr_users  TYPE ty_agr_users.

**--Get selected roles
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
  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION p_system
    EXPORTING
      i_composite_roles = p_comp
      i_single_roles    = p_sing
      i_assigned_roles  = p_assr
      i_get_actual_data = 'X'
    IMPORTING
      e_count           = gs_db_header-roles_analyzed
    TABLES
      it_roles          = s_role
      it_ba             = rba
      et_roles          = gt_agr_define
      et_texts          = lt_agr_texts           "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA PN:11269 (21/01/25)
EXCEPTIONS
    communication_failure = 1
    system_failure = 2
    OTHERS = 3 .
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e002(/psyng/sw) WITH 'Communication failure'(t04).
      WHEN 2.
        MESSAGE e002(/psyng/sw) WITH 'System failure'(t05).
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(t06).
    ENDCASE.
  ENDIF.
*EOC:HBHALLA PN:11269 (21/01/25)
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  DELETE ADJACENT DUPLICATES FROM gt_agr_define COMPARING agr_name.
*  DESCRIBE TABLE gt_agr_define LINES gs_db_header-roles_analyzed.
  msg '# Roles that will be analyzed' gs_db_header-roles_analyzed '' ''.
*--Get Additional Info -
*--Store all roles, also the ones that have no conflicts
*  if storing roles w/o conflicts is selected
  IF p_storno = 'X'.
    SORT lt_agr_texts BY agr_name.
    SORT gt_agr_define BY agr_name.
    LOOP AT gt_agr_define.
      READ TABLE lt_agr_texts INTO ls_agr_texts
      WITH KEY agr_name = gt_agr_define-agr_name
      BINARY SEARCH.
*  -- get role id details
      get_index gt_idx_role gt_agr_define-agr_name
                l_role_idx g_idx_role.
*  --Store role details
      store_role l_role_idx  gt_agr_define ls_agr_texts.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " load_roles
*---------------------------------------------------------------------*
*       FORM 03_analyze                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 03_analyze.

  DATA: lt_agr_define TYPE TABLE OF /psyng/comp_role_tcode.

  DATA : l_nrrole TYPE i.
  WHILE NOT gt_agr_define[] IS INITIAL.
    REFRESH :lt_agr_define,  gt_sum_results.
    APPEND LINES OF gt_agr_define FROM 1 TO p_subtch TO lt_agr_define.
    DELETE gt_agr_define FROM 1 TO p_subtch.
    DESCRIBE TABLE lt_agr_define LINES l_nrrole.
    msg '--ANALYSIS STARTING--' l_nrrole ' ROLES' ''.

    PERFORM summary_analysis
      TABLES gt_sum_results
             lt_agr_define.
    PERFORM collect_roles_per_conflict.
*--   User detailed Function Analysis
    PERFORM function_anal_load_matrix.
    PERFORM collect_roles_per_function.
    LOOP AT gt_fun_role.
      PERFORM 04_function_based_analysis.
    ENDLOOP.
    WAIT UNTIL g_tasksrunning = 0.
*--Process any unprocessed results
    PERFORM process_results.
*--If there are already detailed results in memory, commit them to DB
    PERFORM store_auth_results.

  ENDWHILE.
ENDFORM.                    " analyze
*---------------------------------------------------------------------*
*       FORM summary_analysis                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SUM_RESULTS                                                *
*  -->  IT_USERS                                                      *
*---------------------------------------------------------------------*
FORM summary_analysis
TABLES
  et_sum_results STRUCTURE /psyng/sw_out_routput
  lt_agr_define  STRUCTURE gt_agr_define.
  DATA : l_cnt     TYPE i,
         lt_roles  TYPE TABLE OF /psyng/sw_sod_remote_roles,
         ls_roles  TYPE /psyng/sw_sod_remote_roles,
         lt_return TYPE TABLE OF bapireturn.
  msg 'Starting Summary Analysis' '' '' ''.
  LOOP AT lt_agr_define.
    IF p_local IS INITIAL.
      ls_roles-rfcdest  = p_system.
    ELSE.
      ls_roles-rfcdest  = 'LOCAL'.
    ENDIF.
    ls_roles-agr_name = lt_agr_define-agr_name.
    APPEND ls_roles TO lt_roles.
  ENDLOOP.
***--Free user buffer memory
***  CALL FUNCTION '/PSYNG/SW_057'.
*--Summary Analysis
*  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
*       EXPORTING
*            i_org_check       = 'X'
*            i_validuser       = p_val
*            i_vrsio           = p_vrsio
*            i_config_set      = p_cfgset
*            i_shomit          = 'X'
*            i_outvdate        = ' '
*            i_exlckusr        = ' '
*            i_shonosod        = ' '
*            i_analyze_sap_all = 'X'
*            i_remote_only     = p_remon
*       TABLES
*            it_users          = it_users
*            it_confs          = s_conid
*            it_user_rfc       = s_system
*            et_outputdet      = et_sum_results.
  CALL FUNCTION '/PSYNG/SW_API_SOD_BY_ROLE'
    EXPORTING
      vrsio        = p_vrsio
      config_set   = p_cfgset
*      if_org_check = 'X'   "HBHALLA (PN-13164) (08/05/25)
      if_org_check = orgchk "HBHALLA (PN-13164) (08/05/25)
    TABLES
      roles        = lt_roles
      it_conid     = s_conid
      et_output    = et_sum_results
      et_return    = lt_return
      it_orglvl    = orglvl.

  SORT et_sum_results BY agr_name conid.
  DESCRIBE TABLE et_sum_results LINES l_cnt.
  ADD l_cnt TO g_count_summary.
  msg 'Finished Summary Analysis' '' '' ''.
ENDFORM.                    " summary_analysis

*---------------------------------------------------------------------*
*       FORM function_anal_load_matrix                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM function_anal_load_matrix.
  CALL FUNCTION '/PSYNG/SW_028'
*    DESTINATION p_system
    EXPORTING
*      i_orgcheck         = 'X'   "HBHALLA (PN-13164) (08/05/25)
      i_orgcheck         = orgchk "HBHALLA (PN-13164) (08/05/25)
      i_config_set       = p_cfgset
      i_vrsio            = p_vrsio
      i_orphan_functions = 'X'
      if_analysis        = 'X'
      i_org_field        = g_org_field "OPL645
    IMPORTING
      et_faobj_sys       = gt_faobj_system
      et_swsodorgm_sys   = gt_ao_sys
    TABLES
      et_conflict        = gt_conflict_local
      et_confdet         = gt_confdet_local
      et_functtran       = gt_functtran_local
      et_faobj           = gt_faobj_local
      et_swsodorgm       = gt_swsodorgm_local
      et_tcodes          = gt_tcodes_local
      et_functran_no_enh = gt_functran_no_enh_local
      it_rfcdest         = gt_rfcdest
      et_faobj_org       = gt_faobj_org. "OPL645
ENDFORM.
*---------------------------------------------------------------------*
*       FORM collect_roles_per_function                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM collect_roles_per_function.
*--Get functions per conflict
  DATA : lt_confdet TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         l_con_idx  TYPE i,
         l_fun_idx  TYPE i,
         l_agr_name TYPE agr_name.
  FIELD-SYMBOLS <funrole> LIKE LINE OF gt_fun_role.
  REFRESH : gt_fun_role.
  SELECT * FROM /psyng/confdet INTO TABLE lt_confdet
  WHERE vrsio = p_vrsio.
  LOOP AT lt_confdet.
*-- get conflict id details
    READ TABLE gt_con_role
    WITH TABLE KEY conid = lt_confdet-conid.
    IF sy-subrc = 0.
*  -- get function id details
      get_index gt_idx_function lt_confdet-functionid
                l_fun_idx g_idx_function.
      get_index gt_idx_conflict lt_confdet-conid
                l_con_idx g_idx_conflict.
*--Store conflict function link
      store_confun l_con_idx l_fun_idx.

      LOOP AT gt_con_role-roles INTO l_agr_name.
        READ TABLE gt_fun_role
        WITH TABLE KEY funid = lt_confdet-functionid
        ASSIGNING <funrole>.
        IF sy-subrc <> 0.
          gs_fun_role-funid = lt_confdet-functionid.
          REFRESH gs_fun_role-roles[].
          INSERT  gs_fun_role INTO TABLE gt_fun_role.
          READ TABLE gt_fun_role
          WITH TABLE KEY funid = lt_confdet-functionid
          ASSIGNING <funrole>.
        ENDIF.
        IF <funrole> IS ASSIGNED.
          INSERT l_agr_name INTO TABLE <funrole>-roles.
        ELSE.
          msg 'ERROR <funrole> not assigned'
          lt_confdet-functionid '' ''.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " collect_roles_per_function
*---------------------------------------------------------------------*
*       FORM collect_roles_per_conflict                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM collect_roles_per_conflict.
  DATA : l_role_idx TYPE i,
         l_con_idx  TYPE i.
  FIELD-SYMBOLS <conrole> LIKE LINE OF gt_con_role.
  DATA: l_mit_by_role TYPE /psyng/se_config_param-value,
        ls_agr_texts  TYPE agr_texts.
  REFRESH : gt_con_role[].
  se_config_param 'SW_MIT_BY_ROLE' l_mit_by_role.
  LOOP AT gt_sum_results.
*--collect roles for determining fields in header table
*  CONFLICTED_ROLES
*  MITIGATED_ROLES
*  MITIGATED_CON
    IF l_mit_by_role EQ '2'
    OR l_mit_by_role EQ '3'.
      IF NOT gt_sum_results-contid IS INITIAL.
        ADD 1 TO g_count_summary_mit.
        gt_mitigated_roles-role = gt_sum_results-agr_name.
        gt_mitigated_roles-count = 1.
        COLLECT gt_mitigated_roles.
      ENDIF.
    ENDIF.
    gt_conflicted_roles-role = gt_sum_results-agr_name.
    gt_conflicted_roles-count = 1.
    COLLECT gt_conflicted_roles.

*-- get role id details
    get_index gt_idx_role gt_sum_results-agr_name
              l_role_idx g_idx_role.
*--Store role details
    store_role l_role_idx gt_sum_results ls_agr_texts.
*-- get conflict id details
    get_index gt_idx_conflict gt_sum_results-conid
              l_con_idx g_idx_conflict.
*--Store role conflict info
    store_rolecon l_role_idx l_con_idx gt_sum_results-contid.
    READ TABLE gt_con_role
    WITH TABLE KEY conid = gt_sum_results-conid
    ASSIGNING <conrole>.
    IF sy-subrc <> 0.
      gs_con_role-conid = gt_sum_results-conid.
      REFRESH gs_con_role-roles[].
      INSERT  gs_con_role INTO TABLE gt_con_role.
      READ TABLE gt_con_role
      WITH TABLE KEY conid = gt_sum_results-conid
      ASSIGNING <conrole>.
    ENDIF.
    IF <conrole> IS ASSIGNED.
      INSERT gt_sum_results-agr_name INTO TABLE <conrole>-roles.
    ELSE.
      msg 'ERROR <conrole> not assigned' gt_sum_results-conid '' ''.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " collect_roles_per_conflict
*---------------------------------------------------------------------*
*       FORM 04_function_based_analysis                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 04_function_based_analysis.
  RANGES : lr_roles FOR agr_define-agr_name,
           lr_funid FOR gt_fun_role-funid.
  DATA   : l_numroles TYPE i.


*-Create range of roles, in batches of 10?
*-Call detailed analysis on function and batch
*-do something with the results here
  lr_funid-sign   = 'I'.
  lr_funid-option = 'EQ'.
  lr_funid-low    = gt_fun_role-funid.
  APPEND lr_funid.
  DESCRIBE TABLE gt_fun_role-roles LINES l_numroles.
  msg ' |_Detailed Analysis '  gt_fun_role-funid ' #roles' l_numroles.
  CLEAR gt_runtime.
  gt_runtime-id    = gt_fun_role-funid.
  gt_runtime-roles = l_numroles.
  gt_runtime-startd = sy-datum.
  gt_runtime-startt = sy-uzeit.
  CLEAR l_numroles.

  LOOP AT gt_fun_role-roles INTO lr_roles-low.

    lr_roles-sign   = 'I'.
    lr_roles-option = 'EQ'.
    APPEND lr_roles.
    ADD 1 TO l_numroles.
    IF l_numroles >= p_dtbtch.
*--Process batch of roles
      PERFORM analyze_details_function
      TABLES
          lr_funid
          lr_roles.
      REFRESH lr_roles.
      CLEAR l_numroles.
    ENDIF.
  ENDLOOP.
*--Process remainder
  IF l_numroles > 0.
    PERFORM analyze_details_function
      TABLES
        lr_funid
        lr_roles.
    REFRESH lr_roles.

  ENDIF.
*--Let all started tasks finish.
  WAIT UNTIL g_tasksrunning = 0.
  PERFORM add_runtime.
ENDFORM.                    " function_based_analysis
*---------------------------------------------------------------------*
*       FORM add_runtime                                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM add_runtime.
  FIELD-SYMBOLS <rt> LIKE gt_runtime.
  gt_runtime-endd = sy-datum.
  gt_runtime-endt = sy-uzeit.
  CALL FUNCTION 'SWI_DURATION_DETERMINE'
    EXPORTING
      start_date = gt_runtime-startd
      end_date   = gt_runtime-endd
      start_time = gt_runtime-startt
      end_time   = gt_runtime-endt
    IMPORTING
      duration   = gt_runtime-seconds.
  IF gt_runtime-seconds = 0. gt_runtime-seconds = 1. ENDIF.
  gt_runtime-minutes = gt_runtime-seconds / 60.
  gt_runtime-hours   = gt_runtime-minutes / 60.
  READ TABLE gt_runtime WITH KEY  id = gt_runtime-id
  ASSIGNING <rt>.
  IF sy-subrc  <> 0.
    APPEND gt_runtime.
  ELSE.
    ADD gt_runtime-seconds TO <rt>-seconds.
  ENDIF.




ENDFORM.                    " add_runtime
*---------------------------------------------------------------------*
*       FORM analyze_details_function                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IR_FUNID                                                      *
*  -->  IR_USERS                                                      *
*---------------------------------------------------------------------*
FORM analyze_details_function
TABLES  ir_funid STRUCTURE /psyng/range_funid
        ir_roles STRUCTURE /psyng/range_agr_name.
  DATA :
    lt_results         TYPE TABLE OF /psyng/sw_out_routdet3
                       WITH HEADER LINE,
    l_numroles         TYPE i,
    l_taskname         TYPE string,
    l_str              TYPE string,
    lf_remote          TYPE flag,
    ls_faobj_system    TYPE /psyng/sw_sys_faobj,
    ls_ao_sys          TYPE /psyng/sw_sys_ao,
    l_system           TYPE rfcdest,
    lt_faobj_sys       TYPE TABLE OF /psyng/faobj2,
    lt_conflict_local  TYPE TABLE OF /psyng/conflict
                       WITH HEADER LINE,
    lt_confdet_local   TYPE TABLE OF /psyng/confdet
                       WITH HEADER LINE,
    lt_functtran_local TYPE TABLE OF /psyng/functtran,
    lt_sodorgm         TYPE TABLE OF /psyng/swsodorgm
                       WITH HEADER LINE,
    lt_rfcdest         TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                       WITH HEADER LINE,
    l_mem_used         TYPE i.


*--Process any unprocessed results
  PERFORM process_results.
*--If there are already detailed results in memory, commit them to DB
  PERFORM store_auth_results.
  READ TABLE ir_funid INDEX 1.

  lt_conflict_local[]  = gt_conflict_local[].
  lt_confdet_local[]   = gt_confdet_local[].
  lt_functtran_local[] = gt_functtran_local[].

  DELETE lt_confdet_local WHERE functionid <> ir_funid-low.
  DELETE lt_functtran_local WHERE functionid <> ir_funid-low.
  SORT lt_confdet_local BY functionid.
  DELETE ADJACENT DUPLICATES FROM lt_confdet_local COMPARING
functionid.

*  LOOP AT lt_conflict_local.
*    READ TABLE lt_confdet_local
*    WITH KEY conid = lt_conflict_local-conid.
*    IF sy-subrc NE 0.
*      DELETE lt_conflict_local.
*    ENDIF.
*  ENDLOOP.

  l_system = gt_rfcdest-rfcoptions.
*--Give the task a unique name
  ADD 1 TO g_tasknumber.
  WAIT UNTIL g_tasksrunning < p_maxtsk.
  ADD 1 TO g_tasksrunning.
  l_str = g_tasknumber.
  CONCATENATE 'SW_FUN_DET_' ir_funid-low '_' l_str INTO l_taskname.
  DESCRIBE TABLE ir_roles LINES l_numroles.
  register_task l_taskname l_system.

*    msg '-->Starting task ' l_taskname  '#users' l_numusers.
* --Variable Elements, get the correct values for the remote system
  READ TABLE ir_funid INDEX 1.
  READ TABLE gt_faobj_system INTO ls_faobj_system
  WITH KEY rfcdest = l_system.
  IF sy-subrc = 0.
    lt_faobj_sys[] = ls_faobj_system-faobj[].
*  lt_faobj_sys[] = gt_faobj_local[].
*    DELETE lt_faobj_sys WHERE funid <> ir_funid-low.
  ENDIF.
*--Org Elements, get the correct values for the system
  CLEAR ls_ao_sys.
  READ TABLE gt_ao_sys INTO ls_ao_sys
  WITH KEY rfcdest = l_system.

*--Remove sodorgm data that is not for relevant objects
*  REFRESH : lt_sodorgm.
*  SORT lt_faobj_sys BY object.
*  LOOP AT ls_ao_sys-swsodorgm INTO lt_sodorgm.
**  LOOP AT gt_swsodorgm_local INTO lt_sodorgm.
*    READ TABLE lt_faobj_sys WITH KEY object = lt_sodorgm-object
*    BINARY SEARCH TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      APPEND lt_sodorgm.
*    ENDIF.
*  ENDLOOP.


  REFRESH :lt_rfcdest.
  lt_rfcdest-sign   = 'I'.
  lt_rfcdest-option = 'EQ'.
  lt_rfcdest-low =   gt_rfcdest-rfcdest.
  APPEND lt_rfcdest.
  IF NOT p_system IS INITIAL.
    lf_remote = 'X'.
  ELSE.
    CLEAR lf_remote .
    REFRESH : lt_rfcdest.
  ENDIF.

*  IF gt_rfcdest-rfcdest IS INITIAL.
*--Execute the detailed analysis
  CALL FUNCTION '/PSYNG/FUNC_ROLE_DET_ANALYSIS'
    STARTING NEW TASK l_taskname
    PERFORMING get_detailed_function_res ON END OF TASK
    EXPORTING
      i_showcomp        = 'X'
*      i_orgchk          = 'X'   "HBHALLA (PN-13164) (08/05/25)
      i_orgchk          = orgchk "HBHALLA (PN-13164) (08/05/25)
      i_sodvrsio        = p_vrsio
      i_config_set      = p_cfgset
      i_ronlyrem        = lf_remote
      i_composite_roles = p_comp
      i_single_roles    = p_sing
      i_assigned_roles  = p_assr
    i_org_field       = g_org_field "OPL645
* IMPORTING
*     E_ROLECOUNT       =
    TABLES
      it_roles          = ir_roles
      it_rfcdest        = lt_rfcdest
      et_outputdet      = lt_results
      it_conflict       = lt_conflict_local
      it_confdet        = lt_confdet_local
      it_functtran      = lt_functtran_local
      it_faobj          = lt_faobj_sys
*     it_swsodorgm      = lt_sodorgm.
      it_swsodorgm      = ls_ao_sys-swsodorgm[]
      it_faobj_org      = gt_faobj_org "OPL645
      it_orglvl         = orglvl.
*  ELSE.
*    CALL FUNCTION '/PSYNG/FUNC_ROLE_DET_ANALYSIS'
*      STARTING NEW TASK l_taskname
*      DESTINATION gt_rfcdest-rfcdest
*      PERFORMING get_detailed_function_res ON END OF TASK
*     EXPORTING
*       i_showcomp        = 'X'
*       i_orgchk          = 'X'
*       i_sodvrsio        = p_vrsio
*       i_config_set      = p_cfgset
*      i_rolerfc          = gt_rfcdest-rfcdest
*      i_composite_roles  = p_comp
*      i_single_roles     = p_sing
*      i_assigned_roles   = p_assr
** IMPORTING
**   E_ROLECOUNT                 =
*     TABLES
*       it_roles           = ir_roles
*       et_outputdet       = lt_results
*       it_confdet         = lt_confdet_local
*       it_functtran       = lt_functtran_local
*       it_faobj           = lt_faobj_sys
*       it_swsodorgm       = lt_sodorgm.
*  ENDIF.
ENDFORM.                    "
*---------------------------------------------------------------------*
*       FORM get_detailed_function_res                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TASKNAME                                                    *
*---------------------------------------------------------------------*
FORM get_detailed_function_res USING i_taskname.
  DATA :
    lt_results       TYPE TABLE OF /psyng/sw_out_routdet3
                     WITH HEADER LINE,
    l_system_msg(80) TYPE c,
    l_numres         TYPE i,
    l_det            TYPE i,
    l_task           LIKE LINE OF gt_idx_task.

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/FUNC_ROLE_DET_ANALYSIS'
    TABLES
          et_outputdet                = lt_results
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.

  SUBTRACT 1 FROM g_tasksrunning.

  IF sy-subrc <> 0.
    msg_nc 'Failed task' i_taskname sy-subrc l_system_msg.
    ADD 1 TO g_failedtasks.
  ELSE.
    DESCRIBE TABLE lt_results LINES l_numres.

    ADD l_numres TO g_totalresults.
    l_task-task = i_taskname.

    READ TABLE gt_idx_task WITH TABLE KEY task = l_task-task.
    IF sy-subrc = 0.
      APPEND LINES OF lt_results TO gt_det_results. "C1476
*      gt_det_results[]   = lt_results[].
      FREE lt_results.
    ELSE.
      msg_nc 'ERROR' 'Failed to lookup system for Task'
     i_taskname ''.
    ENDIF.
  ENDIF.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM process_results                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM process_results.
*  LOOP AT gt_det_results.
  PERFORM process_detailed_res
    TABLES gt_det_results.
  REFRESH : gt_det_results.
*    DELETE gt_det_results.
*  ENDLOOP.
*--Clear unused memory when we have a chance.
  IF gt_det_results[] IS INITIAL.
    FREE gt_det_results.
  ENDIF.
ENDFORM.                    " process_results
*---------------------------------------------------------------------*
*       FORM process_detailed_res                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_RESULTS                                                    *
*  -->  IT_USER_PROF                                                  *
*  -->  I_SYSID                                                       *
*---------------------------------------------------------------------*
FORM process_detailed_res
TABLES   it_results STRUCTURE /psyng/sw_out_routdet3.
  DATA : l_fun_idx   TYPE i,
         l_con_idx   TYPE i,
         l_role_idx  TYPE i,
         l_child_idx TYPE i,
         l_tcode_idx TYPE i,
         l_obj_idx   TYPE i,
         l_field_idx TYPE i,
         l_auth_idx  TYPE i,
         l_abb_idx   TYPE i.
  LOOP AT it_results.
*-- get role id details
    get_index gt_idx_role it_results-agr_name
              l_role_idx g_idx_role.
*-- get function id details
    get_index gt_idx_function it_results-functionid
              l_fun_idx g_idx_function.
*-- get tcode details
    get_index gt_idx_tcode it_results-tcode
              l_tcode_idx g_idx_tcode.
*-- get object details
    get_index gt_idx_object it_results-objct
              l_obj_idx g_idx_object.
*-- get field details
    get_index gt_idx_field it_results-field
              l_field_idx g_idx_field.
*-- get auth details
    get_index gt_idx_auth it_results-auth
              l_auth_idx g_idx_auth.
*-- get child role details
    IF NOT it_results-child_agr IS INITIAL.
      get_index gt_idx_child it_results-child_agr
                l_child_idx g_idx_child.
*--Store role child role combo
      store_rolechild
        l_role_idx l_auth_idx l_child_idx.
    ENDIF.
*--Store the details
*--out of macro params, store org abb directly
    gt_db_vonbisabb-abb = it_results-org_abb.
    store_authdetails '' l_fun_idx l_role_idx
                      l_tcode_idx l_obj_idx l_field_idx
                      l_auth_idx it_results-von it_results-bis.
    IF NOT it_results-org_abb IS INITIAL.
      get_index gt_idx_abb it_results-org_abb
                l_abb_idx g_idx_abb.
      store_rolefunabb
        l_role_idx l_fun_idx l_abb_idx.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " process_detailed_results

*---------------------------------------------------------------------*
*       FORM store_auth_results                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM store_auth_results.
*--Store the Auth Details in the database
  DATA : l_det             TYPE i,
         l_record          TYPE string,
         l_alldata         TYPE string,
         l_tmp             TYPE string,
         l_fieldseparator  TYPE c VALUE ',',
         l_recordseparator TYPE c VALUE '-',
         lt_resc           TYPE TABLE OF /psyng/swrrscaut
        WITH               HEADER LINE,
         lt_resc2          TYPE TABLE OF /psyng/swrrscaut
       WITH               HEADER LINE,

         ls_resc_id        TYPE /psyng/swrrscaut,
         ls_resc_id_prev   TYPE /psyng/swrrscaut,
         l_len             TYPE i,
         l_numoriginal     TYPE i,
         l_rt_start        TYPE i,
         l_rt_end          TYPE i.

*--Error detection, store nr of records per function profile
  TYPES : BEGIN OF typ_stats,
            funindex    TYPE i,
            profindex   TYPE i,
            numprofiles TYPE i,
          END OF typ_stats.
  STATICS : st_stats TYPE SORTED TABLE OF typ_stats
  WITH NON-UNIQUE KEY funindex profindex
  WITH HEADER LINE.

  IF NOT gt_db_authdetails[] IS INITIAL.
    GET RUN TIME FIELD l_rt_start.
    DESCRIBE TABLE gt_db_authdetails LINES l_numoriginal.

*--Concatenate into a single field so storing in db is faster
* tcodeindex, objectindex fieldindex,
* vbaindex, authindex
    DEFINE concat_int.
      l_tmp = &2.
      condense l_tmp.
      if &1 is initial.
        &1 = l_tmp.
      else.
        concatenate &1 l_fieldseparator l_tmp into &1.
      endif.
    END-OF-DEFINITION.

    LOOP AT gt_db_authdetails.
      MOVE-CORRESPONDING gt_db_authdetails TO ls_resc_id.
      ls_resc_id-roleindex = gt_db_authdetails-profileindex.
      READ TABLE gt_idx_caut WITH TABLE KEY
        funindex     = ls_resc_id-funindex
        roleindex    = ls_resc_id-roleindex.
      IF sy-subrc = 0.
*    --This role has already been stored for this function
      ELSE.
        IF ls_resc_id_prev IS INITIAL.
          ls_resc_id_prev = ls_resc_id.
        ENDIF.
        IF ls_resc_id <> ls_resc_id_prev.
*  --a full role has been handled
          lt_resc = ls_resc_id_prev.
          lt_resc-dataindex = 0.

          WHILE NOT l_alldata IS INITIAL.
            l_len = strlen( l_alldata ).
            IF l_len > 255.
              l_len = 255.
            ENDIF.
            lt_resc-data = l_alldata(l_len).
            l_alldata = l_alldata+l_len.
            ADD 1 TO lt_resc-dataindex.
            APPEND lt_resc.

            CLEAR lt_resc-data.
          ENDWHILE.
          MOVE-CORRESPONDING lt_resc TO gt_idx_caut.
          INSERT TABLE gt_idx_caut.
        ENDIF.
        CLEAR l_record.
        concat_int l_record :
         gt_db_authdetails-tcodeindex,
         gt_db_authdetails-objectindex,
         gt_db_authdetails-fieldindex,
         gt_db_authdetails-vbaindex,
         gt_db_authdetails-authindex.
        CONDENSE l_record.
        IF l_alldata IS INITIAL.
          l_alldata = l_record.
        ELSE.
          CONCATENATE l_alldata l_recordseparator l_record
          INTO l_alldata.
        ENDIF.

        ls_resc_id_prev = ls_resc_id.
      ENDIF.
    ENDLOOP.
*--Process last role
    IF NOT l_alldata IS INITIAL.
      READ TABLE gt_idx_caut WITH TABLE KEY
        funindex     = ls_resc_id-funindex
        roleindex    = ls_resc_id-roleindex.
      IF sy-subrc <> 0.
        lt_resc = ls_resc_id.
        lt_resc-dataindex = 0.
        WHILE NOT l_alldata IS INITIAL.
          l_len = strlen( l_alldata ).
          IF l_len > 255.
            l_len = 255.
          ENDIF.
          lt_resc-data = l_alldata(l_len).
          l_alldata = l_alldata+l_len.
          ADD 1 TO lt_resc-dataindex.
          APPEND lt_resc.
          CLEAR lt_resc-data.
        ENDWHILE.
        MOVE-CORRESPONDING lt_resc TO gt_idx_caut.
        INSERT TABLE gt_idx_caut.
      ENDIF.
    ENDIF.
    MODIFY /psyng/swrrscaut FROM TABLE lt_resc.
    DESCRIBE TABLE lt_resc LINES l_det.
    ADD l_det TO g_nr_authdetails.
    FREE lt_resc.
    REFRESH : gt_db_authdetails.

    GET RUN TIME FIELD l_rt_end.
    l_rt_end = l_rt_end - l_rt_start.
    ADD l_rt_end TO g_storage_ms_a.
  ENDIF.

ENDFORM.                    " store_auth_results
*---------------------------------------------------------------------*
*       FORM 06_summarize_results                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FUNINFO                                                     *
*---------------------------------------------------------------------*
FORM 06_summarize_results USING i_funinfo TYPE flag.
  DATA : l_lines     TYPE i,
         l_total     TYPE p,
         l_tables    TYPE p,
         l_secperu   TYPE p,
         l_bytes     TYPE i,
         l_bytes_p   TYPE p,
         l_kbytes    TYPE p,
         l_mbytes    TYPE p,
         l_lines_c   TYPE string,
         l_mbytes_c  TYPE string,
         l_size      TYPE string,
         l_unit      TYPE string,
         l_seconds   TYPE i,
         l_minutes   TYPE i,
         l_hours     TYPE i,
         l_seconds_s TYPE string,
         l_minutes_s TYPE string,
         l_hours_s   TYPE string,

         l_str       TYPE string,
         l_char(72)  TYPE c.

  msg '---------------------' '---------------------'
'---------------------' '---------------------'.
  msg '|                    ' 'Job Summary   '
'                     ' '                    |'.
  msg '---------------------' '---------------------'
'---------------------' '---------------------'.


  DEFINE summary_info.
    select count( * ) into l_lines from &3
    where aid = gs_db_header-aid.                "#EC SAST_CI_GEN_CHECK

    add l_lines to l_total.
    add 1 to l_tables.
    perform get_bytes using &2 changing l_bytes.
    l_bytes_p = l_bytes * l_lines.
    l_kbytes = l_bytes_p / 1024.
    add l_kbytes to g_storage_kb_est .
    l_mbytes = l_kbytes / 1024.
    l_lines_c = l_lines.
    if l_mbytes > 0.
      l_mbytes_c = l_mbytes.
      l_unit     = 'Mb'.
    elseif l_kbytes > 0.
      l_mbytes_c = l_kbytes.
      l_unit     = 'Kb'.
    else.
      l_mbytes_c = l_bytes.
      l_unit     = 'B'.
    endif.

    concatenate l_lines_c 'lines.' l_mbytes_c l_unit into l_size
    separated by space.
    message s002(/psyng/sw) with &1 &2  l_size.
  END-OF-DEFINITION.

  DEFINE summary_info_noai.
    select count( * ) into l_lines from &3.             "#EC CI_NOWHERE
    message s002(/psyng/sw) with &1 &2 l_lines.
    add l_lines to l_total.
    add 1 to l_tables.
  END-OF-DEFINITION.


*--Print info about how long storage took
  l_seconds = g_storage_ms_a / 1000000.
  IF l_seconds > 60.
    l_minutes = l_seconds / 60.
    l_seconds = l_seconds MOD 60.
  ENDIF.
  IF l_minutes > 60.
    l_hours = l_minutes / 60.
    l_minutes = l_hours MOD 60.
  ENDIF.
  l_hours_s   = l_hours.
  l_minutes_s = l_minutes.
  l_seconds_s = l_seconds.
  CONCATENATE l_hours_s ':' l_minutes_s ':' l_seconds_s INTO l_str.
  CONDENSE l_str NO-GAPS.
  msg '# Auth Details Storage Time'  l_str   '' ''.
  l_seconds = g_storage_ms / 1000000.
  IF l_seconds > 60.
    l_minutes = l_seconds / 60.
    l_seconds = l_seconds MOD 60.
  ENDIF.
  IF l_minutes > 60.
    l_hours = l_minutes / 60.
    l_minutes = l_hours MOD 60.
  ENDIF.
  l_hours_s   = l_hours.
  l_minutes_s = l_minutes.
  l_seconds_s = l_seconds.
  CONCATENATE l_hours_s ':' l_minutes_s ':' l_seconds_s INTO l_str.
  CONDENSE l_str NO-GAPS.
  msg '# Other Details Storage Time'  l_str   '' ''.

*--Print info about storage
  summary_info_noai 'Global Index Tables ':
   '/PSYNG/SWRESVBA'  /psyng/swresvba.                  "#EC CI_NOWHERE

  summary_info 'Index Tables' :
  '/PSYNG/SWRRSICON'  /psyng/swrrsicon,
  '/PSYNG/SWRRSITCD'  /psyng/swrrsitcd,
  '/PSYNG/SWRRSIOBJ'  /psyng/swrrsiobj,
  '/PSYNG/SWRRSIFLD'  /psyng/swrrsifld,
  '/PSYNG/SWRRSIFUN'  /psyng/swrrsifun,
  '/PSYNG/SWRRSIAUT'  /psyng/swrrsiaut,
  '/PSYNG/SWRRSICHD'  /psyng/swrrsichd,
  '/PSYNG/SWRRSIABB'  /psyng/swrrsiabb.          "#EC SAST_CI_GEN_CHECK

  summary_info 'Data Tables' :
   '/PSYNG/SWRRSCAUT'  /psyng/swrrscaut,
   '/PSYNG/SWRRSCON'   /psyng/swrrscon,
   '/PSYNG/SWRRSROL'   /psyng/swrrsrol,
   '/PSYNG/SWRRSCFUN'  /psyng/swrrscfun,
   '/PSYNG/SWRRSRCHD'  /psyng/swrrsrchd,
   '/PSYNG/SWRRSRABB'  /psyng/swrrsrabb.         "#EC SAST_CI_GEN_CHECK

*--Add storage info to header record
*  we estimate about 25% extra is needed for indexes and general
*  overhead on top of the raw record storage
  gs_db_header-kbytes_est = ( g_storage_kb_est * 125 ) / 100 .
  MODIFY /psyng/swrrshdr FROM gs_db_header.
  COMMIT WORK.


  msg_nc '#records : ' l_total 'in #tables' l_tables.
  IF i_funinfo = 'X'.
*  --Display how long we spent on each conflict/function
    SORT gt_runtime BY seconds DESCENDING.
    msg 'Runtime Information' '' '' ''.
    CLEAR l_char.
    l_char    = 'ID'.
    l_char+15 = 'seconds'.
    l_char+25 = 'roles'.
    l_char+35 = 'roles/second'.
*    msg 'ID' 'seconds' 'users' 'user/second'.
    msg l_char '' '' ''.
    LOOP AT gt_runtime.
      CLEAR l_char.
      l_secperu = gt_runtime-roles  / gt_runtime-seconds.
      l_char    = gt_runtime-id.
      l_str = gt_runtime-seconds.
      CONDENSE l_str.
      l_char+15 = l_str.
      l_str = gt_runtime-roles.
      CONDENSE l_str.
      l_char+25 = l_str.
      l_str = l_secperu.
      CONDENSE l_str.
      l_char+35 = l_str.
*      msg gt_runtime-id gt_runtime-seconds gt_runtime-users l_secperu.
      msg l_char '' '' ''.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " summarize_results
*---------------------------------------------------------------------*
*       FORM 05_store_results                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 05_store_results.
  DATA : lt_conflict TYPE TABLE OF /psyng/swrrsicon WITH HEADER LINE,
         lt_childrol TYPE TABLE OF /psyng/swrrsichd WITH HEADER LINE,
         lt_tcode    TYPE TABLE OF /psyng/swrrsitcd WITH HEADER LINE,
         lt_object   TYPE TABLE OF /psyng/swrrsiobj WITH HEADER LINE,
         lt_field    TYPE TABLE OF /psyng/swrrsifld WITH HEADER LINE,
         lt_function TYPE TABLE OF /psyng/swrrsifun WITH HEADER LINE,
         lt_auth     TYPE TABLE OF /psyng/swrrsiaut WITH HEADER LINE,
         lt_abb      TYPE TABLE OF /psyng/swrrsiabb WITH HEADER LINE,
         l_rt_start  TYPE i,
         l_rt_end    TYPE i,
         l_cnt_con   TYPE i,
         l_cnt_mit   TYPE i.

  DEFINE convert_val_table.
    loop at &1.
      move-corresponding &1 to &2.
      &2-&3 = &1-key.
      &2-&4 = &1-index.
      &2-aid = gs_db_header-aid.
      append &2.
    endloop.
    free &1.
    modify (&5) from table &2.
    free &2.
    message s002(/psyng/sw) with 'STORED:' &5.

    commit work.

  END-OF-DEFINITION.

  DEFINE store_db_table.
    modify (&1) from table &2.
    free &2.
    message s002(/psyng/sw) with 'STORED:' &1.

    commit work.
  END-OF-DEFINITION.


  msg '---------------------' '---------------------'
'---------------------' '---------------------'.

  PERFORM store_auth_results.

*--Add details about the analysis
  gs_db_header-conflicts     = g_count_summary.
  gs_db_header-mitigated_con = g_count_summary_mit.
*--Count : conflicted roles ( at least one unmitigated conflict)
*          mitigated roles  ( has conflicts, all mitigated )
  SORT : gt_conflicted_roles BY role,
         gt_mitigated_roles  BY role.
  LOOP AT gt_conflicted_roles.
    l_cnt_con = gt_conflicted_roles-count.
    CLEAR l_cnt_mit.
    READ TABLE gt_mitigated_roles
      WITH KEY role = gt_conflicted_roles-role BINARY SEARCH.
    IF sy-subrc <> 0.
*--No conflicts Mitigated
      ADD 1 TO gs_db_header-conflicted_roles.
    ELSE.
      l_cnt_mit = gt_mitigated_roles-count.
      IF gt_mitigated_roles-count < gt_conflicted_roles-count.
*--More conflicts than mitigated
        ADD 1 TO gs_db_header-conflicted_roles.
      ELSE.
*--All conflicts mitigated
        ADD 1 TO gs_db_header-mitigated_roles.
      ENDIF.
    ENDIF.
    role_count_con gt_conflicted_roles-role l_cnt_con l_cnt_mit.
  ENDLOOP.


  GET RUN TIME FIELD l_rt_start.
  msg 'Start Inverting the indexes' '' '' ''.
  invert_index :
      gt_idx_conflict      gt_val_conflict,
      gt_idx_role          gt_val_role,
      gt_idx_function      gt_val_function,
      gt_idx_child         gt_val_child,
      gt_idx_tcode         gt_val_tcode,
      gt_idx_object        gt_val_object,
      gt_idx_field         gt_val_field,
      gt_idx_auth          gt_val_auth,
      gt_idx_abb           gt_val_abb,
      gt_db_vonbisabb      gt_idx_vonbisabb.
  msg 'Finished Inverting the indexes' '' '' ''.

*--Determine which roles belong to the profiles,
*  and how they are assigned to the users

  store_db_table : '/PSYNG/SWRESVBA'   gt_db_vonbisabb,
                   '/PSYNG/SWRRSROL'   gt_db_roles,
                   '/PSYNG/SWRRSCON'   gt_db_rolecon,
                   '/PSYNG/SWRRSCFUN'  gt_db_confun,
                   '/PSYNG/SWRRSRCHD'  gt_db_rolechild,
                   '/PSYNG/SWRRSRABB'  gt_db_rfunabb.
*--Value tables all have KEY field in memory,
* but specific named fields in DB
* Convert and store them
  convert_val_table :
    gt_val_conflict lt_conflict conid    conindex    '/PSYNG/SWRRSICON',
    gt_val_child    lt_childrol agr_name childindex  '/PSYNG/SWRRSICHD',
    gt_val_tcode    lt_tcode    tcode    tcodeindex  '/PSYNG/SWRRSITCD',
    gt_val_object   lt_object   object   objectindex '/PSYNG/SWRRSIOBJ',
    gt_val_field    lt_field    field    fieldindex  '/PSYNG/SWRRSIFLD',
    gt_val_function lt_function funid    funindex    '/PSYNG/SWRRSIFUN',
    gt_val_auth     lt_auth     auth     authindex   '/PSYNG/SWRRSIAUT',
    gt_val_abb      lt_abb      org_abb  abbindex    '/PSYNG/SWRRSIABB'.

  gs_db_header-sysid           = gt_rfcdest-rfcoptions.
  gs_db_header-det_job_success = g_tasknumber - g_failedtasks.
  gs_db_header-det_job_failed  = g_failedtasks.
  msg 'Analysis and Storage completed' '' '' ''.

*--Register the end time for the analysis
  gs_db_header-end_time      = sy-uzeit.
  gs_db_header-end_date      = sy-datum.
  gs_db_header-delete_date   = gs_db_header-end_date + p_retday.
  gs_db_header-delete_date_det = gs_db_header-end_date + p_retdet.
  gs_db_header-delete_date_sum = gs_db_header-end_date + p_retsum.
  IF gs_db_header-delete_date IS INITIAL.
    gs_db_header-delete_date = '99991231'. "later than sap can handle
  ENDIF.

*--Calculate duration
  DATA: l_hr           TYPE i,
        l_mn           TYPE i,
        l_se           TYPE i,
        l_duration(16) TYPE c,
        l_nums         TYPE numc2,
        l_numm         TYPE numc2,
        l_strh         TYPE string.
  cl_abap_tstmp=>td_subtract(
   EXPORTING
    date2 = gs_db_header-start_date time2 = gs_db_header-start_time
    date1 = gs_db_header-end_date   time1 = gs_db_header-end_time
   IMPORTING
     res_secs = l_se
   ).
  l_hr = l_se DIV 3600.
  l_se = l_se MOD 3600.
  l_mn = l_se DIV 60.
  l_se = l_se MOD 60.
  MOVE l_se TO l_nums .
  MOVE l_mn TO l_numm.
  MOVE l_hr TO l_strh.
  CONDENSE l_strh.
  CONCATENATE l_strh ':' l_numm ':' l_nums INTO l_duration.
  msg 'Duration' l_duration '' ''.
  gs_db_header-duration = l_duration.

  gs_db_header-finished        = 'X'.

  MODIFY /psyng/swrrshdr FROM gs_db_header.
  COMMIT WORK.
  GET RUN TIME FIELD l_rt_end.
  l_rt_end = l_rt_end - l_rt_start.
  ADD l_rt_end TO g_storage_ms.

ENDFORM.                    " store_results

*---------------------------------------------------------------------*
*       FORM get_bytes                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_TABNAME                                                     *
*  -->  E_LEN                                                         *
*---------------------------------------------------------------------*
FORM get_bytes USING i_tabname TYPE ddobjname
               CHANGING e_len TYPE i.
  DATA : lt_dfies TYPE TABLE OF dfies WITH HEADER LINE.
  PERFORM get_dfies
              TABLES
                 lt_dfies
              USING
                 i_tabname.
  CLEAR e_len.
  LOOP AT lt_dfies.
    ADD lt_dfies-intlen TO e_len.
  ENDLOOP.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_dfies                                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_DFIES                                                      *
*  -->  I_TABNAME                                                     *
*---------------------------------------------------------------------*
FORM get_dfies  TABLES   et_dfies  STRUCTURE dfies
                USING    i_tabname TYPE      ddobjname.

  TYPES :
    BEGIN OF ty_dfies_list,
      tabname TYPE ddobjname,
      dfies   TYPE ddfields,
    END OF  ty_dfies_list.

  STATICS : st_dfies_list TYPE HASHED TABLE OF ty_dfies_list
                          WITH UNIQUE KEY tabname
                          WITH HEADER LINE.

  READ TABLE st_dfies_list WITH TABLE KEY tabname = i_tabname.
  IF sy-subrc = 0.
    et_dfies[] = st_dfies_list-dfies[].
  ELSE.
    CALL FUNCTION 'DDIF_NAMETAB_GET'
      EXPORTING
        tabname   = i_tabname
      TABLES
        dfies_tab = et_dfies
      EXCEPTIONS
        not_found = 1
        OTHERS    = 2.
*BOC:HBHALLA (03/12/24)
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE s002(/psyng/sw)
       WITH 'No Active Runtime Object Found for TABNAME'.
        WHEN OTHERS.
          MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
      ENDCASE.
    ENDIF.
*EOC:HBHALLA (03/12/24)
    SORT et_dfies BY fieldname.
    st_dfies_list-tabname = i_tabname.
    st_dfies_list-dfies[] = et_dfies[].

    INSERT TABLE st_dfies_list.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM rfc_validations                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM rfc_validations.
DATA: lr_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE,
lt_bapiret TYPE TABLE OF bapiret2.
  DATA: lt_ret TYPE TABLE OF bapiret2,
        ls_ret TYPE bapiret2.
  CLEAR gf_invalid_rfc.
*refresh lt_bapiret.
  lr_rfcs-sign   = 'I'.
  lr_rfcs-option = 'EQ'.
  lr_rfcs-low    = p_system.

  APPEND lr_rfcs.

  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup   = 'N'
      i_module  = 'SE'
    TABLES
      it_rfcdes = lr_rfcs
      et_return = lt_ret.

  IF NOT lt_ret IS INITIAL.
    READ TABLE lt_ret INTO ls_ret INDEX 1.
    MESSAGE s002(/psyng/sw) WITH ls_ret-message.
    gf_invalid_rfc = 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.



*---------------------------------------------------------------------*
*       FORM set_button_icons                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'ANB_BUT'  'X' CHANGING anb_but .
  PERFORM init_but USING 'BGD_BUT'  'X' CHANGING bgd_but .
  PERFORM init_but USING 'ANAT_BUT' '' CHANGING anat_but .
  PERFORM init_but USING 'SYSB_BUT' 'X' CHANGING sysb_but .
  PERFORM init_but USING 'EXE_BUT'  '' CHANGING exe_but  .
  PERFORM init_but USING 'RESB_BUT' 'X' CHANGING resb_but .



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
    CLEAR g_button_set.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
    g_button_set = 'X'.
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
*     text       = text-b01
*     info       = text-x02
      name       = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result     = button
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             icon_not_found = 1
             outputfield_too_short = 2
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
*EOC:HBHALLA (04/12/24)

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
*     text       = text-b01
*     info       = text-x01
      name       = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result     = button
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             icon_not_found = 1
             outputfield_too_short = 2
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
*EOC:HBHALLA (04/12/24)

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
    WHEN 'ANB_BUT'.
      PERFORM toggle USING anb_but 'ANB_BUT'.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but 'BGD_BUT'.
    WHEN 'ANAT_BUT'.
      PERFORM toggle USING anat_but 'ANAT_BUT'.
    WHEN 'SYSB_BUT'.
      PERFORM toggle USING sysb_but 'SYSB_BUT'.
*BOC:AKUMAR (PN-13164) (10/05/25)
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
*EOC:AKUMAR (PN-13164) (10/05/25)
    WHEN 'RESB_BUT'.
      PERFORM toggle USING resb_but 'RESB_BUT'.
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
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  anb_but  'ANB'.
  PERFORM handle_section USING  resb_but 'RES'.
  PERFORM handle_section USING  anat_but 'ANA'.
  PERFORM handle_section USING  sysb_but 'SYS'.
  PERFORM handle_section USING  exe_but 'EXE'.
  PERFORM handle_section USING  bgd_but  'BGD'.

ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  create_variant_from_sel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_variant_from_sel.
  DATA: curr_report LIKE rsvar-report.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = g_curr_variant
      vari_desc     = g_vari_desc
    TABLES
      vari_contents = g_vari_contents
      vari_text     = g_vari_text
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          illegal_report_or_variant = 1
          illegal_variantname = 2
          not_authorized = 3
          not_executed = 4
          report_not_existent = 5
          report_not_supplied = 6
          variant_exists = 7
          variant_locked = 8
          OTHERS = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " create_variant_from_sel
*&---------------------------------------------------------------------*
*&      Form  get_default_version_set
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_default_version_set.
  IF p_dflt = 'X'.
    se_config_param 'DFLT_GLOBAL_VERSION' p_vrsio.

    IF gf_cfg_set_enabled = 'X'. "AKUMAR PN13164
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio      = 'X'
          i_cfgvrsio   = p_vrsio
        IMPORTING
          e_config_set = p_cfgset.

      GET PARAMETER ID 'pid'
        FIELD g_rpt_succ.                        "#EC SAST_CI_GEN_CHECK
      IF g_rpt_succ <> 'X'.
        MESSAGE s002(/psyng/sw) WITH
        'Using default SOD Matrix version and config set'(t02)
        p_vrsio p_cfgset.
      ENDIF.
    ENDIF.

  ENDIF.
ENDFORM.                    " get_default_version_set
*&---------------------------------------------------------------------*
*&      Form  GET_ROLES_COUNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count .
  DATA :  l_num TYPE i.

  IF NOT p_system IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
  CHECK gf_invalid_rfc  IS INITIAL.
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
  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION p_system
    EXPORTING
      i_composite_roles = p_comp
      i_single_roles    = p_sing
      i_assigned_roles  = p_assr
    IMPORTING
      e_count           = l_num
    TABLES
      it_ba             = rba
      it_roles          = s_role                 "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA PN:11269 (21/01/25)
EXCEPTIONS
    communication_failure = 1
    system_failure = 2
    OTHERS = 3 .
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e002(/psyng/sw) WITH 'Communication failure'(t04).
      WHEN 2.
        MESSAGE e002(/psyng/sw) WITH 'System failure'(t05).
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(t06).
    ENDCASE.
  ENDIF.
*EOC:HBHALLA PN:11269 (21/01/25)
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  MESSAGE i002 WITH 'Number of roles(s) will be analyzed : '(004)
  l_num.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  UPDATE_SAST_MAPPING_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_sast_mapping_table .
  DATA: l_tabname TYPE tabname.
  CONSTANTS: lc_map_table TYPE dd02l-tabname VALUE '/SAST/SOD_SE_AUD',
             lc_finish  TYPE flag VALUE 'F',
             lc_check_type TYPE c LENGTH 1 VALUE '4'.
  SELECT tabname FROM dd02l UP TO 1 ROWS
    INTO (l_tabname)
    WHERE tabname = lc_map_table.                "#EC SAST_CI_GEN_CHECK
  ENDSELECT.

  IF NOT l_tabname IS INITIAL.
    UPDATE (lc_map_table) SET                    "#EC SAST_CI_GEN_CHECK
                    aid       = g_analysis_id
                   job_status = lc_finish
        WHERE auditplan_id    =  p_audpl
               AND run_id     = p_runid
               AND sysid      = sy-sysid
             AND check_type   = lc_check_type.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_ORGLVL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1007   text
*      <--P_ORGLVL_LOW  text
*----------------------------------------------------------------------*
FORM f4_orglvl USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
  CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
    EXPORTING
      i_cfg_set       = p_cfgset
   IMPORTING
     e_orglvl        = e_orglvl.
ENDFORM.
