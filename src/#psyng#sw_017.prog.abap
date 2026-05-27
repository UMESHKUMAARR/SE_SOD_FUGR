**----------------------------------------------------------------------
**
* PROGRAM               : /PSYNG/SW_017
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_017 .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

TABLES: tstc,usr02.

TYPES: BEGIN OF typ_usr02,
         bname TYPE usr02-bname,
         class TYPE usr02-class,
       END OF typ_usr02.

DATA: gt_tstct TYPE STANDARD TABLE OF tstct WITH HEADER LINE.
DATA: gt_user_stat TYPE STANDARD TABLE OF /psyng/sw_entry WITH HEADER
LINE,
      gt_hitlist TYPE TABLE OF /psyng/hitlist WITH HEADER LINE.

DATA: BEGIN OF gt_months OCCURS 0.
DATA:   month LIKE sy-datum.
DATA: END OF gt_months.

CONSTANTS: c_se_def_job_txt TYPE btcjob VALUE 'SAP HISTORY CAPTURE JOB'.

DATA: BEGIN OF gt_usertcode OCCURS 0.
DATA:   bname LIKE usr02-bname,
        month(7) TYPE c,
        tcode LIKE tstc-tcode,
        ttext LIKE tstct-ttext,
      END OF gt_usertcode.

TYPE-POOLS: slis.                                      "For ALV call

DATA: gt_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: gt_sort_alv TYPE STANDARD TABLE OF slis_sortinfo_alv.

DATA: gt_critcodes TYPE HASHED TABLE OF /psyng/critcodes
      WITH UNIQUE KEY tcode WITH HEADER LINE.

DATA: gt_usr02 TYPE HASHED TABLE OF typ_usr02 WITH UNIQUE KEY bname
             WITH HEADER LINE,
      gt_usr02_temp TYPE HASHED TABLE OF typ_usr02 WITH UNIQUE KEY bname
             WITH HEADER LINE.

DATA: gv_dsp_mng_lock VALUE 'N',
      gv_dsp_slf_lock VALUE 'Y',
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      g_usercount TYPE i.
*--Global data for tcode origin details
DATA: BEGIN OF gs_tcode_role,
        bname LIKE /psyng/bc_uidn-bname,
*        name_text TYPE ad_namtext,
        tcode LIKE agr_tcodes-tcode,
        ttext LIKE tstct-ttext,
        agr_name LIKE agr_users-agr_name,
        profile  TYPE xuprofile,
      END OF gs_tcode_role.

DATA:gf_job_active TYPE c.
DATA: gt_tcode_role LIKE STANDARD TABLE OF gs_tcode_role INITIAL SIZE 0
      WITH HEADER LINE.
DATA: gt_fieldcat TYPE slis_t_fieldcat_alv,
      gt_layout TYPE slis_layout_alv,
      gt_sort TYPE slis_t_sortinfo_alv,
*DATA: usertype TYPE /psyng/xuustyp,
      gv_gltgb TYPE sy-datum.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
      gv_exit_proc TYPE flag,
      g_current_user TYPE sy-uname. "C0700
*-- Selection Screen

SELECTION-SCREEN: BEGIN OF BLOCK prer WITH FRAME TITLE text-019.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-012.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-013.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-010.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
*SELECTION-SCREEN: COMMENT 3(66) text-015.
SELECTION-SCREEN: COMMENT 3(70) text-011.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-018.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 2.
SELECTION-SCREEN: COMMENT 1(75) s_cmt MODIF ID cm1.
SELECTION-SCREEN:SKIP.
SELECTION-SCREEN:BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  1(30) text-026 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(30) text-027 USER-COMMAND sm37
MODIF ID sm.
SELECTION-SCREEN:END OF LINE.


SELECTION-SCREEN: END OF BLOCK prer .
SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-003.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-001.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: 1stmon(7) OBLIGATORY.
*PARAMETERS : 1stmon TYPE sy-datum.
SELECTION-SCREEN: COMMENT 28(30) text-000.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-002.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: lastmon(7) OBLIGATORY.
*PARAMETERS : lastmon TYPE sy-datum.
SELECTION-SCREEN: COMMENT 28(30) text-000.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(65) ava_txt.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

SELECTION-SCREEN: BEGIN OF BLOCK usr WITH FRAME TITLE text-004.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(25) text-005.
SELECT-OPTIONS: pbname FOR usr02-bname.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(25) text-024.
SELECT-OPTIONS:   pclass FOR gt_usr02-class.  "user group
SELECTION-SCREEN: END OF LINE.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.


