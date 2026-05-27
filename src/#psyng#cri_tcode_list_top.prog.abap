*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/CRI_TCODE_LIST_TOP                                  *
*----------------------------------------------------------------------*
TABLES: usr02, agr_tcodes, tstct, ust10c, ust10s, ust12,
         /psyng/criprof, /psyng/critcodes, rfcdes.


TYPE-POOLS: slis.                              "For ALV call

CONSTANTS: gc_erp_class(16)    TYPE c VALUE '/PSYNG/SW_CL_ERP',
           gc_kostl_method(20) TYPE c VALUE 'GET_COST_CENTER_NAME',
           gc_persa_method(25) TYPE c VALUE 'GET_PERSONNEL_AREA_NAME'.

DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv, "For ALV call
      alv_layout     TYPE slis_layout_alv.     "For ALV call
DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

DATA: program LIKE sy-repid.                   "For ALV call

DATA : iagr_prof TYPE TABLE OF /psyng/userauth,
       wa_iagr_prof TYPE /psyng/userauth,
       iagr_prof_part TYPE TABLE OF /psyng/userauth,
       gt_role_prof TYPE TABLE OF /psyng/sw_critcode_detail WITH HEADER
LINE.

DATA: functioncall_1(4),
      done(4) VALUE 'DONE'.

DATA: gt_function TYPE STANDARD TABLE OF /psyng/function WITH HEADER
LINE.
DATA: iusgrpt TYPE STANDARD TABLE OF usgrpt WITH HEADER LINE.

DATA: kostl_resp TYPE STANDARD TABLE OF /psyng/sw_kostl_resp
      WITH HEADER LINE.

DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y',
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      gf_use_erp             TYPE /psyng/bapiflagx,
      go_classtype           TYPE REF TO cl_abap_typedescr,
      go_erp_class           TYPE REF TO object.

DATA: gt_functtran TYPE STANDARD TABLE OF /psyng/functtran
      WITH HEADER LINE.
DATA: BEGIN OF gt_functtran2 OCCURS 0,
        tcode LIKE gt_functtran-tcode,
        functionid LIKE gt_functtran-functionid,
      END OF gt_functtran2.
DATA: functtran2_idx TYPE i.
DATA: function_idx TYPE i.

DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort TYPE slis_sortinfo_alv.

DATA: itstct TYPE SORTED TABLE OF tstct WITH UNIQUE KEY sprsl tcode
      WITH HEADER LINE.

DATA : iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE,
       iust10s TYPE TABLE OF ust10s-auth WITH HEADER LINE,
       iust10c TYPE TABLE OF ust10c WITH HEADER LINE,
       lt_auths TYPE TABLE OF ust10s-auth WITH HEADER LINE.

DATA : g_local_sys TYPE rfcdes-rfcoptions,
       gt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE,
    gt_uinfo_temp TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE,

       gt_uinfo_part TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER
LINE.

DATA: BEGIN OF outab OCCURS 10.
DATA:   persa      LIKE /psyng/sw_uinfo-persa,
        name1      LIKE /psyng/sw_persa_desc-pbtxt,
        tcode      LIKE tstct-tcode,
        ttext      LIKE tstct-ttext,
        rfcdest    LIKE rfcdes-rfcdest,
        imp        LIKE /psyng/critcodes-imp,
        owner      LIKE /psyng/critcodes-owner,
        busarea(100),
        kostl      LIKE /psyng/sw_uinfo-kostl,
        ltext      LIKE /psyng/sw_kostl_desc-ltext,
        kostlresp  LIKE kostl_resp-kostlresp,
        bname      LIKE usr02-bname,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        name_text  LIKE /psyng/sw_uinfo-name_text,
        status(10) TYPE c,
        agr_name   LIKE agr_tcodes-agr_name,
        profile    LIKE ust04-profile,
        functionid LIKE /psyng/function-function,
        fundes LIKE /psyng/function-description,
         class   LIKE usr02-class.
DATA: END OF outab.
DATA: wa_outab LIKE LINE OF outab.

DATA: BEGIN OF outab4 OCCURS 10 .
DATA:
        persa      LIKE /psyng/sw_uinfo-persa,
        name1      LIKE /psyng/sw_persa_desc-pbtxt,
        tcode      LIKE tstct-tcode,
        ttext      LIKE tstct-ttext,
        rfcdest    LIKE rfcdes-rfcdest,
        imp        LIKE /psyng/critcodes-imp,
        owner      LIKE /psyng/critcodes-owner,
        busarea(100),
        kostl      LIKE /psyng/sw_uinfo-kostl,
        ltext      LIKE /psyng/sw_kostl_desc-ltext,
        kostlresp  LIKE kostl_resp-kostlresp,
        bname      LIKE usr02-bname,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        name_text  LIKE /psyng/sw_uinfo-name_text,
        status(10) TYPE c,
        agr_name   LIKE agr_tcodes-agr_name,
        profile    LIKE ust04-profile,
        functionid LIKE /psyng/function-function,
        fundes LIKE /psyng/function-description,
         class   LIKE usr02-class.
