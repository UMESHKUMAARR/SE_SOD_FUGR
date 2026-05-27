FUNCTION /psyng/sw_sodsys_get_role_data.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(AGR_NAME) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(BNAME) LIKE  USR02-BNAME
*"     VALUE(REM_EXECUTION) TYPE  CHAR01 OPTIONAL
*"     VALUE(RFCDEST) LIKE  RFCDES-RFCDEST OPTIONAL
*"     VALUE(I_AUTHDETAILS) TYPE  FLAG DEFAULT ''
*"  TABLES
*"      ROLETCODE STRUCTURE  /PSYNG/USERTCODE OPTIONAL
*"      ROLEPROF STRUCTURE  /PSYNG/USERPROF OPTIONAL
*"      ROLEAUTH STRUCTURE  /PSYNG/USERAUTH OPTIONAL
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2
*"      IT_1016 STRUCTURE  AGR_1016
*"      IT_UST10S STRUCTURE  UST10S
*"      IT_1251 STRUCTURE  AGR_1251 OPTIONAL
*"      IT_1252 STRUCTURE  AGR_1252 OPTIONAL
*"----------------------------------------------------------------------


*--> BOC SE VF Scan changes - UMITTAL - 02/12/24
CONSTANTS: lc_fname TYPE rs38l_fnam
  VALUE '/PSYNG/SW_SODSYS_GET_ROLE_DATA'.
*  S_RFC AUTHORITY CHECK
  AUTHORITY-CHECK OBJECT 'S_RFC'
        ID 'RFC_TYPE' FIELD 'FUNC'
        ID 'RFC_NAME' FIELD lc_fname
        ID 'ACTVT' FIELD '16'.
  IF sy-subrc <> 0.
    MESSAGE e089(/psyng/sw) WITH lc_fname.
  ENDIF.

*--> EOC SO VF Scan changes - UMITTAL - 02/12/24
****This FM is a copy of /PSYNG/SW_GET_SIMU_ROLE_DATA as of 1/30/09*****
*   But tuned for System-Wide analysis.
  statics :
    lt_faobj_old  type table of /PSYNG/FAOBJ2 with header line,
    lt_faobj1_old like table of faobj1,
    lt_functtran_old type table of /PSYNG/FUNCTTRAN with header line,
    lt_ftcodes_old like table of ftcodes,
    lt_tstc_old TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode
                      WITH HEADER LINE.
  FREE : faobj1[]."dhorions 08/05/2008
  DATA: dest LIKE rfcdes-rfcdest.
  field-symbols : <faobj> type /PSYNG/FAOBJ2.

  IF rem_execution <> space.  "read FM documentation
    CHECK rfcdest <> space.
    dest = rfcdest.
  ELSE.
    CONCATENATE sy-sysid sy-mandt INTO dest.
  ENDIF.

  REFRESH: roletcode, roleprof, roleauth.
*  SORT: functtran BY tcode.
*  sort faobj BY object.
  if lt_faobj_old[] = FAOBJ[].
*-- FAOBJ table passed in previous call to this FM was exacltly the same
*   no need to loop again, use previous foabj1 lookup table
    faobj1[] = lt_faobj1_old[].
  else.

    LOOP AT faobj assigning <faobj>.
      faobj1-object   = <faobj>-object.
*      faobj1-funid    = <faobj>-funid.
*      faobj1-tcode    = <faobj>-tcode.
*      faobj1-field    = <faobj>-field.
*      faobj1-val_from = <faobj>-val_from.
*      faobj1-val_to   = <faobj>-val_to.
*      APPEND faobj1.
       collect faobj1.
    ENDLOOP.
    sort faobj1.
    lt_faobj1_old[] = faobj1[].
  endif.
  lt_faobj_old[] = FAOBJ[].
  if lt_functtran_old[] = functtran[].
    ftcodes[] = lt_ftcodes_old[].
    dbtstc[]  = lt_tstc_old[].
  else.
    LOOP AT functtran.        "Get a unique list of tcodes
      ftcodes-tcode = functtran-tcode.  "in SOD matrix
      APPEND ftcodes.          "to perform binary searches
      wa_dbtstc-tcode = functtran-tcode.
      INSERT wa_dbtstc INTO TABLE dbtstc.
    ENDLOOP.
    SORT ftcodes.
    DELETE ADJACENT DUPLICATES FROM ftcodes.
    lt_ftcodes_old[] = ftcodes[].
    lt_tstc_old[]    = dbtstc[].
  endif.
  lt_functtran_old[] = functtran[].


