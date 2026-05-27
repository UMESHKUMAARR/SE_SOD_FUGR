***INCLUDE /PSYNG/SODTOP .
***INCLUDE /PSYNG/SODTOP .

TABLES: agr_users, agr_agrs, agr_1251, tstct, sscrfields.
TABLES: /psyng/functtran, /psyng/conflict, /psyng/sodobject,
        /psyng/rolehdr, /psyng/confdet, agr_prof, bapiret1,
        adr6, usr21.

TABLES: ust04, ust10c, ust10s, ust12, tactt.

TABLES: usr02, agr_tcodes, pa0001, pa0105,
        agr_define, rfcdes.

TYPE-POOLS: slis.                                      "For ALV call
DATA: program         LIKE sy-repid.                   "For ALV call
DATA: i_fieldcat_alv  TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv2 TYPE slis_t_fieldcat_alv,        "For ALV call
      i_fieldcat_alv3 TYPE slis_t_fieldcat_alv,        "For ALV call
      alv_layout      TYPE slis_layout_alv,            "For ALV call
      wa_fieldcat     LIKE LINE OF i_fieldcat_alv,     "For ALV call
      wa_variant      LIKE disvariant,                 "For ALV call
      wa_title        LIKE sy-title,                   "For ALV call
      alv_grid_titl   TYPE lvc_title.                  "For ALV call


DATA: first_char TYPE c, fr_low TYPE ust12-von,
      to_high TYPE ust12-von.

DATA: table1done TYPE c,   "Flag for finishing 1st table
      table2done TYPE c.   "Flag for finishing 2nd table

DATA: usercount TYPE f,    "Progress indicator flag
      counter   TYPE f,    "Progress indicator flag
      percent   TYPE f,    "Progress indicator flag
      records   TYPE f,    "# of records in table
      percentxt(8),        "Text field for percent
      ptext(2),            "only 1st 2 chars of percent
      pertext(200),        "Progress indicator text
      nodata    VALUE 'Y', "No data in table flag
      done      TYPE c,
      oldauth   LIKE ust12-auth,
      newauth   LIKE ust12-auth,
      oldfield  LIKE ust12-field,
      newfield  LIKE ust12-field.

DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.
DATA: ifuncttran TYPE SORTED TABLE OF /psyng/functtran WITH UNIQUE KEY
                      functionid tcode WITH HEADER LINE.
DATA: wa_functtran TYPE /psyng/functtran.

DATA: BEGIN OF functtran2 OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran2.

DATA: BEGIN OF confdet OCCURS 100.
        INCLUDE STRUCTURE /psyng/confdet.
DATA: END OF confdet.

DATA: BEGIN OF sodobject OCCURS 100.
        INCLUDE STRUCTURE /psyng/sodobject.
DATA: END OF sodobject.

DATA: BEGIN OF auths_fm OCCURS 10.
        INCLUDE STRUCTURE usref.
DATA: END OF auths_fm.

DATA: BEGIN OF values_fm OCCURS 10.
        INCLUDE STRUCTURE usref.
DATA: END OF values_fm.

DATA: BEGIN OF sodobject1 OCCURS 100.          "Table to do binary
DATA:   object LIKE /psyng/sodobject-object,   "searches on object
        tcode LIKE /psyng/sodobject-tcode,
        field LIKE /psyng/sodobject-field,
        val_from LIKE /psyng/sodobject-val_from,
        val_to LIKE /psyng/sodobject-val_to.
DATA: END OF sodobject1.

DATA: BEGIN OF profinfo OCCURS 10.                "Single profile list
DATA:   profn     LIKE ust10c-profn,
        composite TYPE c.
DATA: END OF profinfo.

DATA: profinfo2 LIKE profinfo OCCURS 10 WITH HEADER LINE.

DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA:   bname        LIKE ust04-bname,
        conid        LIKE /psyng/conflict-conid,
        description  LIKE /psyng/conflict-description.
DATA: END OF 1stoutput.

types: BEGIN OF ty_outdet,           "Table containing SOD details
        bname        LIKE ust04-bname,    "For appending each user
        conid        LIKE /psyng/conflict-conid,    "details
        functionid   LIKE /psyng/functtran-functionid,
        rfcdest      LIKE rfcdes-rfcdest,
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        description  LIKE /psyng/conflict-description,
        agr_name     LIKE agr_prof-agr_name,
        profile      LIKE ust04-profile.
      END OF outputdet.

