REPORT /psyng/sw_146 MESSAGE-ID /psyng/sw."#EC SAST_CI_GEN_CHECK
INCLUDE /psyng/sw_config.
TABLES /psyng/sw_rfcdes.
TYPE-POOLS : slis.
DATA :
lt_elements           TYPE TABLE OF /psyng/swcfsel WITH HEADER LINE,
lt_varel          TYPE TABLE OF /psyng/swcfgve WITH HEADER LINE,
lt_systems          TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
lt_org                 TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
lt_return	        TYPE TABLE OF bapireturn WITH HEADER LINE,
ls_set                TYPE /psyng/swcfgset,
ls_version            TYPE /psyng/swsodvers,
ls_return             TYPE bapireturn,
g_program             LIKE sy-repid,
g_org_current_count   TYPE i,
g_org_orig_count      TYPE i,
g_varel_current_count TYPE i,
g_varel_orig_count    TYPE i,
gf_email_sent         TYPE flag,
gf_email_sent_global  TYPE flag,
g_exit_proc,
g_ucomm               LIKE sy-ucomm,
curr_variant          LIKE  rsvar-variant,
g_curr_variant        LIKE  rsvar-variant,
g_variant             LIKE vari-variant,
g_vari_desc           TYPE varid OCCURS 0 WITH HEADER LINE,
g_vari_contents       LIKE  rsparams OCCURS 0 WITH HEADER LINE,
g_vari_text           LIKE varit OCCURS 0 WITH HEADER LINE,
gt_irsparams          TYPE rsparams OCCURS 0 WITH HEADER LINE,
gt_rfcdest            TYPE TABLE OF rfcdes WITH HEADER LINE,



BEGIN OF gt_output OCCURS 0,
  remsys    TYPE /psyng/sysid,
  type      LIKE /psyng/swcfsel-type,
  type_text TYPE string,
  orig      TYPE flag,
  current   TYPE flag,
  abb       TYPE /psyng/dorg_abb,
  name      TYPE string,
  system    LIKE /psyng/swcfgve-sysid,
  value     TYPE xuvalue,
  setid     TYPE /psyng/seconfid,
  description TYPE /psyng/longtextfield,
END OF gt_output.

SELECTION-SCREEN: BEGIN OF BLOCK eml WITH FRAME TITLE text-b01 .
PARAMETERS : pf_email    TYPE flag AS CHECKBOX,
             p_email     TYPE /PSYNG/TEXT240."/psyng/longtext.
SELECTION-SCREEN: END OF BLOCK eml.
SELECTION-SCREEN: BEGIN OF BLOCK set WITH FRAME TITLE text-b02 .
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS :
             p_cfgdef   TYPE flag DEFAULT 'X'.
SELECTION-SCREEN COMMENT 3(35) text-c01 FOR FIELD p_cfgdef.
SELECTION-SCREEN END OF LINE.
PARAMETER p_cfgset    TYPE /psyng/seconfid.
SELECTION-SCREEN: END OF BLOCK set.

SELECTION-SCREEN: BEGIN OF BLOCK sysb WITH FRAME TITLE text-b05.
SELECT-OPTIONS :
      s_system  FOR /psyng/sw_rfcdes-rfcdest
                MATCHCODE OBJECT /psyng/sw_rfcsh_coll
                MODIF ID sys.
PARAMETERS     :
      p_remon   TYPE flag MODIF ID sys.
SELECTION-SCREEN: END OF BLOCK sysb.

SELECTION-SCREEN: BEGIN OF BLOCK cmp WITH FRAME TITLE text-b03 .
PARAMETERS :
             p_igman   TYPE flag DEFAULT 'X',
             p_init    TYPE flag DEFAULT ''.
SELECTION-SCREEN: END OF BLOCK cmp.
*---Background Block
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME TITLE text-b04 .
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK bgd_o.



