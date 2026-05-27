*----------------------------------------------------------------------*
* Report  /PSYNG/SW_091                                                *
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
REPORT /psyng/sw_091 MESSAGE-ID /psyng/sw NO STANDARD PAGE HEADING.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

TABLES: /psyng/mcauditor, /psyng/mcuser,usr02.

DATA: gt_hist     TYPE TABLE OF /psyng/mchistmon WITH HEADER LINE,
      gt_tran     TYPE TABLE OF /psyng/mctran    WITH HEADER LINE,
      gt_repid    TYPE TABLE OF /psyng/mcrepid   WITH HEADER LINE,
      gt_mcuser   TYPE TABLE OF /psyng/mcuser    WITH HEADER LINE,
      gt_mcusrgrp TYPE TABLE OF /psyng/mcusrgrp  WITH HEADER LINE,
      gt_mchdr    TYPE TABLE OF /psyng/mchdr     WITH HEADER LINE,
      gt_userinfo TYPE TABLE OF /psyng/sw_uinfo  WITH HEADER LINE,
      gt_frequency TYPE TABLE OF /psyng/sw_freq WITH HEADER LINE.

DATA: BEGIN OF gt_auditor OCCURS 0,
        auditor TYPE /psyng/mcauditor-auditor,
        contid  TYPE /psyng/mcauditor-contid,
        company type USCOMP,
      END OF gt_auditor.

DATA: BEGIN OF gt_output OCCURS 0,
        contid  TYPE /psyng/mcrepid-contid,
        type(1) TYPE c,
        repid   TYPE /psyng/mcrepid-repid,
        auditor TYPE /psyng/mcauditor-auditor,
      END OF gt_output.

SELECTION-SCREEN BEGIN OF BLOCK blk1 WITH FRAME TITLE text-t01.
SELECT-OPTIONS: s_contid FOR  gt_mchdr-contid,
                s_auditr FOR /psyng/mcauditor-auditor,
                s_class  FOR usr02-class,
                s_comp   FOR /psyng/mcauditor-company,
                s_vrsio  FOR /psyng/mcuser-vrsio.

*               s_rfc    FOR
SELECTION-SCREEN SKIP.
PARAMETERS: p_assgnd AS CHECKBOX USER-COMMAND assgnd.
PARAMETERS: p_bycomp AS CHECKBOX modif id COM.
SELECTION-SCREEN END OF BLOCK blk1.

SELECTION-SCREEN BEGIN OF BLOCK blk2 WITH FRAME TITLE text-t02.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_email AS CHECKBOX.
SELECTION-SCREEN: COMMENT 3(75) text-000 FOR FIELD p_email.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(75) text-001.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN SKIP.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_wrkflw AS CHECKBOX.
SELECTION-SCREEN: COMMENT 3(75) text-002 FOR FIELD p_wrkflw.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(75) text-003.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN SKIP.
PARAMETERS: p_log  AS CHECKBOX,
            p_test AS CHECKBOX.
SELECTION-SCREEN END OF BLOCK blk2.

*-------------------------- INITIALIZATION ----------------------------*
INITIALIZATION.
  PERFORM exelog.

*------------------------ AT SELECTION-SCREEN -------------------------*
AT SELECTION-SCREEN OUTPUT.
*--The "By Company" checkbox is only relevant when e-mails are being
*  sent to the auditors in the assignment.
    loop at screen.
      if screen-group1 = 'COM'.
        if p_assgnd = 'X'.
          screen-input  = 0.
*          screen-active = 0.

          p_bycomp = ''.
        else.
          screen-input  = 1.
*          screen-active = 1.
        endif.
        modify screen.
      endif.
    endloop.

*------------------------- START-OF-SELECTION -------------------------*
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
  IF p_email = 'X'.
    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'SENDMCEM'.
    IF sy-subrc <> 0.
      MESSAGE e108 WITH text-e02.
    ENDIF.
  ENDIF.

  IF p_wrkflw = 'X'.
    AUTHORITY-CHECK OBJECT 'Y&SW_ADMIN'
             ID 'Y&SW_ADMF' FIELD 'SENDMCWF'.
    IF sy-subrc <> 0.
      MESSAGE e108 WITH text-e03.
    ENDIF.
  ENDIF.

  IF p_email IS INITIAL AND p_wrkflw IS INITIAL.
    MESSAGE e116.
  ENDIF.

  EXELOG sy-repid ''.
