*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/USER_LOGON_MONITOR
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
REPORT /psyng/user_logon_monitor MESSAGE-ID /psyng/sw .
INCLUDE /psyng/sw_config.
INCLUDE /psyng/sw_125.
INCLUDE /psyng/basis_exelog.
TABLES: usr02, /psyng/sw_rfcdes, /psyng/swresusr,
        agr_define, ust04,/psyng/sw_uinfo, /psyng/bc_sec_policy_range.
INCLUDE /psyng/user_logon_monitor_top.



"BOC UMITTAL 24-09-2024
DATA : l_lock_chg         TYPE flag VALUE '',
        l_lock_del_chg    TYPE flag VALUE '',
        l_del_chg         TYPE flag VALUE '',
        l_chg             TYPE flag VALUE '',
        l_lock_del        TYPE flag VALUE '',
        l_del             TYPE flag VALUE '',
        l_no_lock_del_chg TYPE flag VALUE '',
        l_lock            TYPE flag VALUE ''.

"EOC UMITTAL 24-09-2024
SELECTION-SCREEN: BEGIN OF BLOCK blok WITH FRAME TITLE text-011.
*SELECTION-SCREEN PUSHBUTTON  01(6) blok_but USER-COMMAND blok_but.
*SELECTION-SCREEN COMMENT 16(50) text-011 .
*
*SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(10) text-006 MODIF ID blk.
SELECTION-SCREEN: POSITION 12.
PARAMETERS: lockdays(4) TYPE n OBLIGATORY MODIF ID blk.
SELECTION-SCREEN: COMMENT 17(10) lok_date.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: lock AS CHECKBOX MODIF ID xx1. "++ UMITTAL 24-09-2024
SELECTION-SCREEN: COMMENT 32(15) text-009 MODIF ID blk.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(11) text-012.
SELECTION-SCREEN: POSITION 12.
PARAMETERS: valdays(4) TYPE n  OBLIGATORY MODIF ID blk.
SELECTION-SCREEN: COMMENT 17(10) val_date MODIF ID blk.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: chgval AS CHECKBOX MODIF ID yy1. "++UMITTAL 24-09-2024
SELECTION-SCREEN: COMMENT 32(30) text-013 MODIF ID blk.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 1(11) text-007.
SELECTION-SCREEN: POSITION 12.
PARAMETERS: deldays(4) TYPE n  OBLIGATORY MODIF ID blk.
SELECTION-SCREEN: COMMENT 17(10) del_date MODIF ID blk.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: delete AS CHECKBOX MODIF ID zz1. "++ UMITTAL 24-09-2024
SELECTION-SCREEN: COMMENT 32(15) text-010 MODIF ID blk.
SELECTION-SCREEN: END OF LINE.


SELECTION-SCREEN : SKIP.
SELECTION-SCREEN: BEGIN OF LINE.

SELECTION-SCREEN: COMMENT 1(66) text-019.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK blok.

*--User group parameters
SELECTION-SCREEN: BEGIN OF BLOCK ugrp WITH FRAME TITLE text-b11.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_uglck AS CHECKBOX.
SELECTION-SCREEN: COMMENT 4(37) text-v05.
SELECTION-SCREEN: POSITION 42.
PARAMETERS p_lckgrp TYPE usr02-class.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: p_ugexp AS CHECKBOX.
SELECTION-SCREEN: COMMENT 4(37) text-v06.
SELECTION-SCREEN: POSITION 42.
PARAMETERS p_expgrp TYPE usr02-class.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK ugrp.

SELECTION-SCREEN: BEGIN OF BLOCK exe WITH FRAME TITLE text-005.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: pbname FOR usr02-bname,  "user ID
                pclass FOR usr02-class, "user group
                s_lictyp FOR users-usertyp,
                s_kostl FOR /psyng/swresusr-kostl " Cost center
                         MATCHCODE OBJECT /psyng/kostl,
                s_comp  FOR /psyng/swresusr-company, " company
                 s_cuid   FOR  /psyng/sw_uinfo-central_uid,

                s_dep   FOR /psyng/swresusr-department, " department
                s_role   FOR agr_define-agr_name   MODIF ID usr,
                s_prof   FOR ust04-profile         MODIF ID usr,
                s_secpol FOR /psyng/bc_sec_policy_range-low
                  MODIF ID sec.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.

*--SE3.4PS3 - Ability to exclude
* users with recently changed validity
* or unlocked users
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: ig_ul AS CHECKBOX.
SELECTION-SCREEN: COMMENT 4(25) text-v01.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: uldays(4) TYPE n DEFAULT 0030 OBLIGATORY.
SELECTION-SCREEN: COMMENT 36(15) text-v02.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: ig_vc AS CHECKBOX.
SELECTION-SCREEN: COMMENT 4(25) text-v03.
SELECTION-SCREEN: POSITION 30.
PARAMETERS: vcdays(4) TYPE n DEFAULT 0030 OBLIGATORY.
SELECTION-SCREEN: COMMENT 36(15) text-v02.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK exe.
**---Om 2021/07/07
SELECTION-SCREEN: BEGIN OF BLOCK sysb WITH FRAME  TITLE text-018.
PARAMETERS :
      p_system TYPE /psyng/sw_rfcdes-rfcdest
                MATCHCODE OBJECT /psyng/sw_rfcsh_coll
                MODIF ID sys.
SELECTION-SCREEN: END OF BLOCK sysb.

SELECTION-SCREEN: BEGIN OF BLOCK eml WITH FRAME TITLE text-b07  .
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS in_lcd AS CHECKBOX MODIF ID eml.
SELECTION-SCREEN: COMMENT 4(35) text-v07.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS       in_exp AS CHECKBOX MODIF ID eml.
SELECTION-SCREEN: COMMENT 4(35) text-v08.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS          in_del AS CHECKBOX MODIF ID eml.
SELECTION-SCREEN: COMMENT 4(35) text-v09.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: END OF BLOCK eml.

*---output
SELECTION-SCREEN: BEGIN OF BLOCK out WITH FRAME TITLE text-b06  .
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: showalv   RADIOBUTTON GROUP o1
USER-COMMAND out1 MODIF ID out.
SELECTION-SCREEN: COMMENT 4(20) text-o01 FOR FIELD showalv
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: no_out   RADIOBUTTON GROUP o1
   MODIF ID out.
SELECTION-SCREEN: COMMENT 4(20) text-o02 FOR FIELD no_out
                                          MODIF ID out.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS: down_fil   RADIOBUTTON GROUP o1
     MODIF ID out.
SELECTION-SCREEN: COMMENT 4(20) text-o03 FOR FIELD down_fil
                                          MODIF ID out.
SELECTION-SCREEN: POSITION 30.
*--Folder
PARAMETERS :  basepath TYPE rlgrap-filename
LOWER CASE DEFAULT 'c:\temp\inactive_users.xls' OBLIGATORY.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK out.

*---Background Block C0334
SELECTION-SCREEN: BEGIN OF BLOCK bgd_o WITH FRAME TITLE text-b05  ..
SELECTION-SCREEN SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  4(30) text-b10 USER-COMMAND scjb
MODIF ID bgd.
SELECTION-SCREEN PUSHBUTTON  40(25) text-b09 USER-COMMAND sm37
MODIF ID bgd.
SELECTION-SCREEN END OF LINE.
SELECTION-SCREEN: END OF BLOCK bgd_o.
**end

INITIALIZATION.
* BOC by RGUPTA on 08.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 08.04.22 for C0700
*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
    EXPORTING
      i_repid = '/PSYNG/USER_LOGON_MONITOR'.

*  PERFORM set_button_icons."BOC UMITTAL 24-09-2024
  PERFORM init.
  PERFORM fill_init_selection.

AT SELECTION-SCREEN.
  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.

*---C0634
  CASE sy-ucomm.
    WHEN 'SCJB'.
      g_exit_proc = 'Y'.
      PERFORM schedule_back_job.
    WHEN 'SM37'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SM37'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH 'SM37'.
      ELSE.
        CALL TRANSACTION 'SM37'.
      ENDIF.
  ENDCASE.

  PERFORM change_sel_screen_text.
*--disabled email parameters when no output not selected

AT SELECTION-SCREEN OUTPUT.
  "BOC UMITTAL 24-09-2024
  AUTHORITY-CHECK
   OBJECT 'Y&SW_UASMT'
   ID 'Y&SW_BNAME' FIELD g_current_user
   ID 'ACTVT' FIELD '02'.

  IF sy-subrc EQ 0.
    AUTHORITY-CHECK
     OBJECT 'Y&SW_UASMT'
     ID 'Y&SW_BNAME' FIELD g_current_user
     ID 'ACTVT' FIELD '06'.
    IF sy-subrc EQ 0.
      AUTHORITY-CHECK
        OBJECT 'Y&SW_UASMT'
        ID 'Y&SW_BNAME' FIELD g_current_user
        ID 'ACTVT' FIELD '05'.
      IF sy-subrc EQ 0.
        l_lock_del_chg = 'X'.
      ELSE.
        l_del_chg = 'X'.
      ENDIF.
    ELSE.
      AUTHORITY-CHECK
        OBJECT 'Y&SW_UASMT'
        ID 'Y&SW_BNAME' FIELD g_current_user
        ID 'ACTVT' FIELD '05'.
      IF sy-subrc EQ 0.
        l_lock_chg = 'X'.
      ELSE.
        l_chg = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    AUTHORITY-CHECK OBJECT 'Y&SW_UASMT'
     ID 'Y&SW_BNAME' FIELD g_current_user
     ID 'ACTVT' FIELD '06'.
    IF sy-subrc EQ 0.
      AUTHORITY-CHECK
        OBJECT 'Y&SW_UASMT'
        ID 'Y&SW_BNAME' FIELD g_current_user
        ID 'ACTVT' FIELD '05'.
      IF sy-subrc EQ 0.
        l_lock_del = 'X'.
      ELSE.
        l_del = 'X'.
      ENDIF.
    ELSE.
      AUTHORITY-CHECK
        OBJECT 'Y&SW_UASMT'
        ID 'Y&SW_BNAME' FIELD g_current_user
        ID 'ACTVT' FIELD '05'.
      IF sy-subrc EQ 0.
        l_lock = 'X'.
      ELSE.
        l_no_lock_del_chg = 'X'.
      ENDIF.
    ENDIF.
  ENDIF.

  LOOP AT SCREEN.
*Screen group for checking 'CHANGE' access
    IF screen-group1 = 'YY1'.
      IF l_no_lock_del_chg  = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_lock_del_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock_del = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_lock = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_del_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_del = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
*Screen group for Lock Auth check
    IF screen-group1 = 'XX1'.
      IF l_no_lock_del_chg  = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_lock_del_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock_del = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_del_chg = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_chg = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_del = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

*Screen group for checking 'DELETE' access
    IF screen-group1 = 'ZZ1'.
      IF l_no_lock_del_chg  = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_lock_del_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock_chg = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_lock_del = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_lock = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_del_chg = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ELSEIF l_chg = 'X'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSEIF l_del = 'X'.
        screen-input = 1.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.

  ENDLOOP.
  "EOC UMITTAL 24-09-2024
  LOOP AT SCREEN.
    IF no_out <> 'X'.
      IF screen-group1 = 'EML'.
        screen-input = 0.
        MODIFY SCREEN.
      ELSE.
        IF screen-group1 = 'EML'.
          screen-input = 1.
          MODIFY SCREEN.
        ENDIF.
      ENDIF.
    ENDIF.
  ENDLOOP.

