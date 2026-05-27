*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_099_TOP                                          *
*----------------------------------------------------------------------*
CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.

TYPE-POOLS: slis.
DATA : gt_conid TYPE TABLE OF /psyng/sw_sel_opts_conid.
DATA: wa_conid TYPE /psyng/sw_sel_opts_conid,
       gt_local_swaudhdr TYPE TABLE OF /psyng/swaudhdr.
DATA : lf_reject TYPE flag.
DATA : lt_user_range TYPE TABLE OF /psyng/sw_sel_opts_xubname
WITH HEADER LINE,
gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE.

DATA: g_persa          TYPE /psyng/persa,            "For select-options
g_repid          TYPE sy-repid,
g_variant        LIKE rsvar-variant,
go_classtype     TYPE REF TO cl_abap_typedescr,
g_rfc_searchhelp TYPE /psyng/rfcdest,
gt_audout        TYPE TABLE OF /psyng/output WITH HEADER LINE,
gt_sodout        TYPE TABLE OF /psyng/sw_sod_output_org
            WITH HEADER LINE,
gf_no_upd_scan   TYPE /psyng/bapiflagx,
gf_exit_proc(1)  TYPE c,
gf_hide_org      TYPE flag,
gv_ca_count TYPE i,
gv_sod_count TYPE i,
gf_st_missing_auth TYPE /psyng/bapiflagx,
g_repeat_hdr_bkgdjob TYPE flag,
gf_pages TYPE i.
DATA : lt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE
,
gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       gf_auth_fail TYPE /psyng/bapiflagx,
       gf_missing_auth TYPE flag,
       i_fieldcat_alv  TYPE slis_t_fieldcat_alv.
DATA: gt_enh_con LIKE STANDARD TABLE OF /psyng/sw_enh_usr_con INITIAL
SIZE 0 WITH HEADER LINE.

FIELD-SYMBOLS : <usr02> TYPE /psyng/sw_uinfo_remote,
                <uinfo> TYPE /psyng/sw_uinfo.

DATA: BEGIN OF gt_output OCCURS 0,
        rfcdest   LIKE rfcdes-rfcdest,
        type(10)  TYPE c,
        class     LIKE /psyng/bc_uidn-class,
        bname     LIKE /psyng/bc_uidn-bname,
        name_text LIKE /psyng/bc_uidn-name_text,
        imp       LIKE /psyng/conflict-imp,
        owner     LIKE /psyng/swaudhdr-owner,
        conid     LIKE /psyng/conflict-conid,
        condesc   LIKE /psyng/conflict-description,
        contid    LIKE /psyng/conflict-contid,
        auditor   LIKE /psyng/mccauser-auditor,
        from_date  LIKE /psyng/mccauser-from_date,
        to_date    LIKE /psyng/mccauser-to_date,
        er        LIKE /psyng/sw_sod_output_org-er,
        enhanced  LIKE /psyng/output-enhanced,
        ustyp     LIKE usr02-ustyp,
        mit_icon  LIKE icon-id,
      END OF gt_output.
DATA: gs_output LIKE gt_output.

DATA : gt_output_cafm TYPE TABLE OF /psyng/sw_ca_output_org WITH HEADER
LINE.

DATA: gt_output_final LIKE TABLE OF gt_output WITH HEADER LINE.

DATA: gt_mcuser TYPE TABLE OF /psyng/mitigation_assignment
                              WITH HEADER LINE,
      gt_mcuser_sod TYPE TABLE OF /psyng/mitigation_assignment
                              WITH HEADER LINE,
      gt_uinfo  TYPE TABLE OF /psyng/sw_uinfo_remote
         WITH HEADER LINE,
      gt_mccauser TYPE TABLE OF /psyng/mitigation_assignment
       WITH HEADER LINE.

DATA: tusercount TYPE i,
l_tabname  TYPE dd02l-tabname,
gf_showpcom(1) TYPE c,
g_current_user TYPE sy-uname. "C0700
