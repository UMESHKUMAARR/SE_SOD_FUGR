FUNCTION-POOL /PSYNG/SW_SOD_OBJS3 MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
TYPE-POOLS: slis.                                      "For ALV call
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      alv_grid_titl   TYPE lvc_title,                  "For ALV call
      alv_grid_titl2  TYPE lvc_title.                  "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort TYPE slis_sortinfo_alv.

DATA: usercount TYPE i,    "Progress indicator flag
      counter   TYPE i,    "Progress indicator flag
      percent   TYPE f,    "Progress indicator flag
      udone(8),            "only 1st 2 chars of percent
      ucounttxt(8),        "total user count text
      pertext(200),        "Progress indicator text
      rfcdest LIKE rfcdes-rfcdest,
      exit_proc.

DATA: percentxt(3),
      prtext(3),
      percenti TYPE i.

*Background job variables
DATA: curr_report LIKE  rsvar-report,
      curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: ivarit TYPE varit OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.

DATA: BEGIN OF functtran2 OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran2.
DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.
DATA: confdet_tmp TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
                  conid functionid
                  WITH HEADER LINE.
DATA: wa_confdet TYPE /psyng/confdet.
DATA: BEGIN OF faobj OCCURS 100.
        INCLUDE STRUCTURE /psyng/faobj2.
DATA: END OF faobj.

DATA: BEGIN OF auths_fm OCCURS 10.
        INCLUDE STRUCTURE usref.
DATA: END OF auths_fm.

DATA: BEGIN OF values_fm OCCURS 10.
        INCLUDE STRUCTURE usref.
DATA: END OF values_fm.

DATA: BEGIN OF profinfo OCCURS 10.                "Single profile list
DATA:   profn     LIKE ust10c-profn,
        composite TYPE c.
DATA: END OF profinfo.

DATA: profinfo2 LIKE profinfo OCCURS 10 WITH HEADER LINE.

TYPES: BEGIN OF 1stoutput_typ,            "Table to output 1st
        bname        LIKE ust04-bname,
        name_text    LIKE adrp-name_text,
        isort        TYPE i,
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,
        description  LIKE /psyng/conflict-description,
        simu         TYPE c,
        contid       LIKE /psyng/1stoutput_u-contid,
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
        fields       TYPE slis_t_specialcol_alv,
      END OF 1stoutput_typ.

DATA: s1stoutput TYPE SORTED TABLE OF 1stoutput_typ WITH NON-UNIQUE KEY
        bname name_text imp conid
        WITH HEADER LINE.
DATA: wa_s1stoutput TYPE 1stoutput_typ.


DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA:   bname        LIKE ust04-bname,
        name_text    LIKE adrp-name_text,
        isort        TYPE i,
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,
        description  LIKE /psyng/conflict-description,
        simu         TYPE c,
        contid       LIKE /psyng/1stoutput_u-contid,
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol,  " Cell color
        fields TYPE slis_t_specialcol_alv.
DATA: END OF 1stoutput.


TYPES: BEGIN OF typ_outdet,      "Table containing SOD details
         bname        LIKE ust04-bname,     "For appending each user
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         agr_name     LIKE agr_prof-agr_name,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         profile      LIKE ust04-profile,
         description  LIKE /psyng/conflict-description,
         simu         TYPE c,
         color_line(4) TYPE c,           " Line color
         color_cell    TYPE lvc_t_scol,  " Cell color
       END OF typ_outdet.
DATA: wa_outdet TYPE typ_outdet.
DATA: outputdet TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid agr_name rfcdest tcode objct auth
                field von bis profile
                WITH HEADER LINE.

DATA: outputdet2 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid agr_name rfcdest tcode objct auth
                field von bis profile
                WITH HEADER LINE.

DATA: BEGIN OF outputdet3 OCCURS 0.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for capturing all conflicts
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,      "of ALL USERS to
        functionid   LIKE /psyng/functtran-functionid,   "be used for
        agr_name     LIKE agr_prof-agr_name,             "ALV output
        rfcdest      LIKE rfcdes-rfcdest,
        tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        profile      LIKE ust04-profile,
        description  LIKE /psyng/conflict-description,
        simu          TYPE c,
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF outputdet3.

DATA: BEGIN OF outputdet4 OCCURS 0.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for a user and conflict only
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,     "this is to be used
        functionid   LIKE /psyng/functtran-functionid,   "when a user
        agr_name     LIKE agr_prof-agr_name,             "double-clicks
        rfcdest      LIKE rfcdes-rfcdest,                "in summary
        tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        profile      LIKE ust04-profile,
        description  LIKE /psyng/conflict-description,
        simu          TYPE c,
        color_line(4) TYPE c,           " Line color
        color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF outputdet4.