*--disable if sec policy doesn't exist in the system
  CONSTANTS l_sectab TYPE tabname VALUE 'SEC_POLICY_CUST'.
  DATA l_tabname TYPE tabname.
  SELECT tabname FROM dd02l INTO l_tabname UP TO 1 ROWS
  WHERE tabname = l_sectab.                      "#EC SAST_CI_GEN_CHECK
  ENDSELECT.
  IF sy-subrc <> 0.
    LOOP AT SCREEN.
      IF screen-group1 = 'SEC'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDLOOP.
  ENDIF.

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
*--collepse/expand buttons
  PERFORM handle_button.
*  PERFORM handle_sections."BOC UMITTAL 24-09-2024


AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-low.
  PERFORM f4_company USING 'S_COMP-LOW' CHANGING s_comp-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_comp-high.
  PERFORM f4_company USING 'S_COMP-HIGH' CHANGING s_comp-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_dep-low.
  PERFORM f4_department USING 'S_DEP-LOW' CHANGING s_dep-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_dep-high.
  PERFORM f4_department USING 'S_DEP-HIGH' CHANGING s_dep-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-low.
  PERFORM f4_central_uid USING 'S_CUID-LOW' CHANGING s_cuid-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_cuid-high.
  PERFORM f4_central_uid USING 'S_CUID-HIGH' CHANGING s_cuid-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_secpol-low.
  PERFORM f4_sec_policy USING 'S_SECPOL-LOW' CHANGING s_secpol-low .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR s_secpol-high.
  PERFORM f4_sec_policy USING 'S_SECPOL-HIGH' CHANGING s_secpol-high .

AT SELECTION-SCREEN ON VALUE-REQUEST FOR basepath.
  PERFORM dir_select .

START-OF-SELECTION.

*BOC UMITTAL ATC check SIEMENS 11/02/25
  AUTHORITY-CHECK OBJECT 'S_PROGRAM'
         ID 'P_GROUP' FIELD 'SW_SE'
         ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) WITH 'execute ' sy-repid.
    EXIT.
  ENDIF.
*EOC UMITTAL ATC check SIEMENS 11/02/25

  exelog sy-repid ''.

  g_program = sy-repid.
  IF g_exit_proc = 'Y'.
*BOC UMITTAL SE VF scan changes-25/11/2024
*    SUBMIT (g_program)
    SUBMIT /psyng/user_logon_monitor
*EOC UMITTAL SE VF scan changes-25/11/2024
           VIA SELECTION-SCREEN
           USING SELECTION-SET g_curr_variant .
  ENDIF.

*--Om C0383
**-- Check RFC destinations
  IF NOT p_system IS INITIAL.
    PERFORM rfc_validations.
    msg 'System:'(l02) p_system '' '' .
  ENDIF.

  PERFORM input_fields_validations.
  PERFORM check_accidental_delete.
  PERFORM get_data.

*---Check cua and get scum settings if active
  PERFORM get_scum_settings.

  PERFORM fill_user_name.

  IF lock = 'X'.
    PERFORM user_lock.
  ENDIF.
  IF chgval = 'X'.
    PERFORM user_expire.
  ENDIF.
  IF delete = 'X'.
    PERFORM user_delete.
  ENDIF.

  CASE 'X'.
    WHEN showalv .
      PERFORM output_alv.
    WHEN no_out.
*---send email
      IF in_lcd = 'X' OR in_exp = 'X' OR in_del = 'X'.
        PERFORM send_email.
        IF sy-batch EQ 'X'.
          PERFORM write_spool.
        ENDIF.
      ELSE.
        MESSAGE s140 WITH
        'Select at least one option from E-mail Parameters'(e10).
      ENDIF.
    WHEN down_fil.
      PERFORM download_output.
  ENDCASE.

*&---------------------------------------------------------------------*
*&      Form  get_data
*&---------------------------------------------------------------------*
*       Get user data
*----------------------------------------------------------------------*
FORM get_data.
  DATA: lv_yusloc TYPE x VALUE '40',     "Locked by Administrator
        lv_yugloc TYPE x VALUE '20'.     "Locked by globaladministrator

  DATA : l_uflag TYPE x.
  DATA: lv_createdate          TYPE sy-datum,
        lv_logondate           TYPE sy-datum,
        lf_missing_auth_ugroup TYPE /psyng/bapiflagx,
        i_include_locked       TYPE flag,
        i_include_expire       TYPE flag,
        lt_users               TYPE TABLE OF usr02 WITH HEADER LINE,
        lv_comparedate         TYPE sy-datum.
  DATA: lt_usr02 TYPE TABLE OF typ_usr02 WITH HEADER LINE,
        wa_usr02 LIKE LINE OF lt_usr02.

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

  msg '-->Start loading users info.'(l03) '' '' '' .

  IF p_system IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_041'
      EXPORTING
        i_validuser       = validusr
        i_include_locked  = i_include_locked
        i_include_expired = i_include_expire
      TABLES
        et_users          = lt_users
        it_userlist       = pbname
        it_grouplist      = pclass
        it_usertype       = usrtype
        it_actgroups      = s_role
        it_profile        = s_prof
        it_cuid           = s_cuid
        it_costcenter     = s_kostl
        it_company        = s_comp
        it_department     = s_dep
        it_secpolicy      = s_secpol.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_041'
      DESTINATION p_system
      EXPORTING
        i_validuser           = validusr
        i_include_locked      = i_include_locked
        i_include_expired     = i_include_expire
      TABLES
        et_users              = lt_users
        it_userlist           = pbname
        it_grouplist          = pclass
        it_usertype           = usrtype
        it_actgroups          = s_role
        it_profile            = s_prof
        it_cuid               = s_cuid
        it_costcenter         = s_kostl
        it_company            = s_comp
        it_department         = s_dep
        it_secpolicy          = s_secpol
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0 .
      MESSAGE s398(00) WITH g_system_msg.
      LEAVE LIST-PROCESSING.
    ENDIF.

  ENDIF.
  CHECK NOT lt_users[] IS INITIAL.

  LOOP AT lt_users.
    wa_usr02-bname = lt_users-bname.
    wa_usr02-class = lt_users-class.
    wa_usr02-gltgv = lt_users-gltgv.
    wa_usr02-gltgb = lt_users-gltgb.
    wa_usr02-uflag = lt_users-uflag.
    wa_usr02-erdat = lt_users-erdat.
    wa_usr02-trdat = lt_users-trdat.
    INSERT wa_usr02 INTO TABLE lt_usr02 .
  ENDLOOP.

  lockdate = sy-datum - lockdays.
  deldate = sy-datum - deldays.
  DELETE lt_usr02 WHERE trdat GT lockdate.


*--SE3.4PS3 - Ability to exclude
* users with recently changed validity
* or unlocked users
  PERFORM ignore_recent_changed_usr
    TABLES lt_usr02.

  LOOP AT lt_usr02.
    CLEAR lv_comparedate.
    l_uflag  = lt_usr02-uflag."unicode

    CLEAR: users.

*   Check license type
    SELECT SINGLE lic_type INTO users-usertyp FROM usr06
                  WHERE bname = lt_usr02-bname.
    IF NOT s_lictyp[] IS INITIAL.
      CHECK users-usertyp IN s_lictyp.
    ENDIF.

    SELECT SINGLE utyptext INTO users-utyptext FROM tutyp
                  WHERE langu   = sy-langu
                    AND usertyp = users-usertyp.

    MOVE-CORRESPONDING lt_usr02 TO users.

    lv_createdate = lt_usr02-erdat.
    lv_logondate = lt_usr02-trdat.

    IF lv_logondate IS INITIAL.  "user has never logged on
*Determine comparison date
*--Case 16500, 17165 - If the start of the validity of the user is after
*                      the creation date of the user, this date is used
*                      if it's blank or before the creation date, the
*                      creation date is used as the date to compare for
*                      users that have never logged in
*  --Case 17165 -     /psyng/sw_041 overwrites initial
*                     validity date with '000101', so consider that as
*                     well as initial

      IF ( lt_usr02-gltgv IS INITIAL OR lt_usr02-gltgv = '00010101' ) OR
         lt_usr02-gltgv < lv_createdate.
        lv_comparedate = lv_createdate.
      ELSE.
        lv_comparedate = lt_usr02-gltgv.
      ENDIF.
* comparison date older than delete

      IF lv_comparedate LT deldate . "Case 16500
        users-action = 'TO_BE_DELETED'.
        APPEND users.
        deleteuser-bname = lt_usr02-bname.
        APPEND deleteuser.
      ENDIF.
* creation older than validity date
      IF lv_comparedate LT expdate.
        users-action = 'TO_BE_EXPIRED'.
        APPEND users.
        expireuser-bname = lt_usr02-bname.
        APPEND expireuser.
      ENDIF.

* creation older than lock date
      IF lv_comparedate LT lockdate
      AND NOT
          ( l_uflag O lv_yusloc OR
            l_uflag O lv_yugloc ).
        users-action = 'TO_BE_LOCKED'.
        APPEND users.
        lockuser-bname = lt_usr02-bname.
        APPEND lockuser.
      ENDIF.

    ELSE.  "user has logged on at least once

* logon older than delete date
      IF lv_logondate LT deldate.
        users-action = 'TO_BE_DELETED'.
        APPEND users.
        deleteuser-bname = lt_usr02-bname.
        APPEND deleteuser.
      ENDIF.

* logon older than validity date
      IF lv_logondate LT expdate.
        users-action = 'TO_BE_EXPIRED'.
        APPEND users.
        expireuser-bname = lt_usr02-bname.
        APPEND expireuser.
      ENDIF.

* logon older than lock date and greater-than/equal-to delete date
      IF lv_logondate LT lockdate
      AND NOT
        ( l_uflag O lv_yusloc OR
          l_uflag O lv_yugloc ).
        users-action = 'TO_BE_LOCKED'.
        APPEND users.
        lockuser-bname = lt_usr02-bname.
        APPEND lockuser.
      ENDIF.
    ENDIF.
  ENDLOOP.

  SORT: deleteuser, lockuser, expireuser, users.

  DESCRIBE TABLE deleteuser LINES delcount.
  DESCRIBE TABLE lockuser LINES lockcount.
  DESCRIBE TABLE expireuser LINES expcount.
  msg '--->Nr. of users that will be expired:'(l07) expcount '' '' .
  msg '--->Nr. of users that will be locked:'(l04)  lockcount '' '' .
  msg '--->Nr. of users that will be deleted:'(l05)  delcount '' '' .
ENDFORM.                    " get_data

*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_alv.
  DATA:
*  lv_temp(90),
    program       LIKE sy-repid,
    alv_layout    TYPE slis_layout_alv,
    alv_grid_titl TYPE lvc_title,
    ls_variant    TYPE disvariant.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  alv_layout-box_fieldname     = 'SEL'.
  SORT: users BY action DESCENDING bname.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = program
      i_internal_tabname     = 'USERS'
      i_inclname             = program
    CHANGING
      ct_fieldcat            = i_fieldcat_alv
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  CHECK sy-subrc = 0.
  PERFORM change_catalog_texts.
  MESSAGE s176(/psyng/sw).

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title            = alv_grid_titl
      i_callback_program      = program
      i_callback_top_of_page  = 'ALV_HEADER'
      i_callback_pf_status_set = 'SET_PFSTATUS'
      i_callback_user_command = 'USER_CLICK'
      is_layout               = alv_layout
      it_fieldcat             = i_fieldcat_alv
      i_save                  = 'A'
      is_variant              = ls_variant
    TABLES
      t_outtab                = users
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.


ENDFORM.                    " output_alv

FORM set_pfstatus  USING
       it_extab         TYPE slis_t_extab.

  SET PF-STATUS 'STATUS_01' OF PROGRAM '/PSYNG/USER_LOGON_MONITOR'
      EXCLUDING it_extab.
