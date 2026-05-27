*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_082
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

REPORT /psyng/sw_082 NO STANDARD PAGE HEADING LINE-SIZE 200.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

*************************************************************
*------------------------tables-----------------------------*
*************************************************************
TABLES:
usr02,
 agr_users,
agr_agrs.

*************data declaration************************
*****************************************************
TYPES: BEGIN OF gt_final_tab,

        agr_name TYPE agr_users-agr_name,
        child_agr TYPE agr_agrs-child_agr,
        uname TYPE agr_users-uname,
        flag_com_role TYPE agr_users-col_flag,
        name TYPE adrp-name_text,
        tcode TYPE tstct-tcode,
        total_no_tcode TYPE i,
        no_of_user TYPE i,
        no_of_extcd TYPE i,
        tcd_percntage TYPE p DECIMALS 3,
        role_percntage TYPE p DECIMALS 3,
        flg_er_role TYPE flag,
        pshbtn_sod(10) TYPE c,
*        FLG_COM_R_SIN TYPE C,
       END OF gt_final_tab.

TYPES: BEGIN OF gt_er,
        bname LIKE usr02-bname,
        agr_name LIKE agr_users-agr_name,
        fr_date LIKE sy-datum,
        to_date LIKE sy-datum,
      END OF gt_er.
TYPES: BEGIN OF gt_r_usr ,
        agr_name LIKE agr_users-agr_name,
        child_agr LIKE agr_agrs-child_agr,
        uname LIKE agr_users-uname,
        flag_com_role LIKE agr_users-col_flag,
        name LIKE adrp-name_text,
        total_no_tcode TYPE i,
        no_of_user TYPE i,
        flg_er_role TYPE c,
        pshbtn_sod(10) TYPE c,
       END OF gt_r_usr.

DATA: gt_er_role TYPE STANDARD TABLE OF gt_er INITIAL SIZE 0 WITH HEADER
 LINE .
DATA: gt_role_user1 TYPE standard TABLE OF gt_r_usr INITIAL SIZE 0 WITH
HEADER LINE .
DATA: gt_role_user TYPE standard TABLE OF gt_r_usr INITIAL SIZE 0 WITH
HEADER LINE .

DATA: gt_final_tcd_tab TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE
      0 ,
      gt_final_role TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0 ,
      gt_comp_role TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0 ,
      gt_sin_role TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0 ,
      gt_role_users TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0 ,
      gt_co_role TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0 ,
      it_emptytab TYPE STANDARD TABLE OF gt_final_tab INITIAL SIZE 0.

DATA: wa_role TYPE gt_final_tab,
      wa_role_t TYPE gt_final_tab,
      wa_sin_role TYPE gt_final_tab,
      wa_comp_role TYPE gt_final_tab,
      wa_role_user TYPE gt_final_tab.

DATA: idirectory TYPE STANDARD TABLE OF /psyng/sw_dates
WITH HEADER LINE.

DATA: BEGIN OF months OCCURS 0,
      month LIKE sy-datum,
      END OF months.

DATA: BEGIN OF users OCCURS 10,
        bname LIKE usr02-bname,
        name LIKE adrp-name_text,
pernr like /psyng/output-pernr,
kostl like /psyng/sw_uinfo-kostl,
persg like /psyng/range_persg-low,
werks like /psyng/output-persa.
DATA: END OF users.

DATA: BEGIN OF gt_usertcode OCCURS 0,
      bname LIKE usr02-bname,
      tcode LIKE tstc-tcode,
      ttext LIKE tstct-ttext,
      END OF gt_usertcode.

DATA: BEGIN OF gt_role_tcode OCCURS 0,
      agr_name LIKE agr_users-agr_name,
      tcode LIKE tstct-tcode,
      END OF gt_role_tcode.

DATA: BEGIN OF gt_com_tcode OCCURS 0,
      agr_name LIKE agr_users-agr_name,
      t_no_c_tcode TYPE i,
      END OF gt_com_tcode.

DATA: BEGIN OF gt_get_role OCCURS 0,
        agr_name LIKE agr_users-agr_name,
        child_agr LIKE agr_agrs-child_agr,
        flag_com_role LIKE agr_users-col_flag,
        total_no_tcode TYPE i,
       END OF gt_get_role.

DATA: BEGIN OF gt_exe_tcd_tab OCCURS 0,
        agr_name LIKE agr_users-agr_name,
        child_agr LIKE agr_agrs-child_agr,
        uname LIKE agr_users-uname,
        flag_com_role LIKE agr_users-col_flag,
        name LIKE adrp-name_text,
        ex_tcode LIKE tstct-tcode,
        total_no_tcode TYPE i,
        no_of_user TYPE i,
        no_of_extcd TYPE i,
        tcd_percntage TYPE p DECIMALS 3,
        role_percntage TYPE p DECIMALS 3,
        flg_er_role TYPE c,
       END OF gt_exe_tcd_tab.

DATA: BEGIN OF gt_role_tcd_u OCCURS 0,
      agr_name LIKE agr_users-agr_name,
      tcode LIKE tstct-tcode,
      uname LIKE agr_users-uname,
      END OF gt_role_tcd_u.

DATA: BEGIN OF gt_com_us OCCURS 0,
      agr_name LIKE agr_users-agr_name,
      uname LIKE agr_users-uname,
      END OF gt_com_us.

DATA: g_agr_name LIKE agr_define-agr_name,
      g_child_agr LIKE agr_agrs-child_agr.

DATA: g_kostl                TYPE kostl,         "For select-options
      g_pernr                TYPE /psyng/pernr,  "For select-options
      g_persa                TYPE /psyng/persa,  "For select-options
      g_persg                TYPE /psyng/persg,  "For select-options
      gf_use_erp             TYPE /psyng/bapiflagx,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

DATA: l_tabname LIKE dd02l-tabname,
      g_com_flag TYPE c.
DATA: swconfig TYPE /psyng/swconfig,
      dsp_mng_lock VALUE 'N',
      dsp_slf_lock VALUE 'Y',
      g_node_key TYPE lvc_nkey.
DATA: g_1stmonth TYPE sy-datum,
      g_lastmont TYPE sy-datum,
      g_1mon_cal TYPE sy-datum,
      g_lmn_cal TYPE sy-datum.

************ CONSTANTS ***************************
CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.

***************ALV TREE VARIABLES ******************
CLASS cl_gui_column_tree DEFINITION LOAD.
CLASS cl_gui_cfw DEFINITION LOAD.

DATA tree1  TYPE REF TO  cl_gui_alv_tree.

INCLUDE <icon>.
DATA: gt_fieldcatalog TYPE lvc_t_fcat,
      ok_code LIKE sy-ucomm.   "OK-Code

*****************************************************
****************INCLUDE PROGRAM**********************
*****************************************************

INCLUDE /psyng/sw_082_evt_cls.

*****************************************************************
*----------------------SELECTION SCREEN ------------------------*
*****************************************************************
****************************
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.
SELECT-OPTIONS: s_role FOR agr_users-agr_name .
PARAMETERS : p_er TYPE c AS CHECKBOX MODIF ID b1.
SELECTION-SCREEN: END OF BLOCK b1.
SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-002.
SELECT-OPTIONS: s_uid   FOR usr02-bname.
SELECT-OPTIONS: s_class FOR usr02-class.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_valdur AS CHECKBOX DEFAULT 'X'.  "valid & dialog users
SELECTION-SCREEN: COMMENT 3(50) text-003.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN ULINE MODIF ID c.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-004 MODIF ID c.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: s_kostl FOR g_kostl MATCHCODE OBJECT kost MODIF ID c .
SELECTION-SCREEN ULINE MODIF ID c.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-005 MODIF ID c.
SELECTION-SCREEN: END OF LINE.

SELECT-OPTIONS: s_pernr FOR g_pernr MODIF ID c,
                s_werks FOR g_persa MATCHCODE OBJECT h_t500p MODIF ID c,
                s_persg FOR g_persg MODIF ID c .

SELECTION-SCREEN: END OF BLOCK blk1.

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-006.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-007.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: p_1stmon(7).
SELECTION-SCREEN: COMMENT 28(30) text-008.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(12) text-009.
SELECTION-SCREEN: POSITION 15.
PARAMETERS: p_lstmn(7).
SELECTION-SCREEN: COMMENT 28(30) text-008.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(65) ava_txt.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK exe.

SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-017.

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


***********************************************************************
******************* selection screen validation************************
***********************************************************************

AT SELECTION-SCREEN.
********** MONTH AND YEAR VALIDATION............
  IF p_lstmn+0(2)  < 01 OR p_lstmn+0(2) > 12.
    SET CURSOR FIELD p_lstmn.
    MESSAGE e147(/psyng/sw) WITH p_lstmn+0(2) .
  ENDIF.
  IF p_1stmon+0(2)  < 01 OR p_1stmon+0(2) > 12.
    SET CURSOR FIELD p_lstmn.
    MESSAGE e147(/psyng/sw) WITH p_1stmon+0(2) .
  ENDIF.

  CONCATENATE p_1stmon+3(4) p_1stmon+0(2) INTO g_1mon_cal.
  CONCATENATE p_lstmn+3(4) p_lstmn+0(2) INTO g_lmn_cal.
  IF g_1mon_cal > g_lmn_cal.
    MESSAGE e148(/psyng/sw).
  ENDIF.
************************************************************************
*---------------- AT SELECTION-SCREEN ON VALUE-REQUEST ----------------*
************************************************************************

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_pernr-low.
  IF s_pernr IS INITIAL.
    PERFORM f4_pernr CHANGING s_pernr-low.
  ELSE.
    LOOP AT s_pernr.
      PERFORM f4_pernr CHANGING s_pernr-low.
    ENDLOOP.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_pernr-high.
  IF s_pernr IS INITIAL.
    PERFORM f4_pernr CHANGING s_pernr-high.
  ELSE.
    LOOP AT s_pernr.
      PERFORM f4_pernr CHANGING s_pernr-high.
    ENDLOOP.
  ENDIF.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_persg-low.
  PERFORM f4_persg CHANGING s_persg-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_persg-high.
  PERFORM f4_persg CHANGING s_persg-high.

************************************************************************
*---------------------------- INITIALIZATION --------------------------*
************************************************************************
INITIALIZATION.
  PERFORM exelog.
  PERFORM initialization.
************************************************************************
*-----------------SELECTION SCREEN OUTPUT -----------------------------*
************************************************************************

AT SELECTION-SCREEN OUTPUT.:
Data : lo_classtype TYPE REF TO cl_abap_typedescr.

  SELECT SINGLE tabname
  FROM dd02l
  INTO l_tabname
  WHERE tabname = '/PSYNG/ER_MAIN'
  AND as4local = 'A'."#EC SAST_CI_GEN_CHECK

  LOOP AT SCREEN .
    IF NOT l_tabname IS INITIAL.
      IF screen-group1 = 'B1'.
        screen-active = 1 .
        MODIFY SCREEN.
      ENDIF.
    ELSE.
      IF screen-group1 = 'B1'.
        screen-active = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = gc_erp_class
    RECEIVING
      p_descr_ref    = lo_classtype
     EXCEPTIONS
       type_not_found = 1
       OTHERS         = 2.

  IF sy-subrc EQ 0.
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


************************************************************************
*------------------- START-OF-SELECTION--------------------------------*
************************************************************************
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
  EXELOG sy-repid ''.
  PERFORM get_userid.
  PERFORM get_role.
  IF l_tabname = '/PSYNG/ER_MAIN' AND p_er = 'X'.
    PERFORM get_er_role.
  ENDIF.
  PERFORM role_user.
  IF l_tabname = '/PSYNG/ER_MAIN' AND p_er = 'X'.
    PERFORM add_er_role.
  ENDIF.
  PERFORM user_filter.
  PERFORM pro_indict USING 30 text-026.
  PERFORM user_by_userid.

  PERFORM role_tcode.
  PERFORM pro_indict USING 50 text-012.
  PERFORM get_executed_tcodes.
  PERFORM executed_details.
  PERFORM calculation.
  PERFORM pro_indict USING 85 text-013.
  CALL SCREEN 8000.

*&---------------------------------------------------------------------*
*&      Form  initialization
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM initialization.
  DATA: lv_st_txt(10),
          ls_txt(10),
          lo_classtype TYPE REF TO cl_abap_typedescr,
          l_value TYPE /psyng/param_value.

*Valid & Dialog Users only
  se_config_param 'DFLT_VALID_DIALOG' l_value.
  IF l_value = 'Y'.
    p_valdur = 'X'.
  ELSEIF l_value = 'N'.
    p_valdur = ' '.
  ENDIF.
  CLEAR l_value.

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
    months-month = idirectory-startdate.
    APPEND months.
  ENDLOOP.

  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth(4) INTO p_1stmon.
  CONCATENATE g_lastmont+4(2) '/' g_lastmont(4) INTO p_lstmn.


  CONCATENATE g_1stmonth+4(2) '/' g_1stmonth+6(2) '/' g_1stmonth(4)
              INTO lv_st_txt.
  CONCATENATE sy-datum+4(2) '/' sy-datum+6(2) '/' sy-datum(4)
              INTO ls_txt.
  CONCATENATE text-010 lv_st_txt text-011 ls_txt
              INTO ava_txt SEPARATED BY space.

** Determine whether or not to use ERP tables
*  CALL METHOD cl_abap_classdescr=>describe_by_name
*    EXPORTING
*      p_name         = gc_erp_class
*    RECEIVING
*      p_descr_ref    = lo_classtype
*     EXCEPTIONS
*       type_not_found = 1
*       OTHERS         = 2.
*
*  IF sy-subrc = 0.
*    gf_use_erp = 'X'.
*  ELSE.
**   Remove ERP fields from screen
*    LOOP AT SCREEN.
*      CHECK screen-name CS '0017COMA' OR screen-name CS 'KOSTL'
*      OR screen-name CS '0001COMA'    OR screen-name CS 'PRNR'
*      OR screen-name CS 'WERKS'       OR screen-name CS 'PERSG'
*      OR screen-name CS '%_U006%%'    OR screen-name CS '%_U011%%'.
*
*      screen-active = 0.
*      MODIFY SCREEN.
*    ENDLOOP.
*  ENDIF.


ENDFORM.                    " initialization

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
*       text
*----------------------------------------------------------------------*
*      <--P_PERSG_LOW  text
*----------------------------------------------------------------------*
FORM f4_persg CHANGING e_persg.
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
*&      Form  GET_USERID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_userid.
  CONSTANTS: lc_method(17) TYPE c VALUE 'GET_USERS_FROM_HR'.

  DATA: lt_bname TYPE /psyng/range_bname_t,
        lt_pernr TYPE /psyng/range_pernr_t,
        lt_persa TYPE /psyng/range_persa_t,
        lt_persg TYPE /psyng/range_persg_t,
        lt_kostl TYPE /psyng/range_kostl_t,
        ls_bname TYPE /psyng/range_bname,
        lt_users TYPE /psyng/hr_user_t,
        ls_users TYPE /psyng/hr_user.


  REFRESH users.

  ls_bname-sign   = 'I'.
  ls_bname-option = 'EQ'.
  SELECT bname FROM usr02 INTO ls_bname-low WHERE bname IN s_uid
                                                  AND class IN s_class.

*    IF gf_use_erp = 'X'.
*      APPEND ls_bname TO lt_bname.
*    ELSE.
    users-bname = ls_bname-low.
    APPEND users.
*    ENDIF.
  ENDSELECT.

*   Exit if no users are found
  CHECK sy-subrc = 0.

*--Get HR information only if using ERP tables
  CHECK gf_use_erp = 'X'.

  lt_pernr[] = s_pernr[].
  lt_persa[] = s_werks[].
  lt_persg[] = s_persg[].
  lt_kostl[] = s_kostl[].
  CALL METHOD (gc_erp_class)=>(lc_method)"#EC PATHLOCK_CI_DYN_ACCES
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
      MOVE-CORRESPONDING ls_users TO users.
      APPEND users.
    ELSE.
*if NO hr related select options are given, include non-HR users
      IF lt_persa[] IS INITIAL AND lt_pernr[] IS INITIAL
      AND lt_persg[] IS INITIAL AND lt_kostl[] IS INITIAL.
        CLEAR users.
        users-bname = ls_bname-low.
        APPEND users.
      ENDIF.
    ENDIF.
  ENDLOOP.

  IF sy-subrc <> 0 AND NOT s_uid[] IS INITIAL.
    LOOP AT lt_bname INTO ls_bname.
      users-bname = ls_bname-low.
      APPEND users.
    ENDLOOP.
  ENDIF.

ENDFORM.                    " GET_USERID
*&---------------------------------------------------------------------*
*&      Form  GET_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_role.
  SELECT agr_name
         FROM agr_define
         INTO (g_agr_name)
         WHERE agr_name IN s_role.

