*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_CRIT_AUTH_BYROLE_TOP                             *
*----------------------------------------------------------------------*
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: i_fieldcat_alv_det  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: isortdet TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: BEGIN OF output OCCURS 0 .
DATA:   rfcdest LIKE rfcdes-rfcdest,
        swaudid TYPE /psyng/swaudhdr-swaudid,
        description LIKE /psyng/swaudhdr-description,
        agr_name  TYPE agr_name,
        agr_text     TYPE agr_title,
        imp          TYPE /psyng/swaudhdr-imp,
        barea(100),
        enhanced     TYPE flag,
        contid       LIKE /psyng/mccarole-contid,
        auditor      LIKE /psyng/mccarole-auditor,
        from_date    LIKE /psyng/mccarole-from_date,
        to_date      LIKE /psyng/mccarole-to_date,
        simu         TYPE c,
        simu_before  TYPE c,
        simu_after   TYPE c.

DATA: END OF output.
DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE,
      gt_remote_anal_rfc TYPE TABLE OF rfcdes with header line,
      gt_mitigations     TYPE TABLE OF /psyng/mitigation_assignment
                         WITH HEADER LINE.

DATA: cc  TYPE lvc_t_scol WITH HEADER LINE,
      color TYPE lvc_s_colo.

*--Global Data for Removed Roles Popup
DATA :  gr_alvgrid TYPE REF TO cl_gui_alv_grid,
        gc_custom_control_name TYPE scrfname VALUE 'CC_ALV',
        gr_ccontainer TYPE REF TO cl_gui_custom_container,
        gt_fieldcat TYPE lvc_t_fcat,
        gs_layout TYPE lvc_s_layo,
        gt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
      WITH HEADER LINE.


DATA: BEGIN OF outputdet OCCURS 0 .
DATA:   rfcdest LIKE rfcdes-rfcdest,
        swaudid TYPE /psyng/swaudhdr-swaudid,
        description LIKE /psyng/swaudhdr-description,
        agr_name TYPE agr_name,
        agr_text    LIKE agr_texts-text,
        tcode TYPE tcode,
        objct TYPE xuobject,
        auth TYPE xuauth,
        field TYPE xufield,
        von TYPE xuval,
        bis TYPE xuval,
        child_agr TYPE agr_name,
        simu TYPE flag,
        enhanced     TYPE c, "flag for enhanced ruleset
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF outputdet.
DATA : l_date(12) TYPE c.
DATA : swaudhdr TYPE TABLE OF /psyng/swaudhdr WITH HEADER LINE,
       gt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output.

TYPES: BEGIN OF typ_itcd,
         tcode LIKE /psyng/psswtcd-tcode,
         rfcdest LIKE rfcdes-rfcdest,
       END OF typ_itcd.

DATA : showcomp TYPE flag.

DATA : lt_remote_roles TYPE TABLE OF agr_define WITH HEADER LINE,
         lt_remote_childroles TYPE TABLE OF agr_agrs WITH HEADER LINE,
         lt_simu_roleauth TYPE TABLE OF /psyng/roleauth
         WITH HEADER LINE,
         lt_simu_roletcode TYPE TABLE OF /psyng/roletcode
         WITH HEADER LINE,
         lt_roleauth TYPE TABLE OF /psyng/userauth
         WITH HEADER LINE,
         lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
         lt_uniqueauths TYPE TABLE OF /psyng/uniqueauths
         WITH HEADER LINE,
         lt_itcd TYPE SORTED TABLE OF typ_itcd WITH UNIQUE KEY
           tcode rfcdest
           WITH HEADER LINE,
         lt_itcd2 TYPE STANDARD TABLE OF typ_itcd,
         lt_simu_tcdaut TYPE TABLE OF /psyng/psswtcdaut,
         l_system_msg(100) TYPE c,
         lt_routput_sum TYPE TABLE OF /psyng/sw_out_routput
         WITH HEADER LINE.
DATA : l_nr_roles_analyzed TYPE i,
       l_rfcdes LIKE rfcdes.
DATA : l_taskname TYPE string,
        g_running_tasks TYPE i.

DATA : gt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: exit_proc.
DATA: curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.

DATA : g_nr_auths TYPE i,
      gf_st_missing_auth TYPE /psyng/bapiflagx,
      g_repeat_hdr_bkgdjob TYPE flag.

DATA : gt_fm_output_before TYPE TABLE OF /psyng/sw_ca_routput
        WITH HEADER LINE,
     gt_fm_output_after TYPE TABLE OF /psyng/sw_ca_routput
        WITH HEADER LINE,
        ls_output TYPE /psyng/sw_ca_routput,
        gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
        gt_role_addition_simu
         TYPE TABLE OF /psyng/sw_role_addition_simu WITH HEADER LINE,
               gt_role_removal_simu
         TYPE TABLE OF /psyng/sw_role_removal_simu WITH HEADER LINE,
         g_current_user TYPE sy-uname. "C0700