ENDFORM.
*--
* SE3.5PS2 Drill down to SU01 if the user has the authorization,
* otherwise do nothing
*--
FORM user_click USING r_ucomm LIKE sy-ucomm
                      rs_selfield TYPE slis_selfield.
  DATA : lt_users_tmp LIKE TABLE OF users WITH HEADER LINE,
        l_fld TYPE string.
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.

  CASE r_ucomm.
    WHEN 'ACTION'.


      DATA l_raise_error TYPE flag.
      CLEAR l_raise_error.
      lt_users_tmp[] = users[].
      DELETE users WHERE sel <> 'X'.
*---Handle for actions already taken
      LOOP AT users WHERE action = 'USER_LOCKED' OR
                          action = 'USER_EXPIRED' OR
                          action = 'USER_DELETED'.
        l_raise_error = 'X'.
        EXIT.
      ENDLOOP.
      IF l_raise_error IS INITIAL.
        PERFORM apply_actions.
        DELETE lt_users_tmp WHERE sel = 'X'.
*        REFRESH users.
        APPEND LINES OF lt_users_tmp TO users.
*        users[] = lt_users_tmp[].
      ELSE.
        users[] = lt_users_tmp[].
        MESSAGE s398(00) WITH
        'Action already taken in selected entries,'(L11)
           'please deselect!'(L12).

      ENDIF.
* Refresh the grid with the new data
      l_fld = '(SAPLSLVC_FULLSCREEN)GT_GRID-GRID'.
      ASSIGN  (l_fld) TO <g_grid>.           "#EC PATHLOCK_CI_DYN_ACCES
      CALL METHOD <g_grid>->refresh_table_display.
      FREE lt_users_tmp.
  ENDCASE.

  CHECK rs_selfield-fieldname = 'BNAME'.
*  AUTHORITY-CHECK OBJECT 'S_TCODE'
*           ID 'TCD' FIELD 'SU01'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
  IF sy-subrc = 1.
    SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
    CALL TRANSACTION 'SU01'.
  ELSE.
*    AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01D'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
    IF sy-subrc = 1.
      SET PARAMETER ID 'XUS' FIELD rs_selfield-value.
      CALL TRANSACTION 'SU01D'.
    ELSE.
      MESSAGE e077(s#) WITH 'SU01D'.
    ENDIF.
  ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  USER_LOCK
*&---------------------------------------------------------------------*
FORM user_lock.
  DATA: ls_usrfldtsel LIKE LINE OF gt_usrfldtsel,
        l_dest        TYPE rfcdest,
        lv_logondata  LIKE bapilogond,
        lv_logondatax LIKE bapilogonx.

*--- C0383 lock as per scum setting
  IF g_cua_active = 'Y'.
    READ TABLE gt_usrfldtsel INTO ls_usrfldtsel
    WITH KEY log_field = 'LOGONDATA_VALID'.
  ENDIF.

*-- if cua is active and set as globle then take cua host
*-- as rfc and ignore entered rfc
  IF g_cua_active = 'Y' AND ls_usrfldtsel-uflag = 'G'.
    l_dest = g_sendsystem.
  ELSE.
    l_dest = p_system.
  ENDIF.

  LOOP AT users WHERE action = 'TO_BE_LOCKED'.
    REFRESH: return.
    IF l_dest IS INITIAL.
      CALL FUNCTION 'BAPI_USER_LOCK'   "#EC SAST_CI_GEN_CHECK(HBHALLA)(
*17/12/24)
        EXPORTING
          username = users-bname
        TABLES
          return   = return.
*--  update usergroup
      IF p_uglck = 'X'.
        lv_logondata-class = p_lckgrp.
        lv_logondatax-class = 'X'.
       CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
         EXPORTING
           username   = users-bname
           logondata  = lv_logondata
           logondatax = lv_logondatax
         TABLES
                 return     = retun1.
      ENDIF.

    ELSE.
      CALL FUNCTION 'BAPI_USER_LOCK'
        DESTINATION l_dest
        EXPORTING
          username              = users-bname
        TABLES
          return                = return
        EXCEPTIONS
          communication_failure = 1 MESSAGE g_system_msg
          system_failure        = 2 MESSAGE g_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        MESSAGE e002(/psyng/sw) WITH g_system_msg.
      ENDIF.
*--  update usergroup
      IF p_uglck = 'X'.
        lv_logondata-class = p_lckgrp.
        lv_logondatax-class = 'X'.
        CALL FUNCTION 'BAPI_USER_CHANGE'
        DESTINATION l_dest
          EXPORTING
            username   = users-bname
            logondata  = lv_logondata
            logondatax = lv_logondatax
          TABLES
            return     = retun1
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
            WHEN 2.
              MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
            WHEN OTHERS.
              MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
          ENDCASE.
        ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
      ENDIF.
    ENDIF.
    LOOP AT return WHERE number = '245'.
      users-action = 'USER_LOCKED'.
      MODIFY users.
      EXIT.
    ENDLOOP.
  ENDLOOP.


ENDFORM.                    " USER_LOCK
*&---------------------------------------------------------------------*
*&      Form  USER_DELETE
*&---------------------------------------------------------------------*
FORM user_delete.
  DATA: lv_logondata     LIKE bapilogond,
        l_cua            TYPE /psyng/flag,
        l_sendsys        TYPE rfcsendsys,
        l_rcvsys         TYPE rfcrcvsys,
        l_system_msg(72) TYPE c,
        lt_roles         TYPE TABLE OF bapilocagr WITH HEADER LINE,
        lt_profiles      TYPE TABLE OF bapilprof WITH HEADER LINE,
        lt_return        TYPE TABLE OF bapiret2 WITH HEADER LINE,
        lt_systems       TYPE TABLE OF uszbvsys WITH HEADER LINE,
        lt_upd_systems   TYPE TABLE OF ussystem WITH HEADER LINE.

* Check for CUA
  CALL FUNCTION '/PSYNG/BC_002'
    IMPORTING
      e_cua_active = l_cua
      e_sendsystem = l_sendsys
      e_rcvsystem  = l_rcvsys.

  LOOP AT users WHERE action = 'TO_BE_DELETED'.
    IF l_cua = 'N'.
      REFRESH: return.
      IF p_system IS INITIAL.  "Change by RGUPTA on 9th Feb 2022
*     Delete user on local system
        CALL FUNCTION 'BAPI_USER_DELETE' "#EC SAST_CI_GEN_CHECK(HBHALLA)
*17/12/24
          EXPORTING
            username = users-bname
          TABLES
                    return   = return.
* BOC by RGUPTA on 9th Feb 2022
      ELSE.
*     Delete user from system entered in selection screen
        CALL FUNCTION 'BAPI_USER_DELETE'
        DESTINATION p_system
          EXPORTING
            username = users-bname
          TABLES
            return   = return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
            WHEN 2.
              MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
            WHEN OTHERS.
              MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
          ENDCASE.
        ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
      ENDIF.
* EOC by RGUPTA on 9th  Feb 2022
      LOOP AT return WHERE number = '232'.
        users-action = 'USER_DELETED'.
        MODIFY users.
        EXIT.
      ENDLOOP.
*-- Once user deleted not need to show other action in the output
*-- odubey B16612 10/06/2022
      DELETE users WHERE bname = users-bname AND
                         action <> 'USER_DELETED'.
    ELSE.
      REFRESH: lt_systems, lt_upd_systems, lt_roles, lt_profiles.

*     Get all systems for user
      CALL FUNCTION '/PSYNG/SW_093' DESTINATION l_sendsys
        EXPORTING
          i_bname               = users-bname
        TABLES
          et_systems            = lt_systems
        EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK

      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH text-e01 l_sendsys.
      ENDCASE.
* BOC by RGUPTA on 1st Feb 2022
**     Read roles for local system
*      CALL FUNCTION 'BAPI_USER_LOCACTGROUPS_READ'
*        DESTINATION l_sendsys
*        EXPORTING
*          username              = users-bname
*        TABLES
*          activitygroups        = lt_roles
*          return                = lt_return
*        EXCEPTIONS
*          communication_failure = 1 MESSAGE l_system_msg
*          system_failure        = 2 MESSAGE l_system_msg
*          OTHERS                = 3.
*
*      CASE sy-subrc.
*        WHEN 0.
*          LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
*            MESSAGE ID lt_return-id TYPE lt_return-type
*                    NUMBER lt_return-number
*                    WITH lt_return-message_v1 lt_return-message_v2
*                         lt_return-message_v3 lt_return-message_v4.
*          ENDLOOP.
*
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH text-e01 l_sendsys.
*      ENDCASE.
*
**     Delete roles from local sytem
*      DELETE lt_roles WHERE subsystem = l_rcvsys.
*
*      IF sy-subrc = 0.
*        CALL FUNCTION 'BAPI_USER_LOCACTGROUPS_ASSIGN'
*          DESTINATION l_sendsys
*          EXPORTING
*            username              = users-bname
*          TABLES
*            activitygroups        = lt_roles
*            return                = lt_return
*          EXCEPTIONS
*            communication_failure = 1 MESSAGE l_system_msg
*            system_failure        = 2 MESSAGE l_system_msg
*            OTHERS                = 3.
*
*        CASE sy-subrc.
*          WHEN 0.
*            LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
*              MESSAGE ID lt_return-id TYPE lt_return-type
*                      NUMBER lt_return-number
*                      WITH lt_return-message_v1 lt_return-message_v2
*                           lt_return-message_v3 lt_return-message_v4.
*            ENDLOOP.
*
*          WHEN 1 OR 2.
*            MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*          WHEN 3.
*            MESSAGE e398(00) WITH text-e01 l_sendsys.
*        ENDCASE.
*      ENDIF.
*
**     Read profiles for local system
*      CALL FUNCTION 'BAPI_USER_LOCPROFILES_READ'
*        DESTINATION l_sendsys
*        EXPORTING
*          username              = users-bname
*        TABLES
*          profiles              = lt_profiles
*          return                = lt_return
*        EXCEPTIONS
*          communication_failure = 1 MESSAGE l_system_msg
*          system_failure        = 2 MESSAGE l_system_msg
*          OTHERS                = 3.
*
*      CASE sy-subrc.
*        WHEN 0.
*          LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
*            MESSAGE ID lt_return-id TYPE lt_return-type
*                    NUMBER lt_return-number
*                    WITH lt_return-message_v1 lt_return-message_v2
*                         lt_return-message_v3 lt_return-message_v4.
*          ENDLOOP.
*
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH text-e01 l_sendsys.
*      ENDCASE.
*
**     Delete profiles from local system
*      DELETE lt_profiles WHERE subsystem = l_rcvsys.
*
*      IF sy-subrc = 0.
*        CALL FUNCTION 'BAPI_USER_LOCPROFILES_ASSIGN'
*          DESTINATION l_sendsys
*          EXPORTING
*            username              = users-bname
*          TABLES
*            profiles              = lt_profiles
*            return                = lt_return
*          EXCEPTIONS
*            communication_failure = 1 MESSAGE l_system_msg
*            system_failure        = 2 MESSAGE l_system_msg
*            OTHERS                = 3.
*
*        CASE sy-subrc.
*          WHEN 0.
*            LOOP AT lt_return WHERE type = 'E' OR type = 'A'.
*              MESSAGE ID lt_return-id TYPE lt_return-type
*                      NUMBER lt_return-number
*                      WITH lt_return-message_v1 lt_return-message_v2
*                           lt_return-message_v3 lt_return-message_v4.
*            ENDLOOP.
*
*          WHEN 1 OR 2.
*            MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*          WHEN 3.
*            MESSAGE e398(00) WITH text-e01 l_sendsys.
*        ENDCASE.
*      ENDIF.
*
**     Remove local system
*      LOOP AT lt_systems WHERE subsystem <> l_rcvsys.
*        lt_upd_systems-subsystem = lt_systems-subsystem.
*        APPEND lt_upd_systems.
*      ENDLOOP.
*
**     Update user
*      CALL FUNCTION 'SUSR_ZBV_USER_SYSTEM_PUT' DESTINATION l_sendsys
*        EXPORTING
*          user                  = users-bname
*        TABLES
*          systems               = lt_upd_systems
*        EXCEPTIONS
*          communication_failure = 1 MESSAGE l_system_msg
*          system_failure        = 2 MESSAGE l_system_msg
*          OTHERS                = 3.
*
*      CASE sy-subrc.
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH text-e01 l_sendsys.
*      ENDCASE.
*
*      CALL FUNCTION 'SUSR_ZBV_USER_SYSTEM_SAVE' DESTINATION l_sendsys
*        EXCEPTIONS
*          communication_failure = 1 MESSAGE l_system_msg
*          system_failure        = 2 MESSAGE l_system_msg
*          OTHERS                = 3.
*
*      CASE sy-subrc.
*        WHEN 1 OR 2.
*          MESSAGE e398(00) WITH text-e01 l_sendsys l_system_msg.
*        WHEN 3.
*          MESSAGE e398(00) WITH text-e01 l_sendsys.
*      ENDCASE.
* Delete the system as per selection screen
      DELETE lt_systems WHERE subsystem = p_system.
      LOOP AT lt_systems.
        lt_upd_systems-subsystem = lt_systems-subsystem.
        APPEND lt_upd_systems.
      ENDLOOP.
