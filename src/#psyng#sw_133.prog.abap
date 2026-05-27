*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_133
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT  /psyng/sw_133 MESSAGE-ID /psyng/sw
  LINE-SIZE 132."#EC SAST_CI_GEN_CHECK
TABLES:
  /psyng/mcrvwsgn, /psyng/sw_mc_review_report,rfcdes,
  /psyng/ex_caobj_lock.
DATA : l_appl TYPE /psyng/application,

       gt_messages TYPE TABLE OF bapiret2 WITH HEADER LINE,
       lt_mc_summary TYPE SORTED TABLE OF /psyng/sw_mit_exp_summary
       WITH UNIQUE KEY contid conid swaudid
       WITH HEADER LINE,
       ls_mc_summary TYPE /psyng/sw_mit_exp_summary,
       ls_range_bname TYPE /psyng/range_bname,
       gt_expired  TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
       g_exit_proc TYPE flag,
       g_program         LIKE sy-repid,
       g_curr_variant LIKE  rsvar-variant,
       g_vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      g_vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      g_vari_text LIKE varit OCCURS 0 WITH HEADER LINE,
      g_variant LIKE vari-variant,
      gf_sp_installed type flag.
FIELD-SYMBOLS : <summary> TYPE /psyng/sw_mit_exp_summary.
INCLUDE /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
*INCLUDE /psyng/sw_125.


*--Actions
SELECTION-SCREEN: BEGIN OF BLOCK b3 WITH FRAME TITLE text-t03.
PARAMETERS :
  p_exp TYPE flag DEFAULT 'X',
  p_sgn TYPE flag DEFAULT 'X'.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN : POSITION 4.
PARAMETERS : p_arv TYPE flag DEFAULT 'X' .
SELECTION-SCREEN COMMENT 6(40) text-arv    .
SELECTION-SCREEN: END OF LINE.
PARAMETERS :  p_eml TYPE flag DEFAULT 'X'.
SELECTION-SCREEN: END OF BLOCK b3.


*--Reviewer Selection
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-t01.
PARAMETERS :
  p_sod TYPE /psyng/sodvrsio MEMORY ID /psyng/vrsio.
SELECT-OPTIONS:
  s_rev FOR /psyng/mcrvwsgn-auditor,
*  s_per FOR /psyng/mcrvwsgn-from_date,
  s_mit FOR /psyng/mcrvwsgn-contid.
SELECTION-SCREEN: END OF BLOCK b1.
*--Assignment Selection
SELECTION-SCREEN: BEGIN OF BLOCK b2 WITH FRAME TITLE text-t02.
SELECT-OPTIONS: s_uas FOR /psyng/mcrvwsgn-userid,
                s_ras FOR /psyng/mcrvwsgn-agr_name,
                s_cus FOR /psyng/mcrvwsgn-userid,
                s_crs FOR /psyng/mcrvwsgn-agr_name.
SELECTION-SCREEN: END OF BLOCK b2.
*--Scope
SELECTION-SCREEN: BEGIN OF BLOCK b4 WITH FRAME TITLE text-t04.
*---Remote Block
SELECTION-SCREEN: BEGIN OF BLOCK rem_o WITH FRAME   TITLE text-t05.
*  --Conflict origin
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(20) text-170    MODIF ID rem.
SELECTION-SCREEN : POSITION 22.
PARAMETERS : p_local TYPE flag DEFAULT 'X' MODIF ID rem.
SELECTION-SCREEN COMMENT 24(10) text-173 FOR FIELD p_local
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 35.
PARAMETERS : p_remote TYPE flag DEFAULT ' '
                                           MODIF ID rem.
SELECTION-SCREEN COMMENT 37(10) text-174 FOR FIELD p_remote
                                           MODIF ID rem.
SELECTION-SCREEN : POSITION 49.
PARAMETERS : p_cross TYPE flag DEFAULT ' ' MODIF ID rem.
SELECTION-SCREEN COMMENT 51(20) text-175 FOR FIELD p_cross
                                           MODIF ID rem.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN : POSITION 04.
PARAMETERS : p_locusr AS CHECKBOX          MODIF ID rem.
SELECTION-SCREEN COMMENT 8(45) text-162 FOR FIELD p_locusr
                                           MODIF ID rem.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
*  Only analyze remote systems
SELECTION-SCREEN : POSITION 04.
PARAMETERS : p_remonl AS CHECKBOX USER-COMMAND remo
                                           MODIF ID rem.
SELECTION-SCREEN COMMENT 8(45) text-179 FOR FIELD p_remonl
                                           MODIF ID rem.
SELECTION-SCREEN END OF LINE.

