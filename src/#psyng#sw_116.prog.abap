REPORT /psyng/sw_116.
TABLES : usr02,rfcdes.
CONSTANTS: max_wp TYPE i VALUE '4'.
DATA : lt_users_to_check TYPE TABLE OF ush02 WITH HEADER LINE,
       lt_users_to_check_tmp TYPE TABLE OF ush02 WITH HEADER LINE,
       lt_modified_users TYPE TABLE OF ush02 WITH HEADER LINE,
       lt_usr02 TYPE TABLE OF usr02 WITH HEADER LINE,
       l_num_checked TYPE i,
       l_num_changed TYPE i,
       l_dat TYPE dats,
       lt_cntuser TYPE TABLE OF /psyng/sw_cntusv WITH HEADER LINE,
       lt_cntuser_updated TYPE TABLE OF /psyng/sw_cntusv
       WITH HEADER LINE,
       lt_cntuser_analyzed TYPE TABLE OF /psyng/sw_cntusv
       WITH HEADER LINE,
       l_date TYPE dats,
       l_time TYPE tims,
       lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       lt_cnt_functions TYPE TABLE OF /psyng/sw_cntfun WITH HEADER LINE,
       lt_cnt_critauths TYPE TABLE OF /psyng/sw_cntca WITH HEADER LINE,
       lt_cnt_tcodes type table of /PSYNG/SW_CNTTCD with header line,
       exit_proc,
       program         LIKE sy-repid.
*Background job variables'
DATA: curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE,
      lt_functions TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
      lt_critauths TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
      lt_crittcodes TYPE TABLE OF /psyng/sw_output_org WITH HEADER LINE,
      ls_date type dats,
      ls_time type tims
      .
DATA: variant LIKE vari-variant.

FIELD-SYMBOLS : <cntuser> TYPE /psyng/sw_cntusv.

SELECTION-SCREEN: BEGIN OF BLOCK act_o WITH FRAME TITLE text-t01.
PARAMETERS : init  TYPE flag RADIOBUTTON GROUP g1 ,
             updat TYPE flag RADIOBUTTON GROUP g1 DEFAULT 'X'.
SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN: COMMENT 1(50) text-188.
SELECTION-SCREEN: END OF LINE.

PARAMETERS : sod  TYPE flag AS CHECKBOX ,
             ca   TYPE flag AS CHECKBOX ,
             tc   TYPE flag AS CHECKBOX.


SELECTION-SCREEN: END OF BLOCK act_o .
SELECTION-SCREEN: BEGIN OF BLOCK usr_o WITH FRAME TITLE text-t02.
SELECT-OPTIONS : bname FOR usr02-bname.
PARAMETERS :    active TYPE flag AS CHECKBOX,
                vrsio  TYPE /psyng/sodvrsio.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0' MODIF ID exe.

SELECTION-SCREEN: COMMENT 3(65) text-008
                                    MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : defgrp TYPE flag  RADIOBUTTON GROUP ppro DEFAULT 'X'
                                    MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-090 FOR FIELD defgrp
                                    MODIF ID exe.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS : specgrp TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-089 FOR FIELD specgrp
                                   MODIF ID exe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pgroup TYPE rzlli_apcl MODIF ID exe.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.

PARAMETERS : specsrv TYPE flag  RADIOBUTTON GROUP ppro
                                   MODIF ID exe.
SELECTION-SCREEN: COMMENT 3(27) text-088 FOR FIELD specsrv
                                   MODIF ID exe.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: pserver LIKE msxxlist-name MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  30(20) text-002 USER-COMMAND gpsv
                                       MODIF ID exe.
SELECTION-SCREEN: END OF LINE.
PARAMETERS : upp TYPE i                MODIF ID exe DEFAULT '5000'.
SELECTION-SCREEN: END OF BLOCK usr_o .
SELECTION-SCREEN: BEGIN OF BLOCK rfc_o WITH FRAME TITLE text-t03.
PARAMETERS: rfcs TYPE rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh MODIF ID rem.
SELECTION-SCREEN: END OF BLOCK rfc_o .


*---Background Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME TITLE  text-b07.
SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK bgd_o.

INITIALIZATION.
  program = sy-repid.


AT SELECTION-SCREEN.
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ELSE.
      CALL TRANSACTION 'SM37'.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.

    EXIT.
  ENDIF.
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
  IF exit_proc = 'Y'.

    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
            VIA SELECTION-SCREEN
            USING SELECTION-SET curr_variant .
  ENDIF.

  l_date = sy-datum.
  l_time = sy-uzeit.

  MESSAGE s002(/psyng/sw) WITH
  'Updating Central Directory on '(i08) rfcs.
  MESSAGE s002(/psyng/sw) WITH
  'Following analysis will be executed:'(i09).

  if sod = 'X'.
    MESSAGE s002(/psyng/sw) WITH
    '-User SOD Analysis'(i10).
  endif.
  if ca = 'X'.
    MESSAGE s002(/psyng/sw) WITH
    '-User Critical Authorization Analysis'(i11).
  endif.
  if tc = 'X'.
    MESSAGE s002(/psyng/sw) WITH
    '-User Critical Transaction Analysis'(i12).
  endif.

  COMMIT WORK.


  MESSAGE s002(/psyng/sw) WITH
  'Loading users'.
  COMMIT WORK.

