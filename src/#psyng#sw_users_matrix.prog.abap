*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_USERS_MATRIX
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*----------------------------------------------------------------------*
REPORT /psyng/sw_users_matrix MESSAGE-ID /psyng/basis.
INCLUDE /psyng/basis_exelog.
INCLUDE /psyng/sw_config.
TYPE-POOLS : abap, slis,sscr, icon.
TYPES: BEGIN OF ty_function,
         function    TYPE /psyng/function_id,
         description TYPE /psyng/fundsc,
       END OF ty_function.
TYPES: BEGIN OF ty_pivot_raw,
         conid   TYPE /psyng/conflict_id, "Conflict
         cdescr  TYPE /psyng/rskdsc,      "Conflict Description
         funid   TYPE /psyng/function_id, "Function
         fdescr  TYPE /psyng/fundsc,      "Function Description
         tcode   TYPE tcode,              "Transaction
         userid  TYPE xubname,            "User
         udescr  TYPE ad_namtext,         "Full Name of Person
         usergrp TYPE xuclass,            "User Grp
         company TYPE bukrs,              "Company Code
         depart  TYPE text40,             "Department
         ecount  TYPE int4,
      "Execution Count
       END OF ty_pivot_raw.
TABLES: sscrfields, usr10.
TABLES: agr_define, agr_users, usr02, tstct, ust04, rfcdes.
TABLES: /psyng/conflict, /psyng/function, /psyng/sw_uinfo,
/psyng/swresusr.
DATA:
  gt_confdet       TYPE TABLE OF  /psyng/confdet WITH HEADER LINE,
  gt_summary       TYPE TABLE OF /psyng/bc_uh_summary WITH HEADER LINE,
  gt_userconflicts TYPE TABLE OF /psyng/sw_sod_output_org WITH HEADER
  LINE,
  gt_exe           TYPE TABLE OF /psyng/user_role_tcode_exe WITH HEADER
  LINE,
  gt_lexe          TYPE TABLE OF /psyng/user_role_exe WITH HEADER LINE,
  gt_conflict      TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
  gs_conflict      LIKE LINE OF gt_conflict,
  gt_function      TYPE STANDARD TABLE OF ty_function,
  gs_function      LIKE LINE OF gt_function,
  gt_pivot_raw     TYPE STANDARD TABLE OF ty_pivot_raw,
  gs_pivot_raw     LIKE LINE OF gt_pivot_raw,
  gt_users         TYPE TABLE OF usr02,
  gs_users         LIKE LINE OF gt_users,
  BEGIN OF gt_functtran OCCURS 0,
    mandt	     TYPE mandt,
    functionid TYPE /psyng/function_id,
    tcode	     TYPE tcode,
    vrsio	     TYPE /psyng/sodvrsio,
    type       TYPE /psyng/tcodetype,
    fioriid	   TYPE /psyng/sw_fioriid,
  END OF gt_functtran,
  gv_uname            TYPE syuname,
  gv_label            TYPE smp_dyntxt,
  gr_table            TYPE REF TO data,
  gr_rec              TYPE REF TO data,
  gr_raw              TYPE REF TO data,
  gs_swconfig         TYPE /psyng/swconfig,
  gv_description      TYPE /psyng/function-description,
  gt_fieldcat_alv     TYPE slis_t_fieldcat_alv,
  gs_fieldcat_alv     TYPE slis_fieldcat_alv,
  gt_fieldcat_raw     TYPE slis_t_fieldcat_alv,
  gs_fieldcat_raw     TYPE slis_fieldcat_alv,
  gs_layout           TYPE slis_layout_alv,
  gs_color            TYPE lvc_s_scol,
  gf_se_installed     TYPE flag,
  gf_se_version       TYPE /psyng/prog_vrsio,
  gf_ta_installed     TYPE flag,
  gf_ta_version       TYPE /psyng/prog_vrsio,
  gt_role_users       TYPE TABLE OF /psyng/sw_sel_opts_xubname WITH
  HEADER LINE,
  gs_return           TYPE bapireturn,
  gv_program          LIKE sy-repid,
* l_idx               TYPE sy-tabix,
  gt_sort             TYPE slis_t_sortinfo_alv,
  gs_sort             TYPE slis_sortinfo_alv,
  gs_usrhis_or_usrsod TYPE flag.

DATA: BEGIN OF 1stoutput OCCURS 10.            "Table to output 1st
DATA: sel(1)        TYPE c,           "selected row by user in ALV grid
      class         LIKE usr02-class,
      company       LIKE /psyng/sw_uinfo-company,
      compshort     LIKE /psyng/sw_uinfo-company,
      department    LIKE /psyng/sw_uinfo-department,
      central_uid   LIKE /psyng/sw_uinfo-central_uid,
      ustyp         LIKE usr02-ustyp,
      bname         LIKE ust04-bname,
      name_text     LIKE adrp-name_text,
      conid         LIKE /psyng/conflict-conid,
      description   LIKE /psyng/conflict-description,
      imp           LIKE /psyng/1stoutput_u-imp,
      impsort       TYPE n,
      contid        LIKE /psyng/1stoutput_u-contid,
      inactive      LIKE /psyng/mchdr-inactive,
      auditor       LIKE /psyng/mcuser-auditor,
      from_date     LIKE /psyng/mcuser-from_date,
      to_date       LIKE /psyng/mcuser-to_date,
      mit_icon      LIKE icon-id,
      enhanced      TYPE c, "flag for enhanced ruleset
      simu          TYPE c, "flag for simulated conflict
      er            TYPE c, "flag for ER conflict
      origin(12)    TYPE c, "LOCAL/REMOTE/CROSS
      level2        TYPE c,
      level3        TYPE c,
      level4        TYPE c,
      simu_after    TYPE c,
      simu_before   TYPE c,
      abb           LIKE /psyng/sw_sod_output_org-org_abb,
      color_line(4) TYPE c,           " Line color
      color_cell    TYPE lvc_t_scol.  " Cell color
DATA: END OF 1stoutput.

FIELD-SYMBOLS : <fs_tab>        TYPE STANDARD TABLE,
                <fs_raw>        TYPE STANDARD TABLE,
                <fs_rec>        TYPE agr_tcodes,
                <user>          TYPE usr02-bname,
                <fs_o>          TYPE any,
                <fs_r>          TYPE any,
                <fs_dynfield>   TYPE any,
                <fs_dynfield_h> TYPE any,
                <ta_color>      TYPE lvc_t_scol
                .