SELECTION-SCREEN: SKIP 1.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(25) text-006.
SELECT-OPTIONS: ptcode FOR tstc-tcode.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(25) text-023.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: sodvrsio LIKE  /psyng/critcodes-vrsio MODIF ID cri.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
*Critical tcodes only
PARAMETERS: critcod AS CHECKBOX DEFAULT space USER-COMMAND crit.
SELECTION-SCREEN: COMMENT 3(50) text-008.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK usr.

DATA: g_1stmonth TYPE sy-datum, lastmont TYPE sy-datum.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM exelog.
  PERFORM initialize.

AT SELECTION-SCREEN OUTPUT.
  PERFORM check_job_status.

  LOOP AT SCREEN.
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

  ENDLOOP.

AT SELECTION-SCREEN.
  PERFORM user_command.

START-OF-SELECTION.
*BOC UMITTAL SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC UMITTAL SE VF scan changes-25/11/2024
  IF gv_exit_proc = 'Y'.
    EXIT.
  ENDIF.

  PERFORM on_scr_date_validation.

  CONCATENATE 1stmon+3(4) 1stmon(2) '01' INTO g_1stmonth.
  CONCATENATE lastmon+3(4) lastmon(2) '01' INTO lastmont.

  IF critcod = 'X'.
    SELECT tcode FROM /psyng/critcodes
           INTO CORRESPONDING FIELDS OF TABLE gt_critcodes
           WHERE vrsio = sodvrsio.
  ENDIF.

  PERFORM get_valid_users.

*  CHECK NOT gt_usr02[] IS INITIAL.

  IF NOT gt_usr02[] IS INITIAL.

   gt_usr02_temp[] = gt_usr02[].
    SORT gt_usr02_temp BY bname.
    DELETE ADJACENT DUPLICATES FROM gt_usr02_temp
      COMPARING bname.

    DESCRIBE TABLE gt_usr02_temp LINES g_usercount.

    LOOP AT gt_months.
      CHECK gt_months-month GE g_1stmonth AND gt_months-month LE
lastmont.

      CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
           EXPORTING
                startdate = gt_months-month
           TABLES
                user_stat = gt_user_stat
                hitlist   = gt_hitlist.

      SORT gt_user_stat BY account.
      SORT gt_hitlist BY account.

      LOOP AT gt_user_stat.
        CHECK gt_user_stat-entry_id(20) IN ptcode.
*      CHECK gt_user_stat-account IN pbname.
        READ TABLE gt_usr02 WITH TABLE KEY bname = gt_user_stat-account
                   TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
        ELSE.
*--Deleted users will also be reported.
          CHECK validusr IS INITIAL
            AND usrtype[] IS INITIAL
            AND exlckusr IS INITIAL.
          CHECK gt_user_stat-account IN pbname.
          SELECT SINGLE gltgb FROM usr02 INTO (gv_gltgb)
                 WHERE bname = gt_user_stat-account.
          CHECK sy-subrc NE 0.
        ENDIF.


        IF gt_user_stat-entry_id+72(1) = 'T'.   "transaction code
          IF critcod = 'X'.
            gt_usertcode-tcode = gt_user_stat-entry_id(20).
            READ TABLE gt_critcodes WITH TABLE KEY tcode =
gt_usertcode-tcode
                       TRANSPORTING NO FIELDS.
            CHECK sy-subrc = 0.
          ENDIF.

          CLEAR gt_usertcode.

*--- 21/07/2015 : Changing output format for date : HSHARMA

*          CONCATENATE gt_months-month+4(2) '/' gt_months-month(4)
*                      INTO gt_usertcode-month.

          CONCATENATE gt_months-month(4) '/' gt_months-month+4(2)
                                INTO gt_usertcode-month.

*--- End of change : HSHARMA

          gt_usertcode-bname = gt_user_stat-account.
          gt_usertcode-tcode = gt_user_stat-entry_id(20).

          READ TABLE gt_usertcode WITH KEY bname = gt_usertcode-bname
                                        tcode = gt_usertcode-tcode
                                        month = gt_usertcode-month.
          CHECK sy-subrc NE 0.
          APPEND gt_usertcode.
        ENDIF.
      ENDLOOP.

      LOOP AT gt_hitlist WHERE tcode <> space.
        READ TABLE gt_usr02 WITH TABLE KEY bname = gt_hitlist-account
                   TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
        ELSE.
*--Deleted users will also be reported.
          CHECK validusr IS INITIAL
            AND usrtype[] IS INITIAL
            AND exlckusr IS INITIAL.
          CHECK gt_hitlist-account IN pbname.
          SELECT SINGLE gltgb FROM usr02 INTO (gv_gltgb)
           WHERE bname = gt_hitlist-account.
          CHECK sy-subrc NE 0.
        ENDIF.
