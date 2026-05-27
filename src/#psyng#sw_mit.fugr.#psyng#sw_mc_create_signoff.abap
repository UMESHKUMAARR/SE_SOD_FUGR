FUNCTION /psyng/sw_mc_create_signoff .
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(I_VALIDITY_DATE) TYPE  DATS DEFAULT SY-DATUM
*"     REFERENCE(I_VRSIO) TYPE  /PSYNG/SODVRSIO
*"     VALUE(IF_TEST) TYPE  FLAG DEFAULT ''
*"     VALUE(IF_AUTO_SIGNOFF) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      IT_CONTID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      IT_AUDITOR STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      ET_MESSAGES STRUCTURE  BAPIRET2 OPTIONAL
*"      ET_SIGNOFF STRUCTURE  /PSYNG/MCRVWSGN OPTIONAL
*"      IT_SODUSER STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_CAUSER STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_SODROLE STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"      IT_CAROLE STRUCTURE  /PSYNG/SW_SEL_OPTS_AGR_NAME OPTIONAL
*"----------------------------------------------------------------------
  DATA : lt_mcuser        TYPE TABLE OF /psyng/mcuser WITH HEADER LINE,
         lt_assignments   TYPE TABLE OF /psyng/mitigation_assignment
                             WITH HEADER LINE,
         lt_assignments_t TYPE TABLE OF /psyng/mitigation_assignment
                             WITH HEADER LINE,
         l_cnt            TYPE i,
         l_mit_by_role_status TYPE string.

  se_config_param 'SW_MIT_BY_ROLE' l_mit_by_role_status.
  PERFORM init_new_line.
*--Load mitigation frequencies into table gt_mc_freq
  PERFORM load_frequencies.
*--Load SOD Matrix
  PERFORM load_matrix USING i_vrsio
                            'X' "all
                            ''  "no conid
                            ''.  "no swaudid

*--Get all assignments of each type and put in common table

*-Type 1 - Conflict Mitigation assignment to user
*  and
*-Type 2 - Conflict Mitigation assignment to user group
*  and
*-Type 4 - Conflict Mitigation assignment to role
  CALL FUNCTION '/PSYNG/SW_071'
       EXPORTING
            i_vrsio      = i_vrsio
            i_start_date = i_validity_date
            i_end_date   = i_validity_date
       TABLES
            it_users     = IT_SODUSER
            et_mcusers   = lt_assignments_t.
  DELETE lt_assignments_t WHERE NOT contid  IN it_contid.
  APPEND LINES OF lt_assignments_t TO lt_assignments.
  DESCRIBE TABLE lt_assignments_t LINES l_cnt.
  log et_messages 'S' 'Conflict Mitigations :'(001) l_cnt '' ''.

  REFRESH : lt_assignments_t.
*-Type 3 - Critical Auth Mitigation assignment to user
*  and
*-Type 5 - Critical Auth Mitigation assignment to role
  CALL FUNCTION '/PSYNG/SW_096'
       EXPORTING
            i_vrsio      = i_vrsio
            i_start_date = i_validity_date
            i_end_date   = i_validity_date
       TABLES
            it_users     = IT_CAUSER
            et_mcusers   = lt_assignments_t.
  DELETE lt_assignments_t WHERE NOT contid  IN it_contid.
  APPEND LINES OF lt_assignments_t TO lt_assignments.
  DESCRIBE TABLE lt_assignments_t LINES l_cnt.
  log et_messages 'S' 'CA Mitigations :'(002) l_cnt '' ''.

  IF l_mit_by_role_status = '2' OR l_mit_by_role_status = '3'.
*--Load the role SOD assignments that are only applicatble to roles.
    REFRESH : lt_assignments_t.
    SELECT * FROM /psyng/mcrole
    INTO CORRESPONDING FIELDS OF TABLE lt_assignments_t
    WHERE vrsio = i_vrsio AND
      from_date LE i_validity_date AND
      to_date   GE i_validity_date AND
      contid    IN it_contid       AND
      agr_name  IN IT_SODROLE      .
    lt_assignments_t-type = '4'.
    modify  lt_assignments_t  transporting type where type = ''.
    APPEND LINES OF lt_assignments_t TO lt_assignments.
    DESCRIBE TABLE lt_assignments_t LINES l_cnt.
    log et_messages 'S' 'Role Conflict Mitigations :'(005) l_cnt '' ''.
*--Load the role CA assignments that are only applicatble to roles.
    REFRESH : lt_assignments_t.
    SELECT * FROM /psyng/mccarole
    INTO CORRESPONDING FIELDS OF TABLE lt_assignments_t
    WHERE vrsio = i_vrsio AND
      from_date LE i_validity_date AND
      to_date   GE i_validity_date AND
      contid IN it_contid          AND
      agr_name  IN IT_CAROLE      .
    lt_assignments_t-type = '5'.
    modify  lt_assignments_t  transporting type  where type = ''.

    APPEND LINES OF lt_assignments_t TO lt_assignments.
    DESCRIBE TABLE lt_assignments_t LINES l_cnt.
    log et_messages 'S' 'Role CA Mitigations :'(006) l_cnt '' ''.

  ENDIF.
*--Now for each of these, create signoff records
  PERFORM create_signoff_records
                                 TABLES lt_assignments
                                        et_messages
                                        ET_SIGNOFF
                                 USING i_validity_date
                                       if_test
                                       if_auto_signoff.
ENDFUNCTION.
