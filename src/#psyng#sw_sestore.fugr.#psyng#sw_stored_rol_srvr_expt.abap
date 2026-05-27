FUNCTION /PSYNG/SW_STORED_ROL_SRVR_EXPT.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_ALL) TYPE  FLAG
*"     REFERENCE(I_RSWC) TYPE  FLAG
*"     REFERENCE(I_AID) TYPE  /PSYNG/SERESID
*"     REFERENCE(I_COMP) TYPE  FLAG
*"     REFERENCE(I_SING) TYPE  FLAG
*"     REFERENCE(I_ASSR) TYPE  FLAG
*"     REFERENCE(I_MITCON) TYPE  FLAG
*"     REFERENCE(I_FUN) TYPE  FLAG
*"     REFERENCE(I_ORGVAR) TYPE  FLAG
*"     REFERENCE(I_RSWOC) TYPE  FLAG
*"     REFERENCE(I_EXPORT) TYPE  FLAG DEFAULT 'X'
*"     REFERENCE(I_ROLES_COUNT) TYPE  I
*"     REFERENCE(I_SERVER_PATH) TYPE  CHAR200
*"  TABLES
*"      I_ROLE STRUCTURE  /PSYNG/RANGE_AGR_NAME
*"      I_RBA STRUCTURE  /PSYNG/RANGE_BUSAREA_ROLE
*"      I_CONID STRUCTURE  /PSYNG/RANGE_CONID
*"      I_RNUM STRUCTURE  /PSYNG/RANGE_CONFNUM
*"      I_RMNUM STRUCTURE  /PSYNG/RANGE_CONFNUM
*"----------------------------------------------------------------------

  TYPES : ttree_item LIKE STANDARD TABLE OF mtreeitm WITH DEFAULT KEY,
        tsodorgm   LIKE STANDARD TABLE OF /psyng/swsodorgm
          WITH DEFAULT KEY INITIAL SIZE 0.

  TYPES: BEGIN OF ty_swrrscon,
         roleindex TYPE /psyng/seres_roleindex,
         conindex  TYPE /psyng/seres_conindex,
       END OF ty_swrrscon.

  DATA : lt_role TYPE TABLE OF /psyng/swrrsrol WITH HEADER LINE,
        l_num_actual_con  TYPE i,
        l_aid             TYPE char10,
        lt_range_roles TYPE TABLE OF /psyng/range_agr_name,
        ls_hdr            TYPE /psyng/swrrshdr,
        l_desc            TYPE string,
        lt_conflict  TYPE TABLE OF /psyng/swrrsicon WITH HEADER LINE,
        l_head            TYPE string,
        lt_node           TYPE treev_ntab,
        lt_confun        TYPE TABLE OF /psyng/swrrscfun WITH HEADER
LINE,
        l_summary_del TYPE flag,
        lt_item           TYPE ttree_item,
        lt_sysinfo   TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_roles_info TYPE TABLE OF /psyng/comp_role_tcode,
        ls_hdr2            TYPE /psyng/swrrshdr,
        lt_rolecon       TYPE TABLE OF /psyng/swrrscon WITH HEADER LINE,
        ls_range_roles TYPE /psyng/range_agr_name,
        lt_roles_alv     TYPE TABLE OF /psyng/swrrsrol WITH HEADER LINE,
        l_role_count     TYPE i,
        lt_authdet       TYPE TABLE OF /psyng/serrs_authdetail
                         WITH HEADER LINE,
        lt_function      TYPE TABLE OF /psyng/swrrsifun WITH HEADER
        LINE,
        l_numcon_part     TYPE i,
        l_file_count       TYPE i,
  lf_cancel_export TYPE flag.

  DATA: BEGIN OF lt_output_alv OCCURS 0,
        agr_name  TYPE agr_define-agr_name,
        conid     TYPE /psyng/conflict-conid,
        confnum  TYPE /psyng/nr_conflicts,
        mitinum  TYPE /psyng/nr_conflicts,
        mitigated TYPE flag,
        funid     TYPE /psyng/faobj2-funid,
        childrole TYPE agr_define-agr_name,
        sysid     TYPE /psyng/sw_rfcdes-systid,
        tcode     TYPE /psyng/faobj2-tcode,
        auth      TYPE /psyng/serrs_authdetail-auth,
        object    TYPE /psyng/faobj2-object,
        field     TYPE /psyng/faobj2-field,
        von       TYPE /psyng/serrs_authdetail-von,
        bis       TYPE /psyng/serrs_authdetail-bis,
        abb       TYPE /psyng/serrs_authdetail-abb,
      END OF lt_output_alv,
      l_alv_count LIKE sy-tabix.

  RANGES : lr_roles FOR lt_role-roleindex,
           lr_conflicts FOR lt_conflict-conindex,
           lr_funindex  FOR /psyng/swrrscfun-funindex,
           lr_roleindex_all FOR /psyng/swrrscon-roleindex,
           lr_roleindex_part FOR /psyng/swrrscon-roleindex,
           lr_roleindex FOR /psyng/swrrscon-roleindex.

  FIELD-SYMBOLS: <swrrsrole> TYPE /psyng/swrrsrol,
                 <confun>    TYPE /psyng/swrrscfun.

  lr_roles-sign     = 'I'. lr_roles-option     = 'EQ'.
  lr_conflicts-sign = 'I'. lr_conflicts-option = 'EQ'.
  ls_range_roles-sign = 'I'. ls_range_roles-option = 'EQ'.

