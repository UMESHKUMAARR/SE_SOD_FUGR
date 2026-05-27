*----------------------------------------------------------------------*
* PROGRAM               : /PSYNG/CRI_TCODE_LIST
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

REPORT /psyng/cri_tcode_list NO STANDARD PAGE HEADING LINE-SIZE 255.
INCLUDE /PSYNG/SW_CONFIG.
INCLUDE /psyng/sw_125.
include /PSYNG/CRI_TCODE_LIST_top.



SELECTION-SCREEN: BEGIN OF BLOCK blk1 WITH FRAME TITLE text-001.
SELECTION-SCREEN BEGIN OF LINE.
SELECTION-SCREEN PUSHBUTTON  68(12) text-198 USER-COMMAND verify_u
                                      MODIF ID usr.
SELECTION-SCREEN END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(23) text-002.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: uid FOR usr02-bname.      "User ID
*SELECT-OPTIONS: s_class FOR usr02-class.                     "User
*Group
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(23) text-046.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: s_class FOR usr02-class.                    "User Group
SELECTION-SCREEN: END OF LINE.


*RFC destination for remote analysis
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(23) text-047.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: remrfc FOR rfcdes-rfcdest MATCHCODE OBJECT
/psyng/sw_rfcsh_coll MODIF ID rem.
SELECTION-SCREEN: END OF LINE.

*-- User type & valid user screen
SELECTION-SCREEN INCLUDE BLOCKS b_usr.


*SELECTION-SCREEN: BEGIN OF LINE.
*PARAMETERS: validusr AS CHECKBOX DEFAULT 'X' USER-COMMAND usr_fil.
*"valid & dialog users
*SELECTION-SCREEN: COMMENT 3(50) text-000.
*SELECTION-SCREEN: END OF LINE.
*
*SELECT-OPTIONS : usrtype FOR usertype MODIF ID usr .
*PARAMETERS: exlckusr AS CHECKBOX DEFAULT 'X'  MODIF ID usr.


SELECTION-SCREEN: BEGIN OF LINE.
PARAMETERS:remote AS CHECKBOX USER-COMMAND remo DEFAULT ' '.
SELECTION-SCREEN: COMMENT 3(50) text-049.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: SKIP 1.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 3(60) text-003.            "Restrict text
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(23) text-004.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: tcodes FOR tstct-tcode.             "Tcode
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(20) text-005.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: roles FOR agr_tcodes-agr_name.       "Role
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(22) text-006.
SELECTION-SCREEN POSITION 26.
*SELECT-OPTIONS: profiles FOR ust04-profile.         "Profiles
SELECT-OPTIONS: profiles FOR /psyng/criprof-profile.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(22) text-017.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: p_imp FOR /psyng/critcodes-imp.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(22) text-018.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: p_owner FOR /psyng/critcodes-owner.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 6(22) text-028.
SELECTION-SCREEN POSITION 26.
SELECT-OPTIONS: p_busare FOR /psyng/critcodes-busarea.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk1.


*Version selection
SELECTION-SCREEN: BEGIN OF BLOCK blk0 WITH FRAME TITLE text-045.
PARAMETER : sodvrsio LIKE /psyng/conflict-vrsio DEFAULT '0'.
SELECTION-SCREEN: END OF BLOCK blk0 .
*version selection


SELECTION-SCREEN: BEGIN OF BLOCK blk2 WITH FRAME TITLE text-011.

*SELECTION-SCREEN POSITION 16.
SELECTION-SCREEN: BEGIN OF LINE.
PARAMETER: alvsum RADIOBUTTON GROUP 1 DEFAULT 'X' USER-COMMAND a.
SELECTION-SCREEN COMMENT 4(11) text-008.
**SELECTION-SCREEN COMMENT (11) text-008.

SELECTION-SCREEN POSITION 25.
PARAMETER: alvdet RADIOBUTTON GROUP 1.              "ALV Detail
SELECTION-SCREEN COMMENT 29(11) text-007.
SELECTION-SCREEN: END OF LINE.

PARAMETERS : sumfunc TYPE flag.

*SELECTION-SCREEN POSITION 33.
*SELECTION-SCREEN POSITION 39.
*PARAMETER: stdsum RADIOBUTTON GROUP 1.              "Standard Summary
**SELECTION-SCREEN COMMENT (16) text-009.
*SELECTION-SCREEN COMMENT 41(25) text-009.


SELECTION-SCREEN: END OF BLOCK blk2.

SELECTION-SCREEN: SKIP 2.

SELECTION-SCREEN: BEGIN OF BLOCK blk3 WITH FRAME TITLE text-012.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-010.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-013.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-014.
SELECTION-SCREEN: END OF LINE.
SELECTION-SCREEN: BEGIN OF LINE.
SELECTION-SCREEN COMMENT 1(70) text-015.
SELECTION-SCREEN: END OF LINE.

SELECTION-SCREEN: END OF BLOCK blk3.

INITIALIZATION.
  PERFORM exelog.
  PERFORM initialize.
*  PERFORM set_def_usrtype.
* BOC by RGUPTA on 28.03.22 for C0700
  CLEAR g_current_user.
  CALL METHOD cl_abap_syst=>get_user_name
    RECEIVING
      user_name = g_current_user.
* EOC by RGUPTA on 28.03.22 for C0700
AT SELECTION-SCREEN ON VALUE-REQUEST FOR tcodes-low.
  PERFORM f4_tcodes CHANGING tcodes-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR tcodes-high.
  PERFORM f4_tcodes CHANGING tcodes-high.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-low.
  PERFORM f4_usrtype CHANGING usrtype-low.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR usrtype-high.
  PERFORM f4_usrtype CHANGING usrtype-high.

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

      WHEN 'SUMFUNC'.
        IF alvsum <> 'X'.
          screen-input = 0.
          CLEAR sumfunc.
        ELSE.
          screen-input = 1.
        ENDIF.
        MODIFY SCREEN.
    ENDCASE.
  ENDLOOP.

AT SELECTION-SCREEN.

  PERFORM at_selection_screen.

****Only remote analysis Check
  IF sy-ucomm = 'REMO'.
    IF remote = 'X'.
      IF remrfc[] IS INITIAL.
        MESSAGE w140(/psyng/sw) WITH
        'Please enter RFC destinations for remote analysis'(180).
      ENDIF.
    ENDIF.
  ENDIF.
  IF sy-ucomm = 'VERIFY_U'.
    PERFORM get_users_count.
    EXIT.
  ENDIF.


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
*--Clear system filter buffer when a new analysis starts
CALL FUNCTION '/PSYNG/SW_124'
    EXPORTING IF_CLEAR_BUFFER = 'X'
"(++)BOC UMITTAL SE VF scan-25/11/2024
    EXCEPTIONS
      too_many_options = 1
      OTHERS           = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.  .

  program = sy-repid.

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
    gf_use_erp = 'X'.

    CREATE OBJECT go_erp_class TYPE (gc_erp_class).
    IF sy-subrc <> 0.
      CLEAR gf_use_erp.
    ENDIF.
  ELSE.
    CLEAR gf_use_erp.
  ENDIF.


  IF NOT remrfc[] IS INITIAL.
    PERFORM rfc_validations.
  ENDIF.
**get RFC destination.
*  PERFORM get_rfc_destinations.

* add local system to list of rfc destinations
  IF remote NE 'X'.
    CONCATENATE sy-sysid sy-mandt INTO gt_rfcdest-rfcoptions.
    CONCATENATE sy-sysid sy-mandt INTO g_local_sys.
    gt_rfcdest-rfcdest = 'LOCAL'.
    APPEND gt_rfcdest.
  ENDIF.

* get user
  PERFORM get_user.

* For roles and profile filter
* Check whether user has access to roles or profile entered in
* selection screen or not, then only he/she access to tcodes !!
*  PERFORM check_user_access.
* get all table data
  IF NOT gt_uinfo[] IS INITIAL.
    gt_uinfo_temp[] = gt_uinfo[].
    SORT gt_uinfo BY rfcdest bname.
    DELETE ADJACENT DUPLICATES FROM gt_uinfo_temp
      COMPARING rfcdest bname.
    DESCRIBE TABLE gt_uinfo_temp LINES g_usercount.
    PERFORM get_critical_data.
* get get auth. data by user
    PERFORM get_data_by_user.
* filter critical tcode with sod matrix critical tcode
    PERFORM build_output.

    PERFORM fill_other_data.
  ENDIF.



  IF alvsum = 'X'.
