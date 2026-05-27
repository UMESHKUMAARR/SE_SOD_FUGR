*----------------------------------------------------------------------*
* Function Module       : /PSYNG/SW_GET_USER_AUTH_DATA
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
FUNCTION /psyng/sw_user_cri_auth_data.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  EXPORTING
*"     VALUE(RETURN) LIKE  BAPIRET1 STRUCTURE  BAPIRET1
*"  TABLES
*"      USERTCODE STRUCTURE  /PSYNG/USERTCODE OPTIONAL
*"      USERPROF STRUCTURE  /PSYNG/USERPROF OPTIONAL
*"      USERAUTH STRUCTURE  /PSYNG/USERAUTH OPTIONAL
*"      IUST12 STRUCTURE  UST12
*"      SWAUDC STRUCTURE  /PSYNG/SWAUDC2
*"      IUSR02 STRUCTURE  USR02
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_USER_CRI_AUTH_DATA'.
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
*This function module will only fetch authorization and transaction
*data that is part of the SOD matrix only!
*This is done to increase performance of the Security Weaver SOD reports
  REFRESH :gt_agrprof[],iagrprof[] .


  DATA: dest LIKE rfcdes-rfcdest.

  DATA: BEGIN OF ustcodeauth OCCURS 0,
          auth LIKE ust10s-auth,
        END OF ustcodeauth.
  DATA: BEGIN OF ustcodeprof OCCURS 0,
          profn LIKE ust10s-profn,
        END OF ustcodeprof.

  CONCATENATE sy-sysid sy-mandt INTO dest.
***********************************************
  SELECT agr_name profile FROM agr_1016 INTO TABLE gt_agrprof.
  INSERT LINES OF gt_agrprof INTO TABLE iagrprof.
  REFRESH gt_agrprof[].
  CLEAR  gt_agrprof.
  LOOP AT swaudc.   "Unique list of tcodes
    ftcodes-tcode = swaudc-tcode.
    APPEND ftcodes.
  ENDLOOP.
  SORT ftcodes.
  DELETE ADJACENT DUPLICATES FROM ftcodes.

  SORT iusr02.
  SORT userprof.
  DELETE ADJACENT DUPLICATES FROM userprof.
  suserprof[] = userprof[].
  REFRESH userprof.
  CLEAR: userprof, suserprof.
  LOOP AT iusr02.
    PERFORM fill_cri_userprof USING iusr02-bname.
  ENDLOOP.
  CLEAR: userprof, suserprof.
  LOOP AT suserprof.
    ustcodeprof-profn = suserprof-profile.
    APPEND ustcodeprof.
  ENDLOOP.
  SORT ustcodeprof.
  DELETE ADJACENT DUPLICATES FROM ustcodeprof.

* Newcode start
  IF NOT ustcodeprof IS INITIAL.
    SELECT auth FROM ust10s
                  INTO TABLE ustcodeauth
                  FOR ALL ENTRIES IN ustcodeprof
                  WHERE profn = ustcodeprof-profn AND
                        objct = 'S_TCODE'.
  ENDIF.
**New code end
****************************************************
  SORT ustcodeauth.
  REFRESH: ustcodeprof.

  if not ustcodeauth[] is initial.
  SELECT * FROM ust12
           INTO CORRESPONDING FIELDS OF TABLE dbust12
           FOR ALL ENTRIES IN ustcodeauth
           WHERE objct = 'S_TCODE' AND
                 auth = ustcodeauth-auth.
  endif.
  REFRESH ustcodeauth.

  SORT: usertcode, userprof, userauth.
  DELETE ADJACENT DUPLICATES FROM usertcode.
  DELETE ADJACENT DUPLICATES FROM userauth.
  susertcode[] = usertcode[].

  SORT: iust12.
  LOOP AT iusr02.
    PERFORM fill_cri_usertcode
              TABLES ftcodes USING iusr02-bname dest.

    PERFORM fill_cri_userauth
            TABLES iust12 USING iusr02-bname dest.
  ENDLOOP.
  userauth[] = suserauth[].
  REFRESH: suserauth.
  usertcode[] = susertcode[].
  REFRESH: susertcode.
  userprof[] = suserprof[].
  refresh: suserprof.
ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  FILL_USERPROF
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_cri_userprof USING userid LIKE usr02-bname.
  SELECT * FROM ust04 WHERE bname = userid.
    REFRESH: profinfo.
    CLEAR:   wa_suserprof.
    CALL FUNCTION '/PSYNG/SW_GET_SINGLE_PROFS'
         EXPORTING
              profname = ust04-profile
         TABLES
              profinfo = profinfo.
    LOOP AT profinfo.
      wa_suserprof-bname = ust04-bname.
      wa_suserprof-profile = profinfo-profn.
      CONCATENATE sy-sysid sy-mandt INTO wa_suserprof-rfcdest.
      READ TABLE iagrprof WITH KEY profile = profinfo-profn+0(10)
                                             BINARY SEARCH
                                             TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        wa_suserprof-agr_name = iagrprof-agr_name.
      ELSE.
        CLEAR wa_suserprof-agr_name.
      ENDIF.
      INSERT wa_suserprof INTO TABLE suserprof.
    ENDLOOP.
  ENDSELECT.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  FILL_USERTCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_cri_usertcode TABLES ftcodes   STRUCTURE ftcodes
                           USING userid LIKE usr02-bname
                                 dest LIKE rfcdes-rfcdest.
  READ TABLE suserprof WITH KEY bname   = userid
                               rfcdest = dest
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
  userprof_idx = sy-tabix.
  LOOP AT suserprof FROM userprof_idx
                   WHERE bname = userid AND rfcdest = dest.
    SELECT * FROM ust10s WHERE profn = suserprof-profile AND
                               objct = 'S_TCODE'.
      REFRESH iiust12.
      READ TABLE dbust12 WITH KEY objct = 'S_TCODE'
                                   auth = ust10s-auth
                                  aktps = 'A'
                                  field = 'TCD'
                                  BINARY SEARCH
                                  TRANSPORTING NO FIELDS.
      dbust12_idx = sy-tabix.
      LOOP AT dbust12 FROM dbust12_idx
                      WHERE objct = 'S_TCODE' AND
                             auth = ust10s-auth AND
                            aktps = 'A' AND
                             field = 'TCD'.

        MOVE-CORRESPONDING dbust12 TO iiust12.
        APPEND iiust12.
      ENDLOOP.

      LOOP AT iiust12.
        fr_low = iiust12-von.
        to_high = iiust12-bis.
        PERFORM fill_cri_transaction
                        TABLES ftcodes USING userid.
      ENDLOOP.
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " FILL_USERTCODE

