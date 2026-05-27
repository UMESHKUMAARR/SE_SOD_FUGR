*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_POLARF01 .
*----------------------------------------------------------------------*



*FORM get_sw032_results USING p_task type c.
*  data : lt_polar type table of /psyng/sw_role_polar,
*         lt_polar_combo type table of /psyng/sw_role_polar_combo,
*         lt_polar_combo_users
*         type table of /psyng/sw_role_polar_combo_usr .
*  refresh : lt_polar[].
*  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_032'
*      TABLES
*        et_polar        = lt_polar
*        et_combos       = lt_polar_combo
*        et_combo_users  = lt_polar_combo_users.
*
**  loop at lt_polar assigning <polar>.
**    collect <polar> into gt_polar.
**  endloop.
**collect in parallel is not a good idea
** numbers are not correct
*  append lines of lt_polar to gt_polar.
*  data : l_lines type numc10.
*  describe table lt_polar lines l_lines.
*
*  free : lt_polar[].
*
*  append lines of lt_polar_combo to gt_polar_combo.
*  data : l_lines_combo type numc10.
*  describe table lt_polar_combo lines l_lines_combo.
*  free : lt_polar_combo[].
*
*  append lines of lt_polar_combo_users to gt_polar_combo_users.
*  data : l_lines_combo_usr type numc10.
*  describe table lt_polar_combo_users lines l_lines_combo_usr.
*  free : lt_polar_combo_users[].
**Report progress
*  g_pct_progress = g_pct_progress + g_pct_per_process.
*  data : l_pct type i.
*  l_pct = g_pct_progress.
*  if l_pct > 100. l_pct = 100. endif.
** report every 10% in job log
*  data : l_remains type i.
*  l_remains = l_pct mod 10.
*  if l_remains = 0 and l_pct <> g_prev_pct.
*    CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*         EXPORTING
*              percentage = l_pct
*              text       = text-035.
*    MESSAGE s010(/psyng/basis) WITH text-035 ' : ' l_pct '%.'.
*    g_prev_pct = l_pct.
*  endif.
*  g_numres = g_numres + l_lines.
** release 1 process
*  subtract 1 from g_numproc.
*ENDFORM.                                                    " ZGET_1
*
**---------------------------------------------------------------------*
**       FORM fill_internal_tables                                     *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  IT_USER                                                       *
**  -->  I_ORGCHK                                                      *
**  -->  I_VRSIO                                                       *
**  -->  I_ENHANC                                                      *
**---------------------------------------------------------------------*
*FORM fill_internal_tables
*                TABLES
*                  it_user STRUCTURE /psyng/range_bname
*                USING
*                  i_orgchk TYPE flag
*                  i_vrsio  TYPE /psyng/sodvrsio
*                  i_enhanc TYPE flag
*                .
*
*
*  DATA : idcl_task(9) VALUE 'IDCL_USER',
*         lt_conflict  TYPE TABLE OF /psyng/conflict,
*         lt_confdet   TYPE TABLE OF /psyng/confdet.
**Get SOD Matrix
*  CALL FUNCTION '/PSYNG/SW_028'
*    EXPORTING
*      i_orgcheck         = i_orgchk
*      i_vrsio            = i_vrsio
*      i_enhance          = i_enhanc
*    TABLES
**      it_spconfs         = spconfs
**      it_imp             = sens
**      it_org             = orglvl
*      et_conflict        = lt_conflict
*      et_confdet         = lt_confdet
*      et_functtran       = functtran
*      et_faobj           = faobj
*      et_swsodorgm       = swsodorgm
*      et_tcodes          = gt_enh_tcodes.
*  conflict[] = lt_conflict[].
*  confdet[]  = lt_confdet[].
*  confs2[] = confdet[].
** Remove rows with no object
*  DELETE faobj WHERE object = space.
** Custom conflicts are NOT included in the analysis
*ENDFORM.
*
**---------------------------------------------------------------------*
**       FORM get_idcl_user                                            *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
**  -->  TASKNAME                                                      *
**---------------------------------------------------------------------*
*FORM get_idcl_user USING taskname.
*  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_IDCL_USER'
*    TABLES
**      PBNAME_FM       = userlist
*      iduser_fm       = iduser_fm.
*  IF sy-subrc = 0.
*    idcl_data_received = 'Y'.
*  ENDIF.
*ENDFORM.
**&---------------------------------------------------------------------*
**&      Form  get_users_from_selection
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM get_users_from_selection
*                  TABLES
*                  it_user STRUCTURE /psyng/range_bname
*                  USING
*                    i_vrsio type /psyng/sodvrsio
*
*.
*DATA:   YULOCK   TYPE X VALUE '80',     "Locked by incorrect login
*        YUSLOC   TYPE X VALUE '40',     "Locked by Administrator
*        YUGLOC   TYPE X VALUE '20'.     "Locked by global Administrator
*data : l_uflagx type x.
*
*  CONSTANTS: lc_method(17) TYPE c VALUE 'GET_USERS_FROM_HR'.
*
*  DATA: objectcount_fm TYPE  i,
*      concount_fm  TYPE  i,
*      byobject  TYPE  char10,
*      lt_persa  TYPE /psyng/range_persa_t,
*      lt_user   TYPE /psyng/hr_user_t,
*      ls_user   TYPE /psyng/hr_user,
*      lt_bname  TYPE /psyng/range_bname_t,
*      ls_bname  TYPE /psyng/range_bname,
*      wa_iusers TYPE usr02,
*      oldbname  type bname,
*      wa_idusers TYPE idusers_typ,
*      lt_uinfo type table of /psyng/sw_uinfo with header line.
*
**do We care about valid users?
*  IF validusr IS INITIAL.
*    SELECT bname class
*           INTO CORRESPONDING FIELDS OF wa_iusers
*           FROM usr02
*           WHERE bname IN it_user.
*      INSERT wa_iusers INTO TABLE iusers.
*      IF wa_iusers-bname <> oldbname.
**          tusercount = tusercount + 1.
*        oldbname = wa_iusers-bname.
*      ENDIF.
*    ENDSELECT.
*  ELSE.
*    PERFORM get_sw_repo_conifg.
*    SELECT bname gltgv gltgb ustyp uflag class
*           INTO CORRESPONDING FIELDS OF wa_iusers
*           FROM usr02
*           WHERE bname IN it_user AND
*                 ustyp = 'A'.
*      IF wa_iusers-gltgv IS INITIAL.
*        wa_iusers-gltgv = '00010101'.
*      ENDIF.
*      IF wa_iusers-gltgb IS INITIAL.
*        wa_iusers-gltgb = '99991231'.
*      ENDIF.
*      IF wa_iusers-gltgv <= sy-datum AND wa_iusers-gltgb >= sy-datum.
**SF Case 1405
*          l_uflagx = wa_iusers-uflag."unicode
*          IF l_uflagx O yusloc OR "locked by admin
*             l_uflagx O yugloc.   "locked by CUA admin
**        --User is locked by Local or Global Administrator
*             IF dsp_mng_lock = 'Y'.
*                INSERT wa_iusers INTO TABLE iusers.
*             ENDIF.
*          ELSEIF l_uflagx O yulock.
**        --User is locked by failed logins
*            IF dsp_slf_lock = 'Y'.
*                INSERT wa_iusers INTO TABLE iusers.
*            ENDIF.
*          ELSE.
**        --User is active
*                INSERT wa_iusers INTO TABLE iusers.
*          ENDIF.
*        IF wa_iusers-bname <> oldbname.
*          oldbname = wa_iusers-bname.
*        ENDIF.
**        CASE wa_iusers-uflag.
**          WHEN 0.   "user ID unlocked
**            INSERT wa_iusers INTO TABLE iusers.
**            IF wa_iusers-bname <> oldbname.
***                tusercount = tusercount + 1.
**              oldbname = wa_iusers-bname.
**            ENDIF.
**          WHEN 64.  "user ID locked by system manager
**            IF dsp_mng_lock = 'Y'.
**              INSERT wa_iusers INTO TABLE iusers.
**              IF wa_iusers-bname <> oldbname.
***                  tusercount = tusercount + 1.
**                oldbname = wa_iusers-bname.
**              ENDIF.
**            ENDIF.
**          WHEN 128. "user ID locked due to incorrect logins
**            IF dsp_slf_lock = 'Y'.
**              INSERT wa_iusers INTO TABLE iusers.
**              IF wa_iusers-bname <> oldbname.
***                  tusercount = tusercount + 1.
**                oldbname = wa_iusers-bname.
**              ENDIF.
**            ENDIF.
**        ENDCASE.
*
*      ENDIF.
*    ENDSELECT.
*  ENDIF.
***DHO 20101202
**  LOOP AT iusers.   "get complete users for FM updates
**    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
**             ID 'CLASS' FIELD iusers-class.
**
**    IF sy-subrc = 0.
**      totalusers2-bname = iusers-bname.
**      APPEND totalusers2.
**    ELSEIF NOT ( iusers-class IS INITIAL ) .
**      gf_missing_auth_ugroup = 'X'.
**      DELETE iusers WHERE bname = iusers-bname.
**    ENDIF.
**  ENDLOOP.
**DHO 20101202
*  loop at iusers.
*      lt_uinfo-bname = iusers-bname.
*      append lt_uinfo.
*  endloop.
*    CALL FUNCTION '/PSYNG/SW_USER_INFO'
*     EXPORTING
*       VRSIO                    = i_vrsio
**       ENHANCED_SCANTABLE       = ''
*       I_NAME_ONLY              = 'X'
*       I_MR_COMPANY             = 'X'
*      TABLES
*        sw_uinfo                 = lt_uinfo.
*              .
*
*  LOOP AT lt_uinfo.
*
*
*  if not lt_uinfo-class is initial AND
*     not lt_uinfo-company is initial.
*
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*         ID 'CLASS' FIELD lt_uinfo-class
*         ID 'Y&SW_VRSIO'  field i_vrsio
*         ID 'Y&SW_COMP'   field lt_uinfo-company.
*      IF sy-subrc <> 0.
*        DELETE iusers WHERE bname = lt_uinfo-bname.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*  elseif not lt_uinfo-class is initial.
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*         ID 'CLASS' FIELD lt_uinfo-class
*         ID 'Y&SW_VRSIO'  field i_vrsio
*         ID 'Y&SW_COMP'   DUMMY.
*      IF sy-subrc <> 0.
*        DELETE iusers WHERE bname = lt_uinfo-bname.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*  elseif not lt_uinfo-company is initial.
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*         ID 'CLASS' DUMMY
*         ID 'Y&SW_VRSIO'  field i_vrsio
*         ID 'Y&SW_COMP'   field lt_uinfo-company.
*      IF sy-subrc <> 0.
*        DELETE iusers WHERE bname = lt_uinfo-bname.
*        gf_missing_auth_ugroup = 'X'.
*      ENDIF.
*  endif.
*  ENDLOOP.
*
*
*
**  DESCRIBE TABLE iusers LINES tusercount.
*
**  DESCRIBE TABLE iusers LINES objectcount_fm.
**  SELECT COUNT( * ) FROM /psyng/conflict
**         INTO concount_fm
**         WHERE conid IN spconfs
**         AND   vrsio =  sodvrsio.
**  byobject = 'USER'.
*
**  CALL FUNCTION '/PSYNG/SW_SOD_UPDATE_STAT'
**    IN BACKGROUND TASK
**    EXPORTING
**      objectcount_fm       = objectcount_fm
**      concount_fm          = concount_fm
**      byobject             = byobject.
**
*
**  check
*  WAIT UNTIL idcl_data_received = 'Y'.
*
*  LOOP AT iduser_fm.
*    CLEAR wa_idusers-class.
*    SELECT SINGLE class INTO wa_idusers-class
*           FROM usr02 WHERE bname = iduser_fm-idbname.
*    wa_idusers-bname = iduser_fm-idbname.
*    INSERT wa_idusers INTO TABLE idusers.
*  ENDLOOP.
**  refresh: iduser_fm.
*  LOOP AT iusers.
*    READ TABLE idusers WITH TABLE KEY bname = iusers-bname.
*    IF sy-subrc = 0.
*      DELETE TABLE iusers WITH TABLE KEY bname = idusers-bname.
*    ENDIF.
*  ENDLOOP.
*ENDFORM.                    " get_users_from_selection
**---------------------------------------------------------------------*
**       FORM get_sw_repo_conifg                                       *
**---------------------------------------------------------------------*
**       ........                                                      *
**---------------------------------------------------------------------*
*FORM get_sw_repo_conifg.
*  DATA: swconfig TYPE /psyng/swconfig.
*
*  CLEAR: swconfig.
*  SELECT SINGLE * FROM /psyng/swconfig
*         INTO swconfig
*         WHERE param = 'REP_USR_LOK_DSP_MGR'.
*  IF swconfig-value = 'Y'.
*    dsp_mng_lock = 'Y'.
*  ENDIF.
*
*  CLEAR swconfig.
*  SELECT SINGLE * FROM /psyng/swconfig
*         INTO swconfig
*         WHERE param = 'REP_USR_LOK_DSP_SLF'.
*  IF swconfig-value = 'N'.
*    dsp_slf_lock = 'N'.
*  ENDIF.
*ENDFORM.                    " get_sw_repo_conifg
**&---------------------------------------------------------------------*
**&      Form  compile_sod_by_user
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*form compile_sod_by_user using i_orgchk.
*data :  wa_iusers TYPE usr02,
*        wa_susertcode TYPE /psyng/usertcode,
*        wa_suserauth TYPE /psyng/userauth,
*        wa_userprof TYPE /psyng/userprof.
*DATA: wa_itcd TYPE typ_itcd.
*DATA: wa_tobjs1 TYPE typ_tobjs.
*.
** Reference User check
*  if not iusers[] is initial.
*    SELECT bname refuser FROM usrefus
*      INTO CORRESPONDING FIELDS OF TABLE iusrefus
*      FOR ALL ENTRIES IN iusers WHERE bname = iusers-bname AND
*              refuser NE space.
*  endif.
*  SORT iusers.
*  LOOP AT iusrefus.
*    READ TABLE iusers WITH TABLE KEY bname = iusrefus-refuser.
*    CHECK sy-subrc <> 0.
*    wa_iusers-bname = iusrefus-refuser.
*    wa_iusers-class = 'REFUSER'.
*    INSERT wa_iusers INTO TABLE iusers.
*  ENDLOOP.
*  SORT iusers.
** Reference User check
*
*  LOOP AT iusers.
*    CLEAR: usertcode_fm, userprof, userauth_fm.
*    CALL FUNCTION '/PSYNG/SW_GET_USER_AUTH_DATA'
*         EXPORTING
*              userid    = iusers-bname
*         TABLES
*              functtran = functtran
*              faobj     = faobj
*              usertcode = usertcode_fm
*              userprof  = userprof
*              userauth  = userauth_fm.
*  endloop.
** Reference User check
*  LOOP AT iusrefus.
*    LOOP AT userprof INTO wa_userprof WHERE bname = iusrefus-refuser.
*      wa_userprof-bname = iusrefus-bname.
*      INSERT wa_userprof INTO TABLE userprof.
*    ENDLOOP.
*  ENDLOOP.
**DHORIONS -->OKAY UNTIL HERE I THINK
*sort : userprof.
** Reference User check
*  LOOP AT userprof WHERE profile CS 'SAP_ALL'.
*    outputdet3-bname = userprof-bname.
*    outputdet3-conid = 'ALL'.
*    outputdet3-functionid = 'ALL'.
*    outputdet3-profile  = userprof-profile.
*    outputdet3-description = text-044.
*    outputdet3-rfcdest  = userprof-rfcdest.
*    APPEND outputdet3.
*
*    LOOP AT iduser_fm WHERE bname = userprof-bname.
*      outputdet3-bname = iduser_fm-idbname.
*      APPEND outputdet3.
*    ENDLOOP.
*    CLEAR outputdet3.
*
**    DELETE iusers WHERE bname = userprof-bname.
*    DELETE usertcode_fm WHERE bname = userprof-bname.
*    DELETE suserauth WHERE bname = userprof-bname.
*    DELETE userprof.
*  ENDLOOP.
*
*
*sort : userprof,usertcode_fm .
*
*
*
*
*  SORT: usertcode_fm, userauth_fm.
*  DELETE ADJACENT DUPLICATES FROM usertcode_fm.
*  DELETE ADJACENT DUPLICATES FROM userauth_fm.
*  susertcode[] = usertcode_fm[].
*  suserauth[] = userauth_fm[].
*  REFRESH: usertcode_fm, userauth_fm.
*
** Reference User check
*  LOOP AT iusrefus.
*    LOOP AT susertcode INTO wa_susertcode
*            WHERE bname = iusrefus-refuser.
*      wa_susertcode-bname = iusrefus-bname.
*      INSERT wa_susertcode INTO TABLE susertcode.
*    ENDLOOP.
*
*    LOOP AT suserauth INTO wa_suserauth WHERE bname = iusrefus-refuser.
*      wa_suserauth-bname = iusrefus-bname.
*      INSERT wa_suserauth INTO TABLE suserauth.
*    ENDLOOP.
*  ENDLOOP.
*  DELETE iusers WHERE class = 'REFUSER'.
*  SORT userprof BY bname.
*  LOOP AT iusrefus.
*    READ TABLE iusers WITH TABLE KEY bname = iusrefus-refuser.
*    CHECK sy-subrc NE 0.  "REFUSER not in selection screen
*    DELETE susertcode WHERE bname = iusrefus-refuser.
*    DELETE suserauth WHERE bname  = iusrefus-refuser.
*    DELETE userprof WHERE bname  = iusrefus-refuser.
*  ENDLOOP.
** Reference User check
*
*  LOOP AT suserauth.
*    uniqueauths-rfcdest = suserauth-rfcdest.
*    uniqueauths-objct   = suserauth-objct.
*    uniqueauths-auth    = suserauth-auth.
*    APPEND uniqueauths.
*  ENDLOOP.
*  SORT uniqueauths.
*  DELETE ADJACENT DUPLICATES FROM uniqueauths COMPARING ALL FIELDS.
*
*  LOOP AT susertcode.
*    wa_itcd-tcode = susertcode-tcode.
*    wa_itcd-rfcdest = susertcode-rfcdest.
*    INSERT wa_itcd INTO TABLE itcd.
*  ENDLOOP.
*
*  MESSAGE s208(00) WITH text-045.
*  COMMIT WORK.
*  PERFORM remove_stuff_for_performance.
*
*  LOOP AT faobj.
*    MOVE-CORRESPONDING faobj TO wa_tobjs1.
*    INSERT wa_tobjs1 INTO TABLE tobjs3.
*  ENDLOOP.
*  tobjs1[] = tobjs3[].
*  tobjs2[] = tobjs3[].
*
*  SORT: functtran, faobj.
*
*  MESSAGE s208(00) WITH text-046.
*  COMMIT WORK.
*  CALL FUNCTION '/PSYNG/SW_GET_TCODE_AUTH_DATA'
*       TABLES
*            tcd         = itcd2
*            faobj       = faobj
*            functtran   = functtran
*            tcdaut      = itcdaut
*            uniqueauths = uniqueauths.
*
*  COMMIT WORK.
*
*  SORT: faobj, itcdaut.
*  DELETE ADJACENT DUPLICATES FROM itcdaut COMPARING ALL FIELDS.
*  if not   i_orgchk is initial.
*    PERFORM get_org_level_auth."get org level authorizations
*  endif.
*  PERFORM compare_soddef_with_auth_new using i_orgchk.
*
*
*endform.                    " compile_sod_by_user
**&---------------------------------------------------------------------*
**&      Form  get_org_level_auth
**&---------------------------------------------------------------------*
**       Select authorizations that contain org levels
**----------------------------------------------------------------------*
*form get_org_level_auth.
**Using own FM
*data : lt_systemauths type table of /psyng/swsodorgauth.
*lt_systemauths[] = gt_systemauths[].
*free gt_systemauths[].
*CALL FUNCTION '/PSYNG/SW_024'
*  TABLES
*    swsodorgm         = swsodorgm
*    uniqueauths       = uniqueauths
*    systemauths       = lt_systemauths.
*sort lt_systemauths.
*gt_systemauths[] = lt_systemauths[].
*free lt_systemauths[].
*
**  MESSAGE s208(00) WITH
**  'Finished getting org level authorizations'(002).
*endform. " get_org_level_auth
*
**&---------------------------------------------------------------------*
**&      Form  COMPARE_SODDEF_WITH_AUTH_NEW
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM compare_soddef_with_auth_new using i_orgchk type flag.
**DATA: wa_tobjs1 TYPE typ_tobjs.
*
*  DATA: wa_ft         TYPE ft_typ,
*        wa_cf         TYPE cf_typ,
*        outputdet_idx TYPE i.
**DATA: usertcode_idx   TYPE i,
**      userauth_idx    TYPE i,
**      itcdaut_idx     TYPE i.
**
*
*  usertcode_idx = 1.  userauth_idx = 1.  outputdet_idx = 1.
*
**  PERFORM output_table_sizes.
*  LOOP AT functtran.
*    MOVE-CORRESPONDING functtran TO wa_ft.
*    INSERT wa_ft INTO TABLE ft.
*  ENDLOOP.
*  LOOP AT confdet.
*    MOVE-CORRESPONDING confdet TO wa_cf.
*    INSERT wa_cf INTO TABLE cf.
*  ENDLOOP.
*  REFRESH: functtran, confdet.
*  CLEAR: functtran, confdet.
*
*  MESSAGE s208(00) WITH text-050.
*  COMMIT WORK.
*
**  CLEAR counter.
*  LOOP AT iusers.
*    wa_tobjs1-userhas = 'Y'.
*    PERFORM refresh_internal_tables.
*    PERFORM step5 using i_orgchk .
*  ENDLOOP.    "IUSERS
*
*  PERFORM step6 using i_orgchk .
*
*
** Get composite roles if necessary
**IS IT NECESSARY??
**  IF showcomp = 'X'.
**    PERFORM get_composite_roles.
**  ENDIF.
*
**  LOOP AT iduser_fm.
**    READ TABLE outputdet2 WITH KEY bname = iduser_fm-bname
**                                   BINARY SEARCH
**                                   TRANSPORTING NO FIELDS.
**    outputdet_idx = sy-tabix.
**    LOOP AT outputdet2 FROM outputdet_idx WHERE
**                            bname = iduser_fm-bname.
**      MOVE-CORRESPONDING outputdet2 TO outputdet3.
**      outputdet3-bname = iduser_fm-idbname.
***      DELETE outputdet2.
**      APPEND outputdet3.
**    ENDLOOP.
**  ENDLOOP.
*  APPEND LINES OF outputdet2 TO outputdet3.
*  REFRESH outputdet2.
*
*
*ENDFORM.                    " COMPARE_SODDEF_WITH_AUTH
**&---------------------------------------------------------------------*
**&      Form  refresh_internal_tables
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
**  -->  p1        text
**  <--  p2        text
**----------------------------------------------------------------------*
*form refresh_internal_tables.
*  REFRESH:    itcd,
*              userprof.
*
*endform.                    " refresh_internal_tables
**&---------------------------------------------------------------------*
**&      Form  step5
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM step5 using i_orgchk type flag.
*  DATA: ft_idx TYPE i,
*        cf_idx TYPE i.
**DATA: usertcode_idx   TYPE i,
** data :      userauth_idx    TYPE i,
**      itcdaut_idx     TYPE i.
**DATA: wa_outdet TYPE typ_outdet.
*
**  refresh suserauth.  clear suserauth.
**  insert lines of suserauth2 into suserauth where bname = iusers-bname.
*
*  READ TABLE susertcode WITH KEY bname = iusers-bname BINARY SEARCH
*                                         TRANSPORTING NO FIELDS.
*  usertcode_idx = sy-tabix.
*  LOOP AT susertcode FROM usertcode_idx WHERE bname = iusers-bname.
*    usertcode_idx = sy-tabix.
*    READ TABLE ft WITH KEY tcode = susertcode-tcode
*                                   BINARY SEARCH
*                                   TRANSPORTING NO FIELDS.
*    ft_idx = sy-tabix.
*    LOOP AT ft FROM ft_idx WHERE tcode = susertcode-tcode.
*      ft_idx = sy-tabix.
*      READ TABLE cf WITH KEY functionid = ft-functionid
*                                          BINARY SEARCH
*                                          TRANSPORTING NO FIELDS.
*      cf_idx = sy-tabix.
*      LOOP AT cf FROM cf_idx WHERE functionid = ft-functionid.
*        cf_idx = sy-tabix.
*        READ TABLE faobj WITH KEY funid = ft-functionid
*                                  tcode = susertcode-tcode
*                                  BINARY SEARCH
*                                  TRANSPORTING NO FIELDS.
*        IF sy-subrc <> 0.
*          wa_outdet-bname       = susertcode-bname.
*          wa_outdet-conid       = cf-conid.
*          wa_outdet-functionid  = cf-functionid.
*          wa_outdet-rfcdest     = susertcode-rfcdest.
*          wa_outdet-tcode       = susertcode-tcode.
*          wa_outdet-objct       = 'S_TCODE'.
*          wa_outdet-auth        = susertcode-auth.
*          wa_outdet-field       = 'TCD'.
*          wa_outdet-von         = susertcode-tcode.
*          wa_outdet-bis         = ''.
*          wa_outdet-description = ''. "not for performance
*          wa_outdet-agr_name    = susertcode-agr_name.
*          wa_outdet-profile     = susertcode-profn.
*          INSERT wa_outdet INTO TABLE outputdet5.
*          CLEAR wa_outdet.
*        ENDIF.
*        READ TABLE itcdaut WITH KEY rfcdest = susertcode-rfcdest
*                                      funid = ft-functionid
*                                      tcode = susertcode-tcode
*                                      BINARY SEARCH
*                                      TRANSPORTING NO FIELDS.
*        CHECK sy-subrc = 0.
*        itcdaut_idx = sy-tabix.
*        LOOP AT itcdaut FROM itcdaut_idx
*                        WHERE rfcdest = susertcode-rfcdest AND
*                                funid = ft-functionid AND
*                                tcode = susertcode-tcode.
*          READ TABLE suserauth WITH KEY bname = susertcode-bname
*                                     rfcdest  = itcdaut-rfcdest
*                                     objct    = itcdaut-objct
*                                     auth     = itcdaut-auth
*                                     BINARY SEARCH
*                                     TRANSPORTING NO FIELDS.
*          CHECK sy-subrc = 0. "if not skip to next tcode/auth combo
*          userauth_idx = sy-tabix.
*          LOOP AT suserauth FROM userauth_idx
*                           WHERE bname    = susertcode-bname AND
*                                 rfcdest  = itcdaut-rfcdest AND
*                                 objct    = itcdaut-objct   AND
*                                 auth     = itcdaut-auth.
*            userauth_idx = sy-tabix.
*            wa_outdet-bname       = susertcode-bname.
*            wa_outdet-conid       = cf-conid.
*            wa_outdet-functionid  = cf-functionid.
*            wa_outdet-rfcdest     = susertcode-rfcdest.
*            wa_outdet-tcode       = susertcode-tcode.
*            wa_outdet-objct       = 'S_TCODE'.
*            wa_outdet-auth        = susertcode-auth.
*            wa_outdet-field       = 'TCD'.
*            wa_outdet-von         = susertcode-tcode.
*            wa_outdet-bis         = ''.
*            wa_outdet-description = ''.  "not for performance
*            wa_outdet-agr_name    = susertcode-agr_name.
*            wa_outdet-profile     = susertcode-profn.
*            INSERT wa_outdet INTO TABLE outputdet5.
*            CLEAR wa_outdet.
*
*            wa_outdet-bname       = susertcode-bname.
*            wa_outdet-conid       = cf-conid.
*            wa_outdet-functionid  = cf-functionid.
*            wa_outdet-rfcdest     = suserauth-rfcdest.
*            wa_outdet-tcode       = susertcode-tcode.
*            wa_outdet-objct       = suserauth-objct.
*            wa_outdet-auth        = suserauth-auth.
*            wa_outdet-field       = itcdaut-field.
*            wa_outdet-von         = itcdaut-von.
*            wa_outdet-bis         = itcdaut-bis.
*            wa_outdet-description = ''.  "not for performance
*            wa_outdet-agr_name    = suserauth-agr_name.
*            wa_outdet-profile     = suserauth-profn.
*            INSERT wa_outdet INTO TABLE outputdet5.
*            CLEAR wa_outdet.
*            MODIFY tobjs1 FROM wa_tobjs1 TRANSPORTING
*                   userhas WHERE
*                                funid  = ft-functionid AND
*                                tcode  = susertcode-tcode AND
*                                object = suserauth-objct.
*          ENDLOOP.  "USERAUTH
*        ENDLOOP. "itcdaut
*      ENDLOOP.       "confdet
**      AT END OF tcode.
*      AT END OF functionid.
*        LOOP AT tobjs1 WHERE funid = ft-functionid AND
*                             tcode = susertcode-tcode AND
*                             obj_or NE 'OR' AND
*                             userhas <> 'Y' .
*          REFRESH outputdet5.
*        ENDLOOP.
*        CHECK sy-subrc <> 0.  "if user has at least 1 auth for all objs
*        LOOP AT outputdet5.
*          INSERT outputdet5 INTO TABLE outputdet.
*        ENDLOOP.
*        REFRESH outputdet5.
*        tobjs1[] = tobjs3[].
*      ENDAT.
*    ENDLOOP.  "functtran
*  ENDLOOP.                                                  "usertcode1
*
*  DELETE susertcode WHERE bname = iusers-bname.
*  DELETE suserauth WHERE bname = iusers-bname.
*ENDFORM.                                                    " step5
**&---------------------------------------------------------------------*
**&      Form  step6
**&---------------------------------------------------------------------*
*FORM step6 using i_orgchk type flag.
**data for org level reporting
*  DATA : wa_systemauth     TYPE           /psyng/swsodorgauth,
*         ls_orgm           TYPE           /psyng/swsodorgm,
*         ls_out            LIKE LINE OF   outputdet2,
*         lt_outputdet_org  LIKE TABLE OF  outputdet,
*  BEGIN OF lt_confs_org    OCCURS 0,
*         conid             TYPE           /psyng/conflict_id,
*         funid             TYPE           /psyng/function_id,
*         abb               TYPE           /psyng/dorg_abb,
*  END OF lt_confs_org,
*         ls_confs_org      LIKE LINE OF   lt_confs_org,
*         ls_hit            TYPE           flag.
*  FIELD-SYMBOLS :
*         <confs_org>       LIKE           ls_confs_org,
*         <confs>           LIKE LINE OF   confs1.
**data for org level reporting
*
*  outputdet2[] = outputdet[].
*  gr_role-sign   = 'I'.
*  gr_role-option = 'EQ'.
*  LOOP AT outputdet.
*    AT NEW bname.
*      confs1[] = confs2[].
*      if i_orgchk = 'X'. "dhorions 11/18/2008
*        free : lt_confs_org[].
*      endif.
*    ENDAT.
*
*    LOOP AT confs1 WHERE conid = outputdet-conid.
*      IF confs1-functionid = outputdet-functionid.
*        confs1-userhas = 'Y'.
**       org level reporting
*        IF i_orgchk = 'X'.
*          read table gt_SYSTEMAUTHS with key
*            auth = outputdet-auth
*            object = outputdet-objct
*            transporting no fields.
*          if sy-subrc = 0.
*            LOOP AT  gt_systemauths from sy-tabix
*            INTO  wa_systemauth
*            WHERE auth = outputdet-auth AND
*            object = outputdet-objct .
*              CLEAR ls_out.
*              ls_out = outputdet.
*              ls_out-org_abb = wa_systemauth-abb.
*              READ TABLE swsodorgm
*              INTO ls_orgm
*              WITH KEY
*                abb = ls_out-org_abb
*                object = ls_out-objct.
*              IF sy-subrc = 0.
*                ls_out-field = ls_orgm-varbl.
*                ls_out-von = ls_orgm-low.
*                ls_out-bis = ls_orgm-high.
*                APPEND ls_out TO lt_outputdet_org.
**              add these org levels for the function as well
*                CLEAR ls_confs_org.
*                ls_confs_org-conid = confs1-conid.
*                ls_confs_org-funid = confs1-functionid.
*                ls_confs_org-abb = ls_out-org_abb.
*                APPEND ls_confs_org TO lt_confs_org.
*              ENDIF.
*            ENDLOOP.
**check if object has any org level specific values based on object
*          else.
*            READ TABLE swsodorgm
*            INTO ls_orgm
*            WITH KEY
*              object = outputdet-objct.
*            if sy-subrc = 0.
*              ls_confs_org-conid = confs1-conid.
*              ls_confs_org-funid = confs1-functionid.
*              clear ls_confs_org-abb ."leave blank
*              APPEND ls_confs_org TO lt_confs_org.
*            endif.
**check if object has any org level specific values based on object
*          endif.
*        ENDIF."org check
**       org level reporting
*        MODIFY confs1.
*      ENDIF.
*    ENDLOOP.
*
*    AT END OF bname.
*      LOOP AT confs1 WHERE userhas NE 'Y'.
*        DELETE outputdet2 WHERE bname = outputdet-bname AND
*                                conid = confs1-conid.
**       org level reporting
*        IF i_orgchk = 'X'.
*          DELETE lt_outputdet_org WHERE bname = outputdet-bname AND
*                   conid = confs1-conid.
**       dhorions 11/24/2008 : Delete functions that are org level
**       specific but for which the user doesn't match any org level
*          delete lt_confs_org where abb = ''.
*        ENDIF.
**       org level reporting
*        DELETE confs1 WHERE conid = confs1-conid.
*      ENDLOOP.
**       org level reporting
*      IF NOT i_orgchk IS INITIAL.
*        SORT : confs1, lt_confs_org.
*        LOOP AT confs1.
**         check if at least 1 orglevel for this function
**         occurs in all other functions for conflict
*          CLEAR ls_hit.
*          LOOP AT confs1 ASSIGNING <confs>
*                  WHERE conid      = confs1-conid AND
*                        functionid <> confs1-functionid.
*            read table lt_confs_org with key
*                   conid = confs1-conid
*                   funid = confs1-functionid.
*            if sy-subrc = 0.
*              LOOP AT lt_confs_org from sy-tabix ASSIGNING <confs_org>
*               WHERE conid = confs1-conid AND
*                     funid = confs1-functionid.
*                READ TABLE lt_confs_org WITH KEY
*                    conid = confs1-conid
*                    funid = <confs>-functionid
*                    abb   = <confs_org>-abb.
*                IF sy-subrc = 0 and not <confs_org>-abb is initial.
*                  ls_hit = 'X'.
*                  EXIT.
*                else.
*                  READ TABLE lt_confs_org WITH KEY
*                      conid = confs1-conid
*                      funid = <confs>-functionid.
*                  if sy-subrc = 4.
**                   there are no org levels in this conflict.
*                    ls_hit = 'X'.
*                    exit.
*                  else.
**                    there are org levels,
**                    they just don't match any we are looking for
*                  endif.
*                ENDIF.
*              ENDLOOP.
*            else.
**           there are no org levels in this conflict.
*              ls_hit = 'X'.
*            endif.
*          ENDLOOP.
*          IF ls_hit <> 'X'.
*            DELETE outputdet2 WHERE bname = outputdet-bname AND
*                   conid = confs1-conid.
*            DELETE lt_outputdet_org WHERE bname = outputdet-bname AND
*                   conid = confs1-conid.
*          ENDIF.
*        ENDLOOP.
*      ENDIF. "org check
**       org level reporting
*      REFRESH confs1.
*      confs1[] = confs2[].
*    ENDAT.
*
**   Collect role names for finding composite roles later
*    IF showcomp = 'X'.
*      gr_role-low = outputdet-agr_name.
*      COLLECT gr_role.
*    ENDIF.
*  ENDLOOP.
**       org level reporting
*  IF i_orgchk = 'X' .
**add the org level fields to outputdet2, but since this is
*    SORT lt_outputdet_org.
*    DELETE ADJACENT DUPLICATES FROM lt_outputdet_org.
*    APPEND LINES OF outputdet2 TO lt_outputdet_org.
*    SORT lt_outputdet_org BY
*         bname conid functionid
*         agr_name rfcdest tcode
*         objct auth field
*         von bis profile.
*    DELETE ADJACENT DUPLICATES FROM lt_outputdet_org COMPARING
*    bname conid functionid
*    agr_name rfcdest tcode
*    objct auth field
*    von bis profile.
*    outputdet2[] = lt_outputdet_org[].
*  ENDIF."org check
**       org level reporting
*  REFRESH outputdet.
*  DELETE outputdet2 WHERE bname = space.
*
*ENDFORM.                                                    " step6
**&---------------------------------------------------------------------*
**&      Form  remove_stuff_for_performance
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM remove_stuff_for_performance.
*DATA: confdet_tmp TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
*                  conid functionid
*                  WITH HEADER LINE.
*DATA: BEGIN OF functtran2 OCCURS 100.
*        INCLUDE STRUCTURE /psyng/functtran.
*DATA: END OF functtran2.
*  DO 3 TIMES.  "this way all unneeded stuff is removed objects/functions
*    LOOP AT faobj.
*      READ TABLE itcd WITH KEY tcode = faobj-tcode
*                                       BINARY SEARCH
*                                       TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE faobj.
*      DELETE gt_enh_tcodes WHERE calling_tcode = faobj-tcode.
*    ENDLOOP.
*
*    LOOP AT functtran.
*      READ TABLE itcd WITH KEY tcode = functtran-tcode
*                                       BINARY SEARCH
*                                       TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE functtran WHERE tcode = functtran-tcode.
*    ENDLOOP.
*
*    SORT functtran.
*    confdet_tmp[] = confdet[].
*    LOOP AT confdet_tmp.
*      READ TABLE functtran WITH KEY functionid = confdet_tmp-functionid
*                                   BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE confdet WHERE conid = confdet_tmp-conid.
*    ENDLOOP.
*
*    confdet_tmp[] = confdet[].
*    LOOP AT confdet_tmp.
*      AT NEW conid.
*        confs1[] = confs2[].
*      ENDAT.
*
*      LOOP AT confs1 WHERE conid = confdet_tmp-conid AND
*                      functionid = confdet_tmp-functionid.
*        confs1-userhas = 'Y'.
*        MODIFY confs1.
*      ENDLOOP.
*
*      AT END OF conid.
*      LOOP AT confs1 WHERE conid = confdet_tmp-conid AND userhas NE 'Y'.
*          DELETE confdet WHERE conid = confs1-conid.
*        ENDLOOP.
*        REFRESH confs1.
*        confs1[] = confs2[].
*      ENDAT.
*    ENDLOOP.
*    confdet_tmp[] = confdet[].
*
*    functtran2[] = functtran[].
*    LOOP AT functtran2.
*      LOOP AT confdet WHERE functionid = functtran2-functionid.
*        EXIT.
*      ENDLOOP.
*      CHECK sy-subrc <> 0.
*      DELETE functtran WHERE functionid = functtran2-functionid.
*    ENDLOOP.
*    REFRESH functtran2.
*
*    LOOP AT itcd.
*      LOOP AT functtran WHERE tcode = itcd-tcode.
*        EXIT.
*      ENDLOOP.
*      CHECK sy-subrc <> 0.
*      DELETE itcd.
*    ENDLOOP.
*    itcd2[] = itcd[].  "since sorted table can't be passed to FM
*
*    LOOP AT susertcode.
*      READ TABLE itcd WITH KEY tcode = susertcode-tcode BINARY SEARCH
*                                       TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE susertcode.
*    ENDLOOP.
*
*  ENDDO.
*ENDFORM.         "remove_stuff_for_performance