*--DHORIONS 2015/07/08 to Conserve memory data was directly added to
*  correct table in fill_other_data
*    LOOP AT outab2.
*      MOVE-CORRESPONDING outab2 TO outab3.
*      APPEND outab3.
*      DELETE outab2.
*    ENDLOOP.
    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s190(/psyng/sw).
    ELSE.
      IF outab3[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
        EXIT.
      ELSE.
        MESSAGE s176(/psyng/sw).
      ENDIF.
    ENDIF.
    PERFORM build_alv_catalog_outab3.
    PERFORM output_using_alv_outab3.
  ELSEIF alvdet = 'X'.
    IF gf_missing_auth_ugroup = 'X'.
      MESSAGE s190(/psyng/sw).
    ELSE.
      IF outab4[] IS INITIAL.
        MESSAGE s174(/psyng/sw).
        EXIT.
      ELSE.
        MESSAGE s176(/psyng/sw).
      ENDIF.
    ENDIF.
    PERFORM build_alv_catalog_outab4.
    PERFORM output_using_alv_outab4.
  ENDIF.


TOP-OF-PAGE.
  IF gf_use_erp = 'X'.
    WRITE:/ 'PA', 5 text-019.
  ENDIF.

  WRITE:/10 text-020, 31 text-021.
  WRITE:/20 text-022.

  IF gf_use_erp = 'X'.
    WRITE: 41 text-023.
  ENDIF.

  WRITE:/30 text-024, 43 text-025, 124 text-026,
          135 text-027.
  ULINE.

*&---------------------------------------------------------------------
*
*&      Form  BUILD_ALV_CATALOG_OUTAB3
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
FORM build_alv_catalog_outab3.


  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'OUTAB3'
            i_inclname         = program
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .

  wa_fieldcat_alv-seltext_l = text-d01.
  wa_fieldcat_alv-seltext_m = text-d01.
  wa_fieldcat_alv-seltext_s = text-d01.
  wa_fieldcat_alv-reptext_ddic = text-d01.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BNAME'.

  IF sumfunc = 'X'.
    wa_fieldcat_alv-no_out = ''.
  ELSE.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l = text-030.
  wa_fieldcat_alv-seltext_m = text-030.
  wa_fieldcat_alv-seltext_s = text-030.
  wa_fieldcat_alv-reptext_ddic = text-030.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'FUNCTIONID'.

  IF sumfunc = 'X'.
    wa_fieldcat_alv-no_out = ''.
  ELSE.
    wa_fieldcat_alv-no_out = 'X'.
  ENDIF.
  wa_fieldcat_alv-seltext_l = text-029.
  wa_fieldcat_alv-seltext_m = text-027.
  wa_fieldcat_alv-seltext_s = text-027.
  wa_fieldcat_alv-reptext_ddic = text-029.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                      no_out
                   WHERE
                      fieldname = 'FUNDES'.

  wa_fieldcat_alv-seltext_l = 'System/Client'(048).
  wa_fieldcat_alv-seltext_m = 'System/Client'(048).
  wa_fieldcat_alv-seltext_s = 'System/Client'(048).
  wa_fieldcat_alv-reptext_ddic = 'System/Client'(048).
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.


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
                      fieldname = 'STATUS'.

  wa_fieldcat_alv-seltext_l = text-d07.
  wa_fieldcat_alv-seltext_m = text-d07.
  wa_fieldcat_alv-seltext_s = text-d07.
  wa_fieldcat_alv-reptext_ddic = text-d07.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat_alv-seltext_l = text-d08.
  wa_fieldcat_alv-seltext_m = text-d08.
  wa_fieldcat_alv-seltext_s = text-d09.
  wa_fieldcat_alv-reptext_ddic = text-d08.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BUSAREA'.


  wa_fieldcat_alv-seltext_l = text-d12.
  wa_fieldcat_alv-seltext_m = text-d12.
  wa_fieldcat_alv-seltext_s = text-d12.
  wa_fieldcat_alv-reptext_ddic = text-d12.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'DEPARTMENT'.



  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.


  wa_fieldcat_alv-no_out = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      no_out
                   WHERE
                      fieldname = 'COMPSHORT'.

  wa_fieldcat_alv-col_pos = 0.
  wa_fieldcat_alv-seltext_l = text-031.
  wa_fieldcat_alv-seltext_m = text-031.
  wa_fieldcat_alv-seltext_s = text-031.
  wa_fieldcat_alv-reptext_ddic = text-031.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CLASS'.
ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------
*
*&      Form  OUTPUT_USING_ALV_OUTAB3
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM output_using_alv_outab3.
  DATA: ls_variant TYPE disvariant.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_sort-spos = '1'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '3'.
  l_sort-fieldname = 'STATUS'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '4'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '5'.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '7'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.

  APPEND l_sort TO isort.
  l_sort-spos = '8'.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  APPEND l_sort TO isort.
  l_sort-spos = '9'.
  l_sort-fieldname = 'FUNCTIONID'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  APPEND l_sort TO isort.
  l_sort-spos = '10'.
  l_sort-fieldname = 'FUNDES'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '11'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '12'.
  l_sort-fieldname = 'COMPANY'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '13'.
  l_sort-fieldname = 'DEPARTMENT'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  l_sort-spos = '14'.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname = 'OUTAB3'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program       = program
            i_callback_top_of_page   = 'ALV_HEADER'
            i_callback_pf_status_set = 'PF_STATUS'
            i_callback_user_command  = 'HOTSPOT_CLICK'
            is_layout                = alv_layout
            it_sort                  = isort
            it_fieldcat              = i_fieldcat_alv
            i_save                   = 'A'
            is_variant               = ls_variant
       TABLES
            t_outtab                 = outab3
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .
ENDFORM.                    " OUTPUT_USING_ALV

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


  SET PF-STATUS 'CTL' EXCLUDING lt_func.
ENDFORM.
*
*&---------------------------------------------------------------------
*
*&      Form  exelog
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM exelog.
  DATA: task_name(8),
        exelog LIKE /psyng/exelog OCCURS 0 WITH HEADER LINE.

  MOVE sy-uzeit TO task_name.
  exelog-mandt         = sy-mandt.
  exelog-repid         = sy-repid.
  exelog-uname         = g_current_user."sy-uname. C0700
  exelog-datum         = sy-datum.
  exelog-uzeit         = sy-uzeit.
  APPEND exelog.

  CALL FUNCTION '/PSYNG/BASIS_EXELOG'
    STARTING NEW TASK task_name DESTINATION IN GROUP DEFAULT
    TABLES
     exelog         = exelog.
  COMMIT WORK.

ENDFORM.                    " exelog

*&---------------------------------------------------------------------
*
*&      Form  start_child_get_user_name
*&---------------------------------------------------------------------
*
FORM get_user.
  DATA : l_system_msg(80) TYPE c.
  DATA:   yulock   TYPE x VALUE '80',     "Locked by incorrect login
          yusloc   TYPE x VALUE '40',     "Locked by Administrator
         yugloc   TYPE x VALUE '20'.     "Locked by global
**Administrator
  DATA : l_uflagx TYPE x,
         l_ustyp  TYPE usr02-ustyp.
  DATA: wa_uinfo TYPE  /psyng/sw_uinfo,
        wa_usr02 TYPE usr02,
        i_include_locked TYPE flag,
        i_include_expire TYPE flag.

  DATA : lt_uinfo TYPE TABLE OF /psyng/sw_uinfo_remote WITH HEADER LINE.

  CALL FUNCTION '/PSYNG/SW_GET_USER_INFO_NEW'
       EXPORTING
            i_validuser   = validusr
            i_exlckusr    = exlckusr
            i_outvdate    = outvdate
            i_remote_only = remote
       TABLES
            it_users      = uid
            it_usergroup  = s_class
            it_usertype   = usrtype
            it_user_rfc   = remrfc
            et_uinfo      = lt_uinfo.

  SORT lt_uinfo BY rfcdest bname.
  DELETE ADJACENT DUPLICATES FROM lt_uinfo.

  LOOP AT lt_uinfo.
    IF NOT lt_uinfo-class IS INITIAL AND
       NOT lt_uinfo-company IS INITIAL.

      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.

    ELSEIF NOT lt_uinfo-class IS INITIAL.

      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD lt_uinfo-class
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP' FIELD ''. "HBHALLA VF-SCAN FIX(05/12/24)
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.
      ENDIF.

    ELSEIF NOT lt_uinfo-company IS INITIAL.

      AUTHORITY-CHECK OBJECT 'Y&SW_RPOUG'
           ID 'CLASS' FIELD '' "HBHALLA VF-SCAN FIX(05/12/24)
           ID 'Y&SW_VRSIO'  FIELD sodvrsio
           ID 'Y&SW_COMP'   FIELD lt_uinfo-company.
      IF sy-subrc <> 0.
        gt_rpoug_auth_fail-bname   = lt_uinfo-bname.
        gt_rpoug_auth_fail-class   = lt_uinfo-class.
        gt_rpoug_auth_fail-company = lt_uinfo-company.
        APPEND gt_rpoug_auth_fail.
        CLEAR gt_rpoug_auth_fail.
        DELETE lt_uinfo.
        gf_missing_auth_ugroup = 'X'.

      ENDIF.
    ENDIF.
  ENDLOOP.

  gt_uinfo[] = lt_uinfo[].
  REFRESH lt_uinfo.

ENDFORM.                    " get_user

*---------------------------------------------------------------------*
*       FORM get_userinfo_from_child                                  *
*---------------------------------------------------------------------*
FORM get_userinfo_from_child USING taskname.
  DATA : l_system_msg(80) TYPE c.

  RECEIVE RESULTS FROM FUNCTION '/PSYNG/SW_USER_INFO'
          TABLES
      sw_uinfo       = gt_uinfo
      iusgrpt        = iusgrpt
      kostl_resp     = kostl_resp
      EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3.
  IF sy-subrc = 0.
    functioncall_1 = done.
  ELSE.
    CASE sy-subrc.
      WHEN 1 OR 2.
        MESSAGE s398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23)
        l_system_msg.
      WHEN 3.
        MESSAGE s398(00) WITH
        'Task :'(l22)
        taskname
        'failed.'(l23).
    ENDCASE.
  ENDIF.
ENDFORM.
**&---------------------------------------------------------------------
**
**&      Form  output_standard_list
**&---------------------------------------------------------------------
**
**       text
**----------------------------------------------------------------------
**
*FORM output_standard_list.
*  DATA: l_ltext TYPE /psyng/kltxt,
*        l_pbtxt TYPE /psyng/pbtxt.
*
*  LOOP AT outab2.
*
*    AT NEW persa.
**     If ERP system, write personnel area text
*      IF gf_use_erp = 'X'.
*        NEW-PAGE.
*        WRITE:/ outab2-persa.
*
*        CALL METHOD go_erp_class->(gc_persa_method)
*          EXPORTING
*            i_persa = outab2-persa
*          IMPORTING
*            e_pbtxt = l_pbtxt.
*
*        WRITE: l_pbtxt.
*      ENDIF.
*    ENDAT.
*
*    AT NEW tcode.
*      SKIP 1.
*      WRITE:/10 outab2-tcode.
*      READ TABLE itstct WITH KEY sprsl = sy-langu
*                                 tcode = outab2-tcode
*                                 BINARY SEARCH
*                                 TRANSPORTING ttext.
*      IF sy-subrc = 0.
*        WRITE: itstct-ttext.
*      ENDIF.
*    ENDAT.
*
*    AT NEW kostl.
*      SKIP 1.
*      WRITE:/20 outab2-kostl(3).
*
**     If ERP system, write cost center text
*      IF gf_use_erp = 'X'.
*        CALL METHOD go_erp_class->(gc_kostl_method)
*          EXPORTING
*            i_kostl = outab2-kostl
*          IMPORTING
*            e_ltext = l_ltext.
*
*        WRITE: l_ltext.
*      ENDIF.
*
*      READ TABLE kostl_resp WITH KEY kostl = outab2-kostl
*           BINARY SEARCH.
*      IF sy-subrc = 0.
*        WRITE: kostl_resp-kostlresp.
*      ENDIF.
*    ENDAT.
*
*    CONDENSE: outab2-bname, outab2-name_text,
*              outab2-status, outab2-fundes.
*
*    WRITE:/30 outab2-bname, outab2-name_text,
*              outab2-status, outab2-fundes.
*  ENDLOOP.
*
*
*
*ENDFORM.                    " output_standard_list