*--First get a list of all users
  CALL FUNCTION '/PSYNG/SW_041'
       EXPORTING
            i_validuser = active
       TABLES
            it_userlist = bname
            et_users    = lt_usr02.

  DESCRIBE TABLE lt_users_to_check LINES l_num_checked.
  IF init = 'X'.
    l_dat = '19000101'.
*--Set the last checked date to initial date
    lt_users_to_check-modda = l_dat.
    CLEAR lt_users_to_check-modti.
    LOOP AT lt_usr02.
      lt_users_to_check-bname = lt_usr02-bname.
      APPEND lt_users_to_check.
    ENDLOOP.
    lt_modified_users[] = lt_users_to_check[].
  ELSE.
* Load the last update time from central system
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
    CALL FUNCTION '/PSYNG/SW_111' DESTINATION rfcs
      EXPORTING
        i_sysid        = sy-sysid
        i_mandt        = sy-mandt
        i_vrsio        = vrsio
      TABLES
        et_users       = lt_cntuser
        it_users       = bname
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
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
    SORT lt_cntuser BY userid.
    LOOP AT lt_usr02.
      READ TABLE lt_cntuser WITH KEY userid = lt_usr02-bname
      BINARY SEARCH
      TRANSPORTING
      update_date update_time
      ca_date     ca_time
      sod_date    sod_time
      ct_date     ct_time.
      IF sy-subrc = 0.
        lt_users_to_check-modda = lt_cntuser-update_date.
        lt_users_to_check-modti = lt_cntuser-update_time.
*--Get the oldest analysis date for the user,
*  we'll re-analyze if any change happened after that date
        if not lt_cntuser-CA_DATE is initial.
          ls_date = lt_cntuser-CA_DATE.
          ls_time = lt_cntuser-CA_time.
        endif.

        if not lt_cntuser-CT_DATE is initial and
           ( lt_cntuser-CT_DATE < ls_date or
             ( lt_cntuser-CT_DATE = ls_date and
              lt_cntuser-CT_time < ls_time )
            ).
          ls_date = lt_cntuser-CT_DATE.
          ls_time = lt_cntuser-CT_time.
        else.
        if not lt_cntuser-SOD_DATE is initial AND
        ( lt_cntuser-SOD_DATE < ls_date or
           ( lt_cntuser-SOD_DATE = ls_date and
            lt_cntuser-SOD_time < ls_time )
        ).
          ls_date = lt_cntuser-SOD_DATE.
          ls_time = lt_cntuser-SOD_time.
        endif.
        endif.
        if not ls_date is initial and
           not ls_time is initial.
          lt_users_to_check-modda = ls_date.
          lt_users_to_check-modti = ls_time.
        endif.
      ELSE.
*--Never checked before
        lt_users_to_check-modda = '19000101'.
        lt_users_to_check-modti = '000000'.
      ENDIF.
      lt_users_to_check-bname = lt_usr02-bname.
      APPEND lt_users_to_check.
    ENDLOOP.
    lt_users_to_check_tmp[] = lt_users_to_check[].

    MESSAGE s002(/psyng/sw) WITH
    'Identifying users that changed'.
    COMMIT WORK.


        CALL FUNCTION '/PSYNG/SW_109'
             TABLES
                  it_users = lt_users_to_check
                  et_users = lt_modified_users.
    lt_users_to_check[] = lt_users_to_check_tmp[].
*--Now we have the last modification moment of all our users
*--If that date is after the last analysis, reanalyze
    DESCRIBE TABLE lt_modified_users LINES l_num_changed.
  ENDIF.


  IF sod = 'X'.
    PERFORM analyze_users_sod
      TABLES lt_cntuser
             lt_modified_users
             lt_functions
      USING init.
  ENDIF.
  IF ca = 'X'.
    PERFORM analyze_users_ca
      TABLES lt_cntuser
             lt_modified_users
             lt_critauths
      USING init.

  ENDIF.

  IF tc = 'X'.
    PERFORM analyze_users_ct
      TABLES lt_cntuser
             lt_modified_users
             lt_crittcodes
      USING init.

  ENDIF.

  MESSAGE s002(/psyng/sw) WITH 'Collecting user master Data'.
  COMMIT WORK.
*--Collect information about all current users in the system
  LOOP AT lt_users_to_check.
    lt_uinfo-bname = lt_users_to_check-bname.
    APPEND lt_uinfo.
  ENDLOOP.
