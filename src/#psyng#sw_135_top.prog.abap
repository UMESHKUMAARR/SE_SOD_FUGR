*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_135_TOP                                          *
*----------------------------------------------------------------------*

DATA : gf_ve_loaded  TYPE flag,
       gf_sys_loaded TYPE flag,
       gf_ao_loaded  TYPE flag,
       gf_vs_loaded  type flag,
       gf_set_loaded TYPE flag,
       g_loaded_set  TYPE /psyng/seconfid,
       gf_CFG_SET_ORG_SHOW_TOT type flag,
       gf_CFG_SET_AUTO_PARSE type flag,
       gf_element_loaded type flag,
       gt_selections type table of /PSYNG/SWCFSEL with header line,
       g_vrsio             type /psyng/sodvrsio,
       g_current_user TYPE sy-uname. "RGUPTA for C0700

DEFINE highlight_org_sum.
*  delete gt_organization-cellstyles where fname = &2.
  clear ls_cellstyle.
  read table gt_output with key abb      = &1
                                varbl    = &2
                                manual   = 'X'.
  if sy-subrc = 0.
    ls_cellstyle-fname     = &2.
    ls_cellstyle-color-col = '2'.
    ls_cellstyle-color-int = '1'.
    ls_cellstyle-color-inv = '1'.
    append ls_cellstyle to gt_organization-cellstyles.
  endif.
END-OF-DEFINITION.
DEFINE add_column.

  gs_fieldcat-hotspot   = &1.
  gs_fieldcat-fieldname = &2.
  gs_fieldcat-seltext   = &3.
  gs_fieldcat-coltext   = &3.
  gs_fieldcat-intlen    = &5.
  gs_fieldcat-outputlen = &5.
  gs_fieldcat-fix_column = 'X'.
  gs_fieldcat-lzero = 'X'.
  if gf_dispchg =  gc_change.
    gs_fieldcat-edit = &6.
  endif.
  gs_fieldcat-emphasize = '0004'.
  gs_fieldcat-f4availabl = &7.
  gs_fieldcat-style      = &8.
  gs_fieldcat-checkbox   = &9.
  append gs_fieldcat to &4.
END-OF-DEFINITION.


DEFINE set_alv_group.
  gs_fieldcat-sp_group  = &3.
  gs_fieldcat-do_sum    = 'X'.
  gs_fieldcat-fieldname = &2.
  modify  &1 from gs_fieldcat
  transporting sp_group do_sum
  where fieldname = gs_fieldcat-fieldname.
END-OF-DEFINITION.
DEFINE hide_alv_field.
  gs_fieldcat-no_out  = 'X'.
  gs_fieldcat-fieldname = &2.
  modify  &1 from gs_fieldcat
  transporting no_out
  where fieldname = gs_fieldcat-fieldname.
END-OF-DEFINITION.
*define sum_alv_field.
*  gs_fieldcat-do_sum  = 'X'.
*  gs_fieldcat-subtotal = 'X'.
*  gs_fieldcat-fieldname = &2.
*  modify  &1 from gs_fieldcat
*  transporting do_sum subtotal
*  where fieldname = gs_fieldcat-fieldname.
*end-of-definition.


DEFINE count_all.
  delete gt_output where not varbl = &1.
  sort gt_output by low.
  delete adjacent duplicates from gt_output comparing low.
  &2 = 0.
  loop at gt_output where varbl = &1 and check = 'X'.
    add 1 to &2.
  endloop.
END-OF-DEFINITION.


*--
* &1 - input field to count
* &2 - field where active/total should go
*--

DEFINE count_field.
  clear : l_total, l_active.
  lt_temp_count[] = gt_output[].
  delete lt_temp_count where not varbl = &1.
  sort lt_temp_count by low ascending check descending.
  delete adjacent duplicates from lt_temp_count comparing low.
  loop at lt_temp_count where varbl = &1.
    add 1 to l_total.
    if lt_temp_count-check = 'X'.
      add 1 to l_active.
    endif.
  endloop.
  l_total_c = l_total.
  l_active_c = l_active.
  condense : l_total_c,l_active_c.
  if gf_CFG_SET_ORG_SHOW_TOT = 'X'.
    concatenate l_active_c '/' l_total_c into &2.
  else.
    &2 = l_active_c.
  endif.
END-OF-DEFINITION.


DEFINE count_field_company.
*  clear : l_total, l_active.
*  lt_temp_count[] = gt_output[].
*  delete lt_temp_count where not varbl = &1 or not ABB = &2 .
*  sort lt_temp_count by low ascending check descending.
*  delete adjacent duplicates from lt_temp_count comparing low.
*  loop at lt_temp_count where varbl = &1.
*    add 1 to l_total.
*    if lt_temp_count-check = 'X'.
*      add 1 to l_active.
*    endif.
*  endloop.
**  describe table lt_temp_count lines l_total.
**  delete   lt_temp_count where check = ''.
**  describe table lt_temp_count lines l_active.
*
*  l_total_c = l_total.
*  l_active_c = l_active.
*  condense : l_total_c,l_active_c.
*  concatenate l_active_c '/' l_total_c into &3.

  perform f_count_field_company
    using &1 &2 &4 changing &3.