*&---------------------------------------------------------------------
*
*&      Form  fill_other_data
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM fill_other_data.
*  SELECT * FROM /psyng/functtran
*           INTO CORRESPONDING FIELDS OF TABLE gt_functtran
*           WHERE
*           vrsio = sodvrsio
*           ORDER BY functionid.

*  LOOP AT gt_functtran.
*    MOVE-CORRESPONDING gt_functtran TO gt_functtran2.
*    APPEND gt_functtran2.
*  ENDLOOP.
*  REFRESH: gt_functtran.  CLEAR gt_functtran.
*  SORT gt_functtran2 BY tcode functionid.
*  DELETE ADJACENT DUPLICATES FROM gt_functtran2.
  IF sumfunc = 'X' OR alvdet = 'X'.
    SELECT DISTINCT tcode functionid FROM /psyng/functtran
             INTO CORRESPONDING FIELDS OF TABLE gt_functtran2
             WHERE
             vrsio = sodvrsio
             ORDER BY tcode functionid.
  ENDIF.

  SORT: gt_uinfo, kostl_resp, gt_function BY function.

  LOOP AT outab.
    READ TABLE gt_uinfo WITH KEY bname = outab-bname BINARY SEARCH.
    IF sy-subrc = 0.
      outab-name_text = gt_uinfo-name_text.
      outab-persa = gt_uinfo-persa.
      outab-kostl = gt_uinfo-kostl.
      outab-department = gt_uinfo-department.
      outab-compshort = gt_uinfo-company.
      outab-class = gt_uinfo-class.

      PERFORM get_comp_name
                  CHANGING
                     gt_uinfo-company
                     outab-company.
      IF gt_uinfo-uflag = 0.
        outab-status = 'Active'(035).
      ELSE.
        outab-status = 'Locked'(036).
      ENDIF.

*     If ERP system, write cost center text
      IF gf_use_erp = 'X'.
        CALL METHOD go_erp_class->(gc_kostl_method)
"#EC PATHLOCK_CI_DYN_ACCES
          EXPORTING
            i_kostl = gt_uinfo-kostl
          IMPORTING
            e_ltext = outab-ltext.
      ENDIF.

      READ TABLE kostl_resp WITH KEY kostl = gt_uinfo-kostl
           BINARY SEARCH.
      IF sy-subrc = 0.
        outab-kostlresp = kostl_resp-kostlresp.
      ENDIF.

*     If ERP system, get personnel area text
      IF gf_use_erp = 'X'.
CALL METHOD go_erp_class->(gc_persa_method) "#EC PATHLOCK_CI_DYN_ACCES
          EXPORTING
            i_persa = gt_uinfo-persa
          IMPORTING
            e_pbtxt = outab-name1.
      ENDIF.
    ENDIF.

    IF alvdet = 'X'.

*      PERFORM get_tcode_origin USING
*      outab-tcode outab-bname outab-name_text
*                                  outab-imp outab-rfcdest.
      MOVE-CORRESPONDING outab TO wa_outab4.
      DELETE outab.
      CLEAR : function_idx, functtran2_idx.
      READ TABLE gt_functtran2 WITH KEY tcode = outab-tcode
                                             BINARY SEARCH
                                             TRANSPORTING NO FIELDS.
      functtran2_idx = sy-tabix.
      LOOP AT gt_functtran2 FROM functtran2_idx
                                        WHERE tcode = outab-tcode.
        READ TABLE gt_function
                          WITH KEY function = gt_functtran2-functionid
                          BINARY SEARCH TRANSPORTING NO FIELDS.
        IF sy-subrc = 0.
          function_idx = sy-tabix.
          LOOP AT gt_function FROM function_idx
              WHERE function = gt_functtran2-functionid.
            wa_outab4-functionid = gt_function-function.
            wa_outab4-fundes = gt_function-description.
            APPEND wa_outab4 TO outab4.
          ENDLOOP.
        ELSE.
          APPEND wa_outab4 TO outab4.
        ENDIF.
      ENDLOOP.
      IF sy-subrc <> 0.
        APPEND wa_outab4 TO outab4.
      ENDIF.
    ELSEIF ( alvsum = 'X' )."OR stdsum = 'X' ) .
      MOVE-CORRESPONDING outab TO wa_outab2.
      DELETE outab.
      IF sumfunc = 'X'.
        READ TABLE gt_functtran2 WITH KEY tcode = outab-tcode
                                  BINARY SEARCH TRANSPORTING NO FIELDS.
        functtran2_idx = sy-tabix.
        LOOP AT gt_functtran2 FROM functtran2_idx
                                  WHERE tcode = outab-tcode.
          READ TABLE gt_function
                          WITH KEY function = gt_functtran2-functionid
                          BINARY SEARCH TRANSPORTING NO FIELDS.
          IF sy-subrc = 0.
            function_idx = sy-tabix.
            LOOP AT gt_function FROM function_idx
                              WHERE function = gt_functtran2-functionid.
              wa_outab2-functionid = gt_function-function.
              wa_outab2-fundes = gt_function-description.
*--DHORIONS 2015/07/08 Conserve memory by adding to correct table
*            APPEND wa_outab2 TO outab2.
              MOVE-CORRESPONDING wa_outab2 TO outab3.
              APPEND outab3.
            ENDLOOP.
          ELSE.
*--DHORIONS 2015/07/08 Conserve memory by adding to correct table
*            APPEND wa_outab2 TO outab2.
            MOVE-CORRESPONDING wa_outab2 TO outab3.
            APPEND outab3.
          ENDIF.
        ENDLOOP.
        IF sy-subrc <> 0.
*--DHORIONS 2015/07/08 Conserve memory by adding to correct table
*           APPEND wa_outab2 TO outab2.
          MOVE-CORRESPONDING wa_outab2 TO outab3.
          APPEND outab3.
        ENDIF.
      ELSE.
*--DHORIONS 2015/07/08 Conserve memory by adding to correct table
*         APPEND wa_outab2 TO outab2.
        MOVE-CORRESPONDING wa_outab2 TO outab3.
        APPEND outab3.
      ENDIF.
    ENDIF.
  ENDLOOP.
  FREE : outab.
*  SORT outab2.
*  DELETE ADJACENT DUPLICATES FROM outab2.

  IF alvsum = 'X'.
    SORT outab3.
    DELETE ADJACENT DUPLICATES FROM outab3.
  ENDIF.
  IF alvdet = 'X'.
    SORT outab4.
    DELETE ADJACENT DUPLICATES FROM outab4.
  ENDIF.
ENDFORM.                    " fill_other_data

*---------------------------------------------------------------------*
*       FORM build_alv_catalog_outab4                                 *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM build_alv_catalog_outab4.

  IF outab4[] IS INITIAL.
    MESSAGE s150(/psyng/sw).
    LEAVE LIST-PROCESSING.
  ENDIF.

  CALL FUNCTION 'REUSE_ALV_FIELDCATALOG_MERGE'
       EXPORTING
            i_program_name     = program
            i_internal_tabname = 'OUTAB4'
            i_inclname         = program
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .


  wa_fieldcat_alv-seltext_l = text-030.
  wa_fieldcat_alv-seltext_m = text-030.
  wa_fieldcat_alv-seltext_s = text-030.
  wa_fieldcat_alv-reptext_ddic = text-030.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNCTIONID'.


  wa_fieldcat_alv-seltext_l = text-029.
  wa_fieldcat_alv-seltext_m = text-027.
  wa_fieldcat_alv-seltext_s = text-027.
  wa_fieldcat_alv-reptext_ddic = text-029.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'FUNDES'.

  wa_fieldcat_alv-seltext_l = text-d07.
  wa_fieldcat_alv-seltext_m = text-d07.
  wa_fieldcat_alv-seltext_s = text-d07.
  wa_fieldcat_alv-reptext_ddic = text-d07.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'IMP'.

  wa_fieldcat_alv-seltext_l = text-048.
  wa_fieldcat_alv-seltext_m = text-048.
  wa_fieldcat_alv-seltext_s = text-048.
  wa_fieldcat_alv-reptext_ddic = text-048.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'RFCDEST'.


  IF gf_use_erp = 'X'.
    wa_fieldcat_alv-seltext_l = text-037.
    wa_fieldcat_alv-seltext_m = text-038.
    wa_fieldcat_alv-seltext_s = text-038.
    wa_fieldcat_alv-reptext_ddic = text-038.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'NAME1'.

    wa_fieldcat_alv-seltext_l = text-039.
    wa_fieldcat_alv-seltext_m = text-040.
    wa_fieldcat_alv-seltext_s = text-040.
    wa_fieldcat_alv-reptext_ddic = text-040.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'LTEXT'.

    wa_fieldcat_alv-seltext_l = text-041.
    wa_fieldcat_alv-seltext_m = text-042.
    wa_fieldcat_alv-seltext_s = text-042.
    wa_fieldcat_alv-reptext_ddic = text-042.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                      TRANSPORTING
                        seltext_l
                        seltext_m
                        seltext_s
                        reptext_ddic
                     WHERE
                        fieldname = 'KOSTLRESP'.

  ELSE.
    wa_fieldcat_alv-no_out = 'X'.
    MODIFY i_fieldcat_alv FROM wa_fieldcat_alv TRANSPORTING no_out
                          WHERE fieldname = 'PERSA'
                             OR fieldname = 'NAME1'
                             OR fieldname = 'LTEXT'
                             OR fieldname = 'KOSTLRESP'
                             OR fieldname = 'KOSTL'.

  ENDIF.


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
                      fieldname = 'STATUS'.