*--DHORIONS 2010/12/19 - Apply TCODE filter - Case 1670
        CHECK gt_hitlist-tcode IN ptcode.

        IF critcod = 'X'.
          READ TABLE gt_critcodes WITH TABLE KEY tcode =
gt_hitlist-tcode
                     TRANSPORTING NO FIELDS.
          CHECK sy-subrc = 0.
        ENDIF.

        CLEAR gt_usertcode.

*--- 21/07/2015 : Changing output format for date : HSHARMA

*          CONCATENATE gt_months-month+4(2) '/' gt_months-month(4)
*                      INTO gt_usertcode-month.

        CONCATENATE gt_months-month(4) '/' gt_months-month+4(2)
                              INTO gt_usertcode-month.

*--- End of change : HSHARMA

        gt_usertcode-bname = gt_hitlist-account.
        gt_usertcode-tcode = gt_hitlist-tcode.
        READ TABLE gt_usertcode WITH KEY bname = gt_usertcode-bname
                                tcode = gt_usertcode-tcode
                                month = gt_usertcode-month.
        CHECK sy-subrc NE 0.
        APPEND gt_usertcode.
      ENDLOOP.

      REFRESH: gt_user_stat, gt_hitlist.
    ENDLOOP.   "gt_months
  ENDIF.

*--Data is already sorted in the table
*  SORT: gt_usertcode.
*  DELETE ADJACENT DUPLICATES FROM gt_usertcode.

  SELECT * FROM tstct INTO TABLE gt_tstct
         WHERE sprsl = sy-langu.

  SORT gt_tstct BY tcode.

  LOOP AT gt_usertcode.
    READ TABLE gt_tstct WITH KEY sprsl = sy-langu tcode =
 gt_usertcode-tcode
           BINARY SEARCH.
    IF sy-subrc = 0.
      gt_usertcode-ttext = gt_tstct-ttext.
      MODIFY gt_usertcode.
    ELSE.
*    DELETE gt_usertcode.  "delete tcode
    ENDIF.
  ENDLOOP.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE s190(/psyng/sw).
  ELSE.
    IF gt_usertcode[] IS INITIAL.
      MESSAGE s174(/psyng/sw).
      EXIT.
    ELSE.
      MESSAGE s176(/psyng/sw).
    ENDIF.
  ENDIF.


  PERFORM output_alv.


*&---------------------------------------------------------------------*
*&      Form  OUTPUT_ALV
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_alv.
  DATA: lv_program    LIKE sy-repid,
        ls_alv_layout TYPE slis_layout_alv,
        ls_variant TYPE disvariant.


  lv_program = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = lv_program
            i_internal_tabname = 'GT_USERTCODE'
            i_inclname         = lv_program
       CHANGING
            ct_fieldcat        = gt_fieldcat_alv
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

  PERFORM build_alv_stuff.

  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
*      i_callback_top_of_page  = 'USER-TOP-OF-PAGE'
      i_callback_program      = lv_program
      it_sort                 = gt_sort_alv
      i_callback_pf_status_set = 'PF_STATUS'
      i_callback_user_command = 'USER_DOUBLE_CLICK_ON_SUMRY'
      i_callback_top_of_page = 'ALV_HEADER'
      is_layout               = ls_alv_layout
      it_fieldcat             = gt_fieldcat_alv
      i_save                  = 'A'
      is_variant              = ls_variant
    TABLES
      t_outtab                = GT_USERTCODE
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    "OUTPUT_ALV
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


  SET PF-STATUS 'SW_017' EXCLUDING lt_func.
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
  DATA : ls_alv_layout      TYPE slis_layout_alv,
         lv_alv_grid_titl   TYPE lvc_title,
         lt_fieldcat_alv  TYPE slis_t_fieldcat_alv.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  DATA: ls_variant TYPE disvariant.

  CLEAR ls_alv_layout.
  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.

  REFRESH lt_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'BNAME'.
  wa_fieldcat_alv-col_pos     = 1.
  wa_fieldcat_alv-seltext_l = text-h16.
  wa_fieldcat_alv-seltext_m = text-h16.
  wa_fieldcat_alv-seltext_s = text-h16.
  wa_fieldcat_alv-reptext_ddic = text-h16.
  APPEND wa_fieldcat_alv TO lt_fieldcat_alv.

  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'CLASS'.
  wa_fieldcat_alv-col_pos     = 2.
  wa_fieldcat_alv-seltext_l = text-h17.
  wa_fieldcat_alv-seltext_m = text-h17.
  wa_fieldcat_alv-seltext_s = text-h17.
  wa_fieldcat_alv-reptext_ddic = text-h17.
  APPEND wa_fieldcat_alv TO lt_fieldcat_alv.
  CLEAR wa_fieldcat_alv.

  wa_fieldcat_alv-fieldname = 'COMPANY'.
  wa_fieldcat_alv-col_pos     = 3.
  wa_fieldcat_alv-seltext_l = text-h18.
  wa_fieldcat_alv-seltext_m = text-h18.
  wa_fieldcat_alv-seltext_s = text-h18.
  wa_fieldcat_alv-reptext_ddic = text-h18.
  APPEND wa_fieldcat_alv TO lt_fieldcat_alv.
  CLEAR wa_fieldcat_alv.


  SORT gt_rpoug_auth_fail BY class company.

  CLEAR : sy-ucomm.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
   	EXPORTING
          i_grid_title          = lv_alv_grid_titl
          is_layout             = ls_alv_layout
          it_fieldcat           = lt_fieldcat_alv
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

