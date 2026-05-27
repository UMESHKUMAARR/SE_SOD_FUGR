*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SOD_MANG_REPO
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
REPORT /psyng/sod_mang_repo.
INCLUDE /psyng/sw_config.
TABLES : /psyng/syscandt,usr02.
TYPE-POOLS slis.
PARAMETERS : sodvrsio LIKE /psyng/syscandt-vrsio.
CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.

DATA: g_graph_title(80),
      g_title(80),
      gf_use_erp             TYPE /psyng/bapiflagx,
      go_classtype           TYPE REF TO cl_abap_typedescr,
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx.

*to query by BNAME
DATA: gt_syscandt TYPE SORTED TABLE OF /psyng/syscandt WITH UNIQUE KEY
                 bname conid
                 WITH HEADER LINE.
DATA: gt_syscandt2 TYPE SORTED TABLE OF /psyng/syscandt WITH UNIQUE KEY
                 bname conid
                 WITH HEADER LINE.

*complete user info
TYPES: BEGIN OF typ_userinfo,
         bname       LIKE usr02-bname,
         class       LIKE usr02-class,
         text        LIKE usgrpt-text,
         name        LIKE adrp-name_text,
         werks       LIKE /psyng/output-persa,
         name1       LIKE /psyng/sw_persa_desc-pbtxt,
         conid       LIKE /psyng/conflict-conid,
         imp         LIKE /psyng/conflict-imp,
         description LIKE /psyng/conflict-description,
       END OF typ_userinfo.
DATA: gt_userinfo TYPE HASHED TABLE OF typ_userinfo WITH UNIQUE KEY
              bname WITH HEADER LINE.

DATA: gt_user_gp_info TYPE STANDARD TABLE  OF typ_userinfo INITIAL SIZE
0 WITH HEADER LINE.

DATA: gt_user_gp_hi TYPE STANDARD TABLE  OF typ_userinfo INITIAL SIZE
0 WITH HEADER LINE.
DATA: gt_user_gp_crit TYPE STANDARD TABLE  OF typ_userinfo INITIAL SIZE
0 WITH HEADER LINE.
DATA: gt_user_gp_med TYPE STANDARD TABLE  OF typ_userinfo INITIAL SIZE
0 WITH HEADER LINE.
DATA: gt_user_gp_low TYPE STANDARD TABLE  OF typ_userinfo INITIAL SIZE
0 WITH HEADER LINE.

DATA: BEGIN OF gt_user_gp_con OCCURS 0,
        conid LIKE /psyng/conflict-conid,
        imp   LIKE /psyng/conflict-imp,
      END OF gt_user_gp_con.

*User ID information
TYPES: BEGIN OF typ_usrgrp,
         bname LIKE usr02-bname,
         class LIKE usr02-class,
         name  LIKE adrp-name_text,
         pernr LIKE /psyng/output-pernr,
       END OF typ_usrgrp.
DATA: gt_usrgrp TYPE HASHED TABLE OF typ_usrgrp WITH UNIQUE KEY
             bname
             WITH HEADER LINE.


DATA: gt_iadrp TYPE HASHED TABLE OF /psyng/bc_uidn WITH UNIQUE KEY
                 bname
                 WITH HEADER LINE.


*Configuration tables containing texts
DATA: gt_iusgrpt TYPE HASHED TABLE OF usgrpt WITH UNIQUE KEY
              usergroup
              WITH HEADER LINE.

DATA: gt_iconflict TYPE HASHED TABLE OF /psyng/conflict WITH UNIQUE KEY
                conid "DESCRIPTION OWNER IMP BUSAREA
                WITH HEADER LINE.

TYPES: BEGIN OF byuserid_typ,
         bname LIKE /psyng/syscandt-bname,
         count TYPE p,
       END OF byuserid_typ.

DATA: gt_byuserid TYPE SORTED TABLE OF byuserid_typ WITH UNIQUE KEY
               bname
               WITH HEADER LINE.
DATA: wa_byuserid TYPE byuserid_typ.

DATA: BEGIN OF gt_byuserid2 OCCURS 0.
DATA:   bname LIKE /psyng/syscandt-bname,
        count TYPE p,
        END OF gt_byuserid2.

DATA: BEGIN OF gt_byusergrp OCCURS 0.
DATA:   usergroup LIKE usgrp-usergroup,
        count     TYPE p,
        END OF gt_byusergrp.

TYPES: BEGIN OF bybusarea_typ,
         busarea LIKE /psyng/busarea-busarea,
         count   TYPE p,
       END OF bybusarea_typ.
DATA: gt_bybusarea TYPE SORTED TABLE OF bybusarea_typ WITH UNIQUE KEY
                busarea
                WITH HEADER LINE.
DATA: wa_bybusarea TYPE bybusarea_typ.

DATA: BEGIN OF gt_bybusarea2 OCCURS 0.
DATA:   busarea LIKE /psyng/busarea-busarea,
        count   TYPE p,
        END OF gt_bybusarea2.

DATA: BEGIN OF gt_bypersa OCCURS 0.
DATA:   werks LIKE /psyng/output-persa,
        count TYPE p,
        END OF gt_bypersa.

DATA: BEGIN OF gt_bysens OCCURS 0.
DATA:   imp   LIKE /psyng/conflict-imp,
        count TYPE p,
        END OF gt_bysens.

TYPES: BEGIN OF byconflict_typ,
         conid       LIKE /psyng/conflict-conid,
         count       TYPE p,
         description LIKE /psyng/conflict-description,
       END OF byconflict_typ.
DATA: gt_byconflict TYPE SORTED TABLE OF byconflict_typ WITH UNIQUE KEY
                conid
                WITH HEADER LINE.
DATA: wa_byconflict TYPE byconflict_typ.

DATA: BEGIN OF gt_byconflict2 OCCURS 0.
DATA:   conid LIKE /psyng/conflict-conid,
        count TYPE p,
        END OF gt_byconflict2.

* Graphs
DATA: BEGIN OF gt_data OCCURS 1,
        text(25),
        value     TYPE p,
        desc(100) TYPE c,
      END OF gt_data.
DATA: BEGIN OF gt_grafmenu OCCURS 1,
        text(32),                              "button text
      END OF gt_grafmenu.

DATA:g_flag_usr_grp_det TYPE c,
     g_tot_crit_con     TYPE i,
     g_tot_hg_con       TYPE i,
     g_tot_mid_con      TYPE i,
     g_tot_low_con      TYPE i.

DATA: p_class   LIKE usr02-class,
      l_tot_con TYPE string.

DATA: BEGIN OF gt_grp_usr OCCURS 0,
        bname LIKE usr02-bname,
        class LIKE usr02-class,
      END OF gt_grp_usr.

DATA: BEGIN OF gt_nouser OCCURS 0,
        name  TYPE string,
        count TYPE i,
      END OF gt_nouser.
DATA: BEGIN OF gt_nouser_h OCCURS 0,
        name  TYPE string,
        count TYPE i,
      END OF gt_nouser_h.
DATA: BEGIN OF gt_nouser_m OCCURS 0,
        name  TYPE string,
        count TYPE i,
      END OF gt_nouser_m.
DATA: BEGIN OF gt_nouser_l OCCURS 0,
        name  TYPE string,
        count TYPE i,
      END OF gt_nouser_l.

DATA: g_t_usr_c TYPE string,
      g_t_usr_h TYPE string,
      g_t_usr_m TYPE string,
      g_t_usr_l TYPE string.
DATA: g_cnt TYPE i.

*dhorions : previous button to know from where sod
* analysis is executed
DATA  g_prev_button TYPE c.

TYPES : BEGIN OF ty_busarea,
          busarea TYPE /psyng/busarea-busarea,
          text    TYPE /psyng/busarea-text,
        END OF ty_busarea.

TYPES : BEGIN OF ty_conflict,
          conid       TYPE /psyng/conflict-conid,
          description TYPE /psyng/conflict-description,
        END OF ty_conflict.

TYPES: BEGIN OF ty_usgrpt,
         usergroup TYPE char12,
         text(60)  TYPE c,
       END OF ty_usgrpt.

TYPES: BEGIN OF ty_t500p,
         persa TYPE char4,
         name1 TYPE char30,
       END OF ty_t500p.

