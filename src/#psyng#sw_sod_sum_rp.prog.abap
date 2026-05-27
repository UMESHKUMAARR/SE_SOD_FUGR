*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/SW_SOD_SUM_RP
* AUTHOR                : Security Weaver, LLC
*----------------------------------------------------------------------*
* COPYRIGHTS Security Weaver, LLC
* WARNING:
* THIS COMPUTER PROGRAM IS PROTECTED BY COPYRIGHT LAW AND INTERNATIONAL
* TREATIES. UNAUTHORIZED REPRODUCTION OR DISTRIBUTION IS STRICTLY
* PROHIBITED AND MAY RESULT IN SEVERE CIVIL AND CRIMINAL PENALTIES AND
* WILL BE PROSECUTED TO THE MAXIMUM EXTENT POSSIBLE UNDER THE LAW.
*&---------------------------------------------------------------------*

REPORT /psyng/sw_sod_sum_rp MESSAGE-ID /psyng/sw
LINE-SIZE 132.
TYPE-POOLS:slis.
TABLES: /psyng/conflict,usr02, /psyng/swresusr."usr21,
INCLUDE /PSYNG/BASIS_EXELOG.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.

DATA: isort TYPE STANDARD TABLE OF slis_sortinfo_alv.
*lf_initialized TYPE flag.
DEFINE add_sel.
  &1-selname = &2.
  &1-kind    = &3.
  &1-sign    = &4.
  &1-option  = &5.
  &1-low     = &6.
  &1-high    = &7.
  append &1.
END-OF-DEFINITION.

CONSTANTS: gc_erp_class(16) TYPE c VALUE '/PSYNG/SW_CL_ERP'.

DATA: BEGIN OF output1 OCCURS 0,
        persa LIKE /psyng/sw_uinfo-persa,
        kostl LIKE /psyng/sw_uinfo-kostl,
        bname LIKE usr02-bname,
        name_text LIKE /psyng/sw_uinfo-name_text,
        uflag LIKE usr02-uflag,
        conid LIKE /psyng/conflict-conid,
        contid LIKE /psyng/mchdr-contid,
        auditor LIKE /psyng/syscandt-auditor,
        mit_date_from LIKE /psyng/syscandt-mit_date_from,
        mit_date_to LIKE /psyng/syscandt-mit_date_to,
        risk     LIKE /psyng/conflict-risk,
        scandate LIKE /psyng/syscandt-scandate,
     END OF output1.

DATA: BEGIN OF output2 OCCURS 0,
        persa LIKE /psyng/sw_uinfo-persa,
        kostl LIKE /psyng/sw_uinfo-kostl,
        bname LIKE usr02-bname,
        name_text LIKE /psyng/sw_uinfo-name_text,
        conid LIKE /psyng/conflict-conid,
        risk     LIKE /psyng/conflict-risk,
        scandate LIKE /psyng/syscandt-scandate,
     END OF output2.

DATA: BEGIN OF output3 OCCURS 0,
        persa LIKE /psyng/sw_uinfo-persa,
        kostl LIKE /psyng/sw_uinfo-kostl,
        bname LIKE usr02-bname,
        name_text LIKE /psyng/sw_uinfo-name_text,
        conid LIKE /psyng/conflict-conid,
        risk     LIKE /psyng/conflict-risk,
        scandate LIKE /psyng/syscandt-scandate,
     END OF output3.
DATA: BEGIN OF output4 OCCURS 0,
        persa LIKE /psyng/sw_uinfo-persa,
        persa_text TYPE  /psyng/pbtxt,
        kostl LIKE /psyng/sw_uinfo-kostl,
        kostl_text TYPE  /psyng/kltxt,
        bname LIKE usr02-bname,
        name_text LIKE /psyng/sw_uinfo-name_text,
        conid LIKE /psyng/conflict-conid,
        contid LIKE /psyng/mchdr-contid,
        auditor LIKE /psyng/syscandt-auditor,
        mit_date_from LIKE /psyng/syscandt-mit_date_from,
        mit_date_to LIKE /psyng/syscandt-mit_date_to,
        con_text LIKE /psyng/conflict-description,
        risk     LIKE /psyng/conflict-risk,
        scandate LIKE /psyng/syscandt-scandate,
        count TYPE i,
        mit_count TYPE i,
     END OF output4.

DATA: BEGIN OF output_con OCCURS 0,
        busarea LIKE /psyng/conflict-busarea,
        imp LIKE /psyng/conflict-imp,
        conid LIKE /psyng/conflict-conid,
        con_text LIKE /psyng/conflict-description,
        count TYPE i,
        mit_count TYPE i,
     END OF output_con.
DATA: BEGIN OF output_user OCCURS 0,
        class LIKE usr02-class,
        bname LIKE usr02-bname,
        name_text LIKE /psyng/sw_uinfo-name_text,
        count TYPE i,
        mit_count TYPE i,
     END OF output_user.


DATA: g_functioncall_1(4),
      g_done(4) VALUE 'DONE',
      gf_missing_auth_ugroup TYPE /psyng/bapiflagx,
      g_scantable TYPE tabname,
      g_dynnr        TYPE sy-dynnr.
RANGES : gr_conid FOR /psyng/conflict-conid.
DATA: scandt TYPE STANDARD TABLE OF /psyng/syscandt WITH HEADER LINE.
DATA: gt_sw_uinfo TYPE STANDARD TABLE OF /psyng/sw_uinfo WITH HEADER
LINE.

*DATA: gt_function TYPE STANDARD TABLE OF /psyng/function WITH HEADER
*LINE.
*DATA: gt_iusgrpt TYPE STANDARD TABLE OF usgrpt WITH HEADER LINE.
*DATA: gt_conflict TYPE STANDARD TABLE OF /psyng/conflict WITH HEADER
*LINE,
      data : gt_conflict_sorted TYPE HASHED TABLE OF /psyng/conflict
      WITH UNIQUE KEY conid
      WITH HEADER LINE .
DATA: gt_cuscon TYPE STANDARD TABLE OF /psyng/sw_cuscon WITH HEADER LINE
.
DATA: gt_kostl_resp TYPE STANDARD TABLE OF /psyng/sw_kostl_resp
      WITH HEADER LINE,
      gt_kostl_sorted TYPE HASHED TABLE OF /psyng/sw_kostl_resp
      WITH UNIQUE KEY kostl WITH HEADER LINE.
*DATA: gs_usr02 TYPE usr02.

DATA:
*      g_dsp_mng_lock VALUE 'N',
*      g_dsp_slf_lock VALUE 'Y',
      gf_use_erp   TYPE /psyng/bapiflagx,
*      go_classtype TYPE REF TO cl_abap_typedescr,
      gs_config    TYPE /psyng/swconfig,
      g_i_fieldcat_alv  TYPE slis_t_fieldcat_alv,
      gt_outno_mit TYPE TABLE OF /psyng/syscandt WITH HEADER LINE,
      gt_outmit_count TYPE TABLE OF /psyng/syscandt WITH HEADER LINE,
      gt_outuser_count LIKE TABLE OF output4 WITH HEADER LINE,
*      gt_outconf_count TYPE TABLE OF /psyng/syscandt WITH HEADER LINE,
      gt_mit_per_user LIKE TABLE OF /psyng/syscandt WITH HEADER LINE,

      g_lmit_count TYPE i,
      g_lconf_count TYPE i,
      g_luser_count TYPE i,
      g_laverage_count TYPE i,
      g_lmit_countc(6) TYPE c,
      g_lconf_countc(6) TYPE c,
      g_luser_countc(6) TYPE c,
      g_laverage_countc(4) TYPE c.
DATA :gt_rpoug_auth_fail TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE,
       gt_conid TYPE TABLE OF /psyng/conflict WITH HEADER LINE,
       lt_cuscon TYPE TABLE OF /psyng/sw_cuscon WITH HEADER LINE,
       g_current_user TYPE sy-uname. "C0700

*-- Selection Screen
SELECTION-SCREEN: BEGIN OF BLOCK sel WITH FRAME TITLE text-001.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECT-OPTIONS: pbname FOR usr02-bname,
                pclass FOR usr02-class,
                s_kostl  FOR /psyng/swresusr-kostl
                MATCHCODE OBJECT kostn.

PARAMETERS : sodvrsio LIKE /psyng/conflict-vrsio.
SELECT-OPTIONS: s_conid FOR /psyng/conflict-conid,
                s_busa  FOR /psyng/conflict-busarea,
                s_imp   FOR /psyng/conflict-imp,
                s_risk  FOR /psyng/conflict-risk.
SELECTION-SCREEN: SKIP 1.


*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.
PARAMETER : shomit AS CHECKBOX DEFAULT 'X'.




SELECTION-SCREEN: END OF BLOCK sel.


SELECTION-SCREEN: BEGIN OF BLOCK disp WITH FRAME TITLE text-029.
PARAMETERS : p_o_con TYPE flag RADIOBUTTON GROUP g2 USER-COMMAND a
DEFAULT 'X'.
PARAMETERS : p_o_usr TYPE flag RADIOBUTTON GROUP g2.
PARAMETERS : p_o_det TYPE flag RADIOBUTTON GROUP g2.
PARAMETERS : p_con   TYPE flag AS CHECKBOX DEFAULT 'X',
             p_none  TYPE flag AS CHECKBOX DEFAULT 'X',
             p_noinf TYPE flag AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN : SKIP 1.


