FUNCTION /psyng/sw_get_role_sum_data.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(AGR_NAME) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(BNAME) LIKE  USR02-BNAME
*"     VALUE(REM_EXECUTION) TYPE  CHAR01 OPTIONAL
*"     VALUE(RFCDEST) LIKE  RFCDES-RFCDEST OPTIONAL
*"  TABLES
*"      ROLETCODE STRUCTURE  /PSYNG/USERTCODE OPTIONAL
*"      ROLEPROF STRUCTURE  /PSYNG/USERPROF OPTIONAL
*"      ROLEAUTH STRUCTURE  /PSYNG/USERAUTH OPTIONAL
*"      FUNCTTRAN STRUCTURE  /PSYNG/FUNCTTRAN
*"      FAOBJ STRUCTURE  /PSYNG/FAOBJ2
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_GET_ROLE_SUM_DATA'.
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

  IF rem_execution <> space.  "read FM documentation
    CHECK rfcdest <> space.
    dest = rfcdest.
  ELSE.
    CONCATENATE sy-sysid sy-mandt INTO dest.
  ENDIF.

  SELECT agr_name profile INTO      "#EC CI_SEL_NESTED
                  (wa_iagrprof-agr_name, wa_iagrprof-profile)
                  FROM agr_1016.
    INSERT wa_iagrprof INTO TABLE iagrprof.
  ENDSELECT.

  REFRESH: roletcode, roleprof, roleauth.
  SORT: functtran BY tcode, faobj BY object.

  LOOP AT faobj.
    MOVE-CORRESPONDING faobj TO faobj1.
    APPEND faobj1.
  ENDLOOP.

  LOOP AT functtran.        "Get a unique list of tcodes
    ftcodes-tcode = functtran-tcode.  "in SOD matrix
    APPEND ftcodes.          "to perform binary searches
  ENDLOOP.
  SORT ftcodes.
  DELETE ADJACENT DUPLICATES FROM ftcodes.
  free : dbtstc[].
  LOOP AT functtran.
    wa_dbtstc-tcode = functtran-tcode.
    INSERT wa_dbtstc INTO TABLE dbtstc.
  ENDLOOP.

  SELECT SINGLE * FROM agr_agrs WHERE agr_name = agr_name.
  IF sy-subrc = 0.   "If role is a composite role
    SELECT * FROM agr_agrs WHERE agr_name = agr_name.
      PERFORM get_data_from_single_role TABLES
                                            roletcode
                                            roleprof
                                            roleauth
                                            ftcodes
                                            faobj
                                        USING
                                            agr_agrs-child_agr
                                            bname
                                            dest.
    ENDSELECT.
  ELSE.     "if the role is a single role
    PERFORM get_data_from_single_role TABLES
                                          roletcode
                                          roleprof
                                          roleauth
                                          ftcodes
                                          faobj
                                      USING
                                          agr_name
                                          bname
                                          dest.
  ENDIF.
  REFRESH: sagrprof, iagrprof.
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
                               USING
                                 agr_name LIKE agr_define-agr_name
                                 bname    LIKE usr02-bname
                                 dest  LIKE rfcdes-rfcdest.

*Get profile name of AGR_NAME
  SELECT profile FROM agr_1016 INTO roleprof-profile WHERE
                                    agr_name = agr_name.
    roleprof-bname = bname.
    roleprof-rfcdest = dest.
    roleprof-agr_name = agr_name.
    APPEND roleprof.
  ENDSELECT.

*Get authorization data of AGR_NAME
  SELECT * FROM agr_1251 WHERE agr_name = agr_name AND deleted = space.
    READ TABLE faobj1 WITH KEY object = agr_1251-object
         BINARY SEARCH.
    CHECK sy-subrc = 0.
    IF agr_1251-low+0(1) <> '$'.    "if field is not org level
      roleauth-bname    = bname.
      roleauth-rfcdest  = dest.
      roleauth-objct    = agr_1251-object.
      roleauth-auth     = agr_1251-auth.
      roleauth-field    = agr_1251-field.
      roleauth-von      = agr_1251-low.
      roleauth-bis      = agr_1251-high.
      roleauth-agr_name = agr_name.
      roleauth-profn    = ''.
      APPEND roleauth.
    ELSE.                             "if field is org level
      SELECT * FROM agr_1252 WHERE agr_name = agr_name AND
                                      varbl = agr_1251-low.
        roleauth-bname    = bname.
        roleauth-rfcdest  = dest.
        roleauth-objct    = agr_1251-object.
        roleauth-auth     = agr_1251-auth.
        roleauth-field    = agr_1251-field.
        roleauth-von      = agr_1252-low.
        roleauth-bis      = agr_1252-high.
        roleauth-agr_name = agr_name.
        roleauth-profn    = ''.
        APPEND roleauth.
      ENDSELECT.
    ENDIF.
  ENDSELECT.
  LOOP AT roleauth WHERE profn = space.
    LOOP AT roleprof WHERE agr_name = roleauth-agr_name.
      roleauth-profn = roleprof-profile.
    ENDLOOP.
    MODIFY roleauth.
  ENDLOOP.

*Get tcodes of AGR_NAME
  LOOP AT roleprof WHERE bname = bname.
    SELECT * FROM ust10s                         "#EC CI_SEL_NESTED
            WHERE profn LIKE roleprof-profile AND
                               objct = 'S_TCODE'.
      SELECT * FROM ust12
                          WHERE objct = 'S_TCODE'
                          AND auth = ust10s-auth
                          AND field = 'TCD'.
        fr_low = ust12-von.
        to_high = ust12-bis.
        PERFORM fill_tcodes
                          TABLES roletcode ftcodes
                          USING bname dest.
      ENDSELECT.
    ENDSELECT.
  ENDLOOP.
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
                              dest LIKE rfcdes-rfcdest.
  roletcode-bname = bname.
  first_char = fr_low.
  IF first_char = '*'.                     "If auth has "*" get all
