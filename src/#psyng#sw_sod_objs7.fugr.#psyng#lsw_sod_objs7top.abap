*----------------------------------------------------------------------*
* Include :  /PSYNG/LSW_SOD_OBJS7TOP                                   *
* AUTHOR  : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

FUNCTION-POOL /PSYNG/SW_SOD_OBJS7.          "MESSAGE-ID ..
INCLUDE /PSYNG/SW_CONFIG.
*--types
TYPES: BEGIN OF typ_roletcode.
 include structure /PSYNG/ROLETCODE.
TYPES: END OF typ_roletcode.
TYPES: BEGIN OF typ_roleauth.
        include structure /PSYNG/ROLEAUTH.
TYPES: END OF typ_roleauth.

TYPES : BEGIN OF typ_swaudid_auth,
          swaudid TYPE /psyng/swaudid,
          auth    TYPE xuauth,
          object  TYPE xuobject,
          tcode   TYPE tcode,
        END OF typ_swaudid_auth,

        BEGIN OF typ_audcobjs,
        objct LIKE ust10s-objct,
        END OF typ_audcobjs.
.TYPES: BEGIN OF userhas_obj_typ,
        swaudid LIKE /psyng/swaudc-swaudid,
        bname LIKE usr02-bname,
        objct LIKE ust10s-objct,
        tcode TYPE tcode,
      END OF userhas_obj_typ.
.TYPES: BEGIN OF rolehas_obj_typ,
        swaudid LIKE /psyng/swaudc-swaudid,
        agr_name type agr_name,
        objct LIKE ust10s-objct,
        tcode TYPE tcode,
      END OF rolehas_obj_typ.

TYPES: BEGIN OF userhas_typ,
        swaudid LIKE /psyng/swaudc-swaudid,
        bname LIKE usr02-bname,
        simu  type flag,
        er    type flag,
      END OF userhas_typ.
TYPES: BEGIN OF rolehas_typ,
        swaudid LIKE /psyng/swaudc-swaudid,
        agr_name type agr_name,
      END OF rolehas_typ.
TYPES : BEGIN OF user_tcode_typ ,
          bname TYPE xubname,
          von TYPE xuvalue,
          bis TYPE xuvalue,
        END OF user_tcode_typ.
*--global variables
FIELD-SYMBOLS : <g_swaudc> TYPE /psyng/swaudc2.
DATA : g_vrsio TYPE /psyng/sodvrsio,
       g_nr_users_analyzed TYPE i,
       gf_details TYPE flag,
       gf_validuser TYPE flag,
       gf_usrbf3_loaded TYPE flag, "this flag is set if usrbf3 is loaded
                                   "for all users in gt_unique_users
       gf_usrbf2_loaded type flag, "this flag is set if usrbf2 is loaded
                                   "for all users in gt_unique_users
       gt_swaudc TYPE TABLE OF /psyng/swaudc2,
       gt_usr02 TYPE TABLE OF usr02,
       gt_unique_usr02 TYPE TABLE OF usr02,
       gt_uinfo TYPE STANDARD TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       gt_usgrpt TYPE STANDARD TABLE OF usgrpt
                 WITH HEADER LINE,
       gt_swaudhdr TYPE STANDARD TABLE OF /psyng/swaudhdr
                   WITH HEADER LINE,
       gt_kostl_resp TYPE STANDARD TABLE OF /psyng/sw_kostl_resp
                     WITH HEADER LINE,
       gt_usrefus TYPE STANDARD TABLE OF usrefus WITH HEADER LINE,
       gt_swaudid_auth TYPE HASHED TABLE OF typ_swaudid_auth
       WITH UNIQUE KEY swaudid auth object tcode
       with header line,
       gt_user_auth TYPE sorted  TABLE OF /psyng/userauth
       WITH non-UNIQUE KEY objct auth bname ,
       gt_output TYPE SORTED TABLE OF /psyng/output WITH UNIQUE KEY
       bname swaudid ,"enhanced,
       gt_outputdet TYPE TABLE OF /psyng/sw_ca_outputdet
       ,
       gt_tcdaut TYPE STANDARD TABLE OF /psyng/psswtcdaut
       WITH HEADER LINE,
       gt_userhas_obj TYPE HASHED TABLE OF userhas_obj_typ
       WITH UNIQUE KEY
        swaudid bname tcode objct ,
       gt_rolehas_obj TYPE HASHED TABLE OF rolehas_obj_typ
       WITH UNIQUE KEY
        swaudid agr_name tcode objct ,
       tcdaut_idx LIKE sy-tabix,
       iuserauth_idx LIKE sy-tabix,
       iusertcode_idx LIKE sy-tabix,
       gt_usrbf3 TYPE HASHED TABLE OF usrbf3 WITH UNIQUE KEY bname,
       gt_usrbf2 TYPE sorted TABLE OF usrbf2
       with unique key bname objct auth,
       gt_refusers type hashed table of usrefus
       with unique key bname,

       gt_ust12_buffer type sorted table of ust12
       with non-unique key  objct auth.