AT SELECTION-SCREEN OUTPUT.

  LOOP AT SCREEN.
    IF screen-name = 'P_EMAIL'.
      screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

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
  DATA: l_continue TYPE flag,
        l_count    TYPE i,
        l_org_current_count   TYPE i,
        l_org_orig_count      TYPE i,
        l_varel_current_count TYPE i,
        l_varel_orig_count    TYPE i.
  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_146
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.
  IF  NOT p_remon IS INITIAL
  AND s_system IS INITIAL.
    MESSAGE s002 WITH 'Please enter remote system'(e00).
    LEAVE LIST-PROCESSING.
  ENDIF.
*-- Check RFC destinations
  IF NOT s_system[] IS INITIAL.
    PERFORM rfc_validations CHANGING l_continue.
    IF l_continue NE 'X'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.
  PERFORM load_rfc
            TABLES
              s_system
              gt_rfcdest.
*--Add local system to gt_rfcdest.
  IF p_remon IS INITIAL.
    CLEAR gt_rfcdest.
    CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest-rfcoptions.
    APPEND gt_rfcdest.
  ENDIF.
  IF gt_rfcdest[] IS INITIAL.
    LEAVE LIST-PROCESSING.
  ENDIF.
*-- Check RFC destinations
  DESCRIBE TABLE gt_rfcdest[] LINES l_count.
  LOOP AT gt_rfcdest.
    CLEAR: ls_set, ls_version, ls_return,
           l_org_current_count, l_org_orig_count,
           l_varel_current_count, l_varel_orig_count,
           gf_email_sent.
    REFRESH: lt_varel, lt_systems, lt_org, lt_elements, lt_return.
*--Load the config set
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
    CALL FUNCTION '/PSYNG/SW_API_I_GET_CONFIG_SET'
    DESTINATION gt_rfcdest-rfcdest
         EXPORTING
              config_set    = p_cfgset
              if_def_conf   = p_cfgdef
              if_inactive   = 'X'  "Validate complete set as previous
         IMPORTING
              es_set        = ls_set
              es_sod_matrix = ls_version
              return        = ls_return
         TABLES
              et_varel      = lt_varel
              et_systems    = lt_systems
              et_org        = lt_org
              et_elements   = lt_elements
              et_return     = lt_return
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
    IF ls_return-type = 'E'.
      MESSAGE i002(/psyng/sw) WITH ls_return-message
      'In analzed system'(t12)
      gt_rfcdest-rfcoptions.
      IF l_count EQ 1.
        LEAVE LIST-PROCESSING.
      ELSE.
        CONTINUE.
      ENDIF.
    ENDIF.
*--Initialize the stored differences, so mails can be re-sent
    IF p_init = 'X'.

      DELETE FROM /psyng/swcfgcmp
      WHERE remsys = gt_rfcdest-rfcoptions
        AND setid = ls_set-setid.
      MESSAGE s002(/psyng/sw) WITH
      'Deleted history of changes that were e-mailed'
      'about'
      'for analyzed system'(t13)
      gt_rfcdest-rfcoptions.
      COMMIT WORK.

    ENDIF.

*--Analyze the current situation
*--Org Values
    PERFORM check_org_values
      TABLES
        lt_elements
        lt_org.
*--Variable Elements
    PERFORM check_varel_values
      TABLES
        lt_elements
        lt_varel.
*--Send e-mail
    IF pf_email = 'X'.
      PERFORM send_email.
    ENDIF.

  ENDLOOP.
*--Remove duplicates
*sort gt_output.
*delete adjacent duplicates from gt_output.

*--Output results
  IF  sy-batch IS INITIAL
  AND NOT gf_email_sent_global IS INITIAL.
    MESSAGE s002(/psyng/sw) WITH 'E-Mail sent to  : ' p_email.
  ENDIF.
  PERFORM output_results_alv.


INITIALIZATION.
  PERFORM load_email_config.


