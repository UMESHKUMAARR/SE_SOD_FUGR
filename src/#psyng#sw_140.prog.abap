REPORT /psyng/sw_140 MESSAGE-ID /psyng/sw.
TABLES : /psyng/conflict, /psyng/swresusr,/psyng/sw_rfcdes,usr02,usr21,
         /psyng/swsodorgm. "HBHALLA
INCLUDE  /psyng/sw_config.
INCLUDE  /psyng/sw_140_macros.
INCLUDE  /psyng/sw_140_global.
INCLUDE : /psyng/basis_exelog.

RANGES :
  gr_users          FOR sy-uname.
DATA:
yulock                   TYPE x VALUE '80',
"Locked by incorrect login
yusloc                   TYPE x VALUE '40',
"Locked by Administrator
yugloc                   TYPE x VALUE '20',
"Locked by global Administrator
l_uflag                  TYPE x,
dsp_mng_lock             VALUE 'N',
dsp_slf_lock             VALUE 'Y',
gf_cfg_set_enabled       TYPE flag,
gf_mit_by_org            TYPE flag,
g_exit_proc,
curr_variant             LIKE  rsvar-variant,
g_curr_variant           LIKE  rsvar-variant,
g_ucomm                  LIKE sy-ucomm,
g_button_set             TYPE flag,
g_variant                LIKE vari-variant,
g_vari_desc              TYPE varid OCCURS 0 WITH HEADER LINE,
g_vari_contents          LIKE  rsparams OCCURS 0 WITH HEADER LINE,
g_vari_text              LIKE varit OCCURS 0 WITH HEADER LINE,
gt_irsparams             TYPE rsparams OCCURS 0 WITH HEADER LINE,
g_program                LIKE sy-repid,
gt_rfcdest               TYPE TABLE OF rfcdes WITH HEADER LINE,
gt_users                 TYPE SORTED TABLE OF usr02
WITH HEADER LINE WITH UNIQUE KEY bname ,
gt_usr06                 TYPE SORTED TABLE OF usr06
WITH HEADER LINE WITH UNIQUE KEY bname,
gt_sum_results           TYPE TABLE OF /psyng/sw_sod_output_org
WITH HEADER LINE,

g_tasknumber             TYPE i,
g_tasksrunning           TYPE i,
g_failedtasks            TYPE i,
g_totalresults           TYPE i,
g_count_summary          TYPE sy-tabix, "Conflicts with abbr.
g_count_summary_mit      TYPE sy-tabix,
gt_faobj_system          TYPE /psyng/sw_tab_sys_faobj,
gt_ao_sys                TYPE /psyng/sw_tab_sys_ao,
gt_conflict_local        TYPE TABLE OF /psyng/conflict,
gt_confdet_local         TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
gt_functtran_local       TYPE TABLE OF /psyng/functtran,
gt_faobj_local           TYPE TABLE OF /psyng/faobj2,
gt_faobj_only_org        TYPE TABLE OF /psyng/faobj2,
gt_swsodorgm_local       TYPE TABLE OF /psyng/swsodorgm,
gt_functran_no_enh_local
TYPE TABLE OF /psyng/functtran,
gt_tcodes_local          TYPE TABLE OF /psyng/sw_par_tcode_output,
g_nr_authdetails         TYPE sy-tabix,
g_warning_msg(1)         TYPE c,
g_preconfig              TYPE /psyng/swcfgset-setid,
lf_set_invalid           TYPE flag,
lf_set_nocover           TYPE flag,
lf_set_mismatch          TYPE flag,
lf_include_local         TYPE flag,
l_vrsio                  TYPE /psyng/sodvrsio,
g_current_user           TYPE sy-uname, "RGUPTA for C0700
g_rpt_succ               TYPE flag, "AKUMAR for PN4445

BEGIN OF gs_fun_user ,
funid TYPE /psyng/function_id,
users TYPE SORTED TABLE OF xubname WITH UNIQUE KEY table_line,
END OF gs_fun_user,
gt_fun_user LIKE SORTED TABLE OF gs_fun_user WITH HEADER LINE
WITH UNIQUE KEY  funid,
BEGIN OF gs_con_user ,
conid TYPE /psyng/conflict_id,
users TYPE SORTED TABLE OF xubname WITH UNIQUE KEY table_line,
END OF gs_con_user,
gt_con_user LIKE SORTED TABLE OF gs_con_user WITH HEADER LINE
WITH UNIQUE KEY  conid,
BEGIN OF gt_conflicted_users OCCURS 0,
bname TYPE xubname,
count TYPE i,
END OF gt_conflicted_users,
BEGIN OF gt_mitigated_users OCCURS 0,
bname TYPE xubname,
count TYPE i,
END OF gt_mitigated_users,
BEGIN OF gt_det_results OCCURS 0,
sys       TYPE /psyng/sysid,
results   TYPE STANDARD TABLE OF /psyng/sw_func_scan_det,
user_prof TYPE STANDARD TABLE OF /psyng/se_user_prof_role,
END OF gt_det_results.

*--> BOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
CONSTANTS : lc_scjb(4)  TYPE c VALUE 'SCJB',
            lc_onli(4)  TYPE c VALUE 'ONLI',
            lc_remon(5) TYPE c VALUE 'REMON',
            lc_nc(2)    TYPE c VALUE 'NC',
            lc_sm37(4)  TYPE c VALUE 'SM37',
            lc_dflt(4)  TYPE c VALUE 'DFLT'.
*--> EOC PN-15294 - SE ATC fixes - UMITTAL - 09/09/25 D67K940733
DATA : g_org_field TYPE flag.

*BOC:HBHALLA (PN-11746) (08/05/25)
DATA: swconfig TYPE /psyng/swconfig,
      gf_hide_org         TYPE /psyng/bapiflagx.
*EOC:HBHALLA (PN-11746) (08/05/25)


*BOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
  DATA : lv_er TYPE flag.
SELECTION-SCREEN: BEGIN OF BLOCK anb WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) anb_but USER-COMMAND anb_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .


PARAMETERS :
  p_desc   TYPE /psyng/longtextfield      MODIF ID anb,
  p_retdet TYPE /psyng/se_retention_days  MODIF ID anb.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-c01 FOR FIELD p_deldet
           MODIF ID anb."HBHALLA(13/02/26)
PARAMETERS
  p_deldet TYPE sy-datum                  MODIF ID anb.
SELECTION-SCREEN END OF LINE.
PARAMETERS:
  p_retsum TYPE /psyng/se_retention_days  MODIF ID anb.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(31) text-c02 FOR FIELD p_delsum
           MODIF ID anb."HBHALLA(13/02/26)
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
  p_dflt   TYPE flag USER-COMMAND dflt MODIF ID res,"HBHALLA(13/02/26)
  p_vrsio  TYPE /psyng/sodvrsio        MODIF ID res,
  p_cfgset TYPE /psyng/seconfid        MODIF ID res.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                             MODIF ID res."HBHALLA(13/02/26)
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS :
      s_bname   FOR usr02-bname           MODIF ID res,
      s_class   FOR usr02-class           MODIF ID res,
      s_ustyp   FOR usr02-ustyp           MODIF ID res,
      s_kostl   FOR /psyng/swresusr-kostl MODIF ID res
                                          MATCHCODE OBJECT /psyng/kostl.
PARAMETERS :
      p_val     TYPE flag MODIF ID res.
SELECT-OPTIONS :
      s_conid   FOR /psyng/conflict-conid MODIF ID res.

SELECTION-SCREEN: END OF BLOCK resb.

SELECTION-SCREEN: BEGIN OF BLOCK sysb WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) sysb_but USER-COMMAND sysb_but.
SELECTION-SCREEN COMMENT 16(50) text-b04 .


*BOC AKUMAR PN-13175
*  --Conflict origin
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-001    MODIF ID sys.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X' MODIF ID sys.
SELECTION-SCREEN COMMENT 24(10) text-002 FOR FIELD p_local
                                           MODIF ID sys.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag DEFAULT ' '
                                          MODIF ID sys.
SELECTION-SCREEN COMMENT 37(10) text-003 FOR FIELD p_remote
                                           MODIF ID sys.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag DEFAULT ' ' MODIF ID sys.
SELECTION-SCREEN COMMENT 51(20) text-004 FOR FIELD p_cross
                                           MODIF ID sys.