*--Read user details /PSYNG/SW_USER_INFO
  IF NOT lt_uinfo[] IS INITIAL.
        CALL FUNCTION '/PSYNG/SW_USER_INFO'
             EXPORTING
                  i_name_only     = 'X'
                  i_mr_company    = 'X'
                  i_mr_department = 'X'
                  i_central_uid   = 'X'
             TABLES
                  sw_uinfo        = lt_uinfo.
  ENDIF.
*--Move to format of central user directory
*  lt_cntuser_updated-update_date = l_date.
*  lt_cntuser_updated-update_time = l_time.
   lt_cntuser_updated-vrsio        = vrsio.
  IF sod = 'X'.
    lt_cntuser_updated-sod_date    = l_date.
    lt_cntuser_updated-sod_time    = l_time.
  ENDIF.
  IF ca = 'X'.
    lt_cntuser_updated-ca_date    = l_date.
    lt_cntuser_updated-ca_time    = l_time.
  ENDIF.
  IF tc = 'X'.
    lt_cntuser_updated-ct_date    = l_date.
    lt_cntuser_updated-ct_time    = l_time.
  ENDIF.

  CONCATENATE sy-sysid sy-mandt INTO lt_cntuser_updated-sysclient.
  "#EC SAST_CI_GEN_CHECK
  LOOP AT lt_uinfo.
*--Get last change date for user
    READ TABLE lt_modified_users WITH KEY bname = lt_uinfo-bname.
    IF sy-subrc = 0.
      lt_cntuser_updated-update_date = lt_modified_users-modda.
      lt_cntuser_updated-update_time = lt_modified_users-modti.
    ELSE.
      lt_cntuser_updated-update_date = l_date.
      lt_cntuser_updated-update_time = l_time.
    ENDIF.
    lt_cntuser_updated-userid    = lt_uinfo-bname.
    lt_cntuser_updated-usergroup = lt_uinfo-class.
    MOVE-CORRESPONDING lt_uinfo TO lt_cntuser_updated.
*--Set last analysis times to previous values
*  if one of the analysis wasn't executed
    IF sod <> 'X' OR ca <> 'X' OR tc <> 'X'.
      READ TABLE lt_cntuser WITH KEY userid = lt_uinfo-bname.
      IF sy-subrc = 0.
        IF sod <> 'X'.
          lt_cntuser_updated-sod_date    = lt_cntuser-sod_date.
          lt_cntuser_updated-sod_time    = lt_cntuser-sod_time.
        ENDIF.
        IF ca <> 'X'.
          lt_cntuser_updated-ca_date    = lt_cntuser-ca_date.
          lt_cntuser_updated-ca_time    = lt_cntuser-ca_time.
        ENDIF.
        IF tc <> 'X'.
          lt_cntuser_updated-ct_date    = lt_cntuser-ct_date.
          lt_cntuser_updated-ct_time    = lt_cntuser-ct_time.
        ENDIF.
      ENDIF.
    ENDIF.
    APPEND lt_cntuser_updated.

  ENDLOOP.
*--Collect users that no longer exist in this system
  LOOP AT lt_cntuser_updated.
    DELETE lt_cntuser WHERE userid =  lt_cntuser_updated-userid.
  ENDLOOP.




*--Move functions to format of central directory
  lt_cnt_functions-sysclient = lt_cntuser_updated-sysclient.
  "#EC SAST_CI_GEN_CHECK
  LOOP AT lt_functions.
    MOVE-CORRESPONDING lt_functions TO lt_cnt_functions.
    lt_cnt_functions-userid = lt_functions-bname.
    lt_cnt_functions-vrsio  = vrsio.
    APPEND lt_cnt_functions.
  ENDLOOP.
  FREE : lt_functions.
*--Move critical auths to format of central directory
  lt_cnt_critauths-sysclient = lt_cntuser_updated-sysclient.
  "#EC SAST_CI_GEN_CHECK
  LOOP AT lt_critauths.
    MOVE-CORRESPONDING lt_critauths TO lt_cnt_critauths.
    lt_cnt_critauths-userid = lt_critauths-bname.
    lt_cnt_critauths-swaudid = lt_critauths-funid.
    lt_cnt_critauths-vrsio  = vrsio.
    APPEND lt_cnt_critauths.
  ENDLOOP.
  FREE : lt_critauths.
*--Move critical tcodes to format of sentral duirectory
  lt_cnt_tcodes-sysclient = lt_cntuser_updated-sysclient.
  "#EC SAST_CI_GEN_CHECK
  LOOP AT lt_crittcodes.
    MOVE-CORRESPONDING lt_crittcodes TO lt_cnt_tcodes.
    lt_cnt_tcodes-userid = lt_crittcodes-bname.
    lt_cnt_tcodes-tcode  = lt_crittcodes-funid.
    lt_cnt_tcodes-vrsio  = vrsio.
    APPEND lt_cnt_tcodes.
  ENDLOOP.
  FREE : lt_crittcodes.