*  FREE : dbtstc[].
*  LOOP AT functtran.
*    wa_dbtstc-tcode = functtran-tcode.
*    INSERT wa_dbtstc INTO TABLE dbtstc.
*  ENDLOOP.

  PERFORM get_data_from_single_role TABLES
                                        roletcode
                                        roleprof
                                        roleauth
                                        ftcodes
                                        faobj
                                        it_1016
                                        it_1251
                                        it_1252
                                        it_ust10s
                                    USING
                                        agr_name
                                        bname
                                        dest
                                        i_authdetails.
  REFRESH: iagrprof.     "sagrprof,
  SORT: roleauth, roletcode, roleprof.
  DELETE ADJACENT DUPLICATES FROM roleauth.
  DELETE ADJACENT DUPLICATES FROM roletcode.
  DELETE ADJACENT DUPLICATES FROM roleprof.
ENDFUNCTION.

*&---------------------------------------------------------------------*
*&      Form  GET_DATA_FROM_SINGLE_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data_from_single_role TABLES
                               roletcode STRUCTURE /psyng/usertcode
                               roleprof  STRUCTURE /psyng/userprof
                               roleauth  STRUCTURE /psyng/userauth
                               ftcodes   STRUCTURE ftcodes
                               sodobject STRUCTURE /psyng/faobj2
                               it_1016   STRUCTURE agr_1016
                               it_1251   STRUCTURE agr_1251
                               it_1252   STRUCTURE agr_1252
                               it_ust10s STRUCTURE ust10s
                             USING
                                 agr_name LIKE agr_define-agr_name
                                 bname    LIKE usr02-bname
                                 dest  LIKE rfcdes-rfcdest
                                 i_authdetails TYPE flag.

  DATA: idx LIKE sy-tabix,
        idx2 LIKE sy-tabix.

  DATA: lt_1016 TYPE SORTED TABLE OF agr_1016
        WITH UNIQUE KEY agr_name profile
        WITH HEADER LINE.

  DATA: lt_1251 TYPE SORTED TABLE OF agr_1251
        WITH UNIQUE KEY agr_name object auth field low high
        WITH HEADER LINE.

  DATA: lt_1252 TYPE SORTED TABLE OF agr_1252
        WITH UNIQUE KEY agr_name varbl low high
        WITH HEADER LINE.

  DATA: lt_ust10s TYPE SORTED TABLE OF ust10s
        WITH UNIQUE KEY profn aktps objct auth
        WITH HEADER LINE.

  SORT: it_ust10s, it_1252, it_1251, it_1016, faobj1.
  DELETE ADJACENT DUPLICATES FROM it_ust10s.
  DELETE ADJACENT DUPLICATES FROM it_1252.
  DELETE ADJACENT DUPLICATES FROM it_1251.
  DELETE ADJACENT DUPLICATES FROM it_1016.

* move data to sorted tables.
  lt_1016[] = it_1016[]. FREE: it_1016.
  lt_1251[] = it_1251[]. FREE: it_1251.
  lt_1252[] = it_1252[]. FREE: it_1252.
  lt_ust10s[] = it_ust10s[]. FREE: it_ust10s.

*Get profile name of AGR_NAME
  READ TABLE lt_1016 WITH KEY agr_name = agr_name
             BINARY SEARCH TRANSPORTING NO FIELDS.
  idx = sy-tabix.
  LOOP AT lt_1016 FROM idx WHERE agr_name = agr_name.
    roleprof-profile = lt_1016-profile.
    roleprof-bname = bname.
    roleprof-rfcdest = dest.
    roleprof-agr_name = agr_name.
    APPEND roleprof.
  ENDLOOP.

* Get authorization data of UST12
  DATA : lt_ust12 TYPE TABLE OF ust12 WITH HEADER LINE,
         lt_ust12s TYPE SORTED TABLE OF ust12 WITH HEADER LINE
         WITH NON-UNIQUE KEY objct field.

  LOOP AT lt_ust10s.
    READ TABLE faobj1 WITH KEY object = lt_ust10s-objct
    BINARY SEARCH.
    CHECK sy-subrc <> 0 AND lt_ust10s-objct <> 'S_TCODE'.
    DELETE lt_ust10s.
  ENDLOOP.
  CHECK NOT lt_ust10s[] IS INITIAL.
  SELECT * FROM ust12
             INTO TABLE lt_ust12
             FOR ALL ENTRIES IN lt_ust10s
             WHERE objct   = lt_ust10s-objct
             AND   auth    = lt_ust10s-auth
             AND   aktps   = 'A'.



  SORT lt_ust12 BY objct field.
  lt_ust12s[] = lt_ust12[].
  FREE lt_ust12.
  LOOP AT lt_ust12s.
*--Move authorizations to output table
    roleauth-bname    = bname.
    roleauth-rfcdest  = dest.
    roleauth-objct    = lt_ust12s-objct.
    roleauth-auth     = lt_ust12s-auth.
    IF i_authdetails = 'X'.
      roleauth-field    = lt_ust12s-field.
      roleauth-von      = lt_ust12s-von.
      roleauth-bis      = lt_ust12s-bis.
    ENDIF.
    roleauth-agr_name = agr_name.
    roleauth-profn    = ''.
    APPEND roleauth.
