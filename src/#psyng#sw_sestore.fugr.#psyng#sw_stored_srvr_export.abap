FUNCTION /psyng/sw_stored_srvr_export.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     REFERENCE(I_AID) TYPE  /PSYNG/SERESID
*"     REFERENCE(I_LOCAL) TYPE  FLAG
*"     REFERENCE(I_REMOTE) TYPE  FLAG
*"     REFERENCE(I_CROSS) TYPE  FLAG
*"     REFERENCE(I_MITCON) TYPE  FLAG
*"     REFERENCE(I_FUN) TYPE  FLAG
*"     REFERENCE(I_ROLPRO) TYPE  FLAG
*"     REFERENCE(I_ORGVAR) TYPE  FLAG
*"     REFERENCE(I_ALL) TYPE  FLAG
*"     REFERENCE(I_USWC) TYPE  FLAG
*"     REFERENCE(I_SERVER_PATH) TYPE  CHAR200
*"     REFERENCE(I_USERS_COUNT) TYPE  I
*"     REFERENCE(I_EXPORT) TYPE  FLAG DEFAULT 'X'
*"  TABLES
*"      I_BNAME STRUCTURE  /PSYNG/RANGE_BNAME
*"      I_CLASS STRUCTURE  /PSYNG/RANGE_CLASS
*"      I_KOSTL STRUCTURE  /PSYNG/RANGE_XUKOSTL
*"      I_COMP STRUCTURE  /PSYNG/RANGE_COMPANY
*"      I_DEP STRUCTURE  /PSYNG/RANGE_DEPARTMENT
*"      I_UNUM STRUCTURE  /PSYNG/RANGE_CONFNUM
*"      I_UMNUM STRUCTURE  /PSYNG/RANGE_CONFNUM
*"      I_USRTYP STRUCTURE  /PSYNG/RANGE_USTYP
*"      I_CONID STRUCTURE  /PSYNG/RANGE_CONID
*"----------------------------------------------------------------------
  DATA: ls_fun           TYPE mtreeitm,
        ls_connode       TYPE treev_node,
        ls_funnode       TYPE treev_node,
        ls_usernode      TYPE treev_node,
        ls_rolnode       TYPE treev_node,
        l_aid            TYPE char10,
        lt_users_alv     TYPE TABLE OF /psyng/swresusr WITH HEADER LINE,
        ls_items         TYPE mtreeitm,
        lt_funprof       TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
        lt_usrprof       TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_usrprof2      TYPE TABLE OF /psyng/swresupr WITH HEADER LINE,
        lt_profrole      TYPE SORTED TABLE OF /psyng/swresprol
                         WITH HEADER LINE WITH UNIQUE KEY profindex,
        lt_roles         TYPE SORTED TABLE OF /psyng/swresirol
                         WITH HEADER LINE WITH UNIQUE KEY roleindex,
        lt_comprole      TYPE SORTED TABLE OF /psyng/swresucom
                         WITH HEADER LINE WITH NON-UNIQUE KEY roleindex,
        li_comp          LIKE LINE OF lt_comprole,
        ls_role          TYPE /psyng/swresirol,
        li_comprole      TYPE /psyng/swresirol,
        lt_profiles      TYPE TABLE OF /psyng/swresipro WITH HEADER LINE,
        lt_authdet       TYPE TABLE OF /psyng/seres_authdetail
                         WITH HEADER LINE,
        lt_authdet_all   TYPE TABLE OF /psyng/seres_authdetail
                     WITH HEADER LINE,
        ls_function      TYPE /psyng/swresifun,
        l_funindex       TYPE /psyng/seres_funindex,
        l_userinndex     TYPE /psyng/seres_userindex,
        lt_funprofile    TYPE TABLE OF /psyng/swresfpr WITH HEADER LINE,
        lt_confun        TYPE TABLE OF /psyng/swrescfun WITH HEADER LINE,
        lt_function      TYPE TABLE OF /psyng/swresifun WITH HEADER LINE,
        lt_usercon       TYPE TABLE OF /psyng/swrescon WITH HEADER LINE,
        l_continue       TYPE flag,
        l_user_count     TYPE i,
        g_alv_count      TYPE sy-tabix,
        l_num_actual_con TYPE /psyng/nr_conflicts,
        l_numcon_part    TYPE i,
        it_conflict      TYPE TABLE OF /psyng/swresicon WITH HEADER LINE.
  DATA: lv_filename(200)    TYPE c,
        lf_line(750)        TYPE c,
        lc_hiphen           TYPE c VALUE '_',
        lv_counter          TYPE i,
        lv_total_count      TYPE i,
        lv_file_count       TYPE i VALUE 0,
        lv_file_seq         TYPE string,
        lv_file_open(1)     TYPE c,
        lv_server_path(200) TYPE c,
        lv_users_analyzed   TYPE i,
        gv_file_count       TYPE i.
  RANGES: ir_conflicts FOR /psyng/swresicon-conindex.

  DATA: BEGIN OF et_output_records OCCURS 0,
*        aid      TYPE /psyng/swreshdr-aid,
          bname     TYPE /psyng/swreshdr-bname,
          conid     TYPE /psyng/conflict-conid,
          confnum   TYPE /psyng/nr_conflicts,
          mitinum   TYPE /psyng/nr_conflicts,
          mitigated TYPE flag,
          funid     TYPE /psyng/faobj2-funid,
          comp_agr  TYPE agr_define-agr_name,
          agr_name  TYPE agr_define-agr_name,
          profname  TYPE agr_prof-profile,
          sysid     TYPE /psyng/sw_rfcdes-systid,
          tcode     TYPE /psyng/faobj2-tcode,
          auth      TYPE /psyng/seres_authdetail-auth,
          object    TYPE /psyng/faobj2-object,
          field     TYPE /psyng/faobj2-field,
          von       TYPE /psyng/seres_authdetail-von,
          bis       TYPE /psyng/seres_authdetail-bis,
          abb       TYPE /psyng/seres_authdetail-abb,
          origin    TYPE c LENGTH 12, "B16609 for C0633
        END OF et_output_records.

  FIELD-SYMBOLS: <swresusr> TYPE /psyng/swresusr,
                 <confun>   TYPE /psyng/swrescfun.
  RANGES: lr_userindex FOR /psyng/swrescon-userindex,
          lr_userindex_all FOR /psyng/swrescon-userindex,
          lr_userindex_part FOR /psyng/swrescon-userindex,
          lr_funindex  FOR /psyng/swrescfun-funindex,
          lr_profindex FOR /psyng/swresupr-profileindex,
          lr_sys       FOR /psyng/swresupr-sys.

  RANGES :
  lr_users      FOR lt_users_alv-userindex,
  lr_users_part FOR lt_users_alv-userindex,
  lr_users_all  FOR lt_users_alv-userindex,
  r_bname       FOR usr02-bname,
  lr_usertype   FOR /psyng/swresusr-ustyp.
  TYPES: BEGIN OF ty_swrescon,
           userindex TYPE /psyng/seres_userindex,
           conindex  TYPE /psyng/seres_conindex,
         END OF ty_swrescon.

  lr_users-sign     = 'I'. lr_users-option     = 'EQ'.
  ir_conflicts-sign = 'I'. ir_conflicts-option = 'EQ'.

*--users
  IF i_all = 'X'.
    SELECT * FROM /psyng/swresusr INTO TABLE lt_users_alv
             WHERE aid = i_aid AND
                   bname       IN i_bname AND
                   class       IN i_class AND
                   kostl       IN i_kostl AND
                   company     IN i_comp AND
                   department  IN i_dep AND
                   nr_conflicts IN i_unum AND
                   nr_mitigated IN i_umnum AND
                   ustyp        IN i_usrtyp.
  ELSEIF i_uswc = 'X'.
    IF i_unum IS NOT INITIAL
    OR i_umnum IS NOT INITIAL.
      SELECT * FROM /psyng/swresusr INTO TABLE lt_users_alv
               WHERE aid = i_aid AND
                     bname       IN i_bname AND
                     class       IN i_class AND
                     kostl       IN i_kostl AND
                     company     IN i_comp AND
                     department  IN i_dep  AND
                     nr_conflicts IN i_unum AND
                     nr_mitigated IN i_umnum AND
                     ustyp        IN i_usrtyp.
    ELSE.
      SELECT * FROM /psyng/swresusr INTO TABLE lt_users_alv
               WHERE aid = i_aid AND
                     bname       IN i_bname AND
                     class       IN i_class AND
                     kostl       IN i_kostl AND
                     company     IN i_comp AND
                     department  IN i_dep  AND
                     ustyp        IN i_usrtyp AND
                     nr_conflicts > 0 .
    ENDIF.
  ELSE.
    SELECT * FROM /psyng/swresusr INTO TABLE lt_users_alv
             WHERE aid = i_aid AND
                   bname       IN i_bname AND
                   class       IN i_class AND
                   kostl       IN i_kostl AND
                   company     IN i_comp AND
                   department  IN i_dep  AND
                   ustyp        IN i_usrtyp.
*                   nr_conflicts = 0.
    LOOP AT lt_users_alv.
      l_num_actual_con = lt_users_alv-nr_conflicts - lt_users_alv-nr_mitigated.
      IF l_num_actual_con > 0.
        DELETE lt_users_alv.
      ENDIF.
    ENDLOOP.
    IF lt_users_alv[] IS INITIAL.
      SELECT SINGLE COUNT(*) FROM /psyng/swresusr INTO l_numcon_part
              WHERE aid = i_aid AND
                   nr_conflicts = 0.
*      IF l_numcon_part = 0.
*        l_aid = i_aid.
*        SHIFT l_aid LEFT DELETING LEADING '0'.
*        MESSAGE s002 WITH
*       'Users without conflict are not stored'(x12)
*       'in the analysis'(x13)
*       l_aid.
*        LEAVE LIST-PROCESSING.
*      ENDIF.
    ENDIF.
  ENDIF.
  LOOP AT lt_users_alv.
    lr_users-low = lt_users_alv-userindex.
    APPEND lr_users.
  ENDLOOP.
*--Conflicts
  SELECT * FROM /psyng/swresicon INTO TABLE it_conflict
           WHERE aid   =   i_aid AND
                 conid IN  i_conid.
  LOOP AT it_conflict.
    ir_conflicts-low = it_conflict-conindex.
    APPEND ir_conflicts.
  ENDLOOP.
  IF ir_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
    ir_conflicts-sign   = 'E'.
    ir_conflicts-option = 'GT'.
    ir_conflicts-low    = '0'.
    APPEND ir_conflicts.
  ENDIF.

  IF NOT i_conid[] IS INITIAL AND i_uswc = 'X'.
*--Filter by conflicts was used, remove users that don't have any of these conflicts
    DATA : lt_rescon        TYPE HASHED TABLE OF /psyng/swrescon WITH UNIQUE KEY userindex,
           lt_rescon_nosort TYPE TABLE OF /psyng/swrescon.
    lr_users_all[] = lr_users[].
    REFRESH : lt_rescon.
    WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
      REFRESH : lr_users_part , lt_rescon_nosort.
      APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
      DELETE lr_users_all FROM 1 TO 5000.
      SELECT DISTINCT userindex FROM /psyng/swrescon
        INTO CORRESPONDING FIELDS OF TABLE lt_rescon_nosort
         WHERE
          aid       =   i_aid AND
          userindex IN  lr_users_part AND
          conindex  IN  ir_conflicts.
      INSERT LINES OF lt_rescon_nosort INTO TABLE lt_rescon.
    ENDWHILE.
    FREE : lr_users_part ,lr_users_all.
    LOOP AT lr_users.
      READ TABLE lt_rescon WITH TABLE KEY userindex = lr_users-low TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE lt_users_alv WHERE userindex = lr_users-low.
        DELETE lr_users WHERE low = lr_users-low.
      ENDIF.
    ENDLOOP.
  ENDIF.

*--If include mitigated conflicts is not selected,
**--remove users that don't have any of unmitigated conflict
**--Also remove conflicts; if not present in any user
  IF i_mitcon IS INITIAL.
    DATA : lt_rescon_usr        TYPE SORTED TABLE OF ty_swrescon
           WITH NON-UNIQUE KEY userindex,
           lt_rescon_usr_nosort TYPE TABLE OF ty_swrescon.
    DATA  lt_rescon_tmp TYPE SORTED TABLE OF ty_swrescon
          WITH NON-UNIQUE KEY conindex.
    IF NOT i_conid[] IS INITIAL.
      lr_users_all[] = lr_users[].

      WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
        REFRESH : lr_users_part , lt_rescon_usr_nosort.
        APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
        DELETE lr_users_all FROM 1 TO 5000.
        SELECT userindex conindex FROM /psyng/swrescon
          INTO TABLE lt_rescon_usr_nosort
           WHERE
            aid       =   i_aid AND
            userindex IN  lr_users_part AND
            conindex  IN ir_conflicts AND
            mitigated = i_mitcon.
        INSERT LINES OF lt_rescon_usr_nosort INTO TABLE lt_rescon_usr.
      ENDWHILE.
      FREE : lr_users_part ,lr_users_all, lt_rescon_usr_nosort.

    ELSE.