*Any records left in lt_cntuser are users that were in the central
*repository, but no longer exist.
  MESSAGE s002(/psyng/sw) WITH 'Updating Central Repository'
  rfcs.
  COMMIT WORK.
*--Get total nr of users
data : l_users type i.
select count(*) into l_users from usr02.
*--Update central repository on central system
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
  CALL FUNCTION '/PSYNG/SW_110' DESTINATION rfcs
    EXPORTING
      i_sysid          = sy-sysid
      i_mandt          = sy-mandt
      i_vrsio          = vrsio
      i_sod            = sod
      i_ca             = ca
      i_ct             = tc
      i_totalusercount = l_users
    TABLES
      it_users         = lt_cntuser_updated
      it_deleted       = lt_cntuser
      it_changed_users = lt_cntuser_analyzed
      it_functions     = lt_cnt_functions
      it_critauths     = lt_cnt_critauths
      it_crittcodes    = lt_cnt_tcodes
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
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






*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob.
  DATA: lt_params TYPE rsparams OCCURS 0 WITH HEADER LINE.


  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab TABLES lt_params.
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
    IF init = 'X'.
      l_jobname = 'Init Central User Directory'(j01).
    ELSE.
      l_jobname = 'Update Central User Directory'(j02).
    ENDIF.
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

*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

  SELECT  variant INTO variant FROM varid

  WHERE report = sy-repid   AND
        variant LIKE '/PSYNG/%' AND NOT
        variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    oldnumber = variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
  ENDIF.

  vari_desc-report = sy-repid.
  vari_desc-variant = variant.
  APPEND vari_desc.

ENDFORM.                    " get_next_variant_id

*---------------------------------------------------------------------*
*       FORM fill_sel_screen_fields_to_tab                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_PARAMS                                                     *
*---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab
TABLES et_params STRUCTURE rsparams .
  REFRESH : et_params[].
*Parameters
  et_params-selname = 'INIT'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = init.
  APPEND et_params.

  et_params-selname = 'UPDAT'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = updat.
  APPEND et_params.

  et_params-selname = 'SOD'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = sod.
  APPEND et_params.

  et_params-selname = 'CA'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = ca.
  APPEND et_params.

  et_params-selname = 'TC'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = TC.
  APPEND et_params.


  et_params-selname = 'ACTIVE'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = active.
  APPEND et_params.

  et_params-selname = 'VRSIO'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = vrsio.
  APPEND et_params.

  et_params-selname = 'RFCS'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = rfcs.
  APPEND et_params.

  et_params-selname = 'WP'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = wp.
  APPEND et_params.


  et_params-selname = 'PSERVER'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = pserver.
  APPEND et_params.

  et_params-selname = 'PGROUP'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = pgroup.
  APPEND et_params.

  et_params-selname = 'UPP'. et_params-kind = 'P'.
  et_params-sign = 'I'. et_params-option = 'EQ'.
  et_params-low = upp.
  APPEND et_params.


  et_params-selname = 'BNAME'. et_params-kind = 'S'.
  LOOP AT bname.
    et_params-sign   = bname-sign.
    et_params-option = bname-option.
    et_params-low    = bname-low.
    et_params-high   = bname-high.
    APPEND et_params.
  ENDLOOP.
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
*--Check paralell processing info
  IF specsrv = 'X'.
    CLEAR pgroup.
  ENDIF.
  IF specgrp = 'X'.
    CLEAR pserver.
  ENDIF.
  IF defgrp = 'X'.
    CLEAR : pgroup, pserver.
  ENDIF.
  DATA : l_req_wp TYPE num1.
  l_req_wp = wp.
        CALL FUNCTION '/PSYNG/BASIS_RFC_CHECK'
             EXPORTING
                  i_pserver = pserver
                  i_group   = pgroup
                  i_no_msg  = 'X'
             CHANGING
                  wp        = wp
"(++)BOC UMITTAL SE VF scan-25/11/2024.
            EXCEPTIONS
               USE_GROUP_OR_SERVER = 1
               OTHERS = 2.
     IF sy-subrc <> 0.
             MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                     WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
         ENDIF.

"(++)EOC UMITTAL SE VF scan-25/11/2024.
  IF l_req_wp > wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE w398(00) WITH text-091 wp text-092.
  ENDIF.
  IF sy-ucomm = 'GPSV'.
    PERFORM get_server_name.
  ENDIF.
  IF wp GT max_wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE e208(00) WITH text-031.
  ENDIF.
  PERFORM check_server_is_valid.

ENDFORM.                    " check_input

*---------------------------------------------------------------------*
*       FORM check_server_is_valid                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM check_server_is_valid.
  DATA: ilist TYPE STANDARD TABLE OF msxxlist WITH HEADER LINE.
  DATA: srvexist, messagetxt(80).

  CHECK NOT pserver IS INITIAL.
  CALL FUNCTION 'TH_SERVER_LIST'
