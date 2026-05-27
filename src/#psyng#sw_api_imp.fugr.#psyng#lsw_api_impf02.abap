**&---------------------------------------------------------------------*
**&  Include           /PSYNG/LSW_API_IMPF02
**&  Function Group    /PSYNG/SW_API_IMP
**&  Description       SE API - Analysis Result Detail Output (Optimized)
**&---------------------------------------------------------------------*
**&  PN-17852 Performance Optimization - Phase 5
**&  Author  : UMITTAL
**&  Date    : 26.05.2026
**&---------------------------------------------------------------------*
**&  CHANGES OVER LIVE PHASE 4 CODE (3 surgical parallel cursor fixes):
**&
**&  PC-1 : METHOD lcl_authdet_bulk_cache=>get
**&           LIVE:  LOOP AT gt_bulk WHERE sys=x AND funindex=x AND ...
**&                  gt_bulk is SORTED TABLE keyed BY sys funindex profileindex
**&                  ABAP uses a partial binary scan but still re-enters the
**&                  loop header on every row to evaluate all 3 WHERE fields.
**&           FIX:   READ TABLE gt_bulk ... BINARY SEARCH -> lv_start
**&                  LOOP AT gt_bulk FROM lv_start, EXIT on key boundary.
**&                  Pure O(log n) entry + O(k) iteration where k = matches.
**&                  This method is called once per fprprof row in the
**&                  innermost output loop -> HIGH cumulative impact.
**&
**&  PC-2 : FORM get_output_new_se — it_comprole loop
**&           LIVE:  LOOP AT it_comprole INTO ls_comprole
**&                    WHERE userindex = ls_usercon-userindex
**&                      AND roleindex = ls_profrole-roleindex.
**&                  it_comprole sort key is NON-UNIQUE KEY roleindex only.
**&                  ABAP cannot use the key for userindex -> O(n) per call.
**&           FIX:   Change sort to BY userindex roleindex before loop entry.
**&                  READ TABLE ... BINARY SEARCH to find start position.
**&                  LOOP FROM start, EXIT when key changes.
**&                  Reduces comprole scan from O(n) to O(log n) + O(k).
**&
**&  PC-3 : FORM get_output_old_se — it_comprole loop (same fix as PC-2)
**&           Identical issue and identical fix mirrored in the old SE path.
**&
**&  All other FORMs (get_analy_res_users, get_analy_res_conflicts,
**&  get_analy_res_profiles, get_analy_res_roles, get_analy_res_det)
**&  are UNCHANGED from live Phase 4 code.
**&---------------------------------------------------------------------*
**&  FULL OPTIMIZATION INVENTORY (Phase 4 + Phase 5):
**&  OPT-1  : lcl_authdet_bulk_cache — ONE bulk SELECT replaces FM calls
**&  OPT-2  : Parallel cursor on it_confun in output loops
**&  OPT-3  : BINARY SEARCH + bounded LOOP on it_fprprof / it_funprofile
**&  OPT-4  : User/conflict resolved only on key change
**&  OPT-5  : Inline HASHED lt_dedup — no post-loop SORT+DELETE
**&  OPT-6  : RFC_CALLBACK_REJECTED guard on remote RFC calls
**&  OPT-7  : Chunked 5000-row IN-range SELECTs
**&  OPT-8  : FOR ALL ENTRIES for all related table SELECTs
**&  OPT-9  : FREE all large tables after output is built
**&  PC-1   : Parallel cursor in METHOD get (gt_bulk lookup)       [NEW]
**&  PC-2/3 : Parallel cursor on it_comprole in both output FORMs  [NEW]
**&---------------------------------------------------------------------*
*
*
**======================================================================*
**  CLASS lcl_authdet_bulk_cache
**======================================================================*
*CLASS lcl_authdet_bulk_cache DEFINITION.
*  PUBLIC SECTION.
*
*    CLASS-METHODS init
*      IMPORTING
*        i_aid      TYPE /psyng/seresid
*        it_fprprof TYPE ty_tt_fprprof
*        it_sysmap  TYPE ty_th_sysmap.
*
*    CLASS-METHODS get
*      IMPORTING
*        i_sys          TYPE /psyng/swresfpr-sys
*        i_funindex     TYPE /psyng/swresfpr-funindex
*        i_profileindex TYPE /psyng/swresfpr-profileindex
*      CHANGING
*        ct_authdet     TYPE table.
*
*    CLASS-METHODS clear.
*
*    CLASS-DATA gf_initialized TYPE flag.
*
*  PRIVATE SECTION.
*
*    CLASS-DATA gt_bulk TYPE SORTED TABLE OF ty_caut_flat
*                       WITH NON-UNIQUE KEY sys funindex profileindex.
*
*ENDCLASS.
*
*
*CLASS lcl_authdet_bulk_cache IMPLEMENTATION.
*
*  METHOD init.
**   UNCHANGED from live Phase 4 — this method is already optimal.
**   ONE bulk SELECT on /psyng/swrescaut + 7 index table SELECTs total.
*
*    DATA: lt_caut       TYPE TABLE OF /psyng/swrescaut,
*          ls_caut       TYPE /psyng/swrescaut,
*          ls_fpr        TYPE /psyng/swresfpr,
*          ls_flat       TYPE ty_caut_flat,
*          ls_sysmap     TYPE /psyng/swresisys,
*          lt_idx_tcode  TYPE HASHED TABLE OF /psyng/swresitcd
*                        WITH UNIQUE KEY tcodeindex,
*          lt_idx_object TYPE HASHED TABLE OF /psyng/swresiobj
*                        WITH UNIQUE KEY objectindex,
*          lt_idx_field  TYPE HASHED TABLE OF /psyng/swresifld
*                        WITH UNIQUE KEY fieldindex,
*          lt_idx_auth   TYPE HASHED TABLE OF /psyng/swresiaut
*                        WITH UNIQUE KEY authindex,
*          lt_idx_vba    TYPE HASHED TABLE OF /psyng/swresvba
*                        WITH UNIQUE KEY vbaindex,
*          ls_tcode      TYPE /psyng/swresitcd,
*          ls_object     TYPE /psyng/swresiobj,
*          ls_field      TYPE /psyng/swresifld,
*          ls_auth       TYPE /psyng/swresiaut,
*          ls_vba        TYPE /psyng/swresvba,
*          ls_profile    TYPE /psyng/swresipro,
*          ls_function   TYPE /psyng/swresifun,
*          lt_profiles   TYPE HASHED TABLE OF /psyng/swresipro
*                        WITH UNIQUE KEY aid profindex,
*          lt_functions  TYPE HASHED TABLE OF /psyng/swresifun
*                        WITH UNIQUE KEY aid funindex,
*          lv_data       TYPE string,
*          lt_records    TYPE TABLE OF string,
*          lv_rec        TYPE string,
*          BEGIN OF ls_authdet_s,
*            tcodeindex  TYPE string,
*            objectindex TYPE string,
*            fieldindex  TYPE string,
*            vbaindex    TYPE string,
*            authindex   TYPE string,
*          END OF ls_authdet_s,
*          BEGIN OF ls_authdet,
*            tcodeindex  TYPE i,
*            objectindex TYPE i,
*            fieldindex  TYPE i,
*            vbaindex    TYPE i,
*            authindex   TYPE i,
*          END OF ls_authdet,
*          lv_cur_sys    TYPE /psyng/swrescaut-sys,
*          lv_cur_fun    TYPE /psyng/swrescaut-funindex,
*          lv_cur_prof   TYPE /psyng/swrescaut-profileindex.
*
*    DATA: lr_sys  TYPE RANGE OF /psyng/swrescaut-sys,
*          lr_fun  TYPE RANGE OF /psyng/swrescaut-funindex,
*          lr_prof TYPE RANGE OF /psyng/swrescaut-profileindex,
*          ls_sys  LIKE LINE OF lr_sys,
*          ls_fun  LIKE LINE OF lr_fun,
*          ls_prof LIKE LINE OF lr_prof.
*
*    REFRESH gt_bulk.
*    CLEAR gf_initialized.
*    CHECK NOT it_fprprof[] IS INITIAL.
*
*    ls_sys-sign  = 'I'. ls_sys-option  = 'EQ'.
*    ls_fun-sign  = 'I'. ls_fun-option  = 'EQ'.
*    ls_prof-sign = 'I'. ls_prof-option = 'EQ'.
*
*    LOOP AT it_fprprof INTO ls_fpr.
*      ls_sys-low  = ls_fpr-sys.          APPEND ls_sys  TO lr_sys.
*      ls_fun-low  = ls_fpr-funindex.     APPEND ls_fun  TO lr_fun.
*      ls_prof-low = ls_fpr-profileindex. APPEND ls_prof TO lr_prof.
*    ENDLOOP.
*
*    SORT lr_sys  BY low. DELETE ADJACENT DUPLICATES FROM lr_sys  COMPARING low.
*    SORT lr_fun  BY low. DELETE ADJACENT DUPLICATES FROM lr_fun  COMPARING low.
*    SORT lr_prof BY low. DELETE ADJACENT DUPLICATES FROM lr_prof COMPARING low.
*
*    SELECT * FROM /psyng/swrescaut INTO TABLE lt_caut
*      WHERE aid = i_aid AND sys IN lr_sys
*        AND funindex IN lr_fun AND profileindex IN lr_prof
*      ORDER BY sys funindex profileindex dataindex.
*    CHECK NOT lt_caut[] IS INITIAL.
*
*    SELECT * FROM /psyng/swresitcd INTO TABLE lt_idx_tcode  WHERE aid = i_aid.
*    SELECT * FROM /psyng/swresiobj INTO TABLE lt_idx_object WHERE aid = i_aid.
*    SELECT * FROM /psyng/swresifld INTO TABLE lt_idx_field  WHERE aid = i_aid.
*    SELECT * FROM /psyng/swresiaut INTO TABLE lt_idx_auth   WHERE aid = i_aid.
*    SELECT * FROM /psyng/swresvba  INTO TABLE lt_idx_vba.
*    SELECT * FROM /psyng/swresipro INTO TABLE lt_profiles   WHERE aid = i_aid.
*    SELECT * FROM /psyng/swresifun INTO TABLE lt_functions  WHERE aid = i_aid.
*
*    CLEAR: lv_cur_sys, lv_cur_fun, lv_cur_prof, lv_data.
*
*    LOOP AT lt_caut INTO ls_caut.
*
*      IF ls_caut-sys          <> lv_cur_sys
*      OR ls_caut-funindex     <> lv_cur_fun
*      OR ls_caut-profileindex <> lv_cur_prof.
*
*        IF lv_data IS NOT INITIAL.
*          REFRESH lt_records.
*          SPLIT lv_data AT '-' INTO TABLE lt_records.
*
*          READ TABLE lt_functions INTO ls_function
*            WITH TABLE KEY aid = i_aid funindex = lv_cur_fun.
*          READ TABLE lt_profiles INTO ls_profile
*            WITH TABLE KEY aid = i_aid profindex = lv_cur_prof.
*          READ TABLE it_sysmap INTO ls_sysmap
*            WITH TABLE KEY sysindex = lv_cur_sys.
*
*          LOOP AT lt_records INTO lv_rec.
*            CHECK lv_rec IS NOT INITIAL.
*            SPLIT lv_rec AT ',' INTO
*              ls_authdet_s-tcodeindex  ls_authdet_s-objectindex
*              ls_authdet_s-fieldindex  ls_authdet_s-vbaindex
*              ls_authdet_s-authindex.
*
*            ls_authdet-tcodeindex  = ls_authdet_s-tcodeindex.
*            ls_authdet-objectindex = ls_authdet_s-objectindex.
*            ls_authdet-fieldindex  = ls_authdet_s-fieldindex.
*            ls_authdet-vbaindex    = ls_authdet_s-vbaindex.
*            ls_authdet-authindex   = ls_authdet_s-authindex.
*
*            CLEAR ls_flat.
*            ls_flat-sys          = lv_cur_sys.
*            ls_flat-funindex     = lv_cur_fun.
*            ls_flat-profileindex = lv_cur_prof.
*            ls_flat-funid        = ls_function-funid.
*            ls_flat-profname     = ls_profile-profname.
*            ls_flat-sysid        = ls_sysmap-sysid.
*
*            READ TABLE lt_idx_tcode  INTO ls_tcode
*              WITH TABLE KEY tcodeindex  = ls_authdet-tcodeindex.
*            READ TABLE lt_idx_object INTO ls_object
*              WITH TABLE KEY objectindex = ls_authdet-objectindex.
*            READ TABLE lt_idx_field  INTO ls_field
*              WITH TABLE KEY fieldindex  = ls_authdet-fieldindex.
*            READ TABLE lt_idx_auth   INTO ls_auth
*              WITH TABLE KEY authindex   = ls_authdet-authindex.
*            READ TABLE lt_idx_vba    INTO ls_vba
*              WITH TABLE KEY vbaindex    = ls_authdet-vbaindex.
*
*            ls_flat-tcode  = ls_tcode-tcode.
*            ls_flat-object = ls_object-object.
*            ls_flat-field  = ls_field-field.
*            ls_flat-auth   = ls_auth-auth.
*            ls_flat-von    = ls_vba-von.
*            ls_flat-bis    = ls_vba-bis.
*            ls_flat-abb    = ls_vba-abb.
*
*            INSERT ls_flat INTO TABLE gt_bulk.
*          ENDLOOP.
*        ENDIF.
*
*        lv_cur_sys  = ls_caut-sys.
*        lv_cur_fun  = ls_caut-funindex.
*        lv_cur_prof = ls_caut-profileindex.
*        CLEAR lv_data.
*      ENDIF.
*
*      CONCATENATE lv_data ls_caut-data INTO lv_data.
*
*    ENDLOOP.
*
*    IF lv_data IS NOT INITIAL.
*      REFRESH lt_records.
*      SPLIT lv_data AT '-' INTO TABLE lt_records.
*
*      READ TABLE lt_functions INTO ls_function
*        WITH TABLE KEY aid = i_aid funindex = lv_cur_fun.
*      READ TABLE lt_profiles INTO ls_profile
*        WITH TABLE KEY aid = i_aid profindex = lv_cur_prof.
*      READ TABLE it_sysmap INTO ls_sysmap
*        WITH TABLE KEY sysindex = lv_cur_sys.
*
*      LOOP AT lt_records INTO lv_rec.
*        CHECK lv_rec IS NOT INITIAL.
*        SPLIT lv_rec AT ',' INTO
*          ls_authdet_s-tcodeindex  ls_authdet_s-objectindex
*          ls_authdet_s-fieldindex  ls_authdet_s-vbaindex
*          ls_authdet_s-authindex.
*
*        ls_authdet-tcodeindex  = ls_authdet_s-tcodeindex.
*        ls_authdet-objectindex = ls_authdet_s-objectindex.
*        ls_authdet-fieldindex  = ls_authdet_s-fieldindex.
*        ls_authdet-vbaindex    = ls_authdet_s-vbaindex.
*        ls_authdet-authindex   = ls_authdet_s-authindex.
*
*        CLEAR ls_flat.
*        ls_flat-sys          = lv_cur_sys.
*        ls_flat-funindex     = lv_cur_fun.
*        ls_flat-profileindex = lv_cur_prof.
*        ls_flat-funid        = ls_function-funid.
*        ls_flat-profname     = ls_profile-profname.
*        ls_flat-sysid        = ls_sysmap-sysid.
*
*        READ TABLE lt_idx_tcode  INTO ls_tcode
*          WITH TABLE KEY tcodeindex  = ls_authdet-tcodeindex.
*        READ TABLE lt_idx_object INTO ls_object
*          WITH TABLE KEY objectindex = ls_authdet-objectindex.
*        READ TABLE lt_idx_field  INTO ls_field
*          WITH TABLE KEY fieldindex  = ls_authdet-fieldindex.
*        READ TABLE lt_idx_auth   INTO ls_auth
*          WITH TABLE KEY authindex   = ls_authdet-authindex.
*        READ TABLE lt_idx_vba    INTO ls_vba
*          WITH TABLE KEY vbaindex    = ls_authdet-vbaindex.
*
*        ls_flat-tcode  = ls_tcode-tcode.
*        ls_flat-object = ls_object-object.
*        ls_flat-field  = ls_field-field.
*        ls_flat-auth   = ls_auth-auth.
*        ls_flat-von    = ls_vba-von.
*        ls_flat-bis    = ls_vba-bis.
*        ls_flat-abb    = ls_vba-abb.
*
*        INSERT ls_flat INTO TABLE gt_bulk.
*      ENDLOOP.
*    ENDIF.
*
*    gf_initialized = 'X'.
*
*  ENDMETHOD.
*
*
**----------------------------------------------------------------------*
** METHOD get  — PC-1: PARALLEL CURSOR replaces LOOP AT gt_bulk WHERE
**
** LIVE CODE (Phase 4):
**   LOOP AT gt_bulk INTO ls_flat
**     WHERE sys = i_sys AND funindex = i_funindex
**       AND profileindex = i_profileindex.
**   ENDLOOP.
**   Problem: Although gt_bulk is SORTED BY sys funindex profileindex,
**   ABAP's LOOP WHERE evaluates all 3 WHERE conditions on every row
**   it visits. For a large gt_bulk (thousands of flat rows across all
**   sys/fun/profile combos) ABAP does use the sort key to narrow the
**   scan range, but the range-entry itself re-evaluates the full WHERE
**   predicate and cannot EXIT early without an explicit EXIT statement.
**
** NEW CODE (Phase 5 - PC-1):
**   READ TABLE gt_bulk WITH KEY sys=x funindex=x profileindex=x
**     BINARY SEARCH -> lv_bulk_start (tabix of first matching row).
**   LOOP AT gt_bulk FROM lv_bulk_start, EXIT the instant any key field
**   changes. This guarantees O(log n) entry + O(k) pure iteration with
**   no WHERE predicate overhead per row.
**   Impact: Called once per fprprof row in the innermost output loop.
**   For 10K users × 5 conflicts × 3 profiles = 150K calls -> measurable.
**----------------------------------------------------------------------*
*  METHOD get.
*
*    DATA: ls_flat     TYPE ty_caut_flat,
*          ls_authdet  TYPE /psyng/seres_authdetail,
*          lv_bulk_start TYPE i.             "PC-1: cursor position
*
**   PC-1: Binary search entry — O(log n) instead of WHERE-scan entry
*    READ TABLE gt_bulk INTO ls_flat
*      WITH KEY sys          = i_sys
*               funindex     = i_funindex
*               profileindex = i_profileindex
*      BINARY SEARCH.
*
*    IF sy-subrc <> 0.
*      RETURN.                               "no authdet for this combo
*    ENDIF.
*
*    lv_bulk_start = sy-tabix.
*
**   PC-1: Iterate only matching rows — EXIT the instant key changes
*    LOOP AT gt_bulk INTO ls_flat FROM lv_bulk_start.
*
*      IF ls_flat-sys          <> i_sys
*      OR ls_flat-funindex     <> i_funindex
*      OR ls_flat-profileindex <> i_profileindex.
*        EXIT.                               "past our key block, stop
*      ENDIF.
*
*      CLEAR ls_authdet.
*      ls_authdet-tcode    = ls_flat-tcode.
*      ls_authdet-object   = ls_flat-object.
*      ls_authdet-field    = ls_flat-field.
*      ls_authdet-von      = ls_flat-von.
*      ls_authdet-bis      = ls_flat-bis.
*      ls_authdet-abb      = ls_flat-abb.
*      ls_authdet-auth     = ls_flat-auth.
*      ls_authdet-funid    = ls_flat-funid.
*      ls_authdet-profname = ls_flat-profname.
*      APPEND ls_authdet TO ct_authdet.
*
*    ENDLOOP.
*
*  ENDMETHOD.
*
*
*  METHOD clear.
*    REFRESH gt_bulk.
*    CLEAR gf_initialized.
*  ENDMETHOD.
*
*ENDCLASS.
*
*
**======================================================================*
** FORM get_analy_res_users  — UNCHANGED from live Phase 4
**======================================================================*
*FORM get_analy_res_users
*  TABLES
*    it_users             STRUCTURE /psyng/sw_userlist
*    et_return            STRUCTURE bapiret2
*  USING
*    i_analysis_run       TYPE /psyng/seresid
*  CHANGING
*    et_user              TYPE ty_th_users
*    lr_userindex         TYPE ty_r_userindex
*    ef_continue          TYPE flag.
*
*  DATA: lt_system     TYPE SORTED TABLE OF /psyng/swresisys
*                         WITH UNIQUE KEY sysindex WITH HEADER LINE,
*        lt_sysinfo    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
*        lt_bname      TYPE TABLE OF /psyng/sw_sel_opts_xubname,
*        ls_bname      TYPE /psyng/sw_sel_opts_xubname,
*        lt_user1      TYPE TABLE OF usr02,
*        lt_rem_users  TYPE TABLE OF usr02,
*        lt_lcl_users  TYPE TABLE OF usr02,
*        lt_user_keep  TYPE TABLE OF ty_users,
*        ls_user       TYPE ty_users,
*        lt_user_tmp   TYPE TABLE OF ty_users,
*        loc_system    TYPE rfcdest,
*        ls_userindex  LIKE LINE OF lr_userindex,
*        lt_users_orig TYPE TABLE OF /psyng/sw_userlist,
*        ls_users_orig TYPE /psyng/sw_userlist.
*
*  RANGES: lr_uname FOR usr02-bname.
*
*  SORT it_users.
*  DELETE ADJACENT DUPLICATES FROM it_users COMPARING ALL FIELDS.
*
*  lr_uname-sign   = 'I'.
*  lr_uname-option = 'CP'.
*  LOOP AT it_users.
*    lr_uname-low = it_users-bname.
*    APPEND lr_uname.
*  ENDLOOP.
*
*  IF lr_uname[] IS INITIAL.
*    SELECT aid userindex bname nr_conflicts department class nr_mitigated
*      FROM /psyng/swresusr INTO TABLE et_user
*      WHERE aid = i_analysis_run.
*  ELSE.
*    SELECT aid userindex bname nr_conflicts department class nr_mitigated
*      FROM /psyng/swresusr INTO TABLE et_user
*      WHERE aid = i_analysis_run AND bname IN lr_uname.
*  ENDIF.
*
*  IF sy-subrc <> 0.
*    log et_return 'E' 'NOUSERS' 'No Users match the selection' '' '' ''.
*    CLEAR ef_continue.
*    RETURN.
*  ENDIF.
*
*  IF it_users[] IS NOT INITIAL.
*    SELECT * FROM /psyng/swresisys INTO TABLE lt_system
*      WHERE aid = i_analysis_run.
*    IF NOT lt_system[] IS INITIAL.
*      SELECT * FROM /psyng/sw_rfcdes INTO TABLE lt_sysinfo
*        FOR ALL ENTRIES IN lt_system WHERE systid = lt_system-sysid.
*    ENDIF.
*
*    CONCATENATE sy-sysid sy-mandt INTO loc_system.
*
*    ls_bname-sign   = 'I'.
*    ls_bname-option = 'EQ'.
*    LOOP AT it_users.
*      ls_bname-low = it_users-bname.
*      APPEND ls_bname TO lt_bname.
*    ENDLOOP.
*
*    lt_users_orig[] = it_users[].
*    CLEAR it_users.
*
*    LOOP AT lt_sysinfo.
*      IF lt_sysinfo-systid <> loc_system.
*        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
*          EXCEPTIONS OTHERS = 5.
*        CALL FUNCTION '/PSYNG/SW_041'
*          DESTINATION lt_sysinfo-rfcdest
*          EXPORTING
*            i_include_locked      = 'X'
*            i_include_expired     = 'X'
*          TABLES
*            et_users              = lt_rem_users
*            it_userlist           = lt_bname
*          EXCEPTIONS
*            communication_failure = 1
*            system_failure        = 2
*            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK
*        IF sy-subrc = 0.
*          APPEND LINES OF lt_rem_users TO lt_user1.
*        ELSE.
*          log et_return 'W' 'RFCFAIL'
*            'RFC user validation failed for system' lt_sysinfo-systid '' ''.
*        ENDIF.
*      ELSE.
*        CALL FUNCTION '/PSYNG/SW_041'
*          EXPORTING
*            i_include_locked  = 'X'
*            i_include_expired = 'X'
*          TABLES
*            et_users          = lt_lcl_users
*            it_userlist       = lt_bname.
*        APPEND LINES OF lt_lcl_users TO lt_user1.
*      ENDIF.
*      FREE: lt_rem_users, lt_lcl_users.
*    ENDLOOP.
*
*    SORT lt_user1.
*    DELETE ADJACENT DUPLICATES FROM lt_user1 COMPARING ALL FIELDS.
*
*    LOOP AT et_user INTO ls_user.
*      READ TABLE lt_user1 WITH KEY bname = ls_user-bname
*        BINARY SEARCH TRANSPORTING NO FIELDS.
*      IF sy-subrc = 0.
*        APPEND ls_user TO lt_user_keep.
*      ENDIF.
*    ENDLOOP.
*    et_user = lt_user_keep[].
*    FREE: lt_user1, lt_user_keep.
*  ENDIF.
*
*  ls_userindex-sign   = 'I'.
*  ls_userindex-option = 'EQ'.
*  LOOP AT et_user INTO ls_user.
*    ls_userindex-low = ls_user-userindex.
*    APPEND ls_userindex TO lr_userindex.
*  ENDLOOP.
*
*  IF lt_users_orig[] IS NOT INITIAL.
*    lt_user_tmp = et_user.
*    SORT lt_user_tmp BY bname.
*    LOOP AT lt_users_orig INTO ls_users_orig.
*      READ TABLE lt_user_tmp WITH KEY bname = ls_users_orig-bname
*        BINARY SEARCH TRANSPORTING NO FIELDS.
*      IF sy-subrc NE 0.
*        log_v et_return 'W' 'INVALIDUSER'
*          'User' ls_users_orig-bname 'does not exist'
*          ls_users_orig-bname ''.
*      ENDIF.
*    ENDLOOP.
*    FREE lt_user_tmp.
*  ENDIF.
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_analy_res_conflicts  — UNCHANGED from live Phase 4
**======================================================================*
*FORM get_analy_res_conflicts
*  TABLES
*    et_users             STRUCTURE /psyng/userconcount
*    et_return            STRUCTURE bapiret2
*  USING
*    i_analysis_run       TYPE /psyng/seresid
*    if_exclude_mitigated TYPE flag
*    it_user              TYPE ty_th_users
*    it_userindex         TYPE ty_r_userindex
*  CHANGING
*    et_usercon           TYPE ty_tt_usercon
*    et_conflict          TYPE ty_th_conflict
*    et_confun            TYPE ty_tt_confun
*    et_function          TYPE ty_th_function
*    lr_funindex          TYPE ty_r_funindex
*    e_result_count       TYPE i.
*
*  DATA: ls_user     TYPE ty_users,
*        ls_funindex LIKE LINE OF lr_funindex.
*
*  RANGES: lr_uix_all   FOR /psyng/swrescon-userindex,
*          lr_uix_chunk FOR /psyng/swrescon-userindex.
*
*  FIELD-SYMBOLS: <confun> TYPE /psyng/swrescfun.
*
*  LOOP AT it_user INTO ls_user.
*    et_users-uname = ls_user-bname.
*    et_users-count = ls_user-nr_conflicts.
*    ADD ls_user-nr_conflicts TO e_result_count.
*    APPEND et_users.
*  ENDLOOP.
*
*  lr_uix_all[] = it_userindex[].
*  WHILE NOT lr_uix_all[] IS INITIAL.
*    REFRESH lr_uix_chunk.
*    APPEND LINES OF lr_uix_all FROM 1 TO 5000 TO lr_uix_chunk.
*    DELETE lr_uix_all FROM 1 TO 5000.
*    IF if_exclude_mitigated = 'X'.
*      SELECT * FROM /psyng/swrescon APPENDING TABLE et_usercon
*        WHERE aid       = i_analysis_run
*          AND userindex IN lr_uix_chunk
*          AND mitigated = ''.
*    ELSE.
*      SELECT * FROM /psyng/swrescon APPENDING TABLE et_usercon
*        WHERE aid       = i_analysis_run
*          AND userindex IN lr_uix_chunk.
*    ENDIF.
*  ENDWHILE.
*
*  CHECK NOT et_usercon[] IS INITIAL.
*
*  SELECT * FROM /psyng/swresicon INTO TABLE et_conflict
*    FOR ALL ENTRIES IN et_usercon
*    WHERE aid = i_analysis_run AND conindex = et_usercon-conindex.
*
*  SELECT * FROM /psyng/swrescfun INTO TABLE et_confun
*    FOR ALL ENTRIES IN et_usercon
*    WHERE aid = i_analysis_run AND conindex = et_usercon-conindex.
*
*  IF NOT et_confun[] IS INITIAL.
*    SELECT * FROM /psyng/swresifun INTO TABLE et_function
*      FOR ALL ENTRIES IN et_confun
*      WHERE aid = i_analysis_run AND funindex = et_confun-funindex.
*  ENDIF.
*
*  ls_funindex-sign   = 'I'.
*  ls_funindex-option = 'EQ'.
*  LOOP AT et_confun ASSIGNING <confun>.
*    ls_funindex-low = <confun>-funindex.
*    APPEND ls_funindex TO lr_funindex.
*  ENDLOOP.
*  SORT lr_funindex BY low.
*  DELETE ADJACENT DUPLICATES FROM lr_funindex COMPARING low.
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_analy_res_profiles  — UNCHANGED from live Phase 4
**======================================================================*
*FORM get_analy_res_profiles
*  USING
*    i_analysis_run TYPE /psyng/seresid
*    i_new_se_vrs   TYPE flag
*    it_usercon     TYPE ty_tt_usercon
*    it_funindex    TYPE ty_r_funindex
*    it_userindex   TYPE ty_r_userindex
*  CHANGING
*    et_fprprof     TYPE ty_tt_fprprof
*    et_usrprof     TYPE ty_tt_usrprof
*    et_funprofile  TYPE ty_tt_fprprof
*    et_profiles    TYPE ty_th_profiles
*    lr_profindex   TYPE ty_r_profindex
*    lr_sys         TYPE ty_r_sys.
*
*  DATA: ls_usrprof    TYPE /psyng/swresupr,
*        ls_profindex  LIKE LINE OF lr_profindex,
*        ls_funprofile TYPE /psyng/swresfpr,
*        ls_sys        LIKE LINE OF lr_sys,
*        lt_usrprof2   TYPE TABLE OF /psyng/swresupr,
*        lr_pix_all    LIKE lr_profindex,
*        lr_pix_part   LIKE lr_profindex.
*
*  IF i_new_se_vrs = 'X'.
*    IF it_userindex[] IS NOT INITIAL.
*      SELECT * FROM /psyng/swresfpr INTO TABLE et_fprprof
*        FOR ALL ENTRIES IN it_userindex
*        WHERE aid = i_analysis_run AND userindex = it_userindex-low.
*    ENDIF.
*  ELSE.
*    IF it_userindex[] IS NOT INITIAL.
*      SELECT * FROM /psyng/swresupr
*        INTO CORRESPONDING FIELDS OF TABLE et_usrprof
*        FOR ALL ENTRIES IN it_userindex
*        WHERE aid = i_analysis_run AND userindex = it_userindex-low.
*    ENDIF.
*  ENDIF.
*
*  ls_profindex-sign   = 'I'.
*  ls_profindex-option = 'EQ'.
*  ls_sys-sign         = 'I'.
*  ls_sys-option       = 'EQ'.
*
*  IF i_new_se_vrs = 'X'.
*    LOOP AT et_fprprof INTO ls_funprofile.
*      ls_profindex-low = ls_funprofile-profileindex.
*      APPEND ls_profindex TO lr_profindex.
*      ls_sys-low = ls_funprofile-sys.
*      APPEND ls_sys TO lr_sys.
*    ENDLOOP.
*  ELSE.
*    LOOP AT et_usrprof INTO ls_usrprof.
*      ls_profindex-low = ls_usrprof-profileindex.
*      APPEND ls_profindex TO lr_profindex.
*      ls_sys-low = ls_usrprof-sys.
*      APPEND ls_sys TO lr_sys.
*    ENDLOOP.
*  ENDIF.
*
*  SORT lr_profindex BY low.
*  SORT lr_sys BY low.
*  DELETE ADJACENT DUPLICATES FROM lr_profindex COMPARING low.
*  DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.
*
*  IF NOT lr_profindex[] IS INITIAL.
*    lr_pix_all[] = lr_profindex[].
*    WHILE NOT lr_pix_all[] IS INITIAL.
*      REFRESH lr_pix_part.
*      APPEND LINES OF lr_pix_all FROM 1 TO 5000 TO lr_pix_part.
*      DELETE lr_pix_all FROM 1 TO 5000.
*      IF i_new_se_vrs IS INITIAL.
*        SELECT * FROM /psyng/swresfpr APPENDING TABLE et_funprofile
*          WHERE aid          = i_analysis_run
*            AND sys          IN lr_sys
*            AND funindex     IN it_funindex
*            AND profileindex IN lr_pix_part.
*      ENDIF.
*    ENDWHILE.
*  ENDIF.
*
*  IF NOT lr_profindex[] IS INITIAL.
*    SELECT * FROM /psyng/swresipro INTO TABLE et_profiles
*      FOR ALL ENTRIES IN lr_profindex
*      WHERE aid = i_analysis_run AND profindex = lr_profindex-low.
*  ENDIF.
*
*  IF i_new_se_vrs IS INITIAL.
*    SORT et_funprofile BY sys profileindex.
*    LOOP AT et_usrprof INTO ls_usrprof.
*      READ TABLE et_funprofile WITH KEY
*        sys = ls_usrprof-sys profileindex = ls_usrprof-profileindex
*        BINARY SEARCH TRANSPORTING NO FIELDS.
*      IF sy-subrc = 0.
*        APPEND ls_usrprof TO lt_usrprof2.
*      ENDIF.
*    ENDLOOP.
*    et_usrprof[] = lt_usrprof2[].
*    FREE lt_usrprof2.
*  ENDIF.
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_analy_res_roles  — UNCHANGED from live Phase 4
**======================================================================*
*FORM get_analy_res_roles
*  USING
*    i_analysis_run TYPE /psyng/seresid
*    i_new_se_vrs   TYPE flag
*    it_fprprof     TYPE ty_tt_fprprof
*    it_usrprof     TYPE ty_tt_usrprof
*    it_userindex   TYPE ty_r_userindex
*    it_sys         TYPE ty_r_sys
*  CHANGING
*    et_profrole    TYPE ty_ts_profrole
*    et_roles       TYPE ty_ts_roles
*    et_comprole    TYPE ty_ts_comprole.
*
*  DATA: lr_uix_all   LIKE it_userindex,
*        lr_uix_part  LIKE it_userindex,
*        lt_comp_part TYPE SORTED TABLE OF /psyng/swresucom
*                     WITH NON-UNIQUE KEY roleindex,
*        ls_comp_part TYPE /psyng/swresucom.
*
*  IF i_new_se_vrs = 'X'.
*    IF NOT it_fprprof[] IS INITIAL.
*      SELECT * FROM /psyng/swresprol INTO TABLE et_profrole
*        FOR ALL ENTRIES IN it_fprprof
*        WHERE aid      = i_analysis_run
*          AND sys      = it_fprprof-sys
*          AND profindex = it_fprprof-profileindex.
*
*      IF NOT et_profrole[] IS INITIAL.
*        SELECT * FROM /psyng/swresirol INTO TABLE et_roles
*          FOR ALL ENTRIES IN et_profrole
*          WHERE aid      = i_analysis_run
*            AND roleindex = et_profrole-roleindex.
*
*        IF NOT et_roles[] IS INITIAL.
*          IF it_userindex[] IS NOT INITIAL.
*            lr_uix_part[] = it_userindex[].
*            WHILE NOT lr_uix_part[] IS INITIAL.
*              REFRESH lr_uix_all.
*              APPEND LINES OF lr_uix_part FROM 1 TO 5000 TO lr_uix_all.
*              DELETE lr_uix_part FROM 1 TO 5000.
*              SELECT * FROM /psyng/swresucom INTO TABLE lt_comp_part
*                FOR ALL ENTRIES IN et_roles
*                WHERE aid       = i_analysis_run
*                  AND userindex IN lr_uix_all
*                  AND roleindex  = et_roles-roleindex.
*              LOOP AT lt_comp_part INTO ls_comp_part.
*                INSERT ls_comp_part INTO TABLE et_comprole.
*              ENDLOOP.
*              REFRESH: lr_uix_all[], lt_comp_part[].
*            ENDWHILE.
*          ENDIF.
*
*          IF NOT et_comprole[] IS INITIAL.
*            DELETE et_comprole
*              WHERE compindex IS INITIAL OR compindex = 0.
*          ENDIF.
*          IF NOT et_comprole[] IS INITIAL.
*            SELECT * FROM /psyng/swresirol APPENDING TABLE et_roles
*              FOR ALL ENTRIES IN et_comprole
*              WHERE aid      = i_analysis_run
*                AND roleindex = et_comprole-compindex.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*
*  ELSE.
*    IF NOT it_usrprof[] IS INITIAL.
*      SELECT * FROM /psyng/swresprol INTO TABLE et_profrole
*        FOR ALL ENTRIES IN it_usrprof
*        WHERE aid      = i_analysis_run
*          AND sys      = it_usrprof-sys
*          AND profindex = it_usrprof-profileindex.
*
*      IF NOT et_profrole[] IS INITIAL.
*        SELECT * FROM /psyng/swresirol INTO TABLE et_roles
*          FOR ALL ENTRIES IN et_profrole
*          WHERE aid      = i_analysis_run
*            AND roleindex = et_profrole-roleindex.
*
*        IF NOT et_roles[] IS INITIAL.
*          SELECT * FROM /psyng/swresucom INTO TABLE et_comprole
*            FOR ALL ENTRIES IN et_roles
*            WHERE aid       = i_analysis_run
*              AND userindex IN it_userindex
*              AND roleindex  = et_roles-roleindex.
*
*          IF NOT et_comprole[] IS INITIAL.
*            DELETE et_comprole
*              WHERE compindex IS INITIAL OR compindex = 0.
*          ENDIF.
*          IF NOT et_comprole[] IS INITIAL.
*            SELECT * FROM /psyng/swresirol APPENDING TABLE et_roles
*              FOR ALL ENTRIES IN et_comprole
*              WHERE aid      = i_analysis_run
*                AND roleindex = et_comprole-compindex.
*          ENDIF.
*        ENDIF.
*      ENDIF.
*    ENDIF.
*  ENDIF.
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_output_new_se
**
** PC-2: PARALLEL CURSOR on it_comprole replaces LOOP WHERE
**
** LIVE CODE (Phase 4):
**   it_comprole TYPE ty_ts_comprole =
**     SORTED TABLE WITH NON-UNIQUE KEY roleindex
**
**   LOOP AT it_comprole INTO ls_comprole
**     WHERE userindex = ls_usercon-userindex
**       AND roleindex  = ls_profrole-roleindex.
**
**   Problem: The sort key is roleindex ONLY.
**   ABAP uses the key to narrow to rows with matching roleindex,
**   but userindex is NOT in the key so every row in that roleindex
**   block is visited and tested — O(n) for the roleindex group.
**   This loop sits inside the INNERMOST fprprof loop.
**
** FIX (PC-2):
**   1. Before the outer loop, re-sort it_comprole BY userindex roleindex.
**      (it_comprole is declared SORTED in ty_ts_comprole — we must use
**       a local STANDARD TABLE copy sorted by the new key order to avoid
**       violating the SORTED TABLE key constraint.)
**   2. READ TABLE with BINARY SEARCH to find start position.
**   3. LOOP FROM position, EXIT when userindex or roleindex changes.
**   Result: O(log n) entry + O(k) iteration where k = actual matches.
**======================================================================*
*FORM get_output_new_se
*  TABLES
*    lt_output     STRUCTURE /psyng/sw_outputdet
*  USING
*    i_analysis_run       TYPE /psyng/seresid
*    if_direct_assn_only  TYPE flag
*    it_user              TYPE ty_th_users
*    it_usercon           TYPE ty_tt_usercon
*    it_conflict          TYPE ty_th_conflict
*    it_confun            TYPE ty_tt_confun
*    it_function          TYPE ty_th_function
*    it_profiles          TYPE ty_th_profiles
*    it_fprprof           TYPE ty_tt_fprprof
*    it_profrole          TYPE ty_ts_profrole
*    it_roles             TYPE ty_ts_roles
*    it_comprole          TYPE ty_ts_comprole
*    it_sysmap            TYPE ty_th_sysmap.
*
*  DATA: ls_user        TYPE ty_users,
*        ls_conflict    TYPE /psyng/swresicon,
*        ls_function    TYPE /psyng/swresifun,
*        ls_profiles    TYPE /psyng/swresipro,
*        ls_profrole    TYPE /psyng/swresprol,
*        ls_roles       TYPE /psyng/swresirol,
*        ls_comprole    TYPE /psyng/swresucom,
*        ls_usercon     TYPE /psyng/swrescon,
*        ls_fprprof     TYPE /psyng/swresfpr,
*        ls_confun      TYPE /psyng/swrescfun,
*        ls_sysmap      TYPE /psyng/swresisys,
*        ls_output      LIKE LINE OF lt_output,
*        ls_authdet     TYPE /psyng/seres_authdetail,
*        lt_authdet     TYPE TABLE OF /psyng/seres_authdetail,
*        lt_dedup       TYPE HASHED TABLE OF /psyng/sw_outputdet
*                        WITH UNIQUE KEY bname conid sysid funid
*                                        comp_agr agr_name profname
*                                        tcode auth object field von bis,
*        lv_comp_agr    TYPE agr_define-agr_name,
*        lf_direct_role TYPE flag,
*        lf_profauth    TYPE flag,
*        lv_cur_confun  TYPE i,
*        lv_fpr_start   TYPE i,
*        lv_prev_con    TYPE /psyng/swrescon-conindex,
*        lv_prev_uix    TYPE /psyng/swrescon-userindex,
*        lv_user_ok     TYPE flag,
*        lv_con_ok      TYPE flag,
**       PC-2: STANDARD TABLE — allows SORT command (SORTED TABLE does not)
*        lt_comprole_pc TYPE STANDARD TABLE OF /psyng/swresucom,
*        lv_compr_start TYPE i.            "PC-2: cursor position
*
** Pre-sorts for existing parallel cursors (OPT-2 and OPT-3)
*  SORT: it_usercon BY conindex userindex,
*        it_confun  BY conindex,
*        it_fprprof BY userindex funindex profileindex.
*
** PC-2: Build local comprole copy sorted by userindex roleindex.
**        Cannot re-sort ty_ts_comprole (SORTED TABLE with fixed key).
**        Copy once here — O(n log n) done ONCE before the loop,
**        pays for itself immediately in the first few fprprof iterations.
*  lt_comprole_pc[] = it_comprole[].
*  SORT lt_comprole_pc BY userindex roleindex.
*
*  CLEAR: lv_prev_con, lv_prev_uix, lv_user_ok, lv_con_ok.
*  lv_cur_confun = 1.
*
**=== OUTER LOOP ===
*  LOOP AT it_usercon INTO ls_usercon.
*
**   OPT-4: resolve user only on userindex change
*    IF ls_usercon-userindex <> lv_prev_uix.
*      lv_prev_uix = ls_usercon-userindex.
*      READ TABLE it_user INTO ls_user
*        WITH TABLE KEY aid       = i_analysis_run
*                       userindex = ls_usercon-userindex.
*      IF sy-subrc = 0.
*        lv_user_ok = 'X'.
*      ELSE.
*        CLEAR lv_user_ok.
*      ENDIF.
*    ENDIF.
*    CHECK lv_user_ok = 'X'.
*
**   OPT-4 + OPT-2: resolve conflict and advance confun cursor
*    IF ls_usercon-conindex <> lv_prev_con.
*      lv_prev_con = ls_usercon-conindex.
*      READ TABLE it_conflict INTO ls_conflict
*        WITH TABLE KEY aid      = i_analysis_run
*                       conindex = ls_usercon-conindex.
*      IF sy-subrc = 0.
*        lv_con_ok = 'X'.
*      ELSE.
*        CLEAR lv_con_ok.
*      ENDIF.
*      READ TABLE it_confun INTO ls_confun
*        WITH KEY conindex = ls_usercon-conindex BINARY SEARCH.
*      IF sy-subrc = 0.
*        lv_cur_confun = sy-tabix.
*      ELSE.
*        lv_cur_confun = 0.
*      ENDIF.
*    ENDIF.
*    CHECK lv_con_ok = 'X'.
*    CHECK lv_cur_confun > 0.
*
*    CLEAR ls_output.
*    ls_output-bname     = ls_user-bname.
*    ls_output-deprtmnt  = ls_user-department.
*    ls_output-class     = ls_user-class.
*    ls_output-confnum   = ls_user-nr_conflicts.
*    ls_output-mitinum   = ls_user-nr_mitigated.
*    ls_output-conid     = ls_conflict-conid.
*    ls_output-mitigated = ls_usercon-mitigated.
*    ls_output-origin    = ls_usercon-origin.
*
**=== MIDDLE LOOP: OPT-2 parallel cursor on it_confun ===
*    LOOP AT it_confun INTO ls_confun FROM lv_cur_confun.
*      IF ls_confun-conindex <> ls_usercon-conindex.
*        EXIT.
*      ENDIF.
*
*      READ TABLE it_function INTO ls_function
*        WITH TABLE KEY aid      = i_analysis_run
*                       funindex = ls_confun-funindex.
*      CHECK sy-subrc = 0.
*      ls_output-funid = ls_function-funid.
*
**     OPT-3: binary search to start position in fprprof
*      READ TABLE it_fprprof INTO ls_fprprof
*        WITH KEY userindex = ls_usercon-userindex
*                 funindex  = ls_confun-funindex
*        BINARY SEARCH.
*      IF sy-subrc <> 0.
*        CONTINUE.
*      ENDIF.
*      lv_fpr_start = sy-tabix.
*
**=== INNER LOOP: OPT-3 bounded loop on it_fprprof ===
*      LOOP AT it_fprprof INTO ls_fprprof FROM lv_fpr_start.
*        IF ls_fprprof-userindex <> ls_usercon-userindex
*        OR ls_fprprof-funindex  <> ls_confun-funindex.
*          EXIT.
*        ENDIF.
*
*        READ TABLE it_sysmap INTO ls_sysmap
*          WITH TABLE KEY sysindex = ls_fprprof-sys.
*        ls_output-sysid = ls_sysmap-sysid.
*
*        READ TABLE it_profiles INTO ls_profiles
*          WITH TABLE KEY aid      = i_analysis_run
*                         profindex = ls_fprprof-profileindex.
*        IF sy-subrc = 0.
*          ls_output-profname = ls_profiles-profname.
*        ELSE.
*          CLEAR ls_output-profname.
*        ENDIF.
*
*        CLEAR: ls_profrole, ls_roles, lv_comp_agr,
*               lf_direct_role, lf_profauth,
*               ls_output-agr_name, ls_output-comp_agr.
*
*        READ TABLE it_profrole INTO ls_profrole
*          WITH KEY profindex = ls_fprprof-profileindex.
*        IF sy-subrc = 0.
*          READ TABLE it_roles INTO ls_roles
*            WITH KEY roleindex = ls_profrole-roleindex.
*          IF sy-subrc = 0.
*            ls_output-agr_name = ls_roles-agr_name.
*          ENDIF.
*
**         PC-2: parallel cursor on lt_comprole_pc (sorted BY userindex roleindex)
**         LIVE used: LOOP AT it_comprole WHERE userindex=x AND roleindex=x
**         which scanned all rows with matching roleindex and checked userindex.
**         NEW: binary search to first matching row, EXIT on key change.
*          READ TABLE lt_comprole_pc INTO ls_comprole
*            WITH KEY userindex = ls_usercon-userindex
*                     roleindex = ls_profrole-roleindex
*            BINARY SEARCH.
*
*          IF sy-subrc = 0.
*            lv_compr_start = sy-tabix.
*
*            LOOP AT lt_comprole_pc INTO ls_comprole FROM lv_compr_start.
*              IF ls_comprole-userindex <> ls_usercon-userindex
*              OR ls_comprole-roleindex <> ls_profrole-roleindex.
*                EXIT.                     "PC-2: past key block, stop
*              ENDIF.
*
*              READ TABLE it_roles INTO ls_roles
*                WITH KEY roleindex = ls_comprole-compindex.
*              IF sy-subrc = 0.
*                ls_output-comp_agr = ls_roles-agr_name.
*                lv_comp_agr        = ls_output-comp_agr.
*                IF if_direct_assn_only = 'X'.
*                  READ TABLE lt_comprole_pc INTO ls_comprole
*                    WITH KEY userindex = ls_usercon-userindex
*                             roleindex = ls_profrole-roleindex
*                             compindex = 0
*                    BINARY SEARCH.
*                  IF sy-subrc = 0.
*                    lf_direct_role = 'X'.
*                  ELSE.
*                    CLEAR lf_direct_role.
*                  ENDIF.
*                ELSE.
*                  lf_direct_role = 'X'.
*                ENDIF.
*              ENDIF.
*            ENDLOOP.                      "lt_comprole_pc parallel cursor
*
*          ELSE.
**           No comprole entry — profile directly assigned
*            lf_profauth = 'X'.
*          ENDIF.
*
*        ELSE.
*          lf_profauth = 'X'.
*        ENDIF.
*
*        IF if_direct_assn_only = 'X'
*          AND lf_direct_role = space
*          AND lf_profauth    = space.
*          CONTINUE.
*        ENDIF.
*
**       PC-1: in-memory authdet lookup via parallel cursor in METHOD get
*        REFRESH lt_authdet.
*        CALL METHOD lcl_authdet_bulk_cache=>get
*          EXPORTING
*            i_sys          = ls_fprprof-sys
*            i_funindex     = ls_confun-funindex
*            i_profileindex = ls_fprprof-profileindex
*          CHANGING
*            ct_authdet     = lt_authdet[].
*
*        LOOP AT lt_authdet INTO ls_authdet.
*          MOVE-CORRESPONDING ls_authdet TO ls_output.
*          ls_output-bname     = ls_user-bname.
*          ls_output-sysid     = ls_sysmap-sysid.
*          ls_output-conid     = ls_conflict-conid.
*          ls_output-funid     = ls_function-funid.
*          ls_output-profname  = ls_profiles-profname.
*          ls_output-comp_agr  = lv_comp_agr.
*          ls_output-confnum   = ls_user-nr_conflicts.
*          ls_output-mitinum   = ls_user-nr_mitigated.
*          ls_output-mitigated = ls_usercon-mitigated.
*          ls_output-origin    = ls_usercon-origin.
*
*          INSERT ls_output INTO TABLE lt_dedup.
*          IF sy-subrc = 0.
*            APPEND ls_output TO lt_output.
*          ENDIF.
*        ENDLOOP.
*
*      ENDLOOP.   " it_fprprof — OPT-3 bounded cursor
*    ENDLOOP.     " it_confun  — OPT-2 parallel cursor
*  ENDLOOP.       " it_usercon — outer driver
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_output_old_se
**
** PC-3: Same parallel cursor fix on it_comprole as PC-2 above.
** Old SE path (swresupr-based). All other logic unchanged from Phase 4.
**======================================================================*
*FORM get_output_old_se
*  TABLES
*    lt_output     STRUCTURE /psyng/sw_outputdet
*  USING
*    i_analysis_run       TYPE /psyng/seresid
*    if_direct_assn_only  TYPE flag
*    it_user              TYPE ty_th_users
*    it_usercon           TYPE ty_tt_usercon
*    it_conflict          TYPE ty_th_conflict
*    it_confun            TYPE ty_tt_confun
*    it_function          TYPE ty_th_function
*    it_profiles          TYPE ty_th_profiles
*    it_usrprof           TYPE ty_tt_usrprof
*    it_funprofile        TYPE ty_tt_fprprof
*    it_profrole          TYPE ty_ts_profrole
*    it_roles             TYPE ty_ts_roles
*    it_comprole          TYPE ty_ts_comprole
*    it_sysmap            TYPE ty_th_sysmap.
*
*  DATA: ls_user        TYPE ty_users,
*        ls_conflict    TYPE /psyng/swresicon,
*        ls_function    TYPE /psyng/swresifun,
*        ls_profiles    TYPE /psyng/swresipro,
*        ls_usrprof     TYPE /psyng/swresupr,
*        ls_funprofile  TYPE /psyng/swresfpr,
*        ls_profrole    TYPE /psyng/swresprol,
*        ls_roles       TYPE /psyng/swresirol,
*        ls_comprole    TYPE /psyng/swresucom,
*        ls_usercon     TYPE /psyng/swrescon,
*        ls_confun      TYPE /psyng/swrescfun,
*        ls_sysmap      TYPE /psyng/swresisys,
*        ls_output      LIKE LINE OF lt_output,
*        ls_authdet     TYPE /psyng/seres_authdetail,
*        lt_authdet     TYPE TABLE OF /psyng/seres_authdetail,
*        lt_dedup       TYPE HASHED TABLE OF /psyng/sw_outputdet
*                        WITH UNIQUE KEY bname conid sysid funid
*                                        comp_agr agr_name profname
*                                        tcode auth object field von bis,
*        lv_comp_agr    TYPE agr_define-agr_name,
*        lf_direct_role TYPE flag,
*        lf_profauth    TYPE flag,
*        lv_cur_confun  TYPE i,
*        lv_fpr_start   TYPE i,
*        lv_prev_con    TYPE /psyng/swrescon-conindex,
*        lv_prev_uix    TYPE /psyng/swrescon-userindex,
*        lv_user_ok     TYPE flag,
*        lv_con_ok      TYPE flag,
**       PC-3: STANDARD TABLE — allows SORT command (SORTED TABLE does not)
*        lt_comprole_pc TYPE STANDARD TABLE OF /psyng/swresucom,
*        lv_compr_start TYPE i.            "PC-3: cursor position
*
*  SORT: it_usercon    BY conindex userindex,
*        it_confun     BY conindex,
*        it_usrprof    BY sys userindex profileindex,
*        it_funprofile BY userindex funindex profileindex.
*
** PC-3: build local comprole copy sorted by userindex roleindex
*  lt_comprole_pc[] = it_comprole[].
*  SORT lt_comprole_pc BY userindex roleindex.
*
*  CLEAR: lv_prev_con, lv_prev_uix, lv_user_ok, lv_con_ok.
*  lv_cur_confun = 1.
*
**=== OUTER LOOP ===
*  LOOP AT it_usercon INTO ls_usercon.
*
*    IF ls_usercon-userindex <> lv_prev_uix.
*      lv_prev_uix = ls_usercon-userindex.
*      READ TABLE it_user INTO ls_user
*        WITH TABLE KEY aid       = i_analysis_run
*                       userindex = ls_usercon-userindex.
*      IF sy-subrc = 0.
*        lv_user_ok = 'X'.
*      ELSE.
*        CLEAR lv_user_ok.
*      ENDIF.
*    ENDIF.
*    CHECK lv_user_ok = 'X'.
*
*    IF ls_usercon-conindex <> lv_prev_con.
*      lv_prev_con = ls_usercon-conindex.
*      READ TABLE it_conflict INTO ls_conflict
*        WITH TABLE KEY aid      = i_analysis_run
*                       conindex = ls_usercon-conindex.
*      IF sy-subrc = 0.
*        lv_con_ok = 'X'.
*      ELSE.
*        CLEAR lv_con_ok.
*      ENDIF.
*      READ TABLE it_confun INTO ls_confun
*        WITH KEY conindex = ls_usercon-conindex BINARY SEARCH.
*      IF sy-subrc = 0.
*        lv_cur_confun = sy-tabix.
*      ELSE.
*        lv_cur_confun = 0.
*      ENDIF.
*    ENDIF.
*    CHECK lv_con_ok = 'X'.
*    CHECK lv_cur_confun > 0.
*
*    CLEAR ls_output.
*    ls_output-bname     = ls_user-bname.
*    ls_output-deprtmnt  = ls_user-department.
*    ls_output-class     = ls_user-class.
*    ls_output-confnum   = ls_user-nr_conflicts.
*    ls_output-mitinum   = ls_user-nr_mitigated.
*    ls_output-conid     = ls_conflict-conid.
*    ls_output-mitigated = ls_usercon-mitigated.
*    ls_output-origin    = ls_usercon-origin.
*
**=== MIDDLE LOOP: OPT-2 parallel cursor on it_confun ===
*    LOOP AT it_confun INTO ls_confun FROM lv_cur_confun.
*      IF ls_confun-conindex <> ls_usercon-conindex.
*        EXIT.
*      ENDIF.
*
*      READ TABLE it_function INTO ls_function
*        WITH TABLE KEY aid      = i_analysis_run
*                       funindex = ls_confun-funindex.
*      CHECK sy-subrc = 0.
*      ls_output-funid = ls_function-funid.
*
**     OPT-3: binary search on funprofile
*      READ TABLE it_funprofile INTO ls_funprofile
*        WITH KEY userindex = ls_usercon-userindex
*                 funindex  = ls_confun-funindex
*        BINARY SEARCH.
*      IF sy-subrc <> 0.
*        CONTINUE.
*      ENDIF.
*      lv_fpr_start = sy-tabix.
*
**=== INNER LOOP: OPT-3 bounded on it_funprofile ===
*      LOOP AT it_funprofile INTO ls_funprofile FROM lv_fpr_start.
*        IF ls_funprofile-userindex <> ls_usercon-userindex
*        OR ls_funprofile-funindex  <> ls_confun-funindex.
*          EXIT.
*        ENDIF.
*
*        READ TABLE it_usrprof INTO ls_usrprof
*          WITH KEY sys          = ls_funprofile-sys
*                   userindex    = ls_usercon-userindex
*                   profileindex = ls_funprofile-profileindex
*          BINARY SEARCH.
*        CHECK sy-subrc = 0.
*
*        READ TABLE it_sysmap INTO ls_sysmap
*          WITH TABLE KEY sysindex = ls_usrprof-sys.
*        ls_output-sysid = ls_sysmap-sysid.
*
*        READ TABLE it_profiles INTO ls_profiles
*          WITH TABLE KEY aid      = i_analysis_run
*                         profindex = ls_usrprof-profileindex.
*        IF sy-subrc = 0.
*          ls_output-profname = ls_profiles-profname.
*        ELSE.
*          CLEAR ls_output-profname.
*        ENDIF.
*
*        CLEAR: ls_profrole, ls_roles, lv_comp_agr,
*               lf_direct_role, lf_profauth,
*               ls_output-agr_name, ls_output-comp_agr.
*
*        READ TABLE it_profrole INTO ls_profrole
*          WITH KEY profindex = ls_usrprof-profileindex.
*        IF sy-subrc = 0.
*          READ TABLE it_roles INTO ls_roles
*            WITH KEY roleindex = ls_profrole-roleindex.
*          IF sy-subrc = 0.
*            ls_output-agr_name = ls_roles-agr_name.
*          ENDIF.
*
**         PC-3: parallel cursor on lt_comprole_pc (sorted BY userindex roleindex)
*          READ TABLE lt_comprole_pc INTO ls_comprole
*            WITH KEY userindex = ls_usercon-userindex
*                     roleindex = ls_profrole-roleindex
*            BINARY SEARCH.
*
*          IF sy-subrc = 0.
*            lv_compr_start = sy-tabix.
*
*            LOOP AT lt_comprole_pc INTO ls_comprole FROM lv_compr_start.
*              IF ls_comprole-userindex <> ls_usercon-userindex
*              OR ls_comprole-roleindex <> ls_profrole-roleindex.
*                EXIT.                     "PC-3: past key block, stop
*              ENDIF.
*
*              READ TABLE it_roles INTO ls_roles
*                WITH KEY roleindex = ls_comprole-compindex.
*              IF sy-subrc = 0.
*                ls_output-comp_agr = ls_roles-agr_name.
*                lv_comp_agr        = ls_output-comp_agr.
*                IF if_direct_assn_only = 'X'.
*                  READ TABLE lt_comprole_pc INTO ls_comprole
*                    WITH KEY userindex = ls_usercon-userindex
*                             roleindex = ls_profrole-roleindex
*                             compindex = 0
*                    BINARY SEARCH.
*                  IF sy-subrc = 0.
*                    lf_direct_role = 'X'.
*                  ELSE.
*                    CLEAR lf_direct_role.
*                  ENDIF.
*                ELSE.
*                  lf_direct_role = 'X'.
*                ENDIF.
*              ENDIF.
*            ENDLOOP.                      "lt_comprole_pc parallel cursor
*            CLEAR ls_output-comp_agr.
*
*          ELSE.
*            lf_profauth = 'X'.
*          ENDIF.
*
*        ELSE.
*          lf_profauth = 'X'.
*        ENDIF.
*
*        IF if_direct_assn_only = 'X'
*          AND lf_direct_role = space
*          AND lf_profauth    = space.
*          CONTINUE.
*        ENDIF.
*
**       PC-1: in-memory authdet via parallel cursor in METHOD get
*        REFRESH lt_authdet.
*        CALL METHOD lcl_authdet_bulk_cache=>get
*          EXPORTING
*            i_sys          = ls_usrprof-sys
*            i_funindex     = ls_confun-funindex
*            i_profileindex = ls_usrprof-profileindex
*          CHANGING
*            ct_authdet     = lt_authdet[].
*
*        LOOP AT lt_authdet INTO ls_authdet.
*          MOVE-CORRESPONDING ls_authdet TO ls_output.
*          ls_output-bname     = ls_user-bname.
*          ls_output-sysid     = ls_sysmap-sysid.
*          ls_output-conid     = ls_conflict-conid.
*          ls_output-funid     = ls_function-funid.
*          ls_output-profname  = ls_profiles-profname.
*          ls_output-comp_agr  = lv_comp_agr.
*          ls_output-confnum   = ls_user-nr_conflicts.
*          ls_output-mitinum   = ls_user-nr_mitigated.
*          ls_output-mitigated = ls_usercon-mitigated.
*          ls_output-origin    = ls_usercon-origin.
*
*          INSERT ls_output INTO TABLE lt_dedup.
*          IF sy-subrc = 0.
*            APPEND ls_output TO lt_output.
*          ENDIF.
*        ENDLOOP.
*
*      ENDLOOP.   " it_funprofile — OPT-3 bounded cursor
*    ENDLOOP.     " it_confun     — OPT-2 parallel cursor
*  ENDLOOP.       " it_usercon    — outer driver
*
*ENDFORM.
*
*
**======================================================================*
** FORM get_analy_res_det  — UNCHANGED from live Phase 4
**======================================================================*
*FORM get_analy_res_det
*  TABLES
*    it_users             STRUCTURE /psyng/sw_userlist
*    et_users             STRUCTURE /psyng/userconcount
*    lt_output            STRUCTURE /psyng/sw_outputdet
*    et_return            STRUCTURE bapiret2
*  USING
*    i_analysis_run       TYPE /psyng/seresid
*    if_exclude_mitigated TYPE flag
*    if_direct_assn_only  TYPE flag
*  CHANGING
*    e_result_count       TYPE i.
*
*  DATA: l_new_se_vrs  TYPE flag,
*        lf_continue   TYPE flag,
*        lv_fpr_aid    TYPE /psyng/seresid,
*        lt_user       TYPE ty_th_users,
*        lr_userindex  TYPE ty_r_userindex,
*        lt_usercon    TYPE ty_tt_usercon,
*        lt_conflict   TYPE ty_th_conflict,
*        lt_confun     TYPE ty_tt_confun,
*        lt_function   TYPE ty_th_function,
*        lr_funindex   TYPE ty_r_funindex,
*        lt_fprprof    TYPE ty_tt_fprprof,
*        lt_usrprof    TYPE ty_tt_usrprof,
*        lt_funprofile TYPE ty_tt_fprprof,
*        lt_profiles   TYPE ty_th_profiles,
*        lr_profindex  TYPE ty_r_profindex,
*        lr_sys        TYPE ty_r_sys,
*        lt_profrole   TYPE ty_ts_profrole,
*        lt_roles      TYPE ty_ts_roles,
*        lt_comprole   TYPE ty_ts_comprole,
*        lt_sysmap     TYPE ty_th_sysmap.
*
*  CLEAR l_new_se_vrs.
*  SELECT SINGLE aid INTO lv_fpr_aid
*    FROM /psyng/swresfpr WHERE aid = i_analysis_run.
*  IF sy-subrc = 0.
*    l_new_se_vrs = 'X'.
*  ENDIF.
*
*  SELECT * FROM /psyng/swresisys INTO TABLE lt_sysmap
*    WHERE aid = i_analysis_run.
*
*  lf_continue = 'X'.
*
*  PERFORM get_analy_res_users
*    TABLES  it_users et_return
*    USING   i_analysis_run
*    CHANGING lt_user lr_userindex lf_continue.
*
*  CHECK lf_continue = 'X'.
*
*  PERFORM get_analy_res_conflicts
*    TABLES  et_users et_return
*    USING   i_analysis_run if_exclude_mitigated lt_user lr_userindex
*    CHANGING lt_usercon lt_conflict lt_confun lt_function
*             lr_funindex e_result_count.
*
*  CHECK NOT lt_usercon[] IS INITIAL.
*
*  PERFORM get_analy_res_profiles
*    USING   i_analysis_run l_new_se_vrs lt_usercon
*            lr_funindex lr_userindex
*    CHANGING lt_fprprof lt_usrprof lt_funprofile lt_profiles
*             lr_profindex lr_sys.
*
*  PERFORM get_analy_res_roles
*    USING   i_analysis_run l_new_se_vrs lt_fprprof lt_usrprof
*            lr_userindex lr_sys
*    CHANGING lt_profrole lt_roles lt_comprole.
*
*  IF l_new_se_vrs = 'X'.
*    CALL METHOD lcl_authdet_bulk_cache=>init
*      EXPORTING
*        i_aid      = i_analysis_run
*        it_fprprof = lt_fprprof
*        it_sysmap  = lt_sysmap.
*  ELSE.
*    CALL METHOD lcl_authdet_bulk_cache=>init
*      EXPORTING
*        i_aid      = i_analysis_run
*        it_fprprof = lt_funprofile
*        it_sysmap  = lt_sysmap.
*  ENDIF.
*
*  IF l_new_se_vrs = 'X'.
*    PERFORM get_output_new_se
*      TABLES  lt_output
*      USING   i_analysis_run if_direct_assn_only
*              lt_user lt_usercon lt_conflict lt_confun lt_function
*              lt_profiles lt_fprprof lt_profrole lt_roles
*              lt_comprole lt_sysmap.
*  ELSE.
*    PERFORM get_output_old_se
*      TABLES  lt_output
*      USING   i_analysis_run if_direct_assn_only
*              lt_user lt_usercon lt_conflict lt_confun lt_function
*              lt_profiles lt_usrprof lt_funprofile lt_profrole lt_roles
*              lt_comprole lt_sysmap.
*  ENDIF.
*
*  SORT lt_output BY bname conid sysid funid.
*
*  CALL METHOD lcl_authdet_bulk_cache=>clear.
*
*  FREE: lt_user,
*        lt_usercon,
*        lt_conflict,
*        lt_confun,
*        lt_function,
*        lt_fprprof,
*        lt_usrprof,
*        lt_funprofile,
*        lt_profiles,
*        lt_profrole,
*        lt_roles,
*        lt_comprole,
*        lt_sysmap.
*
*ENDFORM.


