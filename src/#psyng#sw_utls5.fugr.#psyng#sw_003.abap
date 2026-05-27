*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_003
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
FUNCTION /psyng/sw_003.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(ROLE) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(CRIAUTH_RFC) LIKE  RFCDES-RFCDEST OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_DETAILS) TYPE  FLAG OPTIONAL
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRETURN STRUCTURE  BAPIRETURN
*"  TABLES
*"      OUTPUT STRUCTURE  /PSYNG/OUTPUT OPTIONAL
*"      OUTPUTDET STRUCTURE  /PSYNG/SW_CA_ROUTPUTDET OPTIONAL
*"  EXCEPTIONS
*"      INVALID_CRI_AUTH_RFC
*"      NO_AUTH_TO_READ_ALL_CRI_AUTH
*"----------------------------------------------------------------------

*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_003'.
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


  DATA: dest LIKE rfcdes-rfcdest.
  DATA : ls_outputdet TYPE /psyng/sw_ca_outputdet,
         ls_routputdet TYPE /psyng/sw_ca_routputdet,
         ls_output TYPE /psyng/output.
  gf_details = i_details.

  CONCATENATE sy-sysid sy-mandt INTO dest.
  PERFORM refresh_internal_tables.

  IF criauth_rfc IS INITIAL.  "get local cri auths

    CALL FUNCTION '/PSYNG/SW_READ_ALL_CA_DETAILS'
         EXPORTING
              vrsio                      = vrsio
         TABLES
              swaudc_fm                  = iswaudc
         EXCEPTIONS
              not_authorized_to_read_all = 1
              OTHERS                     = 2.

    CASE sy-subrc.
      WHEN 1.
        RAISE no_auth_to_read_all_cri_auth.
      WHEN 2.
      WHEN OTHERS.
    ENDCASE.

  ELSE.   " get remote cri auths

    SELECT SINGLE rfcdest FROM rfcdes INTO rfcdes
           WHERE rfcdest = criauth_rfc AND rfctype = '3'.
    IF sy-subrc NE 0.
      RAISE invalid_cri_auth_rfc.
    ENDIF.
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
    CALL FUNCTION '/PSYNG/SW_READ_ALL_CA_DETAILS'
      DESTINATION criauth_rfc
      EXPORTING
          vrsio                      = vrsio
      TABLES
         swaudc_fm       = iswaudc
      EXCEPTIONS
        not_authorized_to_read_all       = 1
        SYSTEM_FAILURE = 2
        COMMUNICATION_FAILURE = 3
        OTHERS           = 4."#EC SAST_CI_GEN_CHECK

*-----------------BOC AGARG 08/08/2025------------------------*
  IF sy-subrc NE 0.
    CASE sy-subrc.
      WHEN 1.
        RAISE no_auth_to_read_all_cri_auth.
      WHEN 2.
         MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
       WHEN 3.
         MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
    ENDCASE.
  ENDIF.
ENDIF.
*-----------------EOC AGARG 08/08/2025------------------------*
  LOOP AT iswaudc.
    audcobjs-objct = iswaudc-object.
    APPEND audcobjs.
    CHECK iswaudc-tcode NE '*'.
    atcodes-tcode = iswaudc-tcode.
    APPEND atcodes.
  ENDLOOP.
  SORT: audcobjs, atcodes.
  DELETE ADJACENT DUPLICATES FROM audcobjs.
  DELETE ADJACENT DUPLICATES FROM atcodes.
  if not audcobjs[] is initial.
    SELECT profn objct auth FROM ust10s
         INTO CORRESPONDING FIELDS OF TABLE iust10s
         FOR ALL ENTRIES IN audcobjs WHERE objct = audcobjs-objct
         AND aktps = 'A'.
  endif.
  REFRESH: audcobjs.

  SELECT profile FROM agr_1016
       INTO profiles-profn
       WHERE agr_name = role.
    APPEND profiles.
  ENDSELECT.
  IF sy-subrc NE 0.
    SELECT * FROM agr_agrs WHERE agr_name = role
    AND attributes <> 'X'.
      SELECT profile FROM agr_1016
*      SELECT profile FROM agr_prof
             INTO profiles-profn
             WHERE agr_name = agr_agrs-child_agr.
        APPEND profiles.
      ENDSELECT.
    ENDSELECT.
  ENDIF.

  CHECK NOT profiles[] IS INITIAL.

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

  iusr02-bname = '000000000000'.
  APPEND iusr02.

  LOOP AT profiles.
    userprof-profile = profiles-profn.
    userprof-bname = iusr02-bname.   "   '000000000000'
    userprof-rfcdest = dest.
    APPEND userprof.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/SW_USER_CRI_AUTH_DATA'
       TABLES
            usertcode = usertcode
            userprof  = userprof
            userauth  = userauth
            iust12    = iust12
            swaudc    = iswaudc
            iusr02    = iusr02.

*  PERFORM fill_cri_usertcode
*            USING iusr02-bname dest.
*
*  PERFORM fill_cri_userauth
*          TABLES iust12 USING iusr02-bname dest.

