*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_016
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
REPORT /psyng/sw_016 .
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.
TABLES: usr02, usgrp.

TYPE-POOLS: slis.                                      "For ALV call
DATA: g_program         LIKE sy-repid.                   "For ALV call
DATA: gs_fieldcat_alv  TYPE slis_t_fieldcat_alv.        "For ALV call

DATA: BEGIN OF term3 OCCURS 0,
        terminalid LIKE sapwlhitl-terminalid,
        bname LIKE sapwlhitl-account,
        name_text LIKE /psyng/bc_userid_name-name_full,
      END OF term3.

DATA: g_reject       TYPE /psyng/bapiflagx,
      g_dsp_mng_lock TYPE /psyng/swconfig-value,
      g_dsp_slf_lock TYPE /psyng/swconfig-value.

DATA: gt_term1 LIKE term3 OCCURS 0 WITH HEADER LINE.
DATA: gt_term2 LIKE term3 OCCURS 0 WITH HEADER LINE.

DATA: gt_idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
WITH HEADER LINE.
DATA: gt_hitlist TYPE STANDARD TABLE OF /psyng/hitlist WITH HEADER LINE.

DATA: BEGIN OF gt_months OCCURS 0.
DATA:   month LIKE sy-datum.
DATA: END OF gt_months.

DATA: BEGIN OF username3 OCCURS 0.
DATA:   bname LIKE usr21-bname,
        name_first LIKE adrp-name_first,
        name_last LIKE adrp-name_last,
        persa LIKE /psyng/sw_uinfo-persa,
        kostl LIKE /psyng/sw_uinfo-kostl,
        trdat LIKE usr02-trdat,
        status(10),
      END OF username3.
*****************************************


*****************************************
DATA: gt_username2 LIKE username3 OCCURS 0 WITH HEADER LINE.
DATA: gt_username1 LIKE username3 OCCURS 0 WITH HEADER LINE.
DATA: gt_sw_uinfo LIKE /psyng/sw_uinfo OCCURS 0 WITH HEADER LINE.
DATA: gt_sw_uinfo_final LIKE /psyng/sw_uinfo OCCURS 0 WITH HEADER LINE.
DATA : gt_comp_users TYPE TABLE OF v_usr_name WITH HEADER LINE.

DATA: g_1stmonth TYPE sy-datum,
      g_lastmont TYPE sy-datum,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      g_1mon_cal TYPE sy-datum,
      g_lmn_cal TYPE sy-datum,
      g_current_user TYPE sy-uname. "C0700


SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-002.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: byname RADIOBUTTON GROUP 1 DEFAULT 'X'.
SELECTION-SCREEN: COMMENT 3(20) text-001.
SELECT-OPTIONS: pbname FOR usr02-bname.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(20) text-018.
SELECT-OPTIONS: s_class FOR usr02-class.
SELECTION-SCREEN: END OF LINE.

*PARAMETER: validusr AS CHECKBOX.       "Valid and Dialog users only
*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

SELECTION-SCREEN: SKIP 3.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: bytrm RADIOBUTTON GROUP 1.
SELECTION-SCREEN: COMMENT 3(65) text-003.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 15(12) text-005.
SELECTION-SCREEN: POSITION 27.
PARAMETERS: 1stmon(7) OBLIGATORY.
SELECTION-SCREEN: COMMENT 35(20) text-004.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 15(12) text-006.
SELECTION-SCREEN: POSITION 27.
PARAMETERS: lastmon(7) OBLIGATORY.
SELECTION-SCREEN: COMMENT 35(20) text-004.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 15(55) ava_txt.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

INITIALIZATION.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  PERFORM init.
  PERFORM exelog.

AT SELECTION-SCREEN OUTPUT.

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

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

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
  IF bytrm = 'X'.
    PERFORM on_scr_date_validation.
  ENDIF.
  PERFORM get_users.

  IF  NOT gt_sw_uinfo_final[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
*     VRSIO                    = sodvrsio
*     ENHANCED_SCANTABLE       = ''
       i_name_only              = ' '
       i_mr_company             = 'X'
      TABLES
        sw_uinfo                 = gt_sw_uinfo_final.
    LOOP AT gt_sw_uinfo_final.
      IF NOT gt_sw_uinfo_final-class IS INITIAL AND
         NOT gt_sw_uinfo_final-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD gt_sw_uinfo_final-class
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD gt_sw_uinfo_final-company.
        IF sy-subrc <> 0.
          DELETE gt_sw_uinfo_final .
          gf_missing_auth_ugroup = 'X'.
          CONTINUE.
        ENDIF.
      ELSEIF NOT gt_sw_uinfo_final-class IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD gt_sw_uinfo_final-class
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
        IF sy-subrc <> 0.
          DELETE gt_sw_uinfo_final .
          gf_missing_auth_ugroup = 'X'.
          CONTINUE.
        ENDIF.
      ELSEIF NOT gt_sw_uinfo_final-company IS INITIAL.
        AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
             ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
             ID 'Y&SW_COMP'   FIELD gt_sw_uinfo_final-company.
        IF sy-subrc <> 0.
          DELETE gt_sw_uinfo_final .
          gf_missing_auth_ugroup = 'X'.
          CONTINUE.
        ENDIF.
      ENDIF.
*  ENDLOOP.

      IF gf_missing_auth_ugroup = 'X'.
        MESSAGE s398(00) WITH text-008.
      ENDIF.
    ENDLOOP.
  ENDIF.

  IF byname = 'X'.
    PERFORM get_similar_users_by_name.
  ELSEIF bytrm = 'X'.
    PERFORM mult_user_same_trmnl.
  ENDIF.


*---------------------------------------------------------------------*
*       FORM alv_output                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_output.
  DATA: alv_layout    TYPE slis_layout_alv,            "For ALV call
        alv_grid_titl TYPE lvc_title,                  "For ALV call
        ls_variant    TYPE disvariant.


  g_program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'USERNAME3'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gs_fieldcat_alv
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

  CHECK sy-subrc = 0.
  PERFORM change_catalog_texts.

*  MOVE text-000 TO alv_grid_titl.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_grid_title       = alv_grid_titl
            i_callback_top_of_page = 'ALV_HEADER'
            i_callback_program = g_program
            is_layout          = alv_layout
            it_fieldcat        = gs_fieldcat_alv
            i_save             = 'A'
            is_variant         = ls_variant
       TABLES
            t_outtab           = username3
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " alv_output

*&---------------------------------------------------------------------*
*&      Form  init
*&---------------------------------------------------------------------*
FORM init.
  DATA: st_txt(10), ls_txt(10).



  CALL FUNCTION '/PSYNG/SW_GET_DIRECTORY'
       TABLES
            idirectory = gt_idirectory.

  LOOP AT gt_idirectory. " WHERE periodtype = 'M' AND hostid = 'TOTAL'.
    IF g_1stmonth IS INITIAL OR g_1stmonth > gt_idirectory-startdate.
      g_1stmonth = gt_idirectory-startdate.
    ENDIF.
    IF g_lastmont IS INITIAL OR g_lastmont < gt_idirectory-startdate.
      g_lastmont = gt_idirectory-startdate.
    ENDIF.
    gt_months-month = gt_idirectory-startdate.
    APPEND gt_months.
  ENDLOOP.

  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth(4) INTO 1stmon.
  CONCATENATE g_lastmont+4(2) '/' g_lastmont(4) INTO lastmon.


  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth+6(2) '/' g_1stmonth(4)
              INTO st_txt.
  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
              INTO ls_txt.
  CONCATENATE text-007 st_txt text-006 ls_txt
              INTO ava_txt SEPARATED BY space.

ENDFORM.                    " init
*&---------------------------------------------------------------------*
*&      Form  comparison
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM comparison.
  LOOP AT gt_sw_uinfo_final.
    MOVE-CORRESPONDING gt_sw_uinfo_final TO username3.
    IF gt_sw_uinfo_final-uflag GE 64.
      username3-status = text-013.
    ELSE.
      CLEAR username3-status.
    ENDIF.
    APPEND username3.
  ENDLOOP.

ENDFORM.                    " comparison
*&---------------------------------------------------------------------*
*&      Form  change_catalog_texts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM change_catalog_texts.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = text-010.
  wa_fieldcat_alv-seltext_m = text-010.
  wa_fieldcat_alv-seltext_s = text-011.
  wa_fieldcat_alv-reptext_ddic = text-010.
  MODIFY gs_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TRDAT'.

  wa_fieldcat_alv-seltext_l = text-012.
  wa_fieldcat_alv-seltext_m = text-012.
  wa_fieldcat_alv-seltext_s = text-012.
  wa_fieldcat_alv-reptext_ddic = text-012.
  MODIFY gs_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'STATUS'.

ENDFORM.                    " change_catalog_texts
*&---------------------------------------------------------------------*
*&      Form  get_user_logon_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_user_logon_info.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x.

  LOOP AT username3.
    SELECT SINGLE * FROM usr02 WHERE bname = username3-bname.
    CHECK sy-subrc = 0.
    username3-trdat = usr02-trdat.
*--Sf CASE 1405
    l_uflagx = usr02-uflag."unicode
*    IF usr02-uflag GE 64.
    IF l_uflagx O yusloc OR "locked by admin
       l_uflagx O yugloc.   "locked by CUA admin
      username3-status = text-013.
    ENDIF.
    MODIFY username3.
    gt_sw_uinfo-bname = username3-bname.
  ENDLOOP.
ENDFORM.                    " get_user_logon_info
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  get_similar_users_by_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_similar_users_by_name.
  PERFORM comparison.
  SORT username3 BY bname name_first name_last  .
  DELETE ADJACENT DUPLICATES FROM username3 COMPARING bname name_first
name_last .

  IF username3[] IS INITIAL.
    MESSAGE s174(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
  PERFORM alv_output.
ENDFORM.                    " get_similar_users_by_name
*&---------------------------------------------------------------------*
*&      Form  mult_user_same_trmnl
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM mult_user_same_trmnl.
  DATA: ls_variant TYPE disvariant.
  DATA: ls_grid_setting TYPE lvc_s_glay.
  DATA: lt_isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
  DATA: l_sort TYPE slis_sortinfo_alv,
        l_title       TYPE lvc_title,
        ls_alv_layout    TYPE slis_layout_alv.            "For ALV call


  LOOP AT gt_sw_uinfo_final.
    IF gt_sw_uinfo_final-ustyp NE 'A'.
      DELETE gt_sw_uinfo_final INDEX sy-tabix.
    ENDIF.
  ENDLOOP.


  LOOP AT gt_months.
    CHECK gt_months-month GE g_1stmonth AND gt_months-month LE
g_lastmont.

    CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
         EXPORTING
              startdate = gt_months-month
         TABLES
              hitlist   = gt_hitlist.

    LOOP AT gt_hitlist.
      CHECK NOT gt_hitlist-tcode IS INITIAL.
      gt_term1-bname = gt_hitlist-account.
      gt_term1-terminalid = gt_hitlist-terminalid.
      APPEND gt_term1.
    ENDLOOP.
    REFRESH: gt_hitlist.
  ENDLOOP.   "months

  SORT gt_term1.
  DELETE ADJACENT DUPLICATES FROM gt_term1.

  gt_term2[] = gt_term1[].

  LOOP AT gt_term1.
    LOOP AT gt_term2 WHERE terminalid = gt_term1-terminalid.
      IF gt_term1-bname <> gt_term2-bname.
        CLEAR term3.
        MOVE-CORRESPONDING gt_term1 TO term3.
        APPEND term3.
        CLEAR term3.
        MOVE-CORRESPONDING gt_term2 TO term3.
        APPEND term3.
      ENDIF.
    ENDLOOP.
  ENDLOOP.
  REFRESH: gt_term1, gt_term2.

  SORT term3.
  DELETE ADJACENT DUPLICATES FROM term3.

  LOOP AT term3.
   READ TABLE gt_sw_uinfo_final WITH KEY bname = term3-bname BINARY
SEARCH
             .
    CHECK sy-subrc = 0.
    term3-name_text = gt_sw_uinfo_final-name_text.
    MODIFY term3.
  ENDLOOP.

  g_program = sy-repid.
  ls_grid_setting-coll_top_p = 'X'.
  ls_variant-report = sy-repid.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = g_program
            i_internal_tabname = 'TERM3'
            i_inclname         = g_program
       CHANGING
            ct_fieldcat        = gs_fieldcat_alv
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

  ls_alv_layout-zebra = 'X'.
  ls_alv_layout-colwidth_optimize = 'X'.
  ls_alv_layout-get_selinfos = 'X'.

  l_sort-spos = '1'.
  l_sort-fieldname = 'TERMINALID'.
  l_sort-tabname = 'TERM3'.
  APPEND l_sort TO lt_isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'TERM3'.
  APPEND l_sort TO lt_isort.

  PERFORM change_catalog_info.

*  l_title = text-003.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
*            i_grid_title       = l_title
            i_callback_top_of_page = 'ALV_HEADER'
            i_save             = 'A'
            is_variant         = ls_variant
            i_callback_program = g_program
            it_sort            = lt_isort
*            i_grid_settings    = grid_setting
            is_layout          = ls_alv_layout
            it_fieldcat        = gs_fieldcat_alv
       TABLES
            t_outtab           = term3
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.                    " mult_user_same_trmnl

*&---------------------------------------------------------------------*
*&      Form  change_catalog_info
*&---------------------------------------------------------------------*
FORM change_catalog_info.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = text-014.
  wa_fieldcat_alv-seltext_m = text-014.
  wa_fieldcat_alv-seltext_s = text-015.
  wa_fieldcat_alv-reptext_ddic = text-014.
  MODIFY gs_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-seltext_l = text-016.
  wa_fieldcat_alv-seltext_m = text-016.
  wa_fieldcat_alv-seltext_s = text-017.
  wa_fieldcat_alv-reptext_ddic = text-016.
  MODIFY gs_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'NAME_TEXT'.

ENDFORM.                    " change_catalog_info
*&---------------------------------------------------------------------*
*&      Form  get_user_org_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_user_org_info.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
       TABLES
            sw_uinfo = gt_sw_uinfo.
ENDFORM.                    " get_user_org_info
*&---------------------------------------------------------------------*
*&      Form  get_users
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users.

  RANGES: iusr02 FOR /psyng/bc_uidn-bname.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE,
         i_include_locked TYPE flag,
         i_include_expire TYPE flag.




  SELECT
  a~bname
  b~name_first
  b~name_last
  b~name_text
 INTO CORRESPONDING FIELDS OF TABLE gt_sw_uinfo FROM usr02 AS a INNER
JOIN
v_usr_name AS b ON a~bname = b~bname
WHERE   a~bname IN pbname
    AND a~class IN s_class
    AND ustyp IN usrtype."#EC SAST_CI_GEN_CHECK
  IF byname = 'X'.
    LOOP AT gt_sw_uinfo.
      SELECT * FROM  v_usr_name
      INTO CORRESPONDING FIELDS OF TABLE gt_comp_users
      WHERE name_first = gt_sw_uinfo-name_first
       AND name_last  = gt_sw_uinfo-name_last
       AND bname <> gt_sw_uinfo-bname."#EC SAST_CI_GEN_CHECK
      IF sy-subrc = 0.
        LOOP AT gt_comp_users.
          MOVE-CORRESPONDING gt_comp_users TO gt_sw_uinfo_final.
          APPEND gt_sw_uinfo_final.
        ENDLOOP.
      ENDIF.
    ENDLOOP.
  ELSE.
    gt_sw_uinfo_final[] = gt_sw_uinfo[].
  ENDIF.


  LOOP AT gt_sw_uinfo_final.
    iusr02-sign = 'I'.
    iusr02-option = 'EQ'.
    iusr02-low = gt_sw_uinfo_final-bname.
    APPEND iusr02.
  ENDLOOP.

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

*  REFRESH s_class. "filtering already done on usergroup
  CALL FUNCTION '/PSYNG/SW_041'
       EXPORTING
            i_validuser       = validusr
            i_include_locked  = i_include_locked
            i_include_expired = i_include_expire
       TABLES
            et_users          = lt_users
            it_userlist       = iusr02
            it_grouplist      = s_class
            it_usertype       = usrtype.

  SORT lt_users BY bname.
  LOOP AT gt_sw_uinfo_final.
    READ TABLE lt_users WITH KEY bname = gt_sw_uinfo_final-bname
    BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc NE 0.
      DELETE gt_sw_uinfo_final.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " get_users
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
      CONCATENATE text-ed1 text-d02 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d02 text-p04 INTO l_message SEPARATED BY space.
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
      CONCATENATE text-ed1 text-d03 INTO l_message SEPARATED BY space.
      EXIT.
    ENDIF.
  ELSE.
    CONCATENATE text-d03 text-p04 INTO l_message SEPARATED BY space.
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
    AND b~ddlanguage = sy-langu. "#EC SAST_CI_GEN_CHECK

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
        l_temp(90),
        l_alv_grid_titl TYPE lvc_title.


  MOVE text-000 TO l_alv_grid_titl.

  wa-typ = 'H'.
  wa-info = l_alv_grid_titl.
  APPEND wa TO lt_header.
  CLEAR l_alv_grid_titl.
  MOVE text-h01 TO l_alv_grid_titl.
  wa-typ = 'H'.
  wa-info = l_alv_grid_titl.
  APPEND wa TO lt_header.

*User & Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user"sy-uname     C0700
   text-h04 l_exedate l_exetime
              INTO wa-info SEPARATED BY SPACE.
  APPEND wa TO lt_header.

    CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = lt_header.
 ENDFORM.