* Validate at least one control exists
  SELECT * INTO TABLE gt_mchdr FROM /psyng/mchdr
         WHERE contid IN s_contid.
  IF sy-subrc <> 0.
    WRITE: / 'No control selected'(014).
  ENDIF.

* Determine when transactions and reports were last executed
  SELECT * INTO TABLE gt_hist FROM /psyng/mchistmon
         WHERE contid IN s_contid.
* Get tcodes for monitoring
  SELECT * INTO TABLE gt_tran FROM /psyng/mctran
         WHERE contid IN s_contid
         ORDER BY PRIMARY KEY.
* Get reports for monitoring

  SELECT * INTO TABLE gt_repid FROM /psyng/mcrepid
         WHERE contid IN s_contid
         ORDER BY PRIMARY KEY.
* Get auditors
  SELECT auditor contid company
         INTO TABLE gt_auditor FROM /psyng/mcauditor
         WHERE contid  IN s_contid
           AND auditor IN s_auditr
           AND company IN s_comp.

* Get Frequency
  SELECT * INTO TABLE gt_frequency FROM /psyng/sw_freq.

  SORT gt_auditor BY auditor.
  LOOP AT gt_auditor.
    AT NEW auditor.
      gt_userinfo-bname = gt_auditor-auditor.
      APPEND gt_userinfo.
    ENDAT.

    AT LAST.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
           EXPORTING
                i_name_only = 'X'
           TABLES
                sw_uinfo    = gt_userinfo.

      DELETE gt_userinfo WHERE NOT class IN s_class.
    ENDAT.
  ENDLOOP.

  IF sy-subrc <> 0.
    WRITE: / 'No auditors found'(013).
  ENDIF.

  LOOP AT gt_auditor.
    READ TABLE gt_userinfo WITH KEY bname = gt_auditor-auditor
               TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    DELETE gt_auditor.
  ENDLOOP.

  IF ( p_assgnd = 'X' OR p_email = 'X' )
  AND NOT gt_auditor[] IS INITIAL.
    SELECT * INTO TABLE gt_mcuser FROM /psyng/mcuser
           FOR ALL ENTRIES IN gt_auditor
           WHERE contid     = gt_auditor-contid
             AND auditor    = gt_auditor-auditor
             AND vrsio      IN  s_vrsio
             AND from_date <= sy-datum
             AND to_date   >= sy-datum
           ORDER BY PRIMARY KEY.

    SELECT * INTO TABLE gt_mcusrgrp FROM /psyng/mcusrgrp
           FOR ALL ENTRIES IN gt_auditor
           WHERE contid     = gt_auditor-contid
             AND auditor    = gt_auditor-auditor
             AND vrsio      IN  s_vrsio
             AND from_date <= sy-datum
             AND to_date   >= sy-datum
           ORDER BY PRIMARY KEY.
  ENDIF.

  PERFORM filter_mc.

  IF p_wrkflw = 'X'.
    PERFORM trigger_events.
  ENDIF.

  IF p_email = 'X'.
    PERFORM send_email.
  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  filter_mc
*&---------------------------------------------------------------------*
*       Filter out mitigating controls that do not yet need monitoring
*----------------------------------------------------------------------*
FORM filter_mc.
  DATA: l_need_exec_date TYPE d.

* Remove tcodes that do not need to be executed yet
  gt_output-type = 'T'.
  LOOP AT gt_tran.
    CLEAR gt_hist.
    CLEAR l_need_exec_date.
    READ TABLE gt_hist WITH KEY contid = gt_tran-contid
                                tcode  = gt_tran-tcode.

    gt_frequency-numdays = 0.
    READ TABLE gt_frequency WITH KEY freq = gt_tran-frequency.
    IF sy-subrc EQ 0.
      l_need_exec_date = sy-datum - gt_frequency-numdays.
    ENDIF.
    IF l_need_exec_date < gt_hist-last_exec
    AND NOT gt_hist-last_exec IS INITIAL.
      DELETE gt_tran.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD '3'
             ID 'Y&SW_CNTID' FIELD  gt_tran-contid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    CHECK sy-subrc = 0.

    gt_output-contid = gt_tran-contid.
    gt_output-repid  = gt_tran-tcode.

    IF p_assgnd = 'X'.
      LOOP AT gt_mcuser WHERE contid = gt_tran-contid.
        gt_output-auditor = gt_mcuser-auditor.
        APPEND gt_output.
      ENDLOOP.

      LOOP AT gt_mcusrgrp WHERE contid = gt_tran-contid.
        gt_output-auditor = gt_mcusrgrp-auditor.
        APPEND gt_output.
      ENDLOOP.
    ELSE.
      LOOP AT gt_auditor WHERE contid = gt_tran-contid.
        gt_output-auditor = gt_auditor-auditor.
        APPEND gt_output.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

