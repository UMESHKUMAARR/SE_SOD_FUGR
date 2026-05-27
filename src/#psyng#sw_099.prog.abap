*----------------------------------------------------------------------*
* Report  /PSYNG/SW_099                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_099  MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

TABLES: /psyng/conflict,
        /psyng/swaudc2,
        agr_define,
        rfcdes,
        usr02,
        ust04.
INCLUDE /psyng/sw_125.
include /psyng/sw_099_top.

DATA: g_dynnr        TYPE sy-dynnr,
     gf_dflt_enhance_matrix type flag.
RANGES : s_prof_t FOR  ust04-profile,
         s_role_t FOR agr_define-agr_name.

SELECTION-SCREEN BEGIN OF BLOCK sel WITH FRAME TITLE text-t02.

PARAMETERS: p_vrsio  LIKE /psyng/conflict-vrsio MEMORY ID /psyng/vrsio.
*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.
PARAMETERS:p_ustb   AS CHECKBOX DEFAULT space.

SELECTION-SCREEN BEGIN OF BLOCK exe WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_byuser RADIOBUTTON GROUP g1 USER-COMMAND radi DEFAULT 'X'.
SELECTION-SCREEN COMMENT 4(21) text-001.
SELECTION-SCREEN POSITION 25.
SELECT-OPTIONS: s_bname FOR usr02-bname MATCHCODE OBJECT user_comp.
"user ID
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 4(20) text-002.
SELECT-OPTIONS: s_usrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll. "RFC destinations for
SELECTION-SCREEN END OF LINE.                "users
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 4.
PARAMETERS: p_locusr AS CHECKBOX.       "use local users only for
SELECTION-SCREEN COMMENT 7(60) text-003. "cross system analysis
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_byugrp RADIOBUTTON GROUP g1.
SELECTION-SCREEN COMMENT 4(21) text-004.
SELECTION-SCREEN POSITION 25.
SELECT-OPTIONS: s_class FOR usr02-class.  "user group
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_bypa RADIOBUTTON GROUP g1.
SELECTION-SCREEN COMMENT 4(21) text-005 FOR FIELD p_bypa.
SELECTION-SCREEN POSITION 25.
SELECT-OPTIONS: s_werks FOR g_persa.       "personnel area
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN ULINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: p_onlyrm TYPE flag USER-COMMAND remo.
SELECTION-SCREEN COMMENT 3(47) text-010.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS p_enhanc AS CHECKBOX USER-COMMAND enhance. "Enhanced ruleset
SELECTION-SCREEN COMMENT 3(30) text-011.
PARAMETERS p_hienhn AS CHECKBOX.
SELECTION-SCREEN COMMENT 36(49) text-012.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid, "Specific Conflicts
                s_imp   FOR /psyng/conflict-imp, "Sensitivity
                s_risk  FOR /psyng/conflict-risk,      "Risk scenario
                s_role FOR agr_define-agr_name,
                s_prof FOR  ust04-profile .
PARAMETERS: cuscon  AS CHECKBOX DEFAULT ' ' .
PARAMETERS: p_shwcmp AS CHECKBOX DEFAULT space,
            p_shwpcm AS CHECKBOX DEFAULT space,
            erroles  AS CHECKBOX DEFAULT ' ' USER-COMMAND er1,
            excl_er  AS CHECKBOX DEFAULT ' ' USER-COMMAND er2,
            p_xmc    AS CHECKBOX DEFAULT ' ',"ignore mitigating controls
            p_nosod  AS CHECKBOX DEFAULT ' ',  "show users w/o conflicts
            p_orgchk AS CHECKBOX DEFAULT ' '.  "org check

*--Conflict origin
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-013.
SELECTION-SCREEN POSITION 22.
PARAMETERS: p_local TYPE flag DEFAULT 'X'.
SELECTION-SCREEN COMMENT 24(10) text-014.
SELECTION-SCREEN POSITION 35.
PARAMETERS: p_remote TYPE flag DEFAULT ' ' USER-COMMAND rm.
SELECTION-SCREEN COMMENT 37(10) text-015.
SELECTION-SCREEN POSITION 49.
PARAMETERS: p_cross TYPE flag DEFAULT ' ' USER-COMMAND cr.
SELECTION-SCREEN COMMENT 51(12) text-016.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK exe.

SELECTION-SCREEN BEGIN OF BLOCK criauth WITH FRAME TITLE text-t03.
SELECT-OPTIONS: s_audid FOR /psyng/swaudc2-swaudid.
SELECTION-SCREEN END OF BLOCK criauth.
SELECTION-SCREEN END OF BLOCK sel.

SELECTION-SCREEN BEGIN OF BLOCK cblk WITH FRAME TITLE text-t04.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-017.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-018.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN PUSHBUTTON 4(30) text-019 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON 40(25) text-020 USER-COMMAND sm37.
SELECTION-SCREEN END OF BLOCK cblk.

PARAMETERS: p_varnt LIKE varid-variant NO-DISPLAY.

*-------------------------- INITIALIZATION ----------------------------*
INITIALIZATION.
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
  PERFORM exelog.
  g_repid = sy-repid.
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

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_local.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_remote.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  p_cross.
  PERFORM show_help USING '/PSYNG/SE_CONFLICT_ORIGIN'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-low.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_prof-high.
  PERFORM show_help USING '/PSYNG/SE_PROFILE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-low.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.

AT SELECTION-SCREEN ON HELP-REQUEST FOR  s_role-high.
  PERFORM show_help USING '/PSYNG/SE_ROLE'.


AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_werks-low.
  PERFORM f4_werks CHANGING s_werks-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_werks-high.
  PERFORM f4_werks CHANGING s_werks-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

*------------------------ AT SELECTION-SCREEN -------------------------*
AT SELECTION-SCREEN.

  IF sy-ucomm = 'REMO'.
    IF p_onlyrm = 'X'.
      CLEAR : p_local.
      p_remote = 'X'.
      LOOP AT SCREEN.
        CASE screen-name.
          WHEN 'P_LOCAL'.
            screen-input = 0.
            MODIFY SCREEN.

        ENDCASE.


      ENDLOOP.
      p_remote = 'X'.
      IF s_usrrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(184).
      ENDIF.
    ELSE.
      p_local = 'X'.
      CLEAR p_remote.
      CLEAR p_cross.
    ENDIF.
  ENDIF.


  IF sy-ucomm = 'RM'.
    IF p_remote = 'X'.
      IF s_usrrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(184).
      ENDIF.
    ENDIF.
  ENDIF.

  IF sy-ucomm = 'CR'.
    IF p_cross = 'X'.
      IF s_usrrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for Cross analysis'(183).
      ENDIF.
    ENDIF.
  ENDIF.

  IF p_onlyrm = 'X' OR p_remote = 'X' OR p_cross = 'X'.
    IF s_usrrfc[] IS INITIAL.
      MESSAGE w140 WITH
      'Please enter RFC destinations for remote analysis'(184).
    ENDIF.
  ENDIF.


  CASE sy-ucomm .
    WHEN 'SCJB'.
      gf_exit_proc = 'Y'.
      PERFORM schedule_back_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
    WHEN 'ER1'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR excl_er.
      ENDIF.
    WHEN 'ER2'.
      IF erroles = 'X' AND excl_er = 'X'.
        CLEAR erroles.
      ENDIF.

  ENDCASE.


  LOOP AT SCREEN.
*--Disable Show no SOD when conflict ID's are restricted

    IF  screen-name CS 'S_CONID'
    OR screen-name CS 'S_RISK'
    OR screen-name CS 'S_IMP'.
      IF NOT s_imp[] IS INITIAL OR
         NOT s_risk[] IS INITIAL  OR
         NOT s_conid[] IS INITIAL.

        IF p_nosod = 'X'.
          MESSAGE s398(00) WITH text-074.
          STOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN OUTPUT.

*--Check if ER is installed/ deactivate ER buttons
  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF p_onlyrm = 'X'.
    CLEAR : p_local.
    p_remote = 'X'.
    LOOP AT SCREEN.
      CASE screen-name.
        WHEN 'P_LOCAL'.
          screen-input = 0.
          MODIFY SCREEN.
      ENDCASE.
    ENDLOOP.
  ENDIF.


  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'P_HIENHN'.
        IF p_enhanc = space.
          screen-input = 0.
          CLEAR p_hienhn.
        ELSE.
          screen-input = 1.
          p_hienhn = 'X'.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'P_NOSOD'.
*--Disable Show no SOD when conflict ID's are restricted
        IF NOT s_imp[] IS INITIAL OR
           NOT s_risk[] IS INITIAL  OR
           NOT s_conid[] IS INITIAL.
          screen-input = 0.

          IF p_nosod = 'X'.
            CLEAR p_nosod.
            MESSAGE w398(00) WITH text-074.
          ENDIF.

        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.

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

      WHEN 'P_SHWCMP'.
        IF gf_showpcom = 'X'.
          screen-invisible = 1.
        ELSE.
          screen-invisible = 0.
        ENDIF.
        MODIFY SCREEN.

      WHEN 'P_SHWPCM'.
        IF gf_showpcom = ' '.
          screen-invisible = 1.
        ELSE.
          screen-invisible = 0.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.

  ENDLOOP.
* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = gc_erp_class
    RECEIVING
      p_descr_ref    = go_classtype
     EXCEPTIONS
       type_not_found = 1
       OTHERS         = 2.

  IF sy-subrc <> 0.
*   Remove Personnel Area from screen
    LOOP AT SCREEN.
      CHECK screen-name CS 'S_WERKS' OR screen-name CS 'P_BYPA'.
      screen-active = 0.
      MODIFY SCREEN.
    ENDLOOP.
  ENDIF.



*------------------------ START-OF-SELECTION --------------------------*
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
  EXELOG sy-repid ''.
  s_prof_t[] = s_prof[].
  s_role_t[] = s_role[].

  IF gf_exit_proc = 'Y'.
    SUBMIT (g_repid) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
    VIA SELECTION-SCREEN
           USING SELECTION-SET g_variant.
  ENDIF.

  CONCATENATE sy-title text-000 p_vrsio
              INTO sy-title SEPARATED BY space.

  IF p_ustb IS INITIAL.
    gf_no_upd_scan = 'X'.
  ENDIF.

** Case 3479 Bug 1905
  IF p_byuser = 'X'.
    REFRESH: s_class , s_werks.
    CLEAR: s_class , s_werks.
  ENDIF.
  IF p_byugrp = 'X'.
    REFRESH : s_bname , s_werks.
    CLEAR : s_bname , s_werks.
  ENDIF.
  IF p_bypa = 'X'.
    REFRESH : s_class , s_bname.
    CLEAR : s_class , s_bname.
  ENDIF.


  IF NOT s_usrrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.


  PERFORM get_conflicts_from_selection.

  PERFORM critical_auth_scan
    TABLES gt_audout.
*  IF gt_conid[] IS INITIAL AND gt_local_swaudhdr[] IS INITIAL.
**--Selection of conflicts showed no conflicts
*    MESSAGE i135 WITH 'No Conflict or CA ID''s match selection'(177).
*    LEAVE LIST-PROCESSING.
*  ENDIF.
*  IF NOT gt_conid[] IS INITIAL.
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_org_check               = p_orgchk
      i_validuser               = validusr
      i_vrsio                   = p_vrsio
      i_exlckusr                = exlckusr
      i_outvdate                = outvdate
      i_cuscon                  = cuscon
      i_shomit                  = p_xmc
      i_enh                     = p_enhanc
      i_hienh                   = p_hienhn
      i_xstb                    = gf_no_upd_scan
      i_shonosod                = p_nosod
      i_locsod                  = ' '
      i_locusr                  = p_locusr
*Analyze users with sap_all in detail
      i_analyze_sap_all        = 'X'
      i_output                 = 'X'
      i_remote_only            = p_onlyrm
     i_er_roles                  = erroles
     i_exclude_er_roles          = excl_er
   IMPORTING
      e_usercount               = tusercount
      ef_missing_auth           = gf_missing_auth
      ef_st_missing_auth        = gf_st_missing_auth
    TABLES
      it_users                  = s_bname
      it_usergroup              = s_class
      it_actgroups              = s_role_t
      it_profiles               = s_prof_t
      it_usertype               = usrtype
      it_confs                  = gt_conid
      et_outputdet              = gt_sodout
      et_enh_con                = gt_enh_con
       it_user_rfc              = s_usrrfc
      it_risk                   = s_risk
      et_mitigations            = gt_mcuser_sod
      et_rpoug_auth_fail        = lt_rpoug_auth_fail.