SELECTION-SCREEN: END OF BLOCK disp.

SELECTION-SCREEN: BEGIN OF BLOCK scan WITH FRAME TITLE text-030.
PARAMETERS : p_std TYPE flag RADIOBUTTON GROUP g1 DEFAULT 'X'
,
             p_enh TYPE flag RADIOBUTTON GROUP g1 .
SELECTION-SCREEN: END OF BLOCK scan.


SELECTION-SCREEN: BEGIN OF BLOCK prer WITH FRAME TITLE text-002.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-003.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-004.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN: COMMENT 3(66) text-005.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: END OF BLOCK prer .
PARAMETERS : drill TYPE flag NO-DISPLAY. "marks if this is a drilldown

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

AT SELECTION-SCREEN.

  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.
INITIALIZATION. "#EC DUPL_EVENT

* BOC by RGUPTA on 08.04.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 08.04.22 for C0700

*--Register report for Most Used Reports
  CALL FUNCTION '/PSYNG/SW_128'
  EXPORTING
  i_repid       = '/PSYNG/SW_SOD_SUM_RP'.



AT SELECTION-SCREEN OUTPUT.

*If the configuration setting SW_ENH_SCAN_TBL = Y,
*The radiobuttons to choose between standard and enhanced ruleset
*are shown
  se_config_param 'SW_ENH_SCAN_TBL' gs_config-value.
  LOOP AT SCREEN.

    CASE screen-name.
      WHEN 'P_STD' OR 'P_ENH' OR 'SCAN' OR '%B030021_BLOCK_1000'.
        IF gs_config-value = 'Y'.
          screen-invisible = '0'.
        ELSE.
          screen-input = '0'.
        ENDIF.
        MODIFY SCREEN .

      WHEN 'USRTYPE-LOW' OR 'USRTYPE-HIGH' OR 'EXLCKUSR' OR 'OUTVDATE'.
        IF validusr = 'X'.
          exlckusr = 'X'.
          outvdate = 'X'.
          PERFORM set_def_usrtype.
          screen-input = 0.
          CLEAR p_flag.
        ELSE.
          REFRESH usrtype.
          PERFORM get_config_usr.

          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.
      WHEN 'P_CON' OR 'P_NONE' OR 'P_NOINF'.
        IF p_o_det <> 'X'.
          screen-input    = 0.
        ELSE.
          screen-input    = 1.
        ENDIF.
        MODIFY SCREEN.

    ENDCASE.


  ENDLOOP.




START-OF-SELECTION.

*BOC AKUMAR SE VF scan changes-25/11/2024

AUTHORITY-CHECK OBJECT 'S_PROGRAM'
       ID 'P_GROUP' FIELD 'SW_SE'
       ID 'P_ACTION' FIELD 'SUBMIT'.
  IF sy-subrc NE 0..
    MESSAGE i108(/psyng/sw) with 'execute ' sy-repid.
    EXIT.
  ENDIF.

*EOC AKUMAR SE VF scan changes-25/11/2024
  CONCATENATE sy-title text-032 sodvrsio
              INTO sy-title SEPARATED BY space.
  EXELOG sy-repid ''.
* Determine which scan table to use
  IF p_enh = 'X'.
    g_scantable = '/PSYNG/ENHSCANDT'.
  ELSE.
    g_scantable = '/PSYNG/SYSCANDT'.
  ENDIF.
*2017/05/03 Never use ERP fields
  CLEAR gf_use_erp.

  IF p_con  IS INITIAL.
    IF p_none  IS INITIAL.
      IF p_noinf  IS INITIAL.
        MESSAGE s116(/psyng/sw).
        LEAVE LIST-PROCESSING.
      ENDIF.
    ENDIF.
  ENDIF.
  SELECT      conid owner description busarea imp
  FROM       /psyng/conflict
  INTO CORRESPONDING FIELDS OF TABLE gt_conid
  WHERE vrsio   = sodvrsio
  AND conid     IN s_conid
  AND imp       IN s_imp
  AND risk      IN s_risk
  AND busarea   IN s_busa.
  MESSAGE s002 WITH 'Loading Conflict Definitions'.
  COMMIT WORK.

*--Also select the custom conflicts (SF 1697)

  SELECT conid busarea imp cdesc FROM /psyng/sw_cuscon
  INTO CORRESPONDING FIELDS OF TABLE lt_cuscon
  WHERE vrsio = sodvrsio
  AND   inactive <> 'X'
  AND   conid IN s_conid
  AND   imp   IN s_imp
  AND   busarea IN s_busa.

  IF gt_conid[] IS INITIAL AND lt_cuscon[] IS INITIAL.
*--Selection of conflicts showed no conflicts
  MESSAGE i135(/psyng/sw) WITH 'No Conflict ID(s) match selection'(033).
    LEAVE LIST-PROCESSING.
  ELSE.
*--Create a conflict range
    gr_conid-sign   = 'I'.
    gr_conid-option = 'EQ'.
    LOOP AT gt_conid.
      gr_conid-low = gt_conid-conid.
      APPEND gr_conid.
    ENDLOOP.
    LOOP AT lt_cuscon.
      gr_conid-low = lt_cuscon-conid.
      APPEND gr_conid.
    ENDLOOP.
  ENDIF.
  PERFORM start_child_get_user_name.

*--Summary Output Mode
  IF p_o_con = 'X'.
*--Log execution.
    exelog sy-repid 'CONFLICTSUMMARY'.
    PERFORM conflict_summary.
  ELSEIF p_o_usr = 'X'.
*--Log execution.
    exelog sy-repid 'USERSUMMARY'.
    PERFORM user_summary.
  ELSE.
*--Log execution.
    exelog sy-repid 'DETAILS'.

*--Detailed output mode
    IF p_con = 'X'.
      MESSAGE s002 WITH 'Loading Conflicts from Scan table'.
      COMMIT WORK.
*get all users WITH conflicts

*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  IF p_enh = 'X'.
*    g_scantable = '/PSYNG/ENHSCANDT'.
      SELECT * FROM /PSYNG/ENHSCANDT
               INTO CORRESPONDING FIELDS OF TABLE scandt
               WHERE bname IN pbname AND
                     conid <> 'NONE' AND
                     conid IN gr_conid AND
                     vrsio =  sodvrsio
               ORDER BY bname. "#EC SAST_CI_GEN_CHECK
  ELSE.
*    g_scantable = '/PSYNG/SYSCANDT'.
      SELECT * FROM /PSYNG/SYSCANDT
               INTO CORRESPONDING FIELDS OF TABLE scandt
               WHERE bname IN pbname AND
                     conid <> 'NONE' AND
                     conid IN gr_conid AND
                     vrsio =  sodvrsio
               ORDER BY bname. "#EC SAST_CI_GEN_CHECK
  ENDIF.

**      SELECT * FROM (g_scantable)
**               INTO CORRESPONDING FIELDS OF TABLE scandt
**               WHERE bname IN pbname AND
**                     conid <> 'NONE' AND
**                     conid IN gr_conid AND
**                     vrsio =  sodvrsio
**               ORDER BY bname. "#EC SAST_CI_GEN_CHECK
***HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25

**** Delete records with Mitigation ID when mitigation checkbox is space
      IF shomit IS INITIAL.
        gt_outno_mit[] = scandt[].
        DELETE gt_outno_mit WHERE contid NE space.
      ENDIF.

*** get no of records with mitigation
      IF shomit = 'X'.
        MESSAGE s002 WITH 'Analyzing Mitigation Assignments'.
        COMMIT WORK.

        gt_outmit_count[] = scandt[].
        DELETE gt_outmit_count WHERE contid EQ space.
        DESCRIBE TABLE gt_outmit_count LINES g_lmit_count.

        gt_mit_per_user[] = gt_outmit_count[].
        SORT gt_mit_per_user BY bname conid
                               contid mit_date_from mit_date_to.
        DELETE ADJACENT DUPLICATES FROM gt_mit_per_user
        COMPARING bname conid contid mit_date_from mit_date_to.
      ENDIF.

      SORT gt_sw_uinfo BY bname.
      LOOP AT scandt.
        READ TABLE gt_sw_uinfo WITH KEY bname = scandt-bname
                   BINARY SEARCH.
        CHECK sy-subrc = 0.
        MOVE-CORRESPONDING scandt TO output1.
        MOVE-CORRESPONDING gt_sw_uinfo TO output1.
        IF shomit IS INITIAL.
          IF output1-contid EQ space.
            APPEND output1.
          ENDIF.
        ELSE.
          APPEND output1.
        ENDIF.
      ENDLOOP.
      SORT output1.  DELETE ADJACENT DUPLICATES FROM output1.
      REFRESH scandt. CLEAR scandt.
    ENDIF.
    IF p_none = 'X'.
    MESSAGE s002 WITH 'Loading users without conflicts from Scan table'.
      COMMIT WORK.

*get all users WITHOUT conflicts

*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  IF p_enh = 'X'.
*    g_scantable = '/PSYNG/ENHSCANDT'.
      SELECT * FROM /PSYNG/ENHSCANDT
               INTO CORRESPONDING FIELDS OF TABLE scandt
               WHERE bname IN pbname AND
                     conid = 'NONE'  AND
                     vrsio = sodvrsio
               ORDER BY bname."#EC SAST_CI_GEN_CHECK
  ELSE.