*    SELECT * FROM tstct WHERE sprsl = 'E'. "tcodes defined in system
     loop at dbtstc. "tcodes defined in system (/psyng/functtran)
      READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode BINARY SEARCH.
      CHECK sy-subrc = 0.
      roletcode-tcode   = dbtstc-tcode.
      roletcode-auth    = ust12-auth.
      roletcode-profn   = ust10s-profn.
      roletcode-rfcdest = dest.
      LOOP AT iagrprof WHERE profile = ust10s-profn.
        roletcode-agr_name = iagrprof-agr_name.
        CONTINUE.
      ENDLOOP.
      APPEND roletcode.
*    ENDSELECT.
     ENDLOOP.
  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range
*      SELECT * FROM tstct
*          WHERE tcode >= fr_low AND tcode <= to_high AND sprsl = 'E'.
      loop at dbtstc WHERE tcode >= fr_low  AND tcode <= to_high. "#EC CI_SORTSEQ

        READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode BINARY SEARCH.
        CHECK sy-subrc = 0.
        roletcode-tcode   = dbtstc-tcode.
        roletcode-auth    = ust12-auth.
        roletcode-profn   = ust10s-profn.
        roletcode-rfcdest = dest.
        LOOP AT iagrprof WHERE profile = ust10s-profn.
          roletcode-agr_name = iagrprof-agr_name.
          CONTINUE.
        ENDLOOP.
        APPEND roletcode.
*      ENDSELECT.
      ENDLOOP.
      REPLACE '*' WITH '%' INTO to_high.   "If auth 'TO' ends with '*'
      IF sy-subrc = 0.                    "get all transactions begining
*        SELECT * FROM tstct                "with PREFIX text
*            WHERE tcode LIKE to_high AND sprsl = 'E'.
      LOOP AT dbtstc WHERE tcode CP to_high. "#EC CI_SORTSEQ

          READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode
                                                BINARY SEARCH.
          CHECK sy-subrc = 0.
          roletcode-tcode   = dbtstc-tcode.
          roletcode-auth    = ust12-auth.
          roletcode-profn   = ust10s-profn.
          roletcode-rfcdest = dest.
          LOOP AT iagrprof WHERE profile = ust10s-profn.
            roletcode-agr_name = iagrprof-agr_name.
            CONTINUE.
          ENDLOOP.
          APPEND roletcode.
*        ENDSELECT.
      ENDLOOP.
      ENDIF.
      REPLACE '*' WITH '%' INTO fr_low.    "If auth 'FROM' ends with '*'
      IF sy-subrc = 0.                    "get all transactions begining
*        SELECT * FROM tstct               "with PREFIX text
*        WHERE tcode LIKE fr_low AND sprsl = 'E'..
        LOOP AT dbtstc "#EC CI_SORTSEQ
           WHERE tcode CP fr_low.

          READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode
                                                BINARY SEARCH.
          CHECK sy-subrc = 0.
          roletcode-tcode   = dbtstc-tcode.
          roletcode-auth    = ust12-auth.
          roletcode-profn   = ust10s-profn.
          roletcode-rfcdest = dest.
          LOOP AT iagrprof WHERE profile = ust10s-profn.
            roletcode-agr_name = iagrprof-agr_name.
            CONTINUE.
          ENDLOOP.
          APPEND roletcode.
*        ENDSELECT.
      ENDLOOP.
      ENDIF.
    ELSE.               "If auth has a starting char with * following it
      REPLACE '*' WITH '%' INTO fr_low.
      IF sy-subrc = 0.
*        SELECT * FROM tstct WHERE tcode LIKE fr_low AND sprsl = 'E'..
        LOOP AT dbtstc WHERE tcode CP fr_low. "#EC CI_SORTSEQ

          READ TABLE ftcodes WITH KEY tcode = tstct-tcode
                                                BINARY SEARCH.
          CHECK sy-subrc = 0.
          roletcode-tcode = dbtstc-tcode.
          roletcode-auth  = ust12-auth.
          roletcode-profn = ust10s-profn.
          roletcode-rfcdest = dest.
          LOOP AT iagrprof WHERE profile = ust10s-profn.
            roletcode-agr_name = iagrprof-agr_name.
            CONTINUE.
          ENDLOOP.
          APPEND roletcode.
*        ENDSELECT.
        ENDLOOP.
      ELSE.                "If specific transaction is specified
*        SELECT SINGLE * FROM tstct WHERE tcode = ust12-von AND
*                                         sprsl = 'E'.
        READ TABLE dbtstc WITH KEY tcode = ust12-von BINARY SEARCH.

        CHECK sy-subrc = 0.
        READ TABLE ftcodes WITH KEY tcode = dbtstc-tcode
                                                BINARY SEARCH.
        CHECK sy-subrc = 0.
        roletcode-tcode = dbtstc-tcode.
        roletcode-auth  = ust12-auth.
        roletcode-profn = ust10s-profn.
        roletcode-rfcdest = dest.
        LOOP AT iagrprof WHERE profile = ust10s-profn.
          roletcode-agr_name = iagrprof-agr_name.
          CONTINUE.
        ENDLOOP.
        APPEND roletcode.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TCODES
