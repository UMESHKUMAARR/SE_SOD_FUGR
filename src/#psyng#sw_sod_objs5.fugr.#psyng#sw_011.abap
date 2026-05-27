*----------------------------------------------------------------------*
* FUNCTION              : /PSYNG/SW_011
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
*SW: Read & Summarize SOD Scan Summary
*&----------------------------------------------------------------------
FUNCTION /psyng/sw_011.
*"----------------------------------------------------------------------
*"*"Local interface:
*"  IMPORTING
*"     VALUE(VRSIO) TYPE  /PSYNG/SODVRSIO OPTIONAL
*"  EXPORTING
*"     VALUE(SYSID) LIKE  SY-SYSID
*"     VALUE(MANDT) LIKE  SY-MANDT
*"     VALUE(UA_COUNT) TYPE  /PSYNG/SW_COUNT
*"     VALUE(U_COUNT) TYPE  /PSYNG/SW_COUNT
*"     VALUE(SODA_COUNT) TYPE  /PSYNG/SW_SOD_CONFLICT_COUNT
*"     VALUE(SOD_COUNT) TYPE  /PSYNG/SW_SOD_CONFLICT_COUNT
*"     VALUE(OLDSTA_DATE) TYPE  DATUM
*"     VALUE(OLDST_DATE) TYPE  DATUM
*"  TABLES
*"      CONS STRUCTURE  /PSYNG/SW_SUM_CONS OPTIONAL
*"      USERS STRUCTURE  /PSYNG/SW_SUM_USERS OPTIONAL
*"      UGROUPS STRUCTURE  /PSYNG/SW_SUM_UGROUP OPTIONAL
*"----------------------------------------------------------------------
*BOC:UMITTAL CVA scan fix 27/02/2026
CONSTANTS: lc_fname TYPE rs38l_fnam
        VALUE '/PSYNG/SW_011'.
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
  DATA: lt_usr02 TYPE HASHED TABLE OF usr02 WITH UNIQUE KEY bname
        WITH HEADER LINE.
  DATA: lt_usr02t TYPE STANDARD TABLE OF usr02
        WITH HEADER LINE.
  DATA: wa_usr02 TYPE usr02.
  DATA: lt_syscandt TYPE SORTED TABLE OF /psyng/syscandt
         WITH UNIQUE KEY bname conid scandate
         WITH HEADER LINE.
  DATA: wa_syscandt TYPE /psyng/syscandt.

  DATA: lt_users TYPE SORTED TABLE OF /psyng/sw_sum_users
        WITH UNIQUE KEY bname
        WITH HEADER LINE.
  DATA: wa_users TYPE /psyng/sw_sum_users.

  DATA: lt_cons TYPE SORTED TABLE OF /psyng/sw_sum_cons
        WITH UNIQUE KEY conid
        WITH HEADER LINE.
  DATA: wa_cons TYPE /psyng/sw_sum_cons.

  DATA: lt_ugroups TYPE SORTED TABLE OF /psyng/sw_sum_ugroup
        WITH UNIQUE KEY class
        WITH HEADER LINE.
  DATA: wa_ugroups TYPE /psyng/sw_sum_ugroup.

  DATA: count TYPE /psyng/sw_count.    "generic counter
  DATA: totalconflicts TYPE /psyng/sw_count. "total SOD conflicts
  DATA: conflicts TYPE /psyng/sw_count. "SOD conflicts counter
  DATA: test TYPE /psyng/sw_count. "dummy counter.
DATA:   YULOCK   TYPE X VALUE '80',     "Locked by incorrect login
        YUSLOC   TYPE X VALUE '40',     "Locked by Administrator
        YUGLOC   TYPE X VALUE '20'.     "Locked by global Administrator
data : l_uflagx type x.

  sysid = sy-sysid.
  mandt = sy-mandt.

  SELECT bname gltgv gltgb ustyp class uflag
         INTO CORRESPONDING FIELDS OF TABLE lt_usr02t
         FROM usr02 ORDER BY bname.
  SELECT * FROM /psyng/syscandt
           INTO CORRESPONDING FIELDS OF TABLE lt_syscandt
           WHERE vrsio = vrsio.

  SELECT COUNT( * ) INTO totalconflicts
         FROM /psyng/conflict WHERE inactive IS null.

  SELECT COUNT( DISTINCT bname ) INTO test
         FROM /psyng/syscandt
         where vrsio = vrsio.

  LOOP AT lt_usr02t.
*--SF CASE 1405
     l_uflagx = lt_usr02t-uflag.
     IF l_uflagx O yusloc OR "locked by admin
        l_uflagx O yugloc.   "locked by CUA admin
        lt_usr02t-accnt = 'X'.         "not dialog or valid
     endif.
*    IF lt_usr02t-uflag >= 64.        "user locked
*      lt_usr02t-accnt = 'X'.         "not dialog or valid
*    ENDIF.
    IF lt_usr02t-ustyp <> 'A'.       "user not dialog
      lt_usr02t-accnt = 'X'.         "not dialog or valid
    ENDIF.
    IF lt_usr02t-gltgv >= sy-datum . "valid from greater than today
      lt_usr02t-accnt = 'X'.         "not dialog or valid
    ENDIF.
    IF lt_usr02t-gltgb <= sy-datum AND "valid to less than today
       NOT ( lt_usr02t-gltgb IS INITIAL ) .
      lt_usr02t-accnt = 'X'.         "not dialog or valid
    ENDIF.

    u_count = u_count + 1.
    IF lt_usr02t-accnt IS INITIAL.
      ua_count = ua_count + 1.
    ENDIF.

    MODIFY lt_usr02t.
  ENDLOOP.

  SORT lt_usr02t BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_usr02t COMPARING bname.
  lt_usr02[] = lt_usr02t[].
  REFRESH: lt_usr02t.

  oldst_date  = '99991231'.
  oldsta_date = '99991231'.

  LOOP AT lt_syscandt.
    CHECK lt_syscandt-conid NE 'NONE'.
    READ TABLE lt_usr02 WITH TABLE KEY bname = lt_syscandt-bname.
    CHECK sy-subrc = 0 .
    IF lt_syscandt-conid = 'ALL'.
      conflicts = totalconflicts.
    ELSE.
      conflicts = 1.
    ENDIF.

    sod_count = sod_count + conflicts.
    IF lt_usr02-accnt = 'X' AND      "not dialog or valid
       oldst_date > lt_syscandt-scandate.
      oldst_date = lt_syscandt-scandate.
    ENDIF.

    IF lt_usr02-accnt IS INITIAL.    "user dialog & valid
      soda_count = soda_count + conflicts.
      IF oldsta_date > lt_syscandt-scandate.
        oldsta_date = lt_syscandt-scandate.
      ENDIF.

*     Summarize for Users
      READ TABLE lt_users WITH TABLE KEY bname = lt_syscandt-bname.
      IF sy-subrc = 0.
        lt_users-sod_count = lt_users-sod_count + conflicts.
        MODIFY lt_users TRANSPORTING sod_count
               WHERE bname = lt_syscandt-bname.
      ELSE.
        wa_users-bname = lt_syscandt-bname.
        wa_users-sod_count = conflicts.
        INSERT wa_users INTO TABLE lt_users.
      ENDIF.

*     Summarize for Conflict IDs
      READ TABLE lt_cons WITH TABLE KEY conid = lt_syscandt-conid.
      IF sy-subrc = 0.
        lt_cons-user_count = lt_cons-user_count + conflicts.
        MODIFY lt_cons TRANSPORTING user_count
               WHERE conid = lt_syscandt-conid.
      ELSE.
        wa_cons-conid = lt_syscandt-conid.
        wa_cons-user_count = conflicts.
        INSERT wa_cons INTO TABLE lt_cons.
      ENDIF.

*     Summarize for User Groups
      READ TABLE lt_usr02 WITH TABLE KEY bname = lt_syscandt-bname.
      IF NOT lt_usr02-class IS INITIAL.
        READ TABLE lt_ugroups WITH TABLE KEY class = lt_usr02-class.
        IF sy-subrc = 0.
          lt_ugroups-sod_count = lt_ugroups-sod_count + conflicts.
          MODIFY lt_ugroups TRANSPORTING sod_count
                 WHERE class = lt_usr02-class.
        ELSE.
          wa_ugroups-class = lt_usr02-class.
          wa_ugroups-sod_count = conflicts.
          INSERT wa_ugroups INTO TABLE lt_ugroups.
        ENDIF.
      ENDIF.    "NOT lt_usr02-class IS INITIAL.

    ENDIF.     "IF lt_usr02-accnt IS INITIAL.

  ENDLOOP.    "lt_syscandt.

  ugroups[] = lt_ugroups[].
  cons[] = lt_cons[].
  users[] = lt_users[].

ENDFUNCTION.
