REPORT /psyng/sw_095 MESSAGE-ID /psyng/sw.
TABLES : usr02, rfcdes, /psyng/function, agr_define,/psyng/swsodorgm.
TYPE-POOLS : slis.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/sw_113.
INCLUDE /psyng/sw_125.
INCLUDE /psyng/sw_095_top.
DATA :
  g_usercnt                TYPE i,
  gt_faobj_system          TYPE /psyng/sw_tab_sys_faobj,
  gt_ao_sys                TYPE /psyng/sw_tab_sys_ao,
  gf_cfg_set_enabled       TYPE flag,
  lt_rfcdes                TYPE TABLE OF rfcdes WITH HEADER LINE,
  lt_conflict_local        TYPE TABLE OF /psyng/conflict,
  lt_confdet_local         TYPE TABLE OF /psyng/confdet
                            WITH HEADER LINE,
  lt_functtran_local       TYPE TABLE OF /psyng/functtran,
  lt_faobj_local           TYPE TABLE OF /psyng/faobj2,
  lt_swsodorgm_local       TYPE TABLE OF /psyng/swsodorgm,
  lt_functran_no_enh_local
    TYPE TABLE OF /psyng/functtran,
  lt_tcodes_local          TYPE TABLE OF /psyng/sw_par_tcode_output,
  l_system_msg(80)         TYPE c,
  lt_uinfo                 TYPE TABLE OF /psyng/sw_uinfo_remote
                           WITH HEADER LINE,
  lt_user_mapping          TYPE  TABLE OF /psyng/sw_user_mapping,
  l_rfcdest                TYPE rfcdest,
  lt_role_removal_simu
    TYPE TABLE OF /psyng/sw_role_removal_simu,
  lt_role_addition_simu
    TYPE TABLE OF /psyng/sw_role_addition_simu,
  l_vrsio                  TYPE /psyng/swsodvers-vrsio,
  lt_user_range            TYPE TABLE OF /psyng/sw_sel_opts_xubname
                           WITH HEADER LINE,
  lt_class_range           TYPE TABLE OF /psyng/range_class,
  gt_uinfo_sorted          TYPE HASHED TABLE OF /psyng/sw_uinfo_remote
                           WITH UNIQUE KEY rfcdest bname,
  l_conf_number            TYPE i,
  g_warning_msg(1)         TYPE c,
  g_preconfig              TYPE /psyng/swcfgset-setid,
  lf_set_invalid           TYPE flag,
  lf_set_nocover           TYPE flag,
  lf_set_mismatch          TYPE flag,
  lf_include_local         TYPE flag,
  g_current_user           TYPE sy-uname. "C0700

FIELD-SYMBOLS :
  <uinfo> TYPE /psyng/sw_uinfo_remote,
  <map>   TYPE /psyng/sw_user_mapping.

*--Selection Screen
SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-006.
*--SE 3.2 - Verify users
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: userlist FOR usr02-bname,
                pclass FOR usr02-class,  "user group
                xusrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll.
*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

PARAMETERS: orgchk   AS CHECKBOX DEFAULT ' ' USER-COMMAND org.
SELECTION-SCREEN BEGIN OF LINE.
*  Only analyze remote systems
PARAMETERS : p_remonl AS CHECKBOX USER-COMMAND remo.
SELECTION-SCREEN COMMENT 3(45) text-179 FOR FIELD p_remonl .
SELECTION-SCREEN END OF LINE.
PARAMETERS :
  erroles AS CHECKBOX DEFAULT ' ' MODIF ID exe USER-COMMAND er1,
  excl_er AS CHECKBOX DEFAULT ' ' MODIF ID exe USER-COMMAND er2.

PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance. "Enhanced ruleset
PARAMETERS: showcomp AS CHECKBOX DEFAULT space.
SELECTION-SCREEN: END OF BLOCK exe.
SELECTION-SCREEN: BEGIN OF BLOCK cres WITH FRAME TITLE text-017.

SELECT-OPTIONS:  spfun FOR   /psyng/function-function,
                 busarea FOR /psyng/function-busarea,
                 owner   FOR /psyng/function-owner.


PARAMETERS:      sodvrsio LIKE /psyng/conflict-vrsio. "SOD Version
* Configuration Set Selection
PARAMETERS : cfgset   TYPE /psyng/seconfid MODIF ID con.

SELECT-OPTIONS orglvl  FOR /psyng/swsodorgm-abb
                                   MODIF ID exe.

SELECTION-SCREEN: END OF BLOCK cres.

SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME.
SELECTION-SCREEN COMMENT 1(50) text-h14 .
SELECTION-SCREEN INCLUDE BLOCKS b_sim.
SELECTION-SCREEN: END OF BLOCK sim_o.


SELECTION-SCREEN: BEGIN OF BLOCK pblk WITH FRAME TITLE text-007.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0'.
SELECTION-SCREEN: COMMENT 3(65) text-008.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 2(15) text-003.
PARAMETERS: pserver LIKE msxxlist-name. "server name (40 chars in 4.7)
SELECTION-SCREEN PUSHBUTTON  60(16) text-002 USER-COMMAND gpsv.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK pblk.

*--------SE 3.2 Enhancement to include Details level output---------*
SELECTION-SCREEN: BEGIN OF BLOCK detail WITH FRAME TITLE text-012.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: sum RADIOBUTTON GROUP out1 DEFAULT 'X' USER-COMMAND a.
SELECTION-SCREEN: COMMENT 4(30) text-013.

SELECTION-SCREEN: POSITION 35.
PARAMETERS: det RADIOBUTTON GROUP out1.              "Detailed output
SELECTION-SCREEN: COMMENT 37(30) text-014.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK detail.

*SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-001.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-019.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-020.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.


LOAD-OF-PROGRAM.
*--Check if Configuration Set functionality is enabled.
  se_config_param 'CFG_SET_ENABLED' gf_cfg_set_enabled.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    gf_cfg_set_enabled = 'X'.
  ELSE.
    CLEAR gf_cfg_set_enabled.
  ENDIF.


AT SELECTION-SCREEN.
  PERFORM check_input.

  IF sy-ucomm = 'REMO'.
    IF p_remonl = 'X'.
      IF xusrrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.


  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
    EXIT.
  ENDIF.
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'GPSV'.
    PERFORM get_server_name.
  ENDIF.

*--SE 3.2 - Verify Users
  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.
  CASE sy-ucomm.
    WHEN 'ER1'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR excl_er.
      ENDIF.
    WHEN 'ER2'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR erroles.
      ENDIF.
  ENDCASE.


  IF NOT gf_cfg_set_enabled IS INITIAL.
    IF sy-ucomm IS INITIAL.
*--Check Config Set
      IF p_remonl <> 'X'.
        lf_include_local = 'X'.
      ELSE.
        CLEAR lf_include_local.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
        EXPORTING
          i_setid         = cfgset
          i_vrsio         = sodvrsio
          if_show_warning = 'X'
          if_local_system = lf_include_local
        TABLES
          it_rfcdest      = xusrrfc.
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  IF gf_cfg_set_enabled = 'X' OR gf_cfg_set_enabled = 'Y'.
    IF cfgset IS INITIAL.
*--   default to the latest published configuration set (highest nr)
*      DATA e_vrsio TYPE /psyng/sodvrsio.
**Get sod version default
*      CALL FUNCTION '/PSYNG/SW_034'
*           IMPORTING
*                e_vrsio = e_vrsio.
      CALL FUNCTION '/PSYNG/SW_CGF_SET_DEFAULT'
        EXPORTING
          i_vrsio      = 'X'
          i_cfgvrsio   = sodvrsio
        IMPORTING
          e_config_set = cfgset.
    ENDIF.
  ENDIF.

  IF p_remonl = 'X'.
    IF xusrrfc[] IS INITIAL.
      MESSAGE w140(/psyng/sw) WITH
      'Please enter RFC destinations for remote analysis'(180).
    ENDIF.
  ENDIF.


  LOOP AT SCREEN.
    IF  screen-name CS 'S_CUID'.
      IF gf_central_uid = 'X'.
        screen-active    = 1.
      ELSE.
        screen-active    = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.

    IF ( screen-name CS 'ERROLES'
         OR
         screen-name CS 'EXCL_ER'
       )
        AND gf_er_inst IS INITIAL.
      screen-active = 0.
      MODIFY SCREEN.
    ENDIF.
    IF  screen-name = 'ORGLVL-LOW' OR screen-name = 'ORGLVL-HIGH'.
      IF orgchk = 'X'.
        screen-input = 1.
      ELSE.
        REFRESH : orglvl.
        screen-input = 0.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.


  ENDLOOP.

  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.

    ENDCASE.
*--Hide configuration set selection if not enabled
    IF gf_cfg_set_enabled IS INITIAL AND screen-name CS 'CFGSET'.
      screen-invisible = 1.
      screen-active    = 0.
      MODIFY SCREEN.
    ENDIF.

  ENDLOOP.




INITIALIZATION.
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
  PERFORM exelog.
  PERFORM get_initial_config.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-low.
  PERFORM f4_orglvl USING 'ORGLVL-LOW' CHANGING orglvl-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR orglvl-high.
  PERFORM f4_orglvl USING 'ORGLVL-HIGH' CHANGING orglvl-high .


START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-12/04/2024

  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-12/04/2024

  IF NOT gf_cfg_set_enabled IS INITIAL.
*--Check Config Set
    lf_include_local = 'X'.
    IF p_remonl = 'X'.
      CLEAR lf_include_local.
    ENDIF.
    CALL FUNCTION '/PSYNG/SW_CGF_SET_VALID'
      EXPORTING
        i_setid            = cfgset
        i_vrsio            = sodvrsio
        if_show_warning    = 'X'
        if_local_system    = lf_include_local
      IMPORTING
        ef_wrong_version   = lf_set_invalid
        ef_missing_system  = lf_set_nocover
        ef_system_mismatch = lf_set_mismatch
      TABLES
        it_rfcdest         = xusrrfc.
    IF lf_set_invalid  = 'X' OR
       lf_set_nocover  = 'X' .
      EXIT.
    ENDIF.
  ENDIF.
* BOC for C0766
  IF orgchk = 'X' AND g_orgchk IS INITIAL.
    g_orgchk = 'X'.
  ENDIF.
* EOC for C0766
  IF orgchk = 'X'
    OR g_orgchk IS NOT INITIAL. "C0766
    exelog sy-repid 'ORGCHECK'.
  ELSE.
    exelog sy-repid 'NO_ORGCHECK'.
  ENDIF.
*--Clear system filter buffer when a new analysis starts
  CALL FUNCTION '/PSYNG/SW_124'
    EXPORTING
      if_clear_buffer = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          too_many_options = 1
          OTHERS = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.

  IF exit_proc = 'Y'.
    program = sy-repid.
    SUBMIT (program)                         "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.

  CLEAR g_warning_msg.

*--Display information about parameters in job log
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid = program.


  CONCATENATE sy-sysid sy-mandt INTO g_rfcdes_local.
*-- Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT xusrrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

  REFRESH : gt_output[].
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.

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
*--Load Local SOD Matrix


    CALL FUNCTION '/PSYNG/SW_028'
      EXPORTING
        i_orgcheck         = g_orgchk "orgchk C0766
        i_config_set       = cfgset
        i_vrsio            = sodvrsio
        i_orphan_functions = 'X'
        if_analysis        = 'X'
      IMPORTING
        et_faobj_sys       = gt_faobj_system
        et_swsodorgm_sys   = gt_ao_sys
      TABLES
        et_conflict        = lt_conflict_local
        et_confdet         = lt_confdet_local
        et_functtran       = lt_functtran_local
        et_faobj           = lt_faobj_local
        et_swsodorgm       = lt_swsodorgm_local
        et_tcodes          = lt_tcodes_local
        et_functran_no_enh = lt_functran_no_enh_local
        it_rfcdest         = gt_rfcdest_anal.

*--Delete unwanted functions
    SORT lt_confdet_local BY functionid.
    DELETE ADJACENT DUPLICATES FROM lt_confdet_local COMPARING
functionid.
    LOOP AT lt_confdet_local.
      CLEAR lt_confdet_local-conid.
      READ TABLE gt_functions
      WITH KEY function = lt_confdet_local-functionid.
      IF sy-subrc <> 0.
        DELETE lt_functtran_local WHERE
        functionid = lt_confdet_local-functionid.
        DELETE lt_faobj_local WHERE
        funid = lt_confdet_local-functionid.
        DELETE lt_confdet_local WHERE
        functionid = lt_confdet_local-functionid.
      ELSE.
        IF lt_confdet_local-conid IS INITIAL.
          l_conf_number = l_conf_number + 1.
          lt_confdet_local-conid = l_conf_number + 1.
          MODIFY lt_confdet_local.
        ENDIF.
      ENDIF.
    ENDLOOP.
    DELETE ADJACENT DUPLICATES FROM lt_confdet_local
           COMPARING functionid.

*--Get user information
    PERFORM get_user_info
      TABLES
        userlist
        pclass
        lt_uinfo
        gt_rfcdest_anal
        lt_user_mapping
        usrtype
       USING
         validusr
         exlckusr
         outvdate
         ' '
         ' '
         sodvrsio
         p_remonl.
    SORT lt_user_mapping BY  source_bname target_rfc.
    SORT lt_uinfo BY rfcdest bname.
    DELETE ADJACENT DUPLICATES FROM lt_uinfo.

    gt_uinfo_sorted[] = lt_uinfo[].
    IF byrsimu = 'X'.
*--prepare table for role removal simulation
      PERFORM prepare_role_removal_simu
              TABLES gt_role_removal_simu.
    ENDIF.

    IF bysimu = 'X'.
*--   prepare table for role addition simulation
      PERFORM prepare_role_addition_simu
              TABLES gt_role_addition_simu.
    ENDIF.

**----SE 3.2 - Validation
    PERFORM validate_other_fields.
*-- Simulation Before and After Logic
    IF det NE 'X'.
      IF bysimu = 'X' OR byrsimu = 'X'.
        PERFORM before_after_simulation
        TABLES gt_role_removal_simu
               gt_role_addition_simu.
        EXIT.
      ENDIF.
    ENDIF.
  ENDIF.
  PERFORM data_processing.

  IF det EQ 'X'.
* BOC for C0766
    IF g_orgchk IS NOT INITIAL AND orgchk IS INITIAL
                               AND lt_outdet[] IS NOT INITIAL.
      DELETE lt_outdet[] WHERE org_abb IS NOT INITIAL
                            OR ( von IS INITIAL AND bis IS INITIAL ).
    ENDIF.
* EOC for C0766
    MESSAGE s176(/psyng/sw).
    PERFORM output_using_alv_det.
  ELSE.
    PERFORM output_using_alv_sum.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  data_processing
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_processing.
  DATA :
    lt_confdet_sys         TYPE TABLE OF /psyng/confdet,
    lt_functtran_sys       TYPE TABLE OF /psyng/functtran,
    lt_faobj_sys           TYPE TABLE OF /psyng/faobj2,
    l_system               TYPE /psyng/rfcname,
    ls_faobj_system        TYPE /psyng/sw_sys_faobj,
    ls_ao_sys              TYPE /psyng/sw_sys_ao,
lt_simu_roleauth       TYPE TABLE OF /psyng/userauth
                         WITH HEADER LINE,
lt_simu_roletcode      TYPE TABLE OF /psyng/usertcode
                           WITH HEADER LINE,
lt_simu_roleprof       TYPE TABLE OF /psyng/userprof
                          WITH HEADER LINE,
lt_simu_roleauth_part  TYPE TABLE OF /psyng/userauth
                          WITH HEADER LINE,
lt_simu_roletcode_part TYPE TABLE OF /psyng/usertcode
                          WITH HEADER LINE,
lt_role_removal_simu   TYPE TABLE OF /psyng/sw_role_removal_simu
                                                  WITH HEADER LINE,
lt_role_addition_simu  TYPE TABLE OF /psyng/sw_role_addition_simu.
  FIELD-SYMBOLS: <fs_role_addition_simu>
                 TYPE /psyng/sw_role_addition_simu.

  IF det NE 'X'.
*--Processing for Summary Output
*    LOOP AT lt_rfcdes.
    LOOP AT gt_rfcdest_anal.

      REFRESH lt_user_range.
      REFRESH gt_res.
      REFRESH gt_uinfo_remote.
      lt_user_range-sign   = 'I'.
      lt_user_range-option = 'EQ'.
      LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
        LOOP AT lt_user_mapping ASSIGNING <map>
        WHERE target_rfc = gt_rfcdest_anal-rfcoptions AND
        source_bname = <uinfo>-bname.
          lt_user_range-low = <uinfo>-bname.
          COLLECT lt_user_range.
        ENDLOOP.
      ENDLOOP.

      IF lt_user_range[] IS INITIAL.
        CONTINUE.
      ENDIF.

      FREE : lt_role_removal_simu.