* Assign updated systems to the user
      CALL FUNCTION 'BAPI_USER_SYSTEM_ASSIGN'
        DESTINATION l_sendsys
             EXPORTING
                  username  = users-bname
             TABLES
                  systems   = lt_upd_systems
                  return    = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
          WHEN 2.
            MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
          WHEN OTHERS.
            MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
        ENDCASE.
      ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
* If no system exists, delete the user
      IF lt_upd_systems IS INITIAL.
        CALL FUNCTION 'BAPI_USER_DELETE'
        DESTINATION l_sendsys
             EXPORTING
                  username = users-bname
             TABLES
                  return   = lt_return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
        IF sy-subrc <> 0.
          CASE sy-subrc.
            WHEN 1.
              MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
            WHEN 2.
              MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
            WHEN OTHERS.
              MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
          ENDCASE.
        ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
      ENDIF.
* EOC by RGUPTA on 1st Feb 2022
      users-action = 'USER_DELETED'.
      MODIFY users.
    ENDIF.

*-- Once user deleted not need to show other action in the output
*-- odubey B16612 10/06/2022
    DELETE users WHERE bname = users-bname AND
                       action <> 'USER_DELETED'.
  ENDLOOP.
ENDFORM.                    " USER_DELETE
*&---------------------------------------------------------------------*
*&      Form  init
*&---------------------------------------------------------------------*
FORM init.

*---C0634 Default nr days
  CLEAR swconfig.
  se_config_param 'DFLT_INACT_LOCK' swconfig-value.
  lockdays = swconfig-value.

  CLEAR swconfig.
  se_config_param 'DFLT_INACT_EXP' swconfig-value.
  valdays = swconfig-value.

  CLEAR swconfig.
  se_config_param 'DFLT_INACT_DEL' swconfig-value.
  deldays = swconfig-value.
  CLEAR swconfig.

  lockdate = sy-datum - lockdays.
  deldate = sy-datum - deldays.
  expdate = sy-datum - valdays.

  WRITE: deldate TO del_date.
  WRITE: lockdate TO lok_date.
  WRITE: expdate TO val_date.
ENDFORM.                    " init
*&---------------------------------------------------------------------*
*&      Form  change_catalog_texts
*&---------------------------------------------------------------------*
FORM change_catalog_texts.
  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.

  wa_fieldcat_alv-seltext_l = text-024.
  wa_fieldcat_alv-seltext_m = text-025.
  wa_fieldcat_alv-seltext_s = text-025.
  wa_fieldcat_alv-reptext_ddic = text-025.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ACTION'.

  wa_fieldcat_alv-seltext_l = text-026.
  wa_fieldcat_alv-seltext_m = text-026.
  wa_fieldcat_alv-seltext_s = text-026.
  wa_fieldcat_alv-reptext_ddic = text-026.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-seltext_l = text-003.
  wa_fieldcat_alv-seltext_m = text-003.
  wa_fieldcat_alv-seltext_s = text-003.
  wa_fieldcat_alv-reptext_ddic = text-003.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'USERTYP'.

  wa_fieldcat_alv-seltext_l = text-004.
  wa_fieldcat_alv-seltext_m = text-004.
  wa_fieldcat_alv-seltext_s = text-004.
  wa_fieldcat_alv-reptext_ddic = text-004.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'UTYPTEXT'.

  wa_fieldcat_alv-seltext_l = text-027.
  wa_fieldcat_alv-seltext_m = text-027.
  wa_fieldcat_alv-seltext_s = text-028.
  wa_fieldcat_alv-reptext_ddic = text-029.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CLASS'.

  wa_fieldcat_alv-seltext_l = text-030.
  wa_fieldcat_alv-seltext_m = text-030.
  wa_fieldcat_alv-seltext_s = text-031.
  wa_fieldcat_alv-reptext_ddic = text-031.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'TRDAT'.

  wa_fieldcat_alv-seltext_l = text-032.
  wa_fieldcat_alv-seltext_m = text-032.
  wa_fieldcat_alv-seltext_s = text-033.
  wa_fieldcat_alv-reptext_ddic = text-032.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ERDAT'.

  wa_fieldcat_alv-seltext_l = text-034.
  wa_fieldcat_alv-seltext_m = text-034.
  wa_fieldcat_alv-seltext_s = text-035.
  wa_fieldcat_alv-reptext_ddic = text-036.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'NAME'.

  wa_fieldcat_alv-seltext_l = text-037.
  wa_fieldcat_alv-seltext_m = text-037.
  wa_fieldcat_alv-seltext_s = text-037.
  wa_fieldcat_alv-reptext_ddic = text-037.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IDNAME'.

*SE3.5PS2 - Don't hide BNAME by default
*  CLEAR: wa_fieldcat_alv.
*  wa_fieldcat_alv-no_out = 'X'.
*  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
*                    TRANSPORTING
*                      no_out
*                   WHERE
*                      fieldname = 'BNAME'.
*SE3.5PS2 - Drill down to SU01 if user is authorized
  AUTHORITY-CHECK OBJECT 'S_TCODE'
           ID 'TCD' FIELD 'SU01'.
  IF sy-subrc = 0.
    CLEAR: wa_fieldcat_alv.
    wa_fieldcat_alv-hotspot = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        hotspot
                     WHERE
                        fieldname = 'BNAME'.
  ENDIF.


  CLEAR: wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'NAME'.
*BOC UMITTAL : PN-12417 German Language Translation
  CLEAR: wa_fieldcat_alv.
  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'SEL'.
*EOC UMITTAL : PN-12417 German Language Translation
  CLEAR: wa_fieldcat_alv.
  CLEAR wa_fieldcat_alv-key .
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                    key
                    WHERE
                      key = 'X'.


ENDFORM.                    " change_catalog_texts

*&---------------------------------------------------------------------*
*&      Form  fill_user_name
*&---------------------------------------------------------------------*
FORM fill_user_name.

  DATA: username TYPE STANDARD TABLE OF /psyng/bc_userid_name
        WITH HEADER LINE.
  DATA: lv_temp(82).


  LOOP AT users.
    username-bname = users-bname.
    APPEND username.
  ENDLOOP.

  CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
    EXPORTING
      no_email = 'X'
    TABLES
      username = username.

  LOOP AT users.
    READ TABLE username WITH KEY bname = users-bname BINARY SEARCH.
    CHECK sy-subrc = 0.
    users-name = username-name_full.

    CONCATENATE '(' username-name_full ')' INTO lv_temp.
    CONCATENATE users-bname lv_temp INTO users-idname SEPARATED BY space
.

    MODIFY users.
  ENDLOOP.

  REFRESH: username.

  WRITE lockcount TO lockcountc.
  WRITE delcount TO delcountc.
  WRITE expcount TO expcountc.

  SHIFT lockcountc LEFT  DELETING LEADING  '0'.
  SHIFT delcountc LEFT  DELETING LEADING  '0'.
  SHIFT expcountc LEFT DELETING LEADING '0'.
  IF expcountc IS INITIAL.
    expcountc = '0'.
  ENDIF.
  IF delcountc IS INITIAL.
    delcountc = '0'.
  ENDIF.
  IF lockcountc IS INITIAL.
    lockcountc = '0'.
  ENDIF.

  IF users[] IS INITIAL.
    MESSAGE s184(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM fill_init_selection                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM fill_init_selection.

*  DATA: l_repid   LIKE rsvar-report,
  DATA: l_repid   TYPE vari_reprt,
        l_variant LIKE rsvar-variant.

  DATA : lv_rprt TYPE vari_reprt.
  pbname-sign = 'E'. pbname-option = 'EQ'.
  pbname-low = 'SAP*'. APPEND pbname.

  pbname-sign = 'E'. pbname-option = 'EQ'.
  pbname-low = 'DDIC'. APPEND pbname.

  pbname-sign = 'E'. pbname-option = 'EQ'.
  pbname-low = 'SAPCPIC'. APPEND pbname.

  pbname-sign = 'E'. pbname-option = 'EQ'.
  pbname-low = 'WF-BATCH'. APPEND pbname.

  l_repid = sy-repid.
  l_variant = 'EXPIRE_DAYS'.
  SELECT SINGLE report FROM varid INTO lv_rprt WHERE
     report EQ l_repid
  AND variant EQ l_variant.                      "#EC SAST_CI_GEN_CHECK
  CHECK sy-subrc EQ 0.
  CALL FUNCTION 'RS_SUPPORT_SELECTIONS'
    EXPORTING
      report               = l_repid
      variant              = l_variant
    EXCEPTIONS
      variant_not_existent = 01
      variant_obsolete     = 02
      OTHERS               = 03.
*BOC:HBHALLA (04/12/24)
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Layout Does not Exist'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'Obsolete Variant'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (04/12/24)


ENDFORM.                    " LIST_EXCLUDED_OBJECTS
*&---------------------------------------------------------------------*
*&      Form  change_sel_screen_text
*&---------------------------------------------------------------------*
FORM change_sel_screen_text.
  lockdate = sy-datum - lockdays.
  expdate = sy-datum - valdays.
  deldate = sy-datum - deldays.

  WRITE lockdate TO lok_date.
  WRITE deldate TO del_date.
  WRITE expdate TO val_date.

ENDFORM.                    " change_sel_screen_text


*&---------------------------------------------------------------------*
*&      Form  check_Accidental_delete
*&---------------------------------------------------------------------*
*       Count the users to be deleted and ask user if this is OK
*----------------------------------------------------------------------*
FORM check_accidental_delete.
  DATA: lv_popup_ques(80),
        lf_missing_auth_ugroup TYPE /psyng/bapiflagx,
        i_include_locked       TYPE flag,
        i_include_expire       TYPE flag,
        lt_usr02               TYPE TABLE OF usr02 WITH HEADER LINE.
  CHECK delete =  'X'.
  CLEAR delcount.

  msg 'Check for accidental Deletion'(l01) '' '' '' .
*--local users
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
  IF p_system IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_041'
      EXPORTING
        i_validuser       = validusr
        i_include_locked  = i_include_locked
        i_include_expired = i_include_expire
      TABLES
        et_users          = lt_usr02
        it_userlist       = pbname
        it_grouplist      = pclass
        it_usertype       = usrtype
        it_actgroups      = s_role
        it_profile        = s_prof
        it_costcenter     = s_kostl
        it_company        = s_comp
        it_cuid           = s_cuid
        it_department     = s_dep
        it_secpolicy      = s_secpol.

  ELSE.
    CALL FUNCTION '/PSYNG/SW_041'
      DESTINATION p_system
      EXPORTING
        i_validuser           = validusr
        i_include_locked      = i_include_locked
        i_include_expired     = i_include_expire
      TABLES
        et_users              = lt_usr02
        it_userlist           = pbname
        it_grouplist          = pclass
        it_usertype           = usrtype
        it_actgroups          = s_role
        it_profile            = s_prof
        it_costcenter         = s_kostl
        it_company            = s_comp
        it_cuid               = s_cuid
        it_department         = s_dep
        it_secpolicy          = s_secpol
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0 .
      MESSAGE s398(00) WITH g_system_msg.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  LOOP AT lt_usr02.

    CLEAR: users.

*   Check license type
    SELECT SINGLE lic_type INTO users-usertyp FROM usr06
                  WHERE bname = lt_usr02-bname.
    IF NOT s_lictyp[] IS INITIAL.
      CHECK users-usertyp IN s_lictyp.
    ENDIF.


    IF lt_usr02-trdat IS INITIAL.  "user has never logged on
* creation older than delete
      IF lt_usr02-erdat LT deldate.
        ADD 1 TO delcount.
      ENDIF.
    ELSE.  "user has logged on at least once
* logon older than delete date
      IF lt_usr02-trdat LT deldate.
        ADD 1 TO delcount.
      ENDIF.
    ENDIF.
  ENDLOOP.

  CHECK delcount GE 1 AND sy-batch NE 'X'.

  CONCATENATE text-014 delcount text-015
              INTO lv_popup_ques SEPARATED BY space.
  DATA : l_answer.
  CALL FUNCTION 'POPUP_TO_CONFIRM'
    EXPORTING
      titlebar       = text-016
      text_question  = lv_popup_ques
      default_button = '2'
    IMPORTING
      answer         = l_answer
    EXCEPTIONS
      text_not_found = 1
      OTHERS         = 2.
*BOC:HBHALLA (04/12/24)
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw) WITH 'Diagnosis text not found'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (04/12/24)
*DHORIONS 2014/05/15 - Don't delete if user answers NO
  IF l_answer <> '1'.
    CLEAR delete.
  ENDIF.
