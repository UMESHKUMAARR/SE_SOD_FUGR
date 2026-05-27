REPORT /psyng/sw_129 MESSAGE-ID /psyng/sw.

TABLES: agr_define, /psyng/function, rfcdes,/psyng/swsodorgm.
INCLUDE /psyng/sw_113.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/sw_125.
*---internal table Declaration
TYPE-POOLS : slis.
CONSTANTS: gc_service       TYPE xuobject VALUE 'S_SERVICE',
           gc_srv_name      TYPE xufield  VALUE 'SRV_NAME'.
DATA:
  gt_functions       TYPE TABLE OF /psyng/function  WITH HEADER LINE,
  gt_simu_roleauth   TYPE TABLE OF /psyng/roleauth  WITH HEADER LINE,
  gt_simu_roletcode  TYPE TABLE OF /psyng/roletcode WITH HEADER LINE,
  gt_routput_summary TYPE TABLE OF /psyng/sw_out_routput
                                                   WITH HEADER LINE,
  gt_roles_forrem_simulation
                     TYPE TABLE OF /psyng/sw_role_removal_simu
                                                   WITH HEADER LINE,
  gt_removed_roles   TYPE TABLE OF /psyng/sw_removed_roles_role
                                                   WITH HEADER LINE,
  gt_mitigations      TYPE TABLE OF /psyng/mitigation_assignment,
  gt_routput_sum      TYPE TABLE OF /psyng/sw_out_routput,
  gt_func_routput     TYPE TABLE OF /psyng/sw_out_routput
                                                   WITH HEADER LINE,
  gt_routput_temp     TYPE TABLE OF /psyng/sw_out_routput,
  gt_res              TYPE TABLE OF /psyng/sw_out_routput
                                                   WITH HEADER LINE,
  gt_routput_before   TYPE TABLE OF /psyng/sw_out_routput
                                                   WITH HEADER LINE,
  gt_routput_after    TYPE TABLE OF /psyng/sw_out_routput
                                                   WITH HEADER LINE,
  gt_role_addition_simu
                      TYPE TABLE OF /psyng/sw_role_addition_simu
                                                   WITH HEADER LINE,
 gt_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu
                                                   WITH HEADER LINE,
 gt_rfcdest_anal      TYPE TABLE OF rfcdes         WITH HEADER LINE,
 g_trolecount         TYPE int4,
 g_ucomm              LIKE sy-ucomm,
 gf_before_sim(1)     TYPE c,
 gt_faobj_system      TYPE /psyng/sw_tab_sys_faobj,
 gt_ao_sys            TYPE /psyng/sw_tab_sys_ao,
 gf_cfg_set_enabled   TYPE flag,
 BEGIN OF gt_routput OCCURS 0.
INCLUDE       STRUCTURE /psyng/sw_out_routput.
DATA:   color_cell   TYPE lvc_t_scol,  " Cell color
END OF gt_routput,
gt_outputdet         TYPE TABLE OF /psyng/sw_out_routdet3
                                                 WITH HEADER LINE,
gt_outputdet_temp    TYPE TABLE OF /psyng/sw_out_routdet3
                                                 WITH HEADER LINE,
g_curr_variant       LIKE  rsvar-variant,
g_vari_desc          TYPE varid OCCURS 0         WITH HEADER LINE,
g_variant            LIKE vari-variant,
gr_irsparams         TYPE rsparams OCCURS 0      WITH HEADER LINE,
gt_varit             TYPE varit OCCURS 0         WITH HEADER LINE,
g_numroles           TYPE i,
g_exit_proc,
g_rfcdes_local       TYPE rfcdes-rfcoptions,
g_program            LIKE sy-repid,
gt_rfcdest           TYPE TABLE OF rfcdes WITH HEADER LINE,
*--- Field catalog
gt_fieldcat          TYPE TABLE OF slis_fieldcat_alv,
gs_fieldcat          LIKE LINE OF gt_fieldcat,
gs_layout            TYPE slis_layout_alv,
gt_sort              TYPE STANDARD TABLE OF slis_sortinfo_alv,
gt_fieldcat1         TYPE TABLE OF slis_fieldcat_alv,
gs_fieldcat1         LIKE LINE OF gt_fieldcat,
gs_layout1           TYPE slis_layout_alv,
gt_sort1             TYPE STANDARD TABLE OF slis_sortinfo_alv,
g_running_tasks      TYPE i,
g_dynnr              TYPE sy-dynnr,
gf_dflt_enhance_matrix TYPE flag,
BEGIN OF gt_output_smm OCCURS 0,
       rfcdest       LIKE /psyng/sw_out_routput-rfcdest,
       agr_name      LIKE /psyng/sw_out_routput-agr_name,
       agr_text      LIKE /psyng/sw_out_routput-agr_text,
       functionid    LIKE /psyng/sw_out_routput-functionid,
       org_abb       LIKE /psyng/sw_out_routput-org_abb,
       fdescription  LIKE /psyng/function-description,
       owner         LIKE /psyng/function-owner,
       busarea       LIKE /psyng/function-busarea,
       simu          TYPE c,
       simu_before   TYPE c,
       simu_after    TYPE c,
       enhanced      TYPE c,
       color_cell    TYPE lvc_t_scol,
 END OF gt_output_smm,
 BEGIN OF gt_output_det OCCURS 0,
       agr_name      LIKE /psyng/sw_out_routdet3-agr_name,
       org_abb       LIKE /psyng/sw_out_routput-org_abb,
       functionid    LIKE /psyng/sw_out_routdet3-functionid,
       rfcdest       LIKE /psyng/sw_out_routdet3-rfcdest,
       tcode         LIKE /psyng/sw_out_routdet3-tcode,
       objct         LIKE /psyng/sw_out_routdet3-objct,
       auth          LIKE /psyng/sw_out_routdet3-auth,
       field         LIKE /psyng/sw_out_routdet3-field,
       von           LIKE /psyng/sw_out_routdet3-von,
       bis           LIKE /psyng/sw_out_routdet3-bis,
       child_agr     LIKE /psyng/sw_out_routdet3-child_agr,
       simu          TYPE c,
       enhanced      TYPE c,
        color_cell   TYPE lvc_t_scol,
 END OF gt_output_det,
 gt_conflict_local   TYPE TABLE OF /psyng/conflict,
 gt_confdet_local    TYPE TABLE OF /psyng/confdet
                                             WITH HEADER LINE,
 gt_functtran_local  TYPE TABLE OF /psyng/functtran,
 gt_faobj_local      TYPE TABLE OF /psyng/faobj2,
 gt_swsodorgm_local  TYPE TABLE OF /psyng/swsodorgm,
 gt_functran_no_enh_local
                     TYPE TABLE OF /psyng/functtran,
 gt_tcodes_local     TYPE TABLE OF /psyng/sw_par_tcode_output,
 gt_roles_foradd_simu
                     TYPE TABLE OF /psyng/sw_role_addition_simu,
 g_conf_number       TYPE i,
 g_local_sod_value   TYPE /psyng/swconfig-value,
 gf_local_sod        TYPE flag,
 g_warning_msg(1)    TYPE c,
 g_preconfig         TYPE /psyng/swcfgset-setid,
 lf_set_invalid      TYPE FLAG,
 lf_set_nocover      TYPE flag,
 lf_set_mismatch     TYPE flag,
 lf_include_local    type flag,
 ls_ba_role          type /PSYNG/BC_BA_00,
 g_current_user TYPE sy-uname. "C0700

*---Selection Screen
*--Role Block
SELECTION-SCREEN: BEGIN OF BLOCK role_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) role_but USER-COMMAND role_but.
SELECTION-SCREEN COMMENT 16(50) text-b01 .

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  63(12) text-198 USER-COMMAND verify_r
                                      MODIF ID rol.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-009 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
SELECT-OPTIONS: role FOR agr_define-agr_name MODIF ID rol.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-084 MODIF ID rol.
SELECTION-SCREEN: POSITION 25.
select-options : rba for ls_ba_role-busarea
MODIF ID rol."(++)HBHALLA(PN-17817)(19/02/26)(Collapse button)
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(21) text-013 MODIF ID rol.
SELECTION-SCREEN: POSITION 28.
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
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS: orgchk   AS CHECKBOX DEFAULT ' ' USER-COMMAND org
MODIF ID rol."(++)HBHALLA(PN-17817)(19/02/26)(Collapse button)
SELECTION-SCREEN: COMMENT 7(47) text-167 FOR FIELD orgchk
                                         MODIF ID rol.

SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK role_o.

*--Remote Block
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) rem_but
  USER-COMMAND rem_but .
SELECTION-SCREEN COMMENT 16(50) text-b02  .
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 4(20) text-159 MODIF ID rem.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: POSITION 4.
PARAMETERS : ronlyrem TYPE flag USER-COMMAND remo MODIF ID rem.
SELECTION-SCREEN: COMMENT 7(47) text-075 FOR FIELD ronlyrem
                                         MODIF ID rem.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK rem_o.

SELECTION-SCREEN: BEGIN OF BLOCK cres WITH FRAME. "TITLE text-017.
SELECTION-SCREEN PUSHBUTTON  01(6) fun_but USER-COMMAND fun_but.
SELECTION-SCREEN COMMENT 16(50) text-017.
SELECT-OPTIONS:  spfun FOR   /psyng/function-function MODIF ID fun,
                 busarea FOR /psyng/function-busarea  MODIF ID fun,
                 owner   FOR /psyng/function-owner    MODIF ID fun.
PARAMETERS:      sodvrsio LIKE /psyng/conflict-vrsio
                 MEMORY ID /psyng/vrsio               MODIF ID fun.
PARAMETERS : cfgset   TYPE /psyng/seconfid            MODIF ID fun.

SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb       MODIF ID fun.

SELECTION-SCREEN: END OF BLOCK cres.

SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME.
SELECTION-SCREEN PUSHBUTTON  1(6) simu_but USER-COMMAND simu_but.
SELECTION-SCREEN COMMENT 16(50) text-h13 .
SELECTION-SCREEN INCLUDE BLOCKS b_sim.
SELECTION-SCREEN: END OF BLOCK sim_o.

*--------SE 3.2 Enhancement to include Details level output---------*
SELECTION-SCREEN: BEGIN OF BLOCK detail WITH FRAME TITLE text-012.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: sum RADIOBUTTON GROUP out1 DEFAULT 'X' USER-COMMAND a.
SELECTION-SCREEN: COMMENT 4(30) text-020.

SELECTION-SCREEN: POSITION 35.
PARAMETERS: det RADIOBUTTON GROUP out1.              "Detailed output
SELECTION-SCREEN: COMMENT 37(30) text-021.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK detail.

*---Execution Options Block
SELECTION-SCREEN: BEGIN OF BLOCK exe_o WITH FRAME  .
SELECTION-SCREEN PUSHBUTTON  01(6) exe_but USER-COMMAND exe_but.
SELECTION-SCREEN COMMENT 10(50) text-h10.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance MODIF ID exe.
SELECTION-SCREEN COMMENT 3(30) text-015 MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX MODIF ID exe.
SELECTION-SCREEN COMMENT 36(50) text-016 MODIF ID exe.
SELECTION-SCREEN END OF LINE.

PARAMETERS: p_shonof AS CHECKBOX DEFAULT ' ' MODIF ID exe.

SELECTION-SCREEN: END OF BLOCK exe_o.

SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME .
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b07.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-025 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-026 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-002 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-001 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN: END OF BLOCK bgd_o.
*--Hidden parameters

PARAMETERS: p_caldet(1) TYPE c NO-DISPLAY,
            p_first TYPE flag NO-DISPLAY.


LOAD-OF-PROGRAM.
  p_first = 'X'.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
*    IF cfgset IS INITIAL.
*     DATA e_vrsio TYPE /psyng/sodvrsio.
**Get sod version default
*      CALL FUNCTION '/PSYNG/SW_034'
*           IMPORTING
*                e_vrsio = e_vrsio.
**--   default to the latest published configuration set (highest nr)
*      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
*      EXPORTING
*                i_vrsio      = 'X'
*                i_cfgvrsio   = e_vrsio
*           IMPORTING
*                e_config_set = cfgset.
*    ENDIF.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.
*---Default config param for enhanced sod matrix checkbox
  se_config_param 'DFLT_ENHANCE_MATRIX' gf_dflt_enhance_matrix.
  IF gf_dflt_enhance_matrix = 'Y' OR gf_dflt_enhance_matrix = 'X'.
    IF p_enhanc IS INITIAL.
      p_enhanc = 'X'.
    ENDIF.
  ELSE.
    CLEAR p_enhanc.
  ENDIF.

INITIALIZATION.
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700
  PERFORM exelog.
  PERFORM set_button_icons.

AT SELECTION-SCREEN.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.

  PERFORM check_input.
  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.

  IF ronlyrem = 'X'.
    IF remrfc[] IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for remote analysis'(180).
    ENDIF.
  ENDIF.

  IF NOT gf_cfg_set_enabled IS INITIAL.
   IF  g_ucomm is initial.
*--Check Config Set
     lf_include_local = 'X'.
      if ronlyrem = 'X'.
        clear lf_include_local.
      endif.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
           EXPORTING
                i_setid         = cfgset
                i_vrsio         = sodvrsio
                if_show_warning = 'X'
                IF_LOCAL_SYSTEM = lf_include_local
            TABLES
              IT_RFCDEST        = remrfc.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
      EXPORTING
                i_vrsio      = 'X'
                i_cfgvrsio   = sodvrsio
           IMPORTING
                e_config_set = cfgset.
    ENDIF.
   ENDIF.

  PERFORM handle_button.
  PERFORM handle_sections.


  LOOP AT SCREEN.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND screen-name CS 'CFGSET'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.


    CASE screen-name .
      WHEN 'ORGLVL-LOW' OR  'ORGLVL-HIGH'.
        IF orgchk = 'X'.
          screen-input = 1.
        ELSE.
          REFRESH : orglvl.
          screen-input = 0.
        ENDIF.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          IF p_caldet <> 'X'.
            screen-input = 1.
            IF p_first = 'X'.
              CLEAR p_first.
              p_hienhn = 'X'.
            ENDIF.
          ENDIF.
        ENDIF.
      WHEN 'P_SHONOF'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT spfun[] IS INITIAL
        OR NOT busarea[] IS INITIAL
        OR NOT owner[] IS INITIAL.
          IF p_shonof = 'X'.
            CLEAR p_shonof.
            screen-input = 0.
            MESSAGE w398(00) WITH text-c03.
          ENDIF.

          screen-input = 0.
          CLEAR p_shonof.
        ELSE.
          screen-input = 1.
        ENDIF.