"CHATGPT
*&---------------------------------------------------------------------*
*&  Include           /PSYNG/LSW_API_IMPF02
*&  Function Group    /PSYNG/SW_API_IMP
*&  Description       SE API - Analysis Result Detail Output Optimized
*&---------------------------------------------------------------------*
*&  PN-17852 Performance Optimization
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&  Include           /PSYNG/LSW_API_IMPF02
*&  Function Group    /PSYNG/SW_API_IMP
*&  Description       SE API - Analysis Result Detail Output Optimized
*&---------------------------------------------------------------------*
*&  PN-17852 Performance Optimization
*&---------------------------------------------------------------------*

*======================================================================*
* CLASS lcl_authdet_bulk_cache
*======================================================================*
CLASS lcl_authdet_bulk_cache DEFINITION.
  PUBLIC SECTION.

    CLASS-METHODS init
      IMPORTING
        i_aid      TYPE /psyng/seresid
        it_fprprof TYPE ty_tt_fprprof
        it_sysmap  TYPE ty_th_sysmap.

    CLASS-METHODS get
      IMPORTING
        i_sys          TYPE /psyng/swresfpr-sys
        i_funindex     TYPE /psyng/swresfpr-funindex
        i_profileindex TYPE /psyng/swresfpr-profileindex
      CHANGING
        ct_authdet     TYPE ty_tt_authdetail.

    CLASS-METHODS clear.

    CLASS-DATA gf_initialized TYPE flag.

  PRIVATE SECTION.

    CLASS-DATA gt_bulk TYPE STANDARD TABLE OF ty_caut_flat.

