*----------------------------------------------------------------------*
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*//
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_147 MESSAGE-ID /psyng/sw
NO STANDARD PAGE HEADING."#EC SAST_CI_GEN_CHECK

TYPE-POOLS: slis.
INCLUDE /psyng/sw_config.

CONSTANTS: gc_batch_but TYPE char7 VALUE 'BGD_BUT',
           gc_batch     TYPE char3 VALUE 'BGD',
           gc_flag_on   TYPE char1 VALUE 'X',
           gc_flag_yes  TYPE char1 VALUE 'Y'.

TYPES: BEGIN OF ty_swenhbuff,
         update_date TYPE /psyng/swenhbuff-update_date,
       END   OF ty_swenhbuff,

       BEGIN OF ty_usr_displ,
         expanded TYPE flag,
       END OF ty_usr_displ.

DATA: g_exit_proc,
      g_button_set     TYPE flag,
      g_ucomm          LIKE sy-ucomm,
      g_curr_variant   LIKE  rsvar-variant,
      g_variant        LIKE  vari-variant,
      g_program        LIKE sy-repid,
      gt_vari_desc     TYPE varid OCCURS 0 WITH HEADER LINE,
      gt_vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      gt_vari_text     LIKE varit OCCURS 0 WITH HEADER LINE,
      gt_irsparams     TYPE rsparams OCCURS 0 WITH HEADER LINE,
      g_current_user   TYPE sy-uname. "C0700

*--Basic Selection block
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-b01.
PARAMETERS: p_force TYPE flag,
            p_vrsio TYPE /psyng/sodvrsio MEMORY ID /psyng/vrsio,
            p_udate TYPE /psyng/swenhbuff-update_date.
SELECTION-SCREEN: END OF BLOCK b1.

*---Background Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME.
SELECTION-SCREEN PUSHBUTTON  01(6) bgd_but USER-COMMAND bgd_but.
SELECTION-SCREEN COMMENT 16(50) text-b05 .
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-025 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-026 MODIF ID bgd.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK bgd_o.


INITIALIZATION.
  PERFORM init_but     USING gc_batch_but  gc_flag_on CHANGING bgd_but.
  PERFORM handle_section USING  bgd_but  gc_batch.
* BOC by RGUPTA for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA for C0700
*--Disable screen field
AT SELECTION-SCREEN OUTPUT.

  PERFORM fill_last_update_date.
  PERFORM handle_button.
  PERFORM handle_section USING  bgd_but  gc_batch.

*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN ON p_vrsio.
  DATA : l_vrsio TYPE /psyng/sodvrsio.
*--Validation of SOD version
  SELECT SINGLE vrsio INTO l_vrsio FROM /psyng/swsodvers
  WHERE vrsio = p_vrsio.
  IF sy-subrc NE 0.
    MESSAGE s002(/psyng/sw) WITH
    'Please Enter Valid SOD version'(029).
    LEAVE SCREEN.
  ENDIF.

AT SELECTION-SCREEN.

  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.
  CASE g_ucomm.
    WHEN 'SCJB'.
      g_exit_proc = gc_flag_yes.
      PERFORM schedule_back_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
  ENDCASE.

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
  DATA: l_enh_buffer        TYPE /psyng/param,
        l_enh_buffer_days   TYPE /psyng/param,
        l_enh_buffer_days_i TYPE i,
        l_last_update_days  TYPE i,
        lf_force            TYPE flag,
        ls_swenhbuff        TYPE ty_swenhbuff.

  g_program = sy-repid.
  IF g_exit_proc = gc_flag_yes.
*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_147
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.
  lf_force = p_force.
*--Check if buffering is enabled
  se_config_param 'SW_ENH_BUFFER' l_enh_buffer.
  IF l_enh_buffer NE gc_flag_yes.
    MESSAGE i002(/psyng/sw) WITH
    'Dynamic Enhancement Buffering is not enabled'(030).
  ENDIF.

*--Get buffer days defined in parameters
  se_config_param 'SW_ENH_BUFFER_DAYS' l_enh_buffer_days.
  l_enh_buffer_days_i = l_enh_buffer_days.
*--Fetch last update date of buffer table for the input version
  PERFORM get_last_update_date
    USING p_vrsio
 CHANGING ls_swenhbuff-update_date.

  IF NOT ls_swenhbuff-update_date IS INITIAL.
    l_last_update_days = sy-datum - ls_swenhbuff-update_date.
  ELSE.
    lf_force = 'X'.
  ENDIF.
*--If the data currently stored in the buffer
*--is older than SW_ENH_BUFFER_DAYS or there is no data stored"
*--Or P_FORCE = X update the data in the buffer
*--by calling FM /PSYNG/SW_ENH_UPDATE
  IF l_last_update_days GT l_enh_buffer_days_i
  OR lf_force EQ gc_flag_on.
    CALL FUNCTION '/PSYNG/SW_ENH_UPDATE'
         EXPORTING
              i_vrsio = p_vrsio.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  init_but
*&---------------------------------------------------------------------*
*       To initilize the expand/collapse button
*----------------------------------------------------------------------*
*      <--P_USER_BUT  text
*      <--P_'USER_BUT'  text
*      <--P_'X'  text
*----------------------------------------------------------------------*
FORM init_but USING    i_name
                       i_default_expanded
              CHANGING i_button.

  DATA : ls_state TYPE ty_usr_displ,
         l_exp TYPE flag.
  SELECT expanded
    INTO ls_state
    FROM /psyng/usr_displ
    UP TO 1 ROWS
  WHERE