* Get auths for tcodes that are critical
  CALL FUNCTION '/PSYNG/SW_GET_CRIT_AUTH_DATA'
       TABLES
            tcdaut = tcdaut
            iust12 = iust12
            swaudc = iswaudc.

  LOOP AT userauth.
    MOVE-CORRESPONDING userauth TO iuserauth.
    APPEND iuserauth.
    DELETE userauth.
  ENDLOOP.
  REFRESH userauth.  CLEAR userauth.

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

* if gf_details is initial.
*  MODIFY iswaudc FROM wa_iswaudc
*               TRANSPORTING
*                  object
*                  valueset
*                  field
*                  val_from
*                  val_to
*                WHERE
*                  swaudid <> space.
*endif.

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
         userhasflag TYPE flag,
         lt_userhas_obj_temp TYPE TABLE OF userhas_obj_typ.
  FIELD-SYMBOLS : <usr> TYPE userhas_obj_typ,
                  <iswaudc> TYPE /psyng/swaudc2.
  lt_userhas_obj_temp[] = lt_users[] = userhas_obj[].
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
*READ TABLE lt_userhas_obj_temp WITH KEY
*            bname   = <usr>-bname
*            swaudid = <iswaudc>-swaudid
*            TRANSPORTING NO FIELDS.
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

  LOOP AT iswaudc.
    LOOP AT userhas WHERE swaudid = iswaudc-swaudid.
      output-swaudid = iswaudc-swaudid.
      MOVE-CORRESPONDING sw_uinfo TO output.
      APPEND output.
    ENDLOOP.
  ENDLOOP.
  SORT output.
  DELETE ADJACENT DUPLICATES FROM output.
  FREE :userhas_obj[],lt_users,userhasflag,wa_userhas_obj.
  IF i_details = 'X'.
    LOOP AT gt_outputdet INTO ls_outputdet.
      READ TABLE output
      INTO ls_output
      WITH KEY
*      bname = ls_outputdet-bname
        swaudid = ls_outputdet-swaudid.
      IF sy-subrc = 0.
*    get the role to which this auth belongs
        IF ls_outputdet-child_agr IS INITIAL.
          SELECT SINGLE agr_name           "#EC CI_SEL_NESTED
          INTO ls_outputdet-child_agr
          FROM agr_1250 WHERE auth = ls_outputdet-auth.
          IF sy-subrc = 0.
           MODIFY gt_outputdet FROM ls_outputdet TRANSPORTING child_agr
            WHERE auth = ls_outputdet-auth.
          ENDIF.
        ENDIF.
        MOVE-CORRESPONDING ls_outputdet TO ls_routputdet.
        ls_routputdet-agr_name = ls_outputdet-bname.
        APPEND ls_routputdet TO outputdet.
      ELSE.
        DELETE gt_outputdet WHERE
*       bname   = ls_outputdet-bname and
          swaudid = ls_outputdet-swaudid.
      ENDIF.
    ENDLOOP.
  ENDIF.
ENDFUNCTION.

*---------------------------------------------------------------------*
*       FORM fill_cri_usertcode                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  USERID                                                        *
*  -->  DEST                                                          *
*---------------------------------------------------------------------*
FORM fill_cri_usertcode USING userid LIKE usr02-bname
                                 dest LIKE rfcdes-rfcdest.
  LOOP AT userprof WHERE bname = userid AND rfcdest = dest.
    SELECT * FROM ust10s WHERE profn = userprof-profile AND
                               objct = 'S_TCODE'.
      REFRESH iiust12.
      READ TABLE iust12 WITH KEY objct = 'S_TCODE'
                                   auth = ust10s-auth
                                  aktps = 'A'
                                  field = 'TCD'
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
      dbust12_idx = sy-tabix.
      LOOP AT iust12 FROM dbust12_idx
                      WHERE objct = 'S_TCODE' AND
                             auth = ust10s-auth AND
                            aktps = 'A' AND
                             field = 'TCD'.
        MOVE-CORRESPONDING iust12 TO iiust12.
        APPEND iiust12.
      ENDLOOP.

      LOOP AT iiust12.
        fr_low = iiust12-von.
        to_high = iiust12-bis.
        PERFORM fill_cri_transaction USING userid.
      ENDLOOP.
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " FILL_USERTCODE

*---------------------------------------------------------------------*
*       FORM fill_cri_userauth                                        *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IUST12                                                        *
*  -->  USERID                                                        *
*  -->  DEST                                                          *
*---------------------------------------------------------------------*
FORM fill_cri_userauth TABLES iust12 STRUCTURE ust12
                          USING userid LIKE usr02-bname
                                dest LIKE rfcdes-rfcdest.
  LOOP AT userprof WHERE bname = userid AND rfcdest = dest.
    SELECT * FROM ust10s WHERE profn = userprof-profile.
      READ TABLE iust12 WITH KEY objct = ust10s-objct
                                 BINARY SEARCH
                                 TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
**** Below gets just the authorization name
      wa_suserauth-bname   = userprof-bname.