* Remove reports that do not need to be executed yet
  gt_output-type = 'R'.
  LOOP AT gt_repid.
    CLEAR gt_hist.
    CLEAR l_need_exec_date.

    READ TABLE gt_hist WITH KEY contid = gt_repid-contid
                                repid  = gt_repid-repid.

    gt_frequency-numdays = 0.
    READ TABLE gt_frequency WITH KEY freq = gt_repid-frequency.

    IF sy-subrc EQ 0.
      l_need_exec_date = sy-datum - gt_frequency-numdays.
    ENDIF.
    IF l_need_exec_date < gt_hist-last_exec
    AND NOT gt_hist-last_exec IS INITIAL.
      DELETE gt_repid.
    ENDIF.

    AUTHORITY-CHECK OBJECT 'Y&SW_MITGH'
             ID 'ACTVT'      FIELD '3'
             ID 'Y&SW_CNTID' FIELD  gt_repid-contid
             ID 'Y&SW_VRSIO' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
    CHECK sy-subrc = 0.

    gt_output-contid = gt_repid-contid.
    gt_output-repid  = gt_repid-repid.

    IF p_assgnd = 'X'.
      LOOP AT gt_mcuser WHERE contid = gt_repid-contid.
        gt_output-auditor = gt_mcuser-auditor.
        APPEND gt_output.
      ENDLOOP.

      LOOP AT gt_mcusrgrp WHERE contid = gt_repid-contid.
        gt_output-auditor = gt_mcusrgrp-auditor.
        APPEND gt_output.
      ENDLOOP.
    ELSE.
      LOOP AT gt_auditor WHERE contid = gt_repid-contid.
        gt_output-auditor = gt_auditor-auditor.
        APPEND gt_output.
      ENDLOOP.
    ENDIF.
  ENDLOOP.

  SORT gt_output.
  DELETE ADJACENT DUPLICATES FROM gt_output COMPARING ALL FIELDS.
ENDFORM.                    " filter_mc

*&---------------------------------------------------------------------*
*&      Form  trigger_events
*&---------------------------------------------------------------------*
*       Trigger workflow events for monitoring
*----------------------------------------------------------------------*
FORM trigger_events.
  DATA: l_object_key TYPE swr_struct-object_key,
        l_wf_count   TYPE i.


  LOOP AT gt_output.
    IF p_test IS INITIAL.
      l_object_key = gt_output.
      CALL FUNCTION 'SAP_WAPI_CREATE_EVENT'
           EXPORTING
                object_type = '/PSYNG/MC'
                object_key  = l_object_key
                event       = 'EXECUTE'.
    ENDIF.

    IF p_log = 'X'.
      WRITE: /2 'Workflow generated for control'(005),
                gt_output-contid,
                'User'(006),
                gt_output-auditor.

      IF gt_output-type = 'T'.
        WRITE: 'T-Code'(007).
      ELSE.
        WRITE: 'Report'(008).
      ENDIF.

      WRITE: gt_output-repid.
    ENDIF.
  ENDLOOP.

  SKIP.
  DESCRIBE TABLE gt_output LINES l_wf_count.
  WRITE: / l_wf_count,
           'workflow items generated in total'(004).
ENDFORM.                    " trigger_events