*  ENDIF.

  APPEND LINES OF lt_rpoug_auth_fail TO gt_rpoug_auth_fail.
* Combine output
  gt_output-type = 'C'.

  SORT gt_audout.
  DELETE ADJACENT DUPLICATES FROM gt_audout COMPARING ALL FIELDS.

  LOOP AT gt_audout.
    MOVE-CORRESPONDING gt_audout TO gt_output.
    gt_output-conid = gt_audout-swaudid.

    PERFORM get_aud_desc USING gt_audout-swaudid
                         CHANGING gt_output-condesc
                                  gt_output-imp
                                  gt_output-owner.
    APPEND gt_output.
    ADD 1 TO gv_ca_count.
    CLEAR: gt_output-imp, gt_output-owner.
  ENDLOOP.

  CLEAR gt_output.

  gt_output-type = 'S'.

*--Filter Conflict origin
  IF p_local <> 'X'.
    DELETE gt_sodout WHERE origin = 1.
  ENDIF.
  IF p_remote <> 'X'.
    DELETE gt_sodout WHERE origin = 2.
  ENDIF.
  IF p_cross <> 'X'.
    DELETE gt_sodout WHERE origin = 3.
  ENDIF.

  IF NOT s_imp[]  IS INITIAL OR
     NOT s_conid[]  IS INITIAL OR
     NOT s_risk[] IS INITIAL.
    IF gt_conid IS INITIAL.
      REFRESH gt_sodout.
    ENDIF.
  ENDIF.

  LOOP AT gt_sodout.
    MOVE-CORRESPONDING gt_sodout TO gt_output.

    CASE gt_sodout-origin.
      WHEN 1.
        gt_output-rfcdest = 'Local'(173).
      WHEN 2.
        gt_output-rfcdest = 'Remote'(174).
      WHEN 3.
        gt_output-rfcdest = 'Cross'(175).
    ENDCASE.

    READ TABLE gt_enh_con WITH KEY bname = gt_sodout-bname
                                   conid = gt_sodout-conid.
    IF sy-subrc = 0.
      gt_output-enhanced = 'X'.
    ELSE.
      CLEAR gt_output-enhanced.
    ENDIF.

    APPEND gt_output.
    IF NOT gt_sodout-conid EQ '----'.
      ADD 1 TO gv_sod_count.
    ENDIF.
  ENDLOOP.
*** SF case 3479 : No conflict found message
  IF sy-subrc NE 0.
    MESSAGE s398(00) WITH text-069.
  ENDIF.
**  End
  SORT gt_output.
  DELETE ADJACENT DUPLICATES FROM gt_output.


*----SE 3.2 - Mitigation Processing-----*
  IF p_xmc = 'X'.
    PERFORM process_mitigations.
  ENDIF.


  IF gt_output[] IS INITIAL.
    IF gf_missing_auth IS INITIAL.
      MESSAGE s140 WITH 'No results found.'(021).
    ELSE.
      PERFORM output.
    ENDIF.
  ELSE.
    MESSAGE s140 WITH 'Analysis Complete.'(029).
    PERFORM output.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  output
*&---------------------------------------------------------------------*
*       Output to screen
*----------------------------------------------------------------------*
FORM output.
  DATA: lt_fieldcat TYPE slis_t_fieldcat_alv,
        ls_fieldcat TYPE slis_fieldcat_alv,
        lt_sort     TYPE slis_t_sortinfo_alv,
        ls_sort     TYPE slis_sortinfo_alv,
        ls_variant  TYPE disvariant,
        ls_layout   TYPE slis_layout_alv.
  DATA: ls_swconfig_bkgd_job TYPE /psyng/swconfig.
  DATA: ls_line_count TYPE i.

  g_repid = sy-repid.

* REPEAT_HDR_BKGDJOB Flag Check
  IF sy-batch EQ 'X'.
    se_config_param 'REPEAT_HDR_BKGDJOB' ls_swconfig_bkgd_job-value.
    IF ls_swconfig_bkgd_job-value = 'N'.
      CLEAR g_repeat_hdr_bkgdjob.
      DESCRIBE TABLE gt_output LINES ls_line_count.
      PERFORM set_print_param USING ls_line_count.
    ELSE.
      g_repeat_hdr_bkgdjob = 'X'.
    ENDIF.

  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_repid
            i_internal_tabname = 'GT_OUTPUT'
            i_inclname         = g_repid
       CHANGING
            ct_fieldcat        = lt_fieldcat
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

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h04.
  ls_fieldcat-seltext_m    = text-h04.
  ls_fieldcat-seltext_s    = text-h04.
  ls_fieldcat-reptext_ddic = text-h04.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                   WHERE
                      fieldname = 'TO_DATE'.


  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h00.
  ls_fieldcat-seltext_m    = text-h00.
  ls_fieldcat-seltext_s    = text-h00.
  ls_fieldcat-reptext_ddic = text-h00.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'TYPE'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h14.
  ls_fieldcat-seltext_m    = text-h14.
  ls_fieldcat-seltext_s    = text-h14.
  ls_fieldcat-reptext_ddic = text-h14.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'BNAME'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h01.
  ls_fieldcat-seltext_m    = text-h01.
  ls_fieldcat-seltext_s    = text-h01.
  ls_fieldcat-reptext_ddic = text-h01.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'NAME_TEXT'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h02.
  ls_fieldcat-seltext_m    = text-h02.
  ls_fieldcat-seltext_s    = text-h02.
  ls_fieldcat-reptext_ddic = text-h02.
  ls_fieldcat-hotspot      = 'X'.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                       hotspot
                     WHERE
                       fieldname = 'CONID'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l    = text-h17.
  ls_fieldcat-seltext_m    = text-h17.
  ls_fieldcat-seltext_s    = text-h17.
  ls_fieldcat-reptext_ddic = text-h17.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'USTYP'.

*---------SE 3.2 - Mitigation Icon-----------*
  CLEAR ls_fieldcat.
  ls_fieldcat-tabname      = 'GT_OUTPUT'.
  ls_fieldcat-inttype      = 'C'.
*  ls_fieldcat-intlen = '000004'.
*  ls_fieldcat-ddic_outputlen = '000004'.
  ls_fieldcat-seltext_l    = text-h31.
  ls_fieldcat-seltext_m    = text-h31.
  ls_fieldcat-seltext_s    = text-h31.
  ls_fieldcat-reptext_ddic = text-h31.
*  ls_fieldcat-icon    = 'X'.
*  ls_fieldcat-hotspot = 'X'.
  IF p_xmc IS INITIAL.
    ls_fieldcat-no_out = 'X'.
  ENDIF.
  MODIFY lt_fieldcat FROM ls_fieldcat
                    TRANSPORTING
                      col_pos
                      tabname
                      inttype
                      intlen
                      ddic_outputlen
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      icon
                      hotspot
                      no_out
                   WHERE
                      fieldname = 'CONTID'.

  CLEAR ls_fieldcat.
  ls_fieldcat-tabname      = 'GT_OUTPUT'.
  ls_fieldcat-inttype      = 'C'.
*  ls_fieldcat-intlen = '000004'.
*  ls_fieldcat-ddic_outputlen = '000004'.
  ls_fieldcat-seltext_l    = text-h31.
  ls_fieldcat-seltext_m    = text-h31.
  ls_fieldcat-seltext_s    = text-h31.
  ls_fieldcat-reptext_ddic = text-h31.
*  ls_fieldcat-icon    = 'X'.
*  ls_fieldcat-hotspot = 'X'.
  IF p_xmc IS INITIAL.
    ls_fieldcat-no_out = 'X'.
  ENDIF.
  MODIFY lt_fieldcat FROM ls_fieldcat
                    TRANSPORTING
                      col_pos
                      tabname
                      inttype
                      intlen
                      ddic_outputlen
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      icon
                      hotspot
                      no_out
                   WHERE
                      fieldname = 'AUDITOR'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l      = 'Emergency Repair'(h03).
  ls_fieldcat-seltext_m      = 'Emergency Repair'(h03).
  ls_fieldcat-seltext_s      = 'Emergency Repair'(h03).
  ls_fieldcat-reptext_ddic   = 'Emergency Repair'(h03).
  ls_fieldcat-checkbox       = 'X'.
  ls_fieldcat-just           = 'X'.
  IF erroles <> 'X'.
    ls_fieldcat-no_out = 'X'.
  ELSE.
    CLEAR ls_fieldcat-no_out.
  ENDIF.
  MODIFY lt_fieldcat FROM ls_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'ER'.

  CLEAR ls_fieldcat.
  ls_fieldcat-seltext_l      = 'Enhanced'(h04).
  ls_fieldcat-seltext_m      = 'Enhanced'(h04).
  ls_fieldcat-seltext_s      = 'Enhanced'(h04).
  ls_fieldcat-reptext_ddic   = 'Enhanced'(h04).
  ls_fieldcat-checkbox       = 'X'.
  ls_fieldcat-just           = 'X'.
  IF p_enhanc <> 'X'.
    ls_fieldcat-no_out = 'X'.
  ELSE.
    CLEAR ls_fieldcat-no_out.
  ENDIF.
  MODIFY lt_fieldcat FROM ls_fieldcat
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                      checkbox
                      just
                   WHERE
                      fieldname = 'ENHANCED'.

  CLEAR ls_fieldcat.
  IF s_usrrfc[] IS INITIAL.
    ls_fieldcat-no_out = 'X'.
  ELSE.
    CLEAR ls_fieldcat-no_out.
  ENDIF.
  ls_fieldcat-seltext_l    = text-h20.
  ls_fieldcat-seltext_m    = text-h20.
  ls_fieldcat-seltext_s    = text-h20.
  ls_fieldcat-reptext_ddic = text-h20.
  MODIFY lt_fieldcat FROM ls_fieldcat
                     TRANSPORTING
                       seltext_l
                       seltext_m
                       seltext_s
                       reptext_ddic
                     WHERE
                       fieldname = 'RFCDEST'.

  CLEAR ls_fieldcat.
*  wa_fieldcat_alv-col_pos = '25'.
  ls_fieldcat-tabname = 'GT_OUTPUT'.
  ls_fieldcat-inttype = 'C'.
  ls_fieldcat-intlen = '000004'.
  ls_fieldcat-ddic_outputlen = '000004'.
  ls_fieldcat-seltext_l = text-h29.
  ls_fieldcat-seltext_m = text-h30.
  ls_fieldcat-seltext_s = text-h30.
  ls_fieldcat-reptext_ddic = text-h30.
  ls_fieldcat-icon    = 'X'.
  ls_fieldcat-hotspot = 'X'.
  IF p_xmc IS INITIAL.
    ls_fieldcat-no_out = 'X'.
  ENDIF.
  MODIFY lt_fieldcat FROM ls_fieldcat
                    TRANSPORTING
                      col_pos
                      tabname
                      inttype
                      intlen
                      ddic_outputlen
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      icon
                      hotspot
                      no_out
                   WHERE
                      fieldname = 'MIT_ICON'.


  ls_sort-spos = '1'.
  ls_sort-fieldname = 'TYPE'.
  ls_sort-tabname = 'GT_OUTPUT'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '2'.
  ls_sort-fieldname = 'CLASS'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '3'.
  ls_sort-fieldname = 'BNAME'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '4'.
  ls_sort-fieldname = 'USTYP'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '5'.
  ls_sort-fieldname = 'NAME_TEXT'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '6'.
  ls_sort-fieldname = 'IMP'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '7'.
  ls_sort-fieldname = 'OWNER'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '8'.
  ls_sort-fieldname = 'CONID'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '9'.
  ls_sort-fieldname = 'CONDESC'.
  APPEND ls_sort TO lt_sort.
  ls_sort-spos = '10'.
  ls_sort-fieldname = 'RFCDEST'.
  APPEND ls_sort TO lt_sort.


  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.

  ls_fieldcat-col_pos = '1'.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'RFCDEST'.

  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'TYPE'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CLASS'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'BNAME'.

  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'NAME_TEXT'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'USTYP'.

  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'IMP'.

  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'OWNER'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CONID'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'CONDESC'.
  ADD 1 TO ls_fieldcat-col_pos.
  ls_fieldcat-hotspot = 'X'.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          hotspot
          col_pos
        WHERE
          fieldname = 'CONTID'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'AUDITOR'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'ER'.
  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'ENHANCED'.

  ADD 1 TO ls_fieldcat-col_pos.
  MODIFY lt_fieldcat FROM ls_fieldcat
        TRANSPORTING
          col_pos
        WHERE
          fieldname = 'MIT_ICON'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = g_repid
            it_sort                  = lt_sort
            i_callback_user_command  = 'DOUBLE_CLICK_ON_SUMRY'
            i_callback_pf_status_set = 'PF_STATUS_SUMMARY'
            i_callback_top_of_page   = 'ALV_HEADER'
            is_layout                = ls_layout
            it_fieldcat              = lt_fieldcat
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_output
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " output