*    g_scantable = '/PSYNG/SYSCANDT'.
      SELECT * FROM /PSYNG/SYSCANDT
               INTO CORRESPONDING FIELDS OF TABLE scandt
               WHERE bname IN pbname AND
                     conid = 'NONE'  AND
                     vrsio = sodvrsio
               ORDER BY bname."#EC SAST_CI_GEN_CHECK
  ENDIF.

**      SELECT * FROM (g_scantable)
**               INTO CORRESPONDING FIELDS OF TABLE scandt
**               WHERE bname IN pbname AND
**                     conid = 'NONE'  AND
**                     vrsio = sodvrsio
**               ORDER BY bname."#EC SAST_CI_GEN_CHECK
***HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25

      LOOP AT scandt.
        READ TABLE gt_sw_uinfo WITH KEY bname = scandt-bname
                   BINARY SEARCH TRANSPORTING NO FIELDS.
        CHECK sy-subrc = 0.
        MOVE-CORRESPONDING scandt TO output3.
     READ TABLE gt_sw_uinfo WITH KEY bname = scandt-bname BINARY SEARCH
           .
        IF sy-subrc = 0.
          MOVE-CORRESPONDING gt_sw_uinfo TO output3.
        ENDIF.
        APPEND output3.
      ENDLOOP.
      SORT output3.  DELETE ADJACENT DUPLICATES FROM output3.

    ENDIF.
    WAIT UNTIL g_functioncall_1 = g_done.
    IF p_noinf = 'X'.