AT SELECTION-SCREEN.



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
  ENDCASE.
  g_ucomm = sy-ucomm.
  CLEAR sy-ucomm.


FORM load_email_config.
  DATA : l_cidx      TYPE i,
         l_idx TYPE string,
         l_emails TYPE string,
         l_param     TYPE /psyng/param,
         l_paramval  TYPE /psyng/param_value.

  se_config_param 'CFGGSET_COMP_ADDR' l_emails.
*--Get default variable elements
  l_cidx = 1.
  WHILE l_cidx LE 999.
    l_idx = l_cidx.
    CONCATENATE 'CFGGSET_COMP_ADDR' l_idx INTO l_param.
    se_config_param l_param l_paramval.
    IF NOT l_paramval IS INITIAL .
*      append l_paramval to lt_defaults.
      CONCATENATE l_emails l_paramval INTO l_emails.
    ELSE.
      IF l_cidx > 1.
        EXIT."only consider consecutive param nrs
        "CFGGSET_COMP_ADDR1 can be skipped
      ENDIF.
    ENDIF.
    ADD 1 TO l_cidx.
  ENDWHILE.
  p_email = l_emails.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM schedule_back_job                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_back_job.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob.
  CLEAR: curr_report, g_curr_variant.



  PERFORM create_variant_from_sel.

  curr_report = sy-repid.
  g_curr_variant = g_variant.

  l_jobname = 'SE-Compare Config Set with Customizing'(j01) .
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
       EXPORTING
            in_jobname  = l_jobname
            in_repvarnt = g_curr_variant
            in_report   = curr_report.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ENDIF.
ENDFORM.                    " schedule_back_job
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

*---------------------------------------------------------------------*
*       FORM create_variant_from_sel                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
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
*       FORM check_varel_values                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_ELEMENTS                                                   *
*  -->  IT_VAREL                                                      *
*---------------------------------------------------------------------*
FORM check_varel_values
TABLES
  it_elements STRUCTURE /psyng/swcfsel
  it_varel    STRUCTURE /psyng/swcfgve.
  DATA :
    lt_varel_current  TYPE TABLE OF	/psyng/swcfgve
                      WITH HEADER LINE,
    lt_varel_combined TYPE TABLE OF	/psyng/swcfgve
                      WITH HEADER LINE,
    lt_varel_sel      TYPE TABLE OF /psyng/range_se_varel
                      WITH HEADER LINE,
    lf_orig           TYPE flag,
    lf_current        TYPE flag.

  LOOP AT it_elements WHERE type = 'VE' AND sel = 'X'.
    lt_varel_sel-sign   = 'I'.
    lt_varel_sel-option = 'EQ'.
    lt_varel_sel-low    = it_elements-varbl.
    APPEND lt_varel_sel.
  ENDLOOP.
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
  CALL FUNCTION '/PSYNG/SW_VE_READ'
    DESTINATION gt_rfcdest-rfcdest
       EXPORTING
            if_analyze          = 'X'
            i_setid             = ls_set-setid
            i_varel_vrsio       = ls_set-varel_vrsio
            if_include_inactive = 'X'
            if_validate         = 'X'
       TABLES
            et_ve_values        = lt_varel_current
            it_systems          = lt_systems
            it_analyze_elements = lt_varel_sel
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
  IF p_igman = 'X'.
*--Ignore manual exclusions
    DELETE it_varel         WHERE active <> 'X' AND modified <> 'X'.
*--Ignore manual inclusions
    DELETE it_varel         WHERE active = 'X' AND modified = 'X'.

  ELSE.
    DELETE it_varel         WHERE active <> 'X'.
  ENDIF.
  DELETE lt_varel_current WHERE active <> 'X'.
  lt_varel_combined[] = it_varel[].
  APPEND LINES OF lt_varel_current TO lt_varel_combined .

  SORT : lt_varel_current, it_varel, lt_varel_combined.
  DELETE ADJACENT DUPLICATES FROM lt_varel_combined COMPARING
    var_element sysid value .
  LOOP AT lt_varel_combined.
    CLEAR : lf_orig, lf_current.
