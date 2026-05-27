*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_152_TOP
*&---------------------------------------------------------------------*
DEFINE add_column.

  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  gs_fieldcat-no_out = &6.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-style      = &8.
  gs_fieldcat-checkbox   = &9.
  append gs_fieldcat to &4.
  clear gs_fieldcat.
END-OF-DEFINITION.

DEFINE add_sort.
  gs_sort-spos      = &1.
  gs_sort-fieldname = &2.
  gs_sort-up        = &3.
  gs_sort-down      = &4.
  IF NOT g_confv IS INITIAL.
  append gs_sort to gt_sort.
  ELSE.
  append gs_sort to gt_sort_rolv.
  ENDIF.
  clear gs_sort.
END-OF-DEFINITION.

*---data declaration for 100 screen
*---field catalog
DATA: gt_detail            TYPE TABLE OF /psyng/sw_kpi_new_conflicts,
      gt_detail_role_view  TYPE TABLE OF
/psyng/sw_rolview_new_rem_conf,
      gt_newconflict_roles TYPE TABLE OF /psyng/sw_sod_det_ana,
      gt_remconflict_roles TYPE TABLE OF /psyng/sw_sod_det_ana,
      gt_hdr               TYPE TABLE OF /psyng/swrrshdr,
      g_confv              TYPE flag,
      g_latest_aid         TYPE /psyng/serrsid,
      g_pre_aid            TYPE /psyng/serrsid,
*--Begin of Addition AKUMAR 12-11-2025
      gt_con_new_rem_role TYPE TABLE OF /psyng/sw_kpi_con_new_rem_role,
      gt_role_new_rem_con TYPE TABLE OF /psyng/sw_kpi_role_new_rem_con.
*--End of Addition.


DATA: gt_sort           TYPE lvc_t_sort,
      gt_sort_rolv      TYPE lvc_t_sort,
      gt_sort_drolv      TYPE lvc_t_sort, "AKUMAR++ PN15658
      gt_sort_dconfv type lvc_t_sort, "AKUMAR++ PN15658
      gs_sort           TYPE lvc_s_sort,
      gt_fieldcat_comp  TYPE lvc_t_fcat,
      gt_fieldcat_dconfv type lvc_t_fcat, "AKUMAR++ PN15658
      gt_fieldcat_rolv  TYPE lvc_t_fcat,
      gt_fieldcat_drolv  TYPE lvc_t_fcat, "AKUMAR++ PN15658
      gs_fieldcat       TYPE lvc_s_fcat,
      gs_layout_comp    TYPE lvc_s_layo,
      gs_layout_rolv    TYPE lvc_s_layo,
      go_html           TYPE REF TO cl_gui_html_viewer,
      go_html_cont      TYPE REF TO cl_gui_custom_container,
      go_alvgrid_comp   TYPE REF TO cl_gui_alv_grid,
      go_container_comp TYPE REF TO cl_gui_custom_container.
