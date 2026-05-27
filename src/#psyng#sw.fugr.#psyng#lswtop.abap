FUNCTION-POOL /psyng/sw                  MESSAGE-ID sv.
CLASS /psyng/sw_cl_constants DEFINITION LOAD.
include /psyng/sw_config.
INCLUDE /psyng/basis_exelog.
TABLES: agr_users, agr_agrs, agr_1251, tstc, tstct, agr_1252,
        agr_1016.
TABLES: /psyng/functtran, /psyng/conflict, /psyng/sodobject,
        /psyng/rolehdr, /psyng/confdet, agr_prof, bapiret1,
        /psyng/userprof, /psyng/usertcode, /psyng/userauth,
        /psyng/function, /psyng/swaudhdr, /psyng/mchdr,
        /psyng/mcrepid, /psyng/mctran, /psyng/mcuser,
        /psyng/mcusrgrp, /psyng/swinvisbl, /psyng/sw_stat1,
        /psyng/history.

TABLES: ust04, ust10c, ust10s, ust12, sscrfields.

TABLES: usr02, agr_tcodes, "pa0001,  pa0105,
        agr_define, rfcdes.

DATA: first_char TYPE c, fr_low TYPE ust12-von,
      to_high TYPE ust12-von.

DATA: table1done TYPE c,   "Flag for finishing 1st table
      table2done TYPE c.   "Flag for finishing 2nd table

DATA: usercount TYPE i,    "Progress indicator flag
      usercount_c(6),
      records   TYPE i,    "Progress indicator flag
      records_c(6),
      message(200),
      asterisk TYPE c VALUE '*',
      g_mandt like sy-mandt.

DATA: BEGIN OF functtran OCCURS 100.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF functtran.

DATA: BEGIN OF ftcodes OCCURS 0.  "Unique list of tcodes in SOD matrix
DATA:   tcode LIKE sy-tcode.      "used to perfrom binary searches
DATA: END OF ftcodes.
DATA: BEGIN OF faobj OCCURS 100.
        INCLUDE STRUCTURE /psyng/faobj2.
DATA: END OF faobj.

DATA: BEGIN OF profinfo OCCURS 10.                "Single profile list
DATA:   profn     LIKE ust10c-profn,
        composite TYPE c.
DATA: END OF profinfo.

DATA: profinfo2 LIKE profinfo OCCURS 10 WITH HEADER LINE.

DATA: BEGIN OF ifuncttran        OCCURS 0.
        INCLUDE STRUCTURE /psyng/functtran.
DATA: END OF ifuncttran.

* * * * * * * * * * * *     CAUTION !!!       * * * * * * * * * * *
*The below type is used in SOD reports as well as critical auth reports
*/PSYNG/SW_GET_TCODE_AUTH_DATA     &   /PSYNG/SW_GET_CRIT_AUTH_DATA
* Make sure any changes to below type does not impact either of those
* funciton modules
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
* * * * * * * * * *  CAUTION !!!   READ DOCU ABOVE  * * * * * * * * * *

*Table contains auths and values that the user has
DATA: iust12 TYPE SORTED TABLE OF typ_iust12 WITH UNIQUE KEY
             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.
DATA: wa_iust12 TYPE typ_iust12.
DATA: wa_just12 TYPE typ_iust12.
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

TYPES: BEGIN OF typ_xust12,
         objct LIKE ust12-objct,
         aktps LIKE ust12-aktps,
         field LIKE ust12-field,
         auth  LIKE ust12-auth,
         von   LIKE ust12-von,
         bis   LIKE ust12-bis,
       END OF typ_xust12.
*table for containing all auths values for objects in FAOBJ table
*Type need for hash table for performing loops
DATA: xust12 TYPE SORTED TABLE OF typ_xust12 WITH UNIQUE KEY
             objct aktps field auth von bis
             WITH HEADER LINE.
DATA: wa_xust12 TYPE typ_xust12.

DATA: BEGIN OF wvr_sod_objects   OCCURS 0.
        INCLUDE STRUCTURE /psyng/faobj2.
DATA:   auth LIKE ust12-auth.
DATA:   flag TYPE c.
DATA: END OF wvr_sod_objects.

DATA: exist     TYPE c,
      one_exist TYPE c.

TYPES: BEGIN OF typ_iagrprof,
         profile LIKE agr_prof-profile,
         agr_name LIKE agr_prof-agr_name,
       END OF typ_iagrprof.
DATA: wa_iagrprof TYPE typ_iagrprof.
DATA: iagrprof TYPE SORTED TABLE OF typ_iagrprof WITH UNIQUE KEY
               profile agr_name
               WITH HEADER LINE.

TYPES: BEGIN OF typ_agrprof,
        profile LIKE agr_prof-profile,
        agr_name LIKE agr_prof-agr_name,
       END OF typ_agrprof.
DATA: gt_agrprof TYPE SORTED TABLE OF typ_agrprof WITH UNIQUE KEY
               profile agr_name
               WITH HEADER LINE.

DATA: BEGIN OF g_wa_tstct,
      tcode LIKE tstct-tcode,
      END OF g_wa_tstct.

DATA: gt_i_tstct LIKE TABLE OF g_wa_tstct WITH HEADER LINE
      INITIAL SIZE 0.


DATA: sagrprof TYPE typ_iagrprof OCCURS 0 WITH HEADER LINE.

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
      aust10s_idx     TYPE i,
      aust12_idx      TYPE i.

TYPES: BEGIN OF typ_outdet,      "Table containing SOD details
         bname        LIKE ust04-bname,     "For appending each user
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
       END OF typ_outdet.
DATA: wa_outdet TYPE typ_outdet.

DATA: outputdet TYPE HASHED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid
                WITH HEADER LINE.

DATA: outputdet5 TYPE HASHED TABLE OF typ_outdet WITH UNIQUE KEY
                 bname conid functionid
                 WITH HEADER LINE.

*************    CRITICAL AUTHORIZATIONS    ***********************
*Table contains auths and values that the user has
DATA: iust12a TYPE SORTED TABLE OF typ_iust12 WITH UNIQUE KEY
             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.

*Table contains auths and values the user does not have
DATA: just12a TYPE SORTED TABLE OF typ_iust12 WITH UNIQUE KEY
             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.

*Table for temporary storage
DATA: kust12a TYPE STANDARD TABLE OF typ_iust12 "WITH UNIQUE KEY
*             funid tcode mandt objct auth aktps field von bis
             WITH HEADER LINE.

DATA: suserprof TYPE SORTED TABLE OF /psyng/userprof WITH UNIQUE KEY
                bname rfcdest profile
                WITH HEADER LINE.
DATA: wa_suserprof TYPE /psyng/userprof.

DATA: suserauth TYPE SORTED TABLE OF /psyng/userauth WITH UNIQUE KEY
                bname rfcdest objct auth field von bis agr_name profn
                WITH HEADER LINE.
DATA: wa_suserauth TYPE /psyng/userauth.
DATA: suserauth_idx TYPE i.

DATA: susertcode TYPE SORTED TABLE OF /psyng/usertcode
      WITH UNIQUE KEY
      bname rfcdest tcode auth profn
      WITH HEADER LINE.
DATA: wa_susertcode TYPE /psyng/usertcode.

DATA: BEGIN OF userhas OCCURS 0,
        swaudid LIKE /psyng/swaudc2-swaudid,
        bname LIKE usr02-bname,
      END OF userhas.

DATA: userprof_idx TYPE i.
DATA: wa_ust12 TYPE ust12.
*************    CRITICAL AUTHORIZATIONS    ***********************

INCLUDE lsvimdat                                . "general data decl.
INCLUDE /psyng/lswt00                           . "view rel. data dcl.

*******************   SYS-WIDE SCAN    ****************************

DATA: dbust12_idx TYPE i, dbust10s_idx TYPE i, dbtstc_idx TYPE i.
DATA: dbust12 TYPE SORTED TABLE OF ust12 WITH NON-UNIQUE KEY
             objct auth aktps field von
             WITH HEADER LINE.
*******************   SYS-WIDE SCAN    ****************************
*******************   SYS-WIDE SCAN  NEW **************************

TYPES: BEGIN OF typ_tobjs,
         funid   LIKE /psyng/faobj2-funid,
         tcode   LIKE sy-tcode,
         object  LIKE /psyng/faobj2-object,
         userhas,
       END OF typ_tobjs.

DATA: iusers TYPE HASHED TABLE OF usr02 WITH UNIQUE KEY
      bname
      WITH HEADER LINE.
DATA: wa_iusers TYPE usr02.


DATA: tmp_functionid  LIKE /psyng/confdet-functionid.

DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
              conid functionid
              WITH HEADER LINE.

DATA: outputdet2 TYPE SORTED TABLE OF typ_outdet WITH UNIQUE KEY
                bname conid functionid agr_name rfcdest tcode objct auth
                field von bis profile
                WITH HEADER LINE.

DATA: itcdaut TYPE HASHED TABLE OF /psyng/psswtcdaut WITH UNIQUE KEY
              rfcdest funid tcode objct auth
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
DATA: wa_tobjs1 TYPE typ_tobjs.

DATA: BEGIN OF confs1 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs1.
DATA: wa_confs1 LIKE confs1.
DATA: BEGIN OF confs2 OCCURS 10.
        INCLUDE STRUCTURE /psyng/confdet.
DATA:   userhas.
DATA: END OF confs2.

TYPES: BEGIN OF 1stoutput_typ,
        bname        LIKE ust04-bname,
        name_text    LIKE adrp-name_text,
        conid        LIKE /psyng/conflict-conid,
        description  LIKE /psyng/conflict-description,
      END OF 1stoutput_typ.

DATA: s1stoutput TYPE SORTED TABLE OF 1stoutput_typ WITH UNIQUE KEY
        bname name_text conid
        WITH HEADER LINE.
DATA: wa_s1stoutput TYPE 1stoutput_typ.

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

*******************   SYS-WIDE SCAN  NEW **************************
* 11/22/06 additions

DATA: itcd TYPE SORTED TABLE OF /psyng/psswtcd WITH UNIQUE KEY
      tcode rfcdest
      WITH HEADER LINE.
DATA: ifaobj TYPE SORTED TABLE OF /psyng/faobj2 WITH UNIQUE KEY
      funid tcode object valueset field val_from val_to
      WITH HEADER LINE.

DATA: 1ust12 TYPE SORTED TABLE OF typ_xust12 WITH NON-UNIQUE KEY
             objct aktps field
             WITH HEADER LINE.
DATA: wa_1ust12 TYPE typ_xust12.

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

* End of 11/22/06 addition

* Start of Role mitigations 3/25/07
DATA: mcroleauth TYPE SORTED TABLE OF /psyng/sw_mc_role_auths
                 WITH UNIQUE KEY rfcdest objct auth conid
*                 sagr_name cagr_name
                 WITH HEADER LINE.
DATA: hmcroleauth TYPE HASHED TABLE OF /psyng/sw_mc_role_auths
                  WITH UNIQUE KEY rfcdest objct auth conid
*                  sagr_name cagr_name
                  WITH HEADER LINE.
DATA: wa_mcroleauth TYPE /psyng/sw_mc_role_auths.
DATA: role LIKE agr_define-agr_name.
* End of Role mitigations

* Begin of SOD Conflict details screen
CONTROLS: tc_funct     TYPE TABLEVIEW USING SCREEN 1000,
          tc_tstct     TYPE TABLEVIEW USING SCREEN 1000,
          tc_mctran    TYPE TABLEVIEW USING SCREEN 1100,
          tc_mcrepid   TYPE TABLEVIEW USING SCREEN 1100,
          tc_mcauditor TYPE TABLEVIEW USING SCREEN 1100,
          tc_critcode TYPE TABLEVIEW USING SCREEN 1200.

RANGES: gr_tcode FOR /psyng/functtran-tcode.

DATA: BEGIN OF gt_text OCCURS 0,
        text TYPE /psyng/texts-text,
      END OF gt_text.

DATA: BEGIN OF gt_funct OCCURS 0,
        function    TYPE /psyng/function-function,
        description TYPE /psyng/function-description,
        sel         TYPE /psyng/flagx,
      END OF gt_funct.

