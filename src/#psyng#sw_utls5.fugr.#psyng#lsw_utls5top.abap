FUNCTION-POOL /PSYNG/SW_UTLS5.              "MESSAGE-ID ..
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/basis_exelog.
type-pools:slis.
TABLES: ust10s, agr_agrs, tstct, rfcdes, /psyng/mcuser,
        /psyng/mcuseraud,/psyng/tsw_hst.
DATA: BEGIN OF iust04 OCCURS 0.
        INCLUDE STRUCTURE ust04.
DATA:   cprofn LIKE ust10c-profn.
DATA: END OF iust04.

DATA: BEGIN OF iiust04 OCCURS 0.
        INCLUDE STRUCTURE ust04.
DATA:   cprofn LIKE ust10c-profn.
DATA: END OF iiust04.

DATA: iusr02 TYPE STANDARD TABLE OF usr02 WITH HEADER LINE.
DATA: wa_usr02 TYPE usr02.
DATA: iswaudc TYPE STANDARD TABLE OF /psyng/swaudc2 WITH HEADER LINE.
DATA: wa_iswaudc TYPE /psyng/swaudc2.
DATA: iust12 TYPE STANDARD TABLE OF ust12 WITH HEADER LINE.
DATA: iust10s TYPE STANDARD TABLE OF ust10s WITH HEADER LINE.
DATA: profinfo TYPE STANDARD TABLE OF /psyng/profinfo WITH HEADER LINE.
DATA: tcdaut TYPE STANDARD TABLE OF /psyng/psswtcdaut WITH HEADER LINE.
DATA: iust10c TYPE STANDARD TABLE OF ust10c WITH HEADER LINE.
DATA: usertcode TYPE STANDARD TABLE OF /psyng/usertcode
      WITH HEADER LINE.
DATA: userprof TYPE STANDARD TABLE OF /psyng/userprof WITH HEADER LINE.
DATA: userauth TYPE STANDARD TABLE OF /psyng/userauth WITH HEADER LINE.
DATA: swaudhdr TYPE STANDARD TABLE OF /psyng/swaudhdr WITH HEADER LINE.
DATA: iusgrpt TYPE STANDARD TABLE OF usgrpt WITH HEADER LINE.
DATA: sw_uinfo TYPE STANDARD TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
DATA: kostl_resp TYPE STANDARD TABLE OF /psyng/sw_kostl_resp
      WITH HEADER LINE.
DATA: wa_usertcode TYPE /psyng/usertcode.

DATA: BEGIN OF itcdaut OCCURS 0,
        swaudid LIKE iswaudc-swaudid,
        tcode LIKE tcdaut-tcode,
        objct LIKE tcdaut-objct,
        auth  LIKE tcdaut-auth,
      END OF itcdaut.

DATA: tcdaut_idx TYPE i,
      iuserauth_idx TYPE i,
      iusertcode_idx TYPE i.


TYPES: BEGIN OF typ_userauth,
        objct LIKE tcdaut-objct,
        auth LIKE tcdaut-auth,
        bname LIKE userauth-bname,
      END OF typ_userauth.

DATA: huserauth TYPE HASHED TABLE OF typ_userauth WITH UNIQUE KEY
                objct auth bname
                WITH HEADER LINE.
DATA: iuserauth TYPE STANDARD TABLE OF typ_userauth
                WITH HEADER LINE.
DATA: suserauth TYPE SORTED TABLE OF typ_userauth WITH NON-UNIQUE KEY
                objct auth
                WITH HEADER LINE.
DATA: wa_suserauth TYPE typ_userauth.

DATA: BEGIN OF iusertcode OCCURS 0,
        tcode LIKE usertcode-tcode,
        bname LIKE usertcode-bname,
      END OF iusertcode.


DATA: BEGIN OF profiles OCCURS 0,
        profn LIKE ust10s-profn,
      END OF profiles.

DATA: BEGIN OF audcobjs OCCURS 0,
        objct LIKE ust10s-objct,
      END OF audcobjs.

DATA: BEGIN OF 10sobjs OCCURS 0,
        objct LIKE ust10s-objct,
        auth LIKE ust10s-auth,
      END OF 10sobjs.

TYPES: BEGIN OF userhas_typ,            "Table to output 1st
        swaudid LIKE /psyng/swaudc-swaudid,
        bname LIKE usr02-bname,
      END OF userhas_typ.

DATA: userhas TYPE HASHED TABLE OF userhas_typ WITH UNIQUE KEY
        swaudid bname
        WITH HEADER LINE.
DATA: wa_userhas TYPE userhas_typ.
TYPES: BEGIN OF userhas_obj_typ,
        swaudid LIKE /psyng/swaudc-swaudid,
        bname LIKE usr02-bname,
        objct LIKE ust10s-objct,
        tcode LIKE usertcode-tcode,
      END OF userhas_obj_typ.
DATA: userhas_obj TYPE HASHED TABLE OF userhas_obj_typ WITH UNIQUE KEY
        swaudid bname tcode objct .

DATA: functioncall_1(4),
      done(4) VALUE 'DONE'.

DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y'.

*Start of Reference User
DATA: iusrefus1 TYPE STANDARD TABLE OF usrefus WITH HEADER LINE.
*end of Reference user.


*Critical auths in roles
DATA: dbust12_idx TYPE i.

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

DATA: first_char TYPE c, fr_low TYPE ust12-von,
      to_high TYPE ust12-von.

DATA: BEGIN OF atcodes OCCURS 0,
        tcode LIKE tstc-tcode,
      END OF atcodes.
data : gf_details type flag, "include details in output
       gt_outputdet type table of /PSYNG/SW_CA_OUTPUTDET,
       gt_routputdet type table of /PSYNG/SW_CA_ROUTPUTDET.