*Get users for whom there is no SOD analysis information available
      LOOP AT gt_sw_uinfo WHERE sodscandate = '18010101'.
        MOVE-CORRESPONDING gt_sw_uinfo TO output2.

        APPEND output2.
      ENDLOOP.
      SORT output2.  DELETE ADJACENT DUPLICATES FROM output2.
    ENDIF.

    PERFORM fill_user_info.
    PERFORM write_data_to_screen.


    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s190(/psyng/sw).
    ELSE.
      IF output4[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
        EXIT.
      ELSE.
        MESSAGE s176(/psyng/sw).
      ENDIF.
    ENDIF.
*--Free some memory for unneeded tables
    FREE : gt_kostl_resp[],
*           gt_conflict[],
           gt_conflict_sorted[],
           gt_kostl_resp[],
           output1[],
           output2[],
           output3[]
*           ,gt_sw_uinfo[] "don't clear, needed in alv header
           .
    MESSAGE s002 WITH 'ALV Output Starting'.
    COMMIT WORK.
    PERFORM output_alv.
  ENDIF.


*&---------------------------------------------------------------------*
*&      Form  start_child_get_user_name
*&---------------------------------------------------------------------*
FORM start_child_get_user_name.
  MESSAGE s002 WITH 'Loading Users'.
  COMMIT WORK.

  DATA: wa_uinfo TYPE  /psyng/sw_uinfo ,
*  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
*          yusloc   TYPE x VALUE '40',     "Locked by Administrator
*   yugloc   TYPE x VALUE '20'.     "Locked by global Administrator
*  DATA : l_uflagx TYPE x,
  i_include_locked TYPE flag,
  i_include_expire TYPE flag.
  DATA : BEGIN OF ls_auth_checks,
    class TYPE xuclass,
    company TYPE uscomp,
    success TYPE flag,
    END OF ls_auth_checks,
    lt_auth_checks LIKE HASHED TABLE OF ls_auth_checks
    WITH UNIQUE KEY class company WITH HEADER LINE.

  DATA : lt_users TYPE TABLE OF usr02 WITH HEADER LINE.

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
            IT_COSTCENTER     = s_kostl.

  CHECK NOT lt_users[] IS INITIAL.

  LOOP AT lt_users.
    wa_uinfo-bname   = lt_users-bname.
    wa_uinfo-class   = lt_users-class.
    APPEND wa_uinfo TO gt_sw_uinfo.
  ENDLOOP.
*--Load User details if needed
  CHECK p_o_det = 'X' OR p_o_usr = 'X'.
  MESSAGE s002 WITH 'Executing Authorization Checks'.
  COMMIT WORK.

* Check authority to user group
  IF NOT gt_sw_uinfo[] IS INITIAL.
    CALL FUNCTION '/PSYNG/SW_USER_INFO'
     EXPORTING
       vrsio                    = sodvrsio
*       ENHANCED_SCANTABLE       = ''
       i_name_only              = 'X'
       i_mr_company             = 'X'
      TABLES
        sw_uinfo                 = gt_sw_uinfo.
    LOOP AT gt_sw_uinfo.
      READ TABLE lt_auth_checks WITH
      TABLE KEY class   = gt_sw_uinfo-class
                company = gt_sw_uinfo-company.
      IF sy-subrc = 0.
*--Authorization was checked before
        IF lt_auth_checks-success <> 'X'.
          gt_rpoug_auth_fail-bname   = gt_sw_uinfo-bname.
          gt_rpoug_auth_fail-class   = gt_sw_uinfo-class.
          gt_rpoug_auth_fail-company = gt_sw_uinfo-company.
          APPEND gt_rpoug_auth_fail.
          CLEAR gt_rpoug_auth_fail.
          DELETE gt_sw_uinfo.
          gf_missing_auth_ugroup = 'X'.
        ENDIF.
      ELSE.
*--Authorization was not checked before
        lt_auth_checks-class   = gt_sw_uinfo-class.
        lt_auth_checks-company = gt_sw_uinfo-company.
        lt_auth_checks-success = 'X'.
        IF NOT gt_sw_uinfo-class IS INITIAL AND
           NOT gt_sw_uinfo-company IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
               ID 'CLASS' FIELD gt_sw_uinfo-class
               ID 'Y&SW_VRSIO'  FIELD sodvrsio "#EC AUTFLD_LEN
               ID 'Y&SW_COMP'   FIELD gt_sw_uinfo-company.

          IF sy-subrc <> 0.
            gt_rpoug_auth_fail-bname   = gt_sw_uinfo-bname.
            gt_rpoug_auth_fail-class   = gt_sw_uinfo-class.
            gt_rpoug_auth_fail-company = gt_sw_uinfo-company.
            APPEND gt_rpoug_auth_fail.
            CLEAR gt_rpoug_auth_fail.
            DELETE gt_sw_uinfo.
            gf_missing_auth_ugroup = 'X'.
            CLEAR lt_auth_checks-success .
          ENDIF.
        ELSEIF NOT gt_sw_uinfo-class IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
               ID 'CLASS' FIELD gt_sw_uinfo-class
               ID 'Y&SW_VRSIO'  FIELD sodvrsio
               ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
          IF sy-subrc <> 0.
            gt_rpoug_auth_fail-bname   = gt_sw_uinfo-bname.
            gt_rpoug_auth_fail-class   = gt_sw_uinfo-class.
            gt_rpoug_auth_fail-company = gt_sw_uinfo-company.
            APPEND gt_rpoug_auth_fail.
            CLEAR gt_rpoug_auth_fail.
            DELETE gt_sw_uinfo.
            gf_missing_auth_ugroup = 'X'.
            CLEAR lt_auth_checks-success .
          ENDIF.
        ELSEIF NOT gt_sw_uinfo-company IS INITIAL.
          AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
               ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
               ID 'Y&SW_VRSIO'  FIELD sodvrsio "#EC AUTFLD_LEN
               ID 'Y&SW_COMP'   FIELD gt_sw_uinfo-company.
          IF sy-subrc <> 0.
            gt_rpoug_auth_fail-bname   = gt_sw_uinfo-bname.
            gt_rpoug_auth_fail-class   = gt_sw_uinfo-class.
            gt_rpoug_auth_fail-company = gt_sw_uinfo-company.
            APPEND gt_rpoug_auth_fail.
            CLEAR gt_rpoug_auth_fail.
            DELETE gt_sw_uinfo.
            gf_missing_auth_ugroup = 'X'.
            CLEAR lt_auth_checks-success .
          ENDIF.
        ENDIF.
        INSERT TABLE lt_auth_checks.
      ENDIF.
    ENDLOOP.

  ENDIF.


ENDFORM.                    " start_child_get_user_name


*&---------------------------------------------------------------------*
*&      Form  fill_user_info
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM fill_user_info.
  MESSAGE s002 WITH 'Adding user information to output'.
  COMMIT WORK.


  FIELD-SYMBOLS : <o1> LIKE LINE OF  output1,
                  <o2> LIKE LINE OF  output2,
                  <o3> LIKE LINE OF  output3.

  LOOP AT output1 ASSIGNING <o1>.
    READ TABLE gt_sw_uinfo WITH KEY bname = <o1>-bname BINARY SEARCH.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING gt_sw_uinfo TO <o1>.
*      MODIFY output1.
    ENDIF.
  ENDLOOP.

  LOOP AT output2 ASSIGNING <o2>.
    READ TABLE gt_sw_uinfo WITH KEY bname =  <o2>-bname BINARY SEARCH.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING gt_sw_uinfo TO <o2>.
    ENDIF.
  ENDLOOP.

  LOOP AT output3 ASSIGNING <o3>.
    READ TABLE gt_sw_uinfo WITH KEY bname = <o3>-bname BINARY SEARCH.
    IF sy-subrc = 0.
      MOVE-CORRESPONDING gt_sw_uinfo TO <o3>.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " fill_user_info
*&---------------------------------------------------------------------*
*&      Form  write_data_to_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM write_data_to_screen.
  MESSAGE s002 WITH 'Preparing detailedoutput'.
  COMMIT WORK.

  CONSTANTS: lc_kostl_method(20) TYPE c VALUE 'GET_COST_CENTER_NAME',
             lc_persa_method(25) TYPE c VALUE 'GET_PERSONNEL_AREA_NAME'.
  DATA: lo_erp_class TYPE REF TO object,
        l_ltext      TYPE /psyng/kltxt,
        l_pbtxt      TYPE /psyng/pbtxt,
        l_mit_idx    LIKE sy-tabix,
        l_out1_idx   LIKE sy-tabix,
        l_mitu_idx   LIKE sy-tabix,
        l_cnt        LIKE sy-tabix.
  FIELD-SYMBOLS <fs1> LIKE output1.
  DATA : lt_uinfo_sorted TYPE HASHED TABLE OF /psyng/sw_uinfo
         WITH UNIQUE KEY bname  WITH HEADER LINE.

  IF gf_use_erp = 'X'.
    CREATE OBJECT lo_erp_class TYPE (gc_erp_class).
    IF lo_erp_class is initial.
      CLEAR gf_use_erp.
    ENDIF.
  ENDIF.

  CLEAR: output1, output2, output3.
*  DATA l_date TYPE sy-datum.

* Users WITH conflicts
  IF NOT output1[] IS INITIAL.
    DESCRIBE TABLE output1 LINES l_cnt.
    MESSAGE s002 WITH 'Preparing output - Users with conflicts ' l_cnt .
    COMMIT WORK.

    SORT gt_kostl_resp BY kostl.
    gt_kostl_sorted[] = gt_kostl_resp[].
    SORT gt_conid.
    gt_conflict_sorted[] = gt_conid[].
    LOOP AT output1.
      CLEAR output4.
      output4-persa = output1-persa.
      output4-kostl = output1-kostl.
      output4-bname = output1-bname.
      output4-name_text = output1-name_text.
      output4-conid = output1-conid.
      output4-contid = output1-contid.
      output4-auditor = output1-auditor.
      output4-mit_date_from = output1-mit_date_from.
      output4-mit_date_to = output1-mit_date_to.
      output4-risk     = output1-risk.
      output4-scandate = output1-scandate.

      IF gf_use_erp = 'X'.
        CALL METHOD lo_erp_class->(lc_persa_method)
          EXPORTING
            i_persa = output1-persa
          IMPORTING
            e_pbtxt = l_pbtxt. "#EC PATHLOCK_CI_DYN_ACCES
        output4-persa_text = l_pbtxt.
      ENDIF.
      IF gf_use_erp = 'X'.
        CALL METHOD lo_erp_class->(lc_kostl_method)
          EXPORTING
            i_kostl = output1-kostl
          IMPORTING
            e_ltext = l_ltext. "#EC PATHLOCK_CI_DYN_ACCES
        output4-kostl_text = l_ltext.
      ENDIF.
      READ TABLE gt_kostl_sorted WITH TABLE KEY kostl = output1-kostl.
      IF sy-subrc = 0.
        output4-kostl_text = gt_kostl_sorted-kostlresp.
      ENDIF.

      READ TABLE gt_conflict_sorted
      WITH TABLE KEY conid = output1-conid.
      IF sy-subrc = 0.
        output4-con_text = gt_conflict_sorted-description.
        output4-risk     = gt_conflict_sorted-risk.
      ELSE.
*       custom conflict
        READ TABLE gt_cuscon WITH KEY conid = output1-conid
        BINARY SEARCH.
        IF sy-subrc = 0.
          output4-con_text = gt_cuscon-cdesc.
        ENDIF.
      ENDIF.

      IF shomit IS INITIAL.
        CLEAR output4-count.
        READ TABLE gt_outno_mit
        WITH KEY bname = output1-bname
                 scandate = output1-scandate
        BINARY SEARCH
        TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_mit_idx = sy-tabix.
          LOOP AT gt_outno_mit
          FROM l_mit_idx.
            IF gt_outno_mit-bname    <> output1-bname OR
               gt_outno_mit-scandate <> output1-scandate.
              EXIT.
            ENDIF.
            output4-count = output4-count + 1.
          ENDLOOP.
        ENDIF.
      ELSE.
        READ TABLE output1 WITH KEY
          bname = output1-bname
          scandate = output1-scandate
          BINARY SEARCH
          TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          l_out1_idx = sy-tabix.
          LOOP AT output1 ASSIGNING <fs1> FROM l_out1_idx.
            IF NOT <fs1>-bname = output1-bname OR
               NOT <fs1>-scandate = output1-scandate.
              EXIT.
            ENDIF.
            output4-count = output4-count + 1.
          ENDLOOP.
        ENDIF.
      ENDIF.
      READ TABLE gt_mit_per_user WITH KEY bname = output1-bname
      BINARY SEARCH TRANSPORTING NO FIELDS.
      IF sy-subrc = 0.
        l_mitu_idx = sy-tabix.
        LOOP AT gt_mit_per_user FROM l_mitu_idx.
          IF gt_mit_per_user-bname <> output1-bname.
            EXIT.
          ENDIF.
          output4-mit_count = output4-mit_count + 1.
        ENDLOOP.
      ENDIF.
      APPEND output4.
    ENDLOOP.                                                "output1
  ENDIF.   "check to see if output1 is filled

  CLEAR: output1, output2, output3.

  lt_uinfo_sorted[] = gt_sw_uinfo[].
* Users WITHOUT conflicts

  IF NOT output3[] IS INITIAL.
    DESCRIBE TABLE output3 LINES l_cnt.
  MESSAGE s002 WITH 'Preparing output - Users without conflicts ' l_cnt.
    COMMIT WORK.

    LOOP AT output3.
      CLEAR output4.
      MOVE-CORRESPONDING output3 TO output4.
      IF gf_use_erp = 'X'.
        CALL METHOD lo_erp_class->(lc_persa_method)
          EXPORTING
            i_persa = output3-persa
          IMPORTING
            e_pbtxt = l_pbtxt. "#EC PATHLOCK_CI_DYN_ACCES
        output4-persa_text = l_pbtxt.
      ENDIF.
*     If ERP system, write cost center text
      IF gf_use_erp = 'X'.
        CALL METHOD lo_erp_class->(lc_kostl_method)
          EXPORTING
            i_kostl = output3-kostl
          IMPORTING
            e_ltext = l_ltext. "#EC PATHLOCK_CI_DYN_ACCES
        output4-kostl_text = l_ltext.
      ENDIF.

      READ TABLE  gt_kostl_sorted WITH TABLE KEY kostl = output3-kostl.
      IF sy-subrc = 0.
        output4-kostl_text = gt_kostl_sorted-kostlresp.
      ENDIF.
      READ TABLE lt_uinfo_sorted WITH TABLE KEY bname = output3-bname.
      IF sy-subrc = 0.
        MOVE lt_uinfo_sorted-sodcount TO output4-count.
      ENDIF.
      APPEND output4.
    ENDLOOP.
  ENDIF.


* Users WITHOUT any SOD information available
  IF NOT output2[] IS INITIAL.
    DESCRIBE TABLE output2 LINES l_cnt.
    MESSAGE s002 WITH 'Preparing output - Users without data ' l_cnt.
    COMMIT WORK.

    LOOP AT output2.
*--Confirm no data is found for this user yet
      READ TABLE output4 WITH KEY bname = output2-bname
      BINARY SEARCH TRANSPORTING NO FIELDS.
      CHECK sy-subrc <> 0.

      CLEAR output4.
      MOVE-CORRESPONDING output2 TO output4.
*       If ERP system, write personnel area text
      IF gf_use_erp = 'X'.

        CALL METHOD lo_erp_class->(lc_persa_method)
          EXPORTING
            i_persa = output2-persa
          IMPORTING
            e_pbtxt = l_pbtxt. "#EC PATHLOCK_CI_DYN_ACCES
        output4-persa_text = l_pbtxt.

      ENDIF.

*       If ERP system, write cost center text
      IF gf_use_erp = 'X'.
        CALL METHOD lo_erp_class->(lc_kostl_method)
          EXPORTING
            i_kostl = output2-kostl
          IMPORTING
            e_ltext = l_ltext. "#EC PATHLOCK_CI_DYN_ACCES
        output4-kostl_text = l_ltext.
      ENDIF.

      READ TABLE gt_kostl_sorted WITH TABLE KEY kostl = output2-kostl.
      IF sy-subrc = 0.
        output4-kostl_text = gt_kostl_sorted-kostlresp.
      ENDIF.
      READ TABLE lt_uinfo_sorted WITH TABLE KEY bname = output2-bname.
      IF sy-subrc = 0.
        MOVE lt_uinfo_sorted-sodcount TO output4-count.
      ENDIF.
      APPEND output4.
    ENDLOOP.                                                "output2
  ENDIF.  "check to see if output2 is filled
  CLEAR: output1, output2, output3.
  FREE : lt_uinfo_sorted[].


ENDFORM.                    " write_data_to_screen
*&---------------------------------------------------------------------*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*FORM get_sw_repo_conifg.
*  se_config_param 'REP_USR_LOK_DSP_MGR' g_dsp_mng_lock.
*  se_config_param 'REP_USR_LOK_DSP_SLF' g_dsp_slf_lock.
*ENDFORM.                    " get_sw_repo_conifg
*&---------------------------------------------------------------------*
*&      Form  output_alv
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM output_alv.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT4'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table.
  PERFORM adjust_columns.
  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_CLICK'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output4
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

ENDFORM.                    " output_alv
*---------------------------------------------------------------------*
*       FORM output_alv_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM output_alv_con.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT_CON'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table_con.
  PERFORM adjust_columns_con.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER_CON'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_CLICK_CON'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output_con
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_alv
*---------------------------------------------------------------------*
*       FORM output_alv_user                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM output_alv_user.
  DATA: ls_variant TYPE disvariant,
        alv_layout      TYPE slis_layout_alv
        .
  DATA: l_program LIKE sy-repid.



  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_program = sy-repid.
  REFRESH : g_i_fieldcat_alv.
  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = l_program
            i_internal_tabname = 'OUTPUT_USER'
            i_inclname         = l_program
       CHANGING
            ct_fieldcat        = g_i_fieldcat_alv
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
  PERFORM build_sort_table_user.
  PERFORM adjust_columns_user.
  MESSAGE s002 WITH 'Analysis Completed'.
  COMMIT WORK.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_top_of_page   = 'ALV_HEADER_CON'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'USER_CLICK_USER'
            i_callback_program       = l_program
            is_layout                = alv_layout
            it_fieldcat              = g_i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
            it_sort                  = isort
       TABLES
            t_outtab                 = output_user
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.

ENDFORM.                    " output_alv


*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header. "#EC CALLED
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_exedate(10),
        l_exetime(8) TYPE c,
        l_alv_grid_titl2   TYPE lvc_title,
        l_user_total TYPE i,
        l_user_totalc(4) TYPE c,
         l_mandt TYPE sy-mandt,
        l_sysid TYPE sy-sysid,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

  gt_outuser_count[] = output4[].
  CLEAR : g_luser_count,
          g_laverage_count,
          g_lconf_count,
          l_user_total.

  DESCRIBE TABLE gt_sw_uinfo LINES l_user_total.
  SORT gt_outuser_count BY bname conid.
  LOOP AT gt_outuser_count.
    CHECK gt_outuser_count-conid <> 'NONE'(071).
    CHECK gt_outuser_count-conid NE space .
    AT NEW  bname.
      g_luser_count = g_luser_count + 1.
    ENDAT.
    g_lconf_count = g_lconf_count + 1.
  ENDLOOP.


  IF g_luser_count > 0.
    g_laverage_count = g_lconf_count / g_luser_count.
  ENDIF.

  g_laverage_countc = g_laverage_count.
  g_luser_countc = g_luser_count.
  g_lmit_countc = g_lmit_count.
  g_lconf_countc = g_lconf_count.
  l_user_totalc = l_user_total.

  CONCATENATE  l_user_totalc 'user(s) analyzed.'(h24)
           'Avg'(h30) g_laverage_countc 'SOD Conflict(s) in'(h25)
            g_luser_countc 'user(s)'(h29)
            INTO l_alv_grid_titl2 SEPARATED BY space.
  CONDENSE l_alv_grid_titl2.

  wa-typ = 'H'.
  wa-info = 'Segregation of Duties Summary Report'(h01).
  APPEND wa TO header.

*--sysid mandt
  CALL FUNCTION 'SCCR_GET_RELEASE_NR'
       IMPORTING
            sysid = l_sysid
            mandt = l_mandt. "#EC SAST_CI_GEN_CHECK
  wa-typ = 'S'.
  wa-key = 'System:'(h34).
  CONCATENATE l_sysid l_mandt INTO wa-info.
  CONDENSE wa-info.
  APPEND wa TO header.

  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date

  wa-typ = 'S'.
  wa-key = text-h11.
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

   CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user "sy-uname C0700
   text-h12 l_exedate l_exetime text-200 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  wa-typ = 'S'.
  wa-key = 'Summary:'(h23).
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.

  IF shomit = 'X'.
    wa-typ = 'S'.
    wa-key = 'Mitigation Summary:'(h26).
    CONCATENATE g_lconf_countc 'conflicts of which'(h27)
                g_lmit_countc 'mitigated'(h28)
                INTO wa-info SEPARATED BY space.
    CONDENSE wa-info.
    APPEND wa TO header.
  ENDIF.

*--Add some of the selection criteria to the header,
*  but only if it was a drilldown
  DATA : l_linecount TYPE i.
*--Application Area Drilldown
  IF NOT s_busa[] IS INITIAL.
    DESCRIBE TABLE s_busa LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_busa.
        wa-typ = 'S'.
        wa-key = 'Application Area:'(h40).
        IF s_busa-sign = 'I' AND s_busa-option = 'EQ'.
          wa-info = s_busa-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*--Conflict
  IF NOT s_conid[] IS INITIAL.
    DESCRIBE TABLE s_conid LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_conid.
        wa-typ = 'S'.
        wa-key = 'Conflict ID:'(h32).
        IF s_conid-sign = 'I' AND s_conid-option = 'EQ'.
          wa-info = s_conid-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE w190(/psyng/sw).
  ENDIF.


ENDFORM.
*---------------------------------------------------------------------*
*       FORM alv_header_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header_con. "#EC CALLED
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        l_exedate(10),
        l_exetime(8) TYPE c,
        l_alv_grid_titl2   TYPE lvc_title,
        l_user_total TYPE i,
        l_user_totalc(20) TYPE c,
         l_mandt TYPE sy-mandt,
        l_sysid TYPE sy-sysid,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR

*--Total conflict count includes mitigated conflicts
  CLEAR : g_lconf_count, g_lmit_count.
  IF p_o_con = 'X'.
    LOOP AT output_con.
      ADD output_con-mit_count TO g_lmit_count.
      ADD output_con-mit_count TO g_lconf_count.
      ADD output_con-count TO g_lconf_count.
    ENDLOOP.
  ELSE.
    LOOP AT output_user.
      ADD output_user-mit_count TO g_lmit_count.
      ADD output_user-mit_count TO g_lconf_count.
      ADD output_user-count TO g_lconf_count.
    ENDLOOP.

  ENDIF.


  DESCRIBE TABLE gt_sw_uinfo LINES l_user_total.
  IF g_luser_count > 0.
    g_laverage_count = g_lconf_count / g_luser_count.
  ENDIF.

  g_laverage_countc = g_laverage_count.
  g_luser_countc = g_luser_count.
  g_lmit_countc = g_lmit_count.
  g_lconf_countc = g_lconf_count.
  l_user_totalc = l_user_total.


  wa-typ = 'H'.
  wa-info = 'Segregation of Duties Summary Report'(h01).
  APPEND wa TO header.

*--sysid mandt
  CALL FUNCTION 'SCCR_GET_RELEASE_NR'
       IMPORTING
            sysid = l_sysid
            mandt = l_mandt. "#EC SAST_CI_GEN_CHECK
  wa-typ = 'S'.
  wa-key = 'System:'(h34).
  CONCATENATE l_sysid l_mandt INTO wa-info.
  CONDENSE wa-info.
  APPEND wa TO header.

  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h02).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date

  wa-typ = 'S'.
  wa-key = text-h11.
  WRITE sy-datum TO l_exedate.

  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO l_exetime SEPARATED BY ':'.

   CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR

  CONCATENATE g_current_user "sy-uname C0700
   text-h12 l_exedate l_exetime text-200 l_systemid
              INTO wa-info SEPARATED BY space.
  APPEND wa TO header.

  CONCATENATE  l_user_totalc 'user(s) analyzed.'(h24)
            INTO l_alv_grid_titl2 SEPARATED BY space.
  CONDENSE l_alv_grid_titl2.

  wa-typ = 'S'.
  wa-key = 'Summary:'(h23).
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.


  CONCATENATE 'Avg'(h30) g_laverage_countc 'SOD Conflict(s) in'(h25)
           g_luser_countc 'user(s)'(h29)
           INTO l_alv_grid_titl2 SEPARATED BY space.
  wa-typ = 'S'.
  wa-key = ''.
  wa-info = l_alv_grid_titl2.
  APPEND wa TO header.


  wa-typ = 'S'.
  wa-key = 'Mitigation Summary:'(h26).
  CONCATENATE g_lconf_countc 'conflicts of which'(h27)
              g_lmit_countc 'mitigated'(h28)
              INTO wa-info SEPARATED BY space.
  CONDENSE wa-info.
  APPEND wa TO header.


*--Add some of the selection criteria to the header,
*  but only if it was a drilldown
  DATA : l_linecount TYPE i.
*--Application Area Drilldown
  IF NOT s_busa[] IS INITIAL.
    DESCRIBE TABLE s_busa LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_busa.
        wa-typ = 'S'.
        wa-key = 'Application Area:'(h40).
        IF s_busa-sign = 'I' AND s_busa-option = 'EQ'.
          wa-info = s_busa-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.
*--Conflict
  IF NOT s_conid[] IS INITIAL.
    DESCRIBE TABLE s_conid LINES l_linecount.
    IF l_linecount = 1.
      LOOP AT s_conid.
        wa-typ = 'S'.
        wa-key = 'Conflict ID:'(h32).
        IF s_conid-sign = 'I' AND s_conid-option = 'EQ'.
          wa-info = s_conid-low.
          CONDENSE wa-info.
          APPEND wa TO header.
        ENDIF.
      ENDLOOP.
    ENDIF.
  ENDIF.



  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
       EXPORTING
            it_list_commentary = header.

  IF gf_missing_auth_ugroup = 'X'.
    MESSAGE w190(/psyng/sw).
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  build_sort_table
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM build_sort_table.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.
  IF gf_use_erp = 'X'.
    ADD 1 TO l_sort-spos.
    l_sort-fieldname = 'PERSA'.
    l_sort-tabname   = 'OUTPUT4'.
    l_sort-up        = 'X'.
    l_sort-subtot    = 'X'.
    APPEND l_sort TO isort.
    ADD 1 TO l_sort-spos.
    l_sort-fieldname = 'PERSA_TEXT'.
    l_sort-tabname   = 'OUTPUT4'.
    l_sort-up        = 'X'.
    l_sort-subtot    = 'X'.
    APPEND l_sort TO isort.
    ADD 1 TO l_sort-spos.
    l_sort-fieldname = 'KOSTL'.
    l_sort-tabname   = 'OUTPUT4'.
    l_sort-up        = 'X'.
    l_sort-subtot    = 'X'.
    APPEND l_sort TO isort.
    ADD 1 TO l_sort-spos.
    l_sort-fieldname = 'KOSTL_TEXT'.
    l_sort-tabname   = 'OUTPUT4'.
    l_sort-up        = 'X'.
    l_sort-subtot    = 'X'.
    APPEND l_sort TO isort.
  ENDIF.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname   = 'OUTPUT4'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname   = 'OUTPUT4'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'SCANDATE'.
  l_sort-tabname   = 'OUTPUT4'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
