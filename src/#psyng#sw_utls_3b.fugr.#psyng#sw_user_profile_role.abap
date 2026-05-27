FUNCTION /PSYNG/SW_USER_PROFILE_ROLE.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(IF_SHOWCOMP) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_USER_PROF STRUCTURE  /PSYNG/SE_USER_PROF_ROLE
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_USER_PROFILE_ROLE'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

data : lt_agr_1016   type sorted table of AGR_1016
                     with non-unique key profile
                     with header line,
       lt_users      type table of usr02 with header line,
       lt_prof_names type table of xuprofile with header line,
       lr_role_names type table of /PSYNG/RANGE_AGR_NAME
                     with header line,
       lt_comp_child type table of /PSYNG/AGR_COMP_CHILD
                     with header line,
       lt_agr_users  type table of AGR_USERS
                     with header line,
       lt_all_agr_users  type table of AGR_USERS
                     with header line,
       l_idx_comp    like sy-tabix,
       lf_onefound   type flag,
       lt_user_prof  type table of /PSYNG/SE_USER_PROF_ROLE
                     with header line.
field-symbols : <userprof> type /PSYNG/SE_USER_PROF_ROLE.
check not IT_USER_PROF[] is initial.
*--Get unique profile names
loop at it_user_prof.
  lt_prof_names = it_user_prof-PROFILE.
  collect lt_prof_names.
  lt_users-bname = it_user_prof-bname.
  collect lt_users.
endloop.
*--Get the single roles that belong to them
select  agr_name profile from agr_1016
  into corresponding fields of table lt_agr_1016
  for all entries in lt_prof_names where
    profile = lt_prof_names-table_line and
    pstate = 'A'.
if IF_SHOWCOMP = 'X'.
*--Collect unique role names
  lr_role_names-sign = 'I'. lr_role_names-option = 'EQ'.
  loop at lt_agr_1016.
    lr_role_names-low = lt_agr_1016-agr_name.
    collect lr_role_names.
  endloop.
*  --Get the composite roles for these roles
  CALL FUNCTION '/PSYNG/SW_084'
   EXPORTING
     I_INCLUDE_USERS            = 'X'
*     I_REMOVAL_SIMULATION       =
    TABLES
      it_singleroles             = lr_role_names
      et_comp_child              = lt_comp_child
      it_users                   = lt_users
      et_agr_users               = lt_agr_users.
  sort : lt_comp_child by agr_name comp_agr,
         lt_agr_users  by uname agr_name.

*--Get the direct role assignments
if not lt_users[] is initial.
  select * from agr_users
  into table lt_all_agr_users
  for all entries in lt_users
  where
    uname     = lt_users-bname AND
    col_flag  = '' AND
    from_dat <= sy-datum AND
    to_dat   >= sy-datum and
    agr_name in lr_role_names.
    endif.
  sort lt_all_agr_users by uname agr_name.
endif.
*--Add single role to output table
loop at it_user_prof assigning <userprof>.
  clear lf_onefound.
  read table lt_agr_1016 with table key profile = <userprof>-profile
  transporting agr_name.
  if sy-subrc = 0.
    <userprof>-agr_name = lt_agr_1016-agr_name.
    if IF_SHOWCOMP = 'X'.
*--Check if this user has a composite role assigned at all
     read table  lt_agr_users with key uname =    <userprof>-bname
     binary search transporting no fields.
     check sy-subrc = 0.
*  --Check if part of a composite role
      read table lt_comp_child with key agr_name = <userprof>-agr_name
        binary search transporting no fields.
      if sy-subrc = 0.
        l_idx_comp = sy-tabix.
        loop at lt_comp_child from l_idx_comp.
          if not lt_comp_child-agr_name = <userprof>-agr_name.
            exit.
          endif.
*  --Check if composite assigned to user
          read table   lt_agr_users
            with key uname    = <userprof>-bname
                     agr_name = lt_comp_child-comp_agr
                     binary search.
          if sy-subrc = 0.
            if lf_onefound is initial.
                <userprof>-comp_agr = lt_comp_child-comp_agr.
              lf_onefound = 'X'.
            else.
*  --User gets this from multiple composite roles, add this one
                lt_user_prof = <userprof>.
                lt_user_prof-comp_agr = lt_comp_child-comp_agr.
                append lt_user_prof.
            endif.

          endif.
        endloop.
      endif.
*--Check if role also assigned directly
      read table lt_all_agr_users with key
           uname    = <userprof>-bname
           agr_name = lt_agr_1016-agr_name
           binary search.
      if sy-subrc = 0.
         lt_user_prof = <userprof>.
         clear lt_user_prof-comp_agr.
         append lt_user_prof.
      endif.

    endif.
  endif.
endloop.
append lines of lt_user_prof to IT_USER_PROF.

ENDFUNCTION.
