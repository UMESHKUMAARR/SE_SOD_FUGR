FUNCTION-POOL /psyng/sw_api_imp.            "MESSAGE-ID ..

INCLUDE /psyng/sw_config.

TYPES: BEGIN OF ty_users,
         aid          TYPE /psyng/seresid,
         userindex    TYPE /psyng/seres_userindex,
         bname        TYPE xubname,
         nr_conflicts TYPE /psyng/nr_conflicts,
         department   TYPE text40,
         class        TYPE xuclass,
         nr_mitigated TYPE /psyng/nr_conflicts,
       END OF ty_users,

       BEGIN OF ty_conhead,
         conid TYPE /psyng/conflict_id,
         vrsio TYPE /psyng/sodvrsio,
         imp   TYPE /psyng/importance,
       END OF ty_conhead.

TYPES: BEGIN OF ty_authdet_cache_key,
         aid          TYPE /psyng/seresid,
         sys          TYPE /psyng/swresfpr-sys,
         funindex     TYPE /psyng/swresfpr-funindex,
         profileindex TYPE /psyng/swresfpr-profileindex,
         cache_index  TYPE i,
       END OF ty_authdet_cache_key.

TYPES: BEGIN OF ty_authdet_flat,
         cache_index  TYPE i,
         sys          TYPE /psyng/swresfpr-sys,
         funindex     TYPE /psyng/swresfpr-funindex,
         profileindex TYPE /psyng/swresfpr-profileindex,
         tcode        TYPE /psyng/seres_authdetail-tcode,
         auth         TYPE /psyng/seres_authdetail-auth,
         object       TYPE /psyng/seres_authdetail-object,
         field        TYPE /psyng/seres_authdetail-field,
         von          TYPE /psyng/seres_authdetail-von,
         bis          TYPE /psyng/seres_authdetail-bis,
         abb          TYPE /psyng/seres_authdetail-abb,
         funid        TYPE /psyng/seres_authdetail-funid,
         profname     TYPE /psyng/seres_authdetail-profname,
       END OF ty_authdet_flat.

TYPES: BEGIN OF ty_outputdet_ext,
         bname      TYPE xubname,
         conid      TYPE /psyng/conflict_id,
         origin     TYPE /psyng/conflict_origin,
         sysid      TYPE /psyng/sysid,
         mitigated  TYPE flag,
         confnum    TYPE /psyng/nr_conflicts,
         mitinum    TYPE /psyng/nr_conflicts,
         funid      TYPE /psyng/function_id,
         tcode      TYPE tcode,
         object     TYPE xuobject,
         field      TYPE xufield,
         von        TYPE xuval,
         bis        TYPE xuval,
         abb        TYPE /psyng/dorg_abb,
         profname   TYPE xuprofile,
         agr_name   TYPE agr_name,
         comp_agr   TYPE agr_name,
         class      TYPE xuclass,
         deprtmnt   TYPE text40,
         auth       TYPE xuauth,
         origin_txt TYPE char20,
       END OF ty_outputdet_ext.

TYPES: BEGIN OF ty_caut_flat,
         sys          TYPE /psyng/swresfpr-sys,
         funindex     TYPE /psyng/swresfpr-funindex,
         profileindex TYPE /psyng/swresfpr-profileindex,
         tcode        TYPE /psyng/seres_authdetail-tcode,
         object       TYPE /psyng/seres_authdetail-object,
         field        TYPE /psyng/seres_authdetail-field,
         von          TYPE /psyng/seres_authdetail-von,
         bis          TYPE /psyng/seres_authdetail-bis,
         abb          TYPE /psyng/seres_authdetail-abb,
         auth         TYPE /psyng/seres_authdetail-auth,
         funid        TYPE /psyng/seres_authdetail-funid,
         profname     TYPE /psyng/seres_authdetail-profname,
         sysid        TYPE /psyng/swresisys-sysid,
       END OF ty_caut_flat.

TYPES: ty_tt_authdetail    TYPE STANDARD TABLE OF
       /psyng/seres_authdetail.
TYPES: ty_tt_outputdet_ext TYPE TABLE OF ty_outputdet_ext.

TYPES:
  ty_th_users    TYPE HASHED TABLE OF ty_users
                 WITH UNIQUE KEY aid userindex,

* Phase 6: SORTED TABLE used to maintain order.
* F02 still uses backward walk after READ TABLE to safely reach first
*row of a non-unique key block.
  ty_tt_usercon  TYPE SORTED TABLE OF /psyng/swrescon
               WITH NON-UNIQUE KEY userindex conindex,

  ty_tt_confun   TYPE SORTED TABLE OF /psyng/swrescfun
                 WITH NON-UNIQUE KEY conindex,

  ty_th_conflict TYPE HASHED TABLE OF /psyng/swresicon
                 WITH UNIQUE KEY aid conindex,

  ty_th_function TYPE HASHED TABLE OF /psyng/swresifun
                 WITH UNIQUE KEY aid funindex,

  ty_th_profiles TYPE HASHED TABLE OF /psyng/swresipro
                 WITH UNIQUE KEY aid profindex,

  ty_tt_fprprof  TYPE SORTED TABLE OF /psyng/swresfpr
                 WITH NON-UNIQUE KEY
                 userindex funindex sys profileindex,

  ty_tt_usrprof  TYPE TABLE OF /psyng/swresupr,

  ty_ts_profrole TYPE SORTED TABLE OF /psyng/swresprol
                 WITH UNIQUE KEY profindex,

  ty_ts_roles    TYPE SORTED TABLE OF /psyng/swresirol
                 WITH UNIQUE KEY roleindex,

  ty_ts_comprole TYPE SORTED TABLE OF /psyng/swresucom
                 WITH NON-UNIQUE KEY roleindex,

  ty_r_userindex TYPE RANGE OF /psyng/swrescon-userindex,
  ty_r_funindex  TYPE RANGE OF /psyng/swrescfun-funindex,
  ty_r_profindex TYPE RANGE OF /psyng/swresupr-profileindex,
  ty_r_sys       TYPE RANGE OF /psyng/swresupr-sys.

TYPES: ty_th_sysmap TYPE HASHED TABLE OF /psyng/swresisys
                    WITH UNIQUE KEY sysindex.

DATA: g_start TYPE /psyng/dec11,
      g_stop  TYPE /psyng/dec11.

DATA: gt_routput_sum TYPE TABLE OF /psyng/sw_out_routput.

DEFINE log.
  &1-type    = &2.
  &1-id      = &3.
  concatenate &4 &5 &6 &7 into &1-message separated by space.
  append &1.
END-OF-DEFINITION.

DEFINE log_v.
  &1-type    = &2.
  &1-id      = &3.
  concatenate &4 &5 &6 into &1-message separated by space.
  &1-message_v1 = &7.
  &1-message_v2 = &8.
  append &1.
END-OF-DEFINITION.