ENDCLASS.


CLASS lcl_authdet_bulk_cache IMPLEMENTATION.

  METHOD init.

    DATA: lt_caut       TYPE TABLE OF /psyng/swrescaut,
          ls_caut       TYPE /psyng/swrescaut,
          ls_fpr        TYPE /psyng/swresfpr,
          lt_fpr_key    TYPE ty_tt_fprprof,
          ls_flat       TYPE ty_caut_flat,
          ls_sysmap     TYPE /psyng/swresisys,
          lt_idx_tcode  TYPE HASHED TABLE OF /psyng/swresitcd
                        WITH UNIQUE KEY tcodeindex,
          lt_idx_object TYPE HASHED TABLE OF /psyng/swresiobj
                        WITH UNIQUE KEY objectindex,
          lt_idx_field  TYPE HASHED TABLE OF /psyng/swresifld
                        WITH UNIQUE KEY fieldindex,
          lt_idx_auth   TYPE HASHED TABLE OF /psyng/swresiaut
                        WITH UNIQUE KEY authindex,
          lt_idx_vba    TYPE HASHED TABLE OF /psyng/swresvba
                        WITH UNIQUE KEY vbaindex,
          ls_tcode      TYPE /psyng/swresitcd,
          ls_object     TYPE /psyng/swresiobj,
          ls_field      TYPE /psyng/swresifld,
          ls_auth       TYPE /psyng/swresiaut,
          ls_vba        TYPE /psyng/swresvba,
          ls_profile    TYPE /psyng/swresipro,
          ls_function   TYPE /psyng/swresifun,
          lt_profiles   TYPE HASHED TABLE OF /psyng/swresipro
                        WITH UNIQUE KEY aid profindex,
          lt_functions  TYPE HASHED TABLE OF /psyng/swresifun
                        WITH UNIQUE KEY aid funindex,
          lv_data       TYPE string,
          lt_records    TYPE TABLE OF string,
          lv_rec        TYPE string,
          BEGIN OF ls_authdet_s,
            tcodeindex  TYPE string,
            objectindex TYPE string,
            fieldindex  TYPE string,
            vbaindex    TYPE string,
            authindex   TYPE string,
          END OF ls_authdet_s,
          BEGIN OF ls_authdet,
            tcodeindex  TYPE i,
            objectindex TYPE i,
            fieldindex  TYPE i,
            vbaindex    TYPE i,
            authindex   TYPE i,
          END OF ls_authdet,
          lv_cur_sys    TYPE /psyng/swrescaut-sys,
          lv_cur_fun    TYPE /psyng/swrescaut-funindex,
          lv_cur_prof   TYPE /psyng/swrescaut-profileindex.

    REFRESH gt_bulk.
    CLEAR gf_initialized.

    CHECK NOT it_fprprof[] IS INITIAL.