* BOC by RGUPTA for C0583 on 10th Jan, 2022
      lr_users_all[] = lr_users[].

      WHILE NOT lr_users_all[] IS INITIAL.
*  --Load rescon per 5k users to prevent DBSQL_STMNT_TOO_LARGE
        REFRESH : lr_users_part , lt_rescon_usr_nosort.
        APPEND LINES OF lr_users_all FROM 1 TO 5000 TO lr_users_part .
        DELETE lr_users_all FROM 1 TO 5000.
* EOC by RGUPTA for C0583 on 10th Jan, 2022
        SELECT userindex conindex FROM /psyng/swrescon
          INTO TABLE lt_rescon_usr_nosort "lt_rescon_usr  by RGUPTA
           WHERE
            aid       =   i_aid AND
            userindex IN  lr_users_part AND "lr_users AND by RGUPTA
            mitigated = i_mitcon.
* BOC by RGUPTA for C0583 on 10th Jan, 2022
        INSERT LINES OF lt_rescon_usr_nosort INTO TABLE lt_rescon_usr.
      ENDWHILE.
      FREE : lr_users_part ,lr_users_all, lt_rescon_usr_nosort.
* EOC by RGUPTA for C0583 on 10th Jan, 2022
    ENDIF.
    IF i_uswc EQ 'X'.
      LOOP AT lr_users.
        READ TABLE lt_rescon_usr WITH TABLE KEY userindex = lr_users-low TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          DELETE lt_users_alv WHERE userindex = lr_users-low.
          DELETE lr_users WHERE low = lr_users-low.
        ENDIF.
      ENDLOOP.
    ENDIF.
    lt_rescon_tmp = lt_rescon_usr.
    LOOP AT it_conflict.
      READ TABLE lt_rescon_tmp WITH TABLE KEY conindex = it_conflict-conindex TRANSPORTING NO FIELDS.
      IF sy-subrc <> 0.
        DELETE it_conflict WHERE conindex = it_conflict-conindex.
        DELETE ir_conflicts WHERE low = it_conflict-conindex.
      ENDIF.
    ENDLOOP.
    IF ir_conflicts[] IS INITIAL.
*--No conflicts match the selection screen
      ir_conflicts-sign   = 'E'.
      ir_conflicts-option = 'GT'.
      ir_conflicts-low    = '0'.
      APPEND ir_conflicts.
    ENDIF.
  ENDIF.



*---Warning if nr of users > 50
  DESCRIBE TABLE lt_users_alv LINES l_user_count.
*---collect user index
  LOOP AT lt_users_alv ASSIGNING <swresusr>.
    lr_userindex-sign = 'I'.
    lr_userindex-option = 'EQ'.
    lr_userindex-low = <swresusr>-userindex.
    APPEND lr_userindex.
  ENDLOOP.
*-- get user conflict
  IF NOT lr_userindex[] IS INITIAL.
    lr_userindex_all[] = lr_userindex[].
    WHILE NOT lr_userindex[] IS INITIAL.
      APPEND LINES OF lr_userindex FROM 1 TO 5000
      TO lr_userindex_part.
      DELETE lr_userindex FROM 1 TO 5000.
      IF i_mitcon EQ 'X'.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       =  i_aid AND
                         userindex IN lr_userindex_part AND
                         conindex  IN ir_conflicts.
      ELSE.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       =  i_aid AND
                         userindex IN lr_userindex_part AND
                         conindex  IN ir_conflicts AND
                         mitigated = i_mitcon.
      ENDIF.
      REFRESH : lr_userindex_part[].
    ENDWHILE.
    lr_userindex[] = lr_userindex_all[].
  ENDIF.
  FREE : lr_userindex_part, lr_userindex_all.

