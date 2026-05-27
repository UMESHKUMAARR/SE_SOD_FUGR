*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_140_MACROS                                       *
*----------------------------------------------------------------------*
FIELD-SYMBOLS : <m_users> TYPE /psyng/swresusr.
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

*DEFINE get_idx_value.
DEFINE register_task.
  gt_idx_task-task  = &1.
  condense gt_idx_task-task.
  gt_idx_task-sysid = &2.
  insert table gt_idx_task.
END-OF-DEFINITION.

*END-OF-DEFINITION.
*--Get index for a table with key and index AND SYS
DEFINE get_index_sys.
  read table &1 with table key sys = &5 key = &2.
  if sy-subrc = 0.
    &3 = &1-index.
  else.
    &1-key = &2.
    &1-sys = &5.
    add 1 to &4.
    &1-index = &4.
    insert table &1.
    &3 = &1-index.
  endif.
END-OF-DEFINITION.
*--Store user Details
DEFINE store_user.
  read table gt_db_users with table key userindex = &1.
  if sy-subrc <> 0.
    move-corresponding &2 to gt_db_users.
    gt_db_users-userindex = &1.
    read table gt_users with table key bname = gt_db_users-bname.
    if sy-subrc = 0.
      check_locked gt_users gt_db_users-locked.
      gt_db_users-gltgb = gt_users-gltgb.
      gt_db_users-gltgv = gt_users-gltgv.
    endif.
    read table gt_uinfo with  key bname = gt_db_users-bname
    binary search.
    if sy-subrc = 0.
      gt_db_users-kostl = gt_uinfo-kostl.
    endif.
    read table gt_usr06 with table key bname = gt_db_users-bname.
    if sy-subrc = 0.
      gt_db_users-lic_type = gt_usr06-lic_type.
    endif.
    insert table gt_db_users.
  endif.
END-OF-DEFINITION.
*--Update conflicts/mit conflicts for a user
DEFINE user_count_con.
  read table gt_db_users assigning <m_users>
  with key bname = &1.
  if sy-subrc = 0.
    <m_users>-NR_CONFLICTS = &2.
    <m_users>-NR_MITIGATED = &3.
  endif.
END-OF-DEFINITION.
*--check if a user is locked
DEFINE check_locked.
  l_uflag = &1-uflag.
  clear &2.
  if l_uflag o yusloc or "locked by admin
     l_uflag o yugloc.   "locked by CUA admin
*--User is locked by Local or Global Administrator
    if dsp_mng_lock <> 'Y'.
      &2 = 'X'.
    endif.
  elseif l_uflag o yulock.
*--User is locked by failed logins
    if dsp_slf_lock <> 'Y'.
      &2 = 'X'.
    endif.
  endif.
END-OF-DEFINITION.
*--Store user function abbreviation combo
DEFINE store_userfunabb    .
  read table gt_db_ufunabb with table key
    userindex = &1
    funindex  = &2
    abbindex  = &3.
  if sy-subrc <> 0.
    gt_db_ufunabb-userindex = &1.
    gt_db_ufunabb-funindex  = &2.
    gt_db_ufunabb-abbindex  = &3.
    insert table gt_db_ufunabb.
  endif.
END-OF-DEFINITION.
*--Store User Conflict Combo
DEFINE store_usercon.
  read table gt_db_usercon with table key userindex = &1
                                          conindex  = &2.
  if sy-subrc <> 0.
    clear gt_db_usercon-MITIGATED.
    gt_db_usercon-userindex = &1.
    gt_db_usercon-conindex  = &2.
    if &3 is not initial.
      gt_db_usercon-MITIGATED = 'X'.
    endif.
    gt_db_usercon-origin = &4. "Changes by RGUPTA on 16.03.22 for C0633
    insert table gt_db_usercon.
  endif.
END-OF-DEFINITION.
*--Store Conflicts Count
DEFINE store_concont.
*  read table gt_db_concont with table key sys = &1
*                                          conindex = &2
*                                          abbindex = &3.
*  if sy-subrc <> 0.
*    clear gt_db_usercon-MITIGATED.
  CLEAR: gt_db_concont-mitigated_con.
  gt_db_concont-sys = &1.
  gt_db_concont-conindex  = &2.
  gt_db_concont-abbindex  = &3.
  if &4 is not initial.
    gt_db_concont-mitigated_con = 1.
  endif.
    gt_db_concont-conflicts = 1.
  collect gt_db_concont.
*  endif.
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
*--Store System Function Profile combo
DEFINE store_funprofile.
  read table gt_db_funprofile with table key sys           = &1
                                             funindex      = &2
                                             profileindex  = &3
*Added by : UMITTAL C1342 D67K931619 14/05/2024
                                             userindex     = &4.
  if sy-subrc <> 0.
    gt_db_funprofile-sys           = &1.
    gt_db_funprofile-funindex      = &2.
    gt_db_funprofile-profileindex  = &3.
*Added by : UMITTAL C1342 D67K931619 14/05/2024
    gt_db_funprofile-userindex     = &4.
    insert table gt_db_funprofile.
  endif.
END-OF-DEFINITION.
*--Store System  Profile Role combo
DEFINE store_profilerole.
  read table gt_db_profilerole with table key sys           = &1
                                              profindex     = &2
                                              roleindex     = &3.
  if sy-subrc <> 0.
    gt_db_profilerole-sys          = &1.
    gt_db_profilerole-profindex    = &2.
    gt_db_profilerole-roleindex    = &3.
    insert table gt_db_profilerole.
  endif.
END-OF-DEFINITION.
*--Store System User Profile combo
DEFINE store_userprofile.
  read table gt_db_userprofile with table key sys           = &1
                                              userindex     = &2
                                              profileindex  = &3.
  if sy-subrc <> 0.
    gt_db_userprofile-sys          = &1.
    gt_db_userprofile-userindex    = &2.
    gt_db_userprofile-profileindex = &3.
    insert table gt_db_userprofile.
  endif.
END-OF-DEFINITION.
*--Store System User Role Composite combo
DEFINE store_usercomposite.
  read table gt_db_usercomposite with table key sys       = &1
                                                userindex = &2
                                                roleindex = &3
                                                compindex = &4.
  if sy-subrc <> 0.
    gt_db_usercomposite-sys        = &1.
    gt_db_usercomposite-userindex  = &2.
    gt_db_usercomposite-roleindex  = &3.
    gt_db_usercomposite-compindex  = &4.
    insert table gt_db_usercomposite.
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

*    gt_db_vonbisabb-abb   = gt_db_authdetails-abb.
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
*      von          = &8
*      bis          = &9
*      abb          = gt_db_authdetails-abb.
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
DEFINE convert_val_table.
  loop at &1.
    move-corresponding &1 to &2.
    &2-&3 = &1-key.
    &2-&4 = &1-index.
    &2-aid = gs_db_header-aid.
    append &2.
  endloop.
  free &1.
  modify (&5) from table &2.
  free &2.
  message s002(/psyng/sw) with 'STORED:' &5.

  commit work.

END-OF-DEFINITION.