*-----------------------------------------------------------------------
* Exact auth-cache key selection.
* Avoids cross-combination over-fetch from SYS x FUNINDEX x PROFILEINDEX.
*-----------------------------------------------------------------------
    lt_fpr_key[] = it_fprprof[].

    SORT lt_fpr_key BY sys funindex profileindex.
    DELETE ADJACENT DUPLICATES FROM lt_fpr_key
      COMPARING sys funindex profileindex.

    CHECK NOT lt_fpr_key[] IS INITIAL.

    SELECT *
      FROM /psyng/swrescaut
      INTO TABLE lt_caut
      FOR ALL ENTRIES IN lt_fpr_key
      WHERE aid          = i_aid
        AND sys          = lt_fpr_key-sys
        AND funindex     = lt_fpr_key-funindex
        AND profileindex = lt_fpr_key-profileindex.

    CHECK NOT lt_caut[] IS INITIAL.

    SORT lt_caut BY sys funindex profileindex dataindex.

*-----------------------------------------------------------------------
* Index texts.
*-----------------------------------------------------------------------
    SELECT *
      FROM /psyng/swresitcd
      INTO TABLE lt_idx_tcode
      WHERE aid = i_aid.

    SELECT *
      FROM /psyng/swresiobj
      INTO TABLE lt_idx_object
      WHERE aid = i_aid.

    SELECT *
      FROM /psyng/swresifld
      INTO TABLE lt_idx_field
      WHERE aid = i_aid.

    SELECT *
      FROM /psyng/swresiaut
      INTO TABLE lt_idx_auth
      WHERE aid = i_aid.

    SELECT *
      FROM /psyng/swresvba
      INTO TABLE lt_idx_vba.

    SELECT *
      FROM /psyng/swresipro
      INTO TABLE lt_profiles
      WHERE aid = i_aid.

    SELECT *
      FROM /psyng/swresifun
      INTO TABLE lt_functions
      WHERE aid = i_aid.