*   EXPORTING
*     SERVICES             = 255
    TABLES
      list                 = ilist
   EXCEPTIONS
     no_server_list       = 1
     OTHERS               = 2.

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  LOOP AT ilist.
    CHECK ilist-name = pserver.
    srvexist = 'Y'.
  ENDLOOP.
  CONCATENATE text-065 pserver text-066
              INTO messagetxt SEPARATED BY space.
  IF srvexist IS INITIAL.
    SET CURSOR FIELD 'PSERVER'.
    MESSAGE e208(00) WITH messagetxt.
  ENDIF.
ENDFORM.                    " check_server_is_valid
*---------------------------------------------------------------------*
*       FORM get_server_name                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
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
  specsrv = 'X'.
  CLEAR : specgrp , defgrp.
ENDFORM.                    " get_server_name
*&---------------------------------------------------------------------*
*&      Form  analyze_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_CNTUSER  text
*      -->P_LT_MODIFIED_USERS  text
*----------------------------------------------------------------------*
FORM analyze_users_sod TABLES it_cntuser STRUCTURE /psyng/sw_cntusv
                             it_modified_users STRUCTURE ush02
                             et_functions STRUCTURE /psyng/sw_output_org
                   USING     if_init.

  DATA : lt_conflicts    TYPE TABLE OF /psyng/conflict,
         lt_confdet      TYPE TABLE OF /psyng/confdet,
         lt_functtran    TYPE TABLE OF /psyng/functtran,
         lt_faobj        TYPE TABLE OF /psyng/faobj2,
         lt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
             WITH HEADER LINE.


*--Run Function analysis on users in lt_modified_users
*Read sod Matrix
*--No enhancement or org specific options users for now
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
  CALL FUNCTION '/PSYNG/SW_READ_SOD_MATRIX_ORG' DESTINATION rfcs
   EXPORTING
     vrsio                    = vrsio
   TABLES
     conflict_fm              = lt_conflicts
     confdet_fm               = lt_confdet
     functtran_fm             = lt_functtran
     faobj_fm                 = lt_faobj
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
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

*--Convert user list to range
  REFRESH: lt_user_range.
  lt_user_range-sign   = 'I'.
  lt_user_range-option = 'EQ'.
  LOOP AT lt_modified_users.
*--Check if modified since last SOD check
    READ TABLE  it_cntuser
    WITH KEY userid = lt_modified_users-bname.
    IF
       if_init = 'X'  "first time
       OR
       (
         sy-subrc = 0 AND
         (
           it_cntuser-sod_date < lt_modified_users-modda
           OR
           (
             it_cntuser-sod_date = lt_modified_users-modda AND
             it_cntuser-sod_time < lt_modified_users-modti
            )
          )
      ).
      lt_user_range-low = lt_modified_users-bname.

      APPEND lt_user_range.
      MOVE-CORRESPONDING lt_modified_users TO lt_cntuser_analyzed.
      lt_cntuser_analyzed-userid = lt_modified_users-bname.
      APPEND lt_cntuser_analyzed.
    ENDIF.
  ENDLOOP.
*--Function analysis
  describe table lt_user_range lines l_num_changed.
  IF NOT lt_user_range[] IS INITIAL.
    DESCRIBE TABLE lt_user_range LINES l_num_changed.
    MESSAGE s002(/psyng/sw) WITH
    'SOD analysis started for'(i04)
    l_num_changed
    'users'(i03).

    COMMIT WORK.
    CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
     EXPORTING
       i_vrsio                     = vrsio
*     I_ENH                       =
*     I_ORG_CHECK                 =
       i_wp                        = wp
*     I_VALIDUSER                 =
       i_allug                     = 'X'
*     I_XSTB_FM                   = 'X'
       i_pserver                   = pserver
*     I_HIENH                     = ' '
       i_group                     = pgroup
       i_max_upp                   = upp
*     I_LOCUSR                    = ' '
*     I_ADVANCED_ROLE_SIMU        = ' '
*     I_REMOTE_ONLY               = ''
*     I_ER_ROLES                  = ''
*     I_EXCLUDE_ER_ROLES          = ''
*     I_LEVEL_2                   = ''
*     I_LEVEL_2_START             =
*     I_LEVEL_2_END               =
*     I_LEVEL_3                   = ''
*     I_LEVEL_3_START             =
*     I_LEVEL_3_END               =
*     I_LEVEL_3_CHANGEDOCS        = 'X'
*     I_LEVEL_3_TABLOG            = 'X'
*     I_LEVEL_3_DETAILS           = ''
*   IMPORTING
*     E_USERCOUNT                 =
*     E_SERVERNAME                =
     TABLES
       it_users                    = lt_user_range
*     IT_USERGROUP                =
*     IT_CONFS                    =
*     IT_USER_RFC                 =
*     IT_SIMU_ROLE_RFC            =
*     IT_SIMU_PROFILE_RFC         =
*     ET_RETURN                   =
*     ET_ENH_FUN                  =
       et_output                   = et_functions
