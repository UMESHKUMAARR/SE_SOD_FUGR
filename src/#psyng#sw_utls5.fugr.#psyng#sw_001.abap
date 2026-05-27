*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_001
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_001.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(USERID) LIKE  UST04-BNAME OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_DETAILS) TYPE  FLAG DEFAULT ' '
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      OUTPUT STRUCTURE  /PSYNG/OUTPUT OPTIONAL
*"      OUTPUTDET STRUCTURE  /PSYNG/SW_CA_OUTPUTDET OPTIONAL
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_001'.
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


  DATA : ls_outputdet TYPE /psyng/sw_ca_outputdet,
         ls_output TYPE /psyng/output.
  gf_details = i_details.

  PERFORM refresh_internal_tables.

  PERFORM start_child_get_user_name USING userid vrsio.

  SELECT * FROM /psyng/swaudc2
           INTO CORRESPONDING FIELDS OF TABLE iswaudc
           WHERE vrsio = vrsio.
*           WHERE swaudid IN paudid.

  LOOP AT iswaudc.
    audcobjs-objct = iswaudc-object.
    APPEND audcobjs.
  ENDLOOP.
  SORT audcobjs.
  DELETE ADJACENT DUPLICATES FROM audcobjs.

* REFERENCE USER begin of addition 1
  if not iusr02[] is initial.
    SELECT bname refuser FROM usrefus
      INTO CORRESPONDING FIELDS OF TABLE iusrefus1
      FOR ALL ENTRIES IN iusr02 WHERE bname = iusr02-bname AND
      refuser NE space."#EC SAST_CI_GEN_CHECK
  endif.
* add reference users to the list of users to get profiles for
  LOOP AT iusrefus1.
    wa_usr02-bname = iusrefus1-refuser.
    wa_usr02-class = 'REFUSER'.
    INSERT wa_usr02 INTO TABLE iusr02.
  ENDLOOP.
* REFERENCE USER end of addition 1
  if not audcobjs[] is initial.
    SELECT profn objct auth FROM ust10s
           INTO CORRESPONDING FIELDS OF TABLE iust10s
           FOR ALL ENTRIES IN audcobjs WHERE objct = audcobjs-objct
           AND aktps = 'A'."#EC SAST_CI_GEN_CHECK
  endif.
  REFRESH: audcobjs.


  SELECT bname profile FROM ust04
         INTO CORRESPONDING FIELDS OF TABLE iust04.

  SORT iusr02.
  LOOP AT iust04.
    READ TABLE iusr02 WITH KEY bname = iust04-bname
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    CHECK sy-subrc <> 0.
    DELETE iust04.
  ENDLOOP.


  CHECK NOT iust04[] IS INITIAL.

  SELECT * FROM ust10c INTO CORRESPONDING FIELDS OF TABLE iust10c.
  LOOP AT iust04.
    profiles-profn = iust04-profile.
    APPEND profiles.
    MOVE-CORRESPONDING iust04 TO iiust04.
    APPEND iiust04.
    PERFORM get_single_profiles.
    LOOP AT profinfo.
      profiles-profn = profinfo-profn.
      APPEND profiles.
      CHECK profinfo-profn <> iust04-profile. "only on comp profiles
      iiust04-bname = iust04-bname.
      iiust04-profile = profinfo-profn.
      iiust04-cprofn = iust04-profile.
      APPEND iiust04.
    ENDLOOP.
    REFRESH profinfo.
    CLEAR profinfo.
  ENDLOOP.
  SORT: profiles, iiust04.
  DELETE ADJACENT DUPLICATES FROM profiles.
  DELETE ADJACENT DUPLICATES FROM iiust04.
  REFRESH: iust04.
  iust04[] = iiust04[].
  REFRESH: iiust04.

  LOOP AT iust10s.
    READ TABLE profiles WITH KEY profn = iust10s-profn BINARY SEARCH
                                         TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE iust10s.
    ELSE.
      10sobjs-objct = iust10s-objct.
      10sobjs-auth = iust10s-auth.
      APPEND 10sobjs.
    ENDIF.
  ENDLOOP.
  SORT 10sobjs.
  DELETE ADJACENT DUPLICATES FROM 10sobjs.

  CHECK NOT 10sobjs[] IS INITIAL.
  SELECT * FROM ust12
           INTO CORRESPONDING FIELDS OF TABLE iust12
           FOR ALL ENTRIES IN 10sobjs WHERE objct = 10sobjs-objct AND
                                            auth = 10sobjs-auth AND
                                            aktps = 'A'.
  REFRESH: 10sobjs.
  SORT: iust12.

  CALL FUNCTION '/PSYNG/SW_USER_CRI_AUTH_DATA'
       TABLES
            usertcode = usertcode
            userprof  = userprof
            userauth  = userauth
            iust12    = iust12
            swaudc    = iswaudc
            iusr02    = iusr02.

