*----------------------------------------------------------------------*
* Report  /PSYNG/SW_056                                                *
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
REPORT /psyng/sw_056 LINE-SIZE 170 message-id /psyng/sw.
*Odubey 23.01.2024 Siemens energy requist
*CONSTANTS : g_sod_vrsio TYPE /psyng/sodvrsio VALUE '000'.
*end
DATA: usercount TYPE i,    "Progress indicator flag
      exit_proc,
      chksm TYPE i,
      g_sod_vrsio TYPE /psyng/sodvrsio,
      gt_are TYPE TABLE OF /PSYNG/RANGE_APPL,
      gt_conid type table of /psyng/sw_sel_opts_conid.
DATA : seldone TYPE flag VALUE ' '.

DATA: curr_report LIKE  rsvar-report,
      curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: ivarit TYPE varit OCCURS 0 WITH HEADER LINE.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.

DATA: max_wp TYPE i VALUE '4'.
*DATA : ta_output TYPE TABLE OF /psyng/1stoutput_u,
*       ta_output_enh TYPE TABLE OF /psyng/1stoutput_u,
*       wa_output TYPE /psyng/1stoutput_u,
DATA : ta_output TYPE TABLE OF /psyng/sw_sod_output_org,
       ta_output_enh TYPE TABLE OF /psyng/sw_sod_output_org,
       ta_output_origin TYPE TABLE OF /psyng/sw_sod_output_org
       with header line,
       ta_output_no_er TYPE TABLE OF /psyng/sw_sod_output_org,
       wa_output TYPE /psyng/sw_sod_output_org,
        wa_return TYPE bapireturn,
       ta_conflicts TYPE TABLE OF /psyng/conflict,
       ta_swcuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
       ta_areas TYPE TABLE OF /psyng/busarea,
       count_conflicts_all TYPE i,
       count_users_with_conf TYPE i,
       count_con TYPE i.
DATA : BEGIN OF area_details,
      busarea TYPE /psyng/busarea-busarea,
      usercount TYPE i,
      count_inc_all TYPE i,
      avg TYPE p DECIMALS 2,
      END OF area_details.
DATA : BEGIN OF con_details,
      busarea TYPE /psyng/busarea-busarea,
      conid TYPE /psyng/conflict_id,
      count_inc_all TYPE i,
      perc TYPE p DECIMALS 2,
      END OF con_details.
DATA : wa_area LIKE LINE OF ta_areas,
       wa_conflict LIKE LINE OF ta_conflicts,
       wa_cuscon LIKE LINE OF ta_swcuscon.

DATA : ta_con_details LIKE TABLE OF con_details,
       ta_area_details LIKE TABLE OF area_details,
       begin of gt_remote occurs 0,
         system type rfcdest,
         rfcdest type rfcdest,
         index   type i,
       end of gt_remote,
       g_cfg_ustb type flag,
       g_cfg_locusr type flag.
ranges : gr_range_rfc for rfcdes-rfcdest.
DATA : ls_rfcdes TYPE rfcdes-rfcdest.
SELECTION-SCREEN: BEGIN OF BLOCK sblk WITH FRAME TITLE text-016.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(20) text-017.

PARAMETERS: sysid TYPE sysysid DEFAULT sy-sysid.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(35) text-018.
PARAMETERS: grocman(40) TYPE c .
SELECTION-SCREEN: END OF LINE.
SKIP 1.

