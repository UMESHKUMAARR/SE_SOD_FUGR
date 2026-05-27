*&---------------------------------------------------------------------*
*&  Include           /PSYNG/SW_152_TOP
*&---------------------------------------------------------------------*
DEFINE add_column.
  clear gs_fieldcat.
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
END-OF-DEFINITION.

DEFINE add_sort.
  gs_sort-spos      = &1.
  gs_sort-fieldname = &2.
  gs_sort-up        = &3.
  gs_sort-down      = &4.
  IF g_view EQ 'C'.
  append gs_sort to gt_sort.
  ELSEIF g_view EQ 'U'.
  append gs_sort to gt_sort_usrv.
  ELSEIF g_view EQ 'UC'.
  append gs_sort to gt_sort_usrconv.
  ENDIF.
  clear gs_sort.
END-OF-DEFINITION.
CONSTANTS: gc_space TYPE char1 VALUE '',
           gc_con_identified TYPE char10 VALUE 'Identified'.
*---data declaration for 100 screen
*---field catalog
DATA: gt_detail            TYPE TABLE OF /psyng/sw_kpi_new_conflicts,
      gt_detail_user_view  TYPE TABLE OF /psyng/sw_usrview_new_rem_conf,
     gt_detail_usrcon_view TYPE TABLE OF /psyng/sw_botview_new_rem_conf,
     gt_detail_usrcon_view_hide TYPE TABLE OF /psyng/sw_botview_new_rem_conf,
      gt_newconflict_users TYPE TABLE OF /psyng/sw_sod_det_ana,
      gt_remconflict_users TYPE TABLE OF /psyng/sw_sod_det_ana,
      gt_hdr               TYPE TABLE OF /psyng/swreshdr,
      g_view               TYPE char2,
      g_hide               TYPE flag,
      g_latest_aid         TYPE /psyng/seresid,
      g_pre_aid            TYPE /psyng/seresid.

DATA: gt_sort           TYPE lvc_t_sort,
      gt_sort_usrv      TYPE lvc_t_sort,
      gt_sort_usrconv   TYPE lvc_t_sort,
      gs_sort           TYPE lvc_s_sort,
      gt_fieldcat_comp  TYPE lvc_t_fcat,
      gt_fieldcat_usrv  TYPE lvc_t_fcat,
      gt_fieldcat_usrconv TYPE lvc_t_fcat,
      gs_fieldcat       TYPE lvc_s_fcat,
      gs_layout         TYPE lvc_s_layo,
      go_html           TYPE REF TO cl_gui_html_viewer,
      go_html_cont      TYPE REF TO cl_gui_custom_container,
      go_alvgrid_comp   TYPE REF TO cl_gui_alv_grid,
      go_container_comp TYPE REF TO cl_gui_custom_container,
      gr_usrtype type range of /PSYNG/SWRESUSR-USTYP,
       gs_usrtype like line of gr_usrtype.