*get all the single role of this Composite Role
    SELECT SINGLE * FROM agr_agrs WHERE agr_name = g_agr_name.
    IF sy-subrc = 0.   "If role is a composite role
      g_com_flag = 'X'.
      SELECT agr_name
             child_agr
             FROM agr_agrs
             INTO (g_agr_name,g_child_agr)
             WHERE agr_name = g_agr_name
             AND   attributes <> 'X'.

        gt_get_role-agr_name = g_agr_name.
        gt_get_role-child_agr = g_child_agr.
        gt_get_role-flag_com_role = 'X'.
        APPEND gt_get_role.
      ENDSELECT.
    ELSE.
      CLEAR gt_get_role.
      gt_get_role-agr_name =  g_agr_name.
      APPEND gt_get_role.
    ENDIF.
  ENDSELECT.
  IF sy-subrc <> 0.
    MESSAGE i100(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
  SORT gt_get_role.
  DELETE ADJACENT DUPLICATES FROM gt_get_role COMPARING ALL FIELDS.

ENDFORM.                    " GET_ROLE
*&---------------------------------------------------------------------*
*&      Form  ROLE_USER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM role_user.
  LOOP AT gt_get_role.
    IF gt_get_role-flag_com_role = 'X'.
      SELECT agr_name
             uname
      FROM agr_users
      INTO (gt_role_user1-child_agr,gt_role_user1-uname)
      WHERE agr_name = gt_get_role-child_agr .
        gt_role_user1-agr_name = gt_get_role-agr_name.
        gt_role_user1-flag_com_role = gt_get_role-flag_com_role.
        gt_role_user1-total_no_tcode  = gt_get_role-total_no_tcode.
        APPEND gt_role_user1.
      ENDSELECT.

*select composite user for composite efficency.

      SELECT agr_name
             uname
      FROM agr_users
      APPENDING TABLE gt_com_us
      WHERE agr_name = gt_get_role-agr_name.
    ELSE.
      CLEAR gt_role_user1.
      SELECT agr_name
             uname
      FROM agr_users
      INTO (gt_role_user1-agr_name,gt_role_user1-uname)
      WHERE agr_name = gt_get_role-agr_name .
        gt_role_user1-flag_com_role = gt_get_role-flag_com_role.
        APPEND gt_role_user1.
      ENDSELECT.
    ENDIF.
  ENDLOOP.
  SORT gt_role_user1.
  DELETE ADJACENT DUPLICATES FROM gt_role_user1 COMPARING ALL FIELDS.
  gt_role_user[] = gt_role_user1[].

ENDFORM.                    " ROLE_USER
*&---------------------------------------------------------------------*
*&      Form  USER_BY_USERID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_by_userid.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
  DATA : l_uflagx TYPE x,
         lt_uidn  TYPE TABLE OF /psyng/bc_uidn WITH HEADER LINE.

  TYPES: BEGIN OF typ_usr02,
           bname TYPE usr02-bname,
           class TYPE usr02-class,
         END OF typ_usr02.

DATA: iusr02       TYPE HASHED TABLE OF typ_usr02 WITH UNIQUE KEY bname
                                                       WITH HEADER LINE,
                                            wa_usr02     TYPE typ_usr02,
                                          l_gltgv      TYPE usr02-gltgv,
                                          l_gltgb      TYPE usr02-gltgb,
                                          l_ustyp      TYPE usr02-ustyp,
                                          l_uflag      TYPE usr02-uflag.

  RANGES: lt_bname FOR /psyng/bc_uidn-bname.


  IF p_valdur IS INITIAL.
    SELECT bname class INTO TABLE iusr02
           FROM usr02.
  ELSE.
    PERFORM get_sw_repo_conifg.
    SELECT bname class gltgv gltgb ustyp uflag
           INTO (wa_usr02-bname, wa_usr02-class, l_gltgv, l_gltgb,
                 l_ustyp, l_uflag)
           FROM usr02
           WHERE "bname IN pbname AND
                 ustyp = 'A'.
      IF l_gltgv IS INITIAL.  "valid from date
        l_gltgv = '00010101'.
      ENDIF.
      IF l_gltgb IS INITIAL.  "valid to date
        l_gltgb = '99991231'.
      ENDIF.
      IF l_gltgv <= sy-datum AND l_gltgb >= sy-datum.
*Case 1405
        l_uflagx = l_uflag."unicode
        IF l_uflagx O yusloc OR "locked by admin
           l_uflagx O yugloc.   "locked by CUA admin
*      --User is locked by Local or Global Administrator
          IF dsp_mng_lock = 'Y'.
            INSERT wa_usr02 INTO TABLE iusr02.
          ENDIF.
        ELSEIF l_uflagx O yulock.
*      --User is locked by failed logins
          IF dsp_slf_lock = 'Y'.
            INSERT wa_usr02 INTO TABLE iusr02.
          ENDIF.
        ELSE.
*      --User is active
          INSERT wa_usr02 INTO TABLE iusr02.
        ENDIF.

*        CASE l_uflag.
*          WHEN 0.   "user ID unlocked
*            INSERT wa_usr02 INTO TABLE iusr02.
*          WHEN 64.  "user ID locked by system manager
*            IF dsp_mng_lock = 'Y'.
*              INSERT wa_usr02 INTO TABLE iusr02.
*            ENDIF.
*          WHEN 128. "user ID locked due to incorrect logins
*            IF dsp_slf_lock = 'Y'.
*              INSERT wa_usr02 INTO TABLE iusr02.
*            ENDIF.
*        ENDCASE.
      ENDIF.
    ENDSELECT.
  ENDIF.

*DHO 20101202
*   Check user group authority
  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.
  LOOP AT iusr02.
    lt_uinfo-bname = iusr02-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
   EXPORTING
*       VRSIO                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
     i_name_only              = 'X'
     i_mr_company             = 'X'
    TABLES
      sw_uinfo                 = lt_uinfo.
  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_role_user WHERE uname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'  FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_role_user WHERE uname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ELSEIF NOT lt_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        DELETE iusr02 WHERE bname = lt_uinfo-bname.
        DELETE gt_role_user WHERE uname = lt_uinfo-bname.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.
    ENDIF.
  ENDLOOP.


  SORT gt_role_user BY uname.
****  Filter the user
  LOOP AT gt_role_user.
    READ TABLE iusr02 WITH TABLE KEY bname = gt_role_user-uname.
    IF sy-subrc <> 0.
      DELETE gt_role_user.
      CONTINUE.
    ENDIF.


*   Check user group authority
*DHO 20101202
*    AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
*             ID 'CLASS' FIELD iusr02-class.
*    IF sy-subrc <> 0.
*      DELETE gt_role_user.
*      gf_missing_auth_ugroup = 'X'.
*      CONTINUE.
*    ENDIF.

    REFRESH: lt_bname, lt_uidn.
    lt_bname-sign   = 'I'.
    lt_bname-option = 'EQ'.
    lt_bname-low    = gt_role_user-uname.
    APPEND lt_bname.

    CALL FUNCTION '/PSYNG/BC_011'
         TABLES
              it_bname = lt_bname
              et_uidn  = lt_uidn.

    SORT lt_uidn BY bname.
    READ TABLE lt_uidn INDEX 1 TRANSPORTING name_first name_last.
    CHECK sy-subrc = 0.

    CONCATENATE lt_uidn-name_first lt_uidn-name_last
                INTO gt_role_user-name
                SEPARATED BY space.
    MODIFY gt_role_user.
  ENDLOOP.
  IF gt_role_user[] IS INITIAL.
    MESSAGE i149(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.                    " USER_BY_USERID
*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_sw_repo_conifg.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.
ENDFORM.                    " get_sw_repo_conifg
*&---------------------------------------------------------------------*
*&      Form  ROLE_TCODE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM role_tcode.

  DATA: BEGIN OF lt_com_tcode OCCURS 0,
        agr_name LIKE agr_users-agr_name,
        tcode LIKE tstct-tcode,
        END OF lt_com_tcode.

  DATA:l_role_name LIKE agr_users-agr_name,
       l_tcode_count TYPE i,
       l_com_r_cnt TYPE i,
       l_dummy TYPE i.
  DATA: lt_roletcode LIKE STANDARD TABLE OF /psyng/usertcode
  INITIAL SIZE 0 WITH HEADER LINE.


  LOOP AT gt_get_role.
    CLEAR: l_role_name,
           l_tcode_count.
    IF gt_get_role-flag_com_role = 'X'.
      l_role_name = gt_get_role-child_agr.
    ELSE.
      l_role_name = gt_get_role-agr_name.
    ENDIF.
****** get all the role tcode********
    CALL FUNCTION '/PSYNG/SW_030'
         EXPORTING
              i_agr_name   = l_role_name
         TABLES
              et_roletcode = lt_roletcode.

    LOOP AT lt_roletcode.
      l_tcode_count = l_tcode_count + 1.
      gt_role_tcode-agr_name = lt_roletcode-agr_name.
      gt_role_tcode-tcode = lt_roletcode-tcode.
      APPEND gt_role_tcode.

*Unique tcodes in composite role *
      IF gt_get_role-flag_com_role = 'X'.
        lt_com_tcode-agr_name = gt_get_role-agr_name.
        lt_com_tcode-tcode = lt_roletcode-tcode.
        APPEND lt_com_tcode.
      ENDIF.
    ENDLOOP.
    REFRESH lt_roletcode.
** count total tcode with in a role*******
    LOOP AT gt_role_user WHERE agr_name = gt_get_role-agr_name AND
child_agr = gt_get_role-child_agr.
      gt_role_user-total_no_tcode = l_tcode_count.
      MODIFY gt_role_user TRANSPORTING total_no_tcode.
      CLEAR: l_role_name.
    ENDLOOP.
  ENDLOOP.
  SORT lt_com_tcode.
  DELETE ADJACENT DUPLICATES FROM lt_com_tcode COMPARING ALL FIELDS.

  SORT gt_role_tcode BY tcode.
  DELETE ADJACENT DUPLICATES FROM gt_role_tcode COMPARING ALL FIELDS.
** count total tcode with in a composite role*******
  LOOP AT lt_com_tcode.
    l_com_r_cnt = l_com_r_cnt + 1.
    AT END OF agr_name.
      l_dummy = l_com_r_cnt.
      CLEAR l_com_r_cnt.
    ENDAT.
    IF l_dummy <> 0.
      gt_com_tcode-agr_name = lt_com_tcode-agr_name.
      gt_com_tcode-t_no_c_tcode = l_dummy.
      APPEND gt_com_tcode.
    ENDIF.
    CLEAR l_dummy.
  ENDLOOP.
  FREE lt_com_tcode.
ENDFORM.                    " ROLE_TCODE
*&---------------------------------------------------------------------*
*&      Form  get_executed_tcodes
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_executed_tcodes.
  DATA: gt_user_stat TYPE TABLE OF /psyng/sw_entry WITH HEADER LINE,
        lt_hitlist   TYPE TABLE OF /psyng/hitlist WITH HEADER LINE.


  SORT users.
  LOOP AT months.
    CHECK months-month GE g_1stmonth AND months-month LE g_lastmont.
*Get all the Executed Tcode***************
    CALL FUNCTION '/PSYNG/SW_SUMMARY_STATISTIC'
         EXPORTING
              startdate = months-month
         TABLES
              user_stat = gt_user_stat
              hitlist   = lt_hitlist.

    LOOP AT gt_user_stat.
      READ TABLE users WITH KEY bname = gt_user_stat-account
           BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.

      IF gt_user_stat-entry_id+72(1) = 'T'.   "transaction code
        CLEAR gt_usertcode.
        gt_usertcode-bname = gt_user_stat-account.
        gt_usertcode-tcode = gt_user_stat-entry_id(20).
        APPEND gt_usertcode.
      ENDIF.
    ENDLOOP.
    REFRESH: gt_user_stat.

    LOOP AT lt_hitlist WHERE tcode <> space.
      READ TABLE users WITH KEY bname = lt_hitlist-account
                 BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc = 0.

      CLEAR gt_usertcode.
      gt_usertcode-bname = lt_hitlist-account.
      gt_usertcode-tcode = lt_hitlist-tcode.
      APPEND gt_usertcode.
    ENDLOOP.
    REFRESH lt_hitlist.
  ENDLOOP.   "months

  SORT gt_usertcode BY tcode bname.
  DELETE ADJACENT DUPLICATES FROM gt_usertcode COMPARING ALL FIELDS.

*GET ROLE FOR THAT TCODE AND USER.
  LOOP AT  gt_usertcode.
    LOOP AT gt_role_tcode WHERE tcode = gt_usertcode-tcode.
      gt_role_tcd_u-agr_name = gt_role_tcode-agr_name.
      gt_role_tcd_u-tcode = gt_role_tcode-tcode.
      gt_role_tcd_u-uname = gt_usertcode-bname.
      APPEND gt_role_tcd_u.
    ENDLOOP.
  ENDLOOP.
  SORT gt_role_tcd_u BY agr_name uname .
  DELETE ADJACENT DUPLICATES FROM gt_role_tcd_u COMPARING ALL FIELDS.

ENDFORM.                    " get_executed_tcodes
*&---------------------------------------------------------------------*
*&      Form  EXECUTED_DETAILS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM executed_details.
  DATA:l_role_name LIKE agr_users-agr_name.
  DATA:l_index LIKE sy-tabix VALUE '1'.
  DATA: l_cnt_tcd TYPE i VALUE '0',
      l_dumy_tcd TYPE i.
  SORT gt_role_user .
  LOOP AT gt_role_user .
    IF gt_role_user-flag_com_role = 'X'.
      l_role_name = gt_role_user-child_agr.
    ELSE.
      l_role_name = gt_role_user-agr_name.
    ENDIF.
   LOOP AT gt_role_tcd_u  FROM l_index WHERE agr_name = l_role_name AND
                                             uname = gt_role_user-uname.
      gt_exe_tcd_tab-agr_name = gt_role_user-agr_name.
      gt_exe_tcd_tab-child_agr = gt_role_user-child_agr.
      gt_exe_tcd_tab-uname = gt_role_user-uname.
      gt_exe_tcd_tab-flag_com_role = gt_role_user-flag_com_role.
      gt_exe_tcd_tab-name = gt_role_user-name.
      gt_exe_tcd_tab-ex_tcode = gt_role_tcd_u-tcode.
      gt_exe_tcd_tab-total_no_tcode = gt_role_user-total_no_tcode.
      gt_exe_tcd_tab-no_of_user = gt_role_user-no_of_user.
      gt_exe_tcd_tab-flg_er_role = gt_role_user-flg_er_role.
      APPEND gt_exe_tcd_tab.
      l_index = sy-tabix.
    ENDLOOP.
  ENDLOOP.

  SORT gt_exe_tcd_tab.
  DELETE ADJACENT DUPLICATES FROM gt_exe_tcd_tab COMPARING ALL FIELDS.
*  count the no of ex_tcode.
  LOOP AT gt_exe_tcd_tab.

    l_cnt_tcd = l_cnt_tcd + 1.
    AT END OF uname.
      l_dumy_tcd = l_cnt_tcd.
      CLEAR l_cnt_tcd.
    ENDAT.
    gt_exe_tcd_tab-no_of_extcd = l_dumy_tcd.
    MODIFY gt_exe_tcd_tab TRANSPORTING no_of_extcd.
    CLEAR l_dumy_tcd.
  ENDLOOP.

ENDFORM.                    " EXECUTED_DETAILS
*&---------------------------------------------------------------------*
*&      Form  CALCULATION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM calculation.
  DATA: l_cnt_tcd TYPE i VALUE '0',
      l_dumy_tcd TYPE i,
      l_c_no_user TYPE i,
      l_dmy_user TYPE i.
  DATA:l_idx LIKE sy-tabix,
         l_totl_tcd TYPE f,
         l_exe_tcd TYPE f,
         l_tcd_prcntg TYPE p DECIMALS 3,
         l_role_per TYPE f ,
         l_sum_tcd_per TYPE f,
         l_no_user TYPE f.
  gt_final_tcd_tab[] = gt_exe_tcd_tab[].
  LOOP AT gt_role_user.
    READ TABLE gt_exe_tcd_tab WITH KEY agr_name =
                                               gt_role_user-agr_name
                                   child_agr = gt_role_user-child_agr
                                       uname = gt_role_user-uname.
    IF sy-subrc <> 0.
      wa_role-agr_name = gt_role_user-agr_name.
      wa_role-child_agr = gt_role_user-child_agr.
      wa_role-uname = gt_role_user-uname.
      wa_role-flag_com_role = gt_role_user-flag_com_role.
      wa_role-name = gt_role_user-name.
      wa_role-tcode = ' '."GT_EXE_TCD_TAB-TCODE.
      wa_role-total_no_tcode = gt_role_user-total_no_tcode.
      wa_role-no_of_user = gt_role_user-no_of_user.
      wa_role-flg_er_role = gt_role_user-flg_er_role.
      wa_role-no_of_extcd = '0'.
      APPEND wa_role TO gt_final_tcd_tab.
    ENDIF.
  ENDLOOP.
  SORT gt_final_tcd_tab.
  DELETE ADJACENT DUPLICATES FROM gt_final_tcd_tab COMPARING ALL FIELDS.

*********************** populate composite role details****************
  LOOP AT gt_final_tcd_tab INTO wa_role.


    IF wa_role-flag_com_role = 'X'.
      LOOP AT gt_com_tcode WHERE agr_name = wa_role-agr_name.
        wa_comp_role-agr_name = wa_role-agr_name.
        wa_comp_role-uname = wa_role-uname.
        wa_comp_role-name = wa_role-name.
        wa_comp_role-flag_com_role = wa_role-flag_com_role.
        wa_comp_role-tcode = wa_role-tcode.
        wa_comp_role-total_no_tcode = gt_com_tcode-t_no_c_tcode.
        APPEND wa_comp_role TO gt_co_role.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
  SORT gt_co_role BY agr_name uname tcode.
  DELETE ADJACENT DUPLICATES FROM gt_co_role COMPARING ALL FIELDS.

  IF NOT gt_com_us[] IS INITIAL.
    LOOP AT gt_com_us.
      LOOP AT gt_co_role INTO wa_comp_role  FROM l_idx WHERE agr_name =
      gt_com_us-agr_name AND uname = gt_com_us-uname.
        APPEND wa_comp_role TO gt_comp_role.
      ENDLOOP.
    ENDLOOP.
  ENDIF.
  IF NOT gt_comp_role[] IS INITIAL.
    LOOP AT gt_comp_role INTO wa_comp_role. " where tcode <> ' '.
      IF wa_comp_role-tcode <> ' '.
        l_cnt_tcd = l_cnt_tcd + 1.
      ENDIF.
      AT END OF uname.
        l_c_no_user = l_c_no_user + 1.
        l_dumy_tcd = l_cnt_tcd.
        CLEAR l_cnt_tcd.
      ENDAT.
      AT END OF agr_name.
        l_dmy_user = l_c_no_user.
        CLEAR l_c_no_user.
      ENDAT.
      wa_comp_role-no_of_user = l_dmy_user.
      wa_comp_role-no_of_extcd = l_dumy_tcd.
      MODIFY gt_comp_role FROM wa_comp_role TRANSPORTING no_of_extcd
  no_of_user.
      CLEAR l_dumy_tcd.
    ENDLOOP.

    LOOP AT gt_comp_role INTO wa_comp_role.
      l_totl_tcd = wa_comp_role-total_no_tcode.
      l_exe_tcd = wa_comp_role-no_of_extcd.
      AT END OF uname.
        IF l_exe_tcd = '0'.
          l_tcd_prcntg = '0'.
        ELSE.
          l_tcd_prcntg = ( l_exe_tcd / l_totl_tcd ) * 100.
        ENDIF.

        l_sum_tcd_per = l_sum_tcd_per + l_tcd_prcntg.
      ENDAT.
      l_no_user = wa_comp_role-no_of_user.
      AT END OF agr_name.
        IF l_no_user = 0.
          l_role_per = 0.
        ELSE.
          l_role_per = l_sum_tcd_per / l_no_user.
          CLEAR : l_sum_tcd_per.
        ENDIF.
      ENDAT.

      wa_comp_role-role_percntage = l_role_per.
      wa_comp_role-tcd_percntage = l_tcd_prcntg.
      MODIFY gt_comp_role FROM wa_comp_role TRANSPORTING
                                role_percntage tcd_percntage.
    ENDLOOP.
    DELETE gt_comp_role WHERE role_percntage = '0'.
  ENDIF.

**********
  LOOP AT gt_final_tcd_tab INTO wa_role.
    l_totl_tcd = wa_role-total_no_tcode.
    l_exe_tcd = wa_role-no_of_extcd.
    wa_role_user = wa_role.
    AT END OF uname.

      IF l_exe_tcd = '0'.
        l_tcd_prcntg = '0'.
      ELSE.
        l_tcd_prcntg = ( l_exe_tcd / l_totl_tcd ) * 100.
      ENDIF.
      wa_role_user-role_percntage =  l_tcd_prcntg.
      wa_role_user-tcode = ' '.
*      WA_ROLE_USER-FLG_ER_ROLE = WA_ROLE-FLG_ER_ROLE.
      APPEND wa_role_user TO gt_role_users.

    ENDAT.
    l_sum_tcd_per = l_sum_tcd_per + l_tcd_prcntg.
    l_no_user = wa_role-no_of_user.
    wa_sin_role = wa_role.
    AT END OF child_agr.
      IF l_no_user = 0.
        l_role_per = 0.
      ELSE.
        l_role_per = l_sum_tcd_per / l_no_user.
        CLEAR l_sum_tcd_per.
      ENDIF.
      wa_sin_role-tcd_percntage = ' '.
      wa_sin_role-flag_com_role = 'X'.
      wa_sin_role-name = ' '.
      wa_sin_role-uname = ' '.
      wa_sin_role-tcode = ' '.
      wa_sin_role-role_percntage = l_role_per.
      APPEND wa_sin_role TO gt_sin_role.
    ENDAT.
    wa_role-role_percntage = l_role_per.
    wa_role-tcd_percntage = l_tcd_prcntg.
    MODIFY gt_final_tcd_tab FROM wa_role TRANSPORTING role_percntage
    tcd_percntage.
    wa_role_t = wa_role.
    CLEAR : l_tcd_prcntg,l_no_user,l_role_per.
    AT END OF agr_name.

      IF wa_role_t-flag_com_role = 'X'.

        wa_role_t-tcd_percntage = '0'.
        wa_role_t-role_percntage = '0'.
        wa_role_t-child_agr = 'COMPOSITE ROLE'.
        wa_role_t-flag_com_role = 'X'.
        wa_role_t-name = ' '.
        wa_role_t-uname = ' '.
        wa_role_t-tcode = ' '.
*        WA_ROLE_T-FLG_COM_R_SIN = 'X'.
      ELSE.
        wa_role_t-child_agr = ' '.
        wa_role_t-name = ' '.
        wa_role_t-flag_com_role = ' '.
        wa_role_t-name = ' '.
        wa_role_t-uname = ' '.
        wa_role_t-tcode = ' '.
        wa_role_t-tcd_percntage = '0'.
      ENDIF.
      APPEND wa_role_t TO gt_final_role.
    ENDAT.
  ENDLOOP.
  LOOP AT gt_final_role INTO wa_role_t.
    IF wa_role_t-flag_com_role = 'X'.
      READ TABLE gt_comp_role INTO wa_comp_role WITH KEY agr_name =
      wa_role_t-agr_name .
      IF sy-subrc = 0.
        wa_role_t-role_percntage = wa_comp_role-role_percntage.
        MODIFY gt_final_role FROM wa_role_t TRANSPORTING role_percntage.
      ENDIF.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " CALCULATION
*&---------------------------------------------------------------------*
*&      Module  before_display  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE before_display OUTPUT.
  SET PF-STATUS 'MAIN100'.
  SET TITLEBAR 'MAIN'.
  IF tree1 IS INITIAL.
    PERFORM init_tree.
  ENDIF.
  CALL METHOD cl_gui_cfw=>flush.

ENDMODULE.                 " before_display  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  init_tree
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM init_tree.
* repid for saving variants
  DATA: ls_variant TYPE disvariant.
* create container for alv-tree
  DATA: l_tree_container_name(30) TYPE c,
        l_custom_container TYPE REF TO cl_gui_custom_container.

* create fieldcatalog for structure role.
  PERFORM build_fieldcatalog.

  l_tree_container_name = 'TREE1'.

  IF sy-batch IS INITIAL.
    CREATE OBJECT l_custom_container
      EXPORTING
            container_name = l_tree_container_name
      EXCEPTIONS
            cntl_error                  = 1
            cntl_system_error           = 2
            create_error                = 3
            lifetime_error              = 4
            lifetime_dynpro_dynpro_link = 5.
    IF sy-subrc <> 0.
      MESSAGE x208(00) WITH 'ERROR'.
    ENDIF.
  ENDIF.

* create tree control
  CREATE OBJECT tree1
    EXPORTING
        parent              = l_custom_container
        node_selection_mode = cl_gui_column_tree=>node_sel_mode_single
        item_selection      = 'X'
        no_html_header      = 'X'
        no_toolbar          = 'X'
    EXCEPTIONS
        cntl_error                   = 1
        cntl_system_error            = 2
        create_error                 = 3
        lifetime_error               = 4
        illegal_node_selection_mode  = 5
        failed                       = 6
        illegal_column_name          = 7.
  IF sy-subrc <> 0.
    MESSAGE x208(00) WITH 'ERROR'.
  ENDIF.

* create Hierarchy-header
  DATA l_hierarchy_header TYPE treev_hhdr.
  PERFORM build_hierarchy_header CHANGING l_hierarchy_header.

  ls_variant-report = sy-repid.
* create emty tree-control
  CALL METHOD tree1->set_table_for_first_display
     EXPORTING
               is_hierarchy_header  = l_hierarchy_header

               is_variant            = ls_variant
     CHANGING
               it_outtab            = it_emptytab "table must be emty !!
               it_fieldcatalog      = gt_fieldcatalog.



* create hierarchy
  PERFORM create_hierarchy.
* register events
  PERFORM register_events.

  CALL METHOD tree1->column_optimize.

ENDFORM.                    " init_tree
*&---------------------------------------------------------------------*
*&      Form  build_fieldcatalog
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_fieldcatalog.
  DATA ls_fcat TYPE lvc_s_fcat .

  ls_fcat-fieldname = 'PSHBTN_SOD' .
  ls_fcat-inttype = 'C' .
  ls_fcat-outputlen = '10' .
  ls_fcat-coltext = text-027.
  ls_fcat-seltext = text-027 .
  ls_fcat-hotspot = 'X'.
  APPEND ls_fcat TO gt_fieldcatalog .

  IF g_com_flag = 'X'.
    ls_fcat-fieldname = 'AGR_NAME' .
    ls_fcat-inttype = 'C' .
    ls_fcat-outputlen = '10' .
    ls_fcat-coltext = text-025.
    ls_fcat-seltext = text-025 .
    APPEND ls_fcat TO gt_fieldcatalog .

    CLEAR ls_fcat.
    ls_fcat-fieldname = 'CHILD_AGR' .
    ls_fcat-inttype = 'C' .
    ls_fcat-outputlen = '20' .
    ls_fcat-coltext = text-019 .
    ls_fcat-seltext = text-019 .
    APPEND ls_fcat TO gt_fieldcatalog .
    CLEAR ls_fcat.
  ELSE.
    ls_fcat-fieldname = 'AGR_NAME' .
    ls_fcat-inttype = 'C' .
    ls_fcat-outputlen = '10' .
    ls_fcat-coltext = text-018.
    ls_fcat-seltext = text-018 .
    APPEND ls_fcat TO gt_fieldcatalog .
  ENDIF.
  ls_fcat-fieldname = 'UNAME' .
  ls_fcat-inttype = 'C' .
  ls_fcat-outputlen = '35' .
  ls_fcat-coltext = text-020 .
  ls_fcat-seltext = text-020 .
  APPEND ls_fcat TO gt_fieldcatalog.
  CLEAR ls_fcat.

  ls_fcat-fieldname = 'NAME' .
  ls_fcat-inttype = 'C' .
  ls_fcat-outputlen = '35' .
  ls_fcat-coltext = text-021 .
  ls_fcat-seltext = text-021 .
  APPEND ls_fcat TO gt_fieldcatalog.
  CLEAR ls_fcat.

  ls_fcat-fieldname = 'TCODE' .
  ls_fcat-inttype = 'C' .
  ls_fcat-outputlen = '35' .
  ls_fcat-coltext = text-022 .
  ls_fcat-seltext = text-022 .
  APPEND ls_fcat TO gt_fieldcatalog.
  CLEAR ls_fcat.

  ls_fcat-fieldname = 'ROLE_PERCNTAGE'.
  ls_fcat-inttype = 'C'.
  ls_fcat-outputlen = '20'.
  ls_fcat-no_zero = 'X'.
  ls_fcat-coltext = text-023.
  ls_fcat-seltext = text-023.
  APPEND ls_fcat TO gt_fieldcatalog.
  CLEAR ls_fcat.
*************************************************
* *  rkanaka latest changes
  IF l_tabname = '/PSYNG/ER_MAIN' AND p_er = 'X'.
*  When exporting to spreadsheet, checkboxes appear in the
*             incorrect column.  This can be fixed by setting the
*             'JUSTIFIED' flag.
    ls_fcat-fieldname = 'FLG_ER_ROLE'.
*  ls_fcat-inttype = 'C'.
    ls_fcat-checkbox = 'X'.
    ls_fcat-just = 'X'.
    ls_fcat-outputlen = '5'.
*  ls_fcat-no_zero = 'X'.
    ls_fcat-coltext = text-024.
    ls_fcat-seltext = text-024.
    APPEND ls_fcat TO gt_fieldcatalog.
    CLEAR ls_fcat.
  ENDIF.
* *  rkanaka latest changes
*************************************************
ENDFORM.                    " build_fieldcatalog
*&---------------------------------------------------------------------*
*&      Form  build_hierarchy_header
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_L_HIERARCHY_HEADER  text
*----------------------------------------------------------------------*
FORM build_hierarchy_header CHANGING
                     p_hierarchy_header TYPE treev_hhdr.
  p_hierarchy_header-heading = 'Hierarchy Header'.          "#EC NOTEXT
  p_hierarchy_header-tooltip =
                         'This is the Hierarchy Header !'.  "#EC NOTEXT
  p_hierarchy_header-width = 30.
  p_hierarchy_header-width_pix = ''.

ENDFORM.                    " build_hierarchy_header

*&---------------------------------------------------------------------*
*&      Form  create_hierarchy
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM create_hierarchy.
  DATA: l_crole_key TYPE lvc_nkey,
          l_srole_key TYPE lvc_nkey,
          l_last_key TYPE lvc_nkey.
  LOOP AT  gt_final_role INTO wa_role_t .
    PERFORM add_role_node USING    wa_role_t
                                     ''
                            CHANGING l_crole_key.
    g_node_key = l_crole_key.
    IF wa_role_t-flag_com_role = 'X'.


      LOOP AT gt_sin_role INTO wa_sin_role WHERE agr_name =
     wa_role_t-agr_name.
        PERFORM add_sub_role USING    wa_sin_role
                                   l_crole_key
                              CHANGING l_srole_key.


        LOOP AT gt_role_users INTO wa_role_user WHERE agr_name =
                                                 wa_role_t-agr_name AND
                                                     child_agr =
                                                  wa_sin_role-child_agr.


          PERFORM add_user USING  wa_role_user
                                           l_srole_key
                                  CHANGING l_last_key.


          LOOP AT gt_final_tcd_tab INTO wa_role WHERE agr_name =
                                                 wa_role_t-agr_name AND
                                                      child_agr =
                                              wa_sin_role-child_agr AND
                                               name = wa_role_user-name.
            IF wa_role-tcode <> ' '.
              PERFORM add_exe_tcd USING  wa_role
                                      l_last_key.

            ENDIF.
          ENDLOOP.
        ENDLOOP.
      ENDLOOP.
      CALL METHOD tree1->expand_node
   EXPORTING
       i_node_key = g_node_key
       i_level_count = 1.
    ELSE.
      LOOP AT gt_role_users INTO wa_role_user WHERE agr_name =
                                                 wa_role_t-agr_name.


        PERFORM add_user USING  wa_role_user
                                         l_crole_key
                                CHANGING l_last_key.

        LOOP AT gt_final_tcd_tab INTO wa_role WHERE agr_name =
                                                 wa_role_t-agr_name AND
                                               name = wa_role_user-name.
          IF wa_role-tcode <> ' '.
            PERFORM add_exe_tcd USING  wa_role
                                     l_last_key.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
  ENDLOOP.
* calculate totals
  CALL METHOD tree1->update_calculations.

* this method must be called to send the data to the frontend
  CALL METHOD tree1->frontend_update.

ENDFORM.                    " create_hierarchy
*&---------------------------------------------------------------------*
*&      Form  add_carrid_line
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_GT_FINAL_TCD_TAB  text
*      -->P_RELAT_KEY  text
*      <--P_NODE_KEY  text
*----------------------------------------------------------------------*
FORM add_role_node USING    ps_role TYPE gt_final_tab
                               p_relat_key TYPE lvc_nkey
                     CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.

* set item-layout
  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-fieldname = tree1->c_hierarchy_column_name.
  APPEND ls_item_layout TO lt_item_layout.

  ls_item_layout-fieldname = 'PSHBTN_SOD'.
*  ls_item_layout-t_image = '@1F@'.
  ls_item_layout-class = cl_gui_column_tree=>item_class_button.
  ls_item_layout-chosen = ps_role-pshbtn_sod.
  CLEAR ps_role-pshbtn_sod.
  CLEAR ps_role-flg_er_role.
  APPEND ls_item_layout TO lt_item_layout.

* add node
  l_node_text =  ps_role-agr_name.
  CALL METHOD tree1->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = ps_role
          it_item_layout   = lt_item_layout
       IMPORTING
          e_new_node_key = p_node_key.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  ADD_SUB_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM add_sub_role USING     ps_s_role TYPE gt_final_tab
                               p_relat_key TYPE lvc_nkey
                     CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.


  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  CLEAR ps_s_role-flg_er_role.
  ls_item_layout-fieldname = tree1->c_hierarchy_column_name.
  APPEND ls_item_layout TO lt_item_layout.

  ls_item_layout-fieldname = 'PSHBTN_SOD'.
*  ls_item_layout-t_image = '@1F@'.
  ls_item_layout-class = cl_gui_column_tree=>item_class_button.
  ls_item_layout-chosen = wa_sin_role-pshbtn_sod.
  CLEAR ps_s_role-pshbtn_sod.

  APPEND ls_item_layout TO lt_item_layout.

* add node
  l_node_text =  ps_s_role-child_agr.
  CALL METHOD tree1->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = ps_s_role
          it_item_layout   = lt_item_layout
       IMPORTING
          e_new_node_key = p_node_key.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_8000  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_8000 INPUT.
  CASE ok_code.
    WHEN 'EXIT' OR 'CANCEL'.
      PERFORM exit_program.
    WHEN 'BACK'.
      PERFORM back_pgm.
    WHEN OTHERS.
      CALL METHOD cl_gui_cfw=>dispatch.
  ENDCASE.
  CLEAR ok_code.

  CALL METHOD cl_gui_cfw=>flush.

ENDMODULE.                 " USER_COMMAND_8000  INPUT
*&---------------------------------------------------------------------*
*&      Form  exit_program
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM exit_program.
  CALL METHOD tree1->free.
  LEAVE PROGRAM.
ENDFORM.                    " exit_program
*&---------------------------------------------------------------------*
*&      Form  add_USER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_WA_ROLE_USER  text
*      -->p_relat_key  text
*      <--p_node_key  text
*----------------------------------------------------------------------*
FORM add_user USING     ps_user TYPE gt_final_tab
                               p_relat_key TYPE lvc_nkey
                     CHANGING  p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.

  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-fieldname = tree1->c_hierarchy_column_name.
*ls_item_layout-class = cl_gui_column_tree=>item_class_checkbox.
  APPEND ls_item_layout TO lt_item_layout.
*add check box for ER Role
  ls_item_layout-fieldname = 'FLG_ER_ROLE'.
  ls_item_layout-class = cl_gui_column_tree=>item_class_checkbox.
  ls_item_layout-chosen = ps_user-flg_er_role.
  CLEAR ps_user-flg_er_role.
  APPEND ls_item_layout TO lt_item_layout.


* add node
  l_node_text =  ps_user-name.
  CALL METHOD tree1->add_node
    EXPORTING
          i_relat_node_key = p_relat_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          i_node_text      = l_node_text
          is_outtab_line   = ps_user
          it_item_layout   = lt_item_layout
       IMPORTING
          e_new_node_key = p_node_key.

ENDFORM.                    " add_USER
*&---------------------------------------------------------------------*
*&      Form  add_EXE_TCD
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->ps_ex_tcd text
*      -->p_node_key  text
*----------------------------------------------------------------------*
FORM add_exe_tcd USING         ps_ex_tcd TYPE gt_final_tab
                               p_node_key TYPE lvc_nkey.

  DATA: l_node_text TYPE lvc_value.
  ps_ex_tcd-role_percntage = '0'.
  ps_ex_tcd-flg_er_role = ' '.

* set item-layout
  DATA: lt_item_layout TYPE lvc_t_layi,
        ls_item_layout TYPE lvc_s_layi.
  ls_item_layout-fieldname = tree1->c_hierarchy_column_name.
  APPEND ls_item_layout TO lt_item_layout.

  l_node_text =  ps_ex_tcd-tcode.
  CALL METHOD tree1->add_node
    EXPORTING
          i_relat_node_key = p_node_key
          i_relationship   = cl_gui_column_tree=>relat_last_child
          is_outtab_line   = ps_ex_tcd
          i_node_text      = l_node_text
          it_item_layout   = lt_item_layout.
*       importing
*          e_new_node_key = p_node_key.
ENDFORM.                    " add_EXE_TCD
*&---------------------------------------------------------------------*
*&      Form  back_pgm
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM back_pgm.
  CALL METHOD tree1->free.
  LEAVE TO SCREEN 0.
ENDFORM.                    " back_pgm
*&---------------------------------------------------------------------*
*&      Form  PRO_INDICT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_50     text
*      -->P_TEXT_12  text
*----------------------------------------------------------------------*
FORM pro_indict USING    p_per TYPE n
                         p_text TYPE c.
  CALL FUNCTION 'SAPGUI_PROGRESS_INDICATOR'
       EXPORTING
            percentage = p_per
            text       = p_text.

ENDFORM.                    " PRO_INDICT
*&---------------------------------------------------------------------*
*&      Form  GET_ER_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_er_role.
*get all the ER role
  SELECT bname
         agr_name
         fr_date
         to_date
  FROM (l_tabname)
  INTO TABLE gt_er_role
  WHERE bname IN s_uid AND
        agr_name IN s_role. "#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*Check the Current ER ROle
  IF NOT gt_er_role[] IS INITIAL.
    LOOP AT gt_er_role.
     IF NOT sy-datum  BETWEEN gt_er_role-fr_date AND gt_er_role-to_date.
        DELETE  gt_er_role INDEX sy-tabix.
      ENDIF.
    ENDLOOP.
  ENDIF.
  SORT gt_er_role BY agr_name bname fr_date to_date.
  DELETE ADJACENT DUPLICATES FROM gt_er_role COMPARING ALL FIELDS.
ENDFORM.                    " GET_ER_ROLE
*&---------------------------------------------------------------------*
*&      Form  USER_FILTER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_filter.
  DATA: l_cnt_usr TYPE i,
        l_dummy TYPE i.
*select only those user have in role.
  LOOP AT gt_role_user.
    READ TABLE users WITH KEY bname = gt_role_user-uname.
    IF sy-subrc <> 0.
      DELETE gt_role_user.
    ENDIF.
  ENDLOOP.
  IF gt_role_user[] IS INITIAL.
    MESSAGE i146(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
  SORT gt_role_user BY agr_name child_agr uname .
  DELETE ADJACENT DUPLICATES FROM gt_role_user COMPARING ALL FIELDS.
  SORT gt_com_us.
  DELETE ADJACENT DUPLICATES FROM gt_com_us COMPARING ALL FIELDS.


*count no of user with in role.
  LOOP AT gt_role_user.
    l_cnt_usr = l_cnt_usr + 1.
    AT END OF child_agr."agr_name.
      l_dummy = l_cnt_usr.
      CLEAR l_cnt_usr.
    ENDAT.
    gt_role_user-no_of_user = l_dummy.
    MODIFY gt_role_user TRANSPORTING no_of_user.
    CLEAR l_dummy.
  ENDLOOP.

ENDFORM.                    " USER_FILTER
*&---------------------------------------------------------------------*
*&      Form  ADD_ER_ROLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM add_er_role.
  SORT gt_role_user1.

  IF NOT gt_er_role[] IS INITIAL.
    LOOP AT gt_er_role.
      LOOP AT gt_role_user1  WHERE agr_name =
  gt_er_role-agr_name OR child_agr = gt_er_role-agr_name.
        gt_role_user-agr_name = gt_role_user1-agr_name.
        gt_role_user-child_agr = gt_role_user1-child_agr.
        gt_role_user-uname = gt_er_role-bname.
        gt_role_user-flag_com_role = gt_role_user1-flag_com_role.
        gt_role_user-flg_er_role = 'X'.
        APPEND gt_role_user.
      ENDLOOP.
    ENDLOOP.
  ENDIF.
  SORT gt_role_user.
  DELETE ADJACENT DUPLICATES FROM gt_role_user COMPARING ALL FIELDS.
  DELETE ADJACENT DUPLICATES FROM gt_role_user COMPARING uname.
ENDFORM.                    " ADD_ER_ROLE
*&---------------------------------------------------------------------*
*&      Form  register_events
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM register_events.

* define the events which will be passed to the backend
  DATA: lt_events TYPE cntl_simple_events,
        l_event TYPE cntl_simple_event.

* define the events which will be passed to the backend
  l_event-eventid = cl_gui_column_tree=>eventid_button_click.
  APPEND l_event TO lt_events.


  l_event-eventid = cl_gui_column_tree=>eventid_expand_no_children.
  APPEND l_event TO lt_events.


  CALL METHOD tree1->set_registered_events
    EXPORTING
      events = lt_events
    EXCEPTIONS
      cntl_error                = 1
      cntl_system_error         = 2
      illegal_event_combination = 3.
  IF sy-subrc <> 0.
    MESSAGE i100(/psyng/sw).
  ENDIF.



* set Handler
  DATA: l_event_receiver TYPE REF TO lcl_tree_event_receiver.
  CREATE OBJECT l_event_receiver.
  SET HANDLER l_event_receiver->handle_button_click FOR tree1.


ENDFORM.                    " register_events
*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
FORM exelog.
  DATA: exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE,
        l_current_user TYPE sy-uname. "C0700
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR l_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = l_current_user.
* EOC by RGUPTA on 04.04.22 for C0700

  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = l_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.
  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    IN BACKGROUND TASK
    TABLES
     exelog         = exelog.
  COMMIT WORK.
ENDFORM.                    " exelog
