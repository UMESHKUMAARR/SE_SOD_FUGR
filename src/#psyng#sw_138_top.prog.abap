*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_138_TOP                                          *
*----------------------------------------------------------------------*
DATA : gf_grid_initialized TYPE flag,
       g_vrsio             TYPE /psyng/sodvrsio,
       gf_show_unavailable TYPE FLAG.
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
  gs_sort-up   = 'X'.
  gs_sort-spos = &1.
  gs_sort-fieldname = &2.
  append gs_sort to gt_sort.

END-OF-DEFINITION.
*---data declaration for 100 screen

DATA: g_fltr_ana_strt_in(12) TYPE c,
      g_fltr_system(12)      TYPE  c,
      g_fltr_all_vrsio       TYPE flag,
      g_fltr_all_set         TYPE flag,
      g_loaded_first         TYPE flag,
      g_clk_refresh          TYPE flag,
      g_warning_msg(1)       TYPE c,
      g_preconfig            TYPE /psyng/swcfgset-setid.


*---field catalog
DATA: gt_fieldcat   TYPE lvc_t_fcat,
      gt_sort       TYPE lvc_t_sort,
      gs_sort       TYPE lvc_s_sort,
      gs_fieldcat   TYPE lvc_s_fcat,
      gs_layout     TYPE lvc_s_layo,
      gr_alvgrid    TYPE REF TO cl_gui_alv_grid,
      gr_ccontainer TYPE REF TO cl_gui_custom_container.

DATA: gt_detail            TYPE TABLE OF /psyng/sw_kpi_new_conflicts,
      gt_newconflict_users TYPE TABLE OF /psyng/sw_sod_det_ana,
      gt_remconflict_users TYPE TABLE OF /psyng/sw_sod_det_ana,
      g_latest_aid         TYPE /psyng/seresid,
      g_pre_aid            TYPE /psyng/seresid.

DATA: gt_fieldcat_comp  TYPE lvc_t_fcat,
      gs_layout_comp    TYPE lvc_s_layo,
      go_alvgrid_comp   TYPE REF TO cl_gui_alv_grid,
      go_container_comp TYPE REF TO cl_gui_custom_container.

DATA: BEGIN OF gt_resultset OCCURS 0.
        INCLUDE STRUCTURE /psyng/swreshdr.
DATA:  sysid              TYPE /psyng/longtextfield,
       name_text(40)      TYPE c,
       unconflicted_users TYPE /psyng/nr_conusers,
       summary_data       TYPE FLAG,
       detail_data        TYPE FLAG,
       END OF gt_resultset.
*     gt_resultset TYPE TABLE OF /psyng/swreshdr WITH HEADER LINE.
FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.

RANGES gr_aid FOR /psyng/swreshdr-aid.