CONSTANTS :
  gc_fm_sw036 TYPE rs38l_fnam VALUE '/PSYNG/SW_036',
  gc_fm_sw028 TYPE rs38l_fnam VALUE '/PSYNG/SW_028',
  gc_fm_ta071 TYPE rs38l_fnam VALUE '/PSYNG/BC_USRHIS_071'.

DEFINE clean_username.
  while &1 cs '-'.
    replace '-' with '_' into &1.
  endwhile.
  while &1 cs '.'.
    replace '.' with '_' into &1.
  endwhile.
END-OF-DEFINITION.
DEFINE assign_value.
  assign component &1 of structure <fs_o> to <fs_dynfield>.
  <fs_dynfield> = &2.
  unassign <fs_dynfield>.
END-OF-DEFINITION.

RANGES : gr_roles FOR agr_define-agr_name,
         gr_conid FOR gt_userconflicts-conid,
         gr_tcode FOR sy-tcode,
         gr_users FOR usr02-bname.
DATA restrict TYPE sscr_restrict.
DATA : optlist TYPE sscr_opt_list,
       ass     TYPE sscr_ass,
       l_vrsn_flag type flag. "HBHALLA
DATA: usertype TYPE /psyng/xuustyp.


SELECTION-SCREEN: BEGIN OF BLOCK date_o WITH FRAME TITLE text-b01  .
SELECT-OPTIONS : s_dates FOR sy-datum.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  01(8) text-b13 USER-COMMAND m_but.
SELECTION-SCREEN PUSHBUTTON  10(8) text-b14 USER-COMMAND hy_but.
SELECTION-SCREEN PUSHBUTTON  19(8) text-b15 USER-COMMAND y_but.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK date_o .

SELECTION-SCREEN: BEGIN OF BLOCK con_o WITH FRAME TITLE text-b02.
PARAMETERS : p_vrsio TYPE /psyng/sodvrsio.
SELECT-OPTIONS: s_conid  FOR /psyng/conflict-conid.
SELECTION-SCREEN: END OF BLOCK con_o .

SELECTION-SCREEN: BEGIN OF BLOCK user_o WITH FRAME TITLE text-b03.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: s_users  FOR usr02-bname           MODIF ID usr,
                s_class  FOR usr02-class           MODIF ID usr,
                s_comp   FOR 1stoutput-company     MODIF ID usr,
                s_depart FOR 1stoutput-department  MODIF ID usr,
                s_cuid   FOR /psyng/sw_uinfo-central_uid
                                                   MODIF ID usr,
                s_kostl  FOR /psyng/swresusr-kostl    MODIF ID usr
               MATCHCODE OBJECT /psyng/kostl,
                s_role   FOR agr_define-agr_name   MODIF ID usr,
                s_prof   FOR ust04-profile           MODIF ID usr.
PARAMETERS: p_vldusr AS CHECKBOX DEFAULT abap_true MODIF ID usr
USER-COMMAND usr_fil.
SELECT-OPTIONS: s_utype  FOR usertype              MODIF ID usr.
SELECTION-SCREEN COMMENT /1(24) text-100. "MODIF ID usr.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: p_exlusr AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-102 MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN POSITION 1.
PARAMETERS: p_otvdat AS CHECKBOX DEFAULT ' '  MODIF ID usr.
SELECTION-SCREEN COMMENT 3(79) text-101 MODIF ID usr.
SELECTION-SCREEN END OF LINE.
PARAMETERS: p_hidusr AS CHECKBOX DEFAULT 'X' MODIF ID usr.
SELECTION-SCREEN: END OF BLOCK user_o.

*--Output Determination
SELECTION-SCREEN BEGIN OF BLOCK output_o WITH FRAME TITLE text-t01.
SELECTION-SCREEN BEGIN OF LINE.
PARAMETERS: p_alv RADIOBUTTON GROUP gp1 DEFAULT 'X'.
SELECTION-SCREEN COMMENT 4(30) text-001.
PARAMETERS: p_raw RADIOBUTTON GROUP gp1.
SELECTION-SCREEN COMMENT 38(30) text-002.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN END OF BLOCK output_o.

*--User type & valid user screen
PARAMETERS: p_remonl NO-DISPLAY.
"AS CHECKBOX USER-COMMAND remo MODIF ID rem.




*--Search Help for Department
AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-low.
  PERFORM f4_department USING 'S_DEPART-LOW' CHANGING s_depart-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_depart-high.
  PERFORM f4_department USING 'S_DEPART-HIGH' CHANGING s_depart-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-low.
  PERFORM f4_central_uid USING 'S_CUID-LOW' CHANGING s_cuid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-high.
  PERFORM f4_central_uid USING 'S_CUID-HIGH' CHANGING s_cuid-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-low.
  PERFORM f4_company USING 'S_COMP-LOW' CHANGING s_comp-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-high.
  PERFORM f4_company USING 'S_COMP-HIGH' CHANGING s_comp-high .



*----------------------------------------------------------------------*
*   Initializing the User Violation Matrix report                      *
*----------------------------------------------------------------------*
INITIALIZATION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024

*--Record customer execution steps.
  exelog sy-repid space.
  gv_uname = cl_abap_syst=>get_user_name( ).

*--Activate predefined function keys
  CLEAR gs_usrhis_or_usrsod.
  CLEAR gv_label.
  gv_label-icon_id   = icon_usergroup.
  gv_label-text      = 'SE: User Analysis drill down'(s00).
  gv_label-icon_text = 'SE: User Analysis drill down'(s00).
* sscrfields-functxt_01 = gv_label.


*--PERFORM define_restriction."Simplifies the handling of SELECT-OPTIONS
  CLEAR gs_usrhis_or_usrsod.
  gv_program = sy-repid.

*--Check if SE and TA are installed
  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'SE'
    IMPORTING
      e_installed      = gf_se_installed
      e_module_version = gf_se_version.

  CALL FUNCTION '/PSYNG/BASIS_GET_MODULES'
    EXPORTING
      i_module         = 'TA'
    IMPORTING
      e_installed      = gf_ta_installed
      e_module_version = gf_ta_version.

  IF NOT gf_se_installed = abap_true OR NOT gf_ta_installed = abap_true.
    MESSAGE e113 WITH 'Functionality only available if'(m00)
    'Modules SE and TA are installed'(m01).
  ENDIF.