CONSTANTS : gc_app_area      TYPE sy-ucomm VALUE 'APP_AREA',
            gc_conflict      TYPE sy-ucomm VALUE 'CONFLICT',
            gc_sensitvity    TYPE sy-ucomm VALUE 'SENSITVITY',
            gc_user_group    TYPE sy-ucomm VALUE 'USER_GROUP',
            gc_grp_dtls      TYPE sy-ucomm VALUE 'GRP_DTLS',
            gc_usr_wi_mos    TYPE sy-ucomm VALUE 'USR_WI_MOS',
            gc_per_area      TYPE sy-ucomm VALUE 'PER_AREA',
            gc_summary       TYPE sy-ucomm VALUE 'SUMMARY',
            gc_critical      TYPE sy-ucomm VALUE 'CRITICAL',
            gc_high          TYPE sy-ucomm VALUE 'HIGH',
            gc_medium        TYPE sy-ucomm VALUE 'MEDIUM',
            gc_low           TYPE sy-ucomm VALUE 'LOW',
            gc_conflicts     TYPE sy-ucomm VALUE 'CONFLICTS',
            gc_bac           TYPE sy-ucomm VALUE 'BAC',
            gc_canc          TYPE sy-ucomm VALUE 'CANC',
            gc_bak           TYPE sy-ucomm VALUE 'BAK',
            gc_exi           TYPE sy-ucomm VALUE 'EXI',
            gc_graf          TYPE rsmpe-status    VALUE 'GRAF',
            gc_pf_status     TYPE slis_formname VALUE 'PF_STATUS',
            gc_user_command  TYPE slis_formname VALUE 'USER_COMMAND',
            gc_gt_data       TYPE slis_tabname  VALUE 'GT_DATA',
            gc_group_dtls    TYPE rsmpe-status  VALUE 'GROUP_DTLS',
            gc_open_bracket  TYPE c             VALUE '(',
            gc_close_bracket TYPE c             VALUE ')',
            gc_text          TYPE slis_fieldcat_alv-fieldname
                                                VALUE 'TEXT',
            gc_value         TYPE slis_fieldcat_alv-fieldname
                                                VALUE 'VALUE',
            gc_desc          TYPE slis_fieldcat_alv-fieldname
                                                VALUE 'DESC',
            gc_t500p         TYPE dd02l-tabname   VALUE 'T500P',
            gc_a             TYPE dd02l-as4local  VALUE 'A'.


DATA :g_count_result_flag           TYPE c,
      g_program                     LIKE sy-repid,
      gt_fieldcat                   TYPE slis_t_fieldcat_alv,
      gs_alv_layout                 TYPE slis_layout_alv,
      gs_fieldcat                   TYPE slis_fieldcat_alv,
      g_group_detail_pf_status_flag TYPE c,
      g_first_display               TYPE c,
      g_tabname                     TYPE dd02l-tabname,
      gt_username                   TYPE TABLE OF /psyng/bc_userid_name,
      g_current_user                TYPE sy-uname. "C0700


INITIALIZATION.
  REFRESH : gt_fieldcat[], gt_username[].
  CLEAR: g_count_result_flag, g_program, gs_alv_layout,
         gs_fieldcat, g_group_detail_pf_status_flag,
         g_first_display.
* BOC by RGUPTA on 29.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 29.03.22 for C0700
  SELECT SINGLE tabname
         INTO g_tabname
         FROM dd02l
         WHERE tabname  = gc_t500p
         AND   as4local = gc_a."#EC SAST_CI_GEN_CHECK


  PERFORM exelog.

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
* Determine whether or not to use ERP tables
  CALL METHOD cl_abap_classdescr=>describe_by_name
    EXPORTING
      p_name         = gc_erp_class
    RECEIVING
      p_descr_ref    = go_classtype
    EXCEPTIONS
      type_not_found = 1
      OTHERS         = 2.

  IF sy-subrc = 0.
    gf_use_erp = abap_true.
  ELSE.
    CLEAR gf_use_erp.
  ENDIF.

  PERFORM get_scan_details.
  PERFORM get_config_texts.
  PERFORM get_user_info.
  PERFORM put_all_data_together.
  PERFORM output_graphs.
*---------------------------------------------------------------------*
*       FORM get_scan_details                                         *
*---------------------------------------------------------------------*
FORM get_scan_details.
  CONSTANTS : lc_none TYPE /psyng/syscandt-conid VALUE 'NONE',
              lc_y    TYPE /psyng/swconfig-value VALUE 'Y'.
  DATA: lt_syscandt1 TYPE STANDARD TABLE OF /psyng/syscandt WITH HEADER
  LINE.
*If the configuration setting SW_ENH_SCAN_TBL = Y,
* a popup is shown to decide which scan table to use for Graphs
  DATA :  ls_tabname           TYPE tabname,
          ls_config            TYPE /psyng/swconfig,
          l_scantable_decision TYPE flag.
  CONSTANTS : enh_tabname TYPE tabname VALUE '/PSYNG/ENHSCANDT',
              sys_tabname TYPE tabname VALUE '/PSYNG/SYSCANDT'.
  se_config_param 'SW_ENH_SCAN_TBL' ls_config-value.
  IF ls_config-value = lc_y.
    CALL FUNCTION 'POPUP_TO_DECIDE'
         EXPORTING
              textline1      = 'Choose SOD-Matrix for Graphs'(019)
              text_option1   = 'Standard SOD-Matrix'(020)
              text_option2   = 'Enhanced SOD-Matrix'(021)
              titel          = 'Choose SOD-Matrix for Graphs'(019)
              cancel_display = ' '
         IMPORTING
              answer         = l_scantable_decision.
    IF l_scantable_decision = 2.
      ls_tabname = enh_tabname.
    ELSE.
      ls_tabname = sys_tabname.
    ENDIF.
  ELSE.
    ls_tabname = sys_tabname.
  ENDIF.
*select data from appropriate scan table

CASE ls_Tabname.
  WHEN enh_tabname.
    SELECT * FROM /PSYNG/ENHSCANDT INTO TABLE lt_syscandt1
         WHERE conid <> lc_none
         AND   vrsio = sodvrsio."#EC SAST_CI_GEN_CHECK
  WHEN sys_tabname.
    SELECT * FROM /PSYNG/SYSCANDT INTO TABLE lt_syscandt1
         WHERE conid <> lc_none
         AND   vrsio = sodvrsio."#EC SAST_CI_GEN_CHECK
ENDCASE.

*  SELECT * FROM (ls_tabname) INTO TABLE lt_syscandt1
*         WHERE conid <> lc_none
*         AND   vrsio = sodvrsio.

  SORT: lt_syscandt1 BY bname conid scandate DESCENDING.
  DELETE ADJACENT DUPLICATES FROM lt_syscandt1 COMPARING bname conid.
  REFRESH: gt_syscandt.
  gt_syscandt[] = lt_syscandt1[].
  REFRESH lt_syscandt1.
  CLEAR lt_syscandt1.

  IF gt_syscandt[] IS INITIAL.
    CALL FUNCTION 'POPUP_TO_INFORM'
         EXPORTING
              titel = 'Information'(000)
              txt1  = ''(009)
              txt2  = ' No data available'(001).
    LEAVE PROGRAM.
  ENDIF.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_user_info                                            *
*---------------------------------------------------------------------*
FORM get_user_info.
  DATA: wa_usrgrp TYPE typ_usrgrp.

  SELECT bname class
         FROM usr02
         INTO (wa_usrgrp-bname, wa_usrgrp-class)
         ORDER BY bname.
    INSERT wa_usrgrp INTO TABLE gt_usrgrp.
    CLEAR: wa_usrgrp.
  ENDSELECT.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_config_texts
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM get_config_texts.
  SELECT DISTINCT usergroup text
         FROM usgrpt
         INTO CORRESPONDING FIELDS OF TABLE gt_iusgrpt
         WHERE sprsl = sy-langu.
  SELECT DISTINCT conid vrsio description owner imp busarea
         FROM /psyng/conflict
         INTO CORRESPONDING FIELDS OF TABLE gt_iconflict
         WHERE vrsio = sodvrsio.
ENDFORM.                    " get_config_texts
*&---------------------------------------------------------------------*
*&      Form  put_all_data_together
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM put_all_data_together.
  CONSTANTS: lc_pa_name_method(25) TYPE c VALUE
                                  'GET_PERSONNEL_AREA_NAME',
             lc_persa_method(17)   TYPE c VALUE 'GET_USERS_FROM_HR',
             lc_i                  TYPE char1   VALUE 'I',
             lc_eq                 TYPE char2 VALUE 'EQ'.


  DATA: lo_erp_class TYPE REF TO object,
        lt_uidn      TYPE TABLE OF /psyng/bc_uidn,
        lt_user      TYPE /psyng/hr_user_t,
        ls_user      TYPE /psyng/hr_user,
        l_reject     TYPE /psyng/bapiflagx,
        ls_userinfo  TYPE typ_userinfo,
        ls_adrp      TYPE adrp.

  DATA : lt_uinfo  TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
         lf_reject TYPE flag.

  RANGES: lt_bname FOR /psyng/bc_uidn-bname.


  IF gf_use_erp = abap_true.
    CREATE OBJECT lo_erp_class TYPE (gc_erp_class).
    IF sy-subrc <> 0.
      CLEAR gf_use_erp.
    ELSE.
 CALL METHOD lo_erp_class->(lc_persa_method)"#EC PATHLOCK_CI_DYN_ACCES
        EXPORTING
          i_begda = sy-datum
          i_endda = sy-datum
        IMPORTING
          et_user = lt_user.

      SORT lt_user BY bname.
    ENDIF.
  ENDIF.

  lt_bname-sign   = lc_i.
  lt_bname-option = lc_eq.
  LOOP AT lt_user INTO ls_user.
    lt_bname-low = ls_user-bname.
    APPEND lt_bname.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/BC_011'
       TABLES
            it_bname = lt_bname
            et_uidn  = lt_uidn.
