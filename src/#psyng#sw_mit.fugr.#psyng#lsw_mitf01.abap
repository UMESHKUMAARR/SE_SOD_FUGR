*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_MITF01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  new_transid_ignore_lock
*&---------------------------------------------------------------------*
FORM new_transid_ignore_lock
  USING
           i_nr_keys  TYPE i
  CHANGING e_first_id TYPE /psyng/se_mc_signoffid
           e_last_id  TYPE /psyng/se_mc_signoffid.
  DATA: wa_icc       TYPE /psyng/sw_sgnid,
        wa_icc_check TYPE /psyng/sw_sgnid.

  SELECT SINGLE * FROM /psyng/sw_sgnid INTO wa_icc.
  IF wa_icc-signoffid IS INITIAL.
    wa_icc-signoffid = 1.
    e_first_id = wa_icc-signoffid.
    wa_icc-signoffid = wa_icc-signoffid + i_nr_keys - 1.
    e_last_id = wa_icc-signoffid.
    INSERT INTO /psyng/sw_sgnid VALUES wa_icc.
  ELSE.
    ADD 1 TO wa_icc-signoffid.
    e_first_id = wa_icc-signoffid.
    wa_icc-signoffid = wa_icc-signoffid + i_nr_keys - 1.
    e_last_id = wa_icc-signoffid.
    UPDATE /psyng/sw_sgnid SET signoffid = wa_icc-signoffid.
    COMMIT WORK.
  ENDIF.
*   try until transid in db is the one we have as output
  WHILE wa_icc-signoffid <> wa_icc_check-signoffid.
    SELECT SINGLE * FROM /psyng/sw_sgnid INTO wa_icc_check.
    IF wa_icc-signoffid <> wa_icc_check-signoffid.
      wa_icc-signoffid = wa_icc_check-signoffid.
      ADD 1 TO wa_icc-signoffid.
      e_first_id = wa_icc-signoffid.
      wa_icc-signoffid = wa_icc-signoffid + i_nr_keys - 1.
      e_last_id = wa_icc-signoffid.
      UPDATE /psyng/sw_sgnid SET signoffid = wa_icc-signoffid.
      COMMIT WORK.
    ENDIF.
  ENDWHILE.
ENDFORM.                    " new_transid_ignore_lock
*&---------------------------------------------------------------------*
*&      Form  create_signoff_records
*&---------------------------------------------------------------------*
*      Create Signoff records for Mitigation Assignments
*----------------------------------------------------------------------*
FORM create_signoff_records
TABLES it_assignments     STRUCTURE /psyng/mitigation_assignment
       et_messages        STRUCTURE bapiret2
       et_signoff         STRUCTURE /psyng/mcrvwsgn
USING  i_reference_date   TYPE dats
       if_test            TYPE flag
       if_auto_signoff    TYPE flag.

  DATA : lt_signoff TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
         l_days     TYPE i,
         l_cnt      TYPE i.

  SORT it_assignments BY auditor contid userid.
  LOOP AT it_assignments.
*--Get frequency info
    CLEAR gt_mc_freq.
   READ TABLE gt_mc_freq WITH TABLE KEY contid =  it_assignments-contid.
    IF sy-subrc <> 0 OR NOT gt_mc_freq-numdays CO '0123456789'.
*--There is no frequency assigned to this Mitigation Header,
*  so we can't create a signoff record.
*  Or the number of days field has non numeric records
      log et_messages 'W' 'Mitigation has no frequency assigned'(003)
                       it_assignments-contid '' ''.
    ELSE.
      l_days = gt_mc_freq-numdays.
*--Check end date of oldest review record inside current validity date
      CLEAR lt_signoff.
      PERFORM get_oldest_signoff_date
        USING    it_assignments
                 i_reference_date
        CHANGING lt_signoff.
      IF lt_signoff IS INITIAL.
*--This is the first review period for this assignment.
*--Create all signoff records
*  after i_reference_date and after start of assignment.
        IF it_assignments-from_date < i_reference_date.
          lt_signoff-to_date     = i_reference_date - 1.
          lt_signoff-from_date   = i_reference_date - 1
                                   - l_days.
*--Never have a signoff period start or end before the assignment
*  record was valid
          if lt_signoff-from_date < it_assignments-from_date.
              lt_signoff-from_date = it_assignments-from_date.
              lt_signoff-to_date   = lt_signoff-from_date + l_days.
          endif.
*--Review period can't end after assignment
          if lt_signoff-to_date > it_assignments-to_date.
              lt_signoff-to_date = it_assignments-to_date.
          endif.

        ELSE.
          lt_signoff-from_date = it_assignments-from_date.
          lt_signoff-to_date   = lt_signoff-from_date
                                 + l_days.
        ENDIF.
      ELSE.
*--Create all signoff records after the latest one that exists
        lt_signoff-from_date = lt_signoff-to_date   + 1.
        lt_signoff-to_date   = lt_signoff-from_date + l_days - 1.
      ENDIF.
*--Only create signoff records for periods
*  that are completely in the past
      WHILE lt_signoff-to_date < i_reference_date.
        lt_signoff-contid    =  it_assignments-contid.
        lt_signoff-vrsio     =  it_assignments-vrsio.
        lt_signoff-auditor   =  it_assignments-auditor.
        lt_signoff-type      =  it_assignments-type.
        lt_signoff-userid    =  it_assignments-userid.
        lt_signoff-class     =  it_assignments-class.
        lt_signoff-agr_name  =  it_assignments-agr_name.
        lt_signoff-conid     =  it_assignments-conid.
        lt_signoff-swaudid   =  it_assignments-swaudid.
        lt_signoff-org_abb   =  it_assignments-org_abb.
        clear :
          lt_signoff-signoff_date,
          lt_signoff-signoff_time,
          lt_signoff-signoff_complete,
          lt_signoff-signoff_type.

*--Check variables related to auto signoff
          PERFORM analyze_auto_signoff
          TABLES   et_messages
          USING    if_auto_signoff
          CHANGING lt_signoff.
        log et_messages 'I' 'Signoff Record Created'(004)
                        it_assignments-auditor
                        it_assignments-contid
                        it_assignments-userid.
        APPEND lt_signoff.
*--Set dates of next record
        lt_signoff-from_date = lt_signoff-to_date + 1.
        lt_signoff-to_date   = lt_signoff-from_date
                               + l_days - 1.
        DESCRIBE TABLE lt_signoff LINES l_cnt.
        IF l_cnt >= 1000.
*--Store the batch of 1000 records to database
*  Create any justifications for auto reviewed records
          APPEND LINES OF lt_signoff TO et_signoff.
          IF if_test <> 'X'.
            PERFORM commit_signoff
              TABLES lt_signoff
                     et_messages.
          ENDIF.
          REFRESH lt_signoff.
        ENDIF.
      ENDWHILE.
    ENDIF.
  ENDLOOP.
*--Store the rest of the records to database
*  Create any justifications for auto reviewed records
  APPEND LINES OF lt_signoff TO et_signoff.
  IF if_test <> 'X'.
    PERFORM commit_signoff
      TABLES lt_signoff
             et_messages.
  ENDIF.
  REFRESH lt_signoff.

ENDFORM.                    " create_signoff_record
*&---------------------------------------------------------------------*
*&      Form  get_oldest_signoff_date
*&---------------------------------------------------------------------*
*Check end date of oldest review record inside current validity date
*----------------------------------------------------------------------*
FORM get_oldest_signoff_date
   USING    is_assignments TYPE /psyng/mitigation_assignment
            i_reference_date TYPE dats
   CHANGING es_signoff.
  CLEAR es_signoff.
  SELECT  * FROM /psyng/mcrvwsgn
  INTO es_signoff
  WHERE
    contid   =  is_assignments-contid     AND
    vrsio    =  is_assignments-vrsio      AND
    type     =  is_assignments-type       AND
    userid   =  is_assignments-userid     AND
    class    =  is_assignments-class      AND
    agr_name =  is_assignments-agr_name   AND
    conid    =  is_assignments-conid      AND
    swaudid  =  is_assignments-swaudid    AND
    org_abb  =  is_assignments-org_abb    AND
    from_date >= is_assignments-from_date AND
    to_date   <=  i_reference_date
    ORDER BY from_date DESCENDING.
    EXIT."only first record
  ENDSELECT.