*--Get tcodes of AGR_NAME
    CHECK lt_ust12s-objct = 'S_TCODE' AND lt_ust12s-field = 'TCD'.
    fr_low =  lt_ust12s-von.
    to_high = lt_ust12s-bis.
    ust12   = lt_ust12s.
    PERFORM fill_tcodes
                      TABLES roletcode ftcodes
                      USING bname dest lt_ust10s-profn agr_name.

  ENDLOOP.


  LOOP AT roleauth WHERE profn = space.
    LOOP AT roleprof WHERE agr_name = roleauth-agr_name.
      roleauth-profn = roleprof-profile.
    ENDLOOP.
    MODIFY roleauth.
  ENDLOOP.
*--START DHORIONS 2011/05/25
  FREE : lt_ust12s.
  SORT roletcode.
  DELETE ADJACENT DUPLICATES FROM roletcode COMPARING ALL FIELDS.
ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  FILL_TCODES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_tcodes TABLES roletcode STRUCTURE /psyng/usertcode
                        ftcodes STRUCTURE ftcodes
                        USING bname LIKE usr02-bname
                              dest LIKE rfcdes-rfcdest
                              profn LIKE ust10s-profn
                              agr_name LIKE agr_define-agr_name.

  DATA : ls_compare TYPE /psyng/auth_compare,
         lt_compare TYPE TABLE OF /psyng/auth_compare.

  FIELD-SYMBOLS : <comp> TYPE /psyng/auth_compare.

  REFRESH lt_compare.
  roletcode-bname = bname.
  first_char = fr_low.
  IF first_char = '*'.                     "If auth has "*" get all
    LOOP AT dbtstc. "tcodes defined in system (/psyng/functtran)
      READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode BINARY SEARCH.
      CHECK sy-subrc = 0.
      roletcode-tcode   = dbtstc-tcode.
      roletcode-auth    = ust12-auth.
      roletcode-profn   = profn.
      roletcode-rfcdest = dest.
      roletcode-agr_name = agr_name.
      APPEND roletcode.
    ENDLOOP.
  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range
*     tcodes between high and low


      LOOP AT dbtstc.
        ls_compare-auth_from  = fr_low.
        ls_compare-auth_to    = to_high.
        ls_compare-sod_from   = dbtstc-tcode.
        APPEND ls_compare TO lt_compare  .
      ENDLOOP.
*  --SW_021 does the sorting and deleting dupes
*      CALL FUNCTION '/PSYNG/SW_021'
      CALL FUNCTION '/PSYNG/SW_COMPARE_RANGES'
           TABLES
                it_compare = lt_compare.

      SORT lt_compare BY match.
      DELETE lt_compare WHERE match <> 'X'.
      LOOP AT lt_compare ASSIGNING <comp>
        WHERE match = 'X'.
        READ TABLE ftcodes WITH KEY tcode = <comp>-sod_from
        BINARY SEARCH.
        CHECK sy-subrc = 0.
        roletcode-tcode   = <comp>-sod_from.
        roletcode-auth    = ust12-auth.
        roletcode-profn   = profn.
        roletcode-rfcdest = dest.
        roletcode-agr_name = agr_name.
        APPEND roletcode.
      ENDLOOP.

      IF fr_low CS '*'.

        LOOP AT dbtstc
           WHERE tcode CP fr_low.
          READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode
                                                BINARY SEARCH.
          CHECK sy-subrc = 0.
          roletcode-tcode   = dbtstc-tcode.
          roletcode-auth    = ust12-auth.
          roletcode-profn   = profn.
          roletcode-rfcdest = dest.
          roletcode-agr_name = agr_name.
          APPEND roletcode.
        ENDLOOP.
      ENDIF.
    ELSE.               "If auth has a starting char with * following it
      IF fr_low CS '*'.
        LOOP AT dbtstc WHERE tcode CP fr_low.
          READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode
                                                BINARY SEARCH.
          CHECK sy-subrc = 0.
          roletcode-tcode = dbtstc-tcode.
          roletcode-auth  = ust12-auth.
          roletcode-profn = profn.
          roletcode-rfcdest = dest.
          roletcode-agr_name = agr_name.
          APPEND roletcode.
        ENDLOOP.
      ELSE.                "If specific transaction is specified
        READ TABLE dbtstc WITH KEY tcode = ust12-von BINARY SEARCH.
        CHECK sy-subrc = 0.
        roletcode-tcode = ust12-von.
        roletcode-auth  = ust12-auth.
        roletcode-profn = profn.
        roletcode-rfcdest = dest.
        roletcode-agr_name = agr_name.
        APPEND roletcode.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TCODES