*--Check if current
    READ TABLE lt_varel_current WITH KEY
      var_element  = lt_varel_combined-var_element
      sysid        = lt_varel_combined-sysid
      value        = lt_varel_combined-value.
*      active       = lt_varel_combined-active.
    IF sy-subrc = 0.
      lf_current = 'X'.
    ENDIF.
*--Check if in config set
    READ TABLE it_varel WITH KEY
      var_element  = lt_varel_combined-var_element
      sysid        = lt_varel_combined-sysid
      value        = lt_varel_combined-value.
    IF sy-subrc = 0.
      lf_orig = 'X'.
    ENDIF.
    IF lf_current <> lf_orig.
      gt_output-remsys    = gt_rfcdest-rfcoptions.
      gt_output-type      = 'VE'.
      gt_output-type_text = 'Variable Element'(t01).
      gt_output-orig      = lf_orig.
      gt_output-current   = lf_current.
      gt_output-abb       = ''.
      gt_output-name      = lt_varel_combined-var_element.
      gt_output-system    = lt_varel_combined-sysid.
      gt_output-value     = lt_varel_combined-value.
      gt_output-setid     = ls_set-setid.
      gt_output-description = ls_set-description.
      APPEND gt_output.
      IF lf_orig = 'X'.
        ADD 1 TO g_varel_orig_count.
        ADD 1 TO l_varel_orig_count.
      ELSE.
        ADD 1 TO g_varel_current_count.
        ADD 1 TO l_varel_current_count.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  check_org_values
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_ELEMENTS  text
*      -->P_LT_ORG  text
*----------------------------------------------------------------------*
FORM check_org_values
TABLES
  it_elements STRUCTURE /psyng/swcfsel
  it_org      STRUCTURE /psyng/swcfgoe.
  DATA :
    lt_org_current    TYPE TABLE OF	/psyng/swcfgoe WITH HEADER LINE
,
    lt_org_combined   TYPE TABLE OF	/psyng/swcfgoe WITH HEADER LINE
,
    lt_org_sel        TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
    lf_orig           TYPE flag,
    lf_current        TYPE flag.
*--Organizational Values
  LOOP AT it_elements WHERE type = 'ORG' AND sel = 'X'.
    lt_org_sel-varbl    = it_elements-varbl.
    lt_org_sel-field    = it_elements-varbl.
    lt_org_sel-selected = 'X'.
    APPEND lt_org_sel.
  ENDLOOP.
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
  CALL FUNCTION '/PSYNG/SW_AO_READ'
    DESTINATION gt_rfcdest-rfcdest
       EXPORTING
            if_analyze          = 'X'
            if_validate         = 'X'
            i_setid             = ls_set-setid
       TABLES
            et_org_values       = lt_org_current
*            et_texts            = lt_texts
            it_analyze_elements = lt_org_sel
            it_systems          = lt_systems
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

*--opl554 and 546 om 16/11/2022
*--take all modified objects and delete them if
*--ignore manual changes ticked
  IF p_igman = 'X'.
    LOOP AT it_org WHERE modified = 'X'.
      READ TABLE lt_org_current WITH KEY
             abb    = it_org-abb
            varbl  = it_org-varbl
            sysid  = it_org-sysid
            value  = it_org-value.
      IF sy-subrc = 0.
        DELETE lt_org_current
        WHERE
              abb    = it_org-abb AND
             varbl  = it_org-varbl AND
             sysid  = it_org-sysid AND
             value  = it_org-value.
        READ TABLE it_org WITH KEY
                         abb = it_org-abb
                          varbl = 'BUKRS'
                          active = ' '.
        IF sy-subrc = 0.
          DELETE lt_org_current WHERE
                    abb = it_org-abb.
        ENDIF.

      ENDIF.
      DELETE it_org.
    ENDLOOP.
  ENDIF.
