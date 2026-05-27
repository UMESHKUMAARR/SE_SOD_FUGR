*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_CRIT_AUTHS_TOP                                   *
*----------------------------------------------------------------------*
DATA: simuagrs LIKE STANDARD TABLE OF /psyng/sw_sod_remote_roles INITIAL
 SIZE 0 WITH HEADER LINE.

DATA : it_simu_role_addition TYPE TABLE OF /psyng/sw_role_addition_simu
WITH HEADER LINE.

DATA :  gr_alvgrid TYPE REF TO cl_gui_alv_grid,
        gc_custom_control_name TYPE scrfname VALUE 'CC_ALV',
        gr_ccontainer TYPE REF TO cl_gui_custom_container,
        gt_fieldcat TYPE lvc_t_fcat,
        gs_layout TYPE lvc_s_layo.

DATA : lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  l_tabname  TYPE dd02l-tabname,
*  lt_faobj TYPE TABLE OF /psyng/faobj2,
*  lt_functtran TYPE TABLE OF /psyng/functtran,
  lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  g_ucomm LIKE sy-ucomm.


DATA : g_nr_users_analyzed TYPE i,
       gf_totals_counted TYPE flag,
       gf_pages TYPE i.

TABLES: /psyng/swaudc2,
        ust04,rfcdes,/psyng/sw_uinfo, /psyng/swaudhdr.
TYPE-POOLS: slis, icon.                                "For ALV call
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: i_fieldcat_alv_det  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: isortdet TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: BEGIN OF output OCCURS 0 .
DATA:   sel(1) TYPE c,   "selected row by user in ALV grid
        swaudid TYPE /psyng/swaudhdr-swaudid,
        description LIKE /psyng/swaudhdr-description,
        imp TYPE /psyng/swaudhdr-imp,
        barea(100),
        owner TYPE /psyng/swaudhdr-owner,
        persa TYPE /psyng/persa,
        pernr	TYPE /psyng/pernr,
        kostl	TYPE kostl,
        class	TYPE usr02-class,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        central_uid   LIKE /psyng/sw_uinfo-central_uid,
        bname	TYPE usr02-bname,
        name_text LIKE adrp-name_text,
        ustyp   LIKE usr02-ustyp,
        rfcdest    TYPE rfcdest,
        contid     TYPE /psyng/contid,
        auditor    LIKE /psyng/mccauser-auditor,
        from_date  LIKE /psyng/mccauser-from_date,
        to_date    LIKE /psyng/mccauser-to_date,
        simu       TYPE  flag,
        simu_before       TYPE  flag,
        simu_after       TYPE  flag,
        er         TYPE  flag,
        mit_icon   LIKE icon-id,
        enhanced   TYPE flag,
        color_cell TYPE lvc_t_scol,
        appl TYPE /psyng/ex_syshdr_st-appl.
DATA: END OF output.
DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE,
      gf_missing_auth_ugroup TYPE flag,
      gt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
      lt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output,
      gf_st_missing_auth TYPE /psyng/bapiflagx,
      g_repeat_hdr_bkgdjob TYPE flag,
      gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      gf_auth_fail TYPE /psyng/bapiflagx,
     gs_variant TYPE disvariant.

DATA: BEGIN OF outputdet OCCURS 0 .
DATA:   swaudid TYPE /psyng/swaudhdr-swaudid,
        description LIKE /psyng/swaudhdr-description,
        imp TYPE /psyng/swaudhdr-imp,
        barea(100),
        owner TYPE /psyng/swaudhdr-owner,
        bname	TYPE usr02-bname,
        tcode TYPE xuval,"TYPE tcode,
        objct TYPE xuobject,
        auth TYPE xuauth,
        field TYPE xufield,
        von TYPE xuval,
        bis TYPE xuval,
        child_agr TYPE agr_name,
        comp_agr  LIKE agr_users-agr_name,
        rfcdest TYPE rfcdest,
        simu TYPE flag,
        er   TYPE flag,
        enhanced TYPE flag,
        color_cell    TYPE lvc_t_scol,
        ustyp TYPE usr02-ustyp,
        profile LIKE ust04-profile,
        comp_prof LIKE ust04-profile,
        appl TYPE /psyng/ex_syshdr_st-appl.
DATA: END OF outputdet,
        gf_central_uid TYPE flag,
        gf_company_longtext    TYPE /psyng/bapiflagx,
        gt_output_det TYPE TABLE OF /psyng/sw_caoutputdet3 WITH HEADER
LINE.
DATA:
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      alv_grid_titl   TYPE lvc_title.                  "For ALV call
DATA : swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
*       gt_mccauser    TYPE TABLE OF /psyng/mccauser WITH HEADER LINE,
       gt_mccauser TYPE TABLE OF /psyng/mitigation_assignment
       WITH HEADER LINE,
       gt_rfcdes TYPE TABLE OF rfcdes WITH HEADER LINE,
       g_button_set TYPE flag.