***   SE 3.1:E5
  wa_fieldcat_alv-hotspot = 'X'.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      hotspot
                   WHERE
                      fieldname = 'TCODE'.

  wa_fieldcat_alv-seltext_l = text-d08.
  wa_fieldcat_alv-seltext_m = text-d08.
  wa_fieldcat_alv-seltext_s = text-d09.
  wa_fieldcat_alv-reptext_ddic = text-d08.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'BUSAREA'.


  wa_fieldcat_alv-seltext_l = text-d10.
  wa_fieldcat_alv-seltext_m = text-d10.
  wa_fieldcat_alv-seltext_s = text-d10.
  wa_fieldcat_alv-reptext_ddic = text-d10.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'AGR_NAME'.

  wa_fieldcat_alv-seltext_l = text-d11.
  wa_fieldcat_alv-seltext_m = text-d11.
  wa_fieldcat_alv-seltext_s = text-d11.
  wa_fieldcat_alv-reptext_ddic = text-d11.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'PROFILE'.

  wa_fieldcat_alv-col_pos = 0.
  wa_fieldcat_alv-seltext_l = text-031.
  wa_fieldcat_alv-seltext_m = text-031.
  wa_fieldcat_alv-seltext_s = text-031.
  wa_fieldcat_alv-reptext_ddic = text-031.
  MODIFY i_fieldcat_alv FROM wa_fieldcat_alv
                    TRANSPORTING
                      col_pos
                      seltext_l
                      seltext_m
                      seltext_s
                      reptext_ddic
                   WHERE
                      fieldname = 'CLASS'.

ENDFORM.                    " BUILD_ALV_CATALOG
*&---------------------------------------------------------------------
*
*&      Form  OUTPUT_USING_ALV_OUTAB4
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM output_using_alv_outab4.
  DATA: ls_variant TYPE disvariant.

  alv_layout-zebra = 'X'.
  alv_layout-colwidth_optimize = 'X'.

  l_sort-spos = '1'.
  l_sort-fieldname = 'PERSA'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '2'.
  l_sort-fieldname = 'NAME1'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '3'.
  l_sort-fieldname = 'TCODE'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '4'.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  l_sort-spos = '5'.
  l_sort-fieldname = 'IMP'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '6'.
  l_sort-fieldname = 'KOSTL'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '7'.
  l_sort-fieldname = 'LTEXT'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '8'.
  l_sort-fieldname = 'KOSTLRESP'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.

  APPEND l_sort TO isort.
  l_sort-spos = '9'.
  l_sort-fieldname = 'BNAME'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '10'.
  l_sort-fieldname = 'NAME_TEXT'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '11'.
  l_sort-fieldname = 'STATUS'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '12'.
  l_sort-fieldname = 'AGR_NAME'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '13'.
  l_sort-fieldname = 'PROFILE'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '14'.
  l_sort-fieldname = 'FUNDES'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '15'.
  l_sort-fieldname = 'RFCDEST'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '16'.
  l_sort-fieldname = 'OWNER'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.
  l_sort-spos = '17'.
  l_sort-fieldname = 'TTEXT'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '18'.
  l_sort-fieldname = 'BUSAREA'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.

  l_sort-spos = '19'.
  l_sort-fieldname = 'CLASS'.
  l_sort-tabname = 'OUTAB4'.
  l_sort-up = 'X'.
  APPEND l_sort TO isort.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program      = program
            i_callback_top_of_page  = 'ALV_HEADER'
            i_callback_user_command = 'HOTSPOT_CLICK_DETAIL'
            is_layout               = alv_layout
            it_sort                 = isort
            it_fieldcat             = i_fieldcat_alv
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = outab4
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
             PROGRAM_ERROR          = 1
             OTHERS                 = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.              .
ENDFORM.                    " OUTPUT_USING_ALV
*
*&---------------------------------------------------------------------
*
*&      Form  get_sw_repo_conifg
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM get_sw_repo_conifg.
  se_config_param 'REP_USR_LOK_DSP_MGR' dsp_mng_lock.
  se_config_param 'REP_USR_LOK_DSP_SLF' dsp_slf_lock.
ENDFORM.                    " get_sw_repo_conifg

*---------------------------------------------------------------------*
*       FORM alv_header                                               *
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
FORM alv_header.
  DATA: header TYPE slis_t_listheader,
        wa TYPE slis_listheader,
        count TYPE i,
        exedate TYPE char10,
        exetime(8) TYPE c,
        c_count TYPE string,
        alv_grid_titl2   TYPE lvc_title,
        l_date(12) TYPE c,
        l_detail(40) TYPE c,
        c_usercount(6) TYPE c,
        l_systemid       TYPE /psyng/sysid. "C1102 AKUMAR
  .
  wa-typ = 'H'.
  wa-info = 'Critical Transaction Code List'(h01).
  APPEND wa TO header.
*Version
  wa-typ  = 'S'.
  wa-key  = 'SOD version:'(h22).
  SELECT SINGLE vdesc INTO wa-info FROM /psyng/swsodvers
  WHERE vrsio = sodvrsio.
  CONCATENATE sodvrsio ' : '  wa-info INTO wa-info SEPARATED BY space.
  APPEND wa TO header.
*Date
  wa-typ = 'S'.
  wa-key = 'User Date & System:'(h03).
  CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2)
              INTO exetime SEPARATED BY ':'.
  WRITE sy-datum TO exedate.
     CONCATENATE sy-sysid sy-mandt INTO l_systemid. "C1102 AKUMAR
*  CONCATENATE sy-uname text-h11 exedate exetime "C0700
  CONCATENATE g_current_user text-h11 exedate exetime "C0700
   text-h23 l_systemid INTO wa-info SEPARATED BY space.
*  wa-info = l_date.
  APPEND wa TO header.


*Summary
  wa-typ = 'S'.
  wa-key = 'Summary'(h04).
  c_usercount = g_usercount.
  CONCATENATE c_usercount text-h05 INTO l_detail SEPARATED BY space.
  wa-info = l_detail.
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

  DATA : iseltab TYPE STANDARD TABLE OF  rsparams WITH HEADER LINE.

  IF r_ucomm = 'FUSER'.
    PERFORM show_user_grp_cmp_invalid.
    EXIT.
  ENDIF.

  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE outab3 INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.


      CHECK NOT outab3-tcode = ' '.
      REFRESH : iseltab[].
      CLEAR iseltab.

      iseltab-selname = 'UID'.
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = outab3-bname.
      APPEND iseltab.

      iseltab-selname = 'VALIDUSR'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = validusr.
      APPEND iseltab.

  LOOP AT usrtype .
    iseltab-selname = 'USRTYPE'.
    iseltab-kind    = 'S'.
    iseltab-sign    = usrtype-sign.
    iseltab-option  = usrtype-option.
    iseltab-low     = usrtype-low.
    iseltab-high    = usrtype-high.
    APPEND iseltab.
  ENDLOOP.

      iseltab-selname = 'EXLCKUSR'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = exlckusr.
      APPEND iseltab.

      iseltab-selname = 'OUTVDATE'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = exlckusr.
      APPEND iseltab.

      iseltab-selname = 'P_FLAG'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = p_flag.
      APPEND iseltab.

      DATA : l_local_rfc TYPE rfcdest,
             l_remote_rfc TYPE rfcdest.
      CONCATENATE sy-sysid sy-mandt INTO l_local_rfc.
      IF l_local_rfc <> outab3-rfcdest.
        READ TABLE gt_rfcdest WITH KEY rfcoptions = outab3-rfcdest.
        IF sy-subrc = 0.
          l_remote_rfc = gt_rfcdest-rfcdest.
        ENDIF.

        iseltab-selname = 'REMOTE'.
        iseltab-kind    = 'P'.
        iseltab-sign    = 'I'.
        iseltab-option  = 'EQ'.
        iseltab-low     = 'X'.
        APPEND iseltab.

        iseltab-selname = 'REMRFC'.
        iseltab-kind    = 'S'.
        iseltab-sign    = 'I'.
        iseltab-option  = 'EQ'.
        iseltab-low     = l_remote_rfc.
        APPEND iseltab.
        CLEAR l_remote_rfc.
      ENDIF.

      iseltab-selname = 'TCODES'.
      iseltab-kind    = 'S'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = outab3-tcode.
      APPEND iseltab.

      iseltab-selname = 'ALVDET'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = 'X'.
      APPEND iseltab.

      iseltab-selname = 'ALVSUM'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = ' '.
      APPEND iseltab.


      iseltab-selname = 'SODVRSIO'.
      iseltab-kind    = 'P'.
      iseltab-sign    = 'I'.
      iseltab-option  = 'EQ'.
      iseltab-low     = sodvrsio.
      APPEND iseltab.

      IF NOT roles[] IS INITIAL.
        iseltab-selname = 'ROLES'.
        iseltab-kind    = 'S'.
        LOOP AT roles.
          iseltab-sign    = roles-sign.
          iseltab-option  = roles-option.
          iseltab-low     = roles-low.
          iseltab-high    = roles-high.
          APPEND iseltab.
        ENDLOOP.
      ENDIF.

      IF NOT profiles[] IS INITIAL.
        iseltab-selname = 'PROFILES'.
        iseltab-kind    = 'S'.
        LOOP AT profiles.
          iseltab-sign    = profiles-sign.
          iseltab-option  = profiles-option.
          iseltab-low     = profiles-low.
          iseltab-high    = profiles-high.
          APPEND iseltab.
        ENDLOOP.

      ENDIF.
   SUBMIT /psyng/cri_tcode_list WITH SELECTION-TABLE iseltab AND RETURN.

*      PERFORM get_tcode_origin USING
*      is_selfield-value outab3-bname outab3-name_text
*                                  outab3-imp outab3-rfcdest.
*      PERFORM fieldcat_drill_detail_tcode.
*      PERFORM build_sort_detail_tcode.
*      PERFORM drill_alv_detail_tcode.

    WHEN OTHERS.
*--No action

  ENDCASE.