*      wa_suserauth-profn   = ust10s-profn.
*      CONCATENATE sy-sysid sy-mandt INTO wa_suserauth-rfcdest.
      wa_suserauth-objct   = ust10s-objct.
      wa_suserauth-auth    = ust10s-auth.
      INSERT wa_suserauth INTO TABLE suserauth.

***  Below gets all authorizaiton data
*      SELECT * FROM UST12
*               into table iiust12
*               WHERE  OBJCT = UST10S-OBJCT AND
*                       AUTH = UST10S-AUTH.
*        USERAUTH-BNAME   = USERPROF-BNAME.
*        USERAUTH-PROFN   = UST10S-PROFN.
*        CONCATENATE SY-SYSID SY-MANDT INTO USERAUTH-RFCDEST.
*        USERAUTH-OBJCT   = iiust12-OBJCT.
*        USERAUTH-AUTH    = iiust12-AUTH.
*        USERAUTH-FIELD   = iiust12-FIELD.
*        USERAUTH-VON     = iiust12-VON.
*        USERAUTH-BIS     = iiust12-BIS.
*        SELECT SINGLE * FROM AGR_PROF WHERE PROFILE = UST10S-PROFN.
*        IF SY-SUBRC = 0.
*          USERAUTH-AGR_NAME = AGR_PROF-AGR_NAME.
*        ENDIF.
*        APPEND USERAUTH.
*      ENDSELECT.
*************
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " FILL_USER_AUTH

*---------------------------------------------------------------------*
*       FORM fill_cri_transaction                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  USERID                                                        *
*---------------------------------------------------------------------*
FORM fill_cri_transaction  USING userid LIKE usr02-bname.

  wa_usertcode-bname = userid.
  first_char = fr_low.

  IF first_char = '*'.                     "If auth has "*" get all
    LOOP AT atcodes.                       "tcodes defined in system
*      CHECK sy-subrc = 0.
      wa_usertcode-bname = userid.
      wa_usertcode-tcode = atcodes-tcode.
      wa_usertcode-auth  = iiust12-auth.
      wa_usertcode-profn = ust10s-profn.
      CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
      INSERT wa_usertcode INTO TABLE usertcode.
      CLEAR wa_usertcode.
    ENDLOOP.
  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range
      LOOP AT atcodes
          WHERE tcode >= fr_low AND tcode <= to_high .
        wa_usertcode-bname = userid.
        wa_usertcode-tcode = atcodes-tcode.
        wa_usertcode-auth  = iiust12-auth.
        wa_usertcode-profn = ust10s-profn.
        CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
        INSERT wa_usertcode INTO TABLE usertcode.
        CLEAR wa_usertcode.
      ENDLOOP.
      REPLACE '*' WITH '%' INTO to_high.
      "If auth 'TO' ends with '*'
      IF sy-subrc = 0.                    "get all transactions
        "begining
        LOOP AT atcodes                "with PREFIX text
            WHERE tcode CP to_high.
          wa_usertcode-bname = userid.
          wa_usertcode-tcode = atcodes-tcode.
          wa_usertcode-auth  = iiust12-auth.
          wa_usertcode-profn = ust10s-profn.
          CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
          INSERT wa_usertcode INTO TABLE usertcode.
          CLEAR wa_usertcode.
        ENDLOOP.
      ENDIF.
*    CONCATENATE FR_LOW '%' INTO FR_TCODE.
      REPLACE '*' WITH '%' INTO fr_low.
      "If auth 'FROM' ends with '*'
      IF sy-subrc = 0.                    "get all transactions
        "begining
        LOOP AT atcodes               "with PREFIX text
        WHERE tcode CP fr_low .
          wa_usertcode-bname = userid.
          wa_usertcode-tcode = tstct-tcode.
          wa_usertcode-auth  = iiust12-auth.
          wa_usertcode-profn = ust10s-profn.
          CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
          INSERT wa_usertcode INTO TABLE usertcode.
          CLEAR wa_usertcode.
        ENDLOOP..
      ENDIF.
    ELSE.               "If auth has a starting char with * following
      "it
      REPLACE '*' WITH '%' INTO fr_low.
      IF sy-subrc = 0.
        LOOP AT atcodes WHERE tcode CP fr_low.
          wa_usertcode-bname = userid.
          wa_usertcode-tcode = atcodes-tcode.
          wa_usertcode-auth  = iiust12-auth.
          wa_usertcode-profn = ust10s-profn.
          CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
          INSERT wa_usertcode INTO TABLE usertcode.
          CLEAR wa_usertcode.
        ENDLOOP.
      ELSE.                "If specific transaction is specified
        LOOP AT atcodes WHERE tcode = iiust12-von .
          wa_usertcode-bname = userid.
          wa_usertcode-tcode = atcodes-tcode.
          wa_usertcode-auth  = iiust12-auth.
          wa_usertcode-profn = ust10s-profn.
          CONCATENATE sy-sysid sy-mandt INTO wa_usertcode-rfcdest.
          INSERT wa_usertcode INTO TABLE usertcode.
          CLEAR wa_usertcode.
        ENDLOOP.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TRANSACTION