ENDFORM.                    " check_accidental_delete
*&---------------------------------------------------------------------*
*&      Form  user_expire
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM user_expire.

  DATA: lv_logondata  LIKE bapilogond,
        yesterday     LIKE sy-datum,
        lv_logondatax LIKE bapilogonx,
        ls_usrfldtsel LIKE LINE OF gt_usrfldtsel,
        l_dest        TYPE rfcdest.


  yesterday = sy-datum - 1.
  REFRESH: return.

  IF g_cua_active = 'Y'.
    READ TABLE gt_usrfldtsel INTO ls_usrfldtsel
    WITH KEY log_field = 'LOGONDATA_VALID'.
  ENDIF.
*---C0383 For cua
*-- if cua is active and set as globle then take cua host
*-- as rfc and ignore entered rfc
  IF g_cua_active = 'Y' AND ls_usrfldtsel-uflag = 'G'.
    l_dest = g_sendsystem.
  ELSE.
    l_dest = p_system.
  ENDIF.

  LOOP AT users WHERE action = 'TO_BE_EXPIRED'.
    REFRESH: return.
    IF NOT l_dest IS INITIAL.
      CALL FUNCTION 'BAPI_USER_GET_DETAIL'
        DESTINATION l_dest
        EXPORTING
          username              = users-bname
        IMPORTING
          logondata             = lv_logondata
        TABLES
          return                = return
        EXCEPTIONS
          communication_failure = 1 MESSAGE g_system_msg
          system_failure        = 2 MESSAGE g_system_msg
          OTHERS                = 3.             "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        MESSAGE e002(/psyng/sw) WITH g_system_msg.
      ENDIF.

      CHECK return[] IS INITIAL.   "no errors while reading

      lv_logondata-gltgb = yesterday.
      lv_logondatax-gltgb = 'X'.

*---if usr group parameter checked, update the user group
      IF p_ugexp = 'X'.
        lv_logondata-class = p_expgrp.
        lv_logondatax-class = 'X'.
      ENDIF.

      REFRESH: return.
      CALL FUNCTION 'BAPI_USER_CHANGE'
        DESTINATION l_dest
        EXPORTING
          username   = users-bname
          logondata  = lv_logondata
          logondatax = lv_logondatax
        TABLES
          return     = return
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        CASE sy-subrc.
          WHEN 1.
            MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
          WHEN 2.
            MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
          WHEN OTHERS.
            MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
        ENDCASE.
      ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025

    ELSE.
*---non cua
      CALL FUNCTION 'BAPI_USER_GET_DETAIL'
        EXPORTING
          username  = users-bname
        IMPORTING
          logondata = lv_logondata
        TABLES
          return    = return.

      CHECK return[] IS INITIAL.   "no errors while reading

      lv_logondata-gltgb = yesterday.
      lv_logondatax-gltgb = 'X'.

*---if usr group parameter checked, update the user group
      IF p_ugexp = 'X'.
        lv_logondata-class = p_expgrp.
        lv_logondatax-class = 'X'.
      ENDIF.

      REFRESH: return.
      CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
        EXPORTING
          username   = users-bname
          logondata  = lv_logondata
          logondatax = lv_logondatax
        TABLES
          return     = return.
    ENDIF.
    LOOP AT return WHERE number = '039'.
      users-action = 'USER_EXPIRED'.
      MODIFY users.
      EXIT.
    ENDLOOP.
  ENDLOOP.
ENDFORM.                    " user_expire
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
        lt_data    LIKE TABLE OF ls_data,
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
    AND b~ddlanguage = sy-langu.                 "#EC SAST_CI_GEN_CHECK

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
      AND b~ddlanguage = 'EN'.                   "#EC SAST_CI_GEN_CHECK
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
*BOC:HBHALLA (04/12/24)
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Incorrect parameter'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'No values found'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (04/12/24)

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
  DATA: lt_header     TYPE slis_t_listheader,
        wa            TYPE slis_listheader,
        lv_count      TYPE i,
        lv_exetime(8) TYPE c,
        lv_exedate    TYPE char10,
        lv_temp(90),
        alv_grid_titl TYPE lvc_title,
        l_sysid TYPE /psyng/sysid,
        l_rfc TYPE rfcdest.
*--Title
  alv_grid_titl = 'User Inactivity Status'(000).
  wa-typ = 'H'.
  wa-info = alv_grid_titl.
  APPEND wa TO lt_header.
*--User & Date
  wa-typ = 'S'.
  wa-key = 'User & Date'(h03).
  WRITE sy-datum TO lv_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO lv_exetime SEPARATED BY ':'.
  CONCATENATE g_current_user "sy-uname C0700
   text-h04 lv_exedate lv_exetime
              INTO wa-info SEPARATED BY space.
  APPEND wa TO lt_header.

*---System
  SELECT SINGLE systid INTO l_sysid FROM
    /psyng/sw_rfcdes WHERE rfcdest = p_system.

  IF sy-subrc <> 0 AND p_system IS INITIAL.
    CONCATENATE sy-sysid sy-mandt INTO l_sysid.
  ELSE.
    CALL FUNCTION '/PSYNG/SW_062'
     DESTINATION p_system
     IMPORTING
       e_rfcdest       = l_rfc
    EXCEPTIONS
     communication_failure  =  1 MESSAGE g_system_msg
      system_failure        = 2 MESSAGE g_system_msg
      OTHERS                = 3.                 "#EC SAST_CI_GEN_CHECK
    IF sy-subrc = 0.
      l_sysid = l_rfc.
    ENDIF.
  ENDIF.
  wa-typ = 'S'.
  wa-key = 'System'.
  wa-info = l_sysid.
  APPEND wa TO lt_header.

  wa-typ = 'S'.
  wa-key = 'Users to Lock'(l00).
  wa-info = lockcountc.
  APPEND wa TO lt_header.
*--Expire
  wa-typ = 'S'.
  wa-key = 'Users to Expire'(001).
  wa-info = expcountc.
  APPEND wa TO lt_header.
*--Delete
  wa-typ = 'S'.
  wa-key = 'Users to Delete'(002).
  wa-info = delcountc.
  APPEND wa TO lt_header.




  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  IGNORE_RECENT_UNLOCKED_OR_VAL_
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_LT_USR02  text
*----------------------------------------------------------------------*
FORM ignore_recent_changed_usr
TABLES et_usr02 STRUCTURE gs_usr02.

  DATA : lt_bname   TYPE TABLE OF /psyng/range_bname WITH HEADER LINE,
         lt_changes TYPE TABLE OF /psyng/er_usrmaster_changes
                    WITH HEADER LINE,
         l_ul_date  TYPE dats,
         l_vc_date  TYPE dats,
         l_date     TYPE dats,
         lf_ignore  TYPE flag,
         l_uflag_n  TYPE x,
         l_uflag_o  TYPE x,
         lt_range_tcode TYPE TABLE OF /psyng/range_tcode,
         ls_range_tcode TYPE /psyng/range_tcode.
  FIELD-SYMBOLS :
         <usr02>    TYPE typ_usr02.
  CHECK NOT ig_ul IS INITIAL OR NOT ig_vc IS INITIAL.
*TODO - call /PSYNG/BC_USRHIS_35 to check if users recently changed.
  lt_bname-sign   = 'I'.
  lt_bname-option = 'EQ'.

  LOOP AT et_usr02 ASSIGNING <usr02>.
    lt_bname-low = <usr02>-bname.
    APPEND lt_bname.
  ENDLOOP.

*--Check for changes to user master for users in scope
*  after the earliest of the two provided dates
  l_date = sy-datum.
  IF ig_ul = 'X'.
    l_ul_date = sy-datum - uldays.
    l_date = l_ul_date.
  ENDIF.
  IF ig_vc = 'X'.
    l_vc_date = sy-datum - vcdays.
    IF l_vc_date < l_date.
      l_date = l_vc_date.
    ENDIF.
  ENDIF.

*--Get User Master Change History corresponding to SU01 tcode
  CLEAR ls_range_tcode.
  ls_range_tcode-sign   = 'I'.
  ls_range_tcode-option = 'EQ'.
  ls_range_tcode-low    = 'SU01'.
  APPEND ls_range_tcode to lt_range_tcode.

*--Get User Master Change History corresponding to SU10 tcode
  CLEAR ls_range_tcode-low.
  ls_range_tcode-low    = 'SU10'.
  APPEND ls_range_tcode to lt_range_tcode.

*--Get User Master Change History corresponding to /PSY tcode
  CLEAR ls_range_tcode-low.
  ls_range_tcode-low    = '/PSY'.
  APPEND ls_range_tcode to lt_range_tcode.

*--Find the changes in the User Master Change History
  IF p_system IS INITIAL.
    CALL FUNCTION '/PSYNG/BC_USRHIS_35'
      EXPORTING
        i_start_date     = l_date
        i_start_time     = '000000'
        i_end_date       = sy-datum
        i_end_time       = sy-uzeit
        i_check_header   = 'X'
      TABLES
        it_bname_changed = lt_bname
        et_changes       = lt_changes
        it_tcode         = lt_range_tcode.

  ELSE.
    CALL FUNCTION '/PSYNG/BC_USRHIS_35'
    DESTINATION p_system
    EXPORTING
      i_start_date     = l_date
      i_start_time     = '000000'
      i_end_date       = sy-datum
      i_end_time       = sy-uzeit
      i_check_header   = 'X'
    TABLES
      it_bname_changed = lt_bname
      et_changes       = lt_changes
      it_tcode         = lt_range_tcode
      EXCEPTIONS
        communication_failure = 1 MESSAGE g_system_msg
        system_failure        = 2 MESSAGE g_system_msg
        OTHERS                = 3.               "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0 .
      MESSAGE s398(00) WITH g_system_msg.
      LEAVE LIST-PROCESSING.
    ENDIF..
  ENDIF.