*--User's Conflict functions
  IF NOT lt_usercon[] IS INITIAL.
    SELECT * FROM /psyng/swrescfun  INTO TABLE lt_confun
    FOR ALL ENTRIES IN lt_usercon
             WHERE aid       =  i_aid AND
                   conindex  = lt_usercon-conindex.
    IF NOT lt_confun[] IS INITIAL.
      SELECT  * FROM /psyng/swresifun INTO TABLE lt_function
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

*--Approach with multiple selects, optimize use of indexes
*--Get all profiles user has
  SELECT * FROM /psyng/swresupr
  INTO CORRESPONDING FIELDS OF TABLE lt_usrprof
  WHERE aid          = i_aid AND
        userindex    IN lr_userindex.
*--For these profiles,
*  get the ones that relate to the functions we care about
  lr_profindex-sign   = 'I'.
  lr_profindex-option = 'EQ'.
  MOVE-CORRESPONDING lr_profindex TO lr_sys.
  LOOP AT lt_usrprof.
    lr_profindex-low = lt_usrprof-profileindex.
    APPEND lr_profindex.
    lr_sys-low = lt_usrprof-sys.
    APPEND lr_sys.
  ENDLOOP.
  SORT lr_profindex BY low.
  SORT lr_sys BY low.
  DELETE ADJACENT DUPLICATES FROM  lr_profindex COMPARING low.
  DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.

  SELECT * FROM /psyng/swresfpr
  INTO TABLE lt_funprofile
  WHERE
    aid = i_aid AND
    sys IN lr_sys AND
*      funindex IN lr_funindex AND
    profileindex IN lr_profindex.

  SORT lt_funprofile BY sys profileindex.
  LOOP AT lt_usrprof.
    READ TABLE lt_funprofile WITH KEY
      sys           = lt_usrprof-sys
      profileindex  = lt_usrprof-profileindex
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      APPEND lt_usrprof TO lt_usrprof2.
    ENDIF.
  ENDLOOP.
  lt_usrprof[] =   lt_usrprof2[].
  FREE lt_usrprof2[].
**--Get the roles
  IF NOT lt_usrprof[] IS INITIAL.

    SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles
      FOR ALL ENTRIES IN
        lt_usrprof
    WHERE aid       = i_aid AND
*              sys       = lt_usrprof-sys and
          profindex = lt_usrprof-profileindex.

    SELECT * FROM /psyng/swresprol
    INTO TABLE lt_profrole
    FOR ALL ENTRIES IN lt_usrprof
    WHERE aid       = i_aid AND
          sys       = lt_usrprof-sys AND
          profindex = lt_usrprof-profileindex.
    IF NOT lt_profrole[] IS INITIAL.
      SELECT * FROM /psyng/swresirol
      INTO TABLE lt_roles
      FOR ALL ENTRIES IN lt_profrole
        WHERE aid = i_aid AND
              roleindex = lt_profrole-roleindex.
      IF NOT lt_roles[] IS INITIAL.
*--Get any composite role through which these roles may be assigned
        SELECT * FROM /psyng/swresucom
        INTO TABLE lt_comprole
        FOR ALL ENTRIES IN lt_roles WHERE
          aid = i_aid AND
*            userindex = l_userinndex AND
          userindex IN lr_userindex AND
          roleindex = lt_roles-roleindex.
* BOC by RGUPTA on 25.07.22 for #22227
        IF lt_comprole[] IS NOT INITIAL.
          DELETE lt_comprole[] WHERE compindex IS INITIAL
                                  OR compindex EQ 0.
        ENDIF.
* EOC by RGUPTA on 25.07.22 for #22227
        IF NOT lt_comprole[] IS INITIAL.
          SELECT * FROM /psyng/swresirol
          APPENDING TABLE lt_roles
          FOR ALL ENTRIES IN lt_comprole
            WHERE aid = i_aid AND
                  roleindex = lt_comprole-compindex.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDIF.