*--end changes opl 554 & 546

  IF p_igman = 'X'.
*--Ignore manual exclusions
    DELETE it_org         WHERE active <> 'X' AND modified <> 'X'.
*--Ignore manual inclusions
    DELETE it_org         WHERE active = 'X' AND modified = 'X'.
  ELSE.
    DELETE it_org         WHERE active <> 'X'.
  ENDIF.

  lt_org_combined[] = it_org[].
  APPEND LINES OF lt_org_current TO lt_org_combined .
  CLEAR lt_org_combined-modified.
  MODIFY lt_org_combined TRANSPORTING modified WHERE modified = 'X'.

  DELETE lt_org_current WHERE active <> 'X'.
  SORT : lt_org_current, it_org.
  SORT lt_org_combined BY abb varbl sysid value.
  DELETE ADJACENT DUPLICATES FROM lt_org_combined COMPARING
    abb varbl sysid value.
  LOOP AT lt_org_combined.
    CLEAR : lf_orig, lf_current.
*--Check if current
    READ TABLE lt_org_current WITH KEY
      abb    = lt_org_combined-abb
      varbl  = lt_org_combined-varbl
      sysid  = lt_org_combined-sysid
      value  = lt_org_combined-value.
*      active = lt_org_combined-active.
    IF sy-subrc = 0.
      lf_current = 'X'.
    ENDIF.
*--Check if in config set
    READ TABLE it_org WITH KEY
      abb    = lt_org_combined-abb
      varbl  = lt_org_combined-varbl
      sysid  = lt_org_combined-sysid
      value  = lt_org_combined-value.
    IF sy-subrc = 0.
      lf_orig = 'X'.
    ENDIF.
    IF lf_current <> lf_orig.
      gt_output-remsys    = gt_rfcdest-rfcoptions.
      gt_output-type      = 'ORG'.
      gt_output-type_text = 'Org Element'(t02).
      gt_output-orig      = lf_orig.
      gt_output-current   = lf_current.
      gt_output-abb       = lt_org_combined-abb.
      gt_output-name      = lt_org_combined-varbl.
      gt_output-system    = lt_org_combined-sysid.
      gt_output-value     = lt_org_combined-value.
      gt_output-setid     = ls_set-setid.
      gt_output-description = ls_set-description.
      APPEND gt_output.
      IF lf_orig = 'X'.
        ADD 1 TO g_org_orig_count.
        ADD 1 TO l_org_orig_count.
      ELSE.
        ADD 1 TO g_org_current_count.
        ADD 1 TO l_org_current_count.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " check_org_values
*&---------------------------------------------------------------------*
*&      Form  output_results_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM output_results_alv.
  DATA : lt_fcat TYPE slis_t_fieldcat_alv,
         ls_fcat TYPE slis_fieldcat_alv,
         ls_layout TYPE slis_layout_alv.

  DEFINE add_fcat.
    add 1 to ls_fcat-col_pos.
    ls_fcat-fieldname    = &1.
    ls_fcat-seltext_l    = &2.
    ls_fcat-seltext_m    = &2.
    ls_fcat-seltext_s    = &2.
    ls_fcat-reptext_ddic = &2.
    ls_fcat-checkbox     = &3.
    append ls_fcat to lt_fcat .
  END-OF-DEFINITION.

*--Create field catalog
  add_fcat :
    'REMSYS'     'Analyzed System'(t11) '',
    'SETID'      'Configuration Set ID'(H20) '',
    'DESCRIPTION' 'Configuration Set'(H21) '',
    'SYSTEM'     'System'(t09)          '',
    'ABB'        'Company Code'(t07)    '',
    'NAME'       'Name'(t08)            '',
    'VALUE'      'Value'(t10)           '',
    'ORIG'       'In Config Set'(t05)   'X',
    'CURRENT'    'Current'(t06)         'X',
    'TYPE'       'Type'(t03)            '',
    'TYPE_TEXT'  'Type Text'(t04)       ''  .

  ls_layout-colwidth_optimize = 'X'.
