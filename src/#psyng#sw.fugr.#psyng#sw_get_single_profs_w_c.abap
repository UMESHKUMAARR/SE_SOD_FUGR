*&---------------------------------------------------------------------*
*&      FUNCTION  /PSYNG/SW_GET_SINGLE_PROFS_W_C
*&---------------------------------------------------------------------*
*       This form is used to get all sub-profiles of any given profile.
*       This form takes the profile name PROFNAME and compiles all
*       single profiles that it contains, even if the single profiles
*       are in other composite profiles.  Once compiled it populates
*       that profile list in an inernal table called PROFINFO.  If the
*       profile provided is a single profile, it will return the single
*       profile in PROFINFO.
*   The way /PSYNG/SW_GET_SINGLE_PROFS_W_C differs from
*   /PSYNG/SW_GET_SINGLE_PROFS is that /PSYNG/SW_GET_SINGLE_PROFS_W_C
*   also returns the composite profile names.
*----------------------------------------------------------------------*
*  -->  PROFNAME  Profile name (Single or Composite)
*  <--  PROFINFO  Internal table populated with profile names contained
*                 in the profile provided in PROFNAME parameter
*----------------------------------------------------------------------*
FUNCTION /PSYNG/SW_GET_SINGLE_PROFS_W_C.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     REFERENCE(PROFNAME) LIKE  UST04-PROFILE
*"  TABLES
*"      PROFINFO STRUCTURE  /PSYNG/PROFINFO
*"----------------------------------------------------------------------

data: begin of cprof occurs 0.
        include structure /psyng/profinfo.
data: end of cprof.

*Check if profile is a composite profile, if so get all sub profiles
  SELECT SINGLE * FROM ust10c WHERE profn = profname.
  IF sy-subrc = 0.
    SELECT * FROM ust10c WHERE profn = profname.
      profinfo-profn = ust10c-subprof. "get all sub profiles
      profinfo-composite = 'Y'.
      APPEND profinfo.
    ENDSELECT.
    cprof-profn = profname.
    append cprof.
  ELSE.     "if there is no entry for profile in composite table
    profinfo-profn = profname. "Add the sub profile
    APPEND profinfo.
  ENDIF.

  profinfo2[] = profinfo[].

  WHILE table1done = space AND table2done = space.
* Loop on 1st table and add/delete data from 2nd table
    LOOP AT profinfo WHERE composite = 'Y'. "only loop at comp profiles
      SELECT SINGLE * FROM ust10c WHERE profn = profinfo-profn.
      IF sy-subrc = 0.            "if the sub profile is also composite
        SELECT * FROM ust10c WHERE profn = profinfo-profn.
          READ TABLE profinfo2 WITH KEY profn = ust10c-subprof. "no dups
          IF sy-subrc <> 0.         "only append if profile is not there
            profinfo2-profn = ust10c-subprof. "get the sub profiles
            profinfo2-composite = 'Y'.  "assume sub profile is also comp
            APPEND profinfo2.
          ENDIF.
        ENDSELECT.
        clear cprof.
        cprof-profn = profinfo-profn.  "capture composite profile name
        append cprof.
        DELETE profinfo.   "remove the composite entry from table
      ELSE.     "if there is no entry for profile in composite table
        profinfo-composite = ' '.
        MODIFY profinfo.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.   "No more composites
      table1done = 'Y'.
    ENDIF.

* Do the same (but exact opposite) logic again on the second table
* Loop at 2nd table and add/delete data from 1st table
    LOOP AT profinfo2 WHERE composite = 'Y'.
      SELECT SINGLE * FROM ust10c WHERE profn = profinfo2-profn.
      IF sy-subrc = 0.
        SELECT * FROM ust10c WHERE profn = profinfo2-profn.
          READ TABLE profinfo WITH KEY profn = ust10c-subprof.
          IF sy-subrc <> 0.
            profinfo-profn = ust10c-subprof.
            profinfo-composite = 'Y'.
            APPEND profinfo.
          ENDIF.
        ENDSELECT.
        clear cprof.
        cprof-profn = profinfo2-profn.
        append cprof.
        DELETE profinfo2.
      ELSE.
        profinfo2-composite = ' '.
        MODIFY profinfo2.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      table2done = 'Y'.
    ENDIF.

  ENDWHILE.

  sort cprof.
  delete adjacent duplicates from cprof.
  append lines of cprof to profinfo.
ENDFUNCTION.