ENDFORM.                    " get_oldest_signoff_date
*&---------------------------------------------------------------------*
*&      Form  load_frequencies
*&---------------------------------------------------------------------*
*       Load mitigation frequencies into table gt_mc_freq
*----------------------------------------------------------------------*
FORM load_frequencies.
  SELECT contid frequency numdays auto_am auto_tcode auto_changes
  INTO TABLE gt_mc_freq
  FROM /psyng/mcrvwhdr AS r
  INNER JOIN /psyng/sw_freq AS f ON
  f~freq = r~frequency
  ORDER BY contid .
ENDFORM.                    " load_frequencies
*&---------------------------------------------------------------------*
*&      Form  commit_signoff
*&---------------------------------------------------------------------*
*       Store the signoff records to the database
*       and generate their ID's
*----------------------------------------------------------------------*
FORM commit_signoff
TABLES  it_signoff STRUCTURE /psyng/mcrvwsgn
        et_messages STRUCTURE bapiret2.
  DATA : l_cnt   TYPE i,
         l_first TYPE /psyng/se_mc_signoffid,
         l_last  TYPE /psyng/se_mc_signoffid.
  FIELD-SYMBOLS :
         <so>    TYPE /psyng/mcrvwsgn.

  DATA : ls_signoff_bu TYPE /psyng/mcrvwsgn,
         l_auto_review_text TYPE string.
*--Backup the header line
  ls_signoff_bu = it_signoff.
  DESCRIBE TABLE it_signoff  LINES l_cnt.
  CALL FUNCTION '/PSYNG/SW_MC_GET_NEW_SIGNOFFID'
       EXPORTING
            i_nr_keys  = l_cnt
       IMPORTING
            e_first_id = l_first
            e_last_id  = l_last.
  LOOP AT it_signoff ASSIGNING <so>.
    SUBTRACT 1 FROM l_cnt.
    <so>-signoffid = l_first.
    ADD 1 TO l_first.
    IF l_first > l_last.