*--Disable Show no SOD when detailed output is requested
        IF det = 'X'.
          screen-input  = '0'.
          IF p_shonof = 'X'.
            CLEAR p_shonof.
            MESSAGE w398(00) WITH text-c03.
          ENDIF.
        ELSE.
          IF spfun[] IS INITIAL
          AND busarea[] IS INITIAL
          AND owner[] IS INITIAL.
            screen-input  = '1'.
          ENDIF.
        ENDIF.
    ENDCASE.
    MODIFY SCREEN .
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high .

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
  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    lf_include_local = 'X'.
      if ronlyrem = 'X'.
        clear lf_include_local.
      endif.
        CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
             EXPORTING
                  i_setid          = cfgset
                  i_vrsio          = sodvrsio
                  if_show_warning  = 'X'
                  IF_LOCAL_SYSTEM  = lf_include_local
             IMPORTING
                 ef_wrong_version   = lf_set_invalid
                 EF_MISSING_SYSTEM  = lf_set_nocover
                 EF_SYSTEM_MISMATCH = lf_set_mismatch
            TABLES
              IT_RFCDEST            = remrfc.
    IF lf_set_invalid  = 'X' or
       lf_set_nocover  = 'X' .
      exit.
    endif.
  ENDIF.


  DATA : l_vrsio TYPE /psyng/sodvrsio.
*--Clear system filter buffer when a new analysis starts
  CALL FUNCTION '/PSYNG/SW_124'
       EXPORTING
            if_clear_buffer = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
         TOO_MANY_OPTIONS = 1
          OTHERS = 2.
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.
  g_program = sy-repid.
  IF g_exit_proc = 'Y'.

*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_129
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.
clear g_warning_msg.

  IF orgchk = 'X'.
    exelog sy-repid 'ORGCHECK'.
  ELSE.
    exelog sy-repid 'NO_ORGCHECK'.
  ENDIF.

  se_config_param 'DFLT_LOCAL_SOD' gf_local_sod.


  IF g_local_sod_value = 'Y'.
    gf_local_sod = 'X'.
  ELSE.
    gf_local_sod = ' '.
  ENDIF.
*--Display information about parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid = g_program.

    CONCATENATE sy-sysid sy-mandt INTO g_rfcdes_local.

*-- Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

  IF gf_local_sod IS INITIAL.

*--If we use a local sod matrix, validate it exists
    SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
    WHERE vrsio = sodvrsio.
    IF sy-subrc NE 0.
      MESSAGE i135 WITH 'SOD Version does not exist.'(195).
      LEAVE LIST-PROCESSING.
    ENDIF.

*--Get functions
    SELECT * FROM /psyng/function
    INTO CORRESPONDING FIELDS OF TABLE gt_functions
    WHERE vrsio    = sodvrsio
      AND busarea  IN busarea
      AND function IN spfun
      AND owner    IN owner.

    IF   gt_functions[] IS INITIAL.
      MESSAGE i113(/psyng/sw) WITH
    'No Function IDs match selection'(m01).
      LEAVE LIST-PROCESSING.
    ENDIF.


    IF NOT gt_functions[] IS INITIAL.
*  *--Load Local SOD Matrix
      CALL FUNCTION '/PSYNG/SW_028'
           EXPORTING
                i_vrsio            = sodvrsio
                i_config_set       = cfgset
                i_orphan_functions = 'X'
                i_enhance          = p_enhanc
                i_orgcheck         = orgchk
                IF_ANALYSIS        = 'X'
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
                it_rfcdest         = gt_rfcdest_anal.
*--Delete unwanted functions
      SORT gt_confdet_local BY functionid.
      LOOP AT gt_confdet_local.
        READ TABLE gt_functions
        WITH KEY function = gt_confdet_local-functionid.
        IF sy-subrc <> 0.
          DELETE gt_functtran_local WHERE
          functionid = gt_confdet_local-functionid.
          DELETE gt_faobj_local WHERE
          funid = gt_confdet_local-functionid.
          DELETE gt_confdet_local WHERE
          functionid = gt_confdet_local-functionid.
        ELSE.
          IF gt_confdet_local-conid IS INITIAL.
            g_conf_number = g_conf_number + 1.
            gt_confdet_local-conid = g_conf_number + 1.
            MODIFY gt_confdet_local.
          ENDIF.
        ENDIF.
      ENDLOOP.

      SORT gt_confdet_local BY functionid.
      DELETE ADJACENT DUPLICATES FROM gt_confdet_local COMPARING
  functionid.
    ENDIF.
  ENDIF.

  REFRESH : gt_role_removal_simu,gt_role_addition_simu.
  IF byrsimu = 'X'.
*--prepare table for role removal simulation
    PERFORM prepare_role_removal_simu
      TABLES gt_roles_forrem_simulation.
    gt_role_removal_simu[] = gt_roles_forrem_simulation[].
  ENDIF.


  IF bysimu = 'X'.
*--3.1 prepare table for role removal simulation
    PERFORM prepare_role_addition_simu
      TABLES gt_roles_foradd_simu.
    gt_role_addition_simu[] = gt_roles_foradd_simu[].
  ENDIF.

  PERFORM validate_other_fields.

*- Simulation Before and After Logic
  IF det NE 'X' AND ( bysimu = 'X' OR byrsimu = 'X' ).
    gt_roles_foradd_simu[] = gt_role_addition_simu[].
    gt_roles_forrem_simulation[] = gt_role_removal_simu[].

    PERFORM before_after_simulation
    TABLES gt_roles_forrem_simulation
           gt_roles_foradd_simu.
  ELSE.
    gt_roles_foradd_simu[] = gt_role_addition_simu[].
    gt_roles_forrem_simulation[] = gt_role_removal_simu[].
    PERFORM smm_data_processing.
  ENDIF.

  PERFORM reformat_output.



  IF det EQ 'X'.
    MESSAGE s176(/psyng/sw).
    PERFORM output_using_alv_det.
  ELSE.
    PERFORM output_using_alv_sum.
  ENDIF.