*--Show ALV
*--Output ALV
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page = 'ALV_HEADER'
            i_grid_title           = sy-title
            i_callback_program     = g_program
            it_fieldcat            = lt_fcat
            is_layout              = ls_layout
       TABLES
            t_outtab               = gt_output
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_results_alv

*---------------------------------------------------------------------*
*       FORM ALV_HEADER                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA :
    lt_header            TYPE slis_t_listheader,
    ls_header            TYPE slis_listheader.
  DEFINE add_alv_header.
    ls_header-typ  =  &1.
    ls_header-key  =  &2 .
    ls_header-info =  &3 .
    append ls_header to lt_header.
  END-OF-DEFINITION.
*  add_alv_header 'S' :
*  'Configuration Set ID'(h20) ls_set-setid,
*  'Configuration Set'(h21)    ls_set-description.

  IF NOT gt_output[] IS INITIAL.
    add_alv_header
    'H' ''
    'Current Configuration is different from Stored Set'(h01).
*--Overview of the differences
    add_alv_header 'S' :
      'New Org : '(h03)           g_org_current_count,
      'Removed Org'(h04)          g_org_orig_count,
      'New Var.Elem.:'(h05)       g_varel_current_count,
      'Removed Var.Elem.:'(h06)   g_varel_orig_count.
    add_alv_header 'A' ''
       'Updating the configuration set is advised.'(h07).
    IF gf_email_sent_global = 'X'.
      add_alv_header 'S' :
        'E-Mail Sent to : '(h11)   p_email.
    ENDIF.
  ELSE.
    add_alv_header
    'H' ''
    'Current Configuration is the same as Stored Set'(h02).
    add_alv_header 'A' ''
    'No action required.'(h08).

  ENDIF.
  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = lt_header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  send_email
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM send_email.
*--Text ID
* /PSYNG/SW_CONFIG_SET_COMPARE
  DATA :
  l_send_templ TYPE thead-tdname,
  l_css_temp TYPE dokhl-object,
  lt_headers TYPE TABLE OF /psyng/bc_tab_headers WITH HEADER LINE,
  l_subject TYPE so_obj_des,
  lt_htmlt TYPE /psyng/bc_html_data_t ,
  ls_htmlt TYPE /psyng/bc_html_data,
  lt_email_cont TYPE TABLE OF solisti1,
  ls_email_cont TYPE solisti1,
  l_tabstyle TYPE sylisel,
  lt_receivers TYPE TABLE OF /psyng/bc_userid_name
                    WITH HEADER LINE,
  l_central_sys   TYPE /psyng/param_value,
  l_systems TYPE string,
  l_man_change TYPE string,
  l_tabtitle TYPE text300,
  lt_adresses TYPE TABLE OF ad_smtpadr WITH HEADER LINE.
  l_send_templ  = '/PSYNG/SW_CONFIG_SET_COMPARE'.
  DEFINE header.
    add 1 to lt_headers-col_num .
    lt_headers-fld_name = &1.
    lt_headers-fld_txt  = &2.
    append lt_headers.
  END-OF-DEFINITION.
  DEFINE add_placeholder.
    ls_htmlt-placeholder = &1.
    ls_htmlt-text        = &2.
    append ls_htmlt to lt_htmlt.
  END-OF-DEFINITION.

  DATA : lt_cmp TYPE TABLE OF /psyng/swcfgcmp WITH HEADER LINE,
         lt_email LIKE TABLE OF gt_output WITH HEADER LINE,
         lv_uname TYPE syuname. "C0700