*     ET_UNIQUE_USERS             =
*     IT_TCODES                   =
*     ET_ALLUSERS                 =
       it_conflict                 = lt_conflicts
       it_confdet                  = lt_confdet
       it_functtran                = lt_functtran
       it_faobj                    = lt_faobj
*     IT_SWSODORGM                =
*     IT_FUNCTRAN_NO_ENH          =
*     IT_RISK                     =
*     IT_UINFO                    =
*     IT_ADVANCED_ROLE_SIMU       =
*     IT_SIMU_ROLE_REMOVAL        =
*     ET_SIMU_REMOVED_ROLES       =
*     IT_SIMU_ADD_ROLETCODE       =
*     IT_SIMU_ADD_ROLEAUTH        =
*     ET_LEVEL3_DETAILS           =
    .
  ENDIF.

  MESSAGE s002(/psyng/sw) WITH
  'SOD analysis completed'(i05).
  COMMIT WORK.

ENDFORM.                    " analyze_users


*---------------------------------------------------------------------*
*       FORM analyze_users_ca                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_CNTUSER                                                    *
*  -->  IT_MODIFIED_USERS                                             *
*  -->  ET_CRITAUTHS                                                  *
*  -->  IF_INIT                                                       *
*---------------------------------------------------------------------*
FORM analyze_users_ca TABLES it_cntuser STRUCTURE /psyng/sw_cntusv
                             it_modified_users STRUCTURE ush02
                             et_critauths STRUCTURE /psyng/sw_output_org
                   USING     if_init.

  DATA : lt_conflicts    TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
        lt_confdet      TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_faobj        TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_swaudhdr     TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
        lt_swaudc       TYPE TABLE OF /psyng/swaudc2 WITH HEADER LINE,
        lt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
            WITH HEADER LINE.
  DATA : l_numtcodes TYPE i.
  FIELD-SYMBOLS : <swaudc> TYPE /psyng/swaudc2.


*--Run CA analysis on users in lt_modified_users
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
  CALL FUNCTION '/PSYNG/SW_READ_ALL_CA_DETAILS' DESTINATION rfcs
   EXPORTING
     vrsio                            = vrsio
   TABLES
     swaudc_fm                        = lt_swaudc
     swaudhdr_fm                      = lt_swaudhdr
   EXCEPTIONS
     SYSTEM_FAILURE = 1
     COMMUNICATION_FAILURE = 2
     not_authorized_to_read_all       = 3
     OTHERS                           = 4."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc <> 0.
    MESSAGE e108(/psyng/sw) WITH 'read critical auths on'(e01) rfcs.
  ENDIF.
  check not lt_swaudhdr[] is initial.
*--Convert Critical Auths to functions
*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.
  LOOP AT lt_swaudhdr.
    lt_conflicts-conid       = lt_swaudhdr-swaudid.
    APPEND lt_conflicts.
    lt_confdet-conid        = lt_swaudhdr-swaudid.
    lt_confdet-functionid   = lt_swaudhdr-swaudid.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_swaudhdr-swaudid.
    IF lt_swaudhdr-tcode = '*'.
*--Case 2975 : Improve performance when tcode = * and
*              exactly 1 tcode is in
*              the critical authorization.
      l_numtcodes = 0.
      LOOP AT lt_swaudc WHERE
                               swaudid = lt_swaudhdr-swaudid AND
                               object  = 'S_TCODE' AND
                               field   = 'TCD' AND
                               val_to  = ''.
        IF lt_swaudc-val_from NS '*'.
          ADD 1 TO l_numtcodes.
          lt_functtran-tcode = lt_swaudc-val_from.
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
      lt_functtran-tcode    = lt_swaudhdr-tcode.
*--Also update the details
      LOOP AT lt_swaudc ASSIGNING <swaudc>
                               WHERE
                               swaudid = lt_swaudhdr-swaudid.
        <swaudc>-tcode =  lt_swaudhdr-tcode.
      ENDLOOP.
    ENDIF.
    APPEND lt_functtran.
    LOOP AT lt_swaudc WHERE swaudid = lt_swaudhdr-swaudid.
      MOVE-CORRESPONDING lt_swaudc TO lt_faobj.
*--Case 2975 : Improve performance by converting ranges where
*              high = low
*              to exact values.
      IF lt_faobj-val_from = lt_faobj-val_to.
        CLEAR lt_faobj-val_to.
      ENDIF.
      lt_faobj-funid = lt_functtran-functionid.
      lt_faobj-tcode = lt_functtran-tcode.
      APPEND lt_faobj.
    ENDLOOP.
  ENDLOOP.



*--Convert user list to range
  REFRESH: lt_user_range.
  lt_user_range-sign   = 'I'.
  lt_user_range-option = 'EQ'.
  LOOP AT lt_modified_users.
