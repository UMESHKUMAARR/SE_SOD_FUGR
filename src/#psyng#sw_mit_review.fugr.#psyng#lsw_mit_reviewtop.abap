FUNCTION-POOL /PSYNG/SW_MIT_REVIEW.            "MESSAGE-ID ..
INCLUDE : /PSYNG/SW_CONFIG.
DATA : container   TYPE REF TO cl_gui_custom_container,
       text_editor TYPE REF TO cl_gui_textedit,
       gt_texttab  TYPE soli_tab,
       gw_texttab   LIKE LINE of gt_texttab.

DATA: g_FROM_DATE TYPE DATUM,
      g_to_DATE   TYPE DATUM,
      g_user      TYPE /PSYNG/MCRVWSGN-USERID,
      g_user_nm(40) TYPE c,
      g_VRSIO     TYPE /PSYNG/SODVRSIO,
      g_CONID TYPE  /PSYNG/CONFLICT_ID,
      G_AGR_NAME TYPE  /PSYNG/MCRVWSGN-AGR_NAME,
      g_agr_desc(40) TYPE c,
      G_CONTID TYPE  /PSYNG/CONTID,
      G_AUDITOR TYPE /PSYNG/MCRVWSGN-USERID,
      g_auditor_nm(40) TYPE c,
      g_mit_desc(40) TYPE c,
      g_conid_nm(40) TYPE c,
      G_ASSIGN_TYPE TYPE  /PSYNG/SW_MC_ASSIGNMENT_TYPE,
      g_crauth_desc(40) TYPE c,
      G_CEXE TYPE  C,
      G_CCHG TYPE  C,
      G_COAM TYPE  C,
      G_CJUST TYPE  C,
      G_CATT TYPE  C,
      G_CTYPE TYPE /PSYNG/SW_MITIGATION_TYPE,
      GCAID TYPE /psyng/swaudc2-swaudid,
      g_org_abb type /psyng/dorg_abb,
      gf_mit_by_org type flag.
DATA: gt_rfcdes TYPE TABLE OF rfcdes WITH HEADER LINE,
      gw_details type /psyng/sw_mc_review_report,
      gw_summary  TYPE /psyng/mcrvwsgn,
      G_cnt TYPE i,
      gt_lines LIKE TABLE OF tline,
      w_lines type tline.


DATA: GS_SIGNOFF TYPE /PSYNG/MCRVWSGN.

TYPE-POOLS: SLIS.
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV
