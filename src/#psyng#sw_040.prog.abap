*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_040
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
*
* COPYRIGHT Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*

REPORT /psyng/user_exe_tcode  NO STANDARD PAGE HEADING LINE-SIZE 200.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

TABLES: ust10c, ust04, ust10s, tstc,  usr02.

CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.

TYPE-POOLS: slis.                                        "For ALV call
DATA: g_program LIKE sy-repid.                             "For ALV call
DATA: i_fieldcat_alv TYPE slis_t_fieldcat_alv,           "For ALV call
     gs_alv_layout     TYPE slis_layout_alv.               "For ALV call

DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
WITH HEADER LINE.

DATA: BEGIN OF gt_months OCCURS 0.
DATA:   month LIKE sy-datum.
DATA: END OF gt_months.

DATA: BEGIN OF gt_usertcode OCCURS 0.
DATA:   bname LIKE usr02-bname,
*        month LIKE sy-datum,
        tcode LIKE tstc-tcode,
        ttext LIKE tstct-ttext,
      END OF gt_usertcode.

DATA: BEGIN OF gt_users OCCURS 10.
DATA:   bname LIKE ust04-bname,
        name LIKE adrp-name_text,
        pernr LIKE /psyng/output-pernr,
        kostl LIKE /psyng/sw_uinfo-kostl,
        persg LIKE /psyng/range_persg-low,
        werks LIKE /psyng/output-persa.
DATA: END OF gt_users.

DATA: users_temp LIKE TABLE OF gt_users WITH HEADER LINE,
g_usercount TYPE i.

DATA: g_1stmonth TYPE sy-datum,
      g_lastmont TYPE sy-datum.

TYPES: BEGIN OF usrtcode_typ,
         bname LIKE ust04-bname,
         tcode LIKE tstct-tcode,
         ttext LIKE tstct-ttext,
       END OF usrtcode_typ.
DATA: wa_usrtcode TYPE usrtcode_typ.
DATA: gt_usrtcode TYPE SORTED TABLE OF usrtcode_typ WITH UNIQUE KEY
      bname tcode WITH HEADER LINE.

DATA: gt_itstc TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode
      WITH HEADER LINE.
DATA: gt_itstct TYPE HASHED TABLE OF tstct WITH UNIQUE KEY sprsl tcode
      WITH HEADER LINE.

DATA: gt_iust12 TYPE SORTED TABLE OF ust12 WITH UNIQUE KEY
      mandt objct auth aktps field von bis
      WITH HEADER LINE.
DATA: g_itstc_idx TYPE i.

*end of performance enhancements
DATA: BEGIN OF gt_outab OCCURS 10.       "Table to contain data For ALV
DATA:   bname LIKE usr02-bname,
        name LIKE adrp-name_text,
        pernr LIKE /psyng/output-pernr,
        kostl LIKE /psyng/sw_uinfo-kostl,
        persg LIKE /psyng/range_persg-low,
        werks LIKE /psyng/output-persa,
        exe,
        tcode LIKE tstct-tcode,
        ttext LIKE tstct-ttext.
DATA: END OF gt_outab.

DATA : gf_exit_proc TYPE flag.

DATA: BEGIN OF gt_tcodestar OCCURS 10. "This table is to improve
DATA:   bname LIKE ust04-bname.     "performance when a user
DATA: END OF gt_tcodestar.             "has * for tcode

DATA: BEGIN OF gt_profinfo OCCURS 10.
DATA:   profn     LIKE ust10c-profn,
        composite TYPE c.
DATA: END OF gt_profinfo.

DATA: gt_profinfo2 LIKE gt_profinfo OCCURS 10 WITH HEADER LINE.

DATA: BEGIN OF gt_userprof OCCURS 10.
DATA:   bname LIKE ust04-bname,
        profile LIKE ust04-profile.
DATA: END OF gt_userprof.

DATA: g_first_char TYPE c, g_fr_low TYPE ust12-von,
      g_to_high TYPE ust12-von, g_done TYPE c.

DATA: g_table1done TYPE c,   "Flag for finishing 1st table
      g_table2done TYPE c.   "Flag for finishing 2nd table

DATA: g_percent TYPE f,      "Progress indicator flag
      g_records TYPE f,      "# of records in table
      g_pertext(200),        "Progress indicator text
      g_nodata VALUE 'Y',    "No data in table flag
      g_kostl                TYPE kostl,         "For select-options
      g_pernr                TYPE /psyng/pernr,  "For select-options
      g_persa                TYPE /psyng/persa,  "For select-options
      g_persg                TYPE /psyng/persg,  "For select-options
      gf_use_erp             TYPE /psyng/bapiflagx,
      go_erp_class           TYPE REF TO object,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.
DATA:gf_job_active TYPE c.
CONSTANTS:se_def_job_txt TYPE btcjob VALUE 'SAP HISTORY CAPTURE JOB'.
DATA: g_dsp_mng_lock VALUE 'N',
      g_dsp_slf_lock VALUE 'Y'.
*--Global data for tcode origin details
DATA: BEGIN OF gs_tcode_role,
        bname LIKE /psyng/bc_uidn-bname,
        name_text TYPE ad_namtext,
        tcode LIKE agr_tcodes-tcode,
        ttext LIKE tstct-ttext,
        agr_name LIKE agr_users-agr_name,
        profile  TYPE xuprofile,
      END OF gs_tcode_role.

DATA: gt_tcode_role LIKE STANDARD TABLE OF gs_tcode_role INITIAL SIZE 0
      WITH HEADER LINE.
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      y_layout TYPE slis_layout_alv,
      gt_sort TYPE slis_t_sortinfo_alv.
DATA: g_ucomm TYPE sy-ucomm.
*DATA: usertype TYPE /psyng/xuustyp.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

*-- Selection Screen
SELECTION-SCREEN: BEGIN OF BLOCK prer WITH FRAME TITLE text-041.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-042.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-043.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-044.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 3(66) text-015.
SELECTION-SCREEN: COMMENT 3(70) text-045.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-046.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 2.
SELECTION-SCREEN: COMMENT 1(75) s_cmt MODIF ID cm1.
SELECTION-SCREEN:SKIP.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-047 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-048 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.


SELECTION-SCREEN: END OF BLOCK prer .



SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-003.

SELECT-OPTIONS: uid FOR usr02-bname.
SELECT-OPTIONS: s_class FOR usr02-class.

*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS: validusr AS CHECKBOX DEFAULT 'X' USER-COMMAND usr_fil.
*"valid & dialog users
*SELECTION-SCREEN: COMMENT 3(50) text-010.
*SELECTION-SCREEN: END OF LINE.
*
*SELECT-OPTIONS : usrtype FOR usertype MODIF ID usr .
*PARAMETERS: exlckusr AS CHECKBOX DEFAULT 'X'  MODIF ID usr.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.


SELECTION-SCREEN ULINE MODIF ID c.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-012 MODIF ID c.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: kostl FOR g_kostl MODIF ID c.
SELECTION-SCREEN ULINE MODIF ID c.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-013 MODIF ID c.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: prnr FOR g_pernr MODIF ID c,
                werks FOR g_persa MATCHCODE OBJECT h_t500p MODIF ID c,
                persg FOR g_persg MODIF ID c.

SELECTION-SCREEN: END OF BLOCK blk1.

*SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-001.
SELECTION-SCREEN: BEGIN OF LINE.                     "Tcodes
SELECTION-SCREEN COMMENT 4(23) text-002.
SELECTION-SCREEN POSITION 25.
SELECT-OPTIONS: ptcode FOR tstc-tcode.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.                     "CriticalTcode onl
SELECTION-SCREEN POSITION 4.
PARAMETERS: critcod AS CHECKBOX DEFAULT space USER-COMMAND crit.
SELECTION-SCREEN COMMENT 7(55) text-011.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.                     "SOD Version
SELECTION-SCREEN COMMENT 4(33) text-040.
PARAMETERS: p_vrsio LIKE /psyng/conflict-vrsio MODIF ID cri.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK blk2.

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-018.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-019.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: 1stmon(7) OBLIGATORY.
SELECTION-SCREEN: COMMENT 28(30) text-017.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-020.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: lastmon(7) OBLIGATORY.
SELECTION-SCREEN: COMMENT 28(30) text-017.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(65) ava_txt.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

SELECTION-SCREEN SKIP 1.

SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-004.

*SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN COMMENT 1(70) CAUT1.
*SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-014.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-015.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-016.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk3.

