*----------------------------------------------------------------------*
* Include :  /PSYNG/LSW_SOD_OBJS7F01                                   *
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
*----------------------------------------------------------------------*
*  Change Date  Changed by  Change Tag  Transport                      *
*  17/02/2020   Gurpinder   C0016       P33K940473                     *
*----------------------------------------------------------------------*


*----------------------------------------------------------------------*
***INCLUDE /PSYNG/LSW_SOD_OBJS7F01 .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Form  get_critical_auth_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_critical_auth_data
 TABLES it_swaudid STRUCTURE /psyng/range_swaudid
        it_swaudc  STRUCTURE /psyng/swaudc2
        it_swaudhdr STRUCTURE /psyng/swaudhdr
  USING
                              i_enhance TYPE flag
                              i_local_ca TYPE flag
                              I_MATRIX_RFC type rfcdest.

  Data : lt_swaudc type /psyng/swaudc2.
  CLEAR gt_tcodes_enh.
  IF i_local_ca = 'X'.
*    SELECT * FROM /psyng/swaudhdr         "#EC CI_IMUD_NESTED
*              INTO TABLE gt_swaudhdr
*              WHERE swaudid IN it_swaudid
*              AND vrsio = g_vrsio.

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
    CALL FUNCTION '/PSYNG/SW_CR_GET_ALL_CRIAUTHS'
    destination I_MATRIX_RFC
     EXPORTING
       VRSIO          = g_vrsio
       if_details     = 'X'
      TABLES
        swaudhdr       = gt_swaudhdr
        swaudc2        = gt_swaudc. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    delete gt_swaudhdr where not swaudid  in it_swaudid.
    delete gt_swaudc   where not swaudid  in it_swaudid.
    SORT : gt_swaudhdr.
  ELSE.
*--The Critical Auth Definitions that we will use are passed to the FM
    gt_swaudc[] = it_swaudc[].
    gt_swaudhdr[] = it_swaudhdr[].
  ENDIF.
*-- IF no detail maintained for CA
  LOOP AT gt_swaudhdr.
    READ TABLE gt_swaudc into lt_swaudc
                       WITH KEY swaudid = gt_swaudhdr-swaudid
                                  tcode = gt_swaudhdr-tcode
                                  object = 'S_TCODE'
                                  field = 'TCD'.
    IF sy-subrc NE 0.
      MOVE-CORRESPONDING gt_swaudhdr TO lt_swaudc.
      lt_swaudc-object = 'S_TCODE'.
      lt_swaudc-field = 'TCD'.
      lt_swaudc-VAL_FROM = gt_swaudhdr-tcode.
      APPEND lt_swaudc to gt_swaudc .
    ENDIF.
  ENDLOOP.
  IF i_enhance = 'X'.
*-- In progress : Dynamic Enhancement of Critical Authorizations
*  Enhance Critical Authorizations
    FIELD-SYMBOLS : <swaudc2> TYPE /psyng/swaudc2.
    DATA : lt_tcodes  TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
           lt_tcodes_enh TYPE TABLE OF /psyng/sw_par_tcode_output
           WITH HEADER LINE,
           ls_swaudc TYPE /psyng/swaudc2.
    RANGES: lr_tcode FOR tstc-tcode.

    lr_tcode-sign = 'I'.
    LOOP AT gt_swaudc ASSIGNING <swaudc2>.
      IF <swaudc2>-tcode <> '*'.
        lt_tcodes-functionid = <swaudc2>-swaudid.
        lt_tcodes-vrsio      = g_vrsio.
        lt_tcodes-tcode      = <swaudc2>-tcode.
        APPEND lt_tcodes.
      ENDIF.
*-- S_TCODE object
      IF <swaudc2>-object = 'S_TCODE'.
        REFRESH lr_tcode.
        IF <swaudc2>-val_from CS '*' OR <swaudc2>-val_to CS '*'.
          lr_tcode-option = 'CP'.
        ELSEIF <swaudc2>-val_to IS INITIAL.
          lr_tcode-option = 'EQ'.
        ELSE.
          lr_tcode-option = 'BT'.
        ENDIF.

        lr_tcode-low  = <swaudc2>-val_from.
        lr_tcode-high = <swaudc2>-val_to.
        APPEND lr_tcode.

        SELECT tcode INTO lt_tcodes-tcode     "#EC CI_IMUD_NESTED
              FROM tstc
               WHERE tcode IN lr_tcode.

          READ TABLE lt_tcodes WITH KEY functionid = <swaudc2>-swaudid
                                        tcode      = lt_tcodes-tcode
                                  BINARY SEARCH TRANSPORTING NO FIELDS.
          CHECK sy-subrc <> 0.
          lt_tcodes-functionid = <swaudc2>-swaudid.
          lt_tcodes-vrsio      = g_vrsio.
          APPEND lt_tcodes.
        ENDSELECT.
      ENDIF.
    ENDLOOP.
    SORT lt_tcodes.
    DELETE ADJACENT DUPLICATES FROM lt_tcodes.
* Get list of called tcodes
****  CALL FUNCTION '/PSYNG/SW_029'
****       TABLES
****            functtran = lt_tcodes
****            tcodes    = lt_tcodes_enh.
  CALL FUNCTION '/PSYNG/SW_ENH_GET'
       EXPORTING
            i_vrsio      = g_vrsio
       TABLES
            it_functtran = lt_tcodes
            et_tcodes    = lt_tcodes_enh.

    gt_tcodes_enh[] = lt_tcodes_enh[].
* Combine Critical Auths with enhanced tcodes.
    LOOP AT lt_tcodes.
      LOOP AT lt_tcodes_enh WHERE called_tcode = lt_tcodes-tcode.
        READ TABLE gt_swaudhdr WITH KEY swaudid = lt_tcodes-functionid
                                       tcode   = lt_tcodes-tcode.
        IF sy-subrc = 0.
          gt_swaudhdr-tcode = lt_tcodes_enh-calling_tcode.
          APPEND gt_swaudhdr.
          LOOP AT gt_swaudc INTO ls_swaudc
          WHERE swaudid = lt_tcodes-functionid AND
                tcode   = lt_tcodes-tcode.

            ls_swaudc-tcode =     lt_tcodes_enh-calling_tcode.
            APPEND  ls_swaudc TO gt_swaudc.
          ENDLOOP.
        ENDIF.
      ENDLOOP.
    ENDLOOP.

  ENDIF.
  SORT : gt_swaudc.

ENDFORM.                    " get_critical_auth_data
*&---------------------------------------------------------------------*
*&      Form  get_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_BNAME  text
*----------------------------------------------------------------------*
FORM get_users TABLES   it_bname STRUCTURE /psyng/range_bname
                        it_class STRUCTURE /psyng/range_class
               USING    i_allug  TYPE flag.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.
  FIELD-SYMBOLS : <fs_usr02> TYPE usr02.

  DATA : lt_usr02 TYPE TABLE OF usr02,
         ls_uinfo TYPE /psyng/sw_uinfo,
         ls_usr02 TYPE usr02,
         gf_missing_auth_ugroup TYPE flag,
         lt_user_range_all TYPE TABLE OF /psyng/range_bname,
         lt_user_range_part TYPE TABLE OF /psyng/range_bname.
  REFRESH : gt_usr02[].
  IF gf_validuser IS INITIAL.
*    SELECT bname gltgv gltgb ustyp uflag
*           INTO CORRESPONDING FIELDS OF TABLE gt_usr02
*           FROM usr02
*           WHERE bname IN it_bname AND
*                 class IN it_class .
    lt_user_range_all[] = it_bname[].
    FREE : lt_usr02.
    WHILE NOT lt_user_range_all[] IS INITIAL.
      APPEND LINES OF lt_user_range_all FROM 1 TO 2500
      TO lt_user_range_part.
      DELETE lt_user_range_all FROM 1 TO 2500.
      SELECT bname gltgv gltgb ustyp uflag     "#EC CI_IMUD_NESTED
             INTO CORRESPONDING FIELDS OF TABLE gt_usr02
             FROM usr02
             WHERE bname IN lt_user_range_part AND
                   class IN it_class .
      FREE     lt_user_range_part.
    ENDWHILE.
    FREE     lt_user_range_all.

  ELSE.
    PERFORM get_sw_repo_config.
    lt_user_range_all[] = it_bname[].
    FREE : lt_usr02.
    WHILE NOT lt_user_range_all[] IS INITIAL.
      APPEND LINES OF lt_user_range_all FROM 1 TO 2500
      TO lt_user_range_part.
      DELETE lt_user_range_all FROM 1 TO 2500.
      SELECT bname class gltgv gltgb ustyp uflag
             APPENDING CORRESPONDING FIELDS OF TABLE lt_usr02
             FROM usr02
             WHERE bname IN lt_user_range_part AND
                   class IN it_class AND
                   ustyp = 'A'.
      FREE     lt_user_range_part.
    ENDWHILE.
    FREE     lt_user_range_all.
    LOOP AT lt_usr02 ASSIGNING <fs_usr02>.
      IF <fs_usr02>-gltgv IS INITIAL.  "valid from date
        <fs_usr02>-gltgv = '00010101'.
      ENDIF.
      IF <fs_usr02>-gltgb IS INITIAL.  "valid to date
        <fs_usr02>-gltgb = '99991231'.
      ENDIF.
      IF <fs_usr02>-gltgv <= sy-datum AND <fs_usr02>-gltgb >= sy-datum.
*--SF CASE 1405
        l_uflagx = <fs_usr02>-uflag."unicode
        IF l_uflagx O yusloc OR "locked by admin
           l_uflagx O yugloc.   "locked by CUA admin
*      --User is locked by Local or Global Administrator
          IF dsp_mng_lock = 'Y'.
            INSERT <fs_usr02> INTO TABLE gt_usr02."#EC SAST_CI_GEN_CHECK
*HBHALLA: Only using field symbol of usr02, so no fix needed.
          ENDIF.
        ELSEIF l_uflagx O yulock.
*      --User is locked by failed logins
          IF dsp_slf_lock = 'Y'.
            INSERT <fs_usr02> INTO TABLE gt_usr02."#EC SAST_CI_GEN_CHECK
*HBHALLA: Only using field symbol of usr02, so no fix needed.
          ENDIF.
        ELSE.
*      --User is active
          INSERT <fs_usr02> INTO TABLE gt_usr02."#EC SAST_CI_GEN_CHECK
*HBHALLA: Only using field symbol of usr02, so no fix needed.
        ENDIF.
*        CASE <usr02>-uflag.
*          WHEN 0.   "user ID unlocked
*            INSERT <usr02> INTO TABLE gt_usr02.
*          WHEN 64.  "user ID locked by system manager
*            IF dsp_mng_lock = 'Y'.
*              INSERT <usr02> INTO TABLE gt_usr02.
*            ENDIF.
*          WHEN 128. "user ID locked due to incorrect logins
*            IF dsp_slf_lock = 'Y'.
*              INSERT <usr02> INTO TABLE gt_usr02.
*            ENDIF.
*        ENDCASE.
      ENDIF.
    ENDLOOP.
  ENDIF.
  SORT gt_usr02.
*DHO 20101202
*  LOOP AT lt_usr02 ASSIGNING <usr02>.
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*    ID 'CLASS' FIELD <usr02>-class.
*    IF sy-subrc <> 0 AND NOT ( <usr02>-class IS INITIAL ) .
*      gf_missing_auth_ugroup = 'X'.
*      DELETE lt_usr02 WHERE bname = <usr02>-bname.
*    ENDIF.
*  ENDLOOP.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s398(00) WITH 'Missing some user group authorizations'(012).
    COMMIT WORK.
  ENDIF.

  DESCRIBE TABLE gt_usr02 LINES g_nr_users_analyzed.
  LOOP AT gt_usr02 ASSIGNING <fs_usr02>.
    ls_uinfo-bname = <fs_usr02>-bname.
    APPEND ls_uinfo TO gt_uinfo.
  ENDLOOP.
  IF i_allug IS INITIAL.
    IF NOT gt_usr02[] IS INITIAL.
*DHO 20101202
      DATA : lf_reject TYPE flag.
      CALL FUNCTION '/PSYNG/SW_USER_INFO'
        EXPORTING
          vrsio          = g_vrsio
          i_mr_company   = 'X'
          i_name_only    = 'X'
        TABLES
          sw_uinfo       = gt_uinfo
          iusgrpt        = gt_usgrpt
*      swaudhdr       = gt_swaudhdr
          kostl_resp     = gt_kostl_resp.
      IF sy-subrc = 0.
        functioncall_1 = done.
      ENDIF.
*    ENDIF.
*DHO 20101202

      LOOP AT gt_uinfo .
        CLEAR lf_reject.
        PERFORM check_rpoug_auth USING gt_uinfo g_vrsio
                               CHANGING lf_reject.
        IF lf_reject = 'X'.
          DELETE gt_uinfo.
          gf_missing_auth_ugroup = 'X'.
        ENDIF.
      ENDLOOP.
    ENDIF.

*reference users are handled automatically because we use
* FM SUSR_USER_AUTH_FOR_OBJ_GET
*--get reference users
    IF NOT gt_usr02[] IS INITIAL.
      SELECT bname refuser FROM usrefus
        INTO CORRESPONDING FIELDS OF TABLE gt_usrefus
        FOR ALL ENTRIES IN gt_usr02 WHERE bname = gt_usr02-bname AND
        refuser NE space. "#EC SAST_CI_GEN_CHECK
*-- add reference users to the list of users to get profiles for
      LOOP AT gt_usrefus.
        ls_usr02-bname = gt_usrefus-refuser.
        ls_usr02-class = 'REFUSER'.
        INSERT ls_usr02 INTO TABLE gt_usr02.
      ENDLOOP.
    ENDIF.
  ENDIF.
ENDFORM.                    " get_users

*---------------------------------------------------------------------*
*       FORM get_userinfo_from_child                                  *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*FORM get_userinfo_from_child USING taskname.
*  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_USER_INFO'
*          TABLES
*              sw_uinfo       = gt_uinfo
*              iusgrpt        = gt_usgrpt
**              swaudhdr       = gt_swaudhdr
*              kostl_resp     = gt_kostl_resp.
*
*  IF sy-subrc = 0.
*    functioncall_1 = done.
*  ENDIF.
*ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_sw_repo_config.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.
ENDFORM.                    " get_sw_repo_conifg
*&---------------------------------------------------------------------*
*&      Form  get_system_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_system_auths.
  FIELD-SYMBOLS : <swaudhdr> TYPE /psyng/swaudhdr,
                  <swaudc>   TYPE /psyng/swaudc2,
                  <auth>     TYPE usref.
  DATA : l_idx LIKE sy-tabix VALUE '1',
         l_subrc LIKE sy-subrc,
         l_object TYPE xuobject,
         lt_values TYPE TABLE OF usref,
         ls_value TYPE usref,
         lt_ust12 TYPE TABLE OF ust12,
         ls_swaudid_auth TYPE typ_swaudid_auth,
         ls_obj TYPE typ_obj_field,
*         ls_tcode_auth type typ_tcode_auth,
         l_nr_auth TYPE i,
         lf_firstfield TYPE flag,
         lt_auths_combined TYPE TABLE OF usref, "auths for all objects
                                                "combined
         lt_auths_single   TYPE TABLE OF usref. "auths for 1 single
  "object
  MESSAGE s113(/psyng/sw) WITH
  'Loading system auths'(004).
  COMMIT WORK.

