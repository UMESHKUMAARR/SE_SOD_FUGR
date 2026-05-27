*----------------------------------------------------------------------*
*   INCLUDE /PSYNG/USER_LOGON_MONITOR_TOP                              *
*----------------------------------------------------------------------*
DATA: lockdate TYPE sy-datum,
      deldate TYPE sy-datum,
      expdate TYPE sy-datum,
      lockcount(7) TYPE n,
      lockcountc(7),
      delcount(7) TYPE n,
      delcountc(7),
      expcount(7) TYPE n,
      expcountc(7).

DATA: BEGIN OF users OCCURS 0.
DATA:   sel(1) type c,
        bname LIKE usr02-bname,   "user ID
        name LIKE adrp-name_text, "user name
        idname(95),
        usertyp  LIKE tutypa-usertyp,  "License type
        utyptext LIKE tutyp-utyptext,  "License type description
        class LIKE usr02-class,   "user group
        action(20),               "action
        trdat LIKE usr02-trdat,   "logon date
        erdat LIKE usr02-erdat,   "creation date
      END OF users.

DATA: return TYPE STANDARD TABLE OF bapiret2 WITH HEADER LINE,
      retun1 type STANDARD TABLE OF bapiret2 with header line.

TYPE-POOLS: slis.                                      "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv.         "For ALV call

  DATA: BEGIN OF lockuser OCCURS 0,
          bname LIKE usr02-bname,
        END OF lockuser.
  DATA: deleteuser LIKE lockuser OCCURS 0 WITH HEADER LINE.
  DATA: expireuser LIKE lockuser OCCURS 0 WITH HEADER LINE.

  types: BEGIN OF typ_usr02 ,
          class TYPE usr02-class,
          bname TYPE usr02-bname,
          gltgv TYPE usr02-gltgv,
          gltgb TYPE usr02-gltgb,
          uflag TYPE usr02-uflag,
          erdat TYPE usr02-erdat,
          trdat TYPE usr02-trdat,
        END OF typ_usr02.
  data : gs_usr02 type  typ_usr02.
  DATA:  yulock   TYPE x VALUE '80',    "Locked by incorrect login
         yusloc   TYPE x VALUE '40',    "Locked by Administrator
         yugloc   TYPE x VALUE '20'.    "Locked by global Administrator

*--C0383
 data: g_system_msg(80) TYPE c,
        g_cua_active  TYPE c,
        g_modelname   TYPE custmodel,
        g_sendsystem  TYPE rfcsendsys,
        g_rcvsystem   TYPE rfcrcvsys,
        g_uflag       TYPE user02-uflag,
        gt_usrfldtsel TYPE TABLE OF usrfldtsel.
*--C0634
 data: g_exit_proc,
  curr_variant             LIKE  rsvar-variant,
  g_curr_variant           LIKE  rsvar-variant,
  g_variant                LIKE vari-variant,
  g_vari_desc              TYPE varid OCCURS 0 WITH HEADER LINE,
  g_vari_contents          LIKE  rsparams OCCURS 0 WITH HEADER LINE,
  g_vari_text              LIKE varit OCCURS 0 WITH HEADER LINE,
  gt_irsparams             TYPE rsparams OCCURS 0 WITH HEADER LINE,
  g_program                LIKE sy-repid,
  g_folder TYPE string,
   g_ucomm LIKE sy-ucomm,
   g_current_user TYPE sy-uname. "C0700


*---log message
 DEFINE msg.
  if sy-batch = 'X'.
    message s002(/psyng/sw) with &1 &2 &3 &4.
    commit work.
  endif.
  END-OF-DEFINITION.