*BOC UMITTAL PN6315 09/09/2024
"Resolving PN 6315:Dump coming while execution
"because of Duplicate users
SORT lt_uidn BY bname.
DELETE ADJACENT DUPLICATES FROM lt_uidn COMPARING bname.
*EOC UMITTAL PN6315 09/09/2024
  gt_iadrp[] = lt_uidn[].
  FREE lt_uidn.

  LOOP AT gt_usrgrp.
    lt_uinfo-bname = gt_usrgrp-bname.
    APPEND lt_uinfo.
  ENDLOOP.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
       EXPORTING
            vrsio        = sodvrsio
            i_name_only  = abap_true
            i_mr_company = abap_true
       TABLES
            sw_uinfo     = lt_uinfo.
  LOOP AT lt_uinfo.
    CLEAR lf_reject.
    PERFORM check_rpoug_auth USING lt_uinfo sodvrsio
                             CHANGING lf_reject.
    IF lf_reject = abap_true.
      DELETE gt_usrgrp WHERE bname = lt_uinfo-bname.
      gf_missing_auth_ugroup = abap_true.
    ENDIF.
  ENDLOOP.



  LOOP AT gt_syscandt.
    ls_userinfo-bname = gt_syscandt-bname.
    ls_userinfo-conid = gt_syscandt-conid.
    READ TABLE gt_usrgrp WITH TABLE KEY bname = gt_syscandt-bname.
    IF sy-subrc EQ 0.
      ls_userinfo-class = gt_usrgrp-class.
    ELSE.
      DELETE gt_syscandt.
      CONTINUE.
    ENDIF.

*   If ERP system, get personnel area info
    IF gf_use_erp = abap_true.
      READ TABLE lt_user INTO ls_user
                 WITH KEY bname = gt_syscandt-bname
                 BINARY SEARCH.

      ls_userinfo-werks = ls_user-werks.

CALL METHOD lo_erp_class->(lc_pa_name_method)"#EC PATHLOCK_CI_DYN_ACCES
        EXPORTING
          i_persa = ls_user-werks
        IMPORTING
          e_pbtxt = ls_userinfo-name1.
    ENDIF.

    READ TABLE gt_iadrp WITH TABLE KEY bname = gt_syscandt-bname.
    IF sy-subrc EQ 0.
      ls_userinfo-name = gt_iadrp-name_text.
    ENDIF.

    READ TABLE gt_iusgrpt WITH TABLE KEY usergroup = gt_usrgrp-class.
    IF sy-subrc = 0.
      ls_userinfo-text = gt_iusgrpt-text.
    ENDIF.
    READ TABLE gt_iconflict WITH TABLE KEY conid = gt_syscandt-conid.
    IF sy-subrc = 0.
      ls_userinfo-imp = gt_iconflict-imp.
      ls_userinfo-description = gt_iconflict-description.
    ENDIF.
    INSERT ls_userinfo INTO TABLE gt_userinfo.
    CLEAR ls_userinfo.
  ENDLOOP.                                                  "syscandt

  FREE: gt_iadrp.
  CLEAR ls_userinfo.
ENDFORM.                    " put_all_data_together

*&---------------------------------------------------------------------*
*&      Form  output_graphs
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_graphs.
  DATA: l_busg_stat TYPE c,   "graphic-parameter
        l_m_typ     TYPE c,   "graphic parameter
        l_b_typ     TYPE c,   "graphic parameter
        l_b_key(2)  TYPE c.   "pressed graphic button

  CONSTANTS : lc_colon(3) TYPE c VALUE ' : ',
              lc_hypen(3) TYPE c VALUE ' - ',
              lc_d        TYPE c VALUE 'D',
              lc_c        TYPE c VALUE 'C',
              lc_i        TYPE c VALUE 'I',
              lc_5        TYPE i VALUE '5',
              lc_hs(2)    TYPE c VALUE 'HS',
              lc_90       TYPE i VALUE '90'.


  IF gf_missing_auth_ugroup = abap_true.
    MESSAGE i398(00) WITH
                     'Missing some user group authorizations.'(018).
  ENDIF.
  CLEAR: g_flag_usr_grp_det.

  LOOP AT gt_syscandt.
    CLEAR: gt_bybusarea, gt_bypersa, gt_byconflict, gt_bysens,
  gt_byuserid,wa_byuserid, wa_bybusarea.

    PERFORM fill_bybusarea.
    PERFORM fill_bypersa.
    PERFORM fill_byconflict.
    PERFORM fill_bysens.
    PERFORM fill_byuserid.
  ENDLOOP.
  gt_syscandt2[] = gt_syscandt[].
  REFRESH: gt_syscandt.
  SORT gt_bypersa BY count DESCENDING werks ASCENDING AS TEXT.
  DELETE ADJACENT DUPLICATES FROM gt_bypersa.
  SORT gt_bysens BY count DESCENDING imp ASCENDING AS TEXT.
  DELETE ADJACENT DUPLICATES FROM gt_bysens.

  gt_byuserid2[] = gt_byuserid[].
  SORT gt_byuserid2 BY count DESCENDING bname ASCENDING AS TEXT.
  REFRESH gt_byuserid.
  gt_bybusarea2[] = gt_bybusarea[].
  SORT gt_bybusarea2 BY count DESCENDING busarea ASCENDING AS TEXT.
  REFRESH gt_bybusarea.
  gt_byconflict2[] = gt_byconflict[].
  SORT gt_byconflict2 BY count DESCENDING conid ASCENDING AS TEXT.
  REFRESH gt_byconflict.

  IF l_b_key IS INITIAL.
    l_b_key = 1.
  ENDIF.

  PERFORM fill_data_tab_for_graph USING l_b_key.
  DO.
    IF g_count_result_flag IS INITIAL.
      IF g_flag_usr_grp_det = abap_true.
        REFRESH gt_grafmenu.
        gt_grafmenu-text = 'Summary'(102).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'Critical'(130).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'High'(103).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'Medium'(104).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'Low'(105).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'Conflicts'(106).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'Run SOD Analysis'(126).
        APPEND gt_grafmenu.

      ELSE.
        REFRESH gt_grafmenu.
        gt_grafmenu-text = 'By Application Area'(002).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'By Conflict'(004).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'By Sensitivity'(005).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'By User Group'(006).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'User Group Details'(101).
        APPEND gt_grafmenu.

        gt_grafmenu-text = 'By Users with Most'(007).
        APPEND gt_grafmenu.

* If ERP system, allow running by personnel area
        IF gf_use_erp = abap_true.
          gt_grafmenu-text = 'By Personnel Area'(003).
          APPEND gt_grafmenu.
        ENDIF.
        gt_grafmenu-text = 'Count'(022).
        APPEND gt_grafmenu.
      ENDIF.


      IF NOT gt_data[] IS INITIAL.
        CALL FUNCTION 'GRAPH_BUSG_MENU_SET'
             TABLES
                  menu_tab = gt_grafmenu.

*--Add version to title
        CLEAR g_title.
        g_title = g_graph_title.
        CONCATENATE 'Version'(t01)
                    lc_colon
                    sodvrsio
                    lc_hypen
                    g_title
                    INTO g_title SEPARATED BY space.

        CALL FUNCTION 'GRAPH_2D'
             EXPORTING
                  stat         = l_busg_stat
                  mail_allow   = abap_true
                  titl         = g_title
                  display_type = lc_hs
                  winpos       = lc_5
                  winszx       = lc_90
                  winszy       = lc_90
             IMPORTING
                  m_typ        = l_m_typ
                  b_typ        = l_b_typ
                  b_key        = l_b_key
             TABLES
                  data         = gt_data
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             GUI_REFUSE_GRAPHIC = 1
             OTHERS             = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
        l_busg_stat = 3.
**********tsen***************
        IF g_flag_usr_grp_det = abap_true AND l_m_typ = lc_d.
          CLEAR: g_flag_usr_grp_det.
          CLEAR: l_busg_stat.
          l_b_key = 1.
          l_b_typ = lc_c.
          l_m_typ = lc_i.
        ENDIF.
***********************************
        CASE l_m_typ.
          WHEN lc_d.
            EXIT.
          WHEN lc_i.
            CASE l_b_typ.
              WHEN lc_c.
                IF l_b_key = 1 OR l_b_key = 2 OR l_b_key = 3
                  OR l_b_key = 4 OR
                            l_b_key = 5  OR
                            ( l_b_key = 7  AND
                  g_flag_usr_grp_det IS INITIAL )
                            OR l_b_key = 6 OR l_b_key = 8.
                  PERFORM fill_data_tab_for_graph USING l_b_key.
                ELSEIF l_b_key = 7 AND g_flag_usr_grp_det = abap_true .
                  PERFORM do_sod_analysis.
                ENDIF.
            ENDCASE.
        ENDCASE.
      ELSE.
        MESSAGE i208(00)
          WITH 'No data available for this criteria. Trying next.'(008).
        ADD 1 TO l_b_key.
        IF l_b_key GT 7.
          l_b_key = 1.
        ENDIF.
        PERFORM fill_data_tab_for_graph USING l_b_key.
      ENDIF.
    ELSE.
      EXIT.
    ENDIF.
  ENDDO.

ENDFORM.                    " output_graphs
*&---------------------------------------------------------------------*
*&      Form  fill_data_tab_for_graph
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_data_tab_for_graph USING button.
  REFRESH gt_data.
  IF g_flag_usr_grp_det = space.
    CASE button.