*--for remote analysis
DATA : lt_remote_anal_rfc TYPE TABLE OF rfcdes WITH HEADER LINE,
       l_rfcdes TYPE rfcdes,
       lt_local_swaudhdr TYPE TABLE OF /psyng/swaudhdr,
       lt_local_swaudc   TYPE TABLE OF /psyng/swaudc2,
       l_local_ca TYPE flag,
       lt_uinfo        TYPE TABLE OF /psyng/sw_uinfo_remote
       WITH HEADER LINE,
       lt_uinfo_all        TYPE TABLE OF /psyng/sw_uinfo_remote
       WITH HEADER LINE,
       lt_user_mapping TYPE  TABLE OF /psyng/sw_user_mapping,
       lt_uinfo_sorted        TYPE
       SORTED TABLE OF /psyng/sw_uinfo_remote
        WITH UNIQUE KEY rfcdest bname
        WITH HEADER LINE,
       lt_user_mapping_sorted TYPE  TABLE OF /psyng/sw_user_mapping
*       WITH NON-UNIQUE KEY target_bname target_rfc
*DHORIONS Case 2810
*         WITH  NON-UNIQUE KEY source_bname target_rfc
       WITH  KEY source_bname target_rfc target_bname
       WITH HEADER LINE,
       l_nr_users_analyzed  TYPE i,
       l_local_rfc TYPE rfcdest.
*        lt_uinfo_sorted_t LIKE TABLE OF lt_uinfo_sorted WITH HEADER
*LINE

TYPES : BEGIN OF typ_usr02_remote  ,
         rfcdest TYPE rfcdest.
        INCLUDE STRUCTURE  usr02.
TYPES : END OF typ_usr02_remote,
       BEGIN OF idusers_typ,
         bname LIKE usr02-bname,
       END OF idusers_typ.
FIELD-SYMBOLS : <map>        TYPE /psyng/sw_user_mapping.

***********************************
*Background job variables
DATA: curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: exit_proc,
      gt_simu_roles TYPE TABLE OF /psyng/sw_sod_remote_roles WITH HEADER
      LINE,
      gt_uinfo_remote TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER
      LINE.

DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
**************************************
DATA : g_numres TYPE i,
       g_nummit TYPE  i,
       l_expires TYPE i,
       g_mit_message.

*Tables that contain all the output of the analysis fm's
DATA :  gt_fm_output TYPE TABLE OF /psyng/output,
        gt_fm_outputdet TYPE TABLE OF /psyng/sw_ca_outputdet.
*Parallel processing Status
DATA : BEGIN OF gt_process_status OCCURS 0,
        rfcdest TYPE rfcdest,
        numproc TYPE i,
       END OF gt_process_status,
       BEGIN OF gt_process_name OCCURS 0,
         procname(72) TYPE c,
         rfcdest TYPE rfcdest,
       END OF gt_process_name.
FIELD-SYMBOLS : <status> LIKE gt_process_status.
DATA : l_system_msg(80) TYPE c,
       lt_bnames TYPE TABLE OF /psyng/range_bname WITH HEADER LINE.
DATA : lt_conflict  TYPE TABLE OF /psyng/conflict,
       lt_confdet   TYPE TABLE OF /psyng/confdet,
       lt_functtran TYPE TABLE OF /psyng/functtran,
       lt_faobj     TYPE TABLE OF /psyng/faobj2.
DATA : gt_funcscan_std      TYPE TABLE OF /psyng/sw_output_org,
       gt_enh_fun           TYPE TABLE OF /psyng/sw_enh_usr_fun WITH
HEADER LINE,
       lt_enh_fun_part      TYPE TABLE OF /psyng/sw_enh_usr_fun,
       lt_funcscan_std_part TYPE TABLE OF /psyng/sw_output_org,
       lt_allusers          TYPE TABLE OF /psyng/sw_uinfo_remote,
       lt_unique_users      TYPE TABLE OF /psyng/sw_uinfo_remote,
       gt_con_outdet        TYPE TABLE OF /psyng/sw_outputdet3.
DATA : lt_outdet TYPE TABLE OF /psyng/sw_outputdet3,
       lt_simrols TYPE TABLE OF /psyng/sw_sel_opts_agr_name
       WITH HEADER LINE,
             gt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu WITH HEADER LINE,
               gt_role_removal_simu
         TYPE TABLE OF /psyng/sw_role_removal_simu WITH HEADER LINE.


DATA: tusercount TYPE i.
DATA : gt_output TYPE TABLE OF /psyng/sw_ca_output_org,
gf_missing_auth TYPE flag,
gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
gf_use_sec_obj         TYPE c,
 gf_showpcom(1) TYPE c,
 g_current_user TYPE sy-uname. "C0700