*-----------------------------------------------------------------------
* Build flattened authorization cache.
*-----------------------------------------------------------------------
    CLEAR: lv_cur_sys, lv_cur_fun, lv_cur_prof, lv_data.

    LOOP AT lt_caut INTO ls_caut.

      IF ls_caut-sys          <> lv_cur_sys
      OR ls_caut-funindex     <> lv_cur_fun
      OR ls_caut-profileindex <> lv_cur_prof.

        IF lv_data IS NOT INITIAL.

          REFRESH lt_records.
          SPLIT lv_data AT '-' INTO TABLE lt_records.

          READ TABLE lt_functions INTO ls_function
            WITH TABLE KEY aid = i_aid funindex = lv_cur_fun.

          READ TABLE lt_profiles INTO ls_profile
            WITH TABLE KEY aid = i_aid profindex = lv_cur_prof.

          READ TABLE it_sysmap INTO ls_sysmap
            WITH TABLE KEY sysindex = lv_cur_sys.

          LOOP AT lt_records INTO lv_rec.

            CHECK lv_rec IS NOT INITIAL.

            SPLIT lv_rec AT ',' INTO
              ls_authdet_s-tcodeindex
              ls_authdet_s-objectindex
              ls_authdet_s-fieldindex
              ls_authdet_s-vbaindex
              ls_authdet_s-authindex.

            ls_authdet-tcodeindex  = ls_authdet_s-tcodeindex.
            ls_authdet-objectindex = ls_authdet_s-objectindex.
            ls_authdet-fieldindex  = ls_authdet_s-fieldindex.
            ls_authdet-vbaindex    = ls_authdet_s-vbaindex.
            ls_authdet-authindex   = ls_authdet_s-authindex.

            CLEAR ls_flat.
            ls_flat-sys          = lv_cur_sys.
            ls_flat-funindex     = lv_cur_fun.
            ls_flat-profileindex = lv_cur_prof.
            ls_flat-funid        = ls_function-funid.
            ls_flat-profname     = ls_profile-profname.
            ls_flat-sysid        = ls_sysmap-sysid.

            READ TABLE lt_idx_tcode INTO ls_tcode
              WITH TABLE KEY tcodeindex = ls_authdet-tcodeindex.

            READ TABLE lt_idx_object INTO ls_object
              WITH TABLE KEY objectindex = ls_authdet-objectindex.

            READ TABLE lt_idx_field INTO ls_field
              WITH TABLE KEY fieldindex = ls_authdet-fieldindex.

            READ TABLE lt_idx_auth INTO ls_auth
              WITH TABLE KEY authindex = ls_authdet-authindex.

            READ TABLE lt_idx_vba INTO ls_vba
              WITH TABLE KEY vbaindex = ls_authdet-vbaindex.

            ls_flat-tcode  = ls_tcode-tcode.
            ls_flat-object = ls_object-object.
            ls_flat-field  = ls_field-field.
            ls_flat-auth   = ls_auth-auth.
            ls_flat-von    = ls_vba-von.
            ls_flat-bis    = ls_vba-bis.
            ls_flat-abb    = ls_vba-abb.

            APPEND ls_flat TO gt_bulk.

          ENDLOOP.

        ENDIF.

        lv_cur_sys  = ls_caut-sys.
        lv_cur_fun  = ls_caut-funindex.
        lv_cur_prof = ls_caut-profileindex.

        CLEAR lv_data.

      ENDIF.

      CONCATENATE lv_data ls_caut-data INTO lv_data.

    ENDLOOP.

    IF lv_data IS NOT INITIAL.

      REFRESH lt_records.
      SPLIT lv_data AT '-' INTO TABLE lt_records.

      READ TABLE lt_functions INTO ls_function
        WITH TABLE KEY aid = i_aid funindex = lv_cur_fun.

      READ TABLE lt_profiles INTO ls_profile
        WITH TABLE KEY aid = i_aid profindex = lv_cur_prof.

      READ TABLE it_sysmap INTO ls_sysmap
        WITH TABLE KEY sysindex = lv_cur_sys.

      LOOP AT lt_records INTO lv_rec.

        CHECK lv_rec IS NOT INITIAL.

        SPLIT lv_rec AT ',' INTO
          ls_authdet_s-tcodeindex
          ls_authdet_s-objectindex
          ls_authdet_s-fieldindex
          ls_authdet_s-vbaindex
          ls_authdet_s-authindex.

        ls_authdet-tcodeindex  = ls_authdet_s-tcodeindex.
        ls_authdet-objectindex = ls_authdet_s-objectindex.
        ls_authdet-fieldindex  = ls_authdet_s-fieldindex.
        ls_authdet-vbaindex    = ls_authdet_s-vbaindex.
        ls_authdet-authindex   = ls_authdet_s-authindex.

        CLEAR ls_flat.
        ls_flat-sys          = lv_cur_sys.
        ls_flat-funindex     = lv_cur_fun.
        ls_flat-profileindex = lv_cur_prof.
        ls_flat-funid        = ls_function-funid.
        ls_flat-profname     = ls_profile-profname.
        ls_flat-sysid        = ls_sysmap-sysid.

        READ TABLE lt_idx_tcode INTO ls_tcode
          WITH TABLE KEY tcodeindex = ls_authdet-tcodeindex.

        READ TABLE lt_idx_object INTO ls_object
          WITH TABLE KEY objectindex = ls_authdet-objectindex.

        READ TABLE lt_idx_field INTO ls_field
          WITH TABLE KEY fieldindex = ls_authdet-fieldindex.

        READ TABLE lt_idx_auth INTO ls_auth
          WITH TABLE KEY authindex = ls_authdet-authindex.

        READ TABLE lt_idx_vba INTO ls_vba
          WITH TABLE KEY vbaindex = ls_authdet-vbaindex.

        ls_flat-tcode  = ls_tcode-tcode.
        ls_flat-object = ls_object-object.
        ls_flat-field  = ls_field-field.
        ls_flat-auth   = ls_auth-auth.
        ls_flat-von    = ls_vba-von.
        ls_flat-bis    = ls_vba-bis.
        ls_flat-abb    = ls_vba-abb.

        APPEND ls_flat TO gt_bulk.

      ENDLOOP.

    ENDIF.

    SORT gt_bulk BY sys funindex profileindex.

    FREE: lt_caut,
          lt_fpr_key,
          lt_records,
          lt_idx_tcode,
          lt_idx_object,
          lt_idx_field,
          lt_idx_auth,
          lt_idx_vba,
          lt_profiles,
          lt_functions.

    gf_initialized = 'X'.

  ENDMETHOD.


  METHOD get.

    DATA: ls_flat       TYPE ty_caut_flat,
          ls_authdet    TYPE /psyng/seres_authdetail,
          lv_bulk_start TYPE sy-tabix,
          lv_prev       TYPE sy-tabix.

    READ TABLE gt_bulk INTO ls_flat
      WITH KEY sys          = i_sys
               funindex     = i_funindex
               profileindex = i_profileindex
      BINARY SEARCH.

    IF sy-subrc <> 0.
      RETURN.
    ENDIF.

    lv_bulk_start = sy-tabix.