*BOC: HBHALLA
clear l_vrsn_flag.
if gf_se_version CP '*Q*'.
  l_vrsn_flag = 'X'.
  endif.
  IF     gf_se_version < '3.1' and l_vrsn_flag is INITIAL.
    MESSAGE e017 WITH 'Separations Enforcer'(m02) 'SE' '3.1'
    'this system'(m03).
  ENDIF.
* END OF CHANGE: HBHALLA

  IF gf_ta_version < '2.4'.
    MESSAGE e017 WITH 'Transaction Archive'(m04) 'TA' '2.4'
    'this system'(m03).
  ENDIF.

  IF s_dates[] IS INITIAL.
    s_dates-sign   = 'I'.
    s_dates-option = 'BT'.
    s_dates-low    = sy-datum - 30.
    s_dates-high   = sy-datum.
    APPEND s_dates.
  ENDIF.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'M_BUT'.   "Monthly Button
      REFRESH s_dates.
      s_dates-sign   = 'I'.
      s_dates-option = 'BT'.
      s_dates-low    = sy-datum - 30.
      s_dates-high   = sy-datum.
      APPEND s_dates.
    WHEN 'HY_BUT'.  "Year/2 Button
      REFRESH s_dates.
      s_dates-sign   = 'I'.
      s_dates-option = 'BT'.
      s_dates-low    = sy-datum - ( 365 / 2 ).
      s_dates-high   = sy-datum.
      APPEND s_dates.
    WHEN 'Y_BUT'.   "Year Button
      REFRESH s_dates.
      s_dates-sign   = 'I'.
      s_dates-option = 'BT'.
      s_dates-low    = sy-datum - 365 .
      s_dates-high   = sy-datum.
      APPEND s_dates.
  ENDCASE.

  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.

AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    CASE screen-name.
      WHEN 'S_UTYPE-LOW' OR 'S_UTYPE-HIGH' OR 'P_EXLUSR' OR
         'P_OTVDAT'.
        IF p_vldusr = abap_true.
          p_exlusr = abap_true.
          p_otvdat = abap_true.
          PERFORM set_def_usrtype.
          screen-input = 0.
*         CLEAR p_flag.
        ELSE.
          PERFORM get_config_usr.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.



*----------------------------------------------------------------------*
*   Standard processing block of the User Violation Matrix             *
*----------------------------------------------------------------------*
START-OF-SELECTION.

*--Get all the sum total of users.
  CALL FUNCTION '/PSYNG/SW_041'
    EXPORTING
      i_validuser       = p_vldusr
      i_include_locked  = p_exlusr
      i_include_expired = p_otvdat
    TABLES
      et_users          = gt_users
      it_userlist       = s_users
      it_grouplist      = s_class
      it_usertype       = s_utype
      it_actgroups      = s_role
      it_profile        = s_prof
      it_costcenter     = s_kostl
      it_cuid           = s_cuid
      it_company        = s_comp
      it_department     = s_depart.
  IF gt_users[] IS INITIAL.
    MESSAGE s010 WITH 'No users found in date range'(m05) DISPLAY LIKE
    'I'.
    RETURN.
  ENDIF.

*--Rebuild the user range table.
  REFRESH s_users. CLEAR s_users.
  s_users-sign   = 'I'.
  s_users-option = 'EQ'.
  LOOP AT gt_users INTO gs_users.
    s_users-low = gs_users-bname.
    COLLECT s_users.
  ENDLOOP.

*--User Summary Analysis
  CALL FUNCTION '/PSYNG/SW_SOD_SCAN_FUNC'
    EXPORTING
      i_validuser       = p_vldusr
      i_outvdate        = abap_true
      i_analyze_sap_all = abap_true
      i_abap            = abap_true
      i_output          = abap_true
      i_exlckusr        = abap_true
      i_vrsio           = p_vrsio
    TABLES
      it_users          = s_users
      it_actgroups      = s_role
      it_usergroup      = s_class
      it_confs          = s_conid
      et_outputdet      = gt_userconflicts.
  IF gt_userconflicts[] IS INITIAL.
    MESSAGE s010 WITH 'No users found with conflicts'(m06) DISPLAY LIKE
    'I'.
    RETURN.
  ENDIF.

*--Remove users that have NO conflicks per checkbox.
  SORT gt_userconflicts BY bname.
  IF p_hidusr EQ abap_true.
    LOOP AT s_users.
      READ TABLE gt_userconflicts WITH KEY bname = s_users-low
                                                 BINARY SEARCH.
      IF sy-subrc NE 0.
        DELETE s_users WHERE low EQ s_users-low.
      ENDIF.
    ENDLOOP.
  ENDIF.
*--Collect the Conflicks
  gr_conid-sign   = 'I'.
  gr_conid-option = 'EQ'.
  LOOP AT gt_userconflicts.
    gr_conid-low = gt_userconflicts-conid.
    COLLECT gr_conid.
  ENDLOOP.
  IF gt_users[] IS INITIAL.
    MESSAGE s010 WITH 'No users found with conflicts'(m06) DISPLAY LIKE
    'I'.
    RETURN.
  ENDIF.

  CALL FUNCTION '/PSYNG/SW_028'
    EXPORTING
      i_vrsio      = p_vrsio
    TABLES
      it_spconfs   = gr_conid
      et_confdet   = gt_confdet
      et_conflict  = gt_conflict
      et_functtran = gt_functtran.
  PERFORM get_tcodes_from_objects.

*--Collect the relevant tcodes
  gr_tcode-sign   = 'I'.
  gr_tcode-option = 'EQ'.
  LOOP AT gt_functtran WHERE type EQ 'T'. "Tranactions.
    gr_tcode-low = gt_functtran-tcode.
    COLLECT gr_tcode.
  ENDLOOP.

*--Get all the Functional descriptions.
  IF gt_confdet[] IS NOT INITIAL.
    SELECT function description INTO TABLE gt_function FROM
    /psyng/function
                                         FOR ALL ENTRIES IN gt_confdet
                                                      WHERE function EQ
