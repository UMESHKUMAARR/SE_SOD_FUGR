*----------------------------------------------------------------------*
* FUNCTION MODULE       : /PSYNG/SW_UPDATE_SYS_SCAN_INFO
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /PSYNG/SW_UPDATE_SYS_SCAN_INF2.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(NODELETE) TYPE  CHAR01 OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  TABLES
*"      SYSCANDT STRUCTURE  /PSYNG/SYSCANDT2
*"      RFCDES STRUCTURE  RFCDES OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_UPDATE_SYS_SCAN_INF2'.
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
  DATA: wa LIKE /psyng/syscandt2,
        count TYPE i,
        del_syscandt1 TYPE /psyng/syscandt2 OCCURS 0 WITH HEADER LINE,
        del_syscandt2 TYPE /psyng/syscandt2 OCCURS 0 WITH HEADER LINE,
        conflict      TYPE /psyng/conflict OCCURS 0 WITH HEADER LINE,
        syscandt3     TYPE /psyng/syscandt2 OCCURS 0 WITH HEADER LINE,
        iusr02        TYPE usr02           OCCURS 0 WITH HEADER LINE,
        wa_iusr02     TYPE usr02,
        syscandt4     TYPE /psyng/syscandt2 OCCURS 0 WITH HEADER LINE,
        wa_syscandt4  TYPE /psyng/syscandt2,
        commitcount TYPE i VALUE '5000', "database commit counter
        loopcount   TYPE i,  "loop counter
        records TYPE i.     "number of records in internal table

  LOOP AT syscandt.
    AT NEW agr_name.
      del_syscandt1-agr_name = syscandt-agr_name.
      APPEND del_syscandt1.       "collect unique IDs
    ENDAT.
    IF syscandt-conid = '----'.
      DELETE syscandt.      "remove records if user has no conflicts
    ENDIF.
  ENDLOOP.

  IF nodelete EQ space.          "don't delete all records of users if
    SORT del_syscandt1.          "specific conflicts were queried
    DELETE ADJACENT DUPLICATES FROM del_syscandt1.

    LOOP AT del_syscandt1.
      SELECT * FROM /psyng/syscandt2    "get all records of
               APPENDING TABLE del_syscandt2     "#EC CI_SEL_NESTED
               WHERE agr_name = del_syscandt1-agr_name
               AND   VRSIO    = vrsio.
    ENDLOOP.
    REFRESH: del_syscandt1.
    SORT del_syscandt2.
    DELETE ADJACENT DUPLICATES FROM del_syscandt2.

*************
* Commit every COMMITCOUNT records
    DESCRIBE TABLE del_syscandt2 LINES records.
    IF records LE commitcount.
      DELETE /psyng/syscandt2 FROM TABLE del_syscandt2.
      COMMIT WORK.
    ELSE.
      REFRESH del_syscandt1. CLEAR del_syscandt1.
      LOOP AT del_syscandt2.
        loopcount = loopcount + 1.
        APPEND del_syscandt2 TO del_syscandt1.
        DELETE del_syscandt2.
        IF loopcount GE commitcount.
          DELETE /psyng/syscandt2              "#EC CI_IMUD_NESTED
               FROM TABLE del_syscandt1.
          COMMIT WORK.
          REFRESH del_syscandt1. CLEAR del_syscandt1.
          CLEAR loopcount.
        ENDIF.
      ENDLOOP.
      IF NOT del_syscandt1[] IS INITIAL.
        DELETE /psyng/syscandt2 FROM TABLE del_syscandt1.
        COMMIT WORK.
        REFRESH del_syscandt1.
        CLEAR: del_syscandt1, loopcount, records.
      ENDIF.
    ENDIF.   "records LE commitcount
  ENDIF.   "nodelete EQ space.
  REFRESH: del_syscandt2, del_syscandt1.
  CLEAR:   del_syscandt2, del_syscandt1.

  wa-scandate = sy-datum.
  MODIFY syscandt FROM wa TRANSPORTING scandate
               WHERE agr_name NE space AND
               VRSIO = vrsio.

  SELECT * FROM /psyng/conflict INTO TABLE conflict
  WHERE vrsio = vrsio.
  syscandt3[] = syscandt[].

  DELETE syscandt WHERE conid = 'ALL'.

  LOOP AT syscandt3 WHERE conid = 'ALL'.
    LOOP AT conflict.
      syscandt-agr_name = syscandt3-agr_name.
      syscandt-scandate = sy-datum.
      syscandt-conid = conflict-conid.
      APPEND syscandt.
    ENDLOOP.
  ENDLOOP.
  REFRESH syscandt3. CLEAR: syscandt3.
  SORT syscandt.
  DELETE ADJACENT DUPLICATES FROM syscandt.

*************
* Commit every COMMITCOUNT records
  DESCRIBE TABLE syscandt LINES records.
  IF records LE commitcount.
    MODIFY /psyng/syscandt2 FROM TABLE syscandt.
    COMMIT WORK.
  ELSE.
    REFRESH syscandt3. CLEAR syscandt3.
    LOOP AT syscandt.
      loopcount = loopcount + 1.
      APPEND syscandt TO syscandt3.
      IF loopcount GE commitcount.
        MODIFY /psyng/syscandt2             "#EC CI_IMUD_NESTED
                FROM TABLE syscandt3.
        COMMIT WORK.
        REFRESH syscandt3. CLEAR syscandt3.
        CLEAR loopcount.
      ENDIF.
    ENDLOOP.
    IF NOT syscandt3[] IS INITIAL.
*      INSERT /psyng/syscandt2 FROM TABLE syscandt3.
      MODIFY /psyng/syscandt2 FROM TABLE syscandt3.
      COMMIT WORK.
      REFRESH syscandt3.
      CLEAR: syscandt3, loopcount, records.
    ENDIF.
  ENDIF.   "records LE commitcount
ENDFUNCTION.
