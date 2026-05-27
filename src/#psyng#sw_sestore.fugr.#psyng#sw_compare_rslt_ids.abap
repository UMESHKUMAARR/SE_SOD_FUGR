FUNCTION /psyng/sw_compare_rslt_ids.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(I_LATEST_AID) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(I_PRE_AID) TYPE  /PSYNG/SERESID OPTIONAL
*"     VALUE(I_VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_VRSIO_PRE) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(IF_USER_VIEW) TYPE  FLAG OPTIONAL
*"     VALUE(IF_EX_MISSING_USERS) TYPE  FLAG OPTIONAL
*"     VALUE(I_ROLE_LATEST_AID) TYPE  /PSYNG/SERRSID OPTIONAL
*"     VALUE(I_ROLE_PRE_AID) TYPE  /PSYNG/SERRSID OPTIONAL
*"     VALUE(IF_ROLE) TYPE  FLAG OPTIONAL
*"     VALUE(IF_ROLE_VIEW) TYPE  FLAG OPTIONAL
*"     VALUE(I_CON_ROLE_DET) TYPE  FLAG OPTIONAL
*"     VALUE(I_ROLE_CON_DET) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      ET_DETAIL STRUCTURE  /PSYNG/SW_KPI_NEW_CONFLICTS OPTIONAL
*"      ET_DETAIL_USER_VIEW STRUCTURE  /PSYNG/SW_USRVIEW_NEW_REM_CONF
*"       OPTIONAL
*"      ET_DETAIL_ROLE_VIEW STRUCTURE  /PSYNG/SW_ROLVIEW_NEW_REM_CONF
*"       OPTIONAL
*"      ET_DETAIL_USRCON_VIEW STRUCTURE  /PSYNG/SW_BOTVIEW_NEW_REM_CONF
*"       OPTIONAL
*"      ET_NEWCONFLICT_USERS STRUCTURE  /PSYNG/SW_SOD_DET_ANA OPTIONAL
*"      ET_REMCONFLICT_USERS STRUCTURE  /PSYNG/SW_SOD_DET_ANA OPTIONAL
*"      ET_NEWCONFLICT_ROLES STRUCTURE  /PSYNG/SW_SOD_DET_ANA OPTIONAL
*"      ET_REMCONFLICT_ROLES STRUCTURE  /PSYNG/SW_SOD_DET_ANA OPTIONAL
*"      ET_CON_NEW_REM_ROLE STRUCTURE  /PSYNG/SW_KPI_CON_NEW_REM_ROLE
*"       OPTIONAL
*"      ET_ROLE_NEW_REM_CON STRUCTURE  /PSYNG/SW_KPI_ROLE_NEW_REM_CON
*"       OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_COMPARE_RSLT_IDS'.
*  S_RFC AUTHORITY CHECK
* BOC BNAYAK CVA scan fix DT:05-05-2026
*  AUTHORITY-CHECK OBJECT 'S_RFC'
  AUTHORITY-CHECK OBJECT 'Y&CO_RFC'
