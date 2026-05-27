*----------------------------------------------------------------------*
* Report  /PSYNG/SW_CRIT_AUTHS                                         *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT  /psyng/sw_crit_auths MESSAGE-ID /psyng/sw
                             LINE-SIZE 195.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

DATA : g_nr_roles_analyzed TYPE i,
       g_dynnr        TYPE sy-dynnr,
       gf_dflt_enhance_matrix TYPE flag.

TABLES: /psyng/swaudc2,/psyng/swaudhdr, agr_define, rfcdes.
TYPE-POOLS: slis.                                      "For ALV call
INCLUDE /psyng/sw_113.
INCLUDE /psyng/sw_crit_auth_byrole_top.


SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-005.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_r
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.
SELECT-OPTIONS: roles FOR agr_define-agr_name.
SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN: COMMENT 1(21) text-013 MODIF ID rol.
SELECTION-SCREEN: POSITION 33.
PARAMETERS:   rchdatf LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN: COMMENT 47(3) text-014 MODIF ID rol.
SELECTION-SCREEN: POSITION 53.
PARAMETERS:   rchdatt LIKE agr_define-change_dat MODIF ID rol.
SELECTION-SCREEN PUSHBUTTON  65(10) text-019 USER-COMMAND shrl
MODIF ID rol.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: SKIP 1.
PARAMETERS : sodvrsio LIKE /psyng/conflict-vrsio MEMORY ID /psyng/vrsio.
SELECT-OPTIONS: paudid FOR /psyng/swaudc2-swaudid,
                s_imp FOR /psyng/swaudhdr-imp,
                s_owner FOR /psyng/swaudhdr-owner,
                s_barea FOR /psyng/swaudhdr-busarea.


*RFC options for remote analysis
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : shonoca TYPE flag.
SELECTION-SCREEN: COMMENT 3(50) text-094 FOR FIELD shonoca.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS : onlyrem TYPE flag.
PARAMETERS : onlyrem AS CHECKBOX USER-COMMAND remo
                                 MODIF ID rem.

SELECTION-SCREEN: COMMENT 3(47) text-093 FOR FIELD onlyrem.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : singrol TYPE flag DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(47) text-161 FOR FIELD singrol.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : comprol TYPE flag DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(47) text-162 FOR FIELD comprol.
SELECTION-SCREEN: END OF LINE.
*PARAMETERS : showcomp AS CHECKBOX NO-DISPLAY DEFAULT ' ' .
*"Show composite roles

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : assgn_r TYPE flag DEFAULT ' '.
SELECTION-SCREEN: COMMENT 3(47) text-182 FOR FIELD assgn_r.
SELECTION-SCREEN: END OF LINE.

PARAMETERS: p_shomit AS CHECKBOX.
*--Dynamic Enhancement
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 3(27) text-168 FOR FIELD p_enhanc
                                   MODIF ID exe.
PARAMETERS p_hienhn AS CHECKBOX
                                   MODIF ID exe.
SELECTION-SCREEN COMMENT 34(45) text-169 FOR FIELD p_hienhn
                                   MODIF ID exe.

SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: END OF BLOCK exe.
*--Simulation Block
SELECTION-SCREEN: BEGIN OF BLOCK sim_o WITH FRAME .
*SELECTION-SCREEN PUSHBUTTON  01(6) simu_but USER-COMMAND simu_but.
SELECTION-SCREEN COMMENT 1(50) text-b06 .

SELECTION-SCREEN INCLUDE BLOCKS b_sim.

SELECTION-SCREEN: END OF BLOCK sim_o.

SELECTION-SCREEN: BEGIN OF BLOCK out WITH FRAME TITLE text-009.
SELECTION-SCREEN: BEGIN OF LINE.



*PARAMETERS: alv RADIOBUTTON GROUP out1 DEFAULT 'X'.  "ALV output
*SELECTION-SCREEN: COMMENT 4(12) text-007.
*
*SELECTION-SCREEN: POSITION 20.
*PARAMETERS: std RADIOBUTTON GROUP out1.
*SELECTION-SCREEN: COMMENT 23(20) text-008.
PARAMETERS: sum RADIOBUTTON GROUP out1 DEFAULT 'X'
USER-COMMAND show.  "Summary Output
SELECTION-SCREEN: COMMENT 4(30) text-054 FOR FIELD sum.

SELECTION-SCREEN: POSITION 35.
PARAMETERS: det RADIOBUTTON GROUP out1.              "Detailed output
SELECTION-SCREEN: COMMENT 37(30) text-055 FOR FIELD det.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK out.


SELECTION-SCREEN: BEGIN OF BLOCK pblk WITH FRAME TITLE text-095.
PARAMETERS:ustb AS CHECKBOX DEFAULT ' '. "Update Scan table

PARAMETERS: odt AS CHECKBOX DEFAULT ' '. "output data to screen
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o01.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o02.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o03.
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 3(70) text-o04.
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK pblk.
*SELECTION-SCREEN: BEGIN OF BLOCK sim WITH FRAME TITLE text-h13.
*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS: bysimu AS CHECKBOX DEFAULT ' '.
*SELECTION-SCREEN: COMMENT 3(27) text-h14 FOR FIELD bysimu.
*SELECTION-SCREEN: POSITION 30.
*SELECT-OPTIONS: simurols FOR agr_define-agr_name. "simulation role
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 5(27) text-h15.
*PARAMETERS: rolerfc LIKE rfcdes-rfcdest MATCHCODE OBJECT
* /psyng/sw_rfcsh
*. "RFC destination for role
*SELECTION-SCREEN: END OF LINE.
*SELECTION-SCREEN: END OF BLOCK sim.



************************************
***********************************
SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-t11.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t06.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-t07.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-t09 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-t10 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK blk3.


INITIALIZATION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
* BOC by RGUPTA on 05.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 05.04.22 for C0700

  PERFORM exelog.
  PERFORM get_initial_config.
*---Default config param for enhanced sod matrix checkbox
  se_config_param 'DFLT_ENHANCE_MATRIX' gf_dflt_enhance_matrix.
  IF gf_dflt_enhance_matrix = 'Y' OR gf_dflt_enhance_matrix = 'X'.
    IF p_enhanc IS INITIAL.
      p_enhanc = 'X'.
       ENDIF.
    ELSE.
      CLEAR p_enhanc.
     ENDIF.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name .
      WHEN 'SHONOCA'.
        IF NOT paudid[] IS INITIAL OR
           NOT s_imp[] IS INITIAL  OR
           NOT s_owner[] IS INITIAL OR
           NOT s_barea[] IS INITIAL.
          screen-input = 0.
          MODIFY SCREEN.
               IF shonoca = 'X'.
          CLEAR shonoca.
          MESSAGE w398(00) WITH text-c03.
        ENDIF.
        ENDIF.
        IF det = 'X'.
          screen-input = '0'.
          IF shonoca = 'X'.
            CLEAR shonoca.
            MESSAGE w398(00) WITH text-c03.
          ENDIF.

          ELSE.
            IF paudid[] IS INITIAL AND
            s_imp[] IS INITIAL  AND
            s_owner[] IS INITIAL AND
            s_barea[] IS INITIAL.
              screen-input = 1.
            ENDIF.
          ENDIF.
          MODIFY SCREEN.
        WHEN 'P_HIENHN'.
          IF p_enhanc = space.
            screen-input = 0.
          ELSE.
            screen-input = 1.
          ENDIF.

          MODIFY SCREEN.
      ENDCASE.



    ENDLOOP.

AT SELECTION-SCREEN.
  SET PARAMETER ID '/PSYNG/VRSIO' FIELD sodvrsio.

  IF sy-ucomm = 'ENHANCE' AND p_enhanc = 'X'.
    p_hienhn = 'X'.
    MESSAGE s139(/psyng/sw).
  ENDIF.

  CASE sy-ucomm.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.

    WHEN 'SHRL'.
      PERFORM show_roles_based_on_dates.

    WHEN 'SCJB'.
      exit_proc = 'Y'.
      PERFORM schedule_back_job.

    WHEN 'ENHANCE'.
      IF p_enhanc = space.
        CLEAR p_hienhn.
      ELSE.
        p_hienhn = 'X'.
      ENDIF.
  ENDCASE.

  PERFORM check_input.

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
  DATA : lt_local_swaudhdr TYPE TABLE OF /psyng/swaudhdr,
         lt_local_swaudc   TYPE TABLE OF /psyng/swaudc2.

  DATA : lt_conflict   TYPE TABLE OF /psyng/conflict with header line,
         lt_confdet    TYPE TABLE OF /psyng/confdet,
         lt_functtran  TYPE TABLE OF /psyng/functtran,
         lt_faobj      TYPE TABLE OF /psyng/faobj2,
         lt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output.
  DATA : lt_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu,
         lt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu.
  DATA : lt_fm_output TYPE TABLE OF /psyng/sw_ca_routput
          WITH HEADER LINE,
         lt_fm_outputdet TYPE TABLE OF /psyng/sw_ca_routputdet
         WITH HEADER LINE,
         lt_confdet_sys   TYPE TABLE OF /psyng/confdet,
         lt_functtran_sys TYPE TABLE OF /psyng/functtran,
         lt_faobj_sys     TYPE TABLE OF /psyng/faobj2,
         l_system         TYPE /psyng/rfcname,
         lt_rfcdest       type table of /PSYNG/SW_SEL_OPTS_RFCDEST
                          with header line.


  SET PARAMETER ID '/PSYNG/VRSIO' FIELD sodvrsio.
*--Clear system filter buffer when a new analysis starts
  CALL FUNCTION '/PSYNG/SW_124'
    EXPORTING
      IF_CLEAR_BUFFER = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  program = sy-repid.
  IF exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_CRIT_AUTHS_BYROLE
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.
  EXELOG sy-repid ''.
  WRITE sy-datum TO l_date.

*--Check RFC destinations
  IF  bysimu = 'X'
  OR  byrsimu = 'X'
  OR NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.

*--Validate version
  SELECT SINGLE mandt FROM /psyng/swsodvers INTO sy-mandt
  WHERE vrsio = sodvrsio.
  IF sy-subrc <> 0.
    MESSAGE i156(/psyng/sw) WITH sodvrsio.
*   SOD Version does not exist &
    EXIT.
  ENDIF.

  PERFORM load_local_swauds
    TABLES
           lt_conflict
           lt_functtran
           lt_faobj
           lt_confdet
           lt_local_swaudhdr
           lt_local_swaudc
           lt_enh_tcodes.
  APPEND LINES OF lt_enh_tcodes TO gt_enh_tcodes.

  REFRESH : gt_role_removal_simu,gt_role_addition_simu.
  IF byrsimu = 'X'.
*--prepare table for role removal simulation
    PERFORM prepare_role_removal_simu
      TABLES lt_role_removal_simu.
    gt_role_removal_simu[] = lt_role_removal_simu[].
  ENDIF.
  IF bysimu = 'X'.
*--3.1 prepare table for role removal simulation
    PERFORM prepare_role_addition_simu
      TABLES lt_role_addition_simu.
    gt_role_addition_simu[] = lt_role_addition_simu[].
  ENDIF.

*----SE 3.2 - Validations
  PERFORM validate_other_fields.

  CASE det.
    WHEN 'X'.
      lt_role_addition_simu[] = gt_role_addition_simu[].
      lt_role_removal_simu[] = gt_role_removal_simu[].
      IF  NOT onlyrem = 'X'.
      DATA : lt_outputdet TYPE TABLE OF /psyng/sw_out_routdet3
              WITH HEADER LINE.
*--Filter Critical Auths by system
        concatenate sy-sysid sy-mandt into l_system .
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]     = lt_faobj[].
        lt_confdet_sys[]   = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS   = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


      CALL FUNCTION '/PSYNG/SW_083'
       EXPORTING
         i_bysimu                    = bysimu
         i_showcomp                  = showcomp
         i_sodvrsio                  = sodvrsio
         i_enhanc                    = p_enhanc
         i_hienhn                    = p_hienhn
         i_xmc                       = ''
         i_shonosod                  = shonoca
         i_rolerfc                   = rolerfc
         i_ronlyrem                  = onlyrem
         i_rchdatt                   = rchdatt
         i_rchdatf                   = rchdatf
         i_composite_roles           = comprol
         i_single_roles              = singrol
         i_shomit                    = p_shomit
         i_assigned_roles = assgn_r
       IMPORTING
         e_rolecount                 = l_nr_roles_analyzed
       TABLES
         it_roles                    = roles
*         it_rfcdest                 = remrfc
         it_simurols                 = simurols
         et_outputdet                = lt_outputdet
         et_enh_tcodes               = gt_enh_tcodes
         it_conflict                 = lt_conflict
         it_confdet                  = lt_confdet_sys
         it_functtran                = lt_functtran_sys
         it_faobj                    = lt_faobj_sys
         it_simu_role_removal        = lt_role_removal_simu
         it_simu_role_addition       = lt_role_addition_simu
                .
      CONCATENATE sy-sysid sy-mandt INTO lt_fm_outputdet-rfcdest.
      LOOP AT  lt_outputdet.
        lt_fm_outputdet-swaudid = lt_outputdet-conid.
        MOVE-CORRESPONDING lt_outputdet TO lt_fm_outputdet.
        APPEND lt_fm_outputdet.
      ENDLOOP.

      ENDIF.
      IF NOT gt_remote_anal_rfc[] IS INITIAL.



        LOOP AT gt_remote_anal_rfc INTO l_rfcdes.
**--Filter Critical Auths by system
*        l_system =  l_rfcdes-rfcoptions.
*        lt_functtran_sys[] = lt_functtran[].
*        lt_faobj_sys[]     = lt_faobj[].
*        lt_confdet_sys[]   = lt_confdet[].
*        CALL FUNCTION '/PSYNG/SW_124'
*          EXPORTING
*           IF_CA              = 'X'
*           i_system           = l_system
*           I_APPLICATION      = 'SAP'
*           i_vrsio            = sodvrsio
*         TABLES
*           IT_FUNCTTRAN        = lt_functtran_sys
*           IT_FAOBJ            = lt_faobj_sys
*           IT_CONFDET          = lt_confdet_sys.
          refresh :lt_rfcdest.
          lt_rfcdest-sign   = 'I'.
          lt_rfcdest-option = 'EQ'.
          lt_rfcdest-low =   l_rfcdes-rfcdest.
          append lt_rfcdest.
          l_taskname = l_rfcdes-rfcoptions.
          ADD 1 TO g_running_tasks.
          CALL FUNCTION '/PSYNG/SW_083'
*               STARTING NEW TASK l_taskname
*               DESTINATION l_rfcdes-rfcdest
*               DESTINATION ''
*               PERFORMING get_remote_results_det ON END OF TASK
             EXPORTING
               i_bysimu                    = bysimu
               i_showcomp                  = showcomp
               i_sodvrsio                  = sodvrsio
               i_enhanc                    = p_enhanc
               i_hienhn                    = p_hienhn
               i_xmc                       = ''
               i_shonosod                  = shonoca
               i_rolerfc                   = rolerfc
               i_ronlyrem                  = 'X'
               i_rchdatt                   = rchdatt
               i_rchdatf                   = rchdatf
               i_composite_roles           = comprol
               i_single_roles              = singrol
               i_shomit                    = p_shomit
               i_assigned_roles            = assgn_r
               if_ca                       = 'X'