*- Created Subroutine for SOD Types, for reusability of code.

      WHEN 1.      "by Application Area
        PERFORM byapplicationarea.
        g_graph_title = 'Top Application Areas (by conflicts)'(010).
      WHEN 2.       "by conflicts
        PERFORM byconflict.
        g_graph_title = 'Top 30 conflicts (by user count)'(011).
      WHEN 3.      "by Sensitivity
        PERFORM bysensitivity.
        g_graph_title = 'Conflicts by Sensitivity'(012).
      WHEN 4.   "by user group
        PERFORM byusergrp.
        g_graph_title = 'Top 30 User Groups (by conflicts)'(013).
      WHEN 6.   "by user id
        PERFORM byuserid.
        g_graph_title = 'Top 30 User IDs with most Conflicts'(014).
      WHEN 7. "by Personnel Area
        IF gf_use_erp EQ abap_true.
          PERFORM bypersa.
          g_graph_title = 'Top 30 Personnel Areas (by conflicts)'(015).
        ELSE.
          PERFORM bycount.
        ENDIF.
      WHEN 8.      "Count
        PERFORM bycount.
      WHEN 5.

        CALL SCREEN 100 STARTING AT 40 10 .
    ENDCASE.
  ELSE.
*******  CODE FOR UserGroup de BUTTON****************
    g_prev_button = button.
    CASE button.
      WHEN 1.      "by SUMMARY
        PERFORM summary.
        CONCATENATE 'Summary of user group'(107) p_class INTO
                              g_graph_title SEPARATED BY space.
      WHEN 2.      "by CRITICAL
        PERFORM crit_con.
        CLEAR: g_graph_title.
        PERFORM data_cnt.
        IF g_cnt LE 30.
          CONCATENATE g_t_usr_c 'Users with Critical Conflicts in'(127)
                      p_class   INTO g_graph_title SEPARATED BY space.
        ELSE.
          CONCATENATE 'Top 30 of'(114) g_t_usr_c
                       'Users with Critical Conflicts in'(127) p_class
                       INTO g_graph_title SEPARATED BY space.
        ENDIF.
      WHEN 3.      "by HIGH CONF
        PERFORM high_con.
        CLEAR: g_graph_title.
        PERFORM data_cnt.
        IF g_cnt LE 30.
          CONCATENATE g_t_usr_h 'Users with High Conflicts in'(123)
                      p_class INTO g_graph_title SEPARATED BY space.
        ELSE.
          CONCATENATE 'Top 30 of'(114) g_t_usr_h
                      'Users with High Conflicts in'(123) p_class
                       INTO g_graph_title SEPARATED BY space.
        ENDIF.
      WHEN 4.      "by MEDIUM CONF
        PERFORM medium_con.
        CLEAR: g_graph_title.
        PERFORM data_cnt.
        IF g_cnt LE 30.
          CONCATENATE g_t_usr_m ' Users with Medium Conflicts in'(116)
                      p_class INTO g_graph_title SEPARATED BY space.
        ELSE.
          CONCATENATE 'Top 30 of'(114) g_t_usr_m
                      ' Users with Medium Conflicts in'(116) p_class
                      INTO g_graph_title SEPARATED BY space.
        ENDIF.
      WHEN 5.      "by LOW CONF
        PERFORM low_con.
        CLEAR: g_graph_title.
        PERFORM data_cnt.
        IF g_cnt LE 30.
          CONCATENATE g_t_usr_l  ' Users with Low Conflicts in'(118)
                      p_class INTO g_graph_title SEPARATED BY space.
        ELSE.
          CONCATENATE 'Top 30 of'(114) g_t_usr_l
                       ' Users with Low Conflicts in'(118) p_class INTO
                        g_graph_title SEPARATED BY space.
        ENDIF.
      WHEN 6.      "by CONFid
        PERFORM by_conid.
        CLEAR: g_graph_title.
       CONCATENATE 'Top 30 Conflicts for'(119)  p_class gc_open_bracket
                             l_tot_con 'total)'(121) INTO g_graph_title
                             SEPARATED BY space.
    ENDCASE.
  ENDIF.
ENDFORM.                    " fill_data_tab_for_graph

*&---------------------------------------------------------------------*
*&      Form  exelog
*&---------------------------------------------------------------------*
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
      exelog = exelog.

  COMMIT WORK.
ENDFORM.                    " exelog
*&---------------------------------------------------------------------*
*&      Form  fill_bybusarea
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_bybusarea.
  DATA: l_bybusarea_idx TYPE i.

  READ TABLE gt_iconflict WITH TABLE KEY conid = gt_syscandt-conid.
  IF sy-subrc = 0 AND ( NOT gt_iconflict-busarea IS INITIAL ) .
    READ TABLE gt_bybusarea WITH KEY busarea = gt_iconflict-busarea
               BINARY SEARCH TRANSPORTING NO FIELDS.
    IF sy-subrc = 0.
      l_bybusarea_idx = sy-tabix.
    ENDIF.
    LOOP AT gt_bybusarea FROM l_bybusarea_idx
            WHERE busarea = gt_iconflict-busarea.
      gt_bybusarea-count = gt_bybusarea-count + 1.
      MODIFY gt_bybusarea.
    ENDLOOP.
    IF sy-subrc NE 0.
      wa_bybusarea-busarea = gt_iconflict-busarea.
      wa_bybusarea-count = 1.
      INSERT wa_bybusarea INTO TABLE gt_bybusarea.
    ENDIF.
  ENDIF.
ENDFORM.                    " fill_bybusarea
*&---------------------------------------------------------------------*
*&      Form  fill_bypersa
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_bypersa.
  CHECK gf_use_erp = abap_true.

  READ TABLE gt_userinfo WITH TABLE KEY bname = gt_syscandt-bname.
  IF sy-subrc EQ 0 AND ( NOT gt_userinfo-werks IS INITIAL ) .
    LOOP AT gt_bypersa WHERE werks = gt_userinfo-werks.
      gt_bypersa-count = gt_bypersa-count + 1.
      MODIFY gt_bypersa.
    ENDLOOP.
    IF sy-subrc NE 0.
      gt_bypersa-werks = gt_userinfo-werks.
      gt_bypersa-count = 1.
      APPEND gt_bypersa.
    ENDIF.
  ENDIF.

ENDFORM.                    " fill_bypersa
*&---------------------------------------------------------------------*
*&      Form  fill_byconflict
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_byconflict.
  DATA: l_byconflict_idx TYPE i.

*  -   -   -   -   - If BYCONFLICT table is SORTED -   -   -   -   -  |
  READ TABLE gt_byconflict WITH KEY conid = gt_syscandt-conid
             BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 0.
    l_byconflict_idx = sy-tabix.
  ENDIF.
  LOOP AT gt_byconflict FROM l_byconflict_idx
  WHERE conid = gt_syscandt-conid.
    gt_byconflict-count = gt_byconflict-count + 1.
    MODIFY gt_byconflict.
  ENDLOOP.
  IF sy-subrc NE 0.
    wa_byconflict-conid = gt_syscandt-conid.
    wa_byconflict-count = 1.
    INSERT wa_byconflict INTO TABLE gt_byconflict.
  ENDIF.
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - |

ENDFORM.                    " fill_byconflict
*&---------------------------------------------------------------------*
*&      Form  fill_bysens
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_bysens.
  READ TABLE gt_iconflict WITH TABLE KEY conid = gt_syscandt-conid.
  IF sy-subrc = 0 AND ( NOT gt_iconflict-imp IS INITIAL ) .
    LOOP AT gt_bysens WHERE imp = gt_iconflict-imp.
      gt_bysens-count = gt_bysens-count + 1.
      MODIFY gt_bysens.
    ENDLOOP.
    IF sy-subrc NE 0.
      gt_bysens-imp = gt_iconflict-imp.
      gt_bysens-count = 1.
      APPEND gt_bysens.
    ENDIF.
  ENDIF.

ENDFORM.                    " fill_bysens
*&---------------------------------------------------------------------*
*&      Form  fill_byuserid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_byuserid.
  DATA: l_byuserid_idx TYPE i.

*  -   -   -   -   - If BYUSERID table is SORTED -   -   -   -   -  |
  READ TABLE gt_byuserid WITH KEY bname = gt_syscandt-bname
             BINARY SEARCH TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 0.
    l_byuserid_idx = sy-tabix.
  ENDIF.
  LOOP AT gt_byuserid FROM l_byuserid_idx WHERE bname =
gt_syscandt-bname.
    gt_byuserid-count = gt_byuserid-count + 1.
    MODIFY gt_byuserid.
  ENDLOOP.
  IF sy-subrc NE 0.
    wa_byuserid-bname = gt_syscandt-bname.
    wa_byuserid-count = 1.
    INSERT wa_byuserid INTO TABLE gt_byuserid.
  ENDIF.
* -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   -   - |
ENDFORM.                    " fill_byuserid

*&---------------------------------------------------------------------*
*&      Module  AFTER_INPUT  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE after_input INPUT.
  CONSTANTS : lc_can   TYPE sy-ucomm VALUE 'CAN',
              lc_conti TYPE sy-ucomm VALUE 'CONTI'.
  DATA: l_b_key(2)  TYPE c.   "pressed graphic button
  CASE sy-ucomm.
    WHEN lc_can.
      g_flag_usr_grp_det  = space.
      g_group_detail_pf_status_flag = space.
      l_b_key = 1.
      PERFORM fill_data_tab_for_graph USING l_b_key.
      LEAVE TO  SCREEN 000.
    WHEN lc_conti.
      IF sy-subrc = 0.
        g_group_detail_pf_status_flag = abap_true.
        PERFORM user_group_details.
        LEAVE TO  SCREEN 000.
      ELSE.
        MESSAGE w108(/psyng/sw) WITH 'display user group'(125)
                                      usr02-class .
      ENDIF.
  ENDCASE.