*   Binary search with duplicates may not return first matching row.
*   Move backward to the beginning of the key block.
    WHILE lv_bulk_start GT 1.

      lv_prev = lv_bulk_start - 1.

      READ TABLE gt_bulk INTO ls_flat INDEX lv_prev.
      IF sy-subrc <> 0.
        EXIT.
      ENDIF.

      IF ls_flat-sys          <> i_sys
      OR ls_flat-funindex     <> i_funindex
      OR ls_flat-profileindex <> i_profileindex.
        EXIT.
      ENDIF.

      lv_bulk_start = lv_prev.

    ENDWHILE.

    LOOP AT gt_bulk INTO ls_flat FROM lv_bulk_start.

      IF ls_flat-sys          <> i_sys
      OR ls_flat-funindex     <> i_funindex
      OR ls_flat-profileindex <> i_profileindex.
        EXIT.
      ENDIF.

      CLEAR ls_authdet.
      ls_authdet-tcode    = ls_flat-tcode.
      ls_authdet-object   = ls_flat-object.
      ls_authdet-field    = ls_flat-field.
      ls_authdet-von      = ls_flat-von.
      ls_authdet-bis      = ls_flat-bis.
      ls_authdet-abb      = ls_flat-abb.
      ls_authdet-auth     = ls_flat-auth.
      ls_authdet-funid    = ls_flat-funid.
      ls_authdet-profname = ls_flat-profname.

      APPEND ls_authdet TO ct_authdet.

    ENDLOOP.

  ENDMETHOD.


  METHOD clear.

    REFRESH gt_bulk.
    CLEAR gf_initialized.

  ENDMETHOD.

ENDCLASS.


*======================================================================*
* FORM get_analy_res_users
*======================================================================*
FORM get_analy_res_users
  TABLES
    it_users             STRUCTURE /psyng/sw_userlist
    et_return            STRUCTURE bapiret2
  USING
    i_analysis_run       TYPE /psyng/seresid
  CHANGING
    et_user              TYPE ty_th_users
    lr_userindex         TYPE ty_r_userindex
    ef_continue          TYPE flag.

  DATA: lt_system     TYPE SORTED TABLE OF /psyng/swresisys
                         WITH UNIQUE KEY sysindex WITH HEADER LINE,
        lt_sysinfo    TYPE TABLE OF /psyng/sw_rfcdes WITH HEADER LINE,
        lt_bname      TYPE TABLE OF /psyng/sw_sel_opts_xubname,
        ls_bname      TYPE /psyng/sw_sel_opts_xubname,
        lt_user1      TYPE TABLE OF usr02,
        lt_rem_users  TYPE TABLE OF usr02,
        lt_lcl_users  TYPE TABLE OF usr02,
        lt_user_keep  TYPE TABLE OF ty_users,
        ls_user       TYPE ty_users,
        lt_user_tmp   TYPE TABLE OF ty_users,
        loc_system    TYPE rfcdest,
        ls_userindex  LIKE LINE OF lr_userindex,
        lt_users_orig TYPE TABLE OF /psyng/sw_userlist,
        ls_users_orig TYPE /psyng/sw_userlist.

  RANGES: lr_uname FOR usr02-bname.

  SORT it_users BY bname.
  DELETE ADJACENT DUPLICATES FROM it_users COMPARING bname.

  lr_uname-sign   = 'I'.
  lr_uname-option = 'CP'.

  LOOP AT it_users.
    lr_uname-low = it_users-bname.
    APPEND lr_uname.
  ENDLOOP.

  IF lr_uname[] IS INITIAL.

    SELECT aid userindex bname nr_conflicts department class nr_mitigated
      FROM /psyng/swresusr
      INTO TABLE et_user
      WHERE aid = i_analysis_run.

  ELSE.

    SELECT aid userindex bname nr_conflicts department class nr_mitigated
      FROM /psyng/swresusr
      INTO TABLE et_user
      WHERE aid = i_analysis_run
        AND bname IN lr_uname.

  ENDIF.

  IF sy-subrc <> 0.
    log et_return 'E' 'NOUSERS' 'No Users match the selection' '' '' ''.
    CLEAR ef_continue.
    RETURN.
  ENDIF.

  IF it_users[] IS NOT INITIAL.

    SELECT *
      FROM /psyng/swresisys
      INTO TABLE lt_system
      WHERE aid = i_analysis_run.

    IF NOT lt_system[] IS INITIAL.

      SELECT *
        FROM /psyng/sw_rfcdes
        INTO TABLE lt_sysinfo
        FOR ALL ENTRIES IN lt_system
        WHERE systid = lt_system-sysid.

    ENDIF.

    CONCATENATE sy-sysid sy-mandt INTO loc_system.

    ls_bname-sign   = 'I'.
    ls_bname-option = 'CP'.

    LOOP AT it_users.
      ls_bname-low = it_users-bname.
      APPEND ls_bname TO lt_bname.
    ENDLOOP.

    lt_users_orig[] = it_users[].
    CLEAR it_users.

    LOOP AT lt_sysinfo.

      IF lt_sysinfo-systid <> loc_system.

        CALL FUNCTION 'RFC_CALLBACK_REJECTED'
          EXCEPTIONS
            OTHERS = 5.

        CALL FUNCTION '/PSYNG/SW_041'
          DESTINATION lt_sysinfo-rfcdest
          EXPORTING
            i_include_locked      = 'X'
            i_include_expired     = 'X'
          TABLES
            et_users              = lt_rem_users
            it_userlist           = lt_bname
          EXCEPTIONS
            communication_failure = 1
            system_failure        = 2
            OTHERS                = 3.           "#EC SAST_CI_GEN_CHECK

        IF sy-subrc = 0.
          APPEND LINES OF lt_rem_users TO lt_user1.
        ELSE.
          log et_return 'W' 'RFCFAIL'
            'RFC user validation failed for system' lt_sysinfo-systid '' ''.
        ENDIF.

      ELSE.

        CALL FUNCTION '/PSYNG/SW_041'
          EXPORTING
            i_include_locked  = 'X'
            i_include_expired = 'X'
          TABLES
            et_users          = lt_lcl_users
            it_userlist       = lt_bname.

        APPEND LINES OF lt_lcl_users TO lt_user1.

      ENDIF.

      FREE: lt_rem_users, lt_lcl_users.

    ENDLOOP.

    SORT lt_user1 BY bname.
    DELETE ADJACENT DUPLICATES FROM lt_user1 COMPARING bname.

    LOOP AT et_user INTO ls_user.

      READ TABLE lt_user1
        WITH KEY bname = ls_user-bname
        BINARY SEARCH
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.
        APPEND ls_user TO lt_user_keep.
      ENDIF.

    ENDLOOP.

    et_user = lt_user_keep[].

    FREE: lt_user1, lt_user_keep.

  ENDIF.

  ls_userindex-sign   = 'I'.
  ls_userindex-option = 'EQ'.

  LOOP AT et_user INTO ls_user.
    ls_userindex-low = ls_user-userindex.
    APPEND ls_userindex TO lr_userindex.
  ENDLOOP.

  IF lt_users_orig[] IS NOT INITIAL.

    lt_user_tmp = et_user.
    SORT lt_user_tmp BY bname.

    LOOP AT lt_users_orig INTO ls_users_orig.

      IF ls_users_orig-bname CS '*' OR ls_users_orig-bname CS '+'.
        CONTINUE.
      ENDIF.

      READ TABLE lt_user_tmp
        WITH KEY bname = ls_users_orig-bname
        BINARY SEARCH
        TRANSPORTING NO FIELDS.

      IF sy-subrc NE 0.
        log_v et_return 'W' 'INVALIDUSER'
          'User' ls_users_orig-bname 'does not exist'
          ls_users_orig-bname ''.
      ENDIF.

    ENDLOOP.

    FREE lt_user_tmp.

  ENDIF.

ENDFORM.


*======================================================================*
* FORM get_analy_res_conflicts
*======================================================================*
FORM get_analy_res_conflicts
  TABLES
    et_users             STRUCTURE /psyng/userconcount
    et_return            STRUCTURE bapiret2
  USING
    i_analysis_run       TYPE /psyng/seresid
    if_exclude_mitigated TYPE flag
    it_user              TYPE ty_th_users
    it_userindex         TYPE ty_r_userindex
  CHANGING
    et_usercon           TYPE ty_tt_usercon
    et_conflict          TYPE ty_th_conflict
    et_confun            TYPE ty_tt_confun
    et_function          TYPE ty_th_function
    lr_funindex          TYPE ty_r_funindex
    e_result_count       TYPE i.

  DATA: ls_user     TYPE ty_users,
        ls_funindex LIKE LINE OF lr_funindex.

  RANGES: lr_uix_all   FOR /psyng/swrescon-userindex,
          lr_uix_chunk FOR /psyng/swrescon-userindex.

  FIELD-SYMBOLS: <confun> TYPE /psyng/swrescfun.

  LOOP AT it_user INTO ls_user.
    et_users-uname = ls_user-bname.
    et_users-count = ls_user-nr_conflicts.
    ADD ls_user-nr_conflicts TO e_result_count.
    APPEND et_users.
  ENDLOOP.

  lr_uix_all[] = it_userindex[].

  WHILE NOT lr_uix_all[] IS INITIAL.

    REFRESH lr_uix_chunk.
    APPEND LINES OF lr_uix_all FROM 1 TO 5000 TO lr_uix_chunk.
    DELETE lr_uix_all FROM 1 TO 5000.

    IF if_exclude_mitigated = 'X'.

      SELECT *
        FROM /psyng/swrescon
        APPENDING TABLE et_usercon
        WHERE aid       = i_analysis_run
          AND userindex IN lr_uix_chunk
          AND mitigated = ''.

    ELSE.

      SELECT *
        FROM /psyng/swrescon
        APPENDING TABLE et_usercon
        WHERE aid       = i_analysis_run
          AND userindex IN lr_uix_chunk.

    ENDIF.

  ENDWHILE.

  CHECK NOT et_usercon[] IS INITIAL.

  SELECT *
    FROM /psyng/swresicon
    INTO TABLE et_conflict
    FOR ALL ENTRIES IN et_usercon
    WHERE aid      = i_analysis_run
      AND conindex = et_usercon-conindex.

  SELECT *
    FROM /psyng/swrescfun
    INTO TABLE et_confun
    FOR ALL ENTRIES IN et_usercon
    WHERE aid      = i_analysis_run
      AND conindex = et_usercon-conindex.

  IF NOT et_confun[] IS INITIAL.

    SELECT *
      FROM /psyng/swresifun
      INTO TABLE et_function
      FOR ALL ENTRIES IN et_confun
      WHERE aid      = i_analysis_run
        AND funindex = et_confun-funindex.

  ENDIF.

  ls_funindex-sign   = 'I'.
  ls_funindex-option = 'EQ'.

  LOOP AT et_confun ASSIGNING <confun>.
    ls_funindex-low = <confun>-funindex.
    APPEND ls_funindex TO lr_funindex.
  ENDLOOP.

  SORT lr_funindex BY low.
  DELETE ADJACENT DUPLICATES FROM lr_funindex COMPARING low.

ENDFORM.


*======================================================================*
* FORM get_analy_res_profiles
*======================================================================*
FORM get_analy_res_profiles
  USING
    i_analysis_run TYPE /psyng/seresid
    i_new_se_vrs   TYPE flag
    it_usercon     TYPE ty_tt_usercon
    it_funindex    TYPE ty_r_funindex
    it_userindex   TYPE ty_r_userindex
  CHANGING
    et_fprprof     TYPE ty_tt_fprprof
    et_usrprof     TYPE ty_tt_usrprof
    et_funprofile  TYPE ty_tt_fprprof
    et_profiles    TYPE ty_th_profiles
    lr_profindex   TYPE ty_r_profindex
    lr_sys         TYPE ty_r_sys.

  DATA: ls_usrprof    TYPE /psyng/swresupr,
        ls_profindex  LIKE LINE OF lr_profindex,
        ls_funprofile TYPE /psyng/swresfpr,
        ls_sys        LIKE LINE OF lr_sys,
        lt_usrprof2   TYPE TABLE OF /psyng/swresupr,
        lr_pix_all    LIKE lr_profindex,
        lr_pix_part   LIKE lr_profindex.

  IF i_new_se_vrs = 'X'.

    IF it_userindex[] IS NOT INITIAL.

      SELECT *
        FROM /psyng/swresfpr
        INTO TABLE et_fprprof
        FOR ALL ENTRIES IN it_userindex
        WHERE aid       = i_analysis_run
          AND userindex = it_userindex-low.

    ENDIF.

  ELSE.

    IF it_userindex[] IS NOT INITIAL.

      SELECT *
        FROM /psyng/swresupr
        INTO CORRESPONDING FIELDS OF TABLE et_usrprof
        FOR ALL ENTRIES IN it_userindex
        WHERE aid       = i_analysis_run
          AND userindex = it_userindex-low.

    ENDIF.

  ENDIF.

  ls_profindex-sign   = 'I'.
  ls_profindex-option = 'EQ'.
  ls_sys-sign         = 'I'.
  ls_sys-option       = 'EQ'.

  IF i_new_se_vrs = 'X'.

    LOOP AT et_fprprof INTO ls_funprofile.
      ls_profindex-low = ls_funprofile-profileindex.
      APPEND ls_profindex TO lr_profindex.

      ls_sys-low = ls_funprofile-sys.
      APPEND ls_sys TO lr_sys.
    ENDLOOP.

  ELSE.

    LOOP AT et_usrprof INTO ls_usrprof.
      ls_profindex-low = ls_usrprof-profileindex.
      APPEND ls_profindex TO lr_profindex.

      ls_sys-low = ls_usrprof-sys.
      APPEND ls_sys TO lr_sys.
    ENDLOOP.

  ENDIF.

  SORT lr_profindex BY low.
  SORT lr_sys BY low.

  DELETE ADJACENT DUPLICATES FROM lr_profindex COMPARING low.
  DELETE ADJACENT DUPLICATES FROM lr_sys COMPARING low.

  IF NOT lr_profindex[] IS INITIAL.

    lr_pix_all[] = lr_profindex[].

    WHILE NOT lr_pix_all[] IS INITIAL.

      REFRESH lr_pix_part.
      APPEND LINES OF lr_pix_all FROM 1 TO 5000 TO lr_pix_part.
      DELETE lr_pix_all FROM 1 TO 5000.

      IF i_new_se_vrs IS INITIAL.

        SELECT *
          FROM /psyng/swresfpr
          APPENDING TABLE et_funprofile
          WHERE aid          = i_analysis_run
            AND sys          IN lr_sys
            AND funindex     IN it_funindex
            AND profileindex IN lr_pix_part.

      ENDIF.

    ENDWHILE.

  ENDIF.

  IF NOT lr_profindex[] IS INITIAL.

    SELECT *
      FROM /psyng/swresipro
      INTO TABLE et_profiles
      FOR ALL ENTRIES IN lr_profindex
      WHERE aid       = i_analysis_run
        AND profindex = lr_profindex-low.

  ENDIF.

  IF i_new_se_vrs IS INITIAL.

    SORT et_funprofile BY sys profileindex.

    LOOP AT et_usrprof INTO ls_usrprof.

      READ TABLE et_funprofile
        WITH KEY sys          = ls_usrprof-sys
                 profileindex = ls_usrprof-profileindex
        BINARY SEARCH
        TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.
        APPEND ls_usrprof TO lt_usrprof2.
      ENDIF.

    ENDLOOP.

    et_usrprof[] = lt_usrprof2[].

    FREE lt_usrprof2.

  ENDIF.

