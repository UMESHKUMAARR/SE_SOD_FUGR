*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SOD_SYSWIDE_BYROLE_TOP                              *
*----------------------------------------------------------------------*
TYPE-POOLS: slis.                                      "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA: isort           TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort          TYPE slis_sortinfo_alv.
DATA: ls_variant      TYPE disvariant.
DATA: variant         LIKE vari-variant.
DATA: irsparams       TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: ivarit          TYPE varit OCCURS 0 WITH HEADER LINE.
DATA: wa_iagr_define  TYPE agr_define.
DATA: conflictcount   TYPE i,
      averagecon      TYPE i,
      c_averagecon(4) TYPE c,
      trolecount      TYPE int4,
      c_trolecount(6) TYPE c,
      c_rolecount(6)  TYPE c.
DATA: dsp_mng_lock    VALUE 'N',
      dsp_slf_lock    VALUE 'Y',
      gf_hide_org     TYPE /psyng/bapiflagx.

DATA: gt_rfcdes       TYPE TABLE OF rfcdes WITH HEADER LINE,
      gt_rfcdest      TYPE TABLE OF rfcdes WITH HEADER LINE.

DATA : lt_uniqueauths TYPE TABLE OF /psyng/uniqueauths
         WITH HEADER LINE,
         lt_itcd      TYPE SORTED TABLE OF typ_itcd WITH UNIQUE KEY
           tcode rfcdest
           WITH HEADER LINE,
         lt_itcd2       TYPE STANDARD TABLE OF typ_itcd,
         lt_simu_tcdaut TYPE TABLE OF /psyng/psswtcdaut.

DATA : gt_routput_sum     TYPE TABLE OF /psyng/sw_out_routput,
gt_routput_sum_before     TYPE TABLE OF /psyng/sw_out_routput WITH
HEADER LINE,
gt_routput_sum_after     TYPE TABLE OF /psyng/sw_out_routput WITH HEADER
 LINE,
ls_output TYPE  /psyng/sw_out_routput,
exit_proc.
DATA: curr_report  LIKE  rsvar-report,
      curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE.
DATA: cc  TYPE lvc_t_scol WITH HEADER LINE,
      color TYPE lvc_s_colo.
DATA :  alv_layout    TYPE slis_layout_alv,            "For ALV call
      alv_grid_titl   TYPE lvc_title.                  "For ALV call

DATA: program         LIKE sy-repid.                   "For ALV call

DATA: BEGIN OF routdet3 OCCURS 0,
         rfcdest       TYPE rfcdest,
         agr_name      LIKE agr_define-agr_name,
         AGR_TEXT     like agr_texts-text,
         isort        TYPE i,
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,
         description  LIKE /psyng/conflict-description,
         risk         LIKE /psyng/conflict-risk,
         contid       LIKE /psyng/1stoutput_u-contid,
         auditor      LIKE /psyng/mcrole-auditor,
         from_date    LIKE /psyng/mcrole-from_date,
         to_date      LIKE /psyng/mcrole-to_date,
         simu         TYPE c,
         simu_before  TYPE c,
         simu_after   TYPE c,
         mit_icon     LIKE icon-id,
         enhanced     TYPE c, "flag for enhanced ruleset
         color_line(4) TYPE c,           " Line color
         color_cell    TYPE lvc_t_scol,  " Cell color
         child_agr    LIKE  agr_define-agr_name,
         Appl like /psyng/sw_out_routput-appl,
       END OF routdet3,
       gt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
       g_running_tasks TYPE i,
       g_ucomm LIKE sy-ucomm,
      gt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
      WITH HEADER LINE,
      gt_mitigations TYPE TABLE OF /psyng/mitigation_assignment
      WITH HEADER LINE,
      gf_st_missing_auth TYPE /psyng/bapiflagx,
      g_repeat_hdr_bkgdjob TYPE flag,
       gf_org_field type flag. "AKUMAR OPL645

*--Global Data for Removed Roles Popup
DATA :  gr_alvgrid TYPE REF TO cl_gui_alv_grid,
        gc_custom_control_name TYPE scrfname VALUE 'CC_ALV',
        gr_ccontainer TYPE REF TO cl_gui_custom_container,
        gt_fieldcat TYPE lvc_t_fcat,
        gs_layout TYPE lvc_s_layo.

DATA: BEGIN OF it_conid OCCURS 0,
        conid TYPE /psyng/conflict-conid,
        owner TYPE /psyng/conflict-owner,
      END OF it_conid.

DATA: gt_conid TYPE TABLE OF /psyng/sw_sel_opts_conid with header line.
DATA: wa_conid TYPE /psyng/sw_sel_opts_conid.

DATA :lt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       gf_auth_fail TYPE /psyng/bapiflagx,
      gt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu WITH HEADER LINE,
               gt_role_removal_simu
         TYPE TABLE OF /psyng/sw_role_removal_simu WITH HEADER LINE.

data: g_preconfig type /psyng/swcfgset-setid,
      g_warning_msg(1) type c.