DATA: END OF outab4.
DATA: wa_outab4 LIKE outab4.

DATA: BEGIN OF outab3 OCCURS 10.
DATA:   bname      LIKE usr02-bname,
        name_text  LIKE /psyng/sw_uinfo-name_text,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        status(10) TYPE c,
        tcode      LIKE tstct-tcode,
        ttext      LIKE tstct-ttext,
        rfcdest    LIKE rfcdes-rfcdest,
        imp        LIKE /psyng/critcodes-imp,
        owner      LIKE /psyng/critcodes-owner,
        busarea(100),
        functionid LIKE /psyng/function-function,
        fundes LIKE /psyng/function-description,
        class   LIKE usr02-class.

DATA: END OF outab3.
DATA: wa_outab3 LIKE LINE OF outab3.
TYPES: BEGIN OF outab2_typ,
        persa      LIKE /psyng/sw_uinfo-persa,
        name1      LIKE /psyng/sw_persa_desc-pbtxt,
        tcode      LIKE tstct-tcode,
        ttext      LIKE tstct-ttext,
        rfcdest    LIKE rfcdes-rfcdest,
        imp        LIKE /psyng/critcodes-imp,
        owner      LIKE /psyng/critcodes-owner,
        busarea(100),
        kostl      LIKE /psyng/sw_uinfo-kostl,
        ltext      LIKE /psyng/sw_kostl_desc-ltext,
        kostlresp  LIKE kostl_resp-kostlresp,
        bname      LIKE usr02-bname,
        name_text  LIKE /psyng/sw_uinfo-name_text,
        company      LIKE /psyng/sw_uinfo-company,
        compshort    LIKE /psyng/sw_uinfo-company,
        department   LIKE /psyng/sw_uinfo-department,
        status(10) TYPE c,
        functionid LIKE /psyng/function-function,
        fundes LIKE /psyng/function-description,
        class   LIKE usr02-class,
      END OF outab2_typ.
DATA: wa_outab2 TYPE outab2_typ.

DATA: outab2 TYPE STANDARD TABLE OF outab2_typ
      WITH HEADER LINE,
      gf_company_longtext    TYPE /psyng/bapiflagx.

DATA: BEGIN OF lt_critcodes OCCURS 10.
        INCLUDE STRUCTURE /psyng/critcodes.
DATA: END OF lt_critcodes.

DATA: BEGIN OF profinfo OCCURS 10.
DATA:   profn     LIKE ust10c-profn,
        composite TYPE c.
DATA: END OF profinfo.

DATA: profinfo2 LIKE profinfo OCCURS 10 WITH HEADER LINE.

DATA: BEGIN OF userprof OCCURS 10.
DATA:   bname LIKE ust04-bname,
        profile LIKE ust04-profile.
DATA: END OF userprof.

DATA: BEGIN OF iusr10 OCCURS 10.
        INCLUDE STRUCTURE usr10.
DATA: END OF iusr10.

DATA: BEGIN OF iagr_define OCCURS 10.
        INCLUDE STRUCTURE agr_define.
DATA: END OF iagr_define.

*--global data for tcode origin details
DATA: BEGIN OF ls_tcode_role,
        bname LIKE /psyng/bc_uidn-bname,
        name_text TYPE ad_namtext,
        tcode LIKE agr_tcodes-tcode,
        ttext LIKE tstct-ttext,
        rfcdest LIKE rfcdes-rfcdest,
        imp   LIKE /psyng/critcodes-imp,
        agr_name LIKE agr_users-agr_name,
        profile  TYPE xuprofile,
      END OF ls_tcode_role.

DATA: gt_tcode_role LIKE STANDARD TABLE OF ls_tcode_role INITIAL SIZE 0
      WITH HEADER LINE.
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      y_layout TYPE slis_layout_alv,
      gt_sort TYPE slis_t_sortinfo_alv.
DATA : gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       gt_usrtcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
       gt_usrtcode_part TYPE TABLE OF /psyng/usertcode WITH HEADER LINE.
DATA:
      l_gltgb TYPE sy-datum,
      g_usercount TYPE i.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      g_current_user TYPE sy-uname. "C0700

FIELD-SYMBOLS : <cri> TYPE /psyng/critcodes.