*&---------------------------------------------------------------------*
*&      Form  send_email
*&---------------------------------------------------------------------*
*       Send reminder emails to auditors
*----------------------------------------------------------------------*
FORM send_email.
  DATA: ls_docdata    TYPE sodocchgi1,
        ls_mit_assgn  TYPE /psyng/mitigation_assignment,
        lt_obj_cont   TYPE TABLE OF solisti1 WITH HEADER LINE,
        lt_receivers  TYPE TABLE OF somlreci1 WITH HEADER LINE,
        lt_all_langu  TYPE TABLE OF /psyng/langu_user WITH HEADER LINE,
        lt_username   TYPE TABLE OF /psyng/bc_userid_name
                      WITH HEADER LINE,
        lt_auditor    TYPE TABLE OF /psyng/bc_userid_name
                      WITH HEADER LINE,
        lt_body       TYPE TABLE OF tline WITH HEADER LINE,
        lt_body_all   TYPE TABLE OF tline WITH HEADER LINE,
        lt_mcuser     TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_mcuser_flt TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
        lt_mcusrgrp   TYPE TABLE OF /psyng/mcusrgrp,
        lt_langu      TYPE TABLE OF /psyng/range_langu WITH HEADER LINE,
        l_cfg_val     TYPE /psyng/swconfig-value,
        l_tdname      TYPE thead-tdname,
        l_email_count TYPE i,
        lt_mcrepid    TYPE TABLE OF /psyng/mcrepid,
        lt_mctran     TYPE TABLE OF /psyng/mctran,
        l_subrc TYPE sy-subrc,
        l_str TYPE string,
        lt_uinfo      type table of /psyng/sw_uinfo with header line.

* Get text name from configuration
  se_config_param 'SW_MIT_REMIND_EMAIL' l_cfg_val.
  IF l_cfg_val is initial.
    WRITE: / 'Text for email not configured'(015).
    EXIT.
  ENDIF.

  l_tdname = l_cfg_val.

  IF NOT gt_output[] IS INITIAL.
    LOOP AT gt_output.
      lt_username-bname = gt_output-auditor.
      COLLECT lt_username.
    ENDLOOP.
  ELSE.
    LOOP AT gt_auditor.
      lt_username-bname = gt_auditor-auditor.
      COLLECT lt_username.
    ENDLOOP.

    IF sy-subrc <> 0.
      SKIP.
      WRITE: / l_email_count,
               'email items generated in total'(012).
      EXIT.
    ENDIF.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       TABLES
            username = lt_username.
  LOOP AT lt_username.
    IF lt_username-smtp_addr = space.
      MESSAGE s160 WITH 'User'(m03) lt_username-bname
      'does not have an e-mail address.'(m04).
      WRITE: / 'User'(m03),
               lt_username-bname,
                'does not have an e-mail address.'(m04).

    ENDIF.
  ENDLOOP.

  DELETE lt_username WHERE smtp_addr = space.

* Get possible languages for email
  LOOP AT lt_username.
    CALL FUNCTION '/PSYNG/BC_005'
         EXPORTING
              i_bname       = lt_username-bname
         TABLES
              et_langu_user = lt_all_langu.
  ENDLOOP.

  SORT lt_all_langu BY priority bname.
  DELETE ADJACENT DUPLICATES FROM lt_all_langu
                             COMPARING priority bname.


  SORT gt_mchdr.
  DELETE ADJACENT DUPLICATES FROM gt_mchdr.
  SORT lt_username.
  DELETE ADJACENT DUPLICATES FROM lt_username.
  LOOP AT lt_username.
    FREE : lt_body_all, lt_receivers,lt_langu.

    lt_langu-sign   = 'I'.
    lt_langu-option = 'EQ'.
    LOOP AT lt_all_langu WHERE bname = lt_username-bname.
      lt_langu-low = lt_all_langu-langu.
      COLLECT lt_langu.
    ENDLOOP.

    ls_docdata-obj_name   = 'MIT REMINDER'(m00).
    ls_docdata-obj_descr  = 'SE Mitigation Reminder'(m01).
    ls_docdata-obj_langu  = lt_all_langu-langu.
    ls_docdata-sensitivty = 'O'.
    ls_docdata-obj_prio   = '1'.



    IF p_test IS INITIAL.
      LOOP AT gt_mchdr.
        CLEAR: lt_auditor, lt_auditor[], lt_mcuser, lt_mcuser[],
               lt_mcusrgrp, lt_mcusrgrp[], lt_mcrepid[], lt_mctran[].
        READ TABLE gt_auditor WITH KEY auditor = lt_username-bname
                                       contid =  gt_mchdr-contid
                              BINARY SEARCH.
        CHECK sy-subrc = 0.
        LOOP AT gt_mcuser WHERE auditor = lt_username-bname AND
                                contid  = gt_mchdr-contid.
          APPEND gt_mcuser TO lt_mcuser.
        ENDLOOP.

        LOOP AT gt_mcusrgrp WHERE auditor = lt_username-bname AND
                                contid  = gt_mchdr-contid.
          APPEND gt_mcusrgrp TO lt_mcusrgrp.
        ENDLOOP.

        LOOP AT gt_tran WHERE contid = gt_mchdr-contid.
          APPEND gt_tran TO lt_mctran.
        ENDLOOP.
        LOOP AT gt_repid WHERE contid = gt_mchdr-contid.
          APPEND gt_repid TO lt_mcrepid.
        ENDLOOP.
        IF p_assgnd IS INITIAL.