* EOC BNAYAK CVA scan fix DT:05-05-2026
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026

  CONSTANTS gc_con_identified TYPE char10 VALUE 'Identified'.
  DATA :
    lt_confdet        TYPE TABLE OF /psyng/conflict,
    ls_confdet        TYPE /psyng/conflict,
    lr_aid            TYPE RANGE OF /psyng/seresid,
    lsr_aid           LIKE LINE OF lr_aid,
    ls_detail         TYPE /psyng/sw_kpi_new_conflicts,
    lt_user           TYPE SORTED TABLE OF /psyng/swresusr
                      WITH UNIQUE KEY aid bname,
    lt_user_byindex   TYPE SORTED TABLE OF /psyng/swresusr
                      WITH UNIQUE KEY aid userindex,
    ls_user           TYPE /psyng/swresusr,
    ls_user_tmp       TYPE /psyng/swresusr,
    lt_role           TYPE SORTED TABLE OF /psyng/swrrsrol
                      WITH UNIQUE KEY aid agr_name,
    lt_role_byindex   TYPE SORTED TABLE OF /psyng/swrrsrol
                      WITH UNIQUE KEY aid roleindex,
    ls_role           TYPE /psyng/swrrsrol,
    ls_role_tmp       TYPE /psyng/swrrsrol,
    lt_usercon        TYPE SORTED TABLE OF /psyng/swrescon
                      WITH NON-UNIQUE KEY aid conindex userindex,
    lt_usercon_t      TYPE SORTED TABLE OF /psyng/swrescon
                      WITH NON-UNIQUE KEY aid conindex userindex,
    ls_usercon        TYPE /psyng/swrescon,
    ls_usercon_tmp    TYPE /psyng/swrescon,
    lt_rolecon        TYPE SORTED TABLE OF /psyng/swrrscon
                      WITH NON-UNIQUE KEY aid conindex roleindex,
    lt_rolecon_t      TYPE SORTED TABLE OF /psyng/swrrscon
                      WITH NON-UNIQUE KEY aid conindex roleindex,
    ls_rolecon        TYPE /psyng/swrrscon,
    ls_rolecon_tmp    TYPE /psyng/swrrscon,
    lt_conflicts      TYPE TABLE OF /psyng/swresicon,
    ls_conflict       TYPE /psyng/swresicon,
    ls_conflict_tmp   TYPE /psyng/swresicon,
    lt_conflicts_role TYPE TABLE OF /psyng/swrrsicon,
    ls_conflict_role  TYPE /psyng/swrrsicon,
    ls_conflict_role_t TYPE /psyng/swrrsicon,
    l_index           TYPE sy-tabix,
    lf_add_conflict   TYPE flag,
    l_latest_aid      TYPE /psyng/seresid,
    l_pre_aid         TYPE /psyng/seresid,
    ls_usrcon_view      TYPE /psyng/sw_botview_new_rem_conf.


  DATA: lt_user_group TYPE TABLE OF usgrpt,
        ls_user_group TYPE usgrpt.
  FIELD-SYMBOLS: <fs_detail_user_view>
                 TYPE /psyng/sw_usrview_new_rem_conf.

  RANGES: lr_userindex FOR /psyng/swrescon-userindex,
          lr_userindex_all FOR /psyng/swrescon-userindex,
          lr_userindex_part FOR /psyng/swrescon-userindex,

          lr_roleindex FOR /psyng/swrrscon-roleindex,
          lr_roleindex_all FOR /psyng/swrrscon-roleindex,
          lr_roleindex_part FOR /psyng/swrrscon-roleindex,
          lr_conid FOR /psyng/conflict-conid,
          lr_role FOR /psyng/swrrsrol-agr_name.

  DATA: lf_end TYPE flag,
        lv_counter_n TYPE i,
        lv_counter_r TYPE i.


  IF if_role IS INITIAL.
    l_latest_aid = i_latest_aid.
    l_pre_aid    = i_pre_aid.
*--Create AID Range
    lsr_aid-sign   = 'I'.
    lsr_aid-option = 'EQ'.
    IF NOT l_latest_aid IS INITIAL.
      lsr_aid-low = l_latest_aid.
      APPEND lsr_aid TO lr_aid.
    ENDIF.
    IF NOT l_pre_aid IS INITIAL.
      lsr_aid-low = l_pre_aid.
      APPEND lsr_aid TO lr_aid.
    ENDIF.
    CHECK NOT lr_aid IS INITIAL.
**--Get users for both IDs
    SELECT * FROM /psyng/swresusr INTO TABLE lt_user
             WHERE aid IN lr_aid.
    lt_user_byindex = lt_user.
**---collect user index
    LOOP AT lt_user INTO ls_user.
      lr_userindex-sign = 'I'.
      lr_userindex-option = 'EQ'.
      lr_userindex-low = ls_user-userindex.
      APPEND lr_userindex.
    ENDLOOP.
*-- get user conflict
    IF NOT lr_userindex[] IS INITIAL.
      SORT lr_userindex BY low.
      DELETE ADJACENT DUPLICATES FROM lr_userindex COMPARING low.
      lr_userindex_all[] = lr_userindex[].
      WHILE NOT lr_userindex[] IS INITIAL.
        APPEND LINES OF lr_userindex FROM 1 TO 5000
        TO lr_userindex_part.
        DELETE lr_userindex FROM 1 TO 5000.
        SELECT * FROM /psyng/swrescon APPENDING TABLE lt_usercon
                   WHERE aid       IN lr_aid AND
                         userindex IN lr_userindex_part
                     AND mitigated = ''.
        REFRESH : lr_userindex_part[].
      ENDWHILE.
      lr_userindex[] = lr_userindex_all[].
    ENDIF.
    FREE : lr_userindex_part, lr_userindex_all.
    lt_usercon_t = lt_usercon.

    DELETE ADJACENT DUPLICATES FROM lt_usercon_t COMPARING aid conindex.
    IF NOT lt_usercon_t IS INITIAL.
      SELECT * FROM /psyng/swresicon
        INTO TABLE lt_conflicts
        FOR ALL ENTRIES IN lt_usercon_t
        WHERE aid EQ lt_usercon_t-aid
          AND conindex EQ lt_usercon_t-conindex
          AND conid IN it_conid.
    ENDIF.
    FREE lt_usercon_t.
    IF NOT lt_conflicts IS INITIAL.
      SELECT * FROM /psyng/conflict
        INTO TABLE lt_confdet
        FOR ALL ENTRIES IN lt_conflicts
        WHERE conid EQ lt_conflicts-conid
          AND ( vrsio EQ i_vrsio
           OR   vrsio EQ i_vrsio_pre ).
    ENDIF.
    DELETE ADJACENT DUPLICATES FROM lt_confdet COMPARING conid.
    LOOP AT lt_confdet INTO ls_confdet.
      MOVE-CORRESPONDING ls_confdet TO ls_detail.
      ls_detail-sensitivity = ls_confdet-imp.
      LOOP AT lt_conflicts INTO ls_conflict
        WHERE conid EQ ls_confdet-conid.