*&---------------------------------------------------------------------*
*&      Form  FILL_USERAUTH
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_cri_userauth TABLES iust12 STRUCTURE ust12
                          USING userid LIKE usr02-bname
                                dest LIKE rfcdes-rfcdest.
  READ TABLE suserprof WITH KEY bname   = userid
                               rfcdest = dest
                               BINARY SEARCH
                               TRANSPORTING NO FIELDS.
  userprof_idx = sy-tabix.
  LOOP AT suserprof FROM userprof_idx
                   WHERE bname = userid AND rfcdest = dest.
    SELECT * FROM ust10s WHERE profn = suserprof-profile.
      READ TABLE iust12 WITH KEY objct = ust10s-objct
                                 BINARY SEARCH
                                 TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.
**** Below gets just the authorization name
      wa_suserauth-bname   = suserprof-bname.
      wa_suserauth-profn   = ust10s-profn.
      CONCATENATE sy-sysid sy-mandt INTO wa_suserauth-rfcdest.
      wa_suserauth-objct   = ust10s-objct.
      wa_suserauth-auth    = ust10s-auth.
      READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                             BINARY SEARCH.
      IF sy-subrc = 0.
        wa_suserauth-agr_name = iagrprof-agr_name.
      ENDIF.
      INSERT wa_suserauth INTO TABLE suserauth.
    ENDSELECT.
  ENDLOOP.
ENDFORM.                    " FILL_USER_AUTH