ENDFORM.
*&---------------------------------------------------------------------
*
*&      Form  get_tcode_origin
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------
*
*FORM get_tcode_origin USING i_tcode i_bname TYPE xubname i_name i_imp
*i_rfc.
*  DATA : lt_objects TYPE TABLE OF /psyng/xuobject WITH HEADER LINE,
*         lt_values  TYPE TABLE OF usvalues,
*         lt_auths   TYPE TABLE OF usvalues WITH HEADER LINE,
*         lf_match   TYPE flag,
*         lt_ust10s  TYPE TABLE OF ust10s WITH HEADER LINE,
*         lt_ust10c TYPE TABLE OF ust10c WITH HEADER LINE,
*         lt_roles   TYPE TABLE OF agr_prof WITH HEADER LINE,
*         lt_profiles TYPE TABLE OF  ust10c WITH HEADER LINE,
*         lt_usrprofiles TYPE TABLE OF  ust04 WITH HEADER LINE,
*         lt_usrroles TYPE TABLE OF agr_users WITH HEADER LINE,
*"prevent recursive subprofile
*         l_subprof_maxlevel TYPE i VALUE '5',
*
*         l_subrc TYPE sysubrc,
*         l_tcode TYPE tcode.
*
*  RANGES lt_profile FOR ust10c-profn.
*
*  l_tcode = i_tcode.
*  FREE : gt_tcode_role.
*  FIELD-SYMBOLS : <val> TYPE usvalues.
*  lt_objects-object = 'S_TCODE'.
*  APPEND lt_objects.
**--Get the tcode text
*  PERFORM get_tcode_text
*              USING
*                 l_tcode
*              CHANGING
*                 gt_tcode_role-ttext.
*
*  CALL FUNCTION '/PSYNG/SW_049'
*       EXPORTING
*            user_name  = i_bname
*       TABLES
*            values     = lt_values
*            it_objects = lt_objects.
*
*  LOOP AT lt_values ASSIGNING <val>.
*    IF <val>-bis IS INITIAL AND
*       <val>-von NS '*'.
*      IF <val>-von = l_tcode.
*        lt_auths-auth = <val>-auth.
*        APPEND lt_auths.
*      ENDIF.
*    ELSE.
*      CALL FUNCTION '/PSYNG/SW_021'
*       EXPORTING
*         auth_from        =  <val>-von
*         auth_to          =  <val>-bis
*         sod_from         =  l_tcode
**       SOD_TO           =
*       IMPORTING
*         match            = lf_match.
*      IF lf_match = 'X'.
*        lt_auths-auth = <val>-auth.
*        APPEND lt_auths.
*      ENDIF.
*    ENDIF.
*  ENDLOOP.
*  CHECK NOT lt_auths[] IS INITIAL.
**  IF NOT lt_auths[] IS INITIAL.
**--Get the Single profiles
*  SELECT DISTINCT profn  FROM ust10s INTO CORRESPONDING FIELDS OF
*  TABLE lt_ust10s FOR ALL ENTRIES IN lt_auths
*  WHERE auth = lt_auths-auth
*  AND profn IN profiles.
*
*  SELECT DISTINCT profn  FROM ust10c INTO CORRESPONDING FIELDS OF
*  TABLE lt_ust10c FOR ALL ENTRIES IN lt_auths
*  WHERE subprof = lt_auths-auth
*  AND profn IN profiles.
*
*  lt_profile-sign = 'I'.
*  lt_profile-option = 'EQ'.
*  LOOP AT lt_ust10s.
*    lt_profile-low = lt_ust10s-profn.
*    APPEND lt_profile.
*  ENDLOOP.
*
*  LOOP AT lt_ust10c.
*    lt_profile-low = lt_ust10c-profn.
*    APPEND lt_profile.
*  ENDLOOP.
*
**  ENDIF.
**--Get the roles
*
*  CHECK NOT lt_ust10s[] IS INITIAL.
**  IF NOT lt_ust10s[] IS INITIAL.
*  SELECT * FROM agr_prof INTO TABLE lt_roles
*                      FOR ALL ENTRIES IN lt_ust10s
*                      WHERE profile = lt_ust10s-profn
*                      AND agr_name IN roles.
*  .
**  ENDIF.
*
*  IF NOT lt_roles[] IS INITIAL.
*    SELECT * FROM agr_users INTO TABLE lt_usrroles FOR ALL ENTRIES IN
*  lt_roles WHERE
*  uname = i_bname AND
*  agr_name = lt_roles-agr_name.
*
*    LOOP AT lt_usrroles.
*      gt_tcode_role-bname     = i_bname.
*
*      gt_tcode_role-name_text = i_name.
*      gt_tcode_role-tcode     = i_tcode.
*      gt_tcode_role-rfcdest   = i_rfc.
*      gt_tcode_role-imp       = i_imp.
*      READ TABLE lt_roles WITH KEY agr_name = lt_usrroles-agr_name.
*      gt_tcode_role-agr_name  = lt_roles-agr_name.
*      gt_tcode_role-profile   = lt_roles-profile.
*      APPEND gt_tcode_role.
*      DELETE lt_ust10s WHERE profn = lt_roles-profile.
*    ENDLOOP.
*  ENDIF.
**--Directly assigned profiles : lt_ust10s
**Find parent profiles
*  CHECK NOT lt_ust10s[] IS INITIAL.
*  IF NOT lt_ust10s[] IS INITIAL.
*    SELECT DISTINCT profn subprof  FROM ust10c
*                INTO CORRESPONDING FIELDS OF TABLE lt_profiles
*                FOR ALL ENTRIES IN lt_ust10s
*                WHERE subprof = lt_ust10s-profn.
*  ENDIF.
*  l_subrc = sy-subrc.
*  WHILE l_subrc = 0 AND l_subprof_maxlevel < 0.
*    SELECT DISTINCT profn subprof
*    FROM ust10c APPENDING CORRESPONDING FIELDS OF
*    TABLE lt_profiles FOR ALL ENTRIES IN lt_profiles
*    WHERE subprof = lt_profiles-profn.
*    l_subrc = sy-subrc.
*    LOOP AT lt_profiles.
*      DELETE lt_profiles WHERE profn = lt_profiles-subprof.
*    ENDLOOP.
*    SUBTRACT 1 FROM l_subprof_maxlevel.
*  ENDWHILE.
*
*  SORT lt_profiles BY profn.
*  DELETE ADJACENT DUPLICATES FROM lt_profiles COMPARING profn.
**    CHECK NOT lt_profiles[] IS INITIAL.
*  IF NOT lt_profiles[] IS INITIAL.
*    SELECT * FROM ust04 INTO TABLE lt_usrprofiles FOR ALL ENTRIES IN
*    lt_profiles WHERE bname = i_bname AND
*                      profile = lt_profiles-profn.
*  ENDIF.
*  IF lt_profiles[] IS INITIAL AND lt_roles[] IS INITIAL.
*    IF NOT lt_ust10s[] IS INITIAL.
*      SELECT * FROM ust04 INTO TABLE lt_usrprofiles FOR ALL ENTRIES IN
*      lt_ust10s WHERE profile = lt_ust10s-profn AND
*                      bname = i_bname.
*    ENDIF.
*  ENDIF.
*  LOOP AT lt_usrprofiles.
*    gt_tcode_role-bname     = i_bname.
*    gt_tcode_role-name_text = i_name.
*    gt_tcode_role-tcode     = i_tcode.
*    gt_tcode_role-rfcdest   = i_rfc.
*    gt_tcode_role-imp       = i_imp.
*    CLEAR gt_tcode_role-agr_name.
*    gt_tcode_role-profile   = lt_usrprofiles-profile.
*    APPEND gt_tcode_role.
*  ENDLOOP.
*
*ENDFORM.                    " get_tcode_origin
*&---------------------------------------------------------------------
*
*&      Form  get_tcode_text
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*      -->P_GT_USRHIS_RPT  text
*      <--P_GT_USRHIS_RPT_TCODE_TEXT  text
*----------------------------------------------------------------------
*
*FORM get_tcode_text USING    i_tcode
*                    CHANGING e_text.
*  TYPES: BEGIN OF t_tran,
*           tcode TYPE tstct-tcode,
*           ttext TYPE tstct-ttext,
*         END OF t_tran.
*
*  DATA: ls_tran TYPE t_tran.
*
*  STATICS: lt_tran TYPE HASHED TABLE OF t_tran WITH UNIQUE KEY tcode.
*
*
*  CLEAR e_text.
*
*  READ TABLE lt_tran INTO ls_tran WITH TABLE KEY tcode = i_tcode.
*  IF sy-subrc = 0.
*    e_text = ls_tran-ttext.
*    EXIT.
*  ENDIF.
*
*  SELECT SINGLE ttext INTO ls_tran-ttext FROM tstct
*                WHERE sprsl = sy-langu
*                  AND tcode = i_tcode.
*  IF sy-subrc = 0.
*    e_text        = ls_tran-ttext.
*    ls_tran-tcode = i_tcode.
*    INSERT ls_tran INTO TABLE lt_tran.
*  ELSEIF ls_tran-ttext IS INITIAL.
*    e_text        = 'Tcode for cross system analysis'(100).
*    ls_tran-tcode = i_tcode.
*    INSERT ls_tran INTO TABLE lt_tran.
*  ENDIF.
*ENDFORM.                    " get_tcode_text
*&---------------------------------------------------------------------
*
*&      Form  fieldcat_drill_detail_tcode
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
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
  ls_fieldcat-hotspot = 'X'.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'TTEXT'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Transaction Text'(d04).
  ls_fieldcat-col_pos = 4.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'RFCDEST'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'System/Client'(048).
  ls_fieldcat-col_pos = 5.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'IMP'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Sensitivity Level'(d07).
  ls_fieldcat-col_pos = 6.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.


  ls_fieldcat-fieldname = 'AGR_NAME'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Single Role Name'(d05).
  ls_fieldcat-col_pos = 7.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

  ls_fieldcat-fieldname = 'PROFILE'.
  ls_fieldcat-tabname   = 'GT_TCODE_ROLE'.
  ls_fieldcat-seltext_l = 'Profile'(d06).
  ls_fieldcat-col_pos = 8.
  APPEND ls_fieldcat TO gt_fieldcat.
  CLEAR ls_fieldcat.