ENDFORM.


*======================================================================*
* FORM get_analy_res_roles
*======================================================================*
FORM get_analy_res_roles
  USING
    i_analysis_run TYPE /psyng/seresid
    i_new_se_vrs   TYPE flag
    it_fprprof     TYPE ty_tt_fprprof
    it_usrprof     TYPE ty_tt_usrprof
    it_userindex   TYPE ty_r_userindex
    it_sys         TYPE ty_r_sys
  CHANGING
    et_profrole    TYPE ty_ts_profrole
    et_roles       TYPE ty_ts_roles
    et_comprole    TYPE ty_ts_comprole.

  DATA: lr_uix_all   LIKE it_userindex,
        lr_uix_part  LIKE it_userindex,
        lt_comp_part TYPE SORTED TABLE OF /psyng/swresucom
                     WITH NON-UNIQUE KEY roleindex,
        ls_comp_part TYPE /psyng/swresucom.

  IF i_new_se_vrs = 'X'.

    IF NOT it_fprprof[] IS INITIAL.

      SELECT *
        FROM /psyng/swresprol
        INTO TABLE et_profrole
        FOR ALL ENTRIES IN it_fprprof
        WHERE aid       = i_analysis_run
          AND sys       = it_fprprof-sys
          AND profindex = it_fprprof-profileindex.

      IF NOT et_profrole[] IS INITIAL.

        SELECT *
          FROM /psyng/swresirol
          INTO TABLE et_roles
          FOR ALL ENTRIES IN et_profrole
          WHERE aid       = i_analysis_run
            AND roleindex = et_profrole-roleindex.

        IF NOT et_roles[] IS INITIAL.

          IF it_userindex[] IS NOT INITIAL.

            lr_uix_part[] = it_userindex[].

            WHILE NOT lr_uix_part[] IS INITIAL.

              REFRESH lr_uix_all.
              APPEND LINES OF lr_uix_part FROM 1 TO 5000 TO lr_uix_all.
              DELETE lr_uix_part FROM 1 TO 5000.

              SELECT *
                FROM /psyng/swresucom
                INTO TABLE lt_comp_part
                FOR ALL ENTRIES IN et_roles
                WHERE aid       = i_analysis_run
                  AND userindex IN lr_uix_all
                  AND roleindex = et_roles-roleindex.

              LOOP AT lt_comp_part INTO ls_comp_part.
                INSERT ls_comp_part INTO TABLE et_comprole.
              ENDLOOP.

              REFRESH: lr_uix_all[], lt_comp_part[].

            ENDWHILE.

          ENDIF.

          IF NOT et_comprole[] IS INITIAL.
            DELETE et_comprole
              WHERE compindex IS INITIAL
                 OR compindex = 0.
          ENDIF.

          IF NOT et_comprole[] IS INITIAL.

            SELECT *
              FROM /psyng/swresirol
              APPENDING TABLE et_roles
              FOR ALL ENTRIES IN et_comprole
              WHERE aid       = i_analysis_run
                AND roleindex = et_comprole-compindex.

          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ELSE.

    IF NOT it_usrprof[] IS INITIAL.

      SELECT *
        FROM /psyng/swresprol
        INTO TABLE et_profrole
        FOR ALL ENTRIES IN it_usrprof
        WHERE aid       = i_analysis_run
          AND sys       = it_usrprof-sys
          AND profindex = it_usrprof-profileindex.

      IF NOT et_profrole[] IS INITIAL.

        SELECT *
          FROM /psyng/swresirol
          INTO TABLE et_roles
          FOR ALL ENTRIES IN et_profrole
          WHERE aid       = i_analysis_run
            AND roleindex = et_profrole-roleindex.

        IF NOT et_roles[] IS INITIAL.

          SELECT *
            FROM /psyng/swresucom
            INTO TABLE et_comprole
            FOR ALL ENTRIES IN et_roles
            WHERE aid       = i_analysis_run
              AND userindex IN it_userindex
              AND roleindex = et_roles-roleindex.

          IF NOT et_comprole[] IS INITIAL.
            DELETE et_comprole
              WHERE compindex IS INITIAL
                 OR compindex = 0.
          ENDIF.

          IF NOT et_comprole[] IS INITIAL.

            SELECT *
              FROM /psyng/swresirol
              APPENDING TABLE et_roles
              FOR ALL ENTRIES IN et_comprole
              WHERE aid       = i_analysis_run
                AND roleindex = et_comprole-compindex.

          ENDIF.

        ENDIF.

      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.


*======================================================================*
* FORM get_output_new_se
*======================================================================*
FORM get_output_new_se
  TABLES
    lt_output             STRUCTURE /psyng/sw_outputdet
  USING
    i_analysis_run        TYPE /psyng/seresid
    if_direct_assn_only   TYPE flag
    it_user               TYPE ty_th_users
    it_usercon            TYPE ty_tt_usercon
    it_conflict           TYPE ty_th_conflict
    it_confun             TYPE ty_tt_confun
    it_function           TYPE ty_th_function
    it_profiles           TYPE ty_th_profiles
    it_fprprof            TYPE ty_tt_fprprof
    it_profrole           TYPE ty_ts_profrole
    it_roles              TYPE ty_ts_roles
    it_comprole           TYPE ty_ts_comprole
    it_sysmap             TYPE ty_th_sysmap.

  DATA: ls_user        TYPE ty_users,
        ls_conflict    TYPE /psyng/swresicon,
        ls_function    TYPE /psyng/swresifun,
        ls_profiles    TYPE /psyng/swresipro,
        ls_profrole    TYPE /psyng/swresprol,
        ls_roles       TYPE /psyng/swresirol,
        ls_comprole    TYPE /psyng/swresucom,
        ls_usercon     TYPE /psyng/swrescon,
        ls_fprprof     TYPE /psyng/swresfpr,
        ls_confun      TYPE /psyng/swrescfun,
        ls_sysmap      TYPE /psyng/swresisys,
        ls_output      LIKE LINE OF lt_output,
        ls_authdet     TYPE /psyng/seres_authdetail,
        lt_authdet     TYPE ty_tt_authdetail,
        lt_dedup       TYPE HASHED TABLE OF /psyng/sw_outputdet
                        WITH UNIQUE KEY bname conid sysid funid
                                        comp_agr agr_name profname
                                        tcode auth object field von bis,
        lv_comp_agr    TYPE agr_define-agr_name,
        lf_direct_role TYPE flag,
        lf_profauth    TYPE flag,
        lv_cur_confun  TYPE sy-tabix,
        lv_fpr_start   TYPE sy-tabix,
        lv_prev_con    TYPE /psyng/swrescon-conindex,
        lv_prev_uix    TYPE /psyng/swrescon-userindex,
        lv_user_ok     TYPE flag,
        lv_con_ok      TYPE flag,
        lt_comprole_pc TYPE STANDARD TABLE OF /psyng/swresucom,
        lv_compr_start TYPE sy-tabix,
        lv_prev        TYPE sy-tabix.

  SORT: it_usercon BY conindex userindex,
        it_confun  BY conindex,
        it_fprprof BY userindex funindex profileindex.

  lt_comprole_pc[] = it_comprole[].
  SORT lt_comprole_pc BY userindex roleindex.

  CLEAR: lv_prev_con, lv_prev_uix, lv_user_ok, lv_con_ok.
  lv_cur_confun = 1.

  LOOP AT it_usercon INTO ls_usercon.

    IF ls_usercon-userindex <> lv_prev_uix.

      lv_prev_uix = ls_usercon-userindex.

      READ TABLE it_user INTO ls_user
        WITH TABLE KEY aid       = i_analysis_run
                       userindex = ls_usercon-userindex.

      IF sy-subrc = 0.
        lv_user_ok = 'X'.
      ELSE.
        CLEAR lv_user_ok.
      ENDIF.

    ENDIF.

    CHECK lv_user_ok = 'X'.

    IF ls_usercon-conindex <> lv_prev_con.

      lv_prev_con = ls_usercon-conindex.

      READ TABLE it_conflict INTO ls_conflict
        WITH TABLE KEY aid      = i_analysis_run
                       conindex = ls_usercon-conindex.

      IF sy-subrc = 0.
        lv_con_ok = 'X'.
      ELSE.
        CLEAR lv_con_ok.
      ENDIF.

      READ TABLE it_confun INTO ls_confun
        WITH KEY conindex = ls_usercon-conindex
        BINARY SEARCH.

      IF sy-subrc = 0.

        lv_cur_confun = sy-tabix.

        WHILE lv_cur_confun GT 1.

          lv_prev = lv_cur_confun - 1.

          READ TABLE it_confun INTO ls_confun INDEX lv_prev.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          IF ls_confun-conindex <> ls_usercon-conindex.
            EXIT.
          ENDIF.

          lv_cur_confun = lv_prev.

        ENDWHILE.

      ELSE.
        lv_cur_confun = 0.
      ENDIF.

    ENDIF.

    CHECK lv_con_ok = 'X'.
    CHECK lv_cur_confun > 0.

    CLEAR ls_output.
    ls_output-bname     = ls_user-bname.
    ls_output-deprtmnt  = ls_user-department.
    ls_output-class     = ls_user-class.
    ls_output-confnum   = ls_user-nr_conflicts.
    ls_output-mitinum   = ls_user-nr_mitigated.
    ls_output-conid     = ls_conflict-conid.
    ls_output-mitigated = ls_usercon-mitigated.
    ls_output-origin    = ls_usercon-origin.

    LOOP AT it_confun INTO ls_confun FROM lv_cur_confun.

      IF ls_confun-conindex <> ls_usercon-conindex.
        EXIT.
      ENDIF.

      READ TABLE it_function INTO ls_function
        WITH TABLE KEY aid      = i_analysis_run
                       funindex = ls_confun-funindex.

      CHECK sy-subrc = 0.

      ls_output-funid = ls_function-funid.

      READ TABLE it_fprprof INTO ls_fprprof
        WITH KEY userindex = ls_usercon-userindex
                 funindex  = ls_confun-funindex
        BINARY SEARCH.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_fpr_start = sy-tabix.

      WHILE lv_fpr_start GT 1.

        lv_prev = lv_fpr_start - 1.

        READ TABLE it_fprprof INTO ls_fprprof INDEX lv_prev.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        IF ls_fprprof-userindex <> ls_usercon-userindex
        OR ls_fprprof-funindex  <> ls_confun-funindex.
          EXIT.
        ENDIF.

        lv_fpr_start = lv_prev.

      ENDWHILE.

      LOOP AT it_fprprof INTO ls_fprprof FROM lv_fpr_start.

        IF ls_fprprof-userindex <> ls_usercon-userindex
        OR ls_fprprof-funindex  <> ls_confun-funindex.
          EXIT.
        ENDIF.

        READ TABLE it_sysmap INTO ls_sysmap
          WITH TABLE KEY sysindex = ls_fprprof-sys.

        ls_output-sysid = ls_sysmap-sysid.

        READ TABLE it_profiles INTO ls_profiles
          WITH TABLE KEY aid       = i_analysis_run
                         profindex = ls_fprprof-profileindex.

        IF sy-subrc = 0.
          ls_output-profname = ls_profiles-profname.
        ELSE.
          CLEAR ls_output-profname.
        ENDIF.

        CLEAR: ls_profrole,
               ls_roles,
               lv_comp_agr,
               lf_direct_role,
               lf_profauth,
               ls_output-agr_name,
               ls_output-comp_agr.

        READ TABLE it_profrole INTO ls_profrole
          WITH KEY profindex = ls_fprprof-profileindex.

        IF sy-subrc = 0.

          READ TABLE it_roles INTO ls_roles
            WITH KEY roleindex = ls_profrole-roleindex.

          IF sy-subrc = 0.
            ls_output-agr_name = ls_roles-agr_name.
          ENDIF.

          READ TABLE lt_comprole_pc INTO ls_comprole
            WITH KEY userindex = ls_usercon-userindex
                     roleindex = ls_profrole-roleindex
            BINARY SEARCH.

          IF sy-subrc = 0.

            lv_compr_start = sy-tabix.

            WHILE lv_compr_start GT 1.

              lv_prev = lv_compr_start - 1.

              READ TABLE lt_comprole_pc INTO ls_comprole INDEX lv_prev.
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.

              IF ls_comprole-userindex <> ls_usercon-userindex
              OR ls_comprole-roleindex <> ls_profrole-roleindex.
                EXIT.
              ENDIF.

              lv_compr_start = lv_prev.

            ENDWHILE.

            LOOP AT lt_comprole_pc INTO ls_comprole FROM lv_compr_start.

              IF ls_comprole-userindex <> ls_usercon-userindex
              OR ls_comprole-roleindex <> ls_profrole-roleindex.
                EXIT.
              ENDIF.

              IF ls_comprole-compindex IS INITIAL
              OR ls_comprole-compindex = 0.

                lf_direct_role = 'X'.

              ELSE.

                READ TABLE it_roles INTO ls_roles
                  WITH KEY roleindex = ls_comprole-compindex.

                IF sy-subrc = 0.

                  ls_output-comp_agr = ls_roles-agr_name.
                  lv_comp_agr        = ls_output-comp_agr.

                  IF if_direct_assn_only <> 'X'.
                    lf_direct_role = 'X'.
                  ENDIF.

                ENDIF.

              ENDIF.

            ENDLOOP.

          ELSE.

            lf_profauth = 'X'.

          ENDIF.

        ELSE.

          lf_profauth = 'X'.

        ENDIF.

        IF if_direct_assn_only = 'X'
          AND lf_direct_role = space
          AND lf_profauth    = space.
          CONTINUE.
        ENDIF.

        REFRESH lt_authdet.

        CALL METHOD lcl_authdet_bulk_cache=>get
          EXPORTING
            i_sys          = ls_fprprof-sys
            i_funindex     = ls_confun-funindex
            i_profileindex = ls_fprprof-profileindex
          CHANGING
            ct_authdet     = lt_authdet.

        LOOP AT lt_authdet INTO ls_authdet.

          MOVE-CORRESPONDING ls_authdet TO ls_output.

          ls_output-bname     = ls_user-bname.
          ls_output-sysid     = ls_sysmap-sysid.
          ls_output-conid     = ls_conflict-conid.
          ls_output-funid     = ls_function-funid.
          ls_output-profname  = ls_profiles-profname.
          ls_output-comp_agr  = lv_comp_agr.
          ls_output-confnum   = ls_user-nr_conflicts.
          ls_output-mitinum   = ls_user-nr_mitigated.
          ls_output-mitigated = ls_usercon-mitigated.
          ls_output-origin    = ls_usercon-origin.

          INSERT ls_output INTO TABLE lt_dedup.

          IF sy-subrc = 0.
            APPEND ls_output TO lt_output.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDLOOP.

ENDFORM.


