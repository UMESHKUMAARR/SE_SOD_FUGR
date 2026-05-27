*----------------------------------------------------------------------*
* FUNCTION MODULE       : /PSYNG/SW_EXELOG
* AUTHOR                : Security Weaver LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
FUNCTION /psyng/sw_updt_cri_auth_info.
*"----------------------------------------------------------------------
*"*"Local Interface:
*"  IMPORTING
*"     VALUE(NODELETE) TYPE  CHAR01 OPTIONAL
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"     VALUE(I_VALIDUSER) TYPE  FLAG OPTIONAL
*"     VALUE(I_REMOTE_ONLY) TYPE  FLAG OPTIONAL
*"  TABLES
*"      IUSR02 STRUCTURE  USR02
*"      USERHAS STRUCTURE  /PSYNG/SW_USHAS
*"      RFCDES STRUCTURE  RFCDES OPTIONAL
*"      USERMAPPING STRUCTURE  /PSYNG/SW_USER_MAPPING OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_UPDT_CRI_AUTH_INFO'.
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
  DATA: wa LIKE /psyng/syscandt,
        count TYPE i,
        dusr02        TYPE usr02           OCCURS 0 WITH HEADER LINE,
        wa_dusr02     TYPE usr02,
        del_1 TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        del_2 TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        cratdt      TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        cratdt1     TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        cratdt2     TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        wa_cratdt2  TYPE /psyng/sw_cratdt,
        gt_cratdt   TYPE /psyng/sw_cratdt OCCURS 0 WITH HEADER LINE,
        wa_cratdt   TYPE /psyng/sw_cratdt,
        commitcount TYPE i VALUE '5000', "database commit counter
        loopcount   TYPE i,  "loop counter
        records TYPE i,     "number of records in internal table
        ls_config  TYPE /psyng/swconfig,
        lf_verify_users TYPE flag.

*******************************************************
*Decide if users will be verified against the Local user master record
*******************************************************
  se_config_param 'SCAN_NO_VERIFICATION' ls_config-value.

  IF ls_config-value = 'Y'.
    CLEAR lf_verify_users.
  ELSE.
    lf_verify_users = 'X'.
  ENDIF.


  LOOP AT userhas.
    AT NEW bname.
      del_1-bname = userhas-bname.
      del_1-vrsio = vrsio.
      APPEND del_1.       "collect unique IDs
    ENDAT.
  ENDLOOP.

  IF nodelete EQ space.          "don't delete all records of users if
    SORT del_1.                  "specific conflicts were queried
    DELETE ADJACENT DUPLICATES FROM del_1.
    IF NOT del_1[] IS INITIAL.
      SELECT * FROM /psyng/sw_cratdt "#EC CI_SEL_NESTED
               APPENDING TABLE del_2       "get all records of
               FOR ALL ENTRIES IN del_1 WHERE bname = del_1-bname
               AND vrsio = vrsio.
    ENDIF.
    REFRESH: del_1.
    SORT del_2.
    DELETE ADJACENT DUPLICATES FROM del_2.

    IF NOT del_2[] IS INITIAL.
*************
* Commit every COMMITCOUNT records
      DESCRIBE TABLE del_2 LINES records.
      IF records LE commitcount.
        DELETE /psyng/sw_cratdt FROM TABLE del_2.   "#EC CI_IMUD_NESTED
        COMMIT WORK.
      ELSE.
        REFRESH del_1. CLEAR del_1.
        LOOP AT del_2.
          loopcount = loopcount + 1.
          APPEND del_2 TO del_1.
          DELETE del_2.
          IF loopcount GE commitcount.
            DELETE /psyng/sw_cratdt        "#EC CI_IMUD_NESTED
                 FROM TABLE del_1.
            COMMIT WORK.
            REFRESH del_1.
            CLEAR: loopcount,  del_1.
          ENDIF.
        ENDLOOP.
        IF NOT del_1[] IS INITIAL.
          DELETE /psyng/sw_cratdt FROM TABLE del_1.  "#EC CI_IMUD_NESTED
          COMMIT WORK.
          REFRESH del_1.
          CLEAR: del_1, loopcount, records.
        ENDIF.
      ENDIF.   "records LE commitcount
    ENDIF.     "del_2[] is not initial
  ENDIF.      "nodelete EQ space.
  REFRESH: del_2, del_1.

  LOOP AT userhas.
    MOVE-CORRESPONDING userhas TO cratdt.
    cratdt-vrsio    = vrsio.
    cratdt-scandate = sy-datum.
    cratdt-mandt    = sy-mandt.
    APPEND cratdt.
  ENDLOOP.

*************
* Commit every COMMITCOUNT records