*&---------------------------------------------------------------------*
*&      Form  DOUBLE_CLICK_ON_SUMRY
*&---------------------------------------------------------------------*
*       Double click on summary report
*----------------------------------------------------------------------*
FORM double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                 rs_selfield TYPE slis_selfield.
  DATA: lt_seltab TYPE STANDARD TABLE OF rsparams WITH HEADER LINE,
        l_contid TYPE /psyng/mchdr-contid,
        l_uname  LIKE sy-uname,
        l_parva  TYPE usr05-parva,
        l_sod    TYPE /psyng/swsodvers-vrsio.

  CASE r_ucomm.


    WHEN 'FAILEDUSER'.
      PERFORM show_user_grp_cmp_invalid.
      EXIT.
  ENDCASE.

*  CASE is_selfield-fieldname.
*    when 'TCODE'.
*      read table gt_output index is_selfield-tabindex.
*      check sy-subrc = 0.
*       PERFORM get_tcode_origin using
*       is_selfield-value userconf3-bname .
*       PERFORM fieldcat_drill_detail_tcode.
*       PERFORM build_sort_detail_tcode.
*       PERFORM drill_alv_detail_tcode.
*  when 'OTHERS'.

*-------SE 3.2 - Mitigation Icon
  CASE rs_selfield-fieldname.

   WHEN 'CONTID'.
    CHECK rs_selfield-value <> space.
      l_contid = rs_selfield-value.
      l_uname = g_current_user.     "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING p_vrsio l_uname.

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
     EXIT.
    WHEN 'MIT_ICON'.
      READ TABLE gt_output INDEX rs_selfield-tabindex.
      IF gt_output-mit_icon IS INITIAL.
        MESSAGE e123 WITH gt_output-bname gt_output-conid.
      ENDIF.
      PERFORM show_mit_details USING gt_output.
      EXIT.
  ENDCASE.

  READ TABLE gt_output INDEX rs_selfield-tabindex.
  IF gt_output-type = 'C'.

    LOOP AT usrtype .
      lt_seltab-selname = 'USRTYPE'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = usrtype-sign.
      lt_seltab-option  = usrtype-option.
      lt_seltab-low     = usrtype-low.
      lt_seltab-high    = usrtype-high.
      APPEND lt_seltab.
    ENDLOOP.

    lt_seltab-selname = 'PBNAME'.    "user ID
    lt_seltab-kind    = 'S'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = gt_output-bname.
    APPEND lt_seltab.
    lt_seltab-selname = 'VALIDUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = ' '.
    APPEND lt_seltab.
    lt_seltab-selname = 'SODVRSIO'.        "SOD Version
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_vrsio.
    APPEND lt_seltab.
    lt_seltab-selname = 'PAUDID'.   "specific crit auth
    lt_seltab-kind    = 'S'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = gt_output-conid.
    APPEND lt_seltab.
    lt_seltab-selname = 'SUM'.    "show details
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = ' '.
    APPEND lt_seltab.
    lt_seltab-selname = 'DET'.    "show details
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_ENHANC'.       "include enhanced ruleset
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_enhanc.
    APPEND lt_seltab.
    lt_seltab-selname = 'P_HIENHN'.       "higlight enhanced ruleset
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_hienhn.
    APPEND lt_seltab.

    lt_seltab-selname = 'EXCL_ER'.
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = excl_er.
    APPEND lt_seltab.

    lt_seltab-selname = 'ERROLES'.
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = erroles.
    APPEND lt_seltab.

    lt_seltab-selname = 'VALIDUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = validusr.
    APPEND lt_seltab.

    lt_seltab-selname = 'EXLCKUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = exlckusr.
    APPEND lt_seltab.

    lt_seltab-selname = 'OUTVDATE'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = outvdate.
    APPEND lt_seltab.


    lt_seltab-selname = 'P_FLAG'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_flag.
    APPEND lt_seltab.

    lt_seltab-selname = 'XMC'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_xmc.
    APPEND lt_seltab.

*    LOOP AT s_usrrfc.                  "Cross system analysis
*      lt_seltab-selname = 'REMRFC'.
*      lt_seltab-kind    = 'S'.
*      lt_seltab-sign    = s_usrrfc-sign.
*      lt_seltab-option  = s_usrrfc-option.
*      lt_seltab-low     = s_usrrfc-low.
*      lt_seltab-high    = s_usrrfc-high.
*      APPEND lt_seltab.
*    ENDLOOP.
*


    DATA : l_local_rfc TYPE rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
    IF l_local_rfc <> gt_output-rfcdest.
      READ TABLE gt_rfcdest WITH KEY rfcoptions =  gt_output-rfcdest.
      lt_seltab-selname = 'REMRFC'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
*    lt_seltab-low     = output-rfcdest.
      lt_seltab-low     =  gt_rfcdest-rfcdest.

      APPEND lt_seltab.

      lt_seltab-selname = 'ONLYREM'.
      lt_seltab-kind    = 'P'.
      lt_seltab-sign    = 'I'.
      lt_seltab-option  = 'EQ'.
      lt_seltab-low     = 'X'.
      APPEND lt_seltab.
    ENDIF.

    SUBMIT /psyng/sw_crit_auths WITH SELECTION-TABLE lt_seltab
           AND RETURN.
  ELSE.

    LOOP AT usrtype .
      lt_seltab-selname = 'USRTYPE'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = usrtype-sign.
      lt_seltab-option  = usrtype-option.
      lt_seltab-low     = usrtype-low.
      lt_seltab-high    = usrtype-high.
      APPEND lt_seltab.
    ENDLOOP.

    lt_seltab-selname = 'P_REMONL'.    "Only Remote
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     =  p_onlyrm.
    APPEND lt_seltab.


    lt_seltab-selname = 'BYUSER'.    "by user ID
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.
    lt_seltab-selname = 'PBNAME'.    "user ID
    lt_seltab-kind    = 'S'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = gt_output-bname.
    APPEND lt_seltab.
    lt_seltab-selname = 'SHODET'.    "show details
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.
    lt_seltab-selname = 'SHOWCOMP'.  "Show composite role(s)
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_shwcmp.
    APPEND lt_seltab.

    lt_seltab-selname = 'SHOWPCOM'.  "Show composite profile(s)
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_shwpcm.
    APPEND lt_seltab.

    lt_seltab-selname = 'SHOSUM'.    "show details
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = ' '.
    APPEND lt_seltab.
    lt_seltab-selname = 'SPCONFS'.   "specific onflicts
    lt_seltab-kind    = 'S'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = gt_output-conid.
    APPEND lt_seltab.
    lt_seltab-selname = 'VALIDUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = ' '.
    APPEND lt_seltab.
    lt_seltab-selname = 'XMC'.       "ignore mitigating controls
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.

    lt_seltab-selname = 'ORGCHK'.       "Use Org Level Check
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_orgchk.
    APPEND lt_seltab.
*      lt_seltab-selname = 'XROLERFC'.  " RFC destination for Role
*      lt_seltab-kind    = 'S'.
*      lt_seltab-sign    = 'I'.
*      lt_seltab-option  = 'EQ'.
*      lt_seltab-low     = s_rlrfc.
*      APPEND lt_seltab.
    LOOP AT s_usrrfc.                  "Cross system analysis
      lt_seltab-selname = 'XUSRRFC'.
      lt_seltab-kind    = 'S'.
      lt_seltab-sign    = s_usrrfc-sign.
      lt_seltab-option  = s_usrrfc-option.
      lt_seltab-low     = s_usrrfc-low.
      lt_seltab-high    = s_usrrfc-high.
      APPEND lt_seltab.
    ENDLOOP.

    lt_seltab-selname = 'SODVRSIO'.        "SOD Version
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_vrsio.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_ENHANC'.       "include enhanced ruleset
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_enhanc.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_HIENHN'.       "higlight enhanced ruleset
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_hienhn.
    APPEND lt_seltab.

    lt_seltab-selname = 'EXCL_ER'.
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = excl_er.
    APPEND lt_seltab.

    lt_seltab-selname = 'ERROLES'.
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = erroles.
    APPEND lt_seltab.

    lt_seltab-selname = 'VALIDUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = validusr.
    APPEND lt_seltab.

    lt_seltab-selname = 'EXLCKUSR'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = exlckusr.
    APPEND lt_seltab.

    lt_seltab-selname = 'OUTVDATE'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = outvdate.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_FLAG'.  "valid user: Show all users
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = p_flag.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_CALDET'.   "Call from Summary
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.

    lt_seltab-selname = 'P_ABAP'.       "Analyze SE systems
    lt_seltab-kind    = 'P'.
    lt_seltab-sign    = 'I'.
    lt_seltab-option  = 'EQ'.
    lt_seltab-low     = 'X'.
    APPEND lt_seltab.



    SUBMIT /psyng/sodreport_org WITH SELECTION-TABLE lt_seltab
           AND RETURN.
  ENDIF.
*  endcase.
ENDFORM.                    " double_click_on_sumry

*&---------------------------------------------------------------------*
*&      Form  get_aud_desc
*&---------------------------------------------------------------------*
*       Get critical auth description
*----------------------------------------------------------------------*
FORM get_aud_desc USING    i_swaudid TYPE /psyng/swaudhdr-swaudid
                  CHANGING e_desc TYPE /psyng/swaudhdr-description
                           e_imp  TYPE /psyng/swaudhdr-imp
                           e_owner TYPE /psyng/swaudhdr-owner.

  TYPES: BEGIN OF ty_aud,
           swaudid     TYPE /psyng/swaudhdr-swaudid,
           description TYPE /psyng/swaudhdr-description,
           imp         TYPE /psyng/swaudhdr-imp,
           owner       TYPE /psyng/swaudhdr-owner,
         END OF ty_aud.

  STATICS: lt_aud TYPE HASHED TABLE OF ty_aud WITH UNIQUE KEY swaudid.

  DATA: ls_aud TYPE ty_aud.


  READ TABLE lt_aud INTO ls_aud WITH TABLE KEY swaudid = i_swaudid.
  IF sy-subrc = 0.
    e_desc = ls_aud-description.
    e_imp  = ls_aud-imp.
    e_owner = ls_aud-owner.
    EXIT.
  ENDIF.

  SELECT SINGLE  description imp  owner              "#EC CI_SEL_NESTED
     INTO (e_desc, e_imp, e_owner)
            FROM /psyng/swaudhdr
                WHERE vrsio = p_vrsio  AND
                      swaudid = i_swaudid.
  CHECK sy-subrc = 0.

  ls_aud-swaudid     = i_swaudid.
  ls_aud-description = e_desc.
  ls_aud-imp         = e_imp.
  ls_aud-owner       = e_owner.
  INSERT ls_aud INTO TABLE lt_aud.

ENDFORM.                    " get_aud_desc

*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       Schedule background job
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: lt_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
        l_variant    LIKE vari-variant,
        lt_rsparams  TYPE rsparams OCCURS 0 WITH HEADER LINE,
        lt_varit     TYPE varit OCCURS 0 WITH HEADER LINE.


  PERFORM get_next_variant_id TABLES lt_varit lt_vari_desc
                              CHANGING l_variant.
  PERFORM fill_sel_screen_fields_to_tab TABLES lt_rsparams.

  g_variant = l_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report               = g_repid
            curr_variant              = l_variant
            vari_desc                 = lt_vari_desc
       TABLES
            vari_contents             = lt_rsparams
            vari_text                 = lt_varit
       EXCEPTIONS
            illegal_report_or_variant = 1
            illegal_variantname       = 2
            not_authorized            = 3
            not_executed              = 4
            report_not_existent       = 5
            report_not_supplied       = 6
            variant_exists            = 7
            variant_locked            = 8
            OTHERS                    = 9.

  IF sy-subrc <> 0.
    MESSAGE e208(00) WITH text-e03.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = text-146
              in_repvarnt = g_variant
              in_report   = g_repid.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.
