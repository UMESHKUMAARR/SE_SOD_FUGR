*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_140_MACROS                                       *
*----------------------------------------------------------------------*
FIELD-SYMBOLS : <m_roles> TYPE /psyng/swrrsrol.
*--Create a value table from an index table
DEFINE invert_index.
  refresh : &2.
  loop at &1.
    insert &1 into table &2.
  endloop.
END-OF-DEFINITION.

*--Get index for a table with key and index
DEFINE get_index.
  read table &1 with table key key = &2.
  if sy-subrc = 0.
    &3 = &1-index.
  else.
    &1-key = &2.
    add 1 to &4.
    &1-index = &4.
    insert table &1.
    &3 = &1-index.
  endif.
END-OF-DEFINITION.

DEFINE register_task.
  gt_idx_task-task  = &1.
  condense gt_idx_task-task.
  gt_idx_task-sysid = &2.
  insert table gt_idx_task.
END-OF-DEFINITION.

*--Store role Details
DEFINE store_role.
  read table gt_db_roles with table key roleindex = &1.
  if sy-subrc <> 0.
    move-corresponding &2 to gt_db_roles.
    if not &3 is initial.
*    gt_db_roles-agr_text = &3-title.
     gt_db_roles-agr_text = &3-text.
    endif.
    gt_db_roles-roleindex = &1.
    insert table gt_db_roles.
  endif.
END-OF-DEFINITION.
*--Update conflicts/mit conflicts for a role
DEFINE role_count_con.
  read table gt_db_roles assigning <m_roles>
  with key agr_name = &1.
  if sy-subrc = 0.
    <m_roles>-NR_CONFLICTS = &2.
    <m_roles>-NR_MITIGATED = &3.
  endif.
END-OF-DEFINITION.
*--Store role function abbreviation combo
DEFINE store_rolefunabb    .
  read table gt_db_rfunabb with table key
    roleindex = &1
    funindex  = &2
    abbindex  = &3.
  if sy-subrc <> 0.
    gt_db_rfunabb-roleindex = &1.
    gt_db_rfunabb-funindex  = &2.
    gt_db_rfunabb-abbindex  = &3.
    insert table gt_db_rfunabb.
  endif.
END-OF-DEFINITION.
*--Store Role Conflict Combo
DEFINE store_rolecon.
  read table gt_db_rolecon with table key roleindex = &1
                                          conindex  = &2.
  if sy-subrc <> 0.
    clear gt_db_rolecon-mitigated.
    gt_db_rolecon-roleindex = &1.
    gt_db_rolecon-conindex  = &2.
    if &3 is not initial.
      gt_db_rolecon-mitigated = 'X'.
    endif.
    insert table gt_db_rolecon.
  endif.
END-OF-DEFINITION.
*--Store Conflict Function Combo
DEFINE store_confun.
  read table gt_db_confun with table key conindex = &1
                                         funindex = &2.
  if sy-subrc <> 0.
    gt_db_confun-conindex = &1.
    gt_db_confun-funindex  = &2.
    insert table gt_db_confun.
  endif.
END-OF-DEFINITION.
*--Store Role Child role combo
DEFINE store_rolechild.
  read table gt_db_rolechild with table key roleindex  = &1
                                            authindex  = &2
                                            childindex = &3.
  if sy-subrc <> 0.
    gt_db_rolechild-roleindex      = &1.
    gt_db_rolechild-authindex      = &2.
    gt_db_rolechild-childindex     = &3.
    insert table gt_db_rolechild.
  endif.
END-OF-DEFINITION.
*--Store System Function Profile details
DEFINE store_authdetails.

  read table gt_db_vonbisabb with table key
    von          = &8
    bis          = &9
    abb          = gt_db_vonbisabb-abb.
  if sy-subrc <> 0.
*    get a new VBA ID
    call function '/PSYNG/SW_SESTORE_NEW_VBAID'
         importing
              resid = g_idx_vba
*BOC:HBHALLA (03/12/24)
        EXCEPTIONS
             OTHERS     = 1.  "#EC SAST_CI_GEN_CHECK
          IF sy-subrc <> 0.
           CASE sy-subrc.
             WHEN OTHERS.
                MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
           ENDCASE.
          ENDIF.
*EOC:HBHALLA (03/12/24)
    gt_db_vonbisabb-vbaindex = g_idx_vba.
    gt_db_vonbisabb-von   = &8.
    gt_db_vonbisabb-bis   = &9.
    insert table gt_db_vonbisabb.
  endif.

  read table gt_db_authdetails with table key
      sys          = &1
      funindex     = &2
      profileindex = &3
      tcodeindex   = &4
      objectindex  = &5
      fieldindex   = &6
      authindex    = &7
      vbaindex     = gt_db_vonbisabb-vbaindex.
  if sy-subrc <> 0.
    gt_db_authdetails-sys             = &1.
    gt_db_authdetails-funindex        = &2.
    gt_db_authdetails-profileindex    = &3.
    gt_db_authdetails-tcodeindex      = &4.
    gt_db_authdetails-objectindex     = &5.
    gt_db_authdetails-fieldindex      = &6.
    gt_db_authdetails-authindex       = &7.
    gt_db_authdetails-vbaindex        = gt_db_vonbisabb-vbaindex.
    insert table gt_db_authdetails.
  endif.
END-OF-DEFINITION.
*--Logging stuff
DEFINE msg.
  message s002(/psyng/sw) with &1 &2 &3 &4.
  commit work.
END-OF-DEFINITION.
DEFINE msg_nc. "without commit
  message s002(/psyng/sw) with &1 &2 &3 &4.
END-OF-DEFINITION.