PARAMETERS p_abap AS CHECKBOX USER-COMMAND abap DEFAULT 'X'
                                   MODIF ID rem."EN.

SELECT-OPTIONS: xusrrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.

PARAMETERS p_nabap AS CHECKBOX USER-COMMAND abap MODIF ID rem."EN.
SELECT-OPTIONS: s_appl FOR l_appl
MATCHCODE OBJECT
/psyng/ex_application
MODIF ID rem."EN.

SELECT-OPTIONS: s_system FOR /psyng/ex_caobj_lock-sysid
MATCHCODE OBJECT
/psyng/ex_system
MODIF ID rem."EN
SELECTION-SCREEN: END OF BLOCK rem_o.


SELECTION-SCREEN: BEGIN OF BLOCK b5 WITH FRAME TITLE text-t06.
PARAMETERS:
 orgchk             AS CHECKBOX DEFAULT ' ',
 p_enhanc           AS CHECKBOX DEFAULT ' ',
 erroles            AS CHECKBOX DEFAULT ' ' ,
 excl_er            AS CHECKBOX DEFAULT ' ',
 ignsp    type flag as checkbox.


SELECTION-SCREEN: END OF BLOCK b5.

SELECTION-SCREEN: END OF BLOCK b4.


*--Scheduling Block
SELECTION-SCREEN: BEGIN OF BLOCK cblk WITH FRAME TITLE text-001.
SELECTION-SCREEN PUSHBUTTON  4(30) text-010 USER-COMMAND scjb.
SELECTION-SCREEN PUSHBUTTON  40(25) text-009 USER-COMMAND sm37.
SELECTION-SCREEN: END OF BLOCK cblk.

INITIALIZATION.
  g_program = sy-repid.
*--Check if SP is installed
CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
 EXPORTING
   I_MODULE               = 'SP'
 IMPORTING
   E_INSTALLED            = gf_sp_installed.

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



AT SELECTION-SCREEN OUTPUT.
  DATA:
        g_installed TYPE /psyng/bapiflagx,
        g_module_version TYPE  /psyng/prog_vrsio,
        g_swconfig TYPE /psyng/swconfig.

*--Check if ER is installed/ deactivate ER buttons
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'ER'
       IMPORTING
            e_installed      = g_installed
            e_module_version = g_module_version.
  IF g_installed <> 'X' OR g_module_version < '3.0'.
    LOOP AT SCREEN.
      IF screen-name = 'ERROLES' OR screen-name = 'EXCL_ER'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.
  CLEAR : g_installed, g_module_version.


*-- Check if EN is installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
       EXPORTING
            i_module         = 'EN'
       IMPORTING
            e_installed      = g_installed
            e_module_version = g_module_version.
  LOOP AT SCREEN.
    IF g_installed <> 'X'.
      IF screen-name = 'P_NABAP' OR
       screen-name = '%_P_NABAP_%_APP_%-TEXT'
      OR screen-name = 'S_APPL-LOW'
      OR screen-name = 'S_APPL-HIGH'
      OR screen-name = '%_S_APPL_%_APP_%-TEXT'
      OR screen-name =  '%_S_APPL_%_APP_%-VALU_PUSH'
      OR screen-name =  '%_S_SYSTEM_%_APP_%-TEXT'
      OR screen-name = 'S_SYSTEM-LOW'
      OR screen-name = 'S_SYSTEM-HIGH'
      OR screen-name = '%_S_SYSTEM_%_APP_%-VALU_PUSH'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
     IF screen-name = 'IGNSP'.
        if gf_sp_installed = 'X'.
          screen-invisible = 0.
          screen-active    = 1.
        else.
           screen-invisible = 1.
           screen-active    = 0.
         endif.
         modify screen.
     endif.
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
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
    SUBMIT (g_program) "#EC PATHLOCK_CI_DYN_ACCES
*    SUBMIT /PSYNG/SW_133
*EOC UMITTAL SE VF scan changes-25/11/2024
            VIA SELECTION-SCREEN
            USING SELECTION-SET g_curr_variant .
  ENDIF.

  exelog sy-repid ''.

*--Expire the Obsolete Mitigations
  IF p_exp = 'X'.
    PERFORM handle_mit_expiration.
  ENDIF.
*--Create the signoff records
  IF p_sgn = 'X'.
    CALL FUNCTION '/PSYNG/SW_MC_CREATE_SIGNOFF'
         EXPORTING
              i_validity_date = sy-datum
              i_vrsio         = p_sod
              if_test         = ''
              if_auto_signoff = p_arv
         TABLES
              it_contid       = s_mit
              it_soduser      = s_uas
              it_causer       = s_cus
              it_sodrole      = s_ras
              it_carole       = s_crs
              et_messages     = gt_messages.
  ENDIF.
