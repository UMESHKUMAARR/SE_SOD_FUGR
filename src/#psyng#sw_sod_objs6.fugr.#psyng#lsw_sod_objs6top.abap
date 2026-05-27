FUNCTION-POOL /psyng/sw_sod_objs6 MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
CLASS /PSYNG/SW_CL_CONSTANTS DEFINITION LOAD.
*Global Data declarations for SW_036
DATA : gt_roles       TYPE TABLE OF /psyng/sw_sel_opts_agr_name,
       gt_roles_simu  TYPE TABLE OF /psyng/sw_sel_opts_agr_name,
       gt_confs       TYPE TABLE OF /psyng/sw_sel_opts_conid,
       gt_sens        TYPE TABLE OF /psyng/sw_sel_opts_imp,
       gt_risk        TYPE TABLE OF /psyng/range_risk,
       g_vrsio        TYPE  /psyng/sodvrsio ,
       g_org_check    TYPE  flag ,
       gf_org_field type flag, "AKUMAR OPL645
       g_enh_fm       TYPE  flag,
       g_rchdatf      TYPE  menu_date,
       g_rchdatt      TYPE  menu_date,
       g_simu_rfc     TYPE  rfcdest,
       g_xstb_fm      TYPE  flag,
       g_bysimu       TYPE flag,
       gt_routput_sum TYPE TABLE OF /PSYNG/SW_OUT_ROUTPUT,
       gt_routput     TYPE TABLE OF /PSYNG/SW_OUT_ROUTPUT,
       g_return type bapireturn,
       gt_faobj_org1 type table of /psyng/faobj2. "AKUMAR OPL645
DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.
DATA: conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
      conid "description
      WITH HEADER LINE.
DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.
DATA: BEGIN OF faobj OCCURS 100.
        INCLUDE STRUCTURE /psyng/faobj2.
DATA: END OF faobj.
DATA: swsodorgm       TYPE STANDARD TABLE OF /psyng/swsodorgm
                      WITH HEADER LINE,
      gt_enh_tcodes TYPE TABLE OF /psyng/sw_par_tcode_output.
DATA: iagr_define TYPE HASHED TABLE OF agr_define WITH UNIQUE KEY
      agr_name
      WITH HEADER LINE.
DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.

DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2,
      simuagrs LIKE agr_define OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF roleauth_fm OCCURS 100.       "Role auth details
        INCLUDE STRUCTURE /psyng/userauth.
DATA: END OF roleauth_fm.
DATA: BEGIN OF roletcode_fm OCCURS 10.       "Role tcode details
        INCLUDE STRUCTURE /psyng/usertcode.
DATA: END OF roletcode_fm.
DATA: BEGIN OF roleprof_fm OCCURS 10.
        INCLUDE STRUCTURE /psyng/userprof.
DATA: END OF roleprof_fm.

DATA: et_agrs TYPE STANDARD TABLE OF agr_agrs WITH HEADER LINE.
DATA: et_1016 TYPE STANDARD TABLE OF agr_1016 WITH HEADER LINE.
DATA: et_1251 TYPE STANDARD TABLE OF agr_1251 WITH HEADER LINE.
DATA: et_1252 TYPE STANDARD TABLE OF agr_1252 WITH HEADER LINE.
DATA: et_ust10s TYPE STANDARD TABLE OF ust10s WITH HEADER LINE.

TYPES : BEGIN OF type_confs_org ,
         agr_name TYPE agr_name,
         conid TYPE /psyng/conflict_id,
         funid TYPE /psyng/function_id,
         abb TYPE /psyng/dorg_abb,
         END OF type_confs_org.


  TYPEs : BEGIN OF type_org_obj,
      funid TYPE /psyng/function_id,
      tcode TYPE tcode,
      object TYPE xuobject,
      abb TYPE /psyng/dorg_abb,
      obj_or(3)  TYPE c,
      userhas TYPE flag,
      END OF type_org_obj.
