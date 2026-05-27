FUNCTION-POOL sw_sod_objs2                  MESSAGE-ID sv.
CLASS /PSYNG/SW_CL_CONSTANTS DEFINITION LOAD.
INCLUDE /PSYNG/SW_CONFIG.
TABLES: agr_users, agr_agrs, agr_1251, tstct, sscrfields.
TABLES: /psyng/functtran, /psyng/conflict, agr_1252,
        /psyng/rolehdr, /psyng/confdet, /psyng/faobj2, agr_prof,
        bapiret1, adr6, usr21, tobj, /psyng/mcusrgrp, /psyng/swsodorgm.

TABLES: ust04, ust10c, ust10s, ust12, tactt.

TABLES: usr02, agr_tcodes,          "pa0001, pa0105,
        agr_define, rfcdes, varid.

TYPE-POOLS: slis.                                      "For ALV call
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv3 TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      wa_fieldcat     LIKE LINE OF i_fieldcat_alv,     "For ALV call
      wa_variant      LIKE disvariant,                 "For ALV call
      wa_title        LIKE sy-title,                   "For ALV call
      alv_grid_titl   TYPE lvc_title,                  "For ALV call
      alv_grid_titl2  TYPE lvc_title.                  "For ALV call
DATA: wa_fieldcat_alv TYPE slis_t_fieldcat_alv WITH HEADER LINE.
DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
DATA: l_sort TYPE slis_sortinfo_alv.


DATA: first_char TYPE c, fr_low TYPE ust12-von,
      to_high TYPE ust12-von.

DATA: table1done TYPE c,   "Flag for finishing 1st table
      table2done TYPE c.   "Flag for finishing 2nd table

DATA: usercount TYPE i,    "Progress indicator flag
      counter   TYPE i,    "Progress indicator flag
      percent   TYPE f,    "Progress indicator flag
      records   TYPE f,    "# of records in table
      udone(8),            "only 1st 2 chars of percent
      ucounttxt(8),        "total user count text
      pertext(200),        "Progress indicator text
      nodata    VALUE 'Y', "No data in table flag
      done      TYPE c,
      oldauth   LIKE ust12-auth,
      newauth   LIKE ust12-auth,
      oldfield  LIKE ust12-field,
      newfield  LIKE ust12-field,
      rfcdest LIKE rfcdes-rfcdest,
      exit_proc,
      update_scan_default VALUE 'N'.


DATA: percentxt(3),
      prtext(3),
      percenti TYPE i.

*Background job variables
DATA: var_number_c(13),
      var_number TYPE i,
      curr_report LIKE  rsvar-report,
      curr_variant LIKE  rsvar-variant,
      vari_desc TYPE varid OCCURS 0 WITH HEADER LINE,
      vari_contents LIKE  rsparams OCCURS 0 WITH HEADER LINE,
      vari_text LIKE varit OCCURS 0 WITH HEADER LINE.
DATA: variant LIKE vari-variant.
DATA: irsparams TYPE rsparams OCCURS 0 WITH HEADER LINE.
DATA: ivarit TYPE varit OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.

DATA: BEGIN OF functtran2 OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran2.

*DATA: BEGIN OF confdet OCCURS 100.
*        INCLUDE STRUCTURE /psyng/confdet.
*DATA: END OF confdet.

DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.
DATA: confdet_tmp TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
                  conid functionid
                  WITH HEADER LINE.
DATA: wa_confdet TYPE /psyng/confdet.

*DATA: BEGIN OF sodobject OCCURS 100.
*        INCLUDE STRUCTURE /psyng/sodobject.
*DATA: END OF sodobject.

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
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         profile      LIKE ust04-profile,
         description  LIKE /psyng/conflict-description,
         simu         TYPE c,
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
        tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        profile      LIKE ust04-profile,
        description  LIKE /psyng/conflict-description,
        simu         TYPE c.
DATA: END OF outputdet3.