* Get auths for tcodes that are critical
  CALL FUNCTION '/PSYNG/SW_GET_CRIT_AUTH_DATA'
       TABLES
            tcdaut = tcdaut
            iust12 = iust12
            swaudc = iswaudc.

* REFERENCE USER begin of addition 2
  LOOP AT iusrefus1.
    LOOP AT userauth WHERE bname = iusrefus1-refuser.
      MOVE-CORRESPONDING userauth TO iuserauth.
      iuserauth-bname = iusrefus1-bname.
      APPEND iuserauth.
      DELETE userauth.
    ENDLOOP.
  ENDLOOP.
* REFERENCE USER begin of addition 2

  LOOP AT userauth.
    MOVE-CORRESPONDING userauth TO iuserauth.
    APPEND iuserauth.
    DELETE userauth.
  ENDLOOP.
  REFRESH userauth.  CLEAR userauth.

* REFERENCE USER begin of addition 3
  LOOP AT iusrefus1.
    LOOP AT usertcode WHERE bname = iusrefus1-refuser.
      MOVE-CORRESPONDING usertcode TO iusertcode.
      iusertcode-bname = iusrefus1-bname.
      APPEND iusertcode.
      DELETE usertcode.
    ENDLOOP.
  ENDLOOP.
  DELETE iusr02 WHERE class = 'REFUSER'.
* REFERENCE USER begin of addition 3

  LOOP AT usertcode.
    MOVE-CORRESPONDING usertcode TO iusertcode.
    APPEND iusertcode.
    DELETE usertcode.
  ENDLOOP.
  REFRESH usertcode.  CLEAR usertcode.

  LOOP AT tcdaut.
    MOVE-CORRESPONDING tcdaut TO itcdaut.
    itcdaut-swaudid = tcdaut-funid.
    DELETE tcdaut.
    APPEND itcdaut.
  ENDLOOP.
  REFRESH: tcdaut. CLEAR: tcdaut.
*  sort itcdaut.

  IF gf_details IS INITIAL.
    MODIFY iswaudc FROM wa_iswaudc
                   TRANSPORTING
*                      object
                      valueset
                      field
                      val_from
                      val_to
                    WHERE
                      swaudid <> space.
  ENDIF.

*  CONCATENATE sy-sysid sy-mandt INTO rfcdest.
*  MESSAGE s208(00) WITH 'Sorting started'.
  SORT: iswaudc, tcdaut, iuserauth, iusertcode, itcdaut.
*  MESSAGE s208(00) WITH 'Deleting duplicates'.
  DELETE ADJACENT DUPLICATES FROM iswaudc.
  DELETE ADJACENT DUPLICATES FROM tcdaut.
  DELETE ADJACENT DUPLICATES FROM iuserauth.
  DELETE ADJACENT DUPLICATES FROM iusertcode.
  DELETE ADJACENT DUPLICATES FROM itcdaut.
  huserauth[] = iuserauth[].
  suserauth[] = iuserauth[].
  REFRESH: iuserauth.
  CLEAR: iuserauth, huserauth, suserauth.

  LOOP AT iswaudc.
    IF iswaudc-tcode = '*'.
      PERFORM if_tcode_is_star.
    ELSE.
      PERFORM if_tcode_specified.
    ENDIF.
  ENDLOOP.
*--------------------------------------------------------------------
*User should have access to ALL objects withing crit auth
*check if user has auth for all objects and fill table userhas
  DATA : wa_userhas_obj LIKE LINE OF userhas_obj,
         lt_users TYPE TABLE OF userhas_obj_typ ,
         userhasflag TYPE flag.
  FIELD-SYMBOLS : <usr> TYPE userhas_obj_typ,
                  <iswaudc> TYPE /psyng/swaudc2.
  lt_users[] = userhas_obj[].
  SORT lt_users.
  DELETE ADJACENT DUPLICATES FROM lt_users COMPARING bname.
  LOOP AT lt_users ASSIGNING <usr> .
    LOOP AT iswaudc ASSIGNING <iswaudc>.
      AT NEW swaudid.
        userhasflag = 'X'.
      ENDAT.
      IF userhasflag = 'X'. "#EC SAST_CI_GEN_CHECK