*--role filteration with or without conflicts
  IF i_all = 'X'.
    SELECT * FROM /psyng/swrrsrol INTO TABLE lt_role
       WHERE aid = i_aid AND
             agr_name    IN i_role AND
             nr_conflicts IN i_rnum AND
             nr_mitigated IN i_rmnum.
  ELSEIF i_rswc = 'X'.
    IF i_rnum IS NOT INITIAL
OR i_rmnum IS NOT INITIAL.
      SELECT * FROM /psyng/swrrsrol INTO TABLE lt_role
               WHERE aid = i_aid AND
                     agr_name    IN i_role AND
                     nr_conflicts IN i_rnum AND
                     nr_mitigated IN i_rmnum.
    ELSE.
      SELECT * FROM /psyng/swrrsrol INTO TABLE lt_role
               WHERE aid = i_aid AND
                     agr_name    IN i_role AND
                     nr_conflicts > 0 .
    ENDIF.
  ELSE.
    SELECT * FROM /psyng/swrrsrol INTO TABLE lt_role
             WHERE aid = i_aid AND
                   agr_name IN i_role.
    "nr_conflicts = 0.
    LOOP AT lt_role.
      l_num_actual_con = lt_role-nr_conflicts - lt_role-nr_mitigated.
      IF l_num_actual_con > 0.
        DELETE lt_role.
      ENDIF.
    ENDLOOP.
    IF lt_role[] IS INITIAL.
      SELECT SINGLE COUNT(*) FROM /psyng/swrrsrol INTO l_numcon_part
              WHERE aid = i_aid AND
                   nr_conflicts = 0.
*      IF l_numcon_part = 0.
*        l_aid = i_aid.
*        SHIFT l_aid LEFT DELETING LEADING '0'.
*        MESSAGE s002 WITH
*       'Roles without conflict are not stored'(x12)
*       'in the analysis'(x13)
*        l_aid.
*        LEAVE LIST-PROCESSING.
*      ENDIF.
    ENDIF.
  ENDIF.

*--preparing role and roleindex range
  LOOP AT lt_role.
    lr_roles-low = lt_role-roleindex.
    APPEND lr_roles.
    ls_range_roles-low = lt_role-agr_name.
    APPEND ls_range_roles TO lt_range_roles.
  ENDLOOP.

*--Result ID header
  SELECT SINGLE * FROM /psyng/swrrshdr INTO ls_hdr
        WHERE aid = i_aid.
  ls_hdr2 = ls_hdr.

*--Get system & rfc destination for which analysis was done
  SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sysinfo
  WHERE systid = ls_hdr2-sysid.

*--Filter roles based on single roles/ comp roles/ assigned roles
  READ TABLE lt_sysinfo INDEX 1.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
  CALL FUNCTION '/PSYNG/SW_GET_ROLES'
  DESTINATION lt_sysinfo-rfcdest
  EXPORTING
    i_composite_roles = i_comp
    i_single_roles    = i_sing
    i_assigned_roles  = i_assr
    i_get_actual_data = 'X'
  TABLES
    it_roles          = lt_range_roles
    it_ba             = i_rba
    et_roles          = lt_roles_info
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
 IF sy-subrc <> 0.
    CASE sy-subrc.
       WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
       WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
     ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

  SORT lt_roles_info BY agr_name.
  LOOP AT lt_role.
    READ TABLE lt_roles_info WITH KEY agr_name = lt_role-agr_name
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE lt_role  WHERE agr_name = lt_role-agr_name.
      DELETE lr_roles WHERE low = lt_role-roleindex.
    ENDIF.
  ENDLOOP.

*--Conflicts
  SELECT * FROM /psyng/swrrsicon INTO TABLE lt_conflict
         WHERE aid   =   i_aid AND
               conid IN  i_conid.
  LOOP AT lt_conflict.
    lr_conflicts-low = lt_conflict-conindex.
    APPEND lr_conflicts.
  ENDLOOP.
  IF lr_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
    lr_conflicts-sign   = 'E'.
    lr_conflicts-option = 'GT'.
    lr_conflicts-low    = '0'.
    APPEND lr_conflicts.
  ENDIF.

  IF NOT i_conid[] IS INITIAL AND i_rswc = 'X'.
*--Filter by conflicts was used, remove roles that don't have any of
*    these conflicts
   DATA : lt_rrscon TYPE HASHED TABLE OF /psyng/swrrscon WITH UNIQUE KEY
                                                            roleindex.
    SELECT DISTINCT roleindex FROM /psyng/swrrscon
      INTO CORRESPONDING FIELDS OF TABLE lt_rrscon
       WHERE
        aid       =   i_aid AND
        roleindex IN  lr_roles AND
        conindex  IN  lr_conflicts.
    LOOP AT lr_roles.
      READ TABLE lt_rrscon WITH TABLE KEY roleindex = lr_roles-low
      TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE lt_role  WHERE roleindex = lr_roles-low.
        DELETE lr_roles WHERE low = lr_roles-low.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--if include mitigated conflicts is not selected,
**--remove roles that don't have any of unmitigated conflict
**--Also remove conflicts; if not present in any role
  IF i_mitcon IS INITIAL.
    DATA : lt_rrscon_rol TYPE SORTED TABLE OF ty_swrrscon
           WITH NON-UNIQUE KEY roleindex,
           lt_rrscon_tmp TYPE SORTED TABLE OF ty_swrrscon
           WITH NON-UNIQUE KEY conindex.
    IF NOT i_conid[] IS INITIAL.
      SELECT roleindex conindex FROM /psyng/swrrscon
        INTO TABLE lt_rrscon_rol
         WHERE
          aid       =   i_aid AND
          roleindex IN  lr_roles AND
          conindex  IN lr_conflicts AND
          mitigated = i_mitcon.
    ELSE.
      SELECT roleindex conindex FROM /psyng/swrrscon
        INTO TABLE lt_rrscon_rol
         WHERE
          aid       =   i_aid AND
          roleindex IN  lr_roles AND
          mitigated = i_mitcon.
    ENDIF.
    IF i_rswc EQ 'X'.
      LOOP AT lr_roles.
        READ TABLE lt_rrscon_rol WITH TABLE KEY roleindex = lr_roles-low
        TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE lt_role WHERE roleindex = lr_roles-low.
          DELETE lr_roles WHERE low = lr_roles-low.
        ENDIF.
      ENDLOOP.
    ENDIF.
    lt_rrscon_tmp = lt_rrscon_rol.
    LOOP AT lt_conflict.
      READ TABLE lt_rrscon_tmp WITH TABLE KEY conindex =
      lt_conflict-conindex TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE lt_conflict WHERE conindex = lt_conflict-conindex.
        DELETE lr_conflicts WHERE low = lt_conflict-conindex.
      ENDIF.
    ENDLOOP.
    IF lr_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
      lr_conflicts-sign   = 'E'.
      lr_conflicts-option = 'GT'.
      lr_conflicts-low    = '0'.
      APPEND lr_conflicts.
    ENDIF.
  ENDIF.

  lt_roles_alv[] = lt_role[].
*---Warning if nr of roles > 50
  DESCRIBE TABLE lt_roles_alv LINES l_role_count.

*---collect role index
  LOOP AT lt_roles_alv ASSIGNING <swrrsrole>.
    lr_roleindex-sign = 'I'.
    lr_roleindex-option = 'EQ'.
    lr_roleindex-low = <swrrsrole>-roleindex.
    APPEND lr_roleindex.
  ENDLOOP.

*-- get role conflict
  IF NOT lr_roleindex[] IS INITIAL.
    lr_roleindex_all[] = lr_roleindex[].
    WHILE NOT lr_roleindex[] IS INITIAL.
      APPEND LINES OF lr_roleindex FROM 1 TO 5000
      TO lr_roleindex_part.
      DELETE lr_roleindex FROM 1 TO 5000.
      IF i_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrrscon APPENDING TABLE lt_rolecon
                   WHERE aid       =  i_aid AND
                         roleindex IN lr_roleindex_part AND
                         conindex  IN lr_conflicts.
      ELSE.
        SELECT * FROM /psyng/swrrscon APPENDING TABLE lt_rolecon
                   WHERE aid       =  i_aid AND
                         roleindex IN lr_roleindex_part AND
                         conindex  IN lr_conflicts
                     AND mitigated = i_mitcon.
      ENDIF.
      REFRESH : lr_roleindex_part[].
    ENDWHILE.
    lr_roleindex[] = lr_roleindex_all[].
  ENDIF.
  FREE : lr_roleindex_part, lr_roleindex_all.

*--Role's Conflict functions
  IF NOT lt_rolecon[] IS INITIAL.
    SELECT * FROM /psyng/swrrscfun  INTO TABLE lt_confun
    FOR ALL ENTRIES IN lt_rolecon
             WHERE aid       =  i_aid AND
                   conindex  = lt_rolecon-conindex.
    IF NOT lt_confun[] IS INITIAL.
      SELECT  * FROM /psyng/swrrsifun INTO TABLE lt_function
      FOR ALL ENTRIES IN lt_confun
           WHERE aid      = i_aid AND
                 funindex = lt_confun-funindex.
    ENDIF.
  ENDIF.
  LOOP AT lt_confun ASSIGNING <confun>.
    lr_funindex-sign = 'I'.
    lr_funindex-option = 'EQ'.
    lr_funindex-low = <confun>-funindex.
    APPEND lr_funindex.
  ENDLOOP.

*---Macro to get only uniq record when org/var option not selected
  DEFINE export_only_uniq_value.
    check i_orgvar <> 'X'.

    if i_fun = 'X'.
  read table lt_output_alv with key agr_name = &1"lt_users_alv-bname
                                       conid = &2"gt_conflict-conid
                                       funid = &3."lt_function-funid.
      if sy-subrc = 0.
        clear lt_output_alv.
      else.
        add 1 to l_alv_count.
        append lt_output_alv.
      endif.

    endif.
  END-OF-DEFINITION.

*    SORT lt_usrprof BY sys userindex profileindex.
  LOOP AT lt_confun.
    CLEAR lt_output_alv.
*      LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
    LOOP AT lt_rolecon WHERE conindex = lt_confun-conindex.
*          READ TABLE lt_usrprof WITH KEY
*            sys          = lt_funprofile-sys
*            userindex    = lt_usercon-userindex
*            profileindex = lt_funprofile-profileindex
*            BINARY SEARCH.
*          CHECK sy-subrc = 0.
* userid
      READ TABLE lt_roles_alv WITH KEY roleindex = lt_rolecon-roleindex.
      IF sy-subrc = 0.
        lt_output_alv-agr_name = lt_roles_alv-agr_name.
        lt_output_alv-confnum = lt_roles_alv-nr_conflicts.
        lt_output_alv-mitinum = lt_roles_alv-nr_mitigated.
      ENDIF.
* Conflicts
      READ TABLE lt_conflict WITH KEY conindex = lt_confun-conindex.
      IF sy-subrc = 0.
        lt_output_alv-conid = lt_conflict-conid.
        lt_output_alv-mitigated = lt_rolecon-mitigated.
      ENDIF.
* function
      READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
      IF sy-subrc = 0.
        lt_output_alv-funid = lt_function-funid.
      ENDIF.

*          IF p_fun <> 'X'.
* profiles
*            READ TABLE lt_profiles WITH KEY
*                          profindex = lt_usrprof-profileindex.
*            IF sy-subrc = 0.
*              gt_output_alv-profname = lt_profiles-profname.
*            ENDIF.

** Role
*            READ TABLE lt_profrole WITH KEY
*                       profindex = lt_usrprof-profileindex.
*            IF sy-subrc = 0.
*              READ TABLE lt_roles WITH KEY
*                roleindex = lt_profrole-roleindex.
*              gt_output_alv-agr_name = lt_roles-agr_name.
** Composite Role
*              READ TABLE lt_comprole WITH KEY
*                userindex = lt_usercon-userindex
*                roleindex = lt_profrole-roleindex.
*              IF sy-subrc = 0.
*                READ TABLE lt_roles WITH KEY
*                  roleindex  = lt_comprole-compindex.
*                IF sy-subrc = 0.
*                  gt_output_alv-comp_agr = lt_roles-agr_name.
*                ENDIF.
*              ELSE.
*                CLEAR gt_output_alv-comp_agr.
*              ENDIF.
*          LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
*                             AND  roleindex = lt_profrole-roleindex.
*                READ TABLE lt_roles WITH KEY
*             roleindex  = lt_comprole-compindex.
*                IF sy-subrc = 0.
*                  gt_output_alv-comp_agr = lt_roles-agr_name.
*                ENDIF.
*        READ TABLE gt_output_alv WITH KEY  bname = lt_users_alv-bname
*                                            conid = gt_conflict-conid
*                                            funid = lt_function-funid
*                                    comp_agr = gt_output_alv-comp_agr
*                                    agr_name = gt_output_alv-agr_name
*                                   profname = gt_output_alv-profname.
*                IF sy-subrc <> 0.
*                  APPEND gt_output_alv.
*                  ADD 1 TO g_alv_count.
*                ENDIF.
*              ENDLOOP.
*              CLEAR: gt_output_alv-comp_agr.
*            ENDIF.
*            IF  p_rolpro = 'X'.
*           export_only_uniq_value lt_users_alv-bname gt_conflict-conid
*       lt_function-funid  gt_output_alv-agr_name lt_profiles-profname.
*            ENDIF.
*          ENDIF.

*--- call macro only if org/var expand o/p option not selected
      IF i_fun = 'X'.
        export_only_uniq_value lt_roles_alv-agr_name
         lt_conflict-conid lt_function-funid.
      ENDIF.

* ---- don't go for detail if expand level not selected org/var
      IF i_orgvar = 'X'.
        REFRESH : lt_authdet.
        CALL FUNCTION '/PSYNG/SW_SE_ROL_EXPAND_CAUT'
          EXPORTING
            i_aid          = i_aid
*             i_sys          = lt_usrprof-sys
            i_funindex     = lt_confun-funindex
            i_roleindex    = lt_rolecon-roleindex
          TABLES
            et_roledetails = lt_authdet.

        LOOP AT lt_authdet.
          MOVE-CORRESPONDING lt_authdet TO lt_output_alv.
          ADD 1 TO l_alv_count.
          APPEND lt_output_alv.
          IF l_alv_count = i_roles_count.
            SORT lt_output_alv.
            PERFORM create_role_file_on_server USING lt_output_alv[]
                                                i_server_path
                                                i_roles_count
                                                i_aid
                                          CHANGING l_file_count.
            FREE lt_output_alv.
            CLEAR l_alv_count.
          ENDIF.

        ENDLOOP.
      ENDIF.
      FREE : lt_authdet.
    ENDLOOP.
  ENDLOOP.

*--free some memory
  FREE :     lt_roles_alv,
*               lt_funprof ,
*               lt_usrprof ,
*               lt_usrprof2,
*               lt_profrole,
*               lt_roles,
*               lt_childrole,
*               lt_child,
*               lt_profiles ,
             lt_authdet ,
*               lt_authdet_all ,
*               lt_funprofile ,
             lt_confun,
             lt_function,
             lt_rolecon.

* Check if any records left to be transfered on server, create file o
*  app server.
  IF NOT lt_output_alv[] IS INITIAL.
*---sort and delete duplicates records
    SORT lt_output_alv.
    DELETE ADJACENT DUPLICATES FROM lt_output_alv COMPARING
    ALL FIELDS.
* create files at Appliucation server path
    PERFORM create_role_file_on_server USING lt_output_alv[]
                                        i_server_path
                                        i_roles_count
                                        i_aid
                                  CHANGING l_file_count.
  ENDIF.
  MESSAGE s002(/psyng/sw) WITH 'Total files transfered:'(i08)
                                                         l_file_count.


ENDFUNCTION.