DATA: BEGIN OF outputdet4 OCCURS 0.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for a user and conflict only
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,     "this is to be used
        functionid   LIKE /psyng/functtran-functionid,   "when a user
        agr_name     LIKE agr_prof-agr_name,             "double-clicks
        rfcdest      LIKE rfcdes-rfcdest,                "in summary
        tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        profile      LIKE ust04-profile,
        description  LIKE /psyng/conflict-description,
        simu         TYPE c.
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
DATA: wa_conflict TYPE /psyng/conflict.

DATA: iadrp TYPE SORTED TABLE OF adrp WITH UNIQUE KEY
      persnumber name_text
      WITH HEADER LINE.
DATA: wa_adrp TYPE adrp.

DATA: iusr21 TYPE SORTED TABLE OF usr21 WITH UNIQUE KEY
      bname persnumber
      WITH HEADER LINE.
DATA: wa_usr21 TYPE usr21.

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
DATA: wa_confs1 LIKE confs1.
DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.

TYPES: BEGIN OF typ_tobjs,
         funid   LIKE /psyng/faobj2-funid,
         tcode   LIKE /psyng/faobj2-tcode,
         object  LIKE /psyng/faobj2-object,
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
DATA: roletcode2 TYPE SORTED TABLE OF typ_roletcode WITH UNIQUE KEY
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
DATA: roleauth2 TYPE SORTED TABLE OF typ_roleauth WITH UNIQUE KEY
                agr_name rfcdest objct auth field von bis child_agr
                WITH HEADER LINE.

TYPES: BEGIN OF typ_routdet,
         agr_name      LIKE agr_define-agr_name,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
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
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
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
DATA: routdet6 TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
               agr_name conid functionid tcode objct auth field von bis
               child_agr
               WITH HEADER LINE.

DATA: ifields TYPE STANDARD TABLE OF sval WITH HEADER LINE.

*DATA: BEGIN OF r1stoutput OCCURS 10.            "Table to output 1st
*DATA:   agr_name     LIKE agr_define-agr_name,
*        conid        LIKE /psyng/conflict-conid,
*        description  LIKE /psyng/conflict-description.
*DATA: END OF r1stoutput.

DATA: start    TYPE i,                                      "Run time 1
      finish   TYPE i,                                      "Run time 2
      diff1    TYPE i,                           "Time difference 1
      diff2    TYPE i,                           "Time difference 2
      ndata(4) TYPE n,                           "Numeric text
      pdata    TYPE p DECIMALS 2,                "Packed
      fdata    TYPE f,                           "Floating point
      idata    TYPE i.                           "Integer

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

*colors in ALV
DATA: BEGIN OF alv_table1 OCCURS 0.
        INCLUDE STRUCTURE outputdet4.
DATA:   colortab TYPE lvc_t_scol,
      END OF alv_table1.

DATA: wa_fields TYPE LINE OF slis_t_specialcol_alv.

DATA: usertcode_idx   TYPE i,
      sodtab1_idx     TYPE i,
      userauth_idx    TYPE i,
      tobjs1_idx      TYPE i,
      usertcode2_idx  TYPE i,
      sodtab2_idx     TYPE i,
      userauth2_idx   TYPE i,
      tobjs2_idx      TYPE i,
      outputdet_idx   TYPE i,
      outputdet2_idx  TYPE i,
      itcdaut_idx     TYPE i,
      tmp_functionid  LIKE confdet-functionid.
DATA: BEGIN OF ftcodes OCCURS 0.  "Unique list of tcodes in SOD matrix
DATA:   tcode LIKE sy-tcode.      "used to perfrom binary searches
DATA: END OF ftcodes.

DATA: BEGIN OF faobj1 OCCURS 100.              "Table to do binary
DATA:   object LIKE /psyng/faobj2-object,   "searches on object
        funid LIKE /psyng/faobj2-funid,
        tcode LIKE /psyng/faobj2-tcode,
        field LIKE /psyng/faobj2-field,
        val_from LIKE /psyng/faobj2-val_from,
        val_to LIKE /psyng/faobj2-val_to.
DATA: END OF faobj1.

DATA: wa_agr_1251 TYPE agr_1251.

**------------------------------------------

DATA: ifaobj TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
      funid tcode object valueset field val_from val_to
      WITH HEADER LINE.