*--Check if modified since last SOD check
    READ TABLE  it_cntuser
    WITH KEY userid = lt_modified_users-bname.
    IF
       if_init = 'X'  "first time
       OR
       (
         sy-subrc = 0 AND
         (
           it_cntuser-ca_date < lt_modified_users-modda
           OR
           (
             it_cntuser-ca_date = lt_modified_users-modda AND
             it_cntuser-ca_time < lt_modified_users-modti
            )
          )
      ).
      lt_user_range-low = lt_modified_users-bname.

      APPEND lt_user_range.
      MOVE-CORRESPONDING lt_modified_users TO lt_cntuser_analyzed.
      lt_cntuser_analyzed-userid = lt_modified_users-bname.
      APPEND lt_cntuser_analyzed.
    ENDIF.
  ENDLOOP.
*--Critical Auth analysis
  describe table lt_user_range lines l_num_changed.

  IF NOT lt_user_range[] IS INITIAL.
    DESCRIBE TABLE lt_user_range LINES l_num_changed.
    MESSAGE s002(/psyng/sw) WITH
    'Critical Authorization analysis started for'(i07)
    l_num_changed
    'users'(i03).

    COMMIT WORK.
    CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
     EXPORTING
       i_vrsio                     = vrsio
*     I_ENH                       =
*     I_ORG_CHECK                 =
       i_wp                        = wp
*     I_VALIDUSER                 =
       i_allug                     = 'X'
*     I_XSTB_FM                   = 'X'
       i_pserver                   = pserver
*     I_HIENH                     = ' '
       i_group                     = pgroup
       i_max_upp                   = upp
*     I_LOCUSR                    = ' '
*     I_ADVANCED_ROLE_SIMU        = ' '
*     I_REMOTE_ONLY               = ''
*     I_ER_ROLES                  = ''
*     I_EXCLUDE_ER_ROLES          = ''
*     I_LEVEL_2                   = ''
*     I_LEVEL_2_START             =
*     I_LEVEL_2_END               =
*     I_LEVEL_3                   = ''
*     I_LEVEL_3_START             =
*     I_LEVEL_3_END               =
*     I_LEVEL_3_CHANGEDOCS        = 'X'
*     I_LEVEL_3_TABLOG            = 'X'
*     I_LEVEL_3_DETAILS           = ''
*   IMPORTING
*     E_USERCOUNT                 =
*     E_SERVERNAME                =
     TABLES
       it_users                    = lt_user_range
*     IT_USERGROUP                =
*     IT_CONFS                    =
*     IT_USER_RFC                 =
*     IT_SIMU_ROLE_RFC            =
*     IT_SIMU_PROFILE_RFC         =
*     ET_RETURN                   =
*     ET_ENH_FUN                  =
       et_output                   = et_critauths
*     ET_UNIQUE_USERS             =
*     IT_TCODES                   =
*     ET_ALLUSERS                 =
       it_conflict                 = lt_conflicts
       it_confdet                  = lt_confdet
       it_functtran                = lt_functtran
       it_faobj                    = lt_faobj
*     IT_SWSODORGM                =
*     IT_FUNCTRAN_NO_ENH          =
*     IT_RISK                     =
*     IT_UINFO                    =
*     IT_ADVANCED_ROLE_SIMU       =
*     IT_SIMU_ROLE_REMOVAL        =
*     ET_SIMU_REMOVED_ROLES       =
*     IT_SIMU_ADD_ROLETCODE       =
*     IT_SIMU_ADD_ROLEAUTH        =
*     ET_LEVEL3_DETAILS           =
    .
  ENDIF.
  MESSAGE s002(/psyng/sw) WITH
  'Critical Authorization analysis completed'(i06).
  COMMIT WORK.
ENDFORM.                    " analyze_users



*---------------------------------------------------------------------*
*       FORM analyze_users_ct                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_CNTUSER                                                    *
*  -->  IT_MODIFIED_USERS                                             *
*  -->  ET_CRITTCODES                                                 *
*  -->  IF_INIT                                                       *
*---------------------------------------------------------------------*
FORM analyze_users_ct TABLES it_cntuser STRUCTURE /psyng/sw_cntusv
                            it_modified_users STRUCTURE ush02
                            et_crittcodes STRUCTURE /psyng/sw_output_org
                   USING    if_init.

  DATA : lt_conflicts   TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
        lt_confdet      TYPE TABLE OF /psyng/confdet WITH HEADER LINE,
        lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
        lt_faobj        TYPE TABLE OF /psyng/faobj2 WITH HEADER LINE,
        lt_tcodes       TYPE TABLE OF /psyng/critcodes WITH HEADER LINE,
        lt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
            WITH HEADER LINE.
  DATA : l_numtcodes TYPE i.
  FIELD-SYMBOLS : <swaudc> TYPE /psyng/swaudc2.