*--Load Mitigations assigned to other auditors
          SELECT * INTO TABLE lt_mcuser              "#EC CI_SEL_NESTED
            FROM /psyng/mcuser
                 WHERE contid     = gt_mchdr-contid
                   AND vrsio      IN  s_vrsio
                   AND from_date <= sy-datum
                   AND to_date   >= sy-datum
                 ORDER BY PRIMARY KEY.

          SELECT * INTO TABLE lt_mcusrgrp            "#EC CI_SEL_NESTED
             FROM /psyng/mcusrgrp
                 WHERE contid     = gt_mchdr-contid
                   AND vrsio      IN  s_vrsio
                   AND from_date <= sy-datum
                   AND to_date   >= sy-datum
                 ORDER BY PRIMARY KEY.
          SORT : lt_mcusrgrp, lt_mcuser.
          DELETE ADJACENT DUPLICATES FROM lt_mcusrgrp.
          DELETE ADJACENT DUPLICATES FROM lt_mcuser.
        ENDIF.
*--Get the company for the user assignments, and if it doesn't match
*  with the auditor company asssignment, remove the record
        if p_bycomp = 'X' and not p_assgnd = 'X'.
        refresh : lt_uinfo, lt_mcuser_flt.
        loop at lt_mcuser.
          lt_uinfo-bname = lt_mcuser-userid.
          collect lt_uinfo.
        endloop.
        CALL FUNCTION '/PSYNG/SW_USER_INFO'
         EXPORTING
           I_NAME_ONLY              = 'X'
           I_MR_COMPANY             = 'X'
          TABLES
            sw_uinfo                 = lt_uinfo.
        sort lt_uinfo by bname.
        loop at lt_mcuser.
          read table lt_uinfo with key bname = lt_mcuser-userid
            binary search.
          check sy-subrc = 0.
          loop at gt_auditor where auditor = lt_username-bname and
                                   contid  = gt_mchdr-contid.
             if gt_auditor-company =   lt_uinfo-company or
                gt_auditor-company =   ''.
                append lt_mcuser to lt_mcuser_flt.
                exit."add each record just once if it matches
             endif.

          endloop.
        endloop.

        else.
          lt_mcuser_flt[] = lt_mcuser[].
        endif.
        CALL FUNCTION '/PSYNG/SW_094'
             EXPORTING
                  is_mchdr       = gt_mchdr
                  i_tdname       = l_tdname
                  i_auditor      = lt_username-bname
             TABLES
                  it_langu       = lt_langu
                  it_mcuser      = lt_mcuser_flt
                  it_mcusrgrp    = lt_mcusrgrp
                  it_mctran      = lt_mctran
                  it_mcrepid     = lt_mcrepid
                  et_text        = lt_body
             EXCEPTIONS
                  text_not_found = 1
                  OTHERS         = 2.

        CHECK sy-subrc = 0.

        APPEND LINES OF lt_body TO lt_body_all.
        FREE : lt_body.
      ENDLOOP."gt_mchdr
      lt_receivers-rec_type = 'U'.
      lt_receivers-com_type = 'INT'.
      lt_receivers-receiver = lt_username-smtp_addr.
      APPEND lt_receivers.
      FREE : lt_obj_cont.",lt_all_langu.
      CALL FUNCTION '/PSYNG/BC_006'
           EXPORTING
                i_bname      = lt_username-bname
           TABLES
                it_text      = lt_body_all
                it_all_langu = lt_all_langu
                et_content   = lt_obj_cont.

      CALL FUNCTION 'SO_NEW_DOCUMENT_SEND_API1'
           EXPORTING
                document_data              = ls_docdata
                document_type              = 'RAW'
           TABLES
                object_content             = lt_obj_cont
                receivers                  = lt_receivers
           EXCEPTIONS
                too_many_receivers         = 1
                document_not_sent          = 2
                document_type_not_exist    = 3
                operation_no_authorization = 4
                parameter_error            = 5
                x_error                    = 6
                enqueue_error              = 7
                OTHERS                     = 8.
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
      l_subrc = sy-subrc.
    ELSE.
      l_subrc = 0.
    ENDIF.


    IF l_subrc = 0.
      CLEAR l_subrc.
      ADD 1 TO l_email_count.

      IF p_log = 'X'.
        SKIP.
        LOOP AT gt_mchdr.
          CLEAR: lt_auditor, lt_auditor[], lt_mcuser, lt_mcuser[],
                 lt_mcusrgrp, lt_mcusrgrp[], lt_mcrepid[], lt_mctran[].
          READ TABLE gt_auditor WITH KEY auditor = lt_username-bname
                                         contid =  gt_mchdr-contid
                                BINARY SEARCH.
          CHECK sy-subrc = 0.