ENDFORM.                    " build_sort_table
*---------------------------------------------------------------------*
*       FORM build_sort_table_con                                     *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table_con.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  l_sort-fieldname = 'CONID'.
  l_sort-tabname   = 'OUTPUT_CON'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ' '.
  APPEND l_sort TO isort.
ENDFORM.

*---------------------------------------------------------------------*
*       FORM build_sort_table_user                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_sort_table_user.
  DATA: l_sort TYPE slis_sortinfo_alv.
  REFRESH : isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname   = 'OUTPUT_USER'.
  l_sort-up        = 'X'.
  l_sort-subtot    = 'X'.
  APPEND l_sort TO isort.
  ADD 1 TO l_sort-spos.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname   = 'OUTPUT_USER'.
  l_sort-up        = 'X'.
  l_sort-subtot    = ''.
  APPEND l_sort TO isort.
ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  adjust_columns
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
FORM adjust_columns.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.





  wa_fieldcat_alv-seltext_l = text-h06.
  wa_fieldcat_alv-seltext_m = text-h06.
  wa_fieldcat_alv-seltext_s = text-h06.
  wa_fieldcat_alv-reptext_ddic = text-h06.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'ICON'.

  wa_fieldcat_alv-seltext_l = text-h09.
  wa_fieldcat_alv-seltext_m = text-h09.
  wa_fieldcat_alv-seltext_s = text-h10.
  wa_fieldcat_alv-reptext_ddic = text-h09.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'SCANDATE'.

  IF shomit IS INITIAL.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      hotspot
                   WHERE
                      fieldname = 'CONTID'.

  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                      hotspot
                   WHERE
                      fieldname = 'CONID'.
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'BNAME'.

  wa_fieldcat_alv-seltext_l = text-h20.
  wa_fieldcat_alv-seltext_m = text-h20.
  wa_fieldcat_alv-seltext_s = text-h20.
  wa_fieldcat_alv-reptext_ddic = text-h20.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_COUNT'.

  wa_fieldcat_alv-seltext_l = text-h31.
  wa_fieldcat_alv-seltext_m = text-h31.
  wa_fieldcat_alv-seltext_s = text-h31.
  wa_fieldcat_alv-reptext_ddic = text-h31.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AUDITOR'.

  wa_fieldcat_alv-seltext_l = text-h21.
  wa_fieldcat_alv-seltext_m = text-h21.
  wa_fieldcat_alv-seltext_s = text-h21.
  wa_fieldcat_alv-reptext_ddic = text-h21.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_DATE_FROM'.

  wa_fieldcat_alv-seltext_l = text-h22.
  wa_fieldcat_alv-seltext_m = text-h22.
  wa_fieldcat_alv-seltext_s = text-h22.
  wa_fieldcat_alv-reptext_ddic = text-h22.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_DATE_TO'.

  wa_fieldcat_alv-fieldname = 'KOSTL_TEXT'.
  wa_fieldcat_alv-seltext_l = text-h19.
  wa_fieldcat_alv-seltext_m = text-h19.
  wa_fieldcat_alv-seltext_s = text-h19.
  wa_fieldcat_alv-reptext_ddic = text-h19.
  wa_fieldcat_alv-col_pos   = 4.
  APPEND wa_fieldcat_alv TO g_i_fieldcat_alv.

  wa_fieldcat_alv-col_pos   = 2.
  wa_fieldcat_alv-seltext_l = text-h13.
  wa_fieldcat_alv-seltext_m = text-h13.
  wa_fieldcat_alv-seltext_s = text-h13.
  wa_fieldcat_alv-reptext_ddic = text-h13.
  wa_fieldcat_alv-fieldname = 'PERSA_TEXT'.
  APPEND wa_fieldcat_alv TO g_i_fieldcat_alv.


  IF gf_use_erp <> 'X'.
    DELETE g_i_fieldcat_alv WHERE
      fieldname = 'PERSA_TEXT' OR
      fieldname = 'PERSA' OR
      fieldname = 'KOSTL' OR
      fieldname = 'KOSTL_TEXT'.
  ENDIF.
*--No Longer output Risk Field
  DELETE g_i_fieldcat_alv WHERE
    fieldname = 'RISK'.

ENDFORM.                    " adjust_columns
*---------------------------------------------------------------------*
*       FORM adjust_columns_con                                       *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM adjust_columns_con.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.
  wa_fieldcat_alv-seltext_l = text-h20.
  wa_fieldcat_alv-seltext_m = text-h20.
  wa_fieldcat_alv-seltext_s = text-h20.
  wa_fieldcat_alv-reptext_ddic = text-h20.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_COUNT'.
*--Add hotspots
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    hotspot
                WHERE fieldname = 'BUSAREA' OR
                      fieldname = 'CONID'.
*--Enable subtotal counting
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    do_sum
                WHERE fieldname = 'COUNT' OR
                      fieldname = 'MIT_COUNT'.

ENDFORM.
*---------------------------------------------------------------------*
*       FORM adjust_columns_user                                      *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM adjust_columns_user.

  DATA: wa_fieldcat_alv TYPE slis_fieldcat_alv.
  wa_fieldcat_alv-seltext_l = text-h04.
  wa_fieldcat_alv-seltext_m = text-h04.
  wa_fieldcat_alv-seltext_s = text-h05.
  wa_fieldcat_alv-reptext_ddic = text-h04.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'COUNT'.
  wa_fieldcat_alv-seltext_l = text-h20.
  wa_fieldcat_alv-seltext_m = text-h20.
  wa_fieldcat_alv-seltext_s = text-h20.
  wa_fieldcat_alv-reptext_ddic = text-h20.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'MIT_COUNT'.
*--Add hotspots
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv "#EC SAST_CI_GEN_CHECK
                  TRANSPORTING
                    hotspot
                WHERE fieldname = 'BNAME' OR
                      fieldname = 'CLASS'.

*--Enable subtotal counting
  wa_fieldcat_alv-do_sum = 'X'.
  MODIFY g_i_fieldcat_alv FROM wa_fieldcat_alv
                  TRANSPORTING
                    do_sum
                WHERE fieldname = 'COUNT' OR
                      fieldname = 'MIT_COUNT'.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_initial_config
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
*FORM get_initial_config.
*  IF drill IS INITIAL.
**--Initialize fields if this is not a drilldown event
*    DATA : l_value TYPE /psyng/param_value.
**Valid & Dialog Users only
*    se_config_param 'DFLT_VALID_DIALOG' l_value.
*    IF l_value = 'Y'.
*      validusr = 'X'.
*    ELSEIF l_value = 'N'.
*      validusr = ' '.
*    ENDIF.
*    CLEAR l_value.
*  ENDIF.
*ENDFORM.                    " get_initial_config

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
  if sy-subrc = 0.
    READ TABLE lth_return INTO wah_return INDEX 1.
    IF sy-subrc = 0.
      p_usrtype_low = wah_return-fieldval.
    ENDIF.
  endif.
ENDFORM.                    " f4_usrtype