*For latest aid
        IF ls_conflict-aid EQ l_latest_aid.
          READ TABLE lt_usercon INTO ls_usercon
            WITH KEY aid = l_latest_aid
                     conindex = ls_conflict-conindex
                     BINARY SEARCH.
          IF sy-subrc EQ 0.
            l_index = sy-tabix.
            LOOP AT lt_usercon INTO ls_usercon
              FROM l_index.
              CLEAR lf_add_conflict.
              IF ls_usercon-conindex NE ls_conflict-conindex
              OR ls_usercon-aid      NE l_latest_aid.
                EXIT.
              ENDIF.
*Add total number of users in latest aid having this conflict
              ADD 1 TO ls_detail-conflicts_total.
*Check if this user is present in previous aid
*If yes; then if this user have this conflict in previous aid too
*Otherwise this is new conflict
              IF NOT l_pre_aid IS INITIAL.
*First read user for latest aid
                READ TABLE lt_user_byindex INTO ls_user
                  WITH TABLE KEY aid = l_latest_aid
                                 userindex = ls_usercon-userindex.
                IF sy-subrc EQ 0.
                  ls_usrcon_view-bname = ls_user-bname.
*Read same user for previous aid
                  READ TABLE lt_user INTO ls_user_tmp
                    WITH TABLE KEY aid = l_pre_aid
                             bname = ls_user-bname.
                  IF sy-subrc NE 0.
                    IF NOT if_ex_missing_users IS INITIAL.
                      CONTINUE.
                    ENDIF.
                    lf_add_conflict = 'X'.
                    ls_usrcon_view-pre_aid = 'User Missing'(t01).
                    COLLECT ls_usrcon_view INTO et_detail_usrcon_view.
                    CLEAR ls_usrcon_view.
                  ELSE.
                    ls_usrcon_view-conid   = ls_confdet-conid.
                    ls_usrcon_view-description = ls_confdet-description.
                    ls_usrcon_view-lat_aid = gc_con_identified.
                    ls_usrcon_view-pre_aid = gc_con_identified.
*Read same conflict for this user for previous aid
*--First read conflict index for previous aid
                    READ TABLE lt_conflicts INTO ls_conflict_tmp
                      WITH KEY aid   = l_pre_aid
                               conid = ls_confdet-conid.
                    IF sy-subrc NE 0.
                      lf_add_conflict = 'X'.
                      ls_usrcon_view-pre_aid = 'Missing'(t02).
                    ELSE.
                      READ TABLE lt_usercon INTO ls_usercon_tmp
                        WITH TABLE KEY aid = l_pre_aid
                                 conindex  = ls_conflict_tmp-conindex
                                 userindex = ls_user_tmp-userindex.
                      IF sy-subrc NE 0.
                        lf_add_conflict = 'X'.
                        ls_usrcon_view-pre_aid = 'Missing'(t02).
                      ENDIF.
                    ENDIF.
                  ENDIF.
*-- For those users which are same in both IDs
                  et_detail_user_view-bname     = ls_user-bname.
                  et_detail_user_view-fullname  = ls_user-name_text.
                  et_detail_user_view-usergroup = ls_user-class.
                  COLLECT et_detail_user_view INTO et_detail_user_view.
                  CLEAR et_detail_user_view.
                ENDIF.
              ENDIF.
              IF NOT lf_add_conflict IS INITIAL.
                ADD 1 TO ls_detail-conflicts_new.
                IF et_newconflict_users IS REQUESTED.
                  et_newconflict_users-conid = ls_confdet-conid.
                  et_newconflict_users-bname = ls_user-bname.
                  APPEND et_newconflict_users.
                ENDIF.
              ENDIF.
              IF NOT ls_usrcon_view IS INITIAL.
                COLLECT ls_usrcon_view INTO et_detail_usrcon_view.
                CLEAR ls_usrcon_view.
              ENDIF.
            ENDLOOP.
          ENDIF.