DATA: BEGIN OF gt_tstct OCCURS 0,
        tcode TYPE tstct-tcode,
        ttext TYPE tstct-ttext,
      END OF gt_tstct.
* End of SOD Conflict details screen

*Global data for fm /PSYNG/SW_029
DATA : gt_result_sw_026   TYPE   TABLE OF /psyng/sw_par_tcode_output,
       gt_result_sw_027   TYPE   TABLE OF /psyng/sw_par_tcode_output,
       BEGIN OF gt_tasks_sw_029 OCCURS 0,
          taskname(8),
       END OF gt_tasks_sw_029,
       gf_sw_026_failed TYPE flag,
       gf_sw_027_failed TYPE flag.

DATA: gt_history TYPE STANDARD TABLE OF /psyng/history WITH HEADER LINE,
      gt_mctran    TYPE TABLE OF /psyng/mctran WITH HEADER LINE,
      gt_mcrepid   TYPE TABLE OF /psyng/mcrepid WITH HEADER LINE ,
      gt_mcauditor TYPE TABLE OF /psyng/mcauditor WITH HEADER LINE.

*******************************************************************

**   CHANGE DOCUMENT
DATA: objectid              LIKE cdhdr-objectid,
      tcode                 LIKE cdhdr-tcode,
      planned_change_number LIKE cdhdr-planchngnr,
      utime                 LIKE cdhdr-utime,
      udate                 LIKE cdhdr-udate,
      username              LIKE cdhdr-username,
      cdoc_planned_or_real  LIKE cdhdr-change_ind,
      cdoc_upd_object       LIKE cdhdr-change_ind VALUE 'U',
      cdoc_no_change_pointers LIKE cdhdr-change_ind.

DATA: upd_icdtxt_functs          TYPE c.
DATA: BEGIN OF icdtxt_functs          OCCURS 20.
        INCLUDE STRUCTURE cdtxt.
DATA: END OF icdtxt_functs         .

DATA: upd_psyng_faobj2                   TYPE c.

DATA: upd_psyng_function                 TYPE c.

DATA: upd_psyng_functtran                TYPE c.

DATA: upd_psyng_texts                    TYPE c.
*********************************************
TYPES: BEGIN OF t_trans,
         tcode LIKE tstct-tcode,
         ttext LIKE tstct-ttext,
         imp   LIKE /psyng/critcodes-imp,
         owner LIKE /psyng/critcodes-owner,
       END OF t_trans.
DATA:gt_critcodes TYPE TABLE OF t_trans WITH HEADER LINE.
DATA:g_vrsio TYPE  /psyng/swaudhdr-vrsio.

DATA:    g_start       TYPE /psyng/dec11,
         g_stop        TYPE /psyng/dec11.

*****SE 3.1 enahancements.
DATA: gt_critauths TYPE /psyng/swaudhdr.
*--Macro for Logging into a structure of type BAPIRET2
* &1 : table of type BAPIRET2 with header line
* &2 : Message type: S Success, E Error, W Warning, I Info, A Abort
* &3 : ID, Message class
* &4 : Message text part 1
* &5 : Message text part 2
* &6 : Message text part 3
* &7 : Message text part 4

define log.
  &1-TYPE    = &2.
  &1-ID      = &3.
  concatenate &4 &5 &6 &7 into &1-MESSAGE separated by space.
  append &1.
end-of-definition.

*--Macro for Logging into a structure of type BAPIRET2
*  Filling the first two message variables
* &1 : table of type BAPIRET2 with header line
* &2 : Message type: S Success, E Error, W Warning, I Info, A Abort
* &3 : ID, Message class
* &4 : Message text part 1
* &5 : Message text part 2
* &6 : Message text part 3
* &7 : MESSAGE_V1
* &8 : MESSAGE_V2

define log_v.
  &1-TYPE    = &2.
  &1-ID      = &3.
  concatenate &4 &5 &6 into &1-MESSAGE separated by space.
  &1-MESSAGE_V1 = &7.
  &1-MESSAGE_V2 = &8.
  append &1.
end-of-definition.
