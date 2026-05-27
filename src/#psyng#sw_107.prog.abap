*----------------------------------------------------------------------*
* Report  /PSYNG/SW_107                                                *
* AUTHOR: Security Weaver, LLC                                         *
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
*
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*
REPORT /psyng/sw_107 MESSAGE-ID /psyng/sw.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /PSYNG/BASIS_EXELOG.

* FUNCTION CODES FOR TABSTRIP 'TS_MAIN'
CONSTANTS: BEGIN OF c_ts_main,
             tab1 LIKE sy-ucomm VALUE 'TS_MAIN_FC1',
             tab2 LIKE sy-ucomm VALUE 'TS_MAIN_FC2',
           END OF c_ts_main.

CONSTANTS: gc_display(1) TYPE c VALUE 'D',
           gc_change(1)  TYPE c VALUE 'C',
           gc_select(1)  TYPE c VALUE 'X'.

CONTROLS: ts_main   TYPE TABSTRIP,
          tc_config TYPE TABLEVIEW USING SCREEN 1002.

DATA: BEGIN OF g_ts_main,
        subscreen   LIKE sy-dynnr,
        prog        LIKE sy-repid VALUE '/PSYNG/SW_107',
        pressed_tab LIKE sy-ucomm VALUE c_ts_main-tab1,
      END OF g_ts_main.

DATA: BEGIN OF gt_config OCCURS 10.
        INCLUDE STRUCTURE /PSYNG/SE_CONFIG_PARAM.
*DATA:   default TYPE /psyng/swconfig-value,
data :  newval  TYPE /psyng/swconfig-value,
        sw      TYPE /psyng/bapiflagx,
*        info    TYPE sy-msgno,
        sel(1)  TYPE c,
      END OF gt_config.
data gt_config_tmp like table of gt_config with header line.
DATA: BEGIN OF gt_func OCCURS 0,
        fcode LIKE rsmpe-func,
      END OF gt_func.

DATA: g_ok_code             LIKE sy-ucomm,
      g_curs_line         TYPE i,
      g_tc_config_lines   LIKE sy-loopc,
      g_txt_mit_assgn     TYPE /psyng/swconfig-value,
      g_txt_mit_remind    TYPE /psyng/swconfig-value,
      g_txt_mit_notify    TYPE /psyng/swconfig-value,"C1159 CGUPTA
      g_txt_mit_url       TYPE /psyng/swconfig-value,
      g_lang_mit_assgn(2) TYPE c,
      g_lang_mit_remind(2) TYPE c,
      g_lang_mit_notify(2) TYPE c,"C1159 CGUPTA
      g_lang_mit_url(2)    TYPE c,
      g_msg_mit_assgn(95)  TYPE c,
      g_msg_mit_remind(95) TYPE c,
      g_msg_mit_notify(95) TYPE c,"C1159 CGUPTA
      g_msg_mit_url(95)  TYPE c,
      g_txt_usr_inact     TYPE /psyng/swconfig-value,
      g_lang_usr_inact(2) TYPE c,
      g_msg_usr_inact(95)  TYPE c,
      gs_config           LIKE LINE OF gt_config,
      gt_delete           LIKE TABLE OF gt_config,
      gt_tline            TYPE TABLE OF tline WITH HEADER LINE,
      gf_dispchg(1)       TYPE c,
      gf_insert(1)     type c,
      fld_list LIKE tc_config-cols,
      col TYPE cxtab_column,
      g_txt_mit_soff      TYPE /psyng/swconfig-value,
      g_msg_mit_soff(95)  TYPE c,
      g_lang_mit_soff(2)    TYPE c,
      g_txt_cnf_comp     TYPE /psyng/swconfig-value,
      g_lang_cnf_comp(2)  TYPE c,
      g_msg_cnf_comp(95)  TYPE c.


   data: begin of g_config,
         CATEGORY type /PSYNG/SE_CONFIG_PARAM-CATEGORY,
         param    type /psyng/se_config_param-param,
         VALUE    type /PSYNG/SE_CONFIG_PARAM-value,
    end of g_config.

   DATA: sort_type(20),
         fldname(100),
         gl_config like g_config,
         g_current_user TYPE sy-uname. "C0700


INCLUDE /psyng/sw_107o01.
INCLUDE /psyng/sw_107i01.
INCLUDE /psyng/sw_107f01.

*--------------------------- INITIALIZATION ---------------------------*
INITIALIZATION.
* BOC by RGUPTA on 04.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 04.04.22 for C0700
  AUTHORITY-CHECK OBJECT 'S_TABU_DIS'
           ID 'DICBERCLS' FIELD 'Y&S2'
           ID 'ACTVT' FIELD '03'.
  IF sy-subrc <> 0.
    MESSAGE e108 WITH 'Display'(004) 'Configuration'(006).
  ENDIF.

  gf_dispchg = gc_display.

*------------------------- START-OF-SELECTION -------------------------*
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
   PERFORM get_from_database.
   PERFORM get_texts.
*  refresh gt_config_tmp.
*  gt_config_tmp[] = gt_config[].
  CALL SCREEN 2000.