*&---------------------------------------------------------------------*
*&      Form  user_double_click_on_sumry
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->R_UCOMM      text
*      -->RS_SELFIELD  text
*----------------------------------------------------------------------*
FORM user_double_click_on_sumry USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.
  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE GT_USERTCODE INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      PERFORM get_tcode_origin USING
      is_selfield-value GT_USERTCODE-bname .
      PERFORM fieldcat_drill_detail_tcode.
      PERFORM build_sort_detail_tcode.
      PERFORM drill_alv_detail_tcode.

    WHEN OTHERS.
*--No action

  ENDCASE.

ENDFORM.                    "user_double_click_on_sumry

*&---------------------------------------------------------------------*
*&      Form  initialize
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialize.
  DATA: l_st_txt(10),
        l_ls_txt(10),
        lt_directory TYPE STANDARD TABLE OF /psyng/sw_dates
                   WITH HEADER LINE,
* BOC by RGUPTA on 28.04.22
        lv_field TYPE string VALUE ' MIN( PERIODSTRT )',
        lv_table TYPE c LENGTH 30 VALUE 'SWNCMONI',
        lv_where TYPE string,
        lv_relid TYPE c LENGTH 2 VALUE 'WM',
        lv_comp  TYPE c LENGTH 5 VALUE 'TOTAL',
        lv_value TYPE swncdatum,
        lv_count TYPE i.
* EOC by RGUPTA on 28.04.22
*  DATA : l_value TYPE /psyng/param_value.
*
**--Valid & Dialog Users only
*  SELECT SINGLE value FROM /psyng/swconfig INTO l_value WHERE
*         param = 'DFLT_VALID_DIALOG'.
*  IF l_value = 'Y'.
*    validusr = 'X'.
*  ELSEIF l_value = 'N'.
*    validusr = ' '.
*  ENDIF.
*  CLEAR l_value.

*-- Get History dates
  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = lt_directory.


  LOOP AT lt_directory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF g_1stmonth IS INITIAL OR g_1stmonth > lt_directory-startdate.
      g_1stmonth = lt_directory-startdate.
    ENDIF.
    IF lastmont < lt_directory-startdate.
      lastmont = lt_directory-startdate.
    ENDIF.
    gt_months-month = lt_directory-startdate.
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
  FROM (lv_table)
  INTO lv_value
  WHERE (lv_where). "#EC SAST_CI_GEN_CHECK
  ENDSELECT.
  IF sy-subrc IS INITIAL.
    g_1stmonth = lv_value.
  ENDIF.
  ENDIF.
* EOC by RGUPTA on 28.04.22
  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth(4) INTO 1stmon.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO lastmon.


  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth(4) INTO l_st_txt.
  CONCATENATE lastmont+4(2) '/' lastmont(4) INTO l_ls_txt.

  CONCATENATE text-014 l_st_txt text-015 l_ls_txt
              INTO ava_txt SEPARATED BY space.
