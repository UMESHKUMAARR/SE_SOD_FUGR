*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_MITIGATION_MONITOR
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*


REPORT /psyng/sw_mitigation_monitor.
TYPE-POOLS: sapwl .
INCLUDE /psyng/basis_exelog.
TABLES: /psyng/mchistxn, /psyng/mchisrpt,
         /psyng/mcrepid, /psyng/mctran.
DATA: gt_iusr02       TYPE STANDARD TABLE OF usr02 WITH HEADER LINE,
      gf_missing_auth TYPE flag,
      BEGIN OF usrtcode OCCURS 0,
        bname         LIKE usr02-bname,
        tcode         LIKE /psyng/mctran-tcode,
      END OF usrtcode,
      BEGIN OF usrreport OCCURS 0,
        bname         LIKE usr02-bname,
        programm      LIKE rs38m-programm,
      END OF usrreport,
      BEGIN OF mcrpth OCCURS 0.
        INCLUDE STRUCTURE /psyng/mchisrpt.
DATA: END OF mcrpth,
      BEGIN OF mctxnh OCCURS 0.
        INCLUDE STRUCTURE /psyng/mchistxn.
DATA: END OF mctxnh,
      g_all_stats      TYPE sapwl_allstats,
      g_wa_stats       TYPE LINE OF sapwl_allstats,
     g_program         LIKE sy-repid,
      g_curr_variant   LIKE rsvar-variant,
      g_vari_desc      TYPE varid OCCURS 0 WITH HEADER LINE,
      g_vari_contents  LIKE rsparams OCCURS 0 WITH HEADER LINE,
      g_vari_text      LIKE varit OCCURS 0 WITH HEADER LINE,
      g_variant        LIKE vari-variant,
      g_exit_proc      TYPE flag.


PARAMETERS: pdate LIKE sy-datum.
SELECTION-SCREEN: SKIP 1.
PARAMETERS: pupdate AS CHECKBOX.
PARAMETERS: sodvrsio TYPE /psyng/sodvrsio.


*--Scheduling Block
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-001.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.



INITIALIZATION.
  PERFORM initialization.


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
    g_exit_proc = 'Y'.
    PERFORM schedule_background.
  ENDIF.


START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /PSYNG/SW_MITIGATION_MONITOR
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.

  exelog sy-repid ''.


  CLEAR:gf_missing_auth.
  PERFORM get_mc_users.
  PERFORM get_stats.
  IF pupdate = 'X'.
    PERFORM update_hist_table.
  ENDIF.
  IF gf_missing_auth = 'X'.
*  **SF 1665
    MESSAGE s398(00) WITH
*      'Analysis Complete.'(083)
        'Missing some user authorizations'(084).
  ENDIF.
*************************************
*&---------------------------------------------------------------------*
*&      Form  get_mc_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_mc_users.
  DATA: l_contid  TYPE /psyng/mcuser-contid,
        l_auditor TYPE /psyng/mcuser-auditor.


  REFRESH usrtcode.
  SELECT contid auditor INTO (l_contid, l_auditor)
         FROM /psyng/mcuser
         WHERE vrsio = sodvrsio.
************************************************
**SF 1665
**Authorization check for Displaying SW Mitigations
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'       FIELD '03'
             ID 'Y&SW_CNTID'  FIELD l_contid
             ID 'Y&SW_VRSIO'  FIELD sodvrsio.
    IF sy-subrc EQ 0.
**SF 1665
**************************************************
      PERFORM get_mc_data USING l_contid l_auditor.
** **SF 1665
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
**************************************************

  ENDSELECT.

  SELECT contid auditor INTO (l_contid, l_auditor)
         FROM /psyng/mcauditor.
************************************************
**SF 1665
**Authorization check for Displaying SW Mitigations
    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'       FIELD '3'
             ID 'Y&SW_CNTID'  FIELD l_contid
             ID 'Y&SW_VRSIO'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    IF sy-subrc EQ 0.
**SF 1665
**************************************************
      PERFORM get_mc_data USING l_contid l_auditor.
** **SF 1665
    ELSE.
      gf_missing_auth = 'X'.
    ENDIF.
**************************************************
  ENDSELECT.

  SORT usrtcode.
  DELETE ADJACENT DUPLICATES FROM usrtcode.
  SORT usrreport.
  DELETE ADJACENT DUPLICATES FROM usrreport.
  SORT gt_iusr02.
  DELETE ADJACENT DUPLICATES FROM gt_iusr02.


ENDFORM.                    " get_mc_users