DATA: outputdet5 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                 bname conid functionid agr_name rfcdest tcode objct
                 auth field von bis profile
                 WITH HEADER LINE.

DATA: outputdet6 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                 bname conid functionid agr_name rfcdest tcode objct
                 auth field von bis profile
                 WITH HEADER LINE.

DATA: BEGIN OF totalusers OCCURS 10.    "Document total users
DATA:   bname        LIKE ust04-bname,  "if users dont have any conflic
        noconf(1)    TYPE c.            "still to output text
DATA: END OF totalusers.

DATA: iusers TYPE HASHED TABLE OF usr02 WITH UNIQUE KEY
      bname
      WITH HEADER LINE.
DATA: wa_iusers TYPE usr02.

DATA: totalusers2 TYPE usr02 OCCURS 0 WITH HEADER LINE.

DATA: iagr_define TYPE HASHED TABLE OF agr_define WITH UNIQUE KEY
      agr_name
      WITH HEADER LINE.
DATA: wa_iagr_define TYPE agr_define.

DATA: conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
      conid "description
      WITH HEADER LINE.

DATA: iadrp TYPE SORTED TABLE OF adrp WITH UNIQUE KEY
      persnumber name_text
      WITH HEADER LINE.

DATA: iusr21 TYPE SORTED TABLE OF usr21 WITH UNIQUE KEY
      bname persnumber
      WITH HEADER LINE.

DATA: BEGIN OF usertcode_fm OCCURS 10.       "User tcode details
        INCLUDE STRUCTURE /psyng/usertcode.
DATA: END OF usertcode_fm.
DATA: susertcode TYPE SORTED TABLE OF /psyng/usertcode WITH UNIQUE KEY
                 bname rfcdest tcode auth profn agr_name
                 WITH HEADER LINE.
DATA: susertcode2 TYPE SORTED TABLE OF /psyng/usertcode WITH UNIQUE KEY
                  bname rfcdest tcode auth profn agr_name
                  WITH HEADER LINE.
DATA: roletcode_fm LIKE usertcode_fm OCCURS 10 WITH HEADER LINE.
DATA: wa_susertcode TYPE /psyng/usertcode.

DATA: BEGIN OF userauth_fm OCCURS 100.       "User auth details
        INCLUDE STRUCTURE /psyng/userauth.
DATA: END OF userauth_fm.
DATA: suserauth TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                bname rfcdest objct auth field von bis agr_name profn
                WITH HEADER LINE.

DATA: suserauth2 TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                 bname rfcdest objct auth field von bis agr_name profn
                 WITH HEADER LINE.
DATA: wa_suserauth TYPE /psyng/userauth.

DATA: roleauth_fm LIKE userauth_fm OCCURS 100 WITH HEADER LINE.

DATA: BEGIN OF uniqueauths OCCURS 0.
        INCLUDE STRUCTURE /psyng/uniqueauths.
DATA: END OF uniqueauths.

DATA: BEGIN OF userprof OCCURS 10.
        INCLUDE STRUCTURE /psyng/userprof.
DATA: END OF userprof.
DATA: wa_userprof TYPE /psyng/userprof.

DATA: roleprof_fm LIKE userprof OCCURS 10 WITH HEADER LINE.

TYPES: BEGIN OF typ_itcd,
         tcode LIKE /psyng/psswtcd-tcode,
         rfcdest LIKE rfcdes-rfcdest,
       END OF typ_itcd.
DATA: itcd TYPE SORTED TABLE OF typ_itcd WITH UNIQUE KEY
           tcode rfcdest
           WITH HEADER LINE.
DATA: wa_itcd TYPE typ_itcd.
DATA: BEGIN OF itcd2 OCCURS 10. "since sorted table
        INCLUDE STRUCTURE /psyng/psswtcd.  "can't be passed to FM
DATA: END OF itcd2.

DATA: rfc_tcd TYPE HASHED TABLE OF typ_itcd WITH UNIQUE KEY
              tcode rfcdest
              WITH HEADER LINE.
DATA: wa_rfc_tcd TYPE typ_itcd.
DATA: rfc_tcd_fm TYPE /psyng/psswtcd OCCURS 0 WITH HEADER LINE.

DATA: fields TYPE rfc_db_fld OCCURS 0 WITH HEADER LINE,
      data   TYPE tab512 OCCURS 0 WITH HEADER LINE,
      agrs   TYPE agr_define OCCURS 0 WITH HEADER LINE,
      simuagrs LIKE agr_define OCCURS 0 WITH HEADER LINE,
      data_agrs TYPE tab512 OCCURS 0 WITH HEADER LINE.