*&---------------------------------------------------------------------*
*&      Form  FILL_TRANSACTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM fill_cri_transaction TABLES usertcode STRUCTURE /psyng/usertcode
*                             ftcodes   STRUCTURE ftcodes
*                             USING userid LIKE usr02-bname.
FORM fill_cri_transaction TABLES ftcodes   STRUCTURE ftcodes
                             USING userid LIKE usr02-bname.

  DATA:   iagrprof_idx TYPE i,
          l_tcode TYPE tstct-tcode.
  DATA: BEGIN OF lt_tcode OCCURS 0,
        tcode TYPE tstct-tcode,
        END OF lt_tcode.

  wa_susertcode-bname = userid.
  first_char = fr_low.
  iagrprof_idx = 1.

  IF first_char = '*'.                     "If auth has "*" get all
                                           "tcodes defined in system

   if not ftcodes[] is initial.
   SELECT tcode FROM tstct INTO TABLE lt_tcode
     FOR ALL ENTRIES IN ftcodes WHERE tcode = ftcodes-tcode AND
                                                sprsl = sy-langu.
   endif.
   LOOP AT lt_tcode.
     wa_susertcode-bname = userid.
      wa_susertcode-tcode = lt_tcode-tcode.
      wa_susertcode-auth  = iiust12-auth.
      wa_susertcode-profn = ust10s-profn.
      CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
     READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                             BINARY SEARCH.
      IF sy-subrc = 0.
        wa_susertcode-agr_name = iagrprof-agr_name.
      ENDIF.
      INSERT wa_susertcode INTO TABLE susertcode.
      CLEAR wa_susertcode.
   ENDLOOP.

  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range



    SELECT tcode FROM tstct INTO TABLE lt_tcode
      WHERE tcode >= fr_low AND tcode <= to_high AND sprsl = 'E'.
     SORT ftcodes.

    LOOP AT lt_tcode.
     READ TABLE ftcodes WITH KEY tcode = lt_tcode-tcode BINARY SEARCH
                                            TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        wa_susertcode-bname = userid.
        wa_susertcode-tcode = lt_tcode-tcode.
        wa_susertcode-auth  = iiust12-auth.
        wa_susertcode-profn = ust10s-profn.
        CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
        READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                               BINARY SEARCH.
        IF sy-subrc = 0.
          wa_susertcode-agr_name = iagrprof-agr_name.
        ENDIF.
        INSERT wa_susertcode INTO TABLE susertcode.
        CLEAR wa_susertcode.
    ENDLOOP.
      REFRESH lt_tcode.

      REPLACE '*' WITH '%' INTO to_high.
      "If auth 'TO' ends with '*'
      IF sy-subrc = 0.                    "get all transactions begining

        SELECT tcode FROM tstct INTO TABLE lt_tcode
            WHERE tcode LIKE to_high AND sprsl = sy-langu.
        LOOP AT lt_tcode.
         READ TABLE ftcodes WITH KEY tcode = lt_tcode-tcode
                                                BINARY SEARCH
                                                TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
            wa_susertcode-bname = userid.
            wa_susertcode-tcode = lt_tcode-tcode.
            wa_susertcode-auth  = iiust12-auth.
            wa_susertcode-profn = ust10s-profn.
            CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
            READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                                   BINARY SEARCH.
            IF sy-subrc = 0.
              wa_susertcode-agr_name = iagrprof-agr_name.
            ENDIF.
            INSERT wa_susertcode INTO TABLE susertcode.
            CLEAR wa_susertcode.
       ENDLOOP.

      ENDIF.
     REFRESH lt_tcode.

      REPLACE '*' WITH '%' INTO fr_low.
      "If auth 'FROM' ends with '*'
      IF sy-subrc = 0.                    "get all transactions begining

        SELECT tcode FROM tstct INTO TABLE lt_tcode
        WHERE tcode LIKE fr_low AND sprsl = sy-langu.

        LOOP AT lt_tcode.
        READ TABLE ftcodes WITH KEY tcode = tstct-tcode
                                                BINARY SEARCH
                                                TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          wa_susertcode-bname = userid.
          wa_susertcode-tcode = lt_tcode-tcode.
          wa_susertcode-auth  = iiust12-auth.
          wa_susertcode-profn = ust10s-profn.

          CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
          READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                                 BINARY SEARCH.
          IF sy-subrc = 0.
            wa_susertcode-agr_name = iagrprof-agr_name.
          ENDIF.

          INSERT wa_susertcode INTO TABLE susertcode.
          CLEAR wa_susertcode.

        ENDLOOP.
      ENDIF.

    ELSE.               "If auth has a starting char with * following it
      REPLACE '*' WITH '%' INTO fr_low.
      IF sy-subrc = 0.
       SELECT tcode FROM tstct INTO TABLE lt_tcode
           WHERE tcode LIKE fr_low AND sprsl = sy-langu.

       LOOP AT lt_tcode.

          READ TABLE ftcodes WITH KEY tcode = lt_tcode-tcode
                                                BINARY SEARCH
                                               TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
          wa_susertcode-bname = userid.
          wa_susertcode-tcode = lt_tcode-tcode.
          wa_susertcode-auth  = iiust12-auth.
          wa_susertcode-profn = ust10s-profn.
          CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
          READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                                 BINARY SEARCH.
          IF sy-subrc = 0.
            wa_susertcode-agr_name = iagrprof-agr_name.
          ENDIF.
          INSERT wa_susertcode INTO TABLE susertcode.
          CLEAR wa_susertcode.
       ENDLOOP.

      ELSE.                "If specific transaction is specified

        SELECT SINGLE tcode FROM tstct INTO l_tcode
            WHERE tcode = iiust12-von AND sprsl = sy-langu.

          READ TABLE ftcodes WITH KEY tcode = l_tcode
                                                BINARY SEARCH
                                                TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        wa_susertcode-bname = userid.
        wa_susertcode-tcode = l_tcode.
        wa_susertcode-auth  = iiust12-auth.
        wa_susertcode-profn = ust10s-profn.
        CONCATENATE sy-sysid sy-mandt INTO wa_susertcode-rfcdest.
        READ TABLE iagrprof WITH KEY profile = ust10s-profn
                                               BINARY SEARCH.
        IF sy-subrc = 0.
          wa_susertcode-agr_name = iagrprof-agr_name.
        ENDIF.
        INSERT wa_susertcode INTO TABLE susertcode.
        CLEAR wa_susertcode.

      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TRANSACTION