*             IMPORTING
*               e_rolecount                 = l_nr_roles_analyzed
             TABLES
               it_roles                    = roles
               it_rfcdest                  = lt_rfcdest
               it_simurols                 = simurols
               et_outputdet                = lt_outputdet
               et_enh_tcodes               = gt_enh_tcodes
               it_conflict                 = lt_conflict
               it_confdet                  = lt_confdet
               it_functtran                = lt_functtran
               it_faobj                    = lt_faobj
               it_simu_role_removal        = lt_role_removal_simu
               it_simu_role_addition       = lt_role_addition_simu
                .
*          EXCEPTIONS
*              communication_failure = 1 MESSAGE l_system_msg
*              system_failure        = 2 MESSAGE l_system_msg
*              OTHERS                = 3.
*          IF sy-subrc <> 0.
*            CASE sy-subrc.
*              WHEN 1 OR 2.
*                MESSAGE e398(00) WITH
*                text-e01
*                l_rfcdes-rfcdest
*                l_system_msg.
*              WHEN 3.
*                MESSAGE e398(00) WITH
*                text-e01
*                l_rfcdes-rfcdest.
*            ENDCASE.
             LOOP AT  lt_outputdet.
              lt_fm_outputdet-swaudid = lt_outputdet-conid.
              MOVE-CORRESPONDING lt_outputdet TO lt_fm_outputdet.
              APPEND lt_fm_outputdet.
            ENDLOOP.

            COMMIT WORK.
*          ENDIF.
        ENDLOOP.
      ENDIF.
    WHEN ''.

*-- simulation before and after logic
      IF bysimu = 'X' OR byrsimu = 'X'.
        lt_role_addition_simu[] = gt_role_addition_simu[].
        lt_role_removal_simu[] = gt_role_removal_simu[].
        PERFORM before_after_simulation
        TABLES lt_role_removal_simu
               lt_role_addition_simu.
        EXIT.
      ENDIF.
*--Remote Role Analysis
      IF NOT gt_remote_anal_rfc[] IS INITIAL.

        LOOP AT gt_remote_anal_rfc INTO l_rfcdes.

*--Filter Critical Auths by system
        l_system =  l_rfcdes-rfcoptions.
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]    = lt_faobj[].
        lt_confdet_sys[]  = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


          l_taskname = l_rfcdes-rfcoptions.
          ADD 1 TO g_running_tasks.
          CALL FUNCTION '/PSYNG/SW_036'
             STARTING NEW TASK l_taskname
             DESTINATION l_rfcdes-rfcdest
             PERFORMING get_remote_results ON END OF TASK
             EXPORTING
                  vrsio             = sodvrsio
                  org_check         = ''
                  enh_fm            = p_enhanc
                  i_rchdatf         = rchdatf
                  i_rchdatt         = rchdatt
                  xstb_fm           = 'X'
                  i_local_sod       = ''
                  i_shonosod        = shonoca
                  i_composite_roles = comprol
                  i_single_roles    = singrol
                  i_shomit          = p_shomit
                  i_assigned_roles  = assgn_r
             TABLES
                  it_roles          = roles
                  it_roles_simu     = simurols
                  it_conflict       = lt_conflict
                  it_confdet        = lt_confdet_sys
                  it_functtran      = lt_functtran_sys
                  it_faobj          = lt_faobj_sys
                  it_tcodes         = lt_enh_tcodes
                  it_simurole_auth  = lt_simu_roleauth
                  it_simurole_tcode = lt_simu_roletcode
                  it_simurole_tcdaut = lt_simu_tcdaut
                  ot_routput_sum    = lt_routput_sum
                  et_mitigations    = gt_mitigations
              EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1 OR 2.
                MESSAGE e398(00) WITH
                text-e01
                l_rfcdes-rfcdest
                l_system_msg.
              WHEN 3.
                MESSAGE e398(00) WITH
                text-e01
                l_rfcdes-rfcdest.
            ENDCASE.
            COMMIT WORK.
          ENDIF.

        ENDLOOP.
      ENDIF.
      IF NOT onlyrem = 'X'.

*--Filter Critical Auths by system
        concatenate sy-sysid sy-mandt into l_system.
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]    = lt_faobj[].
        lt_confdet_sys[]  = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        CALL FUNCTION '/PSYNG/SW_036'
             EXPORTING
                  vrsio             = sodvrsio
                  org_check         = ''
                  enh_fm            = p_enhanc
                  i_rchdatf         = rchdatf
                  i_rchdatt         = rchdatt
                  xstb_fm           = 'X'
                  i_local_sod       = ' '
                  i_shonosod        = shonoca
                  i_composite_roles = comprol
                  i_single_roles    = singrol
                  i_shomit          = p_shomit
                  i_assigned_roles  = assgn_r
             IMPORTING
                  o_totalroles      = l_nr_roles_analyzed
             TABLES
                  it_roles          = roles
                  it_roles_simu     = simurols
                  it_conflict       = lt_conflict
                  it_confdet        = lt_confdet_sys
                  it_functtran      = lt_functtran_sys
                  it_faobj          = lt_faobj_sys
                  it_tcodes         = lt_enh_tcodes
                  it_simurole_auth  = lt_simu_roleauth
                  it_simurole_tcode = lt_simu_roletcode
                  it_simurole_tcdaut = lt_simu_tcdaut
                  ot_routput_sum    = lt_routput_sum
                  et_mitigations    = gt_mitigations.
       CONCATENATE  sy-sysid sy-mandt INTO lt_fm_output-rfcdest.
        LOOP AT lt_routput_sum.
          lt_fm_output-swaudid  = lt_routput_sum-conid.
          lt_fm_output-agr_name = lt_routput_sum-agr_name.
          lt_fm_output-agr_text = lt_routput_sum-agr_text.
          lt_fm_output-simu     = lt_routput_sum-simu.
          lt_fm_output-enhanced = lt_routput_sum-enhanced.
          lt_fm_output-contid   = lt_routput_sum-contid.
          APPEND lt_fm_output.
        ENDLOOP.
        ADD l_nr_roles_analyzed TO g_nr_roles_analyzed.
      ENDIF.
  ENDCASE.

  WAIT UNTIL g_running_tasks = 0.
  LOOP AT gt_return.
    MESSAGE  ID   gt_return-id
             TYPE gt_return-type
             NUMBER  gt_return-number
             WITH
             gt_return-message.
  ENDLOOP.




  FIELD-SYMBOLS : <o_sum> TYPE /psyng/sw_ca_routput,
                  <o_det> TYPE /psyng/sw_ca_routputdet.

  SELECT swaudid description imp busarea FROM /psyng/swaudhdr
   INTO CORRESPONDING FIELDS OF TABLE swaudhdr
  WHERE vrsio =   sodvrsio AND swaudid IN paudid
                           AND imp IN s_imp
                           AND owner IN s_owner
                           AND busarea IN s_barea.
*--Case 3073 : swaudhdr table was not sorted
  SORT swaudhdr BY swaudid.
  CASE det.
    WHEN 'X'.
*-process detailed fm output
      LOOP AT lt_fm_outputdet ASSIGNING <o_det>.