*--Run Critical Tcode analysis on users in lt_modified_users
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
  CALL FUNCTION '/PSYNG/SW_CR_READ_CRI_TCODES' DESTINATION rfcs
   EXPORTING
     i_vrsio                         = vrsio
    TABLES
      critcodes                      = lt_tcodes
   EXCEPTIONS
     SYSTEM_FAILURE = 1
     COMMUNICATION_FAILURE = 2
     not_authorized_to_display       = 3
     OTHERS                          = 4."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc <> 0.
 MESSAGE e108(/psyng/sw) WITH 'read Critical Transactions on'(e02) rfcs.
  ENDIF.
  check not lt_tcodes[] is initial.

*--Convert Critical tcodes to functions
*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.
  LOOP AT lt_tcodes.
    lt_conflicts-conid       = lt_tcodes-tcode.
    APPEND lt_conflicts.
    lt_confdet-conid        = lt_tcodes-tcode.
    lt_confdet-functionid   = lt_tcodes-tcode.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_tcodes-tcode.
    lt_functtran-tcode      = lt_tcodes-tcode.
    APPEND lt_functtran.
  ENDLOOP.

*--Convert user list to range
  REFRESH: lt_user_range.
  lt_user_range-sign   = 'I'.
  lt_user_range-option = 'EQ'.
  LOOP AT lt_modified_users.
*--Check if modified since last SOD check
    READ TABLE  it_cntuser
    WITH KEY userid = lt_modified_users-bname.
    IF
       if_init = 'X'  "first time
       OR
       (
         sy-subrc = 0 AND
         (
           it_cntuser-ct_date < lt_modified_users-modda
           OR
           (
             it_cntuser-ct_date = lt_modified_users-modda AND
             it_cntuser-ct_time < lt_modified_users-modti
            )
          )
      ).
      lt_user_range-low = lt_modified_users-bname.

      APPEND lt_user_range.
      MOVE-CORRESPONDING lt_modified_users TO lt_cntuser_analyzed.
      lt_cntuser_analyzed-userid = lt_modified_users-bname.
      APPEND lt_cntuser_analyzed.
    ENDIF.
  ENDLOOP.
*--Transaction analysis
  IF NOT lt_user_range[] IS INITIAL.
    DESCRIBE TABLE lt_user_range LINES l_num_changed.
    MESSAGE s002(/psyng/sw) WITH
    'Critical Transaction analysis started for'(i02)
    l_num_changed
    'users'(i03).
    COMMIT WORK.
    CALL FUNCTION '/PSYNG/SW_FUNC_SCAN'
     EXPORTING
       i_vrsio                     = vrsio
*     I_ENH                       =
*     I_ORG_CHECK                 =
       i_wp                        = wp
*     I_VALIDUSER                 =
       i_allug                     = 'X'
*     I_XSTB_FM                   = 'X'
       i_pserver                   = pserver
*     I_HIENH                     = ' '
       i_group                     = pgroup
       i_max_upp                   = upp
*     I_LOCUSR                    = ' '
*     I_ADVANCED_ROLE_SIMU        = ' '
*     I_REMOTE_ONLY               = ''
*     I_ER_ROLES                  = ''
*     I_EXCLUDE_ER_ROLES          = ''
*     I_LEVEL_2                   = ''
*     I_LEVEL_2_START             =
*     I_LEVEL_2_END               =
*     I_LEVEL_3                   = ''
*     I_LEVEL_3_START             =
*     I_LEVEL_3_END               =
*     I_LEVEL_3_CHANGEDOCS        = 'X'
*     I_LEVEL_3_TABLOG            = 'X'
*     I_LEVEL_3_DETAILS           = ''
*   IMPORTING
*     E_USERCOUNT                 =
*     E_SERVERNAME                =
     TABLES
       it_users                    = lt_user_range
*     IT_USERGROUP                =
*     IT_CONFS                    =
*     IT_USER_RFC                 =
*     IT_SIMU_ROLE_RFC            =
*     IT_SIMU_PROFILE_RFC         =
*     ET_RETURN                   =
*     ET_ENH_FUN                  =
       et_output                   = et_crittcodes
*     ET_UNIQUE_USERS             =
*     IT_TCODES                   =
*     ET_ALLUSERS                 =
       it_conflict                 = lt_conflicts
       it_confdet                  = lt_confdet
       it_functtran                = lt_functtran
       it_faobj                    = lt_faobj
*     IT_SWSODORGM                =
*     IT_FUNCTRAN_NO_ENH          =
*     IT_RISK                     =
*     IT_UINFO                    =
*     IT_ADVANCED_ROLE_SIMU       =
*     IT_SIMU_ROLE_REMOVAL        =
*     ET_SIMU_REMOVED_ROLES       =
*     IT_SIMU_ADD_ROLETCODE       =
*     IT_SIMU_ADD_ROLEAUTH        =
*     ET_LEVEL3_DETAILS           =
    .
  ENDIF.
  MESSAGE s002(/psyng/sw) WITH
  'Critical Transaction analysis done'(i01).
  COMMIT WORK.

ENDFORM.                    " analyze_users