*--Filter Functions by system
      l_system = gt_rfcdest_anal-rfcoptions.
      lt_functtran_sys[] = lt_functtran_local[].
      lt_confdet_sys[]   = lt_confdet_local[].
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
          i_vrsio       = sodvrsio
        TABLES
          it_functtran  = lt_functtran_sys
          it_faobj      = lt_faobj_sys
          it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options = 1
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
      CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
        DESTINATION gt_rfcdest_anal-rfcdest
        EXPORTING
          i_vrsio               = sodvrsio
          i_config_set          = cfgset
          i_enh                 = p_enhanc
          i_org_check           = g_orgchk "orgchk C0766
          i_wp                  = wp
          i_validuser           = validusr
          i_exlckusr            = exlckusr
          i_outvdate            = outvdate
          i_allug               = 'X'
          i_xstb_fm             = 'X'
          i_er_roles            = erroles
          i_exclude_er_roles    = excl_er
        TABLES
          it_users              = lt_user_range
          et_output             = gt_res
          et_enh_fun            = gt_enh_fun
          it_simu_role_rfc      = simuagrs
*          pass contents of local SOD matrix to remote system
          it_conflict           = lt_conflict_local
          it_confdet            = lt_confdet_sys
          it_functtran          = lt_functtran_sys
          it_faobj              = lt_faobj_sys
          it_swsodorgm          = ls_ao_sys-swsodorgm[]
          it_tcodes             = lt_tcodes_local
          it_functran_no_enh    = lt_functran_no_enh_local
          it_uinfo              = gt_uinfo_remote
          it_simu_add_roletcode = lt_roletcode
          it_simu_add_roleauth  = lt_roleauth
          it_simu_role_removal  = lt_role_removal_simu
        EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e02
      gt_rfcdest_anal-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e02
            gt_rfcdest_anal-rfcdest.
        ENDCASE.
      ENDIF.
      PERFORM reformat_output USING gt_rfcdest_anal.
    ENDLOOP.
    IF NOT p_remonl = 'X'.
      REFRESH lt_user_range.
      REFRESH gt_res.
      REFRESH gt_uinfo_remote.
      lt_user_range-sign   = 'I'.
      lt_user_range-option = 'EQ'.
      LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
        LOOP AT lt_user_mapping ASSIGNING <map>
        WHERE target_rfc = l_rfcdest AND
        source_bname = <uinfo>-bname.
          lt_user_range-low = <uinfo>-bname.
          COLLECT lt_user_range.
        ENDLOOP.
      ENDLOOP.

      IF NOT lt_user_range[] IS INITIAL.

