*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_143_TOP                                          *
*----------------------------------------------------------------------*
*--Begin of C0006
CONSTANTS: gc_read_values TYPE char1 VALUE 'X',
           gc_blue_color  TYPE char4 VALUE 'C410'.
*--End of C0006
TYPES: BEGIN OF ty_config_detail,
         type        TYPE char12,
         abb         TYPE /psyng/dorg_abb,
         var_element TYPE char40,
         value       TYPE xuval,
         modified    TYPE /psyng/bapiflagx,
         active      TYPE /psyng/bapiflagx,
         sysid       TYPE /psyng/sysid,
       END OF ty_config_detail.

DATA: BEGIN OF gt_cfgset OCCURS 0,
      sodvrsio      TYPE /psyng/swcfgset-sodvrsio,
      setid         TYPE /psyng/swcfgset-setid,
      published     TYPE /psyng/swcfgset-published,
      change_date   TYPE /psyng/swcfgset-change_date,
      change_time   TYPE /psyng/swcfgset-change_time,
      description   TYPE /psyng/swcfgset-description,
      change_user   TYPE /psyng/swcfgset-change_user,
      system        TYPE /psyng/longtext,
      color_line(4) TYPE c,
END OF gt_cfgset.

DATA: gt_config_detail TYPE TABLE OF ty_config_detail.      "++C0006

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
  clear  gs_sort.
END-OF-DEFINITION.

*---field catalog
DATA: gt_fieldcat      TYPE lvc_t_fcat,
      gt_sort          TYPE lvc_t_sort,
      gs_sort          TYPE lvc_s_sort,
      gs_fieldcat      TYPE lvc_s_fcat,
      gs_layout        TYPE lvc_s_layo,
      gr_alvgrid       TYPE REF TO cl_gui_alv_grid,
      gr_container     TYPE REF TO cl_gui_custom_container,
      go_alvgrid_101   TYPE REF TO cl_gui_alv_grid,         "++C0006
      go_container_101 TYPE REF TO cl_gui_custom_container. "++C0006