ENDFORM.                    " fieldcat_drill_detail_tcode
*
*&---------------------------------------------------------------------
*
*&      Form  build_sort_detail_tcode
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
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

  ls_sort-spos = '5'.
  ls_sort-fieldname = 'RFCDEST'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.

  ls_sort-spos = '6'.
  ls_sort-fieldname = 'IMP'.
  ls_sort-tabname = 'GT_TCODE_ROLE'.
  ls_sort-up = 'X'.
  APPEND ls_sort TO gt_sort.
  CLEAR ls_sort.


ENDFORM.                    " build_sort_detail_tcode

*&---------------------------------------------------------------------
*
*&      Form  drill_alv_detail_tcode
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
FORM drill_alv_detail_tcode.
  DATA: l_program  LIKE sy-repid,
        ls_variant TYPE disvariant.


  l_program = sy-repid.

  y_layout-zebra = 'X'.
  y_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
       EXPORTING
            i_callback_program      = l_program
            i_callback_top_of_page  = 'ALV_HEADER'
            i_callback_user_command = 'HOTSPOT_DRILL_DETAIL'
            is_layout               = y_layout
            it_fieldcat             = gt_fieldcat
            it_sort                 = gt_sort
            i_save                  = 'A'
            is_variant              = ls_variant
       TABLES
            t_outtab                = gt_tcode_role[]
       EXCEPTIONS
            program_error           = 1
            OTHERS                  = 2.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.
ENDFORM.                    " drill_alv_detail_tcode
*---------------------------------------------------------------------*
*       FORM HOTSPOT_CLICK_DETAIL
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM hotspot_click_detail USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.
  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE outab4 INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.

      CALL FUNCTION '/PSYNG/SW_CRITCODE_INFO'
           EXPORTING
                i_tcode = outab4-tcode
                i_vrsio = sodvrsio.

    WHEN OTHERS.
*--No action
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------
*
*---------------------------------------------------------------------*
*       FORM HOTSPOT_DRILL_DETAIL
*---------------------------------------------------------------------*
*       ........                                                      *
*---------------------------------------------------------------------*
*  -->  R_UCOMM                                                       *
*  -->  RS_SELFIELD                                                   *
*---------------------------------------------------------------------*
FORM hotspot_drill_detail USING r_ucomm LIKE sy-ucomm
                                  is_selfield TYPE slis_selfield.
  DATA:l_tcode TYPE tstc-tcode.
  CASE is_selfield-fieldname.
    WHEN 'TCODE'.
      READ TABLE gt_tcode_role INDEX is_selfield-tabindex.
      CHECK sy-subrc = 0.
      l_tcode = gt_tcode_role-tcode.
      CALL FUNCTION '/PSYNG/SW_CRITCODE_INFO'
           EXPORTING
                i_tcode = l_tcode
                i_vrsio = sodvrsio.

    WHEN OTHERS.
*--No action

  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------
*
*&---------------------------------------------------------------------
*
*&      Form  f4_ctprof
*&---------------------------------------------------------------------
*
*       text
*----------------------------------------------------------------------
*
*      <--P_PROFILES_LOW  text
*----------------------------------------------------------------------
*
FORM f4_tcodes CHANGING e_tcode TYPE /psyng/critcodes-tcode.

  DATA: BEGIN OF lt_values OCCURS 0,
          line(255) TYPE c,
        END OF lt_values.

  DATA: lt_fields TYPE TABLE OF help_value WITH HEADER LINE,
        lt_return TYPE TABLE OF ddshretval WITH HEADER LINE,
        ls_ctcode TYPE /psyng/critcodes,
        lt_ctcode TYPE TABLE OF /psyng/critcodes WITH HEADER LINE.

  DATA : BEGIN OF ctcode OCCURS 0,
  ttext TYPE tstct-ttext.
          INCLUDE STRUCTURE /psyng/critcodes.
  DATA END OF ctcode.

  SELECT * FROM /psyng/critcodes INTO TABLE lt_ctcode
  WHERE vrsio = sodvrsio.
  SORT lt_ctcode BY tcode.
  LOOP AT lt_ctcode.
    MOVE-CORRESPONDING lt_ctcode TO ctcode.
    SELECT SINGLE ttext FROM tstct INTO (ctcode-ttext)
    WHERE tcode = lt_ctcode-tcode
    AND sprsl EQ sy-langu.
    IF sy-subrc NE 0.
      ctcode-ttext = 'Tcode for cross system Analysis'(103).
    ENDIF.
    APPEND ctcode.
  ENDLOOP.


  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'TCODE'.
  lt_fields-selectflag = 'X'.
  APPEND lt_fields.

  lt_fields-tabname   = 'TSTCT'.
  lt_fields-fieldname = 'TTEXT'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-tabname   = '/PSYNG/CRITCODES'.
  lt_fields-fieldname = 'VRSIO'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'IMP'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'OWNER'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  lt_fields-fieldname = 'BUSAREA'.
  lt_fields-selectflag = ' '.
  APPEND lt_fields.

  LOOP AT ctcode.
    lt_values-line = ctcode-tcode.
    APPEND lt_values.
    lt_values-line = ctcode-ttext.
    APPEND lt_values.
    lt_values-line = ctcode-vrsio.
    APPEND lt_values.
    lt_values-line = ctcode-imp.
    APPEND lt_values.
    lt_values-line = ctcode-owner.
    APPEND lt_values.
    lt_values-line = ctcode-busarea.
    APPEND lt_values.
  ENDLOOP.

  CALL FUNCTION 'HELP_VALUES_GET_WITH_TABLE'
       EXPORTING
            titel                     = text-t14
       IMPORTING
            select_value              = e_tcode
       TABLES
            fields                    = lt_fields
            valuetab                  = lt_values
       EXCEPTIONS
            field_not_in_ddic         = 1
            more_then_one_selectfield = 2
            no_selectfield            = 3
            OTHERS                    = 4.
  IF sy-subrc <> 0.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*&      Form  get_tcodes_by_user
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_data_by_user.

  DATA : l_local_sys TYPE rfcdes-rfcdest,
         lt_objs  TYPE TABLE OF /psyng/sw_xuobject,
         ls_obj   TYPE /psyng/sw_xuobject,
         ls_tcode TYPE /psyng/sw_tcode,
         lt_tcodes TYPE TABLE OF /psyng/sw_tcode,
         lt_faobj_dummy TYPE TABLE OF /psyng/faobj2,
         lt_functtran_dummy TYPE TABLE OF /psyng/functtran,
         lt_useauth_dummy TYPE TABLE OF /psyng/userauth,
         lt_critcodes_system type table of /psyng/critcodes
         with header line,
         l_system type /PSYNG/RFCNAME.


  ls_obj = 'S_TCODE'.
  INSERT ls_obj INTO TABLE lt_objs.

  DELETE lt_critcodes WHERE tcode EQ space.


*--2015/07/03 DHORIONS - Don't load data for all users at once to
* conserve memory.  Related to case 12758
  DATA : lt_usr_part TYPE TABLE OF  usr02,
         l_maxusers TYPE i VALUE '1000'.


  LOOP AT gt_rfcdest.


*    --Filter Transactions by System
      lt_critcodes_system[] = lt_critcodes[].
      l_system = gt_rfcdest-rfcoptions.
      CALL FUNCTION '/PSYNG/SW_124'
        EXPORTING
         IF_TCODE           = 'X'
         i_system           = l_system
         i_vrsio            = sodvrsio
       TABLES
         IT_CRITCODES        = lt_critcodes_system
"(++)BOC UMITTAL SE VF scan-25/11/2024
           EXCEPTIONS
            TOO_MANY_OPTIONS = 1
             OTHERS          = 2 .
   IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.
"(++)EOC UMITTAL SE VF scan-25/11/2024.           .

      refresh : lt_tcodes.
      LOOP AT lt_critcodes_system.
        ls_tcode-tcode = lt_critcodes_system-tcode.
        INSERT ls_tcode INTO TABLE lt_tcodes.
      ENDLOOP.


    IF gt_rfcdest-rfcdest = 'LOCAL'.

      LOOP AT gt_uinfo WHERE rfcdest EQ g_local_sys.
        iusr02-bname = gt_uinfo-bname.
        APPEND iusr02.
      ENDLOOP.






      WHILE NOT iusr02[] IS INITIAL.
        REFRESH : lt_usr_part[].
        APPEND LINES OF iusr02  FROM 1 TO l_maxusers TO  lt_usr_part.
        DELETE iusr02 FROM 1 TO l_maxusers.

        CALL FUNCTION '/PSYNG/SW_GET_USER_AUTH'
*--Case 11127
*       DESTINATION gt_rfcdest-rfcoptions
         EXPORTING
         i_rolerem_simu  = 'X'
          TABLES
            it_users                 = lt_usr_part
            it_tcodes                = lt_tcodes
*--Required parameter, pass empty table
            it_faobj                 = lt_faobj_dummy
            it_functtran             = lt_functtran_dummy

            it_objects               = lt_objs
            et_usertcode             = gt_usrtcode_part
*--Don't pass, conserver memory
*          et_user_auth             =  lt_useauth_dummy
            .

        APPEND LINES OF gt_usrtcode_part TO gt_usrtcode.
        REFRESH gt_usrtcode_part.
        REFRESH lt_usr_part.
      ENDWHILE.
    ELSE.
      LOOP AT gt_uinfo WHERE rfcdest EQ gt_rfcdest-rfcoptions.
        iusr02-bname = gt_uinfo-bname.
        APPEND iusr02.
      ENDLOOP.

      WHILE NOT iusr02[] IS INITIAL.
        REFRESH : lt_usr_part[].
        APPEND LINES OF iusr02  FROM 1 TO l_maxusers TO  lt_usr_part.
        DELETE iusr02 FROM 1 TO l_maxusers.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
        CALL FUNCTION '/PSYNG/SW_GET_USER_AUTH'
         DESTINATION gt_rfcdest-rfcdest
                EXPORTING
         i_rolerem_simu  = 'X'
        TABLES
          it_users                 = lt_usr_part
          it_tcodes                = lt_tcodes
*--Required parameter, pass empty table
          it_faobj                 = lt_faobj_dummy
          it_functtran             = lt_functtran_dummy

          it_objects               = lt_objs
          et_usertcode             = gt_usrtcode_part