*For previous aid
        ELSEIF ls_conflict-aid EQ l_pre_aid.
          READ TABLE lt_usercon INTO ls_usercon
            WITH KEY aid = l_pre_aid
                     conindex = ls_conflict-conindex
                     BINARY SEARCH.
          IF sy-subrc EQ 0.
            l_index = sy-tabix.
            LOOP AT lt_usercon INTO ls_usercon
              FROM l_index.
              CLEAR lf_add_conflict.
              IF ls_usercon-conindex NE ls_conflict-conindex
              OR ls_usercon-aid      NE l_pre_aid.
                EXIT.
              ENDIF.
*Check if this user is present in latest aid
*If yes; then if this user have this conflict in latest aid too
*Otherwise this is remediated conflict
*First read user for previous aid
              READ TABLE lt_user_byindex INTO ls_user
                WITH TABLE KEY aid = l_pre_aid
                         userindex = ls_usercon-userindex.
              IF sy-subrc EQ 0.
                ls_usrcon_view-bname = ls_user-bname.
*Read same user for latest aid
                READ TABLE lt_user INTO ls_user_tmp
                  WITH TABLE KEY aid = l_latest_aid
                           bname = ls_user-bname.
                IF sy-subrc NE 0.
                  IF NOT if_ex_missing_users IS INITIAL.
                    CONTINUE.
                  ENDIF.
*Add total number of users having this conflict
                  ADD 1 TO ls_detail-conflicts_total.
                  lf_add_conflict = 'X'.
                  ls_usrcon_view-lat_aid = 'User Missing'(t01).
                  COLLECT ls_usrcon_view INTO et_detail_usrcon_view.
                  CLEAR ls_usrcon_view.
                ELSE.
                  ls_usrcon_view-conid   = ls_confdet-conid.
                  ls_usrcon_view-description = ls_confdet-description.
                  ls_usrcon_view-pre_aid = gc_con_identified.
                  ls_usrcon_view-lat_aid = gc_con_identified.

*Read same conflict for this user for latest aid
*--First read conflict index in latest aid
                  READ TABLE lt_conflicts INTO ls_conflict_tmp
                    WITH KEY aid   = l_latest_aid
                             conid = ls_confdet-conid.
                  IF sy-subrc NE 0.
                    ADD 1 TO ls_detail-conflicts_total.
                    lf_add_conflict = 'X'.
                    ls_usrcon_view-lat_aid = 'Missing'(t02).

                  ELSE.
                    READ TABLE lt_usercon INTO ls_usercon_tmp
                      WITH TABLE KEY aid = l_latest_aid
                               conindex  = ls_conflict_tmp-conindex
                               userindex = ls_user_tmp-userindex.
                    IF sy-subrc NE 0.
                      ADD 1 TO ls_detail-conflicts_total.
                      lf_add_conflict = 'X'.
                      ls_usrcon_view-lat_aid = 'Missing'(t02).

                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
              IF NOT lf_add_conflict IS INITIAL.
                ADD 1 TO ls_detail-conflicts_rem.
                IF et_remconflict_users IS REQUESTED.
                  et_remconflict_users-conid = ls_confdet-conid.
                  et_remconflict_users-bname = ls_user-bname.
                  APPEND et_remconflict_users.
                ENDIF.
              ENDIF.
              IF NOT ls_usrcon_view IS INITIAL.
                COLLECT ls_usrcon_view INTO et_detail_usrcon_view.
                CLEAR ls_usrcon_view.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ENDLOOP.
      APPEND ls_detail TO et_detail.
      CLEAR ls_detail.
    ENDLOOP.
    SORT et_detail_usrcon_view.
*--Return ouptut in User View
    IF NOT if_user_view IS INITIAL.
*--First populate the users found in new conflicts
      LOOP AT et_newconflict_users.
        et_detail_user_view-bname = et_newconflict_users-bname.
        ADD 1 TO et_detail_user_view-conflicts_new.
        CLEAR ls_user_tmp.
        READ TABLE lt_user INTO ls_user_tmp
          WITH TABLE KEY aid   = l_latest_aid
                         bname = et_newconflict_users-bname.
        IF sy-subrc EQ 0.
          et_detail_user_view-fullname  = ls_user_tmp-name_text.
          et_detail_user_view-usergroup = ls_user_tmp-class.
        ENDIF.
        COLLECT et_detail_user_view INTO et_detail_user_view.
        CLEAR et_detail_user_view.
      ENDLOOP.
*--Then populate the users found in rem conflicts
      LOOP AT et_remconflict_users.
        et_detail_user_view-bname = et_remconflict_users-bname.
        ADD 1 TO et_detail_user_view-conflicts_rem.
        CLEAR ls_user_tmp.
        READ TABLE lt_user INTO ls_user_tmp
          WITH TABLE KEY aid   = l_pre_aid
                         bname = et_remconflict_users-bname.
        IF sy-subrc EQ 0.
          et_detail_user_view-fullname  = ls_user_tmp-name_text.
          et_detail_user_view-usergroup = ls_user_tmp-class.
        ENDIF.
        COLLECT et_detail_user_view INTO et_detail_user_view.
        CLEAR et_detail_user_view.
      ENDLOOP.