*buffer only relevant data for S_TCODE object to avoid selecting from
*ust12 multiple times.
  LOOP AT gt_swaudc ASSIGNING <swaudc> WHERE
    object = 'S_TCODE' AND field = 'TCD'.
    ls_value-object = <swaudc>-object.
    ls_value-field  = <swaudc>-field.
    ls_value-von    = <swaudc>-val_from.
    ls_value-bis   = <swaudc>-val_to.
    APPEND ls_value TO lt_values.
  ENDLOOP.
  IF NOT lt_values IS INITIAL.
    SORT lt_values.
    DELETE ADJACENT DUPLICATES FROM lt_values.
    CALL FUNCTION '/PSYNG/SW_048'
         EXPORTING
              object = 'S_TCODE'
         TABLES
              values = lt_values
              auths  = lt_auths_single.
    SORT gt_ust12 BY objct field.
    ls_obj-field  = 'TCD'.
    ls_obj-object = 'S_TCODE'.
    APPEND ls_obj TO gt_objs.
    FREE : lt_values, lt_auths_single, lt_ust12.
  ENDIF.






  SORT gt_swaudc BY swaudid tcode valueset object field.


  LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
    REFRESH : lt_values[], lt_auths_combined[].
    LOOP AT gt_swaudc ASSIGNING <swaudc>
          FROM l_idx WHERE swaudid = <swaudhdr>-swaudid AND
                           tcode   = <swaudhdr>-tcode.
      AT NEW swaudid.
        l_object = <swaudc>-object.
        REFRESH : lt_values[].
        lf_firstfield = 'X'.
      ENDAT.
      AT NEW object.
        l_object = <swaudc>-object.
        REFRESH : lt_values[].
      ENDAT.
      AT NEW valueset.
        REFRESH : lt_values[].
        lf_firstfield = 'X'.
      ENDAT.
      AT NEW field.
        REFRESH : lt_values[].
      ENDAT.
      ls_value-object = <swaudc>-object.
      ls_value-field  = <swaudc>-field.
      ls_value-von    = <swaudc>-val_from.
      ls_value-bis   = <swaudc>-val_to.
      APPEND ls_value TO lt_values.
      AT END OF field.
* All lines for which the field is the same reports will assume
* an OR logic.
* For the S_TCODE object an SAP Function module will be used
*  It used less memory but is a little slower
*
        CLEAR l_subrc.
        CALL FUNCTION '/PSYNG/SW_048'
             EXPORTING
                  object = l_object
             TABLES
                  values = lt_values
                  auths  = lt_auths_single.
        l_subrc = sy-subrc.
        IF l_subrc <> 0 .
*             object doesnt exist
          REFRESH : lt_auths_single[].
        ELSE.
          IF lf_firstfield = 'X'.
            CLEAR lf_firstfield.
            lt_auths_combined[] = lt_auths_single[].
          ELSE.
*--         only auths that also matched for previous object(s)
*           are valid
            LOOP AT lt_auths_single ASSIGNING <auth>.
              READ TABLE lt_auths_combined WITH KEY auth = <auth>-auth
              TRANSPORTING NO FIELDS BINARY SEARCH.
              IF sy-subrc <> 0.
                DELETE lt_auths_single WHERE auth =  <auth>-auth.
              ENDIF.
            ENDLOOP.
            lt_auths_combined[] = lt_auths_single[].
          ENDIF.
        ENDIF.
      ENDAT.
      AT END OF valueset.
*-- lt_auths_combined has all auths that match the current critical auth
        LOOP AT lt_auths_combined ASSIGNING <auth>.
          ls_swaudid_auth-swaudid = <swaudhdr>-swaudid.
          ls_swaudid_auth-tcode   = <swaudhdr>-tcode.
          ls_swaudid_auth-auth    = <auth>-auth.
          ls_swaudid_auth-object  = <auth>-object.
          INSERT ls_swaudid_auth INTO TABLE gt_swaudid_auth.
        ENDLOOP.
        REFRESH: lt_auths_combined[].
      ENDAT.
    ENDLOOP.
  ENDLOOP.
  FREE : gt_ust12[].
  MESSAGE s113(/psyng/sw) WITH
  'Finished loading system auths'(005).
  COMMIT WORK.