*---------------------------------------------------------------------*
*       FORM pf_status_summary                                        *
*---------------------------------------------------------------------*
*       Set PF status for summary screen                              *
*---------------------------------------------------------------------*
*  -->  IT_EXTAB                                                      *
*---------------------------------------------------------------------*
FORM pf_status "#EC CALLED
  USING it_extab TYPE slis_t_extab."#EC NEEDED
  DATA: BEGIN OF lt_func OCCURS 0,
          fcode LIKE rsmpe-func,
        END OF lt_func.

  IF gf_missing_auth_ugroup IS INITIAL.
    lt_func-fcode = 'FUSER'.
    APPEND lt_func.
  ENDIF.


  SET PF-STATUS 'SUM' EXCLUDING lt_func.
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
*---------------------------------------------------------------------*
*       FORM user_click_con                                           *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_click_con           "#EC CALLED
  USING r_ucomm LIKE sy-ucomm "#EC NEEDED
        rs_selfield TYPE slis_selfield.
  DATA :  lt_seltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  CASE rs_selfield-fieldname.
    WHEN 'BUSAREA'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'S_BUSA' OR selname = 'P_O_CON'.
      add_sel lt_seltab 'S_BUSA'  'S' 'I' 'EQ' rs_selfield-value ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' '' ''.
      add_sel lt_seltab 'P_O_USR' 'P' 'I' 'EQ' 'X' ''.
      add_sel lt_seltab 'P_FLAG' 'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_rp WITH SELECTION-TABLE lt_seltab
      AND RETURN.
    WHEN 'CONID'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'S_CONID' OR selname = 'P_O_CON'.
      add_sel lt_seltab 'S_CONID' 'S' 'I' 'EQ' rs_selfield-value ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' '' ''.
      add_sel lt_seltab 'P_O_USR' 'P' 'I' 'EQ' 'X' ''.
      add_sel lt_seltab 'P_FLAG' 'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_rp WITH SELECTION-TABLE lt_seltab
      AND RETURN.
  ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM user_click_user                                          *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM user_click_user          "#EC CALLED
  USING r_ucomm LIKE sy-ucomm "#EC NEEDED
        rs_selfield TYPE slis_selfield.
  DATA :  lt_seltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  CASE rs_selfield-fieldname.
    WHEN 'CLASS'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'PCLASS' OR selname = 'P_O_CON'.
      add_sel lt_seltab 'PCLASS'  'S' 'I' 'EQ' rs_selfield-value ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' '' ''.
      add_sel lt_seltab 'P_O_DET' 'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_rp WITH SELECTION-TABLE lt_seltab
      AND RETURN.
    WHEN 'BNAME'.
      PERFORM get_current_selection
                  TABLES
                     lt_seltab.
      DELETE lt_seltab WHERE selname = 'PBNAME' OR selname = 'P_O_CON'.
      add_sel lt_seltab 'PBNAME'  'S' 'I' 'EQ' rs_selfield-value ''.
      add_sel lt_seltab 'P_O_CON' 'P' 'I' 'EQ' '' ''.
      add_sel lt_seltab 'P_O_DET' 'P' 'I' 'EQ' 'X' ''.
      SUBMIT /psyng/sw_sod_sum_rp WITH SELECTION-TABLE lt_seltab
      AND RETURN.
  ENDCASE.
ENDFORM.
*---------------------------------------------------------------------*
*       FORM get_current_selection                                    *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  ET_SELTAB                                                     *
*---------------------------------------------------------------------*
FORM get_current_selection TABLES et_seltab STRUCTURE rsparams.
  REFRESH : et_seltab.
*--SOD Version
  add_sel et_seltab 'SODVRSIO'  'P' 'I' 'EQ' sodvrsio ''.

*--User Name
  LOOP AT pbname.
    add_sel et_seltab 'PBNAME'  'S'
            pbname-sign pbname-option pbname-low pbname-high.
  ENDLOOP.
*--User group
  LOOP AT pclass.
    add_sel et_seltab 'PCLASS'  'S'
            pclass-sign pclass-option pclass-low pclass-high.
  ENDLOOP.
*--Conflicts
  LOOP AT s_conid.
    add_sel et_seltab 'S_CONID'  'S'
            s_conid-sign s_conid-option s_conid-low s_conid-high.
  ENDLOOP.
*--Application Areas
  LOOP AT s_busa.
    add_sel et_seltab 'S_BUSA'  'S'
            s_busa-sign s_busa-option s_busa-low s_busa-high.
  ENDLOOP.
*--Sensitivity
  LOOP AT s_imp.
    add_sel et_seltab 'S_IMP'  'S'
            s_imp-sign s_imp-option s_imp-low s_imp-high.
  ENDLOOP.
*--Risk
  LOOP AT s_risk.
    add_sel et_seltab 'S_RISK'  'S'
            s_risk-sign s_risk-option s_risk-low s_risk-high.
  ENDLOOP.
*--Cost Center
  LOOP AT s_kostl.
    add_sel et_seltab 'S_KOSTL'  'S'
            s_kostl-sign s_kostl-option s_kostl-low s_kostl-high.
  ENDLOOP.


*--Show Mitigated
  add_sel et_seltab 'SHOMIT'  'P' 'I' 'EQ' shomit ''.
*--Show Conflicted
  add_sel et_seltab 'P_CON'  'P' 'I' 'EQ' p_con ''.
*--Show users without conflicts
  add_sel et_seltab 'P_NONE'  'P' 'I' 'EQ' p_none ''.
*--Show users without info
  add_sel et_seltab 'P_NOINF'  'P' 'I' 'EQ' p_noinf ''.
*--Scan Table
  add_sel et_seltab 'P_STD'  'P' 'I' 'EQ' p_std ''.
  add_sel et_seltab 'P_ENH'  'P' 'I' 'EQ' p_enh ''.
*--Valid User
  add_sel et_seltab 'VALIDUSR' 'P' 'I' 'EQ' validusr ''.
*--Exclude Locked
  add_sel et_seltab 'EXLCKUSR' 'P' 'I' 'EQ'  exlckusr ''.
*--User Type
  LOOP AT usrtype.
    add_sel et_seltab 'USRTYPE'  'S'
            usrtype-sign usrtype-option usrtype-low usrtype-high.
  ENDLOOP.
*--User val date
  add_sel et_seltab 'OUTVDATE' 'P' 'I' 'EQ'  outvdate ''.
*--Mark this as a drilldown event
  add_sel et_seltab 'DRILL' 'P' 'I' 'EQ'  'X' ''.


ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  USER_CLICK
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_click  "#EC CALLED
  USING r_ucomm LIKE sy-ucomm
        rs_selfield TYPE slis_selfield.
  DATA:  l_uname        LIKE sy-uname,
*        l_contid TYPE /psyng/mchdr-contid,
        l_parva        TYPE usr05-parva,
        l_sod          TYPE /psyng/swsodvers-vrsio.

  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE rs_selfield-fieldname.
    WHEN 'CONTID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/SW_MIT' FIELD rs_selfield-value.
      g_dynnr = '0211'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
      EXIT.
    WHEN 'CONID'.
      CHECK rs_selfield-value <> space.
      l_uname = g_current_user. "sy-uname. C0700