data: begin of outputdet type ty_outdet occurs 10 with header line.
*DATA: BEGIN OF outputdet OCCURS 1000.   "Table containing SOD details
*DATA:   bname        LIKE ust04-bname,     "For appending each user
*        conid        LIKE /psyng/conflict-conid,    "details
*        functionid   LIKE /psyng/functtran-functionid,
*        rfcdest      LIKE rfcdes-rfcdest,
*        objct        LIKE ust12-objct,
*        auth         LIKE ust12-auth,
*        field        LIKE ust12-field,
*        von          LIKE ust12-von,
*        bis          LIKE ust12-bis,
*        description  LIKE /psyng/conflict-description,
*        agr_name     LIKE agr_prof-agr_name,
*        profile      LIKE ust04-profile.
*DATA: END OF outputdet.

DATA: BEGIN OF outputdet2 OCCURS 100.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "For validating all functions
        conid        LIKE /psyng/conflict-conid,     "are executable by
        functionid   LIKE /psyng/functtran-functionid,   "a user for
        rfcdest      LIKE rfcdes-rfcdest,                "conflicts
        objct        LIKE ust12-objct,                      "step 6
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        description  LIKE /psyng/conflict-description,
        agr_name     LIKE agr_prof-agr_name,
        profile      LIKE ust04-profile.
DATA: END OF outputdet2.

DATA: BEGIN OF outputdet3 OCCURS 100.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for capturing all conflicts
        conid        LIKE /psyng/conflict-conid,      "of all users to
        functionid   LIKE /psyng/functtran-functionid,   "be used for
        rfcdest      LIKE rfcdes-rfcdest,                "ALV output
        objct        LIKE ust12-objct,
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        description  LIKE /psyng/conflict-description,
        agr_name     LIKE agr_prof-agr_name,
        profile      LIKE ust04-profile.
DATA: END OF outputdet3.

DATA: BEGIN OF outputdet4 OCCURS 100.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for a user and conflict only
        conid        LIKE /psyng/conflict-conid,     "this is to be used
        functionid   LIKE /psyng/functtran-functionid,   "when a user
        rfcdest      LIKE rfcdes-rfcdest,                "double-clicks
        objct        LIKE ust12-objct,                   "in summary
        auth         LIKE ust12-auth,
        field        LIKE ust12-field,
        von          LIKE ust12-von,
        bis          LIKE ust12-bis,
        description  LIKE /psyng/conflict-description,
        agr_name     LIKE agr_prof-agr_name,
        profile      LIKE ust04-profile.
DATA: END OF outputdet4.

DATA: BEGIN OF totalusers OCCURS 10.    "Document total users
DATA:   bname        LIKE ust04-bname,  "if users dont have any conflic
        noconf(1)    TYPE c.            "still to output text
DATA: END OF totalusers.

DATA: BEGIN OF usertcode OCCURS 10.       "User tcode details
        INCLUDE STRUCTURE /psyng/usertcode.
DATA: END OF usertcode.
* table to get data from function module
DATA: roletcode_fm LIKE usertcode OCCURS 10.

DATA: BEGIN OF usertcode2 OCCURS 10.       "User tcode details
        INCLUDE STRUCTURE /psyng/usertcode.
DATA: END OF usertcode2.

DATA: BEGIN OF userprof OCCURS 10.
        INCLUDE STRUCTURE /psyng/userprof.
DATA: END OF userprof.
* table to get data from function module
DATA: roleprof_fm LIKE userprof OCCURS 10.

DATA: BEGIN OF userauth OCCURS 100.       "User auth details
        INCLUDE STRUCTURE /psyng/userauth.
DATA: END OF userauth.
* Table used for comparison
DATA: userauth2 LIKE userauth OCCURS 100 WITH HEADER LINE.
* table to get data from function module
DATA: roleauth_fm LIKE userauth OCCURS 100.

* unique list of user's tcode, for function module
DATA: BEGIN OF itcd OCCURS 10.
        INCLUDE STRUCTURE /psyng/psswtcd.
DATA: END OF itcd.

* authorization required to execute the tcode
DATA: BEGIN OF itcdaut OCCURS 10.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut.

DATA: BEGIN OF itcdaut2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut2.

*For Step 6 - Validating a user can perform all functions of conflict
DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.
DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.

DATA: start    TYPE i,                                      "Run time 1
      finish   TYPE i,                                      "Run time 2
      diff1    TYPE i,                           "Time difference 1
      diff2    TYPE i,                           "Time difference 2
      ndata(4) TYPE n,                           "Numeric text
      pdata    TYPE p DECIMALS 2,                "Packed
      fdata    TYPE f,                           "Floating point
      idata    TYPE i.                           "Integer