DATA: irfc LIKE rfcdes OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF itcdaut OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut.

DATA: BEGIN OF itcdaut2 OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut2.

DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.

DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.

TYPES: BEGIN OF typ_tobjs,
         funid   LIKE /psyng/faobj-funid,
         tcode   LIKE /psyng/faobj-tcode,
         object  LIKE /psyng/faobj-object,
         userhas,
       END OF typ_tobjs.
DATA: wa_tobjs1 TYPE typ_tobjs.
DATA: tobjs1 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.
DATA: tobjs2 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.
DATA: tobjs3 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.

TYPES: BEGIN OF typ_roletcode,
         agr_name  LIKE agr_define-agr_name,
         tcode     LIKE sy-tcode,
         child_agr LIKE agr_agrs-child_agr,
         rfcdest   LIKE rfcdes-rfcdest,
       END OF typ_roletcode.
DATA: wa_roletcode TYPE typ_roletcode.
DATA: roletcode TYPE SORTED TABLE OF typ_roletcode WITH UNIQUE KEY
                agr_name tcode child_agr rfcdest
                WITH HEADER LINE.

TYPES: BEGIN OF typ_roleauth,
         agr_name  LIKE agr_define-agr_name,
         rfcdest   LIKE rfcdes-rfcdest,
         objct     LIKE /psyng/userauth-objct,
         auth      LIKE /psyng/userauth-auth,
         field     LIKE /psyng/userauth-field,
         von       LIKE /psyng/userauth-von,
         bis       LIKE /psyng/userauth-bis,
         child_agr LIKE agr_agrs-agr_name,
       END OF typ_roleauth.
DATA: wa_roleauth TYPE typ_roleauth.
DATA: roleauth TYPE SORTED TABLE OF typ_roleauth WITH UNIQUE KEY
               agr_name rfcdest objct auth field von bis child_agr
               WITH HEADER LINE.

TYPES: BEGIN OF typ_routdet,
         agr_name      LIKE agr_define-agr_name,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         child_agr    LIKE agr_agrs-child_agr,
         description  LIKE /psyng/conflict-description,
       END OF typ_routdet.
DATA: wa_routdet TYPE typ_routdet.
DATA: routdet TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
              agr_name conid functionid rfcdest tcode objct auth field
              von bis child_agr
              WITH HEADER LINE.
DATA: routdet2 TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
               agr_name conid functionid rfcdest tcode objct auth field
               von bis child_agr
               WITH HEADER LINE.
DATA: routdet3 TYPE typ_routdet OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF routdet4 OCCURS 0,
         agr_name      LIKE agr_define-agr_name,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         child_agr    LIKE agr_agrs-child_agr,
         description  LIKE /psyng/conflict-description,
       END OF routdet4.

DATA: routdet5 TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
               agr_name conid functionid tcode objct auth field von bis
               child_agr
               WITH HEADER LINE.

DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.

DATA: tusercount    TYPE i,
      conflictcount TYPE i,
      averagecon    TYPE i,
      c_tusercount(6)  TYPE c,
      c_usercount(6)   TYPE c,
      c_averagecon(4)  TYPE c,
      oldbname      TYPE usr02-bname,
      trolecount    TYPE i,
      c_trolecount(6)  TYPE c,
      c_rolecount(6)   TYPE c.

DATA: wa_mcugroup TYPE /psyng/mcusrgrp.

TYPES: BEGIN OF ft_typ,
         tcode TYPE tcode,
         functionid TYPE /psyng/function_id,
       END OF ft_typ.

DATA: ft TYPE SORTED TABLE OF ft_typ WITH UNIQUE KEY
         tcode functionid WITH HEADER LINE.
DATA: wa_ft TYPE ft_typ.
DATA: ft_idx TYPE i.

TYPES: BEGIN OF cf_typ,
         functionid TYPE /psyng/function_id,
         conid TYPE /psyng/conflict_id,
       END OF cf_typ.

DATA: cf TYPE SORTED TABLE OF cf_typ WITH UNIQUE KEY
         functionid conid WITH HEADER LINE.
DATA: wa_cf TYPE cf_typ.
DATA: cf_idx TYPE i.

DATA: usertcode_idx   TYPE i,
      userauth_idx    TYPE i,
      outputdet_idx   TYPE i,
      itcdaut_idx     TYPE i.
data: bysimu,
      ROLE type standard table of /PSYNG/RANGE_AGR_NAME
              with header line,
      simurols type standard table of /PSYNG/RANGE_AGR_NAME
              with header line,
      SPCONFS type standard table of /PSYNG/RANGE_CONID
              with header line.
