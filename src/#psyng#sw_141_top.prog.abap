*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_141_TOP                                          *
*----------------------------------------------------------------------*
*TABLES: /psyng/swreshdr.
DEFINE add_column.

  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
*  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  gs_fieldcat-no_out = &6.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-style      = &8.
  gs_fieldcat-checkbox   = &9.
  if gs_fieldcat-fieldname = 'SYSTID'.
    gs_fieldcat-key   = 'X'.
  endif.
  append gs_fieldcat to &4.
  clear gs_fieldcat.
END-OF-DEFINITION.

DEFINE add_sort.
  gs_sort-up   = 'X'.
  gs_sort-spos = &1.
  gs_sort-fieldname = &2.
  append gs_sort to gt_sort.

END-OF-DEFINITION.

*---field catalog
DATA: gt_fieldcat TYPE lvc_t_fcat ,
      gt_sort       TYPE lvc_t_sort,
*      gs_sort TYPE lvc_s_sort,
      gs_fieldcat   TYPE lvc_s_fcat,
      gs_layout TYPE lvc_s_layo,
      gr_alvgrid  TYPE REF TO cl_gui_alv_grid,
      gr_alvgrid_101 TYPE REF TO cl_gui_alv_grid,
      gr_ccontainer  TYPE REF TO cl_gui_custom_container,
      gr_container_101   TYPE REF TO cl_gui_custom_container.
*FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.

DATA: BEGIN OF gt_output OCCURS 0.
        INCLUDE STRUCTURE /psyng/swadmovw.
DATA: sys_type TYPE    /psyng/sw_rfcdes-sys_type,
      sys_description TYPE /psyng/sw_systyp-sys_description,
      sys_category TYPE /psyng/sw_rfcdes-sys_category,
      cat_description TYPE /psyng/sw_syscat-cat_description,
      audit(10)  TYPE c,
      config(15) TYPE c,
      diagnostic(25) TYPE c,
      api_logging(15) TYPE c,
    END OF gt_output.

DATA: BEGIN OF gt_sodovrview OCCURS 0.
        INCLUDE STRUCTURE /psyng/sw_sod_overview_count.
DATA: color_line(4) TYPE c,
      END OF gt_sodovrview.

RANGES: gr_system FOR /psyng/range_sysid-low.

types : tt_system TYPE TABLE OF /psyng/range_sysid.