gt_confdet-functionid
                                                        AND vrsio    EQ
    p_vrsio.
  ENDIF.

*--Check if user executed Tcodes
  CALL FUNCTION '/PSYNG/BC_USRHIS_030'
    EXPORTING
      if_summarized_by = 'O'  "D
    TABLES
      it_users         = s_users
      it_date          = s_dates
      it_tcode         = gr_tcode
      et_summary       = gt_summary.
  IF gt_summary[] IS INITIAL.
    MESSAGE s010 WITH 'Users executes NO tcodes in date range'(m07)
    DISPLAY LIKE 'I'.
*    RETURN.
  ENDIF.

*--Get rid of tcodes in matrix but not in roles
  REFRESH gr_tcode.
  gr_tcode-sign   = 'I'.
  gr_tcode-option = 'EQ'.
  LOOP AT gt_summary WHERE ( account NE space ) OR ( tcode NE space ).
    gr_tcode-low = gt_summary-tcode.
    COLLECT gr_tcode.
  ENDLOOP.

  IF NOT gr_tcode[] IS INITIAL.
*--Om B16692  29.06.2022
*    REFRESH gt_functtran.
*  ELSE.
    DELETE gt_functtran WHERE NOT tcode IN gr_tcode.
  ENDIF.
  SORT gr_tcode.

*--Build the ALV table.
  PERFORM create_dynamic_table.
  SORT gt_userconflicts BY bname conid funid imp.
  SORT gt_summary BY account tcode.
  SORT gt_function BY function.
  LOOP AT gt_conflict.
    LOOP AT gt_confdet WHERE conid EQ gt_conflict-conid.
      LOOP AT gt_functtran WHERE functionid EQ gt_confdet-functionid.
        CHECK gt_functtran-tcode NP '/PSYNG/-*'.
        READ TABLE gt_function INTO gs_function WITH KEY function =
        gt_confdet-functionid
BINARY SEARCH.
        assign_value 'TCODE'  gt_functtran-tcode.
        assign_value 'CONID'  gt_confdet-conid.
        assign_value 'CDESCR' gt_conflict-description.
        assign_value 'FUNID'  gt_confdet-functionid.
        assign_value 'FDESCR' gs_function-description.
        assign_value 'IMP'    gt_conflict-imp.
        UNASSIGN <fs_dynfield>.
        ASSIGN COMPONENT  'COLORS' OF STRUCTURE <fs_o> TO <ta_color>.
        LOOP AT s_users.
          CLEAR gt_summary.
          gs_color-fname = s_users-low.
          clean_username gs_color-fname.
          READ TABLE gt_summary WITH KEY account = s_users-low
                                           tcode = gt_functtran-tcode
                                           BINARY SEARCH.
          IF sy-subrc EQ 0.
            assign_value gs_color-fname gt_summary-dlgrec.
          ENDIF.
          READ TABLE gt_userconflicts WITH KEY bname = s_users-low
                                               conid = gt_confdet-conid
                                               BINARY SEARCH.
          IF sy-subrc EQ 0.
            IF gt_summary-dlgrec > 0.
              gs_color-color-col = 6. "Red = used
              gs_color-color-int = 0.
            ELSE.
              gs_color-color-col = 5. "Green = not used
              gs_color-color-int = 0.
            ENDIF.
            APPEND gs_color TO <ta_color>.
            CLEAR gs_color.
          ENDIF.
        ENDLOOP.
        APPEND <fs_o> TO <fs_tab>.
        CLEAR <fs_o>.
      ENDLOOP.
    ENDLOOP.
  ENDLOOP.


*----------------------------------------------------------------------*
*   Standard end of processing block for the User Violation Matrix     *
*----------------------------------------------------------------------*
END-OF-SELECTION.

*--Output ALV grid for viewing
  CASE abap_true.
    WHEN p_alv.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          it_fieldcat              = gt_fieldcat_alv[]
          is_layout                = gs_layout
          i_callback_program       = gv_program
          i_callback_pf_status_set = 'SUB_PF_STATUS'
          i_callback_user_command  = 'CONFLICT_HOTSPOT'
          it_sort                  = gt_sort
        TABLES
          t_outtab                 = <fs_tab>
        EXCEPTIONS
          program_error            = 1
          OTHERS                   = 2.
      IF sy-subrc NE 0.
        IF sy-msgid NE space.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          MESSAGE s010 WITH 'Program error occurred in FM'(m10).
        ENDIF.
      ELSE.
        MESSAGE s010 WITH 'User Analysis Completed'(m09).
      ENDIF.

    WHEN p_raw.
      PERFORM build_raw_data_table.
      CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
        EXPORTING
          it_fieldcat        = gt_fieldcat_raw[]
          is_layout          = gs_layout
          i_callback_program = gv_program
        TABLES
          t_outtab           = gt_pivot_raw
        EXCEPTIONS
          program_error      = 1
          OTHERS             = 2.
      IF sy-subrc NE 0.
        IF sy-msgid NE space.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ELSE.
          MESSAGE s010 WITH 'Program error occurred in FM'(m10).
        ENDIF.
      ELSE.
        MESSAGE s010 WITH 'User Analysis Completed'(m09).
      ENDIF.


  ENDCASE.

*---------------------------------------------------------------------*
*       FORM CONFLICT_HOTSPOT                                         *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM conflict_hotspot USING r_ucomm LIKE sy-ucomm
                            rs_selfield TYPE slis_selfield.
  DATA : iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
  FIELD-SYMBOLS: <tcode> TYPE any.
  DATA: lv_tcode TYPE xutcode.
  DATA: lv_text TYPE ttext_stct.

*--User clicked on the Custom button. Switch between History or SOD
  IF r_ucomm EQ '&BUT'.
    IF gs_usrhis_or_usrsod EQ abap_true.
      IF gf_se_installed EQ abap_true.
        CLEAR gs_usrhis_or_usrsod.
        CLEAR: gv_label.
        gv_label-icon_id   = icon_usergroup.
        gv_label-text      = 'SE: User Analysis drill down'(s00).
        gv_label-icon_text = 'SE: User Analysis drill down'(s00).