SELECTION-SCREEN: END OF LINE.


* C1339
*SELECTION-SCREEN BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 1.
*PARAMETERS     : p_locusr type flag MODIF ID sys.
*SELECTION-SCREEN COMMENT 4(45) text-162 FOR FIELD p_locusr
*                                           MODIF ID sys.
*SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN : POSITION 04.
PARAMETERS : p_remon AS CHECKBOX MODIF ID sys USER-COMMAND remon.
SELECTION-SCREEN COMMENT 8(45) text-163 FOR FIELD p_remon
                                           MODIF ID sys.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS :
      s_system  FOR /psyng/sw_rfcdes-rfcdest
                MATCHCODE OBJECT /psyng/sw_rfcsh_coll
                MODIF ID sys.

PARAMETERS p_nocro TYPE flag MODIF ID sys USER-COMMAND nc.
"HBHALLA(13/02/26)

SELECTION-SCREEN: END OF BLOCK sysb.
*EOC AKUMAR PN-13175

*BOC:HBHALLA (PN-11746) (10/05/25)
*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 16(50) text-b06.

PARAMETERS: orgchk  AS CHECKBOX DEFAULT ' ' USER-COMMAND org
                                   MODIF ID exe.
SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb
                                   MODIF ID exe.
*BOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
PARAMETERS : excl_er AS CHECKBOX DEFAULT ' ' MODIF ID exe.
*EOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
SELECTION-SCREEN: END OF BLOCK exe_o.
*EOC:HBHALLA (PN-11746) (10/05/25)

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
* BOC by RGUPTA on 28.03.22
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 28.03.22
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SW_140'.
*
  g_program = sy-repid.
  PERFORM set_button_icons.

*--Get default retention period & desription
*-- if someone entered nonnumeric value then default
  IF p_retday IS INITIAL.
    DATA: ls_config TYPE /psyng/se_config_param.
*    se_config_param 'DFLT_STORE_RET_DAYS' l_retday.
    CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
      EXPORTING
        i_parameter = 'DFLT_STORE_RET_DAYS'
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
        i_parameter = 'DFLT_STORE_R_DAYS_D'
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
        i_parameter = 'DFLT_STORE_R_DAYS_S'
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
    se_config_param 'DFLT_STORE_SOD_DESC' p_desc.
  ENDIF.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.

  se_config_param 'DFLT_STOR_DET_BTCH' p_dtbtch.
  se_config_param 'DFLT_STOR_SUM_BTCH' p_subtch.
  se_config_param 'DFLT_STOR_SUM_PAR'  p_maxtsk.

  se_config_param 'DFLT_STORE_NOCON_USR' ls_config-value.
  IF ls_config-value = 'Y' OR ls_config-value = 'X'.
    p_storno = 'X'.
  ELSE.
    CLEAR p_storno.
  ENDIF.

*--Check if conflicts should be reported by Org Area
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.
  IF gf_mit_by_org = 'X' OR gf_mit_by_org = 'Y'.
    gf_mit_by_org = 'X'.
  ELSE.
    CLEAR gf_mit_by_org.
  ENDIF.
*  GG opl 645
  se_config_param 'CONSIDER_ORG_FIELD' g_org_field.
  IF g_org_field EQ 'Y' OR g_org_field EQ 'X'.
    g_org_field = 'X'.
  ELSE.
    CLEAR g_org_field.
  ENDIF.
*  GG opl 645
*  C1339
**Only analyze local users in cross system analysis
*  CLEAR ls_config.
*  se_config_param 'DFLT_LOCAL_USR' ls_config-value.
*  IF ls_config-value = 'Y'.
*    p_locusr = 'X'.
*  ELSE.
*    p_locusr = ' '.
*  ENDIF.
*  End
*  IF p_dflt = 'X'.
**--Get global default version and latest published set
*    PERFORM get_default_version_set.
*  ELSE.
**  *-- Get user's default version
*    IF p_vrsio = space.
*      CALL FUNCTION '/PSYNG/SW_034'
*        IMPORTING
*          e_vrsio = p_vrsio.
*
*    ENDIF.
**  --Check if Configuration Set functionality is enabled.
*    se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
*    IF gf_cfg_set_enabled = 'Y' OR gf_cfg_set_enabled = 'X'.
*      gf_cfg_set_enabled = 'X'.
*    ELSE.
*      CLEAR gf_cfg_set_enabled.
*    ENDIF.
***  --default to the latest published configuration set (highest nr)
**    IF p_cfgset IS INITIAL.
**      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
**        EXPORTING
**          i_vrsio      = 'X'
**          i_cfgvrsio   = p_vrsio
**        IMPORTING
**          e_config_set = p_cfgset.
**    ENDIF.
**  ENDIF.

*BOC:HBHALLA (PN-11746) (08/05/25)
**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    orgchk = ' '.
  ENDIF.
  CLEAR swconfig.

*--Hide Org Level Check option
  se_config_param 'HIDE_ORG_ANALYSIS' swconfig-value.
  IF swconfig-value = 'Y'.
    gf_hide_org = 'X'.
  ELSEIF swconfig-value = 'N'.
    gf_hide_org = ' '.
  ENDIF.
  CLEAR swconfig.
*EOC:HBHALLA (PN-11746) (08/05/25)

*BOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
"Check if ER module exists or not.
  CLEAR : lv_er.
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'ER'
    IMPORTING
      e_installed       = lv_er.
*EOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026

*BOC:HBHALLA (PN-11746) (12/05/25)
AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high .
*EOC:HBHALLA (PN-11746) (12/05/25)

AT SELECTION-SCREEN  OUTPUT.
  PERFORM handle_button.
  PERFORM handle_sections.
  IF p_dflt = 'X'.
*--Get global default version and latest published set
    PERFORM get_default_version_set.

  ELSE.
*  *-- Get user's default version
*    IF p_vrsio = space.
*      CALL FUNCTION '/PSYNG/SW_034'
*        IMPORTING
*          e_vrsio = p_vrsio.
*
*    ENDIF.
*  --Check if Configuration Set functionality is enabled.
    se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
    IF gf_cfg_set_enabled = 'Y' OR gf_cfg_set_enabled = 'X'.
      gf_cfg_set_enabled = 'X'.
    ELSE.
      CLEAR gf_cfg_set_enabled.
    ENDIF.
*  --default to the latest published configuration set (highest nr)
*    IF p_cfgset IS INITIAL. "AKUMAR++ PN15915
    IF gf_cfg_set_enabled = 'X'. "AKUMAR++ PN15915
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio      = 'X'
          i_cfgvrsio   = p_vrsio
        IMPORTING
          e_config_set = p_cfgset.
    ENDIF.
  ENDIF.
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

*BOC:HBHALLA (PN-11746) (08/05/25)
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
*EOC:HBHALLA (PN-11746) (08/05/25)

      WHEN 'P_LOCAL' OR 'P_CROSS'.
        IF p_remon = 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
*BOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
"If ER Module exists , Enable Checkbox else disable it.
     WHEN 'EXCL_ER'.
        IF lv_er = 'X'.
          screen-input = 1.
        ELSE.
          screen-input = 0.
        ENDIF.
        MODIFY SCREEN.
*EOC UMITTAL PN-17376 : Enable 'Exclude ER Assgnd Role btn' 02/02/2026
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
*--Hide no cross analysis if MIT_BY_ORG is disabled
    IF screen-name CS 'P_NOCRO'.
      IF gf_mit_by_org IS INITIAL.
        screen-invisible = 1.
        screen-active    = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

    IF screen-name CS 'P_CROSS'.
      IF p_nocro = 'X'.
        screen-input = 0.
      ELSE.
        screen-input = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.

AT SELECTION-SCREEN.

  IF sy-ucomm IS INITIAL.
*--Check Config Set
    IF gf_cfg_set_enabled = 'X'.
      lf_include_local = 'X'.
      IF p_remon = 'X'.
        CLEAR lf_include_local.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid         = p_cfgset
          i_vrsio         = p_vrsio
          if_show_warning = 'X'
          if_local_system = lf_include_local
       TABLES
         it_rfcdest       = s_system.
    ENDIF.
  ENDIF.

  CASE sy-ucomm.