*--Remove irrelevant changes
  DELETE lt_changes WHERE   tabname <> 'USR02' OR
                          ( fname   <> 'UFLAG' AND
                            fname   <> 'GLTGB' AND
                            fname   <> 'GLTGV' ). "#EC SAST_CI_GEN_CHECK
*HBHALLA: Only using usr02 as a critria value, so no fix needed.


  LOOP AT lt_changes.
    CLEAR lf_ignore.
*--Check for unlocked users
    IF ig_ul = 'X'.
      IF lt_changes-fname = 'UFLAG'.
        CONDENSE lt_changes-value_new.
        CONDENSE lt_changes-value_old.
        MOVE lt_changes-value_new TO l_uflag_n.
        MOVE lt_changes-value_old TO l_uflag_o.
*--Old status was locked and new status is unlocked
        IF ( l_uflag_o O yusloc OR "locked by admin
             l_uflag_o O yugloc   "locked by CUA admin
            )
            AND NOT
           (
             l_uflag_n O yusloc OR "locked by admin
             l_uflag_n O yugloc   "locked by CUA admin
           ).
          lf_ignore = 'X'.
        ENDIF.
      ENDIF.
    ENDIF.
*--Check for users with changed validity
    IF ig_vc = 'X' AND NOT lf_ignore = 'X'.
      IF ( lt_changes-fname = 'GLTGV' OR
           lt_changes-fname = 'GLTGB' )
           AND
         ( lt_changes-value_old <> lt_changes-value_new ) .
        lf_ignore = 'X'.
      ENDIF.
    ENDIF.
    IF lf_ignore = 'X'.
      DELETE et_usr02 WHERE bname = lt_changes-tabkey.
    ENDIF.
  ENDLOOP.
ENDFORM.                    " IGNORE_RECENT_UNLOCKED_OR_VAL_
FORM get_users_count.
  DATA : l_numb      TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local    TYPE flag VALUE 'X',
         lt_usrrfc   TYPE TABLE OF /psyng/sw_sel_opts_rfcdest
                     WITH HEADER LINE.

  IF exlckusr EQ 'X'.
    CLEAR lv_exlckusr.
  ELSEIF exlckusr IS INITIAL.
    lv_exlckusr = 'X'.
  ENDIF.

  IF outvdate EQ 'X'.
    CLEAR lv_outvdate.
  ELSEIF outvdate IS INITIAL.
    lv_outvdate = 'X'.
  ENDIF.

*---pass rfc
  IF NOT p_system IS INITIAL.
    lt_usrrfc-sign = 'I'.
    lt_usrrfc-option = 'EQ'.
    lt_usrrfc-low = p_system.
    APPEND lt_usrrfc.
  ENDIF.

  CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
    EXPORTING
      i_validuser       = validusr
      i_include_locked  = lv_exlckusr
      i_include_expired = lv_outvdate
      if_local_system   = lv_local
      if_show_message   = 'X'
    IMPORTING
      e_usercount       = l_numb
    TABLES
      it_userlist       = pbname
      it_grouplist      = pclass
      it_usertype       = usrtype
      it_actgroups      = s_role
      it_profile        = s_prof
     it_rfcrange        = lt_usrrfc
*     IT_RFCLIST        =
     it_department     = s_dep
     it_company        = s_comp
     it_cuid           = s_cuid
     it_costcenter     = s_kostl
     it_secpolicy      = s_secpol.

ENDFORM.                    " get_users_count
*&---------------------------------------------------------------------*
*&      Form  RFC_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations .
  DATA: lr_rfcs    TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER
  LINE,
        l_continue TYPE flag,
        lt_bapiret TYPE TABLE OF bapiret2.
*  APPEND LINES OF s_system TO lr_rfcs.
  lr_rfcs-sign = 'I'. lr_rfcs-option = 'EQ'.
  lr_rfcs-low = p_system.
  APPEND lr_rfcs.

  DELETE lr_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
    EXPORTING
      i_popup    = 'X'
      i_module   = 'SE'
    IMPORTING
      e_continue = l_continue
    TABLES
      it_rfcdes  = lr_rfcs.
  IF  l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.

FORM get_scum_settings.

*----Check if cua is active

  CALL FUNCTION '/PSYNG/BC_002'
    IMPORTING
      e_cua_active = g_cua_active
      e_modelname  = g_modelname
      e_sendsystem = g_sendsystem
      e_rcvsystem  = g_rcvsystem.

  IF g_cua_active  = 'Y'.
* Fetch SCUM Data for LOGON Data
    msg '-->Reading SCUM Settings...'(l06) '' '' '' .
    REFRESH: gt_usrfldtsel.
    CALL FUNCTION 'SUSR_ZBV_FLD_SELECT'
      EXPORTING
        custmodel     = g_modelname
        fieldgroup    = 'LOGONDATA'
      TABLES
        it_usrfldtsel = gt_usrfldtsel.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  SCHEDULE_BACK_JOB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM schedule_back_job .
  DATA: l_jobname   TYPE btcjob.
  CLEAR: g_program, g_curr_variant.
  PERFORM create_variant_from_sel.
  g_program = sy-repid.
  g_curr_variant = g_variant.
  l_jobname = g_program .
  CALL FUNCTION '/PSYNG/SW_SCHEDULE_BACK_JOB'
    EXPORTING
      in_jobname  = l_jobname
      in_repvarnt = g_curr_variant
      in_report   = g_program.
  IF sy-subrc <> 0.
    CALL SCREEN 1000.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CREATE_VARIANT_FROM_SEL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM create_variant_from_sel .
  DATA: curr_report LIKE rsvar-report.
  PERFORM get_next_variant_id.
  PERFORM fill_sel_screen_fields_to_tab.
  curr_report = sy-repid.
  g_curr_variant = g_variant.

  CALL FUNCTION 'RS_CREATE_VARIANT'
    EXPORTING
      curr_report   = curr_report
      curr_variant  = g_curr_variant
      vari_desc     = g_vari_desc
    TABLES
      vari_contents = g_vari_contents
      vari_text     = g_vari_text
"(++)BOC UMITTAL SE VF scan-25/11/2024.
       EXCEPTIONS
          illegal_report_or_variant = 1
          illegal_variantname = 2
          not_authorized = 3
          not_executed = 4
          report_not_existent = 5
          report_not_supplied = 6
          variant_exists = 7
          variant_locked = 8
          OTHERS = 9.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  "(++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  GET_NEXT_VARIANT_ID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_next_variant_id .
  CLEAR: g_variant, g_vari_desc.
  REFRESH: g_vari_desc.
  CALL FUNCTION '/PSYNG/BASIS_GET_RPT_VARIANT'
    EXPORTING
      i_report        = sy-repid
   IMPORTING
     e_variant       = g_variant.

  g_vari_desc-report = sy-repid.
  g_vari_desc-variant = g_variant.
  APPEND g_vari_desc.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  FILL_SEL_SCREEN_FIELDS_TO_TAB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_sel_screen_fields_to_tab .
  REFRESH : gt_irsparams[].
  CALL FUNCTION '/PSYNG/BASIS_JOB_LOG_PARAMS'
    EXPORTING
      i_repid       = g_program
      if_no_logging = 'X'
    TABLES
      et_params     = gt_irsparams.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_COMPANY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0459   text
*      <--P_S_COMP_LOW  text
*----------------------------------------------------------------------*
FORM f4_company  USING     fieldname
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
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro    = l_dynnr
      i_dynpprog  = l_repid
      i_fieldname = fieldname
    CHANGING
      e_company   = e_comp.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_DEPARTMENT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0483   text
*      <--P_S_DEP_LOW  text
*----------------------------------------------------------------------*
FORM f4_department  USING    fieldname
                    CHANGING e_department.
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
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_COMPANY_SHLP_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ENDIF.
  ELSE.
    ls_fmname = '/PSYNG/SW_077'.
  ENDIF.

  l_repid = sy-repid.
  l_dynnr = sy-dynnr.
  CALL FUNCTION ls_fmname                    "#EC PATHLOCK_CI_DYN_ACCES
    EXPORTING
      i_dynpro     = l_dynnr
      i_dynpprog   = l_repid
      i_fieldname  = fieldname
    CHANGING
      e_department = e_department.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INPUT_FIELDS_VALIDATIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM input_fields_validations .
  DATA: ls_usgroup TYPE usgrp,
        l_validgroup TYPE flag.

  DEFINE validate_group.
    l_validgroup = 'X'.
    select single * from usgrp into ls_usgroup
      where USERGROUP = &1.
      if sy-subrc <> 0.
        clear l_validgroup.
        endif.
  END-OF-DEFINITION.

*--check if report is running for local system
  IF p_system IS INITIAL.
    IF p_uglck = 'X'.
      validate_group p_lckgrp.
      IF l_validgroup IS INITIAL.
        MESSAGE w140 WITH text-201.
        STOP.
      ENDIF.
    ENDIF.

    IF p_ugexp = 'X'.
      validate_group p_expgrp.
      IF l_validgroup IS INITIAL.
        MESSAGE w140 WITH text-201.
        STOP.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DIR_SELECT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM dir_select .
  DATA : l_file_path TYPE rlgrap-filename.
  l_file_path = basepath.


  DATA : l_uaction   TYPE i,
         l_title     TYPE string,
         l_filetable TYPE  filetable,
         l_def_fname TYPE string,
         l_init_dir  TYPE string.


  l_title = 'Open'(043).
  g_folder = basepath.
  CALL METHOD cl_gui_frontend_services=>directory_browse
                                       "#EC SAST_CI_GEN_CHECK (HBHALLA)
    EXPORTING
      window_title    = l_title
      initial_folder  = g_folder
    CHANGING
      selected_folder = g_folder
    EXCEPTIONS
      cntl_error      = 1
      error_no_gui    = 2
      OTHERS          = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  CALL METHOD cl_gui_cfw=>flush
    EXCEPTIONS
      cntl_system_error = 1
      cntl_error        = 2
      OTHERS            = 3.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
               WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

  basepath  = g_folder  .
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DOWNLOAD_OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM download_output .

  DATA: l_filename        TYPE string,
          l_err_mess      TYPE bapiret2-message,
          l_msgv1         TYPE bapiret2-message_v1,
          l_msgv2         TYPE bapiret2-message_v2,
          l_download_size TYPE i,
          l_msg(200)      TYPE c,
          l_text(10)      TYPE c,
          v_file TYPE string,
          v_dir TYPE string,
          l_extention TYPE string,
          wa_usrs LIKE LINE OF users.

  DATA: BEGIN OF lt_usr_down OCCURS 0,
        bname LIKE usr02-bname,   "user ID
        idname(95), "Userid and name
        usertyp(12) TYPE c,
        utyptext LIKE tutyp-utyptext,  "License type description
         class LIKE usr02-class,   "user group
          action(20),               "action
          trdat(10) TYPE c,   "logon date
          erdat(13) TYPE c,   "creation date
        END OF lt_usr_down.

  SPLIT basepath AT '.' INTO l_filename l_extention.

  IF l_extention NP '*xls' OR l_extention = '*xlsx'.
    MESSAGE s113 WITH 'Invalid Format'(s02).
    LEAVE LIST-PROCESSING.
  ENDIF.

  IF NOT users[] IS INITIAL.
