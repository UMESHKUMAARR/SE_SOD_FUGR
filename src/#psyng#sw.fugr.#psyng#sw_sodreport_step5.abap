FUNCTION /psyng/sw_sodreport_step5.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  TABLES
*"      IUSERS STRUCTURE  USR02
*"      SUSERTCODE STRUCTURE  /PSYNG/USERTCODE
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      CONFDET STRUCTURE  /PSYNG/CONFDET
*"      SODOBJECT STRUCTURE  /PSYNG/SODOBJECT
*"      ITCDAUT STRUCTURE  /PSYNG/PSSWTCDAUT
*"      SUSERAUTH STRUCTURE  /PSYNG/USERAUTH
*"      TOBJS2 STRUCTURE  /PSYNG/TOBJS
*"      CONFS2 STRUCTURE  /PSYNG/SWCONFS
*"      1STOUTPUT STRUCTURE  /PSYNG/1STOUTPUT_U
*"----------------------------------------------------------------------

  DATA: tobjs1 LIKE tobjs2 OCCURS 0 WITH HEADER LINE,
        wa_tobjs LIKE /psyng/tobjs,
        confs1 TYPE /psyng/swconfs OCCURS 0 WITH HEADER LINE,
        outputdet2 LIKE outputdet OCCURS 0 WITH HEADER LINE,
        wa_s1stoutput LIKE /psyng/1stoutput_u.


  DATA: s1stoutput TYPE SORTED TABLE OF /psyng/1stoutput_u
        WITH UNIQUE KEY bname name_text conid
        WITH HEADER LINE.

  usertcode_idx = 1.  sodtab1_idx = 1. userauth_idx = 1.
  usertcode2_idx = 1. sodtab2_idx = 1. userauth2_idx = 1.
  tobjs2_idx = 1.     tobjs1_idx = 1.
  outputdet_idx = 1.  outputdet2_idx = 1.
  tobjs1[] = tobjs2[].
  describe table iusers lines records.
  move records to records_c.

  LOOP AT iusers.
*step 5
*start with transaction exe by user
    READ TABLE susertcode WITH KEY bname = iusers-bname BINARY SEARCH.
    usertcode_idx = sy-tabix.
    LOOP AT susertcode FROM usertcode_idx WHERE bname = iusers-bname.
      usertcode_idx = sy-tabix.
*step 5-a-i
*  get all functions that have that transaction
      LOOP AT functtran WHERE tcode = susertcode-tcode.
        LOOP AT confdet WHERE functionid = functtran-functionid.
          READ TABLE sodobject WITH KEY tcode = susertcode-tcode
                                                BINARY SEARCH.
          IF sy-subrc <> 0.
*document no objects are defined in SOD table document just tcode
            wa_outdet-bname       = susertcode-bname.
            wa_outdet-conid       = confdet-conid.
            wa_outdet-functionid  = confdet-functionid.
            wa_outdet-rfcdest     = susertcode-rfcdest.
            wa_outdet-tcode       = susertcode-tcode.
            wa_outdet-objct       = 'S_TCODE'.
            wa_outdet-auth        = susertcode-auth.
            wa_outdet-field       = 'TCD'.
            wa_outdet-von         = susertcode-tcode.
            wa_outdet-bis         = ''.
            wa_outdet-description = ''. "not for performance
            wa_outdet-agr_name    = susertcode-agr_name.
            wa_outdet-profile     = susertcode-profn.
            INSERT wa_outdet INTO TABLE outputdet5.
            CLEAR wa_outdet.
          ENDIF.
*  can the user "really" execute the transaction, auth check
          READ TABLE itcdaut WITH KEY rfcdest = susertcode-rfcdest
                                        tcode = susertcode-tcode
                                        BINARY SEARCH.
          CHECK sy-subrc = 0.
          itcdaut_idx = sy-tabix.
          LOOP AT itcdaut FROM itcdaut_idx
                          WHERE rfcdest = susertcode-rfcdest AND
                                  tcode = susertcode-tcode.
            READ TABLE suserauth WITH KEY bname = susertcode-bname
                                       rfcdest  = itcdaut-rfcdest
                                       objct    = itcdaut-objct
                                       auth     = itcdaut-auth
                                       BINARY SEARCH.
            CHECK sy-subrc = 0. "if not skip to next tcode/auth combo
