FUNCTION-POOL /psyng/sw_sod MESSAGE-ID /psyng/sw.
TYPES: BEGIN OF t_user,
         bname TYPE usr02-bname,
         class TYPE usr02-class,
       END OF t_user,

       BEGIN OF t_cf,
         functionid TYPE /psyng/function_id,
         conid      TYPE /psyng/conflict_id,
       END OF t_cf,

       BEGIN OF t_ft,
         tcode TYPE tcode,
         functionid TYPE /psyng/function_id,
       END OF t_ft.

TYPES: BEGIN OF t_tobjs,
         funid   LIKE /psyng/faobj2-funid,
         tcode   LIKE /psyng/faobj2-tcode,
         object  LIKE /psyng/faobj2-object,
         userhas,
       END OF t_tobjs,

       BEGIN OF t_outdet,         "Table containing SOD details
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
       END OF t_outdet.

DATA: gt_confdet    TYPE /psyng/confdet      OCCURS 0 WITH HEADER LINE,
      gt_functtran  TYPE /psyng/functtran    OCCURS 0 WITH HEADER LINE,
      gt_faobj      TYPE /psyng/faobj2        OCCURS 0 WITH HEADER LINE,
      gt_tcdaut     TYPE /psyng/psswtcdaut   OCCURS 0 WITH HEADER LINE,
      gt_iduser     TYPE /psyng/sw_iduser_fm OCCURS 0 WITH HEADER LINE,
      gt_users      TYPE HASHED TABLE OF t_user
                    WITH UNIQUE KEY bname WITH HEADER LINE,
      gt_usertcode  TYPE SORTED TABLE OF /psyng/usertcode
                    WITH UNIQUE KEY bname rfcdest tcode auth profn
                    agr_name WITH HEADER LINE,
      gt_userauth   TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                    bname rfcdest objct auth field von bis agr_name
                    profn WITH HEADER LINE,
      gt_tcd        TYPE SORTED TABLE OF /psyng/psswtcd WITH UNIQUE KEY
                    tcode rfcdest WITH HEADER LINE,
      gt_cf         TYPE SORTED TABLE OF t_cf WITH UNIQUE KEY
                    functionid conid WITH HEADER LINE,
      gt_ft         TYPE SORTED TABLE OF t_ft WITH UNIQUE KEY
                    tcode functionid WITH HEADER LINE,
      gs_tobjs1     TYPE t_tobjs,
      gt_tobjs1     TYPE SORTED TABLE OF t_tobjs WITH UNIQUE KEY
                    funid tcode object WITH HEADER LINE,
      gt_tobjs3     TYPE SORTED TABLE OF t_tobjs WITH UNIQUE KEY
                    funid tcode object WITH HEADER LINE,
      gt_outputdet  TYPE SORTED TABLE OF t_outdet WITH UNIQUE KEY
                    bname conid functionid agr_name rfcdest tcode objct
                    auth field von bis profile WITH HEADER LINE,
      gt_outputdet2 TYPE SORTED TABLE OF t_outdet WITH UNIQUE KEY
                    bname conid functionid agr_name rfcdest tcode objct
                    auth field von bis profile WITH HEADER LINE,
      gt_outputdet3 TYPE TABLE OF t_outdet WITH HEADER LINE,

      BEGIN OF gt_confs1 OCCURS 0.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas,
      END OF gt_confs1,

      BEGIN OF gt_confs2 OCCURS 0.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas,
      END OF gt_confs2,

*      BEGIN OF gt_conflict OCCURS 0,
*        conid       TYPE /psyng/conflict-conid,
*        description TYPE /psyng/conflict-description,
*        imp         TYPE /psyng/conflict-imp,
*      END OF gt_conflict,
      gt_conflict type table of /psyng/conflict with header line,
      wa_gt_users   TYPE t_user.