*&---------------------------------------------------------------------*
*&      Form  get_mc_data
*&---------------------------------------------------------------------*
*       Get Mitigating Control transactions and reports
*----------------------------------------------------------------------*
*      -->I_CONTID   Mitigating Control ID
*      -->I_AUDITOR  Auditor ID
*----------------------------------------------------------------------*
FORM get_mc_data USING    i_contid TYPE /psyng/mcuser-contid
                          i_auditor TYPE /psyng/mcuser-auditor.

  gt_iusr02-bname = i_auditor.
  APPEND gt_iusr02.

  SELECT * FROM /psyng/mcrepid INTO /psyng/mcrepid   "#EC CI_SEL_NESTED
         WHERE contid = i_contid.
    CLEAR usrreport.
    MOVE i_auditor TO usrreport-bname.
    MOVE /psyng/mcrepid-repid TO usrreport-programm.
    APPEND usrreport.
  ENDSELECT.

  SELECT * FROM /psyng/mctran INTO /psyng/mctran     "#EC CI_SEL_NESTED
         WHERE contid = i_contid.
    CLEAR usrtcode.
    MOVE i_auditor TO usrtcode-bname.
    MOVE /psyng/mctran-tcode TO usrtcode-tcode.
    APPEND usrtcode.
  ENDSELECT.
ENDFORM.                    " get_mc_data

*&---------------------------------------------------------------------*
*&      Form  get_stats.
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_stats.

  LOOP AT gt_iusr02.
  MESSAGE s002(/psyng/sw) WITH
  'Loading User History' pdate gt_iusr02-bname  .
  commit work.
    REFRESH: g_all_stats.
    CALL FUNCTION 'SAPWL_READ_STATISTIC_FILES'
         EXPORTING
      read_client     = sy-mandt "#EC SAST_CI_GEN_CHECK (HBHALLA)
      read_time       = '240000'
      read_time_delta = '000200'
      read_start_time = '000000'
      read_start_date = pdate
      read_username   = gt_iusr02-bname
         CHANGING
              all_stats       = g_all_stats.
    LOOP AT g_all_stats INTO g_wa_stats.

      IF g_wa_stats-record-tcode > space.
        LOOP AT usrtcode WHERE bname = g_wa_stats-record-account
        AND tcode =  g_wa_stats-record-tcode.
          mctxnh-tcode = g_wa_stats-record-tcode.
          mctxnh-bname = g_wa_stats-record-account.
          mctxnh-xdate = g_wa_stats-record-date.
          APPEND mctxnh.
        ENDLOOP.
      ENDIF.

      IF g_wa_stats-record-report > space.

        LOOP AT usrreport WHERE bname = g_wa_stats-record-account
        AND  programm = g_wa_stats-record-report.
          mcrpth-repid = g_wa_stats-record-report.
          mcrpth-bname = g_wa_stats-record-account.
          mcrpth-xdate = g_wa_stats-record-date.
          APPEND mcrpth.
        ENDLOOP.
      ENDIF.
*

    ENDLOOP.

  ENDLOOP.


ENDFORM.                    " get_stats.

*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialization.
  g_program = sy-repid.
  pdate = sy-datum - 1.
ENDFORM.                    " initialization
*&---------------------------------------------------------------------*
*&      Form  update_hist_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM update_hist_table.
  MESSAGE s002(/psyng/sw) WITH
  'Storing User History'  pdate .
  commit work.
  SORT mctxnh.
  DELETE ADJACENT DUPLICATES FROM mctxnh.
  SORT mcrpth.
  DELETE ADJACENT DUPLICATES FROM mcrpth.
  MODIFY /psyng/mchistxn FROM TABLE mctxnh.
  IF sy-subrc = 0.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
  ENDIF.
  MODIFY /psyng/mchisrpt FROM TABLE mcrpth.
  IF sy-subrc = 0.
    COMMIT WORK.
  ELSE.
    ROLLBACK WORK.
  ENDIF.

ENDFORM.                    " update_hist_table
*---------------------------------------------------------------------*
*       FORM schedule_background                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM schedule_background.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob,
        lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  CLEAR: curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_job TABLES lt_iseltab.
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

  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ELSE.
    l_jobname = text-041.
    CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
         EXPORTING
              in_jobname  = l_jobname
              in_repvarnt = g_curr_variant
              in_report   = curr_report.
    IF sy-subrc <> 0.
      CALL SCREEN 1000.
    ENDIF.
  ENDIF.

ENDFORM.                    " schedule_background


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

*---------------------------------------------------------------------*
*       FORM fill_sel_screen_job                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_ISELTAB                                                    *
*---------------------------------------------------------------------*
FORM fill_sel_screen_job
  TABLES it_iseltab STRUCTURE  rsparams.
  DEFINE add_e_param.
    it_iseltab-kind    = &1.
    it_iseltab-sign    = &2.
    it_iseltab-option  = &3.
    it_iseltab-selname = &4.
    it_iseltab-low     = &5.
    it_iseltab-high    = &6.
    append it_iseltab.
  END-OF-DEFINITION.
  DEFINE add_e_selopt.
    loop at &1.
      it_iseltab-kind    = 'S'.
      it_iseltab-sign    = &1-sign.
      it_iseltab-option  = &1-option.
      it_iseltab-selname = &2.
      it_iseltab-low     = &1-low.
      it_iseltab-high    = &1-high.
      append it_iseltab.
    endloop.
  END-OF-DEFINITION.
*--Add parameters
  add_e_param  'P' 'I' 'EQ' :
    'PDATE'     pdate    '',
    'PUPDATE'   pupdate  '',
    'SODVRSIO'  sodvrsio ''.
ENDFORM.                    " fill_sel_screen_job