*    WHEN 'SCJB'.
    WHEN lc_scjb.
      g_exit_proc = 'Y'.
      PERFORM schedule_back_job.
*    WHEN 'SM37'.
    WHEN lc_sm37.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
*    WHEN 'DFLT'.
    WHEN lc_dflt.
      PERFORM get_default_version_set.
      g_rpt_succ = ' '.                        "HBHALLA
      SET PARAMETER ID 'pid' FIELD g_rpt_succ.     "HBHALLA
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
*    WHEN 'ONLI'.
    WHEN lc_onli.
      IF p_remote EQ 'X' OR p_remon EQ 'X'.
        IF s_system[] IS INITIAL.
          MESSAGE w140 WITH
        'Please enter RFC destinations for remote analysis'(180).
        ENDIF.
      ENDIF.
*    WHEN 'REMON'.
    WHEN lc_remon.
      IF p_remon = 'X'.
        p_remote = 'X'.
        CLEAR: p_local, p_cross.
      ENDIF.

*    WHEN 'NC'.
    WHEN lc_nc.
      IF p_nocro = 'X'.
        CLEAR p_cross.
      ENDIF.

  ENDCASE.
  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.
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
    lf_include_local = 'X'.
    IF p_remon = 'X'.
      CLEAR lf_include_local.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
          i_setid            = p_cfgset
          i_vrsio            = p_vrsio
          if_show_warning    = 'X'
          if_local_system    = lf_include_local
      IMPORTING
          ef_wrong_version   = lf_set_invalid
          ef_missing_system  = lf_set_nocover
          ef_system_mismatch = lf_set_mismatch
     TABLES
       it_rfcdest            = s_system.
    IF lf_set_invalid  = 'X' OR
       lf_set_nocover  = 'X' .
      LEAVE LIST-PROCESSING.
    ENDIF.
*  ELSE.
*    CLEAR p_cfgset.
  ENDIF.

*BOC:HBHALLA (PN-11746) (08/05/25)
  IF orgchk = 'X'.
    exelog sy-repid 'ORGCHECK'.
  ELSE.
    exelog sy-repid 'NO_ORGCHECK'.
  ENDIF.