*           sscrfields-functxt_01 = gv_label.
      ENDIF.
    ELSE.
      IF gf_ta_installed EQ abap_true.
        gs_usrhis_or_usrsod = abap_true.
        CLEAR: gv_label.
        gv_label-icon_id   = icon_history.
        gv_label-text      = 'TA: History Summary drill down'(s01).
        gv_label-icon_text = 'TA: History Summary drill down'(s01).
*           sscrfields-functxt_02 = gv_label.
      ENDIF.
    ENDIF.
    RETURN.
  ENDIF.


  CASE rs_selfield-fieldname.

    WHEN 'TCODE'. "Transaction.
      IF r_ucomm <> '&BUT'.
        SELECT SINGLE ttext INTO lv_text FROM tstct WHERE tcode EQ
        rs_selfield-value
                                                      AND sprsl EQ
        sy-langu.
*--Display the text for the transaction.
        MOVE rs_selfield-value TO lv_tcode.
        CALL FUNCTION '/PSYNG/SW_DISPLAY_TCODE'
          EXPORTING
            i_tcode = lv_tcode.

      ENDIF.
    WHEN OTHERS. "Users - field names = BNAME value.
*--User clicked on the user transactions counts.
      CASE gs_usrhis_or_usrsod.
        WHEN abap_true.                "TA: History Summary
          IF NOT rs_selfield-value IS INITIAL. "> 0.

            iseltab-selname = 'S_USERS'.
            iseltab-kind    = 'S'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = rs_selfield-fieldname.
            APPEND iseltab.

            READ TABLE <fs_tab> ASSIGNING <fs_o> INDEX
            rs_selfield-tabindex.
            ASSIGN COMPONENT 'TCODE' OF STRUCTURE <fs_o> TO <tcode>.
            iseltab-selname = 'S_TCODE'.
            iseltab-kind    = 'S'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = <tcode>. "<fs_o>-tcode.
            APPEND iseltab.

            iseltab-selname = 'S_DATE'.
            iseltab-kind    = 'S'.
            iseltab-sign    = s_dates-sign.    "I
            iseltab-option  = s_dates-option.  "BT
            iseltab-low     = s_dates-low.
            iseltab-high    = s_dates-high.
            APPEND iseltab.

            iseltab-selname = 'R_SUME'.
            iseltab-kind    = 'P'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = abap_true.
            APPEND iseltab.

            iseltab-selname = 'R_DAY'.
            iseltab-kind    = 'P'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = abap_true.
            APPEND iseltab.

            SUBMIT /psyng/bc_usrhis_36 WITH SELECTION-TABLE iseltab AND
            RETURN.
          ENDIF.


        WHEN OTHERS.                   "SE: User Analysis
          IF NOT rs_selfield-value IS INITIAL ."> 0.

            iseltab-selname = 'USERLIST'.
            iseltab-kind    = 'S'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = rs_selfield-fieldname.
            APPEND iseltab.

            iseltab-selname = 'SHOSUM'.
            iseltab-kind    = 'P'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = space.  "Default
            APPEND iseltab.

            iseltab-selname = 'SHOSIMP'.
            iseltab-kind    = 'P'.
            iseltab-sign    = 'I'.
            iseltab-option  = 'EQ'.
            iseltab-low     = abap_true.
            APPEND iseltab.

            SET PARAMETER ID 'XUS' FIELD rs_selfield-fieldname.
            SUBMIT /psyng/sodreport_sys_wide_org WITH SELECTION-TABLE
            iseltab AND RETURN.
          ENDIF.

      ENDCASE.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  get_tcodes_from_objects
*&---------------------------------------------------------------------*
*       Get transaction codes from Function Objects definition for
*       SOD Live analysis.
*       This ensures that even functions with placeholder tcodes
*      can be analyzed with SOD Live
*      This only supports S_TCODE TCD entries with only a Tcode in the
*      val_from field, no ranges, no wildcards
*----------------------------------------------------------------------*
FORM get_tcodes_from_objects.
  DATA :
    BEGIN OF lt_faobj OCCURS 0,
      funid    TYPE /psyng/function_id,
      val_from TYPE xuvalue,
    END OF  lt_faobj,
    l_tabname TYPE tabname VALUE '/PSYNG/FAOBJ2'.


  SELECT funid val_from
*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
*  FROM (l_tabname) INTO TABLE lt_faobj "#EC SAST_CI_GEN_CHECK
  FROM /PSYNG/FAOBJ2 INTO TABLE lt_faobj "#EC SAST_CI_GEN_CHECK
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  WHERE  vrsio  = p_vrsio   AND
         object = 'S_TCODE' AND
         field  = 'TCD'     AND
  val_to = space.

  LOOP AT lt_faobj.
    CHECK lt_faobj-val_from NS '*' .
    gt_functtran-functionid = lt_faobj-funid.
    gt_functtran-tcode      = lt_faobj-val_from.
    APPEND gt_functtran.
  ENDLOOP.
ENDFORM.                    " get_tcodes_from_objects
*&---------------------------------------------------------------------*
*&      Form  create_dynamic_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_dynamic_table.
  DATA : lt_fieldcat TYPE lvc_t_fcat,
         ls_fieldcat TYPE lvc_s_fcat,
         l_bname     TYPE xubname.
  DEFINE add_field.
    ls_fieldcat-fieldname  = &1.
    ls_fieldcat-seltext    = &2.
    ls_fieldcat-intlen     = &3.
    ls_fieldcat-inttype    = &4.
    ls_fieldcat-col_opt    = abap_true.
    ls_fieldcat-fix_column = &5.
    ls_fieldcat-emphasize  = &6.
    ls_fieldcat-hotspot    = &7.


    append ls_fieldcat to lt_fieldcat.

  END-OF-DEFINITION.
  add_field 'IMP'    'Severity'(s02)    '08'  'C' abap_true space space.
  add_field 'CONID'  'Conflict'(s03)    '12'  'C' abap_true space space.
  add_field 'CDESCR' 'Description'(s04) '200' 'C' abap_true space space.
  add_field 'FUNID'  'Function'(s05)    '12'  'C' abap_true space space.
  add_field 'FDESCR' 'Description'(s06) '200' 'C' abap_true space space.
  add_field 'TCODE'  'Transaction'(s07) '20'  'C' abap_true space
  abap_true.
  SORT s_users.
  LOOP AT s_users.
    l_bname = s_users-low.
    clean_username l_bname.
    add_field l_bname s_users-low '12' 'C' space space abap_true.
  ENDLOOP.