ENDFORM.                    " schedule_back_job

*&---------------------------------------------------------------------*
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       Get next variant ID
*----------------------------------------------------------------------*
*      <--ET_VARIT      Variant Texts
*      <--ET_VARI_DESC  Variant Directory
*      <--E_VARIANT     Variant ID
*----------------------------------------------------------------------*
FORM get_next_variant_id TABLES   et_varit STRUCTURE varit
                                  et_vari_desc STRUCTURE varid
                         CHANGING e_variant TYPE vari-variant.
*  DATA: l_oldnumber(7)   TYPE n,
*        l_oldnumber_c(7) TYPE c.


  CLEAR: e_variant, et_varit, et_vari_desc.
  REFRESH: et_varit, et_vari_desc.
*
*  SELECT variant INTO e_variant FROM varid
*         WHERE report = sy-repid
*           AND variant LIKE '/PSYNG/%'
*    AND NOT variant LIKE '/PSYNG/Z%'
*      ORDER BY variant DESCENDING.
*    l_oldnumber = e_variant+7(7).
*    EXIT.
*  ENDSELECT.
*
*  IF sy-subrc NE 0.
*    e_variant = '/PSYNG/0000000'.
*  ELSE.
*    l_oldnumber = l_oldnumber + 1.
*    MOVE l_oldnumber TO l_oldnumber_c.
*    CONCATENATE '/PSYNG/' l_oldnumber_c INTO e_variant.
*  ENDIF.

*C017 Odubey 29/11/2021
CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
  EXPORTING
    i_report        = sy-repid
 IMPORTING
   E_VARIANT       = e_variant.

  et_varit-langu   = sy-langu.
  et_varit-report  = sy-repid.
  et_varit-variant = e_variant.
  et_varit-vtext   = text-146.
  APPEND et_varit.

  et_vari_desc-report  = sy-repid.
  et_vari_desc-variant = e_variant.
  APPEND et_vari_desc.
ENDFORM.                    " get_next_variant_id

*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ET_RSPARAMS  text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab
     TABLES et_rsparams STRUCTURE rsparams.

  REFRESH et_rsparams.

*Parameters
  et_rsparams-selname = 'P_BYUSER'. et_rsparams-kind = 'P'.
  et_rsparams-sign = 'I'. et_rsparams-option = 'EQ'.
  et_rsparams-low = p_byuser.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_BYUGRP'.
  et_rsparams-low = p_byugrp.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_BYPA'.
  et_rsparams-low = p_bypa.
  APPEND et_rsparams.
*  et_rsparams-selname = 'P_BYROLE'.
*  et_rsparams-low = p_byrole.
*  APPEND et_rsparams.
  et_rsparams-selname = 'P_SHWCMP'.
  et_rsparams-low = p_shwcmp.
  APPEND et_rsparams.

    et_rsparams-selname = 'P_SHWPCM'.
  et_rsparams-low = p_shwpcm.
  APPEND et_rsparams.

  et_rsparams-selname = 'VALIDUSR'.
  et_rsparams-low = validusr.
  APPEND et_rsparams.
  et_rsparams-selname = 'EXLCKUSR'.
  et_rsparams-low = exlckusr.
  APPEND et_rsparams.
  et_rsparams-selname = 'OUTVDATE'.
  et_rsparams-low = outvdate.
  APPEND et_rsparams.

  et_rsparams-selname = 'P_NOSOD'.
  et_rsparams-low = p_nosod.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_XMC'.
  et_rsparams-low = p_xmc.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_VARNT'.
  et_rsparams-low = p_varnt.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_USTB'.
  et_rsparams-low = p_ustb.
  APPEND et_rsparams.
  et_rsparams-selname = 'P_ONLYRM'.
  et_rsparams-low = p_onlyrm.
  APPEND et_rsparams.

** Select options
*  et_rsparams-selname = 'S_RCHDT'. et_rsparams-kind = 'S'.
*  et_rsparams-low  = s_rchdt-low.
*  et_rsparams-high = s_rchdt-high.
*  APPEND et_rsparams.

  CLEAR et_rsparams.
  et_rsparams-kind = 'S'.
  LOOP AT s_bname.
    et_rsparams-selname = 'S_BNAME'.
    MOVE-CORRESPONDING s_bname TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

  LOOP AT usrtype.
    et_rsparams-selname = 'USRTYPE'.
    MOVE-CORRESPONDING usrtype TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

  LOOP AT s_usrrfc.
    et_rsparams-selname = 'S_USRRFC'.
    MOVE-CORRESPONDING s_usrrfc TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

  LOOP AT s_class.
    et_rsparams-selname = 'S_CLASS'.
    MOVE-CORRESPONDING s_class TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

  LOOP AT s_werks.
    et_rsparams-selname = 'S_WERKS'.
    MOVE-CORRESPONDING s_werks TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

*  LOOP AT s_role.
*    et_rsparams-selname = 'S_ROLE'.
*    MOVE-CORRESPONDING s_role TO et_rsparams.
*    APPEND et_rsparams.
*  ENDLOOP.

  LOOP AT s_conid.
    et_rsparams-selname = 'S_CONID'.
    MOVE-CORRESPONDING s_conid TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

  LOOP AT s_imp.
    et_rsparams-selname = 'S_IMP'.
    MOVE-CORRESPONDING s_imp TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.

*  LOOP AT s_rlrfc.
*    et_rsparams-selname = 'S_RLRFC'.
*    MOVE-CORRESPONDING s_rlrfc TO et_rsparams.
*    APPEND et_rsparams.
*  ENDLOOP.

  LOOP AT s_audid.
    et_rsparams-selname = 'S_AUDID'.
    MOVE-CORRESPONDING s_audid TO et_rsparams.
    APPEND et_rsparams.
  ENDLOOP.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: swconfig   TYPE /psyng/swconfig,
        l_table(6) TYPE c,
        lt_tvarv   TYPE TABLE OF tvarv WITH HEADER LINE.

*Update Scan Table
  se_config_param 'DFLT_UPD_SCAN_TBL' swconfig-value.
  IF swconfig-value = 'Y'.
    p_ustb = 'X'.
  ELSEIF swconfig-value = 'N'.
    p_ustb = ' '.
  ENDIF.
  CLEAR swconfig.
**Org Level Check
  CLEAR swconfig.
  se_config_param 'DFLT_ORG_LEVEL_CHECK' swconfig-value.
  IF swconfig-value = 'Y'.
    p_orgchk = 'X'.
  ELSEIF swconfig-value = 'N'.
    p_orgchk = ' '.
  ENDIF.
  CLEAR swconfig.
*Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' swconfig-value.
  IF swconfig-value = 'Y'.
    validusr = 'X'.
  ELSEIF swconfig-value = 'N'.
    validusr = ' '.
  ENDIF.
  CLEAR swconfig.

*Show Mitigated Conflicts
  se_config_param 'DFLT_SHO_MIT_CONS' swconfig-value.
  IF swconfig-value = 'Y'.
    p_xmc = 'X'.
  ELSEIF swconfig-value = 'N'.
    p_xmc = ' '.
  ENDIF.
  CLEAR swconfig.

*--Hide Org Level Check option
  se_config_param 'HIDE_ORG_ANALYSIS' swconfig-value.
  IF swconfig-value = 'Y'.
    gf_hide_org = 'X'.
  ELSEIF swconfig-value = 'N'.
    gf_hide_org = ' '.
  ENDIF.

*-- Show Composite profiles

  se_config_param 'USE_ROLES' swconfig-value.
  IF swconfig-value = 'N'.
    gf_showpcom = 'X'.
  ELSE.
    gf_showpcom = ' '.
  ENDIF.
  CLEAR swconfig.

*-- Show Composite Roles/Profiles Checked or unchecked by default
  se_config_param 'DFLT_SHOW_COMPOSITE' swconfig-value.
  IF gf_showpcom IS INITIAL.
    IF swconfig-value = 'Y'.
      p_shwcmp = 'X'.
    ELSE.
      p_shwcmp = ' '.
    ENDIF.
  ELSE.
    IF swconfig-value = 'Y'.
      p_shwpcm = 'X'.
    ELSE.
      p_shwpcm = ' '.
    ENDIF.
  ENDIF.

  CLEAR swconfig.

*-- ER Button

  l_tabname = '/PSYNG/ER_VRSIO'.
  SELECT SINGLE tabname INTO l_tabname FROM dd02l
                WHERE tabname  = l_tabname
                  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc = 0.
    se_config_param 'DFLT_INCLUDE_ER' swconfig-value.
    IF swconfig-value = 'Y'.
      erroles = 'X'.
    ELSE.
      erroles = ' '.
    ENDIF.
    CLEAR swconfig.
  ENDIF.

* Default RFC
  IF s_usrrfc[] IS INITIAL.
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
      MOVE-CORRESPONDING lt_tvarv TO s_usrrfc.
      s_usrrfc-option = lt_tvarv-opti.
      APPEND s_usrrfc.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " get_initial_config

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_exetime(8) TYPE c,
        lv_count TYPE i,
        c_tusercount(6)  TYPE c,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,

        l_date(12) TYPE c,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR
  STATICS:  l_pages TYPE c,
            l_pgcnt TYPE i.

  wa-typ = 'H'.
  wa-info = 'SOD and Critical Authorization Analysis'(h11).
  APPEND wa TO header.
*SOD Version.
  wa-typ = 'S'.
  wa-key = 'Sod Version'(h12).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  CONCATENATE p_vrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'User Date & System:'(h13).
  WRITE sy-datum TO l_date.
  wa-info = l_date.
*  APPEND wa TO header.


  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO lv_exetime SEPARATED BY ':'.
*  CONCATENATE sy-uname text-141 l_date lv_exetime      "C0700
     CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
  CONCATENATE g_current_user text-141 l_date lv_exetime
  text-185 l_systemid"C0700
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.



*Summary
  c_tusercount = tusercount.
  CONCATENATE  c_tusercount text-178 INTO alv_grid_titl2
        SEPARATED BY space.
  wa-typ = 'S'.
  wa-key = 'Summary:'(h21).
  wa-info = alv_grid_titl2.
  APPEND wa TO header.


  wa-typ = 'S'.
  wa-key = 'SOD Conflicts:'(h15).
*  WRITE sy-datum TO l_date.
  wa-info = gv_sod_count.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = 'Critical Auths.:'(h16).
*  WRITE sy-datum TO l_date.
  wa-info = gv_ca_count.
  APPEND wa TO header.

  IF g_repeat_hdr_bkgdjob = 'X'.
    l_pgcnt = l_pgcnt + 1.
    l_pages = l_pgcnt.
    wa-typ = text-073.
    wa-key = text-h28.
    CONDENSE l_pages NO-GAPS.
    wa-info = l_pages.
    APPEND wa TO header.
  ENDIF.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.
  IF  sy-batch  IS INITIAL AND sy-binpt IS INITIAL .
    IF gf_st_missing_auth = 'X'.
      MESSAGE w191(/psyng/sw).
    ENDIF.
    IF NOT gf_missing_auth IS INITIAL.
      gf_auth_fail = 'X'.
      MESSAGE w190(/psyng/sw).
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
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
*&      Form  get_conflicts_from_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_conflicts_from_selection.
  DATA: BEGIN OF it_conid OCCURS 0,
          conid TYPE /psyng/conflict-conid,
          owner TYPE /psyng/conflict-owner,
        END OF it_conid,
        lt_conowner TYPE TABLE OF /psyng/conowner WITH HEADER LINE,
        lt_cuscon   TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE.

