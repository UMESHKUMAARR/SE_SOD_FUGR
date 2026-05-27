*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_140_GLOBAL                                       *
*----------------------------------------------------------------------*
*--Internal structures representing the eventual database tables we'll
*  store this data in
TYPES :
  BEGIN OF typ_index_conflict,
    key   TYPE /psyng/conflict_id,
    index TYPE i,
  END OF typ_index_conflict,
  BEGIN OF typ_index_sys,
    key   TYPE /psyng/sysid,
    index TYPE i,
  END OF typ_index_sys,

  BEGIN OF typ_index_function,
    key   TYPE /psyng/function_id,
    index TYPE i,
  END OF typ_index_function,
  BEGIN OF typ_index_auth,
    key   TYPE xuauth,
    index TYPE i,
  END OF typ_index_auth,
  BEGIN OF typ_index_user,
    key   TYPE xubname,
    index TYPE i,
  END OF typ_index_user,
  BEGIN OF typ_index_role,
    key   TYPE agr_name,
    sys   TYPE i,
    index TYPE i,
  END OF typ_index_role,
  BEGIN OF typ_index_profile,
    key   TYPE xuprofile,
    sys   TYPE i,
    index TYPE i,
  END OF typ_index_profile,
  BEGIN OF typ_index_tcode,
    key   TYPE tcode,
    index TYPE i,
  END OF typ_index_tcode,
  BEGIN OF typ_index_object,
    key   TYPE xuobject,
    index TYPE i,
  END OF typ_index_object,
  BEGIN OF typ_index_field,
    key   TYPE xufield,
    index TYPE i,
  END OF typ_index_field,
  BEGIN OF typ_index_abb,
    key   TYPE /psyng/dORG_ABB,
    index TYPE i,
  END OF typ_index_abb,

  BEGIN OF typ_db_users,
    aid         TYPE /psyng/seresid,
    userindex   TYPE i,
    bname       TYPE xubname,
    name_text   TYPE ad_namtext,
    class       TYPE xuclass,
    company     TYPE uscomp,
    department  TYPE text40,
    ustyp       TYPE xuustyp,
    central_uid TYPE /psyng/central_uid,
  END OF typ_db_users,
  BEGIN OF typ_db_usercon,
    aid         TYPE /psyng/seresid,
    userindex TYPE i,
    conindex  TYPE i,
  END OF typ_db_usercon,
  BEGIN OF typ_db_confun,
    aid         TYPE /psyng/seresid,
    conindex TYPE i,
    funindex TYPE i,
  END OF typ_db_confun,
  BEGIN OF typ_db_funprofile,
    aid          TYPE /psyng/seresid,
    sys          TYPE i,
    funindex     TYPE i,
    profileindex TYPE i,
  END OF typ_db_funprofile,
  BEGIN OF typ_db_profilerole,
    aid           TYPE /psyng/seresid,
    sys           TYPE i,
    profindex     TYPE i,
    roleindex     TYPE i,
  END OF typ_db_profilerole,
  BEGIN OF typ_db_userprofile,
    aid           TYPE /psyng/seresid,
    sys           TYPE i,
    userindex     TYPE i,
    profileindex  TYPE i,
  END OF typ_db_userprofile,
  BEGIN OF typ_db_usercomposite,
    aid           TYPE /psyng/seresid,
    sys           TYPE i,
    userindex     TYPE i,
    roleindex     TYPE i,
    compindex     TYPE i, "composite role
  END OF typ_db_usercomposite,
  BEGIN OF typ_db_authdetails,
*function system profile tcode auth field from to
    aid         TYPE /psyng/seresid,
    sys          TYPE i,
    funindex     TYPE i,
    profileindex TYPE i,
    tcodeindex   TYPE i,
    objectindex  TYPE i,
    fieldindex   TYPE i,
    auth         TYPE xuauth,
    vbaindex     TYPE i,
*    von          TYPE xuval,
*    bis          TYPE xuval,
*    abb          TYPE /psyng/dorg_abb,
  END OF typ_db_authdetails,
  BEGIN OF typ_db_vonbisabb,
*index of von bis abb combos
*    aid         TYPE /PSYNG/SERESID,
    vbaindex     TYPE i,
    von          TYPE xuval,
    bis          TYPE xuval,
    abb          TYPE /psyng/dorg_abb,
  END OF typ_db_vonbisabb,


  BEGIN OF typ_sys_task,
    sysid        TYPE /psyng/sysid,
    task         TYPE string,
  END OF typ_sys_task,
  BEGIN OF typ_caut_index,
    sys          TYPE /psyng/sysid,
    funindex     TYPE i,
    profileindex TYPE i,
  END OF typ_caut_index.

*--Data tables
DATA :
  gs_db_header        TYPE /psyng/swreshdr,
  gt_db_users         TYPE HASHED TABLE OF /psyng/swresusr
                      WITH UNIQUE KEY userindex WITH HEADER LINE,
  gt_db_usercon       TYPE HASHED TABLE OF /psyng/swrescon
                      WITH UNIQUE KEY userindex conindex
                      WITH HEADER LINE,
  gt_db_concont       TYPE HASHED TABLE OF /psyng/swrescont
                      WITH UNIQUE KEY mandt aid sys conindex abbindex
                      WITH HEADER LINE,
  gt_db_confun        TYPE HASHED TABLE OF /psyng/swrescfun
                      WITH UNIQUE KEY conindex funindex WITH HEADER LINE