*--Send E-Mails for Pending Reviews
  IF p_eml = 'X'.
    CALL FUNCTION '/PSYNG/SW_MC_SEND_SIGNOFF_MAIL'
         TABLES
              it_mcid     = s_mit
              it_auditors = s_rev
              et_messages = gt_messages.

  ENDIF.
  loop at gt_messages.
    MESSAGE s002 WITH gt_messages-message gt_messages-message_v1 gt_messages-message_v2 gt_messages-message_v3.
  endloop.
  MESSAGE s002 WITH 'Mitigation Review Scheduler Completed'(s01).



*&---------------------------------------------------------------------*
*&      Form  expire_obsolete_mitigations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_MC_SUMMARY  text
*----------------------------------------------------------------------*
FORM expire_obsolete_mitigations
  USING    is_mc_summary TYPE /psyng/sw_mit_exp_summary.
  DATA : lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE,
         ls_range_bname TYPE /psyng/range_bname.
  DEFINE add_e_param.
    lt_iseltab-kind    = &1.
    lt_iseltab-sign    = &2.
    lt_iseltab-option  = &3.
    lt_iseltab-selname = &4.
    lt_iseltab-low     = &5.
    lt_iseltab-high    = &6.
    append lt_iseltab.
  END-OF-DEFINITION.
*--Fill the selection screen table
  add_e_param     'S' 'I' 'EQ' 'CONTID'  is_mc_summary-contid  ''.
  IF NOT is_mc_summary-conid IS INITIAL.
    add_e_param   'S' 'I' 'EQ' 'CONID'   is_mc_summary-conid   ''.
    add_e_param   'P' 'I' 'EQ' 'SODCON'  'X'                   ''.
    add_e_param   'P' 'I' 'EQ' 'CRIAUT'  ''                    ''.
  ELSE.
    add_e_param   'S' 'I' 'EQ' 'SWAUDID' is_mc_summary-swaudid ''.
    add_e_param   'P' 'I' 'EQ' 'CRIAUT'  'X'                   ''.
    add_e_param   'P' 'I' 'EQ' 'SODCON'  ''                    ''.
  ENDIF.
  add_e_param
        'P' 'I' 'EQ' :
        'P_ABAP'    p_abap    '',
        'P_NABAP'   p_nabap   '',
        'P_CROSS'   p_cross   '',
        'P_ENHANC'  p_enhanc  '',
        'P_LOCAL'   p_local   '',
        'P_LOCUSER' p_locusr  '',
        'P_REMONL'  p_remonl  '',
        'P_REMOTE'  p_remote  '',
        'ORGCHK'    orgchk    '',
        'OBSCHECK'  'X'       '',
        'OBSEXP'    'X'       '',
        'NO_DISP'   'X'       '',
        'SODVRSIO'  p_sod     '',
        'IGNSP'     IGNSP     ''.

  LOOP AT is_mc_summary-users INTO ls_range_bname.
    add_e_param
    'S' ls_range_bname-sign
        ls_range_bname-option
        'USERID'
        ls_range_bname-low ls_range_bname-high.
  ENDLOOP.

  LOOP AT xusrrfc.
    add_e_param
    'S' xusrrfc-sign xusrrfc-option 'XUSRRFC' xusrrfc-low xusrrfc-high.
  ENDLOOP.
  LOOP AT s_appl.
    add_e_param
    'S' s_appl-sign s_appl-option 'S_APPL' s_appl-low s_appl-high.
  ENDLOOP.
  LOOP AT s_system.
    add_e_param
    'S' s_system-sign s_system-option 'S_SYSTEM' s_system-low
    s_system-high.
  ENDLOOP.


  SUBMIT /psyng/sw_105 WITH SELECTION-TABLE lt_iseltab AND RETURN.


ENDFORM.                    " expire_obsolete_mitigations
*&---------------------------------------------------------------------*
*&      Form  handle_mit_expiration
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_mit_expiration.
DATA : lt_signoff_before TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
       lt_signoff_after  TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
           l_reference_date  TYPE dats.
*--Do a test run of creating the Signoff Records, for each record that
*  would be created, we'll check if the Assignment isn't obsolete, if so
* it gets expired.
  CALL FUNCTION '/PSYNG/SW_MC_CREATE_SIGNOFF'
       EXPORTING
            i_validity_date = sy-datum
            i_vrsio         = p_sod
            if_test         = 'X'
            if_auto_signoff = ''
       TABLES
            it_contid       = s_mit
            it_soduser      = s_uas
            it_causer       = s_cus
            it_sodrole      = s_ras
            it_carole       = s_crs
            et_messages     = gt_messages
            et_signoff      = lt_signoff_before.