*--Check if we already informed someone by e-mail on this
  SELECT * FROM /psyng/swcfgcmp INTO TABLE lt_cmp
  WHERE remsys EQ gt_rfcdest-rfcoptions
    AND setid = ls_set-setid.
  SORT lt_cmp BY type orig curr sysid value.
  LOOP AT gt_output WHERE remsys EQ gt_rfcdest-rfcoptions.
    READ TABLE lt_cmp WITH KEY
      type = gt_output-type
      orig = gt_output-orig
      curr = gt_output-current
      sysid = gt_output-system
      value = gt_output-value
      BINARY SEARCH.
    IF sy-subrc = 0 AND lt_cmp-mail_sent = 'X'.
*--Don't send an e-mail again
    ELSE.
      APPEND gt_output TO lt_email.
    ENDIF.
  ENDLOOP.


*--Get configuration parameters
  se_config_param 'APPROVAL_CENTRAL_SYS'    l_central_sys.
  se_config_param 'CFGGSET_COMP_EMAIL' l_send_templ.
*  se_config_param 'CFGGSET_COMP_ADDR' p_email.
  PERFORM load_email_config.
  se_config_param 'SW_CSS_EMAIL' l_css_temp.

  IF NOT lt_email[] IS INITIAL.
*--Create system placeholder value
    LOOP AT lt_systems.
      IF NOT l_systems IS INITIAL.
        CONCATENATE l_systems ',' INTO  l_systems SEPARATED BY space.
      ENDIF.
      CONCATENATE l_systems
     lt_systems-sysid
      INTO
      l_systems
      SEPARATED BY space.
    ENDLOOP.
*--Create the manual changes placeholder
    IF p_igman = 'X'.
      l_man_change = 'Yes'(m01).
    ELSE.
      l_man_change = 'No'(m02).
    ENDIF.
*--Add the placeholders
    add_placeholder :
        '[CONFIG_SET]'             ls_set-setid,
        '[REMSYS]'                 gt_rfcdest-rfcoptions,
        '[SYSTEMS]'                l_systems,
        '[CONFIG_SET_DESCRIPTION]' ls_set-description,
        '[ORG_NEW]'                l_org_current_count,
        '[ORG_IN_SET]'             l_org_orig_count,
        '[VAREL_NEW]'              l_varel_current_count,
        '[VAREL_IN_SET]'           l_varel_orig_count,
        '[MANUAL_IGNORED]'         l_man_change.

*--Add the table
    header :
       'SYSTEM'     'System'(t09)          ,
       'ABB'        'Company Code'(t07)    ,
       'NAME'       'Name'(t08)            ,
       'VALUE'      'Value'(t10)           ,
       'ORIG'       'In Config Set'(t05)   ,
       'CURRENT'    'Current Customizing'(t06),
       'TYPE'       'Type'(t03)            ,
       'TYPE_TEXT'  'Type Text'(t04)       .
    CONCATENATE
 'Current Customizing is different from Stored Configuration set'(h01)
   ls_set-setid INTO l_tabtitle SEPARATED BY space.
    ls_htmlt-placeholder = '[COMPARISON_TABLE]'.
    ls_htmlt-tag         = 'TABLE'.
    l_tabstyle = 'class="table" style="width:99%"'.
    CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
         EXPORTING
              attributes = l_tabstyle
              long_title = l_tabtitle
         TABLES
              i_headers  = lt_headers
              et_data    = ls_htmlt-html_table
              i_table    = lt_email.

    APPEND ls_htmlt TO lt_htmlt.
*--Create the HTML e-mail, but don't send it
    REFRESH : lt_receivers.
* BOC by RGUPTA for C0700
*    lt_receivers-bname = sy-uname.
    CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = lv_uname.
    lt_receivers-bname = lv_uname.