*Fetch User Group description
      IF NOT et_detail_user_view[] IS INITIAL.
        SELECT *
          FROM usgrpt
          INTO TABLE lt_user_group
          FOR ALL ENTRIES IN et_detail_user_view
          WHERE usergroup EQ et_detail_user_view-usergroup
            AND sprsl     EQ sy-langu.
        IF sy-subrc EQ 0.
          SORT lt_user_group BY usergroup.
        ENDIF.
        LOOP AT et_detail_user_view ASSIGNING <fs_detail_user_view>.
          <fs_detail_user_view>-conflicts_total =
          <fs_detail_user_view>-conflicts_new +
          <fs_detail_user_view>-conflicts_rem.
          READ TABLE lt_user_group INTO ls_user_group
            WITH KEY usergroup = <fs_detail_user_view>-usergroup
            BINARY SEARCH.
          IF sy-subrc EQ 0.
            <fs_detail_user_view>-usergroupname = ls_user_group-text.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ELSE.
*Do comparison for role result IDs
    l_latest_aid = i_role_latest_aid.
    l_pre_aid    = i_role_pre_aid.
*--Create AID Range
    lsr_aid-sign   = 'I'.
    lsr_aid-option = 'EQ'.
    IF NOT l_latest_aid IS INITIAL.
      lsr_aid-low = l_latest_aid.
      APPEND lsr_aid TO lr_aid.
    ENDIF.
    IF NOT l_pre_aid IS INITIAL.
      lsr_aid-low = l_pre_aid.
      APPEND lsr_aid TO lr_aid.
    ENDIF.
    CHECK NOT lr_aid IS INITIAL.
**--Get roles for both IDs
    SELECT * FROM /psyng/swrrsrol INTO TABLE lt_role
             WHERE aid IN lr_aid.
    lt_role_byindex = lt_role.
**---collect role index
    LOOP AT lt_role INTO ls_role.
      lr_roleindex-sign = 'I'.
      lr_roleindex-option = 'EQ'.
      lr_roleindex-low = ls_role-roleindex.
      APPEND lr_roleindex.
    ENDLOOP.
*-- get role conflict
    IF NOT lr_roleindex[] IS INITIAL.
      SORT lr_roleindex BY low.
      DELETE ADJACENT DUPLICATES FROM lr_roleindex COMPARING low.
      lr_roleindex_all[] = lr_roleindex[].
      WHILE NOT lr_roleindex[] IS INITIAL.
        APPEND LINES OF lr_roleindex FROM 1 TO 5000
        TO lr_roleindex_part.
        DELETE lr_roleindex FROM 1 TO 5000.
        SELECT * FROM /psyng/swrrscon APPENDING TABLE lt_rolecon
                   WHERE aid       IN lr_aid AND
                         roleindex IN lr_roleindex_part
                     AND mitigated = ''.
        REFRESH : lr_roleindex_part[].
      ENDWHILE.
      lr_roleindex[] = lr_roleindex_all[].
    ENDIF.
    FREE : lr_roleindex_part, lr_roleindex_all.
    lt_rolecon_t = lt_rolecon.
    DELETE ADJACENT DUPLICATES FROM lt_rolecon_t COMPARING aid conindex.
    IF NOT lt_rolecon_t IS INITIAL.
      SELECT * FROM /psyng/swrrsicon
        INTO TABLE lt_conflicts_role
        FOR ALL ENTRIES IN lt_rolecon_t
        WHERE aid EQ lt_rolecon_t-aid
          AND conindex EQ lt_rolecon_t-conindex.
    ENDIF.
    FREE lt_rolecon_t.
    IF NOT lt_conflicts_role IS INITIAL.
      SELECT * FROM /psyng/conflict
        INTO TABLE lt_confdet
        FOR ALL ENTRIES IN lt_conflicts_role
        WHERE conid EQ lt_conflicts_role-conid
          AND ( vrsio EQ i_vrsio
           OR   vrsio EQ i_vrsio_pre ).
    ENDIF.
    DELETE ADJACENT DUPLICATES FROM lt_confdet COMPARING conid.
    LOOP AT lt_confdet INTO ls_confdet.
      MOVE-CORRESPONDING ls_confdet TO ls_detail.
      ls_detail-sensitivity = ls_confdet-imp.
      LOOP AT lt_conflicts_role INTO ls_conflict_role
        WHERE conid EQ ls_confdet-conid.