******  SELECT CLASS WRT AREA,Owner,Sensitivity,Mitigation**
*--DHORIONS 2014/05/16 If no restrictions given, don't fill GT_CONID,
*  otherwise "Show users without conflicts" doesn't work
  IF NOT s_imp[]  IS INITIAL OR
     NOT s_conid[]  IS INITIAL OR
     NOT s_risk[] IS INITIAL.

    SELECT      conid owner
    FROM       /psyng/conflict
    INTO TABLE it_conid
    WHERE vrsio   = p_vrsio
    AND conid     IN s_conid
    AND imp       IN s_imp
    AND risk      IN s_risk.


    LOOP AT it_conid.
      wa_conid-sign = 'I'.
      wa_conid-option = 'EQ'.
      wa_conid-low = it_conid-conid.
      APPEND wa_conid TO gt_conid.
    ENDLOOP.

*--Also select the custom conflicts (SF 1697)
    IF cuscon EQ 'X'.
      SELECT conid FROM /psyng/sw_cuscon
      INTO CORRESPONDING FIELDS OF TABLE lt_cuscon
      WHERE vrsio = p_vrsio
      AND   inactive <> 'X'
*  * Bug Case 3479 bug 1906
      AND imp       IN s_imp
      AND   conid IN s_conid.
*      AND   busarea IN pappa.
      LOOP AT lt_cuscon.
        wa_conid-sign = 'I'.
        wa_conid-option = 'EQ'.
        wa_conid-low = lt_cuscon-conid.
        APPEND wa_conid TO gt_conid.
      ENDLOOP.
*  ELSE.
*    APPEND LINES OF s_conid  TO gt_conid.
    ENDIF.
  ENDIF.
ENDFORM.                    " get_conflicts_from_selection
*&---------------------------------------------------------------------*
*&      Form  critical_auth_scan
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_AUDOUT  text
*----------------------------------------------------------------------*
FORM critical_auth_scan TABLES   et_audout STRUCTURE /psyng/output.
  DATA : lt_conflict  TYPE TABLE OF /psyng/conflict,
         lt_confdet   TYPE TABLE OF /psyng/confdet,
         lt_functtran TYPE TABLE OF /psyng/functtran,
         lt_faobj     TYPE TABLE OF /psyng/faobj2.
  DATA : gt_funcscan_std      TYPE TABLE OF /psyng/sw_output_org,
         gt_enh_fun           TYPE TABLE OF /psyng/sw_enh_usr_fun,
         lt_enh_fun_part      TYPE TABLE OF /psyng/sw_enh_usr_fun,
         lt_funcscan_std_part TYPE TABLE OF /psyng/sw_output_org,
         lt_allusers          TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_unique_users      TYPE TABLE OF /psyng/sw_uinfo_remote,
         gt_con_outdet        TYPE TABLE OF /psyng/sw_outputdet3.
  DATA : lt_outdet TYPE TABLE OF /psyng/sw_outputdet3,
         lt_simrols TYPE TABLE OF /psyng/sw_sel_opts_agr_name
         WITH HEADER LINE.
  DATA : lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
         lt_rfcdes          TYPE TABLE OF rfcdes WITH HEADER LINE,
         l_rfcdes           TYPE rfcdes,
         lt_local_swaudc    TYPE TABLE OF /psyng/swaudc2,
         l_local_ca         TYPE flag,
         lt_uinfo           TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lt_uinfo_all       TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lt_user_mapping    TYPE TABLE OF /psyng/sw_user_mapping,
         lt_uinfo_sorted    TYPE
         SORTED TABLE OF /psyng/sw_uinfo_remote
          WITH UNIQUE KEY rfcdest bname
          WITH HEADER LINE,
         lt_user_mapping_sorted TYPE  TABLE OF /psyng/sw_user_mapping
         WITH NON-UNIQUE KEY target_bname target_rfc
         WITH HEADER LINE,
         l_nr_users_analyzed  TYPE i,
         l_local_rfc TYPE rfcdest.
  DATA : lt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
         l_system_msg(80) TYPE c,
         lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
         lf_error TYPE flag.
  FIELD-SYMBOLS : <o_sum> TYPE /psyng/sw_output_org.
*DATA : lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,


**--Get RFC destinations for Cross system analysis
*  PERFORM load_user_rfc
*          TABLES s_usrrfc
*                 lt_rfcdes.
  REFRESH : gt_output[].
  CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.

  CALL FUNCTION '/PSYNG/SW_CA_SCAN_FUNC'
     EXPORTING
          i_validuser        = validusr
          i_outvdate         = outvdate
          i_exlckusr         = exlckusr
          i_vrsio            = p_vrsio
          i_shomit           = p_xmc
          i_enh              = p_enhanc
          i_hienh            = p_hienhn
*              i_wp               = wp
          i_xstb             = 'X'
          i_xstb_func        = 'X'
*              i_pserver          = pserver
*              i_group            = pgroup
          i_shonoca          = p_nosod
*              i_output           = lf_dont_output_to_screen
          i_remote_only      = p_onlyrm
          i_er_roles         = erroles
          i_exclude_er_roles = excl_er
     IMPORTING
*              e_usercount        = g_nr_users_analyzed
          ef_missing_auth    = gf_missing_auth
          ef_st_missing_auth = gf_st_missing_auth
     TABLES
          it_usertype        = usrtype
          it_users           = s_bname
          it_actgroups       = s_role
          it_profiles        = s_prof
          it_usergroup       = s_class
          it_ca              = s_audid
          et_outputdet       = gt_output_cafm
*              it_department      = s_depart
*              it_company         = s_comp
*              it_central_uid     = s_cuid
          et_mitigations     = gt_mccauser
          et_rpoug_auth_fail = gt_rpoug_auth_fail
          it_user_rfc        = s_usrrfc
          et_return          = lt_return
*              it_sense           = s_imp
*              it_owners          = s_owner
*              it_busarea         = s_barea
          et_enh_fun         = gt_enh_fun.

*--Handle Errors
  LOOP AT lt_return.
    IF lt_return-type = 'E'.
      lf_error = 'X'.
      lt_return-type = 'W'.
    ENDIF.
    MESSAGE ID '/PSYNG/SW' TYPE lt_return-type NUMBER '135'
    WITH lt_return-message.
  ENDLOOP.
  IF lf_error = 'X'.
    MESSAGE ID '/PSYNG/SW' TYPE 'E' NUMBER '140'
    WITH 'Fatal errors have occured.'(e04).
  ENDIF.


  LOOP AT gt_output_cafm.
    et_audout-rfcdest   = gt_output_cafm-rfcdest.
    et_audout-swaudid   = gt_output_cafm-swaudid.
    et_audout-er        = gt_output_cafm-er.
    et_audout-simu      = gt_output_cafm-simu.
    et_audout-bname     = gt_output_cafm-bname.
    et_audout-class   = gt_output_cafm-class.
    et_audout-name_text = gt_output_cafm-name_text.
    et_audout-ustyp     = gt_output_cafm-ustyp.
    et_audout-contid      = gt_output_cafm-contid.

    READ TABLE gt_enh_fun WITH KEY bname = gt_output_cafm-bname
                               funid = gt_output_cafm-swaudid
       TRANSPORTING NO FIELDS BINARY SEARCH.
    IF sy-subrc = 0.
      et_audout-enhanced = 'X'.
    ENDIF.
    APPEND et_audout.
  ENDLOOP.

*-- If Neither local nor remote is checked
  IF p_local IS INITIAL AND p_remote IS INITIAL.
    REFRESH et_audout.
  ENDIF.

  IF p_remote IS INITIAL.
    DELETE et_audout  WHERE rfcdest NE l_local_rfc.
  ENDIF.

  IF p_local IS INITIAL.
    DELETE et_audout  WHERE rfcdest EQ l_local_rfc.
  ENDIF.

ENDFORM.                    " critical_auth_scan




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
  DATA : l_numtcodes TYPE i.
  FIELD-SYMBOLS : <swaudc> TYPE /psyng/swaudc2.

*  data : lt_local_swaudhdr type table of /psyng/swaudhdr
*          with header line,
*         lt_local_scwaudc type table of /psyng/swaudc2
*         with header line.
  SELECT * FROM /psyng/swaudhdr
            INTO TABLE lt_local_swaudhdr
            WHERE swaudid IN s_audid
            AND vrsio = p_vrsio.

  SORT : lt_local_swaudhdr.

  DELETE lt_local_swaudhdr WHERE swaudid IS initial.

  IF NOT lt_local_swaudhdr[] IS INITIAL.
    SELECT * FROM /psyng/swaudc2
     INTO  TABLE lt_local_scwaudc
     FOR ALL ENTRIES IN lt_local_swaudhdr
     WHERE vrsio = p_vrsio
     AND swaudid = lt_local_swaudhdr-swaudid
     AND tcode   = lt_local_swaudhdr-tcode
     AND field <> ''. "#EC SAST_CI_GEN_CHECK
  ENDIF.

*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.

  SORT lt_local_scwaudc BY swaudid object field val_to.
  SORT lt_local_swaudhdr.

  LOOP AT lt_local_swaudhdr.
    lt_conflict-conid       = lt_local_swaudhdr-swaudid.
    APPEND lt_conflict.
    lt_confdet-conid        = lt_local_swaudhdr-swaudid.
    lt_confdet-functionid   = lt_local_swaudhdr-swaudid.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_local_swaudhdr-swaudid.
    IF lt_local_swaudhdr-tcode = '*'.
      l_numtcodes = 0.
      LOOP AT lt_local_scwaudc WHERE
                               swaudid = lt_local_swaudhdr-swaudid AND
                               object  = 'S_TCODE' AND
                               field   = 'TCD' AND
                               val_to  = ''.
        IF lt_local_scwaudc-val_from NS '*'.
          ADD 1 TO l_numtcodes.
          lt_functtran-tcode = lt_local_scwaudc-val_from.
        ELSE.
*--more then 1
          l_numtcodes = 2.
          EXIT.
        ENDIF.
      ENDLOOP.
      IF l_numtcodes <> 1.

        ADD 1 TO l_placeholder_counter.
        CONCATENATE '/PSYNG/-SWAUD' l_placeholder_counter
        INTO lt_functtran-tcode.
      ENDIF.

    ELSE.
      lt_functtran-tcode    = lt_local_swaudhdr-tcode.
*--Also update the details
      LOOP AT lt_local_scwaudc ASSIGNING <swaudc>
                               WHERE
                               swaudid = lt_local_swaudhdr-swaudid.
        <swaudc>-tcode =  lt_local_swaudhdr-tcode.
      ENDLOOP.

    ENDIF.
    APPEND lt_functtran.
    LOOP AT lt_local_scwaudc WHERE swaudid = lt_local_swaudhdr-swaudid.
      MOVE-CORRESPONDING lt_local_scwaudc TO lt_faobj.
      IF lt_faobj-val_from = lt_faobj-val_to.
        CLEAR lt_faobj-val_to.
      ENDIF.
      lt_faobj-funid = lt_functtran-functionid.
      lt_faobj-tcode = lt_functtran-tcode.
      APPEND lt_faobj.
    ENDLOOP.
  ENDLOOP.

*-- No tcode enhancement needed for summary analysis

*  CHECK p_enhanc = 'X'.
**Tcode enhancement
*  CALL FUNCTION '/PSYNG/SW_065'
*       EXPORTING
*            i_vrsio      = p_vrsio
*       TABLES
*            it_functtran = lt_functtran
*            it_faobj     = lt_faobj
*            et_tcodes    = lt_enh_tcodes.


ENDFORM.                    " load_local_swauds
*&---------------------------------------------------------------------*
*&      Form  get_user_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USERS  text
*      -->P_LT_UINFO  text
*----------------------------------------------------------------------*
FORM get_user_info TABLES
    it_users STRUCTURE /psyng/sw_sel_opts_xubname
    it_usergroup STRUCTURE /psyng/range_class
*    it_company STRUCTURE /psyng/range_company
*    it_department STRUCTURE /psyng/range_department
*    it_central_uid STRUCTURE /psyng/range_central_uid
    et_uinfo STRUCTURE /psyng/sw_uinfo_remote
    it_rfcdes STRUCTURE rfcdes
    et_user_mapping STRUCTURE /psyng/sw_user_mapping
      it_usertype STRUCTURE /psyng/sw_sel_opts_usrtyp
    it_actgroups STRUCTURE /psyng/sw_sel_opts_agr_name
    it_profile STRUCTURE /psyng/sw_sel_opts_profile
  USING
    i_validuser TYPE flag
     i_exlckusr  TYPE flag
     i_outvdate  TYPE flag