ENDMODULE.                 " AFTER_INPUT  INPUT
*&---------------------------------------------------------------------*
*&      Form  USER_GROUP_DETAILS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_group_details.
  DATA: l_cunt TYPE i VALUE 0.
  DATA: lt_syscandt1 TYPE STANDARD TABLE OF /psyng/syscandt WITH HEADER
        LINE.
  REFRESH : gt_data,gt_grp_usr,gt_user_gp_info,gt_user_gp_hi,
  gt_user_gp_med,gt_user_gp_low,gt_user_gp_con.
  CLEAR: g_tot_low_con,g_tot_hg_con,g_tot_mid_con,l_tot_con.
  DATA: BEGIN OF lt_uname OCCURS 0,
          bname     LIKE /psyng/bc_uidn-bname,
          name_text LIKE /psyng/bc_uidn-name_text,
          class     LIKE /psyng/bc_uidn-class,
        END OF lt_uname.

  DATA: lt_confl LIKE STANDARD TABLE OF /psyng/conflict INITIAL SIZE 0
        WITH HEADER LINE.

  p_class = usr02-class.
  g_flag_usr_grp_det = abap_true.
*select the user from user group
  SELECT bname class                       "#EC CI_SEL_NESTED
  FROM usr02
  INTO TABLE gt_grp_usr
  WHERE class = p_class.
**select the user
  LOOP AT gt_grp_usr.
    LOOP AT  gt_syscandt2 WHERE  bname = gt_grp_usr-bname.
      lt_syscandt1-bname = gt_syscandt2-bname.
      lt_syscandt1-conid = gt_syscandt2-conid.
      lt_syscandt1-vrsio = gt_syscandt2-vrsio.
      lt_syscandt1-scandate = gt_syscandt2-scandate.
      APPEND lt_syscandt1.
    ENDLOOP.
  ENDLOOP.
  SELECT imp conid vrsio                    "#EC CI_SEL_NESTED
  FROM /psyng/conflict
  INTO CORRESPONDING FIELDS OF TABLE lt_confl
  WHERE vrsio = sodvrsio.

  LOOP AT lt_syscandt1.
    READ TABLE lt_confl WITH KEY conid = lt_syscandt1-conid vrsio =
    lt_syscandt1-vrsio.
    IF sy-subrc = 0.
      gt_user_gp_info-bname = lt_syscandt1-bname.
      gt_user_gp_info-conid = lt_syscandt1-conid.
      gt_user_gp_info-imp = lt_confl-imp.
      APPEND gt_user_gp_info.
    ENDIF.
  ENDLOOP.

  SELECT bname name_text class               "#EC CI_SEL_NESTED
  FROM /psyng/bc_uidn
  INTO TABLE lt_uname
  WHERE class = p_class.

  LOOP AT gt_user_gp_info.
    READ TABLE lt_uname WITH KEY bname = gt_user_gp_info-bname.
    IF sy-subrc = 0.
      gt_user_gp_info-name = lt_uname-name_text.
      MODIFY gt_user_gp_info TRANSPORTING name.
    ENDIF.
  ENDLOOP.

  LOOP AT gt_user_gp_info WHERE imp = gc_high.
    gt_user_gp_hi = gt_user_gp_info.
    APPEND gt_user_gp_hi.
  ENDLOOP.
  SORT gt_user_gp_hi BY bname.

  LOOP AT gt_user_gp_info WHERE imp = gc_medium.
    gt_user_gp_med = gt_user_gp_info.
    APPEND gt_user_gp_med.
  ENDLOOP.
  SORT gt_user_gp_med BY bname.

  LOOP AT gt_user_gp_info WHERE imp = gc_low.
    gt_user_gp_low = gt_user_gp_info.
    APPEND gt_user_gp_low.
  ENDLOOP.
  SORT gt_user_gp_low BY bname.

  LOOP AT gt_user_gp_info WHERE imp = gc_critical.
    gt_user_gp_crit = gt_user_gp_info.
    APPEND gt_user_gp_crit.
  ENDLOOP.
  SORT gt_user_gp_crit BY bname.


  LOOP AT gt_user_gp_info.
    gt_user_gp_con-conid = gt_user_gp_info-conid.
    gt_user_gp_con-imp = gt_user_gp_info-imp.
    APPEND gt_user_gp_con.
  ENDLOOP.
  SORT gt_user_gp_con BY conid.


  l_b_key = 1.
  PERFORM fill_data_tab_for_graph USING l_b_key.

ENDFORM.                    " USER_GROUP_DETAILS
*&---------------------------------------------------------------------*
*&      Module  STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS space.
  SET TITLEBAR 'TITLE'.

ENDMODULE.                 " STATUS_0100  OUTPUT
*&---------------------------------------------------------------------*
*&      Form  SUMMARY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM summary.

  DATA: l_cunt TYPE i.

  SORT: gt_grp_usr BY bname,
        gt_user_gp_info BY bname,
        gt_user_gp_hi BY bname,
        gt_user_gp_med BY bname,
        gt_user_gp_low BY bname.

*  COUNT NO OF USER OF THAT GRP
  LOOP AT gt_grp_usr.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'Total Users'(108).
  gt_data-value = l_cunt.
  APPEND gt_data.
  CLEAR l_cunt.

*COUNT TOTAL USER WITH CONF.
  LOOP AT  gt_user_gp_info.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'With at least 1 Conflict'(109).
  gt_data-value = l_cunt.
  APPEND gt_data.
  CLEAR l_cunt.


  LOOP AT gt_user_gp_crit.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'With Critical Conflicts'(128).
  gt_data-value = l_cunt.
  APPEND gt_data.
  g_tot_crit_con = l_cunt.
  CLEAR l_cunt.

  LOOP AT gt_user_gp_hi.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'With High Conflicts'(110).
  gt_data-value = l_cunt.
  APPEND gt_data.
  g_tot_hg_con = l_cunt.
  CLEAR l_cunt.

  LOOP AT gt_user_gp_med.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'With Medium Conflicts'(111).
  gt_data-value = l_cunt.
  APPEND gt_data.
  g_tot_mid_con = l_cunt.
  CLEAR l_cunt.

  LOOP AT gt_user_gp_low.
    AT END OF bname.
      l_cunt = l_cunt + 1.
    ENDAT.
  ENDLOOP.
  gt_data-text = 'With Low Conflicts'(112).
  gt_data-value = l_cunt.
  APPEND gt_data.
  g_tot_low_con = l_cunt.
  CLEAR l_cunt.

ENDFORM.                    " SUMMARY
*&---------------------------------------------------------------------*
*&      Form  crit_con
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM crit_con.
  DATA: l_cnt   TYPE i,
        l_user  TYPE string,
        l_usrid LIKE usr02-bname,
        l_t_ur  TYPE i.
  REFRESH: gt_nouser,gt_data.
  gt_data-text = 'Total Users with Critical'(129).
  gt_data-value =  g_tot_crit_con.
  APPEND gt_data.
  LOOP AT gt_user_gp_crit.
    l_cnt = l_cnt + 1.
    l_user = gt_user_gp_crit-name.
    l_usrid = gt_user_gp_crit-bname.
    CONCATENATE l_user gc_open_bracket l_usrid gc_close_bracket
                INTO l_user SEPARATED BY space.

    AT END OF bname.
      l_t_ur = l_t_ur + 1.
      gt_nouser-name =  l_user.
      gt_nouser-count = l_cnt.
      APPEND gt_nouser.
      CLEAR: l_cnt,l_user,l_usrid.
    ENDAT.
  ENDLOOP.
  SORT gt_nouser BY count DESCENDING.
  LOOP AT gt_nouser.
    IF sy-tabix <= 30.
      gt_data-text = gt_nouser-name.
      gt_data-value = gt_nouser-count.
      APPEND gt_data.
    ENDIF.
  ENDLOOP.

  g_t_usr_c = l_t_ur.
ENDFORM.                    " high_con

*&---------------------------------------------------------------------*
*&      Form  high_con
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM high_con.
  DATA: l_cnt   TYPE i,
        l_user  TYPE string,
        l_usrid LIKE usr02-bname,
        l_t_ur  TYPE i.
  REFRESH: gt_nouser,gt_data.
  gt_data-text = 'Total Users with High'(113).
  gt_data-value =  g_tot_hg_con.
  APPEND gt_data.
  LOOP AT gt_user_gp_hi.
    l_cnt = l_cnt + 1.
    l_user = gt_user_gp_hi-name.
    l_usrid = gt_user_gp_hi-bname.
    CONCATENATE l_user gc_open_bracket l_usrid gc_close_bracket
                INTO l_user SEPARATED BY space.

    AT END OF bname.
      l_t_ur = l_t_ur + 1.
      gt_nouser-name =  l_user.
      gt_nouser-count = l_cnt.
      APPEND gt_nouser.
      CLEAR: l_cnt,l_user,l_usrid.
    ENDAT.
  ENDLOOP.
  SORT gt_nouser BY count DESCENDING.
  LOOP AT gt_nouser.
    IF sy-tabix <= 30.
      gt_data-text = gt_nouser-name.
      gt_data-value = gt_nouser-count.
      APPEND gt_data.
    ENDIF.
  ENDLOOP.

  g_t_usr_h = l_t_ur.