*---------------------------- INITIALIZATION --------------------------*
INITIALIZATION.
  PERFORM exelog.
  PERFORM initialization.
*  PERFORM set_def_usrtype.
  LOOP AT SCREEN.
    CHECK screen-name = 'P_VRSIO'.
    screen-input = 0.
    MODIFY SCREEN.
  ENDLOOP.

*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR kostl-low.
*  PERFORM f4_kostl CHANGING kostl-low.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR kostl-high.
*  PERFORM f4_kostl CHANGING kostl-high.
*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR prnr-low.
  PERFORM f4_pernr CHANGING prnr-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR prnr-high.
  PERFORM f4_pernr CHANGING prnr-high.

*AT SELECTION-SCREEN ON VALUE-REQUEST FOR werks-low.
*  PERFORM f4_werks CHANGING werks-low.
*
*AT SELECTION-SCREEN ON VALUE-REQUEST FOR werks-high.
*  PERFORM f4_werks CHANGING werks-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR persg-low.
  PERFORM f4_persg CHANGING persg-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR persg-high.
  PERFORM f4_persg CHANGING persg-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.



*------------------------- AT SELECTION-SCREEN ------------------------*
AT SELECTION-SCREEN.
  PERFORM user_command.
  g_ucomm = sy-ucomm.

  IF critcod = 'X'.
*   Validate version
    SELECT SINGLE mandt INTO sy-mandt FROM /psyng/swsodvers
                  WHERE vrsio = p_vrsio.
    IF sy-subrc <> 0.
      MESSAGE e128(/psyng/sw) WITH
                'SOD Version (for Critical TCodes)'(040).
    ENDIF.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  PERFORM check_job_status.
  DATA :  l_classtype TYPE REF TO cl_abap_typedescr.

*user type field handling
  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.

    ENDCASE.

*  ENDLOOP.

*  LOOP AT SCREEN.
    IF screen-group1 EQ 'CRI'.
      IF critcod EQ 'X'.
        screen-active = 1.
        screen-input = 1.
        screen-invisible = 0.
        screen-output = 1.
        MODIFY SCREEN.
      ELSE.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = gc_erp_class
    RECEIVING
      p_descr_ref    = l_classtype
     EXCEPTIONS
       type_not_found = 1
       OTHERS         = 2.

  IF sy-subrc = 0.
    gf_use_erp = 'X'.
  ELSE.
*   Remove ERP fields from screen
    LOOP AT SCREEN.
      IF screen-group1 = 'C'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