*    i_allug     TYPE flag
*    i_locusr    TYPE flag
    i_vrsio     TYPE /psyng/sodvrsio
    i_remote_only TYPE flag
  CHANGING e_usercount.

  DATA : l_tusercount_dum TYPE i,
         lt_usr02 TYPE TABLE OF /psyng/sw_uinfo_remote,
         rfcdest TYPE rfcdest,
         lt_unique_users_dum TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_iduser_dum TYPE TABLE OF /psyng/sw_iduser_fm,
         ls_uinfo TYPE /psyng/sw_uinfo,
         lt_uinfo_remote TYPE TABLE OF /psyng/sw_uinfo,
         lt_uinfo TYPE TABLE OF /psyng/sw_uinfo,
         ls_uinfo_remote TYPE /psyng/sw_uinfo_remote,
         lt_uinfo_sorted TYPE SORTED TABLE OF /psyng/sw_uinfo_remote
         WITH UNIQUE KEY rfcdest bname  WITH HEADER LINE,
         l_rfcdest TYPE rfcdest,
         l_usercount TYPE i,
         lf_match TYPE flag,
         l_maptabix LIKE sy-tabix,
         ls_swconfig TYPE /psyng/swconfig,
         lf_sod_single_comp TYPE flag,
         lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
         ls_rfc TYPE rfcdes,
         lt_uinfo_remote_map TYPE TABLE OF /psyng/sw_uinfo_remote,
         lf_valid TYPE flag,
         l_system_msg(80) TYPE c.
  .

  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF  ls_swconfig-value = 'Y'.
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
                   usrtype
                   s_role
                   s_prof
                USING
                   i_validuser
                    i_exlckusr
                    i_outvdate
*                   i_allug
*                   i_locusr
                   l_tusercount_dum
                   'X' "do user mapping
                   i_remote_only.


  SORT lt_usr02.
  DELETE ADJACENT DUPLICATES FROM lt_usr02.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*  DESCRIBE TABLE lt_usr02 LINES e_usercount.

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
    IF NOT p_onlyrm = 'X'.
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


  IF NOT p_onlyrm = 'X'.
    LOOP AT lt_usr02 ASSIGNING <usr02> WHERE
      rfcdest = l_rfcdest.
      ls_uinfo-bname =  <usr02>-bname.
      APPEND ls_uinfo TO lt_uinfo.
    ENDLOOP.
    SORT lt_uinfo.
    DELETE ADJACENT DUPLICATES FROM lt_uinfo.

*    FREE : lt_usr02.
*  CHECK NOT lt_uinfo[] IS INITIAL.
    IF NOT lt_uinfo[] IS INITIAL.
*  --Get local names for users
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
           EXPORTING
                i_name_only     = 'X'
                i_mr_company    = 'X'
                i_mr_department = 'X'
                i_central_uid   = 'X'
           TABLES
                sw_uinfo        = lt_uinfo.
      IF i_validuser = 'X'.
        LOOP AT lt_uinfo ASSIGNING <uinfo>.
          PERFORM is_user_valid CHANGING <uinfo> lf_valid.
          IF lf_valid IS INITIAL.
            DELETE lt_uinfo WHERE bname = <uinfo>-bname.
          ENDIF.
        ENDLOOP.
      ENDIF.
*  DELETE lt_uinfo WHERE NOT company    IN it_company.
*  DELETE lt_uinfo WHERE NOT department IN it_department.
*   DELETE lt_uinfo WHERE NOT ustyp  IN  it_usertype.

*  DESCRIBE TABLE lt_uinfo LINES e_usercount.

      LOOP AT lt_uinfo ASSIGNING <uinfo>.
        MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
        ls_uinfo_remote-rfcdest = l_rfcdest.
        APPEND ls_uinfo_remote TO et_uinfo.
      ENDLOOP.
    ENDIF.
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
              i_name_only = 'X'
              i_mr_company    = 'X'
              i_mr_department = 'X'
              i_central_uid   = 'X'
         TABLES
              sw_uinfo    = lt_uinfo
      EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e01
          it_rfcdes-rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e01
          it_rfcdes-rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      IF i_validuser = 'X'.
        LOOP AT lt_uinfo ASSIGNING <uinfo>.
          PERFORM is_user_valid CHANGING <uinfo> lf_valid.
          IF lf_valid IS INITIAL.
            DELETE lt_uinfo WHERE bname = <uinfo>-bname.
          ENDIF.
        ENDLOOP.
      ENDIF.

*    DELETE lt_uinfo WHERE NOT company    IN it_company.
*    DELETE lt_uinfo WHERE NOT department IN it_department.

      LOOP AT lt_uinfo ASSIGNING <uinfo>.
        MOVE-CORRESPONDING <uinfo> TO ls_uinfo_remote.
*--DHORIONS 20101201 - We don't need the RFC dstination name, but the
*                      concatenation of system id and client, which is
*                      stored in RFCOPTIONS field
*     ls_uinfo_remote-rfcdest = it_rfcdes-rfcdest.
        ls_uinfo_remote-rfcdest = it_rfcdes-rfcoptions.
        APPEND ls_uinfo_remote TO et_uinfo.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  FREE : lt_usr02.
  SORT et_user_mapping BY target_bname target_rfc.
  it_rfcdes-rfcdest  = 'LOCAL'.
  CONCATENATE sy-sysid sy-mandt INTO it_rfcdes-rfcoptions.
  APPEND it_rfcdes.
  SORT et_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_uinfo COMPARING rfcdest bname.
  lt_uinfo_sorted[] = et_uinfo[].
  FREE : et_uinfo[].

  lt_user_range-sign   = 'I'.
  lt_user_range-option = 'EQ'.



  LOOP AT it_rfcdes.
    LOOP AT lt_uinfo_sorted ASSIGNING <usr02> WHERE
    rfcdest = it_rfcdes-rfcoptions.
*      IF NOT <usr02>-department  IN it_department OR
*         NOT <usr02>-company     IN it_company OR
*         NOT <usr02>-central_uid IN it_central_uid.
*        CLEAR lf_match.
*       READ TABLE et_user_mapping WITH KEY target_bname = <usr02>-bname
*            BINARY SEARCH
*            TRANSPORTING NO FIELDS.
*        l_maptabix = sy-tabix.
*        LOOP AT et_user_mapping FROM l_maptabix
*        WHERE target_bname =  <usr02>-bname AND
*              target_rfc <> <usr02>-rfcdest.
*          READ TABLE lt_uinfo_sorted
*          INTO ls_uinfo_remote
*          WITH TABLE KEY
*           rfcdest = et_user_mapping-target_rfc
*           bname   = et_user_mapping-target_bname.
*          IF sy-subrc = 0.
*            IF  ls_uinfo_remote-department IN it_department AND
*                ls_uinfo_remote-company    IN it_company AND
*                ls_uinfo_remote-central_uid IN it_central_uid.
*              lf_match = 'X'.
**                  append ls_uinfo_remote to et_uinfo.
*              APPEND <usr02> TO et_uinfo.
*              EXIT.
*            ENDIF.
*          ENDIF.
*        ENDLOOP.
**        if lf_match <> 'X'.
**          delete et_uinfo where
**          bname = <usr02>-bname and rfcdest = <usr02>-rfcdest..
**        endif.
*      ELSE.
      IF <usr02>-ustyp IN usrtype.
        APPEND <usr02> TO et_uinfo.
      ENDIF.
    ENDLOOP.

  ENDLOOP.
  FREE : lt_uinfo_sorted.


*  LOOP AT it_rfcdes.
*    LOOP AT et_uinfo ASSIGNING <usr02> WHERE
*    rfcdest = it_rfcdes-rfcoptions.
*     if NOT <usr02>-department in it_department or
*        NOT <usr02>-company    in it_company.
*        clear lf_match.
*        read table et_user_mapping with key target_bname =
*<usr02>-bname
*        BINARY SEARCH
*        transporting no fields.
*        l_maptabix = sy-tabix.
*        loop at et_user_mapping from l_maptabix
*        where target_rfc <> <usr02>-rfcdest and
*              target_bname =  <usr02>-bname.
*          read table et_uinfo with key
*           rfcdest = et_user_mapping-target_rfc
*           bname   = et_user_mapping-target_bname.
*          if sy-subrc = 0.
*            if  et_uinfo-department in it_department AND
*                et_uinfo-company    in it_company.
*                  lf_match = 'X'.
*                  exit.
*           endif.
*         endif.
*        endloop.
*        if lf_match <> 'X'.
*          delete et_uinfo where
*          bname = <usr02>-bname and rfcdest = <usr02>-rfcdest..
*        endif.
*     endif.
*    ENDLOOP.
*  ENDLOOP.


*  DATA : lf_reject TYPE flag.
*  LOOP AT et_uinfo.
*    PERFORM check_rpoug_auth USING et_uinfo i_vrsio
*                             CHANGING lf_reject.
*    IF lf_reject = 'X'.
*      lt_rpoug_auth_fail-bname   = et_uinfo-bname.
*      lt_rpoug_auth_fail-class   = et_uinfo-class.
*      lt_rpoug_auth_fail-company = et_uinfo-company.
*      APPEND lt_rpoug_auth_fail.
*      DELETE et_uinfo.
*      gf_missing_auth = 'X'.
*      CLEAR lt_rpoug_auth_fail.
*    ENDIF.
*  ENDLOOP.






ENDFORM.                    " get_user_info

*&---------------------------------------------------------------------*
*&      Form  set_user_master_prio
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_UINFO_SORTED  text
*----------------------------------------------------------------------*
FORM set_user_master_prio
TABLES   et_uinfo STRUCTURE /psyng/sw_uinfo_remote
         it_rfcdes STRUCTURE rfcdes
         it_company STRUCTURE /psyng/range_company
         it_department STRUCTURE /psyng/range_department
         it_usergroup STRUCTURE /psyng/range_class
USING    i_vrsio TYPE /psyng/sodvrsio
CHANGING e_usercount TYPE i .
  DATA: ls_swconfig TYPE /psyng/swconfig,
        lt_rfcdes TYPE TABLE OF rfcdes WITH HEADER LINE,
        l_local TYPE rfcdest,
        l_prio TYPE i.
  .
  FIELD-SYMBOLS : <des> TYPE  rfcdes.
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
    et_uinfo-prio = l_prio.
    MODIFY et_uinfo
    TRANSPORTING prio
    WHERE
    rfcdest = lt_rfcdes-rfcoptions.
  ENDLOOP.
*--Only keep record with highest priority for each user
  SORT et_uinfo BY bname prio.
  DELETE ADJACENT DUPLICATES FROM  et_uinfo COMPARING bname.
  CLEAR ls_swconfig.
  se_config_param 'SOD_SINGLE_COMPANY' ls_swconfig-value.
  IF sy-subrc = 0 AND ls_swconfig-value = 'Y'.
*--Only consider one company per user, the one with the highest priority
    DELETE et_uinfo WHERE NOT class      IN it_usergroup.

  ENDIF.
*--End  determine priority

  DATA : l_usercount TYPE i.
  DELETE it_rfcdes WHERE rfcdest = 'LOCAL'.
*  SORT et_user_mapping BY source_bname target_rfc.
*DHO 20101202 : Authorization checks
  DATA : lf_reject TYPE flag.
  LOOP AT et_uinfo.
    PERFORM check_rpoug_auth USING et_uinfo i_vrsio
                             CHANGING lf_reject.
    IF lf_reject = 'X'.
      DELETE et_uinfo.
*      gf_missing_auth_ugroup = 'X'.
    ENDIF.
  ENDLOOP.
  CLEAR e_usercount.
  DESCRIBE TABLE et_uinfo LINES l_usercount.
  ADD l_usercount TO e_usercount.


ENDFORM.                    " set_user_master_prio


