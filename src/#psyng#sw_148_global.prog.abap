*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_148_GLOBAL                                       *
*----------------------------------------------------------------------*
*--Internal structures representing the eventual database tables we'll
*  store this data in
TYPES :
  BEGIN OF typ_index_conflict,
    key   TYPE /psyng/conflict_id,
    index TYPE i,
  END OF typ_index_conflict,
  BEGIN OF typ_index_function,
    key   TYPE /psyng/function_id,
    index TYPE i,
  END OF typ_index_function,
  BEGIN OF typ_index_auth,
    key   TYPE xuauth,
    index TYPE i,
  END OF typ_index_auth,
  BEGIN OF typ_index_role,
    key   TYPE agr_name,
    index TYPE i,
  END OF typ_index_role,
  BEGIN OF typ_index_child,
    key   TYPE agr_name,
    index TYPE i,
  END OF typ_index_child,
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
    key   TYPE /psyng/dorg_abb,
    index TYPE i,
  END OF typ_index_abb,

  BEGIN OF typ_sys_task,
    sysid        TYPE /psyng/sysid,
    task         TYPE string,
  END OF typ_sys_task,
  BEGIN OF typ_caut_index,
    funindex     TYPE i,
    roleindex TYPE i,
  END OF typ_caut_index.

*--Data tables
DATA :
  gs_db_header        TYPE /psyng/swrrshdr,
  gt_db_roles         TYPE HASHED TABLE OF /psyng/swrrsrol
                      WITH UNIQUE KEY roleindex WITH HEADER LINE,
  gt_db_rolecon       TYPE HASHED TABLE OF /psyng/swrrscon
                      WITH UNIQUE KEY roleindex conindex
                      WITH HEADER LINE,
  gt_db_confun        TYPE HASHED TABLE OF /psyng/swrrscfun
                      WITH UNIQUE KEY conindex funindex WITH HEADER LINE
                      ,
  gt_db_rolechild     TYPE SORTED TABLE OF /psyng/swrrsrchd
                      WITH UNIQUE KEY roleindex authindex childindex
                      WITH HEADER LINE,
  gt_db_authdetails   TYPE SORTED TABLE OF /psyng/swresauth
                      WITH UNIQUE KEY sys funindex profileindex
                      tcodeindex objectindex fieldindex
                      authindex
                      vbaindex
                      WITH HEADER LINE,
  gt_db_vonbisabb     TYPE HASHED TABLE OF /psyng/swresvba
                      WITH UNIQUE KEY
                      von bis abb
                      WITH HEADER LINE,
  gt_db_rfunabb       TYPE HASHED TABLE OF /psyng/swrrsrabb
                      WITH UNIQUE KEY roleindex funindex abbindex
                      WITH HEADER LINE,
  gt_agr_define TYPE TABLE OF /psyng/comp_role_tcode WITH HEADER LINE.
*--Index keys
DATA : g_idx_conflict TYPE i,
       g_idx_role     TYPE i,
       g_idx_function TYPE i,
       g_idx_child    TYPE i,
       g_idx_tcode    TYPE i,
       g_idx_object   TYPE i,
       g_idx_field    TYPE i,
       g_idx_auth     TYPE i,
       g_idx_vba      TYPE i,
       g_idx_abb      TYPE i,
       g_analysis_id  TYPE /psyng/serrsid.
*--Index tables
DATA :
  gt_idx_conflict TYPE HASHED TABLE OF  typ_index_conflict
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_role     TYPE HASHED TABLE OF  typ_index_role
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_function TYPE HASHED TABLE OF  typ_index_function
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_child    TYPE HASHED TABLE OF  typ_index_child
                   WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_tcode    TYPE HASHED TABLE OF  typ_index_tcode
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_object   TYPE HASHED TABLE OF  typ_index_object
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_field    TYPE HASHED TABLE OF  typ_index_field
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_abb      TYPE HASHED TABLE OF typ_index_abb
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_auth    TYPE HASHED TABLE OF  typ_index_auth
                  WITH UNIQUE KEY key WITH HEADER LINE,
  gt_idx_task     TYPE HASHED TABLE OF typ_sys_task
                  WITH UNIQUE KEY task WITH HEADER LINE,
  gt_idx_vonbisabb     TYPE HASHED TABLE OF /psyng/swresvba
                      WITH UNIQUE KEY  vbaindex
                      WITH HEADER LINE,
  gt_idx_caut     TYPE HASHED TABLE OF typ_caut_index
                  WITH UNIQUE KEY funindex roleindex
                  WITH HEADER LINE.

*--Value tables (same as index tables, but inverted key)
DATA :
  gt_val_conflict TYPE HASHED TABLE OF  typ_index_conflict
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_auth     TYPE HASHED TABLE OF  typ_index_auth
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_role     TYPE HASHED TABLE OF  typ_index_role
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_abb      TYPE HASHED TABLE OF  typ_index_abb
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_function TYPE HASHED TABLE OF  typ_index_function
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_child    TYPE HASHED TABLE OF  typ_index_child
                   WITH UNIQUE KEY index WITH HEADER LINE,

  gt_val_tcode    TYPE HASHED TABLE OF  typ_index_tcode
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_object   TYPE HASHED TABLE OF  typ_index_object
                  WITH UNIQUE KEY index WITH HEADER LINE,
  gt_val_field    TYPE HASHED TABLE OF  typ_index_field
                  WITH UNIQUE KEY index WITH HEADER LINE.
*-Performance analysis
DATA :
BEGIN OF gt_runtime OCCURS 0,
  id    TYPE string,
  roles TYPE i,
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
g_storage_kb_est TYPE i.