*---Macro to get only uniq record when org/var option not selected
  DEFINE export_only_uniq_value.
    check i_orgvar <> 'X'.

    if i_fun = 'X'.
     read table et_output_records with key  bname = &1 "lt_users_alv-bname
                                          conid = &2"it_conflict-conid
                                        funid = &3."lt_function-funid.
      if sy-subrc = 0.
        clear et_output_records.
      else.
        add 1 to g_alv_count.
        append et_output_records.
      endif.

    endif.

    if i_rolpro  = 'X'.
     read table et_output_records with key  bname = &1 "lt_users_alv-bname
                                          conid = &2"it_conflict-conid
                                         funid = &3"lt_function-funid.
                                            agr_name = &4
                                            profname = &5.
      if sy-subrc = 0.
        clear et_output_records.
      else.
        add 1 to g_alv_count.
        append et_output_records.
        clear et_output_records. "Changes by RGUPTA on 30th Nov,2021
      endif.
    endif.
  END-OF-DEFINITION.


  SORT lt_usrprof BY sys userindex profileindex.
  LOOP AT lt_confun.
    CLEAR et_output_records.
    LOOP AT lt_funprofile WHERE funindex = lt_confun-funindex.
      LOOP AT lt_usercon WHERE conindex = lt_confun-conindex.
* BOC for B16609 for C0633
        IF lt_usercon-origin IS NOT INITIAL.
          IF i_local = 'X' AND i_remote IS INITIAL
           AND i_cross IS INITIAL
           AND ( lt_usercon-origin = 2 OR lt_usercon-origin = 3
              OR lt_usercon-origin = 5 ).
            CONTINUE.
          ELSEIF i_local = 'X' AND i_remote = 'X'
           AND i_cross IS INITIAL
           AND lt_usercon-origin = 3.
            CONTINUE.
          ELSEIF i_local = 'X' AND i_remote IS INITIAL
           AND i_cross = 'X'
           AND lt_usercon-origin = 2.
            CONTINUE.
          ELSEIF i_local IS INITIAL AND i_remote = 'X'
           AND i_cross IS INITIAL
           AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 3
              OR lt_usercon-origin = 4 ).
            CONTINUE.
          ELSEIF i_local IS INITIAL AND i_remote = 'X'
           AND i_cross = 'X'
           AND lt_usercon-origin = 1.
            CONTINUE.
          ELSEIF i_local IS INITIAL AND i_remote IS INITIAL
           AND i_cross = 'X'
           AND ( lt_usercon-origin = 1 OR lt_usercon-origin = 2 ).
            CONTINUE.
          ENDIF.
        ENDIF.
* EOC for B16609 for C0633
        READ TABLE lt_usrprof WITH KEY
          sys          = lt_funprofile-sys
          userindex    = lt_usercon-userindex
          profileindex = lt_funprofile-profileindex
          BINARY SEARCH.
        CHECK sy-subrc = 0.
* userid
        READ TABLE lt_users_alv WITH KEY userindex = lt_usercon-userindex.
        IF sy-subrc = 0.
          et_output_records-bname = lt_users_alv-bname.
          et_output_records-confnum = lt_users_alv-nr_conflicts.
          et_output_records-mitinum = lt_users_alv-nr_mitigated.
        ENDIF.
* Conflicts
        READ TABLE it_conflict WITH KEY conindex = lt_confun-conindex.
        IF sy-subrc = 0.
          et_output_records-conid = it_conflict-conid.
          et_output_records-mitigated = lt_usercon-mitigated.
* BOC for B16609 for C0633
          CASE lt_usercon-origin.
            WHEN 1.
              et_output_records-origin = 'Local'(173).
            WHEN 2.
              et_output_records-origin = 'Remote'(174).
            WHEN 3.
              et_output_records-origin = 'Cross'(175).
            WHEN 4.
              et_output_records-origin = 'Local&Cross'(202).
            WHEN 5.
              et_output_records-origin = 'Remote&Cross'(203).
            WHEN 6.
              et_output_records-origin = 'L&R&C'(204).
          ENDCASE.
* EOC for B16609 for C0633
        ENDIF.
* function
        READ TABLE lt_function WITH KEY funindex = lt_confun-funindex.
        IF sy-subrc = 0.
          et_output_records-funid = lt_function-funid.
        ENDIF.

        IF i_fun <> 'X'.
* profiles
          READ TABLE lt_profiles WITH KEY
                        profindex = lt_usrprof-profileindex.
          IF sy-subrc = 0.
            et_output_records-profname = lt_profiles-profname.
          ENDIF.