*EOC:HBHALLA (PN-11746) (08/05/25)

  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program)                       "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_140
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.
*-- Check RFC destinations
  IF NOT s_system[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
  PERFORM validate_job.
  PERFORM 01_prepare_analysis.
  PERFORM 02_load_users.
  PERFORM 03_analyze.
  WAIT UNTIL g_tasksrunning = 0.
  PERFORM 05_store_results.
  msg '# Detailed Scans executed '  g_tasknumber    '' ''.
  msg '# Detailed Scans FAILED '    g_failedtasks   '' ''.
  msg '# Detailed results '         g_totalresults  '' ''.
  msg '# Summary Results  '         g_count_summary '' ''.
  PERFORM 06_summarize_results USING 'X'.
  IF g_failedtasks = 0.
    msg 'SOD Analysis Complete '      gs_db_header-aid '' ''.
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
*    SUBMIT /PSYNG/SW_140
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
    IF p_dflt = 'X'.
*--Get global default version and latest published set
      PERFORM get_default_version_set.
      exelog sy-repid 'DEFAULT'.
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
      lf_include_local = 'X'.
      IF p_remon = 'X'.
        CLEAR lf_include_local.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
            i_setid            = p_cfgset
            i_vrsio            = p_vrsio
            if_show_warning    = 'X'
            if_local_system    = lf_include_local
        IMPORTING
            ef_wrong_version   = lf_set_invalid
            ef_missing_system  = lf_set_nocover
            ef_system_mismatch = lf_set_mismatch
       TABLES
         it_rfcdest            = s_system.
      IF lf_set_invalid  = 'X' OR
         lf_set_nocover  = 'X' .
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
  ENDIF.
ENDFORM.                    " schedule_back_job
*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
*  DATA: oldnumber(7)   TYPE n, oldnumber_c(7).

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

* --- C017 Odubey 29/11/2021
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
          lt_sys          TYPE TABLE OF /psyng/swresisys
                          WITH HEADER LINE.
*--Get a new analysis id
  CALL FUNCTION '/PSYNG/SW_SESTORE_NEW_STOREID'
    IMPORTING
      resid = g_analysis_id.
*--Initialize the analysis ID in all storage tables
  gt_db_users-aid             = g_analysis_id.
  gt_db_usercon-aid           = g_analysis_id.
  gt_db_concont-aid           = g_analysis_id.
  gt_db_confun-aid            = g_analysis_id.
  gt_db_funprofile-aid        = g_analysis_id.
  gt_db_profilerole-aid       = g_analysis_id.
  gt_db_userprofile-aid       = g_analysis_id.
  gt_db_usercomposite-aid     = g_analysis_id.
  gt_db_ufunabb-aid           = g_analysis_id.
  gt_db_authdetails-aid       = g_analysis_id.
*--Analysis header
  gs_db_header-aid            = g_analysis_id.
  gs_db_header-bname          = g_current_user. "sy-uname. C0700
  gs_db_header-start_date     = sy-datum.
  gs_db_header-start_time     = sy-uzeit.
  gs_db_header-description    = p_desc.
  gs_db_header-sodvrsio       = p_vrsio.
  gs_db_header-setid          = p_cfgset.
  gs_db_header-retention_days = p_retday.
  gs_db_header-retention_days_det = p_retdet.
  gs_db_header-retention_days_sum = p_retsum.
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
  SELECT DISTINCT * FROM /psyng/swresvba
    INTO TABLE lt_db_vonbisabb                          "#EC CI_NOWHERE
  ORDER BY von bis abb.
  DELETE ADJACENT DUPLICATES FROM lt_db_vonbisabb COMPARING
  von bis abb.
  INSERT LINES OF lt_db_vonbisabb INTO TABLE gt_db_vonbisabb.
  FREE lt_db_vonbisabb.
*--Check if this is an unrestricted analysis
  gs_db_header-no_restrictions = 'X'.
  IF p_val =  'X'.
    CLEAR gs_db_header-no_restrictions.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_bname[] IS INITIAL.
      LOOP AT s_bname.
        IF NOT ( s_bname-sign   = 'I'  AND
                 s_bname-option = 'CP' AND
                 s_bname-low    = '*'  AND
                 s_bname-high   = ''
               ).
          CLEAR gs_db_header-no_restrictions.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_kostl[] IS INITIAL.
      LOOP AT s_kostl.
        IF NOT ( s_kostl-sign   = 'I'  AND
                 s_kostl-option = 'CP' AND
                 s_kostl-low    = '*'  AND
                 s_kostl-high   = ''
               ).
          CLEAR gs_db_header-no_restrictions.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_class[] IS INITIAL.
      LOOP AT s_class.
        IF NOT ( s_class-sign   = 'I'  AND
                 s_class-option = 'CP' AND
                 s_class-low    = '*'  AND
                 s_class-high   = ''
               ).
          CLEAR gs_db_header-no_restrictions.
          EXIT.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
  IF gs_db_header-no_restrictions = 'X'.
    IF NOT s_ustyp[] IS INITIAL.
      LOOP AT s_ustyp.
        IF NOT ( s_ustyp-sign   = 'I'  AND
                 s_ustyp-option = 'CP' AND
                 s_ustyp-low    = '*'  AND
                 s_ustyp-high   = ''
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
  DATA l_size TYPE c LENGTH 10.
  IF p_dtbtch < 1.
*---Instead of hardcoded take the values from config.
** Opl 547
*    p_dtbtch = 50.
    se_config_param 'DFLT_STOR_DET_BTCH' p_dtbtch.
    l_size = p_dtbtch.
    msg 'Detailed batch size was 0.' 'Defaulted to ' l_size '' .
  ENDIF.
  IF p_subtch < 1.
*    p_subtch = 1000.
    se_config_param 'DFLT_STOR_SUM_BTCH' p_subtch.
    l_size = p_subtch.
    msg 'Summary batch size was 0.' 'Defaulted to ' l_size '' .
  ENDIF.
  IF p_maxtsk < 1.
*    p_maxtsk = 2.
    se_config_param 'DFLT_STOR_SUM_PAR'  p_maxtsk.
*    p_maxtsk = 2.
    l_size = p_maxtsk.

    msg 'Parallel Tasks was 0.' 'Defaulted to 2' '' '' .
    CLEAR l_size.
  ENDIF.


  msg 'Starting Analysis ' gs_db_header-aid '' '' .

*--Register analysis in DB
  MODIFY /psyng/swreshdr FROM gs_db_header.
  COMMIT WORK.

*--Print parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid = g_program.
  PERFORM load_rfc
              TABLES
                s_system
                gt_rfcdest.
*--Add local system to gt_rfcdest.
  IF NOT p_remon = 'X'.
    CLEAR gt_rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest-rfcoptions.
    APPEND gt_rfcdest.
  ENDIF.
*--Store the Systems
* Convert and store them
  invert_index :      gt_idx_sys gt_val_sys.
  convert_val_table : gt_val_sys lt_sys              sysid
                      sysindex   '/PSYNG/SWRESISYS'.

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
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest,
        lt_rfc_log       TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test       TYPE rfctest,
        l_system_msg(80) TYPE c,
        l_sys_idx        TYPE i.

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
*--Add the remote system
      get_index gt_idx_sys <rfcdes>-rfcoptions
                l_sys_idx g_idx_sys.


    ENDIF.
  ENDLOOP.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  IF NOT p_remon = 'X'.
*  --Add the local system
    get_index gt_idx_sys l_local_sys
              l_sys_idx g_idx_sys.
  ENDIF.

  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.
ENDFORM.                    " load_role_rfc

*---------------------------------------------------------------------*
*       FORM 02_load_users                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 02_load_users.
  DATA : lt_users   TYPE TABLE OF usr02,
         lt_uinfo   TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         l_exclude_locked TYPE flag VALUE 'X',
         l_exclude_expired TYPE flag VALUE 'X',
         l_user_idx TYPE sy-tabix,
         l_system   TYPE rfcdest.                 "HBHALLA
  RANGES : lr_users      FOR sy-uname,
           lr_users_part FOR sy-uname.
  IF p_val = 'X'.
    CLEAR : l_exclude_locked, l_exclude_expired.
  ENDIF.
  LOOP AT gt_rfcdest.
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
    CALL FUNCTION '/PSYNG/SW_041'
      DESTINATION gt_rfcdest-rfcdest
      EXPORTING
        i_validuser       = p_val
        i_include_locked  = l_exclude_locked
        i_include_expired = l_exclude_expired
      TABLES
        et_users          = lt_users
        it_grouplist      = s_class
        it_usertype       = s_ustyp
        it_userlist       = s_bname
        it_costcenter     = s_kostl
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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


    SORT lt_users BY bname.
    DELETE ADJACENT DUPLICATES FROM lt_users.
    gt_users[] = lt_users[].
    FREE : lt_users, lt_uinfo[].
    gr_users-sign   = 'I'.
    gr_users-option = 'EQ'.
    LOOP AT gt_users.
      gr_users-low = gt_users-bname.
      COLLECT gr_users.
      MOVE-CORRESPONDING gt_users TO lt_uinfo.
      APPEND lt_uinfo.
    ENDLOOP.
*--Load information about users
*  if storing users w/o conflicts is selected
*PN-13314:Issue3: Multiple users with no conflicts stored even when
*User scope is restricted (02/06/25)
    IF p_storno = 'X' AND NOT gt_users[] IS INITIAL."HBHALLA(02/06/25)
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
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        DESTINATION gt_rfcdest-rfcdest
        EXPORTING
          i_name_only     = 'X'
          i_mr_company    = 'X'
          i_mr_department = 'X'
          i_central_uid   = 'X'
        TABLES
          sw_uinfo        = lt_uinfo
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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

    ENDIF.
*--Get cost center info
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
    CALL FUNCTION '/PSYNG/BASIS_USER_COSTCENTER'
      DESTINATION gt_rfcdest-rfcdest
      TABLES
        it_sw_uinfo = lt_uinfo.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*BOC: HBHALLA
    CONCATENATE sy-sysid sy-mandt INTO l_system.
    IF gt_rfcdest-rfcoptions = l_system.
      LOOP AT lt_uinfo.
        READ TABLE gt_uinfo WITH KEY bname = lt_uinfo-bname.
        IF sy-subrc = 0.
          DELETE gt_uinfo WHERE bname = lt_uinfo-bname.
        ENDIF.
      ENDLOOP.
    ENDIF.
*EOC:HBHALLA
    APPEND LINES OF lt_uinfo TO gt_uinfo.
    SORT gt_uinfo BY bname.
    DELETE ADJACENT DUPLICATES FROM gt_uinfo COMPARING bname.
  ENDLOOP.
  DESCRIBE TABLE gr_users LINES gs_db_header-users_analyzed.
  msg '# Users that will be analyzed' gs_db_header-users_analyzed '' ''.
*--Get Additional Info -
  CHECK NOT gr_users[] IS INITIAL.
  lr_users[] = gr_users[].
  REFRESH :  gt_usr06.
  WHILE NOT lr_users[] IS INITIAL.
    REFRESH : lr_users_part.
    APPEND LINES OF lr_users FROM 1 TO 5000 TO lr_users_part.
    DELETE lr_users FROM 1 TO 5000.
    SELECT bname lic_type FROM usr06 APPENDING CORRESPONDING FIELDS OF
     TABLE gt_usr06
    WHERE bname IN lr_users_part.
  ENDWHILE.
*LOCKED (determine from usr02 flag)


*--Store all users, also the ones that have no conflicts
*  if storing users w/o conflicts is selected
  IF p_storno = 'X'.
    LOOP AT gt_uinfo.
*  -- get user id details
      get_index gt_idx_user gt_uinfo-bname
                l_user_idx g_idx_user.
*  --Store user details
      store_user  l_user_idx  gt_uinfo.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " load_users
*---------------------------------------------------------------------*
*       FORM 03_analyze                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 03_analyze.
*  PERFORM collect_users_per_conflict.

  RANGES : lr_users FOR sy-uname.
  DATA : l_nrusr TYPE i.
  WHILE NOT gr_users[] IS INITIAL.
    REFRESH :lr_users,  gt_sum_results.
    APPEND LINES OF gr_users FROM 1 TO p_subtch TO lr_users.
    DELETE gr_users FROM 1 TO p_subtch.
    DESCRIBE TABLE lr_users LINES l_nrusr.
    msg '--ANALYSIS STARTING--' l_nrusr ' USERS' ''.

    PERFORM summary_analysis
      TABLES gt_sum_results
             lr_users.

    PERFORM collect_users_per_conflict.
*--   User detailed Function Analysis
    PERFORM function_anal_load_matrix.
    PERFORM collect_users_per_function.
    LOOP AT gt_fun_user.
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
  et_sum_results STRUCTURE /psyng/sw_sod_output_org
  it_users       STRUCTURE /psyng/range_bname.
  DATA : l_cnt TYPE i,
         lt_results_cnt TYPE TABLE OF /psyng/sw_sod_output_org."HBHALLA
  DATA: lt_sum_results TYPE TABLE OF /psyng/sw_sod_output_org
        WITH HEADER LINE,
        lt_rfc TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
        WITH HEADER LINE,
        l_remon TYPE flag.
  msg 'Starting Summary Analysis' '' '' ''.
*--Free user buffer memory
  CALL FUNCTION '/PSYNG/SW_057'.
  IF p_nocro IS NOT INITIAL.
    LOOP AT gt_rfcdest.
      REFRESH lt_rfc.
      CLEAR: lt_rfc,l_remon.
      IF gt_rfcdest-rfcdest IS NOT INITIAL.
        l_remon = 'X'.
        lt_rfc-sign   = 'I'.
        lt_rfc-option = 'EQ'.
        lt_rfc-low = gt_rfcdest-rfcdest.
        APPEND lt_rfc.
      ENDIF.
*--Summary Analysis
      CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
        EXPORTING
*          i_org_check       = 'X'   "HBHALLA (PN-11746) (08/05/25)
          i_org_check       = orgchk "HBHALLA (PN-11746) (08/05/25)
          i_validuser       = p_val
          i_vrsio           = p_vrsio
          i_config_set      = p_cfgset
          i_shomit          = 'X'
          i_outvdate        = ' '
*BOC UMITTAL : PN17376:Exculde ER assigned Roles 13/02/2026
          i_exclude_er_roles  =  excl_er
*EOC UMITTAL : PN17376:Exculde ER assigned Roles 13/02/2026
          i_exlckusr        = ' '
          i_shonosod        = ' '
*      i_locusr          = p_locusr
          i_analyze_sap_all = 'X'
          i_remote_only     = l_remon
          if_mit_by_org     = gf_mit_by_org
            i_org_field     = g_org_field                   "opl645 gg

        TABLES
          it_users          = it_users
          it_confs          = s_conid
          it_user_rfc       = lt_rfc
          it_orglvl         = orglvl   "HBHALLA (PN-11746) (10/05/25)
          et_outputdet      = lt_sum_results.
      APPEND LINES OF lt_sum_results TO et_sum_results.
    ENDLOOP.
    SORT et_sum_results BY bname conid.
  ELSE.
*--Summary Analysis
    CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
      EXPORTING
*       i_org_check       = 'X'   "HBHALLA (PN-11746) (08/05/25)
        i_org_check       = orgchk "HBHALLA (PN-11746) (08/05/25)
        i_validuser       = p_val
        i_vrsio           = p_vrsio
        i_config_set      = p_cfgset
        i_shomit          = 'X'
        i_outvdate        = ' '
*BOC UMITTAL : PN17376:Exculde ER assigned Roles 13/02/2026
        i_exclude_er_roles  =  excl_er
*EOC UMITTAL : PN17376:Exculde ER assigned Roles 13/02/2026
        i_exlckusr        = ' '
        i_shonosod        = ' '
        i_analyze_sap_all = 'X'
        i_remote_only     = p_remon
        if_mit_by_org     = gf_mit_by_org
        i_org_field       = g_org_field                   "opl645 gg
      TABLES
        it_users          = it_users
        it_confs          = s_conid
        it_user_rfc       = s_system
        it_orglvl         = orglvl   "HBHALLA (PN-11746) (10/05/25)
        et_outputdet      = et_sum_results.
    SORT et_sum_results BY bname conid.
  ENDIF.

*BOC AKUMAR PN13175
  IF p_local = 'X' AND p_remote IS INITIAL
    AND p_cross IS INITIAL.
    DELETE et_sum_results WHERE origin = 2
                        OR origin = 3
                        OR origin = 5.
  ELSEIF p_local = 'X' AND p_remote = 'X'
    AND p_cross IS INITIAL.
    DELETE et_sum_results WHERE origin = 3.
  ELSEIF p_local = 'X' AND p_remote IS INITIAL
    AND p_cross = 'X'.
    DELETE et_sum_results WHERE origin = 2.
  ELSEIF p_local IS INITIAL AND p_remote = 'X'
    AND p_cross IS INITIAL.
    DELETE et_sum_results WHERE origin = 1
                        OR origin = 3
                        OR origin = 4.
  ELSEIF p_local IS INITIAL AND p_remote = 'X'
    AND p_cross = 'X'.
    DELETE et_sum_results WHERE origin = 1.
  ELSEIF p_local IS INITIAL AND p_remote IS INITIAL
    AND p_cross = 'X'.
    DELETE et_sum_results WHERE origin = 1
                        OR origin = 2.
  ENDIF.
*EOC AKUMAR PN13175

*--Calculating total number of conflicts with abbr.
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
    EXPORTING
*      i_orgcheck         = 'X'   "HBHALLA (PN-11746) (08/05/25)
      i_orgcheck         = orgchk "HBHALLA (PN-11746) (08/05/25)
      i_config_set       = p_cfgset
      i_vrsio            = p_vrsio
      i_orphan_functions = 'X'
      if_analysis        = 'X'
      i_org_field        = g_org_field                      "opl645 gg

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
      et_faobj_org       = gt_faobj_only_org.               "opl645 gg

ENDFORM.
*---------------------------------------------------------------------*
*       FORM collect_users_per_function                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM collect_users_per_function.
*--Get functions per conflict
  DATA : lt_confdet TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
         l_con_idx  TYPE i,
         l_fun_idx  TYPE i,
         l_bname    TYPE xubname.
  FIELD-SYMBOLS <funuser> LIKE LINE OF gt_fun_user.
  REFRESH : gt_fun_user.
  SELECT * FROM /psyng/confdet INTO TABLE lt_confdet
  WHERE vrsio = p_vrsio.
  LOOP AT lt_confdet.
*-- get conflict id details
    READ TABLE gt_con_user WITH TABLE KEY conid = lt_confdet-conid.
    IF sy-subrc = 0.
*  -- get function id details
      get_index gt_idx_function lt_confdet-functionid
                l_fun_idx g_idx_function.
      get_index gt_idx_conflict lt_confdet-conid
                l_con_idx g_idx_conflict.

*--Store conflict function link
      store_confun l_con_idx l_fun_idx.

      LOOP AT gt_con_user-users INTO l_bname.
        READ TABLE gt_fun_user
        WITH TABLE KEY funid = lt_confdet-functionid
        ASSIGNING <funuser>.
        IF sy-subrc <> 0.
          gs_fun_user-funid = lt_confdet-functionid.
          REFRESH gs_fun_user-users[].
          INSERT  gs_fun_user INTO TABLE gt_fun_user.
          READ TABLE gt_fun_user
          WITH TABLE KEY funid = lt_confdet-functionid
          ASSIGNING <funuser>.

        ENDIF.
        IF <funuser> IS ASSIGNED.
          INSERT l_bname INTO TABLE <funuser>-users   .
        ELSE.
         msg 'ERROR <funuser> not assigned' lt_confdet-functionid '' ''.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " collect_users_per_function
*---------------------------------------------------------------------*
*       FORM collect_users_per_conflict                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM collect_users_per_conflict.
  DATA : l_user_idx TYPE i,
         l_con_idx  TYPE i,
         l_sys_idx  TYPE i,
         l_abb_idx  TYPE i.
  FIELD-SYMBOLS <conuser> LIKE LINE OF gt_con_user.
  REFRESH : gt_con_user[].
  LOOP AT gt_sum_results.
*--collect users for determining fields in header table
*  CONFLICTED_USERS
*  MITIGATED_USERS
*  MITIGATED_CON
    IF NOT gt_sum_results-contid IS INITIAL.
      ADD 1 TO g_count_summary_mit.
      gt_mitigated_users-bname = gt_sum_results-bname.
      gt_mitigated_users-count = 1.
      COLLECT gt_mitigated_users.
    ENDIF.
    gt_conflicted_users-bname = gt_sum_results-bname.
    gt_conflicted_users-count = 1.
    COLLECT gt_conflicted_users.
*-- get user id details
    get_index gt_idx_user gt_sum_results-bname
              l_user_idx g_idx_user.
*--Store user details
    store_user  l_user_idx  gt_sum_results.
*-- get conflict id details
    get_index gt_idx_conflict gt_sum_results-conid
              l_con_idx g_idx_conflict.

*--Store user conflict info
    store_usercon l_user_idx l_con_idx gt_sum_results-contid
         gt_sum_results-origin. "Changes by RGUPTA on 16.03.22 for C0633
*--Get Sysid Details
    get_index gt_idx_sys gt_sum_results-rfcdest
              l_sys_idx g_idx_sys.
    CLEAR l_abb_idx.
    IF NOT gt_sum_results-org_abb IS INITIAL.
      get_index gt_idx_abb gt_sum_results-org_abb
                l_abb_idx g_idx_abb.
    ENDIF.
*--Store conflict Count info
    store_concont l_sys_idx l_con_idx l_abb_idx gt_sum_results-contid.
    READ TABLE gt_con_user
    WITH TABLE KEY conid = gt_sum_results-conid
    ASSIGNING <conuser>.
    IF sy-subrc <> 0.
      gs_con_user-conid = gt_sum_results-conid.
      REFRESH gs_con_user-users[].
      INSERT  gs_con_user INTO TABLE gt_con_user.
      READ TABLE gt_con_user
      WITH TABLE KEY conid = gt_sum_results-conid
      ASSIGNING <conuser>.
    ENDIF.
    IF <conuser> IS ASSIGNED.
      INSERT gt_sum_results-bname INTO TABLE <conuser>-users   .
    ELSE.
      msg 'ERROR <conuser> not assigned' gt_sum_results-conid '' ''.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " collect_users_per_conflict
*---------------------------------------------------------------------*
*       FORM 04_function_based_analysis                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM 04_function_based_analysis.
  RANGES : lr_users FOR sy-uname,
           lr_funid FOR gt_fun_user-funid.
  DATA   : l_numusers TYPE i.


*-Create range of users, in batches of 10?
*-Call detailed analysis on function and batch
*-do something with the results here
  lr_funid-sign   = 'I'.
  lr_funid-option = 'EQ'.
  lr_funid-low    = gt_fun_user-funid.
  APPEND lr_funid.
  DESCRIBE TABLE gt_fun_user-users LINES l_numusers.
  msg ' |_Detailed Analysis '  gt_fun_user-funid ' #users' l_numusers.
  CLEAR gt_runtime.
  gt_runtime-id    = gt_fun_user-funid.
  gt_runtime-users = l_numusers.
  gt_runtime-startd = sy-datum.
  gt_runtime-startt = sy-uzeit.
  CLEAR l_numusers.

  CLEAR l_numusers.
  LOOP AT gt_fun_user-users INTO lr_users-low.

    lr_users-sign   = 'I'.
    lr_users-option = 'EQ'.
    APPEND lr_users.
    ADD 1 TO l_numusers.
    IF l_numusers >= p_dtbtch.
*--Process batch of users
      PERFORM analyze_details_function
      TABLES
          lr_funid
          lr_users.
      REFRESH lr_users.
      CLEAR l_numusers.
    ENDIF.
  ENDLOOP.
*--Process remainder
  IF l_numusers > 0.
    PERFORM analyze_details_function
      TABLES
        lr_funid
        lr_users.
    REFRESH lr_users.

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
    ADD gt_runtime-users   TO <rt>-users.
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
        ir_users STRUCTURE /psyng/range_bname.
  DATA :
    lt_results         TYPE TABLE OF /psyng/sw_func_scan_det
                       WITH HEADER LINE,
    lt_user_prof       TYPE TABLE OF /psyng/se_user_prof_role
                       WITH HEADER LINE,
    l_numusers         TYPE i,
    l_taskname         TYPE string,
    l_str              TYPE string,
    ls_faobj_system    TYPE /psyng/sw_sys_faobj,
    ls_ao_sys          TYPE /psyng/sw_sys_ao,
    l_system           TYPE rfcdest,
    lt_faobj_sys       TYPE TABLE OF /psyng/faobj2,
    lt_conflict_local  TYPE TABLE OF /psyng/conflict,
    lt_confdet_local   TYPE TABLE OF /psyng/confdet
                       WITH HEADER LINE,
    lt_functtran_local TYPE TABLE OF /psyng/functtran,
    lt_sodorgm         TYPE TABLE OF /psyng/swsodorgm
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

*delete lt_conflict_local where conid <> ir_funid-low.
  DELETE lt_confdet_local WHERE functionid <> ir_funid-low.
  DELETE lt_functtran_local WHERE functionid <> ir_funid-low.

  LOOP AT gt_rfcdest.
    l_system = gt_rfcdest-rfcoptions.
*--Give the task a unique name
    ADD 1 TO g_tasknumber.
    WAIT UNTIL g_tasksrunning < p_maxtsk.
    ADD 1 TO g_tasksrunning.
    l_str = g_tasknumber.
    READ TABLE ir_funid INDEX 1.
    CONCATENATE 'SW_FUN_DET_' ir_funid-low '_' l_str INTO l_taskname.
    DESCRIBE TABLE ir_users LINES l_numusers.
    register_task l_taskname l_system.

*    msg '-->Starting task ' l_taskname  '#users' l_numusers.
* --Variable Elements, get the correct values for the remote system
    READ TABLE gt_faobj_system INTO ls_faobj_system
    WITH KEY rfcdest = l_system.
    IF sy-subrc = 0.
      lt_faobj_sys[] = ls_faobj_system-faobj[].
      DELETE lt_faobj_sys WHERE funid <> ir_funid-low.
    ENDIF.
*--Org Elements, get the correct values for the system
    CLEAR ls_ao_sys.
    READ TABLE gt_ao_sys INTO ls_ao_sys
    WITH KEY rfcdest = l_system.

*--Remove sodorgm data that is not for relevant objects
    REFRESH : lt_sodorgm.
    SORT lt_faobj_sys BY object.
    LOOP AT ls_ao_sys-swsodorgm INTO lt_sodorgm. "WHERE abb IN orglvl.
      "HBHALLA (PN-11746) (13/05/25)
      READ TABLE lt_faobj_sys WITH KEY object = lt_sodorgm-object
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        APPEND lt_sodorgm.
      ENDIF.
    ENDLOOP.


    IF gt_rfcdest-rfcdest IS INITIAL.

*--Execute the detailed analysis
      CALL FUNCTION '/PSYNG/SW_FUNC_USER_DETAIL_42'
        STARTING NEW TASK l_taskname
        PERFORMING get_detailed_function_res ON END OF TASK
        EXPORTING
          if_showcomp  = 'X'
          if_showpcom  = 'X'
*         IF_EXLCKUSR  =
          if_validusr  = p_val
*         IF_OUTVDATE  =
*          if_orgchk    = 'X'   "HBHALLA (PN-11746) (08/05/25)
          if_orgchk    = orgchk "HBHALLA (PN-11746) (08/05/25)
          i_sodvrsio   = p_vrsio
          i_config_set = p_cfgset
          i_org_field  = g_org_field                        "OPL645
          i_exclude_er_roles  = excl_er "(++)UMITTAL PN17376 18/02/2026

        TABLES
          it_bname     = ir_users
          it_confdet   = lt_confdet_local
          it_functtran = lt_functtran_local
          it_faobj     = lt_faobj_sys
          it_swsodorgm = lt_sodorgm
          et_outputdet = lt_results
          et_user_prof = lt_user_prof
          it_orglvl    = orglvl    "AKUMAR
          it_faobj_org = gt_faobj_only_org.                 "OPL645.

    ELSE.
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
      CALL FUNCTION '/PSYNG/SW_FUNC_USER_DETAIL_42'
        STARTING NEW TASK l_taskname
        DESTINATION gt_rfcdest-rfcdest
        PERFORMING get_detailed_function_res ON END OF TASK
        EXPORTING
          if_showcomp  = 'X'
          if_showpcom  = 'X'
*         IF_EXLCKUSR  =
          if_validusr  = p_val
*         IF_OUTVDATE  =
*          if_orgchk    = 'X'   "HBHALLA (PN-11746) (08/05/25
          if_orgchk    = orgchk "HBHALLA (PN-11746) (08/05/25)
          i_sodvrsio   = p_vrsio
          i_config_set = p_cfgset
          i_org_field  = g_org_field                        "OPL645
          i_exclude_er_roles  = excl_er "(++)UMITTAL PN17376 18/02/2026
        TABLES
          it_bname     = ir_users
          it_confdet   = lt_confdet_local
          it_functtran = lt_functtran_local
          it_faobj     = lt_faobj_sys
          it_swsodorgm = lt_sodorgm
          et_outputdet = lt_results
          et_user_prof = lt_user_prof
          it_orglvl    = orglvl "AKUMAR
          it_faobj_org = gt_faobj_only_org                 "OPL645

*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
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

    ENDIF.
  ENDLOOP.
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
    lt_results       TYPE TABLE OF /psyng/sw_func_scan_det
                     WITH HEADER LINE,
    lt_user_prof     TYPE TABLE OF /psyng/se_user_prof_role
                     WITH HEADER LINE,
    l_system_msg(80) TYPE c,
    l_numres         TYPE i,
    l_det            TYPE i,
    l_task           LIKE LINE OF gt_idx_task.
  FIELD-SYMBOLS: <lfs_results> TYPE /psyng/sw_func_scan_det. "RGUPTA

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_FUNC_USER_DETAIL_42'
    TABLES
          et_outputdet                = lt_results
          et_user_prof                = lt_user_prof
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
*    msg_nc '-->Finished task ' i_taskname  '#results' l_numres.
    ADD l_numres TO g_totalresults.
    l_task-task = i_taskname.
*    condense l_task_string.
    READ TABLE gt_idx_task WITH TABLE KEY task = l_task-task.
    IF sy-subrc = 0.
* BOC by RGUPTA on 20.04.22
      LOOP AT lt_results[] ASSIGNING <lfs_results>.
        IF <lfs_results>-objct <> 'S_TCODE'.
          CLEAR <lfs_results>-tcode.
        ENDIF.
      ENDLOOP.
* EOC by RGUPTA on 20.04.22
      gt_det_results-results[]   = lt_results[].
      gt_det_results-user_prof[] = lt_user_prof[].
      gt_det_results-sys = gt_idx_task-sysid.
      APPEND  gt_det_results TO gt_det_results .
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
  LOOP AT gt_det_results.
    PERFORM process_detailed_res
      TABLES gt_det_results-results
             gt_det_results-user_prof
      USING
             gt_det_results-sys .
    DELETE gt_det_results.
  ENDLOOP.
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
TABLES   it_results STRUCTURE /psyng/sw_func_scan_det
         it_user_prof STRUCTURE /psyng/se_user_prof_role
USING    i_sysid    TYPE /psyng/sysid.
  DATA : l_fun_idx   TYPE i,
         l_con_idx   TYPE i,
         l_role_idx  TYPE i,
         l_prof_idx  TYPE i,
         l_sys_idx   TYPE i,
         l_user_idx  TYPE i,
         l_comp_idx  TYPE i,
         l_tcode_idx TYPE i,
         l_obj_idx   TYPE i,
         l_field_idx TYPE i,
         l_auth_idx  TYPE i,
         l_abb_idx   TYPE i.
  LOOP AT it_results.
*-- get system id details
    get_index gt_idx_sys i_sysid
              l_sys_idx g_idx_sys.
*-- get user id details
    get_index gt_idx_user it_results-bname
              l_user_idx g_idx_user.
*-- get function id details
    get_index gt_idx_function it_results-funid
              l_fun_idx g_idx_function.
*-- get profile id details
    get_index_sys gt_idx_profile it_results-profile
                  l_prof_idx g_idx_profile l_sys_idx.
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
*--Store function profile link
    store_funprofile l_sys_idx l_fun_idx l_prof_idx
    l_user_idx."Added by : UMITTAL C1342 D67K931619 14/05/2024

*--Store user profile link
    store_userprofile l_sys_idx l_user_idx l_prof_idx.
*--Store the details
*--out of macro params, store org abb directly
    gt_db_vonbisabb-abb = it_results-org_abb.
    store_authdetails l_sys_idx l_fun_idx l_prof_idx
                      l_tcode_idx l_obj_idx l_field_idx
                      l_auth_idx it_results-von it_results-bis.
    IF NOT it_results-org_abb IS INITIAL.
      get_index gt_idx_abb it_results-org_abb
                l_abb_idx g_idx_abb.
      store_userfunabb
        l_user_idx l_fun_idx l_abb_idx.
    ENDIF.
  ENDLOOP.
*--Process the role information
  LOOP AT it_user_prof.
    IF NOT it_user_prof-agr_name IS INITIAL.
*-- get role id details
      get_index_sys gt_idx_role it_user_prof-agr_name
                    l_role_idx g_idx_role l_sys_idx.
*-- get profile id details
      get_index_sys gt_idx_profile it_user_prof-profile
                    l_prof_idx g_idx_profile l_sys_idx.
*-- store profile role link
      store_profilerole l_sys_idx l_prof_idx l_role_idx.
      IF NOT it_user_prof-comp_agr IS INITIAL.
*-- get role id details
        get_index_sys gt_idx_role it_user_prof-comp_agr
                      l_comp_idx g_idx_role l_sys_idx.
*--get user index
        get_index gt_idx_user it_user_prof-bname
                  l_user_idx g_idx_user.
*-- store role composite link for user
        store_usercomposite l_sys_idx l_user_idx l_role_idx l_comp_idx.
      ELSE.
*      -- store role NO composite link for user
        store_usercomposite l_sys_idx l_user_idx l_role_idx 0.

      ENDIF.
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
         lt_resc           TYPE TABLE OF /psyng/swrescaut
        WITH               HEADER LINE,
         lt_resc2          TYPE TABLE OF /psyng/swrescaut
       WITH               HEADER LINE,

         ls_resc_id        TYPE /psyng/swrescaut,
         ls_resc_id_prev   TYPE /psyng/swrescaut,
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
      READ TABLE gt_idx_caut WITH TABLE KEY
        sys          = ls_resc_id-sys
        funindex     = ls_resc_id-funindex
        profileindex = ls_resc_id-profileindex.
      IF sy-subrc = 0.
*    --This profile has already been stored for this function
      ELSE.
        IF ls_resc_id_prev IS INITIAL.
          ls_resc_id_prev = ls_resc_id.
        ENDIF.


        IF ls_resc_id <> ls_resc_id_prev.
*  --a full profile has been handled
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
*--Process last profile
    IF NOT l_alldata IS INITIAL.
      READ TABLE gt_idx_caut WITH TABLE KEY
        sys          = ls_resc_id-sys
        funindex     = ls_resc_id-funindex
        profileindex = ls_resc_id-profileindex.
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
    MODIFY /psyng/swrescaut FROM TABLE lt_resc.
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
  msg '|                    ' 'Job Summary    '
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
  '/PSYNG/SWRESICON'  /psyng/swresicon,
  '/PSYNG/SWRESITCD'  /psyng/swresitcd,
  '/PSYNG/SWRESIOBJ'  /psyng/swresiobj,
  '/PSYNG/SWRESIFLD'  /psyng/swresifld,
  '/PSYNG/SWRESIFUN'  /psyng/swresifun,
  '/PSYNG/SWRESIPRO'  /psyng/swresipro,
  '/PSYNG/SWRESIAUT'  /psyng/swresiaut,
  '/PSYNG/SWRESISYS'  /psyng/swresisys,
  '/PSYNG/SWRESIROL'  /psyng/swresirol,
  '/PSYNG/SWRESIABB'  /psyng/swresiabb.

  summary_info 'Data Tables' :
*   '/PSYNG/SWRESVBA'  /PSYNG/SWRESVBA,
   '/PSYNG/SWRESAUTH'  /psyng/swresauth,
   '/PSYNG/SWRESCAUT'  /psyng/swrescaut,
   '/PSYNG/SWRESUPR'   /psyng/swresupr,
   '/PSYNG/SWRESCON'   /psyng/swrescon,
   '/PSYNG/SWRESCONT'  /psyng/swrescont,
   '/PSYNG/SWRESUSR'   /psyng/swresusr,
   '/PSYNG/SWRESCFUN'  /psyng/swrescfun,
   '/PSYNG/SWRESFPR'   /psyng/swresfpr,
   '/PSYNG/SWRESPROL'  /psyng/swresprol,
   '/PSYNG/SWRESUCOM'  /psyng/swresucom,
   '/PSYNG/SWRESUABB'  /psyng/swresuabb.

*--Add storage info to header record
*  we estimate about 25% extra is needed for indexes and general
*  overhead on top of the raw record storage
  gs_db_header-kbytes_est = ( g_storage_kb_est / 100 ) * 125 .
  MODIFY /psyng/swreshdr FROM gs_db_header.
  COMMIT WORK.


  msg_nc '#records : ' l_total 'in #tables' l_tables.
  IF i_funinfo = 'X'.
*  --Display how long we spent on each conflict/function
    SORT gt_runtime BY seconds DESCENDING.
    msg 'Runtime Information' '' '' ''.
    CLEAR l_char.
    l_char    = 'ID'.
    l_char+15 = 'seconds'.
    l_char+25 = 'users'.
    l_char+35 = 'user/second'.
*    msg 'ID' 'seconds' 'users' 'user/second'.
    msg l_char '' '' ''.
    LOOP AT gt_runtime.
      CLEAR l_char.
      l_secperu = gt_runtime-users  / gt_runtime-seconds.
      l_char    = gt_runtime-id.
      l_str = gt_runtime-seconds.
      CONDENSE l_str.
      l_char+15 = l_str.
      l_str = gt_runtime-users.
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
  DATA : lt_conflict TYPE TABLE OF /psyng/swresicon WITH HEADER LINE,
         lt_tcode    TYPE TABLE OF /psyng/swresitcd WITH HEADER LINE,
         lt_object   TYPE TABLE OF /psyng/swresiobj WITH HEADER LINE,
         lt_field    TYPE TABLE OF /psyng/swresifld WITH HEADER LINE,
         lt_function TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
         lt_auth     TYPE TABLE OF /psyng/swresiaut WITH HEADER LINE,
         lt_profile  TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
         lt_role     TYPE TABLE OF /psyng/swresirol WITH HEADER LINE,
         lt_sys      TYPE TABLE OF /psyng/swresisys WITH HEADER LINE,
         lt_abb      TYPE TABLE OF /psyng/swresiabb WITH HEADER LINE,
         l_rt_start  TYPE i,
         l_rt_end    TYPE i,
         l_cnt_con   TYPE i,
         l_cnt_mit   TYPE i.


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
*--Count : conflicted users ( at least one unmitigated conflict)
*          mitigated users  ( has conflicts, all mitigated )
  SORT : gt_conflicted_users BY bname,
         gt_mitigated_users BY bname.
  LOOP AT gt_conflicted_users.
    l_cnt_con = gt_conflicted_users-count.
    CLEAR l_cnt_mit.
    READ TABLE gt_mitigated_users
      WITH KEY bname = gt_conflicted_users-bname BINARY SEARCH.
    IF sy-subrc <> 0.
*--No conflicts Mitigated
      ADD 1 TO gs_db_header-conflicted_users.
    ELSE.
      l_cnt_mit = gt_mitigated_users-count.
      IF gt_mitigated_users-count < gt_conflicted_users-count.
*--More conflicts than mitigated
        ADD 1 TO gs_db_header-conflicted_users.
      ELSE.
*--All conflicts mitigated
        ADD 1 TO gs_db_header-mitigated_users.
      ENDIF.
    ENDIF.
    user_count_con gt_conflicted_users-bname l_cnt_con l_cnt_mit.
  ENDLOOP.


  GET RUN TIME FIELD l_rt_start.
  msg 'Start Inverting the indexes' '' '' ''.
  invert_index :
      gt_idx_conflict      gt_val_conflict,
      gt_idx_sys           gt_val_sys,
      gt_idx_user          gt_val_user,
      gt_idx_function      gt_val_function,
      gt_idx_role          gt_val_role,
      gt_idx_profile       gt_val_profile,
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
                   '/PSYNG/SWRESUSR'   gt_db_users,
                   '/PSYNG/SWRESCON'   gt_db_usercon,
                   '/PSYNG/SWRESCONT'  gt_db_concont,
                   '/PSYNG/SWRESCFUN'  gt_db_confun,
                   '/PSYNG/SWRESFPR'   gt_db_funprofile,
                   '/PSYNG/SWRESUPR'   gt_db_userprofile,
                   '/PSYNG/SWRESPROL'  gt_db_profilerole,
                   '/PSYNG/SWRESUCOM'  gt_db_usercomposite,
                   '/PSYNG/SWRESUABB'  gt_db_ufunabb.
*--Value tables all have KEY field in memory,
* but specific named fields in DB
* Convert and store them
  convert_val_table :
    gt_val_conflict lt_conflict conid    conindex    '/PSYNG/SWRESICON',
    gt_val_tcode    lt_tcode    tcode    tcodeindex  '/PSYNG/SWRESITCD',
    gt_val_object   lt_object   object   objectindex '/PSYNG/SWRESIOBJ',
    gt_val_field    lt_field    field    fieldindex  '/PSYNG/SWRESIFLD',
    gt_val_function lt_function funid    funindex    '/PSYNG/SWRESIFUN',
    gt_val_auth     lt_auth     auth     authindex   '/PSYNG/SWRESIAUT',
    gt_val_profile  lt_profile  profname profindex   '/PSYNG/SWRESIPRO',
    gt_val_role     lt_role     agr_name roleindex   '/PSYNG/SWRESIROL',
    gt_val_sys      lt_sys      sysid    sysindex    '/PSYNG/SWRESISYS',
    gt_val_abb      lt_abb      org_abb  abbindex    '/PSYNG/SWRESIABB'.







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

  MODIFY /psyng/swreshdr FROM gs_db_header.
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
  DATA: lr_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
        WITH HEADER LINE,
  l_continue TYPE flag,
  lt_bapiret TYPE TABLE OF bapiret2.
  APPEND LINES OF s_system TO lr_rfcs.

  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup    = 'X'
      i_module   = 'SE'
    IMPORTING
      e_continue = l_continue
    TABLES
      it_rfcdes  = lr_rfcs
*BOC:HBHALLA (03/12/24)
        EXCEPTIONS
            OTHERS     = 1.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (03/12/24)

  IF  l_continue <> 'X'.
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
  PERFORM init_but USING 'EXE_BUT' 'X' CHANGING exe_but . "HBHALLA
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
    bname = g_current_user AND"sy-uname AND C0700
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
  ls_state-bname       = g_current_user."sy-uname. C0700
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
      name       = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result     = button
*BOC:HBHALLA (03/12/24)
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
      name       = 'ICON_EXPAND'
      add_stdinf = ''
    IMPORTING
      result     = button
*BOC:HBHALLA (06/12/24)
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
*EOC:HBHALLA (06/12/24)

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
*BOC:HBHALLA (PN-11746) (10/05/25)
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
*EOC:HBHALLA (PN-11746) (10/05/25)
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
  PERFORM handle_section USING  exe_but  'EXE'. "HBHALLA
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

*---------------------------------------------------------------------*
*       FORM get_users_count                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_users_count.
  DATA : l_numb      TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local    TYPE flag VALUE 'X',
         l_exclude_locked TYPE flag VALUE 'X',
         l_exclude_expired TYPE flag VALUE 'X'.

  IF p_remon = 'X'.
    CLEAR lv_local.
  ENDIF.

  IF p_val = 'X'.
    CLEAR : l_exclude_locked, l_exclude_expired.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
    EXPORTING
      i_validuser       = ' ' "p_val
      i_include_locked  = l_exclude_locked
      i_include_expired = l_exclude_expired
      if_local_system   = lv_local
      if_show_message   = 'X'
    IMPORTING
      e_usercount       = l_numb
    TABLES
      it_userlist       = s_bname
      it_grouplist      = s_class
      it_usertype       = s_ustyp
      it_costcenter     = s_kostl
      it_rfcrange       = s_system.

ENDFORM.                    " get_users_count
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

*--BOC C1371 AKUMAR
*  --Check if Configuration Set functionality is enabled.
    se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
    IF gf_cfg_set_enabled = 'Y' OR gf_cfg_set_enabled = 'X'.
      gf_cfg_set_enabled = 'X'.
    ELSE.
      CLEAR gf_cfg_set_enabled.
    ENDIF.

    IF gf_cfg_set_enabled = 'X'.
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
*--EOC C1371 AKUMAR

  ENDIF.
ENDFORM.                    " get_default_version_set
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
             lc_check_type TYPE c LENGTH 1 VALUE '3',
        lc_fmname TYPE tfdir-funcname VALUE '/SAST/SE_SOD_USER_RESULTS'.
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
             AND check_type   = lc_check_type.   "#EC SAST_CI_GEN_CHECK
    IF sy-subrc = 0.
*    check if fm exists<
      CALL FUNCTION 'FUNCTION_EXISTS'
        EXPORTING
          funcname                 = lc_fmname
       EXCEPTIONS
         function_not_exist       = 1
         OTHERS                   = 2.

      IF sy-subrc = 0.
*BOC UMITTAL SE VF scan changes-25/11/2024
        CALL FUNCTION lc_fmname              "#EC PATHLOCK_CI_DYN_ACCES
*        CALL FUNCTION '/SAST/SE_SOD_USER_RESULTS'
*EOC UMITTAL SE VF scan changes-25/11/2024
             EXPORTING
               i_auditplan_id       = p_audpl
               i_rundid             = p_runid
               i_sysid              = sy-sysid
               i_check_type         = lc_check_type.
        IF sy-subrc = 0.
          COMMIT WORK.
        ENDIF.
      ELSE.
        MESSAGE s002(/psyng/sw) WITH
                 'SAST Collection FM does not exists'(i15).
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_ORGLVL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1442   text
*      <--P_ORGLVL_LOW  text
*----------------------------------------------------------------------*
FORM f4_orglvl  USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
  CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
    EXPORTING
      i_cfg_set = p_cfgset
    IMPORTING
      e_orglvl  = e_orglvl.
ENDFORM.