*--SF 2735 - Don't display /PSYNG/-SWAUDxxxx for tcode *
        CHECK NOT
          ( <o_det>-objct  EQ 'S_TCODE' AND
            <o_det>-von    CS '/PSYNG/-SWAUD' AND
            <o_det>-field  EQ 'TCD'
          ).
        IF <o_det>-tcode CS '/PSYNG/-SWAUD'.
          <o_det>-tcode = '*'.
        ENDIF.

        outputdet-swaudid     = <o_det>-swaudid.
        outputdet-agr_name    = <o_det>-agr_name.
        outputdet-tcode      = <o_det>-tcode.
        outputdet-objct      = <o_det>-objct.
        outputdet-auth       = <o_det>-auth.
        outputdet-field      = <o_det>-field.
        outputdet-von        = <o_det>-von.
        outputdet-bis        = <o_det>-bis.
        outputdet-simu       = <o_det>-simu.
        outputdet-enhanced = <o_det>-enhanced.

        IF <o_det>-child_agr <> <o_det>-agr_name.
          outputdet-child_agr  = <o_det>-child_agr.
        ELSE.
          CLEAR outputdet-child_agr.
        ENDIF.
        outputdet-rfcdest    = <o_det>-rfcdest.


        PERFORM get_role_text USING <o_det>-agr_name
                                    <o_det>-rfcdest
                              CHANGING outputdet-agr_text.


        IF p_hienhn = 'X'.
          IF outputdet-enhanced = 'X'.
            DELETE outputdet-color_cell
                   WHERE fname = 'SWAUDID'.
            color-col = '7'.   "Orange
            color-int = '1'.   "Intensified
            color-inv = '0'.   "Inverse
            cc-color  = color.
            cc-fname  = 'SWAUDID'.
            APPEND cc TO outputdet-color_cell.
            cc-fname  = 'TCODE'.
            APPEND cc TO outputdet-color_cell.
          ENDIF.
        ENDIF.


        READ TABLE swaudhdr WITH KEY swaudid = outputdet-swaudid
                            BINARY SEARCH.
        IF sy-subrc = 0.
          outputdet-description = swaudhdr-description.
        ENDIF.

        APPEND outputdet.
        CLEAR outputdet.
      ENDLOOP.

      IF outputdet[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
      ELSE.
        MESSAGE s176(/psyng/sw).
        CHECK odt = 'X'.
        PERFORM alv_output_det.
      ENDIF.
    WHEN OTHERS.
*- process summary output
      LOOP AT lt_fm_output ASSIGNING <o_sum>.
        CLEAR output.
        output-swaudid    = <o_sum>-swaudid.
        output-agr_name   = <o_sum>-agr_name.
        output-agr_text   = <o_sum>-agr_text.
        output-rfcdest    = <o_sum>-rfcdest.
        output-simu       = <o_sum>-simu.
        output-enhanced   = <o_sum>-enhanced.
        output-contid     = <o_sum>-contid.

        IF NOT <o_sum>-contid IS INITIAL.
          CLEAR gt_mitigations.
          READ TABLE gt_mitigations WITH KEY contid  = <o_sum>-contid
                                            swaudid  = <o_sum>-swaudid
                                            agr_name = <o_sum>-agr_name.
          output-auditor   = gt_mitigations-auditor.
          output-from_date = gt_mitigations-from_date.
          output-to_date   = gt_mitigations-to_date.
        ENDIF.

        READ TABLE swaudhdr WITH KEY swaudid = output-swaudid
                                     BINARY SEARCH.
        IF sy-subrc = 0.
          output-description = swaudhdr-description.
          output-imp = swaudhdr-imp.
          SELECT SINGLE text FROM /psyng/busarea     "#EC CI_SEL_NESTED
                INTO output-barea
               WHERE busarea = swaudhdr-busarea.
          IF sy-subrc NE 0.
            CLEAR output-barea.
          ENDIF.
          ADD 1 TO g_nr_auths.
        ELSEIF output-swaudid = '----'.
          CONCATENATE
          'No Critical authorizations based on SOD matrix'(n01)
          'defined in Security Weaver on'(n02)
          l_date
          INTO output-description SEPARATED BY space.
        ENDIF.
        APPEND output.
      ENDLOOP.
      IF ustb = 'X'.
*      Update scan table
*-- Check authority for updating scan table
        AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
                 ID 'Y&SW_ADMF' FIELD 'SUMMTAB'.
        IF sy-subrc NE 0.
          gf_st_missing_auth = 'X'.
        ELSE.
          PERFORM update_scan_table.
        ENDIF.
      ENDIF.

      MESSAGE s113(/psyng/sw) WITH
     'Found'(167) g_nr_auths 'Critical Auths.'(118).


      CHECK odt = 'X'.
      IF output[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
      ELSE.
        MESSAGE s176(/psyng/sw).
        PERFORM alv_output_sum.
      ENDIF.
  ENDCASE.

*---------------------------------------------------------------------*
*       FORM exelog                                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user. "sy-uname.
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
*&      Form  alv_output_sum
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_output_sum.
*  LOOP AT output.
*  ENDLOOP.
*
  PERFORM build_alv_catalog_sum.
  PERFORM output_using_alv_sum.
ENDFORM.                    " alv_output_sum

*&---------------------------------------------------------------------*
*&      Form  alv_output_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM alv_output_det.
  PERFORM build_alv_catalog_det.
  PERFORM output_using_alv_det.
ENDFORM.                    " alv_output_det

*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog_sum.
  program = sy-repid.
  REFRESH: i_fieldcat_alv.
  CLEAR: i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = program
            i_internal_tabname     = 'OUTPUT'
            i_inclname             = program
       CHANGING
            ct_fieldcat            = i_fieldcat_alv
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.

  IF sy-subrc <> 0.

  ENDIF.

* Manually building the field catalog, since
* REUSE_ALV_FIELDCATALOG_MERGE is not working properly




  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'AGR_TEXT'.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000080'.
  wa_fieldcat_alv-ddic_outputlen = '000080'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'SWAUDID'.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'ENHANCED'.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
*  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.



  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'IMP'.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  wa_fieldcat_alv-tabname = 'OUTPUT'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000010'.
  wa_fieldcat_alv-ddic_outputlen = '000010'.
*  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.


  wa_fieldcat_alv-seltext_m = text-038.
  wa_fieldcat_alv-seltext_s = text-038.
  wa_fieldcat_alv-reptext_ddic = text-038.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'AGR_NAME'.

  wa_fieldcat_alv-seltext_m = text-039.
  wa_fieldcat_alv-seltext_s = text-039.
  wa_fieldcat_alv-reptext_ddic = text-039.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'AGR_TEXT'.



  wa_fieldcat_alv-seltext_m = text-050.
  wa_fieldcat_alv-seltext_s = text-051.
  wa_fieldcat_alv-reptext_ddic = text-052.
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'SWAUDID'.

  wa_fieldcat_alv-seltext_m = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-seltext_s = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-reptext_ddic = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-seltext_l = 'Sensitivity Levels'(176).
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat_alv-seltext_m = 'Application Area'(183).
  wa_fieldcat_alv-seltext_s = 'Application Area'(183).
  wa_fieldcat_alv-reptext_ddic = 'Application Area'(183).
  wa_fieldcat_alv-seltext_l = 'Application Area'(183).
  wa_fieldcat_alv-col_pos = wa_fieldcat_alv-col_pos + 1.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      col_pos
                   WHERE
                      fieldname = 'BAREA'.

  IF p_enhanc = 'X'.
*  if highlight enhanced ruleset is selected, add this field to the alv
    wa_fieldcat_alv-seltext_l      = text-157.
    wa_fieldcat_alv-seltext_m      = text-157.
    wa_fieldcat_alv-seltext_s      = text-157.
    wa_fieldcat_alv-reptext_ddic   = text-157.
    wa_fieldcat_alv-checkbox       = 'X'.
    wa_fieldcat_alv-just       = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
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
    DELETE i_fieldcat_alv WHERE fieldname = 'ENHANCED'.
  ENDIF.
*************************************************
*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.



  CLEAR  wa_fieldcat_alv.
  IF bysimu = 'X' OR byrsimu = 'X'.
    wa_fieldcat_alv-seltext_l = text-170.
    wa_fieldcat_alv-seltext_m = text-170.
    wa_fieldcat_alv-seltext_s = text-170.
    wa_fieldcat_alv-reptext_ddic = text-170.
    wa_fieldcat_alv-checkbox     = 'X'.
    wa_fieldcat_alv-just       = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                     WHERE
                        fieldname = 'SIMU'.

    wa_fieldcat_alv-seltext_l = text-171.
    wa_fieldcat_alv-seltext_m = text-171.
    wa_fieldcat_alv-seltext_s = text-171.
    wa_fieldcat_alv-reptext_ddic = text-171.
    wa_fieldcat_alv-checkbox     = 'X'.
    wa_fieldcat_alv-just         = 'X'.
    wa_fieldcat_alv-hotspot      = 'X'.

    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                        hotspot
                     WHERE
                        fieldname = 'SIMU_BEFORE'.

    wa_fieldcat_alv-seltext_l = text-172.
    wa_fieldcat_alv-seltext_m = text-172.
    wa_fieldcat_alv-seltext_s = text-172.
    wa_fieldcat_alv-reptext_ddic = text-172.
    wa_fieldcat_alv-checkbox     = 'X'.
    wa_fieldcat_alv-just       = 'X'.
    wa_fieldcat_alv-hotspot = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                        checkbox
                        just
                        hotspot
                     WHERE
                        fieldname = 'SIMU_AFTER'.
*  wa_fieldcat_alv-no_out = ''.
*  wa_fieldcat_alv-col_pos      = '5'.
*  wa_fieldcat_alv-seltext_m    = text-170.
*  wa_fieldcat_alv-seltext_s    = text-170.
*  wa_fieldcat_alv-reptext_ddic = text-170.
*  wa_fieldcat_alv-checkbox     = 'X'.
*  wa_fieldcat_alv-just         = 'X'.
*  wa_fieldcat_alv-tabname = 'OUTPUT'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '000001'.
*  wa_fieldcat_alv-ddic_outputlen = '000001'.
*  wa_fieldcat_alv-fieldname = 'SIMU'.
**************************************************
*
*  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.
*
*  wa_fieldcat_alv-col_pos      = '5'.
*  wa_fieldcat_alv-seltext_m    = text-171.
*  wa_fieldcat_alv-seltext_s    = text-171.
*  wa_fieldcat_alv-reptext_ddic = text-171.
*  wa_fieldcat_alv-checkbox     = 'X'.
*  wa_fieldcat_alv-just         = 'X'.
*  wa_fieldcat_alv-tabname = 'OUTPUT'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '000001'.
*  wa_fieldcat_alv-ddic_outputlen = '000001'.
*  wa_fieldcat_alv-fieldname = 'SIMU_BEFORE'.
*  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.
*
*  wa_fieldcat_alv-col_pos      = '5'.
*  wa_fieldcat_alv-seltext_m    = text-172.
*  wa_fieldcat_alv-seltext_s    = text-172.
*  wa_fieldcat_alv-reptext_ddic = text-172.
*  wa_fieldcat_alv-checkbox     = 'X'.
*  wa_fieldcat_alv-just         = 'X'.
*  wa_fieldcat_alv-tabname = 'OUTPUT'.
*  wa_fieldcat_alv-inttype = 'C'.
*  wa_fieldcat_alv-intlen = '000001'.
*  wa_fieldcat_alv-ddic_outputlen = '000001'.
*  wa_fieldcat_alv-fieldname = 'SIMU_AFTER'.
*
*  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv.
  ELSE.
    DELETE i_fieldcat_alv WHERE fieldname = 'SIMU'.
    DELETE i_fieldcat_alv WHERE fieldname = 'SIMU_BEFORE'.
    DELETE i_fieldcat_alv WHERE fieldname = 'SIMU_AFTER'.
  ENDIF.
*--Hide mitigation fields when xmc <> 'X'
  IF p_shomit <> 'X'.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        no_out
                     WHERE
                           fieldname = 'CONTID'
                        OR fieldname = 'AUDITOR'
                        OR fieldname = 'FROM_DATE'
                        OR fieldname = 'TO_DATE'.
  ELSE.

    wa_fieldcat_alv-seltext_m = text-040.
    wa_fieldcat_alv-seltext_s = text-040.
    wa_fieldcat_alv-reptext_ddic = text-040.
    wa_fieldcat_alv-seltext_l = text-040.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                      seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'TO_DATE'.


    wa_fieldcat_alv-hotspot = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        hotspot
                     WHERE
                           fieldname = 'CONTID'.
  ENDIF.


ENDFORM.                    " build_alv_catalog
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_det
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog_det.

  REFRESH: i_fieldcat_alv_det.
  program = sy-repid.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = program
            i_internal_tabname     = 'OUTPUTDET'
            i_inclname             = program
       CHANGING
            ct_fieldcat            = i_fieldcat_alv_det
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.

  IF sy-subrc <> 0.

  ENDIF.

* Manually building the rest of the field catalog
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'AGR_NAME'.
  wa_fieldcat_alv-col_pos = '1'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000030'.
  wa_fieldcat_alv-ddic_outputlen = '000030'.
  wa_fieldcat_alv-seltext_m = text-038.
  wa_fieldcat_alv-seltext_s = text-038.
  wa_fieldcat_alv-reptext_ddic = text-038.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                      col_pos
                   WHERE
                      fieldname = 'AGR_NAME'.

  wa_fieldcat_alv-col_pos      = '2'.
  wa_fieldcat_alv-seltext_m    = text-039.
  wa_fieldcat_alv-seltext_s    = text-039.
  wa_fieldcat_alv-reptext_ddic = text-039.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AGR_TEXT'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'SWAUDID'.
  wa_fieldcat_alv-col_pos = '3'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000004'.
  wa_fieldcat_alv-ddic_outputlen = '000004'.
  wa_fieldcat_alv-seltext_m = text-050.
  wa_fieldcat_alv-seltext_s = text-051.
  wa_fieldcat_alv-reptext_ddic = text-052.
** Enabling hotspot as of SE 3.1 - HS
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  wa_fieldcat_alv-col_pos = '4'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv TRANSPORTING col_pos
         WHERE fieldname = 'DESCRIPTION'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'OBJCT'.
  wa_fieldcat_alv-col_pos = '5'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000010'.
  wa_fieldcat_alv-ddic_outputlen = '000010'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'AUTH'.
  wa_fieldcat_alv-col_pos = '6'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000012'.
  wa_fieldcat_alv-ddic_outputlen = '000012'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'FIELD'.
  wa_fieldcat_alv-col_pos = '7'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000010'.
  wa_fieldcat_alv-ddic_outputlen = '000010'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'VON'.
  wa_fieldcat_alv-col_pos = '8'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000018'.
  wa_fieldcat_alv-ddic_outputlen = '000018'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'BIS'.
  wa_fieldcat_alv-col_pos = '9'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000018'.
  wa_fieldcat_alv-ddic_outputlen = '000018'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-fieldname = 'CHILD_AGR'.
  wa_fieldcat_alv-col_pos = '10'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000030'.
  wa_fieldcat_alv-ddic_outputlen = '000030'.
  wa_fieldcat_alv-hotspot = 'X'.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.

*  rkanaka latest changes
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
  CLEAR  wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos      = '11'.
  wa_fieldcat_alv-seltext_m    = text-170.
  wa_fieldcat_alv-seltext_s    = text-170.
  wa_fieldcat_alv-reptext_ddic = text-170.
  wa_fieldcat_alv-checkbox     = 'X'.
  wa_fieldcat_alv-just    = 'X'.
  wa_fieldcat_alv-tabname = 'OUTPUTDET'.
  wa_fieldcat_alv-inttype = 'C'.
  wa_fieldcat_alv-intlen = '000001'.
  wa_fieldcat_alv-ddic_outputlen = '000001'.
  wa_fieldcat_alv-fieldname = 'SIMU'.

  IF bysimu = 'X'.
    wa_fieldcat_alv-no_out = ''.
  ELSE.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  INSERT wa_fieldcat_alv INTO TABLE i_fieldcat_alv_det.



  wa_fieldcat_alv-seltext_m = 'TCode'(063).
  wa_fieldcat_alv-seltext_s = 'TCode'(063).
  wa_fieldcat_alv-reptext_ddic = 'TCode'(063).
  wa_fieldcat_alv-hotspot = 'X'.

  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.

  wa_fieldcat_alv-seltext_m = 'Auth.object'(064).
  wa_fieldcat_alv-seltext_s = 'Auth.object'(064).
  wa_fieldcat_alv-reptext_ddic = 'Auth.object'(064).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'OBJCT'.


  wa_fieldcat_alv-seltext_m = 'Authorization'(065).
  wa_fieldcat_alv-seltext_s = 'Authorization'(065).
  wa_fieldcat_alv-reptext_ddic = 'Authorization'(065).
  wa_fieldcat_alv-hotspot = ' '.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'AUTH'.

  wa_fieldcat_alv-seltext_m  = 'Field'(069).
  wa_fieldcat_alv-seltext_s    =  'Field'(069).
  wa_fieldcat_alv-reptext_ddic =  'Field'(069).
  wa_fieldcat_alv-hotspot = 'X'.

  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'FIELD'.



  wa_fieldcat_alv-seltext_m = 'From'(066).
  wa_fieldcat_alv-seltext_s = 'From'(066).
  wa_fieldcat_alv-reptext_ddic = 'From'(066).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'VON'.


  wa_fieldcat_alv-seltext_m = 'To'(067).
  wa_fieldcat_alv-seltext_s =  'To'(067).
  wa_fieldcat_alv-reptext_ddic = 'To'(067).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'BIS'.

  wa_fieldcat_alv-seltext_m = 'Single/Child Role'(068).
  wa_fieldcat_alv-seltext_s =  'Single/Child Role'(068).
  wa_fieldcat_alv-reptext_ddic = 'Single/Child Role'(068).
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      hotspot
                   WHERE
                      fieldname = 'CHILD_AGR'.

*delete the color columns
  DELETE i_fieldcat_alv_det WHERE fieldname = 'COLOR_LINE'.
  DELETE i_fieldcat_alv_det WHERE fieldname = 'COLOR_CELL'.


  IF p_hienhn = 'X'.

*  if highlight enhanced ruleset is selected, add this field to the alv
    wa_fieldcat_alv-seltext_l      = text-157.
    wa_fieldcat_alv-seltext_m      = text-157.
    wa_fieldcat_alv-seltext_s      = text-157.
    wa_fieldcat_alv-reptext_ddic   = text-157.
    wa_fieldcat_alv-checkbox       = 'X'.
    wa_fieldcat_alv-just       = 'X'.
    MODIFY i_fieldcat_alv_det FROM wa_fieldcat_alv
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
    DELETE i_fieldcat_alv_det WHERE fieldname = 'ENHANCED'.
  ENDIF.


ENDFORM.                    " build_alv_catalog_det

*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv_sum.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.
  DATA: ls_swconfig_bkgd_job TYPE /psyng/swconfig.
  DATA: ls_line_count TYPE i.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_grid_titl = text-053.

  PERFORM build_sort_table_sum.
  PERFORM adjust_columns_sum.

* REPEAT_HDR_BKGDJOB Flag Check
  IF sy-batch EQ 'X'.
    se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.
    IF ls_swconfig_bkgd_job-value = 'N'.
      CLEAR g_repeat_hdr_bkgdjob.
      DESCRIBE TABLE output LINES ls_line_count.
      PERFORM set_print_param USING ls_line_count.
    ELSE.
      g_repeat_hdr_bkgdjob = 'X'.
    ENDIF.

  ENDIF.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'SUM_HEADER'
            i_grid_title             = alv_grid_titl
            i_callback_program       = program
            it_sort                  = isort
            i_callback_user_command  = 'USER_DOUBLE_CLICK_ON_SUM'
            is_layout                = alv_layout
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
       TABLES
            t_outtab                 = output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_using_alv
*&---------------------------------------------------------------------*
*&      Form  output_using_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv_det.
  DATA: alv_grid_titl TYPE lvc_title,
        alv_layout    TYPE slis_layout_alv,
        ls_variant    TYPE disvariant.


  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_grid_titl = text-053.

  MOVE 'COLOR_LINE' TO alv_layout-info_fieldname.
  MOVE 'COLOR_CELL' TO alv_layout-coltab_fieldname.

  PERFORM build_sort_table_det.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title            = alv_grid_titl
            i_callback_program      = program
            it_sort                 = isortdet
            i_callback_user_command = 'USER_DOUBLE_CLICK_ON_DET'
            is_layout               = alv_layout
            it_fieldcat             = i_fieldcat_alv_det
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = outputdet
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_using_alv

*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table_sum.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.



  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SWAUDID'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BAREA'.
  l_sort-tabname = 'OUTPUT'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.




ENDFORM.                    " build_sort_table
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table_det.
  DATA: l_sort TYPE slis_sortinfo_alv.


  l_sort-spos = '1'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AGR_TEXT'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SWAUDID'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'DESCRIPTION'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'OBJCT'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'AUTH'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'FIELD'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'VON'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BIS'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.

  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CHILD_AGR'.
  l_sort-tabname = 'OUTPUTDET'.
  l_sort-up = 'X'.
  APPEND l_sort TO isortdet.
ENDFORM.                    " build_sort_table_det

*&---------------------------------------------------------------------*
*&      Form  adjust_columns
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns_sum.


*--make all hotspot field uneditable
  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-edit = '1'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '1'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'AGR_NAME'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '2'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'AGR_TEXT'.


*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '3'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'NAME_TEXT'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '3'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'SWAUDID'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '4'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'DESCRIPTION'.

  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '5'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'IMP'.


  CLEAR wa_fieldcat_alv.
  wa_fieldcat_alv-col_pos = '6'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                   WHERE
                      fieldname = 'BUSAREA'.



*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '6'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'UFLAG'.
*
*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '7'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'TRDAT'.
*
*  CLEAR wa_fieldcat_alv.
*  wa_fieldcat_alv-col_pos = '8'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      col_pos
*                   WHERE
*                      fieldname = 'SODCOUNT'.

ENDFORM.                    " adjust_columns

*---------------------------------------------------------------------*
*       FORM user_double_click_on_det                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click_on_det USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.

  DATA : answer,line(80),
         iobjct    LIKE tobj-objct,
         l_authfield LIKE authx-fieldname,
         l_agr_name TYPE agr_name,
         i_auth LIKE /psyng/swaudhdr-swaudid,
         l_uname        LIKE sy-uname,
         l_contid TYPE /psyng/mchdr-contid,
         l_parva        TYPE usr05-parva,
         l_sod          TYPE /psyng/swsodvers-vrsio,
         ls_outputdet   like outputdet,
         l_tcode        type xutcode.

  CASE rs_selfield-fieldname.
    WHEN 'SWAUDID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/SW_CRIT_AUTH' FIELD rs_selfield-value.
      g_dynnr = '0209'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
    WHEN 'BNAME'.
      CLEAR answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
           EXPORTING
                defaultoption     = '1'
                diagnosetext1     =
     'You can view User Master Record (in transaction SU01) or'(070)
                diagnosetext2     =
     'view user''s transaction code execution history'(071)

                textline1         =
     'View user master or history?'(072)
                text_option1      =
     'User Master'(073)
                text_option2      =
     'User History'(074)
                icon_text_option1 = 'ICON_TBH'
                icon_text_option2 = 'ICON_HISTORY'
                titel             =
     'User Master or Transaction History'(075)
                cancel_display    = 'X'
           IMPORTING
                answer            = answer.

      CASE answer.
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
            SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
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
              SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
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
          ifields-fieldtext = text-081.
          ifields-value = 1stmon.
          APPEND ifields.
          ifields-tabname = '/PSYNG/SW_SEL_MON_YEAR'.
          ifields-fieldname = 'MMYYYYE'.
          ifields-fieldtext = text-082.
          ifields-value = lastmon.
          APPEND ifields.

          CLEAR userresponse.
          CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
               EXPORTING
                    formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
                    programname       = '/PSYNG/SODREPORT_ORG'
                    popup_title       =
               'Restrict months (available displayed)'(076)
                    ok_pushbuttontext = 'Continue'(077)
               IMPORTING
                    returncode        = userresponse
               TABLES
                    fields            = ifields
               EXCEPTIONS
                    error_in_fields   = 1
                    OTHERS            = 2.

          IF sy-subrc <> 0.
            MESSAGE e208(00) WITH 'Error when calling pop-up'(078).
          ENDIF.

          CHECK userresponse NE 'A'."#EC SAST_CI_GEN_CHECK
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
                  WITH pbname = rs_selfield-value
                  WITH 1stmon = 1stmon
                  WITH lastmon = lastmon
                  WITH validusr = ' '
                  AND RETURN.

      ENDCASE.
    WHEN 'TCODE'.
      CHECK rs_selfield-value <> '*'."only for real tcodes
      l_tcode = rs_selfield-value.
      CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
        EXPORTING
         i_tcode           = l_tcode.
    WHEN 'OBJCT'.
      CHECK rs_selfield-value <> space.
      READ TABLE outputdet INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      iobjct = rs_selfield-value.
      CALL FUNCTION 'SUSR_SHOW_OBJECT'
           EXPORTING
                object  = iobjct
                eu_mode = ' '.
    WHEN 'FIELD'.
      CHECK rs_selfield-value <> space.
      l_authfield = rs_selfield-value.


      CALL FUNCTION 'SUSR_AUTF_GET_F1_HELP'
           EXPORTING
                fieldname = l_authfield.

*      CALL FUNCTION 'SUSR_AUTH_FIELD_DOCU'
*           EXPORTING
*                fieldname       = authfield
*           EXCEPTIONS
*                field_not_found = 1
*                OTHERS          = 2.
*      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*      ENDIF.

    WHEN 'VON' OR 'BIS'.
      CHECK rs_selfield-value <> space.
      READ TABLE outputdet INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      CALL FUNCTION 'SUSR_AUTH_FIELD_VALUES'
        EXPORTING
          fieldname             = outputdet-field
          object                = outputdet-objct
*       IMPORTING
*         SEL_VALUE             =
        EXCEPTIONS
          field_not_found       = 1
          OTHERS                = 2.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ENDIF.
    WHEN 'CHILD_AGR' OR 'AGR_NAME'.
*      l_agr_name = rs_selfield-value.
*      CALL FUNCTION 'PRGN_SHOW_EDIT_AGR'
*           EXPORTING
*                agr_name      = l_agr_name
*           EXCEPTIONS
*                agr_not_found = 1
*                OTHERS        = 2.
      l_agr_name = rs_selfield-value.

      DATA: l_repid LIKE sy-repid,
            pertext(200).
      DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.


      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
           EXPORTING
                defaultoption     = '1'
diagnosetext1     =
'Source of this role may be a remote system.'(201)
                diagnosetext2     =
'You can display this role in a remote system.'(202)
                diagnosetext3     =
'You will need to specify a valid RFC Destination'(203)
                textline1         =
'Display local or remote role?'(204)
                text_option1      = 'Local'(205)
                text_option2      = 'Remote'(206)
                icon_text_option1 = 'ICON_INCOMING_TASK'
                icon_text_option2 = 'ICON_OUTGOING_TASK'
                titel             =
'Display Local or Remote Role'(207)
                cancel_display    = 'X'
           IMPORTING
                answer            = answer.
      CASE answer.
        WHEN '1'.
*       CHECK outputdet4-rfcdest+0(3) = sy-sysid AND  "Show only if role
*          outputdet4-rfcdest+3(3) = sy-mandt.     "in current system

  CALL FUNCTION 'PRGN_SHOW_EDIT_AGR' "#EC SAST_CI_GEN_CHECK (HBHALLA)
*      STARTING NEW TASK 'PFCG'
       EXPORTING
            agr_name = l_agr_name
       EXCEPTIONS
            agr_not_found = 1
            OTHERS        = 2.
          IF sy-subrc <> 0.
            IF sy-subrc = 1.
              CLEAR pertext.
              CONCATENATE text-207 text-208
                         INTO pertext SEPARATED BY space.
              MESSAGE i208(00) WITH pertext.
            ELSEIF sy-subrc = 2.
              CONCATENATE text-209 text-208 text-210
                         INTO pertext SEPARATED BY space.
              MESSAGE i208(00) WITH pertext.
            ENDIF.
          ENDIF.
        WHEN '2'.
          DATA: dflt_rfc LIKE /psyng/swconfig-value.

          CLEAR: ifields.
          REFRESH: ifields.

          se_config_param 'SW_DFLT_RFC_DEST' dflt_rfc.
          IF ifields[] IS INITIAL.
            ifields-tabname = 'RFCDES'.
            ifields-fieldname = 'RFCDEST'.
            ifields-fieldtext = 'RFC Destination'(213).
            IF NOT dflt_rfc IS INITIAL.
              ifields-value = dflt_rfc.
            ENDIF.
            APPEND ifields.
          ENDIF.

          CLEAR userresponse.
          l_repid = sy-repid.
          CALL FUNCTION 'POPUP_GET_VALUES_USER_BUTTONS'
               EXPORTING
                    formname          = 'DISPLAY_ROLE_OF_REMOTE_SYSTEM'
                    programname       = l_repid
                    popup_title       =
                    'Enter RFC Destination to the remote system'(211)
                    ok_pushbuttontext =
                    'Continue'(212)
               IMPORTING
                    returncode        = userresponse
               TABLES
                    fields            = ifields
               EXCEPTIONS
                    error_in_fields   = 1
                    OTHERS            = 2.

          IF sy-subrc <> 0.
            MESSAGE e208(00) WITH 'Error when calling pop-up'(214).
          ENDIF.

          CHECK userresponse NE 'A'. "#EC SAST_CI_GEN_CHECK
           "check to see user doesn't abort

          READ TABLE ifields WITH KEY tabname = 'RFCDES'
                                      fieldname = 'RFCDEST'.

*          CHECK NOT ifields-value IS INITIAL.
          IF ifields-value IS INITIAL.
            MESSAGE w208(00) WITH
            'Specify a RFC destination for remote lookup'(215).
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
                      agr_name = l_agr_name
             EXCEPTIONS
               agr_not_found       = 1
               OTHERS              = 2 ."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

            IF sy-subrc = 1.
              CLEAR pertext.
              CONCATENATE 'Role doesn''t exist in'(217)
                        ifields-value
                         INTO pertext SEPARATED BY space.
              MESSAGE i208(00) WITH pertext.
            ELSEIF sy-subrc = 2.
              CONCATENATE 'Could not open role in'(209)
                          ifields-value
                          'check authorizations in RFC Dest.'(210)
                         INTO pertext SEPARATED BY space.
              MESSAGE i208(00) WITH pertext.
            ENDIF.
          ELSE.
            CLEAR pertext.
            CONCATENATE 'RFC Destination'(213)
                         ifields-value
                         'doesn''t exist'(216)
                         INTO pertext SEPARATED BY space.
            MESSAGE i208(00) WITH pertext.
          ENDIF.
        WHEN OTHERS.

      ENDCASE.


  ENDCASE.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM user_double_click_on_sum                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_double_click_on_sum USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.

  DATA:   l_rsimu TYPE flag,
          lf_was_collapsed TYPE flag,
          l_uname        LIKE sy-uname,
*          l_contid TYPE /psyng/mchdr-contid,
          l_parva        TYPE usr05-parva,
          l_sod          TYPE /psyng/swsodvers-vrsio.

  DATA:  l_contid TYPE /psyng/mchdr-contid,
         l_rfc LIKE LINE OF gt_remote_anal_rfc.
*  DATA : ls_orglvl LIKE LINE OF orglvl.

  CASE r_ucomm.
    WHEN 'ROLESIMU'.
*      IF simu_but <> '@3T'.
*        lf_was_collapsed = 'X'.
**        PERFORM expand USING simu_but.
*      ENDIF.
      CALL SCREEN '0101' STARTING AT 10 10.
*      IF lf_was_collapsed = 'X'.
*        PERFORM collapse USING simu_but.
*      ENDIF.
      EXIT.
    WHEN 'ROLEREMDET'.
      CALL SCREEN '0102' STARTING AT 10 10.
      EXIT.
  ENDCASE.


  CASE rs_selfield-fieldname.
    WHEN 'SIMU_AFTER'.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF output-simu_after <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
         'This Critical Auth doesn''t exist after the change.'(m10)
       'Click the ''Before'' checkbox to view'(m11)
         .
        EXIT.
      ELSE.
        READ TABLE output INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0.
        PERFORM detail_role_analysis.
        EXIT.
      ENDIF.

    WHEN 'SIMU_BEFORE'.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF output-simu_before <> 'X'.

        MESSAGE i002(/psyng/sw) WITH
       'This Critical Auth didn''t exist before the change.'(m12)
       'Click the ''After'' checkbox to view'(m13).
        EXIT.
      ELSE.
        READ TABLE output INDEX rs_selfield-tabindex.
        CHECK sy-subrc = 0.
        IF byrsimu = 'X'.
          l_rsimu = 'X'.
          CLEAR byrsimu.
        ENDIF.
        PERFORM detail_role_analysis.
        IF l_rsimu = 'X'.
          byrsimu = 'X'.
        ENDIF.

        EXIT.
      ENDIF.

    WHEN 'SWAUDID'.
      READ TABLE output INDEX rs_selfield-tabindex.
      CHECK sy-subrc = 0.
      IF bysimu = 'X' OR byrsimu = 'X'.
        IF output-simu_after <> 'X'.
          MESSAGE i002(/psyng/sw) WITH
              'This Critical Auth doesn''t exist after the change.'(m10)
             'Click the ''Before'' checkbox to view'(m11).
          EXIT.
        ENDIF.
      ENDIF.
      PERFORM detail_role_analysis.
      EXIT.


    WHEN 'CONTID'.
*      l_contid = rs_selfield-value.
**--Read mitigation info
*      READ TABLE output INDEX rs_selfield-tabindex.
**      READ TABLE gt_mccarole WITH KEY agr_name = output-agr_name
**                                 swaudid  = output-swaudid
**                                 contid = output-contid.
*
**--Read RFC destination
*      READ TABLE gt_rfcdest WITH KEY rfcoptions = output-rfcdest.
*      IF sy-subrc <> 0.
*        l_rfc-rfcdest = 'LOCAL'.
*      ENDIF.
*
*      CALL FUNCTION '/PSYNG/SW_058'
*           EXPORTING
*                i_contid        = l_contid
*                i_rfcdest       = l_rfc-rfcdest
*           EXCEPTIONS
*                invalid_control = 1
*                OTHERS          = 2.
*      IF sy-subrc <> 0.
*        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*      ENDIF.
*
*      EXIT.

      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD rs_selfield-value.
      g_dynnr = '0211'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.


  ENDCASE.
*
*  PERFORM detail_role_analysis.
*
*  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
*  READ TABLE output INDEX rs_selfield-tabindex.
*  CHECK sy-subrc = 0.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_history_months
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
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



*---------------------------------------------------------------------*
*       SUM_HEADER                                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*

FORM sum_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_exedate TYPE char10,
        lv_exetime(8) TYPE c,
        lv_trolecount TYPE i,    "Progress indicator flag
        lv_cauthcount    TYPE i,
        lv_average       TYPE i,
        c_rolecount(6)  TYPE c,
        c_trolecount(6)   TYPE c,
        c_averagecon(4)  TYPE c,
        alv_grid_titl2   TYPE lvc_title.              "For ALV call
  STATICS:   l_pages TYPE c,
              l_pgcnt TYPE i.
*1STOUTPUT data
  DATA : lv_rolecount TYPE i,
         gl_rolecount TYPE i,
         gl_avgcon TYPE i.


  CLEAR: lv_rolecount, lv_average, lv_cauthcount.
  LOOP AT output.
    CHECK output-swaudid <> '---'.

    IF bysimu = 'X' OR byrsimu = 'X'.
      IF output-simu_after = 'X'.
        lv_cauthcount = lv_cauthcount + 1.
      ENDIF.
    ELSE.
      lv_cauthcount = lv_cauthcount + 1.
    ENDIF.
  ENDLOOP.
  DATA : output_count_roles LIKE TABLE OF output.
  IF output_count_roles[] IS INITIAL.
    output_count_roles[] = output[].
    SORT output_count_roles[] BY rfcdest agr_name.
    DELETE ADJACENT DUPLICATES FROM
      output_count_roles COMPARING rfcdest agr_name.
  ENDIF.
  DESCRIBE TABLE output_count_roles LINES lv_rolecount.
  lv_trolecount = g_nr_roles_analyzed.



  lv_average      = lv_cauthcount / lv_rolecount.
  c_rolecount  = lv_rolecount.
  c_averagecon = lv_average.
  c_trolecount = lv_trolecount.
  CONCATENATE  c_trolecount 'role(s) analyzed.'(089)
              'Avg'(090) c_averagecon
              'Crit. Auth(s) in'(091)
              c_rolecount 'role(s)'(092)
              INTO alv_grid_titl2 SEPARATED BY space.
  CONDENSE alv_grid_titl2.

*TITLE AREA
  wa-typ = 'H'.
  wa-info =
  'SW: Critical Authorizations Role Analysis Results'' Summary'(084).
  APPEND wa TO header.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date.
  WRITE sy-datum TO lv_exedate.
  wa-typ = 'S'.
  wa-key = 'User & Date'(085).
*  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
*              INTO exedate.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO lv_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user "sy-uname         C0700
   'on'(086) lv_exedate lv_exetime
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

*NEXT LINE.
  wa-typ = 'S'.
  wa-key = 'System Summary'(087).
  wa-info = alv_grid_titl2.
  APPEND wa TO header.
*-- Global Role Count
  REFRESH : output_count_roles[].
  CLEAR : alv_grid_titl2,lv_average.
  IF output_count_roles[] IS INITIAL.
    output_count_roles[] = output[].
    SORT output_count_roles[] BY agr_name.
    DELETE ADJACENT DUPLICATES FROM
      output_count_roles COMPARING agr_name.

    DESCRIBE TABLE output_count_roles LINES gl_rolecount.
    lv_average      = lv_cauthcount / gl_rolecount.
    c_rolecount  = gl_rolecount.
    c_averagecon = lv_average.
    c_trolecount = gl_rolecount.
    CONCATENATE  c_trolecount 'role(s) analyzed.'(089)
                'Avg'(090) c_averagecon
                'Crit. Auth(s) in'(091)
                c_rolecount 'role(s)'(092)
                INTO alv_grid_titl2 SEPARATED BY space.
    CONDENSE alv_grid_titl2.
  ENDIF.
*NEXT LINE.
  wa-typ = 'S'.
  wa-key = 'Global Summary'(088).
  wa-info = alv_grid_titl2.
  APPEND wa TO header.

* Page no in background job
  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    wa-typ = text-184.
    wa-key = text-185.
    CONDENSE l_pages NO-GAPS.
    wa-info = l_pages.
    APPEND wa TO header.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header
            i_logo             = 'Z_3SW_LOGO_JPG'.

*--Only output messages for each page when not in background mode.
  IF  sy-batch  IS INITIAL AND sy-binpt IS INITIAL .

    IF gf_st_missing_auth = 'X'.
      MESSAGE w191(/psyng/sw).
    ENDIF.

  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Get sod version default
  CALL FUNCTION '/PSYNG/SW_034'
       IMPORTING
            e_vrsio = sodvrsio.

  DATA: swconfig TYPE /psyng/swconfig.

*Update Scan Table
  CLEAR swconfig.
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.

  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSE.
    ustb = ' '.
  ENDIF.
  CLEAR swconfig.



*Show SOD Scan Output
  CLEAR swconfig.
  se_config_param 'DFLT_SHO_SCAN_RSLT' swconfig-value.

  IF swconfig-value = 'Y'.
    odt = 'X'.
  ELSEIF swconfig-value = 'N'.
    odt = ' '.
  ENDIF.
  CLEAR swconfig.

* Default RFC
  IF remrfc[] IS INITIAL.
    IF sy-saprl >= '620'.
*      l_table = 'TVARVC'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarvc
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ELSE.
*      l_table = 'TVARV'.
      SELECT * INTO CORRESPONDING FIELDS OF TABLE
        lt_tvarv FROM tvarv
           WHERE name = '/PSYNG/USER_XRFC'
             AND type = 'S'.
    ENDIF.

*    SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (l_table)
*           WHERE name = '/PSYNG/USER_XRFC'
*             AND type = 'S'.

    LOOP AT lt_tvarv.
      MOVE-CORRESPONDING lt_tvarv TO remrfc.
      remrfc-option = lt_tvarv-opti.
      APPEND remrfc.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_initial_config

*&---------------------------------------------------------------------*
*&      Form  get_role_text
*&---------------------------------------------------------------------*
*       Get role text
*----------------------------------------------------------------------*
*      -->I_AGR_NAME  Role name
*      <--E_AGR_TEXT  Role text
*----------------------------------------------------------------------*
FORM get_role_text USING    i_agr_name TYPE agr_name
                            i_rfc_dest TYPE rfcdest
                   CHANGING e_agr_text TYPE agr_title.

  TYPES: BEGIN OF t_role,
           rfc_dest TYPE rfcdest,
           agr_name TYPE agr_name,
           agr_text TYPE agr_title,
         END OF t_role.

  STATICS: lt_role TYPE HASHED TABLE OF t_role WITH UNIQUE KEY
           rfc_dest agr_name.

  DATA: ls_role TYPE t_role.


  READ TABLE lt_role INTO ls_role WITH TABLE KEY
  rfc_dest = i_rfc_dest
  agr_name = i_agr_name.
  IF sy-subrc = 0.
    e_agr_text = ls_role-agr_text.
    EXIT.
  ENDIF.

  READ TABLE gt_remote_anal_rfc INTO l_rfcdes
   WITH KEY rfcoptions = i_rfc_dest.
  IF sy-subrc EQ 0.
    CALL FUNCTION '/PSYNG/BC_021'
    DESTINATION l_rfcdes-rfcdest
      EXPORTING
        i_agr_name        = i_agr_name
             IMPORTING
               e_text     = e_agr_text
             EXCEPTIONS
               OTHERS     = 1. "#EC SAST_CI_GEN_CHECK
    IF sy-subrc = 0.
      ls_role-rfc_dest = i_rfc_dest.
      ls_role-agr_name = i_agr_name.
      ls_role-agr_text = e_agr_text.
      INSERT ls_role INTO TABLE lt_role.

    ENDIF.
  ELSE.

    SELECT SINGLE text INTO e_agr_text FROM agr_texts
                  WHERE agr_name = i_agr_name
                    AND spras    = sy-langu
                    AND line     = 0.
    CHECK sy-subrc = 0.
    ls_role-rfc_dest = i_rfc_dest.
    ls_role-agr_name = i_agr_name.
    ls_role-agr_text = e_agr_text.
    INSERT ls_role INTO TABLE lt_role.
  ENDIF.
ENDFORM.                    " get_role_text
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_input.
  DATA: BEGIN OF lt_dest OCCURS 0,
            rfcdest TYPE rfcdes-rfcdest,
          END OF lt_dest,
          lt_dest2 LIKE TABLE OF lt_dest,
         lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
         l_rfc_test TYPE rfctest,
         lt1_dest LIKE TABLE OF lt_dest WITH HEADER LINE,
         lt_remrfc TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
LINE.

  RANGES: lr_dest FOR rfcdes-rfcdest.

*----SE 3.2 - Verify Roles
  IF sy-ucomm = 'VERIFY_R'.
    PERFORM get_roles_count.
    EXIT.
  ENDIF.

  IF comprol IS INITIAL AND singrol IS INITIAL.
    MESSAGE e208(00) WITH
    'Select either Composite or Single Roles or both'(163).
  ENDIF.

  IF  NOT rchdatf IS INITIAL.
    IF rchdatt IS INITIAL .
      rchdatt = '99991231'.
    ENDIF.
    IF rchdatf > rchdatt.
      SET CURSOR FIELD 'RCHDATT'.
      MESSAGE e650(db).
    ENDIF.
  ELSEIF roles IS INITIAL AND sy-ucomm+0(1) <> '%' AND
                               sy-ucomm <> 'SHRL' AND
                               sy-ucomm <> 'RADI' AND
                               sy-ucomm NP '*BUT' AND
                               sy-ucomm <> 'SHOW'.
*2012/03/05 : Removing this message for consistency with user reports
*    SET CURSOR FIELD 'ROLE-LOW'.
*    MESSAGE e208(00) WITH text-031.
  ENDIF.
**Only remote analysis Check 26/12/2012
  IF sy-ucomm = 'REMO'.
    IF onlyrem = 'X'.
      IF remrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.


* Check RFC destinations
*  IF  bysimu = 'X'
*  OR  byrsimu = 'X'
*  OR NOT remrfc[] IS INITIAL.
*
*
*
*    APPEND LINES OF remrfc[] TO lr_dest.
*
*    IF NOT lr_dest[] IS INITIAL.
*      SELECT rfcdest INTO TABLE lt_dest FROM rfcdes
*                WHERE rfcdest IN lr_dest.
*      IF sy-subrc NE 0.
*        MESSAGE i135 WITH 'Invalid RFC Destination(s)'(196).
*        LEAVE LIST-PROCESSING.
*      ENDIF.
*    ENDIF.
*
*
**--Role Simulation Destinations
*    lt_dest-rfcdest = ar_rfcd1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd3.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcd4.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs3.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = ar_rfcs4.
*    APPEND lt_dest.
**--Role Removal  Simulation Destinations
*    lt_dest-rfcdest    = rr_rfc_1.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = rr_rfc_2.
*    APPEND lt_dest.
*    lt_dest-rfcdest    = rr_rfc_3.
*    APPEND lt_dest.
*
*    SORT lt_dest BY rfcdest.
*    LOOP AT lt_dest WHERE rfcdest <> '' AND rfcdest <> 'LOCAL'.
*      CLEAR lt_dest2.
*      APPEND lt_dest TO lt_dest2.
*      FREE : lt_rfc_log.
*      CALL FUNCTION 'RFC_WALK_THRU_TEST'
*        EXPORTING
*          test_in            = l_rfc_test
**         IMPORTING
**           TEST_OUT           =
*        TABLES
*          destinations       = lt_dest2
*          log                = lt_rfc_log.
*      LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*        PERFORM report_rfc_error USING
*        lt_rfc_log-rfcdest lt_rfc_log-rfclog .
*      ENDLOOP.
*      lt_remrfc-sign = 'I'.
*      lt_remrfc-option = 'EQ'.
*      lt_remrfc-low = lt_dest-rfcdest.
*      APPEND lt_remrfc.
*    ENDLOOP.
*  ENDIF.
*
*
*  FREE : gt_rfcdest.
*  PERFORM load_role_rfc
*              TABLES
*                 lt_remrfc
*                 gt_rfcdest.

*
*  LOOP AT lt_dest2.
*    gt_rfcdest-rfcdest = lt_dest2-rfcdest.
*    APPEND gt_rfcdest.
*  ENDLOOP.



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




** check rfc destinations
*  IF ( bysimu = 'X' AND NOT rolerfc IS INITIAL )
*  OR NOT remrfc[] IS INITIAL.
*
*    APPEND LINES OF remrfc TO lr_dest.
*    IF bysimu = 'X' AND NOT rolerfc IS INITIAL.
*      lr_dest-sign   = 'I'.
*      lr_dest-option = 'EQ'.
*      lr_dest-low    = rolerfc.
*      APPEND lr_dest.
*    ENDIF.
*
*    LOOP AT lr_dest.
*      CLEAR lt1_dest-rfcdest.
*      SELECT SINGLE rfcdest INTO lt1_dest-rfcdest FROM rfcdes
*             WHERE rfcdest = lr_dest-low.
*      IF sy-subrc = 0.
*        CLEAR lt1_dest-rfcdest.
*        CHECK NOT lr_dest-high IS INITIAL.
*        SELECT SINGLE rfcdest INTO lt1_dest-rfcdest FROM rfcdes
*               WHERE rfcdest = lr_dest-high.
*        IF sy-subrc <> 0.
*          MESSAGE e004(sr).
*        ENDIF.
*      ELSE.
*        MESSAGE e004(sr).
*      ENDIF.
*    ENDLOOP.
*
*    SELECT rfcdest INTO TABLE lt_dest FROM rfcdes
*              WHERE rfcdest IN lr_dest.
*
*    LOOP AT lt_dest.
*      CLEAR lt_dest2.
*      APPEND lt_dest TO lt_dest2.
*      FREE : lt_rfc_log.
*      CALL FUNCTION 'RFC_WALK_THRU_TEST'
*        EXPORTING
*          test_in            = l_rfc_test
**         IMPORTING
**           TEST_OUT           =
*        TABLES
*          destinations       = lt_dest2
*          log                = lt_rfc_log.
*      LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*        PERFORM report_rfc_error USING
*        lt_rfc_log-rfcdest lt_rfc_log-rfclog.
*      ENDLOOP.
*    ENDLOOP.
*  ENDIF.
*
*  IF bysimu = 'X' AND simurols[] IS INITIAL AND
*  ( sy-ucomm IS INITIAL OR sy-ucomm = 'ONLI' ).
*    MESSAGE i140(/psyng/sw) WITH
*    'Please enter role(s) for simulation'(181).
*    IF sy-batch = 'X'.
*      exit_proc = 'Y'.
*    ENDIF.
**    LEAVE LIST-PROCESSING.
*  ENDIF.

ENDFORM.                    " check_input
*---------------------------------------------------------------------*
*       FORM load_role_rfc                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_ROLE_RFC                                                   *
*  -->  ET_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_role_rfc
    TABLES
     it_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_rfc
             AND rfctype = '3'.
  ENDIF.
*  LOOP AT et_rfcdes.
*    FREE : lt_dest.
*    lt_dest-rfcdest = et_rfcdes-rfcdest.
*    APPEND lt_dest.
*    CALL FUNCTION 'RFC_WALK_THRU_TEST'
*         EXPORTING
*              test_in      = l_rfc_test
*         TABLES
*              destinations = lt_dest
*              log          = lt_rfc_log.
*    LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
*      PERFORM report_rfc_error USING
*      lt_rfc_log-rfcdest lt_rfc_log-rfclog.
*    ENDLOOP.
*  ENDLOOP.

  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
    CALL FUNCTION '/PSYNG/SW_062'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
*      CASE sy-subrc.
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH
*          text-e01
*          l_rfcdest
*          l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH
*          text-e01
*          l_rfcdest.
*      ENDCASE.
*      COMMIT WORK.
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

ENDFORM.
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
**&---------------------------------------------------------------------
**
**&      Form  load_local_swauds
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
**      -->P_LT_LOCAL_SWAUDHDR  text
**      -->P_LT_LOCAL_SCWAUDC  text
**----------------------------------------------------------------------
**
*FORM load_local_swauds TABLES
*  et_local_swaudhdr STRUCTURE /psyng/swaudhdr
*  et_local_scwaudc STRUCTURE  /psyng/swaudc2.
*  SELECT * FROM /psyng/swaudhdr
*            INTO TABLE et_local_swaudhdr
*            WHERE swaudid IN paudid
*            AND vrsio = sodvrsio.
*
*  SORT : et_local_swaudhdr.
*  IF NOT et_local_swaudhdr[] IS INITIAL.
*    SELECT * FROM /psyng/swaudc2
*     INTO  TABLE et_local_scwaudc
*     FOR ALL ENTRIES IN et_local_swaudhdr
*     WHERE vrsio = sodvrsio
*     AND swaudid = et_local_swaudhdr-swaudid
*     AND tcode   = et_local_swaudhdr-tcode
*     AND field <> ''. "ignore blank fields
*  ENDIF.
*
*
*ENDFORM.                    " load_local_swauds

*&---------------------------------------------------------------------*
*&      Form  load_local_swauds
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_LOCAL_SWAUDHDR  text
*      -->P_LT_LOCAL_SCWAUDC  text
*----------------------------------------------------------------------*
FORM load_local_swauds TABLES
    lt_conflict  STRUCTURE /psyng/conflict
    lt_functtran STRUCTURE /psyng/functtran
    lt_faobj     STRUCTURE /psyng/faobj2
    lt_confdet   STRUCTURE /psyng/confdet
    lt_local_swaudhdr STRUCTURE /psyng/swaudhdr
    lt_local_scwaudc  STRUCTURE /psyng/swaudc2
    lt_enh_tcodes STRUCTURE /psyng/sw_par_tcode_output.


*  data : lt_local_swaudhdr type table of /psyng/swaudhdr
*          with header line,
*         lt_local_scwaudc type table of /psyng/swaudc2
*         with header line.
  SELECT * FROM /psyng/swaudhdr
            INTO TABLE lt_local_swaudhdr
            WHERE swaudid IN paudid AND
                  imp IN s_imp AND
                  owner IN s_owner AND
                  busarea IN s_barea AND
                  vrsio = sodvrsio.
  IF sy-subrc NE 0.
*--Selection of conflicts showed no conflicts
    MESSAGE i135 WITH 'No Critical Auth ID(s) match selection'(199).
    LEAVE LIST-PROCESSING.
  ENDIF.

  SORT : lt_local_swaudhdr.
  IF NOT lt_local_swaudhdr[] IS INITIAL.
    SELECT * FROM /psyng/swaudc2
     INTO  TABLE lt_local_scwaudc
     FOR ALL ENTRIES IN lt_local_swaudhdr
     WHERE vrsio = sodvrsio
     AND swaudid = lt_local_swaudhdr-swaudid
     AND tcode   = lt_local_swaudhdr-tcode
     AND field <> ''. "ignore blank fields
  ENDIF.

*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.
  LOOP AT lt_local_swaudhdr.
    lt_conflict-conid       = lt_local_swaudhdr-swaudid.
    APPEND lt_conflict.
    lt_confdet-conid        = lt_local_swaudhdr-swaudid.
    lt_confdet-functionid   = lt_local_swaudhdr-swaudid.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_local_swaudhdr-swaudid.
    IF lt_local_swaudhdr-tcode = '*'.
      ADD 1 TO l_placeholder_counter.
      CONCATENATE '/PSYNG/-SWAUD' l_placeholder_counter
      INTO lt_functtran-tcode.
    ELSE.
      lt_functtran-tcode    = lt_local_swaudhdr-tcode.
    ENDIF.
    lt_functtran-vrsio    = lt_local_swaudhdr-vrsio.

    APPEND lt_functtran.
    LOOP AT lt_local_scwaudc WHERE swaudid = lt_local_swaudhdr-swaudid.
      MOVE-CORRESPONDING lt_local_scwaudc TO lt_faobj.
      lt_faobj-funid = lt_functtran-functionid.
      lt_faobj-tcode = lt_functtran-tcode.
      APPEND lt_faobj.
    ENDLOOP.
  ENDLOOP.
  CHECK p_enhanc = 'X'.
*Tcode enhancement
  CALL FUNCTION '/PSYNG/SW_065'
       EXPORTING
            i_vrsio      = sodvrsio
       TABLES
            it_functtran = lt_functtran
            it_faobj     = lt_faobj
            et_tcodes    = lt_enh_tcodes.


ENDFORM.                    " load_local_swauds



*&---------------------------------------------------------------------*
*&      Form  update_scan_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_scan_table.
  DATA : lt_scan TYPE TABLE OF /psyng/sw_cratd2 WITH HEADER LINE,
         lf_nodel TYPE flag.
  LOOP AT output.
    lt_scan-agr_name = output-agr_name.
    lt_scan-swaudid  = output-swaudid.
    lt_scan-scandate = sy-datum.
    lt_scan-vrsio    = sodvrsio.
    APPEND lt_scan.
  ENDLOOP.
  SORT lt_scan.
  DELETE ADJACENT DUPLICATES FROM lt_scan.
  IF NOT paudid[] IS INITIAL.
    lf_nodel = 'X'.
  ENDIF.
  CALL FUNCTION '/PSYNG/SW_UPDT_CRI_AUTH_INF2'
  IN BACKGROUND TASK

   EXPORTING
     nodelete       = lf_nodel
     vrsio          = sodvrsio
    TABLES
      syscandt      = lt_scan.
  COMMIT WORK.  "trigger execution of background processing of FMs


ENDFORM.                    " update_scan_table

*&---------------------------------------------------------------------*
*&      Form  show_roles_based_on_dates
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM show_roles_based_on_dates.
  DATA: tagr_define LIKE agr_define OCCURS 0 WITH HEADER LINE.
  DATA: ifield_dif LIKE field_dif OCCURS 0 WITH HEADER LINE.
  DATA: header(80), count TYPE i, count_char(9).
  DATA: wa_iagr_define TYPE agr_define.

  IF rchdatf IS INITIAL.
    MESSAGE i208(00) WITH text-096.
    EXIT.
  ENDIF.
  REFRESH tagr_define.
  SELECT agr_name create_dat change_usr change_dat change_tim
             INTO CORRESPONDING FIELDS OF wa_iagr_define
             FROM agr_define
             WHERE agr_name IN roles.
    IF rchdatf IS INITIAL.
      INSERT wa_iagr_define INTO TABLE tagr_define.
    ELSE.
      IF wa_iagr_define-change_dat IS INITIAL.
        CHECK wa_iagr_define-create_dat >= rchdatf AND
              wa_iagr_define-create_dat <= rchdatt.
        INSERT wa_iagr_define INTO TABLE tagr_define.
      ELSE.
        CHECK wa_iagr_define-change_dat >= rchdatf AND
              wa_iagr_define-change_dat <= rchdatt.
        INSERT wa_iagr_define INTO TABLE tagr_define.
      ENDIF.
    ENDIF.
  ENDSELECT.

  CHECK NOT tagr_define[] IS INITIAL.
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

  DESCRIBE TABLE tagr_define LINES count.
  MOVE count TO count_char.
  CONCATENATE count_char text-134 INTO header
              SEPARATED BY space.

  CALL FUNCTION 'STC1_POPUP_WITH_TABLE_CONTROL'
       EXPORTING
            header         = header
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF sy-subrc <> 0.
 MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
         WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
  ENDIF.

ENDFORM.                    " show_roles_based_on_dates


*---------------------------------------------------------------------*
*       FORM get_remote_results                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_remote_results USING taskname.
  DATA : lt_routput_sum   TYPE TABLE OF /psyng/sw_out_routput
          WITH HEADER LINE,
         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
         WITH HEADER LINE,
         lt_mitigations   TYPE TABLE OF /psyng/mitigation_assignment,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_036'

     IMPORTING
       o_totalroles         = l_numroles
         TABLES
       ot_routput_sum       = lt_routput_sum
       et_removed_roles     = lt_removed_roles
       et_mitigations       = lt_mitigations
      EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.
  IF sy-subrc = 0.
    ADD l_numroles TO g_nr_roles_analyzed.
    APPEND LINES OF lt_removed_roles TO gt_removed_roles.
    lt_fm_output-rfcdest = taskname.
    LOOP AT lt_routput_sum.

      lt_fm_output-swaudid  = lt_routput_sum-conid.
      lt_fm_output-agr_name = lt_routput_sum-agr_name.
      lt_fm_output-agr_text = lt_routput_sum-agr_text.
      lt_fm_output-simu     = lt_routput_sum-simu.
      lt_fm_output-contid   = lt_routput_sum-contid.
      APPEND lt_fm_output.
    ENDLOOP.
    FREE lt_removed_roles.
  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg
        INTO gt_return-message.
        COLLECT gt_return.
      WHEN 3.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        INTO gt_return-message.
        COLLECT gt_return.
    ENDCASE.

  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_remote_results                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_remote_results_det USING taskname.
  DATA : lt_outputdet   TYPE TABLE OF /psyng/sw_out_routdet3
         WITH HEADER LINE,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_083'
     IMPORTING
       e_rolecount         = l_numroles
     TABLES
       et_outputdet        = lt_outputdet
     EXCEPTIONS
       communication_failure = 1 MESSAGE l_system_msg
       system_failure        = 2 MESSAGE l_system_msg
       OTHERS                = 3.
  IF sy-subrc = 0.
    ADD l_numroles TO g_nr_roles_analyzed.
    lt_fm_outputdet-rfcdest = taskname.
    LOOP AT  lt_outputdet.
      lt_fm_outputdet-swaudid = lt_outputdet-conid.
      MOVE-CORRESPONDING lt_outputdet TO lt_fm_outputdet.
      APPEND lt_fm_outputdet.
    ENDLOOP.

  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg
        INTO gt_return-message.
        COLLECT gt_return.
      WHEN 3.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.

        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        INTO gt_return-message.
        COLLECT gt_return.
    ENDCASE.
  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report.


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
       EXCEPTIONS
            ILLEGAL_REPORT_OR_VARIANT       = 1
            ILLEGAL_VARIANTNAME             = 2
            NOT_AUTHORIZED                  = 3
            NOT_EXECUTED                    = 4
            REPORT_NOT_EXISTENT             = 5
            REPORT_NOT_SUPPLIED             = 6
            VARIANT_EXISTS                  = 7
            VARIANT_LOCKED                  = 8
            OTHERS        .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = text-t12  "'Critical Authorizations by role'
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
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id.
*  DATA: oldnumber(7) TYPE n, oldnumber_c(7).
*
  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.


*--C017 Odubey 29/11/2021
CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
  EXPORTING
    i_report        = sy-repid
 IMPORTING
   E_VARIANT       = variant.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.

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
  REFRESH : irsparams.
*Select options


  LOOP AT roles.
    irsparams-selname = 'ROLES'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING roles TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT paudid.
    irsparams-selname = 'PAUDID'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING paudid TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_imp.
    irsparams-selname = 'S_IMP'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_imp TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_owner.
    irsparams-selname = 'S_OWNER'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_owner TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT s_barea.
    irsparams-selname = 'S_BAREA'.
    irsparams-kind = 'S'.
    MOVE-CORRESPONDING s_barea TO irsparams.
    APPEND irsparams.
  ENDLOOP.

*Parameters


  irsparams-selname = 'RCHDATF'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = rchdatf.
  APPEND irsparams.

  irsparams-selname = 'RCHDATT'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = rchdatt.
  APPEND irsparams.

  irsparams-selname = 'SODVRSIO'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = sodvrsio.
  APPEND irsparams.

  irsparams-selname = 'SHONOCA'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = shonoca.
  APPEND irsparams.

  irsparams-selname = 'ONLYREM'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = onlyrem.
  APPEND irsparams.

  irsparams-selname = 'SINGROL'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = singrol.
  APPEND irsparams.

  irsparams-selname = 'COMPROL'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = comprol.
  APPEND irsparams.

  irsparams-selname = 'DET'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = det.
  APPEND irsparams.

  irsparams-selname = 'SUM'.
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = sum.
  APPEND irsparams.


  irsparams-selname = 'SHOWCOMP'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = showcomp.
  APPEND irsparams.

  irsparams-selname = 'USTB'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = ustb.
  APPEND irsparams.

  irsparams-selname = 'BYSIMU'.     " By Simulate
  irsparams-kind = 'P'.
  irsparams-sign = 'I'.
  irsparams-option = 'EQ'.
  irsparams-low = bysimu.
  APPEND irsparams.

*--Role addition Simulation
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.

  irsparams-selname = 'AR_RFCS1'.
  irsparams-low     =  ar_rfcs1.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCD1'.
  irsparams-low     =  ar_rfcd1.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCS2'.
  irsparams-low     =  ar_rfcs2.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCD2'.
  irsparams-low     =  ar_rfcd2.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCS3'.
  irsparams-low     =  ar_rfcs3.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCD3'.
  irsparams-low     =  ar_rfcd3.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCS4'.
  irsparams-low     =  ar_rfcs4.
  APPEND irsparams.

  irsparams-selname = 'AR_RFCD4'.
  irsparams-low     =  ar_rfcd4.
  APPEND irsparams.

  LOOP AT ar_rol_1.
    irsparams-selname = 'AR_ROL_1'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_1 TO irsparams.
    APPEND irsparams.
  ENDLOOP.
  LOOP AT ar_rol_2.
    irsparams-selname = 'AR_ROL_2'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_2 TO irsparams.
    APPEND irsparams.
  ENDLOOP.
  LOOP AT ar_rol_4.
    irsparams-selname = 'AR_ROL_3'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_3 TO irsparams.
    APPEND irsparams.
  ENDLOOP.

  LOOP AT ar_rol_4.
    irsparams-selname = 'AR_ROL_4'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING ar_rol_4 TO irsparams.
    APPEND irsparams.
  ENDLOOP.

*--Role Removal Simulation
  irsparams-selname = 'BYRSIMU'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = byrsimu.
  APPEND irsparams.

  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.

  irsparams-selname = 'RR_RFC_1'.
  irsparams-low     =  rr_rfc_1.
  APPEND irsparams.

  irsparams-selname = 'RR_RFC_2'.
  irsparams-low     =  rr_rfc_2.
  APPEND irsparams.

  irsparams-selname = 'RR_RFC_3'.
  irsparams-low     =  rr_rfc_3.
  APPEND irsparams.

  irsparams-selname = 'RR_RFC_4'.
  irsparams-low     =  rr_rfc_4.
  APPEND irsparams.

  LOOP AT rr_rol_1.
    irsparams-selname = 'RR_ROL_1'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_1 TO irsparams.
    APPEND irsparams.
  ENDLOOP.
  LOOP AT rr_rol_2.
    irsparams-selname = 'RR_ROL_2'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_2 TO irsparams.
    APPEND irsparams.
  ENDLOOP.
  LOOP AT rr_rol_3.
    irsparams-selname = 'RR_ROL_3'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_3 TO irsparams.
    APPEND irsparams.
  ENDLOOP.
  LOOP AT rr_rol_4.
    irsparams-selname = 'RR_ROL_4'.
    irsparams-kind    = 'S'.
    MOVE-CORRESPONDING rr_rol_4 TO irsparams.
    APPEND irsparams.
  ENDLOOP.




  irsparams-selname = 'SODVRSIO'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = sodvrsio.
  APPEND irsparams.

  irsparams-selname = 'ODT'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = 'X'.
  APPEND irsparams.

*  irsparams-selname = 'DET'.
*  irsparams-kind    = 'P'.
*  irsparams-sign    = 'I'.
*  irsparams-option  = 'EQ'.
*  irsparams-low     = 'X'.
*  APPEND irsparams.

  irsparams-selname = 'SUM'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = 'X'.
  APPEND irsparams.

  irsparams-selname = 'P_SHOMIT'.
  irsparams-kind    = 'P'.
  irsparams-sign    = 'I'.
  irsparams-option  = 'EQ'.
  irsparams-low     = p_shomit.
  APPEND irsparams.

*  irsparams-selname = 'ROLES'.
*  irsparams-kind    = 'S'.
*  irsparams-sign    = 'I'.
*  irsparams-option  = 'EQ'.
*  irsparams-low     = output-agr_name.
*  APPEND irsparams.
*
*  irsparams-selname = 'PAUDID'.
*  irsparams-kind    = 'S'.
*  irsparams-sign    = 'I'.
*  irsparams-option  = 'EQ'.
*  irsparams-low     = output-swaudid.
*  APPEND irsparams.




ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  set_print_param
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LS_LINE_COUNT  text
*----------------------------------------------------------------------*
FORM set_print_param USING    p_line_count.
  p_line_count = p_line_count + 25 .
  CALL FUNCTION 'SET_PRINT_PARAMETERS'
       EXPORTING
            line_count = p_line_count.
ENDFORM.                    " set_print_param
*&---------------------------------------------------------------------*
*&      Form  get_roles_count
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_roles_count.
  DATA : lt_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_assnroles TYPE TABLE OF agr_users WITH HEADER LINE,
         l_numb TYPE i,
         l_numb_total type i.
  RANGES: idatseltab FOR sy-datum.
  PERFORM rfc_validations.
  CHECK gf_invalid_rfc  IS INITIAL.

*--Local Roles
  if onlyrem is initial.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = assgn_r
              i_rchdatf         = rchdatt
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = roles.
    add l_numb to l_numb_total.
  endif.
*--Remote roles
  LOOP AT gt_remote_anal_rfc.
    CALL FUNCTION '/PSYNG/SW_GET_ROLES'
    DESTINATION gt_remote_anal_rfc-rfcdest
         EXPORTING
              i_composite_roles = comprol
              i_single_roles    = singrol
              i_assigned_roles  = assgn_r
              i_rchdatf         = rchdatf
              i_rchdatt         = rchdatt
         IMPORTING
              e_count           = l_numb
         TABLES
              it_roles          = roles. "#EC SAST_CI_GEN_CHECK
    ADD l_numb TO l_numb_total.
  ENDLOOP.

  MESSAGE i002 WITH 'Number of roles(s) will be analyzed : '(r01)
  l_numb_total.
ENDFORM.                    " get_roles_count

*&---------------------------------------------------------------------*
*&      Form  validate_other_fields
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM validate_other_fields.

  DATA : l_vrsio TYPE /psyng/sodvrsio,
         l_rfcdest TYPE rfcdes-rfcdest,
         lt_roles TYPE TABLE OF /psyng/bc_agr_name,
         ls_rfcdest TYPE /psyng/sw_sel_opts_rfcdest,
         l_rfcdest_local TYPE rfcdes-rfcdest,
         lt_excluding TYPE  slis_t_extab,
         ls_excluding TYPE slis_extab,
         l_repid          LIKE sy-repid,
         lt_fcat          TYPE slis_t_fieldcat_alv,
         ls_fcat          LIKE LINE OF lt_fcat,
         l_exit.

  DATA : BEGIN OF lt_rfc_roles OCCURS 0,
         rfcdest TYPE rfcdes-rfcdest,
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

*--RFC
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest_local.

**--Validation of SOD version
*  SELECT SINGLE vrsio INTO (l_vrsio) FROM /psyng/swsodvers
*  WHERE vrsio = sodvrsio.
*  IF sy-subrc NE 0.
*    MESSAGE i135 WITH 'SOD Version does not exist.'(195).
*    LEAVE LIST-PROCESSING.
*  ENDIF.

  IF bysimu = 'X'.
*-- Validate Source RFC
    IF NOT ar_rol_1[] IS INITIAL.
      IF NOT ar_rfcs1 = '' AND
         NOT ar_rfcs1 = 'LOCAL' AND
         NOT ar_rfcs1 = l_rfcdest_local.
        READ TABLE gt_rfcdest WITH KEY rfcdest = ar_rfcs1.
        IF sy-subrc = 0.
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.

*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2."#EC SAST_CI_GEN_CHECK
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
*            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
*            LEAVE LIST-PROCESSING.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = ar_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_1
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_2
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.

          ENDIF.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_3
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
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
          CALL FUNCTION '/PSYNG/BC_VALIDATE_GET_ROLES'
          DESTINATION gt_rfcdest-rfcdest
            TABLES
              it_agr_name               = rr_rol_4
              et_roles                  = lt_roles
           EXCEPTIONS
             role_does_not_exist       = 1
             OTHERS                    = 2. "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
            MESSAGE i135 WITH 'Role(s) does not exist.'(197).
            LEAVE LIST-PROCESSING.
          ENDIF.
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



ENDFORM.                    " validate_other_fields
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
FORM prepare_role_addition_simu  TABLES   et_role_addition_simu
STRUCTURE
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
*&      Form  before_after_simulation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ROLE_REMOVAL_SIMU  text
*      -->P_LT_ROLE_ADDITION_SIMU  text
*----------------------------------------------------------------------*
FORM before_after_simulation TABLES   it_role_removal_simu STRUCTURE
                                          /psyng/sw_role_removal_simu
                                      it_role_addition_simu STRUCTURE
                                          /psyng/sw_role_addition_simu.

  DATA : lt_simu_roleauth TYPE TABLE OF /psyng/roleauth
         WITH HEADER LINE,
         lt_simu_roletcode TYPE TABLE OF /psyng/roletcode
         WITH HEADER LINE,
         lt_simu_roleauth_part TYPE TABLE OF /psyng/roleauth
         WITH HEADER LINE,
         lt_simu_roletcode_part TYPE TABLE OF /psyng/roletcode
         WITH HEADER LINE,
         lt_roleauth TYPE TABLE OF /psyng/userauth
         WITH HEADER LINE,
         lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
      WITH HEADER LINE.
  DATA : l_local_rfc TYPE rfcdest,
        lt1_role_removal_simu TYPE TABLE OF /psyng/sw_role_removal_simu
                             WITH HEADER LINE.

  IF bysimu = 'X'.
    PERFORM load_simulated_role_content
     TABLES
       it_role_addition_simu
       lt_simu_roleauth
       lt_simu_roletcode
       lt_functtran
       lt_faobj
       gt_remote_anal_rfc.
  ENDIF.

*-- Before Analysis
  IF NOT gt_remote_anal_rfc[] IS INITIAL.

    LOOP AT gt_remote_anal_rfc INTO l_rfcdes.


*--Filter Critical Auths by system
        l_system           =  l_rfcdes-rfcoptions.
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]     = lt_faobj[].
        lt_confdet_sys[]   = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2.
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      l_taskname = l_rfcdes-rfcoptions.
      ADD 1 TO g_running_tasks.
      CALL FUNCTION '/PSYNG/SW_036'
         STARTING NEW TASK l_taskname
         DESTINATION l_rfcdes-rfcdest
         PERFORMING get_remote_results ON END OF TASK
         EXPORTING
              vrsio          = sodvrsio
              org_check      = ''
              enh_fm         = p_enhanc
              i_rchdatf      = rchdatf
              i_rchdatt      = rchdatt
*              i_simu_rfc     = rolerfc
              xstb_fm        = 'X'
*              i_bysimu       = bysimu
              i_local_sod    = ''
              i_shonosod     = shonoca
              i_composite_roles    = comprol
              i_single_roles       = singrol
              i_shomit             = p_shomit
              i_assigned_roles = assgn_r

*         IMPORTING
*              o_totalroles   = l_nr_roles_analyzed
         TABLES
              it_roles       = roles
              it_roles_simu  = simurols
*              it_confs       = spconfs
*              it_sens        = sens
              it_conflict    = lt_conflict
              it_confdet     = lt_confdet_sys
              it_functtran   = lt_functtran_sys
              it_faobj       = lt_faobj_sys
              it_tcodes      = lt_enh_tcodes
              ot_routput_sum = lt_routput_sum
              et_mitigations = gt_mitigations
          EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e01
            l_rfcdes-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e01
            l_rfcdes-rfcdest.
        ENDCASE.
        COMMIT WORK.
      ENDIF.

    ENDLOOP.
  ENDIF.
  IF NOT onlyrem = 'X'.
*--Filter Critical Auths by system

        concatenate SY-SYSID SY-MANDT into l_system.
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]     = lt_faobj[].
        lt_confdet_sys[]   = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2.
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.



    CALL FUNCTION '/PSYNG/SW_036'
         EXPORTING
              vrsio          = sodvrsio
              org_check      = ''
              enh_fm         = p_enhanc
              i_rchdatf      = rchdatf
              i_rchdatt      = rchdatt