*--Get the records of lt_signoff_test, for each
* unique Mitigation ID -  Conflict or CA combination,
* call the expire mitigations report
* for all users that are mitigated.
*  For mitigations assigned via roles or usergroups, this won't have any
*  effect, so we don't include these
  ls_range_bname-sign   = 'I'.
  ls_range_bname-option = 'EQ'.
  LOOP AT lt_signoff_before WHERE NOT userid = ''."#EC SAST_CI_GEN_CHECK
    check lt_signoff_before-type = 1 or  "assigned to conflict for user
          lt_signoff_before-type = 3.    "assigned to CA for user.

    CLEAR ls_mc_summary.
    MOVE-CORRESPONDING lt_signoff_before TO ls_mc_summary.
    ls_range_bname-low = lt_signoff_before-userid.
    READ TABLE lt_mc_summary WITH TABLE KEY
      contid  = lt_signoff_before-contid
      conid   = lt_signoff_before-conid
      swaudid = lt_signoff_before-swaudid
      ASSIGNING <summary>.
    IF sy-subrc = 0.
      APPEND ls_range_bname TO <summary>-users[].
    ELSE.
      APPEND ls_range_bname TO ls_mc_summary-users[].
      INSERT ls_mc_summary INTO TABLE lt_mc_summary.
    ENDIF.
  ENDLOOP.
*--Call the report to do the expiration per unique combination
  LOOP AT lt_mc_summary.
    PERFORM expire_obsolete_mitigations
      USING lt_mc_summary.
  ENDLOOP.
*--Get the list of records to create signoff's for again
*  so we can add the list of expired mitigations to the output.
  l_reference_date = sy-datum + 1.
  CALL FUNCTION '/PSYNG/SW_MC_CREATE_SIGNOFF'
       EXPORTING
            i_validity_date = l_reference_date
            i_vrsio         = p_sod
            if_test         = 'X'
            if_auto_signoff = ''
       TABLES
            it_contid       = s_mit
            it_soduser      = s_uas
            it_causer       = s_cus
            it_sodrole      = s_ras
            it_carole       = s_crs
            et_messages     = gt_messages
            et_signoff      = lt_signoff_after.

  SORT :
    lt_signoff_before
      BY contid
         vrsio
         type
         userid
         class
         agr_name
         conid
         swaudid,
    lt_signoff_after
      BY contid
         vrsio
         type
         userid
         class
         agr_name
         conid
         swaudid.
*--Find which assignments are expired, and add to table gt_expired.
  LOOP AT lt_signoff_before.
    READ TABLE lt_signoff_after WITH KEY
      contid   = lt_signoff_before-contid
      vrsio    = lt_signoff_before-vrsio
      type     = lt_signoff_before-type
      userid   = lt_signoff_before-userid
      class    = lt_signoff_before-class
      agr_name = lt_signoff_before-agr_name
      conid    = lt_signoff_before-conid
      swaudid  = lt_signoff_before-swaudid
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
*--No longer exists, so expired
      APPEND lt_signoff_before TO gt_expired.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " handle_mit_expiration
*&---------------------------------------------------------------------*
*&      Form  schedule_background
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_background.
  DATA: curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob,
        lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  CLEAR: curr_report, g_curr_variant.
  PERFORM get_next_variant_id.
  perform fill_sel_screen_job tables lt_iseltab.
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
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
form fill_sel_screen_job
  tables it_iseltab structure  rsparams.
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
    'ERROLES'   ERROLES   '',
    'EXCL_ER'   EXCL_ER   '',
    'ORGCHK'    ORGCHK    '',
    'P_ABAP'    P_ABAP    '',
    'P_ARV'     P_ARV     '',
    'P_CROSS'   P_CROSS   '',
    'P_EML'     P_EML     '',
    'P_ENHANC'  P_ENHANC  '',
    'P_EXP'     P_EXP     '',
    'P_LOCAL'   P_LOCAL   '',
    'P_LOCUSR'  P_LOCUSR  '',
    'P_NABAP'   P_NABAP   '',
    'P_REMONL'  P_REMONL  '',
    'P_REMOTE'  P_REMOTE  '',
    'P_SGN'     P_SGN     '',
    'P_SOD'     P_SOD     ''.
*--Add select options
  add_e_selopt :
    S_APPL   'S_APPL',
    S_CRS    'S_CRS',
    S_CUS    'S_CUS',
    S_MIT    'S_MIT',
    S_RAS    'S_RAS',
    S_SYSTEM 'S_SYSTEM',
    S_UAS    'S_UAS',
    XUSRRFC  'XUSRRFC'.
endform.                    " fill_sel_screen_job