*--Filter Functions by system
        CONCATENATE sy-sysid sy-mandt INTO l_system.
        lt_functtran_sys[] = lt_functtran_local[].
        lt_faobj_sys[]     = lt_faobj_local[].
        lt_confdet_sys[]   = lt_confdet_local[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
            if_functions  = 'X'
            i_system      = l_system
            i_application = 'SAP'
            i_vrsio       = sodvrsio
          TABLES
            it_functtran  = lt_functtran_sys
            it_faobj      = lt_faobj_sys
            it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.


        CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
          EXPORTING
            i_vrsio               = sodvrsio
            i_config_set          = cfgset
            i_enh                 = p_enhanc
            i_org_check           = g_orgchk "orgchk C0766
            i_wp                  = wp
            i_validuser           = validusr
            i_exlckusr            = exlckusr
            i_outvdate            = outvdate
            i_allug               = 'X'
*--Dhorions 2014/08/30 - Don't update function scan table
            i_xstb_fm             = 'X'
            i_remote_only         = p_remonl
            i_er_roles            = erroles
            i_exclude_er_roles    = excl_er
          TABLES
            it_users              = lt_user_range
            et_output             = gt_res
            et_enh_fun            = gt_enh_fun
            it_simu_role_rfc      = simuagrs
*          pass contents of local SOD matrix to remote system
            it_conflict           = lt_conflict_local
            it_confdet            = lt_confdet_sys
            it_functtran          = lt_functtran_sys
            it_faobj              = lt_faobj_sys
            it_swsodorgm          = lt_swsodorgm_local
            it_tcodes             = lt_tcodes_local
            it_functran_no_enh    = lt_functran_no_enh_local
            it_uinfo              = gt_uinfo_remote
            it_simu_add_roletcode = lt_roletcode
            it_simu_add_roleauth  = lt_roleauth
            it_simu_role_removal  = lt_role_removal_simu.
        CLEAR gt_rfcdest_anal.
        gt_rfcdest_anal-rfcdest = 'LOCAL'.
        gt_rfcdest_anal-rfcoptions = l_rfcdest.
        PERFORM reformat_output USING gt_rfcdest_anal.
      ENDIF.
    ENDIF.

    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s190(/psyng/sw).
    ELSE.
      IF gt_output[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
        EXIT.
      ELSE.
        MESSAGE s176(/psyng/sw).
      ENDIF.
    ENDIF.


*------------------------SE 3.2 Change------------------------------*
  ELSEIF det EQ 'X'.

*-- Load the all simulated role content on local system only as rfc we
*-- are analysing might not be defined on other remote systems
*--- Due to this reason loading simulations roles is commented out from
*-- FM

    IF bysimu = 'X'.
      PERFORM load_simulated_role_content
       TABLES
         gt_role_addition_simu
         lt_simu_roleauth
         lt_simu_roletcode
         lt_functtran_local
         lt_faobj_local
         gt_rfcdest.
    ENDIF.

    IF p_remonl NE 'X'.
      gt_rfcdest_anal-rfcoptions = g_rfcdes_local.
      gt_rfcdest_anal-rfcdest    = 'LOCAL'.
      APPEND gt_rfcdest_anal.
    ENDIF.

    IF NOT gt_rfcdest_anal[] IS INITIAL.
      LOOP AT gt_rfcdest_anal WHERE rfcdest <> 'LOCAL'.
        MESSAGE s398(00) WITH  'Starting Remote Analysis on : '(109)
        gt_rfcdest_anal-rfcoptions.
        COMMIT WORK.
*--Prepare User Table
        FREE : lt_bnames.
        lt_bnames-sign = 'I'.
        lt_bnames-option = 'EQ'.

        LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
          LOOP AT lt_user_mapping ASSIGNING <map>
          WHERE target_rfc = gt_rfcdest_anal-rfcoptions AND
          source_bname = <uinfo>-bname.
            lt_bnames-low = <uinfo>-bname.
            APPEND lt_bnames.
          ENDLOOP.
        ENDLOOP.
        IF lt_bnames[] IS INITIAL.
          CONTINUE.
        ENDIF.

        FREE : lt_role_removal_simu.
        LOOP AT gt_role_removal_simu
           WHERE rfcdest = gt_rfcdest_anal-rfcdest.
          lt_role_removal_simu = gt_role_removal_simu.
          CLEAR lt_role_removal_simu-rfcdest.
          APPEND lt_role_removal_simu.
        ENDLOOP.

        FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
        LOOP AT lt_simu_roleauth
            WHERE rfcdest =  gt_rfcdest_anal-rfcoptions.
          APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
        ENDLOOP.

        LOOP AT lt_simu_roletcode
             WHERE rfcdest = gt_rfcdest_anal-rfcoptions.
          APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
        ENDLOOP.

*--If in simulation source or target system are same as that
*-- of remote system to be analyzed; then clear
*-- the source and target as it will be local system
        lt_role_addition_simu[] = gt_role_addition_simu[].
        LOOP AT lt_role_addition_simu ASSIGNING <fs_role_addition_simu>.
          IF <fs_role_addition_simu>-source_rfcdest
             = gt_rfcdest_anal-rfcdest.
            CLEAR <fs_role_addition_simu>-source_rfcdest.
          ENDIF.
          IF <fs_role_addition_simu>-target_rfcdest
             = gt_rfcdest_anal-rfcdest.
            CLEAR <fs_role_addition_simu>-target_rfcdest.
          ENDIF.
        ENDLOOP.

*--Filter Functions by system
        l_system = gt_rfcdest_anal-rfcoptions.
        lt_functtran_sys[] = lt_functtran_local[].
        lt_confdet_sys[]   = lt_confdet_local[].
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
            i_vrsio       = sodvrsio
          TABLES
            it_functtran  = lt_functtran_sys
            it_faobj      = lt_faobj_sys
            it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options = 1
             OTHERS           = 2 .
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
        CALL FUNCTION '/PSYNG/SW_FUNC_USER_DETAIL'
          DESTINATION gt_rfcdest_anal-rfcdest
          EXPORTING
            i_bysimu              = bysimu
            i_validusr            = validusr
            i_outvdate            = outvdate
            i_exlckusr            = exlckusr
            i_orgchk              = g_orgchk "orgchk C0766
            i_sodvrsio            = sodvrsio
            i_config_set          = cfgset
            i_enhanc              = p_enhanc
            i_advanced_role_simu  = ' '
            i_xmc                 = 'X'
*           i_remote_only         = p_remonl
            i_showcomp            = showcomp
            i_er_roles            = erroles
            i_exclude_er_roles    = excl_er
          TABLES
            it_bname              = lt_bnames
            et_outputdet          = lt_outdet_temp
            it_orglvl             = orglvl
            it_conflict           = lt_conflict_local
            it_confdet            = lt_confdet_sys
            it_functtran          = lt_functtran_sys
            it_faobj              = lt_faobj_sys
            it_swsodorgm          = ls_ao_sys-swsodorgm[]
            it_simu_role_removal  = lt_role_removal_simu
            it_simu_role_addition = lt_role_addition_simu
            it_simu_add_roletcode = lt_simu_roletcode_part
            it_simu_add_roleauth  = lt_simu_roleauth_part
          EXCEPTIONS
* BOC for C0583
*           user_cancelled        = 1
*           OTHERS                = 2.
*        IF sy-subrc <> 0.
*          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*        ENDIF.
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1 OR 2.
              MESSAGE e398(00) WITH
              text-e02
              gt_rfcdest_anal-rfcdest
              l_system_msg.
            WHEN 3.
              MESSAGE e398(00) WITH
              text-e02
              gt_rfcdest_anal-rfcdest.
          ENDCASE.
        ENDIF.
* EOC for C0583
        APPEND LINES OF lt_outdet_temp TO lt_outdet.
        REFRESH lt_outdet_temp.
      ENDLOOP.


*--Prepare User Table
      FREE : lt_bnames.
      lt_bnames-sign = 'I'.
      lt_bnames-option = 'EQ'.
      LOOP AT gt_rfcdest_anal WHERE rfcdest = 'LOCAL'.
        MESSAGE s398(00) WITH  'Starting Remote Analysis on : '(109)
        gt_rfcdest_anal-rfcoptions.
        COMMIT WORK.

        LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
          LOOP AT lt_user_mapping ASSIGNING <map>
          WHERE target_rfc = l_rfcdest AND
          source_bname = <uinfo>-bname.
            lt_bnames-low = <uinfo>-bname.
            APPEND lt_bnames.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
      IF lt_bnames[] IS INITIAL.
        EXIT.
      ENDIF.
      FREE : lt_role_removal_simu.
      LOOP AT gt_role_removal_simu
      WHERE rfcdest = gt_rfcdest_anal-rfcdest OR
            rfcdest = ''.
        APPEND gt_role_removal_simu TO lt_role_removal_simu.
      ENDLOOP.
      FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
      LOOP AT lt_simu_roleauth
      WHERE rfcdest =  gt_rfcdest_anal-rfcoptions OR
            rfcdest = ''.
        APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
      ENDLOOP.

      LOOP AT lt_simu_roletcode
      WHERE rfcdest = gt_rfcdest_anal-rfcoptions OR
             rfcdest = ''.
        APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
      ENDLOOP.

*--Filter Functions by system
      CONCATENATE sy-sysid sy-mandt INTO l_system.
      lt_functtran_sys[] = lt_functtran_local[].
      lt_faobj_sys[]     = lt_faobj_local[].
      lt_confdet_sys[]   = lt_confdet_local[].
      CALL FUNCTION '/PSYNG/SW_124'
        EXPORTING
          if_functions  = 'X'
          i_system      = l_system
          i_application = 'SAP'
          i_vrsio       = sodvrsio
        TABLES
          it_functtran  = lt_functtran_sys
          it_faobj      = lt_faobj_sys
          it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          too_many_options = 1
          OTHERS = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      "(++)EOC UMITTAL SE VF scan-25/11/2024.


      CALL FUNCTION '/PSYNG/SW_FUNC_USER_DETAIL'
        EXPORTING
          i_bysimu              = bysimu
          i_validusr            = validusr
          i_orgchk              = g_orgchk "orgchk C0766
          i_sodvrsio            = sodvrsio
          i_config_set          = cfgset
          i_enhanc              = p_enhanc
          i_remote_only         = p_remonl
          i_er_roles            = erroles
          i_xmc                 = 'X'
          i_showcomp            = showcomp
          i_exclude_er_roles    = excl_er
        TABLES
          it_bname              = lt_bnames
          et_outputdet          = lt_outdet_temp
          it_orglvl             = orglvl
          it_conflict           = lt_conflict_local
          it_confdet            = lt_confdet_sys
          it_functtran          = lt_functtran_sys
          it_faobj              = lt_faobj_sys
          it_swsodorgm          = lt_swsodorgm_local
          it_simu_role_removal  = lt_role_removal_simu
          it_simu_role_addition = gt_role_addition_simu
          it_simu_add_roletcode = lt_simu_roletcode_part
          it_simu_add_roleauth  = lt_simu_roleauth_part
        EXCEPTIONS
          user_cancelled        = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      APPEND LINES OF lt_outdet_temp TO lt_outdet.
      REFRESH lt_outdet_temp.
    ENDIF.
    SORT lt_outdet BY bname functionid org_abb agr_name comp_agr
        rfcdest tcode objct auth field von profile risk imp.
    DELETE ADJACENT DUPLICATES FROM lt_outdet
    COMPARING bname functionid org_abb agr_name
              comp_agr rfcdest tcode objct auth
              field von profile.

*--BOC AKUMAR C1266
*--Commented the code
*--Limit based on org level
*    IF ( orgchk = 'X'
*      OR g_orgchk = 'X' ) "C0766
*      AND NOT orglvl[] IS INITIAL.
*      DATA: BEGIN OF lt_org_funcs OCCURS 0,
*              bname      LIKE lt_outdet_temp-bname,
*              functionid LIKE lt_outdet_temp-functionid,
*              org_abb    LIKE lt_outdet_temp-org_abb,
*            END OF lt_org_funcs.
*
*      lt_outdet_temp[] = lt_outdet[].
*      SORT lt_outdet_temp BY bname functionid org_abb.
*      LOOP AT lt_outdet_temp WHERE org_abb IN orglvl OR
*                                   org_abb = '*'.
*        MOVE-CORRESPONDING lt_outdet_temp TO lt_org_funcs.
*        APPEND lt_org_funcs.
*      ENDLOOP.
*      SORT lt_org_funcs BY bname functionid.
*      LOOP AT lt_outdet.
*        READ TABLE lt_org_funcs WITH KEY bname = lt_outdet-bname
*                                      functionid = lt_outdet-functionid
*                                  BINARY SEARCH TRANSPORTING NO FIELDS.
*        CHECK sy-subrc NE 0.
*        DELETE lt_outdet.
*      ENDLOOP.
*    ENDIF.
*--EOC AKUMAR C1266
  ENDIF.
ENDFORM.                    " data_processing


*&---------------------------------------------------------------------*
*&      Form  load_user_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USER_RFC  text
*      -->P_ET_RETURN  text
*----------------------------------------------------------------------*
FORM load_user_rfc
    TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  .
  DATA : l_rfcdest        TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys      TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  IF NOT it_user_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_user_rfc.
  ENDIF.
*--Get sysid and mandt into field RFCOPTIONS
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
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest.
      ENDCASE.
*      DELETE et_rfcdes.
*      CONTINUE.

      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
*  SORT et_rfcdes BY rfcoptions.
*  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
*--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
  AND rfcdest <> 'LOCAL'.

ENDFORM.                    " validate_user_rfc


*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.
  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = curr_variant
      vari_desc     = vari_desc
    TABLES
      vari_contents = vari_contents
      vari_text     = vari_text
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

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = 'Security Weaver : User Func Scan'(069).
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
      EXPORTING
        in_jobname  = l_jobname
        in_repvarnt = curr_variant
        in_report   = curr_report.
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
FORM get_next_variant_id.
  DATA: oldnumber(7)   TYPE n, oldnumber_c(7).

  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

*  SELECT variant INTO variant FROM varid WHERE report = sy-repid AND
*                           variant LIKE '/PSYNG/%'
*    AND NOT variant LIKE '/PSYNG/Z%'
*  ORDER BY variant DESCENDING.
*    oldnumber = variant+7(7).
*    EXIT.
*  ENDSELECT.
*  IF sy-subrc NE 0.
*    variant = '/PSYNG/0000000'.
*  ELSE.
*    oldnumber = oldnumber + 1.
*    MOVE oldnumber TO oldnumber_c.
*    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
*  ENDIF.

*C017 Odubey 29/11/2021
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
    EXPORTING
      i_report        = sy-repid
   IMPORTING
     e_variant       = variant.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.

ENDFORM.                    " get_next_variant_id

*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  DATA: lt_irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE,
        l_repid      TYPE sy-repid.
  l_repid = sy-repid.
  REFRESH : vari_contents.
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid       = l_repid
      if_no_logging = 'X'
    TABLES
      et_params     = vari_contents.


ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
      exelog = exelog.
  COMMIT WORK.


ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE,
        l_tabname  TYPE dd02l-tabname,
        swconfig   TYPE /psyng/swconfig.

*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
    IMPORTING
      e_vrsio = sodvrsio.
*--Check if ER is installed
  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'.            "#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES'.
        screen-invisible = 0.
        screen-invisible = 1.
        screen-active   = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ELSE.
    gf_er_inst = 'X'.
    se_config_param 'DFLT_INCLUDE_ER' swconfig-value.
    IF swconfig-value = 'Y'.
      erroles = 'X'.
    ELSE.
      erroles = ' '.
    ENDIF.

  ENDIF.

**Valid & Dialog Users only
*  CLEAR swconfig.
*  SELECT SINGLE * FROM /psyng/swconfig INTO swconfig WHERE
*         param = 'DFLT_VALID_DIALOG'.
*  IF swconfig-value = 'Y'.
*    validusr = 'X'.
*  ELSEIF swconfig-value = 'N'.
*    validusr = ' '.
*  ENDIF.
*  CLEAR swconfig.


*--Central User ID search Help
*--Check what FM is configured for Central Userid information
  DATA : ls_fmname TYPE rs38l_fnam.
  se_config_param 'SW_CENTRAL_USR_FM' swconfig-value.
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
* BOC for C0766
  se_config_param 'CONSIDER_ORG_AREA' swconfig-value.
  IF swconfig-value EQ 'Y'.
    g_orgchk = 'X'.
  ELSE.
    g_orgchk = ' '.
  ENDIF.
* EOC for C0766
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  output_using_alv_sum
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_using_alv_sum.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv,        "For ALV call
        alv_layout     TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl  TYPE lvc_title.                  "For ALV call
  DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
  DATA: ls_variant TYPE disvariant.

  program = sy-repid.
*--Create fieldcatalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'GT_OUTPUT'
      i_inclname         = program
*     i_structure_name   = '/PSYNG/SW_OUTPUT_ORG'
    CHANGING
      ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Modify field catalog
  wa_fieldcat_alv-key = ' '.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      key
                   WHERE
                      fieldname NE space.
*--Company short name is not displayed, only used for
*  mitigation auditor verification
  CLEAR wa_fieldcat_alv.
**  Hiding as same as of SOD analysis report
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    no_out
                   WHERE
                      fieldname = 'COMPANY'.
  CLEAR wa_fieldcat_alv.
** SE 3.1 making compshort visible same as of SOD user analysis report
*  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE fieldname = 'COMPSHORT'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-184.
  wa_fieldcat_alv-seltext_m      = text-184.
  wa_fieldcat_alv-seltext_s      = text-184.
  wa_fieldcat_alv-reptext_ddic   = text-184.



  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'DEPARTMENT'.




  IF xusrrfc[] IS INITIAL.
    wa_fieldcat_alv-no_out = '1'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-170.
  wa_fieldcat_alv-seltext_m      = text-170.
  wa_fieldcat_alv-seltext_s      = text-170.
  wa_fieldcat_alv-lowercase      = 'X'.
  IF xusrrfc[] IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      lowercase
                   WHERE
                      fieldname = 'RFCDEST'.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l      = text-176.
  wa_fieldcat_alv-seltext_m      = text-176.
  wa_fieldcat_alv-seltext_s      = text-176.
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.

*----Hotspot on Function ID
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'FUNID'.

  IF bysimu <> 'X' AND byrsimu <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
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

  wa_fieldcat_alv-seltext_l      = 'Before Simulation'(185).
  wa_fieldcat_alv-seltext_m      = 'Before Simulation'(185).
  wa_fieldcat_alv-seltext_s      = 'Before Simulation'(185).
  wa_fieldcat_alv-hotspot        = 'X' .
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
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

  wa_fieldcat_alv-seltext_l      = 'After Simulation'(186).
  wa_fieldcat_alv-seltext_m      = 'After Simulation'(186).
  wa_fieldcat_alv-seltext_s      = 'After Simulation'(186).
  wa_fieldcat_alv-hotspot        = 'X' .
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
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

  IF gf_central_uid IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'CENTRAL_UID'.

  ENDIF.
*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.

  wa_fieldcat_alv-seltext_l      = 'Emergency Repair'(182).
  wa_fieldcat_alv-seltext_m      = 'Emergency Repair'(182).
  wa_fieldcat_alv-seltext_s      = 'Emergency Repair'(182).
  wa_fieldcat_alv-checkbox       = 'X'.
  wa_fieldcat_alv-just           = 'X'.

  IF erroles <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'ER'.



  wa_fieldcat_alv-seltext_l      = 'Org Area'(183).
  wa_fieldcat_alv-seltext_m      = 'Org Area'(183).
  wa_fieldcat_alv-seltext_s      = 'Org Area'(183).
  wa_fieldcat_alv-checkbox       = 'X'.

  IF orgchk <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
  ELSE.
    CLEAR wa_fieldcat_alv-no_out.
  ENDIF.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      no_out
                   WHERE
                      fieldname = 'ORG_ABB'.

*--Create Sort Table
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'COMPANY'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'COMPSHORT'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DEPARTMENT'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CENTRAL_UID'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNID'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'ORG_ABB'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.



  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SIMU'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'ER'.
  l_sort-tabname =  'GT_OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.



*--Prepare layout
  CONCATENATE sy-title text-093 sodvrsio
              INTO sy-title SEPARATED BY space.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_top_of_page   = 'USER_TOP_OF_PAGE'
      i_grid_title             = sy-title
      i_callback_program       = program
      i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      it_sort                  = isort
      i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUMRY'
      is_layout                = alv_layout
      it_fieldcat              = i_fieldcat_alv
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " output_using_alv_sum

*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status_summary USING it_extab TYPE slis_t_extab.
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  SET PF-STATUS 'SW_095' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary

*&---------------------------------------------------------------------*
*&      Form  user_double_click_on_sumry
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.
  DATA: functionid TYPE slis_selfield-value,
        l_rsimu    TYPE flag.

  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE is_selfield-fieldname.

    WHEN 'SIMU_AFTER'.
      READ TABLE gt_output INDEX is_selfield-tabindex.
      IF gt_output-simu_after <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
         'This function doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11)
         .
        EXIT.
      ELSE.
        READ TABLE gt_output INDEX is_selfield-tabindex.
        CHECK sy-subrc = 0.
        PERFORM function_detail_analysis.
        EXIT.
      ENDIF.

    WHEN 'SIMU_BEFORE'.
      READ TABLE gt_output INDEX is_selfield-tabindex.
      IF gt_output-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This function didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE gt_output INDEX is_selfield-tabindex.
        CHECK sy-subrc = 0.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.
        PERFORM function_detail_analysis.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.

        EXIT.
      ENDIF.



    WHEN 'FUNID'.
      READ TABLE gt_output INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF gt_output-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
             'This function doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      IF gt_output-rfcdest = g_rfcdes_local.
      ELSE.
        p_remonl = 'X'.
      ENDIF.

      PERFORM function_detail_analysis.
      CLEAR p_remonl.
  ENDCASE.






ENDFORM.

*---------------------------------------------------------------------*
*       FORM user_top_of_page                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM user_top_of_page.
  DATA: header               TYPE slis_t_listheader,
        wa                   TYPE slis_listheader,
        l_exedate            TYPE char10,
        l_exetime(8)         TYPE c,
        l_c_tusercount(6)    TYPE c,
        l_c_usercount(6)     TYPE c,
        l_c_averagecon(4)    TYPE c,
        l_c_beforesimucon(6) TYPE c,
        l_c_totalcon(6)      TYPE c,
        alv_grid_titl2       TYPE lvc_title,
        ls_cfg_set           TYPE /psyng/swcfgset,
        l_str                TYPE string,
        l_int                TYPE i,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

  STATICS :
    l_msg_displayed  TYPE flag,
    l_totals_counted TYPE flag,
    l_usercount      TYPE i,    "Progress indicator flag
    l_conflictcount  TYPE i,
    l_concount_bs    TYPE i, "before simu
    l_averagecon     TYPE i,
    lt_usercount     LIKE TABLE OF gt_output,
    lt_output_temp   LIKE TABLE OF gt_output WITH HEADER LINE.

  lt_output_temp[] = gt_output[].
  SORT lt_output_temp BY rfcdest bname funid.
  DELETE ADJACENT DUPLICATES FROM lt_output_temp
  COMPARING rfcdest bname funid.
  IF l_totals_counted IS INITIAL.
    LOOP AT lt_output_temp.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF lt_output_temp-simu_after = 'X'.
          l_conflictcount = l_conflictcount + 1.
        ENDIF.
        IF lt_output_temp-simu_before = 'X'.
          l_concount_bs = l_concount_bs + 1.
        ENDIF.
      ELSE.
        l_conflictcount = l_conflictcount + 1.
      ENDIF.
    ENDLOOP.
    l_usercount = g_usercnt.
    FREE : lt_usercount, lt_output_temp.
    l_averagecon =  l_conflictcount / l_usercount.
    l_totals_counted = 'X'.
  ENDIF.
  l_c_tusercount    = l_usercount.
  l_c_usercount     = l_usercount.
  l_c_averagecon    = l_averagecon.
  l_c_beforesimucon = l_concount_bs.
  l_c_totalcon      = l_conflictcount.

*TITLE AREA
  IF det NE 'X'.
    wa-typ =  'H'.
    wa-info = 'Function User Analysis Results Summary'(h01).
    APPEND wa TO header.
  ELSE.
    wa-typ =  'H'.
    wa-info = 'Function User Analysis Results Details'(h09).
    APPEND wa TO header.
  ENDIF.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.                        "#EC SAST_CI_GEN_CHECK
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*--Configuration Set
  IF gf_cfg_set_enabled = 'X'.
    SELECT SINGLE * FROM /psyng/swcfgset INTO ls_cfg_set
    WHERE setid = cfgset.
    wa-typ  = 'S'.
    wa-key  = 'Configuration Set:'(h32).
    l_int = cfgset.
    l_str = l_int.
    CONDENSE l_str.
    CONCATENATE l_str ' : '
    ls_cfg_set-description INTO wa-info SEPARATED BY space.
    APPEND wa TO header.
    wa-key  = 'Config Set Published:'(h33).
    IF ls_cfg_set-published = 'X'.
      wa-info = 'Yes'(h34).
    ELSE.
      wa-info = 'No'(h35).
    ENDIF.
    APPEND wa TO header.
    wa-key  = 'Config Set Changed :'(h36).
    WRITE ls_cfg_set-change_date TO wa-info.
    CONCATENATE wa-info 'by'(h37) ls_cfg_set-change_user
    INTO wa-info SEPARATED BY space.
    APPEND wa TO header.

  ENDIF.

*Date
  wa-typ = 'S'.
  wa-key = 'User Date & System:'(h08).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
*  CONCATENATE sy-uname text-h11 l_exedate l_exetime
  CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
  CONCATENATE g_current_user text-h11 l_exedate l_exetime "C0700
          text-199 l_systemid   INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

*--Averages info
  CONCATENATE  l_c_tusercount 'user(s) analyzed.'(h03)
               'Avg'(h04)
               l_c_averagecon
               'Function(s) in'(h05)
                l_c_usercount
               'user(s).'(h06)
              INTO alv_grid_titl2 SEPARATED BY space.
  CONDENSE alv_grid_titl2.
  wa-typ = 'S'.
  wa-key = 'Summary'(h07).
  wa-info = alv_grid_titl2.
  APPEND wa TO header.


  IF bysimu = 'X' OR byrsimu = 'X'.
*--Before Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'Before simulation'(h38).
    CONCATENATE l_c_beforesimucon 'Functions'(h40)
    INTO wa-info SEPARATED BY space .
    APPEND wa TO header.
*--After Simulation Numbers
    wa-typ  = 'S'.
    wa-key  = 'After simulation'(h39).
    CONCATENATE l_c_totalcon 'Functions'(h40)
    INTO wa-info SEPARATED BY space .
    APPEND wa TO header.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = header
      i_logo             = 'Z_3SW_LOGO_JPG'.

*  gt_output[] = lt_output_temp[].
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  reformat_output
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM reformat_output USING i_rfcdes TYPE rfcdes.
  FIELD-SYMBOLS : <in> TYPE /psyng/sw_output_org.
  DATA : ls_output        LIKE LINE OF gt_output,
        lt_uinfo         TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
        l_system_msg(80) TYPE c.
  SORT gt_uinfo_remote.
  DELETE ADJACENT DUPLICATES FROM gt_uinfo_remote COMPARING ALL FIELDS.

*--Get user information for all analyzed users.
  LOOP AT gt_uinfo_remote." WHERE rfcdest = i_rfcdes-rfcoptions..
    MOVE-CORRESPONDING gt_uinfo_remote TO lt_uinfo.
    APPEND lt_uinfo.
    ADD 1 TO g_usercount.
  ENDLOOP.

  CHECK NOT lt_uinfo[] IS INITIAL.
  IF i_rfcdes-rfcdest IS INITIAL
  OR i_rfcdes-rfcdest = 'LOCAL'.
*--Local
    CONCATENATE sy-sysid sy-mandt INTO i_rfcdes-rfcoptions.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
      EXPORTING
        i_name_only     = 'X'
        i_mr_company    = 'X'
        i_mr_department = 'X'
        i_central_uid   = 'X'
      TABLES
        sw_uinfo        = lt_uinfo.
  ELSE.
*--Remote
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
      DESTINATION i_rfcdes-rfcdest
      EXPORTING
        i_name_only           = 'X'
        i_mr_company          = 'X'
        i_mr_department       = 'X'
        i_central_uid         = 'X'
      TABLES
        sw_uinfo              = lt_uinfo
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          i_rfcdes-rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          i_rfcdes-rfcdest.
      ENDCASE.
    ENDIF.
    .

  ENDIF.

*--Limit based on org level
  IF orgchk = 'X' AND NOT orglvl[] IS INITIAL.
    DELETE gt_res WHERE NOT org_abb IN orglvl.
*    AND NOT org_abb = '*'.
  ENDIF.



  LOOP AT gt_res ASSIGNING <in> WHERE rfcdest = i_rfcdes-rfcoptions..
    READ TABLE lt_uinfo WITH KEY bname = <in>-bname.
    ls_output-class       = lt_uinfo-class.
    ls_output-department  = lt_uinfo-department.
    ls_output-central_uid = lt_uinfo-central_uid.
    ls_output-bname       = lt_uinfo-bname.
    ls_output-name_text   = lt_uinfo-name_text.
    ls_output-company     = lt_uinfo-company.
    ls_output-compshort   = lt_uinfo-company.
    ls_output-rfcdest     = i_rfcdes-rfcoptions.
    ls_output-org_abb     = <in>-org_abb.
    PERFORM get_comp_name
                CHANGING
                   lt_uinfo-company
                   ls_output-company.

    ls_output-funid       = <in>-funid.
    READ TABLE gt_functions WITH KEY function = ls_output-funid.
    IF sy-subrc = 0.
      ls_output-description = gt_functions-description.
    ENDIF.

    ls_output-simu        = <in>-simu.
    ls_output-er          = <in>-er.
    ls_output-simu_before = <in>-simu_before.
    ls_output-simu_after = <in>-simu_after.
*    ls_output-enhanced    = <in>-enhanced.
*    read table gt_enh_fun with key bname = <in>-bname
*                                   funid = <in>-funid.
*    if sy-subrc = 0.
*       ls_output-enhanced = 'X'.
*    else.
*       clear ls_output-enhanced.
*    endif.
*
    APPEND ls_output TO gt_output.

  ENDLOOP.

  FREE : gt_enh_fun.
ENDFORM.                    " reformat_output
*&---------------------------------------------------------------------*
*&      Form  get_comp_name
*&---------------------------------------------------------------------*
*       Get user's company name from company ID
*----------------------------------------------------------------------*
*      <->I_COMPANY    Company ID
*      <--E_COMP_NAME  Company Name
*----------------------------------------------------------------------*
FORM get_comp_name CHANGING i_company "TYPE    "char20
                            e_comp_name. "TYPE  "char20.

  TYPES: BEGIN OF t_comp,
           comp TYPE /psyng/mcauditor-company,
           name TYPE /psyng/mcauditor-company,
         END OF t_comp.

  DATA: l_value  TYPE /psyng/swconfig-value,
        l_fmname TYPE rs38l_fnam,
        ls_comp  TYPE t_comp.

 STATICS: lt_comp      TYPE HASHED TABLE OF t_comp WITH UNIQUE KEY comp,
          l_fm_checked TYPE flag.

  CHECK l_fm_checked IS INITIAL OR gf_company_longtext = 'X'.
  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
  se_config_param 'SW_MGMT_COMP_NAME_FM' l_value.
  IF NOT l_value IS INITIAL.
    l_fmname = l_value.
    IF NOT l_fmname IS INITIAL.
      CALL FUNCTION 'FUNCTION_EXISTS'
        EXPORTING
          funcname           = l_fmname
        EXCEPTIONS
          function_not_exist = 1
          OTHERS             = 2.
      IF sy-subrc <> 0.
*       Configured FM does not exist, use default
        MESSAGE s113(/psyng/sw) WITH
                'Cannot determine SW_MGMT_COMP_NAME_FM with FM '
                l_fmname '. FM doesn''t exist'.
      ELSE.
        gf_company_longtext = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    EXIT.
    CLEAR gf_company_longtext.
  ENDIF.
  IF NOT l_fmname IS INITIAL.
    CALL FUNCTION l_fmname                   "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(12/12/24)
      EXPORTING
        i_company   = i_company
      IMPORTING
        e_comp_name = e_comp_name.
  ENDIF.
  ls_comp-comp = i_company.
  ls_comp-name = e_comp_name.
  INSERT ls_comp INTO TABLE lt_comp.
  l_fm_checked = 'X'.
ENDFORM.                    " get_comp_name
*&---------------------------------------------------------------------*
*&      Form  report_rfc_error
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_RFC_ERROR  text
*      -->P_ROLERFC  text
*----------------------------------------------------------------------*
FORM report_rfc_error USING    l_rfc_error
                               rolerfc.
  MESSAGE i113(/psyng/sw) WITH  rolerfc l_rfc_error text-e02.
  STOP.

ENDFORM.                    " report_rfc_error
*&---------------------------------------------------------------------*
*&      Form  get_server_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_server_name.
  CALL FUNCTION 'TH_GET_ACTIVE_SERVER'
    EXPORTING
      tabname        = ''
      local_tabname  = ''
    IMPORTING
      server         = pserver
    EXCEPTIONS
      no_server_list = 1
      no_server      = 2
      OTHERS         = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*  specsrv = 'X'.
*  CLEAR : specgrp , defgrp.
ENDFORM.                    " get_server_name
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_input.

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
*&      Form  prepare_simuation_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM prepare_simuation_table.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.

  IF rolerfc IS INITIAL.
    rolerfc = l_rfcdest.
  ENDIF.

  it_simu_role_addition-source_rfcdest = rolerfc.
  it_simu_role_addition-target_rfcdest = 'LOCAL'.

  LOOP AT simurols.
    MOVE-CORRESPONDING simurols TO it_simu_role_addition.
    APPEND it_simu_role_addition.
  ENDLOOP.

  LOOP AT it_simu_role_addition.
    MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
    APPEND range_roles.
  ENDLOOP.

  IF rolerfc IS INITIAL OR
     rolerfc EQ 'LOCAL' OR
     rolerfc EQ l_rfcdest.

    CALL FUNCTION '/PSYNG/SW_102'
      TABLES
        it_roles_range = range_roles
        et_roles       = lt_role_names.
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
    CALL FUNCTION '/PSYNG/SW_102'
      DESTINATION rolerfc
      TABLES
        it_roles_range = range_roles
        et_roles       = lt_role_names.          "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  ENDIF.

  LOOP AT lt_role_names.
*--Load local role content
    lt_faobj[] = lt_faobj_local[].
    lt_functtran[] = lt_functtran_local[].
    REFRESH : lt_roleauth,lt_roletcode.

    IF rolerfc IS INITIAL OR
     rolerfc EQ 'LOCAL' OR
     rolerfc EQ l_rfcdest.
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
      "(++)BOC UMITTAL SE VF scan-25/11/2024
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
      "(++)EOC UMITTAL SE VF scan-25/11/2024.

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
      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
        DESTINATION rolerfc
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
          OTHERS         = 2.                    "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    ENDIF.

    lt_roleauth-rfcdest = l_rfcdest.
    lt_roletcode-rfcdest = l_rfcdest.
    MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
    MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.

  ENDLOOP.

ENDFORM.                    " prepare_simuation_table

*&---------------------------------------------------------------------*
*&      Form  f4_usrtype
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USRTYPE_LOW  text
*----------------------------------------------------------------------*
FORM f4_usrtype CHANGING p_usrtype_low.
  DATA: BEGIN OF ls_data,
          value TYPE domvalue_l,
          dtext TYPE val_text,
        END OF ls_data,
        lt_data    LIKE TABLE OF ls_data,
        lth_return TYPE TABLE OF ddshretval,
        wah_return LIKE LINE OF lth_return.

  SELECT a~domvalue_l AS value b~ddtext AS dtext
    INTO CORRESPONDING FIELDS OF TABLE lt_data
    FROM dd07l AS a INNER JOIN dd07t AS b
    ON a~domname = b~domname
    AND a~as4local = b~as4local
    AND a~valpos = b~valpos
    AND a~as4vers = b~as4vers
    WHERE a~domname = '/PSYNG/XUUSTYP'
    AND b~ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

  IF   lt_data[] IS INITIAL.
*--Fallback to English
    SELECT a~domvalue_l AS value b~ddtext AS dtext
      INTO CORRESPONDING FIELDS OF TABLE lt_data
      FROM dd07l AS a INNER JOIN dd07t AS b
      ON a~domname = b~domname
      AND a~as4local = b~as4local
      AND a~valpos = b~valpos
      AND a~as4vers = b~as4vers
      WHERE a~domname = '/PSYNG/XUUSTYP'
      AND b~ddlanguage = 'EN'.                   "#EC SAST_CI_GEN_CHECK
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
    EXPORTING
      retfield        = 'VALUE'
      value_org       = 'S'
      window_title    = 'Title'
    TABLES
      value_tab       = lt_data
      return_tab      = lth_return
    EXCEPTIONS
      parameter_error = 1
      no_values_found = 2
      OTHERS          = 3.

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = wah_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype

FORM f4_orglvl USING    fieldname
               CHANGING e_orglvl.
*--Call search help for Org Level Abbbreviation
*  The source is either the config set or /psyng/swsodorgm table
*  depending on CFG_SET_ENABLED
  CALL FUNCTION '/PSYNG/SW_AO_SEARCHHELP'
    EXPORTING
      i_cfg_set = cfgset
    IMPORTING
      e_orglvl  = e_orglvl.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_user_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_USERLIST  text
*      -->P_P_CLASS  text
*      -->P_' '  text
*      -->P_' '  text
*      -->P_' '  text
*      -->P_LT_UINFO  text
*      -->P_LT_RFCDES  text
*      -->P_LT_USER_MAPPING  text
*      -->P_USRTYPE  text
*      -->P_' '  text
*      -->P_' '  text
*      -->P_VALIDUSR  text
*      -->P_EXLCKUSR  text
*      -->P_1004   text
*      -->P_1005   text
*      -->P_SODVRSIO  text
*      -->P_P_REMONL  text
*      <--P_E_USERCOUNT  text
*----------------------------------------------------------------------*
FORM get_user_info TABLES
    it_users STRUCTURE /psyng/sw_sel_opts_xubname
    it_usergroup STRUCTURE /psyng/range_class
    et_uinfo STRUCTURE /psyng/sw_uinfo_remote
    it_rfcdes STRUCTURE rfcdes
    et_user_mapping STRUCTURE /psyng/sw_user_mapping
    it_usertype STRUCTURE /psyng/sw_sel_opts_usrtyp
  USING
    i_validuser TYPE flag
    i_exlckusr  TYPE flag
    i_outvdate  TYPE flag
    i_allug     TYPE flag
    i_locusr    TYPE flag
    i_vrsio     TYPE /psyng/sodvrsio
    i_remote_only TYPE flag.
  DATA : l_tusercount_dum     TYPE i,
         lt_usr02             TYPE TABLE OF /psyng/sw_uinfo_remote,
         rfcdest              TYPE rfcdest,
         lt_unique_users_dum  TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_iduser_dum        TYPE TABLE OF /psyng/sw_iduser_fm,
         ls_uinfo             TYPE /psyng/sw_uinfo,
         lt_uinfo_remote      TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_uinfo_remote_map  TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_uinfo             TYPE TABLE OF /psyng/sw_uinfo,
         ls_uinfo_remote      TYPE /psyng/sw_uinfo_remote,
         l_rfcdest            TYPE rfcdest,
         l_usercount          TYPE i,
         lf_match             TYPE flag,
         l_maptabix           LIKE sy-tabix,
        lt_uinfo_sorted      TYPE SORTED TABLE OF /psyng/sw_uinfo_remote
              WITH UNIQUE KEY rfcdest bname  WITH HEADER LINE,
        lt1_uinfo            TYPE TABLE OF /psyng/sw_uinfo_remote,
        ls_swconfig          TYPE /psyng/swconfig,
        lf_sod_single_comp   TYPE flag,
        lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
        ls_rfc               TYPE rfcdes,
        lf_valid             TYPE flag.
  FIELD-SYMBOLS : <usr02> TYPE /psyng/sw_uinfo_remote,
                  <uinfo> TYPE /psyng/sw_uinfo.

  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF ls_swconfig-value = 'Y'.
    lf_sod_single_comp = 'X'.
  ENDIF.
  MESSAGE s398(00) WITH  'Loading user information'(l19).
  COMMIT WORK.

*--Get all users matching conditions on ALL selected systems
  PERFORM get_selected_users
                TABLES
                   it_users
                   it_usergroup
                   it_rfcdes
                   lt_iduser_dum
                   lt_usr02
                   lt_unique_users_dum
                   et_user_mapping
                   it_usertype
                USING
                   i_validuser
                   i_exlckusr
                   i_outvdate
                   i_allug
                   i_locusr
                   l_tusercount_dum
                   'X' "do user mapping
                   i_remote_only.

  g_usercnt = l_tusercount_dum.
  SORT lt_usr02.
  DELETE ADJACENT DUPLICATES FROM lt_usr02.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.

  IF lf_sod_single_comp = 'X' AND NOT it_usergroup[] IS INITIAL.
    FREE : lt_uinfo_remote.
    LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
      rfcdest <> l_rfcdest.
      ls_uinfo-bname =  <usr02>-bname.
      ls_uinfo-ustyp =  <usr02>-ustyp.
      ls_uinfo_remote-bname   = <usr02>-bname.
      ls_uinfo_remote-rfcdest = l_rfcdest.
      APPEND ls_uinfo TO lt_uinfo.
      READ TABLE et_user_mapping WITH KEY
      target_rfc   = ls_uinfo_remote-rfcdest
      source_bname = ls_uinfo_remote-bname.
      CHECK NOT sy-subrc = 0.
      APPEND ls_uinfo_remote TO lt_uinfo_remote_map.
    ENDLOOP.
    IF NOT i_remote_only = 'X'.
      ls_rfc-rfcdest = 'LOCAL'.
      IF NOT lt_uinfo_remote_map[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = ls_rfc
          TABLES
            it_users     = lt_uinfo_remote_map
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part TO et_user_mapping.
        FREE : lt_user_mapping_part.
      ENDIF.
    ENDIF.
  ENDIF.
  LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
    rfcdest = l_rfcdest.
    ls_uinfo-bname =  <usr02>-bname.
    APPEND ls_uinfo TO lt_uinfo.
  ENDLOOP.

  SORT lt_uinfo.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

*    FREE : lt_usr02.
*  CHECK NOT lt_uinfo[] IS INITIAL.
  IF NOT lt_uinfo[] IS INITIAL AND NOT i_remote_only = 'X'.
*  --Get local names for users
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
      EXPORTING
        i_name_only     = 'X'
        i_mr_company    = 'X'
        i_mr_department = 'X'
        i_central_uid   = 'X'
      TABLES
        sw_uinfo        = lt_uinfo.

    LOOP AT lt_uinfo ASSIGNING <uinfo>.
      MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
      ls_uinfo_remote-rfcdest = l_rfcdest.
      APPEND ls_uinfo_remote TO et_uinfo.
    ENDLOOP.
  ENDIF.
*  Get user information from remote system(s)
  LOOP AT it_rfcdes.
    FREE : lt_uinfo.
    IF lf_sod_single_comp = 'X' AND NOT it_usergroup[] IS INITIAL.
      FREE : lt_uinfo_remote.
      LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
        rfcdest <> it_rfcdes-rfcoptions.
        ls_uinfo-bname =  <usr02>-bname.
        ls_uinfo-ustyp =  <usr02>-ustyp.
        ls_uinfo_remote-bname   = <usr02>-bname.
        ls_uinfo_remote-rfcdest = it_rfcdes-rfcoptions.
        APPEND ls_uinfo TO lt_uinfo.
        READ TABLE et_user_mapping WITH KEY
        target_rfc   = ls_uinfo_remote-rfcdest
        source_bname = ls_uinfo_remote-bname.
        CHECK NOT sy-subrc = 0.
        APPEND ls_uinfo_remote TO lt_uinfo_remote_map.
      ENDLOOP.
      ls_rfc-rfcdest = it_rfcdes-rfcdest.
      IF NOT lt_uinfo_remote_map[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = ls_rfc
          TABLES
            it_users     = lt_uinfo_remote_map
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part TO et_user_mapping.
        FREE : lt_user_mapping_part.
      ENDIF.
    ENDIF.
    LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
      rfcdest = it_rfcdes-rfcoptions.
      ls_uinfo-bname =  <usr02>-bname.
      APPEND ls_uinfo TO lt_uinfo.
    ENDLOOP.

    CHECK NOT lt_uinfo[] IS INITIAL.
*    --Get local names for users
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
      DESTINATION it_rfcdes-rfcdest
      EXPORTING
        i_name_only     = 'X'
        i_mr_company    = 'X'
        i_mr_department = 'X'
        i_central_uid   = 'X'
      TABLES
        sw_uinfo        = lt_uinfo.              "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


    LOOP AT lt_uinfo ASSIGNING <uinfo>.
      MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
*--DHORIONS 20101201 - We don't need the RFC dstination name, but the
*                      concatenation of system id and client, which is
*                      stored in RFCOPTIONS field
*     ls_uinfo_remote-rfcdest = it_rfcdes-rfcdest.
      ls_uinfo_remote-rfcdest = it_rfcdes-rfcoptions.
      APPEND ls_uinfo_remote TO et_uinfo.
    ENDLOOP.
  ENDLOOP.
  FREE : lt_usr02.
  SORT et_uinfo BY rfcdest bname.

  it_rfcdes-rfcdest  = 'LOCAL'.
  CONCATENATE sy-sysid sy-mandt INTO it_rfcdes-rfcoptions.
*append it_rfcdes.
  INSERT it_rfcdes INDEX 1.
  SORT et_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_uinfo COMPARING rfcdest bname.
  lt_uinfo_sorted[] = et_uinfo[].
  FREE : et_uinfo[].

  SORT et_user_mapping BY target_bname target_rfc source_bname.
  LOOP AT it_rfcdes.
    LOOP AT lt_uinfo_sorted ASSIGNING <usr02> WHERE
    rfcdest = it_rfcdes-rfcoptions.
      CLEAR lf_match.
      READ TABLE et_user_mapping WITH KEY target_bname = <usr02>-bname
                                                         BINARY SEARCH
                                                TRANSPORTING NO FIELDS.
      l_maptabix = sy-tabix.

      LOOP AT et_user_mapping FROM l_maptabix
      WHERE target_bname =  <usr02>-bname AND
                                    target_rfc <> <usr02>-rfcdest.

        READ TABLE lt_uinfo_sorted
        INTO ls_uinfo_remote

        WITH TABLE KEY
         rfcdest = et_user_mapping-target_rfc
         bname   = et_user_mapping-target_bname.
        IF sy-subrc = 0.
          APPEND <usr02> TO et_uinfo.
          EXIT.
        ENDIF.
      ENDLOOP.
      APPEND <usr02> TO et_uinfo.
    ENDLOOP.
  ENDLOOP.

*--Determine user master data priority
  FREE lt_uinfo_sorted.
  PERFORM set_user_master_prio
    TABLES
      et_uinfo
*      lt_rfcdes
    gt_rfcdest_anal
      it_usergroup
      gt_rpoug_auth_fail
    USING sodvrsio.

  DELETE it_rfcdes WHERE rfcdest = 'LOCAL'.
  SORT et_user_mapping BY source_bname target_rfc.
ENDFORM.                    " get_user_info
*&---------------------------------------------------------------------*
*&      Form  get_selected_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USERS  text
*      -->P_IT_USERGROUP  text
*      -->P_IT_RFCDES  text
*      -->P_LT_IDUSER_DUM  text
*      -->P_LT_USR02  text
*      -->P_LT_UNIQUE_USERS_DUM  text
*      -->P_ET_USER_MAPPING  text
*      -->P_IT_USERTYPE  text
*      -->P_IT_ACTGROUPS  text
*      -->P_IT_PROFILE  text
*      -->P_I_VALIDUSER  text
*      -->P_I_EXLCKUSR  text
*      -->P_I_ALLUG  text
*      -->P_I_LOCUSR  text
*      -->P_L_TUSERCOUNT_DUM  text
*      -->P_4030   text
*      -->P_I_REMOTE_ONLY  text
*----------------------------------------------------------------------*
FORM get_selected_users     TABLES
       it_users        STRUCTURE /psyng/sw_sel_opts_xubname
       it_usergroup    STRUCTURE  /psyng/range_class
       it_rfcdes       STRUCTURE rfcdes
       it_iduser       STRUCTURE /psyng/sw_iduser_fm
       et_users        STRUCTURE /psyng/sw_uinfo_remote
       et_unique_users STRUCTURE /psyng/sw_uinfo_remote
       et_user_mapping STRUCTURE /psyng/sw_user_mapping
       it_usertype     STRUCTURE /psyng/sw_sel_opts_usrtyp
     USING
       i_validuser  TYPE flag
       i_exlckusr   TYPE flag
       i_outvdate   TYPE flag
       i_allug      TYPE flag
       i_locusr     TYPE flag
       e_tusercount TYPE i
       i_do_mapping TYPE flag
       i_remote_only TYPE flag.

  DATA : lt_users             TYPE TABLE OF usr02,
         lt_local_users       TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_remote_users      TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
         lt_user_mapping_all  TYPE TABLE OF /psyng/sw_user_mapping
         WITH HEADER LINE,
         ls_rfc               TYPE rfcdes,
         lt_users_range       TYPE TABLE OF /psyng/sw_sel_opts_xubname
         WITH HEADER LINE,
         lt_usergroup_range   TYPE TABLE OF /psyng/sw_sel_opts_xubname,
         i_include_locked     TYPE flag,
         i_include_expire     TYPE flag.
  FIELD-SYMBOLS : <usr>    TYPE /psyng/sw_uinfo_remote,
                  <rfc>    TYPE rfcdes,
                  <iduser> TYPE /psyng/sw_iduser_fm,
                  <map>    TYPE /psyng/sw_user_mapping,
                  <usr02>  TYPE usr02.

*--local users
  IF i_validuser IS INITIAL.
    IF i_exlckusr = 'X'.
      CLEAR i_include_locked.
    ELSE.
      i_include_locked = 'X'.
    ENDIF.

    IF i_outvdate = 'X'.
      CLEAR i_include_expire.
    ELSE.
      i_include_expire = 'X'.
    ENDIF.
  ENDIF.

  IF i_remote_only <> 'X'.
    CALL FUNCTION '/PSYNG/SW_041'
      EXPORTING
        i_validuser       = i_validuser
        i_include_locked  = i_include_locked
        i_include_expired = i_include_expire
      TABLES
        et_users          = lt_users
        it_userlist       = it_users
        it_grouplist      = it_usergroup
        it_usertype       = it_usertype.

    CONCATENATE sy-sysid sy-mandt INTO et_users-rfcdest.

    LOOP AT lt_users ASSIGNING <usr02>.
      MOVE-CORRESPONDING <usr02> TO et_users.
      APPEND et_users.
    ENDLOOP.
*        APPEND LINES OF lt_users TO et_users.
    FREE: lt_users[].
    IF i_do_mapping = 'X'.
*  --Perform user mapping for local users
      ls_rfc-rfcdest = 'LOCAL'.
      CALL FUNCTION '/PSYNG/SW_060'
        EXPORTING
          i_target_rfc = ls_rfc
        TABLES
          it_users     = et_users
          et_mapping   = lt_user_mapping_part.
      APPEND LINES OF lt_user_mapping_part TO lt_user_mapping_all.
      FREE : lt_user_mapping_part.
    ENDIF.
    lt_local_users[] = et_users[].
  ENDIF.
*--remote users
  IF NOT it_rfcdes[] IS INITIAL.
    LOOP AT it_rfcdes ASSIGNING <rfc>.
*--If only users that exist locally need to be analyzed, don't use
*  selection screen criteria for the remote users
      IF i_locusr IS INITIAL.
        lt_users_range[] = it_users[].
        lt_usergroup_range[] = it_usergroup[].
      ELSE.
        FREE : lt_users_range[], lt_usergroup_range[].
      ENDIF.

      IF i_do_mapping = 'X'.
*-- Perform User mapping for remote users
        FREE : lt_user_mapping_part.
        CALL FUNCTION '/PSYNG/SW_060'
          EXPORTING
            i_target_rfc = <rfc>
          TABLES
            it_users     = lt_local_users
            et_mapping   = lt_user_mapping_part.
        APPEND LINES OF lt_user_mapping_part TO lt_user_mapping_all.
*--Add mapped users to user range
        lt_users_range-sign   = 'I'.
        lt_users_range-option = 'EQ'.
        LOOP AT lt_user_mapping_part ASSIGNING <map>.
          lt_users_range-low = <map>-target_bname.
          APPEND lt_users_range.
        ENDLOOP.
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
          CALL FUNCTION '/PSYNG/SW_041'
            DESTINATION <rfc>-rfcdest
            EXPORTING
              i_validuser       = i_validuser
              i_include_locked  = i_include_locked
              i_include_expired = i_include_expire
            TABLES
              et_users          = lt_users
           it_userlist       = lt_users_range.   "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          LOOP AT lt_users ASSIGNING <usr02>.
            MOVE-CORRESPONDING <usr02> TO et_users.
            et_users-rfcdest = <rfc>-rfcoptions.
            APPEND et_users.
          ENDLOOP.
        ENDIF.
        FREE : lt_user_mapping_part.
      ENDIF.
      REFRESH : lt_users[].
*      APPEND LINES OF lt_users TO et_users.
*--Dhorions 20101013
      IF i_locusr IS INITIAL.
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
          DESTINATION <rfc>-rfcdest
          EXPORTING
            i_validuser       = i_validuser
            i_include_locked  = i_include_locked
            i_include_expired = i_include_expire
          TABLES
            et_users          = lt_users
            it_userlist       = it_users
            it_grouplist      = it_usergroup
            it_usertype       = it_usertype.     "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        LOOP AT lt_users ASSIGNING <usr02>.
          MOVE-CORRESPONDING <usr02> TO et_users.
          et_users-rfcdest = <rfc>-rfcoptions.
          APPEND et_users.
        ENDLOOP.
      ENDIF.
*-- Perform User mapping for remote users
      LOOP AT lt_users ASSIGNING <usr02>.
        MOVE-CORRESPONDING <usr02> TO lt_remote_users.
        APPEND lt_remote_users.
      ENDLOOP.
      FREE : lt_user_mapping_part.
      CALL FUNCTION '/PSYNG/SW_060'
        EXPORTING
          i_target_rfc = <rfc>
        TABLES
          it_users     = lt_remote_users
          et_mapping   = lt_user_mapping_part.
      APPEND LINES OF lt_user_mapping_part TO lt_user_mapping_all.
      FREE : lt_user_mapping_part,lt_remote_users.
*--Dhorions end 20101013
      FREE: lt_users[].

    ENDLOOP.
  ENDIF.


*--check for fake user for role based analysis
  et_users-bname = '000000000000'.
  READ TABLE it_users WITH KEY sign   = 'I'
                               option = 'EQ'
                               low    = et_users-bname.
  IF sy-subrc = 0.
    APPEND  et_users.
    CONCATENATE sy-sysid sy-mandt INTO lt_user_mapping_all-target_rfc.
    lt_user_mapping_all-source_bname = et_users-bname.
    lt_user_mapping_all-target_bname = et_users-bname.
    APPEND lt_user_mapping_all.
*--2014/05/06 - Also add fake simulation user for remote systems
    LOOP AT it_rfcdes ASSIGNING <rfc>.
      et_users-rfcdest = <rfc>-rfcoptions.
      APPEND  et_users.
      lt_user_mapping_all-target_rfc = <rfc>-rfcoptions.
      lt_user_mapping_all-source_bname = et_users-bname.
      lt_user_mapping_all-target_bname = et_users-bname.
      APPEND lt_user_mapping_all.
    ENDLOOP.
  ENDIF.
*--delete dupes
  SORT et_users BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_users COMPARING rfcdest bname.

  et_unique_users[] = et_users[].
  DATA : lt_unqusr LIKE TABLE OF et_users.
  lt_unqusr[] = et_unique_users[].
  SORT lt_unqusr BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_unqusr COMPARING bname.
  DESCRIBE TABLE  lt_unqusr LINES e_tusercount.
  FREE lt_unqusr.
  et_user_mapping[] = lt_user_mapping_all[].



ENDFORM.                    " get_selected_users
*&---------------------------------------------------------------------*
*&      Form  set_user_master_prio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_UINFO  text
*      -->P_LT_RFCDES  text
*      -->P_IT_USERGROUP  text
*      -->P_GT_RPOUG_AUTH_FAIL  text
*      -->P_I_VRSIO  text
*      <--P_E_USERCOUNT  text
*----------------------------------------------------------------------*
FORM set_user_master_prio TABLES   et_uinfo STRUCTURE
/psyng/sw_uinfo_remote
         it_rfcdes STRUCTURE rfcdes
         it_usergroup  STRUCTURE /psyng/range_class
         lt_rpoug_auth_fail STRUCTURE /psyng/sw_uinfo
USING    i_vrsio TYPE /psyng/sodvrsio .
  DATA: ls_swconfig TYPE /psyng/swconfig,
        lt_rfcdes   TYPE TABLE OF rfcdes WITH HEADER LINE,
        l_local     TYPE rfcdest,
        l_prio      TYPE i.
  .
  FIELD-SYMBOLS : <des> TYPE  rfcdes.
  REFRESH: lt_rpoug_auth_fail.
  lt_rfcdes[] = it_rfcdes[].
  CONCATENATE sy-sysid sy-mandt INTO l_local.
*--Determine parameter for priority of systems
*user attributes (company, user group) shall be determined in the
*following sequence:
* The sort key for the local system is determined by the config
* parameter SW_LOCAL_SYSTEM_SORT,
*( if it is not available, the default blank value will be used, making
*  the local system always having the highest priority)
*For all remote systems, the sort key that will be used is the RFC
* destination name.

*--Get configured sort criteria for local system
  se_config_param 'SW_LOCAL_SYSTEM_SORT' ls_swconfig-value.
  READ TABLE lt_rfcdes
  ASSIGNING <des>
  WITH KEY rfcoptions = l_local.
  IF sy-subrc <> 0.
    lt_rfcdes-rfcoptions = l_local.
    APPEND lt_rfcdes.
    READ TABLE lt_rfcdes
    ASSIGNING <des>
    WITH KEY rfcoptions = l_local.
  ENDIF.
  IF ls_swconfig-value <> '' AND sy-subrc = 0.
    <des>-rfcdest = ls_swconfig-value.
  ELSE.
    CLEAR <des>-rfcdest.
  ENDIF.
  l_prio = 0.
  SORT lt_rfcdes BY rfcdest.
  LOOP AT lt_rfcdes.
    ADD 1 TO l_prio.
    et_uinfo-sodcount = l_prio.
    MODIFY et_uinfo
    TRANSPORTING sodcount
    WHERE
    rfcdest = lt_rfcdes-rfcoptions.
  ENDLOOP.
*--Only keep record with highest priority for each user
  SORT et_uinfo BY bname sodcount.
  DELETE ADJACENT DUPLICATES FROM  et_uinfo COMPARING bname.


*--START DHORIONS 20110221 - Single company per user
  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF ls_swconfig-value = 'Y'.
*--Only consider one company per user, the one with the highest
*  priority
*-- No company and department user input present
*    DELETE et_uinfo WHERE NOT company    IN it_company.
*    DELETE et_uinfo WHERE NOT department IN it_department.
    IF det IS INITIAL.
      DELETE et_uinfo WHERE NOT class      IN it_usergroup.
    ENDIF.
  ENDIF.
*--END DHORIONS 20110221 - Single company per user
*--End  determine priority

*--Authorization Checks
  DATA : lf_reject TYPE flag.
  LOOP AT et_uinfo.
    PERFORM check_rpoug_auth USING et_uinfo i_vrsio
                             CHANGING lf_reject.
    IF lf_reject = 'X'.
      gt_rpoug_auth_fail-bname   = et_uinfo-bname.
      gt_rpoug_auth_fail-class   = et_uinfo-class.
      gt_rpoug_auth_fail-company = et_uinfo-company.
      APPEND gt_rpoug_auth_fail.
      DELETE et_uinfo.
      gf_missing_auth_ugroup = 'X'.
      CLEAR gt_rpoug_auth_fail.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " set_user_master_prio
*&---------------------------------------------------------------------*
*&      Form  check_rpoug_auth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_UINFO  text
*      -->P_I_VRSIO  text
*      <--P_LF_REJECT  text
*----------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo_remote
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
            vrsio    TYPE /psyng/sodvrsio,
            class    TYPE xuclass,
            company  TYPE char20,
            rejected TYPE flag,
          END OF typ_rpoug.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
    lt_rpoug-vrsio = i_vrsio.
    lt_rpoug-class = is_uinfo-class.
    lt_rpoug-company = is_uinfo-company.
    CLEAR lt_rpoug-rejected.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.

ENDFORM.                    " check_rpoug_auth
*&---------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA : alv_layout     TYPE slis_layout_alv,
         alv_grid_titl  TYPE lvc_title,
         i_fieldcat_alv TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: ls_variant TYPE disvariant.

  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  REFRESH i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title = alv_grid_titl
      is_layout    = alv_layout
      it_fieldcat  = i_fieldcat_alv
      i_save       = 'A'
      is_variant   = ls_variant
    TABLES
      t_outtab     = gt_rpoug_auth_fail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " show_user_grp_cmp_invalid

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
  DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv,        "For ALV call
        alv_layout     TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl  TYPE lvc_title.                  "For ALV call
  DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
  DATA: ls_variant TYPE disvariant.

  program = sy-repid.
*--Create fieldcatalog
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name     = program
      i_internal_tabname = 'LT_OUTDET'
      i_inclname         = program
*     i_structure_name   = '/PSYNG/SW_OUTPUT_ORG'
    CHANGING
      ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             inconsistent_interface = 1
             program_error          = 2
             OTHERS                 = 3 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Modify field catalog

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-seltext_l      = text-042.
  wa_fieldcat_alv-seltext_m      = text-042.
  wa_fieldcat_alv-seltext_s      = text-042.
  wa_fieldcat_alv-reptext_ddic   = text-042.
  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-046.
  wa_fieldcat_alv-seltext_m      = text-046.
  wa_fieldcat_alv-seltext_s      = text-046.
  wa_fieldcat_alv-reptext_ddic   = text-046.
  wa_fieldcat_alv-fieldname = 'RISK'.
  wa_fieldcat_alv-key = ' '.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-045.
  wa_fieldcat_alv-seltext_m      = text-045.
  wa_fieldcat_alv-seltext_s      = text-045.
  wa_fieldcat_alv-reptext_ddic   = text-045.
  wa_fieldcat_alv-fieldname = 'CONID'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  IF orgchk EQ ''.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-043.
  wa_fieldcat_alv-seltext_m      = text-043.
  wa_fieldcat_alv-seltext_s      = text-043.
  wa_fieldcat_alv-reptext_ddic   = text-043.
  wa_fieldcat_alv-fieldname = 'ORG_ABB'.
  wa_fieldcat_alv-key = ' '.
*  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-044.
  wa_fieldcat_alv-seltext_m      = text-044.
  wa_fieldcat_alv-seltext_s      = text-044.
  wa_fieldcat_alv-reptext_ddic   = text-044.
  wa_fieldcat_alv-fieldname = 'IMP'.
  wa_fieldcat_alv-key = ' '.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-fieldname = 'IMPSORT'.
  wa_fieldcat_alv-key = ' '.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-047.
  wa_fieldcat_alv-seltext_m      = text-047.
  wa_fieldcat_alv-seltext_s      = text-047.
  wa_fieldcat_alv-reptext_ddic   = text-047.
  wa_fieldcat_alv-fieldname = 'FUNCTIONID'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-050.
  wa_fieldcat_alv-seltext_m      = text-051.
  wa_fieldcat_alv-seltext_s      = text-051.
  wa_fieldcat_alv-reptext_ddic   = text-051.
  wa_fieldcat_alv-fieldname = 'RFCDEST'.
  wa_fieldcat_alv-key = ' '.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-052.
  wa_fieldcat_alv-seltext_m      = text-053.
  wa_fieldcat_alv-seltext_s      = text-053.
  wa_fieldcat_alv-reptext_ddic   = text-053.
  wa_fieldcat_alv-fieldname = 'TCODE'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-054.
  wa_fieldcat_alv-seltext_m      = text-055.
  wa_fieldcat_alv-seltext_s      = text-055.
  wa_fieldcat_alv-reptext_ddic   = text-055.
  wa_fieldcat_alv-fieldname = 'OBJCT'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-056.
  wa_fieldcat_alv-seltext_m      = text-057.
  wa_fieldcat_alv-seltext_s      = text-057.
  wa_fieldcat_alv-reptext_ddic   = text-057.
  wa_fieldcat_alv-fieldname = 'AUTH'.
  wa_fieldcat_alv-key = ' '.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-058.
  wa_fieldcat_alv-seltext_m      = text-058.
  wa_fieldcat_alv-seltext_s      = text-058.
  wa_fieldcat_alv-reptext_ddic   = text-058.
  wa_fieldcat_alv-fieldname = 'FIELD'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-059.
  wa_fieldcat_alv-seltext_m      = text-059.
  wa_fieldcat_alv-seltext_s      = text-059.
  wa_fieldcat_alv-reptext_ddic   = text-059.
  wa_fieldcat_alv-fieldname = 'VON'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-060.
  wa_fieldcat_alv-seltext_m      = text-060.
  wa_fieldcat_alv-seltext_s      = text-060.
  wa_fieldcat_alv-reptext_ddic   = text-060.
  wa_fieldcat_alv-fieldname = 'BIS'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-049.
  wa_fieldcat_alv-seltext_m      = text-049.
  wa_fieldcat_alv-seltext_s      = text-049.
  wa_fieldcat_alv-reptext_ddic   = text-049.
  wa_fieldcat_alv-fieldname = 'AGR_NAME'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = 'X'.
  wa_fieldcat_alv-seltext_l      = text-061.
  wa_fieldcat_alv-seltext_m      = text-061.
  wa_fieldcat_alv-seltext_s      = text-061.
  wa_fieldcat_alv-reptext_ddic   = text-061.
  wa_fieldcat_alv-fieldname = 'PROFILE'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  IF bysimu EQ ''.
    wa_fieldcat_alv-no_out         = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-062.
  wa_fieldcat_alv-seltext_m      = text-062.
  wa_fieldcat_alv-seltext_s      = text-062.
  wa_fieldcat_alv-reptext_ddic   = text-062.
  wa_fieldcat_alv-fieldname = 'SIMU'.
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-checkbox = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  CLEAR wa_fieldcat_alv.
  IF erroles EQ ''.
    wa_fieldcat_alv-no_out         = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l      = text-063.
  wa_fieldcat_alv-seltext_m      = text-063.
  wa_fieldcat_alv-seltext_s      = text-063.
  wa_fieldcat_alv-reptext_ddic   = text-063.
  wa_fieldcat_alv-fieldname = 'ER' . " 'ERROLES'. Odubey
  wa_fieldcat_alv-key = ' '.
  wa_fieldcat_alv-checkbox = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  IF showcomp = 'X'.
    CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out         = ''.
    wa_fieldcat_alv-seltext_l      = text-048.
    wa_fieldcat_alv-seltext_m      = text-048.
    wa_fieldcat_alv-seltext_s      = text-048.
    wa_fieldcat_alv-reptext_ddic   = text-048.
    wa_fieldcat_alv-fieldname = 'COMP_AGR'.
    wa_fieldcat_alv-key = ' '.
    wa_fieldcat_alv-hotspot = 'X'.
    INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.
  ENDIF.



*--Create Sort Table
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OBJCT'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AUTH'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELD'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VON'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname =  'LT_OUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

*----Prepare Layout
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*     i_callback_top_of_page   = 'USER_TOP_OF_PAGE'
      i_grid_title             = sy-title
      i_callback_program       = program
      i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
      it_sort                  = isort
      i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_DETL'
      is_layout                = alv_layout
      it_fieldcat              = i_fieldcat_alv
      i_save                   = 'A'
      is_variant               = ls_variant
    TABLES
      t_outtab                 = lt_outdet
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.



ENDFORM.                    " output_using_alv_det
*&---------------------------------------------------------------------*
*&      Form  get_users_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_count.
  DATA : l_numb      TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local    TYPE flag VALUE 'X'.

  IF p_remonl = 'X'.
    CLEAR lv_local.
  ENDIF.


  IF exlckusr EQ 'X'.
    CLEAR lv_exlckusr.
  ELSEIF exlckusr IS INITIAL.
    lv_exlckusr = 'X'.
  ENDIF.

  IF outvdate EQ 'X'.
    CLEAR lv_outvdate.
  ELSEIF outvdate IS INITIAL.
    lv_outvdate = 'X'.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
    EXPORTING
      i_validuser       = validusr
      i_include_locked  = lv_exlckusr
      i_include_expired = lv_outvdate
      if_local_system   = lv_local
      if_show_message   = 'X'
    IMPORTING
      e_usercount       = l_numb
    TABLES
      it_userlist       = userlist
      it_grouplist      = pclass
      it_usertype       = usrtype
*     IT_ACTGROUPS      = s_role
*     IT_PROFILE        = s_prof
      it_rfcrange       = xusrrfc
*     IT_RFCLIST        =
*     IT_DEPARTMENT     = s_depart
*     IT_COMPANY        = s_comp
*     IT_CUID           = s_cuid.
    .
ENDFORM.                    " get_users_count
*&---------------------------------------------------------------------*
*&      Form  validate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_other_fields.
  DATA : l_vrsio         TYPE /psyng/sodvrsio,
         l_rfcdest       TYPE rfcdes-rfcdest,
         lt_roles        TYPE TABLE OF /psyng/bc_agr_name,
   ls_rfcdest      LIKE /psyng/sw_sel_opts_rfcdest, "LINE OF lt_rfcdest,
   l_rfcdest_local TYPE rfcdes-rfcdest,
   lt_excluding    TYPE  slis_t_extab,
   ls_excluding    TYPE slis_extab,
   l_repid         LIKE sy-repid,
   lt_fcat         TYPE slis_t_fieldcat_alv,
   ls_fcat         LIKE LINE OF lt_fcat,
   l_exit.

  DATA : BEGIN OF lt_rfc_roles OCCURS 0,
           rfcdest      TYPE rfcdes-rfcdest,
           agr_name(30) TYPE c,
         END OF lt_rfc_roles.

  DEFINE append_roles.
    if &1 is initial.
      &1 = 'LOCAL'.
    endif.
    lt_rfc_roles-rfcdest = &1.
    lt_rfc_roles-agr_name = &2.
    append lt_rfc_roles.
    clear gt_rfcdest-rfcdest.
  END-OF-DEFINITION.


  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.

  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  IF sy-subrc NE 0.
    MESSAGE i135 WITH 'SOD Version does not exist.'(195).
    LEAVE LIST-PROCESSING.
  ENDIF.

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
              it_agr_name         = ar_rol_1
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.

*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_1-low.

          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs1.
        ENDIF.

      ELSE.
        CLEAR : gt_rfcdest.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          TABLES
            it_agr_name         = ar_rol_1
            et_roles            = lt_roles
          EXCEPTIONS
            role_does_not_exist = 1
            OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
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
              it_agr_name         = ar_rol_2
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
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
        CLEAR : gt_rfcdest.
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
              it_agr_name         = ar_rol_3
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
            append_roles gt_rfcdest-rfcdest ar_rol_3-low.
          ENDIF.
        ELSE.
          DELETE gt_role_addition_simu WHERE source_rfcdest = ar_rfcs3.
        ENDIF.
      ELSE.
        CLEAR : gt_rfcdest.
        CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          TABLES
            it_agr_name         = ar_rol_3
            et_roles            = lt_roles
          EXCEPTIONS
            role_does_not_exist = 1
            OTHERS              = 2.
        IF sy-subrc <> 0.
*          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*          LEAVE LIST-PROCESSING.
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
              it_agr_name         = ar_rol_4
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
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
        CLEAR : gt_rfcdest.
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
*         I_STRUCTURE_NAME = 'BAPIRET2'
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
        'Unable to show Simulated entries validation issues'.
      ENDIF.

      IF l_exit = 'X'.
        LEAVE LIST-PROCESSING.
      ELSE.

      ENDIF.
    ENDIF.
  ENDIF.

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
              it_agr_name         = rr_rol_1
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
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
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
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
                 OTHERS                       = 5
                        .
          IF sy-subrc NE 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
            DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name         = rr_rol_2
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
*Begin of addition AKUMAR PN15868 09.01.2026
*Delete role if rfc destination does not exist for the system in which
*role is being removed in simulation
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_2.
*End of additon
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
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
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
              it_agr_name         = rr_rol_3
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
*Begin of addition AKUMAR PN15868 09.01.2026
*Delete role if rfc destination does not exist for the system in which
*role is being removed in simulation
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_3.
*End of addition
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
          MESSAGE i135 WITH 'Role(s) does not exist.'(197).
          LEAVE LIST-PROCESSING.
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
                 OTHERS                       = 5
                        .
          IF sy-subrc NE 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
          ENDIF.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
            DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name         = rr_rol_4
              et_roles            = lt_roles
            EXCEPTIONS
              role_does_not_exist = 1
              OTHERS              = 2.           "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
*Begin of addition AKUMAR PN15868 09.01.2026
*Delete role if rfc destination does not exist for the system in which
*role is being removed in simulation
        ELSE.
          DELETE gt_role_removal_simu WHERE rfcdest = rr_rfc_4.
*End of addition
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


ENDFORM.                    " validate_other_fields
*&---------------------------------------------------------------------*
*&      Form  before_after_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------*
FORM before_after_simulation
TABLES
  it_role_removal_simu  STRUCTURE /psyng/sw_role_removal_simu
  it_role_addition_simu STRUCTURE /psyng/sw_role_addition_simu.
  DATA :
 lt_res_before          LIKE TABLE OF gt_res_before    WITH HEADER LINE,
 lt_res_after           LIKE TABLE OF gt_res_after     WITH HEADER LINE,
 lt_uinfo_remote        LIKE TABLE OF gt_uinfo_remote  WITH HEADER LINE,
 lt_simu_roleauth_part
   TYPE TABLE OF /psyng/userauth  WITH HEADER LINE,
 lt_simu_roletcode_part
   TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
 lt_role_removal_simu
   TYPE TABLE OF /psyng/sw_role_removal_simu
                                  WITH HEADER LINE,
 l_local_rfc            TYPE rfcdes-rfcdest,
 lt_confdet_sys         TYPE TABLE OF /psyng/confdet,
 lt_functtran_sys       TYPE TABLE OF /psyng/functtran,
 lt_faobj_sys           TYPE TABLE OF /psyng/faobj2,
 l_system               TYPE /psyng/rfcname,
 ls_faobj_system        TYPE /psyng/sw_sys_faobj,
 ls_ao_sys              TYPE /psyng/sw_sys_ao.


  IF bysimu = 'X'.
    PERFORM load_simulated_role_content
     TABLES
       it_role_addition_simu
       lt_roleauth
       lt_roletcode
       lt_functtran_local
       lt_faobj_local
*     lt_rfcdes.
       gt_rfcdest.
  ENDIF.

*-- Before simulation
  LOOP AT gt_rfcdest_anal.
    REFRESH lt_user_range.
    REFRESH lt_res_before.
    REFRESH gt_uinfo_remote.
    lt_user_range-sign   = 'I'.
    lt_user_range-option = 'EQ'.
    LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
      LOOP AT lt_user_mapping ASSIGNING <map>
      WHERE target_rfc = gt_rfcdest_anal-rfcoptions AND
      source_bname = <uinfo>-bname.
        lt_user_range-low = <uinfo>-bname.
        COLLECT lt_user_range.
      ENDLOOP.
    ENDLOOP.

    IF lt_user_range[] IS INITIAL.
      CONTINUE.
    ENDIF.




*--Filter Functions by system
    l_system = gt_rfcdest_anal-rfcoptions.
    lt_functtran_sys[] = lt_functtran_local[].
    lt_confdet_sys[]   = lt_confdet_local[].
* --Variable Elements, get the correct values for the remote system
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
        i_vrsio       = sodvrsio
      TABLES
        it_functtran  = lt_functtran_sys
        it_faobj      = lt_faobj_sys
        it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             too_many_options = 1
             OTHERS           = 2 .
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
    CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
      DESTINATION gt_rfcdest_anal-rfcdest
      EXPORTING
        i_vrsio               = sodvrsio
        i_config_set          = cfgset
        i_enh                 = p_enhanc
        i_org_check           = g_orgchk "orgchk C0766
        i_wp                  = wp
        i_validuser           = validusr
        i_exlckusr            = exlckusr
        i_outvdate            = outvdate
        i_allug               = 'X'
        i_xstb_fm             = 'X'
        i_er_roles            = erroles
        i_exclude_er_roles    = excl_er
      TABLES
        it_users              = lt_user_range
        et_output             = lt_res_before
        et_enh_fun            = gt_enh_fun
        it_simu_role_rfc      = simuagrs
*      pass contents of local SOD matrix to remote system
        it_conflict           = lt_conflict_local
        it_confdet            = lt_confdet_sys
        it_functtran          = lt_functtran_sys
        it_faobj              = lt_faobj_sys
        it_swsodorgm          = ls_ao_sys-swsodorgm[]
        it_tcodes             = lt_tcodes_local
        it_functran_no_enh    = lt_functran_no_enh_local
        it_uinfo              = gt_uinfo_remote
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          gt_rfcdest_anal-rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          gt_rfcdest_anal-rfcdest.
      ENDCASE.
    ENDIF.

    APPEND LINES OF lt_res_before TO gt_res_before.

*Begin of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
*    APPEND LINES OF lt_uinfo_remote TO gt_uinfo_remote.
    APPEND LINES OF gt_uinfo_remote TO  lt_uinfo_remote.
*    REFRESH lt_uinfo_remote.
    REFRESH gt_uinfo_remote.
*End of Addition:HBHALLA(PN-18666)(R3)(09/04/26)

  ENDLOOP.

  IF NOT p_remonl = 'X'.
    REFRESH lt_user_range.
    REFRESH lt_res_before.
    REFRESH gt_uinfo_remote.
    lt_user_range-sign   = 'I'.
    lt_user_range-option = 'EQ'.
    LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
      LOOP AT lt_user_mapping ASSIGNING <map>
      WHERE target_rfc = l_rfcdest AND
      source_bname = <uinfo>-bname.
        lt_user_range-low = <uinfo>-bname.
        COLLECT lt_user_range.
      ENDLOOP.
    ENDLOOP.

    IF NOT lt_user_range[] IS INITIAL.


*--Filter Functions by system
      CONCATENATE sy-sysid sy-mandt INTO l_system.
      lt_functtran_sys[] = lt_functtran_local[].
      lt_faobj_sys[]     = lt_faobj_local[].
      lt_confdet_sys[]   = lt_confdet_local[].
      CALL FUNCTION '/PSYNG/SW_124'
        EXPORTING
          if_functions  = 'X'
          i_system      = l_system
          i_application = 'SAP'
          i_vrsio       = sodvrsio
        TABLES
          it_functtran  = lt_functtran_sys
          it_faobj      = lt_faobj_sys
          it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          too_many_options = 1
          OTHERS = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      "(++)EOC UMITTAL SE VF scan-25/11/2024.

      CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
        EXPORTING
          i_vrsio            = sodvrsio
          i_config_set       = cfgset
          i_enh              = p_enhanc
          i_org_check        = g_orgchk "orgchk C0766
          i_wp               = wp
          i_validuser        = validusr
          i_exlckusr         = exlckusr
          i_outvdate         = outvdate
          i_allug            = 'X'
          i_xstb_fm          = 'X'
          i_remote_only      = p_remonl
          i_er_roles         = erroles
          i_exclude_er_roles = excl_er
        TABLES
          it_users           = lt_user_range
          et_output          = lt_res_before
          et_enh_fun         = gt_enh_fun
          it_simu_role_rfc   = simuagrs
*          pass contents of local SOD matrix to remote system
          it_conflict        = lt_conflict_local
          it_confdet         = lt_confdet_sys
          it_functtran       = lt_functtran_sys
          it_faobj           = lt_faobj_sys
          it_swsodorgm       = lt_swsodorgm_local
          it_tcodes          = lt_tcodes_local
          it_functran_no_enh = lt_functran_no_enh_local
          it_uinfo           = gt_uinfo_remote.
      CLEAR gt_rfcdest_anal.
      APPEND LINES OF lt_res_before TO gt_res_before.
    ENDIF.
  ENDIF.

*-- After Simulation
  LOOP AT gt_rfcdest_anal.
    REFRESH lt_user_range.
    REFRESH lt_res_after.
    REFRESH gt_uinfo_remote.
    lt_user_range-sign   = 'I'.
    lt_user_range-option = 'EQ'.
    LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
      LOOP AT lt_user_mapping ASSIGNING <map>
      WHERE target_rfc = gt_rfcdest_anal-rfcoptions AND
      source_bname = <uinfo>-bname.
        lt_user_range-low = <uinfo>-bname.
        COLLECT lt_user_range.
      ENDLOOP.
    ENDLOOP.

    IF lt_user_range[] IS INITIAL.
      CONTINUE.
    ENDIF.

*    BOC: HBHALLA
    CLEAR l_system.
    l_system = gt_rfcdest_anal-rfcoptions.
*    END OF CHANGE: HBHALLA

    FREE : lt_role_removal_simu.
    LOOP AT it_role_removal_simu
         WHERE rfcdest = gt_rfcdest_anal-rfcdest.
      APPEND it_role_removal_simu TO lt_role_removal_simu.
    ENDLOOP.

    FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
    LOOP AT lt_roleauth WHERE rfcdest =  gt_rfcdest_anal-rfcoptions.
      MOVE-CORRESPONDING lt_roleauth TO lt_simu_roleauth_part.
      APPEND  lt_simu_roleauth_part.
    ENDLOOP.

    LOOP AT lt_roletcode WHERE rfcdest = gt_rfcdest_anal-rfcoptions.
      MOVE-CORRESPONDING lt_roletcode  TO lt_simu_roletcode_part.
      APPEND  lt_simu_roletcode_part.
    ENDLOOP.
* --Variable Elements, get the correct values for the remote system
    READ TABLE gt_faobj_system INTO ls_faobj_system
    WITH KEY rfcdest = l_system.
    IF sy-subrc = 0.
      lt_faobj_sys[] = ls_faobj_system-faobj[].
    ENDIF.
*--Org Elements, get the correct values for the system
    CLEAR ls_ao_sys.
    READ TABLE gt_ao_sys INTO ls_ao_sys
    WITH KEY rfcdest = l_system.
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
    CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
      DESTINATION gt_rfcdest_anal-rfcdest
      EXPORTING
        i_vrsio               = sodvrsio
        i_config_set          = cfgset
        i_enh                 = p_enhanc
        i_org_check           = g_orgchk "orgchk C0766
        i_wp                  = wp
        i_validuser           = validusr
        i_exlckusr            = exlckusr
        i_outvdate            = outvdate
        i_allug               = 'X'
        i_xstb_fm             = 'X'
        i_er_roles            = erroles
        i_exclude_er_roles    = excl_er
      TABLES
        it_users              = lt_user_range
        et_output             = lt_res_after
        et_enh_fun            = gt_enh_fun
        it_simu_role_rfc      = simuagrs
*          pass contents of local SOD matrix to remote system
        it_conflict           = lt_conflict_local
        it_confdet            = lt_confdet_sys
        it_functtran          = lt_functtran_sys
        it_faobj              = lt_faobj_sys
        it_swsodorgm          = ls_ao_sys-swsodorgm[]
        it_tcodes             = lt_tcodes_local
        it_functran_no_enh    = lt_functran_no_enh_local
        it_uinfo              = gt_uinfo_remote
        it_simu_add_roletcode = lt_simu_roletcode_part
        it_simu_add_roleauth  = lt_simu_roleauth_part
        it_simu_role_removal  = lt_role_removal_simu
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
        gt_rfcdest_anal-rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          gt_rfcdest_anal-rfcdest.
      ENDCASE.
    ENDIF.

    APPEND LINES OF lt_res_after TO gt_res_after.
*Begin of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
*    APPEND LINES OF lt_uinfo_remote TO gt_uinfo_remote.
    APPEND LINES OF gt_uinfo_remote TO  lt_uinfo_remote.
*    REFRESH lt_uinfo_remote.
    REFRESH gt_uinfo_remote.
*End of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
  ENDLOOP.

  IF NOT p_remonl = 'X'.
    REFRESH lt_user_range.
    REFRESH lt_res_after.
    REFRESH gt_uinfo_remote.
    lt_user_range-sign   = 'I'.
    lt_user_range-option = 'EQ'.
    LOOP AT gt_uinfo_sorted ASSIGNING <uinfo>.
      LOOP AT lt_user_mapping ASSIGNING <map>
      WHERE target_rfc = l_rfcdest AND
      source_bname = <uinfo>-bname.
        lt_user_range-low = <uinfo>-bname.
        COLLECT lt_user_range.
      ENDLOOP.
    ENDLOOP.

    IF NOT lt_user_range[] IS INITIAL.
      CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
      FREE : lt_role_removal_simu.
      LOOP AT it_role_removal_simu WHERE rfcdest = 'LOCAL' OR
                                         rfcdest = '' OR
                                         rfcdest = l_local_rfc.
        APPEND it_role_removal_simu TO lt_role_removal_simu.
      ENDLOOP.

      FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.



      LOOP AT lt_roleauth WHERE rfcdest =  l_local_rfc.
        MOVE-CORRESPONDING lt_roleauth TO lt_simu_roleauth_part.
        APPEND  lt_simu_roleauth_part.
      ENDLOOP.

      LOOP AT lt_roletcode WHERE rfcdest = l_local_rfc.
        MOVE-CORRESPONDING lt_roletcode  TO lt_simu_roletcode_part.
        APPEND  lt_simu_roletcode_part.
      ENDLOOP.


*--Filter Functions by system
      CONCATENATE sy-sysid sy-mandt INTO l_system.
      lt_functtran_sys[] = lt_functtran_local[].
      lt_faobj_sys[]     = lt_faobj_local[].
      lt_confdet_sys[]   = lt_confdet_local[].
      CALL FUNCTION '/PSYNG/SW_124'
        EXPORTING
          if_functions  = 'X'
          i_system      = l_system
          i_application = 'SAP'
          i_vrsio       = sodvrsio
        TABLES
          it_functtran  = lt_functtran_sys
          it_faobj      = lt_faobj_sys
          it_confdet    = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          too_many_options = 1
          OTHERS = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

      "(++)EOC UMITTAL SE VF scan-25/11/2024.


      CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
        EXPORTING
          i_vrsio               = sodvrsio
          i_config_set          = cfgset
          i_enh                 = p_enhanc
          i_org_check           = g_orgchk "orgchk C0766
          i_wp                  = wp
          i_validuser           = validusr
          i_exlckusr            = exlckusr
          i_outvdate            = outvdate
          i_allug               = 'X'
*--Dhorions 2014/08/30 - Don't update function scan table
          i_xstb_fm             = 'X'
          i_remote_only         = p_remonl
          i_er_roles            = erroles
          i_exclude_er_roles    = excl_er
        TABLES
          it_users              = lt_user_range
          et_output             = lt_res_after
          et_enh_fun            = gt_enh_fun
          it_simu_role_rfc      = simuagrs
*          pass contents of local SOD matrix to remote system
          it_conflict           = lt_conflict_local
          it_confdet            = lt_confdet_sys
          it_functtran          = lt_functtran_sys
          it_faobj              = lt_faobj_sys
          it_swsodorgm          = lt_swsodorgm_local
          it_tcodes             = lt_tcodes_local
          it_functran_no_enh    = lt_functran_no_enh_local
          it_uinfo              = gt_uinfo_remote
          it_simu_add_roletcode = lt_simu_roletcode_part
          it_simu_add_roleauth  = lt_simu_roleauth_part
          it_simu_role_removal  = lt_role_removal_simu.
      CLEAR gt_rfcdest_anal.
      APPEND LINES OF lt_res_after TO gt_res_after.
*Begin of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
*    APPEND LINES OF lt_uinfo_remote TO gt_uinfo_remote.
    APPEND LINES OF gt_uinfo_remote TO  lt_uinfo_remote.
*    REFRESH lt_uinfo_remote.
    REFRESH gt_uinfo_remote.
*End of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
    ENDIF.
  ENDIF.

*-- Process output.
  SORT  gt_res_after  BY bname funid rfcdest.
  SORT  gt_res_before BY bname funid rfcdest.
*Begin of Addition:HBHALLA(PN-18666)(R3)(09/04/26)
  gt_uinfo_remote[] = lt_uinfo_remote[].
  REFRESH lt_uinfo_remote.
*End of Addition:HBHALLA(PN-18666)(R3)(09/04/26)

  REFRESH : gt_res.

  LOOP AT gt_res_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_res_after TO ls_output.
    READ TABLE gt_res_before
    WITH KEY funid = gt_res_after-funid
             bname = gt_res_after-bname
*Begin of addition AKUMAR PN15868 08.01.2026
*To check simulation status system wise
             rfcdest = gt_res_after-rfcdest.
*End of addition
    IF sy-subrc <> 0.
*--Conflict is added
      ls_output-simu_after = 'X'.
      CLEAR ls_output-simu_before.
    ELSE.
*--Conflict is unchanged
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

  LOOP AT gt_res_before.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_res_before TO ls_output.
    READ TABLE gt_res_after
    WITH KEY funid = gt_res_before-funid
             bname = gt_res_before-bname
*Begin of addition AKUMAR PN15868 08.01.2026
*To check simulation status system wise
             rfcdest = gt_res_before-rfcdest.
*End of addition
    IF sy-subrc <> 0.
*--Conflict is removed
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

  IF NOT p_remonl = 'X'.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
    gt_rfcdest_anal-rfcdest = 'LOCAL'.
    gt_rfcdest_anal-rfcoptions = l_local_rfc.
    APPEND gt_rfcdest_anal.
  ENDIF.
  LOOP AT gt_rfcdest_anal.
    PERFORM reformat_output USING gt_rfcdest_anal.
  ENDLOOP.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF gt_output[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.

  PERFORM output_using_alv_sum.


ENDFORM.                    " before_after_simulation
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
FORM prepare_role_addition_simu TABLES  et_role_addition_simu STRUCTURE
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
*&      Form  load_simulated_role_content
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_ROLE_ADDITION_SIMU  text
*      -->P_LT_ROLEAUTH  text
*      -->P_LT_ROLETCODE  text
*      -->P_LT_FUNCTTRAN_LOCAL  text
*      -->P_LT_FAOBJ_LOCAL  text
*      -->P_LT_RFCDES  text
*----------------------------------------------------------------------*
FORM load_simulated_role_content TABLES   it_simu_role_addition
STRUCTURE /psyng/sw_role_addition_simu
         et_simu_roleauth STRUCTURE /psyng/userauth
         et_simu_roletcode STRUCTURE /psyng/usertcode
         it_functran_local STRUCTURE /psyng/functtran
         it_faobj_local STRUCTURE /psyng/faobj2
         it_rfcdes STRUCTURE rfcdes.

  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu WITH
  HEADER LINE,
         l_agr_name     TYPE agr_name,
         lt_role_names  TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_faobj       TYPE TABLE OF /psyng/faobj2,
         lt_functtran   TYPE TABLE OF /psyng/functtran,
         lt_roleauth    TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
         lt_roletcode   TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
         l_rfcdes       TYPE rfcdest,
         lt_tcodes      TYPE TABLE OF /psyng/sw_par_tcode_output.
  DATA : l_continue TYPE flag,
   r_rfcs     TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE,
   lt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE.

  CONCATENATE sy-sysid sy-mandt INTO l_rfcdes.
  RANGES : range_roles FOR l_agr_name.
*  lt_unique_rfcs[] = it_simu_role_addition[].
  lt_unique_rfcs[] = gt_role_addition_simu[].
  SORT lt_unique_rfcs BY source_rfcdest.
DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs COMPARING source_rfcdest.

  LOOP AT it_simu_role_addition.
    REFRESH : range_roles.
    MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
    APPEND range_roles.
*    ENDLOOP.
    IF it_simu_role_addition-source_rfcdest IS INITIAL OR
       it_simu_role_addition-source_rfcdest = 'LOCAL' OR
       it_simu_role_addition-source_rfcdest = l_rfcdes.
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
        "(++)BOC UMITTAL SE VF scan-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        "(++)EOC UMITTAL SE VF scan-25/11/2024.
*--Update the destination RFCDEST
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
      CALL FUNCTION '/PSYNG/SW_102'
        DESTINATION it_simu_role_addition-source_rfcdest
*        DESTINATION lt_rfcdest-rfcdest
        TABLES
          it_roles_range = range_roles
          et_roles       = lt_role_names.        "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


      LOOP AT lt_role_names.
*--Load remote role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
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
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*        DESTINATION lt_unique_rfcs-source_rfcdest
          DESTINATION it_simu_role_addition-source_rfcdest
*          DESTINATION lt_rfcdest-rfcdest
          EXPORTING
            agr_name       = lt_role_names-agr_name
            bname          = '000000000000'
*           i_enhanced     = 'X'
          TABLES
            roleauth       = lt_roleauth
            roletcode      = lt_roletcode
            functtran      = lt_functtran
            faobj          = lt_faobj
          EXCEPTIONS
            role_not_found = 1
            OTHERS         = 2.                  "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

*--Update the destination RFCDEST
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
        agr_name <> ''  .
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE
        agr_name <> ''.
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
*&      Form  user_double_click_on_detl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_double_click_on_detl USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.

  DATA: functionid TYPE slis_selfield-value.
  DATA: iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  DATA:lt_tcodes TYPE TABLE OF /psyng/range_tcode WITH HEADER LINE.
  DATA:wa_tcodes  LIKE /psyng/range_tcode.
  DATA:wa_outputdet4 LIKE LINE OF lt_outdet,
       l_risktext    LIKE /psyng/sw_risk-text,
       l_repid       LIKE sy-repid,
       l_sod         TYPE /psyng/swsodvers-vrsio,
       l_fioriid     TYPE /psyng/sw_fioriid,
       l_hashcode    TYPE xupname,
       l_uname       LIKE sy-uname,
       l_parva       TYPE usr05-parva.

  DATA: l_agr_name  LIKE agr_define-agr_name,
        l_line(80),
        l_answer,
        l_authfield LIKE authx-fieldname,      "auth field
        l_iobjct    LIKE tobj-objct,
        l_conid     TYPE /psyng/conflict_id.





  CASE is_selfield-fieldname.

*----Auth Field
    WHEN 'FIELD'.
      CHECK is_selfield-value <> space.
      l_authfield = is_selfield-value.

      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
        EXPORTING
          fieldname = l_authfield.

*----User ID
    WHEN 'BNAME'.
      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
        EXPORTING
          defaultoption     = '1'
          diagnosetext1     = text-070
          diagnosetext2     = text-071
          textline1         = text-072
          text_option1      = text-073
          text_option2      = text-074
          icon_text_option1 = 'ICON_TBH'
          icon_text_option2 = 'ICON_HISTORY'
          titel             = text-075
          cancel_display    = 'X'
        IMPORTING
          answer            = l_answer.

      CASE l_answer.
        WHEN '1'.
*          AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
          IF sy-subrc = 1.
            SET PARAMETER ID 'XUS' FIELD is_selfield-value.
            CALL TRANSACTION 'SU01'.
          ELSE.
*            AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01D'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
            IF sy-subrc = 1.
              SET PARAMETER ID 'XUS' FIELD is_selfield-value.
              CALL TRANSACTION 'SU01D'.
            ELSE.
              MESSAGE e077(s#) WITH 'SU01D'.
            ENDIF.
          ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        WHEN '2'.

          DATA: userresponse, 1stmon(7), lastmon(7).

          CLEAR: ifields.
          REFRESH: ifields.

          PERFORM get_history_months USING 1stmon lastmon.

          ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
          ifields-fieldname = 'MMYYYYS'.
          ifields-fieldtext = text-076.
          ifields-value = 1stmon.
          APPEND ifields.
          ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
          ifields-fieldname = 'MMYYYYE'.
          ifields-fieldtext = text-077.
          ifields-value = lastmon.
          APPEND ifields.

          CLEAR userresponse.
          l_repid = sy-repid.
          CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
            EXPORTING
              formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
              programname       = l_repid
              popup_title       = text-078
              ok_pushbuttontext = text-079
            IMPORTING
              returncode        = userresponse
            TABLES
              fields            = ifields
            EXCEPTIONS
              error_in_fields   = 1
              OTHERS            = 2.

          IF sy-subrc <> 0.
            MESSAGE e208(00) WITH text-080.
          ENDIF.

          CHECK userresponse NE 'A'.             "#EC SAST_CI_GEN_CHECK
          "check to see user doesn't abort

          READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                                  fieldname = 'MMYYYYS'.
          CHECK NOT ifields-value IS INITIAL.
          1stmon = ifields-value.

          READ TABLE ifields WITH KEY tabname = '/PSYNG/SW_SEL_MON_YEAR'
                                                  fieldname = 'MMYYYYE'.
          CHECK NOT ifields-value IS INITIAL.
          lastmon = ifields-value.

          SUBMIT /psyng/sw_017
                  WITH pbname = is_selfield-value
                  WITH 1stmon = 1stmon
                  WITH lastmon = lastmon
                  WITH validusr = ' '
                  AND RETURN.
      ENDCASE.

*----Function ID
    WHEN 'FUNCTIONID'.
      CHECK is_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/FUN' FIELD is_selfield-value.
      g_dynnr = '0201'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      ELSE.
        CALL TRANSACTION '/PSYNG/SE'.
      ENDIF.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.

*----Transaction Code
    WHEN 'TCODE'.
      READ TABLE lt_outdet INDEX is_selfield-tabindex.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
          i_tcode = lt_outdet-tcode "is_selfield-value
          i_vrsio = sodvrsio
          i_funid = lt_outdet-functionid.
*----Auth. Object
    WHEN 'OBJCT'.
      CHECK is_selfield-value <> space.
      READ TABLE lt_outdet INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_iobjct = is_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
        EXPORTING
          object  = l_iobjct
          eu_mode = ' '.

*----High
    WHEN 'VON'.
      CHECK is_selfield-value <> space.
      READ TABLE lt_outdet INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  lt_outdet-objct EQ  gc_service
      AND lt_outdet-field  EQ gc_srv_name.
        l_hashcode = lt_outdet-von.
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
          fieldname       = lt_outdet-field
          object          = lt_outdet-objct
*       IMPORTING
*         SEL_VALUE       =
        EXCEPTIONS
          field_not_found = 1
          OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

*----Low
    WHEN 'BIS'.
      CHECK is_selfield-value <> space.
      READ TABLE lt_outdet INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
*--Drill down on the Value field for field SRV_NAME
*-- for Object S_SERVICE
      IF  lt_outdet-objct EQ  gc_service
      AND lt_outdet-field  EQ gc_srv_name.
        l_hashcode = lt_outdet-bis.
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
          fieldname       = lt_outdet-field
          object          = lt_outdet-objct
*       IMPORTING
*         SEL_VALUE       =
        EXCEPTIONS
          field_not_found = 1
          OTHERS          = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.

*----Profile
    WHEN 'PROFILE' OR 'COMP_PROF'.
      CHECK is_selfield-value <> space.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU02'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SU02'.
      ELSE.
        SET PARAMETER ID 'XUP' FIELD is_selfield-value.
        CALL TRANSACTION 'SU02'.
      ENDIF.

*----Role
    WHEN 'AGR_NAME' OR 'COMP_AGR'.
      CHECK is_selfield-value <> space.
      READ TABLE lt_outdet INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_agr_name = is_selfield-value.

      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
        EXPORTING
          defaultoption     = '1'
          diagnosetext1     = l_agr_name
          diagnosetext2     = text-085
          diagnosetext3     = text-086
          textline1         = text-087
          text_option1      = text-088
          text_option2      = text-089
          icon_text_option1 = 'ICON_DISPLAY'
          icon_text_option2 = 'ICON_CHECK'
          titel             = text-090
          cancel_display    = 'X'
        IMPORTING
          answer            = l_answer.

      CASE l_answer.
        WHEN '1'.
          PERFORM display_role_in_pfcg USING l_agr_name.
        WHEN '2'.
          PERFORM role_sod_analysis_from_details USING l_agr_name.
      ENDCASE.

  ENDCASE.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_history_months
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1STMON  text
*      -->P_LASTMON  text
*----------------------------------------------------------------------*
FORM get_history_months USING 1stmon lastmon.
  DATA: 1stmonth TYPE sy-datum, lastmont TYPE sy-datum.
  DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
        WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
    TABLES
      idirectory = idirectory.

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF 1stmonth IS INITIAL OR 1stmonth > idirectory-startdate.
      1stmonth = idirectory-startdate.
    ENDIF.
    IF lastmont < idirectory-startdate.
      lastmont = idirectory-startdate.
    ENDIF.
  ENDLOOP.

  CONCATENATE 1stmonth+4(2) '/' 1stmonth(4) INTO 1stmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.
ENDFORM.                    " get_history_months
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SOD  text
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
  CALL FUNCTION 'BAPI_USER_CHANGE'     "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      username   = l_uname
      parameterx = ls_paramx
    TABLES
      parameter  = lt_param
      return     = lt_return.

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  display_role_in_pfcg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_AGR_NAME  text
*----------------------------------------------------------------------*
FORM display_role_in_pfcg USING agr_name LIKE agr_define-agr_name.
  DATA: l_answer,
        l_repid LIKE sy-repid.


  CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
    EXPORTING
      defaultoption     = '1'
      diagnosetext1     = text-130
      diagnosetext2     = text-131
      diagnosetext3     = text-132
      textline1         = text-133
      text_option1      = text-134
      text_option2      = text-135
      icon_text_option1 = 'ICON_INCOMING_TASK'
      icon_text_option2 = 'ICON_OUTGOING_TASK'
      titel             = text-136
      cancel_display    = 'X'
    IMPORTING
      answer            = l_answer.

  CASE l_answer.
    WHEN '1'.
     CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
*           STARTING NEW TASK 'PFCG'
       EXPORTING
         agr_name      = agr_name
       EXCEPTIONS
         agr_not_found = 1
         OTHERS        = 2.
      IF sy-subrc <> 0.
        IF sy-subrc = 1.
          CLEAR pertext.
          CONCATENATE text-137 text-138
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-139 text-138 text-140
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ENDIF.
    WHEN '2'.
      DATA: l_userresponse, dflt_rfc LIKE /psyng/swconfig-value.

      CLEAR: ifields.
      REFRESH: ifields.

      se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
      IF ifields[] IS INITIAL.
        ifields-tabname = 'RFCDES'.
        ifields-fieldname = 'RFCDEST'.
        ifields-fieldtext = text-141.
        IF NOT dflt_rfc IS INITIAL.
          ifields-value = dflt_rfc.
        ENDIF.
        APPEND ifields.
      ENDIF.

      CLEAR l_userresponse.
      l_repid = sy-repid.
      CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
        EXPORTING
          formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
          programname       = l_repid
          popup_title       = text-142
          ok_pushbuttontext = text-143
        IMPORTING
          returncode        = l_userresponse
        TABLES
          fields            = ifields
        EXCEPTIONS
          error_in_fields   = 1
          OTHERS            = 2.

      IF sy-subrc <> 0.
        MESSAGE e208(00) WITH text-144.
      ENDIF.

      CHECK l_userresponse NE 'A'.  "check to see user doesn't abort

      READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                  fieldname = 'RFCDEST'.

*          CHECK NOT ifields-value IS INITIAL.
      IF ifields-value IS INITIAL.
        MESSAGE w208(00) WITH text-145.
      ENDIF.
      SELECT SINGLE * FROM rfcdes WHERE rfcdest = ifields-value AND
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
          DESTINATION ifields-value
*                STARTING NEW TASK 'PFCG'
          EXPORTING
            agr_name      = agr_name
          EXCEPTIONS
            agr_not_found = 1
            OTHERS        = 2.                   "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


        IF sy-subrc = 1.
          CLEAR pertext.
          CONCATENATE text-137 ifields-value
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ELSEIF sy-subrc = 2.
          CONCATENATE text-139 ifields-value text-140
                     INTO pertext SEPARATED BY space.
          MESSAGE i208(00) WITH pertext.
        ENDIF.
      ELSE.
        CLEAR pertext.
        CONCATENATE text-141 ifields-value text-146
                                 INTO pertext SEPARATED BY space.
        MESSAGE i208(00) WITH pertext.
      ENDIF.

    WHEN OTHERS.

  ENDCASE.

ENDFORM.                    " display_role_in_pfcg
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
          WITH orgchk   = g_orgchk "orgchk C0766
          WITH p_enhanc = p_enhanc
*          WITH p_hienhn  = p_hienhn
          WITH sodvrsio    = sodvrsio
          AND RETURN.

ENDFORM.                    " role_sod_analysis_from_details
*&---------------------------------------------------------------------*
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue     TYPE flag,
r_rfcs         TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE
,
r_rfcs_simu    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
                LINE,
l_rfcdes_local TYPE rfcdes-rfcoptions.



  r_rfcs-sign   = 'I'.
  r_rfcs-option = 'EQ'.
*--Role Simulation Destinations
  IF bysimu = 'X'.
    r_rfcs-low = ar_rfcd1.
    APPEND r_rfcs.
    r_rfcs-low    = ar_rfcd2.
    APPEND r_rfcs.
    r_rfcs-low   = ar_rfcd3.
    APPEND r_rfcs.
    r_rfcs-low    = ar_rfcd4.
    APPEND r_rfcs.
    r_rfcs-low    = ar_rfcs1.
    APPEND r_rfcs.
    r_rfcs-low    = ar_rfcs2.
    APPEND r_rfcs.
    r_rfcs-low    = ar_rfcs3.
    APPEND r_rfcs.
    r_rfcs-low   = ar_rfcs4.
    APPEND r_rfcs.
  ENDIF.
*--Role Removal  Simulation Destinations
  IF byrsimu = 'X'.
    r_rfcs-low    = rr_rfc_1.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_2.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_3.
    APPEND r_rfcs.
    r_rfcs-low    = rr_rfc_4.
    APPEND r_rfcs.
  ENDIF.

  r_rfcs_simu[] = r_rfcs[].
  APPEND LINES OF xusrrfc TO r_rfcs.

  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup    = 'X'
      i_module   = 'SE'
    IMPORTING
      e_continue = l_continue
    TABLES
      it_rfcdes  = r_rfcs.
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest, gt_rfcdest_anal.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs_simu
                 gt_rfcdest.


  PERFORM load_role_rfc
              TABLES
                xusrrfc
                gt_rfcdest_anal.

ENDFORM.                    " rfc_validations

*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_REMRFC  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
      it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
          rfcdest TYPE rfcdes-rfcdest,
        END OF lt_dest,
        lt_rfc_log       TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test       TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc.
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
*Case 2061 - If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
*            ANy rfc destination pointing to the local system will
*            be ignored
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.


ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  function_detail_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM function_detail_analysis.
  DATA: iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
*  READ TABLE gt_output INDEX is_selfield-tabindex.
*  CHECK sy-subrc = 0.
  CHECK NOT gt_output-funid = '----'.
  REFRESH : iseltab[].
  CLEAR iseltab.

  CLEAR gt_functions.
  READ TABLE gt_functions WITH KEY function = gt_output-funid.

  iseltab-selname = 'USERLIST'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gt_output-bname.
  APPEND iseltab.

  iseltab-selname = 'PCLASS'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gt_output-class.
  APPEND iseltab.

  iseltab-selname = 'XUSRRFC'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  IF gt_output-rfcdest = g_rfcdes_local.
    iseltab-low = ' '.
  ELSE.
    READ TABLE gt_rfcdest_anal WITH KEY rfcoptions = gt_output-rfcdest.
    IF sy-subrc = 0.
      iseltab-low     = gt_rfcdest_anal-rfcdest.
    ENDIF.
  ENDIF.
  APPEND iseltab.


  iseltab-selname = 'ORGCHK'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = orgchk.
  APPEND iseltab.

  iseltab-selname = 'P_REMONL'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_remonl.
  APPEND iseltab.

  iseltab-selname = 'ERROLES'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = erroles.
  APPEND iseltab.

  iseltab-selname = 'EXCL_ER'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = excl_er.
  APPEND iseltab.

  iseltab-selname = 'P_ENHANC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.

  iseltab-selname = 'SPFUN'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = gt_output-funid.
  APPEND iseltab.

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
  IF NOT gt_functions-busarea IS INITIAL.
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

  iseltab-selname = 'BYSIMU'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = bysimu.
  APPEND iseltab.


  iseltab-selname = 'WP'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = wp.
  APPEND iseltab.

  iseltab-selname = 'PSERVER'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = pserver.
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

  iseltab-selname = 'VALIDUSR'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = validusr.
  APPEND iseltab.

  LOOP AT usrtype .
    iseltab-selname = 'USRTYPE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = usrtype-sign.
    iseltab-option  = usrtype-option.
    iseltab-low     = usrtype-low.
    iseltab-high    = usrtype-high.
    APPEND iseltab.
  ENDLOOP.

  IF orgchk = 'X' AND NOT
  (  gt_output-org_abb = '*' OR  gt_output-org_abb IS INITIAL ).
    iseltab-selname = 'ORGLVL'.
    iseltab-kind    = 'S'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = gt_output-org_abb.
    APPEND iseltab.
  ENDIF.

  iseltab-selname = 'EXLCKUSR'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = exlckusr.
  APPEND iseltab.

  iseltab-selname = 'OUTVDATE'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = outvdate.
  APPEND iseltab.

  iseltab-selname = 'SHOWCOMP'.  "valid user: Show all users
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = showcomp.
  APPEND iseltab.


  iseltab-selname = 'P_FLAG'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_flag.
  APPEND iseltab.

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

  iseltab-selname = 'AR_RFCS1'.
  iseltab-low     =  ar_rfcs1.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD1'.
  iseltab-low     =  ar_rfcd1.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCS2'.
  iseltab-low     =  ar_rfcs2.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD2'.
  iseltab-low     =  ar_rfcd2.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCS3'.
  iseltab-low     =  ar_rfcs3.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD3'.
  iseltab-low     =  ar_rfcd3.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCS4'.
  iseltab-low     =  ar_rfcs4.
  APPEND iseltab.

  iseltab-selname = 'AR_RFCD4'.
  iseltab-low     =  ar_rfcd4.
  APPEND iseltab.

  LOOP AT ar_rol_1.
    iseltab-selname = 'AR_ROL_1'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_1 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT ar_rol_2.
    iseltab-selname = 'AR_ROL_2'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_2 TO iseltab.
    APPEND iseltab.
  ENDLOOP.
  LOOP AT ar_rol_3.
    iseltab-selname = 'AR_ROL_3'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_3 TO iseltab.
    APPEND iseltab.
  ENDLOOP.

  LOOP AT ar_rol_4.
    iseltab-selname = 'AR_ROL_4'.
    iseltab-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_4 TO iseltab.
    APPEND iseltab.
  ENDLOOP.


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


  program = sy-repid.
  SUBMIT (program)                           "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
WITH SELECTION-TABLE iseltab AND RETURN.
ENDFORM.                    " function_detail_analysis

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