*              i_simu_rfc     = rolerfc
              xstb_fm        = 'X'
*              i_bysimu       = bysimu
              i_local_sod    = ' '
              i_shonosod     = shonoca
              i_composite_roles    = comprol
              i_single_roles       = singrol
              i_shomit             = p_shomit
              i_assigned_roles = assgn_r

*         IMPORTING
*              o_totalroles   = l_nr_roles_analyzed
         TABLES
              it_roles       = roles
              it_roles_simu  = simurols
*              it_confs       = spconfs
*              it_sens        = sens
              it_conflict    = lt_conflict
              it_confdet     = lt_confdet_sys
              it_functtran   = lt_functtran_sys
              it_faobj       = lt_faobj_sys
*              it_swsodorgm   = lt_swsodorgm
              it_tcodes      = lt_enh_tcodes
              ot_routput_sum = lt_routput_sum
              et_mitigations = gt_mitigations.
    CONCATENATE  sy-sysid sy-mandt INTO gt_fm_output_before-rfcdest.
    LOOP AT lt_routput_sum.

      gt_fm_output_before-swaudid  = lt_routput_sum-conid.
      gt_fm_output_before-agr_name = lt_routput_sum-agr_name.
      gt_fm_output_before-agr_text = lt_routput_sum-agr_text.
      gt_fm_output_before-simu     = lt_routput_sum-simu.
      gt_fm_output_before-enhanced = lt_routput_sum-enhanced.
      gt_fm_output_before-contid   = lt_routput_sum-contid.
      APPEND gt_fm_output_before.
    ENDLOOP.

  ENDIF.

  WAIT UNTIL g_running_tasks = 0.

  APPEND LINES OF lt_fm_output  TO gt_fm_output_before.
  REFRESH lt_fm_output.

  LOOP AT gt_return.
    MESSAGE  ID   gt_return-id
             TYPE gt_return-type
             NUMBER  gt_return-number
             WITH
             gt_return-message.
  ENDLOOP.

  REFRESH : lt_routput_sum.