data :
  g_org_obj type table of type_org_obj,
  g_swsodorgm type table of /psyng/swsodorgm,
  g_confs_org type sorted table of type_confs_org
  WITH UNIQUE KEY agr_name funid abb.


TYPES: BEGIN OF typ_roletcode.
 include structure /PSYNG/ROLETCODE.
TYPES: END OF typ_roletcode.

DATA: wa_roletcode TYPE typ_roletcode.
DATA: roletcode TYPE SORTED TABLE OF typ_roletcode WITH UNIQUE KEY
                agr_name tcode child_agr rfcdest
                WITH HEADER LINE.

TYPES: BEGIN OF typ_roleauth.
        include structure /PSYNG/ROLEAUTH.
TYPES: END OF typ_roleauth.
DATA: wa_roleauth TYPE typ_roleauth.

DATA: roleauth TYPE HASHED TABLE OF typ_roleauth WITH UNIQUE KEY
               agr_name rfcdest objct auth
*DHORIONS 2018/01/04 - /PSYNG/SW_SODSYS_GET_ROLE_DATA only returns 1
*record per object-auth combo, so no need for additional keys
*field von bis child_agr
               WITH HEADER LINE.
DATA: BEGIN OF uniqueauths OCCURS 0.
        INCLUDE STRUCTURE /psyng/uniqueauths.
DATA: END OF uniqueauths.
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
TYPES: BEGIN OF typ_tobjs,
         funid   LIKE /psyng/faobj2-funid,
         tcode   LIKE /psyng/faobj2-tcode,
         object  LIKE /psyng/faobj2-object,
         obj_or  LIKE /psyng/faobj2-obj_or,
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


DATA: BEGIN OF itcdaut_fm OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut_fm.

DATA: itcdaut TYPE SORTED TABLE OF /psyng/psswtcdaut WITH UNIQUE KEY
              rfcdest funid tcode objct auth field von bis
              WITH HEADER LINE.
DATA: wa_itcdaut TYPE /psyng/psswtcdaut.

DATA: BEGIN OF itcdaut2 OCCURS 0.
        INCLUDE STRUCTURE /psyng/psswtcdaut.
DATA: END OF itcdaut2.

DATA: BEGIN OF functtran2 OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran2.
TYPES: BEGIN OF ft_typ,
         tcode TYPE tcode,
         functionid TYPE /psyng/function_id,
       END OF ft_typ.

DATA: ft TYPE SORTED TABLE OF ft_typ WITH UNIQUE KEY
         tcode functionid WITH HEADER LINE.

TYPES: BEGIN OF cf_typ,
         functionid TYPE /psyng/function_id,
         conid TYPE /psyng/conflict_id,
       END OF cf_typ.

DATA: cf TYPE SORTED TABLE OF cf_typ WITH UNIQUE KEY
         functionid conid WITH HEADER LINE,
    wa_ft           TYPE ft_typ,
    wa_cf           TYPE cf_typ.
TYPES: BEGIN OF typ_routdet,
         agr_name      LIKE agr_define-agr_name,
         isort        TYPE i,
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,     "details
         risk         LIKE /psyng/conflict-risk,
         functionid   LIKE /psyng/functtran-functionid,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         org_abb      LIKE /psyng/swsodorgm-abb,"org level reporting
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         child_agr    LIKE agr_agrs-child_agr,
         description  LIKE /psyng/conflict-description,
         simu         TYPE c,
         enhanced     TYPE c, "flag for enhanced ruleset
       END OF typ_routdet.

DATA : wa_routdet      TYPE     typ_routdet,
      routdet         TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
                      agr_name conid functionid "rfcdest tcode objct
                      auth field von bis child_agr org_abb
                      WITH HEADER LINE,
      routdet2        TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
                      agr_name conid functionid
                      tcode objct
                      auth field von bis child_agr org_abb
                      WITH HEADER LINE,
      routdet5        TYPE SORTED TABLE OF typ_routdet WITH UNIQUE KEY
                      agr_name conid functionid
                      tcode objct auth field
                      von bis child_agr
                      WITH HEADER LINE.