*--Don't pass, conserver memory
*        et_user_auth             =  lt_useauth_dummy
*BOC UMITTAL PN11269 ATC Error Fixes BMW 15/01/2025
          EXCEPTIONS
            SYSTEM_FAILURE = 1
            COMMUNICATION_FAILURE = 2
            OTHERS = 3.   "#EC SAST_CI_GEN_CHECK
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
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

        APPEND LINES OF gt_usrtcode_part TO gt_usrtcode.
        REFRESH gt_usrtcode_part.
        REFRESH lt_usr_part.
      ENDWHILE.
    ENDIF.
  ENDLOOP.

ENDFORM.                    " get_tcodes_by_user
*&---------------------------------------------------------------------*
*&      Form  get_rfc_destinations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_rfc_destinations.

  DATA : l_rfcdest TYPE rfcdes-rfcdest,
          l_system_msg(80) TYPE c,
          l_local_sys TYPE rfcdest.
  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.

*--Get sysid and mandt into field RFCOPTIONS
  LOOP AT gt_rfcdest ASSIGNING <rfcdes>.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
    EXCEPTIONS
          communication_failure = 1 MESSAGE l_system_msg
          system_failure        = 2 MESSAGE l_system_msg
          OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      CASE sy-subrc.
        WHEN 1 OR 2.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest
          l_system_msg.
        WHEN 3.
          MESSAGE e398(00) WITH
          text-e03
          l_rfcdest.
      ENDCASE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.

*--Delete any RFC pointing to the local system.
  SORT gt_rfcdest BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM gt_rfcdest COMPARING rfcoptions.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE  gt_rfcdest WHERE rfcoptions = l_local_sys
AND rfcdest <> 'LOCAL'.


ENDFORM.                    " get_rfc_destinations
*&---------------------------------------------------------------------*
*&      Form  at_selection_screen
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM at_selection_screen.

*  CHECK NOT remrfc[] IS INITIAL.
*  DATA : l_rfcdest TYPE rfcdes-rfcdest,
*           l_system_msg(80) TYPE c,
*           l_local_sys TYPE rfcdest.
*  FIELD-SYMBOLS : <rfcdes> TYPE rfcdes.
*
*  SELECT rfcdest INTO TABLE gt_rfcdest FROM rfcdes
*         WHERE rfcdest IN remrfc.
**  IF sy-subrc <> 0.
**    MESSAGE e004(sr).
**  ENDIF.


ENDFORM.                    " at_selection_screen
*&---------------------------------------------------------------------*
*&      Form  get_critical_data
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_critical_data.
  DATA : lt_agr_tcodes TYPE TABLE OF agr_tcodes WITH HEADER LINE,
         lt_agr_1016 TYPE TABLE OF agr_1016 WITH HEADER LINE,
         lt_role_prof TYPE TABLE OF /psyng/sw_critcode_detail.

  RANGES : t_profile FOR ust10s-profn,
           s_bname FOR sy-uname,
           s_bname_tmp FOR sy-uname.

* Filter list of tcodes if we are provided with valid role and profile
*names

  IF NOT profiles[] IS INITIAL.
*    SELECT * FROM agr_1016 INTO TABLE lt_agr_1016
*    WHERE profile IN profiles.

    SELECT agr_name FROM agr_1016
      INTO CORRESPONDING FIELDS OF TABLE lt_agr_1016
        WHERE profile IN profiles.

    roles-sign = 'I'.
    roles-option = 'EQ'.
    LOOP AT lt_agr_1016.
      roles-low = lt_agr_1016-agr_name.
      APPEND roles.
    ENDLOOP.
  ENDIF.



  IF NOT roles[] IS INITIAL.
*    SELECT * FROM agr_tcodes INTO TABLE lt_agr_tcodes
*    WHERE agr_name IN roles
*    AND tcode IN tcodes.

    SELECT tcode FROM agr_tcodes
      INTO CORRESPONDING FIELDS OF TABLE lt_agr_tcodes
       WHERE agr_name IN roles
        AND tcode IN tcodes.

    REFRESH tcodes.
    tcodes-sign = 'I'.
    tcodes-option = 'EQ'.

    LOOP AT lt_agr_tcodes.
      tcodes-low = lt_agr_tcodes-tcode.
      APPEND tcodes.
    ENDLOOP.
    CHECK NOT tcodes[] IS INITIAL.
    SORT tcodes.
    DELETE ADJACENT DUPLICATES FROM tcodes COMPARING ALL FIELDS.
  ENDIF.




*-- Get critical tcodes
  SELECT tcode imp owner busarea FROM /psyng/critcodes
  INTO CORRESPONDING FIELDS OF TABLE lt_critcodes
  WHERE vrsio = sodvrsio
    AND imp IN p_imp
    AND owner IN p_owner
    AND busarea IN p_busare.

*-- Filter out non critical tcodes
  DELETE lt_critcodes WHERE NOT tcode IN tcodes.

*-- Get Tcode descriptions
  IF NOT lt_critcodes[] IS INITIAL.

    SELECT DISTINCT * FROM tstct
    INTO CORRESPONDING FIELDS OF TABLE itstct
    FOR ALL ENTRIES IN lt_critcodes
    WHERE tcode = lt_critcodes-tcode
      AND sprsl = sy-langu.

  ENDIF.

*-- New Logic for SE 3.1 Remote roles & profiles

*  s_bname-sign = 'I'.
*  s_bname-option = 'EQ'.
*  LOOP AT gt_uinfo.
*    s_bname-low = gt_uinfo-bname.
*    APPEND s_bname.
*  ENDLOOP.

*  IF alvdet = 'X'.
  IF gt_role_prof[] IS INITIAL.
    LOOP AT gt_rfcdest.
      t_profile[] = profiles[].
*      WHILE NOT s_bname[] IS INITIAL.
*
*        LOOP AT s_bname FROM 1 TO 1200.
*          MOVE-CORRESPONDING s_bname TO s_bname_tmp.
*          APPEND s_bname_tmp.
*        ENDLOOP.
*
*        DELETE s_bname FROM 1 TO 1200.

      IF gt_rfcdest-rfcdest = 'LOCAL'.
        LOOP AT gt_uinfo WHERE rfcdest EQ g_local_sys.
          gt_uinfo_part-bname = gt_uinfo-bname.
          APPEND gt_uinfo_part.
        ENDLOOP.

        CALL FUNCTION '/PSYNG/SW_GET_USR_ROLES_PROFS'
             TABLES
                  et_auth_prof  = iagr_prof_part
                  et_roles_prof = lt_role_prof
                  it_roles      = roles
                  it_profiles   = t_profile
                  it_bname      = s_bname_tmp
                  it_uinfo      = gt_uinfo_part.
      ELSE.

        LOOP AT gt_uinfo WHERE rfcdest EQ gt_rfcdest-rfcoptions.
          gt_uinfo_part-bname = gt_uinfo-bname.
          APPEND gt_uinfo_part.
        ENDLOOP.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.

        CALL FUNCTION '/PSYNG/SW_GET_USR_ROLES_PROFS'
        DESTINATION gt_rfcdest-rfcdest
           TABLES
                  et_auth_prof = iagr_prof_part
                  et_roles_prof = lt_role_prof
                  it_roles    = roles
                  it_profiles = t_profile
                  it_bname    = s_bname_tmp
                  it_uinfo      = gt_uinfo_part. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024


      ENDIF.
      APPEND LINES OF iagr_prof_part TO iagr_prof.
      APPEND LINES OF lt_role_prof TO gt_role_prof.
      REFRESH iagr_prof_part.
      REFRESH lt_role_prof.
      REFRESH gt_uinfo_part.
    ENDLOOP.
  ENDIF.
*  ENDIF.
  IF sumfunc = 'X' OR alvdet = 'X'..
    SELECT function description
      FROM /psyng/function
        INTO CORRESPONDING FIELDS OF TABLE gt_function
          WHERE vrsio = sodvrsio.
  ENDIF.
ENDFORM.                    " get_critical_data
*&---------------------------------------------------------------------*
*&      Form  get_critical_tcode
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM build_output.

  DATA : l_tabix TYPE sy-tabix,
         wa_busarea TYPE /psyng/busarea,
         lt_busarea TYPE TABLE OF /psyng/busarea WITH HEADER LINE.


  SELECT  busarea text FROM /psyng/busarea
   INTO CORRESPONDING FIELDS OF TABLE lt_busarea.
  SORT lt_busarea   BY busarea.
  SORT lt_critcodes BY tcode.
  SORT iagr_prof    BY auth rfcdest bname.
  SORT gt_role_prof BY profile rfcdest.

  LOOP AT gt_rfcdest.
    LOOP AT gt_usrtcode WHERE rfcdest = gt_rfcdest-rfcoptions.

      outab-bname = gt_usrtcode-bname.
      outab-tcode = gt_usrtcode-tcode.


*  fill Transaction text
      READ TABLE itstct WITH KEY sprsl = sy-langu
                                    tcode = gt_usrtcode-tcode
                                    BINARY SEARCH.
      IF sy-subrc EQ 0.
        outab-ttext = itstct-ttext.
      ELSE.
        outab-ttext = 'TCODE FOR CROSS SYSTEM ANALYSIS'(103).
      ENDIF.
      CLEAR itstct-ttext.

* fill sensitivity & owner & Application area
      READ TABLE lt_critcodes WITH KEY tcode = gt_usrtcode-tcode
      BINARY SEARCH.
      IF sy-subrc EQ 0.
        outab-imp = lt_critcodes-imp.
        outab-owner = lt_critcodes-owner.
*      SELECT SINGLE * FROM /psyng/busarea INTO wa_busarea
*      WHERE busarea = lt_critcodes-busarea.
        READ TABLE lt_busarea
        INTO wa_busarea
        WITH KEY busarea = lt_critcodes-busarea
        BINARY SEARCH TRANSPORTING text.
        IF sy-subrc = 0.
          outab-busarea = wa_busarea-text.
        ENDIF.
      ENDIF.
      outab-rfcdest = gt_usrtcode-rfcdest.
*    outab-profile = gt_usrtcode-auth.