*          WRITE  : 'Email sent to auditor'(009),
*                   lt_username-bname,
*                   lt_username-smtp_addr.
*          WRITE:  'for mitigation'(010),
*                   gt_mchdr-contid.
          LOOP AT gt_mcuser WHERE auditor = lt_username-bname AND
                                  contid  = gt_mchdr-contid.
            APPEND gt_mcuser TO lt_mcuser.
          ENDLOOP.

          LOOP AT gt_mcusrgrp WHERE auditor = lt_username-bname AND
                                  contid  = gt_mchdr-contid.
            APPEND gt_mcusrgrp TO lt_mcusrgrp.
          ENDLOOP.

          IF p_assgnd IS INITIAL.
*--Load Mitigations assigned to other auditors
            SELECT * INTO TABLE lt_mcuser            "#EC CI_SEL_NESTED
              FROM /psyng/mcuser
*                 FOR ALL ENTRIES IN gt_auditor
                   WHERE contid     = gt_mchdr-contid
*               AND auditor    = gt_auditor-auditor
                     AND vrsio      IN  s_vrsio
                     AND from_date <= sy-datum
                     AND to_date   >= sy-datum
                   ORDER BY PRIMARY KEY.

            SELECT * INTO TABLE lt_mcusrgrp          "#EC CI_SEL_NESTED
               FROM /psyng/mcusrgrp
*                 FOR ALL ENTRIES IN gt_auditor
                   WHERE contid     = gt_mchdr-contid
*               AND auditor    = gt_auditor-auditor
                     AND vrsio      IN  s_vrsio
                     AND from_date <= sy-datum
                     AND to_date   >= sy-datum
                   ORDER BY PRIMARY KEY.
            SORT : lt_mcusrgrp, lt_mcuser.
            DELETE ADJACENT DUPLICATES FROM lt_mcusrgrp.
            DELETE ADJACENT DUPLICATES FROM lt_mcuser.
          ENDIF.
          IF NOT lt_mcuser[] IS INITIAL.
            CONCATENATE
            'Email sent to auditor'(009)
            lt_username-bname
            lt_username-smtp_addr
            'for mitigation'(010)
            gt_mchdr-contid
            INTO l_str
            SEPARATED BY space.
            WRITE : l_str.
            ULINE.
            WRITE / 'Mitigated User'.
            WRITE  AT 20 'Conflict'.
            WRITE  AT 30 'Auditor' .
            WRITE  AT 42 'Start'.
            WRITE  AT 54 'End' .
            WRITE  AT 66 'Version' .
            ULINE.
            LOOP AT lt_mcuser.
              WRITE / lt_mcuser-userid.
              WRITE  AT 20 lt_mcuser-conid .
              WRITE  AT 30 lt_mcuser-auditor .
              WRITE  AT 42 lt_mcuser-from_date .
              WRITE  AT 54 lt_mcuser-to_date .
              WRITE  AT 66 lt_mcuser-vrsio .
*              WRITE: / lt_mcuser-userid,
*                       'for conflict'(011),
*                       lt_mcuser-conid.
            ENDLOOP.
            ULINE.
          ENDIF.
        ENDLOOP.

      ENDIF.
    ELSE.
      MESSAGE i135 WITH text-e00 lt_username-bname.
    ENDIF.

    COMMIT WORK.
  ENDLOOP.

  SKIP.
  WRITE: / l_email_count,
           'email items generated in total'(012).
ENDFORM.                    " send_email

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: lt_exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700

  lt_exelog-mandt = sy-mandt.
  lt_exelog-repid = sy-repid.
  lt_exelog-uname = l_current_user."sy-uname. C0700
  lt_exelog-datum = sy-datum.
  lt_exelog-uzeit = sy-uzeit.
  APPEND lt_exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = lt_exelog.

  COMMIT WORK.
ENDFORM.                    " exelog