END-OF-DEFINITION.

DEFINE count_all_occurences.
  delete gt_output where not varbl = &1.
  sort gt_output by low.
  delete adjacent duplicates from gt_output comparing low.
  &2 = 0.
  add 1 to &2.
endloop.
END-OF-DEFINITION.

DEFINE count_original_all.
delete gt_output where not varbl = &1.
sort gt_output by low.
delete adjacent duplicates from gt_output comparing low.
&2 = 0.
loop at gt_output where varbl = &1 and manual = ' '.
  add 1 to &2.
endloop.
END-OF-DEFINITION.

*-- Check original Count
DEFINE count_original_occurences.
&3 = 0.
loop at gt_output where abb = &1 and varbl = &2. "and manual = ' '.
  add 1 to &3.
endloop.
END-OF-DEFINITION.


DEFINE count_company_occurences.
&3 = 0.
loop at gt_output where abb = &1 and varbl = &2 and ( check = 'X' or
                                                      manual = 'X' ) .
  add 1 to &3.
endloop.

*--check if there are any that are not checked
read table gt_output with key
  abb = &1
  varbl = &2
  check = ''.
if sy-subrc = 0.
  &4 = 'X'.
endif.

*-- Check if there is any value manual
read table gt_output with key
abb = &1
varbl = &2
manual = 'X'.
if sy-subrc = 0.
  &5 = 'X'.
endif.
END-OF-DEFINITION.


CONTROLS:  tab_appl TYPE TABSTRIP.
CONSTANTS: BEGIN OF c_tab_appl,
         tab1 LIKE sy-ucomm VALUE 'TAB_FC1',
         tab2 LIKE sy-ucomm VALUE 'TAB_FC2',
         tab3 LIKE sy-ucomm VALUE 'TAB_FC3',
         tab4 LIKE sy-ucomm VALUE 'TAB_FC4',
       END OF c_tab_appl,

       gc_display(1) TYPE c VALUE 'D',
       gc_change(1)  TYPE c VALUE 'C'.

DATA:      BEGIN OF g_tab_appl,
         subscreen   LIKE sy-dynnr,
         prog        LIKE sy-repid VALUE '/PSYNG/SW_135',
         pressed_tab LIKE sy-ucomm VALUE c_tab_appl-tab1,
       END OF g_tab_appl.
DATA: BEGIN OF gt_func OCCURS 0,
    fcode LIKE rsmpe-func,
  END OF gt_func.

*******Genaral Data dec
DATA: gf_dispchg(1) TYPE c.

*--- Field catalog objects
DATA: gt_fieldcat TYPE lvc_t_fcat ,
gt_sort       TYPE lvc_t_sort,
gs_fieldcat   TYPE lvc_s_fcat.

FIELD-SYMBOLS: <fcat> TYPE lvc_s_fcat.
*--- Layout structure
DATA gs_layout TYPE lvc_s_layo .

*-- Global data definitions for ALV
*--- ALV Grid instance reference
DATA : gr_alvgrid_sys  TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_ele1  TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_ele2  TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_org  TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_org1 TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_org2 TYPE REF TO cl_gui_alv_grid,
   gr_alvgrid_var  TYPE REF TO cl_gui_alv_grid.

***--- Custom container instance reference
DATA: gr_ccontainer_sys  TYPE REF TO cl_gui_custom_container,
  gr_ccontainer_ele1  TYPE REF TO cl_gui_custom_container,
   gr_ccontainer_ele2  TYPE REF TO cl_gui_custom_container,
  gr_ccontainer_org  TYPE REF TO cl_gui_custom_container,
  gr_ccontainer_org1  TYPE REF TO cl_gui_custom_container,
  gr_ccontainer_org2  TYPE REF TO cl_gui_custom_container,
  gr_ccontainer_var  TYPE REF TO cl_gui_custom_container.

******tables declarations
DATA: BEGIN OF gt_systems OCCURS 0,
    sel      TYPE flag,
    sysid      TYPE /psyng/swcfgsys-sysid,
    rfcdest      TYPE /psyng/sw_rfcdes-rfcdest,
  END OF gt_systems,

  gs_swcfgset  TYPE /psyng/swcfgset,
  g_setid      TYPE /psyng/swcfgset-setid,
  g_published TYPE /psyng/swcfgset-published,
  g_sys_create_flag TYPE flag.

