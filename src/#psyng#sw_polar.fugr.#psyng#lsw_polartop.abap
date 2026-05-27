FUNCTION-POOL /PSYNG/SW_POLAR.              "MESSAGE-ID ..

*BELOW variables may ONLY be used in sw_033 !!!
data : gt_polar type table of /PSYNG/SW_ROLE_POLAR,
       gt_polar_combo type table of /PSYNG/SW_ROLE_POLAR_combo,
       gt_polar_combo_users
       type table of /PSYNG/SW_ROLE_POLAR_combo_usr,

       g_numproc type i,
       g_numres type i,
       g_pct_per_process type f,
       g_pct_progress type f,
       g_prev_pct type i.
* ABOVE variables may ONLY be used in sw_033 !!!
*Types
TYPES: BEGIN OF typ_itcd,
         tcode LIKE /psyng/psswtcd-tcode,
         rfcdest LIKE rfcdes-rfcdest,
       END OF typ_itcd.

TYPES: BEGIN OF typ_tobjs,
         funid   LIKE /psyng/faobj2-funid,
         tcode   LIKE /psyng/faobj2-tcode,
         object  LIKE /psyng/faobj2-object,
         obj_or  LIKE /psyng/faobj2-obj_or,
         userhas,
       END OF typ_tobjs.
TYPES: BEGIN OF ft_typ,
         tcode TYPE tcode,
         functionid TYPE /psyng/function_id,
       END OF ft_typ.


TYPES: BEGIN OF cf_typ,
         functionid TYPE /psyng/function_id,
         conid TYPE /psyng/conflict_id,
       END OF cf_typ.
         TYPES: BEGIN OF typ_outdet,      "Table containing SOD details
         bname        LIKE ust04-bname,     "For appending each user
         org_abb      LIKE /psyng/swsodorgm-abb,"Org level reporting
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         comp_agr     LIKE agr_agrs-agr_name,
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
         enhanced     TYPE C, "flag for enhanced ruleset
         color_line(4) TYPE c,           " Line color
       END OF typ_outdet.

*Global Variables
DATA: wa_tobjs1 TYPE typ_tobjs.
DATA: usertcode_idx   TYPE i,
      userauth_idx    TYPE i,
      itcdaut_idx     TYPE i.
DATA: wa_outdet TYPE typ_outdet.

RANGES: gr_role FOR agr_agrs-child_agr.
DATA: iduser_fm TYPE STANDARD TABLE OF /psyng/sw_iduser_fm
                WITH HEADER LINE,
      idcl_data_received VALUE 'Y'.
DATA: conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
      conid "description
      WITH HEADER LINE.

DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.
DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.
DATA: BEGIN OF faobj OCCURS 100.
        INCLUDE STRUCTURE /psyng/faobj2.
DATA: END OF faobj.
DATA: swsodorgm       TYPE STANDARD TABLE OF /psyng/swsodorgm
                      WITH HEADER LINE,
      gt_systemauths  TYPE SORTED TABLE OF /psyng/swsodorgauth
                      WITH NON-UNIQUE KEY auth,
      gt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output.

.DATA: dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y',
      wa_swconfig TYPE /psyng/swconfig.

data : validusr type flag value 'X'.
DATA: iusers TYPE HASHED TABLE OF usr02 WITH UNIQUE KEY
      bname
      WITH HEADER LINE.
DATA: totalusers2 TYPE usr02 OCCURS 0 WITH HEADER LINE,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.
      TYPES: BEGIN OF idusers_typ,
         bname LIKE usr02-bname,
         class LIKE usr02-class,
       END OF idusers_typ.
DATA: idusers TYPE HASHED TABLE OF idusers_typ WITH UNIQUE KEY
      bname
      WITH HEADER LINE.
DATA: iusrefus TYPE STANDARD TABLE OF usrefus WITH HEADER LINE.

  DATA: BEGIN OF usertcode_fm OCCURS 10.       "User tcode details
        INCLUDE STRUCTURE /psyng/usertcode.
DATA: END OF usertcode_fm.
DATA: BEGIN OF uniqueauths OCCURS 0.
        INCLUDE STRUCTURE /psyng/uniqueauths.
DATA: END OF uniqueauths.

DATA: BEGIN OF userprof OCCURS 10.
        INCLUDE STRUCTURE /psyng/userprof.
DATA: END OF userprof.
DATA: susertcode TYPE SORTED TABLE OF /psyng/usertcode WITH UNIQUE KEY
                 bname rfcdest tcode auth profn agr_name
                 WITH HEADER LINE.
DATA: BEGIN OF userauth_fm OCCURS 100.       "User auth details
        INCLUDE STRUCTURE /psyng/userauth.
DATA: END OF userauth_fm.
DATA: suserauth TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                bname rfcdest objct auth field von bis agr_name profn
                WITH HEADER LINE.
DATA: BEGIN OF outputdet3 OCCURS 0.      "Table containing SOD details
DATA:   bname        LIKE ust04-bname,     "for capturing all conflicts
        org_abb      LIKE /psyng/swsodorgm-abb,"Org level reporting
        imp          LIKE /psyng/conflict-imp,
        conid        LIKE /psyng/conflict-conid,      "of ALL USERS to
        functionid   LIKE /psyng/functtran-functionid,   "be used for
        comp_agr     LIKE agr_agrs-agr_name,
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
        simu          TYPE c,
        enhanced     TYPE C, "flag for enhanced ruleset
        color_line(4) TYPE c.           " Line color
 DATA: END OF outputdet3.
DATA: itcd TYPE SORTED TABLE OF typ_itcd WITH UNIQUE KEY
           tcode rfcdest
           WITH HEADER LINE.
DATA: tobjs1 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.
DATA: tobjs2 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.
DATA: tobjs3 TYPE SORTED TABLE OF typ_tobjs WITH UNIQUE KEY
             funid tcode object
             WITH HEADER LINE.
DATA: BEGIN OF itcd2 OCCURS 10. "since sorted table
        INCLUDE STRUCTURE /psyng/psswtcd.  "can't be passed to FM
DATA: END OF itcd2.
DATA: BEGIN OF itcdaut OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut.
DATA: cf TYPE SORTED TABLE OF cf_typ WITH UNIQUE KEY
         functionid conid WITH HEADER LINE.
DATA: ft TYPE SORTED TABLE OF ft_typ WITH UNIQUE KEY
         tcode functionid WITH HEADER LINE.
DATA: outputdet2 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid comp_agr agr_name rfcdest tcode
                objct auth field von bis profile
                WITH HEADER LINE.
DATA: outputdet5 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                 bname conid functionid agr_name rfcdest tcode objct
                 auth field von bis profile
                 WITH HEADER LINE.
DATA: outputdet TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid comp_agr agr_name rfcdest tcode
                objct auth field von bis profile
                WITH HEADER LINE.
DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.
DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.
data : showcomp type flag.