*--Allow coloring
  ls_fieldcat-tech = abap_true.
  ls_fieldcat-fieldname = 'COLORS'.
  ls_fieldcat-ref_field = 'COLTAB'.
  ls_fieldcat-ref_table = 'CALENDAR_TYPE'.
  ls_fieldcat-scrtext_s = ls_fieldcat-scrtext_m = ls_fieldcat-scrtext_l
  = 'COLOR'.
  APPEND ls_fieldcat TO lt_fieldcat.

*--Create a dynamic table to contain our data
  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = lt_fieldcat
    IMPORTING
      ep_table                  = gr_table
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ASSIGN gr_table->* TO <fs_tab>.
  CREATE DATA gr_rec LIKE LINE OF <fs_tab>.
  ASSIGN gr_rec->* TO <fs_o>.

*--Also prepare ALV Field Catalog
*--Create a field catalog
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    MOVE-CORRESPONDING ls_fieldcat TO gs_fieldcat_alv.
    gs_fieldcat_alv-seltext_s = ls_fieldcat-seltext.
    gs_fieldcat_alv-seltext_m = ls_fieldcat-seltext.
    gs_fieldcat_alv-seltext_l = ls_fieldcat-seltext.
    gs_fieldcat_alv-outputlen = 12.
    gs_fieldcat_alv-do_sum    = abap_true.
    APPEND gs_fieldcat_alv TO gt_fieldcat_alv.
  ENDLOOP.

*--Define the layout for better viewing.
  gs_layout-zebra = abap_true.
  gs_layout-colwidth_optimize = abap_true.
  gs_layout-coltab_fieldname = 'COLORS'.

*--Create Sort Table
  CLEAR gs_sort.
  gs_sort-tabname = '<fs_tab>'.
  gs_sort-up = abap_true.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'IMP'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'CONID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'CDESCR'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'FUNID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'FDESCR'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'TCODE'.
  APPEND gs_sort TO gt_sort.


ENDFORM.                    " create_dynamic_table
*&---------------------------------------------------------------------*
*&      Form  DEFINE_RESTRICTION
*&---------------------------------------------------------------------*
*       Display "Exclude Single Values" tab only
*----------------------------------------------------------------------*
FORM define_restriction .

*--Restricting the USERS selection to only NE, NB and 'NB'.
  optlist-name = 'EXUSERS'.
  optlist-options-eq = abap_true.
  APPEND optlist TO restrict-opt_list_tab.

  ass-kind = 'S'.
  ass-name = 'S_USERS'.
  ass-sg_main = 'I'.
  ass-sg_addy = space.
  ass-op_main = 'EXUSERS'.
  APPEND ass TO restrict-ass_tab.

  CALL FUNCTION 'SELECT_OPTIONS_RESTRICT'
    EXPORTING
      program                = sy-repid
      restriction            = restrict
    EXCEPTIONS
      too_late               = 1
      repeated               = 2
      selopt_without_options = 3
      selopt_without_signs   = 4
      invalid_sign           = 5
      empty_option_list      = 6
      invalid_kind           = 7
      repeated_kind_a        = 8
      OTHERS                 = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
    WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.


ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  GET_USERS_COUNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_users_count .
  DATA : l_numb      TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local    TYPE flag VALUE abap_true,
         lt_usrrfc   TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                     WITH HEADER LINE.

*--Determine the Real User count request.
  IF p_remonl = abap_true.
    CLEAR lv_local.
  ENDIF.
  IF p_exlusr EQ abap_true.
    CLEAR lv_exlckusr.
  ELSEIF p_exlusr IS INITIAL.
    lv_exlckusr = abap_true.
  ENDIF.

  IF p_otvdat EQ abap_true.
    CLEAR lv_outvdate.
  ELSEIF p_otvdat IS INITIAL.
    lv_outvdate = abap_true.
  ENDIF.

*--Now, get the user count.
  CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
    EXPORTING
      i_validuser       = p_vldusr
      i_include_locked  = lv_exlckusr
      i_include_expired = lv_outvdate
      if_local_system   = lv_local
      if_show_message   = abap_true
    IMPORTING
      e_usercount       = l_numb
    TABLES
      it_userlist       = s_users
      it_grouplist      = s_class
      it_usertype       = s_utype
      it_actgroups      = s_role
      it_profile        = s_prof
      it_department     = s_depart
      it_company        = s_comp
      it_cuid           = s_cuid
      it_costcenter     = s_kostl.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  sub_pf_status
*&---------------------------------------------------------------------*
*  Sub-Routine to Set the PF status
*----------------------------------------------------------------------*
FORM sub_pf_status USING rt_extab TYPE slis_t_extab..
  SET PF-STATUS 'ZVIOLATION'.
ENDFORM.                    "sub_pf_status

*&---------------------------------------------------------------------*
*&      Form  user_command
*&---------------------------------------------------------------------*
*   Sub-Routine to handle the click on the ALV aoutput
*----------------------------------------------------------------------*
FORM user_command USING r_ucomm    LIKE sy-ucomm
                       rs_selfield TYPE slis_selfield.

  IF r_ucomm EQ '&BUT'.
*--Put the code here ...
    MESSAGE 'Custom button is clicked.'(m08) TYPE 'S'.
  ENDIF.

ENDFORM.  "User_command
*&---------------------------------------------------------------------*
*&      Form  BUILD_RAW_DATA_TABLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_raw_data_table .
  DATA : lt_fieldcat TYPE lvc_t_fcat,
         ls_fieldcat TYPE lvc_s_fcat,
         l_bname     TYPE xubname.
  TYPES: BEGIN OF ty_user_data,
           bname   TYPE xubname,    "User
           class   TYPE xuclass,    "User Group
           kostl   TYPE xukostl,    "Company Code
           depart  TYPE ad_dprtmnt, "Department
           company TYPE uscomp,     "Company
         END OF ty_user_data.
  DATA: lt_user_data TYPE STANDARD TABLE OF ty_user_data.
  DATA: ls_user_data LIKE LINE OF lt_user_data.
  TYPES: BEGIN OF ty_fullname,
           bname     TYPE xubname,
           name_text TYPE ad_namtext,
         END OF ty_fullname.
  DATA: lt_fnames TYPE STANDARD TABLE OF ty_fullname.
  DATA: ls_fnames LIKE LINE OF lt_fnames.
  DEFINE assign_rvalue.
    assign component &1 of structure <fs_o> to <fs_dynfield>.
    &2 = <fs_dynfield>.
    unassign <fs_dynfield>.
  END-OF-DEFINITION.
  DEFINE clean_user.
    while &1 cs '-'.
      replace '-' with '_' into &1.
    endwhile.
    while &1 cs '.'.
      replace '.' with '_' into &1.
    endwhile.
  END-OF-DEFINITION.