*---header
    lt_usr_down-bname = 'User ID'(h01).
    lt_usr_down-idname  = 'User Name'(h02).
    lt_usr_down-usertyp = 'License Type'(h13).
    lt_usr_down-utyptext = 'License Description'(h14).
    lt_usr_down-class  = 'User Group'(h15).
    lt_usr_down-action = 'Action on User ID'(h06).
    lt_usr_down-trdat = 'Logon Date'(h07).
    lt_usr_down-erdat = 'Creation Date'(h08).
    APPEND lt_usr_down.

    LOOP AT users.
      MOVE-CORRESPONDING users TO lt_usr_down.
      WRITE users-trdat TO   lt_usr_down-trdat.
      WRITE users-erdat TO lt_usr_down-erdat.
      APPEND lt_usr_down.
    ENDLOOP.

    CONCATENATE l_filename '.' l_extention INTO l_filename.
    CLEAR l_download_size.
*BOC:HBHALLA (096)
    AUTHORITY-CHECK OBJECT  'S_GUI'
                     ID      'ACTVT'
                     FIELD   '61'.
    IF sy-subrc = 0.
      CALL FUNCTION 'GUI_DOWNLOAD'               "#EC SAST_CI_GEN_CHECK
        EXPORTING
          filename                = l_filename
          filetype                = 'ASC'
          write_field_separator   = 'X'
          dat_mode                = ' '
        IMPORTING
          filelength              = l_download_size
        TABLES
          data_tab                = lt_usr_down
        EXCEPTIONS
          file_write_error        = 1
          no_batch                = 2
          gui_refuse_filetransfer = 3
          invalid_type            = 4
          no_authority            = 5
          unknown_error           = 6
          header_not_allowed      = 7
          separator_not_allowed   = 8
          filesize_not_allowed    = 9
          header_too_long         = 10
          dp_error_create         = 11
          dp_error_send           = 12
          dp_error_write          = 13
          unknown_dp_error        = 14
          access_denied           = 15
          dp_out_of_memory        = 16
          disk_full               = 17
          dp_timeout              = 18
          file_not_found          = 19
          dataprovider_exception  = 20
          control_flush_error     = 21
          OTHERS                  = 22.

      IF sy-subrc <> 0.
        l_msgv1          = l_filename.
        l_msgv2          = 'Inactive users'(s03).
        CALL FUNCTION '/PSYNG/BC_003'
          EXPORTING
            i_subrc     = sy-subrc
            i_msgty     = 'I'
            i_msgv1     = l_msgv1
            i_msgv2     = l_msgv2
            if_no_popup = 'X'
          IMPORTING
            e_message   = l_err_mess.

        MESSAGE s113 WITH l_err_mess.
      ELSE.
        MESSAGE s113 WITH 'Inactive users output downloaded'(s01).
      ENDIF.
    ENDIF.
*EOC:HBHALLA (096)
    FREE lt_usr_down.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  APPLY_ACTIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM apply_actions .
  DATA : l_fld TYPE string.
  FIELD-SYMBOLS <g_grid> TYPE REF TO cl_gui_alv_grid.
  "BOC UMITTAL 24-09-2024
*    PERFORM user_lock.
*    PERFORM user_expire.
*    PERFORM user_delete.
  IF l_no_lock_del_chg EQ 'X'.
    MESSAGE s002(/psyng/sw) WITH 'You have only display access'.
  ELSEIF l_del_chg EQ 'X'.
    PERFORM user_expire.
    PERFORM user_delete.
    MESSAGE s002(/psyng/sw)
     WITH 'Only EXPIRE and DELETE selected users'.
  ELSEIF l_lock_del EQ 'X'.
    PERFORM user_lock.
    PERFORM user_delete.
    MESSAGE s002(/psyng/sw) WITH 'Only LOCK and DELETE selected users'.
  ELSEIF l_lock_chg EQ 'X'.
    PERFORM user_lock.
    PERFORM user_expire.
    MESSAGE s002(/psyng/sw) WITH 'Only LOCK and EXPIRE selected users'.
  ELSEIF l_chg EQ 'X'.
    PERFORM user_expire.
    MESSAGE s002(/psyng/sw) WITH 'User can only expire selected users'.
  ELSEIF l_del EQ 'X'.
    PERFORM user_delete.
    MESSAGE s002(/psyng/sw) WITH 'User can perform only Delete action'.
  ELSEIF l_lock EQ 'X'.
    PERFORM user_lock.
* Refresh the grid with the new data
    MESSAGE s002(/psyng/sw) WITH 'User can perform only Lock action'.
  ELSEIF l_lock_del_chg  EQ 'X'.
    PERFORM user_delete.
    PERFORM user_lock.
    PERFORM user_expire.
  ENDIF.
  "EOC UMITTAL 24-09-2024
*  PERFORM display_action_log.
ENDFORM.

FORM send_email.

  DATA :
  l_send_templ TYPE thead-tdname,
  l_css_temp TYPE dokhl-object,
  lt_headers TYPE TABLE OF /psyng/bc_tab_headers WITH HEADER LINE,
  l_subject TYPE so_obj_des,
  lt_htmlt TYPE /psyng/bc_html_data_t ,
  ls_htmlt TYPE /psyng/bc_html_data,
  lt_email_cont TYPE TABLE OF solisti1,
  ls_email_cont TYPE solisti1,
  l_tabstyle TYPE sylisel,
  lt_receivers TYPE TABLE OF /psyng/bc_userid_name
                    WITH HEADER LINE,
  l_central_sys   TYPE /psyng/param_value,
  l_systems TYPE string,
  l_man_change TYPE string,
  l_tabtitle TYPE text300,
  lt_adresses TYPE TABLE OF ad_smtpadr WITH HEADER LINE,
  lt_users_email LIKE TABLE OF users WITH HEADER LINE,
  l_actions TYPE string,
  l_action_str TYPE string,
  l_mandt TYPE sy-mandt,
  l_sysid TYPE sy-sysid,
  l_system TYPE rfcdest,
  l_email_count TYPE i,
  l_email_cnt_str TYPE string.

  DEFINE add_placeholder.
    ls_htmlt-placeholder = &1.
    ls_htmlt-text        = &2.
    append ls_htmlt to lt_htmlt.
  END-OF-DEFINITION.

*--Get configuration parameters
  se_config_param 'APPROVAL_CENTRAL_SYS'    l_central_sys.
  se_config_param 'SW_CSS_EMAIL' l_css_temp.
  se_config_param 'SW_USR_INACTIV_EMAIL' l_send_templ.

  lt_users_email[] = users[].
  IF in_lcd IS INITIAL.
    DELETE lt_users_email WHERE action ='TO_BE_LOCKED'.
  ENDIF.

  IF in_exp IS INITIAL.
    DELETE lt_users_email WHERE action ='TO_BE_EXPIRED'.
  ENDIF.

  IF in_del IS INITIAL.
    DELETE lt_users_email WHERE action ='TO_BE_DELEtED'.
  ENDIF.

*---keep only unique users to send email
  SORT lt_users_email BY bname.
  DELETE ADJACENT DUPLICATES FROM lt_users_email COMPARING bname.

*---take the system information
  CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION p_system
   IMPORTING
     e_rfcdest       = l_system
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
      WHEN 2.
        MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
      WHEN OTHERS.
        MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
    ENDCASE.
  ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
  IF NOT l_system IS INITIAL.
    l_mandt = l_system+3(3).                     "#EC SAST_CI_GEN_CHECK
    l_sysid = l_system+0(3).
  ENDIF.
  DATA: l_action_count TYPE i.
  CLEAR l_email_count.
  LOOP AT lt_users_email.
*---check for multiple actions

    LOOP AT users WHERE bname = lt_users_email-bname.
      ADD 1 TO l_action_count.
      CASE users-action.
        WHEN 'TO_BE_LOCKED'.
          l_action_str = 'Locked'(a01).
        WHEN 'TO_BE_EXPIRED'.
          l_action_str = 'Expired'(a02).
        WHEN 'TO_BE_DELETED'.
          l_action_str = 'Deleted'(a03).
      ENDCASE.

*      CONCATENATE  l_actions '[' l_action_str ']' INTO
*          l_actions SEPARATED BY space.
      IF l_action_count > 1.
        CONCATENATE  l_actions ',' l_action_str  INTO
            l_actions SEPARATED BY space.
      ELSE.
        l_actions = l_action_str.
      ENDIF.

    ENDLOOP.
    CLEAR l_action_count.
*--Add the placeholders
    add_placeholder :
        '[S:FULLNAME]'               lt_users_email-name,
        '[S:ACTION]'                 l_actions,
        '[S:SYS_ID]'                 l_sysid,
        '[S:CLIENT]'                 l_mandt,
        '[S:USERID]'                 lt_users_email-bname.

*--Create the HTML e-mail, but don't send it
    REFRESH : lt_receivers.
    lt_receivers-bname = lt_users_email-bname.
    APPEND lt_receivers.

    CALL FUNCTION '/PSYNG/BC_HTML_EMAIL'
       EXPORTING
            header        = 'X'
            style         = l_css_temp
            template_name = l_send_templ
            auto_subject  = 'X'
            if_send_email = ''  "don't send the e-mail
       IMPORTING
            e_subject     = l_subject
       TABLES
            et_data       = lt_email_cont
            it_recipients = lt_receivers
       CHANGING
            it_data       = lt_htmlt.


    CALL FUNCTION '/PSYNG/BC_GET_USER_NAME'
    DESTINATION p_system
   EXPORTING
     no_email = ' '
   TABLES
     username = lt_receivers
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            system_failure = 1
            communication_failure = 2
            OTHERS = 3.                          "#EC SAST_CI_GEN_CHECK
    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1.
          MESSAGE e002(/psyng/sw) WITH 'System failure'(z02).
        WHEN 2.
          MESSAGE e002(/psyng/sw) WITH 'Communication failure'(z01).
        WHEN OTHERS.
          MESSAGE e002(/psyng/sw) WITH 'Unknown Error'(z03).
      ENDCASE.
    ENDIF.

*EOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
    READ TABLE lt_receivers INDEX 1.
    MOVE lt_receivers-smtp_addr TO lt_adresses.
    APPEND  lt_adresses.

    IF NOT lt_adresses[] IS INITIAL
*BOC UMITTAL PN11390 : check if email id is avlbl or not 11/07/2025
      AND NOT lt_receivers-smtp_addr IS INITIAL.
*EOC UMITTAL PN11390 : check if email id is avlbl or not 11/07/2025
      CALL FUNCTION '/PSYNG/BC_036'
      DESTINATION l_central_sys
      EXPORTING
         i_subject                        = l_subject
         i_sensitivity                    = ''
         i_receiver                       = lt_adresses
        TABLES
          lt_body                         = lt_email_cont
       EXCEPTIONS
         error_sending_email              = 1
         too_many_receivers               = 2
         document_not_sent                = 3
         document_type_not_exist          = 4
         operation_no_authorization       = 5
         parameter_error                  = 6
         x_error                          = 7
         enqueue_error                    = 8
         system_failure = 9
         communication_failure = 10
         OTHERS               = 11.              "#EC SAST_CI_GEN_CHECK
      IF sy-subrc <> 0.
        IF sy-subrc = 7.
          MESSAGE s002(/psyng/sw) WITH
       'Email is not maintained in user master for user: '(t24)
          lt_users_email-bname.
          CONTINUE.
        ELSE.
          MESSAGE e002(/psyng/sw) WITH
         'Sending E-mail failed. /PSYNG/BC_036 - subrc = '(t11) sy-subrc
         'for analyzed system'(t13).
        ENDIF.
*BOC UMITTAL PN11390:Add count for valid emails sent
      ELSE.
        ADD 1 TO l_email_count.
*EOC UMITTAL PN11390:Add count for valid emails sent
      ENDIF.
*BOC UMITTAL PN11390 : check if email id is avlbl or not 11/07/2025

    ELSE.
      MESSAGE s002(/psyng/sw) WITH
     'Email is not maintained in user master for user: '(t24)
        lt_users_email-bname.
*EOC UMITTAL PN11390 : check if email id is avlbl or not 11/07/2025

    ENDIF.
    REFRESH : lt_email_cont,lt_adresses,lt_receivers,lt_htmlt.
    CLEAR: lt_receivers, l_subject, l_subject, l_actions.