,
  gt_db_funprofile    TYPE HASHED TABLE OF /psyng/swresfpr
                      WITH UNIQUE KEY sys funindex  profileindex
"Added by : UMITTAL C1342 D67K931619 14/05/2024
                      userindex
                      WITH HEADER LINE,
  gt_db_profilerole   TYPE SORTED TABLE OF /psyng/swresprol
                      WITH UNIQUE KEY sys profindex roleindex
                      WITH HEADER LINE,
  gt_db_userprofile   TYPE HASHED TABLE OF /psyng/swresupr
                      WITH UNIQUE KEY sys userindex profileindex
                      WITH HEADER LINE,
  gt_db_usercomposite TYPE SORTED TABLE OF /psyng/swresucom
                      WITH UNIQUE KEY sys userindex roleindex
                                      compindex
                      WITH HEADER LINE,
  gt_db_authdetails   TYPE SORTED TABLE OF /psyng/swresauth
                      WITH UNIQUE KEY sys funindex profileindex
                      tcodeindex   objectindex fieldindex
                      authindex
                      vbaindex
*                      von bis abb
                      WITH HEADER LINE,
  gt_db_vonbisabb     TYPE HASHED TABLE OF /psyng/swresvba
                      WITH UNIQUE KEY
                      von bis abb
                      WITH HEADER LINE,
  gt_db_ufunabb       type HASHED table of /PSYNG/SWRESUABB
                      with unique key USERINDEX FUNINDEX ABBINDEX
                      with header line,
  gt_uinfo type standard table of /PSYNG/SW_UINFO with header line.
*--Index keys
DATA : g_idx_conflict TYPE i,
       g_idx_user     TYPE i,
       g_idx_function TYPE i,
       g_idx_role     TYPE i,
       g_idx_profile  TYPE i,
       g_idx_sys      TYPE i,
       g_idx_tcode    TYPE i,
       g_idx_object   TYPE i,
       g_idx_field    TYPE i,
       g_idx_auth     TYPE i,
       g_idx_vba      TYPE i,
       g_idx_abb      TYPE i,
       g_analysis_id  TYPE /psyng/seresid.
*--Index tables
DATA :
  gt_idx_conflict TYPE HASHED TABLE OF  typ_index_conflict
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_sys      TYPE HASHED TABLE OF  typ_index_sys
                  WITH UNIQUE KEY KEY WITH HEADER LINE,

  gt_idx_user     TYPE HASHED TABLE OF  typ_index_user
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_function TYPE HASHED TABLE OF  typ_index_function
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_tcode    TYPE HASHED TABLE OF  typ_index_tcode
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_object   TYPE HASHED TABLE OF  typ_index_object
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_field    TYPE HASHED TABLE OF  typ_index_field
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_abb      TYPE HASHED TABLE OF typ_index_abb
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_auth    TYPE HASHED TABLE OF  typ_index_auth
                  WITH UNIQUE KEY KEY WITH HEADER LINE,
  gt_idx_role     TYPE HASHED TABLE OF typ_index_role
                  WITH UNIQUE KEY KEY sys WITH HEADER LINE,
  gt_idx_profile  TYPE HASHED TABLE OF typ_index_profile
                  WITH UNIQUE KEY KEY sys WITH HEADER LINE,
  gt_idx_task     TYPE HASHED TABLE OF typ_sys_task
                  WITH UNIQUE KEY task WITH HEADER LINE,
  gt_idx_vonbisabb     TYPE HASHED TABLE OF /psyng/swresvba
                      WITH UNIQUE KEY  vbaindex
                      WITH HEADER LINE,
  gt_idx_caut     TYPE HASHED TABLE OF typ_caut_index
                  WITH UNIQUE KEY sys funindex profileindex
                  WITH HEADER LINE.

*--Value tables (same as index tables, but inverted key)
DATA :
  gt_val_conflict TYPE HASHED TABLE OF  typ_index_conflict
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_sys      TYPE HASHED TABLE OF  typ_index_sys
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_auth     TYPE HASHED TABLE OF  typ_index_auth
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_user     TYPE HASHED TABLE OF  typ_index_user
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_abb      TYPE HASHED TABLE OF  typ_index_abb
                  WITH UNIQUE KEY index WITH HEADER LINE,

  gt_val_function TYPE HASHED TABLE OF  typ_index_function
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_tcode    TYPE HASHED TABLE OF  typ_index_tcode
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_object   TYPE HASHED TABLE OF  typ_index_object
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_field    TYPE HASHED TABLE OF  typ_index_field
                  WITH UNIQUE KEY index WITH HEADER LINE,

  gt_val_role     TYPE HASHED TABLE OF typ_index_role
                  WITH UNIQUE KEY index sys WITH HEADER LINE,
  gt_val_profile  TYPE HASHED TABLE OF typ_index_profile
                  WITH UNIQUE KEY index sys WITH HEADER LINE.


*-Performance analysis
data :
BEGIN OF gt_runtime OCCURS 0,
  id    TYPE string,
  users TYPE i,
  startd TYPE dats,
  startt TYPE tims,
  endd   TYPE dats,
  endt   TYPE tims,
  seconds TYPE i,
  minutes TYPE i,
  hours   TYPE i,
END OF gt_runtime,
g_storage_ms_a TYPE p,
g_storage_ms   TYPE p,
g_storage_kb_est TYPE p.