*-- After Analysis
  CLEAR : g_nr_roles_analyzed, l_nr_roles_analyzed.
  IF NOT gt_remote_anal_rfc[] IS INITIAL.

    LOOP AT gt_remote_anal_rfc INTO l_rfcdes.
      l_taskname = l_rfcdes-rfcoptions.
      ADD 1 TO g_running_tasks.

      lt1_role_removal_simu[] = it_role_removal_simu[].

      FREE : lt_role_removal_simu.
      LOOP AT lt1_role_removal_simu WHERE rfcdest = l_rfcdes-rfcdest.
        APPEND lt1_role_removal_simu TO lt_role_removal_simu.
      ENDLOOP.
      FREE : lt_removed_roles.

      FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
      LOOP AT lt_simu_roleauth WHERE rfcdest =  l_rfcdes-rfcoptions.
        APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
      ENDLOOP.

      LOOP AT lt_simu_roletcode WHERE rfcdest = l_rfcdes-rfcoptions.
        APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
      ENDLOOP.
*--Filter Critical Auths by system

        l_system           =  l_rfcdes-rfcoptions.
        lt_functtran_sys[] = lt_functtran[].
        lt_faobj_sys[]     = lt_faobj[].
        lt_confdet_sys[]   = lt_confdet[].
        CALL FUNCTION '/PSYNG/SW_124'
          EXPORTING
           IF_CA              = 'X'
           i_system           = l_system
           I_APPLICATION      = 'SAP'
           i_vrsio            = sodvrsio
         TABLES
           IT_FUNCTTRAN        = lt_functtran_sys
           IT_FAOBJ            = lt_faobj_sys
           IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS = 1
             OTHERS           = 2 .
        IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

      CALL FUNCTION '/PSYNG/SW_036'
         STARTING NEW TASK l_taskname
         DESTINATION l_rfcdes-rfcdest
         PERFORMING get_remote_results ON END OF TASK
         EXPORTING
              vrsio          = sodvrsio
              org_check      = ''
              enh_fm         = p_enhanc
              i_rchdatf      = rchdatf
              i_rchdatt      = rchdatt
