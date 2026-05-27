*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_008
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_008.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(ENH_FM) TYPE  FLAG DEFAULT ''
*"  TABLES
*"      IT_USERID STRUCTURE  /PSYNG/SW_SEL_OPTS_XUBNAME OPTIONAL
*"      IT_CONID STRUCTURE  /PSYNG/RANGE_CONID OPTIONAL
*"      IT_SIMULATION_ROLE STRUCTURE  /PSYNG/RANGE_AGR_NAME OPTIONAL
*"      ET_RESULTS STRUCTURE  /PSYNG/SW_SOD_RESULTS OPTIONAL
*"      ET_RETURN STRUCTURE  BAPIRET2 OPTIONAL
*"      IT_REMOTE_ROLE_SIMU STRUCTURE  /PSYNG/SW_SOD_REMOTE_ROLES
*"       OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_008'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE s089(/psyng/sw) WITH lc_fname
    DISPLAY LIKE 'E'.
    EXIT.
  ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
  MESSAGE e002(/psyng/sw) WITH 'Function Module /PSYNG/SW_008 is obsolete'.

ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  FILL_INTERNAL_TABLES
*&---------------------------------------------------------------------*
*       Populate some global internal tables
*----------------------------------------------------------------------*
*FORM fill_internal_tables TABLES
*                          it_userid STRUCTURE /psyng/sw_sel_opts_xubname
*                          it_conid  STRUCTURE /psyng/range_conid
*                          USING
*                          vrsio  type /psyng/sodvrsio
*                          enh_fm type flag.
** Get users
*  IF it_userid IS INITIAL.
*    wa_gt_users-bname = '000000000000'.
*    INSERT wa_gt_users INTO TABLE gt_users.
*  ELSE.
*    SELECT bname INTO TABLE gt_users FROM usr02
*               WHERE bname IN it_userid.
*  ENDIF.
** Get SOD Matrix
*CALL FUNCTION '/PSYNG/SW_028'
* EXPORTING
*   I_VRSIO                  = vrsio
*   I_ORGCHECK         = ''
*   I_ENHANCE          = enh_fm
* TABLES
*   IT_SPCONFS         = it_conid
**   IT_BUS_AREA        =
**   IT_IMP             =
**   IT_COWNER          =
**   IT_CONTID          =
**   IT_ORG             =
*   ET_CONFLICT        = gt_conflict
*   ET_CONFDET         = gt_confdet
*   ET_FUNCTTRAN       = gt_functtran
*   ET_FAOBJ           = gt_faobj
**   ET_SWSODORGM       =
**   ET_TCODES          =
*          .
*ENDFORM.                    " FILL_INTERNAL_TABLES
*
**---------------------------------------------------------------------*
**       FORM GET_IDCL_USER                                            *
**---------------------------------------------------------------------*
**  -->  TASKNAME                                                      *
**---------------------------------------------------------------------*
*FORM get_idcl_user USING taskname.
*  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_IDCL_USER'
*    TABLES
*      iduser_fm       = gt_iduser.
*ENDFORM.
*
**&---------------------------------------------------------------------*
**&      Form  COMPARE_SODDEF_WITH_AUTH_NEW
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM compare_soddef_with_auth_new.
*  DATA: ls_cf           TYPE t_cf,
*        ls_ft           TYPE t_ft,
*        l_outputdet_idx TYPE i.
*
*
*  LOOP AT gt_functtran.
*    MOVE-CORRESPONDING gt_functtran TO ls_ft.
*    INSERT ls_ft INTO TABLE gt_ft.
*  ENDLOOP.
*
*  LOOP AT gt_confdet.
*    MOVE-CORRESPONDING gt_confdet TO ls_cf.
*    INSERT ls_cf INTO TABLE gt_cf.
*  ENDLOOP.
*
*  REFRESH: gt_functtran, gt_confdet.
*  CLEAR: gt_functtran, gt_confdet.
*  SORT gt_faobj BY funid tcode object field val_from val_to.
*  LOOP AT gt_users.
*    gs_tobjs1-userhas = 'Y'.
*    PERFORM step5.
*  ENDLOOP.    "gt_users
*
*  PERFORM step6.
*  PERFORM fill_conflict_description.
*
*  LOOP AT gt_iduser.
*    READ TABLE gt_outputdet2 WITH KEY bname = gt_iduser-bname
*                             BINARY SEARCH TRANSPORTING NO FIELDS.
*    l_outputdet_idx = sy-tabix.
*    LOOP AT gt_outputdet2 FROM l_outputdet_idx WHERE
*                            bname = gt_iduser-bname.
*      MOVE-CORRESPONDING gt_outputdet2 TO gt_outputdet3.
*      gt_outputdet3-bname = gt_iduser-idbname.
*      APPEND gt_outputdet3.
*    ENDLOOP.
*  ENDLOOP.
*
*  APPEND LINES OF gt_outputdet2 TO gt_outputdet3.
*  REFRESH gt_outputdet2.
*ENDFORM.         "compare_soddef_with_auth_new
*
**&---------------------------------------------------------------------*
**&      Form  step5
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM step5.
*  DATA: l_usertcode_idx TYPE i,
*        l_tcdaut_idx    TYPE i,
*        l_userauth_idx  TYPE i,
*        l_ft_idx        TYPE i,
*        l_cf_idx        TYPE i,
*        ls_outdet       TYPE t_outdet,
*        lt_outputdet    TYPE SORTED TABLE OF t_outdet WITH UNIQUE KEY
*                        bname conid functionid agr_name rfcdest tcode
*                        objct auth field von bis profile
*                        WITH HEADER LINE.
*
*
*  READ TABLE gt_usertcode WITH KEY bname = gt_users-bname BINARY SEARCH
*                          TRANSPORTING NO FIELDS.
*  l_usertcode_idx = sy-tabix.
*  LOOP AT gt_usertcode FROM l_usertcode_idx
*          WHERE bname = gt_users-bname.
*
*    l_usertcode_idx = sy-tabix.
*    READ TABLE gt_ft WITH KEY tcode = gt_usertcode-tcode
*                     BINARY SEARCH TRANSPORTING NO FIELDS.
*    l_ft_idx = sy-tabix.
*    LOOP AT gt_ft FROM l_ft_idx WHERE tcode = gt_usertcode-tcode.
*      l_ft_idx = sy-tabix.
*      READ TABLE gt_cf WITH KEY functionid = gt_ft-functionid
*                       BINARY SEARCH TRANSPORTING NO FIELDS.
*      l_cf_idx = sy-tabix.
*      LOOP AT gt_cf FROM l_cf_idx WHERE functionid = gt_ft-functionid.
*        l_cf_idx = sy-tabix.
*        READ TABLE gt_faobj WITH KEY funid = gt_ft-functionid
*                                     tcode = gt_usertcode-tcode
*                                     BINARY SEARCH
*                                     TRANSPORTING NO FIELDS.
*        IF sy-subrc <> 0.
*          ls_outdet-bname       = gt_usertcode-bname.
*          ls_outdet-conid       = gt_cf-conid.
*          ls_outdet-functionid  = gt_cf-functionid.
*          ls_outdet-rfcdest     = gt_usertcode-rfcdest.
*          ls_outdet-tcode       = gt_usertcode-tcode.
*          ls_outdet-objct       = 'S_TCODE'.
*          ls_outdet-auth        = gt_usertcode-auth.
**          ls_outdet-field       = 'TCD'.
**          ls_outdet-von         = gt_usertcode-tcode.
*          ls_outdet-bis         = ''.
*          ls_outdet-description = ''. "not for performance
*          ls_outdet-agr_name    = gt_usertcode-agr_name.
*          ls_outdet-profile     = gt_usertcode-profn.
*          INSERT ls_outdet INTO TABLE lt_outputdet.
*          CLEAR ls_outdet.
*        ENDIF.
*
*        READ TABLE gt_tcdaut WITH KEY rfcdest = gt_usertcode-rfcdest
*                                      funid   = gt_ft-functionid
*                                      tcode   = gt_usertcode-tcode
*                                      BINARY SEARCH
*                                      TRANSPORTING NO FIELDS.
*        CHECK sy-subrc = 0.
*        l_tcdaut_idx = sy-tabix.
*        LOOP AT gt_tcdaut FROM l_tcdaut_idx
*                        WHERE rfcdest = gt_usertcode-rfcdest AND
*                              funid   = gt_ft-functionid AND
*                              tcode   = gt_usertcode-tcode.
*          READ TABLE gt_userauth WITH KEY bname = gt_usertcode-bname
*                                          rfcdest  = gt_tcdaut-rfcdest
*                                          objct    = gt_tcdaut-objct
*                                          auth     = gt_tcdaut-auth
*                                          BINARY SEARCH
*                                          TRANSPORTING NO FIELDS.
*          CHECK sy-subrc = 0. "if not skip to next tcode/auth combo
*          l_userauth_idx = sy-tabix.
*          LOOP AT gt_userauth FROM l_userauth_idx
*                              WHERE bname    = gt_usertcode-bname AND
*                                    rfcdest  = gt_tcdaut-rfcdest AND
*                                    objct    = gt_tcdaut-objct   AND
*                                    auth     = gt_tcdaut-auth.
*            l_userauth_idx = sy-tabix.
*            ls_outdet-bname       = gt_usertcode-bname.
*            ls_outdet-conid       = gt_cf-conid.
*            ls_outdet-functionid  = gt_cf-functionid.
*            ls_outdet-rfcdest     = gt_usertcode-rfcdest.
*            ls_outdet-tcode       = gt_usertcode-tcode.
*            ls_outdet-objct       = 'S_TCODE'.
*            ls_outdet-auth        = gt_usertcode-auth.
*            ls_outdet-field       = 'TCD'.
*            ls_outdet-von         = gt_usertcode-tcode.
*            ls_outdet-bis         = ''.
*            ls_outdet-description = ''.  "not for performance
*            ls_outdet-agr_name    = gt_usertcode-agr_name.
*            ls_outdet-profile     = gt_usertcode-profn.
*            INSERT ls_outdet INTO TABLE lt_outputdet.
*            CLEAR ls_outdet.
*
*            ls_outdet-bname       = gt_usertcode-bname.
*            ls_outdet-conid       = gt_cf-conid.
*            ls_outdet-functionid  = gt_cf-functionid.
*            ls_outdet-rfcdest     = gt_userauth-rfcdest.
*            ls_outdet-tcode       = gt_usertcode-tcode.
*            ls_outdet-objct       = gt_userauth-objct.
*            ls_outdet-auth        = gt_userauth-auth.
*            ls_outdet-field       = gt_tcdaut-field.
*            ls_outdet-von         = gt_tcdaut-von.
*            ls_outdet-bis         = gt_tcdaut-bis.
*            ls_outdet-description = ''.  "not for performance
*            ls_outdet-agr_name    = gt_userauth-agr_name.
*            ls_outdet-profile     = gt_userauth-profn.
*            INSERT ls_outdet INTO TABLE lt_outputdet.
*            CLEAR ls_outdet.
*            MODIFY gt_tobjs1 FROM gs_tobjs1 TRANSPORTING userhas
*                             WHERE funid  = gt_ft-functionid
*                               AND tcode  = gt_usertcode-tcode
*                               AND object = gt_userauth-objct.
*          ENDLOOP.  "USERAUTH
*        ENDLOOP. "gt_tcdaut
*      ENDLOOP.       "confdet
*
*      AT END OF functionid.
*        LOOP AT gt_tobjs1 WHERE funid = gt_ft-functionid
*                            AND tcode = gt_usertcode-tcode
*                            AND userhas <> 'Y'.
*          REFRESH lt_outputdet.
*        ENDLOOP.
*
*        CHECK sy-subrc <> 0.  "if user has at least 1 auth for all objs
*
*        LOOP AT lt_outputdet.
*          INSERT lt_outputdet INTO TABLE gt_outputdet.
*        ENDLOOP.
*
*        REFRESH lt_outputdet.
*        gt_tobjs1[] = gt_tobjs3[].
*      ENDAT.
*    ENDLOOP.  "gt_ft
*  ENDLOOP.    "gt_usertcode
*
*  DELETE gt_usertcode WHERE bname = gt_users-bname.
*  DELETE gt_userauth  WHERE bname = gt_users-bname.
*ENDFORM.                                                    " step5
*
**&---------------------------------------------------------------------*
**&      Form  step6
**&---------------------------------------------------------------------*
*FORM step6.
*  gt_outputdet2[] = gt_outputdet[].
*  LOOP AT gt_outputdet.
*    AT NEW bname.
*      gt_confs1[] = gt_confs2[].
*    ENDAT.
*
*    LOOP AT gt_confs1 WHERE conid = gt_outputdet-conid.
*      IF gt_confs1-functionid = gt_outputdet-functionid.
*        gt_confs1-userhas = 'Y'.
*        MODIFY gt_confs1.
*      ENDIF.
*    ENDLOOP.
*
*    AT END OF bname.
*      LOOP AT gt_confs1 WHERE userhas NE 'Y'.
*        DELETE gt_outputdet2 WHERE bname = gt_outputdet-bname
*                               AND conid = gt_confs1-conid.
*      ENDLOOP.
*
*      gt_confs1[] = gt_confs2[].
*    ENDAT.
*  ENDLOOP.
*
*  REFRESH gt_outputdet.
*  DELETE gt_outputdet2 WHERE bname = space.
*ENDFORM.                                                    " step6
*
**&---------------------------------------------------------------------*
**&      Form  fill_conflict_description
**&---------------------------------------------------------------------*
*FORM fill_conflict_description.
*  DATA: ls_outdet TYPE t_outdet.
*
*  CLEAR ls_outdet.
*  LOOP AT gt_users.
*    LOOP AT gt_conflict.
*      ls_outdet-description = gt_conflict-description.
*      ls_outdet-imp         = gt_conflict-imp.
*      MODIFY gt_outputdet2 FROM ls_outdet
*             TRANSPORTING description imp
*             WHERE bname = gt_users-bname
*               AND conid = gt_conflict-conid.
*    ENDLOOP.
*  ENDLOOP.
*ENDFORM.                    " fill_conflict_description
*
**&---------------------------------------------------------------------*
**&      Form  remove_stuff_for_performance
**&---------------------------------------------------------------------*
**       text
**----------------------------------------------------------------------*
*FORM remove_stuff_for_performance.
* DATA: lt_confdet   TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
*                       conid functionid WITH HEADER LINE,
*          lt_functtran TYPE TABLE OF /psyng/functtran WITH HEADER LINE.
*
*
*  DO 3 TIMES.  "this way all unneeded stuff is removed objects/functions
*    LOOP AT gt_faobj.
*      READ TABLE gt_tcd WITH KEY tcode = gt_faobj-tcode
*                 BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE gt_faobj.
*    ENDLOOP.
*
*    LOOP AT gt_functtran.
*      READ TABLE gt_tcd WITH KEY tcode = gt_functtran-tcode
*                 BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE gt_functtran WHERE tcode = gt_functtran-tcode.
*    ENDLOOP.
*
*    SORT gt_functtran.
*    lt_confdet[] = gt_confdet[].
*    LOOP AT lt_confdet.
*      READ TABLE gt_functtran
*                 WITH KEY functionid = lt_confdet-functionid
*                 BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE gt_confdet WHERE conid = lt_confdet-conid.
*    ENDLOOP.
*
*    lt_confdet[] = gt_confdet[].
*    LOOP AT lt_confdet.
*      AT NEW conid.
*        gt_confs1[] = gt_confs2[].
*      ENDAT.
*
*      LOOP AT gt_confs1 WHERE conid = lt_confdet-conid
*                          AND functionid = lt_confdet-functionid.
*        gt_confs1-userhas = 'Y'.
*        MODIFY gt_confs1.
*      ENDLOOP.
*
*      AT END OF conid.
*        LOOP AT gt_confs1 WHERE conid = lt_confdet-conid
*                            AND userhas NE 'Y'.
*          DELETE gt_confdet WHERE conid = gt_confs1-conid.
*        ENDLOOP.
*
*        REFRESH gt_confs1.
*        gt_confs1[] = gt_confs2[].
*      ENDAT.
*    ENDLOOP.
*
*    lt_confdet[] = gt_confdet[].
*    lt_functtran[] = gt_functtran[].
*
*    LOOP AT lt_functtran.
*      READ TABLE gt_confdet
*                 WITH KEY functionid = lt_functtran-functionid
*                 BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE gt_functtran WHERE functionid = lt_functtran-functionid.
*    ENDLOOP.
*
*    LOOP AT gt_tcd.
*      LOOP AT gt_functtran WHERE tcode = gt_tcd-tcode.
*        EXIT.
*      ENDLOOP.
*
*      CHECK sy-subrc <> 0.
*      DELETE gt_tcd.
*    ENDLOOP.
*
*    LOOP AT gt_usertcode.
*      READ TABLE gt_tcd WITH KEY tcode = gt_usertcode-tcode
*                 BINARY SEARCH TRANSPORTING NO FIELDS.
*      CHECK sy-subrc <> 0.
*      DELETE gt_usertcode.
*    ENDLOOP.
*  ENDDO.
*ENDFORM.         "remove_stuff_for_performance
*
*FORM load_rfc
*    TABLES
*      it_role_rfc STRUCTURE /PSYNG/SW_SOD_REMOTE_ROLES
*      et_rfcdes STRUCTURE rfcdes.
*  .
*  DATA : l_rfcdest TYPE rfcdes-rfcdest,
*         l_system_msg(80) TYPE c,
*         l_local_sys TYPE rfcdest.
*  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.
*
*  IF NOT it_role_rfc[] IS INITIAL.
*    SELECT rfcdest FROM rfcdes
*           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
*           for all entries in it_role_rfc where
*           rfcdest = it_role_rfc-rfcdest.
*  ENDIF.
**--Get sysid and mandt into field RFCOPTIONS
*  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
*    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
*    DESTINATION <rfcdes>-rfcdest
*     IMPORTING
*       e_rfcdest       = l_rfcdest
*    EXCEPTIONS
*          communication_failure = 1 MESSAGE l_system_msg
*          system_failure        = 2 MESSAGE l_system_msg
*          OTHERS                = 3.
*    IF sy-subrc <> 0.
*      CASE sy-subrc.
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH
*          text-e02
*          l_rfcdest
*          l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH
*          text-e02
*          l_rfcdest.
*      ENDCASE.
*      COMMIT WORK.
*    ELSE.
*      <rfcdes>-rfcoptions = l_rfcdest.
*    ENDIF.
*  ENDLOOP.
*
**--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
**  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
**  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
**  AND rfcdest <> 'LOCAL'.
**Case 2061 - If 2 rfc destinations point to the same system-client,
**            we still only output the results once.
*  SORT et_rfcdes BY rfcoptions.
*  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
*
*ENDFORM.                    " validate_user_rfc