*    bname = sy-uname AND "C0700 by RGUPTA
    bname = g_current_user AND "C0700
    repid = sy-repid AND
    button_name = i_name.
  ENDSELECT.
  IF sy-subrc = 0.
    l_exp = ls_state-expanded.
  ELSE.
    l_exp = i_default_expanded.
  ENDIF.

  IF l_exp = gc_flag_on.
    PERFORM expand CHANGING i_button.
  ELSE.
    PERFORM collapse CHANGING i_button.
  ENDIF.

ENDFORM.                    " init_but
*---------------------------------------------------------------------*
*       FORM toggle_section                                           *
*---------------------------------------------------------------------*
*       On Expand/collapse button click, toggle the output            *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*  -->  I_SECTION_NAME                                                *
*---------------------------------------------------------------------*
FORM handle_section USING    i_button
                             i_section_name.

  LOOP AT SCREEN .
    IF screen-group1 = i_section_name.
      IF i_button(3) <> '@3T'.
        screen-invisible = 1.
        screen-active    = 0.
      ELSE.
        screen-invisible = 0.
        screen-active    = 1.
      ENDIF.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " toggle_section

*&---------------------------------------------------------------------*
*&      Form  expand
*&---------------------------------------------------------------------*
*       To expand the section
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
*       To Collapse the section
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
*&      Form  handle_button
*&---------------------------------------------------------------------*
*       To handle button
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_button.
  CASE g_ucomm.
    WHEN 'BGD_BUT'.
      PERFORM toggle USING bgd_but gc_batch_but.
  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.                    " handle_button
*---------------------------------------------------------------------*
*       FORM toggle                                                   *
*---------------------------------------------------------------------*
*       Toggle                                                        *
*---------------------------------------------------------------------*
*  -->  I_BUTTON                                                      *
*---------------------------------------------------------------------*
FORM toggle USING i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700 by RGUPTA
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand CHANGING i_button.
    ls_state-expanded = gc_flag_on.
    CLEAR g_button_set.
  ELSE.
    PERFORM collapse CHANGING i_button.
    CLEAR  ls_state-expanded.
    g_button_set = gc_flag_on.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       Schedule the job in background                                *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname   TYPE btcjob.

  CLEAR: curr_report, g_curr_variant.

  PERFORM create_variant_from_sel.

  curr_report    = sy-repid.
  g_curr_variant = g_variant.

  l_jobname = sy-repid .
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
       EXPORTING
            in_jobname  = l_jobname
            in_repvarnt = g_curr_variant
            in_report   = curr_report.

ENDFORM.                    " schedule_back_job
*&---------------------------------------------------------------------*
*&      Form  create_variant_from_sel
*&---------------------------------------------------------------------*
*       To create selection screen variant
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_variant_from_sel.

  DATA: curr_report LIKE rsvar-report.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report    = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
       EXPORTING
            curr_report   = curr_report
            curr_variant  = g_curr_variant
            vari_desc     = gt_vari_desc
       TABLES
            vari_contents = gt_vari_contents
            vari_text     = gt_vari_text
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

ENDFORM.                    " create_variant_from_sel
*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       Get next variant ID                                           *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: g_variant, gt_vari_desc.
  REFRESH: gt_vari_desc.
  SELECT  variant INTO g_variant FROM varid

  WHERE report = sy-repid   AND
        variant LIKE '/PSYNG/%' AND NOT
        variant LIKE '/PSYNG/Z%'
  ORDER BY variant DESCENDING.
    oldnumber = g_variant+7(7).
    EXIT.
  ENDSELECT.
  IF sy-subrc NE 0.
    g_variant = '/PSYNG/0000000'.
  ELSE.
    oldnumber = oldnumber + 1.
    MOVE oldnumber TO oldnumber_c.
    CONCATENATE '/PSYNG/' oldnumber_c INTO g_variant.
  ENDIF.

  gt_vari_desc-report = sy-repid.
  gt_vari_desc-variant = g_variant.
  APPEND gt_vari_desc.

ENDFORM.                    " get_next_variant_id
*---------------------------------------------------------------------*
*       FORM fill_sel_screen_fields_to_tab                            *
*---------------------------------------------------------------------*
*       Selection screen fields                                       *
*---------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
       EXPORTING
            i_repid       = g_program
            if_no_logging = gc_flag_on
       TABLES
            et_params     = gt_irsparams.
ENDFORM.                    " fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*&      Form  fill_last_update_date
*&---------------------------------------------------------------------*
*       Get last update date for input version
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_last_update_date.

  GET PARAMETER ID '/PSYNG/VRSIO' FIELD p_vrsio.

  CLEAR p_udate.
  PERFORM get_last_update_date
    USING p_vrsio
 CHANGING p_udate.

*--Display the last update date for the selected version
  LOOP AT SCREEN.
    IF screen-name EQ 'P_UDATE'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " fill_last_update_date
*&---------------------------------------------------------------------*
*&      Form  get_last_update_date
*&---------------------------------------------------------------------*
*       Get last update date
*----------------------------------------------------------------------*
*      -->P_P_VRSIO  text
*      <--P_P_UDATE  text
*----------------------------------------------------------------------*
FORM get_last_update_date USING    i_vrsio TYPE /psyng/sodvrsio
                          CHANGING e_udate TYPE dats.

  DATA: ls_swenhbuff TYPE ty_swenhbuff.

  SELECT update_date
    FROM /psyng/swenhbuff
    UP TO 1 ROWS
    INTO ls_swenhbuff
    WHERE vrsio EQ i_vrsio.
    e_udate = ls_swenhbuff-update_date.
  ENDSELECT.

ENDFORM.                    " get_last_update_date