*-- Get user's default version
      SELECT SINGLE parva INTO l_parva FROM usr05
                 WHERE bname = l_uname
                   AND parid = '/PSYNG/VRSIO'.
      IF sy-subrc = 0 AND l_parva <> space.
        l_sod = l_parva.
      ENDIF.

      PERFORM set_default_sodversion USING sodvrsio l_uname.
      SET PARAMETER ID '/PSYNG/CON' FIELD rs_selfield-value.
      g_dynnr = '0202'.
      EXPORT g_dynnr FROM g_dynnr TO MEMORY ID '/PSYNG/DYNNR'.
      AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD '/PSYNG/SE'.
      IF sy-subrc <> 0.
        MESSAGE e077(s#) WITH '/PSYNG/SE'.
      else.
        CALL TRANSACTION '/PSYNG/SE'.
      endif.
*-- Set back to Default
      PERFORM set_default_sodversion USING l_sod l_uname.
   when 'BNAME'.
      READ TABLE output4 INDEX rs_selfield-tabindex.
      if sy-subrc = 0.
       perform user_drilldown using
         output4-bname
         output4-conid.
      endif.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  set_default_sodversion
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_L_SOD  text
*      -->P_L_UNAME  text
*----------------------------------------------------------------------*
FORM set_default_sodversion USING l_sod TYPE /psyng/swsodvers-vrsio
                                  l_uname TYPE sy-uname.
  DATA: lt_param  TYPE TABLE OF bapiparam WITH HEADER LINE,
          lt_return TYPE TABLE OF bapiret2 WITH HEADER LINE,
          ls_paramx TYPE bapiparamx.


  SELECT parid parva INTO TABLE lt_param FROM usr05  "#EC CI_SEL_NESTED
         WHERE bname = l_uname.

  READ TABLE lt_param WITH KEY parid = '/PSYNG/VRSIO'.
  lt_param-parva = l_sod.

  IF sy-subrc = 0.
    MODIFY lt_param INDEX sy-tabix.
  ELSE.
    lt_param-parid = '/PSYNG/VRSIO'.
    APPEND lt_param.
  ENDIF.

  ls_paramx-parid = 'X'.
  ls_paramx-parva = 'X'.
  CALL FUNCTION 'BAPI_USER_CHANGE' "#EC SAST_CI_GEN_CHECK (HBHALLA)
       EXPORTING
            username   = l_uname
            parameterx = ls_paramx
       TABLES
            parameter  = lt_param
            return     = lt_return.

ENDFORM.                    " set_default_sodversion
*&---------------------------------------------------------------------*
*&      Form  conflict_summary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM conflict_summary.
  MESSAGE s002 WITH 'Loading Conflict Summary Data'.
  COMMIT WORK.
  DATA : lt_uinfo_sorted TYPE HASHED TABLE OF /psyng/sw_uinfo
           WITH UNIQUE KEY bname  WITH HEADER LINE.
  FIELD-SYMBOLS : <out> LIKE output_con.

  DATA : lt_confl_users TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  IF p_enh = 'X'.
*    g_scantable = '/PSYNG/ENHSCANDT'.
  SELECT bname conid contid FROM /PSYNG/ENHSCANDT
           INTO CORRESPONDING FIELDS OF TABLE scandt
           WHERE
                 vrsio =  sodvrsio AND
                 conid IN gr_conid."#EC SAST_CI_GEN_CHECK
  ELSE.
*    g_scantable = '/PSYNG/SYSCANDT'.
  SELECT bname conid contid FROM /PSYNG/SYSCANDT
           INTO CORRESPONDING FIELDS OF TABLE scandt
           WHERE
                 vrsio =  sodvrsio AND
                 conid IN gr_conid."#EC SAST_CI_GEN_CHECK
  ENDIF.

**  SELECT bname conid contid FROM (g_scantable)
**           INTO CORRESPONDING FIELDS OF TABLE scandt
**           WHERE
**                 vrsio =  sodvrsio AND
**                 conid IN gr_conid."#EC SAST_CI_GEN_CHECK
***HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25

*delete scandt where not bname  in    lt_bname.
  lt_uinfo_sorted[] = gt_sw_uinfo[].
  CLEAR : g_lconf_count, g_lmit_count.
  LOOP AT scandt.
    READ TABLE lt_uinfo_sorted WITH TABLE KEY bname = scandt-bname
    TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    lt_confl_users-bname = scandt-bname.
    COLLECT lt_confl_users.
    CLEAR output_con.
    output_con-conid = scandt-conid.
    IF NOT scandt-contid IS INITIAL.
      output_con-mit_count = 1.
      ADD 1 TO g_lmit_count.
    ELSE.
      output_con-count = 1.
      ADD 1 TO g_lconf_count.
    ENDIF.
    COLLECT output_con.
  ENDLOOP.
*--Add conflict Texts
  gt_conflict_sorted[] = gt_conid[].
  LOOP AT output_con ASSIGNING <out>.
    READ TABLE gt_conflict_sorted
    WITH TABLE KEY conid = <out>-conid.
    IF sy-subrc = 0.
      <out>-con_text = gt_conflict_sorted-description.
      <out>-busarea  = gt_conflict_sorted-busarea.
      <out>-imp      = gt_conflict_sorted-imp.

    ELSE.
*       custom conflict
      READ TABLE gt_cuscon WITH KEY conid = <out>-conid
      BINARY SEARCH.
      IF sy-subrc = 0.
        <out>-con_text = gt_cuscon-cdesc.
        <out>-busarea  = gt_cuscon-busarea.
        <out>-imp      = gt_cuscon-imp.
      ENDIF.
    ENDIF.
  ENDLOOP.
  DESCRIBE TABLE lt_confl_users LINES g_luser_count.
  PERFORM output_alv_con.
ENDFORM.                    " conflict_summary
*&---------------------------------------------------------------------*
*&      Form  user_summary
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM user_summary.
  MESSAGE s002 WITH 'Loading User Summary Data'.
  COMMIT WORK.

  DATA : lt_uinfo_sorted TYPE HASHED TABLE OF /psyng/sw_uinfo
           WITH UNIQUE KEY bname  WITH HEADER LINE.
  FIELD-SYMBOLS : <out> LIKE output_user.
  DATA : lt_confl_users TYPE TABLE OF /psyng/sw_uinfo WITH HEADER LINE.

*--> BOC PN 11269 - ATC fixes - HBHALLA - 23/01/25
  IF p_enh = 'X'.
*    g_scantable = '/PSYNG/ENHSCANDT'.
  SELECT bname conid contid FROM /PSYNG/ENHSCANDT
           INTO CORRESPONDING FIELDS OF TABLE scandt
           WHERE
                 vrsio =  sodvrsio AND
                 conid IN gr_conid. "#EC SAST_CI_GEN_CHECK
  ELSE.
*    g_scantable = '/PSYNG/SYSCANDT'.
  SELECT bname conid contid FROM /PSYNG/SYSCANDT
           INTO CORRESPONDING FIELDS OF TABLE scandt
           WHERE
                 vrsio =  sodvrsio AND
                 conid IN gr_conid. "#EC SAST_CI_GEN_CHECK
  ENDIF.

**  SELECT bname conid contid FROM (g_scantable)
**           INTO CORRESPONDING FIELDS OF TABLE scandt
**           WHERE
**                 vrsio =  sodvrsio AND
**                 conid IN gr_conid. "#EC SAST_CI_GEN_CHECK
***HBHALLA: As table name is variable so it can’t be fixed. (13/12/24)
*--> EOC PN 11269 - ATC fixes - HBHALLA - 23/01/25

*delete scandt where not bname  in    lt_bname.
  lt_uinfo_sorted[] = gt_sw_uinfo[].
  CLEAR : g_lconf_count, g_lmit_count.

  LOOP AT scandt.
    READ TABLE lt_uinfo_sorted WITH TABLE KEY bname = scandt-bname
    TRANSPORTING NO FIELDS.
    CHECK sy-subrc = 0.
    lt_confl_users-bname = scandt-bname.
    COLLECT lt_confl_users.
    CLEAR output_user.
    output_user-bname = scandt-bname.
    IF NOT scandt-contid IS INITIAL.
      output_user-mit_count = 1.
      ADD 1 TO g_lmit_count.
    ELSE.
      output_user-count = 1.
      ADD 1 TO g_lconf_count.
    ENDIF.
    COLLECT output_user.
  ENDLOOP.
*--Add User Information
  WAIT UNTIL g_functioncall_1 = g_done.
  LOOP AT output_user ASSIGNING <out>.
    READ TABLE lt_uinfo_sorted
    WITH TABLE KEY bname = <out>-bname.
    IF sy-subrc = 0.
      <out>-name_text =  lt_uinfo_sorted-name_text.
      <out>-class    = lt_uinfo_sorted-class.
    ENDIF.
  ENDLOOP.
  DESCRIBE TABLE lt_confl_users LINES g_luser_count.
  PERFORM output_alv_user.

ENDFORM.                    " user_summary
*&---------------------------------------------------------------------*
*&      Form  user_drilldown
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_OUTPUT4  text
*----------------------------------------------------------------------*
form user_drilldown using
  i_bname type xubname
  i_conid type /psyng/conflict_id.


define add_sel_par.
    lt_iseltab-selname = &1.
    lt_iseltab-kind    = &2.
    lt_iseltab-sign    = 'I'.
    lt_iseltab-option  = 'EQ'.
    lt_iseltab-low     = &3.
    APPEND lt_iseltab.
end-of-definition.
data : l_answer,
       lt_iseltab  TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.
      CLEAR l_answer.
      CALL FUNCTION 'POPUP_TO_DECIDE_WITH_MESSAGE'
           EXPORTING 	"#EC FB_OLDED
                defaultoption     = '2'
                diagnosetext1     =
'You can view User Master Record (in transaction SU01) or'(055)
                diagnosetext2     =
'you can perform SOD analysis on this user'(056)
                textline1         =
'View user master or Analyze?'(057)
                text_option1      =
'User Master'(058)
                text_option2      =
'Analyze'(059)
                icon_text_option1 = 'ICON_TBH'
                icon_text_option2 = 'ICON_HISTORY'
                titel             =
'User Master or SOD Analysis'(060)
                cancel_display    = 'X'
           IMPORTING
                answer            = l_answer.

      CASE l_answer.
        WHEN '1'.
*          AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01'.
*Begin of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
          IF sy-subrc = 1.
            SET PARAMETER ID 'XUS' FIELD i_bname.
            CALL TRANSACTION 'SU01'.
          ELSE.
*            AUTHORITY-CHECK OBJECT 'S_TCODE' ID 'TCD' FIELD 'SU01D'.
        CALL FUNCTION 'AUTHORITY_CHECK_TCODE'
          EXPORTING
            tcode         = 'SU01D'
         EXCEPTIONS
           OK            = 1
           NOT_OK        = 2
           OTHERS        = 3.
            IF sy-subrc = 1.
              SET PARAMETER ID 'XUS' FIELD i_bname.
              CALL TRANSACTION 'SU01D'.
            ELSE.
              MESSAGE e077(s#) WITH 'SU01D'.
            ENDIF.
          ENDIF.
*End of Addition:HBHALLA(CVA_PR2_Static txn call)(05/05/26)
        WHEN '2'.
          add_sel_par :
            'SODVRSIO' 'P' SODVRSIO,
            'P_ABAP'   'P' 'X',
            'PBNAME'   'S' i_bname,
            'SPCONFS'  'S' i_conid,
            'BYUSER'   'P' 'X',
            'SHODET'   'P' 'X',
            'SHOSUM'   'P' '',
            'XMC'      'P' ''.
          SUBMIT /psyng/sodreport_org WITH SELECTION-TABLE lt_iseltab
          AND RETURN.



      endcase.

endform.                    " user_drilldown


FORM get_users_count.
  DATA : "l_numb TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c.

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

CALL FUNCTION '/PSYNG/BC_COUNT_USERS'
 EXPORTING
   I_VALIDUSER             = validusr
   I_INCLUDE_LOCKED        = lv_exlckusr
   I_INCLUDE_EXPIRED       = lv_outvdate
   IF_LOCAL_SYSTEM         = 'X'
   IF_SHOW_MESSAGE         = 'X'
* IMPORTING
*   E_USERCOUNT             = l_numb
 TABLES
   IT_USERLIST             = pbname
   IT_GROUPLIST            = pclass
   IT_USERTYPE             = usrtype
*   IT_ACTGROUPS            = s_role
*   IT_PROFILE              = s_prof
*   IT_RFCRANGE             = xusrrfc
*   IT_RFCLIST              =
*   IT_DEPARTMENT           = s_depart
*   IT_COMPANY              = s_comp
*   IT_CUID                 = s_cuid
    .
ENDFORM.                    " get_users_count