*   if not, user doesn't have all objects of cri
        READ TABLE userhas_obj WITH TABLE KEY
            bname   = <usr>-bname
            swaudid = <iswaudc>-swaudid
            tcode   = <iswaudc>-tcode
            objct   = <iswaudc>-object
            TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          CLEAR userhasflag.
        ENDIF.
      ENDIF.
      AT END OF swaudid.
        IF userhasflag = 'X'. "#EC SAST_CI_GEN_CHECK
          wa_userhas-swaudid = <iswaudc>-swaudid.
          wa_userhas-bname = <usr>-bname.
          INSERT wa_userhas INTO TABLE userhas.
        ENDIF.
      ENDAT.
    ENDLOOP.
  ENDLOOP.
  MESSAGE s208(00) WITH 'M'.
  FREE :userhas_obj[],lt_users,userhasflag,wa_userhas_obj.

  WAIT UNTIL functioncall_1 = done.
  MESSAGE s208(00) WITH text-011.

  LOOP AT iswaudc.
    LOOP AT userhas WHERE swaudid = iswaudc-swaudid.
      READ TABLE sw_uinfo WITH KEY bname = userhas-bname.
      IF sy-subrc = 0.
        output-swaudid = iswaudc-swaudid.
        MOVE-CORRESPONDING sw_uinfo TO output.
*        output-sodcount = sw_uinfo-sodcount.
        APPEND output.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
  SORT output.
  DELETE ADJACENT DUPLICATES FROM output.
  IF i_details = 'X'.
    LOOP AT gt_outputdet INTO ls_outputdet.
      READ TABLE output
      INTO ls_output
      WITH KEY
        bname = ls_outputdet-bname
        swaudid = ls_outputdet-swaudid.
      IF sy-subrc = 0.
*    get the role to which this auth belongs
        IF ls_outputdet-child_agr IS INITIAL.
          SELECT SINGLE agr_name        "#EC CI_SEL_NESTED
            INTO ls_outputdet-child_agr
          FROM agr_1250 WHERE auth = ls_outputdet-auth.
          IF sy-subrc = 0.
           MODIFY gt_outputdet FROM ls_outputdet TRANSPORTING child_agr
            WHERE auth = ls_outputdet-auth.
          ENDIF.
        ENDIF.
        APPEND ls_outputdet TO outputdet.
      ELSE.
        DELETE gt_outputdet WHERE
          bname   = ls_outputdet-bname AND
          swaudid = ls_outputdet-swaudid.
      ENDIF.
    ENDLOOP.
  ENDIF.

ENDFUNCTION.
*&---------------------------------------------------------------------*
*&      Form  get_single_profiles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_single_profiles.
  CALL FUNCTION '/PSYNG/SW_GET_SINGLE_PROFS'
       EXPORTING
            profname = iust04-profile
       TABLES
            iust10c  = iust10c
            profinfo = profinfo.

ENDFORM.                    " get_single_profiles

*&---------------------------------------------------------------------*
*&      Form  start_child_get_user_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM start_child_get_user_name USING userid
                                     vrsio TYPE /psyng/sodvrsio.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  IF userid IS INITIAL.
    SELECT bname
           INTO wa_usr02-bname
           FROM usr02
           WHERE bname = userid.
      INSERT wa_usr02 INTO TABLE iusr02.
    ENDSELECT.

  ELSE.
    PERFORM get_sw_repo_conifg.
    SELECT bname gltgv gltgb ustyp uflag
           INTO CORRESPONDING FIELDS OF wa_usr02
           FROM usr02
           WHERE bname = userid AND
                 ustyp = 'A'.
      IF wa_usr02-gltgv IS INITIAL.  "valid from date
        wa_usr02-gltgv = '00010101'.
      ENDIF.
      IF wa_usr02-gltgb IS INITIAL.  "valid to date
        wa_usr02-gltgb = '99991231'.
      ENDIF.
      IF wa_usr02-gltgv <= sy-datum AND wa_usr02-gltgb >= sy-datum.