DATA: gt_userhas TYPE HASHED TABLE OF userhas_typ WITH UNIQUE KEY
        swaudid bname
        WITH HEADER LINE.
DATA: gt_rolehas TYPE HASHED TABLE OF rolehas_typ WITH UNIQUE KEY
        swaudid agr_name
        WITH HEADER LINE.
DATA: usertcode TYPE STANDARD TABLE OF /psyng/usertcode
      WITH HEADER LINE.

DATA: BEGIN OF gt_usertcode OCCURS 0,
        tcode LIKE usertcode-tcode,
        bname LIKE usertcode-bname,
        simu  type flag,
        er    type flag,
      END OF gt_usertcode.

.
DATA: gt_iduser TYPE STANDARD TABLE OF /psyng/sw_iduser_fm
      WITH HEADER LINE.
data : gt_tcodes_enh type table of /PSYNG/SW_PAR_TCODE_OUTPUT,
      gf_enhanced type flag.
*--Global variables for role based auths can
data : gt_roles TYPE TABLE OF agr_define WITH HEADER LINE,
       gt_childroles TYPE TABLE OF agr_agrs WITH HEADER LINE.
DATA: roleauth TYPE HASHED TABLE OF typ_roleauth WITH UNIQUE KEY
               objct auth agr_name  field von bis" child_agr
               WITH HEADER LINE.
DATA: roletcode TYPE SORTED TABLE OF typ_roletcode WITH UNIQUE KEY
                agr_name tcode child_agr rfcdest
                WITH HEADER LINE.
data : gt_ROUTPUT   TYPE TABLE OF /PSYNG/SW_CA_ROUTPUT WITH HEADER LINE,
      gt_ROUTPUTDET TYPE TABLE OF /PSYNG/SW_CA_ROUTPUTDET WITH HEADER
LINE.
*--Declared globally but only used locally
DATA: subrc TYPE sy-subrc,
      idx1 LIKE sy-tabix,
      idx2 LIKE sy-tabix,
      idx3 LIKE sy-tabix,
      length LIKE sy-tabix,
      next_agr_name LIKE agr_define-agr_name, "to calculate idx2
      next_profn LIKE ust10s-profn.           "to calculate idx2
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
DATA: et_agrs TYPE STANDARD TABLE OF agr_agrs WITH HEADER LINE.
DATA: et_1016 TYPE STANDARD TABLE OF agr_1016 WITH HEADER LINE.
DATA: et_1251 TYPE STANDARD TABLE OF agr_1251 WITH HEADER LINE.
DATA: et_1252 TYPE STANDARD TABLE OF agr_1252 WITH HEADER LINE.
DATA: et_ust10s TYPE STANDARD TABLE OF ust10s WITH HEADER LINE.

*--configuration data
DATA: swconfig TYPE /psyng/swconfig,
      dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y'.


*--paralell processing data
DATA: done(4) VALUE 'DONE',
      functioncall_1(4),           "getting user information
      functioncall_2(4),           "identical users
      idcl_task(9) VALUE 'IDCL_USER'.
*-- data for auths_with_spec_vals
TYPES : BEGIN OF typ_obj_field,
          object TYPE xuobject,
          field TYPE xufield,
        END OF typ_obj_field.
DATA : gt_objs TYPE TABLE OF typ_obj_field,
       gt_ust12 TYPE TABLE OF ust12.
*--data for z_user_auth_for-obj
DATA : gt_ust10s   TYPE sorted TABLE OF ust10s with unique
       key profn auth objct,
       gt_ust10c   TYPE TABLE OF ust10c.

*--Table that contains list of unique auths than
*  any of the analyzed users have
data : gt_unique_userauths type hashed table of USRBF2
       with unique key auth.
DATA : gt_er_roles type table of agr_users with header line,
       gf_er_or_simu type flag.

*--Global vars for fm sw_114
DATA : gt_return TYPE TABLE OF bapiret2 WITH HEADER LINE.
DATA : gt_fm_output TYPE TABLE OF /psyng/sw_ca_routput
        WITH HEADER LINE,
        g_running_tasks type i,
        gt_fm_outputdet TYPE TABLE OF /psyng/sw_ca_routputdet
        with header line.