*  if the user really can execute the transaction, then document it
            userauth_idx = sy-tabix.
            LOOP AT suserauth FROM userauth_idx
                             WHERE bname    = susertcode-bname AND
                                   rfcdest  = itcdaut-rfcdest AND
                                   objct    = itcdaut-objct   AND
                                   auth     = itcdaut-auth.
              userauth_idx = sy-tabix.
*  document the transaction
              wa_outdet-bname       = susertcode-bname.
              wa_outdet-conid       = confdet-conid.
              wa_outdet-functionid  = confdet-functionid.
              wa_outdet-rfcdest     = susertcode-rfcdest.
              wa_outdet-tcode       = susertcode-tcode.
              wa_outdet-objct       = 'S_TCODE'.
              wa_outdet-auth        = susertcode-auth.
              wa_outdet-field       = 'TCD'.
              wa_outdet-von         = susertcode-tcode.
              wa_outdet-bis         = ''.
              wa_outdet-description = ''.  "not for performance
              wa_outdet-agr_name    = susertcode-agr_name.
              wa_outdet-profile     = susertcode-profn.
              INSERT wa_outdet INTO TABLE outputdet5.
              CLEAR wa_outdet.

*  document the authorization details
              wa_outdet-bname       = susertcode-bname.
              wa_outdet-conid       = confdet-conid.
              wa_outdet-functionid  = confdet-functionid.
              wa_outdet-rfcdest     = suserauth-rfcdest.
              wa_outdet-tcode       = susertcode-tcode.
              wa_outdet-objct       = suserauth-objct.
              wa_outdet-auth        = suserauth-auth.
              wa_outdet-field       = itcdaut-field.
              wa_outdet-von         = itcdaut-von.
              wa_outdet-bis         = itcdaut-bis.
              wa_outdet-description = ''.  "not for performance
              wa_outdet-agr_name    = suserauth-agr_name.
              wa_outdet-profile     = suserauth-profn.
              INSERT wa_outdet INTO TABLE outputdet5.
              CLEAR wa_outdet.
              MODIFY tobjs1 FROM wa_tobjs TRANSPORTING
                     userhas WHERE
                                  tcode  = susertcode-tcode AND
                                  object = suserauth-objct.
            ENDLOOP.  "USERAUTH
          ENDLOOP. "itcdaut
        ENDLOOP.       "confdet
        AT END OF tcode.
* Check whether user has at least 1 auth for all objects for this tcode
          LOOP AT tobjs1 WHERE tcode = susertcode-tcode AND
                                             userhas <> 'Y'.
            REFRESH outputdet5.
          ENDLOOP.
          CHECK sy-subrc <> 0. "if user has at least 1 auth for all objs
          LOOP AT outputdet5.
            INSERT outputdet5 INTO TABLE outputdet.
          ENDLOOP.
          REFRESH outputdet5.
          tobjs1[] = tobjs2[].
        ENDAT.
      ENDLOOP.  "functtran
    ENDLOOP.                                                "usertcode1

    DELETE susertcode WHERE bname = iusers-bname.
    DELETE suserauth WHERE bname = iusers-bname.

    outputdet2[] = outputdet[].
    LOOP AT outputdet.
      AT NEW bname.
        confs1[] = confs2[].
      ENDAT.

      LOOP AT confs1 WHERE conid = outputdet-conid.
        IF confs1-functionid = outputdet-functionid.
          confs1-userhas = 'Y'.
          MODIFY confs1.
        ENDIF.
      ENDLOOP.

      AT END OF bname.
        LOOP AT confs1 WHERE userhas NE 'Y'.
          DELETE outputdet2 WHERE bname = outputdet-bname AND
                                  conid = confs1-conid.
        ENDLOOP.
        REFRESH confs1.
        confs1[] = confs2[].
      ENDAT.
    ENDLOOP.

    REFRESH outputdet.
    DELETE outputdet2 WHERE bname = space.
    LOOP AT outputdet2.
      MOVE-CORRESPONDING outputdet2 TO wa_s1stoutput.
      INSERT wa_s1stoutput INTO TABLE s1stoutput.
    ENDLOOP.
    REFRESH outputdet2.
*END of STEP 6
*=======================================================================

    usercount = usercount + 1. move usercount to usercount_c.
    concatenate usercount_c text-027 records_c text-028 into message
                separated by space.
    MESSAGE s208(00) WITH  message.
  ENDLOOP.

  INSERT LINES OF s1stoutput INTO TABLE 1stoutput.
  REFRESH s1stoutput.
ENDFUNCTION.