*SF CASE 1405
        l_uflagx = wa_usr02-uflag."unicode
        IF l_uflagx O yusloc OR "locked by admin
           l_uflagx O yugloc.   "locked by CUA admin
*      --User is locked by Local or Global Administrator
          IF dsp_mng_lock = 'Y'.
            INSERT wa_usr02 INTO TABLE iusr02.
          ENDIF.
        ELSEIF l_uflagx O yulock.
*      --User is locked by failed logins
          IF dsp_slf_lock = 'Y'.
            INSERT wa_usr02 INTO TABLE iusr02.
          ENDIF.
        ELSE.
*      --User is active
          INSERT wa_usr02 INTO TABLE iusr02.
        ENDIF.

*        CASE wa_usr02-uflag.
*          WHEN 0.   "user ID unlocked
*            INSERT wa_usr02 INTO TABLE iusr02.
*          WHEN 64.  "user ID locked by system manager
*            IF dsp_mng_lock = 'Y'.
*              INSERT wa_usr02 INTO TABLE iusr02.
*            ENDIF.
*          WHEN 128. "user ID locked due to incorrect logins
*            IF dsp_slf_lock = 'Y'.
*              INSERT wa_usr02 INTO TABLE iusr02.
*            ENDIF.
*        ENDCASE.

      ENDIF.
    ENDSELECT.

  ENDIF.
  SORT iusr02.

  LOOP AT iusr02.
    sw_uinfo-bname = iusr02-bname.
    APPEND sw_uinfo.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_USER_INFO'
*      STARTING NEW TASK 'SW_USER_INFO'
*      DESTINATION IN GROUP DEFAULT
*      PERFORMING get_userinfo_from_child ON END OF TASK
    EXPORTING
      vrsio          = vrsio
    TABLES
      sw_uinfo       = sw_uinfo
      iusgrpt        = iusgrpt
      swaudhdr       = swaudhdr
      kostl_resp     = kostl_resp.

ENDFORM.                    " start_child_get_user_name


*---------------------------------------------------------------------*
*       FORM get_userinfo_from_child                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_userinfo_from_child USING taskname.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_USER_INFO'
          TABLES
              sw_uinfo       = sw_uinfo
              iusgrpt        = iusgrpt
              swaudhdr       = swaudhdr
              kostl_resp     = kostl_resp.

  IF sy-subrc = 0.
    functioncall_1 = done.
  ENDIF.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  if_tcode_is_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM if_tcode_is_star.
  DATA : ls_outputdet TYPE /psyng/sw_ca_outputdet,
         wa_userhas_obj TYPE userhas_obj_typ.

  READ TABLE itcdaut WITH KEY swaudid = iswaudc-swaudid
                                tcode = iswaudc-tcode
                                BINARY SEARCH
                                TRANSPORTING NO FIELDS.
  tcdaut_idx =  sy-tabix.
  LOOP AT itcdaut FROM tcdaut_idx
                 WHERE swaudid = iswaudc-swaudid AND
                       tcode = iswaudc-tcode.
    tcdaut_idx =  sy-tabix.
    READ TABLE suserauth WITH KEY objct = itcdaut-objct
                             auth = itcdaut-auth
                             BINARY SEARCH
                             TRANSPORTING NO FIELDS.
    iuserauth_idx = sy-tabix.
    LOOP AT suserauth FROM iuserauth_idx
                      WHERE objct = itcdaut-objct AND
                             auth = itcdaut-auth.
      IF gf_details = 'X' AND iswaudc-object = itcdaut-objct.
*         document details in output table
        ls_outputdet-bname   = suserauth-bname.
        ls_outputdet-swaudid = iswaudc-swaudid.
        ls_outputdet-tcode   = itcdaut-tcode.
        ls_outputdet-objct   = itcdaut-objct.
        ls_outputdet-auth    = itcdaut-auth.
        ls_outputdet-field   = iswaudc-field.
        ls_outputdet-von     = iswaudc-val_from.
        ls_outputdet-bis     = iswaudc-val_to.
        APPEND ls_outputdet TO gt_outputdet.
      ENDIF.