*              i_simu_rfc     = rolerfc
              xstb_fm        = 'X'
*              i_bysimu       = bysimu
              i_local_sod    = ''
              i_shonosod     = shonoca
              i_composite_roles    = comprol
              i_single_roles       = singrol
              i_shomit             = p_shomit
              i_assigned_roles = assgn_r

*         IMPORTING
*              o_totalroles   = l_nr_roles_analyzed
         TABLES
              it_roles       = roles
              it_roles_simu  = simurols
*              it_confs       = spconfs
*              it_sens        = sens
              it_conflict    = lt_conflict
              it_confdet     = lt_confdet_sys
              it_functtran   = lt_functtran_sys
              it_faobj       = lt_faobj_sys
*              it_swsodorgm   = lt_swsodorgm
              it_tcodes      = lt_enh_tcodes
              it_simurole_auth   = lt_simu_roleauth_part
              it_simurole_tcode  = lt_simu_roletcode_part
              it_simurole_tcdaut = lt_simu_tcdaut
              ot_routput_sum = lt_routput_sum
              et_mitigations = gt_mitigations
**--Role Removal Simulation
             it_simu_role_removal    = lt_role_removal_simu
             et_simu_removed_roles = lt_removed_roles
          EXCEPTIONS
              communication_failure = 1 MESSAGE l_system_msg
              system_failure        = 2 MESSAGE l_system_msg
              OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e01
            l_rfcdes-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e01
            l_rfcdes-rfcdest.
        ENDCASE.
        COMMIT WORK.
      ENDIF.

    ENDLOOP.
  ENDIF.
  IF NOT onlyrem = 'X'.
    lt1_role_removal_simu[] = it_role_removal_simu[].
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
    FREE : lt_role_removal_simu.
    LOOP AT lt1_role_removal_simu WHERE rfcdest = 'LOCAL' OR
                                       rfcdest = '' OR
                                       rfcdest = l_local_rfc.
      APPEND lt1_role_removal_simu TO lt_role_removal_simu.
    ENDLOOP.

    FREE : lt_simu_roleauth_part,lt_simu_roletcode_part.
    LOOP AT lt_simu_roleauth WHERE rfcdest = l_local_rfc.
      APPEND lt_simu_roleauth TO lt_simu_roleauth_part.
    ENDLOOP.

    LOOP AT lt_simu_roletcode WHERE rfcdest = l_local_rfc.
      APPEND lt_simu_roletcode TO lt_simu_roletcode_part.
    ENDLOOP.