** Role
          READ TABLE lt_profrole WITH KEY
                     profindex = lt_usrprof-profileindex.
          IF sy-subrc = 0.
            READ TABLE lt_roles WITH KEY
              roleindex = lt_profrole-roleindex.
            et_output_records-agr_name = lt_roles-agr_name.

            LOOP AT lt_comprole WHERE userindex = lt_usercon-userindex
                                             AND  roleindex = lt_profrole-roleindex.
              READ TABLE lt_roles WITH KEY
           roleindex  = lt_comprole-compindex.
              IF sy-subrc = 0.
                et_output_records-comp_agr = lt_roles-agr_name.
              ENDIF.
              READ TABLE et_output_records WITH KEY  bname = lt_users_alv-bname
                                                  conid = it_conflict-conid
                                                  funid = lt_function-funid
                                          comp_agr = et_output_records-comp_agr
                                          agr_name = et_output_records-agr_name
                                         profname = et_output_records-profname.
              IF sy-subrc <> 0.
                APPEND et_output_records.
                ADD 1 TO g_alv_count.
* BOC by GSINGH for C0765
* Create file on server if the records stored in the table matches with the batch size
                IF g_alv_count = i_users_count.
                  SORT et_output_records.
                  PERFORM create_file_on_server TABLES et_output_records
                      USING i_server_path i_users_count i_aid
                            CHANGING gv_file_count.
                  FREE et_output_records.
                  CLEAR g_alv_count.
                ENDIF.
* EOC by GSINGH for C0765
              ENDIF.
            ENDLOOP.
            CLEAR: et_output_records-comp_agr.
          ENDIF.
          IF  i_rolpro = 'X'.
            export_only_uniq_value lt_users_alv-bname it_conflict-conid
        lt_function-funid  et_output_records-agr_name lt_profiles-profname.
          ENDIF.
        ENDIF.

*--- call macro only if org/var expand o/p option not selected
        IF i_fun = 'X'.
          export_only_uniq_value lt_users_alv-bname it_conflict-conid
                            lt_function-funid  '' ''.
        ENDIF.

* ---- don't go for detail if expand level not selected org/var
        IF i_orgvar = 'X'.
          REFRESH : lt_authdet.
          CALL FUNCTION '/PSYNG/SW_SESTORE_EXPAND_CAUT'
            EXPORTING
              i_aid             = i_aid
              i_sys             = lt_usrprof-sys
              i_funindex        = lt_confun-funindex
              i_profileindex    = lt_usrprof-profileindex
            TABLES
              et_profiledetails = lt_authdet.

          LOOP AT lt_authdet.
            MOVE-CORRESPONDING lt_authdet TO et_output_records.
            ADD 1 TO g_alv_count.
            APPEND et_output_records.
* BOC by GSINGH for C0765
* Create file on server if the records stored in the table matches with the batch size
            IF g_alv_count = i_users_count.
              SORT et_output_records.
              PERFORM create_file_on_server TABLES et_output_records
                  USING i_server_path i_users_count i_aid
                  CHANGING gv_file_count.
              FREE et_output_records.
              CLEAR g_alv_count.
            ENDIF.
* EOC by GSINGH for C0765
          ENDLOOP.
          CLEAR et_output_records. "RGUPTA
        ENDIF.
        FREE : lt_authdet.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.
*--free some memory
  FREE :     lt_users_alv,
             lt_funprof ,
             lt_usrprof ,
             lt_usrprof2,
             lt_profrole,
             lt_roles   ,
             lt_comprole,
             lt_profiles ,
             lt_authdet  ,
             lt_authdet_all ,
             lt_funprofile ,
             lt_confun   ,
             lt_function,
             lt_usercon  .
* Check if any records left to be transfered on server, create file o app server.
  IF NOT et_output_records[] IS INITIAL.
*---sort and delete duplicates records
    SORT et_output_records.
    DELETE ADJACENT DUPLICATES FROM et_output_records COMPARING
    ALL FIELDS.
* create files at Appliucation server path
    PERFORM create_file_on_server TABLES et_output_records
                USING i_server_path i_users_count i_aid
                      CHANGING gv_file_count.
  ENDIF.
  MESSAGE s002(/psyng/sw) WITH 'Total files transfered:'(i08) gv_file_count.
ENDFUNCTION.