*For latest aid
        IF ls_conflict_role-aid EQ l_latest_aid.
          READ TABLE lt_rolecon INTO ls_rolecon
            WITH KEY aid = l_latest_aid
                     conindex = ls_conflict_role-conindex
                     BINARY SEARCH.
          IF sy-subrc EQ 0.
            l_index = sy-tabix.
            LOOP AT lt_rolecon INTO ls_rolecon
              FROM l_index.
              CLEAR lf_add_conflict.
              IF ls_rolecon-conindex NE ls_conflict_role-conindex
              OR ls_rolecon-aid      NE l_latest_aid.
                EXIT.
              ENDIF.
*Add total number of role in latest aid having this conflict
              ADD 1 TO ls_detail-conflicts_total.
*Check if this role is present in previous aid
*If yes; then if this role have this conflict in previous aid too
*Otherwise this is new conflict
              IF NOT l_pre_aid IS INITIAL.
*First read role for latest aid
                READ TABLE lt_role_byindex INTO ls_role
                  WITH TABLE KEY aid = l_latest_aid
                           roleindex = ls_rolecon-roleindex.
                IF sy-subrc EQ 0.
*Read same role for previous aid
                  READ TABLE lt_role INTO ls_role_tmp
                    WITH TABLE KEY aid = l_pre_aid
                             agr_name = ls_role-agr_name.
                  IF sy-subrc NE 0.
                    lf_add_conflict = 'X'.
                  ELSE.
*Read same conflict for this role for previous aid
*--First read conflict index for previous aid
                    READ TABLE lt_conflicts_role INTO ls_conflict_role_t
                      WITH KEY aid   = l_pre_aid
                               conid = ls_confdet-conid.
                    IF sy-subrc NE 0.
                      lf_add_conflict = 'X'.
                    ELSE.
                      READ TABLE lt_rolecon INTO ls_rolecon_tmp
                        WITH TABLE KEY aid = l_pre_aid
                                conindex  = ls_conflict_role_t-conindex
                                roleindex = ls_role_tmp-roleindex.
                      IF sy-subrc NE 0.
                        lf_add_conflict = 'X'.
                      ENDIF.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
              IF NOT lf_add_conflict IS INITIAL.
                ADD 1 TO ls_detail-conflicts_new.
                IF et_newconflict_roles IS REQUESTED.
                  et_newconflict_roles-conid    = ls_confdet-conid.
                  et_newconflict_roles-agr_name = ls_role-agr_name.
                  APPEND et_newconflict_roles.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
*For previous aid
        ELSEIF ls_conflict_role-aid EQ l_pre_aid.
          READ TABLE lt_rolecon INTO ls_rolecon
            WITH KEY aid = l_pre_aid
                           conindex = ls_conflict_role-conindex
                           BINARY SEARCH.
          IF sy-subrc EQ 0.
            l_index = sy-tabix.
            LOOP AT lt_rolecon INTO ls_rolecon
              FROM l_index.
              CLEAR lf_add_conflict.
              IF ls_rolecon-conindex NE ls_conflict_role-conindex
              OR ls_rolecon-aid      NE l_pre_aid.
                EXIT.
              ENDIF.
*Check if this role is present in latest aid
*If yes; then if this role have this conflict in latest aid too
*Otherwise this is remediated conflict
*First read role for previous aid
              READ TABLE lt_role_byindex INTO ls_role
                WITH TABLE KEY aid = l_pre_aid
                         roleindex = ls_rolecon-roleindex.
              IF sy-subrc EQ 0.
*Read same role for latest aid
                READ TABLE lt_role INTO ls_role_tmp
                  WITH TABLE KEY aid = l_latest_aid
                           agr_name = ls_role-agr_name.
                IF sy-subrc NE 0.
*Add total number of roles having this conflict
                  ADD 1 TO ls_detail-conflicts_total.
                  lf_add_conflict = 'X'.
                ELSE.
*Read same conflict for this role for latest aid
*--First read conflict index for latest aid
                  READ TABLE lt_conflicts_role INTO ls_conflict_role_t
                    WITH KEY aid   = l_latest_aid
                             conid = ls_confdet-conid.
                  IF sy-subrc NE 0.
                    ADD 1 TO ls_detail-conflicts_total.

                    lf_add_conflict = 'X'.
                  ELSE.
                    READ TABLE lt_rolecon INTO ls_rolecon_tmp
                      WITH TABLE KEY aid = l_latest_aid

                               conindex  = ls_conflict_role_t-conindex
                               roleindex = ls_role_tmp-roleindex.
                    IF sy-subrc NE 0.
                      ADD 1 TO ls_detail-conflicts_total.

                      lf_add_conflict = 'X'.
                    ENDIF.
                  ENDIF.
                ENDIF.
              ENDIF.
              IF NOT lf_add_conflict IS INITIAL.
                ADD 1 TO ls_detail-conflicts_rem.
                IF et_remconflict_roles IS REQUESTED.
                  et_remconflict_roles-conid = ls_confdet-conid.
                  et_remconflict_roles-agr_name = ls_role-agr_name.
                  APPEND et_remconflict_roles.
                ENDIF.
              ENDIF.
            ENDLOOP.
          ENDIF.
        ENDIF.
      ENDLOOP.
      APPEND ls_detail TO et_detail.
      CLEAR ls_detail.
    ENDLOOP.

