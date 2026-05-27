FUNCTION /psyng/sw_mc_send_signoff_mail .
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  TABLES
*"      IT_AUDITORS STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_MCID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      ET_MESSAGES STRUCTURE  BAPIRET2
*"----------------------------------------------------------------------
  DATA :
  lt_signoffs     TYPE TABLE OF  /psyng/mcrvwsgn WITH HEADER LINE,
  lt_signoffs_eml TYPE TABLE OF  /psyng/mcrvwsgn WITH HEADER LINE,
  lt_auditor_info TYPE TABLE OF  /psyng/bc_userid_name WITH HEADER LINE,
  l_tabix         LIKE sy-tabix,
  l_exp_date      TYPE dats,
  l_token         TYPE /psyng/text25,
  l_html          TYPE string,
  l_link_text     TYPE string,
  l_link_html     TYPE string,
  l_link_url      TYPE string,
  l_central_sys   TYPE /psyng/param_value,
  lt_email_cont   TYPE TABLE OF solisti1 WITH HEADER LINE,
  l_subject       TYPE so_obj_des,
  lt_aud_mcid     TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE.
  se_config_param 'MIT_BY_ORG' gf_mit_by_org.

*--Get pending signoff's
  CALL FUNCTION '/PSYNG/SW_MC_GET_SIGNOFF_LIST'
       EXPORTING
            if_signoff_incomplete  = 'X'
            if_return_auditor_list = 'X'
       TABLES
            it_auditors            = it_auditors
            it_mcid                = it_mcid
            et_signoffs            = lt_signoffs
            et_auditor_info        = lt_auditor_info.


  SORT lt_signoffs BY auditor contid.
  lt_aud_mcid[] = lt_signoffs[].
  DELETE ADJACENT DUPLICATES FROM lt_aud_mcid COMPARING auditor contid.

  LOOP AT lt_auditor_info.
*--Collect all records for this auditor per Mitigating Control
    LOOP AT lt_aud_mcid WHERE auditor =   lt_auditor_info-bname.
      READ TABLE lt_signoffs WITH KEY auditor = lt_auditor_info-bname
                                      contid  = lt_aud_mcid-contid.
      CHECK sy-subrc = 0.
      l_tabix = sy-tabix.
      LOOP AT lt_signoffs FROM l_tabix.
        IF lt_signoffs-auditor <> lt_auditor_info-bname OR
           lt_signoffs-contid  <> lt_aud_mcid-contid.
          EXIT.
        ENDIF.
        APPEND lt_signoffs TO lt_signoffs_eml.
      ENDLOOP.
*--Send the E-Mail for Auditor for Mitigating Control
      if not lt_signoffs_eml[] is initial.

        PERFORM create_email_tables
          TABLES
            lt_signoffs_eml
            et_messages
          USING
           lt_auditor_info.
      endif.
      wait up to 1 seconds."ensure uniqueness of random uuids
      commit work.
      REFRESH : lt_signoffs_eml.
    ENDLOOP.
  ENDLOOP.
ENDFUNCTION.