DATA: routdet3 TYPE typ_routdet OCCURS 0 WITH HEADER LINE.
DATA: BEGIN OF routdet4 OCCURS 0,
         agr_name      LIKE agr_define-agr_name,  "composite role
         isort        TYPE i,
         imp          LIKE /psyng/conflict-imp,
         conid        LIKE /psyng/conflict-conid,    "details
         functionid   LIKE /psyng/functtran-functionid,
         rfcdest      LIKE rfcdes-rfcdest,
         tcode        LIKE /psyng/faobj2-tcode, "parent tcode of auth
         objct        LIKE ust12-objct,
         org_abb      LIKE /psyng/swsodorgm-abb,"org level reporting
         auth         LIKE ust12-auth,
         field        LIKE ust12-field,
         von          LIKE ust12-von,
         bis          LIKE ust12-bis,
         child_agr    LIKE agr_agrs-child_agr,   "single role
         description  LIKE /psyng/conflict-description,
         simu         TYPE c,
         enhanced     TYPE c, "flag for enhanced ruleset
         color_line(4) TYPE c,           " Line color
         color_cell    TYPE lvc_t_scol,  " Cell color
       END OF routdet4.

*Org level info
DATA:       gt_systemauths  TYPE SORTED TABLE OF /psyng/swsodorgauth
                      WITH NON-UNIQUE KEY auth.

*--Declared globally but only used locally
DATA: subrc TYPE sy-subrc,
      idx1 LIKE sy-tabix,
      idx2 LIKE sy-tabix,
      idx3 LIKE sy-tabix,
      length LIKE sy-tabix,
      next_agr_name LIKE agr_define-agr_name, "to calculate idx2
      next_profn LIKE ust10s-profn.           "to calculate idx2

DATA: lt_agrs TYPE SORTED TABLE OF agr_agrs
      WITH UNIQUE KEY agr_name child_agr
      WITH HEADER LINE.
DATA: lt_totalagr TYPE STANDARD TABLE OF agr_define
      WITH HEADER LINE.
DATA: lt_1016 TYPE SORTED TABLE OF agr_1016
      WITH UNIQUE KEY agr_name profile
      WITH HEADER LINE.
DATA: lt_ust10s TYPE SORTED TABLE OF ust10s
      WITH UNIQUE KEY profn aktps objct auth
      WITH HEADER LINE.
DATA: lt_1251 TYPE SORTED TABLE OF agr_1251
      WITH UNIQUE KEY agr_name object auth field low high
      WITH HEADER LINE.
DATA: lt_1252 TYPE SORTED TABLE OF agr_1252
      WITH UNIQUE KEY agr_name varbl low high
      WITH HEADER LINE.
DATA: wa_1016 TYPE agr_1016.
DATA: wa_1251 TYPE agr_1251.
DATA: wa_1252 TYPE agr_1252.
DATA : lt_funcctran TYPE SORTED TABLE OF /psyng/functtran
WITH NON-UNIQUE KEY  tcode,
functtran_tabix LIKE sy-tabix,
ft_tabix LIKE sy-tabix,
cf_tabix LIKE sy-tabix.
DATA: roletcode_idx   TYPE i,
      roleauth_idx    TYPE i.
DATA: usertcode_idx   TYPE i,
      userauth_idx    TYPE i,
      itcdaut_idx     TYPE i.
data : GT_FUNCTRAN_NO_ENH type table of /psyng/functtran
       with header line,
       gt_orglvl      type table of /PSYNG/RANGE_DORG_ABB,
       gt_faobj_org type table of /psyng/faobj2. "AKUMAR OPL645
FIELD-SYMBOLS : <iagr_define> LIKE iagr_define,
                <roletcode>   LIKE roletcode,
                <functtran>   LIKE functtran,
                <ft>          LIKE ft,
                <cf>          LIKE cf,
                <confdet>     LIKE confdet,
                <itcdaut>     LIKE itcdaut,
                <roleauth>    LIKE roleauth.
