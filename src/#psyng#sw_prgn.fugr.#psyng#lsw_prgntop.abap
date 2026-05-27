FUNCTION-POOL /psyng/sw_prgn.               "MESSAGE-ID ..
CLASS lcl_event_handler_100 DEFINITION DEFERRED.
CLASS lcl_event_handler_200 DEFINITION DEFERRED.
include /PSYNG/SW_CONFIG.
*--Global tables
DATA : gt_role_conflicts TYPE TABLE OF /psyng/sw_out_routput
                         WITH HEADER LINE,
       BEGIN OF gt_user_conflicts OCCURS 0,
         bname   TYPE xubname,
         old     TYPE flag,
         new     TYPE flag,
         imp     TYPE /psyng/importance,
         impsort TYPE num1,
         conid   TYPE /psyng/conflict_id,
         condesc TYPE /psyng/rskdsc,
         contid  TYPE /psyng/contid,
       END OF gt_user_conflicts,
       g_vrsio TYPE /psyng/sodvrsio,
       gt_roles_adding   TYPE TABLE OF /psyng/sw_role_addition_simu
                           WITH HEADER LINE,
       gt_roles_removing TYPE TABLE OF /psyng/sw_role_removal_simu
                           WITH HEADER LINE,
       gt_roles_before TYPE TABLE OF /psyng/sw_role_addition_simu
                           WITH HEADER LINE                    .
*--Screen 100 data
DATA :
  gr_alvgrid_100  TYPE REF TO cl_gui_alv_grid,
  gc_control_100  TYPE scrfname VALUE 'ALV_CONTROL',
  gr_ccont_100    TYPE REF TO cl_gui_custom_container,
  gt_fieldcat_100 TYPE lvc_t_fcat,
  gs_layout_100   TYPE lvc_s_layo,
  gt_sort_100     TYPE lvc_t_sort,
  gf_stop         TYPE flag,
  g_transaction   TYPE string,
  gf_allow_conflicts TYPE string,
  g_ucomm TYPE sy-ucomm.

DATA gr_event_handler TYPE REF TO lcl_event_handler_100.

DATA :
  gr_alvgrid_200  TYPE REF TO cl_gui_alv_grid,
  gc_control_200  TYPE scrfname VALUE 'ALV_CONTROL',
  gr_ccont_200    TYPE REF TO cl_gui_custom_container,
  gt_fieldcat_200 TYPE lvc_t_fcat,
  gs_layout_200   TYPE lvc_s_layo,
  gt_sort_200     TYPE lvc_t_sort.

DATA gr_event_handler_200 TYPE REF TO lcl_event_handler_200.

data g_tasks type i.
DATA : gt_user_con_before TYPE TABLE OF /psyng/sw_sod_output_org
                            WITH HEADER LINE,
       gt_user_con_after TYPE TABLE OF /psyng/sw_sod_output_org
                            WITH HEADER LINE.