* EOC by RGUPTA for C0700
    APPEND lt_receivers.

    CALL FUNCTION '/PSYNG/BC_HTML_EMAIL'
         EXPORTING
              header        = 'X'
              style         = l_css_temp "'/PSYNG/BC_EMAIL_CSS'
              template_name = l_send_templ
              auto_subject  = 'X'
              if_send_email = ''  "don't send the e-mail
         IMPORTING
              e_subject     = l_subject
         TABLES
              et_data       = lt_email_cont
              it_recipients = lt_receivers
         CHANGING
              it_data       = lt_htmlt.
*--prepare list of recipients
    SPLIT p_email AT ',' INTO TABLE lt_adresses.
    DELETE lt_adresses WHERE table_line IS INITIAL.
    IF lt_adresses[] IS INITIAL AND NOT p_email IS INITIAL.
      lt_adresses = p_email.
      APPEND lt_adresses.
    ENDIF.
    IF NOT lt_adresses[] IS INITIAL.
      LOOP AT lt_adresses.
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
        CALL FUNCTION '/PSYNG/BC_036'
        DESTINATION l_central_sys
        EXPORTING
           i_subject                        = l_subject
           i_sensitivity                    = ''
           i_receiver                       = lt_adresses
          TABLES
            lt_body                         = lt_email_cont
         EXCEPTIONS
           SYSTEM_FAILURE                   = 1
           COMMUNICATION_FAILURE            = 2
           error_sending_email              = 3
           too_many_receivers               = 4
           document_not_sent                = 5
           document_type_not_exist          = 6
           operation_no_authorization       = 7
           parameter_error                  = 8
           x_error                          = 9
           enqueue_error                    = 10
           OTHERS                           = 11."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
        IF sy-subrc <> 0.
          MESSAGE e002(/psyng/sw) WITH
          'Sending E-mail failed. /PSYNG/BC_036 - subrc = ' sy-subrc
          'for analyzed system'(t13)
          gt_rfcdest-rfcoptions..
        ELSE.
          MESSAGE s002(/psyng/sw) WITH 'E-Mail sent to  : ' p_email
          'for analyzed system'(t13)
          gt_rfcdest-rfcoptions.
          gf_email_sent = 'X'.
          gf_email_sent_global = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.
    IF gf_email_sent = 'X'.
*  --Store the information that we emailed about
      REFRESH lt_cmp.
      LOOP AT lt_email.
        lt_cmp-remsys = gt_rfcdest-rfcoptions.
        lt_cmp-setid = ls_set-setid.
        lt_cmp-type  = lt_email-type.
        lt_cmp-orig  = lt_email-orig.
        lt_cmp-curr  = lt_email-current.
        lt_cmp-sysid = lt_email-system.
        lt_cmp-value = lt_email-value.
        lt_cmp-date_identified = sy-datum.
        lt_cmp-time_identified = sy-uzeit.
        lt_cmp-mail_sent = 'X'.
        APPEND lt_cmp.
      ENDLOOP.
      MODIFY /psyng/swcfgcmp FROM TABLE lt_cmp.
      COMMIT WORK.

    ENDIF.
  ELSE.
    MESSAGE s002(/psyng/sw) WITH
    'Current Configuration is the same as Stored Set'(h02)
    'for analyzed system'(t13)
     gt_rfcdest-rfcoptions.
    MESSAGE s002(/psyng/sw) WITH
    'No E-Mail sent'
    'for analyzed system'(t13)
    gt_rfcdest-rfcoptions.
  ENDIF.

ENDFORM.                    " send_email
*---------------------------------------------------------------------*
*       FORM get_next_variant_id                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_next_variant_id.
  DATA: oldnumber(7) TYPE n, oldnumber_c(7).

  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
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

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.

ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  RFC_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations CHANGING e_continue TYPE flag.
  DATA: lr_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
        WITH HEADER LINE,
        lt_bapiret TYPE TABLE OF bapiret2.
  APPEND LINES OF s_system TO lr_rfcs.

  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup    = 'X'
      i_module   = 'SE'
    IMPORTING
      e_continue = e_continue
    TABLES
      it_rfcdes  = lr_rfcs.
ENDFORM.
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