ENDFORM.                    " high_con
*&---------------------------------------------------------------------*
*&      Form  Medium_con
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM medium_con.
  DATA: l_cnt   TYPE i,
        l_user  TYPE string,
        l_usrid LIKE usr02-bname,
        l_t_ur  TYPE i.
  REFRESH: gt_nouser,gt_data.
  gt_data-text = 'Total Users with Medium'(115).
  gt_data-value =  g_tot_mid_con.
  APPEND gt_data.
  LOOP AT gt_user_gp_med.
    l_cnt = l_cnt + 1.
    l_user = gt_user_gp_med-name.
    l_usrid = gt_user_gp_med-bname.
    CONCATENATE l_user gc_open_bracket l_usrid gc_close_bracket INTO
                l_user SEPARATED BY space.
    AT END OF bname.
      l_t_ur = l_t_ur + 1.
      gt_nouser-name =  l_user.
      gt_nouser-count = l_cnt.
      APPEND gt_nouser.
      CLEAR: l_cnt,l_user,l_usrid.
    ENDAT.
  ENDLOOP.
  SORT gt_nouser BY count DESCENDING.
  LOOP AT gt_nouser.
    IF sy-tabix <= 30.
      gt_data-text = gt_nouser-name.
      gt_data-value = gt_nouser-count.
      APPEND gt_data.
    ENDIF.
  ENDLOOP.
  g_t_usr_m = l_t_ur.
ENDFORM.                    " Medium_con
*&---------------------------------------------------------------------*
*&      Form  LOW_con
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM low_con.

  DATA: l_cnt   TYPE i,
        l_user  TYPE string,
        l_usrid LIKE usr02-bname,
        l_t_ur  TYPE i.
  REFRESH: gt_nouser,gt_data.
  gt_data-text = 'Total Users with Low'(117).
  gt_data-value =  g_tot_low_con.
  APPEND gt_data.
  LOOP AT gt_user_gp_low.
    l_cnt = l_cnt + 1.
    l_user = gt_user_gp_low-name.
    l_usrid = gt_user_gp_low-bname.
    CONCATENATE l_user gc_open_bracket l_usrid gc_close_bracket
                INTO l_user SEPARATED BY space.
    AT END OF bname.
      l_t_ur = l_t_ur + 1.
      gt_nouser-name =  l_user.
      gt_nouser-count = l_cnt.
      APPEND gt_nouser.
      CLEAR: l_cnt,l_user,l_usrid.
    ENDAT.
  ENDLOOP.
  SORT gt_nouser BY count DESCENDING.
  LOOP AT gt_nouser.
    IF sy-tabix <= 30.
      gt_data-text = gt_nouser-name.
      gt_data-value = gt_nouser-count.
      APPEND gt_data.
    ENDIF.
  ENDLOOP.
  g_t_usr_l = l_t_ur.
ENDFORM.                    " LOW_con
*&---------------------------------------------------------------------*
*&      Form  by_conid
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM by_conid.
  DATA: l_cnt      TYPE i,
        l_tot_con1 TYPE i,
        l_imp      TYPE string,
        l_con_id   LIKE /psyng/conflict-conid.

  DATA : lt_data_tmp LIKE TABLE OF gt_data WITH HEADER LINE.

  CONSTANTS : lc_high(5)   TYPE c VALUE 'HIGH-',
              lc_low(4)    TYPE c VALUE 'LOW-',
              lc_medium(7) TYPE c VALUE 'MEDIUM-',
              lc_aaaa(5)   TYPE c VALUE 'AAAA-',
              lc_bbbbbb(7) TYPE c VALUE 'BBBBBB-',
              lc_ccc(4)    TYPE c VALUE 'CCC-'.
  REFRESH: gt_nouser, gt_data,
           gt_nouser[], gt_data[].

*dhorions : collect is clearer and more performant
*start insert
  LOOP AT gt_user_gp_con.
    CONCATENATE
      gt_user_gp_con-imp abap_undefined gt_user_gp_con-conid
      INTO l_imp.
    gt_nouser-name = l_imp.
    gt_nouser-count = 1.
    COLLECT gt_nouser.
  ENDLOOP.
*end insert

  SORT gt_nouser BY  count DESCENDING.
  LOOP AT gt_nouser.
    IF sy-tabix <= 30.
*     dhorions = to do sorting by IMP
*      we need to have something sortable
      lt_data_tmp-text = gt_nouser-name.
      REPLACE lc_high    WITH lc_aaaa   INTO lt_data_tmp-text.
      REPLACE lc_medium  WITH lc_bbbbbb INTO lt_data_tmp-text.
      REPLACE lc_low     WITH lc_ccc    INTO lt_data_tmp-text.
      lt_data_tmp-value = gt_nouser-count.
      APPEND lt_data_tmp.
    ENDIF.
  ENDLOOP.
  SORT lt_data_tmp BY text(3) ASCENDING value DESCENDING.
  DATA : l_tabix LIKE sy-tabix.
  LOOP AT lt_data_tmp.
    l_tabix = sy-tabix.
*     dhorions : change sortable imp with actual text
    REPLACE lc_aaaa    WITH lc_high   INTO lt_data_tmp-text.
    REPLACE lc_bbbbbb  WITH lc_medium INTO lt_data_tmp-text.
    REPLACE lc_ccc     WITH lc_low    INTO lt_data_tmp-text.
    gt_data = lt_data_tmp.
    APPEND gt_data.
  ENDLOOP.

  CLEAR : l_tot_con1,l_tot_con.
  LOOP AT gt_user_gp_con.
    l_tot_con1 = l_tot_con1 + 1.
  ENDLOOP.
  l_tot_con =  l_tot_con1.


ENDFORM.                    " by_conid
*&---------------------------------------------------------------------*
*&      Form  DATA_CNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM data_cnt.
  CLEAR: g_cnt.
  LOOP AT gt_data.
    g_cnt = g_cnt + 1.
  ENDLOOP.

ENDFORM.                    " DATA_CNT
*&---------------------------------------------------------------------*
*&      Form  do_sod_analysis
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM do_sod_analysis .
  CONSTANTS : lc_sodvrsio TYPE rsparams-selname VALUE 'SODVRSIO',
              lc_pclass   TYPE rsparams-selname VALUE 'PCLASS',
              lc_csens    TYPE rsparams-selname VALUE 'CSENS',
              lc_critical TYPE rsparams-low     VALUE 'CRITICAL',
              lc_high     TYPE rsparams-low     VALUE 'HIGH',
              lc_medium   TYPE rsparams-low     VALUE 'MEDIUM',
              lc_low      TYPE rsparams-low     VALUE 'LOW',
              lc_p        TYPE rsparams-kind    VALUE 'P',
              lc_s        TYPE rsparams-kind    VALUE 'S',
              lc_i        TYPE rsparams-sign    VALUE 'I',
              lc_eq       TYPE rsparams-option  VALUE 'EQ'.

  DATA:  iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  CLEAR:   iseltab.
  REFRESH: iseltab, iseltab[].

  iseltab-selname = lc_sodvrsio.    "set version
  iseltab-kind    = lc_p.
  iseltab-sign    = lc_i.
  iseltab-option  = lc_eq.
  iseltab-low     = sodvrsio.
  APPEND iseltab.
  iseltab-selname = lc_pclass.    "set version
  iseltab-kind    = lc_s.
  iseltab-sign    = lc_i.
  iseltab-option  = lc_eq.
  iseltab-low     = usr02-class.
  APPEND iseltab.
* limit by sensitivity
  CASE g_prev_button.
    WHEN 2."CRITICAL
      iseltab-selname = lc_csens.    "set version
      iseltab-kind    = lc_s.
      iseltab-sign    = lc_i.
      iseltab-option  = lc_eq.
      iseltab-low     = lc_critical.
      APPEND iseltab.

    WHEN 3."HIGH
      iseltab-selname = lc_csens.    "set version
      iseltab-kind    = lc_s.
      iseltab-sign    = lc_i.
      iseltab-option  = lc_eq.
      iseltab-low     = lc_high.
      APPEND iseltab.

    WHEN 4."MEDIUM
      iseltab-selname = lc_csens.    "set version
      iseltab-kind    = lc_s.
      iseltab-sign    = lc_i.
      iseltab-option  = lc_eq.
      iseltab-low     = lc_medium.
      APPEND iseltab.

    WHEN 5."LOW
      iseltab-selname = lc_csens.    "set version
      iseltab-kind    = lc_s.
      iseltab-sign    = lc_i.
      iseltab-option  = lc_eq.
      iseltab-low     = lc_low.
      APPEND iseltab.
    WHEN OTHERS."All

  ENDCASE.

  SUBMIT /psyng/sodreport_sys_wide_org
  WITH SELECTION-TABLE iseltab AND RETURN.