*Begin of Addition AKUMAR 06.11.2025 PN16239
    SORT et_con_new_rem_role BY conid role_new role_rem.
    SORT et_detail BY conid.
    SORT et_role_new_rem_con BY agr_name conflicts_new conflicts_rem.
    SORT et_newconflict_roles BY conid.
    SORT et_remconflict_roles BY conid.

    IF i_con_role_det = 'X'.
*--Collect all unique new and remidiated conflicts
      lr_conid-sign = 'I'.
      lr_conid-option = 'EQ'.
      LOOP AT et_newconflict_roles.
        lr_conid-low = et_newconflict_roles-conid.
        COLLECT lr_conid.
      ENDLOOP.
      LOOP AT et_remconflict_roles.
        lr_conid-low = et_remconflict_roles-conid.
        COLLECT lr_conid.
      ENDLOOP.
      SORT lr_conid BY low.

*--Find new and remidiated role name for each conflict
      LOOP AT lr_conid.

        CLEAR : lv_counter_n, lv_counter_r.

*--Check conflict is already traversed or not, if not move farward
        READ TABLE et_con_new_rem_role WITH KEY conid = lr_conid-low
        TRANSPORTING NO FIELDS BINARY SEARCH.
        IF sy-subrc <> 0.
          et_con_new_rem_role-conid = lr_conid-low.
*--Get conflict description, application area & sensitivity
          READ TABLE et_detail INTO ls_detail WITH KEY conid =
                                                         lr_conid-low
                                                         BINARY SEARCH.
          IF sy-subrc = 0.
            et_con_new_rem_role-description = ls_detail-description.
            et_con_new_rem_role-busarea = ls_detail-busarea.
            et_con_new_rem_role-sensitivity = ls_detail-sensitivity.
          ENDIF.

         WHILE lf_end <> 'X'. "No new and remidiated role exist for risk

*--Get new role for conflict
            LOOP AT et_newconflict_roles FROM lv_counter_n
                                       WHERE conid = lr_conid-low.
              lv_counter_n = sy-tabix + 1.
              READ TABLE et_con_new_rem_role WITH KEY conid =
                                                      lr_conid-low
                           role_new = et_newconflict_roles-agr_name
                           BINARY SEARCH.
              IF sy-subrc <> 0.
                EXIT. "New role found for conflict
              ENDIF.
            ENDLOOP.
            IF sy-subrc <> 0.
*--No new role exist for conflict
              CLEAR et_newconflict_roles.
            ENDIF.

*--Get remidiated role for conflict
            LOOP AT et_remconflict_roles FROM lv_counter_r
                                       WHERE conid = lr_conid-low.
              lv_counter_r = sy-tabix + 1.
              READ TABLE et_con_new_rem_role WITH KEY conid =
                                                            lr_conid-low
                               role_rem = et_remconflict_roles-agr_name
                               BINARY SEARCH.
              IF sy-subrc <> 0.
                EXIT. "Remidiated role found for conflict
              ENDIF.
            ENDLOOP.
            IF sy-subrc <> 0.
*--No remidiated role exist for conflict
              CLEAR et_remconflict_roles.
            ENDIF.

            IF et_newconflict_roles-conid IS INITIAL AND
              et_remconflict_roles-conid IS INITIAL.
*--No new and remidiated role exist for risk - EXIT while loop
              lf_end = 'X'.
            ELSE.
              et_con_new_rem_role-role_new =
                                         et_newconflict_roles-agr_name.

              et_con_new_rem_role-role_rem =
                                          et_remconflict_roles-agr_name.
              APPEND et_con_new_rem_role.
            ENDIF.
          ENDWHILE.
          CLEAR:lf_end.
        ENDIF.
      ENDLOOP.
    ENDIF.

    IF i_role_con_det = 'X'.
*--Collect all new and remidiated roles
      lr_role-sign = 'I'.
      lr_role-option = 'EQ'.
      LOOP AT et_newconflict_roles.
        lr_role-low = et_newconflict_roles-agr_name.
        COLLECT lr_role.
      ENDLOOP.
      LOOP AT et_remconflict_roles.
        lr_role-low = et_remconflict_roles-agr_name.
        COLLECT lr_role.
      ENDLOOP.
      SORT lr_role BY low.

*--Find new and remidiated conflict for each role
      LOOP AT lr_role.

        CLEAR : lv_counter_n, lv_counter_r.