*------------------------- START-OF-SELECTION -------------------------*
START-OF-SELECTION.
*  CONCATENATE 1stmon+3(4) 1stmon(2) '01' INTO 1stmonth.
*  CONCATENATE lastmon+3(4) lastmon(2) '01' INTO lastmont.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  IF gf_exit_proc = 'Y'.
    EXIT.
  ENDIF.

  PERFORM on_scr_date_validation.

  g_program = sy-repid.
  PERFORM sync_ust_tables.
  PERFORM get_users.
  PERFORM get_user_name_by_userid.
  users_temp[] = gt_users[].
  SORT users_temp BY bname.
  DELETE ADJACENT DUPLICATES FROM users_temp
    COMPARING bname.

  DESCRIBE TABLE users_temp LINES g_usercount.

  PERFORM get_inscope_tcodes.
  PERFORM get_tcodes_by_userid.
  PERFORM get_executed_tcodes.
  PERFORM format_output.



  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF gt_outab[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
*      percent = 75.
*      CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*           EXPORTING
*                percentage = percent
*                text       = 'Sending data to PC (Step 4 of 4)'(021).
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.
  COMMIT WORK.


*  IF nodata = space.
  PERFORM build_sort_table.
  PERFORM build_alv_catalog.
  PERFORM output_using_alv.
*  ENDIF.

*&---------------------------------------------------------------------*
*&      Form  GET_USERS             "USER ID
*&---------------------------------------------------------------------*
*       Get HR user information based on User ID
*----------------------------------------------------------------------*
FORM get_users.
  CONSTANTS: lc_method(17) TYPE c VALUE 'GET_USERS_FROM_HR'.

  DATA: lt_bname TYPE /psyng/range_bname_t,
        lt_pernr TYPE /psyng/range_pernr_t,
        lt_persa TYPE /psyng/range_persa_t,
        lt_persg TYPE /psyng/range_persg_t,
        lt_kostl TYPE /psyng/range_kostl_t,
        ls_bname TYPE /psyng/range_bname,
        lt_users TYPE /psyng/hr_user_t,
        ls_users TYPE /psyng/hr_user.


  REFRESH gt_users.
  REFRESH gt_usrtcode.



*  IF NOT uid[] IS INITIAL.
*  ls_bname-sign   = 'I'.
*  ls_bname-option = 'EQ'.
*  SELECT bname FROM usr02 INTO ls_bname-low WHERE bname IN uid
*                                             AND class IN s_class.
*
**    IF gf_use_erp = 'X'.
**      APPEND ls_bname TO lt_bname.
**    ELSE.
*    users-bname = ls_bname-low.
*    APPEND users.
**    ENDIF.
*  ENDSELECT.
*
**   Exit if no users are found
*  CHECK sy-subrc = 0.
*  ENDIF.

*-- Get HR information only if using ERP tables
  CHECK gf_use_erp = 'X'.

  lt_pernr[] = prnr[].
  lt_persa[] = werks[].
  lt_persg[] = persg[].
  lt_kostl[] = kostl[].
  CALL METHOD (gc_erp_class)=>(lc_method) "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_begda  = sy-datum
      i_endda  = sy-datum
      it_persa = lt_persa
      it_pernr = lt_pernr
      it_persg = lt_persg
      it_bname = lt_bname
      it_kostl = lt_kostl
    IMPORTING
      et_user = lt_users.

  LOOP AT lt_bname INTO ls_bname.
    READ TABLE lt_users WITH KEY ls_bname-low INTO ls_users.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING ls_users TO gt_users.
      APPEND gt_users.
    ELSE.
*if NO hr related select options are given, include non-HR users
      IF lt_persa[] IS INITIAL AND lt_pernr[] IS INITIAL
      AND lt_persg[] IS INITIAL AND lt_kostl[] IS INITIAL.
        CLEAR gt_users.
        gt_users-bname = ls_bname-low.
        APPEND gt_users.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF sy-subrc <> 0 AND NOT uid[] IS INITIAL.
    LOOP AT lt_bname INTO ls_bname.
      gt_users-bname = ls_bname-low.
      APPEND gt_users.
    ENDLOOP.
  ENDIF.
ENDFORM.                    " GET_USERS

*&---------------------------------------------------------------------*
*&      Form  GET_TCODES_BY_USERID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_tcodes_by_userid.
  DATA: wa_ust12 TYPE ust12.
  DATA: lt_itstc TYPE SORTED TABLE OF tstc WITH UNIQUE KEY tcode
        WITH HEADER LINE.

  CHECK NOT gt_users[] IS INITIAL.
  CLEAR: g_percent.
  SELECT * FROM ust12 INTO wa_ust12
                              WHERE  objct =  'S_TCODE'   AND
                                     aktps = 'A' AND
                                     field = 'TCD'.
    INSERT wa_ust12 INTO TABLE gt_iust12.
  ENDSELECT.

*  percent = 50.
*  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*       EXPORTING
*            percentage = percent
*            text       = 'User Analysis (Step 2 of 4)'(024).
*--Create a backup of table with ALL tcodes
  lt_itstc[] = gt_itstc[].
  LOOP AT gt_users.
    PERFORM fill_tcode.
    gt_itstc[] = lt_itstc[]."Start with ALL tcodes for next user.
  ENDLOOP.

*****  SF Case # 3332 Start Fix
*  REFRESH: iust12, itstc,lt_itstc.
*  FREE : iust12, itstc,lt_itstc.
*  CLEAR: iust12, itstc.

  REFRESH: gt_iust12, lt_itstc.
  FREE : gt_iust12, lt_itstc.
  CLEAR: gt_iust12.

*****  SF Case # 3332 End Fix

*  SORT usrtcode BY bname tcode.
*  DELETE ADJACENT DUPLICATES FROM usrtcode COMPARING ALL FIELDS.
ENDFORM.                    " GET_TCODES_BY_USERID


*&---------------------------------------------------------------------*
*&      Form  FORMAT_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM format_output.
  CLEAR: g_percent, g_nodata.

  SELECT * FROM tstct INTO TABLE gt_itstct WHERE sprsl = sy-langu.

*  percent = 50.
*  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*       EXPORTING
*            percentage = percent
*            text       = 'Formatting Output (Step 3 of 4)'(025).
  LOOP AT gt_users.
    gt_outab-bname = gt_users-bname.
    gt_outab-name  = gt_users-name.
*    outab-pernr = users-pernr.
*    outab-werks = users-werks.
*    outab-persg = users-persg.
*    outab-kostl = users-kostl.

    LOOP AT gt_usrtcode WHERE bname = gt_users-bname.
      gt_outab-tcode = gt_usrtcode-tcode.
      READ TABLE gt_itstct WITH TABLE KEY sprsl = sy-langu
                                       tcode = gt_usrtcode-tcode.
      IF sy-subrc = 0.
        gt_outab-ttext = gt_itstct-ttext.
      ENDIF.
      READ TABLE gt_usertcode WITH KEY bname = gt_users-bname
                                    tcode = gt_usrtcode-tcode
                                    BINARY SEARCH
                                    TRANSPORTING NO FIELDS.
      IF sy-subrc EQ 0.  "user executed the transaction
        gt_outab-exe = 'Y'.
      ELSE.
        gt_outab-exe = 'N'.
      ENDIF.
      APPEND gt_outab.

    ENDLOOP.
  ENDLOOP.

*  DESCRIBE TABLE outab LINES records.
*  IF records = 0.
*    nodata = 'Y'.
*    MESSAGE i208(00) WITH 'No data Selected'(000).
*  ENDIF.

ENDFORM.                    " FORMAT_OUTPUT
*&---------------------------------------------------------------------*
*&      Form  GET_USER_NAME_BY_USERID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_user_name_by_userid.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  TYPES: BEGIN OF l_typ_usr02,
           bname TYPE usr02-bname,
           class TYPE usr02-class,
         END OF l_typ_usr02.

DATA: lt_iusr02   TYPE HASHED TABLE OF l_typ_usr02 WITH UNIQUE KEY bname
                                                       WITH HEADER LINE,
         lt_uidn      TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE,
                                      ls_wa_usr02     TYPE l_typ_usr02,
                                          l_gltgv      TYPE usr02-gltgv,
                                          l_gltgb      TYPE usr02-gltgb,
                                          l_ustyp      TYPE usr02-ustyp,
                                          l_uflag      TYPE usr02-uflag.

  RANGES: lt_bname FOR /psyng/bc_uidn-bname.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE,
         i_include_locked TYPE flag,
         i_include_expire TYPE flag.

  IF validusr IS INITIAL.
    IF exlckusr = 'X'.
      CLEAR i_include_locked.
    ELSE.
      i_include_locked = 'X'.
    ENDIF.

    IF outvdate = 'X'.
      CLEAR i_include_expire.
    ELSE.
      i_include_expire = 'X'.
    ENDIF.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_041'
       EXPORTING
            i_validuser       = validusr
            i_include_locked  = i_include_locked
            i_include_expired = i_include_expire
       TABLES
            et_users          = lt_users
            it_userlist       = uid
            it_grouplist      = s_class
            it_usertype       = usrtype.

  CHECK NOT lt_users[] IS INITIAL.

  LOOP AT lt_users.
    ls_wa_usr02-bname = lt_users-bname.
    ls_wa_usr02-class = lt_users-class.
    INSERT ls_wa_usr02 INTO TABLE lt_iusr02 .
  ENDLOOP.

*  IF validusr IS INITIAL.
*    SELECT bname class INTO TABLE iusr02
*           FROM usr02 WHERE class IN s_class AND
*                            bname IN uid.
*  ELSE.
*    PERFORM get_sw_repo_conifg.
*    SELECT bname class gltgv gltgb ustyp uflag
*           INTO (wa_usr02-bname, wa_usr02-class, l_gltgv, l_gltgb,
*                 l_ustyp, l_uflag)
*           FROM usr02
*           WHERE class IN s_class
*             AND bname IN uid
*             AND ustyp = 'A'.
*
*      IF l_gltgv IS INITIAL.  "valid from date
*        l_gltgv = '00010101'.
*      ENDIF.
*      IF l_gltgb IS INITIAL.  "valid to date
*        l_gltgb = '99991231'.
*      ENDIF.
*      IF l_gltgv <= sy-datum AND l_gltgb >= sy-datum.
**--SF Case 1405
*        l_uflagx = l_uflag."unicode
*        IF l_uflagx O yusloc OR "locked by admin
*           l_uflagx O yugloc.   "locked by CUA admin
**      --User is locked by Local or Global Administrator
*          IF dsp_mng_lock = 'Y'.
*            INSERT wa_usr02 INTO TABLE iusr02.
*          ENDIF.
*        ELSEIF l_uflagx O yulock.
**      --User is locked by failed logins
*          IF dsp_slf_lock = 'Y'.
*            INSERT wa_usr02 INTO TABLE iusr02.
*          ENDIF.
*        ELSE.
**      --User is active
*          INSERT wa_usr02 INTO TABLE iusr02.
*        ENDIF.
*
**        CASE l_uflag.
**          WHEN 0.   "user ID unlocked
**            INSERT wa_usr02 INTO TABLE iusr02.
**          WHEN 64.  "user ID locked by system manager
**            IF dsp_mng_lock = 'Y'.
**              INSERT wa_usr02 INTO TABLE iusr02.
**            ENDIF.
**          WHEN 128. "user ID locked due to incorrect logins
**            IF dsp_slf_lock = 'Y'.
**              INSERT wa_usr02 INTO TABLE iusr02.
**            ENDIF.
**        ENDCASE.
*      ENDIF.
*    ENDSELECT.
*  ENDIF.

*   Check user group authority
*DHO 20101202
*  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  LOOP AT lt_iusr02.
    lt_uinfo-bname = lt_iusr02-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  IF NOT lt_uinfo[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
       vrsio                    = p_vrsio
*       ENHANCED_SCANTABLE       = ''
       i_name_only              = 'X'
       i_mr_company             = 'X'
      TABLES
        sw_uinfo                 = lt_uinfo.
  ENDIF.
  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD p_vrsio
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.

      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_users WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD p_vrsio
             ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.

      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_users WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO'  FIELD p_vrsio
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ELSE.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
*BOC:UMITTAL CVA scan fix 27/02/2026
                   IF sy-subrc <> 0.
                     MESSAGE e135(/psyng/sw) WITH 'Not Authorized'(e12).
                     LEAVE LIST-PROCESSING.
                   ENDIF.
*EOC:UMITTAL CVA scan fix 27/02/2026
      ENDIF.

      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_users WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.

  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.

  LOOP AT lt_uinfo.
    gt_users-bname = lt_uinfo-bname.
    APPEND gt_users.
  ENDLOOP.

  SORT gt_users BY bname.
  LOOP AT gt_users.
    READ TABLE lt_iusr02 WITH TABLE KEY bname = gt_users-bname.
    IF sy-subrc <> 0.
      DELETE gt_users.
      CONTINUE.
    ENDIF.

*   Check user group authority
*DHO 20101202
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*             ID 'CLASS' FIELD iusr02-class.
*    IF sy-subrc <> 0.
*      DELETE users.
*      gf_missing_auth_ugroup = 'X'.
*      CONTINUE.
*    ENDIF.

    REFRESH: lt_bname, lt_uidn.
    lt_bname-low = gt_users-bname.
    APPEND lt_bname.
    CALL FUNCTION '/PSYNG/BC_011'
         TABLES
              it_bname = lt_bname
              et_uidn  = lt_uidn.
    SORT lt_uidn BY bname.
    READ TABLE lt_uidn INDEX 1 TRANSPORTING name_first name_last.
    CHECK sy-subrc = 0.
    CONCATENATE lt_uidn-name_first lt_uidn-name_last INTO gt_users-name
                SEPARATED BY space.
    MODIFY gt_users.
  ENDLOOP.
ENDFORM.                    " GET_USER_NAME_BY_USERID
*&---------------------------------------------------------------------*
*&      Form  FILL_TCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_tcode.
  DATA: l_iust12_idx TYPE i.

  g_done = space.

  REFRESH: gt_userprof.
  CLEAR: gt_userprof.

  PERFORM get_user_profiles.

  LOOP AT gt_userprof WHERE bname = gt_users-bname.
    READ TABLE gt_tcodestar WITH KEY bname = gt_userprof-bname.
    IF sy-subrc <> 0. "If user doesn't already have * for tcode
      SELECT * FROM ust10s WHERE profn = gt_userprof-profile.
        READ TABLE gt_tcodestar WITH KEY bname = gt_userprof-bname.
        IF sy-subrc <> 0.
READ TABLE gt_iust12 WITH KEY mandt = sy-mandt "#EC SAST_CI_GEN_CHECK
                                     objct = 'S_TCODE'
                                     auth = ust10s-auth
                                     aktps = 'A'
                                     field = 'TCD'
                                     BINARY SEARCH
                                     TRANSPORTING NO FIELDS.
          l_iust12_idx = sy-tabix.
     LOOP AT gt_iust12 FROM l_iust12_idx
       WHERE mandt = sy-mandt AND "#EC SAST_CI_GEN_CHECK (HBHALLA)
             objct = 'S_TCODE' AND
             auth = ust10s-auth AND
             aktps = 'A' AND
             field = 'TCD'.
            g_fr_low = gt_iust12-von.
            g_to_high = gt_iust12-bis.
            IF g_done = space.
              PERFORM fill_transaction.
            ENDIF.
          ENDLOOP.
        ENDIF.
      ENDSELECT.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " FILL_TCODE

*&---------------------------------------------------------------------*
*&      Form  FILL_TRANSACTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_transaction.
  wa_usrtcode-bname = gt_userprof-bname.
  g_first_char = g_fr_low.
IF g_first_char = '*'. "If auth has "*" get all tcodes defined in system
    PERFORM first_char_star.
  ELSE.
    IF g_fr_low > space AND g_to_high > space.   "If auth has range
      PERFORM high_low_populated.
    ELSE.              "If auth has a starting char with * following it
      IF g_fr_low CS '*'.
        PERFORM low_has_star.
      ELSE.                      "If a specific transaction is specified
        PERFORM get_specific_tcode.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.                    " FILL_TRANSACTION

*&---------------------------------------------------------------------*
*&      Form  SYNC_UST_TABLES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM sync_ust_tables.
*  CALL FUNCTION 'SUSR_SYNC_USER_TABLES'
*       EXPORTING
*            tabletype = '*'
*       EXCEPTIONS
*            OTHERS    = 1.
ENDFORM.                    " SYNC_UST_TABLES

*&---------------------------------------------------------------------*
*&      Form  GET_SINGLE_PROFILES
*&---------------------------------------------------------------------*
*       This form is used to get all sub-profiles of any given profile.
*       This form takes the profile name PROFNAME and compiles all
*       single profiles that it contains, even if the single profiles
*       are in other composite profiles.  Once compiled it populates
*       that profile list in an inernal table called PROFINFO.  If the
*       profile provided is a single profile, it will return the single
*       profile in PROFINFO.
*----------------------------------------------------------------------*
*  -->  PROFNAME  Profile name (Single or Composite)
*  <--  PROFINFO  Internal table populated with profile names contained
*                 in the profile provided in PROFNAME parameter
*----------------------------------------------------------------------*
FORM get_single_profiles USING profname.

*Check if profile is a composite profile, if so get all sub profiles
  SELECT SINGLE * FROM ust10c WHERE profn = profname.
  IF sy-subrc = 0.
    SELECT * FROM ust10c WHERE profn = profname.
      gt_profinfo-profn = ust10c-subprof. "get all sub profiles
      gt_profinfo-composite = 'Y'.
      APPEND gt_profinfo.
    ENDSELECT.
  ELSE.     "if there is no entry for profile in composite table
    gt_profinfo-profn = profname. "Add the sub profile
    APPEND gt_profinfo.
  ENDIF.

  gt_profinfo2[] = gt_profinfo[].

  WHILE g_table1done = space AND g_table2done = space.
* Loop on 1st table and add/delete data from 2nd table
  LOOP AT gt_profinfo WHERE composite = 'Y'. "only loop at comp profiles
      SELECT SINGLE * FROM ust10c WHERE profn = gt_profinfo-profn.
      IF sy-subrc = 0.            "if the sub profile is also composite
        SELECT * FROM ust10c WHERE profn = gt_profinfo-profn.
       READ TABLE gt_profinfo2 WITH KEY profn = ust10c-subprof. "no dups
          IF sy-subrc <> 0.         "only append if profile is not there
            gt_profinfo2-profn = ust10c-subprof. "get the sub profiles
         gt_profinfo2-composite = 'Y'.  "assume sub profile is also comp
            APPEND gt_profinfo2.
          ENDIF.
        ENDSELECT.
        DELETE gt_profinfo.   "remove the composite entry from table
      ELSE.     "if there is no entry for profile in composite table
        gt_profinfo-composite = ' '.
        MODIFY gt_profinfo.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.   "No more composites
      g_table1done = 'Y'.
    ENDIF.

* Do the same (but exact opposite) logic again on the second table
* Loop at 2nd table and add/delete data from 1st table
    LOOP AT gt_profinfo2 WHERE composite = 'Y'.
      SELECT SINGLE * FROM ust10c WHERE profn = gt_profinfo2-profn.
      IF sy-subrc = 0.
        SELECT * FROM ust10c WHERE profn = gt_profinfo2-profn.
          READ TABLE gt_profinfo WITH KEY profn = ust10c-subprof.
          IF sy-subrc <> 0.
            gt_profinfo-profn = ust10c-subprof.
            gt_profinfo-composite = 'Y'.
            APPEND gt_profinfo.
          ENDIF.
        ENDSELECT.
        DELETE gt_profinfo2.
      ELSE.
        gt_profinfo2-composite = ' '.
        MODIFY gt_profinfo2.
      ENDIF.
    ENDLOOP.
    IF sy-subrc <> 0.
      g_table2done = 'Y'.
    ENDIF.

  ENDWHILE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_catalog.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'GT_OUTAB'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = i_fieldcat_alv
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             INCONSISTENT_INTERFACE = 1
             PROGRAM_ERROR          = 2
             OTHERS                 = 3 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

  wa_fieldcat_alv-seltext_l = 'Executed Transaction'(030).
  wa_fieldcat_alv-seltext_m = 'Exe Tcode'(031).
  wa_fieldcat_alv-seltext_s = 'Executed'(032).
  wa_fieldcat_alv-reptext_ddic = 'Executed Transaction'(030).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'EXE'.

  wa_fieldcat_alv-seltext_l = 'User ID'(d01).
  wa_fieldcat_alv-seltext_m = 'User ID'(d01).
  wa_fieldcat_alv-seltext_s = 'User ID'(d01).
  wa_fieldcat_alv-reptext_ddic = 'User ID'(d01).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

* Remove fields from output if not using HR tables
  IF gf_use_erp = space.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING no_out
                          WHERE fieldname = 'PERNR'
                             OR fieldname = 'KOSTL'
                             OR fieldname = 'PERSG'
                             OR fieldname = 'WERKS'.
  ENDIF.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING hotspot
                        WHERE fieldname = 'TCODE'.

* Modify the column text that is displayed in ALV output.
*  READ TABLE I_FIELDCAT_ALV WITH KEY FIELDNAME = 'NAME'.
*  LOOP AT I_FIELDCAT_ALV.
*    IF I_FIELDCAT_ALV-FIELDNAME = 'NAME'.
*      I_FIELDCAT_ALV-SELTEXT_L = 'User ID'.
*      MODIFY I_FIELDCAT_ALV.
*    ELSEIF I_FIELDCAT_ALV-FIELDNAME = 'BNAME'.
*      I_FIELDCAT_ALV-FIELDNAME = 'User Name'.
*      MODIFY I_FIELDCAT_ALV.
*    ENDIF.
*  ENDLOOP.
* CONCATENATE: 'Execution complete. Formating ALV and passing data'(033)
*                     'to your PC (Step 4 of 4). Please be patient'(034)
*                             INTO pertext SEPARATED BY space.
*
*  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
*       EXPORTING
*            percentage = 95
*            text       = pertext.

ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------*
*&      Form  OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_using_alv.
  DATA: ls_variant TYPE disvariant.


  gs_alv_layout-zebra = 'X'.
  gs_alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = g_program
            i_callback_top_of_page   = 'ALV_HEADER'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'HOTSPOT_CLICK'
            it_sort                  = isort
            is_layout                = gs_alv_layout
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = gt_outab
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " OUTPUT_USING_ALV
*&---------------------------------------------------------------------*
*&      Form  get_inscope_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_inscope_tcodes.

  IF critcod = 'X'.
    SELECT DISTINCT tcode FROM /psyng/critcodes INTO TABLE gt_itstc
           WHERE tcode IN ptcode
             AND vrsio  = p_vrsio.
  ELSE.
    SELECT DISTINCT tcode FROM tstc INTO TABLE gt_itstc
           WHERE tcode IN ptcode.
  ENDIF.
ENDFORM.                    " get_inscope_tcodes
*&---------------------------------------------------------------------*
*&      Form  first_char_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM first_char_star.
  LOOP AT gt_itstc.                         "tcodes defined in system
    wa_usrtcode-tcode = gt_itstc-tcode.
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
    DELETE gt_itstc WHERE tcode = wa_usrtcode-tcode.
  ENDLOOP.
  gt_tcodestar-bname = gt_userprof-bname.
  APPEND gt_tcodestar.     "This table is to improve performance when
  g_done = 'X'.           "user has * for tcode authorization
ENDFORM.                    " first_char_star
*&---------------------------------------------------------------------*
*&      Form  high_low_populated
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM high_low_populated.

  DATA:   l_iagrprof_idx TYPE i,
         ls_compare TYPE /psyng/auth_compare,
         lt_compare TYPE TABLE OF /psyng/auth_compare.

  FIELD-SYMBOLS : <comp> TYPE /psyng/auth_compare.

  REFRESH lt_compare.


  LOOP AT gt_itstc.
    ls_compare-auth_from  = g_fr_low.
    ls_compare-auth_to    = g_to_high.
    ls_compare-sod_from   = gt_itstc-tcode.
    APPEND ls_compare TO lt_compare  .
  ENDLOOP.
*  --SW_021 does the sorting and deleting dupes
  CALL FUNCTION '/PSYNG/SW_021'
       TABLES
            it_compare = lt_compare.

  SORT lt_compare BY match.
  DELETE lt_compare WHERE match <> 'X'.

*
*  READ TABLE itstc WITH KEY tcode = fr_low
*                              BINARY SEARCH
*                              TRANSPORTING NO FIELDS.
*  itstc_idx = sy-tabix - 1.
*  LOOP AT itstc FROM itstc_idx
*                WHERE tcode >= fr_low  AND  "select all tcodes in
*                      tcode <= to_high.     "range
*  LOOP AT itstc FROM itstc_idx
*                  WHERE tcode IN r_tcode.
  LOOP AT lt_compare ASSIGNING <comp>
    WHERE match = 'X'.
    wa_usrtcode-tcode = <comp>-sod_from.
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
    DELETE gt_itstc WHERE tcode = wa_usrtcode-tcode.
  ENDLOOP.

*  IF to_high CS '*'.       "If auth 'TO' ends with '*' get all
*    PERFORM range_high_star.
*  ENDIF.
*
*  IF fr_low CS '*'.         "If auth 'FROM' ends with '*', get all
*    PERFORM range_low_star.
*  ENDIF.
*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x-*x
*  LOOP AT itstc WHERE tcode >= fr_low  AND  "select all tcodes in
*                      tcode <= to_high.     "range
*    wa_usrtcode-tcode = itstc-tcode.
*    INSERT wa_usrtcode INTO TABLE usrtcode.
*  ENDLOOP.
*
*  IF to_high CS '*'.       "If auth 'TO' ends with '*' get all
*    PERFORM range_high_star.
*  ENDIF.
*
*  IF fr_low CS '*'.         "If auth 'FROM' ends with '*', get all
*    PERFORM range_low_star.
*  ENDIF.
ENDFORM.                    " high_low_populated
*&---------------------------------------------------------------------*
*&      Form  low_has_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM low_has_star.
  LOOP AT gt_itstc WHERE tcode CP g_fr_low. "transactions ending
    wa_usrtcode-tcode = gt_itstc-tcode. "with suffix text
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
    DELETE gt_itstc WHERE tcode = wa_usrtcode-tcode.
  ENDLOOP.

ENDFORM.                    " low_has_star
*&---------------------------------------------------------------------*
*&      Form  get_specific_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_specific_tcode.
  READ TABLE gt_itstc WITH TABLE KEY tcode = g_fr_low.
*  READ TABLE itstc WITH TABLE KEY tcode = ust12-von.
  IF sy-subrc = 0.
*    wa_usrtcode-tcode = ust12-von.
    wa_usrtcode-tcode = g_fr_low.
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
    DELETE gt_itstc WHERE tcode = wa_usrtcode-tcode.
  ENDIF.

ENDFORM.                    " get_specific_tcode
*&---------------------------------------------------------------------*
*&      Form  range_high_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM range_high_star.
  READ TABLE gt_itstc WITH KEY tcode = g_to_high
                              BINARY SEARCH
                              TRANSPORTING NO FIELDS.
  g_itstc_idx = sy-tabix - 1.
  LOOP AT gt_itstc FROM g_itstc_idx
                WHERE tcode CP g_to_high. "transactions begining
    wa_usrtcode-tcode = gt_itstc-tcode. "with PREFIX text
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
    DELETE gt_itstc WHERE tcode = wa_usrtcode-tcode.
  ENDLOOP.
ENDFORM.                    " range_high_star
*&---------------------------------------------------------------------*
*&      Form  range_low_star
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM range_low_star.
  LOOP AT gt_itstc WHERE tcode CP g_fr_low. "transactions ending
    wa_usrtcode-tcode = gt_itstc-tcode. "with suffix text
    INSERT wa_usrtcode INTO TABLE gt_usrtcode.
  ENDLOOP.
ENDFORM.                    " range_low_star

*---------------------------------------------------------------------*
*       FORM get_sw_repo_conifg                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM get_sw_repo_conifg.
  CLEAR: swconfig.
  se_config_param 'REP_USR_LOK_DSP_MGR' swconfig-value.
  IF swconfig-value = 'Y'.
    g_dsp_mng_lock = 'Y'.
  ENDIF.
  CLEAR swconfig.
  se_config_param 'REP_USR_LOK_DSP_SLF' swconfig-value.
  IF swconfig-value = 'N'.
    g_dsp_slf_lock = 'N'.
  ENDIF.
ENDFORM.                    " get_sw_repo_conifg
*&---------------------------------------------------------------------*
*&      Form  get_user_profiles
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_user_profiles.
  SELECT * FROM ust04 WHERE bname = gt_users-bname.
    REFRESH: gt_profinfo.
    CLEAR:   g_table1done, g_table2done.
    PERFORM get_single_profiles USING ust04-profile.
    LOOP AT gt_profinfo.
      gt_userprof-bname = ust04-bname.
      gt_userprof-profile = gt_profinfo-profn.
      APPEND gt_userprof.
    ENDLOOP.
  ENDSELECT.
  SORT gt_userprof.
  DELETE ADJACENT DUPLICATES FROM gt_userprof COMPARING ALL FIELDS.

ENDFORM.                    " get_user_profiles
*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialization.
  DATA: l_st_txt(10),
        ls_txt(10),
        lo_classtype TYPE REF TO cl_abap_typedescr,
* BOC by RGUPTA on 28.04.22
        lv_field TYPE string VALUE ' MIN( PERIODSTRT )',
        lv_table TYPE c LENGTH 30 VALUE 'SWNCMONI',
        lv_where TYPE string,
        lv_relid TYPE c LENGTH 2 VALUE 'WM',
        lv_comp  TYPE c LENGTH 5 VALUE 'TOTAL',
        lv_value TYPE swncdatum,
        lv_count TYPE i.
* EOC by RGUPTA on 28.04.22


  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = idirectory.

  LOOP AT idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF g_1stmonth IS INITIAL OR g_1stmonth > idirectory-startdate.
      g_1stmonth = idirectory-startdate.
    ENDIF.
    IF g_lastmont < idirectory-startdate.
      g_lastmont = idirectory-startdate.
    ENDIF.
    gt_months-month = idirectory-startdate.
    APPEND gt_months.
  ENDLOOP.
* BOC by RGUPTA on 28.04.22
  SELECT COUNT(*) FROM  dd02l
                INTO    lv_count
                WHERE   tabname = lv_table(30)
                AND     as4local  = 'A'."#EC SAST_CI_GEN_CHECK
  IF sy-subrc IS INITIAL AND lv_count GT 0.
  lv_where = 'RELID EQ lv_relid AND COMPONENT EQ lv_comp'.
  SELECT (lv_field) UP TO 1 ROWS
  FROM (lv_table) "#EC SAST_CI_GEN_CHECK
  INTO lv_value
  WHERE (lv_where). "#EC SAST_CI_GEN_CHECK
  ENDSELECT.
  IF sy-subrc IS INITIAL.
    g_1stmonth = lv_value.
  ENDIF.
  ENDIF.
* EOC by RGUPTA on 28.04.22

  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth(4) INTO 1stmon.
  CONCATENATE g_lastmont+4(2) '/' g_lastmont(4) INTO lastmon.


  CONCATENATE  g_1stmonth+4(2) '/' g_1stmonth(4) INTO l_st_txt.
  CONCATENATE  g_lastmont+4(2) '/' g_lastmont(4) INTO ls_txt.

  CONCATENATE '*History data available from'(036)
                                 l_st_txt 'to'(037) ls_txt
                                 INTO ava_txt SEPARATED BY space.

ENDFORM.                    " initialization
*&---------------------------------------------------------------------*
*&      Form  get_executed_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_executed_tcodes.
  DATA: user_stat  TYPE TABLE OF /psyng/sw_entry WITH HEADER LINE,
        lt_hitlist TYPE TABLE OF /psyng/hitlist WITH HEADER LINE.


  CHECK NOT gt_users[] IS INITIAL.
  SORT gt_users.

  LOOP AT gt_months.
  CHECK gt_months-month GE g_1stmonth AND gt_months-month LE g_lastmont.

    CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
         EXPORTING
              startdate = gt_months-month
         TABLES
              user_stat = user_stat
              hitlist   = lt_hitlist.

    LOOP AT user_stat.
      READ TABLE gt_users WITH KEY bname = user_stat-account
           BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.

      IF user_stat-entry_id+72(1) = 'T'.   "transaction code
        CLEAR gt_usertcode.
        gt_usertcode-bname = user_stat-account.
        gt_usertcode-tcode = user_stat-entry_id(20).
        IF critcod = 'X'.
          READ TABLE gt_itstc WITH TABLE KEY tcode = gt_usertcode-tcode.
          CHECK sy-subrc = 0.
          APPEND gt_usertcode.
        ELSE.
          APPEND gt_usertcode.
        ENDIF.
      ENDIF.
    ENDLOOP.
    REFRESH: user_stat.

    LOOP AT lt_hitlist WHERE tcode <> space.
      READ TABLE gt_users WITH KEY bname = lt_hitlist-account
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.

      IF critcod = 'X'.
        READ TABLE gt_itstc WITH TABLE KEY tcode = gt_usertcode-tcode.
        CHECK sy-subrc = 0.
      ENDIF.

      CLEAR gt_usertcode.
      gt_usertcode-bname = lt_hitlist-account.
      gt_usertcode-tcode = lt_hitlist-tcode.
      APPEND gt_usertcode.
    ENDLOOP.
    REFRESH lt_hitlist.
  ENDLOOP.   "months

  SORT gt_usertcode.
  DELETE ADJACENT DUPLICATES FROM gt_usertcode.

ENDFORM.                    " get_executed_tcodes
*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTAB'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '2'.
  l_sort-fieldname = 'NAME'.
  l_sort-tabname = 'OUTAB'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '3'.
  l_sort-fieldname = 'EXE'.
  l_sort-tabname = 'OUTAB'.
  l_sort-up = 'Y'.
  APPEND l_sort TO isort.

  l_sort-spos = '4'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTAB'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
ENDFORM.                    " build_sort_table

*&---------------------------------------------------------------------*
*&      Form  f4_kostl
*&---------------------------------------------------------------------*
*       F4 Value help for cost center
*----------------------------------------------------------------------*
*      <--E_KOSTL  Cost Center
*----------------------------------------------------------------------*
FORM f4_kostl CHANGING e_kostl TYPE kostl.
  DATA: lt_f4_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = 'PA0001'
            fieldname         = 'KOSTL'
       TABLES
            return_tab        = lt_f4_return
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.

  IF sy-subrc = 0.
    READ TABLE lt_f4_return WITH KEY fieldname = 'KOSTL'.
    e_kostl = lt_f4_return-fieldval.
  ENDIF.
ENDFORM.                                                    " f4_kostl

*&---------------------------------------------------------------------*
*&      Form  f4_pernr
*&---------------------------------------------------------------------*
*       F4 Value help for employee number
*----------------------------------------------------------------------*
*      <--E_PERNR  Employee number
*----------------------------------------------------------------------*
FORM f4_pernr CHANGING e_pernr TYPE /psyng/pernr.
  DATA: lt_f4_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = 'PA0001'
            fieldname         = 'PERNR'
       TABLES
            return_tab        = lt_f4_return
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.

  IF sy-subrc = 0.
    READ TABLE lt_f4_return INDEX 1.
    e_pernr = lt_f4_return-fieldval.
  ENDIF.
ENDFORM.                                                    " f4_pernr


*&---------------------------------------------------------------------*
*&      Form  f4_persg
*&---------------------------------------------------------------------*
*       F4 Value help for employee group
*----------------------------------------------------------------------*
*      <--E_PERSG  Employee group
*----------------------------------------------------------------------*
FORM f4_persg CHANGING e_persg TYPE /psyng/persg.
  DATA: lt_f4_return TYPE TABLE OF ddshretval WITH HEADER LINE.

  CALL FUNCTION 'F4IF_FIELD_VALUE_REQUEST'
       EXPORTING
            tabname           = 'PA0001'
            fieldname         = 'PERSG'
       TABLES
            return_tab        = lt_f4_return
       EXCEPTIONS
            field_not_found   = 1
            no_help_for_field = 2
            inconsistent_help = 3
            no_values_found   = 4
            OTHERS            = 5.

  IF sy-subrc = 0.
    READ TABLE lt_f4_return INDEX 1.
    e_persg = lt_f4_return-fieldval.
  ENDIF.
ENDFORM.                                                    " f4_persg

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user. "sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_count TYPE i,
        c_usercount(6) TYPE c,
        l_exetime(8) TYPE c,
        l_exedate TYPE char10,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 29.03.22 for C0700

  wa-typ = 'H'.
  wa-info =
'Ran Executable-Currently Authorized Tcodes Executed by Users'(h01)
.
  APPEND wa TO header.
*SOD Version.
  IF critcod = 'X'.
    wa-typ = 'S'.
    wa-key = 'Sod Version'(h02).
    SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
    WHERE vrsio = p_vrsio.
    CONCATENATE p_vrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
    APPEND wa TO header.
  ENDIF.
*Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO l_exedate.
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
 CONCATENATE l_current_user"sy-uname C0700
  text-h05 l_exedate l_exetime INTO wa-info
 SEPARATED BY
 SPACE.
  APPEND wa TO header.
*Summary.
  wa-typ = 'S'.
  wa-key = 'Summary'(h05).
  c_usercount = g_usercount.
  CONCATENATE c_usercount text-h06 INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

ENDFORM.


*---------------------------------------------------------------------*
*       FORM HOTSPOT_CLICK                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM hotspot_click USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.

  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE gt_outab INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      PERFORM get_tcode_origin USING
      is_selfield-value gt_outab-bname gt_outab-name.
      PERFORM fieldcat_drill_detail_tcode.
      PERFORM build_sort_detail_tcode.
      PERFORM drill_alv_detail_tcode.

    WHEN OTHERS.
*--No action

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_tcode_origin
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_tcode_origin USING i_tcode i_bname TYPE xubname i_name.
  DATA : lt_objects TYPE TABLE OF /psyng/xuobject WITH HEADER LINE,
         lt_values  TYPE TABLE OF usvalues,
         lt_auths   TYPE TABLE OF usvalues WITH HEADER LINE,
         lf_match   TYPE flag,
         lt_ust10s  TYPE TABLE OF ust10s,
         lt_roles   TYPE TABLE OF agr_prof WITH HEADER LINE,
         lt_profiles TYPE TABLE OF  ust10c WITH HEADER LINE,
         lt_usrprofiles TYPE TABLE OF  ust04 WITH HEADER LINE,
         lt_usrroles TYPE TABLE OF agr_users WITH HEADER LINE,
"prevent recursive subprofile
         l_subprof_maxlevel TYPE i VALUE '5',

         l_subrc TYPE sysubrc,
         l_tcode TYPE tcode,
         lf_found TYPE flag.
  l_tcode = i_tcode.
  FREE : gt_tcode_role.
  FIELD-SYMBOLS : <val> TYPE usvalues.
  lt_objects-object = 'S_TCODE'.
  APPEND lt_objects.
*--Get the tcode text
  PERFORM get_tcode_text
              USING
                 l_tcode
              CHANGING
                 gt_tcode_role-ttext.

  CALL FUNCTION '/PSYNG/SW_049'
       EXPORTING
            user_name  = i_bname
       TABLES
            values     = lt_values
            it_objects = lt_objects.

  LOOP AT lt_values ASSIGNING <val>.
    IF <val>-bis IS INITIAL AND
       <val>-von NS '*'.
      IF <val>-von = l_tcode.
        lt_auths-auth = <val>-auth.
        APPEND lt_auths.
      ENDIF.
    ELSE.
      CALL FUNCTION '/PSYNG/SW_021'
       EXPORTING
         auth_from        =  <val>-von
         auth_to          =  <val>-bis
         sod_from         =  l_tcode
*       SOD_TO           =
       IMPORTING
         match            = lf_match.
      IF lf_match = 'X'.
        lt_auths-auth = <val>-auth.
        APPEND lt_auths.
      ENDIF.
    ENDIF.
  ENDLOOP.
  IF NOT lt_auths[] IS INITIAL.
*--Get the profiles
    SELECT DISTINCT profn  FROM ust10s
     INTO CORRESPONDING FIELDS OF
      TABLE lt_ust10s FOR ALL ENTRIES IN lt_auths
       WHERE auth = lt_auths-auth.
*--Get the roles
    IF NOT lt_ust10s[] IS INITIAL.
      SELECT * FROM agr_prof                       "#EC CI_NO_TRANSFORM
       INTO TABLE lt_roles FOR ALL ENTRIES IN lt_ust10s
                                        WHERE profile = lt_ust10s-profn.
      IF NOT lt_roles[] IS INITIAL.
      SELECT * FROM agr_users INTO TABLE lt_usrroles FOR ALL ENTRIES IN
                                                         lt_roles WHERE
                                                    uname = i_bname AND
                                           agr_name = lt_roles-agr_name.

        LOOP AT lt_usrroles.
          gt_tcode_role-bname     = i_bname.

          gt_tcode_role-name_text = i_name.
          gt_tcode_role-tcode     = i_tcode.
          READ TABLE lt_roles WITH KEY agr_name = lt_usrroles-agr_name.
          gt_tcode_role-agr_name  = lt_roles-agr_name.
          gt_tcode_role-profile   = lt_roles-profile.
          APPEND gt_tcode_role.
          lf_found = 'X'.
          DELETE lt_ust10s WHERE profn = lt_roles-profile.
        ENDLOOP.
      ENDIF.
*--Directly assigned profiles : lt_ust10s
*Find parent profiles
      IF NOT lt_ust10s[] IS INITIAL.
SELECT DISTINCT profn subprof  FROM ust10c INTO CORRESPONDING FIELDS OF
                         TABLE lt_profiles FOR ALL ENTRIES IN lt_ust10s
                                        WHERE subprof = lt_ust10s-profn.
        l_subrc = sy-subrc.
        WHILE l_subrc = 0 AND l_subprof_maxlevel < 0 and not
        lt_profiles[] is initial.
          SELECT DISTINCT profn subprof            "#EC CI_NO_TRANSFORM
          FROM ust10c APPENDING CORRESPONDING FIELDS OF
          TABLE lt_profiles FOR ALL ENTRIES IN lt_profiles
          WHERE subprof = lt_profiles-profn.
          l_subrc = sy-subrc.
          LOOP AT lt_profiles.
            DELETE lt_profiles WHERE profn = lt_profiles-subprof.
          ENDLOOP.
          SUBTRACT 1 FROM l_subprof_maxlevel.
        ENDWHILE.

        SORT lt_profiles BY profn.
        DELETE ADJACENT DUPLICATES FROM lt_profiles COMPARING profn.
        IF NOT lt_profiles[] IS INITIAL.

          SELECT profile FROM ust04
            INTO TABLE lt_usrprofiles
            FOR ALL ENTRIES IN lt_profiles
             WHERE bname = i_bname AND
                   profile = lt_profiles-profn.

          LOOP AT lt_usrprofiles.
            gt_tcode_role-bname     = i_bname.
            gt_tcode_role-name_text = i_name.
            gt_tcode_role-tcode     = i_tcode.
            CLEAR gt_tcode_role-agr_name.
            gt_tcode_role-profile   = lt_usrprofiles-profile.
            APPEND gt_tcode_role.
            lf_found = 'X'.

          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  IF lf_found <> 'X'.
*--User no longer has tcode
    gt_tcode_role-bname     = i_bname.
    gt_tcode_role-name_text = i_name.
    gt_tcode_role-tcode     = i_tcode.
    gt_tcode_role-agr_name  = gt_tcode_role-profile = 'N/A'.
    APPEND gt_tcode_role.
  ENDIF.

ENDFORM.                    " get_tcode_origin

*&---------------------------------------------------------------------*
*&      Form  get_tcode_text
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_USRHIS_RPT  text
*      <--P_GT_USRHIS_RPT_TCODE_TEXT  text
*----------------------------------------------------------------------*
FORM get_tcode_text USING    i_tcode
                    CHANGING e_text.
  TYPES: BEGIN OF l_t_tran,
           tcode TYPE tstct-tcode,
           ttext TYPE tstct-ttext,
         END OF l_t_tran.

  DATA: ls_tran TYPE l_t_tran.

  STATICS: lt_tran TYPE HASHED TABLE OF l_t_tran WITH UNIQUE KEY tcode.


  CLEAR e_text.

  READ TABLE lt_tran INTO ls_tran WITH TABLE KEY tcode = i_tcode.
  IF sy-subrc = 0.
    e_text = ls_tran-ttext.
    EXIT.
  ENDIF.

  SELECT SINGLE ttext INTO ls_tran-ttext FROM tstct
                WHERE sprsl = sy-langu
                  AND tcode = i_tcode.
  IF sy-subrc = 0.
    e_text        = ls_tran-ttext.
    ls_tran-tcode = i_tcode.
    INSERT ls_tran INTO TABLE lt_tran.
  ENDIF.
ENDFORM.                    " get_tcode_text
*&---------------------------------------------------------------------*
*&      Form  fieldcat_drill_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fieldcat_drill_detail_tcode.

  REFRESH gt_fieldcat[].
  DATA : ls_fieldcat TYPE slis_fieldcat_alv.
  ls_fieldcat-fieldname = 'BNAME'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'User ID'(d01).
  ls_fieldcat-col_pos = 1.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'NAME_TEXT'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Name'(d02).
  ls_fieldcat-col_pos = 2.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'TCODE'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Transaction'(d03).
  ls_fieldcat-col_pos = 3.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'TTEXT'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Transaction Text'(d04).
  ls_fieldcat-col_pos = 4.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'AGR_NAME'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Single Role Name'(d05).
  ls_fieldcat-col_pos = 5.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'PROFILE'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Profile'(d06).
  ls_fieldcat-col_pos = 5.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

ENDFORM.                    " fieldcat_drill_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  build_sort_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_detail_tcode.
  FREE : gt_sort.
  DATA: ls_sort TYPE slis_sortinfo_alv.

  CLEAR: ls_sort, gt_sort.
  REFRESH: gt_sort.

  ls_sort-spos = '1'.
  ls_sort-fieldname = 'BNAME'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.

  ls_sort-spos = '2'.
  ls_sort-fieldname = 'NAME_TEXT'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.

  ls_sort-spos = '3'.
  ls_sort-fieldname = 'TCODE'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.

  ls_sort-spos = '4'.
  ls_sort-fieldname = 'TTEXT'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.
ENDFORM.                    " build_sort_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  drill_alv_detail_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM drill_alv_detail_tcode.
  DATA: l_program  LIKE sy-repid,
        ls_variant TYPE disvariant.


  l_program = sy-repid.

  y_layout-zebra = 'X'.
  y_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = l_program
            is_layout          = y_layout
            it_fieldcat        = gt_fieldcat
            it_sort            = gt_sort
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = gt_tcode_role[]
       EXCEPTIONS
            program_error      = 1
            OTHERS             = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " drill_alv_detail_tcode

*&---------------------------------------------------------------------*
*&      Form  on_scr_date_validation
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM on_scr_date_validation.

  DATA:  l_val_sdate TYPE dats,
         l_val_edate TYPE dats,
         l_sdate TYPE dats,
         l_edate TYPE dats,
         l_message(220) TYPE c.


  l_val_sdate = g_1stmonth.
  l_val_edate = sy-datum.
  CONCATENATE 1stmon+3(4) 1stmon(2) '01' INTO l_sdate.
  CONCATENATE lastmon+3(4) lastmon(2) '01' INTO l_edate.


  PERFORM validate_date USING l_sdate
                              l_edate
                              l_val_sdate
                              l_val_edate
                     CHANGING l_message.
  IF l_message IS INITIAL.
    g_lastmont = l_edate.
    g_1stmonth = l_sdate.
  ELSE.

    SET CURSOR FIELD 1stmon.

    MESSAGE s002(/psyng/sw) WITH l_message.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    " on_scr_date_validation


*---------------------------------------------------------------------*
*       FORM validate_date                                            *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM validate_date USING p_sdate
                         p_edate
                         p_val_sdate
                         p_val_edate
                     CHANGING l_message.

  DATA: l_from_date LIKE sy-datum,
        l_to_date LIKE sy-datum,
        l_date LIKE l_to_date.

  CLEAR l_message.
  l_from_date = p_sdate.
  l_to_date = p_edate.

  IF NOT p_sdate IS INITIAL.
    l_date = l_from_date.
    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      CONCATENATE 'Invalid Format of'(ed1) 'From Date'(d07)
                        INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE 'From Date'(d07) 'Cannot be initial'(p04)
                        INTO l_message SEPARATED BY space.
    EXIT.
  ENDIF.

  IF NOT p_edate IS INITIAL.

    l_date = l_to_date.

    CALL FUNCTION 'DATE_CHECK_PLAUSIBILITY'
         EXPORTING
              date                      = l_date
         EXCEPTIONS
              plausibility_check_failed = 1
              OTHERS                    = 2.
    IF sy-subrc <> 0.
      CONCATENATE 'Invalid Format of'(ed1) 'To Date'(d08)
                        INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE 'To Date'(d08) 'Cannot be initial'(p04)
                            INTO l_message SEPARATED BY space.
    EXIT.
  ENDIF.

  IF l_to_date < l_from_date.
    l_message = 'From date cannot be greater than end date'(p05).
    EXIT.
  ENDIF.

  IF l_from_date < p_val_sdate OR l_from_date > p_val_edate.
    l_message = 'From date is out of availabe history range'(p06).
    EXIT.
  ENDIF.

  IF l_to_date < p_val_sdate OR l_to_date > p_val_edate.
    l_message = 'To date is out of availabe history range'(p07).
    EXIT.
  ENDIF.




ENDFORM.                    " validate_date
*&---------------------------------------------------------------------*
*&      Form  check_job_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_job_status.
  DATA:se_job_txt_msg(77) TYPE c.
  PERFORM get_job_name USING se_def_job_txt
                       CHANGING se_job_txt_msg.

  s_cmt = se_job_txt_msg.
  LOOP AT SCREEN.
    CASE screen-group1.
      WHEN 'CM1'.
        screen-intensified = '1'.
        MODIFY SCREEN.
      WHEN 'BGD'.
        IF gf_job_active EQ 'X'.
          screen-input = 0.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'OUT'.
        screen-active = 0.
        MODIFY SCREEN.
      WHEN OTHERS.
    ENDCASE.
  ENDLOOP.


ENDFORM.                    " check_job_status
*&---------------------------------------------------------------------*
*&      Form  get_job_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_4539   text
*      -->P_SE_DEF_JOB_TXT  text
*      <--P_SE_JOB_TXT_MSG  text
*----------------------------------------------------------------------*
FORM get_job_name USING    i_default  TYPE tbtcp-jobname
                  CHANGING e_job_msg .
  DATA:t_icon TYPE icon-id,
       l_freq_h TYPE tbtco-prdhours,
       l_freq_d TYPE tbtco-prddays.
  CLEAR:gf_job_active.

  SELECT SINGLE o~prdhours o~prddays INTO (l_freq_h,l_freq_d)
           FROM tbtcp AS p
          INNER JOIN tbtco AS o
             ON p~jobname  = o~jobname
            AND p~jobcount = o~jobcount
           WHERE
          (   p~progname  = 'RSCOLL00' OR
              p~progname  = 'RSBPCOLL'
          ) AND o~status    = 'S'.

  IF sy-subrc EQ 0.
    gf_job_active = 'X'.
    t_icon = '@08@'.
    IF NOT l_freq_h IS INITIAL.
      CONCATENATE t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_h 'hours'(s05)
      INTO e_job_msg SEPARATED BY space.
    ELSEIF NOT l_freq_d IS INITIAL.
      CONCATENATE t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_d 'days'(s06)
      INTO e_job_msg SEPARATED BY space.
    ENDIF.

  ELSE.
    t_icon = '@0A@'.
    CONCATENATE t_icon
                'History Capture job is not running.'(w01)
                INTO e_job_msg SEPARATED BY space.
  ENDIF.

ENDFORM.                    " get_job_name


*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_command.
  CASE sy-ucomm.
    WHEN 'SCJB'.
      gf_exit_proc = 'Y'.
      PERFORM schedule_background_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
  ENDCASE.
ENDFORM.                    " user_command
*&---------------------------------------------------------------------*
*&      Form  schedule_background_job
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_background_job.
  DATA: curr_report LIKE rsvar-report,
          l_jobname TYPE btcjob.
  DATA:lt_vari_desc TYPE TABLE OF varid WITH HEADER LINE,
           ls_variant LIKE vari-variant,
           ls_prev_variant LIKE vari-variant,
           ls_report LIKE rsvar-report,
           l_last_id(7).

  curr_report = sy-repid.
  l_jobname = 'SAP_COLLECTOR_FOR_PERFMONITOR'.
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
       EXPORTING
            in_jobname  = l_jobname
            in_repvarnt = ls_variant
            in_report   = 'RSCOLL00'.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ELSE.
    LEAVE LIST-PROCESSING.
  ENDIF.
*  ENDIF.

ENDFORM.                    " schedule_background_job
*&---------------------------------------------------------------------*
*&      Form  f4_usrtype
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_USRTYPE_LOW  text
*----------------------------------------------------------------------*
FORM f4_usrtype CHANGING p_usrtype_low.
  DATA: BEGIN OF ls_data,
                value TYPE domvalue_l,
                dtext TYPE val_text,
              END OF ls_data,
              lt_data   LIKE TABLE OF ls_data,
              lt_return TYPE TABLE OF ddshretval,
              ls_return LIKE LINE OF lt_return.

  SELECT a~domvalue_l AS value b~ddtext AS dtext
    INTO CORRESPONDING FIELDS OF TABLE lt_data
    FROM dd07l AS a INNER JOIN dd07t AS b
    ON a~domname = b~domname
    AND a~as4local = b~as4local
    AND a~valpos = b~valpos
    AND a~as4vers = b~as4vers
    WHERE a~domname = '/PSYNG/XUUSTYP'
    AND b~ddlanguage = sy-langu."#EC SAST_CI_GEN_CHECK

  IF   lt_data[] IS INITIAL.
*--Fallback to English
    SELECT a~domvalue_l AS value b~ddtext AS dtext
      INTO CORRESPONDING FIELDS OF TABLE lt_data
      FROM dd07l AS a INNER JOIN dd07t AS b
      ON a~domname = b~domname
      AND a~as4local = b~as4local
      AND a~valpos = b~valpos
      AND a~as4vers = b~as4vers
      WHERE a~domname = '/PSYNG/XUUSTYP'
      AND b~ddlanguage = 'EN'."#EC SAST_CI_GEN_CHECK
  ENDIF.

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
       EXPORTING
            retfield        = 'VALUE'
            value_org       = 'S'
            window_title    = 'Title'
       TABLES
            value_tab       = lt_data
            return_tab      = lt_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

  READ TABLE lt_return INTO ls_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = ls_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype
*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status USING it_extab TYPE slis_t_extab.
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  SET PF-STATUS 'SW_040' EXCLUDING lt_func.
ENDFORM.                    " pf_status_summary
*&---------------------------------------------------------------------*
*&      Form  show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM show_user_grp_cmp_invalid.
  DATA : alv_layout      TYPE slis_layout_alv,
         alv_grid_titl   TYPE lvc_title,
         i_fieldcat_alv  TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: ls_variant TYPE disvariant.

  CLEAR alv_layout.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  REFRESH i_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO i_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
          i_grid_title          = alv_grid_titl
          is_layout             = alv_layout
          it_fieldcat           = i_fieldcat_alv
          i_save                = 'A'
          is_variant            = ls_variant
   	TABLES
          t_outtab              = gt_rpoug_auth_fail
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " show_user_grp_cmp_invalid