*======================================================================*
* FORM get_output_old_se
*======================================================================*
FORM get_output_old_se
  TABLES
    lt_output             STRUCTURE /psyng/sw_outputdet
  USING
    i_analysis_run        TYPE /psyng/seresid
    if_direct_assn_only   TYPE flag
    it_user               TYPE ty_th_users
    it_usercon            TYPE ty_tt_usercon
    it_conflict           TYPE ty_th_conflict
    it_confun             TYPE ty_tt_confun
    it_function           TYPE ty_th_function
    it_profiles           TYPE ty_th_profiles
    it_usrprof            TYPE ty_tt_usrprof
    it_funprofile         TYPE ty_tt_fprprof
    it_profrole           TYPE ty_ts_profrole
    it_roles              TYPE ty_ts_roles
    it_comprole           TYPE ty_ts_comprole
    it_sysmap             TYPE ty_th_sysmap.

  DATA: ls_user        TYPE ty_users,
        ls_conflict    TYPE /psyng/swresicon,
        ls_function    TYPE /psyng/swresifun,
        ls_profiles    TYPE /psyng/swresipro,
        ls_usrprof     TYPE /psyng/swresupr,
        ls_funprofile  TYPE /psyng/swresfpr,
        ls_profrole    TYPE /psyng/swresprol,
        ls_roles       TYPE /psyng/swresirol,
        ls_comprole    TYPE /psyng/swresucom,
        ls_usercon     TYPE /psyng/swrescon,
        ls_confun      TYPE /psyng/swrescfun,
        ls_sysmap      TYPE /psyng/swresisys,
        ls_output      LIKE LINE OF lt_output,
        ls_authdet     TYPE /psyng/seres_authdetail,
        lt_authdet     TYPE ty_tt_authdetail,
        lt_dedup       TYPE HASHED TABLE OF /psyng/sw_outputdet
                        WITH UNIQUE KEY bname conid sysid funid
                                        comp_agr agr_name profname
                                        tcode auth object field von bis,
        lv_comp_agr    TYPE agr_define-agr_name,
        lf_direct_role TYPE flag,
        lf_profauth    TYPE flag,
        lv_cur_confun  TYPE sy-tabix,
        lv_fpr_start   TYPE sy-tabix,
        lv_prev_con    TYPE /psyng/swrescon-conindex,
        lv_prev_uix    TYPE /psyng/swrescon-userindex,
        lv_user_ok     TYPE flag,
        lv_con_ok      TYPE flag,
        lt_comprole_pc TYPE STANDARD TABLE OF /psyng/swresucom,
        lv_compr_start TYPE sy-tabix,
        lv_prev        TYPE sy-tabix.

  SORT: it_usercon    BY conindex userindex,
        it_confun     BY conindex,
        it_usrprof    BY sys userindex profileindex,
        it_funprofile BY userindex funindex profileindex.

  lt_comprole_pc[] = it_comprole[].
  SORT lt_comprole_pc BY userindex roleindex.

  CLEAR: lv_prev_con, lv_prev_uix, lv_user_ok, lv_con_ok.
  lv_cur_confun = 1.

  LOOP AT it_usercon INTO ls_usercon.

    IF ls_usercon-userindex <> lv_prev_uix.

      lv_prev_uix = ls_usercon-userindex.

      READ TABLE it_user INTO ls_user
        WITH TABLE KEY aid       = i_analysis_run
                       userindex = ls_usercon-userindex.

      IF sy-subrc = 0.
        lv_user_ok = 'X'.
      ELSE.
        CLEAR lv_user_ok.
      ENDIF.

    ENDIF.

    CHECK lv_user_ok = 'X'.

    IF ls_usercon-conindex <> lv_prev_con.

      lv_prev_con = ls_usercon-conindex.

      READ TABLE it_conflict INTO ls_conflict
        WITH TABLE KEY aid      = i_analysis_run
                       conindex = ls_usercon-conindex.

      IF sy-subrc = 0.
        lv_con_ok = 'X'.
      ELSE.
        CLEAR lv_con_ok.
      ENDIF.

      READ TABLE it_confun INTO ls_confun
        WITH KEY conindex = ls_usercon-conindex
        BINARY SEARCH.

      IF sy-subrc = 0.

        lv_cur_confun = sy-tabix.

        WHILE lv_cur_confun GT 1.

          lv_prev = lv_cur_confun - 1.

          READ TABLE it_confun INTO ls_confun INDEX lv_prev.
          IF sy-subrc <> 0.
            EXIT.
          ENDIF.

          IF ls_confun-conindex <> ls_usercon-conindex.
            EXIT.
          ENDIF.

          lv_cur_confun = lv_prev.

        ENDWHILE.

      ELSE.
        lv_cur_confun = 0.
      ENDIF.

    ENDIF.

    CHECK lv_con_ok = 'X'.
    CHECK lv_cur_confun > 0.

    CLEAR ls_output.
    ls_output-bname     = ls_user-bname.
    ls_output-deprtmnt  = ls_user-department.
    ls_output-class     = ls_user-class.
    ls_output-confnum   = ls_user-nr_conflicts.
    ls_output-mitinum   = ls_user-nr_mitigated.
    ls_output-conid     = ls_conflict-conid.
    ls_output-mitigated = ls_usercon-mitigated.
    ls_output-origin    = ls_usercon-origin.

    LOOP AT it_confun INTO ls_confun FROM lv_cur_confun.

      IF ls_confun-conindex <> ls_usercon-conindex.
        EXIT.
      ENDIF.

      READ TABLE it_function INTO ls_function
        WITH TABLE KEY aid      = i_analysis_run
                       funindex = ls_confun-funindex.

      CHECK sy-subrc = 0.

      ls_output-funid = ls_function-funid.

      READ TABLE it_funprofile INTO ls_funprofile
        WITH KEY userindex = ls_usercon-userindex
                 funindex  = ls_confun-funindex
        BINARY SEARCH.

      IF sy-subrc <> 0.
        CONTINUE.
      ENDIF.

      lv_fpr_start = sy-tabix.

      WHILE lv_fpr_start GT 1.

        lv_prev = lv_fpr_start - 1.

        READ TABLE it_funprofile INTO ls_funprofile INDEX lv_prev.
        IF sy-subrc <> 0.
          EXIT.
        ENDIF.

        IF ls_funprofile-userindex <> ls_usercon-userindex
        OR ls_funprofile-funindex  <> ls_confun-funindex.
          EXIT.
        ENDIF.

        lv_fpr_start = lv_prev.

      ENDWHILE.

      LOOP AT it_funprofile INTO ls_funprofile FROM lv_fpr_start.

        IF ls_funprofile-userindex <> ls_usercon-userindex
        OR ls_funprofile-funindex  <> ls_confun-funindex.
          EXIT.
        ENDIF.

        READ TABLE it_usrprof INTO ls_usrprof
          WITH KEY sys          = ls_funprofile-sys
                   userindex    = ls_usercon-userindex
                   profileindex = ls_funprofile-profileindex
          BINARY SEARCH.

        CHECK sy-subrc = 0.

        READ TABLE it_sysmap INTO ls_sysmap
          WITH TABLE KEY sysindex = ls_usrprof-sys.

        ls_output-sysid = ls_sysmap-sysid.

        READ TABLE it_profiles INTO ls_profiles
          WITH TABLE KEY aid       = i_analysis_run
                         profindex = ls_usrprof-profileindex.

        IF sy-subrc = 0.
          ls_output-profname = ls_profiles-profname.
        ELSE.
          CLEAR ls_output-profname.
        ENDIF.

        CLEAR: ls_profrole,
               ls_roles,
               lv_comp_agr,
               lf_direct_role,
               lf_profauth,
               ls_output-agr_name,
               ls_output-comp_agr.

        READ TABLE it_profrole INTO ls_profrole
          WITH KEY profindex = ls_usrprof-profileindex.

        IF sy-subrc = 0.

          READ TABLE it_roles INTO ls_roles
            WITH KEY roleindex = ls_profrole-roleindex.

          IF sy-subrc = 0.
            ls_output-agr_name = ls_roles-agr_name.
          ENDIF.

          READ TABLE lt_comprole_pc INTO ls_comprole
            WITH KEY userindex = ls_usercon-userindex
                     roleindex = ls_profrole-roleindex
            BINARY SEARCH.

          IF sy-subrc = 0.

            lv_compr_start = sy-tabix.

            WHILE lv_compr_start GT 1.

              lv_prev = lv_compr_start - 1.

              READ TABLE lt_comprole_pc INTO ls_comprole INDEX lv_prev.
              IF sy-subrc <> 0.
                EXIT.
              ENDIF.

              IF ls_comprole-userindex <> ls_usercon-userindex
              OR ls_comprole-roleindex <> ls_profrole-roleindex.
                EXIT.
              ENDIF.

              lv_compr_start = lv_prev.

            ENDWHILE.

            LOOP AT lt_comprole_pc INTO ls_comprole FROM lv_compr_start.

              IF ls_comprole-userindex <> ls_usercon-userindex
              OR ls_comprole-roleindex <> ls_profrole-roleindex.
                EXIT.
              ENDIF.

              IF ls_comprole-compindex IS INITIAL
              OR ls_comprole-compindex = 0.

                lf_direct_role = 'X'.

              ELSE.

                READ TABLE it_roles INTO ls_roles
                  WITH KEY roleindex = ls_comprole-compindex.

                IF sy-subrc = 0.

                  ls_output-comp_agr = ls_roles-agr_name.
                  lv_comp_agr        = ls_output-comp_agr.

                  IF if_direct_assn_only <> 'X'.
                    lf_direct_role = 'X'.
                  ENDIF.

                ENDIF.

              ENDIF.

            ENDLOOP.

            CLEAR ls_output-comp_agr.

          ELSE.

            lf_profauth = 'X'.

          ENDIF.

        ELSE.

          lf_profauth = 'X'.

        ENDIF.

        IF if_direct_assn_only = 'X'
          AND lf_direct_role = space
          AND lf_profauth    = space.
          CONTINUE.
        ENDIF.

        REFRESH lt_authdet.

        CALL METHOD lcl_authdet_bulk_cache=>get
          EXPORTING
            i_sys          = ls_usrprof-sys
            i_funindex     = ls_confun-funindex
            i_profileindex = ls_usrprof-profileindex
          CHANGING
            ct_authdet     = lt_authdet.

        LOOP AT lt_authdet INTO ls_authdet.

          MOVE-CORRESPONDING ls_authdet TO ls_output.

          ls_output-bname     = ls_user-bname.
          ls_output-sysid     = ls_sysmap-sysid.
          ls_output-conid     = ls_conflict-conid.
          ls_output-funid     = ls_function-funid.
          ls_output-profname  = ls_profiles-profname.
          ls_output-comp_agr  = lv_comp_agr.
          ls_output-confnum   = ls_user-nr_conflicts.
          ls_output-mitinum   = ls_user-nr_mitigated.
          ls_output-mitigated = ls_usercon-mitigated.
          ls_output-origin    = ls_usercon-origin.

          INSERT ls_output INTO TABLE lt_dedup.

          IF sy-subrc = 0.
            APPEND ls_output TO lt_output.
          ENDIF.

        ENDLOOP.

      ENDLOOP.

    ENDLOOP.

  ENDLOOP.

ENDFORM.


*======================================================================*
* FORM get_analy_res_det
*======================================================================*
FORM get_analy_res_det
  TABLES
    it_users             STRUCTURE /psyng/sw_userlist
    et_users             STRUCTURE /psyng/userconcount
    lt_output            STRUCTURE /psyng/sw_outputdet
    et_return            STRUCTURE bapiret2
  USING
    i_analysis_run       TYPE /psyng/seresid
    if_exclude_mitigated TYPE flag
    if_direct_assn_only  TYPE flag
  CHANGING
    e_result_count       TYPE i.

  DATA: l_new_se_vrs  TYPE flag,
        lf_continue   TYPE flag,
        lv_fpr_aid    TYPE /psyng/seresid,
        lt_user       TYPE ty_th_users,
        lr_userindex  TYPE ty_r_userindex,
        lt_usercon    TYPE ty_tt_usercon,
        lt_conflict   TYPE ty_th_conflict,
        lt_confun     TYPE ty_tt_confun,
        lt_function   TYPE ty_th_function,
        lr_funindex   TYPE ty_r_funindex,
        lt_fprprof    TYPE ty_tt_fprprof,
        lt_usrprof    TYPE ty_tt_usrprof,
        lt_funprofile TYPE ty_tt_fprprof,
        lt_profiles   TYPE ty_th_profiles,
        lr_profindex  TYPE ty_r_profindex,
        lr_sys        TYPE ty_r_sys,
        lt_profrole   TYPE ty_ts_profrole,
        lt_roles      TYPE ty_ts_roles,
        lt_comprole   TYPE ty_ts_comprole,
        lt_sysmap     TYPE ty_th_sysmap.

  CLEAR l_new_se_vrs.

  SELECT SINGLE aid
    INTO lv_fpr_aid
    FROM /psyng/swresfpr
    WHERE aid = i_analysis_run.

  IF sy-subrc = 0.
    l_new_se_vrs = 'X'.
  ENDIF.

  SELECT *
    FROM /psyng/swresisys
    INTO TABLE lt_sysmap
    WHERE aid = i_analysis_run.

  lf_continue = 'X'.

  PERFORM get_analy_res_users
    TABLES
      it_users
      et_return
    USING
      i_analysis_run
    CHANGING
      lt_user
      lr_userindex
      lf_continue.

  CHECK lf_continue = 'X'.

  PERFORM get_analy_res_conflicts
    TABLES
      et_users
      et_return
    USING
      i_analysis_run
      if_exclude_mitigated
      lt_user
      lr_userindex
    CHANGING
      lt_usercon
      lt_conflict
      lt_confun
      lt_function
      lr_funindex
      e_result_count.

  CHECK NOT lt_usercon[] IS INITIAL.

  PERFORM get_analy_res_profiles
    USING
      i_analysis_run
      l_new_se_vrs
      lt_usercon
      lr_funindex
      lr_userindex
    CHANGING
      lt_fprprof
      lt_usrprof
      lt_funprofile
      lt_profiles
      lr_profindex
      lr_sys.

  PERFORM get_analy_res_roles
    USING
      i_analysis_run
      l_new_se_vrs
      lt_fprprof
      lt_usrprof
      lr_userindex
      lr_sys
    CHANGING
      lt_profrole
      lt_roles
      lt_comprole.

  IF l_new_se_vrs = 'X'.

    CALL METHOD lcl_authdet_bulk_cache=>init
      EXPORTING
        i_aid      = i_analysis_run
        it_fprprof = lt_fprprof
        it_sysmap  = lt_sysmap.

  ELSE.

    CALL METHOD lcl_authdet_bulk_cache=>init
      EXPORTING
        i_aid      = i_analysis_run
        it_fprprof = lt_funprofile
        it_sysmap  = lt_sysmap.

  ENDIF.

  IF l_new_se_vrs = 'X'.

    PERFORM get_output_new_se
      TABLES
        lt_output
      USING
        i_analysis_run
        if_direct_assn_only
        lt_user
        lt_usercon
        lt_conflict
        lt_confun
        lt_function
        lt_profiles
        lt_fprprof
        lt_profrole
        lt_roles
        lt_comprole
        lt_sysmap.

  ELSE.

    PERFORM get_output_old_se
      TABLES
        lt_output
      USING
        i_analysis_run
        if_direct_assn_only
        lt_user
        lt_usercon
        lt_conflict
        lt_confun
        lt_function
        lt_profiles
        lt_usrprof
        lt_funprofile
        lt_profrole
        lt_roles
        lt_comprole
        lt_sysmap.

  ENDIF.

  SORT lt_output BY bname conid sysid funid.

  CALL METHOD lcl_authdet_bulk_cache=>clear.

  FREE: lt_user,
        lt_usercon,
        lt_conflict,
        lt_confun,
        lt_function,
        lt_fprprof,
        lt_usrprof,
        lt_funprofile,
        lt_profiles,
        lt_profrole,
        lt_roles,
        lt_comprole,
        lt_sysmap.

ENDFORM.