*&---------------------------------------------------------------------*
*&      Form  prepare_role_removal_simu
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*----------------------------------------------------------------------*
FORM prepare_role_removal_simu TABLES   et_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu.



  IF  NOT rr_rol_1[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_1.
    LOOP AT rr_rol_1.
      MOVE-CORRESPONDING rr_rol_1 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT  rr_rol_2[] IS INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_2.
    LOOP AT rr_rol_2.
      MOVE-CORRESPONDING rr_rol_2 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_3[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_3.
    LOOP AT rr_rol_3.
      MOVE-CORRESPONDING rr_rol_3 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.
  IF  NOT rr_rol_4[] IS  INITIAL.
    et_role_removal_simu-rfcdest = rr_rfc_4.
    LOOP AT rr_rol_4.
      MOVE-CORRESPONDING rr_rol_4 TO et_role_removal_simu.
      APPEND et_role_removal_simu.
    ENDLOOP.
  ENDIF.


ENDFORM.                    " prepare_role_removal_simu
*&---------------------------------------------------------------------*
*&      Form  prepare_role_addition_simu
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------*
FORM prepare_role_addition_simu TABLES   et_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu.
  IF  NOT ar_rol_1[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs1.
    et_role_addition_simu-target_rfcdest = ar_rfcd1.
    LOOP AT ar_rol_1.
      MOVE-CORRESPONDING ar_rol_1 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_2[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs2.
    et_role_addition_simu-target_rfcdest = ar_rfcd2.
    LOOP AT ar_rol_2.
      MOVE-CORRESPONDING ar_rol_2 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_3[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs3.
    et_role_addition_simu-target_rfcdest = ar_rfcd3.
    LOOP AT ar_rol_3.
      MOVE-CORRESPONDING ar_rol_3 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.
  CLEAR et_role_addition_simu.
  IF  NOT ar_rol_4[] IS  INITIAL.
    et_role_addition_simu-source_rfcdest = ar_rfcs4.
    et_role_addition_simu-target_rfcdest = ar_rfcd4.
    LOOP AT ar_rol_4.
      MOVE-CORRESPONDING ar_rol_4 TO et_role_addition_simu.
      APPEND et_role_addition_simu.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " prepare_role_addition_simu
*&---------------------------------------------------------------------*
*&      Form  smm_data_processing
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM smm_data_processing.
  RANGES: lr_rfcdes      FOR rfcdes-rfcdest.
  DATA: ls_cc            TYPE lvc_t_scol WITH HEADER LINE,
        ls_color         TYPE lvc_s_colo,
        lt_confdet_sys   TYPE TABLE OF /psyng/confdet,
        lt_functtran_sys TYPE TABLE OF /psyng/functtran,
        lt_faobj_sys     TYPE TABLE OF /psyng/faobj2,
        ls_ao_sys        TYPE /psyng/sw_sys_ao,
        l_system         TYPE /psyng/rfcname,
        ls_faobj_system  TYPE /psyng/sw_sys_faobj,
        lt_rfcdest       TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                         WITH HEADER LINE,
        lf_remote        TYPE flag,
        lf_simu          TYPE flag.

  IF det NE 'X'.
    LOOP AT gt_rfcdest_anal.
*--Filter Functions by system
      l_system = gt_rfcdest_anal-rfcoptions.
      lt_functtran_sys[] = gt_functtran_local[].
      lt_confdet_sys[]   = gt_confdet_local[].
*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_system.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_system.

      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = l_vrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
                it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
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
      CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
        DESTINATION gt_rfcdest_anal-rfcdest
         EXPORTING
             vrsio              = sodvrsio
             i_config_set       = cfgset
             i_rchdatf          = rchdatf
             i_rchdatt          = rchdatt
             enh_fm             = p_enhanc
             i_shonosod         = p_shonof
             xstb_fm            = 'X'
             i_local_sod        = gf_local_sod
             i_composite_roles  = comprol
             i_single_roles     = singrol
             i_assigned_roles   = asign_r
             org_check          = orgchk
         IMPORTING
              o_totalroles      = g_numroles
         TABLES
              it_func           = spfun
              it_busarea        = busarea
              it_owner          = owner
              it_roles          = role
              IT_ROLE_BA        = rba
              it_conflict       = gt_conflict_local
              it_confdet        = lt_confdet_sys
              it_functions      = gt_functions
              it_functtran      = lt_functtran_sys
              it_faobj          = lt_faobj_sys
              it_swsodorgm      = ls_ao_sys-swsodorgm[]
              it_tcodes         = gt_tcodes_local
              it_functran_no_enh = gt_functran_no_enh_local
              ot_routput        = gt_func_routput
              ot_routput_sum    = gt_routput_summary
              et_mitigations    = gt_mitigations. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      LOOP AT gt_routput_summary."gt_func_routput.
        MOVE-CORRESPONDING gt_routput_summary TO gt_routput.
        APPEND gt_routput.
      ENDLOOP.
      ADD g_numroles TO g_trolecount.
*-- Get role text
      PERFORM get_role_text.

      LOOP AT gt_routput.
        MOVE-CORRESPONDING gt_routput TO gt_output_smm.
        READ TABLE gt_functions WITH KEY
                           function = gt_routput-functionid.
        IF sy-subrc = 0.
          gt_output_smm-owner = gt_functions-owner.
          gt_output_smm-busarea = gt_functions-busarea.
          gt_output_smm-fdescription = gt_functions-description.
        ENDIF.
        APPEND gt_output_smm.
      ENDLOOP.

    ENDLOOP.


    REFRESH gt_routput.
    IF NOT ronlyrem = 'X'.
*--Filter Functions by system
      CONCATENATE sy-sysid sy-mandt INTO l_system.
      lt_functtran_sys[] = gt_functtran_local[].
      lt_faobj_sys[]     = gt_faobj_local[].
      lt_confdet_sys[]   = gt_confdet_local[].
      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = l_vrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
                it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


      CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
           EXPORTING
                vrsio              = sodvrsio
                i_config_set       = cfgset
                i_rchdatf          = rchdatf
                i_rchdatt          = rchdatt
                enh_fm             = p_enhanc
                i_shonosod         = p_shonof
                xstb_fm            = 'X'
                i_local_sod        = gf_local_sod
                i_composite_roles  = comprol
                i_single_roles     = singrol
                i_assigned_roles   = asign_r
                org_check          = orgchk
           IMPORTING
                o_totalroles       = g_numroles
           TABLES
                it_func            = spfun
                it_busarea         = busarea
                it_owner           = owner
                it_roles           = role
                IT_ROLE_BA         = rba
                it_roles_simu      = simurols
                it_conflict        = gt_conflict_local
                it_confdet         = lt_confdet_sys
                it_functions       = gt_functions
                it_functtran       = lt_functtran_sys
                it_faobj           = lt_faobj_sys
                it_swsodorgm       = gt_swsodorgm_local
                it_tcodes          = gt_tcodes_local
                it_functran_no_enh = gt_functran_no_enh_local
                ot_routput         = gt_func_routput
                ot_routput_sum     = gt_routput_summary
                et_mitigations     = gt_mitigations.


      LOOP AT gt_routput_summary.
        MOVE-CORRESPONDING gt_routput_summary TO gt_routput.
        APPEND gt_routput.
      ENDLOOP.
      ADD g_numroles TO g_trolecount.
    ENDIF.
  ELSEIF det EQ 'X'.
    IF bysimu = 'X' OR byrsimu = 'X'.
      lf_simu = 'X'.
    ENDIF.

    IF ronlyrem  NE 'X'.
      gt_rfcdest_anal-rfcoptions = g_rfcdes_local.
      gt_rfcdest_anal-rfcdest = g_rfcdes_local."'LOCAL'.
      APPEND gt_rfcdest_anal.
    ENDIF.


*    IF NOT ronlyrem = 'X'.
**--add local system to list of systems
*      CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest_anal-rfcoptions.
*      APPEND gt_rfcdest_anal.
*    ENDIF.
    LOOP AT gt_rfcdest_anal.
      MESSAGE s398(00) WITH  'Starting Remote Analysis on : '(109)
      gt_rfcdest_anal-rfcoptions.
      COMMIT WORK.
*--Filter Functions by system
      l_system = gt_rfcdest_anal-rfcoptions.
      lt_functtran_sys[] = gt_functtran_local[].
      lt_confdet_sys[]   = gt_confdet_local[].
*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_system.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_system.


      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = l_vrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
                it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      REFRESH :lt_rfcdest.
      lt_rfcdest-sign   = 'I'.
      lt_rfcdest-option = 'EQ'.
      lt_rfcdest-low =   gt_rfcdest_anal-rfcdest.
      APPEND lt_rfcdest.
      IF gt_rfcdest_anal-rfcoptions <> g_rfcdes_local.
        lf_remote = 'X'.
      ELSE.
        CLEAR lf_remote .
        REFRESH : lt_rfcdest.
      ENDIF.
      CALL FUNCTION '/PSYNG/FUNC_ROLE_DET_ANALYSIS'
           EXPORTING
                i_bysimu              = lf_simu
                i_orgchk              = orgchk
                i_sodvrsio            = sodvrsio
                i_config_set          = cfgset
                i_advanced_role_simu  = 'X'
                i_ronlyrem            = lf_remote
                i_enhanc              = p_enhanc
                i_hienhn              = p_hienhn
                i_rchdatt             = rchdatt
                i_rchdatf             = rchdatf
                i_composite_roles     = comprol
                i_single_roles        = singrol
                i_assigned_roles      = asign_r
           IMPORTING
                e_rolecount           = g_numroles
           TABLES
                it_roles              = role
                IT_ROLE_BA            = rba
                it_simurols           = simurols
                it_rfcdest            = lt_rfcdest
                it_orglvl             = orglvl
                et_outputdet          = gt_outputdet_temp
                it_conflict           = gt_conflict_local
                it_confdet            = lt_confdet_sys
                it_functtran          = lt_functtran_sys
                it_faobj              = lt_faobj_sys
                it_swsodorgm          = ls_ao_sys-swsodorgm[]
                it_simu_role_removal  = gt_roles_forrem_simulation
                it_simu_role_addition = gt_roles_foradd_simu.

      APPEND LINES OF gt_outputdet_temp TO gt_outputdet.
      REFRESH gt_outputdet_temp.
      LOOP AT gt_outputdet.
        MOVE-CORRESPONDING gt_outputdet TO gt_output_det.
        IF p_hienhn = 'X'.
          IF gt_output_det-enhanced = 'X'.
            DELETE gt_output_det-color_cell
                   WHERE fname = 'FUNCTIONID' OR fname = 'TCODE'.
            ls_color-col = '7'.   "Orange
            ls_color-int = '1'.   "Intensified
            ls_color-inv = '0'.   "Inverse
            ls_cc-color  = ls_color.
            ls_cc-fname  = 'FUNCTIONID'.
            APPEND ls_cc TO gt_output_det-color_cell.
            ls_cc-fname  = 'TCODE'.
            APPEND ls_cc TO gt_output_det-color_cell.
          ENDIF.
        ENDIF.
        APPEND gt_output_det.

      ENDLOOP.
    ENDLOOP.

*--Limit based on org level


    IF orgchk = 'X' AND NOT orglvl[] IS INITIAL.
      DATA: lt_outdet_temp LIKE TABLE OF gt_output_det
                                     WITH HEADER LINE,
            BEGIN OF lt_org_funcs OCCURS 0,
             agr_name LIKE lt_outdet_temp-agr_name,
             functionid LIKE lt_outdet_temp-functionid,
             org_abb LIKE lt_outdet_temp-org_abb,
            END OF lt_org_funcs.

      lt_outdet_temp[] = gt_output_det[].
      SORT lt_outdet_temp BY agr_name functionid org_abb.
      LOOP AT lt_outdet_temp WHERE org_abb IN orglvl.
        MOVE-CORRESPONDING lt_outdet_temp TO lt_org_funcs.
        APPEND lt_org_funcs.
      ENDLOOP.
      SORT lt_org_funcs BY agr_name functionid.
      LOOP AT gt_output_det.
        READ TABLE lt_org_funcs WITH KEY
          agr_name   = gt_output_det-agr_name
          functionid = gt_output_det-functionid
          BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc NE 0.
        DELETE gt_output_det.
      ENDLOOP.
    ENDIF.

  ENDIF.
  SORT gt_output_det.
  DELETE ADJACENT DUPLICATES FROM gt_output_det.
ENDFORM.                    " smm_data_processing

*&---------------------------------------------------------------------*
*&      Form  set_button_icons
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM set_button_icons.
  PERFORM init_but USING 'ROLE_BUT' 'X' CHANGING role_but .
  PERFORM init_but USING 'REM_BUT'  '' CHANGING rem_but  .
  PERFORM init_but USING 'FUN_BUT'  '' CHANGING fun_but  .
  PERFORM init_but USING 'SIMU_BUT' '' CHANGING simu_but .
  PERFORM init_but USING 'BGD_BUT'  '' CHANGING bgd_but  .
  PERFORM init_but USING 'EXE_BUT'  '' CHANGING exe_but  .
ENDFORM.                    " set_button_icons
*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1424   text
*      -->P_1425   text
*      <--P_ROLE_BUT  text
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
            name       = 'ICON_COLLAPSE'
            add_stdinf = ''
       IMPORTING
            result     = button
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
*      <--P_I_BUTTON  text
*----------------------------------------------------------------------*
FORM collapse CHANGING button.
  CALL FUNCTION 'ICON_CREATE'
       EXPORTING
            name       = 'ICON_EXPAND'
            add_stdinf = ''
       IMPORTING
            result     = button
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
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
     lr_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE,
     lr_rfcs_simu TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
LINE,
l_rfcdes_local TYPE rfcdes-rfcoptions.

  CLEAR gf_invalid_rfc.

  lr_rfcs-sign   = 'I'.
  lr_rfcs-option = 'EQ'.
*--Role Simulation Destinations
  IF bysimu = 'X'.
    lr_rfcs-low = ar_rfcd1.
    APPEND lr_rfcs.
    lr_rfcs-low    = ar_rfcd2.
    APPEND lr_rfcs.
    lr_rfcs-low   = ar_rfcd3.
    APPEND lr_rfcs.
    lr_rfcs-low    = ar_rfcd4.
    APPEND lr_rfcs.
    lr_rfcs-low    = ar_rfcs1.
    APPEND lr_rfcs.
    lr_rfcs-low    = ar_rfcs2.
    APPEND lr_rfcs.
    lr_rfcs-low    = ar_rfcs3.
    APPEND lr_rfcs.
    lr_rfcs-low   = ar_rfcs4.
    APPEND lr_rfcs.
  ENDIF.
*--Role Removal  Simulation Destinations
  IF byrsimu = 'X'.
    lr_rfcs-low    = rr_rfc_1.
    APPEND lr_rfcs.
    lr_rfcs-low    = rr_rfc_2.
    APPEND lr_rfcs.
    lr_rfcs-low    = rr_rfc_3.
    APPEND lr_rfcs.
    lr_rfcs-low    = rr_rfc_4.
    APPEND lr_rfcs.
  ENDIF.

  lr_rfcs_simu[] = lr_rfcs[].
  APPEND LINES OF remrfc TO lr_rfcs.

  CLEAR l_continue.
  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup    = 'X'
            i_module   = 'SE'
       IMPORTING
            e_continue = l_continue
       TABLES
            it_rfcdes  = lr_rfcs.
  IF l_continue <> 'X'.
    gf_invalid_rfc = 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest,gt_rfcdest_anal.
  PERFORM load_role_rfc
             TABLES
                lr_rfcs_simu
                gt_rfcdest.

  PERFORM load_role_rfc
             TABLES
                remrfc
               gt_rfcdest_anal.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc
TABLES
  it_role_rfc      STRUCTURE /psyng/sw_sel_opts_rfcdest
  et_rfcdes        STRUCTURE rfcdes.

  DATA :
  l_rfcdest        TYPE rfcdes-rfcdest,
  l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc
             AND rfctype = '3'.
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
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3."#EC SAST_CI_GEN_CHECK
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
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.
ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  output_using_alv_sum
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv_sum.
  DATA:
    l_wa_fieldcat_alv TYPE slis_fieldcat_alv,
    l_fieldcat_alv    TYPE slis_t_fieldcat_alv,
    l_alv_layout      TYPE slis_layout_alv,
    l_alv_grid_titl   TYPE lvc_title,
    lt_sort           TYPE STANDARD TABLE OF slis_sortinfo_alv,
    ls_variant        TYPE disvariant.

  g_program = sy-repid.
  MOVE 'COLOR_CELL' TO l_alv_layout-coltab_fieldname.
*--Create fieldcatalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTPUT_SMM'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = l_fieldcat_alv
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
*--Modify field catalog
  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-184.
  l_wa_fieldcat_alv-seltext_m      = text-184.
  l_wa_fieldcat_alv-seltext_s      = text-184.
  l_wa_fieldcat_alv-reptext_ddic   = text-184.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'AGR_NAME'.
  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-185.
  l_wa_fieldcat_alv-seltext_m      = text-185.
  l_wa_fieldcat_alv-seltext_s      = text-185.
  l_wa_fieldcat_alv-reptext_ddic   = text-185.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'AGR_TEXT'.

  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-186.
  l_wa_fieldcat_alv-seltext_m      = text-186.
  l_wa_fieldcat_alv-seltext_s      = text-186.
  l_wa_fieldcat_alv-reptext_ddic   = text-186.
  l_wa_fieldcat_alv-hotspot = 'X'.
  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        hotspot
                     WHERE
                        fieldname = 'FUNCTIONID'.

  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-187.
  l_wa_fieldcat_alv-seltext_m      = text-187.
  l_wa_fieldcat_alv-seltext_s      = text-187.
  l_wa_fieldcat_alv-reptext_ddic   = text-187.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'FDESCRIPTION'.

  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-188.
  l_wa_fieldcat_alv-seltext_m      = text-188.
  l_wa_fieldcat_alv-seltext_s      = text-188.
  l_wa_fieldcat_alv-reptext_ddic   = text-188.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'OWNER'.
  CLEAR l_wa_fieldcat_alv.
  l_wa_fieldcat_alv-seltext_l      = text-189.
  l_wa_fieldcat_alv-seltext_m      = text-189.
  l_wa_fieldcat_alv-seltext_s      = text-189.
  l_wa_fieldcat_alv-reptext_ddic   = text-189.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'BUSAREA'.

  CLEAR l_wa_fieldcat_alv.
  IF bysimu <> 'X' AND byrsimu <> 'X'.
    l_wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR l_wa_fieldcat_alv-no_out.
  ENDIF.

  l_wa_fieldcat_alv-seltext_l      = 'Simu.'(193).
  l_wa_fieldcat_alv-seltext_m      = 'Simu.'(193).
  l_wa_fieldcat_alv-seltext_s      = 'Simu.'(193).
  l_wa_fieldcat_alv-checkbox = 'X'.
  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'SIMU'.

  l_wa_fieldcat_alv-seltext_l      = 'Before Simulation'(191).
  l_wa_fieldcat_alv-seltext_m      = 'Before Simulation'(191).
  l_wa_fieldcat_alv-seltext_s      = 'Before Simulation'(191).
  l_wa_fieldcat_alv-checkbox = 'X'.
  l_wa_fieldcat_alv-hotspot        = 'X' .
  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                      hotspot
                   WHERE
                      fieldname = 'SIMU_BEFORE'.

  l_wa_fieldcat_alv-seltext_l      = 'After Simulation'(192).
  l_wa_fieldcat_alv-seltext_m      = 'After Simulation'(192).
  l_wa_fieldcat_alv-seltext_s      = 'After Simulation'(192).
  l_wa_fieldcat_alv-hotspot        = 'X' .
  l_wa_fieldcat_alv-checkbox = 'X'.
  l_wa_fieldcat_alv-hotspot        = 'X' .
  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                      hotspot
                   WHERE
                      fieldname = 'SIMU_AFTER'.

  IF NOT remrfc[] IS INITIAL.
    CLEAR l_wa_fieldcat_alv-no_out  .
  ELSE.
    l_wa_fieldcat_alv-no_out     = 'X'.
  ENDIF.
  l_wa_fieldcat_alv-seltext_l = 'System - Client'(073).
  l_wa_fieldcat_alv-seltext_m = text-073.
  l_wa_fieldcat_alv-seltext_s = 'Sys-Cli'(072).
  l_wa_fieldcat_alv-reptext_ddic = text-073.
  l_wa_fieldcat_alv-checkbox     = ''.
  l_wa_fieldcat_alv-just         = 'X'.
  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      just
                      no_out
                   WHERE
                      fieldname = 'RFCDEST'.
  CLEAR l_wa_fieldcat_alv.
  IF p_enhanc = 'X'.
    CLEAR l_wa_fieldcat_alv-no_out  .
  ELSE.
    l_wa_fieldcat_alv-no_out     = 'X'.
  ENDIF.

  l_wa_fieldcat_alv-seltext_l      = text-079.
  l_wa_fieldcat_alv-seltext_m      = text-079.
  l_wa_fieldcat_alv-seltext_s      = text-079.
  l_wa_fieldcat_alv-reptext_ddic   = text-079.
  l_wa_fieldcat_alv-checkbox = 'X'.

  MODIFY l_fieldcat_alv FROM l_wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        no_out
                     WHERE
                        fieldname = 'ENHANCED'.

*--Create Sort Table
  DATA: l_sort TYPE slis_sortinfo_alv.
  l_sort-spos = '1'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FDESCRIPTION'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname =  'GT_OUTPUT_SMM'.
  l_sort-up = 'X'.
  APPEND l_sort TO lt_sort.

  IF  bysimu EQ 'X' OR byrsimu EQ 'X'.
    ADD 1 TO l_sort-spos.
    l_sort-fieldname = 'SIMU'.
    l_sort-tabname =  'GT_OUTPUT_SMM'.
    l_sort-up = 'X'.
    APPEND l_sort TO lt_sort.
  ENDIF.
*--Prepare layout
  CONCATENATE sy-title text-093 sodvrsio
              INTO sy-title SEPARATED BY space.
  l_alv_layout-zebra = 'X'.
  l_alv_layout-colwidth_optimize = 'X'.
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page  = 'ROLE_TOP_OF_PAGE'
            i_grid_title            = sy-title
            i_callback_program      = g_program
            it_sort                 = lt_sort
            i_callback_user_command = 'ROLE_DOUBLE_CLICK_ON_SUMRY'
            is_layout               = l_alv_layout
            it_fieldcat             = l_fieldcat_alv
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = gt_output_smm
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_using_alv_sum




*---------------------------------------------------------------------*
*       FORM ROLE_DOUBLE_CLICK_ON_SUMRY                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM role_double_click_on_sumry
 USING r_ucomm     LIKE sy-ucomm
       is_selfield TYPE slis_selfield.
  DATA :
       l_rsimu     TYPE flag.

  CASE is_selfield-fieldname.
    WHEN 'FUNCTIONID'.
      READ TABLE gt_output_smm INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF gt_output_smm-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
             'This function doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      PERFORM function_detail_analysis USING is_selfield-fieldname.
    WHEN 'SIMU_AFTER'.
      READ TABLE gt_output_smm INDEX is_selfield-tabindex.
      IF gt_output_smm-simu_after <> 'X'.
        MESSAGE i002(/psyng/sw) WITH
         'This function doesn''t exist after the change.'(m10)
         'Click the ''Before'' checkbox to view'(m11).
        EXIT.
      ELSE.
        READ TABLE gt_output_smm INDEX is_selfield-tabindex.
        CHECK sy-subrc = 0.
        PERFORM function_detail_analysis USING is_selfield-fieldname.
        EXIT.
      ENDIF.
    WHEN 'SIMU_BEFORE'.
      READ TABLE gt_output_smm INDEX is_selfield-tabindex.
      IF gt_output_smm-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This function didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE gt_output_smm INDEX is_selfield-tabindex.
        CHECK sy-subrc = 0.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.
        PERFORM function_detail_analysis USING is_selfield-fieldname.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.
        EXIT.
      ENDIF.
  ENDCASE.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM ROLE_TOP_OF_PAGE                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM role_top_of_page.
  DATA:   l_header            TYPE slis_t_listheader,
          l_wa                TYPE slis_listheader,
          l_exedate           TYPE char10,
          l_exetime(8)        TYPE c,
          l_rolecount         TYPE i,
          l_rolecountc(6)     TYPE c,
          l_functioncountc(6) TYPE c,
          l_averagefunc(4)    TYPE c,
          l_trolecountc(4)    TYPE c,
          l_alv_grid_titl2    TYPE lvc_title,
          lt_output_temp      LIKE TABLE OF gt_output_smm
                              WITH HEADER LINE,
          lt_rolecount        LIKE TABLE OF gt_output_smm
                              WITH HEADER LINE,
          ls_cfg_set          TYPE /psyng/swcfgset,
          l_str               TYPE string,
          l_int               TYPE i,
          l_concount_bs    type i, "before simulation
          lstat_functioncount  TYPE i,
          c_totalcon       type string,
          c_beforesimucon  type string,
          l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

  STATICS :
         lstat_msg_displayed  TYPE flag,
         lstat_totals_counted TYPE flag,
         lstat_oldagr_name    LIKE agr_define-agr_name,
         lstat_oldrfc         TYPE rfcdest,
         lstat_averagefun     TYPE i,
         lstat_rolecount      TYPE i.

  lstat_rolecount = g_trolecount."l_numroles.
  field-symbols : <row> like gt_output_smm.
  loop at gt_output_smm assigning <row>.
    IF bysimu = 'X' OR byrsimu = 'X'.
      IF <row>-simu_after = 'X'.
        lstat_functioncount = lstat_functioncount + 1.
      ENDIF.
      IF <row>-simu_before = 'X'.
        l_concount_bs = l_concount_bs + 1.
      ENDIF.
    ELSE.
      lstat_functioncount = lstat_functioncount + 1.
    ENDIF.
  endloop.
  lt_output_temp[] = gt_output_smm[].
*  SORT lt_output_temp BY agr_name rfcdest functionid.
*  DELETE ADJACENT DUPLICATES FROM lt_output_temp
*  COMPARING rfcdest agr_name functionid.
*  DESCRIBE TABLE lt_output_temp LINES lstat_functioncount .



  FREE  : lt_output_temp.
  lt_rolecount[] = gt_output_smm[].
  SORT lt_rolecount BY rfcdest agr_name.
  DELETE ADJACENT DUPLICATES FROM lt_rolecount
  COMPARING rfcdest agr_name.
  DESCRIBE TABLE lt_rolecount LINES l_rolecount.
  FREE : lt_rolecount.
  lstat_averagefun = lstat_functioncount  / l_rolecount.
  l_rolecountc     = lstat_rolecount.
  l_functioncountc = lstat_functioncount.
  l_averagefunc    = lstat_averagefun.
  l_trolecountc    = l_rolecount.
  c_totalcon      = lstat_functioncount.
  c_beforesimucon = l_concount_bs.


*TITLE AREA
  IF det NE 'X'.
    l_wa-typ =  'H'.
    l_wa-info = 'Function Role Analysis Results Summary'(h01).
    APPEND l_wa TO l_header.
  ELSE.
    l_wa-typ =  'H'.
    l_wa-info = 'Function Role Analysis Results Details'(h09).
    APPEND l_wa TO l_header.
  ENDIF.
*Version
  l_wa-typ  = 'S'.
  l_wa-key  = 'SOD version:'(h02).
  SELECT SINGLE vdesc INTO l_wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  l_wa-info INTO l_wa-info SEPARATED BY
space.
  APPEND l_wa TO l_header.

*--Configuration Set
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid = cfgset.
    l_wa-typ  = 'S'.
    l_wa-key  = 'Configuration Set:'(h32).
    l_int = cfgset.
    l_str = l_int.
    CONDENSE l_str.
    CONCATENATE l_str ' : '
    ls_cfg_set-description INTO l_wa-info SEPARATED BY space.
    APPEND l_wa TO l_header.
    l_wa-key  = 'Config Set Published:'(h33).
    IF ls_cfg_set-published = 'X'.
      l_wa-info = 'Yes'(h34).
    ELSE.
      l_wa-info = 'No'(h35).
    ENDIF.
    APPEND l_wa TO l_header.
    l_wa-key  = 'Config Set Changed :'(h36).
    WRITE ls_cfg_set-change_date TO l_wa-info.
    CONCATENATE l_wa-info 'by'(h37) ls_cfg_set-change_user
    INTO l_wa-info SEPARATED BY space.
    APPEND l_wa TO l_header.
  ENDIF.
*Date
  l_wa-typ = 'S'.
  l_wa-key = 'User Date & System:'(h08).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
     CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
  CONCATENATE g_current_user "sy-uname C0700
   text-h11 l_exedate l_exetime text-h50 l_systemid
              INTO l_wa-info SEPARATED BY space.
  APPEND l_wa TO l_header.
*--Averages info
  CONCATENATE  l_rolecountc 'Role(s) analyzed.'(h03)
               'Avg'(h04)
               l_averagefunc
               'Function(s) in'(h05)
               l_trolecountc
               'Role(s).'(h06)
              INTO l_alv_grid_titl2 SEPARATED BY space.
  CONDENSE l_alv_grid_titl2.
  l_wa-typ = 'S'.
  l_wa-key = 'Summary'(h07).
  l_wa-info = l_alv_grid_titl2.
  APPEND l_wa TO l_header.

*  CLEAR: l_rolecount.
*  lt_rolecount[] = gt_output_smm[].
*  SORT lt_rolecount BY agr_name.
*  DELETE ADJACENT DUPLICATES FROM lt_rolecount COMPARING agr_name.
*  DESCRIBE TABLE lt_rolecount LINES l_rolecount.
*  lstat_averagefun = lstat_functioncount  / l_rolecount.
*  l_rolecountc = l_rolecount.
*  l_functioncountc = lstat_functioncount.
*  l_averagefunc = lstat_averagefun.
*  l_trolecountc = l_rolecount.

**--Averages info
*  CONCATENATE  l_rolecountc 'Role(s) analyzed.'(h03)
*               'Avg'(h04)
*               l_averagefunc
*               'Function(s) in'(h05)
*               l_trolecountc
*               'Role(s).'(h06)
*              INTO l_alv_grid_titl2 SEPARATED BY space.
*  CONDENSE l_alv_grid_titl2.
*  l_wa-typ = 'S'.
*  l_wa-key = 'Global Summary'(h12).
*  l_wa-info = l_alv_grid_titl2.
*  APPEND l_wa TO l_header.

  IF bysimu = 'X' OR byrsimu = 'X'.
*--Before Simulation Numbers
    l_wa-typ  = 'S'.
    l_wa-key  = 'Before simulation'(h38).
    concatenate c_beforesimucon 'Functions'(h40)
    into l_wa-info separated by space .
    APPEND l_wa TO l_header.
*--After Simulation Numbers
    l_wa-typ  = 'S'.
    l_wa-key  = 'After simulation'(h39).
    concatenate c_totalcon 'Functions'(h40)
    into l_wa-info separated by space .
    APPEND l_wa TO l_header.
  endif.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = l_header
            i_logo             = 'Z_3SW_LOGO_JPG'.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  output_using_alv_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv_det.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,
        alv_layout      TYPE slis_layout_alv,
        alv_grid_titl   TYPE lvc_title,
        isort           TYPE STANDARD TABLE OF slis_sortinfo_alv,
        ls_variant      TYPE disvariant.
  g_program = sy-repid.
*--Create fieldcatalog
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTPUT_DET'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
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

*--Modify field catalog

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-040.
  wa_fieldcat_alv-seltext_m      = text-040.
  wa_fieldcat_alv-seltext_s      = text-040.
  wa_fieldcat_alv-reptext_ddic   = text-040.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'AGR_NAME'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-041.
  wa_fieldcat_alv-seltext_m      = text-041.
  wa_fieldcat_alv-seltext_s      = text-041.
  wa_fieldcat_alv-reptext_ddic   = text-041.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'FUNCTIONID'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-073.
  wa_fieldcat_alv-seltext_m      = text-072.
  wa_fieldcat_alv-seltext_s      = text-072.
  wa_fieldcat_alv-reptext_ddic   = text-072.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                    WHERE
                       fieldname = 'RFCDEST'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-052.
  wa_fieldcat_alv-seltext_m      = text-053.
  wa_fieldcat_alv-seltext_s      = text-053.
  wa_fieldcat_alv-reptext_ddic   = text-053.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                       hotspot
                    WHERE
                       fieldname = 'TCODE'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-044.
  wa_fieldcat_alv-seltext_m      = text-045.
  wa_fieldcat_alv-seltext_s      = text-045.
  wa_fieldcat_alv-reptext_ddic   = text-045.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                       TRANSPORTING
                         seltext_l
                         seltext_m
                         seltext_s
                         reptext_ddic
                         hotspot
                      WHERE
                         fieldname = 'OBJCT'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-046.
  wa_fieldcat_alv-seltext_m      = text-046.
  wa_fieldcat_alv-seltext_s      = text-046.
  wa_fieldcat_alv-reptext_ddic   = text-046.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        hotspot
                     WHERE
                        fieldname = 'AUTH'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-047.
  wa_fieldcat_alv-seltext_m      = text-047.
  wa_fieldcat_alv-seltext_s      = text-047.
  wa_fieldcat_alv-reptext_ddic   = text-047.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                       hotspot
                    WHERE
                       fieldname = 'FIELD'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-048.
  wa_fieldcat_alv-seltext_m      = text-048.
  wa_fieldcat_alv-seltext_s      = text-048.
  wa_fieldcat_alv-reptext_ddic   = text-048.
  wa_fieldcat_alv-fieldname = 'VON'.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'VON'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-049.
  wa_fieldcat_alv-seltext_m      = text-049.
  wa_fieldcat_alv-seltext_s      = text-049.
  wa_fieldcat_alv-reptext_ddic   = text-049.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                       TRANSPORTING
                         seltext_l
                         seltext_m
                         seltext_s
                         reptext_ddic
                         hotspot
                      WHERE
                         fieldname = 'BIS'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-050.
  wa_fieldcat_alv-seltext_m      = text-050.
  wa_fieldcat_alv-seltext_s      = text-050.
  wa_fieldcat_alv-reptext_ddic   = text-050.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                       hotspot
                    WHERE
                       fieldname = 'CHILD_AGR'.

  CLEAR wa_fieldcat_alv.
  IF bysimu <> 'X' AND byrsimu <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.

  wa_fieldcat_alv-seltext_l      = 'Simu.'(193).
  wa_fieldcat_alv-seltext_m      = 'Simu.'(193).
  wa_fieldcat_alv-seltext_s      = 'Simu.'(193).
  wa_fieldcat_alv-checkbox = 'X'.

  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'SIMU'.

  CLEAR wa_fieldcat_alv.
  IF p_enhanc = 'X'.
    CLEAR wa_fieldcat_alv-no_out  .
  ELSE.
    wa_fieldcat_alv-no_out     = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-079.
  wa_fieldcat_alv-seltext_m      = text-079.
  wa_fieldcat_alv-seltext_s      = text-079.
  wa_fieldcat_alv-reptext_ddic   = text-079.
  wa_fieldcat_alv-checkbox       = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      checkbox
                      no_out
                   WHERE
                      fieldname = 'ENHANCED'.

*--Create Sort Table
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OBJCT'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
*
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AUTH'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELD'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VON'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BIS'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CHILD_AGR'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SIMU'.
  l_sort-tabname =  'GT_OUTPUT_DET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
**----Prepare Layout
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title            = sy-title
            i_callback_program      = g_program
            it_sort                 = isort
            i_callback_user_command = 'ROLE_DOUBLE_CLICK_ON_DETL'
            is_layout               = alv_layout
            it_fieldcat             = i_fieldcat_alv
            i_save                  = 'A'
       TABLES
            t_outtab                = gt_output_det
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_using_alv_det
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
    IF  NOT rchdatf IS INITIAL.
      IF rchdatt IS INITIAL .
        rchdatt = '99991231'.
      ENDIF.

    ENDIF.
  ENDIF.

  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    EXIT.
  ENDIF.

  IF NOT rchdatt IS INITIAL AND rchdatf > rchdatt.
    SET CURSOR FIELD 'RCHDATT'.
    MESSAGE e650(db).
  ENDIF.

  IF comprol IS INITIAL AND singrol IS INITIAL.
    IF sy-batch IS INITIAL.
      MESSAGE e208(00) WITH
      'Select either Composite or Single Roles or both'(163).
    ELSE.
      MESSAGE s208(00) WITH
      'Analyzing Composite and Single Roles'(164).
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'SCJB'.
    g_exit_proc = 'Y'.
    PERFORM schedule_back_job.
  ENDIF.
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.

  IF byrsimu = 'X' AND ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' )
"#EC SAST_CI_GEN_CHECK (HBHALLA)
    AND
      rr_rol_1[] IS INITIAL AND
      rr_rol_2[] IS INITIAL AND
      rr_rol_3[] IS INITIAL AND
      rr_rol_4[] IS INITIAL.
    MESSAGE w140 WITH
    'Please enter role(s) for simulation'(181).
  ENDIF.

  IF bysimu = 'X' AND ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' )
"#EC SAST_CI_GEN_CHECK (HBHALLA)
  AND
    ar_rol_1[] IS INITIAL AND
    ar_rol_2[] IS INITIAL AND
    ar_rol_3[] IS INITIAL AND
    ar_rol_4[] IS INITIAL.
    MESSAGE w140 WITH
    'Please enter role(s) for simulation'(181).
  ENDIF.

ENDFORM.                    " check_input
*&---------------------------------------------------------------------*
*&      Form  get_roles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count.
  DATA : lt_roles     TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_assnroles TYPE TABLE OF agr_users WITH HEADER LINE,
         l_numb       TYPE i,
         l_total_num  TYPE i.
  RANGES: idatseltab  FOR sy-datum.
  PERFORM rfc_validations.
  CHECK gf_invalid_rfc  IS INITIAL.
  if ronlyrem is initial.
*--Local Roles
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
            it_roles          = role
            it_ba             = rba.

  ADD l_numb TO l_total_num.
  endif.
*--Remote Roles
  LOOP AT gt_rfcdest_anal.
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
    DESTINATION gt_rfcdest_anal-rfcdest
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = role
              it_ba             = rba. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ADD l_numb TO l_total_num.
  ENDLOOP.

  MESSAGE i002 WITH 'Number of roles(s) will be analyzed : '(r01)
  l_total_num.

ENDFORM.                    " get_roles_count
*&---------------------------------------------------------------------*
*&      Form  show_roles_based_on_dates
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_roles_based_on_dates.

  DATA: lt_agr_define     LIKE agr_define OCCURS 0 WITH HEADER LINE,
        lt_ifield_dif     LIKE field_dif OCCURS 0 WITH HEADER LINE,
        l_header(80),
        l_count           TYPE i,
        l_count_char(9),
        l_wa_iagr_define  TYPE agr_define.

  DATA: lt_roles TYPE TABLE OF /psyng/comp_role_tcode,
        ls_roles TYPE /psyng/comp_role_tcode,
        lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_range_roles TYPE /psyng/range_agr_name.

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH text-070.
    EXIT.
  ENDIF.
  REFRESH lt_agr_define.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = asign_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
              i_get_actual_data = 'X'
         TABLES
              it_roles          = role
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
             INTO CORRESPONDING FIELDS OF l_wa_iagr_define
             FROM agr_define
             WHERE agr_name IN lt_range_roles.
    IF rchdatf IS INITIAL.
      INSERT l_wa_iagr_define INTO TABLE lt_agr_define.
    ELSE.
      IF l_wa_iagr_define-change_dat IS INITIAL.
        CHECK l_wa_iagr_define-create_dat >= rchdatf AND
              l_wa_iagr_define-create_dat <= rchdatt.
        INSERT l_wa_iagr_define INTO TABLE lt_agr_define.
      ELSE.
        CHECK l_wa_iagr_define-change_dat >= rchdatf AND
              l_wa_iagr_define-change_dat <= rchdatt.
        INSERT l_wa_iagr_define INTO TABLE lt_agr_define.
      ENDIF.
    ENDIF.
  ENDSELECT.
  ENDIF.

  IF NOT lt_agr_define[] IS INITIAL.
  lt_ifield_dif-tabname = 'AGR_DEFINE'.
  lt_ifield_dif-fieldname = 'PARENT_AGR'.
  lt_ifield_dif-no_display = 'X'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'CREATE_USR'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'CREATE_DAT'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'CREATE_TIM'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'CREATE_TMP'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'CHANGE_TMP'.
  APPEND lt_ifield_dif.
  lt_ifield_dif-fieldname = 'ATTRIBUTES'.
  APPEND lt_ifield_dif.

  DESCRIBE TABLE lt_agr_define LINES l_count.
  MOVE l_count TO l_count_char.
  CONCATENATE l_count_char text-134 INTO l_header
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
       EXPORTING
            header         = l_header
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
            table          = lt_agr_define
            fielddif       = lt_ifield_dif
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
  ENDIF.
  ELSE.
    MESSAGE i002 WITH 'No valid roles found'(n03).
    EXIT.
  ENDIF.

ENDFORM.                    " show_roles_based_on_dates
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
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
*&---------------------------------------------------------------------*
*&      Form  function_detail_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM function_detail_analysis
USING   callfield  TYPE slis_selfield-fieldname.
  DATA: iseltab    TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  CHECK NOT gt_output_smm-functionid = '----'.
  REFRESH : iseltab[].
  CLEAR iseltab.

  CLEAR gt_functions.
  READ TABLE gt_functions WITH KEY function = gt_output_smm-functionid.

  iseltab-selname = 'ROLE'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gt_output_smm-agr_name.
  APPEND iseltab.

  iseltab-selname = 'RCHDATF'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = rchdatf.
  APPEND iseltab.

  iseltab-selname = 'RCHDATT'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = rchdatt.
  APPEND iseltab.

  iseltab-selname = 'SINGROL'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = singrol.
  APPEND iseltab.

  iseltab-selname = 'COMPROL'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = comprol.
  APPEND iseltab.

  iseltab-selname = 'ASIGN_R'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = asign_r.
  APPEND iseltab.

  DATA rfcdest TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO rfcdest.


  IF gt_output_smm-rfcdest <> rfcdest.
    READ TABLE gt_rfcdest_anal WITH KEY
    rfcoptions = gt_output_smm-rfcdest.
    IF sy-subrc = 0.

      iseltab-selname = 'REMRFC'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = gt_rfcdest_anal-rfcdest.
      APPEND iseltab.

      iseltab-selname = 'RONLYREM'.  "only remote (hidden parameter)
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = 'X'.
      APPEND iseltab.
    ENDIF.
  ELSE.
    iseltab-selname = 'RONLYREM'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = ronlyrem.
    APPEND iseltab.
  ENDIF.




  iseltab-selname = 'SPFUN'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gt_output_smm-functionid.
  APPEND iseltab.

  IF NOT gt_output_smm-org_abb IS INITIAL.
    iseltab-selname = 'ORGLVL'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = gt_output_smm-org_abb.
    APPEND iseltab.
  ENDIF.

  iseltab-selname = 'BUSAREA'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  IF NOT gt_functions-busarea IS INITIAL.
    iseltab-low     = gt_functions-busarea.
  ELSE.
    iseltab-low     = busarea-low.
  ENDIF.
  APPEND iseltab.

  iseltab-selname = 'OWNER'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  IF NOT gt_functions-owner IS INITIAL.
    iseltab-low     = gt_functions-owner.
  ELSE.
    iseltab-low     = owner-low.
  ENDIF.
  APPEND iseltab.

  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sodvrsio.
  APPEND iseltab.

  iseltab-selname = 'ORGCHK'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = orgchk.
  APPEND iseltab.


  iseltab-selname = 'SUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.

  iseltab-selname = 'DET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  CLEAR iseltab.
  iseltab-selname = 'P_ENHANC'.
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

  CLEAR iseltab.
  iseltab-selname = 'CFGSET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = cfgset.
  APPEND iseltab.


*--Role addition Simulation

  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.

  iseltab-selname = 'BYSIMU'.
  iseltab-low     = bysimu.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCS1'.
  iseltab-low     =  ar_rfcs1.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD1'.
  iseltab-low     =  ar_rfcd1.
  APPEND iseltab.


  LOOP AT ar_rol_1.
    iseltab-selname = 'AR_ROL_1'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_1 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'AR_RFCS2'.
  iseltab-low     =  ar_rfcs2.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD2'.
  iseltab-low     =  ar_rfcd2.
  APPEND iseltab.

  LOOP AT ar_rol_2.
    iseltab-selname = 'AR_ROL_2'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_2 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'AR_RFCS3'.
  iseltab-low     =  ar_rfcs3.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD3'.
  iseltab-low     =  ar_rfcd3.
  APPEND iseltab.

  LOOP AT ar_rol_3.
    iseltab-selname = 'AR_ROL_3'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_3 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  iseltab-selname = 'AR_RFCS4'.
  iseltab-low     =  ar_rfcs4.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD4'.
  iseltab-low     =  ar_rfcd4.
  APPEND iseltab.
  LOOP AT ar_rol_4.
    iseltab-selname = 'AR_ROL_4'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_4 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  IF callfield NE 'SIMU_BEFORE'.
*--Role Removal Simulation
    iseltab-selname = 'BYRSIMU'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = byrsimu.
    APPEND iseltab.

    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.

    iseltab-selname = 'RR_RFC_1'.
    iseltab-low     =  rr_rfc_1.
    APPEND iseltab.

    iseltab-selname = 'RR_RFC_2'.
    iseltab-low     =  rr_rfc_2.
    APPEND iseltab.

    iseltab-selname = 'RR_RFC_3'.
    iseltab-low     =  rr_rfc_3.
    APPEND iseltab.

    iseltab-selname = 'RR_RFC_4'.
    iseltab-low     =  rr_rfc_4.
    APPEND iseltab.

    LOOP AT rr_rol_1.
      iseltab-selname = 'RR_ROL_1'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING rr_rol_1 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT rr_rol_2.
      iseltab-selname = 'RR_ROL_2'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING rr_rol_2 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT rr_rol_3.
      iseltab-selname = 'RR_ROL_3'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING rr_rol_3 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
    LOOP AT rr_rol_4.
      iseltab-selname = 'RR_ROL_4'.
      iseltab-kind    = 'S'.
      MOVE-CORRESPONDING rr_rol_4 TO iseltab.
      APPEND iseltab.
    ENDLOOP.
  ENDIF.
  CLEAR iseltab.
  iseltab-selname = 'P_CALDET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  g_program = sy-repid.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_129
*EOC UMITTAL SE VF scan changes-25/11/2024
  WITH SELECTION-TABLE iseltab AND RETURN. "#EC PATHLOCK_CI_DYN_ACCES


ENDFORM.                    " function_detail_analysis

*---------------------------------------------------------------------*
*       FORM ROLE_DOUBLE_CLICK_ON_DETL                                *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM role_double_click_on_detl
  USING r_ucomm       LIKE sy-ucomm
        is_selfield   TYPE slis_selfield.
  DATA:
        lt_functionid TYPE slis_selfield-value,
        lt_iseltab    TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
        lt_tcodes     TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE,
        l_wa_tcodes   LIKE /psyng/range_tcode,
        l_risktext    LIKE /psyng/sw_risk-text,
        l_repid       LIKE sy-repid,
        l_sod         TYPE /psyng/swsodvers-vrsio,
        l_fioriid     TYPE /psyng/sw_fioriid,
        l_hashcode    TYPE xupname,
        l_uname       LIKE sy-uname,
        l_parva       TYPE usr05-parva,
        l_agr_name    LIKE agr_define-agr_name,
        l_line(80),
        l_answer,
        l_authfield   LIKE authx-fieldname,
        l_iobjct      LIKE tobj-objct,
        l_conid       TYPE /psyng/conflict_id.


  CASE is_selfield-fieldname.

    WHEN 'AGR_NAME' OR 'CHILD_AGR'.
      CHECK is_selfield-value <> space.
      READ TABLE gt_output_det INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_agr_name = is_selfield-value.

      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
           EXPORTING
                defaultoption     = '1'
                diagnosetext1     = l_agr_name
                diagnosetext2     = text-057
                diagnosetext3     = text-058
                textline1         = text-059
                text_option1      = text-060
                text_option2      = text-061
                icon_text_option1 = 'ICON_DISPLAY'
                icon_text_option2 = 'ICON_CHECK'
                titel             = text-062
                cancel_display    = 'X'
           IMPORTING
                answer            = l_answer.

      CASE l_answer.
        WHEN '1'.
          PERFORM display_role_in_pfcg USING l_agr_name.
        WHEN '2'.
          PERFORM role_sod_analysis_from_details USING l_agr_name.

      ENDCASE.

    WHEN 'FUNCTIONID'.
      CHECK is_selfield-value <> space.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_OBJECT'
        EXPORTING
          i_objecttype       = 'FUNCTIONID'
          i_objectid         = is_selfield-value
          i_vrsio            = sodvrsio.

    WHEN 'TCODE'.
      READ TABLE gt_output_det INDEX is_selfield-tabindex.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
         i_tcode           = gt_output_det-tcode "is_selfield-value
         I_VRSIO           = sodvrsio
         I_FUNID           = gt_output_det-functionid.

    WHEN 'OBJCT'.
      CHECK is_selfield-value <> space.
      READ TABLE gt_output_det INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_iobjct = is_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
           EXPORTING
                object  = l_iobjct
                eu_mode = ' '.

    WHEN 'VON'.
      CHECK is_selfield-value <> space.
      READ TABLE gt_output_det INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  gt_output_det-objct EQ  gc_service
      AND gt_output_det-field  EQ gc_srv_name.
        l_hashcode = gt_output_det-von.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode           = l_hashcode
           if_show_message       = 'X'
         EXCEPTIONS
           not_found             = 1
           OTHERS                = 2.
        IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
           EXPORTING
                fieldname       = gt_output_det-field
                object          = gt_output_det-objct
           EXCEPTIONS
                field_not_found = 1
                OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'BIS'.
      CHECK is_selfield-value <> space.
      READ TABLE gt_output_det INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  gt_output_det-objct EQ  gc_service
      AND gt_output_det-field  EQ gc_srv_name.
        l_hashcode = gt_output_det-bis.
*--Displays a popup with the name of the Odata Service
        CALL FUNCTION '/PSYNG/SW_ODATA_TEXT'
          EXPORTING
            i_hashcode           = l_hashcode
           if_show_message       = 'X'
         EXCEPTIONS
           not_found             = 1
           OTHERS                = 2.
        IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        RETURN.
      ENDIF.
      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
           EXPORTING
                fieldname       = gt_output_det-field
                object          = gt_output_det-objct
           EXCEPTIONS
                field_not_found = 1
                OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

    WHEN 'FIELD'.
      CHECK is_selfield-value <> space.
      l_authfield = is_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
           EXPORTING
                fieldname = l_authfield.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  display_role_in_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AGR_NAME  text
*----------------------------------------------------------------------*
FORM display_role_in_pfcg USING agr_name LIKE agr_define-agr_name.

  DATA: l_answer,
        l_pertext(200),
        l_repid        LIKE sy-repid,
        lt_fields      TYPE STANDARD TABLE OF sval WITH HEADER LINE.


  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
       EXPORTING
            defaultoption     = '1'
            diagnosetext1     = text-147
            diagnosetext2     = text-064
            diagnosetext3     = text-130
            textline1         = text-074
            text_option1      = text-131
            text_option2      = text-132
            icon_text_option1 = 'ICON_INCOMING_TASK'
            icon_text_option2 = 'ICON_OUTGOING_TASK'
            titel             = text-074
            cancel_display    = 'X'
       IMPORTING
            answer            = l_answer.

  CASE l_answer.
    WHEN '1'.
CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
     EXPORTING
          agr_name      = agr_name
     EXCEPTIONS
          agr_not_found = 1
          OTHERS        = 2.
      IF sy-subrc <> 0.
        IF sy-subrc = 1.
          CLEAR l_pertext.
          CONCATENATE text-076 text-190
                     INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-077 text-190 text-078
                     INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.
        ENDIF.
      ENDIF.
    WHEN '2'.
      DATA: userresponse, dflt_rfc LIKE /psyng/swconfig-value.

      CLEAR: lt_fields.
      REFRESH: lt_fields.
      se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
      IF lt_fields[] IS INITIAL.
        lt_fields-tabname = 'RFCDES'.
        lt_fields-fieldname = 'RFCDEST'.
        lt_fields-fieldtext = text-090.
        IF NOT dflt_rfc IS INITIAL.
          lt_fields-value = dflt_rfc.
        ENDIF.
        APPEND lt_fields.
      ENDIF.

      CLEAR userresponse.
      l_repid = sy-repid.
      CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
           EXPORTING
                formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
                programname       = l_repid
                popup_title       = text-066
                ok_pushbuttontext = text-127
           IMPORTING
                returncode        = userresponse
           TABLES
                fields            = lt_fields
           EXCEPTIONS
                error_in_fields   = 1
                OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH text-067.
      ENDIF.

      CHECK userresponse NE 'A'. "#EC SAST_CI_GEN_CHECK
        "check to see user doesn't abort

      READ TABLE lt_fields WITH KEY tabname = 'RFCDES'
                                  fieldname = 'RFCDEST'.

      IF lt_fields-value IS INITIAL.
        MESSAGE w208(00) WITH text-068.
      ENDIF.
      SELECT SINGLE * FROM rfcdes WHERE rfcdest = lt_fields-value AND
                                        rfctype = '3'.
      IF sy-subrc EQ 0.
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
        CALL FUNCTION 'PRGN_SHOW_EDIT_AGR'
            DESTINATION lt_fields-value
             EXPORTING
                  agr_name = agr_name
         EXCEPTIONS
           agr_not_found       = 1
           OTHERS              = 2 . "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


        IF sy-subrc = 1.
          CLEAR l_pertext.
          CONCATENATE text-076 lt_fields-value
                     INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-077 lt_fields-value text-078
                     INTO l_pertext SEPARATED BY space.
          MESSAGE i208(00) WITH l_pertext.
        ENDIF.
      ELSE.
        CLEAR l_pertext.
        CONCATENATE text-090 lt_fields-value text-133
                                 INTO l_pertext SEPARATED BY space.
        MESSAGE i208(00) WITH l_pertext.
      ENDIF.

    WHEN OTHERS.
  ENDCASE.
ENDFORM.                    " display_role_in_pfcg
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SODVRSIO  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion
   USING  l_sod   TYPE /psyng/swsodvers-vrsio
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

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  before_after_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_ADDITION_SIMU  text
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*----------------------------------------------------------------------*
FORM before_after_simulation
  TABLES
    it_role_removal_simu  STRUCTURE /psyng/sw_role_removal_simu
    it_role_addition_simu STRUCTURE /psyng/sw_role_addition_simu.
  DATA:
  lt_role_removal_sim     TYPE TABLE OF /psyng/sw_role_removal_simu
                          WITH HEADER LINE,
  lt_simu_roleauth_part   TYPE TABLE OF /psyng/roleauth
                          WITH HEADER LINE,
  lt_simu_roletcode_part  TYPE TABLE OF /psyng/roletcode
                          WITH HEADER LINE,
  ls_output               TYPE /psyng/sw_out_routput,
  lt_confdet_sys          TYPE TABLE OF /psyng/confdet,
  lt_functtran_sys        TYPE TABLE OF /psyng/functtran,
  lt_faobj_sys            TYPE TABLE OF /psyng/faobj2,
  l_system                TYPE /psyng/rfcname,
  ls_faobj_system         TYPE /psyng/sw_sys_faobj,
  ls_ao_sys               TYPE /psyng/sw_sys_ao,
  l_rfcdes                TYPE rfcdes,
  l_taskname              TYPE string,
  ls_cc                   TYPE lvc_t_scol WITH HEADER LINE,
  ls_color                TYPE lvc_s_colo.
  IF bysimu = 'X'.
*-- Load all simulated roles from their source system
    DATA :
    l_agr_name TYPE agr_name.
    RANGES : range_roles FOR l_agr_name.
    PERFORM load_simulated_role_content
     TABLES
       it_role_addition_simu
       gt_simu_roleauth
       gt_simu_roletcode
       gt_functtran_local
       gt_faobj_local
       gt_rfcdest_anal.
  ENDIF.

*-- Before SOD analysis
*--Remote Role Analysis

  IF NOT gt_rfcdest_anal[] IS INITIAL.

    LOOP AT gt_rfcdest_anal INTO l_rfcdes.
      l_taskname = l_rfcdes-rfcdest.
      ADD 1 TO g_running_tasks.


*--Filter Functions by system
      l_system           = l_rfcdes-rfcoptions.
      lt_functtran_sys[] = gt_functtran_local[].
      lt_confdet_sys[]   = gt_confdet_local[].

*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_system.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_system.


      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = l_vrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
                it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS  = 1
             OTHERS            = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

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
      CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
         STARTING NEW TASK l_taskname
          DESTINATION l_rfcdes-rfcdest
           PERFORMING get_remote_results ON END OF TASK
       EXPORTING
         vrsio                = sodvrsio
         i_config_set         = cfgset
         i_rchdatf            = rchdatf
         i_rchdatt            = rchdatt
         enh_fm               = p_enhanc
         xstb_fm              = 'X'
*         i_bysimu             = bysimu
         i_shonosod           = p_shonof
         i_local_sod          = gf_local_sod
         i_composite_roles    = comprol
         i_single_roles       = singrol
         i_assigned_roles     = asign_r
         org_check            = orgchk
       TABLES
         it_func              = spfun
         it_busarea           = busarea
         it_owner             = owner
         it_roles             = role
         IT_ROLE_BA           = rba
         it_conflict          = gt_conflict_local
         it_confdet           = lt_confdet_sys
         it_functtran         = lt_functtran_sys
         it_faobj             = lt_faobj_sys
         it_swsodorgm         = ls_ao_sys-swsodorgm[]
         it_tcodes            = gt_tcodes_local
         it_functran_no_enh   = gt_functran_no_enh_local
         ot_routput           = gt_routput_temp
         et_mitigations       = gt_mitigations. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDLOOP.
  ENDIF.
  IF ronlyrem IS INITIAL.
    DATA : l_local_rfc TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.

*--Filter Functions by system
    l_system           = l_local_rfc.
    lt_functtran_sys[] = gt_functtran_local[].
    lt_faobj_sys[]     = gt_faobj_local[].
    lt_confdet_sys[]   = gt_confdet_local[].
    CALL FUNCTION '/PSYNG/SW_124'
         EXPORTING
              if_functions  = 'X'
              i_system      = l_system
              i_application = 'SAP'
              i_vrsio       = l_vrsio
         TABLES
              it_functtran  = lt_functtran_sys
              it_faobj      = lt_faobj_sys
              it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS       = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


    CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
         EXPORTING
              vrsio              = sodvrsio
              i_config_set       = cfgset
              i_rchdatf          = rchdatf
              i_rchdatt          = rchdatt
              enh_fm             = p_enhanc
              i_shonosod         = p_shonof
              xstb_fm            = 'X'
              i_local_sod        = gf_local_sod
              i_composite_roles  = comprol
              i_single_roles     = singrol
              i_assigned_roles   = asign_r
              org_check          = orgchk
         IMPORTING
              o_totalroles       = g_numroles
         TABLES
              it_func            = spfun
              it_busarea         = busarea
              it_owner           = owner
              it_roles           = role
              IT_ROLE_BA         = rba
              it_conflict        = gt_conflict_local
              it_confdet         = lt_confdet_sys
              it_functtran       = lt_functtran_sys
              it_faobj           = lt_faobj_sys
              it_swsodorgm       = gt_swsodorgm_local
              it_tcodes          = gt_tcodes_local
              it_functran_no_enh = gt_functran_no_enh_local
              ot_routput         = gt_func_routput.

    APPEND LINES OF gt_func_routput  TO gt_routput_before.
    FREE : gt_func_routput .
  ENDIF.
  WAIT UNTIL g_running_tasks = 0.

  APPEND LINES OF gt_routput_sum  TO gt_routput_before.
  REFRESH gt_routput_sum.

*-- After Simulation
*--Remote Role Analysis


  CLEAR : g_trolecount, g_numroles.
  IF NOT gt_rfcdest_anal[] IS INITIAL.

    LOOP AT gt_rfcdest_anal INTO l_rfcdes.
      l_taskname = l_rfcdes-rfcdest.
      ADD 1 TO g_running_tasks.
      FREE : lt_role_removal_sim.
      LOOP AT it_role_removal_simu WHERE rfcdest = l_rfcdes-rfcdest.
        APPEND it_role_removal_simu TO lt_role_removal_sim.
      ENDLOOP.
      FREE : gt_removed_roles.


      FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
      LOOP AT gt_simu_roleauth WHERE rfcdest =  l_rfcdes-rfcoptions.
        APPEND gt_simu_roleauth TO lt_simu_roleauth_part.
      ENDLOOP.

      LOOP AT gt_simu_roletcode WHERE rfcdest = l_rfcdes-rfcoptions.
        APPEND gt_simu_roletcode TO lt_simu_roletcode_part.
      ENDLOOP.

*--Filter Functions by system
      l_system           = l_rfcdes-rfcoptions.
      lt_functtran_sys[] = gt_functtran_local[].
      lt_confdet_sys[]   = gt_confdet_local[].
*     --Variable Elements, get the correct values for the remote system
      READ TABLE gt_faobj_system INTO ls_faobj_system
      WITH KEY rfcdest = l_system.
      IF sy-subrc = 0.
        lt_faobj_sys[] = ls_faobj_system-faobj[].
      ENDIF.
*--Org Elements, get the correct values for the system
      CLEAR ls_ao_sys.
      READ TABLE gt_ao_sys INTO ls_ao_sys
      WITH KEY rfcdest = l_system.


      CALL FUNCTION '/PSYNG/SW_124'
           EXPORTING
                if_functions  = 'X'
                i_system      = l_system
                i_application = 'SAP'
                i_vrsio       = l_vrsio
           TABLES
                it_functtran  = lt_functtran_sys
                it_faobj      = lt_faobj_sys
                it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

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
      CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
            STARTING NEW TASK l_taskname
              DESTINATION l_rfcdes-rfcdest
           PERFORMING get_remote_results ON END OF TASK
            EXPORTING
              vrsio                = sodvrsio
              i_rchdatf            = rchdatf
              enh_fm               = p_enhanc
              i_rchdatt            = rchdatt
              i_shonosod           = p_shonof
              xstb_fm              = 'X'
*              i_bysimu             = bysimu
              i_local_sod          = gf_local_sod
              i_composite_roles    = comprol
              i_single_roles       = singrol
              i_assigned_roles     = asign_r
              org_check            = orgchk
            TABLES
             it_func               = spfun
             it_busarea            = busarea
             it_owner              = owner
             it_roles              = role
             IT_ROLE_BA            = rba
             it_conflict           = gt_conflict_local
             it_confdet            = lt_confdet_sys
             it_functtran          = lt_functtran_sys
             it_faobj              = lt_faobj_sys
             it_swsodorgm          = ls_ao_sys-swsodorgm[]
             it_tcodes             = gt_tcodes_local
             it_functran_no_enh    = gt_functran_no_enh_local
             it_simurole_auth      = lt_simu_roleauth_part
             it_simurole_tcode     = lt_simu_roletcode_part
             ot_routput            = gt_routput_temp
*--Role Removal Simulation
             it_simu_role_removal  = lt_role_removal_sim
             et_simu_removed_roles = gt_removed_roles.
             "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDLOOP.

  ENDIF.


  IF ronlyrem IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
    FREE : lt_role_removal_sim.
    LOOP AT it_role_removal_simu WHERE rfcdest = 'LOCAL' OR
                                       rfcdest = '' OR
                                       rfcdest = l_local_rfc.
      APPEND it_role_removal_simu TO lt_role_removal_sim.
    ENDLOOP.
    FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.

    LOOP AT gt_simu_roleauth WHERE rfcdest = l_local_rfc.
      APPEND gt_simu_roleauth TO lt_simu_roleauth_part.
    ENDLOOP.

    LOOP AT gt_simu_roletcode WHERE rfcdest = l_local_rfc.
      APPEND gt_simu_roletcode TO lt_simu_roletcode_part.
    ENDLOOP.
*--Filter Functions by system
    l_system           = l_local_rfc.
    lt_functtran_sys[] = gt_functtran_local[].
    lt_faobj_sys[]     = gt_faobj_local[].
    lt_confdet_sys[]   = gt_confdet_local[].
    CALL FUNCTION '/PSYNG/SW_124'
         EXPORTING
              if_functions  = 'X'
              i_system      = l_system
              i_application = 'SAP'
              i_vrsio       = l_vrsio
         TABLES
              it_functtran  = lt_functtran_sys
              it_faobj      = lt_faobj_sys
              it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS  = 1
             OTHERS          = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


    CALL FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'
         EXPORTING
              vrsio               = sodvrsio
              i_config_set        = cfgset
              i_rchdatf           = rchdatf
              i_rchdatt           = rchdatt
              enh_fm              = p_enhanc
              i_shonosod          = p_shonof
              xstb_fm             = 'X'
*              i_bysimu            = bysimu
              i_local_sod         = gf_local_sod
               i_composite_roles  = comprol
               i_single_roles     = singrol
               i_assigned_roles   = asign_r
               org_check          = orgchk
         IMPORTING
              o_totalroles        = g_numroles
         TABLES
              it_func             = spfun
              it_busarea          = busarea
              it_owner            = owner
              it_roles            = role
              IT_ROLE_BA          = rba
              it_conflict         = gt_conflict_local
              it_confdet          = lt_confdet_sys
              it_functtran        = lt_functtran_sys
              it_faobj            = lt_faobj_sys
              it_swsodorgm        = gt_swsodorgm_local
              it_tcodes           = gt_tcodes_local
              it_functran_no_enh  = gt_functran_no_enh_local
              it_simurole_auth    = lt_simu_roleauth_part
              it_simurole_tcode   = lt_simu_roletcode_part
              ot_routput          = gt_func_routput
*--Role Removal Simulation
              it_simu_role_removal   = lt_role_removal_sim
              et_simu_removed_roles = gt_removed_roles
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

    APPEND LINES OF gt_func_routput TO gt_routput_after.
    FREE : gt_func_routput.
    ADD g_numroles TO g_trolecount.
  ENDIF.
  WAIT UNTIL g_running_tasks = 0.
  APPEND LINES OF gt_routput_sum  TO gt_routput_after.
  REFRESH gt_routput_sum.

  SORT  gt_routput_after  BY functionid agr_name rfcdest.
  SORT  gt_routput_before BY functionid agr_name rfcdest.

  LOOP AT gt_routput_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_routput_after TO ls_output.
    READ TABLE gt_routput_before
    WITH KEY functionid = gt_routput_after-functionid
             agr_name = gt_routput_after-agr_name
*Begin of addition AKUMAR PN15868 08.01.2026
*To check simulation status system wise.
             rfcdest = gt_routput_after-rfcdest.
*End of addition

    IF sy-subrc <> 0.

      ls_output-simu_after = 'X'.
      CLEAR ls_output-simu_before.
    ELSE.
      ls_output-simu_after = 'X'.
      ls_output-simu_before = 'X'.
    ENDIF.
    IF ls_output-simu_after <> ls_output-simu_before.
      ls_output-simu = 'X'.
    ELSE.
      CLEAR ls_output-simu.
    ENDIF.
    APPEND ls_output TO gt_res.
  ENDLOOP.

  LOOP AT gt_routput_before.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_routput_before TO ls_output.
    READ TABLE gt_routput_after
    WITH KEY functionid = gt_routput_before-functionid
             agr_name = gt_routput_before-agr_name
*Begin of addition AKUMAR PN15868 08.01.2026
*To check simulation status system wise.
             rfcdest = gt_routput_before-rfcdest.
*End of addition
    IF sy-subrc <> 0.

      ls_output-simu_before = 'X'.
      CLEAR ls_output-simu_after.

      IF ls_output-simu_after <> ls_output-simu_before.
        ls_output-simu = 'X'.
      ELSE.
        CLEAR ls_output-simu.
      ENDIF.

      APPEND ls_output TO gt_res.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_res.
    MOVE-CORRESPONDING gt_res TO gt_routput.
    APPEND gt_routput.
  ENDLOOP.
ENDFORM.                    " before_after_simulation
*&---------------------------------------------------------------------*
*&      Form  load_simulated_role_content
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_ROLE_ADDITION_SIMU  text
*      -->P_LT_SIMU_ROLEAUTH  text
*      -->P_LT_SIMU_ROLETCODE  text
*      -->P_LT_FUNCTTRAN  text
*      -->P_LT_FAOBJ  text
*      -->P_GT_REMOTE_ANAL_RFC  text
*----------------------------------------------------------------------*
FORM load_simulated_role_content  TABLES   it_simu_role_addition
STRUCTURE /psyng/sw_role_addition_simu
         et_simu_roleauth STRUCTURE /psyng/roleauth
         et_simu_roletcode STRUCTURE /psyng/roletcode
         it_functran_local STRUCTURE /psyng/functtran
         it_faobj_local STRUCTURE /psyng/faobj2
         it_rfcdes STRUCTURE rfcdes.

  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu
                                        WITH HEADER LINE,
     lt_faobj TYPE TABLE OF /psyng/faobj2,
     lt_functtran TYPE TABLE OF /psyng/functtran,
     l_agr_name TYPE agr_name,
     lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
    lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
    lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE.
  DATA: l_rfcdes TYPE rfcdest.

  CONCATENATE sy-sysid sy-mandt INTO   l_rfcdes.
  RANGES : range_roles FOR l_agr_name.
  lt_unique_rfcs[] = it_simu_role_addition[].
  SORT lt_unique_rfcs BY source_rfcdest.
  DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs
                             COMPARING source_rfcdest.

*  LOOP AT lt_unique_rfcs.

  LOOP AT it_simu_role_addition.
    REFRESH : range_roles.
*    WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
    MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
    APPEND range_roles.
*    ENDLOOP.

*    IF lt_unique_rfcs-source_rfcdest IS INITIAL OR
*      lt_unique_rfcs-source_rfcdest = 'LOCAL'.
    IF it_simu_role_addition-source_rfcdest IS INITIAL OR
          it_simu_role_addition-source_rfcdest = 'LOCAL'.
*--Get list of roles matching range
      CALL FUNCTION '/PSYNG/SW_102'
           TABLES
                it_roles_range = range_roles
                et_roles       = lt_role_names.
      LOOP AT lt_role_names.
*--Load local role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
        REFRESH : lt_roleauth,lt_roletcode.
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
             EXPORTING
                  agr_name       = lt_role_names-agr_name
                  bname          = '000000000000'
             TABLES
                  roleauth       = lt_roleauth
                  roletcode      = lt_roletcode
                  functtran      = lt_functtran
                  faobj          = lt_faobj
             EXCEPTIONS
                  role_not_found = 1
                  OTHERS         = 2.
*BOC:HBHALLA (03/12/24)
         IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
               MESSAGE s002(/psyng/sw) WITH 'Invalid Role'.
            WHEN OTHERS.
               MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
          ENDCASE.
         ENDIF.
*EOC:HBHALLA (03/12/24)
*--Update the destination RFCDEST
*        LOOP AT it_simu_role_addition
*        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest
*           AND low  = lt_role_names-agr_name.
*          REFRESH : range_roles.
*          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
*          APPEND range_roles.
        READ TABLE it_rfcdes
        WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
        IF sy-subrc <> 0 AND
        (
          it_simu_role_addition-target_rfcdest = 'LOCAL' OR
          it_simu_role_addition-target_rfcdest = l_rfcdes OR
          it_simu_role_addition-target_rfcdest = ' ' ).
          it_rfcdes-rfcoptions = l_rfcdes.
        ENDIF.
        lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
        lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
        MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.
*        ENDLOOP.
        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
        ENDLOOP.
        REFRESH lt_roleauth.

        LOOP AT lt_roletcode.
          MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
          APPEND et_simu_roletcode.
        ENDLOOP.

        REFRESH lt_roletcode.
      ENDLOOP.

    ELSE.
*--Get list of roles matching range
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
      CALL FUNCTION '/PSYNG/SW_102'
        DESTINATION it_simu_role_addition-source_rfcdest
        TABLES
          it_roles_range       = range_roles
          et_roles             = lt_role_names."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      LOOP AT lt_role_names.
*--Load remote role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
        DESTINATION it_simu_role_addition-source_rfcdest
           EXPORTING
                agr_name  = lt_role_names-agr_name
                bname     = '000000000000'
           TABLES
                roleauth  = lt_roleauth
                roletcode = lt_roletcode
                functtran = lt_functtran
                faobj     = lt_faobj
           EXCEPTIONS
                role_not_found = 1
                OTHERS         = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*--Update the destination RFCDEST
*        LOOP AT it_simu_role_addition
*        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
*          REFRESH : range_roles.
*          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
*          APPEND range_roles.
        READ TABLE it_rfcdes
        WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
        IF sy-subrc <> 0 AND
        (
          it_simu_role_addition-target_rfcdest = 'LOCAL' OR
          it_simu_role_addition-target_rfcdest = l_rfcdes OR
          it_simu_role_addition-target_rfcdest = ' ' ).
          it_rfcdes-rfcoptions = l_rfcdes.
        ENDIF.

        lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
        lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
        MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE
        agr_name <> ''.
*        agr_name IN range_roles  .
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE
        agr_name <> ''.
*        agr_name IN range_roles.
*        ENDLOOP.

        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
        ENDLOOP.

        REFRESH lt_roleauth.
        LOOP AT lt_roletcode.
          MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
          APPEND et_simu_roletcode.
        ENDLOOP.
        REFRESH lt_roletcode.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " load_simulated_role_content
*&---------------------------------------------------------------------*
*&      Form  get_role_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_role_text.
  DATA : lt_agr_names TYPE TABLE OF agr_texts WITH HEADER LINE.

  IF NOT gt_routput[] IS INITIAL.
    SELECT agr_name text FROM agr_texts INTO
    CORRESPONDING FIELDS OF  TABLE lt_agr_names
    FOR ALL ENTRIES IN gt_routput
    WHERE
    agr_name = gt_routput-agr_name AND
    spras = sy-langu AND
    line < 1.
  ENDIF.

  LOOP AT lt_agr_names.
    gt_routput-agr_text = lt_agr_names-text.
    MODIFY gt_routput
    TRANSPORTING agr_text
    WHERE agr_name = lt_agr_names-agr_name.
  ENDLOOP.
ENDFORM.                    " get_role_text
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA : l_jobname TYPE btcjob,
  l_curr_report  LIKE  rsvar-report.

  CLEAR: l_curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  l_curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = l_curr_report
            curr_variant  = g_variant
            vari_desc     = g_vari_desc
       TABLES
            vari_contents = gr_irsparams
            vari_text     = gt_varit
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          ILLEGAL_REPORT_OR_VARIANT = 1
          ILLEGAL_VARIANTNAME = 2
          NOT_AUTHORIZED = 3
          NOT_EXECUTED = 4
          REPORT_NOT_EXISTENT = 5
          REPORT_NOT_SUPPLIED = 6
          VARIANT_EXISTS = 7
          VARIANT_LOCKED = 8
          OTHERS = 9.
IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = 'Security Weaver : Role Func Scan'(069).
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
  DATA: l_oldnumber(7) TYPE n, l_oldnumber_c(7).

  CLEAR: g_variant, gt_varit, g_vari_desc.
  REFRESH: gt_varit, g_vari_desc.

*  SELECT variant INTO g_variant FROM varid
*                     WHERE report = sy-repid AND
*                           variant LIKE '/PSYNG/%'
*    AND NOT  variant LIKE '/PSYNG/Z%'
*  ORDER BY variant DESCENDING.
*    l_oldnumber = g_variant+7(7).
*    EXIT.
*  ENDSELECT.
*  IF sy-subrc NE 0.
*    g_variant = '/PSYNG/0000000'.
*  ELSE.
*    l_oldnumber = l_oldnumber + 1.
*    MOVE l_oldnumber TO l_oldnumber_c.
*    CONCATENATE '/PSYNG/' l_oldnumber_c INTO g_variant.
*  ENDIF.

*--C017 Odubey 29/11/2021
CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
  EXPORTING
    i_report        = sy-repid
 IMPORTING
   E_VARIANT       = g_variant.

  gt_varit-langu = sy-langu.
  gt_varit-report = sy-repid.
  gt_varit-variant = g_variant.
  gt_varit-vtext = text-146.
  APPEND gt_varit.

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
*Parameters
  REFRESH : gr_irsparams.
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = g_program
            if_no_logging = 'X'
       TABLES
            et_params     = gr_irsparams.

ENDFORM.                    " fill_sel_screen_fields_to_tab
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
    WHEN 'ROLE_BUT'.
      PERFORM toggle USING role_but 'ROLE_BUT'.
    WHEN 'REM_BUT'.
      PERFORM toggle USING rem_but 'REM_BUT'.
    WHEN 'FUN_BUT'.
      PERFORM toggle USING fun_but 'FUN_BUT'.
    WHEN 'SIMU_BUT'.
      PERFORM toggle USING simu_but 'SIMU_BUT'.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but 'BGD_BUT'.
    WHEN 'EXE_BUT'.
      PERFORM toggle USING exe_but 'EXE_BUT'.
  ENDCASE.
  CLEAR g_ucomm.

ENDFORM.                    " handle_button
*&---------------------------------------------------------------------*
*&      Form  toggle
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ROLE_BUT  text
*      -->P_7286   text
*----------------------------------------------------------------------*
FORM toggle USING    i_button i_name.
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

ENDFORM.                    " toggle
*&---------------------------------------------------------------------*
*&      Form  handle_sections
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_sections.
  PERFORM handle_section USING  role_but 'ROL'.
  PERFORM handle_section USING  rem_but  'REM'.
  PERFORM handle_section USING  fun_but  'FUN'.
  PERFORM handle_section USING  simu_but 'SIM'.
  PERFORM handle_section USING  bgd_but  'BGD'.
  PERFORM handle_section USING  exe_but  'EXE'.
ENDFORM.                    " handle_sections
*&---------------------------------------------------------------------*
*&      Form  handle_section
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ROLE_BUT  text
*      -->P_7386   text
*----------------------------------------------------------------------*
FORM handle_section USING     i_button
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

ENDFORM.                    " handle_section
*&---------------------------------------------------------------------*
*&      Form  role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AGR_NAME  text
*----------------------------------------------------------------------*
FORM role_sod_analysis_from_details USING    agr_name.

  SUBMIT /psyng/sod_syswide_byrole
           WITH role     = agr_name
           WITH sodvrsio    = sodvrsio
           AND RETURN.

ENDFORM.                    " role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*&      Form  validate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_other_fields.
  DATA :
         lt_roles TYPE TABLE OF /psyng/bc_agr_name,
         l_rfcdest_local TYPE rfcdes-rfcdest,
                             lt_excluding TYPE  slis_t_extab,
         ls_excluding TYPE slis_extab,
         l_repid          LIKE sy-repid,
         lt_fcat          TYPE slis_t_fieldcat_alv,
         ls_fcat          LIKE LINE OF lt_fcat,
         l_exit,
         lf_childexist TYPE c.
  DATA : BEGIN OF lt_rfc_roles OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
         agr_name(30) TYPE c,
         END OF lt_rfc_roles.
  DATA: lt_sim TYPE TABLE OF /psyng/range_agr_name WITH HEADER LINE.
  DEFINE append_roles.
    if &1 is initial.
      &1 = 'LOCAL'.
    endif.
    lt_rfc_roles-rfcdest = &1.
    lt_rfc_roles-agr_name = &2.
    append lt_rfc_roles.
    clear gt_rfcdest-rfcdest.
  END-OF-DEFINITION.

*--RFC
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.


*--Validation of Add role by Simulation
  IF bysimu = 'X'.
*-- Validate Source RFC
    IF NOT ar_rol_1[] IS INITIAL.
      IF NOT ar_rfcs1 = '' AND
         NOT ar_rfcs1 = 'LOCAL' AND
         NOT ar_rfcs1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs1.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.

            append_roles gt_rfcdest-rfcdest ar_rol_1-low.

          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs1.
        ENDIF.

      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_1
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          append_roles gt_rfcdest-rfcdest ar_rol_1-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd1 = '' AND
        NOT ar_rfcd1 = 'LOCAL' AND
        NOT ar_rfcd1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd1.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd1.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_2[] IS INITIAL.
      IF NOT ar_rfcs2 = '' AND
         NOT ar_rfcs2 = 'LOCAL' AND
         NOT ar_rfcs2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs2.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_2-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs2.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_2
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest ar_rol_2-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd2 = '' AND
        NOT ar_rfcd2 = 'LOCAL' AND
        NOT ar_rfcd2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd2.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd2.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_3[] IS INITIAL.
      IF NOT ar_rfcs3 = '' AND
         NOT ar_rfcs3 = 'LOCAL' AND
         NOT ar_rfcs3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs3.
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

          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            append_roles gt_rfcdest-rfcdest ar_rol_3-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs3.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_3
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          append_roles gt_rfcdest-rfcdest ar_rol_3-low..
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd3 = '' AND
        NOT ar_rfcd3 = 'LOCAL' AND
        NOT ar_rfcd3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd3.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd3.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT ar_rol_4[] IS INITIAL.
      IF NOT ar_rfcs4 = '' AND
         NOT ar_rfcs4 = 'LOCAL' AND
         NOT ar_rfcs4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs4.
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

          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_4-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs4.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = ar_rol_4
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest ar_rol_4-low.
        ENDIF.
      ENDIF.
*-- Validate Target RFC
      IF NOT ar_rfcd4 = '' AND
      NOT ar_rfcd4 = 'LOCAL' AND
      NOT ar_rfcd4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcd4.
        IF sy-subrc = 0.
        ELSE.
          DELETE gt_role_addition_simu WHERE target_rfcdest = ar_rfcd4.
        ENDIF.
      ENDIF.
    ENDIF.


  ENDIF.

*-- Role Removal Simulation
  IF byrsimu = 'X'.
    IF NOT rr_rol_1[] IS INITIAL.
      IF NOT rr_rfc_1 = '' AND
         NOT rr_rfc_1 = 'LOCAL' AND
         NOT rr_rfc_1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_1.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_1-low.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_1.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_1
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest rr_rol_1-low.
        ENDIF.
      ENDIF.
    ENDIF.


    IF NOT rr_rol_2[] IS INITIAL.
      IF NOT rr_rfc_2 = '' AND
         NOT rr_rfc_2 = 'LOCAL' AND
         NOT rr_rfc_2 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_2.
        IF sy-subrc = 0.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            append_roles gt_rfcdest-rfcdest rr_rol_2-low.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_2.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_2
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          append_roles gt_rfcdest-rfcdest rr_rol_2-low.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_3[] IS INITIAL.
      IF NOT rr_rfc_3 = '' AND
         NOT rr_rfc_3 = 'LOCAL' AND
         NOT rr_rfc_3 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_3.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            append_roles gt_rfcdest-rfcdest rr_rol_3-low.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_3.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_3
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
          append_roles gt_rfcdest-rfcdest rr_rol_3-low.
        ENDIF.
      ENDIF.
    ENDIF.

    IF NOT rr_rol_4[] IS INITIAL.
      IF NOT rr_rfc_4 = '' AND
         NOT rr_rfc_4 = 'LOCAL' AND
         NOT rr_rfc_4 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = rr_rfc_4.
        IF sy-subrc = 0.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5.
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest rr_rol_4-low.
          ENDIF.
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_4.
        ENDIF.
      ELSE.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
             TABLES
                  it_agr_name         = rr_rol_4
                  et_roles            = lt_roles
             EXCEPTIONS
                  role_does_not_exist = 1
                  OTHERS              = 2.
        IF sy-subrc <> 0.
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  IF NOT lt_rfc_roles[] IS INITIAL.

*-- Show Popup
    l_repid = sy-repid.
    ls_fcat-fieldname = 'RFCDEST'.
    ls_fcat-outputlen = '30'.
    ls_fcat-seltext_l = 'RFC Destination'.
    ls_fcat-reptext_ddic  = ls_fcat-seltext_l.

    APPEND ls_fcat TO lt_fcat.

    ls_fcat-fieldname = 'AGR_NAME'.
    ls_fcat-outputlen = '30'.
    ls_fcat-seltext_l = 'Simulated Entry'.
    ls_fcat-reptext_ddic  = ls_fcat-seltext_l.

    APPEND ls_fcat TO lt_fcat.


*--Exclude buttons that are not required
    ls_excluding-fcode = '&IC1'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '&ETA'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '&OUP'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '&ODN'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '%SC+'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '%SC'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '&ILT'.
    APPEND ls_excluding TO lt_excluding.
    ls_excluding-fcode = '&OL0'.
    APPEND ls_excluding TO lt_excluding.

    CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
         EXPORTING
              i_title       = 'Simulated Entries validation'
              i_selection   = ''
              i_zebra       = 'X'
              i_tabname     = 'LT_RFC_ROLES'
*              I_STRUCTURE_NAME = 'BAPIRET2'
              it_fieldcat   = lt_fcat
              it_excluding  = lt_excluding
         IMPORTING
              e_exit        = l_exit
         TABLES
              t_outtab      = lt_rfc_roles

         EXCEPTIONS
              program_error = 1
              OTHERS        = 2.
    IF sy-subrc <> 0.
      MESSAGE e010 WITH
      'Unable to show Simulated entries validation issues'(201).
    ENDIF.

    IF l_exit = 'X'.
      LEAVE LIST-PROCESSING.
    ELSE.

    ENDIF.
  ENDIF.

  CHECK byrsimu EQ 'X'.

  LOOP AT gt_role_removal_simu.
    MOVE-CORRESPONDING gt_role_removal_simu TO lt_sim.
    APPEND lt_sim.
  ENDLOOP.


  LOOP AT gt_rfcdest_anal.
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
    CALL FUNCTION '/PSYNG/BC_GET_SINGLE_ROLES'
    DESTINATION gt_rfcdest_anal-rfcdest
*     EXPORTING
*       I_AGR_NAME                =
     TABLES
       it_roles                  = role
       it_child                  = lt_sim
       EXCEPTIONS
         role_does_not_exist       = 1
         OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc EQ 0.
      lf_childexist = 'X'.
    ENDIF.
  ENDLOOP.

  IF ronlyrem IS INITIAL.
    CALL FUNCTION '/PSYNG/BC_GET_SINGLE_ROLES'
*     EXPORTING
*       I_AGR_NAME                =
     TABLES
       it_roles                  = role
       it_child                  = lt_sim
     EXCEPTIONS
       role_does_not_exist       = 1
       OTHERS                    = 2
              .
    IF sy-subrc <> 0 AND lf_childexist IS INITIAL.
      MESSAGE s398(00) WITH
      'No Roles had the roles for'(202)
      'which the removal was simulated'(203).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ELSE.
    IF lf_childexist IS INITIAL.

      MESSAGE s398(00) WITH
      'No Roles had the roles for'(202)
      'which the removal was simulated'(203)
.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

ENDFORM.                    " validate_other_fields
*&---------------------------------------------------------------------*
*&      Form  get_remote_results
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_remote_results USING taskname.
  DATA : lt_routput_temp   TYPE TABLE OF /psyng/sw_out_routput,
*         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
*         WITH HEADER LINE,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i.
*         lt_mitigations TYPE TABLE OF /psyng/mitigation_assignment.


  RECEIVE RESULTS FROM FUNCTION '/PSYNG/FUNC_ROLE_ANALYSIS'

     IMPORTING
       o_totalroles         = l_numroles
         TABLES
       ot_routput      = lt_routput_temp
*       et_simu_removed_roles = lt_removed_roles
*       et_mitigations       = lt_mitigations
      EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.
  IF sy-subrc = 0.
*    APPEND LINES OF lt_routput_sum TO gt_routput_sum.
*    APPEND LINES OF lt_removed_roles TO gt_removed_roles.
*    APPEND LINES OF lt_mitigations TO gt_mitigations.
    APPEND LINES OF lt_routput_temp TO gt_routput_sum.
    ADD l_numroles TO g_trolecount.
    FREE : lt_routput_temp.",lt_removed_roles,lt_mitigations .
*    ADD l_numroles TO trolecount.
  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
*        gt_return-type    = 'W'.
*        gt_return-id      = '00'.
*        gt_return-number  = '398'.
*
*        MESSAGE e398(00) WITH
*        'Task :'(l22)
*        taskname
*        'failed.'(l23)
*        l_system_msg
*        INTO gt_return-message.
*        COLLECT gt_return.

        MESSAGE s398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg.
      WHEN 3.
*        gt_return-type    = 'W'.
*        gt_return-id      = '00'.
*        gt_return-number  = '398'.
*
*        MESSAGE e398(00) WITH
*        'Task :'(l22)
*        taskname
*        'failed.'(l23)
*        INTO gt_return-message.
*        COLLECT gt_return.

        MESSAGE s398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23).
    ENDCASE.

  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.


ENDFORM.                    " get_remote_results

*---------------------------------------------------------------------*
*       FORM display_role_of_remote_system                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  FIELDS                                                        *
*  -->  CODE                                                          *
*  -->  ERROR                                                         *
*  -->  SHOW_POPUP                                                    *
*---------------------------------------------------------------------*
FORM display_role_of_remote_system TABLES   fields STRUCTURE sval
                   USING    code
                   CHANGING error  STRUCTURE svale show_popup.
  CASE code.
    WHEN 'EXECUTE'.
    WHEN 'EXIT'.
    WHEN 'OK'.
    WHEN OTHERS.
  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  reformat_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reformat_output.
  DATA: ls_cc  TYPE lvc_t_scol WITH HEADER LINE,
        ls_color TYPE lvc_s_colo.

  IF det IS INITIAL.
*--Filter based on selected org areas
    IF NOT  orglvl[] IS INITIAL AND NOT orgchk IS INITIAL.
      DELETE gt_routput WHERE
                   org_abb <> '*' AND NOT org_abb IN orglvl.
    ENDIF.
*  -- Get role Text
    PERFORM get_role_text.
    LOOP AT gt_routput.
      READ TABLE gt_functions WITH KEY
                         function = gt_routput-functionid.
      IF sy-subrc = 0.
        MOVE-CORRESPONDING gt_routput TO gt_output_smm.
        gt_output_smm-owner = gt_functions-owner.
        gt_output_smm-busarea = gt_functions-busarea.
        gt_output_smm-fdescription = gt_functions-description.
      IF p_hienhn = 'X'.
        IF gt_output_smm-enhanced = 'X'.
          DELETE gt_output_smm-color_cell
                 WHERE fname = 'FUNCTIONID'.
          ls_color-col = '7'.   "Orange
          ls_color-int = '1'.   "Intensified
          ls_color-inv = '0'.   "Inverse
          ls_cc-color  = ls_color.
          ls_cc-fname  = 'FUNCTIONID'.
          APPEND ls_cc TO gt_output_smm-color_cell.
        ENDIF.
      ENDIF.
        APPEND gt_output_smm.
      ENDIF.
    ENDLOOP.
    SORT gt_output_smm BY agr_name functionid rfcdest.
    DELETE ADJACENT DUPLICATES FROM gt_output_smm COMPARING
     agr_name functionid rfcdest org_abb.
    REFRESH : gt_func_routput.
    IF gt_output_smm[] IS INITIAL.
*Begin of Addition:HBHALLA(PN-18733)(02/04/26)
     IF gt_routput[] IS NOT INITIAL AND p_shonof = 'X'.
      MESSAGE s219(/psyng/sw) DISPLAY LIKE 'E'.
     ELSE.
      MESSAGE s174(/psyng/sw).
     ENDIF.
*End of Addition:HBHALLA(PN-18733)(02/04/26)
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.

  ENDIF.
ENDFORM.                    " reformat_output


FORM f4_orglvl USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
  EXPORTING
    i_cfg_set       = cfgset
 IMPORTING
   E_ORGLVL        = e_orglvl.
ENDFORM.