*--Check entry for role already collected or not
        READ TABLE et_role_new_rem_con WITH KEY agr_name = lr_role-low
        TRANSPORTING NO FIELDS BINARY SEARCH.
        IF sy-subrc <> 0.
          et_role_new_rem_con-agr_name = lr_role-low.

          READ TABLE lt_role INTO ls_role_tmp
                    WITH KEY agr_name = lr_role-low.
          IF sy-subrc EQ 0.
            et_role_new_rem_con-agr_text = ls_role_tmp-agr_text.
          ENDIF.

          WHILE lf_end <> 'X'. "No new and remidiated con exist for role

*--Get new conflict for role
            LOOP AT et_newconflict_roles FROM lv_counter_n
                                       WHERE agr_name = lr_role-low.
              lv_counter_n = sy-tabix + 1.
              READ TABLE et_role_new_rem_con WITH KEY agr_name =
                                                      lr_role-low
                           conflicts_new = et_newconflict_roles-conid
                           BINARY SEARCH.
              IF sy-subrc <> 0.
                EXIT. "New conflict found for role
              ENDIF.
            ENDLOOP.
            IF sy-subrc <> 0.
*--No new conflict exist for role
              CLEAR et_newconflict_roles.
            ENDIF.

*--Get remidiated conflict for role
            LOOP AT et_remconflict_roles FROM lv_counter_r
                                       WHERE agr_name = lr_role-low.
              lv_counter_r = sy-tabix + 1.
              READ TABLE et_role_new_rem_con WITH KEY agr_name =
                                                             lr_role-low
                             conflicts_rem = et_remconflict_roles-conid
                             BINARY SEARCH.
              IF sy-subrc <> 0.
                EXIT. "Remidiated conflict found for role
              ENDIF.
            ENDLOOP.
            IF sy-subrc <> 0.
*--No remidiated conflict exist for role
              CLEAR et_remconflict_roles.
            ENDIF.

            IF et_newconflict_roles-agr_name IS INITIAL AND
              et_remconflict_roles-agr_name IS INITIAL.
*--No new and remidiated role exist for risk - EXIT while loop
              lf_end = 'X'.
            ELSE.
              et_role_new_rem_con-conflicts_new =
                                         et_newconflict_roles-conid.

              et_role_new_rem_con-conflicts_rem =
                                          et_remconflict_roles-conid.
              APPEND et_role_new_rem_con.
            ENDIF.
          ENDWHILE.
          CLEAR lf_end.
        ENDIF.

      ENDLOOP.
    ENDIF.
*End of Additon

*--Return ouptut in Role View
    IF NOT if_role_view IS INITIAL.
*--First populate the roles found in new conflicts
      LOOP AT et_newconflict_roles.
        et_detail_role_view-agr_name = et_newconflict_roles-agr_name.
        ADD 1 TO et_detail_role_view-conflicts_new.
        CLEAR ls_role_tmp.
        READ TABLE lt_role INTO ls_role_tmp
          WITH TABLE KEY aid   = l_latest_aid
                         agr_name = et_newconflict_roles-agr_name.
        IF sy-subrc EQ 0.
          et_detail_role_view-agr_text  = ls_role_tmp-agr_text.
        ENDIF.
        COLLECT et_detail_role_view INTO et_detail_role_view.
        CLEAR et_detail_role_view.
      ENDLOOP.
*--Then populate the roles found in rem conflicts
      LOOP AT et_remconflict_roles.
        et_detail_role_view-agr_name = et_remconflict_roles-agr_name.
        ADD 1 TO et_detail_role_view-conflicts_rem.
        READ TABLE lt_role INTO ls_role_tmp
          WITH TABLE KEY aid   = l_pre_aid
                         agr_name = et_remconflict_roles-agr_name.
        IF sy-subrc EQ 0.
          et_detail_role_view-agr_text  = ls_role_tmp-agr_text.
        ENDIF.
        COLLECT et_detail_role_view INTO et_detail_role_view.
        CLEAR et_detail_role_view.
      ENDLOOP.
*-- Add those roles which are same in both IDs
      LOOP AT lt_role INTO ls_role_tmp
        WHERE aid = l_latest_aid.
        et_detail_role_view-agr_name  = ls_role_tmp-agr_name.
        et_detail_role_view-agr_text  = ls_role_tmp-agr_text.
*--Begin of Addition PN16690 AKUMAR Issue1
*        COLLECT et_detail_user_view INTO et_detail_user_view.
*        CLEAR et_detail_user_view.
        COLLECT et_detail_role_view INTO et_detail_role_view.
        CLEAR et_detail_role_view.
*--End of Addition
      ENDLOOP.
    ENDIF.
  ENDIF.

  SORT et_detail BY conflicts_new DESCENDING conflicts_rem DESCENDING.
ENDFUNCTION.
