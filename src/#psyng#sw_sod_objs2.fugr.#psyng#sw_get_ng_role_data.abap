FUNCTION /psyng/sw_get_ng_role_data.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(AGR_NAME) LIKE  AGR_DEFINE-AGR_NAME
*"     VALUE(BNAME) LIKE  USR02-BNAME OPTIONAL
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
        VALUE '/PSYNG/SW_GET_NG_ROLE_DATA'.
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

  REFRESH: roletcode, roleprof, roleauth.
  SORT: functtran BY tcode, faobj BY object.

  bname = '000000000000'. "#EC SAST_CI_GEN_CHECK
  LOOP AT faobj.
    MOVE-CORRESPONDING faobj TO faobj1.
    APPEND faobj1.
  ENDLOOP.

  SORT functtran.
  LOOP AT functtran.        "Get a unique list of tcodes
    ftcodes-tcode = functtran-tcode.  "in SOD matrix
    APPEND ftcodes.          "to perform binary searches
  ENDLOOP.
  SORT ftcodes.
  DELETE ADJACENT DUPLICATES FROM ftcodes.

  SELECT SINGLE * FROM agr_agrs WHERE agr_name = agr_name.
  IF sy-subrc = 0.   "If role is a composite role
    SELECT * FROM agr_agrs WHERE agr_name = agr_name
                           AND attributes <> 'X'.
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

*Get tcodes of AGR_NAME
  SELECT * FROM agr_1251
                      WHERE agr_name = agr_name AND
                      object = 'S_TCODE' AND
                      field = 'TCD'.
    fr_low = agr_1251-low.
    to_high = agr_1251-high.
    PERFORM fill_tcodes
                      TABLES roletcode ftcodes
                      USING bname dest.
  ENDSELECT.
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
    LOOP AT ftcodes.
      roletcode-tcode   = ftcodes-tcode.
      roletcode-auth    = agr_1251-auth.
      roletcode-profn   = agr_1251-auth(10).
      roletcode-agr_name = agr_1251-agr_name.
      roletcode-rfcdest = dest.
      APPEND roletcode.
    ENDLOOP.
  ELSE.
    IF fr_low > space AND to_high > space. "If auth has range
      LOOP AT ftcodes
        WHERE tcode >= fr_low AND tcode <= to_high.
        roletcode-tcode   = ftcodes-tcode.
        roletcode-auth    = agr_1251-auth.
        roletcode-profn   = agr_1251-auth(10).
        roletcode-agr_name = agr_1251-agr_name.
        roletcode-rfcdest = dest.
        APPEND roletcode.
      ENDLOOP.
      IF to_high CS '*'.           "get all transactions begining
        LOOP AT ftcodes WHERE tcode CP to_high.
          roletcode-tcode   = ftcodes-tcode.
          roletcode-auth    = agr_1251-auth.
          roletcode-profn   = agr_1251-auth(10).
          roletcode-agr_name = agr_1251-agr_name.
          roletcode-rfcdest = dest.
          APPEND roletcode.
        ENDLOOP.
      ENDIF.
      IF fr_low CS '*'.             "get all transactions begining
        LOOP AT ftcodes WHERE tcode CP fr_low.
          roletcode-tcode   = ftcodes-tcode.
          roletcode-auth    = agr_1251-auth.
          roletcode-profn   = agr_1251-auth(10).
          roletcode-agr_name = agr_1251-agr_name.
          roletcode-rfcdest = dest.
          APPEND roletcode.
        ENDLOOP.
      ENDIF.
    ELSE.               "If auth has a starting char with * following it
      IF fr_low CS '*'.             "get all transactions begining
        LOOP AT ftcodes WHERE tcode CP fr_low.
          roletcode-tcode   = ftcodes-tcode.
          roletcode-auth    = agr_1251-auth.
          roletcode-profn   = agr_1251-auth(10).
          roletcode-agr_name = agr_1251-agr_name.
          roletcode-rfcdest = dest.
          APPEND roletcode.
        ENDLOOP.
      ELSE.                "If specific transaction is specified
        READ TABLE ftcodes WITH KEY tcode = fr_low BINARY SEARCH.
*             TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        roletcode-tcode   = ftcodes-tcode.
        roletcode-auth    = agr_1251-auth.
        roletcode-profn   = agr_1251-auth(10).
        roletcode-agr_name = agr_1251-agr_name.
        roletcode-rfcdest = dest.
        APPEND roletcode.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TCODES