*--Should the key range we have be exhausted (which shouldn't happen)
*  get some more
      CALL FUNCTION '/PSYNG/SW_MC_GET_NEW_SIGNOFFID'
           EXPORTING
                i_nr_keys  = l_cnt
           IMPORTING
                e_first_id = l_first
                e_last_id  = l_last.
    ENDIF.
*--If the record was auto reviewed, store a justification
    IF <so>-signoff_complete = 'X' AND
       <so>-signoff_type     = 'A'.
      l_auto_review_text = 'Automatically Reviewed'(r01).
      IF <so>-tcode_executed = 'X'.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'Transactions were executed.'(r02)
                    INTO l_auto_review_text.
      ELSE.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'Transactions were not executed.'(r03)
                    INTO l_auto_review_text.
      ENDIF.
      IF <so>-changes_made = 'X'.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'Changes were made.'(r04)
                    INTO l_auto_review_text.
      ELSE.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'Changes were not made.'(r05)
                    INTO l_auto_review_text.
      ENDIF.
      IF <so>-am_alerts_open = 'X'.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'Open Automated Mitigations Alerts Found.'(r06)
                    INTO l_auto_review_text.
      ELSE.
        CONCATENATE l_auto_review_text
                    s_new_line
                    'No Open Automated Mitigations Alerts Found.'(r07)
                    INTO l_auto_review_text.
      ENDIF.
      CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
           EXPORTING
                if_signoff           = 'X'
                if_add               = 'X'
                i_mcid               = <so>-contid
                is_signoff           = <so>
                i_justification_text = l_auto_review_text
           EXCEPTIONS
                invalid_input        = 1
                not_implemented      = 2
                gos_failure          = 3
                OTHERS               = 4.
      IF sy-subrc <> 0.
        log et_messages 'E'
            'Failed to add justification to review'
            <so>-signoffid
            '' '' .
      ENDIF.
    ENDIF.

  ENDLOOP.
  INSERT /psyng/mcrvwsgn FROM TABLE it_signoff.
  REFRESH it_signoff.
*--Restore the header line
  it_signoff = ls_signoff_bu.

ENDFORM.                    " commit_signoff
*&---------------------------------------------------------------------*
*&      Form  create_obj_id
*&---------------------------------------------------------------------*
*       Create the key for a Mitigation Attachment
*       Different types are :
*            (H) header
*            (A) assignment
*            (S) signoff
*       This form generates the key based on the parameters of the
*       FM to handle attachments.
*----------------------------------------------------------------------*
FORM create_obj_id
  USING   i_mcid        TYPE /psyng/contid
          if_header     TYPE flag
          if_assignment TYPE flag
          if_signoff    TYPE flag
          is_assignment TYPE /psyng/mitigation_assignment
          is_signoff    TYPE /psyng/mcrvwsgn
  CHANGING e_objkey     TYPE swo_typeid.
*--Structures for the different types of keys
  DATA : BEGIN OF l_obj_key_assign, "max 70 chars
    type            TYPE c,
    id(12)          TYPE c,
    vrsio(3)        TYPE c,
    assign_type(1)  TYPE c ,
    matrix_obj(12)  TYPE c,
    assigned_to(30) TYPE c,
    org_abb(10)     TYPE c,
  END OF l_obj_key_assign.
  DATA : BEGIN OF l_obj_key_signoff, "max 70 chars
    type            TYPE c,
    id(12)          TYPE c,
    vrsio(3)        TYPE c,
    signoffid(15)   TYPE c,
  END OF l_obj_key_signoff.
  CLEAR : l_obj_key_assign,
          l_obj_key_assign.
  CASE 'X'.
*--Attachment to Mitigation Header
    WHEN if_header.
      l_obj_key_assign-type = 'H'.
      l_obj_key_assign-id   = i_mcid.
      e_objkey = l_obj_key_assign.
*--Attachment to Mitigation Assignment
    WHEN if_assignment.
      l_obj_key_assign-type        = 'A'.
      l_obj_key_assign-id          = i_mcid.
      l_obj_key_assign-vrsio       = is_assignment-vrsio.
      l_obj_key_assign-assign_type = is_assignment-type.
*--Determine who/what the MC is assigned to
      CASE is_assignment-type.
        WHEN 1 OR 3. "assigned to user
          l_obj_key_assign-assigned_to = is_assignment-userid.
        WHEN 4 OR 5. "assigned to role
          l_obj_key_assign-assigned_to = is_assignment-agr_name.
        WHEN 2.      "assigned to user group
          l_obj_key_assign-assigned_to = is_assignment-class.
      ENDCASE.
*--Determine what is mitigated
      CASE is_assignment-type.
        WHEN 1 OR 2 OR 4. "Conflict is Mitigated
          l_obj_key_assign-matrix_obj = is_assignment-conid.
        WHEN 3 OR 5. "Critical Authorization is Mitigated
          l_obj_key_assign-matrix_obj = is_assignment-swaudid.
      ENDCASE.
      l_obj_key_assign-org_abb = is_assignment-org_abb.
      e_objkey = l_obj_key_assign.
*--Attachment to Mitigation Signoff
    WHEN if_signoff.
      MOVE-CORRESPONDING is_signoff TO is_assignment.
      l_obj_key_signoff-type        = 'S'.
      l_obj_key_signoff-id          = i_mcid.
*--The Signoff ID
      l_obj_key_signoff-signoffid   = is_signoff-signoffid.
      e_objkey = l_obj_key_signoff.
  ENDCASE.
ENDFORM.                    " create_obj_id
*&---------------------------------------------------------------------*
*&      Form  analyze_auto_signoff
*&---------------------------------------------------------------------*
*       Analyze the following for this conflict or Critical Auth :
*       Executed :
*           Conflict : Was at least 1 tcode from each function executed
*           CA : was a transaction executed (if any tcodes in CA)
*       Changes Made :
*           Conflict : Was a change made with at least 1 tcode from
*                      each function
*           CA : was a change made with 1 of the transactions
*                (if any tcodes in CA)
*        AM Alerts : Only relevant for conflicts
*----------------------------------------------------------------------*
*      <--P_LT_SIGNOFF  text
*----------------------------------------------------------------------*
FORM analyze_auto_signoff
TABLES   et_messages STRUCTURE bapiret2
USING    if_auto_signoff TYPE flag
CHANGING es_signoff  TYPE      /psyng/mcrvwsgn.
  DATA :
  lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
  lt_confdet   TYPE TABLE OF /psyng/confdet   WITH HEADER LINE,
  lt_faobj     TYPE TABLE OF /psyng/faobj2    WITH HEADER LINE,
  lt_results   TYPE TABLE OF /psyng/sw_sod_output_org
                                              WITH HEADER LINE,
  lt_users   TYPE TABLE OF  /psyng/sw_sel_opts_xubname
                                              WITH HEADER LINE,
  lt_confs   TYPE TABLE OF  /psyng/sw_sel_opts_conid
                                              WITH HEADER LINE,
  lt_conflict  TYPE TABLE OF /psyng/conflict  WITH HEADER LINE,

  l_idx_c TYPE i,
  l_idx_f TYPE i,
  l_idx_t TYPE i,
  lf_conflict TYPE flag,
  l_system_msg(80) TYPE c,
  lf_auto_review TYPE flag,
  l_auto_review_text TYPE string.
  lt_results-bname = es_signoff-userid.
  .

*--Auto review only applies to assignments that involve users
  IF NOT lt_results-bname IS INITIAL.
    CASE es_signoff-type.
      WHEN 1 OR 2 OR 4.
        lf_conflict = 'X'.
        lt_results-conid = es_signoff-conid.
*--Collect the SOD Conflict Info for doing tcode execution check
*--Functions
        READ TABLE gt_confdet WITH KEY conid = es_signoff-conid
        BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        l_idx_c = sy-tabix.
        LOOP AT gt_confdet FROM l_idx_c.
          IF gt_confdet-conid <> es_signoff-conid.
            EXIT.
          ENDIF.
          APPEND gt_confdet TO lt_confdet.
*--Transactions
          READ TABLE gt_functtran
          WITH KEY functionid = gt_confdet-functionid
          BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          l_idx_f = sy-tabix.
          LOOP AT gt_functtran FROM l_idx_f.
            IF gt_functtran-functionid <> gt_confdet-functionid.
              EXIT.
            ENDIF.
            APPEND gt_functtran TO lt_functtran.
*--Objects
            READ TABLE gt_faobj
            WITH KEY funid = gt_confdet-functionid
                     tcode = gt_functtran-tcode
            BINARY SEARCH TRANSPORTING NO FIELDS.
            CHECK sy-subrc = 0.
            l_idx_t = sy-tabix.
            LOOP AT gt_faobj FROM l_idx_t.
              IF gt_faobj-funid <> gt_confdet-functionid OR
                 gt_faobj-tcode <> gt_functtran-tcode.
                EXIT.
              ENDIF.
              APPEND gt_faobj TO lt_faobj.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.
      WHEN 3 OR 5.
        lt_results-conid = es_signoff-swaudid.
*--CA
        lt_results-conid  = es_signoff-swaudid.
        lt_conflict-conid = es_signoff-swaudid.
        collect lt_conflict.
*--Collect the SOD Conflict Info for doing tcode execution check
*--Functions
        READ TABLE gt_ca_confdet WITH KEY conid = es_signoff-swaudid
        BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        l_idx_c = sy-tabix.
        LOOP AT gt_ca_confdet FROM l_idx_c.
          IF gt_ca_confdet-conid <> es_signoff-swaudid.
            EXIT.
          ENDIF.
          APPEND gt_ca_confdet TO lt_confdet.
*--Transactions
          READ TABLE gt_ca_functtran
          WITH KEY functionid = gt_ca_confdet-functionid
          BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          l_idx_f = sy-tabix.
          LOOP AT gt_ca_functtran FROM l_idx_f.
            IF gt_ca_functtran-functionid <> gt_ca_confdet-functionid.
              EXIT.
            ENDIF.
            APPEND gt_ca_functtran TO lt_functtran.
*--Objects
            READ TABLE gt_ca_faobj
            WITH KEY funid = gt_ca_confdet-functionid
                     tcode = gt_ca_functtran-tcode
            BINARY SEARCH TRANSPORTING NO FIELDS.
            CHECK sy-subrc = 0.
            l_idx_t = sy-tabix.
            LOOP AT gt_ca_faobj FROM l_idx_t.
              IF gt_ca_faobj-funid <> gt_confdet-functionid OR
                 gt_ca_faobj-tcode <> gt_functtran-tcode.
                EXIT.
              ENDIF.
              APPEND gt_ca_faobj TO lt_faobj.
            ENDLOOP.
          ENDLOOP.
        ENDLOOP.

    ENDCASE.

    REFRESH : lt_results.
    APPEND lt_results.
*--Tcode Execution Check
    CALL FUNCTION '/PSYNG/SW_098'
     EXPORTING
       i_hist_start         = es_signoff-from_date
       i_hist_end           = es_signoff-to_date
       if_use_ta            = 'X'
       i_vrsio              = es_signoff-vrsio
     TABLES
       it_results           = lt_results
*   IT_FUNCRESULTS       =
       it_functtran         = lt_functtran
       it_confdet           = lt_confdet
       it_faobj             = lt_faobj.
*--Changes check
    CALL FUNCTION '/PSYNG/SW_099'
         EXPORTING
              i_hist_start  = es_signoff-from_date
              i_hist_end    = es_signoff-to_date
              i_vrsio       = es_signoff-vrsio
              i_changedocs  = 'X'
              i_tablog      = 'X'
              i_by_conflict = 'X'
*              I_BY_FUNCTION = 'X'
              if_use_ta     = 'X'
         TABLES
              it_results    = lt_results
              it_functtran  = lt_functtran
              it_confdet    = lt_confdet
              it_faobj      = lt_faobj
              IT_CONFLICTS  = lt_conflict.
*--AM Alerts Check
    IF lf_conflict = 'X'.
*  create ranges
      lt_users-sign = 'I'. lt_users-option = 'EQ'.
      lt_confs-sign = 'I'. lt_confs-option = 'EQ'.
      lt_users-low = es_signoff-userid.
      lt_confs-low = lt_results-conid.
      APPEND lt_confs. APPEND lt_users.


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
      CALL FUNCTION '/PSYNG/SW_100'
      DESTINATION l_system_msg
           EXPORTING
                i_vrsio      = es_signoff-vrsio
                i_hist_start = es_signoff-from_date
                i_hist_end   = es_signoff-to_date
           TABLES
                it_results   = lt_results
                it_users     = lt_users
                it_confs     = lt_confs
          EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      IF sy-subrc <> 0.
        log et_messages 'W' 'Checking for open AM alerts failed'(005)
            es_signoff-contid es_signoff-userid  lt_results-conid.
        IF sy-subrc < 3.
          log et_messages 'W' l_system_msg
              es_signoff-contid es_signoff-userid  lt_results-conid.
        ENDIF.
      ENDIF.
    ENDIF.
    READ TABLE lt_results INDEX 1.
    es_signoff-tcode_executed = lt_results-level2.
    es_signoff-changes_made   = lt_results-level3.
    es_signoff-am_alerts_open = lt_results-level4.

*--Determine if session should be auto reviewed
    IF if_auto_signoff = 'X'.
    READ TABLE gt_mc_freq WITH TABLE KEY contid =  es_signoff-contid.
    IF sy-subrc = 0.
      IF gt_mc_freq-auto_am      = 'X' OR
         gt_mc_freq-auto_tcode   = 'X' OR
         gt_mc_freq-auto_changes = 'X'.
*--One of the three is set, so auto review is active
        lf_auto_review = 'X'.
        IF gt_mc_freq-auto_am      = 'X' AND
          NOT  es_signoff-am_alerts_open IS INITIAL.
          CLEAR lf_auto_review.
        ENDIF.
        IF gt_mc_freq-auto_tcode      = 'X' AND
          NOT  es_signoff-tcode_executed IS INITIAL.
          CLEAR lf_auto_review.
        ENDIF.
        IF gt_mc_freq-auto_changes      = 'X' AND
          NOT  es_signoff-changes_made IS INITIAL.
          CLEAR lf_auto_review.
        ENDIF.
        IF lf_auto_review = 'X'.
*--Log Automatic Review
          es_signoff-signoff_date     = sy-datum.
          es_signoff-signoff_time     = sy-uzeit.
          es_signoff-signoff_complete = 'X'.
          es_signoff-signoff_type     = 'A'.


        ENDIF.
      ENDIF.
    ENDIF.
   ENDIF.
  ENDIF.



ENDFORM.                    " analyze_auto_signoff
*&---------------------------------------------------------------------*
*&      Form  load_matrix
*&---------------------------------------------------------------------*
*      Load SOD Conflict info and CA info
*----------------------------------------------------------------------*
*      -->P_I_VRSIO  text
*----------------------------------------------------------------------*
FORM load_matrix USING i_vrsio
                       if_all    TYPE flag
                       i_conid   TYPE /psyng/conflict_id
                       i_swaudid TYPE /psyng/swaudid.
  FIELD-SYMBOLS : <confdet> LIKE gt_confdet.
  DATA :  lt_swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
          lt_conid    TYPE TABLE OF /psyng/sw_sel_opts_conid
                      WITH HEADER LINE.
*--Load SOD Conflicts
  REFRESH : gt_confdet, gt_functtran,gt_faobj.

  IF NOT if_all = 'X'.
    IF i_conid <> ''.
      REFRESH : lt_conid.
      lt_conid-sign   = 'I'.
      lt_conid-option = 'EQ'.
      lt_conid-low    = i_conid.
      APPEND lt_conid.
    ENDIF.
  ENDIF.
  IF if_all = 'X' OR NOT lt_conid IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_028'
         EXPORTING
              i_vrsio      = i_vrsio
         TABLES
              it_spconfs   = lt_conid
              et_confdet   = gt_confdet
              et_functtran = gt_functtran
              et_faobj     = gt_faobj.

    SORT gt_functtran BY functionid tcode.
    SORT gt_confdet   BY conid functionid.
    SORT gt_faobj     BY funid tcode .
*  --Only the S_TCODE object is interesting
    DELETE gt_faobj WHERE object <> 'S_TCODE'.
  ENDIF.

*--Load Critical Authorizations
*  Load in same format as SOD conflicts
  REFRESH : gt_ca_functtran, gt_ca_confdet, gt_ca_faobj.
  IF if_all = 'X'.
    SELECT * INTO TABLE lt_swaudhdr
    FROM /psyng/swaudhdr WHERE vrsio = i_vrsio.
  ELSEIF i_swaudid <> ''.
    SELECT * INTO TABLE lt_swaudhdr
    FROM /psyng/swaudhdr WHERE
      vrsio   = i_vrsio AND
      swaudid = i_swaudid.
  ENDIF.

  LOOP AT lt_swaudhdr.
    gt_ca_confdet-conid         = lt_swaudhdr-swaudid.
    gt_ca_confdet-functionid    = lt_swaudhdr-swaudid.
    APPEND gt_ca_confdet.
    IF lt_swaudhdr-tcode <> '*'.
*--Only if a tcode is found
      gt_ca_functtran-functionid = lt_swaudhdr-swaudid.
      gt_ca_functtran-tcode      = lt_swaudhdr-tcode.
      APPEND gt_ca_functtran.
    ENDIF.
  ENDLOOP.
  SELECT swaudid AS funid tcode object field val_from val_to
  INTO CORRESPONDING FIELDS OF TABLE gt_ca_faobj
  FROM  /psyng/swaudc2
  WHERE vrsio = i_vrsio
 .
*--Only the S_TCODE object is interesting
  DELETE gt_ca_faobj WHERE object <> 'S_TCODE'.


ENDFORM.                    " load_matrix
*&---------------------------------------------------------------------*
*&      Form  create_email_tables
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_SIGNOFFS_EML  text
*----------------------------------------------------------------------*
FORM create_email_tables
TABLES   it_signoffs     STRUCTURE /psyng/mcrvwsgn
         et_messages     STRUCTURE bapiret2
USING    is_auditor_info TYPE /psyng/bc_userid_name.
  DEFINE yesno.
*--Convert flag to yes or no
    if &1 = 'X'.
      &2 = 'Yes'(y01).
    else.
      &2 = 'No'(y02).
    endif.
  END-OF-DEFINITION.
  DEFINE header.
    &1-col_num  = &2.
    &1-fld_name = &3.
    &1-fld_txt  = &4.
*    &1-attr     = &5.
    append &1.
  END-OF-DEFINITION.
  DATA :   lt_decisions    TYPE TABLE OF  /psyng/se_emldec WITH HEADER
  LINE.

  TYPES : BEGIN OF typ_email_data,
      soid       TYPE string,
      stdate(20) TYPE c,
      eddate(20) TYPE c,
      bname      TYPE string,
      name       TYPE string,
      id         TYPE string,
      text       TYPE string,
      org_abb    TYPE string,
      executed   TYPE string,
      changes    TYPE string,
      amalerts   TYPE string,
      signoff    TYPE string,
      END OF typ_email_data.

  DATA : lt_userconflicts TYPE TABLE OF   typ_email_data,
         lt_userca TYPE TABLE OF   typ_email_data,
         lt_roleconflicts TYPE TABLE OF   typ_email_data,
         lt_roleca TYPE TABLE OF   typ_email_data,
         ls_record TYPE typ_email_data,
         lt_htmlt TYPE /psyng/bc_html_data_t ,
         ls_htmlt TYPE /psyng/bc_html_data,
        lt_headers TYPE TABLE OF /psyng/bc_tab_headers WITH HEADER LINE,
         l_send_templ TYPE thead-tdname,
         l_css_temp type DOKHL-OBJECT,
         l_resp_templ TYPE thead-tdname,
         lt_receivers TYPE TABLE OF /psyng/bc_userid_name
                  WITH HEADER LINE,
         l_central_sys TYPE rfcdest,
         l_exp_date TYPE dats,
         l_link_text TYPE string,
         l_link_html TYPE string,
         l_link_url  TYPE string,
         lt_email_cont TYPE TABLE OF solisti1,
         ls_line TYPE solisti1,
         l_subject TYPE so_obj_des,
         l_tabstyle TYPE sylisel,
         l_body_text TYPE string,
         l_num       TYPE i,
         l_prev_tok  type /PSYNG/TEXT25,
         ls_revhdr   type /psyng/mcrvwhdr,
         l_dec_cnt type i,
         l_dec_cnt_s type string.
  DATA: lf_am_installed type flag,
        ls_config       type /PSYNG/BC_EMLCFG_PARAM,
        lf_email_config TYPE flag.
  DEFINE add_placeholder.
    ls_htmlt-placeholder = &2.
    ls_htmlt-text        = &3.
    append ls_htmlt to &1.
  END-OF-DEFINITION.

*--Check if AM is installed
CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
 EXPORTING
   I_MODULE               = 'AM'
 IMPORTING
   E_INSTALLED            = lf_am_installed.
*Check email approval configuration is active or not
CALL FUNCTION '/PSYNG/BC_037'
 EXPORTING
   I_PARAMETER       = 'EMAIL_APPR_ACTIVE'
 IMPORTING
   E_CONFIG          = ls_config.
IF NOT ls_config-value IS INITIAL.
   lf_email_config = ls_config-value.
ELSE.
   lf_email_config = ls_config-default.
ENDIF.
*--Get RFC destination to E-Mail SIgnoff System
  se_config_param 'APPROVAL_CENTRAL_SYS' l_central_sys.
*--TODO : a smarter expiration date for review link validity
  l_exp_date = sy-datum + 7.

*--Get template for outgoing e-mail
  se_config_param 'SW_MIT_SIGNOFF_EMAIL' l_send_templ.
*--Get template for the review response
  READ TABLE it_signoffs INDEX 1.
  CLEAR l_resp_templ.
  PERFORM get_response_template
  USING    it_signoffs-contid
  CHANGING l_resp_templ.

  LOOP AT it_signoffs.
*--for each signoff record, register a decision
    CLEAR :
      lt_decisions-token,
      l_link_text,
      l_body_text,
      ls_record-signoff,
      l_link_html.
    lt_decisions-userid    = it_signoffs-auditor.
*    lt_decisions-decision  = 'SO'.
    concatenate 'SO' l_dec_cnt_s into lt_decisions-decision.
    condense lt_decisions-decision.

    lt_decisions-sw_module = 'SE'.
    lt_decisions-objectkey = it_signoffs-signoffid.
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
    CALL FUNCTION '/PSYNG/BC_024' DESTINATION l_central_sys
      EXPORTING
        i_username                 = it_signoffs-auditor
        i_decision                 = lt_decisions-decision
        i_expiration_date          = l_exp_date
        i_expiration_time          = '235959'
        i_callback                 = '/PSYNG/SW_MC_EMAIL_WF_CALLBACK'
        i_module                   = 'SE'
        i_email                    = is_auditor_info-smtp_addr
        i_sysid                    = sy-sysid
        i_mandt                    = sy-mandt
     IMPORTING
       e_token                     = lt_decisions-token
     EXCEPTIONS
       username_required                    = 1
       decision_required                    = 2
       invalid_expiration_date              = 3
       invalid_expiration_time              = 4
       callback_function_doesnt_exist       = 5
       callback_required                    = 6
       token_generation_failed              = 7
       system_not_configured                = 8
       OTHERS                               = 9. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      log et_messages 'E' 'Failed to generate decision Token'
          it_signoffs-contid it_signoffs-auditor
          it_signoffs-signoffid.
      clear lt_decisions-token.
      wait up to 2 seconds.
    ELSE.
    if lt_decisions-token  = l_prev_tok.
      wait up to 1 seconds. "wait so next uuid is different
    endif.
    l_prev_tok = lt_decisions-token.
*--This section generated the signoff link
*  This is only executed when e-mail approval is configured correctly.
      APPEND lt_decisions.
*--Create signoff link
      l_link_text = 'Sign Off'(s02).

      PERFORM get_response_text
      USING
        is_auditor_info-bname
        l_resp_templ
      CHANGING
        l_body_text.
*--Add information about signoff requirements (justification/attachment)
*  to the response e-mail
    select single * from /psyng/mcrvwhdr into ls_revhdr
    where contid = it_signoffs-contid.
    concatenate
      l_body_text s_new_line s_new_line 'Signoff Requirements'(r00)
      ' : '
      into l_body_text.
    if ls_revhdr-MANUAL_JUST = 'X'.
      concatenate
      l_body_text  s_new_line 'Justification Required'(r01)
      into l_body_text.
    else.
      concatenate
      l_body_text s_new_line 'Justification Not Required'(r03)
      into l_body_text.
    endif.
    if ls_revhdr-MANUAL_ATTACH = 'X'.
      concatenate
      l_body_text s_new_line 'Attachment Required'(r02)
      into l_body_text.
    else.
      concatenate
      l_body_text s_new_line 'Attachment Not Required'(r04)
      into l_body_text.
    endif.



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
      CALL FUNCTION '/PSYNG/BC_022' DESTINATION l_central_sys
           EXPORTING
                i_token     = lt_decisions-token
                i_decision  = lt_decisions-decision
                i_link_text = l_link_text
                i_body      = l_body_text
           IMPORTING
                e_link      = l_link_html
                e_url       = l_link_url. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

      ls_record-signoff = l_link_html.
      if ls_record-signoff is initial.
         log et_messages 'E' 'Failed to generate decision link'
         'token:' lt_decisions-token
         it_signoffs-signoffid.
      endif.
    endif.
*--Get header info (user or role)
      PERFORM get_header_text
        USING
          it_signoffs
        CHANGING
          ls_record-bname
          ls_record-name.
*--Get assigned object info (sod or ca)
      PERFORM get_text
        USING
          it_signoffs
        CHANGING
          ls_record-text
          ls_record-id.
*--Translate flags into yes/no
      yesno it_signoffs-tcode_executed ls_record-executed.
      yesno it_signoffs-changes_made   ls_record-changes.
      yesno it_signoffs-tcode_executed ls_record-executed.
      yesno it_signoffs-am_alerts_open ls_record-amalerts.

      l_num             = it_signoffs-signoffid.
      ls_record-soid    = l_num.
      WRITE it_signoffs-from_date TO ls_record-stdate.
      WRITE it_signoffs-to_date   TO ls_record-eddate.


      ls_record-org_abb = it_signoffs-org_abb.



*--Add record to appropriate table
      CASE it_signoffs-type.
        WHEN '1' OR '2' OR '4'.
          IF NOT it_signoffs-userid IS INITIAL.
            APPEND ls_record TO lt_userconflicts.
          ELSEIF it_signoffs-type = '4'.
            APPEND ls_record TO lt_roleconflicts.
          ENDIF.
        WHEN '3' OR '5'.
          IF NOT it_signoffs-userid IS INITIAL.
            APPEND ls_record TO lt_userca.
          ELSEIF it_signoffs-type = '5'.
            APPEND ls_record TO lt_roleca.
          ENDIF.
      ENDCASE.
*    ENDIF.
  ENDLOOP.


*--Table style
*  CONCATENATE
*  'style="border: 1px solid black"'
*  'class="table table-striped"'
*  INTO l_tabstyle.
l_tabstyle = 'class="table" style="width:99%"'.
*--Convert each table to it's html renderng
  ls_htmlt-placeholder = '[USER_SOD_TABLE]'.
  ls_htmlt-tag         = 'TABLE'.

  REFRESH lt_headers.
  header lt_headers '1'  'SOID'     'ID'(h12).
  header lt_headers '2'  'STDATE'   'Period Start'(h13).
  header lt_headers '3'  'EDDATE'   'End'(h14).
  header lt_headers '4'  'BNAME'    'User ID'(h01).
  header lt_headers '5'  'NAME'     'Name'(h02).
  header lt_headers '6'  'ID'       'Conflict ID'(h03).
  header lt_headers '7'  'TEXT'     'Conflict'(h04).
  if gf_mit_by_org = 'Y'.
    header lt_headers '8'  'ORG_ABB'  'Org. Area Abbrev.'(h20).
  endif.
  header lt_headers '8'  'EXECUTED' 'Executed'(h05).
  header lt_headers '9'  'CHANGES'  'Changes Made'(h06).
  IF lf_am_installed EQ 'X'.
  header lt_headers '10' 'AMALERTS' 'Automated Mitigations Alerts'(h07).
  ENDIF.
  IF lf_email_config EQ 'Y'.
  header lt_headers '11' 'SIGNOFF'  'Sign Off'(h08).
  ENDIF.

  l_subject = 'Users with SOD Conflicts'(tt1).
  CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
       EXPORTING
            attributes = l_tabstyle
            title      = l_subject
       TABLES
            i_headers  = lt_headers
            et_data    = ls_htmlt-html_table
            i_table    = lt_userconflicts.
  APPEND ls_htmlt TO lt_htmlt.

  CLEAR ls_htmlt.


  ls_htmlt-placeholder = '[USER_CA_TABLE]'.
  ls_htmlt-tag         = 'TABLE'.
  REFRESH lt_headers.
  header lt_headers '1'  'SOID'     'ID'(h12).
  header lt_headers '2'  'STDATE'   'Period Start'(h13).
  header lt_headers '3'  'EDDATE'   'End'(h14).
  header lt_headers '4'  'BNAME'    'User ID'(h01).
  header lt_headers '5'  'NAME'     'Name'(h02).
  header lt_headers '6'  'ID'       'Critical Authorization ID'(h09).
  header lt_headers '7'  'TEXT'     'Critical Authorization'(h10).
  header lt_headers '8'  'EXECUTED' 'Executed'(h05).
  header lt_headers '9'  'CHANGES'  'Changes Made'(h06).
  IF lf_am_installed EQ 'X'.
  header lt_headers '10' 'AMALERTS' 'Automated Mitigations Alerts'(h07).
  ENDIF.
  IF lf_email_config EQ 'Y'.
  header lt_headers '11' 'SIGNOFF'  'Sign Off'(h08).
  ENDIF.
  l_subject  = 'Users with Critical Authorizations'(tt2).
  CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
       EXPORTING
            attributes = l_tabstyle
            title      = l_subject
       TABLES
            i_headers  = lt_headers
            et_data    = ls_htmlt-html_table
            i_table    = lt_userca.
  APPEND ls_htmlt TO lt_htmlt.
  CLEAR ls_htmlt.


  ls_htmlt-placeholder = '[ROLE_SOD_TABLE]'.
  ls_htmlt-tag         = 'TABLE'.

  REFRESH lt_headers.
  header lt_headers '1' 'SOID'      'ID'(h12).
  header lt_headers '2' 'STDATE'    'Period Start'(h13).
  header lt_headers '3' 'EDDATE'    'End'(h14).
  header lt_headers '4' 'BNAME'     'Role'(h11).
  header lt_headers '5' 'NAME'      'Name'(h02).
  header lt_headers '6' 'ID'        'Conflict ID'(h03).
  header lt_headers '7' 'TEXT'      'Conflict'(h04).
  IF lf_email_config EQ 'Y'.
  header lt_headers '8' 'SIGNOFF'   'Sign Off'(h08).
  ENDIF.

  l_subject = 'Roles with SOD Conflicts'(tt3).
  CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
       EXPORTING
            attributes = l_tabstyle
            title      = l_subject
       TABLES
            i_headers  = lt_headers
            et_data    = ls_htmlt-html_table
            i_table    = lt_roleconflicts.
  APPEND ls_htmlt TO lt_htmlt.
  CLEAR ls_htmlt.

  ls_htmlt-placeholder = '[ROLE_CA_TABLE]'.
  ls_htmlt-tag         = 'TABLE'.

  REFRESH lt_headers.
  header lt_headers '1'  'SOID'     'ID'(h12).
  header lt_headers '2'  'STDATE'   'Period Start'(h13).
  header lt_headers '3'  'EDDATE'   'End'(h14).
  header lt_headers '4' 'BNAME'     'Role'(h11).
  header lt_headers '5' 'NAME'      'Name'(h02).
  header lt_headers '6' 'ID'        'Critical Authorization ID'(h09).
  header lt_headers '7' 'TEXT'      'Critical Authorization'(h10).
  IF lf_email_config EQ 'Y'.
  header lt_headers '8' 'SIGNOFF'   'Sign Off'(h08).
  ENDIF.

  l_subject  = 'Roles with Critical Authorizations'(tt4).
  CALL FUNCTION '/PSYNG/BC_HTML_TABLE'
       EXPORTING
            attributes = l_tabstyle
            title      = l_subject
       TABLES
            i_headers  = lt_headers
            et_data    = ls_htmlt-html_table
            i_table    = lt_roleca.
  APPEND ls_htmlt TO lt_htmlt.
  CLEAR ls_htmlt.



*--Add other placeholders to the html table
  add_placeholder lt_htmlt '[SYSTEM_ID]' sy-sysid.
  add_placeholder lt_htmlt '[CLIENT_ID]' sy-mandt.
  add_placeholder lt_htmlt '[AUDITOR_NAME]'  is_auditor_info-name_full.
  add_placeholder lt_htmlt '[MITIGATION_ID]' it_signoffs-contid.
*--Get [MITIGATION_NAME]
  PERFORM mit_info_placeholder
  USING it_signoffs-contid
  CHANGING lt_htmlt
  .



  REFRESH : lt_receivers.
  lt_receivers-bname = is_auditor_info-bname.
  APPEND lt_receivers.


  CONCATENATE 'Pathlock - Mitigation Review : '(s01)
              it_signoffs-contid
              INTO l_subject
              SEPARATED BY space.

*--get configured CSS template
se_config_param 'SW_CSS_EMAIL' l_css_temp.

*--Create the HTML e-mail, but don't send it
  CALL FUNCTION '/PSYNG/BC_HTML_EMAIL'
       EXPORTING
            header        = 'X'
            style         = l_css_temp "'/PSYNG/BC_EMAIL_CSS'
            template_name = l_send_templ
            title         = l_subject
            if_send_email = ''  "don't send the e-mail
       TABLES
            et_data       = lt_email_cont
            it_recipients = lt_receivers
       CHANGING
            it_data       = lt_htmlt.
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
*    I_PRIORITY                       = '5'
     i_sensitivity                    = ''
*    I_LANGUAGE                       = SY-LANGU
     i_receiver                        = is_auditor_info-smtp_addr
    TABLES
      lt_body                          = lt_email_cont
   EXCEPTIONS
     error_sending_email              = 1
     too_many_receivers               = 2
     document_not_sent                = 3
     document_type_not_exist          = 4
     operation_no_authorization       = 5
     parameter_error                  = 6
     x_error                          = 7
     enqueue_error                    = 8
     OTHERS                           = 9."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  IF sy-subrc <> 0.
    log et_messages 'E' 'Failed to Send E-Mail'
        it_signoffs-contid it_signoffs-auditor
        ''.
  ELSE.
    log et_messages 'S' 'E-Mail Sent'
        it_signoffs-auditor
        is_auditor_info-smtp_addr ''.
    MODIFY /psyng/se_emldec FROM TABLE lt_decisions.
    COMMIT WORK.
    REFRESH lt_decisions.
  ENDIF.
ENDFORM.                    " create_email_tables

*---------------------------------------------------------------------*
*       FORM get_mithdr_text                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_CONTID                                                      *
*  -->  E_TEXT                                                        *
*---------------------------------------------------------------------*
FORM get_mithdr_text USING i_contid
                     CHANGING e_text.
  STATICS : lt_mchdr TYPE TABLE OF /psyng/mchdr WITH HEADER LINE.

  READ TABLE lt_mchdr WITH KEY contid = i_contid
  BINARY SEARCH TRANSPORTING description.
  IF sy-subrc = 0.
    e_text = lt_mchdr-description.
  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
         EXPORTING
              contid                      = i_contid
         IMPORTING
              mchdr                       = lt_mchdr
         EXCEPTIONS
              mit_control_id_doesnt_exist = 1
              not_authorized_to_display   = 2
              OTHERS                      = 3.
    IF sy-subrc <> 0.
*--Text not found
      e_text = 'Unknown Mitigation'(um0).
    ELSE.
      APPEND lt_mchdr.
      SORT lt_mchdr BY contid.
      e_text = lt_mchdr-description.
    ENDIF.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_funhdr_text                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_FUNID                                                       *
*  -->  I_VRSIO                                                       *
*  -->  E_TEXT                                                        *
*---------------------------------------------------------------------*
FORM get_funhdr_text USING    i_funid
                              i_vrsio
                     CHANGING e_text.
  STATICS : lt_funhdr TYPE TABLE OF /psyng/function WITH HEADER LINE.

  READ TABLE lt_funhdr WITH KEY function = i_funid
  BINARY SEARCH TRANSPORTING description.
  IF sy-subrc = 0.
    e_text = lt_funhdr-description.
  ELSE.

    CALL FUNCTION '/PSYNG/SW_CR_READ_FUNCTIONID'
         EXPORTING
              functionid            = i_funid
              i_vrsio               = i_vrsio
         IMPORTING
              wa_function           = lt_funhdr
         EXCEPTIONS
              function_doesnt_exist = 1
              not_authorized        = 2
              OTHERS                = 3.
    IF sy-subrc <> 0.
*--Text not found
      e_text = 'Unknown Function'(um1).
    ELSE.
      APPEND lt_funhdr.
      SORT lt_funhdr BY function.
      e_text = lt_funhdr-description.
    ENDIF.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SIGNOFFS  text
*      <--P_LS_RECORD_TEXT  text
*----------------------------------------------------------------------*
FORM get_text USING   is_signoff TYPE /psyng/mcrvwsgn
              CHANGING e_text TYPE string
                       e_id   TYPE string.
  STATICS : lt_conflicts TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
            lt_ca        TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
            BEGIN OF lt_ca_vrsio OCCURS 0,
              vrsio TYPE /psyng/sodvrsio,
            END OF lt_ca_vrsio,
            BEGIN OF lt_sod_vrsio OCCURS 0,
              vrsio TYPE /psyng/sodvrsio,
            END OF lt_sod_vrsio.
  DATA :lt_conflicts_part TYPE TABLE OF /psyng/conflict,
        lt_ca_part        TYPE TABLE OF /psyng/swaudhdr.
  READ TABLE lt_sod_vrsio WITH KEY vrsio = is_signoff-vrsio
  TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
*--First time for this version, load all texts
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CONIDS'
         EXPORTING
              vrsio    = is_signoff-vrsio
         TABLES
              conflict = lt_conflicts_part.
    APPEND LINES OF lt_conflicts_part TO lt_conflicts.
    SORT lt_conflicts BY vrsio conid.
    FREE : lt_conflicts_part.
    lt_sod_vrsio-vrsio = is_signoff-vrsio.
    APPEND lt_sod_vrsio.
  ENDIF.

  READ TABLE lt_ca_vrsio WITH KEY vrsio = is_signoff-vrsio
  TRANSPORTING NO FIELDS.
  IF sy-subrc <> 0.
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CRIAUTHS'
         EXPORTING
              vrsio            = is_signoff-vrsio
         TABLES
              swaudhdr         = lt_ca_part
*              swaudc2          =
            EXCEPTIONS
              no_authorization = 1
              OTHERS           = 2. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    APPEND LINES OF lt_ca_part TO lt_ca.
    SORT lt_ca BY vrsio swaudid.
    FREE : lt_ca_part.
    lt_ca_vrsio-vrsio = is_signoff-vrsio.
    APPEND lt_ca_vrsio.
  ENDIF.

  CASE is_signoff-type.
    WHEN '1' OR '2' OR '4'.
      e_id = is_signoff-conid.
      READ TABLE lt_conflicts WITH KEY vrsio = is_signoff-vrsio
                                       conid = is_signoff-conid
      BINARY SEARCH TRANSPORTING description.
      IF sy-subrc = 0.
        e_text  = lt_conflicts-description.
      ELSE.
        e_text = 'Unknown Conflict'(t01).
      ENDIF.
    WHEN '3' OR '5'.
      e_id = is_signoff-swaudid.
      READ TABLE lt_ca WITH KEY vrsio = is_signoff-vrsio
                                swaudid = is_signoff-swaudid
      BINARY SEARCH TRANSPORTING description.
      IF sy-subrc = 0.
        e_text  = lt_ca-description.
      ELSE.
        e_text = 'Unknown Critical Authorization'(t02).
      ENDIF.
  ENDCASE.
ENDFORM.                    " get_text

*---------------------------------------------------------------------*
*       FORM _text                                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_SIGNOFFS                                                   *
*  -->  E_TEXT                                                        *
*  -->  E_ID                                                          *
*---------------------------------------------------------------------*
FORM get_header_text
USING     is_signoffs TYPE /psyng/mcrvwsgn
CHANGING  e_id      TYPE string
          e_text    TYPE string.
  STATICS :
            lt_roles    TYPE TABLE OF /psyng/sw_roleinfo
                        WITH HEADER LINE.

  DATA :  lt_rol      TYPE TABLE OF /psyng/sw_roleinfo
                      WITH HEADER LINE           .
  IF NOT is_signoffs-userid IS INITIAL.
*--Lookup user name
    e_id = is_signoffs-userid.
    PERFORM get_user_name USING is_signoffs-userid CHANGING e_text.
  ELSE.
*--Lookup role
    e_id = is_signoffs-agr_name.
    READ TABLE lt_roles WITH KEY agr_name =  is_signoffs-agr_name
    BINARY SEARCH TRANSPORTING title.
    IF sy-subrc = 0.
      e_text = lt_roles-title.
    ELSE.
      lt_rol-agr_name = is_signoffs-agr_name.
      APPEND lt_rol.
      CALL FUNCTION '/PSYNG/SW_ROLE_INFO'
           EXPORTING
                i_spras  = sy-langu
           TABLES
                it_roles = lt_rol.
      READ TABLE lt_rol INDEX 1.
      e_text = lt_rol-title.
      APPEND lt_rol TO lt_roles.
      SORT lt_roles BY agr_name.
    ENDIF.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_user_name                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_BNAME                                                       *
*  -->  E_FULLNAME                                                    *
*---------------------------------------------------------------------*
FORM get_user_name
  USING    i_bname
  CHANGING e_fullname.
  STATICS : lt_users    TYPE TABLE OF /psyng/bc_userid_name
                          WITH HEADER LINE.
  DATA :  lt_usr      TYPE TABLE OF /psyng/bc_userid_name
                      WITH HEADER LINE.

*--lookup user name
  READ TABLE lt_users WITH KEY bname =  i_bname
  BINARY SEARCH TRANSPORTING name_full.
  IF sy-subrc = 0.
    e_fullname = lt_users-name_full.
  ELSE.
    lt_usr-bname = i_bname.
    APPEND lt_usr.
    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
         EXPORTING
              no_email = 'X'
         TABLES
              username = lt_usr.
    READ TABLE lt_usr INDEX 1.
    e_fullname = lt_usr-name_full.
    APPEND lt_usr TO lt_users.
    SORT lt_users BY bname.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  mit_info_placeholder
*&---------------------------------------------------------------------*
*       Add Placeholders [MITIGATION_NAME] and [MITIGATION_DESC]
*----------------------------------------------------------------------*
*      -->i_contid  Mitigation ID
*----------------------------------------------------------------------*
FORM mit_info_placeholder
USING    i_contid TYPE  /psyng/contid
CHANGING  it_htmlt TYPE /psyng/bc_html_data_t.

  DATA : lt_texts TYPE TABLE OF /psyng/texts WITH HEADER LINE,
         ls_htmlt TYPE /psyng/bc_html_data,
         ls_mchdr TYPE /psyng/mchdr,
         l_text   TYPE string.
  CALL FUNCTION '/PSYNG/SW_CR_READ_MIT_CONTROLS'
       EXPORTING
            contid                      = i_contid
       IMPORTING
            mchdr                       = ls_mchdr
       TABLES
            texts                       = lt_texts
       EXCEPTIONS
            mit_control_id_doesnt_exist = 1
            not_authorized_to_display   = 2
            OTHERS                      = 3.
  IF sy-subrc = 0.
    add_placeholder it_htmlt '[MITIGATION_NAME]' ls_mchdr-description.
    SORT lt_texts BY line.
    LOOP AT lt_texts.
      CONCATENATE l_text lt_texts-text INTO l_text
      SEPARATED BY space.
    ENDLOOP.
    add_placeholder it_htmlt '[MITIGATION_DESC]' l_text.
  ENDIF.
ENDFORM.                    " mit_info_placeholder


*&---------------------------------------------------------------------*
*&      Form  get_response_template
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SIGNOFFS_CONTID  text
*      <--P_L_RESP_TEMP  text
*----------------------------------------------------------------------*
FORM get_response_template USING   i_contid TYPE  /psyng/contid
                           CHANGING e_resp_temp.

*--Get the default review text for this Mitigating control
  SELECT SINGLE dflt_review INTO e_resp_temp FROM /psyng/mcrvwhdr
  WHERE contid = i_contid.
  IF sy-subrc <> 0 OR  e_resp_temp IS INITIAL.
*--Get the global default
    se_config_param 'SW_MIT_SIGNOFF_TEXT' e_resp_temp.
  ENDIF.


ENDFORM.                    " get_response_template
*&---------------------------------------------------------------------*
*&      Form  get_response_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IS_AUDITOR_INFO_BNAME  text
*      <--P_L_BODY_TEXT  text
*----------------------------------------------------------------------*
FORM get_response_text USING    i_bname TYPE xubname
                                i_template
                       CHANGING e_text TYPE string.
  PERFORM init_new_line.
  DATA : lt_all_langu TYPE TABLE OF /psyng/langu_user
         WITH HEADER LINE,
         lt_lines TYPE TABLE OF tline WITH HEADER LINE.
  CLEAR e_text.
  CALL FUNCTION '/PSYNG/BC_005'
       EXPORTING
            i_bname       = i_bname
       TABLES
            et_langu_user = lt_all_langu.
  SORT lt_all_langu BY priority.
  READ TABLE lt_all_langu INDEX 1.
  IF sy-subrc = 0.
    CALL FUNCTION 'READ_TEXT'
         EXPORTING
              id                      = 'ST'
              language                = lt_all_langu-langu
              name                    = i_template
              object                  = 'TEXT'
         TABLES
              lines                   = lt_lines
         EXCEPTIONS
              id                      = 1
              language                = 2
              name                    = 3
              not_found               = 4
              object                  = 5
              reference_check         = 6
              wrong_access_to_archive = 7
              OTHERS                  = 8. "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
*--Try to read in english if user language not found
      CALL FUNCTION 'READ_TEXT'
           EXPORTING
                id                      = 'ST'
                language                = 'E'
                name                    = i_template
                object                  = 'TEXT'
           TABLES
                lines                   = lt_lines
           EXCEPTIONS
                id                      = 1
                language                = 2
                name                    = 3
                not_found               = 4
                object                  = 5
                reference_check         = 6
                wrong_access_to_archive = 7
                OTHERS                  = 8. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
    ENDIF.
  ENDIF.

  IF NOT lt_lines[] IS INITIAL.
    LOOP AT lt_lines.
      IF lt_lines-tdformat = '*'."start of new line
        CONCATENATE e_text s_new_line INTO e_text.
      ENDIF.
      CONCATENATE e_text lt_lines-tdline INTO e_text.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " get_response_text
*&---------------------------------------------------------------------*
*&      Form  prepare_review_report_details
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ET_SUMMARY  text
*      -->P_ET_DETAILS  text
*----------------------------------------------------------------------*
FORM prepare_review_report_details
TABLES   it_summary STRUCTURE /psyng/mcrvwsgn
         et_details STRUCTURE /psyng/sw_mc_review_report
USING
         i_bname    TYPE xubname.

  DATA : lf_just TYPE flag,
         l_dummy TYPE string,
         l_dsc   TYPE string.
  LOOP AT it_summary.
    CLEAR et_details.
    et_details-signoffid      = it_summary-signoffid.
    et_details-auditor        = it_summary-auditor.
    et_details-org_abb        = it_summary-org_abb.
    PERFORM get_user_name
    USING    et_details-auditor
    CHANGING et_details-auditor_name.

    et_details-contid         = it_summary-contid.
    PERFORM get_mithdr_text
                USING
                   et_details-contid
                CHANGING
                   et_details-contid_desc.

    et_details-vrsio          = it_summary-vrsio.
    CASE it_summary-type.
      WHEN '1' OR '2' OR '4'.
        et_details-assign_type = 'SOD Conflict'(at1).
        et_details-assign_id   = it_summary-conid.
      WHEN '3' OR '5'.
        et_details-assign_type = 'Critical Authorization'(at2).
        et_details-assign_id   = it_summary-swaudid.
      WHEN OTHERS.
        et_details-assign_type = 'Unknown'(at3).
    ENDCASE.
*--Get the Mitigated Object Text
    PERFORM get_text
                USING
                   it_summary
                CHANGING
                   l_dsc
                   l_dummy
                   .
    et_details-assign_desc = l_dsc.

    CASE it_summary-type.
      WHEN '4' OR '5'.
        if it_summary-userid is initial.
          et_details-target_type = 'Role'(at4).
          et_details-target_id   = it_summary-agr_name.
        else.
*--Assigned to user through role
          et_details-target_type = 'User'(at5).
          et_details-target_id   = it_summary-userid.
        endif.
      WHEN '1' OR '2' OR '3'.
        et_details-target_type = 'User'(at5).
        et_details-target_id   = it_summary-userid.
      WHEN OTHERS.
        et_details-target_type = 'Unknown'(at3).
    ENDCASE.
*--Get the Target Text
    PERFORM get_header_text
                USING
                   it_summary
                CHANGING
                   l_dummy
                   l_dsc.
    et_details-target_desc = l_dsc.

    et_details-from_date        = it_summary-from_date.
    et_details-to_date          = it_summary-to_date.
    et_details-tcode_executed   = it_summary-tcode_executed.
    et_details-changes_made     = it_summary-changes_made.
    et_details-am_alerts_open   = it_summary-am_alerts_open.
    et_details-signoff_date     = it_summary-signoff_date.
    et_details-signoff_time     = it_summary-signoff_time.
    et_details-signoff_complete = it_summary-signoff_complete.
*--Check if a justification is present
    CLEAR lf_just.
    CALL FUNCTION '/PSYNG/SW_MC_JUSTIFICATION'
         EXPORTING
              if_signoff           = 'X'
              if_check             = 'X'
              i_mcid               = it_summary-contid
              is_signoff           = it_summary
         IMPORTING
              ef_has_justification = lf_just
         EXCEPTIONS
              invalid_input        = 1
              not_implemented      = 2
              gos_failure          = 3
              OTHERS               = 4.
    IF sy-subrc = 0 AND lf_just = 'X'.
      et_details-just = '@DK@'.
    ENDIF.
*--Check if an attachment is present
    CLEAR lf_just.

    CALL FUNCTION '/PSYNG/SW_MC_ATTACHMENTS'
         EXPORTING
              if_signoff         = 'X'
              if_check           = 'X'
              i_mcid             = it_summary-contid
              is_signoff         = it_summary
         IMPORTING
              ef_has_attachments = lf_just
         EXCEPTIONS
              invalid_input      = 1
              not_implemented    = 2
              gos_failure        = 3
              OTHERS             = 4.
    IF sy-subrc = 0 AND lf_just = 'X'.
      et_details-attachment = '@FM@'.
    ENDIF.
    IF it_summary-signoff_complete <> 'X'.
      IF it_summary-auditor  = i_bname.
*--It's unreviewed and this user can review it
        et_details-review = '@8X@'.
      ENDIF.
    ELSE.
      IF it_summary-signoff_type = 'M'.
        et_details-signoff_type =  '@BM@'.
      ELSE.
        et_details-signoff_type =  '@6K@'.
      ENDIF.
    ENDIF.
    APPEND et_details.
  ENDLOOP.

ENDFORM.                    " prepare_review_report_details
*---------------------------------------------------------------------*
*       FORM init_new_line                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM init_new_line.
  DATA : l_class_name(24) TYPE c VALUE 'CL_ABAP_CHAR_UTILITIES',
         l_attr_name(7)  TYPE c VALUE 'NEWLINE',
         l_class_ref(33)  TYPE c.
  FIELD-SYMBOLS: <attr> TYPE ANY.
  IF s_new_line IS INITIAL.
    CONCATENATE l_class_name '=>' l_attr_name INTO l_class_ref.
    ASSIGN (l_class_ref) TO <attr>. "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA:Variable value is not constant so it can’t be fixed.(17/12/24)
    IF sy-subrc <> 0.
*CL_ABAP_CHAR_UTILITIES=>NEWLINE doesn't exist (4.6c system)
      ASSIGN new_line TO <attr>.
    ENDIF.
    MOVE <attr> TO s_new_line.
  ENDIF.
ENDFORM.                    " init_new_line
*&---------------------------------------------------------------------*
*&      Form  display_changes_made_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_DETAILS_DISPLAY  text
*----------------------------------------------------------------------*
FORM display_changes_made_alv
TABLES
      it_details STRUCTURE /psyng/sw_level3_display
USING
      i_bname   TYPE xubname
      i_conid   TYPE /psyng/conflict_id
      i_swaudid TYPE /psyng/swaudid.

  DATA : lt_sort     TYPE TABLE OF slis_sortinfo_alv WITH HEADER LINE,
         ls_title    TYPE lvc_title,
         ls_layout   TYPE slis_layout_alv,
         ls_variant  TYPE disvariant,
         l_program   TYPE sy-repid,
         l_str       TYPE string,
         lt_fieldcat TYPE slis_t_fieldcat_alv,
         ls_fieldcat TYPE slis_fieldcat_alv.

  IF i_conid IS INITIAL.
    l_str = i_swaudid.
  ELSE.
    l_str = i_conid.
  ENDIF.

  CONCATENATE 'Overview of changes by '(a26)
              i_bname
              'in'(a27)
              l_str
              INTO ls_title SEPARATED BY space.

  DEFINE add_sort.
    add 1 to lt_sort-spos.
    lt_sort-fieldname = &1.
    append lt_sort.
  END-OF-DEFINITION.
  DEFINE add_column.
    add 1 to ls_fieldcat-col_pos.
    ls_fieldcat-fieldname    = &1.
    ls_fieldcat-seltext_l    = &2.
    ls_fieldcat-seltext_m    = &2.
    ls_fieldcat-seltext_s    = &2.
    ls_fieldcat-reptext_ddic = &2.
    ls_fieldcat-hotspot      = &3.
    ls_fieldcat-no_out       = &4.
    append ls_fieldcat to lt_fieldcat.
  END-OF-DEFINITION.

*--Create field catalog
  add_column :
    'BNAME'   'User ID'(a05)     ''  ''.
  IF i_conid IS INITIAL.
*--Critical Auth
    add_column :
      'CONID'   'Conflict ID'(a06)        ''  'X',
      'FUNID'   'Critical Auth Id'(a07)   ''  '',
      'FUNTEXT' 'Critical Auth Text'(a08) ''  ''.
  ELSE.
*--Conflict
    add_column :
      'CONID'   'Conflict ID'(a06)   ''  'X',
      'FUNID'   'Function Id'(a09)   ''  '',
      'FUNTEXT' 'Function Text'(a10) ''  ''.
  ENDIF.
  add_column :
    'DATE'         'Date'(a11)   ''  '',
    'TIME'         'Time'(a12)   ''  '',
    'TCODE'        'Transaction Code'(a13)  ''  '',
    'TTEXT'        'Transaction text'(a14)  ''  '',
    'TYPE'         'Change Type'(a15)       ''  '',
    'TABLE'        'Table'(a16)             ''  '',
    'LOGKEY'       'Log Key'(a17)           ''  '' ,
    'CHANGE_TYPE'  'Type'(a18)              ''  '',
    'FIELDNAME'    'Field Name'(a19)        ''  '',
    'FIELDTEXT'    'Field Text'(a20)        ''  '',
    'VALUE'        'Old Value'(a21)         ''  '',
    'NEWVAL'       'New Value'(a22)         ''  ''.
*--Layout
  ls_layout-zebra             = 'X'.
  ls_layout-colwidth_optimize = 'X'.

*--Create ALV Sort order
  add_sort :
        'BNAME' ,
        'CONID' ,
        'FUNID' ,
        'FUNTEXT' ,
        'DATE',
        'TIME',
        'TCODE',
        'TTEXT',
        'TYPE',
        'TABLE',
        'LOGKEY',
        'CHANGE_TYPE',
        'FIELDNAME',
        'FIELDTEXT',
        'VALUE',
        'NEWVAL'.
  l_program = sy-repid.
*--Display the Grid

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_grid_title            = ls_title
*            i_callback_top_of_page  = 'LEVEL3_ALV_HEADER'
*            i_callback_user_command = 'HOTSPOT_CLICK'
            i_callback_program      = l_program
            it_sort                 = lt_sort[]
            is_layout               = ls_layout
            it_fieldcat             = lt_fieldcat[]
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = it_details
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " display_changes_made_alv
