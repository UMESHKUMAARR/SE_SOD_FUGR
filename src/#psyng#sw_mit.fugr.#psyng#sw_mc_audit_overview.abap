FUNCTION /psyng/sw_mc_audit_overview.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IT_AUDITORS STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_MCID STRUCTURE  /PSYNG/SW_SEL_OPTS_CONTID OPTIONAL
*"      ET_OVERVIEW STRUCTURE  /PSYNG/SW_MC_AUDIT_OVERVIEW
*"----------------------------------------------------------------------
  DATA : lt_users TYPE TABLE OF /psyng/mcrvwsgn WITH HEADER LINE,
        lt_sod_usr_rev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE ,
      lt_sod_usr_unrev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
         lt_ca_usr_rev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
       lt_ca_usr_unrev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
        lt_ca_role_rev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
      lt_ca_role_unrev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
       lt_sod_role_rev TYPE SORTED TABLE OF /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
         lt_sod_role_unrev TYPE SORTED TABLE OF
                                       /psyng/sw_mc_audit_overview
         WITH UNIQUE KEY auditor contid from_date to_date
         WITH HEADER LINE,
         lt_user_name TYPE TABLE OF /psyng/bc_userid_name
         WITH HEADER LINE,
         lt_mchdr TYPE TABLE OF /psyng/mchdr WITH HEADER LINE,
         lt_mchdr_t TYPE TABLE OF /psyng/mchdr WITH HEADER LINE.
  RANGES : lr_auditor FOR sy-uname.
*--Get all users that have pending reviews
  SELECT auditor
  contid from_date to_date
  FROM /psyng/mcrvwsgn
  INTO CORRESPONDING FIELDS OF TABLE lt_users
  WHERE signoff_complete = '' AND
        auditor          IN it_auditors AND
        contid           IN it_mcid
    GROUP BY
      AUDITOR contid FROM_DATE to_date
    ORDER BY
      auditor contid from_date to_date.
  lr_auditor-sign   = 'I'.
  lr_auditor-option = 'EQ'.
  LOOP AT lt_users.
*--SOD Conflict UN-Reviewed by user
    SELECT contid auditor from_date to_date
    COUNT( * ) AS sod_usr_unrev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_sod_usr_unrev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = '' AND
      ( type      = 1 OR type = 2 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--SOD Conflict Reviewed by user
    SELECT contid auditor from_date to_date
    COUNT( * ) AS sod_usr_rev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_sod_usr_rev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = 'X' AND
      ( type      = 1 OR type = 2 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--CA Un-Reviewed by user
    SELECT contid auditor from_date to_date
    COUNT( * ) AS ca_usr_unrev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_ca_usr_unrev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = '' AND
      ( type      = 3 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--CA Reviewed by user
    SELECT contid auditor from_date to_date
    COUNT( * ) AS ca_usr_rev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_ca_usr_rev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = 'X' AND
      ( type      = 3 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--SOD Conflict UN-Reviewed by Role
    SELECT contid auditor from_date to_date
    COUNT( * ) AS sod_role_unrev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_sod_role_unrev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = '' AND
      ( type      = 4 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--SOD Conflict Reviewed by user
    SELECT contid auditor from_date to_date
    COUNT( * ) AS sod_role_rev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_sod_role_rev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = 'X' AND
      ( type      = 4 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--CA Un-Reviewed by Role
    SELECT contid auditor from_date to_date
    COUNT( * ) AS ca_role_unrev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_ca_role_unrev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = '' AND
      ( type      = 5 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--CA Reviewed by role
    SELECT contid auditor from_date to_date
    COUNT( * ) AS ca_role_rev
    APPENDING CORRESPONDING FIELDS OF TABLE lt_ca_role_rev
    FROM /psyng/mcrvwsgn
    WHERE
      auditor   = lt_users-auditor   AND
      contid    = lt_users-contid    AND
      from_date = lt_users-from_date AND
      to_date   = lt_users-to_date   AND
      signoff_complete = 'X' AND
      ( type      = 5 )
    GROUP by
      auditor contid from_date to_date
    ORDER BY
      auditor contid from_date to_date.
*--Collect users
    lt_user_name-bname = lt_users-auditor.
    COLLECT lt_user_name.
*--Collect mcids
    lt_mchdr-contid =   lt_users-contid.
    COLLECT lt_mchdr.
  ENDLOOP.
  DEFINE get_count.
    read table &1 with table key
      auditor   = lt_users-auditor
      contid    = lt_users-contid
      from_date = lt_users-from_date
      to_date   = lt_users-to_date.
    if sy-subrc = 0.
      &2 = &3.
    endif.
  END-OF-DEFINITION.
*--merge all these tables in the output table
*--Get all user info
  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
       EXPORTING
            no_email = 'X'
       TABLES
            username = lt_user_name.
  SORT lt_user_name BY bname.
*--Get al MCid texts
  if not lt_mchdr[] is initial.
    SELECT contid description FROM /psyng/mchdr
    INTO CORRESPONDING FIELDS OF TABLE lt_mchdr_t
    FOR ALL ENTRIES IN lt_mchdr WHERE
    contid = lt_mchdr-contid.
  endif.
  SORT lt_mchdr_t BY contid.
  LOOP AT lt_users.
    clear et_overview.
    MOVE-CORRESPONDING lt_users TO et_overview.
    get_count : lt_sod_usr_rev
                  et_overview-sod_usr_rev lt_sod_usr_rev-sod_usr_rev,
                lt_sod_usr_unrev
                  et_overview-sod_usr_unrev
                  lt_sod_usr_unrev-sod_usr_unrev,
                lt_ca_usr_rev et_overview-ca_usr_rev
                  lt_ca_usr_rev-ca_usr_rev,
                lt_ca_usr_unrev
                  et_overview-ca_usr_unrev lt_ca_usr_unrev-ca_usr_unrev,
                lt_ca_role_rev  et_overview-ca_role_rev
                  lt_ca_usr_rev-ca_role_rev,
                lt_ca_role_unrev  et_overview-ca_role_unrev
                  lt_ca_role_unrev-ca_role_unrev,
                lt_sod_role_rev  et_overview-sod_role_rev
                  lt_sod_usr_rev-sod_role_rev,
                lt_sod_role_unrev  et_overview-sod_role_unrev
                  lt_sod_role_unrev-sod_role_unrev.
    READ TABLE lt_user_name WITH KEY bname = lt_users-auditor
    BINARY SEARCH TRANSPORTING name_full.
    IF sy-subrc = 0.
      et_overview-auditor_name = lt_user_name-name_full.
    ENDIF.
    READ TABLE lt_mchdr_t WITH KEY contid = lt_users-contid
    BINARY SEARCH TRANSPORTING description.
    IF sy-subrc = 0.
      et_overview-description = lt_mchdr_t-description.
    ENDIF.
    APPEND et_overview.
  ENDLOOP.
  SORT et_overview BY contid auditor from_date to_date.
ENDFUNCTION.