*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo_remote
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
    vrsio TYPE /psyng/sodvrsio,
    class TYPE xuclass,
    company TYPE char20,
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
*&      Form  get_selected_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_USERS  text
*      -->P_IT_USERGROUP  text
*      -->P_LT_RFCDES  text
*      -->P_LT_USERS  text
*      -->P_I_VALIDUSER  text
*      -->P_I_ALLUG  text
*      -->P_L_TUSERCOUNT  text
*----------------------------------------------------------------------*
FORM get_selected_users
     TABLES
       it_users        STRUCTURE /psyng/sw_sel_opts_xubname
       it_usergroup    STRUCTURE  /psyng/range_class
       it_rfcdes       STRUCTURE rfcdes
       it_iduser       STRUCTURE /psyng/sw_iduser_fm
       et_users        STRUCTURE /psyng/sw_uinfo_remote
       et_unique_users STRUCTURE /psyng/sw_uinfo_remote
       et_user_mapping STRUCTURE /psyng/sw_user_mapping
       usrtype         STRUCTURE /psyng/sw_sel_opts_usrtyp
       s_role          STRUCTURE /psyng/sw_sel_opts_agr_name
       s_prof          STRUCTURE /psyng/sw_sel_opts_profile
     USING
       i_validuser  TYPE flag
       i_exlckusr   TYPE flag
       i_outvdate   TYPE flag
*       i_allug      TYPE flag
*       i_locusr     TYPE flag
       e_tusercount TYPE i
       i_do_mapping TYPE flag
       i_remote_only TYPE flag.
  TYPES : BEGIN OF typ_usr02_remote  ,
           rfcdest TYPE rfcdest.
          INCLUDE STRUCTURE  usr02.
  TYPES : END OF typ_usr02_remote,
         BEGIN OF idusers_typ,
           bname LIKE usr02-bname,
         END OF idusers_typ.

  DATA : l_system_msg(80) TYPE c.
  DATA: i_include_locked TYPE flag,
        i_include_expire TYPE flag.

  DATA : lt_users TYPE TABLE OF usr02,
         ls_user  TYPE typ_usr02_remote,
         lt_idusers  TYPE HASHED TABLE OF idusers_typ
                     WITH UNIQUE KEY bname,
         ls_iduser TYPE idusers_typ,
         lt_local_users TYPE TABLE OF /psyng/sw_uinfo_remote,
         lt_remote_users TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
         lt_user_mapping_part TYPE TABLE OF /psyng/sw_user_mapping,
         lt_user_mapping_all  TYPE TABLE OF /psyng/sw_user_mapping,
         ls_rfc TYPE rfcdes,
         lt_users_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
         WITH HEADER LINE,
         lt_usergroup_range TYPE TABLE OF /psyng/sw_sel_opts_xubname.
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
              it_usertype       = usrtype
              it_actgroups      = s_role
              it_profile        = s_prof.
    CONCATENATE sy-sysid sy-mandt INTO et_users-rfcdest.

    LOOP AT lt_users ASSIGNING <usr02>.
      MOVE-CORRESPONDING <usr02> TO et_users.
      APPEND et_users.
    ENDLOOP.
*      APPEND LINES OF lt_users TO et_users.
    FREE: lt_users[].
    IF i_do_mapping = 'X'.
*--Perform user mapping for local users
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
*      IF i_locusr IS INITIAL.
      lt_users_range[] = it_users[].
      lt_usergroup_range[] = it_usergroup[].
*      ELSE.
*      FREE : lt_users_range[], lt_usergroup_range[].
*      ENDIF.

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
              i_include_locked = i_include_locked
              i_include_expired = i_include_expire
            TABLES
              et_users          = lt_users
              it_userlist       = lt_users_range
              it_usertype       = usrtype
              it_actgroups      = s_role
              it_profile        = s_prof
              EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          IF sy-subrc <> 0.
            CASE sy-subrc.
              WHEN 1 OR 2.
                MESSAGE e398(00) WITH
                text-e01
                <rfc>-rfcdest
                l_system_msg.
              WHEN 3.
                MESSAGE e398(00) WITH
                text-e01
                <rfc>-rfcdest.
            ENDCASE.
            COMMIT WORK.
          ELSE.
            LOOP AT lt_users ASSIGNING <usr02>.
              MOVE-CORRESPONDING <usr02> TO et_users.
              et_users-rfcdest = <rfc>-rfcoptions.
              APPEND et_users.
            ENDLOOP.
          ENDIF.
        ENDIF.
        FREE : lt_user_mapping_part.
      ENDIF.
      REFRESH : lt_users[].
*      APPEND LINES OF lt_users TO et_users.
*--Dhorions 20101013
*      IF i_locusr IS INITIAL.
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
          i_include_locked = i_include_locked
          i_include_expired = i_include_expire
        TABLES
          et_users          = lt_users
          it_userlist       = it_users
          it_grouplist      = it_usergroup
          it_usertype       = usrtype
          it_actgroups      = s_role
          it_profile        = s_prof
          EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1 OR 2.
            MESSAGE e398(00) WITH
            text-e01
            <rfc>-rfcdest
            l_system_msg.
          WHEN 3.
            MESSAGE e398(00) WITH
            text-e01
            <rfc>-rfcdest.
        ENDCASE.
        COMMIT WORK.
        LEAVE LIST-PROCESSING.
      ENDIF.

      LOOP AT lt_users ASSIGNING <usr02>.
        MOVE-CORRESPONDING <usr02> TO et_users.
        et_users-rfcdest = <rfc>-rfcoptions.
        APPEND et_users.
      ENDLOOP.
*      ENDIF.
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
  ENDIF.
*--delete dupes
  SORT et_users BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM et_users COMPARING rfcdest bname.
*DHO 20101202 - Authority Checks moved to form get_user_info
*--Authority checks
*  LOOP AT et_users ASSIGNING <usr>.
*    IF i_allug <> 'X'. "ignore Y&SW_RPOUG
*      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*               ID 'CLASS' FIELD <usr>-class.
*    ENDIF.
*    IF sy-subrc <> 0 AND NOT ( <usr>-class IS INITIAL )
*      AND i_allug <> 'X'.
*      DELETE et_users WHERE bname = <usr>-bname.
*    ENDIF.
*  ENDLOOP.

  DESCRIBE TABLE et_users LINES e_tusercount.
  et_unique_users[] = et_users[].
*--Get unique users based on it_idusers
  LOOP AT it_iduser ASSIGNING <iduser>.
    ls_iduser-bname = <iduser>-idbname.
    INSERT ls_iduser INTO TABLE lt_idusers.
  ENDLOOP.
  LOOP AT et_users ASSIGNING <usr>.
    READ TABLE lt_idusers WITH TABLE KEY bname = <usr>-bname
    TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      DELETE  et_unique_users WHERE bname = <usr>-bname.
    ENDIF.
  ENDLOOP.


  et_user_mapping[] = lt_user_mapping_all[].

ENDFORM.                    " get_selected_users

*&---------------------------------------------------------------------*
*&      Form  is_user_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_UINFO  text
*      <--P_LF_VALID  text
*----------------------------------------------------------------------*
FORM is_user_valid CHANGING is_uinfo TYPE /psyng/sw_uinfo
                            ef_valid.
  STATICS : l_sf_config_checked TYPE flag,
        dsp_mng_lock    VALUE 'N',
        dsp_slf_lock    VALUE 'Y'.
  DATA: swconfig TYPE /psyng/swconfig.
  IF l_sf_config_checked IS INITIAL.
    CLEAR: swconfig.
    se_config_param 'REP_USR_LOK_DSP_MGR' swconfig-value.
    IF swconfig-value = 'Y'.
      dsp_mng_lock = 'Y'.
    ENDIF.
    CLEAR swconfig.
    se_config_param 'REP_USR_LOK_DSP_SLF' swconfig-value.
    IF swconfig-value = 'N'.
      dsp_slf_lock = 'N'.
    ENDIF.
    l_sf_config_checked = 'X'.
  ENDIF.


  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  CLEAR ef_valid.
  IF is_uinfo-gltgv IS INITIAL.
    is_uinfo-gltgv = '00010101'.
  ENDIF.
  IF is_uinfo-gltgb IS INITIAL.
    is_uinfo-gltgb = '99991231'.
  ENDIF.
  IF is_uinfo-gltgv <= sy-datum AND is_uinfo-gltgb >= sy-datum.
*SF Case 1405
    l_uflagx = is_uinfo-uflag."unicode
    IF l_uflagx O yusloc OR "locked by admin
       l_uflagx O yugloc.   "locked by CUA admin
*  --User is locked by Local or Global Administrator
      IF dsp_mng_lock = 'Y'.
        ef_valid = 'X'.
      ENDIF.
    ELSEIF l_uflagx O yulock.
*  --User is locked by failed logins
      IF dsp_slf_lock = 'Y'.
        ef_valid = 'X'.
      ENDIF.
    ELSE.
*  --User is active
      ef_valid = 'X'.
    ENDIF.
  ENDIF.

ENDFORM.                    " is_user_valid
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Form  load_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_REMRFC  text
*      -->P_LT_REMOTE_ANAL_RFC  text
*----------------------------------------------------------------------*
FORM load_rfc
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
           WHERE rfcdest IN it_rfc.
  ENDIF.
  LOOP AT et_rfcdes.
    FREE : lt_dest.
    lt_dest-rfcdest = et_rfcdes-rfcdest.
    APPEND lt_dest.
    CALL FUNCTION 'RFC_WALK_THRU_TEST'
         EXPORTING
              test_in      = l_rfc_test
         TABLES
              destinations = lt_dest
              log          = lt_rfc_log.
    LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
      PERFORM report_rfc_error USING
      lt_rfc_log-rfcdest lt_rfc_log-rfclog.
    ENDLOOP.
  ENDLOOP.

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
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e01
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e01
          l_rfcdest.
      ENDCASE.
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
*&---------------------------------------------------------------------*
*&      Form  f4_werks
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_S_WERKS_LOW  text
*----------------------------------------------------------------------*
FORM f4_werks CHANGING e_werks TYPE /psyng/persa.
  DATA: lt_f4_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = 'PA0001'
            fieldname         = 'WERKS'
       TABLES
            return_tab        = lt_f4_return
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.

  IF sy-subrc = 0.
    READ TABLE lt_f4_return INDEX 1.
    e_werks = lt_f4_return-fieldval.
  ENDIF.

ENDFORM.                                                    " f4_werks
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

  IF gf_auth_fail IS INITIAL.
    lt_func-fcode = 'FAILEDUSER'.
    APPEND lt_func.
  ENDIF.

  SET PF-STATUS 'SUMM' EXCLUDING lt_func.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA: alv_layout      TYPE slis_layout_alv,
        gs_variant TYPE disvariant.
  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  SORT gt_rpoug_auth_fail.
  DELETE ADJACENT DUPLICATES FROM gt_rpoug_auth_fail.

  DELETE gt_rpoug_auth_fail WHERE bname IS initial.

  PERFORM build_alv_catalog_user_grp_cmp.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING

          is_layout             = alv_layout
          it_fieldcat           = i_fieldcat_alv
          i_save                = 'A'
          is_variant            = gs_variant
   	TABLES
          t_outtab              = gt_rpoug_auth_fail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*&      Form  build_alv_catalog_user_grp_cmp
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_alv_catalog_user_grp_cmp.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
        program         LIKE sy-repid.
  program = sy-repid.
  REFRESH i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h01.
  wa_fieldcat_alv-seltext_m = text-h01.
  wa_fieldcat_alv-seltext_s = text-h01.
  wa_fieldcat_alv-reptext_ddic = text-h01.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h19.
  wa_fieldcat_alv-seltext_m = text-h19.
  wa_fieldcat_alv-seltext_s = text-h19.
  wa_fieldcat_alv-reptext_ddic = text-h19.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

ENDFORM.                    " build_alv_catalog_user_grp_cmp

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
           lt_data   LIKE TABLE OF ls_data,
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
    AND b~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK

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
      AND b~ddlanguage = 'EN'."#EC SAST_CI_GEN_CHECK
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
*&---------------------------------------------------------------------*
*&      Form  show_help
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0730   text
*----------------------------------------------------------------------*
FORM show_help USING    i_dokname.
  CALL FUNCTION '/PSYNG/BASIS_F1_HELP'
       EXPORTING
            dokname = i_dokname.


ENDFORM.                    " show_help
*&---------------------------------------------------------------------*
*&      Form  load_user_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_XUSRRFC  text
*      -->P_LT_RFCDES  text
*----------------------------------------------------------------------*
FORM load_user_rfc  TABLES
      it_user_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  .
  DATA : l_rfcdest TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys TYPE rfcdest.
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
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
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
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
  AND rfcdest <> 'LOCAL'.