*********Added by sgottapu*******************

  SORT cratdt BY mandt bname vrsio swaudid scandate.
  DELETE ADJACENT DUPLICATES FROM cratdt COMPARING ALL FIELDS.

  SELECT * FROM /psyng/sw_cratdt     "#EC CI_SEL_NESTED
           INTO TABLE gt_cratdt
           where vrsio = VRSIO.

  SORT gt_cratdt BY mandt bname vrsio swaudid scandate.
  LOOP AT cratdt INTO wa_cratdt.
    READ TABLE gt_cratdt WITH KEY bname = wa_cratdt-bname
                                  vrsio = wa_cratdt-vrsio
                                  swaudid = wa_cratdt-swaudid
                                  scandate = wa_cratdt-scandate
                                 BINARY SEARCH TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    DELETE TABLE cratdt FROM wa_cratdt.
  ENDLOOP.

  CLEAR wa_cratdt.

*********Added by sgottapu*******************

  DESCRIBE TABLE  cratdt LINES records.
  IF records LE commitcount.
    INSERT /psyng/sw_cratdt FROM TABLE cratdt. "#EC CI_IMUD_NESTED
    COMMIT WORK.
  ELSE.
    REFRESH  cratdt1. CLEAR  cratdt1.
    LOOP AT cratdt.
      loopcount = loopcount + 1.
      APPEND cratdt TO cratdt1.
      IF loopcount GE commitcount.
        INSERT /psyng/sw_cratdt FROM TABLE cratdt1. "#EC CI_IMUD_NESTED
        COMMIT WORK.
        REFRESH cratdt1. CLEAR cratdt1.
        CLEAR loopcount.
      ENDIF.
    ENDLOOP.
    IF NOT cratdt1[] IS INITIAL.
      INSERT /psyng/sw_cratdt FROM TABLE cratdt1. "#EC CI_IMUD_NESTED
      COMMIT WORK.
      REFRESH cratdt1.
      CLEAR: cratdt1, loopcount, records.
    ENDIF.
  ENDIF.   "records LE commitcount

  REFRESH: cratdt.

* Check to see if there are records in this table for users that
* don't exist any longer.
  IF lf_verify_users = 'X'.
    SELECT DISTINCT bname FROM /psyng/sw_cratdt    "#EC CI_SEL_NESTED
          INTO CORRESPONDING FIELDS OF TABLE cratdt2
          WHERE vrsio = vrsio
          ORDER BY bname.

    CHECK NOT cratdt2[] IS INITIAL.

    SELECT DISTINCT bname FROM usr02             "#EC CI_SEL_NESTED
           INTO CORRESPONDING FIELDS OF TABLE dusr02
           ORDER BY bname.

    SORT: dusr02 BY bname, cratdt2 BY bname.
    DELETE ADJACENT DUPLICATES FROM cratdt2.
    DELETE ADJACENT DUPLICATES FROM iusr02.

    LOOP AT cratdt2.
      READ TABLE dusr02 WITH KEY bname = cratdt2-bname
                 BINARY SEARCH TRANSPORTING NO FIELDS.

      IF sy-subrc = 0.  "user still exists in the system
        DELETE cratdt2.
      ENDIF.
    ENDLOOP.
    REFRESH: dusr02.

    CHECK NOT cratdt2[] IS INITIAL.
    SELECT * FROM /psyng/sw_cratdt              "#EC CI_SEL_NESTED
             INTO CORRESPONDING FIELDS OF TABLE del_1
             FOR ALL ENTRIES IN cratdt2 WHERE bname = cratdt2-bname
             AND vrsio = vrsio.
    REFRESH cratdt2.

    CHECK NOT del_1 IS INITIAL.

*************
* Commit every COMMITCOUNT records
    DESCRIBE TABLE del_1 LINES records.
    IF records LE commitcount.
      DELETE /psyng/sw_cratdt FROM TABLE del_1.    "#EC CI_IMUD_NESTED
      COMMIT WORK.
    ELSE.
      REFRESH del_2. CLEAR del_2.
      LOOP AT del_1.
        loopcount = loopcount + 1.
        APPEND del_1 TO del_2.
        DELETE del_1.
        IF loopcount GE commitcount.
          DELETE /psyng/sw_cratdt FROM TABLE del_2.  "#EC CI_IMUD_NESTED
          COMMIT WORK.
          REFRESH del_2.
          CLEAR: loopcount, del_2.
        ENDIF.
      ENDLOOP.
      IF NOT del_2[] IS INITIAL.
        DELETE /psyng/sw_cratdt FROM TABLE del_2.    "#EC CI_IMUD_NESTED
        COMMIT WORK.
        REFRESH del_2.
        CLEAR: del_2, loopcount, records.
      ENDIF.
    ENDIF.   "records LE commitcount
  ENDIF.



ENDFUNCTION.