ENDFORM.                    " do_sod_analysis
*---------------------------------------------------------------------*
*       FORM check_rpoug_auth                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  IS_UINFO                                                      *
*  -->  I_VRSIO                                                       *
*  -->  EF_REJECT                                                     *
*---------------------------------------------------------------------*
FORM check_rpoug_auth USING    is_uinfo TYPE /psyng/sw_uinfo
                               i_vrsio  TYPE /psyng/sodvrsio
                      CHANGING ef_reject TYPE flag.

  CONSTANTS : lc_ysw_rpoug TYPE tstca-objct VALUE 'Y&SW_RPOUG',
              lc_ysw_vrsio TYPE tstca-field VALUE 'Y&SW_VRSIO',
              lc_ysw_comp  TYPE tstca-field VALUE 'Y&SW_COMP',
              lc_class     TYPE tstca-field VALUE 'CLASS'.

  TYPES : BEGIN OF typ_rpoug ,
            vrsio    TYPE /psyng/sodvrsio,
            class    TYPE xuclass,
            company  TYPE char20,
            rejected TYPE flag,
          END OF typ_rpoug.
  STATICS : lt_rpoug TYPE HASHED TABLE OF   typ_rpoug WITH UNIQUE KEY
   vrsio class company WITH HEADER LINE.

  READ TABLE lt_rpoug WITH TABLE KEY vrsio = i_vrsio
                                     class = is_uinfo-class
                                     company = is_uinfo-company.
  IF sy-subrc = 0.
    ef_reject =  lt_rpoug-rejected.
  ELSE.
    lt_rpoug-vrsio = i_vrsio.
    lt_rpoug-class = is_uinfo-class.
    lt_rpoug-company = is_uinfo-company.
    IF NOT is_uinfo-class IS INITIAL AND
       NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT lc_ysw_rpoug
           ID lc_class FIELD is_uinfo-class
           ID lc_ysw_vrsio  FIELD i_vrsio
           ID lc_ysw_comp   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = abap_true.
      ENDIF.
    ELSEIF NOT is_uinfo-class IS INITIAL.
      AUTHORITY-CHECK OBJECT lc_ysw_rpoug
           ID lc_class FIELD is_uinfo-class
           ID lc_ysw_vrsio  FIELD i_vrsio
           ID lc_ysw_comp FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        lt_rpoug-rejected = abap_true.
      ENDIF.
    ELSEIF NOT is_uinfo-company IS INITIAL.
      AUTHORITY-CHECK OBJECT lc_ysw_rpoug
           ID lc_class FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID lc_ysw_vrsio  FIELD i_vrsio
           ID lc_ysw_comp   FIELD is_uinfo-company.
      IF sy-subrc <> 0.
        lt_rpoug-rejected = abap_true.
      ENDIF.
    ENDIF.
    ef_reject =  lt_rpoug-rejected.
    INSERT TABLE lt_rpoug.
  ENDIF.
  CLEAR lt_rpoug.

ENDFORM.                    " check_rpoug_auth

*&---------------------------------------------------------------------*
*&      Form  SW_PF_STATUS_Overall
*&---------------------------------------------------------------------*
*       PF_Status
*----------------------------------------------------------------------*

FORM pf_status USING lt_extab TYPE slis_t_extab.

  DATA: lw_extab TYPE slis_extab.

  IF g_group_detail_pf_status_flag IS INITIAL.
    IF gf_use_erp NE abap_true.
      lw_extab-fcode = gc_per_area.
      APPEND lw_extab TO lt_extab.
      CLEAR lw_extab.
      SET PF-STATUS gc_graf EXCLUDING lt_extab.
    ELSE.
      SET PF-STATUS gc_graf EXCLUDING lt_extab.
    ENDIF.
  ELSE.
    SET PF-STATUS gc_group_dtls EXCLUDING lt_extab.
  ENDIF.
  REFRESH lt_extab[].
ENDFORM.
*---------------------------------------------------------------------*
*       FORM user_double_click                                        *
*---------------------------------------------------------------------*
*       User Command                                                  *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_command USING r_ucomm LIKE sy-ucomm
                        rs_selfield TYPE slis_selfield.

  CASE sy-ucomm.
    WHEN gc_app_area.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM byapplicationarea.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Application Area'(023).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_conflict.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM byconflict.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'By Conflict'(004).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_sensitvity.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM bysensitivity.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'By Sensitivity'(005).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_user_group.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM byusergrp.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'By User Group'(006).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_grp_dtls.
      REFRESH gt_data[].
      CLEAR gt_data.
      g_flag_usr_grp_det = abap_true.

      CALL SCREEN 100 STARTING AT 40 10 .
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Summary'(102).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_usr_wi_mos.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM byuserid.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'By Users with Most'(007).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_per_area.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM bypersa.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'By Personnel Area'(003).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_summary.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM summary.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Summary'(102).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_critical.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM crit_con.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Critical'(130).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_high.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM high_con.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'High'(103).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_medium.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM medium_con.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Medium'(104).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_low.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM low_con.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Low'(105).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_conflicts.
      REFRESH gt_data[].
      PERFORM by_conid.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Conflicts'(106).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.

    WHEN gc_bac OR gc_canc.
      SET SCREEN 0.

    WHEN gc_exi.
      LEAVE PROGRAM.

    WHEN gc_bak.
      CLEAR g_group_detail_pf_status_flag.
      REFRESH gt_data[].
      CLEAR gt_data.
      PERFORM byapplicationarea.
      IF NOT gt_data[] IS INITIAL.
        PERFORM modify_fieldcat USING 'Application Area'(023).
        PERFORM alv_output USING  gt_data[].
        SET SCREEN 0.
      ENDIF.
  ENDCASE.

  IF gt_data[] IS INITIAL.
    MESSAGE i208(00) WITH 'No Data exist..!!!'(026).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  MODIFY_FIELDCAT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_TEXT  text
*----------------------------------------------------------------------*
FORM modify_fieldcat  USING l_text.
  gs_fieldcat-seltext_l = gs_fieldcat-seltext_m =
                          gs_fieldcat-reptext_ddic =
                          l_text.
  IF NOT gs_fieldcat-seltext_l IS INITIAL.
    MODIFY gt_fieldcat FROM gs_fieldcat
                          TRANSPORTING seltext_l seltext_m
                                       reptext_ddic
                          WHERE fieldname = gc_text.
  ENDIF.
*- Value
  CLEAR gs_fieldcat.
  gs_fieldcat-seltext_l = gs_fieldcat-seltext_m =
                          gs_fieldcat-seltext_s =
                          gs_fieldcat-reptext_ddic =
                          'Value'(024).
  gs_fieldcat-col_pos = 3.

  IF NOT gs_fieldcat-seltext_l IS INITIAL AND
     NOT gs_fieldcat-col_pos   IS INITIAL.

    MODIFY gt_fieldcat FROM gs_fieldcat
                          TRANSPORTING col_pos seltext_l seltext_m
                                       seltext_s reptext_ddic
                          WHERE fieldname = gc_value.
  ENDIF.
*- Description
  CLEAR gs_fieldcat.
  gs_fieldcat-seltext_l = gs_fieldcat-seltext_m =
                          gs_fieldcat-seltext_s =
                          gs_fieldcat-reptext_ddic =
                          'Description'(025).


  gs_fieldcat-col_pos = 2.
  IF sy-ucomm NE gc_app_area   AND
     sy-ucomm NE gc_conflict   AND
     sy-ucomm NE gc_user_group AND
     sy-ucomm NE gc_usr_wi_mos AND
     ( sy-ucomm NE gc_per_area OR g_tabname IS INITIAL ) AND
     g_first_display NE abap_true.


    gs_fieldcat-no_out = abap_true.

  ENDIF.

  IF NOT gs_fieldcat-seltext_l IS INITIAL AND
     NOT gs_fieldcat-col_pos   IS INITIAL.

    MODIFY gt_fieldcat FROM gs_fieldcat
                          TRANSPORTING col_pos seltext_l seltext_m
                                       seltext_s reptext_ddic no_out
                          WHERE fieldname = gc_desc.
    CLEAR: gs_fieldcat, g_first_display.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ALV_OUTPUT
*&---------------------------------------------------------------------*
*       ALV Output
*----------------------------------------------------------------------*
*      -->P_GT_BYBUSAREA2  text
*----------------------------------------------------------------------*
FORM alv_output  USING    gt_data LIKE gt_data[].

  gs_alv_layout-zebra = abap_true.
  gs_alv_layout-colwidth_optimize = abap_true.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = g_program
            i_callback_pf_status_set = gc_pf_status
            i_callback_user_command  = gc_user_command
            is_layout                = gs_alv_layout
            it_fieldcat              = gt_fieldcat
       TABLES
            t_outtab                 = gt_data[]
       EXCEPTIONS
            program_error            = 1
            OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                          WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BYUSERGRP
