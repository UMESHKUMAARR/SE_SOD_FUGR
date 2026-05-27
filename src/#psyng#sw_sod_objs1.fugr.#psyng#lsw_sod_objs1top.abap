FUNCTION-POOL /psyng/sw_sod_objs1 MESSAGE-ID sv.

TABLES: agr_users, agr_agrs, agr_1251, tstct, sscrfields.
TABLES: /psyng/functtran, /psyng/conflict,
        /psyng/rolehdr, /psyng/confdet, agr_prof, bapiret1,
        adr6, usr21, tobj, /psyng/sw_sod_st, /psyng/mcusrgrp.

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
      percent   TYPE i,    "Progress indicator flag
      records   TYPE f,    "# of records in table
      percentxt(8),        "Text field for percent
      ptext(3),            "only 1st 2 chars of percent
      ucounttxt(8),        "total user count text
      pertext(200),        "Progress indicator text
      nodata    VALUE 'Y', "No data in table flag
      done      TYPE c,
      oldauth   LIKE ust12-auth,
      newauth   LIKE ust12-auth,
      oldfield  LIKE ust12-field,
      newfield  LIKE ust12-field,
      rfcdest LIKE rfcdes-rfcdest,
      exit_proc.

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

*DATA: BEGIN OF sodobject OCCURS 100.
*        INCLUDE STRUCTURE /psyng/sodobject.
*DATA: END OF sodobject.

*DATA: BEGIN OF auths_fm OCCURS 10.
*        INCLUDE STRUCTURE usref.
*DATA: END OF auths_fm.

*DATA: BEGIN OF values_fm OCCURS 10.
*        INCLUDE STRUCTURE usref.
*DATA: END OF values_fm.

*DATA: BEGIN OF sodobject1 OCCURS 100.          "Table to do binary
*DATA:   object LIKE /psyng/sodobject-object,   "searches on object
*        tcode LIKE /psyng/sodobject-tcode,
*        field LIKE /psyng/sodobject-field,
*        val_from LIKE /psyng/sodobject-val_from,
*        val_to LIKE /psyng/sodobject-val_to.
*DATA: END OF sodobject1.

*DATA: profinfo2 LIKE profinfo OCCURS 10 WITH HEADER LINE.

DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA:   bname        LIKE ust04-bname,
        name_text    LIKE adrp-name_text,
        conid        LIKE /psyng/conflict-conid,
        description  LIKE /psyng/conflict-description,
        imp          LIKE /psyng/conflict-imp,
        impsort      TYPE n,
        contid       LIKE /psyng/mchdr-contid.
DATA: END OF 1stoutput.

*DATA: outputdet2 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
*                bname conid functionid agr_name rfcdest tcode objct
*auth
*                field von bis profile
*                WITH HEADER LINE.
*
*
*DATA: BEGIN OF outputdet3 OCCURS 100.      "Table containing SOD
*details
*DATA:   bname        LIKE ust04-bname,     "for capturing all conflicts
*        conid        LIKE /psyng/conflict-conid,      "of ALL USERS to
*        functionid   LIKE /psyng/functtran-functionid,   "be used for
*        agr_name     LIKE agr_prof-agr_name,             "ALV output
*        rfcdest      LIKE rfcdes-rfcdest,
*        tcode        LIKE /psyng/faobj-tcode, "parent tcode of auth
*        objct        LIKE ust12-objct,
*        auth         LIKE ust12-auth,
*        field        LIKE ust12-field,
*        von          LIKE ust12-von,
*        bis          LIKE ust12-bis,
*        profile      LIKE ust04-profile,
*        description  LIKE /psyng/conflict-description.
*DATA: END OF outputdet3.

DATA: BEGIN OF outputdet4 OCCURS 100.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for a user and conflict only
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
        description  LIKE /psyng/conflict-description.
DATA: END OF outputdet4.

* Check whether a user has auth for all objects for a particular tcode
*DATA: outputdet6 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
*                 bname conid functionid agr_name rfcdest tcode objct
*                 auth field von bis profile
*                 WITH HEADER LINE.

DATA: BEGIN OF totalusers OCCURS 10.    "Document total users
DATA:   bname        LIKE ust04-bname,  "if users dont have any conflic
        noconf(1)    TYPE c.            "still to output text
DATA: END OF totalusers.

DATA: iagr_define TYPE HASHED TABLE OF agr_define WITH UNIQUE KEY
      agr_name
      WITH HEADER LINE.
DATA: wa_iagr_define TYPE agr_define.

DATA: wa_conflict TYPE /psyng/conflict.

DATA: susertcode2 TYPE SORTED TABLE OF /psyng/usertcode WITH UNIQUE KEY
                  bname rfcdest tcode auth profn agr_name
                  WITH HEADER LINE.

* Table used for comparison
DATA: suserauth2 TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                 bname rfcdest objct auth field von bis agr_name profn
                 WITH HEADER LINE.

DATA: fields TYPE rfc_db_fld OCCURS 0 WITH HEADER LINE,
      data   TYPE tab512 OCCURS 0 WITH HEADER LINE,
      agrs   TYPE agr_define OCCURS 0 WITH HEADER LINE,
      data_agrs TYPE tab512 OCCURS 0 WITH HEADER LINE.

DATA: BEGIN OF itcd2 OCCURS 10. "since sorted table
        INCLUDE STRUCTURE /psyng/psswtcd.  "can't be passed to FM
DATA: END OF itcd2.

DATA: BEGIN OF itcdaut2 OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut2.

*DATA: authdetails LIKE itcdaut OCCURS 0.
*DATA: wa_confs1 LIKE confs1.

DATA: start    TYPE i,                                      "Run time 1
      finish   TYPE i,                                      "Run time 2
      diff1    TYPE i,                           "Time difference 1
      diff2    TYPE i,                           "Time difference 2
      ndata(4) TYPE n,                           "Numeric text
      pdata    TYPE p DECIMALS 2,                "Packed
      fdata    TYPE f,                           "Floating point
      idata    TYPE i.                           "Integer

* To build summary numbers for output text in ALV
DATA: conflictcount TYPE i,
      averagecon    TYPE i,
      c_tusercount(6)  TYPE c,
      c_usercount(6)   TYPE c,
      c_averagecon(4)  TYPE c.

*colors in ALV
DATA: BEGIN OF alv_table1 OCCURS 0.
        INCLUDE STRUCTURE outputdet4.
DATA:   colortab TYPE lvc_t_scol,
      END OF alv_table1.

*Indices declaration
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
      tmp_functionid  LIKE /psyng/confdet-functionid.

DATA: iusers2 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE.

DATA: iuserscount TYPE i.
DATA: split TYPE i,
      taskname(8),
      taskcount(1),
      messagetext(40),
      spoolnum TYPE sy-spono,
      max_wp TYPE i VALUE '4'.

****************************************************
DATA: idcl_task(9) VALUE 'IDCL_USER'.
DATA: idcl_data_received.

*^^^^^^^^^^^^************* Identical user  ****^^^^^^^^^^^^^***********