************************************
*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : COMMENT 3(20) text-019.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_01(10) TYPE c OBLIGATORY .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_02(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_03(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_04(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : COMMENT 3(22) text-019.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_01(10) TYPE c OBLIGATORY .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_02(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_03(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_04(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_05(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_06(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_07(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_08(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_05(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_06(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_07(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_08(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_09(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_10(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_11(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_12(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_09(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_10(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_11(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_12(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_13(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_14(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_15(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_16(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_13(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_14(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_15(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_16(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************
*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_17(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_18(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_19(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_20(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_17(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_18(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_19(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_20(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_21(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_22(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_23(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_24(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_21(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_22(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_23(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_24(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_25(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_26(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_27(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_28(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_25(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_26(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_27(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_28(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_29(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_30(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_31(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_32(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_29(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_30(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_31(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_32(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************

*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_33(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_34(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_35(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_36(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_33(10) TYPE c .
SELECTION-SCREEN : POSITION 41 .
PARAMETERS: are_34(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_35(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_36(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************
*SELECTION-SCREEN:BEGIN OF LINE.
*SELECTION-SCREEN : POSITION 24  .
*PARAMETERS: are_37(10) TYPE c .
*SELECTION-SCREEN : POSITION 39  .
*PARAMETERS: are_38(10) TYPE c .
*SELECTION-SCREEN : POSITION 54  .
*PARAMETERS: are_39(10) TYPE c .
*SELECTION-SCREEN : POSITION 69  .
*PARAMETERS: are_40(10) TYPE c .
*SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN : POSITION 26  .
PARAMETERS: are_37(10) TYPE c .
SELECTION-SCREEN : POSITION 41  .
PARAMETERS: are_38(10) TYPE c .
SELECTION-SCREEN : POSITION 56  .
PARAMETERS: are_39(10) TYPE c .
SELECTION-SCREEN : POSITION 71  .
PARAMETERS: are_40(10) TYPE c .
SELECTION-SCREEN: END OF LINE.
************************************
SELECTION-SCREEN: END OF BLOCK sblk .







SELECTION-SCREEN: BEGIN OF BLOCK pblk WITH FRAME TITLE text-001.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: wp(1) TYPE n DEFAULT '0'.
SELECTION-SCREEN: COMMENT 3(65) text-002.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 2(15) text-003.
SELECTION-SCREEN: COMMENT 3(15) text-003.
PARAMETERS: pserver LIKE msxxlist-name. "server name (40 chars in 4.7)
*SELECTION-SCREEN PUSHBUTTON  60(16) text-004 USER-COMMAND gpsv.
SELECTION-SCREEN PUSHBUTTON  60(17) text-004 USER-COMMAND gpsv.
SELECTION-SCREEN: END OF LINE.
SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 2(35) text-123.
SELECTION-SCREEN: COMMENT 3(35) text-123.
PARAMETERS : maxusers TYPE i DEFAULT '0'."conf_maxusers.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: SKIP 1.
*** SF Case 3825 Begin of Change HS
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS : p_locusr AS CHECKBOX          MODIF ID rem.
SELECTION-SCREEN COMMENT 3(45) text-162 FOR FIELD p_locusr
                                           MODIF ID rem.
SELECTION-SCREEN END OF LINE.
*** End of change
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: ustb AS CHECKBOX DEFAULT ' '. "update SCAN table
SELECTION-SCREEN: COMMENT 3(40) text-005.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK pblk.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK rem WITH FRAME TITLE text-124.
select-options : xusrrfc for ls_rfcdes MATCHCODE OBJECT /psyng/sw_rfcsh
no intervals
.
SELECTION-SCREEN: END OF BLOCK rem.


SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-011.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-012.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-013.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-014 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-015 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.


INITIALIZATION.
  PERFORM exelog.
  PERFORM get_initial_config.
  PERFORM get_max_nr_users_config CHANGING maxusers.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR pserver.
  PERFORM disp_total_servers_for_sel.

AT SELECTION-SCREEN OUTPUT.
*SE4.0PS1e - make this editable, but during analysis use all
* configured values anyway, also ignore any values from variants
* or user entry and always revert back to configuration
  perform populate_rfcs.
  LOOP AT SCREEN.
    CHECK screen-name CS 'P_LOCUSR' or
          screen-name CS 'USTB'.
    screen-input = 0.
    MODIFY SCREEN.
  ENDLOOP.


AT SELECTION-SCREEN.
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
*SE4.0PS1e - during analysis use all
* configured values anyway, also ignore any values from variants
* or user entry and always revert back to configuration
IF exit_proc <> 'Y'."(++)HBHALLA(PN-18406)(Issue7)(11/05/26)
  gr_range_rfc[] = xusrrfc[].
  perform populate_rfcs.
  if not gr_range_rfc[] = xusrrfc[].
      MESSAGE S113(/psyng/sw) WITH
      'RFC destination not equal to configured value in'(e03)
      'parameters SW_056_RFC_DEST*'(e04).
      MESSAGE S113(/psyng/sw) WITH
      'Configured values are used for analysis'(e05).
  endif.
*Begin of Addition:HBHALLA(PN-18406)(Issue3)(06/05/26)
 IF NOT xusrrfc[] IS INITIAL.
    MESSAGE S113(/psyng/sw) WITH 'RFC Destinations Used:'(e06).
 ENDIF.
*End of Addition:HBHALLA(PN-18406)(Issue3)(06/05/26)
  loop at xusrrfc.
    MESSAGE S113(/psyng/sw) WITH xusrrfc-low.
  endloop.
*SE4.0PS1e - during analysis use the configured values for
* local users only and fill scan table
  if g_cfg_locusr <> p_locusr.
      MESSAGE S113(/psyng/sw) WITH
      'Only analyze users that exist in local system'(e07)
      'not equal to configured value in DFLT_LOCAL_USR'(e08).
      MESSAGE S113(/psyng/sw) WITH
      'Configured values are used for analysis'(e05).
      p_locusr = g_cfg_locusr.
  endif.
   if g_cfg_ustb <> ustb.
      MESSAGE S113(/psyng/sw) WITH
      'Update Scan Table'(e11)
      'not equal to configured value in DFLT_UPD_SCAN_TBL'(e09).
      MESSAGE S113(/psyng/sw) WITH
      'Configured values are used for analysis'(e05).
      ustb = g_cfg_ustb.
  endif.
ENDIF."(++)HBHALLA(PN-18406)(Issue7)(11/05/26)

**--Validate if RFC destination is what is configured.
*  DATA: swconfig TYPE /psyng/swconfig.
*   loop at xusrrfc.
*     read table gt_remote with key rfcdest = xusrrfc-low
*     transporting no fields.
*     if sy-subrc <> 0.
*      MESSAGE e113(/psyng/sw) WITH
*      'RFC destination not equal to configured value in'(e03)
*      'parameters SW_056_RFC_DEST*'(e04).
*     endif.
*   endloop.
  DATA : program LIKE sy-repid.
  program = sy-repid .
  IF exit_proc = 'Y'.
    SUBMIT (program) "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Program name is variable so it can’t be fixed.(12/12/24)
           VIA SELECTION-SCREEN
           USING SELECTION-SET curr_variant .
  ENDIF.
  IF seldone IS INITIAL.
    PERFORM data_selection.
    seldone = 'X'.
  ENDIF.


  ta_output[] =   ta_output_enh[].
*calculate data for standard ruleset
  PERFORM do_calculation        USING 'X'.
  PERFORM chksm CHANGING chksm.
*Display data for enhanced ruleset
  PERFORM write_header_to_screen USING 'X'.
  PERFORM write_output_to_screen USING 'X'.
  PERFORM write_are_to_screen.
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user."sy-uname. C0700
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
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_initial_config.
  DATA: swconfig TYPE table of /psyng/swconfig with header line,
        lt_rfcdes TYPE TABLE OF rfcdes,
        l_rfctest TYPE rfctest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_len type i,
        l_str type string,
        l_param type /PSYNG/PARAM,
        l_CONFIG type /PSYNG/SE_CONFIG_PARAM.

*  begin of Odubey 23.01.2024
l_param = 'DFLT_GLOBAL_VERSION'.
CALL FUNCTION '/PSYNG/SW_GET_CONFIG'
 EXPORTING
   I_PARAMETER        = l_param
 IMPORTING
   E_CONFIG           = l_CONFIG.
g_sod_vrsio = l_config-value.

*  end
*Update Scan Table
  SELECT SINGLE * FROM /psyng/swconfig INTO swconfig WHERE
         param = 'DFLT_UPD_SCAN_TBL'.
  IF swconfig-value = 'Y'.
    ustb = 'X'.
  ELSEIF swconfig-value = 'N'.
    ustb = ' '.
  ENDIF.
  g_cfg_ustb = ustb.
*Only analyze local users in cross system analysis
  CLEAR swconfig.
  SELECT SINGLE * FROM /psyng/swconfig INTO swconfig WHERE
         param = 'DFLT_LOCAL_USR'.
  IF swconfig-value = 'Y'.
    p_locusr = 'X'.
  ELSE.
    p_locusr = ' '.
  ENDIF.
  g_cfg_locusr = p_locusr.

  CLEAR swconfig.
  perform populate_rfcs.
ENDFORM.                    " get_initial_config
*&---------------------------------------------------------------------*
*&      Form  disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM disp_total_servers_for_sel.
  DATA: title(20).
  DATA btchost LIKE msxxlist-host.
  title = 'Choose a server'(125).
  CALL FUNCTION 'SLWY_SELECT_BTC_SERVER'
    EXPORTING
      select_title         = title
    CHANGING
      btc_host             = btchost
      btc_server           = pserver
    EXCEPTIONS
      no_server_list       = 1
      wrong_host           = 2
      wrong_choice         = 3
      OTHERS               = 4.
  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    " disp_total_servers_for_sel
*&---------------------------------------------------------------------*
*&      Form  check_input
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_input.
  IF sy-ucomm = 'SM37'.
    AUTHORITY-CHECK OBJECT 'S_TCODE'
             ID 'TCD' FIELD 'SM37'.
    IF sy-subrc <> 0.
      MESSAGE e077(s#) WITH 'SM37'.
    ENDIF.

    CALL TRANSACTION 'SM37'.
  ENDIF.
  IF sy-ucomm = 'GPSV'.
    PERFORM get_server_name.
  ENDIF.
  IF wp GT max_wp.
    SET CURSOR FIELD 'WP'.
    MESSAGE e208(00) WITH 'Only 4 Parallel Processes allowed'(126).
  ENDIF.
  PERFORM check_server_is_valid.
  IF sy-ucomm = 'SCJB'.
    exit_proc = 'Y'.
    PERFORM schedule_back_job.
  ENDIF.


ENDFORM.                    " check_input
form populate_rfcs.
DATA: swconfig TYPE table of /psyng/swconfig with header line,
        lt_rfcdes TYPE TABLE OF rfcdes,
        l_rfctest TYPE rfctest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_len type i,
        l_str type string.

**Set RFC destination for remote SOD analysis
*  refresh xusrrfc. "(++)HBHALLA(PN-18406)(11/05/26)
  SELECT  * FROM /psyng/swconfig INTO table swconfig WHERE
         param like 'SW_056_RFC_DEST%' and
         value <> ''.
  loop at swconfig.
*  --Check if RFC destination is valid and reachable
      SELECT  * FROM rfcdes                          "#EC CI_NOORDER
      INTO CORRESPONDING FIELDS OF TABLE lt_rfcdes
      WHERE rfcdest = swconfig-value.
      IF sy-subrc = 0.
        CALL FUNCTION 'RFC_WALK_THRU_TEST'
        EXPORTING
          test_in            = l_rfctest
        TABLES
          destinations       = lt_rfcdes
          log                = lt_rfc_log.
        LOOP AT lt_rfc_log WHERE rfclog NE 'o.k.'.
          PERFORM report_rfc_error USING
          lt_rfc_log-rfcdest lt_rfc_log-rfclog.
        ENDLOOP.
        if sy-subrc <> 0.
          gt_remote-rfcdest = swconfig-value.
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
          CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
          destination  swconfig-value
           IMPORTING
           E_RFCDEST       = gt_remote-system. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

          l_str = swconfig-PARAM.
          condense l_str.
          l_len = strlen( l_str ).
          if  l_len ge 16.
            if l_str+16 co '0123456789'.
              move l_str+16 to gt_remote-index.
              subtract 1 from gt_remote-index.
            else.
              MESSAGE e113(/psyng/sw) WITH
              'Invalid Parameter Name : '
              l_str.
            endif.
          else.
            gt_remote-index = 0.
          endif.
          append gt_remote.
          xusrrfc-sign   = 'I'.
          xusrrfc-option = 'EQ'.
          xusrrfc-low    = swconfig-value.
          append xusrrfc.
        endif.
      ELSE.
        PERFORM report_rfc_error USING
        swconfig-value 'RFC destination does not exist'(e02).
      ENDIF.
  endloop.
  sort gt_remote by system .
  CLEAR swconfig.
  DELETE ADJACENT DUPLICATES FROM xusrrfc.
  "(++)HBHALLA(PN-18406)(11/05/26)

endform.
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
ENDFORM.                    " get_server_name
*&---------------------------------------------------------------------*
*&      Form  check_server_is_valid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM check_server_is_valid.
  DATA: ilist TYPE STANDARD TABLE OF msxxlist WITH HEADER LINE.
  DATA: srvexist, messagetxt(80).
  CHECK NOT pserver IS INITIAL.
  CALL FUNCTION 'TH_SERVER_LIST'
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
  CONCATENATE 'Server:'(127)
              pserver
              'does not exist; check name'(128)
              INTO messagetxt SEPARATED BY space.
  IF srvexist IS INITIAL.
    SET CURSOR FIELD 'PSERVER'.
    MESSAGE e208(00) WITH messagetxt.
  ENDIF.
  FREE : ilist,srvexist,messagetxt.
ENDFORM.                    " check_server_is_valid
*&---------------------------------------------------------------------*
*&      Form  schedule_back_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM schedule_back_job.
  DATA : l_jobname TYPE btcjob.
  CLEAR: curr_report, curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  curr_variant = variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report               = curr_report
            curr_variant              = curr_variant
            vari_desc                 = vari_desc
       TABLES
            vari_contents             = vari_contents
            vari_text                 = vari_text
       EXCEPTIONS
            illegal_report_or_variant = 1
            illegal_variantname       = 2
            not_authorized            = 3
            not_executed              = 4
            report_not_existent       = 5
            report_not_supplied       = 6
            variant_exists            = 7
            variant_locked            = 8.
  IF sy-subrc <> 0.
    MESSAGE w113(/psyng/sw) WITH 'Unable to create variant'(e10).
  ELSE.
    l_jobname = 'Security Weaver: Sys-Wide Scan'(129).
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = curr_variant
              in_report   = curr_report
         EXCEPTIONS
              OTHERS      = 1.
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
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: variant, ivarit, vari_desc.
  REFRESH: ivarit, vari_desc.

  SELECT variant INTO variant FROM varid WHERE report = sy-repid AND
                           variant LIKE '/PSYNG/%'
     order by variant DESCENDING.
    oldnumber = variant+7(7).
    exit.
  ENDSELECT.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO variant.
  ENDIF.

  ivarit-langu = sy-langu.
  ivarit-report = sy-repid.
  ivarit-variant = variant.
  ivarit-vtext = 'Dynamically created'(130).
  APPEND ivarit.

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
  REFRESH irsparams.
  DATA : validusr TYPE flag.
*Parameters
  irsparams-selname = 'VALIDUSR'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = validusr.
  APPEND irsparams.


  irsparams-selname = 'WP'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = wp.
  APPEND irsparams.

  irsparams-selname = 'USTB'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = ustb.
  APPEND irsparams.


  irsparams-selname = 'PSERVER'. irsparams-kind = 'P'.
  irsparams-sign = 'I'. irsparams-option = 'EQ'.
  irsparams-low = pserver.
  APPEND irsparams.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  count_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM count_users.
*Begin of Addition:HBHALLA(PN-18406)(Issue8)(12/05/26)
DATA: lt_remote TYPE TABLE OF usr02,
      lt_users TYPE TABLE OF usr02,
      temp_count TYPE i.

*  SELECT COUNT(*) INTO usercount FROM usr02 .
  SELECT bname INTO CORRESPONDING FIELDS OF
    TABLE lt_users FROM usr02.

  IF xusrrfc IS NOT INITIAL AND p_locusr <> 'X'.
   LOOP AT xusrrfc.
     CALL FUNCTION '/PSYNG/SW_041'
       DESTINATION xusrrfc-low
       EXPORTING
         i_validuser       = ' '
         i_include_locked  = 'X'
         i_include_expired = 'X'
       TABLES
         et_users          = lt_remote.
      APPEND LINES OF lt_remote[] TO lt_users[].
    ENDLOOP.

   SORT lt_users[] BY bname.
   DELETE ADJACENT DUPLICATES FROM lt_users[]
   COMPARING bname.
  ENDIF.
 DESCRIBE TABLE lt_users LINES usercount.
*End of Addition:HBHALLA(PN-18406)(Issue8)(12/05/26)
ENDFORM.                    " count_users
*&---------------------------------------------------------------------*
*&      Form  write_are_to_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM write_are_to_screen.
  FIELD-SYMBOLS <fs> TYPE c.
  DATA : are_name TYPE string,
         are_nr TYPE numc2,
         are_names TYPE string,
         column_nr TYPE i,
         label_printed TYPE flag.

  DO 40 TIMES.
    are_nr = are_nr + 1 .
    column_nr = column_nr + 1.
    CONCATENATE 'are_' are_nr INTO are_name.
    ASSIGN (are_name) TO <fs> ."#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(09/12/24)
    IF NOT <fs> IS  INITIAL.
      IF label_printed IS INITIAL.
        WRITE : /  text-019 , ':'.
        label_printed = 'X'.
      ENDIF.
      are_names = <fs> .
      PERFORM del_trailing_blanks CHANGING are_names.
      WRITE : /  are_names.
    ENDIF.
    IF column_nr = 4. column_nr = 0. ENDIF.
  ENDDO.


  FREE : are_name, are_nr, are_names, column_nr, label_printed.
ENDFORM.                    " write_are_to_screen
*&---------------------------------------------------------------------*
*&      Form  chksm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM chksm CHANGING chksm TYPE i.
  DATA : base TYPE i,
         area_sum TYPE i,
         multiplier_1 TYPE i VALUE   1709 ,
           multiplier_2 TYPE i VALUE   1061,
         multiplier_3 TYPE i VALUE   711,
         divider      TYPE i VALUE   577,
         concount     TYPE i.
  CLEAR : area_sum, chksm, base.

  LOOP AT ta_area_details INTO area_details.
    area_sum = area_sum + area_details-usercount.
  ENDLOOP.
  concount = count_con.

  base   = ( area_sum   * multiplier_1 )
         + ( usercount  * multiplier_2 )
         + ( concount   * multiplier_3 )  .
  chksm = base MOD divider.

  FREE : base ,area_sum,multiplier_1,multiplier_2,
         multiplier_3,divider ,concount.
ENDFORM.                    " chksm
*&---------------------------------------------------------------------*
*&      Form  data_selection
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_selection.

  FREE : ta_output[].
  DATA : xstb_fm TYPE flag,
         uname TYPE xubname,
         chunks TYPE i,
         counter TYPE i,
         ta_users TYPE TABLE OF usr02,
         wa_user TYPE usr02,
         ta_output_tmp LIKE ta_output,
         lt_rfcdest TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
         WITH HEADER LINE,
         lf_auth_failure type flag,
         lf_st_auth_failure type flag,
         l_local type rfcdest.
  RANGES : userids FOR uname.
  field-symbols : <output> type /psyng/sw_sod_output_org.
  DATA : wa_usersel LIKE LINE OF userids.
  FREE : lt_rfcdest.
  lt_rfcdest[] = xusrrfc[].
  IF ustb = 'X'.
    CLEAR xstb_fm.
  ELSE.
    xstb_fm = 'X'.
  ENDIF.
  PERFORM count_users.
  REFRESH : userids[].

  PERFORM areas."(++)HBHALLA(PN-18406)(11/05/26)

*--2016/06/07 - Collect all users that have ER roles currently assigned.
  data : lt_er_users type table of usr02 with header line,
         lt_er_users_h type  hashed table of usr02 with header line
         with unique key bname.
  perform collect_er_users tables lt_er_users.
*--Analyze ALL users as they are
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
       EXPORTING
*SE3.1PS3v - Always enable Org Level Check
            I_ORG_CHECK       = 'X'
            i_validuser       = space
*SE3.1PS3C - Don't exclude locked users
            I_EXLCKUSR        = space
*SE3.1PS3T - Don't exclude expired users
            i_outvdate        = space
*SE3.4PS3D - Return function details to determine origin
            I_FUNCTION_DETAILS = 'X'
*SE4.0PS1e - Ignore Mitigations assigned to g_sod_vrsio
            I_SHOMIT          = 'X'
            i_allug           = 'X'
            i_vrsio           = g_sod_vrsio
            i_enh             = 'X'
            i_wp              = wp
*--2016/06/07 - Never update the normal scan tables
*  /PSYNG/LOCSCANDT will be updated directly by this report
*            i_xstb            = xstb_fm
            i_scanbg          = ' '
            i_xstb_func       = 'X'
            i_cuscon          = 'X'
** i_locusr added for case 3825 HS
            i_locusr          = p_locusr
            i_pserver         = pserver
            i_max_upp         = maxusers
            i_shonosod        = 'X'
            i_analyze_sap_all = 'X'  "analyze sap_all users in detail
       IMPORTING
           EF_MISSING_AUTH    = lf_auth_failure
           ef_st_missing_auth = lf_st_auth_failure

       TABLES
            it_users          = userids
            it_user_rfc       = lt_rfcdest
            et_outputdet      = ta_output_origin
            it_confs          = gt_conid.
                                      "(++)HBHALLA(PN-18406)(11/05/26)

*SE3.4PS3D - TA_OUTPUT_ORIGIN contains the function and origin details
*            of each conflict
*            Summarize this in ta_output_enh
sort ta_output_origin by bname conid rfcdest.
ta_output_enh[] = ta_output_origin[].
delete adjacent duplicates from ta_output_enh comparing bname conid.
*--Delete all local entries from the origin table
CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
 IMPORTING
   E_RFCDEST       = l_local.
delete  ta_output_origin where rfcdest = l_local.


*--2016/06/07 - Analyze users with an ER session again, but without ER
if not lt_er_users[] is initial.
  ranges : lr_users for sy-uname.
  lr_users-sign   = 'I'.
  lr_users-option = 'EQ'.
  sort lt_er_users by bname.
  delete adjacent duplicates from lt_er_users.
  lt_er_users_h[] = lt_er_users[].
  loop at lt_er_users.
    lr_users-low = lt_er_users-bname.
    collect lr_users.
  endloop.
  MESSAGE S002 WITH 'Analyzing users with Assigned ER sessions,'
                    'ignoring the ER roles'.
  commit work.
    CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
         EXPORTING
*SE3.1PS3v - Always enable Org Level Check
            I_ORG_CHECK       = 'X'
            i_validuser       = space
*  SE3.1PS3C - Don't exclude locked users
            I_EXLCKUSR        = space
*SE3.1PS3T - Don't exclude expired users
            i_outvdate        = space
*SE4.0PS1e - Ignore Mitigations assigned to g_sod_vrsio
            I_SHOMIT          = 'X'
*  --Exclude Assigned ER roles
              I_EXCLUDE_ER_ROLES = 'X'
              i_allug           = 'X'
              i_vrsio           = g_sod_vrsio
              i_enh             = 'X'
              i_wp              = wp
*  --2016/06/07 - Never update the normal scan tables
*    /PSYNG/LOCSCANDT will be updated directly by this report
*              i_xstb            = xstb_fm
              i_scanbg          = ' '
              i_xstb_func       = 'X'
              i_cuscon          = 'X'
              i_locusr          = p_locusr
              i_pserver         = pserver
              i_max_upp         = maxusers
              i_shonosod        = 'X'
              i_analyze_sap_all = 'X'  "analyze sap_all users in detail
         IMPORTING
             EF_MISSING_AUTH    = lf_auth_failure
             ef_st_missing_auth = lf_st_auth_failure

         TABLES
              it_users          = lr_users
              it_user_rfc       = lt_rfcdest
              et_outputdet      = ta_output_no_er
              it_confs          = gt_conid.
                                      "(++)HBHALLA(PN-18406)(11/05/26)

  sort ta_output_no_er by bname conid.
endif.
*--2014/05/15 - Terminate job when the user wasn't authorized
*               to analyze all users
  if lf_auth_failure = 'X'.
    MESSAGE E002(/PSYNG/SW) WITH 'Not Authorized to analyze all users'
   'Y&SW_RPOUG' '' ''.
  endif.
*SE3.1PS3T - Users with no conflicts should be in scan table
*  DELETE ta_output_enh WHERE conid = '----'.
   data : ls_output like line of ta_output_enh.
   ls_output-conid = 'NONE'.

   modify ta_output_enh from ls_output
   transporting conid
   where conid = '----' .

*-- 3.1ps3f - Auth Check message for Scan table
  IF lf_st_auth_failure = 'X'.
    MESSAGE e191(/psyng/sw).
  ENDIF.
  IF ustb = 'X'.
    data : lt_scan type table of /PSYNG/LOCSCANDT with header line,
           lt_scan_part type table of /PSYNG/LOCSCANDT with header line,
           l_er_conflicts type i.
*--Prepare to Update the scan table /PSYNG/LOCSCANDT
    delete from /PSYNG/LOCSCANDT "#EC CI_NOFIRST
    where vrsio = g_sod_vrsio.
    lt_scan-scandate = sy-datum.
    loop at ta_output_enh assigning <output>.
      lt_scan-BNAME    = <output>-bname.
      lt_scan-CONID    = <output>-conid.
      lt_scan-VRSIO    = g_sod_vrsio.
      lt_scan-CONTID   = <output>-contid.
      lt_scan-ER       = ''.
*--Check if this conflict was caused by ER
      read table lt_er_users_h with table key
      bname =  <output>-bname transporting no fields.
      if sy-subrc = 0.
        read table ta_output_no_er with key bname = <output>-bname
                                            conid = <output>-conid
        binary search transporting no fields.
        if sy-subrc <> 0.
*--         in the analysis ignoring assigned ER roles, this conflict
*           was not found, so it was caused by ER
            lt_scan-ER = 'X'.
            add 1 to l_er_conflicts.
        endif.
      endif.
      if  <output>-origin = 3.
*SE3.4PS3D - Determine origin for CROSS conflicts
*            SW_056_RFC_DEST    = 3
*            SW_056_RFC_DEST_2  = 4
*            SW_056_RFC_DEST_3  = 5
*            etc

        read table ta_output_origin with key
         bname   = <output>-bname
         conid   = <output>-conid
         binary search transporting rfcdest.
         if sy-subrc = 0.
           read table gt_remote with key
           system = ta_output_origin-rfcdest
           binary search transporting index.
           add gt_remote-index to <output>-origin.
         endif.
      endif.
      lt_scan-origin = <output>-origin.


      append lt_scan.
    endloop.
*Begin of Addition:HBHALLA(PN-18406)(Issue2)(06/05/26)
  IF l_er_conflicts > 0.
    MESSAGE S002 WITH 'Conflicts detected caused by Emergency Repair : '
    l_er_conflicts.
  ENDIF.
*End of Addition:HBHALLA(PN-18406)(Issue2)(06/05/26)
    commit work.


*--Prepare to Update the scan table /PSYNG/LOCSCANDT
    while not lt_scan[] is initial.
      append lines of lt_scan  from 1 to 5000 to lt_scan_part.
      delete lt_scan from 1 to 5000.
      insert /PSYNG/LOCSCANDT from table lt_scan_part.
      commit work.
      refresh lt_scan_part.
    endwhile.
  endif.

  FREE : xstb_fm,uname, chunks,counter,ta_users,
         wa_user,ta_output_tmp ,wa_usersel.
ENDFORM.                    " data_selection
*&---------------------------------------------------------------------*
*&      Form  get_max_nr_users_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_MAXUSERS  text
*----------------------------------------------------------------------*
FORM get_max_nr_users_config CHANGING p_maxusers.
  DATA : swconfig TYPE /psyng/swconfig.
  SELECT SINGLE * FROM /psyng/swconfig
         INTO swconfig
         WHERE param = 'DFLT_MAX_USER_SCAN'.
  IF sy-subrc = 0.
    p_maxusers = swconfig-value.
  ELSE.
    p_maxusers = 0.
  ENDIF.

ENDFORM.                    " get_max_nr_users_config
*&---------------------------------------------------------------------*
*&      Form  scan_for_custom_conflicts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM scan_for_custom_conflicts TABLES ta_users STRUCTURE usr02.
*** Custom Conflicts ***
*   Hard-code function modules here for now to update internal scan
*   table, but eventually these functions will be dynamically called
*   from the SOD reports to update the scan table.  Then this form and
*   it's call can be removed
  DATA : wa_user LIKE LINE OF ta_users,
         lf_has_conflict TYPE /psyng/bapiflagx,
         wa_outp LIKE LINE OF ta_output.
  LOOP AT ta_users INTO wa_user.
*   User has email address
    CALL FUNCTION '/PSYNG/SW_014'
         EXPORTING
              i_bname         = wa_user-bname
         IMPORTING
              ef_has_conflict = lf_has_conflict.
    IF lf_has_conflict = 'X'.
      wa_outp-bname = wa_user-bname.
      wa_outp-conid = 'UM01'.
      APPEND wa_outp TO ta_output.
    ENDIF.
    CLEAR lf_has_conflict.
*   User is valid
    CALL FUNCTION '/PSYNG/SW_015'
         EXPORTING
              i_bname         = wa_user-bname
         IMPORTING
              ef_has_conflict = lf_has_conflict.

    IF lf_has_conflict = 'X'.
      wa_outp-bname = wa_user-bname.
      wa_outp-conid = 'UM02'.
      APPEND wa_outp TO ta_output.
    ENDIF.
  ENDLOOP.
  FREE : ta_users[], wa_user,wa_outp,lf_has_conflict.
ENDFORM.                    " scan_for_custom_conflicts
*&---------------------------------------------------------------------*
*&      Form  do_calculation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM do_calculation USING enh TYPE flag.

  FREE : count_conflicts_all,
         count_con,
         ta_area_details[],
         ta_conflicts[],
         ta_con_details[],
         area_details,
         con_details.
*get al areas that have conflicts
  SELECT  * INTO TABLE ta_areas FROM /psyng/busarea
  WHERE
*  busarea IN busareas AND
  (
    busarea IN ( select DISTINCT busarea FROM /psyng/conflict
    WHERE inactive = space AND vrsio = g_sod_vrsio )
    OR
    busarea IN ( select DISTINCT busarea FROM /psyng/sw_cuscon
    WHERE inactive = space AND vrsio = g_sod_vrsio )
   ).
*Begin of Addition:HBHALLA(PN-18406)(11/05/26)
 IF gt_are IS NOT INITIAL.
    DELETE ta_areas WHERE busarea NOT IN gt_are.
 ENDIF.
*End of Addition:HBHALLA(PN-18406)(11/05/26)
*get all normal conflicts
  SELECT  * INTO TABLE ta_conflicts FROM /psyng/conflict
  WHERE inactive = space AND vrsio = g_sod_vrsio
    AND busarea IN gt_are."(++)HBHALLA(PN-18406)(11/05/26)
*  AND busarea IN busareas.
*get al custom conflicts
  SELECT * INTO TABLE ta_swcuscon
          FROM /psyng/sw_cuscon
          WHERE inactive = space
          AND vrsio = g_sod_vrsio.
*          WHERE busarea IN busareas.
*count ALL conflicts
  LOOP AT ta_output INTO wa_output.
    IF wa_output-conid = 'ALL'.
      count_conflicts_all = count_conflicts_all + 1.
    ENDIF.
  ENDLOOP.

  SORT ta_output.
  LOOP AT ta_areas INTO wa_area.
*NORMAL conflicts
  LOOP AT ta_conflicts INTO wa_conflict WHERE busarea = wa_area-busarea.
      area_details-busarea = wa_area-busarea.
      con_details-busarea = wa_area-busarea.
      con_details-conid = wa_conflict-conid.
      LOOP AT ta_output INTO wa_output WHERE conid = wa_conflict-conid.
        con_details-count_inc_all = con_details-count_inc_all + 1.
      ENDLOOP.
*   calculate values for this conflict
      con_details-count_inc_all =
        con_details-count_inc_all + count_conflicts_all.
      IF con_details-count_inc_all = 0.
        con_details-perc = 0.
      ELSE.
        con_details-perc =
          ( con_details-count_inc_all / usercount ) * 100.
      ENDIF.
      APPEND con_details TO ta_con_details.

*   add the count to the area count
      area_details-count_inc_all =
        area_details-count_inc_all + con_details-count_inc_all.
      CLEAR con_details.
    ENDLOOP.
*CUSTOM conflicts
    LOOP AT ta_swcuscon INTO wa_cuscon WHERE busarea = wa_area-busarea.
      area_details-busarea = wa_area-busarea.
      con_details-busarea = wa_area-busarea.
      con_details-conid = wa_cuscon-conid.
      LOOP AT ta_output INTO wa_output WHERE conid = wa_cuscon-conid.
        con_details-count_inc_all = con_details-count_inc_all + 1.
      ENDLOOP.
*   calculate values for this conflict
      IF con_details-count_inc_all = 0.
        con_details-perc = 0.
      ELSE.
        con_details-perc =
          ( con_details-count_inc_all / usercount ) * 100.
      ENDIF.
      APPEND con_details TO ta_con_details.

*   add the count to the area count
      area_details-count_inc_all =
        area_details-count_inc_all + con_details-count_inc_all.
      CLEAR con_details.
    ENDLOOP.
    area_details-busarea = wa_area-busarea.
    count_con = count_con + area_details-count_inc_all.
    APPEND area_details TO ta_area_details.
    CLEAR area_details.
  ENDLOOP.
*get number of users per area
  DATA : ta_output_tmp LIKE TABLE OF wa_output,
         usercount_normal TYPE i,
         usercount_custom TYPE i,
         concount_normal TYPE i.
  LOOP AT ta_area_details INTO area_details.
    CLEAR : usercount_custom , usercount_normal,concount_normal.
* count users with normal conflicts
    LOOP AT ta_conflicts INTO wa_conflict WHERE
      busarea = area_details-busarea.
      LOOP AT ta_output INTO wa_output WHERE conid = wa_conflict-conid.
        APPEND wa_output TO ta_output_tmp.
      ENDLOOP.
      concount_normal = concount_normal + 1.
    ENDLOOP.
    SORT ta_output_tmp BY bname.
    DELETE ADJACENT DUPLICATES FROM ta_output_tmp COMPARING bname.
    DESCRIBE TABLE ta_output_tmp LINES usercount_normal.
    FREE : ta_output_tmp[].
* count users with custom conflicts
    LOOP AT ta_swcuscon INTO wa_cuscon WHERE
      busarea = area_details-busarea.
      LOOP AT ta_output INTO wa_output WHERE conid = wa_cuscon-conid.
        APPEND wa_output TO ta_output_tmp.
      ENDLOOP.
    ENDLOOP.
    SORT ta_output_tmp BY bname.
    DELETE ADJACENT DUPLICATES FROM ta_output_tmp COMPARING bname.
    DESCRIBE TABLE ta_output_tmp LINES usercount_custom.
    FREE : ta_output_tmp[].

    area_details-usercount = usercount_custom + usercount_normal.
    IF concount_normal > 0.
*   for each normal conflict, we need to add the nr of users that have
*   ALL conflicts to the total nr of users.
      area_details-usercount = area_details-usercount +
       count_conflicts_all .
    ENDIF.
    IF  area_details-usercount <> 0.
      area_details-avg =
        area_details-count_inc_all / area_details-usercount.
    ELSE.
      area_details-avg = 0.
    ENDIF.
    MODIFY ta_area_details FROM area_details.
  ENDLOOP.
*count users with conflicts
  ta_output_tmp[] = ta_output[].
  SORT ta_output_tmp BY bname.
  DELETE ADJACENT DUPLICATES FROM ta_output_tmp COMPARING bname.
  DESCRIBE TABLE ta_output_tmp LINES count_users_with_conf .
  FREE : ta_output_tmp[].
ENDFORM.                    " do_calculation


*&---------------------------------------------------------------------*
*&      Form  write_header_to_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*

FORM write_header_to_screen USING enh TYPE flag.
*version info
  DATA : sod_version TYPE /psyng/sod_vrsio,
*        sw_version TYPE /psyng/sw_vrsio,(--)UMITTAL PN-16237 21/11/25
         sw_version TYPE /PSYNG/PROG_VRSIO,
         textline TYPE string.
*Begin of Addition:HBHALLA(PN-18406)(Issue1)(06/05/26)
*  SELECT SINGLE * FROM /psyng/sod_vrsio INTO sod_version.
         sod_version-vrsio = g_sod_vrsio.
*End of Addition:HBHALLA(PN-18406)(Issue1)(06/05/26)
*BOC UMITTAL PN-16237 21/11/2025
*  SELECT SINGLE * FROM /psyng/sw_vrsio INTO sw_version.
  CALL FUNCTION '/PSYNG/SW_VERSION'
   IMPORTING
*     e_module               =
*     e_module_name          =
     e_module_version       = sw_version.
*EOC UMITTAL PN-16237 21/11/2025

*  WRITE  : / text-099 , AT 40 sy-uname ,
*                        AT 60 text-120,
*                        sod_version-vrsio.
  NEW-LINE.
  FORMAT INTENSIFIED OFF.
  FORMAT COLOR OFF.
  IF enh = 'X'.
    WRITE  :   'SOD Overview for enhanced ruleset'(132).

  ELSE.
    WRITE  :   'SOD Overview for standard ruleset'(124).
  ENDIF.
  NEW-LINE.
  NEW-LINE.
  WRITE  :    AT 60 text-120,
              sod_version-vrsio.

  WRITE  : / text-100 , AT 40 sy-datum,
                        AT 60 text-121,
*BOC UMITTAL PN-16237 21/11/2025
*                        sw_version-vrsio.
                        sw_version.
*EOC UMITTAL PN-16237 21/11/2025
  WRITE  : / text-101 , AT 40 sy-uzeit, AT 60 chksm LEFT-JUSTIFIED.
  WRITE  : / text-017 , AT 40 sysid.
  WRITE  : / text-018 , AT 40 grocman.
  WRITE  : / text-102 , AT 40 usercount .


  LOOP AT ta_area_details INTO area_details.
    CONCATENATE text-103 area_details-busarea INTO textline
    SEPARATED BY space.
* usercount includes users with ALL!
    WRITE : / textline, AT 40 area_details-usercount .
  ENDLOOP.

  WRITE : / text-104, AT 40 count_users_with_conf  .
* ALL
  WRITE : / text-105,AT 40 count_conflicts_all .
  ULINE.
*column headers
  FORMAT   COLOR COL_HEADING .
  WRITE : / text-106,
            AT 35 text-107,
            AT 45 text-109,
            AT 75 text-111.
  FORMAT INTENSIFIED OFF.
ENDFORM.                    " write_output_to_screen


*&---------------------------------------------------------------------*
*&      Form  write_output_to_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM write_output_to_screen USING enh TYPE flag.

* total number of conflicts
  FORMAT INTENSIFIED ON COLOR COL_GROUP .
  WRITE : / 'Total:'(131) LEFT-JUSTIFIED,
            AT 45 count_con LEFT-JUSTIFIED.
  FORMAT INTENSIFIED OFF.
*Begin of Addition:HBHALLA(PN-18406)(11/05/26)
    message s398(00) with
    'Number of SOD conflicts found  :'(l09) count_con.
*End of Addition:HBHALLA(PN-18406)(11/05/26)
* area details
  LOOP AT ta_area_details INTO area_details.
    READ TABLE ta_areas INTO wa_area
    WITH KEY busarea = area_details-busarea.

    FORMAT INTENSIFIED ON COLOR COL_GROUP  .
    WRITE : / wa_area-text(34),
              AT 35 area_details-busarea LEFT-JUSTIFIED,
              AT 45 area_details-count_inc_all LEFT-JUSTIFIED,
              AT 75 area_details-avg  LEFT-JUSTIFIED.
    FORMAT INTENSIFIED OFF.

*conflict details
    FORMAT INTENSIFIED ON COLOR COL_HEADING.
    NEW-LINE.
    WRITE AT 75 text-110.
    FORMAT INTENSIFIED OFF.
    LOOP AT ta_con_details INTO con_details
    WHERE busarea = area_details-busarea.
      WRITE : / con_details-conid,
         AT 35 con_details-busarea LEFT-JUSTIFIED,
         AT 45 con_details-count_inc_all LEFT-JUSTIFIED,
         AT 75 con_details-perc LEFT-JUSTIFIED.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " write_output_to_screen
*&---------------------------------------------------------------------*
*&      Form  del_trailing_blanks
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_ARE_NAMES  text
*----------------------------------------------------------------------*
FORM del_trailing_blanks CHANGING str.
  DATA l TYPE i.
  " handle the case when str is empty
  DATA blank TYPE string.
  SHIFT blank RIGHT BY 1 PLACES.
  IF NOT str IS INITIAL.
    l = strlen( str ) - 1.
    WHILE l > 0 AND str+l(1) = blank.
      l = l - 1.
    ENDWHILE.
    IF l >= 0 AND str+l(1) <> blank.
      l = l + 1.
    ENDIF.
    str = str(l).
  ENDIF.

ENDFORM.                    " del_trailing_blanks

*&---------------------------------------------------------------------*
*&      Form  report_rfc_error
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_RFC_ERROR  text
*      -->P_ROLERFC  text
*----------------------------------------------------------------------*
FORM report_rfc_error USING    l_rfc_error
                               l_rfc_log.
  MESSAGE w113(/psyng/sw) WITH
  l_rfc_error
  l_rfc_log.
  MESSAGE e113(/psyng/sw) WITH
  'Verify RFC destination configured in SW_056_RFC_DEST parameter'(e01).
  COMMIT WORK.
  STOP.

ENDFORM.                    " report_rfc_error
*&---------------------------------------------------------------------*
*&      Form  collect_er_users
*&---------------------------------------------------------------------*
* Collect all users that have ER roles currently assigned.
*----------------------------------------------------------------------*
*      -->et_users
*----------------------------------------------------------------------*
FORM collect_er_users TABLES   ET_USERS STRUCTURE usr02.
constants :
       l_tab_assigned(15) type c value '/PSYNG/ER_ASSGN',
       l_tab_sess(14)     type c value '/PSYNG/ER_SESS'.
data : lf_er_installed type flag,
       lt_transid type table of /PSYNG/ER_TRANSID,
       l_num type i,
       l_er_vrsio type /PSYNG/PROG_VRSIO.
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
   EXPORTING
     I_MODULE               = 'ER'
   IMPORTING
     E_INSTALLED            =  lf_er_installed
     E_MODULE_VERSION       =  l_er_vrsio.
  if lf_er_installed is initial or l_er_vrsio < '2.5'.
    MESSAGE S002 WITH
    'Emergency Repair is not installed on this system'.
  else.
    MESSAGE S002 WITH 'Loading users that currently have'
                      'a running Emergency Repair session'.
select transid from (l_tab_assigned) into table lt_transid.
"#EC SAST_CI_GEN_CHECK
    if not lt_transid is initial.
select distinct username as bname from (l_tab_sess)
"#EC SAST_CI_GEN_CHECK
      into corresponding fields of table et_users
      for all entries in lt_transid
      where transid = lt_transid-table_line.
    endif.
  endif.
  describe table et_users lines l_num.
  MESSAGE S002 WITH 'Active Emergency Repair sessions : ' l_num.
  commit work.
ENDFORM.                    " collect_er_users
*&---------------------------------------------------------------------*
*&      Form  AREAS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM areas .
DATA: ls_are TYPE /PSYNG/RANGE_APPL,
      wa_conid     type /psyng/sw_sel_opts_conid.
data: begin of it_conid occurs 0,
        conid type /psyng/conflict-conid,
        owner type /psyng/conflict-owner,
      end of it_conid.

ls_are-sign = 'I'.
ls_are-option = 'EQ'.

IF are_01 IS NOT INITIAL.
  ls_are-low = are_01.
 APPEND ls_are TO gt_are.
ENDIF.

IF are_02 IS NOT INITIAL.
  ls_are-low = are_02.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_03 IS NOT INITIAL.
  ls_are-low = are_03.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_04 IS NOT INITIAL.
  ls_are-low = are_04.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_05 IS NOT INITIAL.
  ls_are-low = are_05.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_06 IS NOT INITIAL.
  ls_are-low = are_06.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_07 IS NOT INITIAL.
  ls_are-low = are_07.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_08 IS NOT INITIAL.
  ls_are-low = are_08.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_09 IS NOT INITIAL.
  ls_are-low = are_09.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_10 IS NOT INITIAL.
  ls_are-low = are_10.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_11 IS NOT INITIAL.
  ls_are-low = are_11.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_12 IS NOT INITIAL.
  ls_are-low = are_12.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_13 IS NOT INITIAL.
  ls_are-low = are_13.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_14 IS NOT INITIAL.
  ls_are-low = are_14.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_15 IS NOT INITIAL.
  ls_are-low = are_15.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_16 IS NOT INITIAL.
  ls_are-low = are_16.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_17 IS NOT INITIAL.
  ls_are-low = are_17.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_18 IS NOT INITIAL.
  ls_are-low = are_18.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_19 IS NOT INITIAL.
  ls_are-low = are_19.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_20 IS NOT INITIAL.
  ls_are-low = are_20.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_21 IS NOT INITIAL.
  ls_are-low = are_21.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_22 IS NOT INITIAL.
  ls_are-low = are_22.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_23 IS NOT INITIAL.
  ls_are-low = are_23.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_24 IS NOT INITIAL.
  ls_are-low = are_24.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_25 IS NOT INITIAL.
  ls_are-low = are_25.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_26 IS NOT INITIAL.
  ls_are-low = are_26.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_27 IS NOT INITIAL.
  ls_are-low = are_27.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_28 IS NOT INITIAL.
  ls_are-low = are_28.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_29 IS NOT INITIAL.
  ls_are-low = are_29.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_30 IS NOT INITIAL.
  ls_are-low = are_30.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_31 IS NOT INITIAL.
  ls_are-low = are_31.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_32 IS NOT INITIAL.
  ls_are-low = are_32.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_33 IS NOT INITIAL.
  ls_are-low = are_33.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_34 IS NOT INITIAL.
  ls_are-low = are_34.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_35 IS NOT INITIAL.
  ls_are-low = are_35.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_36 IS NOT INITIAL.
  ls_are-low = are_36.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_37 IS NOT INITIAL.
  ls_are-low = are_37.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_38 IS NOT INITIAL.
  ls_are-low = are_38.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_39 IS NOT INITIAL.
  ls_are-low = are_39.
 APPEND ls_are TO gt_are.
ENDIF.


IF are_40 IS NOT INITIAL.
  ls_are-low = are_40.
 APPEND ls_are TO gt_are.
ENDIF.

 SELECT      conid owner
 FROM       /psyng/conflict
 INTO TABLE it_conid
 WHERE busarea IN gt_are.

 LOOP AT it_conid.
   wa_conid-sign = 'I'.
   wa_conid-option = 'EQ'.
   wa_conid-low = it_conid-conid.
   append wa_conid to gt_conid.
 ENDLOOP.

 FREE it_conid[].

 READ TABLE gt_are WITH KEY low = '*'
   TRANSPORTING NO FIELDS.
     IF sy-subrc = 0.
       FREE gt_are.
     ENDIF.

ENDFORM.