*2015/07/03 Dries : also do this in case of summary because we can
* restrict by role/profile
*    IF alvdet = 'X'.
      READ TABLE iagr_prof INTO wa_iagr_prof
      WITH KEY auth = gt_usrtcode-auth
               rfcdest = outab-rfcdest
               bname = outab-bname
      BINARY SEARCH.
      IF sy-subrc = 0.
        outab-profile = wa_iagr_prof-profn.
*      ELSE.
*        CONTINUE.
      ENDIF.
*     fill role
      CLEAR wa_iagr_prof.
      READ TABLE gt_role_prof
              WITH KEY profile = outab-profile
                       rfcdest = outab-rfcdest
              BINARY SEARCH.
      IF sy-subrc = 0.
*       Profile w/ Role AND No roles SPECIFIED
        outab-agr_name = gt_role_prof-agr_name.
      ELSE.

      ENDIF.
*    ENDIF.

      APPEND outab.
      CLEAR outab.
    ENDLOOP.
  ENDLOOP.

  FREE : gt_usrtcode,
         lt_busarea,
         lt_critcodes,
         iagr_prof,
         gt_role_prof.


ENDFORM.                    " get_critical_tcode
*&---------------------------------------------------------------------*
*&      Form  check_user_access
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_user_access.
  DATA lt_role TYPE TABLE OF agr_users-agr_name WITH HEADER LINE.
  DATA lt_profile TYPE TABLE OF ust04-profile WITH HEADER LINE .
  DATA lf_access TYPE flag.

**Do not checl for user access in case of rfc
  CHECK gt_rfcdest[] IS INITIAL.
  IF NOT roles[] IS INITIAL.
    SELECT agr_name FROM agr_users INTO TABLE lt_role
    WHERE uname IN uid
    AND agr_name IN roles.
    IF sy-subrc = 0.
      lf_access = 'X'.
    ELSE.
      MESSAGE s150(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

  IF NOT profiles[] IS INITIAL.
    SELECT profile FROM ust04 INTO TABLE lt_profile WHERE bname IN uid
     AND profile IN profiles.
    IF sy-subrc = 0.
      lf_access = 'X'.
    ELSE.
      MESSAGE s150(/psyng/sw).
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDIF.

ENDFORM.                    " check_user_access
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

  SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
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
    SELECT a~domvalue_l AS value b~ddtext AS dtext "#EC CI_NOORDER
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
  DATA: gs_variant TYPE disvariant.

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
          is_variant            = gs_variant
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
"(++)EOC UMITTAL SE VF scan-25/11/2024.            .

ENDFORM.                    " show_user_grp_cmp_invalid
*&---------------------------------------------------------------------*
*&      Form  initialize
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM initialize.
ENDFORM.                    " initialize
*&---------------------------------------------------------------------*
*&      Form  rfc_validations
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM rfc_validations.
  DATA : l_continue TYPE flag,
       r_rfcs TYPE TABLE OF /psyng/sw_sel_opts_rfcdest WITH HEADER LINE.


  APPEND LINES OF remrfc TO r_rfcs.
  CLEAR l_continue.
  DELETE r_rfcs WHERE low = ' '.
*--Validate RFC Destinations
  CALL FUNCTION '/PSYNG/BC_VALIDATE_RFCDEST'
       EXPORTING
            i_popup    = 'X'
            i_module   = 'SE'
       IMPORTING
            e_continue = l_continue
       TABLES
            it_rfcdes  = r_rfcs.
  IF l_continue <> 'X'.
    LEAVE LIST-PROCESSING.
  ENDIF.


  FREE : gt_rfcdest.
*  lt_remrfc[] = r_rfcs[].
  PERFORM load_role_rfc
              TABLES
                 r_rfcs
                 gt_rfcdest.

ENDFORM.                    " rfc_validations
*&---------------------------------------------------------------------*
*&      Form  load_role_rfc
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      -->P_R_RFCS  text
*      -->P_GT_RFCDEST  text
*----------------------------------------------------------------------*
FORM load_role_rfc TABLES    it_role_rfc STRUCTURE
/psyng/sw_sel_opts_rfcdest
      et_rfcdes STRUCTURE rfcdes.

  DATA : l_rfcdest TYPE rfcdes-rfcdest.
  DATA: BEGIN OF lt_dest OCCURS 0,
           rfcdest TYPE rfcdes-rfcdest,
         END OF lt_dest,
        lt_rfc_log TYPE TABLE OF rfclog WITH HEADER LINE,
        l_rfc_test TYPE rfctest,
        l_system_msg(80) TYPE c.

  FIELD-SYMBOLS :<rfcdes> TYPE rfcdes.
  IF NOT it_role_rfc[] IS INITIAL.
    SELECT rfcdest FROM rfcdes
           APPENDING CORRESPONDING FIELDS OF TABLE et_rfcdes
           WHERE rfcdest IN it_role_rfc."#EC SAST_CI_GEN_CHECK
  ENDIF.
  LOOP AT et_rfcdes ASSIGNING <rfcdes>.
*BOC UMITTAL SE VF scan changes-25/11/2024
    CALL FUNCTION 'RFC_CALLBACK_REJECTED'
         EXCEPTIONS
           invalid_reject_option        = 1
           invalid_reject_state         = 2
           function_not_supported       = 3
           internal_error               = 4
           OTHERS                       = 5
                  .
        IF sy-subrc NE 0.
          MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
                  WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
    CALL FUNCTION '/PSYNG/BC_GET_SYSTEM_ID'
    DESTINATION <rfcdes>-rfcdest
     IMPORTING
       e_rfcdest       = l_rfcdest
  EXCEPTIONS
        communication_failure = 1 MESSAGE l_system_msg
        system_failure        = 2 MESSAGE l_system_msg
        OTHERS                = 3. "#EC SAST_CI_GEN_CHECK
*  Check has been placed but call is before exception handling
*   but since the check fm is called 4 lines before, code compiler
*   is not picking it up
*EOC UMITTAL SE VF scan changes-25/11/2024

    IF sy-subrc <> 0.
      DELETE et_rfcdes.
      CONTINUE.
      COMMIT WORK.
    ELSE.
      <rfcdes>-rfcoptions = l_rfcdest.
    ENDIF.
  ENDLOOP.
  SORT et_rfcdes BY rfcoptions.
  DELETE ADJACENT DUPLICATES FROM et_rfcdes COMPARING rfcoptions.
  DATA : l_local_sys TYPE rfcdest.
  CONCATENATE sy-sysid sy-mandt INTO l_local_sys.
  DELETE et_rfcdes WHERE rfcoptions = l_local_sys.

ENDFORM.                    " load_role_rfc
*&---------------------------------------------------------------------*
*&      Form  get_comp_name
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*      <--P_GT_UINFO_COMPANY  text
*      <--P_OUTAB_COMPANY  text
*----------------------------------------------------------------------*
FORM get_comp_name CHANGING i_company   "TYPE  /psyng/sw_uinfo-company
                            e_comp_name ."TYPE  /psyng/sw_uinfo-company.

  TYPES: BEGIN OF t_comp,
           comp TYPE /psyng/mcauditor-company,
           name TYPE /psyng/mcauditor-company,
         END OF t_comp.

  DATA: l_value  TYPE /psyng/swconfig-value,
        l_fmname TYPE rs38l_fnam,
        ls_comp  TYPE t_comp.

  STATICS: lt_comp TYPE HASHED TABLE OF t_comp WITH UNIQUE KEY comp,
           l_fm_checked TYPE flag.

  CHECK l_fm_checked IS INITIAL OR gf_company_longtext = 'X'.
  READ TABLE lt_comp INTO ls_comp WITH TABLE KEY comp = i_company.
  IF sy-subrc = 0.
    e_comp_name = ls_comp-name.
    EXIT.
  ENDIF.

* Check what FM is configured for Company name
*  SELECT SINGLE value INTO l_value                   "#EC CI_SEL_NESTED
*    FROM /psyng/swconfig
*                WHERE param = 'SW_MGMT_COMP_NAME_FM'.
  se_config_param 'SW_MGMT_COMP_NAME_FM' l_value.
  IF not l_value is initial.
    l_fmname = l_value.
    IF NOT l_fmname IS INITIAL.
      CALL FUNCTION 'FUNCTION_EXISTS'
           EXPORTING
                funcname           = l_fmname
           EXCEPTIONS
                function_not_exist = 1
                OTHERS             = 2.
      IF sy-subrc <> 0.
*       Configured FM does not exist, use none
        CLEAR l_fmname.
        MESSAGE s113(/psyng/sw) WITH
                'Cannot determine SW_MGMT_COMP_NAME_FM with FM '
                l_fmname '. FM doesn''t exist'.
      ELSE.
        gf_company_longtext = 'X'.
      ENDIF.
    ENDIF.
  ELSE.
    EXIT.
    CLEAR gf_company_longtext.
  ENDIF.
  IF NOT l_fmname IS INITIAL.
    CALL FUNCTION l_fmname "#EC PATHLOCK_CI_DYN_ACCES
*HBHALLA: As Function name is variable so it can’t be fixed.(11/12/24)
         EXPORTING
              i_company   = i_company
         IMPORTING
              e_comp_name = e_comp_name.

    ls_comp-comp = i_company.
    ls_comp-name = e_comp_name.
    INSERT ls_comp INTO TABLE lt_comp.
    l_fm_checked = 'X'.
  ENDIF.

ENDFORM.                    " get_comp_name
FORM get_users_count.
  DATA : l_numb TYPE i,
         lv_exlckusr TYPE c,
         lv_outvdate TYPE c,
         lv_local type flag value 'X'.
  IF remote = 'X'.
    clear lv_local.
  endif.

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
   IF_LOCAL_SYSTEM         = lv_local
   IF_SHOW_MESSAGE         = 'X'
 IMPORTING
   E_USERCOUNT             = l_numb
 TABLES
   IT_USERLIST             = uid
   IT_GROUPLIST            = s_class
   IT_USERTYPE             = usrtype
*   IT_ACTGROUPS            = s_role
*   IT_PROFILE              = s_prof
   IT_RFCRANGE             = remrfc
*   IT_RFCLIST              =
*   IT_DEPARTMENT           = s_depart
*   IT_COMPANY              = s_comp
*   IT_CUID                 = s_cuid
    .
ENDFORM.                    " get_users_count