DATA: ifaobj_idx TYPE i.

TYPES: BEGIN OF typ_xust12,
         objct LIKE ust12-objct,
         aktps LIKE ust12-aktps,
         field LIKE ust12-field,
         auth  LIKE ust12-auth,
         von   LIKE ust12-von,
         bis   LIKE ust12-bis,
       END OF typ_xust12.

DATA: 1ust12 TYPE SORTED TABLE OF typ_xust12 WITH NON-UNIQUE KEY
             objct aktps field
             WITH HEADER LINE.
DATA: wa_1ust12 TYPE typ_xust12.

TYPES: BEGIN OF typ_iust12,
         funid LIKE /psyng/faobj2-funid,
         tcode LIKE tstc-tcode,
         mandt LIKE ust12-mandt,
         objct LIKE ust12-objct,
         auth  LIKE ust12-auth,
         aktps LIKE ust12-aktps,
         field LIKE ust12-field,
         von   LIKE ust12-von,
         bis   LIKE ust12-bis,
       END OF typ_iust12.

*Table contains auths and values that the user has
DATA: iust12 TYPE SORTED TABLE OF typ_iust12 WITH UNIQUE KEY
             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.
DATA: wa_iust12 TYPE typ_iust12.

*Table contains auths and values the user does not have
DATA: just12 TYPE SORTED TABLE OF typ_iust12 WITH UNIQUE KEY
             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.
DATA: wa_just12 TYPE typ_iust12.

*Table for temporary storage
DATA: kust12 TYPE STANDARD TABLE OF typ_iust12 "WITH UNIQUE KEY
*             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.
DATA: wa_kust12 TYPE typ_iust12.

*Table for inserting all UST12 values
TYPES: BEGIN OF iiust12_typ,
         objct LIKE ust12-objct,
         field  LIKE ust12-field,
         aktps  LIKE ust12-aktps,
         auth   LIKE ust12-auth,
         von    LIKE ust12-von,
         bis    LIKE ust12-bis,
       END OF  iiust12_typ.

DATA: iiust12 TYPE SORTED TABLE OF iiust12_typ WITH UNIQUE KEY
              objct field aktps auth von bis
              WITH HEADER LINE.
DATA: wa_iiust12 TYPE iiust12_typ.
DATA: iiust12_idx TYPE i.

DATA: aust12 TYPE SORTED TABLE OF ust12 WITH UNIQUE KEY
              objct field aktps auth von bis
              WITH HEADER LINE.
DATA: aust10s TYPE SORTED TABLE OF ust10s WITH UNIQUE KEY
              profn aktps objct auth
              WITH HEADER LINE.

DATA: xust12 TYPE SORTED TABLE OF typ_xust12 WITH UNIQUE KEY
             objct aktps field auth von bis
             WITH HEADER LINE.
DATA: wa_xust12 TYPE typ_xust12.
DATA: xust12_idx TYPE i.

TYPES: BEGIN OF wfaobj_typ,
        funid LIKE /psyng/faobj2-funid,
        tcode LIKE /psyng/faobj2-tcode,
        object LIKE /psyng/faobj2-object,
        valueset LIKE /psyng/faobj2-valueset,
        field LIKE /psyng/faobj2-field,
        val_from LIKE /psyng/faobj2-val_from,
        val_to LIKE /psyng/faobj2-val_to,
        auth LIKE ust12-auth,
        flag TYPE c,
       END OF wfaobj_typ.

DATA: wfaobj TYPE SORTED TABLE OF wfaobj_typ WITH UNIQUE KEY
      funid tcode object valueset field val_from val_to
      WITH HEADER LINE.
DATA: wa_wfaobj TYPE wfaobj_typ.

DATA: dbust12_idx TYPE i, dbust10s_idx TYPE i, dbtstc_idx TYPE i.
DATA: dbust12 TYPE SORTED TABLE OF ust12 WITH NON-UNIQUE KEY
             objct auth aktps field von
             WITH HEADER LINE.

DATA: exist     TYPE c,
      one_exist TYPE c.