*&---------------------------------------------------------------------*
*      SOD By User Group
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM byusergrp .
  DATA: lt_usgrpt TYPE TABLE OF ty_usgrpt,
        lw_usgrpt TYPE ty_usgrpt.

  IF  gt_byusergrp[] IS INITIAL.
    SELECT: bname COUNT( * )                         "#EC CI_SEL_NESTED
                        FROM /psyng/syscandt
                        INTO (wa_byuserid-bname, wa_byuserid-count)
                        WHERE conid <> 'NONE' AND vrsio = sodvrsio
                        GROUP by bname.
      INSERT wa_byuserid INTO TABLE gt_byuserid.
    ENDSELECT.

    LOOP AT gt_byuserid. " WHERE bname = iusr02-bname.
      READ TABLE gt_usrgrp WITH TABLE KEY bname =
                                          gt_byuserid-bname.
      CHECK sy-subrc = 0.

      LOOP AT gt_byusergrp WHERE usergroup = gt_usrgrp-class.
        gt_byusergrp-usergroup = gt_usrgrp-class.
        gt_byusergrp-count = gt_byusergrp-count +
                             gt_byuserid-count.
        MODIFY gt_byusergrp.
      ENDLOOP.
      IF sy-subrc NE 0.
        gt_byusergrp-usergroup = gt_usrgrp-class.
        gt_byusergrp-count = gt_byusergrp-count +
                             gt_byuserid-count.
        APPEND gt_byusergrp.
      ENDIF.
      CLEAR: gt_byusergrp, gt_usrgrp.
    ENDLOOP.
  ENDIF.
  SORT gt_byusergrp BY count DESCENDING usergroup ASCENDING AS
  TEXT.
  DELETE ADJACENT DUPLICATES FROM gt_byusergrp.

  IF NOT gt_byusergrp[] IS INITIAL.
    DESCRIBE TABLE  gt_byusergrp[].
    IF sy-tfill GT 30.
      DELETE gt_byusergrp[] FROM 31 TO sy-tfill .
    ENDIF.
    IF NOT gt_byusergrp[] IS INITIAL.
      SELECT usergroup
             text
             INTO TABLE lt_usgrpt
             FROM usgrpt
             FOR ALL ENTRIES IN gt_byusergrp
             WHERE usergroup = gt_byusergrp-usergroup.
      IF sy-subrc = 0.
        SORT lt_usgrpt[] BY usergroup.
        DELETE ADJACENT DUPLICATES FROM lt_usgrpt[] COMPARING usergroup.
      ENDIF.
    ENDIF.
  ENDIF.

  LOOP AT gt_byusergrp.
    gt_data-text = gt_byusergrp-usergroup.
    gt_data-value = gt_byusergrp-count.
    READ TABLE lt_usgrpt INTO lw_usgrpt WITH KEY
                              usergroup = gt_byusergrp-usergroup
                              BINARY SEARCH.
    IF sy-subrc = 0.
      gt_data-desc = lw_usgrpt-text.
      CLEAR lw_usgrpt.
    ENDIF.
    APPEND gt_data.
  ENDLOOP.
  REFRESH lt_usgrpt[].
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BYAPPLICATIONAREA
*&---------------------------------------------------------------------*
*      SOD By Application Area
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM byapplicationarea.
  DATA : lt_busarea TYPE TABLE OF ty_busarea,
         lw_busarea TYPE ty_busarea.

  IF NOT gt_bybusarea2[] IS INITIAL.
    g_first_display = abap_true.
    DESCRIBE TABLE  gt_bybusarea2[].
    IF sy-tfill GT 30.
      DELETE gt_bybusarea2[] FROM 31 TO sy-tfill .
    ENDIF.
    IF NOT gt_bybusarea2[] IS INITIAL.
      SELECT busarea
             text
        INTO TABLE lt_busarea
        FROM /psyng/busarea
        FOR ALL ENTRIES IN gt_bybusarea2
        WHERE busarea = gt_bybusarea2-busarea.
      IF sy-subrc = 0.
        SORT lt_busarea[] BY busarea.
        DELETE ADJACENT DUPLICATES FROM lt_busarea[] COMPARING busarea.
      ENDIF.

      LOOP AT gt_bybusarea2.
        gt_data-text = gt_bybusarea2-busarea.
        gt_data-value = gt_bybusarea2-count.

        READ TABLE lt_busarea INTO lw_busarea
                             WITH KEY busarea = gt_bybusarea2-busarea
                              BINARY SEARCH.
        IF sy-subrc = 0.
          gt_data-desc = lw_busarea-text.
          CLEAR lw_busarea.
        ENDIF.
        APPEND gt_data.
      ENDLOOP.
      REFRESH lt_busarea[].
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BYCONFLICT
*&---------------------------------------------------------------------*
*      SOD By Conflict
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM byconflict .
  DATA :  lt_conflict TYPE TABLE OF ty_conflict,
          lw_conflict TYPE ty_conflict.
  IF NOT gt_byconflict2[] IS INITIAL.
    DESCRIBE TABLE  gt_byconflict2[].
    IF sy-tfill GT 30.
      DELETE gt_byconflict2[] FROM 31 TO sy-tfill .
    ENDIF.
    IF NOT gt_byconflict2[] IS INITIAL.
      SELECT conid
             description
        INTO TABLE lt_conflict
        FROM /psyng/conflict
        FOR ALL ENTRIES IN gt_byconflict2
        WHERE conid = gt_byconflict2-conid.
      IF sy-subrc = 0.
        SORT lt_conflict[] BY conid.
        DELETE ADJACENT DUPLICATES FROM lt_conflict[] COMPARING conid.
      ENDIF.

      LOOP AT gt_byconflict2.
        gt_data-text = gt_byconflict2-conid.
        gt_data-value = gt_byconflict2-count.
        READ TABLE lt_conflict INTO lw_conflict
                               WITH  KEY conid = gt_byconflict2-conid
                               BINARY SEARCH.

        IF sy-subrc = 0.
          gt_data-desc =  lw_conflict-description.
          CLEAR lw_conflict.
        ENDIF.
        APPEND gt_data.
      ENDLOOP.
      REFRESH lt_conflict[].
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BYSENSITIVITY
*&---------------------------------------------------------------------*
*      SOD By Sensitivity
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bysensitivity .
  LOOP AT gt_bysens.
    IF sy-tabix <= 30.
      gt_data-text = gt_bysens-imp.
      gt_data-value = gt_bysens-count.
      APPEND gt_data.
    ELSE.
      EXIT.
    ENDIF.
  ENDLOOP.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  BYUSERID
*&---------------------------------------------------------------------*
*      SOD By User ID
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM byuserid .
  DATA: lw_username  TYPE /psyng/bc_userid_name,
        lw_byuserid2 LIKE gt_byuserid2.

  IF NOT gt_byuserid2[] IS INITIAL.
    DESCRIBE TABLE  gt_byuserid2[].
    IF sy-tfill GT 30.
      DELETE gt_byuserid2[] FROM 31 TO sy-tfill .
    ENDIF.
    IF NOT gt_byuserid2[] IS INITIAL.
      LOOP AT gt_byuserid2 INTO lw_byuserid2.
        lw_username-bname = lw_byuserid2-bname.
        APPEND lw_username TO gt_username[].
        CLEAR: lw_byuserid2,  lw_username.
      ENDLOOP.

      CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
           EXPORTING
                no_email = abap_true
           TABLES
                username = gt_username[].

      IF NOT gt_username[] IS INITIAL.
        SORT gt_username[] BY bname.
        DELETE ADJACENT DUPLICATES FROM gt_username[] COMPARING bname.
      ENDIF.
    ENDIF.

    LOOP AT gt_byuserid2.
      gt_data-text = gt_byuserid2-bname.
      gt_data-value = gt_byuserid2-count.
      READ TABLE gt_username INTO lw_username
                              WITH  KEY bname = gt_byuserid2-bname
                              BINARY SEARCH.

      IF sy-subrc = 0.
        gt_data-desc =  lw_username-name_full.
        CLEAR lw_username.
      ENDIF.
      APPEND gt_data.
    ENDLOOP.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  bypersa
*&---------------------------------------------------------------------*
*       SOD By Personnel Area
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bypersa.
  DATA: lt_t500p TYPE TABLE OF ty_t500p,
        lw_t500p TYPE ty_t500p.
  IF NOT gt_bypersa[] IS INITIAL AND NOT g_tabname IS INITIAL.
    DESCRIBE TABLE  gt_bypersa[].
    IF sy-tfill GT 30.
      DELETE gt_bypersa[] FROM 31 TO sy-tfill .
    ENDIF.
    IF NOT gt_bypersa[] IS INITIAL.

      SELECT persa
             name1
             FROM (g_tabname)
             INTO TABLE lt_t500p
             FOR ALL ENTRIES IN gt_bypersa
             WHERE persa = gt_bypersa-werks. "#EC SAST_CI_GEN_CHECK
*HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)

      IF sy-subrc = 0.
        SORT lt_t500p[] BY persa.
        DELETE ADJACENT DUPLICATES FROM lt_t500p[] COMPARING persa.
      ENDIF.
    ENDIF.
    LOOP AT gt_bypersa.
      READ TABLE lt_t500p INTO lw_t500p WITH KEY
                                             persa = gt_bypersa-werks
                                             BINARY SEARCH.
      IF sy-subrc = 0.
        gt_data-desc = lw_t500p-name1.
        CLEAR lw_t500p.
      ENDIF.
      gt_data-text = gt_bypersa-werks.
      gt_data-value = gt_bypersa-count.
      APPEND gt_data.
    ENDLOOP.
  ENDIF.
  REFRESH lt_t500p[].
ENDFORM.                    " bypersa
*&---------------------------------------------------------------------*
*&      Form  BYCOUNT
*&---------------------------------------------------------------------*
*       COUNT
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM bycount .
  g_program = sy-repid.
*- Close ALL Graphic windows
  CALL FUNCTION 'GRAPH_DIALOG'
       EXPORTING
            close = abap_true.

  g_count_result_flag = abap_true.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name         = g_program
            i_internal_tabname     = gc_gt_data
            i_inclname             = g_program
       CHANGING
            ct_fieldcat            = gt_fieldcat
       EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2
            OTHERS                 = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  PERFORM byapplicationarea.
  IF NOT gt_data[] IS INITIAL.
    PERFORM modify_fieldcat USING 'Application Area'(023).
    PERFORM alv_output USING gt_data[].
  ELSE.
    MESSAGE i208(00) WITH 'No Data exist..!!!'(026).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