*--Build the raw Layout ALV table
  CLEAR gs_layout.
  gs_layout-zebra = abap_true.
  gs_layout-colwidth_optimize = abap_true.
  gs_layout-no_hotspot = abap_true.

*--Build the raw Sort ALV table
  CLEAR gs_sort. REFRESH gt_sort.
  gs_sort-tabname = '<fs_raw>'.
  gs_sort-up = abap_true.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'CONID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'FUNID'.
  APPEND gs_sort TO gt_sort.
  ADD 1 TO gs_sort-spos.
  gs_sort-fieldname = 'TCODE'.
  APPEND gs_sort TO gt_sort.

*--Build the raw FIELDCAT ALV table
  CLEAR gs_fieldcat_raw. REFRESH gt_fieldcat_raw.
  CLEAR ls_fieldcat. REFRESH lt_fieldcat.
  add_field 'CONID'   'Conflict'(s08) '12' 'C' space space space.
  add_field 'CDESCR'  'Description'(s09) '200' 'C' abap_true space space
  .
  add_field 'FUNID'   'Function'(s10) '12' 'C' space space space.
  add_field 'FDESCR'  'Description'(s09) '200' 'C' abap_true space space
  .
  add_field 'TCODE'   'Transaction'(s11) '20' 'C' space space space.
  add_field 'USERID'  'User'(s12)  '12' 'C' space space space.
  add_field 'UDESCR'  'Fullname'(s13)  '80' 'C' abap_true space space.
  add_field 'USERGRP' 'User Grp'(s14)  '12' 'C' space space space.
  add_field 'COMPANY' 'Company Code'(s15)  '8' 'C' space space space.
  add_field 'DEPART'  'Department'(s16)  '4' 'C' space space space.
  add_field 'ECOUNT'  'Execution Count'(s17)  '12' 'N' space space space
  .

*--Create a dynamic table to contain our data
  UNASSIGN: <fs_raw>. CLEAR gr_raw.
  CALL METHOD cl_alv_table_create=>create_dynamic_table
    EXPORTING
      it_fieldcatalog           = lt_fieldcat
    IMPORTING
      ep_table                  = gr_raw
    EXCEPTIONS
      generate_subpool_dir_full = 1
      OTHERS                    = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  ASSIGN gr_raw->* TO <fs_raw>.
  CREATE DATA gr_rec LIKE LINE OF <fs_raw>.
  ASSIGN gr_raw->* TO <fs_r>.

*--Create a field catalog
  LOOP AT lt_fieldcat INTO ls_fieldcat.
    MOVE-CORRESPONDING ls_fieldcat TO gs_fieldcat_raw.
    gs_fieldcat_raw-seltext_s = ls_fieldcat-seltext.
    gs_fieldcat_raw-seltext_m = ls_fieldcat-seltext.
    gs_fieldcat_raw-seltext_l = ls_fieldcat-seltext.
    gs_fieldcat_raw-outputlen = 12.
    gs_fieldcat_raw-do_sum    = abap_true.

*    if ls_fieldcat-fieldname = 'ECOUNT'.
*     ls_fieldcat-ref_table    = '/PSYNG/SWRESHDR'.
*     ls_fieldcat-ref_field  = 'RETENTION_DAYS_DET'.
*      endif.
    APPEND gs_fieldcat_raw TO gt_fieldcat_raw.
*    clear : ls_fieldcat-ref_table, ls_fieldcat-ref_field.
  ENDLOOP.

gs_fieldcat_raw-ref_tabname = '/PSYNG/SWRESHDR'.
gs_fieldcat_raw-ref_fieldname = 'KBYTES_EST'.
modify gt_fieldcat_raw from gs_fieldcat_raw TRANSPORTING
ref_tabname ref_fieldname where fieldname = 'ECOUNT'.

* Get everyones full name.
  SELECT usr21~bname    "User Name
         adrp~name_text "Full Name
         INTO TABLE lt_fnames
         FROM usr21 JOIN adrp ON usr21~persnumber EQ adrp~persnumber AND
*                             adrp~date_from   EQ '00010101'      AND
                                 adrp~nation      EQ space
  WHERE usr21~bname IN s_users."#EC SAST_CI_GEN_CHECK

*--Get the addtional user information.
  SELECT a~bname      "User
         a~class      "User Group
         b~kostl      "Company Code
         b~department "Department
*         b~company    "Company
         INTO TABLE lt_user_data
         FROM usr02 AS a JOIN user_addr AS b ON a~bname EQ b~bname
  WHERE b~bname IN s_users."#EC SAST_CI_GEN_CHECK

*--Om 03/08/2022
  DATA: lt_swuinfo        TYPE TABLE OF /psyng/sw_uinfo
                             WITH HEADER LINE.
  CALL FUNCTION '/PSYNG/SW_USER_INFO'
          EXPORTING
               i_name_only  = 'X'
               i_mr_company = 'X'
          TABLES
               sw_uinfo     = lt_swuinfo.
  SORT lt_swuinfo.
  SORT lt_user_data BY bname.
  LOOP AT lt_user_data INTO ls_user_data.
    READ TABLE lt_swuinfo WITH KEY bname = ls_user_data-bname
                               BINARY SEARCH.
    IF sy-subrc = 0.
      ls_user_data-company = lt_swuinfo-company.
      MODIFY lt_user_data FROM ls_user_data TRANSPORTING
      company.
    ENDIF.
  ENDLOOP .

  free: lt_swuinfo.
  clear ls_user_data.
*---end