ENDFORM.                    "initialize
*&---------------------------------------------------------------------*
*&      Form  build_alv_stuff
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_alv_stuff.

  IF GT_USERTCODE[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv,
        ls_sort          TYPE slis_sortinfo_alv.


  CLEAR: ls_sort, gt_sort_alv.
  REFRESH: gt_sort_alv.
  ls_sort-spos = '1'.
  ls_sort-fieldname = 'BNAME'.
  ls_sort-tabname = 'GT_USERTCODE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort_alv.

*--- 21/07/2015 : Sorting output table from month : HSHARMA
  ls_sort-spos = '2'.
  ls_sort-fieldname = 'MONTH'.
  ls_sort-tabname = 'GT_USERTCODE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort_alv.

*--- End of change : HSHARMA

*  ls_sort-spos = '3'.
*  ls_sort-fieldname = 'TCODE'.
*  ls_sort-tabname = 'GT_USERTCODE'.
*  ls_sort-up = 'X'.
*  APPEND ls_sort TO gt_sort_alv.

  wa_fieldcat_alv-seltext_l = text-016.
  wa_fieldcat_alv-seltext_m = text-016.
  wa_fieldcat_alv-seltext_s = text-016.
  wa_fieldcat_alv-reptext_ddic = text-016.
*  wa_fieldcat_alv-inttype = 'D'.
  MODIFY gt_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      inttype
                   WHERE
                      fieldname = 'MONTH'.

  wa_fieldcat_alv-seltext_l = text-017.
  wa_fieldcat_alv-seltext_m = text-017.
  wa_fieldcat_alv-seltext_s = text-017.
  wa_fieldcat_alv-reptext_ddic = text-017.
  MODIFY gt_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-hotspot = 'X'..
  MODIFY gt_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.


ENDFORM.                    " build_sort_order
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exelog.
  DATA: lt_exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  lt_exelog-mandt         = sy-mandt.
  lt_exelog-repid         = sy-repid.
  lt_exelog-uname         = g_current_user."sy-uname. C0700
  lt_exelog-datum         = sy-datum.
  lt_exelog-uzeit         = sy-uzeit.
  APPEND lt_exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = lt_exelog.
  COMMIT WORK.
ENDFORM.                    " lt_exelog
*&---------------------------------------------------------------------*
*&      Form  get_valid_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_valid_users.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  DATA: ls_usr02 TYPE typ_usr02,
        l_gltgv  TYPE usr02-gltgv,
        l_gltgb  TYPE usr02-gltgb,
        l_ustyp  TYPE usr02-ustyp,
        l_uflag  TYPE usr02-uflag,
        i_include_locked TYPE flag,
        i_include_expire TYPE flag.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE.

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
            it_userlist       = pbname
            it_grouplist      = pclass
            it_usertype       = usrtype.
*
  CHECK NOT lt_users[] IS INITIAL.

  LOOP AT lt_users.
    ls_usr02-bname = lt_users-bname.
    ls_usr02-class = lt_users-class.
    INSERT ls_usr02 INTO TABLE gt_usr02 .
  ENDLOOP.





*  IF validusr IS INITIAL.
*    SELECT bname class INTO TABLE gt_usr02 FROM usr02
*           WHERE bname IN pbname
*             AND class IN pclass.
*  ELSE.
*    PERFORM get_sw_repo_conifg.
*    SELECT bname class gltgv gltgb ustyp uflag
*           INTO (wa_usr02-bname, wa_usr02-class, l_gltgv, l_gltgb,
*                 l_ustyp, l_uflag)
*           FROM usr02
*           WHERE bname IN pbname AND
*                 ustyp = 'A' AND
*                 class IN pclass.
*      IF l_gltgv IS INITIAL.  "valid from date
*        l_gltgv = '00010101'.
*      ENDIF.
*      IF l_gltgb IS INITIAL.  "valid to date
*        l_gltgb = '99991231'.
*      ENDIF.
*      IF l_gltgv <= sy-datum AND l_gltgb >= sy-datum.
**CASE SF 1405
*        l_uflagx = l_uflag."unicode
*        IF l_uflagx O yusloc OR "locked by admin
*           l_uflagx O yugloc.   "locked by CUA admin
**      --User is locked by Local or Global Administrator
*          IF gv_dsp_mng_lock = 'Y'.
*            INSERT wa_usr02 INTO TABLE gt_usr02.
*          ENDIF.
*        ELSEIF l_uflagx O yulock.
**      --User is locked by failed logins
*          IF gv_dsp_slf_lock = 'Y'.
*            INSERT wa_usr02 INTO TABLE gt_usr02.
*          ENDIF.
*        ELSE.
**      --User is active
*          INSERT wa_usr02 INTO TABLE gt_usr02.
*        ENDIF.
**        CASE l_uflag.
**          WHEN 0.   "user ID unlocked
**            INSERT wa_usr02 INTO TABLE gt_usr02.
**          WHEN 64.  "user ID locked by system manager
**            IF gv_dsp_mng_lock = 'Y'.
**              INSERT wa_usr02 INTO TABLE gt_usr02.
**            ENDIF.
**          WHEN 128. "user ID locked due to incorrect logins
**            IF gv_dsp_slf_lock = 'Y'.
**              INSERT wa_usr02 INTO TABLE gt_usr02.
**            ENDIF.
**        ENDCASE.
*      ENDIF.
*    ENDSELECT.
*  ENDIF.
*DHO 20101202
*  LOOP AT gt_usr02 INTO wa_usr02.
*    CHECK NOT wa_usr02-class IS INITIAL.
*
**   Check user group authority
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*             ID 'CLASS' FIELD wa_usr02-class.
*    IF sy-subrc <> 0.
*      DELETE gt_usr02 WHERE class = wa_usr02-class.
*      gf_missing_auth_ugroup = 'X'.
*    ENDIF.
*  ENDLOOP.
*DHO 20101202

  LOOP AT gt_usr02.
    lt_uinfo-bname = gt_usr02-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  IF NOT lt_uinfo[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
       vrsio                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
       i_name_only              = 'X'
       i_mr_company             = 'X'
      TABLES
        sw_uinfo                 = lt_uinfo.
    .
  ENDIF.
  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
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
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD lt_uinfo-class
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
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
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      IF critcod = 'X'.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO'  FIELD sodvrsio
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
        DELETE gt_usr02 WHERE bname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.


ENDFORM.                    " get_valid_users

*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_sw_repo_conifg.
  DATA: ls_swconfig TYPE /psyng/swconfig.
  CLEAR: ls_swconfig.
  se_config_param 'REP_USR_LOK_DSP_MGR' ls_swconfig-value.
  IF ls_swconfig-value = 'Y'.
    gv_dsp_mng_lock = 'Y'.
  ENDIF.
  CLEAR ls_swconfig.
  se_config_param 'REP_USR_LOK_DSP_SLF' ls_swconfig-value.
  IF ls_swconfig-value = 'N'.
    gv_dsp_slf_lock = 'N'.
  ENDIF.
ENDFORM.                    " get_sw_repo_conifg


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: lt_header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        lv_count TYPE i,
        l_exetime(8) TYPE c,
        l_exedate TYPE char10,
        c_usercount(6) TYPE c,
        lv_count1 TYPE string,
        lv_alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c.
  .
  wa-typ = 'H'.
  wa-info = 'User Execution History Report'(h01).
  APPEND wa TO lt_header.
*SOD Version.
  IF critcod = 'X'.
    wa-typ = 'S'.
    wa-key = 'Sod Version'(h02).
    SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
    WHERE vrsio = sodvrsio.
    CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
    APPEND wa TO lt_header.
  ENDIF.
*Date
  wa-typ = 'S'.
  wa-key = 'Date'(h03).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname      C0700
   text-h04 l_exedate l_exetime
              INTO wa-info SEPARATED BY SPACE.
  APPEND wa TO lt_header.

*Summary.
  wa-typ = 'S'.
  wa-key = 'Summary'(h05).
  c_usercount = g_usercount.
  CONCATENATE c_usercount text-h06 INTO wa-info SEPARATED BY space.
  APPEND wa TO lt_header.

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = lt_header.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_tcode_origin
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_tcode_origin USING i_tcode i_bname TYPE xubname ."i_name.
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
         lv_lf_found TYPE flag.

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
    SELECT DISTINCT profn  FROM ust10s INTO CORRESPONDING FIELDS OF
    TABLE lt_ust10s FOR ALL ENTRIES IN lt_auths
    WHERE auth = lt_auths-auth.
*--Get the roles
    IF NOT lt_ust10s[] IS INITIAL.
SELECT * FROM agr_prof INTO TABLE lt_roles FOR ALL ENTRIES IN lt_ust10s
                                        WHERE profile = lt_ust10s-profn.
      IF NOT lt_roles[] IS INITIAL.
      SELECT * FROM agr_users INTO TABLE lt_usrroles FOR ALL ENTRIES IN
                                                         lt_roles WHERE
                                                    uname = i_bname AND
                                           agr_name = lt_roles-agr_name.

        LOOP AT lt_usrroles.
          gt_tcode_role-bname     = i_bname.

*      gt_tcode_role-name_text = i_name.
          gt_tcode_role-tcode     = i_tcode.
          READ TABLE lt_roles WITH KEY agr_name = lt_usrroles-agr_name.
          gt_tcode_role-agr_name  = lt_roles-agr_name.
          gt_tcode_role-profile   = lt_roles-profile.
          APPEND gt_tcode_role.
          lv_lf_found = 'X'.
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
        WHILE l_subrc = 0 AND l_subprof_maxlevel < 0.
          if not lt_profiles[] is initial.
            SELECT DISTINCT profn subprof     "#EC CI_SEL_NESTED
            FROM ust10c APPENDING CORRESPONDING FIELDS OF
            TABLE lt_profiles FOR ALL ENTRIES IN lt_profiles
            WHERE subprof = lt_profiles-profn.
          endif.
          l_subrc = sy-subrc.
          LOOP AT lt_profiles.
            DELETE lt_profiles WHERE profn = lt_profiles-subprof.
          ENDLOOP.
          SUBTRACT 1 FROM l_subprof_maxlevel.
        ENDWHILE.

        SORT lt_profiles BY profn.
        DELETE ADJACENT DUPLICATES FROM lt_profiles COMPARING profn.
        IF NOT lt_profiles[] IS INITIAL.
       SELECT * FROM ust04 INTO TABLE lt_usrprofiles FOR ALL ENTRIES IN
                                  lt_profiles WHERE bname = i_bname AND
                                            profile = lt_profiles-profn.
          LOOP AT lt_usrprofiles.
            gt_tcode_role-bname     = i_bname.
*    gt_tcode_role-name_text = i_name.
            gt_tcode_role-tcode     = i_tcode.
            CLEAR gt_tcode_role-agr_name.
            gt_tcode_role-profile   = lt_usrprofiles-profile.
            APPEND gt_tcode_role.
            lv_lf_found = 'X'.

          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDIF.
  IF lv_lf_found <> 'X'.
*--User no longer has tcode
    gt_tcode_role-bname     = i_bname.
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
  TYPES: BEGIN OF t_tran,
           tcode TYPE tstct-tcode,
           ttext TYPE tstct-ttext,
         END OF t_tran.

  DATA: ls_tran TYPE t_tran.

  STATICS: lt_tran TYPE HASHED TABLE OF t_tran WITH UNIQUE KEY tcode.


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

*  ls_fieldcat-fieldname = 'NAME_TEXT'.
*  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
*  ls_fieldcat-seltext_l = 'Name'(d02).
*  ls_fieldcat-col_pos = 2.
*  APPEND ls_fieldcat TO gt_fieldcat.
*  CLEAR ls_fieldcat.

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

*  ls_sort-spos = '2'.
*  ls_sort-fieldname = 'NAME_TEXT'.
*  ls_sort-tabname = 'GT_TCODE_ROLE'.
*  ls_sort-up = 'X'.
*  APPEND ls_sort TO gt_sort.
*  CLEAR ls_sort.

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

  gt_layout-zebra = 'X'.
  gt_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program = l_program
            is_layout          = gt_layout
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
    lastmont = l_edate.
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
      CONCATENATE text-ed1 text-d07 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d07 text-p04 INTO l_message SEPARATED BY space.
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
      CONCATENATE text-ed1 text-d08 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d08 text-p04 INTO l_message SEPARATED BY space.
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
             lth_return TYPE TABLE OF ddshretval,
             wah_return LIKE LINE OF lth_return.

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
            return_tab      = lth_return
       EXCEPTIONS
            parameter_error = 1
            no_values_found = 2
            OTHERS          = 3.

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    p_usrtype_low = wah_return-fieldval.
  ENDIF.

ENDFORM.                    " f4_usrtype
*&---------------------------------------------------------------------*
*&      Form  check_job_status
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_job_status.

  DATA: lv_se_job_txt_msg(77) TYPE c.

  PERFORM get_job_name USING c_se_def_job_txt
                       CHANGING lv_se_job_txt_msg.

  s_cmt = lv_se_job_txt_msg.
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
*      -->P_2910   text
*      -->P_SE_DEF_JOB_TXT  text
*      <--P_SE_JOB_TXT_MSG  text
*----------------------------------------------------------------------*
FORM get_job_name USING    i_default  TYPE tbtcp-jobname
                  CHANGING e_job_msg .

  DATA: lv_t_icon TYPE icon-id,
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
          ) AND o~status    = 'S'."#EC SAST_CI_GEN_CHECK

  IF sy-subrc EQ 0.
    gf_job_active = 'X'.
    lv_t_icon = '@08@'.
    IF NOT l_freq_h IS INITIAL.
      CONCATENATE lv_t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_h 'hours'(s05)
      INTO e_job_msg SEPARATED BY space.
    ELSEIF NOT l_freq_d IS INITIAL.
      CONCATENATE lv_t_icon 'History Capture job set up correctly;'(s03)
      'runs every'(s04) l_freq_d 'days'(s06)
      INTO e_job_msg SEPARATED BY space.
    ENDIF.

  ELSE.
    lv_t_icon = '@0A@'.
    CONCATENATE lv_t_icon
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
      gv_exit_proc = 'Y'.
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
  DATA: lv_curr_report LIKE rsvar-report,
        l_jobname TYPE btcjob.
  DATA: lt_vari_desc TYPE TABLE OF varid WITH HEADER LINE,
           ls_variant LIKE vari-variant,
           ls_prev_variant LIKE vari-variant,
           ls_report LIKE rsvar-report,
           l_last_id(7).

*  CLEAR: lv_curr_report, curr_variant.
*
*  ls_report = sy-repid.
*
*  PERFORM get_next_variant_id  TABLES  lt_vari_desc
*                               CHANGING
*                                       ls_variant
*                                       l_last_id
*                                       ls_report.
*  PERFORM fill_sel_screen_fields_to_tab.
  lv_curr_report = sy-repid.
*  curr_variant = ls_variant.
*
*  CALL FUNCTION 'RS_CREATE_VARIANT'
*       EXPORTING
*            curr_report   = lv_curr_report
*            curr_variant  = curr_variant
*            vari_desc     = lt_vari_desc
*       TABLES
*            vari_contents = vari_contents
*            vari_text     = vari_text.
*
*  IF sy-subrc <> 0.
*    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
*            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
*  ELSE.
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
*&      Form  get_next_variant_id
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_VARI_DESC  text
*      <--P_LS_VARIANT  text
*      <--P_L_LAST_ID  text
*      <--P_LS_REPORT  text
*----------------------------------------------------------------------*
FORM get_next_variant_id TABLES vari_desc STRUCTURE varid
 CHANGING variant LIKE vari-variant
          last_id
          report.
  DATA: lv_oldnumber(7) TYPE n, lv_oldnumber_c(7).
*variant
  CLEAR: variant, vari_desc.
  REFRESH: vari_desc.

  SELECT variant INTO variant FROM varid WHERE
                      report = report AND
                      variant LIKE '/PSYNG/%'
    order by variant DESCENDING.
    lv_oldnumber = variant+7(7).
    exit.
  ENDSELECT.
  last_id = lv_oldnumber.
  IF sy-subrc NE 0.
    variant = '/PSYNG/0000000'.
  ELSE.
    lv_oldnumber = lv_oldnumber + 1.
    MOVE lv_oldnumber TO lv_oldnumber_c.
    CONCATENATE '/PSYNG/' lv_oldnumber_c INTO variant.
  ENDIF.

  vari_desc-report = report.
  vari_desc-variant = variant.
  APPEND vari_desc.


ENDFORM.                    " get_next_variant_id
*&---------------------------------------------------------------------*
*&      Form  fill_sel_screen_fields_to_tab
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab.
*  DATA : lt_variant_params_1 TYPE rsparams OCCURS 0 WITH HEADER LINE.
*
**--Users
*  LOOP AT PBNAME.
*    lt_variant_params_1-selname = 'PBNAME'.
*    lt_variant_params_1-kind = 'S'.
*    MOVE-CORRESPONDING PBNAME TO lt_variant_params_1.
*    APPEND lt_variant_params_1.
*  ENDLOOP.
*  IF sy-subrc <> 0.
**--Add empty line if there are no users to be able to compare variants
*    lt_variant_params_1-selname = 'PBNAME'.
*    lt_variant_params_1-kind = 'S'.
*    APPEND lt_variant_params_1.
*  ENDIF.
*
*  lt_variant_params_1-selname = '1STMON'.
*  lt_variant_params_1-kind = 'P'.
*  lt_variant_params_1-sign = 'I'.
*  lt_variant_params_1-option = 'EQ'.
*  lt_variant_params_1-low = 1stmon.
*  APPEND lt_variant_params_1.
*
*  lt_variant_params_1-selname = 'LASTMON'.
*  lt_variant_params_1-kind = 'P'.
*  lt_variant_params_1-sign = 'I'.
*  lt_variant_params_1-option = 'EQ'.
*  lt_variant_params_1-low = lastmon.
*  APPEND lt_variant_params_1.
*
*   LOOP AT s_class.
*    lt_variant_params_1-selname = 'S_CLASS'.
*    lt_variant_params_1-kind = 'S'.
*    MOVE-CORRESPONDING s_class TO lt_variant_params_1.
*    APPEND lt_variant_params_1.
*  ENDLOOP.
*
*  lt_variant_params_1-selname = 'VALIDUSR'.
*  lt_variant_params_1-kind = 'P'.
*  lt_variant_params_1-sign = 'I'.
*  lt_variant_params_1-option = 'EQ'.
*  lt_variant_params_1-low = validusr.
*  APPEND lt_variant_params_1.
*
*   LOOP AT s_class.
*    lt_variant_params_1-selname = 'S_CLASS'.
*    lt_variant_params_1-kind = 'S'.
*    MOVE-CORRESPONDING s_class TO lt_variant_params_1.
*    APPEND lt_variant_params_1.
*  ENDLOOP.
*

ENDFORM.                    " fill_sel_screen_fields_to_tab