*--Filter Critical Auths by system

    concatenate SY-SYSID SY-MANDT into l_system.
    lt_functtran_sys[] = lt_functtran[].
    lt_faobj_sys[]     = lt_faobj[].
    lt_confdet_sys[]   = lt_confdet[].
    CALL FUNCTION '/PSYNG/SW_124'
      EXPORTING
       IF_CA              = 'X'
       i_system           = l_system
       I_APPLICATION      = 'SAP'
       i_vrsio            = sodvrsio
     TABLES
       IT_FUNCTTRAN        = lt_functtran_sys
       IT_FAOBJ            = lt_faobj_sys
       IT_CONFDET          = lt_confdet_sys
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             TOO_MANY_OPTIONS       = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


    CALL FUNCTION '/PSYNG/SW_036'
         EXPORTING
              vrsio          = sodvrsio
              org_check      = ''
              enh_fm         = p_enhanc
              i_rchdatf      = rchdatf
              i_rchdatt      = rchdatt
*              i_simu_rfc     = rolerfc
              xstb_fm        = 'X'
*              i_bysimu       = bysimu
              i_local_sod    = ' '
              i_shonosod     = shonoca
              i_composite_roles    = comprol
              i_single_roles       = singrol
              i_shomit             = p_shomit
              i_assigned_roles = assgn_r

         IMPORTING
              o_totalroles   = l_nr_roles_analyzed
         TABLES
              it_roles       = roles
              it_roles_simu  = simurols
*              it_confs       = spconfs
*              it_sens        = sens
              it_conflict    = lt_conflict
              it_confdet     = lt_confdet_sys
              it_functtran   = lt_functtran_sys
              it_faobj       = lt_faobj_sys
*              it_swsodorgm   = lt_swsodorgm
              it_tcodes      = lt_enh_tcodes
        it_simurole_auth   = lt_simu_roleauth_part
        it_simurole_tcode  = lt_simu_roletcode_part
        it_simurole_tcdaut = lt_simu_tcdaut
*              it_risk        = s_risk
              ot_routput_sum = lt_routput_sum
              et_mitigations = gt_mitigations
**--Role Removal Simulation
    it_simu_role_removal    = lt_role_removal_simu
    et_simu_removed_roles = lt_removed_roles.
    CONCATENATE  sy-sysid sy-mandt INTO gt_fm_output_after-rfcdest.
    APPEND LINES OF lt_removed_roles TO gt_removed_roles.
    LOOP AT lt_routput_sum.

      gt_fm_output_after-swaudid  = lt_routput_sum-conid.
      gt_fm_output_after-agr_name = lt_routput_sum-agr_name.
      gt_fm_output_after-agr_text = lt_routput_sum-agr_text.
      gt_fm_output_after-simu     = lt_routput_sum-simu.
      gt_fm_output_after-enhanced = lt_routput_sum-enhanced.
      gt_fm_output_after-contid   = lt_routput_sum-contid.
      gt_fm_output_after-child_agr = lt_routput_sum-child_agr.
      APPEND gt_fm_output_after.
    ENDLOOP.
    ADD l_nr_roles_analyzed TO g_nr_roles_analyzed.

    FREE lt_removed_roles.
  ENDIF.

  WAIT UNTIL g_running_tasks = 0.

  APPEND LINES OF lt_fm_output  TO gt_fm_output_after.
  REFRESH lt_fm_output.

  LOOP AT gt_return.
    MESSAGE  ID   gt_return-id
             TYPE gt_return-type
             NUMBER  gt_return-number
             WITH
             gt_return-message.
  ENDLOOP.

  SORT  gt_fm_output_after  BY swaudid.
  SORT  gt_fm_output_before BY swaudid.