*      READ TABLE userhas WITH TABLE KEY swaudid = iswaudc-swaudid
*                                  bname = iuserauth-bname.
*      CHECK sy-subrc <> 0.
*      iuserauth_idx = sy-tabix.
*      wa_userhas-swaudid = iswaudc-swaudid.
*      wa_userhas-bname = suserauth-bname.
*      INSERT wa_userhas INTO TABLE userhas.
      wa_userhas_obj-swaudid = iswaudc-swaudid.
      wa_userhas_obj-bname   = suserauth-bname.
      wa_userhas_obj-tcode   = iswaudc-tcode.
      wa_userhas_obj-objct   = itcdaut-objct.
      INSERT wa_userhas_obj INTO TABLE userhas_obj.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " if_tcode_is_star
*&---------------------------------------------------------------------*
*&      Form  if_tcode_specified
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM if_tcode_specified.
  DATA : ls_outputdet TYPE /psyng/sw_ca_outputdet,
         wa_userhas_obj TYPE userhas_obj_typ.

  READ TABLE itcdaut WITH KEY swaudid = iswaudc-swaudid
                             tcode = iswaudc-tcode
                             BINARY SEARCH
                             TRANSPORTING NO FIELDS.
  tcdaut_idx =  sy-tabix.
  LOOP AT itcdaut FROM tcdaut_idx
                 WHERE swaudid = iswaudc-swaudid AND
                         tcode = iswaudc-tcode.
    tcdaut_idx =  sy-tabix.
    READ TABLE iusertcode WITH KEY tcode = iswaudc-tcode
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
    iusertcode_idx = sy-tabix.
    LOOP AT iusertcode FROM iusertcode_idx
                       WHERE tcode = iswaudc-tcode.
      iusertcode_idx = sy-tabix.
      READ TABLE userhas WITH TABLE KEY swaudid = iswaudc-swaudid
                                          bname = iusertcode-bname.
      CHECK sy-subrc <> 0 OR gf_details = 'X'.
      READ TABLE huserauth WITH TABLE KEY objct = itcdaut-objct
                                           auth = itcdaut-auth
                                          bname = iusertcode-bname.
      CHECK sy-subrc = 0.
*      wa_userhas-swaudid = iswaudc-swaudid.
*      wa_userhas-bname = huserauth-bname.
*      INSERT wa_userhas INTO TABLE userhas.
      wa_userhas_obj-swaudid = iswaudc-swaudid.
      wa_userhas_obj-bname   = iusertcode-bname.
      wa_userhas_obj-tcode   = iswaudc-tcode.
      wa_userhas_obj-objct   = itcdaut-objct.
      INSERT wa_userhas_obj INTO TABLE userhas_obj.
      IF gf_details = 'X' AND iswaudc-object = itcdaut-objct.

*         document details in output table
        ls_outputdet-bname   = iusertcode-bname.
        ls_outputdet-swaudid = iswaudc-swaudid.
        ls_outputdet-tcode   = iusertcode-tcode.
        ls_outputdet-objct   = itcdaut-objct.
        ls_outputdet-auth    = itcdaut-auth.
        ls_outputdet-field   = iswaudc-field.
        ls_outputdet-von     = iswaudc-val_from.
        ls_outputdet-bis     = iswaudc-val_to.
        APPEND ls_outputdet TO gt_outputdet.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " if_tcode_specified

*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_sw_repo_conifg.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.
ENDFORM.                    " get_sw_repo_conifg

*---------------------------------------------------------------------*
*       FORM refresh_internal_tables                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM refresh_internal_tables.

  CLEAR:
        10sobjs,
        audcobjs,
        huserauth,
        iiust04,
        iswaudc,
        itcdaut,
        iuserauth,
        iusertcode,
        iusgrpt,
        iusr02,
        iusrefus1,
        iust04,
        iust10c,
        iust10s,
        iust12,
        profiles,
        profinfo,
        suserauth,
        sw_uinfo,
        swaudhdr,
        tcdaut,
        userauth,
        userhas,
        userprof,
        usertcode.


  REFRESH:
        gt_outputdet,
        gt_routputdet,
        10sobjs,
        audcobjs,
        huserauth,
        iiust04,
        iswaudc,
        itcdaut,
        iuserauth,
        iusertcode,
        iusgrpt,
        iusr02,
        iusrefus1,
        iust04,
        iust10c,
        iust10s,
        iust12,
        profiles,
        profinfo,
        suserauth,
        sw_uinfo,
        swaudhdr,
        tcdaut,
        userauth,
        userhas,
        userprof,
        usertcode.

ENDFORM.