*--Populate the RAW data table with ALV and User data
  SORT lt_fnames BY bname.

  LOOP AT <fs_tab> INTO <fs_o>.
    LOOP AT s_users.
      CLEAR gs_pivot_raw.
      MOVE-CORRESPONDING <fs_o> TO gs_pivot_raw.
      MOVE s_users-low TO gs_pivot_raw-userid.
      READ TABLE lt_fnames INTO ls_fnames WITH KEY bname = s_users-low
                                                         BINARY SEARCH.
      MOVE ls_fnames-name_text TO gs_pivot_raw-udescr.
      READ TABLE lt_user_data INTO ls_user_data WITH KEY bname =
      s_users-low
                                                               BINARY
                                                               SEARCH.
      MOVE ls_user_data-class TO gs_pivot_raw-usergrp.
      MOVE ls_user_data-company TO gs_pivot_raw-company.
      MOVE ls_user_data-depart TO gs_pivot_raw-depart.
      clean_user s_users-low.
      assign_rvalue s_users-low gs_pivot_raw-ecount.
      APPEND gs_pivot_raw TO gt_pivot_raw.
    ENDLOOP.
  ENDLOOP.


ENDFORM.

*---------------------------------------------------------------------*
*       FORM set_def_usrtype                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM set_def_usrtype.
  REFRESH s_utype.
  CLEAR s_utype.
  s_utype-sign = 'I'.
  s_utype-option = 'EQ'.
  s_utype-low = 'A'.   "Dialog users
  APPEND s_utype.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_CONFIG_USR
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_config_usr .
  DATA: lv_table(6) TYPE c.
  DATA: lt_tvarv    TYPE TABLE OF tvarv WITH HEADER LINE.


*--Check if anything maintained for usertype in starv
  IF sy-saprl >= '620'.
    lv_table = 'TVARVC'.
  ELSE.
    lv_table = 'TVARV'.
  ENDIF.

*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  IF sy-saprl >= '620'.
*    lv_table = 'TVARVC'.
  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM TVARVC
         WHERE name = '/PSYNG/USERTYPE'
  AND type = 'S'."#EC SAST_CI_GEN_CHECK
  ELSE.
*    lv_table = 'TVARV'.
  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM TVARV
         WHERE name = '/PSYNG/USERTYPE'
  AND type = 'S'."#EC SAST_CI_GEN_CHECK
  ENDIF.

**  SELECT * INTO CORRESPONDING FIELDS OF TABLE lt_tvarv FROM (lv_table)
**         WHERE name = '/PSYNG/USERTYPE'
**  AND type = 'S'."#EC SAST_CI_GEN_CHECK
***HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25

  IF NOT lt_tvarv[] IS INITIAL.
    REFRESH s_utype.
    CLEAR s_utype.
  ENDIF.
  LOOP AT lt_tvarv.
    MOVE-CORRESPONDING lt_tvarv TO s_utype.
    s_utype-option = lt_tvarv-opti.
    APPEND s_utype.
  ENDLOOP.
  IF s_utype[] IS INITIAL.
    PERFORM set_def_usrtype.
  ENDIF.

*--Default locked users
  CLEAR gs_swconfig.
  se_config_param 'DFLT_EXCLUDE_LOCKED' gs_swconfig-value.
  IF gs_swconfig-value = 'Y'.
    p_exlusr = abap_true.
  ELSEIF gs_swconfig-value = 'N'.
    p_exlusr = space.
  ENDIF.

*-- Default expired users
  CLEAR gs_swconfig.
  se_config_param 'DFLT_EXCL_OUT_VALID' gs_swconfig-value.
  IF gs_swconfig-value = 'Y'.
    p_otvdat = abap_true.
  ELSEIF gs_swconfig-value = 'N'.
    p_otvdat = space.
  ENDIF.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_DEPARTMENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0895   text
*      <--P_S_DEPART_LOW  text
*----------------------------------------------------------------------*
FORM f4_department  USING    fieldname
                    CHANGING e_department .
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr.

*--Check what FM is configured for search help for department
  se_config_param 'SW_DEPART_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113 WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '(m11)
      ls_fmname '. FM doesn''t exist'(m12).
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_077'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro     = l_dynnr
      i_dynpprog   = l_repid
      i_fieldname  = fieldname
    CHANGING
      e_department = e_department.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_CENTRAL_UID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0919   text
*      <--P_S_CUID_LOW  text
*----------------------------------------------------------------------*
FORM f4_central_uid USING    fieldname
                CHANGING e_accnt.
  DATA : ls_config_fm TYPE /psyng/swconfig,
         ls_fmname    TYPE rs38l_fnam,
         l_repid      LIKE sy-repid,
         l_dynnr      LIKE sy-dynnr.


  CLEAR ls_config_fm.
*--Check what FM is configured for Central Userid information
  se_config_param 'SW_CENTRAL_USR_FM' ls_config_fm-value.

  IF NOT ls_config_fm IS INITIAL.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113 WITH
      'Cannot determine SW_CENTRAL_USR_FM with FM '(m13)
      ls_fmname '. FM doesn''t exist'(m14).
    ELSE..
      l_repid = sy-repid.
      l_dynnr = sy-dynnr.
*Get Central Userid information as search help
      CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
        EXPORTING
          i_dynpro       = l_dynnr
          i_dynpprog     = l_repid
          i_fieldname    = fieldname
          if_search_help = 'X'
        CHANGING
          e_central_uid  = e_accnt.

    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_COMPANY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_1254   text
*      <--P_S_COMP_LOW  text
*----------------------------------------------------------------------*
FORM f4_company  USING    fieldname
                CHANGING e_comp.
  DATA : ls_config_fm TYPE /psyng/swconfig,
          ls_fmname    TYPE rs38l_fnam,
          l_repid      LIKE sy-repid,
          l_dynnr      LIKE sy-dynnr..
*--Check what FM is configured for search help for Company
  se_config_param 'SW_COMPANY_SHLP_FM' ls_config_fm-value.
  IF sy-subrc = 0.
    ls_fmname = ls_config_fm-value.
    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = ls_fmname
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc <> 0.
*--Configured Fm does not exist, use default
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_074'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro    = l_dynnr
      i_dynpprog  = l_repid
      i_fieldname = fieldname
    CHANGING
      e_company   = e_comp.
ENDFORM.