ENDFORM.                    " load_user_rfc
*&---------------------------------------------------------------------*
*&      Form  show_mit_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_OUTPUT  text
*----------------------------------------------------------------------*
FORM show_mit_details USING 1stoutput LIKE gt_output.

  DATA : l_showuser TYPE flag,
         l_showgroup TYPE flag,
         l_showrole TYPE flag,
         l_showcriauth TYPE flag,
         lt_mcuser_show LIKE TABLE OF gt_mcuser WITH HEADER LINE.
  CLEAR : l_showuser,l_showgroup,l_showrole,lt_mcuser_show[].

*-------Mitigations due to SOD-------*
  IF gt_output-type = 'S'.
    LOOP AT gt_mcuser_sod WHERE userid = 1stoutput-bname
                     AND conid  = 1stoutput-conid.
      MOVE-CORRESPONDING gt_mcuser_sod TO lt_mcuser_show.
      APPEND lt_mcuser_show.

      CASE gt_mcuser_sod-type.
        WHEN '1'.
          l_showuser    = 'X'.
        WHEN '2'.
          l_showgroup   = 'X'.
        WHEN '3'.
          l_showcriauth = 'X'.
        WHEN '4'.
          l_showrole    = 'X'.
        WHEN '5'.
          l_showcriauth = 'X'.
          l_showrole    = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDIF.

*-------Mitigations due to Critical Authorizations-------*
  IF gt_output-type = 'C'.
    LOOP AT gt_mccauser WHERE userid = 1stoutput-bname
                        AND swaudid = 1stoutput-conid.
      MOVE-CORRESPONDING gt_mccauser TO lt_mcuser_show.
      APPEND lt_mcuser_show.

      CASE gt_mccauser-type.
        WHEN '1'.
          l_showuser    = 'X'.
        WHEN '2'.
          l_showgroup   = 'X'.
        WHEN '3'.
          l_showcriauth = 'X'.
        WHEN '4'.
          l_showrole    = 'X'.
        WHEN '5'.
          l_showcriauth = 'X'.
          l_showrole    = 'X'.
      ENDCASE.
    ENDLOOP.
  ENDIF.

*----Call Mitigation Popup----*
  CALL FUNCTION '/PSYNG/SW_076'
       EXPORTING
            if_display      = 'X'
            if_show_class   = l_showgroup
            if_show_role    = l_showrole
            if_show_criauth = l_showcriauth
       TABLES
            it_mcuser       = lt_mcuser_show.

ENDFORM.                    " show_mit_details

*&---------------------------------------------------------------------*
*&      Form  process_mitigations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM process_mitigations.
*  DATA : lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
*         lt_rfcdes          TYPE TABLE OF rfcdes WITH HEADER LINE,
*         l_rfcdes           TYPE rfcdes,
*         l_system_msg(80) TYPE c,
*         lt_mcuser TYPE TABLE OF /psyng/mitigation_assignment
*                                  WITH HEADER LINE,
*         lt_mcuser_part TYPE TABLE OF /psyng/mitigation_assignment
*                                  WITH HEADER LINE.
*  FIELD-SYMBOLS: <mcuser> TYPE /psyng/mitigation_assignment.
*  DATA : l_idx TYPE sy-tabix.
*
**--Get RFC destinations for Cross system analysis
*  PERFORM load_user_rfc
*          TABLES s_usrrfc
*                 lt_rfcdes.
*
**--Append local system to rfcdes table for easier looping over
** user mapping table
*  lt_rfcdes-rfcdest = 'LOCAL'.
*  CONCATENATE sy-sysid sy-mandt INTO l_rfcdes.
*  lt_rfcdes-rfcoptions = l_rfcdes.
*  APPEND lt_rfcdes.
*
*  LOOP AT lt_rfcdes.
*    IF lt_rfcdes-rfcdest = 'LOCAL'.
*      CALL FUNCTION '/PSYNG/SW_096'
*           EXPORTING
*                i_vrsio      = p_vrsio
*                i_start_date = '00000000'
*                i_end_date   = '00000000'
*           TABLES
*                it_users     = s_bname
**                it_auds      = lt_auds
*                et_mcusers   = lt_mcuser_part
*                it_uinfo     = gt_uinfo.
**                it_simu_roles = gt_simu_roles.
*    ELSE.
*      CALL FUNCTION '/PSYNG/SW_096'
*           DESTINATION lt_remote_anal_rfc-rfcdest
*           EXPORTING
*                i_vrsio      = p_vrsio
*                i_start_date = '00000000'
*                i_end_date   = '00000000'
*           TABLES
*                it_users     = s_bname
**                it_auds      = lt_auds
*                et_mcusers   = lt_mcuser_part
*                it_uinfo     = gt_uinfo
**                it_simu_roles = gt_simu_roles
*                 EXCEPTIONS
*              communication_failure = 1 MESSAGE l_system_msg
*              system_failure        = 2 MESSAGE l_system_msg
*              OTHERS                = 3.
*      IF sy-subrc <> 0.
*        CASE sy-subrc.
*          WHEN 1 OR 2.
*            MESSAGE e398(00) WITH
*            text-e04
*            lt_rfcdes-rfcdest
*            l_system_msg.
*          WHEN 3.
*            MESSAGE e398(00) WITH
*            text-e04
*            lt_rfcdes-rfcdest.
*        ENDCASE.
*        COMMIT WORK.
*      ENDIF.
*    ENDIF.
*    APPEND LINES OF lt_mcuser_part TO lt_mcuser.
*    FREE : lt_mcuser_part.
*  ENDLOOP.
*
*  SORT lt_mcuser BY userid vrsio swaudid rfcdest.
*  gt_mcuser[] = lt_mcuser[].
*
*  DATA: lt_usr02 TYPE TABLE OF usr02 WITH HEADER LINE.
*
*  APPEND LINES OF gt_mcuser_sod TO gt_mcuser.
*  SORT gt_mcuser.
*  DELETE ADJACENT DUPLICATES FROM gt_mcuser.
*  SORT gt_output BY bname conid rfcdest.
*
*
*  LOOP AT gt_output.
**-----Mitigation is due to Crit Auth
*    READ TABLE gt_mcuser WITH KEY
*                         swaudid  = gt_output-conid
*                         userid   = gt_output-bname
*                         vrsio    = p_vrsio.
*    IF sy-subrc EQ 0.
*      IF gt_mcuser-to_date LT sy-datum OR
*      gt_mcuser-from_date GT sy-datum.
*        CONTINUE.
*      ENDIF.
*      gt_output-contid    = gt_mcuser-contid.
*      gt_output-auditor   = gt_mcuser-auditor.
*      gt_output-from_date = gt_mcuser-from_date.
*      gt_output-to_date   = gt_mcuser-to_date.
*      CASE gt_mcuser-type.
*        WHEN '1'.
*          gt_output-mit_icon = '@EK@'.
*        WHEN '2'.
*          gt_output-mit_icon = '@ID@'.
*        WHEN '3'.
*          gt_output-mit_icon = '@EK@'.
*        WHEN '4'.
*          gt_output-mit_icon = '@F8@'.
*        WHEN '5'.
*          gt_output-mit_icon = '@F8@'.
*      ENDCASE.
*
*      APPEND gt_output TO gt_output_final.
*    ELSE.
*
**--Mitigation is assigned to User
*      READ TABLE gt_mcuser WITH KEY
*             conid  = gt_output-conid
*             contid = gt_output-contid
*             userid = gt_output-bname
*             vrsio  = p_vrsio.
*      IF sy-subrc EQ 0.
*        IF gt_mcuser-to_date LT sy-datum OR
*        gt_mcuser-from_date GT sy-datum.
*          CONTINUE.
*        ENDIF.
*        l_idx = sy-tabix.
*        gt_output-contid    = gt_mcuser-contid.
*        gt_output-auditor   = gt_mcuser-auditor.
*        gt_output-from_date = gt_mcuser-from_date.
*        gt_output-to_date   = gt_mcuser-to_date.
**----Mitigation Icon Addition
*        CASE gt_mcuser-type.
*          WHEN '1'.
*            gt_output-mit_icon = '@EK@'.
*          WHEN '2'.
*            gt_output-mit_icon = '@ID@'.
*          WHEN '3'.
*            gt_output-mit_icon = '@EK@'.
*          WHEN '4'.
*            gt_output-mit_icon = '@F8@'.
*          WHEN '5'.
*            gt_output-mit_icon = '@F8@'.
*        ENDCASE.
*        APPEND gt_output TO gt_output_final.
*
*      ELSE.
**--Mitigation is assigned to User Group
*        SELECT SINGLE auditor from_date to_date      "#EC CI_SEL_NESTED
*        INTO (gt_output-auditor, gt_output-from_date,
*gs_output-to_date)
*        FROM /psyng/mcusrgrp
*        WHERE contid = lt_mcuser-contid
*          AND conid  = lt_mcuser-conid
*          AND class  = lt_mcuser-class
*          AND vrsio  = p_vrsio.
*        APPEND gt_output TO gt_output_final.
*      ENDIF.
*    ENDIF.
*    CLEAR gt_output.
*  ENDLOOP.
*
*  REFRESH gt_output[].
*  gt_output[] = gt_output_final[].
  LOOP AT gt_output.
    IF gt_output-type = 'C'.
      IF p_xmc = 'X' AND NOT gt_output-contid IS INITIAL.
        LOOP AT gt_mccauser WHERE
                           contid = gt_output-contid AND
                           swaudid  = gt_output-conid  AND
                           userid = gt_output-bname  AND
                           vrsio  = p_vrsio        AND
                           from_date LE sy-datum     AND
                           to_date   GE sy-datum.

          gt_output-auditor   = gt_mccauser-auditor.
          gt_output-from_date = gt_mccauser-from_date.
          gt_output-to_date   = gt_mccauser-to_date.
          CASE gt_mccauser-type.
            WHEN '3'.
              gt_output-mit_icon = '@EK@'.
            WHEN '5'.
              gt_output-mit_icon = '@F8@'.
          ENDCASE.
*        ADD 1 TO g_nummit.
          EXIT."first valid one is ok.
        ENDLOOP.
      ENDIF.
    ELSEIF gt_output-type = 'S'.
      IF p_xmc = 'X' AND NOT gt_output-contid IS INITIAL.
*     Get mitigation assignment info
        LOOP AT gt_mcuser_sod WHERE
                         contid = gt_output-contid AND
                         conid  = gt_output-conid  AND
                         userid = gt_output-bname  AND
                         vrsio  = p_vrsio         AND
                         from_date LE sy-datum     AND
                         to_date   GE sy-datum.
          gt_output-auditor   = gt_mcuser_sod-auditor.
          gt_output-from_date = gt_mcuser_sod-from_date.
          gt_output-to_date   = gt_mcuser_sod-to_date.
          CASE gt_mcuser_sod-type.
            WHEN '1'.
              gt_output-mit_icon = '@EK@'.
            WHEN '2'.
              gt_output-mit_icon = '@ID@'.
            WHEN '4'.
              gt_output-mit_icon = '@F8@'.
          ENDCASE.
          EXIT."first valid one is ok.
        ENDLOOP.
        IF sy-subrc <> 0 .
*       Mitigation is assigned to user group instead of user
          SELECT SINGLE auditor from_date to_date    "#EC CI_SEL_NESTED
                         INTO (gt_output-auditor, gt_output-from_date,
                               gt_output-to_date)
                         FROM /psyng/mcusrgrp
                        WHERE contid = gt_output-contid
                          AND conid  = gt_output-conid
                          AND class  = gt_output-class
                          AND vrsio  = p_vrsio.
        ENDIF.
      ENDIF.

    ENDIF.
    MODIFY gt_output TRANSPORTING auditor from_date to_date mit_icon.
  ENDLOOP.

ENDFORM.                    " process_mitigations
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


  APPEND LINES OF s_usrrfc TO r_rfcs.
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

  FREE : gt_rfcdest.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.


ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES
      it_role_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc.
    IF sy-subrc <> 0.
*--At this point user has already decided to continue despite incorrect
*   rfc destinations, so don't stop here
      MESSAGE s004(sr).
    ENDIF.
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
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
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
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_P_VRSIO  text
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