*  Delete gt_fm_output_after where simu <> 'X'.
  REFRESH : lt_fm_output.

  LOOP AT gt_fm_output_after.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_fm_output_after TO ls_output.
    READ TABLE gt_fm_output_before
    WITH KEY swaudid = gt_fm_output_after-swaudid
    BINARY SEARCH TRANSPORTING NO FIELDS.
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

    APPEND ls_output TO lt_fm_output.
  ENDLOOP.

  FIELD-SYMBOLS : <o_sum> TYPE /psyng/sw_ca_routput.
  SELECT swaudid description imp busarea FROM /psyng/swaudhdr
   INTO CORRESPONDING FIELDS OF TABLE swaudhdr
  WHERE vrsio =   sodvrsio AND swaudid IN paudid
                           AND imp IN s_imp
                           AND owner IN s_owner
                           AND busarea IN s_barea.

  SORT swaudhdr BY swaudid.

  LOOP AT gt_fm_output_before.
    CLEAR ls_output.
    MOVE-CORRESPONDING gt_fm_output_before TO ls_output.
    READ TABLE gt_fm_output_after
    WITH KEY swaudid = gt_fm_output_before-swaudid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--Conflict is removed
      ls_output-simu_before = 'X'.
      CLEAR ls_output-simu_after.
      IF ls_output-simu_after <> ls_output-simu_before.
        ls_output-simu = 'X'.
      ELSE.
        CLEAR ls_output-simu.
      ENDIF.
      APPEND ls_output TO lt_fm_output.
    ENDIF.
  ENDLOOP.
  LOOP AT lt_fm_output ASSIGNING <o_sum>.
    CLEAR output.
    output-swaudid    = <o_sum>-swaudid.
    output-agr_name   = <o_sum>-agr_name.
    output-agr_text   = <o_sum>-agr_text.
    output-rfcdest    = <o_sum>-rfcdest.
    output-simu       = <o_sum>-simu.
    output-enhanced   = <o_sum>-enhanced.
    output-contid     = <o_sum>-contid.
    output-simu_before     = <o_sum>-simu_before.
    output-simu_after    = <o_sum>-simu_after.

    IF NOT <o_sum>-contid IS INITIAL.
      IF <o_sum>-simu IS INITIAL.
        CLEAR gt_mitigations.
        READ TABLE gt_mitigations WITH KEY contid  = <o_sum>-contid
                                          swaudid  = <o_sum>-swaudid
                                          agr_name = <o_sum>-agr_name.
        output-auditor   = gt_mitigations-auditor.
        output-from_date = gt_mitigations-from_date.
        output-to_date   = gt_mitigations-to_date.
      ELSE.
        CLEAR gt_mitigations.
        READ TABLE gt_mitigations WITH KEY contid  = <o_sum>-contid
                                          swaudid  = <o_sum>-swaudid
                                          agr_name = <o_sum>-child_agr.
        IF sy-subrc = 0.
          output-auditor   = gt_mitigations-auditor.
          output-from_date = gt_mitigations-from_date.
          output-to_date   = gt_mitigations-to_date.
        ELSE.
          READ TABLE gt_mitigations WITH KEY contid  = <o_sum>-contid
                                           swaudid  = <o_sum>-swaudid
                                           agr_name = <o_sum>-agr_name.
          output-auditor   = gt_mitigations-auditor.
          output-from_date = gt_mitigations-from_date.
          output-to_date   = gt_mitigations-to_date.
        ENDIF.
      ENDIF.
    ENDIF.

    READ TABLE swaudhdr WITH KEY swaudid = output-swaudid
                                 BINARY SEARCH.
    IF sy-subrc = 0.
      output-description = swaudhdr-description.
      output-imp = swaudhdr-imp.
      SELECT SINGLE text FROM /psyng/busarea         "#EC CI_SEL_NESTED
         INTO output-barea
        WHERE busarea = swaudhdr-busarea.
      IF sy-subrc NE 0.
        CLEAR output-barea.
      ENDIF.

      ADD 1 TO g_nr_auths.
    ELSEIF output-swaudid = '----'.
      CONCATENATE
      'No Critical authorizations based on SOD matrix'(n01)
      'defined in Security Weaver on'(n02)
      l_date
      INTO output-description SEPARATED BY space.
    ENDIF.
    APPEND output.
  ENDLOOP.
  IF ustb = 'X'.
*      Update scan table
*-- Check authority for updating scan table
    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'SUMMTAB'.
    IF sy-subrc NE 0.
      gf_st_missing_auth = 'X'.
    ELSE.
      PERFORM update_scan_table.
    ENDIF.
  ENDIF.

  MESSAGE s113(/psyng/sw) WITH
 'Found'(167) g_nr_auths ' Critical Auths.'(118).


  CHECK odt = 'X'.
  IF output[] IS INITIAL.
    MESSAGE s174(/psyng/sw).
  ELSE.
    MESSAGE s176(/psyng/sw).
    PERFORM alv_output_sum.
  ENDIF.

*  ADD l_numroles TO trolecount.

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
FORM load_simulated_role_content TABLES   it_simu_role_addition
STRUCTURE
 /psyng/sw_role_addition_simu
         et_simu_roleauth STRUCTURE /psyng/roleauth
         et_simu_roletcode STRUCTURE /psyng/roletcode
         it_functran_local STRUCTURE /psyng/functtran
         it_faobj_local STRUCTURE /psyng/faobj2
         it_rfcdes STRUCTURE rfcdes.
  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu
                                      WITH HEADER LINE,
  l_agr_name TYPE agr_name,
  lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_faobj TYPE TABLE OF /psyng/faobj2,
  lt_functtran TYPE TABLE OF /psyng/functtran,
  lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  l_rfcdes TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdes.
  RANGES : range_roles FOR l_agr_name.
  lt_unique_rfcs[] = it_simu_role_addition[].
  SORT lt_unique_rfcs BY source_rfcdest.
  DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs
                             COMPARING source_rfcdest.


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
*BOC:HBHALLA (04/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Invalid Role'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)

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
        MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
        MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.
*        ENDLOOP.

        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
*        APPEND LINES OF lt_roleauth TO et_simu_roleauth.
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
      CALL FUNCTION '/PSYNG/SW_102'
        DESTINATION it_simu_role_addition-source_rfcdest
        TABLES
          it_roles_range       = range_roles
          et_roles             = lt_role_names "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
    EXCEPTIONS
        communication_failure = 1
        system_failure = 2
            OTHERS = 3 .
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN 1.
            MESSAGE s002(/psyng/sw) WITH 'Communication failure'.
         WHEN 2.
            MESSAGE s002(/psyng/sw) WITH 'System failure'.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)

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
                OTHERS         = 2. "#EC SAST_CI_GEN_CHECK
*BOC:HBHALLA (04/12/24)
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN 1.
                MESSAGE s002(/psyng/sw) WITH 'Invalid Role'.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (04/12/24)
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
        agr_name  <> '' .
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
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
       r_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE.


  APPEND LINES OF remrfc TO r_rfcs.
  r_rfcs-sign   = 'I'.
  r_rfcs-option = 'EQ'.
*--Role Simulation Destinations
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
*--Role Removal  Simulation Destinations
  r_rfcs-low    = rr_rfc_1.
  APPEND r_rfcs.
  r_rfcs-low    = rr_rfc_2.
  APPEND r_rfcs.
  r_rfcs-low    = rr_rfc_3.
  APPEND r_rfcs.

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
            it_rfcdes  = r_rfcs
*BOC:HBHALLA (04/12/24)
    EXCEPTIONS
            OTHERS = 1 .
        IF sy-subrc <> 0.
       CASE sy-subrc.
         WHEN OTHERS.
            MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
       ENDCASE.
        ENDIF.
*EOC:HBHALLA (04/12/24)
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

  FREE : gt_remote_anal_rfc.
  PERFORM load_role_rfc
             TABLES
                remrfc
                gt_remote_anal_rfc.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  detail_role_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM detail_role_analysis.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
         l_local_sys TYPE rfcdest,
         l_rfc LIKE rfcdes.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  CHECK NOT output-swaudid = '----'.

  REFRESH : iseltab[].
  CLEAR iseltab.
  IF l_local_sys <> output-rfcdest.
    READ TABLE gt_remote_anal_rfc WITH KEY rfcoptions = output-rfcdest
    INTO l_rfc.
    iseltab-selname = 'REMRFC'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = l_rfc-rfcdest.
    APPEND iseltab.

    iseltab-selname = 'ONLYREM'.
    iseltab-kind    = 'P'.
    iseltab-sign    = 'I'.
    iseltab-option  = 'EQ'.
    iseltab-low     = 'X'.
    APPEND iseltab.
  ENDIF.

  iseltab-selname = 'BYSIMU'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = bysimu.
  APPEND iseltab.

  iseltab-selname = 'P_HIENHN'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_hienhn.
  APPEND iseltab.

  iseltab-selname = 'P_ENHANC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_enhanc.
  APPEND iseltab.

  iseltab-selname = 'ROLERFC'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = rolerfc.
  APPEND iseltab.

  LOOP AT simurols.
    iseltab-selname = 'SIMUROLS'.
    iseltab-kind    = 'S'.
    iseltab-sign    = simurols-sign.
    iseltab-option  = simurols-option.
    iseltab-low     = simurols-low.
    iseltab-high     = simurols-high.
    APPEND iseltab.
  ENDLOOP.

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
  LOOP AT ar_rol_4.
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




  iseltab-selname = 'SODVRSIO'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = sodvrsio.
  APPEND iseltab.

  iseltab-selname = 'ODT'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'DET'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = 'X'.
  APPEND iseltab.

  iseltab-selname = 'SUM'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = ' '.
  APPEND iseltab.

  iseltab-selname = 'P_SHOMIT'.
  iseltab-kind    = 'P'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = p_shomit.
  APPEND iseltab.

  iseltab-selname = 'ROLES'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-agr_name.
  APPEND iseltab.

  iseltab-selname = 'PAUDID'.
  iseltab-kind    = 'S'.
  iseltab-sign    = 'I'.
  iseltab-option  = 'EQ'.
  iseltab-low     = output-swaudid.
  APPEND iseltab.

  program = sy-repid.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_CRIT_AUTHS_BYROLE
*EOC UMITTAL SE VF scan changes-25/11/2024
  WITH SELECTION-TABLE iseltab AND RETURN.
ENDFORM.                    " detail_role_analysis

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


  IF byrsimu IS INITIAL.
    lt_func-fcode = 'ROLEREMDET'.
    APPEND lt_func.
  ENDIF.

  lt_func-fcode = '&XINT'.
  APPEND lt_func.
  SET PF-STATUS 'SUMMARY' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_SIMU_BUT  text
*----------------------------------------------------------------------*
*form expand using    p_simu_but.
*
*endform.                    " expand
*&---------------------------------------------------------------------*
*&      Module  STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0101 OUTPUT.
  SET PF-STATUS '300'.
ENDMODULE.                 " STATUS_0101  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0101 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN '000'.
      LEAVE SCREEN.
    WHEN 'CONTINUE'.
      PERFORM fill_sel_screen_fields_to_tab.
      SUBMIT /psyng/sw_crit_auths_byrole WITH
      SELECTION-TABLE irsparams AND RETURN.
      SET SCREEN '000'.
      LEAVE SCREEN.

*--Resubmit report
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0101  INPUT
*&---------------------------------------------------------------------*
*&      Module  STATUS_0102  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0102 OUTPUT.
  SET PF-STATUS '300' EXCLUDING 'CANCEL'.

ENDMODULE.                 " STATUS_0102  OUTPUT
*&---------------------------------------------------------------------*
*&      Module  DISPLAY_ALV_0102  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE display_alv_0102 OUTPUT.
  PERFORM display_alv_0102 .
ENDMODULE.                 " DISPLAY_ALV_0102  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  display_alv_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_alv_0102.
  SORT gt_removed_roles.
  DELETE ADJACENT DUPLICATES FROM gt_removed_roles.
  IF gr_alvgrid IS INITIAL .
    CREATE OBJECT gr_ccontainer
    EXPORTING
      container_name = gc_custom_control_name
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      others                      = 6 .
    IF sy-subrc <> 0.
*    "Error handling
    ENDIF.
    CREATE OBJECT gr_alvgrid
      EXPORTING
        i_parent = gr_ccontainer
      EXCEPTIONS
        error_cntl_create = 1
        error_cntl_init   = 2
        error_cntl_link   = 3
        error_dp_create   = 4
        others            = 5 .
    IF sy-subrc <> 0.
*    Error handling
    ENDIF.
    PERFORM prepare_field_catalog_0102 CHANGING gt_fieldcat.
    PERFORM prepare_layout_0102        CHANGING gs_layout .
    CALL METHOD gr_alvgrid->set_table_for_first_display
     EXPORTING
       is_layout       = gs_layout
     CHANGING
       it_outtab       = gt_removed_roles[]
       it_fieldcatalog = gt_fieldcat
     EXCEPTIONS
       invalid_parameter_combination = 1
       program_error                 = 2
       too_many_lines                = 3
       OTHERS                        = 4 .
    IF sy-subrc <> 0.
*    Error handling
    ENDIF.
  ELSE.
    CALL METHOD gr_alvgrid->refresh_table_display
*     EXPORTING
*     IS_STABLE =
*     I_SOFT_REFRESH =
      EXCEPTIONS
        finished = 1
        OTHERS   = 2 .

  ENDIF.

ENDFORM.                    " display_alv_0102
*&---------------------------------------------------------------------*
*&      Form  prepare_field_catalog_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_FIELDCAT  text
*----------------------------------------------------------------------*
FORM prepare_field_catalog_0102 CHANGING et_fieldcat TYPE lvc_t_fcat.
  CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
       EXPORTING
            i_structure_name       = '/PSYNG/SW_REMOVED_ROLES_ROLE'
       CHANGING
            ct_fieldcat            = et_fieldcat[]
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
*    Error handling
  ENDIF.

ENDFORM.                    " prepare_field_catalog_0102
*&---------------------------------------------------------------------*
*&      Form  prepare_layout_0102
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GS_LAYOUT  text
*----------------------------------------------------------------------*
FORM prepare_layout_0102 CHANGING es_layout TYPE lvc_s_layo.
  es_layout-zebra = 'X' .
  es_layout-grid_title = 'Roles Removed by Simulation'.
ENDFORM.                    " prepare_layout_0102
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0102  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0102 INPUT.
  CASE sy-ucomm.
    WHEN 'CANCEL'.
      SET SCREEN '000'.
      LEAVE SCREEN.
    WHEN 'CONTINUE'.
      SET SCREEN '000'.
      LEAVE SCREEN.
  ENDCASE.
ENDMODULE.                 " USER_COMMAND_0102  INPUT
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
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.

ENDFORM.                    " set_default_sodversion

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
