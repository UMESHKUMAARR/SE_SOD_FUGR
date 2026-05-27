*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/SW_030_TOP                                          *
*----------------------------------------------------------------------*
TYPES: BEGIN OF typ_usr02,
         class TYPE usr02-class,
         bname TYPE usr02-bname,
       END OF typ_usr02.

DATA : gt_critprof TYPE TABLE OF /psyng/criprof WITH HEADER
LINE.
DATA : gt_ust04 TYPE TABLE OF ust04 WITH HEADER LINE.

RANGES : users FOR usr02-bname.

*DATA: iusr02 TYPE SORTED TABLE OF typ_usr02
*             WITH UNIQUE KEY class bname WITH HEADER LINE,
DATA : iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE,
       gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: gi_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call
DATA: gisort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y'.

DATA: BEGIN OF output OCCURS 0,
        profile LIKE ust04-profile,
        prof_txt LIKE usr11-ptext,
        rfcdest LIKE rfcdes-rfcdest,
        imp LIKE /psyng/criprof-imp,
        owner LIKE /psyng/criprof-owner,
        bname LIKE usr02-bname,
        name LIKE /psyng/bc_userid_name-name_full,
        imporder,
      END OF output.
DATA: wa_output LIKE LINE OF output.

*Start of Reference User
DATA: iusrefus1 TYPE STANDARD TABLE OF usrefus WITH HEADER LINE.
*end of Reference user.
DATA: BEGIN OF gt_text OCCURS 0,
        text TYPE /psyng/texts-text,
      END OF gt_text.
*DATA : gs_critprof TYPE /psyng/criprof.

TYPES: BEGIN OF t_critprof,
          profile TYPE usr11-profn,
          ptext TYPE usr11-ptext,
          imp TYPE /psyng/criprof-imp,
          owner TYPE /psyng/criprof-owner,
*          description TYPE /psyng/criprof-description,
*          flag,       "flag for mark column
       END OF t_critprof.


DATA:    gs_critprof TYPE t_critprof. "workarea
DATA : gt_rfcdest TYPE TABLE OF rfcdes WITH HEADER LINE,
       gt_usrroleprof TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
       gt_usrroleprof_part TYPE TABLE OF /psyng/usertcode WITH HEADER
LINE,
       gt_usr11 TYPE STANDARD TABLE OF usr11 WITH HEADER LINE.

DATA: gt_username TYPE STANDARD TABLE OF /psyng/bc_userid_name
        WITH HEADER LINE,

        iust04   TYPE STANDARD TABLE OF ust04 WITH HEADER LINE.
DATA : g_local_sys TYPE rfcdes-rfcoptions,
       gt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE,
       gt_uinfo_temp TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER
LINE.

DATA: l_gltgb TYPE sy-datum,
      g_usercount TYPE i.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      g_current_user TYPE sy-uname. "C0700