DATA: BEGIN OF gt_element1 OCCURS 0,
  selected TYPE flag,
  default TYPE flag,
  varbl TYPE /psyng/sw_ao_list-varbl,
  description TYPE /psyng/sw_ao_list-description,
  END OF gt_element1.
DATA ls_listrow LIKE LINE OF gt_element1 .
DATA ls_stylerow TYPE lvc_s_styl .
DATA lt_styletab TYPE lvc_t_styl .

DATA: BEGIN OF gt_element2 OCCURS 0,
  selected TYPE flag,
  default TYPE flag,
  var_element TYPE /psyng/sw_ve_list-var_element,
  description TYPE /psyng/sw_ve_list-description,
  END OF gt_element2.

DATA: BEGIN OF gt_organization OCCURS 0,
  abb   TYPE /psyng/swcfgoe-abb,
  label          TYPE xutext,
  bukrs(10)       TYPE c, " company code
  vkorg(10)       TYPE c, " sales org
  ekorg(10)       TYPE c, " purchase org
  werks(10)       TYPE c, " plant
  gsber(10)       TYPE c, " business area
  spart(10)       TYPE c,
  iwerk(10)       TYPE c,
  vtweg(10)       TYPE c,
  kkber(10)       TYPE c,
  kokrs(10)       TYPE c,
  vstel(10)       TYPE c,
  toggle          TYPE flag,
  field           TYPE /psyng/sw_ao_list-field,
  selected        TYPE flag,
  cellstyles      TYPE lvc_t_scol ,
  END OF gt_organization,
  gt_organization1 LIKE TABLE OF gt_organization WITH HEADER LINE.
DATA: BEGIN OF gt_organization2 OCCURS 0,
  country(10) TYPE c,
  varbl(10)   TYPE c,
  field(50)   TYPE c,
  sysid       TYPE /psyng/sysid,
  value(4)    TYPE c,
  label(50)   TYPE c,
  bukrs(4)    TYPE c,
  desc(50)    TYPE c,
  check       TYPE flag,
  END OF gt_organization2,

  g_disp_inact TYPE flag,
  g_varbl_inact TYPE flag,
  g_disp_inact_all_dtl TYPE flag.

***to do need to replace with gt_organization

DATA : BEGIN OF gt_output OCCURS 0.
INCLUDE        STRUCTURE /psyng/swsodorgm.
DATA :
      sysid          TYPE /psyng/sysid,
      label          TYPE xutext,
      icon           TYPE icon_d,
      check          TYPE flag,
      manual         TYPE flag,
      toggled        TYPE flag,
END OF gt_output.

DATA : gt_output_temp LIKE TABLE OF gt_output WITH HEADER LINE,
   gt_output_dtl LIKE TABLE OF gt_output WITH HEADER LINE,
   gt_output_inactive LIKE TABLE OF gt_output WITH HEADER LINE,
   gt_org_values TYPE TABLE OF /psyng/swcfgoe WITH HEADER LINE,
   gt_output_check like table of gt_output with header line.

*data : gt_variable1 type table of /PSYNG/SWCFGVE with header line.
DATA : BEGIN OF gt_variable1 OCCURS 0.
      INCLUDE STRUCTURE /psyng/swcfgve .
DATA : cnt TYPE i,
       VTEXT type XUTEXT,
END OF gt_variable1.
DATA: BEGIN OF gt_variable2 OCCURS 0,
  abb            TYPE /psyng/swcfgoe-abb,
  fieldname      TYPE dd03l-fieldname,
  ddtext         TYPE dd04t-ddtext,
  value          TYPE /psyng/swcfgve-value,
  v_description(60) TYPE c,
  bukrs(4)       TYPE c, " company code
  b_description(60) TYPE c,
   toggle         TYPE flag,
  END OF gt_variable2.

*ranges r_varel FOR /PSYNG/RANGE_SE_VAREL.
DATA: gt_sel_systems TYPE TABLE OF /psyng/swcfgsys WITH HEADER LINE,
  gt_sel_ao_list TYPE TABLE OF /psyng/sw_ao_list WITH HEADER LINE,
  r_varel TYPE TABLE OF /psyng/range_se_varel WITH HEADER LINE,
  g_hotspot_click  TYPE flag,
  g_sod_parse TYPE flag,
  gf_sel_system TYPE flag,
  g_sod_flag TYPE flag,
  g_varel_vrsio_flag TYPE flag,
  gf_data_change TYPE flag,
  gv_prev_setid TYPE /psyng/swcfgset-setid,
  gv_inactive_data_change TYPE flag,
  gv_org_analysis TYPE flag,
  gv_variable_analysis TYPE flag,
  gv_conbine_analysis TYPE flag,
  gf_setid_change,
  gf_screen_change,
  gv_save,
  g_invalid type flag.