ENDFORM.                    " get_system_auths
*&---------------------------------------------------------------------*
*&      Form  get_user_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM get_user_auths TABLES it_users STRUCTURE usr02.
*  FIELD-SYMBOLS : <swaudhdr> TYPE /psyng/swaudhdr,
*                  <swaudc>   TYPE /psyng/swaudc2,
*                  <usr>      TYPE usr02,
*                  <obj>      TYPE typ_audcobjs,
*                  <val>      TYPE usvalues,
*                  <tcode>    TYPE tcode.
*  DATA : l_idx LIKE sy-tabix VALUE '1',
*         lt_objs  TYPE STANDARD TABLE OF typ_audcobjs,
*         lt_tcodes TYPE TABLE OF tcode,
*         ls_tcode TYPE tcode,
*         ls_obj   TYPE typ_audcobjs,
*         lt_values TYPE TABLE OF usvalues,
*         lt_values_tcode TYPE TABLE OF usvalues,
*         ls_user_auth TYPE /psyng/userauth,
*         ls_compare TYPE /psyng/auth_compare,
*         lt_compare TYPE TABLE OF /psyng/auth_compare,
*         ls_user_tcode LIKE LINE OF gt_usertcode,
*         lt_utcode_auth TYPE SORTED TABLE OF user_tcode_typ
*         WITH UNIQUE KEY bname von bis,
*         ls_utcode_auth TYPE user_tcode_typ.
**--move systemauths to hashed table with proper key
*  DATA : lt_systemauths TYPE HASHED TABLE OF typ_swaudid_auth
*         WITH UNIQUE KEY  object auth,
*        lt_systemauths_standard TYPE STANDARD TABLE OF typ_swaudid_auth,
*        lt_unique_user_1  TYPE TABLE OF usr02,
*        lt_unique_user_2  TYPE TABLE OF usr02.
*
*
*  MESSAGE s113(/psyng/sw) WITH
*  'Start loading user auths'(006).
*  COMMIT WORK.
*
*  lt_systemauths_standard[] = gt_swaudid_auth[].
*  SORT lt_systemauths_standard BY object auth.
*  DELETE ADJACENT DUPLICATES FROM lt_systemauths_standard
*  COMPARING  object auth.
*  lt_systemauths[] = lt_systemauths_standard[].
*  FREE : lt_systemauths_standard[].
*
*
**--get unique objects and tcodes
*  LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
*    LOOP AT gt_swaudc ASSIGNING <swaudc>
*         FROM l_idx WHERE swaudid = <swaudhdr>-swaudid.
*      ls_obj-objct = <swaudc>-object.
*      INSERT ls_obj INTO TABLE lt_objs.
*    ENDLOOP.
**  also tcode
*    ls_obj = 'S_TCODE'.
*    INSERT ls_obj INTO TABLE lt_objs.
*    l_idx = sy-tabix.
*    IF <swaudhdr>-tcode <> '*'.
*      ls_tcode = <swaudhdr>-tcode.
*      APPEND ls_tcode TO lt_tcodes.
*    ENDIF.
*  ENDLOOP.
*  SORT lt_objs.
*  DELETE ADJACENT DUPLICATES FROM lt_objs.
*  SORT lt_tcodes.
*  DELETE ADJACENT DUPLICATES FROM lt_tcodes.
*
*
*
*  lt_unique_user_1[] = it_users[].
*
*  WHILE NOT lt_unique_user_1 IS INITIAL.
*    FREE : lt_unique_user_2.
*    APPEND LINES OF lt_unique_user_1 FROM 1 TO 2000
*    TO lt_unique_user_2 .
*    DELETE lt_unique_user_1 FROM 1 TO 2000.
**--release userbuffer memory
*    CALL FUNCTION '/PSYNG/SW_057'.
*
**-get userbuffer settings
*    CALL FUNCTION '/PSYNG/SW_055'
*         TABLES
*              it_users = lt_unique_user_2.
*    LOOP AT lt_unique_user_2 ASSIGNING <usr>.
*      FREE : lt_compare[].
**-- get auths for user
*      FREE : lt_values[].
*      CALL FUNCTION '/PSYNG/SW_049'
*           EXPORTING
*                user_name  = <usr>-bname
*           TABLES
*                values     = lt_values
*                it_objects = lt_objs.
*
*      IF sy-subrc <> 0.
**       MESSAGE ID SY-MSGID TYPE SY-MSGTY NUMBER SY-MSGNO
**               WITH SY-MSGV1 SY-MSGV2 SY-MSGV3 SY-MSGV4.
*      ELSE.
*        lt_values_tcode[] = lt_values[].
*        DELETE lt_values_tcode WHERE objct <> 'S_TCODE'.
*        DELETE lt_values_tcode WHERE field <> 'TCD'.
*        SORT lt_values_tcode BY von bis.
*      DELETE ADJACENT DUPLICATES FROM lt_values_tcode COMPARING von bis.
*        LOOP AT lt_values_tcode ASSIGNING <val> .
**--     collect tcodes for user
*          ls_utcode_auth-bname = <usr>-bname.
*          ls_utcode_auth-von   = <val>-von.
*          ls_utcode_auth-bis   = <val>-bis.
*          INSERT ls_utcode_auth INTO TABLE lt_utcode_auth.
*        ENDLOOP.
*        FREE : lt_values_tcode.
*
*
*      ENDIF.
*      LOOP AT lt_values ASSIGNING <val>.
**-- only add what is in any of the critical auths
*        READ TABLE lt_systemauths WITH TABLE KEY object = <val>-objct
*                                            auth   = <val>-auth
*                                 TRANSPORTING NO FIELDS.
*        IF sy-subrc = 0.
*          ls_user_auth-objct  = <val>-objct.
*          ls_user_auth-auth   = <val>-auth.
*          ls_user_auth-field  = <val>-field.
*          ls_user_auth-von    = <val>-von.
*          ls_user_auth-bis    = <val>-bis.
*          ls_user_auth-bname  =  <usr>-bname.
*          INSERT ls_user_auth INTO TABLE gt_user_auth.
*        ENDIF.
*      ENDLOOP.
*    ENDLOOP.
*    FREE : lt_values.
*
**--find tcodes that users have
*    FIELD-SYMBOLS : <utc> LIKE ls_utcode_auth,
*                    <comp> TYPE /psyng/auth_compare.
*    DELETE ADJACENT DUPLICATES FROM lt_utcode_auth.
*    LOOP AT lt_utcode_auth ASSIGNING <utc>.
*      IF <utc>-bis IS INITIAL AND
*         <utc>-von NS '*'.
*        READ TABLE lt_tcodes WITH KEY table_line = <utc>-von
*        BINARY SEARCH TRANSPORTING NO FIELDS.
*        IF sy-subrc = 0.
*          ls_user_tcode-bname = <utc>-bname.
*          ls_user_tcode-tcode = <utc>-von.
*          APPEND ls_user_tcode TO gt_usertcode.
*        ENDIF.
*      ELSE.
*        LOOP AT lt_tcodes ASSIGNING <tcode>.
**               auth contains range or pattern, will be analyzed with
**               compare fm
*          ls_compare-auth_from  = <utc>-von.
*          ls_compare-auth_to    = <utc>-bis.
*          ls_compare-sod_from   = <tcode>.
*          APPEND ls_compare TO lt_compare  .
*        ENDLOOP.
*        SORT lt_compare.
*        DELETE ADJACENT DUPLICATES FROM lt_compare.
*        CALL FUNCTION '/PSYNG/SW_021'
*             TABLES
*                  it_compare = lt_compare.
*        SORT lt_compare BY match.
*        DELETE lt_compare WHERE match <> 'X'.
*        LOOP AT lt_compare ASSIGNING <comp>
*          WHERE match = 'X'.
*          ls_user_tcode-bname = <utc>-bname.
*          ls_user_tcode-tcode = <comp>-sod_from.
*          APPEND ls_user_tcode TO gt_usertcode.
*          DELETE lt_compare WHERE sod_from = ls_user_tcode-tcode.
*        ENDLOOP.
*        REFRESH : lt_compare[].
*      ENDIF.
*      FREE : lt_compare[].
*      FREE : lt_values[].
*
*    ENDLOOP.
*  ENDWHILE.
*  FREE :  lt_systemauths[].
*ENDFORM.                    " get_user_auths
*&---------------------------------------------------------------------*
*&      Form  COMPARE_USER_AUTHS_WITH_SYSTEM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM compare_user_auths_with_system.
*  MESSAGE s113(/psyng/sw) WITH
*  text-002.
*  COMMIT WORK.
*
*  FIELD-SYMBOLS : <swaudid_auth> LIKE LINE OF gt_swaudid_auth,
*                  <user_auth> LIKE LINE OF gt_user_auth.
*  DATA : ls_swaudc LIKE LINE OF gt_swaudc,
*         l_nrdel TYPE i,
*         l_cnrdel TYPE string.
*  STATICS : lt_swaudid_auth TYPE TABLE OF typ_swaudid_auth,
*            lt_swaudid_auth2 TYPE TABLE OF typ_swaudid_auth,
*            lt_swaudc TYPE TABLE OF /psyng/swaudc2.
*  DATA : BEGIN OF ls_auth_role,
*            auth TYPE xuauth,
*            agr_name TYPE agr_name,
*         END OF ls_auth_role,
*         lt_auths TYPE TABLE OF xuauth WITH HEADER LINE.
*  DATA : lt_auth_role LIKE SORTED TABLE OF ls_auth_role
*  WITH NON-UNIQUE KEY auth
*  WITH HEADER LINE.
**--remove auths from gt_swaudid_auth that no users have
*  MESSAGE s113(/psyng/sw) WITH
*  'Remove unused auths'.
*  COMMIT WORK.
**-- backupglobal table (include auths not used for
**  the users we currently are analyzing
*
*  IF lt_swaudid_auth[] IS INITIAL.
**--Only copy the table the first time this form is called
*    lt_swaudid_auth[] = gt_swaudid_auth[].
*    lt_swaudid_auth2[] = gt_swaudid_auth[].
*    SORT lt_swaudid_auth2 BY object auth.
*    DELETE ADJACENT DUPLICATES FROM lt_swaudid_auth2
*    COMPARING object auth.
**--Backup swaudc details
*    lt_swaudc[] = gt_swaudc[].
*  ENDIF..
*  LOOP AT lt_swaudid_auth2 ASSIGNING <swaudid_auth>.
*    READ TABLE gt_user_auth WITH KEY objct  = <swaudid_auth>-object
*                                     auth   = <swaudid_auth>-auth
*                                     TRANSPORTING NO FIELDS
*
*                                     BINARY SEARCH.
*    IF sy-subrc <> 0.
*      DELETE  gt_swaudid_auth WHERE auth   = <swaudid_auth>-auth
*                                AND object  = <swaudid_auth>-object .
*      ADD 1 TO l_nrdel.
*    ENDIF.
*  ENDLOOP.
*  l_cnrdel = l_nrdel.
*  MESSAGE s113(/psyng/sw) WITH
*  'Finished removing unused auths' l_cnrdel .
*  COMMIT WORK.
*  READ TABLE gt_user_auth WITH KEY simu = 'X' TRANSPORTING NO FIELDS.
*  IF sy-subrc = 0.
*    gf_er_or_simu = 'X'.
*  ELSE.
*    READ TABLE gt_user_auth WITH KEY er = 'X' TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      gf_er_or_simu = 'X'.
*    ENDIF.
*  ENDIF.
*
*  IF gf_details IS INITIAL AND gf_er_or_simu IS INITIAL.
*    MODIFY gt_swaudc FROM ls_swaudc
*                   TRANSPORTING
*                      valueset
*                      field
*                      val_from
*                      val_to
*                    WHERE
*                      swaudid <> space.
*    SORT gt_swaudc.
*    DELETE ADJACENT DUPLICATES FROM gt_swaudc.
*  ENDIF.
*
*
*  DATA : l_swaudid_count TYPE i,
*         l_swaudid_index TYPE i,
*         l_swaudid_index_str TYPE string,
*         l_pct TYPE f,
*         l_pct_i TYPE i,
*         l_pct_str TYPE string,
*         l_prev_pct_str TYPE string,
*         l_mod TYPE i,
*         l_rescount TYPE i,
*         l_rescount_str TYPE string,
*         l_progress1 TYPE string,
*         l_progress2 TYPE string,
*         l_progress3 TYPE string.
*  DESCRIBE TABLE gt_swaudc LINES l_swaudid_count.
*  l_rescount_str = l_swaudid_count.
*
*  MESSAGE s398(00) WITH
*  'Analyzing ' l_rescount_str  ' Crit. Auth Details'.
*  COMMIT WORK.
*
*  SORT gt_usertcode BY tcode.
*
*  LOOP AT gt_swaudc ASSIGNING <g_swaudc>.
**--START : Display progress
*    ADD 1 TO l_swaudid_index.
*    l_pct = ( l_swaudid_index /  l_swaudid_count ) * 100.
*    l_mod =  l_pct MOD 10.
*    IF l_mod = 0.
*      l_pct_i = l_pct.
*      l_pct_str = l_pct_i.
*      IF l_prev_pct_str <> l_pct_str.
*        DESCRIBE TABLE gt_outputdet LINES l_rescount.
*        l_swaudid_index_str = l_swaudid_index.
*        l_rescount_str = l_rescount.
*        CONCATENATE
*          l_pct_str '% done - '
*        INTO l_progress1 SEPARATED BY space.
*        CONCATENATE
*              'Analyzed : ' l_swaudid_index_str 'Cri.Auths'
*        INTO l_progress2 SEPARATED BY space.
*        IF gf_details = 'X'.
*          CONCATENATE
*                'results : ' l_rescount_str
*          INTO l_progress3 SEPARATED BY space.
*        ENDIF.
*        MESSAGE s398(00) WITH l_progress1 l_progress2 l_progress3.
*        COMMIT WORK.
*      ENDIF.
*      l_prev_pct_str = l_pct_str.
*    ENDIF.
**--END : Display progress
*
*    READ TABLE gt_swaudid_auth WITH KEY
*    swaudid = <g_swaudc>-swaudid
*    object  = <g_swaudc>-object
*    tcode = <g_swaudc>-tcode.
**    TRANSPORTING NO FIELDS.
*    CHECK sy-subrc = 0.
*    IF <g_swaudc>-tcode = '*'.
*      PERFORM if_tcode_is_star.
*    ELSE.
*      PERFORM if_tcode_specified.
*    ENDIF.
*  ENDLOOP.
*
*  SORT gt_outputdet.
*  DELETE ADJACENT DUPLICATES FROM gt_outputdet.
*
**--------------------------------------------------------------------
**User should have access to ALL objects withing crit auth
**check if user has auth for all objects and fill table userhas
*  DATA : wa_userhas_obj LIKE LINE OF gt_userhas_obj,
*         wa_userhas LIKE LINE OF gt_userhas,
*         lt_users TYPE TABLE OF userhas_obj_typ ,
*         userhasflag TYPE flag,
*         ls_output LIKE LINE OF gt_output,
*         ls_outputdet LIKE LINE OF gt_outputdet,
*         lt_outputdet LIKE TABLE OF ls_outputdet,
*         lf_simu TYPE flag,
*         lf_er TYPE flag.
*  FIELD-SYMBOLS : <usr> TYPE userhas_obj_typ,
*                  <iswaudc> TYPE /psyng/swaudc2,
*                  <userhas> LIKE LINE OF gt_userhas,
*                  <userhas_obj> LIKE LINE OF gt_userhas_obj,
*                  <uinfo> LIKE LINE OF gt_uinfo.
*  lt_users[] = gt_userhas_obj[].
*  SORT lt_users.
*  DELETE ADJACENT DUPLICATES FROM lt_users COMPARING bname.
*  LOOP AT lt_users ASSIGNING <usr> .
**Check if any ER or SIMU roles are used
*    CLEAR : lf_er, lf_simu.
*    READ TABLE gt_outputdet WITH KEY bname = <usr>-bname
*                                     er = 'X'
*    TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      lf_er = 'X'.
*    ENDIF.
*    READ TABLE gt_outputdet WITH KEY bname = <usr>-bname
*                                     simu = 'X'
*    TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      lf_simu = 'X'.
*    ENDIF.
*
*    LOOP AT gt_swaudc ASSIGNING <iswaudc>.
*      AT NEW swaudid.
*        userhasflag = 'X'.
*      ENDAT.
*      IF userhasflag = 'X'.
**   if not, user doesn't have all objects of cri
*        READ TABLE gt_userhas_obj WITH TABLE KEY
*            bname   = <usr>-bname
*            swaudid = <iswaudc>-swaudid
*            tcode   = <iswaudc>-tcode
*            objct   = <iswaudc>-object
*            ASSIGNING <userhas_obj>.
**            TRANSPORTING NO FIELDS.
*        IF sy-subrc <> 0.
*          CLEAR userhasflag.
*        ENDIF.
*      ENDIF.
*      AT END OF swaudid.
*        IF userhasflag = 'X'.
*          wa_userhas-swaudid = <iswaudc>-swaudid.
*          wa_userhas-bname = <usr>-bname.
*          wa_userhas-simu = lf_simu.
*          wa_userhas-er   = lf_er.
*          INSERT wa_userhas INTO TABLE gt_userhas.
*        ENDIF.
*      ENDAT.
*    ENDLOOP.
*  ENDLOOP.
*  MESSAGE s208(00) WITH text-003.
*  COMMIT WORK.
*  FREE :gt_userhas_obj[],lt_users,userhasflag,wa_userhas_obj.
*
*  WAIT UNTIL functioncall_1 = done.
*  MESSAGE s208(00) WITH text-011.
*  COMMIT WORK.
*  LOOP AT gt_swaudc ASSIGNING <g_swaudc>.
*    LOOP AT gt_userhas ASSIGNING <userhas>
*    WHERE swaudid = <g_swaudc>-swaudid.
*      READ TABLE gt_uinfo ASSIGNING <uinfo>
*      WITH KEY bname = <userhas>-bname.
*      IF sy-subrc = 0.
*        ls_output-swaudid = <g_swaudc>-swaudid.
*        ls_output-persa  = <uinfo>-persa .
*        ls_output-pernr  = <uinfo>-pernr .
*        ls_output-kostl  = <uinfo>-kostl .
*        ls_output-class  = <uinfo>-class .
*        ls_output-bname = <uinfo>-bname .
*        ls_output-name_text = <uinfo>-name_text .
*        ls_output-uflag  = <uinfo>-uflag .
*        ls_output-trdat = <uinfo>-trdat .
*        ls_output-sodcount = <uinfo>-sodcount .
*        IF lf_er = 'X'.
*        READ TABLE gt_outputdet WITH KEY
*          bname   = ls_output-bname
*          swaudid = ls_output-swaudid
*          er      = 'X'
*          TRANSPORTING NO FIELDS.
*        IF sy-subrc = 0.
*          ls_output-er = 'X'.
*        ELSE.
*          CLEAR ls_output-er .
*        ENDIF.
*      ENDIF.
*      IF lf_simu = 'X'.
*        READ TABLE gt_outputdet WITH KEY
*          bname   = ls_output-bname
*          swaudid = ls_output-swaudid
*          simu    = 'X'
*          TRANSPORTING NO FIELDS.
*        IF sy-subrc = 0.
*          ls_output-simu = 'X'.
*        ELSE.
*          CLEAR ls_output-simu .
*        ENDIF.
*      ENDIF.
*
*      INSERT ls_output INTO TABLE gt_output.
*    ENDIF.
*  ENDLOOP.
*ENDLOOP.
*
**--DHORIONS 20101210 - Optimize performance, only select once per auth
*IF gf_details = 'X'.
*  LOOP AT gt_outputdet INTO ls_outputdet.
*    lt_auths = ls_outputdet-auth.
*    COLLECT lt_auths.
*  ENDLOOP.
*  CHECK NOT  lt_auths[] IS INITIAL.
*  SELECT DISTINCT u~auth a~agr_name         "#EC CI_IMUD_NESTED
*  INTO  CORRESPONDING FIELDS OF TABLE lt_auth_role
*  FROM
*  ust10s AS u INNER JOIN agr_1016 AS a ON
*  u~profn = a~profile
*  FOR ALL ENTRIES IN lt_auths
*  WHERE u~auth = lt_auths-table_line.
*ENDIF.
*
*
**--DHORIONS 20101201 - Moved this code outside of this form
**  SORT gt_output.
*DELETE ADJACENT DUPLICATES FROM gt_output.
*IF gf_details = 'X'.
*  LOOP AT gt_outputdet INTO ls_outputdet.
*    READ TABLE gt_output
*    INTO ls_output
*    WITH TABLE KEY
*      bname = ls_outputdet-bname
*      swaudid = ls_outputdet-swaudid.
*    IF sy-subrc = 0.
**      get the role to which this auth belongs
*      IF ls_outputdet-child_agr IS INITIAL.
**--DHORIONS 20101210 - Optimize performance, only select once per auth
*        READ TABLE lt_auth_role
*        WITH TABLE KEY auth = ls_outputdet-auth.
*        IF sy-subrc = 0 .
*          ls_outputdet-child_agr = lt_auth_role-agr_name.
*        ELSE.
*          lt_auth_role-auth = ls_outputdet-auth.
*          CLEAR lt_auth_role-agr_name.
*          INSERT TABLE lt_auth_role.
*        ENDIF.
*        IF NOT ls_outputdet-child_agr IS INITIAL.
*          MODIFY gt_outputdet FROM ls_outputdet TRANSPORTING child_agr
*                                       WHERE auth = ls_outputdet-auth.
*        ENDIF.
*      ENDIF.
*      APPEND ls_outputdet TO lt_outputdet.
*    ELSE.
*      DELETE gt_outputdet WHERE
*        bname   = ls_outputdet-bname AND
*        swaudid = ls_outputdet-swaudid.
*    ENDIF.
*  ENDLOOP.
*ENDIF.
*
*gt_outputdet[] = lt_outputdet[].
*
*
**--restore backup to global table again (include auths not used for
**  the users we currently are analyzing
*gt_swaudid_auth[]  = lt_swaudid_auth[].
**--restore swaudc details
*gt_swaudc[] = lt_swaudc[].
*
*
*ENDFORM.                    " COMPARE_USER_AUTHS_WITH_SYSTEM
*&---------------------------------------------------------------------*
*&      Form  refresh_internal_tables
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM refresh_internal_tables.
  REFRESH : gt_swaudc[] ,
  gt_usr02[] ,
  gt_uinfo[] ,
  gt_usgrpt[],
  gt_swaudhdr[] ,
  gt_kostl_resp[],
  gt_usrefus[],
  gt_swaudid_auth[],
  gt_ust12[],
  gt_objs[],
  gt_user_auth[] ,
  gt_output[] ,
  gt_tcdaut[],
  gt_userhas_obj[],
  gt_userhas[],
  gt_outputdet[],
  gt_usertcode[],
  gt_ust10s[],
  gt_ust10c[],
  gt_usrbf3[],
  gt_roles[],
  gt_childroles[],
  roleauth[],
  roletcode[],
  gt_rolehas[],
  gt_rolehas_obj[],
  gt_routput[],
  gt_routputdet[].
  CLEAR :  gf_usrbf3_loaded.

ENDFORM.                    " refresh_internal_tables

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
         wa_userhas_obj TYPE userhas_obj_typ,
         lf_match TYPE flag.
  FIELD-SYMBOLS : <swaudid_auth> TYPE typ_swaudid_auth,
                  <user_auth>    TYPE /psyng/userauth,
                  <user>         TYPE /psyng/userauth.
  LOOP AT gt_swaudid_auth
                 ASSIGNING <swaudid_auth>
                 WHERE swaudid = <g_swaudc>-swaudid AND
                       tcode   = <g_swaudc>-tcode.

    READ TABLE gt_user_auth ASSIGNING <user_auth>
          WITH KEY
                             objct = <swaudid_auth>-object
                             auth = <swaudid_auth>-auth.
    IF sy-subrc = 0.
      iuserauth_idx = sy-tabix.
      LOOP AT gt_user_auth  ASSIGNING <user> FROM iuserauth_idx
      WHERE objct = <swaudid_auth>-object AND
                    auth = <swaudid_auth>-auth.
        wa_userhas_obj-swaudid = <g_swaudc>-swaudid.
        wa_userhas_obj-bname   = <user>-bname.
        wa_userhas_obj-tcode   = <g_swaudc>-tcode.
        wa_userhas_obj-objct   = <swaudid_auth>-object.
        INSERT wa_userhas_obj INTO TABLE gt_userhas_obj.
      ENDLOOP.
      IF gf_details = 'X' OR gf_er_or_simu = 'X'.

        LOOP AT gt_user_auth
                         ASSIGNING <user_auth> FROM iuserauth_idx
                         WHERE objct = <swaudid_auth>-object AND
                                auth = <swaudid_auth>-auth   AND
                                field = <g_swaudc>-field.
*           check if user auth really matches critical auth
          CLEAR lf_match.
*          CALL FUNCTION '/PSYNG/SW_021'
           CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
               EXPORTING
                    auth_from = <user_auth>-von
                    auth_to   = <user_auth>-bis
                    sod_from  = <g_swaudc>-val_from
                    sod_to    = <g_swaudc>-val_to
               IMPORTING
                    match     = lf_match.
          IF lf_match = 'X'.
*               document details in output table
            ls_outputdet-bname   = <user_auth>-bname.
            ls_outputdet-swaudid = <g_swaudc>-swaudid.
            ls_outputdet-tcode   = <swaudid_auth>-tcode.
            ls_outputdet-objct   = <swaudid_auth>-object.
            ls_outputdet-auth    = <swaudid_auth>-auth.
            ls_outputdet-field   = <g_swaudc>-field.
            ls_outputdet-von     = <g_swaudc>-val_from.
            ls_outputdet-bis     = <g_swaudc>-val_to.
            ls_outputdet-simu    = <user_auth>-simu.
            ls_outputdet-er      = <user_auth>-er.
            APPEND ls_outputdet TO gt_outputdet.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " if_tcode_is_star
*&---------------------------------------------------------------------
*
*&      Form  if_tcode_specified
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
FORM if_tcode_specified.
  DATA : ls_outputdet TYPE /psyng/sw_ca_outputdet,
         wa_userhas_obj TYPE userhas_obj_typ,
         lf_match TYPE flag.
  FIELD-SYMBOLS : <swaudid_auth> TYPE typ_swaudid_auth,
                  <user_auth>    TYPE /psyng/userauth,
                  <usertcode>    LIKE LINE OF gt_usertcode.
  LOOP AT gt_swaudid_auth
                 ASSIGNING <swaudid_auth>
                 WHERE swaudid = <g_swaudc>-swaudid AND
                       tcode   = <g_swaudc>-tcode   AND
                       object  = <g_swaudc>-object .

    tcdaut_idx =  sy-tabix.
    READ TABLE gt_usertcode WITH KEY tcode = <g_swaudc>-tcode
    TRANSPORTING NO FIELDS BINARY SEARCH .
    iusertcode_idx = sy-tabix.
    LOOP AT gt_usertcode ASSIGNING <usertcode>
    FROM iusertcode_idx
    WHERE tcode = <g_swaudc>-tcode.
      READ TABLE gt_user_auth
        ASSIGNING <user_auth>
        WITH TABLE KEY
                               objct = <swaudid_auth>-object
                               auth = <swaudid_auth>-auth
                               bname = <usertcode>-bname.
      IF sy-subrc = 0.
        iuserauth_idx = sy-tabix.
*       no details requested, just mark that user has object
        wa_userhas_obj-swaudid = <g_swaudc>-swaudid.
        wa_userhas_obj-bname   = <user_auth>-bname.
        wa_userhas_obj-tcode   = <g_swaudc>-tcode.
        wa_userhas_obj-objct   = <swaudid_auth>-object.
        INSERT wa_userhas_obj INTO TABLE gt_userhas_obj.

        IF gf_details = 'X' OR gf_er_or_simu = 'X'.
*         details are requested, mark each auth for this object
          LOOP AT gt_user_auth
                            ASSIGNING <user_auth> FROM iuserauth_idx
                            WHERE objct = <swaudid_auth>-object AND
                                   auth = <swaudid_auth>-auth AND
                                   bname = <usertcode>-bname AND
                                   field = <g_swaudc>-field.
*           check if user auth really matches critical auth
            CLEAR lf_match.
            CALL FUNCTION '/PSYNG/SW_021'
                 EXPORTING
                      auth_from = <user_auth>-von
                      auth_to   = <user_auth>-bis
                      sod_from  = <g_swaudc>-val_from
                      sod_to    = <g_swaudc>-val_to
                 IMPORTING
                      match     = lf_match.
            IF lf_match = 'X'.
*             document details in output details table
              ls_outputdet-bname   = <user_auth>-bname.
              ls_outputdet-swaudid = <g_swaudc>-swaudid.
              ls_outputdet-tcode   = <swaudid_auth>-tcode.
              ls_outputdet-objct   = <swaudid_auth>-object.
              ls_outputdet-auth    = <swaudid_auth>-auth.
              ls_outputdet-field   = <g_swaudc>-field.
              ls_outputdet-von     = <g_swaudc>-val_from.
              ls_outputdet-bis     = <g_swaudc>-val_to.
              ls_outputdet-simu    = <user_auth>-simu.
              ls_outputdet-er      = <user_auth>-er.

              APPEND ls_outputdet TO gt_outputdet.
            ENDIF.
          ENDLOOP.
          IF sy-subrc = 0. "auths were found
*--Dhorions 2011/07/12 : Also add tcode information
            ls_outputdet-bname   = <user_auth>-bname.
            ls_outputdet-swaudid = <g_swaudc>-swaudid.
            ls_outputdet-tcode   = <swaudid_auth>-tcode.
            ls_outputdet-objct   = 'S_TCODE'.
            ls_outputdet-auth    = gt_swaudid_auth-auth.
            ls_outputdet-field   = 'TCD'.
            ls_outputdet-von     = <g_swaudc>-tcode.
            ls_outputdet-bis     = ''.
            ls_outputdet-simu    = <user_auth>-simu.
            ls_outputdet-er      = <user_auth>-er.

            APPEND ls_outputdet TO gt_outputdet.
          ENDIF.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " if_tcode_specified
*&---------------------------------------------------------------------*
*&      Form  if_tcode_is_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM role_if_tcode_is_star.
  DATA : ls_outputdet TYPE /psyng/sw_ca_routputdet,
         wa_rolehas_obj TYPE rolehas_obj_typ,
         lf_match TYPE flag.
  FIELD-SYMBOLS : <swaudid_auth> TYPE typ_swaudid_auth,
                  <role_auth>    TYPE typ_roleauth,
                  <role>         TYPE typ_roleauth.
  LOOP AT gt_swaudid_auth
                 ASSIGNING <swaudid_auth>
                 WHERE swaudid = <g_swaudc>-swaudid AND
                       tcode   = <g_swaudc>-tcode.

    READ TABLE roleauth ASSIGNING <role_auth>
          WITH KEY
                             objct = <swaudid_auth>-object
                             auth = <swaudid_auth>-auth.
    IF sy-subrc = 0.
      iuserauth_idx = sy-tabix.
      LOOP AT roleauth  ASSIGNING <role> "FROM iuserauth_idx
      WHERE objct = <swaudid_auth>-object AND
                    auth = <swaudid_auth>-auth.
        wa_rolehas_obj-swaudid = <g_swaudc>-swaudid.
        wa_rolehas_obj-agr_name   = <role>-agr_name.
        wa_rolehas_obj-tcode   = <g_swaudc>-tcode.
        wa_rolehas_obj-objct   = <swaudid_auth>-object.
        INSERT wa_rolehas_obj INTO TABLE gt_rolehas_obj.
      ENDLOOP.
      IF gf_details = 'X'.

        LOOP AT roleauth
                         ASSIGNING <role_auth>
                         WHERE objct = <swaudid_auth>-object AND
                                auth = <swaudid_auth>-auth   AND
                                field = <g_swaudc>-field.
*           check if user auth really matches critical auth
          CLEAR lf_match.
          CALL FUNCTION '/PSYNG/SW_021'
               EXPORTING
                    auth_from = <role_auth>-von
                    auth_to   = <role_auth>-bis
                    sod_from  = <g_swaudc>-val_from
                    sod_to    = <g_swaudc>-val_to
               IMPORTING
                    match     = lf_match.
          IF lf_match = 'X'.
*               document details in output table
            ls_outputdet-agr_name   = <role_auth>-agr_name.
            ls_outputdet-swaudid = <g_swaudc>-swaudid.
            ls_outputdet-tcode   = <swaudid_auth>-tcode.
            ls_outputdet-objct   = <swaudid_auth>-object.
            ls_outputdet-auth    = <swaudid_auth>-auth.
            ls_outputdet-field   = <g_swaudc>-field.
            ls_outputdet-von     = <g_swaudc>-val_from.
            ls_outputdet-bis     = <g_swaudc>-val_to.
            APPEND ls_outputdet TO gt_routputdet.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " role_if_tcode_is_star
*&---------------------------------------------------------------------
*
*&      Form  if_tcode_specified
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
FORM role_if_tcode_specified.
  DATA : ls_outputdet TYPE /psyng/sw_ca_routputdet,
         wa_rolehas_obj TYPE rolehas_obj_typ,
         lf_match TYPE flag.
  FIELD-SYMBOLS : <swaudid_auth> TYPE typ_swaudid_auth,
                  <role_auth>    TYPE typ_roleauth,
                  <roletcode>    TYPE typ_roletcode.
  LOOP AT gt_swaudid_auth
                 ASSIGNING <swaudid_auth>
                 WHERE swaudid = <g_swaudc>-swaudid AND
                       tcode   = <g_swaudc>-tcode   AND
                       object  = <g_swaudc>-object .

    tcdaut_idx =  sy-tabix.
    LOOP AT roletcode ASSIGNING <roletcode>
    WHERE tcode = <g_swaudc>-tcode.
      READ TABLE roleauth
        ASSIGNING <role_auth>
        WITH KEY
                               objct = <swaudid_auth>-object
                               auth = <swaudid_auth>-auth
                               agr_name = <roletcode>-agr_name.
      IF sy-subrc = 0.
*       no details requested, just mark that role has object
        wa_rolehas_obj-swaudid = <g_swaudc>-swaudid.
        wa_rolehas_obj-agr_name   = <role_auth>-agr_name.
        wa_rolehas_obj-tcode   = <g_swaudc>-tcode.
        wa_rolehas_obj-objct   = <swaudid_auth>-object.
        INSERT wa_rolehas_obj INTO TABLE gt_rolehas_obj.

        IF gf_details = 'X'.
*         details are requested, mark each auth for this object
          LOOP AT roleauth
                           ASSIGNING <role_auth>
                            WHERE objct = <swaudid_auth>-object AND
                                   auth = <swaudid_auth>-auth AND
                                   agr_name = <roletcode>-agr_name AND
                                   field = <g_swaudc>-field.
*           check if role auth really matches critical auth
            CLEAR lf_match.
            CALL FUNCTION '/PSYNG/SW_021'
                 EXPORTING
                      auth_from = <role_auth>-von
                      auth_to   = <role_auth>-bis
                      sod_from  = <g_swaudc>-val_from
                      sod_to    = <g_swaudc>-val_to
                 IMPORTING
                      match     = lf_match.
            IF lf_match = 'X'.
*             document details in output details table
              ls_outputdet-agr_name   = <role_auth>-agr_name.
              ls_outputdet-swaudid = <g_swaudc>-swaudid.
              ls_outputdet-tcode   = <swaudid_auth>-tcode.
              ls_outputdet-objct   = <swaudid_auth>-object.
              ls_outputdet-auth    = <swaudid_auth>-auth.
              ls_outputdet-field   = <g_swaudc>-field.
              ls_outputdet-von     = <g_swaudc>-val_from.
              ls_outputdet-bis     = <g_swaudc>-val_to.
              APPEND ls_outputdet TO gt_routputdet.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " role_if_tcode_specified

*&---------------------------------------------------------------------*
*&      Form  get_identical_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_BNAME  text
*----------------------------------------------------------------------*
*FORM get_identical_users TABLES   it_bname STRUCTURE /psyng/range_bname
*                                  it_class STRUCTURE /psyng/range_class.
*
*  CALL FUNCTION '/PSYNG/SW_IDCL_USER'
*    STARTING NEW TASK idcl_task
*    DESTINATION IN GROUP DEFAULT
*    PERFORMING get_idcl_user ON END OF TASK
*    EXPORTING
*      validusr        = gf_validuser
*    TABLES
*      pbname_fm       = it_bname
*      iduser_fm       = gt_iduser
*      pclass_fm       = it_class
*    EXCEPTIONS
*     RESOURCE_FAILURE      = 1
*     communication_failure = 2
*     system_failure        = 3.
*  IF sy-subrc <> 0.
*    CALL FUNCTION '/PSYNG/SW_IDCL_USER'
*         EXPORTING
*              validusr  = gf_validuser
*         TABLES
*              pbname_fm = it_bname
*              iduser_fm = gt_iduser
*              pclass_fm = it_class.
*    IF sy-subrc = 0.
*      functioncall_2 = done.
*    ENDIF.
*  ENDIF.
*ENDFORM.                    " get_identical_users

*---------------------------------------------------------------------*
*       FORM GET_IDCL_USER                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_idcl_user USING taskname.

  DATA: messagetext(40).

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_IDCL_USER'
    TABLES
      iduser_fm       = gt_iduser.

  IF sy-subrc = 0.
    functioncall_2 = done.
  ELSE.
    CONCATENATE text-051 taskname INTO
                 messagetext SEPARATED BY space.
    MESSAGE s208(00) WITH messagetext.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  process_identical_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM process_identical_users.
*  FIELD-SYMBOLS : <usr> LIKE LINE OF gt_iduser,
*                  <out> LIKE LINE OF gt_output,
*                  <outdet> LIKE LINE OF gt_outputdet,
*                  <uinfo> LIKE LINE OF gt_uinfo.
*
*  DATA : l_output_idx LIKE sy-tabix,
*         ls_output LIKE LINE OF gt_output,
*         ls_outputdet LIKE LINE OF gt_outputdet..
*  LOOP AT gt_iduser ASSIGNING <usr>.
*    READ TABLE gt_output WITH KEY bname = <usr>-bname
*                                   BINARY SEARCH
*                                   TRANSPORTING NO FIELDS.
*    IF sy-subrc = 0.
*      l_output_idx = sy-tabix.
*      LOOP AT gt_output ASSIGNING <out> FROM l_output_idx
*              WHERE bname = <usr>-bname.
*        ls_output = <out>.
*        ls_output-bname = <usr>-idbname.
*        READ TABLE gt_uinfo ASSIGNING <uinfo>
*          WITH KEY bname = ls_output-bname.
*        IF sy-subrc = 0.
*          ls_output-persa = <uinfo>-persa.
*          ls_output-pernr = <uinfo>-pernr.
*          ls_output-kostl = <uinfo>-kostl.
*          ls_output-name_text = <uinfo>-name_text.
*          ls_output-uflag = <uinfo>-uflag.
*          ls_output-trdat = <uinfo>-trdat.
*          ls_output-sodcount = <uinfo>-sodcount.
*
*        ENDIF.
*        INSERT ls_output INTO TABLE gt_output.
*      ENDLOOP.
*    ENDIF.
*    IF gf_details = 'X'.
*      READ TABLE gt_outputdet WITH KEY bname = <usr>-bname
*                                       BINARY SEARCH
*                                      TRANSPORTING NO FIELDS.
*      IF sy-subrc = 0.
*        l_output_idx = sy-tabix.
*        LOOP AT gt_outputdet ASSIGNING <outdet> FROM l_output_idx
*                WHERE bname = <usr>-bname.
*          ls_outputdet = <outdet>.
*          ls_outputdet-bname = <usr>-idbname.
*          INSERT ls_outputdet INTO TABLE gt_outputdet.
*        ENDLOOP.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*ENDFORM.                    " process_identical_users
*&---------------------------------------------------------------------*
*&      Form  handle_reference_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM handle_reference_users.
*  FIELD-SYMBOLS :<refus> LIKE LINE OF gt_usrefus,
*                 <usrauth> LIKE LINE OF gt_user_auth,
*                 <usrtcode> LIKE LINE OF gt_usertcode.
*  DATA : ls_user_auth LIKE LINE OF gt_user_auth,
*         ls_usertcode LIKE LINE OF gt_usertcode,
*         lt_usrefus TYPE TABLE OF usrefus WITH HEADER LINE .
*
*  lt_usrefus[] = gt_usrefus[].
*  SORT lt_usrefus BY refuser.
*  DELETE ADJACENT DUPLICATES FROM lt_usrefus COMPARING refuser.
*  LOOP AT lt_usrefus.
*    LOOP AT gt_user_auth ASSIGNING <usrauth>
*    WHERE bname = lt_usrefus-refuser.
*      LOOP AT gt_usrefus ASSIGNING <refus>.
*        ls_user_auth = <usrauth>.
*        ls_user_auth-bname = <refus>-bname.
*        INSERT ls_user_auth INTO TABLE gt_user_auth.
*      ENDLOOP.
*    ENDLOOP.
*  ENDLOOP.
*  LOOP AT gt_usrefus ASSIGNING <refus>.
*    LOOP AT gt_usertcode ASSIGNING <usrtcode>
*    WHERE bname = <refus>-refuser
*    .
*      ls_usertcode = <usrtcode>.
*      ls_usertcode-bname = <refus>-bname.
*      INSERT ls_usertcode INTO TABLE gt_usertcode.
*    ENDLOOP.
*  ENDLOOP.
*
*  LOOP AT gt_usrefus ASSIGNING <refus>.
*    DELETE gt_user_auth WHERE bname = <refus>-refuser.
*    DELETE gt_usertcode WHERE bname = <refus>-refuser.
*  ENDLOOP.
*ENDFORM.                    " handle_reference_users

*&---------------------------------------------------------------------*
*&      Form  update_sys_scan_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SWAUDID  text
*      -->P_I_VRSIO  text
*----------------------------------------------------------------------*
*FORM update_sys_scan_info TABLES
*                           it_swaudid STRUCTURE  /psyng/range_swaudid
*                           USING i_vrsio TYPE /psyng/sodvrsio.
*  DATA: nodelete,
*        lt_userhas TYPE STANDARD TABLE OF userhas_typ,
*        lt_swhas type standard table of
*        /PSYNG/SW_USHAS with header line.
*  IF NOT  it_swaudid[] IS INITIAL. "don't delete all records of users
*    nodelete = 'Y'.             "specific conflicts were queried
*  ELSE.
*    nodelete = ''.
*  ENDIF.
*
*  loop at gt_userhas.
*    move-corresponding gt_userhas to lt_swhas.
*    append lt_swhas.
*  endloop.
*  REFRESH: gt_userhas.
*  CALL FUNCTION '/PSYNG/SW_UPDT_CRI_AUTH_INFO'
*      IN BACKGROUND TASK
*    EXPORTING
*      vrsio          = i_vrsio
*      nodelete       = nodelete
*      if_validuser   = gf_validuser
*    TABLES
*      iusr02         = gt_usr02
**      userhas        = lt_userhas.
*      userhas        = lt_swhas.
*  COMMIT WORK.  "trigger execution of background processing of FMs
*ENDFORM.                    " update_sys_scan_info
*&---------------------------------------------------------------------*
*&      Form  get_sap_all_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_UNIQUE_USR02  text
*      -->P_LT_SAP_ALL_USERS  text
*----------------------------------------------------------------------*
*FORM get_sap_all_users TABLES   it_usr02 STRUCTURE usr02
*                                et_sap_all_users STRUCTURE usr02.
*  FIELD-SYMBOLS : <usr> TYPE usr02.
*  CHECK NOT it_usr02[] IS INITIAL.
*  SELECT bname FROM ust04
*    INTO CORRESPONDING FIELDS OF TABLE et_sap_all_users
*    FOR ALL ENTRIES IN it_usr02
*    WHERE
*    bname = it_usr02-bname  AND
*    profile = 'SAP_ALL'.
*
*  LOOP AT et_sap_all_users ASSIGNING <usr>.
*    DELETE it_usr02 WHERE bname = <usr>-bname.
*  ENDLOOP.
*
*ENDFORM.                    " get_sap_all_users
*&---------------------------------------------------------------------*
*&      Form  process_sap_all_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_SAP_ALL_USERS  text
*----------------------------------------------------------------------*
*FORM process_sap_all_users TABLES   it_sap_all_users STRUCTURE usr02.
*
*  FIELD-SYMBOLS : <usr> TYPE usr02,
*                  <out> LIKE LINE OF gt_output,
*                  <outdet> LIKE LINE OF gt_outputdet,
*                  <uinfo> LIKE LINE OF gt_uinfo.
*
*  DATA : ls_output LIKE LINE OF gt_output.
*  LOOP AT it_sap_all_users ASSIGNING <usr>.
*    ls_output-swaudid = 'ALL'.
*
*    ls_output-bname = <usr>-bname.
*    READ TABLE gt_uinfo ASSIGNING <uinfo>
*      WITH KEY bname = ls_output-bname.
*    IF sy-subrc = 0.
*      ls_output-persa = <uinfo>-persa.
*      ls_output-pernr = <uinfo>-pernr.
*      ls_output-kostl = <uinfo>-kostl.
*      ls_output-name_text = <uinfo>-name_text.
*      ls_output-uflag = <uinfo>-uflag.
*      ls_output-trdat = <uinfo>-trdat.
*      ls_output-sodcount = <uinfo>-sodcount.
*    ENDIF.
*    INSERT ls_output INTO TABLE gt_output.
*  ENDLOOP.
*
*
*
*ENDFORM.                    " process_sap_all_users
*&---------------------------------------------------------------------*
*&      Form  get_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_AGR_NAME  text
*----------------------------------------------------------------------*
FORM get_roles TABLES   it_agr_name STRUCTURE /psyng/range_agr_name
USING
  i_comproles   TYPE flag
  i_singleroles TYPE flag.

  CALL FUNCTION '/PSYNG/SW_066'
       EXPORTING
            i_composite_roles = i_comproles
            i_single_roles    = i_singleroles
       TABLES
            it_roles          = it_agr_name
            et_roles          = gt_roles
            et_childroles     = gt_childroles.

ENDFORM.                    " get_roles


*&---------------------------------------------------------------------*
*&      Form  get_roles_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  <--  ET_RETURN  Return messages
*----------------------------------------------------------------------*
FORM get_roles_data ."TABLES et_return STRUCTURE bapiret2.
  DATA : rfcdest TYPE rfcdest,
         subrc LIKE sy-subrc.

************** Get all data from database at once ********************
  DATA: lt_totalagr TYPE STANDARD TABLE OF agr_define
        WITH HEADER LINE.
  DATA: wa_1016 TYPE agr_1016.
  DATA: wa_1251 TYPE agr_1251.
  DATA: wa_1252 TYPE agr_1252.
  DATA: BEGIN OF roleauth_fm OCCURS 100.       "Role auth details
          INCLUDE STRUCTURE /psyng/userauth.
  DATA: END OF roleauth_fm.
  DATA: BEGIN OF roletcode_fm OCCURS 10.       "Role tcode details
          INCLUDE STRUCTURE /psyng/usertcode.
  DATA: END OF roletcode_fm.
  DATA: BEGIN OF roleprof_fm OCCURS 10.
          INCLUDE STRUCTURE /psyng/userprof.
  DATA: END OF roleprof_fm.
  DATA: BEGIN OF functtran OCCURS 100.
          INCLUDE STRUCTURE /psyng/functtran.
  DATA: END OF functtran.
  DATA: conflict TYPE SORTED TABLE OF /psyng/conflict WITH UNIQUE KEY
        conid "description
        WITH HEADER LINE.
  DATA: confdet TYPE SORTED TABLE OF /psyng/confdet WITH UNIQUE KEY
                conid functionid
                WITH HEADER LINE.
  DATA: BEGIN OF faobj OCCURS 100.
          INCLUDE STRUCTURE /psyng/faobj2.
  DATA: END OF faobj.
  TYPES: BEGIN OF typ_roletcode.
          INCLUDE STRUCTURE /psyng/roletcode.
  TYPES: END OF typ_roletcode.
  TYPES: BEGIN OF typ_roleauth.
          INCLUDE STRUCTURE /psyng/roleauth.
  TYPES: END OF typ_roleauth.


  DATA: wa_roletcode TYPE typ_roletcode.
  DATA: wa_roleauth TYPE typ_roleauth.

  FIELD-SYMBOLS : <swaudhdr> TYPE /psyng/swaudhdr,
                  <swaudc>   TYPE /psyng/swaudc2.


*--Convert Critical Auth data to Function format
  LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
    functtran-functionid = <swaudhdr>-swaudid.
    functtran-tcode = <swaudhdr>-tcode.
    APPEND functtran.
  ENDLOOP.

  LOOP AT gt_swaudc ASSIGNING <swaudc>.
    faobj-funid = <swaudc>-swaudid.
    MOVE-CORRESPONDING <swaudc> TO faobj.
    APPEND faobj.
  ENDLOOP.


* collect all single role names into one table
  APPEND LINES OF gt_roles TO lt_totalagr.
  LOOP AT gt_childroles.
    lt_totalagr-agr_name =  gt_childroles-child_agr.
    APPEND lt_totalagr.
  ENDLOOP.

  SORT lt_totalagr.
  DELETE ADJACENT DUPLICATES FROM lt_totalagr.

* get profiles of single roles
  IF NOT lt_totalagr[] IS INITIAL.
    SELECT agr_name profile
           INTO CORRESPONDING FIELDS OF TABLE lt_1016
           FROM agr_1016
           FOR ALL ENTRIES IN lt_totalagr
           WHERE agr_name = lt_totalagr-agr_name.
  ENDIF.
* get auth names of roles.
  IF NOT lt_1016[] IS INITIAL.
    SELECT profn aktps objct auth
           INTO CORRESPONDING FIELDS OF TABLE lt_ust10s
           FROM ust10s
           FOR ALL ENTRIES IN lt_1016
           WHERE profn = lt_1016-profile AND aktps = 'A'.
  ENDIF.


************** Database selection complete ********************


* Find role's tcodes/authorizations/profiles
  SORT gt_roles.
  LOOP AT gt_roles.
    LOOP AT gt_childroles WHERE agr_name = gt_roles-agr_name.

      CLEAR:   roleauth_fm, roletcode_fm, roleprof_fm,
               et_1016, et_1251, et_1252, et_ust10s.
      REFRESH: roletcode_fm, roleprof_fm, roleauth_fm,
               et_1016, et_1251, et_1252, et_ust10s.

      PERFORM move_data_to_temp_tabs
              USING gt_childroles-child_agr.

      CALL FUNCTION '/PSYNG/SW_SODSYS_GET_ROLE_DATA'
           EXPORTING
                agr_name      = gt_childroles-child_agr
                bname         = ''
                i_authdetails = gf_details
           TABLES
                roleauth      = roleauth_fm
                roletcode     = roletcode_fm
                roleprof      = roleprof_fm
                functtran     = functtran
                faobj         = faobj
                it_1016       = et_1016
                it_ust10s     = et_ust10s.

      CLEAR: wa_roletcode, wa_roleauth.
      LOOP AT roletcode_fm.
        wa_roletcode-agr_name  = gt_roles-agr_name.
        wa_roletcode-tcode     = roletcode_fm-tcode.
        wa_roletcode-rfcdest   = roletcode_fm-rfcdest.
        INSERT wa_roletcode INTO TABLE roletcode.
      ENDLOOP.
      LOOP AT roleauth_fm.
        MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
        wa_roleauth-agr_name  = gt_roles-agr_name.
        INSERT wa_roleauth INTO TABLE roleauth.
      ENDLOOP.
    ENDLOOP.   "lt_agr_agrs
    subrc = sy-subrc.


    CHECK subrc <> 0.  "next role if role is composite

    CLEAR:   roleauth_fm, roletcode_fm, roleprof_fm,
             et_1016, et_1251, et_1252, et_ust10s.
    REFRESH: roletcode_fm, roleprof_fm, roleauth_fm,
             et_1016, et_1251, et_1252, et_ust10s.

    PERFORM move_data_to_temp_tabs
            USING gt_roles-agr_name.

    CALL FUNCTION '/PSYNG/SW_SODSYS_GET_ROLE_DATA'
         EXPORTING
              agr_name      = gt_roles-agr_name
              bname         = ''
              i_authdetails = gf_details
         TABLES
              roleauth      = roleauth_fm
              roletcode     = roletcode_fm
              roleprof      = roleprof_fm
              functtran     = functtran
              faobj         = faobj
              it_1016       = et_1016
              it_ust10s     = et_ust10s.
    CLEAR: wa_roletcode, wa_roleauth.
    LOOP AT roletcode_fm.
      MOVE-CORRESPONDING roletcode_fm TO wa_roletcode.
      CLEAR: wa_roletcode-child_agr.
      INSERT wa_roletcode INTO TABLE roletcode.
    ENDLOOP.

    LOOP AT roleauth_fm.
      MOVE-CORRESPONDING roleauth_fm TO wa_roleauth.
      INSERT wa_roleauth INTO TABLE roleauth.
    ENDLOOP.
  ENDLOOP.    "IAGR_DEFINE

  CLEAR: roleauth_fm, roletcode_fm, roleprof_fm.
  FREE:   roletcode_fm, roleprof_fm, roleauth_fm,
         et_1016, et_1251, et_1252, et_ust10s,
         lt_1016, lt_1251, lt_1252, lt_ust10s.

ENDFORM.                    " get_roles_data
*&---------------------------------------------------------------------*
*&      Form  move_data_to_temp_tabs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_to_temp_tabs USING rolename TYPE agr_define-agr_name.

  DATA: lf_value(50),
        if_value(50),
        lf_foundone.

* Data will be moved using loops if last charcter of role name is
* 'Z' or '9'.

  MOVE rolename TO lf_value.
  CALL FUNCTION '/PSYNG/BC_GET_NEXT_CHAR'
       EXPORTING
            if_value            = lf_value
       IMPORTING
            ef_value            = if_value
            ef_foundone         = lf_foundone
       EXCEPTIONS
            value_over_50_chars = 1
            OTHERS              = 2.

  IF sy-subrc <> 0 OR lf_foundone IS INITIAL.
    PERFORM move_data_via_loops USING rolename.
  ELSE.
    MOVE if_value TO next_agr_name.
    PERFORM move_data_via_no_loops USING rolename .
  ENDIF.

ENDFORM.                    " move_data_to_temp_tabs
*&---------------------------------------------------------------------*
*&      Form  move_data_via_no_loops
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_via_no_loops USING rolename LIKE agr_define-agr_name.

  DATA: lf_value(50),
        if_value(50),
        lf_foundone.

* This logic may not work properly if the role name is 30 chars
* long and the last character of it is '~'.
*  next_agr_name = lt_agrs-child_agr.
*  length = strlen( next_agr_name ) .  "get current length
*  length = length - 1 .               "get proper off-set
*  next_agr_name+length(1) = '~'.      "replace last char

* Problem:
*   Instead of replacing the last character to '~', the last character
*   should be replaced by the next character or digit based on the
*   current last character.  Replacing the last char to '~'  will
*   include all values from current last char to '~', which is not
*   desired.

* Solution:
*   Need to implement SY-ABCDE or something similar


*     AGR_1016
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  READ TABLE lt_1016 WITH KEY agr_name = next_agr_name
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx2 = sy-tabix.
  IF idx2 GT 1.
    idx2 = idx2 - 1.
  ENDIF.
  APPEND LINES OF lt_1016 FROM idx1 TO idx2 TO et_1016 .


*     UST10S
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 WHERE agr_name = rolename.

    MOVE lt_1016-profile TO lf_value.
    CALL FUNCTION '/PSYNG/BC_GET_NEXT_CHAR'
         EXPORTING
              if_value            = lf_value
         IMPORTING
              ef_value            = if_value
              ef_foundone         = lf_foundone
         EXCEPTIONS
              value_over_50_chars = 1
              OTHERS              = 2.

    IF sy-subrc <> 0 OR lf_foundone IS INITIAL.
      READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      idx2 = sy-tabix.
      LOOP AT lt_ust10s FROM idx2 INTO et_ust10s
              WHERE profn = lt_1016-profile.
        APPEND et_ust10s.
      ENDLOOP.
    ELSE.
      MOVE if_value TO next_profn.
      READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      idx2 = sy-tabix.
      READ TABLE lt_ust10s WITH KEY profn = next_profn
           BINARY SEARCH TRANSPORTING NO FIELDS.
      idx3 = sy-tabix.
      IF idx3 GT 1.
        idx3 = idx3 - 1.
      ENDIF.
      APPEND LINES OF lt_ust10s FROM idx2 TO idx3 TO et_ust10s.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " move_data_via_no_loops
*&---------------------------------------------------------------------*
*&      Form  move_data_via_loops
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM move_data_via_loops USING rolename TYPE agr_define-agr_name.

*     AGR_1016
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 INTO et_1016
          WHERE agr_name = rolename.
    APPEND et_1016.
  ENDLOOP.


*     UST10S
  READ TABLE lt_1016 WITH KEY agr_name = rolename
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx1 = sy-tabix.
  LOOP AT lt_1016 FROM idx1 WHERE agr_name = rolename.
    READ TABLE lt_ust10s WITH KEY profn = lt_1016-profile
               BINARY SEARCH TRANSPORTING NO FIELDS.
    idx2 = sy-tabix.
    LOOP AT lt_ust10s FROM idx2 INTO et_ust10s
            WHERE profn = lt_1016-profile.
      APPEND et_ust10s.
    ENDLOOP.
  ENDLOOP.

ENDFORM.                    " move_data_via_loops
*&---------------------------------------------------------------------*
*&      Form  compare_role_auths_with_system
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM compare_role_auths_with_system.
  MESSAGE s113(/psyng/sw) WITH
  text-002.
  COMMIT WORK.

  FIELD-SYMBOLS : <swaudid_auth> LIKE LINE OF gt_swaudid_auth,
                  <role_auth> LIKE LINE OF roleauth.
  DATA : ls_swaudc LIKE LINE OF gt_swaudc,
         lt_swaudid_auth TYPE TABLE OF typ_swaudid_auth,
         lt_swaudc TYPE TABLE OF /psyng/swaudc2.

*--remove auths from gt_swaudid_auth that no users have
  MESSAGE s113(/psyng/sw) WITH
  'Remove unused auths'.
  COMMIT WORK.
*-- backupglobal table (include auths not used for
*  the users we currently are analyzing
  lt_swaudid_auth[] = gt_swaudid_auth[].
  LOOP AT gt_swaudid_auth ASSIGNING <swaudid_auth>.
    READ TABLE roleauth WITH KEY objct  = <swaudid_auth>-object
                                  auth   = <swaudid_auth>-auth
                                  TRANSPORTING NO FIELDS.
    IF sy-subrc <> 0.
      DELETE  gt_swaudid_auth WHERE object  = <swaudid_auth>-object
                                 AND auth   = <swaudid_auth>-auth.
    ENDIF.
  ENDLOOP.
  MESSAGE s113(/psyng/sw) WITH
  'Finished removing unused auths'.
  COMMIT WORK.

  IF gf_details IS INITIAL.
*--Backup swaudc details
    lt_swaudc[] = gt_swaudc[].
    MODIFY gt_swaudc FROM ls_swaudc
                   TRANSPORTING
*                      object
                      valueset
                      field
                      val_from
                      val_to
                    WHERE
                      swaudid <> space.
    SORT gt_swaudc.
    DELETE ADJACENT DUPLICATES FROM gt_swaudc.
  ENDIF.


  DATA : l_swaudid_count TYPE i,
         l_swaudid_index TYPE i,
         l_swaudid_index_str TYPE string,
         l_pct TYPE f,
         l_pct_i TYPE i,
         l_pct_str TYPE string,
         l_prev_pct_str TYPE string,
         l_mod TYPE i,
         l_rescount TYPE i,
         l_rescount_str TYPE string,
         l_progress1 TYPE string,
         l_progress2 TYPE string,
         l_progress3 TYPE string.
  DESCRIBE TABLE gt_swaudc LINES l_swaudid_count.

  LOOP AT gt_swaudc ASSIGNING <g_swaudc>.
*--START : Display progress
    ADD 1 TO l_swaudid_index.
    l_pct = ( l_swaudid_index /  l_swaudid_count ) * 100.
    l_mod =  l_pct MOD 10.
    IF l_mod = 0.
      l_pct_i = l_pct.
      l_pct_str = l_pct_i.
      IF l_prev_pct_str <> l_pct_str.
        DESCRIBE TABLE gt_routputdet LINES l_rescount.
        l_swaudid_index_str = l_swaudid_index.
        l_rescount_str = l_rescount.
        CONCATENATE
          l_pct_str '% done - '
        INTO l_progress1 SEPARATED BY space.
        CONCATENATE
              'Analyzed : ' l_swaudid_index_str ' - '
        INTO l_progress2 SEPARATED BY space.
        IF gf_details = 'X'.
          CONCATENATE
                'results : ' l_rescount_str
          INTO l_progress3 SEPARATED BY space.
        ENDIF.
        MESSAGE s398(00) WITH l_progress1 l_progress2 l_progress3.
        COMMIT WORK.
      ENDIF.
      l_prev_pct_str = l_pct_str.
    ENDIF.
*--END : Display progress

    READ TABLE gt_swaudid_auth WITH KEY
    swaudid = <g_swaudc>-swaudid
    object  = <g_swaudc>-object
    tcode = <g_swaudc>-tcode
    TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    IF <g_swaudc>-tcode = '*'.
      PERFORM role_if_tcode_is_star.
    ELSE.
      PERFORM role_if_tcode_specified.
    ENDIF.
  ENDLOOP.

  SORT gt_routputdet.
  DELETE ADJACENT DUPLICATES FROM gt_routputdet.

*--------------------------------------------------------------------
*User should have access to ALL objects withing crit auth
*check if user has auth for all objects and fill table userhas
  DATA : wa_rolehas_obj LIKE LINE OF gt_rolehas_obj,
         wa_rolehas LIKE LINE OF gt_rolehas,
         lt_roles TYPE TABLE OF rolehas_obj_typ ,
         rolehasflag TYPE flag,
         ls_output LIKE LINE OF gt_routput,
         ls_outputdet LIKE LINE OF gt_routputdet,
         lt_outputdet LIKE TABLE OF ls_outputdet.
  FIELD-SYMBOLS : <role> TYPE rolehas_obj_typ,
                  <iswaudc> TYPE /psyng/swaudc2,
                  <rolehas> LIKE LINE OF gt_rolehas.
  lt_roles[] = gt_rolehas_obj[].
  SORT lt_roles.
  DELETE ADJACENT DUPLICATES FROM lt_roles COMPARING agr_name.
  LOOP AT lt_roles ASSIGNING <role> .
    LOOP AT gt_swaudc ASSIGNING <iswaudc>.
      AT NEW swaudid.
        rolehasflag = 'X'.
      ENDAT.
      IF rolehasflag = 'X'.
*   if not, role doesn't have all objects of cri
        READ TABLE gt_rolehas_obj WITH TABLE KEY
            agr_name   = <role>-agr_name
            swaudid = <iswaudc>-swaudid
            tcode   = <iswaudc>-tcode
            objct   = <iswaudc>-object
            TRANSPORTING NO FIELDS.
        IF sy-subrc <> 0.
          CLEAR rolehasflag.
        ENDIF.
      ENDIF.
      AT END OF swaudid.
        IF rolehasflag = 'X'.
          wa_rolehas-swaudid = <iswaudc>-swaudid.
          wa_rolehas-agr_name = <role>-agr_name.
          INSERT wa_rolehas INTO TABLE gt_rolehas.
        ENDIF.
      ENDAT.
    ENDLOOP.
  ENDLOOP.
  MESSAGE s208(00) WITH text-003.
  COMMIT WORK.
  FREE :gt_rolehas_obj[],lt_roles,rolehasflag,wa_rolehas_obj.

  MESSAGE s208(00) WITH text-011.
  COMMIT WORK.
  DATA : l_rfcdest TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
  LOOP AT gt_swaudc ASSIGNING <g_swaudc>.
    LOOP AT gt_rolehas ASSIGNING <rolehas>
    WHERE swaudid = <g_swaudc>-swaudid.
      ls_output-swaudid = <g_swaudc>-swaudid.
      ls_output-agr_name = <rolehas>-agr_name.
      ls_output-rfcdest = l_rfcdest.
      INSERT ls_output INTO TABLE gt_routput.
    ENDLOOP.
  ENDLOOP.
  DELETE ADJACENT DUPLICATES FROM gt_routput.
  IF gf_details = 'X'.
    LOOP AT gt_routputdet INTO ls_outputdet.
      READ TABLE gt_routput
      INTO ls_output
      WITH KEY
        agr_name = ls_outputdet-agr_name
        swaudid = ls_outputdet-swaudid.
      IF sy-subrc = 0.
*      get the role to which this auth belongs
        IF ls_outputdet-child_agr IS INITIAL.
          SELECT SINGLE agr_name                "#EC CI_IMUD_NESTED
            INTO ls_outputdet-child_agr
          FROM agr_1250 WHERE auth = ls_outputdet-auth.
          IF sy-subrc = 0.
          MODIFY gt_routputdet FROM ls_outputdet TRANSPORTING child_agr
                                         WHERE auth = ls_outputdet-auth.
          ENDIF.
        ENDIF.
      ELSE.
        DELETE gt_routputdet WHERE
          agr_name   = ls_outputdet-agr_name AND
          swaudid = ls_outputdet-swaudid.
      ENDIF.
    ENDLOOP.
  ENDIF.
  MESSAGE s113(/psyng/sw) WITH
  'Finished Comparing user auths with system auths'.
  COMMIT WORK.
*

*--restore backup to global table again (include auths not used for
*  the users we currently are analyzing
  gt_swaudid_auth[]  = lt_swaudid_auth[].
*--restore swaudc details
  gt_swaudc[] = lt_swaudc[].
  gt_routputdet-rfcdest = l_rfcdest.
  MODIFY gt_routputdet TRANSPORTING rfcdest WHERE rfcdest = ''.
ENDFORM.                    " compare_role_auths_with_system
*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.
  TYPES : BEGIN OF typ_rpoug ,
    vrsio TYPE /psyng/sodvrsio,
    class TYPE xuclass,
    company TYPE char20,
    rejected TYPE flag,
    END OF typ_rpoug.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
    lt_rpoug-vrsio = i_vrsio.
    lt_rpoug-class = is_uinfo-class.
    lt_rpoug-company = is_uinfo-company.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD is_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD i_vrsio
           ID 'Y&SW_COMP'   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = 'X'.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.
ENDFORM.                    " check_rpoug_auth
*&---------------------------------------------------------------------*
*&      Form  get_unique_user_auths
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM get_unique_user_auths.
*  TYPES: BEGIN OF typ_prof ,
*         profile TYPE ust10c-profn,
*         END OF typ_prof.
*
*  DATA : BEGIN OF ls_range_object,
*          sign TYPE tvarv_sign,
*          option TYPE tvarv_opti,
*          low TYPE xuobject,
*          high TYPE xuobject,
*         END OF ls_range_object,
*         lt_range_object LIKE TABLE OF ls_range_object,
*         l_idx LIKE sy-tabix,
*         lt_usr02 TYPE TABLE OF usr02,
*         lt_usr02_part TYPE TABLE OF usr02 WITH HEADER LINE,
*         lt_unique_userauths LIKE TABLE OF usrbf2 WITH HEADER LINE,
*         lt_unique_userauths_all LIKE TABLE OF usrbf2,
*         lt_profiles_tmp TYPE TABLE OF typ_prof,
*         lt_profiles TYPE TABLE OF typ_prof,
*
*         lt_subprofs TYPE TABLE OF ust10c,
*                  ls_prof TYPE typ_prof,
*
*         lt_auths TYPE TABLE OF ust10s,
*         l_unbuffered_users TYPE i,
*         l_unbuffered_users_c TYPE string,
*         l_unique_auths TYPE i,
*         l_unique_auths_c TYPE string
*.
*  FIELD-SYMBOLS : <swaudhdr> TYPE /psyng/swaudhdr,
*                  <swaudc>   TYPE /psyng/swaudc2,
*                  <prof> TYPE typ_prof,
*                  <auth>   TYPE ust10s,
*                  <subp> TYPE ust10c.
*  MESSAGE s113(/psyng/sw) WITH
*  'Loading unique authorizations.'(021).
*  COMMIT WORK.
*
*  ls_range_object-sign = 'I'.
*  ls_range_object-option = 'EQ'.
*  LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
*    LOOP AT gt_swaudc ASSIGNING <swaudc>
*         FROM l_idx WHERE swaudid = <swaudhdr>-swaudid.
*      l_idx = sy-tabix.
*      ls_range_object-low = <swaudc>-object.
*      COLLECT ls_range_object INTO lt_range_object.
*    ENDLOOP.
*  ENDLOOP.
*  SORT lt_range_object.
*  lt_usr02[] = gt_usr02[].
*  WHILE NOT lt_usr02[] IS INITIAL.
*    APPEND LINES OF lt_usr02 FROM 1 TO 5000 TO lt_usr02_part .
*    DELETE lt_usr02 FROM 1 TO 5000.
*
*
*    if not lt_usr02_part[] is initial.
*      SELECT  auth  FROM usrbf2               "#EC CI_IMUD_NESTED
*      INTO  CORRESPONDING FIELDS OF TABLE lt_unique_userauths
*      FOR ALL ENTRIES IN lt_usr02_part WHERE
*      bname = lt_usr02_part-bname AND
*      objct IN lt_range_object.
*    endif.
*    CALL FUNCTION '/PSYNG/SW_055'
*         TABLES
*              it_users = lt_usr02_part.
*    LOOP AT lt_usr02_part.
*      FREE :  lt_auths,lt_subprofs.
*      READ TABLE gt_usrbf3 WITH TABLE KEY bname = lt_usr02_part-bname
*      TRANSPORTING NO FIELDS.
*      IF sy-subrc <> 0.
*        ADD 1 TO l_unbuffered_users.
*        SELECT profile  FROM  ust04
*            INTO TABLE lt_profiles
*                WHERE bname = lt_usr02_part-bname.
**   get values from ust12
*        IF NOT lt_profiles[] IS INITIAL.
**     get subprofiles
*          DATA : ust10_tabix LIKE sy-tabix,
*                 lt_ust10c   TYPE SORTED TABLE OF ust10c
*                             with non-unique key profn.
*          SORT gt_ust10c.
*          lt_ust10c[] = gt_ust10c[].
*          LOOP AT lt_profiles ASSIGNING <prof>.
*            READ TABLE lt_ust10c WITH TABLE KEY profn = <prof>-profile
*            TRANSPORTING NO FIELDS.
*            IF sy-subrc = 0.
*              ust10_tabix = sy-tabix.
*              LOOP AT gt_ust10c FROM ust10_tabix ASSIGNING <subp>
*              WHERE profn = <prof>-profile.
*                APPEND <subp> TO lt_subprofs.
*              ENDLOOP.
*            ELSE.
*              SELECT profn subprof FROM  ust10c
*              APPENDING CORRESPONDING FIELDS OF
*                        TABLE lt_subprofs
*                          WHERE
*                            profn  = <prof>-profile
*                         AND    aktps  = 'A'.
**--   buffer subprofile -> profile link
*              INSERT LINES OF lt_subprofs INTO TABLE lt_ust10c.
**              SORT gt_ust10c.
**              DELETE ADJACENT DUPLICATES FROM gt_ust10c.
*            ENDIF.
*          ENDLOOP.
*          gt_ust10c[] = lt_ust10c[].
*          SORT gt_ust10c.
*          DELETE ADJACENT DUPLICATES FROM gt_ust10c.
*          free lt_ust10c[].
*          LOOP AT lt_subprofs ASSIGNING <subp>.
*            ls_prof-profile = <subp>-subprof.
*            APPEND ls_prof TO lt_profiles.
*          ENDLOOP.
*
*          LOOP AT lt_profiles ASSIGNING <prof>.
*            READ TABLE gt_ust10s WITH KEY profn = <prof>-profile
*            BINARY SEARCH TRANSPORTING NO FIELDS.
*            IF sy-subrc = 0.
*              LOOP AT gt_ust10s FROM sy-tabix ASSIGNING <auth> WHERE
*                profn = <prof>-profile AND
*                objct IN lt_range_object.
*                APPEND <auth> TO lt_auths.
*              ENDLOOP.
*            ELSE.
*              DATA : lt_auths_tmp TYPE TABLE OF ust10s.
*              REFRESH : lt_auths_tmp[].
*              SELECT profn auth objct FROM ust10s INTO
*              CORRESPONDING FIELDS OF
*              TABLE lt_auths_tmp
*                     WHERE
*                     profn  = <prof>-profile
**--DHORIONS 20101222 - Added AKTPS restriction, Case 1672
*
*                     AND
*                     aktps = 'A'
*                     AND
*                     objct IN lt_range_object.
**--buffer ust10s data
*              INSERT LINES OF lt_auths_tmp INTO TABLE gt_ust10s.
*              APPEND LINES OF lt_auths_tmp TO lt_auths.
*
*            ENDIF.
*          ENDLOOP.
*          LOOP AT lt_auths ASSIGNING <auth>.
*            lt_unique_userauths-auth = <auth>-auth.
*            APPEND lt_unique_userauths.
*          ENDLOOP.
*          FREE :  lt_auths,lt_subprofs, lt_profiles.
*        ENDIF.
*      ENDIF.
*
*    ENDLOOP.
*    FREE : lt_usr02_part.
*
*    SORT lt_unique_userauths.
*    DELETE ADJACENT DUPLICATES FROM lt_unique_userauths.
*
*
*    APPEND LINES OF lt_unique_userauths TO lt_unique_userauths_all.
*    SORT lt_unique_userauths_all.
*    DELETE ADJACENT DUPLICATES FROM lt_unique_userauths_all.
*  ENDWHILE.
*  gt_unique_userauths[] = lt_unique_userauths_all[].
*
*  FREE : lt_usr02, lt_usr02_part, lt_unique_userauths, lt_range_object,
*  lt_unique_userauths_all.
*
*
*  DESCRIBE TABLE gt_unique_userauths LINES l_unique_auths.
*  l_unique_auths_c = l_unique_auths.
*  MESSAGE s113(/psyng/sw) WITH
*  'Unique authorizations loaded : '(022)
*  l_unique_auths_c.
*
*  IF l_unbuffered_users > 0.
*    l_unbuffered_users_c = l_unbuffered_users.
*    MESSAGE s113(/psyng/sw) WITH
*    'Users not in user buffer : '(020)
*    l_unbuffered_users_c.
*  ENDIF.
*  COMMIT WORK.
*
*ENDFORM.                    " get_unique_user_auths
*&---------------------------------------------------------------------*
*&      Form  report_roles_without_cauth
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM report_roles_without_cauth.
  DATA : lt_noca_roles LIKE TABLE OF gt_routput,
         l_date(12) TYPE c.
  WRITE sy-datum TO l_date.
  LOOP AT gt_roles.
    READ TABLE gt_routput WITH KEY agr_name = gt_roles-agr_name
    BINARY SEARCH.
    IF sy-subrc <> 0.
      CLEAR gt_routput.
      CONCATENATE sy-sysid sy-mandt INTO gt_routput-rfcdest.
      gt_routput-agr_name = gt_roles-agr_name.
      gt_routput-swaudid  = '----'.
      CONCATENATE
'No Critical authorizations based on SOD matrix'(n01)
'defined in Security Weaver on'(n02)
l_date
INTO gt_routput-description SEPARATED BY space.
      APPEND gt_routput TO lt_noca_roles.
    ENDIF.
  ENDLOOP.
  APPEND LINES OF lt_noca_roles TO gt_routput.
  SORT gt_routput.
ENDFORM.                    " report_roles_without_cauth
*&---------------------------------------------------------------------*
*&      Form  get_composite_roles_ca_usr
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM get_composite_roles_ca_usr.
*  DATA: BEGIN OF lt_comp_agr OCCURS 0,
*          agr_name TYPE agr_name,
*          comp_agr TYPE /psyng/agr_name_c,
*        END OF lt_comp_agr,
*        l_system_msg(80) TYPE c,
*        l_tabix LIKE sy-tabix.
*  RANGES : gr_role FOR agr_agrs-child_agr.
*  DATA : lt_comp_agr_part TYPE TABLE OF /psyng/agr_comp_child.
*  DATA : lt_assigned TYPE TABLE OF agr_users WITH HEADER LINE,
*         lt_assigned_part TYPE TABLE OF agr_users,
*        lt_users     TYPE TABLE OF usr02.
*  FIELD-SYMBOLS : <out> LIKE LINE OF gt_outputdet.
*
*  CHECK NOT gt_usr02[] IS INITIAL.
*  lt_users[] = gt_usr02[].
*  FREE gr_role.
*  gr_role-sign   = 'I'.
*  gr_role-option = 'EQ'.
*  LOOP AT gt_outputdet ASSIGNING <out> .
*    gr_role-low = <out>-child_agr.
*    COLLECT gr_role.
*  ENDLOOP.
*  CALL FUNCTION '/PSYNG/SW_084'
*       EXPORTING
*            i_include_users = 'X'
*       TABLES
*            it_singleroles  = gr_role
*            it_users        = lt_users
*            et_comp_child   = lt_comp_agr_part
*            et_agr_users    = lt_assigned_part.
*  FREE : lt_comp_agr, lt_assigned.
*  APPEND LINES OF lt_comp_agr_part TO lt_comp_agr.
*  APPEND LINES OF lt_assigned_part TO lt_assigned.
*  FREE : lt_comp_agr_part, lt_assigned_part.
*  SORT lt_comp_agr.
*  DELETE ADJACENT DUPLICATES FROM lt_comp_agr.
*  SORT lt_assigned BY agr_name uname.
*
*  LOOP AT gt_outputdet ASSIGNING <out>.
*    LOOP AT lt_comp_agr WHERE agr_name = <out>-child_agr.
*      READ TABLE lt_assigned WITH KEY agr_name = lt_comp_agr-comp_agr
*                                   uname    = <out>-bname.
*      IF sy-subrc = 0.
*        <out>-comp_agr = lt_comp_agr-comp_agr.
*        EXIT.
*      ENDIF.
*    ENDLOOP.
*  ENDLOOP.
*
*ENDFORM.                    " get_composite_roles_ca_usr
*&---------------------------------------------------------------------*
*&      Form  validate_simulated_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SIMU_ROLE_RFC  text
*----------------------------------------------------------------------*
*FORM validate_simulated_roles
*      TABLES
*        it_simu_role_rfc STRUCTURE /psyng/sw_sod_remote_roles
*        et_return        STRUCTURE bapiret2.
*  DATA : l_rfcdest TYPE rfcdes-rfcdest,
*         l_tabname  TYPE dd02l-tabname.
*  FIELD-SYMBOLS : <simu> TYPE /psyng/sw_sod_remote_roles.
*  LOOP AT it_simu_role_rfc ASSIGNING <simu> WHERE rfcdest <> 'LOCAL'.
*    SELECT SINGLE rfcdest INTO l_rfcdest FROM rfcdes
*           WHERE rfcdest = <simu>-rfcdest.
*    IF sy-subrc NE 0.
*      et_return-type    = 'W'.
*      et_return-id      = '/PSYNG/SW'.
*      et_return-number  = '016'.
*      MESSAGE w016(/psyng/sw) INTO et_return-message.
*      COLLECT et_return.
*      DELETE it_simu_role_rfc WHERE
*        rfcdest = <simu>-rfcdest AND
*        agr_name = <simu>-agr_name.
*    ENDIF.
*  ENDLOOP.
*ENDFORM.                    " validate_simulated_roles
*&---------------------------------------------------------------------*
*&      Form  include_er_roles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SIMU_ROLE_RFC  text
*----------------------------------------------------------------------*
*FORM include_er_roles
*      TABLES
*       it_users     STRUCTURE /psyng/sw_sel_opts_xubname
*       it_usergroup STRUCTURE  /psyng/range_class
*      USING
*        i_er_roles    TYPE flag
*        i_validuser   TYPE flag.
*  DATA : l_tabname  TYPE dd02l-tabname,
*         l_lines TYPE i.
*  CHECK i_er_roles = 'X'.
**--Include ER-ROLES
*  l_tabname = '/PSYNG/ER_MAIN'.
*  SELECT SINGLE tabname INTO l_tabname FROM dd02l    "#EC CI_IMUD_NESTED
*                WHERE tabname  = l_tabname
*                  AND as4local = 'A'.
*  IF sy-subrc = 0.
*    DESCRIBE TABLE it_users LINES l_lines.
*    IF l_lines LE 100.
*      SELECT bname AS uname agr_name  "#EC CI_IMUD_NESTED
*      FROM (l_tabname)
*      INTO CORRESPONDING FIELDS OF TABLE gt_er_roles
*      WHERE bname IN it_users AND
*      fr_date <= sy-datum AND
*      to_date >= sy-datum.
*    ELSE.
*      SELECT bname AS uname agr_name    "#EC CI_IMUD_NESTED
*      FROM (l_tabname)
*      INTO CORRESPONDING FIELDS OF TABLE gt_er_roles
*      WHERE
*      fr_date <= sy-datum AND
*      to_date >= sy-datum.
*    ENDIF.
**Get the er roles for the selected users into a global table.
**gt_er_roles
*  ENDIF.
*
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_unique_simu_role_data
*&---------------------------------------------------------------------*
* Add unique authorizations of simulated roles to global table
*----------------------------------------------------------------------*
*      -->P_IT_SIMU_ROLE_RFC  text
*----------------------------------------------------------------------*
*FORM get_unique_simu_role_data
*TABLES   simu_role_rfc STRUCTURE /psyng/sw_sod_remote_roles
*USING i_er_roles TYPE flag
*.
*  DATA :
*  lt_roletcode    TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
*  lt_roleauth     TYPE TABLE OF /psyng/userauth  WITH HEADER LINE,
*  lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
*  lt_faobj        TYPE TABLE OF /psyng/faobj2    WITH HEADER LINE,
*  lt_userauths    LIKE TABLE OF usrbf2 WITH HEADER LINE,
*  l_idx           LIKE sy-tabix,
*  l_rfcdest       TYPE rfcdest.
*  FIELD-SYMBOLS : <swaudhdr> LIKE /psyng/swaudhdr,
*                  <swaudc>   LIKE /psyng/swaudc2,
*                  <usr02>    LIKE usr02.
*  IF NOT simu_role_rfc[] IS INITIAL OR i_er_roles = 'X'.
*    LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
*      MOVE-CORRESPONDING <swaudhdr> TO lt_functtran.
*      lt_functtran-functionid = <swaudhdr>-swaudid.
*      APPEND lt_functtran.
*      LOOP AT gt_swaudc ASSIGNING <swaudc>
*           FROM l_idx WHERE swaudid = <swaudhdr>-swaudid.
*        l_idx = sy-tabix.
*        MOVE-CORRESPONDING <swaudc> TO lt_faobj.
*        lt_faobj-funid = <swaudhdr>-swaudid.
*        APPEND lt_faobj.
*      ENDLOOP.
*    ENDLOOP.
*  DATA : lt_simu_role_rfc TYPE TABLE OF /psyng/sw_sod_remote_roles WITH
*    HEADER LINE.
*    lt_simu_role_rfc[] = simu_role_rfc[].
**--Add Er Roles
*    IF i_er_roles = 'X'.
*      LOOP AT gt_er_roles.
*        lt_simu_role_rfc-rfcdest  = 'LOCAL'.
*        lt_simu_role_rfc-agr_name = gt_er_roles-agr_name.
*        APPEND lt_simu_role_rfc.
*      ENDLOOP.
*      SORT lt_simu_role_rfc.
*      DELETE ADJACENT DUPLICATES FROM lt_simu_role_rfc.
*    ENDIF.
*
*    LOOP AT lt_simu_role_rfc.
*      IF lt_simu_role_rfc-rfcdest = 'LOCAL'.
*        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*             EXPORTING
*                  agr_name  = lt_simu_role_rfc-agr_name
*                  bname     = '000000000000'
*             TABLES
*                  roleauth  = lt_roleauth
**                  roletcode = lt_roletcode
**                  roleprof  = lt_roleprof
*                  functtran = lt_functtran
*                  faobj     = lt_faobj
*             EXCEPTIONS
*                  role_not_found = 1
*                  OTHERS         = 2.
*      ELSE.
*        CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*
*        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*             EXPORTING
*                  agr_name  = lt_simu_role_rfc-agr_name
*                  bname     = '000000000000'
*                  rem_execution = 'X'
*                  rfcdest       = l_rfcdest
*
*             TABLES
*                  roleauth  = lt_roleauth
*                  functtran = lt_functtran
*                  faobj     = lt_faobj
*             EXCEPTIONS
*                  role_not_found = 1
*                  OTHERS         = 2.
*
*      ENDIF.
*      LOOP AT lt_roleauth.
*        lt_userauths-auth   = lt_roleauth-auth.
*        APPEND lt_userauths.
*      ENDLOOP.
*    ENDLOOP.
*    SORT lt_userauths.
*    DELETE ADJACENT DUPLICATES FROM lt_userauths.
*    LOOP AT lt_userauths.
*      INSERT lt_userauths INTO TABLE gt_unique_userauths.
*    ENDLOOP.
*  ENDIF.
*ENDFORM.                    " get_unique_simu_role_data
*&---------------------------------------------------------------------*
*&      Form  get_simu_role_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_IT_SIMU_ROLE_RFC  text
*----------------------------------------------------------------------*
*FORM get_simu_role_data
*TABLES
*simu_role_rfc STRUCTURE /psyng/sw_sod_remote_roles
*USING i_er_roles TYPE flag.
*  DATA :
*  lt_roletcode    TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
*  lt_roleauth     TYPE TABLE OF /psyng/userauth  WITH HEADER LINE,
*  lt_functtran    TYPE TABLE OF /psyng/functtran WITH HEADER LINE,
*  lt_faobj        TYPE TABLE OF /psyng/faobj2    WITH HEADER LINE,
*  lt_userauths    LIKE TABLE OF usrbf2 WITH HEADER LINE,
*  l_idx           LIKE sy-tabix,
*  l_rfcdest       TYPE rfcdest,
*  ls_user_auth    LIKE LINE OF gt_user_auth.
*  FIELD-SYMBOLS : <swaudhdr> LIKE /psyng/swaudhdr,
*                  <swaudc>   LIKE /psyng/swaudc2,
*                  <usr02>    LIKE usr02.
*  IF NOT simu_role_rfc[] IS INITIAL OR i_er_roles = 'X'.
*    LOOP AT gt_swaudhdr ASSIGNING <swaudhdr>.
*      MOVE-CORRESPONDING <swaudhdr> TO lt_functtran.
*      lt_functtran-functionid = <swaudhdr>-swaudid.
*      APPEND lt_functtran.
*      LOOP AT gt_swaudc ASSIGNING <swaudc>
*           FROM l_idx WHERE swaudid = <swaudhdr>-swaudid.
*        l_idx = sy-tabix.
*        MOVE-CORRESPONDING <swaudc> TO lt_faobj.
*        lt_faobj-funid = <swaudhdr>-swaudid.
*        APPEND lt_faobj.
*      ENDLOOP.
*    ENDLOOP.
*  ENDIF.
*  LOOP AT simu_role_rfc.
*    IF simu_role_rfc-rfcdest = 'LOCAL'.
*      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*           EXPORTING
*                agr_name  = simu_role_rfc-agr_name
*                bname     = '000000000000'
*           TABLES
*                roleauth  = lt_roleauth
*                roletcode = lt_roletcode
*                functtran = lt_functtran
*                faobj     = lt_faobj
*           EXCEPTIONS
*                role_not_found = 1
*                OTHERS         = 2.
*    ELSE.
*      CONCATENATE sy-sysid sy-mandt INTO l_rfcdest.
*
*      CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*           EXPORTING
*                agr_name  = simu_role_rfc-agr_name
*                bname     = '000000000000'
*                rem_execution = 'X'
*                rfcdest       = l_rfcdest
*
*           TABLES
*                roleauth  = lt_roleauth
*                roletcode = lt_roletcode
*                functtran = lt_functtran
*                faobj     = lt_faobj
*           EXCEPTIONS
*                role_not_found = 1
*                OTHERS         = 2.
*
*    ENDIF.
*    SORT lt_roletcode BY tcode.
*    DELETE ADJACENT DUPLICATES FROM lt_roletcode COMPARING tcode.
*    ls_user_auth-simu   = 'X'.
*    gt_usertcode-simu   = 'X'.
*    LOOP AT gt_usr02 ASSIGNING <usr02>.
*      gt_usertcode-bname = <usr02>-bname.
*      ls_user_auth-bname = <usr02>-bname.
*
*
*      LOOP  AT lt_roletcode.
*        gt_usertcode-tcode = lt_roletcode-tcode.
*        INSERT TABLE gt_usertcode.
*      ENDLOOP.
*      LOOP  AT lt_roleauth.
*        ls_user_auth-objct  = lt_roleauth-objct.
*        ls_user_auth-auth   = lt_roleauth-auth.
*        ls_user_auth-field  = lt_roleauth-field.
*        ls_user_auth-von    = lt_roleauth-von.
*        ls_user_auth-bis    = lt_roleauth-bis.
*        INSERT ls_user_auth INTO TABLE gt_user_auth.
*      ENDLOOP.
*    ENDLOOP.
*  ENDLOOP.
**handle ER Roles
*  IF i_er_roles = 'X'.
*    CLEAR : ls_user_auth, gt_usertcode.
*    ls_user_auth-er   = 'X'.
*    gt_usertcode-er   = 'X'.
*
*    LOOP AT gt_usr02 ASSIGNING <usr02>.
*      gt_usertcode-bname = <usr02>-bname.
*      ls_user_auth-bname = <usr02>-bname.
*      LOOP AT gt_er_roles WHERE uname = <usr02>-bname.
*        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
*             EXPORTING
*                  agr_name  = gt_er_roles-agr_name
*                  bname     = '000000000000'
*             TABLES
*                  roleauth  = lt_roleauth
*                  roletcode = lt_roletcode
*                  functtran = lt_functtran
*                  faobj     = lt_faobj
*             EXCEPTIONS
*                  role_not_found = 1
*                  OTHERS         = 2.
*        LOOP  AT lt_roletcode.
*          gt_usertcode-tcode = lt_roletcode-tcode.
*          INSERT TABLE gt_usertcode.
*        ENDLOOP.
*        LOOP  AT lt_roleauth.
*          ls_user_auth-objct  = lt_roleauth-objct.
*          ls_user_auth-auth   = lt_roleauth-auth.
*          ls_user_auth-field  = lt_roleauth-field.
*          ls_user_auth-von    = lt_roleauth-von.
*          ls_user_auth-bis    = lt_roleauth-bis.
*          INSERT ls_user_auth INTO TABLE gt_user_auth.
*        ENDLOOP.
*      ENDLOOP.
*    ENDLOOP.
*  ENDIF.
*ENDFORM.                    " get_simu_role_data

*---------------------------------------------------------------------*
*       FORM load_local_swauds                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  LT_CONFLICT                                                   *
*  -->  LT_FUNCTTRAN                                                  *
*  -->  LT_FAOBJ                                                      *
*  -->  LT_CONFDET                                                    *
*  -->  LT_LOCAL_SWAUDHDR                                             *
*  -->  LT_LOCAL_SCWAUDC                                              *
*  -->  LT_ENH_TCODES                                                 *
*  -->  IT_SWAUDID                                                    *
*  -->  I_VRSIO                                                       *
*  -->  I_ENHANC                                                      *
*---------------------------------------------------------------------*
FORM load_local_swauds TABLES
    lt_conflict  STRUCTURE /psyng/conflict
    lt_functtran STRUCTURE /psyng/functtran
    lt_faobj     STRUCTURE /psyng/faobj2
    lt_confdet   STRUCTURE /psyng/confdet
    lt_local_swaudhdr STRUCTURE /psyng/swaudhdr
    lt_local_scwaudc  STRUCTURE /psyng/swaudc2
    lt_enh_tcodes STRUCTURE /psyng/sw_par_tcode_output
    it_swaudid   STRUCTURE /psyng/range_swaudid
    USING
    i_vrsio TYPE /psyng/sodvrsio
    i_enhanc TYPE flag.
  SELECT * FROM /psyng/swaudhdr
            INTO TABLE lt_local_swaudhdr
            WHERE swaudid IN it_swaudid AND
                  vrsio = i_vrsio.

  SORT : lt_local_swaudhdr.
  IF NOT lt_local_swaudhdr[] IS INITIAL.
    SELECT * FROM /psyng/swaudc2
     INTO  TABLE lt_local_scwaudc
     FOR ALL ENTRIES IN lt_local_swaudhdr
     WHERE vrsio = i_vrsio
     AND swaudid = lt_local_swaudhdr-swaudid
     AND tcode   = lt_local_swaudhdr-tcode
     AND field <> ''. "ignore blank fields
  ENDIF.

*Convert to functions
  DATA : l_placeholder_counter TYPE numc5.
  LOOP AT lt_local_swaudhdr.
    lt_conflict-conid       = lt_local_swaudhdr-swaudid.
    APPEND lt_conflict.
    lt_confdet-conid        = lt_local_swaudhdr-swaudid.
    lt_confdet-functionid   = lt_local_swaudhdr-swaudid.
    APPEND lt_confdet.
    lt_functtran-functionid = lt_local_swaudhdr-swaudid.
    IF lt_local_swaudhdr-tcode = '*'.
      ADD 1 TO l_placeholder_counter.
      CONCATENATE '/PSYNG/-SWAUD' l_placeholder_counter
      INTO lt_functtran-tcode.
    ELSE.
      lt_functtran-tcode    = lt_local_swaudhdr-tcode.
    ENDIF.
    lt_functtran-vrsio    = lt_local_swaudhdr-vrsio.

    APPEND lt_functtran.
    LOOP AT lt_local_scwaudc WHERE swaudid = lt_local_swaudhdr-swaudid.
      MOVE-CORRESPONDING lt_local_scwaudc TO lt_faobj.
      lt_faobj-funid = lt_functtran-functionid.
      lt_faobj-tcode = lt_functtran-tcode.
      APPEND lt_faobj.
    ENDLOOP.
  ENDLOOP.
  CHECK i_enhanc = 'X'.
*Tcode enhancement
  CALL FUNCTION '/PSYNG/SW_065'
       EXPORTING
            i_vrsio      = i_vrsio
       TABLES
            it_functtran = lt_functtran
            it_faobj     = lt_faobj
            et_tcodes    = lt_enh_tcodes.


ENDFORM.                    " load_local_swauds
*---------------------------------------------------------------------*
*       FORM load_simulated_role_content                              *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_SIMU_ROLE_ADDITION                                         *
*  -->  ET_SIMU_ROLEAUTH                                              *
*  -->  ET_SIMU_ROLETCODE                                             *
*  -->  IT_FUNCTRAN_LOCAL                                             *
*  -->  IT_FAOBJ_LOCAL                                                *
*  -->  IT_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_simulated_role_content
TABLES   it_simu_role_addition STRUCTURE /psyng/sw_role_addition_simu
         et_simu_roleauth STRUCTURE /psyng/roleauth
         et_simu_roletcode STRUCTURE /psyng/roletcode
         it_functran_local STRUCTURE /psyng/functtran
         it_faobj_local STRUCTURE /psyng/faobj2
         it_rfcdes STRUCTURE rfcdes.
  DATA : lt_unique_rfcs TYPE TABLE OF /psyng/sw_role_addition_simu WITH
  HEADER LINE,
  l_agr_name TYPE agr_name,
  lt_role_names TYPE TABLE OF agr_define WITH HEADER LINE,
  lt_faobj TYPE TABLE OF /psyng/faobj2,
  lt_functtran TYPE TABLE OF /psyng/functtran,
  lt_roleauth TYPE TABLE OF /psyng/userauth WITH HEADER LINE,
  lt_roletcode TYPE TABLE OF /psyng/usertcode WITH HEADER LINE,
  l_rfcdes TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_rfcdes.
  RANGES : range_roles FOR l_agr_name.
  lt_unique_rfcs[] = it_simu_role_addition[].
  SORT lt_unique_rfcs BY source_rfcdest.
DELETE ADJACENT DUPLICATES FROM lt_unique_rfcs COMPARING source_rfcdest.


  LOOP AT lt_unique_rfcs.
    REFRESH : range_roles.
    LOOP AT it_simu_role_addition
    WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
      MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
      APPEND range_roles.
    ENDLOOP.
    IF lt_unique_rfcs-source_rfcdest IS INITIAL OR
       lt_unique_rfcs-source_rfcdest = 'LOCAL'.
*--Get list of roles matching range
      CALL FUNCTION '/PSYNG/SW_102'
           TABLES
                it_roles_range = range_roles
                et_roles       = lt_role_names.
      LOOP AT lt_role_names.
*--Load local role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
        REFRESH : lt_roleauth,lt_roletcode.
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
             EXPORTING
                  agr_name       = lt_role_names-agr_name
                  bname          = '000000000000'
             TABLES
                  roleauth       = lt_roleauth
                  roletcode      = lt_roletcode
                  functtran      = lt_functtran
                  faobj          = lt_faobj
             EXCEPTIONS
                  role_not_found = 1
                  OTHERS         = 2. "#EC SAST_CI_GEN_CHECK
"(++)BOC UMITTAL SE VF scan-25/11/2024
  IF sy-subrc <> 0.
            MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
   ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

*--Update the destination RFCDEST
        LOOP AT it_simu_role_addition
        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
          REFRESH : range_roles.
          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
          APPEND range_roles.
          READ TABLE it_rfcdes
          WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
          IF sy-subrc <> 0 AND
          (
            it_simu_role_addition-target_rfcdest = 'LOCAL' OR
            it_simu_role_addition-target_rfcdest = l_rfcdes ).
            it_rfcdes-rfcoptions = l_rfcdes.
          ENDIF.
          lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
          lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
          MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE agr_name <> ''.
          MODIFY lt_roletcode TRANSPORTING rfcdest WHERE agr_name <> ''.
        ENDLOOP.
        MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
        APPEND et_simu_roleauth.
        REFRESH lt_roleauth.
        MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
        APPEND et_simu_roletcode.
        REFRESH lt_roletcode.

      ENDLOOP.
    ELSE.
*--Get list of roles matching range
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
      CALL FUNCTION '/PSYNG/SW_102'
        DESTINATION lt_unique_rfcs-source_rfcdest
        TABLES
          it_roles_range       = range_roles
          et_roles             = lt_role_names."#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
      LOOP AT lt_role_names.
*--Load remote role content
        lt_faobj[] = it_faobj_local[].
        lt_functtran[] = it_functran_local[].
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
        CALL FUNCTION '/PSYNG/SW_GET_SIMU_ROLE_DATA'
        DESTINATION lt_unique_rfcs-source_rfcdest
           EXPORTING
                agr_name  = lt_role_names-agr_name
                bname     = '000000000000'
           TABLES
                roleauth  = lt_roleauth
                roletcode = lt_roletcode
                functtran = lt_functtran
                faobj     = lt_faobj
           EXCEPTIONS
                role_not_found = 1
                OTHERS         = 2. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024
*--Update the destination RFCDEST
        LOOP AT it_simu_role_addition
        WHERE source_rfcdest = lt_unique_rfcs-source_rfcdest.
          REFRESH : range_roles.
          MOVE-CORRESPONDING it_simu_role_addition TO range_roles.
          APPEND range_roles.
          READ TABLE it_rfcdes
          WITH KEY rfcdest = it_simu_role_addition-target_rfcdest.
          IF sy-subrc <> 0 AND
          (
            it_simu_role_addition-target_rfcdest = 'LOCAL' OR
            it_simu_role_addition-target_rfcdest = l_rfcdes ).
            it_rfcdes-rfcoptions = l_rfcdes.
          ENDIF.

          lt_roleauth-rfcdest = it_rfcdes-rfcoptions.
          lt_roletcode-rfcdest = it_rfcdes-rfcoptions.
          MODIFY  lt_roleauth TRANSPORTING rfcdest WHERE
          agr_name IN range_roles  .
          MODIFY lt_roletcode TRANSPORTING rfcdest WHERE
          agr_name IN range_roles.
        ENDLOOP.

        LOOP AT lt_roleauth.
          MOVE-CORRESPONDING lt_roleauth TO et_simu_roleauth.
          APPEND et_simu_roleauth.
        ENDLOOP.

        REFRESH lt_roleauth.
        LOOP AT lt_roletcode.
          MOVE-CORRESPONDING lt_roletcode TO et_simu_roletcode.
          APPEND et_simu_roletcode.
        ENDLOOP.
        REFRESH lt_roletcode.
      ENDLOOP.

    ENDIF.
  ENDLOOP.

ENDFORM.                    " load_simulated_role_content
*---------------------------------------------------------------------*
*       FORM load_rfc                                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IT_RFC                                                        *
*  -->  ET_RFCDES                                                     *
*---------------------------------------------------------------------*
FORM load_rfc
    TABLES
      it_rfc STRUCTURE /psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.
  .
  DATA : l_rfcdest TYPE rfcdes-rfcdest,
         l_system_msg(80) TYPE c,
         l_local_sys TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

  IF NOT it_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_rfc.
  ENDIF.
*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
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
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e02
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--DHORIONS 2011/01/20 : Delete any RFC pointing to the local system.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  et_rfcdes WHERE rfcoptions = l_local_sys
  AND rfcdest <> 'LOCAL'.
*Case 2061 - If 2 rfc destinations point to the same system-client,
*            we still only output the results once.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.

ENDFORM.                    " validate_user_rfc


*---------------------------------------------------------------------*
*       FORM get_remote_results                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_remote_results USING taskname.
  DATA : lt_routput_sum   TYPE TABLE OF /psyng/sw_out_routput
          WITH HEADER LINE,
         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
         WITH HEADER LINE,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_036'

     IMPORTING
       o_totalroles         = l_numroles
         TABLES
       ot_routput_sum       = lt_routput_sum
       et_removed_roles     = lt_removed_roles
      EXCEPTIONS
            communication_failure = 1 MESSAGE l_system_msg
            system_failure        = 2 MESSAGE l_system_msg
            OTHERS                = 3.
  IF sy-subrc = 0.
    gt_fm_output-rfcdest = taskname.
    LOOP AT lt_routput_sum.

      gt_fm_output-swaudid  = lt_routput_sum-conid.
      gt_fm_output-agr_name = lt_routput_sum-agr_name.
      gt_fm_output-agr_text = lt_routput_sum-agr_text.
      gt_fm_output-simu     = lt_routput_sum-simu.
      APPEND gt_fm_output.
    ENDLOOP.

  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg
        INTO gt_return-message.
        COLLECT gt_return.
      WHEN 3.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        INTO gt_return-message.
        COLLECT gt_return.
    ENDCASE.

  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_remote_results_det                                   *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  TASKNAME                                                      *
*---------------------------------------------------------------------*
FORM get_remote_results_det USING taskname.
  DATA : lt_outputdet   TYPE TABLE OF /psyng/sw_out_routdet3
         WITH HEADER LINE,
         lt_removed_roles TYPE TABLE OF /psyng/sw_removed_roles_role
         WITH HEADER LINE,
         l_system_msg(80) TYPE c,
         l_numroles TYPE i.
  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_083'
     IMPORTING
       e_rolecount         = l_numroles
     TABLES
       et_outputdet        = lt_outputdet
     EXCEPTIONS
       communication_failure = 1 MESSAGE l_system_msg
       system_failure        = 2 MESSAGE l_system_msg
       OTHERS                = 3.
  IF sy-subrc = 0.
    gt_fm_outputdet-rfcdest = taskname.
    LOOP AT  lt_outputdet.
      gt_fm_outputdet-swaudid = lt_outputdet-conid.
      MOVE-CORRESPONDING lt_outputdet TO gt_fm_outputdet.
      APPEND gt_fm_outputdet.
    ENDLOOP.

  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.
        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg
        INTO gt_return-message.
        COLLECT gt_return.
      WHEN 3.
        gt_return-type    = 'W'.
        gt_return-id      = '00'.
        gt_return-number  = '398'.

        MESSAGE e398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        INTO gt_return-message.
        COLLECT gt_return.
    ENDCASE.
  ENDIF.
  SUBTRACT 1 FROM g_running_tasks.

ENDFORM.

*---------------------------------------------------------------------*
*       FORM get_role_text                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  I_AGR_NAME                                                    *
*  -->  E_AGR_TEXT                                                    *
*---------------------------------------------------------------------*
*FORM get_role_text USING    i_agr_name TYPE agr_name
*                   CHANGING e_agr_text TYPE agr_title.
*
*  TYPES: BEGIN OF t_role,
*           agr_name TYPE agr_name,
*           agr_text TYPE agr_title,
*         END OF t_role.
*
*  STATICS: lt_role TYPE HASHED TABLE OF t_role WITH UNIQUE KEY agr_name.
*
*  DATA: ls_role TYPE t_role.
*
*
*  READ TABLE lt_role INTO ls_role WITH TABLE KEY agr_name = i_agr_name.
*  IF sy-subrc = 0.
*    e_agr_text = ls_role-agr_text.
*    EXIT.
*  ENDIF.
*
*  SELECT SINGLE text INTO e_agr_text FROM agr_texts
*                WHERE agr_name = i_agr_name
*                  AND spras    = sy-langu
*                  AND line     = 0.
*  CHECK sy-subrc = 0.
*
*  ls_role-agr_name = i_agr_name.
*  ls_role-agr_text = e_agr_text.
*  INSERT ls_role INTO TABLE lt_role.
*ENDFORM.                    " get_role_text