*    ADD 1 TO l_email_count."(--)UMITTAL PN11390:do not count all
*emails
  ENDLOOP.
  l_email_cnt_str = l_email_count.
  IF l_email_count > 0.
    MESSAGE s002(/psyng/sw) WITH 'E-Mail sent to valid User Ids'(t12).
  ENDIF.
*  msg '--->Emails sent to:'(l08) expcount 'Users.'(l09) '' .
  msg '--->Emails sent to:'(l08) l_email_count 'Users.'(l09) '' .
  FREE : lt_users_email.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  DISPLAY_ACTION_LOG
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM display_action_log .
  RANGES lr_action FOR users-action.
  DATA: ls_action LIKE LINE OF lr_action,
        lt_usr_log LIKE TABLE OF users WITH HEADER LINE,
        program       LIKE sy-repid,
        alv_layout    TYPE slis_layout_alv,
        alv_grid_titl TYPE lvc_title,
        wa_alv TYPE slis_fieldcat_alv.
*-- log should be the records which are already processed and only
*--when you click on apply actions button
  ls_action-sign = 'I'. ls_action-option = 'EQ'.
  ls_action-low = 'USER_EXPIRED'.
  APPEND ls_action TO lr_action.

  ls_action-low = 'USER_LOCKED'.
  APPEND ls_action TO lr_action.

  ls_action-low = 'USER_DELETED'.
  APPEND ls_action TO lr_action.

  LOOP AT users WHERE action IN lr_action.
    MOVE-CORRESPONDING users TO lt_usr_log.
    APPEND lt_usr_log.
    DELETE users.
  ENDLOOP.
  SORT: lt_usr_log BY action DESCENDING bname.
*--hide other fields
  wa_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_alv
                      TRANSPORTING
                        no_out
                     WHERE
                        fieldname = 'SEL' OR
                        fieldname = 'USERTYP' OR
                        fieldname = 'UTYPTEXT' OR
                        fieldname = 'CLASS' OR
                        fieldname = 'TRDAT' OR
                        fieldname = 'ERDAT'.
  program = sy-repid.
  alv_grid_titl = 'List of Locked/Expired/Deleted Users'(H05).
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
      EXPORTING
        i_grid_title            = alv_grid_titl
        i_callback_program      = program
        is_layout               = alv_layout
        it_fieldcat             = i_fieldcat_alv
        i_save                  = 'A'
      TABLES
        t_outtab                = lt_usr_log
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
  "(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  F4_CENTRAL_UID
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0757   text
*      <--P_S_CUID_LOW  text
*----------------------------------------------------------------------*
FORM f4_central_uid  USING    fieldname
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
      MESSAGE s113(/psyng/sw) WITH
      'Cannot determine SW_CENTRAL_USR_FM with FM '
      ls_fmname '. FM doesn''t exist'.
    ELSE..
      l_repid = sy-repid.
      l_dynnr = sy-dynnr.
*Get Central Userid information as search help
      CALL FUNCTION ls_fmname                "#EC PATHLOCK_CI_DYN_ACCES
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
*&      Form  SET_BUTTON_ICONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
"BOC UMITTAL 24-09-2024
*FORM set_button_icons .
**  PERFORM init_but USING 'BLOK_BUT' 'X' CHANGING blok_but .
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  INIT_BUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_5156   text
*      -->P_5157   text
*      <--P_BLOK_BUT  text
*----------------------------------------------------------------------*
*FORM init_but  USING    i_name
*                       i_default_expanded
*              CHANGING i_button.
*  DATA : ls_state TYPE /psyng/usr_displ,
*         l_exp TYPE flag.
*  SELECT SINGLE * INTO ls_state
*  FROM /psyng/usr_displ
*  WHERE
*    bname = g_current_user AND "sy-uname AND C0700
*    repid = sy-repid AND
*    button_name = i_name.
*  IF sy-subrc = 0.
*    l_exp = ls_state-expanded.
*  ELSE.
*    l_exp = i_default_expanded.
*  ENDIF.
*
*  IF l_exp = 'X'.
*    PERFORM expand CHANGING i_button.
*  ELSE.
*    PERFORM collapse CHANGING i_button.
*  ENDIF.
*ENDFORM.
"EOC UMITTAL 24-09-2024
*&---------------------------------------------------------------------*
*&      Form  EXPAND
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
*----------------------------------------------------------------------*
FORM expand  CHANGING  button.
*--Set user button Icon
  CALL FUNCTION 'ICON_CREATE'
    EXPORTING
*      text   =  text-b01
*      info   = text-x02
      name   = 'ICON_COLLAPSE'
      add_stdinf = ''
    IMPORTING
      result = button
*BOC:HBHALLA (04/12/24)
        EXCEPTIONS
             icon_not_found = 1
             outputfield_too_short = 2
             OTHERS     = 3.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Icon name unknown to system'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'Length of field (RESULT) is too small'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (04/12/24)
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  COLLAPSE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_I_BUTTON  text
*----------------------------------------------------------------------*
FORM collapse  CHANGING button.
  CALL FUNCTION 'ICON_CREATE'
      EXPORTING
*      text   =  text-b01
*      info   = text-x01
        name   = 'ICON_EXPAND'
        add_stdinf = ''
      IMPORTING
        result = button
*BOC:HBHALLA (06/12/24)
        EXCEPTIONS
             icon_not_found = 1
             outputfield_too_short = 2
             OTHERS     = 3.
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Icon name unknown to system'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'Length of field (RESULT) is too small'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (06/12/24)
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_BUTTON
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM handle_button .
  CASE g_ucomm.
    WHEN 'BLOK_BUT'.                   "#EC SAST_CI_GEN_CHECK (HBHALLA)
*      PERFORM toggle USING blok_but 'BLOk_BUT'.
  ENDCASE.
  CLEAR g_ucomm.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  TOGGLE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_BLOK_BUT  text
*      -->P_5280   text
*----------------------------------------------------------------------*
FORM toggle  USING   i_button i_name.
  DATA : ls_state TYPE /psyng/usr_displ.
  ls_state-repid       = sy-repid.
  ls_state-bname       = g_current_user. "sy-uname. C0700
  ls_state-screen      = '1000'.
  ls_state-button_name = i_name.
  ls_state-group_name  = i_name.
  ls_state-ucomm       = g_ucomm.

  IF i_button(3) <> '@3T'.
    PERFORM expand USING i_button.
    ls_state-expanded = 'X'.
  ELSE.
    PERFORM collapse USING i_button.
    CLEAR  ls_state-expanded.
  ENDIF.
  MODIFY /psyng/usr_displ FROM ls_state.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_SECTIONS
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
"BOC UMITTAL 24-09-2024
*FORM handle_sections .
**  PERFORM handle_section USING blok_but 'BLK'.
*ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  HANDLE_SECTION
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_ROLE_BUT  text
*      -->P_5380   text
*----------------------------------------------------------------------*
*FORM handle_section  USING   i_button
*                             i_section_name.
*  DATA : l_collapse TYPE flag.
*
*  LOOP AT SCREEN .
*    IF screen-group1 = i_section_name.
*      IF i_button(3) <> '@3T'.
*        screen-invisible = 1.
*        screen-active    = 0.
*        l_collapse = 'X'.
*      ELSE.
*        screen-invisible = 0.
*        screen-active    = 1.
*      ENDIF.
*      MODIFY SCREEN.
*    ENDIF.
*  ENDLOOP.
*ENDFORM.
*EOC UMITTAL 24-09-2024
*&---------------------------------------------------------------------*
*&      Form  F4_SEC_POLICY
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_0885   text
*      <--P_S_SECPOL_HIGH  text
*----------------------------------------------------------------------*
FORM f4_sec_policy  USING    fieldname
                    CHANGING e_secpolilcy.
  DATA: BEGIN OF ls_data,
        name TYPE /psyng/bc_sec_policy,
      END OF ls_data,
      lt_data    LIKE TABLE OF ls_data,
      lth_return TYPE TABLE OF ddshretval,
      wah_return LIKE LINE OF lth_return.

  CONSTANTS lc_sectab TYPE tabname VALUE 'SEC_POLICY_CUST'.

  SELECT name FROM (lc_sectab) INTO TABLE lt_data "#EC SAST_CI_GEN_CHECK
    UP TO 500 ROWS.                              "#EC SAST_CI_GEN_CHECK
*HBHALLA VF-SCAN FIX (19/12/24)

  CALL FUNCTION 'F4IF_INT_TABLE_VALUE_REQUEST'
EXPORTING
  retfield        = 'NAME'
  value_org       = 'S'
  window_title    = 'Title'
TABLES
  value_tab       = lt_data
  return_tab      = lth_return
EXCEPTIONS
  parameter_error = 1
  no_values_found = 2
  OTHERS          = 3.
*BOC:HBHALLA (06/12/24)
  IF sy-subrc <> 0.
    CASE sy-subrc.
      WHEN 1.
        MESSAGE s002(/psyng/sw)
     WITH 'Incorrect parameter'.
      WHEN 2.
        MESSAGE s002(/psyng/sw)
     WITH 'No values found'.
      WHEN OTHERS.
        MESSAGE s002(/psyng/sw) WITH 'Unknown Error'.
    ENDCASE.
  ENDIF.
*EOC:HBHALLA (06/12/24)

  READ TABLE lth_return INTO wah_return INDEX 1.
  IF sy-subrc = 0.
    e_secpolilcy = wah_return-fieldval.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  WRITE_SPOOL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM write_spool .


  IF in_exp EQ 'X'.
    WRITE : / 'Nr. of users that will be expired:', expcount .
  ENDIF.
  IF in_lcd EQ 'X'.
    WRITE : / 'Nr. of users that will be locked:' , lockcount.
  ENDIF.

  IF in_del EQ 'X'.
    WRITE : / 'Nr. of users that will be deleted:', delcount.
  ENDIF.

  ULINE.
  IF in_exp EQ space.
    DELETE users WHERE action ='TO_BE_EXPIRED'.
  ENDIF.
  IF in_lcd EQ space.
    DELETE users WHERE action ='TO_BE_LOCKED'.
  ENDIF.

  IF in_del EQ space.
    DELETE users WHERE action ='TO_BE_DELETED'.
  ENDIF.


  DATA:
  program       LIKE sy-repid,
  alv_layout    TYPE slis_layout_alv,
  alv_grid_titl TYPE lvc_title,
  ls_variant    TYPE disvariant.


  program = sy-repid.
  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.
*  alv_layout-no_colhead = 'X'.
*  alv_layout-expand_fieldname = 'X'.
*  alv_layout-expand_all = 'X'.
*  alv_layout-box_fieldname     = 'SEL'.
  SORT: users BY action DESCENDING bname.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
    EXPORTING
      i_program_name         = program
      i_internal_tabname     = 'USERS'
      i_inclname             = program
    CHANGING
      ct_fieldcat            = i_fieldcat_alv
    EXCEPTIONS
      inconsistent_interface = 1
      program_error          = 2
      OTHERS                 = 3.

  CHECK sy-subrc = 0.
  PERFORM change_catalog_texts.
  MESSAGE s176(/psyng/sw).

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_grid_title            = alv_grid_titl
      i_callback_program      = program
      i_callback_top_of_page  = 'ALV_HEADER'
      i_callback_pf_status_set = 'SET_PFSTATUS'
      i_callback_user_command = 'USER_CLICK'
      is_layout               = alv_layout
      it_fieldcat             = i_fieldcat_alv
      i_save                  = 'A'
      is_variant              = ls_variant
    TABLES
      t_outtab                = users
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             program_error          = 1
             OTHERS                 = 2 .
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
*  (++)EOC UMITTAL SE VF scan-25/11/2024.
ENDFORM.
